import 'objects.dart';

/// Hayvanlar oyunundaki bir hayvan. Görselleri oyundaki hazır nesne ve
/// çıkartma görsellerinden gelir; sesi `assets/audio/animals/<key>.mp3`
/// dosyasındadır.
class Animal {
  const Animal(this.key, this.image);

  /// Çeviri, ses kaydı ve hayvan sesi dosyasının kökü: adı `animal_<key>`,
  /// tanıtım cümlesi `animal_<key>_d`, sesinin yazılışı `animal_<key>_s`.
  final String key;
  final GameObject image;

  String get nameKey => 'animal_$key';
  String get textKey => 'animal_${key}_d';

  /// Hayvan sesi kaydı yokken cihazın okuduğu yazılış (ör. "Miyav!").
  String get soundKey => 'animal_${key}_s';
}

/// Sesleri birbirinden kolayca ayırt edilen, gerçek hayvanlar. Keçi ile koyun
/// (ikisi de "mee") ve tavuk ile horoz birbirine çok benzediği için birer
/// tanesi alındı.
const animals = <Animal>[
  Animal('cat', GameObject('cat', '🐱', 1)),
  Animal('dog', GameObject('dog', '🐶', 1)),
  Animal('cow', GameObject('st_cow', '🐄', 1, 'stickers')),
  Animal('sheep', GameObject('st_sheep', '🐑', 1, 'stickers')),
  Animal('horse', GameObject('st_horse', '🐴', 1, 'stickers')),
  Animal('duck', GameObject('st_duck', '🦆', 1, 'stickers')),
  Animal('rooster', GameObject('st_rooster', '🐓', 1, 'stickers')),
  Animal('chick', GameObject('bird', '🐤', 1)),
  Animal('frog', GameObject('frog', '🐸', 1)),
  Animal('lion', GameObject('lion', '🦁', 1)),
  Animal('elephant', GameObject('elephant', '🐘', 1)),
];
