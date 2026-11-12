import '../app_state.dart';

/// Resimli, sesli kısa bir hikâye. Her sayfanın görseli
/// `assets/images/stories/story_<id>_<sayfa>.png`, Türkçe ses kaydı
/// `story_<id>_<sayfa>` adıyla bulunur; kaydı olmayan dillerde metni cihaz okur.
class Story {
  const Story(this.id, this.title, this.emojis, this.pages);
  final String id;
  final Map<String, String> title;

  /// Görseller gelene kadar sayfalarda görünen geçici simgeler.
  final List<String> emojis;
  final List<Map<String, String>> pages;

  static String _pick(Map<String, String> texts) =>
      texts[AppState.I.lang] ?? texts['en']!;

  String get localTitle => _pick(title);
  String text(int page) => _pick(pages[page]);
  String voiceKey(int page) => 'story_${id}_${page + 1}';
  String image(int page) => 'assets/images/stories/story_${id}_${page + 1}.png';
}

/// İlk hikâye herkese açık, diğerleri abonelikle dinlenir.
const stories = <Story>[
  Story(
    'ball',
    {
      'tr': "Kayıp Top",
      'en': "The Lost Ball",
      'de': "Der verlorene Ball",
      'fr': "Le ballon perdu",
      'es': "La pelota perdida",
    },
    ['⚽', '🌳', '🐰', '🏃', '🦆', '🎉'],
    [
      {
        'tr': "Fıstık çayırda kırmızı topuyla oynuyordu.",
        'en': "Fıstık was playing with a red ball in the meadow.",
        'de': "Fıstık spielte auf der Wiese mit einem roten Ball.",
        'fr': "Fıstık jouait dans le pré avec un ballon rouge.",
        'es': "Fıstık jugaba en el prado con una pelota roja.",
      },
      {
        'tr': "Top yuvarlandı ve çalıların arkasında kayboldu.",
        'en': "The ball rolled away and vanished behind the bushes.",
        'de': "Der Ball rollte weg und verschwand hinter den Büschen.",
        'fr': "Le ballon a roulé et a disparu derrière les buissons.",
        'es': "La pelota rodó y desapareció detrás de los arbustos.",
      },
      {
        'tr': "Fıstık tavşana sordu: Topumu gördün mü?",
        'en': "Fıstık asked the rabbit: Have you seen my ball?",
        'de': "Fıstık fragte den Hasen: Hast du meinen Ball gesehen?",
        'fr': "Fıstık a demandé au lapin : As-tu vu mon ballon ?",
        'es': "Fıstık le preguntó al conejo: ¿Has visto mi pelota?",
      },
      {
        'tr':
            "Tavşan, dereye doğru yuvarlandı, dedi. Birlikte dereye koştular.",
        'en': "It rolled toward the stream, said the rabbit. They ran to the stream together.",
        'de': "Er ist zum Bach gerollt, sagte der Hase. Zusammen liefen sie zum Bach.",
        'fr': "Il a roulé vers le ruisseau, a dit le lapin. Ils ont couru ensemble jusqu'au ruisseau.",
        'es': "Rodó hacia el arroyo, dijo el conejo. Corrieron juntos hasta el arroyo.",
      },
      {
        'tr': "Top derenin kenarında, bir ördeğin yanında duruyordu.",
        'en': "The ball was resting by the stream, next to a duck.",
        'de': "Der Ball lag am Bach, neben einer Ente.",
        'fr': "Le ballon était au bord du ruisseau, à côté d'un canard.",
        'es': "La pelota estaba junto al arroyo, al lado de un pato.",
      },
      {
        'tr': "Fıstık topunu aldı. Üç arkadaş birlikte oyun oynadı.",
        'en': "Fıstık picked up the ball. The three friends played together.",
        'de': "Fıstık holte den Ball. Die drei Freunde spielten zusammen.",
        'fr': "Fıstık a repris le ballon. Les trois amis ont joué ensemble.",
        'es': "Fıstık recogió la pelota. Los tres amigos jugaron juntos.",
      },
    ],
  ),
  Story(
    'seed',
    {
      'tr': "Minik Tohum",
      'en': "The Little Seed",
      'de': "Der kleine Samen",
      'fr': "La petite graine",
      'es': "La pequeña semilla",
    },
    ['🌰', '🪴', '💧', '☀️', '🌱', '🌻'],
    [
      {
        'tr': "Fıstık bir gün küçük bir tohum buldu.",
        'en': "One day Fıstık found a little seed.",
        'de': "Eines Tages fand Fıstık einen kleinen Samen.",
        'fr': "Un jour, Fıstık a trouvé une petite graine.",
        'es': "Un día Fıstık encontró una pequeña semilla.",
      },
      {
        'tr': "Tohumu toprağa ekti ve üstünü örttü.",
        'en': "Fıstık planted the seed in the soil and covered it.",
        'de': "Fıstık pflanzte den Samen in die Erde und deckte ihn zu.",
        'fr': "Fıstık a planté la graine dans la terre et l'a recouverte.",
        'es': "Fıstık plantó la semilla en la tierra y la cubrió.",
      },
      {
        'tr': "Her gün ona su verdi.",
        'en': "Every day Fıstık gave it water.",
        'de': "Jeden Tag gab Fıstık ihm Wasser.",
        'fr': "Chaque jour, Fıstık lui a donné de l'eau.",
        'es': "Cada día Fıstık le daba agua.",
      },
      {
        'tr': "Güneş toprağı ısıttı. Fıstık sabırla bekledi.",
        'en': "The sun warmed the soil. Fıstık waited patiently.",
        'de': "Die Sonne wärmte die Erde. Fıstık wartete geduldig.",
        'fr': "Le soleil a réchauffé la terre. Fıstık a attendu patiemment.",
        'es': "El sol calentó la tierra. Fıstık esperó con paciencia.",
      },
      {
        'tr': "Bir sabah topraktan minik yeşil bir filiz çıktı.",
        'en': "One morning a tiny green sprout came out of the soil.",
        'de': "Eines Morgens kam ein winziger grüner Spross aus der Erde.",
        'fr': "Un matin, une toute petite pousse verte est sortie de la terre.",
        'es': "Una mañana salió de la tierra un pequeño brote verde.",
      },
      {
        'tr': "Filiz büyüdü ve kocaman sarı bir ayçiçeği oldu. Fıstık çok mutluydu.",
        'en': "The sprout grew into a big yellow sunflower. Fıstık was very happy.",
        'de': "Der Spross wuchs zu einer großen gelben Sonnenblume. Fıstık freute sich sehr.",
        'fr': "La pousse est devenue un grand tournesol jaune. Quelle joie pour Fıstık !",
        'es': "El brote creció y se convirtió en un gran girasol amarillo. ¡Qué alegría para Fıstık!",
      },
    ],
  ),
];
