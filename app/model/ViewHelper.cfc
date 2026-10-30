/**
 * Presentation helpers: output encoding, formatting, avatars, URL building.
 * Every value that reaches HTML should pass through h() / ha().
 */
component output="false" {

    variables.avatarPalette = ["indigo", "violet", "teal", "rose", "amber", "sky", "emerald", "slate"];

    public ViewHelper function init(required any settings) {
        variables.settings = arguments.settings;
        return this;
    }

    /** HTML body encoding (XSS). Safe for null/empty/numbers. */
    public string function h(any value = "") {
        return encodeForHTML(isSimpleValue(arguments.value) ? toString(arguments.value) : "");
    }

    /** HTML attribute encoding. */
    public string function ha(any value = "") {
        return encodeForHTMLAttribute(isSimpleValue(arguments.value) ? toString(arguments.value) : "");
    }

    public string function fmtMoney(any value) {
        if (!isNumeric(arguments.value)) {
            return "";
        }
        return variables.settings.currencySymbol & numberFormat(arguments.value, ",0.00");
    }

    public string function fmtDate(any value, string mask = "mmm d, yyyy") {
        return isDate(arguments.value) ? dateFormat(arguments.value, arguments.mask) : "";
    }

    public string function fmtDateTime(any value) {
        return isDate(arguments.value) ? dateFormat(arguments.value, "mmm d, yyyy") & " " & timeFormat(arguments.value, "h:mm tt") : "";
    }

    /** Form value for <input type="date"> */
    public string function isoDate(any value) {
        return isDate(arguments.value) ? dateFormat(arguments.value, "yyyy-mm-dd") : "";
    }

    /** "2 yrs, 3 mos" style tenure from a joining date. */
    public string function tenure(any joined) {
        if (!isDate(arguments.joined)) {
            return "";
        }
        if (dateCompare(arguments.joined, now(), "d") > 0) {
            return "Starts " & dateFormat(arguments.joined, "mmm d, yyyy");
        }
        var months = dateDiff("m", arguments.joined, now());
        if (months < 1) {
            var days = dateDiff("d", arguments.joined, now());
            return days == 0 ? "Joined today" : days & (days == 1 ? " day" : " days");
        }
        var years = int(months / 12);
        var rest  = months mod 12;
        var parts = [];
        if (years) {
            arrayAppend(parts, years & (years == 1 ? " yr" : " yrs"));
        }
        if (rest) {
            arrayAppend(parts, rest & (rest == 1 ? " mo" : " mos"));
        }
        return arrayToList(parts, ", ");
    }

    public string function initials(required string name) {
        var words = listToArray(trim(arguments.name), " ");
        if (!arrayLen(words)) {
            return "?";
        }
        var letters = uCase(left(words[1], 1));
        if (arrayLen(words) > 1) {
            letters &= uCase(left(words[arrayLen(words)], 1));
        }
        return letters;
    }

    /** Stable colour class per name so an avatar never changes colour. */
    public string function avatarColor(required string name) {
        var sum = 0;
        for (var i = 1; i <= len(arguments.name); i++) {
            sum += asc(mid(arguments.name, i, 1));
        }
        return "avatar-" & variables.avatarPalette[(sum mod arrayLen(variables.avatarPalette)) + 1];
    }

    public string function statusClass(required string status) {
        switch (arguments.status) {
            case "Active":   return "status-active";
            case "On Leave": return "status-leave";
            default:         return "status-inactive";
        }
    }

    public string function statusIcon(required string status) {
        switch (arguments.status) {
            case "Active":   return "bi-check-circle-fill";
            case "On Leave": return "bi-clock-history";
            default:         return "bi-dash-circle-fill";
        }
    }

    /**
     * Builds a URL with an encoded query string.
     * @params struct of name -> value; empty values are skipped.
     */
    public string function link(required string path, struct params = {}) {
        var pairs = [];
        for (var key in arguments.params) {
            var value = arguments.params[key];
            if (isSimpleValue(value) && len(value)) {
                arrayAppend(pairs, encodeForURL(key) & "=" & encodeForURL(value));
            }
        }
        return arguments.path & (arrayLen(pairs) ? "?" & arrayToList(pairs, "&") : "");
    }

    /** URL of the directory page for the current filters, with optional overrides. */
    public string function directoryLink(required string path, required struct filters, struct overrides = {}) {
        var p = {
            q          = arguments.filters.search,
            department = arguments.filters.department,
            status     = arguments.filters.status,
            sort       = arguments.filters.sort,
            dir        = arguments.filters.dir,
            pageSize   = arguments.filters.pageSize,
            page       = arguments.filters.page
        };
        structAppend(p, arguments.overrides, true);
        if (p.sort == "name" && p.dir == "asc") {   // keep URLs tidy: defaults omitted
            p.sort = ""; p.dir = "";
        }
        if (isNumeric(p.page) && p.page <= 1) {
            p.page = "";
        }
        if (p.pageSize == variables.settings.defaultPageSize) {
            p.pageSize = "";
        }
        return link(arguments.path, p);
    }

    /** Page numbers to display: first, last and a window around the current page ("..." = 0). */
    public array function pageWindow(required numeric current, required numeric pages) {
        var out = [];
        var last = 0;
        for (var i = 1; i <= arguments.pages; i++) {
            if (i == 1 || i == arguments.pages || abs(i - arguments.current) <= 1) {
                if (last && i - last > 1) {
                    arrayAppend(out, 0);
                }
                arrayAppend(out, i);
                last = i;
            }
        }
        return out;
    }

}
