import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/audio.dart';
import '../theme.dart';
import 'common.dart';

// Bu dosyadaki hareketlerin hepsi tek seferliktir: çocuğun yaptığı bir şeye
// karşılık bir kez oynar ve durur. Sürekli zıplayan, sallanan öğe yoktur.

/// Bir noktadan dışa doğru saçılan yıldız parıltıları. [t] 0..1 arası
/// ilerlemedir; 0 ve 1'de hiçbir şey çizilmez.
class SparklePainter extends CustomPainter {
  SparklePainter(this.t);
  final double t;

  static const _colors = [AppColors.yellow, Colors.white, AppColors.orange];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final reach = size.shortestSide * 0.95;
    final ease = Curves.easeOutCubic.transform(t);
    final paint = Paint();
    const count = 10;
    for (var i = 0; i < count; i++) {
      final angle = i * 2 * pi / count + 0.3;
      final distance = reach * (0.35 + 0.45 * ease) * (i.isEven ? 1 : 0.8);
      final radius = size.shortestSide * (i.isEven ? 0.07 : 0.05) * (1 - t);
      paint.color = _colors[i % _colors.length].withValues(
        alpha: (1 - t).clamp(0.0, 1.0),
      );
      _star(
        canvas,
        center + Offset(cos(angle), sin(angle)) * distance,
        radius,
        paint,
      );
    }
  }

  static void _star(Canvas canvas, Offset c, double r, Paint paint) {
    if (r <= 0) return;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -pi / 2 + i * pi / 5;
      final len = i.isEven ? r : r * 0.45;
      final p = c + Offset(cos(a), sin(a)) * len;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(SparklePainter old) => old.t != t;
}

/// Oyun ekranındaki Fıstık: doğru cevapta bir kez sevinçle zıplar, yanlışta
/// başını iki yana sallar. Yüz ifadesi [pose] ile değişir.
class ReactingMascot extends StatefulWidget {
  const ReactingMascot(this.pose, {super.key});
  final String pose;

  @override
  State<ReactingMascot> createState() => _ReactingMascotState();
}

class _ReactingMascotState extends State<ReactingMascot>
    with TickerProviderStateMixin {
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void didUpdateWidget(ReactingMascot old) {
    super.didUpdateWidget(old);
    if (old.pose == widget.pose) return;
    if (widget.pose == 'happy') _hop.forward(from: 0);
    if (widget.pose == 'oops') _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _hop.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_hop, _shake]),
      builder: (context, child) {
        final h = sin(_hop.value * pi);
        // Kalkışta hafif basılma, havada uzama.
        final squash = _hop.value < 0.12 ? 1 - _hop.value : 1 + h * 0.08;
        final tilt = sin(_shake.value * pi * 4) * 0.18 * (1 - _shake.value);
        return Transform.translate(
          offset: Offset(0, -h * 22),
          child: Transform.rotate(
            angle: tilt,
            child: Transform.scale(scaleY: squash, child: child),
          ),
        );
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: SizedBox.expand(
          key: ValueKey(widget.pose),
          child: Mascot(widget.pose),
        ),
      ),
    );
  }
}

/// Ekrana gelince [times] kez zıplayıp duran öğe (bölüm sonundaki Fıstık).
class HopOnce extends StatefulWidget {
  const HopOnce({super.key, required this.child, this.times = 2});
  final Widget child;
  final int times;

  @override
  State<HopOnce> createState() => _HopOnceState();
}

class _HopOnceState extends State<HopOnce> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 480 * widget.times),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final local = (_controller.value * widget.times) % 1;
        final h = _controller.value >= 1 ? 0.0 : sin(local * pi);
        return Transform.translate(offset: Offset(0, -h * 20), child: child);
      },
      child: widget.child,
    );
  }
}

/// Bölüm sonunda kazanılan yıldızlar birer birer, dönerek ve "pıt" sesiyle
/// yerine konur; kazanılmayanlar gri kalır.
class StarReveal extends StatefulWidget {
  const StarReveal(this.stars, {super.key, this.size = 56});
  final int stars;
  final double size;

  /// İlk yıldızın gelmeden önceki bekleme ve yıldızlar arası süre.
  static const start = Duration(milliseconds: 350);
  static const step = Duration(milliseconds: 380);

  /// Bütün yıldızların yerine oturduğu an.
  static Duration doneAfter(int stars) =>
      start + step * stars + const Duration(milliseconds: 200);

  @override
  State<StarReveal> createState() => _StarRevealState();
}

class _StarRevealState extends State<StarReveal> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers = [
    for (var i = 0; i < 3; i++)
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 520),
      ),
  ];
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.stars.clamp(0, 3); i++) {
      _timers.add(
        Timer(StarReveal.start + StarReveal.step * i, () {
          if (!mounted) return;
          _controllers[i].forward();
          Sfx.play('pop');
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _image(bool full) => GameImage(
    'assets/images/ui/${full ? 'star_full' : 'star_empty'}.png',
    fallback: FittedBox(
      child: Icon(
        Icons.star_rounded,
        color: full ? AppColors.yellow : AppColors.grey.withValues(alpha: 0.6),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Row(
      key: const ValueKey('star_reveal'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: _image(false)),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _controllers[i],
                    builder: (context, child) {
                      final v = _controllers[i].value;
                      if (v == 0) return const SizedBox.shrink();
                      final scale = Curves.elasticOut.transform(v);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: SparklePainter(v)),
                          ),
                          Positioned.fill(
                            child: Transform.rotate(
                              angle: (1 - v) * -1.2,
                              child: Transform.scale(
                                scale: scale,
                                child: child,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    child: _image(true),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// [delay] sonra yukarıdan, büyük ve dönerek gelip yerine oturan öğe
/// (bölüm sonunda kazanılan çıkartma).
class FlyIn extends StatefulWidget {
  const FlyIn({super.key, required this.child, required this.delay});
  final Widget child;
  final Duration delay;

  @override
  State<FlyIn> createState() => _FlyInState();
}

class _FlyInState extends State<FlyIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (!mounted) return;
      _controller.forward();
      Sfx.play('pop');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final v = _controller.value;
        if (v == 0) return Opacity(opacity: 0, child: child);
        final move = Curves.easeOutBack.transform(v);
        return Transform.translate(
          offset: Offset(0, -140 * (1 - move)),
          child: Transform.rotate(
            angle: (1 - v) * 2 * pi,
            child: Transform.scale(
              scale: 2.2 - 1.2 * move,
              child: Opacity(opacity: min(1, v * 3), child: child),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
