var myApp = angular.module("myApp", ["ngRoute", "ngStorage", "ui.bootstrap"]);

myApp.config(function ($logProvider, $routeProvider) {
    $logProvider.debugEnabled(true);
    $routeProvider
        .when("/login", { caseInsensitiveMatch: true, templateUrl: "views/login.html", controller: "LoginController" })
        .when("/home", { caseInsensitiveMatch: true, templateUrl: "views/home.html" })
        .when("/exec", { caseInsensitiveMatch: true, templateUrl: "views/exec.html" })
        .when("/entities", { caseInsensitiveMatch: true, templateUrl: "views/entities.html", controller: "EntitiesController" })
        .when("/entity", { caseInsensitiveMatch: true, templateUrl: "views/entity.html", controller: "EntityController" })
        .when("/entity/:EntityId", { caseInsensitiveMatch: true, templateUrl: "views/entity.html", controller: "EntityController" })
        .when("/test/:EntityId?", { caseInsensitiveMatch: true, templateUrl: "views/test.html", controller: "TestController" })
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

myApp.controller("EntitiesController", ["$scope", "procedure", function ($scope, procedure) {

    var list = new procedure({ name: "apiEntities", type: "array", model: "Entities", });
    list.execute($scope);

}]);

myApp.controller("EntityController", ["$scope", "procedure", "$routeParams", "$location", function ($scope, procedure, $routeParams, $location) {

    var action = ($routeParams.EntityId) ? "Update" : "Insert";
    var apiSave = new procedure({
        name: "apiEntity" + action,
        parameters: [
            { name: "Name", type: "scope", value: "Entity.Name" },
            { name: "Address", type: "scope", value: "Entity.Address" },
            { name: "PostalCode", type: "scope", value: "Entity.PostalCode" },
            { name: "CountryId", type: "scope", value: "Entity.CountryId" }
        ],
        type: "array",
        model: "Entity"
    });
    window.alert(JSON.stringify(apiSave.postData()));

    var apiEntity = new procedure({ name: "apiEntity", parameters: [{ name: "EntityId", type: "route", required: true }], type: "singleton", model: "Entity" });
    apiEntity.execute($scope);

    var apiEntityTypes = new procedure({
        name: "apiEntityTypes", type: "array", model: "Types",
        success: function (data) {
            angular.forEach(data, function (item) {
                apiSave.addParameter({ name: item.Code, type: "scope", value: "Entity." + item.code });
            });
            window.alert(JSON.stringify(apiSave.postData()));
        }
    });
    apiEntityTypes.execute($scope);

    var apiCountries = new procedure({ name: "apiCountries", type: "array", model: "Countries" });
    apiCountries.execute($scope);

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

myApp.controller("TestController", ["$scope", "$routeParams", "procedure", function ($scope, $routeParams, procedure) {

    $scope.routeParams = $routeParams;
    $scope.Id = 1;

    var p1 = new procedure({
        name: "apiEntity",
        parameters: [{ name: "EntityId", type: "scope", value: "Id", required: true }],
        type: "singleton",
        model: "Entity",
        success: function (data) { window.alert(JSON.stringify(data)); },
        error: function (data, status) { window.alert(status); }
    });
    p1.autoexec($scope);

}]);

