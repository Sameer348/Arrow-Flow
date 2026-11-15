"""Google Play feature graphic, 1024x500. Run: python make_feature_graphic.py"""
import os
from PIL import Image, ImageDraw, ImageFont
from common import *

ROOT = os.path.join(os.path.dirname(__file__), '..', '..')
W, H, SS = 1024, 500, 3


def main():
    w, h = W * SS, H * SS
    img = vertical_gradient((w, h), (20, 28, 62), (8, 11, 24)).convert('RGBA')
    img.alpha_composite(radial_glow((w, h), (w * 0.78, h * 0.45), h * 0.75, BLUE, 0.45))
    img.alpha_composite(radial_glow((w, h), (w * 0.95, h * 0.95), h * 0.5, VIOLET, 0.4))
    img.alpha_composite(radial_glow((w, h), (w * 0.1, h * 0.1), h * 0.5, CYAN, 0.18))
    d = ImageDraw.Draw(img)

    # Board on the right.
    cell = h * 0.155
    gap = cell * 0.13
    n = 4
    grid = cell * n + gap * (n - 1)
    x0 = w * 0.585
    y0 = (h - grid) / 2
    tiles = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    td0 = ImageDraw.Draw(tiles)
    rounded_rect(td0, [x0 - gap * 2, y0 - gap * 2, x0 + grid + gap * 2, y0 + grid + gap * 2], cell * 0.4, fill=(255, 255, 255, 10), outline=(255, 255, 255, 30), width=SS * 2)
    for r in range(n):
        for c in range(n):
            bx, by = x0 + c * (cell + gap), y0 + r * (cell + gap)
            rounded_rect(td0, [bx, by, bx + cell, by + cell], cell * 0.22, fill=(255, 255, 255, 16))
    img.alpha_composite(tiles)
    def cc(r, c):
        return x0 + c * (cell + gap) + cell / 2, y0 + r * (cell + gap) + cell / 2
    grey = dict(c1=(120, 136, 180), c2=(84, 98, 146), glow=False)
    span = cell + gap
    x, y = cc(0, 0); draw_arrow(img, x + span / 2, y, span + cell * 0.7, cell * 0.24, 0, **grey)
    x, y = cc(2, 0); draw_arrow(img, x, y + span / 2, span + cell * 0.7, cell * 0.24, -90, **grey)
    x, y = cc(3, 2); draw_arrow(img, x, y, cell * 0.8, cell * 0.24, 180, **grey)
    x, y = cc(0, 3); draw_arrow(img, x, y, cell * 0.8, cell * 0.24, 90, **grey)
    x, y = cc(3, 3); draw_arrow(img, x, y - span / 2, span + cell * 0.7, cell * 0.24, -90, c1=VIOLET, c2=CYAN)
    # Hero arrow escaping off the right edge with a trail.
    x, y = cc(1, 2)
    trail = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    td = ImageDraw.Draw(trail)
    for i in range(60):
        t = i / 59
        tx = x0 + (x + span * 0.8 - x0) * t
        td.ellipse([tx - cell * 0.12, y - cell * 0.12, tx + cell * 0.12, y + cell * 0.12], fill=(66, 232, 255, int(110 * t)))
    from PIL import ImageFilter
    img.alpha_composite(trail.filter(ImageFilter.GaussianBlur(cell * 0.1)))
    draw_arrow(img, x + span * 1.2, y, span * 1.5, cell * 0.36, 0, c1=(120, 245, 255), c2=CYAN)

    # Left: icon + title + tagline.
    icon = Image.open(os.path.join(ROOT, 'store', 'branding', 'app_icon_1024.png')).convert('RGBA')
    isz = int(h * 0.26)
    icon = icon.resize((isz, isz), Image.LANCZOS)
    m = Image.new('L', (isz, isz), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, isz - 1, isz - 1], radius=int(isz * 0.22), fill=255)
    icon.putalpha(m)
    lx = int(w * 0.07)
    img.alpha_composite(icon, (lx, int(h * 0.14)))
    title = ImageFont.truetype(FONT, int(h * 0.17), index=HEAVY)
    sub = ImageFont.truetype(FONT, int(h * 0.062), index=DEMI)
    d = ImageDraw.Draw(img)
    d.text((lx, int(h * 0.45)), 'ARROW', font=title, fill=WHITE)
    # Gradient "FLOW".
    tw = d.textbbox((0, 0), 'FLOW', font=title)
    layer = Image.new('L', (w, h), 0)
    ImageDraw.Draw(layer).text((lx, int(h * 0.62)), 'FLOW', font=title, fill=255)
    grad = linear_fill((w, h), CYAN, BLUE, 0).convert('RGBA')
    grad.putalpha(layer)
    img.alpha_composite(grad)
    d.text((lx, int(h * 0.83)), 'Tap. Escape. Clear the board.', font=sub, fill=MUTED)

    out = img.resize((W, H), Image.LANCZOS).convert('RGB')
    os.makedirs(os.path.join(ROOT, 'store', 'google_play'), exist_ok=True)
    out.save(os.path.join(ROOT, 'store', 'google_play', 'feature_graphic_1024x500.png'))
    print('feature ok')


if __name__ == '__main__':
    main()
