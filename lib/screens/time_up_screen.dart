import 'package:flutter/material.dart';

import '../l10n.dart';
import '../services/audio.dart';
import '../services/screen_time.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'parent_gate.dart';
import 'parents_screen.dart';

/// Günlük süre dolunca açılan ekran. Geri tuşuyla kapanmaz; ebeveyn kapısını
/// geçen kişi süre ekleyebilir, bugün için sınırı kaldırabilir ya da
/// ayarlara gidebilir. Süre yeniden açılınca ekranı uygulama kaldırır.
class TimeUpScreen extends StatefulWidget {
  const TimeUpScreen({super.key});

  @override
  State<TimeUpScreen> createState() => _TimeUpScreenState();
}

class _TimeUpScreenState extends State<TimeUpScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Tts.speak(L.t('time_up'), owner: this, key: 'time_up');
    });
  }

  @override
  void dispose() {
    Tts.stopFor(this);
    super.dispose();
  }

  Future<void> _parent() async {
    if (!await showParentGate(context) || !mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => const _ExtendDialog(),
    );
    if (!mounted || choice == null) return;
    final time = ScreenTime.I;
    switch (choice) {
      case '15':
        time.addMinutes(15);
      case '30':
        time.addMinutes(30);
      case 'unlimited':
        time.unlimitedToday();
      case 'settings':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ParentsScreen(initialTab: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
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
                          const Expanded(
                            flex: 4,
                            child: Bobbing(child: Mascot('wave')),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 6,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PopIn(
                                  child: SpeechBubble(
                                    tail: BubbleTail.left,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 16,
                                    ),
                                    child: Text(
                                      L.t('time_up'),
                                      textAlign: TextAlign.center,
                                      style: titleStyle.copyWith(fontSize: 28),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Icon(
                                  Icons.nightlight_round,
                                  color: AppColors.yellow,
                                  size: 46,
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
            // Ebeveyn düğmesi küçük ve köşede: çocuğun ilgisini çekmesin.
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Pressable(
                    onTap: _parent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            color: AppColors.ink,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            L.t('parents'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
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

/// Ebeveynin seçenekleri: süre ekle, bugün sınırsız, ayarlar.
class _ExtendDialog extends StatelessWidget {
  const _ExtendDialog();

  @override
  Widget build(BuildContext context) {
    final min = L.t('min_short');
    Widget option(String value, String label, Color color, IconData icon) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: SizedBox(
            width: 340,
            child: BigButton(
              label: label,
              color: color,
              icon: icon,
              fontSize: 20,
              onTap: () => Navigator.of(context).pop(value),
            ),
          ),
        );
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FittedBox(
        child: SizedBox(
          width: 440,
          child: ToyPanel(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      L.t('time_extend'),
                      textAlign: TextAlign.center,
                      style: titleStyle.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 12),
                    option(
                      '15',
                      '+15 $min',
                      AppColors.green,
                      Icons.add_rounded,
                    ),
                    option('30', '+30 $min', AppColors.blue, Icons.add_rounded),
                    option(
                      'unlimited',
                      L.t('time_unlimited'),
                      AppColors.orange,
                      Icons.all_inclusive_rounded,
                    ),
                    option(
                      'settings',
                      L.t('time_settings'),
                      AppColors.purple,
                      Icons.tune_rounded,
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: RoundButton(
                    icon: Icons.close_rounded,
                    asset: 'btn_close',
                    color: AppColors.red,
                    size: 40,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
