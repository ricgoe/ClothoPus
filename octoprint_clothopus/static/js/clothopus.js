$(function() {
    function ClothopusViewModel(parameters) {
        var self = this;
        self.settings = parameters[0];
        self.stacksArray = ko.observableArray();
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
        self.filamentRows = ko.observableArray([]);
        self.fetchFilaments = function () {
            OctoPrint.simpleApiCommand(
                "clothopus",
                "fetch_filaments"
            ).done(function (resp) {
                self.filamentRows(resp.rows || []);
            });
        };
        self.onTabChange = function (current, previous) {
            if (current === "#tab_plugin_clothopus") {
                self.fetchFilaments();
            }
        };
        self.onAfterBinding = function () {
            const stacks = self.settings.settings.plugins.clothopus.stacks || {};
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
