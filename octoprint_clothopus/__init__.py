# coding=utf-8
from __future__ import absolute_import
import octoprint.plugin
import flask
from .hx711 import HX711
from .stack import Stack
from .pn5180 import Sensor
import pigpio

class ClothopusPlugin(
    octoprint.plugin.SettingsPlugin,
    octoprint.plugin.AssetPlugin,
    octoprint.plugin.TemplatePlugin,
    octoprint.plugin.SimpleApiPlugin,
    octoprint.plugin.StartupPlugin
):

    def __init__(self):
        self.active_stacks = {}

    def on_after_startup(self):
        scales = self._settings.get(["scales"]) or {}
        self.active_stacks = { key: HX711.from_json(value) for key, value in scales.items() }
        self._logger.info(f"Loaded {len(self.active_stacks)} active scales.")

    def get_settings_defaults(self):
        return {
            "max_spools": 5,
            "auto_read": True,
            "nfc_device": "/dev/ttyUSB0",
            "scales": {}
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
            dict(type="settings", name="Clothopus Settings", custom_bindings=True)
        ]

    def get_assets(self):
        return {
            "js": ["js/clothopus.js"],
            "css": ["css/clothopus.css"]
        }

    def save_scale(self, stack_id, data):
        scales = self._settings.get(["scales"]) or {}
        scales[stack_id] = data
        self._settings.set(["scales"], scales)
        self._settings.save()
        self._logger.info(f"Saved scale {data}")


    def get_api_commands(self):
        return dict(
            initialize_scale=["stack_id","pins"],
            calibrate_scale=["stack_id", "known_weight"],
            initialize_nfc=["stack_id", "nfc"],
            get_grams=["stack_id"]
        )

    def on_api_command(self, command, data: dict):
        if command == "initialize_scale":
            stack_id = str(data.get("stack_id"))
            pins = data.get("pins")
            stack = Stack(pi=pigpio.pi(), name="")
            if not pins:
                return flask.jsonify(dict(success=False, error="Missing pins."))
            try:
                scale = HX711(stack.pi, **pins)#TODO
            except ConnectionError:
                return flask.jsonify(dict(success=False, error="Could not connect to scale."))
            stack.scale = scale
            self.active_stacks[stack_id] = stack
            return flask.jsonify(dict(success=True))

        if command == "calibrate_scale":
            stack_id = str(data.get("stack_id"))
            known_weight = data.get("known_weight")
            stack: Stack = self.active_stacks.get(stack_id)
            if not stack or not stack.scale or not stack.scale.reachable() or not known_weight:
                return flask.jsonify(dict(success=False, error="Could not connect to scale."))
            result=stack.scale.calib_scale(known_weight)
            if not result:
                return flask.jsonify(dict(success=False, error="Could not calibrate scale."))
            # self.save_scale(stack_id, result)
            return flask.jsonify(result)

        if command == "initialize_nfc":
            stack_id = str(data.get("stack_id"))
            stack: Stack = self.active_stacks.get(stack_id)
            nfc = data.get("nfc")
            if not stack or not nfc:
                return flask.jsonify(dict(success=False, error="Missing nfc."))
            sensor = Sensor.from_json(stack.pi, nfc)
            if not sensor._read_tx_config():
                return flask.jsonify(dict(success=False, error="Could not connect to scale."))
            stack.nfc = sensor
            return flask.jsonify(dict(success=True))

        if command == "get_grams":
            stack_id = str(data.get("stack_id"))
            scale = self.active_stacks.get(stack_id)
            if not scale or not scale.reachable():
                return flask.jsonify(dict(success=False, error="Could not connect to scale."))
            return flask.jsonify(dict(success=True, grams=scale.get_grams()))


__plugin_name__ = "Clothopus"
__plugin_pythoncompat__ = ">=3,<4"


def __plugin_load__():
    global __plugin_implementation__
    __plugin_implementation__ = ClothopusPlugin()

    global __plugin_hooks__
    __plugin_hooks__ = {}
