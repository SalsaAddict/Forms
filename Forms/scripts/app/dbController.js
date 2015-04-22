myApp.factory("Procedure", ["$localStorage", "$parse", "$routeParams", "$http", "$modal", "$location", function ($localStorage, $parse, $routeParams, $http, $modal, $location) {
    function Procedure(name, output, type) {
        this.name = name;
        this.parameters = [];
        this.output = output;
        switch (angular.lowercase(type)) {
            case "object": this.type = "object"; break;
            case "singleton": this.type = "singleton"; break;
            default: this.type = "array"; break;
        };
        this.createPostData = function (scope) {
            var hasRequiredParameters = true;
            var postData = {
                JWT: $localStorage.JWT,
                Name: this.name,
                Parameters: [],
                Type: this.type
            };
            angular.forEach(this.parameters, function (item) {
                if (item.type === "user")
                    postData.Parameters.push({ Name: item.name, Value: item.name, XML: false });
                else {
                    var value = null, xml = false;
                    switch (item.type) {
                        case "route": value = $routeParams[item.value]; break;
                        case "scope": value = $parse(item.value)(scope); if (angular.isObject(value)) xml = true; break;
                        default: value = item.value; break;
                    };
                    if (item.required === true && !value)
                        hasRequiredParameters = false;
                    else if (value)
                        postData.Parameters.push({ Name: item.name, Value: value, XML: xml });
                };
            });
            if (hasRequiredParameters === true) return postData; else return null;
        };
        this.execute = function (scope, success, error) {
            var self = this, model = null;
            if (self.output) {
                model = $parse(self.output);
                model.assign(scope, (self.type === "array") ? [] : {});
            };
            var postData = this.createPostData(scope);
            if (postData) {
                $http.post("exec.ashx", postData)
                    .success(function (data) {
                        if (self.output) {
                            var result = (self.type === "singleton") ? data[0] : data;
                            if (result) model.assign(scope, result);
                        };
                        if (angular.isFunction(success)) success(data);
                    })
                    .error(function (data, status) {
                        var messageBox = $modal.open({
                            templateUrl: "/messageBox.html",
                            controller: "MessageBoxController",
                            backdrop: "static",
                            resolve: {
                                heading: function () {
                                    switch (status) {
                                        case 401: return "Access Denied"; break;
                                        default: return "Error"; break;
                                    };
                                },
                                message: function () {
                                    switch (status) {
                                        case 401: return data; break;
                                        default: return "An unexpected error occurred. Please try again. If the problem persists, please contact the Claimsuite support team."; break;
                                    };
                                },
                                buttonText: function () { return "OK"; }
                            }
                        })
                        .result.then(function (result) {
                            if (angular.isFunction(error)) error(data, status);
                            if (status == 401) {
                                $localStorage.JWT = null;
                                $location.path("/login");
                            };
                        });
                    });
            };
        };
    };
    Procedure.prototype = {
        addUserIdParameter: function () {
            this.parameters.push({
                name: "user",
                type: "user",
                value: "user",
                required: true
            });
        },
        addRouteParameter: function (parameterName, routeParamName, required) {
            this.parameters.push({
                name: parameterName,
                type: "route",
                value: routeParamName,
                required: !(required !== true)
            });
        },
        addScopeParameter: function (parameterName, scopeName, required) {
            this.parameters.push({
                name: parameterName,
                type: "scope",
                value: scopeName,
                required: !(required !== true)
            });
        },
        addValueParameter: function (parameterName, value) {
            this.parameters.push({
                name: parameterName,
                type: "value",
                value: value,
                required: true
            });
        },
        execute: function (scope, success, error) {
            return this.execute(scope, success, error);
        },
        autoexec: function (scope, success, error) {
            var self = this;
            self.execute(scope, success, error);
            angular.forEach(this.parameters, function (item) {
                if (item.type === "scope") {
                    scope.$watch(item.value, function (newValue, oldValue) {
                        if (newValue !== oldValue) {
                            self.execute(scope, success, error);
                        }
                    });
                };
            });
        }
    };
    return Procedure;
}]);