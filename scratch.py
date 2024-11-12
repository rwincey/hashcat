"""
Adapted from https://gitlab.com/lschwiderski/vt2_bundle_unpacker
murmur/murmurhash64.rs
https://bitsquid.blogspot.com/2011/08/code-snippet-murmur-hash-inverse-pre.html
This appears to be MurmurHash2 (specifically MurmurHash64A)
"""
global INITIAL
global MIDDLE_OF_BLOCK
global BEFORE_OVERFLOW
global OVERFLOW
global AFTER_OVERFLOW_7
global AFTER_OVERFLOW

INITIAL = None
MIDDLE_OF_BLOCK = None
BEFORE_OVERFLOW = None
OVERFLOW = None
AFTER_OVERFLOW_7 = None
AFTER_OVERFLOW = None



# 'M' and 'R' are mixing constants generated offline.
# They're not really 'magic', they just happen to work well.
M: int = 0xC6A4A7935BD1E995  # u64
# Multiplicative inverse of `M` under % 2^64
M_INVERSE: int = 0x5F7A0EA7E59B19BD  # u64
R: int = 47  # 47


def wrapping_mul(a, b):
    # Returns (a * b) mod 2**N, where N is the width of a and b in bits.
    # we're only dealing in u64, so N is always 64?
    return (a * b) % 2**64


def hash64(key: list[int], seed: int) -> int:
    global INITIAL
    global MIDDLE_OF_BLOCK
    global BEFORE_OVERFLOW
    global OVERFLOW
    global AFTER_OVERFLOW_7
    global AFTER_OVERFLOW
    length = len(key)
    h: int = seed ^ wrapping_mul(length, M)

    INITIAL = h

    endpos = length - (length & 7)
    
    i = 0
    while i != endpos:
        k = key[i]
        k |= key[i + 1] << 8
        k |= key[i + 2] << 16
        k |= key[i + 3] << 24
        k |= key[i + 4] << 32
        k |= key[i + 5] << 40
        k |= key[i + 6] << 48
        k |= key[i + 7] << 56

        if i == 0:
            MIDDLE_OF_BLOCK = k

        k = wrapping_mul(k, M)
        k ^= k >> R
        k = wrapping_mul(k, M)

        h ^= k
        h = wrapping_mul(h, M)

        i += 8
    
    
    BEFORE_OVERFLOW = h
    overflow = length & 7
    OVERFLOW = overflow
    if overflow == 7:
        h ^= key[i + 6] << 48
        AFTER_OVERFLOW_7 = h
    if overflow >= 6:
        h ^= key[i + 5] << 40
    if overflow >= 5:
        h ^= key[i + 4] << 32
    if overflow >= 4:
        h ^= key[i + 3] << 24
    if overflow >= 3:
        h ^= key[i + 2] << 16
    if overflow >= 2:
        h ^= key[i + 1] << 8
    if overflow >= 1:
        h ^= key[i]
    if overflow > 0:
        h = wrapping_mul(h, M)
    
    AFTER_OVERFLOW = h

    h ^= h >> R
    h = wrapping_mul(h, M)
    h ^= h >> R
    return h


# don't need hash_inverse?


def hash32(key: list[int], seed: int) -> int:
    h = hash64(key, seed)
    return h >> 32


def test_hash():
    assert 0 == hash64(bytes("", "UTF-8"), 0)
    assert 0xC26E8BC196329B0F == hash64(bytes("", "UTF-8"), 10)
    assert 0xA14E8DFA2CD117E2 == hash64(bytes("lua", "UTF-8"), 0)
    assert 0x069A33456AAD3042 == hash64(bytes("twitch_intervention", "UTF-8"), 0)


# test_hash()

def get_hash(string: str, seed: int) -> int:
    key = [ord(char) for char in string]
    return hash64(key, seed)

def get_short_hash(string: str, seed: int) -> int:
    key = [ord(char) for char in string]
    return hash32(key, seed)




"""
s = "deadbeef"
s_int = int(s, 16)

expected_bytes = struct.pack("<Q", s_int)
print(expected_bytes.hex())

# verify

result_int, = struct.unpack("<Q", expected_bytes)
print(result_int)
"""



data = "hashcat"
seed = 0x0

# s = bytes.fromhex(data)[::-1].decode("utf-8")

# s = "deadbeef"

h = get_hash(data, seed)

pretty = f"{h:016x}:{seed:016x}:{data} INITIAL: {INITIAL:016x} B4OVERFLOW: {BEFORE_OVERFLOW:016x} overflow: {OVERFLOW} AFTER_OVERFLOW = {AFTER_OVERFLOW:016x}"

print(pretty)

"""
data = "4142434445"
s = bytes.fromhex(data).decode("utf-8")
print(s)
"""

# print(f"{wrapping_mul(0xC6A4A7935BD1E995, 0x773e34d9d52c9ef8):016x}")

reverse = "69686361 6d657665 5f746e65 6c6c6f68 00005f79"
r_s = reverse.split(" ")
r_s = [bytearray.fromhex(s) for s in r_s]
for x in r_s:
    x.reverse()
fnl = bytearray()
for x in r_s:
    fnl += x

print(fnl.decode("utf-8"))
