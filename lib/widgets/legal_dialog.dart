import 'package:flutter/material.dart';

import '../data/legal.dart';
import '../l10n.dart';
import '../theme.dart';
import 'common.dart';
import 'ui.dart';

/// Uzun bir yasal metni (hakkında, gizlilik politikası, kullanım koşulları)
/// kaydırılabilir bir pencerede gösterir.
void showLegalText(BuildContext context, String title, String body) {
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

/// Kullanım Koşulları ve Gizlilik Politikası bağlantıları. Abonelik ekranında
/// ve ilk kurulumda görünür; ikisi de yalnızca ebeveynin gördüğü yerlerdir.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key, this.fontSize = 13});
  final double fontSize;

  Widget _link(BuildContext context, String key, String body) {
    return Pressable(
      onTap: () => showLegalText(context, L.t(key), body),
      child: Text(
        L.t(key),
        style: TextStyle(
          fontSize: fontSize,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: AppColors.blue,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.blue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        _link(context, 'terms', Legal.terms),
        Text('·', style: TextStyle(fontSize: fontSize, height: 1.3)),
        _link(context, 'privacy', Legal.privacy),
      ],
    );
  }
}
