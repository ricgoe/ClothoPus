# coding=utf-8
from __future__ import absolute_import
import threading
import octoprint.plugin
import flask
from .stack import Stack
from .hx711 import HX711
from .pn5180 import Sensor
import pigpio

class ClothopusPlugin(
    octoprint.plugin.SettingsPlugin,
    octoprint.plugin.AssetPlugin,
    octoprint.plugin.TemplatePlugin,
    octoprint.plugin.SimpleApiPlugin,
    octoprint.plugin.StartupPlugin,
    octoprint.plugin.ShutdownPlugin,
):

    def __init__(self):
        self._scale_lock = threading.Lock()
        self._nfc_lock = threading.Lock()
        self._pi = pigpio.pi()
        self.active_stacks = {}

    def on_after_startup(self):
        self._load_stacks_from_settings()
        self._logger.info(f"Loaded {len(self.active_stacks)} active stacks.")

    def on_shutdown(self):
        for stack in self.active_stacks.values():
            try:
                stack.close()
            except Exception as e:
                self._logger.info(e)

    def on_settings_save(self, data):
        super().on_settings_save(data)
        self._load_stacks_from_settings()


    def get_settings_defaults(self):
        return {
            "max_spools": 5,
            "auto_read": True,
            "nfc_device": "/dev/ttyUSB0",
            "stacks": {}
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

    def save_stack(self, stack_id, data):
        stacks = self._settings.get(["stacks"]) or {}
        stacks[stack_id] = data
        self._settings.set(["stacks"], stacks)
        self._settings.save()
        self._logger.info(f"Saved scale {data}")


    def get_api_commands(self):
        return dict(
            initialize_scale=["stack_id", "name", "pins"],
            calibrate_scale=["stack_id", "known_weight"],
            initialize_nfc=["stack_id", "nfc"],
            get_grams=["stack_id"],
            fetch_filaments=[]
        )

    def on_api_command(self, command, data: dict):
        if command == "initialize_scale":
            stack_id = str(data.get("stack_id"))
            pins = data.get("pins")
            stack = Stack(pi=self._pi, name=data.get("name"))
            if not pins:
                return flask.jsonify(dict(success=False, error="Missing pins."))
            with self._scale_lock:
                try:
                    scale = HX711(stack.pi, **pins)#TODO
                except ConnectionError:
                    return flask.jsonify(dict(success=False, error="Could not connect to scale."))
            stack.scale = scale
            self.active_stacks[stack_id] = stack
            print(self.active_stacks)
            return flask.jsonify(dict(success=True))

        if command == "calibrate_scale":
            stack_id = str(data.get("stack_id"))
            known_weight = data.get("known_weight")
            stack: Stack = self.active_stacks.get(stack_id)
            if not stack or not stack.scale or not known_weight:
                return flask.jsonify(dict(success=False, error="Could not connect to scale."))
            with self._scale_lock:
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
            with self._nfc_lock:
                sensor = Sensor.from_json(stack.pi, nfc)
                if not sensor.reachable():
                    return flask.jsonify(dict(success=False, error="Could not connect to sensor."))
            stack.nfc = sensor
            self.save_stack(stack_id, stack.json())
            return flask.jsonify(dict(success=True))

        if command == "fetch_filaments":
            with self._nfc_lock:
                filaments = []
                for stack in self.active_stacks.values():
                    filament = stack.read_tag()
                    if filament: filaments.append(filament | {"stack_name": stack.name})
            return {"rows": filaments}

        if command == "get_grams":
            stack_id = str(data.get("stack_id"))
            scale = self.active_stacks.get(stack_id)
            with self._scale_lock:
                if not scale or not scale.reachable():
                    return flask.jsonify(dict(success=False, error="Could not connect to scale."))
                return flask.jsonify(dict(success=True, grams=scale.get_grams()))

    def is_api_protected(self):
        return True

    def _load_stacks_from_settings(self):
        stacks_cfg = self._settings.get(["stacks"]) or {}
        for stack in getattr(self, "active_stacks", {}).values():
            try:
                stack.close()
            except Exception:
                self._logger.exception("Failed to close stack")
        self.active_stacks = {}
        for key, cfg in stacks_cfg.items():
            stack = Stack.from_json(self._pi, cfg)
            stack.prepare()
            self.active_stacks[key] = stack



__plugin_name__ = "Clothopus"
__plugin_pythoncompat__ = ">=3,<4"


def __plugin_load__():
    global __plugin_implementation__
    __plugin_implementation__ = ClothopusPlugin()

    global __plugin_hooks__
    __plugin_hooks__ = {}
