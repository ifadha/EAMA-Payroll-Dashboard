-- ============================================================
-- EAMA PAYROLL — SUPABASE SCHEMA / AUDIT REFERENCE
-- Generated from live Supabase metadata supplied by the user.
--
-- IMPORTANT:
-- This is a reconstructed schema reference, NOT a pg_dump backup.
-- It is intended for code/database auditing and AI-assisted debugging.
-- It should NOT be executed blindly against a production database.
--
-- Source metadata captured:
--   * public table columns/defaults/nullability
--   * primary/foreign keys
--   * indexes/unique indexes
--   * public RLS policies
--   * public functions
--   * public triggers
--   * storage RLS policies
--   * storage bucket query returned NO ROWS
--
-- No application row data is included.
-- ============================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- 1. TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.company_settings (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    standard_monthly_hours numeric NOT NULL DEFAULT 200.00,
    updated_at timestamptz NOT NULL DEFAULT now(),
    company_name text NOT NULL DEFAULT 'EAMA Garments',
    registration_number text NOT NULL DEFAULT 'PV-12345678',
    primary_email text NOT NULL DEFAULT 'admin@eamagarments.com',
    phone_number text NOT NULL DEFAULT '+94 11 234 5678',
    registered_address text NOT NULL DEFAULT '123, Industry Road, Katunayake Export Processing Zone, Sri Lanka',
    logo_url text
);

CREATE TABLE IF NOT EXISTS public.departments (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamptz NOT NULL DEFAULT now(),
    name text NOT NULL,
    description text
);

CREATE TABLE IF NOT EXISTS public.designations (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    department_id uuid NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    title text NOT NULL
);

CREATE TABLE IF NOT EXISTS public.user_profiles (
    id uuid NOT NULL,
    department_id uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    email text NOT NULL,
    full_name text NOT NULL,
    role text NOT NULL DEFAULT 'employee',
    avatar_url text
);

CREATE TABLE IF NOT EXISTS public.employees (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid,
    date_of_birth date,
    department_id uuid NOT NULL,
    designation_id uuid NOT NULL,
    manager_id uuid,
    joining_date date NOT NULL DEFAULT CURRENT_DATE,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    employee_number text NOT NULL,
    full_name text NOT NULL,
    nic_passport text,
    gender text,
    phone text,
    email text NOT NULL,
    residential_address text,
    avatar_url text,
    employment_type text NOT NULL DEFAULT 'Full-time',
    status text NOT NULL DEFAULT 'Active',
    emergency_contact_name text,
    emergency_contact_phone text
);

CREATE TABLE IF NOT EXISTS public.salary_history (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    employee_id uuid NOT NULL,
    basic_salary numeric NOT NULL,
    ot_hourly_rate numeric NOT NULL DEFAULT 0.00,
    housing_allowance numeric NOT NULL DEFAULT 0.00,
    transport_allowance numeric NOT NULL DEFAULT 0.00,
    other_allowance numeric NOT NULL DEFAULT 0.00,
    fixed_deduction numeric NOT NULL DEFAULT 0.00,
    effective_from date NOT NULL,
    effective_to date,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.statutory_configs (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    epf_employee_rate numeric NOT NULL DEFAULT 8.00,
    epf_employer_rate numeric NOT NULL DEFAULT 12.00,
    etf_employer_rate numeric NOT NULL DEFAULT 3.00,
    apit_tax_slabs jsonb NOT NULL DEFAULT '[]'::jsonb,
    effective_from date NOT NULL,
    effective_to date,
    created_at timestamptz NOT NULL DEFAULT now(),
    config_name text NOT NULL
);

CREATE TABLE IF NOT EXISTS public.attendance (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    employee_id uuid NOT NULL,
    date date NOT NULL,
    check_in time,
    check_out time,
    total_hours numeric NOT NULL DEFAULT 0.00,
    raw_overtime_hours numeric NOT NULL DEFAULT 0.00,
    created_at timestamptz NOT NULL DEFAULT now(),
    status text NOT NULL,
    notes text
);

CREATE TABLE IF NOT EXISTS public.leave_types (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    annual_allocation numeric NOT NULL DEFAULT 14.0,
    is_paid boolean NOT NULL DEFAULT true,
    name text NOT NULL
);

CREATE TABLE IF NOT EXISTS public.leave_balances (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    employee_id uuid NOT NULL,
    leave_type_id uuid NOT NULL,
    year integer NOT NULL DEFAULT EXTRACT(year FROM CURRENT_DATE),
    total_allocated numeric NOT NULL DEFAULT 14.0,
    used_days numeric NOT NULL DEFAULT 0.0,
    pending_days numeric NOT NULL DEFAULT 0.0,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.leave_requests (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    employee_id uuid NOT NULL,
    leave_type_id uuid NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    total_days numeric NOT NULL,
    approved_by uuid,
    action_date timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    reason text,
    status text NOT NULL DEFAULT 'Pending'
);

CREATE TABLE IF NOT EXISTS public.overtime_requests (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    employee_id uuid NOT NULL,
    date date NOT NULL,
    hours numeric NOT NULL,
    rate_multiplier numeric NOT NULL DEFAULT 1.50,
    calculated_amount numeric NOT NULL DEFAULT 0.00,
    approved_by uuid,
    action_date timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    overtime_type text NOT NULL DEFAULT 'Normal',
    reason text,
    attachment_url text,
    status text NOT NULL DEFAULT 'Pending'
);

CREATE TABLE IF NOT EXISTS public.payroll_periods (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    start_date date NOT NULL,
    end_date date NOT NULL,
    workflow_stage integer NOT NULL DEFAULT 1,
    total_gross numeric NOT NULL DEFAULT 0.00,
    total_deductions numeric NOT NULL DEFAULT 0.00,
    total_net numeric NOT NULL DEFAULT 0.00,
    total_employer_cost numeric NOT NULL DEFAULT 0.00,
    processed_by uuid,
    processed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    period_name text NOT NULL,
    status text NOT NULL DEFAULT 'DRAFT'
);

CREATE TABLE IF NOT EXISTS public.payroll_records (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    payroll_period_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    salary_history_id uuid NOT NULL,
    basic_salary numeric NOT NULL,
    total_allowances numeric NOT NULL DEFAULT 0.00,
    overtime_hours numeric NOT NULL DEFAULT 0.00,
    overtime_pay numeric NOT NULL DEFAULT 0.00,
    other_earnings numeric NOT NULL DEFAULT 0.00,
    gross_salary numeric NOT NULL,
    epf_employee_amount numeric NOT NULL DEFAULT 0.00,
    epf_employer_amount numeric NOT NULL DEFAULT 0.00,
    etf_employer_amount numeric NOT NULL DEFAULT 0.00,
    paye_tax numeric NOT NULL DEFAULT 0.00,
    no_pay_deduction numeric NOT NULL DEFAULT 0.00,
    loan_deduction numeric NOT NULL DEFAULT 0.00,
    salary_advance numeric NOT NULL DEFAULT 0.00,
    insurance_deduction numeric NOT NULL DEFAULT 0.00,
    total_deductions numeric NOT NULL,
    net_salary numeric NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    employee_number text NOT NULL,
    employee_name text NOT NULL,
    department_name text NOT NULL,
    designation_title text NOT NULL,
    status text NOT NULL DEFAULT 'DRAFT'
);

CREATE TABLE IF NOT EXISTS public.payroll_items (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    payroll_record_id uuid NOT NULL,
    amount numeric NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    category text NOT NULL,
    name text NOT NULL
);

CREATE TABLE IF NOT EXISTS public.payslips (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    payroll_record_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    payroll_period_id uuid NOT NULL,
    sent_at timestamptz,
    viewed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    pdf_url text,
    status text NOT NULL DEFAULT 'Pending'
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid,
    payload jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    source text NOT NULL DEFAULT 'Web Dashboard',
    user_name text NOT NULL,
    user_role text NOT NULL,
    module text NOT NULL,
    activity text NOT NULL,
    description text NOT NULL,
    target_entity text,
    ip_address text
);

-- ============================================================
-- 2. PRIMARY / FOREIGN KEYS
-- ============================================================

ALTER TABLE public.company_settings
    ADD CONSTRAINT company_settings_pkey PRIMARY KEY (id);

ALTER TABLE public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);

ALTER TABLE public.designations
    ADD CONSTRAINT designations_pkey PRIMARY KEY (id);

ALTER TABLE public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);

ALTER TABLE public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);

ALTER TABLE public.salary_history
    ADD CONSTRAINT salary_history_pkey PRIMARY KEY (id);

ALTER TABLE public.statutory_configs
    ADD CONSTRAINT statutory_configs_pkey PRIMARY KEY (id);

ALTER TABLE public.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (id);

ALTER TABLE public.leave_types
    ADD CONSTRAINT leave_types_pkey PRIMARY KEY (id);

ALTER TABLE public.leave_balances
    ADD CONSTRAINT leave_balances_pkey PRIMARY KEY (id);

ALTER TABLE public.leave_requests
    ADD CONSTRAINT leave_requests_pkey PRIMARY KEY (id);

ALTER TABLE public.overtime_requests
    ADD CONSTRAINT overtime_requests_pkey PRIMARY KEY (id);

ALTER TABLE public.payroll_periods
    ADD CONSTRAINT payroll_periods_pkey PRIMARY KEY (id);

ALTER TABLE public.payroll_records
    ADD CONSTRAINT payroll_records_pkey PRIMARY KEY (id);

ALTER TABLE public.payroll_items
    ADD CONSTRAINT payroll_items_pkey PRIMARY KEY (id);

ALTER TABLE public.payslips
    ADD CONSTRAINT payslips_pkey PRIMARY KEY (id);

ALTER TABLE public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);

ALTER TABLE public.designations
    ADD CONSTRAINT designations_department_id_fkey
    FOREIGN KEY (department_id) REFERENCES public.departments(id);

ALTER TABLE public.user_profiles
    ADD CONSTRAINT user_profiles_id_fkey
    FOREIGN KEY (id) REFERENCES auth.users(id);

ALTER TABLE public.user_profiles
    ADD CONSTRAINT user_profiles_department_id_fkey
    FOREIGN KEY (department_id) REFERENCES public.departments(id);

ALTER TABLE public.employees
    ADD CONSTRAINT employees_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.user_profiles(id);

ALTER TABLE public.employees
    ADD CONSTRAINT employees_department_id_fkey
    FOREIGN KEY (department_id) REFERENCES public.departments(id);

ALTER TABLE public.employees
    ADD CONSTRAINT employees_designation_id_fkey
    FOREIGN KEY (designation_id) REFERENCES public.designations(id);

ALTER TABLE public.employees
    ADD CONSTRAINT employees_manager_id_fkey
    FOREIGN KEY (manager_id) REFERENCES public.employees(id);

ALTER TABLE public.salary_history
    ADD CONSTRAINT salary_history_employee_id_fkey
    FOREIGN KEY (employee_id) REFERENCES public.employees(id);

ALTER TABLE public.attendance
    ADD CONSTRAINT attendance_employee_id_fkey
    FOREIGN KEY (employee_id) REFERENCES public.employees(id);

ALTER TABLE public.leave_balances
    ADD CONSTRAINT leave_balances_employee_id_fkey
    FOREIGN KEY (employee_id) REFERENCES public.employees(id);

ALTER TABLE public.leave_balances
    ADD CONSTRAINT leave_balances_leave_type_id_fkey
    FOREIGN KEY (leave_type_id) REFERENCES public.leave_types(id);

ALTER TABLE public.leave_requests
    ADD CONSTRAINT leave_requests_employee_id_fkey
    FOREIGN KEY (employee_id) REFERENCES public.employees(id);

ALTER TABLE public.leave_requests
    ADD CONSTRAINT leave_requests_leave_type_id_fkey
    FOREIGN KEY (leave_type_id) REFERENCES public.leave_types(id);

ALTER TABLE public.leave_requests
    ADD CONSTRAINT leave_requests_approved_by_fkey
    FOREIGN KEY (approved_by) REFERENCES public.user_profiles(id);

ALTER TABLE public.overtime_requests
    ADD CONSTRAINT overtime_requests_employee_id_fkey
    FOREIGN KEY (employee_id) REFERENCES public.employees(id);

ALTER TABLE public.overtime_requests
    ADD CONSTRAINT overtime_requests_approved_by_fkey
    FOREIGN KEY (approved_by) REFERENCES public.user_profiles(id);

ALTER TABLE public.payroll_periods
    ADD CONSTRAINT payroll_periods_processed_by_fkey
    FOREIGN KEY (processed_by) REFERENCES public.user_profiles(id);

ALTER TABLE public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.user_profiles(id);

ALTER TABLE public.payroll_records
    ADD CONSTRAINT payroll_records_payroll_period_id_fkey
    FOREIGN KEY (payroll_period_id) REFERENCES public.payroll_periods(id);

ALTER TABLE public.payroll_records
    ADD CONSTRAINT payroll_records_employee_id_fkey
    FOREIGN KEY (employee_id) REFERENCES public.employees(id);

ALTER TABLE public.payroll_records
    ADD CONSTRAINT payroll_records_salary_history_id_fkey
    FOREIGN KEY (salary_history_id) REFERENCES public.salary_history(id);

ALTER TABLE public.payroll_items
    ADD CONSTRAINT payroll_items_payroll_record_id_fkey
    FOREIGN KEY (payroll_record_id) REFERENCES public.payroll_records(id);

ALTER TABLE public.payslips
    ADD CONSTRAINT payslips_payroll_record_id_fkey
    FOREIGN KEY (payroll_record_id) REFERENCES public.payroll_records(id);

ALTER TABLE public.payslips
    ADD CONSTRAINT payslips_employee_id_fkey
    FOREIGN KEY (employee_id) REFERENCES public.employees(id);

ALTER TABLE public.payslips
    ADD CONSTRAINT payslips_payroll_period_id_fkey
    FOREIGN KEY (payroll_period_id) REFERENCES public.payroll_periods(id);

-- ============================================================
-- 3. UNIQUE CONSTRAINTS / INDEXES
-- ============================================================

CREATE UNIQUE INDEX IF NOT EXISTS departments_name_key
    ON public.departments USING btree (name);

CREATE UNIQUE INDEX IF NOT EXISTS uq_dept_designation
    ON public.designations USING btree (department_id, title);

CREATE UNIQUE INDEX IF NOT EXISTS employees_email_key
    ON public.employees USING btree (email);

CREATE UNIQUE INDEX IF NOT EXISTS employees_employee_number_key
    ON public.employees USING btree (employee_number);

CREATE UNIQUE INDEX IF NOT EXISTS employees_user_id_key
    ON public.employees USING btree (user_id);

CREATE UNIQUE INDEX IF NOT EXISTS user_profiles_email_key
    ON public.user_profiles USING btree (email);

CREATE UNIQUE INDEX IF NOT EXISTS leave_types_name_key
    ON public.leave_types USING btree (name);

CREATE UNIQUE INDEX IF NOT EXISTS uq_emp_leave_balance
    ON public.leave_balances USING btree (employee_id, leave_type_id, year);

CREATE UNIQUE INDEX IF NOT EXISTS uq_emp_attendance_date
    ON public.attendance USING btree (employee_id, date);

CREATE UNIQUE INDEX IF NOT EXISTS payroll_periods_period_name_key
    ON public.payroll_periods USING btree (period_name);

CREATE UNIQUE INDEX IF NOT EXISTS uq_period_employee
    ON public.payroll_records USING btree (payroll_period_id, employee_id);

CREATE UNIQUE INDEX IF NOT EXISTS payslips_payroll_record_id_key
    ON public.payslips USING btree (payroll_record_id);

CREATE INDEX IF NOT EXISTS idx_attendance_date_emp
    ON public.attendance USING btree (date, employee_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_module_time
    ON public.audit_logs USING btree (module, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_leave_requests_emp_dates
    ON public.leave_requests USING btree (employee_id, start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_overtime_requests_emp_date
    ON public.overtime_requests USING btree (employee_id, date, status);

CREATE INDEX IF NOT EXISTS idx_payroll_items_record
    ON public.payroll_items USING btree (payroll_record_id);

CREATE INDEX IF NOT EXISTS idx_payroll_records_period_emp
    ON public.payroll_records USING btree (payroll_period_id, employee_id);

CREATE INDEX IF NOT EXISTS idx_salary_history_lookup
    ON public.salary_history USING btree (employee_id, effective_from, effective_to);

-- ============================================================
-- 4. FUNCTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION public.is_admin_or_hr()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.user_profiles
        WHERE id = auth.uid()
          AND role IN ('admin', 'hr_manager')
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.is_department_manager(p_dept_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.user_profiles
        WHERE id = auth.uid()
          AND role = 'department_manager'
          AND department_id = p_dept_id
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_current_employee_id()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
    RETURN (
        SELECT id
        FROM public.employees
        WHERE user_id = auth.uid()
        LIMIT 1
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_apit_tax(
    p_taxable_income numeric,
    p_slabs jsonb
)
RETURNS numeric
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
    v_slab JSONB;
    v_tax NUMERIC(10,2) := 0.00;
    v_remaining_income NUMERIC := p_taxable_income;
    v_slab_limit NUMERIC;
    v_slab_rate NUMERIC;
    v_taxable_in_slab NUMERIC;
BEGIN
    IF p_slabs IS NULL
       OR jsonb_array_length(p_slabs) = 0
       OR p_taxable_income <= 0 THEN
        RETURN 0.00;
    END IF;

    FOR v_slab IN
        SELECT * FROM jsonb_array_elements(p_slabs)
    LOOP
        v_slab_limit := (v_slab->>'limit')::NUMERIC;
        v_slab_rate := (v_slab->>'rate')::NUMERIC;

        IF v_slab_limit IS NULL THEN
            v_tax := v_tax
                + ROUND(v_remaining_income * (v_slab_rate / 100.00), 2);
            v_remaining_income := 0;
            EXIT;
        ELSE
            v_taxable_in_slab := LEAST(v_remaining_income, v_slab_limit);
            v_tax := v_tax
                + ROUND(v_taxable_in_slab * (v_slab_rate / 100.00), 2);
            v_remaining_income := v_remaining_income - v_taxable_in_slab;
        END IF;

        EXIT WHEN v_remaining_income <= 0;
    END LOOP;

    RETURN v_tax;
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_employee_with_salary(
    p_employee_number text,
    p_full_name text,
    p_nic_passport text,
    p_date_of_birth date,
    p_gender text,
    p_phone text,
    p_email text,
    p_residential_address text,
    p_department_id uuid,
    p_designation_id uuid,
    p_joining_date date,
    p_employment_type text,
    p_basic_salary numeric,
    p_ot_hourly_rate numeric DEFAULT 0.00,
    p_housing_allowance numeric DEFAULT 0.00,
    p_transport_allowance numeric DEFAULT 0.00,
    p_other_allowance numeric DEFAULT 0.00,
    p_fixed_deduction numeric DEFAULT 0.00,
    p_manager_id uuid DEFAULT NULL::uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
    v_emp_id UUID;
    v_sal_id UUID;
BEGIN
    IF NOT public.is_admin_or_hr() THEN
        RAISE EXCEPTION 'Access Denied: Only Admin or HR Managers can register employees.';
    END IF;

    INSERT INTO public.employees (
        employee_number, full_name, nic_passport, date_of_birth, gender,
        phone, email, residential_address, department_id, designation_id,
        joining_date, employment_type, manager_id
    )
    VALUES (
        p_employee_number, p_full_name, p_nic_passport, p_date_of_birth, p_gender,
        p_phone, p_email, p_residential_address, p_department_id, p_designation_id,
        p_joining_date, p_employment_type, p_manager_id
    )
    RETURNING id INTO v_emp_id;

    INSERT INTO public.salary_history (
        employee_id, basic_salary, ot_hourly_rate, housing_allowance,
        transport_allowance, other_allowance, fixed_deduction,
        effective_from, effective_to
    )
    VALUES (
        v_emp_id, p_basic_salary, p_ot_hourly_rate, p_housing_allowance,
        p_transport_allowance, p_other_allowance, p_fixed_deduction,
        p_joining_date, NULL
    )
    RETURNING id INTO v_sal_id;

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
        'Employees',
        'Employee registered',
        format(
            'Created employee %s (%s) with initial basic salary %s.',
            p_full_name, p_employee_number, p_basic_salary
        ),
        p_employee_number
    );

    RETURN jsonb_build_object(
        'success', true,
        'employee_id', v_emp_id,
        'salary_history_id', v_sal_id
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_monthly_payroll(p_period_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
    v_period RECORD;
    v_statutory RECORD;
    v_emp RECORD;
    v_sal RECORD;
    v_std_hours NUMERIC(5,2);
    v_ot_hours NUMERIC(6,2);
    v_ot_pay NUMERIC(12,2);
    v_no_pay_days NUMERIC(4,1);
    v_no_pay_deduction NUMERIC(10,2);
    v_gross NUMERIC(12,2);
    v_epf_ee NUMERIC(10,2);
    v_epf_er NUMERIC(10,2);
    v_etf_er NUMERIC(10,2);
    v_paye_tax NUMERIC(10,2);
    v_total_allowances NUMERIC(12,2);
    v_total_deductions NUMERIC(12,2);
    v_net NUMERIC(12,2);
    v_record_id UUID;
    v_count INTEGER := 0;
    v_sum_gross NUMERIC(14,2) := 0.00;
    v_sum_deductions NUMERIC(14,2) := 0.00;
    v_sum_net NUMERIC(14,2) := 0.00;
    v_sum_er_cost NUMERIC(14,2) := 0.00;
BEGIN
    IF NOT public.is_admin_or_hr() THEN
        RAISE EXCEPTION 'Access Denied: Only Admin or HR Managers can generate payroll.';
    END IF;

    SELECT * INTO v_period
    FROM public.payroll_periods
    WHERE id = p_period_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payroll period not found.';
    END IF;

    IF v_period.workflow_stage >= 3 THEN
        RAISE EXCEPTION
            'Operation Blocked: Cannot regenerate payroll for an Approved or Finalized period (Stage: %).',
            v_period.workflow_stage;
    END IF;

    SELECT standard_monthly_hours
    INTO v_std_hours
    FROM public.company_settings
    LIMIT 1;

    v_std_hours := COALESCE(v_std_hours, 200.00);

    SELECT * INTO v_statutory
    FROM public.statutory_configs
    WHERE effective_from <= v_period.end_date
      AND (effective_to IS NULL OR effective_to >= v_period.start_date)
    ORDER BY effective_from DESC
    LIMIT 1;

    IF NOT FOUND THEN
        v_statutory.epf_employee_rate := 8.00;
        v_statutory.epf_employer_rate := 12.00;
        v_statutory.etf_employer_rate := 3.00;
        v_statutory.apit_tax_slabs := '[]'::jsonb;
    END IF;

    DELETE FROM public.payroll_records
    WHERE payroll_period_id = p_period_id;

    FOR v_emp IN
        SELECT e.*, d.name AS dept_name, des.title AS desig_title
        FROM public.employees e
        JOIN public.departments d ON d.id = e.department_id
        JOIN public.designations des ON des.id = e.designation_id
        WHERE e.status IN ('Active', 'On Leave')
    LOOP
        SELECT * INTO v_sal
        FROM public.salary_history
        WHERE employee_id = v_emp.id
          AND effective_from <= v_period.end_date
          AND (effective_to IS NULL OR effective_to >= v_period.start_date)
        ORDER BY effective_from DESC
        LIMIT 1;

        IF FOUND THEN
            SELECT
                COALESCE(SUM(hours), 0.00),
                COALESCE(SUM(calculated_amount), 0.00)
            INTO v_ot_hours, v_ot_pay
            FROM public.overtime_requests
            WHERE employee_id = v_emp.id
              AND status = 'Approved'
              AND date BETWEEN v_period.start_date AND v_period.end_date;

            SELECT COALESCE(SUM(total_days), 0.0)
            INTO v_no_pay_days
            FROM public.leave_requests lr
            JOIN public.leave_types lt ON lt.id = lr.leave_type_id
            WHERE lr.employee_id = v_emp.id
              AND lr.status = 'Approved'
              AND lt.is_paid = false
              AND lr.start_date <= v_period.end_date
              AND lr.end_date >= v_period.start_date;

            v_no_pay_deduction :=
                ROUND(v_no_pay_days * (v_sal.basic_salary / 30.00), 2);

            v_total_allowances :=
                v_sal.housing_allowance
                + v_sal.transport_allowance
                + v_sal.other_allowance;

            v_gross := v_sal.basic_salary + v_total_allowances + v_ot_pay;

            v_epf_ee :=
                ROUND(v_sal.basic_salary
                    * (v_statutory.epf_employee_rate / 100.00), 2);

            v_epf_er :=
                ROUND(v_sal.basic_salary
                    * (v_statutory.epf_employer_rate / 100.00), 2);

            v_etf_er :=
                ROUND(v_sal.basic_salary
                    * (v_statutory.etf_employer_rate / 100.00), 2);

            v_paye_tax :=
                public.calculate_apit_tax(
                    v_gross,
                    v_statutory.apit_tax_slabs
                );

            v_total_deductions :=
                v_epf_ee
                + v_paye_tax
                + v_sal.fixed_deduction
                + v_no_pay_deduction;

            v_net := v_gross - v_total_deductions;

            INSERT INTO public.payroll_records (
                payroll_period_id, employee_id, salary_history_id,
                employee_number, employee_name, department_name,
                designation_title, basic_salary, total_allowances,
                overtime_hours, overtime_pay, other_earnings,
                gross_salary, epf_employee_amount, epf_employer_amount,
                etf_employer_amount, paye_tax, no_pay_deduction,
                loan_deduction, salary_advance, insurance_deduction,
                total_deductions, net_salary, status
            )
            VALUES (
                p_period_id, v_emp.id, v_sal.id,
                v_emp.employee_number, v_emp.full_name,
                v_emp.dept_name, v_emp.desig_title,
                v_sal.basic_salary, v_total_allowances,
                v_ot_hours, v_ot_pay, 0.00,
                v_gross, v_epf_ee, v_epf_er, v_etf_er,
                v_paye_tax, v_no_pay_deduction,
                0.00, 0.00, 0.00,
                v_total_deductions, v_net, 'DRAFT'
            )
            RETURNING id INTO v_record_id;

            INSERT INTO public.payroll_items (
                payroll_record_id, category, name, amount
            )
            VALUES
                (v_record_id, 'earning', 'Basic Salary', v_sal.basic_salary),
                (v_record_id, 'earning', 'Housing Allowance', v_sal.housing_allowance),
                (v_record_id, 'earning', 'Transport Allowance', v_sal.transport_allowance),
                (v_record_id, 'earning', 'Overtime Pay', v_ot_pay),
                (
                    v_record_id,
                    'deduction',
                    format('EPF Employee (%s%%)', v_statutory.epf_employee_rate),
                    v_epf_ee
                ),
                (
                    v_record_id,
                    'deduction',
                    'Fixed Deductions',
                    v_sal.fixed_deduction
                ),
                (
                    v_record_id,
                    'employer_contribution',
                    format('EPF Employer (%s%%)', v_statutory.epf_employer_rate),
                    v_epf_er
                ),
                (
                    v_record_id,
                    'employer_contribution',
                    format('ETF Employer (%s%%)', v_statutory.etf_employer_rate),
                    v_etf_er
                );

            IF v_paye_tax > 0 THEN
                INSERT INTO public.payroll_items (
                    payroll_record_id, category, name, amount
                )
                VALUES (
                    v_record_id,
                    'deduction',
                    'PAYE / APIT Tax',
                    v_paye_tax
                );
            END IF;

            IF v_no_pay_deduction > 0 THEN
                INSERT INTO public.payroll_items (
                    payroll_record_id, category, name, amount
                )
                VALUES (
                    v_record_id,
                    'deduction',
                    'No-Pay Deduction',
                    v_no_pay_deduction
                );
            END IF;

            v_count := v_count + 1;
            v_sum_gross := v_sum_gross + v_gross;
            v_sum_deductions := v_sum_deductions + v_total_deductions;
            v_sum_net := v_sum_net + v_net;
            v_sum_er_cost :=
                v_sum_er_cost + v_gross + v_epf_er + v_etf_er;
        END IF;
    END LOOP;

    UPDATE public.payroll_periods
    SET status = 'GENERATED',
        workflow_stage = 2,
        total_gross = v_sum_gross,
        total_deductions = v_sum_deductions,
        total_net = v_sum_net,
        total_employer_cost = v_sum_er_cost,
        processed_by = auth.uid(),
        processed_at = now()
    WHERE id = p_period_id;

    INSERT INTO public.audit_logs (
        user_id, user_name, user_role, module, activity,
        description, target_entity, payload
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
        'Payroll generated',
        format(
            'Generated payroll for %s with %s employees.',
            v_period.period_name, v_count
        ),
        v_period.period_name,
        jsonb_build_object(
            'period_id', p_period_id,
            'employees_processed', v_count,
            'net_payroll', v_sum_net
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'period_id', p_period_id,
        'employees_processed', v_count,
        'total_net', v_sum_net
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.approve_payroll_period(p_period_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
    v_period RECORD;
BEGIN
    IF NOT public.is_admin_or_hr() THEN
        RAISE EXCEPTION 'Access Denied: Only Admin or HR Managers can approve payroll.';
    END IF;

    SELECT * INTO v_period
    FROM public.payroll_periods
    WHERE id = p_period_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payroll period not found.';
    END IF;

    IF v_period.workflow_stage != 2 THEN
        RAISE EXCEPTION
            'Workflow Conflict: Only generated payrolls under review (Stage 2) can be approved (Current Stage: %).',
            v_period.workflow_stage;
    END IF;

    UPDATE public.payroll_records
    SET status = 'APPROVED',
        updated_at = now()
    WHERE payroll_period_id = p_period_id;

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
        'Payroll approved',
        format('Approved payroll period %s.', v_period.period_name),
        v_period.period_name
    );

    RETURN jsonb_build_object(
        'success', true,
        'period_id', p_period_id,
        'workflow_stage', 3,
        'status', 'APPROVED'
    );
END;
$function$;

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
BEGIN
    IF NOT public.is_admin_or_hr() THEN
        RAISE EXCEPTION 'Access Denied: Only Admin or HR Managers can generate payslips.';
    END IF;

    SELECT * INTO v_period
    FROM public.payroll_periods
    WHERE id = p_period_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payroll period not found.';
    END IF;

    IF v_period.workflow_stage < 3 THEN
        RAISE EXCEPTION
            'Workflow Conflict: Cannot generate payslips for unapproved payroll (Current Stage: %).',
            v_period.workflow_stage;
    END IF;

    FOR v_rec IN
        SELECT id, employee_id
        FROM public.payroll_records
        WHERE payroll_period_id = p_period_id
    LOOP
        INSERT INTO public.payslips (
            payroll_record_id, employee_id, payroll_period_id, status
        )
        VALUES (
            v_rec.id, v_rec.employee_id, p_period_id, 'Pending'
        )
        ON CONFLICT (payroll_record_id) DO NOTHING;

        v_count := v_count + 1;
    END LOOP;

    UPDATE public.payroll_periods
    SET status = 'PAID',
        workflow_stage = 4
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
        'workflow_stage', 4
    );
END;
$function$;

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
            'Security Violation: Payroll records in an Approved or Paid period (Stage: %) are strictly immutable.',
            v_stage;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_leave_balance_on_request_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
    v_year INTEGER;
    v_emp_id UUID;
    v_type_id UUID;
BEGIN
    v_year := EXTRACT(year FROM COALESCE(NEW.start_date, OLD.start_date));
    v_emp_id := COALESCE(NEW.employee_id, OLD.employee_id);
    v_type_id := COALESCE(NEW.leave_type_id, OLD.leave_type_id);

    PERFORM 1
    FROM public.leave_balances
    WHERE employee_id = v_emp_id
      AND leave_type_id = v_type_id
      AND year = v_year
    FOR UPDATE;

    IF NOT FOUND THEN
        INSERT INTO public.leave_balances (
            employee_id, leave_type_id, year,
            total_allocated, used_days, pending_days
        )
        VALUES (
            v_emp_id, v_type_id, v_year,
            14.0, 0.0, 0.0
        )
        ON CONFLICT (employee_id, leave_type_id, year) DO NOTHING;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF NEW.status = 'Pending' THEN
            UPDATE public.leave_balances
            SET pending_days = pending_days + NEW.total_days,
                updated_at = now()
            WHERE employee_id = v_emp_id
              AND leave_type_id = v_type_id
              AND year = v_year;
        ELSIF NEW.status = 'Approved' THEN
            UPDATE public.leave_balances
            SET used_days = used_days + NEW.total_days,
                updated_at = now()
            WHERE employee_id = v_emp_id
              AND leave_type_id = v_type_id
              AND year = v_year;
        END IF;

    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status = 'Pending' AND NEW.status = 'Approved' THEN
            UPDATE public.leave_balances
            SET pending_days = GREATEST(0.0, pending_days - OLD.total_days),
                used_days = used_days + NEW.total_days,
                updated_at = now()
            WHERE employee_id = v_emp_id
              AND leave_type_id = v_type_id
              AND year = v_year;

        ELSIF OLD.status = 'Pending'
              AND NEW.status IN ('Rejected', 'Cancelled') THEN
            UPDATE public.leave_balances
            SET pending_days = GREATEST(0.0, pending_days - OLD.total_days),
                updated_at = now()
            WHERE employee_id = v_emp_id
              AND leave_type_id = v_type_id
              AND year = v_year;

        ELSIF OLD.status = 'Approved' AND NEW.status = 'Cancelled' THEN
            UPDATE public.leave_balances
            SET used_days = GREATEST(0.0, used_days - OLD.total_days),
                updated_at = now()
            WHERE employee_id = v_emp_id
              AND leave_type_id = v_type_id
              AND year = v_year;
        END IF;

    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.status = 'Pending' THEN
            UPDATE public.leave_balances
            SET pending_days = GREATEST(0.0, pending_days - OLD.total_days),
                updated_at = now()
            WHERE employee_id = v_emp_id
              AND leave_type_id = v_type_id
              AND year = v_year;

        ELSIF OLD.status = 'Approved' THEN
            UPDATE public.leave_balances
            SET used_days = GREATEST(0.0, used_days - OLD.total_days),
                updated_at = now()
            WHERE employee_id = v_emp_id
              AND leave_type_id = v_type_id
              AND year = v_year;
        END IF;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$function$;

-- ============================================================
-- 5. TRIGGERS
-- ============================================================

CREATE TRIGGER trg_leave_request_sync
AFTER INSERT OR DELETE OR UPDATE
ON public.leave_requests
FOR EACH ROW
EXECUTE FUNCTION public.sync_leave_balance_on_request_change();

CREATE TRIGGER trg_guard_payroll_record_update
BEFORE DELETE OR UPDATE
ON public.payroll_records
FOR EACH ROW
EXECUTE FUNCTION public.guard_payroll_record_mutation();

-- ============================================================
-- 6. ENABLE RLS
-- ============================================================

ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.designations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.overtime_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payslips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.statutory_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 7. PUBLIC RLS POLICIES
-- ============================================================

CREATE POLICY "Department managers view department attendance"
ON public.attendance
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.employees
        WHERE employees.id = attendance.employee_id
          AND public.is_department_manager(employees.department_id)
    )
);

CREATE POLICY "Employees insert own attendance"
ON public.attendance
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    employee_id = public.get_current_employee_id()
);

CREATE POLICY "Employees view own attendance"
ON public.attendance
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    employee_id = public.get_current_employee_id()
);

CREATE POLICY "Staff manage attendance"
ON public.attendance
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Staff read audit logs"
ON public.audit_logs
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (public.is_admin_or_hr());

CREATE POLICY "System insert audit logs"
ON public.audit_logs
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Public read company settings"
ON public.company_settings
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Staff manage company settings"
ON public.company_settings
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Public read departments"
ON public.departments
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Staff manage departments"
ON public.departments
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Public read designations"
ON public.designations
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Staff manage designations"
ON public.designations
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Department managers view department employees"
ON public.employees
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (public.is_department_manager(department_id));

CREATE POLICY "Employees view self"
ON public.employees
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Staff manage employees"
ON public.employees
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Employees view own leave balance"
ON public.leave_balances
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (employee_id = public.get_current_employee_id());

CREATE POLICY "Staff manage leave balances"
ON public.leave_balances
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Department managers update department leave"
ON public.leave_requests
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.employees
        WHERE employees.id = leave_requests.employee_id
          AND public.is_department_manager(employees.department_id)
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.employees
        WHERE employees.id = leave_requests.employee_id
          AND public.is_department_manager(employees.department_id)
    )
);

CREATE POLICY "Department managers view department leave"
ON public.leave_requests
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.employees
        WHERE employees.id = leave_requests.employee_id
          AND public.is_department_manager(employees.department_id)
    )
);

CREATE POLICY "Employees create own leave requests"
ON public.leave_requests
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    employee_id = public.get_current_employee_id()
);

CREATE POLICY "Employees view own leave requests"
ON public.leave_requests
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    employee_id = public.get_current_employee_id()
);

CREATE POLICY "Staff manage leave requests"
ON public.leave_requests
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Public read leave types"
ON public.leave_types
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Staff manage leave types"
ON public.leave_types
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Department managers update department overtime"
ON public.overtime_requests
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.employees
        WHERE employees.id = overtime_requests.employee_id
          AND public.is_department_manager(employees.department_id)
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.employees
        WHERE employees.id = overtime_requests.employee_id
          AND public.is_department_manager(employees.department_id)
    )
);

CREATE POLICY "Department managers view department overtime"
ON public.overtime_requests
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.employees
        WHERE employees.id = overtime_requests.employee_id
          AND public.is_department_manager(employees.department_id)
    )
);

CREATE POLICY "Employees create own overtime"
ON public.overtime_requests
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    employee_id = public.get_current_employee_id()
);

CREATE POLICY "Employees view own overtime"
ON public.overtime_requests
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    employee_id = public.get_current_employee_id()
);

CREATE POLICY "Staff manage overtime requests"
ON public.overtime_requests
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Staff manage payroll items"
ON public.payroll_items
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Staff manage payroll periods"
ON public.payroll_periods
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Staff manage payroll records"
ON public.payroll_records
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Employees view own payslips"
ON public.payslips
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    employee_id = public.get_current_employee_id()
);

CREATE POLICY "Staff manage payslips"
ON public.payslips
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Employees view own salary history"
ON public.salary_history
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    employee_id = public.get_current_employee_id()
);

CREATE POLICY "Staff manage salary history"
ON public.salary_history
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Public read statutory configs"
ON public.statutory_configs
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Staff manage statutory configs"
ON public.statutory_configs
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Admin manage user profiles"
ON public.user_profiles
AS PERMISSIVE
FOR ALL
TO authenticated
USING (public.is_admin_or_hr())
WITH CHECK (public.is_admin_or_hr());

CREATE POLICY "Users read own profile"
ON public.user_profiles
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    (id = auth.uid())
    OR public.is_admin_or_hr()
);

-- ============================================================
-- 8. STORAGE POLICY REFERENCE
-- ============================================================
--
-- IMPORTANT: The live query against storage.buckets returned
-- NO ROWS. Therefore these policies reference buckets that were
-- not present in the live bucket listing at the time of audit.
--
-- The policies themselves existed in pg_policies.
-- They are reproduced below for reference only.
-- DO NOT create buckets based on this section until the frontend
-- is audited and the intended storage architecture is confirmed.
-- ============================================================

CREATE POLICY "Admin manage company assets"
ON storage.objects
AS PERMISSIVE
FOR ALL
TO authenticated
USING (
    bucket_id = 'company-assets'
    AND public.is_admin_or_hr()
)
WITH CHECK (
    bucket_id = 'company-assets'
    AND public.is_admin_or_hr()
);

CREATE POLICY "Admin/HR manage all payslips"
ON storage.objects
AS PERMISSIVE
FOR ALL
TO authenticated
USING (
    bucket_id = 'payslips'
    AND public.is_admin_or_hr()
)
WITH CHECK (
    bucket_id = 'payslips'
    AND public.is_admin_or_hr()
);

CREATE POLICY "Department managers view department overtime attachments"
ON storage.objects
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    bucket_id = 'overtime-attachments'
    AND EXISTS (
        SELECT 1
        FROM public.employees
        WHERE employees.id::text = (storage.foldername(objects.name))[1]
          AND public.is_department_manager(employees.department_id)
    )
);

CREATE POLICY "Employees download own payslips"
ON storage.objects
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    bucket_id = 'payslips'
    AND (storage.foldername(name))[1] = (
        SELECT employees.id::text
        FROM public.employees
        WHERE employees.user_id = auth.uid()
    )
);

CREATE POLICY "Employees upload own overtime attachments"
ON storage.objects
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'overtime-attachments'
    AND (storage.foldername(name))[1] = (
        SELECT employees.id::text
        FROM public.employees
        WHERE employees.user_id = auth.uid()
    )
);

CREATE POLICY "Public read company assets"
ON storage.objects
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    bucket_id = 'company-assets'
);

CREATE POLICY "Staff manage all overtime files"
ON storage.objects
AS PERMISSIVE
FOR ALL
TO authenticated
USING (
    bucket_id = 'overtime-attachments'
    AND public.is_admin_or_hr()
)
WITH CHECK (
    bucket_id = 'overtime-attachments'
    AND public.is_admin_or_hr()
);

-- ============================================================
-- 9. AUDIT NOTES / KNOWN LIMITATIONS
-- ============================================================
--
-- A. This file was reconstructed from metadata queries, not
--    generated by pg_dump.
--
-- B. CHECK constraints were not included in the supplied metadata.
--
-- C. Identity/generated-column metadata beyond the supplied
--    column defaults was not independently captured.
--
-- D. Grants/privileges were not captured.
--
-- E. Storage bucket listing returned zero rows, although storage
--    policies referencing three bucket IDs exist.
--
-- F. Auth users themselves are not included.
--
-- G. Application row data is not included.
--
-- H. This file should be treated as an audit/reference artifact,
--    not a production restore script.
--
-- I. The live database remains the source of truth.
--
-- ============================================================

COMMIT;
