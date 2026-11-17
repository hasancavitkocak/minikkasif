import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minik_kasif/app_state.dart';
import 'package:minik_kasif/data/animals.dart';
import 'package:minik_kasif/data/objects.dart';
import 'package:minik_kasif/data/produce.dart';
import 'package:minik_kasif/games/animals_game.dart';
import 'package:minik_kasif/games/fruits_game.dart';
import 'package:minik_kasif/games/game_def.dart';
import 'package:minik_kasif/data/jobs.dart';
import 'package:minik_kasif/data/seasons.dart';
import 'package:minik_kasif/games/jobs_game.dart';
import 'package:minik_kasif/data/stories.dart';
import 'package:minik_kasif/games/clock_game.dart';
import 'package:minik_kasif/games/letters_game.dart';
import 'package:minik_kasif/games/registry.dart';
import 'package:minik_kasif/games/seasons_game.dart';
import 'package:minik_kasif/l10n.dart';
import 'package:minik_kasif/main.dart';
import 'package:minik_kasif/screens/album_screen.dart';
import 'package:minik_kasif/screens/daily_screen.dart';
import 'package:minik_kasif/screens/home_screen.dart';
import 'package:minik_kasif/screens/level_screen.dart';
import 'package:minik_kasif/screens/parent_gate.dart';
import 'package:minik_kasif/screens/parents_screen.dart';
import 'package:minik_kasif/screens/paywall_screen.dart';
import 'package:minik_kasif/screens/report_screen.dart';
import 'package:minik_kasif/screens/profile_dialog.dart';
import 'package:minik_kasif/screens/welcome_screen.dart';
import 'package:minik_kasif/screens/who_screen.dart';
import 'package:minik_kasif/services/audio.dart';
import 'package:minik_kasif/services/purchases.dart';
import 'package:minik_kasif/widgets/common.dart';
import 'package:minik_kasif/widgets/game_shell.dart';
import 'package:minik_kasif/widgets/intro.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Telefon (yatay) ve tablet ekran boyutları.
const screens = {'telefon': Size(740, 360), 'tablet': Size(1280, 800)};

Future<void> pumpScreen(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pump(const Duration(milliseconds: 100));
}

/// Sürekli dönen animasyonlar olduğu için pumpAndSettle yerine sabit süre.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1500));
}

/// Bekleyen zamanlayıcıların iptal edilmesi için ekranı kaldırır.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

/// Pencerelerin kapatma (X) düğmesi; görseli olsa da olmasa da bulunur.
final closeButton = find.byWidgetPredicate(
  (w) => w is RoundButton && w.icon == Icons.close_rounded,
);

void main() {
  setUp(() async {
    Sfx.enabled = false;
    Tts.enabled = false;
    Purchases.enabled = false;
    Music.enabled = false;
    Intro.enabled = false;
    HomeScreen.askProfile = false;
    GameShell.dailyRun = false;
    objectWorld = 0;
    SharedPreferences.setMockInitialValues({});
    await AppState.I.load();
    AppState.I.setLang('tr');
  });

  test('her dilde tüm çeviri anahtarları var', () {
    AppState.I.setLang('tr');
    final keys = [
      'hello',
      'level_done',
      'parents',
      'gate_title',
      'premium_title',
      'restore',
      'sub_note',
      'i_shapes_color',
      'i_shapes_shape',
      'i_shapes_both',
      'i_memory',
      'i_shadow',
      'i_shadow_rev',
      'i_count',
      'i_pattern',
      'i_odd',
      'i_puzzle',
      'i_sort_asc',
      'i_sort_desc',
      'i_maze',
      'i_color',
      'i_groups',
      'i_simon',
      'i_diff',
      'album',
      'daily',
      'report',
      'sk_memory',
      'sk_creative',
      'profiles',
      'music',
      'tagline',
      'pick_game',
      'how_to',
      for (final g in games) 'g_${g.id}',
    ];
    for (final lang in L.languages.keys) {
      AppState.I.setLang(lang);
      for (final key in keys) {
        expect(L.t(key), isNot(key), reason: '$lang dilinde "$key" eksik');
      }
    }
    // Türkçe dışındaki diller İngilizceye düşmüyor, kendi çevirisini kullanıyor.
    AppState.I.setLang('de');
    expect(L.t('i_count'), 'Wie viele sind es?');
  });

  rewardTests();
  gateTests();
  introTests();
  firstRunTests();

  test('ilk iki oyun ve her oyunun ilk bölümü ücretsiz', () {
    expect(games.length, 20);
    expect(games.where((g) => g.free).map((g) => g.id), ['shapes', 'memory']);
    // Diğer oyunların yalnızca ilk bölümü aboneliksiz oynanır.
    final state = AppState.I;
    for (final g in games) {
      expect(state.canPlay(g, 1), isTrue, reason: g.id);
      expect(state.canPlay(g, 2), g.free, reason: g.id);
      // Ücretsiz oyunlarda da yalnızca ilk dünya açıktır.
      expect(state.canPlay(g, worldSize + 1), isFalse, reason: g.id);
    }
    state.setPremium(true);
    expect(games.every((g) => state.canPlay(g, g.levels)), isTrue);
    state.setPremium(false);
  });

  test('yeni oyunların verisi tutarlı: alfabe, mevsimler, hikâyeler', () {
    // Her dilde büyük ve küçük harfler aynı sayıda ve aynı sırada.
    for (final lang in L.languages.keys) {
      final (upper, lower) = alphabets[lang]!;
      expect(upper.length, lower.length, reason: lang);
    }
    expect(alphabets['tr']!.$1.length, 29);
    expect(letterVoiceKey('ç'), 'let_cc');
    expect(letterVoiceKey('ı'), 'let_ii');
    expect(letterVoiceKey('i'), 'let_i');
    // Her mevsimin bir Fıstık kıyafeti var; yalnızca ilkbahar ile sonbahar
    // birbirinin benzeridir.
    expect(seasonOutfits.length, seasons.length);
    expect(seasonTwin(0), 2);
    expect(seasonTwin(2), 0);
    expect(seasonTwin(1), -1);
    expect(seasonTwin(3), -1);
    expect(SeasonsGame.modeOf(1), SeasonsMode.learn);
    expect(SeasonsGame.modeOf(2), SeasonsMode.dress);
    expect(SeasonsGame.modeOf(6), SeasonsMode.find);
    expect(SeasonsGame.modeOf(10), SeasonsMode.season);

    // Hayvanlar: her hayvan bir kez tanıtılır; sesleri yazıyla da okunabilir.
    expect(
      {
        for (var l = 1; l <= 2; l++)
          for (final a in AnimalsGame.learnSet(l)) a.key,
      }.length,
      animals.length,
    );
    expect(AnimalsGame.modeOf(1), AnimalsMode.learn);
    expect(AnimalsGame.modeOf(3), AnimalsMode.find);
    expect(AnimalsGame.modeOf(10), AnimalsMode.sound);
    // Meyve ve sebze: her ürün bir kez tanıtılır; her renkte en az iki ürün,
    // ağaçta ve tarlada yetişenlerden yeterince ürün vardır.
    expect(
      {
        for (var l = 1; l <= 3; l++)
          for (final p in FruitsGame.learnSet(l)) p.key,
      }.length,
      produce.length,
    );
    for (final color in ProduceColor.values) {
      expect(
        produce.where((p) => p.color == color).length,
        greaterThanOrEqualTo(2),
        reason: color.name,
      );
    }
    expect(produce.where((p) => p.grow == Grow.tree).length, greaterThan(3));
    expect(
      produce.where((p) => p.grow == Grow.field || p.grow == Grow.under).length,
      greaterThan(3),
    );
    expect(FruitsGame.modeOf(1), FruitsMode.learn);
    expect(FruitsGame.modeOf(6), FruitsMode.color);
    expect(FruitsGame.modeOf(8), FruitsMode.kind);
    expect(FruitsGame.modeOf(10), FruitsMode.tree);
    // Her yeni metnin beş dilde de çevirisi vardır.
    for (final lang in L.languages.keys) {
      AppState.I.setLang(lang);
      for (final key in [
        for (final a in animals) ...[a.nameKey, a.textKey, a.soundKey],
        for (final p in produce) ...[p.nameKey, p.kindKey, p.growKey],
        for (final c in ProduceColor.values) c.instructionKey,
      ]) {
        expect(L.t(key), isNot(key), reason: '$lang $key');
      }
    }
    AppState.I.setLang('tr');
    // Hikâyelerin her sayfası her dilde yazılı, her sayfanın simgesi var.
    for (final story in stories) {
      expect(story.emojis.length, story.pages.length, reason: story.id);
      for (final lang in L.languages.keys) {
        expect(story.title[lang], isNotNull, reason: '${story.id} $lang');
        for (final page in story.pages) {
          expect(page[lang], isNotNull, reason: '${story.id} $lang');
        }
      }
    }
    // Saat: ilk bölümler sayı yerleştirme, sonra okuma, en son ayarlama.
    expect(ClockGame.modeOf(1), ClockMode.place);
    expect(ClockGame.modeOf(5), ClockMode.read);
    expect(ClockGame.modeOf(10), ClockMode.set);
    // Meslekler: önce tanıtım, sonra adı söyleneni bulma, en son eşleme. İki
    // tanıtım bölümü on mesleğin hepsini gösterir.
    expect(JobsGame.modeOf(1), JobsMode.learn);
    expect(JobsGame.modeOf(2), JobsMode.learn);
    expect(JobsGame.modeOf(3), JobsMode.find);
    expect(JobsGame.modeOf(6), JobsMode.match);
    expect(jobs.length, 10);
    // Her mesleğin ve mevsimin adı ile tanıtım cümlesi her dilde yazılı.
    for (final lang in L.languages.keys) {
      AppState.I.setLang(lang);
      for (final key in [
        for (final job in jobs) ...[job.nameKey, job.textKey],
        for (final season in seasons) ...[season.id, '${season.id}_d'],
      ]) {
        expect(L.t(key), isNot(key), reason: '$lang $key');
      }
    }
    AppState.I.setLang('tr');
  });

  testWidgets('saat: şekilli parça sürüklenince oyuğuna yerleşir', (
    tester,
  ) async {
    AppState.I.markHowToSeen('clock');
    // Yaşı büyük profilde ilk bölümde üç parça gelir (küçük yaşta iki).
    AppState.I.updateProfile(AppState.I.profile.id, 'Elif', 'rabbit', 5);
    final game = games.firstWhere((g) => g.id == 'clock');
    await pumpScreen(tester, screens['tablet']!, game.builder(game, 1));
    await settle(tester);
    Iterable<ClockPiece> holes() => tester
        .widgetList<ClockPiece>(find.byType(ClockPiece))
        .where((p) => p.ghost);
    final before = holes().length;
    expect(before, greaterThanOrEqualTo(2));
    final number = holes().first.number;
    // Tepsideki parça, saatteki aynı sayılı oyuğa sürüklenir.
    final piece = find.descendant(
      of: find.byType(Draggable<int>),
      matching: find.byWidgetPredicate(
        (w) => w is ClockPiece && w.number == number && !w.ghost,
      ),
    );
    final hole = find.byWidgetPredicate(
      (w) => w is ClockPiece && w.number == number && w.ghost,
    );
    final from = tester.getCenter(piece.first);
    final to = tester.getCenter(hole);
    await tester.timedDragFrom(
      from,
      to - from,
      const Duration(milliseconds: 400),
    );
    await settle(tester);
    expect(holes().length, before - 1);
    // Yanlış oyuğa bırakılan parça yerleşmez.
    final other = tester
        .widgetList<ClockPiece>(
          find.descendant(
            of: find.byType(Draggable<int>),
            matching: find.byType(ClockPiece),
          ),
        )
        .first
        .number;
    final wrongHole = holes().firstWhere((p) => p.number != other).number;
    final start = tester.getCenter(
      find
          .descendant(
            of: find.byType(Draggable<int>),
            matching: find.byWidgetPredicate(
              (w) => w is ClockPiece && w.number == other,
            ),
          )
          .first,
    );
    final end = tester.getCenter(
      find.byWidgetPredicate(
        (w) => w is ClockPiece && w.number == wrongHole && w.ghost,
      ),
    );
    await tester.timedDragFrom(
      start,
      end - start,
      const Duration(milliseconds: 400),
    );
    await settle(tester);
    expect(holes().length, before - 1);
    await unmount(tester);
  });

  test('bölümler sırayla açılır ve yıldızlar kalıcıdır', () async {
    final state = AppState.I;
    expect(state.levelUnlocked('shapes', 1), isTrue);
    expect(state.levelUnlocked('shapes', 2), isFalse);
    state.setStars('shapes', 1, 2);
    expect(state.levelUnlocked('shapes', 2), isTrue);
    state.setStars('shapes', 1, 1); // Daha düşük sonuç eskisini ezmez.
    expect(state.stars('shapes', 1), 2);
    await state.load();
    expect(state.stars('shapes', 1), 2);
  });

  for (final screen in screens.entries) {
    testWidgets('${screen.key}: her oyunun her bölümü taşma olmadan çiziliyor', (
      tester,
    ) async {
      for (final game in games) {
        for (var level = 1; level <= game.levels; level++) {
          // Rastgele üretilen turların farklı hallerini görmek için birkaç kez.
          for (var i = 0; i < 3; i++) {
            await pumpScreen(tester, screen.value, game.builder(game, level));
            expect(
              tester.takeException(),
              isNull,
              reason: '${game.id} bölüm $level',
            );
            await unmount(tester);
          }
        }
      }
    });

    testWidgets('${screen.key}: menü ekranları taşma olmadan çiziliyor', (
      tester,
    ) async {
      for (final lang in L.languages.keys) {
        AppState.I.setLang(lang);
        for (final child in [
          const MinikKasifApp(),
          const HomeScreen(),
          LevelScreen(game: games.first),
          // Ebeveyn alanının her sekmesi.
          for (var tab = 0; tab < 6; tab++) ParentsScreen(initialTab: tab),
          for (final a in activities) a.builder(a, 0),
          const PaywallScreen(),
          const AlbumScreen(),
          const DailyScreen(),
          const ReportScreen(),
        ]) {
          await pumpScreen(tester, screen.value, child);
          expect(
            tester.takeException(),
            isNull,
            reason: '$lang ${child.runtimeType}',
          );
          await unmount(tester);
        }
      }
    });
  }

  testWidgets(
    'ücretli oyunun ilk bölümü açık, ikinci bölümü ebeveyn kapısına gider',
    (tester) async {
      await pumpScreen(tester, screens['tablet']!, const HomeScreen());
      await settle(tester);

      await tester.tap(find.text('Gölgeler').last);
      await settle(tester);
      expect(find.byType(LevelScreen), findsOneWidget);
      await tester.tap(find.text('2'));
      await settle(tester);
      expect(find.text('Yalnızca yetişkinler'), findsOneWidget);
      expect(find.byType(PaywallScreen), findsNothing);
      await tester.tap(closeButton);
      await settle(tester);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

  testWidgets('ücretsiz deneme: süre ve sonraki ücret açıkça yazılır', (
    tester,
  ) async {
    addTearDown(() => Purchases.I.debugSetTrial(Purchases.yearlyId, 0));
    for (final lang in L.languages.keys) {
      AppState.I.setLang(lang);
      for (final size in screens.values) {
        // Deneme yokken: düğme "Devam", deneme notu görünmez.
        Purchases.I.debugSetTrial(Purchases.yearlyId, 0);
        await pumpScreen(tester, size, const PaywallScreen());
        await settle(tester);
        expect(find.byKey(const ValueKey('trial_note')), findsNothing);
        expect(find.text(L.t('trial_start')), findsNothing);
        // Yıllık planda 7 günlük deneme: rozet, düğme ve açıklama görünür.
        Purchases.I.debugSetTrial(Purchases.yearlyId, 7);
        await settle(tester);
        expect(find.byKey(const ValueKey('trial_note')), findsOneWidget);
        expect(find.text(L.t('trial_start')), findsOneWidget);
        expect(
          find.text(L.t('trial_badge').replaceAll('{days}', '7')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: '$lang $size');
        // Aylık plan seçilince deneme notu kalkar (onda deneme yok).
        await tester.tap(find.text(L.t('monthly')));
        await settle(tester);
        expect(find.byKey(const ValueKey('trial_note')), findsNothing);
        expect(find.text(L.t('trial_start')), findsNothing);
        expect(tester.takeException(), isNull, reason: '$lang $size');
        await unmount(tester);
      }
    }
    AppState.I.setLang('tr');
  });

  testWidgets('iki profil varsa açılışta "Kim oynuyor?" sorulur', (
    tester,
  ) async {
    // Tek profilde soru sorulmaz, doğrudan ana ekrana geçilir.
    expect(WhoScreen.next(), isA<HomeScreen>());
    AppState.I.addProfile('Elif', 'rabbit', 4);
    final elif = AppState.I.profiles.last;
    expect(WhoScreen.next(), isA<WhoScreen>());
    for (final size in screens.values) {
      await pumpScreen(tester, size, const WelcomeScreen());
      await settle(tester);
      await tester.tap(find.byType(WelcomeScreen));
      await settle(tester);
      expect(find.byType(WhoScreen), findsOneWidget);
      expect(find.text(L.t('who_plays')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
      await tester.tap(find.byKey(ValueKey('who_${elif.id}')));
      await settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(AppState.I.profile.id, elif.id);
      await unmount(tester);
    }
  });

  testWidgets('gelişim raporu her çocuk için ayrı; oynayan çocuk değişmez', (
    tester,
  ) async {
    final state = AppState.I;
    state.finishLevel('shapes', 1, 3);
    final first = state.profile;
    state.addProfile('Elif', 'rabbit', 4);
    final elif = state.profile;
    // Elif henüz oynamadı; ilk çocuğun yıldızları ondan okunur ama oynayan
    // çocuk Elif kalır.
    expect(state.allStars, 0);
    expect(state.peekProfile(first.id, () => state.allStars), 3);
    expect(state.profile.id, elif.id);
    expect(state.allStars, 0);
    for (final size in screens.values) {
      await pumpScreen(tester, size, ReportScreen(profileId: first.id));
      await settle(tester);
      expect(find.textContaining(state.profileName(first)), findsWidgets);
      await tester.tap(find.byKey(ValueKey('report_${elif.id}')));
      await settle(tester);
      expect(find.textContaining('Elif'), findsWidgets);
      expect(state.profile.id, elif.id);
      expect(tester.takeException(), isNull, reason: '$size');
      // Ebeveyn alanının rapor sekmesi iki çocukla da sığar.
      await pumpScreen(tester, size, const ParentsScreen(initialTab: 4));
      await settle(tester);
      await tester.tap(find.byKey(ValueKey('preport_${first.id}')));
      await settle(tester);
      expect(state.profile.id, elif.id);
      expect(tester.takeException(), isNull, reason: 'rapor sekmesi $size');
      await unmount(tester);
    }
  });

  testWidgets('çocuk eklerken yaş notu görünür, ilk kurulumda görünmez', (
    tester,
  ) async {
    for (final size in screens.values) {
      for (final firstRun in [false, true]) {
        await pumpScreen(
          tester,
          size,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showProfileDialog(context, firstRun: firstRun),
              child: const Text('aç'),
            ),
          ),
        );
        await tester.tap(find.text('aç'));
        await settle(tester);
        expect(
          find.byKey(const ValueKey('age_hint')),
          firstRun ? findsNothing : findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: '$size $firstRun');
        await unmount(tester);
      }
    }
  });

  testWidgets('son bölüm bitince madalya; albümde Madalyalar sayfası', (
    tester,
  ) async {
    final game = games.firstWhere((g) => g.id == 'jobs');
    AppState.I.markHowToSeen(game.id);
    for (var level = 1; level < game.levels; level++) {
      AppState.I.finishLevel(game.id, level, 3);
    }
    await pumpScreen(
      tester,
      screens['tablet']!,
      GameShell(
        game: game,
        level: game.levels,
        rounds: 1,
        instruction: (_) => 'deneme',
        roundBuilder: (round, onSolved, onMistake) => Center(
          child: TextButton(onPressed: onSolved, child: const Text('bitir')),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('bitir'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const ValueKey('new_medal')), findsOneWidget);
    expect(find.text(L.t('new_medal')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester);
    for (final size in screens.values) {
      await pumpScreen(tester, size, const AlbumScreen());
      await settle(tester);
      await tester.tap(find.text(L.t('page_medals')));
      await settle(tester);
      expect(find.byKey(ValueKey('medal_${game.id}')), findsOneWidget);
      expect(find.text('1/${games.length}'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
      await unmount(tester);
    }
  });

  testWidgets('abonelikte kilitli oyunlar açılır', (tester) async {
    AppState.I.setPremium(true);
    await pumpScreen(tester, screens['tablet']!, const HomeScreen());
    await settle(tester);
    await tester.tap(find.text('Gölgeler').last);
    await settle(tester);
    expect(find.byType(LevelScreen), findsOneWidget);
    await unmount(tester);
    AppState.I.setPremium(false);
  });
}

// ---- Ödül sistemi, günün macerası ve profiller ----

void rewardTests() {
  test('ilk bölümler çıkartma kazandırır, tekrar oynamak kazandırmaz', () {
    final state = AppState.I;
    expect(state.stickers, isEmpty);
    expect(state.finishLevel('shapes', 1, 3), isNotNull);
    expect(state.stickers.length, 1);
    expect(
      state.finishLevel('shapes', 1, 3),
      isNull,
      reason: 'aynı bölüm tekrar',
    );
    expect(state.stickers.length, 1);
    expect(state.playsThisWeek, 2);
  });

  test('günün macerası: on yıldız toplanınca günün çıkartması gelir', () {
    final state = AppState.I;
    final tasks = state.dailyTasks(games);
    expect(tasks.length, 3);
    expect({for (final t in tasks) '${t.gameId}:${t.level}'}.length, 3);
    // Ücretsiz kullanıcıya yalnızca aboneliksiz oynanabilen bölümler gelir.
    expect(
      tasks.every(
        (t) =>
            state.canPlay(games.firstWhere((g) => g.id == t.gameId), t.level),
      ),
      isTrue,
    );
    expect(state.dailyComplete, isFalse);
    final reward = state.dailySticker!;
    expect(state.stickers.contains(reward.id), isFalse);
    // Üç bölüm dokuz yıldız eder: hedefe bir yıldız kalır.
    for (final t in tasks) {
      state.finishLevel(t.gameId, t.level, 3);
    }
    expect(state.dailyStars, 9);
    expect(state.dailyComplete, isFalse);
    // Yıldız hangi oyundan gelirse gelsin sayılır; tekrar oynanan bölüm de.
    final won = state.finishLevel(tasks[0].gameId, tasks[0].level, 2);
    expect(state.dailyComplete, isTrue);
    expect(state.dailyStars, AppState.dailyGoal);
    expect(won?.id, reward.id);
    expect(state.stickers.contains(reward.id), isTrue);
    // Hedeften sonra oynamak ikinci bir günlük çıkartma vermez.
    final count = state.stickers.length;
    state.finishLevel(tasks[1].gameId, tasks[1].level, 3);
    expect(state.stickers.length, count);
  });

  test('bölüm sonu çıkartması günün ödülünü almaz', () {
    final state = AppState.I;
    for (var i = 0; i < 30; i++) {
      state.resetProgress();
      state.dailyTasks(games);
      final reward = state.dailySticker!;
      // İlk bölüm her zaman bir çıkartma verir; günün ödülü olmamalı.
      final first = state.finishLevel('maze', 1, 1);
      expect(first, isNotNull);
      expect(first!.id, isNot(reward.id));
    }
  });

  test('bölüm sonunda yalnızca ilk bölüm çıkartma verir', () {
    final state = AppState.I;
    expect(state.finishLevel('shapes', 1, 1), isNotNull);
    for (var level = 2; level <= 9; level++) {
      expect(state.finishLevel('shapes', level, 1), isNull);
    }
    expect(state.stickers.length, 1);
  });

  test('oyunun bütün bölümleri bitince madalya kazanılır', () {
    final state = AppState.I;
    final game = games.firstWhere((g) => g.id == 'jobs');
    for (var level = 1; level < game.levels; level++) {
      state.finishLevel(game.id, level, 2);
      expect(state.gameComplete(game), isFalse);
    }
    state.finishLevel(game.id, game.levels, 1);
    expect(state.gameComplete(game), isTrue);
    // Etkinliklerin bölümü yoktur, madalyaları da yoktur.
    expect(state.gameComplete(activities.first), isFalse);
  });

  test('profillerin ilerlemesi birbirinden ayrıdır', () async {
    final state = AppState.I;
    state.finishLevel('shapes', 1, 3);
    state.addProfile('Elif', 'rabbit');
    expect(state.profiles.length, 2);
    expect(state.profile.name, 'Elif');
    expect(state.stars('shapes', 1), 0);
    expect(state.stickers, isEmpty);
    state.finishLevel('memory', 1, 2);
    final second = state.profile.id;
    state.switchProfile(state.profiles.first.id);
    expect(state.stars('shapes', 1), 3);
    expect(state.stars('memory', 1), 0);
    // Kayıtlar kalıcıdır.
    await state.load();
    expect(state.profiles.length, 2);
    state.switchProfile(second);
    expect(state.stars('memory', 1), 2);
    state.deleteProfile(second);
    expect(state.profiles.length, 1);
    expect(state.stars('shapes', 1), 3);
  });

  test('beceri raporu yıldızlara göre ilerler', () {
    final memory = skills.firstWhere((s) => s.key == 'sk_memory');
    expect(ReportScreen.progress(memory), 0);
    AppState.I.finishLevel('memory', 1, 3);
    final possible = [
      for (final g in games)
        if (memory.gameIds.contains(g.id)) g.levels * 3,
    ].reduce((a, b) => a + b);
    expect(ReportScreen.progress(memory), closeTo(3 / possible, 1e-9));
  });

  test('her oyun bir beceri alanına bağlı', () {
    final covered = {for (final s in skills) ...s.gameIds};
    expect(covered, {for (final g in games) g.id});
  });
}

// ---- Ebeveyn kapısı ----

(int, int) gateQuestion(WidgetTester tester) {
  final text = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((s) => s.contains('×'));
  final m = RegExp(r'(\d+) × (\d+)').firstMatch(text)!;
  return (int.parse(m.group(1)!), int.parse(m.group(2)!));
}

Future<void> gateAnswer(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.text(d).last);
    await tester.pump(const Duration(milliseconds: 150));
  }
  await tester.tap(find.text('✓'));
  await tester.pump(const Duration(milliseconds: 400));
}

void introTests() {
  testWidgets('tanışma konuşması ilk açılışta bir kez gösterilir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(740, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Intro.enabled = true;
    addTearDown(() => Intro.enabled = false);
    for (final lang in L.languages.keys) {
      SharedPreferences.setMockInitialValues({});
      await AppState.I.load();
      AppState.I.setLang(lang);
      await tester.pumpWidget(MaterialApp(home: HomeScreen(key: UniqueKey())));
      await settle(tester);
      expect(find.text(L.t('intro_1')), findsOneWidget, reason: lang);
      for (var i = 2; i <= 4; i++) {
        await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
        await settle(tester);
        expect(find.text(L.t('intro_$i')), findsOneWidget, reason: lang);
      }
      await tester.tap(find.byIcon(Icons.check_rounded));
      await settle(tester);
      expect(find.text(L.t('intro_4')), findsNothing);
      expect(Intro.seen, isTrue);
      expect(tester.takeException(), isNull, reason: lang);
    }
    // İkinci açılışta yeniden çıkmaz.
    await tester.pumpWidget(MaterialApp(home: HomeScreen(key: UniqueKey())));
    await settle(tester);
    expect(find.text(L.t('intro_1')), findsNothing);
    await unmount(tester);
  });
}

void firstRunTests() {
  testWidgets('ilk açılışta ad ve yaş sorulur, profile yazılır', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    HomeScreen.askProfile = true;
    addTearDown(() => HomeScreen.askProfile = false);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(key: UniqueKey())));
    await settle(tester);
    expect(find.text(L.t('setup_title')), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Elif');
    await tester.tap(find.text('4'));
    await settle(tester);
    await tester.tap(find.text(L.t('start')));
    await settle(tester);
    expect(find.text(L.t('setup_title')), findsNothing);
    expect(AppState.I.profile.name, 'Elif');
    expect(AppState.I.profile.age, 4);
    expect(AppState.I.onboarded, isTrue);
    // Yeniden açılınca sorulmaz.
    await tester.pumpWidget(MaterialApp(home: HomeScreen(key: UniqueKey())));
    await settle(tester);
    expect(find.text(L.t('setup_title')), findsNothing);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('ilk kurulum geçilebilir: yaş yoksa en kolay seviye', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    HomeScreen.askProfile = true;
    addTearDown(() => HomeScreen.askProfile = false);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(key: UniqueKey())));
    await settle(tester);
    expect(find.text(L.t('setup_title')), findsOneWidget);
    // Kullanım koşulları ilk kurulumdan okunabilir.
    await tester.tap(find.text(L.t('terms')));
    await settle(tester);
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await settle(tester);
    await tester.tap(find.text(L.t('not_now')));
    await settle(tester);
    expect(find.text(L.t('setup_title')), findsNothing);
    expect(AppState.I.onboarded, isTrue);
    // Yaş girilmedi: zorluk en küçük yaşa göre ayarlanır.
    expect(AppState.I.profile.age, 0);
    expect(AppState.I.playAge, 3);
    expect(AppState.I.extraTolerance, 1);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  test('abonelik hakkı yalnızca Minik Kaşif ürünleriyle sayılır', () {
    // Süresi dolan abonelik mağazanın hak listesinden düşer: liste boşsa ya
    // da içinde bizim ürünümüz yoksa premium kapanır.
    expect(Purchases.entitled([]), isFalse);
    expect(Purchases.entitled(['baska_urun']), isFalse);
    expect(Purchases.entitled([Purchases.monthlyId]), isTrue);
    expect(Purchases.entitled(['baska_urun', Purchases.yearlyId]), isTrue);
  });

  test('aynı nesne ve aynı sayı kısa aralıkla yeniden sorulmaz', () {
    final rng = Random(7);
    // Tek nesne seçen oyunlar (sayma, sıralama, farklı olanı bul...).
    final subjects = [
      for (var i = 0; i < 300; i++) pickObjects(rng, 1).first.id,
    ];
    for (var i = 0; i < subjects.length; i++) {
      for (var back = 1; back <= 8 && i - back >= 0; back++) {
        expect(subjects[i], isNot(subjects[i - back]), reason: 'tur $i');
      }
    }
    // 24 nesnenin hepsi sırayla kullanılır.
    expect(subjects.toSet().length, gameObjects.length);
    // Tek kategoriden seçim (labirent ödülü, zor gölge bölümleri): 8 nesnelik
    // havuzda son dört soru yinelenmez.
    final fruits = [
      for (var i = 0; i < 200; i++) pickObjects(rng, 1, category: 0).first.id,
    ];
    for (var i = 4; i < fruits.length; i++) {
      expect(fruits.sublist(i - 4, i), isNot(contains(fruits[i])));
    }
    // Çoklu seçimde nesneler birbirinden farklıdır, ilk nesne yine yenidir.
    var last = '';
    for (var i = 0; i < 200; i++) {
      final picked = pickObjects(rng, 4, category: i % 3);
      expect(picked.map((o) => o.id).toSet().length, 4);
      expect(picked.first.id, isNot(last));
      last = picked.first.id;
    }
    // Sayma oyununda aynı sayı art arda gelmez.
    for (final max in [3, 5, 7, 10]) {
      var previous = 0;
      for (var i = 0; i < 200; i++) {
        final n = pickNumber(rng, max);
        expect(n, inInclusiveRange(1, max));
        expect(n, isNot(previous));
        previous = n;
      }
    }
  });

  test('3 yaş profilinde yıldızlar bir hata daha hoşgörülü', () {
    final state = AppState.I;
    final id = state.profile.id;
    state.updateProfile(id, 'Elif', 'rabbit', 4);
    expect(state.starsFor(1, 1), 3);
    expect(state.starsFor(2, 1), 2);
    expect(state.starsFor(4, 1), 1);
    state.updateProfile(id, 'Elif', 'rabbit', 3);
    expect(state.starsFor(2, 1), 3);
    expect(state.starsFor(3, 1), 2);
    expect(state.starsFor(7, 1), 1);
  });

  test('günün macerası: biten görevden sonra sıradaki görev gelir', () {
    final state = AppState.I;
    final tasks = state.dailyTasks(games);
    expect(state.nextDailyTask(games)!.gameId, tasks[0].gameId);
    state.finishLevel(tasks[0].gameId, tasks[0].level, 3);
    final next = state.nextDailyTask(games)!;
    expect(
      '${next.gameId}:${next.level}',
      '${tasks[1].gameId}:${tasks[1].level}',
    );
    state.finishLevel(tasks[1].gameId, tasks[1].level, 3);
    state.finishLevel(tasks[2].gameId, tasks[2].level, 3);
    // Üç öneri bitti ama hedefe ulaşılmadı: yeni öneriler gelir.
    final more = state.nextDailyTask(games)!;
    expect(state.dailyDone, isEmpty);
    state.finishLevel(more.gameId, more.level, 3);
    // On yıldız toplandı: macera biter.
    expect(state.nextDailyTask(games), isNull);
  });
}

void gateTests() {
  testWidgets('ebeveyn kapısı: yanlışta soru aynı kalır, doğru yanıt açar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final results = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async =>
                    results.add(await showParentGate(context)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    // Art arda iki dokunuş tek pencere açar.
    await tester.tap(find.text('open'));
    await tester.tap(find.text('open'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Yalnızca yetişkinler'), findsOneWidget);
    results.clear();

    final question = gateQuestion(tester);
    await gateAnswer(tester, '1');
    expect(find.text('Yanlış oldu, tekrar deneyin.'), findsOneWidget);
    expect(
      gateQuestion(tester),
      question,
      reason: 'yanlıştan sonra soru değişmemeli',
    );
    await gateAnswer(tester, '${question.$1 * question.$2}');
    await tester.pump(const Duration(milliseconds: 500));
    expect(results, [true]);
    expect(
      find.text('Yalnızca yetişkinler'),
      findsNothing,
      reason: 'altta eski pencere kalmamalı',
    );
  });
  testWidgets('profil adına dokununca profil penceresi, düzenleme kapıdan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(key: UniqueKey())));
    await settle(tester);
    // Tek profil olsa da pencere açılır ve düzenleme düğmesi görünür.
    await tester.tap(find.text(AppState.I.profileName(AppState.I.profile)));
    await settle(tester);
    expect(find.byKey(const ValueKey('edit_profiles')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit_profiles')));
    await settle(tester);
    // Profil düzenleme yalnızca ebeveyn kapısından geçince açılır.
    expect(find.text(L.t('gate_title')), findsOneWidget);
    expect(find.byKey(const ValueKey('edit_profiles')), findsNothing);
    final question = gateQuestion(tester);
    await gateAnswer(tester, '${question.$1 * question.$2}');
    await settle(tester);
    expect(find.byType(ParentsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
