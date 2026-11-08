import math, os, random, re
## Régénère assets/ui/plan_prison.png à partir de PrisonNav.PLAN (style plan d'architecte),
## sur la même grille (24 px par case) : le post-it et la carte restent alignés.
## Lancer : python tools/generate_plan.py   (nécessite Pillow : pip install pillow)
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw, ImageFont, ImageFilter

src = open(os.path.join(ROOT, 'autoload/prison_nav.gd'), encoding='utf-8').read()
plan = re.search(r'const PLAN := """\n(.*?)"""', src, re.S).group(1)
PLAN = [l for l in plan.split('\n') if l.strip()]
ROWS, COLS = len(PLAN), max(len(l) for l in PLAN)
ROOMS = "B123RIGFKDLVAPx"
T = 24; S = 3                      # 24 px par case, dessin en x3 puis réduction (antialiasing)
W, H = COLS*T, ROWS*T
assert (W, H) == (912, 576)

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

# --- Palette « plan d'architecte » (bleu de plan)
BG      = (22, 52, 92)
GRID    = (44, 82, 128)
GRID_B  = (58, 100, 150)
CORR    = (30, 66, 110)
ROOM    = (34, 72, 118)
INK     = (232, 240, 250)
INK_DIM = (160, 190, 222)
RED     = (214, 72, 64)
AMBER   = (232, 186, 72)

img = Image.new('RGB', (W*S, H*S), BG)
d = ImageDraw.Draw(img)
def P(v): return int(round(v*S))
FONT_CANDIDATES = {
    True: ['/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf', 'C:/Windows/Fonts/arialnb.ttf', 'C:/Windows/Fonts/arialbd.ttf', 'DejaVuSansCondensed-Bold.ttf'],
    False: ['/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf', 'C:/Windows/Fonts/consola.ttf', 'C:/Windows/Fonts/cour.ttf', 'DejaVuSansMono.ttf'],
}
def font(sz, bold=True):
    for f in FONT_CANDIDATES[bold]:
        try:
            return ImageFont.truetype(f, P(sz))
        except OSError:
            pass
    return ImageFont.load_default(P(sz))

# Grain du papier
random.seed(4)
for _ in range(9000):
    x, y = random.randrange(W*S), random.randrange(H*S)
    k = random.randint(-6, 6)
    d.point((x, y), fill=(BG[0]+k, BG[1]+k, BG[2]+k))

# Quadrillage : une ligne par case, renforcée toutes les 5 cases
for i in range(COLS+1):
    d.line([(P(i*T), 0), (P(i*T), P(H))], fill=GRID_B if i % 5 == 0 else GRID, width=P(0.6 if i % 5 else 0.9))
for j in range(ROWS+1):
    d.line([(0, P(j*T)), (P(W), P(j*T))], fill=GRID_B if j % 5 == 0 else GRID, width=P(0.6 if j % 5 else 0.9))

# Sols : couloirs et salles
for y in range(ROWS):
    for x in range(COLS):
        r = region(x, y)
        if r == '': continue
        d.rectangle([P(x*T), P(y*T), P((x+1)*T), P((y+1)*T)], fill=CORR if r == 'C' else ROOM)

# Boîtes englobantes des salles
boxes = {}
for y in range(ROWS):
    for x in range(COLS):
        r = region(x, y)
        if r and r != 'C':
            b = boxes.setdefault(r, [x, y, x, y])
            b[0], b[1], b[2], b[3] = min(b[0], x), min(b[1], y), max(b[2], x), max(b[3], y)

def hatch(box, color, step=7, width=0.8):
    x0, y0, x1, y1 = P(box[0]*T), P(box[1]*T), P((box[2]+1)*T), P((box[3]+1)*T)
    layer = Image.new('L', img.size, 0); ld = ImageDraw.Draw(layer)
    for k in range(-(y1-y0), (x1-x0), P(step)):
        ld.line([(x0+k, y1), (x0+k+(y1-y0), y0)], fill=255, width=P(width))
    mask = Image.new('L', img.size, 0); ImageDraw.Draw(mask).rectangle([x0, y0, x1, y1], fill=255)
    from PIL import ImageChops
    layer = ImageChops.multiply(layer, mask)
    img.paste(Image.new('RGB', img.size, color), (0, 0), layer.point(lambda v: v*0.55))

# Cellules : hachures rouges + barreaux ; bureau et générateur : hachures ambre
for r in '123':
    x0, y0, x1, y1 = boxes[r]
    d.rectangle([P(x0*T), P(y0*T), P((x1+1)*T), P((y1+1)*T)], fill=(78, 58, 92))
hatch(boxes['B'], AMBER, step=8)
hatch(boxes['G'], AMBER, step=5)
for r in '123':
    x0, y0, x1, y1 = boxes[r]
    for i in range(1, 6):
        bx = P(x0*T + i*(x1-x0+1)*T/6)
        d.line([(bx, P(y0*T+4)), (bx, P((y1+1)*T-4))], fill=(236, 150, 140), width=P(1.0))

# Murs : arête entre deux cases qu'on ne peut pas traverser, fusionnées en longs segments
WALL = 3.2
h = WALL / 2
def is_wall(a, b):
    if region(*a) == '' and region(*b) == '': return False
    return not passable(a, b)
for y in range(-1, ROWS+1):          # murs horizontaux (arête basse de la case y)
    x = -1
    while x <= COLS:
        if is_wall((x, y), (x, y+1)):
            x0 = x
            while x <= COLS and is_wall((x, y), (x, y+1)): x += 1
            d.rectangle([P(x0*T - h), P((y+1)*T - h), P(x*T + h), P((y+1)*T + h)], fill=INK)
        x += 1
for x in range(-1, COLS+1):          # murs verticaux (arête droite de la case x)
    y = -1
    while y <= ROWS:
        if is_wall((x, y), (x+1, y)):
            y0 = y
            while y <= ROWS and is_wall((x, y), (x+1, y)): y += 1
            d.rectangle([P((x+1)*T - h), P(y0*T - h), P((x+1)*T + h), P(y*T + h)], fill=INK)
        y += 1

# Portes : charnière sur un jambage, battant ouvert à 90° vers la salle, arc jusqu'à l'autre jambage
for y in range(ROWS):
    for x in range(COLS):
        if not is_door(x, y): continue
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            r = region(x+dx, y+dy)
            if r == '' or r == 'C': continue
            if dx:   # ouverture verticale
                ex = (x + (1 if dx > 0 else 0)) * T
                hinge = (ex, y*T + h); along = (0, 1)
            else:    # ouverture horizontale
                ey = (y + (1 if dy > 0 else 0)) * T
                hinge = (x*T + h, ey); along = (1, 0)
            L = T - 2*h
            n = (dx, dy)
            tip = (hinge[0] + n[0]*L, hinge[1] + n[1]*L)
            a0 = math.atan2(n[1], n[0]); a1 = math.atan2(along[1], along[0])
            da = (a1 - a0 + math.pi) % (2*math.pi) - math.pi
            pts = [(P(hinge[0] + L*math.cos(a0 + da*k/24)), P(hinge[1] + L*math.sin(a0 + da*k/24))) for k in range(25)]
            d.line(pts, fill=INK_DIM, width=P(0.8))
            d.line([(P(hinge[0]), P(hinge[1])), (P(tip[0]), P(tip[1]))], fill=INK, width=P(1.6))

# Étiquettes des salles : nom + code
NAMES = {
    'B': ('POSTE DE GARDE', 'BUREAU'), '1': ('CELLULE 1', 'H.S. — A1'), '2': ('CELLULE 2', 'H.S. — B2'),
    '3': ('CELLULE 3', 'H.S. — C3'), 'R': ('RÉSERVE', 'R-04'), 'A': ('ARCHIVES', 'R-05'),
    'I': ('INFIRMERIE', 'M-01'), 'G': ('GÉNÉRATEUR', 'LOCAL TECH.'), 'F': ('RÉFECTOIRE', 'S-01'),
    'K': ('CUISINES', 'S-02'), 'D': ('DOUCHES', 'S-03'), 'L': ('BUANDERIE', 'S-04'),
    'V': ('VESTIAIRE', 'P-02'), 'P': ('PARLOIR', 'V-01'),
}
def label(cx, cy, title, sub, w):
    sz = 9.5 if w >= 4*T else 7.8
    f1, f2 = font(sz), font(sz*0.72, bold=False)
    tw = d.textlength(title, font=f1)
    if tw > P(w-6):
        f1 = font(sz*(w-6)/ (tw/S)); tw = d.textlength(title, font=f1)
    sw = d.textlength(sub, font=f2)
    th = P(sz)
    pad = P(3)
    bw = max(tw, sw) + 2*pad
    bh = th + P(sz*0.72) + P(5) + pad
    x0, y0 = P(cx) - bw/2, P(cy) - bh/2
    d.rectangle([x0, y0, x0+bw, y0+bh], fill=BG, outline=INK_DIM, width=P(0.7))
    d.text((P(cx) - tw/2, y0 + pad*0.6), title, font=f1, fill=INK)
    d.text((P(cx) - sw/2, y0 + pad*0.6 + th + P(2)), sub, font=f2, fill=INK_DIM)
for r, (t, s) in NAMES.items():
    if r not in boxes: continue
    x0, y0, x1, y1 = boxes[r]
    label((x0+x1+1)/2*T, (y0+y1+1)/2*T, t, s, (x1-x0+1)*T)

# Rose des vents (coin haut gauche)
cx, cy, R = 44, 44, 26
d.ellipse([P(cx-R), P(cy-R), P(cx+R), P(cy+R)], outline=INK_DIM, width=P(1))
d.ellipse([P(cx-R+5), P(cy-R+5), P(cx+R-5), P(cy+R-5)], outline=GRID_B, width=P(0.7))
d.polygon([(P(cx), P(cy-R+2)), (P(cx+6), P(cy)), (P(cx), P(cy+R-2)), (P(cx-6), P(cy))], outline=INK, width=P(1))
d.polygon([(P(cx), P(cy-R+2)), (P(cx+6), P(cy)), (P(cx), P(cy))], fill=INK)
d.polygon([(P(cx), P(cy+R-2)), (P(cx-6), P(cy)), (P(cx), P(cy))], fill=INK)
fN = font(9); d.text((P(cx) - d.textlength('N', font=fN)/2, P(cy-R-13)), 'N', font=fN, fill=INK)

# Échelle (bas gauche) : 1 case = 1,4 m -> segments de 2 m
x0, y0 = 12, H - 22
seg = 2.0 / 1.4 * T
d.text((P(x0), P(y0-14)), 'ÉCHELLE (m)', font=font(7, bold=False), fill=INK_DIM)
for i in range(5):
    d.rectangle([P(x0 + i*seg), P(y0), P(x0 + (i+1)*seg), P(y0+5)],
                fill=INK if i % 2 == 0 else BG, outline=INK, width=P(0.7))
for i in (0, 1, 2, 3, 4, 5):
    t = str(i*2)
    tw = d.textlength(t, font=font(6.5, bold=False)) / S
    d.text((P(x0 + i*seg - tw/2), P(y0+7)), t, font=font(6.5, bold=False), fill=INK_DIM)

# Cartouche (bas droite)
bx0, by0, bx1, by1 = 21*T + 6, 22*T + 8, W - 6, H - 5
d.rectangle([P(bx0), P(by0), P(bx1), P(by1)], fill=BG, outline=INK, width=P(1.6))
mid = bx0 + 236
d.line([(P(mid), P(by0)), (P(mid), P(by1))], fill=INK, width=P(1))
d.line([(P(mid), P((by0+by1)/2)), (P(bx1), P((by0+by1)/2))], fill=INK, width=P(0.8))
d.text((P(bx0+8), P(by0+3)), 'PÉNITENCIER SAINT-ROCH', font=font(11), fill=INK)
d.text((P(bx0+8), P(by0+19)), 'AILE PSYCHIATRIQUE — PLAN DU NIVEAU 0', font=font(7.2, bold=False), fill=INK_DIM)
d.text((P(mid+6), P(by0+3)), 'PLANCHE N° 07/12', font=font(7.2, bold=False), fill=INK_DIM)
d.text((P(mid+6), P((by0+by1)/2+2)), 'ÉCH. 1:200', font=font(7.2, bold=False), fill=INK_DIM)

# Légère vignette
vig = Image.new('L', img.size, 0); vd = ImageDraw.Draw(vig)
vd.rectangle([0, 0, img.size[0], img.size[1]], fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(P(40)))
dark = Image.new('RGB', img.size, (12, 30, 58))
img = Image.composite(img, dark, vig.point(lambda v: 150 + v*105//255))

img = img.resize((W, H), Image.LANCZOS)
img.save(os.path.join(ROOT, 'assets/ui/plan_prison.png'))
print(img.size)
