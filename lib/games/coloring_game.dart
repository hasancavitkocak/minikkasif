import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';

/// Boyama: küçük örneğe bakarak resmin bölümlerini aynı renklere boya.
class ColoringGame extends StatelessWidget {
  const ColoringGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  @override
  Widget build(BuildContext context) {
    final index = min(level - 1, coloringPictures.length - 1);
    final picture = coloringPictures[index];
    return GameShell(
      game: game,
      level: level,
      rounds: 1,
      tolerance: 2,
      instruction: (_) => L.t('i_color'),
      roundBuilder: (round, onSolved, onMistake) => _ColoringLoader(
        name: coloringNames[index],
        fallback: picture,
        colorCount: min(picture.regions.length, min(6, 2 + level ~/ 2)),
        onSolved: onSolved,
        onMistake: onMistake,
      ),
    );
  }
}

const _palette = [
  AppColors.red,
  AppColors.orange,
  AppColors.yellow,
  AppColors.green,
  AppColors.blue,
  AppColors.purple,
  AppColors.pink,
  Color(0xFFB98052), // kahverengi
  Color(0xFF2EC4B6), // turkuaz
];

/// Boyama paleti; resimlerdeki renk sırası buna göredir.
const coloringPalette = _palette;

/// 100x100 birimlik bir alanda tanımlı boyama resmi.
class ColoringPicture {
  const ColoringPicture(this.regions, {this.lines = const []});

  /// Boyanabilir bölümler; sonraki öncekinin üstüne çizilir.
  final List<Path> regions;

  /// Yalnızca çizgi olarak görünen süslemeler (ip, direk gibi).
  final List<Path> lines;
}

Path _oval(double l, double t, double w, double h) =>
    Path()..addOval(Rect.fromLTWH(l, t, w, h));

Path _circle(double cx, double cy, double r) =>
    Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

Path _rect(double l, double t, double w, double h, [double r = 2]) => Path()
  ..addRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), Radius.circular(r)),
  );

Path _poly(List<double> xy) {
  final path = Path()..moveTo(xy[0], xy[1]);
  for (var i = 2; i < xy.length; i += 2) {
    path.lineTo(xy[i], xy[i + 1]);
  }
  return path..close();
}

Path _line(List<double> xy) {
  final path = Path()..moveTo(xy[0], xy[1]);
  for (var i = 2; i < xy.length; i += 2) {
    path.lineTo(xy[i], xy[i + 1]);
  }
  return path;
}

/// Bölüm sırasıyla, üretilmiş boyama resimlerinin adları
/// (`assets/images/coloring/<ad>_lines.png`). Dosyası olmayan bölümde aynı
/// sıradaki kod çizimi kullanılır.
const coloringNames = [
  'balloons',
  'fish',
  'flower',
  'butterfly',
  'house',
  'car',
  'boat',
  'rocket',
  'turtle',
  'train',
];

/// Üretilmiş bir resimden çıkarılan boyama sayfası
/// (bkz. tool/import_coloring.py).
class RasterPicture {
  RasterPicture._(
    this.size,
    this._map,
    this.lines,
    this._masks,
    this._boxes,
    this.colors,
    this._dots,
  );

  /// Kare resmin kenarı (piksel).
  final int size;

  /// Piksel başına bölge numarası + 1; 0 boş.
  final Uint8List _map;
  final ui.Image lines;
  final List<ui.Image> _masks;
  final List<Rect> _boxes;

  /// Her bölgenin örnekteki rengi: paletteki sırası.
  final List<int> colors;

  /// "Noktaları birleştir" için resmin dış çizgisi üstündeki noktalar:
  /// nokta sayısı -> sırayla noktalar (0..1).
  final Map<int, List<Offset>> _dots;

  /// [count] noktalı (yoksa en yakın sayıdaki) nokta dizisi.
  List<Offset>? dotsFor(int count) {
    if (_dots.isEmpty) return null;
    final key = _dots.keys.reduce(
      (a, b) => (a - count).abs() <= (b - count).abs() ? a : b,
    );
    return _dots[key];
  }

  static final _cache = <String, Future<RasterPicture?>>{};

  /// Resim yoksa ya da okunamazsa null döner.
  static Future<RasterPicture?> load(String name) =>
      _cache[name] ??= _load(name);

  static Future<RasterPicture?> _load(String name) async {
    try {
      const dir = 'assets/images/coloring';
      final meta =
          jsonDecode(await rootBundle.loadString('$dir/$name.json')) as Map;
      final colors = [for (final c in meta['colors'] as List) c as int];
      final lines = await _decode(
        await rootBundle.load('$dir/${name}_lines.png'),
      );
      final mapImage = await _decode(
        await rootBundle.load('$dir/${name}_map.png'),
      );
      final size = mapImage.width;
      final rgba = (await mapImage.toByteData())!.buffer.asUint8List();
      mapImage.dispose();
      final map = Uint8List(size * size);
      for (var i = 0; i < map.length; i++) {
        final v = rgba[i * 4];
        map[i] = v <= colors.length ? v : 0;
      }
      final masks = <ui.Image>[];
      final boxes = <Rect>[];
      for (var r = 0; r < colors.length; r++) {
        final b = [
          for (final v in (meta['boxes'] as List)[r] as List) v as int,
        ];
        masks.add(await _decode(await rootBundle.load('$dir/${name}_r$r.png')));
        boxes.add(
          Rect.fromLTWH(b[0] * 1.0, b[1] * 1.0, b[2] * 1.0, b[3] * 1.0),
        );
      }
      final dots = <int, List<Offset>>{};
      (meta['dots'] as Map?)?.forEach((count, points) {
        dots[int.parse(count as String)] = [
          for (final p in points as List)
            Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
        ];
      });
      return RasterPicture._(size, map, lines, masks, boxes, colors, dots);
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image> _decode(ByteData data) async {
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  /// 0..1 aralığındaki noktadaki bölge; yoksa -1.
  int regionAt(Offset unit) {
    final x = (unit.dx * size).floor(), y = (unit.dy * size).floor();
    if (x < 0 || y < 0 || x >= size || y >= size) return -1;
    return _map[y * size + x] - 1;
  }

  void paint(Canvas canvas, Size area, List<Color?> fills) {
    canvas.save();
    canvas.scale(area.width / size);
    for (var i = 0; i < _masks.length; i++) {
      final color = fills[i];
      if (color == null) continue;
      canvas.drawImage(
        _masks[i],
        _boxes[i].topLeft,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    canvas.drawImage(
      lines,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }
}

/// Kolaydan zora sıralı kod çizimi resimler; üretilmiş resmi olmayan bölümde
/// kullanılır.
final coloringPictures = <ColoringPicture>[
  // Balonlar
  ColoringPicture(
    [_oval(8, 16, 28, 36), _oval(64, 16, 28, 36), _oval(36, 6, 28, 36)],
    lines: [
      _line([22, 52, 50, 96]),
      _line([78, 52, 50, 96]),
      _line([50, 42, 50, 96]),
    ],
  ),

  // Balık
  ColoringPicture(
    [
      _poly([24, 50, 4, 30, 4, 70]),
      _poly([40, 32, 56, 12, 64, 32]),
      _poly([44, 68, 56, 86, 62, 68]),
      _oval(20, 28, 60, 44),
    ],
    lines: [_circle(64, 44, 2.5)],
  ),

  // Çiçek
  ColoringPicture([
    _rect(47, 50, 6, 46),
    _oval(26, 66, 21, 11),
    _oval(53, 74, 21, 11),
    for (var i = 0; i < 6; i++)
      _circle(50 + 17 * cos(i * pi / 3), 32 + 17 * sin(i * pi / 3), 11),
    _circle(50, 32, 10),
  ]),

  // Kelebek
  ColoringPicture([
    _oval(8, 12, 38, 40),
    _oval(54, 12, 38, 40),
    _oval(14, 50, 32, 36),
    _oval(54, 50, 32, 36),
    _oval(45, 16, 10, 68),
  ]),

  // Ev
  ColoringPicture([
    _circle(86, 14, 9),
    _rect(22, 46, 56, 46),
    _poly([12, 48, 50, 12, 88, 48]),
    _rect(42, 64, 16, 28),
    _rect(27, 54, 11, 11),
    _rect(62, 54, 11, 11),
  ]),

  // Araba
  ColoringPicture([
    _poly([24, 50, 36, 28, 66, 28, 78, 50]),
    _rect(41, 33, 20, 14),
    _rect(6, 48, 88, 24, 8),
    _circle(28, 74, 11),
    _circle(72, 74, 11),
  ]),

  // Yelkenli
  ColoringPicture(
    [
      _circle(14, 16, 9),
      _poly([10, 66, 90, 66, 74, 90, 26, 90]),
      _poly([47, 22, 47, 61, 18, 61]),
      _poly([53, 30, 53, 61, 80, 61]),
      _poly([50, 8, 66, 14, 50, 20]),
    ],
    lines: [
      _line([50, 8, 50, 66]),
    ],
  ),

  // Roket
  ColoringPicture([
    _poly([42, 74, 58, 74, 50, 97]),
    _poly([36, 54, 18, 80, 36, 74]),
    _poly([64, 54, 82, 80, 64, 74]),
    _rect(36, 24, 28, 52, 12),
    _poly([36, 32, 50, 3, 64, 32]),
    _circle(50, 46, 7),
  ]),

  // Dondurma
  ColoringPicture([
    _poly([30, 52, 70, 52, 50, 97]),
    _circle(37, 42, 16),
    _circle(63, 42, 16),
    _circle(50, 22, 16),
  ]),

  // Tren
  ColoringPicture([
    _rect(10, 44, 50, 30, 4),
    _rect(60, 24, 28, 50, 4),
    _rect(66, 32, 16, 16),
    _rect(20, 26, 12, 18),
    _poly([16, 26, 36, 26, 32, 16, 20, 16]),
    _circle(24, 78, 10),
    _circle(48, 78, 10),
    _circle(74, 78, 10),
  ]),
];

/// Üretilmiş resmi yükler; yoksa kod çizimiyle devam eder.
class _ColoringLoader extends StatefulWidget {
  const _ColoringLoader({
    required this.name,
    required this.fallback,
    required this.colorCount,
    required this.onSolved,
    required this.onMistake,
  });
  final String name;
  final ColoringPicture fallback;
  final int colorCount;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_ColoringLoader> createState() => _ColoringLoaderState();
}

class _ColoringLoaderState extends State<_ColoringLoader> {
  late final Future<RasterPicture?> _raster = RasterPicture.load(widget.name);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RasterPicture?>(
      future: _raster,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.expand();
        }
        return _ColoringRound(
          picture: widget.fallback,
          raster: snap.data,
          colorCount: widget.colorCount,
          onSolved: widget.onSolved,
          onMistake: widget.onMistake,
        );
      },
    );
  }
}

class _ColoringRound extends StatefulWidget {
  const _ColoringRound({
    required this.picture,
    this.raster,
    required this.colorCount,
    required this.onSolved,
    required this.onMistake,
  });
  final ColoringPicture picture;

  /// Varsa kod çizimi yerine bu resim boyanır.
  final RasterPicture? raster;
  final int colorCount;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_ColoringRound> createState() => _ColoringRoundState();
}

class _ColoringRoundState extends State<_ColoringRound> {
  late final List<Color> _colors;

  /// Her bölümün örnekteki rengi.
  late final List<Color> _target;
  late final List<Color?> _painted;
  late Color _selected;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final raster = widget.raster;
    if (raster != null) {
      // Üretilmiş resimde renkler resmin kendi renkleridir.
      _target = [for (final c in raster.colors) _palette[c % _palette.length]];
      final used = _palette.where(_target.contains).toList();
      final spare = _palette.where((c) => !used.contains(c)).toList()
        ..shuffle(rng);
      // Seçim yapılabilsin diye en az üç boya sunulur.
      while (used.length < 3 && spare.isNotEmpty) {
        used.add(spare.removeLast());
      }
      _colors = _palette.where(used.contains).toList();
      _painted = List.filled(_target.length, null);
      _selected = _colors.first;
      return;
    }
    final n = widget.picture.regions.length;
    _colors = ([..._palette]..shuffle(rng)).take(widget.colorCount).toList();
    // Her renk en az bir kez kullanılır.
    final picks = [
      for (var i = 0; i < n; i++)
        i < _colors.length ? _colors[i] : _colors[rng.nextInt(_colors.length)],
    ]..shuffle(rng);
    _target = picks;
    _painted = List.filled(n, null);
    _selected = _colors.first;
  }

  void _tap(Offset position, double size) {
    if (_done) return;
    final raster = widget.raster;
    final point = position * (100 / size);
    final hit = raster?.regionAt(position / size);
    // Üstte çizilen bölüm önce denenir.
    for (var i = _target.length - 1; i >= 0; i--) {
      if (raster != null
          ? hit != i
          : !widget.picture.regions[i].contains(point)) {
        continue;
      }
      if (_painted[i] == _selected) return;
      setState(() => _painted[i] = _selected);
      if (_selected != _target[i]) {
        widget.onMistake();
      } else if (List.generate(
        _target.length,
        (j) => _painted[j] == _target[j],
      ).every((ok) => ok)) {
        _done = true;
        widget.onSolved();
      } else {
        Sfx.play('pop');
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final canvas = min(box.maxHeight, box.maxWidth * 0.56);
        final side = min(box.maxWidth - canvas - 24, box.maxHeight * 0.9);
        final sample = min(side, box.maxHeight * 0.46);
        final swatch = min(
          (side - 16) / 3,
          (box.maxHeight - sample - 28) / 2,
        ).clamp(24.0, 70.0);
        // Resim ve örnek her dilde aynı yönde durur.
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: side,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Örnek: boyanmış hali.
                    Container(
                      width: sample,
                      height: sample,
                      padding: EdgeInsets.all(sample * 0.06),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(sample * 0.14),
                        border: Border.all(color: AppColors.yellow, width: 4),
                      ),
                      child: CustomPaint(
                        painter: _PicturePainter(
                          widget.picture,
                          _target,
                          widget.raster,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final color in _colors)
                          Pressable(
                            onTap: () => setState(() => _selected = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: swatch,
                              height: swatch,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selected == color
                                      ? AppColors.ink
                                      : Colors.white,
                                  width: _selected == color ? 5 : 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.ink.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: _selected == color
                                  ? Icon(
                                      Icons.brush_rounded,
                                      color: Colors.white,
                                      size: swatch * 0.5,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTapDown: (d) => _tap(
                  d.localPosition - Offset(canvas * 0.05, canvas * 0.05),
                  canvas * 0.9,
                ),
                child: Container(
                  width: canvas,
                  height: canvas,
                  padding: EdgeInsets.all(canvas * 0.05),
                  decoration: panelDecoration(radius: canvas * 0.08),
                  child: CustomPaint(
                    painter: _PicturePainter(
                      widget.picture,
                      _painted,
                      widget.raster,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PicturePainter extends CustomPainter {
  _PicturePainter(this.picture, List<Color?> colors, this.raster)
    : colors = [...colors];
  final ColoringPicture picture;
  final List<Color?> colors;
  final RasterPicture? raster;

  @override
  void paint(Canvas canvas, Size size) {
    if (raster != null) {
      raster!.paint(canvas, size, colors);
      return;
    }
    canvas.scale(size.width / 100);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = AppColors.ink;
    for (var i = 0; i < picture.regions.length; i++) {
      canvas.drawPath(
        picture.regions[i],
        Paint()..color = colors[i] ?? Colors.white,
      );
      canvas.drawPath(picture.regions[i], outline);
    }
    for (final line in picture.lines) {
      canvas.drawPath(line, outline);
    }
  }

  @override
  bool shouldRepaint(_PicturePainter old) {
    for (var i = 0; i < colors.length; i++) {
      if (old.colors[i] != colors[i]) return true;
    }
    return old.picture != picture || old.raster != raster;
  }
}
