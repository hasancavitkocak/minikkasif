import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/objects.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

/// İki kişilik hafıza: iki oyuncu sırayla iki kart açar. Eşini bulan bir
/// puan alır ve bir kez daha oynar; en çok eş bulan kazanır.
class DuelScreen extends StatefulWidget {
  const DuelScreen({super.key});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  static const _pairs = 8;
  static const _playerColors = [AppColors.blue, AppColors.pink];

  late List<GameObject> _cards;
  final Set<int> _open = {};
  final Set<int> _matched = {};
  final List<int> _scores = [0, 0];
  int _turn = 0;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _deal();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Tts.speakKeys(['g_duel'], owner: this);
    });
  }

  @override
  void dispose() {
    Tts.stopFor(this);
    _timer?.cancel();
    super.dispose();
  }

  void _deal() {
    final rng = Random();
    objectWorld = 0;
    final picked = pickObjects(rng, _pairs);
    _cards = [...picked, ...picked]..shuffle(rng);
    _open.clear();
    _matched.clear();
    _scores[0] = _scores[1] = 0;
    _turn = 0;
    _busy = false;
  }

  bool get _over => _matched.length == _cards.length;

  void _tap(int i) {
    if (_busy || _open.contains(i) || _matched.contains(i)) return;
    Sfx.play('pop');
    setState(() => _open.add(i));
    if (_open.length < 2) return;
    final pair = _open.toList();
    _busy = true;
    if (_cards[pair[0]].id == _cards[pair[1]].id) {
      Sfx.play('correct');
      _timer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _matched.addAll(pair);
          _open.clear();
          _scores[_turn]++;
          _busy = false;
        });
        if (_over) {
          Sfx.play('win');
          Tts.speak(L.praise());
        }
      });
    } else {
      // Eş değilse kartlar kapanır, sıra öbür oyuncuya geçer.
      _timer = Timer(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        setState(() {
          _open.clear();
          _turn = 1 - _turn;
          _busy = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Backdrop('meadow'),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              // Oyuncular her dilde aynı yanda oturur.
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    _player(0),
                    Expanded(child: LayoutBuilder(builder: _board)),
                    _player(1),
                  ],
                ),
              ),
            ),
          ),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: BackRoundButton(),
              ),
            ),
          ),
          if (_over) _result(),
        ],
      ),
    );
  }

  Widget _player(int p) {
    final active = _turn == p && !_over;
    final color = _playerColors[p];
    final panel = Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 1 : 0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: active ? AppColors.yellow : Colors.white,
          width: active ? 5 : 3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '${p + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.yellow, size: 26),
              Text(' ${_scores[p]}', style: titleStyle.copyWith(fontSize: 24)),
            ],
          ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.only(top: p == 0 ? 64 : 0),
      child: Center(
        child: AnimatedScale(
          scale: active ? 1.08 : 0.94,
          duration: const Duration(milliseconds: 200),
          child: active ? Glow(radius: 22, child: panel) : panel,
        ),
      ),
    );
  }

  Widget _board(BuildContext context, BoxConstraints box) {
    const cols = 4;
    final rows = (_cards.length / cols).ceil();
    const gap = 8.0;
    final size = min(
      (box.maxWidth - 24 - gap * (cols - 1)) / cols,
      (box.maxHeight - gap * (rows - 1)) / rows,
    );
    return Center(
      child: SizedBox(
        width: size * cols + gap * (cols - 1),
        child: Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (var i = 0; i < _cards.length; i++) _card(i, size)],
        ),
      ),
    );
  }

  Widget _card(int i, double size) {
    final shown = _open.contains(i) || _matched.contains(i);
    return GestureDetector(
      onTapDown: (_) => _tap(i),
      child: AnimatedOpacity(
        opacity: _matched.contains(i) ? 0.45 : 1,
        duration: const Duration(milliseconds: 300),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Container(
            key: ValueKey(shown),
            width: size,
            height: size,
            padding: EdgeInsets.all(shown ? size * 0.1 : 0),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: shown ? Colors.white : AppColors.blue,
              borderRadius: BorderRadius.circular(size * 0.18),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: shown
                ? ObjectImage(_cards[i])
                : const GameImage(
                    'assets/images/ui/card_back.png',
                    fit: BoxFit.cover,
                    fallback: Center(
                      child: Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _result() {
    final draw = _scores[0] == _scores[1];
    final winner = _scores[0] > _scores[1] ? 0 : 1;
    final text = draw
        ? L.t('duel_draw')
        : L.t('duel_win').replaceAll('{n}', '${winner + 1}');
    return Positioned.fill(
      child: Stack(
        children: [
          const Positioned.fill(child: ConfettiBurst()),
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.ink.withValues(alpha: 0.35),
              child: Center(
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ToyPanel(
                      padding: const EdgeInsets.fromLTRB(36, 14, 36, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 110,
                            height: 110,
                            child: const Mascot('happy'),
                          ),
                          StrokeText(
                            text,
                            size: 34,
                            color: draw
                                ? AppColors.yellow
                                : _playerColors[winner],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_scores[0]} - ${_scores[1]}',
                            style: titleStyle.copyWith(fontSize: 28),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RoundButton(
                                icon: Icons.home_rounded,
                                color: AppColors.blue,
                                asset: 'btn_home',
                                size: 76,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(width: 20),
                              RoundButton(
                                icon: Icons.replay_rounded,
                                color: AppColors.purple,
                                asset: 'btn_replay',
                                size: 76,
                                onTap: () => setState(_deal),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
