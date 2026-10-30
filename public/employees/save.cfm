<!--- Create / update action. POST only, CSRF verified, server-side validated. Never renders HTML. --->
<cfinclude template="/app/views/init.cfm">
<cfscript>
    requirePost(root & "employees/index.cfm");

    empId   = toId(form.id ?: "");
    backUrl = root & "employees/form.cfm" & (empId ? "?id=" & empId : "");
    requireCsrf(backUrl);

    result = empId ? svc.update(empId, form) : svc.create(form);

    if (result.success) {
        flash.add("success", empId
            ? "#result.values.name# was updated successfully."
            : "#result.values.name# was added to the directory.");
        location(url = root & "employees/view.cfm?id=" & result.id, addToken = false);
    }

    if (structKeyExists(result, "notFound")) {
        flash.add("warning", "That employee no longer exists.");
        location(url = root & "employees/index.cfm", addToken = false);
    }

    // Validation or database failure: return to the form with the input and messages preserved
    flash.stashForm(empId, result.values, result.errors);
    flash.add("danger", structKeyExists(result.errors, "_general")
        ? result.errors._general
        : "The employee was not saved. Please fix the highlighted fields.");
    location(url = backUrl, addToken = false);
</cfscript>
