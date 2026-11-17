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
  Story(
    'rain',
    {
      'tr': "Yağmurlu Gün",
      'en': "The Rainy Day",
      'de': "Der Regentag",
      'fr': "Le jour de pluie",
      'es': "El día de lluvia",
    },
    ['🌧️', '🧥', '☂️', '💦', '🌈', '😊'],
    [
      {
        'tr': "Fıstık dışarıda oynamak istiyordu ama yağmur yağıyordu.",
        'en': "Fıstık wanted to play outside, but it was raining.",
        'de': "Fıstık wollte draußen spielen, aber es regnete.",
        'fr': "Fıstık voulait jouer dehors, mais il pleuvait.",
        'es': "Fıstık quería jugar fuera, pero estaba lloviendo.",
      },
      {
        'tr': "Sarı yağmurluğunu ve kırmızı çizmelerini giydi.",
        'en': "Fıstık put on a yellow raincoat and red boots.",
        'de': "Fıstık zog die gelbe Regenjacke und die roten Stiefel an.",
        'fr': "Fıstık a mis son imperméable jaune et ses bottes rouges.",
        'es': "Fıstık se puso el impermeable amarillo y las botas rojas.",
      },
      {
        'tr': "Şemsiyesini aldı ve bahçeye çıktı.",
        'en': "Fıstık took the umbrella and went out into the garden.",
        'de': "Fıstık nahm den Regenschirm und ging in den Garten.",
        'fr': "Fıstık a pris son parapluie pour aller au jardin.",
        'es': "Fıstık tomó el paraguas y salió al jardín.",
      },
      {
        'tr': "Su birikintilerinde zıpladı: şlap, şlap!",
        'en': "Fıstık jumped in the puddles: splash, splash!",
        'de': "Fıstık sprang in die Pfützen: platsch, platsch!",
        'fr': "Fıstık a sauté dans les flaques : plouf, plouf !",
        'es': "Fıstık saltó en los charcos: ¡chof, chof!",
      },
      {
        'tr': "Yağmur durunca gökyüzünde kocaman bir gökkuşağı çıktı.",
        'en': "When the rain stopped, a big rainbow appeared in the sky.",
        'de':
            "Als der Regen aufhörte, erschien ein großer Regenbogen am Himmel.",
        'fr': "Quand la pluie s'est arrêtée, un grand arc-en-ciel est apparu dans le ciel.",
        'es': "Cuando paró la lluvia, apareció un gran arcoíris en el cielo.",
      },
      {
        'tr': "Fıstık gökkuşağının renklerine baktı ve çok sevindi.",
        'en': "Fıstık looked at the colors of the rainbow and smiled with joy.",
        'de': "Fıstık sah die Farben des Regenbogens an und freute sich sehr.",
        'fr': "Fıstık a regardé les couleurs de l'arc-en-ciel. Quelle joie !",
        'es': "Fıstık miró los colores del arcoíris. ¡Qué alegría!",
      },
    ],
  ),
  Story(
    'share',
    {
      'tr': "Elma Ağacı",
      'en': "The Apple Tree",
      'de': "Der Apfelbaum",
      'fr': "Le pommier",
      'es': "El manzano",
    },
    ['🍎', '🌳', '🧺', '🍏', '🤝', '😊'],
    [
      {
        'tr': "Fıstık bahçedeki ağaçta kırmızı elmalar gördü.",
        'en': "Fıstık saw red apples on the tree in the garden.",
        'de': "Fıstık sah rote Äpfel am Baum im Garten.",
        'fr': "Fıstık a vu des pommes rouges sur l'arbre du jardin.",
        'es': "Fıstık vio manzanas rojas en el árbol del jardín.",
      },
      {
        'tr': "Elmalar çok yüksekteydi, Fıstık yetişemedi.",
        'en': "The apples were very high, and Fıstık could not reach them.",
        'de': "Die Äpfel hingen sehr hoch, Fıstık kam nicht heran.",
        'fr':
            "Les pommes étaient très haut, Fıstık ne pouvait pas les attraper.",
        'es': "Las manzanas estaban muy altas y Fıstık no llegaba.",
      },
      {
        'tr': "Tavşan ve ördek yardıma geldi. Tavşan bir sepet getirdi.",
        'en': "The rabbit and the duck came to help. The rabbit brought a basket.",
        'de': "Der Hase und die Ente kamen zu Hilfe. Der Hase brachte einen Korb.",
        'fr': "Le lapin et le canard sont venus aider. Le lapin a apporté un panier.",
        'es':
            "El conejo y el pato vinieron a ayudar. El conejo trajo una cesta.",
      },
      {
        'tr': "Fıstık ağacı yavaşça salladı, elmalar sepete düştü.",
        'en': "Fıstık gently shook the tree, and the apples fell into the basket.",
        'de': "Fıstık schüttelte den Baum sanft, und die Äpfel fielen in den Korb.",
        'fr': "Fıstık a secoué doucement l'arbre, et les pommes sont tombées dans le panier.",
        'es': "Fıstık sacudió el árbol con cuidado y las manzanas cayeron en la cesta.",
      },
      {
        'tr': "Fıstık elmaları arkadaşlarıyla paylaştı.",
        'en': "Fıstık shared the apples with friends.",
        'de': "Fıstık teilte die Äpfel mit den Freunden.",
        'fr': "Fıstık a partagé les pommes avec ses amis.",
        'es': "Fıstık compartió las manzanas con sus amigos.",
      },
      {
        'tr': "Paylaşınca elmalar daha da tatlı oldu. Hepsi çok mutluydu.",
        'en': "Shared apples tasted even sweeter. Everyone was very happy.",
        'de':
            "Geteilte Äpfel schmeckten noch süßer. Alle waren sehr glücklich.",
        'fr': "Partagées, les pommes étaient encore plus sucrées. Tout le monde était très content.",
        'es': "Compartidas, las manzanas sabían aún más dulces. Todos estaban muy felices.",
      },
    ],
  ),
  Story(
    'sleep',
    {
      'tr': "Uyku Vakti",
      'en': "Bedtime",
      'de': "Schlafenszeit",
      'fr': "L'heure du dodo",
      'es': "La hora de dormir",
    },
    ['⭐', '🪥', '👕', '📖', '🧸', '💤'],
    [
      {
        'tr': "Akşam oldu, gökyüzünde yıldızlar parladı.",
        'en': "Evening came, and stars twinkled in the sky.",
        'de': "Es wurde Abend, und die Sterne funkelten am Himmel.",
        'fr': "Le soir est venu, et les étoiles ont brillé dans le ciel.",
        'es': "Llegó la noche y las estrellas brillaron en el cielo.",
      },
      {
        'tr': "Fıstık dişlerini güzelce fırçaladı.",
        'en': "Fıstık brushed every tooth nice and clean.",
        'de': "Fıstık putzte gründlich die Zähne.",
        'fr': "Fıstık s'est bien brossé les dents.",
        'es': "Fıstık se cepilló bien los dientes.",
      },
      {
        'tr': "Yıldızlı pijamalarını giydi.",
        'en': "Fıstık put on pajamas with little stars.",
        'de': "Fıstık zog den Schlafanzug mit den kleinen Sternen an.",
        'fr': "Fıstık a mis son pyjama à petites étoiles.",
        'es': "Fıstık se puso el pijama de estrellitas.",
      },
      {
        'tr': "Yatağına uzandı ve en sevdiği kitaba baktı.",
        'en': "Fıstık lay in bed and looked at a favorite book.",
        'de': "Fıstık legte sich ins Bett und schaute das Lieblingsbuch an.",
        'fr': "Au lit, Fıstık a regardé son livre préféré.",
        'es': "Fıstık se acostó en la cama y miró su libro favorito.",
      },
      {
        'tr': "Oyuncak ayısına sarıldı ve gözlerini kapattı.",
        'en': "Fıstık hugged the teddy bear and closed both eyes.",
        'de': "Fıstık kuschelte mit dem Teddybären und schloss die Augen.",
        'fr': "Fıstık a serré son ours en peluche et a fermé les yeux.",
        'es': "Fıstık abrazó a su osito de peluche y cerró los ojos.",
      },
      {
        'tr': "İyi geceler, Fıstık! Tatlı rüyalar!",
        'en': "Good night, Fıstık! Sweet dreams!",
        'de': "Gute Nacht, Fıstık! Träum süß!",
        'fr': "Bonne nuit, Fıstık ! Fais de beaux rêves !",
        'es': "¡Buenas noches, Fıstık! ¡Dulces sueños!",
      },
    ],
  ),
];
