# This file is executed on every boot (including wake-boot from deepsleep)
#import esp
#esp.osdebug(None)
#import webrepl
#webrepl.start()
import time
import network
from machine import Pin
from microdot import Microdot, Request, Response
from driver.kailhEnc import KailhEnc
from driver.pn5180.sensor import Sensor
# from dummy_driver.DummySensor import DummySensor as Sensor
# from dummy_driver.DummyEnc import DummyKailhEnc as KailhEnc


lan = network.LAN(mdc=Pin(23), mdio=Pin(18), power=Pin(12), phy_type=network.PHY_LAN8720, phy_addr=0, ref_clk=Pin(17), ref_clk_mode=Pin.OUT)
lan.active(True)

for i in range(30):
    print("active:", lan.active(), "connected:", lan.isconnected(), "ifconfig:", lan.ifconfig())
    if lan.isconnected():
        break
    time.sleep(1)

app = Microdot()

@app.get('/sysinfo')
async def sysinfo(request: Request):
    s: Sensor = request.app.sensor
    with s.read_io():
        last_tag = s.read_system_information(parse=True)
    if not last_tag:
        return Response(reason="No tag", status_code=404)
    resp = {}
    for k,v in last_tag.items():
        resp[k] = v.hex() if "uid" in k else v
    return resp

@app.get("/blocks")
def read_tag(request: Request):
    s: Sensor = request.app.sensor
    with s.read_io():
        last_tag = s.read_system_information(parse=True)
    if not last_tag:
        return Response(reason="No tag", status_code=404)
    with s.read_io():
        data = s.read_blocks(last_tag['num_blocks'], last_tag['block_size'], last_tag['uid_lsb'])
    if not any(data):
        # print("Empty Tag walk through wizard to initialize a new tag")
        return Response("Empty tag found", status_code=204)
    # print(f"{data=}")
    return Response(bytes(data), headers={"Content-Type": "application/octet-stream"})

@app.get("/reachable")
def reachable(request: Request):
    s: Sensor = request.app.sensor
    code = 200 if s.reachable() else 404
    return Response(status_code=code)

@app.get("/consumed")
def get_clicks(request: Request):
    e: KailhEnc = request.app.encoder
    density = float(request.args.get("density"))
    filament_diameter = float(request.args.get("filament_diameter"))
    if density is None or filament_diameter is None:
        return Response("Missing parameters", status_code=404)
    resp = {"consumed_weight": e.weight_from_clicks(density, filament_diameter)}
    return resp

@app.post("/blocks")
def write_tag(request: Request):
    data = bytearray(request.body)
    retries_per_block = int(request.args.get("retries_per_block"), 10)
    diff_only = request.args.get("diff_only")
    s: Sensor = request.app.sensor
    with s.read_io():
        last_tag=s.read_system_information(parse=True)
    with s.read_io():
        s.write_blocks(data, last_tag["block_size"], last_tag["uid_lsb"], retries_per_block, diff_only)
    return Response(bytes(data), headers={"Content-Type": "application/octet-stream"})

def main():
    with KailhEnc() as encoder:
        app.encoder = encoder
        with Sensor() as sensor:
            app.sensor = sensor
            print("Starting microdot service.")
            app.run(port=80, debug=True)

if __name__ == "__main__":
    main()