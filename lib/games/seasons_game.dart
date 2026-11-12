import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/objects.dart';
import '../data/seasons.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';
import 'quiz_round.dart';

/// Mevsimler oyununun dört aşaması.
enum SeasonsMode {
  /// Mevsimler tek tek tanıtılır: adı, havası ve Fıstık'ın o mevsimdeki
  /// kıyafeti.
  learn,

  /// Gösterilen mevsimde Fıstık'ın ne giyeceğini bul.
  dress,

  /// Adı söylenen mevsimi bul.
  find,

  /// Fıstık'ın kıyafetinin hangi mevsime ait olduğunu bul.
  season,
}

/// Mevsimler: önce tanıtım, sonra "Fıstık bu havada ne giysin?", ardından adı
/// söylenen mevsimi bulma, en son kıyafetten mevsimi bulma.
class SeasonsGame extends StatelessWidget {
  const SeasonsGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  static SeasonsMode modeOf(int level) => level <= 1
      ? SeasonsMode.learn
      : level <= 5
      ? SeasonsMode.dress
      : level <= 7
      ? SeasonsMode.find
      : SeasonsMode.season;

  @override
  Widget build(BuildContext context) {
    final mode = modeOf(level);
    return GameShell(
      game: game,
      level: level,
      rounds: mode == SeasonsMode.learn ? seasons.length : 5,
      instruction: (_) => L.t(switch (mode) {
        SeasonsMode.learn => 'i_seasons_learn',
        SeasonsMode.dress => 'i_seasons',
        SeasonsMode.find => 'i_seasons_find',
        SeasonsMode.season => 'i_seasons_rev',
      }),
      roundBuilder: (round, onSolved, onMistake) {
        if (mode == SeasonsMode.learn) {
          final index = round % seasons.length;
          return LearnRound(
            image: ObjectImage(seasons[index]),
            nameKey: seasons[index].id,
            textKey: '${seasons[index].id}_d',
            // Fıstık'ın o mevsimdeki kıyafeti, resmin yanında büyükçe durur.
            companion: ObjectImage(seasonOutfits[index]),
            first: round == 0,
            onDone: onSolved,
          );
        }
        return _SeasonsRound(
          level: level,
          mode: mode,
          first: round == 0,
          onSolved: onSolved,
          onMistake: onMistake,
        );
      },
    );
  }
}

class _SeasonsRound extends StatefulWidget {
  const _SeasonsRound({
    required this.level,
    required this.mode,
    required this.first,
    required this.onSolved,
    required this.onMistake,
  });
  final int level;
  final SeasonsMode mode;

  /// Bölümün ilk turu mu? İlk turda yönerge okunduğu için mevsim adı biraz
  /// bekleyip söylenir.
  final bool first;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_SeasonsRound> createState() => _SeasonsRoundState();
}

class _SeasonsRoundState extends State<_SeasonsRound> {
  static final _recent = RecentPicker(2);

  late final int _answer;
  late final List<int> _options;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final level = widget.level;
    _answer = _recent.pick(rng, seasons.length);
    // Seçenek sayısı ve ilkbahar-sonbahar ikilisinin birlikte gelip
    // gelmeyeceği bölüme göre değişir.
    final (count, twins) = switch (widget.mode) {
      SeasonsMode.dress => level <= 3 ? (2, false) : (3, level >= 5),
      SeasonsMode.find => level <= 6 ? (3, true) : (4, true),
      _ => level <= 8 ? (2, false) : (level == 9 ? (3, false) : (4, true)),
    };
    final others = [
      for (var s = 0; s < seasons.length; s++)
        if (s != _answer && (twins || s != seasonTwin(_answer))) s,
    ]..shuffle(rng);
    _options = [_answer, ...others.take(count - 1)]..shuffle(rng);
    if (widget.mode == SeasonsMode.find) {
      _timer = Timer(Duration(milliseconds: widget.first ? 2600 : 700), () {
        if (mounted) _say();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Sorulan mevsimin adını söyler.
  void _say() {
    final key = seasons[_answer].id;
    Tts.speak(L.t(key), key: key);
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    GameObject option(int season) =>
        mode == SeasonsMode.dress ? seasonOutfits[season] : seasons[season];
    return QuizRound(
      prompt: switch (mode) {
        // Hoparlöre dokununca mevsim adı yeniden söylenir.
        SeasonsMode.find => Pressable(
          onTap: _say,
          child: const FittedBox(
            child: Icon(Icons.volume_up_rounded, color: AppColors.blue),
          ),
        ),
        SeasonsMode.season => ObjectImage(seasonOutfits[_answer]),
        _ => ObjectImage(seasons[_answer]),
      },
      options: [for (final s in _options) ObjectImage(option(s))],
      answer: _options.indexOf(_answer),
      onSolved: () {
        // Doğru bulunan mevsimin adı söylenir.
        _say();
        widget.onSolved();
      },
      onMistake: widget.onMistake,
    );
  }
}
