import math, os, random, re
## Génère assets/ui/plan_postit.png : le plan « recopié à la main » par le garde sur son post-it.
## Même grille que plan_prison.png (24 px par case, 912 x 576), fond transparent, encre de stylo bille.
## Lancer : python tools/generate_postit.py   (nécessite Pillow : pip install pillow)
from PIL import Image, ImageDraw, ImageFont

ROOT = os.environ.get('IMAJAM_ROOT') or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = open(os.path.join(ROOT, 'autoload/prison_nav.gd'), encoding='utf-8').read()
plan = re.search(r'const PLAN := """\n(.*?)"""', src, re.S).group(1)
PLAN = [l for l in plan.split('\n') if l.strip()]
ROWS, COLS = len(PLAN), max(len(l) for l in PLAN)
ROOMS = "B123RIGFKDLVAPx"
T, S = 24, 2
W, H = COLS * T, ROWS * T

def ch(x, y):
    if x < 0 or y < 0 or y >= ROWS or x >= len(PLAN[y]): return '.'
    return PLAN[y][x]
def region(x, y):
    c = ch(x, y)
    if c == '+': return 'C'
    if c == 'C' or c in ROOMS: return c
    return ''
def is_door(x, y): return ch(x, y) == '+'
def passable(a, b):
    ra, rb = region(*a), region(*b)
    if ra == '' or rb == '': return False
    return ra == rb or is_door(*a) or is_door(*b)
def is_wall(a, b):
    if region(*a) == '' and region(*b) == '': return False
    return not passable(a, b)

INK = (28, 44, 120, 235)        # stylo bille bleu
INK_LIGHT = (28, 44, 120, 150)
img = Image.new('RGBA', (W * S, H * S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
rng = random.Random(12)
def P(v): return v * S

def pen_line(x0, y0, x1, y1, width=4.6, color=INK):
    """Trait à main levée : léger tremblement, petit dépassement aux extrémités."""
    length = math.hypot(x1 - x0, y1 - y0)
    if length < 1: return
    ux, uy = (x1 - x0) / length, (y1 - y0) / length
    nx, ny = -uy, ux
    over0, over1 = rng.uniform(0.5, 3.0), rng.uniform(0.5, 3.0)
    x0, y0 = x0 - ux * over0, y0 - uy * over0
    x1, y1 = x1 + ux * over1, y1 + uy * over1
    n = max(2, int(length / 18))
    drift = rng.uniform(-1.2, 1.2)
    pts = []
    for i in range(n + 1):
        t = i / n
        wob = math.sin(t * math.pi) * drift + rng.uniform(-0.45, 0.45)
        pts.append((P(x0 + (x1 - x0) * t + nx * wob), P(y0 + (y1 - y0) * t + ny * wob)))
    d.line(pts, fill=color, width=int(P(width)), joint='curve')

# Murs regroupés en longs segments, tracés comme au stylo
for y in range(-1, ROWS + 1):
    x = -1
    while x <= COLS:
        if is_wall((x, y), (x, y + 1)):
            x0 = x
            while x <= COLS and is_wall((x, y), (x, y + 1)): x += 1
            pen_line(x0 * T, (y + 1) * T, x * T, (y + 1) * T)
        x += 1
for x in range(-1, COLS + 1):
    y = -1
    while y <= ROWS:
        if is_wall((x, y), (x + 1, y)):
            y0 = y
            while y <= ROWS and is_wall((x, y), (x + 1, y)): y += 1
            pen_line((x + 1) * T, y0 * T, (x + 1) * T, y * T)
        y += 1

# Salles : noms abrégés, écrits vite
boxes = {}
for y in range(ROWS):
    for x in range(COLS):
        r = region(x, y)
        if r and r != 'C':
            b = boxes.setdefault(r, [x, y, x, y])
            b[0], b[1], b[2], b[3] = min(b[0], x), min(b[1], y), max(b[2], x), max(b[3], y)
NAMES = {'B': 'bureau', '1': 'C1', '2': 'C2', '3': 'C3', 'R': 'réserve', 'A': 'archives',
         'I': 'infirm.', 'G': 'géné.', 'F': 'réfectoire', 'K': 'cuisine', 'D': 'douches',
         'L': 'buand.', 'V': 'vest.', 'P': 'parloir'}
FONT_PATHS = [os.path.join(ROOT, 'assets/fonts/Caveat.ttf'), 'Caveat.ttf']
def hand(size):
    for f in FONT_PATHS:
        try:
            ft = ImageFont.truetype(f, int(P(size)))
            try: ft.set_variation_by_axes([700])
            except Exception: pass
            return ft
        except OSError: pass
    return ImageFont.load_default(int(P(size)))
for r, name in NAMES.items():
    if r not in boxes: continue
    x0, y0, x1, y1 = boxes[r]
    w = (x1 - x0 + 1) * T - 8
    size = 46 if r in "123" else 40
    f = hand(size)
    while d.textlength(name, font=f) > P(w) and size > 18:
        size -= 2; f = hand(size)
    cx, cy = (x0 + x1 + 1) / 2 * T, (y0 + y1 + 1) / 2 * T
    tw = d.textlength(name, font=f)
    bb = d.textbbox((0, 0), name, font=f)
    layer = Image.new('RGBA', (int(tw + P(20)), int(bb[3] + P(16))), (0, 0, 0, 0))
    ImageDraw.Draw(layer).text((P(10), P(4)), name, font=f, fill=INK)
    layer = layer.rotate(rng.uniform(-6, 6), resample=Image.BICUBIC, expand=True)
    img.alpha_composite(layer, (int(P(cx) - layer.width / 2), int(P(cy) - layer.height / 2)))

# Le générateur entouré deux fois (c'est là qu'il faut aller pendant la panne)
gx0, gy0, gx1, gy1 = boxes['G']
cx, cy = (gx0 + gx1 + 1) / 2 * T, (gy0 + gy1 + 1) / 2 * T + 2
for k, (rx, ry) in enumerate([(56, 42), (59, 40)]):
    pts = []
    start = rng.uniform(0, math.tau)
    for i in range(49):
        a = start + math.tau * 1.06 * i / 48
        pts.append((P(cx + math.cos(a) * (rx + rng.uniform(-1.5, 1.5))), P(cy + math.sin(a) * (ry + rng.uniform(-1.5, 1.5)))))
    d.line(pts, fill=INK, width=int(P(2.4 if k == 0 else 1.6)), joint='curve')

img = img.resize((W, H), Image.LANCZOS)
out = os.path.join(ROOT, 'assets/ui/plan_postit.png')
img.save(out)
print(out, img.size)
