import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../app_state.dart';
import '../l10n.dart';

/// Kısa ses efektleri (assets/audio/*.wav).
class Sfx {
  /// Testlerde platform eklentilerine dokunmamak için kapatılır.
  static bool enabled = true;

  static final Map<String, AudioPlayer> _players = {};

  static Future<void> play(String name) async {
    if (!enabled || !AppState.I.soundOn) return;
    try {
      final player = _players[name] ??= AudioPlayer();
      await player.stop();
      await player.play(AssetSource('audio/$name.wav'));
    } catch (_) {
      // Ses çalınamazsa oyun sessiz devam eder.
    }
  }
}

/// Arka plan müziği (assets/audio/music.wav), kısık sesle döngüde çalar.
class Music {
  static bool enabled = true;

  static AudioPlayer? _player;
  static bool _playing = false;

  /// Ayara göre müziği başlatır ya da durdurur. Tarayıcılar ilk dokunuştan
  /// önce ses çalmaya izin vermediği için ilk dokunuştan sonra çağrılır.
  static Future<void> sync() async {
    final wanted = enabled && AppState.I.musicOn;
    try {
      if (wanted && !_playing) {
        final player = _player ??= AudioPlayer();
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setVolume(0.22);
        await player.play(AssetSource('audio/music.wav'));
        _playing = true;
      } else if (!wanted && _playing) {
        _playing = false;
        await _player?.stop();
      }
    } catch (_) {
      _playing = false;
    }
  }

  /// Uygulama arka plana geçince duraklatır, geri gelince sürdürür.
  static Future<void> setActive(bool active) async {
    try {
      if (!_playing) return;
      active ? await _player?.resume() : await _player?.pause();
    } catch (_) {}
  }
}

/// Kayıtlı seslendirmeler: `assets/audio/voice/<dil>/<anahtar>.mp3`.
/// Bir cümlenin kaydı varsa metin okuma motoru yerine o çalınır.
class Voice {
  static AudioPlayer? _player;

  /// Şu an bir kayıt çalıyor mu (bkz. [finished]).
  static bool _active = false;
  static Set<String>? _files;

  /// [key] cümlesinin seçili dildeki kaydının yolu; kayıt yoksa null.
  static Future<String?> find(String key) async {
    try {
      final files = _files ??= {
        ...(await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets(),
      };
      for (final ext in const ['mp3', 'm4a', 'wav', 'ogg']) {
        final path = 'audio/voice/${AppState.I.lang}/$key.$ext';
        if (files.contains('assets/$path')) return path;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> play(String path) async {
    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      _active = true;
      await player.play(AssetSource(path));
    } catch (_) {
      _active = false;
      // Çalma yarıda kesilirse (hemen ardından başka cümle gelirse) sessiz geçilir.
    }
  }

  static Future<void> stop() async {
    _active = false;
    try {
      await _player?.stop();
    } catch (_) {}
  }

  /// Çalan kayıt bitince tamamlanır. Kayıt çalmıyorsa (cümle makine sesiyle
  /// okunuyorsa) [fallback] kadar bekler.
  static Future<void> finished(Duration fallback) async {
    final player = _player;
    if (!_active || player == null) {
      await Future<void>.delayed(fallback);
      return;
    }
    try {
      await player.onPlayerComplete.first.timeout(const Duration(seconds: 8));
    } catch (_) {}
    _active = false;
  }
}

/// Sesli yönergeler: çocuklar okuyamadığı için yönergeler seslendirilir.
/// Cümlenin kaydı varsa o, yoksa cihazın metin okuma motoru kullanılır.
class Tts {
  static bool enabled = true;

  static FlutterTts? _tts;
  static int _request = 0;

  /// Son konuşmayı başlatan ekran (bkz. [stopFor]).
  static Object? _owner;

  /// Testler için: söylenmesi istenen her cümle ve kayıt anahtarı bildirilir.
  static void Function(String text, String? key)? observer;

  /// [keys] çeviri anahtarlarındaki cümleleri sırayla okur; biri bitmeden
  /// ötekine geçmez. Araya başka bir konuşma ya da susturma girerse kalanı
  /// okunmaz.
  static Future<void> speakKeys(List<String> keys, {Object? owner}) async {
    for (var i = 0; i < keys.length; i++) {
      final text = L.t(keys[i]);
      await speak(text, owner: owner, key: keys[i]);
      if (i == keys.length - 1) break;
      if (!enabled || !AppState.I.soundOn) continue;
      final request = _request;
      await Voice.finished(Duration(milliseconds: 600 + 90 * text.length));
      if (request != _request) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (request != _request) return;
    }
  }

  /// [key] verilirse kayıt o adla aranır; verilmezse cümleden bulunur. Aynı
  /// yazılan iki cümle (ör. oyun adı ve beceri adı) böylece karışmaz.
  static Future<void> speak(String text, {Object? owner, String? key}) async {
    key ??= L.voiceKey(text);
    observer?.call(text, key);
    if (!enabled || !AppState.I.soundOn) return;
    _owner = owner;
    // Art arda gelen isteklerde yalnızca sonuncusu okunur.
    final request = ++_request;
    try {
      await Voice.stop();
      final path = key == null ? null : await Voice.find(key);
      if (request != _request) return;
      if (path != null) {
        // Kaydı olan cümle yalnızca kayıtla okunur; kayıt çalınamasa bile
        // makine sesi devreye girmez, yoksa iki ses üst üste biner.
        await _tts?.stop();
        await Voice.play(path);
        return;
      }
      final tts = _tts ??= FlutterTts();
      await tts.stop();
      // Tarayıcıda durdurmanın hemen ardından verilen cümle yutulabiliyor.
      if (kIsWeb) await Future<void>.delayed(const Duration(milliseconds: 150));
      if (request != _request) return;
      await tts.setLanguage(L.ttsCode);
      await tts.setSpeechRate(kIsWeb ? 0.9 : 0.45);
      await tts.setPitch(1.2);
      await tts.speak(text);
    } catch (_) {
      // Cihazda bu dil için ses yoksa yönerge yalnızca yazılı görünür.
    }
  }

  /// [owner] kapanırken çağrılır: yalnızca hâlâ onun başlattığı konuşma
  /// sürüyorsa susturur. Böylece kapanan ekran, yerine açılan ekranın yeni
  /// başlamış cümlesini yarıda kesmez.
  static Future<void> stopFor(Object owner) async {
    if (identical(_owner, owner)) await stop();
  }

  /// Testler için: konuşma gerçekten susturulduğunda bildirilir.
  static void Function()? stopObserver;

  static Future<void> stop() async {
    stopObserver?.call();
    _request++;
    await Voice.stop();
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}
