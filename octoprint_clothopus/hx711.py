from typing import Optional
class HX711:
    
    @classmethod
    def from_json(cls, data: dict):
        return cls()
    
    def __init__(self, dout, pd_sck, gain=128):
        pass
    
    def reachable(self) -> bool:
        return True
    
    def calib_scale(self, known_weight: float)->dict[str, dict[str, int|float]]:
        return self.json()
    
    def json(self):
        return dict(pins=dict(dout=1, pd_sck=2), calib=dict(offset=804444.776, scale=-448.998))
    