import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/jobs.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';
import 'quiz_round.dart';

/// Meslekler oyununun üç aşaması.
enum JobsMode {
  /// Meslekler tek tek tanıtılır: adı, ne yaptığı ve aracı.
  learn,

  /// Adı söylenen mesleği bul.
  find,

  /// Aracı kullanan mesleği (ya da mesleğin aracını) bul.
  match,
}

/// Meslekler: önce tanıtım, sonra adı söylenen mesleği bulma, en son meslekle
/// aracını eşleme. Çocuk mesleği tanımadan soru sorulmaz.
class JobsGame extends StatelessWidget {
  const JobsGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  static JobsMode modeOf(int level) => level <= 2
      ? JobsMode.learn
      : level <= 5
      ? JobsMode.find
      : JobsMode.match;

  /// Son bölümlerde tek numaralı turlar tersine oynanır.
  bool _reversed(int round) => level >= 8 && round.isOdd;

  @override
  Widget build(BuildContext context) {
    final mode = modeOf(level);
    return GameShell(
      game: game,
      level: level,
      rounds: 5,
      instruction: (round) => L.t(switch (mode) {
        JobsMode.learn => 'i_jobs_learn',
        JobsMode.find => 'i_jobs_find',
        JobsMode.match => _reversed(round) ? 'i_jobs_rev' : 'i_jobs',
      }),
      roundBuilder: (round, onSolved, onMistake) {
        if (mode == JobsMode.learn) {
          // İlk bölüm ilk beş mesleği, ikinci bölüm kalan beşini tanıtır.
          final job = jobs[((level - 1) * 5 + round) % jobs.length];
          return LearnRound(
            image: ObjectImage(job.person),
            nameKey: job.nameKey,
            textKey: job.textKey,
            extras: [ObjectImage(job.tool)],
            first: round == 0,
            onDone: onSolved,
          );
        }
        return _JobsRound(
          level: level,
          mode: mode,
          reversed: _reversed(round),
          first: round == 0,
          onSolved: onSolved,
          onMistake: onMistake,
        );
      },
    );
  }
}

class _JobsRound extends StatefulWidget {
  const _JobsRound({
    required this.level,
    required this.mode,
    required this.reversed,
    required this.first,
    required this.onSolved,
    required this.onMistake,
  });
  final int level;
  final JobsMode mode;
  final bool reversed;

  /// Bölümün ilk turu mu? İlk turda yönerge okunduğu için meslek adı biraz
  /// bekleyip söylenir.
  final bool first;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_JobsRound> createState() => _JobsRoundState();
}

class _JobsRoundState extends State<_JobsRound> {
  static final _recent = RecentPicker(4);

  late final List<Job> _options;
  late final Job _answer;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final level = widget.level;
    final count = switch (widget.mode) {
      JobsMode.find => level <= 3 ? 2 : 3,
      _ => level <= 7 ? 3 : 4,
    };
    _answer = jobs[_recent.pick(rng, jobs.length)];
    final others = [
      for (final j in jobs)
        if (j != _answer) j,
    ]..shuffle(rng);
    _options = [_answer, ...others.take(count - 1)]..shuffle(rng);
    if (widget.mode == JobsMode.find) {
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

  /// Sorulan mesleğin adını söyler.
  void _say() => Tts.speak(L.t(_answer.nameKey), key: _answer.nameKey);

  @override
  Widget build(BuildContext context) {
    final find = widget.mode == JobsMode.find;
    final reversed = widget.reversed;
    return QuizRound(
      prompt: find
          // Hoparlöre dokununca meslek adı yeniden söylenir.
          ? Pressable(
              onTap: _say,
              child: const FittedBox(
                child: Icon(Icons.volume_up_rounded, color: AppColors.blue),
              ),
            )
          : ObjectImage(reversed ? _answer.person : _answer.tool),
      options: [
        for (final j in _options) ObjectImage(reversed ? j.tool : j.person),
      ],
      answer: _options.indexOf(_answer),
      onSolved: () {
        // Doğru bulunan mesleğin adı söylenir.
        _say();
        widget.onSolved();
      },
      onMistake: widget.onMistake,
    );
  }
}
