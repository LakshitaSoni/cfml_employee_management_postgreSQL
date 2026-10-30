<cfprocessingdirective pageEncoding="utf-8">
<!--- Shown (HTTP 503) when the database is unreachable or the employees table is missing columns.
      Deliberately generic: no connection strings, credentials, stack traces or SQL. --->
<cfparam name="request.root" default="">
<cfset st = request.setupStatus>
<cfcontent reset="true" type="text/html; charset=utf-8"><cfoutput><!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex, nofollow">
    <title>Setup required &middot; People Hub</title>
    <link rel="stylesheet" href="#request.root#assets/vendor/bootstrap/bootstrap.min.css">
    <link rel="stylesheet" href="#request.root#assets/vendor/bootstrap-icons/bootstrap-icons.min.css">
    <link rel="stylesheet" href="#request.root#assets/css/app.css?v=1">
</head>
<body class="standalone">
<main class="standalone-card card">
    <div class="empty-icon tone-amber-bg"><i class="bi bi-database-exclamation"></i></div>
    <h1 class="h4 text-center mb-2">Database setup required</h1>

    <cfif NOT st.connected>
        <p class="text-secondary text-center">The application could not connect to the database. Check that PostgreSQL is running and that the connection settings are correct.</p>
        <ol class="setup-steps">
            <li>Start PostgreSQL and confirm the <code>admin_employee_management</code> database exists.</li>
            <li>Set <code>DB_HOST</code>, <code>DB_PORT</code>, <code>DB_NAME</code>, <code>DB_USER</code>, <code>DB_PASSWORD</code> in the <code>.env</code> file (project root) or as OS environment variables &mdash; <em>or</em> create a ColdFusion Administrator datasource named <code>admin_employee_management</code>.</li>
            <li>Restart ColdFusion (or open this site with <code>?reinit=1</code> when <code>APP_ENV=development</code>).</li>
        </ol>
        <p class="small text-secondary text-center mb-0">Details were written to the <code>employee_app</code> log.</p>
    <cfelseif NOT st.tableFound>
        <p class="text-secondary text-center">The database is reachable but the <code>employees</code> table was not found. Run <code>database/schema.sql</code> to create it.</p>
    <cfelse>
        <p class="text-secondary text-center">The <code>employees</code> table is missing columns this application needs:</p>
        <p class="text-center"><cfloop array="#st.missing#" index="col"><span class="badge text-bg-light border me-1">#encodeForHTML(col)#</span></cfloop></p>
        <p class="text-secondary text-center mb-0">Run <code>database/schema.sql</code> &mdash; it adds the missing columns to your existing table without touching existing rows.</p>
    </cfif>

    <div class="text-center mt-4">
        <a href="" class="btn btn-primary"><i class="bi bi-arrow-clockwise me-1"></i>Try again</a>
    </div>
</main>
</body>
</html>
</cfoutput>
