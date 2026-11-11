import 'package:flutter/material.dart';

import '../app_state.dart';
import '../games/game_def.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

/// Bir oyunun bütün bölümleri bitirildi mi?
bool gameCompleted(GameDef game) {
  for (var level = 1; level <= game.levels; level++) {
    if (AppState.I.stars(game.id, level) == 0) return false;
  }
  return game.levels > 0;
}

/// Başarı belgesi: oyunun tüm bölümlerini bitiren çocuğun adıyla gösterilir.
/// Ebeveyn ekran görüntüsünü alıp saklayabilir ya da paylaşabilir.
Future<void> showCertificate(BuildContext context, GameDef game) {
  final state = AppState.I;
  final now = DateTime.now();
  final date =
      '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  Sfx.play('win');
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.6),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: FittedBox(
        child: SizedBox(
          width: 620,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Çift çerçeveli, köşeleri yıldızlı belge kâğıdı.
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.orange, width: 5),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 150,
                        height: 170,
                        child: SpeakOnce('cert_title', child: Mascot('happy')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StrokeText(
                              L.t('cert_title'),
                              size: 34,
                              color: AppColors.yellow,
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                state.profileName(state.profile),
                                style: titleStyle.copyWith(
                                  fontSize: 38,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                            Text(
                              L
                                  .t('cert_text')
                                  .replaceAll('{game}', L.t('g_${game.id}')),
                              textAlign: TextAlign.center,
                              style: titleStyle.copyWith(
                                fontSize: 19,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.yellow,
                                    size: 34,
                                  ),
                                  Text(
                                    ' ${state.totalStars(game.id)} / ${game.levels * 3}',
                                    style: titleStyle.copyWith(fontSize: 22),
                                  ),
                                  const SizedBox(width: 18),
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF8A7B70),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 84,
                        height: 84,
                        child: GameImage(
                          'assets/images/icons/game_${game.id}.png',
                          fallback: Emoji(game.emoji),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                top: -14,
                end: -14,
                child: RoundButton(
                  icon: Icons.close_rounded,
                  color: AppColors.red,
                  size: 46,
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
