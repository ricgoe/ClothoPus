from pn5180 import ISO15693Sensor
from hx711 import HX711
from OPTag import PrintTagHandler
import pigpio

class Stack:
    def __init__(
            self, spi_channel:int, dout:int, nss:int, busy:int, reset:int, pd_sck:int=6, gain:int=128,
            calc_scale_offset:bool=False, baud:int = 115200, verbose: bool = False
        ):
        self._pi = pigpio.pi()
        self.scale = HX711(self._pi, dout, pd_sck, gain, calc_offset=calc_scale_offset)
        self.nfc = ISO15693Sensor(self._pi, spi_channel, nss, busy, reset, baud, verbose)
        self.last_seen_tag = None
        self.tag = PrintTagHandler()

    def __enter__(self):
        self.nfc.__enter__()
        return self

    def __exit__(self, exc_type, exc, tb):
        self.nfc.__exit__(exc_type, exc, tb)
        self._pi.stop()
        return False

    def get_weight(self, times=16) -> float:
        return self.scale.get_grams(times)

    def read_tag(self,) -> None | dict:
        if not self.last_seen_tag:
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

if __name__ == "__main__":
    d={"data" : {}}
    with Stack(spi_channel=0, dout=25, nss=24, busy=7, reset=8) as s:
        s.write_tag({}, diff_only=True)
        d=s.read_tag()
        #bytearray(b'\xa0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        #bytearray(b'\xbf\x00\x18d\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        print(d)