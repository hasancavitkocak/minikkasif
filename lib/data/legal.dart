import '../app_state.dart';

/// Uygulama sürümü (pubspec.yaml ile aynı tutulur).
const appVersion = '1.0.0';

/// Destek adresi. Alan adı alınınca gerçek adresle değiştirilecek.
const supportEmail = 'destek@minikkasif.com';

/// Uzun yasal metinler. Türkçe ve İngilizce yazıldı; diğer dillerde
/// İngilizcesi gösterilir.
class Legal {
  static String _pick(Map<String, String> texts) =>
      (texts[AppState.I.lang] ?? texts['en']!).replaceAll(
        '{email}',
        supportEmail,
      );

  static String get privacy => _pick(_privacy);
  static String get terms => _pick(_terms);
  static String get about => _pick(_about);

  static const _about = {
    'tr':
        'Minik Kaşif, 3-5 yaş arası çocuklar için hazırlanmış bir zekâ ve '
        'beceri oyunudur. Hafıza, dikkat, mantık, sayılar ve yaratıcılık '
        'alanlarında oyunlar içerir.\n\n'
        'Uygulamada reklam yoktur. Çocuğunuz dışarıya açılan bir bağlantıya '
        'ya da satın alma ekranına tek başına ulaşamaz; bu alanlar ebeveyn '
        'kapısının arkasındadır.\n\n'
        'Soru ve önerileriniz için: {email}',
    'en':
        'Minik Kaşif is a brain and skills game made for children aged 3 to '
        '5. It includes games for memory, attention, logic, numbers and '
        'creativity.\n\n'
        'The app has no ads. Your child cannot reach an outside link or a '
        'purchase screen alone; those areas are behind the parent gate.\n\n'
        'Questions and suggestions: {email}',
  };

  static const _privacy = {
    'tr':
        'Bu politika, Minik Kaşif uygulamasının hangi bilgileri nasıl '
        'kullandığını açıklar.\n\n'
        '1. Topladığımız bilgiler\n'
        'Uygulama, çocuğunuzdan ya da sizden kişisel bilgi toplamaz ve '
        'hiçbir bilgiyi sunucularımıza göndermez. Hesap açmanız gerekmez.\n\n'
        '2. Cihazda saklanan bilgiler\n'
        'Profil adı, yaş, seçilen avatar, kazanılan yıldızlar ve '
        'çıkartmalar, çizimler ve ayarlar yalnızca cihazınızda saklanır. '
        'Uygulamayı sildiğinizde bu bilgiler de silinir. İlerlemeyi Ebeveyn '
        'Alanı içinden istediğiniz zaman sıfırlayabilirsiniz.\n\n'
        '3. Reklam ve izleme\n'
        'Uygulamada reklam, reklam kimliği ya da davranış izleme aracı '
        'bulunmaz.\n\n'
        '4. Satın alımlar\n'
        'Abonelikler App Store ya da Google Play üzerinden yapılır. Ödeme '
        'bilgileriniz bize ulaşmaz; yalnızca aboneliğinizin etkin olup '
        'olmadığı bilgisi mağazadan alınır.\n\n'
        '5. Seslendirme\n'
        'Kaydı olmayan cümleler cihazınızın metin okuma özelliğiyle '
        'seslendirilir. Bu işlem cihazınızın ayarlarına bağlıdır.\n\n'
        '6. Çocukların gizliliği\n'
        'Uygulama çocuklara yöneliktir. Satın alma ve ayar ekranları '
        'ebeveyn kapısıyla korunur.\n\n'
        '7. Değişiklikler ve iletişim\n'
        'Bu politika güncellenirse yeni hali uygulamada yayımlanır. '
        'Sorularınız için: {email}',
    'en':
        'This policy explains what information Minik Kaşif uses and how.\n\n'
        '1. Information we collect\n'
        'The app does not collect personal information from you or your '
        'child and sends nothing to our servers. No account is needed.\n\n'
        '2. Information stored on the device\n'
        'Profile name, age, chosen avatar, earned stars and stickers, '
        'drawings and settings are stored only on your device. They are '
        'removed when you delete the app. You can reset progress at any time '
        'in the Parents Area.\n\n'
        '3. Ads and tracking\n'
        'The app contains no ads, no advertising identifiers and no '
        'behavioural tracking.\n\n'
        '4. Purchases\n'
        'Subscriptions are handled by the App Store or Google Play. We never '
        'receive your payment details; we only learn from the store whether '
        'your subscription is active.\n\n'
        '5. Voice\n'
        'Sentences without a recording are read by your device\'s '
        'text-to-speech feature, which depends on your device settings.\n\n'
        '6. Children\'s privacy\n'
        'The app is made for children. Purchase and settings screens are '
        'protected by a parent gate.\n\n'
        '7. Changes and contact\n'
        'If this policy changes, the new version will be published in the '
        'app. Questions: {email}',
  };

  static const _terms = {
    'tr':
        'Minik Kaşif uygulamasını kullanarak aşağıdaki koşulları kabul etmiş '
        'olursunuz.\n\n'
        '1. Kullanım\n'
        'Uygulama, çocukların ebeveyn ya da veli gözetiminde kullanması '
        'için hazırlanmıştır. Kişisel ve ticari olmayan kullanım içindir.\n\n'
        '2. Ücretsiz ve ücretli içerik\n'
        'İlk iki oyunun ilk on bölümü, diğer oyunların ilk bölümü ve '
        'serbest etkinlikler ücretsizdir. Diğer bölümler abonelikle '
        'açılır.\n\n'
        '3. Abonelik\n'
        'Aylık ve yıllık abonelik seçenekleri vardır. Abonelik, dönem '
        'bitmeden en az 24 saat önce iptal edilmezse otomatik yenilenir. '
        'İptal ve yönetim, mağaza hesabınızın abonelik ayarlarından '
        'yapılır. İade talepleri ilgili mağazanın kurallarına tabidir.\n\n'
        '4. Fikrî haklar\n'
        'Uygulamadaki görseller, sesler, metinler ve yazılım izinsiz '
        'kopyalanamaz, dağıtılamaz ve değiştirilemez.\n\n'
        '5. Sorumluluk\n'
        'Uygulama eğlence ve gelişimi destekleme amaçlıdır; eğitim ya da '
        'sağlık hizmetinin yerini tutmaz. Uygulama "olduğu gibi" sunulur.\n\n'
        '6. Değişiklikler ve iletişim\n'
        'Koşullar güncellenebilir; güncel hali uygulamada yer alır. '
        'Sorularınız için: {email}',
    'en':
        'By using Minik Kaşif you accept the following terms.\n\n'
        '1. Use\n'
        'The app is intended for children to use under the supervision of '
        'a parent or guardian, for personal and non-commercial use.\n\n'
        '2. Free and paid content\n'
        'The first ten levels of the first two games, the first level of '
        'every other game and the free activities are free. Other levels '
        'are unlocked with a subscription.\n\n'
        '3. Subscription\n'
        'Monthly and yearly subscriptions are offered. A subscription '
        'renews automatically unless cancelled at least 24 hours before the '
        'end of the period. You can manage or cancel it in your store '
        'account settings. Refunds follow the rules of the store.\n\n'
        '4. Intellectual property\n'
        'The images, sounds, texts and software in the app may not be '
        'copied, distributed or modified without permission.\n\n'
        '5. Liability\n'
        'The app is meant for fun and to support development; it does not '
        'replace education or health services. It is provided "as is".\n\n'
        '6. Changes and contact\n'
        'These terms may be updated; the current version is available in '
        'the app. Questions: {email}',
  };
}
