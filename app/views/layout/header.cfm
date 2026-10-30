<cfprocessingdirective pageEncoding="utf-8">
<cfparam name="request.pageTitle" default="Employee Management">
<cfparam name="request.activeNav" default="">
<cfoutput><!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex, nofollow">
    <title>#h(request.pageTitle)# &middot; People Hub</title>
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='8' fill='%234f46e5'/%3E%3Ccircle cx='16' cy='12' r='5' fill='white'/%3E%3Cpath d='M6 26c1-5 5-8 10-8s9 3 10 8z' fill='white'/%3E%3C/svg%3E">
    <link rel="stylesheet" href="#root#assets/vendor/bootstrap/bootstrap.min.css">
    <link rel="stylesheet" href="#root#assets/vendor/bootstrap-icons/bootstrap-icons.min.css">
    <link rel="stylesheet" href="#root#assets/css/app.css?v=1">
</head>
<body>
<div class="app-shell">

    <!--- Sidebar: static on lg+, off-canvas below --->
    <aside class="sidebar offcanvas-lg offcanvas-start" tabindex="-1" id="sidebar" aria-labelledby="sidebarLabel">
        <div class="sidebar-brand">
            <a href="#root#index.cfm" class="brand-link" id="sidebarLabel">
                <span class="brand-mark"><i class="bi bi-people-fill"></i></span>
                <span class="brand-text">People Hub<small>Employee management</small></span>
            </a>
            <button type="button" class="btn-close btn-close-white d-lg-none" data-bs-dismiss="offcanvas" data-bs-target="##sidebar" aria-label="Close menu"></button>
        </div>

        <nav class="sidebar-nav" aria-label="Main">
            <div class="nav-section">Overview</div>
            <a class="nav-item-link #request.activeNav eq 'dashboard' ? 'active' : ''#" href="#root#index.cfm"><i class="bi bi-grid-1x2-fill"></i><span>Dashboard</span></a>

            <div class="nav-section">Workforce</div>
            <a class="nav-item-link #request.activeNav eq 'employees' ? 'active' : ''#" href="#root#employees/index.cfm"><i class="bi bi-person-lines-fill"></i><span>Employee directory</span></a>
            <a class="nav-item-link #request.activeNav eq 'add' ? 'active' : ''#" href="#root#employees/form.cfm"><i class="bi bi-person-plus-fill"></i><span>Add employee</span></a>

            <div class="nav-section">Quick filters</div>
            <a class="nav-item-link" href="#root#employees/index.cfm?status=Active"><span class="dot dot-active"></span><span>Active</span></a>
            <a class="nav-item-link" href="#root#employees/index.cfm?status=On+Leave"><span class="dot dot-leave"></span><span>On leave</span></a>
            <a class="nav-item-link" href="#root#employees/index.cfm?status=Inactive"><span class="dot dot-inactive"></span><span>Inactive</span></a>
        </nav>

        <div class="sidebar-foot">
            <i class="bi bi-shield-check"></i>
            <span>Secure session &middot; CSRF protected</span>
        </div>
    </aside>

    <div class="main-column">
        <!--- Top navigation bar --->
        <header class="topbar">
            <button class="btn btn-icon d-lg-none" type="button" data-bs-toggle="offcanvas" data-bs-target="##sidebar" aria-controls="sidebar" aria-label="Open menu">
                <i class="bi bi-list fs-4"></i>
            </button>

            <form class="topbar-search" action="#root#employees/index.cfm" method="get" role="search">
                <i class="bi bi-search"></i>
                <input type="search" name="q" class="form-control" maxlength="100" placeholder="Search employees by name, email, department&hellip;" aria-label="Search employees">
            </form>

            <div class="topbar-actions">
                <span class="topbar-date d-none d-md-inline"><i class="bi bi-calendar3"></i> #dateFormat(now(), "ddd, mmm d, yyyy")#</span>
                <a href="#root#employees/form.cfm" class="btn btn-primary btn-add"><i class="bi bi-plus-lg"></i><span class="d-none d-sm-inline ms-1">Add employee</span></a>
            </div>
        </header>

        <main class="content" id="main">
</cfoutput>
