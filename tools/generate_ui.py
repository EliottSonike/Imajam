"""Génère les textures de l'interface (thème « poste de garde »).

Toile d'uniforme surpiquée, poche de chemise, porte-bloc, boutons en ruban Dymo,
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


NAVY = (31, 39, 57)
FAB = 96  # tuile centrale des 9-patch de tissu (multiple des motifs : sergé 4 px, points 8 px)


def twill(w, h, base, seed, amp=7):
    """Sergé : fines côtes diagonales + grain du fil, raccordé tous les FAB pixels."""
    grain = tile_noise(seed, 9, size=FAB // 2)
    slub = tile_noise(seed + 1, 30, blur=3, size=FAB // 2)
    img = Image.new("RGB", (w, h))
    px = img.load()
    gp, sp = grain.load(), slub.load()
    half = FAB // 2
    for y in range(h):
        for x in range(w):
            rib = math.sin((x + y) * math.pi / 2.0) * amp * 0.6 + (amp * 0.5 if (x + y) % 4 == 0 else 0)
            n = (gp[x % half, y % half] - 128) * 0.5 + (sp[x % half, y % half] - 128) * 0.12 + rib
            px[x, y] = tuple(max(0, min(255, int(c + n))) for c in base)
    return img


def stitches(img, inset, thread, dash=5, period=8, sides=(True, True, True, True), top=None, bottom=None):
    """Surpiqûre : petits traits de fil clair avec leur ombre, à `inset` px du bord."""
    w, h = img.size
    d = ImageDraw.Draw(img)
    shadow = tuple(int(c * 0.45) for c in NAVY)
    t = inset if top is None else top
    b = h - 1 - inset if bottom is None else bottom
    left, right = inset, w - 1 - inset
    if sides[0]:
        for x in range(left, right + 1):
            if x % period < dash:
                d.point((x, t + 1), fill=shadow)
                d.point((x, t), fill=thread)
    if sides[2]:
        for x in range(left, right + 1):
            if x % period < dash:
                d.point((x, b + 1), fill=shadow)
                d.point((x, b), fill=thread)
    for x0, on in ((left, sides[3]), (right, sides[1])):
        if not on:
            continue
        for y in range(t, b + 1):
            if y % period < dash:
                d.point((x0 + 1, y), fill=shadow)
                d.point((x0, y), fill=thread)


def hem(img, depth=9):
    """Ourlet : bord replié un peu plus sombre, pli éclairé côté intérieur."""
    w, h = img.size
    px = img.load()
    for y in range(h):
        for x in range(w):
            e = min(x, y, w - 1 - x, h - 1 - y)
            if e < depth:
                k = 0.86 if e > 0 else 0.45
                if e == depth - 1:
                    k = 1.12
                px[x, y] = tuple(int(min(255, c * k)) for c in px[x, y])
            elif e == depth:
                px[x, y] = tuple(int(c * 0.78) for c in px[x, y])


def round_alpha(img, r):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.size[0] - 1, img.size[1] - 1), r, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def fabric(name, thread, seed):
    m = 28
    w = h = m * 2 + FAB
    img = twill(w, h, NAVY, seed)
    hem(img)
    stitches(img, 13, thread)
    stitches(img, 17, tuple(int(c * 0.85) for c in thread))
    round_alpha(img, 5).save(os.path.join(OUT, name))


def pocket():
    """Poche de chemise d'uniforme : rabat en haut (le bouton est posé à part)."""
    top, m = 76, 28
    w, h = m * 2 + FAB, top + 14 + m + FAB  # marge haute du 9-patch = top + 14 (rabat + surpiqûres)
    img = twill(w, h, NAVY, 21)
    hem(img)
    stitches(img, 13, (128, 138, 160), top=top + 4)
    stitches(img, 17, (110, 118, 138), top=top + 8)
    flap = twill(w, top - 6, tuple(int(c * 1.1) for c in NAVY), 22)
    hem(flap, 7)
    stitches(flap, 11, (140, 150, 172))
    px = img.load()
    for y in range(top - 6, top + 6):  # ombre portée du rabat
        k = 0.4 + 0.6 * (y - (top - 6)) / 12.0
        for x in range(w):
            px[x, y] = tuple(int(c * k) for c in px[x, y])
    img.paste(flap, (0, 0))
    round_alpha(img, 6).save(os.path.join(OUT, "poche.png"))


def button():
    s = 44
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((5, 7, s - 3, s - 1), fill=(0, 0, 0, 110))
    for i in range(18, 0, -1):
        v = int(22 + (18 - i) * 1.6)
        d.ellipse((s / 2 - 2 - i, s / 2 - 2 - i, s / 2 - 2 + i, s / 2 - 2 + i), fill=(v, v + 3, v + 8, 255))
    d.ellipse((7, 7, s - 11, s - 11), outline=(70, 76, 88, 255), width=2)
    for dx, dy in ((-4, -4), (4, -4), (-4, 4), (4, 4)):
        cx, cy = s / 2 - 2 + dx, s / 2 - 2 + dy
        d.ellipse((cx - 1.8, cy - 1.8, cx + 1.8, cy + 1.8), fill=(8, 9, 12, 255))
    d.line((s / 2 - 6, s / 2 - 6, s / 2 + 2, s / 2 + 2), fill=(150, 156, 170, 255), width=1)  # fil
    d.line((s / 2 + 2, s / 2 - 6, s / 2 - 6, s / 2 + 2), fill=(150, 156, 170, 255), width=1)
    img.save(os.path.join(OUT, "bouton.png"))


def clipboard():
    """Porte-bloc en isorel : fibres, coins arrondis."""
    m = 30
    w = h = m * 2 + FAB
    rnd = random.Random(31)
    base = (118, 84, 52)
    fib = tile_noise(31, 14, size=FAB // 2)
    img = Image.new("RGB", (w, h))
    px, fp = img.load(), fib.load()
    half = FAB // 2
    for y in range(h):
        for x in range(w):
            n = (fp[x % half, (y // 2) % half] - 128) * 0.6 + (fp[(x * 3) % half, y % half] - 128) * 0.25
            px[x, y] = tuple(max(0, min(255, int(c + n))) for c in base)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, w - 1, h - 1), 14, outline=(60, 40, 22), width=2)
    d.rounded_rectangle((2, 2, w - 3, h - 3), 12, outline=(150, 112, 74), width=1)
    round_alpha(img, 14).save(os.path.join(OUT, "porte_bloc.png"))


def clip():
    w, h = 220, 70
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((14, 22, w - 10, h - 2), 8, fill=(0, 0, 0, 90))  # ombre
    for y in range(18, h - 8):  # plaque de la pince
        t = (y - 18) / (h - 26)
        v = int(205 - 90 * t + 30 * math.exp(-((t - 0.2) / 0.1) ** 2))
        d.line((8, y, w - 16, y), fill=(v, v, v + 4, 255))
    d.rounded_rectangle((8, 18, w - 16, h - 8), 8, outline=(60, 62, 66, 255), width=2)
    d.rectangle((30, 8, w - 38, 26), fill=(150, 152, 158, 255), outline=(55, 57, 60, 255), width=2)  # levier
    d.line((34, 12, w - 42, 12), fill=(225, 226, 230, 255))
    for x in (28, w - 36):  # rivets
        d.ellipse((x - 5, h - 26, x + 5, h - 16), fill=(90, 92, 96, 255), outline=(40, 40, 44, 255))
    img.save(os.path.join(OUT, "pince.png"))


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


def _icon_canvas():
    s = 128
    return Image.new("RGBA", (s * 2, s * 2), (0, 0, 0, 0)), 2  # dessiné en 2x puis réduit (anticrénelage)


def _finish_icon(img, name):
    img = img.resize((128, 128), Image.LANCZOS)
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    a = img.split()[3].point(lambda v: int(v * 0.55))
    shadow.putalpha(a.filter(ImageFilter.GaussianBlur(2.5)))
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.alpha_composite(shadow, (3, 4))
    out.alpha_composite(img)
    out.save(os.path.join(OUT, name))


def icon_gun():
    img, k = _icon_canvas()
    d = ImageDraw.Draw(img)
    S = lambda pts: [(x * k, y * k) for x, y in pts]
    ink = (12, 13, 15, 255)
    d.polygon(S([(70, 56), (98, 56), (108, 108), (104, 112), (84, 114), (80, 110)]), fill=(40, 34, 30, 255), outline=ink, width=4)  # crosse
    for i in range(5):
        y = 70 + i * 8
        d.line(S([(80 + i * 1.5, y), (100 + i * 1.6, y - 2)]), fill=(64, 56, 48, 255), width=3)
    d.arc([60 * k, 46 * k, 84 * k, 78 * k], 0, 180, fill=ink, width=7)  # pontet
    d.line(S([(70, 56), (66, 68)]), fill=ink, width=7)  # détente
    d.rounded_rectangle(S([(10, 32), (110, 56)]), 4 * k, fill=(70, 74, 80, 255), outline=ink, width=4)  # culasse
    d.rectangle(S([(10, 52), (64, 60)]), fill=(52, 55, 60, 255), outline=ink, width=3)  # carcasse
    for i in range(6):
        x = 88 + i * 3.5
        d.line(S([(x, 35), (x, 53)]), fill=(48, 50, 55, 255), width=3)  # stries
    d.line(S([(14, 37), (104, 37)]), fill=(140, 146, 154, 255), width=3)  # reflet
    d.rectangle(S([(10, 28), (16, 32)]), fill=ink)  # guidon
    _finish_icon(img, "objet_pistolet.png")


def icon_taser():
    img, k = _icon_canvas()
    d = ImageDraw.Draw(img)
    S = lambda pts: [(x * k, y * k) for x, y in pts]
    ink = (12, 13, 15, 255)
    yel, yel_d = (236, 190, 36, 255), (190, 146, 20, 255)
    d.polygon(S([(42, 66), (66, 66), (72, 112), (46, 114)]), fill=yel_d, outline=ink, width=4)  # poignée
    for i in range(4):
        d.line(S([(48, 76 + i * 9), (68, 75 + i * 9)]), fill=(30, 28, 20, 255), width=4)
    d.rounded_rectangle(S([(14, 40), (96, 70)]), 8 * k, fill=yel, outline=ink, width=4)  # corps
    d.line(S([(22, 46), (88, 46)]), fill=(255, 236, 150, 255), width=3)
    d.rounded_rectangle(S([(90, 36), (118, 74)]), 5 * k, fill=(28, 30, 34, 255), outline=ink, width=4)  # tête
    for y in (46, 62):
        d.rectangle(S([(116, y), (122, y + 5)]), fill=(90, 170, 255, 255), outline=ink, width=2)  # électrodes
    d.line(S([(60, 70), (56, 82)]), fill=ink, width=6)  # détente
    _finish_icon(img, "objet_taser.png")


def icon_meds():
    img, k = _icon_canvas()
    d = ImageDraw.Draw(img)
    S = lambda pts: [(x * k, y * k) for x, y in pts]
    ink = (20, 22, 26, 255)
    d.polygon(S([(18, 48), (82, 38), (112, 52), (48, 64)]), fill=(250, 250, 246, 255), outline=ink, width=4)  # dessus
    d.polygon(S([(18, 48), (48, 64), (48, 106), (18, 88)]), fill=(206, 208, 206, 255), outline=ink, width=4)  # côté
    d.polygon(S([(48, 64), (112, 52), (112, 92), (48, 106)]), fill=(232, 233, 230, 255), outline=ink, width=4)  # face
    red = (206, 30, 30, 255)
    d.polygon(S([(74, 66), (86, 64), (86, 72), (94, 70), (94, 80), (86, 82), (86, 90), (74, 92), (74, 84), (66, 86), (66, 76), (74, 74)]), fill=red)
    d.polygon(S([(56, 46), (64, 44), (72, 47), (64, 49)]), fill=red)
    _finish_icon(img, "objet_medicaments.png")


def main():
    os.makedirs(OUT, exist_ok=True)
    fabric("toile.png", (128, 138, 160), 3)
    fabric("toile_alerte.png", (196, 70, 58), 8)
    pocket()
    button()
    clipboard()
    clip()
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
    icon_gun()
    icon_taser()
    icon_meds()
    print("textures écrites dans", OUT)


if __name__ == "__main__":
    main()
