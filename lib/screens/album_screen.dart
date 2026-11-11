import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/stickers.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

/// Çıkartma albümü: bölümleri bitirdikçe kazanılan çıkartmalar üç temalı
/// sayfada toplanır.
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  static const _backdrops = {'farm': 'meadow', 'sea': 'sea', 'space': 'space'};
  static const _colors = {
    'farm': AppColors.green,
    'sea': AppColors.blue,
    'space': AppColors.purple,
  };

  String _page = stickerPages.first;

  @override
  Widget build(BuildContext context) {
    final owned = AppState.I.stickers;
    final stickers = [
      for (final s in allStickers)
        if (s.page == _page) s,
    ];
    return Scaffold(
      body: Stack(
        children: [
          Backdrop(_backdrops[_page]!),
          SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(72, 8, 16, 8),
                    // Tasarım sabit genişlikte kurulur, ekrana göre ölçeklenir.
                    child: FittedBox(
                      child: SizedBox(
                        width: 780,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                StrokeText(L.t('album'), size: 32),
                                const SizedBox(width: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 2,
                                  ),
                                  decoration: panelDecoration(radius: 18),
                                  child: Text(
                                    '${owned.length}/${allStickers.length}',
                                    style: titleStyle.copyWith(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final page in stickerPages)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Opacity(
                                      opacity: page == _page ? 1 : 0.7,
                                      child: BigButton(
                                        label: L.t('page_$page'),
                                        color: _colors[page]!,
                                        fontSize: page == _page ? 19 : 16,
                                        onTap: () =>
                                            setState(() => _page = page),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ToyPanel(
                              border: _colors[_page]!,
                              padding: const EdgeInsets.all(14),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (final (i, sticker) in stickers.indexed)
                                    _slot(
                                      sticker,
                                      owned.contains(sticker.id),
                                      i,
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
                const PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: BackRoundButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slot(Sticker sticker, bool owned, int index) {
    const size = 110.0;
    if (!owned) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.grey.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.grey.withValues(alpha: 0.6),
            width: 3,
          ),
        ),
        child: Center(
          child: Text(
            '?',
            style: titleStyle.copyWith(fontSize: 44, color: AppColors.grey),
          ),
        ),
      );
    }
    return PopIn(
      key: ValueKey('$_page-${sticker.id}'),
      delay: index,
      // Dokununca çıkartma büyüyerek açılır.
      child: Pressable(
        onTap: () => _showBig(sticker),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.yellow, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.2),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: StickerImage(sticker),
        ),
      ),
    );
  }

  void _showBig(Sticker sticker) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: AppColors.ink.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (context, animation, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: animation, child: child),
      ),
      pageBuilder: (context, _, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: FractionallySizedBox(
            heightFactor: 0.78,
            child: AspectRatio(
              aspectRatio: 1,
              child: Bobbing(
                distance: 8,
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _colors[_page]!, width: 8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellow.withValues(alpha: 0.7),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: StickerImage(sticker),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
