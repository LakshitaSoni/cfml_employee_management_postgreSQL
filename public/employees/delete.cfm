<!--- Delete action. POST only, CSRF verified. The confirmation dialog lives in the UI (partials/delete_modal.cfm). --->
<cfinclude template="/app/views/init.cfm">
<cfscript>
    requirePost(root & "employees/index.cfm");

    // Where to return: the directory, keeping the visitor's filters (charset-restricted, our own path only)
    returnQuery = reReplace(left(form.returnQuery ?: "", 300), "[^A-Za-z0-9_=&%.+\-]", "", "all");
    listUrl     = root & "employees/index.cfm" & (len(returnQuery) ? "?" & returnQuery : "");
    requireCsrf(listUrl);

    empId = toId(form.id ?: "");
    if (!empId) {
        flash.add("warning", "No employee was selected.");
        location(url = listUrl, addToken = false);
    }

    result = svc.remove(empId);
    flash.add(result.success ? "success" : "danger",
              result.success ? "#result.name# was deleted." : result.message);
    location(url = listUrl, addToken = false);
</cfscript>
