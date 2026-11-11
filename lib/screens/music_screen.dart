import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'parent_gate.dart';
import 'paywall_screen.dart';

/// Öğretilen bir şarkı: sırayla basılacak çubuklar (0: kalın do ... 7: ince do).
class Song {
  const Song(this.emoji, this.notes);
  final String emoji;
  final List<int> notes;
}

/// Sekiz notaya sığan, herkesin bildiği kısa ezgiler. İlki ücretsizdir.
const songs = <Song>[
  // Twinkle Twinkle Little Star
  Song('⭐', [0, 0, 4, 4, 5, 5, 4, 3, 3, 2, 2, 1, 1, 0]),
  // Row, Row, Row Your Boat
  Song('🚣', [0, 0, 0, 1, 2, 2, 1, 2, 3, 4]),
  // Mary Had a Little Lamb
  Song('🐑', [2, 1, 0, 1, 2, 2, 2, 1, 1, 1, 2, 4, 4]),
  // London Bridge
  Song('🌉', [4, 5, 4, 3, 2, 3, 4, 1, 2, 3, 2, 3, 4]),
  // Ode to Joy
  Song('🎼', [2, 2, 3, 4, 4, 3, 2, 1, 0, 0, 1, 2, 2, 1, 1]),
];

/// Müzik kutusu: sekiz çubuklu renkli ksilofon. Serbest çalınır ya da bir
/// şarkı seçilir; şarkıda sıradaki çubuk parlar, çocuk ona dokunarak ezgiyi
/// kendisi çalar.
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  static const _colors = [
    AppColors.red,
    AppColors.orange,
    AppColors.yellow,
    AppColors.green,
    AppColors.teal,
    AppColors.blue,
    AppColors.purple,
    AppColors.pink,
  ];

  /// Her çubuğun vuruluş sayacı; değişince çubuk zıplar.
  final List<int> _hits = List.filled(8, 0);

  /// Seçili şarkı; null ise serbest çalma.
  int? _song;

  /// Şarkıda sıradaki notanın sırası.
  int _step = 0;
  bool _finished = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Arka plan müziği notaları bastırmasın.
    Music.setActive(false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    Music.setActive(true);
    super.dispose();
  }

  /// Sıradaki basılacak çubuk; şarkı yoksa ya da bittiyse null.
  int? get _target =>
      _song == null || _finished ? null : songs[_song!].notes[_step];

  void _play(int i) {
    Sfx.play('xylo${i + 1}');
    setState(() {
      _hits[i]++;
      // Yanlış çubuk da çalar ama şarkı ilerlemez; ceza yoktur.
      if (i != _target) return;
      _step++;
      if (_step >= songs[_song!].notes.length) {
        _finished = true;
        _timer = Timer(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          Sfx.play('win');
          Tts.speak(L.praise());
        });
      }
    });
  }

  Future<void> _select(int? song) async {
    if (song != null && song > 0 && !AppState.I.premium) {
      // İlk şarkı ücretsiz; diğerleri abonelikle açılır.
      final navigator = Navigator.of(context);
      if (await showParentGate(context)) {
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
        );
      }
      return;
    }
    _timer?.cancel();
    setState(() {
      _song = song;
      _step = 0;
      _finished = false;
    });
    Tts.speak(L.t(song == null ? 'i_music' : 'music_follow'));
  }

  @override
  Widget build(BuildContext context) {
    final hint = L.t(_song == null ? 'i_music' : 'music_follow');
    return Scaffold(
      body: Stack(
        children: [
          const Backdrop('meadow'),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                children: [
                  SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        const BackRoundButton(),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: SpeakOnce(
                            'i_music',
                            child: Mascot(_finished ? 'happy' : 'hello'),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: SpeechBubble(
                              child: Text(
                                hint,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle.copyWith(
                                  fontSize: 17,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _songPicker(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Çubuklar her dilde kalından inceye, soldan sağa dizilir.
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: [
                          for (var i = 0; i < 8; i++) Expanded(child: _bar(i)),
                        ],
                      ),
                    ),
                  ),
                  if (_song != null) ...[
                    const SizedBox(height: 6),
                    _progress(),
                  ],
                ],
              ),
            ),
          ),
          if (_finished)
            const Positioned.fill(child: IgnorePointer(child: ConfettiBurst())),
        ],
      ),
    );
  }

  /// Serbest çalma ve şarkı düğmeleri.
  Widget _songPicker() {
    final premium = AppState.I.premium;
    Widget chip(int? song, String emoji) {
      final selected = _song == song;
      final locked = song != null && song > 0 && !premium;
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Pressable(
          onTap: () => _select(song),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: selected ? 52 : 46,
                height: selected ? 52 : 46,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: selected ? 1 : 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.yellow : Colors.white,
                    width: selected ? 4 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Opacity(opacity: locked ? 0.5 : 1, child: Emoji(emoji)),
              ),
              if (locked)
                const Positioned(
                  right: -4,
                  top: -4,
                  width: 22,
                  height: 22,
                  child: GameImage(
                    'assets/images/ui/lock.png',
                    fallback: FittedBox(
                      child: Icon(Icons.lock_rounded, color: AppColors.orange),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip(null, '🎹'),
          for (final (i, song) in songs.indexed) chip(i, song.emoji),
        ],
      ),
    );
  }

  /// Şarkının neresinde olunduğunu gösteren noktalar.
  Widget _progress() {
    final notes = songs[_song!].notes;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < notes.length; i++)
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i < _step
                    ? _colors[notes[i]]
                    : Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: i == _step && !_finished
                      ? AppColors.ink
                      : Colors.white,
                  width: 2,
                ),
              ),
            ),
          if (_finished) ...[
            const SizedBox(width: 10),
            RoundButton(
              icon: Icons.replay_rounded,
              color: AppColors.purple,
              size: 40,
              onTap: () => _select(_song),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bar(int i) {
    final color = _colors[i];
    final target = _target == i;
    // Şarkıda sıradaki çubuk parlar, ötekiler biraz solar.
    final dim = _target != null && !target;
    final bar = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.lerp(color, Colors.white, 0.35)!,
            color,
            Color.lerp(color, Colors.black, 0.15)!,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: target ? AppColors.yellow : Colors.white,
          width: target ? 6 : 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _peg(),
          if (target)
            const FittedBox(
              child: Icon(
                Icons.touch_app_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          _peg(),
        ],
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _play(i),
      child: FractionallySizedBox(
        // İnce ses daha kısa çubuk.
        heightFactor: 1 - i * 0.065,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('$i-${_hits[i]}'),
          tween: Tween(begin: _hits[i] == 0 ? 0 : 1, end: 0),
          duration: const Duration(milliseconds: 260),
          builder: (context, v, child) =>
              Transform.scale(scale: 1 - 0.07 * v, child: child),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: AnimatedOpacity(
              opacity: dim ? 0.55 : 1,
              duration: const Duration(milliseconds: 150),
              child: target ? Glow(radius: 18, spread: 8, child: bar) : bar,
            ),
          ),
        ),
      ),
    );
  }

  Widget _peg() => Container(
    width: 14,
    height: 14,
    margin: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.85),
      shape: BoxShape.circle,
    ),
  );
}
