// ============================================================================
// EAMA PAYROLL SYSTEM — CENTRALIZED SUPABASE CLIENT & UTILITIES
// ============================================================================
// IMPORTANT:
// The Supabase CDN already creates window.supabase.
// DO NOT create `const supabase` because that conflicts with the CDN global.
//
// The initialized application client is stored as:
// window.eamaSupabase
// ============================================================================

(function () {
    'use strict';

    // ------------------------------------------------------------------------
    // SUPABASE CONFIGURATION
    // ------------------------------------------------------------------------

    const SUPABASE_URL =
        window.ENV_SUPABASE_URL ||
        'https://YOUR_SUPABASE_PROJECT_ID.supabase.co';

    const SUPABASE_ANON_KEY =
        window.ENV_SUPABASE_ANON_KEY ||
        'YOUR_SUPABASE_ANON_KEY';


    // ------------------------------------------------------------------------
    // CHECK SUPABASE LIBRARY
    // ------------------------------------------------------------------------

    if (
        !window.supabase ||
        typeof window.supabase.createClient !== 'function'
    ) {
        console.error(
            'CRITICAL: Supabase JS library was not loaded. ' +
            'Make sure the Supabase CDN script appears before supabase-client.js.'
        );

        return;
    }


    // ------------------------------------------------------------------------
    // VALIDATE CONFIGURATION
    // ------------------------------------------------------------------------

    if (
        !SUPABASE_URL ||
        SUPABASE_URL.includes('YOUR_SUPABASE_PROJECT_ID')
    ) {
        console.error(
            'CRITICAL: SUPABASE_URL is not configured. ' +
            'Replace YOUR_SUPABASE_PROJECT_ID with your actual Supabase project ID.'
        );
    }

    if (
        !SUPABASE_ANON_KEY ||
        SUPABASE_ANON_KEY === 'YOUR_SUPABASE_ANON_KEY'
    ) {
        console.error(
            'CRITICAL: SUPABASE_ANON_KEY is not configured.'
        );
    }


    // ------------------------------------------------------------------------
    // CREATE APPLICATION SUPABASE CLIENT
    // ------------------------------------------------------------------------
    // IMPORTANT:
    // Store the client under a DIFFERENT name from window.supabase.
    // ------------------------------------------------------------------------

    window.eamaSupabase = window.supabase.createClient(
        SUPABASE_URL,
        SUPABASE_ANON_KEY
    );


    // Make a short alias available globally.
    // This is safe because `eamaSupabase` does not conflict with the CDN.
    window.db = window.eamaSupabase;


    // ------------------------------------------------------------------------
    // CONFIRM INITIALIZATION
    // ------------------------------------------------------------------------

    if (
        !window.eamaSupabase ||
        typeof window.eamaSupabase.from !== 'function'
    ) {
        console.error(
            'CRITICAL: EAMA Supabase client failed to initialize.'
        );
    } else {
        console.log(
            'EAMA Payroll: Supabase client initialized successfully.'
        );
    }


    // ------------------------------------------------------------------------
    // UNIVERSAL TOAST NOTIFICATION
    // ------------------------------------------------------------------------

    window.showToast = function (message, type = 'info') {

        let container =
            document.getElementById('toast-container');

        if (!container) {

            container = document.createElement('div');

            container.id = 'toast-container';

            container.className =
                'fixed bottom-5 right-5 z-50 flex flex-col gap-2 pointer-events-none';

            document.body.appendChild(container);
        }


        const toast =
            document.createElement('div');


        const bgColors = {
            success: 'bg-[#137333] text-white',
            error: 'bg-[#ba1a1a] text-white',
            warning: 'bg-[#b06000] text-white',
            info: 'bg-[#644aae] text-white'
        };


        const icons = {
            success: 'check_circle',
            error: 'error',
            warning: 'warning',
            info: 'info'
        };


        toast.className =
            `flex items-center gap-3 px-4 py-3 rounded-lg shadow-xl ` +
            `text-sm font-medium pointer-events-auto transition-all ` +
            `duration-300 transform translate-y-4 opacity-0 ` +
            `${bgColors[type] || bgColors.info}`;


        // Use textContent for the message to avoid interpreting
        // arbitrary message content as HTML.
        const icon =
            document.createElement('span');

        icon.className =
            'material-symbols-outlined text-[20px]';

        icon.textContent =
            icons[type] || 'info';


        const text =
            document.createElement('span');

        text.textContent =
            String(message ?? '');


        toast.appendChild(icon);
        toast.appendChild(text);

        container.appendChild(toast);


        setTimeout(() => {
            toast.classList.remove(
                'translate-y-4',
                'opacity-0'
            );
        }, 10);


        setTimeout(() => {

            toast.classList.add(
                'opacity-0',
                'translate-y-2'
            );

            setTimeout(() => {
                toast.remove();
            }, 350);

        }, 4500);
    };


    // ------------------------------------------------------------------------
    // CURRENCY FORMATTER
    // ------------------------------------------------------------------------

    window.formatCurrency = function (amount) {

        const num =
            parseFloat(amount) || 0;

        return (
            'LKR ' +
            num.toLocaleString('en-US', {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2
            })
        );
    };


    // ------------------------------------------------------------------------
    // DATE FORMATTER
    // ------------------------------------------------------------------------

    window.formatDate = function (dateStr) {

        if (!dateStr) {
            return '--';
        }


        const parts =
            String(dateStr).split('-');


        if (parts.length === 3) {

            const d =
                new Date(
                    Number(parts[0]),
                    Number(parts[1]) - 1,
                    Number(parts[2])
                );


            if (!isNaN(d.getTime())) {

                return d.toLocaleDateString(
                    'en-GB',
                    {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric'
                    }
                );
            }
        }


        const d =
            new Date(dateStr);


        return isNaN(d.getTime())
            ? String(dateStr)
            : d.toLocaleDateString(
                'en-GB',
                {
                    day: '2-digit',
                    month: 'short',
                    year: 'numeric'
                }
            );
    };


    // ------------------------------------------------------------------------
    // LOCAL ISO DATE
    // ------------------------------------------------------------------------

    window.formatISODate = function (date = new Date()) {

        const year =
            date.getFullYear();

        const month =
            String(date.getMonth() + 1)
                .padStart(2, '0');

        const day =
            String(date.getDate())
                .padStart(2, '0');

        return `${year}-${month}-${day}`;
    };


    // ------------------------------------------------------------------------
    // GET CURRENT AUTHENTICATED USER
    // ------------------------------------------------------------------------

    window.getCurrentUser = async function () {

        const client =
            window.eamaSupabase;


        if (!client) {
            console.error(
                'getCurrentUser: Supabase client unavailable.'
            );

            return null;
        }


        const {
            data,
            error
        } =
            await client.auth.getUser();


        if (error) {

            console.error(
                'Error getting current user:',
                error
            );

            return null;
        }


        return data?.user || null;
    };


    // ------------------------------------------------------------------------
    // GET CURRENT USER PROFILE
    // ------------------------------------------------------------------------

    window.getCurrentProfile = async function () {

        const client =
            window.eamaSupabase;


        if (!client) {
            return null;
        }


        const user =
            await window.getCurrentUser();


        if (!user) {
            return null;
        }


        const {
            data: profile,
            error
        } =
            await client
                .from('user_profiles')
                .select(`
                    *,
                    department:departments(name)
                `)
                .eq('id', user.id)
                .maybeSingle();


        if (error) {

            console.error(
                'Error fetching user profile:',
                error
            );

            return null;
        }


        return {
            ...user,
            profile
        };
    };


    // ------------------------------------------------------------------------
    // GET CURRENT EMPLOYEE
    // ------------------------------------------------------------------------

    window.getCurrentEmployee = async function () {

        const client =
            window.eamaSupabase;


        if (!client) {
            return null;
        }


        const user =
            await window.getCurrentUser();


        if (!user) {
            return null;
        }


        const {
            data: employee,
            error
        } =
            await client
                .from('employees')
                .select(`
                    *,
                    department:departments(name),
                    designation:designations(title)
                `)
                .eq('user_id', user.id)
                .maybeSingle();


        if (error) {

            console.error(
                'Error fetching current employee:',
                error
            );

            return null;
        }


        return employee;
    };


    // ------------------------------------------------------------------------
    // AUTHENTICATION GUARD
    // ------------------------------------------------------------------------

    window.requireAuth = async function (
        allowedRoles = [
            'admin',
            'hr_manager',
            'department_manager'
        ]
    ) {

        const client =
            window.eamaSupabase;


        if (!client) {

            console.error(
                'Authentication failed: Supabase client unavailable.'
            );

            window.location.href =
                'login.html';

            return null;
        }


        const {
            data: sessionData,
            error: sessionError
        } =
            await client.auth.getSession();


        if (sessionError) {

            console.error(
                'Session error:',
                sessionError
            );

            window.location.href =
                'login.html';

            return null;
        }


        const session =
            sessionData?.session;


        if (!session) {

            window.location.href =
                'login.html';

            return null;
        }


        const current =
            await window.getCurrentProfile();


        if (!current || !current.profile) {

            await client.auth.signOut();

            window.location.href =
                'login.html';

            return null;
        }


        const userRole =
            current.profile.role;


        if (
            allowedRoles.length > 0 &&
            !allowedRoles.includes(userRole)
        ) {

            if (userRole === 'employee') {

                window.location.href =
                    'demo.html';

            } else {

                window.location.href =
                    'login.html';
            }

            return null;
        }


        // Populate authenticated user's name.
        document
            .querySelectorAll('.auth-user-name')
            .forEach(el => {

                el.textContent =
                    current.profile.full_name ||
                    current.email ||
                    'User';
            });


        // Populate authenticated user's role.
        document
            .querySelectorAll('.auth-user-role')
            .forEach(el => {

                el.textContent =
                    String(userRole || '')
                        .replace(/_/g, ' ')
                        .toUpperCase();
            });


        return current;
    };


    // ------------------------------------------------------------------------
    // LOGOUT
    // ------------------------------------------------------------------------

    window.logout = async function () {

        const client =
            window.eamaSupabase;


        if (client) {
            await client.auth.signOut();
        }


        window.location.href =
            'login.html';
    };


    // ------------------------------------------------------------------------
    // UNIVERSAL LOGOUT BUTTONS
    // ------------------------------------------------------------------------

    document.addEventListener(
        'DOMContentLoaded',
        () => {

            document
                .querySelectorAll(
                    '[data-action="logout"]'
                )
                .forEach(button => {

                    button.addEventListener(
                        'click',
                        async event => {

                            event.preventDefault();

                            await window.logout();
                        }
                    );
                });
        }
    );

})();