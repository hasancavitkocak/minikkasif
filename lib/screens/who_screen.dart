import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'home_screen.dart';

/// "Kim oynuyor?": birden fazla profil varsa açılışta (ve uzun bir aradan
/// sonra) çocuk kendi resmine dokunarak profilini seçer. Böylece kardeşlerin
/// yıldızları ve çıkartmaları karışmaz. Tek profil varsa hiç gösterilmez.
class WhoScreen extends StatelessWidget {
  const WhoScreen({super.key});

  /// Açılıştan sonra gidilecek ekran: profil birden çoksa bu ekran, değilse
  /// doğrudan ana ekran.
  static Widget next() =>
      AppState.I.profiles.length > 1 ? const WhoScreen() : const HomeScreen();

  void _pick(BuildContext context, Profile p) {
    AppState.I.switchProfile(p.id);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    return Scaffold(
      body: Stack(
        children: [
          const Backdrop('home'),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox.expand(
                child: FittedBox(
                  child: SizedBox(
                    width: 900,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 120,
                              height: 120,
                              child: SpeakOnce(
                                'who_plays',
                                child: Mascot('hello'),
                              ),
                            ),
                            SpeechBubble(
                              child: Text(
                                L.t('who_plays'),
                                style: titleStyle.copyWith(fontSize: 30),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final p in state.profiles)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Pressable(
                                  key: ValueKey('who_${p.id}'),
                                  onTap: () => _pick(context, p),
                                  child: Container(
                                    width: 180,
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      16,
                                      12,
                                      12,
                                    ),
                                    decoration: panelDecoration(
                                      radius: 32,
                                      color: Colors.white,
                                    ),
                                    child: Column(
                                      children: [
                                        // En son oynayan profil çerçeveyle
                                        // öne çıkar.
                                        Avatar(
                                          p,
                                          size: 128,
                                          selected: p.id == state.profile.id,
                                        ),
                                        const SizedBox(height: 10),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            state.profileName(p),
                                            maxLines: 1,
                                            style: titleStyle.copyWith(
                                              fontSize: 26,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
        ],
      ),
    );
  }
}
