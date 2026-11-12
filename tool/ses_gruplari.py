"""Eksik seslendirmeleri toplu kayıt için gruplar ve toplu kayıtları böler.

Grupları hazırla (yalnızca eksik cümleler):
    python tool/ses_gruplari.py
  -> docs/ses-gruplari.md   : her grubun okunacak metni, cümleler arasında
                              duraklama işaretiyle
  -> tool/ses_gruplari.json : her gruptaki kayıt adları, sırayla

Kaydedilen grupları böl ve oyuna aktar:
    python tool/ses_gruplari.py bol <klasör>
  Klasördeki grup01.mp3, grup02.mp3 ... dosyalarını sessizliklerden cümlelere
  ayırır ve assets/audio/voice/tr/ içine doğru adlarla yazar. Bir grupta
  cümle sayısı tutmazsa o grup aktarılmaz, bildirilir.

Bölme için ffmpeg gerekir: PATH'te, FFMPEG ortam değişkeninde ya da
D:\\tools\\ffmpeg altında aranır.
"""
import glob
import json
import os
import re
import shutil
import subprocess
import sys

from eksikler import BASE, LETTERS, LETTER_KEYS, VOICE, recorded, voice_sections, voice_table

GROUPS_JSON = os.path.join(BASE, "tool", "ses_gruplari.json")
GROUPS_DOC = os.path.join(BASE, "docs", "ses-gruplari.md")

# Cümleler arasındaki duraklama. Seslendirme aracı bu işareti okumaz, susar.
# Eleven v3: tek işaret kısa kalıyor, iki işaret yaklaşık 0,7-1 sn susturuyor.
BREAK = "[long pause] [long pause]"
GROUP_SIZE = 10

NUMBER_WORDS = ["bir", "iki", "üç", "dört", "beş", "altı", "yedi", "sekiz", "dokuz", "on", "on bir", "on iki"]
LETTER_NAMES = {
    "a": "a", "b": "be", "c": "ce", "ç": "çe", "d": "de", "e": "e", "f": "fe", "g": "ge",
    "ğ": "yumuşak ge", "h": "he", "ı": "ı", "i": "i", "j": "je", "k": "ke", "l": "le",
    "m": "me", "n": "ne", "o": "o", "ö": "ö", "p": "pe", "r": "re", "s": "se", "ş": "şe",
    "t": "te", "u": "u", "ü": "ü", "v": "ve", "y": "ye", "z": "ze",
}


def spoken_text(key, table):
    """Seslendirme aracına yazılacak metin: sayılar ve harfler okunuşuyla."""
    if key.startswith("num_"):
        return NUMBER_WORDS[int(key[4:]) - 1].capitalize() + "."
    if key in LETTER_KEYS:
        # Tek başına "Ce." yazılınca ses bunu İngilizce okuyabiliyor ("si").
        # "harfi" sözcüğü cümleyi Türkçe yapar. ı ve i küçük yazılır ki
        # birbirine karışmasın.
        name = LETTER_NAMES[LETTERS[LETTER_KEYS.index(key)]]
        return (name if name in "ıi" else name.capitalize()) + " harfi."
    text = table[key]
    # Sonda nokta olunca ses cümleyi bitirir, sonraki cümleye bağlamaz.
    return text if text[-1] in ".!?" else text + "."


def make_groups():
    table = voice_table()
    groups = []
    for title, keys in voice_sections(table):
        missing = [k for k in keys if not recorded(k)]
        # Bölüm eşit büyüklükte gruplara ayrılır; en çok GROUP_SIZE cümle.
        count = -(-len(missing) // GROUP_SIZE)
        for g in range(count):
            size = -(-len(missing) // count)
            groups.append((title, missing[g * size:(g + 1) * size]))
    # Birkaç cümlelik küçük gruplar tek grupta toplanır: daha az dosya.
    small = [g for g in groups if len(g[1]) < 4]
    if len(small) > 1:
        groups = [g for g in groups if len(g[1]) >= 4]
        merged = [k for _, keys in small for k in keys]
        for i in range(0, len(merged), GROUP_SIZE):
            groups.append(("Diğer kısa cümleler", merged[i:i + GROUP_SIZE]))
    names = {f"grup{i + 1:02d}": keys for i, (_, keys) in enumerate(groups)}
    with open(GROUPS_JSON, "w", encoding="utf-8", newline="\n") as f:
        json.dump(names, f, ensure_ascii=False, indent=1)

    total = sum(len(k) for k in names.values())
    out = [
        "# Toplu ses kaydı grupları",
        "",
        f"**{total} eksik cümle, {len(names)} grup.** Yalnızca kaydı olmayan cümleler vardır.",
        "",
        "Bu dosya `python tool/ses_gruplari.py` ile yenilenir; elle düzenlemeyin.",
        "",
        "Nasıl kullanılır:",
        "",
        "1. Bir grubun kutusundaki metnin tamamını kopyalayıp seslendirme aracına yapıştırın.",
        f"2. Metindeki `{BREAK}` işaretlerine dokunmayın: araç orada susar,",
        "   cümleler o sessizliklerden ayrılır.",
        "3. Çıkan tek ses dosyasını başlıktaki adla (örnek: `grup01.mp3`) Downloads klasörüne kaydedin.",
        "4. Hepsi aynı ses ve aynı ayarlarla üretilsin.",
        "",
        "Metin ElevenLabs'in **Eleven v3** modeli içindir: duraklama o modelde",
        f"`{BREAK}` işaretiyle yapılır. (Multilingual v2 kullanılırsa işaret",
        '`<break time="2.5s" />` olmalıdır; haber verin, metni ona göre yazarım.)',
        "",
        "Bir grupta cümle atlanır ya da fazladan duraklama olursa o grup aktarılmaz;",
        "hangi grup olduğu size bildirilir ve yalnızca o yeniden üretilir.",
        "",
    ]
    last = None
    for (title, keys), name in zip(groups, names):
        if title != last:
            out += [f"## {title}", ""]
            last = title
        out += [f"### `{name}.mp3` ({len(keys)} cümle)", "", "```"]
        out += [f" {BREAK}\n".join(spoken_text(k, table) for k in keys)]
        out += ["```", ""]
    with open(GROUPS_DOC, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))
    return total, len(names)


def render_remaining():
    """Belgeyi mevcut gruplardan yeniden yazar: grup numaraları değişmez,
    kaydı tamamlanan gruplar çıkar."""
    table = voice_table()
    groups = json.load(open(GROUPS_JSON, encoding="utf-8"))
    left = {n: k for n, k in groups.items() if not all(recorded(x) for x in k)}
    out = [
        "# Toplu ses kaydı grupları",
        "",
        f"**{sum(len(k) for k in left.values())} eksik cümle, {len(left)} grup.** Kaydı tamamlanan gruplar listeden çıkar; numaralar değişmez.",
        "",
        "Nasıl kullanılır:",
        "",
        "1. Bir grubun kutusundaki metnin tamamını kopyalayıp ElevenLabs'e yapıştırın (model: **Eleven v3**).",
        f"2. Metindeki `{BREAK}` işaretlerine dokunmayın: ses orada susar, cümleler o sessizliklerden ayrılır.",
        "3. Çıkan tek ses dosyasını başlıktaki adla (örnek: `grup02.mp3`) Downloads klasörüne kaydedin.",
        "4. Hepsi aynı ses ve aynı ayarlarla üretilsin.",
        "",
        "Bir grupta cümleler net ayrılamazsa o grup oyuna aktarılmaz; hangisi olduğu",
        "size bildirilir ve yalnızca o yeniden üretilir.",
        "",
        "## Kalan gruplar",
        "",
    ]
    for name, keys in left.items():
        out += [f"### `{name}.mp3` ({len(keys)} cümle)", "", "```"]
        out += [(" " + BREAK + chr(10)).join(spoken_text(k, table) for k in keys)]
        out += ["```", ""]
    with open(GROUPS_DOC, "w", encoding="utf-8", newline=chr(10)) as f:
        f.write(chr(10).join(out))
    return len(left)


def find_ffmpeg():
    for candidate in [os.environ.get("FFMPEG"), shutil.which("ffmpeg")]:
        if candidate and os.path.exists(candidate):
            return candidate
    found = glob.glob(r"D:\tools\ffmpeg*\**\ffmpeg.exe", recursive=True)
    if found:
        return found[0]
    sys.exit("ffmpeg bulunamadı.")


def silences(ffmpeg, path):
    """Dosyadaki sessizlikler [(başlangıç, bitiş)] ve toplam süre."""
    log = subprocess.run(
        [ffmpeg, "-hide_banner", "-nostats", "-i", path, "-af", "silencedetect=noise=-38dB:d=0.2", "-f", "null", "-"],
        capture_output=True, text=True, encoding="utf-8", errors="replace",
    ).stderr
    duration = re.search(r"Duration: (\d+):(\d+):([\d.]+)", log)
    total = int(duration.group(1)) * 3600 + int(duration.group(2)) * 60 + float(duration.group(3))
    starts = [float(x) for x in re.findall(r"silence_start: (-?[\d.]+)", log)]
    ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", log)]
    # Dosya sessizlikle bitiyorsa son sessizliğin bitişi yazılmaz.
    ends += [total] * (len(starts) - len(ends))
    return [(max(0.0, s), e) for s, e in zip(starts, ends)], total


def speech_parts(gaps, total):
    """Sessizliklerin arasındaki konuşma parçaları [(başlangıç, bitiş)]."""
    edges = [0.0] + [x for g in gaps for x in g] + [total]
    parts = [(edges[i], edges[i + 1]) for i in range(0, len(edges), 2)]
    return [(s, e) for s, e in parts if e - s > 0.08]


def by_pauses(parts, count):
    """Cümle araları belirgin biçimde uzunsa (duraklama işareti çalıştıysa)
    parçaları o aralardan [count] cümleye ayırır; değilse None."""
    gaps = [(parts[i + 1][0] - parts[i][1], i) for i in range(len(parts) - 1)]
    if len(gaps) < count - 1:
        return None
    ranked = sorted(gaps, reverse=True)
    chosen = ranked[:count - 1]
    if count > 1:
        shortest = min(g for g, _ in chosen)
        longest_rest = max((g for g, _ in ranked[count - 1:]), default=0.0)
        if shortest < 0.6 or longest_rest > shortest * 0.6:
            return None
    cuts = sorted(i for _, i in chosen)
    bounds = [0] + [i + 1 for i in cuts] + [len(parts)]
    return [parts[bounds[i]:bounds[i + 1]] for i in range(count)]


def by_lengths(parts, weights):
    """Duraklamalar kısaysa: parçaları, her cümlenin beklenen süresine (harf
    sayısına) en iyi uyan biçimde cümlelere dağıtır. Bir cümle birden çok
    parçadan oluşabilir ("Resim ... Çiz"). Sonuç yeterince kesin değilse
    (None, neden) döner."""
    from itertools import combinations

    count = len(weights)
    if len(parts) < count:
        return None, f"{count} cümle bekleniyordu, yalnızca {len(parts)} parça bulundu"
    if len(parts) > count + 8:
        return None, f"{count} cümle için {len(parts)} parça var; çok fazla duraklama"
    lengths = [e - s for s, e in parts]
    rate = sum(lengths) / sum(weights)

    def cost(bounds):
        total = 0.0
        for i in range(count):
            got = sum(lengths[bounds[i]:bounds[i + 1]])
            want = rate * weights[i]
            total += ((got - want) / (want + 0.25)) ** 2
        return total

    scored = sorted(
        (cost([0, *cuts, len(parts)]), cuts)
        for cuts in combinations(range(1, len(parts)), count - 1)
    )
    best, cuts = scored[0]
    if len(scored) > 1 and scored[1][0] < best * 2 + 0.05:
        return None, "cümleler sürelerinden kesin ayrılamadı (iki olası bölme birbirine yakın)"
    if best / count > 0.25:
        return None, "parça süreleri cümle uzunluklarıyla uyuşmuyor"
    bounds = [0, *cuts, len(parts)]
    return [parts[bounds[i]:bounds[i + 1]] for i in range(count)], None


def letters(text):
    return max(1, sum(ch.isalpha() for ch in text))


def split_folder(folder, out_dir=None):
    ffmpeg = find_ffmpeg()
    groups = json.load(open(GROUPS_JSON, encoding="utf-8"))
    table = voice_table()
    out_dir = out_dir or os.path.join(VOICE, "tr")
    done = failed = 0
    for name, keys in groups.items():
        source = next(
            (p for ext in ("mp3", "wav", "m4a", "ogg") if os.path.exists(p := os.path.join(folder, f"{name}.{ext}"))),
            None,
        )
        if source is None:
            continue
        gaps, total = silences(ffmpeg, source)
        parts = speech_parts(gaps, total)
        runs = by_pauses(parts, len(keys))
        how = "duraklamalardan"
        if runs is None:
            runs, problem = by_lengths(parts, [letters(spoken_text(k, table)) for k in keys])
            how = "cümle sürelerinden"
            if runs is None:
                print(f"  {name}: AKTARILMADI - {problem}")
                failed += 1
                continue
        for key, run in zip(keys, runs):
            # Cümle içindeki duraklamalar kısaltılır; baş ve sonda çok kısa bir
            # pay bırakılır ki ses kırpılmasın.
            pieces = [
                (max(0.0, s - 0.04), min(total, e + (0.08 if i == len(run) - 1 else 0.14)))
                for i, (s, e) in enumerate(run)
            ]
            graph = "".join(
                f"[0:a]atrim={s:.3f}:{e:.3f},asetpts=PTS-STARTPTS[p{i}];"
                for i, (s, e) in enumerate(pieces)
            ) + "".join(f"[p{i}]" for i in range(len(pieces))) + f"concat=n={len(pieces)}:v=0:a=1[o]"
            subprocess.run(
                [ffmpeg, "-hide_banner", "-loglevel", "error", "-y", "-i", source,
                 "-filter_complex", graph, "-map", "[o]",
                 "-ac", "1", "-ar", "44100", "-codec:a", "libmp3lame", "-b:a", "96k",
                 os.path.join(out_dir, f"{key}.mp3")],
                check=True,
            )
        print(f"  {name}: {len(keys)} cümle aktarıldı ({how})")
        for key, run in zip(keys, runs):
            length = sum(e - s for s, e in run)
            joined = f", {len(run)} parça birleştirildi" if len(run) > 1 else ""
            print(f"      {length:4.1f} sn  {spoken_text(key, table)}{joined}")
        done += 1
    print()
    print(f"{done} grup aktarıldı, {failed} grup aktarılamadı.")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    if len(sys.argv) >= 3 and sys.argv[1] == "bol":
        # Üçüncü değer verilirse dosyalar oyuna değil o klasöre yazılır (deneme).
        split_folder(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
    elif len(sys.argv) >= 2 and sys.argv[1] == "belge":
        # Grupları yeniden numaralamadan yalnızca belgeyi yeniler.
        print(f"{render_remaining()} grup kaldı -> docs/ses-gruplari.md")
    else:
        total, count = make_groups()
        print(f"{total} eksik cümle, {count} grup -> docs/ses-gruplari.md")
