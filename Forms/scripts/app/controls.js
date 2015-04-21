myApp.service("DataService", ["$http", "$log", "$sessionStorage", "$location", "$modal", function ($http, $log, $sessionStorage, $location, $modal) {
    this.Execute = function (Name, Parameters, ReturnsXML, success, error) {
        var JWT = $sessionStorage.$default({ JWT: null }).JWT;
        var NVArray = [], XML = null;
        angular.forEach(Parameters, function (value, key) {
            if (value) {
                var XML = angular.isObject(value);
                NVArray.push({ Name: key, Value: value, XML: XML });
            };
        });
        return $http.post("exec.ashx?rx=" + ((ReturnsXML === true) ? "true" : "false"), { JWT: JWT, Name: Name, Parameters: NVArray, XML: XML })
            .success(function (response) { if (angular.isFunction(success)) success(response); })
            .error(function (response, status) {
                $log.error(status + ":" + response);
                var messageBox = $modal.open({
                    templateUrl: "/messageBox.html",
                    controller: "MessageBoxController",
                    size: "sm",
                    backdrop: "static",
                    resolve: {
                        heading: function () { return "Access Denied"; },
                        message: function () {
                            switch (response) {
                                case "Missing token.": return "You are not logged in. Please login and try again."; break;
                                default: return response; break;
                            };
                        },
                        buttonText: function () { return "OK"; }
                    }
                })
                .result.then(function (result) { $location.path("/login"); });
                if (angular.isFunction(error)) error(response);
            });
    };
}]);

myApp.controller("MessageBoxController", function ($scope, $modalInstance, heading, message, buttonText) {
    $scope.heading = heading;
    $scope.message = message;
    $scope.buttonText = buttonText;
    $scope.close = function () { $modalInstance.close(); };
});

myApp.directive("mgController", ["DataService", function () {
    return {
        restrict: "E",
        require: "mgController",
        controller: function ($scope, $parse, $routeParams, DataService, $log) {
            var that = this, mgProcs = {};
            this.registerProc = function (name, options) {
                mgProcs[name] = options;
                if (options.ngModel) $scope.$eval(options.ngModel + " = " + ((options.type === "array") ? "[]" : "{}"))
            };
            $scope.Execute = this.Execute = function (name, success, error) {
                var o = mgProcs[name], parameters = {}, shouldExecute = true;
                angular.forEach(o.parameters, function (item) {
                    var value = null;
                    switch (item.type) {
                        case "scope": value = $parse(item.value)($scope); break;
                        case "route": value = $routeParams[item.value]; break;
                        default: value = item.value; break;
                    };
                    if (item.required === true && angular.isUndefined(value))
                        shouldExecute = false;
                    else
                        parameters[item.name] = value;
                });
                if (shouldExecute === true) {
                    $log.debug("mgController:Execute:" + name);
                    DataService.Execute(name, parameters, (o.type === "object") ? true : false, success, error)
                        .success(function (data) {
                            if (o.ngModel) {
                                ngModel = $parse(o.ngModel);
                                switch (o.type) {
                                    case "object": if (o.root) ngModel.assign($scope, data[o.root]); else ngModel.assign($scope, data); break;
                                    case "singleton": ngModel.assign($scope, data[0]); break;
                                    default: ngModel.assign($scope, data); break;
                                };
                            };
                        });
                };
            };
            this.initialize = function () {
                angular.forEach(mgProcs, function (options, name) {
                    if (options.autoexec === true) {
                        that.Execute(name);
                        angular.forEach(options.parameters, function (item) {
                            if (item.type === "scope") {
                                $scope.$watch(item.value, function (newValue, oldValue) {
                                    if (newValue !== oldValue) {
                                        that.Execute(name);
                                    }
                                });
                            };
                        });
                    };
                });
                $scope.$broadcast("mgController.initialized");
            };
        },
        link: function (scope, iElement, iAttrs, controller) { controller.initialize(); }
    };
}]);

myApp.directive("mgProc", function () {
    return {
        restrict: "E",
        require: "^^mgController",
        scope: { name: "@", type: "@", root: "@", ngModel: "@", autoexec: "@" },
        controller: function ($scope) {
            switch (angular.lowercase($scope.type)) {
                case "object": $scope.type = "object"; break;
                case "singleton": $scope.type = "singleton"; break;
                default: $scope.type = "array"; break;
            };
            $scope.autoexec = (angular.lowercase($scope.autoexec === "true")) ? true : false;
            $scope.options = { type: $scope.type, root: $scope.root, parameters: [], ngModel: $scope.ngModel, autoexec: $scope.autoexec };
            this.addParameter = function (parameter) { $scope.options.parameters.push(parameter); };
        },
        link: {
            pre: function (scope, iElement, iAttrs, controller) {
                controller.registerProc(scope.name, scope.options);
            }
        }
    };
});

myApp.directive("mgProcParam", function () {
    return {
        restrict: "E",
        require: "^^mgProc",
        scope: { name: "@", type: "@", value: "@", required: "@" },
        controller: function ($scope) {
            switch (angular.lowercase($scope.type)) {
                case "scope": $scope.type = "scope"; break;
                case "route": $scope.type = "route"; break;
                default: $scope.type = "const"; break;
            };
            $scope.required = (angular.lowercase($scope.required) === "true") ? true : false;
            $scope.parameter = { name: $scope.name, type: $scope.type, value: $scope.value, required: $scope.required };
        },
        link: {
            pre: function (scope, iElement, iAttrs, controller) {
                controller.addParameter(scope.parameter);
            }
        }
    };
});

myApp.directive("mgForm", ["$window", "$location", "$route", function ($window, $location, $route) {
    return {
        restrict: "E",
        require: "^^mgController",
        templateUrl: "controls/mgForm.html",
        transclude: true,
        scope: { name: "@", heading: "@", backRoute: "@back", saveProc: "@", deleteProc: "@", success: "=", error: "=" },
        controller: function ($scope) {
            this.form = $scope.form = function () { return $scope[$scope.name]; };
            $scope.editable = ($scope.saveProc) ? true : false;
            $scope.deletable = ($scope.deleteProc) ? true : false;
            $scope.back = function () { if ($scope.back) $location.path($scope.backRoute); else $window.history.back(); };
            $scope.undo = function () { $route.reload(); };
        },
        link: function (scope, iElement, iAttrs, controller) {
            scope.save = function () {
                controller.Execute(scope.saveProc);
                scope.form().$setPristine();
            };
            scope.delete = function () {
                controller.Execute(scope.deleteProc);
                scope.back();
            };
        }
    }
}]);

myApp.directive("mgField", function () {
    return {
        restrict: "E",
        require: "^^mgForm",
        templateUrl: "controls/mgLabel.html",
        transclude: true,
        scope: { labelFor: "@for", labelText: "@text" },
        controller: function ($scope) { this.labelFor = $scope.labelFor; },
        link: function (scope, iElement, iAttrs, controller) {
            scope.form = function () { return controller.form(); };
        }
    };
});

myApp.directive("mgControl", function () {
    return {
        restrict: "A",
        require: "^^mgField",
        link: function (scope, iElement, iAttrs, controller) {
            if (!iElement.hasClass("form-control")) iElement.addClass("form-control");
            iElement.attr("id", controller.labelFor);
        }
    };
});