import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import 'common.dart';
import 'ui.dart';

/// Fıstık'ın tanışma konuşması: ilk açılışta kendini tanıtır ve oyunu
/// konuşma balonlarıyla, sesli olarak anlatır.
class Intro {
  /// Testlerde otomatik açılmaması için kapatılır.
  static bool enabled = true;

  static const _id = 'intro';
  static bool _open = false;

  static bool get seen => AppState.I.seenHowTo(_id);

  /// İlk açılışta bir kez gösterir.
  static void showOnce(BuildContext context) {
    if (enabled && !seen) show(context);
  }

  static Future<void> show(BuildContext context) async {
    if (_open) return;
    _open = true;
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 250),
        transitionBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        // Arkadaki ekran kararır, dikkat Fıstık'ta toplanır.
        pageBuilder: (_, _, _) => Material(
          color: AppColors.ink.withValues(alpha: 0.72),
          child: const _IntroDialog(),
        ),
      );
    } finally {
      _open = false;
      Tts.stop();
      AppState.I.markHowToSeen(_id);
    }
  }
}

class _IntroDialog extends StatefulWidget {
  const _IntroDialog();

  @override
  State<_IntroDialog> createState() => _IntroDialogState();
}

class _IntroDialogState extends State<_IntroDialog> {
  static const _lines = ['intro_1', 'intro_2', 'intro_3', 'intro_4'];
  static const _poses = ['hello', 'happy', 'happy', 'hello'];
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _speak();
  }

  void _speak() => Tts.speak(L.t(_lines[_step]));

  void _next() {
    if (_step == _lines.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step++);
    _speak();
  }

  @override
  Widget build(BuildContext context) {
    final last = _step == _lines.length - 1;
    return SafeArea(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Ekranın herhangi bir yerine dokunmak da ilerletir.
        onTap: _next,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FittedBox(
            child: SizedBox(
              width: 720,
              height: 340,
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 260,
                        height: 300,
                        child: _step == 0
                            ? const WavingMascot()
                            : Bobbing(
                                distance: 4,
                                child: Mascot(_poses[_step]),
                              ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PopIn(
                              key: ValueKey(_step),
                              child: SpeechBubble(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 16,
                                ),
                                child: Text(
                                  L.t(_lines[_step]),
                                  textAlign: TextAlign.center,
                                  style: titleStyle.copyWith(fontSize: 28),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < _lines.length; i++)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    width: i == _step ? 18 : 12,
                                    height: i == _step ? 18 : 12,
                                    decoration: BoxDecoration(
                                      color: i == _step
                                          ? AppColors.yellow
                                          : Colors.white.withValues(alpha: 0.7),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.ink,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 18),
                                Bobbing(
                                  distance: 0,
                                  pulse: 0.07,
                                  child: RoundButton(
                                    icon: last
                                        ? Icons.check_rounded
                                        : Icons.arrow_forward_rounded,
                                    color: AppColors.green,
                                    size: 78,
                                    onTap: _next,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Sabırsız yetişkin için: konuşmayı atla.
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: RoundButton(
                      icon: Icons.close_rounded,
                      color: AppColors.grey,
                      size: 46,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
