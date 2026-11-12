import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/legal.dart';
import '../data/stickers.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../services/purchases.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/legal_dialog.dart';
import '../widgets/ui.dart';
import 'home_screen.dart';
import 'paywall_screen.dart';
import 'profile_dialog.dart';
import 'report_screen.dart';

/// Ebeveyn alanı: çocuk profilleri, dil, ayarlar, abonelik, gelişim raporu ve
/// hakkında. Solda büyük sekmeler, sağda yalnızca seçilen bölüm görünür; böylece
/// telefonda da yazılar büyük ve sayfa sade kalır.
class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key, this.initialTab = 0});

  /// Açılışta seçili sekme (testler için).
  final int initialTab;

  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  static const _muted = Color(0xFF8A7B70);

  late int _tab = widget.initialTab;

  Future<bool> _confirm(BuildContext context, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FittedBox(
          child: SizedBox(
            width: 440,
            child: ToyPanel(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 84,
                    height: 84,
                    child: Mascot('thinking'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: titleStyle.copyWith(fontSize: 19),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      BigButton(
                        label: L.t('cancel'),
                        color: AppColors.blue,
                        fontSize: 18,
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                      BigButton(
                        label: L.t('yes'),
                        color: AppColors.red,
                        fontSize: 18,
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return ok ?? false;
  }

  void _showText(BuildContext context, String title, String body) =>
      showLegalText(context, title, body);

  Future<void> _editProfile(BuildContext context, Profile? profile) async {
    final result = await showProfileDialog(context, profile: profile);
    if (result == null || !context.mounted) return;
    final state = AppState.I;
    if (result.delete) {
      if (await _confirm(context, L.t('delete_confirm'))) {
        state.deleteProfile(profile!.id);
      }
    } else if (profile == null) {
      state.addProfile(result.name, result.avatar, result.age);
    } else {
      state.updateProfile(profile.id, result.name, result.avatar, result.age);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.I;
    return Scaffold(
      body: Stack(
        children: [
          const Backdrop('home'),
          // Manzara görünür kalır; kartlar okunaklı olsun diye hafif perde.
          Positioned.fill(
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.3)),
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
                        6,
                        14,
                        6,
                      ),
                      // Tasarım sabit boyutta kurulur, ekrana göre ölçeklenir.
                      child: FittedBox(
                        child: SizedBox(
                          width: 640,
                          height: 300,
                          child: _content(context),
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

  Widget _content(BuildContext context) {
    final tabs = [
      (L.t('profiles'), Icons.face_rounded, AppColors.orange),
      (L.t('language'), Icons.language_rounded, AppColors.blue),
      (L.t('settings'), Icons.tune_rounded, AppColors.pink),
      (L.t('subscription'), Icons.workspace_premium_rounded, AppColors.green),
      (L.t('report'), Icons.insights_rounded, AppColors.purple),
      (L.t('about'), Icons.info_rounded, AppColors.teal),
    ];
    final (title, icon, color) = tabs[_tab];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 176,
          child: Column(
            children: [
              SizedBox(
                height: 38,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: Mascot('happy'),
                      ),
                      const SizedBox(width: 6),
                      StrokeText(
                        L.t('parents'),
                        size: 22,
                        color: AppColors.yellow,
                      ),
                    ],
                  ),
                ),
              ),
              for (var i = 0; i < tabs.length; i++) ...[
                const SizedBox(height: 5),
                _tabButton(i, tabs[i].$1, tabs[i].$2, tabs[i].$3),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _card(title, icon, color, switch (_tab) {
            0 => _profiles(context),
            1 => _languages(),
            2 => _settings(context),
            3 => _subscription(context),
            4 => _report(context),
            _ => _about(context),
          }),
        ),
      ],
    );
  }

  /// Soldaki sekme düğmesi: seçiliyken kendi rengiyle dolar.
  Widget _tabButton(int index, String label, IconData icon, Color color) {
    final selected = index == _tab;
    return Pressable(
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        key: ValueKey('ptab_$index'),
        duration: const Duration(milliseconds: 150),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.white : color,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languages() {
    final state = AppState.I;
    return Center(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final entry in L.languages.entries)
            _languageTile(entry.key, entry.value, state.lang == entry.key),
        ],
      ),
    );
  }

  static const _chevron = Icon(
    Icons.chevron_right_rounded,
    color: _muted,
    size: 30,
  );

  /// Ayarlar: ses, müzik ve ilerlemeyi sıfırlama.
  Widget _settings(BuildContext context) {
    final state = AppState.I;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _row(
          L.t('sound'),
          icon: state.soundOn
              ? Icons.volume_up_rounded
              : Icons.volume_off_rounded,
          trailing: _Switch(value: state.soundOn, onChanged: state.setSound),
        ),
        const SizedBox(height: 10),
        _row(
          L.t('music'),
          icon: state.musicOn
              ? Icons.music_note_rounded
              : Icons.music_off_rounded,
          trailing: _Switch(
            value: state.musicOn,
            onChanged: (on) {
              state.setMusic(on);
              Music.sync();
            },
          ),
        ),
        const SizedBox(height: 10),
        _row(
          L.t('reset'),
          icon: Icons.restart_alt_rounded,
          tint: AppColors.red,
          trailing: _chevron,
          onTap: () async {
            if (await _confirm(context, L.t('reset_confirm'))) {
              state.resetProgress();
            }
          },
        ),
      ],
    );
  }

  /// Abonelik: durum, geri yükleme ve aboneliğin kazandırdıkları.
  Widget _subscription(BuildContext context) {
    final state = AppState.I;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _row(
          L.t(state.premium ? 'premium_active' : 'premium_inactive'),
          icon: Icons.workspace_premium_rounded,
          trailing: state.premium
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.green,
                  size: 34,
                )
              : _button(
                  L.t('get_premium'),
                  AppColors.green,
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PaywallScreen(),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        _row(
          L.t('restore'),
          icon: Icons.restore_rounded,
          trailing: _chevron,
          dense: true,
          onTap: Purchases.I.restore,
        ),
        const SizedBox(height: 8),
        // İptal ve plan değişikliği mağazada yapılır: iOS'ta mağazanın kendi
        // penceresi açılır, açılamazsa yol tarifi gösterilir.
        _row(
          L.t('sub_manage'),
          icon: Icons.manage_accounts_rounded,
          trailing: _chevron,
          dense: true,
          onTap: () async {
            final opened = await Purchases.I.manage();
            if (!opened && context.mounted) {
              _showText(
                context,
                L.t('sub_manage'),
                Purchases.legalText('sub_manage_text'),
              );
            }
          },
        ),
        const SizedBox(height: 8),
        // Aboneliğin nereden iptal edileceği her zaman görünür.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            children: [
              Icon(
                Icons.info_rounded,
                color: AppColors.ink.withValues(alpha: 0.55),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Purchases.whereToCancel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, height: 1.2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Gelişim raporu: özet sayılar ve ayrıntılı rapora geçiş.
  Widget _report(BuildContext context) {
    final state = AppState.I;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
        _row(
          L.t('report'),
          icon: Icons.insights_rounded,
          subtitle: state.profileName(state.profile),
          trailing: _chevron,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const ReportScreen())),
        ),
      ],
    );
  }

  /// Rapor özetindeki tek bir sayı kutusu.
  Widget _stat(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: titleStyle.copyWith(fontSize: 22, height: 1.2),
              ),
            ),
            // Uzun etiketler iki satıra bölünür; küçülüp okunmaz olmaz.
            SizedBox(
              height: 30,
              child: Center(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.15,
                    color: _muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hakkında: uygulamanın adı ve sürümü, altında yasal metinler.
  Widget _about(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            const SizedBox(width: 48, height: 48, child: Mascot('hello')),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Minik Kaşif',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle.copyWith(fontSize: 21, height: 1.15),
                  ),
                  Text(
                    L.t('app_sub'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.2,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${L.t('version')} $appVersion',
              style: const TextStyle(fontSize: 15, color: _muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _row(
          L.t('about_app'),
          icon: Icons.info_outline_rounded,
          dense: true,
          trailing: _chevron,
          onTap: () => _showText(context, 'Minik Kaşif', Legal.about),
        ),
        const SizedBox(height: 6),
        _row(
          L.t('privacy'),
          icon: Icons.shield_outlined,
          dense: true,
          trailing: _chevron,
          onTap: () => _showText(context, L.t('privacy'), Legal.privacy),
        ),
        const SizedBox(height: 6),
        _row(
          L.t('terms'),
          icon: Icons.description_outlined,
          dense: true,
          trailing: _chevron,
          onTap: () => _showText(context, L.t('terms'), Legal.terms),
        ),
      ],
    );
  }

  /// Profiller ve altında kısa bir açıklama.
  Widget _profiles(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _profileTiles(context),
        const SizedBox(height: 12),
        Text(
          L.t('profiles_hint'),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, height: 1.25, color: _muted),
        ),
      ],
    );
  }

  /// Çocuk profilleri: dokununca seçilir, kalemle düzenlenir.
  Widget _profileTiles(BuildContext context) {
    final state = AppState.I;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final p in state.profiles)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _profileTile(context, p, p.id == state.profile.id),
          ),
        if (state.profiles.length < AppState.maxProfiles)
          Pressable(
            onTap: () => _editProfile(context, null),
            child: Container(
              width: 94,
              height: 128,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.grey.withValues(alpha: 0.7),
                  width: 2.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      L.t('add_profile'),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle.copyWith(fontSize: 15, height: 1.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _profileTile(BuildContext context, Profile p, bool selected) {
    final state = AppState.I;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Pressable(
          onTap: () => state.switchProfile(p.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 94,
            height: 128,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.green.withValues(alpha: 0.16)
                  : AppColors.cream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? AppColors.green
                    : AppColors.grey.withValues(alpha: 0.5),
                width: selected ? 4 : 2.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Avatar(p, size: 60),
                const SizedBox(height: 4),
                Text(
                  state.profileName(p),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle.copyWith(fontSize: 17, height: 1.2),
                ),
                Text(
                  p.age > 0 ? L.t('age_n').replaceAll('{n}', '${p.age}') : '',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.1,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          end: -6,
          top: -6,
          child: Pressable(
            onTap: () => _editProfile(context, p),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Renkli başlıklı kart: oyundaki panellerle aynı aileden.
  Widget _card(String title, IconData icon, Color color, Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            color: color,
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(12), child: child),
          ),
        ],
      ),
    );
  }

  /// Ayar satırı: isteğe bağlı simge, başlık, açıklama ve sağda bir denetim.
  Widget _row(
    String title, {
    IconData? icon,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool dense = false,
    Color? tint,
  }) {
    final row = Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 7 : 12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: tint ?? AppColors.ink, size: 30),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle.copyWith(
                    fontSize: 20,
                    height: 1.25,
                    color: tint,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      color: _muted,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
    return onTap == null ? row : Pressable(onTap: onTap, child: row);
  }

  /// Alt kenarı koyu, oyundaki düğmelerle aynı aileden küçük düğme.
  Widget _button(
    String label,
    Color color,
    VoidCallback onTap, {
    bool outlined = false,
    IconData? icon,
  }) {
    final front = outlined ? color : Colors.white;
    final edge = Color.lerp(color, Colors.black, 0.2)!;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          color: outlined ? color : edge,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: outlined ? Colors.white : color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: front, size: 20),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: front,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageTile(String code, Language language, bool selected) {
    return Pressable(
      onTap: () => AppState.I.setLang(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 200,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green.withValues(alpha: 0.16)
              : AppColors.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.green
                : AppColors.grey.withValues(alpha: 0.5),
            width: selected ? 3.5 : 2,
          ),
        ),
        child: Row(
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                language.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle.copyWith(fontSize: 19),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: AppColors.green, size: 26),
          ],
        ),
      ),
    );
  }
}

/// Açma kapama düğmesi.
class _Switch extends StatelessWidget {
  const _Switch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 70,
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.green : AppColors.grey,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
