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

/// Ses hafızası: hayvanların çaldığı sırayı dinle, aynı sırayla dokun.
class SimonGame extends StatelessWidget {
  const SimonGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  @override
  Widget build(BuildContext context) {
    return GameShell(
      game: game,
      level: level,
      rounds: 3,
      tolerance: 2,
      background: 'space',
      instruction: (_) => L.t('i_simon'),
      roundBuilder: (round, onSolved, onMistake) => _SimonRound(
        length: 2 + (level - 1) ~/ 2 + (round == 2 && level > 1 ? 1 : 0),
        stepMs: max(450, 800 - level * 35),
        onSolved: onSolved,
        onMistake: onMistake,
      ),
    );
  }
}

class _SimonRound extends StatefulWidget {
  const _SimonRound({
    required this.length,
    required this.stepMs,
    required this.onSolved,
    required this.onMistake,
  });
  final int length;
  final int stepMs;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_SimonRound> createState() => _SimonRoundState();
}

class _SimonRoundState extends State<_SimonRound> {
  static const _colors = [
    AppColors.red,
    AppColors.yellow,
    AppColors.green,
    AppColors.blue,
  ];
  static const _animals = ['frog', 'bird', 'cat', 'dog'];

  late final List<int> _sequence;
  final List<Timer> _timers = [];
  int _position = 0;
  int? _lit;
  bool _showing = true;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _sequence = [for (var i = 0; i < widget.length; i++) rng.nextInt(4)];
    _playSequence(900);
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _after(int ms, VoidCallback action) {
    _timers.add(
      Timer(Duration(milliseconds: ms), () {
        if (mounted) action();
      }),
    );
  }

  void _light(int pad) {
    Sfx.play('note${pad + 1}');
    setState(() => _lit = pad);
  }

  /// Sırayı çalar; bu sırada tuşlar dokunmaya kapalıdır.
  void _playSequence(int delay) {
    _showing = true;
    _position = 0;
    final step = widget.stepMs;
    for (var i = 0; i < _sequence.length; i++) {
      _after(delay + i * step, () => _light(_sequence[i]));
      _after(
        delay + i * step + (step * 0.65).round(),
        () => setState(() => _lit = null),
      );
    }
    _after(
      delay + _sequence.length * step,
      () => setState(() => _showing = false),
    );
  }

  void _tap(int pad) {
    if (_showing || _done) return;
    _light(pad);
    _after(250, () {
      if (_lit == pad) setState(() => _lit = null);
    });
    if (pad != _sequence[_position]) {
      widget.onMistake();
      setState(() => _showing = true);
      _playSequence(1200);
      return;
    }
    _position++;
    if (_position == _sequence.length) {
      _done = true;
      widget.onSolved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = min(box.maxHeight * 0.7, (box.maxWidth - 60) / 4);
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Kaçıncı notada olunduğunu gösteren noktalar.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showing ? Icons.hearing_rounded : Icons.touch_app_rounded,
                  color: AppColors.ink,
                  size: 30,
                ),
                const SizedBox(width: 10),
                for (var i = 0; i < _sequence.length; i++)
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: !_showing && i < _position
                          ? AppColors.green
                          : Colors.white,
                      border: Border.all(color: AppColors.ink, width: 2),
                    ),
                  ),
              ],
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [for (var pad = 0; pad < 4; pad++) _pad(pad, size)],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pad(int pad, double size) {
    final lit = _lit == pad;
    final color = _colors[pad];
    final animal = gameObjects.firstWhere((o) => o.id == _animals[pad]);
    return GestureDetector(
      onTapDown: (_) => _tap(pad),
      child: AnimatedScale(
        scale: lit ? 1.14 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.12),
          decoration: BoxDecoration(
            color: lit ? Color.lerp(color, Colors.white, 0.35) : color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: size * 0.06),
            boxShadow: [
              BoxShadow(
                color: lit ? color : AppColors.ink.withValues(alpha: 0.25),
                blurRadius: lit ? 30 : 8,
                spreadRadius: lit ? 8 : 0,
                offset: lit ? Offset.zero : const Offset(0, 5),
              ),
            ],
          ),
          child: Opacity(
            opacity: _showing && !lit ? 0.7 : 1,
            child: ObjectImage(animal),
          ),
        ),
      ),
    );
  }
}
