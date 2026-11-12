import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

/// Solda bir soru görseli, sağda seçenekler: doğru seçeneğe dokunulur.
/// Meslekler ve mevsimler oyunları bu düzeni kullanır.
class QuizRound extends StatelessWidget {
  const QuizRound({
    super.key,
    required this.prompt,
    required this.options,
    required this.answer,
    required this.onSolved,
    required this.onMistake,
  });

  final Widget prompt;
  final List<Widget> options;

  /// Doğru seçeneğin [options] içindeki sırası.
  final int answer;
  final VoidCallback onSolved;
  final VoidCallback onMistake;

  bool _pick(int i) {
    if (i != answer) {
      onMistake();
      return false;
    }
    onSolved();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // Soru solda, seçenekler sağda yan yana durur: yatay ekranda yükseklik
        // dar olduğu için alt alta dizince resimler küçük kalıyordu.
        const gap = 14.0;
        final promptSize = min(box.maxHeight * 0.86, box.maxWidth * 0.27);
        final room = box.maxWidth - promptSize - gap * 3;
        final optionSize = min(
          box.maxHeight * 0.86,
          (room - gap * (options.length - 1)) / options.length,
        );
        return Row(
          children: [
            const SizedBox(width: gap),
            Container(
              width: promptSize,
              height: promptSize,
              padding: EdgeInsets.all(promptSize * 0.06),
              decoration: panelDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                radius: promptSize * 0.2,
              ),
              child: prompt,
            ),
            const SizedBox(width: gap),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < options.length; i++)
                    ChoiceTile(
                      size: optionSize,
                      padding: 0.06,
                      onTap: () => _pick(i),
                      child: options[i],
                    ),
                ],
              ),
            ),
            const SizedBox(width: gap),
          ],
        );
      },
    );
  }
}

/// Art arda aynı sorunun gelmemesi için son sorulanları hatırlar.
class RecentPicker {
  RecentPicker(this.window);
  final int window;
  final List<int> _recent = [];

  /// 0..[count) aralığından, son sorulanlar dışında rastgele bir sıra.
  int pick(Random rng, int count) {
    final fresh = [
      for (var i = 0; i < count; i++)
        if (!_recent.contains(i)) i,
    ];
    final choice = fresh.isEmpty
        ? rng.nextInt(count)
        : fresh[rng.nextInt(fresh.length)];
    _recent.add(choice);
    while (_recent.length > min(window, count - 1)) {
      _recent.removeAt(0);
    }
    return choice;
  }
}

/// Tanıtım kartı: resim, ad ve kısa bir cümle; ikisi de sesli okunur. İleri
/// okuna basınca tur biter. Soru sorulmadan önce konu böyle tanıtılır.
class LearnRound extends StatefulWidget {
  const LearnRound({
    super.key,
    required this.image,
    required this.nameKey,
    required this.textKey,
    this.extras = const [],
    this.companion,
    required this.first,
    required this.onDone,
  });

  final Widget image;

  /// Resmin sağ alt köşesinde, çerçeveden taşarak duran büyük figür
  /// (mevsimlerde o mevsime göre giyinmiş Fıstık).
  final Widget? companion;

  /// Adın ve tanıtım cümlesinin çeviri anahtarları (ses kayıtları da bu adla).
  final String nameKey;
  final String textKey;

  /// Altta gösterilen küçük resimler (mesleğin aracı, mevsimin giysileri).
  final List<Widget> extras;

  /// Bölümün ilk kartı mı? İlk kartta yönerge okunduğu için ad biraz bekleyip
  /// söylenir.
  final bool first;
  final VoidCallback onDone;

  @override
  State<LearnRound> createState() => _LearnRoundState();
}

class _LearnRoundState extends State<LearnRound> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: widget.first ? 2400 : 600), () {
      if (mounted) _say();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    Tts.stopFor(this);
    super.dispose();
  }

  /// Adı, ardından tanıtım cümlesini söyler.
  void _say() => Tts.speakKeys([widget.nameKey, widget.textKey], owner: this);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final picture = min(box.maxHeight * 0.92, box.maxWidth * 0.36);
        final extra = min(box.maxHeight * 0.24, box.maxWidth * 0.085);
        final companion = widget.companion;
        // Figür resmin üçte ikisi boyundadır ve yarısı çerçevenin dışındadır.
        final figure = picture * 0.66;
        final overhang = companion == null ? 0.0 : figure * 0.5;
        return Row(
          children: [
            const SizedBox(width: 8),
            // Resme dokununca yeniden anlatılır.
            Pressable(
              onTap: _say,
              child: SizedBox(
                width: picture + overhang,
                height: picture,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: picture,
                      height: picture,
                      padding: EdgeInsets.all(picture * 0.06),
                      decoration: panelDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        radius: picture * 0.18,
                      ),
                      child: widget.image,
                    ),
                    if (companion != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        width: figure,
                        height: figure,
                        child: companion,
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: StrokeText(
                        L.t(widget.nameKey),
                        size: 40,
                        color: AppColors.yellow,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: panelDecoration(radius: 16),
                      child: Text(
                        L.t(widget.textKey),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle.copyWith(
                          fontSize: 19,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (widget.extras.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final item in widget.extras)
                            Container(
                              width: extra,
                              height: extra,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: EdgeInsets.all(extra * 0.1),
                              decoration: panelDecoration(radius: extra * 0.25),
                              child: item,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            RoundButton(
              key: const ValueKey('learn_next'),
              icon: Icons.arrow_forward_rounded,
              color: AppColors.green,
              size: 72,
              onTap: widget.onDone,
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}
