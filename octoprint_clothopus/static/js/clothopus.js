$(function() {
    function ClothopusViewModel(parameters) {
        var self = this;
        self.settings = parameters[0];
        self.wizard = {
            _curr_id: null,

            step: ko.observable(1),
            name: ko.observable(""),
            scale_pins: ko.observable({ dout: "", pd_sck: "" }),
            nfc: ko.observable({ nss: "", busy: "", reset: "", baud: "115200", spi_channel: "0" }),
            knownWeight: ko.observable(""),
            result: ko.observable({}),

            initializeScale: function() {
                const ID = Date.now().toString();
                OctoPrint.simpleApiCommand("clothopus", "initialize_scale", {
                    stack_id: ID,
                    pins: self.wizard.scale_pins()
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
                    nfc: self.wizard.nfc()
                }).done(function(resp) {
                    if (resp.success) {
                        self.wizard._curr_id = ID;
                        self.wizard.step(4);
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
                self.wizard.scale_pins({ dout: "", pd_sck: "" });
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
                    case 3: return "Initialize NFC Reader";
                    case 4: return "Add Stack";
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
                        self.wizard.initializeNFC();
                        break;
                    case 4:
                        self.wizard.resetForNewStack();
                        break;
                }
            },

            secondaryText: ko.pureComputed(function() {
                return (self.wizard.step() < 4) ? "Cancel" : "Finish";
            }),

            secondaryAction: function() {
                if (self.wizard.step() < 4) {
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
    }

    OCTOPRINT_VIEWMODELS.push({
        construct: ClothopusViewModel,
        name: "ClothopusViewModel",
        dependencies: ["settingsViewModel"],
        elements: ["#clothopus_settings", "#clothopus_tab"]
    });
});
