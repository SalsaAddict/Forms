﻿myApp.directive("mgData", ["DataService", function () {
    return {
        restrict: "E",
        require: "mgData",
        controller: function ($scope, $parse, $routeParams, DataService) {
            var that = this, mgObjects = {};
            this.registerObject = function (name, options) {
                switch (options.type) {
                    case "array": $scope[name] = []; break;
                    case "object": $scope[name] = {}; break;
                    case "singleton": $scope[name] = {}; break;
                    default: $scope[name] = null; break;
                };
                mgObjects[name] = options;
            };
            this.loadObject = function (name) {
                var o = mgObjects[name], parameters = {};
                angular.forEach(o.parameters, function (item) {
                    switch (item.type) {
                        case "scope": parameters[item.name] = $parse(item.value)($scope); break;
                        case "route": parameters[item.name] = $routeParams[item.value]; break;
                        default: parameters[item.name] = item.value; break;
                    };
                });
                DataService.Execute(o.source, parameters, (o.type === "object") ? true : false)
                    .success(function (data) {
                        switch (o.type) {
                            case "array": $scope[name] = data; break;
                            case "object": if (o.root) $scope[name] = data[o.root]; else $scope[name] = data; break;
                            case "singleton": $scope[name] = data[0]; break;
                            default: $scope[name] = data; break;
                        };
                    });
            };
            this.initialize = function () {
                angular.forEach(mgObjects, function (options, name) {
                    that.loadObject(name);
                    angular.forEach(options.parameters, function (item) {
                        if (item.type === "scope") {
                            $scope.$watch(item.value, function (newValue, oldValue) {
                                if (newValue !== oldValue) {
                                    that.loadObject(name);
                                }
                            });
                        };
                    });
                });
            };
        },
        link: function (scope, iElement, iAttrs, controller) { controller.initialize(); }
    };
}]);

myApp.directive("mgObject", function () {
    return {
        restrict: "E",
        require: "^^mgData",
        scope: { name: "@", source: "@", type: "@", root: "@" },
        controller: function ($scope) {
            switch (angular.lowercase($scope.type)) {
                case "object": $scope.type = "object"; break;
                case "singleton": $scope.type = "singleton"; break;
                default: $scope.type = "array"; break;
            };
            $scope.options = { source: $scope.source, type: $scope.type, root: $scope.root, parameters: [] };
            this.addParameter = function (parameter) { $scope.options.parameters.push(parameter); };
        },
        link: {
            pre: function (scope, iElement, iAttrs, controller) {
                controller.registerObject(scope.name, scope.options);
            },
            post: function (scope, iElement, iAttrs, controller) { iElement.remove(); }
        }
    };
});

myApp.directive("mgParameter", function () {
    return {
        restrict: "E",
        require: "^^mgObject",
        scope: { name: "@", type: "@", value: "@" },
        controller: function ($scope) {
            switch (angular.lowercase($scope.type)) {
                case "scope": $scope.type = "scope"; break;
                case "route": $scope.type = "route"; break;
                default: $scope.type = "const"; break;
            };
            $scope.parameter = { name: $scope.name, type: $scope.type, value: $scope.value };
        },
        link: {
            pre: function (scope, iElement, iAttrs, controller) {
                controller.addParameter(scope.parameter);
            }
        }
    };
});

myApp.directive("mgForm", function () {
    return {
        restrict: "E",
        require: "^^mgData",
        scope: true,
        template: "<form class='form-horizontal' ng-transclude></form>",
        transclude: true,
        replace: true,
        controller: function ($scope) {

        },
        link: function (scope, iElement, iAttrs, controller) { }
    }
});

myApp.directive("mgPanel", function () {
    return {
        restrict: "E",
        require: "^^mgForm",
        scope: true,
        template: "<div class='panel panel-default' ng-transclude></div>",
        transclude: true,
        replace: true,
        controller: function ($scope) { },
        link: function (scope, iElement, iAttrs, controller) { }
    }
});

myApp.directive("mgPanelHeading", function () {
    return {
        restrict: "E",
        require: "^^mgPanel",
        scope: true,
        template: "<div class='panel-heading'><h4 ng-transclude></h4></div>",
        transclude: true,
        replace: true,
        controller: function ($scope) { },
        link: function (scope, iElement, iAttrs, controller) { }
    }
});