"""Üretilen görselleri oyuna aktarır.

Kullanım: python tool/import_images.py <kaynak_klasör>

Kaynak klasördeki, docs/gorsel-promptlari.md içindeki adlarla kaydedilmiş resim
dosyalarını (PNG, JPEG, WebP) bulur; şeffaf olmayanların (beyaz ya da damalı) arka planını
temizler, kenar boşluklarını kırpar, uygun boyuta küçültür ve assets/images/
altındaki doğru klasöre yazar. Kaynak dosyalara dokunmaz.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "images")

OBJECTS = [
    "apple", "banana", "strawberry", "orange", "grapes", "watermelon", "pear", "cherry",
    "cat", "dog", "rabbit", "elephant", "lion", "frog", "fish", "bird",
    "car", "bus", "plane", "boat", "train", "balloon", "ball", "star",
]
GAMES = [
    "shapes", "memory", "shadow", "count", "pattern", "odd", "puzzle", "sort",
    "maze", "color", "groups", "simon", "diff", "dots",
    "scene", "duel", "music", "wardrobe",
]
OUTFITS = ["acc_cap", "acc_flower", "acc_glasses", "acc_party", "acc_bow", "acc_explorer", "acc_tophat", "acc_crown"]
STICKERS = [
    "st_cow", "st_goat", "st_chicken", "st_horse", "st_sheep", "st_duck", "st_tractor", "st_barn", "st_sunflower", "st_carrot", "st_corn", "st_rooster",
    "st_whale", "st_octopus", "st_crab", "st_turtle", "st_dolphin", "st_shark", "st_starfish", "st_clownfish", "st_seahorse", "st_jellyfish", "st_submarine", "st_anchor",
    "st_rocket", "st_rover", "st_planet", "st_mars", "st_star", "st_astronaut", "st_comet", "st_earth", "st_sun", "st_telescope", "st_satellite", "st_robot",
]
UI = [
    "lock", "star_full", "star_empty", "crown", "card_back", "btn_play", "btn_back", "btn_home",
    "btn_replay", "btn_next", "btn_sound_on", "btn_sound_off", "btn_parents",
]

EXTENSIONS = {".png", ".jpg", ".jpeg", ".jfif", ".webp"}

# dosya adı -> (klasör, en uzun kenar, şeffaf kesim mi?)
TARGETS = {}
for pose in ["hello", "happy", "thinking", "oops", "wave"]:
    TARGETS[f"fox_{pose}"] = ("mascot", 768, True)
for name in ["home", "meadow", "sea", "space"]:
    TARGETS[f"bg_{name}"] = ("bg", 1600, False)
for name in GAMES:
    TARGETS[f"game_{name}"] = ("icons", 512, True)
for name in OBJECTS:
    TARGETS[name] = ("objects", 512, True)
for name in ["farm", "sea", "jungle", "space"]:
    TARGETS[f"puzzle_{name}"] = ("puzzle", 1024, False)
for name in UI:
    TARGETS[name] = ("ui", 384, True)
for name in STICKERS:
    TARGETS[name] = ("stickers", 384, True)
TARGETS["logo"] = ("ui", 1024, True)
for name in OUTFITS:
    TARGETS[name] = ("outfits", 384, True)
TARGETS["level_stop"] = ("ui", 512, True)
# Kareye oturtulmayan, kendi en-boy oranında kalan görseller.
WIDE = {"logo", "level_stop"}


def remove_baked_background(im, keep_all=False):
    """Kenarlardan başlayıp açık renkli, renksiz (beyaz/gri damalı) zemini siler.

    Çizimlerin koyu dış çizgisi taşmayı durdurur; içerideki beyaz alanlar
    (göz, karın, kuyruk ucu) korunur.
    """
    rgb = im.convert("RGB")
    r, g, b = rgb.split()
    lightest = ImageChops.lighter(ImageChops.lighter(r, g), b)
    darkest = ImageChops.darker(ImageChops.darker(r, g), b)
    is_light = darkest.point(lambda v: 255 if v >= 150 else 0)
    is_grey = ImageChops.subtract(lightest, darkest).point(lambda v: 255 if v <= 32 else 0)
    candidate = ImageChops.multiply(is_light, is_grey)

    # Tek bir taşırma ile tüm kenarlardan başlamak için 1 piksel çerçeve ekle.
    w, h = im.size
    padded = Image.new("L", (w + 2, h + 2), 255)
    padded.paste(candidate, (1, 1))
    ImageDraw.floodfill(padded, (0, 0), 128)
    background = padded.crop((1, 1, w + 1, h + 1)).point(lambda v: 255 if v == 128 else 0)

    # Kenardaki açık renkli hale kalmasın diye maskeyi 1-2 piksel içeri al.
    alpha = ImageChops.invert(background).filter(ImageFilter.MinFilter(5))
    if not keep_all:
        alpha = ImageChops.multiply(alpha, main_parts(alpha))
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.8))
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def main_parts(alpha):
    """Zeminden arta kalan kırıntıları atar: yalnızca büyük parçalar kalır."""
    w, h = alpha.size
    small = alpha.resize((w // 2, h // 2), Image.NEAREST)
    mask = np.asarray(small) > 0
    sh, sw = mask.shape
    label = np.where(mask, np.arange(1, sh * sw + 1).reshape(sh, sw), 0)
    while True:
        grown = label.copy()
        grown[1:, :] = np.maximum(grown[1:, :], label[:-1, :])
        grown[:-1, :] = np.maximum(grown[:-1, :], label[1:, :])
        grown[:, 1:] = np.maximum(grown[:, 1:], label[:, :-1])
        grown[:, :-1] = np.maximum(grown[:, :-1], label[:, 1:])
        grown[~mask] = 0
        if np.array_equal(grown, label):
            break
        label = grown
    ids, counts = np.unique(label[label > 0], return_counts=True)
    keep = ids[counts >= counts.max() * 0.03]
    kept = Image.fromarray((np.isin(label, keep) * 255).astype(np.uint8))
    return kept.resize((w, h), Image.NEAREST).filter(ImageFilter.MaxFilter(5))


def add_sticker_border(im):
    """Zeminle birlikte silinen beyaz çıkartma kenarını yeniden ekler."""
    pad = max(im.size) // 22
    big = Image.new("RGBA", (im.width + 2 * pad, im.height + 2 * pad), (0, 0, 0, 0))
    big.paste(im, (pad, pad))
    solid = big.getchannel("A").point(lambda v: 255 if v > 100 else 0)
    edge = solid.filter(ImageFilter.MaxFilter(pad // 2 * 2 + 1)).filter(ImageFilter.GaussianBlur(1.2))
    out = Image.new("RGBA", big.size, (255, 255, 255, 0))
    out.putalpha(edge)
    out.alpha_composite(big)
    return out


def is_transparent(im):
    if im.mode != "RGBA":
        return False
    return im.getchannel("A").histogram()[0] > im.size[0] * im.size[1] * 0.05


def import_one(path, name):
    folder, size, cutout = TARGETS[name]
    im = Image.open(path)
    note = ""
    if cutout:
        if is_transparent(im):
            im = im.convert("RGBA")
        else:
            # Temizleme büyük resimde yavaştır; önce hedefe yakın boyuta küçült.
            im.thumbnail((int(size * 1.25), int(size * 1.25)), Image.LANCZOS)
            im = remove_baked_background(im, keep_all=name in WIDE)
            note = " (arka plan temizlendi)"
        # Görünen kısma kırp, kareye ortala, kenarda küçük boşluk bırak.
        box = im.getchannel("A").point(lambda v: 255 if v > 16 else 0).getbbox()
        im = im.crop(box)
        if note and folder == "stickers":
            im = add_sticker_border(im)
        if name not in WIDE:
            side = int(max(im.size) * 1.06)
            square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
            square.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
            im = square
    else:
        im = im.convert("RGB")
    if max(im.size) > size:
        im.thumbnail((size, size), Image.LANCZOS)
    dest = os.path.join(ROOT, folder, f"{name}.png")
    im.save(dest, optimize=True)
    print(f"  {folder}/{name}.png {im.size[0]}x{im.size[1]}{note}")


def main():
    source = sys.argv[1]
    found = set()
    for file in sorted(os.listdir(source)):
        name, ext = os.path.splitext(file)
        if ext.lower() in EXTENSIONS and name in TARGETS:
            import_one(os.path.join(source, file), name)
            found.add(name)
    missing = [n for n in TARGETS if not os.path.exists(os.path.join(ROOT, TARGETS[n][0], n + ".png"))]
    print(f"\n{len(found)} görsel aktarıldı. Henüz eksik olan {len(missing)} görsel:")
    print("  " + ", ".join(missing))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
