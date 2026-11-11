import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/legal.dart';
import '../l10n.dart';
import '../services/audio.dart';
import '../services/purchases.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'home_screen.dart';
import 'paywall_screen.dart';
import 'profile_dialog.dart';
import 'report_screen.dart';

/// Ebeveyn alanı: çocuk profilleri, gelişim raporu, dil, ses, abonelik ve
/// hakkında. Oyunun görünümünü taşır (manzara, renkli başlıklı kartlar) ama
/// yetişkin için düzenli ve okunaklıdır.
class ParentsScreen extends StatelessWidget {
  const ParentsScreen({super.key});

  static const _muted = Color(0xFF8A7B70);

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

  /// Hakkında, gizlilik politikası ya da kullanım koşulları penceresi.
  void _showText(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ToyPanel(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: titleStyle.copyWith(fontSize: 22),
                      ),
                    ),
                    RoundButton(
                      icon: Icons.close_rounded,
                      color: AppColors.red,
                      size: 42,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          body,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ),
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
                      // Tasarım sabit genişlikte kurulur, ekrana göre ölçeklenir.
                      child: FittedBox(
                        child: SizedBox(width: 860, child: _content(context)),
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
    final state = AppState.I;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 52, height: 52, child: Mascot('happy')),
            const SizedBox(width: 8),
            StrokeText(L.t('parents'), size: 32, color: AppColors.yellow),
          ],
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  children: [
                    _card(
                      L.t('profiles'),
                      Icons.face_rounded,
                      AppColors.orange,
                      _profiles(context),
                    ),
                    const SizedBox(height: 10),
                    _card(
                      L.t('language'),
                      Icons.language_rounded,
                      AppColors.blue,
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in L.languages.entries)
                            _languageTile(
                              entry.key,
                              entry.value,
                              state.lang == entry.key,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _card(
                        L.t('about'),
                        Icons.info_rounded,
                        AppColors.teal,
                        _about(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 9,
                child: Column(
                  children: [
                    _card(
                      L.t('report'),
                      Icons.insights_rounded,
                      AppColors.purple,
                      _row(
                        state.profileName(state.profile),
                        subtitle: L
                            .t('plays_week')
                            .replaceAll('{n}', '${state.playsThisWeek}'),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: _muted,
                          size: 30,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ReportScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _card(
                      L.t('settings'),
                      Icons.tune_rounded,
                      AppColors.pink,
                      Column(
                        children: [
                          _row(
                            L.t('sound'),
                            icon: state.soundOn
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            trailing: _Switch(
                              value: state.soundOn,
                              onChanged: state.setSound,
                            ),
                          ),
                          const SizedBox(height: 6),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _card(
                        L.t('subscription'),
                        Icons.workspace_premium_rounded,
                        AppColors.green,
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _row(
                              L.t(
                                state.premium
                                    ? 'premium_active'
                                    : 'premium_inactive',
                              ),
                              trailing: state.premium
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.green,
                                      size: 30,
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
                            const SizedBox(height: 6),
                            _row(
                              L.t('restore'),
                              icon: Icons.restore_rounded,
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: _muted,
                                size: 26,
                              ),
                              onTap: Purchases.I.restore,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Hakkında: yasal metinler, sürüm ve ilerlemeyi sıfırlama.
  Widget _about(BuildContext context) {
    final state = AppState.I;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _button(
              L.t('about_app'),
              AppColors.teal,
              () => _showText(context, 'Minik Kaşif', Legal.about),
              outlined: true,
            ),
            _button(
              L.t('privacy'),
              AppColors.teal,
              () => _showText(context, L.t('privacy'), Legal.privacy),
              outlined: true,
            ),
            _button(
              L.t('terms'),
              AppColors.teal,
              () => _showText(context, L.t('terms'), Legal.terms),
              outlined: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '${L.t('version')} $appVersion',
                style: const TextStyle(fontSize: 14, color: _muted),
              ),
            ),
            Flexible(
              child: _button(
                L.t('reset'),
                AppColors.red,
                () async {
                  if (await _confirm(context, L.t('reset_confirm'))) {
                    state.resetProgress();
                  }
                },
                outlined: true,
                icon: Icons.restart_alt_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Çocuk profilleri: dokununca seçilir, kalemle düzenlenir.
  Widget _profiles(BuildContext context) {
    final state = AppState.I;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in state.profiles)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: _profileTile(context, p, p.id == state.profile.id),
          ),
        if (state.profiles.length < AppState.maxProfiles)
          Pressable(
            onTap: () => _editProfile(context, null),
            child: Container(
              width: 92,
              height: 108,
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
                      style: titleStyle.copyWith(fontSize: 13, height: 1.1),
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
            width: 92,
            height: 108,
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
                Avatar(p, size: 50),
                const SizedBox(height: 2),
                Text(
                  state.profileName(p),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle.copyWith(fontSize: 15, height: 1.2),
                ),
                Text(
                  p.age > 0 ? L.t('age_n').replaceAll('{n}', '${p.age}') : '',
                  style: const TextStyle(
                    fontSize: 12,
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
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 15,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            color: color,
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(10), child: child),
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
  }) {
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.ink, size: 24),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle.copyWith(fontSize: 17, height: 1.25),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
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
  static Widget _button(
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: outlined ? Colors.white : color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: front, size: 18),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
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
        width: 138,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
            Text(language.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                language.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle.copyWith(fontSize: 15),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: AppColors.green, size: 20),
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
        width: 58,
        height: 32,
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
            width: 22,
            height: 22,
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
