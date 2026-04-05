/// Centralized country-name translations.
///
/// Korean names are the internal identifiers (database keys) used throughout
/// the app.  This class provides display-name lookups for 14 languages and
/// reverse lookups from any language back to the Korean key.
class CountryL10n {
  CountryL10n._();

  /// {koreanKey: {langCode: displayName}}
  static const Map<String, Map<String, String>> _map = {
    '대한민국': {
      'ko': '대한민국', 'en': 'South Korea', 'ja': '韓国', 'zh': '韩国',
      'fr': 'Corée du Sud', 'de': 'Südkorea', 'es': 'Corea del Sur',
      'pt': 'Coreia do Sul', 'ru': 'Южная Корея', 'tr': 'Güney Kore',
      'ar': 'كوريا الجنوبية', 'it': 'Corea del Sud', 'hi': 'दक्षिण कोरिया', 'th': 'เกาหลีใต้',
    },
    '일본': {
      'ko': '일본', 'en': 'Japan', 'ja': '日本', 'zh': '日本',
      'fr': 'Japon', 'de': 'Japan', 'es': 'Japón',
      'pt': 'Japão', 'ru': 'Япония', 'tr': 'Japonya',
      'ar': 'اليابان', 'it': 'Giappone', 'hi': 'जापान', 'th': 'ญี่ปุ่น',
    },
    '미국': {
      'ko': '미국', 'en': 'United States', 'ja': 'アメリカ', 'zh': '美国',
      'fr': 'États-Unis', 'de': 'USA', 'es': 'Estados Unidos',
      'pt': 'Estados Unidos', 'ru': 'США', 'tr': 'ABD',
      'ar': 'الولايات المتحدة', 'it': 'Stati Uniti', 'hi': 'अमेरिका', 'th': 'สหรัฐอเมริกา',
    },
    '프랑스': {
      'ko': '프랑스', 'en': 'France', 'ja': 'フランス', 'zh': '法国',
      'fr': 'France', 'de': 'Frankreich', 'es': 'Francia',
      'pt': 'França', 'ru': 'Франция', 'tr': 'Fransa',
      'ar': 'فرنسا', 'it': 'Francia', 'hi': 'फ़्रांस', 'th': 'ฝรั่งเศส',
    },
    '영국': {
      'ko': '영국', 'en': 'United Kingdom', 'ja': 'イギリス', 'zh': '英国',
      'fr': 'Royaume-Uni', 'de': 'Vereinigtes Königreich', 'es': 'Reino Unido',
      'pt': 'Reino Unido', 'ru': 'Великобритания', 'tr': 'Birleşik Krallık',
      'ar': 'المملكة المتحدة', 'it': 'Regno Unito', 'hi': 'यूनाइटेड किंगडम', 'th': 'สหราชอาณาจักร',
    },
    '독일': {
      'ko': '독일', 'en': 'Germany', 'ja': 'ドイツ', 'zh': '德国',
      'fr': 'Allemagne', 'de': 'Deutschland', 'es': 'Alemania',
      'pt': 'Alemanha', 'ru': 'Германия', 'tr': 'Almanya',
      'ar': 'ألمانيا', 'it': 'Germania', 'hi': 'जर्मनी', 'th': 'เยอรมนี',
    },
    '이탈리아': {
      'ko': '이탈리아', 'en': 'Italy', 'ja': 'イタリア', 'zh': '意大利',
      'fr': 'Italie', 'de': 'Italien', 'es': 'Italia',
      'pt': 'Itália', 'ru': 'Италия', 'tr': 'İtalya',
      'ar': 'إيطاليا', 'it': 'Italia', 'hi': 'इटली', 'th': 'อิตาลี',
    },
    '스페인': {
      'ko': '스페인', 'en': 'Spain', 'ja': 'スペイン', 'zh': '西班牙',
      'fr': 'Espagne', 'de': 'Spanien', 'es': 'España',
      'pt': 'Espanha', 'ru': 'Испания', 'tr': 'İspanya',
      'ar': 'إسبانيا', 'it': 'Spagna', 'hi': 'स्पेन', 'th': 'สเปน',
    },
    '브라질': {
      'ko': '브라질', 'en': 'Brazil', 'ja': 'ブラジル', 'zh': '巴西',
      'fr': 'Brésil', 'de': 'Brasilien', 'es': 'Brasil',
      'pt': 'Brasil', 'ru': 'Бразилия', 'tr': 'Brezilya',
      'ar': 'البرازيل', 'it': 'Brasile', 'hi': 'ब्राज़ील', 'th': 'บราซิล',
    },
    '인도': {
      'ko': '인도', 'en': 'India', 'ja': 'インド', 'zh': '印度',
      'fr': 'Inde', 'de': 'Indien', 'es': 'India',
      'pt': 'Índia', 'ru': 'Индия', 'tr': 'Hindistan',
      'ar': 'الهند', 'it': 'India', 'hi': 'भारत', 'th': 'อินเดีย',
    },
    '중국': {
      'ko': '중국', 'en': 'China', 'ja': '中国', 'zh': '中国',
      'fr': 'Chine', 'de': 'China', 'es': 'China',
      'pt': 'China', 'ru': 'Китай', 'tr': 'Çin',
      'ar': 'الصين', 'it': 'Cina', 'hi': 'चीन', 'th': 'จีน',
    },
    '호주': {
      'ko': '호주', 'en': 'Australia', 'ja': 'オーストラリア', 'zh': '澳大利亚',
      'fr': 'Australie', 'de': 'Australien', 'es': 'Australia',
      'pt': 'Austrália', 'ru': 'Австралия', 'tr': 'Avustralya',
      'ar': 'أستراليا', 'it': 'Australia', 'hi': 'ऑस्ट्रेलिया', 'th': 'ออสเตรเลีย',
    },
    '캐나다': {
      'ko': '캐나다', 'en': 'Canada', 'ja': 'カナダ', 'zh': '加拿大',
      'fr': 'Canada', 'de': 'Kanada', 'es': 'Canadá',
      'pt': 'Canadá', 'ru': 'Канада', 'tr': 'Kanada',
      'ar': 'كندا', 'it': 'Canada', 'hi': 'कनाडा', 'th': 'แคนาดา',
    },
    '멕시코': {
      'ko': '멕시코', 'en': 'Mexico', 'ja': 'メキシコ', 'zh': '墨西哥',
      'fr': 'Mexique', 'de': 'Mexiko', 'es': 'México',
      'pt': 'México', 'ru': 'Мексика', 'tr': 'Meksika',
      'ar': 'المكسيك', 'it': 'Messico', 'hi': 'मेक्सिको', 'th': 'เม็กซิโก',
    },
    '아르헨티나': {
      'ko': '아르헨티나', 'en': 'Argentina', 'ja': 'アルゼンチン', 'zh': '阿根廷',
      'fr': 'Argentine', 'de': 'Argentinien', 'es': 'Argentina',
      'pt': 'Argentina', 'ru': 'Аргентина', 'tr': 'Arjantin',
      'ar': 'الأرجنتين', 'it': 'Argentina', 'hi': 'अर्जेंटीना', 'th': 'อาร์เจนตินา',
    },
    '러시아': {
      'ko': '러시아', 'en': 'Russia', 'ja': 'ロシア', 'zh': '俄罗斯',
      'fr': 'Russie', 'de': 'Russland', 'es': 'Rusia',
      'pt': 'Rússia', 'ru': 'Россия', 'tr': 'Rusya',
      'ar': 'روسيا', 'it': 'Russia', 'hi': 'रूस', 'th': 'รัสเซีย',
    },
    '터키': {
      'ko': '터키', 'en': 'Türkiye', 'ja': 'トルコ', 'zh': '土耳其',
      'fr': 'Turquie', 'de': 'Türkei', 'es': 'Turquía',
      'pt': 'Turquia', 'ru': 'Турция', 'tr': 'Türkiye',
      'ar': 'تركيا', 'it': 'Turchia', 'hi': 'तुर्किये', 'th': 'ตุรกี',
    },
    '이집트': {
      'ko': '이집트', 'en': 'Egypt', 'ja': 'エジプト', 'zh': '埃及',
      'fr': 'Égypte', 'de': 'Ägypten', 'es': 'Egipto',
      'pt': 'Egito', 'ru': 'Египет', 'tr': 'Mısır',
      'ar': 'مصر', 'it': 'Egitto', 'hi': 'मिस्र', 'th': 'อียิปต์',
    },
    '남아프리카': {
      'ko': '남아프리카', 'en': 'South Africa', 'ja': '南アフリカ', 'zh': '南非',
      'fr': 'Afrique du Sud', 'de': 'Südafrika', 'es': 'Sudáfrica',
      'pt': 'África do Sul', 'ru': 'Южная Африка', 'tr': 'Güney Afrika',
      'ar': 'جنوب أفريقيا', 'it': 'Sudafrica', 'hi': 'दक्षिण अफ़्रीका', 'th': 'แอฟริกาใต้',
    },
    '태국': {
      'ko': '태국', 'en': 'Thailand', 'ja': 'タイ', 'zh': '泰国',
      'fr': 'Thaïlande', 'de': 'Thailand', 'es': 'Tailandia',
      'pt': 'Tailândia', 'ru': 'Таиланд', 'tr': 'Tayland',
      'ar': 'تايلاند', 'it': 'Thailandia', 'hi': 'थाईलैंड', 'th': 'ประเทศไทย',
    },
    '네덜란드': {
      'ko': '네덜란드', 'en': 'Netherlands', 'ja': 'オランダ', 'zh': '荷兰',
      'fr': 'Pays-Bas', 'de': 'Niederlande', 'es': 'Países Bajos',
      'pt': 'Países Baixos', 'ru': 'Нидерланды', 'tr': 'Hollanda',
      'ar': 'هولندا', 'it': 'Paesi Bassi', 'hi': 'नीदरलैंड', 'th': 'เนเธอร์แลนด์',
    },
    '스웨덴': {
      'ko': '스웨덴', 'en': 'Sweden', 'ja': 'スウェーデン', 'zh': '瑞典',
      'fr': 'Suède', 'de': 'Schweden', 'es': 'Suecia',
      'pt': 'Suécia', 'ru': 'Швеция', 'tr': 'İsveç',
      'ar': 'السويد', 'it': 'Svezia', 'hi': 'स्वीडन', 'th': 'สวีเดน',
    },
    '노르웨이': {
      'ko': '노르웨이', 'en': 'Norway', 'ja': 'ノルウェー', 'zh': '挪威',
      'fr': 'Norvège', 'de': 'Norwegen', 'es': 'Noruega',
      'pt': 'Noruega', 'ru': 'Норвегия', 'tr': 'Norveç',
      'ar': 'النرويج', 'it': 'Norvegia', 'hi': 'नॉर्वे', 'th': 'นอร์เวย์',
    },
    '포르투갈': {
      'ko': '포르투갈', 'en': 'Portugal', 'ja': 'ポルトガル', 'zh': '葡萄牙',
      'fr': 'Portugal', 'de': 'Portugal', 'es': 'Portugal',
      'pt': 'Portugal', 'ru': 'Португалия', 'tr': 'Portekiz',
      'ar': 'البرتغال', 'it': 'Portogallo', 'hi': 'पुर्तगाल', 'th': 'โปรตุเกส',
    },
    '인도네시아': {
      'ko': '인도네시아', 'en': 'Indonesia', 'ja': 'インドネシア', 'zh': '印度尼西亚',
      'fr': 'Indonésie', 'de': 'Indonesien', 'es': 'Indonesia',
      'pt': 'Indonésia', 'ru': 'Индонезия', 'tr': 'Endonezya',
      'ar': 'إندونيسيا', 'it': 'Indonesia', 'hi': 'इंडोनेशिया', 'th': 'อินโดนีเซีย',
    },
    '말레이시아': {
      'ko': '말레이시아', 'en': 'Malaysia', 'ja': 'マレーシア', 'zh': '马来西亚',
      'fr': 'Malaisie', 'de': 'Malaysia', 'es': 'Malasia',
      'pt': 'Malásia', 'ru': 'Малайзия', 'tr': 'Malezya',
      'ar': 'ماليزيا', 'it': 'Malesia', 'hi': 'मलेशिया', 'th': 'มาเลเซีย',
    },
    '싱가포르': {
      'ko': '싱가포르', 'en': 'Singapore', 'ja': 'シンガポール', 'zh': '新加坡',
      'fr': 'Singapour', 'de': 'Singapur', 'es': 'Singapur',
      'pt': 'Singapura', 'ru': 'Сингапур', 'tr': 'Singapur',
      'ar': 'سنغافورة', 'it': 'Singapore', 'hi': 'सिंगापुर', 'th': 'สิงคโปร์',
    },
    '뉴질랜드': {
      'ko': '뉴질랜드', 'en': 'New Zealand', 'ja': 'ニュージーランド', 'zh': '新西兰',
      'fr': 'Nouvelle-Zélande', 'de': 'Neuseeland', 'es': 'Nueva Zelanda',
      'pt': 'Nova Zelândia', 'ru': 'Новая Зеландия', 'tr': 'Yeni Zelanda',
      'ar': 'نيوزيلندا', 'it': 'Nuova Zelanda', 'hi': 'न्यूज़ीलैंड', 'th': 'นิวซีแลนด์',
    },
    '필리핀': {
      'ko': '필리핀', 'en': 'Philippines', 'ja': 'フィリピン', 'zh': '菲律宾',
      'fr': 'Philippines', 'de': 'Philippinen', 'es': 'Filipinas',
      'pt': 'Filipinas', 'ru': 'Филиппины', 'tr': 'Filipinler',
      'ar': 'الفلبين', 'it': 'Filippine', 'hi': 'फ़िलीपींस', 'th': 'ฟิลิปปินส์',
    },
    '베트남': {
      'ko': '베트남', 'en': 'Vietnam', 'ja': 'ベトナム', 'zh': '越南',
      'fr': 'Vietnam', 'de': 'Vietnam', 'es': 'Vietnam',
      'pt': 'Vietnã', 'ru': 'Вьетнам', 'tr': 'Vietnam',
      'ar': 'فيتنام', 'it': 'Vietnam', 'hi': 'वियतनाम', 'th': 'เวียดนาม',
    },
    '우크라이나': {
      'ko': '우크라이나', 'en': 'Ukraine', 'ja': 'ウクライナ', 'zh': '乌克兰',
      'fr': 'Ukraine', 'de': 'Ukraine', 'es': 'Ucrania',
      'pt': 'Ucrânia', 'ru': 'Украина', 'tr': 'Ukrayna',
      'ar': 'أوكرانيا', 'it': 'Ucraina', 'hi': 'यूक्रेन', 'th': 'ยูเครน',
    },
    '폴란드': {
      'ko': '폴란드', 'en': 'Poland', 'ja': 'ポーランド', 'zh': '波兰',
      'fr': 'Pologne', 'de': 'Polen', 'es': 'Polonia',
      'pt': 'Polônia', 'ru': 'Польша', 'tr': 'Polonya',
      'ar': 'بولندا', 'it': 'Polonia', 'hi': 'पोलैंड', 'th': 'โปแลนด์',
    },
    '체코': {
      'ko': '체코', 'en': 'Czechia', 'ja': 'チェコ', 'zh': '捷克',
      'fr': 'Tchéquie', 'de': 'Tschechien', 'es': 'Chequia',
      'pt': 'Tchéquia', 'ru': 'Чехия', 'tr': 'Çekya',
      'ar': 'التشيك', 'it': 'Cechia', 'hi': 'चेकिया', 'th': 'เช็ก',
    },
    '헝가리': {
      'ko': '헝가리', 'en': 'Hungary', 'ja': 'ハンガリー', 'zh': '匈牙利',
      'fr': 'Hongrie', 'de': 'Ungarn', 'es': 'Hungría',
      'pt': 'Hungria', 'ru': 'Венгрия', 'tr': 'Macaristan',
      'ar': 'المجر', 'it': 'Ungheria', 'hi': 'हंगरी', 'th': 'ฮังการี',
    },
    '그리스': {
      'ko': '그리스', 'en': 'Greece', 'ja': 'ギリシャ', 'zh': '希腊',
      'fr': 'Grèce', 'de': 'Griechenland', 'es': 'Grecia',
      'pt': 'Grécia', 'ru': 'Греция', 'tr': 'Yunanistan',
      'ar': 'اليونان', 'it': 'Grecia', 'hi': 'ग्रीस', 'th': 'กรีซ',
    },
    '이스라엘': {
      'ko': '이스라엘', 'en': 'Israel', 'ja': 'イスラエル', 'zh': '以色列',
      'fr': 'Israël', 'de': 'Israel', 'es': 'Israel',
      'pt': 'Israel', 'ru': 'Израиль', 'tr': 'İsrail',
      'ar': 'إسرائيل', 'it': 'Israele', 'hi': 'इज़राइल', 'th': 'อิสราเอล',
    },
    '사우디아라비아': {
      'ko': '사우디아라비아', 'en': 'Saudi Arabia', 'ja': 'サウジアラビア', 'zh': '沙特阿拉伯',
      'fr': 'Arabie saoudite', 'de': 'Saudi-Arabien', 'es': 'Arabia Saudita',
      'pt': 'Arábia Saudita', 'ru': 'Саудовская Аравия', 'tr': 'Suudi Arabistan',
      'ar': 'المملكة العربية السعودية', 'it': 'Arabia Saudita', 'hi': 'सऊदी अरब', 'th': 'ซาอุดีอาระเบีย',
    },
    'UAE': {
      'ko': 'UAE', 'en': 'UAE', 'ja': 'UAE', 'zh': '阿联酋',
      'fr': 'EAU', 'de': 'VAE', 'es': 'EAU',
      'pt': 'EAU', 'ru': 'ОАЭ', 'tr': 'BAE',
      'ar': 'الإمارات', 'it': 'EAU', 'hi': 'संयुक्त अरब अमीरात', 'th': 'สหรัฐอาหรับเอมิเรตส์',
    },
    '파키스탄': {
      'ko': '파키스탄', 'en': 'Pakistan', 'ja': 'パキスタン', 'zh': '巴基斯坦',
      'fr': 'Pakistan', 'de': 'Pakistan', 'es': 'Pakistán',
      'pt': 'Paquistão', 'ru': 'Пакистан', 'tr': 'Pakistan',
      'ar': 'باكستان', 'it': 'Pakistan', 'hi': 'पाकिस्तान', 'th': 'ปากีสถาน',
    },
    '방글라데시': {
      'ko': '방글라데시', 'en': 'Bangladesh', 'ja': 'バングラデシュ', 'zh': '孟加拉国',
      'fr': 'Bangladesh', 'de': 'Bangladesch', 'es': 'Bangladés',
      'pt': 'Bangladesh', 'ru': 'Бангладеш', 'tr': 'Bangladeş',
      'ar': 'بنغلاديش', 'it': 'Bangladesh', 'hi': 'बांग्लादेश', 'th': 'บังกลาเทศ',
    },
    '나이지리아': {
      'ko': '나이지리아', 'en': 'Nigeria', 'ja': 'ナイジェリア', 'zh': '尼日利亚',
      'fr': 'Nigeria', 'de': 'Nigeria', 'es': 'Nigeria',
      'pt': 'Nigéria', 'ru': 'Нигерия', 'tr': 'Nijerya',
      'ar': 'نيجيريا', 'it': 'Nigeria', 'hi': 'नाइजीरिया', 'th': 'ไนจีเรีย',
    },
    '케냐': {
      'ko': '케냐', 'en': 'Kenya', 'ja': 'ケニア', 'zh': '肯尼亚',
      'fr': 'Kenya', 'de': 'Kenia', 'es': 'Kenia',
      'pt': 'Quênia', 'ru': 'Кения', 'tr': 'Kenya',
      'ar': 'كينيا', 'it': 'Kenya', 'hi': 'केन्या', 'th': 'เคนยา',
    },
    '에티오피아': {
      'ko': '에티오피아', 'en': 'Ethiopia', 'ja': 'エチオピア', 'zh': '埃塞俄比亚',
      'fr': 'Éthiopie', 'de': 'Äthiopien', 'es': 'Etiopía',
      'pt': 'Etiópia', 'ru': 'Эфиопия', 'tr': 'Etiyopya',
      'ar': 'إثيوبيا', 'it': 'Etiopia', 'hi': 'इथियोपिया', 'th': 'เอธิโอเปีย',
    },
    '모로코': {
      'ko': '모로코', 'en': 'Morocco', 'ja': 'モロッコ', 'zh': '摩洛哥',
      'fr': 'Maroc', 'de': 'Marokko', 'es': 'Marruecos',
      'pt': 'Marrocos', 'ru': 'Марокко', 'tr': 'Fas',
      'ar': 'المغرب', 'it': 'Marocco', 'hi': 'मोरक्को', 'th': 'โมร็อกโก',
    },
    '콜롬비아': {
      'ko': '콜롬비아', 'en': 'Colombia', 'ja': 'コロンビア', 'zh': '哥伦比亚',
      'fr': 'Colombie', 'de': 'Kolumbien', 'es': 'Colombia',
      'pt': 'Colômbia', 'ru': 'Колумбия', 'tr': 'Kolombiya',
      'ar': 'كولومبيا', 'it': 'Colombia', 'hi': 'कोलम्बिया', 'th': 'โคลอมเบีย',
    },
    '페루': {
      'ko': '페루', 'en': 'Peru', 'ja': 'ペルー', 'zh': '秘鲁',
      'fr': 'Pérou', 'de': 'Peru', 'es': 'Perú',
      'pt': 'Peru', 'ru': 'Перу', 'tr': 'Peru',
      'ar': 'بيرو', 'it': 'Perù', 'hi': 'पेरू', 'th': 'เปรู',
    },
    '칠레': {
      'ko': '칠레', 'en': 'Chile', 'ja': 'チリ', 'zh': '智利',
      'fr': 'Chili', 'de': 'Chile', 'es': 'Chile',
      'pt': 'Chile', 'ru': 'Чили', 'tr': 'Şili',
      'ar': 'تشيلي', 'it': 'Cile', 'hi': 'चिली', 'th': 'ชิลี',
    },
    '덴마크': {
      'ko': '덴마크', 'en': 'Denmark', 'ja': 'デンマーク', 'zh': '丹麦',
      'fr': 'Danemark', 'de': 'Dänemark', 'es': 'Dinamarca',
      'pt': 'Dinamarca', 'ru': 'Дания', 'tr': 'Danimarka',
      'ar': 'الدنمارك', 'it': 'Danimarca', 'hi': 'डेनमार्क', 'th': 'เดนมาร์ก',
    },
    '핀란드': {
      'ko': '핀란드', 'en': 'Finland', 'ja': 'フィンランド', 'zh': '芬兰',
      'fr': 'Finlande', 'de': 'Finnland', 'es': 'Finlandia',
      'pt': 'Finlândia', 'ru': 'Финляндия', 'tr': 'Finlandiya',
      'ar': 'فنلندا', 'it': 'Finlandia', 'hi': 'फ़िनलैंड', 'th': 'ฟินแลนด์',
    },
    '오스트리아': {
      'ko': '오스트리아', 'en': 'Austria', 'ja': 'オーストリア', 'zh': '奥地利',
      'fr': 'Autriche', 'de': 'Österreich', 'es': 'Austria',
      'pt': 'Áustria', 'ru': 'Австрия', 'tr': 'Avusturya',
      'ar': 'النمسا', 'it': 'Austria', 'hi': 'ऑस्ट्रिया', 'th': 'ออสเตรีย',
    },
    '스위스': {
      'ko': '스위스', 'en': 'Switzerland', 'ja': 'スイス', 'zh': '瑞士',
      'fr': 'Suisse', 'de': 'Schweiz', 'es': 'Suiza',
      'pt': 'Suíça', 'ru': 'Швейцария', 'tr': 'İsviçre',
      'ar': 'سويسرا', 'it': 'Svizzera', 'hi': 'स्विट्ज़रलैंड', 'th': 'สวิตเซอร์แลนด์',
    },
    '벨기에': {
      'ko': '벨기에', 'en': 'Belgium', 'ja': 'ベルギー', 'zh': '比利时',
      'fr': 'Belgique', 'de': 'Belgien', 'es': 'Bélgica',
      'pt': 'Bélgica', 'ru': 'Бельгия', 'tr': 'Belçika',
      'ar': 'بلجيكا', 'it': 'Belgio', 'hi': 'बेल्जियम', 'th': 'เบลเยียม',
    },
    '아일랜드': {
      'ko': '아일랜드', 'en': 'Ireland', 'ja': 'アイルランド', 'zh': '爱尔兰',
      'fr': 'Irlande', 'de': 'Irland', 'es': 'Irlanda',
      'pt': 'Irlanda', 'ru': 'Ирландия', 'tr': 'İrlanda',
      'ar': 'أيرلندا', 'it': 'Irlanda', 'hi': 'आयरलैंड', 'th': 'ไอร์แลนด์',
    },
  };

  /// Build a reverse lookup: any display name → Korean key.
  static final Map<String, String> _reverseMap = () {
    final m = <String, String>{};
    for (final entry in _map.entries) {
      for (final name in entry.value.values) {
        m[name.toLowerCase()] = entry.key;
      }
    }
    return m;
  }();

  /// Get the localized display name for a country given its Korean key.
  /// Falls back to English, then the key itself.
  static String localizedName(String koreanKey, String langCode) {
    final translations = _map[koreanKey];
    if (translations == null) return koreanKey;
    return translations[langCode] ?? translations['en'] ?? koreanKey;
  }

  /// Reverse-lookup: given a display name in *any* language, return the Korean
  /// key.  Returns [displayName] unchanged if no match is found.
  static String koreanKey(String displayName) {
    return _reverseMap[displayName.toLowerCase()] ?? displayName;
  }

  /// Returns `true` when the country (identified by its Korean key) matches
  /// [query] in any of the 14 supported languages.  Case-insensitive.
  static bool matchesSearch(String koreanKey, String query) {
    final q = query.toLowerCase();
    final translations = _map[koreanKey];
    if (translations == null) return koreanKey.toLowerCase().contains(q);
    return translations.values.any((v) => v.toLowerCase().contains(q));
  }

  /// Get all supported Korean keys.
  static List<String> get allKeys => _map.keys.toList();
}
