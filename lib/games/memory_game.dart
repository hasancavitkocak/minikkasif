import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/objects.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';

/// Hafıza kartları: aynı iki kartı bul.
class MemoryGame extends StatelessWidget {
  const MemoryGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  static const _pairsByLevel = [2, 3, 3, 4, 4, 5, 6, 6, 8, 10];

  @override
  Widget build(BuildContext context) {
    final pairs = _pairsByLevel[(level - 1).clamp(0, _pairsByLevel.length - 1)];
    return GameShell(
      game: game,
      level: level,
      rounds: 1,
      tolerance: pairs,
      background: 'sea',
      instruction: (_) => L.t('i_memory'),
      roundBuilder: (round, onSolved, onMistake) => _MemoryRound(
        pairs: pairs,
        // İlk bölümlerde kartlar kısa süre açık gösterilir.
        preview: level <= 3,
        onSolved: onSolved,
        onMistake: onMistake,
      ),
    );
  }
}

class _MemoryRound extends StatefulWidget {
  const _MemoryRound({
    required this.pairs,
    required this.preview,
    required this.onSolved,
    required this.onMistake,
  });
  final int pairs;
  final bool preview;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_MemoryRound> createState() => _MemoryRoundState();
}

class _MemoryRoundState extends State<_MemoryRound> {
  late final List<GameObject> _cards;
  final Set<int> _open = {};
  final Set<int> _matched = {};
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final picked = pickObjects(rng, widget.pairs);
    _cards = [...picked, ...picked]..shuffle(rng);
    if (widget.preview) {
      _busy = true;
      _open.addAll(List.generate(_cards.length, (i) => i));
      _timer = Timer(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        setState(() {
          _open.clear();
          _busy = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tap(int i) {
    if (_busy || _open.contains(i) || _matched.contains(i)) return;
    Sfx.play('pop');
    setState(() => _open.add(i));
    if (_open.length < 2) return;

    final pair = _open.toList();
    if (_cards[pair[0]].id == _cards[pair[1]].id) {
      setState(() {
        _matched.addAll(pair);
        _open.clear();
      });
      if (_matched.length == _cards.length) widget.onSolved();
    } else {
      _busy = true;
      widget.onMistake();
      _timer = Timer(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        setState(() {
          _open.clear();
          _busy = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _cards.length;
    final cols = total <= 16 ? total ~/ 2 : 7;
    final rows = (total / cols).ceil();
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 10.0;
        final size = min(
          (box.maxWidth - gap * (cols - 1)) / cols,
          (box.maxHeight - gap * (rows - 1)) / rows,
        );
        return Center(
          child: SizedBox(
            width: cols * size + gap * (cols - 1),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < total; i++)
                  GestureDetector(
                    onTap: () => _tap(i),
                    child: AnimatedOpacity(
                      opacity: _matched.contains(i) ? 0.55 : 1,
                      duration: const Duration(milliseconds: 300),
                      child: _FlipCard(
                        size: size,
                        faceUp: _open.contains(i) || _matched.contains(i),
                        object: _cards[i],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({
    required this.size,
    required this.faceUp,
    required this.object,
  });
  final double size;
  final bool faceUp;
  final GameObject object;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.18;
    // Kart arkası: beyaz çerçeve kodla çizilir, içi desen görseliyle dolar.
    final back = Container(
      clipBehavior: Clip.antiAlias,
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white, width: size * 0.05),
      ),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox.expand(
        child: GameImage(
          'assets/images/ui/card_back.png',
          fit: BoxFit.cover,
          fallback: Center(
            child: Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
    final front = Container(
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.yellow, width: size * 0.04),
      ),
      child: ObjectImage(object),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(end: faceUp ? 1 : 0),
      duration: const Duration(milliseconds: 280),
      builder: (context, v, _) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(pi * v),
        child: SizedBox(
          width: size,
          height: size,
          child: v < 0.5
              ? back
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(pi),
                  child: front,
                ),
        ),
      ),
    );
  }
}
