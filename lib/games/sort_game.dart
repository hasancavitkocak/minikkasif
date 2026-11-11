import 'dart:math';

import 'package:flutter/material.dart';

import '../data/objects.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';

/// Sıralama: nesnelere küçükten büyüğe (ileri bölümlerde büyükten küçüğe)
/// sırayla dokun.
class SortGame extends StatelessWidget {
  const SortGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  bool _descending(int round) => level >= 5 && round.isOdd;

  @override
  Widget build(BuildContext context) {
    return GameShell(
      game: game,
      level: level,
      rounds: 4,
      instruction: (round) =>
          L.t(_descending(round) ? 'i_sort_desc' : 'i_sort_asc'),
      roundBuilder: (round, onSolved, onMistake) => _SortRound(
        level: level,
        descending: _descending(round),
        onSolved: onSolved,
        onMistake: onMistake,
      ),
    );
  }
}

class _SortRound extends StatefulWidget {
  const _SortRound({
    required this.level,
    required this.descending,
    required this.onSolved,
    required this.onMistake,
  });
  final int level;
  final bool descending;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_SortRound> createState() => _SortRoundState();
}

class _SortRoundState extends State<_SortRound> {
  late final GameObject _object;

  /// Ekrandaki sırayla her nesnenin büyüklük sırası (0 en küçük).
  late final List<int> _ranks;
  final List<int> _tapped = [];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final level = widget.level;
    final count = level <= 3
        ? 3
        : level <= 6
        ? 4
        : 5;
    _object = pickObjects(rng, 1).first;
    _ranks = List.generate(count, (i) => i);
    // Zaten sıralı gelmesin.
    do {
      _ranks.shuffle(rng);
    } while (_isSorted(_ranks));
  }

  bool _isSorted(List<int> list) {
    var asc = true;
    var desc = true;
    for (var i = 1; i < list.length; i++) {
      if (list[i] < list[i - 1]) asc = false;
      if (list[i] > list[i - 1]) desc = false;
    }
    return asc || desc;
  }

  bool _tap(int rank) {
    if (_tapped.contains(rank)) return true;
    final n = _ranks.length;
    final expected = widget.descending
        ? n - 1 - _tapped.length
        : _tapped.length;
    if (rank != expected) {
      widget.onMistake();
      return false;
    }
    setState(() => _tapped.add(rank));
    if (_tapped.length == n) {
      widget.onSolved();
    } else {
      Sfx.play('pop');
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final n = _ranks.length;
    return LayoutBuilder(
      builder: (context, box) {
        final maxSize = min(
          box.maxHeight * 0.85,
          box.maxWidth / (n * 0.8 + 0.6),
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final rank in _ranks)
              _item(rank, maxSize * (0.4 + 0.6 * rank / (n - 1))),
          ],
        );
      },
    );
  }

  Widget _item(int rank, double size) {
    final order = _tapped.indexOf(rank);
    final done = order >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ChoiceTile(
            size: size,
            color: done ? const Color(0xFFDFF7E6) : Colors.white,
            onTap: () => _tap(rank),
            child: ObjectImage(_object),
          ),
          if (done)
            Positioned(
              top: -10,
              right: -10,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Text(
                  '${order + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
