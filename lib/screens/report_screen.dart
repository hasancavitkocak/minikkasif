import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/stickers.dart';
import '../games/registry.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'home_screen.dart';

/// Bir beceri alanı ve onu geliştiren oyunlar.
class Skill {
  const Skill(this.key, this.icon, this.color, this.gameIds);
  final String key;
  final IconData icon;
  final Color color;
  final List<String> gameIds;
}

const skills = <Skill>[
  Skill('sk_memory', Icons.psychology_rounded, AppColors.blue, [
    'memory',
    'simon',
  ]),
  Skill('sk_attention', Icons.visibility_rounded, AppColors.orange, [
    'odd',
    'diff',
    'shadow',
  ]),
  Skill('sk_logic', Icons.extension_rounded, AppColors.purple, [
    'pattern',
    'sort',
    'groups',
    'maze',
  ]),
  Skill('sk_numbers', Icons.pin_rounded, AppColors.green, [
    'count',
    'shapes',
    'dots',
  ]),
  Skill('sk_creative', Icons.brush_rounded, AppColors.pink, [
    'puzzle',
    'color',
  ]),
];

/// Gelişim raporu: seçili profilin beceri alanlarına göre ilerlemesi.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  /// Becerinin oyunlarında kazanılan yıldızların, kazanılabilecek toplam
  /// yıldıza oranı (0..1).
  static double progress(Skill skill) {
    var earned = 0;
    var possible = 0;
    for (final game in games) {
      if (!skill.gameIds.contains(game.id)) continue;
      earned += AppState.I.totalStars(game.id);
      possible += game.levels * 3;
    }
    return possible == 0 ? 0 : earned / possible;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    return Scaffold(
      body: Stack(
        children: [
          const Backdrop('meadow'),
          SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(72, 8, 16, 8),
                    child: FittedBox(
                      child: SizedBox(
                        width: 800,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Avatar(state.profile, size: 50),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: StrokeText(
                                      '${state.profileName(state.profile)} · ${L.t('report')}',
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _stat(
                                  Icons.flag_rounded,
                                  AppColors.blue,
                                  '${state.completedLevels}',
                                  L.t('st_levels'),
                                ),
                                _stat(
                                  Icons.star_rounded,
                                  AppColors.yellow,
                                  '${state.allStars}',
                                  L.t('st_stars'),
                                ),
                                _stat(
                                  Icons.auto_stories_rounded,
                                  AppColors.purple,
                                  '${state.stickers.length}/${allStickers.length}',
                                  L.t('st_stickers'),
                                ),
                                _stat(
                                  Icons.calendar_month_rounded,
                                  AppColors.green,
                                  '${state.playsThisWeek}',
                                  L.t('st_week'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ToyPanel(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              child: Column(
                                children: [
                                  for (final skill in skills) _skillRow(skill),
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

  Widget _stat(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ToyPanel(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          radius: 22,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 30),
                  const SizedBox(width: 6),
                  Text(value, style: titleStyle.copyWith(fontSize: 26)),
                ],
              ),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skillRow(Skill skill) {
    final value = progress(skill);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: skill.color,
              shape: BoxShape.circle,
            ),
            child: Icon(skill.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 230,
            child: Text(
              L.t(skill.key),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleStyle.copyWith(fontSize: 18),
            ),
          ),
          Expanded(
            child: Container(
              height: 22,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: skill.color,
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              AppState.I.lang == 'tr'
                  ? '%${(value * 100).round()}'
                  : '${(value * 100).round()}%',
              textAlign: TextAlign.end,
              style: titleStyle.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
