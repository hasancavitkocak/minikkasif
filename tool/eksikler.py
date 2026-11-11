"""Eksik görsellerin ve seslendirmelerin listesini yeniler.

Kullanım: python tool/eksikler.py

docs/gorsel-promptlari.md içindeki her görselin oyuna aktarılıp aktarılmadığına
bakar; yalnızca eksik olanların prompt'larını docs/eksik-gorseller.md dosyasına
yazar. Ayrıca Fıstık'ın seslendirilecek cümlelerini docs/seslendirme.md
dosyasına, kaydı gelmiş olanları işaretleyerek yazar.
"""
import os
import re
import sys

from import_images import TARGETS

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
IMAGES = os.path.join(BASE, "assets", "images")
VOICE = os.path.join(BASE, "assets", "audio", "voice")

# Oyunda bir sürümü var ama yenisi bekleniyor: ad -> neden.
REDO = {}

# Seslendirilecek cümleler, kayıt sırasıyla.
VOICE_KEYS = [
    ("Tanışma konuşması (ilk açılışta, sırayla)", ["intro_1", "intro_2", "intro_3", "intro_4"]),
    ("Ana ekran ve bölüm haritası", ["pick_game", "pick_level"]),
    ("Bölüm sonu (övgülerden rastgele biri; çıkartma kazanılınca ardından ikinci cümle)", ["praise_1", "praise_2", "praise_3", "praise_4", "new_sticker"]),
    ("Oyun yönergeleri", None),  # i_ ile başlayan tüm anahtarlar
    ("Günün macerası", ["daily_bubble", "daily_done"]),
    ("Etkinlikler ve belge", ["scene_hint", "music_follow", "wardrobe_hint", "cert_title"]),
    ("Sayılar (sayma oyununda doğru yanıt okunur)", [f"num_{n}" for n in range(1, 11)]),
]


def exists(name):
    if name.startswith("color_"):
        return os.path.exists(os.path.join(IMAGES, "coloring", name[6:] + ".json"))
    if name in TARGETS:
        return os.path.exists(os.path.join(IMAGES, TARGETS[name][0], name + ".png"))
    return False


def missing_images():
    doc = open(os.path.join(BASE, "docs", "gorsel-promptlari.md"), encoding="utf-8").read()
    out = [
        "# Eksik görseller",
        "",
        "Bu dosya `python tool/eksikler.py` ile otomatik yenilenir; elle düzenlemeyin.",
        "Yalnızca oyunda henüz olmayan (ya da yenisi beklenen) görsellerin prompt'ları vardır.",
        "Tam liste: [gorsel-promptlari.md](gorsel-promptlari.md).",
        "",
        "Üretilen dosyayı başlıktaki adla kaydedip Downloads klasörüne koymanız yeterli.",
        "",
    ]
    count = 0
    section = None
    for part in re.split(r"^(?=## |### )", doc, flags=re.M):
        if part.startswith("## "):
            section = part.splitlines()[0]
            printed = False
            continue
        m = re.match(r"### (\d+)\. `(\w+)\.png`\n\n```\n(.*?)\n```", part, re.S)
        if not m:
            continue
        number, name, prompt = m.groups()
        if exists(name) and name not in REDO:
            continue
        if not printed:
            out += [section, ""]
            printed = True
        out += [f"### {number}. `{name}.png`", ""]
        if name in REDO:
            out += [REDO[name], ""]
        out += ["```", prompt, "```", ""]
        count += 1
    if count == 0:
        out += ["Eksik görsel yok.", ""]
    out.insert(2, f"**{count} görsel eksik.**")
    out.insert(3, "")
    with open(os.path.join(BASE, "docs", "eksik-gorseller.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))
    return count


def voice_lines():
    src = open(os.path.join(BASE, "lib", "l10n.dart"), encoding="utf-8").read()
    tr = src[src.index("'tr': {"):src.index("'en': {")]
    table = {}
    for key, _, text in re.findall(r"^\s+'([a-z_0-9]+)':\s*\n?\s*([\"'])(.*)\2,$", tr, re.M):
        table[key] = text
    for i, text in enumerate(table["praise"].split("|")):
        table[f"praise_{i + 1}"] = text
    for n in range(1, 11):
        table[f"num_{n}"] = str(n)

    def recorded(key):
        folder = os.path.join(VOICE, "tr")
        return any(os.path.exists(os.path.join(folder, f"{key}.{ext}")) for ext in ("mp3", "m4a", "wav", "ogg"))

    out = [
        "# Fıstık'ın seslendirmeleri",
        "",
        "Bu dosya `python tool/eksikler.py` ile otomatik yenilenir.",
        "",
        "Her cümle ayrı bir ses dosyası olarak kaydedilir ve tablodaki adla",
        "`assets/audio/voice/tr/` klasörüne konur (örnek: `intro_1.mp3`).",
        "Kaydı olan cümle o sesle, olmayan cümle cihazın metin okuma sesiyle okunur;",
        "yani kayıtlar parça parça eklenebilir.",
        "",
        "- Biçim: MP3 (tercih), M4A, WAV ya da OGG; tek kanal yeterli.",
        "- Başta ve sonda boşluk bırakmayın, cümle hemen başlasın.",
        "- Hepsi aynı ses, aynı uzaklık ve aynı ses düzeyinde olsun.",
        "- Başka diller için aynı adlar `assets/audio/voice/en/`, `de/`, `fr/`, `es/`, `ar/` klasörlerine konur.",
        "",
    ]
    total = done = 0
    for title, keys in VOICE_KEYS:
        if keys is None:
            keys = [k for k in table if k.startswith("i_")]
        out += [f"## {title}", "", "| Dosya adı | Cümle | Kayıt |", "|---|---|---|"]
        for key in keys:
            ok = recorded(key)
            total += 1
            done += ok
            out.append(f"| `{key}.mp3` | {table[key]} | {'var' if ok else '—'} |")
        out.append("")
    out.insert(2, f"**{total} cümlenin {done} tanesi kayıtlı.**")
    out.insert(3, "")
    with open(os.path.join(BASE, "docs", "seslendirme.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))
    return total, done


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    print(f"Eksik görsel: {missing_images()} -> docs/eksik-gorseller.md")
    total, done = voice_lines()
    print(f"Seslendirme: {done}/{total} kayıtlı -> docs/seslendirme.md")
