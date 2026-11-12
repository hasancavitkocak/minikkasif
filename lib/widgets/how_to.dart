import 'dart:math';

import 'package:flutter/material.dart';

import '../data/jobs.dart';
import '../data/objects.dart';
import '../data/seasons.dart';
import '../games/clock_game.dart';
import '../games/game_def.dart';
import '../games/puzzle_game.dart';
import '../games/shapes_game.dart';
import '../l10n.dart';
import '../theme.dart';
import 'common.dart';
import 'ui.dart';

/// "Nasıl oynanır" penceresi: maskot yönergeyi söyler, altında bir el
/// oyunun nasıl oynandığını canlandırarak gösterir.
Future<void> showHowTo(BuildContext context, GameDef game, String instruction) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.45),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: FittedBox(
        child: SizedBox(
          width: 560,
          child: ToyPanel(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 84,
                      height: 84,
                      child: Mascot('thinking'),
                    ),
                    Expanded(
                      child: SpeechBubble(
                        child: Text(
                          instruction,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle.copyWith(fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    color: game.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: game.color.withValues(alpha: 0.5),
                      width: 3,
                    ),
                  ),
                  // Canlandırma her dilde soldan sağa oynar.
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: demoFor(game.id),
                  ),
                ),
                const SizedBox(height: 12),
                Bobbing(
                  distance: 0,
                  pulse: 0.05,
                  child: BigButton(
                    label: L.t('start'),
                    icon: Icons.play_arrow_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Canlandırma sahnesindeki bir öğe.
class DemoItem {
  const DemoItem(this.id, this.at, this.size, this.child, {this.tapped});
  final String id;

  /// Sahne içindeki yeri (-1..1).
  final Alignment at;

  /// Sahne yüksekliğine oranla boyutu.
  final double size;
  final Widget child;

  /// Dokunulduktan sonra gösterilecek hali (ör. açılan kart).
  final Widget? tapped;
}

/// Elin yaptığı bir hareket: [to] verilirse sürükleme, yoksa dokunma.
class DemoStep {
  const DemoStep.tap(this.id) : to = null;
  const DemoStep.drag(this.id, Alignment this.to);
  final String id;
  final Alignment? to;
}

/// Bir elin [steps] hareketlerini sırayla yapıp başa döndüğü küçük sahne.
class DemoScene extends StatefulWidget {
  const DemoScene({super.key, required this.items, required this.steps});
  final List<DemoItem> items;
  final List<DemoStep> steps;

  @override
  State<DemoScene> createState() => _DemoSceneState();
}

class _DemoSceneState extends State<DemoScene>
    with SingleTickerProviderStateMixin {
  static const _stepMs = 1500;
  static const _holdMs = 1100;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.steps.length * _stepMs + _holdMs),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _frame(box.biggest),
      ),
    );
  }

  Widget _frame(Size scene) {
    Offset pos(Alignment a) =>
        Offset((a.x + 1) / 2 * scene.width, (a.y + 1) / 2 * scene.height);

    final steps = widget.steps;
    final ms = _controller.value * (steps.length * _stepMs + _holdMs);
    final index = min(ms ~/ _stepMs, steps.length);
    final local = index < steps.length ? (ms - index * _stepMs) / _stepMs : 1.0;

    final centers = {for (final item in widget.items) item.id: pos(item.at)};
    final tapped = <String>{};
    // Tamamlanan adımların sonucunu uygula.
    var hand = Offset(scene.width / 2, scene.height * 1.15);
    for (var i = 0; i < index; i++) {
      final step = steps[i];
      if (step.to == null) {
        tapped.add(step.id);
      } else {
        centers[step.id] = pos(step.to!);
      }
      hand = centers[step.id]!;
    }
    // Süren adım: önce el öğeye gider, sonra dokunur ya da sürükler.
    var pressing = false;
    if (index < steps.length) {
      final step = steps[index];
      final from = centers[step.id]!;
      final reach = Curves.easeInOut.transform((local / 0.45).clamp(0.0, 1.0));
      hand = Offset.lerp(hand, from, reach)!;
      if (local > 0.45) {
        pressing = local < 0.9;
        if (step.to == null) {
          if (local > 0.6) tapped.add(step.id);
        } else {
          final move = Curves.easeInOut.transform(
            ((local - 0.5) / 0.4).clamp(0.0, 1.0),
          );
          centers[step.id] = Offset.lerp(from, pos(step.to!), move)!;
          hand = centers[step.id]!;
        }
      }
    }

    final handSize = scene.height * 0.34;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final item in widget.items)
          Positioned(
            left: centers[item.id]!.dx - item.size * scene.height / 2,
            top: centers[item.id]!.dy - item.size * scene.height / 2,
            width: item.size * scene.height,
            height: item.size * scene.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  item.size * scene.height * 0.24,
                ),
                boxShadow: tapped.contains(item.id)
                    ? const [BoxShadow(color: AppColors.green, spreadRadius: 5)]
                    : null,
              ),
              child: tapped.contains(item.id)
                  ? item.tapped ?? item.child
                  : item.child,
            ),
          ),
        // Parmak ucu hedefin tam üstüne gelecek şekilde konumlanır.
        Positioned(
          left: hand.dx - handSize * 0.42,
          top: hand.dy - handSize * 0.08,
          child: Transform.scale(
            scale: pressing ? 0.85 : 1,
            child: Icon(
              Icons.touch_app_rounded,
              size: handSize,
              color: AppColors.ink,
              shadows: const [
                Shadow(color: Colors.white, blurRadius: 3),
                Shadow(color: Colors.white, blurRadius: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

GameObject _object(String id) => gameObjects.firstWhere((o) => o.id == id);

Widget _tile(Widget child, {Color color = Colors.white}) {
  return Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.18),
          blurRadius: 4,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

Widget _objectTile(String id) => _tile(ObjectImage(_object(id)));

Widget _numberTile(String text, Color color) {
  return _tile(
    color: color,
    FittedBox(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 40,
        ),
      ),
    ),
  );
}

Widget _shape(ShapeKind kind, Color color, {bool ghost = false}) {
  return CustomPaint(painter: ShapePainter(kind, color, ghost: ghost));
}

Widget _cardBack() {
  return _tile(
    color: AppColors.blue,
    const FittedBox(child: Icon(Icons.star_rounded, color: Colors.white)),
  );
}

/// Her mini oyun için kısa bir oynanış canlandırması.
Widget demoFor(String gameId) {
  switch (gameId) {
    case 'shapes':
      const redSlot = Alignment(-0.45, -0.45);
      const blueSlot = Alignment(0.45, -0.45);
      return DemoScene(
        items: [
          DemoItem(
            'ghostRed',
            redSlot,
            0.42,
            _shape(ShapeKind.circle, AppColors.red, ghost: true),
          ),
          DemoItem(
            'ghostBlue',
            blueSlot,
            0.42,
            _shape(ShapeKind.square, AppColors.blue, ghost: true),
          ),
          DemoItem(
            'blue',
            const Alignment(-0.45, 0.55),
            0.36,
            _shape(ShapeKind.square, AppColors.blue),
          ),
          DemoItem(
            'red',
            const Alignment(0.45, 0.55),
            0.36,
            _shape(ShapeKind.circle, AppColors.red),
          ),
        ],
        steps: const [
          DemoStep.drag('red', redSlot),
          DemoStep.drag('blue', blueSlot),
        ],
      );
    case 'memory':
      return DemoScene(
        items: [
          DemoItem(
            'a',
            const Alignment(-0.72, 0),
            0.5,
            _cardBack(),
            tapped: _objectTile('apple'),
          ),
          DemoItem(
            'b',
            const Alignment(-0.24, 0),
            0.5,
            _cardBack(),
            tapped: _objectTile('cat'),
          ),
          DemoItem(
            'c',
            const Alignment(0.24, 0),
            0.5,
            _cardBack(),
            tapped: _objectTile('apple'),
          ),
          DemoItem(
            'd',
            const Alignment(0.72, 0),
            0.5,
            _cardBack(),
            tapped: _objectTile('cat'),
          ),
        ],
        steps: const [DemoStep.tap('a'), DemoStep.tap('c')],
      );
    case 'shadow':
      return DemoScene(
        items: [
          DemoItem(
            'shadow',
            const Alignment(0, -0.5),
            0.44,
            _tile(ObjectShadow(_object('cat'))),
          ),
          DemoItem(
            'apple',
            const Alignment(-0.45, 0.55),
            0.4,
            _objectTile('apple'),
          ),
          DemoItem('cat', const Alignment(0.45, 0.55), 0.4, _objectTile('cat')),
        ],
        steps: const [DemoStep.tap('cat')],
      );
    case 'count':
      return DemoScene(
        items: [
          for (var i = 0; i < 3; i++)
            DemoItem(
              'o$i',
              Alignment(-0.4 + i * 0.4, -0.5),
              0.36,
              ObjectImage(_object('apple')),
            ),
          DemoItem(
            'two',
            const Alignment(-0.35, 0.55),
            0.4,
            _numberTile('2', AppColors.pink),
          ),
          DemoItem(
            'three',
            const Alignment(0.35, 0.55),
            0.4,
            _numberTile('3', AppColors.blue),
          ),
        ],
        steps: const [DemoStep.tap('three')],
      );
    case 'pattern':
      return DemoScene(
        items: [
          for (var i = 0; i < 5; i++)
            DemoItem(
              's$i',
              Alignment(-0.8 + i * 0.32, -0.5),
              0.32,
              ObjectImage(_object(i.isEven ? 'apple' : 'banana')),
            ),
          DemoItem(
            'q',
            const Alignment(0.8, -0.5),
            0.34,
            _numberTile('?', AppColors.orange),
          ),
          DemoItem(
            'apple',
            const Alignment(-0.35, 0.55),
            0.4,
            _objectTile('apple'),
          ),
          DemoItem(
            'banana',
            const Alignment(0.35, 0.55),
            0.4,
            _objectTile('banana'),
          ),
        ],
        steps: const [DemoStep.tap('banana')],
      );
    case 'odd':
      return DemoScene(
        items: [
          for (final (i, id) in ['apple', 'apple', 'cat', 'apple'].indexed)
            DemoItem(
              'i$i',
              Alignment(-0.72 + i * 0.48, 0),
              0.48,
              _objectTile(id),
            ),
        ],
        steps: const [DemoStep.tap('i2')],
      );
    case 'puzzle':
      const slot = Alignment(-0.35, 0);
      return DemoScene(
        items: [
          DemoItem(
            'slot',
            slot,
            0.62,
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.ink.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
            ),
          ),
          DemoItem(
            'piece',
            const Alignment(0.55, 0.3),
            0.62,
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const PuzzlePicture(0),
            ),
          ),
        ],
        steps: const [DemoStep.drag('piece', slot)],
      );
    case 'maze':
      const goal = Alignment(0.6, 0);
      return DemoScene(
        items: [
          DemoItem('food', goal, 0.44, ObjectImage(_object('apple'))),
          const DemoItem('fox', Alignment(-0.6, 0), 0.5, Mascot('hello')),
        ],
        steps: const [DemoStep.drag('fox', goal)],
      );
    case 'color':
      return DemoScene(
        items: [
          DemoItem(
            'red',
            const Alignment(-0.6, -0.45),
            0.34,
            _shape(ShapeKind.circle, AppColors.red),
          ),
          DemoItem(
            'blue',
            const Alignment(-0.6, 0.45),
            0.34,
            _shape(ShapeKind.circle, AppColors.blue),
          ),
          DemoItem(
            'picture',
            const Alignment(0.4, 0),
            0.7,
            _shape(ShapeKind.heart, AppColors.grey, ghost: true),
            tapped: _shape(ShapeKind.heart, AppColors.red),
          ),
        ],
        steps: const [DemoStep.tap('red'), DemoStep.tap('picture')],
      );
    case 'groups':
      const animals = Alignment(-0.5, 0.5);
      const fruits = Alignment(0.5, 0.5);
      return DemoScene(
        items: [
          DemoItem(
            'animals',
            animals,
            0.5,
            _tile(ObjectImage(_object('cat')), color: const Color(0xFFFFD9D9)),
          ),
          DemoItem(
            'fruits',
            fruits,
            0.5,
            _tile(
              ObjectImage(_object('apple')),
              color: const Color(0xFFD9ECFF),
            ),
          ),
          DemoItem(
            'dog',
            const Alignment(-0.25, -0.55),
            0.34,
            ObjectImage(_object('dog')),
          ),
          DemoItem(
            'banana',
            const Alignment(0.25, -0.55),
            0.34,
            ObjectImage(_object('banana')),
          ),
        ],
        steps: const [
          DemoStep.drag('dog', animals),
          DemoStep.drag('banana', fruits),
        ],
      );
    case 'simon':
      const colors = [
        AppColors.red,
        AppColors.yellow,
        AppColors.green,
        AppColors.blue,
      ];
      const animals = ['frog', 'bird', 'cat', 'dog'];
      return DemoScene(
        items: [
          for (var i = 0; i < 4; i++)
            DemoItem(
              'p$i',
              Alignment(-0.72 + i * 0.48, 0),
              0.5,
              _tile(ObjectImage(_object(animals[i])), color: colors[i]),
            ),
        ],
        steps: const [
          DemoStep.tap('p0'),
          DemoStep.tap('p2'),
          DemoStep.tap('p1'),
        ],
      );
    case 'diff':
      return DemoScene(
        items: [
          DemoItem('l0', const Alignment(-0.78, 0), 0.42, _objectTile('apple')),
          DemoItem('l1', const Alignment(-0.34, 0), 0.42, _objectTile('cat')),
          DemoItem('r0', const Alignment(0.34, 0), 0.42, _objectTile('apple')),
          DemoItem('r1', const Alignment(0.78, 0), 0.42, _objectTile('dog')),
        ],
        steps: const [DemoStep.tap('r1')],
      );
    case 'sort':
      return DemoScene(
        items: [
          DemoItem('mid', const Alignment(-0.6, 0.1), 0.5, _objectTile('star')),
          DemoItem(
            'small',
            const Alignment(-0.05, 0.3),
            0.32,
            _objectTile('star'),
          ),
          DemoItem(
            'big',
            const Alignment(0.58, -0.05),
            0.68,
            _objectTile('star'),
          ),
        ],
        steps: const [
          DemoStep.tap('small'),
          DemoStep.tap('mid'),
          DemoStep.tap('big'),
        ],
      );
    case 'jobs':
    case 'seasons':
      // İlk bölüm tanıtımdır: resme bakılır, ok ile sonrakine geçilir.
      final jobsDemo = gameId == 'jobs';
      return DemoScene(
        items: [
          DemoItem(
            'picture',
            const Alignment(-0.55, 0),
            0.8,
            _tile(ObjectImage(jobsDemo ? jobs[0].person : seasons[3])),
          ),
          DemoItem(
            'extra',
            // Mevsimlerde Fıstık, resmin köşesinde büyükçe durur (oyundaki gibi).
            jobsDemo ? const Alignment(0.1, 0.45) : const Alignment(-0.1, 0.4),
            jobsDemo ? 0.36 : 0.62,
            jobsDemo
                ? _tile(ObjectImage(jobs[0].tool))
                : ObjectImage(seasonOutfits[3]),
          ),
          DemoItem(
            'next',
            const Alignment(0.72, 0),
            0.4,
            _tile(
              const FittedBox(
                child: Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ),
              color: AppColors.green,
            ),
          ),
        ],
        steps: const [DemoStep.tap('next')],
      );
    case 'clock':
      // İlk bölümler: şekilli sayı parçası sürüklenip oyuğuna bırakılır.
      const hole = Alignment(-0.45, -0.1);
      return DemoScene(
        items: [
          DemoItem(
            'hole',
            hole,
            0.62,
            LayoutBuilder(
              builder: (context, box) =>
                  ClockPiece(1, size: box.maxWidth, ghost: true),
            ),
          ),
          DemoItem(
            'piece',
            const Alignment(0.5, 0.35),
            0.5,
            LayoutBuilder(
              builder: (context, box) => ClockPiece(1, size: box.maxWidth),
            ),
          ),
        ],
        steps: const [DemoStep.drag('piece', hole)],
      );
    case 'letters':
      return DemoScene(
        items: [
          DemoItem(
            'ask',
            const Alignment(0, -0.6),
            0.42,
            _numberTile('A', AppColors.blue),
          ),
          DemoItem(
            'b',
            const Alignment(-0.45, 0.55),
            0.42,
            _numberTile('B', AppColors.orange),
          ),
          DemoItem(
            'a',
            const Alignment(0.45, 0.55),
            0.42,
            _numberTile('A', AppColors.blue),
          ),
        ],
        steps: const [DemoStep.tap('a')],
      );
    case 'dots':
      return DemoScene(
        items: [
          DemoItem(
            'one',
            const Alignment(-0.55, 0.45),
            0.36,
            _numberTile('1', AppColors.green),
          ),
          DemoItem(
            'two',
            const Alignment(0, -0.5),
            0.36,
            _numberTile('2', AppColors.orange),
          ),
          DemoItem(
            'three',
            const Alignment(0.55, 0.45),
            0.36,
            _numberTile('3', AppColors.blue),
          ),
        ],
        steps: const [
          DemoStep.tap('one'),
          DemoStep.tap('two'),
          DemoStep.tap('three'),
        ],
      );
  }
  return const SizedBox.shrink();
}
