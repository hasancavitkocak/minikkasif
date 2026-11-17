import 'package:flutter/material.dart';

import 'objects.dart';

/// Meyve mi sebze mi.
enum ProduceKind { fruit, veg }

/// Nerede yetiştiği. Tanıtım kartında söylenir; "Hangisi ağaçta yetişir?"
/// sorusunda yalnızca [tree], [field] ve [under] karşılaştırılır.
enum Grow {
  /// Ağaçta (elma, armut...).
  tree,

  /// Tarlada (çilek, domates...).
  field,

  /// Toprağın altında (havuç, patates).
  under,

  /// Asmada (üzüm).
  vine,

  /// Sıcak ülkelerde (muz).
  warm,
}

/// Meyve ve Sebze oyunundaki bir ürün. Görselleri `assets/images/objects/`
/// (havuç ve mısır çıkartma görsellerinden) gelir.
class Produce {
  const Produce(this.key, this.image, this.kind, this.color, this.grow);

  /// Çeviri ve ses kaydı adlarının kökü: adı `food_<key>`.
  final String key;
  final GameObject image;
  final ProduceKind kind;

  /// Gerçek rengi; birden çok belirgin rengi olanlarda (karpuz, mısır,
  /// patates) null, renk sorularında kullanılmaz.
  final ProduceColor? color;
  final Grow grow;

  String get nameKey => 'food_$key';
  String get kindKey => kind == ProduceKind.fruit ? 'food_fruit' : 'food_veg';
  String get growKey => 'grow_${grow.name}';
}

/// Renk soruları: rengin adı ve gerçek rengi.
enum ProduceColor {
  red(Color(0xFFE53935)),
  yellow(Color(0xFFFDD835)),
  orange(Color(0xFFFB8C00)),
  green(Color(0xFF43A047)),
  purple(Color(0xFF8E24AA));

  const ProduceColor(this.color);
  final Color color;

  /// "Kırmızı olanı bul!" gibi yönergenin anahtarı.
  String get instructionKey => 'i_fruits_$name';
}

const produce = <Produce>[
  Produce(
    'apple',
    GameObject('apple', '🍎', 0),
    ProduceKind.fruit,
    ProduceColor.red,
    Grow.tree,
  ),
  Produce(
    'pear',
    GameObject('pear', '🍐', 0),
    ProduceKind.fruit,
    ProduceColor.green,
    Grow.tree,
  ),
  Produce(
    'banana',
    GameObject('banana', '🍌', 0),
    ProduceKind.fruit,
    ProduceColor.yellow,
    Grow.warm,
  ),
  Produce(
    'carrot',
    GameObject('st_carrot', '🥕', 0, 'stickers'),
    ProduceKind.veg,
    ProduceColor.orange,
    Grow.under,
  ),
  Produce(
    'tomato',
    GameObject('tomato', '🍅', 0),
    ProduceKind.veg,
    ProduceColor.red,
    Grow.field,
  ),
  Produce(
    'grapes',
    GameObject('grapes', '🍇', 0),
    ProduceKind.fruit,
    ProduceColor.purple,
    Grow.vine,
  ),
  Produce(
    'orange',
    GameObject('orange', '🍊', 0),
    ProduceKind.fruit,
    ProduceColor.orange,
    Grow.tree,
  ),
  Produce(
    'cucumber',
    GameObject('cucumber', '🥒', 0),
    ProduceKind.veg,
    ProduceColor.green,
    Grow.field,
  ),
  Produce(
    'strawberry',
    GameObject('strawberry', '🍓', 0),
    ProduceKind.fruit,
    ProduceColor.red,
    Grow.field,
  ),
  Produce(
    'potato',
    GameObject('potato', '🥔', 0),
    ProduceKind.veg,
    null,
    Grow.under,
  ),
  Produce(
    'cherry',
    GameObject('cherry', '🍒', 0),
    ProduceKind.fruit,
    ProduceColor.red,
    Grow.tree,
  ),
  Produce(
    'eggplant',
    GameObject('eggplant', '🍆', 0),
    ProduceKind.veg,
    ProduceColor.purple,
    Grow.field,
  ),
  Produce(
    'lemon',
    GameObject('lemon', '🍋', 0),
    ProduceKind.fruit,
    ProduceColor.yellow,
    Grow.tree,
  ),
  Produce(
    'broccoli',
    GameObject('broccoli', '🥦', 0),
    ProduceKind.veg,
    ProduceColor.green,
    Grow.field,
  ),
  Produce(
    'watermelon',
    GameObject('watermelon', '🍉', 0),
    ProduceKind.fruit,
    null,
    Grow.field,
  ),
  Produce(
    'corn',
    GameObject('st_corn', '🌽', 0, 'stickers'),
    ProduceKind.veg,
    null,
    Grow.field,
  ),
  Produce(
    'pumpkin',
    GameObject('pumpkin', '🟠', 0),
    ProduceKind.veg,
    ProduceColor.orange,
    Grow.field,
  ),
];
