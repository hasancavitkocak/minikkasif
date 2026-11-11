import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/outfits.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

/// Fıstık'ın dolabı: toplanan yıldızlarla açılan aksesuarlar. Seçilen
/// aksesuarı Fıstık karşılama ve ana ekranda takar.
class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    return Scaffold(
      body: Stack(
        children: [
          const Backdrop('home'),
          Positioned.fill(
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.25)),
          ),
          SafeArea(
            child: ListenableBuilder(
              listenable: state,
              builder: (context, _) => Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        72,
                        8,
                        16,
                        8,
                      ),
                      child: FittedBox(
                        child: SizedBox(
                          width: 780,
                          height: 360,
                          child: _content(state),
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

  Widget _content(AppState state) {
    final stars = state.allStars;
    final worn = currentOutfit;
    return Row(
      children: [
        SizedBox(
          width: 270,
          child: Column(
            children: [
              SpeechBubble(
                tail: BubbleTail.bottom,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Text(
                  L.t('wardrobe_hint'),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: titleStyle.copyWith(fontSize: 17, height: 1.15),
                ),
              ),
              // Seçilen aksesuar hemen Fıstık'ın üstünde görünür.
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: SpeakOnce(
                    'wardrobe_hint',
                    child: worn == null
                        ? const Mascot('hello')
                        : PopIn(
                            key: ValueKey(worn.id),
                            child: DressedFox(worn),
                          ),
                  ),
                ),
              ),
              // Rengi değiştirilebilen aksesuar takılıyken renk damlaları.
              SizedBox(
                height: 44,
                child: worn?.color == null
                    ? null
                    : Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final e in outfitColors.entries)
                              _swatch(state, worn!, e.key, e.value),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StrokeText(L.t('g_wardrobe'), size: 30),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      decoration: panelDecoration(radius: 18),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.yellow,
                            size: 24,
                          ),
                          Text(
                            ' $stars',
                            style: titleStyle.copyWith(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ToyPanel(
                  padding: const EdgeInsets.all(12),
                  // Raflar her dilde aynı sırada durur.
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        for (final outfit in outfits)
                          _slot(state, outfit, stars, worn?.id == outfit.id),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _swatch(AppState state, Outfit outfit, String name, Color color) {
    final selected = outfit.chosenColor == name;
    return Pressable(
      onTap: () {
        Sfx.play('tap');
        state.setProfileData('oc_${outfit.id}', name);
      },
      child: Container(
        key: ValueKey('swatch_$name'),
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.ink : Colors.white,
            width: selected ? 4 : 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.25),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slot(AppState state, Outfit outfit, int stars, bool worn) {
    final open = stars >= outfit.stars;
    return Pressable(
      onTap: open
          ? () {
              // Takılı olana yeniden dokununca çıkarılır.
              state.setProfileData('outfit', worn ? null : outfit.id);
            }
          : () => Sfx.play('wrong'),
      child: Container(
        width: 104,
        height: 112,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: worn
              ? AppColors.green.withValues(alpha: 0.2)
              : open
              ? Colors.white
              : AppColors.grey.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: worn
                ? AppColors.green
                : open
                ? AppColors.yellow
                : AppColors.grey.withValues(alpha: 0.6),
            width: worn ? 5 : 3,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Opacity(
                opacity: open ? 1 : 0.35,
                child: OutfitImage(outfit),
              ),
            ),
            if (open)
              Icon(
                worn
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: worn ? AppColors.green : AppColors.grey,
                size: 22,
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.yellow,
                    size: 20,
                  ),
                  Text(
                    ' ${outfit.stars}',
                    style: titleStyle.copyWith(fontSize: 16, height: 1.2),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
