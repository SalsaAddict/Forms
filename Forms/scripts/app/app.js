var myApp = angular.module("myApp", ["ngRoute", "ngStorage", "ui.bootstrap"]);

myApp.config(function ($logProvider, $routeProvider) {
    $logProvider.debugEnabled(false);
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

myApp.run(["$rootScope", "$localStorage", "$location", function ($rootScope, $localStorage, $location) {
    $rootScope.navBarCollapsed = true;
    $rootScope.loggedIn = function () { return ($localStorage.JWT) ? true : false; };
    $rootScope.logout = $rootScope.login = function () { $localStorage.JWT = null; $location.path("/login"); };
}]);

myApp.controller("EntitiesController", ["$scope", "SqlUi", function ($scope, SqlUi) {

    var list = SqlUi.StoredProcedure({ name: "apiEntities", type: "array", model: "Entities", });
    list.execute($scope);

}]);

myApp.controller("EntityController", ["$scope", "SqlUi", "$routeParams", "$location", function ($scope, SqlUi, $routeParams, $location) {

    var apiSave = SqlUi.StoredProcedure({
        name: "apiEntity" + ($routeParams.EntityId) ? "Update" : "Insert",
        parameters: [
            { name: "Name", type: "scope", value: "Entity.Name", required: true },
            { name: "Address", type: "scope", value: "Entity.Address" },
            { name: "PostalCode", type: "scope", value: "Entity.PostalCode" },
            { name: "CountryId", type: "scope", value: "Entity.CountryId" }
        ],
        type: "array",
        model: "Entity"
    });
    if ($routeParams.EntityId) apiSave.addParameter({ name: "EntityId", type: "route", required: true });

    var apiEntity = SqlUi.StoredProcedure({ name: "apiEntity", parameters: [{ name: "EntityId", type: "route", required: true }], type: "singleton", model: "Entity" });
    apiEntity.execute($scope);

    var apiEntityTypes = SqlUi.StoredProcedure({
        name: "apiEntityTypes", type: "array", model: "Types",
        success: function (data) { angular.forEach(data, function (item) { apiSave.addParameter({ name: item.Code, type: "scope", value: "Entity." + item.Code }); }); }
    });
    apiEntityTypes.execute($scope);

    var apiCountries = SqlUi.StoredProcedure({ name: "apiCountries", type: "array", model: "Countries" });
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

myApp.controller("TestController", ["$scope", "$routeParams", "SqlUi", function ($scope, $routeParams, SqlUi) {

    window.alert(SqlUi.Boolean(undefined));

}]);

