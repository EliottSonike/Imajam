"""Allège un modèle .glb téléchargé (Sketchfab…) : réduit ses textures.

    python tools/optimize_glb.py entree.glb sortie.glb [taille_max=1024]

Les textures plus grandes que taille_max sont réduites ; celles sans transparence
sont réencodées en JPEG. La géométrie n'est pas touchée.
"""
import io
import json
import struct
import sys

from PIL import Image


def read_glb(path):
    data = open(path, "rb").read()
    magic, version, length = struct.unpack("<III", data[:12])
    assert magic == 0x46546C67, "pas un fichier glb"
    off, gltf, binary = 12, None, b""
    while off < length:
        clen, ctype = struct.unpack("<II", data[off:off + 8])
        chunk = data[off + 8:off + 8 + clen]
        if ctype == 0x4E4F534A:
            gltf = json.loads(chunk)
        elif ctype == 0x004E4942:
            binary = chunk
        off += 8 + clen
    return gltf, binary


def write_glb(path, gltf, binary):
    js = json.dumps(gltf, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    binary += b"\0" * ((4 - len(binary) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(binary)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        f.write(struct.pack("<II", len(binary), 0x004E4942) + binary)


def optimize(src, dst, max_size=1024):
    gltf, binary = read_glb(src)
    views = gltf.get("bufferViews", [])
    blobs = [binary[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]] for v in views]
    for img in gltf.get("images", []):
        if "bufferView" not in img:
            continue
        i = img["bufferView"]
        im = Image.open(io.BytesIO(blobs[i]))
        im.load()
        has_alpha = im.mode in ("RGBA", "LA") and im.getchannel("A").getextrema()[0] < 250
        if max(im.size) > max_size:
            k = max_size / max(im.size)
            im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
        out = io.BytesIO()
        if has_alpha:
            im.save(out, "PNG", optimize=True)
            img["mimeType"] = "image/png"
        else:
            im.convert("RGB").save(out, "JPEG", quality=88, optimize=True)
            img["mimeType"] = "image/jpeg"
        if len(out.getvalue()) < len(blobs[i]):
            blobs[i] = out.getvalue()
        else:
            img["mimeType"] = "image/png" if blobs[i][:4] == b"\x89PNG" else "image/jpeg"
    new = bytearray()
    for v, b in zip(views, blobs):
        new += b"\0" * ((4 - len(new) % 4) % 4)
        v["byteOffset"] = len(new)
        v["byteLength"] = len(b)
        new += b
    if gltf.get("buffers"):
        gltf["buffers"][0]["byteLength"] = len(new)
    write_glb(dst, gltf, bytes(new))


if __name__ == "__main__":
    optimize(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 1024)
