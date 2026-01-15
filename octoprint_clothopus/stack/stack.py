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
        if self.nfc is not None:
            self.nfc.__enter__()

    def close(self):
        if self.nfc is not None:
            self.nfc.__exit__(None, None, None)
        # self.pi.stop()

    def get_weight(self, times=16) -> float:
        return self.scale.get_grams(times)

    def read_tag(self,) -> None | dict:
        with self.nfc.read_io():
            self.last_seen_tag=self.nfc.read_system_information(parse=True)
        if not self.last_seen_tag:
            # print("No last seen Tag")
            return
        with self.nfc.read_io():
            data = self.nfc.read_blocks(self.last_seen_tag['num_blocks'], self.last_seen_tag['block_size'], self.last_seen_tag['uid_lsb'])
        if not any(data):
            print("Empty Tag walk through wizard to initialize a new tag")
            return {}
        # print(f"{data=}")
        self.tag.current_record = data
        return self.tag.bin_to_dict()

    def write_tag(self, patches:dict = {}, retries_per_block=10, diff_only=True, with_weight=True):
        if not self.last_seen_tag:
            with self.nfc.read_io():
                self.last_seen_tag=self.nfc.read_system_information(parse=True)
        if not self.tag.current_record:
            self.read_tag()
        _info = self.tag.bin_to_dict()
        _w=_info["data"]["main"].get("actual_netto_full_weight",0)+_info["data"]["main"].get("empty_container_weight",0)
        weight =  {"data": { "aux": {"consumed_weight": _w-self.scale.get_grams()}}} if with_weight else {}
        b=self.tag.patch_bin(patches | weight)
        patched = bytearray(b)
        with self.nfc.read_io():
            self.nfc.write_blocks(patched, self.last_seen_tag["block_size"], self.last_seen_tag["uid_lsb"], retries_per_block, diff_only)
        return self.tag.bin_to_dict()
            
    def init_tag_w_id(self, prusa_id: str):
        tag_data: dict = self.tag.generate_opt_json(prusa_id)
        if tag_data:
            self.tag.nfc_initialize()
            self.tag.patch_bin(tag_data)
            return True
        return False

    def json(self):
        return {
            "name": self.name,
            "scale": self.scale.json(),
            "nfc": self.nfc.json(),
            "last_seen_tag": self.last_seen_tag
        }

    @classmethod
    def from_json(cls, pi, data: dict):
        stack = cls(name=data["name"], pi=pi)
        stack.nfc = Sensor.from_json(pi, data["nfc"])
        stack.scale = HX711.from_json(pi, data["scale"])
        return stack

if __name__ == "__main__":
    from octoprint_clothopus.pn5180 import Sensor
    from octoprint_clothopus.hx711 import HX711
    from octoprint_clothopus.OPTag import PrintTagHandler
    import time
    from statistics import stdev
    
    pth = PrintTagHandler()
    pth.nfc_initialize()
    pth.patch_bin({'data': {'main': {'material_class': 'FFF', 'material_type': 'PETG', 'material_name': 'PETG Prusa Orange', 'brand_name': 'Prusament'}}})
    print(pth.bin_to_dict())
    # pi = pigpio.pi()
    # stacks = [Stack(f"test{i}", pi) for i in range(5)]
    # s=Stack("test", pi)
    # d={"data" : {}}
    # for s in stacks:
    # stacks[1-1].nfc = Sensor(pi, spi_channel=0, nss=12, reset=13, busy=5)
    # stacks[2-1].nfc = Sensor(pi, spi_channel=0, nss=20, reset=26, busy=19)
    # stacks[3-1].nfc = Sensor(pi, spi_channel=0, nss=24, reset=8, busy=7)
    # stacks[4-1].nfc = Sensor(pi, spi_channel=0, nss=27, reset=22, busy=17)
    # stacks[5-1].nfc = Sensor(pi, spi_channel=0, nss=3, reset=4, busy=2)
    # stacks[1-1].scale = HX711(pi, dout=16, pd_sck=6)
    # stacks[2-1].scale = HX711(pi, dout=21, pd_sck=6)
    # stacks[3-1].scale = HX711(pi, dout=25, pd_sck=6)
    # stacks[4-1].scale = HX711(pi, dout=23, pd_sck=6)
    # stacks[5-1].scale = HX711(pi, dout=18, pd_sck=6)
    # s.scale = HX711.from_json(pi, {'pins': {'dout': 25, 'pd_sck': 6, 'gain': 128}, 'calib': {'offset': -384446.3125, 'scale': -440.7148913043478}})
    # s.scale = HX711.from_json(pi, {'pins': {'dout': 25, 'pd_sck': 6, 'gain': 128}, 'calib': {'offset': -384446.3125, 'scale': -440.7148913043478}})
    # s.scale = HX711(pi, dout=21, pd_sck=6, gain=128, calc_offset=True)
    # for s in stacks:
    #     # s.prepare()
    #     try:
    #         # s.scale.reachable()
    #         # c=s.scale.calib_scale(int(input("Put known>>> ")))
    #         # print(c)
    #         # input("put funky weight")
    #         first=s.get_weight()
    #         print(first)
    #         # s.scale = HX711.from_json()
    #         # print(s.scale.reachable())
    #         # s.write_tag({}, diff_only=True)
    #         # d=s.read_tag()
    #         # print(d)
    #         # measurments=[]
    #         # for i in range(10):
    #         #     measurments.append(s.get_weight())
    #         #     s.scale.power_cycle()
    #         #     time.sleep(2)
    #         # print(f"σ={stdev(measurments)}", "\n\n", measurments)
    #     except KeyboardInterrupt:
    #         s.close()
    #         print("cleaned")
    # s.prepare()
    # s.write_tag({}, diff_only=True)
    # d=s.read_tag()
    #bytearray(b'\xa0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    #bytearray(b'\xbf\x00\x18d\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    # s.close()
    # print(d)