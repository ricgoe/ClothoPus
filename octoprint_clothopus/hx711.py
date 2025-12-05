from typing import Optional
class HX711:
    
    @classmethod
    def from_json(cls, data: dict):
        return cls(**data.get("pins"))
    
    def __init__(self, dout, pd_sck, gain=128):
        self.dout = dout
        self.pd_sck = pd_sck
        self.gain = gain
    
    def reachable(self) -> bool:
        return True
    
    def calib_scale(self, known_weight: float)->dict[str, dict[str, int|float]]:
        return self.json()
    
    def json(self):
        return dict(pins=dict(dout=self.dout, pd_sck=self.pd_sck), calib=dict(offset=804444.776, scale=-448.998))
    
    def get_grams(self) -> Optional[float]:
        return 1*self.dout
    