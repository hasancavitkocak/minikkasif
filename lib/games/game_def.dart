import 'package:flutter/material.dart';

/// Bir dünyadaki bölüm sayısı.
const worldSize = 10;

/// Bölümün dünyası: 0 çiftlik, 1 deniz, 2 uzay.
int worldOf(int level) => (level - 1) ~/ worldSize;

/// Bölümün kendi dünyasındaki sırası (1-10); zorluk buna göre artar.
int stageOf(int level) => (level - 1) % worldSize + 1;

/// Bir mini oyunun tanımı.
class GameDef {
  const GameDef({
    required this.id,
    required this.emoji,
    required this.color,
    required this.builder,
    this.free = false,
    this.levels = 10,
  });

  /// Çeviri anahtarı (`g_<id>`) ve ikon dosyası (`game_<id>.png`) bundan türetilir.
  final String id;

  /// İkon görseli eklenene kadar kart üzerinde görünen geçici simge.
  final String emoji;
  final Color color;

  /// Abonelik olmadan oynanabilir mi?
  final bool free;
  final int levels;
  final Widget Function(GameDef game, int level) builder;
}
