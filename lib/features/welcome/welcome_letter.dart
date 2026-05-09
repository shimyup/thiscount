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

// Build 265: 트라이얼 문장을 본문에서 분리 — 이미 Premium/Brand 인 사용자가
// 재로그인하면 grantWelcomeTrial 가 no-op 이라 trial 미부여인데도 카피는
// "trial just started" 였던 회귀 수정. buildWelcomeLetter(withTrial:) 로 분기.
const Map<String, String> _body = {
  'ko': '''반가워요, 여행자님.

Thiscount에 오신 걸 환영해요. 이 메시지는 지구 반대편까지 천천히 여행한 첫 번째 도착이에요.

이곳엔 알고리즘도 피드도 없어요. 메시지와 쿠폰은 육로로, 항공으로, 해운으로 천천히 이동하고, 누군가의 받은함에 조용히 도착해요.

지도를 열어 근처에 떠있는 혜택을 주워 써보세요. 메시지 한 줄이라도 좋으니, 누군가에게 보내봐도 좋아요.

천천히, 그리고 오래 머물러 주세요. 🕊️''',
  'en': '''Welcome, traveler.

This is the first message to land in your wallet — one that crossed the world slowly, just for you.

There are no feeds here and no algorithms. Messages and coupons move by land, air, and sea, arriving quietly in someone else's wallet to be opened when they're ready.

Open the map and grab a nearby coupon. Or send a single line to someone — that's enough.

Take it slow. Stay a while. 🕊️''',
  'ja': '''ようこそ、旅人さん。

Thiscountへようこそ。このメッセージは、地球をゆっくり旅してきた最初の到着です。

ここにはアルゴリズムもフィードもありません。メッセージとクーポンは陸路・空路・海路で静かに移動し、誰かの受信箱に届きます。

地図を開いて、近くに浮かぶ特典を拾ってみてください。一文のメッセージを誰かに送ってみるのもいいですね。

ゆっくり、そして長くとどまってくださいね。🕊️''',
  'zh': '''你好，旅人。

欢迎来到 Thiscount。这条消息是你钱包里的第一份——一份慢慢穿越地球来到你身边的礼物。

这里没有算法，也没有信息流。消息和优惠券由陆路、空运和海运缓缓移动，悄悄抵达某人的钱包。

打开地图，把附近的优惠券拾起来用吧。也可以给某人发一句话——一行就够了。

慢慢来，久一点。🕊️''',
  'fr': '''Bienvenue, voyageur.

Voici le premier message à arriver dans votre porte-monnaie — il a traversé le monde lentement, pour vous.

Ici, pas de fil d'actualité, pas d'algorithme. Messages et coupons voyagent par la terre, l'air et la mer, arrivent tranquillement dans le porte-monnaie de quelqu'un.

Ouvrez la carte et ramassez un coupon proche. Ou envoyez une seule phrase à quelqu'un — c'est suffisant.

Prenez votre temps. Restez un moment. 🕊️''',
  'de': '''Willkommen, Reisende.

Dies ist die erste Nachricht in deiner Geldbörse — sie ist langsam um die halbe Welt gereist.

Hier gibt es keine Feeds und keine Algorithmen. Nachrichten und Coupons bewegen sich über Land, Luft und Meer und kommen leise in jemandes Geldbörse an.

Öffne die Karte und schnapp dir einen Coupon in der Nähe. Oder schick jemandem einen einzigen Satz — das reicht.

Lass dir Zeit. Bleib eine Weile. 🕊️''',
  'es': '''Bienvenido, viajero.

Este es el primer mensaje que llega a tu cartera — un mensaje que ha cruzado el mundo lentamente, solo para ti.

Aquí no hay feeds ni algoritmos. Los mensajes y cupones se mueven por tierra, aire y mar, y llegan discretamente a la cartera de alguien.

Abre el mapa y recoge un cupón cercano. O envía una sola frase a alguien — basta con eso.

Ve despacio. Quédate un rato. 🕊️''',
  'pt': '''Olá, viajante.

Esta é a primeira mensagem a chegar à sua carteira — uma mensagem que atravessou o mundo devagar, só para você.

Aqui não há feeds nem algoritmos. Mensagens e cupons movem-se por terra, ar e mar, chegando em silêncio à carteira de alguém.

Abra o mapa e pegue um cupom próximo. Ou envie uma única frase a alguém — basta isso.

Vá devagar. Fique por aqui. 🕊️''',
  'ru': '''Здравствуй, путешественник.

Это первое сообщение в твоём кошельке — оно медленно пересекло мир, чтобы попасть именно к тебе.

Здесь нет лент и алгоритмов. Сообщения и купоны движутся по земле, воздуху и морю и тихо приходят в чей-то кошелёк.

Открой карту и подбери ближайший купон. Или отправь кому-нибудь одну строку — этого достаточно.

Не торопись. Побудь здесь. 🕊️''',
  'tr': '''Hoş geldin, yolcu.

Bu, cüzdanına düşen ilk mesaj — dünyayı yavaşça dolaşıp sana ulaştı.

Burada akış yok, algoritma yok. Mesajlar ve kuponlar karadan, havadan ve denizden usulca ilerler, birinin cüzdanına sessizce varır.

Haritayı aç ve yakındaki bir kuponu kap. Ya da birine tek bir cümle gönder — o kadarı yeterli.

Yavaş ilerle. Bir süre kal. 🕊️''',
  'ar': '''مرحباً أيها المسافر.

هذه أول رسالة تصل إلى محفظتك — عبرت العالم ببطء لتصل إليك.

لا توجد هنا خلاصات ولا خوارزميات. الرسائل والكوبونات تتحرك براً وجواً وبحراً وتصل بهدوء إلى محفظة شخص ما.

افتح الخريطة والتقط كوبوناً قريباً. أو أرسل سطراً واحداً لأحد — هذا يكفي.

خذ وقتك. ابقَ قليلاً. 🕊️''',
  'it': '''Benvenuto, viaggiatore.

Questo è il primo messaggio ad atterrare nel tuo portafoglio — ha attraversato il mondo lentamente, solo per te.

Qui non ci sono feed né algoritmi. Messaggi e coupon si muovono via terra, aria e mare e arrivano in silenzio nel portafoglio di qualcuno.

Apri la mappa e raccogli un coupon vicino. O manda una sola frase a qualcuno — basta così.

Prendi il tuo tempo. Fermati un po'. 🕊️''',
  'hi': '''स्वागत है, यात्री।

यह आपकी वॉलेट में पहुँचने वाला पहला संदेश है — एक ऐसा संदेश जिसने दुनिया को धीरे-धीरे पार किया, सिर्फ आपके लिए।

यहाँ कोई फ़ीड नहीं, कोई एल्गोरिद्म नहीं। संदेश और कूपन भूमि, वायु और समुद्र से चलते हैं, किसी की वॉलेट में चुपचाप पहुँचते हैं।

नक्शा खोलें और पास का कोई कूपन उठा लें। या किसी को एक पंक्ति भेज दें — इतना काफ़ी है।

धीरे चलें। कुछ देर ठहरें। 🕊️''',
  'th': '''ยินดีต้อนรับนะ นักเดินทาง

นี่คือข้อความฉบับแรกที่มาถึงกระเป๋าของคุณ — เดินทางช้า ๆ ข้ามโลกมาเพื่อคุณ

ที่นี่ไม่มีฟีด ไม่มีอัลกอริทึม ข้อความและคูปองเดินทางทางบก ทางอากาศ และทางทะเล มาถึงกระเป๋าของใครสักคนอย่างเงียบ ๆ

เปิดแผนที่แล้วเก็บคูปองใกล้ ๆ ดู หรือส่งข้อความสั้น ๆ ให้ใครสักคนก็ได้ — เพียงประโยคเดียวก็พอ

ค่อย ๆ ไปนะ อยู่นาน ๆ หน่อย 🕊️''',
};

// 트라이얼이 실제로 부여된 신규 가입자에게만 본문 첫 단락 뒤에 삽입.
const Map<String, String> _trialMention = {
  'ko': '가입 기념으로 7일간 Premium 체험이 함께 시작됐어요.',
  'en': 'As a welcome gift, your 7-day Premium trial just started.',
  'ja': '登録特典として、7日間のPremium体験が始まりました。',
  'zh': '注册礼物，7天 Premium 体验同时开始。',
  'fr': 'En cadeau de bienvenue, votre essai Premium de 7 jours vient de démarrer.',
  'de': 'Als Willkommensgeschenk startet jetzt deine 7-tägige Premium-Testphase.',
  'es': 'Como regalo de bienvenida, tu prueba Premium de 7 días acaba de comenzar.',
  'pt': 'Como presente de boas-vindas, sua avaliação Premium de 7 dias acabou de começar.',
  'ru': 'В подарок за регистрацию запущен 7-дневный пробный Premium.',
  'tr': 'Hoş geldin hediyesi olarak 7 günlük Premium deneme süren başladı.',
  'ar': 'هديةً للترحيب، بدأت تجربة Premium لمدة 7 أيام.',
  'it': 'Come regalo di benvenuto, è iniziata la tua prova Premium di 7 giorni.',
  'hi': 'स्वागत उपहार के रूप में 7-दिन का Premium ट्रायल शुरू हो गया है।',
  'th': 'ของขวัญต้อนรับ — ทดลอง Premium 7 วันเริ่มแล้ว',
};

/// 본문 + (선택) 트라이얼 안내 문장. trial 이 실제로 부여됐을 때만 노출.
String _buildBody(String langCode, {required bool withTrial}) {
  final base = _pick(_body, langCode);
  if (!withTrial) return base;
  final mention = _trialMention[langCode] ?? _trialMention['en']!;
  // 첫 단락(빈 줄까지) 다음에 트라이얼 문장을 삽입. \r\n / 비공백 화이트
  // 스페이스 / NBSP 가 섞여도 견디도록 RegExp 사용.
  final parts = base.split(RegExp(r'\n[\s ]*\n'));
  if (parts.length < 2) return '$base\n\n$mention';
  return '${parts.first}\n\n$mention\n\n${parts.skip(1).join('\n\n')}';
}

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
  bool withTrial = false,
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
    content: _buildBody(langCode, withTrial: withTrial),
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
