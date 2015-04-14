var $routeProviderRef;

var myApp = angular.module("myApp", ["ngRoute", "ngStorage", "ui.bootstrap"]);

myApp.config(function ($routeProvider) { $routeProviderRef = $routeProvider; });

myApp.run(function ($http, $route) {
    $http.post("exec.ashx", { Name: "pr_UiRoutes" }).success(function (Data) {
        angular.forEach(Data, function (Value) {
            var Route = Value.Route, Parameters = Value.Parameters;
            $routeProviderRef
                .when(Route, {
                    caseInsensitiveMatch: true,
                    templateUrl: "views/form.html",
                    controller: "FormController",
                    resolve: { Route: function () { return Route; } }
                })
                .when(Route + Parameters, {
                    caseInsensitiveMatch: true,
                    templateUrl: "views/form.html",
                    controller: "FormController",
                    resolve: { Route: function () { return Route; } }
                });
        });
        $routeProviderRef
            .when("/home", {
                caseInsensitiveMatch: true,
                templateUrl: "views/home.html",
                controller: "HomeController",
            })
            .when("/exec", {
                caseInsensitiveMatch: true,
                templateUrl: "views/exec.html",
                controller: "ExecController",
            })
            .otherwise({ redirectTo: "/home" });
        $route.reload();
    });
});

myApp.controller("HomeController", ["$scope", "$route", function ($scope, $route) {

    $scope.Form = { Id: "UiForm" };

}]);

myApp.controller("ExecController", ["$scope", "$localStorage", "$http", function ($scope, $localStorage, $http) {

    $scope.$storage = $localStorage.$default({ Input: { Name: "", Parameters: [] }, Handler: "exec.ashx", RX: false} );

    $scope.Output = {};

    $scope.Exec = function () {
        $http.post($scope.$storage.Handler + "?rx=" + $scope.$storage.RX, $scope.$storage.Input).success(function (Data) { $scope.Output = Data; });
    };

}]);

myApp.controller("FormController", ["$scope", "$http", "$routeParams", "$filter", "Route", function ($scope, $http, $routeParams, $filter, Route) {

    $http.post("exec.ashx?rx=true", { Name: "pr_UiForm", Parameters: [{ Name: "Route", Value: Route }] })
        .success(function (Data) {
            $scope.Form = Data.Form; $scope.Form.Edit = false;
            var Parameters = [];
            angular.forEach($routeParams, function (Value, Key) {
                Parameters.push({ Name: Key, Value: Value });
            });
            if ($routeParams) {
                $http.post("read.ashx", { Name: $scope.Form.Id, Parameters: Parameters }).success(function (Data) {

                    $scope.Data = Data[0]
                });
            };
        });

    $scope.Data = {};
    $scope.Lists = {};

    $scope.SetupField = function (Field) {
        $scope.Data[Field.Id] = "";
        if (Field.List) {
            $scope.Lists[Field.Id] = angular.copy(Field.List);
            $scope.FetchList(Field.Id);
            if (angular.isArray(Field.List.Parameters)) {
                for (i = 0; i < Field.List.Parameters.length; i++) {
                    var Parameter = Field.List.Parameters[i];
                    if (Parameter.Type == "Field") {
                        $scope.$watch("Data." + Parameter.Value, function (newValue, oldValue) {
                            if (newValue !== oldValue) { $scope.FetchList(Field.Id); };
                        });
                    }
                };
            };
        };
    };

    $scope.FetchList = function (FieldId) {
        var List = $scope.Lists[FieldId];
        var StoredProcedure = { Name: List.Name, Parameters: [] };
        if (angular.isArray(List.Parameters)) {
            for (i = 0; i < List.Parameters.length; i++) {
                var Parameter = List.Parameters[i];
                var OutParam = {};
                OutParam.Name = Parameter.Name;
                switch (Parameter.Type) {
                    case "Const": OutParam.Value = Parameter.Value; break;
                    case "Field": OutParam.Value = $scope.Data[Parameter.Value]; break;
                };
                StoredProcedure.Parameters.push(OutParam);
            };
        };
        $scope.Data[FieldId] = "";
        $http.post("exec.ashx", StoredProcedure).success(function (data) {
            if (angular.isArray(data)) { List.Values = data; } else { List.Values = []; }
        });
    };

    $scope.List = function (FieldId) {
        return $scope.Lists[FieldId].Values;
    };

    $scope.ListValue = function (FieldId) {
        if ($scope.Data[FieldId]) {
            var List = $scope.Lists[FieldId];
            if (List.Values) {
                var Items = ($filter("filter")(List.Values, function (Item) { return Item[List.ValueField] == $scope.Data[FieldId]; }));
                if (Items) {
                    var Item = Items[0];
                    return Item[List.TextField];
                };
            };
        };
    };

    $scope.ValidateField = function (Field) {
        return !($scope.Form.Edit && Field.Required && !($scope.Data[Field.Id]));
    };

    $scope.ValidateTab = function (Tab) {
        return ($filter("filter")(Tab.Fields, function (Field) {
            return !$scope.ValidateField(Field);
        })).length == 0;
    };

    $scope.ValidateForm = function (Form) {
        return ($filter("filter")(Form.Tabs, function (Tab) {
            return !$scope.ValidateTab(Tab);
        })).length == 0;
    };

}]);