myApp.directive("pah", ["DataService", function () {
    return {
        restrict: "E",
        require: "pah",
        controller: function ($scope, DataService) {
            var that = this, myDatasets = {};
            $scope.Data = {};
            $scope.Dataset = function (Name) { return myDatasets[Name].Data; };
            this.SetupDataset = function (Name, Options) { myDatasets[Name] = Options; };
            this.ReloadDataset = function (Name) {
                var Dataset = myDatasets[Name], Parameters = {};
                angular.forEach(Dataset.Parameters, function (Item) {
                    var Parameter = {};
                    switch (Item.Type) {
                        case "Field": Parameters[Item.Name] = $scope.Data[Item.Value]; break;
                        default: Parameters[Item.Name] = Item.Value; break;
                    };
                });
                DataService.Execute(Dataset.Source, Parameters)
                    .success(function (Response) {
                        Dataset.Data = Response;
                        if (Dataset.Master) $scope.Data = angular.copy(Response[0]);
                    })
                    .error(function (Response) {
                        Dataset.Data = [];
                    });
            };
            this.InitializeDatasets = function () {
                angular.forEach(myDatasets, function (Options, Name) {
                    that.ReloadDataset(Name);
                    angular.forEach(Options.Parameters, function (Item) {
                        if (Item.Type == "Field") {
                            $scope.$watch("Data." + Item.Value, function (newValue, oldValue) {
                                if (newValue !== oldValue) { that.ReloadDataset(Name); };
                            });
                        };
                    });
                });
            };
        },
        link: function (scope, iElement, iAttrs, controller) { controller.InitializeDatasets(); }
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
        link: function (scope, iElement, iAttrs, controller) {
            controller[0].SetupDataset(scope.Name, controller[1].Options);
            iElement.remove();
        }
    };
});

myApp.directive("pahDatasetParam", function () {
    return {
        restrict: "E",
        require: ["^^pahDataset", "pahDatasetParam"],
        scope: { Name: "@name", Type: "@type", Value: "@value" },
        controller: function ($scope) {
            switch ($scope.Type) {
                case "Field": $scope.Type = "Field"; break;
                default: $scope.Type = "Constant"; break;
            };
            this.Parameter = { Name: $scope.Name, Type: $scope.Type, Value: $scope.Value }
        },
        link: function (scope, iElement, iAttrs, controller) {
            controller[0].AddParameter(controller[1].Parameter);
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

