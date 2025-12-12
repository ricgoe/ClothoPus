from record import Record
from common import default_config_file
from opt_check import opt_check
import ndef
import cbor2
import os
import types
import yaml
from fields import Fields, EncodeConfig
from common import default_config_file


class PrintTagHandler:
    def __init__(self, config_file = default_config_file, size: int = 320, block_size: int = 4, aux_region_size: int = 32, meta_region = None, max_meta_section_size: int = 8):
        self._current_record: Record = None
        self._config_file = config_file
        self._size: int = size
        self._block_size: int = block_size
        self._aux_region_size: int = aux_region_size
        self._meta_region = meta_region
        self._max_meta_section_size: int = max_meta_section_size
        
    @property
    def current_record(self):
        return self._current_record
    
    @current_record.setter
    def current_record(self, data: bytearray):
        self._current_record = Record(self._config_file , memoryview(data))
    
    
    def bin_to_dict(self, tag_uid = None) -> dict:
        if tag_uid:
            tag_uid = bytes.fromhex(tag_uid) 
        output = {}
        data = {}   
        unknown_fields = {}

        for name, region in self._current_record.regions.items():
            if name == "meta":
                continue

            unknown_fields = dict()
            data[name] = region.read(out_unknown_fields=unknown_fields)

            if len(unknown_fields) > 0:
                unknown_fields[name] = unknown_fields

        output["data"] = data

        if len(unknown_fields):
            output["unknown_fields"] = unknown_fields

        output["uri"] = self._current_record.uri

        for name, region in self._current_record.regions.items():
            region.fields.validate(region.read())
            output["opt_check"] = opt_check(self._current_record, tag_uid)

        return output
    
    
    def patch_bin(self, patch_data: dict) -> bytes:
        for region_name, region in self._current_record.regions.items():
            region.update(
                update_fields=patch_data.get("data", dict()).get(region_name, dict()),
                remove_fields=patch_data.get("remove", dict()).get(region_name, dict()),
                clear=False,
            )

        return self._current_record.data
    
    
    def nfc_initialize(self, ndef_uri: bool = None):
        
        def write_section(offset: int, data: bytes):
            enc_len = len(data)
            payload[offset : offset + enc_len] = data
            return enc_len

        def align_region_offset(offset: int, align_up: bool = True):
            """Aligns offset to the NDEF block size"""

            # We're aligning within the whole tag frame, not just within the NFC payload
            misalignment = (ndef_payload_start + offset) % self._block_size
            if misalignment == 0:
                return offset

            elif align_up:
                return offset + self._block_size - misalignment

            else:
                return offset - misalignment
        
        
        config_dir = os.path.dirname(self._config_file)
        with open(self._config_file, "r", encoding="utf-8") as f:
            config = types.SimpleNamespace(**yaml.safe_load(f))

        assert config.root == "nfcv", "nfc_initialize only supports NFC-V tags"

        # Set up TLV and CC
        assert (self._size % 8) == 0, f"Tag size {self._size} must be divisible by 8 (to be encodable in the CC)"
        assert self._size/ 8 <= 255, "Tag too big to be representable in the CC"
        capability_container = bytes(
            [
                0xE1,  # Magic number
                0x40  # Version 1.0 (upper 4 bits)
                | 0x0,  # Read/write access without restrictions (lower 4 bits)
                self._size // 8,
                #
                # Capabilities - TAG SPECIFIC!
                0x01,  # MBREAD - supports "Read Multiple Blocks" command - SLIX2 DOES
                # | 0x02 # IPREAD - supports "Inventory Page Read" command - SLIX2 does NOT
            ]
        )
        capability_container_size = len(capability_container)

        tlv_terminator = bytes([0xFE])

        ndef_tlv_header_size = 2

        # Our NDEF record will be adjusted so that the message fills the whole available space
        ndef_message_length = self._size - capability_container_size - len(tlv_terminator) - ndef_tlv_header_size

        if ndef_message_length > 0xFE:
            # We need two more bytes to encode longer TLV lenghts
            ndef_tlv_header_size += 2
            ndef_message_length -= 2

        # Do not merge with the previous if - the available space decrease might get us under this line
        if ndef_message_length <= 0xFE:
            ndef_tlv_header = bytes(
                [
                    0x03,  # NDEF Message tag
                    ndef_message_length,
                ]
            )
        else:
            ndef_tlv_header = bytes(
                [
                    0x03,  # NDEF Message tag
                    0xFF,
                    ndef_message_length // 256,
                    ndef_message_length % 256,
                ]
            )

        assert len(ndef_tlv_header) == ndef_tlv_header_size

        # Set up preceding NDEF regions
        records = []
        if ndef_uri is not None:
            records.append(ndef.UriRecord(ndef_uri))

        preceding_records_size = len(b"".join(ndef.message_encoder(records)))

        ndef_header_size = 3 + len(config.mime_type)
        ndef_payload_start = capability_container_size + ndef_tlv_header_size + preceding_records_size + ndef_header_size
        payload_size = ndef_message_length - ndef_header_size - preceding_records_size

        assert payload_size > self._max_meta_section_size, "There is not enough space even for the meta region"

        # If the NDEF payload size would exceed 255 bytes, its length cannot be stored in a single byte
        # and NDEF switches to storing the length into 4 bytes
        if payload_size > 255:
            ndef_header_size += 3
            ndef_payload_start += 3
            payload_size -= 3

            # If we now got back under 255, the ndef payload length will be shorter again and we wouldn't fill the NDEF message fully to the TLV-dictated size
            # This could be resolved by enforcing the longer NDEF header in this case anyway, but the NDEF library does not support it - we'd need to construct the NDEFs by ourselves
            assert payload_size > 255, "Unable to fill the NDEF message correctly"

        payload = bytearray(payload_size)
        metadata = dict()
        meta_fields = Fields.from_file(os.path.join(config_dir, config.meta_fields))

        

        # Determine main region offset
        if self._meta_region is not None:
            # If we don't know the meta section actual size (because it is deteremined by how the main_region_offset is encoded), we have to assume maximum
            main_region_offset = self._meta_region
            metadata["main_region_offset"] = main_region_offset
        else:
            # If we are not aligning, we don't need to write the main region offset, it will be directly after the meta region
            main_region_offset = None

        # Prepare aux region
        if self._aux_region_size is not None:
            assert self._aux_region_size > 4, "Aux region is too small"

            aux_region_offset = align_region_offset(payload_size - self._aux_region_size, align_up=False)
            metadata["aux_region_offset"] = aux_region_offset
            write_section(aux_region_offset, cbor2.dumps({}))

        # Prepare meta section
        # Indefinite containers take one extra byte, don't do that for the meta region - that one won't likely ever be updated
        meta_section_size = write_section(0, meta_fields.encode(metadata, EncodeConfig(indefinite_containers=False)))
        if main_region_offset is None:
            main_region_offset = meta_section_size

        if self._aux_region_size is not None:
            assert aux_region_offset - main_region_offset >= 4, "Main region is too small"
        else:
            assert payload_size - main_region_offset >= 8, "Main region is too small"

        # Write main region
        write_section(main_region_offset, cbor2.dumps({}))

        # Create the NDEF record
        records.append(ndef.Record(config.mime_type, "", payload))
        ndef_data = b"".join(ndef.message_encoder(records))

        assert len(ndef_data) == ndef_message_length

        # Check that we have deduced the ndef header size correctly
        expected_size = preceding_records_size + ndef_header_size + payload_size
        if len(ndef_data) != expected_size:
            raise ValueError(f"NDEF record calculated incorrectly: expected size {expected_size} ({preceding_records_size} + {ndef_header_size} + {payload_size}), but got {len(ndef_data)}")

        full_data = bytes()
        full_data += capability_container
        full_data += ndef_tlv_header
        full_data += ndef_data
        full_data += tlv_terminator

        # The full data can be slightly smaller because we might have decreased ndef_tlv_available_space by 2 to fit the bigger TLV header and then ended up not needing the bigger TLV header
        assert self._size - 1 <= len(full_data) <= self._size

        # Check that the payload is where we expect it to be
        assert full_data[ndef_payload_start : ndef_payload_start + payload_size] == payload

        self.current_record = bytearray(full_data)
        
        return bytearray(full_data)
    
    

if __name__ == "__main__":
    pth = PrintTagHandler()
    pth.nfc_initialize()
    a = {'data': {'main': {'material_class': 'FFF', 'material_type': 'PETG', 'material_name': 'PETG Prusa Orange', 'brand_name': 'Prusament'}}}
    pth.patch_bin(a)
    b = {'data': {'main': {'brand_name': 'Prasament'}}}
    pth.patch_bin(b)
    c = {'data': {'main': {'brand_name': 'Prusament'}}}
    pth.patch_bin(c)
    print(pth.bin_to_dict())
    
    

