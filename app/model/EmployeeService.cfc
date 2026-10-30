/**
 * Business logic for employees: input normalisation, validation, orchestration.
 * Presentation code never talks to the DAO directly; the DAO never validates.
 */
component output="false" {

    public EmployeeService function init(required any dao, required any settings) {
        variables.dao      = arguments.dao;
        variables.settings = arguments.settings;
        variables.sortKeys = ["name", "email", "department", "job_title", "salary", "joining_date", "status"];
        return this;
    }

    // ---- Queries ------------------------------------------------------------------

    /** Turns untrusted URL parameters into a safe, complete filter struct. */
    public struct function normalizeFilters(required struct raw) {
        var f = {
            search     = left(cleanText(pick(arguments.raw, "q")), 100),
            department = left(cleanText(pick(arguments.raw, "department")), 100),
            status     = pick(arguments.raw, "status"),
            sort       = pick(arguments.raw, "sort"),
            dir        = lcase(pick(arguments.raw, "dir")),
            pageSize   = val(pick(arguments.raw, "pageSize")),
            page       = val(pick(arguments.raw, "page"))
        };
        if (!arrayFindNoCase(variables.settings.statuses, f.status)) {
            f.status = "";
        } else {
            f.status = variables.settings.statuses[arrayFindNoCase(variables.settings.statuses, f.status)];
        }
        if (!arrayFind(variables.sortKeys, f.sort)) {
            f.sort = "name";
        }
        if (f.dir != "desc") {
            f.dir = "asc";
        }
        if (!arrayFind(variables.settings.pageSizes, f.pageSize)) {
            f.pageSize = variables.settings.defaultPageSize;
        }
        f.page = max(1, int(f.page));
        return f;
    }

    /** @return struct: rows (query), total, page, pages, pageSize, from, to, filters */
    public struct function search(required struct filters) {
        var f = duplicate(arguments.filters);
        f.limit  = f.pageSize;
        f.offset = (f.page - 1) * f.pageSize;

        var result = variables.dao.search(f);
        var pages  = max(1, ceiling(result.total / f.pageSize));

        if (f.page > pages) {        // e.g. last row of the last page was deleted
            f.page   = pages;
            f.offset = (pages - 1) * f.pageSize;
            result   = variables.dao.search(f);
        }
        return {
            rows     = result.rows,
            total    = result.total,
            page     = f.page,
            pages    = pages,
            pageSize = f.pageSize,
            from     = result.total ? f.offset + 1 : 0,
            to       = min(f.offset + f.pageSize, result.total),
            filters  = f
        };
    }

    public struct function get(required numeric id) {
        return arguments.id > 0 ? variables.dao.getById(arguments.id) : {};
    }

    /** Existing departments merged with the built-in suggestions (for the form datalist / filter). */
    public array function departmentOptions(boolean includeSuggestions = false) {
        var list = [];
        for (var row in variables.dao.departments()) {
            arrayAppend(list, row.department);
        }
        if (arguments.includeSuggestions) {
            for (var d in variables.settings.suggestedDepartments) {
                if (!arrayFindNoCase(list, d)) {
                    arrayAppend(list, d);
                }
            }
            arraySort(list, "textnocase");
        }
        return list;
    }

    public struct function dashboard() {
        return {
            stats       = variables.dao.stats(variables.settings.recentHireDays),
            departments = variables.dao.departmentBreakdown(6),
            recent      = variables.dao.recentHires(6)
        };
    }

    public struct function checkSchema() {
        return variables.dao.checkSchema();
    }

    // ---- Commands -----------------------------------------------------------------

    /** @return struct: success, id, errors (struct field -> message), values */
    public struct function create(required struct raw) {
        var v = validate(arguments.raw, 0);
        if (!v.valid) {
            return {success = false, id = 0, errors = v.errors, values = v.values};
        }
        try {
            var id = variables.dao.insert(v.values);
            return {success = true, id = id, errors = {}, values = v.values};
        } catch (any e) {
            return failure(e, v);
        }
    }

    public struct function update(required numeric id, required struct raw) {
        if (structIsEmpty(variables.dao.getById(arguments.id))) {
            return {success = false, id = arguments.id, errors = {_general = "That employee no longer exists."}, values = {}, notFound = true};
        }
        var v = validate(arguments.raw, arguments.id);
        if (!v.valid) {
            return {success = false, id = arguments.id, errors = v.errors, values = v.values};
        }
        try {
            variables.dao.update(arguments.id, v.values);
            return {success = true, id = arguments.id, errors = {}, values = v.values};
        } catch (any e) {
            return failure(e, v);
        }
    }

    /** @return struct: success, message, name */
    public struct function remove(required numeric id) {
        var emp = variables.dao.getById(arguments.id);
        if (structIsEmpty(emp)) {
            return {success = false, message = "That employee no longer exists.", name = ""};
        }
        try {
            variables.dao.delete(arguments.id);
            return {success = true, message = "", name = emp.name};
        } catch (any e) {
            writeLog(type = "error", file = "employee_app", text = "Delete failed for id #arguments.id#: #e.message# | #e.detail#");
            return {success = false, message = "The employee could not be deleted. Please try again.", name = emp.name};
        }
    }

    // ---- Validation ---------------------------------------------------------------

    /**
     * Cleans and validates form input.
     * @return struct: valid, errors (field -> message), values (cleaned strings)
     */
    public struct function validate(required struct raw, numeric excludeId = 0) {
        var errors = {};
        var v = {
            name         = cleanText(pick(arguments.raw, "name")),
            email        = lcase(cleanText(pick(arguments.raw, "email"))),
            phone        = cleanText(pick(arguments.raw, "phone")),
            department   = cleanText(pick(arguments.raw, "department")),
            job_title    = cleanText(pick(arguments.raw, "job_title")),
            salary       = reReplace(pick(arguments.raw, "salary"), "[,\s]", "", "all"),
            joining_date = trim(pick(arguments.raw, "joining_date")),
            status       = trim(pick(arguments.raw, "status"))
        };

        // Name
        if (!len(v.name)) {
            errors.name = "Full name is required.";
        } else if (len(v.name) < 2 || len(v.name) > 100) {
            errors.name = "Name must be between 2 and 100 characters.";
        } else if (!createObject("java", "java.util.regex.Pattern").matches("[\p{L}\p{M}][\p{L}\p{M} .'\-]*", v.name)) {
            errors.name = "Name may contain letters, spaces, apostrophes, periods and hyphens only.";
        }

        // Email
        if (!len(v.email)) {
            errors.email = "Email address is required.";
        } else if (len(v.email) > 254 || !isValid("email", v.email) || !reFind("^[^\s@]+@[^\s@]+\.[A-Za-z]{2,}$", v.email)) {
            errors.email = "Enter a valid email address (up to 254 characters).";
        } else if (variables.dao.emailExists(v.email, arguments.excludeId)) {
            errors.email = "An employee with this email address already exists.";
        }

        // Phone (optional)
        if (len(v.phone)) {
            var digits = reReplace(v.phone, "\D", "", "all");
            if (!reFind("^\+?[0-9 ()\-.]{7,30}$", v.phone) || len(digits) < 7 || len(digits) > 15) {
                errors.phone = "Enter a valid phone number (7-15 digits; + ( ) - . and spaces allowed).";
            }
        }

        // Department / job title
        validateText(v, errors, "department", "Department");
        validateText(v, errors, "job_title", "Job title");

        // Salary (optional)
        if (len(v.salary)) {
            if (!reFind("^[0-9]{1,10}(\.[0-9]{1,2})?$", v.salary)) {
                errors.salary = "Salary must be a positive number with at most 2 decimal places.";
            } else {
                v.salary = numberFormat(v.salary, "0.00");
            }
        }

        // Joining date
        if (!len(v.joining_date)) {
            errors.joining_date = "Joining date is required.";
        } else if (!isRealIsoDate(v.joining_date)) {
            errors.joining_date = "Enter a valid date.";
        } else {
            var parsed = createDate(listGetAt(v.joining_date, 1, "-"), listGetAt(v.joining_date, 2, "-"), listGetAt(v.joining_date, 3, "-"));
            if (dateCompare(parsed, createDate(1950, 1, 1), "d") < 0) {
                errors.joining_date = "Joining date cannot be before 1950.";
            } else if (dateCompare(parsed, dateAdd("d", 365, now()), "d") > 0) {
                errors.joining_date = "Joining date cannot be more than a year in the future.";
            }
        }

        // Status
        if (!len(v.status)) {
            errors.status = "Employment status is required.";
        } else if (!arrayFind(variables.settings.statuses, v.status)) {
            errors.status = "Choose a valid employment status.";
        }

        return {valid = structIsEmpty(errors), errors = errors, values = v};
    }

    // ---- Internals ----------------------------------------------------------------

    private void function validateText(required struct v, required struct errors, required string field, required string label) {
        var value = arguments.v[arguments.field];
        if (!len(value)) {
            arguments.errors[arguments.field] = arguments.label & " is required.";
        } else if (len(value) < 2 || len(value) > 100) {
            arguments.errors[arguments.field] = arguments.label & " must be between 2 and 100 characters.";
        } else if (reFind("[<>]", value)) {
            arguments.errors[arguments.field] = arguments.label & " contains invalid characters.";
        }
    }

    /** Strict yyyy-mm-dd check (rejects 2024-02-30, which CFML's isDate may accept). */
    private boolean function isRealIsoDate(required string value) {
        if (!reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", arguments.value)) {
            return false;
        }
        try {
            createObject("java", "java.time.LocalDate").of(
                javaCast("int", listGetAt(arguments.value, 1, "-")),
                javaCast("int", listGetAt(arguments.value, 2, "-")),
                javaCast("int", listGetAt(arguments.value, 3, "-"))
            );
            return true;
        } catch (any e) {
            return false;
        }
    }

    /** Maps a persistence failure to a friendly result; duplicate-key races become a field error. */
    private struct function failure(required any e, required struct v) {
        var text = (structKeyExists(arguments.e, "message") ? arguments.e.message : "") & " " &
                   (structKeyExists(arguments.e, "detail") ? arguments.e.detail : "");
        if (findNoCase("duplicate entry", text) || findNoCase("uq_employees_email", text)) {
            return {success = false, id = 0, values = arguments.v.values,
                    errors = {email = "An employee with this email address already exists."}};
        }
        writeLog(type = "error", file = "employee_app", text = "Save failed: #arguments.e.message# | #text#");
        return {success = false, id = 0, values = arguments.v.values,
                errors = {_general = "The employee could not be saved because of a database problem. Please try again."}};
    }

    /** Trims, collapses whitespace, strips control characters. */
    private string function cleanText(required string value) {
        var s = reReplace(arguments.value, "[[:space:]]+", " ", "all");
        return trim(reReplace(s, "[[:cntrl:]]", "", "all"));
    }

    private string function pick(required struct source, required string key) {
        if (structKeyExists(arguments.source, arguments.key) && isSimpleValue(arguments.source[arguments.key])) {
            return arguments.source[arguments.key];
        }
        return "";
    }

}
