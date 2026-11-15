"""Framed store screenshots with headlines.

Input:  store/raw_screenshots/*.png  (1320x2868 simulator captures)
Output: store/app_store/screenshots_6.9, screenshots_6.5, store/google_play/screenshots
Run:    python make_screenshots.py
"""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from common import *

ROOT = os.path.join(os.path.dirname(__file__), '..', '..')
RAW = os.path.join(ROOT, 'store', 'raw_screenshots')

# (raw file, line 1, highlighted line 2, subtitle, glow colour)
SLIDES = [
    ('game47', 'Tap the arrow', 'with a clear path', 'Free it, then find the next one', CYAN),
    ('game_combo', 'Chain combos', 'for huge scores', 'x2, x3, x5 multipliers', BLUE),
    ('daily_board', 'A new puzzle', 'every single day', 'Daily Challenge, same for everyone', GOLD),
    ('tower', 'Rotate the', '2.5D Tower', 'Clear stacked layers', VIOLET),
    ('complete', 'Earn 3 stars', 'on every level', 'Play clean for a Perfect clear', (53, 224, 161)),
    ('map', '1,200+ levels', 'to master', 'From easy to expert, always solvable', CYAN),
    ('skins', 'Unlock skins', '& board themes', '10 skins · 9 themes · no pay-to-win', (255, 106, 77)),
    ('boosters', 'Stuck? Use', 'smart boosters', 'Hint, Undo, Hammer, Shuffle & more', VIOLET),
]

TARGETS = [
    ('app_store/screenshots_6.9', 1320, 2868),
    ('app_store/screenshots_6.5', 1284, 2778),
    ('google_play/screenshots', 1080, 1920),
]


def gradient_text(img, xy, text, font, c1, c2):
    w, h = img.size
    mask = Image.new('L', (w, h), 0)
    ImageDraw.Draw(mask).text(xy, text, font=font, fill=255, anchor='mt')
    bbox = mask.getbbox()
    grad = linear_fill((w, h), c1, c2, 0).convert('RGBA')
    if bbox:
        g = linear_fill((bbox[2] - bbox[0] or 1, h), c1, c2, 0).convert('RGBA')
        grad = Image.new('RGBA', (w, h))
        grad.paste(g, (bbox[0], 0))
    grad.putalpha(mask)
    img.alpha_composite(grad)


def slide(raw, l1, l2, sub, accent, W, H):
    img = vertical_gradient((W, H), (18, 26, 56), (8, 11, 24)).convert('RGBA')
    img.alpha_composite(radial_glow((W, H), (W * 0.15, H * 0.08), W * 0.55, accent, 0.35))
    img.alpha_composite(radial_glow((W, H), (W * 0.95, H * 0.55), W * 0.5, VIOLET, 0.25))
    img.alpha_composite(radial_glow((W, H), (W * 0.5, H * 0.95), W * 0.6, BLUE, 0.25))

    wide = W / H > 0.5  # Play's 9:16 canvas is wider relative to height
    title_size = int(W * (0.085 if not wide else 0.072))
    sub_size = int(W * (0.038 if not wide else 0.034))
    f_title = ImageFont.truetype(FONT, title_size, index=HEAVY)
    f_sub = ImageFont.truetype(FONT, sub_size, index=DEMI)
    top = int(H * (0.055 if not wide else 0.045))
    d = ImageDraw.Draw(img)
    d.text((W / 2, top), l1, font=f_title, fill=WHITE, anchor='mt')
    gradient_text(img, (W / 2, top + title_size * 1.12), l2, f_title, (130, 245, 255), lerp(accent, BLUE, 0.3))
    d = ImageDraw.Draw(img)
    d.text((W / 2, top + title_size * 2.4), sub, font=f_sub, fill=MUTED, anchor='mt')

    # Device frame.
    shot = Image.open(os.path.join(RAW, raw + '.png')).convert('RGBA')
    dev_top = int(top + title_size * 2.4 + sub_size * 2.0)
    dev_w = int(W * (0.80 if not wide else 0.60))
    dev_h = int(dev_w * shot.height / shot.width)
    bezel = int(dev_w * 0.028)
    radius = int(dev_w * 0.13)
    shot = shot.resize((dev_w, dev_h), Image.LANCZOS)
    m = Image.new('L', (dev_w, dev_h), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, dev_w - 1, dev_h - 1], radius=radius - bezel, fill=255)
    shot.putalpha(m)

    fw, fh = dev_w + bezel * 2, dev_h + bezel * 2
    x = (W - fw) // 2
    # Shadow + accent glow behind the phone.
    sh = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([x, dev_top + 30, x + fw, dev_top + fh + 30], radius=radius, fill=(0, 0, 0, 170))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(40)))
    gl = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(gl).rounded_rectangle([x, dev_top, x + fw, dev_top + fh], radius=radius, fill=accent + (90,))
    img.alpha_composite(gl.filter(ImageFilter.GaussianBlur(60)))
    frame = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame)
    fd.rounded_rectangle([x, dev_top, x + fw, dev_top + fh], radius=radius, fill=(20, 24, 36, 255), outline=(90, 100, 130, 255), width=max(2, bezel // 6))
    img.alpha_composite(frame)
    img.alpha_composite(shot, (x + bezel, dev_top + bezel))
    return img.convert('RGB')


def main():
    for folder, W, H in TARGETS:
        out = os.path.join(ROOT, 'store', folder)
        os.makedirs(out, exist_ok=True)
        for i, (raw, l1, l2, sub, accent) in enumerate(SLIDES, 1):
            slide(raw, l1, l2, sub, accent, W, H).save(os.path.join(out, f'{i:02d}_{raw}.png'), optimize=True)
        print('ok', folder)


if __name__ == '__main__':
    main()
