import math
import random

PER_ROTATION = 24
ODOMETER_DIAMETER = 7.25

class DummyKailhEnc:
    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False
    
    def get_count(self):
        return random.randint(0,24)

    def weight_from_clicks(self, density: float, filament_diameter: float):
        o = ODOMETER_DIAMETER/10
        f = filament_diameter/10
        length = self.get_count() * (math.pi * o) / PER_ROTATION
        area = math.pi * (f / 2) ** 2
        return density * area * length