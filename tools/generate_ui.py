"""Génère les textures de l'interface (thème « poste de garde »).

Plaques d'acier peintes et vissées, boutons en ruban Dymo, bande de danger,
curseurs et interrupteurs. Toutes les images sont des 9-patch utilisées par
scripts/ui/ui_theme.gd (StyleBoxTexture).

    python tools/generate_ui.py
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.environ.get("IMAJAM_ROOT", os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "assets", "ui", "theme")

PAINT = (44, 49, 44)
TILE = 64


def tile_noise(seed, amp, blur=0.0, size=TILE):
    """Bruit qui se répète sans couture sur une tuile carrée."""
    rnd = random.Random(seed)
    img = Image.new("L", (size, size))
    img.putdata([128 + int(rnd.gauss(0, amp)) for _ in range(size * size)])
    if blur:
        big = Image.new("L", (size * 3, size * 3))
        for i in range(3):
            for j in range(3):
                big.paste(img, (i * size, j * size))
        big = big.filter(ImageFilter.GaussianBlur(blur))
        img = big.crop((size, size, size * 2, size * 2))
    return img


def painted_steel(w, h, seed=1):
    fine = tile_noise(seed, 7)
    mottle = tile_noise(seed + 1, 40, blur=6)
    img = Image.new("RGB", (w, h))
    px = img.load()
    fp, mp = fine.load(), mottle.load()
    for y in range(h):
        for x in range(w):
            n = (fp[x % TILE, y % TILE] - 128) + (mp[x % TILE, y % TILE] - 128) * 0.35
            px[x, y] = tuple(max(0, min(255, int(c + n))) for c in PAINT)
    return img


def screw(draw, cx, cy, r, rnd):
    for i in range(r + 2, 0, -1):  # ombre portée
        draw.ellipse((cx - i + 1, cy - i + 2, cx + i + 1, cy + i + 2), fill=(14, 16, 14))
    for i in range(r, 0, -1):
        t = i / r
        v = int(150 - 70 * t)
        draw.ellipse((cx - i - (1 - t), cy - i - (1 - t), cx + i - (1 - t), cy + i - (1 - t)), fill=(v, v + 2, v - 4))
    a = rnd.uniform(0, math.pi)
    dx, dy = math.cos(a) * (r - 1.5), math.sin(a) * (r - 1.5)
    draw.line((cx - dx, cy - dy, cx + dx, cy + dy), fill=(30, 32, 30), width=2)
    draw.line((cx - dx + 0.6, cy - dy + 1, cx + dx + 0.6, cy + dy + 1), fill=(150, 152, 145), width=1)


def bevel(img, light, dark, outer=(9, 10, 9)):
    w, h = img.size
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, w - 1, h - 1), outline=outer)
    d.line((1, 1, w - 2, 1), fill=light)
    d.line((1, 1, 1, h - 2), fill=light)
    d.line((1, h - 2, w - 2, h - 2), fill=dark)
    d.line((w - 2, 1, w - 2, h - 2), fill=dark)
    d.line((2, h - 3, w - 3, h - 3), fill=tuple(int(c * 0.8) for c in PAINT))
    d.line((w - 3, 2, w - 3, h - 3), fill=tuple(int(c * 0.8) for c in PAINT))


def chips(img, margin, seed):
    """Éclats de peinture et rayures dans les coins (le métal apparaît)."""
    rnd = random.Random(seed)
    w, h = img.size
    d = ImageDraw.Draw(img)
    for cx, cy in ((0, 0), (w, 0), (0, h), (w, h)):
        for _ in range(16):
            x = abs(cx - rnd.uniform(2, margin - 4))
            y = abs(cy - rnd.uniform(2, margin - 4))
            if 6 < min(x, w - x) and 6 < min(y, h - y) and rnd.random() < 0.6:
                continue  # les éclats restent près du bord
            r = rnd.uniform(0.4, 1.6)
            v = rnd.randint(85, 125)
            d.ellipse((x - r, y - r * 0.7, x + r, y + r * 0.7), fill=(v, v + 2, v - 6))
        for _ in range(3):
            x0, y0 = abs(cx - rnd.uniform(6, margin)), abs(cy - rnd.uniform(6, margin))
            a = rnd.uniform(0, math.pi)
            ln = rnd.uniform(3, 8)
            d.line((x0, y0, x0 + math.cos(a) * ln, y0 + math.sin(a) * ln), fill=(78, 84, 76), width=1)


def plate():
    w = h = 32 * 2 + TILE
    img = painted_steel(w, h, seed=3)
    bevel(img, (88, 95, 86), (22, 25, 22))
    chips(img, 32, seed=4)
    d = ImageDraw.Draw(img)
    rnd = random.Random(5)
    for cx, cy in ((14, 14), (w - 15, 14), (14, h - 15), (w - 15, h - 15)):
        screw(d, cx, cy, 5, rnd)
    img.save(os.path.join(OUT, "plaque.png"))


def hazard_plate():
    m = 24
    w = h = m * 2 + 48
    img = painted_steel(w, h, seed=8)
    px = img.load()
    for y in range(h):
        for x in range(w):
            edge = min(x, y, w - 1 - x, h - 1 - y)
            if 3 <= edge < 15:
                yellow = ((x + y) // 8) % 2 == 0
                base = (216, 168, 34) if yellow else (22, 22, 20)
                r, g, b = px[x, y]
                n = (r - PAINT[0])
                px[x, y] = tuple(max(0, min(255, c + n)) for c in base)
    bevel(img, (110, 104, 70), (20, 20, 18))
    d = ImageDraw.Draw(img)
    d.rectangle((15, 15, w - 16, h - 16), outline=(14, 15, 14))
    chips(img, m, seed=9)
    img.save(os.path.join(OUT, "plaque_danger.png"))


def dymo(name, base, seed):
    """Ruban Dymo : bourrelets en haut et en bas, bouts coupés aux ciseaux."""
    w, h = 112, 44
    rnd = random.Random(seed)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    noise = tile_noise(seed, 5)
    cut_l = [rnd.uniform(0, 3) for _ in range(h)]
    cut_r = [rnd.uniform(0, 3) for _ in range(h)]
    slope = rnd.uniform(-3, 3)
    for y in range(h):
        sheen = 1.0 + 0.16 * math.exp(-((y - h * 0.3) / (h * 0.16)) ** 2) - 0.12 * (y / h)
        left = 2 + cut_l[y // 4 * 4] + slope * (y / h - 0.5)
        right = w - 3 - cut_r[y // 4 * 4] + slope * (0.5 - y / h)
        for x in range(w):
            if x < left or x > right:
                continue
            n = noise.getpixel((x % TILE, y % TILE)) - 128
            c = [base[i] * sheen + n for i in range(3)]
            if y in (3, h - 4):  # bourrelet
                c = [v + 24 for v in c]
            if y in (4, h - 3):
                c = [v - 18 for v in c]
            if y < 2 or y > h - 3:
                a = 0
            else:
                a = 255
            px[x, y] = tuple(max(0, min(255, int(v))) for v in c) + (a,)
    img.save(os.path.join(OUT, name))


def separator():
    img = Image.new("RGBA", (8, 2))
    for x in range(8):
        img.putpixel((x, 0), (8, 9, 8, 210))
        img.putpixel((x, 1), (110, 116, 104, 110))
    img.save(os.path.join(OUT, "separateur.png"))


def slot():
    w, h = 24, 12
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, w - 1, h - 1), fill=(12, 13, 12, 255))
    d.line((1, 1, w - 2, 1), fill=(4, 4, 4, 255))
    d.line((1, h - 1, w - 2, h - 1), fill=(90, 96, 86, 255))
    img.save(os.path.join(OUT, "rainure.png"))


def fader(name, line):
    w, h = 20, 30
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((2, 3, w - 1, h - 1), fill=(0, 0, 0, 120))
    for y in range(1, h - 2):
        v = int(58 - 22 * (y / h)) + (8 if y % 4 == 0 else 0)
        d.line((1, y, w - 3, y), fill=(v, v, v - 2, 255))
    d.rectangle((1, 1, w - 3, h - 3), outline=(10, 10, 10, 255))
    d.line((2, 2, w - 4, 2), fill=(110, 110, 104, 255))
    d.line((3, h // 2 - 1, w - 5, h // 2 - 1), fill=line + (255,), width=2)
    img.save(os.path.join(OUT, name))


def toggle(name, on):
    w, h = 54, 26
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 2, 38, h - 3), 3, fill=(14, 15, 14, 255), outline=(70, 75, 68, 255))
    kx = 20 if on else 2
    d.rectangle((kx, 4, kx + 16, h - 5), fill=(120, 122, 116, 255), outline=(30, 31, 30, 255))
    for i in range(3):
        d.line((kx + 5 + i * 3, 7, kx + 5 + i * 3, h - 8), fill=(80, 82, 78, 255))
    lamp = (240, 170, 50) if on else (70, 52, 30)
    if on:
        d.ellipse((40, 5, 53, 18), fill=(240, 170, 50, 70))
    d.ellipse((42, 7, 51, 16), fill=lamp + (255,), outline=(20, 18, 14, 255))
    d.point((45, 9), fill=(255, 240, 200, 255) if on else (110, 90, 60, 255))
    img.save(os.path.join(OUT, name))


def main():
    os.makedirs(OUT, exist_ok=True)
    plate()
    hazard_plate()
    dymo("dymo.png", (22, 22, 22), 11)
    dymo("dymo_survol.png", (148, 30, 26), 12)
    dymo("dymo_appui.png", (110, 22, 20), 13)
    dymo("dymo_inactif.png", (66, 68, 64), 14)
    separator()
    slot()
    fader("curseur.png", (210, 200, 175))
    fader("curseur_survol.png", (240, 170, 50))
    toggle("interrupteur_on.png", True)
    toggle("interrupteur_off.png", False)
    print("textures écrites dans", OUT)


if __name__ == "__main__":
    main()
