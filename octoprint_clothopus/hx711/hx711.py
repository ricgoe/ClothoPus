# import RPi.GPIO as GPIO
from contextlib import suppress
import pigpio
import time
import warnings
import threading

class HX711:
    gain_mapper: dict = {128: 3, 64: 2, 32: 1}

    def __init__(self, pi:pigpio.pi, dout:int, pd_sck:int, gain:int=128, calc_offset: bool = True):
        """
        Set GPIO Mode, and pin for communication with HX711
        :param dout: Serial Data Output pin
        :param pd_sck: Power Down and Serial Clock Input pin
        :param gain: set gain 128, 64, 32
        """

        self._gain = 0
        self._offset = 0
        self._scale = 1

        # Setup the gpio pin numbering system
        # GPIO.setmode(GPIO.BCM)
        self._pi = pi

        # Set the pin numbers
        self._pd_sck: int = int(pd_sck)
        self._dout: int = int(dout)

        # Setup the GPIO Pin as output
        self._pi.set_mode(self._pd_sck, pigpio.OUTPUT)

        # Setup the GPIO Pin as input
        self._pi.set_mode(self._dout, pigpio.INPUT)

        # Power up the chip
        self.power_up()
        self.set_gain(gain)

        self.reachable()

        if calc_offset:
            self.calib_offset()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        with suppress(Exception):
            self.clean_exit()
        return False

    def set_gain(self, gain=128):
        if gain not in HX711.gain_mapper:
            warnings.warn(
                f"Invalid gain '{gain}', falling back to default (128). "
                f"Valid values: {list(HX711.gain_mapper.keys())}"
            )

        self._gain = gain
        self.power_up()
        self.read()


    def read(self):
        """
        Read data from the HX711 chip
        :param void
        :return reading from the HX711
        """

        # Control if the chip is ready
        self.reachable()

        # Original C source code ported to Python as described in datasheet
        # https://cdn.sparkfun.com/datasheets/Sensors/ForceFlex/hx711_english.pdf
        # Output from python matched the output of
        # different HX711 Arduino library example
        # Lastly, behaviour matches while applying pressure
        # Please see page 8 of the PDF document

        count = 0

        for i in range(24):
            self._pi.gpio_trigger(self._pd_sck, 2, 1)
            count = count << 1
            if self._pi.read(self._dout):
                count += 1

        self._pi.gpio_trigger(self._pd_sck, 2, 1) #TODO
        count = count ^ 0x800000

        # set channel and gain factor for next reading
        for _ in range(HX711.gain_mapper.get(self._gain, 1)):
            self._pi.gpio_trigger(self._pd_sck, 2, 1)

        return count

    def read_average(self, times: int = 16):
        """
        Calculate average value from
        :param times: measure x amount of time to get average
        """
        sum = 0
        for i in range(times):
            sum += self.read()
        return sum / times

    def get_grams(self, times: int = 16):
        """
        :param times: Set value to calculate average,
        be aware that high number of times will have a
        slower runtime speed.
        :return float weight in grams
        """
        v = self.read_average(times)
        # print(f"{self._offset=}, {self._scale=}, {v=}")
        value = (v - self._offset)
        grams = (value / self._scale)
        self.power_cycle()

        return grams

    def tara(self, times: int = 16):
        """
        Tare functionality for calibration
        :param times: set value to calculate average
        """
        sum = self.read_average(times)
        self._offset = sum

    def power_down(self):
        """
        Power the chip down
        """
        self._pi.write(self._pd_sck, 0)
        self._pi.write(self._pd_sck, 1)

    def power_up(self):
        """
        Power the chip up
        """
        self._pi.write(self._pd_sck, 0)

    def power_cycle(self):
        # stable readings
        # self._pi.gpio_trigger(self._pd_sck, 100, 1)
        self.power_down()
        time.sleep(.001)
        self.power_up()

    def reachable(self, timeout_s: int = 5):
        ev = threading.Event()
        cb = self._pi.callback(self._dout, pigpio.FALLING_EDGE, lambda g, l, t: ev.set())
        try:
            if self._pi.read(self._dout) == 0:
                return
            if not ev.wait(timeout_s):
                raise ConnectionError(f"Scale is not reachable on pins: dout={self._dout}, pd_sck={self._pd_sck}")
        finally:
            cb.cancel()

    def calib_offset(self)-> None:
        offset = self.read_average()
        self._offset = offset

    def calib_scale(self, known_weight: str | float) -> dict[str, dict[str, int] | dict[str, float]]:
        try:
            if isinstance(known_weight, str):
                known_weight.replace(",", ".")
            known_weight = float(known_weight)
        except ValueError:
            return None
        measured_weight = (self.read_average()-self._offset)
        scale = measured_weight/known_weight
        self._scale = scale
        return self.json()

    @classmethod
    def from_json(cls, pi:pigpio.pi, data: dict):
        pins: dict = data["pins"]
        calib: dict = data["calib"]
        if not pi:
            raise ValueError
        scale = cls(pi,**pins, calc_offset=False)
        scale._offset = calib.get("offset")
        scale._scale = calib.get("scale")
        return scale

    def json(self):
        return {
            "pins": {"dout": self._dout, "pd_sck": self._pd_sck, "gain": self._gain},
            "calib": {"offset": self._offset, "scale": self._scale}
        }

if __name__ == "__main__":
    polumbus = pigpio.pi()
    scala = HX711(polumbus, 25, 6)
    print(scala.get_grams())