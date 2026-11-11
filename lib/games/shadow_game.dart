import 'dart:math';

import 'package:flutter/material.dart';

import '../data/objects.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';

/// Gölgesini bul: gölgenin sahibini (ileri bölümlerde nesnenin gölgesini) seç.
class ShadowGame extends StatelessWidget {
  const ShadowGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  /// İleri bölümlerde tek numaralı turlar tersine oynanır.
  bool _reversed(int round) => level >= 5 && round.isOdd;

  @override
  Widget build(BuildContext context) {
    return GameShell(
      game: game,
      level: level,
      rounds: 5,
      instruction: (round) =>
          L.t(_reversed(round) ? 'i_shadow_rev' : 'i_shadow'),
      roundBuilder: (round, onSolved, onMistake) => _ShadowRound(
        level: level,
        reversed: _reversed(round),
        onSolved: onSolved,
        onMistake: onMistake,
      ),
    );
  }
}

class _ShadowRound extends StatefulWidget {
  const _ShadowRound({
    required this.level,
    required this.reversed,
    required this.onSolved,
    required this.onMistake,
  });
  final int level;
  final bool reversed;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_ShadowRound> createState() => _ShadowRoundState();
}

class _ShadowRoundState extends State<_ShadowRound> {
  late final List<GameObject> _options;
  late final GameObject _answer;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final level = widget.level;
    final count = level <= 2
        ? 2
        : level <= 6
        ? 3
        : 4;
    // Aynı kategoriden seçenekler birbirine daha çok benzer, yani daha zordur.
    final picked = pickObjects(
      rng,
      count,
      category: level >= 4 ? rng.nextInt(3) : null,
    );
    // İlk nesne yakın zamanda sorulmamış olandır (bkz. pickObjects).
    _answer = picked.first;
    _options = [...picked]..shuffle(rng);
  }

  bool _pick(GameObject object) {
    if (object.id != _answer.id) {
      widget.onMistake();
      return false;
    }
    setState(() => _solved = true);
    widget.onSolved();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final reversed = widget.reversed;
    return LayoutBuilder(
      builder: (context, box) {
        final targetSize = box.maxHeight * 0.44;
        final optionSize = min(
          box.maxHeight * 0.4,
          box.maxWidth / (_options.length + 1),
        );
        // Soruda gölge gösterilir; doğru cevapta gölge renklenir.
        final showColor = reversed || _solved;
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: targetSize,
              height: targetSize,
              padding: EdgeInsets.all(targetSize * 0.1),
              decoration: panelDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                radius: targetSize * 0.25,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: KeyedSubtree(
                  key: ValueKey(showColor),
                  child: showColor
                      ? ObjectImage(_answer)
                      : ObjectShadow(_answer),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final object in _options)
                  ChoiceTile(
                    size: optionSize,
                    onTap: () => _pick(object),
                    child: reversed
                        ? ObjectShadow(object)
                        : ObjectImage(object),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
