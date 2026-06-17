#!/usr/bin/env python3
"""
Zero out DT_VERNEED/DT_VERNEEDNUM/DT_VERSYM in the ELF DYNAMIC segment.

objcopy only removes sections from the section header table; glibc uses
the DYNAMIC program header (PT_DYNAMIC) to find these entries at runtime.
This script patches the DYNAMIC segment directly, so glibc skips all
symbol-version checking, allowing the binary to load libcurl.so.4
(OpenSSL) in place of libcurl-gnutls.so.4 (GnuTLS). Idempotent.
"""
import struct
import sys


def patch(path: str) -> None:
    with open(path, "rb") as f:
        data = bytearray(f.read())

    if data[:4] != b"\x7fELF" or data[4] != 2:
        return  # not a 64-bit ELF

    endian = "<" if data[5] == 1 else ">"
    e_phoff = struct.unpack_from(endian + "Q", data, 32)[0]
    e_phentsize = struct.unpack_from(endian + "H", data, 54)[0]
    e_phnum = struct.unpack_from(endian + "H", data, 56)[0]

    PT_DYNAMIC = 2
    DT_NULL = 0
    TARGETS = {
        0x6FFFFFF0,  # DT_VERSYM
        0x6FFFFFFE,  # DT_VERNEED
        0x6FFFFFFF,  # DT_VERNEEDNUM
    }

    for i in range(e_phnum):
        ph = e_phoff + i * e_phentsize
        if struct.unpack_from(endian + "I", data, ph)[0] != PT_DYNAMIC:
            continue
        offset = struct.unpack_from(endian + "Q", data, ph + 8)[0]
        size = struct.unpack_from(endian + "Q", data, ph + 32)[0]
        pos = offset
        while pos + 16 <= offset + size:
            tag = struct.unpack_from(endian + "Q", data, pos)[0]
            if tag == DT_NULL:
                break
            if tag in TARGETS:
                struct.pack_into(endian + "QQ", data, pos, 0, 0)
            pos += 16
        break

    with open(path, "wb") as f:
        f.write(bytes(data))


if __name__ == "__main__":
    patch(sys.argv[1])
