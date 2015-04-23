myApp.factory("procedure", ["$log", "$parse", "$localStorage", "$routeParams", "$http",
    function ($log, $parse, $localStorage, $routeParams, $http) {

        function procedure(config) {

            if (!config) { $log.error("procedure:required:config"); return; };
            if (!config.name) { $log.error("procedure:required:name"); return; };

            var self = this; self.config = { name: config.name, parameters: [] };

            if (angular.isArray(config.parameters)) {
                var parameterIndex = 0;
                angular.forEach(config.parameters, function (item) {
                    if (!item.name) { $log.error("procedure:" + config.name + ":parameter:" + parameterIndex + ":required:name:ignored") }
                    else {
                        var parameter = { name: item.name };
                        switch ((item.type) ? item.type.trim().toLowerCase() : "") {
                            case "route": parameter.type = "route"; break;
                            case "scope": parameter.type = "scope"; break;
                            default: parameter.type = "value"; break;
                        };
                        if (parameter.type === "value")
                            parameter.value = (item.value) ? item.value : null;
                        else
                            parameter.value = (item.value) ? item.value : item.name;
                        parameter.required = (item.required) ? !(item.required.toString().trim().toLowerCase() !== "true") : false;
                        self.config.parameters.push(parameter);
                    };
                });
            };

            self.config.userId = (config.userId) ? !(config.userId.toString().trim().toLowerCase() !== "true") : false;

            switch ((config.type) ? config.type.trim().toLowerCase() : "") {
                case "array": self.config.type = "array"; break;
                case "singleton": self.config.type = "singleton"; break;
                case "object": self.config.type = "object"; break;
                default: self.config.type = "execute"; break;
            };

            if (self.config.type === "execute") self.config.model = null;
            else self.config.model = (config.model) ? config.model : self.config.name;

            self.config.success = (angular.isFunction(config.success)) ? config.success : null;
            self.config.error = (angular.isFunction(config.error)) ? config.error : null;

            this.postData = function (scope) {
                var hasRequired = true;
                var postData = {
                    JWT: $localStorage.JWT,
                    Name: self.config.name,
                    Parameters: [],
                    UserId: self.config.userId,
                    Type: self.config.type
                };
                angular.forEach(self.config.parameters, function (item) {
                    var value = null, xml = false;
                    switch (item.type) {
                        case "route": value = $routeParams[item.value]; break;
                        case "scope": value = $parse(item.value)(scope); if (angular.isObject(value)) xml = true; break;
                        default: value = item.value; break;
                    };
                    if (item.required === true && !value) hasRequired = false;
                    else if (value) postData.Parameters.push({ Name: item.name, Value: value, XML: xml });
                });
                if (hasRequired === true) return postData; else return null;
            };

            this.execute = function (scope) {

                $log.debug("procedure:" + self.config.name + ":execute");

                var model = null;
                if (self.config.model) {
                    model = $parse(self.config.model);
                    model.assign(scope, (self.config.type === "array") ? [] : {});
                };

                var postData = self.postData(scope);
                if (postData) {
                    $http.post("exec.ashx", postData)
                        .success(function (data) {
                            $log.debug("procedure:" + self.config.name + ":execute:success");
                            if (angular.isFunction(model)) {
                                var value = null;
                                if (angular.isArray(data)) {
                                    switch (self.config.type) {
                                        case "array": value = data; break;
                                        default: value = data[0]; break;
                                    };
                                }
                                else if (angular.isObject(data)) {
                                    switch (self.config.type) {
                                        case "array": value = [data]; break;
                                        default: value = data; break;
                                    };
                                };
                                if (value) model.assign(scope, value);
                            };
                            if (angular.isFunction(self.config.success)) self.config.success((angular.isFunction(model)) ? model(scope) : null);
                        })
                        .error(function (data, status) {
                            $log.error("procedure:" + self.config.name + ":error:" + status + ":" + data);
                            if (angular.isFunction(self.config.error)) self.config.error(data, status);
                        });
                }
                else {
                    $log.debug("procedure:" + self.config.name + ":execute:missingdata");
                    if (angular.isFunction(self.config.error)) self.config.error((angular.isFunction(model)) ? model(scope) : null, -1);
                }

            };

            this.autoexec = function (scope) {
                self.execute(scope);
                angular.forEach(self.config.parameters, function (item) {
                    if (item.type === "scope") {
                        scope.$watch(item.value, function (newValue, oldValue) {
                            if (newValue !== oldValue) { self.execute(scope); }
                        });
                    };
                });
            };

        };

        return procedure;

    }]);