import 'dart:math';

import 'package:flutter/material.dart';

import '../data/objects.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import '../widgets/ui.dart';
import 'game_def.dart';

/// Labirent: tilkiyi parmakla sürükleyerek yoldan geçir, yiyeceğe ulaştır.
class MazeGame extends StatelessWidget {
  const MazeGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  static const _sizes = [
    (4, 3),
    (5, 3),
    (5, 4),
    (6, 4),
    (7, 4),
    (7, 5),
    (8, 5),
    (9, 5),
    (9, 6),
    (10, 6),
  ];

  @override
  Widget build(BuildContext context) {
    final (cols, rows) = _sizes[(level - 1).clamp(0, _sizes.length - 1)];
    return GameShell(
      game: game,
      level: level,
      rounds: 2,
      instruction: (_) => L.t('i_maze'),
      roundBuilder: (round, onSolved, onMistake) => _MazeRound(
        cols: cols,
        rows: rows,
        color: game.color,
        onSolved: onSolved,
      ),
    );
  }
}

// Bir hücreden açık olan yönler (bit maskesi).
const _right = 1;
const _down = 2;
const _left = 4;
const _up = 8;

class _MazeRound extends StatefulWidget {
  const _MazeRound({
    required this.cols,
    required this.rows,
    required this.color,
    required this.onSolved,
  });
  final int cols;
  final int rows;
  final Color color;
  final VoidCallback onSolved;

  @override
  State<_MazeRound> createState() => _MazeRoundState();
}

class _MazeRoundState extends State<_MazeRound> {
  late final List<int> _open;
  late final int _goal;
  late final GameObject _prize;

  /// Tilkinin geçtiği hücreler; geri dönünce iz kısalır.
  final List<int> _trail = [0];
  bool _done = false;

  int get _cols => widget.cols;
  int get _rows => widget.rows;
  int get _player => _trail.last;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _prize = pickObjects(rng, 1, category: 0).first;
    // Derinlik öncelikli kazı: her hücreye tek bir yoldan ulaşılan labirent.
    _open = List.filled(_cols * _rows, 0);
    final visited = <int>{0};
    final stack = [0];
    while (stack.isNotEmpty) {
      final cell = stack.last;
      final options = [
        for (final (dir, next) in _neighbors(cell))
          if (!visited.contains(next)) (dir, next),
      ];
      if (options.isEmpty) {
        stack.removeLast();
        continue;
      }
      final (dir, next) = options[rng.nextInt(options.length)];
      _open[cell] |= dir;
      _open[next] |= _opposite(dir);
      visited.add(next);
      stack.add(next);
    }
    // Hedef, başlangıca en uzak hücredir.
    final distance = {0: 0};
    final queue = [0];
    var farthest = 0;
    while (queue.isNotEmpty) {
      final cell = queue.removeAt(0);
      if (distance[cell]! > distance[farthest]!) farthest = cell;
      for (final (dir, next) in _neighbors(cell)) {
        if (_open[cell] & dir != 0 && !distance.containsKey(next)) {
          distance[next] = distance[cell]! + 1;
          queue.add(next);
        }
      }
    }
    _goal = farthest;
  }

  int _opposite(int dir) => switch (dir) {
    _right => _left,
    _left => _right,
    _down => _up,
    _ => _down,
  };

  List<(int, int)> _neighbors(int cell) {
    final x = cell % _cols;
    final y = cell ~/ _cols;
    return [
      if (x < _cols - 1) (_right, cell + 1),
      if (y < _rows - 1) (_down, cell + _cols),
      if (x > 0) (_left, cell - 1),
      if (y > 0) (_up, cell - _cols),
    ];
  }

  /// Parmağın bulunduğu hücreye doğru, duvar yoksa adım adım ilerler.
  void _moveToward(Offset position, double cell) {
    if (_done) return;
    final tx = (position.dx / cell).floor().clamp(0, _cols - 1);
    final ty = (position.dy / cell).floor().clamp(0, _rows - 1);
    var moved = false;
    for (var step = 0; step < 6; step++) {
      final dx = tx - _player % _cols;
      final dy = ty - _player ~/ _cols;
      if (dx == 0 && dy == 0) break;
      final horizontal = dx > 0 ? (_right, _player + 1) : (_left, _player - 1);
      final vertical = dy > 0
          ? (_down, _player + _cols)
          : (_up, _player - _cols);
      final tries = [
        if (dx.abs() >= dy.abs() && dx != 0) horizontal,
        if (dy != 0) vertical,
        if (dx.abs() < dy.abs() && dx != 0) horizontal,
      ];
      (int, int)? choice;
      for (final option in tries) {
        if (_open[_player] & option.$1 != 0) {
          choice = option;
          break;
        }
      }
      if (choice == null) break;
      final next = choice.$2;
      if (_trail.length > 1 && _trail[_trail.length - 2] == next) {
        _trail.removeLast();
      } else {
        _trail.add(next);
      }
      moved = true;
      if (next == _goal) break;
    }
    if (!moved) return;
    setState(() {});
    if (_player == _goal) {
      _done = true;
      widget.onSolved();
    } else {
      Sfx.play('pop');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cell = min(box.maxWidth / _cols, box.maxHeight / _rows);
        Offset corner(int index) =>
            Offset((index % _cols) * cell, (index ~/ _cols) * cell);
        final sprite = cell * 0.82;
        final inset = (cell - sprite) / 2;
        return Center(
          // Labirent her dilde soldan sağa çizilir.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: GestureDetector(
              onPanStart: (d) => _moveToward(d.localPosition, cell),
              onPanUpdate: (d) => _moveToward(d.localPosition, cell),
              onTapDown: (d) => _moveToward(d.localPosition, cell),
              child: SizedBox(
                width: cell * _cols,
                height: cell * _rows,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MazePainter(_open, _cols, _rows, [
                          ..._trail,
                        ], widget.color),
                      ),
                    ),
                    Positioned(
                      left: corner(_goal).dx + inset,
                      top: corner(_goal).dy + inset,
                      width: sprite,
                      height: sprite,
                      child: Bobbing(distance: 3, child: ObjectImage(_prize)),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 110),
                      left: corner(_player).dx + inset,
                      top: corner(_player).dy + inset,
                      width: sprite,
                      height: sprite,
                      child: Mascot(_done ? 'happy' : 'hello'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MazePainter extends CustomPainter {
  _MazePainter(this.open, this.cols, this.rows, this.trail, this.color);
  final List<int> open;
  final int cols;
  final int rows;
  final List<int> trail;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / cols;
    final board = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(cell * 0.2),
    );
    canvas.drawRRect(
      board,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    Offset center(int index) =>
        Offset((index % cols + 0.5) * cell, (index ~/ cols + 0.5) * cell);
    if (trail.length > 1) {
      final path = Path()
        ..moveTo(center(trail.first).dx, center(trail.first).dy);
      for (final index in trail.skip(1)) {
        path.lineTo(center(index).dx, center(index).dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color.withValues(alpha: 0.35),
      );
    }

    final wall = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(4, cell * 0.09)
      ..strokeCap = StrokeCap.round
      ..color = AppColors.ink;
    for (var i = 0; i < open.length; i++) {
      final x = (i % cols) * cell;
      final y = (i ~/ cols) * cell;
      if (open[i] & _right == 0 && i % cols < cols - 1) {
        canvas.drawLine(Offset(x + cell, y), Offset(x + cell, y + cell), wall);
      }
      if (open[i] & _down == 0 && i ~/ cols < rows - 1) {
        canvas.drawLine(Offset(x, y + cell), Offset(x + cell, y + cell), wall);
      }
    }
    canvas.drawRRect(board, wall);
  }

  @override
  bool shouldRepaint(_MazePainter old) =>
      old.trail.length != trail.length ||
      (trail.isNotEmpty && old.trail.last != trail.last);
}
