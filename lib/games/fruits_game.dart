import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/produce.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';
import 'quiz_round.dart';

/// Meyve ve Sebze oyununun aşamaları.
enum FruitsMode {
  /// Ürünler tek tek tanıtılır: adı, meyve mi sebze mi, nerede yetişir.
  learn,

  /// Adı söyleneni bul.
  find,

  /// Söylenen renkteki ürünü bul.
  color,

  /// Meyveler arasındaki sebzeyi (ya da sebzeler arasındaki meyveyi) bul.
  kind,

  /// Ağaçta yetişeni bul.
  tree,
}

/// Meyve ve Sebze: önce tanıtım, sonra adı söyleneni bulma, renge göre bulma,
/// meyve ile sebzeyi ayırma ve ağaçta yetişeni bulma. Sorulan her bilgi
/// (meyve mi sebze mi, nerede yetişir) tanıtım kartında söylenmiştir.
class FruitsGame extends StatefulWidget {
  const FruitsGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  static FruitsMode modeOf(int level) => switch (level) {
    <= 3 => FruitsMode.learn,
    <= 5 => FruitsMode.find,
    <= 7 => FruitsMode.color,
    8 => FruitsMode.kind,
    _ => FruitsMode.tree,
  };

  /// Tanıtım bölümlerinde gösterilen ürünler: 6, 6 ve 5 tane.
  static List<Produce> learnSet(int level) => switch (level) {
    1 => produce.sublist(0, 6),
    2 => produce.sublist(6, 12),
    _ => produce.sublist(12),
  };

  @override
  State<FruitsGame> createState() => _FruitsGameState();
}

class _FruitsGameState extends State<FruitsGame> {
  static const _rounds = 5;

  /// Renk turlarında her turun rengi; art arda aynı renk gelmez.
  late final List<ProduceColor> _colors;

  /// Meyve-sebze turlarında her turda aranan tür; dönüşümlü.
  late final List<ProduceKind> _kinds;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final colors = ProduceColor.values.toList()..shuffle(rng);
    _colors = [for (var i = 0; i < _rounds; i++) colors[i % colors.length]];
    final first = rng.nextBool() ? ProduceKind.veg : ProduceKind.fruit;
    _kinds = [
      for (var i = 0; i < _rounds; i++)
        i.isEven
            ? first
            : (first == ProduceKind.veg ? ProduceKind.fruit : ProduceKind.veg),
    ];
  }

  String _instruction(FruitsMode mode, int round) => switch (mode) {
    FruitsMode.learn => 'i_fruits_learn',
    FruitsMode.find => 'i_fruits_find',
    FruitsMode.color => _colors[round % _rounds].instructionKey,
    FruitsMode.kind =>
      _kinds[round % _rounds] == ProduceKind.veg
          ? 'i_fruits_veg'
          : 'i_fruits_fruit',
    FruitsMode.tree => 'i_fruits_tree',
  };

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final mode = FruitsGame.modeOf(level);
    final learn = FruitsGame.learnSet(level);
    return GameShell(
      game: widget.game,
      level: level,
      rounds: mode == FruitsMode.learn ? learn.length : _rounds,
      instruction: (round) => L.t(_instruction(mode, round)),
      roundBuilder: (round, onSolved, onMistake) {
        if (mode == FruitsMode.learn) {
          final item = learn[round % learn.length];
          return LearnRound(
            image: ObjectImage(item.image),
            nameKey: item.nameKey,
            textKey: item.kindKey,
            textKey2: item.growKey,
            first: round == 0,
            onDone: onSolved,
          );
        }
        return _FruitsRound(
          level: level,
          mode: mode,
          color: _colors[round % _rounds],
          kind: _kinds[round % _rounds],
          instructionKey: _instruction(mode, round),
          first: round == 0,
          onSolved: onSolved,
          onMistake: onMistake,
        );
      },
    );
  }
}

class _FruitsRound extends StatefulWidget {
  const _FruitsRound({
    required this.level,
    required this.mode,
    required this.color,
    required this.kind,
    required this.instructionKey,
    required this.first,
    required this.onSolved,
    required this.onMistake,
  });
  final int level;
  final FruitsMode mode;
  final ProduceColor color;
  final ProduceKind kind;
  final String instructionKey;

  /// Bölümün ilk turu mu? İlk turda yönerge okunduğu için ad biraz bekleyip
  /// söylenir.
  final bool first;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_FruitsRound> createState() => _FruitsRoundState();
}

class _FruitsRoundState extends State<_FruitsRound> {
  static final _recent = RecentPicker(4);

  late final Produce _answer;
  late final List<Produce> _options;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final level = widget.level;
    final count = switch (widget.mode) {
      FruitsMode.find => level <= 4 ? 3 : 4,
      FruitsMode.color => level <= 6 ? 3 : 4,
      FruitsMode.kind => 3,
      _ => level <= 9 ? 3 : 4,
    };
    // Sorunun cevabı olabilecekler ve yanlış seçenek olabilecekler.
    final (answers, wrong) = switch (widget.mode) {
      FruitsMode.find => (produce, produce),
      FruitsMode.color => (
        [
          for (final p in produce)
            if (p.color == widget.color) p,
        ],
        [
          for (final p in produce)
            if (p.color != null && p.color != widget.color) p,
        ],
      ),
      FruitsMode.kind => (
        [
          for (final p in produce)
            if (p.kind == widget.kind) p,
        ],
        [
          for (final p in produce)
            if (p.kind != widget.kind) p,
        ],
      ),
      _ => (
        [
          for (final p in produce)
            if (p.grow == Grow.tree) p,
        ],
        // Asma (üzüm) ve sıcak ülkeler (muz) karışabileceği için sorulmaz.
        [
          for (final p in produce)
            if (p.grow == Grow.field || p.grow == Grow.under) p,
        ],
      ),
    };
    _answer = answers[_recent.pick(rng, answers.length)];
    final others = [
      for (final p in wrong)
        if (p != _answer) p,
    ]..shuffle(rng);
    if (widget.mode == FruitsMode.color) {
      // Yanlış seçenekler mümkünse birbirinden de farklı renkte olur.
      final distinct = <Produce>[];
      final used = <ProduceColor?>{};
      for (final p in others) {
        if (used.add(p.color)) distinct.add(p);
      }
      others
        ..removeWhere(distinct.contains)
        ..insertAll(0, distinct);
    }
    _options = [_answer, ...others.take(count - 1)]..shuffle(rng);
    if (widget.mode == FruitsMode.find) {
      _timer = Timer(Duration(milliseconds: widget.first ? 2600 : 700), () {
        if (mounted) _sayName();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _sayName() => Tts.speak(L.t(_answer.nameKey), key: _answer.nameKey);

  void _sayInstruction() =>
      Tts.speak(L.t(widget.instructionKey), key: widget.instructionKey);

  Widget _prompt() {
    switch (widget.mode) {
      case FruitsMode.find:
        return Pressable(onTap: _sayName, child: const SpeakerArt());
      case FruitsMode.color:
        // Aranan renk büyük bir boya lekesi olarak da görünür.
        return Pressable(
          onTap: _sayInstruction,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DecoratedBox(
              key: ValueKey('color_${widget.color.name}'),
              decoration: BoxDecoration(
                color: widget.color.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      case FruitsMode.tree:
        return Pressable(
          onTap: _sayInstruction,
          // Soru "Hangisi ağaçta yetişir?": büyük bir ağaç görseli.
          child: const GameImage(
            'assets/images/ui/prompt_tree.png',
            fallback: FittedBox(
              child: Icon(Icons.park_rounded, color: Color(0xFF43A047)),
            ),
          ),
        );
      default:
        return Pressable(onTap: _sayInstruction, child: const SpeakerArt());
    }
  }

  @override
  Widget build(BuildContext context) {
    return QuizRound(
      prompt: _prompt(),
      options: [for (final p in _options) ObjectImage(p.image)],
      answer: _options.indexOf(_answer),
      onSolved: () {
        // Doğru bulunanın adı söylenir.
        _sayName();
        widget.onSolved();
      },
      onMistake: widget.onMistake,
    );
  }
}
