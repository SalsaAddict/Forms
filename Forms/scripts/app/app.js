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

myApp.controller("EntitiesController", ["$scope", "$http", function ($scope, $http) {

    $scope.Entities = [];

    $http.post("exec.ashx?rx=true", { Name: "pr_Entities" })
        .success(function (Response) {
            $scope.Entities = Response.Root.Entities;
        });

}]);

myApp.controller("EntityController", ["$scope", "$routeParams", "$http", function ($scope, $routeParams, $http) {

    $scope.Entity = {};

    $scope.Load = function (EntityId) {
        $http.post("exec.ashx?rx=true", { Name: "pr_Entity", Parameters: [{ Name: "Id", Value: EntityId }] })
            .success(function (Response) {
                $scope.Entity = Response.Entity;
            });
    };

    $scope.Save = function () {
        var EntityId = $scope.Entity.Id;
        $http.post("exec.ashx?rx=true", { Name: "pr_Entity_Save", XML: { Entity: $scope.Entity } })
            .success(function (Response) {
                $scope.Entity = Response.Entity;
            })
            .error(function (Response) {
                window.alert(Response);
            });
    };

    if ($routeParams.EntityId) { $scope.Load($routeParams.EntityId); };



}]);