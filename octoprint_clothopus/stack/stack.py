from ..pn5180 import Sensor
from ..hx711 import HX711
from ..OPTag import PrintTagHandler
import pigpio

class Stack:
    def __init__(
            self, name:str, pi:pigpio.pi
        ):
        self.pi = pi
        self.name = name
        self.scale: HX711|None = None
        self.nfc: Sensor|None = None
        self.last_seen_tag = None
        self.tag = PrintTagHandler()

    def prepare(self):
        self.nfc.__enter__()

    def close(self):
        self.nfc.__exit__(None, None, None)
        self.pi.stop()

    def get_weight(self, times=16) -> float:
        return self.scale.get_grams(times)

    def read_tag(self,) -> None | dict:
        with self.nfc.read_io():
            self.last_seen_tag=self.nfc.read_system_information(parse=True)
        if not self.last_seen_tag:
            print("No last seen Tag")
            return
        with self.nfc.read_io():
            data = self.nfc.read_blocks(self.last_seen_tag['num_blocks'], self.last_seen_tag['block_size'], self.last_seen_tag['uid_lsb'])
        if not any(data):
            print("Empty Tag walk through wizard to initialize a new tag")
            return
        # print(f"{data=}")
        self.tag.current_record = data
        return self.tag.bin_to_dict()

    def write_tag(self, patches:dict, retries_per_block=10, diff_only=True):
        if not self.last_seen_tag:
            with self.nfc.read_io():
                self.last_seen_tag=self.nfc.read_system_information(parse=True)
        if not self.tag.current_record:
            self.read_tag()
        _w=self.tag.bin_to_dict()["data"]["main"].get("actual_netto_full_weight",0)
        b=self.tag.patch_bin({"data": { "aux": {"consumed_weight": _w-self.scale.get_grams()}}})
        patched = bytearray(b)
        with self.nfc.read_io():
            self.nfc.write_blocks(patched, self.last_seen_tag["block_size"], self.last_seen_tag["uid_lsb"], retries_per_block, diff_only)

    def json(self):
        return {
            "name": self.name,
            "scale": self.scale.json(),
            "nfc": self.nfc.json(),
            "last_seen_tag": self.last_seen_tag
        }

    @classmethod
    def from_json(cls, data: dict):
        pi = pigpio.pi()
        stack = cls(name=data["name"], pi=pi)
        stack.nfc = Sensor.from_json(pi, data["nfc"])
        stack.scale = HX711.from_json(pi, data["scale"])
        return stack

if __name__ == "__main__":
    d={"data" : {}}
    pi = pigpio.pi()
    s=Stack(pi, spi_channel=0, dout=25, nss=24, busy=7, reset=8)
    s.prepare()
    # s.write_tag({}, diff_only=True)
    d=s.read_tag()
    #bytearray(b'\xa0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    #bytearray(b'\xbf\x00\x18d\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    s.close()
    print(d)