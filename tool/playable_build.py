"""Reklam için oynanabilir mini oyunu (playable ad) üretir.

Kullanım:
    python tool/playable_build.py [mağaza_adresi]

tool/playable/template.html şablonundaki görselleri ve yazı tipini dosyanın
içine gömer (reklam ağları dışarıdan dosya yüklemeye izin vermez) ve
build/playable/ klasörüne şunları yazar:

  minikkasif_meta.html     Meta (Facebook, Instagram): tek HTML dosyası.
  minikkasif_google.zip    Google Ads uygulama kampanyası: içinde index.html.
  minikkasif_mraid.html    AppLovin, Unity, ironSource, Mintegral gibi ağlar.
  minikkasif_onizleme.html Tarayıcıda denemek için; düğme bir yere gitmez.

mağaza_adresi yalnızca MRAID dosyasında kullanılır (öbür ağlar tıklamayı
kampanyada tanımlı adrese kendileri yönlendirir).
"""
import base64
import io
import json
import os
import sys
import zipfile

from PIL import Image

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
IMAGES = os.path.join(BASE, "assets", "images")
OUT = os.path.join(BASE, "build", "playable")
LIMIT = 2 * 1024 * 1024  # En katı ağ (Meta) 2 MB istiyor; hepsi bunun altında.

# ad -> (dosya, en uzun kenar, biçim)
ASSETS = {
    "bg": ("bg/bg_meadow.png", 960, "JPEG"),
    "logo": ("ui/logo.png", 640, "WEBP"),
    "fox_hello": ("mascot/fox_hello.png", 320, "WEBP"),
    "fox_happy": ("mascot/fox_happy.png", 320, "WEBP"),
    "star_full": ("ui/star_full.png", 96, "WEBP"),
    "star_empty": ("ui/star_empty.png", 96, "WEBP"),
    "lion": ("objects/lion.png", 256, "WEBP"),
    "elephant": ("objects/elephant.png", 256, "WEBP"),
    "bird": ("objects/bird.png", 256, "WEBP"),
    "cat": ("objects/cat.png", 256, "WEBP"),
    "frog": ("objects/frog.png", 256, "WEBP"),
    "rabbit": ("objects/rabbit.png", 256, "WEBP"),
    "dog": ("objects/dog.png", 256, "WEBP"),
}


def data_uri(path, size, fmt):
    im = Image.open(os.path.join(IMAGES, path))
    im.thumbnail((size, size))
    buf = io.BytesIO()
    if fmt == "JPEG":
        im.convert("RGB").save(buf, "JPEG", quality=72, optimize=True)
        mime = "image/jpeg"
    else:
        im.save(buf, "WEBP", quality=80, method=6)
        mime = "image/webp"
    return f"data:{mime};base64," + base64.b64encode(buf.getvalue()).decode()


def build(store_url):
    template = open(os.path.join(BASE, "tool", "playable", "template.html"), encoding="utf-8").read()
    images = {name: data_uri(*spec) for name, spec in ASSETS.items()}
    font = base64.b64encode(open(os.path.join(BASE, "assets", "fonts", "Baloo2-800.ttf"), "rb").read()).decode()
    page = template.replace("{{FONT}}", font).replace("{{IMAGES_JSON}}", json.dumps(images))
    for name, uri in images.items():
        page = page.replace("{{IMG_" + name + "}}", uri)
    assert "{{IMG_" not in page

    variants = {
        "meta": ("", "if (window.FbPlayableAd) FbPlayableAd.onCTAClick();"),
        "google": (
            '<meta name="ad.orientation" content="portrait,landscape">\n'
            '<script src="https://tpc.googlesyndication.com/pagead/gadgets/html5/api/exitapi.js"></script>',
            "if (window.ExitApi) ExitApi.exit();",
        ),
        "mraid": (
            '<script src="mraid.js"></script>',
            f'var u = {json.dumps(store_url)}; if (window.mraid && mraid.open) mraid.open(u); else window.open(u, "_blank");',
        ),
        "onizleme": ("", 'document.getElementById("cta").textContent = "✓ Mağaza açılırdı";'),
    }
    os.makedirs(OUT, exist_ok=True)
    for name, (head, cta) in variants.items():
        html = page.replace("{{HEAD}}", head).replace("{{CTA}}", cta)
        if name == "google":
            path = os.path.join(OUT, "minikkasif_google.zip")
            with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
                z.writestr("index.html", html)
        else:
            path = os.path.join(OUT, f"minikkasif_{name}.html")
            with open(path, "w", encoding="utf-8", newline="\n") as f:
                f.write(html)
        size = os.path.getsize(path)
        assert size < LIMIT, (path, size)
        print(f"  {os.path.basename(path)}: {size / 1024:.0f} KB")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    build(sys.argv[1] if len(sys.argv) > 1 else "https://apps.apple.com/app/idXXXXXXXXXX")
