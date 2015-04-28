myApp.service("SqlUiUtils", ["$filter", function ($filter) {

    var self = this;

    this.IfBlank = function (value, defaultValue, allowedValues) {
        if (!value) return defaultValue;
        else if (!angular.isArray(allowedValues)) return value;
        else {
            if ($filter("filter")(allowedValues, value, function (actual, expected) {
                return (actual.toString().trim().toLowerCase() === expected.toString().trim().toLowerCase());
            }).length > 0) return value; else return defaultValue;
        };
    };

    this.Boolean = function (value) {
        var bvalue = self.IfBlank(value, "false", ["true", "1", "yes"]).toString().trim().toLowerCase();
        return (bvalue === "false") ? false : true;
    };

}]);