import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// Kalın dış çizgili, oyun başlığı tarzı yazı.
class StrokeText extends StatelessWidget {
  const StrokeText(
    this.text, {
    super.key,
    this.size = 32,
    this.color = Colors.white,
    this.stroke = AppColors.ink,
    this.maxLines = 1,
  });

  final String text;
  final double size;
  final Color color;
  final Color stroke;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: 'Kasif',
      fontSize: size,
      height: 1.1,
      fontWeight: FontWeight.w800,
    );
    return Stack(
      children: [
        Text(
          text,
          maxLines: maxLines,
          textAlign: TextAlign.center,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.22
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
          ),
        ),
        Text(
          text,
          maxLines: maxLines,
          textAlign: TextAlign.center,
          style: base.copyWith(color: color),
        ),
      ],
    );
  }
}

enum BubbleTail { left, bottom, none }

/// Maskotun konuşma balonu.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.child,
    this.tail = BubbleTail.left,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final Widget child;
  final BubbleTail tail;
  final EdgeInsets padding;

  static const double tailSize = 16;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return CustomPaint(
      painter: _BubblePainter(tail, rtl),
      child: Padding(
        padding: padding.add(
          EdgeInsetsDirectional.only(
            start: tail == BubbleTail.left ? tailSize : 0,
            bottom: tail == BubbleTail.bottom ? tailSize : 0,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.tail, this.rtl);
  final BubbleTail tail;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    const t = SpeechBubble.tailSize;
    final left = tail == BubbleTail.left && !rtl ? t : 0.0;
    final right = tail == BubbleTail.left && rtl ? t : 0.0;
    final bottom = tail == BubbleTail.bottom ? t : 0.0;
    final body = Rect.fromLTRB(
      left,
      0,
      size.width - right,
      size.height - bottom,
    );
    // Yumuşak, yuvarlak gövde ve maskota doğru kıvrılan damla biçimli kuyruk.
    final radius = Radius.circular(min(28, body.height / 2));
    var path = Path()..addRRect(RRect.fromRectAndRadius(body, radius));
    final tailPath = Path();
    if (tail == BubbleTail.left) {
      final dir = rtl ? -1.0 : 1.0;
      final x = (rtl ? body.right : body.left) + dir * 2;
      final tip = rtl ? size.width : 0.0;
      final cy = body.center.dy;
      tailPath
        ..moveTo(x, cy - t * 0.55)
        ..quadraticBezierTo(x - dir * t * 0.5, cy + t * 0.1, tip, cy + t * 0.75)
        ..quadraticBezierTo(x - dir * t * 0.2, cy + t * 0.85, x, cy + t * 0.6)
        ..close();
    } else if (tail == BubbleTail.bottom) {
      final cx = body.center.dx;
      final y = body.bottom - 2;
      tailPath
        ..moveTo(cx - t * 0.7, y)
        ..quadraticBezierTo(
          cx - t * 0.1,
          y + t * 0.5,
          cx - t * 0.75,
          size.height,
        )
        ..quadraticBezierTo(cx + t * 0.5, y + t * 0.75, cx + t * 0.8, y)
        ..close();
    }
    path = Path.combine(PathOperation.union, path, tailPath);
    // Oyundaki kartlar gibi altta koyu bir kenar: balon kabarık görünür.
    canvas.drawPath(
      path.shift(const Offset(0, 4)),
      Paint()..color = const Color(0xFFE0863A).withValues(alpha: 0.55),
    );
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.orange,
    );
    // Sol üstte küçük bir parlama.
    if (body.height > 30 && body.width > 60) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(body.left + 14, body.top + 6, 18, 5),
          const Radius.circular(3),
        ),
        Paint()..color = AppColors.yellow.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.tail != tail || old.rtl != rtl;
}

/// Sıradaki öğeyi yerinden oynatmadan belli eder: arkasında yavaşça
/// parlayıp sönen sarı bir hale. Zıplayan öğeler dikkat dağıttığı için
/// kartlarda ve bölüm numaralarında bu kullanılır.
class Glow extends StatefulWidget {
  const Glow({super.key, required this.child, this.radius, this.spread = 10});
  final Widget child;

  /// Köşe yuvarlaklığı; verilmezse hale daire olur.
  final double? radius;
  final double spread;

  @override
  State<Glow> createState() => _GlowState();
}

class _GlowState extends State<Glow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

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
        final v = Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: widget.radius == null ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.radius == null
                ? null
                : BorderRadius.circular(widget.radius!),
            boxShadow: [
              BoxShadow(
                color: AppColors.yellow.withValues(alpha: 0.45 + 0.5 * v),
                blurRadius: widget.spread * (1 + v),
                spreadRadius: widget.spread * (0.3 + 0.5 * v),
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Hafifçe yukarı aşağı süzülen (ya da nabız gibi büyüyen) sarmalayıcı.
class Bobbing extends StatefulWidget {
  const Bobbing({
    super.key,
    required this.child,
    this.distance = 6,
    this.pulse = 0,
  });
  final Widget child;

  /// Dikey hareket mesafesi.
  final double distance;

  /// Sıfırdan büyükse büyüme oranı (ör. 0.08).
  final double pulse;

  @override
  State<Bobbing> createState() => _BobbingState();
}

class _BobbingState extends State<Bobbing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

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
        final v = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -widget.distance * v),
          child: Transform.scale(scale: 1 + widget.pulse * v, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Ekrana "pıt" diye büyüyerek giren öğe.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.delay = 0});
  final Widget child;

  /// Giriş sırası; her adım kısa bir gecikme ekler.
  final int delay;

  @override
  Widget build(BuildContext context) {
    final total = 350 + delay * 70;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      builder: (context, t, child) {
        final start = (delay * 70) / total;
        final local = ((t - start) / (1 - start)).clamp(0.0, 1.0);
        return Transform.scale(
          scale: Curves.easeOutBack.transform(local),
          child: Opacity(opacity: min(1, local * 2), child: child),
        );
      },
      child: child,
    );
  }
}

/// Altında koyu kenarı olan, basılabilir "oyuncak" buton.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.green,
    this.icon,
    this.fontSize = 22,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final face = enabled ? color : AppColors.grey;
    final edge = Color.lerp(face, Colors.black, 0.28)!;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: edge,
          borderRadius: BorderRadius.circular(fontSize * 1.3),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: fontSize * 1.2,
            vertical: fontSize * 0.35,
          ),
          decoration: BoxDecoration(
            color: face,
            borderRadius: BorderRadius.circular(fontSize * 1.3),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.65),
              width: 3,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: fontSize * 1.3),
                SizedBox(width: fontSize * 0.3),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Kasif',
                    fontSize: fontSize,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Krem rengi, kalın beyaz kenarlı ana panel (menü ve ayar ekranları).
class ToyPanel extends StatelessWidget {
  const ToyPanel({
    super.key,
    required this.child,
    this.color = AppColors.cream,
    this.border = Colors.white,
    this.padding = const EdgeInsets.all(16),
    this.radius = 30,
  });

  final Widget child;
  final Color color;
  final Color border;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 5),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Ekranın üst köşesindeki geri butonu.
class BackRoundButton extends StatelessWidget {
  const BackRoundButton({super.key, this.size = 54});
  final double size;

  @override
  Widget build(BuildContext context) {
    return RoundButton(
      icon: Icons.arrow_back_rounded,
      color: AppColors.orange,
      asset: 'btn_back',
      size: size,
      onTap: () => Navigator.of(context).maybePop(),
    );
  }
}
