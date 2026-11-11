import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/common.dart';

/// Fıstık'ın takabileceği bir aksesuar. Yıldız toplandıkça açılır. Görseli
/// `assets/images/outfits/<id>.png` dosyasından gelir; yoksa emoji çizilir.
class Outfit {
  const Outfit(
    this.id,
    this.emoji,
    this.stars,
    this.center,
    this.size, [
    this.color,
  ]);
  final String id;
  final String emoji;

  /// Açılması için gereken toplam yıldız.
  final int stars;

  /// Maskot resminin (fox_hello) içinde aksesuarın merkezi, 0..1.
  final Offset center;

  /// Maskot genişliğine oranla boyutu.
  final double size;

  /// Aksesuarın kendi rengi ([outfitColors] anahtarı). Null ise rengi
  /// değiştirilemez (taç, kaşif şapkası, çok renkli parti şapkası).
  final String? color;

  /// Seçili profilin bu aksesuar için seçtiği renk.
  String? get chosenColor {
    if (color == null) return null;
    final c = AppState.I.profileData('oc_$id');
    return outfitColors.containsKey(c) ? c : color;
  }

  /// Görsel dosyası; renk seçenekleri tool/outfit_colors.py ile üretilir.
  String get asset {
    final c = chosenColor;
    final suffix = c == null || c == color ? '' : '_$c';
    return 'assets/images/outfits/$id$suffix.png';
  }
}

/// Aksesuarların boyanabildiği renkler (tool/outfit_colors.py ile aynı).
const outfitColors = <String, Color>{
  'red': Color(0xFFF2242B),
  'orange': Color(0xFFFF9226),
  'green': Color(0xFF3DCC61),
  'blue': Color(0xFF348DEB),
  'purple': Color(0xFF9B52D9),
  'pink': Color(0xFFFF80BB),
};

/// Fıstık'ın başı resimde sağa doğru eğik durur (gözlerinden ölçüldü);
/// aksesuarlar da aynı açıyla eğilir, yoksa başa oturmaz.
const headTilt = 0.21;

// Yerler fox_hello.png üzerinde ölçülerek belirlendi: gözlerin ortası
// (0.506, 0.37), iki göz arası 0.20, başın tepesi yaklaşık (0.55, 0.16).
const outfits = <Outfit>[
  Outfit('acc_cap', '', 5, Offset(0.57, 0.115), 0.44, 'blue'),
  Outfit('acc_flower', '', 12, Offset(0.735, 0.2), 0.17, 'pink'),
  Outfit('acc_glasses', '', 25, Offset(0.506, 0.366), 0.43, 'red'),
  Outfit('acc_party', '', 40, Offset(0.578, 0.065), 0.38),
  Outfit('acc_bow', '', 60, Offset(0.39, 0.115), 0.22, 'red'),
  Outfit('acc_explorer', '', 85, Offset(0.565, 0.13), 0.5),
  Outfit('acc_tophat', '', 115, Offset(0.58, 0.075), 0.4, 'purple'),
  Outfit('acc_crown', '', 150, Offset(0.57, 0.1), 0.34),
];

/// Seçili profilin taktığı aksesuar; yoksa null.
Outfit? get currentOutfit {
  final id = AppState.I.profileData('outfit');
  for (final o in outfits) {
    if (o.id == id) return o;
  }
  return null;
}

class OutfitImage extends StatelessWidget {
  const OutfitImage(this.outfit, {super.key});
  final Outfit outfit;

  @override
  Widget build(BuildContext context) {
    // Görseli gelene kadar aksesuar kodla çizilir. Emoji kullanılmaz: emojinin
    // biçimi ve boşluğu cihaza göre değiştiği için başa oturtulamıyor.
    return GameImage(
      outfit.asset,
      fallback: CustomPaint(painter: _OutfitPainter(outfit.id)),
    );
  }
}

/// Aksesuarların çizimi. Şapkaların tabanı karenin alt ortasındadır; başın
/// tepesine oradan oturur.
class _OutfitPainter extends CustomPainter {
  const _OutfitPainter(this.id);
  final String id;

  static const _ink = Color(0xFF4A3728);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.scale(s);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.035
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = _ink;
    void shape(Path path, Color color) {
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(path, line);
    }

    Path oval(double cx, double cy, double w, double h) => Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: w, height: h));
    Path rrect(double l, double t, double w, double h, double r) => Path()
      ..addRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), Radius.circular(r)),
      );
    Path poly(List<double> xy) {
      final path = Path()..moveTo(xy[0], xy[1]);
      for (var i = 2; i < xy.length; i += 2) {
        path.lineTo(xy[i], xy[i + 1]);
      }
      return path..close();
    }

    switch (id) {
      case 'acc_glasses':
        // İki mercek göz aralığına göre: merkezleri 0.26 ve 0.74.
        canvas.drawLine(
          const Offset(0.42, 0.47),
          const Offset(0.58, 0.47),
          line,
        );
        for (final cx in [0.26, 0.74]) {
          shape(
            rrect(cx - 0.2, 0.33, 0.4, 0.34, 0.13),
            const Color(0xFFFF5B5B),
          );
          canvas.drawPath(
            rrect(cx - 0.15, 0.38, 0.3, 0.24, 0.09),
            Paint()..color = const Color(0xFF2B3A67),
          );
          canvas.drawPath(
            rrect(cx - 0.11, 0.41, 0.1, 0.05, 0.03),
            Paint()..color = Colors.white.withValues(alpha: 0.7),
          );
        }
      case 'acc_cap':
        shape(
          Path()
            ..moveTo(0.14, 0.86)
            ..cubicTo(0.12, 0.3, 0.88, 0.3, 0.86, 0.86)
            ..close(),
          const Color(0xFF4DA6FF),
        );
        shape(
          Path()
            ..moveTo(0.1, 0.86)
            ..cubicTo(-0.12, 0.84, -0.14, 0.7, 0.2, 0.72)
            ..lineTo(0.5, 0.86)
            ..close(),
          const Color(0xFF2F7FD6),
        );
        shape(oval(0.5, 0.42, 0.1, 0.08), const Color(0xFFFFD34E));
      case 'acc_party':
        shape(
          poly([0.5, 0.05, 0.82, 0.88, 0.18, 0.88]),
          const Color(0xFFFF7EB6),
        );
        for (final (i, y) in [0.42, 0.62].indexed) {
          final half = (y - 0.05) / 0.83 * 0.32;
          canvas.drawLine(
            Offset(0.5 - half, y),
            Offset(0.5 + half, y),
            Paint()
              ..strokeWidth = 0.07
              ..color = i == 0
                  ? const Color(0xFFFFD34E)
                  : const Color(0xFF4DA6FF),
          );
        }
        canvas.drawPath(poly([0.5, 0.05, 0.82, 0.88, 0.18, 0.88]), line);
        shape(oval(0.5, 0.07, 0.17, 0.17), const Color(0xFFFFD34E));
      case 'acc_tophat':
        shape(rrect(0.24, 0.12, 0.52, 0.66, 0.06), const Color(0xFF7E57C2));
        canvas.drawRect(
          const Rect.fromLTWH(0.24, 0.56, 0.52, 0.12),
          Paint()..color = const Color(0xFFFFD34E),
        );
        canvas.drawPath(rrect(0.24, 0.12, 0.52, 0.66, 0.06), line);
        shape(rrect(0.06, 0.74, 0.88, 0.14, 0.07), const Color(0xFF6A45B0));
      case 'acc_crown':
        shape(
          poly([
            0.12,
            0.86,
            0.08,
            0.36,
            0.3,
            0.58,
            0.5,
            0.24,
            0.7,
            0.58,
            0.92,
            0.36,
            0.88,
            0.86,
          ]),
          const Color(0xFFFFC928),
        );
        for (final cx in [0.3, 0.5, 0.7]) {
          shape(oval(cx, 0.73, 0.1, 0.1), const Color(0xFFFF5B5B));
        }
      case 'acc_explorer':
        shape(rrect(0.0, 0.7, 1.0, 0.17, 0.085), const Color(0xFFD9B77A));
        shape(
          Path()
            ..moveTo(0.22, 0.76)
            ..cubicTo(0.2, 0.2, 0.8, 0.2, 0.78, 0.76)
            ..close(),
          const Color(0xFFEAD3A2),
        );
        canvas.drawLine(
          const Offset(0.24, 0.66),
          const Offset(0.76, 0.66),
          Paint()
            ..strokeWidth = 0.08
            ..color = const Color(0xFF4CD080),
        );
      case 'acc_flower':
        for (var i = 0; i < 5; i++) {
          final angle = i * 1.2566 - 1.5708;
          shape(
            oval(0.5 + 0.27 * cos(angle), 0.5 + 0.27 * sin(angle), 0.36, 0.36),
            const Color(0xFFFF8FC4),
          );
        }
        shape(oval(0.5, 0.5, 0.3, 0.3), const Color(0xFFFFD34E));
      case 'acc_bow':
        shape(
          poly([0.5, 0.5, 0.06, 0.22, 0.06, 0.78]),
          const Color(0xFFFF5B5B),
        );
        shape(
          poly([0.5, 0.5, 0.94, 0.22, 0.94, 0.78]),
          const Color(0xFFFF5B5B),
        );
        shape(oval(0.5, 0.5, 0.24, 0.24), const Color(0xFFE23F3F));
    }
  }

  @override
  bool shouldRepaint(_OutfitPainter old) => old.id != id;
}
