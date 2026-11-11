import 'dart:math';

import 'package:flutter/material.dart';

import '../data/objects.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';

/// Sayma: nesneleri say, doğru sayıya dokun.
class CountGame extends StatelessWidget {
  const CountGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  @override
  Widget build(BuildContext context) {
    return GameShell(
      game: game,
      level: level,
      rounds: 5,
      instruction: (_) => L.t('i_count'),
      roundBuilder: (round, onSolved, onMistake) =>
          _CountRound(level: level, onSolved: onSolved, onMistake: onMistake),
    );
  }
}

class _CountRound extends StatefulWidget {
  const _CountRound({
    required this.level,
    required this.onSolved,
    required this.onMistake,
  });
  final int level;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_CountRound> createState() => _CountRoundState();
}

class _CountRoundState extends State<_CountRound> {
  static const _buttonColors = [
    AppColors.pink,
    AppColors.blue,
    AppColors.green,
  ];

  late final GameObject _object;
  late final int _answer;
  late final List<int> _options;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final level = widget.level;
    final maxCount = level <= 2
        ? 3
        : level <= 4
        ? 5
        : level <= 7
        ? 7
        : 10;
    _object = pickObjects(rng, 1).first;
    // Aynı sayı art arda sorulmaz.
    _answer = pickNumber(rng, maxCount);
    // Yanlış seçenekler doğru cevaba yakın sayılardan seçilir.
    final near = [
      for (var n = max(1, _answer - 2); n <= min(maxCount, _answer + 2); n++)
        if (n != _answer) n,
    ]..shuffle(rng);
    _options = [_answer, ...near.take(2)]..shuffle(rng);
  }

  bool _pick(int n) {
    if (n != _answer) {
      widget.onMistake();
      return false;
    }
    Tts.speak('$_answer');
    widget.onSolved();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final buttonSize = min(box.maxHeight / 3 - 12, box.maxWidth * 0.16);
        final panelWidth = box.maxWidth - buttonSize - 48;
        // Nesneler panele sığacak şekilde boyutlanır.
        final cols = _answer <= 3 ? _answer : (_answer / 2).ceil();
        final rows = (_answer / cols).ceil();
        final itemSize =
            min((panelWidth - 48) / cols, (box.maxHeight - 48) / rows) * 0.82;
        return Row(
          children: [
            Expanded(
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: panelDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    spacing: itemSize * 0.12,
                    runSpacing: itemSize * 0.08,
                    children: [
                      for (var i = 0; i < _answer; i++)
                        SizedBox(
                          width: itemSize,
                          height: itemSize,
                          child: ObjectImage(_object),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < _options.length; i++)
                  ChoiceTile(
                    size: buttonSize,
                    color: _buttonColors[i % _buttonColors.length],
                    padding: 0.1,
                    onTap: () => _pick(_options[i]),
                    child: FittedBox(
                      child: Text(
                        '${_options[i]}',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
