﻿var myApp = angular.module("myApp", ["ngRoute", "ngResource", "ngStorage", "ui.bootstrap"]);

myApp.config(function ($logProvider, $routeProvider) {
    $logProvider.debugEnabled(true);
    $routeProvider
        .when("/home", { caseInsensitiveMatch: true, templateUrl: "views/home.html" })
        .when("/exec", { caseInsensitiveMatch: true, templateUrl: "views/exec.html" })
        .when("/entities", { caseInsensitiveMatch: true, templateUrl: "views/entities.html" })
        .when("/entity", { caseInsensitiveMatch: true, templateUrl: "views/entity.html", controller: "EntityController" })
        .when("/entity/:EntityId", { caseInsensitiveMatch: true, templateUrl: "views/entity.html", controller: "EntityController" })
        .otherwise({ redirectTo: "/home" });
});

myApp.controller("MainController", ["$scope", "$modal", function ($scope, $modal) {

    $scope.login = function () {
        var modalLogin = $modal.open({
            templateUrl: "/login.html",
            controller: "LoginController"
        });
    };

}]);

myApp.controller("LoginController", ["$scope", "$http", function ($scope, $http) {

    $scope.login = function (email, password) {
        $http.post("login.ashx", { Email: $scope.email, Password: $scope.password })
            .success(function (response) {
                window.alert(JSON.stringify(response));
            });
    };

}]);

myApp.controller("EntityController", ["$scope", "$routeParams", "$location", function ($scope, $routeParams, $location) {

    $scope.inserting = function () { return ($routeParams.EntityId) ? false : true; };

    $scope.saveProc = function () { return ($scope.inserting() === true) ? "apiEntityInsert" : "apiEntityUpdate"; };

    $scope.PostalCodeLabel = function () {
        switch ($scope.Entity.CountryId) {
            case "UK": return "Postcode"; break;
            case "US": return "ZIP Code"; break;
            default: return "Postal Code"; break;
        };
    };

}]);