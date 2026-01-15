# coding=utf-8
from __future__ import absolute_import
import threading
import octoprint.plugin
from octoprint.events import Events
import flask
from .stack import Stack
from .hx711 import HX711
from .pn5180 import Sensor
import pigpio
from .sanitze import sanitize_patch

class ClothopusPlugin(
    octoprint.plugin.SettingsPlugin,
    octoprint.plugin.AssetPlugin,
    octoprint.plugin.TemplatePlugin,
    octoprint.plugin.SimpleApiPlugin,
    octoprint.plugin.StartupPlugin,
    octoprint.plugin.ShutdownPlugin,
    octoprint.plugin.EventHandlerPlugin,
):

    def __init__(self):
        self._lock = threading.Lock()
        self._pi = pigpio.pi()
        self.active_stacks: dict[str, Stack] = {}
        
    def on_event(self, event, payload):
        if event == Events.PRINT_DONE:
            for _id, stack in self.active_stacks.items():
                stack.write_tag(with_weight=True)
        

    def on_after_startup(self):
        self._load_stacks_from_settings()
        self._logger.info(f"Loaded {len(self.active_stacks)} active stacks.")

    def on_shutdown(self):
        for stack in self.active_stacks.values():
            try:
                stack.close()
            except Exception as e:
                self._logger.info(e)
        self._pi.stop()
        self._logger.info(f"Cleaned up correctly")

    def on_settings_save(self, data):
        data = sanitize_patch(data)
        for stack_id in data.get("stacks", {}):
            if stack_id not in self.active_stacks:
                data["stacks"].pop(stack_id, None)
        super().on_settings_save(data)
        self._load_stacks_from_settings()


    def get_settings_defaults(self):
        return {
            "stacks": {},
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
        
    def delete_stack(self, stack_id):
        stack = self.active_stacks.pop(stack_id, None)
        stack.close()
        stacks = self._settings.get(["stacks"]) or {}
        _did = stacks.pop(stack_id, None)
        if _did is None:
            return
        self._settings.set(["stacks"], stacks)
        self._settings.save()

    def get_api_commands(self):
        return dict(
            initialize_scale=["stack_id", "name", "pins"],
            calibrate_scale=["stack_id", "known_weight"],
            initialize_nfc=["stack_id", "nfc"],
            get_grams=["stack_id"],
            fetch_filaments=[],
            delete_stack=["stack_id"],
            init_empty_nfc=["data"]
        )

    def on_api_command(self, command, data: dict):
        if command == "initialize_scale":
            stack_id = str(data.get("stack_id"))
            pins = data.get("pins")
            stack = Stack(pi=self._pi, name=data.get("name"))
            if not pins:
                return flask.jsonify(dict(success=False, error="Missing pins."))
            with self._lock:
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
            stack = self.active_stacks.get(stack_id)
            if not stack or not stack.scale or not known_weight:
                return flask.jsonify(dict(success=False, error="Could not connect to scale."))
            with self._lock:
                result=stack.scale.calib_scale(known_weight)
            if not result:
                return flask.jsonify(dict(success=False, error="Could not calibrate scale."))
            # self.save_scale(stack_id, result)
            return flask.jsonify(result)

        if command == "initialize_nfc":
            stack_id = str(data.get("stack_id"))
            stack = self.active_stacks.get(stack_id)
            nfc = data.get("nfc")
            if not stack or not nfc:
                return flask.jsonify(dict(success=False, error="Missing nfc."))
            with self._lock:
                sensor = Sensor.from_json(stack.pi, nfc)
                if not sensor.reachable():
                    return flask.jsonify(dict(success=False, error="Could not connect to sensor."))
            stack.nfc = sensor
            stack.prepare()
            self.save_stack(stack_id, stack.json())
            return flask.jsonify(dict(success=True, stack=stack.json()))

        if command == "fetch_filaments":
            empty = []
            with self._lock:
                try:
                    filaments = []
                    for _id, stack in self.active_stacks.items():
                        if not stack.nfc: continue
                        filament = stack.read_tag()
                        if filament:
                            if filament.get("data", {}).get("aux", {}).get("consumed_weight") is None:
                                filament = stack.write_tag(with_weight=True)
                            filaments.append(filament | {"stack_name": stack.name, "stack_id": _id})
                        elif filament is not None: 
                            empty.append({"id": _id, "filament": ""})
                except TimeoutError as e:
                    return flask.jsonify(dict(success=False, error=f"Stack {_id}: {e}"))
            return flask.jsonify(dict(success=True, rows=filaments, empty=empty))

        if command == "get_grams":
            stack_id = str(data.get("stack_id"))
            scale = self.active_stacks.get(stack_id)
            with self._lock:
                if not scale or not scale.reachable():
                    return flask.jsonify(dict(success=False, error="Could not connect to scale."))
                return flask.jsonify(dict(success=True, grams=scale.get_grams()))
            
        if command == "delete_stack":
            stack_id = str(data.get("stack_id"))
            stack = self.active_stacks.get(stack_id, None)
            if stack is None:
                return flask.jsonify(dict(success=False, error="Invalid scale."))
            self.delete_stack(stack_id)
            return flask.jsonify(dict(success=True))
        
        if command == "init_empty_nfc":
            empties = data.get("data")
            for empty in empties:
                stack_id = str(empty.get("id"))
                filament = str(empty.get("filament"))
                stack = self.active_stacks.get(stack_id, None)
                if stack is None:
                    return flask.jsonify(dict(success=False, error="Invalid scale."))
                with self._lock:
                    resp = stack.init_tag_w_id(filament)
                    if not resp: return flask.jsonify(dict(success=False, error="Invalid PRUSA-ID."))
                    stack.write_tag()
            return flask.jsonify(dict(success=True))

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
            with self._lock:
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
