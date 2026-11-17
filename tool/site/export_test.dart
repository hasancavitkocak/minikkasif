// Web sitesi için uygulamadaki metinleri dışa aktarır. Test değildir;
// tool/site_build.py çalıştırır:
//   flutter test tool/site/export_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:minik_kasif/app_state.dart';
import 'package:minik_kasif/data/legal.dart';
import 'package:minik_kasif/games/registry.dart';
import 'package:minik_kasif/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('site metinlerini dışa aktar', () async {
    SharedPreferences.setMockInitialValues({});
    await AppState.I.load();
    final out = <String, dynamic>{
      'email': supportEmail,
      'version': appVersion,
      'levels': games.fold<int>(0, (sum, g) => sum + g.levels),
    };
    for (final lang in ['tr', 'en']) {
      AppState.I.setLang(lang);
      out[lang] = {
        'privacy': Legal.privacy,
        'terms': Legal.terms,
        'about': Legal.about,
        'where_ios': L.t('sub_where_ios'),
        'games': [
          for (final g in [...games, ...activities])
            {'id': g.id, 'name': L.t('g_${g.id}')},
        ],
      };
    }
    File(
      'build/site_texts.json',
    ).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(out));
  });
}
