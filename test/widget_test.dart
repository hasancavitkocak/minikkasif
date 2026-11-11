import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minik_kasif/app_state.dart';
import 'package:minik_kasif/data/objects.dart';
import 'package:minik_kasif/games/game_def.dart';
import 'package:minik_kasif/games/registry.dart';
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
import 'package:minik_kasif/services/audio.dart';
import 'package:minik_kasif/services/purchases.dart';
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
    expect(games.length, 14);
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
          const ParentsScreen(),
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
      await tester.tap(find.byIcon(Icons.close_rounded));
      await settle(tester);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    },
  );

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

  test('günün macerası: üç farklı görev, hepsi bitince tamamlanır', () {
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
    for (final t in tasks) {
      state.finishLevel(t.gameId, t.level, 3);
    }
    expect(state.dailyComplete, isTrue);
    expect(
      state.dailyTasks(games).map((t) => t.gameId),
      tasks.map((t) => t.gameId),
    );
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
}
