$(function() {
    function ClothopusViewModel(parameters) {
        var self = this;
        console.log("Clothopus tab ViewModel loaded");
    }

    OCTOPRINT_VIEWMODELS.push({
        construct: ClothopusViewModel,
        template: "clothopus_tab",
        name: "ClothopusViewModel",
        dependencies: ["settingsViewModel"],
        elements: ["#clothopus_tab"]
    });
});
