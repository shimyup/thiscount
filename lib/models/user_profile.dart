class ActivityScore {
  int receivedCount;
  int replyCount;
  int sentCount;
  int likeCount; // 받은 좋아요 수
  int ratingTotal; // 별점 합계
  int ratingCount; // 별점 받은 횟수

  ActivityScore({
    this.receivedCount = 0,
    this.replyCount = 0,
    this.sentCount = 0,
    this.likeCount = 0,
    this.ratingTotal = 0,
    this.ratingCount = 0,
  });

  double get avgRating => ratingCount > 0 ? ratingTotal / ratingCount : 0.0;

  // 랭킹 점수: 받은편지 + 좋아요 + 답장 + 별점
  double get towerHeight =>
      (receivedCount * 1.2) +
      (likeCount * 2.0) +
      (replyCount * 1.5) +
      (sentCount * 0.8) +
      (avgRating * 3.0);

  // 랭킹 스코어 (타워 높이와 동일하게 사용)
  double get rankScore => towerHeight;

  int get towerFloors => (towerHeight / 5).floor().clamp(1, 99);

  Map<String, dynamic> toJson() => {
    'receivedCount': receivedCount,
    'replyCount': replyCount,
    'sentCount': sentCount,
    'likeCount': likeCount,
    'ratingTotal': ratingTotal,
    'ratingCount': ratingCount,
  };

  static ActivityScore fromJson(Map<String, dynamic> j) => ActivityScore(
    receivedCount: j['receivedCount'] as int? ?? 0,
    replyCount: j['replyCount'] as int? ?? 0,
    sentCount: j['sentCount'] as int? ?? 0,
    likeCount: j['likeCount'] as int? ?? 0,
    ratingTotal: j['ratingTotal'] as int? ?? 0,
    ratingCount: j['ratingCount'] as int? ?? 0,
  );

  TowerTier get tier {
    final h = towerHeight;
    if (h < 6) return TowerTier.shack;
    if (h < 15) return TowerTier.cottage;
    if (h < 30) return TowerTier.house;
    if (h < 50) return TowerTier.townhouse;
    if (h < 80) return TowerTier.building;
    if (h < 120) return TowerTier.office;
    if (h < 170) return TowerTier.skyscraper;
    if (h < 250) return TowerTier.supertall;
    if (h < 330) return TowerTier.megatower;
    return TowerTier.landmark;
  }

  double get tierMin {
    switch (tier) {
      case TowerTier.shack:
        return 0;
      case TowerTier.cottage:
        return 6;
      case TowerTier.house:
        return 15;
      case TowerTier.townhouse:
        return 30;
      case TowerTier.building:
        return 50;
      case TowerTier.office:
        return 80;
      case TowerTier.skyscraper:
        return 120;
      case TowerTier.supertall:
        return 170;
      case TowerTier.megatower:
        return 250;
      case TowerTier.landmark:
        return 330;
    }
  }

  double get tierMax {
    switch (tier) {
      case TowerTier.shack:
        return 6;
      case TowerTier.cottage:
        return 15;
      case TowerTier.house:
        return 30;
      case TowerTier.townhouse:
        return 50;
      case TowerTier.building:
        return 80;
      case TowerTier.office:
        return 120;
      case TowerTier.skyscraper:
        return 170;
      case TowerTier.supertall:
        return 250;
      case TowerTier.megatower:
        return 330;
      case TowerTier.landmark:
        return 500;
    }
  }

  double get tierProgress =>
      ((towerHeight - tierMin) / (tierMax - tierMin)).clamp(0.0, 1.0);

  // 명성 칭호 (활동 점수 기반 시적 호칭) — 14-language
  String reputationTitleL(String langCode) {
    final h = towerHeight;
    if (h < 6) return _tFame(0, langCode);
    if (h < 15) return _tFame(1, langCode);
    if (h < 30) return _tFame(2, langCode);
    if (h < 50) return _tFame(3, langCode);
    if (h < 80) return _tFame(4, langCode);
    if (h < 120) return _tFame(5, langCode);
    if (h < 170) return _tFame(6, langCode);
    if (h < 250) return _tFame(7, langCode);
    if (h < 330) return _tFame(8, langCode);
    return _tFame(9, langCode);
  }

  /// Backward-compat — defaults to Korean
  String get reputationTitle => reputationTitleL('ko');

  static String _tFame(int idx, String lc) =>
      _fameTitles[idx][lc] ?? _fameTitles[idx]['en']!;

  static const List<Map<String, String>> _fameTitles = [
    // 0 — shack
    {'ko': '새내기 카운터', 'en': 'Novice Counter', 'ja': '初心者カウンター', 'zh': '新手计数员', 'fr': 'Counter Novice', 'de': 'Neuling-Counter', 'es': 'Counter Novato', 'pt': 'Counter Novato', 'ru': 'Начинающий Counter', 'tr': 'Çaylak Counter', 'ar': 'Counter مبتدئ', 'it': 'Counter Novizio', 'hi': 'नौसिखिया Counter', 'th': 'Counter มือใหม่'},
    // 1 — cottage
    {'ko': '쿠폰 수집가', 'en': 'Coupon Collector', 'ja': 'クーポン収集家', 'zh': '优惠券收藏家', 'fr': 'Collecteur de Coupons', 'de': 'Coupon-Sammler', 'es': 'Coleccionista de Cupones', 'pt': 'Colecionador de Cupões', 'ru': 'Собиратель Купонов', 'tr': 'Kupon Koleksiyoncusu', 'ar': 'جامع القسائم', 'it': 'Collezionista di Coupon', 'hi': 'कूपन संग्रहकर्ता', 'th': 'นักสะสมคูปอง'},
    // 2 — house
    {'ko': '바람의 헌터', 'en': 'Wind Hunter', 'ja': '風のハンター', 'zh': '风之猎人', 'fr': 'Chasseur du Vent', 'de': 'Windjäger', 'es': 'Cazador del Viento', 'pt': 'Caçador do Vento', 'ru': 'Охотник Ветра', 'tr': 'Rüzgâr Avcısı', 'ar': 'صياد الرياح', 'it': 'Cacciatore del Vento', 'hi': 'हवा का शिकारी', 'th': 'นักล่าแห่งสายลม'},
    // 3 — townhouse
    {'ko': '항구의 헌터', 'en': 'Harbor Hunter', 'ja': '港のハンター', 'zh': '港口猎人', 'fr': 'Chasseur du Port', 'de': 'Hafenjäger', 'es': 'Cazador del Puerto', 'pt': 'Caçador do Porto', 'ru': 'Охотник Гавани', 'tr': 'Liman Avcısı', 'ar': 'صياد الميناء', 'it': 'Cacciatore del Porto', 'hi': 'बंदरगाह का शिकारी', 'th': 'นักล่าแห่งท่าเรือ'},
    // 4 — building
    {'ko': '도시의 발견러', 'en': 'City Finder', 'ja': '都市の発見者', 'zh': '城市发现者', 'fr': 'Découvreur de la Ville', 'de': 'Stadtentdecker', 'es': 'Descubridor de la Ciudad', 'pt': 'Descobridor da Cidade', 'ru': 'Исследователь Города', 'tr': 'Şehir Kâşifi', 'ar': 'مكتشف المدينة', 'it': 'Esploratore Urbano', 'hi': 'नगर खोजी', 'th': 'นักค้นพบแห่งเมือง'},
    // 5 — office
    {'ko': '골목의 명사수', 'en': 'Alley Sharpshooter', 'ja': '路地の名手', 'zh': '巷弄神射手', 'fr': 'Tireur des Ruelles', 'de': 'Gassen-Scharfschütze', 'es': 'Tirador de Callejones', 'pt': 'Atirador dos Becos', 'ru': 'Меткий Стрелок Переулков', 'tr': 'Sokak Nişancısı', 'ar': 'قناص الأزقة', 'it': 'Tiratore dei Vicoli', 'hi': 'गली के निशानेबाज़', 'th': 'มือฉมังแห่งตรอกซอย'},
    // 6 — skyscraper
    {'ko': '천 개의 혜택 주인', 'en': 'Master of a Thousand Rewards', 'ja': '千の特典の主', 'zh': '千福之主', 'fr': 'Maître des Mille Récompenses', 'de': 'Herr der Tausend Belohnungen', 'es': 'Maestro de Mil Recompensas', 'pt': 'Mestre das Mil Recompensas', 'ru': 'Хозяин Тысячи Наград', 'tr': 'Bin Ödülün Efendisi', 'ar': 'سيد الألف مكافأة', 'it': 'Maestro delle Mille Ricompense', 'hi': 'हज़ार पुरस्कारों का स्वामी', 'th': 'เจ้าแห่งพันรางวัล'},
    // 7 — supertall
    {'ko': '영원한 사냥꾼', 'en': 'Eternal Hunter', 'ja': '永遠の狩人', 'zh': '永恒猎人', 'fr': 'Chasseur Éternel', 'de': 'Ewiger Jäger', 'es': 'Cazador Eterno', 'pt': 'Caçador Eterno', 'ru': 'Вечный Охотник', 'tr': 'Ebedî Avcı', 'ar': 'الصياد الأبدي', 'it': 'Cacciatore Eterno', 'hi': 'शाश्वत शिकारी', 'th': 'นักล่านิรันดร์'},
    // 8 — megatower
    {'ko': '세계를 연결하는 자', 'en': 'World Connector', 'ja': '世界を繋ぐ者', 'zh': '连结世界之人', 'fr': 'Connecteur du Monde', 'de': 'Weltverbinder', 'es': 'Conector del Mundo', 'pt': 'Conector do Mundo', 'ru': 'Связующий Миры', 'tr': 'Dünyaları Birleştiren', 'ar': 'رابط العوالم', 'it': 'Connettore del Mondo', 'hi': 'विश्व को जोड़ने वाला', 'th': 'ผู้เชื่อมโลก'},
    // 9 — landmark
    {'ko': '전설의 카운터', 'en': 'Legendary Counter', 'ja': '伝説のカウンター', 'zh': '传奇计数器', 'fr': 'Counter Légendaire', 'de': 'Legendärer Counter', 'es': 'Counter Legendario', 'pt': 'Counter Lendário', 'ru': 'Легендарный Counter', 'tr': 'Efsanevi Counter', 'ar': 'Counter الأسطوري', 'it': 'Counter Leggendario', 'hi': 'पौराणिक Counter', 'th': 'Counter ตำนาน'},
  ];
}

enum TowerTier {
  shack,
  cottage,
  house,
  townhouse,
  building,
  office,
  skyscraper,
  supertall,
  megatower,
  landmark,
}

// ── Helper ────────────────────────────────────────────────────────────────
String _t14(Map<String, String> m, String lc) => m[lc] ?? m['en'] ?? '';

extension TowerTierExt on TowerTier {
  int get tierNumber => TowerTier.values.indexOf(this) + 1;

  // ── Tier label (14 languages) ──────────────────────────────────────────
  static const _labels = <TowerTier, Map<String, String>>{
    TowerTier.shack: {'ko': '오두막', 'en': 'Cottage', 'ja': 'コテージ', 'zh': '小屋', 'fr': 'Cabane', 'de': 'Hütte', 'es': 'Cabaña', 'pt': 'Cabana', 'ru': 'Хижина', 'tr': 'Kulübe', 'ar': 'كوخ', 'it': 'Capanna', 'hi': 'कुटीर', 'th': 'กระท่อม'},
    TowerTier.cottage: {'ko': '농가주택', 'en': 'Farmhouse', 'ja': '農家', 'zh': '农舍', 'fr': 'Ferme', 'de': 'Bauernhaus', 'es': 'Granja', 'pt': 'Casa de Campo', 'ru': 'Фермерский дом', 'tr': 'Çiftlik Evi', 'ar': 'منزل ريفي', 'it': 'Cascina', 'hi': 'खेत का घर', 'th': 'บ้านไร่'},
    TowerTier.house: {'ko': '마을집', 'en': 'Village House', 'ja': '村の家', 'zh': '村屋', 'fr': 'Maison de Village', 'de': 'Dorfhaus', 'es': 'Casa del Pueblo', 'pt': 'Casa da Vila', 'ru': 'Деревенский дом', 'tr': 'Köy Evi', 'ar': 'منزل القرية', 'it': 'Casa di Villaggio', 'hi': 'गाँव का घर', 'th': 'บ้านหมู่บ้าน'},
    TowerTier.townhouse: {'ko': '타운하우스', 'en': 'Townhouse', 'ja': 'タウンハウス', 'zh': '联排别墅', 'fr': 'Maison de Ville', 'de': 'Stadthaus', 'es': 'Casa Adosada', 'pt': 'Sobrado', 'ru': 'Таунхаус', 'tr': 'Şehir Evi', 'ar': 'منزل مدني', 'it': 'Casa a Schiera', 'hi': 'टाउनहाउस', 'th': 'ทาวน์เฮาส์'},
    TowerTier.building: {'ko': '빌딩', 'en': 'Building', 'ja': 'ビル', 'zh': '大楼', 'fr': 'Immeuble', 'de': 'Gebäude', 'es': 'Edificio', 'pt': 'Edifício', 'ru': 'Здание', 'tr': 'Bina', 'ar': 'مبنى', 'it': 'Palazzo', 'hi': 'भवन', 'th': 'ตึก'},
    TowerTier.office: {'ko': '오피스타워', 'en': 'Office Tower', 'ja': 'オフィスタワー', 'zh': '办公楼', 'fr': 'Tour de Bureaux', 'de': 'Büroturm', 'es': 'Torre de Oficinas', 'pt': 'Torre Comercial', 'ru': 'Офисная башня', 'tr': 'Ofis Kulesi', 'ar': 'برج مكاتب', 'it': 'Torre Uffici', 'hi': 'ऑफिस टावर', 'th': 'ออฟฟิศทาวเวอร์'},
    TowerTier.skyscraper: {'ko': '마천루', 'en': 'Skyscraper', 'ja': '超高層ビル', 'zh': '摩天楼', 'fr': 'Gratte-ciel', 'de': 'Wolkenkratzer', 'es': 'Rascacielos', 'pt': 'Arranha-céu', 'ru': 'Небоскрёб', 'tr': 'Gökdelen', 'ar': 'ناطحة سحاب', 'it': 'Grattacielo', 'hi': 'गगनचुंबी', 'th': 'ตึกระฟ้า'},
    TowerTier.supertall: {'ko': '초고층빌딩', 'en': 'Supertall', 'ja': 'スーパートール', 'zh': '超高层', 'fr': 'Supertour', 'de': 'Superturm', 'es': 'Supertorre', 'pt': 'Supertorre', 'ru': 'Сверхвысотка', 'tr': 'Süper Yüksek', 'ar': 'برج فائق', 'it': 'Supergrattacielo', 'hi': 'सुपरटॉल', 'th': 'ซูเปอร์ทาวเวอร์'},
    TowerTier.megatower: {'ko': '메가타워', 'en': 'Megatower', 'ja': 'メガタワー', 'zh': '巨塔', 'fr': 'Mégatour', 'de': 'Megaturm', 'es': 'Megatorre', 'pt': 'Megatorre', 'ru': 'Мегабашня', 'tr': 'Mega Kule', 'ar': 'برج عملاق', 'it': 'Megatorre', 'hi': 'मेगाटावर', 'th': 'เมกะทาวเวอร์'},
    TowerTier.landmark: {'ko': '랜드마크', 'en': 'Landmark', 'ja': 'ランドマーク', 'zh': '地标', 'fr': 'Monument', 'de': 'Wahrzeichen', 'es': 'Monumento', 'pt': 'Marco', 'ru': 'Достопримечательность', 'tr': 'Simge Yapı', 'ar': 'معلم', 'it': 'Monumento', 'hi': 'लैंडमार्क', 'th': 'แลนด์มาร์ก'},
  };

  String labelL(String langCode) => _t14(_labels[this]!, langCode);

  /// Backward-compat — defaults to Korean
  String get label => labelL('ko');

  // ── Emoji (unchanged) ──────────────────────────────────────────────────
  String get emoji {
    switch (this) {
      case TowerTier.shack:
        return '🛖';
      case TowerTier.cottage:
        return '🏠';
      case TowerTier.house:
        return '🏡';
      case TowerTier.townhouse:
        return '🏘️';
      case TowerTier.building:
        return '🏢';
      case TowerTier.office:
        return '🏣';
      case TowerTier.skyscraper:
        return '🏙️';
      case TowerTier.supertall:
        return '🌆';
      case TowerTier.megatower:
        return '🌇';
      case TowerTier.landmark:
        return '🗼';
    }
  }

  // ── Next-goal descriptions (14 languages) ──────────────────────────────
  static const _nextGoals = <TowerTier, Map<String, String>>{
    TowerTier.shack: {
      'ko': '혜택 3개 받으면 농가주택으로!',
      'en': 'Receive 3 letters to become a Farmhouse!',
      'ja': '手紙を3通受け取ると農家に！',
      'zh': '收到3封信即可升级为农舍！',
      'fr': 'Recevez 3 lettres pour devenir une Ferme !',
      'de': '3 Briefe erhalten — dann Bauernhaus!',
      'es': '¡Recibe 3 cartas para ser Granja!',
      'pt': 'Receba 3 cartas para virar Casa de Campo!',
      'ru': 'Получите 3 письма — станете Фермерским домом!',
      'tr': '3 mektup alırsan Çiftlik Evi olursun!',
      'ar': 'استلم 3 رسائل لتصبح منزلاً ريفياً!',
      'it': 'Ricevi 3 lettere per diventare Cascina!',
      'hi': '3 पत्र प्राप्त करें और खेत का घर बनें!',
      'th': 'รับจดหมาย 3 ฉบับเพื่อเป็นบ้านไร่!',
    },
    TowerTier.cottage: {
      'ko': '활동 점수 15점이면 마을집으로!',
      'en': 'Reach 15 activity points for Village House!',
      'ja': '活動ポイント15で村の家に！',
      'zh': '活动积分达到15即可升级为村屋！',
      'fr': '15 points d\'activité pour Maison de Village !',
      'de': '15 Aktivitätspunkte — dann Dorfhaus!',
      'es': '¡15 puntos de actividad para Casa del Pueblo!',
      'pt': '15 pontos de atividade para Casa da Vila!',
      'ru': '15 очков активности — Деревенский дом!',
      'tr': '15 aktivite puanıyla Köy Evi!',
      'ar': '15 نقطة نشاط لتصبح منزل القرية!',
      'it': '15 punti attività per Casa di Villaggio!',
      'hi': '15 गतिविधि अंकों पर गाँव का घर!',
      'th': 'ถึง 15 คะแนนกิจกรรมเพื่อเป็นบ้านหมู่บ้าน!',
    },
    TowerTier.house: {
      'ko': '답장 5개 보내면 타운하우스로!',
      'en': 'Send 5 replies to become a Townhouse!',
      'ja': '返信5通でタウンハウスに！',
      'zh': '回复5封信即可升级为联排别墅！',
      'fr': 'Envoyez 5 réponses pour Maison de Ville !',
      'de': '5 Antworten senden — dann Stadthaus!',
      'es': '¡Envía 5 respuestas para Casa Adosada!',
      'pt': 'Envie 5 respostas para virar Sobrado!',
      'ru': 'Отправьте 5 ответов — станете Таунхаусом!',
      'tr': '5 yanıt gönderirsen Şehir Evi olursun!',
      'ar': 'أرسل 5 ردود لتصبح منزلاً مدنياً!',
      'it': 'Invia 5 risposte per diventare Casa a Schiera!',
      'hi': '5 उत्तर भेजें और टाउनहाउस बनें!',
      'th': 'ส่งตอบกลับ 5 ฉบับเพื่อเป็นทาวน์เฮาส์!',
    },
    TowerTier.townhouse: {
      'ko': '활동 점수 50점이면 빌딩으로!',
      'en': 'Reach 50 activity points for Building!',
      'ja': '活動ポイント50でビルに！',
      'zh': '活动积分达到50即可升级为大楼！',
      'fr': '50 points d\'activité pour Immeuble !',
      'de': '50 Aktivitätspunkte — dann Gebäude!',
      'es': '¡50 puntos de actividad para Edificio!',
      'pt': '50 pontos de atividade para Edifício!',
      'ru': '50 очков активности — Здание!',
      'tr': '50 aktivite puanıyla Bina!',
      'ar': '50 نقطة نشاط لتصبح مبنى!',
      'it': '50 punti attività per Palazzo!',
      'hi': '50 गतिविधि अंकों पर भवन!',
      'th': 'ถึง 50 คะแนนกิจกรรมเพื่อเป็นตึก!',
    },
    TowerTier.building: {
      'ko': '활동 점수 80점이면 오피스타워로!',
      'en': 'Reach 80 activity points for Office Tower!',
      'ja': '活動ポイント80でオフィスタワーに！',
      'zh': '活动积分达到80即可升级为办公楼！',
      'fr': '80 points d\'activité pour Tour de Bureaux !',
      'de': '80 Aktivitätspunkte — dann Büroturm!',
      'es': '¡80 puntos de actividad para Torre de Oficinas!',
      'pt': '80 pontos de atividade para Torre Comercial!',
      'ru': '80 очков активности — Офисная башня!',
      'tr': '80 aktivite puanıyla Ofis Kulesi!',
      'ar': '80 نقطة نشاط لتصبح برج مكاتب!',
      'it': '80 punti attività per Torre Uffici!',
      'hi': '80 गतिविधि अंकों पर ऑफिस टावर!',
      'th': 'ถึง 80 คะแนนกิจกรรมเพื่อเป็นออฟฟิศทาวเวอร์!',
    },
    TowerTier.office: {
      'ko': '활동 점수 120점이면 마천루로!',
      'en': 'Reach 120 activity points for Skyscraper!',
      'ja': '活動ポイント120で超高層ビルに！',
      'zh': '活动积分达到120即可升级为摩天楼！',
      'fr': '120 points d\'activité pour Gratte-ciel !',
      'de': '120 Aktivitätspunkte — dann Wolkenkratzer!',
      'es': '¡120 puntos de actividad para Rascacielos!',
      'pt': '120 pontos de atividade para Arranha-céu!',
      'ru': '120 очков активности — Небоскрёб!',
      'tr': '120 aktivite puanıyla Gökdelen!',
      'ar': '120 نقطة نشاط لتصبح ناطحة سحاب!',
      'it': '120 punti attività per Grattacielo!',
      'hi': '120 गतिविधि अंकों पर गगनचुंबी!',
      'th': 'ถึง 120 คะแนนกิจกรรมเพื่อเป็นตึกระฟ้า!',
    },
    TowerTier.skyscraper: {
      'ko': '활동 점수 170점이면 초고층빌딩으로!',
      'en': 'Reach 170 activity points for Supertall!',
      'ja': '活動ポイント170でスーパートールに！',
      'zh': '活动积分达到170即可升级为超高层！',
      'fr': '170 points d\'activité pour Supertour !',
      'de': '170 Aktivitätspunkte — dann Superturm!',
      'es': '¡170 puntos de actividad para Supertorre!',
      'pt': '170 pontos de atividade para Supertorre!',
      'ru': '170 очков активности — Сверхвысотка!',
      'tr': '170 aktivite puanıyla Süper Yüksek!',
      'ar': '170 نقطة نشاط لتصبح برجاً فائقاً!',
      'it': '170 punti attività per Supergrattacielo!',
      'hi': '170 गतिविधि अंकों पर सुपरटॉल!',
      'th': 'ถึง 170 คะแนนกิจกรรมเพื่อเป็นซูเปอร์ทาวเวอร์!',
    },
    TowerTier.supertall: {
      'ko': '활동 점수 250점이면 메가타워로!',
      'en': 'Reach 250 activity points for Megatower!',
      'ja': '活動ポイント250でメガタワーに！',
      'zh': '活动积分达到250即可升级为巨塔！',
      'fr': '250 points d\'activité pour Mégatour !',
      'de': '250 Aktivitätspunkte — dann Megaturm!',
      'es': '¡250 puntos de actividad para Megatorre!',
      'pt': '250 pontos de atividade para Megatorre!',
      'ru': '250 очков активности — Мегабашня!',
      'tr': '250 aktivite puanıyla Mega Kule!',
      'ar': '250 نقطة نشاط لتصبح برجاً عملاقاً!',
      'it': '250 punti attività per Megatorre!',
      'hi': '250 गतिविधि अंकों पर मेगाटावर!',
      'th': 'ถึง 250 คะแนนกิจกรรมเพื่อเป็นเมกะทาวเวอร์!',
    },
    TowerTier.megatower: {
      'ko': '활동 점수 330점이면 랜드마크로!',
      'en': 'Reach 330 activity points for Landmark!',
      'ja': '活動ポイント330でランドマークに！',
      'zh': '活动积分达到330即可升级为地标！',
      'fr': '330 points d\'activité pour Monument !',
      'de': '330 Aktivitätspunkte — dann Wahrzeichen!',
      'es': '¡330 puntos de actividad para Monumento!',
      'pt': '330 pontos de atividade para Marco!',
      'ru': '330 очков активности — Достопримечательность!',
      'tr': '330 aktivite puanıyla Simge Yapı!',
      'ar': '330 نقطة نشاط لتصبح معلماً!',
      'it': '330 punti attività per Monumento!',
      'hi': '330 गतिविधि अंकों पर लैंडमार्क!',
      'th': 'ถึง 330 คะแนนกิจกรรมเพื่อเป็นแลนด์มาร์ก!',
    },
    TowerTier.landmark: {
      'ko': '최고 등급 달성! 🎉',
      'en': 'Top tier reached! 🎉',
      'ja': '最高ランク達成！ 🎉',
      'zh': '最高等级已达成！ 🎉',
      'fr': 'Niveau max atteint ! 🎉',
      'de': 'Höchste Stufe erreicht! 🎉',
      'es': '¡Nivel máximo alcanzado! 🎉',
      'pt': 'Nível máximo atingido! 🎉',
      'ru': 'Высший уровень достигнут! 🎉',
      'tr': 'En yüksek seviyeye ulaşıldı! 🎉',
      'ar': 'تم بلوغ أعلى مستوى! 🎉',
      'it': 'Livello massimo raggiunto! 🎉',
      'hi': 'शीर्ष स्तर प्राप्त! 🎉',
      'th': 'ถึงระดับสูงสุดแล้ว! 🎉',
    },
  };

  String nextGoalL(String langCode) => _t14(_nextGoals[this]!, langCode);

  /// Backward-compat — defaults to Korean
  String get nextGoal => nextGoalL('ko');

  // ── Poetic tower names (14 languages) ──────────────────────────────────
  static const _towerNames = <TowerTier, Map<String, String>>{
    TowerTier.shack: {'ko': '작은 메시지 오두막', 'en': 'Little Message Cottage', 'ja': '小さなメッセージ小屋', 'zh': '小小消息屋', 'fr': 'Petite Cabane à Messages', 'de': 'Kleine Nachrichtenhütte', 'es': 'Pequeña Cabaña de Mensajes', 'pt': 'Pequena Cabana de Mensagens', 'ru': 'Маленькая Хижина Сообщений', 'tr': 'Küçük Mesaj Kulübesi', 'ar': 'كوخ الرسائل الصغير', 'it': 'Piccola Capanna di Messaggi', 'hi': 'छोटी संदेश कुटीर', 'th': 'กระท่อมข้อความเล็กๆ'},
    TowerTier.cottage: {'ko': '들판의 이야기집', 'en': 'Field Story House', 'ja': '野の物語の家', 'zh': '田野故事屋', 'fr': 'Maison des Histoires des Champs', 'de': 'Feld-Geschichtenhaus', 'es': 'Casa de Historias del Campo', 'pt': 'Casa de Histórias do Campo', 'ru': 'Полевой Дом Историй', 'tr': 'Tarla Hikâye Evi', 'ar': 'بيت قصص الحقول', 'it': 'Casa delle Storie di Campo', 'hi': 'खेत की कहानी घर', 'th': 'บ้านเรื่องเล่าทุ่งนา'},
    TowerTier.house: {'ko': '마을 메시지 발신소', 'en': 'Village Message Post', 'ja': '村のメッセージ場', 'zh': '村庄消息站', 'fr': 'Poste aux Messages du Village', 'de': 'Dorf-Nachrichtenstelle', 'es': 'Correo del Pueblo', 'pt': 'Posto de Mensagens da Vila', 'ru': 'Деревенская Почта', 'tr': 'Köy Mesaj Durağı', 'ar': 'مكتب بريد القرية', 'it': 'Posta del Villaggio', 'hi': 'गाँव डाक चौकी', 'th': 'ไปรษณีย์หมู่บ้าน'},
    TowerTier.townhouse: {'ko': '골목 서재', 'en': 'Alley Library', 'ja': '路地裏の書斎', 'zh': '小巷书房', 'fr': 'Bibliothèque de Ruelle', 'de': 'Gassen-Bibliothek', 'es': 'Biblioteca del Callejón', 'pt': 'Biblioteca do Beco', 'ru': 'Переулочная Библиотека', 'tr': 'Sokak Kütüphanesi', 'ar': 'مكتبة الزقاق', 'it': 'Biblioteca del Vicolo', 'hi': 'गली का पुस्तकालय', 'th': 'ห้องสมุดตรอก'},
    TowerTier.building: {'ko': '도시 메신저탑', 'en': 'City Messenger Tower', 'ja': '都市のメッセンジャー塔', 'zh': '城市信使塔', 'fr': 'Tour du Messager Urbain', 'de': 'Stadt-Botenturm', 'es': 'Torre del Mensajero Urbano', 'pt': 'Torre do Mensageiro Urbano', 'ru': 'Городская Башня Вестников', 'tr': 'Şehir Haberci Kulesi', 'ar': 'برج رسل المدينة', 'it': 'Torre del Messaggero Urbano', 'hi': 'शहर संदेशवाहक मीनार', 'th': 'หอผู้ส่งสารเมือง'},
    TowerTier.office: {'ko': '구름 메시지국', 'en': 'Cloud Post Office', 'ja': '雲の郵便局', 'zh': '云端邮局', 'fr': 'Bureau de Poste des Nuages', 'de': 'Wolken-Postamt', 'es': 'Oficina Postal de las Nubes', 'pt': 'Correio das Nuvens', 'ru': 'Облачная Почта', 'tr': 'Bulut Postanesi', 'ar': 'مكتب بريد السحاب', 'it': 'Ufficio Postale delle Nuvole', 'hi': 'बादल डाक घर', 'th': 'ไปรษณีย์เมฆ'},
    TowerTier.skyscraper: {'ko': '하늘 기록탑', 'en': 'Sky Chronicle Tower', 'ja': '天空記録塔', 'zh': '天空记录塔', 'fr': 'Tour des Chroniques du Ciel', 'de': 'Himmels-Chronikturm', 'es': 'Torre Crónica del Cielo', 'pt': 'Torre Crônica do Céu', 'ru': 'Башня Небесных Хроник', 'tr': 'Gökyüzü Kronik Kulesi', 'ar': 'برج سجلات السماء', 'it': 'Torre Cronache del Cielo', 'hi': 'आकाश इतिवृत्त मीनार', 'th': 'หอบันทึกท้องฟ้า'},
    TowerTier.supertall: {'ko': '천공의 탑', 'en': 'Celestial Spire', 'ja': '天空の塔', 'zh': '天穹之塔', 'fr': 'Flèche Céleste', 'de': 'Himmelsspitze', 'es': 'Aguja Celestial', 'pt': 'Pináculo Celestial', 'ru': 'Небесный Шпиль', 'tr': 'Gök Sivri Kulesi', 'ar': 'برج السماء', 'it': 'Guglia Celeste', 'hi': 'खगोलीय शिखर', 'th': 'ยอดสวรรค์'},
    TowerTier.megatower: {'ko': '세계의 정점', 'en': 'Apex of the World', 'ja': '世界の頂点', 'zh': '世界之巅', 'fr': 'Sommet du Monde', 'de': 'Gipfel der Welt', 'es': 'Cima del Mundo', 'pt': 'Ápice do Mundo', 'ru': 'Вершина Мира', 'tr': 'Dünyanın Zirvesi', 'ar': 'قمة العالم', 'it': 'Apice del Mondo', 'hi': 'विश्व का शिखर', 'th': 'จุดสูงสุดของโลก'},
    TowerTier.landmark: {'ko': '전설의 필경원', 'en': 'Legendary Scriptorium', 'ja': '伝説の写本室', 'zh': '传奇抄写院', 'fr': 'Scriptorium Légendaire', 'de': 'Legendäres Skriptorium', 'es': 'Escritorio Legendario', 'pt': 'Escritório Lendário', 'ru': 'Легендарный Скрипторий', 'tr': 'Efsanevi Yazıhane', 'ar': 'دار النسخ الأسطوري', 'it': 'Scriptorium Leggendario', 'hi': 'पौराणिक लेखालय', 'th': 'สำนักเขียนตำนาน'},
  };

  String towerNameL(String langCode) => _t14(_towerNames[this]!, langCode);

  /// Backward-compat — defaults to Korean
  String get towerName => towerNameL('ko');
}

class UserProfile {
  final String id;
  String username;
  String? profileImagePath;
  String country;
  String countryFlag;
  bool isPremium;
  String? email;
  String? socialLink;
  String languageCode; // e.g. 'ko', 'en', 'ja'
  final ActivityScore activityScore;
  final DateTime joinedAt;
  double latitude;
  double longitude;
  List<String> followingIds; // IDs of users I follow
  List<String> followerIds; // IDs of users who follow me
  bool isUsernamePublic; // 닉네임 공개 여부
  bool isSnsPublic; // SNS 링크 공개 여부
  // Build 265: 지도 노출은 닉네임 공개와 별도 필드.
  // 이전엔 isUsernamePublic 한 토글이 두 가지를 동시에 통제 → "닉네임은
  // 공개하되 위치는 비공개" 가 불가능했음. null 이면 username 토글을 따름
  // (legacy migration). 사용자가 별도 토글하면 명시값.
  bool? isMapPublic;
  // ── 프리미엄/유료 전용 필드 ──────────────────────────────────────────────
  bool isBrand; // 브랜드/크리에이터 인증 계정
  String? brandName; // 브랜드 표시명
  String towerColor; // 타워 글로우 색상 (hex, 기본 금색)
  String? towerAccentEmoji; // 타워 장식 이모지
  String? customTowerName; // 사용자 지정 타워 이름
  int towerRoofStyle; // 지붕 스타일 (0=기본, 1=뾰족, 2=돔, 3=평지붕, 4=안테나)
  int towerWindowStyle; // 창문 스타일 (0=사각, 1=원형, 2=아치, 3=모던)
  String? phoneNumber; // 핸드폰 번호 (선택)
  String verifyMethod; // 인증 수단 ('email' or 'phone')

  // ── Brand 인증 필드 (Build 127) ─────────────────────────────────────────
  // Brand 계정이 "정식 등록 사업자" 임을 증명하기 위한 3종 세트. 인증 완료된
  // Brand 는 지도 아바타 플래그 앞에 ✅ 인증 마크 노출.
  // - businessRegistrationNumber: 사업자 등록번호 (예: "123-45-67890")
  // - businessRegistrationDocUrl: 사업자 등록증 스캔/사진 URL
  // - businessContactPhone: 담당자 연락처
  // - brandVerifiedAt: 관리자 승인 완료 시점 (null = 미인증)
  // 관리자 승인 플로우는 후속 스코프 — 현재 클라이언트는 입력·저장·상태 표시만.
  String? businessRegistrationNumber;
  String? businessRegistrationDocUrl;
  String? businessContactPhone;
  DateTime? brandVerifiedAt;

  // ── 카테고리 선호 (Build 218) ───────────────────────────────────────────
  // Premium Level 11 이상 유저가 "받고 싶은 편지 카테고리"를 지정할 수 있다.
  // null = 미설정(랜덤). LetterCategory 의 키 문자열로 직렬화.
  // 설정되어 있으면 매칭 카테고리 편지가 nearbyLetters · 데모 시드 · AI 발송에서
  // 우선순위 가중치를 받는다. 강제 필터가 아니라 확률 부스트.
  String? preferredCategoryKey;

  UserProfile({
    required this.id,
    required this.username,
    this.profileImagePath,
    required this.country,
    required this.countryFlag,
    this.isPremium = false,
    this.email,
    this.socialLink,
    this.languageCode = 'ko',
    ActivityScore? activityScore,
    DateTime? joinedAt,
    this.latitude = 37.5665,
    this.longitude = 126.9780,
    List<String>? followingIds,
    List<String>? followerIds,
    this.isUsernamePublic = true,
    this.isSnsPublic = true,
    this.isMapPublic,
    this.isBrand = false,
    this.brandName,
    this.towerColor = '#FFD700',
    this.towerAccentEmoji,
    this.customTowerName,
    this.towerRoofStyle = 0,
    this.towerWindowStyle = 0,
    this.phoneNumber,
    this.verifyMethod = 'email',
    this.businessRegistrationNumber,
    this.businessRegistrationDocUrl,
    this.businessContactPhone,
    this.brandVerifiedAt,
    this.preferredCategoryKey,
  }) : activityScore = activityScore ?? ActivityScore(),
       joinedAt = joinedAt ?? DateTime.now(),
       followingIds = followingIds ?? [],
       followerIds = followerIds ?? [];
}
