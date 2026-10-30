<cfinclude template="/app/views/init.cfm">
<cfscript>
    request.pageTitle = "Employee directory";
    request.activeNav = "employees";

    filters = svc.normalizeFilters(url);
    result  = svc.search(filters);
    filters = result.filters;                       // page may have been clamped
    departments = svc.departmentOptions();
    rows        = result.rows;

    hasFilters  = len(filters.search) || len(filters.department) || len(filters.status);
    baseLink    = "index.cfm";
    deleteReturnQuery = replace(view.directoryLink("", filters), "?", "");

    /** Sortable column header link with direction indicator. */
    function sortHeader(required string key, required string label, string cssClass = "") {
        var active  = (filters.sort == arguments.key);
        var nextDir = (active && filters.dir == "asc") ? "desc" : "asc";
        var href    = view.directoryLink(baseLink, filters, {sort = arguments.key, dir = nextDir, page = 1});
        var icon    = active ? (filters.dir == "asc" ? "bi-caret-up-fill" : "bi-caret-down-fill") : "bi-chevron-expand";
        return '<th scope="col" class="' & arguments.cssClass & '" aria-sort="' & (active ? (filters.dir == "asc" ? "ascending" : "descending") : "none") & '">' &
               '<a class="sort-link' & (active ? " active" : "") & '" href="' & ha(href) & '">' & h(arguments.label) & ' <i class="bi ' & icon & '"></i></a></th>';
    }
</cfscript>
<cfinclude template="/app/views/layout/header.cfm">
<cfoutput>

<div class="page-head">
    <div>
        <h1 class="page-title">Employee directory</h1>
        <p class="page-sub">#numberFormat(result.total)# <cfif hasFilters>matching </cfif>employee#result.total eq 1 ? "" : "s"#<cfif hasFilters> &middot; <a href="#root#employees/index.cfm">clear filters</a></cfif></p>
    </div>
    <a href="#root#employees/form.cfm" class="btn btn-primary"><i class="bi bi-person-plus-fill me-1"></i>Add employee</a>
</div>

<!--- Filters --->
<form method="get" action="#root#employees/index.cfm" class="card filter-card mb-3" id="filterForm" data-autosubmit>
    <input type="hidden" name="sort" value="#ha(filters.sort)#">
    <input type="hidden" name="dir"  value="#ha(filters.dir)#">
    <div class="row g-2 align-items-end p-3">
        <div class="col-12 col-lg-5">
            <label class="form-label small text-secondary mb-1" for="fSearch">Search</label>
            <div class="input-icon">
                <i class="bi bi-search"></i>
                <input type="search" class="form-control" id="fSearch" name="q" value="#ha(filters.search)#" maxlength="100" placeholder="Name, email, phone, department or title" data-debounce>
            </div>
        </div>
        <div class="col-6 col-lg-3">
            <label class="form-label small text-secondary mb-1" for="fDept">Department</label>
            <select class="form-select" id="fDept" name="department">
                <option value="">All departments</option>
                <cfloop array="#departments#" index="d">
                    <option value="#ha(d)#" #d eq filters.department ? "selected" : ""#>#h(d)#</option>
                </cfloop>
            </select>
        </div>
        <div class="col-6 col-lg-2">
            <label class="form-label small text-secondary mb-1" for="fStatus">Status</label>
            <select class="form-select" id="fStatus" name="status">
                <option value="">All statuses</option>
                <cfloop array="#cfg.statuses#" index="s">
                    <option value="#ha(s)#" #s eq filters.status ? "selected" : ""#>#h(s)#</option>
                </cfloop>
            </select>
        </div>
        <div class="col-6 col-lg-1">
            <label class="form-label small text-secondary mb-1" for="fSize">Rows</label>
            <select class="form-select" id="fSize" name="pageSize">
                <cfloop array="#cfg.pageSizes#" index="n">
                    <option value="#n#" #n eq filters.pageSize ? "selected" : ""#>#n#</option>
                </cfloop>
            </select>
        </div>
        <div class="col-6 col-lg-1 d-flex gap-1">
            <button type="submit" class="btn btn-primary flex-grow-1" title="Apply filters"><i class="bi bi-funnel-fill"></i><span class="visually-hidden">Apply</span></button>
            <a href="#root#employees/index.cfm" class="btn btn-light" title="Reset filters"><i class="bi bi-arrow-counterclockwise"></i><span class="visually-hidden">Reset</span></a>
        </div>
    </div>
</form>

<div class="card table-card position-relative" id="tableCard">
    <div class="table-loading" hidden><div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading&hellip;</span></div></div>

    <cfif result.total eq 0>
        <div class="empty-state">
            <cfif hasFilters>
                <div class="empty-icon"><i class="bi bi-search"></i></div>
                <h2 class="h5">No employees match your filters</h2>
                <p class="text-secondary mb-4">Try a different search term or clear the filters.</p>
                <a href="#root#employees/index.cfm" class="btn btn-outline-primary"><i class="bi bi-x-circle me-1"></i>Clear filters</a>
            <cfelse>
                <div class="empty-icon"><i class="bi bi-people"></i></div>
                <h2 class="h5">No employees yet</h2>
                <p class="text-secondary mb-4">Get started by adding your first employee.</p>
                <a href="#root#employees/form.cfm" class="btn btn-primary"><i class="bi bi-person-plus-fill me-1"></i>Add employee</a>
            </cfif>
        </div>
    <cfelse>
        <div class="table-responsive">
            <table class="table table-directory align-middle mb-0">
                <thead>
                    <tr>
                        #sortHeader("name", "Employee")#
                        #sortHeader("department", "Department", "d-none d-md-table-cell")#
                        #sortHeader("job_title", "Job title", "d-none d-xl-table-cell")#
                        #sortHeader("joining_date", "Joined", "d-none d-lg-table-cell")#
                        #sortHeader("salary", "Salary", "d-none d-xl-table-cell text-end")#
                        #sortHeader("status", "Status", "d-none d-md-table-cell")#
                        <th scope="col" class="text-end"><span class="visually-hidden">Actions</span></th>
                    </tr>
                </thead>
                <tbody>
                    <cfloop query="rows">
                        <tr>
                            <td>
                                <a class="person" href="#root#employees/view.cfm?id=#rows.id#">
                                    <span class="avatar #view.avatarColor(rows.name)#">#h(view.initials(rows.name))#</span>
                                    <span class="person-main">
                                        <span class="person-name">#h(rows.name)#</span>
                                        <span class="person-sub">#h(rows.email)#</span>
                                        <span class="d-md-none mt-1"><span class="status-badge #view.statusClass(rows.status)#"><i class="bi #view.statusIcon(rows.status)#"></i>#h(rows.status)#</span></span>
                                    </span>
                                </a>
                            </td>
                            <td class="d-none d-md-table-cell">#h(rows.department)#</td>
                            <td class="d-none d-xl-table-cell">#len(rows.job_title) ? h(rows.job_title) : '<span class="text-muted">&mdash;</span>'#</td>
                            <td class="d-none d-lg-table-cell nowrap">#len(rows.joining_date) ? h(view.fmtDate(rows.joining_date)) : '<span class="text-muted">&mdash;</span>'#</td>
                            <td class="d-none d-xl-table-cell text-end tabular">#len(rows.salary) ? h(view.fmtMoney(rows.salary)) : '<span class="text-muted">&mdash;</span>'#</td>
                            <td class="d-none d-md-table-cell"><span class="status-badge #view.statusClass(rows.status)#"><i class="bi #view.statusIcon(rows.status)#"></i>#h(rows.status)#</span></td>
                            <td class="text-end text-nowrap">
                                <a href="#root#employees/view.cfm?id=#rows.id#" class="btn btn-icon" title="View profile" aria-label="View #ha(rows.name)#"><i class="bi bi-eye"></i></a>
                                <a href="#root#employees/form.cfm?id=#rows.id#" class="btn btn-icon" title="Edit" aria-label="Edit #ha(rows.name)#"><i class="bi bi-pencil-square"></i></a>
                                <button type="button" class="btn btn-icon btn-icon-danger" title="Delete" aria-label="Delete #ha(rows.name)#"
                                        data-bs-toggle="modal" data-bs-target="##deleteModal"
                                        data-employee-id="#rows.id#" data-employee-name="#ha(rows.name)#"><i class="bi bi-trash3"></i></button>
                            </td>
                        </tr>
                    </cfloop>
                </tbody>
            </table>
        </div>

        <div class="table-footer">
            <div class="text-secondary small">Showing <strong>#result.from#</strong>&ndash;<strong>#result.to#</strong> of <strong>#numberFormat(result.total)#</strong></div>
            <cfif result.pages gt 1>
                <nav aria-label="Employee pages">
                    <ul class="pagination pagination-sm mb-0">
                        <li class="page-item #result.page eq 1 ? 'disabled' : ''#">
                            <a class="page-link" href="#ha(view.directoryLink(baseLink, filters, {page = result.page - 1}))#" aria-label="Previous"><i class="bi bi-chevron-left"></i></a>
                        </li>
                        <cfloop array="#view.pageWindow(result.page, result.pages)#" index="p">
                            <cfif p eq 0>
                                <li class="page-item disabled"><span class="page-link">&hellip;</span></li>
                            <cfelse>
                                <li class="page-item #p eq result.page ? 'active' : ''#" <cfif p eq result.page>aria-current="page"</cfif>>
                                    <a class="page-link" href="#ha(view.directoryLink(baseLink, filters, {page = p}))#">#p#</a>
                                </li>
                            </cfif>
                        </cfloop>
                        <li class="page-item #result.page eq result.pages ? 'disabled' : ''#">
                            <a class="page-link" href="#ha(view.directoryLink(baseLink, filters, {page = result.page + 1}))#" aria-label="Next"><i class="bi bi-chevron-right"></i></a>
                        </li>
                    </ul>
                </nav>
            </cfif>
        </div>
    </cfif>
</div>

</cfoutput>
<cfinclude template="/app/views/partials/delete_modal.cfm">
<cfinclude template="/app/views/layout/footer.cfm">
