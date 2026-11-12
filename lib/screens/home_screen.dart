import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/objects.dart';
import '../data/stickers.dart';
import '../games/game_def.dart';
import '../games/registry.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/intro.dart';
import '../widgets/ui.dart';
import 'album_screen.dart';
import 'daily_screen.dart';
import 'level_screen.dart';
import 'parent_gate.dart';
import 'parents_screen.dart';
import 'profile_dialog.dart';

/// Profilin avatarı: beyaz daire içinde seçilen hayvan.
class Avatar extends StatelessWidget {
  const Avatar(
    this.profile, {
    super.key,
    this.size = 44,
    this.selected = false,
  });
  final Profile profile;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final object = gameObjects.firstWhere(
      (o) => o.id == profile.avatar,
      orElse: () => gameObjects.firstWhere((o) => o.id == 'cat'),
    );
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.green : AppColors.orange,
          width: size * (selected ? 0.1 : 0.07),
        ),
      ),
      child: ObjectImage(object),
    );
  }
}

/// Ana menü: konuşan maskot, günün macerası, albüm ve mini oyun kartları.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Testlerde ilk açılış sorusunu kapatmak için.
  static bool askProfile = true;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// İlk açılışta çocuğun adı ve yaşı sorulur, ardından Fıstık kendini tanıtır.
  Future<void> _firstRun() async {
    final state = AppState.I;
    if (HomeScreen.askProfile && !state.onboarded) {
      final edit = await showProfileDialog(
        context,
        profile: state.profile,
        firstRun: true,
      );
      if (edit != null) {
        state.updateProfile(state.profile.id, edit.name, edit.avatar, edit.age);
      }
      state.markOnboarded();
    }
    if (!mounted) return;
    if (Intro.enabled && !Intro.seen) {
      Intro.show(context);
    } else {
      // Tanışma daha önce yapıldıysa Fıstık balonundaki soruyu sorar.
      Tts.speak(L.t('pick_game'));
    }
  }

  final ScrollController _scroll = ScrollController();
  bool _moreToRight = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final more =
          _scroll.position.pixels < _scroll.position.maxScrollExtent - 20;
      if (more != _moreToRight) setState(() => _moreToRight = more);
    });
    // İlk açılışta Fıstık kendini tanıtır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _firstRun();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Her oyunun bölüm haritası herkese açıktır; ücretli bölümler haritada
  /// kilitli görünür.
  void _openGame(GameDef game) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // Serbest etkinliklerin bölüm haritası yoktur, doğrudan açılır.
        builder: (_) =>
            game.levels == 0 ? game.builder(game, 0) : LevelScreen(game: game),
      ),
    );
  }

  Future<void> _openParents() async {
    final navigator = Navigator.of(context);
    if (await showParentGate(context)) {
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const ParentsScreen()),
      );
    }
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  /// Birden fazla profil varsa çocuğun kendi profilini seçtiği pencere.
  void _pickProfile() {
    final state = AppState.I;
    if (state.profiles.length < 2) return;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FittedBox(
          child: ToyPanel(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final p in state.profiles)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Pressable(
                      onTap: () {
                        state.switchProfile(p.id);
                        Navigator.of(context).pop();
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Avatar(
                            p,
                            size: 96,
                            selected: p.id == state.profile.id,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.profileName(p),
                            style: titleStyle.copyWith(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
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
            child: ListenableBuilder(
              listenable: state,
              builder: (context, _) => Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(
                  children: [
                    SizedBox(width: 168, child: _mascotColumn()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          _topBar(),
                          const SizedBox(height: 4),
                          Expanded(child: LayoutBuilder(builder: _grid)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Üst şerit: profil, günün macerası ve çıkartma albümü.
  Widget _topBar() {
    final state = AppState.I;
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Pressable(
                onTap: _pickProfile,
                child: Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(4, 3, 14, 3),
                  decoration: panelDecoration(radius: 25),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Avatar(state.profile, size: 42),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 110),
                        child: Text(
                          state.profileName(state.profile),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle.copyWith(fontSize: 17),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.yellow,
                        size: 24,
                      ),
                      Text(
                        '${state.allStars}',
                        style: titleStyle.copyWith(fontSize: 17),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: _pill(
              icon: state.dailyComplete
                  ? Icons.check_circle_rounded
                  : Icons.card_giftcard_rounded,
              color: state.dailyComplete ? AppColors.green : AppColors.red,
              // Hedefe ulaşılana kadar bugünkü yıldız sayısı da görünür.
              label: state.dailyComplete || state.dailyStars == 0
                  ? L.t('daily')
                  : '${L.t('daily')}  ${state.dailyStars}/${AppState.dailyGoal}',
              pulse: !state.dailyComplete,
              onTap: () => _push(const DailyScreen()),
            ),
          ),
          const SizedBox(width: 10),
          _pill(
            icon: Icons.auto_stories_rounded,
            color: AppColors.purple,
            label: '${state.stickers.length}/${allStickers.length}',
            pulse: false,
            onTap: () => _push(const AlbumScreen()),
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required Color color,
    required String label,
    required bool pulse,
    required VoidCallback onTap,
  }) {
    final pill = Pressable(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Color.lerp(color, Colors.black, 0.28),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 2.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return FittedBox(fit: BoxFit.scaleDown, child: pill);
  }

  /// Sol sütun: konuşma balonu, maskot ve ayar butonları.
  Widget _mascotColumn() {
    final state = AppState.I;
    return Column(
      children: [
        // Balon maskotun hemen üstünde durur, ikisi birlikte ortalanır.
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpeechBubble(
                tail: BubbleTail.bottom,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  L.t('pick_game'),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle.copyWith(fontSize: 16),
                ),
              ),
              Flexible(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Pressable(
                    // Fıstık'a dokununca tanışma konuşması yeniden oynar.
                    onTap: () => Intro.show(context),
                    child: const WavingMascot(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RoundButton(
              icon: state.soundOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: state.soundOn ? AppColors.pink : AppColors.grey,
              asset: state.soundOn ? 'btn_sound_on' : 'btn_sound_off',
              size: 56,
              onTap: () => state.setSound(!state.soundOn),
            ),
            RoundButton(
              icon: Icons.settings_rounded,
              color: AppColors.teal,
              asset: 'btn_parents',
              size: 56,
              onTap: _openParents,
            ),
          ],
        ),
      ],
    );
  }

  /// Alan yeterince yüksekse (tabletler) üç, değilse (telefonlar) iki sıra.
  /// Üç sırada kart en az 150 birim yüksek kalmalıdır; daha küçüğü küçük
  /// parmaklar için dar bir hedeftir.
  static int rowsFor(double height) =>
      (height - _gridTop - _gridGap * 2 - 8) / 3 >= 150 ? 3 : 2;

  static const _gridGap = 12.0;
  static const _gridTop = 10.0;

  /// Yana kaydırılan oyun kartları.
  Widget _grid(BuildContext context, BoxConstraints box) {
    const gap = _gridGap;
    const topPad = _gridTop;
    final rows = rowsFor(box.maxHeight);
    final cardHeight = (box.maxHeight - topPad - gap * (rows - 1) - 8) / rows;
    // Dördüncü sütundan sonrası yarım görünür; kaydırılabildiği anlaşılır.
    final cardWidth = min(cardHeight * 1.05, (box.maxWidth - gap * 4) / 4.4);
    final entries = [...games, ...activities];
    final columns = (entries.length / rows).ceil();
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(top: topPad, right: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < columns; c++)
                Padding(
                  padding: EdgeInsets.only(left: c == 0 ? 0 : gap),
                  child: Column(
                    children: [
                      for (
                        var i = c * rows;
                        i < min(c * rows + rows, entries.length);
                        i++
                      )
                        Padding(
                          padding: EdgeInsets.only(
                            top: i % rows == 0 ? 0 : gap,
                          ),
                          child: PopIn(
                            delay: i,
                            child: _card(entries[i], cardWidth, cardHeight),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (_moreToRight)
          PositionedDirectional(
            end: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Center(
                child: Bobbing(
                  distance: 0,
                  pulse: 0.12,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.ink,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _card(GameDef game, double width, double height) {
    final state = AppState.I;
    final edge = Color.lerp(game.color, Colors.black, 0.25)!;
    return Pressable(
      onTap: () => _openGame(game),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Alt kenarı koyu, "oyuncak blok" görünümlü kart. İkon düz beyaz bir
            // kutuda değil, renkli zeminde parlayan bir ışık halkasında durur.
            Container(
              padding: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: edge,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(game.color, Colors.white, 0.45)!,
                      game.color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 3,
                  ),
                ),
                child: CustomPaint(
                  painter: const _CardPatternPainter(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                    child: Column(
                      children: [
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: Opacity(
                              opacity: 1,
                              child: GameImage(
                                'assets/images/icons/game_${game.id}.png',
                                fallback: Emoji(game.emoji),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 26,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: StrokeText(
                              L.t('g_${game.id}'),
                              size: 17,
                              stroke: edge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (game.levels > 0)
              Positioned(
                top: -8,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 1,
                  ),
                  decoration: panelDecoration(radius: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.yellow,
                        size: 20,
                      ),
                      Text(
                        '${state.totalStars(game.id)}',
                        style: titleStyle.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kart zemini: ikonun arkasında yumuşak bir ışık halkası ve köşelerde
/// yarı saydam baloncuklar.
class _CardPatternPainter extends CustomPainter {
  const _CardPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, (size.height - 28) / 2);
    final radius = min(size.width, size.height - 28) * 0.52;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.75),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.72, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    final bubble = Paint()..color = Colors.white.withValues(alpha: 0.28);
    final w = size.width;
    final h = size.height;
    for (final (x, y, r) in [
      (0.08, 0.1, 0.07),
      (0.2, 0.04, 0.035),
      (0.93, 0.16, 0.05),
      (0.06, 0.72, 0.045),
      (0.95, 0.66, 0.08),
      (0.86, 0.8, 0.03),
    ]) {
      canvas.drawCircle(Offset(w * x, h * y), w * r, bubble);
    }
  }

  @override
  bool shouldRepaint(_CardPatternPainter old) => false;
}
