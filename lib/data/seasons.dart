import 'objects.dart';

/// Mevsimler: 0 ilkbahar, 1 yaz, 2 sonbahar, 3 kış. Görseller
/// `assets/images/seasons/` klasöründedir.
const seasons = <GameObject>[
  GameObject('season_spring', '🌷', 0, 'seasons'),
  GameObject('season_summer', '☀️', 0, 'seasons'),
  GameObject('season_autumn', '🍂', 0, 'seasons'),
  GameObject('season_winter', '❄️', 0, 'seasons'),
];

/// Fıstık'ın her mevsime göre giyinmiş hali, [seasons] ile aynı sırada:
/// ilkbaharda yağmurluk, yazın ince giysiler, sonbaharda kazak, kışın mont.
const seasonOutfits = <GameObject>[
  GameObject('dress_spring', '☂️', 0, 'seasons'),
  GameObject('dress_summer', '🕶️', 0, 'seasons'),
  GameObject('dress_autumn', '🧶', 0, 'seasons'),
  GameObject('dress_winter', '🧣', 0, 'seasons'),
];

/// İlkbahar ile sonbahar kıyafetleri birbirine yakındır (ikisi de serin ve
/// yağışlı); kolay bölümlerde aynı soruda karşı karşıya getirilmezler.
int seasonTwin(int season) => switch (season) {
  0 => 2,
  2 => 0,
  _ => -1,
};
