<cfprocessingdirective pageEncoding="utf-8">
<!--- Generic error page (HTTP 500). Never prints exception details; the reference id matches the employee_app log entry. --->
<cfparam name="request.root" default="">
<cfparam name="request.errorRef" default="unknown">
<cfscript>
    getPageContext().getResponse().setStatus(500);
</cfscript>
<cfcontent reset="true" type="text/html; charset=utf-8"><cfoutput><!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex, nofollow">
    <title>Something went wrong &middot; People Hub</title>
    <link rel="stylesheet" href="#request.root#assets/vendor/bootstrap/bootstrap.min.css">
    <link rel="stylesheet" href="#request.root#assets/vendor/bootstrap-icons/bootstrap-icons.min.css">
    <link rel="stylesheet" href="#request.root#assets/css/app.css?v=1">
</head>
<body class="standalone">
<main class="standalone-card card text-center">
    <div class="empty-icon tone-rose-bg"><i class="bi bi-emoji-frown"></i></div>
    <h1 class="h4 mb-2">Something went wrong</h1>
    <p class="text-secondary">An unexpected error occurred and has been logged. Please try again in a moment.</p>
    <p class="small text-secondary">Reference: <code>#encodeForHTML(request.errorRef)#</code></p>
    <div class="d-flex justify-content-center gap-2 mt-3">
        <a href="#request.root#index.cfm" class="btn btn-primary"><i class="bi bi-house me-1"></i>Dashboard</a>
        <a href="#request.root#employees/index.cfm" class="btn btn-light">Employee directory</a>
    </div>
</main>
</body>
</html>
</cfoutput>
