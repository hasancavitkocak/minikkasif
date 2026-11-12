import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../games/coloring_game.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

/// Parmakla çizilmiş bir çizgi. Noktalar sayfanın oranıdır (0..1).
class _Stroke {
  _Stroke(this.color, this.points, this.thick);

  /// Boya sırası; silgi çizgisi için -1.
  final int color;
  final List<Offset> points;
  final bool thick;

  List<dynamic> toJson() => [
    color,
    [
      for (final p in points) ...[
        double.parse(p.dx.toStringAsFixed(3)),
        double.parse(p.dy.toStringAsFixed(3)),
      ],
    ],
    thick,
  ];
}

/// Resim çiz: beyaz bir sayfaya parmakla serbest çizim. Renk seçilir,
/// çizilir; silgiyle silinir; tek düğmeyle sayfa temizlenir. Onay ya da
/// yazı yoktur, küçük çocuk tek başına kullanır. Resim kaydedilir.
class SceneScreen extends StatefulWidget {
  const SceneScreen({super.key});

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  static const _maxStrokes = 150;
  static const _paints = [
    AppColors.red,
    AppColors.orange,
    AppColors.yellow,
    AppColors.green,
    AppColors.teal,
    AppColors.blue,
    AppColors.purple,
    AppColors.pink,
    Color(0xFF9C6B3F),
    AppColors.ink,
  ];

  final List<_Stroke> _strokes = [];

  /// Seçili boya; silgi seçiliyken -1.
  int _paint = 0;
  bool _thick = false;

  /// Çizen parmağın numarası; ikinci parmak çizimi bozmaz.
  int? _drawing;

  /// Kılavuz resim: 0 yok, 1.. boyama resimlerinin çizgileri.
  int _guide = 0;
  ui.Image? _guideImage;

  @override
  void initState() {
    super.initState();
    _restore();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Sayfa boşsa adın ardından ne yapılacağı da söylenir.
      Tts.speakKeys([
        'g_scene',
        if (_strokes.isEmpty) 'scene_hint',
      ], owner: this);
    });
  }

  @override
  void dispose() {
    Tts.stopFor(this);
    super.dispose();
  }

  void _restore() {
    final raw = AppState.I.profileData('scene');
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in (data['strokes'] as List<dynamic>?) ?? const []) {
        final list = e as List<dynamic>;
        final xy = [
          for (final v in list[1] as List<dynamic>) (v as num).toDouble(),
        ];
        _strokes.add(
          _Stroke(list[0] as int, [
            for (var i = 0; i + 1 < xy.length; i += 2) Offset(xy[i], xy[i + 1]),
          ], list.length > 2 && list[2] == true),
        );
      }
      _setGuide((data['guide'] as int?) ?? 0);
    } catch (_) {
      // Bozuk kayıt: boş sayfayla başlanır.
    }
  }

  void _save() {
    AppState.I.setProfileData(
      'scene',
      jsonEncode({
        'guide': _guide,
        'strokes': [for (final s in _strokes) s.toJson()],
      }),
    );
  }

  Future<void> _setGuide(int guide) async {
    _guide = guide % (coloringNames.length + 1);
    if (_guide == 0) {
      if (mounted) setState(() => _guideImage = null);
      return;
    }
    final wanted = _guide;
    final picture = await RasterPicture.load(coloringNames[wanted - 1]);
    if (!mounted || wanted != _guide) return;
    setState(() => _guideImage = picture?.lines);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Backdrop('meadow'),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              // Araçlar her dilde aynı yanda durur.
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    _leftBar(),
                    const SizedBox(width: 10),
                    Expanded(child: _page()),
                    const SizedBox(width: 10),
                    _rightBar(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Beyaz çizim sayfası.
  Widget _page() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          Offset unit(Offset p) => Offset(
            (p.dx / box.maxWidth).clamp(0.0, 1.0),
            (p.dy / box.maxHeight).clamp(0.0, 1.0),
          );
          void start(Offset p) => setState(() {
            _strokes.add(_Stroke(_paint, [unit(p)], _thick));
            if (_strokes.length > _maxStrokes) _strokes.removeAt(0);
          });
          // Ham dokunma olayları: parmak değdiği an çizim başlar, tek dokunuş
          // da bir nokta bırakır.
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (d) {
              _drawing = d.pointer;
              start(d.localPosition);
            },
            onPointerMove: (d) {
              if (d.pointer != _drawing || _strokes.isEmpty) return;
              final p = unit(d.localPosition);
              final points = _strokes.last.points;
              // Çok sık nokta kaydı büyütmesin.
              if ((points.last - p).distance < 0.005) return;
              setState(() => points.add(p));
            },
            onPointerUp: (d) {
              if (d.pointer != _drawing) return;
              _drawing = null;
              _save();
            },
            onPointerCancel: (_) => _drawing = null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _StrokePainter(_strokes, _paints, _guideImage),
                ),
                if (_strokes.isEmpty && _guideImage == null)
                  IgnorePointer(
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.8,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 96,
                                height: 96,
                                child: Mascot('hello'),
                              ),
                              SpeechBubble(
                                child: Text(
                                  L.t('scene_hint'),
                                  style: titleStyle.copyWith(fontSize: 22),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Sol kenar: geri düğmesi ve boyalar.
  Widget _leftBar() {
    return Column(
      children: [
        const BackRoundButton(),
        const SizedBox(height: 6),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(26),
              ),
              // Boyalar iki sütunda durur, parmakla rahat seçilir.
              child: SizedBox(
                width: 96,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (var i = 0; i < _paints.length; i++)
                      Pressable(
                        onTap: () => setState(() => _paint = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _paints[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: i == _paint
                                  ? AppColors.yellow
                                  : Colors.white,
                              width: i == _paint ? 6 : 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.2),
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: i == _paint
                              ? Icon(
                                  Icons.brush_rounded,
                                  size: 22,
                                  color: i == 2 ? AppColors.ink : Colors.white,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Sağ kenar: silgi, fırça kalınlığı, kılavuz resim ve sayfayı temizle.
  Widget _rightBar() {
    Widget tool(
      IconData icon,
      Color color,
      VoidCallback onTap, {
      bool selected = false,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.yellow : Colors.transparent,
              width: 5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: RoundButton(
              icon: icon,
              color: color,
              size: 58,
              onTap: onTap,
            ),
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Silgi bir boya gibi seçilir; sürtülen yer silinir.
          tool(
            Icons.auto_fix_normal_rounded,
            AppColors.pink,
            () => setState(() => _paint = -1),
            selected: _paint == -1,
          ),
          tool(
            _thick ? Icons.circle : Icons.fiber_manual_record_outlined,
            AppColors.blue,
            () => setState(() => _thick = !_thick),
          ),
          tool(
            Icons.image_rounded,
            _guide == 0 ? AppColors.grey : AppColors.green,
            () async {
              await _setGuide(_guide + 1);
              _save();
            },
          ),
          // Tümünü sil: onay sorulmaz, küçük çocuk tek dokunuşla yapar.
          tool(Icons.delete_rounded, AppColors.red, () {
            Sfx.play('pop');
            setState(_strokes.clear);
            _save();
          }),
        ],
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.strokes, this.paints, this.guide)
    : _count = strokes.fold(strokes.length, (n, s) => n + s.points.length);
  final List<_Stroke> strokes;
  final List<Color> paints;

  /// Çizimin üstünde duran kılavuz resim (boyama kitabı gibi).
  final ui.Image? guide;
  final int _count;

  @override
  void paint(Canvas canvas, Size size) {
    // Silgi yalnızca çizimi siler; ayrı katmanda çizilip sayfaya basılır.
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final stroke in strokes) {
      final eraser = stroke.color < 0;
      final paint = Paint()
        ..color = eraser ? Colors.white : paints[stroke.color % paints.length]
        ..blendMode = eraser ? BlendMode.clear : BlendMode.srcOver
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            size.height * (eraser ? 0.09 : (stroke.thick ? 0.07 : 0.028))
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final first = stroke.points.first;
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          Offset(first.dx * size.width, first.dy * size.height),
          paint.strokeWidth / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }
      final path = Path()
        ..moveTo(first.dx * size.width, first.dy * size.height);
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.dx * size.width, p.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
    final image = guide;
    if (image != null) {
      final side = size.shortestSide * 0.94;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width * 1.0, image.height * 1.0),
        Rect.fromCenter(
          center: size.center(Offset.zero),
          width: side,
          height: side,
        ),
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
  }

  @override
  bool shouldRepaint(_StrokePainter old) =>
      old._count != _count || old.guide != guide;
}
