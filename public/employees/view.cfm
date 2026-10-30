<cfinclude template="/app/views/init.cfm">
<cfscript>
    empId    = toId(url.id ?: "");
    employee = svc.get(empId);
    if (structIsEmpty(employee)) {
        flash.add("warning", "That employee could not be found.");
        location(url = root & "employees/index.cfm", addToken = false);
    }
    request.pageTitle = employee.name;
    request.activeNav = "employees";
    deleteReturnQuery = "";

    function detail(required string icon, required string label, required string valueHtml) {
        return '<div class="detail-item"><span class="detail-icon"><i class="bi ' & arguments.icon & '"></i></span>' &
               '<div><div class="detail-label">' & arguments.label & '</div><div class="detail-value">' &
               (len(arguments.valueHtml) ? arguments.valueHtml : '<span class="text-muted">Not provided</span>') & '</div></div></div>';
    }
</cfscript>
<cfinclude template="/app/views/layout/header.cfm">
<cfoutput>

<nav aria-label="breadcrumb" class="mb-2">
    <ol class="breadcrumb small mb-0">
        <li class="breadcrumb-item"><a href="#root#employees/index.cfm">Employees</a></li>
        <li class="breadcrumb-item active" aria-current="page">#h(employee.name)#</li>
    </ol>
</nav>

<div class="card profile-hero mb-3">
    <div class="profile-banner"></div>
    <div class="profile-body">
        <span class="avatar avatar-xxl #view.avatarColor(employee.name)#">#h(view.initials(employee.name))#</span>
        <div class="profile-id">
            <h1 class="page-title mb-1">#h(employee.name)#</h1>
            <div class="text-secondary mb-2">
                #len(employee.job_title) ? h(employee.job_title) : "No job title"# &middot; #h(employee.department)#
            </div>
            <span class="status-badge #view.statusClass(employee.status)#"><i class="bi #view.statusIcon(employee.status)#"></i>#h(employee.status)#</span>
        </div>
        <div class="profile-actions">
            <a href="#root#employees/form.cfm?id=#employee.id#" class="btn btn-primary"><i class="bi bi-pencil-square me-1"></i>Edit</a>
            <button type="button" class="btn btn-outline-danger" data-bs-toggle="modal" data-bs-target="##deleteModal"
                    data-employee-id="#employee.id#" data-employee-name="#ha(employee.name)#"><i class="bi bi-trash3 me-1"></i>Delete</button>
        </div>
    </div>
</div>

<div class="row g-3">
    <div class="col-12 col-lg-7">
        <div class="card h-100">
            <div class="card-header-row"><h2 class="card-title-sm">Contact &amp; job details</h2></div>
            <div class="detail-grid p-3 pt-0">
                #detail("bi-envelope", "Email", '<a href="mailto:' & ha(employee.email) & '">' & h(employee.email) & '</a>')#
                #detail("bi-telephone", "Phone", len(employee.phone) ? '<a href="tel:' & ha(reReplace(employee.phone, "[^0-9+]", "", "all")) & '">' & h(employee.phone) & '</a>' : "")#
                #detail("bi-diagram-3", "Department", h(employee.department))#
                #detail("bi-briefcase", "Job title", h(employee.job_title))#
                #detail("bi-cash-stack", "Annual salary", isNumeric(employee.salary) ? h(view.fmtMoney(employee.salary)) : "")#
                #detail("bi-calendar-check", "Joining date", isDate(employee.joining_date) ? h(view.fmtDate(employee.joining_date, "mmmm d, yyyy")) : "")#
            </div>
        </div>
    </div>
    <div class="col-12 col-lg-5">
        <div class="card h-100">
            <div class="card-header-row"><h2 class="card-title-sm">Summary</h2></div>
            <div class="detail-grid single p-3 pt-0">
                #detail("bi-hourglass-split", "Tenure", h(view.tenure(employee.joining_date)))#
                #detail("bi-hash", "Employee ID", "EMP-" & numberFormat(employee.id, "00000"))#
                #detail("bi-plus-circle", "Record created", h(view.fmtDateTime(employee.created_at)))#
                #detail("bi-pencil", "Last updated", h(view.fmtDateTime(employee.updated_at)))#
            </div>
        </div>
    </div>
</div>

<div class="mt-3">
    <a href="#root#employees/index.cfm" class="btn btn-light"><i class="bi bi-arrow-left me-1"></i>Back to directory</a>
</div>

</cfoutput>
<cfinclude template="/app/views/partials/delete_modal.cfm">
<cfinclude template="/app/views/layout/footer.cfm">
