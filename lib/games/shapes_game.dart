import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';

enum ShapeKind { circle, square, triangle, star, heart, diamond }

enum _Mode { color, shape, both }

_Mode _modeFor(int level) => level <= 3
    ? _Mode.color
    : level <= 6
    ? _Mode.shape
    : _Mode.both;

/// Renk ve şekil eşleştirme: parçayı sürükleyip uygun boşluğa bırak.
class ShapesGame extends StatelessWidget {
  const ShapesGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  @override
  Widget build(BuildContext context) {
    final key = switch (_modeFor(level)) {
      _Mode.color => 'i_shapes_color',
      _Mode.shape => 'i_shapes_shape',
      _Mode.both => 'i_shapes_both',
    };
    return GameShell(
      game: game,
      level: level,
      rounds: 4,
      instruction: (_) => L.t(key),
      roundBuilder: (round, onSolved, onMistake) =>
          _ShapesRound(level: level, onSolved: onSolved, onMistake: onMistake),
    );
  }
}

class _ShapesRound extends StatefulWidget {
  const _ShapesRound({
    required this.level,
    required this.onSolved,
    required this.onMistake,
  });
  final int level;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_ShapesRound> createState() => _ShapesRoundState();
}

class _ShapesRoundState extends State<_ShapesRound> {
  static const _palette = [
    AppColors.red,
    AppColors.blue,
    AppColors.yellow,
    AppColors.green,
    AppColors.purple,
    AppColors.orange,
  ];

  late final _Mode _mode = _modeFor(widget.level);
  late final List<(ShapeKind, Color)> _items;
  late final List<int> _targetOrder;
  late final List<int> _pieceOrder;
  final Set<int> _placed = {};

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final level = widget.level;
    final count = level <= 1
        ? 2
        : level <= 6
        ? 3
        : 4;
    final kinds = [...ShapeKind.values]..shuffle(rng);
    final colors = [..._palette]..shuffle(rng);
    _items = switch (_mode) {
      _Mode.color => [for (var i = 0; i < count; i++) (kinds.first, colors[i])],
      _Mode.shape => [for (var i = 0; i < count; i++) (kinds[i], colors.first)],
      // İki şekil x iki renk: hem şekle hem renge bakmak gerekir.
      _Mode.both => [
        for (var k = 0; k < 2; k++)
          for (var c = 0; c < 2; c++) (kinds[k], colors[c]),
      ],
    };
    _targetOrder = List.generate(_items.length, (i) => i)..shuffle(rng);
    _pieceOrder = List.generate(_items.length, (i) => i)..shuffle(rng);
  }

  void _drop(int target, int piece) {
    if (target != piece) {
      widget.onMistake();
      return;
    }
    setState(() => _placed.add(target));
    if (_placed.length == _items.length) {
      widget.onSolved();
    } else {
      Sfx.play('pop');
    }
  }

  Widget _shape(int i, double size, {bool ghost = false}) {
    final (kind, color) = _items[i];
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ShapePainter(
          kind,
          ghost && _mode == _Mode.shape ? AppColors.grey : color,
          ghost: ghost,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = min(
          box.maxHeight * 0.4,
          box.maxWidth / (_items.length + 1.2),
        );
        final pieceSize = size * 0.85;
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final i in _targetOrder)
                  DragTarget<int>(
                    onWillAcceptWithDetails: (_) => !_placed.contains(i),
                    onAcceptWithDetails: (details) => _drop(i, details.data),
                    builder: (context, candidates, _) => AnimatedScale(
                      scale: candidates.isNotEmpty ? 1.12 : 1,
                      duration: const Duration(milliseconds: 120),
                      child: _shape(i, size, ghost: !_placed.contains(i)),
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final i in _pieceOrder)
                  if (_placed.contains(i))
                    SizedBox(width: pieceSize, height: pieceSize)
                  else
                    Draggable<int>(
                      data: i,
                      feedback: _shape(i, size),
                      childWhenDragging: Opacity(
                        opacity: 0.25,
                        child: _shape(i, pieceSize),
                      ),
                      child: _shape(i, pieceSize),
                    ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class ShapePainter extends CustomPainter {
  ShapePainter(this.kind, this.color, {this.ghost = false});
  final ShapeKind kind;
  final Color color;

  /// Boş hedef yuvası: soluk dolgu ve kalın kenar çizgisi.
  final bool ghost;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    final fill = Paint()..color = ghost ? color.withValues(alpha: 0.2) : color;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeJoin = StrokeJoin.round
      ..color = ghost ? color : AppColors.ink.withValues(alpha: 0.35);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  Path _path(Size size) {
    final w = size.width;
    final h = size.height;
    switch (kind) {
      case ShapeKind.circle:
        return Path()
          ..addOval(Rect.fromLTWH(w * 0.06, h * 0.06, w * 0.88, h * 0.88));
      case ShapeKind.square:
        return Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.8),
            Radius.circular(w * 0.1),
          ),
        );
      case ShapeKind.triangle:
        return Path()
          ..moveTo(w * 0.5, h * 0.1)
          ..lineTo(w * 0.94, h * 0.88)
          ..lineTo(w * 0.06, h * 0.88)
          ..close();
      case ShapeKind.diamond:
        return Path()
          ..moveTo(w * 0.5, h * 0.05)
          ..lineTo(w * 0.88, h * 0.5)
          ..lineTo(w * 0.5, h * 0.95)
          ..lineTo(w * 0.12, h * 0.5)
          ..close();
      case ShapeKind.star:
        final path = Path();
        final center = Offset(w * 0.5, h * 0.53);
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? w * 0.47 : w * 0.21;
          final a = -pi / 2 + i * pi / 5;
          final p = center + Offset(cos(a), sin(a)) * r;
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        return path..close();
      case ShapeKind.heart:
        return Path()
          ..moveTo(w * 0.5, h * 0.92)
          ..cubicTo(w * -0.12, h * 0.52, w * 0.12, h * 0.02, w * 0.5, h * 0.3)
          ..cubicTo(w * 0.88, h * 0.02, w * 1.12, h * 0.52, w * 0.5, h * 0.92)
          ..close();
    }
  }

  @override
  bool shouldRepaint(ShapePainter old) =>
      old.kind != kind || old.color != color || old.ghost != ghost;
}
