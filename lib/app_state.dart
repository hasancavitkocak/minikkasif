import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/stickers.dart';
import 'games/game_def.dart';
import 'l10n.dart';

/// Bir çocuk profili. Her profilin ilerlemesi ayrı tutulur.
class Profile {
  Profile(this.id, this.name, this.avatar, [this.age = 0]);
  final int id;
  String name;

  /// Çocuğun yaşı; sorulmadıysa 0.
  int age;

  /// Avatar olarak kullanılan nesnenin kimliği (data/objects.dart).
  String avatar;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'age': age,
  };
}

/// Günün macerasındaki bir görev.
class DailyTask {
  const DailyTask(this.gameId, this.level);
  final String gameId;
  final int level;
}

/// Kalıcı uygulama durumu. Dil, ses ve abonelik tüm cihaz için ortaktır;
/// yıldızlar, çıkartmalar ve günlük macera profile özeldir.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState I = AppState._();

  static const maxProfiles = 4;

  SharedPreferences? _prefs;

  String lang = 'en';
  bool soundOn = true;
  bool musicOn = true;
  bool premium = false;

  List<Profile> profiles = [Profile(0, '', 'cat')];
  int _currentId = 0;

  final Map<String, int> _stars = {};
  List<String> stickers = [];
  Map<String, int> _plays = {};
  String _dailyDate = '';
  List<DailyTask> _dailyTasks = [];
  Set<int> dailyDone = {};

  /// Günün macerasında toplanması gereken yıldız sayısı.
  static const dailyGoal = 10;
  int _dailyStars = 0;
  String? _dailySticker;
  int _dailyRound = 0;

  Profile get profile => profiles.firstWhere(
    (p) => p.id == _currentId,
    orElse: () => profiles.first,
  );

  /// Profile özel anahtar. İlk profil, eski kayıtlarla uyum için öneksizdir.
  String _k(String key) => _currentId == 0 ? key : 'p${_currentId}_$key';

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> load() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    final device = PlatformDispatcher.instance.locale.languageCode;
    lang =
        prefs.getString('lang') ??
        (L.languages.containsKey(device) ? device : 'en');
    // Kaldırılan bir dil kayıtlıysa İngilizceye dönülür.
    if (!L.languages.containsKey(lang)) lang = 'en';
    soundOn = prefs.getBool('soundOn') ?? true;
    musicOn = prefs.getBool('musicOn') ?? true;
    premium = prefs.getBool('premium') ?? false;
    final rawProfiles = prefs.getString('profiles');
    profiles = rawProfiles == null
        ? [Profile(0, '', 'cat')]
        : [
            for (final p in jsonDecode(rawProfiles) as List<dynamic>)
              Profile(
                p['id'] as int,
                p['name'] as String,
                p['avatar'] as String,
                (p['age'] as int?) ?? 0,
              ),
          ];
    _currentId = prefs.getInt('profile') ?? profiles.first.id;
    if (!profiles.any((p) => p.id == _currentId)) {
      _currentId = profiles.first.id;
    }
    _loadProfileData();
    notifyListeners();
  }

  void _loadProfileData() {
    final prefs = _prefs;
    _stars.clear();
    stickers = [];
    _plays = {};
    _dailyDate = '';
    _dailyTasks = [];
    dailyDone = {};
    _dailyStars = 0;
    _dailySticker = null;
    _dailyRound = 0;
    if (prefs == null) return;
    final rawStars = prefs.getString(_k('stars'));
    if (rawStars != null) {
      (jsonDecode(rawStars) as Map<String, dynamic>).forEach(
        (k, v) => _stars[k] = v as int,
      );
    }
    // Albümden sonradan çıkarılmış çıkartmalar sayıya karışmasın.
    final known = {for (final s in allStickers) s.id};
    stickers = [
      for (final id in prefs.getStringList(_k('stickers')) ?? <String>[])
        if (known.contains(id)) id,
    ];
    final rawPlays = prefs.getString(_k('plays'));
    if (rawPlays != null) {
      _plays = (jsonDecode(rawPlays) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      );
    }
    final rawDaily = prefs.getString(_k('daily'));
    if (rawDaily != null) {
      final daily = jsonDecode(rawDaily) as Map<String, dynamic>;
      _dailyDate = daily['date'] as String;
      _dailyTasks = [
        for (final t in daily['tasks'] as List<dynamic>)
          DailyTask(t[0] as String, t[1] as int),
      ];
      dailyDone = {for (final i in daily['done'] as List<dynamic>) i as int};
      _dailyStars = daily['stars'] as int? ?? 0;
      _dailySticker = daily['sticker'] as String?;
      _dailyRound = daily['round'] as int? ?? 0;
    }
  }

  // ---- Genel ayarlar ----

  void setLang(String code) {
    lang = code;
    _prefs?.setString('lang', code);
    notifyListeners();
  }

  void setSound(bool on) {
    soundOn = on;
    _prefs?.setBool('soundOn', on);
    notifyListeners();
  }

  void setMusic(bool on) {
    musicOn = on;
    _prefs?.setBool('musicOn', on);
    notifyListeners();
  }

  void setPremium(bool value) {
    if (premium == value) return;
    premium = value;
    _prefs?.setBool('premium', value);
    notifyListeners();
  }

  // ---- Profiller ----

  void _saveProfiles() {
    _prefs?.setString(
      'profiles',
      jsonEncode([for (final p in profiles) p.toJson()]),
    );
  }

  /// Profile özel serbest kayıt (çıkartma sahnesi, takılan aksesuar...).
  String? profileData(String key) => _prefs?.getString(_k(key));

  void setProfileData(String key, String? value) {
    if (value == null) {
      _prefs?.remove(_k(key));
    } else {
      _prefs?.setString(_k(key), value);
    }
    notifyListeners();
  }

  /// İlk açılıştaki "kim oynayacak" sorusu yanıtlandı mı?
  bool get onboarded =>
      (_prefs?.getBool('onboarded') ?? false) ||
      profiles.any((p) => p.name.trim().isNotEmpty);

  void markOnboarded() => _prefs?.setBool('onboarded', true);

  /// Üç yıldız için tanınan fazladan hata hakkı: 3 yaşındaki çocuğa bir hata
  /// daha hoş görülür. Oyunların içeriği yaşa göre değişmez.
  int get extraTolerance => playAge == 3 ? 1 : 0;

  /// Zorluğun ayarlandığı yaş. Yaş girilmediyse en küçük yaş (3) sayılır;
  /// yani oyunlar en kolay haliyle başlar.
  int get playAge => profile.age == 0 ? 3 : profile.age;

  /// Bir bölümün yıldızı: [tolerance] hataya kadar 3, üç katına kadar 2.
  int starsFor(int mistakes, int tolerance) {
    final t = tolerance + extraTolerance;
    return mistakes <= t
        ? 3
        : mistakes <= t * 3
        ? 2
        : 1;
  }

  /// Profilin görünen adı; isim verilmediyse "Çocuk 1" gibi bir ad.
  String profileName(Profile p) => p.name.trim().isNotEmpty
      ? p.name.trim()
      : '${L.t('child')} ${profiles.indexOf(p) + 1}';

  void switchProfile(int id) {
    if (id == _currentId || !profiles.any((p) => p.id == id)) return;
    _currentId = id;
    _prefs?.setInt('profile', id);
    _loadProfileData();
    notifyListeners();
  }

  void addProfile(String name, String avatar, [int age = 0]) {
    if (profiles.length >= maxProfiles) return;
    final id = profiles.map((p) => p.id).reduce(max) + 1;
    profiles.add(Profile(id, name, avatar, age));
    _saveProfiles();
    switchProfile(id);
  }

  void updateProfile(int id, String name, String avatar, [int? age]) {
    final p = profiles.firstWhere((p) => p.id == id);
    p.name = name;
    p.avatar = avatar;
    if (age != null) p.age = age;
    _saveProfiles();
    notifyListeners();
  }

  /// Profili ve tüm ilerlemesini siler. Son profil silinemez.
  void deleteProfile(int id) {
    if (profiles.length <= 1) return;
    final prefix = id == 0 ? '' : 'p${id}_';
    for (final key in [
      'stars',
      'stickers',
      'plays',
      'daily',
      'howto',
      'scene',
      'outfit',
    ]) {
      _prefs?.remove('$prefix$key');
    }
    profiles.removeWhere((p) => p.id == id);
    _saveProfiles();
    if (_currentId == id) {
      _currentId = profiles.first.id;
      _prefs?.setInt('profile', _currentId);
      _loadProfileData();
    }
    notifyListeners();
  }

  // ---- Nasıl oynanır ----

  /// "Nasıl oynanır" anlatımı bu oyun için daha önce gösterildi mi?
  bool seenHowTo(String gameId) =>
      _prefs?.getStringList(_k('howto'))?.contains(gameId) ?? false;

  void markHowToSeen(String gameId) {
    final seen = {...?_prefs?.getStringList(_k('howto')), gameId};
    _prefs?.setStringList(_k('howto'), seen.toList());
  }

  // ---- Yıldızlar ve bölümler ----

  int stars(String gameId, int level) => _stars['$gameId:$level'] ?? 0;

  int totalStars(String gameId) {
    var sum = 0;
    _stars.forEach((k, v) {
      if (k.startsWith('$gameId:')) sum += v;
    });
    return sum;
  }

  int get allStars => _stars.values.fold(0, (a, b) => a + b);

  /// En az bir kez bitirilmiş bölüm sayısı.
  int get completedLevels => _stars.length;

  /// Bir bölüm, bir önceki bölüm en az bir kez bitirildiyse açılır.
  /// Bölüm aboneliksiz oynanabilir mi? İlk iki oyunun ilk dünyası (ilk on
  /// bölüm) ve diğer oyunların ilk bölümü ücretsizdir.
  /// Oyunun aboneliksiz (ya da abonelikle tümü) oynanabilen bölüm sayısı.
  int freeLevels(GameDef game) => premium
      ? game.levels
      : game.free
      ? min(game.levels, worldSize)
      : 1;

  bool canPlay(GameDef game, int level) =>
      premium || level == 1 || (game.free && level <= worldSize);

  bool levelUnlocked(String gameId, int level) =>
      level <= 1 || stars(gameId, level - 1) > 0;

  /// Oyunda sıradaki (açık ve en ileri) bölüm.
  int nextLevel(GameDef game) {
    for (var level = 1; level <= game.levels; level++) {
      if (stars(game.id, level) == 0) return level;
    }
    return game.levels;
  }

  void setStars(String gameId, int level, int value) {
    if (value <= stars(gameId, level)) return;
    _stars['$gameId:$level'] = value;
    _prefs?.setString(_k('stars'), jsonEncode(_stars));
    notifyListeners();
  }

  /// Bir bölüm bitince çağrılır: yıldızı kaydeder, oynama sayacını ve günün
  /// macerasını günceller. Yeni bir çıkartma kazanıldıysa onu döndürür.
  Sticker? finishLevel(String gameId, int level, int value) {
    final first = stars(gameId, level) == 0;
    setStars(gameId, level, value);

    final today = _today();
    _plays[today] = (_plays[today] ?? 0) + 1;
    final keep = _plays.keys.toList()..sort();
    while (keep.length > 30) {
      _plays.remove(keep.removeAt(0));
    }
    _prefs?.setString(_k('plays'), jsonEncode(_plays));

    Sticker? sticker;
    // Bölüm sonu çıkartması seyrektir: ilk bölüm (albümle tanışma) ve
    // sonrasında her beş yeni bölümden biri. Asıl kaynak günün macerasıdır.
    if (first && (completedLevels == 1 || completedLevels % 5 == 0)) {
      sticker = _awardSticker();
    }
    // Günün macerası: hangi oyun olursa olsun bugün kazanılan yıldızlar
    // sayılır; hedefe ulaşılınca günün çıkartması verilir.
    _startDay();
    final wasComplete = dailyComplete;
    _dailyStars += value;
    for (var i = 0; i < _dailyTasks.length; i++) {
      final task = _dailyTasks[i];
      if (!dailyDone.contains(i) &&
          task.gameId == gameId &&
          task.level == level) {
        dailyDone.add(i);
        break;
      }
    }
    if (!wasComplete && dailyComplete) {
      sticker = _awardSticker(prefer: _dailySticker) ?? sticker;
    }
    _saveDaily();
    notifyListeners();
    return sticker;
  }

  void resetProgress() {
    _stars.clear();
    stickers = [];
    _plays = {};
    _dailyDate = '';
    _dailyTasks = [];
    dailyDone = {};
    _dailyStars = 0;
    _dailySticker = null;
    _dailyRound = 0;
    for (final key in [
      'stars',
      'stickers',
      'plays',
      'daily',
      'howto',
      'scene',
      'outfit',
    ]) {
      _prefs?.remove(_k(key));
    }
    notifyListeners();
  }

  // ---- Çıkartmalar ----

  /// Eksik çıkartmalardan birini verir; [prefer] hâlâ eksikse onu.
  Sticker? _awardSticker({String? prefer}) {
    final missing = [
      for (final s in allStickers)
        if (!stickers.contains(s.id)) s,
    ];
    if (missing.isEmpty) return null;
    final sticker = missing.firstWhere(
      (s) => s.id == prefer,
      orElse: () => missing[Random().nextInt(missing.length)],
    );
    stickers = [...stickers, sticker.id];
    _prefs?.setStringList(_k('stickers'), stickers);
    return sticker;
  }

  // ---- Günün macerası ----

  void _saveDaily() {
    _prefs?.setString(
      _k('daily'),
      jsonEncode({
        'date': _dailyDate,
        'tasks': [
          for (final t in _dailyTasks) [t.gameId, t.level],
        ],
        'done': dailyDone.toList(),
        'stars': _dailyStars,
        'sticker': _dailySticker,
        'round': _dailyRound,
      }),
    );
  }

  /// Yeni bir güne girildiyse sayaçları sıfırlar ve günün çıkartmasını seçer.
  void _startDay() {
    final today = _today();
    if (_dailyDate == today) return;
    _dailyDate = today;
    _dailyTasks = [];
    dailyDone = {};
    _dailyStars = 0;
    _dailyRound = 0;
    final missing = [
      for (final s in allStickers)
        if (!stickers.contains(s.id)) s.id,
    ];
    _dailySticker = missing.isEmpty
        ? null
        : missing[Random(today.hashCode + _currentId).nextInt(missing.length)];
  }

  /// Bugün toplanan yıldız (en çok [dailyGoal] gösterilir).
  int get dailyStars =>
      _dailyDate == _today() ? min(_dailyStars, dailyGoal) : 0;

  /// Bugünün ödülü olan çıkartma; albüm dolduysa null.
  Sticker? get dailySticker {
    if (_dailyDate != _today()) return null;
    for (final s in allStickers) {
      if (s.id == _dailySticker) return s;
    }
    return null;
  }

  /// Bugün için önerilen üç bölüm. Üçü de bitip hedefe hâlâ ulaşılmadıysa
  /// yeni üç bölüm önerilir; hedefe ulaşılınca sabit kalır.
  List<DailyTask> dailyTasks(List<GameDef> games) {
    final today = _today();
    final playable = games;
    _startDay();
    final spent = dailyDone.length >= 3 && !dailyComplete;
    if (spent) _dailyRound++;
    final valid =
        !spent &&
        _dailyTasks.length == 3 &&
        _dailyTasks.every(
          (t) => games.any((g) => g.id == t.gameId && canPlay(g, t.level)),
        );
    if (!valid && playable.isNotEmpty) {
      final rng = Random(today.hashCode + _currentId + _dailyRound * 31);
      final order = [...playable]..shuffle(rng);
      dailyDone = {};
      _dailyTasks = [
        for (var i = 0; i < 3; i++)
          // Oynanabilir oyun üçten azsa aynı oyunun bir önceki bölümü de girer.
          DailyTask(
            order[i % order.length].id,
            // Aboneliksiz kullanıcıya yalnızca ücretsiz bölümler gelir.
            min(
              max(1, nextLevel(order[i % order.length]) - i ~/ order.length),
              freeLevels(order[i % order.length]),
            ),
          ),
      ];
      // Aynı oyun ve bölüm iki kez gelmesin.
      final seen = <String>{};
      _dailyTasks = [
        for (final t in _dailyTasks)
          seen.add('${t.gameId}:${t.level}')
              ? t
              : DailyTask(t.gameId, t.level + 1),
      ];
      _saveDaily();
    }
    return _dailyTasks;
  }

  /// Günün macerasında sıradaki önerilen bölüm; hedefe ulaşıldıysa null.
  DailyTask? nextDailyTask(List<GameDef> games) {
    if (dailyComplete) return null;
    final tasks = dailyTasks(games);
    for (var i = 0; i < tasks.length; i++) {
      if (!dailyDone.contains(i)) return tasks[i];
    }
    return null;
  }

  bool get dailyComplete => _dailyDate == _today() && _dailyStars >= dailyGoal;

  // ---- Rapor ----

  /// Son 7 günde oynanan bölüm sayısı.
  int get playsThisWeek {
    final now = DateTime.now();
    var sum = 0;
    _plays.forEach((date, count) {
      final day = DateTime.tryParse(date);
      if (day != null && now.difference(day).inDays < 7) sum += count;
    });
    return sum;
  }
}
