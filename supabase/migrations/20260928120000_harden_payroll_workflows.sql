-- Draft migration based on the reconstructed schema reference.
-- Do not apply until the live schema has been compared, this migration has
-- been tested against synthetic staging data, and a production backup exists.

BEGIN;

DO $preflight$
BEGIN
    IF to_regclass('public.payroll_records') IS NULL
       OR to_regclass('public.payroll_items') IS NULL
       OR to_regclass('public.overtime_requests') IS NULL
       OR to_regclass('public.leave_requests') IS NULL
             OR to_regclass('public.audit_logs') IS NULL
             OR to_regclass('public.salary_history') IS NULL
             OR to_regclass('public.payroll_periods') IS NULL
             OR to_regclass('public.payslips') IS NULL
             OR to_regclass('public.statutory_configs') IS NULL
             OR to_regclass('public.employees') IS NULL
             OR to_regclass('public.attendance') IS NULL
             OR to_regclass('public.user_profiles') IS NULL THEN
        RAISE EXCEPTION
            'EAMA workflow migration preflight failed: required tables are missing.';
    END IF;

    IF to_regprocedure('public.is_admin_or_hr()') IS NULL
       OR to_regprocedure('public.get_current_employee_id()') IS NULL
       OR to_regprocedure('public.is_department_manager(uuid)') IS NULL THEN
        RAISE EXCEPTION
            'EAMA workflow migration preflight failed: required authorization functions are missing.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_class AS relations
        JOIN pg_namespace AS namespaces
          ON namespaces.oid = relations.relnamespace
        WHERE namespaces.nspname = 'public'
          AND relations.relname = ANY (ARRAY[
              'employees',
              'user_profiles',
              'attendance',
              'leave_requests',
              'overtime_requests',
              'audit_logs',
              'statutory_configs',
              'payroll_periods',
              'payroll_records',
              'payroll_items',
              'payslips'
          ])
          AND (
              relations.relrowsecurity IS NOT TRUE
              OR relations.relforcerowsecurity IS TRUE
          )
    ) THEN
        RAISE EXCEPTION
            'EAMA workflow migration preflight failed: review RLS enabled/FORCE RLS settings before applying.';
    END IF;
END;
$preflight$;

ALTER TABLE public.payslips
    ADD COLUMN IF NOT EXISTS period_name TEXT;

UPDATE public.payslips AS slips
SET period_name = periods.period_name
FROM public.payroll_periods AS periods
WHERE periods.id = slips.payroll_period_id
    AND slips.period_name IS NULL;

CREATE OR REPLACE FUNCTION public.guard_payroll_record_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
    v_stage INTEGER;
BEGIN
    SELECT workflow_stage
    INTO v_stage
    FROM public.payroll_periods
    WHERE id = OLD.payroll_period_id;

    IF v_stage >= 3 THEN
        RAISE EXCEPTION
            'Security Violation: Payroll records in an Approved or Paid period (Stage: %) are immutable.',
            v_stage;
    END IF;

    IF TG_OP = 'DELETE' THEN
        DELETE FROM public.payroll_items
        WHERE payroll_record_id = OLD.id;

        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.require_payroll_generation_config()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
    IF OLD.workflow_stage < 2
       AND NEW.workflow_stage = 2
       AND NOT EXISTS (
            SELECT 1
            FROM public.statutory_configs
            WHERE effective_from <= NEW.end_date
              AND (effective_to IS NULL OR effective_to >= NEW.start_date)
       ) THEN
        RAISE EXCEPTION
            'Payroll generation requires an effective-dated statutory configuration for the entire period.';
    END IF;

    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_require_payroll_generation_config
    ON public.payroll_periods;

CREATE TRIGGER trg_require_payroll_generation_config
BEFORE UPDATE OF workflow_stage
ON public.payroll_periods
FOR EACH ROW
EXECUTE FUNCTION public.require_payroll_generation_config();

CREATE OR REPLACE FUNCTION public.guard_payroll_item_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
    v_record_id UUID;
    v_stage INTEGER;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_record_id := NEW.payroll_record_id;
    ELSE
        v_record_id := OLD.payroll_record_id;
    END IF;

    IF TG_OP = 'UPDATE'
       AND NEW.payroll_record_id IS DISTINCT FROM OLD.payroll_record_id THEN
        RAISE EXCEPTION
            'Payroll items cannot be moved between payroll records.';
    END IF;

    SELECT periods.workflow_stage
    INTO v_stage
    FROM public.payroll_records AS records
    JOIN public.payroll_periods AS periods
      ON periods.id = records.payroll_period_id
    WHERE records.id = v_record_id;

    IF v_stage >= 3 THEN
        RAISE EXCEPTION
            'Payroll items in an approved or paid period are immutable.';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_guard_payroll_item_mutation
    ON public.payroll_items;

CREATE TRIGGER trg_guard_payroll_item_mutation
BEFORE INSERT OR UPDATE OR DELETE
ON public.payroll_items
FOR EACH ROW
EXECUTE FUNCTION public.guard_payroll_item_mutation();

CREATE OR REPLACE FUNCTION public.guard_overtime_request_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
    IF NEW.status IN ('Approved', 'Rejected')
       AND EXISTS (
            SELECT 1
            FROM public.employees
            WHERE id = NEW.employee_id
              AND user_id = auth.uid()
       ) THEN
        RAISE EXCEPTION
            'Users may not approve or reject their own overtime request.';
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF public.is_admin_or_hr() THEN
            RETURN NEW;
        END IF;

        IF NEW.employee_id IS DISTINCT FROM public.get_current_employee_id()
           OR NEW.status IS DISTINCT FROM 'Pending'
           OR NEW.approved_by IS NOT NULL
           OR NEW.action_date IS NOT NULL
           OR NEW.calculated_amount IS DISTINCT FROM 0.00 THEN
            RAISE EXCEPTION
                'Employees may only submit their own pending overtime request with no approved amount.';
        END IF;

        RETURN NEW;
    END IF;

    IF public.is_admin_or_hr() THEN
        RETURN NEW;
    END IF;

    IF NOT public.is_department_manager((
        SELECT department_id
        FROM public.employees
        WHERE id = OLD.employee_id
    )) THEN
        RAISE EXCEPTION
            'Only an authorized department manager or HR may review overtime.';
    END IF;

    IF OLD.status IS DISTINCT FROM 'Pending'
       OR NEW.status NOT IN ('Approved', 'Rejected') THEN
        RAISE EXCEPTION
            'Only pending overtime requests can be approved or rejected.';
    END IF;

    IF (to_jsonb(NEW) - ARRAY['status', 'approved_by', 'action_date'])
       IS DISTINCT FROM
       (to_jsonb(OLD) - ARRAY['status', 'approved_by', 'action_date']) THEN
        RAISE EXCEPTION
            'Department managers may not alter overtime calculation inputs or amounts.';
    END IF;

    IF NEW.approved_by IS DISTINCT FROM auth.uid()
       OR NEW.action_date IS NULL THEN
        RAISE EXCEPTION
            'Overtime review must record the authenticated reviewer and action time.';
    END IF;

    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_guard_overtime_request_mutation
    ON public.overtime_requests;

CREATE TRIGGER trg_guard_overtime_request_mutation
BEFORE INSERT OR UPDATE
ON public.overtime_requests
FOR EACH ROW
EXECUTE FUNCTION public.guard_overtime_request_mutation();

CREATE OR REPLACE FUNCTION public.guard_leave_request_review()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
    IF NEW.status IN ('Approved', 'Rejected')
       AND EXISTS (
            SELECT 1
            FROM public.employees
            WHERE id = NEW.employee_id
              AND user_id = auth.uid()
       ) THEN
        RAISE EXCEPTION
            'Users may not approve or reject their own leave request.';
    END IF;

    IF TG_OP = 'INSERT' THEN
        RETURN NEW;
    END IF;

    IF public.is_admin_or_hr() THEN
        IF NEW.status IN ('Approved', 'Rejected')
           AND (
                NEW.approved_by IS DISTINCT FROM auth.uid()
                OR NEW.action_date IS NULL
           ) THEN
            RAISE EXCEPTION
                'Leave review must record the authenticated reviewer and action time.';
        END IF;

        RETURN NEW;
    END IF;

    IF NOT public.is_department_manager((
        SELECT department_id
        FROM public.employees
        WHERE id = OLD.employee_id
    )) THEN
        RAISE EXCEPTION
            'Only an authorized department manager or HR may review leave.';
    END IF;

    IF OLD.status IS DISTINCT FROM 'Pending'
       OR NEW.status NOT IN ('Approved', 'Rejected') THEN
        RAISE EXCEPTION
            'Only pending leave requests can be approved or rejected.';
    END IF;

    IF (to_jsonb(NEW) - ARRAY['status', 'approved_by', 'action_date'])
       IS DISTINCT FROM
       (to_jsonb(OLD) - ARRAY['status', 'approved_by', 'action_date']) THEN
        RAISE EXCEPTION
            'Department managers may not alter submitted leave request details.';
    END IF;

    IF NEW.approved_by IS DISTINCT FROM auth.uid()
       OR NEW.action_date IS NULL THEN
        RAISE EXCEPTION
            'Leave review must record the authenticated reviewer and action time.';
    END IF;

    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_guard_leave_request_review
    ON public.leave_requests;

CREATE TRIGGER trg_guard_leave_request_review
BEFORE INSERT OR UPDATE
ON public.leave_requests
FOR EACH ROW
EXECUTE FUNCTION public.guard_leave_request_review();

DROP POLICY IF EXISTS "Employees create own overtime"
    ON public.overtime_requests;

CREATE POLICY "Employees create own overtime"
ON public.overtime_requests
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    employee_id = public.get_current_employee_id()
    AND status = 'Pending'
    AND approved_by IS NULL
    AND action_date IS NULL
    AND calculated_amount = 0.00
);

DROP POLICY IF EXISTS "Employees create own leave requests"
    ON public.leave_requests;

CREATE POLICY "Employees create own leave requests"
ON public.leave_requests
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    employee_id = public.get_current_employee_id()
    AND status = 'Pending'
    AND approved_by IS NULL
    AND action_date IS NULL
);

DROP POLICY IF EXISTS "System insert audit logs"
    ON public.audit_logs;

DROP POLICY IF EXISTS "Employees insert own attendance"
    ON public.attendance;

CREATE POLICY "Department managers insert department attendance"
ON public.attendance
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.employees
        WHERE employees.id = attendance.employee_id
          AND public.is_department_manager(employees.department_id)
    )
);

CREATE POLICY "Department managers update department attendance"
ON public.attendance
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.employees
        WHERE employees.id = attendance.employee_id
          AND public.is_department_manager(employees.department_id)
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.employees
        WHERE employees.id = attendance.employee_id
          AND public.is_department_manager(employees.department_id)
    )
);

CREATE OR REPLACE FUNCTION public.log_sensitive_workflow_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
    v_old_row JSONB;
    v_new_row JSONB;
    v_before JSONB;
    v_after JSONB;
    v_row JSONB;
    v_entity TEXT;
    v_module TEXT;
    v_activity TEXT;
BEGIN
    IF TG_OP <> 'INSERT' THEN
        v_old_row := to_jsonb(OLD);
    END IF;

    IF TG_OP <> 'DELETE' THEN
        v_new_row := to_jsonb(NEW);
    END IF;

    IF TG_TABLE_NAME = 'attendance' THEN
        v_before := v_old_row - ARRAY['notes'];
        v_after := v_new_row - ARRAY['notes'];
        v_module := 'Attendance';
    ELSIF TG_TABLE_NAME = 'leave_requests' THEN
        v_before := v_old_row - ARRAY['reason'];
        v_after := v_new_row - ARRAY['reason'];
        v_module := 'Leave';
    ELSIF TG_TABLE_NAME = 'overtime_requests' THEN
        v_before := v_old_row - ARRAY['reason', 'attachment_url'];
        v_after := v_new_row - ARRAY['reason', 'attachment_url'];
        v_module := 'Overtime';
    ELSIF TG_TABLE_NAME = 'salary_history' THEN
        v_before := v_old_row;
        v_after := v_new_row;
        v_module := 'Employees';
    ELSE
        v_before := v_old_row - ARRAY['logo_url'];
        v_after := v_new_row - ARRAY['logo_url'];
        v_module := 'Settings';
    END IF;

    v_row := COALESCE(v_new_row, v_old_row);
    v_entity := COALESCE(v_row->>'id', 'unknown');
    v_activity := CASE TG_OP
        WHEN 'INSERT' THEN 'Record created'
        WHEN 'UPDATE' THEN 'Record updated'
        ELSE 'Record deleted'
    END;

    INSERT INTO public.audit_logs (
        user_id, user_name, user_role, module, activity,
        description, target_entity, payload
    )
    VALUES (
        auth.uid(),
        COALESCE(
            (SELECT full_name FROM public.user_profiles WHERE id = auth.uid()),
            'System'
        ),
        COALESCE(
            (SELECT role FROM public.user_profiles WHERE id = auth.uid()),
            'system'
        ),
        v_module,
        v_activity,
        format('%s %s (%s).', v_module, lower(TG_OP), v_entity),
        v_entity,
        jsonb_build_object(
            'operation', TG_OP,
            'before', v_before,
            'after', v_after
        )
    );

    RETURN COALESCE(NEW, OLD);
END;
$function$;

DROP TRIGGER IF EXISTS trg_audit_leave_request_change
    ON public.leave_requests;

CREATE TRIGGER trg_audit_leave_request_change
AFTER INSERT OR UPDATE OR DELETE
ON public.leave_requests
FOR EACH ROW
EXECUTE FUNCTION public.log_sensitive_workflow_change();

DROP TRIGGER IF EXISTS trg_audit_attendance_change
    ON public.attendance;

CREATE TRIGGER trg_audit_attendance_change
AFTER INSERT OR UPDATE OR DELETE
ON public.attendance
FOR EACH ROW
EXECUTE FUNCTION public.log_sensitive_workflow_change();

DROP TRIGGER IF EXISTS trg_audit_overtime_request_change
    ON public.overtime_requests;

CREATE TRIGGER trg_audit_overtime_request_change
AFTER INSERT OR UPDATE OR DELETE
ON public.overtime_requests
FOR EACH ROW
EXECUTE FUNCTION public.log_sensitive_workflow_change();

DROP TRIGGER IF EXISTS trg_audit_salary_history_change
    ON public.salary_history;

CREATE TRIGGER trg_audit_salary_history_change
AFTER INSERT OR UPDATE OR DELETE
ON public.salary_history
FOR EACH ROW
EXECUTE FUNCTION public.log_sensitive_workflow_change();

DROP TRIGGER IF EXISTS trg_audit_company_settings_change
    ON public.company_settings;

CREATE TRIGGER trg_audit_company_settings_change
AFTER INSERT OR UPDATE OR DELETE
ON public.company_settings
FOR EACH ROW
EXECUTE FUNCTION public.log_sensitive_workflow_change();

DROP POLICY IF EXISTS "Employees view own payroll records"
    ON public.payroll_records;

CREATE POLICY "Employees view own payroll records"
ON public.payroll_records
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    employee_id = public.get_current_employee_id()
    AND EXISTS (
        SELECT 1
        FROM public.payslips
        WHERE payslips.payroll_record_id = payroll_records.id
          AND payslips.employee_id = public.get_current_employee_id()
    )
);

DROP POLICY IF EXISTS "Employees view own payroll items"
    ON public.payroll_items;

CREATE POLICY "Employees view own payroll items"
ON public.payroll_items
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.payroll_records
        WHERE payroll_records.id = payroll_items.payroll_record_id
          AND payroll_records.employee_id = public.get_current_employee_id()
    )
);

DROP POLICY IF EXISTS "Employees view periods with own payslips"
    ON public.payroll_periods;

DROP POLICY IF EXISTS "Staff manage payroll periods"
    ON public.payroll_periods;

CREATE POLICY "Staff read payroll periods"
ON public.payroll_periods
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (public.is_admin_or_hr());

CREATE POLICY "Staff create payroll periods"
ON public.payroll_periods
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    public.is_admin_or_hr()
    AND workflow_stage = 1
    AND status = 'DRAFT'
    AND total_gross = 0.00
    AND total_deductions = 0.00
    AND total_net = 0.00
    AND total_employer_cost = 0.00
    AND processed_by IS NULL
    AND processed_at IS NULL
);

DROP POLICY IF EXISTS "Staff manage payroll records"
    ON public.payroll_records;

CREATE POLICY "Staff read payroll records"
ON public.payroll_records
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (public.is_admin_or_hr());

DROP POLICY IF EXISTS "Staff manage payroll items"
    ON public.payroll_items;

CREATE POLICY "Staff read payroll items"
ON public.payroll_items
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (public.is_admin_or_hr());

DROP POLICY IF EXISTS "Staff manage payslips"
    ON public.payslips;

CREATE POLICY "Staff read payslips"
ON public.payslips
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (public.is_admin_or_hr());

CREATE OR REPLACE FUNCTION public.add_other_allowance_payroll_item()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
    v_other_allowance NUMERIC(12,2);
BEGIN
    SELECT other_allowance
    INTO v_other_allowance
    FROM public.salary_history
    WHERE id = NEW.salary_history_id;

    IF COALESCE(v_other_allowance, 0.00) > 0.00 THEN
        INSERT INTO public.payroll_items (
            payroll_record_id, category, name, amount
        )
        VALUES (
            NEW.id, 'earning', 'Other Allowance', v_other_allowance
        );
    END IF;

    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_add_other_allowance_payroll_item
    ON public.payroll_records;

CREATE TRIGGER trg_add_other_allowance_payroll_item
AFTER INSERT
ON public.payroll_records
FOR EACH ROW
EXECUTE FUNCTION public.add_other_allowance_payroll_item();

CREATE OR REPLACE FUNCTION public.generate_period_payslips(p_period_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
    v_period RECORD;
    v_rec RECORD;
    v_count INTEGER := 0;
    v_inserted INTEGER := 0;
BEGIN
    IF NOT public.is_admin_or_hr() THEN
        RAISE EXCEPTION
            'Access Denied: Only Admin or HR Managers can generate payslips.';
    END IF;

    SELECT * INTO v_period
    FROM public.payroll_periods
    WHERE id = p_period_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payroll period not found.';
    END IF;

    IF v_period.workflow_stage <> 3 THEN
        RAISE EXCEPTION
            'Payslips can only be generated for approved payroll (Stage 3; current stage: %).',
            v_period.workflow_stage;
    END IF;

    FOR v_rec IN
        SELECT id, employee_id
        FROM public.payroll_records
        WHERE payroll_period_id = p_period_id
    LOOP
        INSERT INTO public.payslips (
            payroll_record_id, employee_id, payroll_period_id,
            status, period_name
        )
        VALUES (
            v_rec.id, v_rec.employee_id, p_period_id,
            'Pending', v_period.period_name
        )
        ON CONFLICT (payroll_record_id) DO NOTHING;

        GET DIAGNOSTICS v_inserted = ROW_COUNT;
        v_count := v_count + v_inserted;
    END LOOP;

    -- Issuing payslips is not evidence that wages were paid.
    UPDATE public.payroll_periods
    SET status = 'APPROVED',
        workflow_stage = 3
    WHERE id = p_period_id;

    INSERT INTO public.audit_logs (
        user_id, user_name, user_role, module, activity,
        description, target_entity
    )
    VALUES (
        auth.uid(),
        COALESCE(
            (SELECT full_name FROM public.user_profiles WHERE id = auth.uid()),
            'System Admin'
        ),
        COALESCE(
            (SELECT role FROM public.user_profiles WHERE id = auth.uid()),
            'admin'
        ),
        'Payroll',
        'Payslips generated',
        format(
            'Created %s payslip ledger records for period %s.',
            v_count, v_period.period_name
        ),
        v_period.period_name
    );

    RETURN jsonb_build_object(
        'success', true,
        'period_id', p_period_id,
        'payslips_created', v_count,
        'workflow_stage', 3,
        'status', 'APPROVED'
    );
END;
$function$;

COMMIT;