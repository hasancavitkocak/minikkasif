import 'dart:math';

import 'package:flutter/material.dart';

import '../data/objects.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';

/// Farkı bul: yan yana iki resim arasındaki farklara dokun.
class DiffGame extends StatelessWidget {
  const DiffGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  // (sütun, satır, fark sayısı)
  static const _setups = [
    (2, 2, 1),
    (3, 2, 1),
    (3, 2, 2),
    (3, 3, 2),
    (3, 3, 3),
    (4, 3, 3),
    (4, 3, 3),
    (4, 3, 4),
    (4, 4, 4),
    (4, 4, 5),
  ];

  @override
  Widget build(BuildContext context) {
    final (cols, rows, diffs) =
        _setups[(level - 1).clamp(0, _setups.length - 1)];
    return GameShell(
      game: game,
      level: level,
      rounds: 3,
      background: 'sea',
      instruction: (_) => L.t('i_diff'),
      roundBuilder: (round, onSolved, onMistake) => _DiffRound(
        cols: cols,
        rows: rows,
        diffs: diffs,
        // İleri bölümlerde ters çevrilmiş ya da eksik nesneler de fark olur.
        subtle: level >= 5,
        onSolved: onSolved,
        onMistake: onMistake,
      ),
    );
  }
}

/// Sağdaki resimde bir hücrenin soldakinden nasıl farklı olduğu.
enum _Change { none, replaced, mirrored, missing }

class _DiffRound extends StatefulWidget {
  const _DiffRound({
    required this.cols,
    required this.rows,
    required this.diffs,
    required this.subtle,
    required this.onSolved,
    required this.onMistake,
  });
  final int cols;
  final int rows;
  final int diffs;
  final bool subtle;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_DiffRound> createState() => _DiffRoundState();
}

class _DiffRoundState extends State<_DiffRound> {
  /// Ters çevrildiğinde farkı açıkça görülen (simetrik olmayan) nesneler.
  static const _asymmetric = {
    'fish',
    'bird',
    'car',
    'bus',
    'plane',
    'train',
    'elephant',
    'dog',
    'cat',
    'banana',
    'boat',
  };

  late final List<GameObject> _left;
  late final List<GameObject> _right;
  late final List<_Change> _changes;
  final Set<int> _found = {};

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final count = widget.cols * widget.rows;
    final pool = pickObjects(rng, count + widget.diffs);
    // Nesnesi az olan dünyalarda (deniz, uzay) aynı nesne yeniden kullanılır.
    final picked = [
      for (var i = 0; i < count + widget.diffs; i++) pool[i % pool.length],
    ];
    _left = picked.take(count).toList();
    final spares = picked.skip(count).toList();
    _right = [..._left];
    _changes = List.filled(count, _Change.none);
    final cells = List.generate(count, (i) => i)..shuffle(rng);
    for (var d = 0; d < widget.diffs; d++) {
      final cell = cells[d];
      final options = [
        _Change.replaced,
        if (widget.subtle) _Change.missing,
        if (widget.subtle && _asymmetric.contains(_left[cell].id))
          _Change.mirrored,
      ];
      _changes[cell] = options[rng.nextInt(options.length)];
      if (_changes[cell] == _Change.replaced) {
        _right[cell] = [
          ...spares.skip(d),
          ...pool,
        ].firstWhere((o) => o.id != _left[cell].id);
      }
    }
  }

  bool _tap(int cell) {
    if (_found.contains(cell)) return true;
    if (_changes[cell] == _Change.none) {
      widget.onMistake();
      return false;
    }
    setState(() => _found.add(cell));
    if (_found.length == widget.diffs) {
      widget.onSolved();
    } else {
      Sfx.play('pop');
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cols = widget.cols;
    final rows = widget.rows;
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 6.0;
        const pad = 10.0;
        final panelWidth = (box.maxWidth - 20) / 2;
        final cell = min(
          (panelWidth - pad * 2 - gap * (cols - 1)) / cols,
          (box.maxHeight - 46 - pad * 2 - gap * (rows - 1)) / rows,
        );
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bulunan fark sayısı.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.diffs; i++)
                  Icon(
                    i < _found.length
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: i < _found.length ? AppColors.green : AppColors.ink,
                    size: 26,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _panel(false, cell, gap, pad),
                  _panel(true, cell, gap, pad),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _panel(bool right, double cell, double gap, double pad) {
    final cols = widget.cols;
    return Container(
      // 4'er piksellik kenarlık ve yuvarlama payı dahil.
      width: cols * cell + gap * (cols - 1) + pad * 2 + 9,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: right ? AppColors.orange : AppColors.blue,
          width: 4,
        ),
      ),
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var i = 0; i < _left.length; i++) _cell(i, right, cell),
        ],
      ),
    );
  }

  Widget _cell(int i, bool right, double size) {
    final change = right ? _changes[i] : _Change.none;
    Widget image = ObjectImage(right ? _right[i] : _left[i]);
    if (change == _Change.mirrored) {
      image = Transform.flip(flipX: true, child: image);
    } else if (change == _Change.missing) {
      image = const SizedBox.expand();
    }
    return ChoiceTile(
      size: size,
      padding: 0.08,
      color: _found.contains(i) ? const Color(0xFFCFF5DA) : Colors.white,
      onTap: () => _tap(i),
      child: image,
    );
  }
}
