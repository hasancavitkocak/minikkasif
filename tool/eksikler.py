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

# Türkçe alfabe ve harflerin kayıt adları (lib/games/letters_game.dart ile aynı).
LETTERS = "abcçdefgğhıijklmnoöprsştuüvyz"
LETTER_FILE = {"ç": "cc", "ğ": "gg", "ı": "ii", "ö": "oo", "ş": "ss", "ü": "uu"}
LETTER_KEYS = [f"let_{LETTER_FILE.get(ch, ch)}" for ch in LETTERS]


def story_pages():
    """lib/data/stories.dart içindeki Türkçe sayfa metinleri: ad -> cümle."""
    src = open(os.path.join(BASE, "lib", "data", "stories.dart"), encoding="utf-8").read()
    pages = {}
    for block in src.split("  Story(\n")[1:]:
        story = re.match(r"\s*'(\w+)'", block).group(1)
        texts = re.findall(r"'tr':\s*\n?\s*\"(.*?)\",\n", block)
        # İlk Türkçe satır hikâyenin adıdır.
        for i, text in enumerate(texts[1:], 1):
            pages[f"story_{story}_{i}"] = text
    return pages


STORY_KEYS = list(story_pages())

# Seslendirilecek cümleler, kayıt sırasıyla.
VOICE_KEYS = [
    ("Tanışma konuşması (ilk açılışta, sırayla)", ["intro_1", "intro_2", "intro_3", "intro_4"]),
    ("Ana ekran ve bölüm haritası", ["pick_game", "pick_level"]),
    ("Oyun adları (oyuna girince okunur)", ["g_shapes", "g_memory", "g_shadow", "g_count", "g_pattern", "g_odd", "g_puzzle", "g_sort", "g_maze", "g_color", "g_groups", "g_simon", "g_diff", "g_dots", "g_jobs", "g_seasons", "g_clock", "g_letters", "g_scene", "g_duel", "g_music", "g_wardrobe", "g_story"]),
    ("Bölüm sonu (övgülerden rastgele biri)", ["praise_1", "praise_2", "praise_3", "praise_4"]),
    ("Oyun yönergeleri", None),  # i_ ile başlayan tüm anahtarlar
    ("Günün macerası", ["daily_bubble", "daily_done"]),
    ("Etkinlikler ve belge", ["scene_hint", "music_follow", "wardrobe_hint", "cert_title"]),
    ("Meslekler: her mesleğin adı ve tanıtım cümlesi (ayrı dosyalar)", ['job_firefighter', 'job_firefighter_d', 'job_doctor', 'job_doctor_d', 'job_cook', 'job_cook_d', 'job_teacher', 'job_teacher_d', 'job_builder', 'job_builder_d', 'job_painter', 'job_painter_d', 'job_postman', 'job_postman_d', 'job_pilot', 'job_pilot_d', 'job_farmer', 'job_farmer_d', 'job_astronaut', 'job_astronaut_d']),
    ("Mevsimler: her mevsimin adı ve tanıtım cümlesi (ayrı dosyalar)", ['season_spring', 'season_spring_d', 'season_summer', 'season_summer_d', 'season_autumn', 'season_autumn_d', 'season_winter', 'season_winter_d']),
    ("Hikâyeler ekranı", ["story_hint", "story_end"]),
    ("Sayılar (sayma ve saat oyunlarında okunur)", [f"num_{n}" for n in range(1, 13)]),
    ("Harfler (harfin okunuşu: \"a\", \"be\", \"ce\"...)", LETTER_KEYS),
    ("Hikâye sayfaları (her sayfa ayrı dosya)", STORY_KEYS),
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


def voice_table():
    """Seslendirilecek her cümle: kayıt adı -> Türkçe metin."""
    src = open(os.path.join(BASE, "lib", "l10n.dart"), encoding="utf-8").read()
    tr = src[src.index("'tr': {"):src.index("'en': {")]
    table = {}
    for key, _, text in re.findall(r"^\s+'([a-z_0-9]+)':\s*\n?\s*([\"'])(.*)\2,$", tr, re.M):
        table[key] = text
    for i, text in enumerate(table["praise"].split("|")):
        table[f"praise_{i + 1}"] = text
    for n in range(1, 13):
        table[f"num_{n}"] = str(n)
    for ch, key in zip(LETTERS, LETTER_KEYS):
        table[key] = ch.upper() if ch not in "ıi" else ("I" if ch == "ı" else "İ")
    table.update(story_pages())
    return table


def recorded(key):
    folder = os.path.join(VOICE, "tr")
    return any(os.path.exists(os.path.join(folder, f"{key}.{ext}")) for ext in ("mp3", "m4a", "wav", "ogg"))


def voice_sections(table):
    """Bölüm başlıkları ve o bölümdeki kayıt adları, kayıt sırasıyla."""
    return [
        (title, [k for k in table if k.startswith("i_")] if keys is None else keys)
        for title, keys in VOICE_KEYS
    ]


def voice_lines():
    table = voice_table()
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
        "- Başka diller için aynı adlar `assets/audio/voice/en/`, `de/`, `fr/`, `es/` klasörlerine konur.",
        "- Toplu kayıt için: [ses-gruplari.md](ses-gruplari.md) (yalnızca eksik cümleler, grup grup).",
        "",
    ]
    total = done = 0
    for title, keys in voice_sections(table):
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
