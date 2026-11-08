"""Textures des traces d'eau (décalques) : empreinte de chaussure, flaque, goutte.

Chaque texture a sa version « orm » (rugosité très basse = mouillé).

    python tools/generate_traces.py
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.environ.get("IMAJAM_ROOT", os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "assets", "textures", "traces")
rng = np.random.default_rng(5)


def save(name, alpha, darkness=0.35):
    """alpha : masque 0..1. Couleur sombre (sol mouillé), et ORM avec rugosité basse."""
    a = np.clip(alpha, 0, 1)
    h, w = a.shape
    col = np.zeros((h, w, 4), np.uint8)
    col[..., :3] = 18
    col[..., 3] = (a * 255 * darkness / 0.35).clip(0, 255).astype(np.uint8)
    Image.fromarray(col, "RGBA").save(os.path.join(OUT, name + ".png"))
    orm = np.zeros((h, w, 4), np.uint8)
    orm[..., 0] = 255  # occlusion
    orm[..., 1] = 18  # rugosité : très brillant
    orm[..., 2] = 0
    orm[..., 3] = (a * 255).astype(np.uint8)
    Image.fromarray(orm, "RGBA").save(os.path.join(OUT, name + "_orm.png"))


def speckle(shape, amount):
    n = rng.random(shape)
    return np.where(n < amount, 0.0, 1.0)


def footprint():
    w, h = 96, 240
    img = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(img)
    d.ellipse((8, 4, w - 8, 128), fill=255)  # avant du pied
    d.rounded_rectangle((20, 100, w - 22, 170), 20, fill=200)  # cambrure (moins marquée)
    d.ellipse((14, 160, w - 14, h - 6), fill=255)  # talon
    for y in range(14, 120, 12):  # crampons de la semelle
        d.line((14, y, w - 14, y + 4), fill=90, width=4)
    for y in range(172, h - 10, 12):
        d.line((20, y, w - 20, y), fill=90, width=4)
    a = np.asarray(img.filter(ImageFilter.GaussianBlur(2.2))) / 255.0
    a *= speckle(a.shape, 0.18) * 0.35 + 0.65
    save("trace_pas", a)


def puddle():
    s = 256
    y, x = np.mgrid[0:s, 0:s] / s - 0.5
    ang = np.arctan2(y, x)
    r = np.hypot(x, y)
    edge = 0.33 + 0.05 * np.sin(ang * 3 + 1) + 0.035 * np.sin(ang * 7 + 2) + 0.02 * np.sin(ang * 13)
    a = np.clip((edge - r) / 0.03, 0, 1)
    a = np.asarray(Image.fromarray((a * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3))) / 255.0
    save("flaque", a, 0.28)


def drop():
    s = 64
    y, x = np.mgrid[0:s, 0:s] / s - 0.5
    r = np.hypot(x, y * 1.2)
    a = np.clip((0.32 - r) / 0.08, 0, 1)
    save("goutte", a, 0.3)


def streak():
    w, h = 32, 256
    y, x = np.mgrid[0:h, 0:w]
    a = np.clip(1 - np.abs(x - w / 2) / (w / 2), 0, 1) ** 1.5
    a *= 0.6 + 0.4 * np.sin(y / 9.0) ** 2
    a *= speckle(a.shape, 0.25) * 0.4 + 0.6
    save("trace_roue", a, 0.3)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    footprint()
    puddle()
    drop()
    streak()
    print("textures écrites dans", OUT)
