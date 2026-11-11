import 'dart:math';

import 'package:flutter/material.dart';

import '../data/objects.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';

/// Örüntü tamamlama: sıradaki eksik nesneyi bul.
class PatternGame extends StatelessWidget {
  const PatternGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  @override
  Widget build(BuildContext context) {
    return GameShell(
      game: game,
      level: level,
      rounds: 5,
      background: 'space',
      instruction: (_) => L.t('i_pattern'),
      roundBuilder: (round, onSolved, onMistake) =>
          _PatternRound(level: level, onSolved: onSolved, onMistake: onMistake),
    );
  }
}

class _PatternRound extends StatefulWidget {
  const _PatternRound({
    required this.level,
    required this.onSolved,
    required this.onMistake,
  });
  final int level;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_PatternRound> createState() => _PatternRoundState();
}

class _PatternRoundState extends State<_PatternRound> {
  late final List<GameObject> _sequence;
  late final int _missing;
  late final List<GameObject> _options;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final level = widget.level;
    // Tekrarlayan birim: 0, 1, 2 farklı nesneleri gösterir.
    final units = level <= 3
        ? [
            [0, 1],
          ]
        : level <= 5
        ? [
            [0, 0, 1],
            [0, 1, 1],
          ]
        : level <= 7
        ? [
            [0, 1, 2],
          ]
        : [
            [0, 0, 1, 1],
            [0, 1, 2],
            [0, 1, 1],
            [0, 0, 1],
          ];
    final unit = units[rng.nextInt(units.length)];
    final kinds = unit.reduce(max) + 1;
    final objects = pickObjects(rng, 3);
    final length = unit.length == 4 ? 8 : 6;
    _sequence = [
      for (var i = 0; i < length; i++) objects[unit[i % unit.length]],
    ];
    // İleri bölümlerde eksik nesne sonda değil, ortada olabilir.
    _missing = level >= 9
        ? unit.length + rng.nextInt(length - unit.length)
        : length - 1;
    final optionCount = level <= 3 ? 2 : 3;
    _options = objects.take(max(kinds, optionCount)).toList()..shuffle(rng);
  }

  bool _pick(GameObject object) {
    if (object.id != _sequence[_missing].id) {
      widget.onMistake();
      return false;
    }
    setState(() => _solved = true);
    widget.onSolved();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final n = _sequence.length;
        final cell = min(
          box.maxHeight * 0.36,
          (box.maxWidth - 8.0 * (n - 1)) / n,
        );
        final optionSize = min(box.maxHeight * 0.38, box.maxWidth / 5);
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < n; i++)
                  Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                    child: _cell(i, cell),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final object in _options)
                  ChoiceTile(
                    size: optionSize,
                    onTap: () => _pick(object),
                    child: ObjectImage(object),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _cell(int i, double size) {
    final hidden = i == _missing && !_solved;
    final isSlot = i == _missing;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isSlot ? 0.95 : 0.6),
        borderRadius: BorderRadius.circular(size * 0.2),
        border: isSlot
            ? Border.all(color: AppColors.orange, width: size * 0.05)
            : null,
      ),
      child: hidden
          ? const FittedBox(
              child: Text(
                '?',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: AppColors.orange,
                ),
              ),
            )
          : ObjectImage(_sequence[i]),
    );
  }
}
