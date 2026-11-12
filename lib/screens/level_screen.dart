import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../games/game_def.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import '../widgets/ui.dart';
import 'certificate.dart';
import 'parent_gate.dart';
import 'paywall_screen.dart';

/// Bir mini oyunun bölüm haritası: bölümler kıvrımlı bir yol üzerinde
/// sıralanır ve sırayla açılır.
class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key, required this.game});
  final GameDef game;

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  GameDef get game => widget.game;

  /// Gösterilen dünya; sıradaki bölümün dünyasıyla açılır.
  late int _world = worldOf(AppState.I.nextLevel(widget.game));

  @override
  void initState() {
    super.initState();
    // Oyun yeni bitirildiyse başarı belgesi bir kez kendiliğinden açılır.
    final seenKey = 'cert_${widget.game.id}';
    if (gameCompleted(widget.game) && !AppState.I.seenHowTo(seenKey)) {
      AppState.I.markHowToSeen(seenKey);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showCertificate(context, widget.game);
      });
    }
  }

  int get _worlds => (game.levels / worldSize).ceil();

  /// Dünya seçici: çiftlik, deniz, uzay.
  Widget _worldTabs() {
    const icons = ['🌳', '🌊', '🚀'];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var w = 0; w < _worlds; w++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Pressable(
                onTap: () => setState(() => _world = w),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: w == _world ? 52 : 44,
                  height: w == _world ? 52 : 44,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: w == _world ? 1 : 0.75,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: w == _world ? AppColors.yellow : Colors.white,
                      width: w == _world ? 4 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Emoji(icons[w % icons.length]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Backdrop(const ['home', 'sea', 'space'][_world.clamp(0, 2)]),
          // Arka plan canlı olduğu için yol ve bölümler seçilsin diye hafif perde.
          Positioned.fill(
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.28)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const BackRoundButton(),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              height: 52,
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                8,
                                4,
                                20,
                                4,
                              ),
                              decoration: panelDecoration(radius: 26),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: GameImage(
                                      'assets/images/icons/game_${game.id}.png',
                                      fallback: Emoji(game.emoji),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(L.t('g_${game.id}'), style: titleStyle),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_worlds > 1) ...[
                        const SizedBox(width: 8),
                        _worldTabs(),
                      ],
                      if (gameCompleted(game)) ...[
                        const SizedBox(width: 8),
                        RoundButton(
                          icon: Icons.workspace_premium_rounded,
                          color: AppColors.orange,
                          size: 48,
                          onTap: () => showCertificate(context, game),
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Maskot ne yapılacağını söyler.
                      Flexible(
                        flex: 2,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SpeechBubble(
                            tail: BubbleTail.none,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            child: Text(
                              L.t('pick_level'),
                              style: titleStyle.copyWith(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: SpeakOnce(
                          'pick_level',
                          before: 'g_${game.id}',
                          child: const Mascot('hello'),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: AppState.I,
                      builder: (context, _) => LayoutBuilder(builder: _map),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _map(BuildContext context, BoxConstraints box) {
    final state = AppState.I;
    // Haritada bir dünyanın bölümleri görünür.
    final first = _world * worldSize;
    final n = min(worldSize, game.levels - first);
    final w = box.maxWidth;
    final h = box.maxHeight;
    final node = min(w / (n + 1.2) * 1.25, h * 0.36);
    final stepX = (w - node * 1.3) / (n - 1);
    final centerY = h * 0.47;
    final amp = min(h * 0.17, (h - node * 1.7) / 2);
    // Kıvrımlı yol: bölümler sırayla yukarıda ve aşağıda durur.
    final points = [
      for (var i = 0; i < n; i++)
        Offset(node * 0.65 + i * stepX, centerY + (i.isEven ? -amp : amp)),
    ];
    // Sıradaki bölüm: açık olup henüz bitirilmemiş ilk bölüm.
    var current = 0;
    for (var level = first + 1; level <= first + n; level++) {
      if (state.canPlay(game, level) &&
          state.levelUnlocked(game.id, level) &&
          state.stars(game.id, level) == 0) {
        current = level;
        break;
      }
    }
    // Harita her dilde soldan sağa ilerler.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _PathPainter(points, node * 0.16)),
          ),
          for (var i = 0; i < n; i++)
            Positioned(
              left: points[i].dx - node / 2,
              top: points[i].dy - node / 2,
              child: _LevelNode(
                game: game,
                level: first + i + 1,
                size: node,
                isCurrent: current == first + i + 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.game,
    required this.level,
    required this.size,
    required this.isCurrent,
  });
  final GameDef game;
  final int level;
  final double size;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    // Ücretli bölüm: dokununca ebeveyn kapısından abonelik ekranına gider.
    final paid = state.canPlay(game, level);
    final unlocked = paid && state.levelUnlocked(game.id, level);
    final stars = state.stars(game.id, level);

    // Durak: çimenli bir adacığın üstünde duran parlak, numaralı düğme.
    final base = unlocked ? game.color : const Color(0xFFD9D4CE);
    final d = size * 0.84;
    final button = Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [
            Color.lerp(base, Colors.white, 0.45)!,
            base,
            Color.lerp(base, Colors.black, 0.18)!,
          ],
          stops: const [0, 0.6, 1],
        ),
        border: Border.all(
          color: isCurrent ? AppColors.yellow : Colors.white,
          width: d * (isCurrent ? 0.085 : 0.065),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: Offset(0, d * 0.07),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Üstteki parlama düğmeye şeker gibi bir hacim verir.
          Positioned(
            top: d * 0.1,
            left: d * 0.17,
            child: Container(
              width: d * 0.34,
              height: d * 0.2,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: unlocked ? 0.45 : 0.6),
                borderRadius: BorderRadius.circular(d),
              ),
            ),
          ),
          Text(
            '$level',
            style: TextStyle(
              fontSize: d * 0.46,
              height: 1,
              fontWeight: FontWeight.w900,
              color: unlocked ? Colors.white : const Color(0xFFA39A92),
              shadows: unlocked
                  ? [
                      Shadow(
                        color: Color.lerp(base, Colors.black, 0.45)!,
                        offset: Offset(0, d * 0.035),
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
    final island = SizedBox(
      width: size * 1.16,
      height: size * 0.62,
      child: Opacity(
        opacity: unlocked ? 1 : 0.7,
        child: const GameImage(
          'assets/images/ui/level_stop.png',
          fallback: CustomPaint(painter: _IslandPainter()),
        ),
      ),
    );

    return Pressable(
      onTap: !paid
          ? () => _openPaywall(context)
          : unlocked
          ? () {
              GameShell.dailyRun = false;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => game.builder(game, level),
                ),
              );
            }
          : null,
      child: SizedBox(
        width: size,
        height: size * 1.32,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(top: size * 0.6, child: island),
            isCurrent ? Glow(child: button) : button,
            if (!unlocked)
              Positioned(
                right: -size * 0.02,
                top: -size * 0.06,
                width: size * 0.42,
                height: size * 0.42,
                child: const GameImage(
                  'assets/images/ui/lock.png',
                  fallback: FittedBox(
                    child: Icon(Icons.lock_rounded, color: AppColors.orange),
                  ),
                ),
              ),
            if (stars > 0)
              Positioned(
                top: size * 0.8,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size * 0.06,
                    vertical: 1,
                  ),
                  decoration: panelDecoration(radius: size),
                  child: StarsRow(stars, size: size * 0.27),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Durakların altındaki çimenli adacık (level_stop.png yoksa bu çizilir).
class _IslandPainter extends CustomPainter {
  const _IslandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Toprak: çimenin altından sarkan yuvarlak gövde.
    final soil = Path()
      ..moveTo(w * 0.06, h * 0.36)
      ..cubicTo(w * 0.1, h * 1.02, w * 0.9, h * 1.02, w * 0.94, h * 0.36)
      ..close();
    canvas.drawPath(soil, Paint()..color = const Color(0xFFA9703F));
    final soilShade = Path()
      ..moveTo(w * 0.3, h * 0.6)
      ..cubicTo(w * 0.36, h * 0.96, w * 0.82, h * 0.98, w * 0.94, h * 0.36)
      ..cubicTo(w * 0.86, h * 0.8, w * 0.5, h * 0.84, w * 0.3, h * 0.6)
      ..close();
    canvas.drawPath(soilShade, Paint()..color = const Color(0xFF8C5A30));
    // Çimen: üstte yassı bir oval, kenarı koyu, ortası açık.
    final grass = Rect.fromLTWH(0, 0, w, h * 0.66);
    canvas.drawOval(grass, Paint()..color = const Color(0xFF5DBB4A));
    canvas.drawOval(
      Rect.fromLTWH(w * 0.03, 0, w * 0.94, h * 0.56),
      Paint()..color = const Color(0xFF86DB5E),
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.14, h * 0.05, w * 0.5, h * 0.2),
      Paint()..color = const Color(0xFFA9EC7C),
    );
  }

  @override
  bool shouldRepaint(_IslandPainter old) => false;
}

Future<void> _openPaywall(BuildContext context) async {
  final navigator = Navigator.of(context);
  if (await showParentGate(context)) {
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
    );
  }
}

/// Bölümleri birbirine bağlayan beyaz noktalı yol.
class _PathPainter extends CustomPainter {
  _PathPainter(this.points, this.dot);
  final List<Offset> points;
  final double dot;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final midX = (a.dx + b.dx) / 2;
      path.cubicTo(midX, a.dy, midX, b.dy, b.dx, b.dy);
    }
    final shadow = Paint()..color = AppColors.ink.withValues(alpha: 0.18);
    final white = Paint()..color = Colors.white;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dot * 1.9) {
        final p = metric.getTangentForOffset(d)!.position;
        canvas.drawCircle(p + Offset(0, dot * 0.2), dot / 2, shadow);
        canvas.drawCircle(p, dot / 2, white);
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.dot != dot || old.points.length != points.length;
}
