myApp.directive("mgController", ["DataService", function () {
    return {
        restrict: "E",
        require: "mgController",
        controller: function ($scope, $parse, $routeParams, DataService, $log) {
            var that = this, mgProcs = {};
            this.registerObject = function (name, options) {
                switch (options.type) {
                    case "array": $scope[name] = []; break;
                    case "object": $scope[name] = {}; break;
                    case "singleton": $scope[name] = {}; break;
                    default:
                        $log.error("mgController:registerObject:" + name + ":invalidType:" + type);
                        $scope[name] = null;
                        break;
                };
                mgProcs[name] = options;
            };
            $scope.Execute = this.Execute = function (name) {
                var o = mgProcs[name], parameters =  {}, shouldExecute = true;
                angular.forEach(o.parameters, function (item) {
                    var value = null;
                    switch (item.type) {
                        case "scope":
                            if (angular.isDefined($parse(item.value)($scope)))
                                value = $parse(item.value)($scope);
                            else
                                if (item.required === true) shouldExecute = false;
                            break;
                        case "route":
                            if (angular.isDefined($routeParams[item.value]))
                                value = $routeParams[item.value];
                            else {
                                if (item.required === true) shouldExecute = false;
                            };
                            break;
                        default: value = item.value; break;
                    };
                    parameters[item.name] = value;
                });
                if (shouldExecute === true) {
                    $log.debug("mgController:Execute:" + name);
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
            };
            this.initialize = function () {
                angular.forEach(mgProcs, function (options, name) {
                    if (options.autoexec) {
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
                $scope.$broadcast("mg.Initialized");
            };
        },
        link: function (scope, iElement, iAttrs, controller) { controller.initialize(); }
    };
}]);

myApp.directive("mgProc", function () {
    return {
        restrict: "E",
        require: "^^mgController",
        scope: { name: "@", source: "@", type: "@", root: "@", autoexec: "@" },
        controller: function ($scope) {
            switch (angular.lowercase($scope.type)) {
                case "object": $scope.type = "object"; break;
                case "singleton": $scope.type = "singleton"; break;
                default: $scope.type = "array"; break;
            };
            $scope.autoexec = (angular.lowercase($scope.autoexec) === "true") ? true : false;
            $scope.options = { source: $scope.source, type: $scope.type, root: $scope.root, parameters: [], autoexec: $scope.autoexec };
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

myApp.directive("mgForm", function () {
    return {
        restrict: "E",
        require: "^^mgController",
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
        scope: { heading: "@" },
        template: "<div class='panel panel-default'><div class='panel-heading'><h4>{{heading}}</h4></div><ng-transclude></ng-transclude></div>",
        transclude: true,
        replace: true,
        controller: function ($scope) { },
        link: function (scope, iElement, iAttrs, controller) { }
    }
});
