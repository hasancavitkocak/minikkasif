import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/animals.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';
import 'quiz_round.dart';

/// Hayvanlar oyununun üç aşaması.
enum AnimalsMode {
  /// Hayvanlar tek tek tanıtılır: adı, ne yaptığı ve sesi.
  learn,

  /// Adı söylenen hayvanı bul.
  find,

  /// Sesi çalınan hayvanı bul.
  sound,
}

/// Hayvanlar: önce tanıtım (ad ve ses), sonra adı söylenen hayvanı bulma, en
/// son sesinden hayvanı bulma. Çocuk hayvanı ve sesini tanımadan soru sorulmaz.
class AnimalsGame extends StatelessWidget {
  const AnimalsGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  static AnimalsMode modeOf(int level) => level <= 2
      ? AnimalsMode.learn
      : level <= 4
      ? AnimalsMode.find
      : AnimalsMode.sound;

  /// Tanıtım bölümünde gösterilen hayvanlar: ilk bölüm ilk altısı, ikinci
  /// bölüm kalanları.
  static List<Animal> learnSet(int level) =>
      level <= 1 ? animals.sublist(0, 6) : animals.sublist(6);

  @override
  Widget build(BuildContext context) {
    final mode = modeOf(level);
    final learn = learnSet(level);
    return GameShell(
      game: game,
      level: level,
      rounds: mode == AnimalsMode.learn ? learn.length : 5,
      instruction: (_) => L.t(switch (mode) {
        AnimalsMode.learn => 'i_animals_learn',
        AnimalsMode.find => 'i_animals_find',
        AnimalsMode.sound => 'i_animals_sound',
      }),
      roundBuilder: (round, onSolved, onMistake) {
        if (mode == AnimalsMode.learn) {
          final animal = learn[round % learn.length];
          void sound() => AnimalSound.play(animal.key, animal.soundKey);
          return LearnRound(
            image: ObjectImage(animal.image),
            nameKey: animal.nameKey,
            textKey: animal.textKey,
            // Adı ve cümlesi söylendikten sonra sesi çalınır.
            afterSpeech: sound,
            // Hoparlöre dokununca ses yeniden çalınır.
            extras: [
              Pressable(
                key: const ValueKey('animal_sound'),
                onTap: sound,
                child: const SpeakerArt(),
              ),
            ],
            first: round == 0,
            onDone: onSolved,
          );
        }
        return _AnimalsRound(
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

class _AnimalsRound extends StatefulWidget {
  const _AnimalsRound({
    required this.level,
    required this.mode,
    required this.first,
    required this.onSolved,
    required this.onMistake,
  });
  final int level;
  final AnimalsMode mode;

  /// Bölümün ilk turu mu? İlk turda yönerge okunduğu için soru biraz bekleyip
  /// sorulur.
  final bool first;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_AnimalsRound> createState() => _AnimalsRoundState();
}

class _AnimalsRoundState extends State<_AnimalsRound> {
  static final _recent = RecentPicker(4);

  late final Animal _answer;
  late final List<Animal> _options;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final level = widget.level;
    final count = switch (widget.mode) {
      AnimalsMode.find => level <= 3 ? 3 : 4,
      _ => level <= 5 ? 2 : (level <= 7 ? 3 : 4),
    };
    _answer = animals[_recent.pick(rng, animals.length)];
    final others = [
      for (final a in animals)
        if (a != _answer) a,
    ]..shuffle(rng);
    _options = [_answer, ...others.take(count - 1)]..shuffle(rng);
    _timer = Timer(Duration(milliseconds: widget.first ? 2600 : 700), () {
      if (mounted) _ask();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    AnimalSound.stop();
    super.dispose();
  }

  /// Soruyu sorar: bulma aşamasında hayvanın adını söyler, ses aşamasında
  /// sesini çalar.
  void _ask() => widget.mode == AnimalsMode.find ? _sayName() : _playSound();

  void _sayName() => Tts.speak(L.t(_answer.nameKey), key: _answer.nameKey);

  void _playSound() => AnimalSound.play(_answer.key, _answer.soundKey);

  @override
  Widget build(BuildContext context) {
    return QuizRound(
      // Hoparlöre dokununca soru yeniden sorulur.
      prompt: Pressable(onTap: _ask, child: const SpeakerArt()),
      options: [for (final a in _options) ObjectImage(a.image)],
      answer: _options.indexOf(_answer),
      onSolved: () {
        // Doğru bulununca öbür bilgi pekiştirilir: adı sorulduysa sesi
        // çalınır, sesi sorulduysa adı söylenir.
        widget.mode == AnimalsMode.find ? _playSound() : _sayName();
        widget.onSolved();
      },
      onMistake: widget.onMistake,
    );
  }
}
