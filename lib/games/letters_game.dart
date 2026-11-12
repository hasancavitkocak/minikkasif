import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import 'game_def.dart';
import 'quiz_round.dart';

/// Her dilin alfabesi: büyük ve küçük harfler aynı sırada.
const alphabets = <String, (String, String)>{
  'tr': ('ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ', 'abcçdefgğhıijklmnoöprsştuüvyz'),
  'en': ('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),
  'de': ('ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ', 'abcdefghijklmnopqrstuvwxyzäöü'),
  'fr': ('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),
  'es': ('ABCDEFGHIJKLMNÑOPQRSTUVWXYZ', 'abcdefghijklmnñopqrstuvwxyz'),
};

/// Seçili dilin alfabesi.
(String, String) get alphabet => alphabets[AppState.I.lang] ?? alphabets['en']!;

/// Harfin ses kaydının adı (`let_a`, `let_cc`...). Dosya adları yalnızca
/// İngilizce harf içersin diye özel harfler çift yazılır.
String letterVoiceKey(String lower) {
  const special = {
    'ç': 'cc',
    'ğ': 'gg',
    'ı': 'ii',
    'ö': 'oo',
    'ş': 'ss',
    'ü': 'uu',
    'ä': 'ae',
    'ñ': 'nn',
  };
  return 'let_${special[lower] ?? lower}';
}

/// Harfler oyununun üç aşaması.
enum LettersMode {
  /// Gösterilen harfin aynısını bul.
  same,

  /// Söylenen harfi bul.
  hear,

  /// Büyük harfin küçüğünü bul.
  lower,
}

/// Harfler: önce aynı harfi bulma, sonra duyulan harfi bulma, en son büyük
/// harfi küçüğüyle eşleme. Seçili dilin alfabesiyle oynanır.
class LettersGame extends StatelessWidget {
  const LettersGame({super.key, required this.game, required this.level});
  final GameDef game;
  final int level;

  static LettersMode modeOf(int level) => level <= 4
      ? LettersMode.same
      : level <= 7
      ? LettersMode.hear
      : LettersMode.lower;

  @override
  Widget build(BuildContext context) {
    final mode = modeOf(level);
    return GameShell(
      game: game,
      level: level,
      rounds: 5,
      instruction: (_) => L.t(switch (mode) {
        LettersMode.same => 'i_letters_same',
        LettersMode.hear => 'i_letters_hear',
        LettersMode.lower => 'i_letters_case',
      }),
      roundBuilder: (round, onSolved, onMistake) => _LettersRound(
        level: level,
        mode: mode,
        first: round == 0,
        onSolved: onSolved,
        onMistake: onMistake,
      ),
    );
  }
}

class _LettersRound extends StatefulWidget {
  const _LettersRound({
    required this.level,
    required this.mode,
    required this.first,
    required this.onSolved,
    required this.onMistake,
  });
  final int level;
  final LettersMode mode;

  /// Bölümün ilk turu mu? İlk turda yönerge okunduğu için harf biraz
  /// bekleyip söylenir.
  final bool first;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  @override
  State<_LettersRound> createState() => _LettersRoundState();
}

class _LettersRoundState extends State<_LettersRound> {
  static final _recent = RecentPicker(8);

  static const _colors = [
    AppColors.red,
    AppColors.orange,
    AppColors.green,
    AppColors.teal,
    AppColors.blue,
    AppColors.purple,
    AppColors.pink,
  ];

  late final String _upper;
  late final String _lower;
  late final int _answer;
  late final List<int> _options;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final level = widget.level;
    final letters = alphabet;
    _upper = letters.$1;
    _lower = letters.$2;
    final count = switch (widget.mode) {
      LettersMode.same => level <= 2 ? 2 : 3,
      LettersMode.hear => level <= 6 ? 3 : 4,
      LettersMode.lower => level <= 9 ? 3 : 4,
    };
    _answer = _recent.pick(rng, _upper.length);
    final others = [
      for (var i = 0; i < _upper.length; i++)
        if (i != _answer) i,
    ]..shuffle(rng);
    _options = [_answer, ...others.take(count - 1)]..shuffle(rng);
    if (widget.mode == LettersMode.hear) {
      _timer = Timer(Duration(milliseconds: widget.first ? 2400 : 700), () {
        if (mounted) _say();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Sorulan harfi söyler.
  void _say() {
    final letter = _lower[_answer];
    Tts.speak(letter, key: letterVoiceKey(letter));
  }

  /// Harfler, okumayı öğrenenler için tasarlanmış ayrı bir yazı tipiyle
  /// yazılır: büyük I çizgili, küçük l kuyruklu, j ile i belirgin.
  Widget _letter(String text, Color color) {
    return FittedBox(
      child: Text(
        text,
        style: titleStyle.copyWith(
          fontSize: 64,
          height: 1.1,
          fontFamily: 'Harf',
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    return QuizRound(
      prompt: mode == LettersMode.hear
          // Hoparlöre dokununca harf yeniden söylenir.
          ? Pressable(
              onTap: _say,
              child: const FittedBox(
                child: Icon(Icons.volume_up_rounded, color: AppColors.blue),
              ),
            )
          : _letter(_upper[_answer], AppColors.ink),
      // Renk harfe değil sıraya bağlıdır; yoksa renk doğru cevabı ele verir.
      options: [
        for (final (slot, i) in _options.indexed)
          _letter(
            mode == LettersMode.lower ? _lower[i] : _upper[i],
            _colors[(slot + _answer) % _colors.length],
          ),
      ],
      answer: _options.indexOf(_answer),
      onSolved: () {
        // Doğru bulunan harf sesli de söylenir.
        _say();
        widget.onSolved();
      },
      onMistake: widget.onMistake,
    );
  }
}
