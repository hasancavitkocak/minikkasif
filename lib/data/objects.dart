import 'dart:math';

import 'stickers.dart';

/// Mini oyunlarda ortak kullanılan nesne. Görseli
/// `assets/images/objects/<id>.png` dosyasından gelir; dosya yoksa emoji çizilir.
class GameObject {
  const GameObject(
    this.id,
    this.emoji,
    this.category, [
    this.folder = 'objects',
  ]);
  final String id;
  final String emoji;

  /// Görselin bulunduğu klasör (`assets/images/<folder>/<id>.png`).
  final String folder;

  /// 0: meyve, 1: hayvan, 2: taşıt ve oyuncak
  final int category;
}

const gameObjects = <GameObject>[
  GameObject('apple', '🍎', 0),
  GameObject('banana', '🍌', 0),
  GameObject('strawberry', '🍓', 0),
  GameObject('orange', '🍊', 0),
  GameObject('grapes', '🍇', 0),
  GameObject('watermelon', '🍉', 0),
  GameObject('pear', '🍐', 0),
  GameObject('cherry', '🍒', 0),
  GameObject('cat', '🐱', 1),
  GameObject('dog', '🐶', 1),
  GameObject('rabbit', '🐰', 1),
  GameObject('elephant', '🐘', 1),
  GameObject('lion', '🦁', 1),
  GameObject('frog', '🐸', 1),
  GameObject('fish', '🐟', 1),
  GameObject('bird', '🐤', 1),
  GameObject('car', '🚗', 2),
  GameObject('bus', '🚌', 2),
  GameObject('plane', '✈️', 2),
  GameObject('boat', '⛵', 2),
  GameObject('train', '🚂', 2),
  GameObject('balloon', '🎈', 2),
  GameObject('ball', '⚽', 2),
  GameObject('star', '⭐', 2),
];

/// Dünyalar: her oyunun bölümleri onar onar başka bir dünyada geçer ve o
/// dünyanın nesneleriyle oynanır. İlk dünya [gameObjects] ile, deniz ve uzay
/// dünyaları albümdeki çıkartmaların görselleriyle oynanır.
const worldPages = ['farm', 'sea', 'space'];

/// Oynanan bölümün dünyası (0: çiftlik, 1: deniz, 2: uzay). Bölüm açılırken
/// WorldScope ayarlar.
int objectWorld = 0;

final List<List<GameObject>> _worldObjects = [
  gameObjects,
  for (final page in worldPages.skip(1))
    [
      for (final s in allStickers)
        if (s.page == page) GameObject(s.id, s.emoji, 0, 'stickers'),
    ],
];

/// Oynanan dünyanın bütün nesneleri.
List<GameObject> objectPool() =>
    _worldObjects[objectWorld.clamp(0, _worldObjects.length - 1)];

/// Son turların "baş" nesneleri, eskiden yeniye. Aynı nesne art arda ya da
/// kısa aralıkla yeniden sorulmasın diye tutulur.
final List<String> _recentSubjects = [];

/// Birbirinden farklı [count] nesne seçer. [category] verilirse yalnızca o
/// kategoriden seçer.
///
/// Dönen listenin ilk öğesi turun baş nesnesidir (sorulan, sayılan, aranan
/// nesne): son turlarda baş nesne olmuş bir nesne yeniden ilk sıraya gelmez.
/// Havuz küçükse en eski kullanılan öne alınır.
List<GameObject> pickObjects(Random rng, int count, {int? category}) {
  // Deniz ve uzay dünyalarında kategori ayrımı yoktur.
  final pool = [
    for (final o in objectPool())
      if (objectWorld != 0 || category == null || o.category == category) o,
  ]..shuffle(rng);
  // Havuzun en fazla yarısı "yakın zamanda soruldu" sayılır.
  final window = min(8, pool.length ~/ 2);
  final recent = _recentSubjects.reversed
      .where((id) => pool.any((o) => o.id == id))
      .take(window)
      .toList();
  final fresh = [
    for (final o in pool)
      if (!recent.contains(o.id)) o,
  ];
  final stale = [
    for (final id in recent.reversed) pool.firstWhere((o) => o.id == id),
  ];
  final picked = [...fresh, ...stale].take(count).toList();
  if (picked.isNotEmpty) {
    _recentSubjects
      ..remove(picked.first.id)
      ..add(picked.first.id);
    if (_recentSubjects.length > 24) {
      _recentSubjects.removeAt(0);
    }
  }
  return picked;
}

int _lastNumber = 0;

/// 1 ile [max] arasında, bir önceki seçilenden farklı bir sayı seçer.
int pickNumber(Random rng, int max) {
  var n = 1 + rng.nextInt(max);
  if (max > 1 && n == _lastNumber) n = n % max + 1;
  return _lastNumber = n;
}
