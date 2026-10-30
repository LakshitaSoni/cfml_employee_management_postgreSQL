/**
 * Immutable application settings derived from the environment.
 * Holds no credentials: the database login lives only in the datasource.
 */
component output="false" {

    public Settings function init(required struct env, required string datasource) {
        this.datasource    = arguments.datasource;

        // The table name is interpolated into SQL (identifiers cannot be bound), so it is strictly validated.
        if (!reFind("^[A-Za-z0-9_]{1,64}$", arguments.env.DB_TABLE)) {
            throw(type = "InvalidSetting", message = "DB_TABLE may only contain letters, digits and underscores.");
        }
        this.table         = arguments.env.DB_TABLE;
        this.appEnv        = lcase(arguments.env.APP_ENV);
        this.isDevelopment = (this.appEnv == "development");

        // Currency symbols are built from code points so source file encoding never matters.
        var symbols = {
            INR = chr(8377), USD = "$", EUR = chr(8364), GBP = chr(163),
            JPY = chr(165), AUD = "A$", CAD = "C$", AED = "AED "
        };
        var code = ucase(arguments.env.APP_CURRENCY);
        this.currencySymbol = structKeyExists(symbols, code) ? symbols[code] : symbols.INR;

        var size = val(arguments.env.APP_PAGE_SIZE);
        this.pageSizes       = [10, 25, 50];
        this.defaultPageSize = arrayFind(this.pageSizes, size) ? size : 10;

        this.statuses = ["Active", "On Leave", "Inactive"];

        // Suggestions only - the department field accepts any value; existing
        // departments from the database are merged into this list at runtime.
        this.suggestedDepartments = [
            "Engineering", "Human Resources", "Finance", "Sales", "Marketing",
            "Operations", "Design", "Customer Support", "Legal"
        ];

        this.recentHireDays = 30;
        return this;
    }

}
