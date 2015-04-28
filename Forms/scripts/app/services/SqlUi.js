myApp.service("SqlUi", ["$log", "SqlUiUtils", "SqlUiSp", "$modal", function ($log, SqlUiUtils, SqlUiSp, $modal) {

    this.IfBlank = SqlUiUtils.IfBlank;
    this.Boolean = SqlUiUtils.Boolean;

    this.StoredProcedure = function (config) { return new SqlUiSp(config); };

    this.Popup = function (config) {

        if (!config) { $log.error("popup:missing:options"); return; };

        var options = {};

        return $modal.open({
            templateUrl: "views/popup.html",
            controller: "PopupController"
        });

    };

}]);