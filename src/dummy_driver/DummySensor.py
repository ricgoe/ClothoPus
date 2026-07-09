import random
import os

class DummyReadIO:
    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False


class DummySensor:
    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def read_io(self):
        return DummyReadIO()

    def read_system_information(self, parse=True):
        # if random.choice([True, False]):
            # return None

        return {
            "num_blocks": 80,
            "block_size": 4,
            "uid_lsb": os.urandom(8).hex(),
        }

    def read_blocks(self, num_blocks, block_size, uid_lsb):
        size = num_blocks * block_size

        if random.choice([True, False]):
            return bytearray(size)  # empty tag
        arr = bytearray(random.getrandbits(8) for _ in range(size))
        arr[-1] = 254
        return arr

    def write_blocks(self, data, block_size, uid_lsb, retries_per_block, diff_only):
        print("dummy write_blocks:", {
            "size": len(data),
            "block_size": block_size,
            "uid_lsb": uid_lsb,
            "retries_per_block": retries_per_block,
            "diff_only": diff_only,
            "data": data,
        })

    def reachable(self):
        return True