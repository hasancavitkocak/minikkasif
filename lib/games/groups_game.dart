import 'dart:math';

import 'package:flutter/material.dart';

import '../data/objects.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';

/// Gruplama: nesneleri türüne göre (meyve, hayvan, taşıt) doğru sepete taşı.
class GroupsGame extends StatelessWidget {
  const GroupsGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  @override
  Widget build(BuildContext context) {
    return GameShell(
      game: game,
      level: level,
      rounds: 3,
      instruction: (_) => L.t('i_groups'),
      roundBuilder: (round, onSolved, onMistake) =>
          _GroupsRound(level: level, onSolved: onSolved, onMistake: onMistake),
    );
  }
}

class _GroupsRound extends StatefulWidget {
  const _GroupsRound({
    required this.level,
    required this.onSolved,
    required this.onMistake,
  });
  final int level;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_GroupsRound> createState() => _GroupsRoundState();
}

class _GroupsRoundState extends State<_GroupsRound> {
  static const _itemCounts = [4, 4, 5, 6, 6, 6, 6, 7, 8, 9];
  static const _basketColors = [AppColors.red, AppColors.blue, AppColors.green];

  late final List<int> _categories;

  /// Her sepetin üstünde duran, o türü temsil eden örnek nesne.
  late final List<GameObject> _signs;
  late final List<GameObject> _items;
  final Map<int, List<GameObject>> _sorted = {};

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final level = widget.level;
    _categories = ([0, 1, 2]..shuffle(rng)).take(level >= 7 ? 3 : 2).toList();
    _signs = [
      for (final c in _categories) pickObjects(rng, 1, category: c).first,
    ];
    final count = _itemCounts[(level - 1).clamp(0, _itemCounts.length - 1)];
    final pool = [
      for (final o in gameObjects)
        if (_categories.contains(o.category) && !_signs.contains(o)) o,
    ]..shuffle(rng);
    // Her türden en az bir nesne bulunur.
    final picked = <GameObject>[
      for (final c in _categories) pool.firstWhere((o) => o.category == c),
    ];
    for (final o in pool) {
      if (picked.length >= count) break;
      if (!picked.contains(o)) picked.add(o);
    }
    _items = picked..shuffle(rng);
    for (final c in _categories) {
      _sorted[c] = [];
    }
  }

  void _drop(int category, GameObject object) {
    if (object.category != category) {
      widget.onMistake();
      return;
    }
    setState(() {
      _items.remove(object);
      _sorted[category]!.add(object);
    });
    if (_items.isEmpty) {
      widget.onSolved();
    } else {
      Sfx.play('pop');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final total =
            _items.length + _sorted.values.fold(0, (a, b) => a + b.length);
        final itemSize = min(
          box.maxHeight * 0.3,
          (box.maxWidth - 16) / total - 8,
        );
        final basketHeight = box.maxHeight * 0.52;
        final basketWidth = min(
          (box.maxWidth - 24.0 * (_categories.length - 1)) / _categories.length,
          box.maxWidth * 0.42,
        );
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: box.maxHeight * 0.36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final object in _items)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Draggable<GameObject>(
                        data: object,
                        feedback: SizedBox(
                          width: itemSize * 1.15,
                          height: itemSize * 1.15,
                          child: ObjectImage(object),
                        ),
                        childWhenDragging: SizedBox(
                          width: itemSize,
                          height: itemSize,
                        ),
                        child: Container(
                          width: itemSize,
                          height: itemSize,
                          padding: EdgeInsets.all(itemSize * 0.1),
                          decoration: panelDecoration(radius: itemSize * 0.22),
                          child: ObjectImage(object),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final (i, category) in _categories.indexed)
                  DragTarget<GameObject>(
                    onAcceptWithDetails: (details) =>
                        _drop(category, details.data),
                    builder: (context, candidates, _) => _basket(
                      i,
                      category,
                      basketWidth,
                      basketHeight,
                      candidates.isNotEmpty,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _basket(
    int index,
    int category,
    double width,
    double height,
    bool hover,
  ) {
    final color = _basketColors[index];
    final inside = _sorted[category]!;
    final sign = height * 0.42;
    final mini = min(
      height * 0.38,
      (width - sign - 40) / max(3, inside.length),
    );
    return AnimatedScale(
      scale: hover ? 1.06 : 1,
      duration: const Duration(milliseconds: 120),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color.lerp(color, Colors.white, 0.72),
          borderRadius: BorderRadius.circular(height * 0.2),
          border: Border.all(color: color, width: 5),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Sepetin tabelası: bu sepete ne tür şeylerin gireceğini gösterir.
            Container(
              width: sign,
              height: sign,
              padding: EdgeInsets.all(sign * 0.1),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 4),
              ),
              child: ObjectImage(_signs[index]),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: [
                  for (final object in inside)
                    SizedBox(
                      width: mini,
                      height: mini,
                      child: ObjectImage(object),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
