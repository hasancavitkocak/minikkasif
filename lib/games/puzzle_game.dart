import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';

/// Yapboz: parçaları sürükleyip resimdeki yerine bırak.
class PuzzleGame extends StatelessWidget {
  const PuzzleGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  @override
  Widget build(BuildContext context) {
    final (cols, rows) = level <= 2
        ? (2, 2)
        : level <= 5
        ? (3, 2)
        : level <= 8
        ? (3, 3)
        : (4, 3);
    return GameShell(
      game: game,
      level: level,
      rounds: 1,
      tolerance: cols * rows ~/ 2,
      instruction: (_) => L.t('i_puzzle'),
      roundBuilder: (round, onSolved, onMistake) => _PuzzleRound(
        picture: (level - 1) % PuzzlePicture.count,
        cols: cols,
        rows: rows,
        // İlk bölümlerde resmin soluk hali ipucu olarak görünür.
        hint: level <= 5,
        onSolved: onSolved,
        onMistake: onMistake,
      ),
    );
  }
}

class _PuzzleRound extends StatefulWidget {
  const _PuzzleRound({
    required this.picture,
    required this.cols,
    required this.rows,
    required this.hint,
    required this.onSolved,
    required this.onMistake,
  });
  final int picture;
  final int cols;
  final int rows;
  final bool hint;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_PuzzleRound> createState() => _PuzzleRoundState();
}

class _PuzzleRoundState extends State<_PuzzleRound> {
  late final List<int> _tray;
  final Set<int> _placed = {};

  int get _count => widget.cols * widget.rows;

  @override
  void initState() {
    super.initState();
    _tray = List.generate(_count, (i) => i)..shuffle(Random());
  }

  void _drop(int slot, int piece) {
    if (slot != piece) {
      widget.onMistake();
      return;
    }
    setState(() => _placed.add(slot));
    if (_placed.length == _count) {
      widget.onSolved();
    } else {
      Sfx.play('pop');
    }
  }

  /// Resmin [index] numaralı parçası; [board] resmin tam kenar uzunluğudur.
  Widget _piece(int index, double board) {
    final cols = widget.cols;
    final rows = widget.rows;
    final col = index % cols;
    final row = index ~/ cols;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: board / cols,
        height: board / rows,
        child: OverflowBox(
          maxWidth: board,
          maxHeight: board,
          minWidth: board,
          minHeight: board,
          alignment: Alignment(
            -1 + 2 * col / (cols - 1),
            -1 + 2 * row / (rows - 1),
          ),
          child: PuzzlePicture(widget.picture),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cols = widget.cols;
    final rows = widget.rows;
    return LayoutBuilder(
      builder: (context, box) {
        final board = min(box.maxHeight, box.maxWidth * 0.52);
        final trayWidth = box.maxWidth - board - 20;
        // İpucu olmayan bölümlerde resmin bitmiş hali küçük bir örnek olarak
        // görünür; çocuk parçaları ona bakarak yerleştirir.
        final reference = widget.hint ? 0.0 : min(box.maxHeight * 0.38, 170.0);
        // Tepsideki parçalar, hepsi sığacak kadar küçültülür.
        final scale = min(
          1.0,
          sqrt(trayWidth * (box.maxHeight - reference) * 0.5 / (board * board)),
        );
        return Row(
          children: [
            Container(
              width: board,
              height: board,
              decoration: panelDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                radius: 12,
              ),
              child: Stack(
                children: [
                  if (widget.hint)
                    Opacity(
                      opacity: 0.22,
                      child: PuzzlePicture(widget.picture),
                    ),
                  for (var i = 0; i < _count; i++)
                    Positioned(
                      left: (i % cols) * board / cols,
                      top: (i ~/ cols) * board / rows,
                      width: board / cols,
                      height: board / rows,
                      child: DragTarget<int>(
                        onWillAcceptWithDetails: (_) => !_placed.contains(i),
                        onAcceptWithDetails: (details) =>
                            _drop(i, details.data),
                        builder: (context, candidates, _) => _placed.contains(i)
                            ? _piece(i, board)
                            : Container(
                                decoration: BoxDecoration(
                                  color: candidates.isNotEmpty
                                      ? AppColors.yellow.withValues(alpha: 0.45)
                                      : null,
                                  border: Border.all(
                                    color: AppColors.ink.withValues(
                                      alpha: 0.25,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  if (!widget.hint)
                    Container(
                      width: reference - 10,
                      height: reference - 10,
                      margin: const EdgeInsets.only(bottom: 10),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: PuzzlePicture(widget.picture),
                    ),
                  Expanded(
                    child: Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final i in _tray)
                            if (!_placed.contains(i))
                              Draggable<int>(
                                data: i,
                                feedback: _piece(i, board),
                                childWhenDragging: Opacity(
                                  opacity: 0.2,
                                  child: _piece(i, board * scale),
                                ),
                                child: _piece(i, board * scale),
                              ),
                        ],
                      ),
                    ),
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

/// Yapboz resmi. assets/images/puzzle/ altındaki görsel yoksa emojilerden
/// oluşan geçici bir sahne çizilir.
class PuzzlePicture extends StatelessWidget {
  const PuzzlePicture(this.index, {super.key});
  final int index;

  static const count = 4;

  static const _names = ['farm', 'sea', 'jungle', 'space'];
  static const _colors = [
    [Color(0xFF9EDBFF), Color(0xFF9BE08A)],
    [Color(0xFF7FD6F2), Color(0xFF3F8FD9)],
    [Color(0xFFC9F0A0), Color(0xFF4FB06A)],
    [Color(0xFF4B3F9E), Color(0xFF1F1B4D)],
  ];
  static const _emojis = [
    ['☀️', '🏠', '🐄', '🚜', '🌻', '🐔', '🌳', '🐑', '🦆'],
    ['🐳', '🐙', '⭐', '🦀', '🪸', '🐠', '🐢', '🐚', '🐬'],
    ['🐒', '🦜', '🦒', '🐘', '🌺', '🌴', '🐯', '🦋', '🐍'],
    ['🚀', '🌕', '🪐', '☀️', '⭐', '🧑‍🚀', '🌍', '☄️', '🌟'],
  ];

  @override
  Widget build(BuildContext context) {
    final i = index % count;
    return SizedBox.expand(
      child: GameImage(
        'assets/images/puzzle/puzzle_${_names[i]}.png',
        fit: BoxFit.cover,
        fallback: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _colors[i],
            ),
          ),
          // 3x3 düzen: her bölgede farklı bir şey olur, parçalar ayırt edilir.
          child: Column(
            children: [
              for (var r = 0; r < 3; r++)
                Expanded(
                  child: Row(
                    children: [
                      for (var c = 0; c < 3; c++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: SizedBox.expand(
                              child: Emoji(_emojis[i][r * 3 + c]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
