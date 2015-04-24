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