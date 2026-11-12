import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/stories.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'parent_gate.dart';
import 'paywall_screen.dart';

/// Hikâyeler: çocuk bir hikâye seçer, Fıstık sayfa sayfa anlatır.
class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  Future<void> _open(int index) async {
    final navigator = Navigator.of(context);
    if (index > 0 && !AppState.I.premium) {
      // İlk hikâye ücretsiz; diğerleri abonelikle açılır.
      if (await showParentGate(context)) {
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
        );
      }
      return;
    }
    final finished = await navigator.push<bool>(
      MaterialPageRoute<bool>(builder: (_) => StoryReader(stories[index])),
    );
    if (finished == true && mounted) {
      Tts.speakKeys(['story_end'], owner: this);
    }
  }

  @override
  void dispose() {
    Tts.stopFor(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Backdrop('home'),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                children: [
                  SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        const BackRoundButton(),
                        const SizedBox(width: 6),
                        const SizedBox(
                          width: 64,
                          height: 64,
                          child: SpeakOnce(
                            'story_hint',
                            before: 'g_story',
                            child: Mascot('hello'),
                          ),
                        ),
                        Flexible(
                          child: SpeechBubble(
                            child: Text(
                              L.t('story_hint'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle.copyWith(
                                fontSize: 17,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: AppState.I,
                      builder: (context, _) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < stories.length; i++)
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: _card(i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hikâye kartı: kapak resmi (ilk sayfa) ve adı.
  Widget _card(int index) {
    final story = stories[index];
    final locked = index > 0 && !AppState.I.premium;
    return Pressable(
      onTap: () => _open(index),
      child: AspectRatio(
        aspectRatio: 1.25,
        child: Container(
          key: ValueKey('story_$index'),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.yellow, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: locked ? 0.5 : 1,
                      child: StoryPicture(story, 0),
                    ),
                    if (locked)
                      const Center(
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: GameImage(
                            'assets/images/ui/lock.png',
                            fallback: FittedBox(
                              child: Icon(
                                Icons.lock_rounded,
                                color: AppColors.orange,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  story.localTitle,
                  maxLines: 1,
                  style: titleStyle.copyWith(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hikâyenin bir sayfasının resmi; görsel yoksa renkli zeminde bir simge.
class StoryPicture extends StatelessWidget {
  const StoryPicture(this.story, this.page, {super.key});
  final Story story;
  final int page;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: GameImage(
          story.image(page),
          fit: BoxFit.cover,
          fallback: ColoredBox(
            color: const Color(0xFFCDEBFF),
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 0.7,
                child: Emoji(story.emojis[page]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hikâyeyi sayfa sayfa gösterir ve her sayfayı sesli okur.
class StoryReader extends StatefulWidget {
  const StoryReader(this.story, {super.key});
  final Story story;

  @override
  State<StoryReader> createState() => _StoryReaderState();
}

class _StoryReaderState extends State<StoryReader> {
  int _page = 0;

  Story get story => widget.story;
  bool get _last => _page == story.pages.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _read();
    });
  }

  @override
  void dispose() {
    Tts.stopFor(this);
    super.dispose();
  }

  /// Açık sayfayı sesli okur.
  void _read() {
    Tts.speak(story.text(_page), owner: this, key: story.voiceKey(_page));
  }

  void _go(int page) {
    setState(() => _page = page);
    _read();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Backdrop('meadow'),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                children: [
                  Expanded(
                    // Sayfalar her dilde soldan sağa çevrilir.
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: [
                          const Align(
                            alignment: Alignment.topCenter,
                            child: BackRoundButton(),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: _page == 0
                                ? null
                                : RoundButton(
                                    icon: Icons.arrow_back_ios_new_rounded,
                                    color: AppColors.blue,
                                    onTap: () => _go(_page - 1),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 1.5,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.ink.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: StoryPicture(
                                      story,
                                      _page,
                                      key: ValueKey(_page),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Son sayfada ileri oku yerine "bitti" düğmesi.
                          RoundButton(
                            key: const ValueKey('story_next'),
                            icon: _last
                                ? Icons.check_rounded
                                : Icons.arrow_forward_ios_rounded,
                            color: _last ? AppColors.green : AppColors.blue,
                            onTap: () => _last
                                ? Navigator.of(context).pop(true)
                                : _go(_page + 1),
                          ),
                          const SizedBox(width: 62),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < story.pages.length; i++)
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _page
                                ? AppColors.orange
                                : Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: panelDecoration(radius: 20),
                    child: Row(
                      children: [
                        RoundButton(
                          icon: Icons.volume_up_rounded,
                          color: AppColors.orange,
                          size: 44,
                          onTap: _read,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            story.text(_page),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle.copyWith(
                              fontSize: 19,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}
