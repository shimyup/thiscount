import '../../models/letter.dart';

/// "Welcome letter" — a curated, pre-delivered letter from the Thiscount
/// team that lands in every new user's mailbox on signup. Kills the
/// empty-inbox Day-0 feeling and teaches the delivery metaphor by doing.

// Thiscount HQ fictional origin — Seoul coordinates (brand home).
const double _hqLat = 37.5665;
const double _hqLng = 126.9780;
const String _hqCountry = '대한민국';
const String _hqFlag = '🇰🇷';

const Map<String, String> _teamName = {
  'ko': 'Thiscount 팀',
  'en': 'The Thiscount Team',
  'ja': 'Thiscount チーム',
  'zh': 'Thiscount 团队',
  'fr': "L'équipe Thiscount",
  'de': 'Das Thiscount Team',
  'es': 'El equipo de Thiscount',
  'pt': 'A equipe Thiscount',
  'ru': 'Команда Thiscount',
  'tr': 'Thiscount Ekibi',
  'ar': 'فريق Thiscount',
  'it': 'Il team Thiscount',
  'hi': 'Thiscount टीम',
  'th': 'ทีม Thiscount',
};

const Map<String, String> _body = {
  'ko': '''반가워요, 여행자님.

Thiscount에 오신 걸 환영해요. 이 편지는 지구 반대편까지 천천히 여행하는 편지의 첫 번째 도착이에요.

이곳엔 알고리즘도 피드도 없어요. 편지는 육로로, 항공으로, 해운으로 천천히 이동하고, 누군가의 우편함에 도착해 조용히 읽혀요.

오늘 한 통만 써보세요. 창 밖 풍경 한 문장이어도 괜찮아요. 편지가 출발하면, 지구 어딘가의 누군가에게 도착할 거예요.

천천히, 그리고 오래 머물러 주세요. 🕊️''',
  'en': '''Welcome, traveler.

This is the first letter to land in your mailbox — a letter that crossed the world slowly, just for you.

There are no feeds here and no algorithms. Letters move by land, air, and sea, arriving quietly in someone else's mailbox to be read when they're ready.

Try writing one today. A single sentence about what's outside your window is enough. Once it leaves, it'll travel to someone, somewhere.

Take it slow. Stay a while. 🕊️''',
  'ja': '''ようこそ、旅人さん。

Thiscountへようこそ。この手紙は、地球をゆっくり旅してきた最初の到着です。

ここにはアルゴリズムもフィードもありません。手紙は陸路・空路・海路で静かに移動し、誰かのポストに届き、静かに読まれます。

今日、一通だけ書いてみてください。窓の外の景色を一文だけでも大丈夫。送り出せば、地球のどこかの誰かに届きます。

ゆっくり、そして長くとどまってくださいね。🕊️''',
  'zh': '''你好，旅人。

欢迎来到 Thiscount。这封信是你信箱里的第一封——一封慢慢穿越地球来到你身边的信。

这里没有算法，也没有信息流。信件由陆路、空运和海运缓缓移动，悄悄抵达某人的信箱，静静地被人读到。

今天写一封试试吧。哪怕只是一句关于窗外风景的话。寄出之后，它会旅行到地球上的某个人手中。

慢慢来，久一点。🕊️''',
  'fr': '''Bienvenue, voyageur.

Voici la première lettre à atterrir dans votre boîte — elle a traversé le monde lentement, pour vous.

Ici, pas de fil d'actualité, pas d'algorithme. Les lettres voyagent par la terre, l'air et la mer, arrivent tranquillement dans une autre boîte et s'y lisent en silence.

Essayez d'en écrire une aujourd'hui. Une phrase sur ce que vous voyez par votre fenêtre suffit. Une fois partie, elle trouvera quelqu'un, quelque part.

Prenez votre temps. Restez un moment. 🕊️''',
  'de': '''Willkommen, Reisende.

Dies ist der erste Brief, der in deinem Briefkasten landet — einer, der langsam um die halbe Welt gereist ist.

Hier gibt es keine Feeds und keine Algorithmen. Briefe bewegen sich über Land, durch die Luft und über das Meer, sie kommen leise in Briefkästen an und werden in Ruhe gelesen.

Schreib heute einen. Ein einziger Satz über das, was vor deinem Fenster liegt, reicht schon. Ist er erst unterwegs, findet er jemanden, irgendwo.

Lass dir Zeit. Bleib eine Weile. 🕊️''',
  'es': '''Bienvenido, viajero.

Esta es la primera carta que llega a tu buzón — un mensaje que ha cruzado el mundo lentamente, solo para ti.

Aquí no hay feeds ni algoritmos. Las cartas se mueven por tierra, aire y mar, llegan discretamente a otro buzón y se leen en calma.

Escribe una hoy. Una frase sobre lo que ves por la ventana basta. Cuando parta, encontrará a alguien, en algún lugar.

Ve despacio. Quédate un rato. 🕊️''',
  'pt': '''Olá, viajante.

Esta é a primeira carta a chegar à sua caixa — uma carta que atravessou o mundo devagar, só para você.

Aqui não há feeds nem algoritmos. As cartas se movem por terra, pelo ar e pelo mar, chegam em silêncio a outra caixa de correio e são lidas com calma.

Tente escrever uma hoje. Uma frase sobre o que vê pela janela já basta. Quando partir, encontrará alguém, em algum lugar.

Vá devagar. Fique por aqui. 🕊️''',
  'ru': '''Здравствуй, путешественник.

Это первое письмо в твоём ящике — оно медленно пересекло мир, чтобы попасть именно к тебе.

Здесь нет лент и алгоритмов. Письма движутся по земле, воздуху и морю, тихо приходят в чей-то ящик и спокойно читаются.

Попробуй сегодня написать одно. Достаточно одной фразы о том, что видно из твоего окна. Отправленное, оно найдёт кого-то, где-то.

Не торопись. Побудь здесь. 🕊️''',
  'tr': '''Hoş geldin, yolcu.

Bu, posta kutuna düşen ilk mektup — dünyayı yavaşça dolaşıp sana ulaştı.

Burada akış yok, algoritma yok. Mektuplar karadan, havadan ve denizden usulca ilerler, birinin kutusuna sessizce varır ve sakince okunur.

Bugün bir tane yazmayı dene. Penceren dışındaki manzara hakkında tek bir cümle yeter. Yola çıktığında, bir yerde birini bulacak.

Yavaş ilerle. Bir süre kal. 🕊️''',
  'ar': '''مرحباً أيها المسافر.

هذه أول رسالة تصل إلى صندوقك — رسالة عبرت العالم ببطء لتصل إليك.

لا توجد هنا خلاصات ولا خوارزميات. الرسائل تتحرك براً وجواً وبحراً، وتصل بهدوء إلى صندوق شخص آخر لتُقرأ في سكون.

حاول كتابة رسالة واحدة اليوم. جملة واحدة عما تراه من نافذتك تكفي. وحين تنطلق، ستجد أحداً ما، في مكانٍ ما.

خذ وقتك. ابقَ قليلاً. 🕊️''',
  'it': '''Benvenuto, viaggiatore.

Questa è la prima lettera ad atterrare nella tua buca — una lettera che ha attraversato il mondo lentamente, solo per te.

Qui non ci sono feed né algoritmi. Le lettere si muovono via terra, aria e mare, arrivano in silenzio nella cassetta di qualcun altro e vengono lette con calma.

Prova a scriverne una oggi. Basta una frase su ciò che vedi dalla finestra. Una volta partita, troverà qualcuno, da qualche parte.

Prendi il tuo tempo. Fermati un po'. 🕊️''',
  'hi': '''स्वागत है, यात्री।

यह आपके मेलबॉक्स में उतरने वाला पहला पत्र है — एक ऐसा पत्र जिसने दुनिया को धीरे-धीरे पार किया, सिर्फ आपके लिए।

यहाँ कोई फ़ीड नहीं, कोई एल्गोरिद्म नहीं। पत्र भूमि, वायु और समुद्र से चलते हैं, किसी और के मेलबॉक्स में चुपचाप पहुँचते हैं और शांति से पढ़े जाते हैं।

आज एक पत्र लिखने की कोशिश करें। खिड़की के बाहर का एक वाक्य भी काफ़ी है। रवाना होते ही यह कहीं न कहीं किसी को मिल जाएगा।

धीरे चलें। कुछ देर ठहरें। 🕊️''',
  'th': '''ยินดีต้อนรับนะ นักเดินทาง

นี่คือจดหมายฉบับแรกที่มาถึงกล่องของคุณ — จดหมายที่เดินทางช้า ๆ ข้ามโลกมาเพื่อคุณ

ที่นี่ไม่มีฟีด ไม่มีอัลกอริทึม จดหมายเดินทางทางบก ทางอากาศ และทางทะเล มาถึงกล่องของใครสักคนอย่างเงียบ ๆ แล้วถูกอ่านอย่างสงบ

ลองเขียนสักฉบับในวันนี้ เพียงประโยคเดียวเกี่ยวกับสิ่งที่เห็นนอกหน้าต่างก็พอ เมื่อถูกส่งออกไป มันจะไปถึงใครบางคนที่ไหนสักแห่ง

ค่อย ๆ ไปนะ อยู่นาน ๆ หน่อย 🕊️''',
};

String _pick(Map<String, String> m, String lang) => m[lang] ?? m['en']!;

/// Builds the welcome letter as an already-delivered, ready-to-read inbox
/// item destined for this specific user.
Letter buildWelcomeLetter({
  required String userId,
  required String userCountry,
  required String userCountryFlag,
  required double userLat,
  required double userLng,
  required String langCode,
}) {
  final origin = LatLng(_hqLat, _hqLng);
  final dest = LatLng(userLat, userLng);
  final segments = LogisticsHubs.buildRoute(
    fromCountry: _hqCountry,
    fromCity: origin,
    toCountry: userCountry,
    toCity: dest,
  );
  for (final s in segments) {
    s.progress = 1.0;
  }
  final totalMin = segments.fold<int>(0, (s, seg) => s + seg.estimatedMinutes);
  final now = DateTime.now();

  return Letter(
    id: 'welcome_$userId',
    senderId: 'letter_go_welcome',
    senderName: _pick(_teamName, langCode),
    senderCountry: _hqCountry,
    senderCountryFlag: _hqFlag,
    content: _pick(_body, langCode),
    originLocation: origin,
    destinationLocation: dest,
    destinationCountry: userCountry,
    destinationCountryFlag: userCountryFlag.isNotEmpty ? userCountryFlag : '🌍',
    segments: segments,
    currentSegmentIndex: segments.isEmpty ? 0 : segments.length - 1,
    status: DeliveryStatus.delivered,
    sentAt: now.subtract(const Duration(hours: 1)),
    arrivedAt: now,
    arrivalTime: now,
    isAnonymous: false,
    estimatedTotalMinutes: totalMin,
    senderIsBrand: true,
    senderTier: LetterSenderTier.brand,
    paperStyle: 0,
    fontStyle: 0,
  );
}
