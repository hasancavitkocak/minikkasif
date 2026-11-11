import 'package:flutter/material.dart';

import '../app_state.dart';
import '../games/game_def.dart';
import '../games/registry.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import '../widgets/ui.dart';

/// Günün macerası: her gün değişen üç bölümlük görev. Üçü de bitince
/// fazladan bir çıkartma kazanılır.
class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Tts.speak(L.t(AppState.I.dailyComplete ? 'daily_done' : 'daily_bubble'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Backdrop('home'),
          Positioned.fill(
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.25)),
          ),
          SafeArea(
            child: ListenableBuilder(
              listenable: AppState.I,
              builder: (context, _) {
                final state = AppState.I;
                final tasks = state.dailyTasks(games);
                final done = state.dailyDone;
                // Görevler sırayla yapılır.
                var current = 0;
                while (current < tasks.length && done.contains(current)) {
                  current++;
                }
                return Stack(
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StrokeText(
                                  L.t('daily'),
                                  size: 34,
                                  color: AppColors.yellow,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Bobbing(
                                      child: SizedBox(
                                        width: 86,
                                        height: 86,
                                        child: Mascot(
                                          state.dailyComplete
                                              ? 'happy'
                                              : 'hello',
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      child: SpeechBubble(
                                        child: Text(
                                          L.t(
                                            state.dailyComplete
                                                ? 'daily_done'
                                                : 'daily_bubble',
                                          ),
                                          style: titleStyle.copyWith(
                                            fontSize: 19,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (
                                        var i = 0;
                                        i < tasks.length;
                                        i++
                                      ) ...[
                                        _taskCard(
                                          context,
                                          tasks[i],
                                          i,
                                          done.contains(i),
                                          i == current,
                                        ),
                                        const _Dots(),
                                      ],
                                      _gift(state.dailyComplete),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskCard(
    BuildContext context,
    DailyTask task,
    int index,
    bool done,
    bool current,
  ) {
    final GameDef game = games.firstWhere((g) => g.id == task.gameId);
    final card = Pressable(
      onTap: current
          ? () {
              // Bölüm bitince sıradaki göreve geçilir (bkz. GameShell).
              GameShell.dailyRun = true;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => game.builder(game, task.level),
                ),
              );
            }
          : null,
      child: Opacity(
        opacity: done || current ? 1 : 0.6,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 168,
              height: 176,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color.lerp(game.color, Colors.white, 0.55),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: current ? AppColors.yellow : Colors.white,
                  width: current ? 6 : 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: GameImage(
                      'assets/images/icons/game_${game.id}.png',
                      fallback: Emoji(game.emoji),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StrokeText(
                      L.t('g_${game.id}'),
                      size: 17,
                      stroke: Color.lerp(game.color, Colors.black, 0.3)!,
                    ),
                  ),
                ],
              ),
            ),
            // Bölüm numarası.
            Positioned(
              top: -10,
              left: -10,
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: game.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Text(
                  '${task.level}',
                  style: titleStyle.copyWith(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
            if (done)
              const Positioned(
                top: -12,
                right: -12,
                child: PopIn(
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.green,
                      size: 46,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return current ? Glow(radius: 26, child: card) : card;
  }

  Widget _gift(bool opened) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: opened ? AppColors.green : AppColors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        opened ? Icons.check_rounded : Icons.card_giftcard_rounded,
        color: Colors.white,
        size: 60,
      ),
    );
  }
}

/// Görevleri birbirine bağlayan noktalar.
class _Dots extends StatelessWidget {
  const _Dots();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
