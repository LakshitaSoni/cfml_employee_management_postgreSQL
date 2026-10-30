<cfprocessingdirective pageEncoding="utf-8">
<cfscript>
    // Shared page setup: service handles and short encoding/formatting helpers.
    svc   = application.employeeService;
    csrf  = application.csrf;
    flash = application.flash;
    view  = application.view;
    cfg   = application.settings;
    root  = request.root;

    function h(any value = "")  { return view.h(arguments.value); }
    function ha(any value = "") { return view.ha(arguments.value); }

    /** Digits only, always >= 0 - used for ids coming from URL or form. */
    function toId(any value = "") {
        return (isSimpleValue(arguments.value) && reFind("^[0-9]{1,9}$", trim(arguments.value))) ? int(trim(arguments.value)) : 0;
    }

    /** POST-only gate used by the action pages. */
    function requirePost(required string redirectTo) {
        if (cgi.request_method != "POST") {
            getPageContext().getResponse().setStatus(405);
            flash.add("warning", "That action must be submitted from the page.");
            location(url = arguments.redirectTo, addToken = false);
        }
    }

    /** CSRF gate used by every state-changing action page. */
    function requireCsrf(required string redirectTo) {
        if (!csrf.verify(structKeyExists(form, "csrf_token") ? form.csrf_token : "")) {
            flash.add("danger", "Your session expired or the request could not be verified. Please try again.");
            location(url = arguments.redirectTo, addToken = false);
        }
    }
</cfscript>
