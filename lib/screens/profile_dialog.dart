import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/objects.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'home_screen.dart';

/// Profil penceresinin sonucu.
class ProfileEdit {
  const ProfileEdit(this.name, this.avatar, this.age, {this.delete = false});
  final String name;
  final String avatar;

  /// Çocuğun yaşı; seçilmediyse 0.
  final int age;
  final bool delete;
}

/// Profil ekleme ya da düzenleme penceresi. [profile] boşsa yeni profil.
/// [firstRun] ilk açılıştaki tanışma sorusudur: vazgeçilemez, başlığı vardır.
Future<ProfileEdit?> showProfileDialog(
  BuildContext context, {
  Profile? profile,
  bool firstRun = false,
}) {
  return showDialog<ProfileEdit>(
    context: context,
    barrierDismissible: !firstRun,
    builder: (_) => _ProfileDialog(profile: profile, firstRun: firstRun),
  );
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({this.profile, required this.firstRun});
  final Profile? profile;
  final bool firstRun;

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  static const _ages = [3, 4, 5, 6];

  late final TextEditingController _name = TextEditingController(
    text: widget.profile?.name ?? '',
  );
  late String _avatar = widget.profile?.avatar ?? 'rabbit';
  late int _age = widget.profile?.age ?? 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() =>
      Navigator.of(context).pop(ProfileEdit(_name.text.trim(), _avatar, _age));

  @override
  Widget build(BuildContext context) {
    final animals = [
      for (final o in gameObjects)
        if (o.category == 1) o,
    ];
    final firstRun = widget.firstRun;
    final canDelete =
        !firstRun && widget.profile != null && AppState.I.profiles.length > 1;
    return PopScope(
      canPop: !firstRun,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 560,
              child: ToyPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (firstRun) ...[
                      Text(
                        L.t('setup_title'),
                        textAlign: TextAlign.center,
                        style: titleStyle.copyWith(fontSize: 24),
                      ),
                      Text(
                        L.t('setup_hint'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            child: TextField(
                              controller: _name,
                              maxLength: 12,
                              textAlign: TextAlign.center,
                              textCapitalization: TextCapitalization.words,
                              style: titleStyle.copyWith(fontSize: 22),
                              decoration: InputDecoration(
                                hintText: L.t('name'),
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: AppColors.grey,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          L.t('age'),
                          style: titleStyle.copyWith(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        // Yaş her dilde aynı sırada durur.
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: [
                              for (final age in _ages)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Pressable(
                                    onTap: () => setState(() => _age = age),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      width: 46,
                                      height: 46,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _age == age
                                            ? AppColors.green
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _age == age
                                              ? AppColors.green
                                              : AppColors.grey,
                                          width: 3,
                                        ),
                                      ),
                                      child: Text(
                                        '$age',
                                        style: titleStyle.copyWith(
                                          fontSize: 22,
                                          color: _age == age
                                              ? Colors.white
                                              : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final animal in animals)
                          Pressable(
                            onTap: () => setState(() => _avatar = animal.id),
                            child: Avatar(
                              Profile(-1, '', animal.id),
                              size: 54,
                              selected: _avatar == animal.id,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (canDelete)
                          BigButton(
                            label: L.t('delete'),
                            color: AppColors.red,
                            fontSize: 17,
                            onTap: () => Navigator.of(context).pop(
                              ProfileEdit(
                                _name.text,
                                _avatar,
                                _age,
                                delete: true,
                              ),
                            ),
                          ),
                        if (!firstRun)
                          BigButton(
                            label: L.t('cancel'),
                            color: AppColors.blue,
                            fontSize: 17,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        BigButton(
                          label: L.t(firstRun ? 'start' : 'save'),
                          fontSize: firstRun ? 20 : 17,
                          onTap: _save,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
