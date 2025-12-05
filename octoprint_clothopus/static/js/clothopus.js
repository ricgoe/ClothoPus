$(function() {
    function ClothopusViewModel(parameters) {
        var self = this;
        self.totalScales = ko.observable(3);
        self.wizard = {
            _curr_id: null,
            step: ko.observable(1),

            pins: ko.observable({ dout: "", pd_sck: "" }),
            knownWeight: ko.observable(""),
            result: ko.observable({}),

            initializeScale: function() {
                const ID = Date.now().toString();
                OctoPrint.simpleApiCommand("clothopus", "initialize_scale", {
                    scale_id: ID,
                    pins: self.wizard.pins()
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
                    scale_id: self.wizard._curr_id,
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

            resetForNewScale: function() {
                self.wizard.step(1);
                self.wizard.pins({ dout: "", pd_sck: "" });
                self.wizard.knownWeight("");
                self.wizard.result({});
                self.wizard._curr_id = null;
            },

            closeWizard: function() {
                $("#clothopus_wizard").modal("hide");
            },

            primaryText: ko.pureComputed(function() {
                switch (self.wizard.step()) {
                    case 1: return "Next Step";
                    case 2: return "Finish";
                    case 3: return "Add Scale";
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
                        self.wizard.resetForNewScale();
                        break;
                }
            },

            secondaryText: ko.pureComputed(function() {
                return (self.wizard.step() < 3) ? "Cancel" : "Finish";
            }),

            secondaryAction: function() {
                if (self.wizard.step() < 3) {
                    self.wizard.closeWizard();
                } else {
                    self.wizard.closeWizard();
                }
            }
        };


        self.startWizard = function() {
            self.wizard.resetForNewScale();
            $("#clothopus_wizard").modal("show");
        };
    }

    OCTOPRINT_VIEWMODELS.push({
        construct: ClothopusViewModel,
        name: "ClothopusViewModel",
        dependencies: ["settingsViewModel"],
        elements: ["#clothopus_tab"]
    });
});
