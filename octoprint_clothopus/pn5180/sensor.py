from abc import ABC, abstractmethod
from contextlib import contextmanager, suppress
import pigpio
from time import sleep
from math import ceil
from typing import Literal, Optional

from ..pn5180.definitions import *


class Sensor:
    def __init__(
        self,
        pi: pigpio.pi,
        spi_channel: int = 0,
        nss : int = 8,
        busy: int = 25,
        reset: int = 7,
        baud: int = 115200,
        verbose: bool = False,
    ) -> None:
        self._verbose: bool = verbose
        self._pi = pi
        self._spi_channel = int(spi_channel)
        self._baud = int(baud)
        self._spi = self._pi.spi_open(self._spi_channel, self._baud, 0)
        self._nss_pin = int(nss)
        self._pi.set_mode(self._nss_pin, pigpio.OUTPUT)
        self._pi.write(self._nss_pin, 1)
        self._busy_pin = int(busy)
        self._pi.set_mode(self._busy_pin, pigpio.INPUT)
        self._reset_pin = int(reset)
        self._pi.set_mode(self._reset_pin, pigpio.OUTPUT)
        self._pi.write(self._reset_pin, 0)
        sleep(1)
        self._pi.write(self._reset_pin, 1)
        sleep(1)

    def _wait_ready(self, timeout=4) -> None:
        self._log("Checking if chip is ready")
        if not self._pi.read(self._busy_pin):
            self._log("Chip is ready; continuing")
            return
        self._log("Chip is not ready, waiting...")
        for i in range(10*timeout):
            if not self._pi.read(self._busy_pin): break
            sleep(0.1)
        else:
            raise TimeoutError("PN5180 BUSY did not go low")
        self._log("Chip is ready; continuing")
        return

    def _log(self, message: str) -> None:
        if self._verbose:
            print(message)

    def _read(self, length: int) -> bytearray:
        self._log(f"Reading {length} bytes")
        self._pi.write(self._nss_pin, 0)
        bytes_read, data = self._pi.spi_read(self._spi, length)
        self._pi.write(self._nss_pin, 1)
        if bytes_read != length:
            raise RuntimeError(
                f"Expected to read {length} bytes but only read {bytes_read}"
            )
        return data

    def _write(self, bytes: list) -> None:
        self._wait_ready()
        self._pi.write(self._nss_pin, 0)
        self._pi.spi_write(self._spi, bytes)
        self._pi.write(self._nss_pin, 1)
        self._log(f"Sent frame: {bytes}")
        self._wait_ready()

    def _turn_on_rf_field(self, parameter: int = 0x00) -> None:
        self._write([CMD_RF_ON, parameter])

    def _turn_off_rf_field(self) -> None:
        # second parameter is a dummy byte
        self._write([CMD_RF_OFF, 0x00])

    def _clear_interrupt_register(self) -> None:
        # write all 1s into the bits actually used
        self._write([CMD_WRITE_REGISTER, REG_IRQ_CLEAR, 0xFF, 0xFF, 0xFF, 0xFF])

    def _read_data_cmd(self) -> None:
        self._write([CMD_READ_DATA, 0x00])

    def _read_irq(self) -> None:
        self._write([CMD_READ_REGISTER, REG_IRQ_CLEAR])

    def __enter__(self):
        self._prepare_sensor()
        return self

    def __exit__(self, exc_type, exc, tb):
        self._end_sensor()
        self._pi.spi_close(self._spi)
        return False

    def _load_protocol(self) -> None:
        self._write([CMD_LOAD_RF_CONFIGURATION, TX_ISO_15693_ASK100_26, RX_ISO_15693_26])

    def _set_idle_state(self) -> None:
        # clear idle bits, keep all other bits the same
        self._write(
            [CMD_WRITE_REGISTER_AND_MASK, REG_SYSTEM_CONFIG, 0xF8, 0xFF, 0xFF, 0xFF]
        )

    def _activate_transceive_routine(self) -> None:
        # set transceive bits, keep all other bits the same
        self._write(
            [CMD_WRITE_REGISTER_OR_MASK, REG_SYSTEM_CONFIG, 0x03, 0x00, 0x00, 0x00]
        )

    def _activate_inventory_mode(self) -> None:
        self._write([CMD_SEND_DATA, 0x00, 0x26, 0x01, 0x00])

    def _set_send_eof(self) -> None:
        # clear bits 7, 8, and 11, keep all other bits the same
        self._write(
            [CMD_WRITE_REGISTER_AND_MASK, REG_TX_CONFIG, 0x3F, 0xFB, 0xFF, 0xFF]
        )

    def _read_tx_config(self, binary=False):
        self._write([CMD_READ_REGISTER, REG_TX_CONFIG])
        response = self._read(REGISTER_SIZE)
        if binary and response:
            return self._to_binary(response)
        return response

    def _send_eof(self) -> None:
        self._write([CMD_SEND_DATA, 0x00])

    def _get_card_response(self, binary=False):
        sleep(0.1)
        self._write([CMD_READ_REGISTER, REG_RX_STATUS])
        response = self._read(REGISTER_SIZE)
        self._log(f"Received {response}")
        b = self._to_binary(response)
        codes = {16-2:"RX_DATA_INTEGRITY_ERROR", 17-2:"RX_PROTOCOL_ERROR", 18-2: "RX_COLLISION_DETECTED"}
        errors = [codes[i] for i in [16-2,17-2,18-2] if b[i]]
        if binary:
            return b
        if errors:
            raise ConnectionError(f"Ran into {', '.join(errors)}\ncode={b}")
            return None
        return response

    def _to_binary(self, data: bytearray):
        return [int(i) for i in "".join([f"{r:08b}" for r in data])]

    def _get_card_response_bytes(self) -> int:
        response = self._get_card_response()
        if response:
            return response[0]
        return 0

    def _get_system_information(self, address: Optional[bytearray]):
        if address:
            self._write([CMD_SEND_DATA, 0x00, 0x22, 0x2B, *address])
        else:
            self._write([CMD_SEND_DATA, 0x00, 0x02, 0x2B])

    def _read_single_block(self, block_number: int, address: Optional[bytearray]=None):
        if address:
            self._write([CMD_SEND_DATA, 0x00, 0x22, 0x20, *address, block_number])
        else:
            self._write([CMD_SEND_DATA, 0x00, 0x02, 0x20, block_number])

    def _read_multiple_blocks(self, start_block, n_blocks, address: Optional[bytearray]=None):
        if address:
            self._write([CMD_SEND_DATA, 0x00, 0x22, 0x23, *address, start_block, n_blocks-1])
        else:
            self._write([CMD_SEND_DATA, 0x00, 0x02, 0x23, start_block, n_blocks-1])

    def _write_single_block(self, block_number:int, data: bytearray, address: Optional[bytearray]=None):
        if address:
            self._write([CMD_SEND_DATA, 0x00, 0x22, 0x21, *address, block_number, *data])
        else:
            self._write([CMD_SEND_DATA, 0x00, 0x02, 0x21, block_number, *data])

    def _write_multiple_blocks(self, start_block, n_blocks, data, address: Optional[bytearray]=None):
        if address:
            self._write([CMD_SEND_DATA, 0x00, 0x22, 0x24, *address, start_block, n_blocks-1, *data])
        else:
           self._write([CMD_SEND_DATA, 0x00, 0x02, 0x24, start_block, n_blocks-1, *data])

    def _prepare_sensor(self):
        self._load_protocol()
        self._turn_on_rf_field()

    def _prepare_read(self):
        self._clear_interrupt_register()
        self._set_idle_state()
        self._activate_transceive_routine()

    def _end_sensor(self):
        # self._set_send_eof()
        self._set_idle_state()
        self._turn_off_rf_field()

    def _end_read(self):
        self._clear_interrupt_register()

    def _read_buffer(self):
        response_bytes = self._get_card_response_bytes()
        if not response_bytes: return None
        self._read_data_cmd()
        buffer_response = self._read(response_bytes)
        self._log(f"Received: {buffer_response}")
        return buffer_response

    def read_inv_response(self) -> Optional[bytearray]:
        self._activate_inventory_mode()
        response=self._read_buffer()
        return response

    def read_system_information(self, address:Optional[bytearray]=None, parse:bool=False) -> Optional[bytearray|dict]:
        self._get_system_information(address)
        response=self._read_buffer()
        if parse and response:
            return self.parse_system_information(response)
        return response

    def read_block(self, block_number:int, address: Optional[bytearray]) -> Optional[bytearray]:
        if block_number < 0 or block_number > 255: raise ValueError(f"{block_number=} but must be between 0 and 255")
        self._read_single_block(block_number, address)
        response=self._read_buffer()
        return response

    def read_blocks(self, n_blocks:int, block_size: Literal[4, 8], address: Optional[bytearray]=None, retries=10):
        if n_blocks < 0 or n_blocks > 255: raise ValueError(f"{n_blocks=} but must be between 0 and 255")
        if block_size != 4 and block_size != 8: raise ValueError(f"{block_size=} must be either 4 or 8")
        response = bytearray()
        max_request = int(0xFF/block_size)
        current = 0
        remaining = n_blocks
        while remaining > 0:
            n = min(remaining, max_request)
            self._read_multiple_blocks(current, n, address)
            chunk=self._read_buffer()
            for j in range(retries):
                if chunk and chunk[0] == 0:
                    break
                self._read_multiple_blocks(current, n, address)
                chunk=self._read_buffer()
            else: raise TimeoutError(f"Could not read blocks from {current} to {current+n}")
            response.extend(chunk[1:])
            current += n
            remaining -= n
        return response

    def write_blocks(self, data: bytearray, block_size: Literal[4, 8], address: Optional[bytearray]=None, retries=10, diff_only=False):
        blocks = {i: b for i,b in enumerate(data[i:block_size+i] for i in range(0, len(data), block_size))}
        n_blocks = len(blocks)
        if diff_only:
            _b = self.read_blocks(n_blocks, block_size, address, retries)
            old = {i: b for i,b in enumerate(_b[i:block_size+i] for i in range(0, len(_b), block_size))}
            blocks = {i: blocks[i] for i in old if blocks[i]!=old[i]}
        if n_blocks < 0 or n_blocks > 255: raise ValueError(f"{n_blocks=} but must be between 0 and 255")
        errors=[]
        for i, block in blocks.items():
            with self.read_io(): #TODO why is IRQ not cleared. Read IRQ_STATUS
                self._write_single_block(i, block, address)
                status = self._read_buffer()
                for j in range(retries):
                    with self.read_io():
                        if status:
                            break
                        self._write_single_block(i, block, address)
                        status = self._read_buffer()
                else: errors.append(str(i))
        if errors:
            raise ConnectionError(f"Couldnt write to blocks: {', '.join(errors)}")

    def write_block(self, block_number, data: bytearray):
        raise NotImplementedError

    def parse_system_information(self, response: bytes) -> dict[str, object]:
        if len(response) < 2:
            raise ValueError("response too short to be valid system information")
        result: dict[str, object] = {}
        info_flags = response[1]
        result["infoflags"] = info_flags
        index = 2  # pointer to next field
        if info_flags & 0x01:
            uid = response[index:index+8]
            if len(uid) != 8:
                raise ValueError("invalid uid length")
            result["uid_lsb"] = uid
            result["uid"] = uid[::-1]  # msb-first
            index += 8
        if info_flags & 0x02:
            result["dsfid"] = response[index]
            index += 1
        if info_flags & 0x04:
            result["afi"] = response[index]
            index += 1
        if info_flags & 0x08:
            if len(response) < index + 2:
                raise ValueError("memory size field incomplete")
            num_blocks_minus1 = response[index]
            block_size_minus1 = response[index + 1]
            result["num_blocks"] = num_blocks_minus1 + 1
            result["block_size"] = block_size_minus1 + 1
            index += 2
        if info_flags & 0x10:
            if len(response) <= index:
                raise ValueError("ic reference field missing")
            result["ic_ref"] = response[index]
            index += 1

        return result

    def reachable(self):
        r=self._read_tx_config()
        return any(r)

    @contextmanager
    def read_io(self):
        self._prepare_read()
        try:
            yield self
        finally:
            self._end_read()

    def json(self):
        return {
            "busy": self._busy_pin,
            "nss": self._nss_pin,
            "reset": self._reset_pin,
            "spi_channel": self._spi_channel,
            "baud": self._baud
        }

    @classmethod
    def from_json(cls, pi:pigpio.pi, data: dict):
        if not pi:
            raise ValueError
        return cls(pi, **data)
