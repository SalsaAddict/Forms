var myApp = angular.module("myApp", ["ngRoute", "ngStorage", "ui.bootstrap"]);

myApp.config(function ($logProvider, $routeProvider) {
    $logProvider.debugEnabled(true);
    $routeProvider
        .when("/login", { caseInsensitiveMatch: true, templateUrl: "views/login.html", controller: "LoginController" })
        .when("/home", { caseInsensitiveMatch: true, templateUrl: "views/home.html" })
        .when("/exec", { caseInsensitiveMatch: true, templateUrl: "views/exec.html" })
        .when("/entities", { caseInsensitiveMatch: true, templateUrl: "views/entities.html" })
        .when("/entity", { caseInsensitiveMatch: true, templateUrl: "views/entity.html", controller: "EntityController" })
        .when("/entity/:EntityId", { caseInsensitiveMatch: true, templateUrl: "views/entity.html", controller: "EntityController" })
        .otherwise({ redirectTo: "/home" });
});

myApp.service("AuthService", ["$window", function ($window) {

}]);

myApp.controller("LoginController", ["$scope", "$http", "$sessionStorage", "$localStorage", "$location", function ($scope, $http, $sessionStorage, $localStorage, $location) {

    $scope.failed = false;
    $scope.$session = $sessionStorage.$default({ JWT: null, User: null });
    $scope.$local = $localStorage.$default({ email: null });
    $scope.password = null;

    $scope.login = function () {
        $http.post("login.ashx", { Email: $scope.$local.email, Password: $scope.password })
            .success(function (response) {
                if (response.Validated) {
                    $scope.$session.JWT = response.JWT;
                    $scope.$session.User = response.User;
                    $location.path("/home");
                }
                else {
                    $scope.failed = true;
                    $scope.$session.JWT = null;
                    $scope.$session.User = null;
                };
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