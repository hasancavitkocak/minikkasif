import 'package:flutter/material.dart';

import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'home_screen.dart';

/// Karşılama ekranı: oyunun adı, maskot ve büyük "başla" butonu.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _start(BuildContext context) {
    Music.sync();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _start(context),
        child: Stack(
          children: [
            const Backdrop('home'),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox.expand(
                  child: FittedBox(
                    child: SizedBox(
                      width: 720,
                      height: 340,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                PopIn(
                                  delay: 3,
                                  child: SpeechBubble(
                                    tail: BubbleTail.bottom,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      L.t('intro_1'),
                                      style: titleStyle.copyWith(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: PopIn(child: WavingMascot()),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Logo görseli varsa o, yoksa yazı görünür.
                                const PopIn(
                                  delay: 1,
                                  child: SizedBox(
                                    height: 150,
                                    child: GameImage(
                                      'assets/images/ui/logo.png',
                                      fallback: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: StrokeText(
                                          'Minik Kaşif',
                                          size: 68,
                                          color: AppColors.yellow,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                PopIn(
                                  delay: 2,
                                  child: StrokeText(L.t('tagline'), size: 24),
                                ),
                                const SizedBox(height: 22),
                                PopIn(
                                  delay: 4,
                                  child: Bobbing(
                                    distance: 0,
                                    pulse: 0.08,
                                    child: RoundButton(
                                      icon: Icons.play_arrow_rounded,
                                      color: AppColors.green,
                                      asset: 'btn_play',
                                      size: 120,
                                      onTap: () => _start(context),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
