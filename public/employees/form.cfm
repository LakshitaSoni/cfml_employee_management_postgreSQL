<cfinclude template="/app/views/init.cfm">
<cfscript>
    empId  = toId(url.id ?: "");
    isEdit = empId > 0;

    if (isEdit) {
        employee = svc.get(empId);
        if (structIsEmpty(employee)) {
            flash.add("warning", "That employee could not be found.");
            location(url = root & "employees/index.cfm", addToken = false);
        }
    }

    // Values: previously submitted (after a validation error) > stored record > defaults
    state  = flash.popForm(empId);
    errors = structKeyExists(state, "errors") ? state.errors : {};
    if (structKeyExists(state, "values")) {
        vals = state.values;
    } else if (isEdit) {
        vals = {
            name = employee.name, email = employee.email, phone = employee.phone,
            department = employee.department, job_title = employee.job_title,
            salary = isNumeric(employee.salary) ? numberFormat(employee.salary, "0.00") : "",
            joining_date = view.isoDate(employee.joining_date), status = employee.status
        };
    } else {
        vals = {name = "", email = "", phone = "", department = "", job_title = "", salary = "",
                joining_date = dateFormat(now(), "yyyy-mm-dd"), status = "Active"};
    }

    request.pageTitle = isEdit ? "Edit employee" : "Add employee";
    request.activeNav = isEdit ? "employees" : "add";
    departments = svc.departmentOptions(true);

    function invalidClass(required string field) {
        return structKeyExists(errors, arguments.field) ? " is-invalid" : "";
    }
    function feedback(required string field) {
        return structKeyExists(errors, arguments.field)
            ? '<div class="invalid-feedback" data-server>' & h(errors[arguments.field]) & '</div>'
            : '<div class="invalid-feedback"></div>';
    }
</cfscript>
<cfinclude template="/app/views/layout/header.cfm">
<cfoutput>

<nav aria-label="breadcrumb" class="mb-2">
    <ol class="breadcrumb small mb-0">
        <li class="breadcrumb-item"><a href="#root#employees/index.cfm">Employees</a></li>
        <cfif isEdit><li class="breadcrumb-item"><a href="#root#employees/view.cfm?id=#empId#">#h(employee.name)#</a></li></cfif>
        <li class="breadcrumb-item active" aria-current="page">#isEdit ? "Edit" : "Add"#</li>
    </ol>
</nav>

<div class="page-head">
    <div>
        <h1 class="page-title">#isEdit ? "Edit employee" : "Add a new employee"#</h1>
        <p class="page-sub">Fields marked <span class="text-danger">*</span> are required.</p>
    </div>
</div>

<cfif structKeyExists(errors, "_general")>
    <div class="alert alert-danger d-flex align-items-start gap-2" role="alert">
        <i class="bi bi-exclamation-octagon-fill mt-1"></i><div>#h(errors._general)#</div>
    </div>
<cfelseif NOT structIsEmpty(errors)>
    <div class="alert alert-danger d-flex align-items-start gap-2" role="alert">
        <i class="bi bi-exclamation-octagon-fill mt-1"></i><div>Please correct the highlighted fields and try again.</div>
    </div>
</cfif>

<form method="post" action="#root#employees/save.cfm" class="needs-validation" id="employeeForm" novalidate data-loading data-preview-form>
    #csrf.field()#
    <input type="hidden" name="id" value="#empId#">

    <div class="row g-3">
        <div class="col-12 col-xl-8">
            <div class="card form-card mb-3">
                <div class="card-header-row"><h2 class="card-title-sm"><i class="bi bi-person-vcard me-2"></i>Personal information</h2></div>
                <div class="row g-3 p-3 pt-0">
                    <div class="col-12 col-md-6">
                        <label for="name" class="form-label">Full name <span class="text-danger">*</span></label>
                        <input type="text" class="form-control#invalidClass('name')#" id="name" name="name" value="#ha(vals.name)#"
                               required minlength="2" maxlength="100" autocomplete="name" placeholder="e.g. Aarav Mehta" data-preview-name>
                        #feedback("name")#
                    </div>
                    <div class="col-12 col-md-6">
                        <label for="email" class="form-label">Email address <span class="text-danger">*</span></label>
                        <input type="email" class="form-control#invalidClass('email')#" id="email" name="email" value="#ha(vals.email)#"
                               required maxlength="254" autocomplete="email" placeholder="name@company.com">
                        #feedback("email")#
                    </div>
                    <div class="col-12 col-md-6">
                        <label for="phone" class="form-label">Phone <span class="text-secondary small">(optional)</span></label>
                        <input type="tel" class="form-control#invalidClass('phone')#" id="phone" name="phone" value="#ha(vals.phone)#"
                               maxlength="30" pattern="\+?[0-9 ()\-.]{7,30}" autocomplete="tel" placeholder="+91 98765 43210">
                        #feedback("phone")#
                    </div>
                </div>
            </div>

            <div class="card form-card mb-3">
                <div class="card-header-row"><h2 class="card-title-sm"><i class="bi bi-briefcase me-2"></i>Job details</h2></div>
                <div class="row g-3 p-3 pt-0">
                    <div class="col-12 col-md-6">
                        <label for="department" class="form-label">Department <span class="text-danger">*</span></label>
                        <input type="text" class="form-control#invalidClass('department')#" id="department" name="department" value="#ha(vals.department)#"
                               required minlength="2" maxlength="100" list="departmentList" autocomplete="off" placeholder="Choose or type a department" data-preview-dept>
                        <datalist id="departmentList">
                            <cfloop array="#departments#" index="d"><option value="#ha(d)#"></option></cfloop>
                        </datalist>
                        #feedback("department")#
                    </div>
                    <div class="col-12 col-md-6">
                        <label for="job_title" class="form-label">Job title <span class="text-danger">*</span></label>
                        <input type="text" class="form-control#invalidClass('job_title')#" id="job_title" name="job_title" value="#ha(vals.job_title)#"
                               required minlength="2" maxlength="100" placeholder="e.g. Senior Software Engineer" data-preview-title>
                        #feedback("job_title")#
                    </div>
                    <div class="col-12 col-md-4">
                        <label for="salary" class="form-label">Salary <span class="text-secondary small">(annual, optional)</span></label>
                        <div class="input-group has-validation">
                            <span class="input-group-text">#h(cfg.currencySymbol)#</span>
                            <input type="number" class="form-control#invalidClass('salary')#" id="salary" name="salary" value="#ha(vals.salary)#"
                                   min="0" max="9999999999.99" step="0.01" inputmode="decimal" placeholder="0.00">
                            #feedback("salary")#
                        </div>
                    </div>
                    <div class="col-12 col-md-4">
                        <label for="joining_date" class="form-label">Joining date <span class="text-danger">*</span></label>
                        <input type="date" class="form-control#invalidClass('joining_date')#" id="joining_date" name="joining_date" value="#ha(vals.joining_date)#"
                               required min="1950-01-01">
                        #feedback("joining_date")#
                    </div>
                    <div class="col-12 col-md-4">
                        <label for="status" class="form-label">Employment status <span class="text-danger">*</span></label>
                        <select class="form-select#invalidClass('status')#" id="status" name="status" required>
                            <cfloop array="#cfg.statuses#" index="s">
                                <option value="#ha(s)#" #s eq vals.status ? "selected" : ""#>#h(s)#</option>
                            </cfloop>
                        </select>
                        #feedback("status")#
                    </div>
                </div>
            </div>

            <div class="d-flex flex-wrap gap-2">
                <button type="submit" class="btn btn-primary px-4">
                    <span class="btn-label"><i class="bi bi-check2-circle me-1"></i>#isEdit ? "Save changes" : "Create employee"#</span>
                </button>
                <a href="#root#employees/#isEdit ? 'view.cfm?id=' & empId : 'index.cfm'#" class="btn btn-light px-4">Cancel</a>
            </div>
        </div>

        <!--- Live preview --->
        <div class="col-12 col-xl-4">
            <div class="card preview-card">
                <div class="card-header-row"><h2 class="card-title-sm">Profile preview</h2></div>
                <div class="p-3 pt-0 text-center">
                    <span class="avatar avatar-xl #view.avatarColor(vals.name)#" id="previewAvatar">#h(len(vals.name) ? view.initials(vals.name) : "?")#</span>
                    <div class="preview-name" id="previewName">#len(vals.name) ? h(vals.name) : "New employee"#</div>
                    <div class="text-secondary" id="previewTitle">#len(vals.job_title) ? h(vals.job_title) : "Job title"#</div>
                    <div class="text-secondary small" id="previewDept">#len(vals.department) ? h(vals.department) : "Department"#</div>
                </div>
            </div>
            <cfif isEdit>
                <div class="card mt-3">
                    <div class="p-3 small text-secondary">
                        <div><i class="bi bi-plus-circle me-1"></i>Created #h(view.fmtDateTime(employee.created_at))#</div>
                        <div class="mt-1"><i class="bi bi-pencil me-1"></i>Last updated #h(view.fmtDateTime(employee.updated_at))#</div>
                    </div>
                </div>
            </cfif>
        </div>
    </div>
</form>

</cfoutput>
<cfinclude template="/app/views/layout/footer.cfm">
