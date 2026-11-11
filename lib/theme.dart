import 'package:flutter/material.dart';

/// Oyunun çocuklara özel renk paleti.
class AppColors {
  static const sky = Color(0xFF8FD3FF);
  static const cream = Color(0xFFFFF7E6);
  static const orange = Color(0xFFFF9F43);
  static const green = Color(0xFF4CD080);
  static const pink = Color(0xFFFF7EB6);
  static const purple = Color(0xFF9B7BFF);
  static const yellow = Color(0xFFFFD34E);
  static const teal = Color(0xFF2EC4B6);
  static const red = Color(0xFFFF6B6B);
  static const blue = Color(0xFF4DA6FF);
  static const ink = Color(0xFF4A3728);
  static const grey = Color(0xFFB8BCC8);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Kasif',
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.orange),
    scaffoldBackgroundColor: AppColors.cream,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}

/// Beyaz, yuvarlak köşeli, hafif gölgeli panel.
BoxDecoration panelDecoration({
  Color color = Colors.white,
  double radius = 24,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: AppColors.ink.withValues(alpha: 0.18),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

const titleStyle = TextStyle(
  fontFamily: 'Kasif',
  fontSize: 22,
  height: 1.15,
  fontWeight: FontWeight.w800,
  color: AppColors.ink,
);
