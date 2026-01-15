$(function() {
    function ClothopusViewModel(parameters) {
        var self = this;
        self.p0 = parameters[0];
        self.stacksArray = ko.observableArray();
        self._filamentPollTimer = null;
        self._filamentPollMs = 15000
        self.currentEmptyStacks = ko.observableArray();
        self.wizard = {
            _curr_id: null,

            step: ko.observable(1),
            name: ko.observable("N"),
            scale: { dout: ko.observable(""), pd_sck: ko.observable(""), gain: ko.observable(128) },
            nfc: {
                nss: ko.observable(""),
                busy: ko.observable(""),
                reset: ko.observable(""),
                baud: ko.observable(115200),
                spi_channel: ko.observable(0)
            },

            knownWeight: ko.observable(""),
            result: ko.observable({}),

            initializeScale: function() {
                const ID = Date.now().toString();
                OctoPrint.simpleApiCommand("clothopus", "initialize_scale", {
                    stack_id: ID,
                    name: self.wizard.name(),
                    pins: ko.toJS(self.wizard.scale)
                }).done(function(resp) {
                    if (resp.success) {
                        self.wizard._curr_id = ID;
                        self.wizard.step(2);
                    } else {
                        new PNotify({
                            title: "Scale Error",
                            text: resp.error || "Unknown error",
                            type: "error"
                        });
                    }
                });
            },

            calibrateScale: function() {
                OctoPrint.simpleApiCommand("clothopus", "calibrate_scale", {
                    stack_id: self.wizard._curr_id,
                    known_weight: self.wizard.knownWeight()
                }).done(function(resp) {
                    if (resp.success !== false) {
                        self.wizard.result(resp);
                        self.wizard.step(3);
                    } else {
                        new PNotify({
                            title: "Scale Error",
                            text: resp.error || "Unknown error",
                            type: "error"
                        });
                    }
                });
            },

            initializeNFC: function() {
                OctoPrint.simpleApiCommand("clothopus", "initialize_nfc", {
                    stack_id: self.wizard._curr_id,
                    nfc: ko.toJS(self.wizard.nfc)
                }).done(function(resp) {
                    if (resp.success) {
                        self.wizard.step(5);
                        self.stacksArray.push({
                            id: self.wizard._curr_id,
                            data: resp.stack
                        })
                    } else {
                        new PNotify({
                            title: "Scale Error",
                            text: resp.error || "Unknown error",
                            type: "error"
                        });
                    }
                });
            },

            resetForNewStack: function() {
                self.wizard.step(1);
                self.wizard.scale = { dout: ko.observable(""), pd_sck: ko.observable(""), gain: ko.observable(128) };
                self.wizard.nfc = {
                    nss: ko.observable(""),
                    busy: ko.observable(""),
                    reset: ko.observable(""),
                    baud: ko.observable(115200),
                    spi_channel: ko.observable(0)
                };
                self.wizard.name("");
                self.wizard.knownWeight("");
                self.wizard.result({});
                self.wizard._curr_id = null;
            },

            closeWizard: function() {
                $("#clothopus_wizard").modal("hide");
            },

            primaryText: ko.pureComputed(function() {
                switch (self.wizard.step()) {
                    case 1: return "Initialize Scale";
                    case 2: return "Next Step";
                    case 3: return "Next Step";
                    case 4: return "Initialize NFC Reader";
                    case 5: return "Add another Stack";
                }
            }),

            primaryAction: function() {
                switch (self.wizard.step()) {
                    case 1:
                        self.wizard.initializeScale();
                        break;
                    case 2:
                        self.wizard.calibrateScale();
                        break;
                    case 3:
                        self.wizard.step(4);
                        break;
                    case 4:
                        self.wizard.initializeNFC();
                        break;
                    case 5:
                        self.wizard.resetForNewStack();
                        break;
                }
            },

            secondaryText: ko.pureComputed(function() {
                return (self.wizard.step() < 5) ? "Cancel" : "Finish";
            }),

            secondaryAction: function() {
                if (self.wizard.step() < 5) {
                    self.wizard.closeWizard();
                } else {
                    self.wizard.closeWizard();
                }
            }
        };


        self.startWizard = function() {
            self.wizard.resetForNewStack();
            $("#clothopus_wizard").modal("show");
        };

        self.closeEmptyWizard = function() {
            self.currentEmptyStacks([])
            $("#clothopus_empty_wizard").modal("hide");
            self.startFilamentPolling();
        }

        self.submitEmptyWizard = function() {
            OctoPrint.simpleApiCommand(
                "clothopus",
                "init_empty_nfc", { data: ko.toJS(self.currentEmptyStacks) }
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

        self.deleteStack = function (stack) {
            OctoPrint.simpleApiCommand("clothopus", "delete_stack", {
                    stack_id: stack.id
                }
            ).done(function(resp) {
                if (resp.success) {
                    self.stacksArray.remove(stack);
                } else {
                    new PNotify({
                        title: "Error",
                        text: resp.error || "Unknown error",
                        type: "error"
                    });
                }
            });
        }

        self.filamentRows = ko.observableArray([]);
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
            const rows = Object.keys(stacks).map(function (id) {
                return {
                    id: id,
                    data: stacks[id]
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
