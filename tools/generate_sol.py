"""Génère la texture de sol en dalles vinyles (« lino » de bâtiment public).

Dalles de 30 cm mouchetées, joints, rayures et traces d'usure. La texture est
raccordable (tuilable) et presque grise : chaque pièce la teinte avec sa couleur
(scripts/world/decor.gd).

    python tools/generate_sol.py
"""
import os

import numpy as np
from PIL import Image

ROOT = os.environ.get("IMAJAM_ROOT", os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "assets", "textures", "sol_lino")
SIZE = 1024
TILES = 8  # 8 dalles de 30 cm : la texture couvre 2,40 m
rng = np.random.default_rng(12)


def tile_blur(a, radius):
    """Flou gaussien circulaire (par FFT) : la texture reste raccordable."""
    f = np.fft.fftfreq(SIZE)
    k = np.exp(-2 * (np.pi * radius) ** 2 * (f[:, None] ** 2 + f[None, :] ** 2))
    return np.real(np.fft.ifft2(np.fft.fft2(a) * k))


def noise(scale, amp):
    return tile_blur(rng.standard_normal((SIZE, SIZE)), scale) * amp


def main():
    os.makedirs(OUT, exist_ok=True)
    t = SIZE // TILES
    y, x = np.mgrid[0:SIZE, 0:SIZE]

    # teinte de base par dalle (légèrement différente d'une dalle à l'autre)
    tile_tone = rng.uniform(-0.035, 0.035, (TILES, TILES))
    tone = tile_tone[y // t, x // t]

    # mouchetures (dalles « VCT ») : petites taches claires et sombres
    fleck = np.zeros((SIZE, SIZE))
    for _ in range(9000):
        cx, cy = rng.integers(0, SIZE, 2)
        r = rng.uniform(0.8, 2.6)
        v = rng.choice([-0.16, -0.09, 0.08, 0.12])
        x0, x1 = int(cx - r - 1), int(cx + r + 2)
        y0, y1 = int(cy - r - 1), int(cy + r + 2)
        yy, xx = np.mgrid[y0:y1, x0:x1]
        m = ((xx - cx) ** 2 + ((yy - cy) * rng.uniform(0.6, 1.4)) ** 2) <= r * r
        fleck[yy[m] % SIZE, xx[m] % SIZE] = v
    fleck = tile_blur(fleck, 0.6)

    # usure : zones plus sombres et plus mates, grandes taches douces
    wear = noise(60, 1.0)
    wear = (wear - wear.min()) / (wear.max() - wear.min())
    grime = noise(18, 0.05) + (wear - 0.5) * 0.09

    # rayures fines
    scratch = np.zeros((SIZE, SIZE))
    for _ in range(80):
        x0, y0 = rng.uniform(0, SIZE, 2)
        ang = rng.uniform(0, np.pi)
        ln = rng.uniform(20, 140)
        for s in np.linspace(0, ln, int(ln * 2)):
            px = int(x0 + np.cos(ang) * s) % SIZE
            py = int(y0 + np.sin(ang) * s) % SIZE
            scratch[py, px] = 1.0
    scratch = tile_blur(scratch, 0.5)

    # joints entre dalles
    gx = np.minimum(x % t, t - 1 - x % t)
    gy = np.minimum(y % t, t - 1 - y % t)
    g = np.minimum(gx, gy)
    joint = np.clip(1.0 - g / 1.6, 0.0, 1.0)

    base = 0.74 + tone + fleck + grime + noise(1.2, 0.012)
    base = base * (1.0 - joint * 0.55) - scratch * 0.035
    base = np.clip(base, 0.0, 1.0)
    rgb = np.stack([base * 1.0, base * 0.995, base * 0.98], -1)
    Image.fromarray((rgb * 255).astype(np.uint8)).save(os.path.join(OUT, "lino_couleur.jpg"), quality=92)

    # relief : joints en creux, légère ondulation, rayures
    h = -joint * 1.0 - scratch * 0.25 + noise(3, 0.04)
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 2.0
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 2.0
    n = np.stack([-dx, -dy, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8)).save(os.path.join(OUT, "lino_normal.png"))

    # rugosité : cire brillante, usure et joints plus mats
    rough = np.clip(0.42 + wear * 0.25 + joint * 0.35 + scratch * 0.2 + noise(4, 0.03), 0, 1)
    Image.fromarray((rough * 255).astype(np.uint8)).save(os.path.join(OUT, "lino_rugosite.jpg"), quality=92)
    print("texture écrite dans", OUT)


if __name__ == "__main__":
    main()
