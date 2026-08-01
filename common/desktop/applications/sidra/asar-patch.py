#!/usr/bin/env python3
"""Patch dist/integrations/mpris/index.js inside a Sidra app.asar so that
xesam:url falls back to getShareUrl() (catalogId/globalId) when the item has
no share URL attribute. Rewrites the asar in place.
"""
import hashlib
import json
import struct
import sys

TARGET = "dist/integrations/mpris/index.js"

OLD = b"""    if (payload.url != null) {
        metadata['xesam:url'] = new Variant('s', payload.url);
    }
"""

NEW = b"""    const shareUrl = player_1.getShareUrl(payload);
    if (shareUrl != null) {
        metadata['xesam:url'] = new Variant('s', shareUrl);
    }
"""

BLOCK_SIZE = 4 * 1024 * 1024


def integrity(data: bytes) -> dict:
    blocks = []
    for off in range(0, len(data), BLOCK_SIZE):
        blocks.append(hashlib.sha256(data[off : off + BLOCK_SIZE]).hexdigest())
    if not blocks:
        blocks.append(hashlib.sha256(b"").hexdigest())
    return {
        "algorithm": "SHA256",
        "hash": hashlib.sha256(data).hexdigest(),
        "blockSize": BLOCK_SIZE,
        "blocks": blocks,
    }


def main() -> None:
    path = sys.argv[1]
    data = open(path, "rb").read()
    size = struct.unpack("<I", data[4:8])[0]
    json_len = struct.unpack("<I", data[12:16])[0]
    header = json.loads(data[16 : 16 + json_len])
    # file data starts after the header pickle (Chromium: 8 + header size)
    base = 8 + size

    # collect regular files in their on-disk order
    entries = []

    def walk(files, prefix=""):
        for name, meta in files.items():
            p = prefix + name
            if "files" in meta:
                walk(meta["files"], p + "/")
            elif "link" not in meta and "unpacked" not in meta:
                off = int(meta["offset"])
                size = meta["size"]
                entries.append((p, meta, data[base + off : base + off + size]))

    walk(header["files"])

    patched = False
    for i, (path_, meta, content) in enumerate(entries):
        if path_ == TARGET:
            assert OLD in content, "expected xesam:url block not found"
            content = content.replace(OLD, NEW)
            meta["size"] = len(content)
            meta["integrity"] = integrity(content)
            entries[i] = (path_, meta, content)
            patched = True

    assert patched, f"target {TARGET} not found"

    # assign new offsets in the original on-disk order
    entries.sort(key=lambda e: int(e[1]["offset"]))
    cursor = 0
    for _, meta, content in entries:
        meta["offset"] = str(cursor)
        cursor += len(content)

    json_bytes = json.dumps(header, separators=(",", ":")).encode()
    header_payload = struct.pack("<i", len(json_bytes)) + json_bytes
    # Chromium's Pickle expects the payload padded up to the aligned size
    payload_size = (len(header_payload) + 3) & ~3
    header_payload += b"\x00" * (payload_size - len(header_payload))
    header_buf = struct.pack("<I", payload_size) + header_payload
    size_buf = struct.pack("<I", 4) + struct.pack("<I", len(header_buf))

    with open(path, "wb") as f:
        f.write(size_buf)
        f.write(header_buf)
        for _, _, content in entries:
            f.write(content)

    print(f"patched {TARGET}: {len(OLD)} -> {len(NEW)} bytes")


if __name__ == "__main__":
    main()
