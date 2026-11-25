import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';
import 'audio.dart';

/// Ebeveynin koyduğu günlük oyun süresi. Süre cihaz için ortaktır (hangi
/// çocuk oynarsa oynasın aynı sayaç işler), gece yarısı kendiliğinden
/// sıfırlanır. Süre dolunca [locked] olur; uygulama kapanmaz, "Süre doldu"
/// ekranı açılır ve yalnızca ebeveyn kapısından geçen süreyi uzatabilir.
class ScreenTime extends ChangeNotifier {
  ScreenTime._();
  static final ScreenTime I = ScreenTime._();

  /// Ayarlarda sunulan süreler (dakika); 0 = kapalı.
  static const choices = [0, 15, 30, 60];

  /// "Özel" süre seçimi: 5 dakikalık adımlarla 5 dk – 3 saat.
  static const customStep = 5;
  static const customMax = 180;

  /// Seçili süre hazır seçeneklerden biri değil mi?
  bool get isCustom => !choices.contains(limitMinutes);

  /// Bitmesine bu kadar kala Fıstık uyarır.
  static const warnBefore = 60;

  SharedPreferences? _prefs;
  Timer? _timer;
  bool _active = true;

  /// Günlük süre (dakika); 0 ise sınır yok.
  int limitMinutes = 0;

  String _date = '';
  int _used = 0;
  int _extra = 0;
  bool _unlimited = false;
  bool _warned = false;

  /// Bir bölüm oynanırken süre dolarsa ekran bölüm bitene kadar bekler.
  int _busy = 0;

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> load() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    limitMinutes = prefs.getInt('timeLimit') ?? 0;
    _date = prefs.getString('timeDate') ?? '';
    _used = prefs.getInt('timeUsed') ?? 0;
    _extra = prefs.getInt('timeExtra') ?? 0;
    _unlimited = prefs.getBool('timeUnlimited') ?? false;
    _rollover();
    // Yalnızca tarayıcı önizlemesi: adres ?sure_dene içerirse süre 15 sn
    // sonra dolacak şekilde ayarlanır (uyarı ve kilit ekranını denemek için).
    if (kIsWeb && Uri.base.queryParameters.containsKey('sure_dene')) {
      if (limitMinutes == 0) limitMinutes = 15;
      _extra = 0;
      _unlimited = false;
      _used = limitMinutes * 60 - 15;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Uygulama arka plandayken süre işlemez.
  void setActive(bool active) {
    _active = active;
    if (!active) _save();
  }

  bool get enabled => limitMinutes > 0;

  /// Bugün kalan saniye; sınır yoksa ya da bugün sınırsızsa null.
  int? get remaining {
    if (!enabled || _unlimited) return null;
    final left = limitMinutes * 60 + _extra - _used;
    return left < 0 ? 0 : left;
  }

  bool get timeUp => remaining == 0;

  /// "Süre doldu" ekranı gösterilmeli mi?
  bool get locked => timeUp && _busy == 0;

  /// Bölüm başlarken ve biterken (ya da yarıda bırakılınca) çağrılır.
  void beginLevel() => _busy++;

  void endLevel() {
    if (_busy == 0) return;
    _busy--;
    if (_busy == 0 && timeUp) notifyListeners();
  }

  void setLimit(int minutes) {
    limitMinutes = minutes;
    // Ayarlar ebeveyn kapısının arkasında: bir süre seçmek "şu andan
    // itibaren bu kadar" demektir. Sayaç baştan başlar; aynı süreye yeniden
    // basmak da süreyi yeniler.
    _used = 0;
    _extra = 0;
    _unlimited = false;
    _warned = false;
    _prefs?.setInt('timeLimit', minutes);
    _save();
    notifyListeners();
  }

  /// Ebeveyn kapısından sonra: bugünkü süreye [minutes] dakika ekler.
  void addMinutes(int minutes) {
    _rollover();
    // Süre çoktan dolduysa ek, şu andan itibaren sayılır.
    final over = enabled ? _used - (limitMinutes * 60 + _extra) : 0;
    _extra += minutes * 60 + (over > 0 ? over : 0);
    _warned = false;
    _save();
    notifyListeners();
  }

  /// Ebeveyn kapısından sonra: bugün gece yarısına kadar sınır kalkar.
  void unlimitedToday() {
    _rollover();
    _unlimited = true;
    _save();
    notifyListeners();
  }

  void _rollover() {
    final today = _today();
    if (_date == today) return;
    _date = today;
    _used = 0;
    _extra = 0;
    _unlimited = false;
    _warned = false;
    _save();
    notifyListeners();
  }

  void _tick() {
    if (!_active) return;
    _rollover();
    if (!enabled || _unlimited) return;
    final wasUp = timeUp;
    _used++;
    if (_used % 15 == 0) _save();
    final left = remaining!;
    if (!_warned && left <= warnBefore && left > 0) {
      _warned = true;
      Tts.speak(L.t('time_warn'), key: 'time_warn');
    }
    if (!wasUp && timeUp) _save();
    // Ayarlardaki geri sayım her saniye güncellensin.
    notifyListeners();
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setString('timeDate', _date);
    prefs.setInt('timeUsed', _used);
    prefs.setInt('timeExtra', _extra);
    prefs.setBool('timeUnlimited', _unlimited);
  }
}
