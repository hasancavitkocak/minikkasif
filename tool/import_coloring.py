"""Renkli üretilmiş boyama resimlerini oyunun boyanabilir biçimine çevirir.

Kullanım: python tool/import_coloring.py <kaynak_klasör> [önizleme_klasörü]

Kaynak klasördeki `color_<ad>` resimlerini (PNG, JPEG, WebP) okur (docs/gorsel-promptlari.md,
M bölümü). Her resim için assets/images/coloring/ altına şu dosyaları yazar:

  <ad>_lines.png  çizgiler ve boyanmayan minik ayrıntılar (şeffaf zemin)
  <ad>_map.png    bölge haritası: piksel değeri = bölge numarası + 1, 0 = boş
  <ad>_r<n>.png   n numaralı bölgenin boyama maskesi
  <ad>.json       her bölgenin örnekteki rengi (oyun paletindeki sırası) ve yeri

Önizleme klasörü verilirse, bölgelerin nasıl ayrıldığını gösteren bir kontrol
resmi de oraya yazılır.
"""
import colorsys
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "images", "coloring")
SIZE = 512
NAMES = ["balloons", "fish", "flower", "butterfly", "house", "car", "boat", "rocket", "turtle", "train"]

# Oyun paleti (lib/games/coloring_game.dart ile aynı sıra) ve yaklaşık renk tonları.
PALETTE = ["red", "orange", "yellow", "green", "blue", "purple", "pink", "brown", "teal"]
# Kaynak resimler yalnızca ilk altı renkle üretilir; tonlarına göre tanınır.
HUES = [0, 28, 55, 125, 215, 275]
PALETTE_RGB = [
    (255, 107, 107), (255, 159, 67), (255, 211, 78), (76, 208, 128), (77, 166, 255), (155, 123, 255),
    (255, 126, 182), (185, 128, 82), (46, 196, 182),
]

# Resimler hep aynı altı renkle üretildiği için birbirine benzemesin diye,
# oyunda görünecek renkler burada resim resim seçilir: kaynak renk -> oyun rengi.
RECOLOR = {
    "balloons": {"blue": "teal"},
    "fish": {"blue": "teal", "red": "pink"},
    "flower": {"red": "pink"},
    "butterfly": {"purple": "pink", "orange": "brown", "blue": "teal"},
    "house": {"orange": "brown", "blue": "brown", "purple": "blue"},
    "car": {"blue": "teal", "purple": "brown"},
    "boat": {"red": "brown", "purple": "pink", "green": "red"},
    "rocket": {"purple": "red", "yellow": "teal"},
    "turtle": {"purple": "brown"},
    "train": {"purple": "pink", "orange": "brown"},
}
INK = (74, 55, 40)

DETAIL_AREA = 0.0012  # bundan küçük parçalar boyanmaz, çizgi katmanında kalır
SMALL_AREA = 0.02  # bundan küçük parça, yakınındaki aynı renkli bölgeye katılır
MIN_REGION = 0.004  # tek başına kalan parça parmakla boyanabilecek kadar büyük olmalı


def components(mask):
    """4 komşuluklu bağlı bileşenler. 0 = maske dışı, 1..n = bileşenler."""
    h, w = mask.shape
    label = np.where(mask, np.arange(1, h * w + 1).reshape(h, w), 0)
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
    ids = np.unique(label)
    ids = ids[ids > 0]
    out = np.zeros_like(label)
    for i, v in enumerate(ids):
        out[label == v] = i + 1
    return out, len(ids)


def dilate(mask, radius):
    im = Image.fromarray((mask * 255).astype(np.uint8))
    return np.asarray(im.filter(ImageFilter.MaxFilter(radius * 2 + 1))) > 0


def classify(rgb):
    """Ortalama rengi palet sırasına çevirir; beyaz/gri için -1."""
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    if s < 0.25:
        return -1
    deg = h * 360
    dist = [min(abs(deg - x), 360 - abs(deg - x)) for x in HUES]
    return int(np.argmin(dist))


def trace_outline(shape):
    """Şeklin dış sınırını saat yönünde, sırayla dolaşır (Moore komşuluğu)."""
    h, w = shape.shape
    padded = np.zeros((h + 2, w + 2), dtype=bool)
    padded[1:-1, 1:-1] = shape
    ys, xs = np.where(padded)
    start = (int(ys.min()), int(xs[ys == ys.min()].min()))
    # Saat yönünde sekiz komşu: batıdan başlar.
    ring = [(0, -1), (-1, -1), (-1, 0), (-1, 1), (0, 1), (1, 1), (1, 0), (1, -1)]
    points = [start]
    current, back = start, 0
    for _ in range(4 * (h + w) * 4):
        for k in range(8):
            d = (back + k) % 8
            ny, nx = current[0] + ring[d][0], current[1] + ring[d][1]
            if padded[ny, nx]:
                current = (ny, nx)
                # Bir sonraki arama, geldiğimiz yönün gerisinden başlar.
                back = (d + 5) % 8
                break
        else:
            break
        if current == start:
            break
        points.append(current)
    return np.array([(x - 1, y - 1) for y, x in points], dtype=float)


def pick_dots(outline, count, min_gap):
    """Dış çizgi üstünde şekli en iyi anlatan [count] noktayı seçer."""
    n = len(outline)
    # En uzak iki noktayla başla, sonra her adımda çizgiden en çok sapan noktayı ekle.
    first = int(np.argmin(outline[:, 1]))
    far = int(np.argmax(((outline - outline[first]) ** 2).sum(axis=1)))
    chosen = sorted({first, far})
    while len(chosen) < count:
        best, best_score = None, -1.0
        for a, b in zip(chosen, chosen[1:] + [chosen[0] + n]):
            idx = np.arange(a + 1, b) % n
            if len(idx) == 0:
                continue
            p, q = outline[a % n], outline[b % n]
            seg = q - p
            length = np.hypot(*seg) or 1.0
            pts = outline[idx]
            dist = np.abs(seg[0] * (pts[:, 1] - p[1]) - seg[1] * (pts[:, 0] - p[0])) / length
            # Parmakla ayırt edilemeyecek kadar yakın noktalar seçilmez.
            gaps = np.min(np.hypot(pts[:, None, 0] - outline[chosen][None, :, 0], pts[:, None, 1] - outline[chosen][None, :, 1]), axis=1)
            dist = np.where(gaps < min_gap, -1, dist + 0.02 * gaps)
            k = int(np.argmax(dist))
            if dist[k] > best_score:
                best, best_score = int(idx[k]), float(dist[k])
        if best is None or best_score < 0:
            break
        chosen = sorted(set(chosen) | {best})
    # Sıra en üstteki noktadan başlar.
    top = min(chosen, key=lambda i: (outline[i][1], outline[i][0]))
    k = chosen.index(top)
    return [outline[i] for i in chosen[k:] + chosen[:k]]


def convert(path, name, preview_dir):
    src = Image.open(path).convert("RGB")
    # Çizimin kapladığı alana kırp, kareye ortala.
    grey = np.asarray(src).min(axis=2)
    ys, xs = np.where(grey < 235)
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    cut = src.crop(box)
    side = int(max(cut.size) * 1.04)
    square = Image.new("RGB", (side, side), (255, 255, 255))
    square.paste(cut, ((side - cut.width) // 2, (side - cut.height) // 2))
    im = square.resize((SIZE, SIZE), Image.LANCZOS)
    rgb = np.asarray(im).astype(np.int32)
    brightest = rgb.max(axis=2)

    darkest = rgb.min(axis=2)
    line = brightest < 110
    white = (darkest >= 200) & (brightest - darkest <= 40)
    # Beyaz zemin de çizgi gibi ayırıcıdır: dış çizgisi eksik kalmış renkli
    # alanlar (resmin kenarında kesilen çimen gibi) zemine karışmaz.
    label, count = components(~line & ~white)
    total = SIZE * SIZE

    parts = []  # (bileşen no, alan, palet sırası)
    detail = np.zeros_like(line)
    for c in range(1, count + 1):
        m = label == c
        area = m.sum() / total
        # Kenar yumuşatmasından etkilenmemek için bileşenin iç kısmının rengine bak.
        inner = m & ~dilate(~m, 2)
        color = classify(rgb[inner if inner.any() else m].mean(axis=0))
        if color < 0:
            continue  # çizgi kenarındaki gri geçiş pikselleri
        if area < DETAIL_AREA:
            detail |= m
        else:
            parts.append((c, area, color))

    def center(c):
        ys, xs = np.where(label == c)
        return np.array([ys.mean(), xs.mean()])

    # Küçük parçayı (balon düğümü gibi) aynı renkli daha büyük bir bölgeye kat:
    # önce hemen yanındakine, parmakla boyanamayacak kadar küçükse en yakındakine.
    parts.sort(key=lambda p: -p[1])
    group = {}  # bileşen no -> bölge sırası
    regions = []  # palet sırası
    notes = []
    for c, area, color in parts:
        target = None
        same = [c2 for c2, area2, color2 in parts if c2 != c and color2 == color and area2 > area and c2 in group]
        if area < SMALL_AREA:
            near = dilate(label == c, 16)
            for c2 in same:
                if (near & (label == c2)).any():
                    target = group[c2]
                    break
        if target is None and area < MIN_REGION:
            if not same:
                notes.append(f"çok küçük bölge (%{area * 100:.2f}) boyanmaz bırakıldı")
                detail |= label == c
                continue
            here = center(c)
            target = group[min(same, key=lambda c2: np.linalg.norm(center(c2) - here))]
        if target is None:
            target = len(regions)
            regions.append(color)
        group[c] = target

    swap = RECOLOR.get(name, {})
    regions = [PALETTE.index(swap.get(PALETTE[c], PALETTE[c])) for c in regions]

    region_map = np.zeros((SIZE, SIZE), dtype=np.uint8)
    for c, r in group.items():
        region_map[label == c] = r + 1
    painted = region_map > 0
    # Bölgeleri çizgilerin altına doğru birkaç piksel büyüt ki arada boşluk kalmasın.
    solid_line = brightest < 60
    for _ in range(5):
        grown = np.asarray(Image.fromarray(region_map).filter(ImageFilter.MaxFilter(3)))
        region_map = np.where((region_map == 0) & solid_line, grown, region_map)

    # Çizgi katmanı: koyu pikseller mürekkep renginde, minik ayrıntılar özgün renginde.
    alpha = np.clip((150 - brightest) / 100, 0, 1)
    # Koyu renkli dolguların içi çizgi sayılmasın.
    alpha[painted & ~dilate(line, 1)] = 0
    # Dış çizgisi olmayan kenarlara çizgi ekle.
    alpha[dilate(painted, 3) & white] = 1
    lines = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    lines[..., :3] = INK
    lines[..., 3] = (alpha * 255).astype(np.uint8)
    keep = dilate(detail, 1) & ~line
    lines[keep, :3] = rgb[keep]
    lines[keep, 3] = 255

    os.makedirs(ROOT, exist_ok=True)
    Image.fromarray(lines).save(os.path.join(ROOT, f"{name}_lines.png"), optimize=True)
    Image.fromarray(region_map).save(os.path.join(ROOT, f"{name}_map.png"), optimize=True)
    # Her bölgenin boyanacak maskesi: beyaz, yalnızca kendi alanında opak.
    for old in os.listdir(ROOT):
        if old.startswith(f"{name}_r") and old.endswith(".png"):
            os.remove(os.path.join(ROOT, old))
    boxes = []
    for r in range(len(regions)):
        m = region_map == r + 1
        ys, xs = np.where(m)
        x0, y0, x1, y1 = int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
        mask = np.full((y1 - y0, x1 - x0, 4), 255, dtype=np.uint8)
        mask[..., 3] = m[y0:y1, x0:x1] * 255
        Image.fromarray(mask).save(os.path.join(ROOT, f"{name}_r{r}.png"), optimize=True)
        boxes.append([x0, y0, x1 - x0, y1 - y0])
    # "Noktaları birleştir" oyunu için resmin dış çizgisinden nokta dizileri.
    sil_label, sil_count = components(line | painted | detail)
    sizes = [(sil_label == c).sum() for c in range(1, sil_count + 1)]
    outline = trace_outline(sil_label == int(np.argmax(sizes)) + 1)
    dots = {}
    for count in range(5, 15):
        picked = pick_dots(outline, count, SIZE * 0.11)
        if len(picked) >= 4:
            dots[str(len(picked))] = [[round(float(x) / SIZE, 4), round(float(y) / SIZE, 4)] for x, y in picked]
    with open(os.path.join(ROOT, f"{name}.json"), "w", encoding="utf-8") as f:
        json.dump({"size": SIZE, "colors": regions, "boxes": boxes, "dots": dots}, f)

    print(f"  {name}: {len(regions)} bölge -> " + ", ".join(PALETTE[c] for c in regions))
    for note in notes:
        print(f"    not: {note}")
    if len(set(regions)) < 2:
        print("    UYARI: tek renk bulundu, resmi kontrol edin")

    if preview_dir:
        # Sol: boyanmamış sayfa. Sağ: oyunun göstereceği boyanmış örnek.
        sheet = Image.new("RGB", (SIZE * 2 + 30, SIZE + 20), (255, 255, 255))
        line_im = Image.fromarray(lines)
        painted = np.full((SIZE, SIZE, 3), 255, dtype=np.uint8)
        for r, color in enumerate(regions):
            painted[region_map == r + 1] = PALETTE_RGB[color]
        blank = Image.new("RGB", (SIZE, SIZE), (255, 255, 255))
        blank.paste(line_im, (0, 0), line_im)
        full = Image.fromarray(painted)
        full.paste(line_im, (0, 0), line_im)
        draw = ImageDraw.Draw(blank)
        if dots:
            pts = [(x * SIZE, y * SIZE) for x, y in dots[max(dots, key=int)]]
            draw.line(pts + [pts[0]], fill=(255, 80, 80), width=3)
            for i, (x, y) in enumerate(pts):
                draw.ellipse((x - 11, y - 11, x + 11, y + 11), fill=(255, 211, 78), outline=(74, 55, 40), width=2)
                draw.text((x - 4, y - 6), str(i + 1), fill=(0, 0, 0))
        sheet.paste(blank, (10, 10))
        sheet.paste(full, (SIZE + 20, 10))
        sheet.save(os.path.join(preview_dir, f"coloring_{name}.png"))


def main():
    source = sys.argv[1]
    preview_dir = sys.argv[2] if len(sys.argv) > 2 else None
    done = 0
    for name in NAMES:
        for ext in (".png", ".jpg", ".jpeg", ".jfif", ".webp"):
            path = os.path.join(source, f"color_{name}{ext}")
            if os.path.exists(path):
                convert(path, name, preview_dir)
                done += 1
                break
    missing = [n for n in NAMES if not os.path.exists(os.path.join(ROOT, f"{n}.json"))]
    print(f"\n{done} boyama resmi aktarıldı. Henüz eksik olan {len(missing)} resim:")
    print("  " + ", ".join(f"color_{n}" for n in missing))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
