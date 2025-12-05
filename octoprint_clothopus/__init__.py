# coding=utf-8
from __future__ import absolute_import
import octoprint.plugin
import flask
from .hx711 import HX711

class ClothopusPlugin(
    octoprint.plugin.SettingsPlugin,
    octoprint.plugin.AssetPlugin,
    octoprint.plugin.TemplatePlugin,
    octoprint.plugin.SimpleApiPlugin
):
    
    def __init__(self):
        self.active_scales = {}

    def on_after_startup(self):
        scales = self._settings.get(["scales"]) or {}
        self.active_scales = { key: HX711.from_json(value) for key, value in scales.items() }

        self._logger.info(f"Loaded {len(self.active_scales)} active scales.")

    def get_settings_defaults(self):
        return {
            "max_spools": 5,
            "auto_read": True,
            "nfc_device": "/dev/ttyUSB0"
        }

    def get_template_vars(self):
        import os, yaml

        data_folder = "/home/jaboll/Documents/yamls"
        filaments = []

        if os.path.isdir(data_folder):
            for fn in os.listdir(data_folder):
                if fn.endswith(".yaml"):
                    file_path = os.path.join(data_folder, fn)
                    with open(file_path, "r") as f:
                        parsed = yaml.safe_load(f)
                        filaments.append(parsed)

        return {
            "clothopus_rows": filaments
        }


    def get_template_configs(self):
        return [
            dict(type="tab", name="Clothopus", icon="tag"),
            dict(type="settings", name="Clothopus Settings", custom_bindings=False)
        ]

    def get_assets(self):
        return {
            "js": ["js/clothopus.js"],
            "css": ["css/clothopus.css"]
        }
        
    def save_scale(self, scale_id, data):
        scales = self._settings.get(["scales"]) or {}
        scales[scale_id] = data
        self._settings.set(["scales"], scales)
        self._settings.save()


    def get_api_commands(self):
        return dict(
            initialize_scale=["scale_id","pins"],
            calibrate_scale=["scale_id", "known_weight"]
        )

    def on_api_command(self, command, data: dict):
        if command == "initialize_scale":
            scale_id = str(data.get("scale_id"))
            pins = data.get("pins")
            if not pins:
                return flask.jsonify(dict(success=False, error="Missing pins."))
            try:
                scale = HX711(**pins)#TODO
            except ConnectionError:
                return flask.jsonify(dict(success=False, error="Could not connect to scale."))
            self.active_scales[scale_id] = scale
            return flask.jsonify(dict(success=True))

        if command == "calibrate_scale":
            scale_id = str(data.get("scale_id"))
            known_weight = data.get("known_weight")
            scale = self.active_scales.get(scale_id)
            if not scale or not scale.reachable() or not known_weight:
                return flask.jsonify(dict(success=False, error="Could not connect to scale."))
            result=scale.calib_scale(known_weight)
            if not result:
                return flask.jsonify(dict(success=False, error="Could not calibrate scale."))
            self.save_scale(scale_id, result)
            return flask.jsonify(result)


__plugin_name__ = "Clothopus"
__plugin_pythoncompat__ = ">=3,<4"


def __plugin_load__():
    global __plugin_implementation__
    __plugin_implementation__ = ClothopusPlugin()

    global __plugin_hooks__
    __plugin_hooks__ = {}
