"use strict";

/*
 * ============================================================
 * EAMA PAYROLL — EMPLOYEES PAGE
 * employee.js
 * ============================================================
 *
 * Requires:
 *     supabase-client.js
 *
 * This file handles:
 *
 *     • Supabase initialization
 *     • Authentication
 *     • Role checking
 *     • Departments
 *     • Designations
 *     • Employees
 *     • Search
 *     • Filters
 *     • Add Employee
 *     • Employee creation RPC
 *     • View Employee
 *     • Edit placeholder
 *     • CSV export
 *     • Logout
 *     • Toast messages
 *
 * ============================================================
 */

(function () {

    /*
     * ========================================================
     * PAGE STATE
     * ========================================================
     */

    let sb = null;

    let currentUser = null;

    let currentProfile = null;

    let employees = [];

    let departments = [];

    let designations = [];

    let filteredEmployees = [];


    /*
     * ========================================================
     * DOM ELEMENTS
     * ========================================================
     */

    const modal =
        document.getElementById("addEmployeeModal");

    const openAddEmployeeBtn =
        document.getElementById("openAddEmployeeBtn");

    const closeModalBtn =
        document.getElementById("closeModalBtn");

    const cancelModalBtn =
        document.getElementById("cancelModalBtn");

    const modalBackdrop =
        document.getElementById("modalBackdrop");

    const form =
        document.getElementById("addEmployeeForm");

    const saveEmployeeBtn =
        document.getElementById("saveEmployeeBtn");

    const saveEmployeeText =
        document.getElementById("saveEmployeeText");

    const saveEmployeeIcon =
        document.getElementById("saveEmployeeIcon");

    const formError =
        document.getElementById("formError");

    const employeesTableBody =
        document.getElementById("employeesTableBody");

    const employeeCountText =
        document.getElementById("employeeCountText");

    const searchInput =
        document.getElementById("searchInput");

    const departmentFilter =
        document.getElementById("departmentFilter");

    const statusFilter =
        document.getElementById("statusFilter");

    const departmentIdInput =
        document.getElementById("departmentId");

    const designationIdInput =
        document.getElementById("designationId");

    const currentUserName =
        document.getElementById("currentUserName");

    const logoutBtn =
        document.getElementById("logoutBtn");

    const exportBtn =
        document.getElementById("exportBtn");

    const mobileMenuBtn =
        document.getElementById("mobileMenuBtn");


    /*
     * ========================================================
     * INITIALIZATION
     * ========================================================
     */

    async function initializePage() {

        try {

            console.log(
                "EAMA Payroll: Initializing Employees page..."
            );


            /*
             * ------------------------------------------------
             * WAIT FOR THE ACTUAL SUPABASE CLIENT
             * ------------------------------------------------
             */

            if (
                typeof window.waitForSupabase !==
                "function"
            ) {

                throw new Error(
                    "waitForSupabase() is not available. " +
                    "Make sure supabase-client.js is loaded before employee.js."
                );

            }


            sb =
                await window.waitForSupabase(
                    10000
                );


            /*
             * ------------------------------------------------
             * VERIFY CLIENT
             * ------------------------------------------------
             */

            if (
                !sb ||
                !sb.auth ||
                typeof sb.from !== "function"
            ) {

                throw new Error(
                    "The Supabase client is not available."
                );

            }


            console.log(
                "EAMA Payroll: Supabase client ready."
            );


            /*
             * ------------------------------------------------
             * CHECK AUTHENTICATION
             * ------------------------------------------------
             */

            const {
                data: userData,
                error: authError
            } =
                await sb.auth.getUser();


            if (authError) {
                throw authError;
            }


            const user =
                userData?.user || null;


            if (!user) {

                console.warn(
                    "EAMA Payroll: No authenticated user."
                );


                window.location.href =
                    "login.html";


                return;

            }


            currentUser =
                user;


            console.log(
                "EAMA Payroll: Authenticated user:",
                user.email
            );


            /*
             * ------------------------------------------------
             * LOAD USER PROFILE
             * ------------------------------------------------
             */

            const {
                data: profile,
                error: profileError
            } =
                await sb
                    .from("user_profiles")
                    .select(
                        "id, email, full_name, role"
                    )
                    .eq(
                        "id",
                        user.id
                    )
                    .maybeSingle();


            if (profileError) {
                throw profileError;
            }


            if (!profile) {

                throw new Error(
                    "Your user profile could not be found."
                );

            }


            currentProfile =
                profile;


            /*
             * ------------------------------------------------
             * CHECK ROLE
             * ------------------------------------------------
             */

            const role =
                String(
                    profile.role || ""
                )
                .trim()
                .toLowerCase();


            console.log(
                "EAMA Payroll: User role:",
                role
            );


            const allowedRoles = [
                "admin",
                "hr_manager"
            ];


            if (
                !allowedRoles.includes(role)
            ) {

                alert(
                    "You do not have permission to manage employees."
                );


                window.location.href =
                    "dashboard.html";


                return;

            }


            /*
             * ------------------------------------------------
             * DISPLAY USER NAME
             * ------------------------------------------------
             */

            if (currentUserName) {

                currentUserName.textContent =
                    profile.full_name ||
                    profile.email ||
                    "User";

            }


            /*
             * ------------------------------------------------
             * LOAD DEPARTMENTS + DESIGNATIONS
             * ------------------------------------------------
             */

            await Promise.all([
                loadDepartments(),
                loadDesignations()
            ]);


            /*
             * ------------------------------------------------
             * LOAD EMPLOYEES
             * ------------------------------------------------
             */

            await loadEmployees();


            console.log(
                "EAMA Payroll: Employees page ready."
            );

        } catch (error) {

            console.error(
                "EAMA Payroll: Employees page initialization failed:",
                error
            );


            showTableError(
                getFriendlyError(error)
            );

        }

    }


    /*
     * ========================================================
     * LOAD DEPARTMENTS
     * ========================================================
     */

    async function loadDepartments() {

        console.log(
            "EAMA Payroll: Loading departments..."
        );


        if (!sb) {

            throw new Error(
                "Supabase client is not ready."
            );

        }


        const {
            data,
            error
        } =
            await sb
                .from("departments")
                .select("id, name")
                .order(
                    "name",
                    {
                        ascending: true
                    }
                );


        if (error) {
            throw error;
        }


        departments =
            Array.isArray(data)
                ? data
                : [];


        /*
         * ------------------------------------------------
         * FORM DEPARTMENT DROPDOWN
         * ------------------------------------------------
         */

        if (departmentIdInput) {

            departmentIdInput.innerHTML =
                `<option value="">Select Department</option>`;


            departments.forEach(
                function (department) {

                    const option =
                        document.createElement(
                            "option"
                        );


                    option.value =
                        department.id;


                    option.textContent =
                        department.name;


                    departmentIdInput.appendChild(
                        option
                    );

                }
            );

        }


        /*
         * ------------------------------------------------
         * FILTER DEPARTMENT DROPDOWN
         * ------------------------------------------------
         */

        if (departmentFilter) {

            departmentFilter.innerHTML =
                `<option value="">All Departments</option>`;


            departments.forEach(
                function (department) {

                    const option =
                        document.createElement(
                            "option"
                        );


                    option.value =
                        department.id;


                    option.textContent =
                        department.name;


                    departmentFilter.appendChild(
                        option
                    );

                }
            );

        }


        console.log(
            "EAMA Payroll: Departments loaded:",
            departments.length
        );

    }


    /*
     * ========================================================
     * LOAD DESIGNATIONS
     * ========================================================
     */

    async function loadDesignations() {

        console.log(
            "EAMA Payroll: Loading designations..."
        );


        if (!sb) {

            throw new Error(
                "Supabase client is not ready."
            );

        }


        const {
            data,
            error
        } =
            await sb
                .from("designations")
                .select(
                    "id, title"
                )
                .order(
                    "title",
                    {
                        ascending: true
                    }
                );


        if (error) {
            throw error;
        }


        designations =
            Array.isArray(data)
                ? data
                : [];


        /*
         * ------------------------------------------------
         * FORM DESIGNATION DROPDOWN
         * ------------------------------------------------
         */

        if (designationIdInput) {

            designationIdInput.innerHTML =
                `<option value="">Select Designation</option>`;


            designations.forEach(
                function (designation) {

                    const option =
                        document.createElement(
                            "option"
                        );


                    option.value =
                        designation.id;


                    option.textContent =
                        designation.title;


                    designationIdInput.appendChild(
                        option
                    );

                }
            );

        }


        console.log(
            "EAMA Payroll: Designations loaded:",
            designations.length
        );

    }


    /*
     * ========================================================
     * LOAD EMPLOYEES
     * ========================================================
     */

    async function loadEmployees() {

        if (!sb) {

            throw new Error(
                "Supabase client is not ready."
            );

        }


        showLoadingTable();


        console.log(
            "EAMA Payroll: Loading employees..."
        );


        const {
            data,
            error
        } =
            await sb
                .from("employees")
                .select(`
                    *,
                    department:departments(
                        id,
                        name
                    ),
                    designation:designations(
                        id,
                        title
                    )
                `)
                .order(
                    "created_at",
                    {
                        ascending: false
                    }
                );


        if (error) {

            console.error(
                "EAMA Payroll: Employee query failed:",
                error
            );


            throw error;

        }


        employees =
            Array.isArray(data)
                ? data
                : [];


        console.log(
            "EAMA Payroll: Employees loaded:",
            employees.length
        );


        applyFilters();

    }


    /*
     * ========================================================
     * APPLY FILTERS
     * ========================================================
     */

    function applyFilters() {

        const searchTerm =
            String(
                searchInput?.value || ""
            )
            .trim()
            .toLowerCase();


        const selectedDepartment =
            String(
                departmentFilter?.value || ""
            );


        const selectedStatus =
            String(
                statusFilter?.value || ""
            );


        filteredEmployees =
            employees.filter(
                function (employee) {

                    const name =
                        String(
                            employee.full_name || ""
                        )
                        .toLowerCase();


                    const employeeNumber =
                        String(
                            employee.employee_number || ""
                        )
                        .toLowerCase();


                    const email =
                        String(
                            employee.email || ""
                        )
                        .toLowerCase();


                    const phone =
                        String(
                            employee.phone || ""
                        )
                        .toLowerCase();


                    const matchesSearch =
                        !searchTerm ||
                        name.includes(searchTerm) ||
                        employeeNumber.includes(searchTerm) ||
                        email.includes(searchTerm) ||
                        phone.includes(searchTerm);


                    const matchesDepartment =
                        !selectedDepartment ||
                        String(
                            employee.department_id || ""
                        ) === selectedDepartment ||
                        String(
                            employee.department?.id || ""
                        ) === selectedDepartment;


                    const matchesStatus =
                        !selectedStatus ||
                        normalizeStatus(
                            employee.status
                        ) ===
                        normalizeStatus(
                            selectedStatus
                        );


                    return (
                        matchesSearch &&
                        matchesDepartment &&
                        matchesStatus
                    );

                }
            );


        renderEmployees();

    }


    /*
     * ========================================================
     * RENDER EMPLOYEES
     * ========================================================
     */

    function renderEmployees() {

        if (!employeesTableBody) {
            return;
        }


        if (!filteredEmployees.length) {

            employeesTableBody.innerHTML = `
                <tr>
                    <td colspan="6" class="py-16 text-center">
                        <div class="flex flex-col items-center gap-3 text-on-surface-variant">

                            <span class="material-symbols-outlined text-4xl">
                                person_off
                            </span>

                            <div class="font-semibold text-on-surface">
                                No employees found
                            </div>

                            <div class="text-sm">
                                Try changing your search or filters.
                            </div>

                        </div>
                    </td>
                </tr>
            `;


            if (employeeCountText) {

                employeeCountText.textContent =
                    "Showing 0 employees";

            }


            return;

        }


        employeesTableBody.innerHTML =
            "";


        filteredEmployees.forEach(
            function (employee) {

                const row =
                    createEmployeeRow(
                        employee
                    );


                employeesTableBody.appendChild(
                    row
                );

            }
        );


        if (employeeCountText) {

            employeeCountText.innerHTML =
                `
                Showing
                <span class="font-semibold text-on-surface">
                    1
                </span>
                to
                <span class="font-semibold text-on-surface">
                    ${filteredEmployees.length}
                </span>
                of
                <span class="font-semibold text-on-surface">
                    ${employees.length}
                </span>
                employees
                `;

        }

    }


    /*
     * ========================================================
     * CREATE EMPLOYEE ROW
     * ========================================================
     */

    function createEmployeeRow(employee) {

        const row =
            document.createElement(
                "tr"
            );


        row.className =
            "hover:bg-surface-container-low transition-colors group";


        const departmentName =
            employee.department?.name ||
            getDepartmentName(
                employee.department_id
            ) ||
            "—";


        const designationName =
            employee.designation?.title ||
            getDesignationName(
                employee.designation_id
            ) ||
            "—";


        const employeeStatus =
            employee.status ||
            "Active";


        const employmentType =
            employee.employment_type ||
            "—";


        const joiningDate =
            formatDate(
                employee.joining_date
            );


        const initials =
            getInitials(
                employee.full_name
            );


        row.innerHTML = `
            <td class="py-4 px-6 text-on-surface-variant">
                ${escapeHtml(
                    employee.employee_number || "—"
                )}
            </td>

            <td class="py-4 px-6">

                <div class="flex items-center gap-3">

                    <div class="w-10 h-10 rounded-full bg-secondary-container text-primary flex items-center justify-center font-semibold shrink-0">
                        ${escapeHtml(initials)}
                    </div>

                    <div class="min-w-0">

                        <div class="font-semibold text-on-surface truncate">
                            ${escapeHtml(
                                employee.full_name ||
                                "Unnamed Employee"
                            )}
                        </div>

                        <div class="text-xs text-on-surface-variant mt-0.5 truncate">
                            ${escapeHtml(
                                employee.email ||
                                "No email"
                            )}
                        </div>

                    </div>

                </div>

            </td>

            <td class="py-4 px-6">

                <div class="text-on-surface">
                    ${escapeHtml(departmentName)}
                </div>

                <div class="text-xs text-on-surface-variant mt-0.5">
                    ${escapeHtml(designationName)}
                </div>

            </td>

            <td class="py-4 px-6">

                <div class="text-on-surface">
                    ${escapeHtml(employmentType)}
                </div>

                <div class="text-xs text-on-surface-variant mt-0.5">
                    Joined:
                    ${escapeHtml(joiningDate)}
                </div>

            </td>

            <td class="py-4 px-6">
                ${getStatusMarkup(employeeStatus)}
            </td>

            <td class="py-4 px-6 text-right">

                <div class="flex justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">

                    <button
                        type="button"
                        data-action="view"
                        data-id="${escapeHtml(employee.id)}"
                        class="p-1.5 text-on-surface-variant hover:text-primary hover:bg-surface-container rounded-md transition-colors"
                        title="View Profile">

                        <span class="material-symbols-outlined text-xl">
                            visibility
                        </span>

                    </button>

                    <button
                        type="button"
                        data-action="edit"
                        data-id="${escapeHtml(employee.id)}"
                        class="p-1.5 text-on-surface-variant hover:text-primary hover:bg-surface-container rounded-md transition-colors"
                        title="Edit">

                        <span class="material-symbols-outlined text-xl">
                            edit
                        </span>

                    </button>

                </div>

            </td>
        `;


        return row;

    }


    /*
     * ========================================================
     * STATUS BADGE
     * ========================================================
     */

    function getStatusMarkup(status) {

        const normalized =
            normalizeStatus(status);


        if (normalized === "active") {

            return `
                <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-[#E6F4EA] text-[#137333]">
                    <span class="w-1.5 h-1.5 rounded-full bg-[#137333] mr-1.5"></span>
                    Active
                </span>
            `;

        }


        if (normalized === "on leave") {

            return `
                <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-[#FEF7E0] text-[#B06000]">
                    <span class="w-1.5 h-1.5 rounded-full bg-[#B06000] mr-1.5"></span>
                    On Leave
                </span>
            `;

        }


        if (normalized === "inactive") {

            return `
                <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-[#F1F3F4] text-[#5F6368]">
                    <span class="w-1.5 h-1.5 rounded-full bg-[#5F6368] mr-1.5"></span>
                    Inactive
                </span>
            `;

        }


        return `
            <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-[#F1F3F4] text-[#5F6368]">
                <span class="w-1.5 h-1.5 rounded-full bg-[#5F6368] mr-1.5"></span>
                ${escapeHtml(status || "Unknown")}
            </span>
        `;

    }


    /*
     * ========================================================
     * NORMALIZE STATUS
     * ========================================================
     */

    function normalizeStatus(status) {

        const value =
            String(
                status || ""
            )
            .trim()
            .toLowerCase();


        if (value === "active") {
            return "active";
        }


        if (
            value === "on leave" ||
            value === "leave"
        ) {

            return "on leave";

        }


        if (value === "inactive") {
            return "inactive";
        }


        return value;

    }


    /*
     * ========================================================
     * OPEN MODAL
     * ========================================================
     */

    function openModal() {

        if (!modal) {
            return;
        }


        clearFormError();


        if (form) {
            form.reset();
        }


        const otHourlyRate =
            document.getElementById(
                "otHourlyRate"
            );


        if (otHourlyRate) {

            otHourlyRate.value =
                "0";

        }


        modal.classList.remove(
            "hidden"
        );


        setTimeout(
            function () {

                document
                    .getElementById(
                        "fullName"
                    )
                    ?.focus();

            },
            100
        );

    }


    /*
     * ========================================================
     * CLOSE MODAL
     * ========================================================
     */

    function closeModal() {

        if (!modal) {
            return;
        }


        modal.classList.add(
            "hidden"
        );


        clearFormError();

    }


    /*
     * ========================================================
     * MODAL EVENTS
     * ========================================================
     */

    openAddEmployeeBtn?.addEventListener(
        "click",
        openModal
    );


    closeModalBtn?.addEventListener(
        "click",
        closeModal
    );


    cancelModalBtn?.addEventListener(
        "click",
        closeModal
    );


    modalBackdrop?.addEventListener(
        "click",
        closeModal
    );


    document.addEventListener(
        "keydown",
        function (event) {

            if (
                event.key === "Escape" &&
                modal &&
                !modal.classList.contains(
                    "hidden"
                )
            ) {

                closeModal();

            }

        }
    );


    /*
     * ========================================================
     * ADD EMPLOYEE
     * ========================================================
     */

    form?.addEventListener(
        "submit",
        async function (event) {

            event.preventDefault();


            if (!sb) {

                showFormError(
                    "Supabase is not ready. Please reload the page."
                );


                return;

            }


            if (!currentUser) {

                showFormError(
                    "Your session has expired. Please sign in again."
                );


                return;

            }


            clearFormError();


            if (
                saveEmployeeBtn &&
                saveEmployeeBtn.disabled
            ) {

                return;

            }


            setSavingState(true);


            try {

                const formData =
                    new FormData(form);


                /*
                 * -----------------------------------------
                 * FORM VALUES
                 * -----------------------------------------
                 */

                const employeeNumber =
                    getFormValue(
                        formData,
                        "employeeNumber"
                    );


                const fullName =
                    getFormValue(
                        formData,
                        "fullName"
                    );


                const nicPassport =
                    getFormValue(
                        formData,
                        "nicPassport"
                    );


                const dateOfBirth =
                    getFormValue(
                        formData,
                        "dateOfBirth"
                    );


                const gender =
                    getFormValue(
                        formData,
                        "gender"
                    );


                const phone =
                    getFormValue(
                        formData,
                        "phone"
                    );


                const email =
                    getFormValue(
                        formData,
                        "email"
                    );


                const residentialAddress =
                    getFormValue(
                        formData,
                        "residentialAddress"
                    );


                const departmentId =
                    getFormValue(
                        formData,
                        "departmentId"
                    );


                const designationId =
                    getFormValue(
                        formData,
                        "designationId"
                    );


                const joiningDate =
                    getFormValue(
                        formData,
                        "joiningDate"
                    );


                const employmentType =
                    getFormValue(
                        formData,
                        "employmentType"
                    );


                const basicSalaryRaw =
                    formData.get(
                        "basicSalary"
                    );


                const otHourlyRateRaw =
                    formData.get(
                        "otHourlyRate"
                    );


                const basicSalary =
                    Number(
                        basicSalaryRaw
                    );


                const otHourlyRate =
                    Number(
                        otHourlyRateRaw || 0
                    );


                /*
                 * -----------------------------------------
                 * VALIDATION
                 * -----------------------------------------
                 */

                if (!employeeNumber) {

                    throw new Error(
                        "Employee ID is required."
                    );

                }


                if (!fullName) {

                    throw new Error(
                        "Full name is required."
                    );

                }


                if (!email) {

                    throw new Error(
                        "Email address is required."
                    );

                }


                if (!isValidEmail(email)) {

                    throw new Error(
                        "Please enter a valid email address."
                    );

                }


                if (!departmentId) {

                    throw new Error(
                        "Please select a department."
                    );

                }


                if (!designationId) {

                    throw new Error(
                        "Please select a designation."
                    );

                }


                if (!joiningDate) {

                    throw new Error(
                        "Joining date is required."
                    );

                }


                if (
                    !Number.isFinite(
                        basicSalary
                    ) ||
                    basicSalary < 0
                ) {

                    throw new Error(
                        "Please enter a valid basic salary."
                    );

                }


                if (
                    !Number.isFinite(
                        otHourlyRate
                    ) ||
                    otHourlyRate < 0
                ) {

                    throw new Error(
                        "Please enter a valid OT hourly rate."
                    );

                }


                /*
                 * -----------------------------------------
                 * CREATE EMPLOYEE
                 * -----------------------------------------
                 */

                console.log(
                    "EAMA Payroll: Calling create_employee_with_salary..."
                );


                const {
                    data,
                    error
                } =
                    await sb.rpc(
                        "create_employee_with_salary",
                        {
                            p_employee_number:
                                employeeNumber,

                            p_full_name:
                                fullName,

                            p_nic_passport:
                                nicPassport ||
                                null,

                            p_date_of_birth:
                                dateOfBirth ||
                                null,

                            p_gender:
                                gender ||
                                null,

                            p_phone:
                                phone ||
                                null,

                            p_email:
                                email,

                            p_residential_address:
                                residentialAddress ||
                                null,

                            p_department_id:
                                departmentId,

                            p_designation_id:
                                designationId,

                            p_joining_date:
                                joiningDate,

                            p_employment_type:
                                employmentType ||
                                "Full-time",

                            p_basic_salary:
                                basicSalary,

                            p_ot_hourly_rate:
                                otHourlyRate
                        }
                    );


                if (error) {

                    console.error(
                        "EAMA Payroll: RPC error:",
                        error
                    );


                    throw error;

                }


                console.log(
                    "EAMA Payroll: Employee created successfully:",
                    data
                );


                /*
                 * -----------------------------------------
                 * RESET FORM
                 * -----------------------------------------
                 */

                if (form) {
                    form.reset();
                }


                const otInput =
                    document.getElementById(
                        "otHourlyRate"
                    );


                if (otInput) {

                    otInput.value =
                        "0";

                }


                /*
                 * -----------------------------------------
                 * CLOSE MODAL
                 * -----------------------------------------
                 */

                closeModal();


                /*
                 * -----------------------------------------
                 * REFRESH LIST
                 * -----------------------------------------
                 */

                await loadEmployees();


                /*
                 * -----------------------------------------
                 * SUCCESS
                 * -----------------------------------------
                 */

                showToast(
                    "Employee created successfully.",
                    "success"
                );


                const createdId =
                    extractCreatedEmployeeId(
                        data
                    );


                if (createdId) {

                    console.log(
                        "EAMA Payroll: New employee ID:",
                        createdId
                    );

                }

            } catch (error) {

                console.error(
                    "EAMA Payroll: Employee creation failed:",
                    error
                );


                showFormError(
                    getFriendlySupabaseError(
                        error
                    )
                );

            } finally {

                setSavingState(
                    false
                );

            }

        }
    );


    /*
     * ========================================================
     * EXTRACT CREATED EMPLOYEE ID
     * ========================================================
     */

    function extractCreatedEmployeeId(data) {

        if (
            data === null ||
            data === undefined
        ) {

            return null;

        }


        if (
            typeof data === "string" ||
            typeof data === "number"
        ) {

            return String(data);

        }


        if (Array.isArray(data)) {

            if (!data.length) {
                return null;
            }


            return extractCreatedEmployeeId(
                data[0]
            );

        }


        if (
            typeof data === "object"
        ) {

            return (
                data.id ||
                data.employee_id ||
                data.employeeId ||
                null
            );

        }


        return null;

    }


    /*
     * ========================================================
     * SAVING STATE
     * ========================================================
     */

    function setSavingState(isSaving) {

        if (saveEmployeeBtn) {

            saveEmployeeBtn.disabled =
                isSaving;

        }


        if (saveEmployeeText) {

            saveEmployeeText.textContent =
                isSaving
                    ? "Saving..."
                    : "Save Employee";

        }


        if (saveEmployeeIcon) {

            saveEmployeeIcon.textContent =
                isSaving
                    ? "progress_activity"
                    : "save";


            saveEmployeeIcon.classList.toggle(
                "animate-spin",
                isSaving
            );

        }

    }


    /*
     * ========================================================
     * TABLE ACTIONS
     * ========================================================
     */

    employeesTableBody?.addEventListener(
        "click",
        function (event) {

            const button =
                event.target.closest(
                    "button[data-action]"
                );


            if (!button) {
                return;
            }


            const action =
                button.dataset.action;


            const employeeId =
                button.dataset.id;


            if (!employeeId) {
                return;
            }


            if (action === "view") {

                window.location.href =
                    "employee-profile.html?id=" +
                    encodeURIComponent(
                        employeeId
                    );


                return;

            }


            if (action === "edit") {

                showToast(
                    "Employee editing has not been connected yet.",
                    "info"
                );


                return;

            }

        }
    );


    /*
     * ========================================================
     * SEARCH
     * ========================================================
     */

    searchInput?.addEventListener(
        "input",
        applyFilters
    );


    /*
     * ========================================================
     * DEPARTMENT FILTER
     * ========================================================
     */

    departmentFilter?.addEventListener(
        "change",
        applyFilters
    );


    /*
     * ========================================================
     * STATUS FILTER
     * ========================================================
     */

    statusFilter?.addEventListener(
        "change",
        applyFilters
    );


    /*
     * ========================================================
     * EXPORT CSV
     * ========================================================
     */

    exportBtn?.addEventListener(
        "click",
        exportEmployees
    );


    function exportEmployees() {

        if (!filteredEmployees.length) {

            showToast(
                "There are no employees to export.",
                "info"
            );


            return;

        }


        const headers = [
            "Employee ID",
            "Full Name",
            "NIC / Passport",
            "Date of Birth",
            "Gender",
            "Phone",
            "Email",
            "Residential Address",
            "Department",
            "Designation",
            "Employment Type",
            "Joining Date",
            "Status",
            "Basic Salary",
            "OT Hourly Rate"
        ];


        const rows =
            filteredEmployees.map(
                function (employee) {

                    return [

                        employee.employee_number || "",

                        employee.full_name || "",

                        employee.nic_passport || "",

                        employee.date_of_birth || "",

                        employee.gender || "",

                        employee.phone || "",

                        employee.email || "",

                        employee.residential_address || "",

                        employee.department?.name ||
                        getDepartmentName(
                            employee.department_id
                        ) ||
                        "",

                        employee.designation?.title ||
                        getDesignationName(
                            employee.designation_id
                        ) ||
                        "",

                        employee.employment_type || "",

                        employee.joining_date || "",

                        employee.status || "",

                        employee.basic_salary ?? "",

                        employee.ot_hourly_rate ?? ""

                    ];

                }
            );


        const csv =
            [
                headers,
                ...rows
            ]
            .map(
                function (row) {

                    return row
                        .map(csvEscape)
                        .join(",");

                }
            )
            .join("\r\n");


        const blob =
            new Blob(
                [csv],
                {
                    type:
                        "text/csv;charset=utf-8;"
                }
            );


        const url =
            URL.createObjectURL(
                blob
            );


        const link =
            document.createElement(
                "a"
            );


        link.href =
            url;


        link.download =
            "eama-employees-" +
            new Date()
                .toISOString()
                .slice(0, 10) +
            ".csv";


        document.body.appendChild(
            link
        );


        link.click();


        link.remove();


        URL.revokeObjectURL(
            url
        );


        showToast(
            "Employee list exported successfully.",
            "success"
        );

    }


    /*
     * ========================================================
     * LOGOUT
     * ========================================================
     */

    logoutBtn?.addEventListener(
        "click",
        async function () {

            if (!sb) {

                window.location.href =
                    "login.html";


                return;

            }


            try {

                logoutBtn.disabled =
                    true;


                const {
                    error
                } =
                    await sb.auth.signOut();


                if (error) {
                    throw error;
                }


                window.location.href =
                    "login.html";


            } catch (error) {

                console.error(
                    "EAMA Payroll: Logout failed:",
                    error
                );


                logoutBtn.disabled =
                    false;


                showToast(
                    "Unable to log out. Please try again.",
                    "error"
                );

            }

        }
    );


    /*
     * ========================================================
     * MOBILE MENU
     * ========================================================
     */

    mobileMenuBtn?.addEventListener(
        "click",
        function () {

            const sidebar =
                document.querySelector(
                    "nav"
                );


            if (!sidebar) {
                return;
            }


            sidebar.classList.toggle(
                "hidden"
            );


            sidebar.classList.toggle(
                "flex"
            );

        }
    );


    /*
     * ========================================================
     * GET DEPARTMENT NAME
     * ========================================================
     */

    function getDepartmentName(id) {

        if (
            id === null ||
            id === undefined ||
            id === ""
        ) {

            return "";

        }


        const department =
            departments.find(
                function (item) {

                    return String(item.id) ===
                        String(id);

                }
            );


        return department?.name || "";

    }


    /*
     * ========================================================
     * GET DESIGNATION NAME
     * ========================================================
     */

    function getDesignationName(id) {

        if (
            id === null ||
            id === undefined ||
            id === ""
        ) {

            return "";

        }


        const designation =
            designations.find(
                function (item) {

                    return String(item.id) ===
                        String(id);

                }
            );


        return designation?.title || "";

    }


    /*
     * ========================================================
     * FORMAT DATE
     * ========================================================
     */

    function formatDate(dateString) {

        if (!dateString) {
            return "—";
        }


        const date =
            new Date(
                `${dateString}T00:00:00`
            );


        if (
            Number.isNaN(
                date.getTime()
            )
        ) {

            return String(
                dateString
            );

        }


        return date.toLocaleDateString(
            "en-GB",
            {
                day: "2-digit",
                month: "short",
                year: "numeric"
            }
        );

    }


    /*
     * ========================================================
     * GET INITIALS
     * ========================================================
     */

    function getInitials(name) {

        if (!name) {
            return "?";
        }


        const parts =
            String(name)
                .trim()
                .split(/\s+/)
                .filter(Boolean);


        if (!parts.length) {
            return "?";
        }


        if (parts.length === 1) {

            return parts[0]
                .substring(0, 2)
                .toUpperCase();

        }


        return (
            parts[0].charAt(0) +
            parts[parts.length - 1].charAt(0)
        )
        .toUpperCase();

    }


    /*
     * ========================================================
     * ESCAPE HTML
     * ========================================================
     */

    function escapeHtml(value) {

        return String(
            value ?? ""
        )
        .replace(
            /&/g,
            "&amp;"
        )
        .replace(
            /</g,
            "&lt;"
        )
        .replace(
            />/g,
            "&gt;"
        )
        .replace(
            /"/g,
            "&quot;"
        )
        .replace(
            /'/g,
            "&#039;"
        );

    }


    /*
     * ========================================================
     * CSV ESCAPE
     * ========================================================
     */

    function csvEscape(value) {

        const stringValue =
            String(
                value ?? ""
            );


        if (
            stringValue.includes(",") ||
            stringValue.includes('"') ||
            stringValue.includes("\n") ||
            stringValue.includes("\r")
        ) {

            return (
                '"' +
                stringValue.replace(
                    /"/g,
                    '""'
                ) +
                '"'
            );

        }


        return stringValue;

    }


    /*
     * ========================================================
     * FORM VALUE
     * ========================================================
     */

    function getFormValue(
        formData,
        fieldName
    ) {

        return String(
            formData.get(fieldName) || ""
        )
        .trim();

    }


    /*
     * ========================================================
     * EMAIL VALIDATION
     * ========================================================
     */

    function isValidEmail(email) {

        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/
            .test(email);

    }


    /*
     * ========================================================
     * LOADING TABLE
     * ========================================================
     */

    function showLoadingTable() {

        if (!employeesTableBody) {
            return;
        }


        employeesTableBody.innerHTML = `
            <tr>
                <td colspan="6"
                    class="py-12 text-center text-on-surface-variant">

                    <div class="flex flex-col items-center gap-3">

                        <span class="material-symbols-outlined text-3xl animate-spin">
                            progress_activity
                        </span>

                        <span>
                            Loading employees...
                        </span>

                    </div>

                </td>
            </tr>
        `;


        if (employeeCountText) {

            employeeCountText.textContent =
                "Loading...";

        }

    }


    /*
     * ========================================================
     * TABLE ERROR
     * ========================================================
     */

    function showTableError(message) {

        if (!employeesTableBody) {
            return;
        }


        employeesTableBody.innerHTML = `
            <tr>

                <td colspan="6"
                    class="py-16 text-center">

                    <div class="flex flex-col items-center gap-3 text-error">

                        <span class="material-symbols-outlined text-4xl">
                            error
                        </span>

                        <div class="font-semibold">
                            Failed to load employees
                        </div>

                        <div class="text-sm max-w-lg">
                            ${escapeHtml(message)}
                        </div>

                        <button
                            type="button"
                            id="retryEmployeesBtn"
                            class="mt-2 px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-container transition-colors">

                            Retry

                        </button>

                    </div>

                </td>

            </tr>
        `;


        if (employeeCountText) {

            employeeCountText.textContent =
                "Unable to load employees";

        }


        document
            .getElementById(
                "retryEmployeesBtn"
            )
            ?.addEventListener(
                "click",
                async function () {

                    try {

                        if (!sb) {

                            sb =
                                await window.waitForSupabase(
                                    10000
                                );

                        }


                        await loadEmployees();


                    } catch (error) {

                        console.error(
                            "EAMA Payroll: Retry failed:",
                            error
                        );


                        showTableError(
                            getFriendlyError(
                                error
                            )
                        );

                    }

                }
            );

    }


    /*
     * ========================================================
     * FORM ERROR
     * ========================================================
     */

    function showFormError(message) {

        if (!formError) {
            return;
        }


        formError.textContent =
            message;


        formError.classList.remove(
            "hidden"
        );


        formError.scrollIntoView({
            behavior: "smooth",
            block: "nearest"
        });

    }


    function clearFormError() {

        if (!formError) {
            return;
        }


        formError.textContent =
            "";


        formError.classList.add(
            "hidden"
        );

    }


    /*
     * ========================================================
     * FRIENDLY SUPABASE ERROR
     * ========================================================
     */

    function getFriendlySupabaseError(error) {

        const message =
            String(
                error?.message ||
                error?.details ||
                error?.hint ||
                "An unexpected error occurred."
            );


        const lower =
            message.toLowerCase();


        /*
         * DUPLICATE
         */

        if (
            lower.includes("duplicate") ||
            lower.includes("unique") ||
            lower.includes("already exists")
        ) {

            return (
                "An employee with this Employee ID " +
                "or another unique value already exists."
            );

        }


        /*
         * FOREIGN KEY
         */

        if (
            lower.includes("foreign key") ||
            (
                lower.includes("violates") &&
                lower.includes("fkey")
            )
        ) {

            return (
                "The selected department or designation " +
                "is invalid. Please refresh the page " +
                "and try again."
            );

        }


        /*
         * PERMISSION / RLS
         */

        if (
            lower.includes("permission") ||
            lower.includes("row-level security") ||
            lower.includes("rls") ||
            error?.code === "42501"
        ) {

            return (
                "You do not have permission to perform " +
                "this action."
            );

        }


        /*
         * RPC NOT FOUND
         */

        if (
            lower.includes("function") &&
            (
                lower.includes("does not exist") ||
                lower.includes("not found")
            )
        ) {

            return (
                "The employee creation database function " +
                "could not be found. Please check that " +
                "create_employee_with_salary exists in Supabase."
            );

        }


        /*
         * COLUMN NOT FOUND
         */

        if (
            lower.includes("column") &&
            lower.includes("does not exist")
        ) {

            return (
                "The Employees database structure does not " +
                "match this page. Please check the employees table columns."
            );

        }


        /*
         * TABLE NOT FOUND
         */

        if (
            lower.includes("relation") &&
            lower.includes("does not exist")
        ) {

            return (
                "A required Employees database table could not " +
                "be found. Please check the Supabase database schema."
            );

        }


        /*
         * NETWORK
         */

        if (
            lower.includes("network") ||
            lower.includes("failed to fetch")
        ) {

            return (
                "Could not connect to Supabase. " +
                "Please check your internet connection and try again."
            );

        }


        return message;

    }


    /*
     * ========================================================
     * GENERAL FRIENDLY ERROR
     * ========================================================
     */

    function getFriendlyError(error) {

        if (!error) {

            return (
                "An unexpected error occurred."
            );

        }


        return getFriendlySupabaseError(
            error
        );

    }


    /*
     * ========================================================
     * TOAST
     * ========================================================
     */

    function showToast(
        message,
        type = "info"
    ) {

        const existing =
            document.getElementById(
                "eamaToast"
            );


        if (existing) {
            existing.remove();
        }


        const toast =
            document.createElement(
                "div"
            );


        toast.id =
            "eamaToast";


        let classes =
            "fixed bottom-6 right-6 z-[100] " +
            "px-5 py-3 rounded-xl shadow-lg " +
            "text-sm font-medium flex items-center gap-3";


        if (type === "success") {

            classes +=
                " bg-[#E6F4EA] text-[#137333]";

        }
        else if (type === "error") {

            classes +=
                " bg-error-container text-on-error-container";

        }
        else {

            classes +=
                " bg-surface-container-high text-on-surface";

        }


        toast.className =
            classes;


        let icon =
            "info";


        if (type === "success") {

            icon =
                "check_circle";

        }
        else if (type === "error") {

            icon =
                "error";

        }


        toast.innerHTML = `
            <span class="material-symbols-outlined text-lg">
                ${icon}
            </span>

            <span>
                ${escapeHtml(message)}
            </span>
        `;


        document.body.appendChild(
            toast
        );


        setTimeout(
            function () {

                if (
                    toast &&
                    toast.parentNode
                ) {

                    toast.remove();

                }

            },
            4000
        );

    }


    /*
     * ========================================================
     * START PAGE
     * ========================================================
     */

    initializePage();

})();