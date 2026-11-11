"""Aksesuarların renk seçeneklerini üretir.

Kullanım: python tool/outfit_colors.py

assets/images/outfits/ içindeki renklendirilebilir aksesuarların ana rengini
(şapkanın kumaşı, gözlüğün çerçevesi...) diğer renklere çevirip
<ad>_<renk>.png olarak kaydeder. Çizgiler, yıldız, bant, cam gibi parçalar
olduğu gibi kalır. tool/import_images.py ile yeni aksesuar görseli
aktarıldıktan sonra yeniden çalıştırılır.
"""
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "images", "outfits")

# Renk adı -> (ton 0..360, doygunluk, parlaklık). lib/data/outfits.dart ile aynı sırada.
COLORS = {
    "red": (358, 0.85, 0.95),
    "orange": (28, 0.85, 1.0),
    "green": (135, 0.70, 0.80),
    "blue": (214, 0.78, 0.92),
    "purple": (272, 0.62, 0.85),
    "pink": (332, 0.50, 1.0),
}

# Aksesuar -> (kendi rengi, ana rengin ton aralığı).
ITEMS = {
    "acc_cap": ("blue", (195, 255)),
    "acc_flower": ("pink", (295, 350)),
    "acc_glasses": ("red", (340, 15)),
    "acc_bow": ("red", (340, 15)),
    "acc_tophat": ("purple", (255, 310)),
}


def recolor(im, hue_range, target):
    rgb = np.asarray(im.convert("RGBA"), dtype=np.float64) / 255
    r, g, b, a = rgb[..., 0], rgb[..., 1], rgb[..., 2], rgb[..., 3]
    mx = rgb[..., :3].max(-1)
    mn = rgb[..., :3].min(-1)
    d = mx - mn
    v = mx
    s = np.where(mx > 0, d / np.maximum(mx, 1e-9), 0)
    dd = np.maximum(d, 1e-9)
    h = np.where(mx == r, ((g - b) / dd) % 6, np.where(mx == g, (b - r) / dd + 2, (r - g) / dd + 4)) * 60
    lo, hi = hue_range
    in_hue = (h >= lo) & (h <= hi) if lo <= hi else (h >= lo) | (h <= hi)
    # Koyu kahve çizgiler ve beyaz parçalar (puantiye, parlama) dışarıda kalır.
    main = in_hue & (s > 0.2) & (v > 0.3) & (a > 0)
    if not main.any():
        return im
    # Ana rengin tipik doygunluğu ve parlaklığı; gölgeler buna oranla korunur.
    base_s = np.median(s[main & (s > 0.5)]) if (main & (s > 0.5)).any() else np.median(s[main])
    base_v = np.median(v[main])
    th, ts, tv = target
    ns = np.clip(s * ts / base_s, 0, 1)
    nv = np.clip(v * tv / base_v, 0, 1)
    out = rgb.copy()
    hh = th / 60
    i = int(hh) % 6
    f = hh - int(hh)
    p = nv * (1 - ns)
    q = nv * (1 - ns * f)
    t = nv * (1 - ns * (1 - f))
    combos = [(nv, t, p), (q, nv, p), (p, nv, t), (p, q, nv), (t, p, nv), (nv, p, q)][i]
    for c in range(3):
        out[..., c] = np.where(main, combos[c], rgb[..., c])
    return Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGBA")


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    count = 0
    for name, (own, hue_range) in ITEMS.items():
        path = os.path.join(ROOT, name + ".png")
        if not os.path.exists(path):
            print("yok:", name)
            continue
        im = Image.open(path)
        for color, target in COLORS.items():
            if color == own:
                continue
            recolor(im, hue_range, target).save(os.path.join(ROOT, f"{name}_{color}.png"), optimize=True)
            count += 1
    print(count, "renk seçeneği üretildi")


if __name__ == "__main__":
    main()
