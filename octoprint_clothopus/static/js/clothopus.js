$(function() {
    function ClothopusViewModel(parameters) {
        var self = this;
        self.p0 = parameters[0];
        self.stacksArray = ko.observableArray();
        self._filamentPollTimer = null;
        self._filamentPollMs = 15000
        self.filamentRows = ko.observableArray([]);
        self.aliveDevices = ko.observableArray([]);
        self.currentEmptyStacks = ko.observableArray([]);

        self.refreshAliveDevices = function () {
            console.log("Refreshing alive devices");
            OctoPrint.simpleApiCommand("clothopus", "alive_devices", {})
                .done(function (response) {
                    if (response.success) {
                        self.aliveDevices(response.devices || []);
                    } else {
                        self.aliveDevices([]);
                    }
                })
                .fail(function () {
                    self.aliveDevices([]);
                });
        };

        self.startESPWizard = function() {
            self.refreshAliveDevices();
            $("#clothopus_esp_wizard").modal("show");
        }

        self.closeEmptyWizard = function() {
            self.currentEmptyStacks([])
            $("#clothopus_empty_wizard").modal("hide");
            self.startFilamentPolling();
        }

        self.submitEmptyWizard = function() {
            OctoPrint.simpleApiCommand(
                "clothopus",
                "init_empty_nfc", { empties: ko.toJS(self.currentEmptyStacks) }
            ).done(function(resp) {
                if (resp.success) {
                    self.closeEmptyWizard();
                } else {
                    new PNotify({
                        title: "Error",
                        text: resp.error || "Unknown error",
                        type: "error"
                    });
                }
            });
        }

        self.confirmDeleteStack = function (stack) {
            showConfirmationDialog({
                title: "Delete stack?",
                onproceed: function () {
                    self.deleteStack(stack);
                }
            });
        };

        self.deleteStack = function (device) {
            OctoPrint.simpleApiCommand("clothopus", "delete_stack", {
                    mac: device.mac
                }
            ).done(function(resp) {
                if (resp.success) {
                    self.stacksArray.remove(device);
                } else {
                    new PNotify({
                        title: "Error",
                        text: resp.error || "Unknown error",
                        type: "error"
                    });
                }
            });
        }

        self.addStack = function (device) {
            OctoPrint.simpleApiCommand("clothopus", "add_stack", {
                    mac: device.mac,
                    ip: device.ip
                }
            ).done(function(resp) {
                if (resp.success) {
                    self.stacksArray.push(device);
                } else {
                    new PNotify({
                        title: "Error",
                        text: resp.error || "Unknown error",
                        type: "error"
                    });
                }
            });
        }

        self.fetchFilaments = function () {
            OctoPrint.simpleApiCommand(
                "clothopus",
                "fetch_filaments"
            ).done(function (resp) {
                if (resp.success) {
                    self.filamentRows(resp.rows || []);
                    if (resp.empty.length > 0) {
                        self.currentEmptyStacks(resp.empty)
                        $("#clothopus_empty_wizard").modal("show");
                        self.stopFilamentPolling();
                    }
                } else {
                    new PNotify({
                        title: "Error",
                        text: resp.error || "Unknown error",
                        type: "error"
                    });
                }
            });
        };

        self.startFilamentPolling = function () {
            if (self._filamentPollTimer) return;
            self.fetchFilaments();
            self._filamentPollTimer = setInterval(function () {
                if ($("#tab_plugin_clothopus").is(":visible")) { // sanity check
                    self.fetchFilaments();
                }
            }, self._filamentPollMs);
        };

        self.stopFilamentPolling = function () {
            if (!self._filamentPollTimer) return;
            clearInterval(self._filamentPollTimer);
            self._filamentPollTimer = null;
        };

        self.onTabChange = function (current, previous) {
            if (current === "#tab_plugin_clothopus") {
                self.startFilamentPolling();
            } else if (previous === "#tab_plugin_clothopus") {
                self.stopFilamentPolling();
            }
        };

        self.onAfterBinding = function () {
            self.settings = self.p0.settings
            const stacks = self.settings.plugins.clothopus.stacks || {};
            const rows = Object.keys(stacks).map(function (mac) {
                return {
                    mac: mac,
                    ip: stacks[mac]
                };
            });
            self.stacksArray(rows);
        };

    }

    OCTOPRINT_VIEWMODELS.push({
        construct: ClothopusViewModel,
        name: "ClothopusViewModel",
        dependencies: ["settingsViewModel"],
        elements: ["#settings_plugin_clothopus", "#tab_plugin_clothopus"]
    });
});
