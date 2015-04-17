var myApp = angular.module("myApp", ["ngRoute", "ngStorage", "ui.bootstrap"]);

myApp.config(function ($routeProvider) {
    $routeProvider
        .when("/test/:sId", {
            caseInsensitiveMatch: true,
            templateUrl: "views/test.html"
        })
        .when("/home", {
            caseInsensitiveMatch: true,
            templateUrl: "views/home.html"
        })
        .when("/exec", {
            caseInsensitiveMatch: true,
            templateUrl: "views/exec.html"
        })
        .when("/entities", {
            caseInsensitiveMatch: true,
            templateUrl: "views/entities.html",
            controller: "EntitiesController"
        })
        .when("/entity", {
            caseInsensitiveMatch: true,
            templateUrl: "views/entity.html",
            controller: "EntityController"
        })
        .when("/entity/:EntityId", {
            caseInsensitiveMatch: true,
            templateUrl: "views/entity.html",
            controller: "EntityController"
        })
        .otherwise({ redirectTo: "/home" });
});

myApp.service("DataService", ["$http", function ($http) {

    this.Execute = function (Name, Parameters, ReturnsXML) {
        var NVArray = [], XML = null;
        angular.forEach(Parameters, function (Value, Key) {
            if (Value) {
                if (Key == "XML")
                    XML = Value;
                else
                    NVArray.push({ Name: Key, Value: Value });
            };
        });
        return $http.post("exec.ashx?rx=" + !(ReturnsXML !== true), { Name: Name, Parameters: NVArray, XML: XML });
    };

}]);

myApp.controller("EntitiesController", ["$scope", "DataService", function ($scope, DataService) {

    $scope.Entities = [];

    DataService.Execute("pr_Entities", null, true).success(function (Response) { $scope.Entities = Response.Root.Entities; });

}]);

myApp.controller("EntityController", ["$scope", "$routeParams", "DataService", function ($scope, $routeParams, DataService) {

    $scope.Entity = {};

    $scope.Load = function (EntityId) {
        DataService.Execute("pr_Entity", { Id: EntityId }, true)
            .success(function (Response) {
                $scope.Entity = Response.Entity;
            });
    };

    $scope.Save = function () {
        DataService.Execute("pr_Entity_Save", { XML: { Entity: $scope.Entity } }, true)
            .success(function (Response) {
                $scope.Entity = Response.Entity;
            })
            .error(function (Response) {
                window.alert(Response);
            });
    };

    if ($routeParams.EntityId) { $scope.Load($routeParams.EntityId); };

}]);