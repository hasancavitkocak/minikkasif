import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/objects.dart';
import '../data/stickers.dart';
import '../games/game_def.dart';
import '../games/registry.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import 'common.dart';
import 'how_to.dart';
import 'ui.dart';

/// Bir turun çizimi. Tur çözülünce [onSolved], hatalı denemede [onMistake]
/// çağrılır.
typedef RoundBuilder = Widget Function(
  int round,
  VoidCallback onSolved,
  VoidCallback onMistake,
);

/// Dünyalı bir oyunun bölümünü sarar: bölümün dünyasını seçer ve gerçek bölüm
/// numarasını [GameShell]'e taşır. Oyunun kendisine dünyadaki sıra verilir.
class WorldScope extends StatefulWidget {
  const WorldScope({super.key, required this.level, required this.child});
  final int level;
  final Widget child;

  @override
  State<WorldScope> createState() => _WorldScopeState();
}

class _WorldScopeState extends State<WorldScope> {
  @override
  void initState() {
    super.initState();
    objectWorld = worldOf(widget.level);
  }

  @override
  Widget build(BuildContext context) =>
      _WorldData(level: widget.level, child: widget.child);
}

class _WorldData extends InheritedWidget {
  const _WorldData({required this.level, required super.child});
  final int level;

  @override
  bool updateShouldNotify(_WorldData old) => old.level != level;
}

/// Tüm mini oyunların ortak çerçevesi: arka plan, üst çubuk, sesli yönerge,
/// tur ilerlemesi, kutlama ve bölüm sonu ekranı.
class GameShell extends StatefulWidget {
  const GameShell({
    super.key,
    required this.game,
    required this.level,
    required this.rounds,
    required this.instruction,
    required this.roundBuilder,
    this.tolerance = 1,
    this.background = 'meadow',
  });

  final GameDef game;
  final int level;
  final int rounds;

  /// Turun yönergesi (hem yazılı görünür hem seslendirilir).
  final String Function(int round) instruction;
  final RoundBuilder roundBuilder;

  /// 3 yıldız için izin verilen hata sayısı.
  final int tolerance;
  final String background;

  /// Bölüm günün macerasından açıldıysa true: bitince aynı oyunun sonraki
  /// bölümüne değil, maceranın sıradaki görevine geçilir.
  static bool dailyRun = false;

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  int _round = 0;
  int _attempt = 0;
  int _mistakes = 0;
  bool _celebrating = false;
  int? _earnedStars;
  String _pose = 'thinking';
  String? _lastSpoken;
  String _praise = '';
  Sticker? _newSticker;
  final List<Timer> _timers = [];
  final bool _daily = GameShell.dailyRun;

  /// Kaydedilen bölüm numarası. Dünyalı oyunlarda [GameShell.level] dünyanın
  /// içindeki sıradır (zorluk), gerçek bölüm [WorldScope] içinden gelir.
  late final int _level;

  String get _background => worldOf(_level) == 0
      ? widget.background
      : const ['meadow', 'sea', 'space'][worldOf(_level).clamp(0, 2)];

  @override
  void initState() {
    super.initState();
    final scope = context.getInheritedWidgetOfExactType<_WorldData>();
    _level = scope?.level ?? widget.level;
    // Dünyasız oyunlar her zaman ilk dünyanın nesneleriyle oynanır.
    if (scope == null) objectWorld = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Oyun ilk kez açılıyorsa önce nasıl oynandığı gösterilir. Günün
      // macerasında oyunlar karışık geldiği için anlatım her görevde açılır.
      if (_daily || !AppState.I.seenHowTo(widget.game.id)) {
        AppState.I.markHowToSeen(widget.game.id);
        _showHowTo();
      } else {
        _speakInstruction();
      }
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    Tts.stopFor(this);
    super.dispose();
  }

  void _after(int ms, VoidCallback action) {
    _timers.add(
      Timer(Duration(milliseconds: ms), () {
        if (mounted) action();
      }),
    );
  }

  void _speakInstruction({bool force = false}) {
    final text = widget.instruction(_round);
    if (!force && text == _lastSpoken) return;
    _lastSpoken = text;
    Tts.speak(text, owner: this);
  }

  void _showHowTo() {
    // Anlatım açılırken yönerge sesli okunur.
    _speakInstruction(force: true);
    showHowTo(context, widget.game, widget.instruction(_round));
  }

  void _onSolved() {
    if (_celebrating || _earnedStars != null) return;
    Sfx.play('correct');
    setState(() {
      _celebrating = true;
      _pose = 'happy';
    });
    _after(1200, () {
      if (_round + 1 >= widget.rounds) {
        _finish();
      } else {
        setState(() {
          _round++;
          _celebrating = false;
          _pose = 'thinking';
        });
        _speakInstruction();
      }
    });
  }

  void _onMistake() {
    if (_celebrating) return;
    _mistakes++;
    Sfx.play('wrong');
    setState(() => _pose = 'oops');
    _after(900, () {
      if (!_celebrating) setState(() => _pose = 'thinking');
    });
  }

  void _finish() {
    final stars = AppState.I.starsFor(_mistakes, widget.tolerance);
    _newSticker = AppState.I.finishLevel(widget.game.id, _level, stars);
    Sfx.play('win');
    _praise = L.praise();
    Tts.speak(_praise, owner: this);
    // Övgünün ardından yeni çıkartma da sesli duyurulur.
    if (_newSticker != null) {
      _after(1700, () => Tts.speak(L.t('new_sticker'), owner: this));
    }
    setState(() => _earnedStars = stars);
  }

  void _replay() {
    _quiet();
    setState(() {
      _round = 0;
      _attempt++;
      _mistakes = 0;
      _celebrating = false;
      _earnedStars = null;
      _newSticker = null;
      _pose = 'thinking';
    });
    _speakInstruction(force: true);
  }

  /// Bekleyen zamanlayıcıları (ör. gecikmeli "yeni çıkartma" duyurusu) iptal
  /// eder ve bu bölümün konuşmasını susturur; ekrandan çıkarken çağrılır.
  void _quiet() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    Tts.stopFor(this);
  }

  void _next() {
    _quiet();
    var game = widget.game;
    var level = _level + 1;
    if (_daily) {
      final task = AppState.I.nextDailyTask(games);
      if (task == null) {
        // Macera bitti: görev ekranına dönülür, hediye orada açılır.
        Navigator.of(context).pop();
        return;
      }
      game = games.firstWhere((g) => g.id == task.gameId);
      level = task.level;
    } else if (!AppState.I.canPlay(game, level)) {
      // Sonraki bölüm ücretli: bölüm haritasına dönülür, kilit orada görünür.
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => game.builder(game, level)),
    );
  }

  void _goHome() {
    _quiet();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final finished = _earnedStars != null;
    return Scaffold(
      body: Stack(
        children: [
          Backdrop(_background),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  _topBar(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: _celebrating || finished,
                      child: KeyedSubtree(
                        key: ValueKey('$_attempt-$_round'),
                        child: widget.roundBuilder(
                          _round,
                          _onSolved,
                          _onMistake,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_celebrating || finished)
            Positioned.fill(
              child: ConfettiBurst(
                key: ValueKey('c$_attempt-$_round-$finished'),
              ),
            ),
          if (finished) _resultOverlay(_earnedStars!),
        ],
      ),
    );
  }

  Widget _topBar() {
    final text = widget.instruction(_round);
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          const BackRoundButton(),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              key: ValueKey(_pose),
              width: 64,
              height: 64,
              child: Mascot(_pose),
            ),
          ),
          // Maskotun konuşma balonu: yönerge yazılı görünür, dokununca okunur.
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Pressable(
                onTap: () => _speakInstruction(force: true),
                child: SpeechBubble(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.pink,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle.copyWith(fontSize: 18, height: 1.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bölümün içinden doğrudan ana sayfaya dönüş.
          RoundButton(
            icon: Icons.home_rounded,
            color: AppColors.orange,
            size: 46,
            onTap: _goHome,
          ),
          const SizedBox(width: 8),
          RoundButton(
            icon: Icons.question_mark_rounded,
            color: AppColors.blue,
            size: 46,
            onTap: _showHowTo,
          ),
          if (widget.rounds > 1) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < widget.rounds; i++)
                    Icon(
                      Icons.star_rounded,
                      size: 26,
                      color:
                          i < _round ||
                              (i == _round &&
                                  (_celebrating || _earnedStars != null))
                          ? AppColors.yellow
                          : AppColors.grey.withValues(alpha: 0.6),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultOverlay(int stars) {
    final hasNext = _daily || _level < widget.game.levels;
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.ink.withValues(alpha: 0.35),
        child: Center(
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ToyPanel(
                padding: const EdgeInsets.fromLTRB(36, 14, 36, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Bobbing(
                      child: SizedBox(
                        width: 110,
                        height: 110,
                        child: Mascot('happy'),
                      ),
                    ),
                    StrokeText(_praise, size: 36, color: AppColors.yellow),
                    Text(
                      L.t('level_done'),
                      style: titleStyle.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 6),
                    PopIn(delay: 3, child: StarsRow(stars, size: 56)),
                    if (_newSticker != null) ...[
                      const SizedBox(height: 8),
                      // Bu bölümle kazanılan yeni çıkartma.
                      PopIn(
                        delay: 7,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
                          decoration: BoxDecoration(
                            color: AppColors.yellow.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppColors.yellow,
                              width: 3,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 58,
                                height: 58,
                                child: StickerImage(_newSticker!),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                L.t('new_sticker'),
                                style: titleStyle.copyWith(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RoundButton(
                          icon: Icons.home_rounded,
                          color: AppColors.blue,
                          asset: 'btn_home',
                          size: 76,
                          onTap: _goHome,
                        ),
                        const SizedBox(width: 20),
                        RoundButton(
                          icon: Icons.replay_rounded,
                          color: AppColors.purple,
                          asset: 'btn_replay',
                          size: 76,
                          onTap: _replay,
                        ),
                        if (hasNext) ...[
                          const SizedBox(width: 20),
                          RoundButton(
                            icon: Icons.arrow_forward_rounded,
                            color: AppColors.green,
                            asset: 'btn_next',
                            size: 88,
                            onTap: _next,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
