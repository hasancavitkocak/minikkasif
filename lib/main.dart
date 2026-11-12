import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'l10n.dart';
import 'screens/welcome_screen.dart';
import 'services/audio.dart';
import 'services/purchases.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Oyun yalnızca yatay ekranda, tam ekran çalışır.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await AppState.I.load();
  Purchases.I.init();
  runApp(const MinikKasifApp());
}

class MinikKasifApp extends StatefulWidget {
  const MinikKasifApp({super.key});

  @override
  State<MinikKasifApp> createState() => _MinikKasifAppState();
}

class _MinikKasifAppState extends State<MinikKasifApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Uygulama arka plana geçince müzik duraklar, geri gelince sürer ve
  /// aboneliğin hâlâ geçerli olup olmadığına bakılır.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Music.setActive(state == AppLifecycleState.resumed);
    // Abonelik uygulama kapaliyken bitmis olabilir.
    if (state == AppLifecycleState.resumed) Purchases.I.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) => MaterialApp(
        title: "Minik Kaşif: Fıstık'la Oyunlar",
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: Locale(AppState.I.lang),
        supportedLocales: [for (final code in L.languages.keys) Locale(code)],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const WelcomeScreen(),
      ),
    );
  }
}
