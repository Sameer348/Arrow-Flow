"""App icon: 1024 master + all iOS/Android launcher sizes + adaptive icon.

Run: python tool/store_assets/make_icon.py   (needs Pillow)
"""
import json, os
from PIL import Image, ImageDraw, ImageFilter
from common import *

ROOT = os.path.join(os.path.dirname(__file__), '..', '..')
SS = 4  # supersampling


def glyph(size, scale=1.0):
    """Board tiles + escaping arrow on transparent canvas."""
    S = size * SS
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = S / 2
    cell = S * 0.19 * scale
    gap = cell * 0.14
    grid = cell * 3 + gap * 2
    x0 = c - grid / 2 - S * 0.06 * scale
    y0 = c - grid / 2 + S * 0.03 * scale
    # Tiles (one cell left empty where the arrow was).
    for r in range(3):
        for col in range(3):
            bx = x0 + col * (cell + gap)
            by = y0 + r * (cell + gap)
            fill = (255, 255, 255, 20) if (r, col) != (1, 2) else (66, 232, 255, 34)
            rounded_rect(d, [bx, by, bx + cell, by + cell], cell * 0.24, fill=fill)
    # Two calm blocked arrows inside the board.
    draw_arrow(img, x0 + cell * 0.5, y0 + (cell + gap) * 1 + cell * 0.5 + cell * 0.55, cell * 1.6, cell * 0.24, -90,
               c1=(120, 136, 180), c2=(80, 94, 140), glow=False, alpha=0.9)
    draw_arrow(img, x0 + (cell + gap) * 1 + cell * 0.5, y0 + (cell + gap) * 2 + cell * 0.5, cell * 0.85, cell * 0.24, 180,
               c1=(120, 136, 180), c2=(80, 94, 140), glow=False, alpha=0.9)
    # Hero arrow escaping right out of the board.
    ay = y0 + (cell + gap) * 1 + cell * 0.5
    ax = x0 + grid * 0.80
    # Speed trail.
    trail = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    td = ImageDraw.Draw(trail)
    for i in range(40):
        t = i / 39
        x = x0 - cell * 0.3 + (ax - x0) * t
        td.ellipse([x - cell * 0.13, ay - cell * 0.13, x + cell * 0.13, ay + cell * 0.13], fill=(66, 232, 255, int(120 * t)))
    img.alpha_composite(trail.filter(ImageFilter.GaussianBlur(cell * 0.08)))
    draw_arrow(img, ax + cell * 0.35, ay, cell * 2.5, cell * 0.44, 0, c1=(120, 245, 255), c2=CYAN)
    # Sparks at the tip.
    sp = ImageDraw.Draw(img)
    tip = ax + cell * 0.35 + cell * 1.25
    for dx, dy, r in [(0.35, -0.42, 0.06), (0.55, 0.05, 0.045), (0.3, 0.45, 0.05), (0.75, -0.2, 0.03)]:
        sp.ellipse([tip + dx * cell - r * cell, ay + dy * cell - r * cell, tip + dx * cell + r * cell, ay + dy * cell + r * cell], fill=(220, 250, 255, 230))
    return img


def background(size):
    S = size * SS
    bg = vertical_gradient((S, S), (22, 30, 66), (8, 11, 24)).convert('RGBA')
    bg.alpha_composite(radial_glow((S, S), (S * 0.25, S * 0.2), S * 0.45, BLUE, 0.45))
    bg.alpha_composite(radial_glow((S, S), (S * 0.85, S * 0.85), S * 0.4, VIOLET, 0.35))
    return bg


def master(size=1024):
    bg = background(size)
    bg.alpha_composite(glyph(size))
    return bg.resize((size, size), Image.LANCZOS).convert('RGB')


def main():
    out = os.path.join(ROOT, 'store', 'branding')
    os.makedirs(out, exist_ok=True)
    icon = master(1024)
    icon.save(os.path.join(out, 'app_icon_1024.png'))
    icon.resize((512, 512), Image.LANCZOS).save(os.path.join(out, 'play_store_icon_512.png'))

    # iOS: every size listed in the app icon set.
    ios_dir = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    contents = json.load(open(os.path.join(ios_dir, 'Contents.json')))
    for im in contents['images']:
        pts = float(im['size'].split('x')[0])
        px = int(round(pts * int(im['scale'][0])))
        icon.resize((px, px), Image.LANCZOS).save(os.path.join(ios_dir, im['filename']))

    # Android legacy launcher icons (rounded square) + round.
    res = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
    dens = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    big = master(1024)
    mask_sq = Image.new('L', (1024, 1024), 0)
    ImageDraw.Draw(mask_sq).rounded_rectangle([0, 0, 1023, 1023], radius=200, fill=255)
    mask_rd = Image.new('L', (1024, 1024), 0)
    ImageDraw.Draw(mask_rd).ellipse([0, 0, 1023, 1023], fill=255)
    sq = big.convert('RGBA'); sq.putalpha(mask_sq)
    rd = big.convert('RGBA'); rd.putalpha(mask_rd)
    for name, k in dens.items():
        d = os.path.join(res, f'mipmap-{name}')
        os.makedirs(d, exist_ok=True)
        sq.resize((int(48 * k), int(48 * k)), Image.LANCZOS).save(os.path.join(d, 'ic_launcher.png'))
        rd.resize((int(48 * k), int(48 * k)), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_round.png'))
        # Adaptive layers are 108dp; content must sit in the inner 66dp.
        fg = glyph(432, scale=0.8).resize((int(108 * k), int(108 * k)), Image.LANCZOS)
        fg.save(os.path.join(d, 'ic_launcher_foreground.png'))
        bg = background(432).resize((int(108 * k), int(108 * k)), Image.LANCZOS).convert('RGB')
        bg.save(os.path.join(d, 'ic_launcher_background.png'))

    any_dir = os.path.join(res, 'mipmap-anydpi-v26')
    os.makedirs(any_dir, exist_ok=True)
    xml = ('<?xml version="1.0" encoding="utf-8"?>\n'
           '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
           '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
           '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
           '    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>\n'
           '</adaptive-icon>\n')
    for n in ('ic_launcher.xml', 'ic_launcher_round.xml'):
        open(os.path.join(any_dir, n), 'w').write(xml)
    print('icons ok')


if __name__ == '__main__':
    main()
