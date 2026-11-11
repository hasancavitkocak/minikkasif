import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/game_shell.dart';
import 'coloring_game.dart';
import 'game_def.dart';

/// Noktaları birleştir: numaralı noktalara sırayla dokun (ya da parmağını
/// sürükle); çizgi tamamlanınca resim ortaya çıkar.
class DotsGame extends StatelessWidget {
  const DotsGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  @override
  Widget build(BuildContext context) {
    return GameShell(
      game: game,
      level: level,
      rounds: 1,
      tolerance: 2,
      instruction: (_) => L.t('i_dots'),
      roundBuilder: (round, onSolved, onMistake) => _DotsLoader(
        name: coloringNames[(level - 1) % coloringNames.length],
        // İlk bölümde 5, son bölümde 14 nokta.
        count: 4 + level,
        onSolved: onSolved,
        onMistake: onMistake,
      ),
    );
  }
}

class _DotsLoader extends StatefulWidget {
  const _DotsLoader({
    required this.name,
    required this.count,
    required this.onSolved,
    required this.onMistake,
  });
  final String name;
  final int count;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader> {
  late final Future<RasterPicture?> _picture = RasterPicture.load(widget.name);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RasterPicture?>(
      future: _picture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.expand();
        }
        final picture = snap.data;
        // Resmin noktaları yoksa düzgün bir yıldız çizdirilir.
        final dots =
            picture?.dotsFor(widget.count) ??
            [
              for (var i = 0; i < widget.count; i++)
                Offset(
                  0.5 + sin(i * 2 * pi / widget.count) * 0.4,
                  0.5 - cos(i * 2 * pi / widget.count) * 0.4,
                ),
            ];
        return _DotsRound(
          picture: picture?.dotsFor(widget.count) == null ? null : picture,
          dots: dots,
          onSolved: widget.onSolved,
          onMistake: widget.onMistake,
        );
      },
    );
  }
}

class _DotsRound extends StatefulWidget {
  const _DotsRound({
    required this.picture,
    required this.dots,
    required this.onSolved,
    required this.onMistake,
  });
  final RasterPicture? picture;

  /// Noktalar, resmin içinde 0..1 aralığında ve sırayla.
  final List<Offset> dots;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_DotsRound> createState() => _DotsRoundState();
}

class _DotsRoundState extends State<_DotsRound>
    with SingleTickerProviderStateMixin {
  /// Sıradaki noktanın sırası; hepsi bitince nokta sayısına eşit olur.
  int _next = 0;
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  bool get _done => _next >= widget.dots.length;

  /// [strict] dokunuşta yanlış noktaya basmak hata sayılır; sürüklerken
  /// başka noktaların üstünden geçmek sayılmaz.
  void _touch(Offset unit, double radius, {required bool strict}) {
    if (_done) return;
    if ((widget.dots[_next] - unit).distance <= radius) {
      setState(() => _next++);
      if (_done) {
        _reveal.forward();
        widget.onSolved();
      } else {
        Sfx.play('pop');
      }
      return;
    }
    if (!strict) return;
    for (var i = _next + 1; i < widget.dots.length; i++) {
      if ((widget.dots[i] - unit).distance <= radius * 0.8) {
        widget.onMistake();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final side = min(box.maxHeight, box.maxWidth);
        final inner = side * 0.86;
        final pad = (side - inner) / 2;
        // Parmağın rahat tutturacağı yarıçap.
        final radius = max(0.07, 26 / inner);
        Offset unit(Offset local) => (local - Offset(pad, pad)) / inner;
        return Center(
          child: GestureDetector(
            onTapDown: (d) =>
                _touch(unit(d.localPosition), radius, strict: true),
            onPanUpdate: (d) =>
                _touch(unit(d.localPosition), radius * 0.7, strict: false),
            child: Container(
              width: side,
              height: side,
              padding: EdgeInsets.all(pad),
              decoration: panelDecoration(radius: side * 0.08),
              child: AnimatedBuilder(
                animation: _reveal,
                builder: (context, _) => CustomPaint(
                  painter: _DotsPainter(
                    widget.dots,
                    _next,
                    Curves.easeOut.transform(_reveal.value),
                    widget.picture,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.dots, this.next, this.reveal, this.picture);
  final List<Offset> dots;
  final int next;

  /// 0: yalnızca çizgiler, 1: resim tamamen görünür.
  final double reveal;
  final RasterPicture? picture;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final done = next >= dots.length;
    final points = [for (final d in dots) d * s];

    if (done && reveal > 0) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: reveal),
      );
      if (picture != null) {
        picture!.paint(canvas, size, [
          for (final c in picture!.colors)
            coloringPalette[c % coloringPalette.length],
        ]);
      } else {
        canvas.drawPath(
          Path()..addPolygon(points, true),
          Paint()..color = AppColors.yellow,
        );
      }
      canvas.restore();
    }

    // Birleştirilen noktalar arasındaki çizgi; resim belirdikçe solar.
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.016
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.ink.withValues(
        alpha: picture == null ? 1 : 1 - reveal,
      );
    if (next > 1) {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (var i = 1; i < min(next, points.length); i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      if (done) path.close();
      canvas.drawPath(path, line);
    }
    if (done) return;

    final r = s * 0.058;
    for (var i = points.length - 1; i >= 0; i--) {
      final visited = i < next;
      final current = i == next;
      final radius = visited
          ? r * 0.45
          : current
          ? r * 1.25
          : r;
      if (current) {
        canvas.drawCircle(
          points[i],
          radius * 1.45,
          Paint()..color = AppColors.yellow.withValues(alpha: 0.55),
        );
      }
      canvas.drawCircle(
        points[i],
        radius,
        Paint()
          ..color = visited
              ? AppColors.green
              : current
              ? AppColors.orange
              : Colors.white,
      );
      canvas.drawCircle(
        points[i],
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.008
          ..color = AppColors.ink,
      );
      if (visited) continue;
      final text = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            fontFamily: 'Kasif',
            fontSize: radius * 1.15,
            height: 1,
            fontWeight: FontWeight.w800,
            color: current ? Colors.white : AppColors.ink,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, points[i] - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.next != next || old.reveal != reveal || old.dots != dots;
}
