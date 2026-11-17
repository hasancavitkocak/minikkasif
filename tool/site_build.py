"""minikkasif.app web sitesini üretir (sunucu gerektirmeyen sabit sayfalar).

Kullanım:
    python tool/site_build.py

1. Uygulamadaki yasal metinleri ve oyun adlarını dışa aktarır
   (flutter test tool/site/export_test.dart -> build/site_texts.json).
2. site/ klasörüne Türkçe ve İngilizce sayfaları, görselleri ve yazı tiplerini
   yazar; build/site.zip olarak da paketler (Cloudflare Pages'e yüklemek için).

Ekran görüntüleri tool/site/shots/ klasöründen alınır.
"""
import html
import io
import json
import os
import re
import shutil
import subprocess
import sys
import zipfile

from PIL import Image

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SITE = os.path.join(BASE, "site")
IMAGES = os.path.join(BASE, "assets", "images")
SHOTS = os.path.join(BASE, "tool", "site", "shots")
DOMAIN = "https://minikkasif.app"
YEAR = "2026"

T = {
    "tr": {
        "lang": "tr", "home": "/", "privacy_url": "/gizlilik/", "terms_url": "/kosullar/", "support_url": "/destek/",
        "other": "/en/", "other_label": "EN", "other_name": "English",
        "title": "Minik Kaşif: Fıstık'la Oyunlar",
        "desc": "3-6 yaş için {games} eğitici oyun: hafıza, dikkat, mantık, sayılar ve harfler. Reklamsız, güvenli, sevimli tilki Fıstık'la.",
        "nav_games": "Oyunlar", "nav_parents": "Ebeveynler için", "nav_support": "Destek",
        "hero_kicker": "3-6 yaş · Reklamsız · Türkçe seslendirme",
        "hero_title": "Fıstık'la oyna, düşün, keşfet!",
        "hero_text": "Minik Kaşif, okul öncesi çocuklar için {games} eğitici oyun ve {levels} bölüm sunar. Sevimli tilki Fıstık her oyunu sesli anlatır; çocuğunuz okuma bilmeden tek başına oynayabilir.",
        "store": "App Store'da yakında", "store_small": "iPhone ve iPad için",
        "features_title": "Ebeveynler neden seviyor?",
        "features": [
            ("shield", "Reklam yok", "Uygulamada hiç reklam yok; çocuğunuz dışarıya açılan bir bağlantıya rastlamaz."),
            ("lock", "Ebeveyn kapısı", "Ayarlar ve satın alma ekranı, yetişkinin çözebileceği bir sorunun arkasında."),
            ("voice", "Sesli anlatım", "Her yönerge Türkçe seslendirildi; okuma bilmeyen çocuk da rahatça oynar."),
            ("target", "Yaşa göre zorluk", "Çocuğunuzun yaşını seçin; oyunlar ona göre kolaylaşır ya da zorlaşır."),
            ("chart", "Gelişim raporu", "Hafıza, dikkat, mantık, sayılar ve yaratıcılıkta ilerlemeyi görün."),
            ("people", "Dört profil", "Kardeşler ayrı ayrı oynar; her birinin yıldızları ve çıkartmaları kendine."),
        ],
        "shots_title": "Oyundan kareler",
        "games_title": "{games} oyun ve {acts} etkinlik",
        "games_text": "Her oyunun ilk bölümü ücretsiz. İlk iki oyun ilk dünyada tamamen ücretsiz. Tüm bölümler için aylık ya da yıllık abonelik; dilediğiniz zaman iptal edebilirsiniz.",
        "privacy_title": "Gizlilik Politikası", "terms_title": "Kullanım Koşulları", "support_title": "Destek",
        "support_intro": "Soru, öneri ya da bir sorun için bize yazın; en kısa sürede dönüş yaparız.",
        "faq_title": "Sık sorulan sorular",
        "faq": [
            ("Aboneliği nasıl iptal ederim?", "iPhone ya da iPad'de: {where}. İptal ettiğinizde abonelik, ödediğiniz dönemin sonuna kadar açık kalır. Uygulamayı silmek aboneliği iptal etmez. Uygulamanın içinden de Ebeveyn Alanı → Abonelik → \"Aboneliği yönet veya iptal et\" ile ulaşabilirsiniz."),
            ("Yeni cihazda aboneliğim görünmüyor.", "Ebeveyn Alanı → Abonelik → \"Satın alımları geri yükle\" düğmesine dokunun. Aynı Apple hesabıyla giriş yapmış olmanız gerekir."),
            ("Çocuğumun ilerlemesi nerede saklanıyor?", "Yalnızca cihazınızda. Sunucuya hiçbir bilgi gönderilmez; uygulama silinirse ilerleme de silinir."),
            ("Ebeveyn kapısı nedir?", "Ayarlara, abonelik ekranına ve dışarıya açılan bağlantılara girmeden önce sorulan, yetişkinin kolayca çözebileceği kısa bir sorudur."),
            ("Uygulama internet ister mi?", "Hayır. Oyunlar internetsiz oynanır; yalnızca abonelik işlemleri için internet gerekir."),
        ],
        "email_label": "E-posta",
        "footer": "Tüm hakları saklıdır.",
        "back": "← Ana sayfa",
        "notfound": "Aradığınız sayfa bulunamadı.",
    },
    "en": {
        "lang": "en", "home": "/en/", "privacy_url": "/en/privacy/", "terms_url": "/en/terms/", "support_url": "/en/support/",
        "other": "/", "other_label": "TR", "other_name": "Türkçe",
        "title": "Minik Kaşif: Games with Fıstık",
        "desc": "{games} learning games for ages 3-6: memory, attention, logic, numbers and letters. No ads, safe, with Fıstık the cute fox.",
        "nav_games": "Games", "nav_parents": "For parents", "nav_support": "Support",
        "hero_kicker": "Ages 3-6 · No ads · Voice guidance",
        "hero_title": "Play, think and explore with Fıstık!",
        "hero_text": "Minik Kaşif offers {games} learning games and {levels} levels for preschoolers. Fıstık the friendly fox explains every game out loud, so your child can play alone before learning to read.",
        "store": "Coming soon to the App Store", "store_small": "For iPhone and iPad",
        "features_title": "Why parents love it",
        "features": [
            ("shield", "No ads", "There are no ads at all; your child will not run into links that lead outside the app."),
            ("lock", "Parent gate", "Settings and the purchase screen sit behind a question only an adult can answer."),
            ("voice", "Voice guidance", "Every instruction is spoken, so children who cannot read yet can play with ease."),
            ("target", "Age-based difficulty", "Choose your child's age and the games adjust to it."),
            ("chart", "Progress report", "See progress in memory, attention, logic, numbers and creativity."),
            ("people", "Four profiles", "Siblings play separately, each with their own stars and stickers."),
        ],
        "shots_title": "Screenshots",
        "games_title": "{games} games and {acts} activities",
        "games_text": "The first level of every game is free, and the first two games are fully free in the first world. A monthly or yearly subscription unlocks everything; cancel anytime.",
        "privacy_title": "Privacy Policy", "terms_title": "Terms of Use", "support_title": "Support",
        "support_intro": "Write to us with any question, suggestion or problem; we will get back to you as soon as possible.",
        "faq_title": "Frequently asked questions",
        "faq": [
            ("How do I cancel my subscription?", "On iPhone or iPad: {where}. After you cancel, the subscription stays active until the end of the period you paid for. Deleting the app does not cancel the subscription. In the app you can also go to Parent Area → Subscription → \"Manage or cancel subscription\"."),
            ("My subscription does not show on a new device.", "Tap Parent Area → Subscription → \"Restore purchases\". You must be signed in with the same Apple Account."),
            ("Where is my child's progress stored?", "Only on your device. Nothing is sent to a server; if you delete the app, the progress is deleted too."),
            ("What is the parent gate?", "A short question, easy for an adult, asked before settings, the subscription screen and any outside link."),
            ("Does the app need the internet?", "No. The games work offline; only subscription actions need an internet connection."),
        ],
        "email_label": "Email",
        "footer": "All rights reserved.",
        "back": "← Home",
        "notfound": "The page you are looking for was not found.",
    },
}

ICONS = {
    "shield": '<path d="M12 3l7 3v6c0 4.6-3 7.6-7 9-4-1.4-7-4.4-7-9V6z"/><path d="M9 12.2l2.2 2.2L15.5 10"/>',
    "lock": '<rect x="5" y="11" width="14" height="10" rx="2.5"/><path d="M8.5 11V8a3.5 3.5 0 0 1 7 0v3"/><path d="M12 15v2"/>',
    "voice": '<path d="M4 10v4h3.5L13 18.5v-13L7.5 10z"/><path d="M16.5 9.2a4 4 0 0 1 0 5.6"/><path d="M19 6.8a7.5 7.5 0 0 1 0 10.4"/>',
    "target": '<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="4.5"/><circle cx="12" cy="12" r="1"/>',
    "chart": '<path d="M4 20h16"/><path d="M6.5 16v-4"/><path d="M11 16V8"/><path d="M15.5 16v-6"/><path d="M20 4l-4.5 4.5-3-2L7 11"/>',
    "people": '<circle cx="9" cy="8" r="3.2"/><path d="M3 19.5c.7-3.3 3.1-5.2 6-5.2s5.3 1.9 6 5.2"/><circle cx="17" cy="9.2" r="2.5"/><path d="M16.2 14.4c2.5.2 4.2 1.9 4.8 4.6"/>',
    "globe": '<circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3c2.4 2.6 3.6 5.6 3.6 9s-1.2 6.4-3.6 9c-2.4-2.6-3.6-5.6-3.6-9S9.6 5.6 12 3z"/>',
}


def svg_icon(key, size=24):
    return (f'<svg viewBox="0 0 24 24" width="{size}" height="{size}" fill="none" stroke="currentColor" '
            f'stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">{ICONS[key]}</svg>')


CSS = """
@font-face { font-family: Kasif; src: url(/fonts/Baloo2-600.ttf) format("truetype"); font-weight: 500; font-display: swap; }
@font-face { font-family: Kasif; src: url(/fonts/Baloo2-800.ttf) format("truetype"); font-weight: 800; font-display: swap; }
:root { --ink: #3b2a20; --orange: #ff9f43; --cream: #fff8e8; --green: #2ecc71; --sky: #bfe6ff; --muted: #6f5d50; }
* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
body { margin: 0; font-family: Kasif, "Segoe UI", Arial, sans-serif; font-weight: 500; color: var(--ink); background: #fffdf7; line-height: 1.55; }
a { color: #1f7ae0; }
img { max-width: 100%; height: auto; display: block; }
.wrap { width: min(1120px, 92vw); margin: 0 auto; }
header { position: sticky; top: 0; z-index: 10; background: rgba(255,253,247,.92); backdrop-filter: blur(8px); border-bottom: 1px solid #f1e6d2; }
header .wrap { display: flex; align-items: center; gap: 24px; height: 68px; }
header .logo { flex-shrink: 0; display: block; }
header .logo img { height: 42px; width: auto; max-width: none; }
header nav { margin-left: auto; display: flex; gap: 20px; align-items: center; font-weight: 800; }
header nav a { color: var(--ink); text-decoration: none; }
header nav a.lang { display: inline-flex; align-items: center; gap: 6px; border: 2px solid #f1e6d2; border-radius: 999px; padding: 3px 12px 3px 9px; background: #fff; }
header nav a.lang:hover { border-color: var(--orange); }
.hero { position: relative; overflow: hidden; background: url(/img/bg.webp) center bottom / cover no-repeat; }
.hero::before { content: ''; position: absolute; inset: 0; background: linear-gradient(90deg, rgba(255,253,247,.94) 0%, rgba(255,253,247,.82) 42%, rgba(255,253,247,0) 68%); }
.hero .wrap { position: relative; }
.hero-logo { width: min(360px, 70%); margin-bottom: 10px; filter: drop-shadow(0 6px 0 rgba(0,0,0,.08)); }
.wave { position: absolute; left: 0; right: 0; bottom: -1px; width: 100%; height: 60px; }
.hero .wrap { display: grid; grid-template-columns: 1.05fr 1fr; gap: 40px; align-items: center; padding: 56px 0 110px; }
.kicker { display: inline-block; background: #fff; border-radius: 999px; padding: 4px 14px; font-weight: 800; color: var(--orange); box-shadow: 0 2px 0 rgba(0,0,0,.06); }
h1 { font-weight: 800; font-size: clamp(34px, 5vw, 56px); line-height: 1.08; margin: 16px 0; }
h2 { font-weight: 800; font-size: clamp(26px, 3.4vw, 38px); line-height: 1.15; margin: 0 0 18px; }
.lead { font-size: 19px; color: var(--muted); max-width: 34em; }
.store { display: inline-flex; flex-direction: column; margin-top: 22px; background: var(--ink); color: #fff; border-radius: 16px; padding: 10px 22px; text-decoration: none; }
.store b { font-size: 20px; font-weight: 800; }
.store small { opacity: .8; }
.hero-art { position: relative; }
.hero-art .tablet { border-radius: 28px; border: 12px solid #2b2b33; box-shadow: 0 24px 50px rgba(30,60,90,.25); overflow: hidden; background: #2b2b33; }
.hero-art .fox { position: absolute; width: 42%; left: -14%; bottom: -12%; filter: drop-shadow(0 12px 10px rgba(0,0,0,.18)); }
section { padding: 72px 0; }
.features { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }
.card { background: var(--cream); border-radius: 22px; padding: 22px; box-shadow: 0 3px 0 #f1e3c6; }
.card .icon { width: 52px; height: 52px; border-radius: 16px; display: grid; place-items: center; color: #fff; }
.card .icon svg { width: 28px; height: 28px; }
.c0 { background: #ff8a5c; } .c1 { background: #9b7bff; } .c2 { background: #ff6fa8; }
.c3 { background: #2ec27e; } .c4 { background: #3d9bff; } .c5 { background: #f5b02e; }
.card h3 { margin: 8px 0 6px; font-weight: 800; font-size: 21px; }
.card p { margin: 0; color: var(--muted); }
.shots { display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; }
.shots img { border-radius: 18px; box-shadow: 0 10px 24px rgba(30,60,90,.15); }
.games { display: grid; grid-template-columns: repeat(auto-fill, minmax(118px, 1fr)); gap: 14px; margin-top: 26px; }
.game { background: #fff; border-radius: 18px; padding: 10px 8px 8px; text-align: center; font-weight: 800; font-size: 15px; box-shadow: 0 3px 0 #efe6d6, 0 0 0 1px #f3ebdc inset; }
.game img { width: 76px; height: 76px; margin: 0 auto 4px; object-fit: contain; }
.band { background: var(--cream); }
.doc { max-width: 760px; }
.doc h2 { font-size: 22px; margin: 28px 0 6px; }
.doc p { margin: 0 0 12px; }
.mail { display: inline-block; font-size: 22px; font-weight: 800; background: var(--cream); padding: 10px 18px; border-radius: 14px; text-decoration: none; }
details { background: var(--cream); border-radius: 16px; padding: 14px 18px; margin: 10px 0; }
summary { font-weight: 800; cursor: pointer; }
footer { background: var(--ink); color: #f6eadb; padding: 34px 0; margin-top: 40px; }
footer .wrap { display: flex; flex-wrap: wrap; gap: 18px 28px; align-items: center; }
footer a { color: #ffd59e; }
footer .copy { margin-left: auto; opacity: .75; }
@media (max-width: 860px) {
  .hero .wrap { grid-template-columns: 1fr; padding-top: 28px; }
  .hero::before { background: linear-gradient(180deg, rgba(255,253,247,.94) 0%, rgba(255,253,247,.85) 55%, rgba(255,253,247,.2) 100%); }
  .hero-art .fox { width: 28%; left: auto; right: -3%; bottom: -14%; }
  .features { grid-template-columns: 1fr 1fr; }
  .shots { grid-template-columns: 1fr; }
  header nav a:not(.lang) { display: none; }
}
@media (max-width: 520px) { .features { grid-template-columns: 1fr; } footer .copy { margin-left: 0; } }
"""


def esc(text):
    return html.escape(text, quote=True)


def page(t, title, desc, path, body, alternate):
    full = title if title == t["title"] else f"{title} · Minik Kaşif"
    return f"""<!DOCTYPE html>
<html lang="{t['lang']}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{esc(full)}</title>
<meta name="description" content="{esc(desc)}">
<link rel="canonical" href="{DOMAIN}{path}">
<link rel="alternate" hreflang="{'en' if t['lang'] == 'tr' else 'tr'}" href="{DOMAIN}{alternate}">
<meta property="og:title" content="{esc(full)}">
<meta property="og:description" content="{esc(desc)}">
<meta property="og:image" content="{DOMAIN}/img/og.jpg">
<meta property="og:url" content="{DOMAIN}{path}">
<meta name="theme-color" content="#bfe6ff">
<link rel="icon" href="/img/favicon.png">
<link rel="apple-touch-icon" href="/img/apple-touch-icon.png">
<link rel="stylesheet" href="/style.css">
</head>
<body>
<header><div class="wrap">
  <a class="logo" href="{t['home']}"><img src="/img/logo.webp" alt="Minik Kaşif"></a>
  <nav>
    <a href="{t['home']}#oyunlar">{t['nav_games']}</a>
    <a href="{t['home']}#ebeveyn">{t['nav_parents']}</a>
    <a href="{t['support_url']}">{t['nav_support']}</a>
    <a class="lang" href="{alternate}" title="{t['other_name']}" hreflang="{t['other_label'].lower()}">{svg_icon('globe', 18)}{t['other_label']}</a>
  </nav>
</div></header>
{body}
<footer><div class="wrap">
  <a href="{t['privacy_url']}">{t['privacy_title']}</a>
  <a href="{t['terms_url']}">{t['terms_title']}</a>
  <a href="{t['support_url']}">{t['support_title']}</a>
  <span class="copy">© {YEAR} Minik Kaşif. {t['footer']}</span>
</div></footer>
</body>
</html>
"""


def legal_body(text):
    """Uygulamadaki düz metni başlıklı paragraflara çevirir."""
    out = []
    for block in text.strip().split("\n\n"):
        lines = block.split("\n")
        if re.match(r"^\d+\.\s", lines[0]):
            out.append(f"<h2>{esc(lines[0])}</h2>")
            lines = lines[1:]
        for line in lines:
            if line.strip():
                out.append(f"<p>{linkify(esc(line))}</p>")
    return "\n".join(out)


def linkify(text):
    return re.sub(r"([\w.+-]+@[\w-]+\.[\w.]+)", r'<a href="mailto:\1">\1</a>', text)


def save_image(src, dest, size, fmt="WEBP", quality=82):
    im = Image.open(src)
    im.thumbnail((size, size))
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    if fmt == "JPEG":
        im.convert("RGB").save(dest, "JPEG", quality=quality, optimize=True)
    else:
        im.save(dest, fmt, quality=quality, method=6) if fmt == "WEBP" else im.save(dest, fmt)


def write(rel, content):
    path = os.path.join(SITE, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(content)


def build():
    flutter = os.path.join("D:" + os.sep, "flutter", "bin", "flutter.bat")
    env = dict(os.environ, PUB_CACHE=r"D:\flutter_pub_cache")
    subprocess.run([flutter, "test", "tool/site/export_test.dart"], cwd=BASE, env=env, check=True,
                   stdout=subprocess.DEVNULL)
    data = json.load(open(os.path.join(BASE, "build", "site_texts.json"), encoding="utf-8"))

    # Klasörün kendisi değil içi temizlenir (yerel sunucu açıkken de çalışsın).
    os.makedirs(SITE, exist_ok=True)
    for name in os.listdir(SITE):
        path = os.path.join(SITE, name)
        shutil.rmtree(path) if os.path.isdir(path) else os.remove(path)
    # Görseller ve yazı tipleri
    save_image(os.path.join(IMAGES, "ui", "logo.png"), os.path.join(SITE, "img", "logo.webp"), 720)
    save_image(os.path.join(IMAGES, "bg", "bg_home.png"), os.path.join(SITE, "img", "bg.webp"), 1600, quality=72)
    save_image(os.path.join(IMAGES, "mascot", "fox_hello.png"), os.path.join(SITE, "img", "fox.webp"), 520)
    fox = Image.open(os.path.join(IMAGES, "mascot", "fox_hello.png")).convert("RGBA")
    head = fox.crop((180, 20, 600, 440))
    for name, size in (("favicon.png", 64), ("apple-touch-icon.png", 180)):
        icon = Image.new("RGBA", head.size, (191, 230, 255, 255))
        icon.alpha_composite(head)
        icon.resize((size, size), Image.LANCZOS).save(os.path.join(SITE, "img", name))
    for g in data["tr"]["games"]:
        src = os.path.join(IMAGES, "icons", f"game_{g['id']}.png")
        if os.path.exists(src):
            save_image(src, os.path.join(SITE, "img", "games", f"{g['id']}.webp"), 200)
    for name in os.listdir(SHOTS):
        save_image(os.path.join(SHOTS, name), os.path.join(SITE, "img", "shots", name.replace(".png", ".webp")), 1280, quality=78)
    save_image(os.path.join(SHOTS, "home.png"), os.path.join(SITE, "img", "og.jpg"), 1200, "JPEG")
    os.makedirs(os.path.join(SITE, "fonts"), exist_ok=True)
    for f in ("Baloo2-600.ttf", "Baloo2-800.ttf"):
        shutil.copy(os.path.join(BASE, "assets", "fonts", f), os.path.join(SITE, "fonts", f))
    write("style.css", CSS.strip() + "\n")

    activities = {"scene", "duel", "music", "wardrobe", "story"}
    for lang, t in T.items():
        d = data[lang]
        games_n = sum(1 for g in d["games"] if g["id"] not in activities)
        acts_n = len(d["games"]) - games_n
        fill = lambda s: s.format(games=games_n, levels=data["levels"], acts=acts_n, where=d["where_ios"])
        sfx = "" if lang == "tr" else "_en"
        shots = ["welcome", "home", "animals", "seasons"]
        hero = f"""<section class="hero"><div class="wrap">
  <div>
    <img class="hero-logo" src="/img/logo.webp" alt="Minik Kaşif">
    <span class="kicker">{esc(t['hero_kicker'])}</span>
    <h1>{esc(t['hero_title'])}</h1>
    <p class="lead">{esc(fill(t['hero_text']))}</p>
    <span class="store"><small>{esc(t['store_small'])}</small><b>{esc(t['store'])}</b></span>
  </div>
  <div class="hero-art">
    <div class="tablet"><img src="/img/shots/home{sfx}.webp" alt="" width="1280" height="800"></div>
    <img class="fox" src="/img/fox.webp" alt="Fıstık" width="520" height="520">
  </div>
</div><svg class="wave" viewBox="0 0 1440 60" preserveAspectRatio="none" aria-hidden="true"><path d="M0 30 C 240 70 480 0 720 26 S 1200 62 1440 24 V60 H0z" fill="#fffdf7"/></svg></section>"""
        feats = "\n".join(
            f'<div class="card"><div class="icon c{i}">{svg_icon(key)}</div><h3>{esc(h)}</h3><p>{esc(p)}</p></div>'
            for i, (key, h, p) in enumerate(t["features"])
        )
        shots_html = "\n".join(
            f'<img src="/img/shots/{s}{sfx}.webp" alt="" width="1280" height="800" loading="lazy">' for s in shots
        )
        games_html = "\n".join(
            f'<div class="game"><img src="/img/games/{g["id"]}.webp" alt="" loading="lazy">{esc(g["name"])}</div>'
            for g in d["games"]
            if os.path.exists(os.path.join(SITE, "img", "games", f"{g['id']}.webp"))
        )
        body = f"""{hero}
<section id="ebeveyn"><div class="wrap"><h2>{esc(t['features_title'])}</h2><div class="features">{feats}</div></div></section>
<section class="band"><div class="wrap"><h2>{esc(t['shots_title'])}</h2><div class="shots">{shots_html}</div></div></section>
<section id="oyunlar"><div class="wrap"><h2>{esc(fill(t['games_title']))}</h2><p class="lead">{esc(t['games_text'])}</p><div class="games">{games_html}</div></div></section>"""
        other = T["en" if lang == "tr" else "tr"]
        write(os.path.join(t["home"].strip("/"), "index.html"),
              page(t, t["title"], fill(t["desc"]), t["home"], body, other["home"]))

        def doc(title, inner, url, other_url):
            body = f'<section><div class="wrap doc"><p><a href="{t["home"]}">{esc(t["back"])}</a></p><h1>{esc(title)}</h1>{inner}</div></section>'
            write(os.path.join(url.strip("/"), "index.html"), page(t, title, title, url, body, other_url))

        doc(t["privacy_title"], legal_body(d["privacy"]), t["privacy_url"], other["privacy_url"])
        doc(t["terms_title"], legal_body(d["terms"]), t["terms_url"], other["terms_url"])
        faq = "\n".join(f"<details><summary>{esc(q)}</summary><p>{esc(fill(a))}</p></details>" for q, a in t["faq"])
        support = (f'<p class="lead">{esc(t["support_intro"])}</p>'
                   f'<p><a class="mail" href="mailto:{data["email"]}">{data["email"]}</a></p>'
                   f'<h2>{esc(t["faq_title"])}</h2>{faq}')
        doc(t["support_title"], support, t["support_url"], other["support_url"])

    write("404.html", page(T["tr"], "404", T["tr"]["notfound"], "/404.html",
                           f'<section><div class="wrap doc"><h1>404</h1><p>{T["tr"]["notfound"]}</p><p>{T["en"]["notfound"]}</p>'
                           f'<p><a href="/">Minik Kaşif</a></p></div></section>', "/en/"))

    zip_path = os.path.join(BASE, "build", "site.zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for root, _, files in os.walk(SITE):
            for f in files:
                full = os.path.join(root, f)
                z.write(full, os.path.relpath(full, SITE))
    total = sum(os.path.getsize(os.path.join(r, f)) for r, _, fs in os.walk(SITE) for f in fs)
    print(f"site/ hazır: {total / 1024:.0f} KB, build/site.zip")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    build()
