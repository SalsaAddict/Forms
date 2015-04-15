var myApp = angular.module("myApp", ["ngRoute", "ngStorage", "ui.bootstrap"]);

myApp.config(function ($routeProvider) {
    $routeProvider
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

myApp.service("FormService", ["$http", function ($http) {

    this.Execute = function (Name, Parameters, ReturnsXML) {
        var NVArray = [], XML = null;
        angular.forEach(Parameters, function (Value, Key) {
            if (Key == "XML")
                XML = Value;
            else
                NVArray.push({ Name: Key, Value: Value });
        });
        return $http.post("exec.ashx?rx=" + !(ReturnsXML !== true), { Name: Name, Parameters: NVArray, XML: XML });
    };

}]);

myApp.controller("EntitiesController", ["$scope", "FormService", function ($scope, FormService) {

    $scope.Entities = [];

    FormService.Execute("pr_Entities", null, true).success(function (Response) { $scope.Entities = Response.Root.Entities; });

}]);

myApp.controller("EntityController", ["$scope", "$routeParams", "FormService", function ($scope, $routeParams, FormService) {

    $scope.Entity = {};

    $scope.Load = function (EntityId) {
        FormService.Execute("pr_Entity", { Id: EntityId }, true)
            .success(function (Response) {
                $scope.Entity = Response.Entity;
            });
    };

    $scope.Save = function () {
        FormService.Execute("pr_Entity_Save", { XML: { Entity: $scope.Entity } }, true)
            .success(function (Response) {
                $scope.Entity = Response.Entity;
            })
            .error(function (Response) {
                window.alert(Response);
            });
    };

    if ($routeParams.EntityId) { $scope.Load($routeParams.EntityId); };

}]);