<cfinclude template="/app/views/init.cfm">
<cfscript>
    request.pageTitle = "Dashboard";
    request.activeNav = "dashboard";
    data  = svc.dashboard();
    stats = data.stats;

    pct = function(part, whole) { return whole > 0 ? round(part / whole * 100) : 0; };
    recentRows = data.recent;
    deptRows   = data.departments;
    maxHeadcount = deptRows.recordCount ? deptRows.headcount[1] : 1;
</cfscript>
<cfinclude template="/app/views/layout/header.cfm">
<cfoutput>

<div class="page-head">
    <div>
        <h1 class="page-title">Dashboard</h1>
        <p class="page-sub">A live overview of your workforce.</p>
    </div>
    <a href="#root#employees/index.cfm" class="btn btn-outline-secondary"><i class="bi bi-person-lines-fill me-1"></i>View directory</a>
</div>

<cfif stats.total eq 0>
    <div class="card empty-state">
        <div class="empty-icon"><i class="bi bi-people"></i></div>
        <h2 class="h5">No employees yet</h2>
        <p class="text-secondary mb-4">Your dashboard will come alive as soon as you add your first employee.</p>
        <a href="#root#employees/form.cfm" class="btn btn-primary"><i class="bi bi-person-plus-fill me-1"></i>Add the first employee</a>
    </div>
<cfelse>

<!--- Summary cards --->
<div class="row g-3 mb-4">
    <div class="col-12 col-sm-6 col-xl-3">
        <a class="stat-card stat-link" href="#root#employees/index.cfm">
            <span class="stat-icon tone-indigo"><i class="bi bi-people-fill"></i></span>
            <div>
                <div class="stat-label">Total employees</div>
                <div class="stat-value">#numberFormat(stats.total)#</div>
                <div class="stat-note">across all departments</div>
            </div>
        </a>
    </div>
    <div class="col-12 col-sm-6 col-xl-3">
        <a class="stat-card stat-link" href="#root#employees/index.cfm?status=Active">
            <span class="stat-icon tone-emerald"><i class="bi bi-person-check-fill"></i></span>
            <div>
                <div class="stat-label">Active employees</div>
                <div class="stat-value">#numberFormat(stats.active)#</div>
                <div class="stat-note">#pct(stats.active, stats.total)#% of workforce</div>
            </div>
        </a>
    </div>
    <div class="col-12 col-sm-6 col-xl-3">
        <a class="stat-card stat-link" href="#root#employees/index.cfm">
            <span class="stat-icon tone-violet"><i class="bi bi-diagram-3-fill"></i></span>
            <div>
                <div class="stat-label">Departments</div>
                <div class="stat-value">#numberFormat(stats.departments)#</div>
                <div class="stat-note">with at least one employee</div>
            </div>
        </a>
    </div>
    <div class="col-12 col-sm-6 col-xl-3">
        <div class="stat-card">
            <span class="stat-icon tone-amber"><i class="bi bi-stars"></i></span>
            <div>
                <div class="stat-label">Recent hires</div>
                <div class="stat-value">#numberFormat(stats.recentHires)#</div>
                <div class="stat-note">joined in the last #cfg.recentHireDays# days</div>
            </div>
        </div>
    </div>
</div>

<div class="row g-3">
    <!--- Recent hires --->
    <div class="col-12 col-xl-7">
        <div class="card h-100">
            <div class="card-header-row">
                <h2 class="card-title-sm">Latest hires</h2>
                <a href="#root#employees/index.cfm?sort=joining_date&amp;dir=desc" class="link-subtle">See all <i class="bi bi-arrow-right"></i></a>
            </div>
            <cfif recentRows.recordCount>
                <ul class="list-people">
                    <cfloop query="recentRows">
                        <li>
                            <a class="person" href="#root#employees/view.cfm?id=#recentRows.id#">
                                <span class="avatar #view.avatarColor(recentRows.name)#">#h(view.initials(recentRows.name))#</span>
                                <span class="person-main">
                                    <span class="person-name">#h(recentRows.name)#</span>
                                    <span class="person-sub">#h(recentRows.job_title)#<cfif len(recentRows.job_title)> &middot; </cfif>#h(recentRows.department)#</span>
                                </span>
                                <span class="person-meta">
                                    <span class="d-block">#h(view.fmtDate(recentRows.joining_date))#</span>
                                    <span class="text-secondary small">#h(view.tenure(recentRows.joining_date))#</span>
                                </span>
                            </a>
                        </li>
                    </cfloop>
                </ul>
            <cfelse>
                <p class="text-secondary p-4 mb-0">No joining dates recorded yet.</p>
            </cfif>
        </div>
    </div>

    <div class="col-12 col-xl-5">
        <div class="d-flex flex-column gap-3 h-100">
            <!--- Status split --->
            <div class="card">
                <div class="card-header-row"><h2 class="card-title-sm">Employment status</h2></div>
                <div class="p-3 pt-0">
                    <div class="split-bar" role="img" aria-label="Active #stats.active#, on leave #stats.onLeave#, inactive #stats.inactive#">
                        <span class="seg seg-active"   style="width:#pct(stats.active, stats.total)#%"></span>
                        <span class="seg seg-leave"    style="width:#pct(stats.onLeave, stats.total)#%"></span>
                        <span class="seg seg-inactive" style="width:#pct(stats.inactive, stats.total)#%"></span>
                    </div>
                    <div class="legend">
                        <a href="#root#employees/index.cfm?status=Active"><span class="dot dot-active"></span>Active <strong>#stats.active#</strong></a>
                        <a href="#root#employees/index.cfm?status=On+Leave"><span class="dot dot-leave"></span>On leave <strong>#stats.onLeave#</strong></a>
                        <a href="#root#employees/index.cfm?status=Inactive"><span class="dot dot-inactive"></span>Inactive <strong>#stats.inactive#</strong></a>
                    </div>
                </div>
            </div>

            <!--- Department headcount --->
            <div class="card flex-grow-1">
                <div class="card-header-row"><h2 class="card-title-sm">Top departments</h2></div>
                <div class="p-3 pt-0">
                    <cfloop query="deptRows">
                        <a class="dept-row" href="#root#employees/index.cfm?department=#encodeForURL(deptRows.department)#">
                            <span class="dept-name">#h(deptRows.department)#</span>
                            <span class="dept-bar"><span style="width:#pct(deptRows.headcount, maxHeadcount)#%"></span></span>
                            <span class="dept-count">#deptRows.headcount#</span>
                        </a>
                    </cfloop>
                </div>
            </div>
        </div>
    </div>
</div>

</cfif>
</cfoutput>
<cfinclude template="/app/views/layout/footer.cfm">
