/**
 * Data access for the employees table. This is the ONLY component that
 * contains SQL. Every value is bound with a typed parameter; the only text
 * interpolated into SQL (ORDER BY column and direction) comes from fixed
 * whitelists, never from user input.
 */
component output="false" {

    variables.columns = "id, name, email, phone, department, job_title, salary, joining_date, status, created_at, updated_at";

    variables.sortColumns = {
        name         = "name",
        email        = "email",
        department   = "department",
        job_title    = "job_title",
        salary       = "salary",
        joining_date = "joining_date",
        status       = "status"
    };

    variables.requiredColumns = "id,name,email,phone,department,job_title,salary,joining_date,status,created_at,updated_at";

    public EmployeeDAO function init(required string datasource, string table = "employees") {
        variables.opts  = {datasource = arguments.datasource};
        variables.table = arguments.table;   // validated in Settings.cfc
        return this;
    }

    // ---- Reads ------------------------------------------------------------------

    /**
     * @filters struct: search, department, status, sort, dir, limit, offset (already normalized by the service)
     */
    public struct function search(required struct filters) {
        var w      = buildWhere(arguments.filters);
        var where  = arrayLen(w.clauses) ? " WHERE " & arrayToList(w.clauses, " AND ") : "";
        var column = variables.sortColumns[arguments.filters.sort];
        var dir    = arguments.filters.dir == "desc" ? "DESC" : "ASC";

        var total = queryExecute("SELECT COUNT(*) AS c FROM #variables.table#" & where, w.params, variables.opts).c;

        var rowParams = duplicate(w.params);
        rowParams["limit"]  = {value = arguments.filters.limit,  cfsqltype = "cf_sql_integer"};
        rowParams["offset"] = {value = arguments.filters.offset, cfsqltype = "cf_sql_integer"};

        var rows = queryExecute(
            "SELECT #variables.columns# FROM #variables.table#" & where &
            " ORDER BY #column# #dir#, id ASC LIMIT :limit OFFSET :offset",
            rowParams, variables.opts
        );
        return {rows = rows, total = total};
    }

    /** @return struct (empty when not found); NULL columns come back as empty strings */
    public struct function getById(required numeric id) {
        var q = queryExecute(
            "SELECT #variables.columns# FROM #variables.table# WHERE id = :id",
            {id = {value = arguments.id, cfsqltype = "cf_sql_integer"}},
            variables.opts
        );
        if (!q.recordCount) {
            return {};
        }
        var row = {};
        for (var col in listToArray(q.columnList)) {
            row[lcase(col)] = q[col][1];
        }
        return row;
    }

    public boolean function emailExists(required string email, numeric excludeId = 0) {
        var q = queryExecute(
            "SELECT COUNT(*) AS c FROM #variables.table# WHERE LOWER(email) = :email AND id <> :id",
            {
                email = {value = lcase(arguments.email), cfsqltype = "cf_sql_varchar"},
                id    = {value = arguments.excludeId,    cfsqltype = "cf_sql_integer"}
            },
            variables.opts
        );
        return q.c > 0;
    }

    public query function departments() {
        return queryExecute(
            "SELECT DISTINCT department FROM #variables.table# WHERE department <> '' ORDER BY department",
            {}, variables.opts
        );
    }

    public struct function stats(required numeric recentDays) {
        var q = queryExecute(
            "SELECT COUNT(*) AS total,
                    COALESCE(SUM(CASE WHEN status = 'Active'   THEN 1 ELSE 0 END), 0) AS active,
                    COALESCE(SUM(CASE WHEN status = 'On Leave' THEN 1 ELSE 0 END), 0) AS on_leave,
                    COALESCE(SUM(CASE WHEN status = 'Inactive' THEN 1 ELSE 0 END), 0) AS inactive,
                    COUNT(DISTINCT department)                                        AS departments,
                    COALESCE(SUM(CASE WHEN joining_date >= CURRENT_DATE - :days
                                       AND joining_date <= CURRENT_DATE THEN 1 ELSE 0 END), 0) AS recent_hires
             FROM #variables.table#",
            {days = {value = arguments.recentDays, cfsqltype = "cf_sql_integer"}},
            variables.opts
        );
        return {
            total       = q.total,
            active      = q.active,
            onLeave     = q.on_leave,
            inactive    = q.inactive,
            departments = q.departments,
            recentHires = q.recent_hires
        };
    }

    public query function departmentBreakdown(numeric max = 6) {
        return queryExecute(
            "SELECT department, COUNT(*) AS headcount FROM #variables.table#
             GROUP BY department ORDER BY headcount DESC, department ASC LIMIT :max",
            {max = {value = arguments.max, cfsqltype = "cf_sql_integer"}},
            variables.opts
        );
    }

    public query function recentHires(numeric max = 6) {
        return queryExecute(
            "SELECT id, name, department, job_title, joining_date, status FROM #variables.table#
             WHERE joining_date IS NOT NULL
             ORDER BY joining_date DESC, id DESC LIMIT :max",
            {max = {value = arguments.max, cfsqltype = "cf_sql_integer"}},
            variables.opts
        );
    }

    /**
     * Verifies the database is reachable and the table has every column the app needs.
     * @return struct: ok, connected, missing (array)
     */
    public struct function checkSchema() {
        var present = [];
        try {
            var q = queryExecute(
                "SELECT column_name AS col FROM information_schema.columns
                 WHERE table_schema = current_schema() AND table_name = :tbl",
                {tbl = {value = lcase(variables.table), cfsqltype = "cf_sql_varchar"}}, variables.opts
            );
            for (var r in q) {
                arrayAppend(present, lcase(r.col));
            }
        } catch (any e) {
            writeLog(type = "error", file = "employee_app", text = "Schema check failed: #e.message# | #e.detail#");
            return {ok = false, connected = false, tableFound = false, missing = []};
        }

        var missing = [];
        for (var col in listToArray(variables.requiredColumns)) {
            if (!arrayFind(present, col)) {
                arrayAppend(missing, col);
            }
        }
        return {
            ok         = (arrayLen(present) > 0 && arrayLen(missing) == 0),
            connected  = true,
            tableFound = (arrayLen(present) > 0),
            missing    = missing
        };
    }

    // ---- Writes -----------------------------------------------------------------

    /** @return the new employee id */
    public numeric function insert(required struct data) {
        var result = {};
        queryExecute(
            "INSERT INTO #variables.table# (name, email, phone, department, job_title, salary, joining_date, status)
             VALUES (:name, :email, :phone, :department, :job_title, :salary, :joining_date, :status)",
            writeParams(arguments.data),
            {datasource = variables.opts.datasource, result = "result"}
        );
        if (structKeyExists(result, "generatedKey")) {
            return result.generatedKey;
        }
        if (structKeyExists(result, "generated_key")) {
            return result.generated_key;
        }
        // Fallback: look the row up by its unique email
        return queryExecute(
            "SELECT id FROM #variables.table# WHERE email = :email",
            {email = {value = lcase(arguments.data.email), cfsqltype = "cf_sql_varchar"}},
            variables.opts
        ).id;
    }

    public void function update(required numeric id, required struct data) {
        var params = writeParams(arguments.data);
        params["id"] = {value = arguments.id, cfsqltype = "cf_sql_integer"};
        queryExecute(
            "UPDATE #variables.table# SET name = :name, email = :email, phone = :phone, department = :department,
                    job_title = :job_title, salary = :salary, joining_date = :joining_date, status = :status
             WHERE id = :id",
            params, variables.opts
        );
    }

    public void function delete(required numeric id) {
        queryExecute(
            "DELETE FROM #variables.table# WHERE id = :id",
            {id = {value = arguments.id, cfsqltype = "cf_sql_integer"}},
            variables.opts
        );
    }

    // ---- Internals --------------------------------------------------------------

    private struct function buildWhere(required struct filters) {
        var clauses = [];
        var params  = {};

        if (len(arguments.filters.search)) {
            var like = "%" & escapeLike(arguments.filters.search) & "%";
            arrayAppend(clauses,
                "(name ILIKE :q1 OR email ILIKE :q2 OR department ILIKE :q3 OR job_title ILIKE :q4 OR phone ILIKE :q5)");
            for (var i = 1; i <= 5; i++) {
                params["q#i#"] = {value = like, cfsqltype = "cf_sql_varchar"};
            }
        }
        if (len(arguments.filters.department)) {
            arrayAppend(clauses, "department = :department");
            params["department"] = {value = arguments.filters.department, cfsqltype = "cf_sql_varchar"};
        }
        if (len(arguments.filters.status)) {
            arrayAppend(clauses, "status = :status");
            params["status"] = {value = arguments.filters.status, cfsqltype = "cf_sql_varchar"};
        }
        return {clauses = clauses, params = params};
    }

    /** Escape LIKE wildcards so a search for "50%" matches the literal text. */
    private string function escapeLike(required string value) {
        var s = replace(arguments.value, "\", "\\", "all");
        s = replace(s, "%", "\%", "all");
        return replace(s, "_", "\_", "all");
    }

    private struct function writeParams(required struct d) {
        var hasPhone  = len(arguments.d.phone) > 0;
        var hasSalary = len(arguments.d.salary) > 0;
        var hasDate   = len(arguments.d.joining_date) > 0;
        return {
            name         = {value = arguments.d.name,       cfsqltype = "cf_sql_varchar"},
            email        = {value = lcase(arguments.d.email), cfsqltype = "cf_sql_varchar"},
            phone        = {value = arguments.d.phone,      cfsqltype = "cf_sql_varchar", null = !hasPhone},
            department   = {value = arguments.d.department, cfsqltype = "cf_sql_varchar"},
            job_title    = {value = arguments.d.job_title,  cfsqltype = "cf_sql_varchar"},
            salary       = {value = hasSalary ? arguments.d.salary : 0, cfsqltype = "cf_sql_decimal", scale = 2, null = !hasSalary},
            joining_date = {value = hasDate ? createDate(listGetAt(arguments.d.joining_date, 1, "-"), listGetAt(arguments.d.joining_date, 2, "-"), listGetAt(arguments.d.joining_date, 3, "-")) : now(),
                            cfsqltype = "cf_sql_date", null = !hasDate},
            status       = {value = arguments.d.status,     cfsqltype = "cf_sql_varchar"}
        };
    }

}
