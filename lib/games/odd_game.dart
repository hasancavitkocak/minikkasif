import 'dart:math';

import 'package:flutter/material.dart';

import '../data/objects.dart';
import '../l10n.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';

/// Farklı olanı bul: aynı nesnelerin arasındaki tek farklı nesneye dokun.
class OddGame extends StatelessWidget {
  const OddGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  @override
  Widget build(BuildContext context) {
    return GameShell(
      game: game,
      level: level,
      rounds: 5,
      instruction: (_) => L.t('i_odd'),
      roundBuilder: (round, onSolved, onMistake) =>
          _OddRound(level: level, onSolved: onSolved, onMistake: onMistake),
    );
  }
}

class _OddRound extends StatefulWidget {
  const _OddRound({
    required this.level,
    required this.onSolved,
    required this.onMistake,
  });
  final int level;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_OddRound> createState() => _OddRoundState();
}

class _OddRoundState extends State<_OddRound> {
  late final List<GameObject> _items;
  late final int _oddIndex;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final level = widget.level;
    final count = level <= 2
        ? 3
        : level <= 4
        ? 4
        : level <= 7
        ? 6
        : level <= 9
        ? 8
        : 10;
    final common = pickObjects(rng, 1).first;
    // İlk bölümlerde farklı nesne başka kategoridendir (elmalar arasında
    // kedi); sonra aynı kategoriden seçilir (elmalar arasında armut).
    final sameCategory = level >= 4;
    var candidates = [
      for (final o in objectPool())
        if (o.id != common.id &&
            (o.category == common.category) == sameCategory)
          o,
    ];
    // Tek kategorili dünyalarda (deniz, uzay) farklı nesne aynı dünyadandır.
    if (candidates.isEmpty) {
      candidates = [
        for (final o in objectPool())
          if (o.id != common.id) o,
      ];
    }
    final odd = candidates[rng.nextInt(candidates.length)];
    _oddIndex = rng.nextInt(count);
    _items = [for (var i = 0; i < count; i++) i == _oddIndex ? odd : common];
  }

  bool _pick(int i) {
    if (i != _oddIndex) {
      widget.onMistake();
      return false;
    }
    widget.onSolved();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final count = _items.length;
    final cols = count <= 4 ? count : (count / 2).ceil();
    final rows = (count / cols).ceil();
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 16.0;
        final size = min(
          (box.maxWidth - gap * (cols + 1)) / cols,
          (box.maxHeight - gap * (rows + 1)) / rows,
        ).clamp(40.0, box.maxHeight * 0.6);
        return Center(
          child: SizedBox(
            width: cols * size + gap * (cols - 1),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < count; i++)
                  ChoiceTile(
                    size: size,
                    onTap: () => _pick(i),
                    child: ObjectImage(_items[i]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
