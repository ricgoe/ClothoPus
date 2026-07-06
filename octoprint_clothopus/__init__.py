# coding=utf-8
from __future__ import absolute_import
from collections import defaultdict
from pathlib import Path
import time
import struct
import octoprint.plugin
import flask
import httpx
from .OPTag import PrintTagHandler
import asyncio

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
        self.taghandlers = defaultdict(PrintTagHandler)


    def on_after_startup(self):
        pass

    def on_shutdown(self):
        pass

    def on_settings_save(self, data):
        pass


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

    def get_api_commands(self):

        return dict(
            fetch_filaments=[],
            init_empty_nfc=["empties"],
            alive_devices=[],
            delete_stack=["mac"],
            add_stack=["mac", "ip"],
        )

    async def _get_route_of_esps(self, stacks: dict, path: str):
        async with httpx.AsyncClient() as client:
            pulls = {mac: client.get(f"http://{ip}{path}") for mac, ip  in stacks.items()}
            results = await asyncio.gather(*pulls.values(), return_exceptions=True)
            return dict(zip(pulls.keys(), results))

    def _init_tag_w_id(self, handler: PrintTagHandler, prusa_id: str):
        tag_data: dict = handler.generate_opt_json(prusa_id)
        if not tag_data: return False
        handler.nfc_initialize()
        handler.patch_bin(tag_data)
        return True

    def _pack(self, records: list[tuple]):
        packed = bytearray()
        clip = slice(max(0, len(records)-20), None)
        for day, weight in records[clip]:
            packed.extend(int(day).to_bytes(2, "big"))
            packed.extend(int(weight).to_bytes(2, "big"))
        return bytes(packed)

    def _unpack(self, packed_records: bytes):
        records = []
        for i in range(0, len(packed_records), 4):
            day = int.from_bytes(packed_records[i:i+2], "big")
            weight = int.from_bytes(packed_records[i+2:i+4], "big")
            records.append((day, weight))
        return records

    def on_api_command(self, command, data: dict):
        stacks = self._settings.get(["stacks"]) or {}
        if command == "fetch_filaments":
            empty = []
            filaments = []
            for mac, resp in asyncio.run(self._get_route_of_esps(stacks, "/blocks")).items():
                if not isinstance(resp, httpx.Response): continue
                if resp.status_code == 204:
                    empty.append({"mac": mac, "filament": ""})
                elif resp.status_code == 200:
                    raw = bytearray(resp.content)
                    handler = self.taghandlers[mac]
                    handler.current_record = raw
                    try:
                        _info = handler.bin_to_dict()
                        consumed_resp = httpx.get(f"http://{stacks[mac]}/consumed", params={
                            "filament_diameter": _info["data"]["main"].get("filament_diameter", 1.75),
                            "density": _info["data"]["main"]["density"]
                        })
                        consumed_resp.raise_for_status()
                        clicks_consumed = consumed_resp.json()["consumed_weight"]
                        if clicks_consumed != 0:
                            consumed = _info["data"]["aux"].get("consumed_weight", 0)
                            consumed += clicks_consumed
                            patch = {"data": { "aux": {"general_purpose_range_user": "Clotho" ,"consumed_weight": consumed}}}
                            # handler.current_record = raw # nur gott weiß
                            resp = httpx.post(
                                f"http://{stacks[mac]}/blocks", params={"retries_per_block": 10, "diff_only": True, "with_weight": True},
                                content=handler.patch_bin(patch)
                            )
                            resp.raise_for_status()
                    except Exception as e:
                        return flask.jsonify(dict(success=False, error=f"Corrupt tag: {e} @ {mac}"))
                    filaments.append(handler.bin_to_dict())
            return flask.jsonify(dict(success=True, rows=filaments, empty=empty))

        if command == "init_empty_nfc":
            empties = data.get("empties")
            for empty in empties:
                mac = str(empty.get("mac"))
                ip = stacks.get(mac)
                if ip is None:
                    return flask.jsonify(dict(success=False, error="Unknown MAC address."))
                handler = self.taghandlers[mac]
                filament = str(empty.get("filament"))
                resp = self._init_tag_w_id(handler, filament)
                if not resp: return flask.jsonify(dict(success=False, error="Invalid PRUSA-ID."))
                # stack.write_tag()
                try:
                    resp = httpx.post(f"http://{ip}/blocks", params={"retries_per_block": 10, "diff_only": True, "with_weight": True}, content=bytes(handler.current_record.data))
                except Exception as e:
                    return flask.jsonify(dict(success=False, error=str(e)))
                if resp.status_code != 200:
                    return flask.jsonify(dict(success=False, error=str(resp.status_code)))
            return flask.jsonify(dict(success=True))

        if command == "add_stack":
            mac = str(data.get("mac"))
            ip = str(data.get("ip"))
            stacks[mac] = ip
            self._settings.set(["stacks"], stacks)
            self._settings.save()
            return flask.jsonify(dict(success=True))

        if command == "delete_stack":
            mac = str(data.get("mac"))
            if stacks.pop(mac, None) is None:
                return flask.jsonify(dict(success=False))
            self._settings.set(["stacks"], stacks)
            self._settings.save()
            return flask.jsonify(dict(success=True))

        if command == "alive_devices":
            devices = []
            with Path("/var/lib/misc/dnsmasq.leases").open() as f:
                for line in f:
                    parts = line.split()
                    if len(parts) < 3:
                        continue
                    expiry, mac, ip = int(parts[0]), parts[1], parts[2]
                    if expiry != 0 and expiry < time.time():
                        continue
                    # ping = subprocess.run(["ping", "-I", "wlan0", "-c", "1", "-W", "1", ip], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    # if ping.returncode == 0:
                    try:
                        resp =httpx.get(f"http://{ip}/reachable")
                        if resp.status_code == 200:
                            devices.append({"mac": mac, "ip": ip})
                    except Exception as e:
                        continue


            return flask.jsonify(dict(success=True, devices=devices))

    def is_api_protected(self):
        return True



__plugin_name__ = "Clothopus"
__plugin_pythoncompat__ = ">=3,<4"


def __plugin_load__():
    global __plugin_implementation__
    __plugin_implementation__ = ClothopusPlugin()

    global __plugin_hooks__
    __plugin_hooks__ = {}
