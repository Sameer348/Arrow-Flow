"""Shared drawing helpers for store assets (icon, feature graphic, screenshots)."""
import math
from PIL import Image, ImageDraw, ImageFilter

MIDNIGHT = (11, 16, 32)
DEEP = (8, 12, 24)
NAVY = (24, 34, 58)
CYAN = (66, 232, 255)
BLUE = (91, 124, 255)
VIOLET = (155, 108, 255)
GOLD = (255, 184, 77)
WHITE = (248, 250, 255)
MUTED = (170, 181, 204)

FONT = '/System/Library/Fonts/Avenir Next.ttc'
HEAVY, BOLD, DEMI, MEDIUM = 8, 0, 2, 5


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def vertical_gradient(size, top, bottom):
    w, h = size
    g = Image.new('RGB', (1, h))
    for y in range(h):
        g.putpixel((0, y), lerp(top, bottom, y / max(1, h - 1)))
    return g.resize((w, h))


def radial_glow(size, center, radius, color, alpha=0.35):
    """Soft additive light blob as an RGBA layer."""
    layer = Image.new('RGBA', size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = center
    d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=color + (int(255 * alpha),))
    return layer.filter(ImageFilter.GaussianBlur(radius * 0.45))


def linear_fill(size, c1, c2, angle_deg=0):
    """Gradient image along an angle (0 = left→right)."""
    w, h = size
    big = int(math.hypot(w, h)) + 2
    g = Image.new('RGB', (big, 1))
    for x in range(big):
        g.putpixel((x, 0), lerp(c1, c2, x / (big - 1)))
    g = g.resize((big, big)).rotate(-angle_deg, resample=Image.BICUBIC)
    left = (big - w) // 2
    top = (big - h) // 2
    return g.crop((left, top, left + w, top + h))


def arrow_polygon(cx, cy, length, thickness, head_w, head_len, angle_deg):
    """Arrow centred on (cx, cy), pointing along angle_deg (0 = right, -90 = up)."""
    a = math.radians(angle_deg)
    ux, uy = math.cos(a), math.sin(a)
    px, py = -uy, ux
    tail = -length / 2
    neck = length / 2 - head_len
    tip = length / 2
    t = thickness / 2
    pts = [(tail, -t), (neck, -t), (neck, -head_w / 2), (tip, 0), (neck, head_w / 2), (neck, t), (tail, t)]
    return [(cx + x * ux + y * px, cy + x * uy + y * py) for x, y in pts]


def draw_arrow(img, cx, cy, length, thickness, angle, c1=CYAN, c2=BLUE, glow=True, shadow=True, alpha=1.0):
    """Dimensional arrow: shadow, glow, gradient body, rounded tail."""
    w, h = img.size
    poly = arrow_polygon(cx, cy, length, thickness, thickness * 2.1, thickness * 1.5, angle)
    a = math.radians(angle)
    tail = (cx - math.cos(a) * length / 2, cy - math.sin(a) * length / 2)
    mask = Image.new('L', (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.polygon(poly, fill=255)
    md.ellipse([tail[0] - thickness / 2, tail[1] - thickness / 2, tail[0] + thickness / 2, tail[1] + thickness / 2], fill=255)
    if alpha < 1:
        mask = mask.point(lambda v: int(v * alpha))
    if shadow:
        sh = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        sm = mask.filter(ImageFilter.GaussianBlur(thickness * 0.25)).point(lambda v: int(v * 0.55))
        sh.putalpha(sm)
        img.alpha_composite(sh, (0, int(thickness * 0.22)))
    if glow:
        gl = Image.new('RGBA', (w, h), c1 + (0,))
        gm = mask.filter(ImageFilter.GaussianBlur(thickness * 0.9)).point(lambda v: int(v * 0.75))
        gl.putalpha(gm)
        img.alpha_composite(gl)
    body = linear_fill((w, h), c1, c2, angle + 180).convert('RGBA')
    # Gradient runs tail → tip; compute so tip gets c2.
    body = linear_fill((w, h), c2, c1, angle + 180).convert('RGBA')
    body.putalpha(mask)
    img.alpha_composite(body)
    # Specular highlight along the top edge of the shaft.
    hl = Image.new('L', (w, h), 0)
    hd = ImageDraw.Draw(hl)
    px, py = math.sin(a), -math.cos(a)  # perpendicular toward "up"
    if py > 0:
        px, py = -px, -py
    off = thickness * 0.2
    s = (tail[0] + math.cos(a) * thickness * 0.2 + px * off, tail[1] + math.sin(a) * thickness * 0.2 + py * off)
    e = (cx + math.cos(a) * (length / 2 - thickness * 1.8) + px * off, cy + math.sin(a) * (length / 2 - thickness * 1.8) + py * off)
    hd.line([s, e], fill=int(110 * alpha), width=max(2, int(thickness * 0.16)))
    hl = hl.filter(ImageFilter.GaussianBlur(thickness * 0.04))
    white = Image.new('RGBA', (w, h), (255, 255, 255, 0))
    white.putalpha(hl)
    img.alpha_composite(white)


def rounded_rect(draw, box, r, fill=None, outline=None, width=1):
    draw.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)
