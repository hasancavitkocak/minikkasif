import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../app_state.dart';
import '../games/registry.dart';
import '../l10n.dart';
import '../services/purchases.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

/// Abonelik ekranı (aylık ve yıllık). Yalnızca ebeveyn kapısından sonra açılır.
/// Mağaza hesabı olmadan tüm oyunları gösterebilmek için tanıtım derlemesi:
/// `--dart-define=DEMO_UNLOCK=true`. Yayın derlemesinde verilmez.
const _demoUnlock = bool.fromEnvironment('DEMO_UNLOCK');

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _yearly = true;

  @override
  void initState() {
    super.initState();
    final purchases = Purchases.I;
    if (purchases.available && purchases.products.isEmpty) {
      purchases.loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Backdrop('space'),
          SafeArea(
            child: ListenableBuilder(
              listenable: Listenable.merge([Purchases.I, AppState.I]),
              builder: (context, _) => Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        72,
                        10,
                        16,
                        10,
                      ),
                      // Tasarım sabit genişlikte kurulur, ekrana göre ölçeklenir.
                      child: FittedBox(
                        child: SizedBox(
                          width: 780,
                          child: ToyPanel(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                            child: Row(
                              children: [
                                SizedBox(width: 230, child: _mascotSide()),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppState.I.premium
                                      ? _thanks()
                                      : _offer(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const PositionedDirectional(
                    top: 12,
                    start: 12,
                    child: BackRoundButton(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sol taraf: maskot, konuşma balonu ve açılacak oyunların ikonları.
  Widget _mascotSide() {
    final premium = AppState.I.premium;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpeechBubble(
          tail: BubbleTail.bottom,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            L.t(premium ? 'thanks' : 'paywall_bubble'),
            maxLines: 3,
            textAlign: TextAlign.center,
            style: titleStyle.copyWith(fontSize: 16),
          ),
        ),
        const Bobbing(
          child: SizedBox(width: 150, height: 150, child: Mascot('happy')),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final game in games.where((g) => !g.free))
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: game.color, width: 3),
                ),
                child: GameImage(
                  'assets/images/icons/game_${game.id}.png',
                  fallback: Emoji(game.emoji),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _thanks() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 110,
          height: 110,
          child: GameImage('assets/images/ui/crown.png', fallback: Emoji('👑')),
        ),
        StrokeText(L.t('premium_active'), size: 32, color: AppColors.yellow),
        const SizedBox(height: 16),
        BigButton(
          label: L.t('continue'),
          icon: Icons.play_arrow_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Widget _offer() {
    final purchases = Purchases.I;
    final selected = _yearly ? purchases.yearly : purchases.monthly;
    const demo = kDebugMode || _demoUnlock;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: GameImage(
                'assets/images/ui/crown.png',
                fallback: Emoji('👑'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                L.t('premium_title'),
                maxLines: 2,
                style: titleStyle.copyWith(fontSize: 26),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _benefit(Icons.extension_rounded, AppColors.purple, L.t('premium_b1')),
        _benefit(
          Icons.verified_user_rounded,
          AppColors.teal,
          L.t('premium_b2'),
        ),
        _benefit(
          Icons.event_available_rounded,
          AppColors.orange,
          L.t('premium_b3'),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _plan(L.t('monthly'), purchases.monthly, yearly: false),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _plan(
                L.t('yearly'),
                purchases.yearly,
                yearly: true,
                badge: L.t('best_value'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: BigButton(
            label: L.t('continue'),
            icon: Icons.lock_open_rounded,
            // Tanıtım derlemesinde mağaza olmadığı için buton kilidi doğrudan açar.
            onTap: selected != null
                ? () => Purchases.I.buy(selected)
                : demo
                ? () => AppState.I.setPremium(true)
                : null,
          ),
        ),
        if (!purchases.available || purchases.error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_rounded,
                  color: AppColors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    demo && !purchases.available
                        ? 'Tanıtım sürümü: "${L.t('continue')}" butonu tüm oyunları açar.'
                        : purchases.available
                        ? purchases.error!
                        : L.t('store_unavailable'),
                    style: const TextStyle(fontSize: 13, height: 1.2),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 6),
        Pressable(
          onTap: purchases.available ? purchases.restore : null,
          child: Text(
            L.t('restore'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.blue,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.blue,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          L.t('sub_note'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            height: 1.2,
            color: AppColors.ink.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _benefit(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _plan(
    String title,
    ProductDetails? product, {
    required bool yearly,
    String? badge,
  }) {
    final selected = _yearly == yearly;
    final color = yearly ? AppColors.green : AppColors.blue;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Pressable(
          onTap: () => setState(() => _yearly = yearly),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.16) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? color : AppColors.grey.withValues(alpha: 0.6),
                width: selected ? 4 : 2.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? color : AppColors.grey,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle.copyWith(fontSize: 17)),
                      Text(
                        product?.price ?? '—',
                        style: titleStyle.copyWith(fontSize: 24),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (badge != null)
          PositionedDirectional(
            top: -12,
            end: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
