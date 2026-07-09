import math
import time
from machine import Pin, disable_irq, enable_irq # type: ignore

PER_ROTATION = 24
ODOMETER_DIAMETER = 7.25


class KailhEnc:
    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        self.pin.irq(handler=None)
        return False

    def __init__(self, pin_no=15):
        self.count = 0
        self.pin = Pin(pin_no, Pin.IN, Pin.PULL_DOWN)
        self.last_tick = 0
        self.pin.irq(
            trigger=Pin.IRQ_RISING,
            handler=self._on_rising,
        )

    def _on_rising(self, pin):
        now = time.ticks_ms()
        if time.ticks_diff(now, self.last_tick) > 6:
            self.count += 1
            self.last_tick = now

    def get_count(self):
        state = disable_irq()
        try:
            value = self.count
            self.count = 0
            return value
        finally:
            enable_irq(state)

    def weight_from_clicks(self, density: float, filament_diameter: float):
        o = ODOMETER_DIAMETER/10
        f = filament_diameter/10
        length = self.get_count() * (math.pi * o) / PER_ROTATION
        area = math.pi * (f / 2) ** 2
        return density * area * length