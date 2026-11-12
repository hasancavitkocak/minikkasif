import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';
import 'quiz_round.dart';
import 'shapes_game.dart';

/// Saat oyununun üç aşaması.
enum ClockMode {
  /// Şekilli sayı parçalarını saatteki oyuklarına yerleştir.
  place,

  /// Akrebin gösterdiği saati söyle.
  read,

  /// Akrebi istenen sayıya getir.
  set,
}

/// Saat: tahta oyuncak saat gibi. Önce şekilli sayı parçaları yerlerine
/// sürüklenir, sonra tam saatler okunur, en son saat ayarlanır. Küçük yaşta
/// (3-4) parça ve seçenek sayısı azalır.
class ClockGame extends StatelessWidget {
  const ClockGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  static ClockMode modeOf(int level) => level <= 3
      ? ClockMode.place
      : level <= 7
      ? ClockMode.read
      : ClockMode.set;

  @override
  Widget build(BuildContext context) {
    final mode = modeOf(level);
    return GameShell(
      game: game,
      level: level,
      // Yerleştirme turlarında her turda birkaç parça olduğu için tur azdır.
      rounds: mode == ClockMode.place ? 3 : 5,
      instruction: (_) => L.t(switch (mode) {
        ClockMode.place => 'i_clock_place',
        ClockMode.read => 'i_clock_read',
        ClockMode.set => 'i_clock_set',
      }),
      roundBuilder: (round, onSolved, onMistake) => mode == ClockMode.place
          ? _PlaceRound(level: level, onSolved: onSolved, onMistake: onMistake)
          : _ClockRound(
              level: level,
              mode: mode,
              first: round == 0,
              onSolved: onSolved,
              onMistake: onMistake,
            ),
    );
  }
}

bool get _young {
  final age = AppState.I.playAge;
  return age == 3 || age == 4;
}

/// Yerleştirme turu: saatte birkaç oyuk, yanda o oyukların parçaları.
class _PlaceRound extends StatefulWidget {
  const _PlaceRound({
    required this.level,
    required this.onSolved,
    required this.onMistake,
  });
  final int level;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_PlaceRound> createState() => _PlaceRoundState();
}

class _PlaceRoundState extends State<_PlaceRound> {
  /// Yerine konmayı bekleyen sayılar, yandaki tepside durdukları sırayla.
  late final List<int> _pieces;
  final Set<int> _placed = {};
  final _clockKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final level = widget.level;
    final count = (level + 2 - (_young ? 1 : 0)).clamp(2, 5);
    final numbers = List.generate(12, (i) => i + 1)..shuffle(rng);
    if (level <= 2) {
      // İlk bölümlerde her parçanın şekli farklıdır: şekle bakmak yeter.
      final seen = <ShapeKind>{};
      _pieces = [
        for (final n in numbers)
          if (seen.add(ClockFace.shapeOf(n))) n,
      ].take(count).toList();
    } else {
      // Sonra aynı şekilden iki parça olabilir: sayıya da bakmak gerekir.
      _pieces = numbers.take(count).toList();
    }
  }

  /// Parça bırakılınca: ortası bir oyuğa yeterince yakınsa o oyuğa konur.
  /// Parmağın tam oyuğun üstünde olması gerekmez; küçük eller için hoşgörülü.
  void _release(int piece, Offset center, double clockSize) {
    final box = _clockKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(center);
    int? nearest;
    var best = clockSize * 0.13;
    for (final n in _pieces) {
      if (_placed.contains(n)) continue;
      final distance = (ClockFace.centerOf(n, clockSize) - local).distance;
      if (distance < best) {
        best = distance;
        nearest = n;
      }
    }
    if (nearest != null) _drop(nearest, piece);
  }

  void _drop(int hole, int piece) {
    if (hole != piece) {
      widget.onMistake();
      return;
    }
    setState(() => _placed.add(hole));
    Tts.speak('$hole');
    if (_placed.length == _pieces.length) {
      widget.onSolved();
    } else {
      Sfx.play('pop');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final clockSize = min(box.maxHeight, box.maxWidth * 0.5) * 0.98;
        // Tepsideki parçalar kolay tutulsun diye saattekilerden büyüktür.
        final piece = min(
          box.maxHeight / 3 - 10,
          (box.maxWidth - clockSize) / 3 - 16,
        ).clamp(36.0, 96.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ClockFace(
              key: _clockKey,
              size: clockSize,
              holes: {
                for (final n in _pieces)
                  if (!_placed.contains(n)) n,
              },
            ),
            SizedBox(
              width: piece * 2 + 28,
              child: Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (final n in _pieces)
                    if (_placed.contains(n))
                      SizedBox(width: piece, height: piece)
                    else
                      Draggable<int>(
                        data: n,
                        // Sürüklenen parça ekranın üst katmanında çizilir.
                        feedback: Material(
                          type: MaterialType.transparency,
                          child: ClockPiece(n, size: piece),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.25,
                          child: ClockPiece(n, size: piece),
                        ),
                        onDragEnd: (details) => _release(
                          n,
                          details.offset + Offset(piece / 2, piece / 2),
                          clockSize,
                        ),
                        child: ClockPiece(n, size: piece),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClockRound extends StatefulWidget {
  const _ClockRound({
    required this.level,
    required this.mode,
    required this.first,
    required this.onSolved,
    required this.onMistake,
  });
  final int level;
  final ClockMode mode;

  /// Bölümün ilk turu mu? İlk turda yönerge okunduğu için sayı biraz
  /// bekleyip söylenir.
  final bool first;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_ClockRound> createState() => _ClockRoundState();
}

class _ClockRoundState extends State<_ClockRound> {
  static final _recent = RecentPicker(3);

  late final int _answer;
  late final List<int> _options;

  /// Ayarlama aşamasında akrebin durduğu sayı.
  int _hand = 12;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final level = widget.level;
    final young = _young;
    final maxHour = switch (widget.mode) {
      ClockMode.read => level <= (young ? 6 : 5) ? 6 : 12,
      // Akrep 12'de başladığı için 12 sorulmaz.
      _ => young && level == 8 ? 6 : 11,
    };
    _answer = _recent.pick(rng, maxHour) + 1;
    final count = young && level <= 5 ? 2 : 3;
    // Yanlış seçenekler doğru cevaba yakın sayılardan seçilir.
    final near = [
      for (var n = max(1, _answer - 3); n <= min(12, _answer + 3); n++)
        if (n != _answer) n,
    ]..shuffle(rng);
    _options = [_answer, ...near.take(count - 1)]..shuffle(rng);
    if (widget.mode == ClockMode.set) {
      _timer = Timer(Duration(milliseconds: widget.first ? 2200 : 700), () {
        if (mounted) Tts.speak('$_answer');
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _pick(int n) {
    if (n != _answer) {
      widget.onMistake();
      return false;
    }
    setState(() => _hand = n);
    Tts.speak('$n');
    widget.onSolved();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    return LayoutBuilder(
      builder: (context, box) {
        final clockSize = min(box.maxHeight, box.maxWidth * 0.5) * 0.98;
        final clock = ClockFace(
          size: clockSize,
          hour: mode == ClockMode.read ? _answer : _hand,
          onTap: mode == ClockMode.set ? _pick : null,
        );
        if (mode == ClockMode.set) {
          final badge = min(box.maxHeight * 0.5, box.maxWidth * 0.22);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // İstenen saat: büyük bir sayı (ayrıca sesli söylenir).
              Container(
                width: badge,
                height: badge,
                padding: EdgeInsets.all(badge * 0.14),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: badge * 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FittedBox(
                  child: Text(
                    '$_answer',
                    style: titleStyle.copyWith(
                      fontSize: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              clock,
            ],
          );
        }
        final tile = min(
          box.maxHeight / _options.length - 12,
          box.maxWidth * 0.16,
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            clock,
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final n in _options)
                  ChoiceTile(
                    size: tile,
                    onTap: () => _pick(n),
                    child: FittedBox(
                      child: Text(
                        '$n',
                        style: titleStyle.copyWith(
                          fontSize: 64,
                          color: ClockFace.colorOf(n),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Saatin bir sayı parçası: kendi şeklinde ve renginde, üstünde sayısı.
/// [ghost] verilirse parçanın boş oyuğu çizilir.
class ClockPiece extends StatelessWidget {
  const ClockPiece(
    this.number, {
    super.key,
    required this.size,
    this.ghost = false,
  });
  final int number;
  final double size;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final kind = ClockFace.shapeOf(number);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: ShapePainter(
                kind,
                ghost ? AppColors.grey : ClockFace.colorOf(number),
                ghost: ghost,
              ),
            ),
          ),
          // Üçgende sayı tabana yakın durur ki şeklin içinde kalsın.
          Align(
            alignment: Alignment(0, kind == ShapeKind.triangle ? 0.55 : 0.05),
            child: SizedBox(
              width: size * 0.5,
              height: size * 0.42,
              child: FittedBox(
                child: Text(
                  '$number',
                  style: titleStyle.copyWith(
                    fontSize: 40,
                    color: ghost
                        ? AppColors.ink.withValues(alpha: 0.3)
                        : Colors.white,
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

/// Oyuncak saat: her sayı kendi şeklinde bir parçadır; kısa kalın akrep ve
/// 12'de duran yelkovan.
class ClockFace extends StatelessWidget {
  const ClockFace({
    super.key,
    required this.size,
    this.hour,
    this.holes = const {},
    this.onTap,
  });

  final double size;

  /// Akrebin gösterdiği saat; null ise kollar çizilmez.
  final int? hour;

  /// Parçası henüz yerine konmamış sayılar; yerleri boş oyuk olarak görünür.
  final Set<int> holes;

  /// Verilirse sayılara dokunulabilir; doğru sayıda true döner.
  final bool Function(int n)? onTap;

  static const _colors = [
    AppColors.red,
    AppColors.orange,
    AppColors.green,
    AppColors.teal,
    AppColors.blue,
    AppColors.purple,
  ];

  // 1 daire, 2 kare, 3 yıldız, 4 kalp, 5 baklava, 6 üçgen; 7'den sonra
  // yinelenir, yani 12 üçgendir.
  static const _shapes = [
    ShapeKind.circle,
    ShapeKind.square,
    ShapeKind.star,
    ShapeKind.heart,
    ShapeKind.diamond,
    ShapeKind.triangle,
  ];

  static Color colorOf(int n) => _colors[(n - 1) % _colors.length];
  static ShapeKind shapeOf(int n) => _shapes[(n - 1) % _shapes.length];

  /// [n] sayısının, [size] boyutundaki saatin içindeki merkezi.
  static Offset centerOf(int n, double size) => Offset(
    size / 2 + size * 0.355 * sin(n * pi / 6),
    size / 2 - size * 0.355 * cos(n * pi / 6),
  );

  @override
  Widget build(BuildContext context) {
    final chip = size * 0.17;
    return SizedBox(
      width: size,
      height: size,
      // Saat her dilde aynı yönde döner.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _FacePainter(hands: hour != null)),
            ),
            if (hour != null)
              Positioned.fill(
                child: AnimatedRotation(
                  turns: (hour! % 12) / 12,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  child: const CustomPaint(painter: _HourHandPainter()),
                ),
              ),
            for (var n = 1; n <= 12; n++)
              Positioned(
                left: centerOf(n, size).dx - chip / 2,
                top: centerOf(n, size).dy - chip / 2,
                width: chip,
                height: chip,
                child: _chip(n, chip),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(int n, double d) {
    if (holes.contains(n)) {
      // Bırakma, parçanın oyuğa yakınlığına göre oyun tarafından karara
      // bağlanır; burada yalnızca üstüne gelindiğinde oyuk büyür.
      return DragTarget<int>(
        builder: (context, candidates, _) => AnimatedScale(
          scale: candidates.isNotEmpty ? 1.25 : 1,
          duration: const Duration(milliseconds: 120),
          child: ClockPiece(n, size: d, ghost: true),
        ),
      );
    }
    final piece = ClockPiece(n, size: d);
    final tap = onTap;
    if (tap == null) return piece;
    return Pressable(onTap: () => tap(n), child: piece);
  }
}

class _FacePainter extends CustomPainter {
  const _FacePainter({required this.hands});
  final bool hands;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    // Gölge, renkli kasnak ve beyaz kadran.
    canvas.drawCircle(
      c.translate(0, r * 0.04),
      r * 0.97,
      Paint()..color = AppColors.ink.withValues(alpha: 0.18),
    );
    canvas.drawCircle(c, r * 0.97, Paint()..color = AppColors.blue);
    canvas.drawCircle(c, r * 0.89, Paint()..color = Colors.white);
    if (hands) {
      // Yelkovan tam saatlerde hep 12'yi gösterir.
      canvas.drawLine(
        c,
        c.translate(0, -r * 0.5),
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.55)
          ..strokeWidth = r * 0.035
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.hands != hands;
}

/// Yukarıyı gösteren akrep; [AnimatedRotation] ile saate döndürülür.
class _HourHandPainter extends CustomPainter {
  const _HourHandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawLine(
      c,
      c.translate(0, -r * 0.36),
      Paint()
        ..color = AppColors.red
        ..strokeWidth = r * 0.085
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, r * 0.075, Paint()..color = AppColors.ink);
    canvas.drawCircle(c, r * 0.035, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_HourHandPainter old) => false;
}
