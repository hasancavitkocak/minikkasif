import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

/// Ebeveyn kapısı: satın alma ve ayarlar ekranlarından önce, küçük çocuğun
/// çözemeyeceği bir çarpma işlemi sorar. Doğru yanıtta true döner.
Future<bool> showParentGate(BuildContext context) async {
  // Art arda iki dokunuş üst üste iki pencere açmasın: ikincisi çözülünce
  // alttaki eski soru ekranda kalıyordu.
  if (_gateOpen) return false;
  _gateOpen = true;
  try {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _ParentGateDialog(),
    );
    return ok ?? false;
  } finally {
    _gateOpen = false;
  }
}

bool _gateOpen = false;

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog();

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  late int _a;
  late int _b;
  String _input = '';
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    final rng = Random();
    _a = 4 + rng.nextInt(6);
    _b = 3 + rng.nextInt(7);
    _input = '';
  }

  void _press(String key) {
    setState(() {
      _wrong = false;
      if (key == '⌫') {
        if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
      } else if (_input.length < 3) {
        _input += key;
      }
    });
  }

  int _misses = 0;

  void _submit() {
    if (_input.isEmpty) return;
    if (_input == '${_a * _b}') {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _wrong = true;
      _misses++;
      // Yanlışta soru aynı kalır, yalnızca yanıt silinir; böylece yetişkin
      // neyi düzelteceğini görür. Rastgele denemeye karşı üç yanlışta bir
      // soru değişir.
      if (_misses % 3 == 0) {
        _newQuestion();
      } else {
        _input = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: FittedBox(
        child: SizedBox(
          width: 580,
          child: ToyPanel(
            padding: const EdgeInsets.all(18),
            // İşlem ve tuş takımı her dilde soldan sağa okunur.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.2),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          L.t('gate_title'),
                          textAlign: TextAlign.center,
                          style: titleStyle,
                        ),
                        const SizedBox(height: 4),
                        Text(L.t('gate_hint'), textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.yellow.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            '$_a × $_b = ?',
                            style: titleStyle.copyWith(fontSize: 34),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 140,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _wrong ? AppColors.red : AppColors.grey,
                              width: 3,
                            ),
                          ),
                          child: Text(
                            _input,
                            style: titleStyle.copyWith(fontSize: 28),
                          ),
                        ),
                        // Yanlış yanıtta ne olduğu açıkça söylenir.
                        SizedBox(
                          height: 24,
                          child: _wrong
                              ? Text(
                                  L.t('gate_wrong'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.red,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 228,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final key in [
                          '1',
                          '2',
                          '3',
                          '4',
                          '5',
                          '6',
                          '7',
                          '8',
                          '9',
                          '⌫',
                          '0',
                        ])
                          _key(key, AppColors.blue, () => _press(key)),
                        _key('✓', AppColors.green, _submit),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Align(
                    alignment: Alignment.topCenter,
                    child: RoundButton(
                      icon: Icons.close_rounded,
                      color: AppColors.red,
                      size: 44,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Oyundaki kartlar gibi alt kenarı koyu, "basılabilir" görünen tuş.
  Widget _key(String label, Color color, VoidCallback onTap) {
    final action = label == '✓' || label == '⌫';
    final face = label == '⌫' ? AppColors.orange : color;
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 54,
        padding: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: Color.lerp(face, Colors.black, 0.22),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: action ? face : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: face, width: 3),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: action ? Colors.white : AppColors.ink,
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
