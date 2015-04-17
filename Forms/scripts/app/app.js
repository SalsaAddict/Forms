var myApp = angular.module("myApp", ["ngRoute", "ngStorage", "ui.bootstrap"]);

myApp.config(function ($routeProvider) {
    $routeProvider
        .when("/home", { caseInsensitiveMatch: true, templateUrl: "views/home.html" })
        .when("/exec", { caseInsensitiveMatch: true, templateUrl: "views/exec.html" })
        .when("/entities", { caseInsensitiveMatch: true, templateUrl: "views/entities.html" })
        .when("/entity", { caseInsensitiveMatch: true, templateUrl: "views/entity.html" })
        .when("/entity/:EntityId", { caseInsensitiveMatch: true, templateUrl: "views/entity.html", controller: "EntityController" })
        .otherwise({ redirectTo: "/home" });
});

myApp.service("DataService", ["$http", "$log", function ($http, $log) {
    this.Execute = function (Name, Parameters, ReturnsXML) {
        var NVArray = [], XML = null;
        angular.forEach(Parameters, function (Value, Key) {
            if (Value) { if (Key == "XML") XML = Value; else NVArray.push({ Name: Key, Value: Value }); };
        });
        return $http.post("exec.ashx?rx=" + ((ReturnsXML === true) ? "true" : "false"), { Name: Name, Parameters: NVArray, XML: XML })
            .error(function (Response) { $log.error(Response); });
    };
}]);

myApp.controller("EntityController", ["$scope", "$routeParams", "DataService", function ($scope, $routeParams, DataService) {



}]);