myApp.directive("pah", ["DataService", function () {
    return {
        restrict: "E",
        require: "pah",
        controller: function ($scope, DataService) {
            var that = this, myDatasets = {};
            $scope.Data = {};
            $scope.Dataset = function (Name) {
                if (myDatasets[Name]) return myDatasets[Name].Data; else return [];
            };
            this.SetupDataset = function (Name, Options) { myDatasets[Name] = Options; };
            this.ReloadDataset = function (Name) {
                window.alert("Refreshing " + Name);
                var Dataset = myDatasets[Name], Parameters = {};
                angular.forEach(Dataset.Parameters, function (Item) {
                    var Parameter = {};
                    if (Item.Field)
                        Parameters[Item.Name] = Item.Field;
                    else if (Item.Value)
                        Parameters[Item.Name] = Item.Value;
                    else
                        Parameters[Item.Name] = null;
                });
                DataService.Execute(Dataset.Source, Parameters)
                    .success(function (Response) {
                        Dataset.Data = Response;
                        if (Dataset.Master) $scope.Data = angular.copy(Response[0]);
                    })
                    .error(function (Response) {
                        //window.alert(Response);
                        Dataset.Data = [];
                    });
            };
            this.InitializeDatasets = function () {
                angular.forEach(myDatasets, function (Options, Name) {
                    that.ReloadDataset(Name);
                    angular.forEach(Options.Parameters, function (Item) {
                        $scope.$watch(function ($scope) { return Item.Field; }, function (newValue, oldValue) {
                            if (newValue !== oldValue) { that.ReloadDataset(Name); };
                        });
                    });
                });
            };
        },
        link: function (scope, iElement, iAttrs, controller) {
            controller.InitializeDatasets();
        }
    };
}]);

myApp.directive("pahDataset", function () {
    return {
        restrict: "E",
        require: ["^^pah", "pahDataset"],
        scope: { Name: "@name", Source: "@source", Master: "@master" },
        controller: function ($scope) {
            $scope.Master = !($scope.Master !== "true");
            this.Options = { Source: $scope.Source, Master: $scope.Master, Parameters: [] };
            this.AddParameter = function (Parameter) { this.Options.Parameters.push(Parameter); };
        },
        link: {
            pre: function (scope, iElement, iAttrs, controller) {
                controller[0].SetupDataset(scope.Name, controller[1].Options);
            }
        }
    };
});

myApp.directive("pahDatasetParam", function () {
    return {
        restrict: "E",
        require: ["^^pahDataset", "pahDatasetParam"],
        scope: { Name: "@name", Field: "=field", Value: "@value" },
        controller: function ($scope) {

            this.Parameter = { Name: $scope.Name, Field: $scope.Field, Value: $scope.Value }
        },
        link: {
            pre: function (scope, iElement, iAttrs, controller) {
                controller[0].AddParameter(controller[1].Parameter);
            }
        }
    };
});

myApp.directive("pahForm", function () {
    return {
        restrict: "E",
        templateUrl: "controls/pahForm.html",
        transclude: true
    };
});

myApp.directive("pahFormGroup", function () {
    return {
        restrict: "E",
        templateUrl: "controls/pahFormGroup.html",
        transclude: true,
        scope: { For: "@for", Label: "@label" }
    };
});

myApp.directive("pahSelect", function () {
    return {
        restrict: "E",
        templateUrl: "controls/pahSelect.html",
        transclude: true,
        scope: {
            Id: "@id",
            Label: "@label",
            Model: "=model",
            Dataset: "=dataset",
            Value: "@value",
            Text: "@text"
        },
    };
});

