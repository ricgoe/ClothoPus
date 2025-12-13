# import RPi.GPIO as GPIO
import pigpio
import time
import warnings

class HX711:
    gain_mapper: dict = {128: 3, 64: 2, 32: 1}

    def __init__(self, dout:int, pd_sck:int, gain:int=128, calc_offset: bool = True):
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
        self._pi = pigpio.pi()

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

        if not self.reachable():
            raise ConnectionError(f"Scale is not reachable on pins: {dout=}, {pd_sck=}")

        if calc_offset:
            self.calib_offset()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        self.clean_exit()

    @classmethod
    def from_json(cls, data: dict):
        pins: dict = data.get("pins")
        calib: dict = data.get("calib")
        if not pins or not calib:
            raise ValueError
        scale = cls(**pins, calc_offset=False)
        scale._offset = calib.get("offset")
        scale._scale = calib.get("scale")
        return scale

    def set_gain(self, gain=128):
        if gain not in HX711.gain_mapper:
            warnings.warn(
                f"Invalid gain '{gain}', falling back to default (3). "
                f"Valid values: {list(HX711.gain_mapper.keys())}"
            )

        self._gain = HX711.gain_mapper.get(gain, 3)
        self.power_up()
        self.read()


    def read(self):
        """
        Read data from the HX711 chip
        :param void
        :return reading from the HX711
        """

        # Control if the chip is ready
        while not (self._pi.read(self._dout) == 0):
            # Uncommenting the print below results in noisy output
            # print("No input from HX711.")
            pass

        # Original C source code ported to Python as described in datasheet
        # https://cdn.sparkfun.com/datasheets/Sensors/ForceFlex/hx711_english.pdf
        # Output from python matched the output of
        # different HX711 Arduino library example
        # Lastly, behaviour matches while applying pressure
        # Please see page 8 of the PDF document

        count = 0

        for i in range(24):
            self._pi.write(self._pd_sck, 1)
            count = count << 1
            self._pi.write(self._pd_sck, 0)
            if(self._pi.read(self._dout)):
                count += 1

        self._pi.write(self._pd_sck, 1)
        count = count ^ 0x800000
        self._pi.write(self._pd_sck, 0)

        # set channel and gain factor for next reading
        for i in range(self._gain):
            self._pi.write(self._pd_sck, 1)
            self._pi.write(self._pd_sck, 0)

        return count

    def read_average(self, times: int = 16):
        """
        Calculate average value from
        :param times: measure x amount of time to get average
        """
        self.power_cycle()
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
        value = (self.read_average(times) - self._offset)
        grams = (value / self._scale)
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
        self.power_down()
        time.sleep(.001)
        self.power_up()


    def reachable(self, max_tries: int = 20) -> bool:
        scale_ready = False
        for _ in range(max_tries):
            if (self._pi.read(self._dout) == 1):
                scale_ready = True
                break
            if (self._pi.read(self._dout) == 0):
                scale_ready = False
        return scale_ready

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

    def json(self):
        return {"pins": {"dout": self._dout, "pd_sck": self._pd_sck}, "calib": {"offset": self._offset, "scale": self._scale}}

    def clean_exit(self):
        print("Cleaning up...")
        self._pi.stop()
        print("Bye!")



if __name__ == "__main__":
    with HX711(25, 6) as scala:
        print(scala.get_grams())