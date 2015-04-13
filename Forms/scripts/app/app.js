var myApp = angular.module("myApp", ["ngRoute", "ngStorage", "ui.bootstrap"]);

myApp.config(function ($routeProvider) {
    $routeProvider
        .when("/home", {
            templateUrl: "views/home.html",
            controller: "HomeController"
        })
        .when("/home/:Id", {
            templateUrl: "views/home.html",
            controller: "HomeController"
        })
        .otherwise({ redirectTo: "/home" });
});

myApp.directive("myForm", ["$http", "$route", "$routeParams", function ($http, $route, $routeParams) {
    return {
        restrict: "E",
        templateUrl: "directives/myForm.html",
        controller: function ($scope) {

            $http.post("exec.ashx?rx=true", { Name: "pr_UiForm", Parameters: [{ Name: "Id", Value: $scope.Form.Id }] })
                .success(function (Data) { $scope.Form = Data.Form; $scope.Form.Edit = false; });

            $scope.SetupField = function (Field) {

            };

        }
    };
}]);

myApp.controller("HomeController", ["$scope", "$route", function ($scope, $route) {

    $scope.Form = { Id: "UiForm" };

}]);

