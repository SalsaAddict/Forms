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
        .when("/test/:First?/:Second?", { caseInsensitiveMatch: true, templateUrl: "views/test.html", controller: "TestController" })
        .otherwise({ redirectTo: "/home" });
});

myApp.controller("MainController", ["$scope", "$localStorage", "$location", function ($scope, $localStorage, $location) {
    $scope.navBarCollapsed = true;
    $scope.loggedIn = function () { return ($localStorage.JWT) ? true : false; };
    $scope.logout = function () { $localStorage.JWT = null; $location.path("/login"); };
}]);

myApp.controller("LoginController", ["$scope", "$http", "$localStorage", "$location", function ($scope, $http, $localStorage, $location) {

    $scope.failed = false;
    $scope.$local = $localStorage.$default({ JWT: null, email: null });
    $scope.password = null;

    $scope.login = function () {
        $http.post("login.ashx", { Email: $scope.$local.email, Password: $scope.password })
            .success(function (response) {
                if (response.Validated) {
                    $scope.$local.JWT = response.JWT;
                    $location.path("/home");
                }
                else {
                    $scope.failed = true;
                    $scope.$local.JWT = null;
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

myApp.controller("TestController", ["$scope", "$routeParams", "Procedure", function ($scope, $routeParams, Procedure) {

    $scope.routeParams = $routeParams;
    $scope.Id = 1;

    var p1 = new Procedure("apiEntity", "Entity", "singleton");
    p1.addScopeParameter("EntityId", "Id", true);
    p1.autoexec($scope, function () { window.alert(JSON.stringify($scope.Entity)); });

}]);

