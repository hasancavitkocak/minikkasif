import 'package:flutter/material.dart';

import '../games/game_def.dart';
import '../theme.dart';
import 'common.dart';

/// Bir oyunun madalyası: oyunun ikonu altın bir halkanın içinde, altında
/// küçük bir yıldız. Kazanılmadıysa gri ve soluk görünür.
class MedalBadge extends StatelessWidget {
  const MedalBadge(this.game, {super.key, this.earned = true, this.size = 96});
  final GameDef game;
  final bool earned;
  final double size;

  static const _gold = [
    Color(0xFFFFE082),
    Color(0xFFFFB300),
    Color(0xFFFFF3C4),
    Color(0xFFF59E0B),
    Color(0xFFFFE082),
  ];
  static const _grey = [
    Color(0xFFE0E0E0),
    Color(0xFFBDBDBD),
    Color(0xFFEEEEEE),
    Color(0xFFBDBDBD),
    Color(0xFFE0E0E0),
  ];

  @override
  Widget build(BuildContext context) {
    final ring = size * 0.09;
    Widget icon = GameImage(
      'assets/images/icons/game_${game.id}.png',
      fallback: Emoji(game.emoji),
    );
    if (!earned) {
      icon = Opacity(
        opacity: 0.35,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.33, 0.33, 0.33, 0, 0, //
            0.33, 0.33, 0.33, 0, 0, //
            0.33, 0.33, 0.33, 0, 0, //
            0, 0, 0, 1, 0, //
          ]),
          child: icon,
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(ring),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: earned ? _gold : _grey),
              boxShadow: [
                BoxShadow(
                  color: (earned ? const Color(0xFFF59E0B) : AppColors.ink)
                      .withValues(alpha: earned ? 0.45 : 0.12),
                  blurRadius: earned ? 10 : 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Container(
              padding: EdgeInsets.all(size * 0.1),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: icon,
            ),
          ),
          // Altta küçük yıldız: madalyayı çıkartmadan ayırır.
          Positioned(
            left: size * 0.36,
            right: size * 0.36,
            bottom: -size * 0.06,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: earned ? AppColors.yellow : const Color(0xFFD6D6D6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: size * 0.025),
                ),
                child: FittedBox(
                  child: Icon(
                    Icons.star_rounded,
                    color: earned ? const Color(0xFFE65100) : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
