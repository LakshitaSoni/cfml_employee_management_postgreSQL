/**
 * Application bootstrap.
 *
 * Web root is /public. Everything sensitive (components, views, .env, SQL)
 * lives outside it and is reached through the /app mapping below.
 */
component output="false" {

    this.name               = "EmployeeManagementSystem";
    this.applicationTimeout = createTimeSpan(7, 0, 0, 0);
    this.sessionManagement  = true;
    this.sessionTimeout     = createTimeSpan(0, 2, 0, 0);
    this.charset.web        = "UTF-8";
    this.charset.resource   = "UTF-8";
    this.sessionCookie      = {
        httpOnly = true,
        secure   = (cgi.https == "on" || cgi.server_port_secure == "true" || cgi.http_x_forwarded_proto == "https"),
        sameSite = "Lax"
    };

    this.rootDir = replace(getCanonicalPath(getDirectoryFromPath(getCurrentTemplatePath()) & "../"), "\", "/", "all") & "/";
    this.mappings["/app"] = this.rootDir & "app";

    // ---- Datasource -------------------------------------------------------
    // Credentials come from OS environment variables or the git-ignored .env
    // file (never from source). When DB_HOST/DB_USER are not provided the app
    // falls back to a datasource defined in the ColdFusion Administrator.
    variables.env = loadEnv();
    this.datasource = len(variables.env.DB_DATASOURCE) ? variables.env.DB_DATASOURCE : "admin_employee_management";

    if (len(variables.env.DB_HOST) && len(variables.env.DB_USER)) {
        this.datasources[this.datasource] = {
            driver   = "PostgreSQL",
            class    = "org.postgresql.Driver",
            url      = "jdbc:postgresql://" & variables.env.DB_HOST & ":" & variables.env.DB_PORT & "/" & variables.env.DB_NAME & (len(variables.env.DB_PARAMS) ? "?" & variables.env.DB_PARAMS : ""),
            username = variables.env.DB_USER,
            password = variables.env.DB_PASSWORD
        };
    }

    // ---- Lifecycle ----------------------------------------------------------

    public boolean function onApplicationStart() {
        var settings = new app.model.Settings(loadEnv(), this.datasource);
        var dao      = new app.model.EmployeeDAO(settings.datasource, settings.table);

        application.settings        = settings;
        application.employeeService = new app.model.EmployeeService(dao, settings);
        application.csrf            = new app.model.CsrfService();
        application.flash           = new app.model.FlashService();
        application.view            = new app.model.ViewHelper(settings);
        application.schemaReady     = false;
        return true;
    }

    public void function onSessionStart() {
        session.csrfToken = application.csrf.generate();
    }

    public boolean function onRequestStart(required string targetPage) {
        if (structKeyExists(url, "reinit") && application.settings.isDevelopment) {
            lock name="emsReinit" type="exclusive" timeout="10" {
                structDelete(server, "emsEnv");
                onApplicationStart();
            }
        }

        setSecurityHeaders();
        request.root = webRootPrefix();

        if (!application.schemaReady) {
            var status = application.employeeService.checkSchema();
            if (status.ok) {
                application.schemaReady = true;
            } else {
                request.setupStatus = status;
                getPageContext().getResponse().setStatus(503);
                include "/app/views/setup_required.cfm";
                return false;
            }
        }
        return true;
    }

    /**
     * Last-resort handler: log the real error, show the visitor a generic page
     * with a reference id. No stack trace, SQL or configuration is ever output.
     */
    public void function onError(required any exception, required string eventName) {
        request.errorRef = lcase(left(replace(createUUID(), "-", "", "all"), 8));
        try {
            var detail = structKeyExists(arguments.exception, "detail") ? arguments.exception.detail : "";
            writeLog(type = "error", file = "employee_app",
                text = "[#request.errorRef#] #arguments.exception.type#: #arguments.exception.message# | #detail#");
        } catch (any ignore) {}
        include "/app/views/error.cfm";
    }

    // ---- Helpers ----------------------------------------------------------------

    /** "" for pages in /public, "../" for /public/employees, etc. - keeps links valid under any deployment path. */
    private string function webRootPrefix() {
        var publicDir = this.rootDir & "public/";
        var dir       = replace(getDirectoryFromPath(getBaseTemplatePath()), "\", "/", "all");
        if (findNoCase(publicDir, dir) != 1) {
            return "";
        }
        var relative = mid(dir, len(publicDir) + 1, len(dir));
        return repeatString("../", listLen(relative, "/"));
    }

    private void function setSecurityHeaders() {
        var response = getPageContext().getResponse();
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setHeader("X-Frame-Options", "DENY");
        response.setHeader("Referrer-Policy", "same-origin");
        response.setHeader("Cache-Control", "no-store");
        response.setHeader("Content-Security-Policy",
            "default-src 'self'; img-src 'self' data:; style-src 'self'; style-src-attr 'unsafe-inline'; " &
            "script-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'");
    }

    /**
     * Reads the settings the app needs. OS environment variables win over the
     * project-root .env file. Cached for the life of the JVM.
     */
    private struct function loadEnv() {
        if (structKeyExists(server, "emsEnv")) {
            return server.emsEnv;
        }
        lock name="emsEnvLoad" type="exclusive" timeout="10" {
            if (!structKeyExists(server, "emsEnv")) {
                var fromFile = {};
                var envFile  = this.rootDir & ".env";
                if (fileExists(envFile)) {
                    for (var line in listToArray(fileRead(envFile, "utf-8"), chr(10))) {
                        line = trim(line);
                        if (!len(line) || left(line, 1) == "##" || !find("=", line)) {
                            continue;
                        }
                        var key   = trim(left(line, find("=", line) - 1));
                        var value = trim(mid(line, find("=", line) + 1, len(line)));
                        var quote = left(value, 1);
                        if (len(value) >= 2 && (quote == '"' || quote == "'") && right(value, 1) == quote) {
                            value = mid(value, 2, len(value) - 2);
                        }
                        fromFile[key] = value;
                    }
                }

                var osEnv    = createObject("java", "java.lang.System").getenv();
                var defaults = {
                    DB_HOST = "", DB_PORT = "5432", DB_NAME = "admin_employee_management", DB_USER = "",
                    DB_PASSWORD = "", DB_DATASOURCE = "", DB_TABLE = "employees",
                    DB_PARAMS = "",
                    APP_ENV = "production", APP_CURRENCY = "INR", APP_PAGE_SIZE = "10"
                };
                var merged = {};
                for (var name in defaults) {
                    if (osEnv.containsKey(name) && len(osEnv.get(name))) {
                        merged[name] = osEnv.get(name);
                    } else if (structKeyExists(fromFile, name) && len(fromFile[name])) {
                        merged[name] = fromFile[name];
                    } else {
                        merged[name] = defaults[name];
                    }
                }
                server.emsEnv = merged;
            }
        }
        return server.emsEnv;
    }

}
