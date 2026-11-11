import 'package:flutter/material.dart';

import '../widgets/common.dart';

/// Albümde toplanan bir çıkartma. Görseli
/// `assets/images/stickers/<id>.png` dosyasından gelir; yoksa emoji çizilir.
class Sticker {
  const Sticker(this.id, this.emoji, this.page);
  final String id;
  final String emoji;

  /// Albüm sayfası: farm, sea, space.
  final String page;
}

const stickerPages = ['farm', 'sea', 'space'];

const allStickers = <Sticker>[
  Sticker('st_cow', '🐄', 'farm'),
  Sticker('st_goat', '🐐', 'farm'),
  Sticker('st_chicken', '🐔', 'farm'),
  Sticker('st_horse', '🐴', 'farm'),
  Sticker('st_sheep', '🐑', 'farm'),
  Sticker('st_duck', '🦆', 'farm'),
  Sticker('st_tractor', '🚜', 'farm'),
  Sticker('st_barn', '🏠', 'farm'),
  Sticker('st_sunflower', '🌻', 'farm'),
  Sticker('st_carrot', '🥕', 'farm'),
  Sticker('st_corn', '🌽', 'farm'),
  Sticker('st_rooster', '🐓', 'farm'),
  Sticker('st_whale', '🐳', 'sea'),
  Sticker('st_octopus', '🐙', 'sea'),
  Sticker('st_crab', '🦀', 'sea'),
  Sticker('st_turtle', '🐢', 'sea'),
  Sticker('st_dolphin', '🐬', 'sea'),
  Sticker('st_shark', '🦈', 'sea'),
  Sticker('st_starfish', '⭐', 'sea'),
  Sticker('st_clownfish', '🐟', 'sea'),
  Sticker('st_seahorse', '🐠', 'sea'),
  Sticker('st_jellyfish', '🪼', 'sea'),
  Sticker('st_submarine', '🚤', 'sea'),
  Sticker('st_anchor', '⚓', 'sea'),
  Sticker('st_rocket', '🚀', 'space'),
  Sticker('st_rover', '🚙', 'space'),
  Sticker('st_planet', '🪐', 'space'),
  Sticker('st_mars', '🔴', 'space'),
  Sticker('st_star', '🌟', 'space'),
  Sticker('st_astronaut', '🧑‍🚀', 'space'),
  Sticker('st_comet', '☄️', 'space'),
  Sticker('st_earth', '🌍', 'space'),
  Sticker('st_sun', '☀️', 'space'),
  Sticker('st_telescope', '🔭', 'space'),
  Sticker('st_satellite', '🛰️', 'space'),
  Sticker('st_robot', '🤖', 'space'),
];

class StickerImage extends StatelessWidget {
  const StickerImage(this.sticker, {super.key});
  final Sticker sticker;

  @override
  Widget build(BuildContext context) {
    return GameImage(
      'assets/images/stickers/${sticker.id}.png',
      fallback: Emoji(sticker.emoji),
    );
  }
}
