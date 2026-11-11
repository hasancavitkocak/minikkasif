import 'dart:math';

import 'package:flutter/material.dart';

import '../data/objects.dart';
import '../data/outfits.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';

/// Bir asset görselini gösterir; dosya henüz eklenmemişse [fallback] çizilir.
/// Böylece görseller hazır olmadan da oyun oynanabilir.
class GameImage extends StatelessWidget {
  const GameImage(
    this.path, {
    super.key,
    required this.fallback,
    this.fit = BoxFit.contain,
  });

  final String path;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(path, fit: fit, errorBuilder: (_, _, _) => fallback);
  }
}

/// Bulunduğu alanı dolduran emoji (geçici görsel).
class Emoji extends StatelessWidget {
  const Emoji(this.emoji, {super.key});
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Text(emoji, style: const TextStyle(fontSize: 64, height: 1.15)),
    );
  }
}

class ObjectImage extends StatelessWidget {
  const ObjectImage(this.object, {super.key});
  final GameObject object;

  @override
  Widget build(BuildContext context) {
    return GameImage(
      'assets/images/${object.folder}/${object.id}.png',
      fallback: Emoji(object.emoji),
    );
  }
}

/// Nesnenin koyu gölgesi (silüet).
class ObjectShadow extends StatelessWidget {
  const ObjectShadow(this.object, {super.key});
  final GameObject object;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0xFF3D3D52), BlendMode.srcIn),
      child: ObjectImage(object),
    );
  }
}

/// Maskot tilki. [pose]: hello, happy, thinking, oops.
class Mascot extends StatelessWidget {
  const Mascot(this.pose, {super.key});
  final String pose;

  @override
  Widget build(BuildContext context) {
    final image = GameImage(
      'assets/images/mascot/fox_$pose.png',
      fallback: const Emoji('🦊'),
    );
    // Dolaptan seçilen aksesuar "merhaba" duruşunda takılır.
    final outfit = pose == 'hello' ? currentOutfit : null;
    if (outfit == null) return image;
    return Stack(
      fit: StackFit.expand,
      children: [image, _OutfitOverlay(outfit)],
    );
  }
}

/// Belirli bir aksesuarı takmış Fıstık (dolaptaki deneme için).
class DressedFox extends StatelessWidget {
  const DressedFox(this.outfit, {super.key});
  final Outfit outfit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const GameImage(
          'assets/images/mascot/fox_hello.png',
          fallback: Emoji('🦊'),
        ),
        _OutfitOverlay(outfit),
      ],
    );
  }
}

/// Aksesuarı maskot resminin üstünde doğru yere koyar.
class _OutfitOverlay extends StatelessWidget {
  const _OutfitOverlay(this.outfit);
  final Outfit outfit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // Maskot resmi kutunun ortasına kare olarak sığar.
        final side = min(box.maxWidth, box.maxHeight);
        final left = (box.maxWidth - side) / 2;
        final top = (box.maxHeight - side) / 2;
        final size = side * outfit.size;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: left + side * outfit.center.dx - size / 2,
              top: top + side * outfit.center.dy - size / 2,
              width: size,
              height: size,
              // Baş eğik durduğu için aksesuar da aynı açıyla eğilir.
              child: Transform.rotate(
                angle: headTilt,
                child: OutfitImage(outfit),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Ekran açılınca maskotun balonundaki cümleyi bir kez seslendirir.
class SpeakOnce extends StatefulWidget {
  const SpeakOnce(this.textKey, {super.key, required this.child});

  /// Çeviri anahtarı (l10n.dart).
  final String textKey;
  final Widget child;

  @override
  State<SpeakOnce> createState() => _SpeakOnceState();
}

class _SpeakOnceState extends State<SpeakOnce> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Tts.speak(L.t(widget.textKey));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// El sallayan maskot: `fox_hello.png` ile eli öbür yanda duran
/// `fox_wave.png` sırayla gösterilir; gövde yerinden oynamaz.
class WavingMascot extends StatefulWidget {
  const WavingMascot({super.key});

  @override
  State<WavingMascot> createState() => _WavingMascotState();
}

class _WavingMascotState extends State<WavingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final second = (_controller.value * 4).floor().isOdd;
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: second ? 0 : 1,
              child: const GameImage(
                'assets/images/mascot/fox_hello.png',
                fallback: Emoji('🦊'),
              ),
            ),
            Opacity(
              opacity: second ? 1 : 0,
              child: const GameImage(
                'assets/images/mascot/fox_wave.png',
                fallback: SizedBox.shrink(),
              ),
            ),
            // Aksesuar iki karede de yerinde durur.
            if (currentOutfit != null) _OutfitOverlay(currentOutfit!),
          ],
        );
      },
    );
  }
}

/// Dokununca hafifçe küçülen, "pop" sesi çıkaran dokunma alanı.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.sound = true,
  });
  final Widget child;
  final VoidCallback? onTap;
  final bool sound;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.sound) Sfx.play('pop');
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}

/// Büyük yuvarlak buton. `assets/images/ui/<asset>.png` varsa onu kullanır.
class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.asset,
    this.size = 60,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final drawn = Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size * 0.07),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: asset == null
            ? drawn
            : GameImage('assets/images/ui/$asset.png', fallback: drawn),
      ),
    );
  }
}

/// Seçenek kartı. [onTap] doğru seçimde true döndürür; yanlışta kart
/// "hayır" der gibi sağa sola sallanır.
class ChoiceTile extends StatefulWidget {
  const ChoiceTile({
    super.key,
    required this.child,
    required this.onTap,
    this.size,
    this.color = Colors.white,
    this.padding = 0.12,
  });

  final Widget child;
  final bool Function() onTap;
  final double? size;
  final Color color;

  /// Kart boyutuna oranla iç boşluk.
  final double padding;

  @override
  State<ChoiceTile> createState() => _ChoiceTileState();
}

class _ChoiceTileState extends State<ChoiceTile> with TickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  /// Doğru seçimde kartın sevinçle zıplaması.
  late final AnimationController _jump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _shake.dispose();
    _jump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return AnimatedBuilder(
      animation: Listenable.merge([_shake, _jump]),
      builder: (context, child) {
        final hop = sin(_jump.value * pi);
        return Transform.translate(
          offset: Offset(
            sin(_shake.value * pi * 5) * 9 * (1 - _shake.value),
            -hop * (size ?? 80) * 0.14,
          ),
          child: Transform.scale(scale: 1 + hop * 0.1, child: child),
        );
      },
      child: Pressable(
        sound: false,
        onTap: () {
          if (widget.onTap()) {
            _jump.forward(from: 0);
          } else {
            _shake.forward(from: 0);
          }
        },
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all((size ?? 80) * widget.padding),
          decoration: panelDecoration(
            color: widget.color,
            radius: (size ?? 80) * 0.22,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 3 üzerinden kazanılan yıldızlar.
class StarsRow extends StatelessWidget {
  const StarsRow(this.stars, {super.key, this.size = 28});
  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          SizedBox(
            width: size,
            height: size,
            child: GameImage(
              'assets/images/ui/${i < stars ? 'star_full' : 'star_empty'}.png',
              fallback: FittedBox(
                child: Icon(
                  Icons.star_rounded,
                  color: i < stars
                      ? AppColors.yellow
                      : AppColors.grey.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Doğru cevapta ekrana yağan konfeti.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();
  final int _seed = Random().nextInt(1 << 20);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_controller.value, _seed),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.seed);
  final double t;
  final int seed;

  static const _colors = [
    AppColors.red,
    AppColors.yellow,
    AppColors.green,
    AppColors.blue,
    AppColors.pink,
    AppColors.purple,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final paint = Paint();
    for (var i = 0; i < 70; i++) {
      final x0 = rng.nextDouble() * size.width;
      final drift = (rng.nextDouble() - 0.5) * 120;
      final speed = 0.6 + rng.nextDouble() * 0.8;
      final spin = rng.nextDouble() * 10;
      final w = 8 + rng.nextDouble() * 8;
      final color = _colors[rng.nextInt(_colors.length)];
      final y = -30 + t * speed * (size.height + 60);
      paint.color = color.withValues(alpha: (1 - t * t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x0 + drift * t, y);
      canvas.rotate(spin * t + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Oyun ve menü arka planı. `assets/images/bg/bg_<name>.png` yoksa yumuşak bir
/// renk geçişi çizilir.
class Backdrop extends StatelessWidget {
  const Backdrop(this.name, {super.key});
  final String name;

  static const _gradients = {
    'home': [Color(0xFF9EDBFF), Color(0xFFD8F5C8)],
    'meadow': [Color(0xFFCDEBFF), Color(0xFFE4F7D2)],
    'sea': [Color(0xFFB8EEF0), Color(0xFFD3E9FF)],
    'space': [Color(0xFFD9CCFF), Color(0xFFF3D9F5)],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[name] ?? _gradients['meadow']!;
    return SizedBox.expand(
      child: GameImage(
        'assets/images/bg/bg_$name.png',
        fit: BoxFit.cover,
        fallback: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
          ),
        ),
      ),
    );
  }
}
