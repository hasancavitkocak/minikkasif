import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minik_kasif/app_state.dart';
import 'package:minik_kasif/data/objects.dart';
import 'package:minik_kasif/data/jobs.dart';
import 'package:minik_kasif/data/outfits.dart';
import 'package:minik_kasif/data/seasons.dart';
import 'package:minik_kasif/data/stories.dart';
import 'package:minik_kasif/games/letters_game.dart';
import 'package:minik_kasif/data/stickers.dart';
import 'package:minik_kasif/games/registry.dart';
import 'package:minik_kasif/l10n.dart';
import 'package:minik_kasif/screens/certificate.dart';
import 'package:minik_kasif/screens/daily_screen.dart';
import 'package:minik_kasif/screens/home_screen.dart';
import 'package:minik_kasif/screens/level_screen.dart';
import 'package:minik_kasif/screens/music_screen.dart';
import 'package:minik_kasif/screens/scene_screen.dart';
import 'package:minik_kasif/screens/wardrobe_screen.dart';
import 'package:minik_kasif/services/audio.dart';
import 'package:minik_kasif/services/purchases.dart';
import 'package:minik_kasif/widgets/common.dart';
import 'package:minik_kasif/widgets/game_shell.dart';
import 'package:minik_kasif/widgets/intro.dart';
import 'package:minik_kasif/widgets/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Seslendirme senaryoları: hangi ekranda hangi cümlenin, kaç kez ve hangi
/// sırayla söylendiği. Her cümlenin Türkçe kaydı olduğu da denetlenir; kaydı
/// olmayan cümle makine sesiyle okunacağı için burada "TTS:" diye görünür.
final spoken = <String>[];

/// Söylenen cümleler ve susturmalar, oluş sırasıyla.
final events = <String>[];

Future<void> open(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1500));
}

Future<void> wait(WidgetTester tester, [int ms = 1500]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

Future<void> close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

/// Kaydı beklenen (gelmiş de olabilen) cümleler.
final pending = <String>{
  'i_jobs_learn',
  'i_jobs_find',
  'i_seasons_learn',
  'i_seasons_find',
  for (final job in jobs) ...[job.nameKey, job.textKey],
  for (final season in seasons) ...[season.id, '${season.id}_d'],
  'g_shapes',
  'g_memory',
  'g_shadow',
  'g_count',
  'g_pattern',
  'g_odd',
  'g_puzzle',
  'g_sort',
  'g_maze',
  'g_color',
  'g_groups',
  'g_simon',
  'g_diff',
  'g_dots',
  'g_jobs',
  'g_seasons',
  'g_clock',
  'g_letters',
  'g_story',
  'i_jobs',
  'i_jobs_rev',
  'i_seasons',
  'i_seasons_rev',
  'i_clock_place',
  'i_clock_read',
  'i_clock_set',
  'i_letters_same',
  'i_letters_hear',
  'i_letters_case',
  'story_hint',
  'story_end',
  'g_scene',
  'g_duel',
  'g_music',
  'g_wardrobe',
};

bool recorded(String key) => [
  'mp3',
  'wav',
  'm4a',
  'ogg',
].any((ext) => File('assets/audio/voice/tr/$key.$ext').existsSync());

void main() {
  setUp(() async {
    Sfx.enabled = false;
    Tts.enabled = false;
    Music.enabled = false;
    Purchases.enabled = false;
    Intro.enabled = false;
    HomeScreen.askProfile = false;
    GameShell.dailyRun = false;
    objectWorld = 0;
    SharedPreferences.setMockInitialValues({});
    await AppState.I.load();
    AppState.I.setLang('tr');
    spoken.clear();
    events.clear();
    Tts.observer = (text, key) {
      spoken.add(key ?? 'TTS:$text');
      events.add(key ?? 'TTS:$text');
    };
    Tts.stopObserver = () => events.add('<sus>');
  });

  tearDown(() {
    Tts.observer = null;
    Tts.stopObserver = null;
  });

  test('her Türkçe cümlenin kaydı var, her kaydın bir cümlesi var', () {
    final keys = <String>{
      for (var i = 1; i <= 4; i++) 'intro_$i',
      'pick_game',
      'pick_level',
      'new_sticker',
      'daily_bubble',
      'daily_done',
      'scene_hint',
      'i_music',
      'music_follow',
      'wardrobe_hint',
      'cert_title',
    };
    // Oyun yönergeleri: oyunların gerçekten söylediği cümleler.
    final texts = <String, String>{for (final k in keys) k: L.t(k)};
    for (final key in [
      'i_shapes_color',
      'i_shapes_shape',
      'i_shapes_both',
      'i_memory',
      'i_maze',
      'i_color',
      'i_shadow',
      'i_shadow_rev',
      'i_count',
      'i_groups',
      'i_pattern',
      'i_odd',
      'i_diff',
      'i_puzzle',
      'i_sort_asc',
      'i_sort_desc',
      'i_simon',
      'i_dots',
    ]) {
      texts[key] = L.t(key);
    }
    final praises = L.t('praise').split('|');
    for (var i = 0; i < praises.length; i++) {
      texts['praise_${i + 1}'] = praises[i];
    }
    for (var n = 1; n <= 10; n++) {
      texts['num_$n'] = '$n';
    }
    for (final entry in texts.entries) {
      expect(L.voiceKey(entry.value), entry.key, reason: entry.value);
    }
    // Oyun adları: oyuna girince okunur. Kayıt adı açıkça verilir, çünkü
    // aynı yazılan başka bir cümle olabilir ("Hafıza" beceri adı da).
    for (final key in pending) {
      texts[key] = L.t(key);
    }
    for (final entry in texts.entries) {
      // Kaydı beklenenler şimdilik makine sesiyle okunur; kayıtları parça
      // parça gelir. Diğerlerinin kaydı olmalıdır.
      if (pending.contains(entry.key)) continue;
      expect(recorded(entry.key), isTrue, reason: 'kayıt: ${entry.key}');
    }
    final files = {
      for (final f in Directory('assets/audio/voice/tr').listSync())
        f.uri.pathSegments.last.split('.').first,
    };
    // Metni çeviri tablosunda olmayan kayıtlar: harfler, hikâye sayfaları ve
    // saat oyununun 11 ile 12'si.
    final extra = {
      'num_11',
      'num_12',
      for (final letter in alphabets['tr']!.$2.split(''))
        letterVoiceKey(letter),
      for (final story in stories)
        for (var page = 0; page < story.pages.length; page++)
          story.voiceKey(page),
    };
    expect(files.difference({...texts.keys, ...extra}), isEmpty);
  });

  testWidgets('1. ilk açılış: tanışmanın dört cümlesi sırayla, birer kez', (
    tester,
  ) async {
    Intro.enabled = true;
    await open(tester, const HomeScreen());
    expect(spoken, ['intro_1']);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await wait(tester);
    }
    await tester.tap(find.byIcon(Icons.check_rounded));
    await wait(tester, 3000);
    expect(spoken, ['intro_1', 'intro_2', 'intro_3', 'intro_4']);
    await close(tester);
  });

  testWidgets('2. sonraki açılış: ana ekranda yalnızca "hangi oyun" sorusu', (
    tester,
  ) async {
    Intro.enabled = true;
    AppState.I.markHowToSeen('intro');
    await open(tester, const HomeScreen());
    await wait(tester, 3000);
    expect(spoken, ['pick_game']);
    await close(tester);
  });

  testWidgets('3. bölüm haritası: "bir bölüm seç" bir kez', (tester) async {
    await open(tester, LevelScreen(game: games.first));
    await wait(tester, 3000);
    expect(spoken, ['g_shapes', 'pick_level']);
    await close(tester);
  });

  testWidgets('4. oyuna giriş: yönerge bir kez (ilk kez ve sonraki girişte)', (
    tester,
  ) async {
    for (final game in games) {
      for (final seen in [false, true]) {
        spoken.clear();
        if (seen) AppState.I.markHowToSeen(game.id);
        await open(tester, game.builder(game, 1));
        await wait(tester, 2000);
        // Tanıtım bölümleri yönergenin ardından tanıtılanın adını ve cümlesini
        // de söyler; onların dışında yalnızca bir yönerge duyulmalı.
        final lines = [
          for (final s in spoken)
            if (s.startsWith('i_')) s,
        ];
        final rest = [
          for (final s in spoken)
            if (!s.startsWith('i_')) s,
        ];
        expect(lines.length, 1, reason: '${game.id} seen=$seen: $spoken');
        expect(
          rest.every((s) => s.startsWith('job_') || s.startsWith('season_')),
          isTrue,
          reason: '${game.id}: $spoken',
        );
        // Kaydı beklenen yönergeler dışında hepsinin kaydı olmalı; bekleyenler
        // kayıt gelene dek makine sesiyle okunur.
        if (!pending.contains(lines.single)) {
          expect(recorded(lines.single), isTrue, reason: lines.single);
        }
        await close(tester);
      }
    }
  });

  /// Tek dokunuşla biten sahte bir bölüm; sonrası gerçek oyun akışıdır.
  Widget quickLevel() {
    final game = games.first;
    return GameShell(
      game: game,
      level: 1,
      rounds: 1,
      instruction: (_) => L.t('i_memory'),
      roundBuilder: (round, onSolved, onMistake) => Center(
        child: TextButton(onPressed: onSolved, child: const Text('bitir')),
      ),
    );
  }

  testWidgets(
    '5. bölüm sonu: yalnızca övgü, çıkartma sesli duyurulmaz; sonraki bölümün yönergesi kesilmez',
    (tester) async {
      AppState.I.markHowToSeen(games.first.id);
      await open(tester, quickLevel());
      expect(spoken, ['i_memory']);
      await tester.tap(find.text('bitir'));
      await wait(tester, 1300);
      expect(spoken.length, 2);
      expect(spoken.last, startsWith('praise_'));
      // Çıkartma kazanılsa da sesli duyurulmaz.
      await wait(tester, 1800);
      expect(spoken.contains('new_sticker'), isFalse, reason: '$spoken');
      expect(spoken.length, 2);
      // Sonraki bölüme geçiş: yalnızca yeni bölümün yönergesi söylenir.
      await tester.tap(find.byType(RoundButton).last);
      await wait(tester, 4000);
      expect(spoken.length, 3, reason: '$spoken');
      expect(spoken.last, startsWith('i_shapes'));
      // Kapanan eski bölüm, yeni bölümün yönergesini susturmamış olmalı:
      // son olay bir "sus" değil, yönergenin kendisidir.
      expect(events.last, startsWith('i_shapes'), reason: '$events');
      await close(tester);
      expect(spoken.length, 3, reason: '$spoken');
    },
  );

  testWidgets(
    '5b. bölüm sonu beklemeden geçilirse araya eski bir duyuru girmez',
    (tester) async {
      AppState.I.markHowToSeen(games.first.id);
      await open(tester, quickLevel());
      await tester.tap(find.text('bitir'));
      await wait(tester, 1300);
      expect(spoken.last, startsWith('praise_'));
      await tester.tap(find.byType(RoundButton).last);
      await wait(tester, 5000);
      expect(spoken.contains('new_sticker'), isFalse, reason: '$spoken');
      expect(spoken.last, startsWith('i_shapes'));
      await close(tester);
    },
  );

  testWidgets('6. günün macerası: selam, sonra görevin yönergesi', (
    tester,
  ) async {
    await open(tester, const DailyScreen());
    expect(spoken, ['daily_bubble']);
    await tester.tap(find.byType(Glow));
    await wait(tester, 2500);
    expect(spoken.length, 2, reason: '$spoken');
    expect(spoken.last, startsWith('i_'));
    await close(tester);
  });

  testWidgets(
    '7a. resim çiz: ipucu bir kez; çizim, silgi ve tümünü sil çalışır',
    (tester) async {
      await open(tester, const SceneScreen());
      await wait(tester, 3000);
      expect(spoken, ['g_scene', 'scene_hint']);
      String saved() => AppState.I.profileData('scene') ?? '';
      // Sayfanın ortasında bir çizgi çiz.
      final page = tester.getCenter(find.byType(CustomPaint).last);
      await tester.dragFrom(page, const Offset(120, 40));
      await wait(tester, 300);
      expect(saved(), contains('"strokes":[[0,'));
      // Silgi seçilince çizilen çizgi "silgi" olarak kaydedilir (-1).
      await tester.tap(find.byIcon(Icons.auto_fix_normal_rounded));
      await wait(tester, 300);
      await tester.dragFrom(page, const Offset(60, 20));
      await wait(tester, 300);
      expect(saved(), contains('[-1,'));
      // Tümünü sil tek dokunuşla, onaysız çalışır.
      await tester.tap(find.byIcon(Icons.delete_rounded));
      await wait(tester, 300);
      expect(saved(), contains('"strokes":[]'));
      expect(spoken, ['g_scene', 'scene_hint']);
      await close(tester);
    },
  );

  testWidgets('7b. müzik kutusu: yönerge, şarkı seçince "parlayana dokun"', (
    tester,
  ) async {
    await open(tester, const MusicScreen());
    await wait(tester, 3000);
    expect(spoken, ['g_music', 'i_music']);
    await tester.tap(find.text('⭐'));
    await wait(tester);
    expect(spoken, ['g_music', 'i_music', 'music_follow']);
    await close(tester);
  });

  testWidgets('7c. dolap ve belge', (tester) async {
    await open(tester, const WardrobeScreen());
    await wait(tester, 3000);
    expect(spoken, ['g_wardrobe', 'wardrobe_hint']);
    await close(tester);

    spoken.clear();
    await open(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showCertificate(context, games.first),
          child: const Text('belge'),
        ),
      ),
    );
    await tester.tap(find.text('belge'));
    await wait(tester, 3000);
    expect(spoken, ['cert_title']);
    await close(tester);
  });

  testWidgets('dolap: seçilen aksesuar önizlemede hemen görünür', (
    tester,
  ) async {
    for (final g in games) {
      for (var l = 1; l <= 3; l++) {
        AppState.I.setStars(g.id, l, 3);
      }
    }
    await open(tester, const WardrobeScreen());
    expect(find.byType(DressedFox), findsNothing);
    await tester.tap(find.byType(OutfitImage).first);
    await wait(tester);
    expect(find.byType(DressedFox), findsOneWidget);
    expect(AppState.I.profileData('outfit'), 'acc_cap');
    // Şapkanın rengi değiştirilebilir; seçim görsele yansır.
    expect(outfits.first.asset, endsWith('acc_cap.png'));
    await tester.tap(find.byKey(const ValueKey('swatch_green')));
    await wait(tester);
    expect(outfits.first.asset, endsWith('acc_cap_green.png'));
    await tester.tap(find.byKey(const ValueKey('swatch_blue')));
    await wait(tester);
    expect(outfits.first.asset, endsWith('acc_cap.png'));
    // Tacın rengi sabittir.
    expect(outfits.last.color, isNull);
    // Yeniden dokununca çıkarılır.
    await tester.tap(find.byType(OutfitImage).at(1));
    await wait(tester);
    expect(find.byType(DressedFox), findsNothing);
    expect(allStickers.length, 36);
    await close(tester);
  });
}
