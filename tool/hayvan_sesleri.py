"""Hayvan seslerinin listesini yazar ve gelen ses dosyalarını oyuna aktarır.

Listeyi yenile:
    python tool/hayvan_sesleri.py
  -> docs/hayvan-sesleri.md : her hayvan için ElevenLabs ses efekti promptu

Gelen sesleri aktar:
    python tool/hayvan_sesleri.py aktar <klasör>
  Klasördeki sound_<hayvan>.mp3 (ya da .wav) dosyalarının başındaki ve
  sonundaki sessizliği kırpar, ses düzeyini eşitler, en fazla 3 saniyeye
  kısaltır ve assets/audio/animals/<hayvan>.mp3 olarak yazar.
"""
import os
import subprocess
import sys

from ses_gruplari import find_ffmpeg

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(BASE, "assets", "audio", "animals")
DOC = os.path.join(BASE, "docs", "hayvan-sesleri.md")

# lib/data/animals.dart ile aynı sırada: anahtar, Türkçe adı, prompt.
SOUNDS = [
    ("cat", "Kedi", "A cute house cat meowing twice, clear and close, no background noise."),
    ("dog", "Köpek", "A friendly dog barking twice, woof woof, clear and close, no background noise."),
    ("cow", "İnek", "A cow mooing once, a long gentle moo, clear and close, no background noise."),
    ("sheep", "Koyun", "A sheep bleating baa once, clear and close, no background noise."),
    ("horse", "At", "A horse neighing once, clear and close, no background noise."),
    ("duck", "Ördek", "A duck quacking three times, clear and close, no background noise."),
    ("rooster", "Horoz", "A rooster crowing once, cock-a-doodle-doo, clear, no background noise."),
    ("chick", "Civciv", "A small baby chick cheeping softly several times, cute and clear, no background noise."),
    ("frog", "Kurbağa", "A frog croaking a few times, ribbit, clear and close, no background noise."),
    ("lion", "Aslan", "A lion roaring once, friendly and not too scary, short, clear, no background noise."),
    ("elephant", "Fil", "An elephant trumpeting once with its trunk, clear, no background noise."),
]


def recorded(key):
    return os.path.exists(os.path.join(OUT, f"{key}.mp3"))


def write_doc():
    missing = [s for s in SOUNDS if not recorded(s[0])]
    out = [
        "# Hayvan sesleri",
        "",
        f"**{len(SOUNDS)} sesin {len(SOUNDS) - len(missing)} tanesi var.** "
        "Bu dosya `python tool/hayvan_sesleri.py` ile yenilenir.",
        "",
        "Hayvanlar oyununda hayvanın kendi sesi çalınır. Ses gelene kadar sesin",
        "yazılışı (\"Miyav miyav!\") cihazın sesiyle okunur; oyun yine oynanır.",
        "",
        "Nasıl üretilir:",
        "",
        "1. ElevenLabs'te **Sound Effects** (ses efektleri) bölümünü açın; konuşma değil.",
        "2. Süreyi elle **2 saniye** yapın.",
        "3. Aşağıdaki promptu yapıştırıp üretin; birkaç sonuç çıkarsa en gerçekçisini seçin.",
        "4. Başlıktaki adla (örnek: `sound_cat.mp3`) Downloads klasörüne kaydedin.",
        "",
        "Sesin başındaki ve sonundaki sessizliği ben kırpar, ses düzeylerini eşitlerim.",
        "Gerçek kayıt isterseniz Pixabay'in ücretsiz ses efektleri de olur; aynı adla kaydedin.",
        "",
    ]
    if not missing:
        out += ["Eksik ses yok.", ""]
    for key, name, prompt in missing:
        out += [f"### `sound_{key}.mp3` ({name})", "", "```", prompt, "```", ""]
    with open(DOC, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))
    return len(missing)


def import_folder(folder):
    ffmpeg = find_ffmpeg()
    done = 0
    for key, name, _ in SOUNDS:
        source = next(
            (p for ext in ("mp3", "wav", "m4a", "ogg")
             if os.path.exists(p := os.path.join(folder, f"sound_{key}.{ext}"))),
            None,
        )
        if source is None:
            continue
        # Baştaki ve sondaki sessizlik kırpılır (sondakini kırpmak için ses
        # ters çevrilip yeniden kırpılır), düzey eşitlenir, en çok 3 sn kalır.
        trim = "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05"
        chain = (
            f"{trim},areverse,{trim},areverse,"
            "loudnorm=I=-16:TP=-1.5:LRA=11,"
            "atrim=0:3,afade=t=out:st=2.75:d=0.25"
        )
        subprocess.run(
            [ffmpeg, "-hide_banner", "-loglevel", "error", "-y", "-i", source,
             "-af", chain, "-ac", "1", "-ar", "44100",
             "-codec:a", "libmp3lame", "-b:a", "96k",
             os.path.join(OUT, f"{key}.mp3")],
            check=True,
        )
        print(f"  {name}: aktarıldı")
        done += 1
    print(f"\n{done} ses aktarıldı.")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    if len(sys.argv) >= 3 and sys.argv[1] == "aktar":
        import_folder(sys.argv[2])
    print(f"Eksik hayvan sesi: {write_doc()} -> docs/hayvan-sesleri.md")
