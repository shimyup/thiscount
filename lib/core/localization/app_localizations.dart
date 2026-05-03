class AppL10n {
  final String languageCode;
  const AppL10n(this.languageCode);

  static const AppL10n _ko = AppL10n('ko');
  static const AppL10n _en = AppL10n('en');
  static const AppL10n _ja = AppL10n('ja');
  static const AppL10n _zh = AppL10n('zh');
  static const AppL10n _fr = AppL10n('fr');
  static const AppL10n _de = AppL10n('de');
  static const AppL10n _es = AppL10n('es');
  static const AppL10n _pt = AppL10n('pt');
  static const AppL10n _ru = AppL10n('ru');
  static const AppL10n _tr = AppL10n('tr');
  static const AppL10n _ar = AppL10n('ar');
  static const AppL10n _it = AppL10n('it');
  static const AppL10n _hi = AppL10n('hi');
  static const AppL10n _th = AppL10n('th');

  static AppL10n of(String code) {
    switch (code) {
      case 'ko':
        return _ko;
      case 'ja':
        return _ja;
      case 'zh':
        return _zh;
      case 'fr':
        return _fr;
      case 'de':
        return _de;
      case 'es':
        return _es;
      case 'pt':
        return _pt;
      case 'ru':
        return _ru;
      case 'tr':
        return _tr;
      case 'ar':
        return _ar;
      case 'it':
        return _it;
      case 'hi':
        return _hi;
      case 'th':
        return _th;
      default:
        return _en;
    }
  }

  String _t(Map<String, String> translations) =>
      translations[languageCode] ?? translations['en'] ?? '';

  /// Quick Korean/English toggle for inline UI strings.
  /// Returns [ko] when the current language is Korean, otherwise [en].
  String koEn(String ko, String en) => languageCode == 'ko' ? ko : en;

  // ── App-wide ──────────────────────────────────────────────────────────────
  String get appName => _t({
    'ko': 'Message in a Bottle',
    'en': 'Message in a Bottle',
    'ja': 'メッセージ・イン・ア・ボトル',
    'zh': '漂流瓶信',
    'fr': 'Message dans une bouteille',
    'de': 'Flaschenpost',
    'es': 'Mensaje en una botella',
    'pt': 'Mensagem numa garrafa',
    'ru': 'Письмо в бутылке',
    'tr': 'Şişedeki Mesaj',
    'ar': 'رسالة في زجاجة',
    'it': 'Messaggio in bottiglia',
    'hi': 'बोतल में संदेश',
    'th': 'ข้อความในขวด',
  });

  // Build 114: 스플래시 메인 태그라인 — 마케팅 기획서 Build 113 의 1순위
  // 후보 ("걸으면 쿠폰이 보여요" / "Walk close. Pick it up.") 로 교체.
  // 기존 "세상 어딘가의 당신에게" 는 펜팔 포지셔닝 잔재.
  // Build 172: 감성적 톤으로 리라이트. 실용성 (action verb) 보다 "혜택이 나를
  // 기다리는" 감성 앵커를 우선. "주워 쓰세요" 는 onboarding/CTA 에서 계속 등장.
  // 메인 스플래시에는 한 번 만나는 순간이라 여운 있는 카피.
  String get tagline => _t({
    'ko': '오늘, 혜택이 당신을 기다려요',
    'en': 'A reward is waiting for you today',
    'ja': '今日、手紙があなたを待っています',
    'zh': '今天，有一封信在等你',
    'fr': "Aujourd'hui, une lettre vous attend",
    'de': 'Heute wartet ein Brief auf dich',
    'es': 'Hoy, una carta te espera',
    'pt': 'Hoje, uma carta espera por ti',
    'ru': 'Сегодня вас ждёт письмо',
    'tr': 'Bugün seni bir mektup bekliyor',
    'ar': 'اليوم، رسالة تنتظرك',
    'it': 'Oggi, una lettera ti aspetta',
    'hi': 'आज आपका एक पत्र इंतज़ार कर रहा है',
    'th': 'วันนี้ มีจดหมายรอคุณอยู่',
  });

  // ── Auth ──────────────────────────────────────────────────────────────────
  String get login => _t({
    'ko': '로그인',
    'en': 'Login',
    'ja': 'ログイン',
    'zh': '登录',
    'fr': 'Connexion',
    'de': 'Anmelden',
    'es': 'Iniciar sesión',
    'pt': 'Entrar',
    'ru': 'Войти',
    'tr': 'Giriş yap',
    'ar': 'تسجيل الدخول',
    'it': 'Accedi',
    'hi': 'लॉगिन',
    'th': 'เข้าสู่ระบบ',
  });
  String get signup => _t({
    'ko': '회원가입',
    'en': 'Sign Up',
    'ja': '新規登録',
    'zh': '注册',
    'fr': "S'inscrire",
    'de': 'Registrieren',
    'es': 'Registrarse',
    'pt': 'Cadastrar',
    'ru': 'Зарегистрироваться',
    'tr': 'Üye ol',
    'ar': 'إنشاء حساب',
    'it': 'Registrati',
    'hi': 'साइनअप',
    'th': 'สมัครสมาชิก',
  });
  String get email => _t({
    'ko': '이메일',
    'en': 'Email',
    'ja': 'メール',
    'zh': '邮箱',
    'fr': 'Email',
    'de': 'E-Mail',
    'es': 'Correo',
    'pt': 'Email',
    'ru': 'Email',
    'tr': 'E-posta',
    'ar': 'البريد الإلكتروني',
    'it': 'Email',
    'hi': 'ईमेल',
    'th': 'อีเมล',
  });
  String get password => _t({
    'ko': '비밀번호',
    'en': 'Password',
    'ja': 'パスワード',
    'zh': '密码',
    'fr': 'Mot de passe',
    'de': 'Passwort',
    'es': 'Contraseña',
    'pt': 'Senha',
    'ru': 'Пароль',
    'tr': 'Şifre',
    'ar': 'كلمة المرور',
    'it': 'Password',
    'hi': 'पासवर्ड',
    'th': 'รหัสผ่าน',
  });
  String get username => _t({
    'ko': '사용자 이름',
    'en': 'Username',
    'ja': 'ユーザー名',
    'zh': '用户名',
    'fr': "Nom d'utilisateur",
    'de': 'Benutzername',
    'es': 'Nombre de usuario',
    'pt': 'Nome de usuário',
    'ru': 'Имя пользователя',
    'tr': 'Kullanıcı adı',
    'ar': 'اسم المستخدم',
    'it': 'Nome utente',
    'hi': 'उपयोगकर्ता नाम',
    'th': 'ชื่อผู้ใช้',
  });
  String get selectCountry => _t({
    'ko': '나라 선택',
    'en': 'Select Country',
    'ja': '国を選択',
    'zh': '选择国家',
    'fr': 'Choisir le pays',
    'de': 'Land auswählen',
    'es': 'Seleccionar país',
    'pt': 'Selecionar país',
    'ru': 'Выберите страну',
    'tr': 'Ülke seç',
    'ar': 'اختر الدولة',
    'it': 'Seleziona paese',
    'hi': 'देश चुनें',
    'th': 'เลือกประเทศ',
  });

  // ── Privacy policy ────────────────────────────────────────────────────────
  String get agreePrivacy => _t({
    'ko': '개인정보 처리방침에 동의합니다',
    'en': 'I agree to the Privacy Policy',
    'ja': 'プライバシーポリシーに同意します',
    'zh': '我同意隐私政策',
    'fr': "J'accepte la politique de confidentialité",
    'de': 'Ich stimme der Datenschutzrichtlinie zu',
    'es': 'Acepto la política de privacidad',
    'pt': 'Concordo com a Política de Privacidade',
    'ru': 'Я соглашаюсь с политикой конфиденциальности',
    'tr': 'Gizlilik Politikasını kabul ediyorum',
    'ar': 'أوافق على سياسة الخصوصية',
    'it': "Accetto l'informativa sulla privacy",
    'hi': 'मैं गोपनीयता नीति से सहमत हूं',
    'th': 'ฉันยอมรับนโยบายความเป็นส่วนตัว',
  });

  String get languageNotice => _t({
    'ko': '선택한 나라의 언어로 앱이 표시됩니다',
    'en': 'The app will be displayed in your country\'s language',
    'ja': '選択した国の言語でアプリが表示されます',
    'zh': '应用将以所选国家的语言显示',
    'fr': "L'application sera affichée dans la langue de votre pays",
    'de': 'Die App wird in der Sprache Ihres Landes angezeigt',
    'es': 'La aplicación se mostrará en el idioma de su país',
    'pt': 'O aplicativo será exibido no idioma do seu país',
    'ru': 'Приложение будет отображаться на языке вашей страны',
    'tr': 'Uygulama ülkenizin dilinde görüntülenecek',
    'ar': 'سيتم عرض التطبيق بلغة بلدك',
    'it': "L'app verrà visualizzata nella lingua del tuo paese",
    'hi': 'ऐप आपके देश की भाषा में प्रदर्शित होगा',
    'th': 'แอปจะแสดงในภาษาของประเทศคุณ',
  });

  // ── Map ───────────────────────────────────────────────────────────────────
  String get map => _t({
    'ko': '지도',
    'en': 'Map',
    'ja': '地図',
    'zh': '地图',
    'fr': 'Carte',
    'de': 'Karte',
    'es': 'Mapa',
    'pt': 'Mapa',
    'ru': 'Карта',
    'tr': 'Harita',
    'ar': 'خريطة',
    'it': 'Mappa',
    'hi': 'नक्शा',
    'th': 'แผนที่',
  });
  String get inbox => _t({
    'ko': '수집첩',
    'en': 'Inbox',
    'ja': '受信箱',
    'zh': '收件箱',
    'fr': 'Boîte de réception',
    'de': 'Posteingang',
    'es': 'Bandeja de entrada',
    'pt': 'Caixa de entrada',
    'ru': 'Входящие',
    'tr': 'Gelen kutusu',
    'ar': 'البريد الوارد',
    'it': 'Posta in arrivo',
    'hi': 'इनबॉक्स',
    'th': 'กล่องจดหมาย',
  });
  String get profile => _t({
    'ko': '프로필',
    'en': 'Profile',
    'ja': 'プロフィール',
    'zh': '个人资料',
    'fr': 'Profil',
    'de': 'Profil',
    'es': 'Perfil',
    'pt': 'Perfil',
    'ru': 'Профиль',
    'tr': 'Profil',
    'ar': 'الملف الشخصي',
    'it': 'Profilo',
    'hi': 'प्रोफ़ाइल',
    'th': 'โปรไฟล์',
  });

  // ── 하단 네비 전용 라벨 (보물찾기 컨셉) ─────────────────────────────
  // 기존 `map` / `inbox` 는 다른 컨텍스트(대화상자·에러 메시지 등)에서도
  // 쓰이므로 전역 변경은 부작용이 크다. 네비바에서만 쓸 새 키를 별도로
  // 두어 "지도 → 탐험", "편지함 → 수집첩" 으로 브랜드 톤을 바꾼다.
  String get navExplore => _t({
    'ko': '탐험',
    'en': 'Explore',
    'ja': '探検',
    'zh': '探索',
    'fr': 'Explorer',
    'de': 'Erkunden',
    'es': 'Explorar',
    'pt': 'Explorar',
    'ru': 'Карта',
    'tr': 'Keşfet',
    'ar': 'استكشاف',
    'it': 'Esplora',
    'hi': 'खोजें',
    'th': 'สำรวจ',
  });
  String get navCollection => _t({
    'ko': '수집첩',
    'en': 'Collection',
    'ja': 'コレクション',
    'zh': '收藏簿',
    'fr': 'Collection',
    'de': 'Sammlung',
    'es': 'Colección',
    'pt': 'Coleção',
    'ru': 'Коллекция',
    'tr': 'Koleksiyon',
    'ar': 'المجموعة',
    'it': 'Collezione',
    'hi': 'संग्रह',
    'th': 'สะสม',
  });
  // Build 223: '보내기/Send' → '홍보/Promo' — Premium = 홍보 혜택 정체성과 일치.
  // Free 회원은 _ComposeNavItem.isLocked 로 자물쇠 오버레이.
  String get navSend => _t({
    'ko': '홍보',
    'en': 'Promo',
    'ja': '宣伝',
    'zh': '推广',
    'fr': 'Promo',
    'de': 'Promo',
    'es': 'Promo',
    'pt': 'Promo',
    'ru': 'Промо',
    'tr': 'Promo',
    'ar': 'ترويج',
    'it': 'Promo',
    'hi': 'प्रचार',
    'th': 'โปร',
  });

  // Build 139: Brand 유저 전용 중앙 탭 라벨.
  String get navCampaign => _t({
    'ko': '캠페인',
    'en': 'Campaign',
    'ja': 'キャンペーン',
    'zh': '活动',
    'fr': 'Campagne',
    'de': 'Kampagne',
    'es': 'Campaña',
    'pt': 'Campanha',
    'ru': 'Кампания',
    'tr': 'Kampanya',
    'ar': 'حملة',
    'it': 'Campagna',
    'hi': 'अभियान',
    'th': 'แคมเปญ',
  });

  // Build 139: Free 유저 전용 중앙 탭 라벨 — 업그레이드 CTA.
  String get navUpgradeShort => _t({
    'ko': '업그레이드',
    'en': 'Upgrade',
    'ja': 'アップグレード',
    'zh': '升级',
    'fr': 'Upgrade',
    'de': 'Upgrade',
    'es': 'Mejora',
    'pt': 'Upgrade',
    'ru': 'Апгрейд',
    'tr': 'Yükselt',
    'ar': 'ترقية',
    'it': 'Upgrade',
    'hi': 'अपग्रेड',
    'th': 'อัปเกรด',
  });

  // ── Inbox ─────────────────────────────────────────────────────────────────
  String get received => _t({
    'ko': '받은 혜택',
    'en': 'Received',
    'ja': '受信',
    'zh': '已收到',
    'fr': 'Reçus',
    'de': 'Empfangen',
    'es': 'Recibidos',
    'pt': 'Recebidos',
    'ru': 'Получено',
    'tr': 'Alınanlar',
    'ar': 'المستلمة',
    'it': 'Ricevuti',
    'hi': 'प्राप्त',
    'th': 'ที่ได้รับ',
  });
  String get sent => _t({
    'ko': '보낸 혜택',
    'en': 'Sent',
    'ja': '送信済み',
    'zh': '已发送',
    'fr': 'Envoyés',
    'de': 'Gesendet',
    'es': 'Enviados',
    'pt': 'Enviados',
    'ru': 'Отправлено',
    'tr': 'Gönderilenler',
    'ar': 'المرسلة',
    'it': 'Inviati',
    'hi': 'भेजे गए',
    'th': 'ที่ส่งแล้ว',
  });
  String get translate => _t({
    'ko': '번역하기',
    'en': 'Translate',
    'ja': '翻訳する',
    'zh': '翻译',
    'fr': 'Traduire',
    'de': 'Übersetzen',
    'es': 'Traducir',
    'pt': 'Traduzir',
    'ru': 'Перевести',
    'tr': 'Çevir',
    'ar': 'ترجمة',
    'it': 'Tradurre',
    'hi': 'अनुवाद करें',
    'th': 'แปล',
  });
  String get originalText => _t({
    'ko': '원문 보기',
    'en': 'Original',
    'ja': '原文を見る',
    'zh': '查看原文',
    'fr': 'Texte original',
    'de': 'Originaltext',
    'es': 'Texto original',
    'pt': 'Texto original',
    'ru': 'Оригинал',
    'tr': 'Orijinal metin',
    'ar': 'النص الأصلي',
    'it': 'Testo originale',
    'hi': 'मूल पाठ',
    'th': 'ข้อความต้นฉบับ',
  });

  // ── Chain rule ────────────────────────────────────────────────────────────
  String get chainRuleLocked => _t({
    'ko': '다음 혜택을 읽으려면 혜택을 3개 보내야 합니다',
    'en': 'Send 3 promos to unlock the next one',
    'ja': '次の手紙を読むには3通送ってください',
    'zh': '发送3封信后可阅读下一封',
    'fr': 'Envoyez 3 lettres pour lire la suivante',
    'de': 'Sende 3 Briefe um den nächsten zu lesen',
    'es': 'Envía 3 cartas para leer la siguiente',
    'pt': 'Envie 3 cartas para ler a próxima',
    'ru': 'Отправьте 3 письма чтобы читать следующее',
    'tr': 'Sonrakini okumak için 3 mektup gönder',
    'ar': 'أرسل 3 رسائل لقراءة التالية',
    'it': 'Invia 3 lettere per leggere la prossima',
    'hi': 'अगली पढ़ने के लिए 3 पत्र भेजें',
    'th': 'ส่ง 3 จดหมายเพื่ออ่านฉบับต่อไป',
  });

  // ── Compose ───────────────────────────────────────────────────────────────
  String get writeLetter => _t({
    'ko': '홍보 쓰기',
    'en': 'Write Promo',
    'ja': '手紙を書く',
    'zh': '写信',
    'fr': 'Écrire une lettre',
    'de': 'Brief schreiben',
    'es': 'Escribir carta',
    'pt': 'Escrever carta',
    'ru': 'Написать письмо',
    'tr': 'Mektup yaz',
    'ar': 'كتابة رسالة',
    'it': 'Scrivi lettera',
    'hi': 'पत्र लिखें',
    'th': 'เขียนจดหมาย',
  });
  String get sendLetter => _t({
    'ko': '홍보 보내기',
    'en': 'Send Promo',
    'ja': '手紙を送る',
    'zh': '发送信件',
    'fr': 'Envoyer la lettre',
    'de': 'Brief senden',
    'es': 'Enviar carta',
    'pt': 'Enviar carta',
    'ru': 'Отправить письмо',
    'tr': 'Mektup gönder',
    'ar': 'إرسال الرسالة',
    'it': 'Invia lettera',
    'hi': 'पत्र भेजें',
    'th': 'ส่งจดหมาย',
  });
  String get includeSns => _t({
    'ko': 'SNS 주소 포함하기',
    'en': 'Include SNS link',
    'ja': 'SNSを含める',
    'zh': '包含SNS链接',
    'fr': 'Inclure le lien SNS',
    'de': 'SNS-Link einfügen',
    'es': 'Incluir enlace SNS',
    'pt': 'Incluir link SNS',
    'ru': 'Включить ссылку SNS',
    'tr': 'SNS bağlantısı ekle',
    'ar': 'تضمين رابط SNS',
    'it': 'Includi link SNS',
    'hi': 'SNS लिंक शामिल करें',
    'th': 'รวมลิงก์ SNS',
  });

  // ── Notification ──────────────────────────────────────────────────────────
  String get nearbyNotifTitle => _t({
    'ko': '📬 혜택이 도착했어요!',
    'en': '📬 A reward has arrived!',
    'ja': '📬 手紙が届きました！',
    'zh': '📬 信件已到达！',
    'fr': '📬 Une lettre est arrivée!',
    'de': '📬 Ein Brief ist angekommen!',
    'es': '📬 ¡Ha llegado una carta!',
    'pt': '📬 Uma carta chegou!',
    'ru': '📬 Пришло письмо!',
    'tr': '📬 Bir mektup geldi!',
    'ar': '📬 وصلت رسالة!',
    'it': '📬 È arrivata una lettera!',
    'hi': '📬 एक पत्र आया है!',
    'th': '📬 จดหมายมาถึงแล้ว!',
  });
  String get nearbyNotifBody => _t({
    'ko': '2km 이내에 혜택이 있어요. 앱에서 확인하세요!',
    'en': 'A reward is within 2km. Check it in the app!',
    'ja': '2km以内に手紙があります。アプリで確認してください！',
    'zh': '2公里内有一封信。在应用中查看！',
    'fr': 'Une lettre est à moins de 2km. Vérifiez dans l\'app!',
    'de': 'Ein Brief ist weniger als 2km entfernt. In der App prüfen!',
    'es': 'Hay una carta a menos de 2km. ¡Revísala en la app!',
    'pt': 'Há uma carta a menos de 2km. Verifique no app!',
    'ru': 'Письмо в 2км от вас. Проверьте в приложении!',
    'tr': '2km içinde bir mektup var. Uygulamada kontrol et!',
    'ar': 'توجد رسالة على بعد 2 كم. تحقق من التطبيق!',
    'it': 'C\'è una lettera a meno di 2km. Controlla nell\'app!',
    'hi': '2 किमी के भीतर एक पत्र है। ऐप में चेक करें!',
    'th': 'มีจดหมายอยู่ภายใน 2 กม. ตรวจสอบในแอป!',
  });

  // ── Delivery status ───────────────────────────────────────────────────────
  String get inTransit => _t({
    'ko': '배송 중',
    'en': 'In Transit',
    'ja': '配送中',
    'zh': '运输中',
    'fr': 'En transit',
    'de': 'Unterwegs',
    'es': 'En tránsito',
    'pt': 'Em trânsito',
    'ru': 'В пути',
    'tr': 'Yolda',
    'ar': 'في الطريق',
    'it': 'In transito',
    'hi': 'पारगमन में',
    'th': 'กำลังส่ง',
  });
  String get delivered => _t({
    'ko': '배달 완료',
    'en': 'Delivered',
    'ja': '配達完了',
    'zh': '已投递',
    'fr': 'Livré',
    'de': 'Zugestellt',
    'es': 'Entregado',
    'pt': 'Entregue',
    'ru': 'Доставлено',
    'tr': 'Teslim edildi',
    'ar': 'تم التسليم',
    'it': 'Consegnato',
    'hi': 'डिलीवर हुआ',
    'th': 'จัดส่งแล้ว',
  });
  String get read => _t({
    'ko': '읽음',
    'en': 'Read',
    'ja': '既読',
    'zh': '已读',
    'fr': 'Lu',
    'de': 'Gelesen',
    'es': 'Leído',
    'pt': 'Lido',
    'ru': 'Прочитано',
    'tr': 'Okundu',
    'ar': 'مقروء',
    'it': 'Letto',
    'hi': 'पढ़ा',
    'th': 'อ่านแล้ว',
  });
  String get unread => _t({
    'ko': '미읽음',
    'en': 'Unread',
    'ja': '未読',
    'zh': '未读',
    'fr': 'Non lu',
    'de': 'Ungelesen',
    'es': 'No leído',
    'pt': 'Não lido',
    'ru': 'Непрочитанное',
    'tr': 'Okunmadı',
    'ar': 'غير مقروء',
    'it': 'Non letto',
    'hi': 'अपठित',
    'th': 'ยังไม่ได้อ่าน',
  });

  // ── Onboarding (Build 224 재포지셔닝) ─────────────────────────────────────
  // 1번 슬라이드: Thiscount 정체성 = 위치 기반 할인·홍보 보물찾기
  String get onboarding1Title => _t({
    'ko': '🎟 Thiscount',
    'en': '🎟 Thiscount',
    'ja': '🎟 Thiscount',
    'zh': '🎟 Thiscount',
    'fr': '🎟 Thiscount',
    'de': '🎟 Thiscount',
    'es': '🎟 Thiscount',
    'pt': '🎟 Thiscount',
    'ru': '🎟 Thiscount',
    'tr': '🎟 Thiscount',
    'ar': '🎟 Thiscount',
    'it': '🎟 Thiscount',
    'hi': '🎟 Thiscount',
    'th': '🎟 Thiscount',
  });
  String get onboarding1Body => _t({
    'ko': '내 주변 지도 위에 떠 있는 할인·쿠폰을 주워 바로 사용해요. 브랜드는 혜택으로 홍보하고, 회원은 보물처럼 줍습니다.',
    'en':
        'Pick up discounts and coupons floating on the map around you, redeem instantly. Brands promote via promos; members hunt for treasures.',
    'ja': '近くの地図に浮かぶ割引・クーポンを拾って即使用。ブランドは手紙で宣伝し、会員は宝物のように拾います。',
    'zh': '捡起你身边地图上漂浮的折扣和优惠券，立即使用。品牌用信件推广，会员像寻宝一样捡取。',
    'fr':
        'Ramasse les remises et coupons qui flottent sur la carte autour de toi. Les marques font la promo par lettres; les membres chassent des trésors.',
    'de':
        'Sammle Rabatte und Coupons in deiner Nähe auf der Karte und löse sie sofort ein. Marken werben per Brief, Mitglieder gehen auf Schatzsuche.',
    'es':
        'Recoge descuentos y cupones que flotan en el mapa cerca de ti y úsalos al instante. Las marcas promocionan vía cartas; los miembros cazan tesoros.',
    'pt':
        'Apanha descontos e cupões que flutuam no mapa à tua volta e usa imediatamente. Marcas promovem por cartas; membros caçam tesouros.',
    'ru':
        'Подбирайте скидки и купоны на карте рядом с вами — используйте сразу. Бренды продвигают через письма, участники охотятся за сокровищами.',
    'tr':
        'Etrafındaki haritada yüzen indirim ve kuponları topla, hemen kullan. Markalar mektupla tanıtır, üyeler hazine avlar.',
    'ar':
        'التقط الخصومات والقسائم العائمة على الخريطة من حولك واستخدمها فورًا. الماركات تروّج عبر الرسائل والأعضاء يصطادون الكنوز.',
    'it':
        'Raccogli sconti e coupon che fluttuano sulla mappa intorno a te e usali subito. I brand promuovono via lettere; i membri cercano tesori.',
    'hi':
        'अपने आसपास नक्शे पर तैरते छूट और कूपन उठाएँ और तुरंत इस्तेमाल करें। ब्रांड पत्रों से प्रचार करते हैं; सदस्य खजाने ढूँढते हैं।',
    'th': 'เก็บส่วนลดและคูปองที่ลอยอยู่บนแผนที่รอบตัวและใช้ทันที แบรนด์โปรโมตผ่านจดหมาย สมาชิกล่าสมบัติ',
  });

  String get onboarding2Title => _t({
    'ko': '✈️ 실제 배송 경로',
    'en': '✈️ Real Delivery Routes',
    'ja': '✈️ リアルな配送ルート',
    'zh': '✈️ 真实投递路线',
    'fr': '✈️ Vraies routes de livraison',
    'de': '✈️ Echte Lieferwege',
    'es': '✈️ Rutas de entrega reales',
    'pt': '✈️ Rotas de entrega reais',
    'ru': '✈️ Реальные маршруты доставки',
    'tr': '✈️ Gerçek teslimat güzergahları',
    'ar': '✈️ مسارات التسليم الحقيقية',
    'it': '✈️ Percorsi di consegna reali',
    'hi': '✈️ वास्तविक डिलीवरी रूट',
    'th': '✈️ เส้นทางการส่งจดหมายจริง',
  });
  // Build 119: 배송 경로 페이지를 픽업과 묶어 재작성. "내가 주운 편지"도
  // 지도 위에서 출발지→내 위치로 여행한 여정이 시각화된다는 연결 고리로
  // 헌트 포지셔닝에 정렬. 보낸 혜택만 이동하는 것 아님을 명시.
  String get onboarding2Body => _t({
    'ko': '주운 혜택도, 보낸 홍보도 🚚 → ✈️ → 🚚 순서로 지도 위를 이동해요. 실제 우편 이동 시간이 그대로 반영됩니다.',
    'en':
        'Picked-up rewards and sent promos travel 🚚 → ✈️ → 🚚 across the map, reflecting real postal transit times.',
    'ja': '拾った特典も送った宣伝も🚚→✈️→🚚の順で地図を移動します。実際の配送時間を反映します。',
    'zh': '拾取的特惠和发送的推广都会沿🚚→✈️→🚚路线在地图上移动，反映真实物流时间。',
    'fr':
        'Les récompenses ramassées et les promos envoyées voyagent 🚚→✈️→🚚 sur la carte, selon les délais postaux réels.',
    'de':
        'Aufgesammelte Vorteile und gesendete Promos reisen 🚚→✈️→🚚 auf der Karte — in echter Versandzeit.',
    'es':
        'Recompensas recogidas y promos enviadas viajan 🚚→✈️→🚚 por el mapa, con tiempos postales reales.',
    'pt':
        'Recompensas apanhadas e promos enviadas viajam 🚚→✈️→🚚 no mapa, em tempos postais reais.',
    'ru':
        'Подобранные награды и отправленные промо идут по карте 🚚→✈️→🚚 — в реальных сроках доставки.',
    'tr':
        'Toplanan ödüller ve gönderilen promolar haritada 🚚→✈️→🚚 ilerler — gerçek posta sürelerinde.',
    'ar':
        'المكافآت الملتقطة والترويجات المرسلة تتنقل 🚚→✈️→🚚 على الخريطة بأوقات شحن حقيقية.',
    'it':
        'Ricompense raccolte e promo inviate viaggiano 🚚→✈️→🚚 sulla mappa, in tempi postali reali.',
    'hi':
        'उठाए गए लाभ और भेजे गए प्रचार दोनों नक्शे पर 🚚→✈️→🚚 यात्रा करते हैं — असली डाक समय में।',
    'th': 'ทั้งสิทธิประโยชน์ที่คุณเก็บและโปรที่คุณส่งจะเดินทาง 🚚→✈️→🚚 บนแผนที่ ตามเวลาขนส่งจริง',
  });

  // Build 107 재포지셔닝 — "느린 편지 보물찾기" 보다 "할인·홍보 편지 유통" 강조.
  String get onboarding3Title => _t({
    'ko': '🎟 혜택을 주워 바로 쓰세요',
    'en': '🎟 Pick Up Rewards. Redeem Instantly.',
    'ja': '🎟 特典を拾って、その場で使う',
    'zh': '🎟 拾起特惠，即刻使用',
    'fr': '🎟 Ramasse la récompense. Utilise-la.',
    'de': '🎟 Vorteil aufheben. Sofort einlösen.',
    'es': '🎟 Recoge la recompensa. Úsala al instante.',
    'pt': '🎟 Apanha a recompensa. Usa na hora.',
    'ru': '🎟 Подбери награду. Используй.',
    'tr': '🎟 Ödülü al, hemen kullan.',
    'ar': '🎟 التقط المكافأة. استخدمها فوراً.',
    'it': '🎟 Raccogli la ricompensa. Usa subito.',
    'hi': '🎟 इनाम उठाओ. तुरंत उपयोग करो.',
    'th': '🎟 เก็บสิทธิประโยชน์ ใช้ทันที',
  });
  // Build 170: "편지 형식의 글로벌 공간 쿠폰 플랫폼" 포지셔닝 강조.
  String get onboarding3Body => _t({
    'ko': '브랜드의 할인쿠폰·교환권·홍보 메시지가 세계 곳곳 지도에 떨어집니다. 당신 주변 200m 안의 혜택을 주워 매장에서 바로 쓰세요. 감성과 실용성이 공존하는 글로벌 공간 쿠폰 플랫폼.',
    'en':
        'Brand coupons, vouchers, and promo messages drop on the worldwide map. Pick up rewards within 200m of you and redeem them instantly. A global space-based coupon platform.',
    'ja':
        'ブランドの割引券・引換券・宣伝メッセージが世界中の地図に落ちます。あなたの周り 200m 以内の特典を拾って、お店でその場で使おう。感性と実用性が共存する、グローバル空間クーポンプラットフォーム。',
    'zh':
        '品牌的折扣券、兑换券和推广讯息落在全球地图上。拾取你身边 200 米内的特惠，即刻在门店使用。情感与实用兼具的全球空间优惠券平台。',
    'fr':
        'Coupons, bons et messages promo des marques tombent sur la carte mondiale. Ramasse les récompenses dans un rayon de 200 m et utilise-les en boutique tout de suite. Plateforme mondiale de coupons spatiaux.',
    'de':
        'Marken-Coupons, Gutscheine und Promo-Nachrichten fallen auf die Weltkarte. Hol dir Vorteile im 200-m-Radius und löse sie sofort im Geschäft ein. Globale Coupon-Plattform im Raum.',
    'es':
        'Cupones, vales y mensajes promo de marcas caen en el mapa mundial. Recoge recompensas a 200 m de ti y úsalas al instante. Plataforma global de cupones espaciales.',
    'pt':
        'Cupões, vales e mensagens promo das marcas caem no mapa mundial. Apanha recompensas a 200 m de ti e usa na hora. Plataforma global de cupões espaciais.',
    'ru':
        'Купоны, ваучеры и промо-сообщения брендов падают на мировой карте. Подбирайте награды в радиусе 200 м и используйте сразу. Глобальная платформа пространственных купонов.',
    'tr':
        'Marka kuponları, çekleri ve promo mesajları dünya haritasına düşer. Etrafındaki 200 m içindeki ödülleri topla ve hemen kullan. Küresel mekânsal kupon platformu.',
    'ar':
        'قسائم العلامات التجارية وكوبوناتها ورسائلها الترويجية تسقط على خريطة العالم. التقط المكافآت ضمن 200 م حولك واستخدمها فورًا. منصة عالمية للقسائم المكانية.',
    'it':
        'Coupon, buoni e messaggi promo dei brand cadono sulla mappa mondiale. Raccogli le ricompense entro 200 m e usale subito. Piattaforma globale di coupon spaziali.',
    'hi':
        'ब्रांड कूपन, वाउचर और प्रचार संदेश विश्व मानचित्र पर गिरते हैं. 200 मी के भीतर इनाम उठाएँ और तुरंत उपयोग करें. वैश्विक स्थान-आधारित कूपन प्लेटफ़ॉर्म.',
    'th':
        'คูปอง วาวเชอร์ และข้อความโปรของแบรนด์ตกบนแผนที่โลก เก็บสิทธิประโยชน์ในรัศมี 200 ม. แล้วใช้ทันที แพลตฟอร์มคูปองเชิงพื้นที่ระดับโลก',
  });

  // Build 140 재포지셔닝 — 새 3-티어 정체성에 맞춰 "📸 나만의 편지 뿌리기"
  // 로 전면 개편. Free 는 줍기, Premium 은 홍보, Brand 는 캠페인 이라는
  // 3 단 역할 분리를 이 한 슬라이드에서 요약.
  String get onboarding4Title => _t({
    'ko': '📸 내 홍보를 세계에 뿌리다',
    'en': '📸 Drop Your Own Promos',
    'ja': '📸 自分の宣伝を世界に届ける',
    'zh': '📸 向世界投放自己的推广',
    'fr': '📸 Lance tes promos',
    'de': '📸 Eigene Promos verteilen',
    'es': '📸 Lanza tus propias promos',
    'pt': '📸 Espalha as tuas promos',
    'ru': '📸 Распространяйте свои промо',
    'tr': '📸 Kendi promolarını bırak',
    'ar': '📸 انشر ترويجاتك',
    'it': '📸 Lancia le tue promo',
    'hi': '📸 अपने प्रचार बिखेरें',
    'th': '📸 ส่งโปรของคุณ',
  });
  String get onboarding4Body => _t({
    'ko': 'Premium은 📸 사진과 🔗 채널 링크로 나를 홍보하고, Brand는 🎟 할인권·🎁 교환권 캠페인으로 비즈니스를 알려요. Free는 줍는 데 집중!',
    'en':
        'Premium promotes you with 📸 photos and 🔗 channel links. Brand runs 🎟 coupon & 🎁 voucher campaigns. Free focuses on picking up.',
    'ja':
        'Premium は 📸 写真と 🔗 チャンネルリンクで自己PR。Brand は 🎟 割引券・🎁 交換券キャンペーン。Free は拾うことに集中！',
    'zh': 'Premium 用 📸 照片和 🔗 频道链接自我推广。Brand 开展 🎟 优惠券·🎁 代金券活动。Free 专注拾取！',
    'fr':
        'Premium te met en avant avec 📸 photos et 🔗 liens. Brand lance 🎟 coupons & 🎁 bons. Free se concentre sur le ramassage.',
    'de':
        'Premium präsentiert dich mit 📸 Fotos und 🔗 Kanal-Links. Brand schaltet 🎟 Coupon- & 🎁 Gutschein-Kampagnen. Free sammelt auf.',
    'es':
        'Premium te promociona con 📸 fotos y 🔗 enlaces. Brand lanza campañas 🎟 cupones & 🎁 vales. Free se dedica a recoger.',
    'pt':
        'Premium promove-te com 📸 fotos e 🔗 links. Brand lança campanhas 🎟 cupões & 🎁 vales. Free foca-se em apanhar.',
    'ru':
        'Premium продвигает вас через 📸 фото и 🔗 ссылки на канал. Brand запускает кампании 🎟 купонов и 🎁 ваучеров. Free собирает.',
    'tr':
        "Premium seni 📸 fotoğraf ve 🔗 kanal bağlantılarıyla tanıtır. Brand 🎟 kupon ve 🎁 çeki kampanyaları yayınlar. Free toplamaya odaklanır.",
    'ar':
        'Premium يروج لك بـ 📸 الصور و 🔗 روابط القناة. Brand يطلق حملات 🎟 القسائم و 🎁 الكوبونات. Free يركز على الالتقاط.',
    'it':
        'Premium ti promuove con 📸 foto e 🔗 link. Brand lancia campagne 🎟 coupon & 🎁 buoni. Free si concentra sulla raccolta.',
    'hi':
        'Premium आपको 📸 फ़ोटो और 🔗 चैनल लिंक से प्रमोट करता है. Brand 🎟 कूपन & 🎁 वाउचर अभियान चलाता है. Free उठाने पर केंद्रित.',
    'th':
        'Premium โปรโมตคุณด้วย 📸 รูปและ 🔗 ลิงก์ช่อง. Brand จัดแคมเปญ 🎟 คูปอง·🎁 วาวเชอร์. Free เน้นเก็บ!',
  });

  String get onboarding5Title => _t({
    'ko': '🚀 시작하기',
    'en': '🚀 Get Started',
    'ja': '🚀 始めましょう',
    'zh': '🚀 开始',
    'fr': '🚀 Commencer',
    'de': '🚀 Loslegen',
    'es': '🚀 Comenzar',
    'pt': '🚀 Começar',
    'ru': '🚀 Начать',
    'tr': '🚀 Başla',
    'ar': '🚀 ابدأ',
    'it': '🚀 Inizia',
    'hi': '🚀 शुरू करें',
    'th': '🚀 เริ่มต้น',
  });
  String get onboarding5Body => _t({
    // Build 107 재포지셔닝 — 브랜드 쿠폰/홍보 유통이 메인, 홍보 보내기는
    // 부차적. 네비 소개보다 "지도에서 혜택 줍기" 를 최우선 메시지로.
    'ko': '지도를 열어 근처의 할인·홍보 혜택을 주워보세요. 받은 혜택 안 코드·링크로 바로 혜택을 사용할 수 있어요.',
    'en':
        'Open the map and pick up nearby promos and coupon rewards. Use the code or link inside each reward right away.',
    'ja':
        '地図を開いて近くの割引・プロモ手紙を拾いましょう。中のコードやリンクですぐに特典を使えます。',
    'zh':
        '打开地图拾取附近的优惠促销信件。使用信件中的代码或链接立即享受优惠。',
    'fr':
        'Ouvre la carte et ramasse les lettres promo et coupons à proximité. Utilise le code ou le lien à l\'intérieur immédiatement.',
    'de':
        'Öffne die Karte und sammle Rabatt- und Aktionsbriefe in deiner Nähe. Code oder Link im Brief sofort nutzen.',
    'es':
        'Abre el mapa y recoge cupones y cartas promocionales cercanas. Usa el código o enlace al instante.',
    'pt':
        'Abre o mapa e apanha cartas promocionais e cupões próximos. Usa o código ou link imediatamente.',
    'ru':
        'Откройте карту и подбирайте промо- и купонные письма рядом. Используйте код или ссылку сразу.',
    'tr':
        'Haritayı aç, yakınındaki indirim ve kupon mektuplarını topla. İçindeki kod veya bağlantıyı hemen kullan.',
    'ar':
        'افتح الخريطة والتقط رسائل العروض والقسائم القريبة. استخدم الرمز أو الرابط داخلها فوراً.',
    'it':
        'Apri la mappa e raccogli le lettere promo e coupon vicine. Usa subito il codice o il link contenuto.',
    'hi':
        'मानचित्र खोलें और पास के प्रमोशन और कूपन पत्र उठाएँ. अंदर के कोड या लिंक का तुरंत उपयोग करें.',
    'th':
        'เปิดแผนที่และเก็บจดหมายส่วนลดใกล้ ๆ ใช้รหัสหรือลิงก์ข้างในได้ทันที',
  });

  String get getStarted => _t({
    'ko': '시작하기',
    'en': 'Get Started',
    'ja': '始める',
    'zh': '开始',
    'fr': 'Commencer',
    'de': 'Loslegen',
    'es': 'Comenzar',
    'pt': 'Começar',
    'ru': 'Начать',
    'tr': 'Başla',
    'ar': 'ابدأ',
    'it': 'Inizia',
    'hi': 'शुरू करें',
    'th': 'เริ่มต้น',
  });
  String get skip => _t({
    'ko': '건너뛰기',
    'en': 'Skip',
    'ja': 'スキップ',
    'zh': '跳过',
    'fr': 'Passer',
    'de': 'Überspringen',
    'es': 'Saltar',
    'pt': 'Pular',
    'ru': 'Пропустить',
    'tr': 'Atla',
    'ar': 'تخطي',
    'it': 'Salta',
    'hi': 'छोड़ें',
    'th': 'ข้าม',
  });

  // ── Account ───────────────────────────────────────────────────────────────
  String get deleteAccount => _t({
    'ko': '회원탈퇴',
    'en': 'Delete Account',
    'ja': '退会する',
    'zh': '注销账户',
    'fr': 'Supprimer le compte',
    'de': 'Konto löschen',
    'es': 'Eliminar cuenta',
    'pt': 'Excluir conta',
    'ru': 'Удалить аккаунт',
    'tr': 'Hesabı sil',
    'ar': 'حذف الحساب',
    'it': 'Elimina account',
    'hi': 'खाता हटाएं',
    'th': 'ลบบัญชี',
  });
  String get logout => _t({
    'ko': '로그아웃',
    'en': 'Logout',
    'ja': 'ログアウト',
    'zh': '退出登录',
    'fr': 'Déconnexion',
    'de': 'Abmelden',
    'es': 'Cerrar sesión',
    'pt': 'Sair',
    'ru': 'Выйти',
    'tr': 'Çıkış yap',
    'ar': 'تسجيل الخروج',
    'it': 'Disconnetti',
    'hi': 'लॉगआउट',
    'th': 'ออกจากระบบ',
  });
  String get findId => _t({
    'ko': '아이디 찾기',
    'en': 'Find ID',
    'ja': 'IDを探す',
    'zh': '找账号',
    'fr': 'Trouver l\'ID',
    'de': 'ID finden',
    'es': 'Encontrar ID',
    'pt': 'Encontrar ID',
    'ru': 'Найти ID',
    'tr': 'ID bul',
    'ar': 'إيجاد المعرف',
    'it': 'Trova ID',
    'hi': 'आईडी खोजें',
    'th': 'ค้นหา ID',
  });
  String get resetPassword => _t({
    'ko': '비밀번호 찾기',
    'en': 'Reset Password',
    'ja': 'パスワードを探す',
    'zh': '找密码',
    'fr': 'Réinitialiser le mot de passe',
    'de': 'Passwort zurücksetzen',
    'es': 'Restablecer contraseña',
    'pt': 'Redefinir senha',
    'ru': 'Сбросить пароль',
    'tr': 'Şifreyi sıfırla',
    'ar': 'إعادة تعيين كلمة المرور',
    'it': 'Reimposta password',
    'hi': 'पासवर्ड रीसेट करें',
    'th': 'รีเซ็ตรหัสผ่าน',
  });
  String get next => _t({
    'ko': '다음',
    'en': 'Next',
    'ja': '次へ',
    'zh': '下一步',
    'fr': 'Suivant',
    'de': 'Weiter',
    'es': 'Siguiente',
    'pt': 'Próximo',
    'ru': 'Далее',
    'tr': 'İleri',
    'ar': 'التالي',
    'it': 'Avanti',
    'hi': 'अगला',
    'th': 'ถัดไป',
  });
  String get checking => _t({
    'ko': '확인 중...',
    'en': 'Checking...',
    'ja': '確認中...',
    'zh': '检查中...',
    'fr': 'Vérification...',
    'de': 'Prüfung...',
    'es': 'Verificando...',
    'pt': 'Verificando...',
    'ru': 'Проверка...',
    'tr': 'Kontrol ediliyor...',
    'ar': 'جارٍ التحقق...',
    'it': 'Verifica...',
    'hi': 'जाँच हो रही है...',
    'th': 'กำลังตรวจสอบ...',
  });
  String get locationAllow => _t({
    'ko': '위치 허용하기',
    'en': 'Allow Location',
    'ja': '位置を許可',
    'zh': '允许位置',
    'fr': 'Autoriser la position',
    'de': 'Standort erlauben',
    'es': 'Permitir ubicación',
    'pt': 'Permitir localização',
    'ru': 'Разрешить геолокацию',
    'tr': 'Konuma izin ver',
    'ar': 'السماح بالموقع',
    'it': 'Consenti posizione',
    'hi': 'स्थान अनुमति दें',
    'th': 'อนุญาตตำแหน่ง',
  });
  String get locationGranted => _t({
    'ko': '위치 허용 완료!',
    'en': 'Location Allowed!',
    'ja': '位置情報を許可しました！',
    'zh': '位置已允许！',
    'fr': 'Position autorisée !',
    'de': 'Standort erlaubt!',
    'es': '¡Ubicación permitida!',
    'pt': 'Localização permitida!',
    'ru': 'Геолокация разрешена!',
    'tr': 'Konum izni verildi!',
    'ar': 'تم السماح بالموقع!',
    'it': 'Posizione consentita!',
    'hi': 'स्थान अनुमत है!',
    'th': 'อนุญาตตำแหน่งแล้ว!',
  });
  String get locationRequired => _t({
    'ko': '내 위치 허용이 필요해요',
    'en': 'Location Permission Required',
    'ja': '位置情報の許可が必要です',
    'zh': '需要位置权限',
    'fr': 'Permission de localisation requise',
    'de': 'Standortberechtigung erforderlich',
    'es': 'Permiso de ubicación requerido',
    'pt': 'Permissão de localização necessária',
    'ru': 'Необходимо разрешение на геолокацию',
    'tr': 'Konum izni gerekli',
    'ar': 'إذن الموقع مطلوب',
    'it': 'Autorizzazione posizione richiesta',
    'hi': 'स्थान अनुमति आवश्यक है',
    'th': 'ต้องการอนุญาตตำแหน่ง',
  });
  String get locationGrantedBody => _t({
    'ko': '주변 2km 이내에 도착한 혜택을\n수령할 수 있어요 🎉',
    'en': 'You can receive rewards that arrive\nwithin 2km of you 🎉',
    'ja': '2km以内に届いた手紙を\n受け取ることができます 🎉',
    'zh': '您可以接收到达\n2公里范围内的信件 🎉',
    'fr': 'Vous pouvez recevoir les lettres\narrivant à 2km de vous 🎉',
    'de': 'Sie können Briefe erhalten,\ndie innerhalb 2km ankommen 🎉',
    'es': 'Puedes recibir cartas que lleguen\na 2km de ti 🎉',
    'pt': 'Você pode receber cartas que chegam\na 2km de você 🎉',
    'ru': 'Вы можете получать письма\nв радиусе 2км 🎉',
    'tr': '2km içindeki mektupları\nalabilirsiniz 🎉',
    'ar': 'يمكنك استلام الرسائل الواصلة\nضمن 2 كم منك 🎉',
    'it': 'Puoi ricevere lettere che arrivano\nentro 2km da te 🎉',
    'hi': '2 किमी के भीतर पहुंचने वाले पत्र\nप्राप्त कर सकते हैं 🎉',
    'th': 'คุณสามารถรับจดหมายที่มาถึง\nภายใน 2 กม. จากคุณ 🎉',
  });
  String get locationRequiredBody => _t({
    'ko': '혜택이 내 위치 2km 이내에 도착하면\n알림을 받을 수 있어요.\n위치 정보는 앱 내에서만 사용됩니다.',
    'en':
        'Get notified when a reward arrives\nwithin 2km of you.\nLocation is only used within the app.',
    'ja': '2km以内に手紙が届いたとき\n通知を受け取れます。\n位置情報はアプリ内のみで使用されます。',
    'zh': '当信件到达2公里范围内时\n您将收到通知。\n位置仅在应用内使用。',
    'fr':
        'Recevez des notifications lorsqu\'une lettre\narrive à 2km de vous.\nLa position est utilisée uniquement dans l\'app.',
    'de':
        'Benachrichtigungen wenn ein Brief\ninnerhalb 2km ankommt.\nStandort wird nur in der App verwendet.',
    'es':
        'Recibe notificaciones cuando llegue una carta\na 2km de ti.\nLa ubicación solo se usa en la app.',
    'pt':
        'Receba notificações quando uma carta chegar\na 2km de você.\nLocalização usada apenas no app.',
    'ru':
        'Получайте уведомления когда письмо\nприбывает в 2км.\nГеолокация используется только в приложении.',
    'tr':
        '2km içinde mektup geldiğinde\nbildirim alın.\nKonum yalnızca uygulama içinde kullanılır.',
    'ar':
        'احصل على إشعار عند وصول رسالة\nضمن 2 كم.\nيُستخدم الموقع داخل التطبيق فقط.',
    'it':
        'Ricevi notifiche quando una lettera\narriva a 2km da te.\nLa posizione è usata solo nell\'app.',
    'hi':
        'जब 2 किमी के भीतर पत्र आए\nतो सूचना पाएं।\nस्थान केवल ऐप में उपयोग होता है।',
    'th':
        'รับการแจ้งเตือนเมื่อจดหมายมาถึง\nภายใน 2 กม.\nตำแหน่งใช้เฉพาะในแอปเท่านั้น',
  });

  // ── Premium ───────────────────────────────────────────────────────────────
  String get premiumPlanTitle => _t({
    'ko': '플랜 선택',
    'en': 'Plan Selection',
    'ja': 'プラン選択',
    'zh': '选择方案',
    'fr': 'Sélection du forfait',
    'de': 'Plan auswählen',
    'es': 'Selección de plan',
    'pt': 'Seleção de plano',
    'ru': 'Выбор тарифа',
    'tr': 'Plan seçimi',
    'ar': 'اختيار الخطة',
    'it': 'Selezione piano',
    'hi': 'प्लान चुनें',
    'th': 'เลือกแผน',
  });
  String get premiumCurrentPlan => _t({
    'ko': '현재 플랜',
    'en': 'Current Plan',
    'ja': '現在のプラン',
    'zh': '当前方案',
    'fr': 'Forfait actuel',
    'de': 'Aktueller Plan',
    'es': 'Plan actual',
    'pt': 'Plano atual',
    'ru': 'Текущий тариф',
    'tr': 'Mevcut plan',
    'ar': 'الخطة الحالية',
    'it': 'Piano attuale',
    'hi': 'वर्तमान प्लान',
    'th': 'แผนปัจจุบัน',
  });
  String get premiumFreeTrial => _t({
    'ko': '3일 무료',
    'en': '3-day free',
    'ja': '3日間無料',
    'zh': '3天免费',
    'fr': '3 jours gratuits',
    'de': '3 Tage kostenlos',
    'es': '3 días gratis',
    'pt': '3 dias grátis',
    'ru': '3 дня бесплатно',
    'tr': '3 gün ücretsiz',
    'ar': '3 أيام مجاناً',
    'it': '3 giorni gratuiti',
    'hi': '3 दिन मुफ्त',
    'th': '3 วันฟรี',
  });
  String get premiumSubscribeBtn => _t({
    'ko': '구독 시작하기',
    'en': 'Subscribe',
    'ja': '購読を開始する',
    'zh': '开始订阅',
    'fr': "S'abonner",
    'de': 'Abonnieren',
    'es': 'Suscribirse',
    'pt': 'Assinar',
    'ru': 'Подписаться',
    'tr': 'Abone ol',
    'ar': 'اشترك الآن',
    'it': 'Abbonati',
    'hi': 'सदस्यता लें',
    'th': 'สมัครสมาชิก',
  });
  String get premiumRestorePurchase => _t({
    'ko': '이전 구매 복원',
    'en': 'Restore Purchase',
    'ja': '以前の購入を復元',
    'zh': '恢复购买',
    'fr': 'Restaurer les achats',
    'de': 'Kauf wiederherstellen',
    'es': 'Restaurar compra',
    'pt': 'Restaurar compra',
    'ru': 'Восстановить покупку',
    'tr': 'Satın almayı geri yükle',
    'ar': 'استعادة الشراء',
    'it': 'Ripristina acquisto',
    'hi': 'खरीदारी पुनर्स्थापित करें',
    'th': 'กู้คืนการซื้อ',
  });
  String get premiumAutoRenew => _t({
    'ko': '구독은 각 기간 종료 24시간 전에 자동 갱신됩니다.\n언제든지 앱스토어 / 플레이스토어에서 해지 가능합니다.',
    'en':
        'Subscription renews automatically 24 hours before the end of each period.\nCancel anytime from App Store / Play Store.',
    'ja':
        'サブスクリプションは各期間終了の24時間前に自動更新されます。\nいつでもApp Store / Play Storeからキャンセルできます。',
    'zh': '订阅在每个周期结束前24小时自动续订。\n随时可从App Store / Play Store取消。',
    'fr':
        "L'abonnement se renouvelle automatiquement 24h avant la fin de chaque période.\nAnnulez à tout moment depuis l'App Store / Play Store.",
    'de':
        'Das Abonnement verlängert sich automatisch 24 Stunden vor Ende jeder Periode.\nJederzeit im App Store / Play Store kündbar.',
    'es':
        'La suscripción se renueva automáticamente 24 horas antes del final de cada período.\nCancela en cualquier momento desde App Store / Play Store.',
    'pt':
        'A assinatura é renovada automaticamente 24 horas antes do fim de cada período.\nCancele a qualquer momento na App Store / Play Store.',
    'ru':
        'Подписка автоматически продлевается за 24 часа до окончания каждого периода.\nОтмените в любое время в App Store / Play Store.',
    'tr':
        'Abonelik her dönem bitmeden 24 saat önce otomatik yenilenir.\nApp Store / Play Store\'dan istediğiniz zaman iptal edebilirsiniz.',
    'ar':
        'يتجدد الاشتراك تلقائياً قبل 24 ساعة من نهاية كل فترة.\nيمكن الإلغاء في أي وقت من App Store / Play Store.',
    'it':
        "L'abbonamento si rinnova automaticamente 24 ore prima della fine di ogni periodo.\nAnnulla in qualsiasi momento da App Store / Play Store.",
    'hi':
        'सदस्यता प्रत्येक अवधि समाप्त होने से 24 घंटे पहले स्वतः नवीनीकृत होती है।\nApp Store / Play Store से कभी भी रद्द करें।',
    'th':
        'การสมัครสมาชิกจะต่ออายุอัตโนมัติ 24 ชั่วโมงก่อนสิ้นสุดแต่ละรอบ\nยกเลิกได้ตลอดเวลาจาก App Store / Play Store',
  });
  String get premiumActivePlan => _t({
    'ko': '모든 프리미엄 기능을 이용 중이에요 🎉',
    'en': 'You are using all premium features 🎉',
    'ja': 'すべてのプレミアム機能をご利用中です 🎉',
    'zh': '您正在使用所有高级功能 🎉',
    'fr': 'Vous utilisez toutes les fonctionnalités premium 🎉',
    'de': 'Sie nutzen alle Premium-Funktionen 🎉',
    'es': 'Estás usando todas las funciones premium 🎉',
    'pt': 'Você está usando todos os recursos premium 🎉',
    'ru': 'Вы используете все премиум-функции 🎉',
    'tr': 'Tüm premium özellikleri kullanıyorsunuz 🎉',
    'ar': 'أنت تستخدم جميع الميزات المميزة 🎉',
    'it': 'Stai usando tutte le funzionalità premium 🎉',
    'hi': 'आप सभी प्रीमियम सुविधाओं का उपयोग कर रहे हैं 🎉',
    'th': 'คุณกำลังใช้ฟีเจอร์พรีเมียมทั้งหมด 🎉',
  });
  // Build 119: 페이월 히어로 카피 픽업-퍼스트. 기존 "더 넓은 세계로 혜택을
  // 보내보세요" → 5배 반경 · 6배 빠른 쿨다운 으로 핵심 가치 전환.
  String get premiumHeroTitle => _t({
    'ko': '더 넓은 반경으로\n쿠폰을 주워보세요',
    'en': 'Pick up coupons\nacross a wider radius',
    'ja': 'より広い範囲で\nクーポンを拾おう',
    'zh': '在更大范围内\n拾起优惠券',
    'fr': 'Ramasse des coupons\ndans un rayon plus large',
    'de': 'Sammle Coupons\nin einem größeren Umkreis',
    'es': 'Recoge cupones\nen un radio más amplio',
    'pt': 'Apanha cupões\nnum raio maior',
    'ru': 'Подбирайте купоны\nв большем радиусе',
    'tr': 'Daha geniş alanda\nkupon topla',
    'ar': 'التقط كوبونات\nفي نطاق أوسع',
    'it': 'Raccogli coupon\nin un raggio più ampio',
    'hi': 'बड़े दायरे में\nकूपन उठाओ',
    'th': 'เก็บคูปอง\nในรัศมีที่กว้างขึ้น',
  });
  String get premiumActivePlanLabel => _t({
    'ko': '현재 이용 중인 플랜',
    'en': 'Current Plan',
    'ja': '現在ご利用中のプラン',
    'zh': '当前使用中的方案',
    'fr': 'Plan actuellement utilisé',
    'de': 'Aktuell genutzter Plan',
    'es': 'Plan actualmente en uso',
    'pt': 'Plano em uso atual',
    'ru': 'Текущий используемый план',
    'tr': 'Şu an kullanılan plan',
    'ar': 'الخطة المستخدمة حالياً',
    'it': 'Piano attualmente in uso',
    'hi': 'वर्तमान में उपयोग किया जा रहा प्लान',
    'th': 'แผนที่ใช้อยู่ปัจจุบัน',
  });
  String get premiumGiftCard => _t({
    'ko': '1개월 선물권',
    'en': '1-month Gift Card',
    'ja': '1ヶ月ギフトカード',
    'zh': '1个月礼品卡',
    'fr': 'Carte cadeau 1 mois',
    'de': '1-Monat Geschenkkarte',
    'es': 'Tarjeta regalo 1 mes',
    'pt': 'Cartão presente 1 mês',
    'ru': 'Подарочная карта на 1 месяц',
    'tr': '1 aylık hediye kartı',
    'ar': 'بطاقة هدية لمدة شهر',
    'it': 'Carta regalo 1 mese',
    'hi': '1 महीने का गिफ्ट कार्ड',
    'th': 'บัตรของขวัญ 1 เดือน',
  });
  String get premiumGiftCardDesc => _t({
    'ko': '친구에게 1개월 프리미엄을 선물해보세요',
    'en': 'Gift 1 month of Premium to a friend',
    'ja': '友達に1ヶ月のプレミアムをプレゼントしよう',
    'zh': '送给朋友1个月高级会员',
    'fr': 'Offrez 1 mois de Premium à un ami',
    'de': 'Schenke einem Freund 1 Monat Premium',
    'es': 'Regala 1 mes de Premium a un amigo',
    'pt': 'Presenteie um amigo com 1 mês de Premium',
    'ru': 'Подарите другу 1 месяц Premium',
    'tr': 'Arkadaşına 1 aylık Premium hediye et',
    'ar': 'أهدِ صديقك شهراً من Premium',
    'it': 'Regala 1 mese di Premium a un amico',
    'hi': 'दोस्त को 1 महीने का प्रीमियम उपहार दें',
    'th': 'ให้ 1 เดือนพรีเมียมเป็นของขวัญแก่เพื่อน',
  });
  String get premiumGiftCardDiscount => _t({
    'ko': '(10% 할인)',
    'en': '(10% off)',
    'ja': '(10%割引)',
    'zh': '(9折)',
    'fr': '(10% de réduction)',
    'de': '(10% Rabatt)',
    'es': '(10% de descuento)',
    'pt': '(10% de desconto)',
    'ru': '(скидка 10%)',
    'tr': '(%10 indirim)',
    'ar': '(خصم 10%)',
    'it': '(10% di sconto)',
    'hi': '(10% छूट)',
    'th': '(ลด 10%)',
  });
  String get premiumBuyBtn => _t({
    'ko': '구매',
    'en': 'Buy',
    'ja': '購入',
    'zh': '购买',
    'fr': 'Acheter',
    'de': 'Kaufen',
    'es': 'Comprar',
    'pt': 'Comprar',
    'ru': 'Купить',
    'tr': 'Satın al',
    'ar': 'شراء',
    'it': 'Acquista',
    'hi': 'खरीदें',
    'th': 'ซื้อ',
  });
  String get premiumGiftSuccess => _t({
    'ko': '선물권 구매 완료!',
    'en': 'Gift Card Purchase Complete!',
    'ja': 'ギフトカード購入完了！',
    'zh': '礼品卡购买完成！',
    'fr': "Achat de la carte cadeau terminé !",
    'de': 'Geschenkkartenkauf abgeschlossen!',
    'es': '¡Compra de tarjeta regalo completada!',
    'pt': 'Compra do cartão presente concluída!',
    'ru': 'Покупка подарочной карты завершена!',
    'tr': 'Hediye kartı satın alma tamamlandı!',
    'ar': 'اكتمل شراء بطاقة الهدية!',
    'it': 'Acquisto carta regalo completato!',
    'hi': 'गिफ्ट कार्ड खरीद पूर्ण!',
    'th': 'ซื้อบัตรของขวัญสำเร็จ!',
  });
  String get premiumSectionCompare => _t({
    'ko': '📊 플랜 비교',
    'en': '📊 Plan Comparison',
    'ja': '📊 プラン比較',
    'zh': '📊 方案比较',
    'fr': '📊 Comparaison des forfaits',
    'de': '📊 Planvergleich',
    'es': '📊 Comparación de planes',
    'pt': '📊 Comparação de planos',
    'ru': '📊 Сравнение тарифов',
    'tr': '📊 Plan karşılaştırması',
    'ar': '📊 مقارنة الخطط',
    'it': '📊 Confronto piani',
    'hi': '📊 प्लान तुलना',
    'th': '📊 เปรียบเทียบแผน',
  });
  String get premiumSectionGift => _t({
    'ko': '🎁 선물권',
    'en': '🎁 Gift Card',
    'ja': '🎁 ギフトカード',
    'zh': '🎁 礼品卡',
    'fr': '🎁 Carte cadeau',
    'de': '🎁 Geschenkkarte',
    'es': '🎁 Tarjeta regalo',
    'pt': '🎁 Cartão presente',
    'ru': '🎁 Подарочная карта',
    'tr': '🎁 Hediye kartı',
    'ar': '🎁 بطاقة هدية',
    'it': '🎁 Carta regalo',
    'hi': '🎁 गिफ्ट कार्ड',
    'th': '🎁 บัตรของขวัญ',
  });
  String get premiumSectionExtra => _t({
    'ko': '💳 추가 발송권',
    'en': '💳 Extra Send Quota',
    'ja': '💳 追加送信枠',
    'zh': '💳 额外发送配额',
    'fr': '💳 Quota d\'envoi supplémentaire',
    'de': '💳 Extra Sendekontingent',
    'es': '💳 Cuota de envío extra',
    'pt': '💳 Cota de envio extra',
    'ru': '💳 Дополнительная квота отправки',
    'tr': '💳 Ek gönderim kotası',
    'ar': '💳 حصة إرسال إضافية',
    'it': '💳 Quota invio extra',
    'hi': '💳 अतिरिक्त भेजने का कोटा',
    'th': '💳 โควต้าส่งเพิ่มเติม',
  });
  String get premiumExtraTitle => _t({
    'ko': '추가 발송권',
    'en': 'Extra Send Quota',
    'ja': '追加送信枠',
    'zh': '额外发送配额',
    'fr': "Quota d'envoi supplémentaire",
    'de': 'Extra Sendekontingent',
    'es': 'Cuota de envío extra',
    'pt': 'Cota de envio extra',
    'ru': 'Дополнительная квота отправки',
    'tr': 'Ek gönderim kotası',
    'ar': 'حصة إرسال إضافية',
    'it': 'Quota invio extra',
    'hi': 'अतिरिक्त भेजने का कोटा',
    'th': 'โควต้าส่งเพิ่มเติม',
  });
  String get premiumExtraDesc => _t({
    'ko': '1,000통 ₩15,000',
    'en': '1,000 promos ₩15,000',
    'ja': '1,000通 ₩15,000',
    'zh': '1,000封 ₩15,000',
    'fr': '1 000 lettres ₩15 000',
    'de': '1.000 Briefe ₩15.000',
    'es': '1.000 cartas ₩15.000',
    'pt': '1.000 cartas ₩15.000',
    'ru': '1 000 писем ₩15 000',
    'tr': '1.000 mektup ₩15.000',
    'ar': '1,000 رسالة ₩15,000',
    'it': '1.000 lettere ₩15.000',
    'hi': '1,000 पत्र ₩15,000',
    'th': '1,000 ฉบับ ₩15,000',
  });
  String get premiumDowngradeTitle => _t({
    'ko': '구독 해지 예약',
    'en': 'Schedule Cancellation',
    'ja': 'キャンセル予約',
    'zh': '预约取消订阅',
    'fr': "Planifier l'annulation",
    'de': 'Kündigung planen',
    'es': 'Programar cancelación',
    'pt': 'Agendar cancelamento',
    'ru': 'Запланировать отмену',
    'tr': 'İptal planla',
    'ar': 'جدولة الإلغاء',
    'it': 'Pianifica cancellazione',
    'hi': 'रद्दीकरण शेड्यूल करें',
    'th': 'กำหนดการยกเลิก',
  });
  String get premiumDowngradeBtn => _t({
    'ko': '해지 예약',
    'en': 'Schedule Cancel',
    'ja': 'キャンセル予約',
    'zh': '预约取消',
    'fr': "Programmer l'annulation",
    'de': 'Kündigung einplanen',
    'es': 'Programar cancelación',
    'pt': 'Agendar cancelamento',
    'ru': 'Запланировать отмену',
    'tr': 'İptal planla',
    'ar': 'جدولة الإلغاء',
    'it': 'Pianifica cancellazione',
    'hi': 'रद्दीकरण शेड्यूल करें',
    'th': 'กำหนดการยกเลิก',
  });
  String get premiumCancelDowngrade => _t({
    'ko': '예약 취소',
    'en': 'Cancel',
    'ja': 'キャンセル',
    'zh': '取消预约',
    'fr': 'Annuler',
    'de': 'Abbrechen',
    'es': 'Cancelar',
    'pt': 'Cancelar',
    'ru': 'Отменить',
    'tr': 'İptal',
    'ar': 'إلغاء',
    'it': 'Annulla',
    'hi': 'रद्द करें',
    'th': 'ยกเลิก',
  });
  String get premiumLater => _t({
    'ko': '나중에',
    'en': 'Later',
    'ja': 'あとで',
    'zh': '以后再说',
    'fr': 'Plus tard',
    'de': 'Später',
    'es': 'Más tarde',
    'pt': 'Depois',
    'ru': 'Позже',
    'tr': 'Sonra',
    'ar': 'لاحقاً',
    'it': 'Dopo',
    'hi': 'बाद में',
    'th': 'ทีหลัง',
  });
  String get premiumPlanComingSoon => _t({
    'ko': '준비 중',
    'en': 'Coming Soon',
    'ja': '準備中',
    'zh': '即将推出',
    'fr': 'Bientôt disponible',
    'de': 'Demnächst',
    'es': 'Próximamente',
    'pt': 'Em breve',
    'ru': 'Скоро',
    'tr': 'Yakında',
    'ar': 'قريباً',
    'it': 'Prossimamente',
    'hi': 'जल्द आ रहा है',
    'th': 'เร็วๆ นี้',
  });

  // ── Settings ──────────────────────────────────────────────────────────────
  String get settingsTitle => _t({
    'ko': '설정',
    'en': 'Settings',
    'ja': '設定',
    'zh': '设置',
    'fr': 'Paramètres',
    'de': 'Einstellungen',
    'es': 'Ajustes',
    'pt': 'Configurações',
    'ru': 'Настройки',
    'tr': 'Ayarlar',
    'ar': 'الإعدادات',
    'it': 'Impostazioni',
    'hi': 'सेटिंग्स',
    'th': 'การตั้งค่า',
  });
  String get settingsSnsLink => _t({
    'ko': 'SNS 링크 수정',
    'en': 'Edit SNS Link',
    'ja': 'SNSリンク編集',
    'zh': '编辑SNS链接',
    'fr': 'Modifier le lien SNS',
    'de': 'SNS-Link bearbeiten',
    'es': 'Editar enlace SNS',
    'pt': 'Editar link SNS',
    'ru': 'Изменить ссылку SNS',
    'tr': 'SNS bağlantısını düzenle',
    'ar': 'تعديل رابط SNS',
    'it': 'Modifica link SNS',
    'hi': 'SNS लिंक संपादित करें',
    'th': 'แก้ไขลิงก์ SNS',
  });
  String get settingsChangePassword => _t({
    'ko': '비밀번호 변경',
    'en': 'Change Password',
    'ja': 'パスワード変更',
    'zh': '修改密码',
    'fr': 'Changer le mot de passe',
    'de': 'Passwort ändern',
    'es': 'Cambiar contraseña',
    'pt': 'Alterar senha',
    'ru': 'Изменить пароль',
    'tr': 'Şifre değiştir',
    'ar': 'تغيير كلمة المرور',
    'it': 'Cambia password',
    'hi': 'पासवर्ड बदलें',
    'th': 'เปลี่ยนรหัสผ่าน',
  });
  String get settingsSave => _t({
    'ko': '저장',
    'en': 'Save',
    'ja': '保存',
    'zh': '保存',
    'fr': 'Enregistrer',
    'de': 'Speichern',
    'es': 'Guardar',
    'pt': 'Salvar',
    'ru': 'Сохранить',
    'tr': 'Kaydet',
    'ar': 'حفظ',
    'it': 'Salva',
    'hi': 'सहेजें',
    'th': 'บันทึก',
  });
  String get settingsCancel => _t({
    'ko': '취소',
    'en': 'Cancel',
    'ja': 'キャンセル',
    'zh': '取消',
    'fr': 'Annuler',
    'de': 'Abbrechen',
    'es': 'Cancelar',
    'pt': 'Cancelar',
    'ru': 'Отмена',
    'tr': 'İptal',
    'ar': 'إلغاء',
    'it': 'Annulla',
    'hi': 'रद्द करें',
    'th': 'ยกเลิก',
  });
  String get settingsCurrentPw => _t({
    'ko': '현재 비밀번호',
    'en': 'Current Password',
    'ja': '現在のパスワード',
    'zh': '当前密码',
    'fr': 'Mot de passe actuel',
    'de': 'Aktuelles Passwort',
    'es': 'Contraseña actual',
    'pt': 'Senha atual',
    'ru': 'Текущий пароль',
    'tr': 'Mevcut şifre',
    'ar': 'كلمة المرور الحالية',
    'it': 'Password attuale',
    'hi': 'वर्तमान पासवर्ड',
    'th': 'รหัสผ่านปัจจุบัน',
  });
  String get settingsNewPw => _t({
    'ko': '새 비밀번호 (6자 이상)',
    'en': 'New Password (min 6 chars)',
    'ja': '新しいパスワード（6文字以上）',
    'zh': '新密码（至少6位）',
    'fr': 'Nouveau mot de passe (6 car. min)',
    'de': 'Neues Passwort (mind. 6 Zeichen)',
    'es': 'Nueva contraseña (mín. 6 chars)',
    'pt': 'Nova senha (mín. 6 chars)',
    'ru': 'Новый пароль (мин. 6 символов)',
    'tr': 'Yeni şifre (en az 6 karakter)',
    'ar': 'كلمة مرور جديدة (6 أحرف على الأقل)',
    'it': 'Nuova password (min 6 car.)',
    'hi': 'नया पासवर्ड (न्यूनतम 6 अक्षर)',
    'th': 'รหัสผ่านใหม่ (อย่างน้อย 6 ตัว)',
  });
  String get settingsNewPwConfirm => _t({
    'ko': '새 비밀번호 확인',
    'en': 'Confirm New Password',
    'ja': '新しいパスワードを確認',
    'zh': '确认新密码',
    'fr': 'Confirmer le nouveau mot de passe',
    'de': 'Neues Passwort bestätigen',
    'es': 'Confirmar nueva contraseña',
    'pt': 'Confirmar nova senha',
    'ru': 'Подтвердите новый пароль',
    'tr': 'Yeni şifreyi onayla',
    'ar': 'تأكيد كلمة المرور الجديدة',
    'it': 'Conferma nuova password',
    'hi': 'नया पासवर्ड पुष्टि करें',
    'th': 'ยืนยันรหัสผ่านใหม่',
  });
  String get settingsPwMin6 => _t({
    'ko': '비밀번호는 6자 이상이어야 합니다',
    'en': 'Password must be at least 6 characters',
    'ja': 'パスワードは6文字以上必要です',
    'zh': '密码至少需要6个字符',
    'fr': 'Le mot de passe doit contenir au moins 6 caractères',
    'de': 'Das Passwort muss mindestens 6 Zeichen lang sein',
    'es': 'La contraseña debe tener al menos 6 caracteres',
    'pt': 'A senha deve ter pelo menos 6 caracteres',
    'ru': 'Пароль должен содержать не менее 6 символов',
    'tr': 'Şifre en az 6 karakter olmalıdır',
    'ar': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
    'it': 'La password deve essere di almeno 6 caratteri',
    'hi': 'पासवर्ड कम से कम 6 अक्षर का होना चाहिए',
    'th': 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร',
  });
  String get settingsPwMismatch => _t({
    'ko': '새 비밀번호가 일치하지 않습니다',
    'en': 'New passwords do not match',
    'ja': '新しいパスワードが一致しません',
    'zh': '新密码不匹配',
    'fr': 'Les nouveaux mots de passe ne correspondent pas',
    'de': 'Die neuen Passwörter stimmen nicht überein',
    'es': 'Las nuevas contraseñas no coinciden',
    'pt': 'As novas senhas não coincidem',
    'ru': 'Новые пароли не совпадают',
    'tr': 'Yeni şifreler uyuşmuyor',
    'ar': 'كلمات المرور الجديدة غير متطابقة',
    'it': 'Le nuove password non corrispondono',
    'hi': 'नए पासवर्ड मेल नहीं खाते',
    'th': 'รหัสผ่านใหม่ไม่ตรงกัน',
  });
  String get settingsPwChanged => _t({
    'ko': '비밀번호가 변경되었습니다',
    'en': 'Password changed successfully',
    'ja': 'パスワードが変更されました',
    'zh': '密码已更改',
    'fr': 'Mot de passe modifié avec succès',
    'de': 'Passwort erfolgreich geändert',
    'es': 'Contraseña cambiada exitosamente',
    'pt': 'Senha alterada com sucesso',
    'ru': 'Пароль успешно изменён',
    'tr': 'Şifre başarıyla değiştirildi',
    'ar': 'تم تغيير كلمة المرور بنجاح',
    'it': 'Password cambiata con successo',
    'hi': 'पासवर्ड सफलतापूर्वक बदला गया',
    'th': 'เปลี่ยนรหัสผ่านสำเร็จ',
  });
  String get settingsPwError => _t({
    'ko': '비밀번호 변경 실패',
    'en': 'Failed to change password',
    'ja': 'パスワードの変更に失敗しました',
    'zh': '更改密码失败',
    'fr': 'Échec du changement de mot de passe',
    'de': 'Passwortänderung fehlgeschlagen',
    'es': 'Error al cambiar la contraseña',
    'pt': 'Falha ao alterar a senha',
    'ru': 'Не удалось изменить пароль',
    'tr': 'Şifre değiştirilemedi',
    'ar': 'فشل تغيير كلمة المرور',
    'it': 'Impossibile cambiare la password',
    'hi': 'पासवर्ड बदलने में विफल',
    'th': 'เปลี่ยนรหัสผ่านไม่สำเร็จ',
  });
  String get settingsNotifyNearby => _t({
    'ko': '주변 혜택 알림',
    'en': 'Nearby Reward Notification',
    'ja': '近くの手紙通知',
    'zh': '附近信件通知',
    'fr': 'Notification de lettre à proximité',
    'de': 'Benachrichtigung für nahe Briefe',
    'es': 'Notificación de carta cercana',
    'pt': 'Notificação de carta próxima',
    'ru': 'Уведомление о ближайших письмах',
    'tr': 'Yakındaki mektup bildirimi',
    'ar': 'إشعار الرسائل القريبة',
    'it': 'Notifica lettera vicina',
    'hi': 'पास के पत्र की सूचना',
    'th': 'การแจ้งเตือนจดหมายใกล้เคียง',
  });
  String senderMomentLine(int hour) {
    // 시간대 라벨 + "에 쓴 편지" 구조
    final label = _hourToPartOfDay(hour);
    switch (languageCode) {
      case 'ko': return '$label $hour시에 쓴 홍보';
      case 'ja': return '$label $hour時に書かれた手紙';
      case 'zh': return '在$label $hour点写下的信';
      case 'fr': return "Lettre écrite $label à ${hour}h";
      case 'de': return 'Brief geschrieben $label um $hour Uhr';
      case 'es': return "Carta escrita $label a las $hour";
      case 'pt': return "Carta escrita $label às $hour";
      case 'ru': return 'Письмо написано $label в $hour:00';
      case 'tr': return '$label saat $hour\'da yazıldı';
      case 'ar': return 'رسالة كُتبت $label عند الساعة $hour';
      case 'it': return "Lettera scritta $label alle $hour";
      case 'hi': return '$label $hour बजे लिखा पत्र';
      case 'th': return 'จดหมายที่เขียนใน$labelเวลา $hour นาฬิกา';
      case 'en':
      default: return 'Written $label at $hour:00';
    }
  }

  String _hourToPartOfDay(int hour) {
    if (hour >= 5 && hour < 11) {
      return _t({
        'ko': '아침', 'en': 'in the morning', 'ja': '朝',
        'zh': '早晨', 'fr': 'le matin', 'de': 'morgens',
        'es': 'por la mañana', 'pt': 'de manhã', 'ru': 'утром',
        'tr': 'sabah', 'ar': 'صباحاً', 'it': 'di mattina',
        'hi': 'सुबह', 'th': 'ช่วงเช้า',
      });
    }
    if (hour >= 11 && hour < 17) {
      return _t({
        'ko': '낮', 'en': 'in the afternoon', 'ja': '昼',
        'zh': '白天', 'fr': "dans l'après-midi", 'de': 'nachmittags',
        'es': 'por la tarde', 'pt': 'à tarde', 'ru': 'днём',
        'tr': 'öğleden sonra', 'ar': 'ظهراً', 'it': 'di pomeriggio',
        'hi': 'दोपहर', 'th': 'ช่วงบ่าย',
      });
    }
    if (hour >= 17 && hour < 21) {
      return _t({
        'ko': '저녁', 'en': 'in the evening', 'ja': '夕方',
        'zh': '傍晚', 'fr': 'le soir', 'de': 'abends',
        'es': 'por la tarde', 'pt': 'à noite', 'ru': 'вечером',
        'tr': 'akşam', 'ar': 'مساءً', 'it': 'di sera',
        'hi': 'शाम', 'th': 'ช่วงเย็น',
      });
    }
    return _t({
      'ko': '밤', 'en': 'late at night', 'ja': '夜',
      'zh': '深夜', 'fr': 'tard le soir', 'de': 'spätnachts',
      'es': 'de madrugada', 'pt': 'tarde da noite', 'ru': 'ночью',
      'tr': 'gece', 'ar': 'ليلاً', 'it': 'di notte',
      'hi': 'रात', 'th': 'ช่วงค่ำคืน',
    });
  }

  String penpalBadgeCount(int n) {
    switch (languageCode) {
      case 'ko': return '$n번째';
      case 'ja': return '$n通目';
      case 'zh': return '第 $n 封';
      case 'fr': return '${n}e échange';
      case 'de': return '$n. Brief';
      case 'es': return '${n}º intercambio';
      case 'pt': return '${n}º intercâmbio';
      case 'ru': return '$n-е письмо';
      case 'tr': return '$n. mektup';
      case 'ar': return 'الرسالة ${n}';
      case 'it': return '${n}º scambio';
      case 'hi': return '${n}वाँ आदान-प्रदान';
      case 'th': return 'ฉบับที่ $n';
      case 'en':
      default: return '#$n exchange';
    }
  }

  String xpLevelBadge(int level) {
    switch (languageCode) {
      case 'ko': return 'Lv. $level';
      case 'ja': return 'Lv. $level';
      case 'zh': return 'Lv. $level';
      default: return 'Lv. $level';
    }
  }

  String xpLevelNextIn(int currentXp, int remaining) {
    switch (languageCode) {
      case 'ko': return '현재 $currentXp XP · 다음 레벨까지 $remaining XP';
      case 'ja': return '現在 $currentXp XP · 次のレベルまで $remaining XP';
      case 'zh': return '当前 $currentXp XP · 距离下一级 $remaining XP';
      case 'fr': return '$currentXp XP · $remaining XP jusqu\'au niveau suivant';
      case 'de': return '$currentXp XP · $remaining XP bis zum nächsten Level';
      case 'es': return '$currentXp XP · $remaining XP hasta el siguiente nivel';
      case 'pt': return '$currentXp XP · $remaining XP até o próximo nível';
      case 'ru': return '$currentXp XP · $remaining XP до следующего уровня';
      case 'tr': return '$currentXp XP · sonraki seviyeye $remaining XP';
      case 'ar': return '$currentXp XP · $remaining XP حتى المستوى التالي';
      case 'it': return '$currentXp XP · $remaining XP al prossimo livello';
      case 'hi': return '$currentXp XP · अगले स्तर तक $remaining XP';
      case 'th': return '$currentXp XP · อีก $remaining XP ถึงเลเวลถัดไป';
      case 'en':
      default: return '$currentXp XP · $remaining XP to next level';
    }
  }

  String xpLevelMaxed(int currentXp) {
    switch (languageCode) {
      case 'ko': return '$currentXp XP · 최고 레벨 도달 👑';
      case 'ja': return '$currentXp XP · 最高レベル達成 👑';
      case 'zh': return '$currentXp XP · 已达最高等级 👑';
      case 'fr': return '$currentXp XP · niveau maximum atteint 👑';
      case 'de': return '$currentXp XP · Höchstlevel erreicht 👑';
      case 'es': return '$currentXp XP · nivel máximo alcanzado 👑';
      case 'pt': return '$currentXp XP · nível máximo alcançado 👑';
      case 'ru': return '$currentXp XP · достигнут высший уровень 👑';
      case 'tr': return '$currentXp XP · en yüksek seviye 👑';
      case 'ar': return '$currentXp XP · وصلت إلى أعلى مستوى 👑';
      case 'it': return '$currentXp XP · livello massimo raggiunto 👑';
      case 'hi': return '$currentXp XP · सर्वोच्च स्तर पर पहुँचे 👑';
      case 'th': return '$currentXp XP · ถึงเลเวลสูงสุดแล้ว 👑';
      case 'en':
      default: return '$currentXp XP · max level reached 👑';
    }
  }

  String get premiumCollectionsHeader => _t({
    'ko': 'Air Mail Pass 컬렉션',
    'en': 'Air Mail Pass Collections',
    'ja': 'Air Mail Pass コレクション',
    'zh': 'Air Mail Pass 合集',
    'fr': 'Collections Air Mail Pass',
    'de': 'Air Mail Pass Kollektionen',
    'es': 'Colecciones Air Mail Pass',
    'pt': 'Coleções Air Mail Pass',
    'ru': 'Коллекции Air Mail Pass',
    'tr': 'Air Mail Pass Koleksiyonları',
    'ar': 'مجموعات Air Mail Pass',
    'it': 'Collezioni Air Mail Pass',
    'hi': 'Air Mail Pass कलेक्शन',
    'th': 'คอลเลกชัน Air Mail Pass',
  });
  String get premiumCollectionsSub => _t({
    'ko': '하나의 패스 안에, 카드의 결을 바꾸는 세 가지 컬렉션.',
    'en': 'One pass, three collections that change the grain of your promos.',
    'ja': '一つのパスで、手紙の質感を変える3つのコレクション。',
    'zh': '一张通行证，三种改变信件质地的合集。',
    'fr': 'Un seul Pass, trois collections qui changent la texture de vos lettres.',
    'de': 'Ein Pass, drei Kollektionen, die die Textur deiner Briefe verändern.',
    'es': 'Un solo pase, tres colecciones que cambian la textura de tus cartas.',
    'pt': 'Um passe, três coleções que mudam a textura das suas cartas.',
    'ru': 'Один Pass, три коллекции, меняющие текстуру ваших писем.',
    'tr': 'Tek bir pass, mektuplarınızın dokusunu değiştiren üç koleksiyon.',
    'ar': 'باقة واحدة، ثلاث مجموعات تغيّر ملمس رسائلك.',
    'it': 'Un solo pass, tre collezioni che cambiano la trama delle tue lettere.',
    'hi': 'एक पास, तीन कलेक्शन — आपके पत्रों का बनावट बदलते हैं।',
    'th': 'พาสหนึ่งใบ สามคอลเลกชันที่เปลี่ยนสัมผัสของจดหมาย',
  });
  String get premiumCollectionAuroraName => _t({
    'ko': '🌌 Aurora',
    'en': '🌌 Aurora',
    'ja': '🌌 Aurora',
    'zh': '🌌 Aurora',
    'fr': '🌌 Aurora',
    'de': '🌌 Aurora',
    'es': '🌌 Aurora',
    'pt': '🌌 Aurora',
    'ru': '🌌 Aurora',
    'tr': '🌌 Aurora',
    'ar': '🌌 Aurora',
    'it': '🌌 Aurora',
    'hi': '🌌 Aurora',
    'th': '🌌 Aurora',
  });
  String get premiumCollectionAuroraTagline => _t({
    'ko': '밤의 언어로 쓰는 홍보',
    'en': 'Promos in the language of the night',
    'ja': '夜の言葉で綴る手紙',
    'zh': '以夜的语言写成的信',
    'fr': 'Des lettres dans la langue de la nuit',
    'de': 'Briefe in der Sprache der Nacht',
    'es': 'Cartas en el idioma de la noche',
    'pt': 'Cartas na língua da noite',
    'ru': 'Письма на языке ночи',
    'tr': 'Gecenin dilinde mektuplar',
    'ar': 'رسائل بلغة الليل',
    'it': 'Lettere nella lingua della notte',
    'hi': 'रात की भाषा में पत्र',
    'th': 'จดหมายในภาษาของราตรี',
  });
  String get premiumCollectionAuroraBullet1 => _t({
    'ko': '야간 감성 카드 · 이미지 무제한',
    'en': 'Night-themed stationery · unlimited images',
    'ja': '夜の便箋 · 画像無制限',
    'zh': '夜间主题信纸 · 无限图片',
    'fr': 'Papeterie nocturne · images illimitées',
    'de': 'Nachtbriefpapier · unbegrenzte Bilder',
    'es': 'Papel nocturno · imágenes ilimitadas',
    'pt': 'Papel noturno · imagens ilimitadas',
    'ru': 'Ночной дизайн · безлимитные изображения',
    'tr': 'Gece temalı kırtasiye · sınırsız görsel',
    'ar': 'قرطاسية ليلية · صور بلا حدود',
    'it': 'Cancelleria notturna · immagini illimitate',
    'hi': 'रात्रि स्टेशनरी · असीमित छवियाँ',
    'th': 'กระดาษจดหมายธีมกลางคืน · รูปภาพไม่จำกัด',
  });
  String get premiumCollectionAuroraBullet2 => _t({
    'ko': '오로라·별·달빛 페이퍼 스타일',
    'en': 'Aurora, starlight, and moonlight paper styles',
    'ja': 'オーロラ・星・月光の用紙スタイル',
    'zh': '极光、星光、月光纸样',
    'fr': "Aurores, étoiles, clair de lune",
    'de': 'Aurora-, Sternen- und Mondlicht-Papier',
    'es': 'Estilos aurora, estrellas, luz de luna',
    'pt': 'Estilos aurora, estrelas, luar',
    'ru': 'Стили: полярное сияние, звёзды, лунный свет',
    'tr': 'Aurora, yıldız ışığı, ay ışığı tasarımları',
    'ar': 'تصاميم: الشفق، النجوم، ضوء القمر',
    'it': 'Stili aurora, stelle, chiaro di luna',
    'hi': 'ऑरोरा, तारों, चाँदनी वाले पेपर',
    'th': 'แบบกระดาษแสงเหนือ ดาว แสงจันทร์',
  });
  String get premiumCollectionHarvestName => _t({
    'ko': '🌾 Harvest',
    'en': '🌾 Harvest',
    'ja': '🌾 Harvest',
    'zh': '🌾 Harvest',
    'fr': '🌾 Harvest',
    'de': '🌾 Harvest',
    'es': '🌾 Harvest',
    'pt': '🌾 Harvest',
    'ru': '🌾 Harvest',
    'tr': '🌾 Harvest',
    'ar': '🌾 Harvest',
    'it': '🌾 Harvest',
    'hi': '🌾 Harvest',
    'th': '🌾 Harvest',
  });
  String get premiumCollectionHarvestTagline => _t({
    'ko': '계절이 지나가는 속도로',
    'en': 'Paced by the seasons',
    'ja': '季節の歩みとともに',
    'zh': '以季节的节奏',
    'fr': 'Au rythme des saisons',
    'de': 'Im Takt der Jahreszeiten',
    'es': 'Al ritmo de las estaciones',
    'pt': 'No ritmo das estações',
    'ru': 'В ритме времён года',
    'tr': 'Mevsimlerin temposuyla',
    'ar': 'بإيقاع الفصول',
    'it': 'Al ritmo delle stagioni',
    'hi': 'ऋतुओं की लय में',
    'th': 'ตามจังหวะของฤดูกาล',
  });
  String get premiumCollectionHarvestBullet1 => _t({
    'ko': '봄·여름·가을·겨울 카드 + 특급 배송',
    'en': 'Seasonal stationery + express delivery',
    'ja': '四季の便箋 + 特急配送',
    'zh': '四季信纸 + 特快寄送',
    'fr': 'Papeterie saisonnière + livraison express',
    'de': 'Saisonale Briefe + Express-Zustellung',
    'es': 'Papel estacional + entrega exprés',
    'pt': 'Papel sazonal + entrega expressa',
    'ru': 'Сезонный дизайн + экспресс-доставка',
    'tr': 'Mevsimlik kırtasiye + hızlı teslimat',
    'ar': 'قرطاسية موسمية + توصيل سريع',
    'it': 'Cancelleria stagionale + consegna express',
    'hi': 'मौसमी स्टेशनरी + एक्सप्रेस डिलिवरी',
    'th': 'กระดาษตามฤดูกาล + จัดส่งด่วน',
  });
  String get premiumCollectionHarvestBullet2 => _t({
    'ko': '이번 달의 도시 자동 테마 적용',
    'en': 'City-of-the-month themes applied automatically',
    'ja': '今月の都市テーマを自動適用',
    'zh': '自动套用本月之城主题',
    'fr': 'Thèmes "ville du mois" appliqués automatiquement',
    'de': 'Stadt-des-Monats-Themen automatisch angewendet',
    'es': 'Temas de "ciudad del mes" automáticos',
    'pt': 'Temas da "cidade do mês" automaticamente',
    'ru': 'Темы "город месяца" автоматически',
    'tr': 'Ayın şehri temaları otomatik uygulanır',
    'ar': 'مواضيع مدينة الشهر تلقائياً',
    'it': 'Temi "città del mese" automatici',
    'hi': '"महीने का शहर" थीम स्वतः लगते हैं',
    'th': 'ธีม "เมืองประจำเดือน" ติดอัตโนมัติ',
  });
  String get premiumCollectionPostmasterName => _t({
    'ko': '💌 Postmaster',
    'en': '💌 Postmaster',
    'ja': '💌 Postmaster',
    'zh': '💌 Postmaster',
    'fr': '💌 Postmaster',
    'de': '💌 Postmaster',
    'es': '💌 Postmaster',
    'pt': '💌 Postmaster',
    'ru': '💌 Postmaster',
    'tr': '💌 Postmaster',
    'ar': '💌 Postmaster',
    'it': '💌 Postmaster',
    'hi': '💌 Postmaster',
    'th': '💌 Postmaster',
  });
  String get premiumCollectionPostmasterTagline => _t({
    'ko': '공식 발송인의 권한',
    'en': 'The Official Sender tier',
    'ja': '公式発送人の権限',
    'zh': '官方寄件人权限',
    'fr': "Les privilèges du Postmaster",
    'de': 'Die Rechte des offiziellen Absenders',
    'es': 'Los privilegios del remitente oficial',
    'pt': 'Privilégios de remetente oficial',
    'ru': 'Привилегии официального отправителя',
    'tr': 'Resmi gönderici ayrıcalıkları',
    'ar': 'امتيازات المرسل الرسمي',
    'it': 'Privilegi di mittente ufficiale',
    'hi': 'आधिकारिक प्रेषक के विशेषाधिकार',
    'th': 'สิทธิของผู้ส่งทางการ',
  });
  String get premiumCollectionPostmasterBullet1 => _t({
    'ko': '무제한 하늘길 · 답장 우선 도착',
    'en': 'Unlimited skyways · priority reply delivery',
    'ja': '無制限エアルート · 返信が優先到着',
    'zh': '无限空邮 · 回信优先送达',
    'fr': 'Voies aériennes illimitées · priorité des réponses',
    'de': 'Unbegrenzte Luftwege · Antworten mit Vorrang',
    'es': 'Vías aéreas ilimitadas · respuestas prioritarias',
    'pt': 'Vias aéreas ilimitadas · respostas prioritárias',
    'ru': 'Неограниченные авиапути · ответы в приоритете',
    'tr': 'Sınırsız hava yolu · cevaplar önceliklidir',
    'ar': 'خطوط جوية غير محدودة · أولوية للردود',
    'it': 'Rotte aeree illimitate · risposte prioritarie',
    'hi': 'असीमित एयरवे · जवाब प्राथमिकता से',
    'th': 'สายการบินไม่จำกัด · คำตอบส่งก่อน',
  });
  String get premiumCollectionPostmasterBullet2 => _t({
    'ko': '공식 발송인 배지 · SNS 링크 첨부',
    'en': 'Official Sender badge · attach your SNS link',
    'ja': '公式発送人バッジ · SNSリンク添付',
    'zh': '官方寄件人徽章 · SNS 链接附加',
    'fr': 'Badge Postmaster · lien SNS joint',
    'de': 'Postmaster-Abzeichen · SNS-Link anhängen',
    'es': 'Insignia de remitente oficial · enlace SNS',
    'pt': 'Selo de remetente oficial · link SNS',
    'ru': 'Значок официального отправителя · ссылка SNS',
    'tr': 'Resmi gönderici rozeti · SNS bağlantısı',
    'ar': 'شارة المرسل الرسمي · رابط التواصل الاجتماعي',
    'it': 'Badge mittente ufficiale · link SNS',
    'hi': 'आधिकारिक प्रेषक बैज · SNS लिंक',
    'th': 'ตราผู้ส่งทางการ · แนบลิงก์ SNS',
  });
  String get weeklyReflectionTitle => _t({
    'ko': '이번 주의 회고',
    'en': 'This Week in Rewards',
    'ja': '今週のふりかえり',
    'zh': '本周回顾',
    'fr': 'La semaine en lettres',
    'de': 'Diese Woche in Briefen',
    'es': 'Esta semana en cartas',
    'pt': 'Esta semana em cartas',
    'ru': 'Неделя в письмах',
    'tr': 'Mektuplarla bu hafta',
    'ar': 'هذا الأسبوع في الرسائل',
    'it': 'La settimana in lettere',
    'hi': 'इस हफ़्ते के पत्र',
    'th': 'สัปดาห์นี้ในจดหมาย',
  });

  String weeklyReflectionSummary(int letters, int countries, int continents) {
    switch (languageCode) {
      case 'ko':
        return '이번 주 당신의 홍보 $letters통이 $countries개 나라·$continents개 대륙으로 떠났어요 🌍';
      case 'ja':
        return '今週、あなたの手紙$letters通が$countriesヶ国・$continents大陸へと旅立ちました 🌍';
      case 'zh':
        return '本周你的 $letters 封信飞往了 $countries 个国家 · $continents 个大洲 🌍';
      case 'fr':
        return 'Cette semaine, $letters de vos lettres sont parties vers $countries pays et $continents continents 🌍';
      case 'de':
        return 'Diese Woche reisten $letters Briefe in $countries Länder auf $continents Kontinenten 🌍';
      case 'es':
        return 'Esta semana, $letters cartas tuyas partieron a $countries países · $continents continentes 🌍';
      case 'pt':
        return 'Esta semana, $letters cartas suas partiram para $countries países · $continents continentes 🌍';
      case 'ru':
        return 'На этой неделе $letters ваших писем ушли в $countries стран · $continents континентов 🌍';
      case 'tr':
        return 'Bu hafta $letters mektubunuz $countries ülkeye · $continents kıtaya gitti 🌍';
      case 'ar':
        return 'هذا الأسبوع، $letters من رسائلك سافرت إلى $countries دولة · $continents قارة 🌍';
      case 'it':
        return 'Questa settimana $letters tue lettere sono partite verso $countries paesi · $continents continenti 🌍';
      case 'hi':
        return 'इस हफ़्ते आपके $letters पत्र $countries देशों · $continents महाद्वीपों को गए 🌍';
      case 'th':
        return 'สัปดาห์นี้ จดหมาย $letters ฉบับของคุณเดินทางไปยัง $countries ประเทศ · $continents ทวีป 🌍';
      case 'en':
      default:
        return 'This week, $letters of your letters traveled to $countries countries across $continents continents 🌍';
    }
  }

  String weeklyReflectionLongest(int km) {
    switch (languageCode) {
      case 'ko': return '가장 멀리 떠난 혜택은 ${km}km를 여행했어요 ✈️';
      case 'ja': return '最も遠く旅した手紙は${km}kmを旅しました ✈️';
      case 'zh': return '最远的那封信旅行了 ${km} 公里 ✈️';
      case 'fr': return 'Votre lettre la plus lointaine a parcouru ${km} km ✈️';
      case 'de': return 'Der weiteste Brief reiste ${km} km ✈️';
      case 'es': return 'La carta más lejana viajó ${km} km ✈️';
      case 'pt': return 'A carta mais distante viajou ${km} km ✈️';
      case 'ru': return 'Самое дальнее письмо преодолело ${km} км ✈️';
      case 'tr': return 'En uzun yolculuk ${km} km oldu ✈️';
      case 'ar': return 'أبعد رسالة سافرت ${km} كم ✈️';
      case 'it': return 'La lettera più lontana ha percorso ${km} km ✈️';
      case 'hi': return 'सबसे दूर गया पत्र ${km} किमी चला ✈️';
      case 'th': return 'จดหมายที่ไปไกลที่สุดเดินทาง ${km} กม. ✈️';
      case 'en':
      default: return 'Your farthest letter traveled ${km} km ✈️';
    }
  }

  String get replyAlreadyNotice => _t({
    'ko': '이 이미 답장을 보냈어요 · 한 한 번만 답장할 수 있어요',
    'en': 'You\'ve already replied to this reward — one reply per reward',
    'ja': 'この手紙にはすでに返信済みです — 1通につき1回のみ',
    'zh': '你已经回复过这封信 · 每封信只能回复一次',
    'fr': 'Vous avez déjà répondu à cette lettre — une réponse par lettre',
    'de': 'Du hast auf diesen Brief bereits geantwortet — eine Antwort pro Brief',
    'es': 'Ya respondiste a esta carta — una respuesta por carta',
    'pt': 'Você já respondeu a esta carta — uma resposta por carta',
    'ru': 'Вы уже ответили на это письмо — один ответ на письмо',
    'tr': 'Bu mektuba zaten cevap verdin — mektup başına bir cevap',
    'ar': 'لقد رددت على هذه الرسالة مسبقاً — رد واحد لكل رسالة',
    'it': 'Hai già risposto a questa lettera — una risposta per lettera',
    'hi': 'आप इस पत्र का पहले ही जवाब दे चुके हैं — एक पत्र, एक जवाब',
    'th': 'คุณตอบจดหมายฉบับนี้ไปแล้ว · ตอบได้ครั้งเดียวต่อจดหมาย',
  });
  String get replyOnePerLetterTip => _t({
    'ko': '한 한 번만 답장할 수 있어요',
    'en': 'One reply per reward',
    'ja': '1通につき1回のみ返信できます',
    'zh': '每封信只能回复一次',
    'fr': 'Une seule réponse par lettre',
    'de': 'Eine Antwort pro Brief',
    'es': 'Una respuesta por carta',
    'pt': 'Uma resposta por carta',
    'ru': 'Один ответ на письмо',
    'tr': 'Mektup başına bir cevap',
    'ar': 'رد واحد لكل رسالة',
    'it': 'Una risposta per lettera',
    'hi': 'एक पत्र, एक जवाब',
    'th': 'ตอบได้ครั้งเดียวต่อจดหมาย',
  });
  String get labelAiCurated => _t({
    'ko': '문학 봇',
    'en': 'CURATED',
    'ja': '文学Bot',
    'zh': '文学机器人',
    'fr': 'CURATION',
    'de': 'KURATIERT',
    'es': 'CURADO',
    'pt': 'CURADO',
    'ru': 'АВТОР-БОТ',
    'tr': 'SEÇİLMİŞ',
    'ar': 'منتقاة',
    'it': 'SELEZIONATA',
    'hi': 'क्यूरेटेड',
    'th': 'บอตวรรณกรรม',
  });
  String get aiLetterNoticeTitle => _t({
    'ko': '창작 혜택이에요',
    'en': 'A curated reward',
    'ja': '創作の手紙です',
    'zh': '这是一封创作信件',
    'fr': 'Une lettre de curation',
    'de': 'Ein kuratierter Brief',
    'es': 'Una carta curada',
    'pt': 'Uma carta curada',
    'ru': 'Письмо-миниатюра',
    'tr': 'Seçilmiş bir mektup',
    'ar': 'رسالة منتقاة',
    'it': 'Una lettera selezionata',
    'hi': 'एक क्यूरेटेड पत्र',
    'th': 'จดหมายคัดสรร',
  });
  String get aiLetterNoticeBody => _t({
    'ko': '실제 사람이 아닌 문학 봇이 보낸 메시지라, 답장은 전달되지 않아요. 다른 답장해보세요.',
    'en': 'This reward message was written by a literary bot, so replies won\'t reach anyone. Try replying to a real reward instead.',
    'ja': '文学Botが書いた手紙なので、返信は届きません。他の手紙に返信してみてください。',
    'zh': '这封信由文学机器人撰写，回复不会被送达。可以回复其他信件。',
    'fr': 'Cette lettre vient d\'un bot littéraire — les réponses n\'atteindront personne. Répondez plutôt à une vraie lettre.',
    'de': 'Dieser Brief kommt von einem Literatur-Bot — Antworten erreichen niemanden. Beantworte lieber einen echten Brief.',
    'es': 'Esta carta la escribió un bot literario, así que las respuestas no llegan a nadie. Responde a una carta real.',
    'pt': 'Esta carta veio de um bot literário — respostas não chegam a ninguém. Responda a uma carta real.',
    'ru': 'Это письмо написал литературный бот, поэтому ответы никуда не дойдут. Ответьте на реальное письмо.',
    'tr': 'Bu mektup bir edebiyat botundan — cevaplar kimseye ulaşmaz. Gerçek bir mektuba cevap verin.',
    'ar': 'كُتبت هذه الرسالة بواسطة بوت أدبي، لذا لن تصل الردود. جرب الرد على رسالة حقيقية.',
    'it': 'Questa lettera viene da un bot letterario — le risposte non arrivano a nessuno. Rispondi a una lettera reale.',
    'hi': 'यह पत्र एक साहित्यिक बॉट ने लिखा है, जवाब किसी तक नहीं पहुँचेंगे। असली पत्र का जवाब दें।',
    'th': 'จดหมายนี้เขียนโดยบอตวรรณกรรม คำตอบจะไม่ถึงใคร ลองตอบจดหมายจริงแทน',
  });
  String get replyFomoHint => _t({
    'ko': '이 사람은 당신의 답을 기다리고 있을지 몰라요',
    'en': 'Someone, somewhere, may be waiting for your reply',
    'ja': 'この人はあなたの返事を待っているかもしれません',
    'zh': '这个人也许正在等待你的回信',
    'fr': 'Cette personne attend peut-être votre réponse',
    'de': 'Jemand wartet vielleicht gerade auf deine Antwort',
    'es': 'Alguien podría estar esperando tu respuesta',
    'pt': 'Alguém pode estar esperando sua resposta',
    'ru': 'Возможно, кто-то ждёт вашего ответа',
    'tr': 'Biri cevabını bekliyor olabilir',
    'ar': 'ربما ينتظر هذا الشخص ردك',
    'it': 'Qualcuno potrebbe star aspettando la tua risposta',
    'hi': 'शायद कोई आपकी प्रतिक्रिया का इंतज़ार कर रहा है',
    'th': 'อาจมีใครบางคนกำลังรอคำตอบของคุณ',
  });
  String get reminderPrepromptTitle => _t({
    'ko': '매일 아침 8시에 알려드릴까요?',
    'en': 'Nudge at 8 AM every morning?',
    'ja': '毎朝8時にお知らせしますか？',
    'zh': '每天早上 8 点温柔提醒你？',
    'fr': 'Un rappel tous les jours à 8h ?',
    'de': 'Jeden Morgen um 8 Uhr erinnern?',
    'es': '¿Aviso suave a las 8 cada mañana?',
    'pt': 'Lembrete todos os dias às 8h?',
    'ru': 'Напоминать каждое утро в 8:00?',
    'tr': 'Her sabah 8\'de hatırlatalım mı?',
    'ar': 'تذكير كل صباح الساعة 8؟',
    'it': 'Promemoria ogni mattina alle 8?',
    'hi': 'हर सुबह 8 बजे याद दिलाएँ?',
    'th': 'เตือนทุกเช้าเวลา 8 โมง?',
  });
  String get reminderPrepromptBody => _t({
    'ko': '"오늘 나에게 혜택이 왔을까?"\n매일 아침 8시에 수집첩을 열어보도록 조용히 알려드릴게요.',
    'en': '"Did a reward arrive for me today?"\nA quiet 8 AM nudge to open your mailbox — nothing noisy.',
    'ja': '「今日、手紙は届いたかな？」\n毎朝8時に、そっと手紙箱を開くようお知らせします。',
    'zh': '"今天有我的信吗？"\n每天早上 8 点轻轻提醒你打开信箱——不喧哗。',
    'fr': '"Ai-je reçu une lettre aujourd\'hui ?"\nUn rappel doux à 8h pour ouvrir votre boîte.',
    'de': '"Ist heute ein Brief für mich da?"\nEin leiser 8-Uhr-Hinweis, den Briefkasten zu öffnen.',
    'es': '"¿Hoy me ha llegado una carta?"\nUn aviso suave a las 8 para abrir tu buzón.',
    'pt': '"Chegou uma carta pra mim hoje?"\nUm lembrete sutil às 8h para abrir sua caixa.',
    'ru': '"Пришло ли мне сегодня письмо?"\nЛёгкое напоминание в 8 утра открыть почтовый ящик.',
    'tr': '"Bugün bana mektup geldi mi?"\nSabah 8\'de posta kutunu açman için sakin bir hatırlatma.',
    'ar': '"هل وصلتني رسالة اليوم؟"\nتذكير هادئ الساعة 8 صباحاً لتفتح صندوق رسائلك.',
    'it': '"Mi è arrivata una lettera oggi?"\nUn promemoria gentile alle 8 per aprire la tua buca.',
    'hi': '"क्या आज मेरे लिए पत्र आया?"\nसुबह 8 बजे मेलबॉक्स खोलने की शांत याद।',
    'th': '"วันนี้มีจดหมายถึงฉันไหม?"\nการเตือนเบา ๆ เวลา 8 โมงให้เปิดกล่องจดหมาย',
  });
  String get reminderPrepromptYes => _t({
    'ko': '좋아요',
    'en': "Yes, please",
    'ja': 'はい',
    'zh': '好的',
    'fr': "D'accord",
    'de': 'Gerne',
    'es': 'Sí, por favor',
    'pt': 'Sim, por favor',
    'ru': 'Давайте',
    'tr': 'Evet, lütfen',
    'ar': 'نعم',
    'it': 'Sì, grazie',
    'hi': 'हाँ',
    'th': 'ดีเลย',
  });
  String get reminderPrepromptLater => _t({
    'ko': '나중에',
    'en': 'Maybe later',
    'ja': 'あとで',
    'zh': '以后再说',
    'fr': 'Plus tard',
    'de': 'Später',
    'es': 'Quizás después',
    'pt': 'Talvez depois',
    'ru': 'Позже',
    'tr': 'Sonra',
    'ar': 'لاحقاً',
    'it': 'Più tardi',
    'hi': 'बाद में',
    'th': 'ไว้ทีหลัง',
  });
  String get pushModeLabel => _t({
    'ko': '푸시 알림 수준',
    'en': 'Notification Volume',
    'ja': 'プッシュ通知のレベル',
    'zh': '推送通知级别',
    'fr': 'Niveau des notifications',
    'de': 'Benachrichtigungs-Level',
    'es': 'Nivel de notificaciones',
    'pt': 'Nível de notificações',
    'ru': 'Уровень уведомлений',
    'tr': 'Bildirim düzeyi',
    'ar': 'مستوى الإشعارات',
    'it': 'Livello notifiche',
    'hi': 'सूचना स्तर',
    'th': 'ระดับการแจ้งเตือน',
  });
  String get pushModeQuiet => _t({
    'ko': '조용히',
    'en': 'Quiet',
    'ja': '静か',
    'zh': '安静',
    'fr': 'Discret',
    'de': 'Leise',
    'es': 'Silencio',
    'pt': 'Silencioso',
    'ru': 'Тихо',
    'tr': 'Sessiz',
    'ar': 'هادئ',
    'it': 'Silenzioso',
    'hi': 'शांत',
    'th': 'เงียบ',
  });
  String get pushModeStandard => _t({
    'ko': '기본',
    'en': 'Standard',
    'ja': '標準',
    'zh': '标准',
    'fr': 'Standard',
    'de': 'Standard',
    'es': 'Estándar',
    'pt': 'Padrão',
    'ru': 'Обычный',
    'tr': 'Standart',
    'ar': 'افتراضي',
    'it': 'Standard',
    'hi': 'सामान्य',
    'th': 'มาตรฐาน',
  });
  String get pushModeFull => _t({
    'ko': '전체',
    'en': 'Everything',
    'ja': '全て',
    'zh': '全部',
    'fr': 'Tout',
    'de': 'Alle',
    'es': 'Todo',
    'pt': 'Tudo',
    'ru': 'Всё',
    'tr': 'Hepsi',
    'ar': 'الكل',
    'it': 'Tutto',
    'hi': 'सब',
    'th': 'ทั้งหมด',
  });
  String get pushModeQuietDesc => _t({
    'ko': '하루 1번의 아침 리마인더만 받아요',
    'en': 'Only the once-a-day morning nudge',
    'ja': '朝のリマインダーのみ（1日1回）',
    'zh': '仅每天清晨一次提醒',
    'fr': "Seulement le rappel matinal (une fois par jour)",
    'de': 'Nur der morgendliche Hinweis (1 × pro Tag)',
    'es': 'Solo el recordatorio matutino (una vez al día)',
    'pt': 'Apenas o lembrete matinal (uma vez por dia)',
    'ru': 'Только утреннее напоминание (раз в день)',
    'tr': 'Yalnızca sabah hatırlatıcısı (günde 1 kez)',
    'ar': 'فقط تذكير الصباح (مرة واحدة يومياً)',
    'it': 'Solo il promemoria mattutino (una volta al giorno)',
    'hi': 'केवल सुबह की याद (दिन में एक बार)',
    'th': 'แค่การเตือนเช้า (วันละ 1 ครั้ง)',
  });
  String get pushModeStandardDesc => _t({
    'ko': '혜택 도착·DM·아침 리마인더',
    'en': 'Arrivals, DMs, and the daily nudge',
    'ja': '到着・DM・朝のリマインダー',
    'zh': '信件到达·私信·清晨提醒',
    'fr': 'Arrivées, messages et rappel quotidien',
    'de': 'Ankünfte, DMs und tägliche Erinnerung',
    'es': 'Llegadas, DMs y recordatorio diario',
    'pt': 'Chegadas, DMs e lembrete diário',
    'ru': 'Приходы, сообщения и утреннее напоминание',
    'tr': 'Varışlar, DM\'ler ve günlük hatırlatma',
    'ar': 'الوصول، الرسائل، والتذكير اليومي',
    'it': 'Arrivi, DM e promemoria quotidiano',
    'hi': 'पत्र आगमन, DM, दैनिक याद',
    'th': 'การมาถึง, DM, การเตือนรายวัน',
  });
  String get pushModeFullDesc => _t({
    'ko': '근처 도착·쿨다운·카운트다운까지 전부',
    'en': 'All alerts, including nearby and cooldown',
    'ja': '近く・クールダウン・カウントダウンも含む全て',
    'zh': '包括附近、冷却、倒计时的所有提醒',
    'fr': 'Toutes les alertes (proximité, délai, compte à rebours)',
    'de': 'Alle Benachrichtigungen (inkl. Umgebung und Cooldown)',
    'es': 'Todas las alertas (cercanas, enfriamiento, cuenta atrás)',
    'pt': 'Todos os alertas (proximidade, espera, contagem)',
    'ru': 'Все уведомления (рядом, перезарядка, обратный отсчёт)',
    'tr': 'Tüm bildirimler (yakın, bekleme, geri sayım)',
    'ar': 'كل التنبيهات (القريبة، الانتظار، العد التنازلي)',
    'it': 'Tutte le notifiche (vicinanze, attesa, countdown)',
    'hi': 'सभी अलर्ट (पास, कूलडाउन, काउंटडाउन)',
    'th': 'การแจ้งเตือนทั้งหมด (ใกล้เคียง, คูลดาวน์, นับถอยหลัง)',
  });
  String get settingsNotifyDaily => _t({
    'ko': '오늘의 혜택 리마인더',
    'en': "Today's Reward Reminder",
    'ja': '今日の手紙リマインダー',
    'zh': '今日信件提醒',
    'fr': 'Rappel des lettres du jour',
    'de': 'Tägliche Brief-Erinnerung',
    'es': 'Recordatorio de cartas de hoy',
    'pt': 'Lembrete das cartas de hoje',
    'ru': 'Напоминание о сегодняшних письмах',
    'tr': 'Bugünkü mektup hatırlatıcısı',
    'ar': 'تذكير برسائل اليوم',
    'it': 'Promemoria lettere di oggi',
    'hi': 'आज के पत्र की याद',
    'th': 'การเตือนจดหมายวันนี้',
  });
  String get settingsNotifyDailyDesc => _t({
    'ko': '매일 오전 8시에 수집첩을 열어보도록 알려드려요',
    'en': 'A gentle 8:00 AM nudge to check your mailbox',
    'ja': '毎朝8時に手紙を確認するようお知らせします',
    'zh': '每天早上 8 点温柔提醒你查看信箱',
    'fr': 'Un rappel doux à 8h00 pour ouvrir votre boîte',
    'de': 'Ein sanfter Hinweis um 8:00 Uhr, den Briefkasten zu öffnen',
    'es': 'Un suave aviso a las 8:00 para revisar tu buzón',
    'pt': 'Um lembrete gentil às 8h para abrir sua caixa de cartas',
    'ru': 'Лёгкое напоминание в 8:00 открыть почтовый ящик',
    'tr': 'Sabah 8\'de posta kutunuza bakmanız için nazik bir hatırlatma',
    'ar': 'تذكير لطيف الساعة 8:00 صباحاً لفتح صندوق رسائلك',
    'it': 'Un gentile promemoria alle 8:00 per aprire la tua buca',
    'hi': 'सुबह 8 बजे मेलबॉक्स खोलने की कोमल याद',
    'th': 'การเตือนเบา ๆ เวลา 8:00 น. ให้เปิดกล่องจดหมาย',
  });
  String get settingsLogout => _t({
    'ko': '로그아웃',
    'en': 'Logout',
    'ja': 'ログアウト',
    'zh': '退出登录',
    'fr': 'Déconnexion',
    'de': 'Abmelden',
    'es': 'Cerrar sesión',
    'pt': 'Sair',
    'ru': 'Выйти',
    'tr': 'Çıkış yap',
    'ar': 'تسجيل الخروج',
    'it': 'Disconnetti',
    'hi': 'लॉगआउट',
    'th': 'ออกจากระบบ',
  });
  String get settingsLogoutConfirm => _t({
    'ko': '로그아웃 하시겠어요?',
    'en': 'Are you sure you want to logout?',
    'ja': 'ログアウトしますか？',
    'zh': '确定要退出登录吗？',
    'fr': 'Voulez-vous vraiment vous déconnecter ?',
    'de': 'Möchten Sie sich wirklich abmelden?',
    'es': '¿Seguro que quieres cerrar sesión?',
    'pt': 'Tem certeza que deseja sair?',
    'ru': 'Вы уверены, что хотите выйти?',
    'tr': 'Çıkış yapmak istediğinizden emin misiniz?',
    'ar': 'هل أنت متأكد من تسجيل الخروج؟',
    'it': 'Sei sicuro di voler disconnetterti?',
    'hi': 'क्या आप वाकई लॉगआउट करना चाहते हैं?',
    'th': 'คุณแน่ใจว่าต้องการออกจากระบบ?',
  });
  String get settingsWithdraw => _t({
    'ko': '계정 탈퇴',
    'en': 'Delete Account',
    'ja': 'アカウント退会',
    'zh': '注销账户',
    'fr': 'Supprimer le compte',
    'de': 'Konto löschen',
    'es': 'Eliminar cuenta',
    'pt': 'Excluir conta',
    'ru': 'Удалить аккаунт',
    'tr': 'Hesabı sil',
    'ar': 'حذف الحساب',
    'it': 'Elimina account',
    'hi': 'खाता हटाएं',
    'th': 'ลบบัญชี',
  });
  String get settingsWithdrawConfirm => _t({
    'ko': '정말 탈퇴하시겠어요?\n모든 데이터가 삭제됩니다.',
    'en': 'Are you sure?\nAll data will be deleted.',
    'ja': '本当に退会しますか？\nすべてのデータが削除されます。',
    'zh': '确定要注销吗？\n所有数据将被删除。',
    'fr': 'Êtes-vous sûr ?\nToutes les données seront supprimées.',
    'de': 'Sind Sie sicher?\nAlle Daten werden gelöscht.',
    'es': '¿Estás seguro?\nTodos los datos serán eliminados.',
    'pt': 'Tem certeza?\nTodos os dados serão excluídos.',
    'ru': 'Вы уверены?\nВсе данные будут удалены.',
    'tr': 'Emin misiniz?\nTüm veriler silinecek.',
    'ar': 'هل أنت متأكد؟\nسيتم حذف جميع البيانات.',
    'it': 'Sei sicuro?\nTutti i dati verranno eliminati.',
    'hi': 'क्या आप वाकई?\nसभी डेटा हटा दिया जाएगा।',
    'th': 'คุณแน่ใจหรือ?\nข้อมูลทั้งหมดจะถูกลบ',
  });
  String get settingsVersion => _t({
    'ko': '버전',
    'en': 'Version',
    'ja': 'バージョン',
    'zh': '版本',
    'fr': 'Version',
    'de': 'Version',
    'es': 'Versión',
    'pt': 'Versão',
    'ru': 'Версия',
    'tr': 'Sürüm',
    'ar': 'الإصدار',
    'it': 'Versione',
    'hi': 'संस्करण',
    'th': 'เวอร์ชัน',
  });
  String get settingsPrivacy => _t({
    'ko': '개인정보 처리방침',
    'en': 'Privacy Policy',
    'ja': 'プライバシーポリシー',
    'zh': '隐私政策',
    'fr': 'Politique de confidentialité',
    'de': 'Datenschutzrichtlinie',
    'es': 'Política de privacidad',
    'pt': 'Política de privacidade',
    'ru': 'Политика конфиденциальности',
    'tr': 'Gizlilik politikası',
    'ar': 'سياسة الخصوصية',
    'it': 'Informativa sulla privacy',
    'hi': 'गोपनीयता नीति',
    'th': 'นโยบายความเป็นส่วนตัว',
  });
  String get settingsTerms => _t({
    'ko': '서비스 이용약관',
    'en': 'Terms of Service',
    'ja': '利用規約',
    'zh': '服务条款',
    'fr': "Conditions d'utilisation",
    'de': 'Nutzungsbedingungen',
    'es': 'Términos de servicio',
    'pt': 'Termos de serviço',
    'ru': 'Условия использования',
    'tr': 'Kullanım koşulları',
    'ar': 'شروط الخدمة',
    'it': 'Termini di servizio',
    'hi': 'सेवा की शर्तें',
    'th': 'ข้อกำหนดการใช้งาน',
  });
  String get settingsLanguage => _t({
    'ko': '언어',
    'en': 'Language',
    'ja': '言語',
    'zh': '语言',
    'fr': 'Langue',
    'de': 'Sprache',
    'es': 'Idioma',
    'pt': 'Idioma',
    'ru': 'Язык',
    'tr': 'Dil',
    'ar': 'اللغة',
    'it': 'Lingua',
    'hi': 'भाषा',
    'th': 'ภาษา',
  });
  String get settingsPremium => _t({
    'ko': '프리미엄 구독',
    'en': 'Premium Subscription',
    'ja': 'プレミアムサブスクリプション',
    'zh': '高级订阅',
    'fr': 'Abonnement Premium',
    'de': 'Premium-Abonnement',
    'es': 'Suscripción Premium',
    'pt': 'Assinatura Premium',
    'ru': 'Подписка Premium',
    'tr': 'Premium abonelik',
    'ar': 'اشتراك بريميوم',
    'it': 'Abbonamento Premium',
    'hi': 'प्रीमियम सदस्यता',
    'th': 'สมาชิกพรีเมียม',
  });
  String get settingsAccount => _t({
    'ko': '계정',
    'en': 'Account',
    'ja': 'アカウント',
    'zh': '账户',
    'fr': 'Compte',
    'de': 'Konto',
    'es': 'Cuenta',
    'pt': 'Conta',
    'ru': 'Аккаунт',
    'tr': 'Hesap',
    'ar': 'الحساب',
    'it': 'Account',
    'hi': 'खाता',
    'th': 'บัญชี',
  });
  String get settingsNotifications => _t({
    'ko': '알림',
    'en': 'Notifications',
    'ja': '通知',
    'zh': '通知',
    'fr': 'Notifications',
    'de': 'Benachrichtigungen',
    'es': 'Notificaciones',
    'pt': 'Notificações',
    'ru': 'Уведомления',
    'tr': 'Bildirimler',
    'ar': 'الإشعارات',
    'it': 'Notifiche',
    'hi': 'सूचनाएं',
    'th': 'การแจ้งเตือน',
  });

  // ── Auth Screen ──────────────────────────────────────────────────────
  String get authTabLogin => _t({
    'ko': '🔑  로그인',
    'en': '🔑  Login',
    'ja': '🔑  ログイン',
    'zh': '🔑  登录',
    'fr': '🔑  Connexion',
    'de': '🔑  Anmelden',
    'es': '🔑  Iniciar sesión',
    'pt': '🔑  Entrar',
    'ru': '🔑  Войти',
    'tr': '🔑  Giriş',
    'ar': '🔑  تسجيل الدخول',
    'it': '🔑  Accedi',
    'hi': '🔑  लॉगिन',
    'th': '🔑  เข้าสู่ระบบ',
  });

  String get authTabSignup => _t({
    'ko': '✨  회원가입',
    'en': '✨  Sign Up',
    'ja': '✨  新規登録',
    'zh': '✨  注册',
    'fr': "✨  S'inscrire",
    'de': '✨  Registrieren',
    'es': '✨  Registrarse',
    'pt': '✨  Cadastrar',
    'ru': '✨  Регистрация',
    'tr': '✨  Üye ol',
    'ar': '✨  إنشاء حساب',
    'it': '✨  Registrati',
    'hi': '✨  साइनअप',
    'th': '✨  สมัครสมาชิก',
  });

  String get authNicknameId => _t({
    'ko': '닉네임(아이디)',
    'en': 'Nickname (ID)',
    'ja': 'ニックネーム（ID）',
    'zh': '昵称（ID）',
    'fr': 'Pseudo (identifiant)',
    'de': 'Nickname (ID)',
    'es': 'Apodo (ID)',
    'pt': 'Apelido (ID)',
    'ru': 'Никнейм (ID)',
    'tr': 'Takma ad (ID)',
    'ar': 'الاسم المستعار (المعرّف)',
    'it': 'Nickname (ID)',
    'hi': 'उपनाम (आईडी)',
    'th': 'ชื่อเล่น (ID)',
  });

  String get authPasswordHint => _t({
    'ko': '6자 이상',
    'en': '6+ characters',
    'ja': '6文字以上',
    'zh': '6个字符以上',
    'fr': '6 caractères minimum',
    'de': 'Mindestens 6 Zeichen',
    'es': '6 o más caracteres',
    'pt': '6 ou mais caracteres',
    'ru': 'Не менее 6 символов',
    'tr': '6 veya daha fazla karakter',
    'ar': '6 أحرف أو أكثر',
    'it': '6 o più caratteri',
    'hi': '6 या अधिक अक्षर',
    'th': '6 ตัวอักษรขึ้นไป',
  });

  String get authRememberMe => _t({
    'ko': '아이디 · 비밀번호 기억하기',
    'en': 'Remember ID & password',
    'ja': 'IDとパスワードを記憶',
    'zh': '记住ID和密码',
    'fr': 'Se souvenir de l\'identifiant et du mot de passe',
    'de': 'ID & Passwort merken',
    'es': 'Recordar ID y contraseña',
    'pt': 'Lembrar ID e senha',
    'ru': 'Запомнить ID и пароль',
    'tr': 'ID ve şifreyi hatırla',
    'ar': 'تذكر المعرّف وكلمة المرور',
    'it': 'Ricorda ID e password',
    'hi': 'आईडी और पासवर्ड याद रखें',
    'th': 'จดจำ ID และรหัสผ่าน',
  });

  String get authNewUserHint => _t({
    'ko': '처음이신가요? 회원가입 탭에서 계정을 만들어보세요.',
    'en': 'New here? Create an account in the Sign Up tab.',
    'ja': '初めてですか？新規登録タブでアカウントを作成しましょう。',
    'zh': '第一次来？在注册标签页中创建账号。',
    'fr': 'Nouveau ? Créez un compte dans l\'onglet Inscription.',
    'de': 'Neu hier? Erstellen Sie ein Konto im Registrieren-Tab.',
    'es': '¿Nuevo aquí? Crea una cuenta en la pestaña de registro.',
    'pt': 'Novo aqui? Crie uma conta na aba Cadastrar.',
    'ru': 'Впервые здесь? Создайте аккаунт во вкладке Регистрация.',
    'tr': 'Yeni misiniz? Üye ol sekmesinden hesap oluşturun.',
    'ar': 'جديد هنا؟ أنشئ حساباً في علامة تبويب التسجيل.',
    'it': 'Nuovo qui? Crea un account nella scheda Registrati.',
    'hi': 'पहली बार यहाँ? साइनअप टैब में खाता बनाएं।',
    'th': 'ใหม่ที่นี่? สร้างบัญชีในแท็บสมัครสมาชิก',
  });

  String get authFindIdDesc => _t({
    'ko': '가입 시 등록한 이메일을 입력하면\n아이디와 임시 비밀번호를 발급해 드립니다.',
    'en': 'Enter the email you registered with\nto receive your ID and a temporary password.',
    'ja': '登録時のメールアドレスを入力すると\nIDと仮パスワードを発行します。',
    'zh': '输入注册时的邮箱\n我们将提供您的ID和临时密码。',
    'fr': 'Entrez l\'email utilisé lors de l\'inscription\npour recevoir votre identifiant et un mot de passe temporaire.',
    'de': 'Geben Sie die bei der Registrierung verwendete E-Mail ein,\num Ihre ID und ein temporäres Passwort zu erhalten.',
    'es': 'Ingresa el correo registrado\npara recibir tu ID y una contraseña temporal.',
    'pt': 'Insira o email cadastrado\npara receber seu ID e uma senha temporária.',
    'ru': 'Введите email, указанный при регистрации,\nчтобы получить ваш ID и временный пароль.',
    'tr': 'Kayıt sırasında kullandığınız e-postayı girin,\nID ve geçici şifrenizi alın.',
    'ar': 'أدخل البريد الإلكتروني المسجل\nللحصول على معرّفك وكلمة مرور مؤقتة.',
    'it': 'Inserisci l\'email registrata\nper ricevere il tuo ID e una password temporanea.',
    'hi': 'पंजीकरण के समय दर्ज किया गया ईमेल डालें\nआपको ID और अस्थायी पासवर्ड मिलेगा।',
    'th': 'กรอกอีเมลที่ลงทะเบียนไว้\nเพื่อรับ ID และรหัสผ่านชั่วคราว',
  });

  String get authRegisteredEmail => _t({
    'ko': '가입 이메일',
    'en': 'Registered email',
    'ja': '登録メール',
    'zh': '注册邮箱',
    'fr': 'Email d\'inscription',
    'de': 'Registrierte E-Mail',
    'es': 'Correo registrado',
    'pt': 'Email cadastrado',
    'ru': 'Email регистрации',
    'tr': 'Kayıtlı e-posta',
    'ar': 'البريد الإلكتروني المسجل',
    'it': 'Email registrata',
    'hi': 'पंजीकृत ईमेल',
    'th': 'อีเมลที่ลงทะเบียน',
  });

  String get authCancel => _t({
    'ko': '취소',
    'en': 'Cancel',
    'ja': 'キャンセル',
    'zh': '取消',
    'fr': 'Annuler',
    'de': 'Abbrechen',
    'es': 'Cancelar',
    'pt': 'Cancelar',
    'ru': 'Отмена',
    'tr': 'İptal',
    'ar': 'إلغاء',
    'it': 'Annulla',
    'hi': 'रद्द करें',
    'th': 'ยกเลิก',
  });

  String get authFindFailed => _t({
    'ko': '찾기 실패',
    'en': 'Lookup Failed',
    'ja': '検索失敗',
    'zh': '查找失败',
    'fr': 'Recherche échouée',
    'de': 'Suche fehlgeschlagen',
    'es': 'Búsqueda fallida',
    'pt': 'Busca falhou',
    'ru': 'Поиск не удался',
    'tr': 'Arama başarısız',
    'ar': 'فشل البحث',
    'it': 'Ricerca fallita',
    'hi': 'खोज विफल',
    'th': 'ค้นหาไม่สำเร็จ',
  });

  String get authNoAccountForEmail => _t({
    'ko': '해당 이메일로 가입된 계정을 찾을 수 없습니다.',
    'en': 'No account found for this email.',
    'ja': 'このメールアドレスで登録されたアカウントが見つかりません。',
    'zh': '未找到与此邮箱关联的账号。',
    'fr': 'Aucun compte trouvé pour cet email.',
    'de': 'Kein Konto für diese E-Mail gefunden.',
    'es': 'No se encontró una cuenta con este correo.',
    'pt': 'Nenhuma conta encontrada para este email.',
    'ru': 'Аккаунт с этим email не найден.',
    'tr': 'Bu e-posta ile kayıtlı hesap bulunamadı.',
    'ar': 'لم يتم العثور على حساب بهذا البريد الإلكتروني.',
    'it': 'Nessun account trovato per questa email.',
    'hi': 'इस ईमेल के लिए कोई खाता नहीं मिला।',
    'th': 'ไม่พบบัญชีสำหรับอีเมลนี้',
  });

  String get authConfirm => _t({
    'ko': '확인',
    'en': 'OK',
    'ja': '確認',
    'zh': '确认',
    'fr': 'OK',
    'de': 'OK',
    'es': 'Aceptar',
    'pt': 'OK',
    'ru': 'ОК',
    'tr': 'Tamam',
    'ar': 'موافق',
    'it': 'OK',
    'hi': 'ठीक है',
    'th': 'ตกลง',
  });

  String get authAccountInfo => _t({
    'ko': '계정 정보 확인',
    'en': 'Account Information',
    'ja': 'アカウント情報確認',
    'zh': '账号信息确认',
    'fr': 'Informations du compte',
    'de': 'Kontoinformationen',
    'es': 'Información de la cuenta',
    'pt': 'Informações da conta',
    'ru': 'Информация об аккаунте',
    'tr': 'Hesap bilgileri',
    'ar': 'معلومات الحساب',
    'it': 'Informazioni account',
    'hi': 'खाता जानकारी',
    'th': 'ข้อมูลบัญชี',
  });

  String get authId => _t({
    'ko': '아이디',
    'en': 'ID',
    'ja': 'ID',
    'zh': 'ID',
    'fr': 'Identifiant',
    'de': 'ID',
    'es': 'ID',
    'pt': 'ID',
    'ru': 'ID',
    'tr': 'ID',
    'ar': 'المعرّف',
    'it': 'ID',
    'hi': 'आईडी',
    'th': 'ID',
  });

  String get authPasswordResetDone => _t({
    'ko': '비밀번호 재설정 완료',
    'en': 'Password Reset Complete',
    'ja': 'パスワード再設定完了',
    'zh': '密码重置完成',
    'fr': 'Réinitialisation du mot de passe terminée',
    'de': 'Passwort-Zurücksetzung abgeschlossen',
    'es': 'Restablecimiento de contraseña completado',
    'pt': 'Redefinição de senha concluída',
    'ru': 'Сброс пароля завершён',
    'tr': 'Şifre sıfırlama tamamlandı',
    'ar': 'تمت إعادة تعيين كلمة المرور',
    'it': 'Reimpostazione password completata',
    'hi': 'पासवर्ड रीसेट पूरा हुआ',
    'th': 'รีเซ็ตรหัสผ่านเสร็จสิ้น',
  });

  String get authTempPasswordHidden => _t({
    'ko': '보안을 위해 임시 비밀번호는 화면에 표시되지 않습니다.',
    'en': 'For security, the temporary password is not displayed on screen.',
    'ja': 'セキュリティのため、仮パスワードは画面に表示されません。',
    'zh': '出于安全考虑，临时密码不会显示在屏幕上。',
    'fr': 'Pour des raisons de sécurité, le mot de passe temporaire n\'est pas affiché.',
    'de': 'Aus Sicherheitsgründen wird das temporäre Passwort nicht angezeigt.',
    'es': 'Por seguridad, la contraseña temporal no se muestra en pantalla.',
    'pt': 'Por segurança, a senha temporária não é exibida na tela.',
    'ru': 'В целях безопасности временный пароль не отображается на экране.',
    'tr': 'Güvenlik nedeniyle geçici şifre ekranda gösterilmez.',
    'ar': 'لأسباب أمنية، لا يتم عرض كلمة المرور المؤقتة على الشاشة.',
    'it': 'Per sicurezza, la password temporanea non viene mostrata sullo schermo.',
    'hi': 'सुरक्षा के लिए, अस्थायी पासवर्ड स्क्रीन पर नहीं दिखाया जाता।',
    'th': 'เพื่อความปลอดภัย รหัสผ่านชั่วคราวจะไม่แสดงบนหน้าจอ',
  });

  String authTempPasswordExpiry(dynamic minutes) => _t({
    'ko': '$minutes분 후 만료 · 로그인 후 반드시 변경해주세요',
    'en': 'Expires in $minutes min · Please change after login',
    'ja': '${minutes}分後に期限切れ · ログイン後に必ず変更してください',
    'zh': '${minutes}分钟后过期 · 登录后请务必修改',
    'fr': 'Expire dans $minutes min · Veuillez changer après connexion',
    'de': 'Läuft in $minutes Min. ab · Bitte nach dem Login ändern',
    'es': 'Expira en $minutes min · Cambie después de iniciar sesión',
    'pt': 'Expira em $minutes min · Altere após o login',
    'ru': 'Истекает через $minutes мин · Измените после входа',
    'tr': '$minutes dk sonra sona erer · Giriş sonrası değiştirin',
    'ar': 'تنتهي الصلاحية بعد $minutes دقيقة · يرجى التغيير بعد تسجيل الدخول',
    'it': 'Scade in $minutes min · Cambia dopo il login',
    'hi': '$minutes मिनट बाद समाप्त · लॉगिन के बाद बदलें',
    'th': 'หมดอายุใน $minutes นาที · กรุณาเปลี่ยนหลังเข้าสู่ระบบ',
  });

  String get authFind => _t({
    'ko': '찾기',
    'en': 'Find',
    'ja': '検索',
    'zh': '查找',
    'fr': 'Rechercher',
    'de': 'Suchen',
    'es': 'Buscar',
    'pt': 'Buscar',
    'ru': 'Найти',
    'tr': 'Bul',
    'ar': 'بحث',
    'it': 'Cerca',
    'hi': 'खोजें',
    'th': 'ค้นหา',
  });

  String get authResetPasswordDesc => _t({
    'ko': '닉네임과 가입 이메일을 입력하면 임시 비밀번호를 발급합니다.',
    'en': 'Enter your nickname and registered email to receive a temporary password.',
    'ja': 'ニックネームと登録メールを入力すると、仮パスワードを発行します。',
    'zh': '输入昵称和注册邮箱即可获取临时密码。',
    'fr': 'Entrez votre pseudo et email d\'inscription pour recevoir un mot de passe temporaire.',
    'de': 'Geben Sie Ihren Nickname und die registrierte E-Mail ein, um ein temporäres Passwort zu erhalten.',
    'es': 'Ingresa tu apodo y correo registrado para recibir una contraseña temporal.',
    'pt': 'Insira seu apelido e email cadastrado para receber uma senha temporária.',
    'ru': 'Введите никнейм и email для получения временного пароля.',
    'tr': 'Takma adınızı ve kayıtlı e-postanızı girin, geçici şifre gönderilecektir.',
    'ar': 'أدخل اسمك المستعار والبريد الإلكتروني المسجل للحصول على كلمة مرور مؤقتة.',
    'it': 'Inserisci il tuo nickname e l\'email registrata per ricevere una password temporanea.',
    'hi': 'अस्थायी पासवर्ड पाने के लिए अपना उपनाम और पंजीकृत ईमेल दर्ज करें।',
    'th': 'กรอกชื่อเล่นและอีเมลที่ลงทะเบียนเพื่อรับรหัสผ่านชั่วคราว',
  });

  String get authRegisteredEmailRequired => _t({
    'ko': '가입 이메일 (필수)',
    'en': 'Registered email (required)',
    'ja': '登録メール（必須）',
    'zh': '注册邮箱（必填）',
    'fr': 'Email d\'inscription (obligatoire)',
    'de': 'Registrierte E-Mail (erforderlich)',
    'es': 'Correo registrado (obligatorio)',
    'pt': 'Email cadastrado (obrigatório)',
    'ru': 'Email регистрации (обязательно)',
    'tr': 'Kayıtlı e-posta (zorunlu)',
    'ar': 'البريد الإلكتروني المسجل (مطلوب)',
    'it': 'Email registrata (obbligatoria)',
    'hi': 'पंजीकृत ईमेल (आवश्यक)',
    'th': 'อีเมลที่ลงทะเบียน (จำเป็น)',
  });

  String get authTempPasswordIssued => _t({
    'ko': '임시 비밀번호 발급',
    'en': 'Temporary Password Issued',
    'ja': '仮パスワード発行',
    'zh': '临时密码已发放',
    'fr': 'Mot de passe temporaire émis',
    'de': 'Temporäres Passwort ausgestellt',
    'es': 'Contraseña temporal emitida',
    'pt': 'Senha temporária emitida',
    'ru': 'Временный пароль выдан',
    'tr': 'Geçici şifre verildi',
    'ar': 'تم إصدار كلمة مرور مؤقتة',
    'it': 'Password temporanea emessa',
    'hi': 'अस्थायी पासवर्ड जारी किया गया',
    'th': 'ออกรหัสผ่านชั่ว���ราวแล้ว',
  });

  String get authTempPasswordLabel => _t({
    'ko': '임시 비밀번호',
    'en': 'Temporary password',
    'ja': '仮パスワード',
    'zh': '临时密码',
    'fr': 'Mot de passe temporaire',
    'de': 'Temporäres Passwort',
    'es': 'Contraseña temporal',
    'pt': 'Senha temporária',
    'ru': 'Временный пароль',
    'tr': 'Geçici şifre',
    'ar': 'كلمة مرور مؤقتة',
    'it': 'Password temporanea',
    'hi': 'अस्थायी पासवर्ड',
    'th': 'รหัสผ่านชั่วคราว',
  });

  String authExpiresInMinutes(dynamic minutes) => _t({
    'ko': '$minutes분 후 만료됩니다.',
    'en': 'Expires in $minutes minutes.',
    'ja': '${minutes}分後に期限切れになります。',
    'zh': '${minutes}分钟后过期。',
    'fr': 'Expire dans $minutes minutes.',
    'de': 'Läuft in $minutes Minuten ab.',
    'es': 'Expira en $minutes minutos.',
    'pt': 'Expira em $minutes minutos.',
    'ru': 'Истекает через $minutes минут.',
    'tr': '$minutes dakika sonra sona erer.',
    'ar': 'تنتهي الصلاحية بعد $minutes دقيقة.',
    'it': 'Scade in $minutes minuti.',
    'hi': '$minutes मिनट बाद समाप्त होगा।',
    'th': 'หมดอายุใน $minutes นาที',
  });

  String get authMustChangeAfterLogin => _t({
    'ko': '로그인 후 반드시 변경해주세요.',
    'en': 'Please change it after logging in.',
    'ja': 'ログイン後に必ず変更してください。',
    'zh': '登录后请务必修改。',
    'fr': 'Veuillez le changer après connexion.',
    'de': 'Bitte ändern Sie es nach dem Login.',
    'es': 'Cámbiela después de iniciar sesión.',
    'pt': 'Altere após o login.',
    'ru': 'Обязательно измените после входа.',
    'tr': 'Giriş yaptıktan sonra değiştirin.',
    'ar': 'يرجى تغييرها بعد تسجيل الدخول.',
    'it': 'Cambiala dopo il login.',
    'hi': 'लॉगिन के बाद कृपया बदलें।',
    'th': 'กรุณาเปลี่ยนหลังเข้าสู่ระบบ',
  });

  String get authErrorOccurred => _t({
    'ko': '오류가 발생했습니다.',
    'en': 'An error occurred.',
    'ja': 'エラーが発生しました。',
    'zh': '发生错误。',
    'fr': 'Une erreur est survenue.',
    'de': 'Ein Fehler ist aufgetreten.',
    'es': 'Ocurrió un error.',
    'pt': 'Ocorreu um erro.',
    'ru': 'Произошла ошибка.',
    'tr': 'Bir hata oluştu.',
    'ar': 'حدث خطأ.',
    'it': 'Si è verificato un errore.',
    'hi': 'एक त्रुटि हुई।',
    'th': 'เกิดข้อผิดพลาด',
  });

  String get authIssue => _t({
    'ko': '발급',
    'en': 'Issue',
    'ja': '発行',
    'zh': '发放',
    'fr': 'Émettre',
    'de': 'Ausstellen',
    'es': 'Emitir',
    'pt': 'Emitir',
    'ru': 'Выдать',
    'tr': 'Ver',
    'ar': 'إصدار',
    'it': 'Emetti',
    'hi': 'जारी करें',
    'th': 'ออก',
  });

  String get authMustAgreePrivacy => _t({
    'ko': '개인정보 처리방침에 동의해야 가입할 수 있습니다.',
    'en': 'You must agree to the Privacy Policy to sign up.',
    'ja': 'プライバシーポリシーに同意しないと登録できません。',
    'zh': '您必须同意隐私政策才能注册。',
    'fr': 'Vous devez accepter la politique de confidentialité pour vous inscrire.',
    'de': 'Sie müssen der Datenschutzrichtlinie zustimmen, um sich zu registrieren.',
    'es': 'Debe aceptar la política de privacidad para registrarse.',
    'pt': 'Você deve concordar com a Política de Privacidade para se cadastrar.',
    'ru': 'Для регистрации необходимо согласиться с политикой конфиденциальности.',
    'tr': 'Kaydolmak için Gizlilik Politikasını kabul etmelisiniz.',
    'ar': 'يجب الموافقة على سياسة الخصوصية للتسجيل.',
    'it': 'Devi accettare l\'informativa sulla privacy per registrarti.',
    'hi': 'साइनअप करने के लिए गोपनीयता नीति से सहमत होना आवश्यक है।',
    'th': 'คุณต้องยอมรับนโยบายความเป็นส��วนตัวเพื่อสมัครสมาชิก',
  });

  String get authEnterEmail => _t({
    'ko': '이메일을 입력해주세요.',
    'en': 'Please enter your email.',
    'ja': 'メールアドレスを入力してください。',
    'zh': '请输入邮箱。',
    'fr': 'Veuillez entrer votre email.',
    'de': 'Bitte geben Sie Ihre E-Mail ein.',
    'es': 'Ingrese su correo electrónico.',
    'pt': 'Por favor, insira seu email.',
    'ru': 'Пожалуйста, введите email.',
    'tr': 'Lütfen e-postanızı girin.',
    'ar': 'يرجى إدخال بريدك الإلكتروني.',
    'it': 'Inserisci la tua email.',
    'hi': 'कृपया अपना ईमेल दर्ज करें।',
    'th': 'กรุณากรอกอีเมลของคุณ',
  });

  String get authEmailTaken => _t({
    'ko': '이미 가입된 이메일입니다.',
    'en': 'This email is already registered.',
    'ja': 'このメールアドレスは既に登録されています。',
    'zh': '此邮箱已被注册。',
    'fr': 'Cet email est déjà utilisé.',
    'de': 'Diese E-Mail ist bereits registriert.',
    'es': 'Este correo ya está registrado.',
    'pt': 'Este email já está cadastrado.',
    'ru': 'Этот email уже зарегистрирован.',
    'tr': 'Bu e-posta zaten kayıtlı.',
    'ar': 'هذا البريد الإلكتروني مسجل بالفعل.',
    'it': 'Questa email è già registrata.',
    'hi': 'यह ईमेल पहले से पंजीकृत है।',
    'th': 'อีเมลนี้ถูกลงทะเบียนแล้ว',
  });

  String authOtpRetryLater(int seconds) => _t({
    'ko': '잠시 후 다시 시도해주세요. (${seconds}초 후 재시도 가능)',
    'en': 'Please try again later. (Retry in $seconds seconds)',
    'ja': 'しばらくしてからお試しください。（${seconds}秒後に再試行可能）',
    'zh': '请稍后再试。（${seconds}秒后可重试）',
    'fr': 'Veuillez réessayer plus tard. (Réessai dans $seconds secondes)',
    'de': 'Bitte versuchen Sie es später erneut. (Erneut in $seconds Sekunden)',
    'es': 'Inténtelo más tarde. (Reintentar en $seconds segundos)',
    'pt': 'Tente novamente mais tarde. (Tentar em $seconds segundos)',
    'ru': 'Попробуйте позже. (Повтор через $seconds сек.)',
    'tr': 'Lütfen daha sonra tekrar deneyin. ($seconds saniye sonra tekrar denenebilir)',
    'ar': 'يرجى المحاولة لاحقاً. (إعادة المحاولة بعد $seconds ثانية)',
    'it': 'Riprova più tardi. (Riprova tra $seconds secondi)',
    'hi': 'कृपया बाद में पुनः प्रयास करें। ($seconds सेकंड बाद पुनः प्रयास)',
    'th': 'กรุณาลองใหม่ภายหลัง (ลองใหม่ใน $seconds วินาที)',
  });

  String get authOtpLimitExceeded => _t({
    'ko': '인증 코드 요청 횟수를 초과했습니다. 잠시 후 다시 시도해주세요.',
    'en': 'Too many verification code requests. Please try again later.',
    'ja': '認証コードのリクエスト回数を超えました。しばらくしてからお試しください。',
    'zh': '验证码请求次数超限。请稍后再试。',
    'fr': 'Trop de demandes de code. Veuillez réessayer plus tard.',
    'de': 'Zu viele Code-Anfragen. Bitte versuchen Sie es später erneut.',
    'es': 'Demasiadas solicitudes de código. Inténtelo más tarde.',
    'pt': 'Muitas solicitações de código. Tente novamente mais tarde.',
    'ru': 'Слишком много запросов кода. Попробуйте позже.',
    'tr': 'Çok fazla kod talebi. Lütfen daha sonra tekrar deneyin.',
    'ar': 'طلبات رمز التحقق تجاوزت الحد. يرجى المحاولة لاحقاً.',
    'it': 'Troppe richieste di codice. Riprova più tardi.',
    'hi': 'सत्यापन कोड अनुरोधों की सीमा पार हो गई। कृपया बाद में प्रयास करें।',
    'th': 'ขอรหัสยืนยันเกินจำนวนครั้ง กรุณาลองใหม่ภายหลัง',
  });

  String get authEnterOtpCode => _t({
    'ko': '6자리 코드를 입력해주세요.',
    'en': 'Please enter the 6-digit code.',
    'ja': '6桁のコードを入力してください。',
    'zh': '请输入6位数字代码。',
    'fr': 'Veuillez entrer le code à 6 chiffres.',
    'de': 'Bitte geben Sie den 6-stelligen Code ein.',
    'es': 'Ingrese el código de 6 dígitos.',
    'pt': 'Insira o código de 6 dígitos.',
    'ru': 'Введите 6-значный код.',
    'tr': '6 haneli kodu girin.',
    'ar': 'يرجى إدخال الرمز المكون من 6 أرقام.',
    'it': 'Inserisci il codice a 6 cifre.',
    'hi': 'कृपया 6 अंकों का कोड दर्ज करें।',
    'th': 'กรุณากรอกรหัส 6 หลัก',
  });

  String authOtpResendWait(int seconds) => _t({
    'ko': '${seconds}초 후 재발송 가능합니다.',
    'en': 'Resend available in $seconds seconds.',
    'ja': '${seconds}秒後に再送信可能です。',
    'zh': '${seconds}秒后可重新发送。',
    'fr': 'Renvoi possible dans $seconds secondes.',
    'de': 'Erneutes Senden in $seconds Sekunden möglich.',
    'es': 'Reenvío disponible en $seconds segundos.',
    'pt': 'Reenvio disponível em $seconds segundos.',
    'ru': 'Повторная отправка через $seconds сек.',
    'tr': '$seconds saniye sonra tekrar gönderilebilir.',
    'ar': 'إعادة الإرسال متاحة بعد $seconds ثانية.',
    'it': 'Reinvio disponibile tra $seconds secondi.',
    'hi': '$seconds सेकंड बाद पुनः भेजें।',
    'th': 'ส่งใหม่ได้ใน $seconds วินาที',
  });

  String get authLocationDenied => _t({
    'ko': '위치 권한이 거부되었습니다.\n설정 → 앱 → 위치에서 허용해주세요.',
    'en': 'Location permission denied.\nPlease allow in Settings → App → Location.',
    'ja': '位置情報の許可が拒否されました。\n設定 → アプリ → 位置情報で許可してください。',
    'zh': '位置权限被拒绝。\n请在设置 → 应用 → 位置中允许。',
    'fr': 'Permission de localisation refusée.\nVeuillez autoriser dans Réglages → App → Localisation.',
    'de': 'Standortberechtigung verweigert.\nBitte in Einstellungen → App → Standort erlauben.',
    'es': 'Permiso de ubicación denegado.\nPermita en Ajustes → App → Ubicación.',
    'pt': 'Permissão de localização negada.\nPermita em Configurações → App → Localização.',
    'ru': 'Доступ к геолокации запрещён.\nРазрешите в Настройки → Приложение → Местоположение.',
    'tr': 'Konum izni reddedildi.\nLütfen Ayarlar → Uygulama → Konum\'dan izin verin.',
    'ar': 'تم رفض إذن الموقع.\nيرجى السماح في الإعدادات → التطبيق → الموقع.',
    'it': 'Permesso di localizzazione negato.\nConsenti in Impostazioni → App → Posizione.',
    'hi': 'स्थान अनुमति अस्वीकृत।\nकृपया सेटिंग्स → ऐप → स्थान में अनुमति दें।',
    'th': 'การอนุญาตตำแหน่งถูกปฏิเสธ\nกรุณาอนุญาตใน ตั้งค่า → แอป → ตำแหน่ง',
  });

  String get authOpenSettings => _t({
    'ko': '설정 열기',
    'en': 'Open Settings',
    'ja': '設定を開く',
    'zh': '打开设置',
    'fr': 'Ouvrir les réglages',
    'de': 'Einstellungen öffnen',
    'es': 'Abrir ajustes',
    'pt': 'Abrir configurações',
    'ru': 'Открыть настройки',
    'tr': 'Ayarları aç',
    'ar': 'فتح الإعدادات',
    'it': 'Apri impostazioni',
    'hi': 'सेटिंग्स खोलें',
    'th': 'เปิดการตั้งค่า',
  });

  String get authUsernameHint => _t({
    'ko': 'traveler42   (영문 시작, 영문·숫자·_ 2~20자)',
    'en': 'traveler42   (start with letter, 2-20 alphanumeric/_)',
    'ja': 'traveler42   (英字開始、英数字·_ 2〜20文字)',
    'zh': 'traveler42   (字母开头，字母·数字·_ 2-20位)',
    'fr': 'traveler42   (commence par une lettre, 2-20 alphanum./_)',
    'de': 'traveler42   (Buchstabe am Anfang, 2-20 Zeichen: Buchst./Ziffern/_)',
    'es': 'traveler42   (inicia con letra, 2-20 alfanumérico/_)',
    'pt': 'traveler42   (inicia com letra, 2-20 alfanumérico/_)',
    'ru': 'traveler42   (��ачало с буквы, 2-20 букв/цифр/_)',
    'tr': 'traveler42   (harf ile başlar, 2-20 harf/rakam/_)',
    'ar': 'traveler42   (يبدأ بحرف، 2-20 حرف/رقم/_)',
    'it': 'traveler42   (inizia con lettera, 2-20 alfanum./_)',
    'hi': 'traveler42   (अक्षर से शुरू, 2-20 अक्षर/अंक/_)',
    'th': 'traveler42   (เริ่มด้วยตัวอักษร, 2-20 ตัวอักษร/ตัวเลข/_)',
  });

  String get authUsernameTaken => _t({
    'ko': '이미 사용 중인 아이디입니다. 다른 아이디를 입력해주세요.',
    'en': 'This ID is already taken. Please choose a different one.',
    'ja': 'このIDは既に使用されています。別のIDを入力してください。',
    'zh': '此ID已被使用。请输入其他ID。',
    'fr': 'Cet identifiant est déjà pris. Veuillez en choisir un autre.',
    'de': 'Diese ID ist bereits vergeben. Bitte wählen Sie eine andere.',
    'es': 'Este ID ya está en uso. Elija otro.',
    'pt': 'Este ID já está em uso. Escolha outro.',
    'ru': 'Этот ID уже занят. Выберите другой.',
    'tr': 'Bu ID zaten kullanılıyor. Başka bir tane seçin.',
    'ar': 'هذا المعرّف مستخدم بالفعل. يرجى اختيار معرّف آخر.',
    'it': 'Questo ID è già in uso. Scegline un altro.',
    'hi': 'यह आईडी पहले से उपयोग में है। कृपया कोई अन्य चुनें।',
    'th': 'ID นี้ถูกใช้แล้ว กรุณาเลือก ID อื่น',
  });

  String get authPasswordHintSignup => _t({
    'ko': 'Pass123   (영문+숫자 포함 6~12자)',
    'en': 'Pass123   (letters + numbers, 6-12 chars)',
    'ja': 'Pass123   (英数字含む6〜12文字)',
    'zh': 'Pass123   (含字母+数字，6-12位)',
    'fr': 'Pass123   (lettres + chiffres, 6-12 car.)',
    'de': 'Pass123   (Buchstaben + Zahlen, 6-12 Zeichen)',
    'es': 'Pass123   (letras + números, 6-12 caract.)',
    'pt': 'Pass123   (letras + números, 6-12 caract.)',
    'ru': 'Pass123   (буквы + цифры, 6-12 символов)',
    'tr': 'Pass123   (harf + rakam, 6-12 karakter)',
    'ar': 'Pass123   (حروف + أرقام، 6-12 حرف)',
    'it': 'Pass123   (lettere + numeri, 6-12 car.)',
    'hi': 'Pass123   (अक्षर + अंक, 6-12 अक्षर)',
    'th': 'Pass123   (ตัวอักษร + ตัวเลข, 6-12 ตัว)',
  });

  String get authResidenceCountry => _t({
    'ko': '거주 국가',
    'en': 'Country of Residence',
    'ja': '居住国',
    'zh': '居住国家',
    'fr': 'Pays de résidence',
    'de': 'Wohnsitzland',
    'es': 'País de residencia',
    'pt': 'País de residência',
    'ru': 'Страна проживания',
    'tr': 'İkamet ülkesi',
    'ar': 'بلد الإقامة',
    'it': 'Paese di residenza',
    'hi': 'निवास का देश',
    'th': 'ประเทศที่อยู่อาศัย',
  });

  String get authSnsLink => _t({
    'ko': 'SNS 링크 (선택)',
    'en': 'SNS Link (optional)',
    'ja': 'SNSリンク（任意）',
    'zh': '社交链接（可选）',
    'fr': 'Lien SNS (facultatif)',
    'de': 'SNS-Link (optional)',
    'es': 'Enlace SNS (opcional)',
    'pt': 'Link SNS (opcional)',
    'ru': 'Ссылка на соцсеть (необязательно)',
    'tr': 'SNS bağlantısı (isteğe bağlı)',
    'ar': 'رابط التواصل الاجتماعي (اختياري)',
    'it': 'Link SNS (facoltativo)',
    'hi': 'SNS लिंक (वैकल्पिक)',
    'th': 'ลิงก์ SNS (ไม่บังคับ)',
  });

  String get authPrivacyRequired => _t({
    'ko': '(필수) 개인정보 처리방침',
    'en': '(Required) Privacy Policy',
    'ja': '（必須）プライバシーポリシー',
    'zh': '（必填）隐私政策',
    'fr': '(Obligatoire) Politique de confidentialité',
    'de': '(Erforderlich) Datenschutzrichtlinie',
    'es': '(Obligatorio) Política de privacidad',
    'pt': '(Obrigatório) Política de Privacidade',
    'ru': '(Обязательно) Политика конфиденциальности',
    'tr': '(Zorunlu) Gizlilik Politikası',
    'ar': '(مطلوب) سياسة الخصوصية',
    'it': '(Obbligatorio) Informativa sulla privacy',
    'hi': '(आवश्यक) गोपनीयता नीति',
    'th': '(จำเป็น) นโยบายความเป็นส่วนตัว',
  });

  String get authViewContent => _t({
    'ko': '내용 보기',
    'en': 'View',
    'ja': '内容を見る',
    'zh': '查看内容',
    'fr': 'Voir le contenu',
    'de': 'Inhalt ansehen',
    'es': 'Ver contenido',
    'pt': 'Ver conteúdo',
    'ru': 'Просмотреть',
    'tr': 'İçeriği görüntüle',
    'ar': 'عرض المحتوى',
    'it': 'Visualizza',
    'hi': 'सामग्री देखें',
    'th': 'ดูเนื้อหา',
  });

  String get authPrivacyDesc => _t({
    'ko': '수집 항목: 이메일·닉네임·국가·위치(도시 단위)\n목적: 서비스 제공, 계정 관리',
    'en': 'Collected: email, nickname, country, location (city level)\nPurpose: service delivery, account management',
    'ja': '収集項目: メール・ニックネーム・国・位置(都市単位)\n目的: サービス提供、アカウント管理',
    'zh': '收集项目: 邮箱·昵称·国家·位置(城市级别)\n目的: 服务提供、账号管理',
    'fr': 'Données collectées : email, pseudo, pays, localisation (ville)\nObjectif : fourniture du service, gestion du compte',
    'de': 'Erfasst: E-Mail, Nickname, Land, Standort (Stadtebene)\nZweck: Dienstleistung, Kontoverwaltung',
    'es': 'Recopilado: correo, apodo, país, ubicación (ciudad)\nPropósito: prestación del servicio, gestión de cuenta',
    'pt': 'Coletado: email, apelido, país, localização (cidade)\nFinalidade: prestação de serviço, gestão de conta',
    'ru': 'Собираемые данные: email, никнейм, страна, местоположение (город)\nЦель: предоставление услуг, управление аккаунтом',
    'tr': 'Toplanan: e-posta, takma ad, ülke, konum (şehir düzeyi)\nAmaç: hizmet sunumu, hesap yönetimi',
    'ar': 'البيانات المجمعة: البريد الإلكتروني، الاسم المستعار، الدولة، الموقع (مستوى المدينة)\nالغرض: تقديم الخدمة، إدارة الحساب',
    'it': 'Raccolti: email, nickname, paese, posizione (livello città)\nScopo: erogazione servizio, gestione account',
    'hi': 'संग्रह: ईमेल, उपनाम, देश, स्थान (शहर स्तर)\nउद्देश्य: सेवा प्रदान, खाता प्रबंधन',
    'th': '���้อมูลที่เก็บ: อีเมล, ชื่อเล่น, ประเทศ, ตำแหน่ง (ระดับเมือง)\nวัตถุประสงค์: ให้บริการ, จัดการบัญชี',
  });

  String get authLocationOptional => _t({
    'ko': '(선택) 현재 위치 사용 동의',
    'en': '(Optional) Location Access Consent',
    'ja': '（任意）現在地の使用に同意',
    'zh': '（可选）同意使用当前位置',
    'fr': '(Facultatif) Consentement à l\'accès à la localisation',
    'de': '(Optional) Zustimmung zum Standortzugriff',
    'es': '(Opcional) Consentimiento de acceso a ubicación',
    'pt': '(Opcional) Consentimento de acesso à localização',
    'ru': '(Необязательно) Согласие на доступ к местоположению',
    'tr': '(İsteğe bağlı) Konum erişimi onayı',
    'ar': '(��ختياري) الموافقة على الوصول إلى الموقع',
    'it': '(Facoltativo) Consenso accesso alla posizione',
    'hi': '(वैकल्पिक) स्थान पहुँच सहमति',
    'th': '(ไม่บังคับ) ยินยอมใช้ตำแหน่งปัจจุบัน',
  });

  String get authLocationDesc => _t({
    'ko': '가입 후 홍보 발송 시점에도 위치 권한을 요청할 수 있어요.\n지금 동의하면 위치 기반 기능을 바로 사용할 수 있습니다.',
    'en': 'Location permission can also be requested when sending promos.\nAgree now to use location-based features right away.',
    'ja': '手紙送信時にも位置情報の許可を求められます。\n今同意すると、位置情報機能をすぐに使用できます。',
    'zh': '发送信件时也可以请求位置权限。\n现在同意即可立即使用基于位置的功能。',
    'fr': 'La permission de localisation peut aussi être demandée lors de l\'envoi.\nAcceptez maintenant pour utiliser les fonctions de localisation immédiatement.',
    'de': 'Die Standortberechtigung kann auch beim Versenden von Briefen angefragt werden.\nStimmen Sie jetzt zu, um standortbasierte Funktionen sofort zu nutzen.',
    'es': 'El permiso de ubicación también se puede solicitar al enviar cartas.\nAcepte ahora para usar funciones basadas en ubicación de inmediato.',
    'pt': 'A permissão de localização também pode ser solicitada ao enviar cartas.\nConcorde agora para usar recursos baseados em localização imediatamente.',
    'ru': 'Разрешение на геолокацию может запрашиваться при отправке писем.\nСогласитесь сейчас, чтобы сразу использовать функции геолокации.',
    'tr': 'Mektup gönderirken de konum izni istenebilir.\nŞimdi kabul ederek konum tabanlı özellikleri hemen kullanabilirsiniz.',
    'ar': 'يمكن طلب إذن الموقع أيضاً عند إرسال الرسائل.\nوافق الآن لاستخدام ميزات الموقع فوراً.',
    'it': 'Il permesso di localizzazione può essere richiesto anche durante l\'invio.\nAccetta ora per usare subito le funzioni basate sulla posizione.',
    'hi': 'पत्र भेजते समय भी स्थान अनुमति मांगी जा सकती है।\nअभी सहमत होकर स्थान-आधारित सुविधाओं का उपयोग करें।',
    'th': 'การอนุญาตตำแหน่งสามารถขอได้เมื่อส่งจดหมาย\nยินยอมตอนนี้เพื่อใช้ฟีเจอร์ตำแหน่งทันที',
  });

  String get authGranted => _t({
    'ko': '허용됨',
    'en': 'Granted',
    'ja': '許可済み',
    'zh': '已允许',
    'fr': 'Autorisé',
    'de': 'Gewährt',
    'es': 'Concedido',
    'pt': 'Concedido',
    'ru': 'Разрешено',
    'tr': 'İzin verildi',
    'ar': 'مسموح',
    'it': 'Concesso',
    'hi': 'अनुमति दी गई',
    'th': 'อนุญาตแล้ว',
  });

  String get authSignupButton => _t({
    'ko': '가입하기',
    'en': 'Sign Up',
    'ja': '登録する',
    'zh': '注册',
    'fr': "S'inscrire",
    'de': 'Registrieren',
    'es': 'Registrarse',
    'pt': 'Cadastrar',
    'ru': 'Зарегистрироваться',
    'tr': 'Üye ol',
    'ar': 'إنشاء حساب',
    'it': 'Registrati',
    'hi': 'साइनअप करें',
    'th': 'สมัครสมาชิก',
  });

  String get authBackToEmail => _t({
    'ko': '이메일 입력으로 돌아가기',
    'en': 'Back to email entry',
    'ja': 'メール入力に戻る',
    'zh': '返回邮箱输入',
    'fr': 'Retour à la saisie de l\'email',
    'de': 'Zurück zur E-Mail-Eingabe',
    'es': 'Volver a ingresar correo',
    'pt': 'Voltar para inserir email',
    'ru': 'Вернуться к вводу email',
    'tr': 'E-posta girişine geri dön',
    'ar': 'العودة إلى إدخال البريد الإلكتروني',
    'it': 'Torna all\'inserimento email',
    'hi': 'ईमेल दर्ज करने पर वापस जाएं',
    'th': 'กลับไปกรอกอีเมล',
  });

  String get authEmailVerification => _t({
    'ko': '이메일 인증',
    'en': 'Email Verification',
    'ja': 'メール認証',
    'zh': '邮箱验证',
    'fr': 'Vérification par email',
    'de': 'E-Mail-Verifizierung',
    'es': 'Verificación de correo',
    'pt': 'Verificação de email',
    'ru': 'Подтверждение email',
    'tr': 'E-posta doğrulama',
    'ar': 'التحقق من البريد الإلكتروني',
    'it': 'Verifica email',
    'hi': 'ईमेल सत्यापन',
    'th': 'ยืนยันอีเมล',
  });

  String authOtpSent(String email) => _t({
    'ko': '$email\n으로 인증 코드를 발송했습니다.',
    'en': 'A verification code has been sent to\n$email.',
    'ja': '$email\nに認証コードを送信しました。',
    'zh': '验证码已发送至\n$email。',
    'fr': 'Un code de vérification a été envoyé à\n$email.',
    'de': 'Ein Bestätigungscode wurde an\n$email gesendet.',
    'es': 'Se ha enviado un código de verificación a\n$email.',
    'pt': 'Um código de verificação foi enviado para\n$email.',
    'ru': 'Код подтверждения отправлен на\n$email.',
    'tr': '$email\nadresine doğrulama kodu gönderildi.',
    'ar': 'تم إرسال رمز التحقق إلى\n$email.',
    'it': 'Un codice di verifica è stato inviato a\n$email.',
    'hi': '$email\nपर सत्यापन कोड भेजा गया है।',
    'th': 'ส่งรหัสยืนยันไปที่\n$email แล้ว',
  });

  String authExpiresIn(String time) => _t({
    'ko': '$time 후 만료',
    'en': 'Expires in $time',
    'ja': '$time 後に期限切れ',
    'zh': '$time 后过期',
    'fr': 'Expire dans $time',
    'de': 'Läuft in $time ab',
    'es': 'Expira en $time',
    'pt': 'Expira em $time',
    'ru': 'Истекает через $time',
    'tr': '$time sonra sona erer',
    'ar': 'تنتهي الصلاحية بعد $time',
    'it': 'Scade in $time',
    'hi': '$time बाद समाप्त',
    'th': 'หมดอายุใน $time',
  });

  String get authResendCode => _t({
    'ko': '코드 재발송',
    'en': 'Resend Code',
    'ja': 'コード再送信',
    'zh': '重新发送代码',
    'fr': 'Renvoyer le code',
    'de': 'Code erneut senden',
    'es': 'Reenviar código',
    'pt': 'Reenviar código',
    'ru': 'Отправить код повторно',
    'tr': 'Kodu tekrar gönder',
    'ar': 'إعادة إرسال الرمز',
    'it': 'Reinvia codice',
    'hi': 'कोड पुनः भेजें',
    'th': 'ส่งรหัสอีกครั้ง',
  });

  String get authResend => _t({
    'ko': '재발송',
    'en': 'Resend',
    'ja': '再送信',
    'zh': '重新发送',
    'fr': 'Renvoyer',
    'de': 'Erneut senden',
    'es': 'Reenviar',
    'pt': 'Reenviar',
    'ru': 'Отправить повторно',
    'tr': 'Tekrar gönder',
    'ar': 'إعادة إرسال',
    'it': 'Reinvia',
    'hi': 'पुनः भेजें',
    'th': 'ส่งอีกครั้ง',
  });

  String get authVerifyAndSignup => _t({
    'ko': '인증 완료 · 가입하기',
    'en': 'Verify & Sign Up',
    'ja': '認証完了・登録する',
    'zh': '验证完成 · 注册',
    'fr': 'Vérifier et s\'inscrire',
    'de': 'Verifizieren & Registrieren',
    'es': 'Verificar y registrarse',
    'pt': 'Verificar e cadastrar',
    'ru': 'Подтвердить и зарегистрироваться',
    'tr': 'Doğrula ve üye ol',
    'ar': 'تحقق وأنشئ حساباً',
    'it': 'Verifica e registrati',
    'hi': 'सत्यापित करें और साइनअप करें',
    'th': 'ยืนยันและสมัครสมาชิก',
  });

  String get authOtpExpired => _t({
    'ko': '인증 코드가 만료되었습니다. 재발송을 눌러주세요.',
    'en': 'The verification code has expired. Please tap Resend.',
    'ja': '認証コードの有効期限が切れました。再送信を押してください。',
    'zh': '验证码已过期。请点击重新发送。',
    'fr': 'Le code de vérification a expiré. Veuillez appuyer sur Renvoyer.',
    'de': 'Der Bestätigungscode ist abgelaufen. Bitte auf Erneut senden tippen.',
    'es': 'El código de verificación ha expirado. Toque Reenviar.',
    'pt': 'O código de verificação expirou. Toque em Reenviar.',
    'ru': 'Код подтверждения истёк. Нажмите Отправить повторно.',
    'tr': 'Doğrulama kodunun süresi doldu. Tekrar Gönder\'e dokunun.',
    'ar': 'انتهت صلاحية رمز التحقق. يرجى الضغط على إعادة الإرسال.',
    'it': 'Il codice di verifica è scaduto. Tocca Reinvia.',
    'hi': 'सत्यापन कोड समाप्त हो गया है। कृपया पुनः भेजें दबाएं।',
    'th': 'รหัสยืนยันหมดอายุแล้ว กรุณากดส่งอีกครั้ง',
  });

  String get authPrivacyPolicy => _t({
    'ko': '개인정보 처리방침',
    'en': 'Privacy Policy',
    'ja': 'プライバシーポリシー',
    'zh': '隐私政策',
    'fr': 'Politique de confidentialité',
    'de': 'Datenschutzrichtlinie',
    'es': 'Política de privacidad',
    'pt': 'Política de Privacidade',
    'ru': 'Политика конфиденциальности',
    'tr': 'Gizlilik Politikası',
    'ar': 'سياسة الخصوصية',
    'it': 'Informativa sulla privacy',
    'hi': 'गोपनीयता नीति',
    'th': 'นโยบายความเป็นส่วนตัว',
  });

  String get authPrivacySec1Title => _t({
    'ko': '1. 수집 항목',
    'en': '1. Data Collected',
    'ja': '1. 収集項目',
    'zh': '1. 收集项目',
    'fr': '1. Données collectées',
    'de': '1. Erfasste Daten',
    'es': '1. Datos recopilados',
    'pt': '1. Dados coletados',
    'ru': '1. Собираемые данные',
    'tr': '1. Toplanan veriler',
    'ar': '1. البيانات المجمعة',
    'it': '1. Dati raccolti',
    'hi': '1. एकत्रित डेटा',
    'th': '1. ข้อมูลที่เก็บรวบรวม',
  });

  String get authPrivacySec1Body => _t({
    'ko': '이메일, 닉네임, 국가, SNS 링크(선택)',
    'en': 'Email, nickname, country, SNS link (optional)',
    'ja': 'メール、ニックネーム、国、SNSリンク（任意）',
    'zh': '邮箱、昵称、国家、社交链接（可选）',
    'fr': 'Email, pseudo, pays, lien SNS (facultatif)',
    'de': 'E-Mail, Nickname, Land, SNS-Link (optional)',
    'es': 'Correo, apodo, país, enlace SNS (opcional)',
    'pt': 'Email, apelido, país, link SNS (opcional)',
    'ru': 'Email, никнейм, страна, ссылка на соцсеть (необязательно)',
    'tr': 'E-posta, takma ad, ülke, SNS bağlantısı (isteğe bağlı)',
    'ar': 'البريد الإلكتروني، الاسم المستعار، الدولة، رابط التواصل (اختياري)',
    'it': 'Email, nickname, paese, link SNS (facoltativo)',
    'hi': 'ईमेल, उपनाम, देश, SNS लिंक (वैकल्पिक)',
    'th': 'อีเมล, ชื่อเล่น, ประเทศ, ลิงก์ SNS (ไม่บังคับ)',
  });

  String get authPrivacySec2Title => _t({
    'ko': '2. 수집 목적',
    'en': '2. Purpose',
    'ja': '2. 収集目的',
    'zh': '2. 收集目的',
    'fr': '2. Objectif',
    'de': '2. Zweck',
    'es': '2. Propósito',
    'pt': '2. Finalidade',
    'ru': '2. Цель сбора',
    'tr': '2. Toplama amacı',
    'ar': '2. الغرض',
    'it': '2. Scopo',
    'hi': '2. उद्देश्य',
    'th': '2. วัตถุประสงค์',
  });

  String get authPrivacySec2Body => _t({
    'ko': '서비스 제공, 홍보 발송 및 수신, 계정 관리',
    'en': 'Service delivery, sending and receiving rewards, account management',
    'ja': 'サービス提供、手紙の送受信、アカウント管理',
    'zh': '服务提供、信件发送和接收、账号管理',
    'fr': 'Fourniture du service, envoi et réception de lettres, gestion du compte',
    'de': 'Dienstleistung, Senden und Empfangen von Briefen, Kontoverwaltung',
    'es': 'Prestación del servicio, envío y recepción de cartas, gestión de cuenta',
    'pt': 'Prestação de serviço, envio e recebimento de cartas, gestão de conta',
    'ru': 'Предоставление услуг, отправка и получение писем, управление аккаунтом',
    'tr': 'Hizmet sunumu, mektup gönderme ve alma, hesap yönetimi',
    'ar': 'تقديم الخدمة، إرسال واستقبال الرسائل، إدارة الحساب',
    'it': 'Erogazione servizio, invio e ricezione lettere, gestione account',
    'hi': 'सेवा प्रदान, पत्र भेजना और प्राप्त करना, खाता प्रबंधन',
    'th': 'ให้บริการ, ส่งและรับจดหมาย, จัดการบัญชี',
  });

  String get authPrivacySec3Title => _t({
    'ko': '3. 보유 기간',
    'en': '3. Retention Period',
    'ja': '3. 保管期間',
    'zh': '3. 保留期限',
    'fr': '3. Durée de conservation',
    'de': '3. Aufbewahrungsfrist',
    'es': '3. Período de retención',
    'pt': '3. Período de retenção',
    'ru': '3. Срок хранения',
    'tr': '3. Saklama süresi',
    'ar': '3. فترة الاحتفاظ',
    'it': '3. Periodo di conservazione',
    'hi': '3. प्रतिधारण अवधि',
    'th': '3. ระยะเวลาเก็บรักษา',
  });

  String get authPrivacySec3Body => _t({
    'ko': '회원 탈퇴 시까지 (탈퇴 즉시 모든 데이터 삭제)',
    'en': 'Until account deletion (all data deleted immediately upon withdrawal)',
    'ja': '退会時まで（退会と同時にすべてのデータを削除）',
    'zh': '直到账号注销（注销后立即删除所有数据）',
    'fr': "Jusqu'à la suppression du compte (toutes les données supprimées immédiatement)",
    'de': 'Bis zur Kontolöschung (alle Daten werden sofort gelöscht)',
    'es': 'Hasta la eliminación de la cuenta (todos los datos se eliminan inmediatamente)',
    'pt': 'Até a exclusão da conta (todos os dados excluídos imediatamente)',
    'ru': 'До удаления аккаунта (все данные удаляются немедленно)',
    'tr': 'Hesap silinene kadar (silme sonrası tüm veriler hemen silinir)',
    'ar': 'حتى حذف الحساب (يتم حذف جميع البيانات فوراً)',
    'it': "Fino alla cancellazione dell'account (tutti i dati eliminati immediatamente)",
    'hi': 'खाता हटाने तक (हटाने पर सभी डेटा तुरंत हटा दिया जाता है)',
    'th': 'จนกว่าจะลบบัญชี (ข้อมูลทั้งหมดจะถูกลบทันที)',
  });

  String get authPrivacySec4Title => _t({
    'ko': '4. 제3자 제공',
    'en': '4. Third-Party Sharing',
    'ja': '4. 第三者提供',
    'zh': '4. 第三方共享',
    'fr': '4. Partage avec des tiers',
    'de': '4. Weitergabe an Dritte',
    'es': '4. Compartir con terceros',
    'pt': '4. Compartilhamento com terceiros',
    'ru': '4. Передача третьим лицам',
    'tr': '4. Üçüncü taraf paylaşımı',
    'ar': '4. المشاركة مع أطراف ثالثة',
    'it': '4. Condivisione con terzi',
    'hi': '4. तृतीय-पक्ष साझाकरण',
    'th': '4. การแบ่งปันกับบุคคลที่สาม',
  });

  String get authPrivacySec4Body => _t({
    'ko': '수집된 개인정보는 제3자에게 제공되지 않습니다.',
    'en': 'Collected personal data is not shared with third parties.',
    'ja': '収集された個人情報は第三者に提供されません。',
    'zh': '收集的个人信息不会提供给第三方。',
    'fr': 'Les données personnelles collectées ne sont pas partagées avec des tiers.',
    'de': 'Gesammelte personenbezogene Daten werden nicht an Dritte weitergegeben.',
    'es': 'Los datos personales recopilados no se comparten con terceros.',
    'pt': 'Os dados pessoais coletados não são compartilhados com terceiros.',
    'ru': 'Собранные персональные данные не передаются третьим лицам.',
    'tr': 'Toplanan kişisel veriler üçüncü taraflarla paylaşılmaz.',
    'ar': 'لا تتم مشاركة البيانات الشخصية المجمعة مع أطراف ثالثة.',
    'it': 'I dati personali raccolti non vengono condivisi con terzi.',
    'hi': 'एकत्रित व्यक्तिगत डेटा तृतीय पक्षों के साथ साझा नहीं किया जाता।',
    'th': 'ข้อมูลส่วนบุคคลที่เก็บรวบรวมจะไม่ถูกแบ่งปันกับบุคคลที่สาม',
  });

  String get authAgree => _t({
    'ko': '동의하기',
    'en': 'Agree',
    'ja': '同意する',
    'zh': '同意',
    'fr': 'Accepter',
    'de': 'Zustimmen',
    'es': 'Aceptar',
    'pt': 'Concordar',
    'ru': 'Согласен',
    'tr': 'Kabul et',
    'ar': 'موافق',
    'it': 'Accetta',
    'hi': 'सहमत हूँ',
    'th': 'ยอมรับ',
  });

  String get authClose => _t({
    'ko': '닫기',
    'en': 'Close',
    'ja': '閉じる',
    'zh': '关闭',
    'fr': 'Fermer',
    'de': 'Schließen',
    'es': 'Cerrar',
    'pt': 'Fechar',
    'ru': 'Закрыть',
    'tr': 'Kapat',
    'ar': 'إغلاق',
    'it': 'Chiudi',
    'hi': 'बंद करें',
    'th': 'ปิด',
  });

  String get authSelectResidenceCountry => _t({
    'ko': '��주 국가 선택',
    'en': 'Select Country of Residence',
    'ja': '居住国を選択',
    'zh': '选择居住国家',
    'fr': 'Sélectionner le pays de résidence',
    'de': 'Wohnsitzland auswählen',
    'es': 'Seleccionar país de residencia',
    'pt': 'Selecionar país de residência',
    'ru': 'Выберите страну проживания',
    'tr': 'İkamet ülkesini seçin',
    'ar': 'اختر بلد الإقامة',
    'it': 'Seleziona paese di residenza',
    'hi': 'निवास का देश चुनें',
    'th': 'เลือกประเทศที่อยู่อาศัย',
  });

  String authLanguageSet(String langName) => _t({
    'ko': '🌐 언어가 $langName(으)로 설정됩니다',
    'en': '🌐 Language will be set to $langName',
    'ja': '🌐 言語が${langName}に設定されます',
    'zh': '🌐 语言将设置为$langName',
    'fr': '🌐 La langue sera définie sur $langName',
    'de': '🌐 Sprache wird auf $langName eingestellt',
    'es': '🌐 El idioma se establecerá en $langName',
    'pt': '🌐 O idioma será definido como $langName',
    'ru': '🌐 Язык будет установлен: $langName',
    'tr': '🌐 Dil $langName olarak ayarlanacak',
    'ar': '🌐 سيتم تعيين اللغة إلى $langName',
    'it': '🌐 La lingua sarà impostata su $langName',
    'hi': '🌐 भाषा $langName पर सेट होगी',
    'th': '🌐 ภาษาจะถูกตั้งเป็น $langName',
  });

  String get authIAgree => _t({
    'ko': '동의합니다',
    'en': 'I agree',
    'ja': '同意します',
    'zh': '我同意',
    'fr': "J'accepte",
    'de': 'Ich stimme zu',
    'es': 'Estoy de acuerdo',
    'pt': 'Eu concordo',
    'ru': 'Я согласен',
    'tr': 'Kabul ediyorum',
    'ar': 'أوافق',
    'it': 'Accetto',
    'hi': 'मैं सहमत हूँ',
    'th': 'ฉันยอมรับ',
  });

  // ── Compose Screen ──────────────────────────────────────────────────
  // ── Compose Screen ──────────────────────────────────────────────────────

  String get composeLinkNotAllowed => _t({
    'ko': '🔗 링크는 본문에 직접 삽입할 수 없어요.\n아래 링크 첨부 기능을 사용해주세요.',
    'en': '🔗 Links cannot be inserted directly in the text.\nPlease use the link attachment feature below.',
    'ja': '🔗 リンクは本文に直接挿入できません。\n下のリンク添付機能をお使いください。',
    'zh': '🔗 链接不能直接插入正文。\n请使用下方的链接附件功能。',
    'fr': '🔗 Les liens ne peuvent pas être insérés directement.\nVeuillez utiliser la fonction de lien ci-dessous.',
    'de': '🔗 Links können nicht direkt eingefügt werden.\nBitte nutzen Sie die Link-Anhang-Funktion unten.',
    'es': '🔗 Los enlaces no se pueden insertar directamente.\nUsa la función de adjuntar enlace abajo.',
    'pt': '🔗 Links não podem ser inseridos diretamente.\nUse a função de anexar link abaixo.',
    'ru': '🔗 Ссылки нельзя вставлять прямо в текст.\nИспользуйте функцию прикрепления ссылки ниже.',
    'tr': '🔗 Bağlantılar doğrudan eklenemez.\nAşağıdaki bağlantı ekleme özelliğini kullanın.',
    'ar': '🔗 لا يمكن إدراج الروابط مباشرة.\nيرجى استخدام ميزة إرفاق الرابط أدناه.',
    'it': '🔗 I link non possono essere inseriti direttamente.\nUsa la funzione di allegato link qui sotto.',
    'hi': '🔗 लिंक सीधे नहीं डाले जा सकते।\nकृपया नीचे लिंक अटैच सुविधा का उपयोग करें।',
    'th': '🔗 ไม่สามารถแทรกลิงก์โดยตรงได้\nกรุณาใช้ฟีเจอร์แนบลิงก์ด้านล่าง',
  });

  String get composeDraftFound => _t({
    'ko': '이전에 작성하던 혜택이 있어요. 이어 작성할까요?',
    'en': 'You have a previous draft. Continue writing?',
    'ja': '以前の下書きがあります。続けますか？',
    'zh': '您有之前的草稿。要继续写吗？',
    'fr': 'Vous avez un brouillon précédent. Continuer ?',
    'de': 'Sie haben einen vorherigen Entwurf. Fortfahren?',
    'es': 'Tienes un borrador anterior. ¿Continuar?',
    'pt': 'Você tem um rascunho anterior. Continuar?',
    'ru': 'У вас есть предыдущий черновик. Продолжить?',
    'tr': 'Önceki taslağınız var. Devam etmek ister misiniz?',
    'ar': 'لديك مسودة سابقة. هل تريد المتابعة؟',
    'it': 'Hai una bozza precedente. Continuare?',
    'hi': 'आपके पास पिछला ड्राफ्ट है। जारी रखें?',
    'th': 'คุณมีฉบับร่างก่อนหน้า เขียนต่อไหม?',
  });

  String get composeDiscard => _t({
    'ko': '버리기',
    'en': 'Discard',
    'ja': '破棄',
    'zh': '丢弃',
    'fr': 'Supprimer',
    'de': 'Verwerfen',
    'es': 'Descartar',
    'pt': 'Descartar',
    'ru': 'Удалить',
    'tr': 'Sil',
    'ar': 'تجاهل',
    'it': 'Elimina',
    'hi': 'हटाएं',
    'th': 'ทิ้ง',
  });

  String get composeContinueWriting => _t({
    'ko': '이어 쓰기',
    'en': 'Continue',
    'ja': '続ける',
    'zh': '继续',
    'fr': 'Continuer',
    'de': 'Fortfahren',
    'es': 'Continuar',
    'pt': 'Continuar',
    'ru': 'Продолжить',
    'tr': 'Devam et',
    'ar': 'متابعة',
    'it': 'Continua',
    'hi': 'जारी रखें',
    'th': 'เขียนต่อ',
  });

  String get composePhotoAttach => _t({
    'ko': '사진 첨부',
    'en': 'Photo Attachment',
    'ja': '写真添付',
    'zh': '照片附件',
    'fr': 'Photo jointe',
    'de': 'Foto anhängen',
    'es': 'Adjuntar foto',
    'pt': 'Anexar foto',
    'ru': 'Прикрепить фото',
    'tr': 'Fotoğraf ekle',
    'ar': 'إرفاق صورة',
    'it': 'Allega foto',
    'hi': 'फोटो संलग्न',
    'th': 'แนบรูปภาพ',
  });

  String get composePhotoAttachDesc => _t({
    'ko': '홍보에 사진 1장을 첨부할 수 있어요.\n프리미엄 회원은 하루 20통까지 이미지 홍보 발송 가능.',
    'en': 'Attach 1 photo to your promo.\nPremium members can send up to 20 image promos per day.',
    'ja': '手紙に写真を1枚添付できます。\nプレミアム会員は1日20通まで画像付き手紙を送れます。',
    'zh': '可以给信附上1张照片。\n高级会员每天最多可发送20封带图片的信。',
    'fr': 'Joignez 1 photo à votre lettre.\nLes membres Premium peuvent envoyer jusqu\'à 20 lettres avec image par jour.',
    'de': 'Fügen Sie 1 Foto an Ihren Brief an.\nPremium-Mitglieder können bis zu 20 Bildbriefe pro Tag senden.',
    'es': 'Adjunta 1 foto a tu carta.\nLos miembros Premium pueden enviar hasta 20 cartas con imagen al día.',
    'pt': 'Anexe 1 foto à sua carta.\nMembros Premium podem enviar até 20 cartas com imagem por dia.',
    'ru': 'Прикрепите 1 фото к письму.\nПремиум-участники могут отправлять до 20 писем с изображениями в день.',
    'tr': 'Mektubunuza 1 fotoğraf ekleyin.\nPremium üyeler günde 20 resimli mektup gönderebilir.',
    'ar': 'أرفق صورة واحدة برسالتك.\nيمكن للأعضاء المميزين إرسال حتى 20 رسالة مصورة يوميًا.',
    'it': 'Allega 1 foto alla tua lettera.\nI membri Premium possono inviare fino a 20 lettere con immagine al giorno.',
    'hi': 'अपने पत्र में 1 फोटो संलग्न करें।\nप्रीमियम सदस्य प्रतिदिन 20 छवि पत्र भेज सकते हैं।',
    'th': 'แนบรูปภาพ 1 รูปกับจดหมาย\nสมาชิก Premium ส่งจดหมายพร้อมรูปได้วันละ 20 ฉบับ',
  });

  String get composeImageLimitReached => _t({
    'ko': '오늘 이미지 혜택 한도(20통)에 도달했어요. 내일 다시 시도해주세요.',
    'en': 'You\'ve reached today\'s image promo limit (20). Please try again tomorrow.',
    'ja': '本日の画像手紙の上限（20通）に達しました。明日また試してください。',
    'zh': '今天的图片信件配额（20封）已用完。请明天再试。',
    'fr': 'Vous avez atteint la limite de lettres avec image (20). Réessayez demain.',
    'de': 'Sie haben das Tageslimit für Bildbriefe (20) erreicht. Versuchen Sie es morgen erneut.',
    'es': 'Has alcanzado el límite de cartas con imagen (20). Inténtalo mañana.',
    'pt': 'Você atingiu o limite de cartas com imagem (20). Tente novamente amanhã.',
    'ru': 'Вы достигли дневного лимита писем с изображениями (20). Попробуйте завтра.',
    'tr': 'Bugünkü resimli mektup limitine (20) ulaştınız. Yarın tekrar deneyin.',
    'ar': 'لقد وصلت إلى حد رسائل الصور اليومي (20). حاول مرة أخرى غدًا.',
    'it': 'Hai raggiunto il limite giornaliero di lettere con immagine (20). Riprova domani.',
    'hi': 'आज की छवि पत्र सीमा (20) पूरी हो गई। कल फिर प्रयास करें।',
    'th': 'ถึงขีดจำกัดจดหมายพร้อมรูป (20 ฉบับ) แล้ว ลองอีกครั้งพรุ่งนี้',
  });

  String get composeEmptyError => _t({
    'ko': '홍보 내용을 작성해주세요 ✍️',
    'en': 'Please write your promo ✍️',
    'ja': '手紙の内容を書いてください ✍️',
    'zh': '请写信内容 ✍️',
    'fr': 'Veuillez écrire votre lettre ✍️',
    'de': 'Bitte schreiben Sie Ihren Brief ✍️',
    'es': 'Por favor escribe tu carta ✍️',
    'pt': 'Por favor escreva sua carta ✍️',
    'ru': 'Пожалуйста, напишите письмо ✍️',
    'tr': 'Lütfen mektubunuzu yazın ✍️',
    'ar': 'يرجى كتابة رسالتك ✍️',
    'it': 'Scrivi la tua lettera ✍️',
    'hi': 'कृपया अपना पत्र लिखें ✍️',
    'th': 'กรุณาเขียนจดหมาย ✍️',
  });

  String composeMinLengthError(int current) => _t({
    'ko': '혜택은 최소 20자 이상 작성해주세요 ✍️ (현재 ${current}자)',
    'en': 'Please write at least 20 characters ✍️ (currently $current)',
    'ja': '最低20文字以上書いてください ✍️（現在${current}文字）',
    'zh': '请至少写20个字符 ✍️（当前${current}字）',
    'fr': 'Veuillez écrire au moins 20 caractères ✍️ ($current actuellement)',
    'de': 'Bitte mindestens 20 Zeichen schreiben ✍️ (aktuell $current)',
    'es': 'Escribe al menos 20 caracteres ✍️ (actualmente $current)',
    'pt': 'Escreva pelo menos 20 caracteres ✍️ (atualmente $current)',
    'ru': 'Напишите минимум 20 символов ✍️ (сейчас $current)',
    'tr': 'En az 20 karakter yazın ✍️ (şu an $current)',
    'ar': 'يرجى كتابة 20 حرفًا على الأقل ✍️ (حاليًا $current)',
    'it': 'Scrivi almeno 20 caratteri ✍️ (attualmente $current)',
    'hi': 'कृपया कम से कम 20 अक्षर लिखें ✍️ (वर्तमान $current)',
    'th': 'กรุณาเขียนอย่างน้อย 20 ตัวอักษร ✍️ (ตอนนี้ $current)',
  });

  String get composeBannedWordError => _t({
    'ko': '부적절한 표현이 포함되어 있어요 🚫',
    'en': 'Inappropriate language detected 🚫',
    'ja': '不適切な表現が含まれています 🚫',
    'zh': '包含不当用语 🚫',
    'fr': 'Langage inapproprié détecté 🚫',
    'de': 'Unangemessene Sprache erkannt 🚫',
    'es': 'Lenguaje inapropiado detectado 🚫',
    'pt': 'Linguagem inadequada detectada 🚫',
    'ru': 'Обнаружена ненормативная лексика 🚫',
    'tr': 'Uygunsuz ifade tespit edildi 🚫',
    'ar': 'تم اكتشاف لغة غير لائقة 🚫',
    'it': 'Linguaggio inappropriato rilevato 🚫',
    'hi': 'अनुचित भाषा पाई गई 🚫',
    'th': 'พบคำไม่เหมาะสม 🚫',
  });

  String get composeSelectCountryError => _t({
    'ko': '발송할 나라를 최소 1개 선택해주세요 🌍',
    'en': 'Please select at least 1 country 🌍',
    'ja': '送信先の国を1つ以上選択してください 🌍',
    'zh': '请至少选择1个国家 🌍',
    'fr': 'Veuillez sélectionner au moins 1 pays 🌍',
    'de': 'Bitte wählen Sie mindestens 1 Land 🌍',
    'es': 'Selecciona al menos 1 país 🌍',
    'pt': 'Selecione pelo menos 1 país 🌍',
    'ru': 'Выберите хотя бы 1 страну 🌍',
    'tr': 'En az 1 ülke seçin 🌍',
    'ar': 'يرجى اختيار دولة واحدة على الأقل 🌍',
    'it': 'Seleziona almeno 1 paese 🌍',
    'hi': 'कृपया कम से कम 1 देश चुनें 🌍',
    'th': 'กรุณาเลือกอย่างน้อย 1 ประเทศ 🌍',
  });

  String composeExpressBulkSent(int countries, int addresses, int total) => _t({
    'ko': '⚡🌍 특송+대량! ${countries}개 나라 × $addresses주소 = 총 ${total}통 즉시 발송!',
    'en': '⚡🌍 Express+Bulk! $countries countries × $addresses addresses = $total promos sent!',
    'ja': '⚡🌍 特送+大量！${countries}か国 × $addressesアドレス = 合計${total}通即時発送！',
    'zh': '⚡🌍 特快+批量！$countries个国家 × $addresses个地址 = 共${total}封即时发送！',
    'fr': '⚡🌍 Express+Masse ! $countries pays × $addresses adresses = $total lettres envoyées !',
    'de': '⚡🌍 Express+Masse! $countries Länder × $addresses Adressen = $total Briefe gesendet!',
    'es': '⚡🌍 ¡Exprés+Masivo! $countries países × $addresses direcciones = ¡$total cartas enviadas!',
    'pt': '⚡🌍 Expresso+Massa! $countries países × $addresses endereços = $total cartas enviadas!',
    'ru': '⚡🌍 Экспресс+Массовая! $countries стран × $addresses адресов = $total писем отправлено!',
    'tr': '⚡🌍 Hızlı+Toplu! $countries ülke × $addresses adres = toplam $total mektup gönderildi!',
    'ar': '⚡🌍 سريع+جماعي! $countries دول × $addresses عناوين = إجمالي $total رسالة!',
    'it': '⚡🌍 Express+Massa! $countries paesi × $addresses indirizzi = $total lettere inviate!',
    'hi': '⚡🌍 एक्सप्रेस+बल्क! $countries देश × $addresses पते = कुल $total पत्र भेजे!',
    'th': '⚡🌍 ด่วน+จำนวนมาก! $countries ประเทศ × $addresses ที่อยู่ = รวม $total ฉบับส่งแล้ว!',
  });

  String composeBulkSent(int total, int countries) => _t({
    'ko': '🌍  총 ${total}통의 혜택이 ${countries}개 나라로 출발했어요!',
    'en': '🌍  $total promos departed to $countries countries!',
    'ja': '🌍  合計${total}通の手紙が${countries}か国へ出発しました！',
    'zh': '🌍  共${total}封信已发往${countries}个国家！',
    'fr': '🌍  $total lettres envoyées vers $countries pays !',
    'de': '🌍  $total Briefe an $countries Länder gesendet!',
    'es': '🌍  ¡$total cartas enviadas a $countries países!',
    'pt': '🌍  $total cartas enviadas para $countries países!',
    'ru': '🌍  $total писем отправлено в $countries стран!',
    'tr': '🌍  $total mektup $countries ülkeye yola çıktı!',
    'ar': '🌍  تم إرسال $total رسالة إلى $countries دولة!',
    'it': '🌍  $total lettere inviate in $countries paesi!',
    'hi': '🌍  $total पत्र $countries देशों को भेजे गए!',
    'th': '🌍  ส่งจดหมาย $total ฉบับไป $countries ประเทศแล้ว!',
  });

  String composeEstMinutes(int min) => _t({
    'ko': '약 ${min}분 후 도착 예정',
    'en': 'Estimated arrival in ~$min min',
    'ja': '約${min}分後に到着予定',
    'zh': '约${min}分钟后到达',
    'fr': 'Arrivée prévue dans ~$min min',
    'de': 'Voraussichtliche Ankunft in ~$min Min.',
    'es': 'Llegada estimada en ~$min min',
    'pt': 'Chegada estimada em ~$min min',
    'ru': 'Прибытие примерно через $min мин',
    'tr': '~$min dk sonra varış tahmini',
    'ar': 'الوصول المتوقع خلال ~$min دقيقة',
    'it': 'Arrivo stimato in ~$min min',
    'hi': '~$min मिनट में पहुंचने का अनुमान',
    'th': 'คาดว่าจะถึงใน ~$min นาที',
  });

  String composeEstHours(int hours) => _t({
    'ko': '약 ${hours}시간 후 도착 예정',
    'en': 'Estimated arrival in ~$hours hr',
    'ja': '約${hours}時間後に到着予定',
    'zh': '约${hours}小时后到达',
    'fr': 'Arrivée prévue dans ~$hours h',
    'de': 'Voraussichtliche Ankunft in ~$hours Std.',
    'es': 'Llegada estimada en ~$hours h',
    'pt': 'Chegada estimada em ~$hours h',
    'ru': 'Прибытие примерно через $hours ч',
    'tr': '~$hours saat sonra varış tahmini',
    'ar': 'الوصول المتوقع خلال ~$hours ساعة',
    'it': 'Arrivo stimato in ~$hours ore',
    'hi': '~$hours घंटे में पहुंचने का अनुमान',
    'th': 'คาดว่าจะถึงใน ~$hours ชั่วโมง',
  });

  String composeEstDays(int days) => _t({
    'ko': '약 ${days}일 후 도착 예정',
    'en': 'Estimated arrival in ~$days days',
    'ja': '約${days}日後に到着予定',
    'zh': '约${days}天后到达',
    'fr': 'Arrivée prévue dans ~$days jours',
    'de': 'Voraussichtliche Ankunft in ~$days Tagen',
    'es': 'Llegada estimada en ~$days días',
    'pt': 'Chegada estimada em ~$days dias',
    'ru': 'Прибытие примерно через $days дн.',
    'tr': '~$days gün sonra varış tahmini',
    'ar': 'الوصول المتوقع خلال ~$days يوم',
    'it': 'Arrivo stimato in ~$days giorni',
    'hi': '~$days दिन में पहुंचने का अनुमान',
    'th': 'คาดว่าจะถึงใน ~$days วัน',
  });

  String composeReplySent(String name) => _t({
    'ko': '💌  답장이 ${name}에게 출발했어요!',
    'en': '💌  Your reply to $name is on its way!',
    'ja': '💌  ${name}への返信が出発しました！',
    'zh': '💌  给${name}的回信已出发！',
    'fr': '💌  Votre réponse à $name est en route !',
    'de': '💌  Ihre Antwort an $name ist unterwegs!',
    'es': '💌  ¡Tu respuesta a $name va en camino!',
    'pt': '💌  Sua resposta para $name está a caminho!',
    'ru': '💌  Ваш ответ для $name отправлен!',
    'tr': '💌  $name\'a yanıtınız yola çıktı!',
    'ar': '💌  ردك إلى $name في الطريق!',
    'it': '💌  La tua risposta a $name è in viaggio!',
    'hi': '💌  $name को आपका जवाब भेज दिया गया!',
    'th': '💌  จดหมายตอบถึง $name ออกเดินทางแล้ว!',
  });

  String get composeExpressSentRandomBrand => _t({
    'ko': '⚡ 특급 혜택이 5분 내 세계 어딘가로 출발했어요!',
    'en': '⚡ Express promo departed somewhere in the world within 5 min!',
    'ja': '⚡ 特急手紙が5分以内に世界のどこかへ出発しました！',
    'zh': '⚡ 特快信5分钟内发往世界某处！',
    'fr': '⚡ Lettre express envoyée quelque part dans le monde en 5 min !',
    'de': '⚡ Expressbrief innerhalb von 5 Min. irgendwohin gesendet!',
    'es': '⚡ ¡Carta exprés enviada a algún lugar del mundo en 5 min!',
    'pt': '⚡ Carta expressa enviada para algum lugar do mundo em 5 min!',
    'ru': '⚡ Экспресс-письмо отправлено куда-то в мире за 5 мин!',
    'tr': '⚡ Hızlı mektup 5 dk içinde dünyada bir yere gönderildi!',
    'ar': '⚡ رسالة سريعة أُرسلت إلى مكان ما في العالم خلال 5 دقائق!',
    'it': '⚡ Lettera express inviata da qualche parte nel mondo in 5 min!',
    'hi': '⚡ एक्सप्रेस पत्र 5 मिनट में दुनिया में कहीं भेजा गया!',
    'th': '⚡ จดหมายด่วนออกเดินทางไปที่ไหนสักแห่งในโลกภายใน 5 นาที!',
  });

  String get composeExpressSentRandomPremium => _t({
    'ko': '⚡ 특급 혜택이 20분 내 세계 어딘가로 출발했어요!',
    'en': '⚡ Express promo departed somewhere in the world within 20 min!',
    'ja': '⚡ 特急手紙が20分以内に世界のどこかへ出発しました！',
    'zh': '⚡ 特快信20分钟内发往世界某处！',
    'fr': '⚡ Lettre express envoyée quelque part dans le monde en 20 min !',
    'de': '⚡ Expressbrief innerhalb von 20 Min. irgendwohin gesendet!',
    'es': '⚡ ¡Carta exprés enviada a algún lugar del mundo en 20 min!',
    'pt': '⚡ Carta expressa enviada para algum lugar do mundo em 20 min!',
    'ru': '⚡ Экспресс-письмо отправлено куда-то в мире за 20 мин!',
    'tr': '⚡ Hızlı mektup 20 dk içinde dünyada bir yere gönderildi!',
    'ar': '⚡ رسالة سريعة أُرسلت إلى مكان ما في العالم خلال 20 دقيقة!',
    'it': '⚡ Lettera express inviata da qualche parte nel mondo in 20 min!',
    'hi': '⚡ एक्सप्रेस पत्र 20 मिनट में दुनिया में कहीं भेजा गया!',
    'th': '⚡ จดหมายด่วนออกเดินทางไปที่ไหนสักแห่งในโลกภายใน 20 นาที!',
  });

  String composeExpressSentTo(String flag, String country) => _t({
    'ko': '⚡ 특급 혜택이 $flag ${country}로 출발했어요!',
    'en': '⚡ Express promo departed to $flag $country!',
    'ja': '⚡ 特急手紙が$flag ${country}へ出発しました！',
    'zh': '⚡ 特快信已发往$flag $country！',
    'fr': '⚡ Lettre express envoyée vers $flag $country !',
    'de': '⚡ Expressbrief nach $flag $country gesendet!',
    'es': '⚡ ¡Carta exprés enviada a $flag $country!',
    'pt': '⚡ Carta expressa enviada para $flag $country!',
    'ru': '⚡ Экспресс-письмо отправлено в $flag $country!',
    'tr': '⚡ Hızlı mektup $flag $country\'ya gönderildi!',
    'ar': '⚡ رسالة سريعة أُرسلت إلى $flag $country!',
    'it': '⚡ Lettera express inviata a $flag $country!',
    'hi': '⚡ एक्सप्रेस पत्र $flag $country को भेजा गया!',
    'th': '⚡ จดหมายด่วนออกเดินทางไป $flag $country แล้ว!',
  });

  String get composeLetterSentRandom => _t({
    'ko': '✈️  혜택이 세상 어딘가로 출발했어요! 🌍',
    'en': '✈️  Your promo departed somewhere in the world! 🌍',
    'ja': '✈️  手紙が世界のどこかへ出発しました！🌍',
    'zh': '✈️  信件已发往世界某处！🌍',
    'fr': '✈️  Votre lettre est partie quelque part dans le monde ! 🌍',
    'de': '✈️  Ihr Brief ist irgendwohin in die Welt unterwegs! 🌍',
    'es': '✈️  ¡Tu carta partió a algún lugar del mundo! 🌍',
    'pt': '✈️  Sua carta partiu para algum lugar do mundo! 🌍',
    'ru': '✈️  Ваше письмо отправилось куда-то в мир! 🌍',
    'tr': '✈️  Mektubunuz dünyada bir yere yola çıktı! 🌍',
    'ar': '✈️  رسالتك انطلقت إلى مكان ما في العالم! 🌍',
    'it': '✈️  La tua lettera è partita da qualche parte nel mondo! 🌍',
    'hi': '✈️  आपका पत्र दुनिया में कहीं भेज दिया गया! 🌍',
    'th': '✈️  จดหมายออกเดินทางไปที่ไหนสักแห่งในโลกแล้ว! 🌍',
  });

  String composeLetterSentTo(String flag, String country) => _t({
    'ko': '✈️  혜택이 $flag ${country}로 출발했어요!',
    'en': '✈️  Your promo departed to $flag $country!',
    'ja': '✈️  手紙が$flag ${country}へ出発しました！',
    'zh': '✈️  信件已发往$flag $country！',
    'fr': '✈️  Votre lettre est partie vers $flag $country !',
    'de': '✈️  Ihr Brief ist nach $flag $country unterwegs!',
    'es': '✈️  ¡Tu carta partió a $flag $country!',
    'pt': '✈️  Sua carta partiu para $flag $country!',
    'ru': '✈️  Ваше письмо отправилось в $flag $country!',
    'tr': '✈️  Mektubunuz $flag $country\'ya yola çıktı!',
    'ar': '✈️  رسالتك انطلقت إلى $flag $country!',
    'it': '✈️  La tua lettera è partita per $flag $country!',
    'hi': '✈️  आपका पत्र $flag $country को भेजा गया!',
    'th': '✈️  จดหมายออกเดินทางไป $flag $country แล้ว!',
  });

  String composeExpressLimitUsed(int limit) => _t({
    'ko': '⚡ 오늘 특급 배송 ${limit}통을 모두 사용했어요. 내일 다시 사용할 수 있어요.',
    'en': '⚡ You\'ve used all $limit express deliveries today. Available again tomorrow.',
    'ja': '⚡ 本日の特急配送${limit}通をすべて使いました。明日また利用できます。',
    'zh': '⚡ 今天的$limit封特快已全部使用。明天可再次使用。',
    'fr': '⚡ Vous avez utilisé les $limit envois express aujourd\'hui. Disponible demain.',
    'de': '⚡ Sie haben alle $limit Expresslieferungen heute genutzt. Morgen wieder verfügbar.',
    'es': '⚡ Has usado los $limit envíos exprés de hoy. Disponible mañana.',
    'pt': '⚡ Você usou todas as $limit entregas expressas hoje. Disponível amanhã.',
    'ru': '⚡ Вы использовали все $limit экспресс-доставок сегодня. Доступно снова завтра.',
    'tr': '⚡ Bugünkü $limit hızlı gönderimi kullandınız. Yarın tekrar kullanabilirsiniz.',
    'ar': '⚡ استخدمت جميع عمليات التوصيل السريع $limit اليوم. متاح مرة أخرى غدًا.',
    'it': '⚡ Hai usato tutte le $limit consegne express oggi. Disponibile domani.',
    'hi': '⚡ आज की सभी $limit एक्सप्रेस डिलीवरी उपयोग हो गईं। कल फिर उपलब्ध।',
    'th': '⚡ ใช้จดหมายด่วนครบ $limit ฉบับแล้ววันนี้ ใช้ได้อีกครั้งพรุ่งนี้',
  });

  String get composeWriteReply => _t({
    'ko': '답장 쓰기',
    'en': 'Write Reply',
    'ja': '返信を書く',
    'zh': '写回信',
    'fr': 'Écrire une réponse',
    'de': 'Antwort schreiben',
    'es': 'Escribir respuesta',
    'pt': 'Escrever resposta',
    'ru': 'Написать ответ',
    'tr': 'Yanıt yaz',
    'ar': 'كتابة رد',
    'it': 'Scrivi risposta',
    'hi': 'जवाब लिखें',
    'th': 'เขียนตอบ',
  });

  String get composeDestination => _t({
    'ko': '혜택을 보낼 목적지',
    'en': 'Promo destination',
    'ja': '手紙の送り先',
    'zh': '信件目的地',
    'fr': 'Destination de la lettre',
    'de': 'Briefziel',
    'es': 'Destino de la carta',
    'pt': 'Destino da carta',
    'ru': 'Место назначения письма',
    'tr': 'Mektup hedefi',
    'ar': 'وجهة الرسالة',
    'it': 'Destinazione lettera',
    'hi': 'पत्र गंतव्य',
    'th': 'ปลายทางจดหมาย',
  });

  String get composeRandom => _t({
    'ko': '랜덤',
    'en': 'Random',
    'ja': 'ランダム',
    'zh': '随机',
    'fr': 'Aléatoire',
    'de': 'Zufällig',
    'es': 'Aleatorio',
    'pt': 'Aleatório',
    'ru': 'Случайно',
    'tr': 'Rastgele',
    'ar': 'عشوائي',
    'it': 'Casuale',
    'hi': 'रैंडम',
    'th': 'สุ่ม',
  });

  String get composeSomewhereInWorld => _t({
    'ko': '세계 어딘가로',
    'en': 'Somewhere in the world',
    'ja': '世界のどこかへ',
    'zh': '世界某处',
    'fr': 'Quelque part dans le monde',
    'de': 'Irgendwo auf der Welt',
    'es': 'A algún lugar del mundo',
    'pt': 'Algum lugar do mundo',
    'ru': 'Куда-то в мире',
    'tr': 'Dünyada bir yere',
    'ar': 'مكان ما في العالم',
    'it': 'Da qualche parte nel mondo',
    'hi': 'दुनिया में कहीं',
    'th': 'ที่ไหนสักแห่งในโลก',
  });

  String get composeTapToChange => _t({
    'ko': '탭해서 변경',
    'en': 'Tap to change',
    'ja': 'タップして変更',
    'zh': '点击更改',
    'fr': 'Appuyez pour changer',
    'de': 'Tippen zum Ändern',
    'es': 'Toca para cambiar',
    'pt': 'Toque para alterar',
    'ru': 'Нажмите для изменения',
    'tr': 'Değiştirmek için dokun',
    'ar': 'انقر للتغيير',
    'it': 'Tocca per cambiare',
    'hi': 'बदलने के लिए टैप करें',
    'th': 'แตะเพื่อเปลี่ยน',
  });

  String get composeChooseDirectly => _t({
    'ko': '직접 선택하기',
    'en': 'Choose directly',
    'ja': '直接選択',
    'zh': '直接选择',
    'fr': 'Choisir directement',
    'de': 'Direkt auswählen',
    'es': 'Elegir directamente',
    'pt': 'Escolher diretamente',
    'ru': 'Выбрать напрямую',
    'tr': 'Doğrudan seç',
    'ar': 'اختر مباشرة',
    'it': 'Scegli direttamente',
    'hi': 'सीधे चुनें',
    'th': 'เลือกเอง',
  });

  String get composeBrandExpressOn => _t({
    'ko': '브랜드 특급 배송 ON · 5분 내 도착',
    'en': 'Brand Express ON · Arrives in 5 min',
    'ja': 'ブランド特急配送 ON · 5分以内に到着',
    'zh': '品牌特快 ON · 5分钟内到达',
    'fr': 'Express Marque ON · Arrivée en 5 min',
    'de': 'Marken-Express AN · Ankunft in 5 Min.',
    'es': 'Express Marca ON · Llega en 5 min',
    'pt': 'Express Marca ON · Chega em 5 min',
    'ru': 'Бренд Экспресс ВКЛ · Доставка за 5 мин',
    'tr': 'Marka Hızlı AÇIK · 5 dk içinde varış',
    'ar': 'توصيل العلامة التجارية السريع مفعّل · يصل خلال 5 دقائق',
    'it': 'Express Brand ON · Arrivo in 5 min',
    'hi': 'ब्रांड एक्सप्रेस ON · 5 मिनट में पहुंचेगा',
    'th': 'แบรนด์ด่วน เปิด · ถึงใน 5 นาที',
  });

  String get composeBrandExpress => _t({
    'ko': '브랜드 특급 배송 (5분 즉시 배송)',
    'en': 'Brand Express (5 min instant delivery)',
    'ja': 'ブランド特急配送（5分即時配送）',
    'zh': '品牌特快（5分钟即时配送）',
    'fr': 'Express Marque (livraison instantanée 5 min)',
    'de': 'Marken-Express (5 Min. Sofortlieferung)',
    'es': 'Express Marca (entrega instantánea 5 min)',
    'pt': 'Express Marca (entrega instantânea 5 min)',
    'ru': 'Бренд Экспресс (доставка за 5 мин)',
    'tr': 'Marka Hızlı (5 dk anında teslimat)',
    'ar': 'توصيل العلامة التجارية السريع (توصيل فوري 5 دقائق)',
    'it': 'Express Brand (consegna istantanea 5 min)',
    'hi': 'ब्रांड एक्सप्रेस (5 मिनट तुरंत डिलीवरी)',
    'th': 'แบรนด์ด่วน (ส่งทันทีใน 5 นาที)',
  });

  String composePremiumExpressOn(int used, int limit) => _t({
    'ko': '프리미엄 특급 배송 ON · $used/${limit}통 사용',
    'en': 'Premium Express ON · $used/$limit used',
    'ja': 'プレミアム特急配送 ON · $used/${limit}通使用',
    'zh': '高级特快 ON · 已用$used/$limit封',
    'fr': 'Express Premium ON · $used/$limit utilisés',
    'de': 'Premium-Express AN · $used/$limit genutzt',
    'es': 'Express Premium ON · $used/$limit usados',
    'pt': 'Express Premium ON · $used/$limit usados',
    'ru': 'Премиум Экспресс ВКЛ · $used/$limit использовано',
    'tr': 'Premium Hızlı AÇIK · $used/$limit kullanıldı',
    'ar': 'توصيل مميز سريع مفعّل · $used/$limit مستخدم',
    'it': 'Express Premium ON · $used/$limit usati',
    'hi': 'प्रीमियम एक्सप्रेस ON · $used/$limit उपयोग',
    'th': 'พรีเมียมด่วน เปิด · ใช้แล้ว $used/$limit',
  });

  // Build 186: 프리미엄 특급 배송이 오늘 다 소진됐을 때 리셋 시각 안내.
  // 현재 구현상 midnight local 리셋이므로 "내일 00시" 로 표시.
  String get composePremiumExpressResetAt => _t({
    'ko': '💫 내일 00시 자동 리필',
    'en': '💫 Refills at midnight',
    'ja': '💫 深夜0時にリフィル',
    'zh': '💫 凌晨 0 点刷新',
    'fr': '💫 Recharge à minuit',
    'de': '💫 Setzt um Mitternacht zurück',
    'es': '💫 Se recarga a medianoche',
    'pt': '💫 Recarrega à meia-noite',
    'ru': '💫 Сброс в полночь',
    'tr': '💫 Gece yarısı yenilenir',
    'ar': '💫 يُعاد عند منتصف الليل',
    'it': '💫 Si ricarica a mezzanotte',
    'hi': '💫 आधी रात को रिफिल',
    'th': '💫 เติมใหม่เที่ยงคืน',
  });

  String composePremiumExpress(int limit) => _t({
    'ko': '프리미엄 특급 배송 (하루 ${limit}통)',
    'en': 'Premium Express ($limit/day)',
    'ja': 'プレミアム特急配送（1日${limit}通）',
    'zh': '高级特快（每天${limit}封）',
    'fr': 'Express Premium ($limit/jour)',
    'de': 'Premium-Express ($limit/Tag)',
    'es': 'Express Premium ($limit/día)',
    'pt': 'Express Premium ($limit/dia)',
    'ru': 'Премиум Экспресс ($limit/день)',
    'tr': 'Premium Hızlı (günde $limit)',
    'ar': 'توصيل مميز سريع ($limit/يوم)',
    'it': 'Express Premium ($limit/giorno)',
    'hi': 'प्रीमियम एक्सप्रेस ($limit/दिन)',
    'th': 'พรีเมียมด่วน ($limit/วัน)',
  });

  String get composeExpressDelivery => _t({
    'ko': '특급 배송',
    'en': 'Express Delivery',
    'ja': '特急配送',
    'zh': '特快配送',
    'fr': 'Livraison express',
    'de': 'Expresslieferung',
    'es': 'Envío exprés',
    'pt': 'Entrega expressa',
    'ru': 'Экспресс-доставка',
    'tr': 'Hızlı teslimat',
    'ar': 'توصيل سريع',
    'it': 'Consegna express',
    'hi': 'एक्सप्रेस डिलीवरी',
    'th': 'จัดส่งด่วน',
  });

  String get composeExpressDeliveryDesc => _t({
    'ko': '특급 배송은 Premium 전용 기능이에요.\n업그레이드하면 하루 3통까지 즉시 배송할 수 있어요.',
    'en': 'Express delivery is a Premium-only feature.\nUpgrade to send up to 3 instant deliveries per day.',
    'ja': '特急配送はプレミアム専用機能です。\nアップグレードすると1日3通まで即時配送できます。',
    'zh': '特快配送是高级专属功能。\n升级后每天可即时配送最多3封。',
    'fr': 'La livraison express est réservée aux Premium.\nMettez à niveau pour 3 livraisons instantanées par jour.',
    'de': 'Expresslieferung ist eine Premium-Funktion.\nUpgraden Sie für bis zu 3 Sofortlieferungen pro Tag.',
    'es': 'El envío exprés es exclusivo de Premium.\nActualiza para 3 envíos instantáneos al día.',
    'pt': 'Entrega expressa é exclusiva para Premium.\nAtualize para 3 entregas instantâneas por dia.',
    'ru': 'Экспресс-доставка — функция Premium.\nОбновитесь для 3 мгновенных доставок в день.',
    'tr': 'Hızlı teslimat Premium\'a özel bir özelliktir.\nGünde 3 anında teslimat için yükseltin.',
    'ar': 'التوصيل السريع ميزة حصرية للمميزين.\nقم بالترقية لإرسال حتى 3 توصيلات فورية يوميًا.',
    'it': 'La consegna express è solo per Premium.\nAggiorna per 3 consegne istantanee al giorno.',
    'hi': 'एक्सप्रेस डिलीवरी प्रीमियम-ओनली सुविधा है।\nअपग्रेड करें, प्रतिदिन 3 तुरंत डिलीवरी।',
    'th': 'จัดส่งด่วนเป็นฟีเจอร์ Premium เท่านั้น\nอัปเกรดเพื่อส่งด่วนได้วันละ 3 ฉบับ',
  });

  String get composeExpressLocked => _t({
    'ko': '특급 배송 · Premium 하루 3통',
    'en': 'Express Delivery · Premium · 3 / day',
    'ja': '特急配送 · Premium · 1日3通',
    'zh': '特快配送 · Premium · 每天3封',
    'fr': 'Livraison express · Premium · 3 / jour',
    'de': 'Expresslieferung · Premium · 3 / Tag',
    'es': 'Envío exprés · Premium · 3 / día',
    'pt': 'Entrega expressa · Premium · 3 / dia',
    'ru': 'Экспресс-доставка · Premium · 3 / день',
    'tr': 'Hızlı teslimat · Premium · 3 / gün',
    'ar': 'توصيل سريع · Premium · 3 / يوم',
    'it': 'Consegna express · Premium · 3 / giorno',
    'hi': 'एक्सप्रेस डिलीवरी · Premium · 3 / दिन',
    'th': 'จัดส่งด่วน · Premium · 3 / วัน',
  });

  String get composeLuckyApplied => _t({
    'ko': '오늘의 혜택 적용됨 · 탭하면 다른 글귀로',
    'en': 'Today\'s promo applied · Tap for another quote',
    'ja': '今日の手紙適用済み · タップで別の文章へ',
    'zh': '今日之信已应用 · 点击更换',
    'fr': 'Lettre du jour appliquée · Tapez pour changer',
    'de': 'Brief des Tages angewendet · Tippen für anderes Zitat',
    'es': 'Carta del día aplicada · Toca para otra frase',
    'pt': 'Carta do dia aplicada · Toque para outra frase',
    'ru': 'Письмо дня применено · Нажмите для другой цитаты',
    'tr': 'Günün mektubu uygulandı · Başka alıntı için dokun',
    'ar': 'تم تطبيق رسالة اليوم · انقر لعبارة أخرى',
    'it': 'Lettera del giorno applicata · Tocca per un\'altra citazione',
    'hi': 'आज का पत्र लागू · दूसरे उद्धरण के लिए टैप करें',
    'th': 'จดหมายวันนี้ถูกใช้แล้ว · แตะเพื่อเปลี่ยนข้อความ',
  });

  String get composeLuckySend => _t({
    'ko': '오늘의 혜택으로 보내기',
    'en': 'Send as today\'s promo',
    'ja': '今日の手紙として送る',
    'zh': '发送今日之信',
    'fr': 'Envoyer comme lettre du jour',
    'de': 'Als Brief des Tages senden',
    'es': 'Enviar como carta del día',
    'pt': 'Enviar como carta do dia',
    'ru': 'Отправить как письмо дня',
    'tr': 'Günün mektubu olarak gönder',
    'ar': 'أرسل كرسالة اليوم',
    'it': 'Invia come lettera del giorno',
    'hi': 'आज के पत्र के रूप में भेजें',
    'th': 'ส่งเป็นจดหมายวันนี้',
  });

  String get composeLuckyAppliedSub => _t({
    'ko': '내용을 직접 수정하거나 그대로 발송할 수 있어요',
    'en': 'You can edit the content or send as is',
    'ja': '内容を編集するかそのまま送信できます',
    'zh': '可以编辑内容或直接发送',
    'fr': 'Vous pouvez modifier le contenu ou l\'envoyer tel quel',
    'de': 'Sie können den Inhalt bearbeiten oder so senden',
    'es': 'Puedes editar el contenido o enviarlo tal cual',
    'pt': 'Você pode editar o conteúdo ou enviar como está',
    'ru': 'Можете отредактировать содержимое или отправить как есть',
    'tr': 'İçeriği düzenleyebilir veya olduğu gibi gönderebilirsiniz',
    'ar': 'يمكنك تعديل المحتوى أو إرساله كما هو',
    'it': 'Puoi modificare il contenuto o inviarlo così com\'è',
    'hi': 'आप सामग्री संपादित कर सकते हैं या जैसी है भेज सकते हैं',
    'th': 'แก้ไขเนื้อหาหรือส่งตามที่เป็นอยู่ได้',
  });

  String get composeLuckySendSub => _t({
    'ko': '좋은 글귀가 자동으로 채워져요 · 수정도 가능해요',
    'en': 'A nice quote will be auto-filled · You can edit it too',
    'ja': '素敵な文章が自動入力されます · 編集も可能',
    'zh': '好的文字会自动填充 · 也可以编辑',
    'fr': 'Une belle citation sera auto-remplie · Modifiable aussi',
    'de': 'Ein schönes Zitat wird automatisch eingefügt · Bearbeitbar',
    'es': 'Se llenará automáticamente con una frase bonita · También editable',
    'pt': 'Uma frase bonita será preenchida · Editável também',
    'ru': 'Хорошая цитата будет заполнена автоматически · Можно редактировать',
    'tr': 'Güzel bir alıntı otomatik doldurulacak · Düzenlenebilir',
    'ar': 'سيتم ملء عبارة جميلة تلقائيًا · يمكنك تعديلها أيضًا',
    'it': 'Una bella citazione verrà inserita · Modificabile anche',
    'hi': 'एक अच्छा उद्धरण स्वतः भरा जाएगा · संपादन भी संभव',
    'th': 'ข้อความดีๆ จะถูกเติมอัตโนมัติ · แก้ไขได้ด้วย',
  });

  String composeReplyTo(String name) => _t({
    'ko': '${name}에게 답장',
    'en': 'Reply to $name',
    'ja': '${name}への返信',
    'zh': '回复$name',
    'fr': 'Répondre à $name',
    'de': 'Antwort an $name',
    'es': 'Respuesta a $name',
    'pt': 'Resposta para $name',
    'ru': 'Ответ для $name',
    'tr': '$name\'a yanıt',
    'ar': 'رد على $name',
    'it': 'Risposta a $name',
    'hi': '$name को जवाब',
    'th': 'ตอบ $name',
  });

  // 컴포즈 "더 많은 옵션" 접이식 섹션 헤더 (본문 아래 부가 옵션 묶음)
  String get composeOptionsSectionTitle => _t({
    'ko': '더 많은 옵션',
    'en': 'More options',
    'ja': 'さらにオプション',
    'zh': '更多选项',
    'fr': 'Plus d\'options',
    'de': 'Weitere Optionen',
    'es': 'Más opciones',
    'pt': 'Mais opções',
    'ru': 'Дополнительно',
    'tr': 'Daha fazla seçenek',
    'ar': 'المزيد من الخيارات',
    'it': 'Altre opzioni',
    'hi': 'और विकल्प',
    'th': 'ตัวเลือกเพิ่มเติม',
  });

  String get composeLetterFlows => _t({
    'ko': '이 혜택은 세상 어딘가로 흘러갑니다',
    'en': 'This promo will flow somewhere in the world',
    'ja': 'この手紙は世界のどこかへ流れていきます',
    'zh': '这封信将流向世界的某个角落',
    'fr': 'Cette lettre voyagera quelque part dans le monde',
    'de': 'Dieser Brief wird irgendwohin in die Welt fließen',
    'es': 'Esta carta fluirá a algún lugar del mundo',
    'pt': 'Esta carta fluirá para algum lugar do mundo',
    'ru': 'Это письмо уплывёт куда-то в мир',
    'tr': 'Bu mektup dünyanın bir yerine akacak',
    'ar': 'ستنساب هذه الرسالة إلى مكان ما في العالم',
    'it': 'Questa lettera viaggerà da qualche parte nel mondo',
    'hi': 'यह पत्र दुनिया में कहीं बहेगा',
    'th': 'จดหมายนี้จะลอยไปที่ไหนสักแห่งในโลก',
  });

  String composeMinCharsNeeded(int remaining) => _t({
    'ko': '최소 20자 필요 (${remaining}자 더)',
    'en': 'Min 20 chars needed ($remaining more)',
    'ja': '最低20文字必要（あと${remaining}文字）',
    'zh': '至少需要20字（还差${remaining}字）',
    'fr': '20 caractères min. requis ($remaining de plus)',
    'de': 'Min. 20 Zeichen erforderlich (noch $remaining)',
    'es': 'Mín. 20 caracteres ($remaining más)',
    'pt': 'Mín. 20 caracteres (faltam $remaining)',
    'ru': 'Нужно мин. 20 символов (ещё $remaining)',
    'tr': 'En az 20 karakter gerekli ($remaining daha)',
    'ar': 'مطلوب 20 حرفًا على الأقل ($remaining إضافي)',
    'it': 'Min. 20 caratteri necessari ($remaining in più)',
    'hi': 'न्यूनतम 20 अक्षर ($remaining और)',
    'th': 'ต้องการอย่างน้อย 20 ตัวอักษร (อีก $remaining)',
  });

  String get composeMinCharsMet => _t({
    'ko': '최소 글자수 충족',
    'en': 'Minimum met',
    'ja': '最低文字数クリア',
    'zh': '已满足最少字数',
    'fr': 'Minimum atteint',
    'de': 'Minimum erreicht',
    'es': 'Mínimo alcanzado',
    'pt': 'Mínimo atingido',
    'ru': 'Минимум достигнут',
    'tr': 'Minimum karşılandı',
    'ar': 'تم استيفاء الحد الأدنى',
    'it': 'Minimo raggiunto',
    'hi': 'न्यूनतम पूर्ण',
    'th': 'ถึงจำนวนขั้นต่ำแล้ว',
  });

  String get composeBrandCategoryLabel => _t({
    'ko': '혜택 종류',
    'en': 'Reward category',
    'ja': '手紙の種類',
    'zh': '信件类型',
    'fr': 'Type de lettre',
    'de': 'Briefkategorie',
    'es': 'Tipo de carta',
    'pt': 'Categoria da carta',
    'ru': 'Категория письма',
    'tr': 'Mektup türü',
    'ar': 'فئة الرسالة',
    'it': 'Categoria lettera',
    'hi': 'पत्र श्रेणी',
    'th': 'ประเภทจดหมาย',
  });
  String get composeBrandCategoryGeneral => _t({
    'ko': '일반',
    'en': 'Regular',
    'ja': '通常',
    'zh': '普通',
    'fr': 'Ordinaire',
    'de': 'Regulär',
    'es': 'Regular',
    'pt': 'Regular',
    'ru': 'Обычное',
    'tr': 'Normal',
    'ar': 'عادية',
    'it': 'Standard',
    'hi': 'सामान्य',
    'th': 'ทั่วไป',
  });
  String get composeBrandCategoryCoupon => _t({
    'ko': '할인권',
    'en': 'Discount',
    'ja': '割引券',
    'zh': '折扣券',
    'fr': 'Réduction',
    'de': 'Rabatt',
    'es': 'Descuento',
    'pt': 'Desconto',
    'ru': 'Скидка',
    'tr': 'İndirim',
    'ar': 'خصم',
    'it': 'Sconto',
    'hi': 'छूट',
    'th': 'ส่วนลด',
  });
  String get composeBrandCategoryVoucher => _t({
    'ko': '교환권',
    'en': 'Voucher',
    'ja': '引換券',
    'zh': '兑换券',
    'fr': 'Bon',
    'de': 'Gutschein',
    'es': 'Vale',
    'pt': 'Vale',
    'ru': 'Ваучер',
    'tr': 'Fiş',
    'ar': 'قسيمة',
    'it': 'Buono',
    'hi': 'वाउचर',
    'th': 'บัตรแลก',
  });

  // Build 223: Premium 전용 — 일반 홍보 발송 축소 + 홍보 혜택으로 직관 리프레임.
  // Free/Brand 가 아닌 Premium 사용자는 카테고리 3종(general/coupon/voucher)
  // 칩 대신 "📣 내 홍보 편지" 단일 배지를 본다.
  String get composePremiumPromoLabel => _t({
    'ko': '📣 내 홍보 메시지',
    'en': '📣 My Promo Message',
    'ja': '📣 マイ宣伝レター',
    'zh': '📣 我的推广信',
    'fr': '📣 Ma lettre promo',
    'de': '📣 Mein Promo-Brief',
    'es': '📣 Mi carta promo',
    'pt': '📣 Minha carta promo',
    'ru': '📣 Моё промо-письмо',
    'tr': '📣 Promo Mektubum',
    'ar': '📣 رسالتي الترويجية',
    'it': '📣 La mia lettera promo',
    'hi': '📣 मेरा प्रोमो लेटर',
    'th': '📣 จดหมายโปรของฉัน',
  });

  String get composePremiumPromoDesc => _t({
    'ko': '내 SNS · 채널 · 제품을 1km 반경 사용자에게 자동 노출. 📸 사진 + 🔗 링크 첨부 가능.',
    'en': 'Auto-promote your SNS · channel · product to users within 1 km. Attach 📸 photo + 🔗 link.',
    'ja': '自分のSNS・チャンネル・商品を1km圏内のユーザーに自動配信。📸 写真 + 🔗 リンク添付可。',
    'zh': '自动向 1 公里内用户推送你的 SNS · 频道 · 产品。可附 📸 照片 + 🔗 链接。',
    'fr': 'Promeut auto. ton SNS · chaîne · produit aux utilisateurs à 1 km. 📸 photo + 🔗 lien.',
    'de': 'Bewerbe deine SNS · Kanal · Produkt automatisch im 1-km-Radius. 📸 Foto + 🔗 Link.',
    'es': 'Promociona tu SNS · canal · producto a usuarios en 1 km. 📸 foto + 🔗 enlace.',
    'pt': 'Promove SNS · canal · produto para utilizadores a 1 km. 📸 foto + 🔗 link.',
    'ru': 'Авто-продвижение SNS · канала · продукта в радиусе 1 км. 📸 фото + 🔗 ссылка.',
    'tr': 'SNS · kanal · ürününü 1 km içindeki kullanıcılara otomatik tanıt. 📸 foto + 🔗 link.',
    'ar': 'روّج لـ SNS · قناتك · منتجك تلقائيًا للمستخدمين ضمن 1 كم. 📸 صورة + 🔗 رابط.',
    'it': 'Promuovi il tuo SNS · canale · prodotto a utenti entro 1 km. 📸 foto + 🔗 link.',
    'hi': 'अपने SNS · चैनल · उत्पाद को 1 किमी में स्वचालित प्रचार। 📸 फ़ोटो + 🔗 लिंक।',
    'th': 'โปรโมท SNS · ช่อง · สินค้าให้ผู้ใช้ในรัศมี 1 กม. แนบ 📸 รูป + 🔗 ลิงก์ได้',
  });

  String get composePremiumPromoBadge => _t({
    'ko': '홍보',
    'en': 'PROMO',
    'ja': '宣伝',
    'zh': '推广',
    'fr': 'PROMO',
    'de': 'PROMO',
    'es': 'PROMO',
    'pt': 'PROMO',
    'ru': 'ПРОМО',
    'tr': 'PROMO',
    'ar': 'ترويج',
    'it': 'PROMO',
    'hi': 'प्रचार',
    'th': 'โปร',
  });

  String get composePremiumPromoCta => _t({
    'ko': '📸 사진 + 🔗 링크 첨부',
    'en': '📸 Photo + 🔗 Link',
    'ja': '📸 写真 + 🔗 リンク',
    'zh': '📸 照片 + 🔗 链接',
    'fr': '📸 Photo + 🔗 Lien',
    'de': '📸 Foto + 🔗 Link',
    'es': '📸 Foto + 🔗 Enlace',
    'pt': '📸 Foto + 🔗 Link',
    'ru': '📸 Фото + 🔗 Ссылка',
    'tr': '📸 Foto + 🔗 Link',
    'ar': '📸 صورة + 🔗 رابط',
    'it': '📸 Foto + 🔗 Link',
    'hi': '📸 फ़ोटो + 🔗 लिंक',
    'th': '📸 รูป + 🔗 ลิงก์',
  });

  String get composeExactDropToggle => _t({
    'ko': '🎯 정확한 위치 지정',
    'en': '🎯 Exact location',
    'ja': '🎯 正確な位置',
    'zh': '🎯 精确位置',
    'fr': '🎯 Emplacement précis',
    'de': '🎯 Genauer Standort',
    'es': '🎯 Ubicación exacta',
    'pt': '🎯 Local exato',
    'ru': '🎯 Точное место',
    'tr': '🎯 Tam konum',
    'ar': '🎯 موقع دقيق',
    'it': '🎯 Posizione esatta',
    'hi': '🎯 सटीक स्थान',
    'th': '🎯 ตำแหน่งที่แม่นยำ',
  });
  // 🎟 브랜드 홍보 티켓형 팝업 (Build 107) — 로그인 후 1회/세션
  String get brandTicketTopLabel => _t({
    'ko': '한정 혜택 도착',
    'en': 'LIMITED OFFER',
    'ja': '期間限定',
    'zh': '限时优惠',
    'fr': 'OFFRE LIMITÉE',
    'de': 'LIMITIERTES ANGEBOT',
    'es': 'OFERTA LIMITADA',
    'pt': 'OFERTA LIMITADA',
    'ru': 'ОГРАНИЧЕННОЕ ПРЕДЛОЖЕНИЕ',
    'tr': 'SINIRLI TEKLİF',
    'ar': 'عرض محدود',
    'it': 'OFFERTA LIMITATA',
    'hi': 'सीमित ऑफ़र',
    'th': 'ข้อเสนอพิเศษ',
  });

  String get brandTicketBy => _t({
    'ko': 'by',
    'en': 'by',
    'ja': 'by',
    'zh': 'by',
    'fr': 'par',
    'de': 'von',
    'es': 'de',
    'pt': 'de',
    'ru': 'от',
    'tr': 'sunan',
    'ar': 'من',
    'it': 'di',
    'hi': 'द्वारा',
    'th': 'โดย',
  });

  // Build 157: Brand 대시보드 7일 발송 sparkline 라벨.
  String get brandAnalytics7DaySent => _t({
    'ko': '최근 7일 발송',
    'en': 'Last 7 days sent',
    'ja': '過去7日間の発送',
    'zh': '最近 7 天发送',
    'fr': '7 derniers jours',
    'de': 'Letzte 7 Tage',
    'es': 'Últimos 7 días',
    'pt': 'Últimos 7 dias',
    'ru': 'За 7 дней',
    'tr': 'Son 7 gün',
    'ar': 'آخر 7 أيام',
    'it': 'Ultimi 7 giorni',
    'hi': 'पिछले 7 दिन',
    'th': '7 วันที่ผ่านมา',
  });

  // Build 156: 신규 Brand 온보딩 체크리스트 카드.
  String get brandChecklistTitle => _t({
    'ko': '시작 가이드',
    'en': 'Getting Started',
    'ja': 'スタートガイド',
    'zh': '开始指南',
    'fr': 'Pour commencer',
    'de': 'Erste Schritte',
    'es': 'Primeros pasos',
    'pt': 'Primeiros passos',
    'ru': 'С чего начать',
    'tr': 'Başlangıç rehberi',
    'ar': 'دليل البدء',
    'it': 'Per iniziare',
    'hi': 'शुरुआत',
    'th': 'คู่มือเริ่มต้น',
  });

  String get brandChecklistStep1Title => _t({
    'ko': '사업자 인증 제출',
    'en': 'Submit business verification',
    'ja': '事業者認証を提出',
    'zh': '提交企业认证',
    'fr': 'Vérification d\'entreprise',
    'de': 'Geschäftsverifizierung',
    'es': 'Verificación comercial',
    'pt': 'Verificação empresarial',
    'ru': 'Подтверждение бизнеса',
    'tr': 'İşletme doğrulama',
    'ar': 'التحقق من النشاط',
    'it': 'Verifica aziendale',
    'hi': 'व्यवसाय सत्यापन',
    'th': 'ยืนยันธุรกิจ',
  });
  String get brandChecklistStep1Body => _t({
    'ko': '프로필에 ✅ 뱃지가 붙어 수신자 신뢰도 상승',
    'en': 'Get a ✅ badge — boosts recipient trust',
    'ja': 'プロフィールに ✅ — 受信者の信頼度 UP',
    'zh': '获得 ✅ 徽章，提升收件人信任度',
    'fr': 'Obtiens le badge ✅ — gagne la confiance',
    'de': '✅ Abzeichen — mehr Vertrauen',
    'es': 'Consigue el badge ✅ — más confianza',
    'pt': 'Ganha o badge ✅ — mais confiança',
    'ru': 'Получите ✅ — повышение доверия',
    'tr': '✅ rozeti al — güven artışı',
    'ar': 'احصل على شارة ✅ — زيادة الثقة',
    'it': 'Ottieni il badge ✅ — più fiducia',
    'hi': '✅ बैज पाएँ — विश्वास बढ़ाएँ',
    'th': 'รับป้าย ✅ — เพิ่มความน่าเชื่อถือ',
  });

  String get brandChecklistStep2Title => _t({
    'ko': '첫 캠페인 발송',
    'en': 'Send first campaign',
    'ja': '最初のキャンペーンを発送',
    'zh': '发送首个营销活动',
    'fr': 'Lance ta première campagne',
    'de': 'Erste Kampagne senden',
    'es': 'Envía tu primera campaña',
    'pt': 'Lança a primeira campanha',
    'ru': 'Запустите первую кампанию',
    'tr': 'İlk kampanyanı gönder',
    'ar': 'أطلق أول حملة',
    'it': 'Lancia la prima campagna',
    'hi': 'पहला अभियान भेजें',
    'th': 'ส่งแคมเปญแรก',
  });
  String get brandChecklistStep2Body => _t({
    'ko': '🎟 할인권 / 🎁 교환권 / ✉️ 일반 중 골라 보내기 탭 활용',
    'en': 'Pick 🎟 coupon / 🎁 voucher / ✉️ general, tap Send',
    'ja': '🎟 / 🎁 / ✉️ から選んで送信タブで配布',
    'zh': '选择 🎟 优惠券 / 🎁 代金券 / ✉️ 普通，点击发送',
    'fr': 'Choisis 🎟 / 🎁 / ✉️ et envoie via Envoyer',
    'de': 'Wähle 🎟 / 🎁 / ✉️ und sende',
    'es': 'Elige 🎟 / 🎁 / ✉️ y envía',
    'pt': 'Escolhe 🎟 / 🎁 / ✉️ e envia',
    'ru': 'Выберите 🎟/🎁/✉️ и отправьте',
    'tr': '🎟/🎁/✉️ seç ve gönder',
    'ar': 'اختر 🎟 / 🎁 / ✉️ وأرسل',
    'it': 'Scegli 🎟 / 🎁 / ✉️ e invia',
    'hi': '🎟 / 🎁 / ✉️ चुनें और भेजें',
    'th': 'เลือก 🎟 / 🎁 / ✉️ แล้วส่ง',
  });

  String get brandChecklistStep3Title => _t({
    'ko': '첫 픽업 받기',
    'en': 'Reach first pickup',
    'ja': '最初のピックアップ獲得',
    'zh': '获得首次拾取',
    'fr': 'Premier ramassage',
    'de': 'Erster Aufpickung',
    'es': 'Primera recogida',
    'pt': 'Primeira apanha',
    'ru': 'Первое получение',
    'tr': 'İlk toplama',
    'ar': 'أول التقاط',
    'it': 'Primo ritiro',
    'hi': 'पहला पिकअप',
    'th': 'ได้รับการเก็บครั้งแรก',
  });
  String get brandChecklistStep3Body => _t({
    'ko': '아래 대시보드에 픽업·사용·전환율이 실시간 업데이트',
    'en': 'Dashboard below updates picks · uses · conversion live',
    'ja': '下のダッシュボードでピック・使用・転換率をリアルタイム確認',
    'zh': '下方仪表板实时更新拾取·使用·转化率',
    'fr': 'Le tableau de bord ci-dessous se met à jour en direct',
    'de': 'Dashboard unten aktualisiert Picks/Nutzung/Konversion live',
    'es': 'El panel debajo se actualiza en vivo',
    'pt': 'O painel abaixo atualiza em tempo real',
    'ru': 'Панель ниже обновляется в реальном времени',
    'tr': 'Aşağıdaki panel canlı güncellenir',
    'ar': 'اللوحة أدناه تُحدَّث مباشرة',
    'it': 'Il pannello sotto si aggiorna dal vivo',
    'hi': 'नीचे डैशबोर्ड लाइव अपडेट होता है',
    'th': 'แดชบอร์ดด้านล่างอัปเดตแบบเรียลไทม์',
  });

  // Build 155: 내 레벨 SNS 공유 텍스트.
  String shareMyLevelText({
    required int level,
    required String trail,
    required int collected,
  }) {
    switch (languageCode) {
      case 'ko':
        return 'Thiscount 에서 Level $level 도달 $trail\n지금까지 편지 $collected 통 수집 중!\nhttps://letter-go.com';
      case 'ja':
        return 'Thiscount でレベル $level に到達 $trail\n今までに手紙 $collected 通を収集中！\nhttps://letter-go.com';
      case 'zh':
        return 'Thiscount 达到 Level $level $trail\n目前收集了 $collected 封信件！\nhttps://letter-go.com';
      case 'fr':
        return 'Niveau $level atteint sur Thiscount $trail\n$collected lettres collectées !\nhttps://letter-go.com';
      case 'de':
        return 'Level $level in Thiscount erreicht $trail\n$collected Briefe gesammelt!\nhttps://letter-go.com';
      case 'es':
        return 'Nivel $level en Thiscount $trail\n$collected cartas recogidas!\nhttps://letter-go.com';
      case 'pt':
        return 'Nível $level no Thiscount $trail\n$collected cartas apanhadas!\nhttps://letter-go.com';
      case 'ru':
        return 'Достигнут уровень $level в Thiscount $trail\nСобрано $collected писем!\nhttps://letter-go.com';
      case 'tr':
        return "Thiscount'da Level $level $trail\n$collected mektup topladım!\nhttps://letter-go.com";
      case 'ar':
        return 'وصلت إلى المستوى $level في Thiscount $trail\nجمعت $collected رسالة!\nhttps://letter-go.com';
      case 'it':
        return 'Livello $level su Thiscount $trail\n$collected lettere raccolte!\nhttps://letter-go.com';
      case 'hi':
        return 'Thiscount पर स्तर $level $trail\n$collected पत्र एकत्र!\nhttps://letter-go.com';
      case 'th':
        return 'ถึง Level $level ใน Thiscount $trail\nเก็บจดหมายแล้ว $collected ฉบับ!\nhttps://letter-go.com';
      default:
        return 'Level $level on Thiscount $trail\n$collected letters collected!\nhttps://letter-go.com';
    }
  }

  String get shareMyLevelSubject => _t({
    'ko': 'Thiscount 내 레벨',
    'en': 'My Thiscount level',
    'ja': 'Thiscount の私のレベル',
    'zh': '我的 Thiscount 等级',
    'fr': 'Mon niveau Thiscount',
    'de': 'Mein Thiscount Level',
    'es': 'Mi nivel en Thiscount',
    'pt': 'Meu nível Thiscount',
    'ru': 'Мой уровень в Thiscount',
    'tr': 'Thiscount seviyem',
    'ar': 'مستواي في Thiscount',
    'it': 'Il mio livello su Thiscount',
    'hi': 'मेरा Thiscount स्तर',
    'th': 'เลเวลของฉันใน Thiscount',
  });

  String get shareFailed => _t({
    'ko': '공유 실패 — 잠시 후 다시 시도해주세요',
    'en': 'Share failed — please try again',
    'ja': '共有に失敗しました — 後でもう一度お試しください',
    'zh': '分享失败 — 请稍后重试',
    'fr': "Échec du partage — réessayez",
    'de': 'Teilen fehlgeschlagen — erneut versuchen',
    'es': 'Error al compartir — reintenta',
    'pt': 'Falha ao partilhar — tenta de novo',
    'ru': 'Не удалось поделиться — попробуйте позже',
    'tr': 'Paylaşım başarısız — tekrar dene',
    'ar': 'فشل المشاركة — حاول مرة أخرى',
    'it': 'Condivisione fallita — riprova',
    'hi': 'शेयर विफल — पुनः प्रयास करें',
    'th': 'แชร์ไม่สำเร็จ — ลองอีกครั้ง',
  });

  // Build 154: 주말 부스트 칩.
  String get weekendBoostLabel => _t({
    'ko': '주말 부스트',
    'en': 'Weekend Boost',
    'ja': '週末ブースト',
    'zh': '周末加成',
    'fr': 'Boost Week-end',
    'de': 'Wochenend-Boost',
    'es': 'Boost Finde',
    'pt': 'Boost de FDS',
    'ru': 'Буст выходных',
    'tr': 'Hafta Sonu Boost',
    'ar': 'دفعة نهاية الأسبوع',
    'it': 'Boost Weekend',
    'hi': 'वीकेंड बूस्ट',
    'th': 'บูสต์สุดสัปดาห์',
  });

  String get weekendBoostDesc => _t({
    'ko': '🌈 주말에는 더 많은 브랜드가 혜택을 뿌려요. 오늘 더 많이 주워보세요!',
    'en': '🌈 Brands drop more rewards on weekends — pick up extra today!',
    'ja': '🌈 週末はブランドが多くの手紙を届けます — 今日はたくさん拾おう！',
    'zh': '🌈 周末品牌投放更多信件 — 今天多拾取一些吧！',
    'fr': '🌈 Les marques larguent plus de lettres le week-end — ramasse plus aujourd\'hui !',
    'de': '🌈 Marken lassen am Wochenende mehr Briefe fallen — heute extra sammeln!',
    'es': '🌈 Las marcas sueltan más cartas los fines de semana — recoge más hoy!',
    'pt': '🌈 Marcas largam mais cartas ao fim-de-semana — apanha mais hoje!',
    'ru': '🌈 По выходным бренды разбрасывают больше писем — собирайте сегодня!',
    'tr': '🌈 Markalar hafta sonu daha fazla mektup bırakıyor — bugün ekstra topla!',
    'ar': '🌈 العلامات التجارية تسقط المزيد من الرسائل في عطلة نهاية الأسبوع — التقط المزيد اليوم!',
    'it': '🌈 I brand lasciano più lettere nei weekend — raccogli di più oggi!',
    'hi': '🌈 वीकेंड पर ब्रांड अधिक पत्र गिराते हैं — आज अधिक उठाएँ!',
    'th': '🌈 แบรนด์ทิ้งจดหมายมากขึ้นในสุดสัปดาห์ — เก็บเพิ่มวันนี้!',
  });

  // Build 153: 수집첩 월간 목표 진척 라벨 — "이번 달 32 / 50".
  String inboxMonthlyGoalLabel(int collected, int target) {
    switch (languageCode) {
      case 'ko':
        return '이번 달 $collected / $target';
      case 'ja':
        return '今月 $collected / $target';
      case 'zh':
        return '本月 $collected / $target';
      case 'fr':
        return 'Ce mois-ci $collected / $target';
      case 'de':
        return 'Diesen Monat $collected / $target';
      case 'es':
        return 'Este mes $collected / $target';
      case 'pt':
        return 'Este mês $collected / $target';
      case 'ru':
        return 'В этом месяце $collected / $target';
      case 'tr':
        return 'Bu ay $collected / $target';
      case 'ar':
        return 'هذا الشهر $collected / $target';
      case 'it':
        return 'Questo mese $collected / $target';
      case 'hi':
        return 'इस माह $collected / $target';
      case 'th':
        return 'เดือนนี้ $collected / $target';
      default:
        return 'This month $collected / $target';
    }
  }

  // Build 152: 시간대별 인사 pill — 반경 안에 혜택 있을 때 표시.
  String get dailyGreetingMorning => _t({
    'ko': '좋은 아침',
    'en': 'Good morning',
    'ja': 'おはよう',
    'zh': '早上好',
    'fr': 'Bonjour',
    'de': 'Guten Morgen',
    'es': 'Buenos días',
    'pt': 'Bom dia',
    'ru': 'Доброе утро',
    'tr': 'Günaydın',
    'ar': 'صباح الخير',
    'it': 'Buongiorno',
    'hi': 'सुप्रभात',
    'th': 'อรุณสวัสดิ์',
  });
  String get dailyGreetingAfternoon => _t({
    'ko': '오후의 한 템포',
    'en': 'Afternoon check',
    'ja': '午後のひと休み',
    'zh': '下午时光',
    'fr': 'Pause de l\'après-midi',
    'de': 'Nachmittagspause',
    'es': 'Pausa de la tarde',
    'pt': 'Pausa da tarde',
    'ru': 'Полуденная пауза',
    'tr': 'Öğleden sonra molası',
    'ar': 'استراحة العصر',
    'it': 'Pausa pomeridiana',
    'hi': 'दोपहर की जाँच',
    'th': 'ช่วงบ่าย',
  });
  String get dailyGreetingEvening => _t({
    'ko': '오늘의 마무리',
    'en': 'Evening wrap-up',
    'ja': '今日の締めくくり',
    'zh': '傍晚收尾',
    'fr': 'Fin de journée',
    'de': 'Feierabend-Check',
    'es': 'Final del día',
    'pt': 'Fim de dia',
    'ru': 'Завершение дня',
    'tr': 'Akşam özeti',
    'ar': 'ختام اليوم',
    'it': 'Chiusura di giornata',
    'hi': 'दिन का अंत',
    'th': 'สรุปเย็นนี้',
  });
  String get dailyGreetingNight => _t({
    'ko': '심야 탐험',
    'en': 'Late-night hunt',
    'ja': '深夜の探索',
    'zh': '深夜探索',
    'fr': 'Chasse de nuit',
    'de': 'Nacht-Suche',
    'es': 'Caza nocturna',
    'pt': 'Caça noturna',
    'ru': 'Ночная охота',
    'tr': 'Gece avı',
    'ar': 'صيد ليلي',
    'it': 'Caccia notturna',
    'hi': 'देर रात की खोज',
    'th': 'สำรวจดึก',
  });

  /// 시간대 인사 + "근처 N통" 결합 포맷.
  String dailyGreetingCount(String greeting, int count) {
    switch (languageCode) {
      case 'ko':
        return '$greeting · 근처 $count통 대기';
      case 'ja':
        return '$greeting · 近くに $count 通待機';
      case 'zh':
        return '$greeting · 附近 $count 封待拾';
      case 'fr':
        return '$greeting · $count lettres à proximité';
      case 'de':
        return '$greeting · $count in der Nähe';
      case 'es':
        return '$greeting · $count cerca';
      case 'pt':
        return '$greeting · $count perto';
      case 'ru':
        return '$greeting · $count рядом';
      case 'tr':
        return '$greeting · yakında $count';
      case 'ar':
        return '$greeting · $count قريبة';
      case 'it':
        return '$greeting · $count vicino';
      case 'hi':
        return '$greeting · $count पास में';
      case 'th':
        return '$greeting · $count ฉบับใกล้';
      default:
        return '$greeting · $count nearby';
    }
  }

  // Build 149: 첫 실행 시 자동 배치되는 튜토리얼 환영 편지 — 반경 안에 1통
  // 반드시 줍기 가능한 상태로 지도에 뿌려 빈 지도 경험 해소.
  String get tutorialLetterSenderName => _t({
    'ko': 'Thiscount',
    'en': 'Thiscount',
    'ja': 'Thiscount',
    'zh': 'Thiscount',
    'fr': 'Thiscount',
    'de': 'Thiscount',
    'es': 'Thiscount',
    'pt': 'Thiscount',
    'ru': 'Thiscount',
    'tr': 'Thiscount',
    'ar': 'Thiscount',
    'it': 'Thiscount',
    'hi': 'Thiscount',
    'th': 'Thiscount',
  });

  String get tutorialLetterContent => _t({
    'ko': '환영합니다! ✨\n\nThiscount 에 오신 걸 환영해요. 이 혜택을 주우면 줍기 경험을 미리 체험할 수 있어요.\n\n가까이 다가가서 혜택을 탭해보세요. 지도 아래 📍 근처 카운터가 함께 반응할 거예요.\n\n앞으로 전 세계 브랜드들이 뿌리는 할인·이벤트 혜택을 만나보세요!',
    'en': 'Welcome to Thiscount! ✨\n\nPick up this reward to try the hunt experience. Walk close and tap it.\n\nThe 📍 Nearby counter on the map will light up as soon as you\'re in range.\n\nBrands from around the world drop coupons and event rewards — happy hunting!',
    'ja': 'Thiscount へようこそ！✨\n\nこの手紙を拾って体験を始めましょう。近づいてタップしてください。\n\n範囲に入ると地図の 📍 近くのカウンターが反応します。\n\n世界中のブランドが落とす割引・イベント手紙をお楽しみください！',
    'zh': '欢迎来到 Thiscount！✨\n\n拾起这封信体验"拾取"玩法。靠近并点击它即可。\n\n进入范围后地图上的 📍 附近计数器会亮起。\n\n来自世界各地的品牌在此投放优惠与活动信件——祝你好运！',
    'fr': 'Bienvenue dans Thiscount ! ✨\n\nRamasse cette lettre pour découvrir l\'expérience. Approche-toi et appuie dessus.\n\nLe compteur 📍 À proximité s\'allumera dès que tu seras à portée.\n\nDes marques du monde entier déposent coupons et lettres promo — bonne chasse !',
    'de': 'Willkommen bei Thiscount! ✨\n\nHeb diesen Brief auf und probiere die Hunt-Erfahrung. Geh nah ran und tippe ihn an.\n\nDer 📍 In-der-Nähe-Zähler leuchtet auf, sobald du in Reichweite bist.\n\nMarken weltweit verteilen Rabatte und Event-Briefe — viel Spaß beim Sammeln!',
    'es': '¡Bienvenido a Thiscount! ✨\n\nRecoge esta carta para probar la experiencia. Acércate y tócala.\n\nEl contador 📍 Cerca se iluminará en cuanto estés a tiro.\n\nMarcas de todo el mundo sueltan cupones y cartas de eventos — ¡buena caza!',
    'pt': 'Bem-vindo ao Thiscount! ✨\n\nApanha esta carta para experimentar. Aproxima-te e toca.\n\nO contador 📍 Perto vai acender assim que estiveres no alcance.\n\nMarcas do mundo inteiro largam cupões e cartas de eventos — boa caça!',
    'ru': 'Добро пожаловать в Thiscount! ✨\n\nПодберите это письмо, чтобы попробовать охоту. Подойдите и нажмите.\n\nСчётчик 📍 Рядом подсветится, как только вы окажетесь в зоне.\n\nБренды со всего мира разбрасывают купоны — удачной охоты!',
    'tr': 'Thiscount\'ya hoş geldin! ✨\n\nBu mektubu toplayarak deneyimi başlat. Yaklaş ve dokun.\n\nMenzile girdiğin an 📍 Yakın sayacı parlayacak.\n\nDünya çapında markalar kuponlar bırakıyor — iyi avlanmalar!',
    'ar': 'مرحبًا بك في Thiscount! ✨\n\nالتقط هذه الرسالة لتجربة اللعبة. اقترب واضغط عليها.\n\nعدّاد 📍 قريب سيضيء فور دخولك النطاق.\n\nعلامات تجارية من حول العالم تسقط القسائم — صيدًا موفقًا!',
    'it': 'Benvenuto in Thiscount! ✨\n\nRaccogli questa lettera per provare l\'esperienza. Avvicinati e tocca.\n\nIl contatore 📍 Vicino si illuminerà appena sarai a portata.\n\nBrand di tutto il mondo lasciano coupon — buona caccia!',
    'hi': 'Thiscount में आपका स्वागत है! ✨\n\nइस पत्र को उठाकर अनुभव शुरू करें. पास जाएँ और टैप करें.\n\nदायरे में आते ही नक्शे का 📍 पास काउंटर जलेगा.\n\nदुनिया भर के ब्रांड कूपन गिराते हैं — शुभ शिकार!',
    'th': 'ยินดีต้อนรับสู่ Thiscount! ✨\n\nเก็บจดหมายฉบับนี้เพื่อทดลองใช้งาน เดินเข้าใกล้แล้วแตะ\n\nตัวนับ 📍 ใกล้ ๆ บนแผนที่จะสว่างเมื่อคุณอยู่ในรัศมี\n\nแบรนด์ทั่วโลกทิ้งคูปองไว้ — สนุกกับการค้นหา!',
  });

  String get brandTicketDefaultBrand => _t({
    'ko': '공식 발송인',
    'en': 'Official Sender',
    'ja': '公式発信元',
    'zh': '官方发送方',
    'fr': 'Expéditeur officiel',
    'de': 'Offizieller Absender',
    'es': 'Remitente oficial',
    'pt': 'Remetente oficial',
    'ru': 'Официальный отправитель',
    'tr': 'Resmi Gönderici',
    'ar': 'المرسل الرسمي',
    'it': 'Mittente ufficiale',
    'hi': 'आधिकारिक प्रेषक',
    'th': 'ผู้ส่งอย่างเป็นทางการ',
  });

  String get brandTicketFallbackTitle => _t({
    'ko': '지금 바로 주워보세요',
    'en': 'Go pick it up now',
    'ja': '今すぐ手に入れよう',
    'zh': '立即去拾取',
    'fr': 'À ramasser tout de suite',
    'de': 'Jetzt aufheben',
    'es': 'Recógelo ya',
    'pt': 'Apanhe agora',
    'ru': 'Забирайте прямо сейчас',
    'tr': 'Hemen topla',
    'ar': 'التقطها الآن',
    'it': 'Raccogli subito',
    'hi': 'अभी उठाएँ',
    'th': 'รีบเก็บเลย',
  });

  String get brandTicketNoExpiry => _t({
    'ko': '기간 제한 없음',
    'en': 'No expiry',
    'ja': '期限なし',
    'zh': '无限期',
    'fr': 'Sans expiration',
    'de': 'Ohne Ablauf',
    'es': 'Sin caducidad',
    'pt': 'Sem validade',
    'ru': 'Без срока',
    'tr': 'Süresiz',
    'ar': 'بدون انتهاء',
    'it': 'Senza scadenza',
    'hi': 'कोई समाप्ति नहीं',
    'th': 'ไม่มีหมดอายุ',
  });

  String get brandTicketExpired => _t({
    'ko': '만료됨',
    'en': 'Expired',
    'ja': '期限切れ',
    'zh': '已过期',
    'fr': 'Expiré',
    'de': 'Abgelaufen',
    'es': 'Caducado',
    'pt': 'Expirado',
    'ru': 'Истёк',
    'tr': 'Süresi doldu',
    'ar': 'منتهي',
    'it': 'Scaduto',
    'hi': 'समाप्त',
    'th': 'หมดอายุ',
  });

  String brandTicketHoursLeft(int h) {
    switch (languageCode) {
      case 'ko':
        return '${h}시간 남음';
      case 'en':
        return '${h}h left';
      case 'ja':
        return '残り${h}時間';
      case 'zh':
        return '剩 $h 小时';
      case 'fr':
        return '${h}h restant';
      case 'de':
        return 'noch ${h}h';
      case 'es':
        return 'quedan ${h}h';
      case 'pt':
        return '${h}h restantes';
      case 'ru':
        return 'осталось ${h}ч';
      case 'tr':
        return '${h}s kaldı';
      case 'ar':
        return 'متبقي ${h} س';
      case 'it':
        return '${h}h rimaste';
      case 'hi':
        return '${h} घंटे शेष';
      case 'th':
        return 'เหลือ $h ชม.';
      default:
        return '${h}h left';
    }
  }

  String brandTicketDaysLeft(int d) {
    switch (languageCode) {
      case 'ko':
        return '${d}일 남음';
      case 'en':
        return '${d}d left';
      case 'ja':
        return '残り${d}日';
      case 'zh':
        return '剩 $d 天';
      case 'fr':
        return '${d}j restants';
      case 'de':
        return 'noch ${d}T';
      case 'es':
        return 'quedan ${d}d';
      case 'pt':
        return '${d}d restantes';
      case 'ru':
        return 'осталось ${d}д';
      case 'tr':
        return '${d}g kaldı';
      case 'ar':
        return 'متبقي ${d} أيام';
      case 'it':
        return '${d}g rimasti';
      case 'hi':
        return '${d} दिन शेष';
      case 'th':
        return 'เหลือ $d วัน';
      default:
        return '${d}d left';
    }
  }

  String brandTicketExpiresAt(String remaining) {
    switch (languageCode) {
      case 'ko':
        return '유효 기간 · $remaining';
      case 'en':
        return 'Valid · $remaining';
      case 'ja':
        return '有効期間 · $remaining';
      case 'zh':
        return '有效期 · $remaining';
      case 'fr':
        return 'Validité · $remaining';
      case 'de':
        return 'Gültig · $remaining';
      case 'es':
        return 'Válido · $remaining';
      case 'pt':
        return 'Válido · $remaining';
      case 'ru':
        return 'Действует · $remaining';
      case 'tr':
        return 'Geçerli · $remaining';
      case 'ar':
        return 'ساري · $remaining';
      case 'it':
        return 'Valido · $remaining';
      case 'hi':
        return 'मान्य · $remaining';
      case 'th':
        return 'ใช้ได้ · $remaining';
      default:
        return 'Valid · $remaining';
    }
  }

  String get brandTicketCloseHint => _t({
    'ko': '닫기 누르면 오늘은 안 보여요',
    'en': 'Close to hide for today',
    'ja': '閉じると今日は非表示',
    'zh': '点击关闭今日不再显示',
    'fr': 'Fermer pour masquer aujourd\'hui',
    'de': 'Schließen verbirgt für heute',
    'es': 'Cerrar oculta hoy',
    'pt': 'Fechar oculta hoje',
    'ru': 'Закрыть — скрыть на сегодня',
    'tr': 'Kapat · bugün gizle',
    'ar': 'أغلق · إخفاء اليوم',
    'it': 'Chiudi per oggi',
    'hi': 'बंद करें · आज के लिए छिपाएँ',
    'th': 'ปิดเพื่อซ่อนวันนี้',
  });

  // (레거시) 🎁 브랜드 할인 편지 안내 팝업 문자열 — 티켓 팝업 전환으로 더 이상
  // 표시 경로 없음. 롤백 대비 키만 유지.
  String get brandPromoTitle => _t({
    'ko': '브랜드 할인 혜택이 도착하고 있어요',
    'en': 'Brand coupons are dropping on the map',
    'ja': 'ブランド割引手紙が届いています',
    'zh': '品牌折扣信件正在地图上传递',
    'fr': 'Des lettres de coupons de marque arrivent',
    'de': 'Marken-Coupon-Briefe sind unterwegs',
    'es': 'Las cartas de cupón de marca están llegando',
    'pt': 'Cartas de cupão de marca estão a chegar',
    'ru': 'Письма-купоны брендов уже на карте',
    'tr': 'Marka kupon mektupları haritada',
    'ar': 'رسائل قسائم العلامات تصل الآن',
    'it': 'Le lettere-coupon dei brand sono in arrivo',
    'hi': 'ब्रांड कूपन पत्र मानचित्र पर आ रहे हैं',
    'th': 'จดหมายคูปองแบรนด์กำลังมาถึง',
  });

  String get brandPromoBody => _t({
    'ko': '지도에서 가까이 걸어가 혜택을 주우면 즉시 사용 가능한 할인권·교환권이 나와요. 새로 도착한 혜택이 있으면 수집첩에서 확인해보세요!',
    'en': 'Walk close to rewards on the map to pick up ready-to-use coupons and vouchers. Check your Collection for what\'s new.',
    'ja': '地図上で手紙に近づいて拾うと、すぐ使える割引券や引換券がもらえます。コレクションで新着をチェック！',
    'zh': '走近地图上的信件即可获得可立即使用的优惠券和兑换券。请到收藏查看。',
    'fr': 'Rapprochez-vous des lettres sur la carte pour recevoir coupons et bons immédiatement utilisables. Consultez votre Collection !',
    'de': 'Geh nah an Briefe auf der Karte, um sofort einlösbare Coupons und Gutscheine zu bekommen. Sieh in deiner Sammlung nach!',
    'es': 'Acércate a las cartas en el mapa para recibir cupones y vales listos para usar. ¡Revisa tu Colección!',
    'pt': 'Aproxima-te das cartas no mapa para receber cupões e vales prontos a usar. Vê a tua Coleção!',
    'ru': 'Подойдите ближе к письмам на карте, чтобы получить готовые к использованию купоны и ваучеры. Проверьте Коллекцию!',
    'tr': 'Haritadaki mektuplara yaklaşarak hazır kupon ve çek alın. Koleksiyonunuza göz atın!',
    'ar': 'اقترب من الرسائل على الخريطة لاستلام قسائم وقسائم جاهزة للاستخدام. راجع مجموعتك!',
    'it': 'Avvicinati alle lettere sulla mappa per ricevere coupon e buoni pronti all\'uso. Controlla la Collezione!',
    'hi': 'मानचित्र पर पत्रों के पास जाकर तुरंत उपयोगी कूपन और वाउचर प्राप्त करें. कलेक्शन देखें!',
    'th': 'เข้าใกล้จดหมายบนแผนที่เพื่อรับคูปองและบัตรกำนัลพร้อมใช้ ดูในคอลเลคชัน',
  });

  String get brandPromoContactHint => _t({
    'ko': '브랜드 계정으로 광고·캠페인을 운영하고 싶으시면 관리자에게 문의해주세요.',
    'en': 'Want to run brand campaigns? Contact the admin to set up a brand account.',
    'ja': 'ブランドアカウントでキャンペーンを運営したい方は管理者までご連絡ください。',
    'zh': '如需通过品牌账号开展活动，请联系管理员。',
    'fr': 'Pour lancer des campagnes de marque, contactez l\'admin.',
    'de': 'Für Marken-Kampagnen wende dich an den Admin.',
    'es': 'Para campañas de marca, contacta al admin.',
    'pt': 'Para campanhas de marca, contacta o admin.',
    'ru': 'Хотите запустить бренд-кампанию? Напишите админу.',
    'tr': 'Marka kampanyaları için yöneticiye ulaşın.',
    'ar': 'لتشغيل حملات علامة تجارية تواصل مع المشرف.',
    'it': 'Per campagne brand contatta l\'admin.',
    'hi': 'ब्रांड अभियान के लिए व्यवस्थापक से संपर्क करें.',
    'th': 'สนใจทำแคมเปญแบรนด์ ติดต่อผู้ดูแล',
  });

  String get brandPromoDismiss => _t({
    'ko': '알겠어요',
    'en': 'Got it',
    'ja': '了解',
    'zh': '知道了',
    'fr': 'Compris',
    'de': 'Verstanden',
    'es': 'Entendido',
    'pt': 'Entendi',
    'ru': 'Понятно',
    'tr': 'Anladım',
    'ar': 'فهمت',
    'it': 'Capito',
    'hi': 'समझ गया',
    'th': 'เข้าใจแล้ว',
  });

  String get brandPromoContactCta => _t({
    'ko': '💼 관리자 문의',
    'en': '💼 Contact admin',
    'ja': '💼 管理者に連絡',
    'zh': '💼 联系管理员',
    'fr': '💼 Contacter l\'admin',
    'de': '💼 Admin kontaktieren',
    'es': '💼 Contactar admin',
    'pt': '💼 Contactar admin',
    'ru': '💼 Написать админу',
    'tr': '💼 Yöneticiye ulaş',
    'ar': '💼 تواصل مع المشرف',
    'it': '💼 Contatta l\'admin',
    'hi': '💼 व्यवस्थापक से संपर्क',
    'th': '💼 ติดต่อผู้ดูแล',
  });

  // 🎯 ExactDrop 유료 전환 (Build 106) — 크레딧 부족 시 다이얼로그
  String get composeExactDropPaywallTitle => _t({
    'ko': '정확 좌표 드롭은 유료 기능이에요',
    'en': 'Exact-coordinate drop is a paid feature',
    'ja': '精確座標ドロップは有料機能です',
    'zh': '精确坐标投放为付费功能',
    'fr': 'Le dépôt aux coordonnées exactes est payant',
    'de': 'Präzise Ablage ist kostenpflichtig',
    'es': 'La entrega en coordenadas exactas es de pago',
    'pt': 'A entrega em coordenadas exatas é paga',
    'ru': 'Точная доставка — платная функция',
    'tr': 'Tam koordinat teslimi ücretli',
    'ar': 'توصيل الإحداثيات الدقيقة ميزة مدفوعة',
    'it': 'Rilascio a coordinate esatte è a pagamento',
    'hi': 'सटीक निर्देशांक ड्रॉप एक सशुल्क सुविधा है',
    'th': 'การวางจุดพิกัดเป็นฟีเจอร์เสียเงิน',
  });

  String get composeExactDropPaywallBody => _t({
    'ko': '원하는 매장·좌표에 혜택을 정확히 뿌릴 수 있어요. 사용을 원하시면 관리자에게 문의해주세요.',
    'en': 'Drop promos on exact store locations or coordinates. Contact the admin to enable this feature.',
    'ja': '特定の店舗・座標に手紙を正確に配置できます。利用希望は管理者にお問い合わせください。',
    'zh': '将信件精确投放到指定地点或坐标。如需使用请联系管理员。',
    'fr': 'Déposez des lettres à des points de vente ou coordonnées précis. Contactez l\'admin pour activer.',
    'de': 'Briefe an exakte Standorte oder Koordinaten ablegen. Admin für Freischaltung kontaktieren.',
    'es': 'Deja cartas en ubicaciones o coordenadas exactas. Contacta al admin para activarlo.',
    'pt': 'Deixe cartas em locais exatos ou coordenadas. Contacte o admin para ativar.',
    'ru': 'Размещайте письма в точных местах или координатах. Обратитесь к админу.',
    'tr': 'Belirli mağaza veya koordinatlara mektup bırakın. Aktifleştirmek için yöneticiye ulaşın.',
    'ar': 'وزّع الرسائل على مواقع أو إحداثيات دقيقة. تواصل مع المشرف لتفعيلها.',
    'it': 'Rilascia lettere in luoghi o coordinate esatte. Contatta l\'admin per abilitarla.',
    'hi': 'सटीक स्थानों या निर्देशांक पर पत्र छोड़ें. सुविधा सक्षम करने के लिए व्यवस्थापक से संपर्क करें.',
    'th': 'วางจดหมายที่ร้านค้าหรือพิกัดที่ต้องการ ติดต่อผู้ดูแลเพื่อเปิดใช้',
  });

  String get composeExactDropPaywallPricing => _t({
    'ko': '100통 패키지 · 10,000원',
    'en': '100-promo package · KRW 10,000',
    'ja': '100通パッケージ · 10,000ウォン',
    'zh': '100 封套餐 · 10,000 韩元',
    'fr': '100 lettres · 10 000 KRW',
    'de': '100er-Paket · 10.000 KRW',
    'es': 'Paquete de 100 · 10.000 KRW',
    'pt': 'Pacote de 100 · 10.000 KRW',
    'ru': 'Пакет 100 писем · 10 000 KRW',
    'tr': '100 mektup paketi · 10.000 KRW',
    'ar': 'باقة 100 رسالة · 10,000 KRW',
    'it': 'Pacchetto da 100 · 10.000 KRW',
    'hi': '100 पत्र पैकेज · ₩10,000',
    'th': 'แพ็คเกจ 100 ฉบับ · 10,000 วอน',
  });

  String get composeExactDropOutOfCredits => _t({
    'ko': 'ExactDrop 크레딧이 부족해요. 관리자에게 문의하세요.',
    'en': 'Not enough ExactDrop credits. Contact the admin.',
    'ja': 'ExactDrop クレジットが不足しています。管理者にお問い合わせください。',
    'zh': 'ExactDrop 额度不足，请联系管理员。',
    'fr': 'Crédits ExactDrop insuffisants. Contactez l\'admin.',
    'de': 'Nicht genug ExactDrop-Credits. Admin kontaktieren.',
    'es': 'Créditos de ExactDrop insuficientes. Contacta al admin.',
    'pt': 'Créditos ExactDrop insuficientes. Contacte o admin.',
    'ru': 'Недостаточно кредитов ExactDrop. Свяжитесь с админом.',
    'tr': 'ExactDrop kredisi yetersiz. Yöneticiye ulaşın.',
    'ar': 'رصيد ExactDrop غير كافٍ. تواصل مع المشرف.',
    'it': 'Crediti ExactDrop insufficienti. Contatta l\'admin.',
    'hi': 'ExactDrop क्रेडिट अपर्याप्त. व्यवस्थापक से संपर्क करें.',
    'th': 'เครดิต ExactDrop ไม่พอ ติดต่อผู้ดูแล',
  });

  String get composeExactDropHint => _t({
    'ko': '빨간 핀이 떨어뜨릴 위치예요. 지도를 움직여 조정한 뒤 아래 버튼으로 확정하세요',
    'en': 'The red pin marks the drop spot. Pan the map to adjust, then tap Confirm below',
    'ja': '赤いピンが手紙を落とす位置です。地図を動かして調整し、下のボタンで確定してください',
    'zh': '红色图钉即为投放位置。移动地图进行调整后，点击下方按钮确认',
    'fr': "L'épingle rouge indique le point de dépôt. Déplacez la carte, puis appuyez sur Confirmer ci-dessous",
    'de': 'Die rote Markierung zeigt den Ablageort. Karte verschieben, dann unten bestätigen',
    'es': 'El pin rojo marca el punto de entrega. Mueve el mapa y pulsa Confirmar abajo',
    'pt': 'O pino vermelho marca o ponto de entrega. Mova o mapa e toque em Confirmar abaixo',
    'ru': 'Красная метка — место доставки. Сдвиньте карту и нажмите «Подтвердить» ниже',
    'tr': 'Kırmızı iğne teslim noktasıdır. Haritayı kaydırıp aşağıda Onayla’ya dokunun',
    'ar': 'الدبّوس الأحمر هو نقطة التسليم. حرّك الخريطة ثم اضغط تأكيد بالأسفل',
    'it': 'Il perno rosso indica il punto di rilascio. Sposta la mappa e tocca Conferma qui sotto',
    'hi': 'लाल पिन गिराने की जगह है. मानचित्र घुमाएँ और नीचे पुष्टि करें',
    'th': 'หมุดสีแดงคือตำแหน่งวางจดหมาย เลื่อนแผนที่แล้วกดยืนยันด้านล่าง',
  });
  String get composeExactDropTitle => _t({
    'ko': '홍보 떨어뜨릴 위치',
    'en': 'Promo drop location',
    'ja': '手紙を落とす場所',
    'zh': '投放信件位置',
    'fr': "Lieu du dépôt",
    'de': 'Ablageort',
    'es': 'Lugar de entrega',
    'pt': 'Local de entrega',
    'ru': 'Место доставки',
    'tr': 'Teslim yeri',
    'ar': 'مكان وضع الرسالة',
    'it': 'Luogo del rilascio',
    'hi': 'पत्र गिराने का स्थान',
    'th': 'ตำแหน่งวางจดหมาย',
  });
  String get composeExactDropConfirm => _t({
    'ko': '이 위치로 확정',
    'en': 'Confirm this location',
    'ja': 'この場所に確定',
    'zh': '确认此位置',
    'fr': 'Confirmer ce lieu',
    'de': 'Diesen Ort bestätigen',
    'es': 'Confirmar este lugar',
    'pt': 'Confirmar este local',
    'ru': 'Подтвердить место',
    'tr': 'Bu konumu onayla',
    'ar': 'تأكيد هذا الموقع',
    'it': 'Conferma questa posizione',
    'hi': 'इस स्थान की पुष्टि करें',
    'th': 'ยืนยันตำแหน่งนี้',
  });
  String get dayThemeBannerTitle => _t({
    'ko': '오늘의 테마',
    'en': "TODAY'S THEME",
    'ja': '今日のテーマ',
    'zh': '今日主题',
    'fr': 'THÈME DU JOUR',
    'de': 'TAGES-THEMA',
    'es': 'TEMA DE HOY',
    'pt': 'TEMA DE HOJE',
    'ru': 'ТЕМА ДНЯ',
    'tr': 'BUGÜNÜN TEMASI',
    'ar': 'موضوع اليوم',
    'it': 'TEMA DI OGGI',
    'hi': 'आज का विषय',
    'th': 'ธีมวันนี้',
  });
  String get dayThemeEastAsia => _t({
    'ko': '월요일 · 동아시아로 홍보를 써볼까요',
    'en': 'Monday · write to East Asia',
    'ja': '月曜日 · 東アジアに手紙を',
    'zh': '周一 · 写信去东亚',
    'fr': 'Lundi · écrivez vers l\'Asie de l\'Est',
    'de': 'Montag · schreib nach Ostasien',
    'es': 'Lunes · escribe a Asia Oriental',
    'pt': 'Segunda · escreva para o Leste Asiático',
    'ru': 'Понедельник · напишите в Восточную Азию',
    'tr': 'Pazartesi · Doğu Asya\'ya yazın',
    'ar': 'الاثنين · اكتب إلى شرق آسيا',
    'it': 'Lunedì · scrivi nell\'Asia orientale',
    'hi': 'सोमवार · पूर्व एशिया को पत्र',
    'th': 'จันทร์ · เขียนไปเอเชียตะวันออก',
  });
  String get dayThemeEurope => _t({
    'ko': '화요일 · 유럽으로 홍보를 써볼까요',
    'en': 'Tuesday · write to Europe',
    'ja': '火曜日 · ヨーロッパに手紙を',
    'zh': '周二 · 写信去欧洲',
    'fr': 'Mardi · écrivez vers l\'Europe',
    'de': 'Dienstag · schreib nach Europa',
    'es': 'Martes · escribe a Europa',
    'pt': 'Terça · escreva para a Europa',
    'ru': 'Вторник · напишите в Европу',
    'tr': 'Salı · Avrupa\'ya yazın',
    'ar': 'الثلاثاء · اكتب إلى أوروبا',
    'it': 'Martedì · scrivi in Europa',
    'hi': 'मंगलवार · यूरोप को पत्र',
    'th': 'อังคาร · เขียนไปยุโรป',
  });
  String get dayThemeAfrica => _t({
    'ko': '수요일 · 아프리카로 홍보를 써볼까요',
    'en': 'Wednesday · write to Africa',
    'ja': '水曜日 · アフリカに手紙を',
    'zh': '周三 · 写信去非洲',
    'fr': 'Mercredi · écrivez vers l\'Afrique',
    'de': 'Mittwoch · schreib nach Afrika',
    'es': 'Miércoles · escribe a África',
    'pt': 'Quarta · escreva para a África',
    'ru': 'Среда · напишите в Африку',
    'tr': 'Çarşamba · Afrika\'ya yazın',
    'ar': 'الأربعاء · اكتب إلى أفريقيا',
    'it': 'Mercoledì · scrivi in Africa',
    'hi': 'बुधवार · अफ्रीका को पत्र',
    'th': 'พุธ · เขียนไปแอฟริกา',
  });
  String get dayThemeSouthAmerica => _t({
    'ko': '목요일 · 남아메리카로 홍보를 써볼까요',
    'en': 'Thursday · write to South America',
    'ja': '木曜日 · 南アメリカに手紙を',
    'zh': '周四 · 写信去南美',
    'fr': 'Jeudi · écrivez vers l\'Amérique du Sud',
    'de': 'Donnerstag · schreib nach Südamerika',
    'es': 'Jueves · escribe a Sudamérica',
    'pt': 'Quinta · escreva para a América do Sul',
    'ru': 'Четверг · напишите в Южную Америку',
    'tr': 'Perşembe · Güney Amerika\'ya yazın',
    'ar': 'الخميس · اكتب إلى أمريكا الجنوبية',
    'it': 'Giovedì · scrivi in Sud America',
    'hi': 'गुरुवार · दक्षिण अमेरिका को पत्र',
    'th': 'พฤหัส · เขียนไปอเมริกาใต้',
  });
  String get dayThemeOceania => _t({
    'ko': '금요일 · 오세아니아로 홍보를 써볼까요',
    'en': 'Friday · write to Oceania',
    'ja': '金曜日 · オセアニアに手紙を',
    'zh': '周五 · 写信去大洋洲',
    'fr': 'Vendredi · écrivez vers l\'Océanie',
    'de': 'Freitag · schreib nach Ozeanien',
    'es': 'Viernes · escribe a Oceanía',
    'pt': 'Sexta · escreva para a Oceania',
    'ru': 'Пятница · напишите в Океанию',
    'tr': 'Cuma · Okyanusya\'ya yazın',
    'ar': 'الجمعة · اكتب إلى أوقيانوسيا',
    'it': 'Venerdì · scrivi in Oceania',
    'hi': 'शुक्रवार · ओशिनिया को पत्र',
    'th': 'ศุกร์ · เขียนไปโอเชียเนีย',
  });
  String get dayThemeNorthAmerica => _t({
    'ko': '토요일 · 북아메리카로 홍보를 써볼까요',
    'en': 'Saturday · write to North America',
    'ja': '土曜日 · 北アメリカに手紙を',
    'zh': '周六 · 写信去北美',
    'fr': 'Samedi · écrivez vers l\'Amérique du Nord',
    'de': 'Samstag · schreib nach Nordamerika',
    'es': 'Sábado · escribe a Norteamérica',
    'pt': 'Sábado · escreva para a América do Norte',
    'ru': 'Суббота · напишите в Северную Америку',
    'tr': 'Cumartesi · Kuzey Amerika\'ya yazın',
    'ar': 'السبت · اكتب إلى أمريكا الشمالية',
    'it': 'Sabato · scrivi in Nord America',
    'hi': 'शनिवार · उत्तरी अमेरिका को पत्र',
    'th': 'เสาร์ · เขียนไปอเมริกาเหนือ',
  });
  String get dayThemeMiddleEast => _t({
    'ko': '일요일 · 중동으로 홍보를 써볼까요',
    'en': 'Sunday · write to the Middle East',
    'ja': '日曜日 · 中東に手紙を',
    'zh': '周日 · 写信去中东',
    'fr': 'Dimanche · écrivez vers le Moyen-Orient',
    'de': 'Sonntag · schreib in den Nahen Osten',
    'es': 'Domingo · escribe a Oriente Medio',
    'pt': 'Domingo · escreva para o Oriente Médio',
    'ru': 'Воскресенье · напишите на Ближний Восток',
    'tr': 'Pazar · Orta Doğu\'ya yazın',
    'ar': 'الأحد · اكتب إلى الشرق الأوسط',
    'it': 'Domenica · scrivi in Medio Oriente',
    'hi': 'रविवार · मध्य पूर्व को पत्र',
    'th': 'อาทิตย์ · เขียนไปตะวันออกกลาง',
  });
  String get composeQuickPickOpposite => _t({
    'ko': '지구 반대편',
    'en': 'Other side',
    'ja': '地球の反対側',
    'zh': '地球另一端',
    'fr': "À l'opposé",
    'de': 'Gegenseite',
    'es': 'Otro lado',
    'pt': 'Outro lado',
    'ru': 'Другая сторона',
    'tr': 'Karşı taraf',
    'ar': 'الجانب الآخر',
    'it': 'Altro lato',
    'hi': 'दूसरी ओर',
    'th': 'อีกฝั่ง',
  });
  String get composeQuickPickSunrise => _t({
    'ko': '지금 아침인 곳',
    'en': 'Sunrise now',
    'ja': '今朝の国',
    'zh': '此刻是清晨',
    'fr': 'Au lever du jour',
    'de': 'Sonnenaufgang jetzt',
    'es': 'Al amanecer',
    'pt': 'Amanhecer agora',
    'ru': 'Сейчас утро',
    'tr': 'Şu an sabah',
    'ar': 'الشروق الآن',
    'it': "All'alba adesso",
    'hi': 'अभी सुबह',
    'th': 'กำลังเป็นเช้า',
  });
  String get composeQuickPickUnvisited => _t({
    'ko': '안 가본 대륙',
    'en': 'New continent',
    'ja': '未訪大陸',
    'zh': '未到过的大洲',
    'fr': 'Continent inédit',
    'de': 'Neuer Kontinent',
    'es': 'Nuevo continente',
    'pt': 'Novo continente',
    'ru': 'Новый континент',
    'tr': 'Yeni kıta',
    'ar': 'قارة جديدة',
    'it': 'Nuovo continente',
    'hi': 'नया महाद्वीप',
    'th': 'ทวีปใหม่',
  });
  String get composeDailyPromptLabel => _t({
    'ko': '오늘의 영감',
    'en': "TODAY'S PROMPT",
    'ja': '今日のひとこと',
    'zh': '今日灵感',
    'fr': "INSPIRATION DU JOUR",
    'de': "TAGES-IMPULS",
    'es': "INSPIRACIÓN DE HOY",
    'pt': "INSPIRAÇÃO DE HOJE",
    'ru': "ВДОХНОВЕНИЕ ДНЯ",
    'tr': "BUGÜNÜN ESINI",
    'ar': "إلهام اليوم",
    'it': "SPUNTO DI OGGI",
    'hi': "आज की प्रेरणा",
    'th': "แรงบันดาลใจวันนี้",
  });

  // Build 117: 펜팔식 "처음 뵙겠어요" 자기소개 템플릿 → 헌트·브랜드 모두에
  // 중립적인 열린 프롬프트로 교체. 브랜드는 프로모 헤드라인, 비브랜드는
  // 메시지·인사를 자유롭게 쓰도록 유도.
  String get composeHint => _t({
    'ko': '이 홍보에 담고 싶은 이야기를 적어보세요...',
    'en': 'Write the message you want to send in this promo...',
    'ja': 'この手紙で伝えたいことを書いてみましょう...',
    'zh': '写下你想通过这封信传达的内容...',
    'fr': "Écris ce que tu veux partager dans cette lettre...",
    'de': 'Schreib, was du in diesem Brief mitteilen möchtest...',
    'es': 'Escribe lo que quieres decir en esta carta...',
    'pt': 'Escreve o que queres dizer nesta carta...',
    'ru': 'Напишите, что хотите передать в этом письме...',
    'tr': 'Bu mektupta paylaşmak istediklerini yaz...',
    'ar': 'اكتب ما تودّ قوله في هذه الرسالة...',
    'it': 'Scrivi ciò che vuoi dire in questa lettera...',
    'hi': 'इस पत्र में जो संदेश भेजना चाहते हैं, लिखें...',
    'th': 'เขียนสิ่งที่คุณอยากสื่อในจดหมายนี้...',
  });

  String get composeLinkAttach => _t({
    'ko': '링크 첨부',
    'en': 'Link Attachment',
    'ja': 'リンク添付',
    'zh': '链接附件',
    'fr': 'Lien joint',
    'de': 'Link-Anhang',
    'es': 'Adjuntar enlace',
    'pt': 'Anexar link',
    'ru': 'Прикрепить ссылку',
    'tr': 'Bağlantı ekle',
    'ar': 'إرفاق رابط',
    'it': 'Allega link',
    'hi': 'लिंक संलग्न',
    'th': 'แนบลิงก์',
  });

  String get composeLinkAttachDesc => _t({
    'ko': 'SNS, 블로그 링크를 홍보에 첨부할 수 있어요.\n프리미엄·브랜드 회원 전용 기능이에요.',
    'en': 'Attach SNS or blog links to your promo.\nPremium & Brand members only.',
    'ja': 'SNSやブログのリンクを手紙に添付できます。\nプレミアム・ブランド会員限定機能です。',
    'zh': '可以在信中附加SNS或博客链接。\n仅限高级和品牌会员。',
    'fr': 'Joignez des liens SNS ou blog à votre lettre.\nRéservé aux membres Premium et Brand.',
    'de': 'Fügen Sie SNS- oder Blog-Links an Ihren Brief an.\nNur für Premium- und Brand-Mitglieder.',
    'es': 'Adjunta enlaces de SNS o blog a tu carta.\nSolo miembros Premium y Brand.',
    'pt': 'Anexe links de SNS ou blog à sua carta.\nApenas membros Premium e Brand.',
    'ru': 'Прикрепите ссылки SNS или блога к письму.\nТолько для Premium и Brand участников.',
    'tr': 'SNS veya blog bağlantılarını mektubunuza ekleyin.\nSadece Premium ve Brand üyeler.',
    'ar': 'أرفق روابط SNS أو المدونة برسالتك.\nللأعضاء المميزين والعلامات التجارية فقط.',
    'it': 'Allega link SNS o blog alla tua lettera.\nSolo per membri Premium e Brand.',
    'hi': 'अपने पत्र में SNS या ब्लॉग लिंक संलग्न करें।\nकेवल Premium और Brand सदस्य।',
    'th': 'แนบลิงก์ SNS หรือบล็อกในจดหมาย\nเฉพาะสมาชิก Premium และ Brand',
  });

  String get composeSnsLinkAttach => _t({
    'ko': 'SNS 링크 첨부',
    'en': 'Attach SNS Link',
    'ja': 'SNSリンク添付',
    'zh': 'SNS链接附件',
    'fr': 'Joindre lien SNS',
    'de': 'SNS-Link anhängen',
    'es': 'Adjuntar enlace SNS',
    'pt': 'Anexar link SNS',
    'ru': 'Прикрепить ссылку SNS',
    'tr': 'SNS bağlantısı ekle',
    'ar': 'إرفاق رابط SNS',
    'it': 'Allega link SNS',
    'hi': 'SNS लिंक संलग्न करें',
    'th': 'แนบลิงก์ SNS',
  });

  String get composePremiumBrandOnly => _t({
    'ko': 'Premium · Brand 전용',
    'en': 'Premium · Brand only',
    'ja': 'Premium · Brand 専用',
    'zh': 'Premium · Brand 专属',
    'fr': 'Réservé Premium · Brand',
    'de': 'Nur Premium · Brand',
    'es': 'Solo Premium · Brand',
    'pt': 'Apenas Premium · Brand',
    'ru': 'Только Premium · Brand',
    'tr': 'Sadece Premium · Brand',
    'ar': 'حصري Premium · Brand',
    'it': 'Solo Premium · Brand',
    'hi': 'केवल Premium · Brand',
    'th': 'เฉพาะ Premium · Brand',
  });

  String get composeSnsLinkOptional => _t({
    'ko': 'SNS 링크 첨부 (선택)',
    'en': 'Attach SNS Link (optional)',
    'ja': 'SNSリンク添付（任意）',
    'zh': 'SNS链接附件（可选）',
    'fr': 'Joindre lien SNS (optionnel)',
    'de': 'SNS-Link anhängen (optional)',
    'es': 'Adjuntar enlace SNS (opcional)',
    'pt': 'Anexar link SNS (opcional)',
    'ru': 'Прикрепить ссылку SNS (необязательно)',
    'tr': 'SNS bağlantısı ekle (isteğe bağlı)',
    'ar': 'إرفاق رابط SNS (اختياري)',
    'it': 'Allega link SNS (opzionale)',
    'hi': 'SNS लिंक संलग्न करें (वैकल्पिक)',
    'th': 'แนบลิงก์ SNS (ไม่บังคับ)',
  });

  String get composeSnsLinkSub => _t({
    'ko': 'Instagram, X 등 — 연결을 원할 때만',
    'en': 'Instagram, X, etc. — only when you want to connect',
    'ja': 'Instagram、Xなど — つながりたい時だけ',
    'zh': 'Instagram、X 等 — 仅在想要连接时',
    'fr': 'Instagram, X, etc. — seulement si vous souhaitez vous connecter',
    'de': 'Instagram, X, usw. — nur wenn Sie sich verbinden möchten',
    'es': 'Instagram, X, etc. — solo cuando quieras conectar',
    'pt': 'Instagram, X, etc. — só quando quiser se conectar',
    'ru': 'Instagram, X и т.д. — только если хотите связаться',
    'tr': 'Instagram, X, vb. — yalnızca bağlantı kurmak istediğinizde',
    'ar': 'Instagram و X وغيرها — فقط عندما تريد التواصل',
    'it': 'Instagram, X, ecc. — solo quando vuoi connetterti',
    'hi': 'Instagram, X, आदि — केवल जब जुड़ना चाहें',
    'th': 'Instagram, X ฯลฯ — เมื่อต้องการเชื่อมต่อเท่านั้น',
  });

  String get composeBrandNoAnonymous => _t({
    'ko': '브랜드 계정은 익명 발송이 비활성화됩니다',
    'en': 'Anonymous sending is disabled for brand accounts',
    'ja': 'ブランドアカウントは匿名送信が無効です',
    'zh': '品牌账户不能匿名发送',
    'fr': 'L\'envoi anonyme est désactivé pour les comptes de marque',
    'de': 'Anonymes Senden ist für Markenkonten deaktiviert',
    'es': 'El envío anónimo está desactivado para cuentas de marca',
    'pt': 'O envio anônimo está desativado para contas de marca',
    'ru': 'Анонимная отправка отключена для бренд-аккаунтов',
    'tr': 'Marka hesapları için anonim gönderim devre dışıdır',
    'ar': 'الإرسال المجهول معطّل لحسابات العلامات التجارية',
    'it': 'L\'invio anonimo è disabilitato per gli account brand',
    'hi': 'ब्रांड खातों के लिए गुमनाम भेजना अक्षम है',
    'th': 'การส่งแบบไม่ระบุชื่อถูกปิดสำหรับบัญชีแบรนด์',
  });

  String get composeNamePublicBrand => _t({
    'ko': '이름 공개 (브랜드 필수)',
    'en': 'Name visible (Brand required)',
    'ja': '名前公開（ブランド必須）',
    'zh': '公开姓名（品牌必须）',
    'fr': 'Nom visible (obligatoire pour les marques)',
    'de': 'Name sichtbar (Marke erforderlich)',
    'es': 'Nombre visible (obligatorio para Marca)',
    'pt': 'Nome visível (obrigatório para Marca)',
    'ru': 'Имя видимое (обязательно для бренда)',
    'tr': 'Ad görünür (Marka için zorunlu)',
    'ar': 'الاسم مرئي (مطلوب للعلامة التجارية)',
    'it': 'Nome visibile (obbligatorio per Brand)',
    'hi': 'नाम दिखाई दे (ब्रांड अनिवार्य)',
    'th': 'แสดงชื่อ (แบรนด์ต้องแสดง)',
  });

  String get composeSendAnonymous => _t({
    'ko': '익명으로 발송',
    'en': 'Send anonymously',
    'ja': '匿名で送信',
    'zh': '匿名发送',
    'fr': 'Envoyer anonymement',
    'de': 'Anonym senden',
    'es': 'Enviar anónimamente',
    'pt': 'Enviar anonimamente',
    'ru': 'Отправить анонимно',
    'tr': 'Anonim gönder',
    'ar': 'إرسال مجهول',
    'it': 'Invia anonimamente',
    'hi': 'गुमनाम भेजें',
    'th': 'ส่งแบบไม่ระบุชื่อ',
  });

  String get composeNamePublic => _t({
    'ko': '이름 공개',
    'en': 'Name visible',
    'ja': '名前公開',
    'zh': '公开姓名',
    'fr': 'Nom visible',
    'de': 'Name sichtbar',
    'es': 'Nombre visible',
    'pt': 'Nome visível',
    'ru': 'Имя видимое',
    'tr': 'Ad görünür',
    'ar': 'الاسم مرئي',
    'it': 'Nome visibile',
    'hi': 'नाम दिखाई दे',
    'th': 'แสดงชื่อ',
  });

  String get composeBrandNoAnonymousSub => _t({
    'ko': '브랜드 계정은 익명 발송을 사용할 수 없어요',
    'en': 'Brand accounts cannot use anonymous sending',
    'ja': 'ブランドアカウントは匿名送信を使用できません',
    'zh': '品牌账户无法使用匿名发送',
    'fr': 'Les comptes de marque ne peuvent pas envoyer anonymement',
    'de': 'Markenkonten können nicht anonym senden',
    'es': 'Las cuentas de marca no pueden enviar anónimamente',
    'pt': 'Contas de marca não podem enviar anonimamente',
    'ru': 'Бренд-аккаунты не могут отправлять анонимно',
    'tr': 'Marka hesapları anonim gönderim kullanamaz',
    'ar': 'حسابات العلامات التجارية لا يمكنها الإرسال المجهول',
    'it': 'Gli account brand non possono inviare in modo anonimo',
    'hi': 'ब्रांड खाते गुमनाम भेजना उपयोग नहीं कर सकते',
    'th': 'บัญชีแบรนด์ไม่สามารถส่งแบบไม่ระบุชื่อ',
  });

  String get composeAnonymousSub => _t({
    'ko': '수신자가 발신자를 볼 수 없어요',
    'en': 'Recipient cannot see the sender',
    'ja': '受信者は送信者を見ることができません',
    'zh': '收件人无法看到发件人',
    'fr': 'Le destinataire ne peut pas voir l\'expéditeur',
    'de': 'Der Empfänger kann den Absender nicht sehen',
    'es': 'El destinatario no puede ver al remitente',
    'pt': 'O destinatário não pode ver o remetente',
    'ru': 'Получатель не увидит отправителя',
    'tr': 'Alıcı göndereni göremez',
    'ar': 'لا يمكن للمستلم رؤية المرسل',
    'it': 'Il destinatario non può vedere il mittente',
    'hi': 'प्राप्तकर्ता प्रेषक को नहीं देख सकता',
    'th': 'ผู้รับไม่สามารถเห็นผู้ส่ง',
  });

  String get composeNamePublicSub => _t({
    'ko': '수신자가 닉네임을 볼 수 있어요',
    'en': 'Recipient can see your nickname',
    'ja': '受信者はニックネームを見ることができます',
    'zh': '收件人可以看到你的昵称',
    'fr': 'Le destinataire peut voir votre pseudo',
    'de': 'Der Empfänger kann Ihren Spitznamen sehen',
    'es': 'El destinatario puede ver tu apodo',
    'pt': 'O destinatário pode ver seu apelido',
    'ru': 'Получатель увидит ваш никнейм',
    'tr': 'Alıcı takma adınızı görebilir',
    'ar': 'يمكن للمستلم رؤية اسمك المستعار',
    'it': 'Il destinatario può vedere il tuo nickname',
    'hi': 'प्राप्तकर्ता आपका उपनाम देख सकता है',
    'th': 'ผู้รับสามารถเห็นชื่อเล่นของคุณ',
  });

  String get composeBulkOn => _t({
    'ko': '대량 발송 ON',
    'en': 'Bulk Send ON',
    'ja': '大量送信 ON',
    'zh': '批量发送 ON',
    'fr': 'Envoi en masse ON',
    'de': 'Massenversand AN',
    'es': 'Envío masivo ON',
    'pt': 'Envio em massa ON',
    'ru': 'Массовая рассылка ВКЛ',
    'tr': 'Toplu Gönderim AÇIK',
    'ar': 'إرسال جماعي مفعّل',
    'it': 'Invio massivo ON',
    'hi': 'बल्क भेजना ON',
    'th': 'ส่งจำนวนมาก เปิด',
  });

  String get composeBulkBrandOnly => _t({
    'ko': '대량 발송 (Brand 전용)',
    'en': 'Bulk Send (Brand only)',
    'ja': '大量送信（Brand専用）',
    'zh': '批量发送（Brand 专属）',
    'fr': 'Envoi en masse (Brand uniquement)',
    'de': 'Massenversand (nur Brand)',
    'es': 'Envío masivo (solo Brand)',
    'pt': 'Envio em massa (apenas Brand)',
    'ru': 'Массовая рассылка (только Brand)',
    'tr': 'Toplu Gönderim (sadece Brand)',
    'ar': 'إرسال جماعي (Brand فقط)',
    'it': 'Invio massivo (solo Brand)',
    'hi': 'बल्क भेजना (केवल Brand)',
    'th': 'ส่งจำนวนมาก (Brand เท่านั้น)',
  });

  // ── Brand options ──────────────────────────────────────────────────────
  String get composeBrandOptions => _t({
    'ko': '브랜드 발송 옵션', 'en': 'Brand Send Options', 'ja': 'ブランド送信オプション', 'zh': '品牌发送选项',
    'fr': 'Options d\'envoi Brand', 'de': 'Brand-Sendeoptionen', 'es': 'Opciones de envío Brand',
    'pt': 'Opções de envio Brand', 'ru': 'Параметры отправки Brand', 'tr': 'Brand Gönderim Seçenekleri',
    'ar': 'خيارات إرسال Brand', 'it': 'Opzioni invio Brand', 'hi': 'Brand भेजने के विकल्प', 'th': 'ตัวเลือกการส่ง Brand',
  });

  String get composeBrandUniquePerUser => _t({
    'ko': '1인당 1회 수신 제한', 'en': 'Limit to 1 per recipient', 'ja': '1人1通に制限', 'zh': '每人限收1封',
    'fr': '1 par destinataire', 'de': '1 pro Empfänger', 'es': '1 por destinatario',
    'pt': '1 por destinatário', 'ru': '1 на получателя', 'tr': 'Alıcı başına 1',
    'ar': 'رسالة واحدة لكل مستلم', 'it': '1 per destinatario', 'hi': 'प्रति प्राप्तकर्ता 1', 'th': '1 ต่อผู้รับ',
  });

  String get composeBrandUniquePerUserDesc => _t({
    'ko': '같은 사용자에게 중복 발송되지 않습니다', 'en': 'Same user won\'t receive duplicate rewards', 'ja': '同じユーザーに重複送信されません', 'zh': '同一用户不会收到重复信件',
    'fr': 'L\'utilisateur ne recevra pas de doublons', 'de': 'Benutzer erhält keine Duplikate', 'es': 'El usuario no recibirá duplicados',
    'pt': 'Usuário não receberá duplicatas', 'ru': 'Пользователь не получит дублей', 'tr': 'Kullanıcı mükerrer almaz',
    'ar': 'لن يتلقى المستخدم نسخاً مكررة', 'it': 'L\'utente non riceverà duplicati', 'hi': 'उपयोगकर्ता को डुप्लिकेट नहीं मिलेगा', 'th': 'ผู้ใช้จะไม่ได้รับซ้ำ',
  });

  String get composeBrandAutoExpire => _t({
    'ko': '자동 삭제 기간', 'en': 'Auto-delete after', 'ja': '自動削除期間', 'zh': '自动删除时间',
    'fr': 'Suppression auto après', 'de': 'Automatisch löschen nach', 'es': 'Eliminar auto después de',
    'pt': 'Excluir auto após', 'ru': 'Авто-удаление через', 'tr': 'Otomatik silme süresi',
    'ar': 'حذف تلقائي بعد', 'it': 'Elimina auto dopo', 'hi': 'स्वत: हटाने की अवधि', 'th': 'ลบอัตโนมัติหลัง',
  });

  String get composeBrandAutoExpireDesc => _t({
    'ko': '설정 시간 후 혜택이 자동으로 사라집니다', 'en': 'Promo will auto-disappear after the set time', 'ja': '設定時間後にレターが自動的に消えます', 'zh': '设定时间后信件将自动消失',
    'fr': 'La lettre disparaîtra automatiquement', 'de': 'Brief verschwindet automatisch', 'es': 'La carta desaparecerá automáticamente',
    'pt': 'A carta desaparecerá automaticamente', 'ru': 'Письмо автоудалится', 'tr': 'Mektup otomatik silinir',
    'ar': 'ستختفي الرسالة تلقائياً', 'it': 'La lettera scomparirà automaticamente', 'hi': 'पत्र स्वतः गायब हो जाएगा', 'th': 'จดหมายจะหายไปโดยอัตโนมัติ',
  });

  String get composeBrandExpireOff => _t({
    'ko': '없음', 'en': 'None', 'ja': 'なし', 'zh': '无',
    'fr': 'Aucun', 'de': 'Keine', 'es': 'Ninguno',
    'pt': 'Nenhum', 'ru': 'Нет', 'tr': 'Yok',
    'ar': 'بلا', 'it': 'Nessuno', 'hi': 'कोई नहीं', 'th': 'ไม่มี',
  });

  String get composeBrandExpire12h => _t({
    'ko': '12시간', 'en': '12 hours', 'ja': '12時間', 'zh': '12小时',
    'fr': '12 heures', 'de': '12 Stunden', 'es': '12 horas',
    'pt': '12 horas', 'ru': '12 часов', 'tr': '12 saat',
    'ar': '12 ساعة', 'it': '12 ore', 'hi': '12 घंटे', 'th': '12 ชั่วโมง',
  });

  String get composeBrandExpire24h => _t({
    'ko': '24시간', 'en': '24 hours', 'ja': '24時間', 'zh': '24小时',
    'fr': '24 heures', 'de': '24 Stunden', 'es': '24 horas',
    'pt': '24 horas', 'ru': '24 часа', 'tr': '24 saat',
    'ar': '24 ساعة', 'it': '24 ore', 'hi': '24 घंटे', 'th': '24 ชั่วโมง',
  });

  String get composeBrandExpire2d => _t({
    'ko': '2일', 'en': '2 days', 'ja': '2日', 'zh': '2天',
    'fr': '2 jours', 'de': '2 Tage', 'es': '2 días',
    'pt': '2 dias', 'ru': '2 дня', 'tr': '2 gün',
    'ar': 'يومان', 'it': '2 giorni', 'hi': '2 दिन', 'th': '2 วัน',
  });

  String get composeBrandExpire3d => _t({
    'ko': '3일', 'en': '3 days', 'ja': '3日', 'zh': '3天',
    'fr': '3 jours', 'de': '3 Tage', 'es': '3 días',
    'pt': '3 dias', 'ru': '3 дня', 'tr': '3 gün',
    'ar': '3 أيام', 'it': '3 giorni', 'hi': '3 दिन', 'th': '3 วัน',
  });

  String get composeWithin5Min => _t({
    'ko': '5분 내 발송',
    'en': 'Sent within 5 min',
    'ja': '5分以内に発送',
    'zh': '5分钟内发送',
    'fr': 'Envoyé en 5 min',
    'de': 'Versand in 5 Min.',
    'es': 'Enviado en 5 min',
    'pt': 'Enviado em 5 min',
    'ru': 'Отправка за 5 мин',
    'tr': '5 dk içinde gönderilir',
    'ar': 'يُرسل خلال 5 دقائق',
    'it': 'Inviato in 5 min',
    'hi': '5 मिनट में भेजा',
    'th': 'ส่งภายใน 5 นาที',
  });

  String get composeExpressModeOn => _t({
    'ko': '특송 모드 ON — 선택한 나라에 즉시 다중 발송',
    'en': 'Express Mode ON — Instant multi-send to selected countries',
    'ja': '特送モード ON — 選択した国に即時多重送信',
    'zh': '特快模式 ON — 即时多重发送到选定国家',
    'fr': 'Mode Express ON — Envoi multiple instantané aux pays sélectionnés',
    'de': 'Express-Modus AN — Sofort-Mehrfachversand an ausgewählte Länder',
    'es': 'Modo Exprés ON — Envío múltiple instantáneo a países seleccionados',
    'pt': 'Modo Express ON — Envio múltiplo instantâneo para países selecionados',
    'ru': 'Экспресс-режим ВКЛ — Мгновенная множественная отправка в выбранные страны',
    'tr': 'Hızlı Mod AÇIK — Seçilen ülkelere anında çoklu gönderim',
    'ar': 'وضع سريع مفعّل — إرسال متعدد فوري إلى الدول المختارة',
    'it': 'Modalità Express ON — Invio multiplo istantaneo ai paesi selezionati',
    'hi': 'एक्सप्रेस मोड ON — चयनित देशों को तुरंत बहु-भेजना',
    'th': 'โหมดด่วน เปิด — ส่งหลายฉบับทันทีไปยังประเทศที่เลือก',
  });

  String get composeExpressModeBrand => _t({
    'ko': '특송 모드 (Brand 전용 · 5분 즉시 배송)',
    'en': 'Express Mode (Brand only · 5 min instant delivery)',
    'ja': '特送モード（Brand専用 · 5分即時配送）',
    'zh': '特快模式（Brand 专属 · 5分钟即时配送）',
    'fr': 'Mode Express (Brand uniquement · livraison instantanée 5 min)',
    'de': 'Express-Modus (nur Brand · 5 Min. Sofortlieferung)',
    'es': 'Modo Exprés (solo Brand · entrega instantánea 5 min)',
    'pt': 'Modo Express (apenas Brand · entrega instantânea 5 min)',
    'ru': 'Экспресс-режим (только Brand · доставка за 5 мин)',
    'tr': 'Hızlı Mod (sadece Brand · 5 dk anında teslimat)',
    'ar': 'وضع سريع (Brand فقط · توصيل فوري 5 دقائق)',
    'it': 'Modalità Express (solo Brand · consegna istantanea 5 min)',
    'hi': 'एक्सप्रेस मोड (केवल Brand · 5 मिनट तुरंत डिलीवरी)',
    'th': 'โหมดด่วน (Brand เท่านั้น · ส่งทันทีใน 5 นาที)',
  });

  String get composeExpressSettings => _t({
    'ko': '특송 설정',
    'en': 'Express Settings',
    'ja': '特送設定',
    'zh': '特快设置',
    'fr': 'Paramètres Express',
    'de': 'Express-Einstellungen',
    'es': 'Configuración Exprés',
    'pt': 'Configurações Express',
    'ru': 'Настройки экспресса',
    'tr': 'Hızlı Ayarları',
    'ar': 'إعدادات سريعة',
    'it': 'Impostazioni Express',
    'hi': 'एक्सप्रेस सेटिंग्स',
    'th': 'ตั้งค่าด่วน',
  });

  String get composeExpressSettingsSub => _t({
    'ko': '선택 나라의 랜덤 주소로 5분 안에 즉시 발송',
    'en': 'Instant delivery to random addresses in selected country within 5 min',
    'ja': '選択した国のランダムな住所へ5分以内に即時発送',
    'zh': '5分钟内即时发送到选定国家的随机地址',
    'fr': 'Envoi instantané à des adresses aléatoires du pays sélectionné en 5 min',
    'de': 'Sofortversand an zufällige Adressen im ausgewählten Land in 5 Min.',
    'es': 'Envío instantáneo a direcciones aleatorias del país seleccionado en 5 min',
    'pt': 'Envio instantâneo para endereços aleatórios no país selecionado em 5 min',
    'ru': 'Мгновенная доставка на случайные адреса выбранной страны за 5 мин',
    'tr': 'Seçilen ülkedeki rastgele adreslere 5 dk içinde anında teslimat',
    'ar': 'توصيل فوري إلى عناوين عشوائية في البلد المختار خلال 5 دقائق',
    'it': 'Consegna istantanea a indirizzi casuali nel paese selezionato in 5 min',
    'hi': 'चयनित देश में रैंडम पतों पर 5 मिनट में तुरंत डिलीवरी',
    'th': 'ส่งทันทีไปยังที่อยู่สุ่มในประเทศที่เลือกภายใน 5 นาที',
  });

  String get composeTargetCountry => _t({
    'ko': '발송 나라',
    'en': 'Target country',
    'ja': '送信先の国',
    'zh': '目标国家',
    'fr': 'Pays cible',
    'de': 'Zielland',
    'es': 'País destino',
    'pt': 'País alvo',
    'ru': 'Страна назначения',
    'tr': 'Hedef ülke',
    'ar': 'الدولة المستهدفة',
    'it': 'Paese destinazione',
    'hi': 'लक्ष्य देश',
    'th': 'ประเทศเป้าหมาย',
  });

  String get composeAddressCount => _t({
    'ko': '발송 수',
    'en': 'Address count',
    'ja': '送信先アドレス数',
    'zh': '地址数量',
    'fr': 'Nombre d\'adresses',
    'de': 'Adressanzahl',
    'es': 'Cantidad de direcciones',
    'pt': 'Número de endereços',
    'ru': 'Количество адресов',
    'tr': 'Adres sayısı',
    'ar': 'عدد العناوين',
    'it': 'Numero di indirizzi',
    'hi': 'पता संख्या',
    'th': 'จำนวนที่อยู่',
  });

  String composeCountUnit(int count) => _t({
    'ko': '$count 개',
    'en': '$count',
    'ja': '$count 個',
    'zh': '$count 个',
    'fr': '$count',
    'de': '$count',
    'es': '$count',
    'pt': '$count',
    'ru': '$count',
    'tr': '$count',
    'ar': '$count',
    'it': '$count',
    'hi': '$count',
    'th': '$count',
  });

  String composeExpressSummary(String flag, String country, int count) => _t({
    'ko': '⚡ $flag $country 내 ${count}개 랜덤 주소로 5분 내 즉시 배송',
    'en': '⚡ Instant delivery to $count random addresses in $flag $country within 5 min',
    'ja': '⚡ $flag $country内${count}か所のランダムアドレスへ5分以内に即時配送',
    'zh': '⚡ 5分钟内即时送达$flag $country的$count个随机地址',
    'fr': '⚡ Livraison instantanée à $count adresses aléatoires en $flag $country en 5 min',
    'de': '⚡ Sofortlieferung an $count Zufallsadressen in $flag $country in 5 Min.',
    'es': '⚡ Entrega instantánea a $count direcciones aleatorias en $flag $country en 5 min',
    'pt': '⚡ Entrega instantânea para $count endereços aleatórios em $flag $country em 5 min',
    'ru': '⚡ Мгновенная доставка на $count случайных адресов в $flag $country за 5 мин',
    'tr': '⚡ $flag $country\'da $count rastgele adrese 5 dk içinde anında teslimat',
    'ar': '⚡ توصيل فوري إلى $count عنوان عشوائي في $flag $country خلال 5 دقائق',
    'it': '⚡ Consegna istantanea a $count indirizzi casuali in $flag $country in 5 min',
    'hi': '⚡ $flag $country में $count रैंडम पतों पर 5 मिनट में तुरंत डिलीवरी',
    'th': '⚡ ส่งทันทีไปยัง $count ที่อยู่สุ่มใน $flag $country ภายใน 5 นาที',
  });

  String get composeSelectCountryAbove => _t({
    'ko': '위에서 나라를 선택해주세요',
    'en': 'Please select a country above',
    'ja': '上から国を選択してください',
    'zh': '请在上方选择国家',
    'fr': 'Veuillez sélectionner un pays ci-dessus',
    'de': 'Bitte wählen Sie oben ein Land aus',
    'es': 'Selecciona un país arriba',
    'pt': 'Selecione um país acima',
    'ru': 'Выберите страну выше',
    'tr': 'Yukarıdan bir ülke seçin',
    'ar': 'يرجى اختيار دولة أعلاه',
    'it': 'Seleziona un paese sopra',
    'hi': 'ऊपर एक देश चुनें',
    'th': 'กรุณาเลือกประเทศด้านบน',
  });

  String get composeExpressOnShort => _t({
    'ko': '특송 ON — 5분 내 즉시 발송',
    'en': 'Express ON — Instant delivery in 5 min',
    'ja': '特送 ON — 5分以内に即時発送',
    'zh': '特快 ON — 5分钟内即时发送',
    'fr': 'Express ON — Livraison instantanée en 5 min',
    'de': 'Express AN — Sofortlieferung in 5 Min.',
    'es': 'Exprés ON — Entrega instantánea en 5 min',
    'pt': 'Express ON — Entrega instantânea em 5 min',
    'ru': 'Экспресс ВКЛ — Мгновенная доставка за 5 мин',
    'tr': 'Hızlı AÇIK — 5 dk içinde anında teslimat',
    'ar': 'سريع مفعّل — توصيل فوري خلال 5 دقائق',
    'it': 'Express ON — Consegna istantanea in 5 min',
    'hi': 'एक्सप्रेस ON — 5 मिनट में तुरंत डिलीवरी',
    'th': 'ด่วน เปิด — ส่งทันทีใน 5 นาที',
  });

  String get composeExpressDeliveryEachCountry => _t({
    'ko': '선택한 각 나라의 랜덤 주소로 5분 안에 즉시 배송',
    'en': 'Instant delivery to random addresses in each selected country within 5 min',
    'ja': '選択した各国のランダムアドレスへ5分以内に即時配送',
    'zh': '5分钟内即时送达每个选定国家的随机地址',
    'fr': 'Livraison instantanée à des adresses aléatoires dans chaque pays sélectionné en 5 min',
    'de': 'Sofortlieferung an Zufallsadressen in jedem ausgewählten Land in 5 Min.',
    'es': 'Entrega instantánea a direcciones aleatorias en cada país seleccionado en 5 min',
    'pt': 'Entrega instantânea para endereços aleatórios em cada país selecionado em 5 min',
    'ru': 'Мгновенная доставка на случайные адреса каждой выбранной страны за 5 мин',
    'tr': 'Seçilen her ülkedeki rastgele adreslere 5 dk içinde anında teslimat',
    'ar': 'توصيل فوري إلى عناوين عشوائية في كل دولة مختارة خلال 5 دقائق',
    'it': 'Consegna istantanea a indirizzi casuali in ogni paese selezionato in 5 min',
    'hi': 'प्रत्येक चयनित देश में रैंडम पतों पर 5 मिनट में तुरंत डिलीवरी',
    'th': 'ส่งทันทีไปยังที่อยู่สุ่มในแต่ละประเทศที่เลือกภายใน 5 นาที',
  });

  String get composeAddressPerCountry => _t({
    'ko': '나라당 발송 수',
    'en': 'Sends per country',
    'ja': '国ごとの送信先アドレス数',
    'zh': '每个国家的地址数',
    'fr': 'Adresses par pays',
    'de': 'Adressen pro Land',
    'es': 'Direcciones por país',
    'pt': 'Endereços por país',
    'ru': 'Адресов на страну',
    'tr': 'Ülke başına adres',
    'ar': 'عناوين لكل دولة',
    'it': 'Indirizzi per paese',
    'hi': 'प्रति देश पते',
    'th': 'ที่อยู่ต่อประเทศ',
  });

  String get composeBulkRandomCountry => _t({
    'ko': '랜덤 국가로 발송',
    'en': 'Send to random countries',
    'ja': 'ランダムな国に送信',
    'zh': '随机国家发送',
  });

  String get composeBulkRandomDesc => _t({
    'ko': '198개국 중 랜덤으로 선택하여 발송합니다',
    'en': 'Promos sent to random countries from 198 nations',
    'ja': '198カ国からランダムに選んで送信します',
    'zh': '从198个国家中随机选择发送',
  });

  String composeBulkRandomSummary(int count) => _t({
    'ko': '랜덤 국가 ${count}통 발송',
    'en': '$count promos to random countries',
    'ja': 'ランダム国 ${count}通送信',
    'zh': '随机国家 $count封',
  });

  String get composeSelectTargetCountry => _t({
    'ko': '발송 나라 선택',
    'en': 'Select target countries',
    'ja': '送信先の国を選択',
    'zh': '选择目标国家',
    'fr': 'Sélectionner les pays cibles',
    'de': 'Zielländer auswählen',
    'es': 'Seleccionar países destino',
    'pt': 'Selecionar países alvo',
    'ru': 'Выберите страны назначения',
    'tr': 'Hedef ülkeleri seçin',
    'ar': 'اختر الدول المستهدفة',
    'it': 'Seleziona paesi destinazione',
    'hi': 'लक्ष्य देश चुनें',
    'th': 'เลือกประเทศเป้าหมาย',
  });

  String composeSelectedCount(int count) => _t({
    'ko': '${count}개 선택',
    'en': '$count selected',
    'ja': '${count}件選択',
    'zh': '已选${count}个',
    'fr': '$count sélectionné(s)',
    'de': '$count ausgewählt',
    'es': '$count seleccionados',
    'pt': '$count selecionados',
    'ru': '$count выбрано',
    'tr': '$count seçili',
    'ar': 'تم اختيار $count',
    'it': '$count selezionati',
    'hi': '$count चुने गए',
    'th': 'เลือกแล้ว $count',
  });

  String get composeSendPerCountry => _t({
    'ko': '나라당 발송 횟수',
    'en': 'Promos per country',
    'ja': '国ごとの送信回数',
    'zh': '每个国家的发送次数',
    'fr': 'Lettres par pays',
    'de': 'Briefe pro Land',
    'es': 'Cartas por país',
    'pt': 'Cartas por país',
    'ru': 'Писем на страну',
    'tr': 'Ülke başına mektup',
    'ar': 'رسائل لكل دولة',
    'it': 'Lettere per paese',
    'hi': 'प्रति देश पत्र',
    'th': 'จดหมายต่อประเทศ',
  });

  String composeBulkExpressSummary(int total, int countries, int addresses) => _t({
    'ko': '⚡ 총 ${total}통 즉시 발송 · ${countries}개 나라 × ${addresses}주소씩',
    'en': '⚡ $total promos instant · $countries countries × $addresses addresses each',
    'ja': '⚡ 合計${total}通即時発送 · ${countries}か国 × ${addresses}アドレスずつ',
    'zh': '⚡ 共${total}封即时发送 · $countries个国家 × 每国${addresses}个地址',
    'fr': '⚡ $total lettres instantanées · $countries pays × $addresses adresses chacun',
    'de': '⚡ $total Briefe sofort · $countries Länder × $addresses Adressen je',
    'es': '⚡ $total cartas instantáneas · $countries países × $addresses direcciones cada uno',
    'pt': '⚡ $total cartas instantâneas · $countries países × $addresses endereços cada',
    'ru': '⚡ $total писем мгновенно · $countries стран × $addresses адресов каждая',
    'tr': '⚡ Toplam $total mektup anında · $countries ülke × $addresses adres',
    'ar': '⚡ $total رسالة فورية · $countries دول × $addresses عنوان لكل دولة',
    'it': '⚡ $total lettere istantanee · $countries paesi × $addresses indirizzi ciascuno',
    'hi': '⚡ कुल $total पत्र तुरंत · $countries देश × $addresses पते प्रत्येक',
    'th': '⚡ รวม $total ฉบับทันที · $countries ประเทศ × $addresses ที่อยู่ต่อประเทศ',
  });

  String composeBulkSendSummary(int total, int countries, int perCountry) => _t({
    'ko': '📬 총 ${total}통 발송 예정 · ${countries}개 나라 × ${perCountry}통씩',
    'en': '📬 $total promos to send · $countries countries × $perCountry each',
    'ja': '📬 合計${total}通送信予定 · ${countries}か国 × ${perCountry}通ずつ',
    'zh': '📬 共${total}封待发送 · $countries个国家 × 每国${perCountry}封',
    'fr': '📬 $total lettres à envoyer · $countries pays × $perCountry chacun',
    'de': '📬 $total Briefe zu senden · $countries Länder × $perCountry je',
    'es': '📬 $total cartas a enviar · $countries países × $perCountry cada uno',
    'pt': '📬 $total cartas para enviar · $countries países × $perCountry cada',
    'ru': '📬 $total писем к отправке · $countries стран × $perCountry каждая',
    'tr': '📬 Toplam $total mektup gönderilecek · $countries ülke × $perCountry',
    'ar': '📬 $total رسالة للإرسال · $countries دول × $perCountry لكل دولة',
    'it': '📬 $total lettere da inviare · $countries paesi × $perCountry ciascuno',
    'hi': '📬 कुल $total पत्र भेजने हैं · $countries देश × $perCountry प्रत्येक',
    'th': '📬 รวม $total ฉบับที่จะส่ง · $countries ประเทศ × $perCountry ต่อประเทศ',
  });

  String get composeDeliveryIn5Min => _t({
    'ko': '발송 후 5분 내 수신자 수집첩에 도착',
    'en': 'Arrives in recipient\'s inbox within 5 min after sending',
    'ja': '送信後5分以内に受信者の受信箱に到着',
    'zh': '发送后5分钟内到达收件人邮箱',
    'fr': 'Arrivée dans la boîte du destinataire en 5 min après l\'envoi',
    'de': 'Ankunft im Postfach des Empfängers in 5 Min. nach dem Senden',
    'es': 'Llega al buzón del destinatario en 5 min después del envío',
    'pt': 'Chega na caixa do destinatário em 5 min após o envio',
    'ru': 'Поступит в ящик получателя в течение 5 мин после отправки',
    'tr': 'Gönderimden sonra 5 dk içinde alıcının kutusuna ulaşır',
    'ar': 'يصل إلى صندوق المستلم خلال 5 دقائق بعد الإرسال',
    'it': 'Arriva nella casella del destinatario entro 5 min dall\'invio',
    'hi': 'भेजने के बाद 5 मिनट में प्राप्तकर्ता के इनबॉक्स में पहुंचता है',
    'th': 'ถึงกล่องจดหมายผู้รับภายใน 5 นาทีหลังส่ง',
  });

  String get composeImageProcessing => _t({
    'ko': '이미지 처리 중...',
    'en': 'Processing image...',
    'ja': '画像処理中...',
    'zh': '处理图片中...',
    'fr': 'Traitement de l\'image...',
    'de': 'Bild wird verarbeitet...',
    'es': 'Procesando imagen...',
    'pt': 'Processando imagem...',
    'ru': 'Обработка изображения...',
    'tr': 'Resim işleniyor...',
    'ar': 'جاري معالجة الصورة...',
    'it': 'Elaborazione immagine...',
    'hi': 'छवि प्रोसेस हो रही है...',
    'th': 'กำลังประมวลผลรูปภาพ...',
  });

  String get composePhotoAttached => _t({
    'ko': '사진 첨부됨 (탭해서 변경)',
    'en': 'Photo attached (tap to change)',
    'ja': '写真添付済み（タップして変更）',
    'zh': '已附照片（点击更改）',
    'fr': 'Photo jointe (appuyez pour changer)',
    'de': 'Foto angehängt (tippen zum Ändern)',
    'es': 'Foto adjuntada (toca para cambiar)',
    'pt': 'Foto anexada (toque para alterar)',
    'ru': 'Фото прикреплено (нажмите для изменения)',
    'tr': 'Fotoğraf eklendi (değiştirmek için dokun)',
    'ar': 'تم إرفاق صورة (انقر للتغيير)',
    'it': 'Foto allegata (tocca per cambiare)',
    'hi': 'फोटो संलग्न (बदलने के लिए टैप करें)',
    'th': 'แนบรูปแล้ว (แตะเพื่อเปลี่ยน)',
  });

  String get composePhotoAttachPremium => _t({
    'ko': '사진 첨부 (프리미엄 · 1일 20통)',
    'en': 'Photo Attachment (Premium · 20/day)',
    'ja': '写真添付（プレミアム · 1日20通）',
    'zh': '照片附件（Premium · 每天20封）',
    'fr': 'Photo jointe (Premium · 20/jour)',
    'de': 'Foto anhängen (Premium · 20/Tag)',
    'es': 'Adjuntar foto (Premium · 20/día)',
    'pt': 'Anexar foto (Premium · 20/dia)',
    'ru': 'Фото (Premium · 20/день)',
    'tr': 'Fotoğraf ekle (Premium · günde 20)',
    'ar': 'إرفاق صورة (Premium · 20/يوم)',
    'it': 'Allega foto (Premium · 20/giorno)',
    'hi': 'फोटो संलग्न (Premium · 20/दिन)',
    'th': 'แนบรูปภาพ (Premium · 20/วัน)',
  });

  String get composePhotoAttachLocked => _t({
    'ko': '사진 첨부 — Premium 전용',
    'en': 'Photo Attachment — Premium only',
    'ja': '写真添付 — Premium専用',
    'zh': '照片附件 — 仅限Premium',
    'fr': 'Photo jointe — Premium uniquement',
    'de': 'Foto anhängen — nur Premium',
    'es': 'Adjuntar foto — solo Premium',
    'pt': 'Anexar foto — apenas Premium',
    'ru': 'Фото — только Premium',
    'tr': 'Fotoğraf ekle — sadece Premium',
    'ar': 'إرفاق صورة — Premium فقط',
    'it': 'Allega foto — solo Premium',
    'hi': 'फोटो संलग्न — केवल Premium',
    'th': 'แนบรูปภาพ — Premium เท่านั้น',
  });

  String composeQuotaRemaining(int remaining) => _t({
    'ko': '${remaining}통 남음',
    'en': '$remaining left',
    'ja': '残り${remaining}通',
    'zh': '剩余${remaining}封',
    'fr': '$remaining restant(s)',
    'de': '$remaining übrig',
    'es': '$remaining restantes',
    'pt': '$remaining restantes',
    'ru': 'Осталось $remaining',
    'tr': '$remaining kaldı',
    'ar': 'متبقي $remaining',
    'it': '$remaining rimanenti',
    'hi': '$remaining शेष',
    'th': 'เหลือ $remaining',
  });

  String get composeDecorate => _t({
    'ko': '꾸미기',
    'en': 'Decorate',
    'ja': 'デコレーション',
    'zh': '装饰',
    'fr': 'Décorer',
    'de': 'Dekorieren',
    'es': 'Decorar',
    'pt': 'Decorar',
    'ru': 'Украсить',
    'tr': 'Süsle',
    'ar': 'تزيين',
    'it': 'Decora',
    'hi': 'सजाएं',
    'th': 'ตกแต่ง',
  });

  String get composeDecorating => _t({
    'ko': '꾸미는 중',
    'en': 'Decorating',
    'ja': 'デコレーション中',
    'zh': '装饰中',
    'fr': 'Décoration',
    'de': 'Dekoriere',
    'es': 'Decorando',
    'pt': 'Decorando',
    'ru': 'Украшение',
    'tr': 'Süsleniyor',
    'ar': 'تزيين',
    'it': 'Decorando',
    'hi': 'सजा रहे हैं',
    'th': 'กำลังตกแต่ง',
  });

  String get composeEmojiDecorate => _t({
    'ko': '배송 이모티콘 꾸미기',
    'en': 'Delivery Emoji Decoration',
    'ja': '配送絵文字デコレーション',
    'zh': '配送表情装饰',
    'fr': 'Décoration emoji de livraison',
    'de': 'Liefer-Emoji-Dekoration',
    'es': 'Decoración de emoji de envío',
    'pt': 'Decoração de emoji de entrega',
    'ru': 'Украшение эмодзи доставки',
    'tr': 'Teslimat Emoji Süslemesi',
    'ar': 'تزيين رموز التوصيل',
    'it': 'Decorazione emoji consegna',
    'hi': 'डिलीवरी इमोजी सजावट',
    'th': 'ตกแต่งอิโมจิจัดส่ง',
  });

  String get composeEmojiDecorateSub => _t({
    'ko': '각 카테고리에서 1개씩 조합 선택 가능',
    'en': 'Pick 1 from each category to create a combo',
    'ja': '各カテゴリから1つずつ組み合わせ選択可能',
    'zh': '每个类别可选1个进行组合',
    'fr': 'Choisissez 1 par catégorie pour créer un combo',
    'de': 'Wählen Sie 1 pro Kategorie für eine Kombination',
    'es': 'Elige 1 de cada categoría para crear un combo',
    'pt': 'Escolha 1 de cada categoria para criar um combo',
    'ru': 'Выберите по 1 из каждой категории для комбинации',
    'tr': 'Her kategoriden 1 seçerek bir kombinasyon oluşturun',
    'ar': 'اختر 1 من كل فئة لإنشاء مجموعة',
    'it': 'Scegli 1 per categoria per creare un combo',
    'hi': 'कॉम्बो बनाने के लिए प्रत्येक श्रेणी से 1 चुनें',
    'th': 'เลือก 1 จากแต่ละหมวดเพื่อสร้างคอมโบ',
  });

  String get composeReset => _t({
    'ko': '초기화',
    'en': 'Reset',
    'ja': 'リセット',
    'zh': '重置',
    'fr': 'Réinitialiser',
    'de': 'Zurücksetzen',
    'es': 'Restablecer',
    'pt': 'Redefinir',
    'ru': 'Сбросить',
    'tr': 'Sıfırla',
    'ar': 'إعادة تعيين',
    'it': 'Reimposta',
    'hi': 'रीसेट',
    'th': 'รีเซ็ต',
  });

  String get composeSelectedCombo => _t({
    'ko': '선택 조합',
    'en': 'Selected combo',
    'ja': '選択した組み合わせ',
    'zh': '已选组合',
    'fr': 'Combo sélectionné',
    'de': 'Ausgewählte Kombination',
    'es': 'Combo seleccionado',
    'pt': 'Combo selecionado',
    'ru': 'Выбранная комбинация',
    'tr': 'Seçilen kombinasyon',
    'ar': 'المجموعة المختارة',
    'it': 'Combo selezionato',
    'hi': 'चयनित कॉम्बो',
    'th': 'คอมโบที่เลือก',
  });

  String get composeLand => _t({
    'ko': '육지',
    'en': 'Land',
    'ja': '陸路',
    'zh': '陆地',
    'fr': 'Terre',
    'de': 'Land',
    'es': 'Tierra',
    'pt': 'Terra',
    'ru': 'Суша',
    'tr': 'Kara',
    'ar': 'بري',
    'it': 'Terra',
    'hi': 'ज़मीन',
    'th': 'ทางบก',
  });

  String get composeAir => _t({
    'ko': '항공',
    'en': 'Air',
    'ja': '空路',
    'zh': '航空',
    'fr': 'Air',
    'de': 'Luft',
    'es': 'Aéreo',
    'pt': 'Aéreo',
    'ru': 'Воздух',
    'tr': 'Hava',
    'ar': 'جوي',
    'it': 'Aria',
    'hi': 'हवाई',
    'th': 'ทางอากาศ',
  });

  String get composeSea => _t({
    'ko': '바다',
    'en': 'Sea',
    'ja': '海路',
    'zh': '海洋',
    'fr': 'Mer',
    'de': 'See',
    'es': 'Mar',
    'pt': 'Mar',
    'ru': 'Море',
    'tr': 'Deniz',
    'ar': 'بحري',
    'it': 'Mare',
    'hi': 'समुद्र',
    'th': 'ทางทะเล',
  });

  String get composeComboDone => _t({
    'ko': '조합 완료 ✓',
    'en': 'Combo Done ✓',
    'ja': '組み合わせ完了 ✓',
    'zh': '组合完成 ✓',
    'fr': 'Combo terminé ✓',
    'de': 'Kombination fertig ✓',
    'es': 'Combo listo ✓',
    'pt': 'Combo pronto ✓',
    'ru': 'Комбинация готова ✓',
    'tr': 'Kombinasyon tamam ✓',
    'ar': 'المجموعة جاهزة ✓',
    'it': 'Combo fatto ✓',
    'hi': 'कॉम्बो पूरा ✓',
    'th': 'คอมโบเสร็จ ✓',
  });

  String get composeCloseNoSelection => _t({
    'ko': '선택 없이 닫기',
    'en': 'Close without selection',
    'ja': '選択せずに閉じる',
    'zh': '不选择关闭',
    'fr': 'Fermer sans sélection',
    'de': 'Ohne Auswahl schließen',
    'es': 'Cerrar sin selección',
    'pt': 'Fechar sem seleção',
    'ru': 'Закрыть без выбора',
    'tr': 'Seçim yapmadan kapat',
    'ar': 'إغلاق بدون اختيار',
    'it': 'Chiudi senza selezione',
    'hi': 'बिना चयन बंद करें',
    'th': 'ปิดโดยไม่เลือก',
  });

  String get composePaperSelect => _t({
    'ko': '카드 디자인 선택',
    'en': 'Select Paper',
    'ja': '便箋を選択',
    'zh': '选择信纸',
    'fr': 'Choisir le papier',
    'de': 'Papier auswählen',
    'es': 'Seleccionar papel',
    'pt': 'Selecionar papel',
    'ru': 'Выбрать бумагу',
    'tr': 'Kağıt seç',
    'ar': 'اختر الورق',
    'it': 'Seleziona carta',
    'hi': 'कागज़ चुनें',
    'th': 'เลือกกระดาษ',
  });

  String get composeMorePaperPro => _t({
    'ko': '더 많은 카드 디자인 (PRO)',
    'en': 'More papers (PRO)',
    'ja': 'もっと便箋（PRO）',
    'zh': '更多信纸（PRO）',
    'fr': 'Plus de papiers (PRO)',
    'de': 'Mehr Papiere (PRO)',
    'es': 'Más papeles (PRO)',
    'pt': 'Mais papéis (PRO)',
    'ru': 'Больше бумаг (PRO)',
    'tr': 'Daha fazla kağıt (PRO)',
    'ar': 'المزيد من الأوراق (PRO)',
    'it': 'Più carte (PRO)',
    'hi': 'अधिक कागज़ (PRO)',
    'th': 'กระดาษเพิ่มเติม (PRO)',
  });

  String get composeComingSoon => _t({
    'ko': '추후 제공',
    'en': 'Coming soon',
    'ja': '近日公開',
    'zh': '即将推出',
    'fr': 'Bientôt disponible',
    'de': 'Demnächst',
    'es': 'Próximamente',
    'pt': 'Em breve',
    'ru': 'Скоро',
    'tr': 'Yakında',
    'ar': 'قريبًا',
    'it': 'In arrivo',
    'hi': 'जल्द आ रहा है',
    'th': 'เร็วๆ นี้',
  });

  String get composeFontSelect => _t({
    'ko': '폰트 선택',
    'en': 'Select Font',
    'ja': 'フォントを選択',
    'zh': '选择字体',
    'fr': 'Choisir la police',
    'de': 'Schriftart auswählen',
    'es': 'Seleccionar fuente',
    'pt': 'Selecionar fonte',
    'ru': 'Выбрать шрифт',
    'tr': 'Yazı tipi seç',
    'ar': 'اختر الخط',
    'it': 'Seleziona font',
    'hi': 'फ़ॉन्ट चुनें',
    'th': 'เลือกฟอนต์',
  });

  String get composeMoreFontPro => _t({
    'ko': '더 많은 폰트 / 텍스트 효과 (PRO)',
    'en': 'More fonts / text effects (PRO)',
    'ja': 'もっとフォント / テキスト効果（PRO）',
    'zh': '更多字体/文字效果（PRO）',
    'fr': 'Plus de polices / effets texte (PRO)',
    'de': 'Mehr Schriftarten / Texteffekte (PRO)',
    'es': 'Más fuentes / efectos de texto (PRO)',
    'pt': 'Mais fontes / efeitos de texto (PRO)',
    'ru': 'Больше шрифтов / текстовых эффектов (PRO)',
    'tr': 'Daha fazla yazı tipi / metin efekti (PRO)',
    'ar': 'المزيد من الخطوط / تأثيرات النص (PRO)',
    'it': 'Più font / effetti testo (PRO)',
    'hi': 'अधिक फ़ॉन्ट / टेक्स्ट प्रभाव (PRO)',
    'th': 'ฟอนต์เพิ่มเติม / เอฟเฟกต์ข้อความ (PRO)',
  });

  String get composeFontPreview => _t({
    'ko': '가나다라마바사 Aa Bb',
    'en': 'The quick brown fox Aa Bb',
    'ja': 'あいうえおかきく Aa Bb',
    'zh': '天地玄黄宇宙洪荒 Aa Bb',
    'fr': 'Le vif renard brun Aa Bb',
    'de': 'Franz jagt im Aa Bb',
    'es': 'El rápido zorro Aa Bb',
    'pt': 'A rápida raposa Aa Bb',
    'ru': 'Быстрая бурая лиса Aa Bb',
    'tr': 'Pijamalı hasta Aa Bb',
    'ar': 'صندوق خشب أبجد Aa Bb',
    'it': 'La volpe marrone Aa Bb',
    'hi': 'सरल हिंदी पाठ Aa Bb',
    'th': 'กขคงจฉชซ Aa Bb',
  });

  String composeExpressQuota(int used, int limit) => _t({
    'ko': '특급 $used/${limit}통',
    'en': 'Express $used/$limit',
    'ja': '特急 $used/${limit}通',
    'zh': '特快 $used/$limit封',
    'fr': 'Express $used/$limit',
    'de': 'Express $used/$limit',
    'es': 'Exprés $used/$limit',
    'pt': 'Express $used/$limit',
    'ru': 'Экспресс $used/$limit',
    'tr': 'Hızlı $used/$limit',
    'ar': 'سريع $used/$limit',
    'it': 'Express $used/$limit',
    'hi': 'एक्सप्रेस $used/$limit',
    'th': 'ด่วน $used/$limit',
  });

  String composeBonus(int credits) => _t({
    'ko': '보너스 ${credits}통',
    'en': 'Bonus $credits',
    'ja': 'ボーナス ${credits}通',
    'zh': '奖励${credits}封',
    'fr': 'Bonus $credits',
    'de': 'Bonus $credits',
    'es': 'Bonus $credits',
    'pt': 'Bônus $credits',
    'ru': 'Бонус $credits',
    'tr': 'Bonus $credits',
    'ar': 'مكافأة $credits',
    'it': 'Bonus $credits',
    'hi': 'बोनस $credits',
    'th': 'โบนัส $credits',
  });

  String composeQuotaGeneral(int sent, int limit, int remaining) => _t({
    // "0/3 · 남은 3통" 은 중복 정보. 분수만 남겨 간결하게.
    'ko': '오늘 발송 $sent/${limit}통',
    'en': 'Today $sent / $limit sent',
    'ja': '本日 $sent / ${limit}通送信',
    'zh': '今日已发 $sent / $limit 封',
    'fr': 'Aujourd\'hui $sent / $limit envoyés',
    'de': 'Heute $sent / $limit gesendet',
    'es': 'Hoy $sent / $limit enviadas',
    'pt': 'Hoje $sent / $limit enviadas',
    'ru': 'Сегодня $sent / $limit отправлено',
    'tr': 'Bugün $sent / $limit gönderildi',
    'ar': 'اليوم $sent / $limit مرسل',
    'it': 'Oggi $sent / $limit inviate',
    'hi': 'आज $sent / $limit भेजे',
    'th': 'วันนี้ส่ง $sent / $limit',
  });

  String composeQuotaBrand(int sent, int limit, int monthlyRemaining) => _t({
    'ko': '브랜드 · 오늘 $sent/${limit}통 · 남은 ${monthlyRemaining}통/월',
    'en': 'Brand · Today $sent/$limit · $monthlyRemaining/mo remaining',
    'ja': 'ブランド · 本日 $sent/${limit}通 · 残り${monthlyRemaining}通/月',
    'zh': '品牌 · 今日$sent/$limit封 · 月剩余${monthlyRemaining}封',
    'fr': 'Brand · Aujourd\'hui $sent/$limit · $monthlyRemaining/mois restants',
    'de': 'Brand · Heute $sent/$limit · $monthlyRemaining/Monat übrig',
    'es': 'Brand · Hoy $sent/$limit · $monthlyRemaining/mes restantes',
    'pt': 'Brand · Hoje $sent/$limit · $monthlyRemaining/mês restantes',
    'ru': 'Бренд · Сегодня $sent/$limit · осталось $monthlyRemaining/мес',
    'tr': 'Brand · Bugün $sent/$limit · $monthlyRemaining/ay kaldı',
    'ar': 'Brand · اليوم $sent/$limit · متبقي $monthlyRemaining/شهر',
    'it': 'Brand · Oggi $sent/$limit · $monthlyRemaining/mese rimanenti',
    'hi': 'Brand · आज $sent/$limit · $monthlyRemaining/माह शेष',
    'th': 'Brand · วันนี้ $sent/$limit · เหลือ $monthlyRemaining/เดือน',
  });

  String composeQuotaPremium(int sent, int limit, int monthlyRemaining) => _t({
    'ko': '프리미엄 · 오늘 $sent/${limit}통 · 남은 ${monthlyRemaining}통/월',
    'en': 'Premium · Today $sent/$limit · $monthlyRemaining/mo remaining',
    'ja': 'プレミアム · 本日 $sent/${limit}通 · 残り${monthlyRemaining}通/月',
    'zh': '高级 · 今日$sent/$limit封 · 月剩余${monthlyRemaining}封',
    'fr': 'Premium · Aujourd\'hui $sent/$limit · $monthlyRemaining/mois restants',
    'de': 'Premium · Heute $sent/$limit · $monthlyRemaining/Monat übrig',
    'es': 'Premium · Hoy $sent/$limit · $monthlyRemaining/mes restantes',
    'pt': 'Premium · Hoje $sent/$limit · $monthlyRemaining/mês restantes',
    'ru': 'Премиум · Сегодня $sent/$limit · осталось $monthlyRemaining/мес',
    'tr': 'Premium · Bugün $sent/$limit · $monthlyRemaining/ay kaldı',
    'ar': 'Premium · اليوم $sent/$limit · متبقي $monthlyRemaining/شهر',
    'it': 'Premium · Oggi $sent/$limit · $monthlyRemaining/mese rimanenti',
    'hi': 'Premium · आज $sent/$limit · $monthlyRemaining/माह शेष',
    'th': 'Premium · วันนี้ $sent/$limit · เหลือ $monthlyRemaining/เดือน',
  });

  String get composeSendReply => _t({
    'ko': '답장 보내기',
    'en': 'Send Reply',
    'ja': '返信を送る',
    'zh': '发送回信',
    'fr': 'Envoyer la réponse',
    'de': 'Antwort senden',
    'es': 'Enviar respuesta',
    'pt': 'Enviar resposta',
    'ru': 'Отправить ответ',
    'tr': 'Yanıt gönder',
    'ar': 'إرسال الرد',
    'it': 'Invia risposta',
    'hi': 'जवाब भेजें',
    'th': 'ส่งจดหมายตอบ',
  });

  String get composeLetterDeparting => _t({
    'ko': '혜택이 출발합니다...',
    'en': 'Your promo is departing...',
    'ja': '手紙が出発します...',
    'zh': '信件正在出发...',
    'fr': 'Votre lettre part...',
    'de': 'Ihr Brief geht auf die Reise...',
    'es': 'Tu carta está partiendo...',
    'pt': 'Sua carta está partindo...',
    'ru': 'Ваше письмо отправляется...',
    'tr': 'Mektubunuz yola çıkıyor...',
    'ar': 'رسالتك في طريقها...',
    'it': 'La tua lettera sta partendo...',
    'hi': 'आपका पत्र रवाना हो रहा है...',
    'th': 'จดหมายกำลังออกเดินทาง...',
  });

  String get composeSelectDestination => _t({
    'ko': '목적지 선택',
    'en': 'Select Destination',
    'ja': '目的地を選択',
    'zh': '选择目的地',
    'fr': 'Choisir la destination',
    'de': 'Ziel auswählen',
    'es': 'Seleccionar destino',
    'pt': 'Selecionar destino',
    'ru': 'Выбрать место назначения',
    'tr': 'Hedef seç',
    'ar': 'اختر الوجهة',
    'it': 'Seleziona destinazione',
    'hi': 'गंतव्य चुनें',
    'th': 'เลือกปลายทาง',
  });

  String get composeSendRandom => _t({
    'ko': '랜덤으로 보내기',
    'en': 'Send randomly',
    'ja': 'ランダムに送る',
    'zh': '随机发送',
    'fr': 'Envoyer aléatoirement',
    'de': 'Zufällig senden',
    'es': 'Enviar aleatoriamente',
    'pt': 'Enviar aleatoriamente',
    'ru': 'Отправить случайно',
    'tr': 'Rastgele gönder',
    'ar': 'إرسال عشوائي',
    'it': 'Invia casualmente',
    'hi': 'रैंडम भेजें',
    'th': 'ส่งแบบสุ่ม',
  });

  String get composeSendRandomSub => _t({
    'ko': '세계 어딘가 알 수 없는 곳으로 출발 · 발송 후 배송지 공개',
    'en': 'Departs to an unknown place in the world · Destination revealed after sending',
    'ja': '世界のどこか未知の場所へ出発 · 送信後に配送先が公開',
    'zh': '寄往世界某个未知角落 · 发送后公开目的地',
    'fr': 'Part vers un lieu inconnu · Destination révélée après l\'envoi',
    'de': 'Reist an einen unbekannten Ort · Ziel wird nach dem Senden enthüllt',
    'es': 'Sale a un lugar desconocido · Destino revelado después del envío',
    'pt': 'Parte para um lugar desconhecido · Destino revelado após o envio',
    'ru': 'Отправляется в неизвестное место · Место назначения раскрывается после отправки',
    'tr': 'Dünyada bilinmeyen bir yere yola çıkar · Gönderim sonrası hedef açıklanır',
    'ar': 'ينطلق إلى مكان مجهول في العالم · يُكشف الوجهة بعد الإرسال',
    'it': 'Parte verso un luogo sconosciuto · Destinazione rivelata dopo l\'invio',
    'hi': 'दुनिया में अज्ञात स्थान पर भेजा जाता है · भेजने के बाद गंतव्य प्रकट',
    'th': 'ออกเดินทางไปที่ไหนสักแห่งที่ไม่รู้ · เปิดเผยปลายทางหลังส่ง',
  });

  String get composeOrSelectCountry => _t({
    'ko': '또는 나라 직접 선택',
    'en': 'Or select a country directly',
    'ja': 'または国を直接選択',
    'zh': '或直接选择国家',
    'fr': 'Ou sélectionnez un pays directement',
    'de': 'Oder wählen Sie ein Land direkt',
    'es': 'O selecciona un país directamente',
    'pt': 'Ou selecione um país diretamente',
    'ru': 'Или выберите страну напрямую',
    'tr': 'Veya doğrudan bir ülke seçin',
    'ar': 'أو اختر دولة مباشرة',
    'it': 'O seleziona un paese direttamente',
    'hi': 'या सीधे देश चुनें',
    'th': 'หรือเลือกประเทศโดยตรง',
  });

  String get composeSearchCountry => _t({
    'ko': '나라 검색...',
    'en': 'Search country...',
    'ja': '国を検索...',
    'zh': '搜索国家...',
    'fr': 'Rechercher un pays...',
    'de': 'Land suchen...',
    'es': 'Buscar país...',
    'pt': 'Pesquisar país...',
    'ru': 'Поиск страны...',
    'tr': 'Ülke ara...',
    'ar': 'البحث عن دولة...',
    'it': 'Cerca paese...',
    'hi': 'देश खोजें...',
    'th': 'ค้นหาประเทศ...',
  });

  // ── Inbox Screen ────────────────────────────────────────────────────
  // ── Inbox Screen ──────────────────────────────────────────────────────────

  String inboxTotalReceived(int count) => _t({
    'ko': '총 ${count}통 받음',
    'en': '$count received',
    'ja': '合計${count}通受信',
    'zh': '共收到${count}封',
    'fr': '$count reçu(s)',
    'de': '$count empfangen',
    'es': '$count recibido(s)',
    'pt': '$count recebido(s)',
    'ru': 'Получено: $count',
    'tr': '$count alındı',
    'ar': 'تم استلام $count',
    'it': '$count ricevut${count == 1 ? "o" : "i"}',
    'hi': 'कुल $count प्राप्त',
    'th': 'ได้รับทั้งหมด $count ฉบับ',
  });

  String get inboxSearchHint => _t({
    'ko': '내용, 나라, 이모지 검색...',
    'en': 'Search content, country, emoji...',
    'ja': '内容、国、絵文字で検索...',
    'zh': '搜索内容、国家、表情...',
    'fr': 'Rechercher contenu, pays, emoji...',
    'de': 'Inhalt, Land, Emoji suchen...',
    'es': 'Buscar contenido, país, emoji...',
    'pt': 'Pesquisar conteúdo, país, emoji...',
    'ru': 'Поиск по содержанию, стране, эмодзи...',
    'tr': 'İçerik, ülke, emoji ara...',
    'ar': 'بحث في المحتوى، البلد، الرموز...',
    'it': 'Cerca contenuto, paese, emoji...',
    'hi': 'सामग्री, देश, इमोजी खोजें...',
    'th': 'ค้นหาเนื้อหา ประเทศ อิโมจิ...',
  });

  String get inboxTabReceived => _t({
    'ko': '받은',
    'en': 'Received',
    'ja': '受信',
    'zh': '收到',
    'fr': 'Reçus',
    'de': 'Empfangen',
    'es': 'Recibidos',
    'pt': 'Recebidos',
    'ru': 'Входящие',
    'tr': 'Gelen',
    'ar': 'المستلمة',
    'it': 'Ricevuti',
    'hi': 'प्राप्त',
    'th': 'ที่ได้รับ',
  });

  String get inboxTabSent => _t({
    'ko': '보낸',
    'en': 'Sent',
    'ja': '送信',
    'zh': '已发',
    'fr': 'Envoyés',
    'de': 'Gesendet',
    'es': 'Enviados',
    'pt': 'Enviados',
    'ru': 'Исходящие',
    'tr': 'Giden',
    'ar': 'المرسلة',
    'it': 'Inviati',
    'hi': 'भेजे',
    'th': 'ที่ส่ง',
  });

  String get inboxTabDM => _t({
    'ko': 'DM',
    'en': 'DM',
    'ja': 'DM',
    'zh': '私信',
    'fr': 'DM',
    'de': 'DM',
    'es': 'DM',
    'pt': 'DM',
    'ru': 'ЛС',
    'tr': 'DM',
    'ar': 'رسالة خاصة',
    'it': 'DM',
    'hi': 'DM',
    'th': 'DM',
  });

  String get inboxLocalOnly => _t({
    'ko': '이 혜택은 현지에서만 열어볼 수 있어요',
    'en': 'This reward can only be opened locally',
    'ja': 'この手紙は現地でのみ開けます',
    'zh': '此信只能在当地打开',
    'fr': 'Cette lettre ne peut être ouverte que sur place',
    'de': 'Dieser Brief kann nur vor Ort geöffnet werden',
    'es': 'Esta carta solo se puede abrir en el lugar',
    'pt': 'Esta carta só pode ser aberta no local',
    'ru': 'Это письмо можно открыть только на месте',
    'tr': 'Bu mektup yalnızca yerinde açılabilir',
    'ar': 'لا يمكن فتح هذه الرسالة إلا محليًا',
    'it': 'Questa lettera può essere aperta solo in loco',
    'hi': 'यह पत्र केवल स्थानीय रूप से खोला जा सकता है',
    'th': 'จดหมายนี้เปิดได้เฉพาะในพื้นที่เท่านั้น',
  });

  String get inboxLetterLocked => _t({
    'ko': '혜택 잠금',
    'en': 'Reward Locked',
    'ja': '手紙ロック',
    'zh': '信件已锁定',
    'fr': 'Lettre verrouillée',
    'de': 'Brief gesperrt',
    'es': 'Carta bloqueada',
    'pt': 'Carta bloqueada',
    'ru': 'Письмо заблокировано',
    'tr': 'Mektup kilitli',
    'ar': 'الرسالة مقفلة',
    'it': 'Lettera bloccata',
    'hi': 'पत्र लॉक है',
    'th': 'จดหมายถูกล็อก',
  });

  String inboxSendMoreToRead(int remaining) => _t({
    'ko': '다음 혜택을 읽으려면 혜택을 $remaining개 더 보내야 합니다.',
    'en': 'Send $remaining more promo${remaining == 1 ? "" : "s"} to read the next one.',
    'ja': '次の手紙を読むにはあと${remaining}通送ってください。',
    'zh': '再发送${remaining}封信即可阅读下一封。',
    'fr': 'Envoyez encore $remaining lettre${remaining == 1 ? "" : "s"} pour lire la suivante.',
    'de': 'Sende noch $remaining Brief${remaining == 1 ? "" : "e"}, um den nächsten zu lesen.',
    'es': 'Envía $remaining carta${remaining == 1 ? "" : "s"} más para leer la siguiente.',
    'pt': 'Envie mais $remaining carta${remaining == 1 ? "" : "s"} para ler a próxima.',
    'ru': 'Отправьте ещё $remaining, чтобы прочитать следующее.',
    'tr': 'Sonrakini okumak için $remaining mektup daha gönderin.',
    'ar': 'أرسل $remaining رسالة أخرى لقراءة التالية.',
    'it': 'Invia ancora $remaining letter${remaining == 1 ? "a" : "e"} per leggere la prossima.',
    'hi': 'अगला पढ़ने के लिए $remaining और पत्र भेजें।',
    'th': 'ส่งจดหมายอีก $remaining ฉบับเพื่ออ่านฉบับต่อไป',
  });

  String inboxLettersSent(int sent, int total) => _t({
    'ko': '$sent/$total 홍보 발송',
    'en': '$sent/$total promos sent',
    'ja': '$sent/$total通送信済み',
    'zh': '已发送 $sent/$total 封',
    'fr': '$sent/$total lettres envoyées',
    'de': '$sent/$total Briefe gesendet',
    'es': '$sent/$total cartas enviadas',
    'pt': '$sent/$total cartas enviadas',
    'ru': '$sent/$total писем отправлено',
    'tr': '$sent/$total mektup gönderildi',
    'ar': '$sent/$total رسائل مرسلة',
    'it': '$sent/$total lettere inviate',
    'hi': '$sent/$total पत्र भेजे',
    'th': 'ส่งแล้ว $sent/$total ฉบับ',
  });

  String get inboxConfirm => _t({
    'ko': '확인',
    'en': 'OK',
    'ja': '確認',
    'zh': '确认',
    'fr': 'OK',
    'de': 'OK',
    'es': 'Aceptar',
    'pt': 'OK',
    'ru': 'ОК',
    'tr': 'Tamam',
    'ar': 'موافق',
    'it': 'OK',
    'hi': 'ठीक है',
    'th': 'ตกลง',
  });

  String get inboxDeleteTitle => _t({
    'ko': '혜택 삭제',
    'en': 'Delete Reward',
    'ja': '手紙を削除',
    'zh': '删除信件',
    'fr': 'Supprimer la lettre',
    'de': 'Brief löschen',
    'es': 'Eliminar carta',
    'pt': 'Excluir carta',
    'ru': 'Удалить письмо',
    'tr': 'Mektubu sil',
    'ar': 'حذف الرسالة',
    'it': 'Elimina lettera',
    'hi': 'पत्र हटाएं',
    'th': 'ลบจดหมาย',
  });

  String get inboxDeleteBody => _t({
    'ko': '이 혜택을 삭제하시겠어요?\n삭제된 혜택은 복구할 수 없어요.',
    'en': 'Delete this reward?\nDeleted rewards cannot be recovered.',
    'ja': 'この手紙を削除しますか？\n削除した手紙は復元できません。',
    'zh': '确定删除这封信？\n删除后无法恢复。',
    'fr': 'Supprimer cette lettre ?\nLes lettres supprimées ne peuvent pas être récupérées.',
    'de': 'Diesen Brief löschen?\nGelöschte Briefe können nicht wiederhergestellt werden.',
    'es': '¿Eliminar esta carta?\nLas cartas eliminadas no se pueden recuperar.',
    'pt': 'Excluir esta carta?\nCartas excluídas não podem ser recuperadas.',
    'ru': 'Удалить это письмо?\nУдалённые письма нельзя восстановить.',
    'tr': 'Bu mektubu silmek istiyor musunuz?\nSilinen mektuplar geri alınamaz.',
    'ar': 'هل تريد حذف هذه الرسالة؟\nلا يمكن استعادة الرسائل المحذوفة.',
    'it': 'Eliminare questa lettera?\nLe lettere eliminate non possono essere recuperate.',
    'hi': 'यह पत्र हटाएं?\nहटाए गए पत्र पुनर्प्राप्त नहीं किए जा सकते।',
    'th': 'ลบจดหมายนี้?\nจดหมายที่ลบแล้วไม่สามารถกู้คืนได้',
  });

  String get inboxDeleteConfirm => _t({
    'ko': '이 혜택을 삭제하면 복구할 수 없어요.\n정말 삭제할까요?',
    'en': 'This reward cannot be recovered once deleted.\nAre you sure?',
    'ja': 'この手紙を削除すると復元できません。\n本当に削除しますか？',
    'zh': '此信删除后无法恢复。\n确定删除吗？',
    'fr': 'Cette lettre ne pourra pas être récupérée.\nÊtes-vous sûr ?',
    'de': 'Dieser Brief kann nicht wiederhergestellt werden.\nWirklich löschen?',
    'es': 'Esta carta no se puede recuperar.\n¿Estás seguro?',
    'pt': 'Esta carta não pode ser recuperada.\nTem certeza?',
    'ru': 'Это письмо нельзя будет восстановить.\nВы уверены?',
    'tr': 'Bu mektup geri alınamaz.\nEmin misiniz?',
    'ar': 'لا يمكن استعادة هذه الرسالة.\nهل أنت متأكد؟',
    'it': 'Questa lettera non può essere recuperata.\nSei sicuro?',
    'hi': 'यह पत्र पुनर्प्राप्त नहीं किया जा सकता।\nक्या आप सुनिश्चित हैं?',
    'th': 'จดหมายนี้ไม่สามารถกู้คืนได้\nคุณแน่ใจหรือไม่?',
  });

  String get inboxCancel => _t({
    'ko': '취소',
    'en': 'Cancel',
    'ja': 'キャンセル',
    'zh': '取消',
    'fr': 'Annuler',
    'de': 'Abbrechen',
    'es': 'Cancelar',
    'pt': 'Cancelar',
    'ru': 'Отмена',
    'tr': 'İptal',
    'ar': 'إلغاء',
    'it': 'Annulla',
    'hi': 'रद्द करें',
    'th': 'ยกเลิก',
  });

  String get inboxDelete => _t({
    'ko': '삭제',
    'en': 'Delete',
    'ja': '削除',
    'zh': '删除',
    'fr': 'Supprimer',
    'de': 'Löschen',
    'es': 'Eliminar',
    'pt': 'Excluir',
    'ru': 'Удалить',
    'tr': 'Sil',
    'ar': 'حذف',
    'it': 'Elimina',
    'hi': 'हटाएं',
    'th': 'ลบ',
  });

  String get inboxDeleted => _t({
    'ko': '혜택이 삭제되었어요',
    'en': 'Reward deleted',
    'ja': '手紙が削除されました',
    'zh': '信件已删除',
    'fr': 'Lettre supprimée',
    'de': 'Brief gelöscht',
    'es': 'Carta eliminada',
    'pt': 'Carta excluída',
    'ru': 'Письмо удалено',
    'tr': 'Mektup silindi',
    'ar': 'تم حذف الرسالة',
    'it': 'Lettera eliminata',
    'hi': 'पत्र हटाया गया',
    'th': 'ลบจดหมายแล้ว',
  });

  // Build 183: 받은 편지 스와이프 — 우측(→) 사용 완료 라벨.
  String get inboxMarkUsed => _t({
    'ko': '사용 완료',
    'en': 'Mark used',
    'ja': '使用済み',
    'zh': '标记已用',
    'fr': 'Utilisé',
    'de': 'Benutzt',
    'es': 'Usar',
    'pt': 'Usado',
    'ru': 'Использовано',
    'tr': 'Kullanıldı',
    'ar': 'استخدم',
    'it': 'Usato',
    'hi': 'प्रयुक्त',
    'th': 'ใช้แล้ว',
  });

  String get inboxAlreadyUsed => _t({
    'ko': '이미 사용',
    'en': 'Used',
    'ja': '使用済',
    'zh': '已使用',
    'fr': 'Utilisé',
    'de': 'Verwendet',
    'es': 'Usado',
    'pt': 'Usado',
    'ru': 'Использ.',
    'tr': 'Kullanıldı',
    'ar': 'مستخدم',
    'it': 'Usato',
    'hi': 'प्रयुक्त',
    'th': 'ใช้แล้ว',
  });

  String get inboxMarkedUsed => _t({
    'ko': '✅ 사용 완료로 표시했어요',
    'en': '✅ Marked as used',
    'ja': '✅ 使用済みに設定しました',
    'zh': '✅ 已标记为已使用',
    'fr': '✅ Marqué comme utilisé',
    'de': '✅ Als benutzt markiert',
    'es': '✅ Marcado como usado',
    'pt': '✅ Marcado como usado',
    'ru': '✅ Отмечено как использованное',
    'tr': '✅ Kullanıldı olarak işaretlendi',
    'ar': '✅ تم التعليم كمستخدم',
    'it': '✅ Contrassegnato come usato',
    'hi': '✅ प्रयुक्त के रूप में चिह्नित',
    'th': '✅ ทำเครื่องหมายว่าใช้แล้ว',
  });

  String get inboxAlreadyUsedSnack => _t({
    'ko': '이미 사용 완료된 혜택이에요',
    'en': 'Already marked as used',
    'ja': '既に使用済みです',
    'zh': '已是已使用状态',
    'fr': 'Déjà marqué comme utilisé',
    'de': 'Bereits als benutzt markiert',
    'es': 'Ya marcado como usado',
    'pt': 'Já marcado como usado',
    'ru': 'Уже использовано',
    'tr': 'Zaten kullanıldı',
    'ar': 'تم تعليمه كمستخدم',
    'it': 'Già contrassegnato come usato',
    'hi': 'पहले से प्रयुक्त चिह्नित',
    'th': 'ใช้แล้วอยู่แล้ว',
  });

  String get inboxEmptyReceived => _t({
    'ko': '조건에 맞는 받은 혜택이 없어요',
    'en': 'No received rewards match the filter',
    'ja': '条件に合う受信メールはありません',
    'zh': '没有符合条件的收件',
    'fr': 'Aucune lettre reçue ne correspond au filtre',
    'de': 'Keine empfangenen Briefe passen zum Filter',
    'es': 'No hay cartas recibidas que coincidan',
    'pt': 'Nenhuma carta recebida corresponde ao filtro',
    'ru': 'Нет входящих писем, соответствующих фильтру',
    'tr': 'Filtreye uyan gelen mektup yok',
    'ar': 'لا توجد رسائل مستلمة مطابقة',
    'it': 'Nessuna lettera ricevuta corrisponde al filtro',
    'hi': 'फ़िल्टर से मेल खाने वाला कोई प्राप्त पत्र नहीं',
    'th': 'ไม่มีจดหมายที่ได้รับตรงกับตัวกรอง',
  });

  String get inboxEmptyReceivedSub => _t({
    'ko': '필터를 바꾸거나 지도에서 새 혜택을 찾아보세요!',
    'en': 'Try a different filter or find new rewards on the map!',
    'ja': 'フィルターを変えるか、地図で新しい手紙を探してみましょう！',
    'zh': '试试其他筛选条件或在地图上查找新信件！',
    'fr': 'Changez de filtre ou cherchez de nouvelles lettres sur la carte !',
    'de': 'Probiere einen anderen Filter oder finde neue Briefe auf der Karte!',
    'es': '¡Prueba otro filtro o busca nuevas cartas en el mapa!',
    'pt': 'Tente outro filtro ou encontre novas cartas no mapa!',
    'ru': 'Попробуйте другой фильтр или найдите новые письма на карте!',
    'tr': 'Filtreyi değiştirin veya haritada yeni mektuplar bulun!',
    'ar': 'جرب فلترًا مختلفًا أو ابحث عن رسائل جديدة على الخريطة!',
    'it': 'Prova un filtro diverso o trova nuove lettere sulla mappa!',
    'hi': 'कोई अलग फ़िल्टर आज़माएं या मानचित्र पर नए पत्र खोजें!',
    'th': 'ลองเปลี่ยนตัวกรองหรือค้นหาจดหมายใหม่บนแผนที่!',
  });

  /// 필터명을 받아 "아직 X 혜택이 없어요" 식으로 조합. 빈 수집첩에서
  /// 어떤 필터가 걸렸는지 명시적으로 알려준다. "편지" 를 공통 명사로 붙여
  /// 한국어 조사 처리 ((이)가) 를 피하고 "할인권 혜택이", "브랜드 혜택이"
  /// 식으로 매끄럽게 읽히도록 한다.
  String inboxEmptyForFilter(String filterName) {
    switch (languageCode) {
      case 'ko':
        return '아직 $filterName 혜택이 없어요';
      case 'en':
        return 'No $filterName rewards yet';
      case 'ja':
        return 'まだ$filterNameの手紙がありません';
      case 'zh':
        return '暂无$filterName信件';
      case 'fr':
        return 'Pas encore de lettres $filterName';
      case 'de':
        return 'Noch keine $filterName-Briefe';
      case 'es':
        return 'Aún no hay cartas de $filterName';
      case 'pt':
        return 'Ainda não há cartas de $filterName';
      case 'ru':
        return 'Писем категории «$filterName» пока нет';
      case 'tr':
        return 'Henüz $filterName mektubu yok';
      case 'ar':
        return 'لا توجد رسائل $filterName بعد';
      case 'it':
        return 'Ancora nessuna lettera $filterName';
      case 'hi':
        return 'अभी कोई $filterName पत्र नहीं';
      case 'th':
        return 'ยังไม่มีจดหมาย$filterName';
      default:
        return 'No $filterName rewards yet';
    }
  }

  // 회원탈퇴 다이얼로그 — 삭제되는 항목 헤더 · 항목 리스트 · 유저명 입력 안내
  String get settingsWithdrawItemsHeader => _t({
    'ko': '⚠️ 삭제되는 항목',
    'en': '⚠️ What will be deleted',
    'ja': '⚠️ 削除される項目',
    'zh': '⚠️ 将被删除的内容',
    'fr': '⚠️ Éléments supprimés',
    'de': '⚠️ Was gelöscht wird',
    'es': '⚠️ Qué se eliminará',
    'pt': '⚠️ O que será apagado',
    'ru': '⚠️ Что будет удалено',
    'tr': '⚠️ Silinecekler',
    'ar': '⚠️ ما الذي سيتم حذفه',
    'it': '⚠️ Cosa verrà eliminato',
    'hi': '⚠️ क्या हटाया जाएगा',
    'th': '⚠️ สิ่งที่จะถูกลบ',
  });

  String get settingsWithdrawItemsList => _t({
    'ko': '• 모든 혜택 및 DM 기록\n• 타워 및 활동 점수\n• 스탬프 앨범\n• 계정 정보',
    'en': '• All rewards and DM history\n• Tower and activity score\n• Stamp album\n• Account info',
    'ja': '• すべての手紙とDM履歴\n• タワーとアクティビティスコア\n• スタンプアルバム\n• アカウント情報',
    'zh': '• 所有信件和私信记录\n• 塔和活跃度分数\n• 邮票收集册\n• 账号信息',
    'fr': '• Toutes les lettres et DM\n• Tour et score d’activité\n• Album de timbres\n• Info du compte',
    'de': '• Alle Briefe und DMs\n• Turm und Aktivitätsscore\n• Briefmarkenalbum\n• Kontodaten',
    'es': '• Todas las cartas y DMs\n• Torre y puntuación\n• Álbum de sellos\n• Datos de cuenta',
    'pt': '• Todas as cartas e DMs\n• Torre e pontuação\n• Álbum de selos\n• Dados da conta',
    'ru': '• Все письма и ЛС\n• Башня и очки активности\n• Альбом марок\n• Данные аккаунта',
    'tr': '• Tüm mektuplar ve DM\n• Kule ve etkinlik puanı\n• Pul albümü\n• Hesap bilgileri',
    'ar': '• كل الرسائل والمحادثات الخاصة\n• البرج ونقاط النشاط\n• ألبوم الطوابع\n• بيانات الحساب',
    'it': '• Tutte le lettere e DM\n• Torre e punteggio\n• Album dei francobolli\n• Dati account',
    'hi': '• सभी पत्र और DM\n• टावर और गतिविधि स्कोर\n• स्टैम्प एल्बम\n• खाता जानकारी',
    'th': '• จดหมายและ DM ทั้งหมด\n• หอและคะแนนกิจกรรม\n• อัลบั้มแสตมป์\n• ข้อมูลบัญชี',
  });

  String settingsWithdrawTypeUsernameToConfirm(String username) {
    switch (languageCode) {
      case 'ko':
        return '확인을 위해 아이디 "$username"를 입력하세요:';
      case 'ja':
        return '確認のためユーザー名 "$username" を入力してください:';
      case 'zh':
        return '请输入用户名 "$username" 以确认：';
      case 'fr':
        return 'Saisissez "$username" pour confirmer :';
      case 'de':
        return 'Gib "$username" ein, um zu bestätigen:';
      case 'es':
        return 'Escribe "$username" para confirmar:';
      case 'pt':
        return 'Digite "$username" para confirmar:';
      case 'ru':
        return 'Введите "$username" для подтверждения:';
      case 'tr':
        return 'Onaylamak için "$username" yazın:';
      case 'ar':
        return 'اكتب "$username" للتأكيد:';
      case 'it':
        return 'Digita "$username" per confermare:';
      case 'hi':
        return 'पुष्टि करने के लिए "$username" टाइप करें:';
      case 'th':
        return 'พิมพ์ "$username" เพื่อยืนยัน:';
      default:
        return 'Type "$username" to confirm:';
    }
  }

  // 설정 · 고객 지원 섹션
  String get settingsSupport => _t({
    'ko': '고객 지원',
    'en': 'Support',
    'ja': 'サポート',
    'zh': '客户支持',
    'fr': 'Assistance',
    'de': 'Support',
    'es': 'Soporte',
    'pt': 'Suporte',
    'ru': 'Поддержка',
    'tr': 'Destek',
    'ar': 'الدعم',
    'it': 'Assistenza',
    'hi': 'सहायता',
    'th': 'ฝ่ายช่วยเหลือ',
  });

  String get settingsContactUs => _t({
    'ko': '문의하기',
    'en': 'Contact us',
    'ja': 'お問い合わせ',
    'zh': '联系我们',
    'fr': 'Nous contacter',
    'de': 'Kontakt',
    'es': 'Contáctanos',
    'pt': 'Fale conosco',
    'ru': 'Связаться с нами',
    'tr': 'Bize ulaşın',
    'ar': 'تواصل معنا',
    'it': 'Contattaci',
    'hi': 'संपर्क करें',
    'th': 'ติดต่อเรา',
  });

  String get settingsContactUsDesc => _t({
    'ko': '오류 신고 · 기능 제안 · 기타 문의',
    'en': 'Report a bug · Suggest a feature · Other',
    'ja': '不具合報告・機能提案・その他',
    'zh': '反馈问题 · 功能建议 · 其他',
    'fr': 'Bug · Suggestion · Autre',
    'de': 'Fehler · Vorschlag · Sonstiges',
    'es': 'Error · Sugerencia · Otro',
    'pt': 'Erro · Sugestão · Outro',
    'ru': 'Ошибка · Предложение · Другое',
    'tr': 'Hata · Öneri · Diğer',
    'ar': 'إبلاغ عن خطأ · اقتراح · أخرى',
    'it': 'Bug · Suggerimento · Altro',
    'hi': 'बग · सुझाव · अन्य',
    'th': 'แจ้งบัก · เสนอฟีเจอร์ · อื่น ๆ',
  });

  String get settingsManageSubscription => _t({
    'ko': '구독 관리',
    'en': 'Manage subscription',
    'ja': 'サブスクリプション管理',
    'zh': '管理订阅',
    'fr': 'Gérer l\'abonnement',
    'de': 'Abo verwalten',
    'es': 'Gestionar suscripción',
    'pt': 'Gerir subscrição',
    'ru': 'Управление подпиской',
    'tr': 'Aboneliği yönet',
    'ar': 'إدارة الاشتراك',
    'it': 'Gestisci abbonamento',
    'hi': 'सदस्यता प्रबंधित करें',
    'th': 'จัดการการสมัคร',
  });

  String get settingsManageSubscriptionDesc => _t({
    'ko': 'App Store / Google Play에서 구독 변경',
    'en': 'Change your plan in App Store / Google Play',
    'ja': 'App Store / Google Playでプラン変更',
    'zh': '在 App Store / Google Play 更改订阅',
    'fr': 'Modifier dans App Store / Google Play',
    'de': 'Im App Store / Google Play ändern',
    'es': 'Cambiar en App Store / Google Play',
    'pt': 'Alterar em App Store / Google Play',
    'ru': 'Изменить в App Store / Google Play',
    'tr': 'App Store / Google Play üzerinden değiştir',
    'ar': 'تغيير عبر App Store / Google Play',
    'it': 'Modifica in App Store / Google Play',
    'hi': 'App Store / Google Play से बदलें',
    'th': 'เปลี่ยนใน App Store / Google Play',
  });

  // 수집첩 상단의 숫자 칩 3개 — 새 편지 / 배달중 / 총 수신
  String get inboxStatNew => _t({
    'ko': '새 혜택',
    'en': 'New',
    'ja': '新着',
    'zh': '新信件',
    'fr': 'Nouveau',
    'de': 'Neu',
    'es': 'Nuevo',
    'pt': 'Novo',
    'ru': 'Новые',
    'tr': 'Yeni',
    'ar': 'جديد',
    'it': 'Nuovo',
    'hi': 'नया',
    'th': 'ใหม่',
  });

  String get inboxStatTransit => _t({
    'ko': '배달중',
    'en': 'In transit',
    'ja': '配達中',
    'zh': '投递中',
    'fr': 'En route',
    'de': 'Unterwegs',
    'es': 'En camino',
    'pt': 'A caminho',
    'ru': 'В пути',
    'tr': 'Yolda',
    'ar': 'قيد التوصيل',
    'it': 'In viaggio',
    'hi': 'रास्ते में',
    'th': 'กำลังจัดส่ง',
  });

  String get inboxStatTotal => _t({
    'ko': '총 수신',
    'en': 'Total received',
    'ja': '総受信',
    'zh': '累计收件',
    'fr': 'Total reçu',
    'de': 'Gesamt erhalten',
    'es': 'Total recibidas',
    'pt': 'Total recebidas',
    'ru': 'Всего получено',
    'tr': 'Toplam alınan',
    'ar': 'إجمالي المستلم',
    'it': 'Totale ricevute',
    'hi': 'कुल प्राप्त',
    'th': 'รับทั้งหมด',
  });

  String get inboxEmptySent => _t({
    'ko': '조건에 맞는 보낸 혜택이 없어요',
    'en': 'No sent promos match the filter',
    'ja': '条件に合う送信メールはありません',
    'zh': '没有符合条件的已发信件',
    'fr': 'Aucune lettre envoyée ne correspond au filtre',
    'de': 'Keine gesendeten Briefe passen zum Filter',
    'es': 'No hay cartas enviadas que coincidan',
    'pt': 'Nenhuma carta enviada corresponde ao filtro',
    'ru': 'Нет отправленных писем, соответствующих фильтру',
    'tr': 'Filtreye uyan gönderilmiş mektup yok',
    'ar': 'لا توجد رسائل مرسلة مطابقة',
    'it': 'Nessuna lettera inviata corrisponde al filtro',
    'hi': 'फ़िल्टर से मेल खाने वाला कोई भेजा गया पत्र नहीं',
    'th': 'ไม่มีจดหมายที่ส่งตรงกับตัวกรอง',
  });

  String get inboxEmptySentSub => _t({
    'ko': '필터를 바꾸거나 새 홍보를 보내보세요!',
    'en': 'Try a different filter or send a new promo!',
    'ja': 'フィルターを変えるか、新しい手紙を送ってみましょう！',
    'zh': '试试其他筛选条件或发送新信件！',
    'fr': 'Changez de filtre ou envoyez une nouvelle lettre !',
    'de': 'Probiere einen anderen Filter oder sende einen neuen Brief!',
    'es': '¡Prueba otro filtro o envía una nueva carta!',
    'pt': 'Tente outro filtro ou envie uma nova carta!',
    'ru': 'Попробуйте другой фильтр или отправьте новое письмо!',
    'tr': 'Filtreyi değiştirin veya yeni bir mektup gönderin!',
    'ar': 'جرب فلترًا مختلفًا أو أرسل رسالة جديدة!',
    'it': 'Prova un filtro diverso o invia una nuova lettera!',
    'hi': 'कोई अलग फ़िल्टर आज़माएं या नया पत्र भेजें!',
    'th': 'ลองเปลี่ยนตัวกรองหรือส่งจดหมายใหม่!',
  });

  String get inboxAnonymousLetter => _t({
    'ko': '익명의 혜택',
    'en': 'Anonymous Reward',
    'ja': '匿名の手紙',
    'zh': '匿名信件',
    'fr': 'Lettre anonyme',
    'de': 'Anonymer Brief',
    'es': 'Carta anónima',
    'pt': 'Carta anônima',
    'ru': 'Анонимное письмо',
    'tr': 'Anonim mektup',
    'ar': 'رسالة مجهولة',
    'it': 'Lettera anonima',
    'hi': 'गुमनाम पत्र',
    'th': 'จดหมายนิรนาม',
  });

  String get inboxRead => _t({
    'ko': '읽음',
    'en': 'Read',
    'ja': '既読',
    'zh': '已读',
    'fr': 'Lu',
    'de': 'Gelesen',
    'es': 'Leído',
    'pt': 'Lido',
    'ru': 'Прочитано',
    'tr': 'Okundu',
    'ar': 'مقروء',
    'it': 'Letto',
    'hi': 'पढ़ा गया',
    'th': 'อ่านแล้ว',
  });

  String get inboxEta => _t({
    'ko': '예상',
    'en': 'est.',
    'ja': '予定',
    'zh': '预计',
    'fr': 'est.',
    'de': 'ca.',
    'es': 'est.',
    'pt': 'est.',
    'ru': 'ожид.',
    'tr': 'tah.',
    'ar': 'تقدير',
    'it': 'stim.',
    'hi': 'अनुमान',
    'th': 'ประมาณ',
  });

  String get inboxSend3ToOpen => _t({
    'ko': '혜택 3개 픽업 후 열기',
    'en': 'Send 3 promos to open',
    'ja': '3通送ると開けます',
    'zh': '发送3封后可打开',
    'fr': 'Envoyez 3 lettres pour ouvrir',
    'de': 'Sende 3 Briefe zum Öffnen',
    'es': 'Envía 3 cartas para abrir',
    'pt': 'Envie 3 cartas para abrir',
    'ru': 'Отправьте 3 письма, чтобы открыть',
    'tr': 'Açmak için 3 mektup gönderin',
    'ar': 'أرسل 3 رسائل للفتح',
    'it': 'Invia 3 lettere per aprire',
    'hi': 'खोलने के लिए 3 पत्र भेजें',
    'th': 'ส่ง 3 ฉบับเพื่อเปิด',
  });

  String get inboxFilterAll => _t({
    'ko': '전체',
    'en': 'All',
    'ja': 'すべて',
    'zh': '全部',
    'fr': 'Tout',
    'de': 'Alle',
    'es': 'Todo',
    'pt': 'Tudo',
    'ru': 'Все',
    'tr': 'Tümü',
    'ar': 'الكل',
    'it': 'Tutti',
    'hi': 'सभी',
    'th': 'ทั้งหมด',
  });

  String get inboxFilterInTransit => _t({
    'ko': '배송중',
    'en': 'In Transit',
    'ja': '配送中',
    'zh': '运送中',
    'fr': 'En transit',
    'de': 'Unterwegs',
    'es': 'En tránsito',
    'pt': 'Em trânsito',
    'ru': 'В пути',
    'tr': 'Yolda',
    'ar': 'قيد التوصيل',
    'it': 'In transito',
    'hi': 'रास्ते में',
    'th': 'กำลังจัดส่ง',
  });

  String get inboxFilterWaiting => _t({
    'ko': '수령대기',
    'en': 'Awaiting Pickup',
    'ja': '受取待ち',
    'zh': '等待领取',
    'fr': 'En attente',
    'de': 'Wartet',
    'es': 'Esperando',
    'pt': 'Aguardando',
    'ru': 'Ожидает',
    'tr': 'Bekliyor',
    'ar': 'بانتظار الاستلام',
    'it': 'In attesa',
    'hi': 'प्रतीक्षा में',
    'th': 'รอรับ',
  });

  String get inboxFilterBrand => _t({
    'ko': '브랜드',
    'en': 'Brand',
    'ja': 'ブランド',
    'zh': '品牌',
    'fr': 'Marque',
    'de': 'Marke',
    'es': 'Marca',
    'pt': 'Marca',
    'ru': 'Бренд',
    'tr': 'Marka',
    'ar': 'علامة تجارية',
    'it': 'Marchio',
    'hi': 'ब्रांड',
    'th': 'แบรนด์',
  });
  String get inboxFilterCoupon => _t({
    'ko': '할인권',
    'en': 'Coupons',
    'ja': '割引券',
    'zh': '折扣券',
    'fr': 'Réductions',
    'de': 'Rabatte',
    'es': 'Cupones',
    'pt': 'Cupons',
    'ru': 'Купоны',
    'tr': 'Kuponlar',
    'ar': 'قسائم',
    'it': 'Sconti',
    'hi': 'कूपन',
    'th': 'คูปอง',
  });
  String get inboxFilterVoucher => _t({
    'ko': '교환권',
    'en': 'Vouchers',
    'ja': '引換券',
    'zh': '兑换券',
    'fr': 'Bons',
    'de': 'Gutscheine',
    'es': 'Vales',
    'pt': 'Vales',
    'ru': 'Ваучеры',
    'tr': 'Fişler',
    'ar': 'قسائم التبادل',
    'it': 'Buoni',
    'hi': 'वाउचर',
    'th': 'บัตรแลก',
  });

  // Build 183: 받은 혜택 필터에서 brand 제거 후 일반(general) 필터 신설.
  String get inboxFilterGeneral => _t({
    'ko': '일반',
    'en': 'General',
    'ja': '一般',
    'zh': '普通',
    'fr': 'Général',
    'de': 'Allgemein',
    'es': 'General',
    'pt': 'Geral',
    'ru': 'Общие',
    'tr': 'Genel',
    'ar': 'عام',
    'it': 'Generale',
    'hi': 'सामान्य',
    'th': 'ทั่วไป',
  });

  // Build 183: 수집첩 정렬에 "사용 완료" 추가. 이미 redeemed 된 혜택만 보임.
  String get inboxSortUsedOnly => _t({
    'ko': '사용 완료',
    'en': 'Used',
    'ja': '使用済み',
    'zh': '已使用',
    'fr': 'Utilisé',
    'de': 'Benutzt',
    'es': 'Usados',
    'pt': 'Usados',
    'ru': 'Использованные',
    'tr': 'Kullanılmış',
    'ar': 'مستخدم',
    'it': 'Usati',
    'hi': 'प्रयुक्त',
    'th': 'ใช้แล้ว',
  });

  String get inboxStatusInTransit => _t({
    'ko': '배송 중',
    'en': 'In Transit',
    'ja': '配送中',
    'zh': '运送中',
    'fr': 'En transit',
    'de': 'Unterwegs',
    'es': 'En tránsito',
    'pt': 'Em trânsito',
    'ru': 'В пути',
    'tr': 'Yolda',
    'ar': 'قيد التوصيل',
    'it': 'In transito',
    'hi': 'रास्ते में',
    'th': 'กำลังจัดส่ง',
  });

  String get inboxStatusNearby => _t({
    'ko': '도착 근처',
    'en': 'Nearby',
    'ja': '到着間近',
    'zh': '即将到达',
    'fr': 'À proximité',
    'de': 'In der Nähe',
    'es': 'Cerca',
    'pt': 'Próximo',
    'ru': 'Рядом',
    'tr': 'Yakında',
    'ar': 'قريب',
    'it': 'Nelle vicinanze',
    'hi': 'पास में',
    'th': 'ใกล้ถึง',
  });

  String get inboxStatusWaiting => _t({
    'ko': '수령 대기',
    'en': 'Awaiting Pickup',
    'ja': '受取待ち',
    'zh': '等待领取',
    'fr': 'En attente',
    'de': 'Wartet auf Abholung',
    'es': 'Esperando recogida',
    'pt': 'Aguardando retirada',
    'ru': 'Ожидает получения',
    'tr': 'Teslim bekliyor',
    'ar': 'بانتظار الاستلام',
    'it': 'In attesa di ritiro',
    'hi': 'प्राप्ति की प्रतीक्षा',
    'th': 'รอรับ',
  });

  String get inboxStatusDelivered => _t({
    'ko': '전달 완료',
    'en': 'Delivered',
    'ja': '配達完了',
    'zh': '已送达',
    'fr': 'Livré',
    'de': 'Zugestellt',
    'es': 'Entregada',
    'pt': 'Entregue',
    'ru': 'Доставлено',
    'tr': 'Teslim edildi',
    'ar': 'تم التوصيل',
    'it': 'Consegnata',
    'hi': 'पहुंचाया गया',
    'th': 'จัดส่งแล้ว',
  });

  String get inboxStatusNewLetter => _t({
    'ko': '새 혜택',
    'en': 'New Reward',
    'ja': '新着',
    'zh': '新信',
    'fr': 'Nouvelle lettre',
    'de': 'Neuer Brief',
    'es': 'Nueva carta',
    'pt': 'Nova carta',
    'ru': 'Новое письмо',
    'tr': 'Yeni mektup',
    'ar': 'رسالة جديدة',
    'it': 'Nuova lettera',
    'hi': 'नया पत्र',
    'th': 'จดหมายใหม่',
  });

  String inboxEtaRemaining(String eta) => _t({
    'ko': '예상 $eta 남음',
    'en': 'Est. $eta remaining',
    'ja': '残り約$eta',
    'zh': '预计还剩 $eta',
    'fr': 'Environ $eta restant',
    'de': 'Ca. $eta verbleibend',
    'es': 'Aprox. $eta restante',
    'pt': 'Aprox. $eta restante',
    'ru': 'Примерно $eta осталось',
    'tr': 'Tahmini $eta kaldı',
    'ar': 'المتبقي تقريبًا $eta',
    'it': 'Circa $eta rimanente',
    'hi': 'अनुमानित $eta शेष',
    'th': 'เหลือประมาณ $eta',
  });

  String get inboxTrackOnMap => _t({
    'ko': '지도에서 배송 추적',
    'en': 'Track delivery on map',
    'ja': '地図で配送を追跡',
    'zh': '在地图上追踪配送',
    'fr': 'Suivre la livraison sur la carte',
    'de': 'Lieferung auf der Karte verfolgen',
    'es': 'Rastrear envío en el mapa',
    'pt': 'Rastrear entrega no mapa',
    'ru': 'Отслеживать на карте',
    'tr': 'Haritada teslimatı takip et',
    'ar': 'تتبع التوصيل على الخريطة',
    'it': 'Traccia la consegna sulla mappa',
    'hi': 'मानचित्र पर डिलीवरी ट्रैक करें',
    'th': 'ติดตามการจัดส่งบนแผนที่',
  });

  String get inboxNoDM => _t({
    'ko': '아직 DM 대화가 없어요',
    'en': 'No DM conversations yet',
    'ja': 'まだDMはありません',
    'zh': '还没有私信对话',
    'fr': 'Pas encore de conversations DM',
    'de': 'Noch keine DM-Unterhaltungen',
    'es': 'Aún no hay conversaciones DM',
    'pt': 'Nenhuma conversa DM ainda',
    'ru': 'Пока нет личных сообщений',
    'tr': 'Henüz DM sohbeti yok',
    'ar': 'لا توجد محادثات خاصة بعد',
    'it': 'Nessuna conversazione DM',
    'hi': 'अभी तक कोई DM बातचीत नहीं',
    'th': 'ยังไม่มีบทสนทนา DM',
  });

  String get inboxNoDMSub => _t({
    'ko': '받은 받은 혜택에서 발신자를 팔로우하면\n맞팔 시 DM 대화가 시작돼요',
    'en': 'Follow a sender from your inbox\nand DM opens when they follow back',
    'ja': '受信箱から送信者をフォローすると\n相互フォローでDMが開始されます',
    'zh': '在收件箱中关注发件人\n互相关注后即可开始私信',
    'fr': 'Suivez un expéditeur depuis votre boîte\nle DM s\'ouvre quand il vous suit aussi',
    'de': 'Folge einem Absender aus deinem Posteingang\nDM wird bei gegenseitigem Folgen geöffnet',
    'es': 'Sigue a un remitente de tu bandeja\nel DM se abre cuando te sigue de vuelta',
    'pt': 'Siga um remetente da sua caixa\no DM abre quando seguem de volta',
    'ru': 'Подпишитесь на отправителя из входящих\nЛС откроется при взаимной подписке',
    'tr': 'Gelen kutunuzdan bir göndericiyi takip edin\nkarşılıklı takipte DM açılır',
    'ar': 'تابع مرسلًا من صندوق الوارد\nتبدأ المحادثة عند المتابعة المتبادلة',
    'it': 'Segui un mittente dalla posta in arrivo\nil DM si apre con il follow reciproco',
    'hi': 'इनबॉक्स से किसी प्रेषक को फॉलो करें\nआपसी फॉलो पर DM शुरू होता है',
    'th': 'ติดตามผู้ส่งจากกล่องจดหมาย\nDM จะเปิดเมื่อติดตามกลับ',
  });

  String inboxDMChatWith(String name) => _t({
    'ko': '${name}님과 대화',
    'en': 'Chat with $name',
    'ja': '${name}さんとチャット',
    'zh': '与${name}对话',
    'fr': 'Discuter avec $name',
    'de': 'Chat mit $name',
    'es': 'Chat con $name',
    'pt': 'Conversa com $name',
    'ru': 'Чат с $name',
    'tr': '$name ile sohbet',
    'ar': 'محادثة مع $name',
    'it': 'Chat con $name',
    'hi': '$name से चैट',
    'th': 'แชทกับ $name',
  });

  String get inboxDMStartPrompt => _t({
    'ko': '빠른 1:1 대화를 시작하시겠어요?\n배송 없이 즉시 전달됩니다.',
    'en': 'Start a quick 1:1 conversation?\nMessages are delivered instantly.',
    'ja': 'クイック1:1会話を始めますか？\nメッセージは即時配信されます。',
    'zh': '开始快速1:1对话？\n消息即时送达。',
    'fr': 'Commencer une conversation 1:1 rapide ?\nLes messages sont livrés instantanément.',
    'de': 'Schnelle 1:1-Unterhaltung starten?\nNachrichten werden sofort zugestellt.',
    'es': '¿Iniciar una conversación 1:1 rápida?\nLos mensajes se entregan al instante.',
    'pt': 'Iniciar uma conversa 1:1 rápida?\nMensagens entregues instantaneamente.',
    'ru': 'Начать быстрый чат 1:1?\nСообщения доставляются мгновенно.',
    'tr': 'Hızlı 1:1 sohbet başlatılsın mı?\nMesajlar anında iletilir.',
    'ar': 'بدء محادثة 1:1 سريعة؟\nالرسائل تُسلم فوريًا.',
    'it': 'Iniziare una conversazione 1:1 rapida?\nI messaggi vengono consegnati istantaneamente.',
    'hi': 'त्वरित 1:1 बातचीत शुरू करें?\nसंदेश तुरंत वितरित होते हैं।',
    'th': 'เริ่มบทสนทนา 1:1 ด่วน?\nข้อความส่งทันที',
  });

  String get inboxStartChat => _t({
    'ko': '대화 시작',
    'en': 'Start Chat',
    'ja': 'チャット開始',
    'zh': '开始对话',
    'fr': 'Démarrer',
    'de': 'Chat starten',
    'es': 'Iniciar chat',
    'pt': 'Iniciar conversa',
    'ru': 'Начать чат',
    'tr': 'Sohbeti başlat',
    'ar': 'بدء المحادثة',
    'it': 'Inizia chat',
    'hi': 'चैट शुरू करें',
    'th': 'เริ่มแชท',
  });

  String get inboxInvite => _t({
    'ko': '초대',
    'en': 'Invite',
    'ja': '招待',
    'zh': '邀请',
    'fr': 'Invitation',
    'de': 'Einladung',
    'es': 'Invitación',
    'pt': 'Convite',
    'ru': 'Приглашение',
    'tr': 'Davet',
    'ar': 'دعوة',
    'it': 'Invito',
    'hi': 'आमंत्रण',
    'th': 'เชิญ',
  });

  String get inboxMutualFollow => _t({
    'ko': '맞팔로우! 대화를 시작해보세요',
    'en': 'Mutual follow! Start a conversation',
    'ja': '相互フォロー！会話を始めましょう',
    'zh': '互相关注！开始对话吧',
    'fr': 'Suivi mutuel ! Commencez une conversation',
    'de': 'Gegenseitiges Folgen! Starte eine Unterhaltung',
    'es': '¡Seguimiento mutuo! Inicia una conversación',
    'pt': 'Seguimento mútuo! Inicie uma conversa',
    'ru': 'Взаимная подписка! Начните разговор',
    'tr': 'Karşılıklı takip! Bir sohbet başlatın',
    'ar': 'متابعة متبادلة! ابدأ محادثة',
    'it': 'Follow reciproco! Inizia una conversazione',
    'hi': 'आपसी फॉलो! बातचीत शुरू करें',
    'th': 'ติดตามซึ่งกันและกัน! เริ่มบทสนทนา',
  });

  String get inboxStartConversation => _t({
    'ko': '대화를 시작해보세요',
    'en': 'Start a conversation',
    'ja': '会話を始めましょう',
    'zh': '开始对话吧',
    'fr': 'Commencez une conversation',
    'de': 'Starte eine Unterhaltung',
    'es': 'Inicia una conversación',
    'pt': 'Inicie uma conversa',
    'ru': 'Начните разговор',
    'tr': 'Bir sohbet başlatın',
    'ar': 'ابدأ محادثة',
    'it': 'Inizia una conversazione',
    'hi': 'बातचीत शुरू करें',
    'th': 'เริ่มบทสนทนา',
  });

  String get inboxFollowing => _t({
    'ko': '팔로잉',
    'en': 'Following',
    'ja': 'フォロー中',
    'zh': '正在关注',
    'fr': 'Abonnements',
    'de': 'Folge ich',
    'es': 'Siguiendo',
    'pt': 'Seguindo',
    'ru': 'Подписки',
    'tr': 'Takip edilen',
    'ar': 'المتابَعون',
    'it': 'Seguiti',
    'hi': 'फ़ॉलो कर रहे',
    'th': 'กำลังติดตาม',
  });

  String get inboxNoFollowing => _t({
    'ko': '팔로잉 중인 유저가 없어요',
    'en': 'You are not following anyone',
    'ja': 'フォロー中のユーザーはいません',
    'zh': '还没有关注任何人',
    'fr': 'Vous ne suivez personne',
    'de': 'Du folgst niemandem',
    'es': 'No sigues a nadie',
    'pt': 'Você não segue ninguém',
    'ru': 'Вы ни на кого не подписаны',
    'tr': 'Kimseyi takip etmiyorsunuz',
    'ar': 'لا تتابع أحدًا',
    'it': 'Non segui nessuno',
    'hi': 'आप किसी को फॉलो नहीं कर रहे',
    'th': 'คุณยังไม่ได้ติดตามใคร',
  });

  String get inboxNoFollowingSub => _t({
    'ko': '혜택을 읽고 발신자를 팔로우 해보세요!',
    'en': 'Read rewards and follow the senders!',
    'ja': '手紙を読んで送信者をフォローしましょう！',
    'zh': '阅读信件并关注发件人吧！',
    'fr': 'Lisez des lettres et suivez les expéditeurs !',
    'de': 'Lies Briefe und folge den Absendern!',
    'es': '¡Lee cartas y sigue a los remitentes!',
    'pt': 'Leia cartas e siga os remetentes!',
    'ru': 'Читайте письма и подписывайтесь на отправителей!',
    'tr': 'Mektupları okuyun ve gönderenleri takip edin!',
    'ar': 'اقرأ الرسائل وتابع المرسلين!',
    'it': 'Leggi le lettere e segui i mittenti!',
    'hi': 'पत्र पढ़ें और प्रेषकों को फ़ॉलो करें!',
    'th': 'อ่านจดหมายและติดตามผู้ส่ง!',
  });

  String get inboxNoFollowers => _t({
    'ko': '아직 팔로워가 없어요',
    'en': 'No followers yet',
    'ja': 'まだフォロワーはいません',
    'zh': '还没有粉丝',
    'fr': 'Pas encore de followers',
    'de': 'Noch keine Follower',
    'es': 'Aún no tienes seguidores',
    'pt': 'Nenhum seguidor ainda',
    'ru': 'Пока нет подписчиков',
    'tr': 'Henüz takipçi yok',
    'ar': 'لا يوجد متابعون بعد',
    'it': 'Nessun follower ancora',
    'hi': 'अभी तक कोई फॉलोअर नहीं',
    'th': 'ยังไม่มีผู้ติดตาม',
  });

  String get inboxNoFollowersSub => _t({
    'ko': '혜택을 더 보내면 팔로워가 생겨요!',
    'en': 'Send more promos to gain followers!',
    'ja': 'もっと手紙を送ってフォロワーを増やしましょう！',
    'zh': '多发信件就能获得粉丝！',
    'fr': 'Envoyez plus de lettres pour gagner des followers !',
    'de': 'Sende mehr Briefe, um Follower zu gewinnen!',
    'es': '¡Envía más cartas para ganar seguidores!',
    'pt': 'Envie mais cartas para ganhar seguidores!',
    'ru': 'Отправляйте больше писем, чтобы получить подписчиков!',
    'tr': 'Daha fazla mektup göndererek takipçi kazanın!',
    'ar': 'أرسل المزيد من الرسائل لكسب متابعين!',
    'it': 'Invia più lettere per ottenere follower!',
    'hi': 'और पत्र भेजें, फॉलोअर मिलेंगे!',
    'th': 'ส่งจดหมายเพิ่มเพื่อได้ผู้ติดตาม!',
  });

  // ── Premium Screen ──────────────────────────────────────────────────
  // ── premium_gate_sheet.dart ──

  // Build 150: Premium Gate 가격 카드 안심 문구.
  String get premiumGateAssurance => _t({
    'ko': '언제든 해지 · 광고 없음',
    'en': 'Cancel anytime · No ads',
    'ja': 'いつでも解約可能 · 広告なし',
    'zh': '随时取消 · 无广告',
    'fr': 'Annulation à tout moment · Sans pub',
    'de': 'Jederzeit kündbar · Keine Werbung',
    'es': 'Cancela cuando quieras · Sin anuncios',
    'pt': 'Cancela quando quiseres · Sem anúncios',
    'ru': 'Отмена в любое время · Без рекламы',
    'tr': 'İstediğin zaman iptal · Reklamsız',
    'ar': 'إلغاء في أي وقت · بدون إعلانات',
    'it': 'Cancella quando vuoi · Senza pubblicità',
    'hi': 'कभी भी रद्द · बिना विज्ञापन',
    'th': 'ยกเลิกเมื่อใดก็ได้ · ไม่มีโฆษณา',
  });

  String get premiumGatePriceLabel => _t({
    'ko': '₩4,900 / 월',
    'en': '₩4,900 / mo',
    'ja': '₩4,900 / 月',
    'zh': '₩4,900 / 月',
    'fr': '₩4,900 / mois',
    'de': '₩4,900 / Monat',
    'es': '₩4,900 / mes',
    'pt': '₩4,900 / mês',
    'ru': '₩4,900 / мес',
    'tr': '₩4,900 / ay',
    'ar': '₩4,900 / شهر',
    'it': '₩4,900 / mese',
    'hi': '₩4,900 / माह',
    'th': '₩4,900 / เดือน',
  });

  String get premiumGateStartBtn => _t({
    'ko': '👑 프리미엄 시작하기',
    'en': '👑 Start Premium',
    'ja': '👑 プレミアムを始める',
    'zh': '👑 开始高级版',
    'fr': '👑 Commencer Premium',
    'de': '👑 Premium starten',
    'es': '👑 Iniciar Premium',
    'pt': '👑 Iniciar Premium',
    'ru': '👑 Начать Премиум',
    'tr': '👑 Premium Başlat',
    'ar': '👑 ابدأ بريميوم',
    'it': '👑 Inizia Premium',
    'hi': '👑 प्रीमियम शुरू करें',
    'th': '👑 เริ่มใช้พรีเมียม',
  });

  // ── premium_screen.dart ──

  String get premiumPurchaseSuccess => _t({
    'ko': '구매가 완료되었습니다.',
    'en': 'Purchase completed.',
    'ja': '購入が完了しました。',
    'zh': '购买完成。',
    'fr': 'Achat terminé.',
    'de': 'Kauf abgeschlossen.',
    'es': 'Compra completada.',
    'pt': 'Compra concluída.',
    'ru': 'Покупка завершена.',
    'tr': 'Satın alma tamamlandı.',
    'ar': 'تم الشراء.',
    'it': 'Acquisto completato.',
    'hi': 'खरीदारी पूरी हुई।',
    'th': 'ซื้อเสร็จสิ้น',
  });

  String get premiumPurchaseFail => _t({
    'ko': '구매를 진행하지 못했습니다. 잠시 후 다시 시도해주세요.',
    'en': 'Purchase failed. Please try again later.',
    'ja': '購入できませんでした。しばらくしてからお試しください。',
    'zh': '购买失败，请稍后重试。',
    'fr': 'Échec de l\'achat. Veuillez réessayer plus tard.',
    'de': 'Kauf fehlgeschlagen. Bitte versuchen Sie es später erneut.',
    'es': 'Compra fallida. Inténtelo de nuevo más tarde.',
    'pt': 'Falha na compra. Tente novamente mais tarde.',
    'ru': 'Покупка не удалась. Попробуйте позже.',
    'tr': 'Satın alma başarısız. Lütfen daha sonra tekrar deneyin.',
    'ar': 'فشل الشراء. يرجى المحاولة لاحقاً.',
    'it': 'Acquisto non riuscito. Riprova più tardi.',
    'hi': 'खरीदारी विफल। क��पया बाद में पुनः प्रयास करें।',
    'th': 'ซื้อไม่สำเร็จ กรุณาลองใหม่ภายหลัง',
  });

  String get premiumValueFeature1 => _t({
    'ko': '하루 3통 제한 해제 → 최대 30통 발송',
    'en': 'Remove 3/day limit → send up to 30/day',
    'ja': '1日3通制限解除 → 最大30通送信',
    'zh': '解除每日3封限制 → 最多发送30封',
    'fr': 'Supprimez la limite de 3/jour → envoyez jusqu\'à 30/jour',
    'de': '3/Tag-Limit aufheben → bis zu 30/Tag senden',
    'es': 'Elimina el límite de 3/día → envía hasta 30/día',
    'pt': 'Remova o limite de 3/dia → envie até 30/dia',
    'ru': 'Снимите лимит 3/день → отправляйте до 30/день',
    'tr': 'Günlük 3 sınırını kaldır → günde 30\'a kadar gönder',
    'ar': 'إزالة حد 3/يوم → إرسال حتى 30/يوم',
    'it': 'Rimuovi il limite di 3/giorno → invia fino a 30/giorno',
    'hi': '3/दिन की सीमा हटाएं → 30/दिन तक भेजें',
    'th': 'ยกเลิกจำกัด 3/วัน → ส่งได้สูงสุด 30/วัน',
  });

  String get premiumValueFeature2 => _t({
    'ko': '더 많이 보내고 답장 기회 최대 10배 확장',
    'en': 'Send more and expand reply chances up to 10x',
    'ja': 'もっと送信して返信チャンスを最大10倍に',
    'zh': '发送更多，回复机会扩大10倍',
    'fr': 'Envoyez plus et multipliez par 10 les chances de réponse',
    'de': 'Mehr senden und Antwortchancen bis zu 10x erhöhen',
    'es': 'Envía más y amplía las oportunidades de respuesta hasta 10x',
    'pt': 'Envie mais e expanda as chances de resposta até 10x',
    'ru': 'Отправляйте больше и увеличьте шансы на ответ в 10 раз',
    'tr': 'Daha fazla gönder ve yanıt şansını 10 kata kadar artır',
    'ar': 'أرسل أكثر ووسّع فرص الرد حتى 10 أضعاف',
    'it': 'Invia di più e moltiplica le possibilità di risposta fino a 10x',
    'hi': 'अधिक भेजें और उत्तर के अवसर 10 गुना तक बढ़ाएं',
    'th': 'ส่งมากขึ้นและเพิ่มโอกาสตอบกลับสูงสุด 10 เท่า',
  });

  String get premiumValueFeature3 => _t({
    'ko': '이미지+링크 혜택으로 응답률 강화 (하루 20통)',
    'en': 'Boost response rate with image+link promos (20/day)',
    'ja': '画像+リンク付き手紙で応答率アップ（1日20通）',
    'zh': '图片+链接信件提高回复率（每日20封）',
    'fr': 'Boostez le taux de réponse avec des lettres image+lien (20/jour)',
    'de': 'Antwortrate mit Bild+Link-Briefen steigern (20/Tag)',
    'es': 'Aumenta la tasa de respuesta con cartas con imagen+enlace (20/día)',
    'pt': 'Aumente a taxa de resposta com cartas com imagem+link (20/dia)',
    'ru': 'Повысьте отклик с письмами с фото+ссылкой (20/день)',
    'tr': 'Resim+link mektuplarla yanıt oranını artır (günde 20)',
    'ar': 'عزز معدل الاستجابة برسائل صور+روابط (20/يوم)',
    'it': 'Aumenta il tasso di risposta con lettere immagine+link (20/giorno)',
    'hi': 'छवि+लिंक पत्रों से प्रतिक्रिया दर बढ़ाएं (20/दिन)',
    'th': 'เพิ่มอัตราตอบกลับด้วยจดหมายภาพ+ลิงก์ (20/วัน)',
  });

  String get premiumValueFeature4 => _t({
    'ko': '특급 배송 하루 3통 + 커스텀 타워로 존재감 강화',
    'en': 'Express delivery 3/day + custom tower for visibility',
    'ja': '特急配送1日3通 + カスタムタワーで存在感アップ',
    'zh': '特快配送每日3封 + 自定义塔楼提升存在感',
    'fr': 'Livraison express 3/jour + tour personnalisée pour la visibilité',
    'de': 'Express-Zustellung 3/Tag + benutzerdefinierter Turm für Sichtbarkeit',
    'es': 'Entrega exprés 3/día + torre personalizada para visibilidad',
    'pt': 'Entrega expressa 3/dia + torre personalizada para visibilidade',
    'ru': 'Экспресс-доставка 3/день + кастомная башня для заметности',
    'tr': 'Ekspres teslimat günde 3 + özel kule ile görünürlük',
    'ar': 'توصيل سريع 3/يوم + برج مخصص للظهور',
    'it': 'Consegna espressa 3/giorno + torre personalizzata per visibilità',
    'hi': 'एक्सप्रेस डिलीवरी 3/दिन + कस्टम टावर से दृश्यता बढ़ाएं',
    'th': 'จัดส่งด่วน 3/วัน + หอคอยกำหนดเองเพิ่มการมองเห็น',
  });

  // Build 118: 기능 리스트 재배치 — 발송 중심 → 픽업 중심. 마케팅 기획서
  // Build 113 의 "레벨업 = 실제 반경 확대" 차별화 축에 정렬. 1·2번이 헌트
  // 핵심 차이 (반경·쿨다운), 3·4번은 발송·꾸미기 번들.
  String get premiumFeature1 => _t({
    'ko': '줍기 반경 1km · Free 200m의 5배',
    'en': '1 km pickup radius · 5× the free 200 m',
    'ja': '拾える範囲 1km · 無料 200m の 5倍',
    'zh': '拾取范围 1km · 免费 200m 的 5 倍',
    'fr': 'Rayon de ramassage 1 km · 5× des 200 m gratuits',
    'de': 'Aufsammelradius 1 km · 5× die kostenlosen 200 m',
    'es': 'Radio de recogida 1 km · 5× los 200 m gratis',
    'pt': 'Raio de recolha 1 km · 5× os 200 m grátis',
    'ru': 'Радиус подбора 1 км · 5× бесплатных 200 м',
    'tr': 'Toplama yarıçapı 1 km · ücretsiz 200 m’nin 5 katı',
    'ar': 'نطاق الالتقاط 1 كم · 5 أضعاف 200 م المجانية',
    'it': 'Raggio di raccolta 1 km · 5× i 200 m gratuiti',
    'hi': 'पिकअप रेडियस 1 किमी · मुफ्त 200 मी का 5 गुना',
    'th': 'รัศมีเก็บจดหมาย 1 กม. · 5 เท่าของ 200 ม. ฟรี',
  });

  String get premiumFeature2 => _t({
    'ko': '10분 쿨다운 · Free 60분 대비 6배 빠른 픽업',
    'en': '10-min cooldown · 6× faster than free',
    'ja': '10分クールダウン · 無料60分より6倍速い',
    'zh': '冷却 10 分钟 · 比免费 60 分钟快 6 倍',
    'fr': 'Recharge 10 min · 6× plus rapide que le gratuit',
    'de': '10 min Abklingzeit · 6× schneller als kostenlos',
    'es': 'Enfriamiento 10 min · 6× más rápido que gratis',
    'pt': 'Recarga 10 min · 6× mais rápido que o grátis',
    'ru': 'Перезарядка 10 мин · в 6 раз быстрее бесплатной',
    'tr': '10 dk bekleme · ücretsizden 6× hızlı',
    'ar': 'تبريد 10 دقائق · أسرع 6 أضعاف من المجانية',
    'it': 'Cooldown 10 min · 6× più veloce del gratuito',
    'hi': '10 मिनट कूलडाउन · मुफ्त से 6× तेज़',
    'th': 'คูลดาวน์ 10 นาที · เร็วกว่าฟรี 6 เท่า',
  });

  String get premiumFeature3 => _t({
    'ko': '📸 사진 + 🔗 채널 링크 홍보 메시지 · 하루 30통',
    'en': '📸 Photo + 🔗 channel-link promo messages · 30/day',
    'ja': '📸 写真 + 🔗 チャンネルリンクPR手紙 · 1日30通',
    'zh': '📸 照片 + 🔗 频道链接推广信件 · 每日 30 封',
    'fr': '📸 Photo + 🔗 lien de chaîne promo · 30/jour',
    'de': '📸 Foto + 🔗 Kanal-Link Promo-Briefe · 30/Tag',
    'es': '📸 Foto + 🔗 enlace canal promo · 30/día',
    'pt': '📸 Foto + 🔗 link de canal promo · 30/dia',
    'ru': '📸 Фото + 🔗 ссылка на канал · 30/день',
    'tr': '📸 Fotoğraf + 🔗 kanal bağlantısı · 30/gün',
    'ar': '📸 صور + 🔗 روابط قناة ترويجية · 30/يوم',
    'it': '📸 Foto + 🔗 link canale promo · 30/giorno',
    'hi': '📸 फ़ोटो + 🔗 चैनल लिंक प्रोमो · 30/दिन',
    'th': '📸 รูป + 🔗 ลิงก์ช่อง · 30/วัน',
  });

  // Build 185: Premium 혜택에서 타워 언급 제거 — Premium = 레터 트랙.
  // 캐릭터 커스터마이즈(컴패니언/악세사리)는 Build 125 이후 Premium 전용,
  // 특급 배송은 이전부터 유지.
  String get premiumFeature4 => _t({
    'ko': '🎨 카운터 캐릭터 커스터마이즈 · 특급 배송 3통/일',
    'en': '🎨 Counter character customize · 3 express deliveries/day',
    'ja': '🎨 Counter キャラカスタム · 特急配送 3/日',
    'zh': '🎨 Letter 角色定制 · 特快配送 3/日',
    'fr': '🎨 Personnalisation du Letter · 3 livraisons express/jour',
    'de': '🎨 Letter-Charakter anpassen · 3 Express-Lieferungen/Tag',
    'es': '🎨 Personaliza tu Letter · 3 entregas exprés/día',
    'pt': '🎨 Personaliza o teu Letter · 3 entregas expressas/dia',
    'ru': '🎨 Кастомизация Letter · 3 экспресса/день',
    'tr': '🎨 Letter karakter özelleştirme · 3 ekspres/gün',
    'ar': '🎨 تخصيص شخصية Letter · 3 توصيلات سريعة/يوم',
    'it': '🎨 Personalizza il Letter · 3 espressi/giorno',
    'hi': '🎨 Letter कस्टमाइज़ · 3 एक्सप्रेस/दिन',
    'th': '🎨 ปรับแต่ง Letter · ด่วน 3/วัน',
  });

  // Build 118: Free 플랜 카드도 픽업 중심으로 재배치 — 반경·쿨다운 제약을
  // 먼저 보여 Premium 업그레이드 동기를 시각화.
  String get premiumFreeFeature1 => _t({
    'ko': '줍기 반경 200m · 쿨다운 60분',
    'en': '200 m pickup radius · 60-min cooldown',
    'ja': '拾える範囲 200m · 60分クールダウン',
    'zh': '拾取范围 200m · 冷却 60 分钟',
    'fr': 'Rayon 200 m · recharge 60 min',
    'de': '200 m Radius · 60 min Abklingzeit',
    'es': 'Radio 200 m · enfriamiento 60 min',
    'pt': 'Raio 200 m · recarga 60 min',
    'ru': 'Радиус 200 м · перезарядка 60 мин',
    'tr': '200 m yarıçap · 60 dk bekleme',
    'ar': 'نطاق 200 م · تبريد 60 دقيقة',
    'it': 'Raggio 200 m · cooldown 60 min',
    'hi': '200 मी रेडियस · 60 मिनट कूलडाउन',
    'th': 'รัศมี 200 ม. · คูลดาวน์ 60 นาที',
  });

  String get premiumFreeFeature2 => _t({
    'ko': '하루 3통 발송 · 월 100통',
    'en': '3 promos/day · 100/month',
    'ja': '1日3通 · 月100通',
    'zh': '每日3封 · 每月100封',
    'fr': '3 lettres/jour · 100/mois',
    'de': '3 Briefe/Tag · 100/Monat',
    'es': '3 cartas/día · 100/mes',
    'pt': '3 cartas/dia · 100/mês',
    'ru': '3 письма/день · 100/месяц',
    'tr': 'Günde 3 · ayda 100',
    'ar': '3 رسائل/يوم · 100/شهر',
    'it': '3 lettere/giorno · 100/mese',
    'hi': '3 पत्र/दिन · 100/माह',
    'th': '3 ฉบับ/วัน · 100/เดือน',
  });

  String get premiumSwitchToFree => _t({
    'ko': '무료 플랜으로 전환',
    'en': 'Switch to Free Plan',
    'ja': '無料プランに変更',
    'zh': '切换到免费方案',
    'fr': 'Passer au forfait gratuit',
    'de': 'Zum kostenlosen Plan wechseln',
    'es': 'Cambiar al plan gratuito',
    'pt': 'Mudar para o plano gratuito',
    'ru': 'Переключиться на бесплатный план',
    'tr': 'Ücretsiz plana geç',
    'ar': 'التبديل إلى الخطة المجانية',
    'it': 'Passa al piano gratuito',
    'hi': 'मुफ्त योजना पर स्विच करें',
    'th': 'เปลี่ยนเป็นแพ็กเกจฟรี',
  });

  String get premiumSwitchToFreeDesc => _t({
    'ko': '다음 결제일부터 무료 플랜으로 전환됩니다.\n현재 구독 기간은 계속 이용 가능합니다.',
    'en': 'You will switch to the Free plan from the next billing date.\nYou can continue using the current subscription until then.',
    'ja': '次の決済日から無料プランに変更されます。\n現在のサブスクリプション期間は引き続きご利用いただけます。',
    'zh': '将从下一个付款日起切换到免费方案。\n当前订阅期间仍可继续使用。',
    'fr': 'Vous passerez au forfait gratuit à la prochaine date de facturation.\nVous pouvez continuer à utiliser l\'abonnement actuel jusque-là.',
    'de': 'Sie wechseln ab dem nächsten Abrechnungsdatum zum kostenlosen Plan.\nSie können das aktuelle Abonnement bis dahin weiterhin nutzen.',
    'es': 'Cambiará al plan gratuito desde la próxima fecha de facturación.\nPuede seguir usando la suscripción actual hasta entonces.',
    'pt': 'Você mudará para o plano gratuito a partir da próxima data de cobrança.\nVocê pode continuar usando a assinatura atual até lá.',
    'ru': 'Вы перейдёте на бесплатный план со следующей даты оплаты.\nДо тех пор вы можете пользоваться текущей подпиской.',
    'tr': 'Bir sonraki fatura tarihinden itibaren ücretsiz plana geçeceksiniz.\nO zamana kadar mevcut aboneliğinizi kullanmaya devam edebilirsiniz.',
    'ar': 'ستنتقل إلى الخطة المجانية من تاريخ الفوترة التالي.\nيمكنك الاستمرار في استخدام الاشتراك الحالي حتى ذلك الحين.',
    'it': 'Passerai al piano gratuito dalla prossima data di fatturazione.\nPuoi continuare a usare l\'abbonamento attuale fino ad allora.',
    'hi': 'अगली बिलिंग तिथि से मुफ्त योजना पर स्विच होगा।\nतब तक आप वर्तमान सदस्यता का उपयोग जारी रख सकते हैं।',
    'th': 'จะเปลี่ยนเป็นแพ็กเกจฟรีตั้งแต่วัน��รียกเก็บเงินถัดไป\nคุณยังใช้งานแพ็กเกจปัจจุบันได้จนกว่าจะถึงวันนั้น',
  });

  String get premiumCancelViaStore => _t({
    'ko': '실제 해지는 앱스토어 → 설정 → 구독에서 진행해야 합니다',
    'en': 'Actual cancellation must be done in App Store → Settings → Subscriptions',
    'ja': '実際の解約はApp Store → 設定 → サブスクリプションで行う必要があります',
    'zh': '实际取消需在App Store → 设置 → 订阅中操作',
    'fr': 'L\'annulation réelle doit être effectuée dans App Store → Paramètres → Abonnements',
    'de': 'Die tatsächliche Kündigung muss im App Store → Einstellungen → Abonnements erfolgen',
    'es': 'La cancelación real debe hacerse en App Store → Ajustes → Suscripciones',
    'pt': 'O cancelamento real deve ser feito na App Store → Ajustes → Assinaturas',
    'ru': 'Фактическая отмена должна быть выполнена в App Store → Настройки → Подписки',
    'tr': 'Gerçek iptal App Store → Ayarlar → Abonelikler\'den yapılmalıdır',
    'ar': 'يجب إتمام الإلغاء الفعلي في متجر التطبيقات → الإعدادات → الاشتراكات',
    'it': 'L\'annullamento effettivo deve essere fatto in App Store → Impostazioni → Abbonamenti',
    'hi': 'वास्तविक रद्दीकरण App Store → सेटिंग्स → सदस्यता में करना होगा',
    'th': 'การยกเลิกจริงต้องทำที่ App Store → ตั้งค่า → การสมัครสมาชิก',
  });

  String get premiumCancel => _t({
    'ko': '취소',
    'en': 'Cancel',
    'ja': 'キャンセル',
    'zh': '取消',
    'fr': 'Annuler',
    'de': 'Abbrechen',
    'es': 'Cancelar',
    'pt': 'Cancelar',
    'ru': 'Отмена',
    'tr': 'İptal',
    'ar': 'إلغاء',
    'it': 'Annulla',
    'hi': 'रद्द करें',
    'th': 'ยกเลิก',
  });

  String get premiumPerMonth => _t({
    'ko': '/월',
    'en': '/mo',
    'ja': '/月',
    'zh': '/月',
    'fr': '/mois',
    'de': '/Monat',
    'es': '/mes',
    'pt': '/mês',
    'ru': '/мес',
    'tr': '/ay',
    'ar': '/شهر',
    'it': '/mese',
    'hi': '/माह',
    'th': '/เดือน',
  });

  String get premiumPremiumTestDesc => _t({
    'ko': '하루 30통 발송 · 이미지+링크 홍보\n타워 커스텀 · 특급 배송',
    'en': '30 promos/day · image+link promos\nCustom tower · express delivery',
    'ja': '1日30通 · 画像+リンク手紙\nタワーカスタム · 特急配送',
    'zh': '每日30封 · 图片+链接信件\n自定义塔楼 · 特快配送',
    'fr': '30 lettres/jour · lettres image+lien\nTour personnalisée · livraison express',
    'de': '30 Briefe/Tag · Bild+Link-Briefe\nBenutzerdefinierter Turm · Express-Zustellung',
    'es': '30 cartas/día · cartas imagen+enlace\nTorre personalizada · entrega exprés',
    'pt': '30 cartas/dia · cartas imagem+link\nTorre personalizada · entrega expressa',
    'ru': '30 писем/день · п��сьма с фото+ссылкой\nКастомная башня · экспресс-доставка',
    'tr': 'Günde 30 · resim+link mektuplar\nÖzel kule �� ekspres teslimat',
    'ar': '30 رسالة/يوم · رسائل صور+روابط\nبرج مخصص · توصيل سريع',
    'it': '30 lettere/giorno · lettere immagine+link\nTorre personalizzata · consegna espressa',
    'hi': '30 पत्र/दिन · छवि+लिंक पत्र\nकस्टम टावर · एक्सप्रेस डिलीवरी',
    'th': '30 ฉบับ/วัน · จดหมายภาพ+ลิงก์\nหอคอยกำหนดเอง · จัดส่งด่วน',
  });

  String get premiumNoDowngrade => _t({
    'ko': '다운그레이드 불가',
    'en': 'Cannot downgrade',
    'ja': 'ダウングレード不可',
    'zh': '无法降级',
    'fr': 'Rétrogradation impossible',
    'de': 'Downgrade nicht möglich',
    'es': 'No se puede bajar de plan',
    'pt': 'Não é possível fazer downgrade',
    'ru': 'Понижение невозможно',
    'tr': 'Düşürme yapılamaz',
    'ar': 'لا يمكن الخفض',
    'it': 'Downgrade non possibile',
    'hi': 'डाउनग्रेड संभव नहीं',
    'th': 'ไม่สามารถลดแพ็กเกจได้',
  });

  String get premiumBrandFeature1 => _t({
    'ko': '하루 200통 발송 · 월 10,000통',
    'en': '200 promos/day · 10,000/month',
    'ja': '1日200通 · 月10,000通',
    'zh': '每日200封 · 每月10,000封',
    'fr': '200 lettres/jour · 10 000/mois',
    'de': '200 Briefe/Tag · 10.000/Monat',
    'es': '200 cartas/día · 10.000/mes',
    'pt': '200 cartas/dia · 10.000/mês',
    'ru': '200 писем/день · 10 000/месяц',
    'tr': 'Günde 200 · ayda 10.000',
    'ar': '200 رسالة/يوم · 10,000/شهر',
    'it': '200 lettere/giorno · 10.000/mese',
    'hi': '200 पत्र/दिन · 10,000/माह',
    'th': '200 ฉบับ/วัน · 10,000/เดือน',
  });

  String get premiumBrandFeature2 => _t({
    'ko': '추가 발송권 구매 (1,000통 ₩15,000)',
    'en': 'Purchase extra credits (1,000 for ₩15,000)',
    'ja': '追加送信権購入（1,000通 ₩15,000）',
    'zh': '购买额外发送额度（1,000封 ₩15,000）',
    'fr': 'Acheter des crédits supplémentaires (1 000 pour ₩15 000)',
    'de': 'Zusätzliche Credits kaufen (1.000 für ₩15.000)',
    'es': 'Comprar créditos extra (1.000 por ₩15.000)',
    'pt': 'Comprar créditos extras (1.000 por ₩15.000)',
    'ru': 'Купить доп. кредиты (1 000 за ₩15 000)',
    'tr': 'Ekstra kredi satın al (1.000 adet ₩15.000)',
    'ar': 'شراء رصيد إضافي (1,000 مقابل ₩15,000)',
    'it': 'Acquista crediti extra (1.000 per ₩15.000)',
    'hi': 'अतिरिक्त क्रेडिट खरीदें (1,000 के लिए ₩15,000)',
    'th': 'ซื้อเครดิตเพิ่ม (1,000 ฉบับ ₩15,000)',
  });

  String get premiumBrandFeature3 => _t({
    'ko': '복수 나라 동시 대량 발송',
    'en': 'Bulk send to multiple countries simultaneously',
    'ja': '複数国同時大量送信',
    'zh': '多国同时批量发送',
    'fr': 'Envoi en masse simultané vers plusieurs pays',
    'de': 'Massenversand an mehrere Länder gleichzeitig',
    'es': 'Envío masivo a múltiples países simultáneamente',
    'pt': 'Envio em massa para vários países simultaneamente',
    'ru': 'Массовая рассылка в несколько стр��н одновременно',
    'tr': 'Birden fazla ülkeye aynı anda toplu gönderim',
    'ar': 'إرسال جماعي لعدة دول في وقت واحد',
    'it': 'Invio in massa a più paesi contemporaneamente',
    'hi': 'कई देशों में एक साथ बल्क भेजें',
    'th': 'ส่งจำนวนมากไปหลายประเทศพร้อมกัน',
  });

  String get premiumBrandFeature4 => _t({
    'ko': '공식 인증 배지 표시',
    'en': 'Official verified badge',
    'ja': '公式��証バッジ表示',
    'zh': '显示官方认证徽章',
    'fr': 'Badge vérifié officiel',
    'de': 'Offizielles Verifizierungsabzeichen',
    'es': 'Insignia oficial verificada',
    'pt': 'Selo oficial verificado',
    'ru': 'Официальный верифицированный значок',
    'tr': 'Resmi doğrulama rozeti',
    'ar': 'شارة التحقق الرسمية',
    'it': 'Badge ufficiale verificato',
    'hi': 'आधिकारिक सत्यापित बैज',
    'th': 'แสดงเครื่องหมายยืนยันอย่างเป็นทางการ',
  });

  String get premiumBrandFeature5 => _t({
    'ko': '혜택에 신고 버튼 미표시',
    'en': 'No report button on rewards',
    'ja': '手紙に通報ボタン非表示',
    'zh': '信件不显示举报按钮',
    'fr': 'Pas de bouton de signalement sur les lettres',
    'de': 'Kein Melden-Button auf Briefen',
    'es': 'Sin botón de reporte en cartas',
    'pt': 'Sem botão de denúncia nas cartas',
    'ru': 'Без кнопки жалобы на ��исьмах',
    'tr': 'Mektuplarda şikayet butonu yok',
    'ar': 'بدون زر بلاغ على الرسائل',
    'it': 'Nessun pulsante segnala sulle lettere',
    'hi': 'पत्रों पर रिपोर्ट बटन नहीं',
    'th': 'ไม่แสดงปุ่มรายงานบนจดหมาย',
  });

  String get premiumBrandFeature6 => _t({
    'ko': 'Premium 모든 기능 포함',
    'en': 'All Premium features included',
    'ja': 'Premiumの全機能を含む',
    'zh': '包含所有Premium功能',
    'fr': 'Toutes les fonctions Premium incluses',
    'de': 'Alle Premium-Funktionen enthalten',
    'es': 'Todas las funciones Premium incluidas',
    'pt': 'Todas as funções Premium incluídas',
    'ru': 'Все функции Premium включены',
    'tr': 'Tüm Premium özellikleri dahil',
    'ar': 'جميع ميزات بريميوم مضمنة',
    'it': 'Tutte le funzioni Premium incluse',
    'hi': 'सभी Premium सुविधाएं शामिल',
    'th': 'รวมฟีเจอร์ Premium ทั้งหมด',
  });

  String get premiumBrandTestDesc => _t({
    'ko': '하루 200통 · 인증 배지 · 대량 발송\nPremium 모든 기능 포함',
    'en': '200/day · verified badge · bulk send\nAll Premium features included',
    'ja': '1日200通 · 認証バッジ · 大量送信\nPremium全機能含む',
    'zh': '每日200封 · 认证徽章 · 批量发送\n包含所有Premium功能',
    'fr': '200/jour · badge vérifié · envoi en masse\nToutes les fonctions Premium incluses',
    'de': '200/Tag · Verifizierungsabzeichen · Massenversand\nAlle Premium-Funktionen enthalten',
    'es': '200/día · insignia verificada · envío masivo\nTodas las funciones Premium incluidas',
    'pt': '200/dia · selo verificado · envio em massa\nTodas as funções Premium incluídas',
    'ru': '200/день · значок верификации · массовая рассылка\nВсе функции Premium включены',
    'tr': 'Günde 200 · doğrulama rozeti · toplu gönderim\nTüm Premium özellikleri dahil',
    'ar': '200/يوم · شارة تحقق · إرسال جماعي\nجميع ميزات بريميوم مضمنة',
    'it': '200/giorno · badge verificato · invio in massa\nTutte le funzioni Premium incluse',
    'hi': '200/दिन · सत्यापित बैज · बल्क भेजें\nसभी Premium सुविधाएं शामिल',
    'th': '200/วัน · เครื่องหมายยืนยัน · ส่งจำนวนมาก\nรวมฟีเจอร์ Premium ทั้งหมด',
  });

  String get premiumBrandSchedule => _t({
    'ko': '브랜드 변경 예약',
    'en': 'Schedule Brand upgrade',
    'ja': 'ブランド変更予約',
    'zh': '预约品牌升级',
    'fr': 'Planifier le passage à Brand',
    'de': 'Brand-Upgrade planen',
    'es': 'Programar cambio a Brand',
    'pt': 'Agendar upgrade para Brand',
    'ru': 'Запланировать переход на Brand',
    'tr': 'Brand yükseltme planla',
    'ar': 'جدولة ترقية Brand',
    'it': 'Pianifica upgrade a Brand',
    'hi': 'Brand अपग्रेड शेड्यूल करें',
    'th': 'กำหนดการอัปเกรด Brand',
  });

  String get premiumSectionInvite => _t({
    'ko': '친구 초대 리워드',
    'en': 'Invite Friend Rewards',
    'ja': '友達招待リワード',
    'zh': '邀请好友奖励',
    'fr': 'Récompenses d\'invitation d\'amis',
    'de': 'Freunde-einladen-Belohnungen',
    'es': 'Recompensas por invitar amigos',
    'pt': 'Recompensas por convidar amigos',
    'ru': 'Награды за приглашение друзей',
    'tr': 'Arkadaş davet ödülleri',
    'ar': 'مكافآت دعوة الأصدقاء',
    'it': 'Premi invita amici',
    'hi': 'मित्र आमंत्रण पुरस्कार',
    'th': 'รางวัลเชิญเพื่อน',
  });

  String get premiumRestoreTitle => _t({
    'ko': '구매 복원',
    'en': 'Restore Purchases',
    'ja': '購入の復元',
    'zh': '恢复购买',
    'fr': 'Restaurer les achats',
    'de': 'Käufe wiederherstellen',
    'es': 'Restaurar compras',
    'pt': 'Restaurar compras',
    'ru': 'Восстановить покупки',
    'tr': 'Satın almaları geri yükle',
    'ar': 'استعادة المشتريات',
    'it': 'Ripristina acquisti',
    'hi': 'खरीदारी पुनर्स्थापित करें',
    'th': 'กู้คืนการซื้อ',
  });

  String get premiumRestoreDesc => _t({
    'ko': 'iOS에서는 복원 시 Apple 계정 로그인 창이 표시될 수 있습니다.\n동일 Apple ID로 구매한 내역만 복원됩니다.',
    'en': 'On iOS, you may be asked to sign in with your Apple account.\nOnly purchases made with the same Apple ID will be restored.',
    'ja': 'iOSでは復元時にAppleアカウントのログイン画面が表示される場合があります。\n同じApple IDで購入した内容のみ復元されます。',
    'zh': '在iOS上，恢复时可能需要登录Apple账户。\n仅恢复使用同一Apple ID购买的内容。',
    'fr': 'Sur iOS, vous devrez peut-être vous connecter avec votre compte Apple.\nSeuls les achats effectués avec le même identifiant Apple seront restaurés.',
    'de': 'Auf iOS müssen Sie sich möglicherweise mit Ihrem Apple-Konto anmelden.\nNur Käufe mit derselben Apple-ID werden wiederhergestellt.',
    'es': 'En iOS, es posible que deba iniciar sesión con su cuenta Apple.\nSolo se restaurarán las compras realizadas con el mismo ID de Apple.',
    'pt': 'No iOS, pode ser necessário fazer login com sua conta Apple.\nApenas compras feitas com o mesmo Apple ID serão restauradas.',
    'ru': 'На iOS может потребоваться вход в учётную запись Apple.\nВосстановлены будут только покупки с тем же Apple ID.',
    'tr': 'iOS\'ta Apple hesabınızla giriş yapmanız istenebilir.\nYalnızca aynı Apple ID ile yapılan satın almalar geri yüklenir.',
    'ar': 'على iOS، قد يُطلب منك تسجيل الدخول بحساب Apple.\nسيتم استعادة المشتريات المرتبطة بنفس Apple ID فقط.',
    'it': 'Su iOS, potrebbe essere richiesto l\'accesso con il tuo account Apple.\nVerranno ripristinati solo gli acquisti effettuati con lo stesso Apple ID.',
    'hi': 'iOS पर, Apple खाते से लॉगिन करने के लिए कहा जा सकता है।\nकेवल उसी Apple ID से की गई खरीदारी पुनर्स्थापित होगी।',
    'th': 'บน iOS อาจต้องลงชื่อเข้าใช้ด้วยบัญชี Apple\nจะกู้คืนเฉพาะรายการที่ซื้อด้วย Apple ID เดียวกันเท่านั้น',
  });

  String get premiumRestoreBtn => _t({
    'ko': '복원',
    'en': 'Restore',
    'ja': '復元',
    'zh': '恢复',
    'fr': 'Restaurer',
    'de': 'Wiederherstellen',
    'es': 'Restaurar',
    'pt': 'Restaurar',
    'ru': 'Восстановить',
    'tr': 'Geri yükle',
    'ar': 'استعادة',
    'it': 'Ripristina',
    'hi': 'पुनर्स्थापित',
    'th': 'กู้คืน',
  });

  String get premiumRestoreSuccess => _t({
    'ko': '구매 내역을 복원했습니다.',
    'en': 'Purchases restored successfully.',
    'ja': '購入履歴を復元しました。',
    'zh': '购买记录已恢复。',
    'fr': 'Achats restaurés avec succès.',
    'de': 'Käufe erfolgreich wiederhergestellt.',
    'es': 'Compras restauradas con éxito.',
    'pt': 'Compras restauradas com sucesso.',
    'ru': 'Покупки успешно восстановлены.',
    'tr': 'Satın almalar başarıyla geri yüklendi.',
    'ar': 'تم استعادة المشتريات بنجاح.',
    'it': 'Acquisti ripristinati con successo.',
    'hi': 'खरीदारी सफलतापूर्वक पुनर्स्थापित।',
    'th': 'กู้คืนการซื้อสำเร็จ',
  });

  String get premiumAutoRenewAfterSub => _t({
    'ko': '자동갱신일은 구독 시작 후 표시됩니다.',
    'en': 'Auto-renewal date will be shown after subscription starts.',
    'ja': '自動更新日はサブスクリプション開始後に表示されます。',
    'zh': '自动续订日期将在订阅开始后显示。',
    'fr': 'La date de renouvellement automatique s\'affichera après le début de l\'abonnement.',
    'de': 'Das automatische Verlängerungsdatum wird nach Beginn des Abonnements angezeigt.',
    'es': 'La fecha de renovación automática se mostrará después de iniciar la suscripción.',
    'pt': 'A data de renovação automática será exibida após o início da assinatura.',
    'ru': 'Дата автопродления будет показана после начала подписки.',
    'tr': 'Otomatik yenileme tarihi abonelik başladıktan sonra gösterilecektir.',
    'ar': 'سيظهر تاريخ التجديد التلقائي بعد بدء الاشتراك.',
    'it': 'La data di rinnovo automatico verrà mostrata dopo l\'inizio dell\'abbonamento.',
    'hi': 'स्वत: नवीनीकरण तिथि सदस्य��ा शुरू होने के बाद दिखाई जाएगी।',
    'th': 'วันต่ออายุอัตโนมัติจะแสดงหลังเริ่มสมัครสมาชิก',
  });

  String get premiumAutoRenewDate => _t({
    'ko': '자동갱신 예정일',
    'en': 'Auto-renewal date',
    'ja': '自動更新予定日',
    'zh': '自动续订日期',
    'fr': 'Date de renouvellement automatique',
    'de': 'Automatisches Verlängerungsdatum',
    'es': 'Fecha de renovación automática',
    'pt': 'Data de renovação automática',
    'ru': 'Дата автопродления',
    'tr': 'Otomatik yenileme tarihi',
    'ar': 'تاريخ التجديد التلقائي',
    'it': 'Data rinnovo automatico',
    'hi': 'स्वत: नवीनीकरण तिथि',
    'th': 'วันต่ออายุอัตโนมัติ',
  });

  String get premiumAutoRenewSync => _t({
    'ko': '자동갱신일 동기화 중',
    'en': 'Syncing auto-renewal date',
    'ja': '自動更新日を同期中',
    'zh': '正在同步自动续订日期',
    'fr': 'Synchronisation de la date de renouvellement',
    'de': 'Synchronisierung des Verlängerungsdatums',
    'es': 'Sincronizando fecha de renovación',
    'pt': 'Sincronizando data de renovação',
    'ru': 'Синхронизация даты автопродления',
    'tr': 'Otomatik yenileme tarihi senkronize ediliyor',
    'ar': 'جارٍ مزامنة تاريخ التجديد التلقائي',
    'it': 'Sincronizzazione data rinnovo',
    'hi': 'स्वत: नवीनीकरण तिथि सिंक हो रही है',
    'th': 'กำลังซิงค์วันต่ออายุอัตโนมัติ',
  });

  String get premiumActiveLabel => _t({
    'ko': '이용 중',
    'en': 'Active',
    'ja': '利用中',
    'zh': '使用中',
    'fr': 'Actif',
    'de': 'Aktiv',
    'es': 'Activo',
    'pt': 'Ativo',
    'ru': 'Активно',
    'tr': 'Aktif',
    'ar': 'نشط',
    'it': 'Attivo',
    'hi': 'सक्रिय',
    'th': 'ใช้งานอยู่',
  });

  String get premiumGiftCard1Month => _t({
    'ko': '1개월 선물권',
    'en': '1-Month Gift Card',
    'ja': '1ヶ月ギフトカード',
    'zh': '1个月礼品卡',
    'fr': 'Carte cadeau 1 mois',
    'de': '1-Monats-Geschenkkarte',
    'es': 'Tarjeta regalo 1 mes',
    'pt': 'Cartão presente 1 mês',
    'ru': 'Подарочная карта на 1 месяц',
    'tr': '1 aylık hediye kartı',
    'ar': 'بطاقة هدية شهر واحد',
    'it': 'Carta regalo 1 mese',
    'hi': '1 महीने का गिफ्ट कार्ड',
    'th': 'บัตรของขวัญ 1 เดือน',
  });

  String get premiumGiftTestDesc => _t({
    'ko': '친구에게 1개월 프리미엄 선물\n(일반가 ₩9,900, 10% 할인)',
    'en': 'Gift 1 month of Premium to a friend\n(Regular ₩9,900, 10% off)',
    'ja': '友達に1ヶ月プレミアムをプレゼント\n（通常価格₩9,900、10%割引）',
    'zh': '送好友1个��高级版\n（原价₩9,900，9折优惠）',
    'fr': 'Offrez 1 mois de Premium à un ami\n(Prix normal ₩9 900, remise de 10%)',
    'de': 'Schenken Sie einem Freund 1 Monat Premium\n(Normalpreis ₩9.900, 10% Rabatt)',
    'es': 'Regala 1 mes de Premium a un amigo\n(Precio normal ₩9.900, 10% descuento)',
    'pt': 'Presente de 1 mês de Premium para um amigo\n(Preço normal ₩9.900, 10% desconto)',
    'ru': 'Подарите другу 1 месяц Премиума\n(Обычная цена ₩9 900, скидка 10%)',
    'tr': 'Bir arkadaşına 1 aylık Premium hediye et\n(Normal fiyat ₩9.900, %10 indirim)',
    'ar': 'اهدِ صديقك شهر بريميوم\n(السعر العادي ₩9,900، خصم 10%)',
    'it': 'Regala 1 mese di Premium a un amico\n(Prezzo normale ₩9.900, sconto 10%)',
    'hi': 'दोस्त को 1 महीने का Premium उपहार दें\n(सामान्य मूल्य ₩9,900, 10% छूट)',
    'th': 'ให้ของขวัญ Premium 1 เดือนแก่เพื่อน\n(ราคาปกติ ₩9,900 ลด 10%)',
  });

  String get premiumGiftCodeDesc => _t({
    'ko': '아래 코드를 친구에게 전달하세요.\n친구가 앱에서 코드를 입력하면\n1개월 프리미엄이 활성화돼요.',
    'en': 'Share the code below with your friend.\nWhen they enter it in the app,\n1 month of Premium will be activated.',
    'ja': '下のコードを友達に送ってください。\n友達がアプリでコードを入力すると\n1ヶ月プレミアムが有効になります。',
    'zh': '将下方代码发给朋友。\n朋友在应用中输入代码后\n1个月高级版将被激活。',
    'fr': 'Partagez le code ci-dessous avec votre ami.\nQuand il le saisira dans l\'appli,\n1 mois de Premium sera activé.',
    'de': 'Teilen Sie den Code unten mit Ihrem Freund.\nWenn er ihn in der App eingibt,\nwird 1 Monat Premium aktiviert.',
    'es': 'Comparte el código de abajo con tu amigo.\nCuando lo ingrese en la app,\nse activará 1 mes de Premium.',
    'pt': 'Compartilhe o código abaixo com seu amigo.\nQuando ele inserir no app,\n1 mês de Premium será ativado.',
    'ru': 'Отправьте код ниже другу.\nКогда он введёт его в приложении,\n1 месяц Премиума будет активирован.',
    'tr': 'Aşağıdaki kodu arkadaşınla paylaş.\nUygulamada kodu girdiğinde\n1 aylık Premium aktif olur.',
    'ar': 'شارك الكود أدناه مع صديقك.\nعندما يدخله في التطبيق\nسيتم تفعيل شهر بريميوم.',
    'it': 'Condividi il codice qui sotto con il tuo amico.\nQuando lo inserirà nell\'app,\n1 mese di Premium verrà attivato.',
    'hi': 'नीचे दिया गया कोड अपने दोस्त को भेजें।\nजब वे ऐप में कोड दर्ज करेंगे\nतो 1 महीने का Premium सक्रिय होगा।',
    'th': 'แชร์โค้ดด้านล่างให้เพื่อน\nเมื่อเพื่อนกรอกโค้ดในแอป\nPremium 1 เดือนจะเปิดใช้งาน',
  });

  String get premiumGiftValidity => _t({
    'ko': '유효기간 30일',
    'en': 'Valid for 30 days',
    'ja': '有効期限30日',
    'zh': '有效期30天',
    'fr': 'Valable 30 jours',
    'de': '30 Tage gültig',
    'es': 'Válido por 30 días',
    'pt': 'Válido por 30 dias',
    'ru': 'Действителен 30 дней',
    'tr': '30 gün geçerli',
    'ar': 'صالح لمدة 30 يوم',
    'it': 'Valido per 30 giorni',
    'hi': '30 दिनों के लिए मान्य',
    'th': 'ใช้ได้ 30 วัน',
  });

  String get premiumGiftShareTitle => _t({
    'ko': '프리미엄 선물권',
    'en': 'Premium Gift Card',
    'ja': 'プレミアムギフトカード',
    'zh': '高级版礼品卡',
    'fr': 'Carte cadeau Premium',
    'de': 'Premium-Geschenkkarte',
    'es': 'Tarjeta regalo Premium',
    'pt': 'Cartão presente Premium',
    'ru': 'Подарочная карта Премиум',
    'tr': 'Premium hediye kartı',
    'ar': 'بطاقة هدية بريميوم',
    'it': 'Carta regalo Premium',
    'hi': 'Premium गिफ्ट कार्ड',
    'th': 'บัตรของขวัญ Premium',
  });

  String get premiumGiftShareCode => _t({
    'ko': '코드',
    'en': 'Code',
    'ja': 'コード',
    'zh': '代码',
    'fr': 'Code',
    'de': 'Code',
    'es': 'Código',
    'pt': 'Código',
    'ru': 'Код',
    'tr': 'Kod',
    'ar': 'الكود',
    'it': 'Codice',
    'hi': 'कोड',
    'th': 'โค้ด',
  });

  String get premiumGiftShareBody => _t({
    'ko': '앱에서 코드를 입력하면 1개월 프리미엄이 활성화돼요!\n✉️ 전 세계 혜택으로 인연을 만들어보세요.',
    'en': 'Enter the code in the app to activate 1 month of Premium!\n📣 Connect with people worldwide through rewards.',
    'ja': 'アプリでコードを入力すると1ヶ月プレミアムが有効に！\n✉️ 世界中の人と手紙でつながろう。',
    'zh': '在应用中输入代码即可激活1个月高级版！\n✉️ 通过信件与全世界建立联系。',
    'fr': 'Entrez le code dans l\'appli pour activer 1 mois de Premium !\n✉️ Connectez-vous avec le monde entier par lettres.',
    'de': 'Geben Sie den Code in der App ein, um 1 Monat Premium zu aktivieren!\n✉️ Verbinden Sie sich weltweit durch Briefe.',
    'es': '¡Ingresa el código en la app para activar 1 mes de Premium!\n✉️ Conéctate con personas de todo el mundo a través de cartas.',
    'pt': 'Insira o código no app para ativar 1 mês de Premium!\n✉️ Conecte-se com pessoas do mundo inteiro por cartas.',
    'ru': 'Введите код в приложении, чтобы активировать 1 месяц Премиума!\n✉️ Общайтесь с людьми по всему миру ч��рез письма.',
    'tr': 'Uygulamada kodu girerek 1 aylık Premium aktif edin!\n✉️ Mektuplarla dünya genelinde bağlantı kurun.',
    'ar': 'أدخل الكود في التطبيق لتفعيل شهر بريميوم!\n✉️ تواصل مع أشخاص حول العالم عبر الرسائل.',
    'it': 'Inserisci il codice nell\'app per attivare 1 mese di Premium!\n✉️ Connettiti con persone in tutto il mondo tramite lettere.',
    'hi': 'ऐप में कोड दर्ज करके 1 महीन�� का Premium सक्रिय करें!\n✉️ पत्रों के माध्यम से दुनिया ��र के लोगों से जुड़ें।',
    'th': 'กรอกโค้ดในแอปเพื่อเปิดใช้งาน Premium 1 เดือน!\n✉️ เชื่อมต่อกับผู้คนทั่วโลกผ่านจดหมาย',
  });

  String get premiumShareToFriend => _t({
    'ko': '친구에게 공유하기',
    'en': 'Share with friend',
    'ja': '友達にシェア',
    'zh': '分享给朋友',
    'fr': 'Partager avec un ami',
    'de': 'Mit Freund teilen',
    'es': 'Compartir con amigo',
    'pt': 'Compartilhar com amigo',
    'ru': 'Поделиться с другом',
    'tr': 'Arkadaşla paylaş',
    'ar': 'شارك مع صديق',
    'it': 'Condividi con amico',
    'hi': 'दोस्त के साथ साझा करें',
    'th': 'แชร์ให้เพื่อน',
  });

  String get premiumCodeCopied => _t({
    'ko': '코드가 복사되었어요! 친구에게 전달해 주세요 🎁',
    'en': 'Code copied! Share it with your friend 🎁',
    'ja': 'コードがコピーされました！友達に送ってください 🎁',
    'zh': '代码已复制！请发给朋友 🎁',
    'fr': 'Code copié ! Partagez-le avec votre ami 🎁',
    'de': 'Code kopiert! Teilen Sie ihn mit Ihrem Freund 🎁',
    'es': '¡Código copiado! Compártelo con tu amigo 🎁',
    'pt': 'Código copiado! Compartilhe com seu amigo 🎁',
    'ru': 'Код скопирован! Отправьте его другу 🎁',
    'tr': 'Kod kopyalandı! Arkadaşınla paylaş 🎁',
    'ar': 'تم نسخ الكود! شاركه مع صديقك 🎁',
    'it': 'Codice copiato! Condividilo con il tuo amico 🎁',
    'hi': 'कोड कॉपी हो गया! अपने दोस्त को भेजें 🎁',
    'th': 'คัดลอกโค้ดแล้ว! แชร์ให้เพื่อนเลย 🎁',
  });

  String get premiumCopyCode => _t({
    'ko': '코드만 복사',
    'en': 'Copy code',
    'ja': 'コードをコピー',
    'zh': '仅复制代码',
    'fr': 'Copier le code',
    'de': 'Code kopieren',
    'es': 'Copiar código',
    'pt': 'Copiar código',
    'ru': 'Копировать код',
    'tr': 'Kodu kopyala',
    'ar': 'نسخ الكود',
    'it': 'Copia codice',
    'hi': 'कोड कॉपी करें',
    'th': 'คัดลอกโค้ด',
  });

  String get premiumClose => _t({
    'ko': '닫기',
    'en': 'Close',
    'ja': '閉じる',
    'zh': '关闭',
    'fr': 'Fermer',
    'de': 'Schließen',
    'es': 'Cerrar',
    'pt': 'Fechar',
    'ru': 'Закрыть',
    'tr': 'Kapat',
    'ar': 'إغلاق',
    'it': 'Chiudi',
    'hi': 'बंद करें',
    'th': 'ปิด',
  });

  String get premiumInviteSuccess => _t({
    'ko': '친구 초대 리워드가 지급됐어요! 보너스 5통이 추가되었습니다 🎉',
    'en': 'Invite reward received! 5 bonus credits added 🎉',
    'ja': '友達招待リワード獲得！ボーナス5通が追加されました 🎉',
    'zh': '邀请奖励已发放！已添加5封奖励额度 🎉',
    'fr': 'Récompense d\'invitation reçue ! 5 crédits bonus ajoutés 🎉',
    'de': 'Einladungsbelohnung erhalten! 5 Bonuskredite hinzugefügt 🎉',
    'es': '¡Recompensa de invitación recibida! 5 créditos de bonificación agregados 🎉',
    'pt': 'Recompensa de convite recebida! 5 créditos bônus adicionados 🎉',
    'ru': 'Награда за приглашение получена! Добавлено 5 бонусных кредитов 🎉',
    'tr': 'Davet ödülü alındı! 5 bonus kredi eklendi 🎉',
    'ar': 'تم استلام مكافأة الدعوة! تمت إضافة 5 رصيد إضافي 🎉',
    'it': 'Premio invito ricevuto! 5 crediti bonus aggiunti 🎉',
    'hi': 'आमंत्रण पुरस्कार प्राप्त! 5 बोनस क्रेडिट जोड़े गए 🎉',
    'th': 'ได้รับรางวัลเชิญเพื่อนแล้ว! เพิ่มโบนัส 5 เครดิต 🎉',
  });

  String get premiumInviteSelf => _t({
    'ko': '내 초대 코드는 직접 입력할 수 없어요.',
    'en': 'You cannot use your own invite code.',
    'ja': '自分の招待コードは入力できません。',
    'zh': '不能使用自己的邀请码。',
    'fr': 'Vous ne pouvez pas utiliser votre propre code d\'invitation.',
    'de': 'Sie können Ihren eigenen Einladungscode nicht verwenden.',
    'es': 'No puedes usar tu propio código de invitación.',
    'pt': 'Você não pode usar seu próprio código de convite.',
    'ru': 'Нельзя использовать свой собственный код приглашения.',
    'tr': 'Kendi davet kodunuzu kullanamazsınız.',
    'ar': 'لا يمكنك استخدام كود الدعوة الخاص بك.',
    'it': 'Non puoi usare il tuo codice invito.',
    'hi': 'आप अपना आमंत्रण कोड उपयोग नहीं कर सकते।',
    'th': 'ไม่สามารถใช้โค้ดเชิญของตัวเองได้',
  });

  String get premiumInviteAlreadyUsed => _t({
    'ko': '초대 코드는 계정당 1회만 사용할 수 있어요.',
    'en': 'Invite code can only be used once per account.',
    'ja': '招待コードはアカウントごと���1回のみ使用できます。',
    'zh': '邀请码每个账户只能使用一次。',
    'fr': 'Le code d\'invitation ne peut être utilisé qu\'une fois par compte.',
    'de': 'Der Einladungscode kann nur einmal pro Konto verwendet werden.',
    'es': 'El código de invitación solo se puede usar una vez por cuenta.',
    'pt': 'O código de convite só pode ser usado uma vez por conta.',
    'ru': 'Код приглашения можно использовать только один раз на аккаунт.',
    'tr': 'Davet kodu hesap başına yalnızca bir kez kullanılabilir.',
    'ar': 'يمكن استخدام كود الدعوة مرة واحدة فقط لكل حساب.',
    'it': 'Il codice invito può essere usato una sola volta per account.',
    'hi': 'आमंत्रण कोड प्रति खाता केवल एक बार उपयोग किया जा सकता है।',
    'th': 'โค้ดเชิญใช้ได้เพียงครั้งเดียวต่อบัญชี',
  });

  String get premiumInviteInvalid => _t({
    'ko': '코드 형식을 확인해주세요. (영문/숫자 6자리)',
    'en': 'Please check the code format. (6 alphanumeric characters)',
    'ja': 'コード形式を確認してください。（英数���6桁）',
    'zh': '请检查代码格式。（6位字母数字）',
    'fr': 'Veuillez vérifier le format du code. (6 caractères alphanumériques)',
    'de': 'Bitte überprüfen Sie das Code-Format. (6 alphanumerische Zeichen)',
    'es': 'Verifique el formato del código. (6 caracteres alfanuméricos)',
    'pt': 'Verifique o formato do código. (6 caracteres alfanuméricos)',
    'ru': 'Проверьте формат кода. (6 буквенно-цифровых символов)',
    'tr': 'Lütfen kod formatını kontrol edin. (6 alfanumerik karakter)',
    'ar': 'يرجى التحقق من صيغة الكود. (6 أحرف وأرقام)',
    'it': 'Controlla il formato del codice. (6 caratteri alfanumerici)',
    'hi': 'कृपया कोड प्रारूप जांचें। (6 अक्षर/अंक)',
    'th': 'กรุณาตรวจสอบรูปแบบโค้ด (ต��วอักษร/ตัวเลข 6 หลัก)',
  });

  String get premiumInviteServerUnavailable => _t({
    'ko': '서버 연결이 필요해요. 로그인/Firebase 설정을 확인해주세요.',
    'en': 'Server connection required. Please check your login/Firebase settings.',
    'ja': 'サーバー接続が必要です。ログイン/Firebase設定を確認してください。',
    'zh': '需要服务器连接。请检查登录/Firebase设置。',
    'fr': 'Connexion au serveur requise. Vérifiez vos paramètres de connexion/Firebase.',
    'de': 'Serververbindung erforderlich. Bitte überprüfen Sie Ihre Login-/Firebase-Einstellungen.',
    'es': 'Se requiere conexión al servidor. Verifique su configuración de inicio de sesión/Firebase.',
    'pt': 'Conexão com servidor necessária. Verifique suas configurações de login/Firebase.',
    'ru': 'Требуется подключение к серверу. Проверьте настройки входа/Firebase.',
    'tr': 'Sunucu bağlantısı gerekli. Giriş/Firebase ayarlarınızı kontrol edin.',
    'ar': 'مطلوب اتصال بالخادم. يرجى التحقق من إعدادات تسجيل الدخول/Firebase.',
    'it': 'Connessione al server necessaria. Controlla le impostazioni di login/Firebase.',
    'hi': 'सर्वर कनेक्शन आवश्यक। कृपया लॉगिन/Firebase सेटिंग्स जांचें।',
    'th': 'ต้องเชื่อมต่อเซิร์ฟเวอร์ กรุณาตรวจสอบการล็อกอิน/ตั้งค่า Firebase',
  });

  String get premiumInviteNetworkError => _t({
    'ko': '서버 검증 중 오류가 발생했어요. 잠시 후 다시 시도해주세요.',
    'en': 'Server verification error. Please try again later.',
    'ja': 'サーバー検証中にエラーが発生しました。しばらくしてからお試しください。',
    'zh': '服务器验证出错。请稍后重试。',
    'fr': 'Erreur de vérification du serveur. Veuillez réessayer plus tard.',
    'de': 'Serverüberprüfungsfehler. Bitte versuchen Sie es später erneut.',
    'es': 'Error de verificación del servidor. Inténtelo de nuevo más tarde.',
    'pt': 'Erro de verificação do servidor. Tente novamente mais tarde.',
    'ru': 'Ошибка проверки сервера. Попробуйте позже.',
    'tr': 'Sunucu doğrulama hatası. Lütfen daha sonra tekrar deneyin.',
    'ar': 'خطأ في التحقق من الخادم. يرجى المحاولة لاحقاً.',
    'it': 'Errore di verifica del server. Riprova più tardi.',
    'hi': 'सर्वर सत्यापन त्रुटि। कृपया बाद में पुनः प्रयास करें।',
    'th': 'เกิดข้อผิดพลาดในการตรวจสอบเซิร์ฟเวอร์ กรุณาลองใหม่ภายหลัง',
  });

  String get premiumInviteRewardTitle => _t({
    'ko': '친구 초대 시 보너스 발송권 지급',
    'en': 'Bonus credits for inviting friends',
    'ja': '友達招待でボーナス送信権獲得',
    'zh': '邀请好友获得奖励发送额度',
    'fr': 'Crédits bonus pour invitation d\'amis',
    'de': 'Bonuskredite für Freundeseinladungen',
    'es': 'Créditos de bonificación por invitar amigos',
    'pt': 'Créditos bônus por convidar amigos',
    'ru': 'Бонусные кредиты за приглашение друзей',
    'tr': 'Arkadaş davet etme bonusu',
    'ar': 'رصيد إضافي لدعوة الأصدقاء',
    'it': 'Crediti bonus per invitare amici',
    'hi': 'मित्रों को आमंत्रित करने पर बोनस क्रेडिट',
    'th': 'เครดิตโบนัสสำหรับเชิญเพื่อน',
  });

  String get premiumInviteCreditsOwned => _t({
    'ko': '보유',
    'en': 'Owned:',
    'ja': '保有',
    'zh': '拥有',
    'fr': 'Possédés :',
    'de': 'Besitz:',
    'es': 'Posesión:',
    'pt': 'Possuídos:',
    'ru': 'На счету:',
    'tr': 'Sahip:',
    'ar': 'الرصيد:',
    'it': 'Posseduti:',
    'hi': 'स्वामित्व:',
    'th': 'มี:',
  });

  String get premiumInviteOncePerAccount => _t({
    'ko': '코드 적용은 서버 검증 후 지급됩니다. (계정당 1회)',
    'en': 'Code verification is done server-side. (Once per account)',
    'ja': 'コード適用はサーバー検証後に付与されます。（アカウントごとに1回）',
    'zh': '代码验证后由服务器发放。（每账户1次）',
    'fr': 'La vérification du code se fait côté serveur. (Une fois par compte)',
    'de': 'Code-Überprüfung erfolgt serverseitig. (Einmal pro Konto)',
    'es': 'La verificación del código se realiza en el servidor. (Una vez por cuenta)',
    'pt': 'A verificação do código é feita pelo servidor. (Uma vez por conta)',
    'ru': 'Проверка кода выполняется на сервере. (Один раз на аккаунт)',
    'tr': 'Kod doğrulama sunucu tarafında yapılır. (Hesap başına bir kez)',
    'ar': 'يتم التحقق من الكود من جهة الخادم. (مرة واحدة لكل حساب)',
    'it': 'La verifica del codice avviene lato server. (Una volta per account)',
    'hi': 'कोड सत्यापन सर्वर-साइड होता ह���। (प्रति खाता एक बार)',
    'th': 'การตรวจสอบโค้ดทำที่เซิร์ฟเวอร์ (ครั้งเดียวต่อบัญชี)',
  });

  String get premiumMyInviteCode => _t({
    'ko': '내 초대 코드',
    'en': 'My invite code',
    'ja': 'マイ招待コード',
    'zh': '我的邀请码',
    'fr': 'Mon code d\'invitation',
    'de': 'Mein Einladungscode',
    'es': 'Mi código de invitación',
    'pt': 'Meu código de convite',
    'ru': 'Мой код приглашения',
    'tr': 'Davet kodum',
    'ar': 'كود الدعوة الخاص بي',
    'it': 'Il mio codice invito',
    'hi': 'मेरा आमंत्रण कोड',
    'th': 'โค้ดเชิญของฉัน',
  });

  String get premiumInviteCodeCopied => _t({
    'ko': '초대 코드가 복사되었어요.',
    'en': 'Invite code copied.',
    'ja': '招待コードがコピーされました。',
    'zh': '邀请码已复制。',
    'fr': 'Code d\'invitation copié.',
    'de': 'Einladungscode kopiert.',
    'es': 'Código de invitación copiado.',
    'pt': 'Código de convite copiado.',
    'ru': 'Код приглашения скопирован.',
    'tr': 'Davet kodu kopyalandı.',
    'ar': 'تم نسخ كود الدعوة.',
    'it': 'Codice invito copiato.',
    'hi': 'आमंत्रण कोड कॉपी किया गया।',
    'th': 'คัดลอกโค้ดเชิญแล้ว',
  });

  String get premiumCopy => _t({
    'ko': '복사',
    'en': 'Copy',
    'ja': 'コピー',
    'zh': '复制',
    'fr': 'Copier',
    'de': 'Kopieren',
    'es': 'Copiar',
    'pt': 'Copiar',
    'ru': 'Копировать',
    'tr': 'Kopyala',
    'ar': 'نسخ',
    'it': 'Copia',
    'hi': 'कॉपी',
    'th': 'คัดลอก',
  });

  String get premiumShare => _t({
    'ko': '공유',
    'en': 'Share',
    'ja': 'シェア',
    'zh': '分享',
    'fr': 'Partager',
    'de': 'Teilen',
    'es': 'Compartir',
    'pt': 'Compartilhar',
    'ru': 'Поделиться',
    'tr': 'Paylaş',
    'ar': 'مشاركة',
    'it': 'Condividi',
    'hi': 'साझा करें',
    'th': 'แชร์',
  });

  String get premiumInviteShareTagline => _t({
    'ko': '전 세계와 혜택으로 연결되는 앱',
    'en': 'Connect with the world through rewards',
    'ja': '世界中と手紙でつながるアプリ',
    'zh': '通过信件与全世界连接的应用',
    'fr': 'L\'appli qui vous connecte au monde par lettres',
    'de': 'Die App, die dich per Brief mit der Welt verbindet',
    'es': 'La app que te conecta con el mundo por cartas',
    'pt': 'O app que conecta você ao mundo por cartas',
    'ru': 'Приложение, соединяющее вас с миром через письма',
    'tr': 'Mektuplarla dünyayla bağlantı kuran uygulama',
    'ar': 'التطبيق الذي يربطك بالعالم عبر الرسائل',
    'it': 'L\'app che ti connette al mondo tramite lettere',
    'hi': 'पत्रों के माध्यम से दुनिया से जुड़ने वाला ऐप',
    'th': 'แอปที่เชื่อมคุณกับโลกผ่านจดหมาย',
  });

  String get premiumInviteShareBody => _t({
    'ko': '코드 입력하면 보너스 발송권 지급!\n지도 위 혜택이 실시간으로 여행하고,\n낯선 이에게 닿는 특별한 경험을 해보세요 🌍',
    'en': 'Enter the code to get bonus credits!\nWatch rewards travel across the map in real time\nand reach someone special 🌍',
    'ja': 'コードを入力してボーナス送信権をゲット！\n地図上を手紙がリアルタイムで旅し、\n見知らぬ人に届く特別な体験を 🌍',
    'zh': '输入代码获取奖励额度！\n观看信件在地图上实时旅行\n到达陌生人的特别体验 🌍',
    'fr': 'Entrez le code pour obtenir des crédits bonus !\nRegardez les lettres voyager sur la carte en temps réel\net atteindre quelqu\'un de spécial 🌍',
    'de': 'Geben Sie den Code ein, um Bonuskredite zu erhalten!\nSehen Sie Briefe in Echtzeit über die Karte reisen\nund jemand Besonderen erreichen 🌍',
    'es': '¡Ingresa el código para obtener créditos bonus!\nMira las cartas viajar por el mapa en tiempo real\ny llegar a alguien especial 🌍',
    'pt': 'Insira o código para ganhar créditos bônus!\nVeja cartas viajando pelo mapa em tempo real\ne alcançando alguém especial 🌍',
    'ru': 'Введите код и получите бонусные кредиты!\nСмотрите, как письма путешествуют по карте в реальном времени\nи достигают кого-то особенного 🌍',
    'tr': 'Kodu girerek bonus kredi kazan!\nMektupların haritada gerçek zamanlı yolculuğunu izle\nve özel birine ulaş 🌍',
    'ar': 'أدخل الكود للحصول على رصيد إضافي!\nشاهد الرسائل تسافر عبر الخريطة في الوقت الحقيقي\nوتصل لشخص مميز 🌍',
    'it': 'Inserisci il codice per ottenere crediti bonus!\nGuarda le lettere viaggiare sulla mappa in tempo reale\ne raggiungere qualcuno di speciale 🌍',
    'hi': 'बोनस क्रेडिट पाने के लिए कोड दर्ज करें!\nमानचित्र पर पत्रों की वास्तविक समय यात्रा देखें\nऔर किसी विशेष व्यक्ति तक पहुंचें 🌍',
    'th': 'กรอกโค้ดเพื่อรับเครดิตโบนัส!\nดูจดหมายเดินทางบนแ��นที่แบบเรียลไทม์\nและไปถึงคนพิเศษ 🌍',
  });

  String get premiumInviteShareSubject => _t({
    'ko': '초대장',
    'en': 'Invitation',
    'ja': '招待状',
    'zh': '邀请函',
    'fr': 'Invitation',
    'de': 'Einladung',
    'es': 'Invitación',
    'pt': 'Convite',
    'ru': 'Приглашение',
    'tr': 'Davetiye',
    'ar': 'دعوة',
    'it': 'Invito',
    'hi': 'आमंत्रण',
    'th': 'คำเชิญ',
  });

  String get premiumInviteCodeHint => _t({
    'ko': '친구 초대 코드 입력 (예: A1B2C3)',
    'en': 'Enter invite code (e.g. A1B2C3)',
    'ja': '友達招待コードを入力（例：A1B2C3）',
    'zh': '输入邀请码（例：A1B2C3）',
    'fr': 'Entrez le code d\'invitation (ex : A1B2C3)',
    'de': 'Einladungscode eingeben (z.B. A1B2C3)',
    'es': 'Ingrese código de invitación (ej: A1B2C3)',
    'pt': 'Insira o código de convite (ex: A1B2C3)',
    'ru': 'Введите код приглашения (напр. A1B2C3)',
    'tr': 'Davet kodu girin (ör: A1B2C3)',
    'ar': 'أدخل كود الدعوة (مثال: A1B2C3)',
    'it': 'Inserisci codice invito (es. A1B2C3)',
    'hi': 'आमंत्रण कोड दर्ज करें (उदा: A1B2C3)',
    'th': 'กรอกโค้ดเชิญ (เช่น A1B2C3)',
  });

  String get premiumApplyInviteCode => _t({
    'ko': '초대 코드 적용',
    'en': 'Apply invite code',
    'ja': '招待コードを適用',
    'zh': '应用邀请码',
    'fr': 'Appliquer le code d\'invitation',
    'de': 'Einladungscode anwenden',
    'es': 'Aplicar código de invitación',
    'pt': 'Aplicar código de convite',
    'ru': 'Применить код приглашения',
    'tr': 'Davet kodunu uygula',
    'ar': 'تطبيق كود الدعوة',
    'it': 'Applica codice invito',
    'hi': 'आमंत्रण कोड लागू करें',
    'th': 'ใช้โค้ดเชิญ',
  });

  // ── Feature compare table ──

  String get premiumCompareFeature => _t({
    'ko': '기능', 'en': 'Feature', 'ja': '機能', 'zh': '功能',
    'fr': 'Fonction', 'de': 'Funktion', 'es': 'Función', 'pt': 'Função',
    'ru': 'Функция', 'tr': 'Özellik', 'ar': 'الميزة', 'it': 'Funzione',
    'hi': 'सुविधा', 'th': 'ฟีเจอร์',
  });

  String get premiumCompareDailyLetters => _t({
    'ko': '일일 혜택', 'en': 'Daily rewards', 'ja': '日次手紙', 'zh': '每日信件',
    'fr': 'Lettres/jour', 'de': 'Tägliche Briefe', 'es': 'Cartas diarias', 'pt': 'Cartas diárias',
    'ru': 'Писем/день', 'tr': 'Günlük mektup', 'ar': 'رسائل يومية', 'it': 'Lettere/giorno',
    'hi': 'दैनिक पत्र', 'th': 'จดหมายรายวัน',
  });

  String get premiumCompareMonthlyLetters => _t({
    'ko': '월 혜택', 'en': 'Monthly rewards', 'ja': '月次手紙', 'zh': '每月信件',
    'fr': 'Lettres/mois', 'de': 'Monatliche Briefe', 'es': 'Cartas mensuales', 'pt': 'Cartas mensais',
    'ru': 'Писем/месяц', 'tr': 'Aylık mektup', 'ar': 'رسائل شهرية', 'it': 'Lettere/mese',
    'hi': 'मासिक पत्र', 'th': 'จดหมายรายเดือน',
  });

  String get premiumCompareImageLink => _t({
    'ko': '이미지+링크', 'en': 'Image+Link', 'ja': '画像+リンク', 'zh': '图片+链接',
    'fr': 'Image+Lien', 'de': 'Bild+Link', 'es': 'Imagen+Enlace', 'pt': 'Imagem+Link',
    'ru': 'Фото+Ссылка', 'tr': 'Resim+Link', 'ar': 'صورة+رابط', 'it': 'Immagine+Link',
    'hi': 'छवि+लिंक', 'th': 'ภาพ+ลิงก์',
  });

  String get premiumCompare20PerDay => _t({
    'ko': '1일 20통', 'en': '20/day', 'ja': '1日20通', 'zh': '每日20封',
    'fr': '20/jour', 'de': '20/Tag', 'es': '20/día', 'pt': '20/dia',
    'ru': '20/день', 'tr': 'Günde 20', 'ar': '20/يوم', 'it': '20/giorno',
    'hi': '20/दिन', 'th': '20/วัน',
  });

  String get premiumCompareAllIncluded => _t({
    'ko': '전부 포함', 'en': 'All included', 'ja': '全て含む', 'zh': '全部包含',
    'fr': 'Tout inclus', 'de': 'Alles inklusive', 'es': 'Todo incluido', 'pt': 'Tudo incluído',
    'ru': 'Всё включено', 'tr': 'Hepsi dahil', 'ar': 'الكل مشمول', 'it': 'Tutto incluso',
    'hi': 'सभी शामिल', 'th': 'รวมทั้งหมด',
  });

  String get premiumCompareExpress => _t({
    'ko': '특급 배송', 'en': 'Express delivery', 'ja': '特急配送', 'zh': '特快配送',
    'fr': 'Livraison express', 'de': 'Express-Zustellung', 'es': 'Entrega exprés', 'pt': 'Entrega expressa',
    'ru': 'Экспресс-доставка', 'tr': 'Ekspres teslimat', 'ar': 'توصيل سريع', 'it': 'Consegna espressa',
    'hi': 'एक्सप्रेस डिलीवरी', 'th': 'จัดส่งด่วน',
  });

  String get premiumCompare3PerDay => _t({
    'ko': '1일 3통', 'en': '3/day', 'ja': '1日3通', 'zh': '每日3封',
    'fr': '3/jour', 'de': '3/Tag', 'es': '3/día', 'pt': '3/dia',
    'ru': '3/день', 'tr': 'Günde 3', 'ar': '3/يوم', 'it': '3/giorno',
    'hi': '3/दिन', 'th': '3/วัน',
  });

  String get premiumCompareInstantBulk => _t({
    'ko': '5분 즉시·대량', 'en': '5min instant·bulk', 'ja': '5分即時·大量', 'zh': '5分钟即时·批量',
    'fr': '5min instant·masse', 'de': '5Min sofort·Masse', 'es': '5min instant·masivo', 'pt': '5min instant·massa',
    'ru': '5мин мгновенно·массово', 'tr': '5dk anında·toplu', 'ar': '5د فوري·جماعي', 'it': '5min istantaneo·massa',
    'hi': '5मिनट तुरंत·बल्क', 'th': '5นาที ทันที·จำนวนมาก',
  });

  String get premiumCompareStyle => _t({
    'ko': '혜택 스타일', 'en': 'Reward style', 'ja': '手紙スタイル', 'zh': '信件样式',
    'fr': 'Style de lettre', 'de': 'Briefstil', 'es': 'Estilo de carta', 'pt': 'Estilo de carta',
    'ru': 'Стиль письма', 'tr': 'Mektup stili', 'ar': 'نمط الرسالة', 'it': 'Stile lettera',
    'hi': 'पत्र शैली', 'th': 'สไตล์จดหมาย',
  });

  String get premiumCompareBasic => _t({
    'ko': '기본', 'en': 'Basic', 'ja': '基本', 'zh': '基本',
    'fr': 'Basique', 'de': 'Basis', 'es': 'Básico', 'pt': 'Básico',
    'ru': 'Базовый', 'tr': 'Temel', 'ar': 'أساسي', 'it': 'Base',
    'hi': 'बुनियादी', 'th': 'พื้นฐาน',
  });

  String get premiumCompareSpecial => _t({
    'ko': '특별', 'en': 'Special', 'ja': '特別', 'zh': '特别',
    'fr': 'Spécial', 'de': 'Speziell', 'es': 'Especial', 'pt': 'Especial',
    'ru': 'Особый', 'tr': 'Özel', 'ar': 'خاص', 'it': 'Speciale',
    'hi': 'विशेष', 'th': 'พิเศษ',
  });

  String get premiumCompareBrand => _t({
    'ko': '브랜드', 'en': 'Brand', 'ja': 'ブランド', 'zh': '品牌',
    'fr': 'Marque', 'de': 'Marke', 'es': 'Marca', 'pt': 'Marca',
    'ru': 'Бренд', 'tr': 'Marka', 'ar': 'علامة تجارية', 'it': 'Brand',
    'hi': 'ब्रांड', 'th': 'แบรนด์',
  });

  String get premiumCompareBulkSend => _t({
    'ko': '대량 발송', 'en': 'Bulk send', 'ja': '大量送信', 'zh': '批量发送',
    'fr': 'Envoi en masse', 'de': 'Massenversand', 'es': 'Envío masivo', 'pt': 'Envio em massa',
    'ru': 'Массовая рассылка', 'tr': 'Toplu gönderim', 'ar': 'إرسال ��ماعي', 'it': 'Invio in massa',
    'hi': '���ल्क भेजें', 'th': 'ส่งจำนวนมาก',
  });

  // Build 185: 비교표 행 이름에서 타워 표현 제거. 레터 커스터마이즈로 통일.
  String get premiumCompareTowerCustom => _t({
    'ko': '커스터마이즈', 'en': 'Customize', 'ja': 'カスタマイズ', 'zh': '自定义',
    'fr': 'Personnaliser', 'de': 'Anpassung', 'es': 'Personalización', 'pt': 'Personalizar',
    'ru': 'Кастомизация', 'tr': 'Özelleştirme', 'ar': 'تخصيص', 'it': 'Personalizzazione',
    'hi': 'कस्टमाइज़', 'th': 'ปรับแต่ง',
  });

  String get premiumCompareBadge => _t({
    'ko': '인증 배지', 'en': 'Verified badge', 'ja': '認証バッジ', 'zh': '认证徽章',
    'fr': 'Badge vérifié', 'de': 'Verifizierungsabzeichen', 'es': 'Insignia verificada', 'pt': 'Selo verificado',
    'ru': 'Значок верификации', 'tr': 'Doğrulama rozeti', 'ar': 'شارة التحقق', 'it': 'Badge verificato',
    'hi': 'सत्यापित बैज', 'th': 'เครื่องหมายยืนยัน',
  });

  String get premiumCompareReportBtn => _t({
    'ko': '신고 버튼', 'en': 'Report button', 'ja': '通報ボタン', 'zh': '举报按钮',
    'fr': 'Bouton signaler', 'de': 'Melden-Button', 'es': 'Botón reportar', 'pt': 'Botão denunciar',
    'ru': 'Кнопка жалобы', 'tr': 'Şikayet butonu', 'ar': 'زر البلاغ', 'it': 'Pulsante segnala',
    'hi': 'रिपोर्ट बटन', 'th': 'ปุ่มรายงาน',
  });

  String get premiumCompareShown => _t({
    'ko': '표시', 'en': 'Shown', 'ja': '表示', 'zh': '显示',
    'fr': 'Affiché', 'de': 'Angezeigt', 'es': 'Mostrado', 'pt': 'Exibido',
    'ru': 'Показано', 'tr': 'Gösterilir', 'ar': 'معروض', 'it': 'Mostrato',
    'hi': 'दिखाया गया', 'th': 'แสดง',
  });

  String get premiumCompareHidden => _t({
    'ko': '미표시', 'en': 'Hidden', 'ja': '非表示', 'zh': '隐藏',
    'fr': 'Masqué', 'de': 'Versteckt', 'es': 'Oculto', 'pt': 'Oculto',
    'ru': 'Скрыто', 'tr': 'Gizli', 'ar': 'مخفي', 'it': 'Nascosto',
    'hi': 'छिपा हुआ', 'th': 'ซ่อน',
  });

  String get premiumCompareMonthlyPrice => _t({
    'ko': '월 가격', 'en': 'Monthly price', 'ja': '月額', 'zh': '月价格',
    'fr': 'Prix mensuel', 'de': 'Monatspreis', 'es': 'Precio mensual', 'pt': 'Preço mensal',
    'ru': 'Цена/месяц', 'tr': 'Aylık fiyat', 'ar': 'السعر الشهري', 'it': 'Prezzo mensile',
    'hi': 'मासिक मूल्य', 'th': 'ราคารายเดือน',
  });

  String get premiumCompareFree => _t({
    'ko': '무료', 'en': 'Free', 'ja': '無料', 'zh': '免费',
    'fr': 'Gratuit', 'de': 'Kostenlos', 'es': 'Gratis', 'pt': 'Grátis',
    'ru': 'Бесплатно', 'tr': 'Ücretsiz', 'ar': 'مجاني', 'it': 'Gratuito',
    'hi': 'मुफ्त', 'th': 'ฟรี',
  });

  // ── Downgrade section ──

  String get premiumDowngradeDialogBody => _t({
    'ko': '플랜을 무료로 변경하면:\n• 현재 결제 기간 종료 후 무료로 전환됩니다\n• 다음 결제일부터 요금이 청구되지 않아요\n• 현재 기간 동안은 모든 기능을 계속 이용하실 수 있어요',
    'en': 'If you switch to the Free plan:\n• You will switch to Free after the current billing period\n• No charges from the next billing date\n• You can continue using all features during the current period',
    'ja': '無料プランに変更すると：\n• 現在の決済期間終了後に無料に変更されます\n• 次の決済日から料金は発生しません\n• 現在の期間中は全機能をご利用いただけます',
    'zh': '切换到免费���案后：\n• 当前付费期结束后切换为免费\n• 下一个付款日起不再收费\n• 当前期间内可继续使用所有功能',
    'fr': 'Si vous passez au forfait gratuit :\n• Vous passerez en gratuit après la période de facturation actuelle\n• Aucun frais à partir de la prochaine date de facturation\n• Vous pouvez continuer à utiliser toutes les fonctions pendant la période actuelle',
    'de': 'Wenn Sie zum kostenlosen Plan wechseln:\n• Sie wechseln nach dem aktuellen Abrechnungszeitraum zu Kostenlos\n• Keine Gebühren ab dem nächsten Abrechnungsdatum\n• Sie können alle Funktionen während des aktuellen Zeitraums weiter nutzen',
    'es': 'Si cambia al plan gratuito:\n• Cambiará a Gratis después del período de facturación actual\n• Sin cargos desde la próxima fecha de facturación\n• Puede seguir usando todas las funciones durante el período actual',
    'pt': 'Se mudar para o plano gratuito:\n• Mudará para Grátis após o período de cobrança atual\n• Sem cobranças a partir da próxima data de cobrança\n• Pode continuar usando todas as funções durante o período atual',
    'ru': 'При переходе на бесплатный план:\n• Переход произойдёт после текущего периода оплаты\n• Со следующей даты оплаты средства списываться не будут\n• До конца текущего периода все функции доступны',
    'tr': 'Ücretsiz plana geçerseniz:\n• Mevcut fatura döneminden sonra ücretsiz olacaksınız\n• Sonraki fatura tarihinden itibaren ücret alınmaz\n• Mevcut dönem boyunca tüm özellikleri kullanmaya devam edebilirsiniz',
    'ar': 'عند التبديل إلى الخطة المجانية:\n• ستنتقل إلى المجانية بعد فترة الفوترة الحالية\n• لن يتم ت��صيل رسوم من تاريخ الفوترة التالي\n• يمكنك الاستمرار في استخدام جميع الميزات خلال الفترة الحالية',
    'it': 'Se passi al piano gratuito:\n• Passerai a Gratuito dopo il periodo di fatturazione attuale\n• Nessun addebito dalla prossima data di fatturazione\n• Puoi continuare a usare tutte le funzioni durante il periodo attuale',
    'hi': 'यदि आप मुफ्त योजना पर स्विच करते हैं:\n• वर्तमान बिलिंग अवधि के बाद मुफ्त में बदलेंगे\n• अगली बिलिंग तिथि से कोई शुल्क नहीं\n• वर्तमान अवधि के दौरान सभी सुविधाओं का उपयोग जारी रख सकते हैं',
    'th': 'หากเปลี่ยนเป็นแพ็กเกจฟรี:\n• จะเปลี่ยนเป็นฟรีหลังสิ้นสุดรอบบิลปัจจุบัน\n• ไม่เรียกเก็บเงินตั้งแต่วันบิลถัดไป\n• ยังใช้งานฟีเจอร์ทั้งหมดได้ในรอบปัจจุบัน',
  });

  String get premiumDowngradeNextBilling => _t({
    'ko': '다음 결제일부터 무료 플랜으로 전환됩니다',
    'en': 'You will switch to the Free plan from the next billing date',
    'ja': '次の決済日から無料プランに変更されます',
    'zh': '将从下一个付款日起切换到免费方案',
    'fr': 'Vous passerez au forfait gratuit à la prochaine date de facturation',
    'de': 'Sie wechseln ab dem nächsten Abrechnungsdatum zum kostenlosen Plan',
    'es': 'Cambiará al plan gratuito desde la próxima fecha de facturación',
    'pt': 'Você mudará para o plano gratuito a partir da próxima data de cobrança',
    'ru': 'Вы перейдёте на бесплатный план со следующей даты оплаты',
    'tr': 'Bir sonraki fatura tarihinden itibaren ücretsiz plana geçeceksiniz',
    'ar': 'ستنتقل إلى الخطة المجانية من تاريخ الفوترة التالي',
    'it': 'Passerai al piano gratuito dalla prossima data di fatturazione',
    'hi': 'अगली बिलिंग तिथि से मुफ्त योजना पर स्विच ��ोगा',
    'th': 'จะเปลี่ยนเป็นแพ็กเกจฟรีตั้งแต่วันบิลถัดไป',
  });

  // ── Pending plan change ──

  String get premiumPendingFreeChange => _t({
    'ko': '무료 플랜 전환 예정', 'en': 'Free plan change scheduled', 'ja': '無料プラン変更予定', 'zh': '免费方案切换预定',
    'fr': 'Passage au gratuit prévu', 'de': 'Wechsel zu Kostenlos geplant', 'es': 'Cambio a gratuito programado', 'pt': 'Mudança para gratuito agendada',
    'ru': 'Запланирован переход на бесплатный', 'tr': 'Ücretsiz plana geçiş planlandı', 'ar': 'مقرر التبديل إلى المجانية', 'it': 'Passaggio a gratuito previsto',
    'hi': 'मुफ्त योजना बदलाव निर्धारि��', 'th': 'กำหนดเปลี่ยนเป็นแพ็กเกจฟรี',
  });

  String get premiumPendingBrandChange => _t({
    'ko': 'Brand / Creator 변경 예정', 'en': 'Brand / Creator change scheduled', 'ja': 'Brand / Creator変更予定', 'zh': 'Brand / Creator 切换预定',
    'fr': 'Passage à Brand / Creator prévu', 'de': 'Wechsel zu Brand / Creator geplant', 'es': 'Cambio a Brand / Creator programado', 'pt': 'Mudança para Brand / Creator agendada',
    'ru': 'Запланирован переход на Brand / Creator', 'tr': 'Brand / Creator geçişi planlandı', 'ar': 'مقرر التبديل إلى Brand / Creator', 'it': 'Passaggio a Brand / Creator previsto',
    'hi': 'Brand / Creator बदलाव निर्धारित', 'th': 'กำหนดเปลี่ยนเป็น Brand / Creator',
  });

  String get premiumPendingFreeAfter => _t({
    'ko': '이후 무료로 변경됩니다', 'en': 'will switch to Free', 'ja': '以降無料に変更されます', 'zh': '之后切换为免费',
    'fr': 'passage au gratuit', 'de': 'Wechsel zu Kostenlos', 'es': 'cambio a gratuito', 'pt': 'mudança para gratuito',
    'ru': 'переход на бесплатный', 'tr': 'ücretsiz plana geçilecek', 'ar': 'سيتم التبديل إلى المجانية', 'it': 'passaggio a gratuito',
    'hi': 'मुफ्त में बदलेंगे', 'th': 'จะเปลี่ยนเป็นฟรี',
  });

  String get premiumPendingBrandAfter => _t({
    'ko': '이후 Brand / Creator로 변경됩니다', 'en': 'will switch to Brand / Creator', 'ja': '以降Brand / Creatorに変更されます', 'zh': '之后切换为Brand / Creator',
    'fr': 'passage à Brand / Creator', 'de': 'Wechsel zu Brand / Creator', 'es': 'cambio a Brand / Creator', 'pt': 'mudança para Brand / Creator',
    'ru': 'переход на Brand / Creator', 'tr': 'Brand / Creator\'a geçilecek', 'ar': 'سيتم التبديل إلى Brand / Creator', 'it': 'passaggio a Brand / Creator',
    'hi': 'Brand / Creator में बदलेंगे', 'th': 'จะเปลี่ยนเป็น Brand / Creator',
  });

  // ── Brand extra tile ──

  String get premiumQuotaMonthlyLimit => _t({
    'ko': '이번 달 한도', 'en': 'Monthly limit', 'ja': '今月の上限', 'zh': '本月额度',
    'fr': 'Limite mensuelle', 'de': 'Monatslimit', 'es': 'Límite mensual', 'pt': 'Limite mensal',
    'ru': 'Лимит за месяц', 'tr': 'Aylık limit', 'ar': 'حد الشهر', 'it': 'Limite mensile',
    'hi': 'मासिक सीमा', 'th': 'โควต้าเดือนนี้',
  });

  String get premiumQuotaBase => _t({
    'ko': '기본', 'en': 'Base', 'ja': '基本', 'zh': '基本',
    'fr': 'Base', 'de': 'Basis', 'es': 'Base', 'pt': 'Base',
    'ru': 'Базовый', 'tr': 'Temel', 'ar': 'أساسي', 'it': 'Base',
    'hi': 'आधार', 'th': 'พื้นฐาน',
  });

  String get premiumQuotaExtra => _t({
    'ko': '추가', 'en': 'Extra', 'ja': '追加', 'zh': '额外',
    'fr': 'Extra', 'de': 'Extra', 'es': 'Extra', 'pt': 'Extra',
    'ru': 'Доп.', 'tr': 'Ek', 'ar': 'إضافي', 'it': 'Extra',
    'hi': 'अतिरिक्त', 'th': 'เพิ่มเติม',
  });

  String get premiumQuotaBaseLimit => _t({
    'ko': '기본 한도', 'en': 'Base limit', 'ja': '基本上限', 'zh': '基本额度',
    'fr': 'Limite de base', 'de': 'Basislimit', 'es': 'Límite base', 'pt': 'Limite base',
    'ru': 'Базовый лимит', 'tr': 'Temel limit', 'ar': 'الحد الأساسي', 'it': 'Limite base',
    'hi': 'आधार सीमा', 'th': 'โควต้าพื้นฐาน',
  });

  String get premiumQuotaRemaining => _t({
    'ko': '남은 발송량', 'en': 'Remaining', 'ja': '残り送信数', 'zh': '剩余发送量',
    'fr': 'Restant', 'de': 'Verbleibend', 'es': 'Restante', 'pt': 'Restante',
    'ru': 'Осталось', 'tr': 'Kalan', 'ar': 'المتبقي', 'it': 'Rimanente',
    'hi': 'शेष', 'th': 'คงเหลือ',
  });

  String get premiumQuotaThisMonth => _t({
    'ko': '이번 달 기준', 'en': 'This month', 'ja': '今月基準', 'zh': '本月基准',
    'fr': 'Ce mois', 'de': 'Diesen Monat', 'es': 'Este mes', 'pt': 'Este mês',
    'ru': 'За этот месяц', 'tr': 'Bu ay', 'ar': 'هذا الشهر', 'it': 'Questo mese',
    'hi': 'इस महीने', 'th': 'เดือนนี้',
  });

  String get premiumQuotaExtraPurchase => _t({
    'ko': '추가 구매', 'en': 'Extra purchased', 'ja': '追加購入', 'zh': '额外购买',
    'fr': 'Acheté en extra', 'de': 'Extra gekauft', 'es': 'Compra extra', 'pt': 'Compra extra',
    'ru': 'Доп. покупки', 'tr': 'Ek satın alma', 'ar': 'شراء إضافي', 'it': 'Acquisto extra',
    'hi': 'अतिरिक्त खरीद', 'th': 'ซื้อเพิ่ม',
  });

  String get premiumQuotaExtraAdded => _t({
    'ko': '통 추가', 'en': 'extra', 'ja': '通追加', 'zh': '封额外',
    'fr': 'supplémentaires', 'de': 'zusätzlich', 'es': 'extra', 'pt': 'extras',
    'ru': 'доп.', 'tr': 'ek', 'ar': 'إضافي', 'it': 'extra',
    'hi': 'अतिरिक्त', 'th': 'เพิ่มเติม',
  });

  String get premiumQuotaPacks => _t({
    'ko': '팩', 'en': 'packs', 'ja': 'パック', 'zh': '包',
    'fr': 'packs', 'de': 'Pakete', 'es': 'paquetes', 'pt': 'pacotes',
    'ru': 'пакетов', 'tr': 'paket', 'ar': 'حزم', 'it': 'pacchetti',
    'hi': 'पैक', 'th': 'แพ็ค',
  });

  String get premiumExtraAdded => _t({
    'ko': '1,000통이 추가되었습니다 ✓',
    'en': '1,000 credits added ✓',
    'ja': '1,000通が追加されました ✓',
    'zh': '已添加1,000封额度 ✓',
    'fr': '1 000 crédits ajoutés ✓',
    'de': '1.000 Credits hinzugefügt ✓',
    'es': '1.000 créditos agregados ✓',
    'pt': '1.000 créditos adicionados ✓',
    'ru': '1 000 кредитов добавлено ✓',
    'tr': '1.000 kredi eklendi ✓',
    'ar': 'تمت إضافة 1,000 رصيد ✓',
    'it': '1.000 crediti aggiunti ✓',
    'hi': '1,000 क्रेडिट जोड़े गए ✓',
    'th': 'เพิ่ม 1,000 เครดิตแล้ว ✓',
  });

  String get premiumExtraBuyBtn => _t({
    'ko': '1,000통 추가 구매 · ₩15,000',
    'en': 'Buy 1,000 extra · ₩15,000',
    'ja': '1,000通追加購入 · ₩15,000',
    'zh': '购买1,000封额外 · ₩15,000',
    'fr': 'Acheter 1 000 extra · ₩15 000',
    'de': '1.000 extra kaufen · ₩15.000',
    'es': 'Comprar 1.000 extra · ₩15.000',
    'pt': 'Comprar 1.000 extras · ₩15.000',
    'ru': 'Купить 1 000 доп. · ₩15 000',
    'tr': '1.000 ek satın al · ₩15.000',
    'ar': 'شراء 1,000 إضافي · ₩15,000',
    'it': 'Acquista 1.000 extra · ₩15.000',
    'hi': '1,000 अतिरिक्त खरीदें · ₩15,000',
    'th': 'ซื้อเพิ่ม 1,000 · ₩15,000',
  });

  String get premiumExtraResetNote => _t({
    'ko': '이번 달 말 초기화 · 미사용 발송권 소멸',
    'en': 'Resets at end of month · unused credits expire',
    'ja': '月末リセット · 未使用分は消滅',
    'zh': '月末重置 · 未使用额度过期',
    'fr': 'Réinitialisation en fin de mois · crédits non utilisés expirent',
    'de': 'Reset am Monatsende · ungenutzte Credits verfallen',
    'es': 'Se reinicia a fin de mes · créditos no usados expiran',
    'pt': 'Reseta no final do mês · créditos não usados expiram',
    'ru': 'Сброс в конце месяца · неиспользованные кредиты сгорают',
    'tr': 'Ay sonunda sıfırlanır · kullanılmayan krediler sona erer',
    'ar': 'يُعاد التعيين نهاية الشهر · الرصيد غير المستخدم ينتهي',
    'it': 'Reset a fine mese · crediti non usati scadono',
    'hi': 'महीने के अंत में रीसेट · अप्रयुक्त क्रेडिट समाप्त',
    'th': 'รีเซ็ตสิ้นเดือน · เครดิตที่ไม่ใช้จะหมดอายุ',
  });

  // ── Test mode ──

  String get premiumTestModeBadge => _t({
    'ko': '🧪 테스트 모드 — 실제 결제 없음',
    'en': '🧪 Test mode — no real payment',
    'ja': '🧪 テストモード — 実際の決済なし',
    'zh': '🧪 测试模式 — 无实际付款',
    'fr': '🧪 Mode test — pas de paiement réel',
    'de': '🧪 Testmodus — keine echte Zahlung',
    'es': '🧪 Modo prueba — sin pago real',
    'pt': '🧪 Modo teste — sem pagamento real',
    'ru': '🧪 Тестовый режим — без реальной оплаты',
    'tr': '🧪 Test modu — gerçek ödeme yok',
    'ar': '🧪 وضع الاختبار — بدون دفع حقيقي',
    'it': '🧪 Modalità test — nessun pagamento reale',
    'hi': '🧪 टेस्ट मोड — कोई वास्तविक भुगतान नहीं',
    'th': '🧪 โหมดทดสอบ — ไม่มีการชำระเงินจริง',
  });

  String get premiumTestPurchaseBtn => _t({
    'ko': '구매 (테스트)',
    'en': 'Purchase (test)',
    'ja': '購入（テスト）',
    'zh': '购买（测试）',
    'fr': 'Acheter (test)',
    'de': 'Kaufen (Test)',
    'es': 'Comprar (prueba)',
    'pt': 'Comprar (teste)',
    'ru': 'Купить (тест)',
    'tr': 'Satın al (test)',
    'ar': 'شراء (اختبار)',
    'it': 'Acquista (test)',
    'hi': 'खरीदें (टेस्ट)',
    'th': 'ซื้อ (ทดสอบ)',
  });

  // ── Brand upgrade dialog ──

  String get premiumBrandUpgradeTitle => _t({
    'ko': '브랜드 플랜으로 변경',
    'en': 'Switch to Brand Plan',
    'ja': 'ブランドプランに変更',
    'zh': '切换到品牌方案',
    'fr': 'Passer au forfait Brand',
    'de': 'Zum Brand-Plan wechseln',
    'es': 'Cambiar al plan Brand',
    'pt': 'Mudar para o plano Brand',
    'ru': 'Переключиться на план Brand',
    'tr': 'Brand planına geç',
    'ar': 'التبديل إلى خطة Brand',
    'it': 'Passa al piano Brand',
    'hi': 'Brand योजना पर स्विच करें',
    'th': 'เปลี่ยนเป็นแพ็กเกจ Brand',
  });

  String get premiumBrandUpgradeDesc1 => _t({
    'ko': '다음 결제부터 Brand / Creator 플랜(₩99,000/월)으로 변경됩니다.',
    'en': 'Starting from the next billing, you will be switched to the Brand / Creator plan (₩99,000/mo).',
    'ja': '次の決済からBrand / Creatorプラン（₩99,000/月）に変更されます。',
    'zh': '从下次付款起将切换到Brand / Creator方案（₩99,000/月）。',
    'fr': 'À partir de la prochaine facturation, vous passerez au forfait Brand / Creator (₩99 000/mois).',
    'de': 'Ab der nächsten Abrechnung wechseln Sie zum Brand / Creator-Plan (₩99.000/Monat).',
    'es': 'A partir de la próxima facturación, cambiará al plan Brand / Creator (₩99.000/mes).',
    'pt': 'A partir da próxima cobrança, mudará para o plano Brand / Creator (₩99.000/mês).',
    'ru': 'Со следующей оплаты вы перейдёте на план Brand / Creator (₩99 000/мес).',
    'tr': 'Bir sonraki faturadan itibaren Brand / Creator planına (₩99.000/ay) geçilecek.',
    'ar': 'بدءاً من الفوترة التالية، ستنتقل إلى خطة Brand / Creator (₩99,000/شهر).',
    'it': 'Dalla prossima fatturazione, passerai al piano Brand / Creator (₩99.000/mese).',
    'hi': 'अगली बिलिंग से Brand / Creator योजना (₩99,000/माह) पर स्विच होगा।',
    'th': 'ตั้งแต่บิลถัดไปจะเปลี่ยนเป็นแพ็กเกจ Brand / Creator (₩99,000/เดือน)',
  });

  String get premiumBrandUpgradeDesc2 => _t({
    'ko': '현재 구독은 해당일까지 유지됩니다.',
    'en': 'Your current subscription will remain active until then.',
    'ja': '現在のサブスクリプションはその日まで維持されます。',
    'zh': '当前订阅将保持到该日期。',
    'fr': 'Votre abonnement actuel restera actif jusque-là.',
    'de': 'Ihr aktuelles Abonnement bleibt bis dahin aktiv.',
    'es': 'Su suscripción actual permanecerá activa hasta entonces.',
    'pt': 'Sua assinatura atual permanecerá ativa até lá.',
    'ru': 'Текущая подписка сохранится до этой даты.',
    'tr': 'Mevcut aboneliğiniz o zamana kadar aktif kalacak.',
    'ar': 'سيبقى اشتراكك الحالي نشطاً حتى ذلك الحين.',
    'it': 'Il tuo abbonamento attuale rimarrà attivo fino ad allora.',
    'hi': 'आपकी वर्तमान सदस्यता तब तक सक्रिय रहेगी।',
    'th': 'แพ็กเกจปัจจุบันจะใช้ได้จนถึงวันนั้น',
  });

  String get premiumBrandUpgradeScheduleDesc => _t({
    'ko': '이후 변경 예약\nPremium → Brand 플랜 업그레이드',
    'en': 'Scheduled upgrade\nPremium → Brand plan',
    'ja': '以降変更予約\nPremium → Brandプランアップグレード',
    'zh': '之后变更预约\nPremium → Brand方案升级',
    'fr': 'Changement programmé\nPremium → forfait Brand',
    'de': 'Geplantes Upgrade\nPremium → Brand-Plan',
    'es': 'Cambio programado\nPremium → plan Brand',
    'pt': 'Upgrade agendado\nPremium → plano Brand',
    'ru': 'Запланированное обновление\nPremium → план Brand',
    'tr': 'Planlanmış yükseltme\nPremium → Brand planı',
    'ar': 'ترقية مجدولة\nPremium → خطة Brand',
    'it': 'Upgrade programmato\nPremium → piano Brand',
    'hi': 'निर्धारित अपग्रेड\nPremium → Brand योजना',
    'th': 'กำหนดอัปเกรด\nPremium → แพ็กเกจ Brand',
  });

  String get premiumBrandUpgradeTestSuccess => _t({
    'ko': '🏷️ Brand / Creator로 변경됐어요! (테스트 즉시 적용)',
    'en': '🏷️ Changed to Brand / Creator! (test applied immediately)',
    'ja': '🏷️ Brand / Creatorに変更されました！（テスト即時適用）',
    'zh': '🏷️ 已切换到Brand / Creator！（测试立即生效）',
    'fr': '🏷️ Passé à Brand / Creator ! (test appliqué immédiatement)',
    'de': '🏷️ Zu Brand / Creator gewechselt! (Test sofort angewendet)',
    'es': '🏷️ ¡Cambiado a Brand / Creator! (prueba aplicada inmediatamente)',
    'pt': '🏷️ Alterado para Brand / Creator! (teste aplicado imediatamente)',
    'ru': '🏷️ Изменено на Brand / Creator! (тест применён немедленно)',
    'tr': '🏷️ Brand / Creator\'a geçildi! (test anında uygulandı)',
    'ar': '🏷️ تم التبديل إلى Brand / Creator! (تم تطبيق الاختبار فوراً)',
    'it': '🏷️ Cambiato a Brand / Creator! (test applicato immediatamente)',
    'hi': '🏷️ Brand / Creator में बदल गया! (टेस्ट तुरंत लागू)',
    'th': '🏷️ เปลี่ยนเป็น Brand / Creator แล้ว! (ทดสอบมีผลทันที)',
  });

  // ── Share options ──

  String get premiumShareTitle => _t({
    'ko': '공유하기', 'en': 'Share', 'ja': 'シェア', 'zh': '分享',
    'fr': 'Partager', 'de': 'Teilen', 'es': 'Compartir', 'pt': 'Compartilhar',
    'ru': 'Поделиться', 'tr': 'Paylaş', 'ar': 'مشاركة', 'it': 'Condividi',
    'hi': 'साझा करें', 'th': 'แชร์',
  });

  String get premiumShareKakao => _t({
    'ko': '카카오톡', 'en': 'KakaoTalk', 'ja': 'KakaoTalk', 'zh': 'KakaoTalk',
    'fr': 'KakaoTalk', 'de': 'KakaoTalk', 'es': 'KakaoTalk', 'pt': 'KakaoTalk',
    'ru': 'KakaoTalk', 'tr': 'KakaoTalk', 'ar': 'KakaoTalk', 'it': 'KakaoTalk',
    'hi': 'KakaoTalk', 'th': 'KakaoTalk',
  });

  String get premiumShareKakaoDesc => _t({
    'ko': '카카오톡으로 친구에게 보내기',
    'en': 'Send to friend via KakaoTalk',
    'ja': 'KakaoTalkで友達に送る',
    'zh': '通过KakaoTalk发给朋友',
    'fr': 'Envoyer à un ami via KakaoTalk',
    'de': 'Per KakaoTalk an Freund senden',
    'es': 'Enviar a amigo por KakaoTalk',
    'pt': 'Enviar para amigo via KakaoTalk',
    'ru': 'Отправить другу через KakaoTalk',
    'tr': 'KakaoTalk ile arkadaşa gönder',
    'ar': 'إرسال لصديق عبر KakaoTalk',
    'it': 'Invia all\'amico tramite KakaoTalk',
    'hi': 'KakaoTalk से दोस्त को भेजें',
    'th': 'ส่งให้เพื่อนผ่าน KakaoTalk',
  });

  String get premiumShareKakaoMissing => _t({
    'ko': '카카오톡이 없어요. 텍스트가 복사됐어요 📋',
    'en': 'KakaoTalk not found. Text copied to clipboard 📋',
    'ja': 'KakaoTalkが見つかりません。テキストがコピーされました 📋',
    'zh': '未找到KakaoTalk。文本已复制到剪贴板 📋',
    'fr': 'KakaoTalk introuvable. Texte copié dans le presse-papiers 📋',
    'de': 'KakaoTalk nicht gefunden. Text in die Zwischenablage kopiert 📋',
    'es': 'KakaoTalk no encontrado. Texto copiado al portapapeles 📋',
    'pt': 'KakaoTalk não encontrado. Texto copiado para a área de transferência 📋',
    'ru': 'KakaoTalk не найден. Текст скопирован в буфер обмена 📋',
    'tr': 'KakaoTalk bulunamadı. Metin panoya kopyalandı 📋',
    'ar': 'KakaoTalk غير موجود. تم نسخ النص إلى الحافظة 📋',
    'it': 'KakaoTalk non trovato. Testo copiato negli appunti 📋',
    'hi': 'KakaoTalk नहीं मिला। टेक्स्ट क्लिपबोर्ड पर कॉपी किया गया 📋',
    'th': 'ไม่พบ KakaoTalk คัดลอกข้อความแล้ว 📋',
  });

  String get premiumShareEmail => _t({
    'ko': '이메일', 'en': 'Email', 'ja': 'メール', 'zh': '电子邮件',
    'fr': 'E-mail', 'de': 'E-Mail', 'es': 'Correo electrónico', 'pt': 'E-mail',
    'ru': 'Электронная почта', 'tr': 'E-posta', 'ar': 'البريد الإلكتروني', 'it': 'E-mail',
    'hi': 'ईमेल', 'th': 'อีเมล',
  });

  String get premiumShareEmailDesc => _t({
    'ko': '이메일로 전송하기',
    'en': 'Send via email',
    'ja': 'メールで送信',
    'zh': '通过电子邮件发送',
    'fr': 'Envoyer par e-mail',
    'de': 'Per E-Mail senden',
    'es': 'Enviar por correo electrónico',
    'pt': 'Enviar por e-mail',
    'ru': 'Отправить по электронной почте',
    'tr': 'E-posta ile gönder',
    'ar': 'إرسال عبر البريد الإلكتروني',
    'it': 'Invia via e-mail',
    'hi': 'ईमेल से भेजें',
    'th': 'ส่งทางอีเมล',
  });

  String get premiumShareSms => _t({
    'ko': '문자 메시지', 'en': 'Text Message', 'ja': 'テキストメッセージ', 'zh': '短信',
    'fr': 'SMS', 'de': 'SMS', 'es': 'Mensaje de texto', 'pt': 'Mensagem de texto',
    'ru': 'SMS', 'tr': 'SMS', 'ar': 'رسالة نصية', 'it': 'SMS',
    'hi': 'टेक्स्ट संदेश', 'th': 'ข้อความ',
  });

  String get premiumShareSmsDesc => _t({
    'ko': '연락처에서 받는 사람 선택',
    'en': 'Select recipient from contacts',
    'ja': '連絡先から受信者を選択',
    'zh': '从联系人中选择收件人',
    'fr': 'Sélectionner le destinataire depuis les contacts',
    'de': 'Empfänger aus Kontakten auswählen',
    'es': 'Seleccionar destinatario de contactos',
    'pt': 'Selecionar destinatário dos contatos',
    'ru': 'Выберите получателя из контактов',
    'tr': 'Kişilerden alıcı seç',
    'ar': 'اختر المستلم من جهات الاتصال',
    'it': 'Seleziona destinatario dai contatti',
    'hi': 'संपर्कों से प्राप्तकर्ता चुनें',
    'th': 'เลือกผู้รับจากรายชื่อ',
  });

  String get premiumShareCopyLink => _t({
    'ko': '링크 복사', 'en': 'Copy link', 'ja': 'リンクをコピー', 'zh': '复制链接',
    'fr': 'Copier le lien', 'de': 'Link kopieren', 'es': 'Copiar enlace', 'pt': 'Copiar link',
    'ru': 'Копировать ссылку', 'tr': 'Bağlantıyı kopyala', 'ar': 'نسخ الرابط', 'it': 'Copia link',
    'hi': 'लिंक कॉपी करें', 'th': 'คัดลอกลิงก์',
  });

  String get premiumShareCopyLinkDesc => _t({
    'ko': '클립보드에 복사하기',
    'en': 'Copy to clipboard',
    'ja': 'クリップボードにコピー',
    'zh': '复制到剪贴板',
    'fr': 'Copier dans le presse-papiers',
    'de': 'In die Zwischenablage kopieren',
    'es': 'Copiar al portapapeles',
    'pt': 'Copiar para a área de transferência',
    'ru': 'Копировать в буфер обмена',
    'tr': 'Panoya kopyala',
    'ar': 'نسخ إلى الحافظة',
    'it': 'Copia negli appunti',
    'hi': 'क्लिपबोर्ड पर कॉपी करें',
    'th': 'คัดลอกไปยังคลิปบอร์ด',
  });

  String get premiumClipboardCopied => _t({
    'ko': '클립보드에 복사됐어요 📋',
    'en': 'Copied to clipboard 📋',
    'ja': 'クリップボードにコピーしました 📋',
    'zh': '已复制到剪贴板 📋',
    'fr': 'Copié dans le presse-papiers 📋',
    'de': 'In die Zwischenablage kopiert 📋',
    'es': 'Copiado al portapapeles 📋',
    'pt': 'Copiado para a área de transferência 📋',
    'ru': 'Скопировано в буфер обмена 📋',
    'tr': 'Panoya kopyalandı 📋',
    'ar': 'تم النسخ إلى الحافظة 📋',
    'it': 'Copiato negli appunti 📋',
    'hi': 'क्लिपबोर्ड पर कॉपी किया गया 📋',
    'th': 'คัดลอกไปยังคลิปบอร์ดแล้ว 📋',
  });

  // ── Map Screens ─────────────────────────────────────────────────────
  // ── Map screens ──────────────────────────────────────────────────────────

  String get mapDeliveryTracking => _t({
    'ko': '배송 추적',
    'en': 'Delivery Tracking',
    'ja': '配送追跡',
    'zh': '配送跟踪',
    'fr': 'Suivi de livraison',
    'de': 'Lieferverfolgung',
    'es': 'Seguimiento de envío',
    'pt': 'Rastreamento de entrega',
    'ru': 'Отслеживание доставки',
    'tr': 'Teslimat Takibi',
    'ar': 'تتبع التوصيل',
    'it': 'Tracciamento consegna',
    'hi': 'डिलीवरी ट्रैकिंग',
    'th': 'ติดตามการจัดส่ง',
  });

  String get mapLetterNotFound => _t({
    'ko': '혜택을 찾을 수 없습니다.',
    'en': 'Reward not found.',
    'ja': '手紙が見つかりません。',
    'zh': '找不到信件。',
    'fr': 'Lettre introuvable.',
    'de': 'Brief nicht gefunden.',
    'es': 'Carta no encontrada.',
    'pt': 'Carta não encontrada.',
    'ru': 'Письмо не найдено.',
    'tr': 'Mektup bulunamadı.',
    'ar': 'لم يتم العثور على الرسالة.',
    'it': 'Lettera non trovata.',
    'hi': 'पत्र नहीं मिला।',
    'th': 'ไม่พบจดหมาย',
  });

  String get mapArrivedWithin2km => _t({
    'ko': '2km 이내 도착!',
    'en': 'Arrived within 2km!',
    'ja': '2km以内に到着！',
    'zh': '已到达2km范围内！',
    'fr': 'Arrivé à moins de 2km !',
    'de': 'Innerhalb von 2km angekommen!',
    'es': '¡Llegó a menos de 2km!',
    'pt': 'Chegou a menos de 2km!',
    'ru': 'Прибыло в радиусе 2км!',
    'tr': '2km içinde ulaştı!',
    'ar': 'وصلت ضمن 2 كم!',
    'it': 'Arrivata entro 2km!',
    'hi': '2km के भीतर पहुँचा!',
    'th': 'มาถึงภายใน 2 กม.!',
  });

  String get mapDeliveryComplete => _t({
    'ko': '배달 완료',
    'en': 'Delivered',
    'ja': '配達完了',
    'zh': '已送达',
    'fr': 'Livré',
    'de': 'Zugestellt',
    'es': 'Entregado',
    'pt': 'Entregue',
    'ru': 'Доставлено',
    'tr': 'Teslim Edildi',
    'ar': 'تم التوصيل',
    'it': 'Consegnata',
    'hi': 'डिलीवर हो गया',
    'th': 'จัดส่งแล้ว',
  });

  String get mapPreparing => _t({
    'ko': '준비 중',
    'en': 'Preparing',
    'ja': '準備中',
    'zh': '准备中',
    'fr': 'En préparation',
    'de': 'Wird vorbereitet',
    'es': 'Preparando',
    'pt': 'Preparando',
    'ru': 'Подготовка',
    'tr': 'Hazırlanıyor',
    'ar': 'جارٍ التحضير',
    'it': 'In preparazione',
    'hi': 'तैयारी हो रही है',
    'th': 'กำลังเตรียม',
  });

  String get mapNoRouteInfo => _t({
    'ko': '경로 정보 없음',
    'en': 'No route info',
    'ja': '経路情報なし',
    'zh': '无路线信息',
    'fr': 'Aucun itinéraire',
    'de': 'Keine Routeninformation',
    'es': 'Sin información de ruta',
    'pt': 'Sem informação de rota',
    'ru': 'Нет данных о маршруте',
    'tr': 'Rota bilgisi yok',
    'ar': 'لا توجد معلومات عن المسار',
    'it': 'Nessuna info percorso',
    'hi': 'मार्ग की जानकारी नहीं',
    'th': 'ไม่มีข้อมูลเส้นทาง',
  });

  String get mapOverallDeliveryProgress => _t({
    'ko': '전체 배송 진행',
    'en': 'Overall Delivery Progress',
    'ja': '全体配送進捗',
    'zh': '整体配送进度',
    'fr': 'Progression globale',
    'de': 'Gesamtfortschritt',
    'es': 'Progreso general',
    'pt': 'Progresso geral',
    'ru': 'Общий прогресс доставки',
    'tr': 'Genel Teslimat İlerlemesi',
    'ar': 'تقدم التوصيل الإجمالي',
    'it': 'Progresso consegna',
    'hi': 'कुल डिलीवरी प्रगति',
    'th': 'ความคืบหน้าการจัดส่งทั้งหมด',
  });

  String mapMyLocationShown(String distKm) => _t({
    'ko': '내 위치 포인트 표시됨 · 현재 혜택과 약 ${distKm}km',
    'en': 'My location shown · ~${distKm}km from reward',
    'ja': '現在地表示中 · 手紙まで約${distKm}km',
    'zh': '已显示我的位置 · 距信件约${distKm}km',
    'fr': 'Ma position affichée · ~${distKm}km de la lettre',
    'de': 'Mein Standort angezeigt · ~${distKm}km vom Brief',
    'es': 'Mi ubicación mostrada · ~${distKm}km de la carta',
    'pt': 'Minha localização exibida · ~${distKm}km da carta',
    'ru': 'Моя позиция показана · ~${distKm}км от письма',
    'tr': 'Konumum gösterildi · mektuptan ~${distKm}km',
    'ar': 'موقعي معروض · ~${distKm} كم من الرسالة',
    'it': 'La mia posizione mostrata · ~${distKm}km dalla lettera',
    'hi': 'मेरा स्थान दिखाया गया · पत्र से ~${distKm}km',
    'th': 'แสดงตำแหน่งของฉัน · ~${distKm}กม. จากจดหมาย',
  });

  String get mapDeliveryRoute => _t({
    'ko': '배송 경로',
    'en': 'Delivery Route',
    'ja': '配送ルート',
    'zh': '配送路线',
    'fr': 'Itinéraire de livraison',
    'de': 'Lieferroute',
    'es': 'Ruta de envío',
    'pt': 'Rota de entrega',
    'ru': 'Маршрут доставки',
    'tr': 'Teslimat Rotası',
    'ar': 'مسار التوصيل',
    'it': 'Percorso di consegna',
    'hi': 'डिलीवरी मार्ग',
    'th': 'เส้นทางจัดส่ง',
  });

  String mapMinutes(int n) => _t({
    'ko': '${n}분',
    'en': '${n}min',
    'ja': '${n}分',
    'zh': '${n}分钟',
    'fr': '${n}min',
    'de': '${n}Min',
    'es': '${n}min',
    'pt': '${n}min',
    'ru': '${n}мин',
    'tr': '${n}dk',
    'ar': '${n} دقيقة',
    'it': '${n}min',
    'hi': '${n}मिनट',
    'th': '${n}นาที',
  });

  String mapHours(int h) => _t({
    'ko': '${h}시간',
    'en': '${h}h',
    'ja': '${h}時間',
    'zh': '${h}小时',
    'fr': '${h}h',
    'de': '${h}Std',
    'es': '${h}h',
    'pt': '${h}h',
    'ru': '${h}ч',
    'tr': '${h}sa',
    'ar': '${h} ساعة',
    'it': '${h}h',
    'hi': '${h}घंटे',
    'th': '${h}ชม.',
  });

  String mapHoursMinutes(int h, int m) => _t({
    'ko': '${h}시간 ${m}분',
    'en': '${h}h ${m}min',
    'ja': '${h}時間${m}分',
    'zh': '${h}小时${m}分钟',
    'fr': '${h}h ${m}min',
    'de': '${h}Std ${m}Min',
    'es': '${h}h ${m}min',
    'pt': '${h}h ${m}min',
    'ru': '${h}ч ${m}мин',
    'tr': '${h}sa ${m}dk',
    'ar': '${h} ساعة ${m} دقيقة',
    'it': '${h}h ${m}min',
    'hi': '${h}घंटे ${m}मिनट',
    'th': '${h}ชม. ${m}นาที',
  });

  String mapAboutHours(int h) => _t({
    'ko': '약 ${h}시간',
    'en': '~${h}h',
    'ja': '約${h}時間',
    'zh': '约${h}小时',
    'fr': '~${h}h',
    'de': '~${h}Std',
    'es': '~${h}h',
    'pt': '~${h}h',
    'ru': '~${h}ч',
    'tr': '~${h}sa',
    'ar': '~${h} ساعة',
    'it': '~${h}h',
    'hi': '~${h}घंटे',
    'th': '~${h}ชม.',
  });

  String get mapViewAll => _t({
    'ko': '전체보기',
    'en': 'View All',
    'ja': '全体表示',
    'zh': '查看全部',
    'fr': 'Tout voir',
    'de': 'Alle anzeigen',
    'es': 'Ver todo',
    'pt': 'Ver tudo',
    'ru': 'Показать все',
    'tr': 'Tümünü Gör',
    'ar': 'عرض الكل',
    'it': 'Mostra tutto',
    'hi': 'सभी देखें',
    'th': 'ดูทั้งหมด',
  });

  String get mapZoomIn => _t({
    'ko': '확대',
    'en': 'Zoom In',
    'ja': 'ズームイン',
    'zh': '放大',
    'fr': 'Zoomer',
    'de': 'Vergrößern',
    'es': 'Acercar',
    'pt': 'Ampliar',
    'ru': 'Приблизить',
    'tr': 'Yakınlaştır',
    'ar': 'تكبير',
    'it': 'Ingrandisci',
    'hi': 'ज़ूम इन',
    'th': 'ซูมเข้า',
  });

  String get mapZoomOut => _t({
    'ko': '축소',
    'en': 'Zoom Out',
    'ja': 'ズームアウト',
    'zh': '缩小',
    'fr': 'Dézoomer',
    'de': 'Verkleinern',
    'es': 'Alejar',
    'pt': 'Reduzir',
    'ru': 'Отдалить',
    'tr': 'Uzaklaştır',
    'ar': 'تصغير',
    'it': 'Riduci',
    'hi': 'ज़ूम आउट',
    'th': 'ซูมออก',
  });

  String mapRankN(int rank) => _t({
    'ko': '${rank}위',
    'en': '#$rank',
    'ja': '${rank}位',
    'zh': '第${rank}名',
    'fr': '${rank}e',
    'de': 'Platz $rank',
    'es': '${rank}°',
    'pt': '${rank}°',
    'ru': '${rank}-е место',
    'tr': '${rank}.',
    'ar': 'المركز $rank',
    'it': '${rank}°',
    'hi': '#$rank',
    'th': 'อันดับ $rank',
  });

  String get mapWhatsHere => _t({
    'ko': '이 위치에 무엇이 있나요?',
    'en': "What's at this location?",
    'ja': 'この場所には何がありますか？',
    'zh': '这个位置有什么？',
    'fr': "Qu'y a-t-il ici ?",
    'de': 'Was ist an diesem Ort?',
    'es': '¿Qué hay aquí?',
    'pt': 'O que há aqui?',
    'ru': 'Что здесь?',
    'tr': 'Bu konumda ne var?',
    'ar': 'ماذا يوجد هنا؟',
    'it': "Cosa c'è qui?",
    'hi': 'इस स्थान पर क्या है?',
    'th': 'มีอะไรอยู่ที่นี่?',
  });

  // Build 185: 지도 상단 공용 라벨 — 타워 표현 제거. 모든 티어에 "내 레터"
  // 로 통일 (Brand 는 sender identity 로 해석 가능, Free/Premium 은 캐릭터).
  String get mapMyTower => _t({
    'ko': '내 카운터',
    'en': 'My Counter',
    'ja': 'マイカウンター',
    'zh': '我的 Letter',
    'fr': 'Mon Letter',
    'de': 'Mein Letter',
    'es': 'Mi Letter',
    'pt': 'Meu Letter',
    'ru': 'Мой Letter',
    'tr': 'Letter\'ım',
    'ar': 'Letter الخاص بي',
    'it': 'Il mio Letter',
    'hi': 'मेरा Letter',
    'th': 'Letter ของฉัน',
  });

  String get mapFloorUnit => _t({
    'ko': '층',
    'en': 'F',
    'ja': '階',
    'zh': '层',
    'fr': 'ét.',
    'de': 'St.',
    'es': 'p.',
    'pt': 'and.',
    'ru': 'эт.',
    'tr': 'kat',
    'ar': 'طابق',
    'it': 'p.',
    'hi': 'मंज़िल',
    'th': 'ชั้น',
  });

  // Build 185: 근처 타워 → 근처 Letter 사용자.
  String mapNearbyTowers(int count) => _t({
    'ko': '근처 Letter $count명',
    'en': '$count Nearby Rewards',
    'ja': '近くの Letter ${count}人',
    'zh': '附近 $count 位 Letter',
    'fr': '$count Letters à proximité',
    'de': '$count Letters in der Nähe',
    'es': '$count Letters cercanos',
    'pt': '$count Letters próximos',
    'ru': '$count ближайших Letter',
    'tr': '$count yakın Letter',
    'ar': '$count Letter قريبة',
    'it': '$count Letter vicini',
    'hi': '$count पास के Letter',
    'th': 'Letter ใกล้เคียง $count',
  });

  String mapLetterFrom(String country) => _t({
    'ko': '${country}에서 온 혜택',
    'en': 'Reward from $country',
    'ja': '${country}からの手紙',
    'zh': '来自${country}的信',
    'fr': 'Lettre de $country',
    'de': 'Brief aus $country',
    'es': 'Carta de $country',
    'pt': 'Carta de $country',
    'ru': 'Письмо из $country',
    'tr': "$country'dan mektup",
    'ar': 'رسالة من $country',
    'it': 'Lettera da $country',
    'hi': '$country से पत्र',
    'th': 'จดหมายจาก $country',
  });

  String mapReadCountTapToPickUp(int readCount, int maxReaders) => _t({
    'ko': '$readCount/${maxReaders}명 읽음 · 탭해서 수령',
    'en': '$readCount/$maxReaders read · Tap to pick up',
    'ja': '$readCount/${maxReaders}人既読 · タップして受け取る',
    'zh': '$readCount/${maxReaders}人已读 · 点击领取',
    'fr': '$readCount/$maxReaders lu(s) · Appuyez pour récupérer',
    'de': '$readCount/$maxReaders gelesen · Tippen zum Abholen',
    'es': '$readCount/$maxReaders leídos · Toca para recoger',
    'pt': '$readCount/$maxReaders lidos · Toque para recolher',
    'ru': '$readCount/$maxReaders прочит. · Нажмите, чтобы забрать',
    'tr': '$readCount/$maxReaders okundu · Al',
    'ar': '$readCount/$maxReaders مقروءة · اضغط للاستلام',
    'it': '$readCount/$maxReaders letti · Tocca per ritirare',
    'hi': '$readCount/$maxReaders पढ़ा · लेने के लिए टैप करें',
    'th': '$readCount/$maxReaders อ่านแล้ว · แตะเพื่อรับ',
  });

  // Build 186: 온보딩 슬라이드의 티어 뱃지 라벨 (일관된 브랜딩).
  String get tierLabelFree => _t({
    'ko': 'Free', 'en': 'Free', 'ja': 'Free', 'zh': 'Free',
    'fr': 'Free', 'de': 'Free', 'es': 'Free', 'pt': 'Free',
    'ru': 'Free', 'tr': 'Free', 'ar': 'Free', 'it': 'Free',
    'hi': 'Free', 'th': 'Free',
  });

  String get tierLabelPremium => _t({
    'ko': 'Premium', 'en': 'Premium', 'ja': 'Premium', 'zh': 'Premium',
    'fr': 'Premium', 'de': 'Premium', 'es': 'Premium', 'pt': 'Premium',
    'ru': 'Premium', 'tr': 'Premium', 'ar': 'Premium', 'it': 'Premium',
    'hi': 'Premium', 'th': 'Premium',
  });

  String get tierLabelBrand => _t({
    'ko': 'Brand', 'en': 'Brand', 'ja': 'Brand', 'zh': 'Brand',
    'fr': 'Brand', 'de': 'Brand', 'es': 'Brand', 'pt': 'Brand',
    'ru': 'Brand', 'tr': 'Brand', 'ar': 'Brand', 'it': 'Brand',
    'hi': 'Brand', 'th': 'Brand',
  });

  // Build 189.1: compose 닫기 확인 다이얼로그.
  String get composeCloseConfirmTitle => _t({
    'ko': '작성 중인 혜택이 있어요',
    'en': 'You have unsent content',
    'ja': '作成中の手紙があります',
    'zh': '有未发送的内容',
    'fr': 'Contenu non envoyé',
    'de': 'Nicht gesendeter Inhalt',
    'es': 'Contenido sin enviar',
    'pt': 'Conteúdo não enviado',
    'ru': 'Неотправленный черновик',
    'tr': 'Gönderilmemiş içerik',
    'ar': 'محتوى غير مُرسل',
    'it': 'Contenuto non inviato',
    'hi': 'बिना भेजा गया सामग्री',
    'th': 'ยังไม่ได้ส่ง',
  });

  String get composeCloseConfirmBody => _t({
    'ko': '지금 닫으면 저장하거나 삭제할 수 있어요. 저장하면 다음에 이어쓸 수 있어요.',
    'en': 'Save your draft to continue later, or discard it now.',
    'ja': '下書きとして保存すればあとで続きを書けます。破棄するとこのまま閉じます。',
    'zh': '保存为草稿可稍后继续，放弃则不保留。',
    'fr': 'Sauvegarder le brouillon pour continuer plus tard ou l\'abandonner.',
    'de': 'Entwurf speichern, um später fortzufahren, oder verwerfen.',
    'es': 'Guarda el borrador para continuar luego, o descártalo.',
    'pt': 'Guarda o rascunho para continuar depois, ou descarta.',
    'ru': 'Сохраните черновик или удалите.',
    'tr': 'Taslağı kaydet veya sil.',
    'ar': 'احفظ المسودة أو احذفها.',
    'it': 'Salva la bozza o scartala.',
    'hi': 'ड्राफ़्ट सहेजें या हटाएं।',
    'th': 'บันทึกแบบร่างหรือทิ้ง',
  });

  String get composeSaveDraftAndClose => _t({
    'ko': '저장하고 닫기',
    'en': 'Save & close',
    'ja': '保存して閉じる',
    'zh': '保存并关闭',
    'fr': 'Sauvegarder et fermer',
    'de': 'Speichern & schließen',
    'es': 'Guardar y cerrar',
    'pt': 'Guardar e fechar',
    'ru': 'Сохранить',
    'tr': 'Kaydet ve kapat',
    'ar': 'حفظ وإغلاق',
    'it': 'Salva e chiudi',
    'hi': 'सहेजें और बंद करें',
    'th': 'บันทึก & ปิด',
  });

  // Build 189: Brand compose 의 대량 발송 활성 배너.
  String get composeBulkModeActive => _t({
    'ko': '대량 발송 모드 · 여러 나라 일괄 발송',
    'en': 'Bulk mode · multi-country blast',
    'ja': '一括送信モード · 複数国同時送信',
    'zh': '群发模式 · 多国同时发送',
    'fr': 'Mode envoi groupé · multi-pays',
    'de': 'Massenversand · mehrere Länder',
    'es': 'Modo envío masivo · varios países',
    'pt': 'Envio em massa · vários países',
    'ru': 'Массовая рассылка · несколько стран',
    'tr': 'Toplu gönderim · çoklu ülke',
    'ar': 'إرسال جماعي · عدة دول',
    'it': 'Invio di massa · più paesi',
    'hi': 'बल्क भेजें · बहु-देश',
    'th': 'ส่งจำนวนมาก · หลายประเทศ',
  });

  String get composeDisableMode => _t({
    'ko': '끄기',
    'en': 'Turn off',
    'ja': 'オフ',
    'zh': '关闭',
    'fr': 'Désactiver',
    'de': 'Aus',
    'es': 'Desactivar',
    'pt': 'Desativar',
    'ru': 'Выкл',
    'tr': 'Kapat',
    'ar': 'إيقاف',
    'it': 'Disattiva',
    'hi': 'बंद',
    'th': 'ปิด',
  });

  // Build 186: 픽업 쿨다운 상시 pill — MM:SS 로 남은 시간 표시.
  String mapCooldownPill(String mmss) => _t({
    'ko': '다음 줍기까지 $mmss',
    'en': 'Next pickup in $mmss',
    'ja': '次の拾得まで $mmss',
    'zh': '下次拾取 $mmss',
    'fr': 'Prochain ramassage dans $mmss',
    'de': 'Nächstes Aufsammeln in $mmss',
    'es': 'Próxima recogida en $mmss',
    'pt': 'Próxima recolha em $mmss',
    'ru': 'Следующий сбор через $mmss',
    'tr': 'Sonraki toplama $mmss',
    'ar': 'الالتقاط التالي خلال $mmss',
    'it': 'Prossimo ritiro in $mmss',
    'hi': 'अगली पिकअप $mmss',
    'th': 'เก็บครั้งถัดไปใน $mmss',
  });

  // Build 185: "커뮤니티 타워" → "커뮤니티 Letter" — 타 사용자 마커 라벨.
  String get mapCommunityTower => _t({
    'ko': '커뮤니티 Letter',
    'en': 'Community Reward',
    'ja': 'コミュニティ Letter',
    'zh': '社区 Letter',
    'fr': 'Letter de la communauté',
    'de': 'Community-Letter',
    'es': 'Letter de la comunidad',
    'pt': 'Letter da comunidade',
    'ru': 'Letter сообщества',
    'tr': 'Topluluk Letter',
    'ar': 'Letter المجتمع',
    'it': 'Letter della comunità',
    'hi': 'कम्युनिटी Letter',
    'th': 'Letter ชุมชน',
  });

  // Build 220: "레터 순위" → "카운터 순위" (rebrand).
  String get mapWorldRanking => _t({
    'ko': '카운터 순위',
    'en': 'Counter Ranking',
    'ja': 'カウンターランキング',
    'zh': '计数器排名',
    'fr': 'Classement Counter',
    'de': 'Counter-Rangliste',
    'es': 'Ranking de Counter',
    'pt': 'Ranking de Counter',
    'ru': 'Рейтинг Counter',
    'tr': 'Counter Sıralaması',
    'ar': 'تصنيف Counter',
    'it': 'Classifica Counter',
    'hi': 'Counter रैंकिंग',
    'th': 'อันดับ Counter',
  });

  // Build 185: 건물 층수 · 타워 높이 → 활동 레벨 (letter-centric metric).
  String get mapBuildingFloors => _t({
    'ko': '활동 레벨',
    'en': 'Activity Level',
    'ja': 'アクティビティレベル',
    'zh': '活跃等级',
    'fr': 'Niveau d\'activité',
    'de': 'Aktivitätsstufe',
    'es': 'Nivel de actividad',
    'pt': 'Nível de atividade',
    'ru': 'Уровень активности',
    'tr': 'Aktivite Seviyesi',
    'ar': 'مستوى النشاط',
    'it': 'Livello di attività',
    'hi': 'गतिविधि स्तर',
    'th': 'ระดับกิจกรรม',
  });

  String get mapTowerHeight => _t({
    'ko': '활동 레벨',
    'en': 'Activity Level',
    'ja': 'アクティビティレベル',
    'zh': '活跃等级',
    'fr': 'Niveau d\'activité',
    'de': 'Aktivitätsstufe',
    'es': 'Nivel de actividad',
    'pt': 'Nível de atividade',
    'ru': 'Уровень активности',
    'tr': 'Aktivite Seviyesi',
    'ar': 'مستوى النشاط',
    'it': 'Livello di attività',
    'hi': 'गतिविधि स्तर',
    'th': 'ระดับกิจกรรม',
  });

  String get mapClose => _t({
    'ko': '닫기',
    'en': 'Close',
    'ja': '閉じる',
    'zh': '关闭',
    'fr': 'Fermer',
    'de': 'Schließen',
    'es': 'Cerrar',
    'pt': 'Fechar',
    'ru': 'Закрыть',
    'tr': 'Kapat',
    'ar': 'إغلاق',
    'it': 'Chiudi',
    'hi': 'बंद करें',
    'th': 'ปิด',
  });

  String get mapLetterArrivedVisitToOpen => _t({
    'ko': '혜택이 도착했어요!\n이 위치를 직접 방문해야 열어볼 수 있어요.',
    'en': 'A reward has arrived!\nVisit this location to open it.',
    'ja': '手紙が届きました！\nこの場所を訪れると開封できます。',
    'zh': '信已到达！\n请亲自前往此地点才能打开。',
    'fr': 'Une lettre est arrivée !\nRendez-vous sur place pour l\'ouvrir.',
    'de': 'Ein Brief ist angekommen!\nBesuchen Sie diesen Ort, um ihn zu öffnen.',
    'es': '¡Ha llegado una carta!\nVisita este lugar para abrirla.',
    'pt': 'Uma carta chegou!\nVisite este local para abri-la.',
    'ru': 'Письмо прибыло!\nПосетите это место, чтобы открыть его.',
    'tr': 'Mektup geldi!\nAçmak için bu konumu ziyaret edin.',
    'ar': 'وصلت رسالة!\nقم بزيارة هذا الموقع لفتحها.',
    'it': 'È arrivata una lettera!\nVisita questo luogo per aprirla.',
    'hi': 'एक पत्र आ गया है!\nइसे खोलने के लिए इस स्थान पर जाएँ।',
    'th': 'จดหมายมาถึงแล้ว!\nไปที่ตำแหน่งนี้เพื่อเปิดอ่าน',
  });

  String mapReceivedLetterFrom(String country) => _t({
    'ko': '${country}에서 온 혜택을 받았어요!',
    'en': 'You received a reward from $country!',
    'ja': '${country}からの手紙を受け取りました！',
    'zh': '收到了来自${country}的信！',
    'fr': 'Vous avez reçu une lettre de $country !',
    'de': 'Sie haben einen Brief aus $country erhalten!',
    'es': '¡Recibiste una carta de $country!',
    'pt': 'Você recebeu uma carta de $country!',
    'ru': 'Вы получили письмо из $country!',
    'tr': "$country'dan bir mektup aldınız!",
    'ar': 'استلمت رسالة من $country!',
    'it': 'Hai ricevuto una lettera da $country!',
    'hi': '$country से एक पत्र मिला!',
    'th': 'ได้รับจดหมายจาก $country!',
  });

  String get mapPickUpLetter => _t({
    'ko': '혜택 수령하기',
    'en': 'Pick Up Reward',
    'ja': '手紙を受け取る',
    'zh': '领取信件',
    'fr': 'Récupérer la lettre',
    'de': 'Brief abholen',
    'es': 'Recoger carta',
    'pt': 'Recolher carta',
    'ru': 'Забрать письмо',
    'tr': 'Mektubu Al',
    'ar': 'استلام الرسالة',
    'it': 'Ritira la lettera',
    'hi': 'पत्र लें',
    'th': 'รับจดหมาย',
  });

  String get mapLocationPermissionNeeded => _t({
    'ko': '위치 권한 필요',
    'en': 'Location Permission Needed',
    'ja': '位置情報の許可が必要',
    'zh': '需要位置权限',
    'fr': 'Autorisation de localisation requise',
    'de': 'Standortberechtigung erforderlich',
    'es': 'Se necesita permiso de ubicación',
    'pt': 'Permissão de localização necessária',
    'ru': 'Требуется разрешение на геолокацию',
    'tr': 'Konum İzni Gerekli',
    'ar': 'مطلوب إذن الموقع',
    'it': 'Permesso di localizzazione necessario',
    'hi': 'स्थान अनुमति आवश्यक',
    'th': 'ต้องการสิทธิ์ตำแหน่ง',
  });

  String get mapLocationPermissionDesc => _t({
    'ko': 'Thiscount는 홍보를 보내고 받기 위해 위치 권한이 필요합니다.\n설정 앱에서 위치 권한을 "앱 사용 중 허용" 으로 변경해주세요.',
    'en': 'Thiscount needs location permission to send and receive rewards.\nPlease change location permission to "While Using the App" in Settings.',
    'ja': 'Thiscountは手紙の送受信に位置情報の許可が必要です。\n設定アプリで位置情報を「アプリ使用中のみ許可」に変更してください。',
    'zh': 'Thiscount需要位置权限来发送和接收信件。\n请在设置中将位置权限更改为"使用App时允许"。',
    'fr': 'Thiscount a besoin de la localisation pour envoyer et recevoir des lettres.\nVeuillez activer « En cours d\'utilisation » dans les paramètres.',
    'de': 'Thiscount benötigt den Standortzugriff zum Senden und Empfangen von Briefen.\nBitte ändern Sie die Standortberechtigung in den Einstellungen auf „Während der Nutzung".',
    'es': 'Thiscount necesita permisos de ubicación para enviar y recibir cartas.\nPor favor, cambia el permiso a "Mientras se usa la app" en Ajustes.',
    'pt': 'O Thiscount precisa de permissão de localização para enviar e receber cartas.\nAltere a permissão para "Durante o uso do app" nas Configurações.',
    'ru': 'Thiscount нужен доступ к геолокации для отправки и получения писем.\nИзмените разрешение на «При использовании приложения» в Настройках.',
    'tr': 'Thiscount mektup gönderip almak için konum iznine ihtiyaç duyar.\nLütfen Ayarlar\'dan konum iznini "Uygulama Kullanılırken" olarak değiştirin.',
    'ar': 'يحتاج Thiscount إلى إذن الموقع لإرسال واستلام الرسائل.\nيرجى تغيير إذن الموقع إلى "أثناء استخدام التطبيق" في الإعدادات.',
    'it': 'Thiscount ha bisogno del permesso di localizzazione per inviare e ricevere lettere.\nModifica il permesso su "Durante l\'uso dell\'app" nelle Impostazioni.',
    'hi': 'Thiscount को पत्र भेजने और प्राप्त करने के लिए स्थान अनुमति चाहिए।\nकृपया सेटिंग्स में स्थान अनुमति को "ऐप उपयोग के दौरान" में बदलें।',
    'th': 'Thiscount ต้องการสิทธิ์ตำแหน่งเพื่อส่งและรับจดหมาย\nกรุณาเปลี่ยนสิทธิ์ตำแหน่งเป็น "ขณะใช้แอป" ในการตั้งค่า',
  });

  String get mapLater => _t({
    'ko': '나중에',
    'en': 'Later',
    'ja': '後で',
    'zh': '稍后',
    'fr': 'Plus tard',
    'de': 'Später',
    'es': 'Más tarde',
    'pt': 'Depois',
    'ru': 'Позже',
    'tr': 'Sonra',
    'ar': 'لاحقاً',
    'it': 'Dopo',
    'hi': 'बाद में',
    'th': 'ภายหลัง',
  });

  String get mapOpenSettings => _t({
    'ko': '설정 열기',
    'en': 'Open Settings',
    'ja': '設定を開く',
    'zh': '打开设置',
    'fr': 'Ouvrir les paramètres',
    'de': 'Einstellungen öffnen',
    'es': 'Abrir Ajustes',
    'pt': 'Abrir Configurações',
    'ru': 'Открыть Настройки',
    'tr': 'Ayarları Aç',
    'ar': 'فتح الإعدادات',
    'it': 'Apri Impostazioni',
    'hi': 'सेटिंग्स खोलें',
    'th': 'เปิดการตั้งค่า',
  });

  String get mapLocationPermissionRequired => _t({
    'ko': '위치 권한이 필요합니다. 설정에서 허용해주세요.',
    'en': 'Location permission is required. Please allow it in Settings.',
    'ja': '位置情報の許可が必要です。設定で許可してください。',
    'zh': '需要位置权限。请在设置中允许。',
    'fr': 'Autorisation de localisation requise. Veuillez l\'activer dans les paramètres.',
    'de': 'Standortberechtigung erforderlich. Bitte in den Einstellungen erlauben.',
    'es': 'Se requiere permiso de ubicación. Por favor, permítalo en Ajustes.',
    'pt': 'Permissão de localização necessária. Por favor, permita nas Configurações.',
    'ru': 'Требуется разрешение на геолокацию. Разрешите в Настройках.',
    'tr': 'Konum izni gerekli. Lütfen Ayarlar\'dan izin verin.',
    'ar': 'مطلوب إذن الموقع. يرجى السماح به في الإعدادات.',
    'it': 'Permesso di localizzazione necessario. Consenti nelle Impostazioni.',
    'hi': 'स्थान अनुमति आवश्यक है। कृपया सेटिंग्स में अनुमति दें।',
    'th': 'ต้องการสิทธิ์ตำแหน่ง กรุณาอนุญาตในการตั้งค่า',
  });

  String get mapCannotGetLocation => _t({
    'ko': '위치를 가져올 수 없어요. 잠시 후 다시 시도해주세요.',
    'en': 'Cannot get location. Please try again later.',
    'ja': '位置情報を取得できません。後でもう一度お試しください。',
    'zh': '无法获取位置。请稍后重试。',
    'fr': 'Impossible d\'obtenir la position. Réessayez plus tard.',
    'de': 'Standort konnte nicht ermittelt werden. Bitte versuchen Sie es später erneut.',
    'es': 'No se puede obtener la ubicación. Inténtalo de nuevo más tarde.',
    'pt': 'Não foi possível obter a localização. Tente novamente mais tarde.',
    'ru': 'Не удалось получить местоположение. Попробуйте позже.',
    'tr': 'Konum alınamadı. Lütfen daha sonra tekrar deneyin.',
    'ar': 'تعذر الحصول على الموقع. يرجى المحاولة لاحقاً.',
    'it': 'Impossibile ottenere la posizione. Riprova più tardi.',
    'hi': 'स्थान प्राप्त नहीं हो सका। कृपया बाद में पुनः प्रयास करें।',
    'th': 'ไม่สามารถรับตำแหน่งได้ กรุณาลองใหม่ภายหลัง',
  });

  String get mapDawn => _t({
    'ko': '새벽',
    'en': 'Dawn',
    'ja': '夜明け',
    'zh': '黎明',
    'fr': 'Aube',
    'de': 'Morgengrauen',
    'es': 'Amanecer',
    'pt': 'Amanhecer',
    'ru': 'Рассвет',
    'tr': 'Şafak',
    'ar': 'فجر',
    'it': 'Alba',
    'hi': 'सुबह',
    'th': 'รุ่งอรุณ',
  });

  String get mapDay => _t({
    'ko': '낮',
    'en': 'Day',
    'ja': '昼',
    'zh': '白天',
    'fr': 'Jour',
    'de': 'Tag',
    'es': 'Día',
    'pt': 'Dia',
    'ru': 'День',
    'tr': 'Gündüz',
    'ar': 'نهار',
    'it': 'Giorno',
    'hi': 'दिन',
    'th': 'กลางวัน',
  });

  String get mapEvening => _t({
    'ko': '저녁',
    'en': 'Evening',
    'ja': '夕方',
    'zh': '傍晚',
    'fr': 'Soir',
    'de': 'Abend',
    'es': 'Tarde',
    'pt': 'Noite',
    'ru': 'Вечер',
    'tr': 'Akşam',
    'ar': 'مساء',
    'it': 'Sera',
    'hi': 'शाम',
    'th': 'เย็น',
  });

  String get mapNight => _t({
    'ko': '밤',
    'en': 'Night',
    'ja': '夜',
    'zh': '夜晚',
    'fr': 'Nuit',
    'de': 'Nacht',
    'es': 'Noche',
    'pt': 'Noite',
    'ru': 'Ночь',
    'tr': 'Gece',
    'ar': 'ليل',
    'it': 'Notte',
    'hi': 'रात',
    'th': 'กลางคืน',
  });

  String mapLiveExploring(int usersCount, int transitCount) => _t({
    'ko': '${usersCount}명 탐색 중 · 방금 ${transitCount}통 이동',
    'en': '$usersCount exploring · $transitCount in transit',
    'ja': '${usersCount}人が探索中 · ${transitCount}通移動中',
    'zh': '${usersCount}人在探索 · ${transitCount}封运送中',
    'fr': '$usersCount en exploration · $transitCount en transit',
    'de': '$usersCount erkunden · $transitCount unterwegs',
    'es': '$usersCount explorando · $transitCount en tránsito',
    'pt': '$usersCount explorando · $transitCount em trânsito',
    'ru': '$usersCount исследуют · $transitCount в пути',
    'tr': '$usersCount keşfediyor · $transitCount yolda',
    'ar': '$usersCount يستكشفون · $transitCount في الطريق',
    'it': '$usersCount in esplorazione · $transitCount in transito',
    'hi': '$usersCount खोज रहे हैं · $transitCount रास्ते में',
    'th': '$usersCount กำลังสำรวจ · $transitCount กำลังเดินทาง',
  });

  String get mapSyncingData => _t({
    'ko': '데이터 동기화 중',
    'en': 'Syncing data',
    'ja': 'データ同期中',
    'zh': '同步数据中',
    'fr': 'Synchronisation en cours',
    'de': 'Daten werden synchronisiert',
    'es': 'Sincronizando datos',
    'pt': 'Sincronizando dados',
    'ru': 'Синхронизация данных',
    'tr': 'Veriler senkronize ediliyor',
    'ar': 'جارٍ مزامنة البيانات',
    'it': 'Sincronizzazione dati',
    'hi': 'डेटा सिंक हो रहा है',
    'th': 'กำลังซิงค์ข้อมูล',
  });

  String get mapMapLanguage => _t({
    'ko': '지도 언어',
    'en': 'Map Language',
    'ja': '地図の言語',
    'zh': '地图语言',
    'fr': 'Langue de la carte',
    'de': 'Kartensprache',
    'es': 'Idioma del mapa',
    'pt': 'Idioma do mapa',
    'ru': 'Язык карты',
    'tr': 'Harita Dili',
    'ar': 'لغة الخريطة',
    'it': 'Lingua della mappa',
    'hi': 'मानचित्र भाषा',
    'th': 'ภาษาแผนที่',
  });

  String get mapZoom => _t({
    'ko': '줌',
    'en': 'Zoom',
    'ja': 'ズーム',
    'zh': '缩放',
    'fr': 'Zoom',
    'de': 'Zoom',
    'es': 'Zoom',
    'pt': 'Zoom',
    'ru': 'Зум',
    'tr': 'Yakınlık',
    'ar': 'تكبير',
    'it': 'Zoom',
    'hi': 'ज़ूम',
    'th': 'ซูม',
  });

  String get mapTowerLabel => _t({
    'ko': '타워 라벨',
    'en': 'Tower Label',
    'ja': 'タワーラベル',
    'zh': '塔标签',
    'fr': 'Libellé de tour',
    'de': 'Turm-Label',
    'es': 'Etiqueta de torre',
    'pt': 'Rótulo da torre',
    'ru': 'Метка башни',
    'tr': 'Kule Etiketi',
    'ar': 'تسمية البرج',
    'it': 'Etichetta torre',
    'hi': 'टावर लेबल',
    'th': 'ป้ายหอคอย',
  });

  String get mapInTransitLetters => _t({
    'ko': '배송중 혜택',
    'en': 'In Transit',
    'ja': '配送中の手紙',
    'zh': '运送中的信',
    'fr': 'En transit',
    'de': 'Unterwegs',
    'es': 'En tránsito',
    'pt': 'Em trânsito',
    'ru': 'В пути',
    'tr': 'Yolda',
    'ar': 'قيد التوصيل',
    'it': 'In transito',
    'hi': 'रास्ते में',
    'th': 'กำลังจัดส่ง',
  });

  String get mapNearby2km => _t({
    'ko': '2km 근처',
    'en': 'Within 2km',
    'ja': '2km以内',
    'zh': '2km附近',
    'fr': 'À 2km',
    'de': 'Im Umkreis von 2km',
    'es': 'A 2km',
    'pt': 'A 2km',
    'ru': 'В радиусе 2км',
    'tr': '2km içinde',
    'ar': 'ضمن 2 كم',
    'it': 'Entro 2km',
    'hi': '2km के पास',
    'th': 'ภายใน 2 กม.',
  });

  String get mapAllLetters => _t({
    'ko': '전체 혜택',
    'en': 'All Rewards',
    'ja': '全ての手紙',
    'zh': '全部信件',
    'fr': 'Toutes les lettres',
    'de': 'Alle Briefe',
    'es': 'Todas las cartas',
    'pt': 'Todas as cartas',
    'ru': 'Все письма',
    'tr': 'Tüm Mektuplar',
    'ar': 'جميع الرسائل',
    'it': 'Tutte le lettere',
    'hi': 'सभी पत्र',
    'th': 'จดหมายทั้งหมด',
  });

  String mapNearbyLettersArrived(int count) => _t({
    'ko': '혜택 ${count}개가 근처에 도착했어요!  탭해서 확인',
    'en': '$count reward(s) arrived nearby! Tap to check',
    'ja': '${count}通の手紙が近くに届きました！タップして確認',
    'zh': '${count}封信已到达附近！点击查看',
    'fr': '$count lettre(s) arrivée(s) à proximité ! Appuyez pour voir',
    'de': '$count Brief(e) in der Nähe angekommen! Tippen zum Ansehen',
    'es': '¡$count carta(s) llegaron cerca! Toca para ver',
    'pt': '$count carta(s) chegaram por perto! Toque para ver',
    'ru': '$count писем прибыло поблизости! Нажмите для просмотра',
    'tr': '$count mektup yakınında geldi! Görmek için dokun',
    'ar': 'وصلت $count رسالة بالقرب منك! اضغط للتحقق',
    'it': '$count lettera/e arrivata/e nelle vicinanze! Tocca per vedere',
    'hi': '$count पत्र पास में आ गए! देखने के लिए टैप करें',
    'th': 'จดหมาย $count ฉบับมาถึงใกล้ๆ แล้ว! แตะเพื่อดู',
  });

  /// 인앱 배너 다양한 문구 (이모지 + 텍스트)
  List<({String emoji, String text})> mapNearbyBannerVariants(int count) => [
    (
      emoji: '📩',
      text: _t({
        'ko': '혜택 ${count}개가 근처에 도착했어요! 탭해서 확인',
        'en': '$count reward(s) arrived nearby! Tap to check',
        'ja': '${count}通の手紙が近くに届きました！タップして確認',
        'zh': '${count}封信已到达附近！点击查看',
      }),
    ),
    (
      emoji: '🌊',
      text: _t({
        'ko': '파도가 혜택 ${count}개를 해변에 밀어줬어요',
        'en': 'Waves washed $count reward(s) ashore',
        'ja': '波が${count}通の手紙を浜辺に運びました',
        'zh': '海浪把${count}封信冲上了岸',
      }),
    ),
    (
      emoji: '🎐',
      text: _t({
        'ko': '바람을 타고 혜택 ${count}개가 날아왔어요',
        'en': '$count reward(s) blew in on the wind',
        'ja': '風に乗って${count}通の手紙が飛んできました',
        'zh': '${count}封信随风飘来了',
      }),
    ),
    (
      emoji: '🕊️',
      text: _t({
        'ko': '비둘기가 혜택 ${count}개를 물고 왔어요',
        'en': 'A dove brought $count reward(s) to you',
        'ja': '鳩が${count}通の手紙を持ってきました',
        'zh': '鸽子带来了${count}封信',
      }),
    ),
    (
      emoji: '✨',
      text: _t({
        'ko': '근처에서 혜택 ${count}개가 반짝이고 있어요',
        'en': '$count reward(s) are sparkling nearby',
        'ja': '近くで${count}通の手紙がキラキラ光っています',
        'zh': '附近有${count}封信在闪闪发光',
      }),
    ),
    (
      emoji: '🍃',
      text: _t({
        'ko': '어디선가 혜택 ${count}개가 날아왔어요',
        'en': '$count reward(s) drifted in from afar',
        'ja': 'どこかから${count}通の手紙が舞い込みました',
        'zh': '${count}封信从远方飘来',
      }),
    ),
    (
      emoji: '💌',
      text: _t({
        'ko': '소중한 혜택 ${count}개가 기다리고 있어요',
        'en': '$count precious reward(s) await you',
        'ja': '大切な手紙が${count}通待っています',
        'zh': '${count}封珍贵的信在等你',
      }),
    ),
    (
      emoji: '🏖️',
      text: _t({
        'ko': '해변에 혜택병 ${count}개가 떠밀려 왔어요',
        'en': '$count bottle(s) washed up on shore',
        'ja': '浜辺にボトルが${count}本漂着しました',
        'zh': '${count}个漂流瓶被冲上了岸',
      }),
    ),
  ];

  String get mapNearby => _t({
    'ko': '근처',
    'en': 'Nearby',
    'ja': '近く',
    'zh': '附近',
    'fr': 'À proximité',
    'de': 'In der Nähe',
    'es': 'Cerca',
    'pt': 'Perto',
    'ru': 'Рядом',
    'tr': 'Yakın',
    'ar': 'قريب',
    'it': 'Vicino',
    'hi': 'पास में',
    'th': 'ใกล้เคียง',
  });

  String get mapReceivedLetters => _t({
    'ko': '받은 혜택',
    'en': 'Received',
    'ja': '受信した手紙',
    'zh': '收到的信',
    'fr': 'Reçues',
    'de': 'Empfangen',
    'es': 'Recibidas',
    'pt': 'Recebidas',
    'ru': 'Полученные',
    'tr': 'Gelen',
    'ar': 'المستلمة',
    'it': 'Ricevute',
    'hi': 'प्राप्त',
    'th': 'ได้รับ',
  });

  String get mapSentLetters => _t({
    'ko': '보낸 혜택',
    'en': 'Sent',
    'ja': '送信した手紙',
    'zh': '已发送的信',
    'fr': 'Envoyées',
    'de': 'Gesendet',
    'es': 'Enviadas',
    'pt': 'Enviadas',
    'ru': 'Отправленные',
    'tr': 'Gönderilen',
    'ar': 'المرسلة',
    'it': 'Inviate',
    'hi': 'भेजे गए',
    'th': 'ส่งแล้ว',
  });

  String get mapCurrent => _t({
    'ko': '현재',
    'en': 'Current',
    'ja': '現在',
    'zh': '当前',
    'fr': 'Actuel',
    'de': 'Aktuell',
    'es': 'Actual',
    'pt': 'Atual',
    'ru': 'Текущий',
    'tr': 'Mevcut',
    'ar': 'الحالي',
    'it': 'Attuale',
    'hi': 'वर्तमान',
    'th': 'ปัจจุบัน',
  });

  String get mapOverallProgress => _t({
    'ko': '전체 진행률',
    'en': 'Overall Progress',
    'ja': '全体進捗',
    'zh': '总进度',
    'fr': 'Progression globale',
    'de': 'Gesamtfortschritt',
    'es': 'Progreso general',
    'pt': 'Progresso geral',
    'ru': 'Общий прогресс',
    'tr': 'Genel İlerleme',
    'ar': 'التقدم الإجمالي',
    'it': 'Progresso complessivo',
    'hi': 'कुल प्रगति',
    'th': 'ความคืบหน้ารวม',
  });

  String get mapMoving => _t({
    'ko': '이동중',
    'en': 'Moving',
    'ja': '移動中',
    'zh': '移动中',
    'fr': 'En mouvement',
    'de': 'Unterwegs',
    'es': 'En movimiento',
    'pt': 'Em movimento',
    'ru': 'В пути',
    'tr': 'Hareket Halinde',
    'ar': 'في حركة',
    'it': 'In movimento',
    'hi': 'चल रहा है',
    'th': 'กำลังเคลื่อนที่',
  });

  // ── App State ───────────────────────────────────────────────────────
  // ── State (app_state.dart) ────────────────────────────────────────────────

  String get stateMyLocation => _t({
    'ko': '내 위치',
    'en': 'My Location',
    'ja': '現在地',
    'zh': '我的位置',
    'fr': 'Ma position',
    'de': 'Mein Standort',
    'es': 'Mi ubicación',
    'pt': 'Minha localização',
    'ru': 'Моё местоположение',
    'tr': 'Konumum',
    'ar': 'موقعي',
    'it': 'La mia posizione',
    'hi': 'मेरा स्थान',
    'th': 'ตำแหน่งของฉัน',
  });

  String get stateAdmin => _t({
    'ko': '관리자',
    'en': 'Admin',
    'ja': '管理者',
    'zh': '管理员',
    'fr': 'Administrateur',
    'de': 'Administrator',
    'es': 'Administrador',
    'pt': 'Administrador',
    'ru': 'Администратор',
    'tr': 'Yönetici',
    'ar': 'المسؤول',
    'it': 'Amministratore',
    'hi': 'व्यवस्थापक',
    'th': 'ผู้ดูแลระบบ',
  });

  String get stateThemeAuto => _t({
    'ko': '자동 (시간대)',
    'en': 'Auto (Time-based)',
    'ja': '自動（時間帯）',
    'zh': '自动（按时区）',
    'fr': 'Automatique (fuseau horaire)',
    'de': 'Automatisch (Zeitzone)',
    'es': 'Automático (zona horaria)',
    'pt': 'Automático (fuso horário)',
    'ru': 'Авто (по времени)',
    'tr': 'Otomatik (saat dilimine göre)',
    'ar': 'تلقائي (حسب المنطقة الزمنية)',
    'it': 'Automatico (fuso orario)',
    'hi': 'स्वचालित (समय क्षेत्र)',
    'th': 'อัตโนมัติ (ตามเวลา)',
  });

  String get stateThemeLight => _t({
    'ko': '밝은 모드',
    'en': 'Light Mode',
    'ja': 'ライトモード',
    'zh': '浅色模式',
    'fr': 'Mode clair',
    'de': 'Heller Modus',
    'es': 'Modo claro',
    'pt': 'Modo claro',
    'ru': 'Светлая тема',
    'tr': 'Açık mod',
    'ar': 'الوضع الفاتح',
    'it': 'Modalità chiara',
    'hi': 'लाइट मोड',
    'th': 'โหมดสว่าง',
  });

  String get stateThemeDark => _t({
    'ko': '다크 모드',
    'en': 'Dark Mode',
    'ja': 'ダークモード',
    'zh': '深色模式',
    'fr': 'Mode sombre',
    'de': 'Dunkler Modus',
    'es': 'Modo oscuro',
    'pt': 'Modo escuro',
    'ru': 'Тёмная тема',
    'tr': 'Karanlık mod',
    'ar': 'الوضع الداكن',
    'it': 'Modalità scura',
    'hi': 'डार्क मोड',
    'th': 'โหมดมืด',
  });

  String get stateDmUnavailableBrand => _t({
    'ko': '브랜드 계정은 DM을 사용할 수 없어요.\n홍보 발송을 통해 수신자와 소통해보세요.',
    'en': 'Brand accounts cannot use DM.\nPlease communicate with recipients through promos.',
    'ja': 'ブランドアカウントはDMを使用できません。\n手紙の送信で受信者とコミュニケーションしてください。',
    'zh': '品牌账号无法使用私信功能。\n请通过发送信件与收件人沟通。',
    'fr': 'Les comptes de marque ne peuvent pas utiliser les MP.\nCommuniquez avec les destinataires via les lettres.',
    'de': 'Markenkonten können keine DMs nutzen.\nKommunizieren Sie mit Empfängern über Briefe.',
    'es': 'Las cuentas de marca no pueden usar MD.\nComunícate con los destinatarios a través de cartas.',
    'pt': 'Contas de marca não podem usar MD.\nComunique-se com os destinatários por cartas.',
    'ru': 'Бренд-аккаунты не могут использовать ЛС.\nОбщайтесь с получателями через письма.',
    'tr': 'Marka hesapları DM kullanamaz.\nAlıcılarla mektup yoluyla iletişim kurun.',
    'ar': 'حسابات العلامة التجارية لا يمكنها استخدام الرسائل المباشرة.\nتواصل مع المستلمين عبر الرسائل.',
    'it': 'Gli account brand non possono usare i MD.\nComunica con i destinatari tramite lettere.',
    'hi': 'ब्रांड अकाउंट DM का उपयोग नहीं कर सकते।\nकृपया पत्र भेजकर संवाद करें।',
    'th': 'บัญชีแบรนด์ไม่สามารถใช้ DM ได้\nกรุณาสื่อสารกับผู้รับผ่านจดหมาย',
  });

  String stateDmUnavailableFree(int premiumLimit) => _t({
    'ko': '빠른 메시지(DM)는 프리미엄 회원 전용이에요.\n프리미엄으로 업그레이드하면 DM 이용 및 하루 $premiumLimit통 발송이 가능해요.',
    'en': 'Quick Message (DM) is for premium members only.\nUpgrade to Premium for DM access and $premiumLimit promos/day.',
    'ja': 'クイックレター（DM）はプレミアム会員限定です。\nプレミアムにアップグレードするとDMと1日${premiumLimit}通の送信が可能です。',
    'zh': '快信（私信）仅限高级会员使用。\n升级高级版即可使用私信功能，每日发送$premiumLimit封。',
    'fr': 'La lettre rapide (MP) est réservée aux membres premium.\nPassez au Premium pour les MP et $premiumLimit lettres/jour.',
    'de': 'Schnellbrief (DM) ist nur für Premium-Mitglieder.\nUpgrade auf Premium für DMs und $premiumLimit Briefe/Tag.',
    'es': 'Carta rápida (MD) es solo para miembros premium.\nActualiza a Premium para MD y $premiumLimit cartas/día.',
    'pt': 'Carta rápida (MD) é exclusiva para membros premium.\nAtualize para Premium para MD e $premiumLimit cartas/dia.',
    'ru': 'Быстрое письмо (ЛС) — только для премиум-участников.\nОформите подписку Premium для ЛС и $premiumLimit писем/день.',
    'tr': 'Hızlı mektup (DM) yalnızca premium üyelere özeldir.\nPremium\'a yükselterek DM ve günde $premiumLimit mektup gönderebilirsiniz.',
    'ar': 'الرسالة السريعة (DM) مخصصة للأعضاء المميزين فقط.\nقم بالترقية إلى Premium للوصول إلى DM و$premiumLimit رسالة/يوم.',
    'it': 'Lettera rapida (MD) è solo per membri premium.\nPassa a Premium per MD e $premiumLimit lettere/giorno.',
    'hi': 'क्विक लेटर (DM) केवल प्रीमियम सदस्यों के लिए है।\nDM और प्रतिदिन $premiumLimit पत्र भेजने के लिए प्रीमियम में अपग्रेड करें।',
    'th': 'จดหมายด่วน (DM) สำหรับสมาชิกพรีเมียมเท่านั้น\nอัปเกรดเป็น Premium เพื่อใช้ DM และส่งวันละ $premiumLimit ฉบับ',
  });

  String statePremiumExpressLimitExceeded(int limit) => _t({
    'ko': '프리미엄 특급 배송은 하루 $limit통까지 가능해요.',
    'en': 'Premium express delivery is limited to $limit promos/day.',
    'ja': 'プレミアム特急配送は1日${limit}通までです。',
    'zh': '高级特快配送每日限$limit封。',
    'fr': 'La livraison express premium est limitée à $limit lettres/jour.',
    'de': 'Premium-Expressversand ist auf $limit Briefe/Tag begrenzt.',
    'es': 'El envío exprés premium está limitado a $limit cartas/día.',
    'pt': 'A entrega expressa premium é limitada a $limit cartas/dia.',
    'ru': 'Премиум экспресс-доставка ограничена $limit письмами/день.',
    'tr': 'Premium ekspres teslimat günde $limit mektupla sınırlıdır.',
    'ar': 'التوصيل السريع المميز محدود بـ $limit رسائل/يوم.',
    'it': 'La consegna express premium è limitata a $limit lettere/giorno.',
    'hi': 'प्रीमियम एक्सप्रेस डिलीवरी प्रतिदिन $limit पत्रों तक सीमित है।',
    'th': 'การจัดส่งด่วนพรีเมียมจำกัดวันละ $limit ฉบับ',
  });

  String stateImageLimitExceeded(int limit) => _t({
    'ko': '오늘 이미지 혜택 한도(${limit}통)에 도달했어요. 내일 다시 시도해주세요.',
    'en': 'You\'ve reached today\'s image promo limit ($limit). Please try again tomorrow.',
    'ja': '本日の画像レター上限（${limit}通）に達しました。明日もう一度お試しください。',
    'zh': '已达到今日图片信件上限（$limit封）。请明天再试。',
    'fr': 'Vous avez atteint la limite de lettres image ($limit). Réessayez demain.',
    'de': 'Sie haben das heutige Bildbrief-Limit ($limit) erreicht. Versuchen Sie es morgen erneut.',
    'es': 'Has alcanzado el límite de cartas con imagen ($limit). Inténtalo mañana.',
    'pt': 'Você atingiu o limite de cartas com imagem ($limit). Tente novamente amanhã.',
    'ru': 'Достигнут дневной лимит писем с изображениями ($limit). Попробуйте завтра.',
    'tr': 'Bugünkü resimli mektup limitine ($limit) ulaştınız. Yarın tekrar deneyin.',
    'ar': 'لقد وصلت إلى حد رسائل الصور اليومي ($limit). يرجى المحاولة غداً.',
    'it': 'Hai raggiunto il limite giornaliero di lettere con immagine ($limit). Riprova domani.',
    'hi': 'आज का इमेज पत्र सीमा ($limit) पूरी हो गई। कृपया कल पुनः प्रयास करें।',
    'th': 'ถึงขีดจำกัดจดหมายรูปภาพวันนี้แล้ว ($limit ฉบับ) กรุณาลองใหม่พรุ่งนี้',
  });

  String get stateBrandExtraVerificationUnavailable => _t({
    'ko': '서버 검증이 활성화되지 않아 추가 발송권 구매를 완료할 수 없어요.\n로그인 상태와 Firebase 설정을 확인해주세요.',
    'en': 'Server verification is not active, so the extra quota purchase cannot be completed.\nPlease check your login status and Firebase settings.',
    'ja': 'サーバー検証が有効でないため、追加送信権の購入を完了できません。\nログイン状態とFirebase設定を確認してください。',
    'zh': '服务器验证未启用，无法完成额外配额购买。\n请检查登录状态和Firebase设置。',
    'fr': 'La vérification serveur n\'est pas active. L\'achat de quota supplémentaire ne peut pas être finalisé.\nVérifiez votre connexion et les paramètres Firebase.',
    'de': 'Serververifizierung ist nicht aktiv. Der Kauf zusätzlicher Kontingente kann nicht abgeschlossen werden.\nBitte überprüfen Sie Ihren Login-Status und die Firebase-Einstellungen.',
    'es': 'La verificación del servidor no está activa. No se puede completar la compra de cuota adicional.\nVerifica tu estado de inicio de sesión y la configuración de Firebase.',
    'pt': 'A verificação do servidor não está ativa. A compra de cota extra não pode ser concluída.\nVerifique seu status de login e as configurações do Firebase.',
    'ru': 'Проверка на сервере не активна. Покупка дополнительной квоты невозможна.\nПроверьте статус входа и настройки Firebase.',
    'tr': 'Sunucu doğrulaması etkin değil. Ek gönderim hakkı satın alma tamamlanamıyor.\nGiriş durumunuzu ve Firebase ayarlarınızı kontrol edin.',
    'ar': 'التحقق من الخادم غير مفعّل. لا يمكن إتمام شراء الحصة الإضافية.\nيرجى التحقق من حالة تسجيل الدخول وإعدادات Firebase.',
    'it': 'La verifica del server non è attiva. L\'acquisto della quota aggiuntiva non può essere completato.\nVerifica lo stato di accesso e le impostazioni Firebase.',
    'hi': 'सर्वर सत्यापन सक्रिय नहीं है। अतिरिक्त कोटा खरीद पूरी नहीं हो सकती।\nकृपया अपनी लॉगिन स्थिति और Firebase सेटिंग्स जांचें।',
    'th': 'การตรวจสอบเซิร์ฟเวอร์ไม่ได้เปิดใช้งาน ไม่สามารถซื้อโควต้าเพิ่มเติมได้\nกรุณาตรวจสอบสถานะการเข้าสู่ระบบและการตั้งค่า Firebase',
  });

  String stateDailyLimitFreeValueCopy(int freeLimit, int premiumLimit) => _t({
    'ko': '오늘 무료 한도(${freeLimit}통)를 모두 사용했어요.\n프리미엄(월 ₩4,900)으로 업그레이드하면 하루 ${premiumLimit}통까지 보내서 답장 기회를 최대 10배까지 넓힐 수 있어요.',
    'en': 'You\'ve used all $freeLimit free promos today.\nUpgrade to Premium to send up to $premiumLimit/day and multiply your reply chances by 10x.',
    'ja': '本日の無料枠（${freeLimit}通）を使い切りました。\nプレミアムにアップグレードすると1日${premiumLimit}通まで送信でき、返信チャンスが最大10倍に。',
    'zh': '今日免费额度（$freeLimit封）已用完。\n升级Premium每日可发$premiumLimit封，回信机会增加10倍。',
    'fr': 'Vous avez utilisé vos $freeLimit lettres gratuites aujourd\'hui.\nPassez au Premium pour envoyer jusqu\'à $premiumLimit/jour et multiplier vos chances de réponse par 10.',
    'de': 'Sie haben heute alle $freeLimit kostenlosen Briefe verbraucht.\nUpgraden Sie auf Premium für bis zu $premiumLimit/Tag und verzehnfachen Sie Ihre Antwortchancen.',
    'es': 'Has usado todas las $freeLimit cartas gratis hoy.\nActualiza a Premium para enviar hasta $premiumLimit/día y multiplicar tus oportunidades de respuesta por 10.',
    'pt': 'Você usou todas as $freeLimit cartas grátis hoje.\nAtualize para Premium para enviar até $premiumLimit/dia e multiplicar suas chances de resposta por 10x.',
    'ru': 'Вы использовали все $freeLimit бесплатных писем сегодня.\nПодпишитесь на Premium — до $premiumLimit писем/день и в 10 раз больше шансов на ответ.',
    'tr': 'Bugünkü ücretsiz $freeLimit mektup hakkınızı kullandınız.\nPremium\'a yükselerek günde $premiumLimit mektup gönderebilir ve yanıt şansınızı 10 katına çıkarabilirsiniz.',
    'ar': 'لقد استخدمت جميع الرسائل المجانية ($freeLimit) اليوم.\nقم بالترقية إلى Premium لإرسال حتى $premiumLimit/يوم ومضاعفة فرص الرد 10 أضعاف.',
    'it': 'Hai usato tutte le $freeLimit lettere gratuite oggi.\nPassa a Premium per inviare fino a $premiumLimit/giorno e moltiplicare le possibilità di risposta per 10.',
    'hi': 'आज की $freeLimit मुफ्त पत्र सीमा समाप्त हो गई।\nPremium में अपग्रेड करें - प्रतिदिन $premiumLimit पत्र भेजें और जवाब की संभावना 10 गुना बढ़ाएं।',
    'th': 'คุณใช้จดหมายฟรี $freeLimit ฉบับหมดแล้ววันนี้\nอัปเกรดเป็น Premium ส่งได้ถึง $premiumLimit ฉบับ/วัน เพิ่มโอกาสได้รับตอบกลับ 10 เท่า',
  });

  String stateDailyLimitFree(int freeLimit, int premiumLimit) => _t({
    'ko': '무료 회원은 하루 ${freeLimit}통까지 발송할 수 있어요.\n프리미엄(월 ₩4,900)으로 업그레이드하면 하루 ${premiumLimit}통 발송 가능해요!',
    'en': 'Free members can send up to $freeLimit promos/day.\nUpgrade to Premium for $premiumLimit promos/day!',
    'ja': '無料会員は1日${freeLimit}通まで送信できます。\nプレミアムにアップグレードすると1日${premiumLimit}通送信可能！',
    'zh': '免费会员每日可发送$freeLimit封信件。\n升级Premium每日可发$premiumLimit封！',
    'fr': 'Les membres gratuits peuvent envoyer $freeLimit lettres/jour.\nPassez au Premium pour $premiumLimit lettres/jour !',
    'de': 'Kostenlose Mitglieder können $freeLimit Briefe/Tag senden.\nUpgraden Sie auf Premium für $premiumLimit Briefe/Tag!',
    'es': 'Los miembros gratis pueden enviar $freeLimit cartas/día.\n¡Actualiza a Premium para $premiumLimit cartas/día!',
    'pt': 'Membros gratuitos podem enviar $freeLimit cartas/dia.\nAtualize para Premium para $premiumLimit cartas/dia!',
    'ru': 'Бесплатные участники могут отправлять $freeLimit писем/день.\nОформите Premium — $premiumLimit писем/день!',
    'tr': 'Ücretsiz üyeler günde $freeLimit mektup gönderebilir.\nPremium\'a yükselerek günde $premiumLimit mektup gönderin!',
    'ar': 'يمكن للأعضاء المجانيين إرسال $freeLimit رسائل/يوم.\nقم بالترقية إلى Premium لإرسال $premiumLimit رسالة/يوم!',
    'it': 'I membri gratuiti possono inviare $freeLimit lettere/giorno.\nPassa a Premium per $premiumLimit lettere/giorno!',
    'hi': 'मुफ्त सदस्य प्रतिदिन $freeLimit पत्र भेज सकते हैं।\nPremium में अपग्रेड करें - प्रतिदिन $premiumLimit पत्र!',
    'th': 'สมาชิกฟรีส่งได้ $freeLimit ฉบับ/วัน\nอัปเกรดเป็น Premium ส่งได้ $premiumLimit ฉบับ/วัน!',
  });

  String stateDailyLimitBrand(int brandLimit) => _t({
    'ko': '오늘 브랜드 발송 한도(${brandLimit}통)에 도달했어요. 추가 발송권(1,000통 ₩15,000)을 구매하거나 내일 다시 시도해주세요.',
    'en': 'You\'ve reached today\'s brand limit ($brandLimit). Purchase extra quota (1,000 promos) or try again tomorrow.',
    'ja': '本日のブランド送信上限（${brandLimit}通）に達しました。追加送信権（1,000通）を購入するか、明日再度お試しください。',
    'zh': '已达今日品牌发送上限（$brandLimit封）。请购买额外配额（1,000封）或明天再试。',
    'fr': 'Vous avez atteint la limite de marque ($brandLimit). Achetez un quota supplémentaire (1 000 lettres) ou réessayez demain.',
    'de': 'Sie haben das heutige Markenlimit ($brandLimit) erreicht. Kaufen Sie zusätzliches Kontingent (1.000 Briefe) oder versuchen Sie es morgen erneut.',
    'es': 'Has alcanzado el límite de marca ($brandLimit). Compra cuota extra (1.000 cartas) o inténtalo mañana.',
    'pt': 'Você atingiu o limite de marca ($brandLimit). Compre cota extra (1.000 cartas) ou tente amanhã.',
    'ru': 'Достигнут лимит бренда ($brandLimit). Купите дополнительную квоту (1 000 писем) или попробуйте завтра.',
    'tr': 'Bugünkü marka limitine ($brandLimit) ulaştınız. Ek gönderim hakkı (1.000 mektup) satın alın veya yarın deneyin.',
    'ar': 'لقد وصلت إلى حد العلامة التجارية ($brandLimit). اشترِ حصة إضافية (1,000 رسالة) أو حاول غداً.',
    'it': 'Hai raggiunto il limite brand ($brandLimit). Acquista quota aggiuntiva (1.000 lettere) o riprova domani.',
    'hi': 'आज का ब्रांड सीमा ($brandLimit) पूरी हो गई। अतिरिक्त कोटा (1,000 पत्र) खरीदें या कल पुनः प्रयास करें।',
    'th': 'ถึงขีดจำกัดแบรนด์วันนี้แล้ว ($brandLimit ฉบับ) ซื้อโควต้าเพิ่ม (1,000 ฉบับ) หรือลองใหม่พรุ่งนี้',
  });

  String stateDailyLimitPremium(int premiumLimit) => _t({
    'ko': '오늘 프리미엄 발송 한도(${premiumLimit}통)에 도달했어요. 내일 다시 시도해주세요.',
    'en': 'You\'ve reached today\'s premium limit ($premiumLimit). Please try again tomorrow.',
    'ja': '本日のプレミアム送信上限（${premiumLimit}通）に達しました。明日もう一度お試しください。',
    'zh': '已达今日高级发送上限（$premiumLimit封）。请明天再试。',
    'fr': 'Vous avez atteint la limite premium ($premiumLimit). Réessayez demain.',
    'de': 'Sie haben das heutige Premium-Limit ($premiumLimit) erreicht. Versuchen Sie es morgen erneut.',
    'es': 'Has alcanzado el límite premium ($premiumLimit). Inténtalo mañana.',
    'pt': 'Você atingiu o limite premium ($premiumLimit). Tente novamente amanhã.',
    'ru': 'Достигнут дневной премиум-лимит ($premiumLimit). Попробуйте завтра.',
    'tr': 'Bugünkü premium limitine ($premiumLimit) ulaştınız. Yarın tekrar deneyin.',
    'ar': 'لقد وصلت إلى الحد المميز ($premiumLimit). يرجى المحاولة غداً.',
    'it': 'Hai raggiunto il limite premium ($premiumLimit). Riprova domani.',
    'hi': 'आज का प्रीमियम सीमा ($premiumLimit) पूरी हो गई। कृपया कल पुनः प्रयास करें।',
    'th': 'ถึงขีดจำกัดพรีเมียมวันนี้แล้ว ($premiumLimit ฉบับ) กรุณาลองใหม่พรุ่งนี้',
  });

  String stateMonthlyLimitFreeValueCopy(int freeLimit, int premiumLimit) => _t({
    'ko': '이번 달 무료 한도(${freeLimit}통)를 모두 사용했어요.\n프리미엄으로 전환하면 월 ${premiumLimit}통까지 발송 가능해서 더 많은 국가와 연결을 만들 수 있어요.',
    'en': 'You\'ve used all $freeLimit free promos this month.\nSwitch to Premium to send up to $premiumLimit/month and connect with more countries.',
    'ja': '今月の無料枠（${freeLimit}通）を使い切りました。\nプレミアムに切り替えると月${premiumLimit}通まで送信でき、もっと多くの国とつながれます。',
    'zh': '本月免费额度（$freeLimit封）已用完。\n升级Premium月发$premiumLimit封，连接更多国家。',
    'fr': 'Vous avez utilisé vos $freeLimit lettres gratuites ce mois.\nPassez au Premium pour $premiumLimit/mois et connectez-vous avec plus de pays.',
    'de': 'Sie haben alle $freeLimit kostenlosen Briefe diesen Monat verbraucht.\nWechseln Sie zu Premium für $premiumLimit/Monat und verbinden Sie sich mit mehr Ländern.',
    'es': 'Has usado todas las $freeLimit cartas gratis este mes.\nCambia a Premium para $premiumLimit/mes y conecta con más países.',
    'pt': 'Você usou todas as $freeLimit cartas grátis este mês.\nMude para Premium para $premiumLimit/mês e conecte-se com mais países.',
    'ru': 'Вы использовали все $freeLimit бесплатных писем в этом месяце.\nПодпишитесь на Premium — $premiumLimit писем/месяц и связь с большим числом стран.',
    'tr': 'Bu ayki ücretsiz $freeLimit mektup hakkınızı kullandınız.\nPremium\'a geçerek ayda $premiumLimit mektup gönderebilir ve daha fazla ülkeyle bağlantı kurabilirsiniz.',
    'ar': 'لقد استخدمت جميع الرسائل المجانية ($freeLimit) هذا الشهر.\nانتقل إلى Premium لإرسال $premiumLimit/شهر والتواصل مع المزيد من البلدان.',
    'it': 'Hai usato tutte le $freeLimit lettere gratuite questo mese.\nPassa a Premium per $premiumLimit/mese e connettiti con più paesi.',
    'hi': 'इस महीने की $freeLimit मुफ्त पत्र सीमा समाप्त हो गई।\nPremium में बदलें - $premiumLimit पत्र/माह और अधिक देशों से जुड़ें।',
    'th': 'คุณใช้จดหมายฟรี $freeLimit ฉบับหมดแล้วเดือนนี้\nเปลี่ยนเป็น Premium ส่งได้ $premiumLimit ฉบับ/เดือน เชื่อมต่อกับประเทศต่างๆ มากขึ้น',
  });

  String stateMonthlyLimitFree(int freeLimit, int premiumLimit) => _t({
    'ko': '이번 달 발송 한도(${freeLimit}통)에 도달했어요.\n프리미엄으로 업그레이드하면 월 ${premiumLimit}통 발송 가능해요!',
    'en': 'You\'ve reached this month\'s limit ($freeLimit).\nUpgrade to Premium for $premiumLimit promos/month!',
    'ja': '今月の送信上限（${freeLimit}通）に達しました。\nプレミアムにアップグレードすると月${premiumLimit}通送信可能！',
    'zh': '已达本月发送上限（$freeLimit封）。\n升级Premium月发$premiumLimit封！',
    'fr': 'Vous avez atteint la limite mensuelle ($freeLimit).\nPassez au Premium pour $premiumLimit lettres/mois !',
    'de': 'Sie haben das Monatslimit ($freeLimit) erreicht.\nUpgraden Sie auf Premium für $premiumLimit Briefe/Monat!',
    'es': 'Has alcanzado el límite mensual ($freeLimit).\n¡Actualiza a Premium para $premiumLimit cartas/mes!',
    'pt': 'Você atingiu o limite mensal ($freeLimit).\nAtualize para Premium para $premiumLimit cartas/mês!',
    'ru': 'Достигнут месячный лимит ($freeLimit).\nОформите Premium — $premiumLimit писем/месяц!',
    'tr': 'Bu ayın limitine ($freeLimit) ulaştınız.\nPremium\'a yükselerek ayda $premiumLimit mektup gönderin!',
    'ar': 'لقد وصلت إلى الحد الشهري ($freeLimit).\nقم بالترقية إلى Premium لإرسال $premiumLimit رسالة/شهر!',
    'it': 'Hai raggiunto il limite mensile ($freeLimit).\nPassa a Premium per $premiumLimit lettere/mese!',
    'hi': 'इस महीने की सीमा ($freeLimit) पूरी हो गई।\nPremium में अपग्रेड करें - $premiumLimit पत्र/माह!',
    'th': 'ถึงขีดจำกัดเดือนนี้แล้ว ($freeLimit ฉบับ)\nอัปเกรดเป็น Premium ส่งได้ $premiumLimit ฉบับ/เดือน!',
  });

  String stateMonthlyLimitBrand(int total) => _t({
    'ko': '이번 달 브랜드 발송 한도(${total}통)에 도달했어요.\n추가 발송권(1,000통 ₩15,000)을 구매하세요.',
    'en': 'You\'ve reached this month\'s brand limit ($total).\nPurchase extra quota (1,000 promos).',
    'ja': '今月のブランド送信上限（${total}通）に達しました。\n追加送信権（1,000通）を購入してください。',
    'zh': '已达本月品牌发送上限（$total封）。\n请购买额外配额（1,000封）。',
    'fr': 'Vous avez atteint la limite mensuelle de marque ($total).\nAchetez un quota supplémentaire (1 000 lettres).',
    'de': 'Sie haben das monatliche Markenlimit ($total) erreicht.\nKaufen Sie zusätzliches Kontingent (1.000 Briefe).',
    'es': 'Has alcanzado el límite mensual de marca ($total).\nCompra cuota extra (1.000 cartas).',
    'pt': 'Você atingiu o limite mensal de marca ($total).\nCompre cota extra (1.000 cartas).',
    'ru': 'Достигнут месячный лимит бренда ($total).\nКупите дополнительную квоту (1 000 писем).',
    'tr': 'Bu ayın marka limitine ($total) ulaştınız.\nEk gönderim hakkı (1.000 mektup) satın alın.',
    'ar': 'لقد وصلت إلى الحد الشهري للعلامة التجارية ($total).\nاشترِ حصة إضافية (1,000 رسالة).',
    'it': 'Hai raggiunto il limite mensile brand ($total).\nAcquista quota aggiuntiva (1.000 lettere).',
    'hi': 'इस महीने का ब्रांड सीमा ($total) पूरी हो गई।\nअतिरिक्त कोटा (1,000 पत्र) खरीदें।',
    'th': 'ถึงขีดจำกัดแบรนด์เดือนนี้แล้ว ($total ฉบับ)\nซื้อโควต้าเพิ่ม (1,000 ฉบับ)',
  });

  String stateMonthlyLimitPremium(int premiumLimit) => _t({
    'ko': '이번 달 프리미엄 발송 한도(${premiumLimit}통)에 도달했어요. DM 쿼터 포함 기준입니다.',
    'en': 'You\'ve reached this month\'s premium limit ($premiumLimit), including DM quota.',
    'ja': '今月のプレミアム送信上限（${premiumLimit}通）に達しました。DMクォータを含みます。',
    'zh': '已达本月高级发送上限（$premiumLimit封），含私信配额。',
    'fr': 'Vous avez atteint la limite mensuelle premium ($premiumLimit), quota MP inclus.',
    'de': 'Sie haben das monatliche Premium-Limit ($premiumLimit) erreicht, inkl. DM-Kontingent.',
    'es': 'Has alcanzado el límite mensual premium ($premiumLimit), incluyendo cuota de MD.',
    'pt': 'Você atingiu o limite mensal premium ($premiumLimit), incluindo cota de MD.',
    'ru': 'Достигнут месячный премиум-лимит ($premiumLimit), включая квоту ЛС.',
    'tr': 'Bu ayın premium limitine ($premiumLimit) ulaştınız. DM kotası dahildir.',
    'ar': 'لقد وصلت إلى الحد الشهري المميز ($premiumLimit)، شاملاً حصة الرسائل المباشرة.',
    'it': 'Hai raggiunto il limite mensile premium ($premiumLimit), inclusa la quota MD.',
    'hi': 'इस महीने का प्रीमियम सीमा ($premiumLimit) पूरी हो गई। DM कोटा सहित।',
    'th': 'ถึงขีดจำกัดพรีเมียมเดือนนี้แล้ว ($premiumLimit ฉบับ) รวมโควต้า DM',
  });

  String get stateNearbyNotificationTitle => _t({
    'ko': '📩 혜택이 근처에 있어요!',
    'en': '📩 A reward is nearby!',
    'ja': '📩 近くに手紙があります！',
    'zh': '📩 附近有一封信！',
    'fr': '📩 Une lettre est à proximité !',
    'de': '📩 Ein Brief ist in der Nähe!',
    'es': '📩 ¡Hay una carta cerca!',
    'pt': '📩 Uma carta está por perto!',
    'ru': '📩 Рядом есть письмо!',
    'tr': '📩 Yakınında bir mektup var!',
    'ar': '📩 هناك رسالة بالقرب منك!',
    'it': '📩 Una lettera è nelle vicinanze!',
    'hi': '📩 पास में एक पत्र है!',
    'th': '📩 มีจดหมายอยู่ใกล้ๆ!',
  });

  String stateNearbyNotificationBody(String flag, String country) => _t({
    'ko': '$flag ${country}에서 온 혜택이 2km 이내에 도착했어요',
    'en': 'A reward from $flag $country arrived within 2km',
    'ja': '$flag ${country}からの手紙が2km以内に届きました',
    'zh': '来自$flag $country的信件已到达2km范围内',
    'fr': 'Une lettre de $flag $country est arrivée dans un rayon de 2 km',
    'de': 'Ein Brief aus $flag $country ist innerhalb von 2 km angekommen',
    'es': 'Una carta de $flag $country llegó a menos de 2 km',
    'pt': 'Uma carta de $flag $country chegou a menos de 2 km',
    'ru': 'Письмо из $flag $country прибыло в радиусе 2 км',
    'tr': '$flag $country\'den gelen mektup 2 km içinde ulaştı',
    'ar': 'وصلت رسالة من $flag $country على بعد 2 كم',
    'it': 'Una lettera da $flag $country è arrivata entro 2 km',
    'hi': '$flag $country से एक पत्र 2km के भीतर पहुंचा',
    'th': 'จดหมายจาก $flag $country มาถึงในระยะ 2 กม.',
  });

  // ── 랜덤 혜택 도착 알림 문구 풀 ─────────────────────────────────────────────
  List<String> get stateNearbyNotifTitles => [
    _t({
      'ko': '💌 랜덤 혜택이 도착했어요!',
      'en': '💌 A random reward has arrived!',
      'ja': '💌 ランダムレターが届きました！',
      'zh': '💌 随机信件到了！',
    }),
    _t({
      'ko': '🌏 세계 어딘가에서 혜택이 왔어요!',
      'en': '🌏 A reward came from somewhere in the world!',
      'ja': '🌏 世界のどこかから手紙が来ました！',
      'zh': '🌏 世界某处寄来了一封信！',
    }),
    _t({
      'ko': '🎐 바람을 타고 혜택이 날아왔어요',
      'en': '🎐 A reward drifted in on the wind',
      'ja': '🎐 風に乗って手紙が届きました',
      'zh': '🎐 一封信随风飘来',
    }),
    _t({
      'ko': '✨ 누군가의 마음이 도착했어요',
      'en': '✨ Someone\'s heart has arrived',
      'ja': '✨ 誰かの想いが届きました',
      'zh': '✨ 某人的心意到了',
    }),
    _t({
      'ko': '📬 수집첩에 새 혜택이 왔어요!',
      'en': '📬 New reward in your collection!',
      'ja': '📬 新しい手紙が届きました！',
      'zh': '📬 信箱里有新信！',
    }),
    _t({
      'ko': '🌊 바다를 건너 혜택이 도착했어요',
      'en': '🌊 A reward crossed the ocean to reach you',
      'ja': '🌊 海を越えて手紙が届きました',
      'zh': '🌊 一封信漂洋过海到达了',
    }),
    _t({
      'ko': '🕊️ 비둘기가 혜택을 물고 왔어요',
      'en': '🕊️ A dove brought you a reward',
      'ja': '🕊️ 鳩が手紙を届けてくれました',
      'zh': '🕊️ 鸽子带来了一封信',
    }),
    _t({
      'ko': '🌟 새로운 이야기가 도착했어요',
      'en': '🌟 A new story has arrived',
      'ja': '🌟 新しい物語が届きました',
      'zh': '🌟 一个新故事到了',
    }),
    _t({
      'ko': '📮 랜덤 혜택이 배달 완료!',
      'en': '📮 Random reward delivered!',
      'ja': '📮 ランダムレター配達完了！',
      'zh': '📮 随机信件已送达！',
    }),
    _t({
      'ko': '🗺️ 먼 나라에서 혜택이 도착했어요',
      'en': '🗺️ A reward arrived from a distant land',
      'ja': '🗺️ 遠い国から手紙が届きました',
      'zh': '🗺️ 远方来信了',
    }),
  ];

  List<String> stateNearbyNotifBodies(String flag, String country) => [
    _t({
      'ko': '$flag $country에서 보낸 혜택이 도착했어요',
      'en': 'A reward from $flag $country has arrived',
      'ja': '$flag ${country}からの手紙が届きました',
      'zh': '来自$flag $country的信到了',
    }),
    _t({
      'ko': '$flag $country 누군가가 당신에게 마음을 보냈어요',
      'en': 'Someone in $flag $country sent you their heart',
      'ja': '$flag ${country}の誰かがあなたに想いを送りました',
      'zh': '$flag $country有人给你寄了心意',
    }),
    _t({
      'ko': '$flag $country에서 출발한 혜택이 드디어 도착!',
      'en': 'A reward from $flag $country finally arrived!',
      'ja': '$flag ${country}から出発した手紙がついに到着！',
      'zh': '从$flag $country出发的信终于到了！',
    }),
    _t({
      'ko': '$flag $country의 마음이 담긴 혜택이 왔어요',
      'en': 'A heartfelt reward from $flag $country is here',
      'ja': '$flag ${country}の気持ちが込められた手紙が来ました',
      'zh': '来自$flag $country的真挚信件到了',
    }),
    _t({
      'ko': '$flag $country에서 온 혜택을 지금 열어보세요',
      'en': 'Open the reward from $flag $country now',
      'ja': '$flag ${country}からの手紙を今すぐ開きましょう',
      'zh': '快打开来自$flag $country的信吧',
    }),
    _t({
      'ko': '바다를 건너온 $flag $country의 진심을 확인하세요',
      'en': 'Check the heartfelt message from $flag $country',
      'ja': '海を渡ってきた$flag ${country}の真心を確認しましょう',
      'zh': '查看漂洋过海来自$flag $country的真心',
    }),
    _t({
      'ko': '$flag $country에서 온 혜택병이 도착했어요 🏖️',
      'en': 'A bottle reward from $flag $country arrived 🏖️',
      'ja': '$flag ${country}からのボトルレターが届きました 🏖️',
      'zh': '来自$flag $country的漂流瓶到了 🏖️',
    }),
    _t({
      'ko': '$flag $country 혜택이 긴 여행을 마치고 도착했어요',
      'en': 'A $flag $country reward finished its long journey',
      'ja': '$flag ${country}の手紙が長い旅を終えて届きました',
      'zh': '$flag $country的信完成了漫长旅程',
    }),
  ];

  String stateMinSec(int min, int sec) => _t({
    'ko': '${min}분 ${sec}초',
    'en': '${min}m ${sec}s',
    'ja': '${min}分${sec}秒',
    'zh': '${min}分${sec}秒',
    'fr': '${min}min ${sec}s',
    'de': '${min}Min ${sec}Sek',
    'es': '${min}min ${sec}s',
    'pt': '${min}min ${sec}s',
    'ru': '${min}мин ${sec}сек',
    'tr': '${min}dk ${sec}sn',
    'ar': '${min}د ${sec}ث',
    'it': '${min}min ${sec}s',
    'hi': '${min}मिनट ${sec}सेकंड',
    'th': '${min}นาที ${sec}วินาที',
  });

  String stateSec(int sec) => _t({
    'ko': '${sec}초',
    'en': '${sec}s',
    'ja': '${sec}秒',
    'zh': '${sec}秒',
    'fr': '${sec}s',
    'de': '${sec}Sek',
    'es': '${sec}s',
    'pt': '${sec}s',
    'ru': '${sec}сек',
    'tr': '${sec}sn',
    'ar': '${sec}ث',
    'it': '${sec}s',
    'hi': '${sec}सेकंड',
    'th': '${sec}วินาที',
  });

  String get stateTierPremium10min => _t({
    'ko': '프리미엄 10분',
    'en': 'Premium 10min',
    'ja': 'プレミアム10分',
    'zh': '高级10分钟',
    'fr': 'Premium 10min',
    'de': 'Premium 10Min',
    'es': 'Premium 10min',
    'pt': 'Premium 10min',
    'ru': 'Премиум 10мин',
    'tr': 'Premium 10dk',
    'ar': 'مميز 10 دقائق',
    'it': 'Premium 10min',
    'hi': 'प्रीमियम 10मिनट',
    'th': 'พรีเมียม 10นาที',
  });

  String get stateTierFree1hour => _t({
    'ko': '일반 1시간',
    'en': 'Free 1 hour',
    'ja': '無料1時間',
    'zh': '免费1小时',
    'fr': 'Gratuit 1 heure',
    'de': 'Kostenlos 1 Stunde',
    'es': 'Gratis 1 hora',
    'pt': 'Grátis 1 hora',
    'ru': 'Бесплатно 1 час',
    'tr': 'Ücretsiz 1 saat',
    'ar': 'مجاني ساعة واحدة',
    'it': 'Gratuito 1 ora',
    'hi': 'मुफ्त 1 घंटा',
    'th': 'ฟรี 1 ชั่วโมง',
  });

  String statePickupCooldown(String timeStr, String tier) => _t({
    'ko': '⏳ $timeStr 후 줍기 가능 ($tier 쿨다운)',
    'en': '⏳ Pick up available in $timeStr ($tier cooldown)',
    'ja': '⏳ ${timeStr}後に拾えます（${tier}クールダウン）',
    'zh': '⏳ $timeStr后可拾取（$tier冷却）',
    'fr': '⏳ Ramassage disponible dans $timeStr (délai $tier)',
    'de': '⏳ Aufheben möglich in $timeStr ($tier Abklingzeit)',
    'es': '⏳ Recogida disponible en $timeStr (enfriamiento $tier)',
    'pt': '⏳ Coleta disponível em $timeStr (cooldown $tier)',
    'ru': '⏳ Можно поднять через $timeStr (перезарядка $tier)',
    'tr': '⏳ $timeStr sonra alınabilir ($tier bekleme süresi)',
    'ar': '⏳ يمكن الالتقاط بعد $timeStr (فترة التبريد $tier)',
    'it': '⏳ Ritiro disponibile tra $timeStr (cooldown $tier)',
    'hi': '⏳ $timeStr में उठा सकते हैं ($tier कूलडाउन)',
    'th': '⏳ เก็บได้ใน $timeStr (คูลดาวน์ $tier)',
  });

  // ── 쿨다운 중 근처 혜택 알림 ──────────────────────────────────────────────
  String get stateCooldownNearbyTitle => _t({
    'ko': '⏳ 혜택이 근처에 있어요!',
    'en': '⏳ A reward is nearby!',
    'ja': '⏳ 手紙が近くにあります！',
    'zh': '⏳ 附近有一封信！',
    'fr': '⏳ Une lettre est à proximité !',
    'de': '⏳ Ein Brief ist in der Nähe!',
    'es': '⏳ ¡Hay una carta cerca!',
    'pt': '⏳ Uma carta está por perto!',
    'ru': '⏳ Рядом есть письмо!',
    'tr': '⏳ Yakınında bir mektup var!',
    'ar': '⏳ هناك رسالة بالقرب منك!',
    'it': '⏳ Una lettera è nelle vicinanze!',
    'hi': '⏳ आपके पास एक पत्र है!',
    'th': '⏳ มีจดหมายอยู่ใกล้ๆ!',
  });

  String stateCooldownNearbyBody(String flag, String country, String timeStr) => _t({
    'ko': '$flag $country에서 온 혜택이 근처에 있지만, $timeStr 후에 수령할 수 있어요',
    'en': 'A reward from $flag $country is nearby, but you can pick it up in $timeStr',
    'ja': '$flag ${country}からの手紙が近くにありますが、${timeStr}後に受け取れます',
    'zh': '来自$flag $country的信在附近，但$timeStr后才能领取',
    'fr': 'Une lettre de $flag $country est proche, ramassage dans $timeStr',
    'de': 'Ein Brief aus $flag $country ist in der Nähe, abholbar in $timeStr',
    'es': 'Una carta de $flag $country está cerca, recógela en $timeStr',
    'pt': 'Uma carta de $flag $country está por perto, colete em $timeStr',
    'ru': 'Письмо из $flag $country рядом, можно забрать через $timeStr',
    'tr': '$flag $country\'den bir mektup yakınında, $timeStr sonra alabilirsiniz',
    'ar': 'رسالة من $flag $country بالقرب منك، يمكنك استلامها بعد $timeStr',
    'it': 'Una lettera da $flag $country è vicina, ritiro tra $timeStr',
    'hi': '$flag $country से एक पत्र पास में है, $timeStr बाद उठा सकते हैं',
    'th': 'จดหมายจาก $flag $country อยู่ใกล้ แต่เก็บได้ใน $timeStr',
  });

  // ── 신고 임시 차단 알림 (발송자에게) ───────────────────────────────────────
  String get stateReportBlockTitle => _t({
    'ko': '⚠️ 혜택이 신고되었습니다',
    'en': '⚠️ Your promo has been reported',
    'ja': '⚠️ あなたの手紙が通報されました',
    'zh': '⚠️ 您的信件被举报了',
    'fr': '⚠️ Votre lettre a été signalée',
    'de': '⚠️ Ihr Brief wurde gemeldet',
    'es': '⚠️ Tu carta ha sido reportada',
    'pt': '⚠️ Sua carta foi denunciada',
    'ru': '⚠️ На ваше письмо пожаловались',
    'tr': '⚠️ Mektubunuz bildirildi',
    'ar': '⚠️ تم الإبلاغ عن رسالتك',
    'it': '⚠️ La tua lettera è stata segnalata',
    'hi': '⚠️ आपका पत्र रिपोर्ट किया गया',
    'th': '⚠️ จดหมายของคุณถูกรายงาน',
  });

  String get stateReportBlockBody => _t({
    'ko': '신고 접수로 홍보 발송이 일시 제한됩니다. 관리자 검토 후 조치됩니다.',
    'en': 'Your promo sending is temporarily restricted due to a report. An admin will review shortly.',
    'ja': '通報により手紙の送信が一時制限されています。管理者が確認後、対応します。',
    'zh': '由于举报，您的信件发送已暂时限制。管理员将尽快审核。',
    'fr': 'L\'envoi de lettres est temporairement restreint suite à un signalement. Un administrateur examinera sous peu.',
    'de': 'Ihr Briefversand ist vorübergehend eingeschränkt. Ein Administrator wird dies überprüfen.',
    'es': 'El envío de cartas está temporalmente restringido por un reporte. Un administrador lo revisará pronto.',
    'pt': 'O envio de cartas está temporariamente restrito. Um administrador revisará em breve.',
    'ru': 'Отправка писем временно ограничена из-за жалобы. Администратор скоро проверит.',
    'tr': 'Bir bildirim nedeniyle mektup gönderimi geçici olarak kısıtlandı. Yönetici yakında inceleyecek.',
    'ar': 'تم تقييد إرسال الرسائل مؤقتاً بسبب بلاغ. سيقوم المسؤول بالمراجعة قريباً.',
    'it': 'L\'invio di lettere è temporaneamente limitato. Un amministratore esaminerà a breve.',
    'hi': 'रिपोर्ट के कारण पत्र भेजना अस्थायी रूप से प्रतिबंधित है। व्यवस्थापक जल्द समीक्षा करेगा।',
    'th': 'การส่งจดหมายถูกจำกัดชั่วคราว ผู้ดูแลระบบจะตรวจสอบเร็วๆ นี้',
  });

  String get stateAlreadyRead => _t({
    'ko': '이미 읽은 혜택이에요 📖',
    'en': 'You\'ve already read this reward 📖',
    'ja': 'すでに読んだ手紙です 📖',
    'zh': '这封信已经读过了 📖',
    'fr': 'Vous avez déjà lu cette lettre 📖',
    'de': 'Sie haben diesen Brief bereits gelesen 📖',
    'es': 'Ya leíste esta carta 📖',
    'pt': 'Você já leu esta carta 📖',
    'ru': 'Вы уже читали это письмо 📖',
    'tr': 'Bu mektubu zaten okudunuz 📖',
    'ar': 'لقد قرأت هذه الرسالة بالفعل 📖',
    'it': 'Hai già letto questa lettera 📖',
    'hi': 'यह पत्र पहले ही पढ़ लिया गया 📖',
    'th': 'อ่านจดหมายนี้แล้ว 📖',
  });

  String get inboxHuntHint => _t({
    'ko': '주변에 뿌려진 할인권·이벤트 혜택을 주워 활용해보세요',
    'en': 'Pick up discount and event rewards dropped nearby to redeem',
    'ja': '近くに落ちている割引券・イベントの手紙を拾って使ってみて',
    'zh': '拾取附近的折扣券和活动信件即可兑换',
    'fr': 'Ramassez les réductions et événements lâchés près de vous',
    'de': 'Sammle Rabatt- und Event-Briefe in deiner Nähe',
    'es': 'Recoge cartas de descuento y eventos cercanas para usarlas',
    'pt': 'Pegue cartas de desconto e eventos próximas para resgatar',
    'ru': 'Подбирайте скидки и анонсы событий поблизости',
    'tr': 'Yakındaki indirim ve etkinlik mektuplarını topla ve kullan',
    'ar': 'التقط رسائل الخصومات والفعاليات القريبة واستفد منها',
    'it': 'Raccogli lettere di sconti ed eventi vicino a te',
    'hi': 'आसपास गिरे छूट/इवेंट पत्र उठाएँ और उपयोग करें',
    'th': 'เก็บจดหมายส่วนลด/กิจกรรมรอบตัวเพื่อใช้สิทธิ์',
  });

  String get brandOnlySendTitle => _t({
    'ko': '📣 발송 전용 브랜드 계정',
    'en': '📣 Broadcast-only Brand account',
    'ja': '📣 発信専用ブランドアカウント',
    'zh': '📣 仅发送的品牌账号',
    'fr': '📣 Compte Marque — envoi uniquement',
    'de': '📣 Marke: Nur Versand',
    'es': '📣 Cuenta Marca — solo envío',
    'pt': '📣 Conta Marca — apenas envio',
    'ru': '📣 Бренд — только отправка',
    'tr': '📣 Yalnızca gönderim — Marka',
    'ar': '📣 حساب علامة — إرسال فقط',
    'it': '📣 Brand — solo invio',
    'hi': '📣 ब्रांड — केवल भेजें',
    'th': '📣 แบรนด์ — ส่งเท่านั้น',
  });
  String get brandOnlySendBody => _t({
    'ko': '홍보·이벤트·할인 혜택을 지구 곳곳에 뿌려보세요. 혜택 줍기는 일반·프리미엄 회원의 메리트예요.',
    'en': 'Drop promos, events, and discounts around the world. Picking rewards up is the Free/Premium member\'s perk.',
    'ja': '告知・イベント・割引の手紙を世界に配ってください。拾うのは一般・プレミアム会員の特典です。',
    'zh': '把宣传、活动和折扣信件撒到世界各地。收取是普通/高级会员的专属福利。',
    'fr': 'Diffusez promos, événements et réductions dans le monde. Le ramassage est l\'avantage Free/Premium.',
    'de': 'Verbreite Promos, Events und Rabatte weltweit. Abholen bleibt Free/Premium-Mitgliedern vorbehalten.',
    'es': 'Lanza promociones, eventos y descuentos por el mundo. Recoger es el privilegio Free/Premium.',
    'pt': 'Espalhe promos, eventos e descontos pelo mundo. Recolher é o benefício Free/Premium.',
    'ru': 'Рассыпайте акции, события и скидки по миру. Подбирать могут только Free/Premium.',
    'tr': 'Promosyon, etkinlik ve indirim mektuplarını dünyaya yayın. Toplamak Free/Premium ayrıcalığı.',
    'ar': 'انشر العروض والفعاليات والخصومات حول العالم. الالتقاط ميزة Free/Premium.',
    'it': 'Distribuisci promo, eventi e sconti nel mondo. Il ritiro è vantaggio Free/Premium.',
    'hi': 'प्रचार/इवेंट/छूट पत्र दुनिया में बिखेरें। उठाना Free/Premium सदस्यों का लाभ है।',
    'th': 'กระจายโปร, กิจกรรม, ส่วนลดไปทั่วโลก การเก็บเป็นสิทธิ์ของสมาชิก Free/Premium',
  });

  String get statePickupBrandBlocked => _t({
    'ko': '브랜드 계정은 홍보를 보내는 데만 사용돼요 · 픽업은 일반·프리미엄 회원 전용이에요',
    'en': 'Brand accounts can only send promos — pickup is for Free / Premium members',
    'ja': 'ブランドアカウントは送信専用です — 受け取りは一般・プレミアム会員のみ',
    'zh': '品牌账号只能发送信件 · 收取仅限普通/高级会员',
    'fr': 'Les comptes Marque ne peuvent qu\'envoyer — le ramassage est réservé aux membres Free/Premium',
    'de': 'Markenkonten können nur senden — Abholung ist für Free/Premium-Mitglieder',
    'es': 'Las cuentas Marca solo pueden enviar — la recogida es solo para Free/Premium',
    'pt': 'Contas Marca só podem enviar — coleta é apenas para membros Free/Premium',
    'ru': 'Аккаунты брендов только отправляют — подбирать могут только Free/Premium',
    'tr': 'Marka hesapları yalnızca gönderebilir — toplama Free/Premium üyelere özel',
    'ar': 'حسابات العلامات التجارية للإرسال فقط — الالتقاط لأعضاء مجاني/بريميوم',
    'it': 'Gli account Brand possono solo inviare — il ritiro è per membri Free/Premium',
    'hi': 'ब्रांड खाते केवल भेज सकते हैं — उठाना Free/Premium सदस्यों के लिए',
    'th': 'บัญชีแบรนด์ใช้เพื่อส่งเท่านั้น · การเก็บเฉพาะสมาชิก Free/Premium',
  });

  String get stateAlreadyTaken => _t({
    'ko': '누군가 이미 가져간 혜택이에요 😢',
    'en': 'Someone already took this reward 😢',
    'ja': '誰かがすでに持って行った手紙です 😢',
    'zh': '这封信已经被别人拿走了 😢',
    'fr': 'Quelqu\'un a déjà pris cette lettre 😢',
    'de': 'Jemand hat diesen Brief bereits mitgenommen 😢',
    'es': 'Alguien ya tomó esta carta 😢',
    'pt': 'Alguém já pegou esta carta 😢',
    'ru': 'Кто-то уже забрал это письмо 😢',
    'tr': 'Birisi bu mektubu çoktan aldı 😢',
    'ar': 'شخص ما أخذ هذه الرسالة بالفعل 😢',
    'it': 'Qualcuno ha già preso questa lettera 😢',
    'hi': 'किसी ने पहले ही यह पत्र ले लिया 😢',
    'th': 'มีคนเก็บจดหมายนี้ไปแล้ว 😢',
  });

  String stateMaxReadersReached(int maxReaders) => _t({
    'ko': '이미 ${maxReaders}명이 읽은 혜택이에요 📪',
    'en': 'This reward has already been read by $maxReaders people 📪',
    'ja': 'すでに${maxReaders}人が読んだ手紙です 📪',
    'zh': '这封信已经被$maxReaders人读过了 📪',
    'fr': 'Cette lettre a déjà été lue par $maxReaders personnes 📪',
    'de': 'Dieser Brief wurde bereits von $maxReaders Personen gelesen 📪',
    'es': 'Esta carta ya fue leída por $maxReaders personas 📪',
    'pt': 'Esta carta já foi lida por $maxReaders pessoas 📪',
    'ru': 'Это письмо уже прочитали $maxReaders человек 📪',
    'tr': 'Bu mektup zaten $maxReaders kişi tarafından okundu 📪',
    'ar': 'تمت قراءة هذه الرسالة من قبل $maxReaders أشخاص 📪',
    'it': 'Questa lettera è già stata letta da $maxReaders persone 📪',
    'hi': 'यह पत्र पहले ही $maxReaders लोगों ने पढ़ लिया 📪',
    'th': 'จดหมายนี้ถูกอ่านแล้ว $maxReaders คน 📪',
  });

  String get stateDistanceTooFar => _t({
    'ko': '📍 혜택 수령지 2km 이내에 있어야 받을 수 있어요',
    'en': '📍 You must be within 2km of the reward\'s destination to pick it up',
    'ja': '📍 手紙の受取地点から2km以内にいる必要があります',
    'zh': '📍 您需要在信件目的地2km范围内才能领取',
    'fr': '📍 Vous devez être à moins de 2 km de la destination pour récupérer la lettre',
    'de': '📍 Sie müssen innerhalb von 2 km vom Briefziel sein, um ihn abzuholen',
    'es': '📍 Debes estar a menos de 2 km del destino para recoger la carta',
    'pt': '📍 Você precisa estar a menos de 2 km do destino para pegar a carta',
    'ru': '📍 Вы должны быть в пределах 2 км от адресата, чтобы забрать письмо',
    'tr': '📍 Mektubu almak için 2 km içinde olmalısınız',
    'ar': '📍 يجب أن تكون على بعد 2 كم من وجهة الرسالة لاستلامها',
    'it': '📍 Devi essere entro 2 km dalla destinazione per ritirare la lettera',
    'hi': '📍 पत्र लेने के लिए गंतव्य के 2km के भीतर होना आवश्यक है',
    'th': '📍 ต้องอยู่ภายในระยะ 2 กม. จากจุดหมายจดหมายจึงจะเก็บได้',
  });

  String get stateDmReply1 => _t({
    'ko': '정말요? 저도 그렇게 생각해요! 😊',
    'en': 'Really? I think so too! 😊',
    'ja': '本当ですか？私もそう思います！ 😊',
    'zh': '真的吗？我也这么想！ 😊',
    'fr': 'Vraiment ? Je pense pareil ! 😊',
    'de': 'Wirklich? Das denke ich auch! 😊',
    'es': '¿En serio? ¡Yo también lo creo! 😊',
    'pt': 'Sério? Eu também acho! 😊',
    'ru': 'Правда? Я тоже так думаю! 😊',
    'tr': 'Gerçekten mi? Ben de öyle düşünüyorum! 😊',
    'ar': 'حقاً؟ أنا أيضاً أعتقد ذلك! 😊',
    'it': 'Davvero? Anch\'io la penso così! 😊',
    'hi': 'सच में? मैं भी ऐसा ही सोचता हूं! 😊',
    'th': 'จริงเหรอ? ฉันก็คิดแบบนั้นเหมือนกัน! 😊',
  });

  String get stateDmReply2 => _t({
    'ko': '혜택으로 이렇게 대화할 수 있다니 신기해요',
    'en': 'It\'s amazing we can chat like this through rewards',
    'ja': '手紙でこうやって会話できるなんて不思議です',
    'zh': '能通过信件这样聊天真是太神奇了',
    'fr': 'C\'est incroyable de pouvoir discuter ainsi par lettres',
    'de': 'Es ist erstaunlich, dass wir so per Brief chatten können',
    'es': 'Es increíble poder conversar así por cartas',
    'pt': 'É incrível poder conversar assim por cartas',
    'ru': 'Удивительно, что можно так общаться через письма',
    'tr': 'Mektuplarla böyle sohbet edebilmek harika',
    'ar': 'من المدهش أن نتمكن من الدردشة هكذا عبر الرسائل',
    'it': 'È incredibile poter chattare così tramite lettere',
    'hi': 'पत्रों के माध्यम से ऐसे बात करना अद्भुत है',
    'th': 'น่าทึ่งที่เราคุยกันได้แบบนี้ผ่านจดหมาย',
  });

  String get stateDmReply3 => _t({
    'ko': '언젠가 직접 만날 수 있으면 좋겠어요 ✨',
    'en': 'I hope we can meet in person someday ✨',
    'ja': 'いつか直接会えたらいいですね ✨',
    'zh': '希望有一天能见面 ✨',
    'fr': 'J\'espère qu\'on pourra se rencontrer un jour ✨',
    'de': 'Ich hoffe, wir können uns eines Tages persönlich treffen ✨',
    'es': 'Espero que podamos conocernos algún día ✨',
    'pt': 'Espero que possamos nos encontrar algum dia ✨',
    'ru': 'Надеюсь, однажды мы сможем встретиться лично ✨',
    'tr': 'Umarım bir gün yüz yüze tanışabiliriz ✨',
    'ar': 'آمل أن نلتقي شخصياً يوماً ما ✨',
    'it': 'Spero di poterti incontrare di persona un giorno ✨',
    'hi': 'उम्मीद है कि किसी दिन व्यक्तिगत रूप से मिल सकेंगे ✨',
    'th': 'หวังว่าวันหนึ่งเราจะได้พบกัน ✨',
  });

  String get stateDmReply4 => _t({
    'ko': '당신의 이야기가 궁금해요. 더 들려주세요!',
    'en': 'I\'m curious about your story. Tell me more!',
    'ja': 'あなたの話が気になります。もっと聞かせてください！',
    'zh': '很好奇你的故事，请多告诉我一些！',
    'fr': 'Je suis curieux de ton histoire. Raconte-moi !',
    'de': 'Ich bin neugierig auf deine Geschichte. Erzähl mir mehr!',
    'es': 'Tengo curiosidad por tu historia. ¡Cuéntame más!',
    'pt': 'Estou curioso sobre sua história. Conte-me mais!',
    'ru': 'Мне интересна ваша история. Расскажите больше!',
    'tr': 'Hikayeni merak ediyorum. Daha fazla anlat!',
    'ar': 'أنا فضولي بشأن قصتك. أخبرني المزيد!',
    'it': 'Sono curioso della tua storia. Raccontami di più!',
    'hi': 'आपकी कहानी जानने को उत्सुक हूं। और बताइए!',
    'th': 'อยากรู้เรื่องราวของคุณ เล่าให้ฟังอีกหน่อยสิ!',
  });

  String get stateDmReply5 => _t({
    'ko': '저도 비슷한 경험이 있어요. 공감이 가네요',
    'en': 'I\'ve had a similar experience. I can relate',
    'ja': '私も似たような経験があります。共感します',
    'zh': '我也有类似的经历，很有共鸣',
    'fr': 'J\'ai vécu quelque chose de similaire. Je comprends',
    'de': 'Ich hatte eine ähnliche Erfahrung. Ich kann das nachvollziehen',
    'es': 'Tuve una experiencia similar. Lo entiendo',
    'pt': 'Tive uma experiência semelhante. Entendo perfeitamente',
    'ru': 'У меня был похожий опыт. Понимаю вас',
    'tr': 'Benzer bir deneyimim oldu. Anlayabiliyorum',
    'ar': 'مررت بتجربة مماثلة. أستطيع أن أتفهم ذلك',
    'it': 'Ho avuto un\'esperienza simile. Capisco perfettamente',
    'hi': 'मेरा भी ऐसा ही अनुभव रहा है। सहानुभूति है',
    'th': 'ฉันเคยมีประสบการณ์คล้ายๆ กัน เข้าใจเลย',
  });

  String get stateDmReply6 => _t({
    'ko': '와, 정말요? 그 나라는 어때요?',
    'en': 'Wow, really? What\'s that country like?',
    'ja': 'わぁ、本当ですか？その国はどんな感じですか？',
    'zh': '哇，真的吗？那个国家怎么样？',
    'fr': 'Waouh, vraiment ? Comment est ce pays ?',
    'de': 'Wow, wirklich? Wie ist dieses Land?',
    'es': '¡Wow, en serio? ¿Cómo es ese país?',
    'pt': 'Uau, sério? Como é esse país?',
    'ru': 'Ого, правда? Какая эта страна?',
    'tr': 'Vay, gerçekten mi? O ülke nasıl?',
    'ar': 'واو، حقاً؟ كيف هو ذلك البلد؟',
    'it': 'Wow, davvero? Com\'è quel paese?',
    'hi': 'वाह, सच में? वह देश कैसा है?',
    'th': 'ว้าว จริงเหรอ? ประเทศนั้นเป็นยังไงบ้าง?',
  });

  String get stateDmReply7 => _t({
    'ko': '너무 좋은 말이에요. 감사해요 💌',
    'en': 'That\'s so kind. Thank you 💌',
    'ja': 'とても素敵な言葉です。ありがとう 💌',
    'zh': '说得太好了，谢谢 💌',
    'fr': 'C\'est si gentil. Merci 💌',
    'de': 'Das ist sehr nett. Danke 💌',
    'es': 'Qué bonitas palabras. Gracias 💌',
    'pt': 'Que palavras lindas. Obrigado 💌',
    'ru': 'Как красиво сказано. Спасибо 💌',
    'tr': 'Çok güzel bir söz. Teşekkürler 💌',
    'ar': 'كلام جميل جداً. شكراً لك 💌',
    'it': 'Che belle parole. Grazie 💌',
    'hi': 'बहुत अच्छी बात है। धन्यवाद 💌',
    'th': 'พูดดีจังเลย ขอบคุณนะ 💌',
  });

  // ── Settings / Onboarding / Widgets ─────────────────────────────────
// ── Settings Screen ─────────────────────────────────────────────────────────

  String get settingsSubscription => _t({
    'ko': '구독',
    'en': 'Subscription',
    'ja': 'サブスクリプション',
    'zh': '订阅',
    'fr': 'Abonnement',
    'de': 'Abonnement',
    'es': 'Suscripción',
    'pt': 'Assinatura',
    'ru': 'Подписка',
    'tr': 'Abonelik',
    'ar': 'الاشتراك',
    'it': 'Abbonamento',
    'hi': 'सदस्यता',
    'th': 'การสมัครสมาชิก',
  });

  String get settingsBrandActive => _t({
    'ko': 'Brand 이용 중',
    'en': 'Brand Active',
    'ja': 'Brand 利用中',
    'zh': 'Brand 使用中',
    'fr': 'Brand actif',
    'de': 'Brand aktiv',
    'es': 'Brand activo',
    'pt': 'Brand ativo',
    'ru': 'Brand активен',
    'tr': 'Brand aktif',
    'ar': 'Brand نشط',
    'it': 'Brand attivo',
    'hi': 'Brand सक्रिय',
    'th': 'Brand ใช้งานอยู่',
  });

  String get settingsPremiumActive => _t({
    'ko': 'Premium 이용 중',
    'en': 'Premium Active',
    'ja': 'Premium 利用中',
    'zh': 'Premium 使用中',
    'fr': 'Premium actif',
    'de': 'Premium aktiv',
    'es': 'Premium activo',
    'pt': 'Premium ativo',
    'ru': 'Premium активен',
    'tr': 'Premium aktif',
    'ar': 'Premium نشط',
    'it': 'Premium attivo',
    'hi': 'Premium सक्रिय',
    'th': 'Premium ใช้งานอยู่',
  });

  String get settingsPremiumUpgrade => _t({
    'ko': 'Premium 업그레이드',
    'en': 'Upgrade to Premium',
    'ja': 'Premium にアップグレード',
    'zh': '升级到 Premium',
    'fr': 'Passer à Premium',
    'de': 'Auf Premium upgraden',
    'es': 'Mejorar a Premium',
    'pt': 'Atualizar para Premium',
    'ru': 'Обновить до Premium',
    'tr': "Premium'a yükselt",
    'ar': 'الترقية إلى Premium',
    'it': 'Passa a Premium',
    'hi': 'Premium में अपग्रेड करें',
    'th': 'อัปเกรดเป็น Premium',
  });

  String get settingsBrandDesc => _t({
    'ko': '인증 브랜드 계정 · 구독 관리',
    'en': 'Verified brand account · Manage subscription',
    'ja': '認証ブランドアカウント · サブスク管理',
    'zh': '认证品牌账号 · 管理订阅',
    'fr': 'Compte de marque vérifié · Gérer l\'abonnement',
    'de': 'Verifiziertes Markenkonto · Abo verwalten',
    'es': 'Cuenta de marca verificada · Gestionar suscripción',
    'pt': 'Conta de marca verificada · Gerenciar assinatura',
    'ru': 'Подтверждённый бренд · Управление подпиской',
    'tr': 'Onaylı marka hesabı · Abonelik yönetimi',
    'ar': 'حساب علامة تجارية موثق · إدارة الاشتراك',
    'it': 'Account brand verificato · Gestisci abbonamento',
    'hi': 'सत्यापित ब्रांड खाता · सदस्यता प्रबंधन',
    'th': 'บัญชีแบรนด์ยืนยันแล้ว · จัดการการสมัคร',
  });

  String get settingsPremiumDesc => _t({
    'ko': '하루 30통 · 사진 첨부(20통) · 월 500통',
    'en': '30/day · Photos (20/day) · 500/month',
    'ja': '1日30通 · 写真添付(20通) · 月500通',
    'zh': '每天30封 · 附照片(20封) · 每月500封',
    'fr': '30/jour · Photos (20/jour) · 500/mois',
    'de': '30/Tag · Fotos (20/Tag) · 500/Monat',
    'es': '30/día · Fotos (20/día) · 500/mes',
    'pt': '30/dia · Fotos (20/dia) · 500/mês',
    'ru': '30/день · Фото (20/день) · 500/месяц',
    'tr': '30/gün · Fotoğraf (20/gün) · 500/ay',
    'ar': '30/يوم · صور (20/يوم) · 500/شهر',
    'it': '30/giorno · Foto (20/giorno) · 500/mese',
    'hi': '30/दिन · फ़ोटो (20/दिन) · 500/माह',
    'th': '30/วัน · แนบรูป (20/วัน) · 500/เดือน',
  });

  String get settingsFreeDesc => _t({
    'ko': '하루 3통 · 사진 첨부 불가 · 월 100통',
    'en': '3/day · No photos · 100/month',
    'ja': '1日3通 · 写真添付不可 · 月100通',
    'zh': '每天3封 · 无法附照片 · 每月100封',
    'fr': '3/jour · Pas de photos · 100/mois',
    'de': '3/Tag · Keine Fotos · 100/Monat',
    'es': '3/día · Sin fotos · 100/mes',
    'pt': '3/dia · Sem fotos · 100/mês',
    'ru': '3/день · Без фото · 100/месяц',
    'tr': '3/gün · Fotoğraf yok · 100/ay',
    'ar': '3/يوم · بدون صور · 100/شهر',
    'it': '3/giorno · Nessuna foto · 100/mese',
    'hi': '3/दिन · फ़ोटो नहीं · 100/माह',
    'th': '3/วัน · ไม่มีรูป · 100/เดือน',
  });

  String get settingsNickname => _t({
    'ko': '닉네임',
    'en': 'Nickname',
    'ja': 'ニックネーム',
    'zh': '昵称',
    'fr': 'Pseudo',
    'de': 'Spitzname',
    'es': 'Apodo',
    'pt': 'Apelido',
    'ru': 'Никнейм',
    'tr': 'Takma ad',
    'ar': 'الاسم المستعار',
    'it': 'Soprannome',
    'hi': 'उपनाम',
    'th': 'ชื่อเล่น',
  });

  String get settingsNotSet => _t({
    'ko': '미설정',
    'en': 'Not set',
    'ja': '未設定',
    'zh': '未设置',
    'fr': 'Non défini',
    'de': 'Nicht festgelegt',
    'es': 'No configurado',
    'pt': 'Não definido',
    'ru': 'Не задано',
    'tr': 'Ayarlanmadı',
    'ar': 'غير محدد',
    'it': 'Non impostato',
    'hi': 'सेट नहीं',
    'th': 'ยังไม่ตั้ง',
  });

  String get settingsNotifyNearbyDesc => _t({
    'ko': '2km 이내에 혜택이 도착하면 알림',
    'en': 'Notify when a reward arrives within 2km',
    'ja': '2km以内に手紙が届くと通知',
    'zh': '2km内有信件到达时通知',
    'fr': 'Notification quand une lettre arrive à moins de 2 km',
    'de': 'Benachrichtigung bei Brief innerhalb von 2 km',
    'es': 'Notificar cuando una carta llegue a menos de 2 km',
    'pt': 'Notificar quando uma carta chegar a 2 km',
    'ru': 'Уведомлять, когда письмо прибывает в пределах 2 км',
    'tr': '2 km içinde bir mektup geldiğinde bildir',
    'ar': 'إشعار عند وصول رسالة ضمن 2 كم',
    'it': 'Notifica quando una lettera arriva entro 2 km',
    'hi': '2 किमी के भीतर पत्र आने पर सूचित करें',
    'th': 'แจ้งเตือนเมื่อจดหมายมาถึงภายใน 2 กม.',
  });

  String get settingsDisplay => _t({
    'ko': '화면',
    'en': 'Display',
    'ja': '表示',
    'zh': '显示',
    'fr': 'Affichage',
    'de': 'Anzeige',
    'es': 'Pantalla',
    'pt': 'Exibição',
    'ru': 'Экран',
    'tr': 'Görünüm',
    'ar': 'العرض',
    'it': 'Schermo',
    'hi': 'प्रदर्शन',
    'th': 'การแสดงผล',
  });

  String get settingsDisplayMode => _t({
    'ko': '화면 모드',
    'en': 'Display Mode',
    'ja': '表示モード',
    'zh': '显示模式',
    'fr': 'Mode d\'affichage',
    'de': 'Anzeigemodus',
    'es': 'Modo de pantalla',
    'pt': 'Modo de exibição',
    'ru': 'Режим экрана',
    'tr': 'Görünüm modu',
    'ar': 'وضع العرض',
    'it': 'Modalità schermo',
    'hi': 'डिस्प्ले मोड',
    'th': 'โหมดแสดงผล',
  });

  String get settingsThemeSelect => _t({
    'ko': '화면 모드 선택',
    'en': 'Select Display Mode',
    'ja': '表示モードを選択',
    'zh': '选择显示模式',
    'fr': 'Choisir le mode d\'affichage',
    'de': 'Anzeigemodus wählen',
    'es': 'Seleccionar modo de pantalla',
    'pt': 'Selecionar modo de exibição',
    'ru': 'Выбрать режим экрана',
    'tr': 'Görünüm modunu seç',
    'ar': 'اختر وضع العرض',
    'it': 'Seleziona modalità schermo',
    'hi': 'डिस्प्ले मोड चुनें',
    'th': 'เลือกโหมดแสดงผล',
  });

  String get settingsThemeAuto => _t({
    'ko': '자동 (시간대)',
    'en': 'Auto (Time zone)',
    'ja': '自動 (タイムゾーン)',
    'zh': '自动 (时区)',
    'fr': 'Auto (fuseau horaire)',
    'de': 'Automatisch (Zeitzone)',
    'es': 'Automático (zona horaria)',
    'pt': 'Automático (fuso horário)',
    'ru': 'Авто (часовой пояс)',
    'tr': 'Otomatik (Saat dilimi)',
    'ar': 'تلقائي (المنطقة الزمنية)',
    'it': 'Automatico (fuso orario)',
    'hi': 'स्वचालित (समय क्षेत्र)',
    'th': 'อัตโนมัติ (เขตเวลา)',
  });

  String get settingsThemeAutoDesc => _t({
    'ko': '국가 시간에 따라 낮/밤 테마 자동 변경',
    'en': 'Auto-switch day/night theme based on local time',
    'ja': '国の時刻に応じて昼/夜テーマを自動切替',
    'zh': '根据当地时间自动切换日/夜主题',
    'fr': 'Changement auto jour/nuit selon l\'heure locale',
    'de': 'Automatischer Tag/Nacht-Wechsel nach Ortszeit',
    'es': 'Cambio automático día/noche según hora local',
    'pt': 'Troca automática dia/noite pelo horário local',
    'ru': 'Автосмена дневной/ночной темы по местному времени',
    'tr': 'Yerel saate göre gündüz/gece teması otomatik değişir',
    'ar': 'تبديل تلقائي بين سمة النهار/الليل حسب التوقيت المحلي',
    'it': 'Cambio automatico giorno/notte in base all\'ora locale',
    'hi': 'स्थानीय समय के अनुसार दिन/रात थीम स्वचालित बदलें',
    'th': 'สลับธีมกลางวัน/กลางคืนอัตโนมัติตามเวลาท้องถิ่น',
  });

  String get settingsThemeLight => _t({
    'ko': '밝은 모드',
    'en': 'Light Mode',
    'ja': 'ライトモード',
    'zh': '浅色模式',
    'fr': 'Mode clair',
    'de': 'Heller Modus',
    'es': 'Modo claro',
    'pt': 'Modo claro',
    'ru': 'Светлый режим',
    'tr': 'Açık mod',
    'ar': 'الوضع الفاتح',
    'it': 'Modalità chiara',
    'hi': 'लाइट मोड',
    'th': 'โหมดสว่าง',
  });

  String get settingsThemeLightDesc => _t({
    'ko': '항상 낮 테마로 표시',
    'en': 'Always show day theme',
    'ja': '常に昼テーマで表示',
    'zh': '始终显示日间主题',
    'fr': 'Toujours afficher le thème jour',
    'de': 'Immer Tagesmodus anzeigen',
    'es': 'Mostrar siempre tema diurno',
    'pt': 'Sempre mostrar tema diurno',
    'ru': 'Всегда дневная тема',
    'tr': 'Her zaman gündüz teması göster',
    'ar': 'عرض سمة النهار دائمًا',
    'it': 'Mostra sempre il tema diurno',
    'hi': 'हमेशा दिन की थीम दिखाएं',
    'th': 'แสดงธีมกลางวันเสมอ',
  });

  String get settingsThemeDark => _t({
    'ko': '다크 모드',
    'en': 'Dark Mode',
    'ja': 'ダークモード',
    'zh': '深色模式',
    'fr': 'Mode sombre',
    'de': 'Dunkler Modus',
    'es': 'Modo oscuro',
    'pt': 'Modo escuro',
    'ru': 'Тёмный режим',
    'tr': 'Karanlık mod',
    'ar': 'الوضع الداكن',
    'it': 'Modalità scura',
    'hi': 'डार्क मोड',
    'th': 'โหมดมืด',
  });

  String get settingsThemeDarkDesc => _t({
    'ko': '항상 밤 테마로 표시',
    'en': 'Always show night theme',
    'ja': '常に夜テーマで表示',
    'zh': '始终显示夜间主题',
    'fr': 'Toujours afficher le thème nuit',
    'de': 'Immer Nachtmodus anzeigen',
    'es': 'Mostrar siempre tema nocturno',
    'pt': 'Sempre mostrar tema noturno',
    'ru': 'Всегда ночная тема',
    'tr': 'Her zaman gece teması göster',
    'ar': 'عرض سمة الليل دائمًا',
    'it': 'Mostra sempre il tema notturno',
    'hi': 'हमेशा रात की थीम दिखाएं',
    'th': 'แสดงธีมกลางคืนเสมอ',
  });

  String get settingsCountry => _t({
    'ko': '나라',
    'en': 'Country',
    'ja': '国',
    'zh': '国家',
    'fr': 'Pays',
    'de': 'Land',
    'es': 'País',
    'pt': 'País',
    'ru': 'Страна',
    'tr': 'Ülke',
    'ar': 'البلد',
    'it': 'Paese',
    'hi': 'देश',
    'th': 'ประเทศ',
  });

  String get settingsAppInfo => _t({
    'ko': '앱 정보',
    'en': 'App Info',
    'ja': 'アプリ情報',
    'zh': '应用信息',
    'fr': 'Infos de l\'app',
    'de': 'App-Info',
    'es': 'Info de la app',
    'pt': 'Info do app',
    'ru': 'О приложении',
    'tr': 'Uygulama bilgisi',
    'ar': 'معلومات التطبيق',
    'it': 'Info app',
    'hi': 'ऐप जानकारी',
    'th': 'ข้อมูลแอป',
  });

  String get settingsAccountManagement => _t({
    'ko': '계정 관리',
    'en': 'Account Management',
    'ja': 'アカウント管理',
    'zh': '账号管理',
    'fr': 'Gestion du compte',
    'de': 'Kontoverwaltung',
    'es': 'Gestión de cuenta',
    'pt': 'Gerenciar conta',
    'ru': 'Управление аккаунтом',
    'tr': 'Hesap yönetimi',
    'ar': 'إدارة الحساب',
    'it': 'Gestione account',
    'hi': 'खाता प्रबंधन',
    'th': 'จัดการบัญชี',
  });

  String get settingsAdmin => _t({
    'ko': '관리자',
    'en': 'Admin',
    'ja': '管理者',
    'zh': '管理员',
    'fr': 'Admin',
    'de': 'Admin',
    'es': 'Admin',
    'pt': 'Admin',
    'ru': 'Админ',
    'tr': 'Yönetici',
    'ar': 'المسؤول',
    'it': 'Admin',
    'hi': 'एडमिन',
    'th': 'ผู้ดูแล',
  });

  String get settingsAdminPanel => _t({
    'ko': '관리자 패널',
    'en': 'Admin Panel',
    'ja': '管理パネル',
    'zh': '管理面板',
    'fr': 'Panneau admin',
    'de': 'Admin-Panel',
    'es': 'Panel de admin',
    'pt': 'Painel admin',
    'ru': 'Панель администратора',
    'tr': 'Yönetici paneli',
    'ar': 'لوحة المسؤول',
    'it': 'Pannello admin',
    'hi': 'एडमिन पैनल',
    'th': 'แผงผู้ดูแล',
  });

// ── Navigation (main_scaffold) ──────────────────────────────────────────────

  String get navTower => _t({
    'ko': '타워',
    'en': 'Tower',
    'ja': 'タワー',
    'zh': '塔',
    'fr': 'Tour',
    'de': 'Turm',
    'es': 'Torre',
    'pt': 'Torre',
    'ru': 'Башня',
    'tr': 'Kule',
    'ar': 'البرج',
    'it': 'Torre',
    'hi': 'टॉवर',
    'th': 'หอคอย',
  });

  /// Build 169: 수집첩 정렬 UI.
  String get inboxSortLabel => _t({
    'ko': '정렬', 'en': 'Sort', 'ja': '並び替え', 'zh': '排序',
    'fr': 'Tri', 'de': 'Sortieren', 'es': 'Ordenar', 'pt': 'Ordenar',
    'ru': 'Сортировка', 'tr': 'Sırala', 'ar': 'فرز', 'it': 'Ordina',
    'hi': 'छाँटें', 'th': 'เรียง',
  });
  String get inboxSortNewest => _t({
    'ko': '최신순', 'en': 'Newest', 'ja': '新しい順', 'zh': '最新',
    'fr': 'Récent', 'de': 'Neueste', 'es': 'Recientes', 'pt': 'Recentes',
    'ru': 'Новые', 'tr': 'Yeni', 'ar': 'الأحدث', 'it': 'Recenti',
    'hi': 'नया', 'th': 'ใหม่สุด',
  });
  String get inboxSortExpiring => _t({
    'ko': '만료임박', 'en': 'Expiring', 'ja': '期限間近', 'zh': '即将到期',
    'fr': 'Expire bientôt', 'de': 'Läuft bald ab', 'es': 'Por caducar',
    'pt': 'Expira em breve', 'ru': 'Скоро истекает', 'tr': 'Süresi yakın',
    'ar': 'قرب الانتهاء', 'it': 'In scadenza', 'hi': 'समाप्ति जल्द',
    'th': 'ใกล้หมดอายุ',
  });
  String get inboxSortByBrand => _t({
    'ko': '브랜드', 'en': 'Brand', 'ja': 'ブランド', 'zh': '品牌',
    'fr': 'Marque', 'de': 'Marke', 'es': 'Marca', 'pt': 'Marca',
    'ru': 'Бренд', 'tr': 'Marka', 'ar': 'علامة', 'it': 'Marca',
    'hi': 'ब्रांड', 'th': 'แบรนด์',
  });
  String get inboxSortByCategory => _t({
    'ko': '카테고리', 'en': 'Category', 'ja': 'カテゴリ', 'zh': '分类',
    'fr': 'Catégorie', 'de': 'Kategorie', 'es': 'Categoría', 'pt': 'Categoria',
    'ru': 'Категория', 'tr': 'Kategori', 'ar': 'فئة', 'it': 'Categoria',
    'hi': 'श्रेणी', 'th': 'หมวดหมู่',
  });

  /// Build 167: Premium Gate 소셜 증거 바.
  String premiumSocialProof(int count) {
    switch (languageCode) {
      case 'ko': return '이번 주 $count명이 Premium 업그레이드';
      case 'ja': return '今週 $count 人が Premium にアップグレード';
      case 'zh': return '本周 $count 人升级到 Premium';
      case 'fr': return 'Cette semaine, $count personnes passées Premium';
      case 'de': return 'Diese Woche $count Upgrades zu Premium';
      case 'es': return 'Esta semana $count pasaron a Premium';
      case 'pt': return 'Esta semana $count passaram a Premium';
      case 'ru': return 'На этой неделе $count перешли на Premium';
      case 'tr': return 'Bu hafta $count kişi Premium\'a geçti';
      case 'ar': return 'هذا الأسبوع $count ترقّوا إلى Premium';
      case 'it': return 'Questa settimana $count sono passati a Premium';
      case 'hi': return 'इस सप्ताह $count ने Premium अपग्रेड किया';
      case 'th': return 'สัปดาห์นี้ $count คนอัปเกรด Premium';
      default: return '$count upgraded to Premium this week';
    }
  }

  /// Build 166: GPS 필수 동의 플로우 (약관 + skip 경고).
  String get gpsTermsHeader => _t({
    'ko': 'GPS 사용 동의',
    'en': 'GPS Consent',
    'ja': 'GPS 使用同意',
    'zh': 'GPS 使用同意',
    'fr': 'Consentement GPS',
    'de': 'GPS-Einwilligung',
    'es': 'Consentimiento GPS',
    'pt': 'Consentimento GPS',
    'ru': 'Согласие на GPS',
    'tr': 'GPS İzni',
    'ar': 'موافقة GPS',
    'it': 'Consenso GPS',
    'hi': 'GPS सहमति',
    'th': 'ยินยอม GPS',
  });

  String get gpsTermsBody => _t({
    'ko': '• 내 위치 주변의 혜택을 주울 수 있어요\n• 내가 보낸 혜택의 출발 지점을 기록해요\n• 위치 정보는 서비스 제공 외에 사용하지 않아요\n\n❗ 동의하지 않으면 홍보를 보내거나 줍을 수 없어요.',
    'en': '• Pick up rewards dropped near you\n• Mark the origin of promos you send\n• Location is used only for this service\n\n❗ Without consent you cannot pick up or send rewards.',
    'ja': '• 周辺の手紙を拾えます\n• 送った手紙の出発地点を記録します\n• 位置情報はサービス提供以外に使用しません\n\n❗ 同意しないと手紙を送ったり拾ったりできません。',
    'zh': '• 拾起你身边的信件\n• 记录你寄出信件的出发地\n• 位置信息仅用于本服务\n\n❗ 不同意将无法收发信件。',
    'fr': '• Ramasser les lettres déposées près de toi\n• Marquer le point de départ des lettres envoyées\n• Utilisé uniquement pour ce service\n\n❗ Sans consentement, impossible d\'envoyer ou ramasser.',
    'de': '• Briefe in deiner Nähe aufsammeln\n• Absendeort deiner Briefe markieren\n• Nur für diesen Dienst verwendet\n\n❗ Ohne Zustimmung kannst du keine Briefe senden oder aufsammeln.',
    'es': '• Recoge cartas cerca de ti\n• Marca el origen de tus cartas\n• Solo se usa para este servicio\n\n❗ Sin consentimiento no puedes enviar ni recoger.',
    'pt': '• Apanha cartas perto de ti\n• Marca a origem das tuas cartas\n• Usado só para este serviço\n\n❗ Sem consentimento não podes enviar nem apanhar.',
    'ru': '• Подбирайте письма рядом\n• Отмечайте место отправки\n• Используется только для этого сервиса\n\n❗ Без согласия нельзя отправлять или подбирать.',
    'tr': '• Yakınındaki mektupları topla\n• Gönderdiğin mektubun başlangıç noktasını işaretle\n• Yalnızca bu hizmet için\n\n❗ İzin vermeden gönderme / toplama yok.',
    'ar': '• التقط الرسائل القريبة\n• سجّل نقطة إرسال رسائلك\n• تُستخدم لهذه الخدمة فقط\n\n❗ بدون الموافقة لا يمكنك الإرسال أو الالتقاط.',
    'it': '• Raccogli lettere vicino a te\n• Segna il punto di partenza\n• Usata solo per questo servizio\n\n❗ Senza consenso non puoi inviare o raccogliere.',
    'hi': '• आस-पास के पत्र उठाएँ\n• भेजे पत्रों का मूल चिह्नित\n• सेवा के लिए ही उपयोग\n\n❗ सहमति बिना भेजना/उठाना असंभव.',
    'th': '• เก็บจดหมายรอบตัว\n• บันทึกจุดส่งของคุณ\n• ใช้เฉพาะบริการนี้\n\n❗ ไม่ยินยอม = ส่ง/เก็บไม่ได้',
  });

  String get gpsAgreeAndContinue => _t({
    'ko': '동의하고 계속하기',
    'en': 'Agree & Continue',
    'ja': '同意して続ける',
    'zh': '同意并继续',
    'fr': 'Accepter & Continuer',
    'de': 'Zustimmen & Weiter',
    'es': 'Aceptar y Continuar',
    'pt': 'Aceitar e Continuar',
    'ru': 'Согласиться и продолжить',
    'tr': 'Kabul Et ve Devam',
    'ar': 'موافقة ومتابعة',
    'it': 'Accetta e Continua',
    'hi': 'सहमत व जारी',
    'th': 'ยอมรับและต่อไป',
  });

  String get gpsSkipWarningTitle => _t({
    'ko': '정말 건너뛸까요?',
    'en': 'Skip location?',
    'ja': '本当にスキップ?',
    'zh': '真的跳过?',
    'fr': 'Vraiment ignorer?',
    'de': 'Wirklich überspringen?',
    'es': '¿Saltar de verdad?',
    'pt': 'Saltar mesmo?',
    'ru': 'Точно пропустить?',
    'tr': 'Gerçekten atla?',
    'ar': 'تخطي حقًا؟',
    'it': 'Saltare davvero?',
    'hi': 'वास्तव में छोड़ें?',
    'th': 'ข้ามจริง?',
  });

  String get gpsSkipWarningBody => _t({
    'ko': 'GPS 동의 없이는 다음 기능을 사용할 수 없어요:\n\n• 📍 주변 혜택 줍기 불가\n• ✉️ 홍보 발송 불가 (Premium/Brand)\n• 🗺 내 위치 마커 표시 불가\n\n설정에서 언제든지 다시 허용할 수 있지만, 지금 동의하는 것을 강력히 권장합니다.',
    'en': 'Without GPS consent the following are disabled:\n\n• 📍 Pick up nearby rewards\n• 📣 Send promos (Premium/Brand)\n• 🗺 Show your location marker\n\nYou can enable it later in Settings, but we strongly recommend consenting now.',
    'ja': 'GPS 同意なしでは次の機能が使えません:\n\n• 📍 周辺の手紙を拾う\n• ✉️ 手紙を送る (Premium/Brand)\n• 🗺 自分の位置マーカー\n\n設定から後で許可できますが、今すぐ同意することを強くお勧めします。',
    'zh': '没有 GPS 同意将无法使用:\n\n• 📍 拾起附近信件\n• ✉️ 发送信件 (Premium/Brand)\n• 🗺 显示我的位置\n\n可在设置中重新允许，但强烈建议现在同意。',
    'fr': 'Sans consentement GPS, désactivé:\n\n• 📍 Ramasser des lettres\n• ✉️ Envoyer (Premium/Brand)\n• 🗺 Marqueur de position\n\nActivable plus tard dans Paramètres, mais nous recommandons fortement maintenant.',
    'de': 'Ohne GPS deaktiviert:\n\n• 📍 Briefe aufsammeln\n• ✉️ Briefe senden (Premium/Brand)\n• 🗺 Eigene Position\n\nSpäter in Einstellungen aktivierbar, jetzt empfohlen.',
    'es': 'Sin GPS estará deshabilitado:\n\n• 📍 Recoger cartas\n• ✉️ Enviar (Premium/Brand)\n• 🗺 Tu marcador\n\nActívalo luego en Ajustes, pero ahora es recomendable.',
    'pt': 'Sem GPS fica desativado:\n\n• 📍 Apanhar cartas\n• ✉️ Enviar (Premium/Brand)\n• 🗺 Teu marcador\n\nPodes ativar depois, mas recomendamos agora.',
    'ru': 'Без GPS недоступно:\n\n• 📍 Подбор писем\n• ✉️ Отправка (Premium/Brand)\n• 🗺 Ваш маркер\n\nМожно включить позже в настройках, но рекомендуем сейчас.',
    'tr': 'GPS onayı olmadan kapalı:\n\n• 📍 Mektup toplama\n• ✉️ Gönderme (Premium/Brand)\n• 🗺 Konumun\n\nSonra ayarlardan açabilirsin, şimdi öneriyoruz.',
    'ar': 'دون GPS معطل:\n\n• 📍 التقاط الرسائل\n• ✉️ الإرسال (Premium/Brand)\n• 🗺 موقعك\n\nيمكن تفعيله لاحقًا من الإعدادات، ولكن يُنصح الآن.',
    'it': 'Senza GPS disabilitato:\n\n• 📍 Raccogli lettere\n• ✉️ Invia (Premium/Brand)\n• 🗺 Tuo marcatore\n\nAttivabile poi in Impostazioni, ma consigliato ora.',
    'hi': 'GPS बिना अक्षम:\n\n• 📍 पत्र उठाना\n• ✉️ भेजना (Premium/Brand)\n• 🗺 आपका मार्कर\n\nसेटिंग्स में बाद में चालू करें, अभी सुझावित.',
    'th': 'ไม่มี GPS จะปิดใช้:\n\n• 📍 เก็บจดหมาย\n• ✉️ ส่ง (Premium/Brand)\n• 🗺 ตำแหน่งของคุณ\n\nเปิดภายหลังในตั้งค่าได้ แต่แนะนำตอนนี้',
  });

  String get gpsSkipBack => _t({
    'ko': '← 동의하기',
    'en': '← Agree',
    'ja': '← 同意',
    'zh': '← 同意',
    'fr': '← Accepter',
    'de': '← Zustimmen',
    'es': '← Aceptar',
    'pt': '← Aceitar',
    'ru': '← Согласиться',
    'tr': '← Kabul',
    'ar': '← موافقة',
    'it': '← Accetta',
    'hi': '← सहमत',
    'th': '← ยอมรับ',
  });

  String get gpsSkipContinueLimited => _t({
    'ko': '제한 모드로 진행',
    'en': 'Continue limited',
    'ja': '制限モードで続行',
    'zh': '以受限模式继续',
    'fr': 'Mode limité',
    'de': 'Eingeschränkt fortfahren',
    'es': 'Modo limitado',
    'pt': 'Modo limitado',
    'ru': 'Ограниченный режим',
    'tr': 'Sınırlı devam',
    'ar': 'متابعة محدودة',
    'it': 'Modalità limitata',
    'hi': 'सीमित जारी',
    'th': 'ต่อแบบจำกัด',
  });

  /// Build 164: 지도에서 유저 GPS 기준 가장 가까운 편지 마커 상단 라벨.
  String get mapNearestLetterLabel => _t({
    'ko': '가장 가까운',
    'en': 'Nearest',
    'ja': '最も近い',
    'zh': '最近',
    'fr': 'Plus proche',
    'de': 'Am nächsten',
    'es': 'Más cercana',
    'pt': 'Mais próxima',
    'ru': 'Ближайшее',
    'tr': 'En yakın',
    'ar': 'الأقرب',
    'it': 'Più vicina',
    'hi': 'सबसे नज़दीक',
    'th': 'ใกล้ที่สุด',
  });

  /// Build 174: 카운터 캐릭터 갤러리 (과거 티어 회고) 라벨.
  String get letterGalleryTitle => _t({
    'ko': '🧭 카운터 진화 갤러리',
    'en': '🧭 Counter Evolution',
    'ja': '🧭 カウンター進化ギャラリー',
    'zh': '🧭 Letter 进化画廊',
    'fr': '🧭 Évolution Letter',
    'de': '🧭 Letter-Entwicklung',
    'es': '🧭 Evolución Letter',
    'pt': '🧭 Evolução Letter',
    'ru': '🧭 Эволюция Letter',
    'tr': '🧭 Letter Evrimi',
    'ar': '🧭 تطور ليتر',
    'it': '🧭 Evoluzione Letter',
    'hi': '🧭 Letter विकास',
    'th': '🧭 วิวัฒนาการ Letter',
  });

  String get letterGallerySubtitle => _t({
    'ko': '지나온 모습과 다가올 모습',
    'en': 'Who you were and who you\'ll be',
    'ja': 'これまでとこれから',
    'zh': '曾经的你和将来的你',
    'fr': 'Qui tu étais et qui tu seras',
    'de': 'Wer du warst und wirst',
    'es': 'Quien fuiste y serás',
    'pt': 'Quem foste e serás',
    'ru': 'Кем вы были и станете',
    'tr': 'Eski ve gelecek halin',
    'ar': 'من كنت ومن ستكون',
    'it': 'Chi eri e chi sarai',
    'hi': 'जो थे और जो होंगे',
    'th': 'ตัวตนในอดีตและอนาคต',
  });

  /// Build 173: 카운터 생일 (가입 기념일) 카피.
  String letterBirthdayAnniversary(int years) {
    switch (languageCode) {
      case 'ko': return '🎉 카운터와 함께 $years주년!';
      case 'ja': return '🎉 カウンターと $years 周年！';
      case 'zh': return '🎉 与 Counter 同行 $years 周年！';
      case 'fr': return '🎉 $years ans avec Counter !';
      case 'de': return '🎉 $years Jahre mit Counter!';
      case 'es': return '🎉 $years años con Counter!';
      case 'pt': return '🎉 $years anos com Counter!';
      case 'ru': return '🎉 $years лет с Counter!';
      case 'tr': return '🎉 Counter ile $years. yıl!';
      case 'ar': return '🎉 $years سنوات مع Counter!';
      case 'it': return '🎉 $years anni con Counter!';
      case 'hi': return '🎉 Counter के साथ $years साल!';
      case 'th': return '🎉 $years ปีกับ Counter!';
      default: return '🎉 $years years with Counter!';
    }
  }

  String get letterBirthdayFirstDay => _t({
    'ko': '🎂 오늘이 당신의 카운터 생일이에요',
    'en': '🎂 Today is your Counter\'s birthday',
    'ja': '🎂 今日はあなたのカウンターの誕生日',
    'zh': '🎂 今天是你 Counter 的生日',
    'fr': "🎂 C'est l'anniversaire de ton Counter",
    'de': '🎂 Heute ist dein Counter-Geburtstag',
    'es': '🎂 Hoy es el cumple de tu Counter',
    'pt': '🎂 Hoje é o aniversário do teu Counter',
    'ru': '🎂 Сегодня день рождения вашего Counter',
    'tr': "🎂 Bugün Counter'ının doğum günü",
    'ar': '🎂 اليوم عيد ميلاد كاونترك',
    'it': '🎂 Oggi è il compleanno del tuo Counter',
    'hi': '🎂 आज आपके Counter का जन्मदिन',
    'th': '🎂 วันนี้ Counter ของคุณครบรอบ',
  });

  String letterAgeDays(int days) {
    switch (languageCode) {
      case 'ko': return '카운터와 함께 $days일째';
      case 'ja': return 'カウンターと $days 日目';
      case 'zh': return '与 Counter 同行 $days 天';
      case 'fr': return '$days jours avec Counter';
      case 'de': return '$days Tage mit Counter';
      case 'es': return '$days días con Counter';
      case 'pt': return '$days dias com Counter';
      case 'ru': return '$days дней с Counter';
      case 'tr': return 'Counter ile $days gün';
      case 'ar': return '$days أيام مع Counter';
      case 'it': return '$days giorni con Counter';
      case 'hi': return 'Counter के साथ $days दिन';
      case 'th': return '$days วันกับ Counter';
      default: return '$days days with Counter';
    }
  }

  String letterBirthdayUpcoming(int daysRemaining) {
    if (daysRemaining == 0) return letterBirthdayFirstDay;
    switch (languageCode) {
      case 'ko': return '생일까지 D-$daysRemaining';
      case 'ja': return '誕生日まで D-$daysRemaining';
      case 'zh': return '距生日 D-$daysRemaining';
      case 'fr': return 'Anniv dans $daysRemaining j';
      case 'de': return 'Geburtstag in $daysRemaining T';
      case 'es': return 'Cumple en $daysRemaining d';
      case 'pt': return 'Aniversário em $daysRemaining d';
      case 'ru': return 'День рожд. через $daysRemaining д';
      case 'tr': return 'Doğum günü $daysRemaining gün';
      case 'ar': return 'عيد الميلاد بعد $daysRemaining يوم';
      case 'it': return 'Compleanno tra $daysRemaining g';
      case 'hi': return 'जन्मदिन D-$daysRemaining';
      case 'th': return 'วันเกิดอีก $daysRemaining วัน';
      default: return 'Birthday in $daysRemaining d';
    }
  }

  /// Build 171: 카운터 이름 수정 다이얼로그 라벨 (Free/Premium 전용).
  String get profileDialogLetterNameTitle => _t({
    'ko': '내 카운터 이름',
    'en': 'My Counter name',
    'ja': 'カウンターの名前',
    'zh': '我的 Counter 名',
    'fr': 'Nom de mon Counter',
    'de': 'Mein Counter-Name',
    'es': 'Nombre de mi Counter',
    'pt': 'Nome do meu Counter',
    'ru': 'Имя моего Counter',
    'tr': "Counter'imin adı",
    'ar': 'اسم كاونتر الخاص بي',
    'it': 'Nome del mio Counter',
    'hi': 'मेरे Counter का नाम',
    'th': 'ชื่อ Counter ของฉัน',
  });

  String get profileDialogLetterNameHint => _t({
    'ko': '예: 쿠폰헌터 루나', 'en': 'e.g. Coupon Hunter Luna', 'ja': '例: クーポンハンタールナ',
    'zh': '例：优惠券猎人露娜', 'fr': 'ex. Chasseuse de coupons Luna', 'de': 'z.B. Couponjägerin Luna',
    'es': 'ej. Cazadora de cupones Luna', 'pt': 'ex. Caçadora de cupons Luna', 'ru': 'напр. Охотник за купонами Луна',
    'tr': 'örn. Kupon Avcısı Luna', 'ar': 'مثل: صائد الكوبونات لونا', 'it': 'es. Cacciatore di coupon Luna',
    'hi': 'उदा. कूपन हंटर Luna', 'th': 'เช่น นักล่าคูปองลูน่า',
  });

  String get profileDialogLetterNameDesc => _t({
    'ko': '내 카운터 캐릭터에 이름을 붙여보세요. 최대 20자.',
    'en': 'Give your Counter character a name. Max 20 chars.',
    'ja': 'カウンターキャラクターに名前を付けよう。最大20文字。',
    'zh': '给你的 Counter 起个名字。最多 20 字符。',
    'fr': 'Donne un nom à ton Counter. 20 caractères max.',
    'de': 'Gib deinem Counter einen Namen. Max 20 Zeichen.',
    'es': 'Ponle un nombre a tu Counter. Máx. 20 caracteres.',
    'pt': 'Dá um nome ao teu Counter. Máx 20 caracteres.',
    'ru': 'Назови своего Counter. Макс 20 символов.',
    'tr': "Counter'ına isim ver. En fazla 20 karakter.",
    'ar': 'سمّ كاونترك الخاص. 20 حرفًا بحد أقصى.',
    'it': 'Dai un nome al tuo Counter. Max 20 caratteri.',
    'hi': 'अपने Counter का नाम दें. अधिकतम 20 वर्ण.',
    'th': 'ตั้งชื่อ Counter ของคุณ สูงสุด 20 ตัวอักษร',
  });

  /// Build 171: 카운터 캐릭터 로드맵 카드 (다음 해금까지).
  String get letterRoadmapTitle => _t({
    'ko': '🎯 다음 해금', 'en': '🎯 Next unlock', 'ja': '🎯 次の解放',
    'zh': '🎯 下次解锁', 'fr': '🎯 Prochain déblocage', 'de': '🎯 Nächstes Freischalten',
    'es': '🎯 Próximo desbloqueo', 'pt': '🎯 Próximo desbloqueio',
    'ru': '🎯 Следующая разблокировка', 'tr': '🎯 Sonraki açılma',
    'ar': '🎯 الفتح التالي', 'it': '🎯 Prossimo sblocco',
    'hi': '🎯 अगला अनलॉक', 'th': '🎯 ปลดล็อกถัดไป',
  });

  String letterRoadmapCompanion(int level) {
    switch (languageCode) {
      case 'ko': return '$level 레벨에 새 동반자 해금';
      case 'ja': return 'レベル $level で新しい仲間を解放';
      case 'zh': return '等级 $level 解锁新伙伴';
      case 'fr': return 'Nouveau compagnon au niveau $level';
      case 'de': return 'Neuer Gefährte auf Level $level';
      case 'es': return 'Nuevo compañero en el nivel $level';
      case 'pt': return 'Novo companheiro no nível $level';
      case 'ru': return 'Новый спутник на уровне $level';
      case 'tr': return 'Seviye $level yeni yoldaş';
      case 'ar': return 'رفيق جديد في المستوى $level';
      case 'it': return 'Nuovo compagno al livello $level';
      case 'hi': return 'स्तर $level पर नया साथी';
      case 'th': return 'ปลดล็อกเพื่อนใหม่ระดับ $level';
      default: return 'New companion at Level $level';
    }
  }

  String letterRoadmapAccessory(int level) {
    switch (languageCode) {
      case 'ko': return '$level 레벨에 새 악세사리 해금';
      case 'ja': return 'レベル $level で新しいアクセサリー';
      case 'zh': return '等级 $level 解锁新配饰';
      case 'fr': return 'Nouvel accessoire au niveau $level';
      case 'de': return 'Neues Accessoire auf Level $level';
      case 'es': return 'Nuevo accesorio en el nivel $level';
      case 'pt': return 'Novo acessório no nível $level';
      case 'ru': return 'Новый аксессуар на уровне $level';
      case 'tr': return 'Seviye $level yeni aksesuar';
      case 'ar': return 'إكسسوار جديد في المستوى $level';
      case 'it': return 'Nuovo accessorio al livello $level';
      case 'hi': return 'स्तर $level पर नया एक्सेसरी';
      case 'th': return 'ปลดล็อกเครื่องประดับระดับ $level';
      default: return 'New accessory at Level $level';
    }
  }

  String letterRoadmapCharacter(int level) {
    switch (languageCode) {
      case 'ko': return '$level 레벨에 캐릭터 진화';
      case 'ja': return 'レベル $level でキャラクター進化';
      case 'zh': return '等级 $level 角色进化';
      case 'fr': return 'Évolution du personnage au niveau $level';
      case 'de': return 'Charakterentwicklung auf Level $level';
      case 'es': return 'Evolución del personaje en nivel $level';
      case 'pt': return 'Evolução do personagem no nível $level';
      case 'ru': return 'Эволюция персонажа на уровне $level';
      case 'tr': return 'Seviye $level karakter evrimi';
      case 'ar': return 'تطور الشخصية في المستوى $level';
      case 'it': return 'Evoluzione personaggio al livello $level';
      case 'hi': return 'स्तर $level पर चरित्र विकास';
      case 'th': return 'วิวัฒนาการตัวละครระดับ $level';
      default: return 'Character evolves at Level $level';
    }
  }

  /// Build 163 → 220: Free/Premium 전용 탭 라벨 — "카운터" 캐릭터 성장 경험.
  /// Brand 는 `navTower` 유지.
  String get navLetter => _t({
    'ko': '카운터',
    'en': 'Counter',
    'ja': 'カウンター',
    'zh': '计数器',
    'fr': 'Counter',
    'de': 'Counter',
    'es': 'Counter',
    'pt': 'Counter',
    'ru': 'Counter',
    'tr': 'Counter',
    'ar': 'كاونتر',
    'it': 'Letter',
    'hi': 'लेटर',
    'th': 'เลตเตอร์',
  });

// ── Offline Banner ──────────────────────────────────────────────────────────

  String get offlineDisconnected => _t({
    'ko': '인터넷 연결이 끊겼습니다',
    'en': 'No internet connection',
    'ja': 'インターネット接続が切れました',
    'zh': '网络连接已断开',
    'fr': 'Pas de connexion Internet',
    'de': 'Keine Internetverbindung',
    'es': 'Sin conexión a Internet',
    'pt': 'Sem conexão com a Internet',
    'ru': 'Нет подключения к Интернету',
    'tr': 'İnternet bağlantısı kesildi',
    'ar': 'لا يوجد اتصال بالإنترنت',
    'it': 'Nessuna connessione a Internet',
    'hi': 'इंटरनेट कनेक्शन नहीं है',
    'th': 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต',
  });

  String get offlineRetry => _t({
    'ko': '재시도',
    'en': 'Retry',
    'ja': '再試行',
    'zh': '重试',
    'fr': 'Réessayer',
    'de': 'Wiederholen',
    'es': 'Reintentar',
    'pt': 'Tentar novamente',
    'ru': 'Повторить',
    'tr': 'Tekrar dene',
    'ar': 'إعادة المحاولة',
    'it': 'Riprova',
    'hi': 'पुनः प्रयास करें',
    'th': 'ลองอีกครั้ง',
  });

// ── Shared Profile Dialogs ──────────────────────────────────────────────────

  String profileDialogNicknameCooldown(int days, String dateLabel) => _t({
    'ko': '닉네임은 3개월에 1회만 변경할 수 있어요. 약 $days일 남았습니다$dateLabel',
    'en': 'You can only change your nickname once every 3 months. About $days days remaining$dateLabel',
    'ja': 'ニックネームは3ヶ月に1回のみ変更できます。残り約${days}日$dateLabel',
    'zh': '昵称每3个月只能更改一次。还剩约${days}天$dateLabel',
    'fr': 'Vous ne pouvez changer votre pseudo qu\'une fois tous les 3 mois. Environ $days jours restants$dateLabel',
    'de': 'Der Spitzname kann nur alle 3 Monate geändert werden. Noch ca. $days Tage$dateLabel',
    'es': 'Solo puedes cambiar tu apodo una vez cada 3 meses. Faltan unos $days días$dateLabel',
    'pt': 'Você só pode alterar o apelido uma vez a cada 3 meses. Faltam cerca de $days dias$dateLabel',
    'ru': 'Никнейм можно менять раз в 3 месяца. Осталось примерно $days дн.$dateLabel',
    'tr': 'Takma adınızı yalnızca 3 ayda bir değiştirebilirsiniz. Yaklaşık $days gün kaldı$dateLabel',
    'ar': 'يمكنك تغيير الاسم المستعار مرة واحدة فقط كل 3 أشهر. بقي حوالي $days يوم$dateLabel',
    'it': 'Puoi cambiare il soprannome solo una volta ogni 3 mesi. Mancano circa $days giorni$dateLabel',
    'hi': 'उपनाम हर 3 महीने में केवल एक बार बदल सकते हैं। लगभग $days दिन शेष$dateLabel',
    'th': 'เปลี่ยนชื่อเล่นได้เพียง 1 ครั้งใน 3 เดือน เหลืออีกประมาณ $days วัน$dateLabel',
  });

  String get profileDialogTowerNameTitle => _t({
    'ko': '타워 이름 설정',
    'en': 'Set Tower Name',
    'ja': 'タワー名を設定',
    'zh': '设置塔名',
    'fr': 'Définir le nom de la tour',
    'de': 'Turmname festlegen',
    'es': 'Establecer nombre de torre',
    'pt': 'Definir nome da torre',
    'ru': 'Название башни',
    'tr': 'Kule adını ayarla',
    'ar': 'تعيين اسم البرج',
    'it': 'Imposta nome della torre',
    'hi': 'टॉवर का नाम सेट करें',
    'th': 'ตั้งชื่อหอคอย',
  });

  String get profileDialogTowerNameHint => _t({
    'ko': '나만의 타워 이름 (최대 20자)',
    'en': 'Your tower name (max 20 chars)',
    'ja': 'タワーの名前 (最大20文字)',
    'zh': '你的塔名 (最多20字)',
    'fr': 'Nom de votre tour (max 20 car.)',
    'de': 'Ihr Turmname (max. 20 Zeichen)',
    'es': 'Tu nombre de torre (máx. 20 car.)',
    'pt': 'Nome da sua torre (máx. 20 car.)',
    'ru': 'Название вашей башни (макс. 20 симв.)',
    'tr': 'Kulenizin adı (maks. 20 karakter)',
    'ar': 'اسم برجك (20 حرف كحد أقصى)',
    'it': 'Nome della tua torre (max 20 car.)',
    'hi': 'अपने टॉवर का नाम (अधिकतम 20 अक्षर)',
    'th': 'ชื่อหอคอยของคุณ (สูงสุด 20 ตัว)',
  });

  String get profileDialogTowerNameDesc => _t({
    'ko': '지도에서 타워 마커에 이름이 표시됩니다',
    'en': 'This name will appear on your tower marker on the map',
    'ja': '地図上のタワーマーカーに名前が表示されます',
    'zh': '该名称将显示在地图上的塔标记上',
    'fr': 'Ce nom apparaîtra sur le marqueur de votre tour sur la carte',
    'de': 'Dieser Name wird auf Ihrem Turm-Marker auf der Karte angezeigt',
    'es': 'Este nombre aparecerá en el marcador de tu torre en el mapa',
    'pt': 'Este nome será exibido no marcador da sua torre no mapa',
    'ru': 'Это имя будет отображаться на маркере вашей башни на карте',
    'tr': 'Bu ad haritadaki kule işaretçinizde görünecektir',
    'ar': 'سيظهر هذا الاسم على علامة برجك على الخريطة',
    'it': 'Questo nome apparirà sul marcatore della tua torre sulla mappa',
    'hi': 'यह नाम मानचित्र पर आपके टॉवर मार्कर पर दिखाई देगा',
    'th': 'ชื่อนี้จะแสดงบนเครื่องหมายหอคอยของคุณบนแผนที่',
  });

  String get profileDialogEditNickname => _t({
    'ko': '닉네임 수정',
    'en': 'Edit Nickname',
    'ja': 'ニックネームを編集',
    'zh': '修改昵称',
    'fr': 'Modifier le pseudo',
    'de': 'Spitzname bearbeiten',
    'es': 'Editar apodo',
    'pt': 'Editar apelido',
    'ru': 'Изменить никнейм',
    'tr': 'Takma adı düzenle',
    'ar': 'تعديل الاسم المستعار',
    'it': 'Modifica soprannome',
    'hi': 'उपनाम संपादित करें',
    'th': 'แก้ไขชื่อเล่น',
  });

  String get profileDialogNewNickname => _t({
    'ko': '새 닉네임',
    'en': 'New nickname',
    'ja': '新しいニックネーム',
    'zh': '新昵称',
    'fr': 'Nouveau pseudo',
    'de': 'Neuer Spitzname',
    'es': 'Nuevo apodo',
    'pt': 'Novo apelido',
    'ru': 'Новый никнейм',
    'tr': 'Yeni takma ad',
    'ar': 'الاسم المستعار الجديد',
    'it': 'Nuovo soprannome',
    'hi': 'नया उपनाम',
    'th': 'ชื่อเล่นใหม่',
  });

  String get profileDialogNicknameMin2 => _t({
    'ko': '닉네임은 2자 이상이어야 합니다',
    'en': 'Nickname must be at least 2 characters',
    'ja': 'ニックネームは2文字以上で入力してください',
    'zh': '昵称至少需要2个字符',
    'fr': 'Le pseudo doit comporter au moins 2 caractères',
    'de': 'Der Spitzname muss mindestens 2 Zeichen haben',
    'es': 'El apodo debe tener al menos 2 caracteres',
    'pt': 'O apelido deve ter pelo menos 2 caracteres',
    'ru': 'Никнейм должен содержать не менее 2 символов',
    'tr': 'Takma ad en az 2 karakter olmalıdır',
    'ar': 'يجب أن يكون الاسم المستعار حرفين على الأقل',
    'it': 'Il soprannome deve avere almeno 2 caratteri',
    'hi': 'उपनाम कम से कम 2 अक्षर का होना चाहिए',
    'th': 'ชื่อเล่นต้องมีอย่างน้อย 2 ตัวอักษร',
  });

// ── Stamp Album ─────────────────────────────────────────────────────────────

  String get stampAlbumTitle => _t({
    'ko': '우표 앨범',
    'en': 'Stamp Album',
    'ja': '切手アルバム',
    'zh': '邮票相册',
    'fr': 'Album de timbres',
    'de': 'Briefmarkenalbum',
    'es': 'Álbum de sellos',
    'pt': 'Álbum de selos',
    'ru': 'Альбом марок',
    'tr': 'Pul albümü',
    'ar': 'ألبوم الطوابع',
    'it': 'Album di francobolli',
    'hi': 'स्टैम्प एलबम',
    'th': 'อัลบั้มแสตมป์',
  });

  String get stampAlbumSubtitle => _t({
    'ko': '혜택 우표 수집 앨범',
    'en': 'Reward Stamp Collection',
    'ja': '手紙切手コレクション',
    'zh': '信件邮票收藏册',
    'fr': 'Collection de timbres de lettres',
    'de': 'Briefmarkensammlung',
    'es': 'Colección de sellos de cartas',
    'pt': 'Coleção de selos de cartas',
    'ru': 'Коллекция почтовых марок',
    'tr': 'Mektup pulu koleksiyonu',
    'ar': 'مجموعة طوابع الرسائل',
    'it': 'Collezione di francobolli di lettere',
    'hi': 'पत्र डाक टिकट संग्रह',
    'th': 'คอลเลกชันแสตมป์จดหมาย',
  });

  String stampCountriesCount(int n) => _t({
    'ko': '${n}개국',
    'en': '$n countries',
    'ja': '${n}カ国',
    'zh': '${n}个国家',
    'fr': '$n pays',
    'de': '$n Länder',
    'es': '$n países',
    'pt': '$n países',
    'ru': '$n стран',
    'tr': '$n ülke',
    'ar': '$n دولة',
    'it': '$n paesi',
    'hi': '$n देश',
    'th': '$n ประเทศ',
  });

  String get stampVisited => _t({
    'ko': '방문',
    'en': 'Visited',
    'ja': '訪問',
    'zh': '访问',
    'fr': 'Visités',
    'de': 'Besucht',
    'es': 'Visitados',
    'pt': 'Visitados',
    'ru': 'Посещено',
    'tr': 'Ziyaret',
    'ar': 'زيارة',
    'it': 'Visitati',
    'hi': 'भेंट',
    'th': 'เยี่ยมชม',
  });

  String stampLettersCount(int n) => _t({
    'ko': '${n}통',
    'en': '$n rewards',
    'ja': '${n}通',
    'zh': '${n}封',
    'fr': '$n lettres',
    'de': '$n Briefe',
    'es': '$n cartas',
    'pt': '$n cartas',
    'ru': '$n писем',
    'tr': '$n mektup',
    'ar': '$n رسالة',
    'it': '$n lettere',
    'hi': '$n पत्र',
    'th': '$n ฉบับ',
  });

  String get stampReceived => _t({
    'ko': '수신',
    'en': 'Received',
    'ja': '受信',
    'zh': '收到',
    'fr': 'Reçues',
    'de': 'Empfangen',
    'es': 'Recibidas',
    'pt': 'Recebidas',
    'ru': 'Получено',
    'tr': 'Alındı',
    'ar': 'مستلمة',
    'it': 'Ricevute',
    'hi': 'प्राप्त',
    'th': 'ได้รับ',
  });

  String stampReceivedCount(int n) => _t({
    'ko': '${n}통 수신',
    'en': '$n received',
    'ja': '${n}通 受信',
    'zh': '收到${n}封',
    'fr': '$n reçues',
    'de': '$n empfangen',
    'es': '$n recibidas',
    'pt': '$n recebidas',
    'ru': '$n получено',
    'tr': '$n alındı',
    'ar': '$n مستلمة',
    'it': '$n ricevute',
    'hi': '$n प्राप्त',
    'th': 'ได้รับ $n ฉบับ',
  });

  String stampFirstReceived(String date) => _t({
    'ko': '최초: $date',
    'en': 'First: $date',
    'ja': '初回: $date',
    'zh': '首次: $date',
    'fr': 'Premier: $date',
    'de': 'Erster: $date',
    'es': 'Primero: $date',
    'pt': 'Primeiro: $date',
    'ru': 'Первое: $date',
    'tr': 'İlk: $date',
    'ar': 'الأول: $date',
    'it': 'Primo: $date',
    'hi': 'पहला: $date',
    'th': 'ครั้งแรก: $date',
  });

  String get stampEmptyTitle => _t({
    'ko': '아직 수집한 우표가 없어요',
    'en': 'No stamps collected yet',
    'ja': 'まだ切手を集めていません',
    'zh': '还没有收集到邮票',
    'fr': 'Aucun timbre collecté',
    'de': 'Noch keine Briefmarken gesammelt',
    'es': 'Aún no has coleccionado sellos',
    'pt': 'Nenhum selo coletado ainda',
    'ru': 'Пока нет собранных марок',
    'tr': 'Henüz pul toplanmadı',
    'ar': 'لا توجد طوابع مجمعة بعد',
    'it': 'Nessun francobollo raccolto',
    'hi': 'अभी तक कोई स्टैम्प नहीं',
    'th': 'ยังไม่มีแสตมป์ที่สะสม',
  });

  String get stampEmptyBody => _t({
    'ko': '혜택을 받으면 발신 국가 우표가\n자동으로 수집됩니다',
    'en': 'When you receive a reward,\nthe sender\'s country stamp is collected automatically',
    'ja': '手紙を受け取ると、送信国の切手が\n自動的に収集されます',
    'zh': '收到信件后，发件国邮票\n会自动收集',
    'fr': 'Quand vous recevez une lettre,\nle timbre du pays est collecté automatiquement',
    'de': 'Wenn Sie einen Brief erhalten, wird die\nBriefmarke des Absenderlandes automatisch gesammelt',
    'es': 'Cuando recibas una carta,\nel sello del país se coleccionará automáticamente',
    'pt': 'Ao receber uma carta,\no selo do país é coletado automaticamente',
    'ru': 'Когда вы получите письмо,\nмарка страны отправителя будет собрана автоматически',
    'tr': 'Bir mektup aldığınızda gönderen\nülkenin pulu otomatik olarak toplanır',
    'ar': 'عند استلام رسالة، يتم جمع\nطابع بلد المرسل تلقائيًا',
    'it': 'Quando ricevi una lettera,\nil francobollo del paese viene raccolto automaticamente',
    'hi': 'जब आपको पत्र मिलेगा,\nप्रेषक के देश का स्टैम्प स्वचालित रूप से एकत्र होगा',
    'th': 'เมื่อได้รับจดหมาย แสตมป์ของประเทศ\nผู้ส่งจะถูกสะสมโดยอัตโนมัติ',
  });

// ── Onboarding ──────────────────────────────────────────────────────────────

  String get onboardingCountryTitle => _t({
    'ko': '어디에서 오셨나요?',
    'en': 'Where are you from?',
    'ja': 'どちらの国ですか？',
    'zh': '你来自哪里？',
    'fr': 'D\'où venez-vous ?',
    'de': 'Woher kommen Sie?',
    'es': '¿De dónde eres?',
    'pt': 'De onde você é?',
    'ru': 'Откуда вы?',
    'tr': 'Nerelisiniz?',
    'ar': 'من أين أنت؟',
    'it': 'Da dove vieni?',
    'hi': 'आप कहाँ से हैं?',
    'th': 'คุณมาจากไหน?',
  });

  String get onboardingCountrySubtitle => _t({
    'ko': '거주 국가를 선택하면 앱이 해당 언어로 표시됩니다',
    'en': 'Select your country and the app will display in that language',
    'ja': '居住国を選択すると、アプリがその言語で表示されます',
    'zh': '选择您的国家，应用将以该语言显示',
    'fr': 'Sélectionnez votre pays et l\'application s\'affichera dans cette langue',
    'de': 'Wählen Sie Ihr Land und die App wird in dieser Sprache angezeigt',
    'es': 'Selecciona tu país y la app se mostrará en ese idioma',
    'pt': 'Selecione seu país e o app será exibido nesse idioma',
    'ru': 'Выберите страну, и приложение будет отображаться на этом языке',
    'tr': 'Ülkenizi seçin, uygulama o dilde görüntülenecektir',
    'ar': 'اختر بلدك وسيُعرض التطبيق بتلك اللغة',
    'it': 'Seleziona il tuo paese e l\'app verrà visualizzata in quella lingua',
    'hi': 'अपना देश चुनें और ऐप उस भाषा में प्रदर्शित होगा',
    'th': 'เลือกประเทศของคุณ แอปจะแสดงเป็นภาษานั้น',
  });

  String get onboardingSearchCountry => _t({
    'ko': '국가 검색...',
    'en': 'Search country...',
    'ja': '国を検索...',
    'zh': '搜索国家...',
    'fr': 'Rechercher un pays...',
    'de': 'Land suchen...',
    'es': 'Buscar país...',
    'pt': 'Buscar país...',
    'ru': 'Поиск страны...',
    'tr': 'Ülke ara...',
    'ar': 'البحث عن بلد...',
    'it': 'Cerca paese...',
    'hi': 'देश खोजें...',
    'th': 'ค้นหาประเทศ...',
  });

  // Build 119: 온보딩 Premium 소개 페이지도 픽업-퍼스트. 타이틀·서브타이틀
  // 모두 "반경·쿨다운" 의 구체 수치를 내세운다. 마케팅 기획서 Build 113 의
  // "레벨업 = 실제 반경 확대" 축과 정렬.
  String get onboardingPremiumTitle => _t({
    'ko': '더 넓은 반경으로\n쿠폰을 주워보세요',
    'en': 'Pick up coupons\nacross a wider radius',
    'ja': 'より広い範囲で\nクーポンを拾おう',
    'zh': '在更大范围内\n拾起优惠券',
    'fr': 'Ramasse des coupons\ndans un rayon plus large',
    'de': 'Sammle Coupons\nin einem größeren Umkreis',
    'es': 'Recoge cupones\nen un radio más amplio',
    'pt': 'Apanha cupões\nnum raio maior',
    'ru': 'Подбирайте купоны\nв большем радиусе',
    'tr': 'Daha geniş alanda\nkupon topla',
    'ar': 'التقط كوبونات\nفي نطاق أوسع',
    'it': 'Raccogli coupon\nin un raggio più ampio',
    'hi': 'बड़े दायरे में\nकूपन उठाओ',
    'th': 'เก็บคูปอง\nในรัศมีที่กว้างขึ้น',
  });

  String get onboardingPremiumSubtitle => _t({
    'ko': '줍기 반경 1km · 쿨다운 10분\n— Free보다 5배 넓고 6배 빠르게',
    'en': '1 km pickup radius · 10-min cooldown\n— 5× wider, 6× faster than Free',
    'ja': '拾える範囲 1km · クールダウン 10分\n— Freeより5倍広く、6倍速く',
    'zh': '拾取范围 1km · 冷却 10 分钟\n— 比 Free 大 5 倍、快 6 倍',
    'fr': "Rayon 1 km · recharge 10 min\n— 5× plus large, 6× plus rapide que Free",
    'de': '1 km Radius · 10 min Abklingzeit\n— 5× breiter, 6× schneller als Free',
    'es': 'Radio 1 km · enfriamiento 10 min\n— 5× más amplio y 6× más rápido que Free',
    'pt': 'Raio 1 km · recarga 10 min\n— 5× maior e 6× mais rápido que Free',
    'ru': 'Радиус 1 км · перезарядка 10 мин\n— в 5 раз шире и в 6 раз быстрее Free',
    'tr': '1 km yarıçap · 10 dk bekleme\n— Freeden 5× geniş, 6× hızlı',
    'ar': 'نطاق 1 كم · تبريد 10 دقائق\n— أوسع بـ 5 أضعاف وأسرع بـ 6 أضعاف من Free',
    'it': 'Raggio 1 km · cooldown 10 min\n— 5× più ampio, 6× più veloce di Free',
    'hi': '1 किमी रेडियस · 10 मिनट कूलडाउन\n— Free से 5× बड़ा, 6× तेज़',
    'th': 'รัศมี 1 กม. · คูลดาวน์ 10 นาที\n— กว้างกว่า 5 เท่า เร็วกว่า 6 เท่าของ Free',
  });

  // Build 119: 온보딩 Free/Premium feature 리스트 재배치 — 양쪽 모두 픽업
  // 지표(반경 · 쿨다운) 를 1번에 두고, 발송·기타 번들은 뒤로. 페이월과 구조
  // 동일하게 맞춘다.
  String get onboardingFreeFeat1 => _t({
    'ko': '줍기 반경 200m · 쿨다운 60분',
    'en': '200 m pickup radius · 60-min cooldown',
    'ja': '拾える範囲 200m · 60分クールダウン',
    'zh': '拾取范围 200m · 冷却 60 分钟',
    'fr': 'Rayon 200 m · recharge 60 min',
    'de': '200 m Radius · 60 min Abklingzeit',
    'es': 'Radio 200 m · enfriamiento 60 min',
    'pt': 'Raio 200 m · recarga 60 min',
    'ru': 'Радиус 200 м · перезарядка 60 мин',
    'tr': '200 m yarıçap · 60 dk bekleme',
    'ar': 'نطاق 200 م · تبريد 60 دقيقة',
    'it': 'Raggio 200 m · cooldown 60 min',
    'hi': '200 मी रेडियस · 60 मिनट कूलडाउन',
    'th': 'รัศมี 200 ม. · คูลดาวน์ 60 นาที',
  });

  String get onboardingFreeFeat2 => _t({
    'ko': '하루 3통 홍보 발송 · 월 100통',
    'en': '3 promos/day · 100/month',
    'ja': '1日3通 · 月100通',
    'zh': '每天3封 · 每月100封',
    'fr': '3 lettres/jour · 100/mois',
    'de': '3 Briefe/Tag · 100/Monat',
    'es': '3 cartas/día · 100/mes',
    'pt': '3 cartas/dia · 100/mês',
    'ru': '3 письма/день · 100/месяц',
    'tr': '3 mektup/gün · 100/ay',
    'ar': '3 رسائل/يوم · 100/شهر',
    'it': '3 lettere/giorno · 100/mese',
    'hi': '3 पत्र/दिन · 100/माह',
    'th': '3 ฉบับ/วัน · 100/เดือน',
  });

  String get onboardingFreeFeat3 => _t({
    'ko': '세계 지도 열람',
    'en': 'World map access',
    'ja': '世界地図の閲覧',
    'zh': '浏览世界地图',
    'fr': 'Accès à la carte du monde',
    'de': 'Zugang zur Weltkarte',
    'es': 'Acceso al mapa mundial',
    'pt': 'Acesso ao mapa mundial',
    'ru': 'Доступ к мировой карте',
    'tr': 'Dünya haritasına erişim',
    'ar': 'الوصول إلى خريطة العالم',
    'it': 'Accesso alla mappa del mondo',
    'hi': 'विश्व मानचित्र पहुँच',
    'th': 'เข้าถึงแผนที่โลก',
  });

  String get onboardingFreeFeat4 => _t({
    'ko': '기본 타워 스킨',
    'en': 'Basic tower skin',
    'ja': '基本タワースキン',
    'zh': '基础塔皮肤',
    'fr': 'Skin de tour basique',
    'de': 'Basis-Turm-Skin',
    'es': 'Skin de torre básico',
    'pt': 'Skin de torre básica',
    'ru': 'Базовый скин башни',
    'tr': 'Temel kule görünümü',
    'ar': 'مظهر برج أساسي',
    'it': 'Skin torre base',
    'hi': 'बेसिक टॉवर स्किन',
    'th': 'สกินหอคอยพื้นฐาน',
  });

  String get onboardingPremiumFeat1 => _t({
    'ko': '줍기 반경 1km · Free 200m의 5배',
    'en': '1 km pickup radius · 5× the free 200 m',
    'ja': '拾える範囲 1km · 無料 200m の 5倍',
    'zh': '拾取范围 1km · 免费 200m 的 5 倍',
    'fr': 'Rayon 1 km · 5× des 200 m gratuits',
    'de': 'Aufsammelradius 1 km · 5× die kostenlosen 200 m',
    'es': 'Radio de recogida 1 km · 5× los 200 m gratis',
    'pt': 'Raio de recolha 1 km · 5× os 200 m grátis',
    'ru': 'Радиус 1 км · в 5× больше бесплатных 200 м',
    'tr': 'Toplama yarıçapı 1 km · ücretsiz 200 m’nin 5 katı',
    'ar': 'نطاق الالتقاط 1 كم · 5 أضعاف 200 م المجانية',
    'it': 'Raggio di raccolta 1 km · 5× i 200 m gratuiti',
    'hi': 'पिकअप रेडियस 1 किमी · मुफ्त 200 मी का 5×',
    'th': 'รัศมีเก็บ 1 กม. · 5 เท่าของ 200 ม. ฟรี',
  });

  String get onboardingPremiumFeat2 => _t({
    'ko': '10분 쿨다운 · Free 60분 대비 6배',
    'en': '10-min cooldown · 6× faster than free',
    'ja': '10分クールダウン · 無料 60分 より6倍速',
    'zh': '冷却 10 分钟 · 比免费 60 分钟快 6 倍',
    'fr': 'Recharge 10 min · 6× plus rapide que le gratuit',
    'de': '10 min Abklingzeit · 6× schneller als kostenlos',
    'es': 'Enfriamiento 10 min · 6× más rápido que gratis',
    'pt': 'Recarga 10 min · 6× mais rápido que o grátis',
    'ru': 'Перезарядка 10 мин · в 6× быстрее бесплатной',
    'tr': '10 dk bekleme · ücretsizden 6× hızlı',
    'ar': 'تبريد 10 دقائق · أسرع 6× من المجانية',
    'it': 'Cooldown 10 min · 6× più veloce del gratuito',
    'hi': '10 मिनट कूलडाउन · मुफ्त से 6× तेज़',
    'th': 'คูลดาวน์ 10 นาที · เร็วกว่าฟรี 6 เท่า',
  });

  String get onboardingPremiumFeat3 => _t({
    'ko': '하루 30통 발송 + 이미지·링크 홍보',
    'en': '30 promos/day + image & link promos',
    'ja': '1日30通発送 + 画像・リンク付き手紙',
    'zh': '每日 30 封发送 + 图片·链接信件',
    'fr': '30 lettres/jour + image & lien',
    'de': '30 Briefe/Tag + Bild & Link',
    'es': '30 cartas/día + imagen y enlace',
    'pt': '30 cartas/dia + imagem e link',
    'ru': '30 писем/день + фото и ссылки',
    'tr': 'Günde 30 mektup + resim & link',
    'ar': '30 رسالة/يوم + صور وروابط',
    'it': '30 lettere/giorno + immagine e link',
    'hi': '30 पत्र/दिन + छवि व लिंक',
    'th': '30 ฉบับ/วัน + ภาพ·ลิงก์',
  });

  String get onboardingPremiumFeat4 => _t({
    'ko': '타워 커스텀 색상 · 특급 배송 3통/일',
    'en': 'Custom tower color · 3 express deliveries/day',
    'ja': 'タワーカスタムカラー · 特急配送 3/日',
    'zh': '塔楼自定义颜色 · 特快配送 3/日',
    'fr': 'Couleur de tour personnalisée · 3 livraisons express/jour',
    'de': 'Eigene Turmfarbe · 3 Express-Lieferungen/Tag',
    'es': 'Color de torre personalizado · 3 entregas exprés/día',
    'pt': 'Cor de torre personalizada · 3 entregas expressas/dia',
    'ru': 'Свой цвет башни · 3 экспресса/день',
    'tr': 'Özel kule rengi · 3 ekspres/gün',
    'ar': 'لون برج مخصّص · 3 توصيلات سريعة/يوم',
    'it': 'Colore torre personalizzato · 3 espressi/giorno',
    'hi': 'कस्टम टावर रंग · 3 एक्सप्रेस/दिन',
    'th': 'สีหอคอยกำหนดเอง · ด่วน 3/วัน',
  });

  String get onboardingStatActiveUsers => _t({
    'ko': '활성 유저',
    'en': 'Active users',
    'ja': 'アクティブユーザー',
    'zh': '活跃用户',
    'fr': 'Utilisateurs actifs',
    'de': 'Aktive Nutzer',
    'es': 'Usuarios activos',
    'pt': 'Usuários ativos',
    'ru': 'Активные пользователи',
    'tr': 'Aktif kullanıcılar',
    'ar': 'المستخدمون النشطون',
    'it': 'Utenti attivi',
    'hi': 'सक्रिय उपयोगकर्ता',
    'th': 'ผู้ใช้งาน',
  });

  String get onboardingStatTotalLetters => _t({
    'ko': '누적 혜택',
    'en': 'Total rewards',
    'ja': '累計手紙',
    'zh': '累计信件',
    'fr': 'Lettres totales',
    'de': 'Gesamtbriefe',
    'es': 'Cartas totales',
    'pt': 'Total de cartas',
    'ru': 'Всего писем',
    'tr': 'Toplam mektup',
    'ar': 'إجمالي الرسائل',
    'it': 'Lettere totali',
    'hi': 'कुल पत्र',
    'th': 'จดหมายทั้งหมด',
  });

  String get onboardingStatBrandPartners => _t({
    'ko': '브랜드 파트너',
    'en': 'Brand partners',
    'ja': 'ブランドパートナー',
    'zh': '品牌合作伙伴',
    'fr': 'Partenaires de marque',
    'de': 'Markenpartner',
    'es': 'Socios de marca',
    'pt': 'Parceiros de marca',
    'ru': 'Бренд-партнёры',
    'tr': 'Marka ortakları',
    'ar': 'شركاء العلامة التجارية',
    'it': 'Partner di marca',
    'hi': 'ब्रांड पार्टनर',
    'th': 'พาร์ทเนอร์แบรนด์',
  });

  String get onboardingStatDeliveryRate => _t({
    'ko': '혜택 전달률',
    'en': 'Delivery rate',
    'ja': '配達率',
    'zh': '投递率',
    'fr': 'Taux de livraison',
    'de': 'Zustellrate',
    'es': 'Tasa de entrega',
    'pt': 'Taxa de entrega',
    'ru': 'Доставляемость',
    'tr': 'Teslimat oranı',
    'ar': 'معدل التسليم',
    'it': 'Tasso di consegna',
    'hi': 'डिलीवरी दर',
    'th': 'อัตราการจัดส่ง',
  });

  String get onboardingStatCountries => _t({
    'ko': '연결 국가',
    'en': 'Connected countries',
    'ja': '接続国',
    'zh': '连接国家',
    'fr': 'Pays connectés',
    'de': 'Verbundene Länder',
    'es': 'Países conectados',
    'pt': 'Países conectados',
    'ru': 'Стран подключено',
    'tr': 'Bağlı ülkeler',
    'ar': 'الدول المتصلة',
    'it': 'Paesi collegati',
    'hi': 'जुड़े देश',
    'th': 'ประเทศที่เชื่อมต่อ',
  });

  String get onboardingStatCountriesValue => _t({
    'ko': '164개국',
    'en': '164',
    'ja': '164カ国',
    'zh': '164国',
    'fr': '164',
    'de': '164',
    'es': '164',
    'pt': '164',
    'ru': '164',
    'tr': '164',
    'ar': '164',
    'it': '164',
    'hi': '164',
    'th': '164',
  });

  String get onboardingReview1 => _t({
    'ko': '"브랜드 혜택이 일반 광고보다 훨씬 따뜻하게 느껴져요."',
    'en': '"Brand rewards feel much warmer than regular ads."',
    'ja': '"ブランドレターは普通の広告よりずっと温かみがあります。"',
    'zh': '"品牌信件比普通广告感觉温暖得多。"',
    'fr': '"Les lettres de marque semblent bien plus chaleureuses que les publicités."',
    'de': '"Markenbriefe fühlen sich viel wärmer an als normale Werbung."',
    'es': '"Las cartas de marca se sienten mucho más cálidas que los anuncios."',
    'pt': '"As cartas de marca parecem muito mais acolhedoras que anúncios."',
    'ru': '"Брендовые письма ощущаются гораздо теплее обычной рекламы."',
    'tr': '"Marka mektupları normal reklamlardan çok daha sıcak hissettiriyor."',
    'ar': '"رسائل العلامة التجارية تبدو أكثر دفئًا من الإعلانات العادية."',
    'it': '"Le lettere di marca sembrano molto più calde della pubblicità."',
    'hi': '"ब्रांड पत्र सामान्य विज्ञापनों से बहुत गर्म महसूस होते हैं।"',
    'th': '"จดหมายแบรนด์ให้ความรู้สึกอบอุ่นกว่าโฆษณาทั่วไปมาก"',
  });

  String get onboardingReview2 => _t({
    'ko': '"프리미엄으로 올리니 홍보 무제한에 우선 배달까지, 완전 만족!"',
    'en': '"Upgrading to Premium gave me unlimited promos and priority delivery!"',
    'ja': '"プレミアムにしたら手紙無制限＋優先配達で大満足！"',
    'zh': '"升级到高级版后，信件无限+优先配送，超级满意！"',
    'fr': '"Passer en Premium m\'a donné des lettres illimitées et la livraison prioritaire !"',
    'de': '"Premium-Upgrade: unbegrenzte Briefe und Prioritätszustellung!"',
    'es': '"Al pasar a Premium obtuve cartas ilimitadas y entrega prioritaria."',
    'pt': '"Ao atualizar para Premium, ganhei cartas ilimitadas e entrega prioritária!"',
    'ru': '"Премиум дал безлимитные письма и приоритетную доставку!"',
    'tr': '"Premium\'a geçince sınırsız mektup ve öncelikli teslimat!"',
    'ar': '"الترقية إلى المميز أعطتني رسائل غير محدودة وتسليم أولوي!"',
    'it': '"Passando a Premium ho ottenuto lettere illimitate e consegna prioritaria!"',
    'hi': '"प्रीमियम में अपग्रेड से असीमित पत्र और प्राथमिकता डिलीवरी मिली!"',
    'th': '"อัปเกรดเป็นพรีเมียมได้จดหมายไม่จำกัดและจัดส่งลำดับแรก!"',
  });

  // ── 온보딩 타임라인 ───────────────────────────────────────────────────────
  String get onboardingTimelineTitle => _t({
    'ko': '당신의 하루가 달라져요',
    'en': 'Your day, transformed',
    'ja': 'あなたの一日が変わります',
    'zh': '你的一天将会改变',
    'fr': 'Votre journée, transformée',
    'de': 'Ihr Tag, verwandelt',
    'es': 'Tu día, transformado',
    'pt': 'Seu dia, transformado',
    'ru': 'Ваш день преобразится',
    'tr': 'Gününüz değişecek',
    'ar': 'يومك سيتغير',
    'it': 'La tua giornata, trasformata',
    'hi': 'आपका दिन बदल जाएगा',
    'th': 'วันของคุณจะเปลี่ยนไป',
  });

  String get onboardingTimelineMorning => _t({
    'ko': '아침',
    'en': 'MORNING',
    'ja': '朝',
    'zh': '早晨',
    'fr': 'MATIN',
    'de': 'MORGEN',
    'es': 'MAÑANA',
    'pt': 'MANHÃ',
    'ru': 'УТРО',
    'tr': 'SABAH',
    'ar': 'الصباح',
    'it': 'MATTINA',
    'hi': 'सुबह',
    'th': 'เช้า',
  });

  String get onboardingTimelineMorningFree => _t({
    'ko': '홍보 1통 발송',
    'en': 'Send 1 promo',
    'ja': '手紙1通送信',
    'zh': '发送1封信',
    'fr': 'Envoyer 1 lettre',
    'de': '1 Brief senden',
    'es': 'Enviar 1 carta',
    'pt': 'Enviar 1 carta',
    'ru': 'Отправить 1 письмо',
    'tr': '1 mektup gönder',
    'ar': 'إرسال رسالة واحدة',
    'it': 'Invia 1 lettera',
    'hi': '1 पत्र भेजें',
    'th': 'ส่งจดหมาย 1 ฉบับ',
  });

  String get onboardingTimelineMorningPremium => _t({
    'ko': '인연의 기회 10배, 사진과 함께',
    'en': '10x more connections, with photos',
    'ja': '出会いの機会10倍、写真付き',
    'zh': '10倍缘分机会，附带照片',
    'fr': '10x plus de connexions, avec photos',
    'de': '10x mehr Verbindungen, mit Fotos',
    'es': '10x más conexiones, con fotos',
    'pt': '10x mais conexões, com fotos',
    'ru': 'В 10 раз больше связей, с фото',
    'tr': '10 kat daha fazla bağlantı, fotoğraflarla',
    'ar': 'اتصالات أكثر 10 مرات، مع صور',
    'it': '10x più connessioni, con foto',
    'hi': '10 गुना अधिक कनेक्शन, फोटो के साथ',
    'th': 'การเชื่อมต่อมากขึ้น 10 เท่า พร้อมรูปภาพ',
  });

  String get onboardingTimelineAfternoon => _t({
    'ko': '오후',
    'en': 'AFTERNOON',
    'ja': '午後',
    'zh': '下午',
    'fr': 'APRÈS-MIDI',
    'de': 'NACHMITTAG',
    'es': 'TARDE',
    'pt': 'TARDE',
    'ru': 'ДЕНЬ',
    'tr': 'ÖĞLEDEN SONRA',
    'ar': 'بعد الظهر',
    'it': 'POMERIGGIO',
    'hi': 'दोपहर',
    'th': 'บ่าย',
  });

  String get onboardingTimelineAfternoonFree => _t({
    'ko': '답장을 기다리는 중...',
    'en': 'Waiting for replies...',
    'ja': '返信を待っている...',
    'zh': '等待回信中...',
    'fr': 'En attente de réponses...',
    'de': 'Warten auf Antworten...',
    'es': 'Esperando respuestas...',
    'pt': 'Aguardando respostas...',
    'ru': 'Ожидание ответов...',
    'tr': 'Yanıtlar bekleniyor...',
    'ar': 'في انتظار الردود...',
    'it': 'In attesa di risposte...',
    'hi': 'जवाब का इंतज़ार...',
    'th': 'รอการตอบกลับ...',
  });

  String get onboardingTimelineAfternoonPremium => _t({
    'ko': '특송 배달로 이미 3통 도착',
    'en': '3 promos already arrived via express',
    'ja': '特急便で既に3通到着',
    'zh': '特快配送已收到3封',
    'fr': '3 lettres déjà arrivées par express',
    'de': '3 Briefe bereits per Express angekommen',
    'es': '3 cartas ya llegaron por exprés',
    'pt': '3 cartas já chegaram via expresso',
    'ru': '3 письма уже доставлены экспрессом',
    'tr': 'Ekspresle zaten 3 mektup geldi',
    'ar': '3 رسائل وصلت بالفعل عبر البريد السريع',
    'it': '3 lettere già arrivate via express',
    'hi': 'एक्सप्रेस से पहले ही 3 पत्र आ चुके',
    'th': 'จดหมาย 3 ฉบับมาถึงแล้วทางด่วน',
  });

  String get onboardingTimelineEvening => _t({
    'ko': '저녁',
    'en': 'EVENING',
    'ja': '夜',
    'zh': '晚上',
    'fr': 'SOIR',
    'de': 'ABEND',
    'es': 'NOCHE',
    'pt': 'NOITE',
    'ru': 'ВЕЧЕР',
    'tr': 'AKŞAM',
    'ar': 'المساء',
    'it': 'SERA',
    'hi': 'शाम',
    'th': 'เย็น',
  });

  String get onboardingTimelineEveningFree => _t({
    'ko': '오늘은 여기까지',
    'en': "That's it for today",
    'ja': '今日はここまで',
    'zh': '今天就到这里',
    'fr': "C'est tout pour aujourd'hui",
    'de': 'Das war es für heute',
    'es': 'Eso es todo por hoy',
    'pt': 'Isso é tudo por hoje',
    'ru': 'На сегодня всё',
    'tr': 'Bugünlük bu kadar',
    'ar': 'هذا كل شيء لليوم',
    'it': 'Per oggi è tutto',
    'hi': 'आज के लिए बस इतना',
    'th': 'วันนี้แค่นี้',
  });

  String get onboardingTimelineEveningBrand => _t({
    'ko': '월 10,000명에게 내 브랜드 전달 완료',
    'en': 'Brand delivered to 10,000 people/month',
    'ja': '月10,000人にブランドを届け完了',
    'zh': '每月向10,000人传递我的品牌',
    'fr': 'Marque diffusée à 10 000 personnes/mois',
    'de': 'Marke an 10.000 Menschen/Monat geliefert',
    'es': 'Marca entregada a 10.000 personas/mes',
    'pt': 'Marca entregue a 10.000 pessoas/mês',
    'ru': 'Бренд доставлен 10 000 людям в месяц',
    'tr': 'Marka ayda 10.000 kişiye ulaştırıldı',
    'ar': 'العلامة التجارية وصلت إلى 10,000 شخص/شهر',
    'it': 'Brand consegnato a 10.000 persone/mese',
    'hi': 'ब्रांड 10,000 लोगों/माह तक पहुंचाया गया',
    'th': 'แบรนด์ส่งถึง 10,000 คน/เดือน',
  });

  String get onboardingLiveStats => _t({
    'ko': '실사용 지표',
    'en': 'Live Stats',
    'ja': 'リアル統計',
    'zh': '实时数据',
    'fr': 'Statistiques en direct',
    'de': 'Live-Statistiken',
    'es': 'Estadísticas en vivo',
    'pt': 'Estatísticas ao vivo',
    'ru': 'Статистика в реальном времени',
    'tr': 'Canlı istatistikler',
    'ar': 'إحصائيات مباشرة',
    'it': 'Statistiche in tempo reale',
    'hi': 'लाइव आँकड़े',
    'th': 'สถิติสด',
  });

  String get onboardingFreeStartHint => _t({
    'ko': '지금 무료로 시작하고, 언제든지 업그레이드할 수 있어요.',
    'en': 'Start for free now and upgrade anytime.',
    'ja': '今すぐ無料で始めて、いつでもアップグレードできます。',
    'zh': '立即免费开始，随时可以升级。',
    'fr': 'Commencez gratuitement et passez à la version supérieure quand vous voulez.',
    'de': 'Starten Sie jetzt kostenlos und upgraden Sie jederzeit.',
    'es': 'Empieza gratis ahora y mejora cuando quieras.',
    'pt': 'Comece grátis agora e atualize quando quiser.',
    'ru': 'Начните бесплатно и обновитесь в любое время.',
    'tr': 'Şimdi ücretsiz başlayın ve istediğiniz zaman yükseltin.',
    'ar': 'ابدأ مجانًا الآن وقم بالترقية في أي وقت.',
    'it': 'Inizia gratis ora e aggiorna quando vuoi.',
    'hi': 'अभी मुफ़्त में शुरू करें और कभी भी अपग्रेड करें।',
    'th': 'เริ่มต้นฟรีตอนนี้ และอัปเกรดได้ทุกเมื่อ',
  });

  String get onboardingPerMonth => _t({
    'ko': '/월',
    'en': '/mo',
    'ja': '/月',
    'zh': '/月',
    'fr': '/mois',
    'de': '/Monat',
    'es': '/mes',
    'pt': '/mês',
    'ru': '/мес',
    'tr': '/ay',
    'ar': '/شهر',
    'it': '/mese',
    'hi': '/माह',
    'th': '/เดือน',
  });


  // ── Letter Read Screen ──────────────────────────────────────────────
  // ── Letter Read Screen ───────────────────────────────────────────────────

  String letterReadCannotOpenLink(String url) => _t({
    'ko': '링크를 열 수 없어요: $url',
    'en': 'Cannot open link: $url',
    'ja': 'リンクを開けません: $url',
    'zh': '无法打开链接: $url',
    'fr': 'Impossible d\'ouvrir le lien : $url',
    'de': 'Link kann nicht geöffnet werden: $url',
    'es': 'No se puede abrir el enlace: $url',
    'pt': 'Não foi possível abrir o link: $url',
    'ru': 'Не удалось открыть ссылку: $url',
    'tr': 'Bağlantı açılamıyor: $url',
    'ar': 'لا يمكن فتح الرابط: $url',
    'it': 'Impossibile aprire il link: $url',
    'hi': 'लिंक नहीं खोला जा सका: $url',
    'th': 'ไม่สามารถเปิดลิงก์ได้: $url',
  });

  String get letterReadTranslationEmpty => _t({
    'ko': '번역 결과를 가져오지 못했어요',
    'en': 'Could not retrieve translation',
    'ja': '翻訳結果を取得できませんでした',
    'zh': '无法获取翻译结果',
    'fr': 'Impossible de récupérer la traduction',
    'de': 'Übersetzung konnte nicht abgerufen werden',
    'es': 'No se pudo obtener la traducción',
    'pt': 'Não foi possível obter a tradução',
    'ru': 'Не удалось получить перевод',
    'tr': 'Çeviri sonucu alınamadı',
    'ar': 'تعذر الحصول على الترجمة',
    'it': 'Impossibile ottenere la traduzione',
    'hi': 'अनुवाद परिणाम प्राप्त नहीं हो सका',
    'th': 'ไม่สามารถดึงผลการแปลได้',
  });

  String get letterReadTranslationError => _t({
    'ko': '번역 중 오류가 발생했어요',
    'en': 'An error occurred during translation',
    'ja': '翻訳中にエラーが発生しました',
    'zh': '翻译过程中出现错误',
    'fr': 'Une erreur est survenue lors de la traduction',
    'de': 'Bei der Übersetzung ist ein Fehler aufgetreten',
    'es': 'Ocurrió un error durante la traducción',
    'pt': 'Ocorreu um erro durante a tradução',
    'ru': 'Произошла ошибка при переводе',
    'tr': 'Çeviri sırasında bir hata oluştu',
    'ar': 'حدث خطأ أثناء الترجمة',
    'it': 'Si è verificato un errore durante la traduzione',
    'hi': 'अनुवाद के दौरान त्रुटि हुई',
    'th': 'เกิดข้อผิดพลาดระหว่างการแปล',
  });

  String get letterReadReportReasonAbuse => _t({
    'ko': '욕설 / 혐오 표현',
    'en': 'Profanity / Hate speech',
    'ja': '暴言 / ヘイトスピーチ',
    'zh': '辱骂 / 仇恨言论',
    'fr': 'Injures / Discours haineux',
    'de': 'Beleidigung / Hassrede',
    'es': 'Insultos / Discurso de odio',
    'pt': 'Palavrões / Discurso de ódio',
    'ru': 'Оскорбления / Язык ненависти',
    'tr': 'Küfür / Nefret söylemi',
    'ar': 'شتائم / خطاب كراهية',
    'it': 'Insulti / Discorso d\'odio',
    'hi': 'गाली / घृणा भाषण',
    'th': 'คำหยาบ / ถ้อยคำแห่งความเกลียดชัง',
  });

  String get letterReadReportReasonSpam => _t({
    'ko': '스팸 / 광고성 내용',
    'en': 'Spam / Advertising',
    'ja': 'スパム / 広告',
    'zh': '垃圾信息 / 广告',
    'fr': 'Spam / Publicité',
    'de': 'Spam / Werbung',
    'es': 'Spam / Publicidad',
    'pt': 'Spam / Publicidade',
    'ru': 'Спам / Реклама',
    'tr': 'Spam / Reklam',
    'ar': 'بريد مزعج / إعلانات',
    'it': 'Spam / Pubblicità',
    'hi': 'स्पैम / विज्ञापन',
    'th': 'สแปม / โฆษณา',
  });

  String get letterReadReportReasonPrivacy => _t({
    'ko': '개인정보 침해',
    'en': 'Privacy violation',
    'ja': '個人情報の侵害',
    'zh': '隐私侵犯',
    'fr': 'Violation de la vie privée',
    'de': 'Datenschutzverletzung',
    'es': 'Violación de privacidad',
    'pt': 'Violação de privacidade',
    'ru': 'Нарушение конфиденциальности',
    'tr': 'Gizlilik ihlali',
    'ar': 'انتهاك الخصوصية',
    'it': 'Violazione della privacy',
    'hi': 'गोपनीयता का उल्लंघन',
    'th': 'ละเมิดความเป็นส่วนตัว',
  });

  String get letterReadReportTitle => _t({
    'ko': '혜택 신고',
    'en': 'Report Reward',
    'ja': '手紙を報告',
    'zh': '举报信件',
    'fr': 'Signaler la lettre',
    'de': 'Brief melden',
    'es': 'Reportar carta',
    'pt': 'Denunciar carta',
    'ru': 'Пожаловаться на письмо',
    'tr': 'Mektubu şikayet et',
    'ar': 'الإبلاغ عن الرسالة',
    'it': 'Segnala lettera',
    'hi': 'पत्र की रिपोर्ट करें',
    'th': 'รายงานจดหมาย',
  });

  String get letterReadReportDescription => _t({
    'ko': '신고 이유를 선택해주세요.\n3회 이상 신고 시 발신자가 자동 차단됩니다.',
    'en': 'Please select a reason for your report.\nThe sender will be automatically blocked after 3 or more reports.',
    'ja': '報告理由を選択してください。\n3回以上報告されると送信者は自動的にブロックされます。',
    'zh': '请选择举报原因。\n被举报3次以上，发件人将被自动屏蔽。',
    'fr': 'Veuillez sélectionner un motif de signalement.\nL\'expéditeur sera automatiquement bloqué après 3 signalements ou plus.',
    'de': 'Bitte wählen Sie einen Grund für Ihre Meldung.\nDer Absender wird nach 3 oder mehr Meldungen automatisch gesperrt.',
    'es': 'Selecciona un motivo para tu reporte.\nEl remitente será bloqueado automáticamente tras 3 o más reportes.',
    'pt': 'Selecione um motivo para a denúncia.\nO remetente será bloqueado automaticamente após 3 ou mais denúncias.',
    'ru': 'Выберите причину жалобы.\nОтправитель будет автоматически заблокирован после 3 и более жалоб.',
    'tr': 'Şikayet nedeninizi seçin.\n3 veya daha fazla şikayette gönderen otomatik olarak engellenir.',
    'ar': 'يرجى اختيار سبب البلاغ.\nسيتم حظر المرسل تلقائيًا بعد 3 بلاغات أو أكثر.',
    'it': 'Seleziona un motivo per la segnalazione.\nIl mittente verrà bloccato automaticamente dopo 3 o più segnalazioni.',
    'hi': 'कृपया रिपोर्ट का कारण चुनें।\n3 या अधिक रिपोर्ट के बाद प्रेषक स्वचालित रूप से ब्लॉक हो जाएगा।',
    'th': 'กรุณาเลือกเหตุผลในการรายงาน\nผู้ส่งจะถูกบล็อกอัตโนมัติหลังจากถูกรายงาน 3 ครั้งขึ้นไป',
  });

  String get letterReadReportCustomInput => _t({
    'ko': '직접 입력',
    'en': 'Custom input',
    'ja': '直接入力',
    'zh': '自定义输入',
    'fr': 'Saisie personnalisée',
    'de': 'Eigene Eingabe',
    'es': 'Entrada personalizada',
    'pt': 'Entrada personalizada',
    'ru': 'Свой вариант',
    'tr': 'Özel giriş',
    'ar': 'إدخال مخصص',
    'it': 'Inserimento personalizzato',
    'hi': 'कस्टम इनपुट',
    'th': 'กรอกเอง',
  });

  String get letterReadReportHint => _t({
    'ko': '신고 이유를 입력해주세요...',
    'en': 'Please enter the reason for your report...',
    'ja': '報告理由を入力してください…',
    'zh': '请输入举报原因…',
    'fr': 'Veuillez entrer le motif du signalement…',
    'de': 'Bitte geben Sie den Grund für Ihre Meldung ein…',
    'es': 'Ingrese el motivo de su reporte…',
    'pt': 'Insira o motivo da denúncia…',
    'ru': 'Введите причину жалобы…',
    'tr': 'Şikayet nedeninizi girin…',
    'ar': 'يرجى إدخال سبب البلاغ…',
    'it': 'Inserisci il motivo della segnalazione…',
    'hi': 'कृपया रिपोर्ट का कारण दर्ज करें…',
    'th': 'กรุณากรอกเหตุผลในการรายงาน…',
  });

  String get letterReadCancel => _t({
    'ko': '취소',
    'en': 'Cancel',
    'ja': 'キャンセル',
    'zh': '取消',
    'fr': 'Annuler',
    'de': 'Abbrechen',
    'es': 'Cancelar',
    'pt': 'Cancelar',
    'ru': 'Отмена',
    'tr': 'İptal',
    'ar': 'إلغاء',
    'it': 'Annulla',
    'hi': 'रद्द करें',
    'th': 'ยกเลิก',
  });

  String letterReadReportSubmitted(String reason) => _t({
    'ko': '신고 접수: $reason',
    'en': 'Report submitted: $reason',
    'ja': '報告を受け付けました: $reason',
    'zh': '举报已提交: $reason',
    'fr': 'Signalement soumis : $reason',
    'de': 'Meldung eingereicht: $reason',
    'es': 'Reporte enviado: $reason',
    'pt': 'Denúncia enviada: $reason',
    'ru': 'Жалоба отправлена: $reason',
    'tr': 'Şikayet gönderildi: $reason',
    'ar': 'تم إرسال البلاغ: $reason',
    'it': 'Segnalazione inviata: $reason',
    'hi': 'रिपोर्ट दर्ज: $reason',
    'th': 'ส่งรายงานแล้ว: $reason',
  });

  String get letterReadReportSubmit => _t({
    'ko': '신고',
    'en': 'Report',
    'ja': '報告',
    'zh': '举报',
    'fr': 'Signaler',
    'de': 'Melden',
    'es': 'Reportar',
    'pt': 'Denunciar',
    'ru': 'Пожаловаться',
    'tr': 'Şikayet et',
    'ar': 'إبلاغ',
    'it': 'Segnala',
    'hi': 'रिपोर्ट',
    'th': 'รายงาน',
  });

  String get letterReadRatePrompt => _t({
    'ko': '이 혜택을 평가해주세요',
    'en': 'Rate this reward',
    'ja': 'この手紙を評価してください',
    'zh': '请为这封信评分',
    'fr': 'Évaluez cette lettre',
    'de': 'Bewerten Sie diesen Brief',
    'es': 'Califica esta carta',
    'pt': 'Avalie esta carta',
    'ru': 'Оцените это письмо',
    'tr': 'Bu mektubu değerlendirin',
    'ar': 'قيّم هذه الرسالة',
    'it': 'Valuta questa lettera',
    'hi': 'इस पत्र को रेट करें',
    'th': 'ให้คะแนนจดหมายนี้',
  });

  String get letterReadVerifiedAccount => _t({
    'ko': '✓ 인증 계정',
    'en': '✓ Verified',
    'ja': '✓ 認証済み',
    'zh': '✓ 已认证',
    'fr': '✓ Vérifié',
    'de': '✓ Verifiziert',
    'es': '✓ Verificado',
    'pt': '✓ Verificado',
    'ru': '✓ Подтверждён',
    'tr': '✓ Doğrulanmış',
    'ar': '✓ موثّق',
    'it': '✓ Verificato',
    'hi': '✓ सत्यापित',
    'th': '✓ ยืนยันแล้ว',
  });

  String get letterReadReportAction => _t({
    'ko': '신고하기',
    'en': 'Report',
    'ja': '報告する',
    'zh': '举报',
    'fr': 'Signaler',
    'de': 'Melden',
    'es': 'Reportar',
    'pt': 'Denunciar',
    'ru': 'Пожаловаться',
    'tr': 'Şikayet et',
    'ar': 'إبلاغ',
    'it': 'Segnala',
    'hi': 'रिपोर्ट करें',
    'th': 'รายงาน',
  });

  String letterReadRatingConfirm(int rating) => _t({
    'ko': '⭐ ${rating}점 남겨주셨어요! (수집첩 나가기 전까지 변경 가능)',
    'en': '⭐ You rated $rating stars! (Can be changed before leaving)',
    'ja': '⭐ ${rating}点をつけました！（退出前に変更可能）',
    'zh': '⭐ 您评了${rating}分！（离开前可以修改）',
    'fr': '⭐ Vous avez donné $rating étoiles ! (Modifiable avant de quitter)',
    'de': '⭐ Sie haben $rating Sterne vergeben! (Änderbar vor dem Verlassen)',
    'es': '⭐ ¡Has dado $rating estrellas! (Puedes cambiar antes de salir)',
    'pt': '⭐ Você deu $rating estrelas! (Pode alterar antes de sair)',
    'ru': '⭐ Вы поставили $rating! (Можно изменить до выхода)',
    'tr': '⭐ $rating yıldız verdiniz! (Çıkmadan önce değiştirilebilir)',
    'ar': '⭐ لقد أعطيت $rating نجوم! (يمكن التغيير قبل المغادرة)',
    'it': '⭐ Hai dato $rating stelle! (Modificabile prima di uscire)',
    'hi': '⭐ आपने $rating स्टार दिए! (बाहर जाने से पहले बदल सकते हैं)',
    'th': '⭐ คุณให้ $rating ดาว! (เปลี่ยนได้ก่อนออก)',
  });

  String get letterReadReceivedLetter => _t({
    'ko': '🎟 받은 혜택',
    'en': '🎟 Received Reward',
    'ja': '✉️  受信した手紙',
    'zh': '✉️  收到的信',
    'fr': '✉️  Lettre reçue',
    'de': '✉️  Empfangener Brief',
    'es': '✉️  Carta recibida',
    'pt': '✉️  Carta recebida',
    'ru': '✉️  Полученное письмо',
    'tr': '✉️  Gelen Mektup',
    'ar': '✉️  رسالة واردة',
    'it': '✉️  Lettera ricevuta',
    'hi': '✉️  प्राप्त पत्र',
    'th': '✉️  จดหมายที่ได้รับ',
  });

  String get letterReadAnonymousSender => _t({
    'ko': '🎭 익명의 발신자',
    'en': '🎭 Anonymous Sender',
    'ja': '🎭 匿名の送信者',
    'zh': '🎭 匿名发件人',
    'fr': '🎭 Expéditeur anonyme',
    'de': '🎭 Anonymer Absender',
    'es': '🎭 Remitente anónimo',
    'pt': '🎭 Remetente anônimo',
    'ru': '🎭 Анонимный отправитель',
    'tr': '🎭 Anonim Gönderen',
    'ar': '🎭 مرسل مجهول',
    'it': '🎭 Mittente anonimo',
    'hi': '🎭 गुमनाम प्रेषक',
    'th': '🎭 ผู้ส่งนิรนาม',
  });

  String get letterReadVerifiedBadge => _t({
    'ko': '✓ 인증',
    'en': '✓ Verified',
    'ja': '✓ 認証',
    'zh': '✓ 认证',
    'fr': '✓ Vérifié',
    'de': '✓ Verifiziert',
    'es': '✓ Verificado',
    'pt': '✓ Verificado',
    'ru': '✓ Подтв.',
    'tr': '✓ Doğrulanmış',
    'ar': '✓ موثّق',
    'it': '✓ Verificato',
    'hi': '✓ सत्यापित',
    'th': '✓ ยืนยัน',
  });

  String letterReadDepartedFrom(String country) => _t({
    'ko': '${country}에서 출발',
    'en': 'Departed from $country',
    'ja': '${country}から出発',
    'zh': '从${country}出发',
    'fr': 'Envoyé depuis $country',
    'de': 'Abgeschickt aus $country',
    'es': 'Enviado desde $country',
    'pt': 'Enviado de $country',
    'ru': 'Отправлено из $country',
    'tr': '$country\'den gönderildi',
    'ar': 'أُرسل من $country',
    'it': 'Inviato da $country',
    'hi': '$country से भेजा गया',
    'th': 'ส่งจาก $country',
  });

  String letterReadFollowed(String name) => _t({
    'ko': '${name}님을 팔로우했습니다 ⚡',
    'en': 'You followed $name ⚡',
    'ja': '${name}さんをフォローしました ⚡',
    'zh': '已关注 $name ⚡',
    'fr': 'Vous suivez maintenant $name ⚡',
    'de': 'Du folgst jetzt $name ⚡',
    'es': 'Ahora sigues a $name ⚡',
    'pt': 'Agora você segue $name ⚡',
    'ru': 'Вы подписались на $name ⚡',
    'tr': '$name takip edildi ⚡',
    'ar': 'تمت متابعة $name ⚡',
    'it': 'Ora segui $name ⚡',
    'hi': '$name को फॉलो किया ⚡',
    'th': 'ติดตาม $name แล้ว ⚡',
  });

  String get letterReadFollowing => _t({
    'ko': '⚡ 팔로잉',
    'en': '⚡ Following',
    'ja': '⚡ フォロー中',
    'zh': '⚡ 已关注',
    'fr': '⚡ Abonné',
    'de': '⚡ Folge ich',
    'es': '⚡ Siguiendo',
    'pt': '⚡ Seguindo',
    'ru': '⚡ Подписан',
    'tr': '⚡ Takip ediliyor',
    'ar': '⚡ متابَع',
    'it': '⚡ Segui già',
    'hi': '⚡ फॉलो कर रहे हैं',
    'th': '⚡ กำลังติดตาม',
  });

  String get letterReadFollow => _t({
    'ko': '+ 팔로우',
    'en': '+ Follow',
    'ja': '+ フォロー',
    'zh': '+ 关注',
    'fr': '+ Suivre',
    'de': '+ Folgen',
    'es': '+ Seguir',
    'pt': '+ Seguir',
    'ru': '+ Подписаться',
    'tr': '+ Takip et',
    'ar': '+ متابعة',
    'it': '+ Segui',
    'hi': '+ फॉलो',
    'th': '+ ติดตาม',
  });

  String letterReadMutualFollow(String name) => _t({
    'ko': '${name}님도 팔로우 중이에요!',
    'en': '$name is also following you!',
    'ja': '${name}さんもフォロー中です！',
    'zh': '$name 也在关注你！',
    'fr': '$name vous suit aussi !',
    'de': '$name folgt dir auch!',
    'es': '¡$name también te sigue!',
    'pt': '$name também está te seguindo!',
    'ru': '$name тоже подписан на вас!',
    'tr': '$name de seni takip ediyor!',
    'ar': '$name يتابعك أيضًا!',
    'it': 'Anche $name ti segue!',
    'hi': '$name भी आपको फॉलो कर रहे हैं!',
    'th': '$name ก็กำลังติดตามคุณอยู่!',
  });

  String get letterReadStartChatPrompt => _t({
    'ko': '빠른 1:1 대화를 시작하시겠어요?',
    'en': 'Would you like to start a 1:1 chat?',
    'ja': '1:1のレターチャットを始めますか？',
    'zh': '要开始1:1信件对话吗？',
    'fr': 'Voulez-vous démarrer une discussion 1:1 ?',
    'de': 'Möchten Sie einen 1:1-Briefchat starten?',
    'es': '¿Quieres iniciar una conversación 1:1?',
    'pt': 'Deseja iniciar uma conversa 1:1?',
    'ru': 'Начать переписку 1:1?',
    'tr': '1:1 mektup sohbeti başlatmak ister misiniz?',
    'ar': 'هل ترغب في بدء محادثة 1:1؟',
    'it': 'Vuoi iniziare una chat 1:1?',
    'hi': 'क्या आप 1:1 पत्र चैट शुरू करना चाहेंगे?',
    'th': 'ต้องการเริ่มแชทจดหมาย 1:1 ไหม?',
  });

  String get letterReadStartChat => _t({
    'ko': '💬 대화 시작',
    'en': '💬 Start Chat',
    'ja': '💬 チャット開始',
    'zh': '💬 开始对话',
    'fr': '💬 Démarrer le chat',
    'de': '💬 Chat starten',
    'es': '💬 Iniciar chat',
    'pt': '💬 Iniciar conversa',
    'ru': '💬 Начать чат',
    'tr': '💬 Sohbeti başlat',
    'ar': '💬 بدء المحادثة',
    'it': '💬 Inizia chat',
    'hi': '💬 चैट शुरू करें',
    'th': '💬 เริ่มแชท',
  });

  String get letterReadLater => _t({
    'ko': '나중에',
    'en': 'Later',
    'ja': '後で',
    'zh': '稍后',
    'fr': 'Plus tard',
    'de': 'Später',
    'es': 'Más tarde',
    'pt': 'Mais tarde',
    'ru': 'Позже',
    'tr': 'Sonra',
    'ar': 'لاحقًا',
    'it': 'Dopo',
    'hi': 'बाद में',
    'th': 'ภายหลัง',
  });

  String letterReadDmChat(String name) => _t({
    'ko': '${name}님과 DM 대화',
    'en': 'DM with $name',
    'ja': '${name}さんとDM',
    'zh': '与 $name 私信',
    'fr': 'DM avec $name',
    'de': 'DM mit $name',
    'es': 'DM con $name',
    'pt': 'DM com $name',
    'ru': 'ЛС с $name',
    'tr': '$name ile DM',
    'ar': 'رسالة مباشرة مع $name',
    'it': 'DM con $name',
    'hi': '$name के साथ DM',
    'th': 'DM กับ $name',
  });

  String get letterReadToYou => _t({
    'ko': '당신에게',
    'en': 'To you',
    'ja': 'あなたへ',
    'zh': '致你',
    'fr': 'Pour vous',
    'de': 'An dich',
    'es': 'Para ti',
    'pt': 'Para você',
    'ru': 'Тебе',
    'tr': 'Sana',
    'ar': 'إليك',
    'it': 'A te',
    'hi': 'आपके लिए',
    'th': 'ถึงคุณ',
  });

  // Build 182: 본문이 네트워크 이슈로 비어 있을 때 fallback 라벨.
  String get letterReadBodyUnavailable => _t({
    'ko': '본문을 불러오는 중이에요…',
    'en': 'Loading message…',
    'ja': '本文を読み込み中…',
    'zh': '正在加载内容…',
    'fr': 'Chargement du message…',
    'de': 'Nachricht wird geladen…',
    'es': 'Cargando mensaje…',
    'pt': 'A carregar mensagem…',
    'ru': 'Загрузка сообщения…',
    'tr': 'Mesaj yükleniyor…',
    'ar': 'جارٍ تحميل الرسالة…',
    'it': 'Caricamento messaggio…',
    'hi': 'संदेश लोड हो रहा है…',
    'th': 'กำลังโหลดข้อความ…',
  });

  String letterReadTranslated(String lang) => _t({
    'ko': '🔤 번역됨 ($lang)',
    'en': '🔤 Translated ($lang)',
    'ja': '🔤 翻訳済み ($lang)',
    'zh': '🔤 已翻译 ($lang)',
    'fr': '🔤 Traduit ($lang)',
    'de': '🔤 Übersetzt ($lang)',
    'es': '🔤 Traducido ($lang)',
    'pt': '🔤 Traduzido ($lang)',
    'ru': '🔤 Переведено ($lang)',
    'tr': '🔤 Çevrildi ($lang)',
    'ar': '🔤 مترجم ($lang)',
    'it': '🔤 Tradotto ($lang)',
    'hi': '🔤 अनुवादित ($lang)',
    'th': '🔤 แปลแล้ว ($lang)',
  });

  String get letterReadShowOriginal => _t({
    'ko': '🔤 원문 보기',
    'en': '🔤 Show original',
    'ja': '🔤 原文を表示',
    'zh': '🔤 查看原文',
    'fr': '🔤 Voir l\'original',
    'de': '🔤 Original anzeigen',
    'es': '🔤 Ver original',
    'pt': '🔤 Ver original',
    'ru': '🔤 Показать оригинал',
    'tr': '🔤 Orijinali göster',
    'ar': '🔤 عرض الأصل',
    'it': '🔤 Mostra originale',
    'hi': '🔤 मूल दिखाएं',
    'th': '🔤 แสดงต้นฉบับ',
  });

  String get letterReadTranslate => _t({
    'ko': '🔤 번역하기',
    'en': '🔤 Translate',
    'ja': '🔤 翻訳する',
    'zh': '🔤 翻译',
    'fr': '🔤 Traduire',
    'de': '🔤 Übersetzen',
    'es': '🔤 Traducir',
    'pt': '🔤 Traduzir',
    'ru': '🔤 Перевести',
    'tr': '🔤 Çevir',
    'ar': '🔤 ترجمة',
    'it': '🔤 Traduci',
    'hi': '🔤 अनुवाद करें',
    'th': '🔤 แปล',
  });

  String get letterReadAnonymousStranger => _t({
    'ko': '어딘가의 낯선 이',
    'en': 'A stranger somewhere',
    'ja': 'どこかの見知らぬ人',
    'zh': '某处的陌生人',
    'fr': 'Un inconnu quelque part',
    'de': 'Ein Fremder irgendwo',
    'es': 'Un desconocido en algún lugar',
    'pt': 'Um estranho em algum lugar',
    'ru': 'Незнакомец откуда-то',
    'tr': 'Bir yerlerdeki yabancı',
    'ar': 'شخص غريب في مكان ما',
    'it': 'Uno sconosciuto da qualche parte',
    'hi': 'कहीं का अनजान',
    'th': 'คนแปลกหน้าจากที่ไหนสักแห่ง',
  });

  String get letterReadTapToEnlarge => _t({
    'ko': '탭하면 크게 보기 · 저장 가능',
    'en': 'Tap to enlarge · Save',
    'ja': 'タップで拡大 · 保存可能',
    'zh': '点击放大 · 可保存',
    'fr': 'Appuyez pour agrandir · Enregistrer',
    'de': 'Tippen zum Vergrößern · Speichern',
    'es': 'Toca para ampliar · Guardar',
    'pt': 'Toque para ampliar · Salvar',
    'ru': 'Нажмите для увеличения · Сохранить',
    'tr': 'Büyütmek için dokunun · Kaydet',
    'ar': 'انقر للتكبير · حفظ',
    'it': 'Tocca per ingrandire · Salva',
    'hi': 'बड़ा देखने के लिए टैप करें · सेव',
    'th': 'แตะเพื่อขยาย · บันทึกได้',
  });

  String get letterReadSenderLink => _t({
    'ko': '발신자 링크',
    'en': 'Sender link',
    'ja': '送信者リンク',
    'zh': '发件人链接',
    'fr': 'Lien de l\'expéditeur',
    'de': 'Absender-Link',
    'es': 'Enlace del remitente',
    'pt': 'Link do remetente',
    'ru': 'Ссылка отправителя',
    'tr': 'Gönderen bağlantısı',
    'ar': 'رابط المرسل',
    'it': 'Link del mittente',
    'hi': 'प्रेषक लिंक',
    'th': 'ลิงก์ผู้ส่ง',
  });

  String get letterReadDeliveryJourney => _t({
    'ko': '배송 여정',
    'en': 'Delivery Journey',
    'ja': '配送の旅',
    'zh': '配送旅程',
    'fr': 'Parcours de livraison',
    'de': 'Zustellungsreise',
    'es': 'Trayecto de entrega',
    'pt': 'Jornada de entrega',
    'ru': 'Путь доставки',
    'tr': 'Teslimat yolculuğu',
    'ar': 'رحلة التوصيل',
    'it': 'Percorso di consegna',
    'hi': 'डिलीवरी यात्रा',
    'th': 'เส้นทางการจัดส่ง',
  });

  String get letterReadAnonymous => _t({
    'ko': '익명',
    'en': 'Anonymous',
    'ja': '匿名',
    'zh': '匿名',
    'fr': 'Anonyme',
    'de': 'Anonym',
    'es': 'Anónimo',
    'pt': 'Anônimo',
    'ru': 'Аноним',
    'tr': 'Anonim',
    'ar': 'مجهول',
    'it': 'Anonimo',
    'hi': 'गुमनाम',
    'th': 'นิรนาม',
  });

  String get letterReadReplied => _t({
    'ko': '답장 완료 (1회만 가능)',
    'en': 'Replied (one-time only)',
    'ja': '返信済み（1回のみ）',
    'zh': '已回复（仅限一次）',
    'fr': 'Répondu (une seule fois)',
    'de': 'Beantwortet (nur einmal möglich)',
    'es': 'Respondido (solo una vez)',
    'pt': 'Respondido (apenas uma vez)',
    'ru': 'Ответ отправлен (только один раз)',
    'tr': 'Yanıtlandı (yalnızca bir kez)',
    'ar': 'تم الرد (مرة واحدة فقط)',
    'it': 'Risposto (solo una volta)',
    'hi': 'उत्तर दिया (केवल एक बार)',
    'th': 'ตอบแล้ว (ได้ครั้งเดียว)',
  });

  // 브랜드 발송인이 "답장 받지 않음" 으로 설정한 혜택에 표시되는 안내 카드 문구.
  // 답장 버튼이 사라진 대신 "이 캠페인은 답장을 받지 않아요" 한 줄을 띄운다.
  String get letterReadBrandNoReply => _t({
    'ko': '이 캠페인은 답장을 받지 않아요',
    'en': 'This campaign does not accept replies',
    'ja': 'このキャンペーンは返信を受け付けていません',
    'zh': '此活动不接受回复',
    'fr': 'Cette campagne n\'accepte pas de réponse',
    'de': 'Diese Kampagne akzeptiert keine Antworten',
    'es': 'Esta campaña no acepta respuestas',
    'pt': 'Esta campanha não aceita respostas',
    'ru': 'Эта кампания не принимает ответов',
    'tr': 'Bu kampanya yanıt kabul etmiyor',
    'ar': 'هذه الحملة لا تقبل الردود',
    'it': 'Questa campagna non accetta risposte',
    'hi': 'यह अभियान जवाब स्वीकार नहीं करता',
    'th': 'แคมเปญนี้ไม่รับคำตอบ',
  });

  // 브랜드 컴포즈: 쿠폰/교환권 사용 안내 필드 (category != general 시 표시)
  String get composeBrandRedemptionLabel => _t({
    'ko': '사용 방법 안내',
    'en': 'How to redeem',
    'ja': '使い方の案内',
    'zh': '使用方法',
    'fr': 'Mode d\'emploi',
    'de': 'Einlösehinweis',
    'es': 'Cómo usar',
    'pt': 'Como resgatar',
    'ru': 'Как использовать',
    'tr': 'Nasıl kullanılır',
    'ar': 'كيفية الاستخدام',
    'it': 'Come utilizzare',
    'hi': 'कैसे उपयोग करें',
    'th': 'วิธีใช้',
  });

  String get composeBrandRedemptionDesc => _t({
    'ko': '수신자에게 보여줄 코드·링크·매장 안내 등 (최대 200자)',
    'en': 'Code, link, or store instructions shown to the recipient (max 200 chars)',
    'ja': '受信者に表示するコード・リンク・店舗案内など (最大200文字)',
    'zh': '向收件人展示的代码、链接或门店说明 (最多200字)',
    'fr': 'Code, lien ou instructions (200 car. max)',
    'de': 'Code, Link oder Hinweise (max. 200 Zeichen)',
    'es': 'Código, enlace o instrucciones (máx. 200 caracteres)',
    'pt': 'Código, link ou instruções (máx. 200 caracteres)',
    'ru': 'Код, ссылка или инструкция (до 200 символов)',
    'tr': 'Kod, bağlantı veya mağaza bilgisi (maks 200 karakter)',
    'ar': 'رمز أو رابط أو إرشادات (حتى 200 حرف)',
    'it': 'Codice, link o istruzioni (max 200 caratteri)',
    'hi': 'कोड, लिंक, या स्टोर निर्देश (अधिकतम 200 अक्षर)',
    'th': 'รหัส ลิงก์ หรือวิธีการที่ร้าน (ไม่เกิน 200 ตัวอักษร)',
  });

  String get composeBrandRedemptionHint => _t({
    'ko': '예: THISCOUNT20 결제 시 입력',
    'en': 'e.g. Enter THISCOUNT20 at checkout',
    'ja': '例: 決済時に THISCOUNT20 を入力',
    'zh': '例：结账时输入 THISCOUNT20',
    'fr': 'ex : saisir THISCOUNT20 au paiement',
    'de': 'z.B. THISCOUNT20 beim Bezahlen eingeben',
    'es': 'ej: introduce THISCOUNT20 al pagar',
    'pt': 'ex: use THISCOUNT20 no pagamento',
    'ru': 'напр. введите THISCOUNT20 при оплате',
    'tr': 'örn: ödemede THISCOUNT20 girin',
    'ar': 'مثال: أدخل THISCOUNT20 عند الدفع',
    'it': 'es: inserisci THISCOUNT20 al checkout',
    'hi': 'उदा. चेकआउट पर THISCOUNT20 दर्ज करें',
    'th': 'เช่น ใส่ THISCOUNT20 ตอนชำระ',
  });

  // ─────────────────────────────────────────────────────────────────────
  // Build 115 — 소비자 감사 기반 4개 신규 기능. 각 키 묶음 앞에 용도 명시.
  // ─────────────────────────────────────────────────────────────────────

  // 1) 프로필 "나의 레터 기록" 카드 (HuntWalletCard).
  // Build 125: 사용자 정체성 "레터" 통일에 따라 "헌트 기록" → "레터 기록"
  // 으로 교체. 14개 언어 모두 Letter 브랜드명 정합 재작성.
  String get huntWalletTitle => _t({
    'ko': '나의 카운터 기록', 'en': 'My Counter Log', 'ja': '私のカウンター記録',
    'zh': '我的 Counter 记录', 'fr': 'Mon journal Counter', 'de': 'Mein Counter-Log',
    'es': 'Mi registro Counter', 'pt': 'Meu registro Counter',
    'ru': 'Мой Counter-журнал', 'tr': 'Counter kaydım',
    'ar': 'سجل Counter الخاص بي', 'it': 'Il mio diario Counter',
    'hi': 'मेरा Counter लॉग', 'th': 'บันทึก Counter ของฉัน',
  });
  String get huntWalletPickupsMonth => _t({
    'ko': '이번 달 픽업', 'en': 'Pickups this month', 'ja': '今月のピックアップ',
    'zh': '本月拾取', 'fr': 'Ramassées ce mois', 'de': 'Diesen Monat',
    'es': 'Recogidas este mes', 'pt': 'Apanhadas este mês',
    'ru': 'Собрано в месяц', 'tr': 'Bu ay toplandı',
    'ar': 'التقطت هذا الشهر', 'it': 'Raccolte questo mese',
    'hi': 'इस महीने', 'th': 'เดือนนี้',
  });
  String get huntWalletRedeemedMonth => _t({
    'ko': '이번 달 사용', 'en': 'Redeemed this month', 'ja': '今月使用',
    'zh': '本月已使用', 'fr': 'Utilisées ce mois', 'de': 'Eingelöst diesen Monat',
    'es': 'Canjeadas este mes', 'pt': 'Usadas este mês',
    'ru': 'Использовано в месяц', 'tr': 'Bu ay kullanıldı',
    'ar': 'استُخدمت هذا الشهر', 'it': 'Riscattate questo mese',
    'hi': 'इस महीने उपयोग', 'th': 'ใช้เดือนนี้',
  });
  String get huntWalletTotalPickups => _t({
    'ko': '누적 픽업', 'en': 'Total pickups', 'ja': '累計ピックアップ',
    'zh': '累计拾取', 'fr': 'Total ramassées', 'de': 'Gesamt aufgenommen',
    'es': 'Total recogidas', 'pt': 'Total apanhadas',
    'ru': 'Всего собрано', 'tr': 'Toplam toplanan',
    'ar': 'الإجمالي', 'it': 'Totale raccolte',
    'hi': 'कुल पिकअप', 'th': 'รวมทั้งหมด',
  });
  String get huntWalletTotalRedemptions => _t({
    'ko': '누적 사용', 'en': 'Total redemptions', 'ja': '累計使用',
    'zh': '累计使用', 'fr': 'Total utilisées', 'de': 'Gesamt eingelöst',
    'es': 'Total canjeadas', 'pt': 'Total usadas',
    'ru': 'Всего использовано', 'tr': 'Toplam kullanılan',
    'ar': 'إجمالي الاستخدام', 'it': 'Totale riscattate',
    'hi': 'कुल उपयोग', 'th': 'รวมใช้',
  });
  // ─────────────────────────────────────────────────────────────────────
  // Build 120 — 픽업 감각 증폭 UX 로드맵 (7가지). 레벨업 반경 토스트·프로필
  // 반경 바·네비 위 근처 카운터·나침반 힌트·레벨 마일스톤·타워 펄스.
  // ─────────────────────────────────────────────────────────────────────

  String levelUpRadiusDelta(int delta, int newRadius) => _t({
    'ko': '📍 반경 +${delta}m · 이제 ${newRadius}m',
    'en': '📍 Radius +${delta}m · now ${newRadius}m',
    'ja': '📍 範囲 +${delta}m · 現在 ${newRadius}m',
    'zh': '📍 范围 +${delta}米 · 现 ${newRadius}米',
    'fr': '📍 Rayon +${delta} m · ${newRadius} m maintenant',
    'de': '📍 Radius +${delta} m · jetzt ${newRadius} m',
    'es': '📍 Radio +${delta} m · ahora ${newRadius} m',
    'pt': '📍 Raio +${delta} m · agora ${newRadius} m',
    'ru': '📍 Радиус +${delta} м · теперь ${newRadius} м',
    'tr': '📍 Yarıçap +${delta} m · şimdi ${newRadius} m',
    'ar': '📍 نطاق +${delta}م · الآن ${newRadius}م',
    'it': '📍 Raggio +${delta} m · ora ${newRadius} m',
    'hi': '📍 रेडियस +${delta} मी · अब ${newRadius} मी',
    'th': '📍 รัศมี +${delta} ม. · ตอนนี้ ${newRadius} ม.',
  });

  String get huntWalletRadiusTitle => _t({
    'ko': '내 줍기 반경',
    'en': 'My pickup radius',
    'ja': '私の拾える範囲',
    'zh': '我的拾取范围',
    'fr': 'Mon rayon',
    'de': 'Mein Aufsammelradius',
    'es': 'Mi radio',
    'pt': 'Meu raio',
    'ru': 'Мой радиус',
    'tr': 'Yarıçapım',
    'ar': 'نطاقي',
    'it': 'Il mio raggio',
    'hi': 'मेरा रेडियस',
    'th': 'รัศมีของฉัน',
  });

  String huntWalletRadiusValue(int current, int max) => _t({
    'ko': '${current}m · 최대 ${max}m',
    'en': '${current}m · max ${max}m',
    'ja': '${current}m · 最大 ${max}m',
    'zh': '${current}m · 最大 ${max}m',
    'fr': '${current} m · max ${max} m',
    'de': '${current} m · max ${max} m',
    'es': '${current} m · máx ${max} m',
    'pt': '${current} m · máx ${max} m',
    'ru': '${current} м · макс ${max} м',
    'tr': '${current} m · maks ${max} m',
    'ar': '${current}م · الحد ${max}م',
    'it': '${current} m · max ${max} m',
    'hi': '${current} मी · अधिकतम ${max} मी',
    'th': '${current} ม. · สูงสุด ${max} ม.',
  });

  String get huntWalletRadiusUpgradeCta => _t({
    'ko': 'Premium 전환 시 5× 즉시 확대 →',
    'en': 'Go Premium to widen 5× instantly →',
    'ja': 'プレミアムで即 5× 拡大 →',
    'zh': '升级 Premium 立即扩大 5× →',
    'fr': 'Passe en Premium pour élargir 5× →',
    'de': 'Premium: sofort 5× weiter →',
    'es': 'Pásate a Premium para expandir 5× →',
    'pt': 'Vai Premium para expandir 5× →',
    'ru': 'Premium — сразу в 5× шире →',
    'tr': "Premium ile hemen 5× genişle →",
    'ar': 'Premium يوسّعه 5× فوراً →',
    'it': 'Con Premium subito 5× più ampio →',
    'hi': 'Premium से 5× तुरंत बड़ा →',
    'th': 'อัปเป็น Premium กว้างขึ้น 5 เท่าทันที →',
  });

  String mainNavNearbyChip(int n) => _t({
    'ko': '🎟 근처 $n통',
    'en': '🎟 $n nearby',
    'ja': '🎟 近く $n通',
    'zh': '🎟 附近 $n',
    'fr': '🎟 $n à proximité',
    'de': '🎟 $n in der Nähe',
    'es': '🎟 $n cerca',
    'pt': '🎟 $n por perto',
    'ru': '🎟 $n рядом',
    'tr': '🎟 Yakında $n',
    'ar': '🎟 $n قريب',
    'it': '🎟 $n vicino',
    'hi': '🎟 $n पास',
    'th': '🎟 ใกล้ $n',
  });

  // 나침반 힌트 — 주변 반경 내 혜택은 없지만 월드 혜택 중 가장 가까운 것의
  // 방향과 거리. 방향은 화살표 이모지(↑ ↗ → ↘ ↓ ↙ ← ↖) 로 표현해 번역 불필요.
  String mapCompassHint(int meters, String arrow, String categoryEmoji) => _t({
    'ko': '🧭 $arrow ${meters}m — $categoryEmoji 혜택이 있어요',
    'en': '🧭 $arrow ${meters}m — $categoryEmoji reward waiting',
    'ja': '🧭 $arrow ${meters}m に $categoryEmoji 手紙',
    'zh': '🧭 $arrow ${meters}m — $categoryEmoji 信件',
    'fr': "🧭 $arrow ${meters} m — lettre $categoryEmoji",
    'de': '🧭 $arrow ${meters} m — $categoryEmoji Brief',
    'es': '🧭 $arrow ${meters} m — carta $categoryEmoji',
    'pt': '🧭 $arrow ${meters} m — carta $categoryEmoji',
    'ru': '🧭 $arrow ${meters} м — письмо $categoryEmoji',
    'tr': '🧭 $arrow ${meters} m — $categoryEmoji mektup',
    'ar': '🧭 $arrow ${meters}م — رسالة $categoryEmoji',
    'it': '🧭 $arrow ${meters} m — lettera $categoryEmoji',
    'hi': '🧭 $arrow ${meters} मी — $categoryEmoji पत्र',
    'th': '🧭 $arrow ${meters} ม. — จดหมาย $categoryEmoji',
  });

  String milestoneLevelTitle(int level) => _t({
    'ko': '🏆 레벨 $level 달성!',
    'en': '🏆 Level $level reached!',
    'ja': '🏆 レベル $level 到達！',
    'zh': '🏆 达到 $level 级！',
    'fr': '🏆 Niveau $level atteint !',
    'de': '🏆 Level $level erreicht!',
    'es': '🏆 ¡Nivel $level alcanzado!',
    'pt': '🏆 Nível $level alcançado!',
    'ru': '🏆 Уровень $level достигнут!',
    'tr': '🏆 Seviye $level tamam!',
    'ar': '🏆 وصلت للمستوى $level!',
    'it': '🏆 Livello $level raggiunto!',
    'hi': '🏆 स्तर $level प्राप्त!',
    'th': '🏆 ถึงระดับ $level!',
  });

  String milestoneLevelBody(int radius) => _t({
    'ko': '이제 줍기 반경이 ${radius}m 로 넓어졌어요. 더 멀리 주울 수 있어요.',
    'en': 'Your pickup radius is now ${radius}m. Reach further.',
    'ja': '拾える範囲が ${radius}m に広がりました。さらに遠くまで拾えます。',
    'zh': '拾取范围扩大到 ${radius}m。可以走得更远。',
    'fr': 'Ton rayon est maintenant ${radius} m. Va plus loin.',
    'de': 'Dein Radius beträgt jetzt ${radius} m. Greif weiter.',
    'es': 'Tu radio ahora es ${radius} m. Llega más lejos.',
    'pt': 'O teu raio agora é ${radius} m. Chega mais longe.',
    'ru': 'Ваш радиус теперь ${radius} м. Можно дальше.',
    'tr': 'Yarıçapın artık ${radius} m. Daha ileri git.',
    'ar': 'نطاقك الآن ${radius}م. تقدّم أبعد.',
    'it': 'Il tuo raggio è ora ${radius} m. Arriva più lontano.',
    'hi': 'अब आपका रेडियस ${radius} मी है। और दूर पहुँचो।',
    'th': 'รัศมีคุณคือ ${radius} ม. แล้ว ไปไกลขึ้นได้',
  });

  String get milestoneLevelCta => _t({
    'ko': '계속 주우러 가기', 'en': 'Keep hunting', 'ja': '続けて拾う',
    'zh': '继续寻找', 'fr': 'Continuer', 'de': 'Weiter sammeln',
    'es': 'Seguir cazando', 'pt': 'Continuar', 'ru': 'Продолжить',
    'tr': 'Devam', 'ar': 'متابعة', 'it': 'Continua', 'hi': 'जारी रखो',
    'th': 'ไปต่อ',
  });

  String get towerPulseHint => _t({
    'ko': '✨ 내 줍기 반경',
    'en': '✨ My pickup radius',
    'ja': '✨ 私の拾える範囲',
    'zh': '✨ 我的拾取范围',
    'fr': '✨ Mon rayon',
    'de': '✨ Mein Radius',
    'es': '✨ Mi radio',
    'pt': '✨ Meu raio',
    'ru': '✨ Мой радиус',
    'tr': '✨ Yarıçapım',
    'ar': '✨ نطاقي',
    'it': '✨ Il mio raggio',
    'hi': '✨ मेरा रेडियस',
    'th': '✨ รัศมีของฉัน',
  });

  // Build 124: 유저 정체성 명칭 재확정 "레터 (Letter)".
  // Build 123 에서 "레고 (Lego)" 로 지정했지만 The LEGO Group 상표와
  // 직접 충돌(특히 中 乐高 / 日 レゴ / 글로벌 LEGO) 이라 "Letter" 로 전환.
  // "Letter" 는 Thiscount 브랜드명의 핵심 요소이자 일반 명사로 상표 위험
  // 최소. l10n key 이름과 코드 심볼은 기존 `hunter*` 그대로 유지 (내부
  // 식별자, 사용자 노출 없음).
  String get hunterItemsTitle => _t({
    'ko': '카운터 아이템', 'en': 'Counter items', 'ja': 'カウンター アイテム',
    'zh': 'Counter 道具', 'fr': 'Objets Counter', 'de': 'Counter-Ausrüstung',
    'es': 'Objetos Counter', 'pt': 'Itens Counter',
    'ru': 'Снаряжение Counter', 'tr': 'Counter eşyaları',
    'ar': 'أدوات Counter', 'it': 'Oggetti Counter',
    'hi': 'Counter सामान', 'th': 'ไอเท็ม Counter',
  });

  // ─────────────────────────────────────────────────────────────────────
  // Build 127 — 혜택 카테고리 사용법 모달 + 할인권/교환권 구분 카피 +
  // Brand 사업자 인증 UI l10n.
  // ─────────────────────────────────────────────────────────────────────

  String get categoryHelpTitle => _t({
    'ko': '혜택 종류 사용법', 'en': 'Reward types', 'ja': '手紙の種類',
    'zh': '信件类型', 'fr': 'Types de lettres', 'de': 'Brieftypen',
    'es': 'Tipos de carta', 'pt': 'Tipos de carta',
    'ru': 'Типы писем', 'tr': 'Mektup türleri',
    'ar': 'أنواع الرسائل', 'it': 'Tipi di lettera',
    'hi': 'पत्र प्रकार', 'th': 'ประเภทจดหมาย',
  });

  String get categoryHelpCouponDesc => _t({
    'ko': '웹사이트·앱에서 쓸 수 있는 코드 형식 쿠폰. 예: "THISCOUNT20" 같은 문자열을 받은 사람이 결제 시 입력.',
    'en': 'Code-based discount for online use. The receiver types your code (e.g. "THISCOUNT20") at checkout.',
    'ja': 'ウェブサイトやアプリで使えるコード形式のクーポン。例: "THISCOUNT20" のような文字列を決済時に入力。',
    'zh': '网站/APP 使用的代码形式优惠。例如 "THISCOUNT20"，结账时输入即可。',
    'fr': 'Code promo utilisable en ligne. Le destinataire tape ton code (ex : "THISCOUNT20") au paiement.',
    'de': 'Code-basierter Online-Rabatt. Empfänger gibt deinen Code (z. B. "THISCOUNT20") an der Kasse ein.',
    'es': 'Descuento con código para uso online. El receptor introduce tu código (ej. "THISCOUNT20") al pagar.',
    'pt': 'Código de desconto para uso online. O destinatário insere o código (ex. "THISCOUNT20") no pagamento.',
    'ru': 'Промокод для онлайн-оплаты. Получатель вводит ваш код (например, "THISCOUNT20") при оплате.',
    'tr': 'Online kullanım için kod. Alıcı ödemede kodunu ("THISCOUNT20") girer.',
    'ar': 'رمز خصم للاستخدام عبر الإنترنت. يُدخل المستلم الرمز (مثل "THISCOUNT20") عند الدفع.',
    'it': 'Codice sconto per uso online. Il destinatario inserisce il codice (es. "THISCOUNT20") al checkout.',
    'hi': 'ऑनलाइन उपयोग के लिए कोड-आधारित छूट। पाने वाला आपका कोड (जैसे "THISCOUNT20") चेकआउट पर डालता है।',
    'th': 'ส่วนลดแบบรหัสสำหรับใช้ออนไลน์ ผู้รับใส่รหัส (เช่น "THISCOUNT20") ตอนชำระ',
  });

  String get categoryHelpVoucherDesc => _t({
    'ko': '매장·오프라인에서 쓸 수 있는 쿠폰 이미지. 바코드·QR·스탬프 이미지를 업로드해 수신자가 현장에서 보여주고 사용.',
    'en': 'Image coupon for in-store use. Upload a barcode / QR / stamp image the receiver shows at the counter.',
    'ja': '店舗で使える画像クーポン。バーコード・QR・スタンプ画像をアップロードし、受取人がレジで提示。',
    'zh': '线下门店使用的图片优惠。上传条形码 / 二维码 / 图章图片，收件人到店出示即可。',
    'fr': "Bon image pour usage en boutique. Upload un code-barre, QR ou tampon que le destinataire montre en caisse.",
    'de': 'Bild-Gutschein für Laden-Einsatz. Lade einen Barcode/QR/Stempel hoch, den der Empfänger an der Kasse zeigt.',
    'es': 'Cupón de imagen para tienda. Sube un código de barras/QR/sello que el receptor muestra en caja.',
    'pt': 'Cupão de imagem para loja física. Carrega um código de barras/QR/carimbo que o destinatário mostra no balcão.',
    'ru': 'Купон-изображение для магазина. Загрузите штрих-код/QR/штамп — получатель покажет на кассе.',
    'tr': 'Mağazada kullanım için görsel kupon. Barkod/QR/damga yükle, alıcı kasada gösterir.',
    'ar': 'قسيمة صورة للاستخدام في المتجر. ارفع صورة باركود/QR/ختم يعرضها المستلم عند الدفع.',
    'it': 'Coupon immagine per uso in negozio. Carica un codice a barre/QR/timbro che il destinatario mostra alla cassa.',
    'hi': 'दुकान में उपयोग के लिए छवि कूपन। बारकोड/QR/स्टैंप छवि अपलोड करें, पाने वाला काउंटर पर दिखाएगा।',
    'th': 'คูปองแบบรูปใช้ในร้าน อัปโหลดบาร์โค้ด/QR/ตราประทับ ผู้รับแสดงที่เคาน์เตอร์',
  });

  String get categoryHelpGeneralDesc => _t({
    'ko': '일반 브랜드 스토리·공지. 할인 코드나 이미지 없이 자유 메시지를 보낼 때 선택.',
    'en': 'Plain brand message. Use when sending a story, announcement, or greeting without a code or image.',
    'ja': '一般のブランドメッセージ。割引コードや画像なしで自由なメッセージを送るときに。',
    'zh': '普通品牌信息。无优惠码或图片，仅发送品牌故事或通知时选择。',
    'fr': "Message de marque libre. À utiliser pour une annonce ou histoire sans code ni image.",
    'de': 'Freier Marken-Text. Nutze ihn für Story/Ankündigung ohne Code oder Bild.',
    'es': 'Mensaje de marca libre. Úsalo para anuncios o historias sin código ni imagen.',
    'pt': 'Mensagem de marca livre. Usa quando envias uma história ou anúncio sem código ou imagem.',
    'ru': 'Обычное сообщение бренда. Для истории или анонса без кода или изображения.',
    'tr': 'Serbest marka mesajı. Kod veya görsel olmadan hikaye/duyuru gönderirken kullan.',
    'ar': 'رسالة علامة عادية. استخدمها لإرسال قصة أو إعلان دون رمز أو صورة.',
    'it': 'Messaggio di marca libero. Per storie o annunci senza codice o immagine.',
    'hi': 'सामान्य ब्रांड संदेश। कोड या छवि के बिना कहानी/घोषणा भेजते समय चुनें।',
    'th': 'ข้อความแบรนด์ทั่วไป ใช้เมื่อส่งเรื่องราวหรือประกาศโดยไม่มีรหัสหรือรูป',
  });

  String get categoryHelpBrandOnlyNote => _t({
    'ko': '🎟 할인권과 🎁 교환권은 Brand 계정만 발송 가능해요. 무료·Premium 회원은 지도에서 주워서 사용할 수 있어요.',
    'en': '🎟 Coupons and 🎁 Vouchers can only be sent by Brand accounts. Free and Premium users pick them up on the map.',
    'ja': '🎟 割引券と 🎁 交換券は Brand アカウント限定で送信可能。無料・Premium 会員は地図で拾って使えます。',
    'zh': '🎟 优惠券和 🎁 兑换券仅 Brand 账号可发送。免费/Premium 用户在地图上拾取使用。',
    'fr': '🎟 Coupons et 🎁 Bons : envoi réservé aux comptes Brand. Utilisateurs Gratuit/Premium les ramassent sur la carte.',
    'de': '🎟 Gutscheine und 🎁 Bons können nur Brand-Accounts senden. Free/Premium-User sammeln sie auf der Karte.',
    'es': '🎟 Cupones y 🎁 Vales solo los envían cuentas Brand. Los usuarios Gratis/Premium los recogen en el mapa.',
    'pt': '🎟 Cupões e 🎁 Vales só são enviados por contas Brand. Free/Premium apanham no mapa.',
    'ru': '🎟 Купоны и 🎁 Ваучеры отправляют только Brand-аккаунты. Free/Premium подбирают их на карте.',
    'tr': '🎟 Kupon ve 🎁 Fiş sadece Brand hesapları gönderir. Ücretsiz/Premium haritadan toplar.',
    'ar': '🎟 الكوبونات و 🎁 القسائم يرسلها حسابات Brand فقط. يلتقطها Free/Premium من الخريطة.',
    'it': '🎟 Coupon e 🎁 Buoni solo da account Brand. Gli utenti Free/Premium li raccolgono dalla mappa.',
    'hi': '🎟 कूपन और 🎁 वाउचर केवल Brand खाते भेज सकते हैं। Free/Premium उपयोगकर्ता नक्शे पर उठाते हैं।',
    'th': '🎟 คูปองและ 🎁 บัตรกำนัลส่งได้เฉพาะบัญชี Brand. ผู้ใช้ฟรี/Premium เก็บจากแผนที่',
  });

  // Build 182: Brand 전용 게이트 시트 전용 문구 — Premium 과 구분하는 위계.
  String get brandOnlyBadge => _t({
    'ko': 'Brand 전용',
    'en': 'Brand only',
    'ja': 'Brand 限定',
    'zh': 'Brand 专属',
    'fr': 'Brand uniquement',
    'de': 'Nur Brand',
    'es': 'Solo Brand',
    'pt': 'Só Brand',
    'ru': 'Только Brand',
    'tr': 'Sadece Brand',
    'ar': 'Brand فقط',
    'it': 'Solo Brand',
    'hi': 'केवल Brand',
    'th': 'Brand เท่านั้น',
  });

  String get brandOnlyPremiumNote => _t({
    'ko': 'Premium 이 이미 활성화되어 있어요. Brand 는 업그레이드가 아니라 사업자 광고주 계정으로 별도 등록이 필요한 트랙이에요.',
    'en': 'Premium is already active. Brand is a separate advertiser track — not an upgrade, it needs a business registration.',
    'ja': 'Premium は既に有効です。Brand はアップグレードではなく、別途事業者登録が必要な広告主アカウントです。',
    'zh': 'Premium 已激活。Brand 不是升级路径，而是需另行注册的商业广告主账号。',
    'fr': 'Premium est déjà actif. Brand n\'est pas une mise à niveau mais un compte annonceur distinct nécessitant une vérification professionnelle.',
    'de': 'Premium ist bereits aktiv. Brand ist kein Upgrade, sondern ein separates Werbekonto mit Unternehmensprüfung.',
    'es': 'Premium ya está activo. Brand no es una mejora, es una cuenta de anunciante independiente con verificación empresarial.',
    'pt': 'Premium já está ativo. Brand não é um upgrade, é uma conta de anunciante separada com verificação empresarial.',
    'ru': 'Premium уже активен. Brand — это отдельный рекламодательский аккаунт, а не апгрейд.',
    'tr': 'Premium zaten aktif. Brand bir yükseltme değil, ayrı bir reklamveren hesabıdır ve iş doğrulaması gerektirir.',
    'ar': 'Premium مفعّل مسبقًا. Brand ليس ترقية بل حساب معلن منفصل يتطلّب التحقق التجاري.',
    'it': 'Premium è già attivo. Brand non è un upgrade: è un account inserzionista separato con verifica aziendale.',
    'hi': 'Premium पहले से सक्रिय है। Brand अपग्रेड नहीं है, अलग विज्ञापनदाता खाता है जिसे व्यावसायिक सत्यापन चाहिए।',
    'th': 'Premium เปิดใช้งานอยู่แล้ว Brand ไม่ใช่การอัปเกรดแต่เป็นบัญชีผู้ลงโฆษณาแยกที่ต้องยืนยันธุรกิจ',
  });

  String get brandOnlyAcknowledge => _t({
    'ko': '알겠어요',
    'en': 'Got it',
    'ja': 'わかりました',
    'zh': '我知道了',
    'fr': 'Compris',
    'de': 'Verstanden',
    'es': 'Entendido',
    'pt': 'Entendido',
    'ru': 'Понятно',
    'tr': 'Anladım',
    'ar': 'فهمت',
    'it': 'Capito',
    'hi': 'समझ गया',
    'th': 'เข้าใจแล้ว',
  });

  // Build 186: Brand 프로필의 ExactDrop 크레딧 카드.
  String get brandExactDropCreditsTitle => _t({
    'ko': 'ExactDrop 크레딧',
    'en': 'ExactDrop Credits',
    'ja': 'ExactDrop クレジット',
    'zh': 'ExactDrop 额度',
    'fr': 'Crédits ExactDrop',
    'de': 'ExactDrop-Guthaben',
    'es': 'Créditos ExactDrop',
    'pt': 'Créditos ExactDrop',
    'ru': 'Кредиты ExactDrop',
    'tr': 'ExactDrop Kredileri',
    'ar': 'أرصدة ExactDrop',
    'it': 'Crediti ExactDrop',
    'hi': 'ExactDrop क्रेडिट',
    'th': 'เครดิต ExactDrop',
  });

  String brandExactDropCreditsCount(int n) => _t({
    'ko': '$n 통',
    'en': '$n left',
    'ja': '残り$n 通',
    'zh': '剩余 $n',
    'fr': '$n restants',
    'de': '$n übrig',
    'es': '$n restantes',
    'pt': '$n restantes',
    'ru': 'Осталось $n',
    'tr': '$n kaldı',
    'ar': 'متبقي $n',
    'it': '$n rimasti',
    'hi': '$n शेष',
    'th': 'เหลือ $n',
  });

  String get brandExactDropCreditsHint => _t({
    'ko': '정확한 좌표에 혜택을 떨어뜨리려면 크레딧이 필요해요. 100통 단위로 구매.',
    'en': 'Credits are required to drop promos at exact coordinates. Sold in 100-promo packs.',
    'ja': '正確な座標に手紙を配るには ExactDrop クレジットが必要。100通単位で購入。',
    'zh': '向精确坐标投放信件需要 ExactDrop 额度。以 100 封为单位购买。',
    'fr': 'Crédits requis pour lancer des lettres à des coordonnées précises. Packs de 100.',
    'de': 'Guthaben nötig, um Briefe an exakten Koordinaten abzulegen. 100er-Pakete.',
    'es': 'Se necesitan créditos para lanzar cartas en coordenadas exactas. Paquetes de 100.',
    'pt': 'Créditos necessários para lançar cartas em coordenadas exatas. Pacotes de 100.',
    'ru': 'Нужны кредиты для сброса писем по точным координатам. Пакеты по 100.',
    'tr': 'Tam koordinatlara mektup bırakmak için kredi gerekli. 100\'lü paketler.',
    'ar': 'الأرصدة مطلوبة لإسقاط الرسائل في إحداثيات دقيقة. عبوات من 100.',
    'it': 'Servono crediti per lanciare lettere in coordinate esatte. Pacchetti da 100.',
    'hi': 'सटीक निर्देशांक पर पत्र गिराने के लिए क्रेडिट चाहिए। 100 के पैक।',
    'th': 'ต้องใช้เครดิตเพื่อปล่อยจดหมายที่พิกัดแม่นยำ แพ็ก 100 ฉบับ',
  });

  String get brandExactDropCreditsBuyBtn => _t({
    'ko': '💎 100통 구매 (₩10,000)',
    'en': '💎 Buy 100 (\$7.99)',
    'ja': '💎 100通を購入 (¥1,100)',
    'zh': '💎 购买 100 封 (¥50)',
    'fr': '💎 Acheter 100 (€7.99)',
    'de': '💎 100 kaufen (€7.99)',
    'es': '💎 Comprar 100 (€7.99)',
    'pt': '💎 Comprar 100 (€7.99)',
    'ru': '💎 Купить 100 (₽749)',
    'tr': '💎 100 satın al (₺299)',
    'ar': '💎 اشترِ 100 (\$7.99)',
    'it': '💎 Compra 100 (€7.99)',
    'hi': '💎 100 खरीदें (\$7.99)',
    'th': '💎 ซื้อ 100 (฿299)',
  });

  String get brandExactDropCreditsSheetTitle => _t({
    'ko': 'ExactDrop 크레딧 구매 안내',
    'en': 'How to buy ExactDrop credits',
    'ja': 'ExactDrop クレジットの購入案内',
    'zh': '购买 ExactDrop 额度',
    'fr': 'Acheter des crédits ExactDrop',
    'de': 'ExactDrop-Guthaben kaufen',
    'es': 'Comprar créditos ExactDrop',
    'pt': 'Comprar créditos ExactDrop',
    'ru': 'Купить кредиты ExactDrop',
    'tr': 'ExactDrop kredisi satın al',
    'ar': 'شراء أرصدة ExactDrop',
    'it': 'Acquistare crediti ExactDrop',
    'hi': 'ExactDrop क्रेडिट खरीदें',
    'th': 'วิธีซื้อเครดิต ExactDrop',
  });

  String get brandExactDropCreditsSheetBody => _t({
    'ko': '지금은 앱 내 결제가 준비 중이라 관리자 승인으로만 지급돼요.\nsupport@thiscount.io 으로 사업자명과 필요한 통 수를 알려주시면 24시간 안에 충전해 드립니다.',
    'en': 'In-app purchase is coming soon. For now, credits are granted by admin.\nEmail support@thiscount.io with your business name and desired quantity — topped up within 24 hours.',
    'ja': 'アプリ内決済は準備中で、現在は管理者承認で支給されます。\nsupport@thiscount.io へ事業者名と希望通数を送ってください。24時間以内にチャージします。',
    'zh': '应用内购买正在准备中，目前通过管理员审批发放。\n请发送企业名称和所需数量至 support@thiscount.io，24 小时内充值。',
    'fr': 'L\'achat intégré arrive bientôt. En attendant, les crédits sont octroyés par un admin.\nEnvoyez support@thiscount.io votre nom d\'entreprise et quantité — rechargé sous 24h.',
    'de': 'In-App-Kauf kommt bald. Bis dahin werden Guthaben von Admins vergeben.\nMail an support@thiscount.io mit Firmennamen und Menge — innerhalb 24h aufgeladen.',
    'es': 'La compra dentro de la app llegará pronto. Por ahora, los admins asignan créditos.\nEnvíe a support@thiscount.io el nombre de su empresa y la cantidad — recarga en 24h.',
    'pt': 'Compra na app em breve. Por agora, créditos são concedidos por admin.\nEmail support@thiscount.io com o nome da empresa e quantidade — em 24h.',
    'ru': 'Встроенная покупка скоро. Пока кредиты выдаёт администратор.\nПишите на support@thiscount.io с названием бизнеса и количеством — начисление в 24ч.',
    'tr': 'Uygulama içi satın alma yakında. Şimdilik admin kredi veriyor.\nsupport@thiscount.io adresine işletme adı ve miktarı yazın — 24 saat içinde yüklenir.',
    'ar': 'الشراء داخل التطبيق قريبًا. حاليًا يمنح المسؤول الأرصدة.\nراسل support@thiscount.io باسم النشاط والعدد — شحن خلال 24 ساعة.',
    'it': 'Acquisto in-app in arrivo. Per ora i crediti sono concessi dall\'admin.\nScrivi a support@thiscount.io con nome azienda e quantità — caricato entro 24h.',
    'hi': 'इन-ऐप खरीदारी जल्द आ रही है। अभी क्रेडिट एडमिन द्वारा दिए जाते हैं।\nsupport@thiscount.io पर व्यवसाय नाम और मात्रा भेजें — 24 घंटे में लोड।',
    'th': 'ซื้อในแอปกำลังมา ตอนนี้แอดมินเป็นผู้อนุมัติ\nส่งชื่อธุรกิจและจำนวนที่ต้องการไปยัง support@thiscount.io — เติมภายใน 24 ชม.',
  });

  // 카테고리별 redemption 필드 설명 + 힌트 (할인권 코드 vs 교환권 이미지).
  String get composeBrandCouponDesc => _t({
    'ko': '할인 코드를 입력하세요. 수신자가 결제·주문 시 이 코드를 입력하면 혜택 적용.',
    'en': 'Enter the discount code. Receivers type this at checkout/order.',
    'ja': '割引コードを入力。受取人が決済/注文時にこのコードを入力します。',
    'zh': '输入折扣代码。收件人结账/下单时输入该代码。',
    'fr': "Saisis le code. Les destinataires le tapent au paiement.",
    'de': 'Gib den Rabatt-Code ein. Empfänger tippt ihn an der Kasse.',
    'es': 'Introduce el código. El receptor lo escribe al pagar.',
    'pt': 'Introduz o código. O destinatário digita-o no pagamento.',
    'ru': 'Введите код. Получатель вводит его при оплате.',
    'tr': 'İndirim kodunu gir. Alıcı ödemede yazar.',
    'ar': 'أدخل رمز الخصم. يُدخله المستلم عند الدفع.',
    'it': 'Inserisci il codice. Il destinatario lo digita al pagamento.',
    'hi': 'छूट कोड दर्ज करें। पाने वाला चेकआउट पर टाइप करेगा।',
    'th': 'ใส่รหัสส่วนลด ผู้รับพิมพ์ตอนชำระ',
  });

  String get composeBrandCouponHint => _t({
    'ko': '예: THISCOUNT20', 'en': 'e.g. THISCOUNT20', 'ja': '例: THISCOUNT20',
    'zh': '例：THISCOUNT20', 'fr': 'ex : THISCOUNT20', 'de': 'z. B. THISCOUNT20',
    'es': 'ej: THISCOUNT20', 'pt': 'ex: THISCOUNT20',
    'ru': 'напр. THISCOUNT20', 'tr': 'örn: THISCOUNT20',
    'ar': 'مثال: THISCOUNT20', 'it': 'es: THISCOUNT20',
    'hi': 'उदा. THISCOUNT20', 'th': 'เช่น THISCOUNT20',
  });

  String get composeBrandVoucherDesc => _t({
    'ko': '교환권 이미지 URL(바코드·QR·도장). 받은 사람이 매장에서 화면에 띄워 사용. 부가 설명은 본문에.',
    'en': 'Image URL for a physical voucher (barcode/QR/stamp). Receivers show it at the counter. Use the promo body for notes.',
    'ja': '交換券画像の URL(バーコード/QR/スタンプ)。受取人が店舗で画面に表示。補足は本文に。',
    'zh': '兑换券图片 URL（条形码/QR/图章）。收件人到店显示画面。补充说明写在正文中。',
    'fr': "URL d'image pour bon physique (code-barre/QR/tampon). Destinataires la montrent en caisse.",
    'de': 'Bild-URL für Gutschein (Barcode/QR/Stempel). Empfänger zeigt es an der Kasse.',
    'es': 'URL de imagen del vale físico (código/QR/sello). El receptor la muestra en caja.',
    'pt': 'URL da imagem do vale físico (código/QR/carimbo). O destinatário mostra no balcão.',
    'ru': 'URL изображения ваучера (штрих-код/QR/штамп). Получатель покажет на кассе.',
    'tr': 'Fiziksel kupon görseli URL (barkod/QR/damga). Alıcı kasada gösterir.',
    'ar': 'رابط صورة القسيمة المادية (باركود/QR/ختم). يعرضها المستلم في المتجر.',
    'it': "URL dell'immagine del buono (codice/QR/timbro). Il destinatario la mostra alla cassa.",
    'hi': 'भौतिक वाउचर छवि URL (बारकोड/QR/स्टैंप)। पाने वाला काउंटर पर दिखाएगा।',
    'th': 'URL รูปคูปองจริง (บาร์โค้ด/QR/ตรา) ผู้รับแสดงที่เคาน์เตอร์',
  });

  String get composeBrandVoucherHint => _t({
    'ko': '예: https://... .png', 'en': 'e.g. https://... .png',
    'ja': '例: https://... .png', 'zh': '例：https://... .png',
    'fr': 'ex : https://... .png', 'de': 'z. B. https://... .png',
    'es': 'ej: https://... .png', 'pt': 'ex: https://... .png',
    'ru': 'напр. https://... .png', 'tr': 'örn: https://... .png',
    'ar': 'مثال: https://... .png', 'it': 'es: https://... .png',
    'hi': 'उदा. https://... .png', 'th': 'เช่น https://... .png',
  });

  // Build 130: 교환권 이미지 선택 버튼 라벨.
  String get composeBrandVoucherImagePick => _t({
    'ko': '📸 쿠폰 이미지 선택',
    'en': '📸 Pick voucher image',
    'ja': '📸 クーポン画像を選択',
    'zh': '📸 选择优惠券图片',
    'fr': '📸 Choisir l\'image',
    'de': '📸 Bild auswählen',
    'es': '📸 Elegir imagen',
    'pt': '📸 Escolher imagem',
    'ru': '📸 Выбрать изображение',
    'tr': '📸 Görsel seç',
    'ar': '📸 اختر صورة القسيمة',
    'it': '📸 Scegli immagine',
    'hi': '📸 वाउचर छवि चुनें',
    'th': '📸 เลือกรูปคูปอง',
  });

  String get composeBrandVoucherImageChange => _t({
    'ko': '📸 다른 이미지 선택',
    'en': '📸 Change image',
    'ja': '📸 別の画像を選択',
    'zh': '📸 更换图片',
    'fr': '📸 Changer d\'image',
    'de': '📸 Bild ändern',
    'es': '📸 Cambiar imagen',
    'pt': '📸 Trocar imagem',
    'ru': '📸 Заменить',
    'tr': '📸 Görseli değiştir',
    'ar': '📸 تغيير الصورة',
    'it': '📸 Cambia immagine',
    'hi': '📸 छवि बदलें',
    'th': '📸 เปลี่ยนรูป',
  });

  // Build 132: 유효기간 UI.
  String get composeBrandRedemptionValidityLabel => _t({
    'ko': '유효기간',
    'en': 'Validity',
    'ja': '有効期限',
    'zh': '有效期',
    'fr': 'Validité',
    'de': 'Gültigkeit',
    'es': 'Validez',
    'pt': 'Validade',
    'ru': 'Срок действия',
    'tr': 'Geçerlilik',
    'ar': 'الصلاحية',
    'it': 'Validità',
    'hi': 'वैधता',
    'th': 'ระยะเวลา',
  });

  String composeBrandRedemptionExpiresOn(String date) {
    switch (languageCode) {
      case 'ko': return '만료: $date';
      case 'ja': return '期限: $date';
      case 'zh': return '到期: $date';
      case 'fr': return 'Expire le $date';
      case 'de': return 'Läuft ab: $date';
      case 'es': return 'Caduca el $date';
      case 'pt': return 'Expira em $date';
      case 'ru': return 'До $date';
      case 'tr': return 'Son tarih: $date';
      case 'ar': return 'ينتهي: $date';
      case 'it': return 'Scade il $date';
      case 'hi': return 'समाप्ति: $date';
      case 'th': return 'หมดอายุ $date';
      default: return 'Expires $date';
    }
  }

  String get composeBrandRedemptionUnlimited => _t({
    'ko': '만료 없음',
    'en': 'No expiry',
    'ja': '無期限',
    'zh': '无到期日',
    'fr': 'Sans expiration',
    'de': 'Kein Ablauf',
    'es': 'Sin caducidad',
    'pt': 'Sem expiração',
    'ru': 'Бессрочно',
    'tr': 'Süresiz',
    'ar': 'بدون انتهاء',
    'it': 'Senza scadenza',
    'hi': 'समाप्ति नहीं',
    'th': 'ไม่มีวันหมดอายุ',
  });

  String get composeBrandRedemptionUnlimitedChip => _t({
    'ko': '무제한',
    'en': 'Unlimited',
    'ja': '無期限',
    'zh': '无限',
    'fr': 'Illimité',
    'de': 'Unbegrenzt',
    'es': 'Ilimitado',
    'pt': 'Ilimitado',
    'ru': 'Бессрочно',
    'tr': 'Sınırsız',
    'ar': 'غير محدود',
    'it': 'Illimitato',
    'hi': 'असीमित',
    'th': 'ไม่จำกัด',
  });

  String get composeBrandRedemptionOneYear => _t({
    'ko': '1년',
    'en': '1 year',
    'ja': '1年',
    'zh': '1年',
    'fr': '1 an',
    'de': '1 Jahr',
    'es': '1 año',
    'pt': '1 ano',
    'ru': '1 год',
    'tr': '1 yıl',
    'ar': 'سنة',
    'it': '1 anno',
    'hi': '1 वर्ष',
    'th': '1 ปี',
  });

  String composeBrandRedemptionDays(int days) {
    switch (languageCode) {
      case 'ko': return '${days}일';
      case 'ja': return '$days日';
      case 'zh': return '$days天';
      case 'fr': return '$days jours';
      case 'de': return '$days Tage';
      case 'es': return '$days días';
      case 'pt': return '$days dias';
      case 'ru': return '$days дн.';
      case 'tr': return '$days gün';
      case 'ar': return '$days يوم';
      case 'it': return '$days giorni';
      case 'hi': return '$days दिन';
      case 'th': return '$days วัน';
      default: return '$days days';
    }
  }

  // Brand 사업자 인증 UI.
  String get brandVerificationTitle => _t({
    'ko': '사업자 인증', 'en': 'Business verification', 'ja': '事業者認証',
    'zh': '企业认证', 'fr': 'Vérification entreprise',
    'de': 'Geschäftsverifizierung', 'es': 'Verificación empresarial',
    'pt': 'Verificação empresarial', 'ru': 'Подтверждение бизнеса',
    'tr': 'İşletme doğrulama', 'ar': 'التحقق من الأعمال',
    'it': 'Verifica aziendale', 'hi': 'व्यवसाय सत्यापन',
    'th': 'ยืนยันธุรกิจ',
  });

  String get brandVerificationSubtitle => _t({
    'ko': '사업자 번호·등록증·담당자 연락처를 제출하면 인증 완료 후 프로필에 ✅ 마크가 붙어요.',
    'en': 'Submit your business number, registration document, and contact phone to earn a ✅ badge.',
    'ja': '事業者番号・登録証・担当者連絡先を提出すると、認証後プロフィールに ✅ マーク。',
    'zh': '提交企业编号、注册证和联系电话，认证后资料上会显示 ✅。',
    'fr': "Soumets le numéro, le document et le contact pour obtenir le badge ✅.",
    'de': 'Reiche Nummer, Urkunde und Kontakt ein, um das ✅ zu erhalten.',
    'es': 'Envía número, documento y contacto para conseguir la ✅.',
    'pt': 'Envia número, documento e contacto para obter ✅.',
    'ru': 'Отправьте номер, документ и контакт, чтобы получить ✅.',
    'tr': 'Numara, belge ve iletişim gönder — ✅ kazan.',
    'ar': 'أرسل الرقم والمستند والاتصال للحصول على ✅.',
    'it': 'Invia numero, documento e contatto per la ✅.',
    'hi': 'नंबर, दस्तावेज़ और संपर्क भेजें — ✅ बैज पाएँ।',
    'th': 'ส่งเลขทะเบียน เอกสาร และเบอร์ติดต่อ เพื่อรับ ✅',
  });

  String get brandVerificationNumberLabel => _t({
    'ko': '사업자 등록번호', 'en': 'Business registration number',
    'ja': '事業者登録番号', 'zh': '企业注册号',
    'fr': 'N° d\'enregistrement', 'de': 'Handelsregister-Nr.',
    'es': 'Nº de registro', 'pt': 'N.º de registo',
    'ru': 'Регистрационный номер', 'tr': 'Kayıt numarası',
    'ar': 'رقم التسجيل', 'it': 'N° di registrazione',
    'hi': 'पंजीकरण नंबर', 'th': 'หมายเลขทะเบียน',
  });

  String get brandVerificationDocLabel => _t({
    'ko': '등록증 URL', 'en': 'Document URL', 'ja': '登録証 URL',
    'zh': '证件 URL', 'fr': 'URL du document', 'de': 'Dokument-URL',
    'es': 'URL del documento', 'pt': 'URL do documento',
    'ru': 'URL документа', 'tr': 'Belge URL',
    'ar': 'رابط المستند', 'it': 'URL del documento',
    'hi': 'दस्तावेज़ URL', 'th': 'URL เอกสาร',
  });

  String get brandVerificationPhoneLabel => _t({
    'ko': '담당자 전화번호', 'en': 'Contact phone', 'ja': '担当者電話番号',
    'zh': '联系电话', 'fr': 'Téléphone du contact', 'de': 'Kontakttelefon',
    'es': 'Teléfono de contacto', 'pt': 'Telefone de contacto',
    'ru': 'Контактный телефон', 'tr': 'İletişim telefonu',
    'ar': 'هاتف الاتصال', 'it': 'Telefono di contatto',
    'hi': 'संपर्क फ़ोन', 'th': 'เบอร์ติดต่อ',
  });

  String get brandVerificationSubmitCta => _t({
    'ko': '인증 요청 보내기', 'en': 'Submit verification',
    'ja': '認証を申請', 'zh': '提交认证',
    'fr': 'Envoyer la demande', 'de': 'Verifizierung anfordern',
    'es': 'Enviar verificación', 'pt': 'Enviar verificação',
    'ru': 'Отправить запрос', 'tr': 'Doğrulama gönder',
    'ar': 'إرسال طلب التحقق', 'it': 'Invia verifica',
    'hi': 'सत्यापन भेजें', 'th': 'ส่งคำขอยืนยัน',
  });

  String get brandVerificationStatusPending => _t({
    'ko': '검토 대기 중', 'en': 'Under review', 'ja': '審査中',
    'zh': '审核中', 'fr': 'En cours de vérification',
    'de': 'In Prüfung', 'es': 'En revisión', 'pt': 'Em revisão',
    'ru': 'На проверке', 'tr': 'İnceleniyor',
    'ar': 'قيد المراجعة', 'it': 'In revisione',
    'hi': 'समीक्षाधीन', 'th': 'กำลังตรวจสอบ',
  });

  String get brandVerificationStatusApproved => _t({
    'ko': '✅ 인증 완료', 'en': '✅ Verified', 'ja': '✅ 認証済み',
    'zh': '✅ 已认证', 'fr': '✅ Vérifié', 'de': '✅ Verifiziert',
    'es': '✅ Verificado', 'pt': '✅ Verificado', 'ru': '✅ Подтверждено',
    'tr': '✅ Doğrulandı', 'ar': '✅ مُوثَّق', 'it': '✅ Verificato',
    'hi': '✅ सत्यापित', 'th': '✅ ยืนยันแล้ว',
  });

  String get brandVerificationSubmittedToast => _t({
    'ko': '인증 요청이 접수됐어요. 관리자 검토 후 완료됩니다.',
    'en': 'Verification request received. Admin will review soon.',
    'ja': '認証申請を受け付けました。管理者の審査後、完了します。',
    'zh': '已收到认证请求，管理员审核后生效。',
    'fr': 'Demande reçue. L\'admin l\'examinera bientôt.',
    'de': 'Antrag eingegangen. Prüfung folgt.',
    'es': 'Solicitud recibida. El admin la revisará.',
    'pt': 'Pedido recebido. O admin vai rever.',
    'ru': 'Запрос получен. Админ проверит.',
    'tr': 'Başvuru alındı. Yönetici inceleyecek.',
    'ar': 'تم استلام الطلب. سيراجعه المدير.',
    'it': 'Richiesta ricevuta. L\'admin la esaminerà.',
    'hi': 'अनुरोध प्राप्त। व्यवस्थापक समीक्षा करेंगे।',
    'th': 'รับคำขอแล้ว ผู้ดูแลจะตรวจสอบ',
  });

  // Build 125 — 레터 꾸미기 (동행·장식) 슬롯 타이틀.
  String get letterCompanionsTitle => _t({
    'ko': '동행', 'en': 'Companions', 'ja': '仲間',
    'zh': '伙伴', 'fr': 'Compagnons', 'de': 'Gefährten',
    'es': 'Compañeros', 'pt': 'Companheiros', 'ru': 'Спутники',
    'tr': 'Yoldaşlar', 'ar': 'الرفاق', 'it': 'Compagni',
    'hi': 'साथी', 'th': 'เพื่อนร่วมทาง',
  });

  String get letterAccessoriesTitle => _t({
    'ko': '장식', 'en': 'Accessories', 'ja': 'アクセサリー',
    'zh': '装饰', 'fr': 'Accessoires', 'de': 'Accessoires',
    'es': 'Accesorios', 'pt': 'Acessórios', 'ru': 'Аксессуары',
    'tr': 'Aksesuarlar', 'ar': 'الإكسسوارات', 'it': 'Accessori',
    'hi': 'सहायक वस्तुएँ', 'th': 'เครื่องประดับ',
  });

  String hunterItemLockedHint(int level) => _t({
    'ko': 'Lv $level 에 해금',
    'en': 'Unlocks at Lv $level',
    'ja': 'Lv $level で解放',
    'zh': 'Lv $level 解锁',
    'fr': 'Débloque au Lv $level',
    'de': 'Freigeschaltet ab Lv $level',
    'es': 'Se desbloquea en Lv $level',
    'pt': 'Desbloqueia no Lv $level',
    'ru': 'Откроется на Lv $level',
    'tr': 'Lv $level ile açılır',
    'ar': 'يُفتح في Lv $level',
    'it': 'Sbloccato al Lv $level',
    'hi': 'Lv $level पर खुलता है',
    'th': 'ปลดล็อคที่ Lv $level',
  });

  // Build 116 — 헌트 지갑 확장: 팔로우 카운트 + 주간 퀘스트.
  String huntWalletFollowing(int n) => _t({
    'ko': '❤️ $n개 브랜드 팔로우 중',
    'en': '❤️ Following $n brand${n == 1 ? '' : 's'}',
    'ja': '❤️ $nブランドをフォロー中',
    'zh': '❤️ 关注中 $n 个品牌',
    'fr': '❤️ $n marque${n == 1 ? '' : 's'} suivie${n == 1 ? '' : 's'}',
    'de': '❤️ $n Marke${n == 1 ? '' : 'n'} gefolgt',
    'es': '❤️ Siguiendo $n marca${n == 1 ? '' : 's'}',
    'pt': '❤️ A seguir $n marca${n == 1 ? '' : 's'}',
    'ru': '❤️ Подписок: $n',
    'tr': '❤️ $n marka takip',
    'ar': '❤️ متابعة $n علامة',
    'it': '❤️ $n brand seguiti',
    'hi': '❤️ $n ब्रांड फ़ॉलो',
    'th': '❤️ ติดตาม $n แบรนด์',
  });

  String huntWalletWeeklyGoal(int current, int goal) => _t({
    'ko': '이번 주 목표 · $current / $goal통',
    'en': 'Weekly goal · $current / $goal',
    'ja': '今週の目標 · $current / $goal通',
    'zh': '本周目标 · $current / $goal 封',
    'fr': 'Objectif · $current / $goal',
    'de': 'Wochenziel · $current / $goal',
    'es': 'Meta semanal · $current / $goal',
    'pt': 'Meta semanal · $current / $goal',
    'ru': 'Цель недели · $current / $goal',
    'tr': 'Haftalık · $current / $goal',
    'ar': 'هدف الأسبوع · $current / $goal',
    'it': 'Settimana · $current / $goal',
    'hi': 'साप्ताहिक · $current / $goal',
    'th': 'เป้ารายสัปดาห์ · $current / $goal',
  });

  String get huntWalletWeeklyGoalDone => _t({
    'ko': '🎉 이번 주 목표 달성!',
    'en': '🎉 Weekly goal complete!',
    'ja': '🎉 今週の目標達成！',
    'zh': '🎉 本周目标达成！',
    'fr': '🎉 Objectif hebdomadaire atteint !',
    'de': '🎉 Wochenziel erreicht!',
    'es': '🎉 ¡Meta semanal cumplida!',
    'pt': '🎉 Meta semanal cumprida!',
    'ru': '🎉 Цель недели выполнена!',
    'tr': '🎉 Haftalık hedef tamam!',
    'ar': '🎉 هدف الأسبوع مكتمل!',
    'it': '🎉 Obiettivo settimanale!',
    'hi': '🎉 साप्ताहिक लक्ष्य पूरा!',
    'th': '🎉 ครบเป้าสัปดาห์!',
  });

  String get huntWalletEmpty => _t({
    'ko': '아직 주운 혜택이 없어요. 지도에서 찾아보세요!',
    'en': 'No rewards picked up yet. Open the map and hunt!',
    'ja': 'まだ拾った手紙はありません。地図で探しましょう！',
    'zh': '还没有拾起信件。打开地图找找看！',
    'fr': "Aucune lettre ramassée. Ouvre la carte et chasse !",
    'de': 'Noch keine Briefe. Öffne die Karte und jag!',
    'es': '¡Aún no has recogido cartas. Abre el mapa y caza!',
    'pt': 'Ainda sem cartas. Abre o mapa e caça!',
    'ru': 'Ещё ничего не собрано. Откройте карту и начните охоту!',
    'tr': 'Henüz mektup yok. Haritayı aç ve avlan!',
    'ar': 'لم تلتقط أي رسالة بعد. افتح الخريطة وابدأ الصيد!',
    'it': 'Nessuna lettera ancora. Apri la mappa e caccia!',
    'hi': 'अभी कुछ नहीं. नक्शा खोलो और शिकार करो!',
    'th': 'ยังไม่มีจดหมาย เปิดแผนที่แล้วไปล่าเลย!',
  });

  // 2) 인박스 "만료 사이렌" 스트립
  String expirySirenTitle(int n) => _t({
    'ko': '⏰ $n장의 혜택이 24시간 안에 만료돼요',
    'en': '⏰ $n benefit${n == 1 ? '' : 's'} expire in 24h',
    'ja': '⏰ $n枚の特典が24時間以内に期限切れ',
    'zh': '⏰ $n 张优惠将在 24 小时内过期',
    'fr': "⏰ $n avantage${n == 1 ? '' : 's'} expire${n == 1 ? '' : 'nt'} dans 24h",
    'de': '⏰ $n Vorteil${n == 1 ? '' : 'e'} läuft in 24h ab',
    'es': '⏰ $n beneficio${n == 1 ? '' : 's'} expira${n == 1 ? '' : 'n'} en 24h',
    'pt': '⏰ $n benefício${n == 1 ? '' : 's'} expira${n == 1 ? '' : 'm'} em 24h',
    'ru': '⏰ $n выгод${n == 1 ? 'а' : ''} истекает за 24 ч',
    'tr': '⏰ $n fayda 24 saat içinde sona eriyor',
    'ar': '⏰ $n مزايا تنتهي خلال 24 ساعة',
    'it': '⏰ $n vantagg${n == 1 ? 'io' : 'i'} scade${n == 1 ? '' : 'no'} in 24h',
    'hi': '⏰ $n लाभ 24 घंटे में समाप्त',
    'th': '⏰ สิทธิประโยชน์ $n รายการจะหมดใน 24 ชม.',
  });
  String get expirySirenCta => _t({
    'ko': '지금 사용 →', 'en': 'Use now →', 'ja': '今すぐ使う →',
    'zh': '立即使用 →', 'fr': 'Utiliser maintenant →', 'de': 'Jetzt nutzen →',
    'es': 'Usar ahora →', 'pt': 'Usar já →', 'ru': 'Использовать →',
    'tr': 'Şimdi kullan →', 'ar': 'استخدم الآن →', 'it': 'Usa ora →',
    'hi': 'अभी उपयोग करें →', 'th': 'ใช้เลย →',
  });

  // 3) 인박스 빈 상태 근처 혜택 카운터 (부제)
  String inboxEmptyNearbyCount(int n) => _t({
    'ko': '지금 근처에 $n통의 혜택이 있어요',
    'en': '$n reward${n == 1 ? '' : 's'} nearby right now',
    'ja': '今、近くに$n通の手紙があります',
    'zh': '附近有 $n 封信件',
    'fr': '$n lettre${n == 1 ? '' : 's'} à proximité',
    'de': '$n Brief${n == 1 ? '' : 'e'} in der Nähe',
    'es': '$n carta${n == 1 ? '' : 's'} cerca',
    'pt': '$n carta${n == 1 ? '' : 's'} por perto',
    'ru': 'Рядом $n письм${n == 1 ? 'о' : 'а'}',
    'tr': 'Yakınlarda $n mektup',
    'ar': 'يوجد $n رسائل قربك الآن',
    'it': '$n lettera${n == 1 ? '' : 'e'} vicino',
    'hi': 'पास में $n पत्र हैं',
    'th': 'ใกล้คุณมีจดหมาย $n ฉบับ',
  });

  // 4) 혜택 읽기 화면 브랜드 팔로우 토글
  String get letterReadFollowBrand => _t({
    'ko': '브랜드 팔로우', 'en': 'Follow brand', 'ja': 'ブランドをフォロー',
    'zh': '关注品牌', 'fr': 'Suivre la marque', 'de': 'Marke folgen',
    'es': 'Seguir marca', 'pt': 'Seguir marca', 'ru': 'Подписаться',
    'tr': 'Markayı takip et', 'ar': 'متابعة العلامة', 'it': 'Segui brand',
    'hi': 'ब्रांड फ़ॉलो करें', 'th': 'ติดตามแบรนด์',
  });
  String get letterReadUnfollowBrand => _t({
    'ko': '팔로우 해제', 'en': 'Unfollow', 'ja': 'フォロー解除',
    'zh': '取消关注', 'fr': 'Ne plus suivre', 'de': 'Nicht mehr folgen',
    'es': 'Dejar de seguir', 'pt': 'Deixar de seguir', 'ru': 'Отписаться',
    'tr': 'Takipten çık', 'ar': 'إلغاء المتابعة', 'it': 'Smetti di seguire',
    'hi': 'अनफ़ॉलो', 'th': 'เลิกติดตาม',
  });
  String get letterReadFollowedToast => _t({
    'ko': '이 브랜드를 팔로우했어요',
    'en': 'Following this brand',
    'ja': 'このブランドをフォローしました',
    'zh': '已关注此品牌',
    'fr': 'Marque suivie',
    'de': 'Marke gefolgt',
    'es': 'Siguiendo esta marca',
    'pt': 'A seguir esta marca',
    'ru': 'Подписка оформлена',
    'tr': 'Bu marka takipte',
    'ar': 'متابعة العلامة',
    'it': 'Stai seguendo questo brand',
    'hi': 'ब्रांड फ़ॉलो किया',
    'th': 'กำลังติดตามแบรนด์นี้',
  });

  // 5) 첫 픽업 축하 모달
  String get firstPickupCelebrationTitle => _t({
    'ko': '🎉 첫 혜택을 주웠어요!',
    'en': '🎉 First reward picked up!',
    'ja': '🎉 最初の手紙を拾いました！',
    'zh': '🎉 拾起你的第一封信！',
    'fr': '🎉 Première lettre ramassée !',
    'de': '🎉 Ersten Brief aufgehoben!',
    'es': '🎉 ¡Primera carta recogida!',
    'pt': '🎉 Primeira carta apanhada!',
    'ru': '🎉 Первое письмо поднято!',
    'tr': '🎉 İlk mektubunu topladın!',
    'ar': '🎉 التقطت أول رسالة!',
    'it': '🎉 Prima lettera raccolta!',
    'hi': '🎉 पहला पत्र उठाया!',
    'th': '🎉 เก็บจดหมายแรกแล้ว!',
  });
  String get firstPickupCelebrationBody => _t({
    'ko': '이 동네에 흘린 혜택 혜택을 계속 찾아보세요. 레벨이 오를수록 줍는 반경이 넓어져요.',
    'en': 'Keep exploring — rewards are dropped all around you. Every level you gain widens your pickup radius.',
    'ja': 'この街に散らばる手紙を探し続けましょう。レベルが上がるほど拾える範囲が広がります。',
    'zh': '继续探索——信件遍布你的周围。等级提升会扩大拾取范围。',
    'fr': "Continue d'explorer — des lettres tombent autour de toi. Chaque niveau élargit ton rayon.",
    'de': 'Erkunde weiter — überall in deiner Nähe fallen Briefe. Jedes Level vergrößert deinen Radius.',
    'es': 'Sigue explorando: hay cartas por todas partes. Cada nivel amplía tu radio.',
    'pt': 'Continua a explorar — caem cartas à tua volta. Cada nível amplia o teu raio.',
    'ru': 'Продолжайте исследовать — письма падают вокруг вас. Каждый уровень расширяет радиус.',
    'tr': 'Keşfetmeye devam et — etrafına mektuplar düşüyor. Her seviyede yarıçap artıyor.',
    'ar': 'واصل الاستكشاف — الرسائل تتساقط حولك. كل مستوى يوسّع نطاقك.',
    'it': 'Continua a esplorare — le lettere cadono ovunque. Ogni livello allarga il tuo raggio.',
    'hi': 'खोजते रहो — तुम्हारे आसपास पत्र गिर रहे हैं। हर स्तर तुम्हारी रेंज बढ़ाता है।',
    'th': 'สำรวจต่อไป — จดหมายตกอยู่รอบตัวคุณ ระดับยิ่งสูง รัศมียิ่งกว้าง',
  });
  String get firstPickupCelebrationCta => _t({
    'ko': '계속 찾아보기',
    'en': 'Keep hunting',
    'ja': '続けて探す',
    'zh': '继续寻找',
    'fr': 'Continuer',
    'de': 'Weiter suchen',
    'es': 'Seguir cazando',
    'pt': 'Continuar à caça',
    'ru': 'Продолжить охоту',
    'tr': 'Aramaya devam',
    'ar': 'واصل الصيد',
    'it': 'Continua',
    'hi': 'शिकार जारी रखें',
    'th': 'ล่าต่อ',
  });

  // Build 113: 쿠폰/교환권 발송 시 본문 최소 20자 규칙 완화 — 브랜드가 짧은
  // 프로모 헤드라인 (예: "20% off this weekend!") 으로도 바로 보낼 수 있게.
  // 카테고리 패널 사용 방법 필드 아래 안내 라인에 표시.
  String get composeBrandPromoBodyHint => _t({
    'ko': '쿠폰·교환권은 본문을 짧게 써도 바로 보낼 수 있어요',
    'en': 'Promo messages can be sent with just a short headline',
    'ja': '割引・プロモは短いタイトルだけでも送れます',
    'zh': '优惠信件只需简短标题即可发送',
    'fr': 'Les lettres promo peuvent partir avec un simple titre court',
    'de': 'Promo-Briefe gehen auch mit einer kurzen Überschrift raus',
    'es': 'Las cartas promo pueden enviarse con solo un título corto',
    'pt': 'Cartas promo podem ser enviadas só com um título curto',
    'ru': 'Промо-письма можно отправить с коротким заголовком',
    'tr': 'Promosyon mektupları kısa bir başlıkla da gönderilebilir',
    'ar': 'يمكن إرسال رسائل العروض بعنوان قصير فقط',
    'it': 'Le lettere promo possono partire con una breve intestazione',
    'hi': 'प्रोमो पत्र केवल एक छोटे शीर्षक से भेजे जा सकते हैं',
    'th': 'จดหมายโปรโมสามารถส่งด้วยหัวข้อสั้น ๆ ก็ได้',
  });

  // 브랜드 뮤트 — 수신자가 "이 브랜드 혜택 받지 않기" 선택 시.
  String get letterReadMuteBrand => _t({
    'ko': '이 브랜드 혜택 받지 않기',
    'en': 'Stop receiving rewards from this brand',
    'ja': 'このブランドの手紙を受信しない',
    'zh': '不再接收此品牌的信件',
    'fr': 'Ne plus recevoir cette marque',
    'de': 'Keine Briefe dieser Marke mehr erhalten',
    'es': 'Dejar de recibir de esta marca',
    'pt': 'Parar de receber desta marca',
    'ru': 'Не получать от этого бренда',
    'tr': 'Bu markadan mektup alma',
    'ar': 'إيقاف استلام رسائل هذه العلامة',
    'it': 'Non ricevere più da questo brand',
    'hi': 'इस ब्रांड से पत्र न लें',
    'th': 'ไม่รับจดหมายจากแบรนด์นี้',
  });

  String get letterReadUnmuteBrand => _t({
    'ko': '이 브랜드 혜택 다시 받기',
    'en': 'Resume receiving from this brand',
    'ja': 'このブランドの手紙を再開',
    'zh': '恢复接收此品牌信件',
    'fr': 'Réactiver les lettres de cette marque',
    'de': 'Briefe dieser Marke wieder empfangen',
    'es': 'Volver a recibir de esta marca',
    'pt': 'Voltar a receber desta marca',
    'ru': 'Снова получать от бренда',
    'tr': 'Bu markadan tekrar al',
    'ar': 'استئناف الاستلام من العلامة',
    'it': 'Riattiva questo brand',
    'hi': 'ब्रांड को पुनः चालू करें',
    'th': 'รับจดหมายจากแบรนด์นี้อีก',
  });

  String get letterReadMutedToast => _t({
    'ko': '이 브랜드의 새 혜택이 수집첩에 더 이상 쌓이지 않아요',
    'en': 'New rewards from this brand won\'t appear in your collection',
    'ja': 'このブランドの新しい手紙は受信されません',
    'zh': '此品牌的新信件将不再进入收件箱',
    'fr': 'Les nouvelles lettres de cette marque n\'apparaîtront plus',
    'de': 'Neue Briefe dieser Marke erscheinen nicht mehr',
    'es': 'No aparecerán nuevas cartas de esta marca',
    'pt': 'Novas cartas desta marca não aparecerão',
    'ru': 'Новые письма этого бренда не будут приходить',
    'tr': 'Bu markanın yeni mektupları gelmeyecek',
    'ar': 'لن تصل رسائل جديدة من هذه العلامة',
    'it': 'Le nuove lettere da questo brand non compariranno',
    'hi': 'इस ब्रांड के नए पत्र अब संग्रह में नहीं दिखेंगे',
    'th': 'จดหมายใหม่จากแบรนด์นี้จะไม่เข้ากล่อง',
  });

  // 🎫 쿠폰 사용 완료 관련 — Build 108 추가
  String get letterReadRedemptionMarkUsed => _t({
    'ko': '🎫 사용 완료 표시',
    'en': '🎫 Mark as used',
    'ja': '🎫 使用済みにする',
    'zh': '🎫 标记为已使用',
    'fr': '🎫 Marquer comme utilisé',
    'de': '🎫 Als verwendet markieren',
    'es': '🎫 Marcar como usado',
    'pt': '🎫 Marcar como usado',
    'ru': '🎫 Отметить использованным',
    'tr': '🎫 Kullanıldı olarak işaretle',
    'ar': '🎫 وضع علامة مستخدم',
    'it': '🎫 Segna come usato',
    'hi': '🎫 उपयोग किया गया चिह्न',
    'th': '🎫 ทำเครื่องหมายว่าใช้แล้ว',
  });

  String get letterReadRedemptionUsedHeader => _t({
    'ko': '사용 완료된 혜택',
    'en': 'Already redeemed',
    'ja': '使用済みの特典',
    'zh': '已使用的优惠',
    'fr': 'Déjà utilisé',
    'de': 'Bereits eingelöst',
    'es': 'Ya canjeado',
    'pt': 'Já utilizado',
    'ru': 'Уже использовано',
    'tr': 'Kullanıldı',
    'ar': 'تم استخدامه',
    'it': 'Già usato',
    'hi': 'उपयोग किया गया',
    'th': 'ใช้แล้ว',
  });

  String get letterReadRedemptionUsedBadge => _t({
    'ko': '사용됨',
    'en': 'Used',
    'ja': '使用済み',
    'zh': '已使用',
    'fr': 'Utilisé',
    'de': 'Verwendet',
    'es': 'Usado',
    'pt': 'Usado',
    'ru': 'Использовано',
    'tr': 'Kullanıldı',
    'ar': 'مستخدم',
    'it': 'Usato',
    'hi': 'उपयोग',
    'th': 'ใช้แล้ว',
  });

  String get letterReadRedemptionMarkedToast => _t({
    'ko': '사용 완료로 표시했어요',
    'en': 'Marked as used',
    'ja': '使用済みにしました',
    'zh': '已标记为使用',
    'fr': 'Marqué comme utilisé',
    'de': 'Als verwendet markiert',
    'es': 'Marcado como usado',
    'pt': 'Marcado como utilizado',
    'ru': 'Отмечено как использованное',
    'tr': 'Kullanıldı olarak işaretlendi',
    'ar': 'تم الوضع كمستخدم',
    'it': 'Contrassegnato come usato',
    'hi': 'उपयोग किया गया चिह्नित',
    'th': 'ทำเครื่องหมายแล้ว',
  });

  // 수신자 측 혜택 읽기 화면 쿠폰 박스
  String get letterReadRedemptionHeader => _t({
    'ko': '🎁 사용 방법',
    'en': '🎁 How to redeem',
    'ja': '🎁 使い方',
    'zh': '🎁 使用方法',
    'fr': '🎁 Mode d\'emploi',
    'de': '🎁 Einlösen',
    'es': '🎁 Cómo usar',
    'pt': '🎁 Como resgatar',
    'ru': '🎁 Как использовать',
    'tr': '🎁 Nasıl kullanılır',
    'ar': '🎁 طريقة الاستخدام',
    'it': '🎁 Come usare',
    'hi': '🎁 उपयोग विधि',
    'th': '🎁 วิธีใช้',
  });

  // Build 131: 교환권 이미지 아래 안내.
  String get letterReadVoucherShowAtCounter => _t({
    'ko': '매장 카운터에서 이 이미지를 보여주세요.',
    'en': 'Show this image at the counter.',
    'ja': 'カウンターでこの画像を見せてください。',
    'zh': '在柜台出示此图片。',
    'fr': 'Montrez cette image au comptoir.',
    'de': 'Dieses Bild an der Kasse vorzeigen.',
    'es': 'Muestra esta imagen en el mostrador.',
    'pt': 'Mostre esta imagem no balcão.',
    'ru': 'Покажите изображение на кассе.',
    'tr': 'Görseli tezgâhta gösterin.',
    'ar': 'أظهر هذه الصورة عند الكاونتر.',
    'it': 'Mostra l\'immagine alla cassa.',
    'hi': 'यह छवि काउंटर पर दिखाएँ।',
    'th': 'แสดงรูปนี้ที่เคาน์เตอร์',
  });

  // Build 131: 할인권 복사 버튼 + 복사 완료 토스트.
  String get letterReadCouponCopyBtn => _t({
    'ko': '복사',
    'en': 'Copy',
    'ja': 'コピー',
    'zh': '复制',
    'fr': 'Copier',
    'de': 'Kopieren',
    'es': 'Copiar',
    'pt': 'Copiar',
    'ru': 'Копировать',
    'tr': 'Kopyala',
    'ar': 'نسخ',
    'it': 'Copia',
    'hi': 'कॉपी',
    'th': 'คัดลอก',
  });

  String get letterReadCouponCopied => _t({
    'ko': '📋 할인 코드가 복사됐어요',
    'en': '📋 Coupon code copied',
    'ja': '📋 クーポンコードをコピーしました',
    'zh': '📋 优惠码已复制',
    'fr': '📋 Code copié',
    'de': '📋 Code kopiert',
    'es': '📋 Código copiado',
    'pt': '📋 Código copiado',
    'ru': '📋 Код скопирован',
    'tr': '📋 Kod kopyalandı',
    'ar': '📋 تم نسخ الكود',
    'it': '📋 Codice copiato',
    'hi': '📋 कूपन कोड कॉपी हुआ',
    'th': '📋 คัดลอกรหัสแล้ว',
  });

  // Build 133: 쿠폰/교환권 유효기간 · 만료 상태.
  String get letterReadRedemptionExpiredHeader => _t({
    'ko': '⏰ 유효기간 만료',
    'en': '⏰ Redemption expired',
    'ja': '⏰ 有効期限切れ',
    'zh': '⏰ 已过有效期',
    'fr': '⏰ Utilisation expirée',
    'de': '⏰ Abgelaufen',
    'es': '⏰ Canjeo caducado',
    'pt': '⏰ Resgate expirado',
    'ru': '⏰ Срок истёк',
    'tr': '⏰ Süresi doldu',
    'ar': '⏰ انتهت الصلاحية',
    'it': '⏰ Riscatto scaduto',
    'hi': '⏰ अवधि समाप्त',
    'th': '⏰ หมดอายุแล้ว',
  });

  String get letterReadRedemptionExpiredBadge => _t({
    'ko': '만료됨',
    'en': 'Expired',
    'ja': '期限切れ',
    'zh': '已过期',
    'fr': 'Expiré',
    'de': 'Abgelaufen',
    'es': 'Caducado',
    'pt': 'Expirado',
    'ru': 'Истёк',
    'tr': 'Süresi doldu',
    'ar': 'منتهي',
    'it': 'Scaduto',
    'hi': 'समाप्त',
    'th': 'หมดอายุ',
  });

  String letterReadRedemptionExpiresOn(String date) {
    switch (languageCode) {
      case 'ko': return '$date까지';
      case 'ja': return '$dateまで';
      case 'zh': return '有效期至 $date';
      case 'fr': return "jusqu'au $date";
      case 'de': return 'bis $date';
      case 'es': return 'hasta el $date';
      case 'pt': return 'até $date';
      case 'ru': return 'до $date';
      case 'tr': return '$date tarihine kadar';
      case 'ar': return 'حتى $date';
      case 'it': return 'fino al $date';
      case 'hi': return '$date तक';
      case 'th': return 'ถึง $date';
      default: return 'until $date';
    }
  }

  String letterReadRedemptionDaysLeft(int days) {
    switch (languageCode) {
      case 'ko': return '$days일 남음';
      case 'ja': return '残り$days日';
      case 'zh': return '还剩$days天';
      case 'fr': return '$days j. restants';
      case 'de': return 'noch $days Tage';
      case 'es': return '$days días rest.';
      case 'pt': return '$days dias rest.';
      case 'ru': return 'осталось $days дн.';
      case 'tr': return '$days gün kaldı';
      case 'ar': return 'متبقي $days يوم';
      case 'it': return '$days gg rimasti';
      case 'hi': return '$days दिन बाकी';
      case 'th': return 'เหลือ $days วัน';
      default: return '$days days left';
    }
  }

  // Build 137: 무료 유저가 "보내기" 탭 탭했을 때 뜨는 Premium 안내 시트 문구.
  // Free = 줍기 전용, Premium = 홍보 발송의 가치 제안.
  // Build 142: 지도 상단 브랜드 홍보 배너 광고.
  String get brandPromoBannerAdLabel => _t({
    'ko': '· 홍보',
    'en': '· Ad',
    'ja': '· 広告',
    'zh': '· 广告',
    'fr': '· Pub',
    'de': '· Anzeige',
    'es': '· Ad',
    'pt': '· Anúncio',
    'ru': '· Реклама',
    'tr': '· Reklam',
    'ar': '· إعلان',
    'it': '· Annuncio',
    'hi': '· विज्ञापन',
    'th': '· โฆษณา',
  });

  String get brandPromoBannerCTA => _t({
    'ko': '자세히',
    'en': 'View',
    'ja': '詳細',
    'zh': '查看',
    'fr': 'Voir',
    'de': 'Ansehen',
    'es': 'Ver',
    'pt': 'Ver',
    'ru': 'Подробнее',
    'tr': 'Detay',
    'ar': 'عرض',
    'it': 'Vedi',
    'hi': 'देखें',
    'th': 'ดู',
  });

  // Build 141: 지도 상단 ⓘ 도움말 시트 콘텐츠.
  String get mapHelpTitle => _t({
    'ko': 'Thiscount 사용 안내',
    'en': 'How to use Thiscount',
    'ja': 'Thiscount の使い方',
    'zh': 'Thiscount 使用指南',
    'fr': 'Comment utiliser Thiscount',
    'de': 'Thiscount verwenden',
    'es': 'Cómo usar Thiscount',
    'pt': 'Como usar Thiscount',
    'ru': 'Как пользоваться Thiscount',
    'tr': 'Thiscount nasıl kullanılır',
    'ar': 'كيفية استخدام Thiscount',
    'it': 'Come usare Thiscount',
    'hi': 'Thiscount का उपयोग',
    'th': 'วิธีใช้ Thiscount',
  });

  String get mapHelpTierSection => _t({
    'ko': '회원 등급',
    'en': 'Membership tiers',
    'ja': '会員等級',
    'zh': '会员等级',
    'fr': 'Niveaux d\'adhésion',
    'de': 'Mitgliedsstufen',
    'es': 'Niveles',
    'pt': 'Níveis',
    'ru': 'Уровни членства',
    'tr': 'Üyelik seviyeleri',
    'ar': 'مستويات العضوية',
    'it': 'Livelli',
    'hi': 'सदस्यता स्तर',
    'th': 'ระดับสมาชิก',
  });

  // Build 183: 일반 회원(Free/Premium) 등급 설명을 "레터" 트랙 서사로 통일.
  // 이전엔 "pickup only", "photo/link letters" 같은 기능 나열이었으나 유저는
  // Letter 캐릭터가 성장하는 내러티브를 기대. Brand 만 광고주 기능 구분 유지.
  String get mapHelpTierFreeTitle => _t({
    'ko': 'Free — 🎟 레터 줍기',
    'en': 'Free — 🎟 Pick up Rewards',
    'ja': 'Free — 🎟 Letter を拾う',
    'zh': 'Free — 🎟 拾取 Letter',
    'fr': 'Free — 🎟 Ramasser des Letters',
    'de': 'Free — 🎟 Letters aufsammeln',
    'es': 'Free — 🎟 Recoger Letters',
    'pt': 'Free — 🎟 Apanhar Letters',
    'ru': 'Free — 🎟 Собирать Letters',
    'tr': 'Free — 🎟 Letter topla',
    'ar': 'Free — 🎟 التقاط Letter',
    'it': 'Free — 🎟 Raccogli Letter',
    'hi': 'Free — 🎟 Letter उठाएँ',
    'th': 'Free — 🎟 เก็บ Letter',
  });
  String get mapHelpTierFreeBody => _t({
    'ko': '200m 반경 안의 레터를 주워 내 수집첩에 담고 사용하세요. 레벨이 오를수록 반경이 늘어나고 레터가 함께 성장합니다. 쿨다운 60분.',
    'en': 'Pick up Rewards within 200 m into your collection. Your radius grows with each level as your Counter levels up. 60-min cooldown.',
    'ja': '200m 圏内の Letter を拾って受信箱に集めよう。レベルが上がるほど半径も Letter も成長。クールダウン 60 分。',
    'zh': '拾取 200 米范围内的 Letter 到收件箱。等级越高半径越大，Letter 也一同成长。冷却 60 分钟。',
    'fr': 'Ramasse les Letters dans un rayon de 200 m — ta portée grandit avec ton Letter. Cooldown 60 min.',
    'de': 'Letters im 200-m-Radius aufsammeln. Mit jedem Level wächst Radius und dein Letter. 60 min Abklingzeit.',
    'es': 'Recoge Letters en 200 m — tu radio crece con tu Letter. Cooldown 60 min.',
    'pt': 'Apanha Letters em 200 m — o teu raio cresce com o teu Letter. Cooldown 60 min.',
    'ru': 'Собирайте Letter в радиусе 200 м — радиус растёт вместе с вашим Letter. Перезарядка 60 мин.',
    'tr': '200 m yarıçapta Letter topla. Her seviyede yarıçap ve Letter büyür. 60 dk cooldown.',
    'ar': 'التقاط Letter في نطاق 200 م. يزداد النطاق مع نمو Letter الخاص بك. تبريد 60 دقيقة.',
    'it': 'Raccogli Letter entro 200 m — il tuo raggio cresce col tuo Letter. Cooldown 60 min.',
    'hi': '200 मी में Letter उठाएँ। Letter बढ़ने पर परिधि भी बढ़ती है। कूलडाउन 60 मिनट।',
    'th': 'เก็บ Letter ในรัศมี 200 ม. — รัศมีและ Letter เติบโตไปด้วยกัน คูลดาวน์ 60 นาที',
  });

  String get mapHelpTierPremiumTitle => _t({
    'ko': 'Premium — ✉️ 내 카운터 뿌리기',
    'en': 'Premium — 📣 Drop your Promos',
    'ja': 'Premium — ✉️ 自分の Letter を配る',
    'zh': 'Premium — ✉️ 投放自己的 Letter',
    'fr': 'Premium — ✉️ Déposer tes Letters',
    'de': 'Premium — ✉️ Eigene Letters verteilen',
    'es': 'Premium — ✉️ Lanza tus Letters',
    'pt': 'Premium — ✉️ Lança os teus Letters',
    'ru': 'Premium — ✉️ Раскладывайте свои Letters',
    'tr': 'Premium — ✉️ Kendi Letter\'larını bırak',
    'ar': 'Premium — ✉️ وزّع رسائل Letter',
    'it': 'Premium — ✉️ Rilascia i tuoi Letter',
    'hi': 'Premium — ✉️ अपने Letter बिखेरें',
    'th': 'Premium — ✉️ ปล่อย Letter ของคุณ',
  });
  String get mapHelpTierPremiumBody => _t({
    'ko': '1km 반경으로 주우면서 📸 사진 · 🔗 링크가 달린 내 레터를 세계 지도에 떨어뜨릴 수 있어요. 내 카운터가 빠르게 성장합니다. 쿨다운 10분.',
    'en': '1 km pickup radius + drop your own Promos with 📸 photos and 🔗 links on the map. Your Counter levels up faster. 10-min cooldown.',
    'ja': '1km 圏で拾いつつ、📸 写真・🔗 リンクを添えた自分の Letter を世界に配れます。Letter の成長が早まります。クールダウン 10 分。',
    'zh': '1 公里范围内拾取 + 投放带 📸 照片和 🔗 链接的自己的 Letter。Letter 成长更快。冷却 10 分钟。',
    'fr': 'Rayon 1 km · dépose tes Letters avec photos et liens. Ton Letter grandit plus vite. Cooldown 10 min.',
    'de': '1 km · verteile eigene Letters mit Fotos & Links weltweit. Dein Letter wächst schneller. 10 min Cooldown.',
    'es': '1 km · lanza tus Letters con fotos y enlaces. Tu Letter crece más rápido. Cooldown 10 min.',
    'pt': '1 km · lança os teus Letters com fotos e links. O teu Letter cresce mais rápido. Cooldown 10 min.',
    'ru': 'Радиус 1 км · раскладывайте свои Letters с фото и ссылками. Ваш Letter растёт быстрее. Перезарядка 10 мин.',
    'tr': '1 km · kendi Letter\'larını fotoğraf ve linklerle dağıt. Letter\'ın daha hızlı büyür. 10 dk cooldown.',
    'ar': 'نطاق 1 كم · وزّع رسائلك بصور وروابط. ينمو Letter الخاص بك أسرع. تبريد 10 دقائق.',
    'it': '1 km · rilascia i tuoi Letter con foto e link. Il tuo Letter cresce più velocemente. Cooldown 10 min.',
    'hi': '1 किमी · अपने Letter फ़ोटो और लिंक सहित बिखेरें। आपका Letter तेज़ी से बढ़ता है। कूलडाउन 10 मिनट।',
    'th': 'รัศมี 1 กม. · ปล่อย Letter พร้อมรูปและลิงก์ Letter เติบโตเร็วขึ้น คูลดาวน์ 10 นาที',
  });

  String get mapHelpTierBrandTitle => _t({
    'ko': 'Brand — 📣 캠페인 & ROI 대시보드',
    'en': 'Brand — 📣 campaigns & ROI',
    'ja': 'Brand — 📣 キャンペーン・ROI',
    'zh': 'Brand — 📣 营销活动与 ROI',
    'fr': 'Brand — campagnes 📣 & ROI',
    'de': 'Brand — 📣 Kampagnen & ROI',
    'es': 'Brand — 📣 campañas y ROI',
    'pt': 'Brand — 📣 campanhas & ROI',
    'ru': 'Brand — 📣 кампании и ROI',
    'tr': 'Brand — 📣 kampanyalar & ROI',
    'ar': 'Brand — 📣 الحملات و ROI',
    'it': 'Brand — 📣 campagne & ROI',
    'hi': 'Brand — 📣 अभियान व ROI',
    'th': 'Brand — 📣 แคมเปญและ ROI',
  });
  String get mapHelpTierBrandBody => _t({
    'ko': '🎟 할인권·🎁 교환권 캠페인 · ExactDrop 위치 지정 · 발송/픽업/사용 집계 대시보드로 광고 효과 측정.',
    'en': '🎟 Coupon & 🎁 voucher campaigns · ExactDrop location pinning · impression/pickup/redemption dashboard.',
    'ja': '🎟 割引券・🎁 交換券キャンペーン · ExactDrop 位置指定 · 発送/ピック/使用集計ダッシュボード。',
    'zh': '🎟 优惠券·🎁 代金券活动 · ExactDrop 位置选择 · 发送/拾取/使用数据仪表板。',
    'fr': 'Campagnes 🎟 coupons & 🎁 bons · ExactDrop · tableau de bord.',
    'de': '🎟 Coupon- & 🎁 Gutschein-Kampagnen · ExactDrop · Analytics-Dashboard.',
    'es': 'Campañas 🎟 cupones & 🎁 vales · ExactDrop · panel de analíticas.',
    'pt': 'Campanhas 🎟 cupões & 🎁 vales · ExactDrop · painel de análise.',
    'ru': 'Кампании 🎟 купоны & 🎁 ваучеры · ExactDrop · панель аналитики.',
    'tr': '🎟 Kupon & 🎁 çek kampanyaları · ExactDrop · analiz panosu.',
    'ar': 'حملات 🎟 القسائم و 🎁 الكوبونات · ExactDrop · لوحة تحليلات.',
    'it': 'Campagne 🎟 coupon & 🎁 buoni · ExactDrop · dashboard.',
    'hi': '🎟 कूपन व 🎁 वाउचर अभियान · ExactDrop · विश्लेषण डैशबोर्ड.',
    'th': 'แคมเปญ 🎟 คูปอง·🎁 วาวเชอร์ · ExactDrop · แดชบอร์ด.',
  });

  String get mapHelpMarkerSection => _t({
    'ko': '지도 마커 의미',
    'en': 'Map markers',
    'ja': '地図マーカー',
    'zh': '地图标记含义',
    'fr': 'Marqueurs de la carte',
    'de': 'Kartenmarker',
    'es': 'Marcadores',
    'pt': 'Marcadores',
    'ru': 'Маркеры карты',
    'tr': 'Harita işaretleri',
    'ar': 'علامات الخريطة',
    'it': 'Marcatori',
    'hi': 'मानचित्र मार्कर',
    'th': 'สัญลักษณ์แผนที่',
  });
  String get mapHelpMarkerArrivedTitle => _t({
    'ko': '📮 도착 미열람',
    'en': '📮 Arrived, unread',
    'ja': '📮 到着・未読',
    'zh': '📮 已到未读',
    'fr': '📮 Arrivée, non lue',
    'de': '📮 Angekommen, ungelesen',
    'es': '📮 Llegada sin leer',
    'pt': '📮 Chegada por ler',
    'ru': '📮 Прибыло, не прочитано',
    'tr': '📮 Geldi, okunmadı',
    'ar': '📮 وصلت، غير مقروءة',
    'it': '📮 Arrivata, non letta',
    'hi': '📮 आया, अनपढ़',
    'th': '📮 ถึงแล้ว ยังไม่ได้อ่าน',
  });
  String get mapHelpMarkerArrivedBody => _t({
    'ko': '도착 지점에 표시되며 가까이 다가가서 주울 수 있어요.',
    'en': 'Walk up close to pick this reward up.',
    'ja': '到着地点に表示され、近づいて拾えます。',
    'zh': '显示在到达点，靠近即可拾起。',
    'fr': 'Approche-toi pour le ramasser.',
    'de': 'Nähere dich, um ihn aufzusammeln.',
    'es': 'Acércate para recogerla.',
    'pt': 'Aproxima-te para apanhar.',
    'ru': 'Подойдите, чтобы подобрать.',
    'tr': 'Yaklaşıp topla.',
    'ar': 'اقترب لالتقاطها.',
    'it': 'Avvicinati per raccoglierla.',
    'hi': 'उठाने के लिए पास जाएँ।',
    'th': 'เข้าใกล้เพื่อเก็บ',
  });
  String get mapHelpMarkerCouponTitle => _t({
    'ko': '🎟 할인권',
    'en': '🎟 Discount coupon',
    'ja': '🎟 割引券',
    'zh': '🎟 优惠券',
    'fr': '🎟 Coupon',
    'de': '🎟 Rabatt',
    'es': '🎟 Cupón',
    'pt': '🎟 Cupão',
    'ru': '🎟 Купон',
    'tr': '🎟 Kupon',
    'ar': '🎟 قسيمة',
    'it': '🎟 Coupon',
    'hi': '🎟 कूपन',
    'th': '🎟 คูปอง',
  });
  String get mapHelpMarkerCouponBody => _t({
    'ko': '웹사이트·앱에서 쓸 수 있는 할인 코드. 혜택 열어 📋 복사 버튼으로 사용.',
    'en': 'A code to use on web/app. Tap 📋 copy after opening.',
    'ja': 'ウェブ・アプリで使える割引コード。開封後 📋 コピー。',
    'zh': '可在网页/App 使用的折扣码。打开后 📋 复制。',
    'fr': 'Code à utiliser en ligne. Appuie sur 📋 après ouverture.',
    'de': 'Code für Web/App. Nach Öffnen 📋 kopieren.',
    'es': 'Código para web/app. Toca 📋 copiar.',
    'pt': 'Código para web/app. Toca 📋 copiar.',
    'ru': 'Код для сайта/приложения. Нажмите 📋 после открытия.',
    'tr': 'Web/app kodu. Açtıktan sonra 📋 kopyala.',
    'ar': 'رمز للويب/التطبيق. انقر 📋 بعد الفتح.',
    'it': 'Codice per web/app. Tocca 📋 copia.',
    'hi': 'वेब/ऐप कोड। खोलने के बाद 📋 कॉपी।',
    'th': 'รหัสใช้บนเว็บ/แอป เปิดแล้วแตะ 📋 คัดลอก',
  });
  String get mapHelpMarkerVoucherTitle => _t({
    'ko': '🎁 교환권',
    'en': '🎁 Voucher',
    'ja': '🎁 交換券',
    'zh': '🎁 代金券',
    'fr': '🎁 Bon',
    'de': '🎁 Gutschein',
    'es': '🎁 Vale',
    'pt': '🎁 Vale',
    'ru': '🎁 Ваучер',
    'tr': '🎁 Çek',
    'ar': '🎁 كوبون',
    'it': '🎁 Buono',
    'hi': '🎁 वाउचर',
    'th': '🎁 วาวเชอร์',
  });
  String get mapHelpMarkerVoucherBody => _t({
    'ko': '매장에서 쓰는 쿠폰 이미지. 카운터에서 보여주면 돼요.',
    'en': 'Voucher image to show at the store counter.',
    'ja': '店舗で見せるクーポン画像。',
    'zh': '店内出示的优惠券图片。',
    'fr': 'Image à montrer en boutique.',
    'de': 'Gutschein-Bild am Tresen zeigen.',
    'es': 'Imagen para mostrar en tienda.',
    'pt': 'Imagem para mostrar em loja.',
    'ru': 'Показать изображение на кассе.',
    'tr': 'Tezgâhta gösterilecek görsel.',
    'ar': 'صورة لإظهارها عند الكاونتر.',
    'it': 'Immagine da mostrare in negozio.',
    'hi': 'दुकान पर दिखाने की छवि।',
    'th': 'รูปแสดงที่เคาน์เตอร์',
  });
  String get mapHelpMarkerBrandTitle => _t({
    'ko': '🏢 Brand 계정 타워',
    'en': '🏢 Brand tower',
    'ja': '🏢 Brand タワー',
    'zh': '🏢 Brand 塔楼',
    'fr': '🏢 Tour Brand',
    'de': '🏢 Brand-Turm',
    'es': '🏢 Torre Brand',
    'pt': '🏢 Torre Brand',
    'ru': '🏢 Башня Brand',
    'tr': '🏢 Brand kulesi',
    'ar': '🏢 برج Brand',
    'it': '🏢 Torre Brand',
    'hi': '🏢 Brand टावर',
    'th': '🏢 หอ Brand',
  });
  String get mapHelpMarkerBrandBody => _t({
    'ko': '공식 발송인 표시. ✅ 가 붙으면 사업자 인증 완료.',
    'en': 'Official sender. ✅ means verified business.',
    'ja': '公式送信者。✅ は事業者認証済み。',
    'zh': '官方发送者。✅ 表示已认证商户。',
    'fr': 'Expéditeur officiel. ✅ = entreprise vérifiée.',
    'de': 'Offizieller Absender. ✅ = verifiziert.',
    'es': 'Remitente oficial. ✅ = empresa verificada.',
    'pt': 'Remetente oficial. ✅ = empresa verificada.',
    'ru': 'Официальный отправитель. ✅ — проверенный бизнес.',
    'tr': 'Resmi gönderici. ✅ doğrulanmış işletme.',
    'ar': 'مرسل رسمي. ✅ نشاط موثّق.',
    'it': 'Mittente ufficiale. ✅ azienda verificata.',
    'hi': 'आधिकारिक प्रेषक। ✅ = सत्यापित।',
    'th': 'ผู้ส่งทางการ ✅ = ธุรกิจยืนยัน',
  });

  String get mapHelpHowToSection => _t({
    'ko': '사용 방법',
    'en': 'How to use',
    'ja': '使い方',
    'zh': '使用方法',
    'fr': 'Comment',
    'de': 'Anleitung',
    'es': 'Cómo',
    'pt': 'Como',
    'ru': 'Как',
    'tr': 'Nasıl',
    'ar': 'الطريقة',
    'it': 'Come',
    'hi': 'कैसे',
    'th': 'วิธี',
  });
  String get mapHelpStep1Title => _t({
    'ko': '지도 탐험',
    'en': 'Explore the map',
    'ja': '地図を探索',
    'zh': '浏览地图',
    'fr': 'Explore la carte',
    'de': 'Karte erkunden',
    'es': 'Explora el mapa',
    'pt': 'Explora o mapa',
    'ru': 'Изучите карту',
    'tr': 'Haritayı keşfet',
    'ar': 'استكشف الخريطة',
    'it': 'Esplora la mappa',
    'hi': 'मानचित्र देखें',
    'th': 'สำรวจแผนที่',
  });
  String get mapHelpStep1Body => _t({
    'ko': '내 위치 주변에 떨어진 혜택을 확인. 반경 밖 혜택은 상단 나침반에서 방향을 봐요.',
    'en': 'See rewards near you. Outside the radius, the top compass shows direction.',
    'ja': '近くの手紙を確認。圏外の手紙は上部の方位で方向を確認。',
    'zh': '查看附近的信件。范围外的信件可在顶部方向指示查看。',
    'fr': 'Voir les lettres près de toi. Hors portée, la boussole montre la direction.',
    'de': 'Briefe in der Nähe sehen. Außerhalb — oben am Kompass.',
    'es': 'Cartas cerca de ti. Fuera del radio, brújula superior.',
    'pt': 'Cartas perto. Fora do raio, bússola superior.',
    'ru': 'Смотрите письма рядом. Вне радиуса — компас сверху.',
    'tr': 'Yakındaki mektupları gör. Menzil dışı için üst pusula.',
    'ar': 'الرسائل القريبة. خارج النطاق — بوصلة علوية.',
    'it': 'Lettere vicine. Fuori raggio — bussola.',
    'hi': 'पास के पत्र। दायरे के बाहर — शीर्ष दिशा.',
    'th': 'จดหมายใกล้ ๆ นอกรัศมี — เข็มทิศด้านบน',
  });
  String get mapHelpStep2Title => _t({
    'ko': '다가가서 줍기',
    'en': 'Walk over & pick up',
    'ja': '近づいて拾う',
    'zh': '走近拾起',
    'fr': 'Approche-toi & ramasse',
    'de': 'Hingehen & aufheben',
    'es': 'Camina y recoge',
    'pt': 'Vai até lá e apanha',
    'ru': 'Подойдите и подберите',
    'tr': 'Yaklaş ve topla',
    'ar': 'اقترب والتقط',
    'it': 'Avvicinati e raccogli',
    'hi': 'पास जाकर उठाएँ',
    'th': 'เดินไปเก็บ',
  });
  String get mapHelpStep2Body => _t({
    'ko': '반경 안에 들어오면 혜택이 밝아져요. 탭해서 열고 할인 혜택을 확인하세요.',
    'en': 'Rewards light up when in range. Tap to open and view the offer.',
    'ja': '圏内に入ると手紙が光ります。タップして開いて特典を確認。',
    'zh': '进入范围后信件发光。点击打开并查看优惠。',
    'fr': 'Les lettres s\'illuminent à portée. Appuie pour ouvrir.',
    'de': 'Briefe leuchten in Reichweite. Antippen zum Öffnen.',
    'es': 'Se iluminan al entrar en rango. Toca para abrir.',
    'pt': 'Iluminam-se em alcance. Toca para abrir.',
    'ru': 'Письма подсвечиваются в зоне. Нажмите, чтобы открыть.',
    'tr': 'Menzilde parlıyor. Aç ve gör.',
    'ar': 'تضيء في النطاق. اضغط للفتح.',
    'it': 'Si illuminano a portata. Tocca per aprire.',
    'hi': 'दायरे में चमकते हैं। खोलने को टैप करें।',
    'th': 'สว่างเมื่ออยู่ในรัศมี แตะเพื่อเปิด',
  });
  String get mapHelpStep3Title => _t({
    'ko': '혜택 사용',
    'en': 'Redeem the offer',
    'ja': '特典を使う',
    'zh': '使用优惠',
    'fr': 'Utilise l\'offre',
    'de': 'Angebot einlösen',
    'es': 'Canjea la oferta',
    'pt': 'Resgata a oferta',
    'ru': 'Используйте предложение',
    'tr': 'Teklifi kullan',
    'ar': 'استخدم العرض',
    'it': 'Riscatta',
    'hi': 'ऑफ़र उपयोग',
    'th': 'ใช้ข้อเสนอ',
  });
  String get mapHelpStep3Body => _t({
    'ko': '할인권은 📋 코드 복사, 교환권은 이미지를 매장에서 제시. 유효기간을 놓치지 마세요.',
    'en': 'Coupons: copy 📋 code. Vouchers: show image at store. Mind the expiry.',
    'ja': '割引券は 📋 コピー、交換券は画像を店舗で提示。有効期限に注意。',
    'zh': '优惠券 📋 复制码，代金券在店出示图片。注意有效期。',
    'fr': 'Coupons : 📋 copie. Bons : montre l\'image. Vérifie la date.',
    'de': 'Coupons: 📋 kopieren. Gutscheine: Bild zeigen. Ablauf beachten.',
    'es': 'Cupones: 📋 copia. Vales: imagen en tienda. Caducidad.',
    'pt': 'Cupões: 📋 copia. Vales: imagem na loja. Valide.',
    'ru': 'Купоны: 📋 код. Ваучеры: изображение. Срок.',
    'tr': 'Kuponlar: 📋. Çekler: görsel. Süre.',
    'ar': 'القسائم: 📋. الكوبونات: صورة. الصلاحية.',
    'it': 'Coupon: 📋. Buoni: immagine. Scadenza.',
    'hi': 'कूपन: 📋। वाउचर: छवि। समाप्ति.',
    'th': 'คูปอง: 📋 วาวเชอร์: รูป. ระวังหมดอายุ',
  });

  // Build 138: 브랜드 분석 대시보드 l10n.
  String get brandAnalyticsTitle => _t({
    'ko': '캠페인 분석',
    'en': 'Campaign Analytics',
    'ja': 'キャンペーン分析',
    'zh': '活动分析',
    'fr': 'Analyse de campagne',
    'de': 'Kampagnen-Analyse',
    'es': 'Análisis de campaña',
    'pt': 'Análise de campanha',
    'ru': 'Аналитика кампаний',
    'tr': 'Kampanya Analizi',
    'ar': 'تحليلات الحملة',
    'it': 'Analisi campagna',
    'hi': 'अभियान विश्लेषण',
    'th': 'วิเคราะห์แคมเปญ',
  });

  String get brandAnalyticsOffline => _t({
    'ko': '집계를 불러올 수 없어요. 네트워크 확인 후 다시 시도해주세요.',
    'en': "Couldn't load analytics. Check network and retry.",
    'ja': '集計を読み込めません。ネットワーク確認後に再試行してください。',
    'zh': '无法加载数据。请检查网络后重试。',
    'fr': 'Impossible de charger les analyses. Vérifiez le réseau.',
    'de': 'Analysen nicht ladbar. Netzwerk prüfen.',
    'es': 'No se pudo cargar. Revisa la red.',
    'pt': 'Não foi possível carregar. Verifica a rede.',
    'ru': 'Не удалось загрузить аналитику.',
    'tr': 'Analitik yüklenemedi. Ağı kontrol edin.',
    'ar': 'تعذّر تحميل التحليلات.',
    'it': 'Impossibile caricare. Controlla la rete.',
    'hi': 'डेटा लोड नहीं हुआ। नेटवर्क जांचें।',
    'th': 'โหลดข้อมูลไม่สำเร็จ',
  });

  String get brandAnalyticsSent => _t({
    'ko': '발송',
    'en': 'Sent',
    'ja': '発送',
    'zh': '发送',
    'fr': 'Envoyées',
    'de': 'Versendet',
    'es': 'Enviadas',
    'pt': 'Enviadas',
    'ru': 'Отправлено',
    'tr': 'Gönderilen',
    'ar': 'مرسلة',
    'it': 'Inviate',
    'hi': 'भेजे',
    'th': 'ส่ง',
  });

  String get brandAnalyticsPicked => _t({
    'ko': '픽업',
    'en': 'Picked',
    'ja': 'ピックアップ',
    'zh': '拾取',
    'fr': 'Ramassées',
    'de': 'Aufgesammelt',
    'es': 'Recogidas',
    'pt': 'Apanhadas',
    'ru': 'Собрано',
    'tr': 'Toplanan',
    'ar': 'مُلتَقط',
    'it': 'Raccolte',
    'hi': 'उठाए',
    'th': 'เก็บ',
  });

  String get brandAnalyticsRedeemed => _t({
    'ko': '사용',
    'en': 'Used',
    'ja': '使用',
    'zh': '使用',
    'fr': 'Utilisées',
    'de': 'Genutzt',
    'es': 'Usados',
    'pt': 'Usados',
    'ru': 'Использовано',
    'tr': 'Kullanılan',
    'ar': 'مستخدم',
    'it': 'Usate',
    'hi': 'उपयोग',
    'th': 'ใช้',
  });

  String get brandAnalyticsPickupReach => _t({
    'ko': '픽업률',
    'en': 'Pickup reach',
    'ja': 'ピックアップ率',
    'zh': '拾取率',
    'fr': 'Taux de ramassage',
    'de': 'Aufsammel-Reichweite',
    'es': 'Alcance de recogida',
    'pt': 'Alcance',
    'ru': 'Охват подбора',
    'tr': 'Toplama oranı',
    'ar': 'نسبة الالتقاط',
    'it': 'Tasso di raccolta',
    'hi': 'पिकअप दर',
    'th': 'อัตราการเก็บ',
  });

  String get brandAnalyticsConversion => _t({
    'ko': '전환율',
    'en': 'Conversion',
    'ja': '転換率',
    'zh': '转换率',
    'fr': 'Conversion',
    'de': 'Konversion',
    'es': 'Conversión',
    'pt': 'Conversão',
    'ru': 'Конверсия',
    'tr': 'Dönüşüm',
    'ar': 'التحويل',
    'it': 'Conversione',
    'hi': 'रूपांतरण',
    'th': 'คอนเวอร์ชัน',
  });

  String get brandAnalyticsTopCountries => _t({
    'ko': '국가별 픽업 TOP 5',
    'en': 'Top 5 countries (by picks)',
    'ja': '国別ピックアップ TOP 5',
    'zh': '按国家拾取 TOP 5',
    'fr': 'Top 5 pays (ramassages)',
    'de': 'Top 5 Länder (Picks)',
    'es': 'Top 5 países (recogidas)',
    'pt': 'Top 5 países (apanhadas)',
    'ru': 'ТОП-5 стран (по подборам)',
    'tr': 'En iyi 5 ülke (toplama)',
    'ar': 'أفضل 5 دول (التقاط)',
    'it': 'Top 5 paesi (raccolte)',
    'hi': 'शीर्ष 5 देश (पिकअप)',
    'th': '5 ประเทศยอดนิยม (เก็บ)',
  });

  String get composeGateFeatureName => _t({
    'ko': '홍보 발송',
    'en': 'Promo sending',
    'ja': 'プロモ手紙の送信',
    'zh': '推广信件发送',
    'fr': 'Envoi de lettres promo',
    'de': 'Promo-Brief-Versand',
    'es': 'Envío de cartas promo',
    'pt': 'Envio de cartas promo',
    'ru': 'Отправка промо-писем',
    'tr': 'Promo mektup gönderimi',
    'ar': 'إرسال الرسائل الترويجية',
    'it': 'Invio lettere promo',
    'hi': 'प्रोमो पत्र भेजना',
    'th': 'ส่งจดหมายโปรโมต',
  });

  String get composeGateDesc => _t({
    'ko': '혜택을 세계에 뿌리고 싶다면 Premium 으로 업그레이드하세요.\n📸 사진 첨부 · 🔗 채널/SNS 링크로 나를 홍보할 수 있어요.\n무료 회원은 지도에서 혜택을 주워 혜택을 활용할 수 있어요.',
    'en': 'Upgrade to Premium to drop your own promos worldwide.\n📸 Attach photos · 🔗 Add channel/SNS links to promote yourself.\nFree members keep picking up rewards and claiming benefits.',
    'ja': 'Premium にアップグレードして、自分の手紙を世界に届けましょう。\n📸 写真添付 · 🔗 チャンネル/SNS リンクで自己PR。\n無料会員は地図で手紙を拾って特典を活用できます。',
    'zh': '升级 Premium 将你的信件发送到世界各地。\n📸 附加照片 · 🔗 添加频道/社交链接自我宣传。\n免费会员可以继续在地图上拾取信件。',
    'fr': 'Passe à Premium pour envoyer tes lettres dans le monde entier.\n📸 Joins des photos · 🔗 Ajoute des liens de chaîne / réseaux.\nLes membres gratuits continuent de ramasser des lettres.',
    'de': 'Mit Premium sendest du eigene Briefe weltweit.\n📸 Fotos anhängen · 🔗 Kanal-/Social-Links für Selbstvermarktung.\nFreie Mitglieder sammeln weiterhin Briefe auf der Karte.',
    'es': 'Actualiza a Premium para lanzar tus cartas al mundo.\n📸 Adjunta fotos · 🔗 Añade enlaces de canal/redes.\nLos miembros gratuitos siguen recogiendo cartas.',
    'pt': 'Atualiza para Premium e lança as tuas cartas ao mundo.\n📸 Anexa fotos · 🔗 Adiciona links de canal/redes.\nMembros gratuitos continuam a apanhar cartas.',
    'ru': 'Перейдите на Premium, чтобы отправлять письма по всему миру.\n📸 Прикрепляйте фото · 🔗 Добавляйте ссылки на канал/соцсети.\nБесплатные пользователи продолжают собирать письма.',
    'tr': "Premium'a yükselt ve mektuplarını dünyaya bırak.\n📸 Fotoğraf ekle · 🔗 Kanal/SNS bağlantısıyla kendini tanıt.\nÜcretsiz üyeler haritadan mektup toplamaya devam eder.",
    'ar': 'ارتقِ إلى Premium لإرسال رسائلك للعالم.\n📸 أرفق الصور · 🔗 أضف روابط قناتك/وسائلك.\nالأعضاء المجانيون يواصلون التقاط الرسائل.',
    'it': 'Passa a Premium per lanciare le tue lettere nel mondo.\n📸 Allega foto · 🔗 Aggiungi link canale/social.\nI membri gratuiti continuano a raccogliere lettere.',
    'hi': 'Premium में अपग्रेड करें और अपने पत्र दुनिया में भेजें।\n📸 फ़ोटो संलग्न करें · 🔗 चैनल/SNS लिंक जोड़ें।\nमुफ़्त सदस्य मानचित्र पर पत्र उठाते रहें।',
    'th': 'อัปเกรด Premium เพื่อส่งจดหมายไปทั่วโลก\n📸 แนบรูป · 🔗 ใส่ลิงก์ช่อง/โซเชียล\nสมาชิกฟรียังเก็บจดหมายบนแผนที่ได้',
  });

  String get letterReadRedemptionTodayOnly => _t({
    'ko': '오늘 마지막',
    'en': 'last day',
    'ja': '今日まで',
    'zh': '仅剩今天',
    'fr': 'dernier jour',
    'de': 'letzter Tag',
    'es': 'último día',
    'pt': 'último dia',
    'ru': 'последний день',
    'tr': 'son gün',
    'ar': 'آخر يوم',
    'it': 'ultimo giorno',
    'hi': 'अंतिम दिन',
    'th': 'วันสุดท้าย',
  });

  // 브랜드 컴포즈: 답장 수락 토글
  String get composeBrandAcceptsReplies => _t({
    'ko': '답장 받기',
    'en': 'Accept replies',
    'ja': '返信を受け付ける',
    'zh': '接受回复',
    'fr': 'Accepter les réponses',
    'de': 'Antworten zulassen',
    'es': 'Aceptar respuestas',
    'pt': 'Aceitar respostas',
    'ru': 'Принимать ответы',
    'tr': 'Yanıtları kabul et',
    'ar': 'قبول الردود',
    'it': 'Accetta risposte',
    'hi': 'जवाब स्वीकार करें',
    'th': 'รับคำตอบ',
  });

  String get composeBrandAcceptsRepliesDesc => _t({
    'ko': '끄면 수신자에게 답장 버튼이 보이지 않아요',
    'en': 'If off, recipients won\'t see a reply button',
    'ja': 'オフにすると受信者に返信ボタンが表示されません',
    'zh': '关闭后，收件人将看不到回复按钮',
    'fr': 'Désactivé : pas de bouton de réponse pour le destinataire',
    'de': 'Aus: Empfänger sieht keinen Antworten-Button',
    'es': 'Desactivado: el destinatario no verá botón de respuesta',
    'pt': 'Desativado: o destinatário não vê botão de resposta',
    'ru': 'Выкл: получатель не увидит кнопку ответа',
    'tr': 'Kapalı: alıcı yanıt düğmesi görmeyecek',
    'ar': 'إذا أُوقف لن يظهر زر الرد للمستلم',
    'it': 'Se off, il destinatario non vede il pulsante di risposta',
    'hi': 'बंद होने पर प्राप्तकर्ता को उत्तर बटन नहीं दिखेगा',
    'th': 'ปิดแล้วผู้รับจะไม่เห็นปุ่มตอบกลับ',
  });

  String get letterReadReply => _t({
    'ko': '답장 쓰기',
    'en': 'Write Reply',
    'ja': '返信を書く',
    'zh': '写回信',
    'fr': 'Écrire une réponse',
    'de': 'Antwort schreiben',
    'es': 'Escribir respuesta',
    'pt': 'Escrever resposta',
    'ru': 'Написать ответ',
    'tr': 'Yanıt yaz',
    'ar': 'كتابة رد',
    'it': 'Scrivi risposta',
    'hi': 'जवाब लिखें',
    'th': 'เขียนตอบ',
  });

  // 답장 1회 제한 제거 후 "다시 답장 쓰기" / "이미 답장했어요" 상태 표시용
  String get letterReadReplyAgain => _t({
    'ko': '다시 답장 쓰기',
    'en': 'Reply again',
    'ja': 'もう一度返信する',
    'zh': '再次回复',
    'fr': 'Répondre à nouveau',
    'de': 'Erneut antworten',
    'es': 'Responder de nuevo',
    'pt': 'Responder novamente',
    'ru': 'Ответить ещё раз',
    'tr': 'Tekrar yanıtla',
    'ar': 'رد مرة أخرى',
    'it': 'Rispondi di nuovo',
    'hi': 'फिर से जवाब दें',
    'th': 'ตอบอีกครั้ง',
  });
  String get letterReadRepliedHint => _t({
    'ko': '이미 한 번 답장했어요 · 원하면 더 이어서 보낼 수 있어요',
    'en': 'You already replied once — you can send another if you want',
    'ja': '一度返信済みです — もう一通続けて送れます',
    'zh': '你已经回过一次 · 可以再写一封寄出',
    'fr': 'Déjà répondu une fois — vous pouvez en envoyer une autre',
    'de': 'Schon einmal geantwortet — Sie können noch eine schicken',
    'es': 'Ya respondiste una vez — puedes enviar otra si quieres',
    'pt': 'Você já respondeu uma vez — pode mandar outra',
    'ru': 'Вы уже ответили — можно отправить ещё',
    'tr': 'Zaten bir kez yanıtladınız — istersen bir tane daha gönder',
    'ar': 'لقد رددت مرة بالفعل — يمكنك إرسال أخرى',
    'it': 'Hai già risposto una volta — puoi inviarne un\'altra',
    'hi': 'आप एक बार जवाब दे चुके हैं — चाहें तो और भेज सकते हैं',
    'th': 'คุณตอบไปแล้วหนึ่งครั้ง · ถ้าต้องการก็ส่งเพิ่มได้',
  });

  String get letterReadImageLoadFailed => _t({
    'ko': '이미지를 불러올 수 없어요',
    'en': 'Could not load image',
    'ja': '画像を読み込めませんでした',
    'zh': '无法加载图片',
    'fr': 'Impossible de charger l\'image',
    'de': 'Bild konnte nicht geladen werden',
    'es': 'No se pudo cargar la imagen',
    'pt': 'Não foi possível carregar a imagem',
    'ru': 'Не удалось загрузить изображение',
    'tr': 'Görsel yüklenemedi',
    'ar': 'تعذر تحميل الصورة',
    'it': 'Impossibile caricare l\'immagine',
    'hi': 'छवि लोड नहीं हो सकी',
    'th': 'ไม่สามารถโหลดรูปภาพได้',
  });

  String letterReadMinutesAgo(int n) => _t({
    'ko': '$n분 전',
    'en': '$n min ago',
    'ja': '$n分前',
    'zh': '$n分钟前',
    'fr': 'il y a $n min',
    'de': 'vor $n Min.',
    'es': 'hace $n min',
    'pt': 'há $n min',
    'ru': '$n мин. назад',
    'tr': '$n dk önce',
    'ar': 'منذ $n د',
    'it': '$n min fa',
    'hi': '$n मिनट पहले',
    'th': '$n นาทีที่แล้ว',
  });

  String letterReadHoursAgo(int n) => _t({
    'ko': '$n시간 전',
    'en': '$n hr ago',
    'ja': '$n時間前',
    'zh': '$n小时前',
    'fr': 'il y a $n h',
    'de': 'vor $n Std.',
    'es': 'hace $n h',
    'pt': 'há $n h',
    'ru': '$n ч. назад',
    'tr': '$n sa önce',
    'ar': 'منذ $n س',
    'it': '$n ore fa',
    'hi': '$n घंटे पहले',
    'th': '$n ชั่วโมงที่แล้ว',
  });

  String letterReadDaysAgo(int n) => _t({
    'ko': '$n일 전',
    'en': '$n days ago',
    'ja': '$n日前',
    'zh': '$n天前',
    'fr': 'il y a $n j',
    'de': 'vor $n Tagen',
    'es': 'hace $n días',
    'pt': 'há $n dias',
    'ru': '$n дн. назад',
    'tr': '$n gün önce',
    'ar': 'منذ $n يوم',
    'it': '$n giorni fa',
    'hi': '$n दिन पहले',
    'th': '$n วันที่แล้ว',
  });

  String get letterReadSaveFailed => _t({
    'ko': '저장 실패: 사진 접근 권한을 확인해주세요',
    'en': 'Save failed: Please check photo access permissions',
    'ja': '保存失敗: 写真のアクセス権限を確認してください',
    'zh': '保存失败：请检查照片访问权限',
    'fr': 'Échec de l\'enregistrement : vérifiez les autorisations d\'accès aux photos',
    'de': 'Speichern fehlgeschlagen: Bitte Fotozugriffsrechte prüfen',
    'es': 'Error al guardar: comprueba los permisos de acceso a fotos',
    'pt': 'Falha ao salvar: verifique as permissões de acesso a fotos',
    'ru': 'Ошибка сохранения: проверьте права доступа к фото',
    'tr': 'Kaydetme başarısız: Fotoğraf erişim izinlerini kontrol edin',
    'ar': 'فشل الحفظ: يرجى التحقق من أذونات الوصول إلى الصور',
    'it': 'Salvataggio fallito: controlla i permessi di accesso alle foto',
    'hi': 'सेव विफल: कृपया फोटो एक्सेस अनुमतियां जांचें',
    'th': 'บันทึกล้มเหลว: กรุณาตรวจสอบสิทธิ์การเข้าถึงรูปภาพ',
  });

  String get letterReadSaving => _t({
    'ko': '저장 중...',
    'en': 'Saving...',
    'ja': '保存中...',
    'zh': '保存中...',
    'fr': 'Enregistrement...',
    'de': 'Speichern...',
    'es': 'Guardando...',
    'pt': 'Salvando...',
    'ru': 'Сохранение...',
    'tr': 'Kaydediliyor...',
    'ar': 'جارٍ الحفظ...',
    'it': 'Salvataggio...',
    'hi': 'सेव हो रहा है...',
    'th': 'กำลังบันทึก...',
  });

  String get letterReadSaved => _t({
    'ko': '저장됐어요 ✓',
    'en': 'Saved ✓',
    'ja': '保存しました ✓',
    'zh': '已保存 ✓',
    'fr': 'Enregistré ✓',
    'de': 'Gespeichert ✓',
    'es': 'Guardado ✓',
    'pt': 'Salvo ✓',
    'ru': 'Сохранено ✓',
    'tr': 'Kaydedildi ✓',
    'ar': 'تم الحفظ ✓',
    'it': 'Salvato ✓',
    'hi': 'सेव हो गया ✓',
    'th': 'บันทึกแล้ว ✓',
  });

  String get letterReadSavePhoto => _t({
    'ko': '사진 저장',
    'en': 'Save Photo',
    'ja': '写真を保存',
    'zh': '保存照片',
    'fr': 'Enregistrer la photo',
    'de': 'Foto speichern',
    'es': 'Guardar foto',
    'pt': 'Salvar foto',
    'ru': 'Сохранить фото',
    'tr': 'Fotoğrafı kaydet',
    'ar': 'حفظ الصورة',
    'it': 'Salva foto',
    'hi': 'फोटो सेव करें',
    'th': 'บันทึกรูปภาพ',
  });


  // ── Profile ─────────────────────────────────────────────────────────
  String get profileTitle => _t({
    'ko': '프로필', 'en': 'Profile', 'ja': 'プロフィール', 'zh': '个人资料',
    'fr': 'Profil', 'de': 'Profil', 'es': 'Perfil',
    'pt': 'Perfil', 'ru': 'Профиль', 'tr': 'Profil',
    'ar': 'الملف الشخصي', 'it': 'Profilo', 'hi': 'प्रोफ़ाइल', 'th': 'โปรไฟล์',
  });

  String get profileAccountSection => _t({
    'ko': '계정', 'en': 'Account', 'ja': 'アカウント', 'zh': '账户',
    'fr': 'Compte', 'de': 'Konto', 'es': 'Cuenta',
    'pt': 'Conta', 'ru': 'Аккаунт', 'tr': 'Hesap',
    'ar': 'الحساب', 'it': 'Account', 'hi': 'खाता', 'th': 'บัญชี',
  });

  String get profilePrivacySection => _t({
    'ko': '공개 설정', 'en': 'Privacy', 'ja': 'プライバシー', 'zh': '隐私设置',
    'fr': 'Confidentialité', 'de': 'Datenschutz', 'es': 'Privacidad',
    'pt': 'Privacidade', 'ru': 'Конфиденциальность', 'tr': 'Gizlilik',
    'ar': 'الخصوصية', 'it': 'Privacy', 'hi': 'गोपनीयता', 'th': 'ความเป็นส่วนตัว',
  });

  String get profileNotificationSection => _t({
    'ko': '알림', 'en': 'Notifications', 'ja': '通知', 'zh': '通知',
    'fr': 'Notifications', 'de': 'Benachrichtigungen', 'es': 'Notificaciones',
    'pt': 'Notificações', 'ru': 'Уведомления', 'tr': 'Bildirimler',
    'ar': 'الإشعارات', 'it': 'Notifiche', 'hi': 'सूचनाएँ', 'th': 'การแจ้งเตือน',
  });

  String get profileDisplaySection => _t({
    'ko': '화면', 'en': 'Display', 'ja': '表示', 'zh': '显示',
    'fr': 'Affichage', 'de': 'Anzeige', 'es': 'Pantalla',
    'pt': 'Exibição', 'ru': 'Экран', 'tr': 'Görünüm',
    'ar': 'العرض', 'it': 'Schermo', 'hi': 'प्रदर्शन', 'th': 'การแสดงผล',
  });

  String get profileAppInfoSection => _t({
    'ko': '앱 정보', 'en': 'App Info', 'ja': 'アプリ情報', 'zh': '应用信息',
    'fr': "Infos de l'app", 'de': 'App-Info', 'es': 'Info de la app',
    'pt': 'Info do app', 'ru': 'О приложении', 'tr': 'Uygulama Bilgisi',
    'ar': 'معلومات التطبيق', 'it': "Info sull'app", 'hi': 'ऐप जानकारी', 'th': 'ข้อมูลแอป',
  });

  String get profileAccountManageSection => _t({
    'ko': '계정 관리', 'en': 'Account Management', 'ja': 'アカウント管理', 'zh': '账户管理',
    'fr': 'Gestion du compte', 'de': 'Kontoverwaltung', 'es': 'Gestión de cuenta',
    'pt': 'Gerenciamento de conta', 'ru': 'Управление аккаунтом', 'tr': 'Hesap Yönetimi',
    'ar': 'إدارة الحساب', 'it': 'Gestione account', 'hi': 'खाता प्रबंधन', 'th': 'จัดการบัญชี',
  });

  // Build 183: 프로필 "설정" 섹션 접기 버튼 라벨.
  String get profileSettingsCollapseLabel => _t({
    'ko': '계정 · 알림 · 앱 설정',
    'en': 'Account · Notifications · App Settings',
    'ja': 'アカウント · 通知 · アプリ設定',
    'zh': '账户 · 通知 · 应用设置',
    'fr': 'Compte · Notifications · Paramètres',
    'de': 'Konto · Mitteilungen · App-Einstellungen',
    'es': 'Cuenta · Notificaciones · Ajustes',
    'pt': 'Conta · Notificações · Configurações',
    'ru': 'Аккаунт · Уведомления · Настройки',
    'tr': 'Hesap · Bildirimler · Uygulama',
    'ar': 'الحساب · الإشعارات · الإعدادات',
    'it': 'Account · Notifiche · Impostazioni',
    'hi': 'खाता · सूचनाएँ · ऐप सेटिंग्स',
    'th': 'บัญชี · การแจ้งเตือน · การตั้งค่า',
  });

  String get profileSettingsCollapseSublabel => _t({
    'ko': '탭해서 펼치기',
    'en': 'Tap to expand',
    'ja': 'タップで展開',
    'zh': '点击展开',
    'fr': 'Toucher pour ouvrir',
    'de': 'Tippen zum Öffnen',
    'es': 'Toca para abrir',
    'pt': 'Toca para abrir',
    'ru': 'Нажмите, чтобы открыть',
    'tr': 'Açmak için dokun',
    'ar': 'اضغط للفتح',
    'it': 'Tocca per aprire',
    'hi': 'खोलने के लिए टैप करें',
    'th': 'แตะเพื่อเปิด',
  });

  String get profileNickname => _t({
    'ko': '닉네임', 'en': 'Nickname', 'ja': 'ニックネーム', 'zh': '昵称',
    'fr': 'Pseudo', 'de': 'Spitzname', 'es': 'Apodo',
    'pt': 'Apelido', 'ru': 'Никнейм', 'tr': 'Takma Ad',
    'ar': 'الاسم المستعار', 'it': 'Soprannome', 'hi': 'उपनाम', 'th': 'ชื่อเล่น',
  });

  String get profileNicknamePublic => _t({
    'ko': '닉네임 공개', 'en': 'Show Nickname', 'ja': 'ニックネームを公開', 'zh': '公开昵称',
    'fr': 'Afficher le pseudo', 'de': 'Spitzname anzeigen', 'es': 'Mostrar apodo',
    'pt': 'Mostrar apelido', 'ru': 'Показать никнейм', 'tr': 'Takma Adı Göster',
    'ar': 'إظهار الاسم المستعار', 'it': 'Mostra soprannome', 'hi': 'उपनाम दिखाएँ', 'th': 'แสดงชื่อเล่น',
  });

  String get profileNicknamePublicDesc => _t({
    'ko': '다른 사용자에게 닉네임 표시', 'en': 'Show your nickname to other users', 'ja': '他のユーザーにニックネームを表示', 'zh': '向其他用户显示昵称',
    'fr': 'Afficher votre pseudo aux autres utilisateurs', 'de': 'Spitzname für andere Nutzer anzeigen', 'es': 'Mostrar tu apodo a otros usuarios',
    'pt': 'Mostrar seu apelido para outros usuários', 'ru': 'Показывать никнейм другим пользователям', 'tr': 'Takma adınızı diğer kullanıcılara göster',
    'ar': 'إظهار اسمك المستعار للمستخدمين الآخرين', 'it': 'Mostra il tuo soprannome agli altri utenti', 'hi': 'अन्य उपयोगकर्ताओं को अपना उपनाम दिखाएँ', 'th': 'แสดงชื่อเล่นของคุณแก่ผู้ใช้อื่น',
  });

  String get profileSnsLink => _t({
    'ko': 'SNS 링크', 'en': 'SNS Link', 'ja': 'SNSリンク', 'zh': 'SNS链接',
    'fr': 'Lien SNS', 'de': 'SNS-Link', 'es': 'Enlace SNS',
    'pt': 'Link SNS', 'ru': 'Ссылка на соцсеть', 'tr': 'SNS Bağlantısı',
    'ar': 'رابط SNS', 'it': 'Link SNS', 'hi': 'SNS लिंक', 'th': 'ลิงก์ SNS',
  });

  String get profileSnsLinkEdit => _t({
    'ko': 'SNS 링크 편집', 'en': 'Edit SNS Link', 'ja': 'SNSリンクを編集', 'zh': '编辑SNS链接',
    'fr': 'Modifier le lien SNS', 'de': 'SNS-Link bearbeiten', 'es': 'Editar enlace SNS',
    'pt': 'Editar link SNS', 'ru': 'Редактировать ссылку на соцсеть', 'tr': 'SNS Bağlantısını Düzenle',
    'ar': 'تعديل رابط SNS', 'it': 'Modifica link SNS', 'hi': 'SNS लिंक संपादित करें', 'th': 'แก้ไขลิงก์ SNS',
  });

  String get profileSnsLinkPublic => _t({
    'ko': 'SNS 공개', 'en': 'Show SNS', 'ja': 'SNSを公開', 'zh': '公开SNS',
    'fr': 'Afficher le SNS', 'de': 'SNS anzeigen', 'es': 'Mostrar SNS',
    'pt': 'Mostrar SNS', 'ru': 'Показать соцсеть', 'tr': "SNS'yi Göster",
    'ar': 'إظهار SNS', 'it': 'Mostra SNS', 'hi': 'SNS दिखाएँ', 'th': 'แสดง SNS',
  });

  String get profileSnsPublicDesc => _t({
    'ko': '프로필에 SNS 링크 표시', 'en': 'Show SNS link on profile', 'ja': 'プロフィールにSNSリンクを表示', 'zh': '在个人资料上显示SNS链接',
    'fr': 'Afficher le lien SNS sur le profil', 'de': 'SNS-Link im Profil anzeigen', 'es': 'Mostrar enlace SNS en el perfil',
    'pt': 'Mostrar link SNS no perfil', 'ru': 'Показывать ссылку на соцсеть в профиле', 'tr': 'Profilde SNS bağlantısını göster',
    'ar': 'إظهار رابط SNS في الملف الشخصي', 'it': 'Mostra il link SNS sul profilo', 'hi': 'प्रोफ़ाइल पर SNS लिंक दिखाएँ', 'th': 'แสดงลิงก์ SNS บนโปรไฟล์',
  });

  String get profilePhoto => _t({
    'ko': '프로필 사진', 'en': 'Profile Photo', 'ja': 'プロフィール写真', 'zh': '头像',
    'fr': 'Photo de profil', 'de': 'Profilbild', 'es': 'Foto de perfil',
    'pt': 'Foto de perfil', 'ru': 'Фото профиля', 'tr': 'Profil Fotoğrafı',
    'ar': 'صورة الملف الشخصي', 'it': 'Foto profilo', 'hi': 'प्रोफ़ाइल फ़ोटो', 'th': 'รูปโปรไฟล์',
  });

  String get profilePhotoSet => _t({
    'ko': '사진 설정됨', 'en': 'Photo Set', 'ja': '写真設定済み', 'zh': '已设置照片',
    'fr': 'Photo définie', 'de': 'Foto festgelegt', 'es': 'Foto establecida',
    'pt': 'Foto definida', 'ru': 'Фото установлено', 'tr': 'Fotoğraf Ayarlandı',
    'ar': 'تم تعيين الصورة', 'it': 'Foto impostata', 'hi': 'फ़ोटो सेट', 'th': 'ตั้งรูปแล้ว',
  });

  String get profilePhotoDefault => _t({
    'ko': '기본', 'en': 'Default', 'ja': 'デフォルト', 'zh': '默认',
    'fr': 'Par défaut', 'de': 'Standard', 'es': 'Predeterminado',
    'pt': 'Padrão', 'ru': 'По умолчанию', 'tr': 'Varsayılan',
    'ar': 'افتراضي', 'it': 'Predefinito', 'hi': 'डिफ़ॉल्ट', 'th': 'ค่าเริ่มต้น',
  });

  String get profilePhotoChanged => _t({
    'ko': '프로필 사진이 변경되었습니다', 'en': 'Profile photo changed', 'ja': 'プロフィール写真が変更されました', 'zh': '头像已更改',
    'fr': 'Photo de profil modifiée', 'de': 'Profilbild geändert', 'es': 'Foto de perfil cambiada',
    'pt': 'Foto de perfil alterada', 'ru': 'Фото профиля изменено', 'tr': 'Profil fotoğrafı değiştirildi',
    'ar': 'تم تغيير صورة الملف الشخصي', 'it': 'Foto profilo modificata', 'hi': 'प्रोफ़ाइल फ़ोटो बदली गई', 'th': 'เปลี่ยนรูปโปรไฟล์แล้ว',
  });

  String get profileSelectFromAlbum => _t({
    'ko': '앨범에서 선택', 'en': 'Select from Album', 'ja': 'アルバムから選択', 'zh': '从相册选择',
    'fr': "Sélectionner dans l'album", 'de': 'Aus Album auswählen', 'es': 'Seleccionar del álbum',
    'pt': 'Selecionar do álbum', 'ru': 'Выбрать из альбома', 'tr': 'Albümden Seç',
    'ar': 'اختيار من الألبوم', 'it': "Seleziona dall'album", 'hi': 'एल्बम से चुनें', 'th': 'เลือกจากอัลบั้ม',
  });

  String get profileChangeToDefaultAvatar => _t({
    'ko': '기본 아바타로 변경', 'en': 'Change to Default Avatar', 'ja': 'デフォルトアバターに変更', 'zh': '更改为默认头像',
    'fr': "Changer pour l'avatar par défaut", 'de': 'Zum Standard-Avatar wechseln', 'es': 'Cambiar al avatar predeterminado',
    'pt': 'Alterar para avatar padrão', 'ru': 'Сменить на аватар по умолчанию', 'tr': 'Varsayılan Avatara Değiştir',
    'ar': 'التغيير إلى الصورة الرمزية الافتراضية', 'it': "Cambia all'avatar predefinito", 'hi': 'डिफ़ॉल्ट अवतार में बदलें', 'th': 'เปลี่ยนเป็นอวาตาร์เริ่มต้น',
  });

  String get profileDefaultAvatarChanged => _t({
    'ko': '기본 아바타로 변경되었습니다', 'en': 'Changed to default avatar', 'ja': 'デフォルトアバターに変更されました', 'zh': '已更改为默认头像',
    'fr': "Changé pour l'avatar par défaut", 'de': 'Zum Standard-Avatar geändert', 'es': 'Cambiado al avatar predeterminado',
    'pt': 'Alterado para avatar padrão', 'ru': 'Изменено на аватар по умолчанию', 'tr': 'Varsayılan avatara değiştirildi',
    'ar': 'تم التغيير إلى الصورة الرمزية الافتراضية', 'it': "Cambiato all'avatar predefinito", 'hi': 'डिफ़ॉल्ट अवतार में बदल दिया गया', 'th': 'เปลี่ยนเป็นอวาตาร์เริ่มต้นแล้ว',
  });

  String get profileCountry => _t({
    'ko': '나라', 'en': 'Country', 'ja': '国', 'zh': '国家',
    'fr': 'Pays', 'de': 'Land', 'es': 'País',
    'pt': 'País', 'ru': 'Страна', 'tr': 'Ülke',
    'ar': 'البلد', 'it': 'Paese', 'hi': 'देश', 'th': 'ประเทศ',
  });

  String get profileTowerName => _t({
    'ko': '타워 이름', 'en': 'Tower Name', 'ja': 'タワー名', 'zh': '塔名',
    'fr': 'Nom de la tour', 'de': 'Turmname', 'es': 'Nombre de la torre',
    'pt': 'Nome da torre', 'ru': 'Название башни', 'tr': 'Kule Adı',
    'ar': 'اسم البرج', 'it': 'Nome della torre', 'hi': 'टावर का नाम', 'th': 'ชื่อหอคอย',
  });

  String get profileSubscriptionPlan => _t({
    'ko': '구독 플랜', 'en': 'Subscription Plan', 'ja': 'サブスクリプションプラン', 'zh': '订阅计划',
    'fr': "Plan d'abonnement", 'de': 'Abonnementplan', 'es': 'Plan de suscripción',
    'pt': 'Plano de assinatura', 'ru': 'План подписки', 'tr': 'Abonelik Planı',
    'ar': 'خطة الاشتراك', 'it': 'Piano di abbonamento', 'hi': 'सदस्यता योजना', 'th': 'แผนการสมัครสมาชิก',
  });

  String get profileFree => _t({
    'ko': '무료', 'en': 'Free', 'ja': '無料', 'zh': '免费',
    'fr': 'Gratuit', 'de': 'Kostenlos', 'es': 'Gratis',
    'pt': 'Grátis', 'ru': 'Бесплатно', 'tr': 'Ücretsiz',
    'ar': 'مجاني', 'it': 'Gratuito', 'hi': 'मुफ़्त', 'th': 'ฟรี',
  });

  String get profileUpgrade => _t({
    'ko': '업그레이드', 'en': 'Upgrade', 'ja': 'アップグレード', 'zh': '升级',
    'fr': 'Mettre à niveau', 'de': 'Upgrade', 'es': 'Mejorar',
    'pt': 'Atualizar', 'ru': 'Обновить', 'tr': 'Yükselt',
    'ar': 'ترقية', 'it': 'Aggiorna', 'hi': 'अपग्रेड', 'th': 'อัปเกรด',
  });

  String get profileChangePassword => _t({
    'ko': '비밀번호 변경', 'en': 'Change Password', 'ja': 'パスワード変更', 'zh': '更改密码',
    'fr': 'Changer le mot de passe', 'de': 'Passwort ändern', 'es': 'Cambiar contraseña',
    'pt': 'Alterar senha', 'ru': 'Изменить пароль', 'tr': 'Şifreyi Değiştir',
    'ar': 'تغيير كلمة المرور', 'it': 'Cambia password', 'hi': 'पासवर्ड बदलें', 'th': 'เปลี่ยนรหัสผ่าน',
  });

  String get profileCurrentPassword => _t({
    'ko': '현재 비밀번호', 'en': 'Current Password', 'ja': '現在のパスワード', 'zh': '当前密码',
    'fr': 'Mot de passe actuel', 'de': 'Aktuelles Passwort', 'es': 'Contraseña actual',
    'pt': 'Senha atual', 'ru': 'Текущий пароль', 'tr': 'Mevcut Şifre',
    'ar': 'كلمة المرور الحالية', 'it': 'Password attuale', 'hi': 'वर्तमान पासवर्ड', 'th': 'รหัสผ่านปัจจุบัน',
  });

  String get profileNewPassword => _t({
    'ko': '새 비밀번호', 'en': 'New Password', 'ja': '新しいパスワード', 'zh': '新密码',
    'fr': 'Nouveau mot de passe', 'de': 'Neues Passwort', 'es': 'Nueva contraseña',
    'pt': 'Nova senha', 'ru': 'Новый пароль', 'tr': 'Yeni Şifre',
    'ar': 'كلمة المرور الجديدة', 'it': 'Nuova password', 'hi': 'नया पासवर्ड', 'th': 'รหัสผ่านใหม่',
  });

  String get profileConfirmPassword => _t({
    'ko': '비밀번호 확인', 'en': 'Confirm Password', 'ja': 'パスワード確認', 'zh': '确认密码',
    'fr': 'Confirmer le mot de passe', 'de': 'Passwort bestätigen', 'es': 'Confirmar contraseña',
    'pt': 'Confirmar senha', 'ru': 'Подтвердите пароль', 'tr': 'Şifreyi Onayla',
    'ar': 'تأكيد كلمة المرور', 'it': 'Conferma password', 'hi': 'पासवर्ड की पुष्टि करें', 'th': 'ยืนยันรหัสผ่าน',
  });

  String get profilePasswordMinLength => _t({
    'ko': '비밀번호는 6자 이상이어야 합니다', 'en': 'Password must be at least 6 characters', 'ja': 'パスワードは6文字以上である必要があります', 'zh': '密码至少需要6个字符',
    'fr': 'Le mot de passe doit contenir au moins 6 caractères', 'de': 'Passwort muss mindestens 6 Zeichen lang sein', 'es': 'La contraseña debe tener al menos 6 caracteres',
    'pt': 'A senha deve ter pelo menos 6 caracteres', 'ru': 'Пароль должен содержать не менее 6 символов', 'tr': 'Şifre en az 6 karakter olmalıdır',
    'ar': 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل', 'it': 'La password deve contenere almeno 6 caratteri', 'hi': 'पासवर्ड कम से कम 6 अक्षर का होना चाहिए', 'th': 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร',
  });

  String get profilePasswordMismatch => _t({
    'ko': '비밀번호가 일치하지 않습니다', 'en': 'Passwords do not match', 'ja': 'パスワードが一致しません', 'zh': '密码不匹配',
    'fr': 'Les mots de passe ne correspondent pas', 'de': 'Passwörter stimmen nicht überein', 'es': 'Las contraseñas no coinciden',
    'pt': 'As senhas não coincidem', 'ru': 'Пароли не совпадают', 'tr': 'Şifreler eşleşmiyor',
    'ar': 'كلمات المرور غير متطابقة', 'it': 'Le password non corrispondono', 'hi': 'पासवर्ड मेल नहीं खाते', 'th': 'รหัสผ่านไม่ตรงกัน',
  });

  String get profileCurrentPasswordWrong => _t({
    'ko': '현재 비밀번호가 올바르지 않습니다', 'en': 'Current password is incorrect', 'ja': '現在のパスワードが正しくありません', 'zh': '当前密码不正确',
    'fr': 'Le mot de passe actuel est incorrect', 'de': 'Aktuelles Passwort ist falsch', 'es': 'La contraseña actual es incorrecta',
    'pt': 'A senha atual está incorreta', 'ru': 'Текущий пароль неверен', 'tr': 'Mevcut şifre yanlış',
    'ar': 'كلمة المرور الحالية غير صحيحة', 'it': 'La password attuale non è corretta', 'hi': 'वर्तमान पासवर्ड गलत है', 'th': 'รหัสผ่านปัจจุบันไม่ถูกต้อง',
  });

  String get profilePasswordChanged => _t({
    'ko': '비밀번호가 변경되었습니다', 'en': 'Password changed', 'ja': 'パスワードが変更されました', 'zh': '密码已更改',
    'fr': 'Mot de passe modifié', 'de': 'Passwort geändert', 'es': 'Contraseña cambiada',
    'pt': 'Senha alterada', 'ru': 'Пароль изменён', 'tr': 'Şifre değiştirildi',
    'ar': 'تم تغيير كلمة المرور', 'it': 'Password modificata', 'hi': 'पासवर्ड बदल दिया गया', 'th': 'เปลี่ยนรหัสผ่านแล้ว',
  });

  String get profileNearbyNotification => _t({
    'ko': '근처 혜택 알림', 'en': 'Nearby Reward Notification', 'ja': '近くの手紙通知', 'zh': '附近信件通知',
    'fr': 'Notification de lettre à proximité', 'de': 'Benachrichtigung über Briefe in der Nähe', 'es': 'Notificación de carta cercana',
    'pt': 'Notificação de carta próxima', 'ru': 'Уведомление о письме поблизости', 'tr': 'Yakındaki Mektup Bildirimi',
    'ar': 'إشعار الرسائل القريبة', 'it': 'Notifica lettera nelle vicinanze', 'hi': 'पास के पत्र की सूचना', 'th': 'แจ้งเตือนจดหมายใกล้เคียง',
  });

  String get profileNearbyNotificationDesc => _t({
    'ko': '2km 이내 도착 혜택 알림', 'en': 'Notify when reward arrives within 2km', 'ja': '2km以内に届いた手紙を通知', 'zh': '信件到达2km以内时通知',
    'fr': 'Notifier quand une lettre arrive à moins de 2 km', 'de': 'Benachrichtigen, wenn ein Brief innerhalb von 2 km ankommt', 'es': 'Notificar cuando una carta llegue a menos de 2 km',
    'pt': 'Notificar quando uma carta chegar a menos de 2 km', 'ru': 'Уведомлять, когда письмо прибудет в радиусе 2 км', 'tr': '2 km içinde mektup geldiğinde bildir',
    'ar': 'إشعار عند وصول رسالة في نطاق 2 كم', 'it': 'Notifica quando una lettera arriva entro 2 km', 'hi': '2 किमी के भीतर पत्र आने पर सूचित करें', 'th': 'แจ้งเตือนเมื่อจดหมายมาถึงภายใน 2 กม.',
  });

  String get profileDisplayMode => _t({
    'ko': '화면 모드', 'en': 'Display Mode', 'ja': '表示モード', 'zh': '显示模式',
    'fr': "Mode d'affichage", 'de': 'Anzeigemodus', 'es': 'Modo de pantalla',
    'pt': 'Modo de exibição', 'ru': 'Режим отображения', 'tr': 'Görünüm Modu',
    'ar': 'وضع العرض', 'it': 'Modalità schermo', 'hi': 'डिस्प्ले मोड', 'th': 'โหมดการแสดงผล',
  });

  String get profileSelectDisplayMode => _t({
    'ko': '화면 모드 선택', 'en': 'Select Display Mode', 'ja': '表示モードを選択', 'zh': '选择显示模式',
    'fr': "Sélectionner le mode d'affichage", 'de': 'Anzeigemodus auswählen', 'es': 'Seleccionar modo de pantalla',
    'pt': 'Selecionar modo de exibição', 'ru': 'Выбрать режим отображения', 'tr': 'Görünüm Modunu Seç',
    'ar': 'اختيار وضع العرض', 'it': 'Seleziona modalità schermo', 'hi': 'डिस्प्ले मोड चुनें', 'th': 'เลือกโหมดการแสดงผล',
  });

  String get profileAutoTimezone => _t({
    'ko': '자동 (시간대)', 'en': 'Auto (Timezone)', 'ja': '自動（タイムゾーン）', 'zh': '自动（时区）',
    'fr': 'Auto (fuseau horaire)', 'de': 'Auto (Zeitzone)', 'es': 'Auto (zona horaria)',
    'pt': 'Auto (fuso horário)', 'ru': 'Авто (часовой пояс)', 'tr': 'Otomatik (Saat Dilimi)',
    'ar': 'تلقائي (المنطقة الزمنية)', 'it': 'Auto (fuso orario)', 'hi': 'स्वचालित (समय क्षेत्र)', 'th': 'อัตโนมัติ (เขตเวลา)',
  });

  String get profileAutoTimezoneDesc => _t({
    'ko': '시간대에 따라 자동 변경', 'en': 'Changes automatically by timezone', 'ja': 'タイムゾーンに応じて自動変更', 'zh': '根据时区自动更改',
    'fr': 'Change automatiquement selon le fuseau horaire', 'de': 'Ändert sich automatisch nach Zeitzone', 'es': 'Cambia automáticamente según la zona horaria',
    'pt': 'Muda automaticamente pelo fuso horário', 'ru': 'Автоматически меняется по часовому поясу', 'tr': 'Saat dilimine göre otomatik değişir',
    'ar': 'يتغير تلقائيًا حسب المنطقة الزمنية', 'it': 'Cambia automaticamente in base al fuso orario', 'hi': 'समय क्षेत्र के अनुसार स्वचालित बदलाव', 'th': 'เปลี่ยนอัตโนมัติตามเขตเวลา',
  });

  String get profileLightMode => _t({
    'ko': '밝은 모드', 'en': 'Light Mode', 'ja': 'ライトモード', 'zh': '浅色模式',
    'fr': 'Mode clair', 'de': 'Heller Modus', 'es': 'Modo claro',
    'pt': 'Modo claro', 'ru': 'Светлый режим', 'tr': 'Açık Mod',
    'ar': 'الوضع الفاتح', 'it': 'Modalità chiara', 'hi': 'लाइट मोड', 'th': 'โหมดสว่าง',
  });

  String get profileLightModeDesc => _t({
    'ko': '항상 밝은 모드', 'en': 'Always light mode', 'ja': '常にライトモード', 'zh': '始终浅色模式',
    'fr': 'Toujours en mode clair', 'de': 'Immer heller Modus', 'es': 'Siempre modo claro',
    'pt': 'Sempre modo claro', 'ru': 'Всегда светлый режим', 'tr': 'Her zaman açık mod',
    'ar': 'الوضع الفاتح دائمًا', 'it': 'Sempre modalità chiara', 'hi': 'हमेशा लाइट मोड', 'th': 'โหมดสว่างเสมอ',
  });

  String get profileDarkMode => _t({
    'ko': '다크 모드', 'en': 'Dark Mode', 'ja': 'ダークモード', 'zh': '深色模式',
    'fr': 'Mode sombre', 'de': 'Dunkler Modus', 'es': 'Modo oscuro',
    'pt': 'Modo escuro', 'ru': 'Тёмный режим', 'tr': 'Karanlık Mod',
    'ar': 'الوضع الداكن', 'it': 'Modalità scura', 'hi': 'डार्क मोड', 'th': 'โหมดมืด',
  });

  String get profileDarkModeDesc => _t({
    'ko': '항상 다크 모드', 'en': 'Always dark mode', 'ja': '常にダークモード', 'zh': '始终深色模式',
    'fr': 'Toujours en mode sombre', 'de': 'Immer dunkler Modus', 'es': 'Siempre modo oscuro',
    'pt': 'Sempre modo escuro', 'ru': 'Всегда тёмный режим', 'tr': 'Her zaman karanlık mod',
    'ar': 'الوضع الداكن دائمًا', 'it': 'Sempre modalità scura', 'hi': 'हमेशा डार्क मोड', 'th': 'โหมดมืดเสมอ',
  });

  String get profileNotSet => _t({
    'ko': '미설정', 'en': 'Not Set', 'ja': '未設定', 'zh': '未设置',
    'fr': 'Non défini', 'de': 'Nicht festgelegt', 'es': 'No configurado',
    'pt': 'Não definido', 'ru': 'Не задано', 'tr': 'Ayarlanmadı',
    'ar': 'غير محدد', 'it': 'Non impostato', 'hi': 'सेट नहीं', 'th': 'ยังไม่ตั้ง',
  });

  String get profileVersion => _t({
    'ko': '버전', 'en': 'Version', 'ja': 'バージョン', 'zh': '版本',
    'fr': 'Version', 'de': 'Version', 'es': 'Versión',
    'pt': 'Versão', 'ru': 'Версия', 'tr': 'Sürüm',
    'ar': 'الإصدار', 'it': 'Versione', 'hi': 'संस्करण', 'th': 'เวอร์ชัน',
  });

  String get profileDeleteAccountMsg => _t({
    'ko': '정말 탈퇴하시겠습니까? 모든 데이터가 삭제됩니다.', 'en': 'Are you sure you want to delete your account? All data will be deleted.', 'ja': '本当に退会しますか？すべてのデータが削除されます。', 'zh': '确定要注销账户吗？所有数据将被删除。',
    'fr': 'Voulez-vous vraiment supprimer votre compte ? Toutes les données seront supprimées.', 'de': 'Möchten Sie Ihr Konto wirklich löschen? Alle Daten werden gelöscht.', 'es': '¿Está seguro de que desea eliminar su cuenta? Todos los datos serán eliminados.',
    'pt': 'Tem certeza de que deseja excluir sua conta? Todos os dados serão excluídos.', 'ru': 'Вы уверены, что хотите удалить аккаунт? Все данные будут удалены.', 'tr': 'Hesabınızı silmek istediğinizden emin misiniz? Tüm veriler silinecektir.',
    'ar': 'هل أنت متأكد من حذف حسابك؟ سيتم حذف جميع البيانات.', 'it': 'Sei sicuro di voler eliminare il tuo account? Tutti i dati verranno eliminati.', 'hi': 'क्या आप वाकई अपना खाता हटाना चाहते हैं? सारा डेटा हटा दिया जाएगा।', 'th': 'คุณแน่ใจหรือไม่ว่าต้องการลบบัญชี? ข้อมูลทั้งหมดจะถูกลบ',
  });

  String get profileLogoutMsg => _t({
    'ko': '로그아웃 하시겠습니까?', 'en': 'Are you sure you want to log out?', 'ja': 'ログアウトしますか？', 'zh': '确定要退出登录吗？',
    'fr': 'Voulez-vous vous déconnecter ?', 'de': 'Möchten Sie sich abmelden?', 'es': '¿Está seguro de que desea cerrar sesión?',
    'pt': 'Tem certeza de que deseja sair?', 'ru': 'Вы уверены, что хотите выйти?', 'tr': 'Çıkış yapmak istediğinizden emin misiniz?',
    'ar': 'هل أنت متأكد من تسجيل الخروج؟', 'it': 'Sei sicuro di voler uscire?', 'hi': 'क्या आप लॉग आउट करना चाहते हैं?', 'th': 'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?',
  });

  String get profileTodaySent => _t({
    'ko': '오늘 발송', 'en': 'Sent Today', 'ja': '今日の送信', 'zh': '今日发送',
    'fr': "Envoyés aujourd'hui", 'de': 'Heute gesendet', 'es': 'Enviados hoy',
    'pt': 'Enviados hoje', 'ru': 'Отправлено сегодня', 'tr': 'Bugün Gönderilen',
    'ar': 'أُرسل اليوم', 'it': 'Inviati oggi', 'hi': 'आज भेजे गए', 'th': 'ส่งวันนี้',
  });

  String get profileResetMidnight => _t({
    'ko': '자정에 초기화', 'en': 'Resets at midnight', 'ja': '午前0時にリセット', 'zh': '午夜重置',
    'fr': 'Réinitialisé à minuit', 'de': 'Wird um Mitternacht zurückgesetzt', 'es': 'Se reinicia a medianoche',
    'pt': 'Reinicia à meia-noite', 'ru': 'Сбрасывается в полночь', 'tr': 'Gece yarısı sıfırlanır',
    'ar': 'يُعاد التعيين عند منتصف الليل', 'it': 'Si azzera a mezzanotte', 'hi': 'आधी रात को रीसेट', 'th': 'รีเซ็ตตอนเที่ยงคืน',
  });

  String get profileReceivedLetters => _t({
    'ko': '받은 혜택', 'en': 'Received', 'ja': '受信', 'zh': '收到',
    'fr': 'Reçues', 'de': 'Empfangen', 'es': 'Recibidas',
    'pt': 'Recebidas', 'ru': 'Получено', 'tr': 'Alınan',
    'ar': 'المستلمة', 'it': 'Ricevute', 'hi': 'प्राप्त', 'th': 'ได้รับ',
  });

  String get profileSentLetters => _t({
    'ko': '보낸 혜택', 'en': 'Sent', 'ja': '送信', 'zh': '已发送',
    'fr': 'Envoyées', 'de': 'Gesendet', 'es': 'Enviadas',
    'pt': 'Enviadas', 'ru': 'Отправлено', 'tr': 'Gönderilen',
    'ar': 'المرسلة', 'it': 'Inviate', 'hi': 'भेजे गए', 'th': 'ส่งแล้ว',
  });

  String get profileVisitedCountries => _t({
    'ko': '방문 국가', 'en': 'Countries', 'ja': '訪問国', 'zh': '访问国家',
    'fr': 'Pays', 'de': 'Länder', 'es': 'Países',
    'pt': 'Países', 'ru': 'Страны', 'tr': 'Ülkeler',
    'ar': 'الدول', 'it': 'Paesi', 'hi': 'देश', 'th': 'ประเทศ',
  });

  String get profileFollowing => _t({
    'ko': '팔로잉', 'en': 'Following', 'ja': 'フォロー中', 'zh': '关注',
    'fr': 'Abonnements', 'de': 'Folge ich', 'es': 'Siguiendo',
    'pt': 'Seguindo', 'ru': 'Подписки', 'tr': 'Takip Edilen',
    'ar': 'المتابَعون', 'it': 'Seguiti', 'hi': 'फ़ॉलो कर रहे हैं', 'th': 'กำลังติดตาม',
  });

  String get profileFollowers => _t({
    'ko': '팔로워', 'en': 'Followers', 'ja': 'フォロワー', 'zh': '粉丝',
    'fr': 'Abonnés', 'de': 'Follower', 'es': 'Seguidores',
    'pt': 'Seguidores', 'ru': 'Подписчики', 'tr': 'Takipçiler',
    'ar': 'المتابِعون', 'it': 'Follower', 'hi': 'फ़ॉलोअर्स', 'th': 'ผู้ติดตาม',
  });

  String get profileNoFollowing => _t({
    'ko': '팔로잉 없음', 'en': 'No following', 'ja': 'フォローなし', 'zh': '没有关注',
    'fr': 'Aucun abonnement', 'de': 'Keine Abonnements', 'es': 'Sin seguidos',
    'pt': 'Nenhum seguido', 'ru': 'Нет подписок', 'tr': 'Takip edilen yok',
    'ar': 'لا يوجد متابَعون', 'it': 'Nessun seguito', 'hi': 'कोई फ़ॉलो नहीं', 'th': 'ไม่มีการติดตาม',
  });

  String get profileNoFollowers => _t({
    'ko': '팔로워 없음', 'en': 'No followers', 'ja': 'フォロワーなし', 'zh': '没有粉丝',
    'fr': 'Aucun abonné', 'de': 'Keine Follower', 'es': 'Sin seguidores',
    'pt': 'Nenhum seguidor', 'ru': 'Нет подписчиков', 'tr': 'Takipçi yok',
    'ar': 'لا يوجد متابِعون', 'it': 'Nessun follower', 'hi': 'कोई फ़ॉलोअर नहीं', 'th': 'ไม่มีผู้ติดตาม',
  });

  String get profileNoStamps => _t({
    'ko': '아직 스탬프가 없어요', 'en': 'No stamps yet', 'ja': 'まだスタンプがありません', 'zh': '还没有邮票',
    'fr': 'Pas encore de timbres', 'de': 'Noch keine Stempel', 'es': 'Aún no hay sellos',
    'pt': 'Nenhum selo ainda', 'ru': 'Пока нет марок', 'tr': 'Henüz pul yok',
    'ar': 'لا توجد طوابع بعد', 'it': 'Nessun timbro ancora', 'hi': 'अभी तक कोई स्टैम्प नहीं', 'th': 'ยังไม่มีแสตมป์',
  });

  String profileStampCollected(int count) => _t({
    'ko': '$count개 수집', 'en': '$count collected', 'ja': '$count個収集', 'zh': '已收集$count个',
    'fr': '$count collectés', 'de': '$count gesammelt', 'es': '$count recopilados',
    'pt': '$count coletados', 'ru': '$count собрано', 'tr': '$count toplandı',
    'ar': 'تم جمع $count', 'it': '$count raccolti', 'hi': '$count एकत्रित', 'th': 'สะสมแล้ว $count',
  });

  String get save => _t({
    'ko': '저장', 'en': 'Save', 'ja': '保存', 'zh': '保存',
    'fr': 'Enregistrer', 'de': 'Speichern', 'es': 'Guardar',
    'pt': 'Salvar', 'ru': 'Сохранить', 'tr': 'Kaydet',
    'ar': 'حفظ', 'it': 'Salva', 'hi': 'सहेजें', 'th': 'บันทึก',
  });

  String get cancel => _t({
    'ko': '취소', 'en': 'Cancel', 'ja': 'キャンセル', 'zh': '取消',
    'fr': 'Annuler', 'de': 'Abbrechen', 'es': 'Cancelar',
    'pt': 'Cancelar', 'ru': 'Отмена', 'tr': 'İptal',
    'ar': 'إلغاء', 'it': 'Annulla', 'hi': 'रद्द करें', 'th': 'ยกเลิก',
  });

  String get change => _t({
    'ko': '변경', 'en': 'Change', 'ja': '変更', 'zh': '更改',
    'fr': 'Modifier', 'de': 'Ändern', 'es': 'Cambiar',
    'pt': 'Alterar', 'ru': 'Изменить', 'tr': 'Değiştir',
    'ar': 'تغيير', 'it': 'Modifica', 'hi': 'बदलें', 'th': 'เปลี่ยน',
  });

  String get withdraw => _t({
    'ko': '탈퇴', 'en': 'Withdraw', 'ja': '退会', 'zh': '注销',
    'fr': 'Se désinscrire', 'de': 'Konto löschen', 'es': 'Darse de baja',
    'pt': 'Cancelar conta', 'ru': 'Удалить аккаунт', 'tr': 'Hesabı Sil',
    'ar': 'حذف الحساب', 'it': 'Cancella account', 'hi': 'खाता हटाएँ', 'th': 'ลบบัญชี',
  });

  // ── Tower / Badges ──────────────────────────────────────────────────
  // ── Tower / Ranking Display ────────────────────────────────────────────────

  String get towerMyTower => _t({
    'ko': '내 타워', 'en': 'My Tower', 'ja': 'マイタワー', 'zh': '我的塔',
    'fr': 'Ma tour', 'de': 'Mein Turm', 'es': 'Mi torre',
    'pt': 'Minha torre', 'ru': 'Моя башня', 'tr': 'Kulem',
    'ar': 'برجي', 'it': 'La mia torre', 'hi': 'मेरा टावर', 'th': 'หอคอยของฉัน',
  });

  // Build 183: Free/Premium 용 "내 레터" 타이틀 — 타워 대신.
  String get letterMyCharacter => _t({
    'ko': '내 카운터', 'en': 'My Counter', 'ja': 'マイカウンター', 'zh': '我的信使',
    'fr': 'Ma lettre', 'de': 'Mein Letter', 'es': 'Mi carta',
    'pt': 'Meu Letter', 'ru': 'Мой Letter', 'tr': 'Letter\'ım',
    'ar': 'Letter الخاص بي', 'it': 'Il mio Letter', 'hi': 'मेरा Letter', 'th': 'Letter ของฉัน',
  });

  String get towerEditProfile => _t({
    'ko': '프로필 편집', 'en': 'Edit Profile', 'ja': 'プロフィール編集', 'zh': '编辑资料',
    'fr': 'Modifier le profil', 'de': 'Profil bearbeiten', 'es': 'Editar perfil',
    'pt': 'Editar perfil', 'ru': 'Редактировать профиль', 'tr': 'Profili düzenle',
    'ar': 'تعديل الملف الشخصي', 'it': 'Modifica profilo', 'hi': 'प्रोफ़ाइल संपादित करें', 'th': 'แก้ไขโปรไฟล์',
  });

  String get towerSettings => _t({
    'ko': '설정', 'en': 'Settings', 'ja': '設定', 'zh': '设置',
    'fr': 'Paramètres', 'de': 'Einstellungen', 'es': 'Ajustes',
    'pt': 'Configurações', 'ru': 'Настройки', 'tr': 'Ayarlar',
    'ar': 'الإعدادات', 'it': 'Impostazioni', 'hi': 'सेटिंग्स', 'th': 'การตั้งค่า',
  });

  String get towerCustomize => _t({
    'ko': '꾸미기', 'en': 'Customize', 'ja': 'カスタマイズ', 'zh': '装饰',
    'fr': 'Personnaliser', 'de': 'Anpassen', 'es': 'Personalizar',
    'pt': 'Personalizar', 'ru': 'Настроить', 'tr': 'Özelleştir',
    'ar': 'تخصيص', 'it': 'Personalizza', 'hi': 'कस्टमाइज़', 'th': 'ตกแต่ง',
  });

  String get towerCustomizeTitle => _t({
    'ko': '타워 꾸미기', 'en': 'Customize Tower', 'ja': 'タワーをカスタマイズ', 'zh': '装饰塔',
    'fr': 'Personnaliser la tour', 'de': 'Turm anpassen', 'es': 'Personalizar torre',
    'pt': 'Personalizar torre', 'ru': 'Настроить башню', 'tr': 'Kuleyi özelleştir',
    'ar': 'تخصيص البرج', 'it': 'Personalizza torre', 'hi': 'टावर कस्टमाइज़ करें', 'th': 'ตกแต่งหอคอย',
  });

  String get towerCustomTitle => _t({
    'ko': '꾸미기', 'en': 'Customize', 'ja': 'カスタマイズ', 'zh': '装饰',
    'fr': 'Personnaliser', 'de': 'Anpassen', 'es': 'Personalizar',
    'pt': 'Personalizar', 'ru': 'Настроить', 'tr': 'Özelleştir',
    'ar': 'تخصيص', 'it': 'Personalizza', 'hi': 'कस्टमाइज़', 'th': 'ตกแต่ง',
  });

  String get towerCustomDesc => _t({
    'ko': '타워를 나만의 스타일로', 'en': 'Make your tower unique', 'ja': 'タワーを自分らしく', 'zh': '打造你的专属塔',
    'fr': 'Rendez votre tour unique', 'de': 'Mach deinen Turm einzigartig', 'es': 'Haz tu torre única',
    'pt': 'Torne sua torre única', 'ru': 'Сделайте башню уникальной', 'tr': 'Kuleni benzersiz yap',
    'ar': 'اجعل برجك فريداً', 'it': 'Rendi unica la tua torre', 'hi': 'अपने टावर को अनोखा बनाएं', 'th': 'ทำให้หอคอยเป็นแบบของคุณ',
  });

  String get towerDecoEmoji => _t({
    'ko': '장식 이모지', 'en': 'Decoration Emoji', 'ja': 'デコレーション絵文字', 'zh': '装饰表情',
    'fr': 'Émoji décoratif', 'de': 'Deko-Emoji', 'es': 'Emoji decorativo',
    'pt': 'Emoji decorativo', 'ru': 'Декоративный эмодзи', 'tr': 'Dekorasyon emojisi',
    'ar': 'إيموجي زخرفي', 'it': 'Emoji decorativo', 'hi': 'सजावटी इमोजी', 'th': 'อิโมจิตกแต่ง',
  });

  String get towerGlowColor => _t({
    'ko': '발광 색상', 'en': 'Glow Color', 'ja': '発光カラー', 'zh': '发光颜色',
    'fr': 'Couleur de lueur', 'de': 'Leuchtfarbe', 'es': 'Color de brillo',
    'pt': 'Cor de brilho', 'ru': 'Цвет свечения', 'tr': 'Parlama rengi',
    'ar': 'لون التوهج', 'it': 'Colore bagliore', 'hi': 'चमक रंग', 'th': 'สีเรืองแสง',
  });

  // ── Roof & Window Styles ──────────────────────────────────────────────────

  String get towerRoofStyle => _t({
    'ko': '지붕 스타일', 'en': 'Roof Style', 'ja': '屋根スタイル', 'zh': '屋顶样式',
    'fr': 'Style de toit', 'de': 'Dachstil', 'es': 'Estilo de techo',
    'pt': 'Estilo de telhado', 'ru': 'Стиль крыши', 'tr': 'Çatı stili',
    'ar': 'نمط السقف', 'it': 'Stile del tetto', 'hi': 'छत शैली', 'th': 'รูปแบบหลังคา',
  });

  String get towerRoofDefault => _t({
    'ko': '기본', 'en': 'Default', 'ja': 'デフォルト', 'zh': '默认',
    'fr': 'Par défaut', 'de': 'Standard', 'es': 'Predeterminado',
    'pt': 'Padrão', 'ru': 'По умолчанию', 'tr': 'Varsayılan',
    'ar': 'افتراضي', 'it': 'Predefinito', 'hi': 'डिफ़ॉल्ट', 'th': 'ค่าเริ่มต้น',
  });

  String get towerRoofPointed => _t({
    'ko': '뾰족', 'en': 'Pointed', 'ja': '尖塔', 'zh': '尖顶',
    'fr': 'Pointu', 'de': 'Spitz', 'es': 'Puntiagudo',
    'pt': 'Pontiagudo', 'ru': 'Остроконечная', 'tr': 'Sivri',
    'ar': 'مدبب', 'it': 'Appuntito', 'hi': 'नुकीला', 'th': 'แหลม',
  });

  String get towerRoofDome => _t({
    'ko': '돔', 'en': 'Dome', 'ja': 'ドーム', 'zh': '圆顶',
    'fr': 'Dôme', 'de': 'Kuppel', 'es': 'Cúpula',
    'pt': 'Cúpula', 'ru': 'Купол', 'tr': 'Kubbe',
    'ar': 'قبة', 'it': 'Cupola', 'hi': 'गुंबद', 'th': 'โดม',
  });

  String get towerRoofFlat => _t({
    'ko': '평지붕', 'en': 'Flat', 'ja': 'フラット', 'zh': '平顶',
    'fr': 'Plat', 'de': 'Flach', 'es': 'Plano',
    'pt': 'Plano', 'ru': 'Плоская', 'tr': 'Düz',
    'ar': 'مسطح', 'it': 'Piatto', 'hi': 'सपाट', 'th': 'แบน',
  });

  String get towerRoofAntenna => _t({
    'ko': '안테나', 'en': 'Antenna', 'ja': 'アンテナ', 'zh': '天线',
    'fr': 'Antenne', 'de': 'Antenne', 'es': 'Antena',
    'pt': 'Antena', 'ru': 'Антенна', 'tr': 'Anten',
    'ar': 'هوائي', 'it': 'Antenna', 'hi': 'एंटीना', 'th': 'เสาอากาศ',
  });

  String get towerWindowStyle => _t({
    'ko': '창문 스타일', 'en': 'Window Style', 'ja': '窓スタイル', 'zh': '窗户样式',
    'fr': 'Style de fenêtre', 'de': 'Fensterstil', 'es': 'Estilo de ventana',
    'pt': 'Estilo de janela', 'ru': 'Стиль окон', 'tr': 'Pencere stili',
    'ar': 'نمط النافذة', 'it': 'Stile finestra', 'hi': 'खिड़की शैली', 'th': 'รูปแบบหน้าต่าง',
  });

  String get towerWindowSquare => _t({
    'ko': '사각', 'en': 'Square', 'ja': '四角', 'zh': '方形',
    'fr': 'Carré', 'de': 'Quadratisch', 'es': 'Cuadrada',
    'pt': 'Quadrada', 'ru': 'Квадратное', 'tr': 'Kare',
    'ar': 'مربع', 'it': 'Quadrata', 'hi': 'चौकोर', 'th': 'สี่เหลี่ยม',
  });

  String get towerWindowCircle => _t({
    'ko': '원형', 'en': 'Circle', 'ja': '円形', 'zh': '圆形',
    'fr': 'Rond', 'de': 'Rund', 'es': 'Circular',
    'pt': 'Circular', 'ru': 'Круглое', 'tr': 'Yuvarlak',
    'ar': 'دائري', 'it': 'Circolare', 'hi': 'गोल', 'th': 'กลม',
  });

  String get towerWindowArch => _t({
    'ko': '아치', 'en': 'Arch', 'ja': 'アーチ', 'zh': '拱形',
    'fr': 'Arche', 'de': 'Bogen', 'es': 'Arco',
    'pt': 'Arco', 'ru': 'Арочное', 'tr': 'Kemer',
    'ar': 'مقوس', 'it': 'Arco', 'hi': 'मेहराब', 'th': 'โค้ง',
  });

  String get towerWindowModern => _t({
    'ko': '모던', 'en': 'Modern', 'ja': 'モダン', 'zh': '现代',
    'fr': 'Moderne', 'de': 'Modern', 'es': 'Moderno',
    'pt': 'Moderno', 'ru': 'Современное', 'tr': 'Modern',
    'ar': 'حديث', 'it': 'Moderno', 'hi': 'आधुनिक', 'th': 'โมเดิร์น',
  });

  // ── Ranking Labels ────────────────────────────────────────────────────────

  String get towerRank1 => _t({
    'ko': '1위', 'en': '#1', 'ja': '1位', 'zh': '第1名',
    'fr': '1er', 'de': 'Rang 1', 'es': '1.º',
    'pt': '1º lugar', 'ru': '1-е место', 'tr': '1. sıra',
    'ar': 'المرتبة 1', 'it': '1° posto', 'hi': 'रैंक #1', 'th': 'อันดับ 1',
  });

  String get towerRank2 => _t({
    'ko': '2위', 'en': '#2', 'ja': '2位', 'zh': '第2名',
    'fr': '2e', 'de': 'Rang 2', 'es': '2.º',
    'pt': '2º lugar', 'ru': '2-е место', 'tr': '2. sıra',
    'ar': 'المرتبة 2', 'it': '2° posto', 'hi': 'रैंक #2', 'th': 'อันดับ 2',
  });

  String get towerRank3 => _t({
    'ko': '3위', 'en': '#3', 'ja': '3位', 'zh': '第3名',
    'fr': '3e', 'de': 'Rang 3', 'es': '3.º',
    'pt': '3º lugar', 'ru': '3-е место', 'tr': '3. sıra',
    'ar': 'المرتبة 3', 'it': '3° posto', 'hi': 'रैंक #3', 'th': 'อันดับ 3',
  });

  String towerRankN(int rank) => _t({
    'ko': '${rank}위', 'en': '#$rank', 'ja': '${rank}位', 'zh': '第${rank}名',
    'fr': '${rank}e', 'de': 'Rang $rank', 'es': '$rank.º',
    'pt': '${rank}º lugar', 'ru': '${rank}-е место', 'tr': '$rank. sıra',
    'ar': 'المرتبة $rank', 'it': '${rank}° posto', 'hi': 'रैंक #$rank', 'th': 'อันดับ $rank',
  });

  String towerMyRankLabel(int rank) => _t({
    'ko': '내 순위 ${rank}위', 'en': 'My rank #$rank', 'ja': '自分の順位 ${rank}位', 'zh': '我的排名 第${rank}名',
    'fr': 'Mon classement ${rank}e', 'de': 'Mein Rang $rank', 'es': 'Mi puesto $rank.º',
    'pt': 'Meu ranking ${rank}º', 'ru': 'Моё место: ${rank}-е', 'tr': 'Sıralamam: $rank.',
    'ar': 'ترتيبي: $rank', 'it': 'La mia posizione: ${rank}°', 'hi': 'मेरी रैंक #$rank', 'th': 'อันดับของฉัน $rank',
  });

  String get towerSaveChanges => _t({
    'ko': '변경 저장', 'en': 'Save Changes', 'ja': '変更を保存', 'zh': '保存更改',
    'fr': 'Enregistrer', 'de': 'Änderungen speichern', 'es': 'Guardar cambios',
    'pt': 'Salvar alterações', 'ru': 'Сохранить изменения', 'tr': 'Değişiklikleri kaydet',
    'ar': 'حفظ التغييرات', 'it': 'Salva modifiche', 'hi': 'बदलाव सहेजें', 'th': 'บันทึกการเปลี่ยนแปลง',
  });

  String get towerClose => _t({
    'ko': '닫기', 'en': 'Close', 'ja': '閉じる', 'zh': '关闭',
    'fr': 'Fermer', 'de': 'Schließen', 'es': 'Cerrar',
    'pt': 'Fechar', 'ru': 'Закрыть', 'tr': 'Kapat',
    'ar': 'إغلاق', 'it': 'Chiudi', 'hi': 'बंद करें', 'th': 'ปิด',
  });

  String get towerNickname => _t({
    'ko': '닉네임', 'en': 'Nickname', 'ja': 'ニックネーム', 'zh': '昵称',
    'fr': 'Pseudo', 'de': 'Spitzname', 'es': 'Apodo',
    'pt': 'Apelido', 'ru': 'Никнейм', 'tr': 'Takma ad',
    'ar': 'الاسم المستعار', 'it': 'Soprannome', 'hi': 'उपनाम', 'th': 'ชื่อเล่น',
  });

  String get towerSetNameHint => _t({
    'ko': '타워 이름 입력', 'en': 'Enter tower name', 'ja': 'タワー名を入力', 'zh': '输入塔名',
    'fr': 'Entrez le nom de la tour', 'de': 'Turmnamen eingeben', 'es': 'Ingrese nombre de torre',
    'pt': 'Digite o nome da torre', 'ru': 'Введите название башни', 'tr': 'Kule adını girin',
    'ar': 'أدخل اسم البرج', 'it': 'Inserisci nome torre', 'hi': 'टावर का नाम दर्ज करें', 'th': 'ป้อนชื่อหอคอย',
  });

  String get towerSnsLinkOptional => _t({
    'ko': 'SNS 링크 (선택)', 'en': 'SNS Link (optional)', 'ja': 'SNSリンク（任意）', 'zh': 'SNS链接（可选）',
    'fr': 'Lien SNS (facultatif)', 'de': 'SNS-Link (optional)', 'es': 'Enlace SNS (opcional)',
    'pt': 'Link SNS (opcional)', 'ru': 'Ссылка на соцсеть (необязательно)', 'tr': 'SNS bağlantısı (isteğe bağlı)',
    'ar': 'رابط SNS (اختياري)', 'it': 'Link SNS (facoltativo)', 'hi': 'SNS लिंक (वैकल्पिक)', 'th': 'ลิงก์ SNS (ไม่บังคับ)',
  });

  String get towerActivityStats => _t({
    'ko': '활동 통계', 'en': 'Activity Stats', 'ja': 'アクティビティ統計', 'zh': '活动统计',
    'fr': 'Statistiques d\'activité', 'de': 'Aktivitätsstatistiken', 'es': 'Estadísticas de actividad',
    'pt': 'Estatísticas de atividade', 'ru': 'Статистика активности', 'tr': 'Aktivite istatistikleri',
    'ar': 'إحصائيات النشاط', 'it': 'Statistiche attività', 'hi': 'गतिविधि आँकड़े', 'th': 'สถิติกิจกรรม',
  });

  String towerTierProgress(int current, int total) => _t({
    'ko': '$current단계 / $total단계', 'en': 'Tier $current / $total', 'ja': 'ステージ$current / $total', 'zh': '第$current阶 / $total阶',
    'fr': 'Étape $current / $total', 'de': 'Stufe $current / $total', 'es': 'Nivel $current / $total',
    'pt': 'Nível $current / $total', 'ru': 'Уровень $current / $total', 'tr': 'Aşama $current / $total',
    'ar': 'المرحلة $current / $total', 'it': 'Livello $current / $total', 'hi': 'चरण $current / $total', 'th': 'ระดับ $current / $total',
  });

  String get towerActivityScore => _t({
    'ko': '활동 점수', 'en': 'Activity Score', 'ja': 'アクティビティスコア', 'zh': '活动分数',
    'fr': 'Score d\'activité', 'de': 'Aktivitätspunktzahl', 'es': 'Puntuación de actividad',
    'pt': 'Pontuação de atividade', 'ru': 'Баллы активности', 'tr': 'Aktivite puanı',
    'ar': 'نقاط النشاط', 'it': 'Punteggio attività', 'hi': 'गतिविधि स्कोर', 'th': 'คะแนนกิจกรรม',
  });

  String get towerScoreFormula => _t({
    'ko': '점수 = 보낸×2 + 받은×1 + 답장×3', 'en': 'Score = Sent×2 + Received×1 + Reply×3', 'ja': 'スコア = 送信×2 + 受信×1 + 返信×3', 'zh': '分数 = 发送×2 + 接收×1 + 回复×3',
    'fr': 'Score = Envoyé×2 + Reçu×1 + Réponse×3', 'de': 'Punkte = Gesendet×2 + Empfangen×1 + Antwort×3', 'es': 'Puntos = Enviado×2 + Recibido×1 + Respuesta×3',
    'pt': 'Pontos = Enviado×2 + Recebido×1 + Resposta×3', 'ru': 'Баллы = Отправлено×2 + Получено×1 + Ответ×3', 'tr': 'Puan = Gönderilen×2 + Alınan×1 + Yanıt×3',
    'ar': 'النقاط = مرسل×2 + مستلم×1 + رد×3', 'it': 'Punti = Inviato×2 + Ricevuto×1 + Risposta×3', 'hi': 'स्कोर = भेजे×2 + प्राप्त×1 + उत्तर×3', 'th': 'คะแนน = ส่ง×2 + รับ×1 + ตอบ×3',
  });

  String get towerSentLetters => _t({
    'ko': '보낸 혜택', 'en': 'Sent Promos', 'ja': '送った手紙', 'zh': '已发信件',
    'fr': 'Lettres envoyées', 'de': 'Gesendete Briefe', 'es': 'Cartas enviadas',
    'pt': 'Cartas enviadas', 'ru': 'Отправленные письма', 'tr': 'Gönderilen mektuplar',
    'ar': 'الرسائل المرسلة', 'it': 'Lettere inviate', 'hi': 'भेजे गए पत्र', 'th': 'จดหมายที่ส่ง',
  });

  String get towerReceivedLetters => _t({
    'ko': '받은 혜택', 'en': 'Received Rewards', 'ja': '受け取った手紙', 'zh': '已收信件',
    'fr': 'Lettres reçues', 'de': 'Empfangene Briefe', 'es': 'Cartas recibidas',
    'pt': 'Cartas recebidas', 'ru': 'Полученные письма', 'tr': 'Alınan mektuplar',
    'ar': 'الرسائل المستلمة', 'it': 'Lettere ricevute', 'hi': 'प्राप्त पत्र', 'th': 'จดหมายที่ได้รับ',
  });

  String get towerBuildingFloors => _t({
    'ko': '건물 층수', 'en': 'Building Floors', 'ja': '建物の階数', 'zh': '建筑层数',
    'fr': 'Nombre d\'étages', 'de': 'Gebäudestockwerke', 'es': 'Pisos del edificio',
    'pt': 'Andares do edifício', 'ru': 'Этажей здания', 'tr': 'Bina katları',
    'ar': 'طوابق المبنى', 'it': 'Piani dell\'edificio', 'hi': 'भवन की मंजिलें', 'th': 'จำนวนชั้น',
  });

  String get towerTowerHeight => _t({
    'ko': '타워 높이', 'en': 'Tower Height', 'ja': 'タワーの高さ', 'zh': '塔高',
    'fr': 'Hauteur de la tour', 'de': 'Turmhöhe', 'es': 'Altura de la torre',
    'pt': 'Altura da torre', 'ru': 'Высота башни', 'tr': 'Kule yüksekliği',
    'ar': 'ارتفاع البرج', 'it': 'Altezza torre', 'hi': 'टावर की ऊँचाई', 'th': 'ความสูงหอคอย',
  });

  // Build 183: Brand 쪽에서는 타워 맥락 유지, Free/Premium 은 어차피
  // 이 키가 참조 안 되는 쪽에서 letter 네이밍 써야 함. 공용 라벨이라 letter
  // 네이밍으로 통일.
  /// Build 217: Brand 사용자에게는 "타워 순위" 라는 명칭이 더 적합 (캠페인 영향력
  /// 컨텍스트). Free/Premium 은 캐릭터 없는 화면이라 이 키 자체가 referenced 안 됨.
  String get towerWorldRanking => _t({
    'ko': '타워 순위', 'en': 'Tower Ranking', 'ja': 'タワーランキング', 'zh': '塔排名',
    'fr': 'Classement de tours', 'de': 'Turm-Rangliste', 'es': 'Ranking de torres',
    'pt': 'Ranking de torres', 'ru': 'Рейтинг башен', 'tr': 'Kule sıralaması',
    'ar': 'تصنيف الأبراج', 'it': 'Classifica torri', 'hi': 'टावर रैंकिंग', 'th': 'อันดับหอคอย',
  });

  String towerMyRank(int rank) => _t({
    'ko': '$rank위', 'en': 'Rank #$rank', 'ja': '${rank}位', 'zh': '第${rank}名',
    'fr': '${rank}e', 'de': 'Rang $rank', 'es': 'Puesto $rank',
    'pt': '${rank}º lugar', 'ru': '${rank}-е место', 'tr': '${rank}. sıra',
    'ar': 'المرتبة $rank', 'it': '${rank}° posto', 'hi': 'रैंक #$rank', 'th': 'อันดับที่ $rank',
  });

  String get towerNextGoal => _t({
    'ko': '다음 목표', 'en': 'Next Goal', 'ja': '次の目標', 'zh': '下一个目标',
    'fr': 'Prochain objectif', 'de': 'Nächstes Ziel', 'es': 'Siguiente meta',
    'pt': 'Próxima meta', 'ru': 'Следующая цель', 'tr': 'Sonraki hedef',
    'ar': 'الهدف التالي', 'it': 'Prossimo obiettivo', 'hi': 'अगला लक्ष्य', 'th': 'เป้าหมายถัดไป',
  });

  String towerNextTierInfo(int tierMax, String ptsNeeded) => _t({
    'ko': '$tierMax까지 ${ptsNeeded}점 필요', 'en': '$ptsNeeded pts to tier $tierMax', 'ja': 'ティア${tierMax}まであと${ptsNeeded}ポイント', 'zh': '距等级${tierMax}还需${ptsNeeded}分',
    'fr': '$ptsNeeded pts pour tier $tierMax', 'de': '$ptsNeeded Pkt. bis Stufe $tierMax', 'es': '$ptsNeeded pts para nivel $tierMax',
    'pt': '$ptsNeeded pts para nível $tierMax', 'ru': '$ptsNeeded очков до уровня $tierMax', 'tr': 'Seviye $tierMax için $ptsNeeded puan',
    'ar': '$ptsNeeded نقطة إلى المستوى $tierMax', 'it': '$ptsNeeded punti per livello $tierMax', 'hi': 'टियर $tierMax तक $ptsNeeded अंक', 'th': 'อีก $ptsNeeded คะแนนถึงระดับ $tierMax',
  });

  String get towerTopTierReached => _t({
    'ko': '최고 등급 달성!', 'en': 'Top tier reached!', 'ja': '最高ランク達成！', 'zh': '已达最高等级！',
    'fr': 'Niveau maximum atteint !', 'de': 'Höchste Stufe erreicht!', 'es': '¡Nivel máximo alcanzado!',
    'pt': 'Nível máximo alcançado!', 'ru': 'Высший уровень достигнут!', 'tr': 'En üst seviyeye ulaşıldı!',
    'ar': 'تم الوصول للمستوى الأعلى!', 'it': 'Livello massimo raggiunto!', 'hi': 'शीर्ष स्तर प्राप्त!', 'th': 'ถึงระดับสูงสุดแล้ว!',
  });

  String towerPtsRemaining(String pts) => _t({
    'ko': '${pts}점 남음', 'en': '$pts pts remaining', 'ja': '残り${pts}ポイント', 'zh': '还剩${pts}分',
    'fr': '$pts pts restants', 'de': '$pts Pkt. verbleibend', 'es': '$pts pts restantes',
    'pt': '$pts pts restantes', 'ru': 'Осталось $pts очков', 'tr': '$pts puan kaldı',
    'ar': '$pts نقطة متبقية', 'it': '$pts punti rimanenti', 'hi': '$pts अंक शेष', 'th': 'เหลืออีก $pts คะแนน',
  });

  String get towerStartPremium => _t({
    'ko': '프리미엄 시작', 'en': 'Start Premium', 'ja': 'プレミアム開始', 'zh': '开始高级版',
    'fr': 'Démarrer Premium', 'de': 'Premium starten', 'es': 'Iniciar Premium',
    'pt': 'Iniciar Premium', 'ru': 'Начать Премиум', 'tr': 'Premium\'u başlat',
    'ar': 'ابدأ بريميوم', 'it': 'Avvia Premium', 'hi': 'प्रीमियम शुरू करें', 'th': 'เริ่มพรีเมียม',
  });

  String get towerManageSent => _t({
    'ko': '보낸 혜택 관리', 'en': 'Manage Sent', 'ja': '送信済み管理', 'zh': '管理已发',
    'fr': 'Gérer envoyés', 'de': 'Gesendete verwalten', 'es': 'Gestionar enviados',
    'pt': 'Gerenciar enviados', 'ru': 'Управление отправленными', 'tr': 'Gönderilenler yönet',
    'ar': 'إدارة المرسلة', 'it': 'Gestisci inviati', 'hi': 'भेजे गए प्रबंधित करें', 'th': 'จัดการจดหมายที่ส่ง',
  });

  String get towerManageReceived => _t({
    'ko': '받은 혜택 관리', 'en': 'Manage Received', 'ja': '受信済み管理', 'zh': '管理已收',
    'fr': 'Gérer reçus', 'de': 'Empfangene verwalten', 'es': 'Gestionar recibidos',
    'pt': 'Gerenciar recebidos', 'ru': 'Управление полученными', 'tr': 'Alınanları yönet',
    'ar': 'إدارة المستلمة', 'it': 'Gestisci ricevuti', 'hi': 'प्राप्त प्रबंधित करें', 'th': 'จัดการจดหมายที่ได้รับ',
  });

  String get towerNoLetters => _t({
    'ko': '혜택이 없습니다', 'en': 'No rewards', 'ja': '手紙がありません', 'zh': '没有信件',
    'fr': 'Aucune lettre', 'de': 'Keine Briefe', 'es': 'Sin cartas',
    'pt': 'Sem cartas', 'ru': 'Нет писем', 'tr': 'Mektup yok',
    'ar': 'لا توجد رسائل', 'it': 'Nessuna lettera', 'hi': 'कोई पत्र नहीं', 'th': 'ไม่มีจดหมาย',
  });

  String get towerRead => _t({
    'ko': '읽기', 'en': 'Read', 'ja': '読む', 'zh': '阅读',
    'fr': 'Lire', 'de': 'Lesen', 'es': 'Leer',
    'pt': 'Ler', 'ru': 'Читать', 'tr': 'Oku',
    'ar': 'قراءة', 'it': 'Leggi', 'hi': 'पढ़ें', 'th': 'อ่าน',
  });

  String get towerReply => _t({
    'ko': '답장', 'en': 'Reply', 'ja': '返信', 'zh': '回复',
    'fr': 'Répondre', 'de': 'Antworten', 'es': 'Responder',
    'pt': 'Responder', 'ru': 'Ответить', 'tr': 'Yanıtla',
    'ar': 'رد', 'it': 'Rispondi', 'hi': 'उत्तर दें', 'th': 'ตอบกลับ',
  });

  String get towerAnonymousLetter => _t({
    'ko': '익명 혜택', 'en': 'Anonymous Reward', 'ja': '匿名の手紙', 'zh': '匿名信件',
    'fr': 'Lettre anonyme', 'de': 'Anonymer Brief', 'es': 'Carta anónima',
    'pt': 'Carta anônima', 'ru': 'Анонимное письмо', 'tr': 'Anonim mektup',
    'ar': 'رسالة مجهولة', 'it': 'Lettera anonima', 'hi': 'गुमनाम पत्र', 'th': 'จดหมายนิรนาม',
  });

  String get towerAnonymousUser => _t({
    'ko': '익명 사용자', 'en': 'Anonymous User', 'ja': '匿名ユーザー', 'zh': '匿名用户',
    'fr': 'Utilisateur anonyme', 'de': 'Anonymer Benutzer', 'es': 'Usuario anónimo',
    'pt': 'Usuário anônimo', 'ru': 'Анонимный пользователь', 'tr': 'Anonim kullanıcı',
    'ar': 'مستخدم مجهول', 'it': 'Utente anonimo', 'hi': 'गुमनाम उपयोगकर्ता', 'th': 'ผู้ใช้นิรนาม',
  });

  String towerSentLetterCount(int count) => _t({
    'ko': '보낸 혜택 ${count}통', 'en': '$count sent', 'ja': '送信 ${count}通', 'zh': '已发 ${count}封',
    'fr': '$count envoyée(s)', 'de': '$count gesendet', 'es': '$count enviada(s)',
    'pt': '$count enviada(s)', 'ru': '$count отправлено', 'tr': '$count gönderildi',
    'ar': '$count مرسلة', 'it': '$count inviate', 'hi': '$count भेजे गए', 'th': 'ส่ง $count ฉบับ',
  });

  String towerReceivedLetterCount(int count) => _t({
    'ko': '받은 혜택 ${count}통', 'en': '$count received', 'ja': '受信 ${count}通', 'zh': '已收 ${count}封',
    'fr': '$count reçue(s)', 'de': '$count empfangen', 'es': '$count recibida(s)',
    'pt': '$count recebida(s)', 'ru': '$count получено', 'tr': '$count alındı',
    'ar': '$count مستلمة', 'it': '$count ricevute', 'hi': '$count प्राप्त', 'th': 'รับ $count ฉบับ',
  });

  String towerTotalCount(int count) => _t({
    'ko': '총 ${count}통', 'en': '$count total', 'ja': '合計 ${count}通', 'zh': '共 ${count}封',
    'fr': '$count au total', 'de': '$count insgesamt', 'es': '$count en total',
    'pt': '$count no total', 'ru': 'Всего $count', 'tr': 'Toplam $count',
    'ar': '$count إجمالي', 'it': '$count in totale', 'hi': 'कुल $count', 'th': 'ทั้งหมด $count ฉบับ',
  });

  String get towerDeleteAccountTitle => _t({
    'ko': '회원 탈퇴', 'en': 'Delete Account', 'ja': 'アカウント削除', 'zh': '注销账户',
    'fr': 'Supprimer le compte', 'de': 'Konto löschen', 'es': 'Eliminar cuenta',
    'pt': 'Excluir conta', 'ru': 'Удалить аккаунт', 'tr': 'Hesabı sil',
    'ar': 'حذف الحساب', 'it': 'Elimina account', 'hi': 'खाता हटाएं', 'th': 'ลบบัญชี',
  });

  String get towerDeleteAccountMsg => _t({
    'ko': '정말 탈퇴하시겠습니까?', 'en': 'Are you sure?', 'ja': '本当に退会しますか？', 'zh': '确定要注销吗？',
    'fr': 'Êtes-vous sûr(e) ?', 'de': 'Sind Sie sicher?', 'es': '¿Está seguro?',
    'pt': 'Tem certeza?', 'ru': 'Вы уверены?', 'tr': 'Emin misiniz?',
    'ar': 'هل أنت متأكد؟', 'it': 'Sei sicuro?', 'hi': 'क्या आप सुनिश्चित हैं?', 'th': 'คุณแน่ใจหรือไม่?',
  });

  String get towerDeleteAccountConfirm => _t({
    'ko': '탈퇴 확인', 'en': 'Confirm Delete', 'ja': '削除を確認', 'zh': '确认注销',
    'fr': 'Confirmer la suppression', 'de': 'Löschen bestätigen', 'es': 'Confirmar eliminación',
    'pt': 'Confirmar exclusão', 'ru': 'Подтвердить удаление', 'tr': 'Silmeyi onayla',
    'ar': 'تأكيد الحذف', 'it': 'Conferma eliminazione', 'hi': 'हटाने की पुष्टि करें', 'th': 'ยืนยันการลบ',
  });

  String get towerLogoutMsg => _t({
    'ko': '로그아웃 하시겠습니까?', 'en': 'Log out?', 'ja': 'ログアウトしますか？', 'zh': '确定退出登录？',
    'fr': 'Se déconnecter ?', 'de': 'Abmelden?', 'es': '¿Cerrar sesión?',
    'pt': 'Sair?', 'ru': 'Выйти?', 'tr': 'Çıkış yapılsın mı?',
    'ar': 'تسجيل الخروج؟', 'it': 'Disconnettersi?', 'hi': 'लॉग आउट करें?', 'th': 'ออกจากระบบ?',
  });

  // ── Achievement Badges ────────────────────────────────────────────────────

  String get towerAchievementBadges => _t({
    'ko': '업적 배지', 'en': 'Achievement Badges', 'ja': '実績バッジ', 'zh': '成就徽章',
    'fr': 'Badges de réussite', 'de': 'Erfolgsabzeichen', 'es': 'Insignias de logros',
    'pt': 'Medalhas de conquista', 'ru': 'Значки достижений', 'tr': 'Başarı rozetleri',
    'ar': 'شارات الإنجاز', 'it': 'Badge dei traguardi', 'hi': 'उपलब्धि बैज', 'th': 'เหรียญความสำเร็จ',
  });

  String get towerBadgeFirstStep => _t({
    'ko': '첫 발걸음', 'en': 'First Step', 'ja': '最初の一歩', 'zh': '第一步',
    'fr': 'Premier pas', 'de': 'Erster Schritt', 'es': 'Primer paso',
    'pt': 'Primeiro passo', 'ru': 'Первый шаг', 'tr': 'İlk adım',
    'ar': 'الخطوة الأولى', 'it': 'Primo passo', 'hi': 'पहला कदम', 'th': 'ก้าวแรก',
  });

  String get towerBadgeFirstStepDesc => _t({
    'ko': '첫 홍보 발송', 'en': 'Send your first promo', 'ja': '初めての手紙を送る', 'zh': '发送第一封信',
    'fr': 'Envoyer votre première lettre', 'de': 'Sende deinen ersten Brief', 'es': 'Envía tu primera carta',
    'pt': 'Envie sua primeira carta', 'ru': 'Отправьте первое письмо', 'tr': 'İlk mektubunu gönder',
    'ar': 'أرسل رسالتك الأولى', 'it': 'Invia la tua prima lettera', 'hi': 'अपना पहला पत्र भेजें', 'th': 'ส่งจดหมายฉบับแรก',
  });

  String get towerBadgeCollector => _t({
    'ko': '혜택 수집가', 'en': 'Reward Collector', 'ja': '手紙コレクター', 'zh': '信件收藏家',
    'fr': 'Collectionneur de lettres', 'de': 'Briefesammler', 'es': 'Coleccionista de cartas',
    'pt': 'Colecionador de cartas', 'ru': 'Коллекционер писем', 'tr': 'Mektup koleksiyoncusu',
    'ar': 'جامع الرسائل', 'it': 'Collezionista di lettere', 'hi': 'पत्र संग्रहकर्ता', 'th': 'นักสะสมจดหมาย',
  });

  String get towerBadgeCollectorDesc => _t({
    'ko': '혜택 10통 수집', 'en': 'Collect 10 rewards', 'ja': '手紙を10通集める', 'zh': '收集10封信',
    'fr': 'Collectez 10 lettres', 'de': 'Sammle 10 Briefe', 'es': 'Recopila 10 cartas',
    'pt': 'Colete 10 cartas', 'ru': 'Соберите 10 писем', 'tr': '10 mektup topla',
    'ar': 'اجمع 10 رسائل', 'it': 'Raccogli 10 lettere', 'hi': '10 पत्र संग्रह करें', 'th': 'สะสมจดหมาย 10 ฉบับ',
  });

  String get towerBadgeCommunicator => _t({
    'ko': '소통의 달인', 'en': 'Master Communicator', 'ja': 'コミュニケーション達人', 'zh': '沟通达人',
    'fr': 'Maître communicant', 'de': 'Kommunikationsmeister', 'es': 'Maestro comunicador',
    'pt': 'Mestre comunicador', 'ru': 'Мастер общения', 'tr': 'İletişim ustası',
    'ar': 'خبير التواصل', 'it': 'Maestro comunicatore', 'hi': 'संवाद विशेषज्ञ', 'th': 'นักสื่อสารระดับเซียน',
  });

  String get towerBadgeCommunicatorDesc => _t({
    'ko': '답장 10회', 'en': 'Reply 10 times', 'ja': '返信10回', 'zh': '回复10次',
    'fr': 'Répondez 10 fois', 'de': 'Antworte 10 Mal', 'es': 'Responde 10 veces',
    'pt': 'Responda 10 vezes', 'ru': 'Ответьте 10 раз', 'tr': '10 kez yanıtla',
    'ar': 'قم بالرد 10 مرات', 'it': 'Rispondi 10 volte', 'hi': '10 बार उत्तर दें', 'th': 'ตอบกลับ 10 ครั้ง',
  });

  String get towerBadgeTraveler => _t({
    'ko': '세계 여행자', 'en': 'World Traveler', 'ja': '世界旅行者', 'zh': '世界旅行者',
    'fr': 'Voyageur du monde', 'de': 'Weltreisender', 'es': 'Viajero mundial',
    'pt': 'Viajante mundial', 'ru': 'Путешественник', 'tr': 'Dünya gezgini',
    'ar': 'مسافر حول العالم', 'it': 'Viaggiatore mondiale', 'hi': 'विश्व यात्री', 'th': 'นักเดินทางรอบโลก',
  });

  String get towerBadgeTravelerDesc => _t({
    'ko': '5개국 혜택 수신', 'en': 'Receive rewards from 5 countries', 'ja': '5か国から手紙を受け取る', 'zh': '收到来自5个国家的信',
    'fr': 'Recevez des lettres de 5 pays', 'de': 'Erhalte Briefe aus 5 Ländern', 'es': 'Recibe cartas de 5 países',
    'pt': 'Receba cartas de 5 países', 'ru': 'Получите письма из 5 стран', 'tr': '5 ülkeden mektup al',
    'ar': 'استلم رسائل من 5 دول', 'it': 'Ricevi lettere da 5 paesi', 'hi': '5 देशों से पत्र प्राप्त करें', 'th': 'รับจดหมายจาก 5 ประเทศ',
  });

  String get towerBadgeHouseBuilder => _t({
    'ko': '마을집 건축', 'en': 'House Builder', 'ja': '家の建築', 'zh': '房屋建造者',
    'fr': 'Constructeur de maison', 'de': 'Hausbauer', 'es': 'Constructor de casa',
    'pt': 'Construtor de casa', 'ru': 'Строитель дома', 'tr': 'Ev inşaatçısı',
    'ar': 'باني المنزل', 'it': 'Costruttore di case', 'hi': 'घर निर्माता', 'th': 'ช่างสร้างบ้าน',
  });

  String get towerBadgeHouseBuilderDesc => _t({
    'ko': '타워 5층 달성', 'en': 'Reach tower floor 5', 'ja': 'タワー5階達成', 'zh': '塔达到5层',
    'fr': 'Atteindre l\'étage 5', 'de': 'Erreiche Stockwerk 5', 'es': 'Alcanza el piso 5',
    'pt': 'Alcance o andar 5', 'ru': 'Достигните 5-го этажа', 'tr': '5. kata ulaş',
    'ar': 'الوصول للطابق 5', 'it': 'Raggiungi il piano 5', 'hi': 'टावर मंजिल 5 तक पहुंचें', 'th': 'ถึงชั้นที่ 5',
  });

  String get towerBadgeBuildingArchitect => _t({
    'ko': '빌딩 건축가', 'en': 'Building Architect', 'ja': 'ビル建築家', 'zh': '建筑师',
    'fr': 'Architecte de bâtiment', 'de': 'Gebäudearchitekt', 'es': 'Arquitecto de edificios',
    'pt': 'Arquiteto de edifícios', 'ru': 'Архитектор здания', 'tr': 'Bina mimarı',
    'ar': 'مهندس معماري', 'it': 'Architetto di edifici', 'hi': 'भवन वास्तुकार', 'th': 'สถาปนิก',
  });

  String get towerBadgeBuildingArchitectDesc => _t({
    'ko': '타워 20층 달성', 'en': 'Reach tower floor 20', 'ja': 'タワー20階達成', 'zh': '塔达到20层',
    'fr': 'Atteindre l\'étage 20', 'de': 'Erreiche Stockwerk 20', 'es': 'Alcanza el piso 20',
    'pt': 'Alcance o andar 20', 'ru': 'Достигните 20-го этажа', 'tr': '20. kata ulaş',
    'ar': 'الوصول للطابق 20', 'it': 'Raggiungi il piano 20', 'hi': 'टावर मंजिल 20 तक पहुंचें', 'th': 'ถึงชั้นที่ 20',
  });

  String get towerBadgeSkyscraper => _t({
    'ko': '마천루', 'en': 'Skyscraper', 'ja': '摩天楼', 'zh': '摩天大楼',
    'fr': 'Gratte-ciel', 'de': 'Wolkenkratzer', 'es': 'Rascacielos',
    'pt': 'Arranha-céu', 'ru': 'Небоскрёб', 'tr': 'Gökdelen',
    'ar': 'ناطحة سحاب', 'it': 'Grattacielo', 'hi': 'गगनचुंबी इमारत', 'th': 'ตึกระฟ้า',
  });

  String get towerBadgeSkyscraperDesc => _t({
    'ko': '타워 50층 달성', 'en': 'Reach tower floor 50', 'ja': 'タワー50階達成', 'zh': '塔达到50层',
    'fr': 'Atteindre l\'étage 50', 'de': 'Erreiche Stockwerk 50', 'es': 'Alcanza el piso 50',
    'pt': 'Alcance o andar 50', 'ru': 'Достигните 50-го этажа', 'tr': '50. kata ulaş',
    'ar': 'الوصول للطابق 50', 'it': 'Raggiungi il piano 50', 'hi': 'टावर मंजिल 50 तक पहुंचें', 'th': 'ถึงชั้นที่ 50',
  });

  String get towerBadgePopular => _t({
    'ko': '인기 카운터', 'en': 'Popular Penpal', 'ja': '人気のペンパル', 'zh': '人气笔友',
    'fr': 'Correspondant populaire', 'de': 'Beliebter Brieffreund', 'es': 'Corresponsal popular',
    'pt': 'Correspondente popular', 'ru': 'Популярный друг по переписке', 'tr': 'Popüler mektup arkadaşı',
    'ar': 'صديق مراسلة مشهور', 'it': 'Amico di penna popolare', 'hi': 'लोकप्रिय पेनपाल', 'th': 'เพื่อนทางจดหมายยอดนิยม',
  });

  String get towerBadgePopularDesc => _t({
    'ko': '팔로워 10명 달성', 'en': 'Get 10 followers', 'ja': 'フォロワー10人達成', 'zh': '获得10个关注者',
    'fr': 'Obtenez 10 abonnés', 'de': 'Erreiche 10 Follower', 'es': 'Consigue 10 seguidores',
    'pt': 'Consiga 10 seguidores', 'ru': 'Наберите 10 подписчиков', 'tr': '10 takipçi kazan',
    'ar': 'احصل على 10 متابعين', 'it': 'Ottieni 10 follower', 'hi': '10 फ़ॉलोअर प्राप्त करें', 'th': 'มีผู้ติดตาม 10 คน',
  });

  String get towerBadgeLegendaryLandmark => _t({
    'ko': '전설의 랜드마크', 'en': 'Legendary Landmark', 'ja': '伝説のランドマーク', 'zh': '传奇地标',
    'fr': 'Monument légendaire', 'de': 'Legendäres Wahrzeichen', 'es': 'Monumento legendario',
    'pt': 'Marco lendário', 'ru': 'Легендарный ориентир', 'tr': 'Efsanevi simge',
    'ar': 'معلم أسطوري', 'it': 'Punto di riferimento leggendario', 'hi': 'महान स्थल', 'th': 'สถานที่ระดับตำนาน',
  });

  String get towerBadgeLegendaryLandmarkDesc => _t({
    'ko': '타워 100층 달성', 'en': 'Reach tower floor 100', 'ja': 'タワー100階達成', 'zh': '塔达到100层',
    'fr': 'Atteindre l\'étage 100', 'de': 'Erreiche Stockwerk 100', 'es': 'Alcanza el piso 100',
    'pt': 'Alcance o andar 100', 'ru': 'Достигните 100-го этажа', 'tr': '100. kata ulaş',
    'ar': 'الوصول للطابق 100', 'it': 'Raggiungi il piano 100', 'hi': 'टावर मंजिल 100 तक पहुंचें', 'th': 'ถึงชั้นที่ 100',
  });

  // ── DM / Status / ETA / Transport ──────────────────────────────────
  // ── DM (Direct Message) ──────────────────────────────────────────────────

  String get dmTitle => _t({
    'ko': '메시지', 'en': 'Messages', 'ja': 'メッセージ', 'zh': '消息',
    'fr': 'Messages', 'de': 'Nachrichten', 'es': 'Mensajes',
    'pt': 'Mensagens', 'ru': 'Сообщения', 'tr': 'Mesajlar',
    'ar': 'الرسائل', 'it': 'Messaggi', 'hi': 'संदेश', 'th': 'ข้อความ',
  });

  String get dmWriteMessage => _t({
    'ko': '메시지 입력...', 'en': 'Type a message...', 'ja': 'メッセージを入力...', 'zh': '输入消息...',
    'fr': 'Saisissez un message...', 'de': 'Nachricht eingeben...', 'es': 'Escribe un mensaje...',
    'pt': 'Digite uma mensagem...', 'ru': 'Введите сообщение...', 'tr': 'Bir mesaj yazın...',
    'ar': 'اكتب رسالة...', 'it': 'Scrivi un messaggio...', 'hi': 'संदेश लिखें...', 'th': 'พิมพ์ข้อความ...',
  });

  String get dmPremiumOnly => _t({
    'ko': 'DM은 프리미엄 전용 기능입니다', 'en': 'DM is a premium-only feature', 'ja': 'DMはプレミアム専用機能です', 'zh': 'DM是高级专属功能',
    'fr': 'Les DM sont réservés aux abonnés premium', 'de': 'DM ist eine Premium-exklusive Funktion', 'es': 'Los DM son una función exclusiva premium',
    'pt': 'DM é um recurso exclusivo premium', 'ru': 'Личные сообщения доступны только в премиум', 'tr': 'DM yalnızca premium kullanıcılara özeldir',
    'ar': 'الرسائل المباشرة ميزة حصرية للمميزين', 'it': 'I DM sono una funzione esclusiva premium', 'hi': 'DM केवल प्रीमियम सुविधा है', 'th': 'DM เป็นฟีเจอร์สำหรับพรีเมียมเท่านั้น',
  });

  String get dmUnavailableTitle => _t({
    'ko': 'DM 사용 불가', 'en': 'DM Unavailable', 'ja': 'DMは利用できません', 'zh': 'DM不可用',
    'fr': 'DM indisponible', 'de': 'DM nicht verfügbar', 'es': 'DM no disponible',
    'pt': 'DM indisponível', 'ru': 'Личные сообщения недоступны', 'tr': 'DM kullanılamıyor',
    'ar': 'الرسائل المباشرة غير متاحة', 'it': 'DM non disponibile', 'hi': 'DM उपलब्ध नहीं', 'th': 'DM ไม่พร้อมใช้งาน',
  });

  String get dmGateFeature1 => _t({
    'ko': '1:1 실시간 대화', 'en': 'Real-time 1:1 chat', 'ja': '1:1リアルタイムチャット', 'zh': '1:1实时聊天',
    'fr': 'Chat 1:1 en temps réel', 'de': '1:1-Echtzeit-Chat', 'es': 'Chat 1:1 en tiempo real',
    'pt': 'Chat 1:1 em tempo real', 'ru': 'Чат 1:1 в реальном времени', 'tr': '1:1 gerçek zamanlı sohbet',
    'ar': 'محادثة فردية فورية', 'it': 'Chat 1:1 in tempo reale', 'hi': '1:1 रीयल-टाइम चैट', 'th': 'แชท 1:1 แบบเรียลไทม์',
  });

  // Build 114: "펜팔 / 혜택 친구" 문구를 "긴 대화 스레드" 로 교체. DM 기능은
  // Build 104 패치에서 UI 숨김 상태지만, 코드 경로가 살아있어 l10n 만이라도
  // 현재 헌트 포지셔닝과 충돌하지 않게 정리.
  String get dmGateFeature2 => _t({
    'ko': '오래 이어가는 대화 스레드', 'en': 'Ongoing conversation threads', 'ja': '長く続ける会話スレッド', 'zh': '持续的对话主题',
    'fr': 'Fils de conversation continus', 'de': 'Fortlaufende Gesprächsstränge', 'es': 'Hilos de conversación continuos',
    'pt': 'Threads de conversa contínuos', 'ru': 'Долговременные ветки диалогов', 'tr': 'Uzun süreli sohbet akışları',
    'ar': 'خيوط محادثة مستمرة', 'it': 'Fili di conversazione continui', 'hi': 'लगातार चलने वाले बातचीत थ्रेड', 'th': 'กระทู้สนทนาต่อเนื่อง',
  });

  String get dmGateFeature3 => _t({
    'ko': '사진 및 이미지 공유', 'en': 'Share photos and images', 'ja': '写真や画像を共有', 'zh': '分享照片和图片',
    'fr': 'Partager des photos et des images', 'de': 'Fotos und Bilder teilen', 'es': 'Compartir fotos e imágenes',
    'pt': 'Compartilhar fotos e imagens', 'ru': 'Делитесь фото и изображениями', 'tr': 'Fotoğraf ve görsel paylaşın',
    'ar': 'مشاركة الصور والصور', 'it': 'Condividi foto e immagini', 'hi': 'फ़ोटो और चित्र साझा करें', 'th': 'แชร์รูปภาพและภาพ',
  });

  String get dmGateFeature4 => _t({
    'ko': '상호 팔로우 시 자동 활성화', 'en': 'Auto-enabled with mutual follow', 'ja': '相互フォローで自動有効化', 'zh': '互相关注后自动启用',
    'fr': 'Activation auto avec suivi mutuel', 'de': 'Automatisch aktiviert bei gegenseitigem Folgen', 'es': 'Activación automática con seguimiento mutuo',
    'pt': 'Ativação automática com seguimento mútuo', 'ru': 'Автоматическая активация при взаимной подписке', 'tr': 'Karşılıklı takipte otomatik etkinleşir',
    'ar': 'تفعيل تلقائي عند المتابعة المتبادلة', 'it': 'Attivazione automatica con follow reciproco', 'hi': 'आपसी फ़ॉलो पर स्वतः सक्रिय', 'th': 'เปิดใช้งานอัตโนมัติเมื่อติดตามกัน',
  });

  String get dmCancel => _t({
    'ko': '취소', 'en': 'Cancel', 'ja': 'キャンセル', 'zh': '取消',
    'fr': 'Annuler', 'de': 'Abbrechen', 'es': 'Cancelar',
    'pt': 'Cancelar', 'ru': 'Отмена', 'tr': 'İptal',
    'ar': 'إلغاء', 'it': 'Annulla', 'hi': 'रद्द करें', 'th': 'ยกเลิก',
  });

  String get dmConfirm => _t({
    'ko': '확인', 'en': 'Confirm', 'ja': '確認', 'zh': '确认',
    'fr': 'Confirmer', 'de': 'Bestätigen', 'es': 'Confirmar',
    'pt': 'Confirmar', 'ru': 'Подтвердить', 'tr': 'Onayla',
    'ar': 'تأكيد', 'it': 'Conferma', 'hi': 'पुष्टि करें', 'th': 'ยืนยัน',
  });

  String get dmBlock => _t({
    'ko': '차단', 'en': 'Block', 'ja': 'ブロック', 'zh': '屏蔽',
    'fr': 'Bloquer', 'de': 'Blockieren', 'es': 'Bloquear',
    'pt': 'Bloquear', 'ru': 'Заблокировать', 'tr': 'Engelle',
    'ar': 'حظر', 'it': 'Blocca', 'hi': 'ब्लॉक करें', 'th': 'บล็อก',
  });

  String get dmBlockUser => _t({
    'ko': '사용자 차단', 'en': 'Block User', 'ja': 'ユーザーをブロック', 'zh': '屏蔽用户',
    'fr': 'Bloquer l\'utilisateur', 'de': 'Benutzer blockieren', 'es': 'Bloquear usuario',
    'pt': 'Bloquear usuário', 'ru': 'Заблокировать пользователя', 'tr': 'Kullanıcıyı engelle',
    'ar': 'حظر المستخدم', 'it': 'Blocca utente', 'hi': 'उपयोगकर्ता को ब्लॉक करें', 'th': 'บล็อกผู้ใช้',
  });

  String get dmBlockAction => _t({
    'ko': '차단하기', 'en': 'Block', 'ja': 'ブロックする', 'zh': '屏蔽',
    'fr': 'Bloquer', 'de': 'Blockieren', 'es': 'Bloquear',
    'pt': 'Bloquear', 'ru': 'Заблокировать', 'tr': 'Engelle',
    'ar': 'حظر', 'it': 'Blocca', 'hi': 'ब्लॉक करें', 'th': 'บล็อก',
  });

  String dmBlockConfirm(String name) => _t({
    'ko': '$name님을 차단하시겠습니까?', 'en': 'Block $name?', 'ja': '$nameさんをブロックしますか？', 'zh': '屏蔽$name？',
    'fr': 'Bloquer $name ?', 'de': '$name blockieren?', 'es': '¿Bloquear a $name?',
    'pt': 'Bloquear $name?', 'ru': 'Заблокировать $name?', 'tr': '$name engellensin mi?',
    'ar': 'حظر $name؟', 'it': 'Bloccare $name?', 'hi': '$name को ब्लॉक करें?', 'th': 'บล็อก $name?',
  });

  String dmBlocked(String name) => _t({
    'ko': '$name님을 차단했습니다', 'en': '$name has been blocked', 'ja': '$nameさんをブロックしました', 'zh': '已屏蔽$name',
    'fr': '$name a été bloqué', 'de': '$name wurde blockiert', 'es': '$name ha sido bloqueado',
    'pt': '$name foi bloqueado', 'ru': '$name заблокирован(а)', 'tr': '$name engellendi',
    'ar': 'تم حظر $name', 'it': '$name è stato bloccato', 'hi': '$name को ब्लॉक किया गया', 'th': 'บล็อก $name แล้ว',
  });

  String get dmReport => _t({
    'ko': '신고', 'en': 'Report', 'ja': '報告', 'zh': '举报',
    'fr': 'Signaler', 'de': 'Melden', 'es': 'Reportar',
    'pt': 'Denunciar', 'ru': 'Пожаловаться', 'tr': 'Şikayet et',
    'ar': 'إبلاغ', 'it': 'Segnala', 'hi': 'रिपोर्ट करें', 'th': 'รายงาน',
  });

  String get dmReportUser => _t({
    'ko': '사용자 신고', 'en': 'Report User', 'ja': 'ユーザーを報告', 'zh': '举报用户',
    'fr': 'Signaler l\'utilisateur', 'de': 'Benutzer melden', 'es': 'Reportar usuario',
    'pt': 'Denunciar usuário', 'ru': 'Пожаловаться на пользователя', 'tr': 'Kullanıcıyı şikayet et',
    'ar': 'الإبلاغ عن المستخدم', 'it': 'Segnala utente', 'hi': 'उपयोगकर्ता की रिपोर्ट करें', 'th': 'รายงานผู้ใช้',
  });

  String get dmReportAction => _t({
    'ko': '신고하기', 'en': 'Report', 'ja': '報告する', 'zh': '举报',
    'fr': 'Signaler', 'de': 'Melden', 'es': 'Reportar',
    'pt': 'Denunciar', 'ru': 'Пожаловаться', 'tr': 'Şikayet et',
    'ar': 'إبلاغ', 'it': 'Segnala', 'hi': 'रिपोर्ट करें', 'th': 'รายงาน',
  });

  String get dmReportAutoBlock => _t({
    'ko': '신고 시 자동으로 차단됩니다', 'en': 'User will be auto-blocked on report', 'ja': '報告すると自動的にブロックされます', 'zh': '举报后将自动屏蔽该用户',
    'fr': 'L\'utilisateur sera automatiquement bloqué lors du signalement', 'de': 'Der Benutzer wird bei Meldung automatisch blockiert', 'es': 'El usuario será bloqueado automáticamente al reportar',
    'pt': 'O usuário será bloqueado automaticamente ao denunciar', 'ru': 'Пользователь будет автоматически заблокирован при жалобе', 'tr': 'Şikayet edildiğinde kullanıcı otomatik olarak engellenecektir',
    'ar': 'سيتم حظر المستخدم تلقائياً عند الإبلاغ', 'it': 'L\'utente verrà bloccato automaticamente alla segnalazione', 'hi': 'रिपोर्ट करने पर उपयोगकर्ता स्वतः ब्लॉक हो जाएगा', 'th': 'ผู้ใช้จะถูกบล็อกอัตโนมัติเมื่อรายงาน',
  });

  String get dmReportReasonSpam => _t({
    'ko': '스팸', 'en': 'Spam', 'ja': 'スパム', 'zh': '垃圾信息',
    'fr': 'Spam', 'de': 'Spam', 'es': 'Spam',
    'pt': 'Spam', 'ru': 'Спам', 'tr': 'Spam',
    'ar': 'بريد مزعج', 'it': 'Spam', 'hi': 'स्पैम', 'th': 'สแปม',
  });

  String get dmReportReasonHarass => _t({
    'ko': '괴롭힘', 'en': 'Harassment', 'ja': 'ハラスメント', 'zh': '骚扰',
    'fr': 'Harcèlement', 'de': 'Belästigung', 'es': 'Acoso',
    'pt': 'Assédio', 'ru': 'Домогательство', 'tr': 'Taciz',
    'ar': 'تحرش', 'it': 'Molestie', 'hi': 'उत्पीड़न', 'th': 'การคุกคาม',
  });

  String get dmReportReasonHate => _t({
    'ko': '혐오 발언', 'en': 'Hate Speech', 'ja': 'ヘイトスピーチ', 'zh': '仇恨言论',
    'fr': 'Discours haineux', 'de': 'Hassrede', 'es': 'Discurso de odio',
    'pt': 'Discurso de ódio', 'ru': 'Язык ненависти', 'tr': 'Nefret söylemi',
    'ar': 'خطاب كراهية', 'it': 'Incitamento all\'odio', 'hi': 'घृणा भाषण', 'th': 'ถ้อยคำแห่งความเกลียดชัง',
  });

  String get dmReportReasonIllegal => _t({
    'ko': '불법 콘텐츠', 'en': 'Illegal Content', 'ja': '違法コンテンツ', 'zh': '违法内容',
    'fr': 'Contenu illégal', 'de': 'Illegaler Inhalt', 'es': 'Contenido ilegal',
    'pt': 'Conteúdo ilegal', 'ru': 'Незаконный контент', 'tr': 'Yasadışı içerik',
    'ar': 'محتوى غير قانوني', 'it': 'Contenuto illegale', 'hi': 'अवैध सामग्री', 'th': 'เนื้อหาผิดกฎหมาย',
  });

  String get dmReportReasonOther => _t({
    'ko': '기타', 'en': 'Other', 'ja': 'その他', 'zh': '其他',
    'fr': 'Autre', 'de': 'Sonstiges', 'es': 'Otro',
    'pt': 'Outro', 'ru': 'Другое', 'tr': 'Diğer',
    'ar': 'أخرى', 'it': 'Altro', 'hi': 'अन्य', 'th': 'อื่นๆ',
  });

  String dmReportReason(String reason) => _t({
    'ko': '신고 사유: $reason', 'en': 'Report reason: $reason', 'ja': '報告理由: $reason', 'zh': '举报原因: $reason',
    'fr': 'Motif du signalement : $reason', 'de': 'Meldegrund: $reason', 'es': 'Motivo del reporte: $reason',
    'pt': 'Motivo da denúncia: $reason', 'ru': 'Причина жалобы: $reason', 'tr': 'Şikayet nedeni: $reason',
    'ar': 'سبب الإبلاغ: $reason', 'it': 'Motivo della segnalazione: $reason', 'hi': 'रिपोर्ट का कारण: $reason', 'th': 'เหตุผลในการรายงาน: $reason',
  });

  String dmReported(String name) => _t({
    'ko': '$name님을 신고했습니다', 'en': '$name has been reported', 'ja': '$nameさんを報告しました', 'zh': '已举报$name',
    'fr': '$name a été signalé', 'de': '$name wurde gemeldet', 'es': '$name ha sido reportado',
    'pt': '$name foi denunciado', 'ru': 'Жалоба на $name отправлена', 'tr': '$name şikayet edildi',
    'ar': 'تم الإبلاغ عن $name', 'it': '$name è stato segnalato', 'hi': '$name की रिपोर्ट की गई', 'th': 'รายงาน $name แล้ว',
  });

  String dmConversationInfo(String name, int quota) => _t({
    'ko': '$name님과의 대화 (메시지 $quota개 가능)', 'en': 'Chat with $name ($quota messages available)', 'ja': '$nameさんとの会話（残り$quota通）', 'zh': '与$name的对话（剩余$quota条）',
    'fr': 'Discussion avec $name ($quota messages disponibles)', 'de': 'Chat mit $name ($quota Nachrichten verfügbar)', 'es': 'Chat con $name ($quota mensajes disponibles)',
    'pt': 'Conversa com $name ($quota mensagens disponíveis)', 'ru': 'Чат с $name ($quota сообщений доступно)', 'tr': '$name ile sohbet ($quota mesaj kaldı)',
    'ar': 'محادثة مع $name ($quota رسائل متاحة)', 'it': 'Chat con $name ($quota messaggi disponibili)', 'hi': '$name के साथ चैट ($quota संदेश उपलब्ध)', 'th': 'สนทนากับ $name (เหลือ $quota ข้อความ)',
  });

  String dmStartChat(String name) => _t({
    'ko': '$name님과 대화 시작', 'en': 'Start chat with $name', 'ja': '$nameさんとチャットを開始', 'zh': '开始与$name聊天',
    'fr': 'Démarrer une discussion avec $name', 'de': 'Chat mit $name starten', 'es': 'Iniciar chat con $name',
    'pt': 'Iniciar conversa com $name', 'ru': 'Начать чат с $name', 'tr': '$name ile sohbeti başlat',
    'ar': 'بدء محادثة مع $name', 'it': 'Avvia chat con $name', 'hi': '$name के साथ चैट शुरू करें', 'th': 'เริ่มแชทกับ $name',
  });

  String dmQuotaInfo(String name, int remaining) => _t({
    'ko': '$name님과 대화 · 남은 메시지: $remaining', 'en': 'Chat with $name · $remaining remaining', 'ja': '$nameさんとの会話 · 残り$remaining通', 'zh': '与$name聊天 · 剩余$remaining条',
    'fr': 'Chat avec $name · $remaining restants', 'de': 'Chat mit $name · $remaining übrig', 'es': 'Chat con $name · $remaining restantes',
    'pt': 'Chat com $name · $remaining restantes', 'ru': 'Чат с $name · осталось $remaining', 'tr': '$name ile sohbet · $remaining kaldı',
    'ar': 'محادثة مع $name · $remaining متبقية', 'it': 'Chat con $name · $remaining rimanenti', 'hi': '$name के साथ चैट · $remaining शेष', 'th': 'แชทกับ $name · เหลือ $remaining',
  });

  String dmQuotaInsufficient(int quota) => _t({
    'ko': '오늘 메시지 한도에 도달했습니다', 'en': 'Daily message limit reached', 'ja': '本日のメッセージ上限に達しました', 'zh': '今日消息限额已达上限',
    'fr': 'Limite quotidienne de messages atteinte', 'de': 'Tägliches Nachrichtenlimit erreicht', 'es': 'Límite diario de mensajes alcanzado',
    'pt': 'Limite diário de mensagens atingido', 'ru': 'Дневной лимит сообщений достигнут', 'tr': 'Günlük mesaj limitine ulaşıldı',
    'ar': 'تم الوصول إلى الحد اليومي للرسائل', 'it': 'Limite giornaliero di messaggi raggiunto', 'hi': 'दैनिक संदेश सीमा पूरी हो गई', 'th': 'ถึงขีดจำกัดข้อความรายวันแล้ว',
  });

  // ── Status / Stage (letter delivery) ────────────────────────────────────

  String get statusDrafting => _t({
    'ko': '작성 중', 'en': 'Drafting', 'ja': '作成中', 'zh': '撰写中',
    'fr': 'Rédaction', 'de': 'Entwurf', 'es': 'Redactando',
    'pt': 'Redigindo', 'ru': 'Черновик', 'tr': 'Yazılıyor',
    'ar': 'جارٍ الكتابة', 'it': 'In bozza', 'hi': 'लिखा जा रहा है', 'th': 'กำลังร่าง',
  });

  String get statusNearby => _t({
    'ko': '마지막 배달 구간 🛵',
    'en': 'Out for final delivery 🛵',
    'ja': '最終配達区間 🛵',
    'zh': '最后一公里 🛵',
    'fr': 'En livraison finale 🛵',
    'de': 'Letzte Zustellstrecke 🛵',
    'es': 'En reparto final 🛵',
    'pt': 'Entrega final 🛵',
    'ru': 'Последняя миля 🛵',
    'tr': 'Son teslim etabı 🛵',
    'ar': 'المرحلة الأخيرة من التسليم 🛵',
    'it': 'Ultimo tratto di consegna 🛵',
    'hi': 'अंतिम वितरण चरण 🛵',
    'th': 'ช่วงสุดท้ายก่อนส่งถึง 🛵',
  });

  String get statusArrivedPickup => _t({
    'ko': '우체국 도착 · 수령 대기 📬',
    'en': 'Arrived at post office · Awaiting pickup 📬',
    'ja': '郵便局到着・受取待ち 📬',
    'zh': '已到邮局 · 等待取件 📬',
    'fr': 'Arrivé au bureau de poste · En attente 📬',
    'de': 'Im Postamt · Wartet auf Abholung 📬',
    'es': 'En la oficina postal · Esperando recogida 📬',
    'pt': 'Nos correios · Aguardando retirada 📬',
    'ru': 'Прибыло в отделение · Ожидает получения 📬',
    'tr': 'Postanede · Teslim alınmayı bekliyor 📬',
    'ar': 'وصلت إلى مكتب البريد · بانتظار الاستلام 📬',
    'it': 'All\'ufficio postale · In attesa di ritiro 📬',
    'hi': 'डाकघर पहुँचा · लेने की प्रतीक्षा 📬',
    'th': 'ถึงที่ทำการไปรษณีย์ · รอรับ 📬',
  });

  String get statusDelivered => _t({
    'ko': '우편함 도착 💌',
    'en': 'In your mailbox 💌',
    'ja': 'ポストに到着 💌',
    'zh': '已投入信箱 💌',
    'fr': 'Dans votre boîte aux lettres 💌',
    'de': 'Im Briefkasten 💌',
    'es': 'En tu buzón 💌',
    'pt': 'Na sua caixa de correio 💌',
    'ru': 'В вашем почтовом ящике 💌',
    'tr': 'Posta kutunuzda 💌',
    'ar': 'في صندوق بريدك 💌',
    'it': 'Nella tua cassetta 💌',
    'hi': 'आपके डाक-बक्से में 💌',
    'th': 'ถึงตู้จดหมายแล้ว 💌',
  });

  String get statusRead => _t({
    'ko': '읽음', 'en': 'Read', 'ja': '既読', 'zh': '已读',
    'fr': 'Lu', 'de': 'Gelesen', 'es': 'Leído',
    'pt': 'Lido', 'ru': 'Прочитано', 'tr': 'Okundu',
    'ar': 'مقروءة', 'it': 'Letta', 'hi': 'पढ़ा गया', 'th': 'อ่านแล้ว',
  });

  String get stageDelivered => _t({
    'ko': '전달 완료', 'en': 'Delivered', 'ja': '配達完了', 'zh': '已送达',
    'fr': 'Livré', 'de': 'Zugestellt', 'es': 'Entregado',
    'pt': 'Entregue', 'ru': 'Доставлено', 'tr': 'Teslim edildi',
    'ar': 'تم التسليم', 'it': 'Consegnata', 'hi': 'वितरित', 'th': 'ส่งแล้ว',
  });

  String get stageNearby2km => _t({
    'ko': '2km 이내 도착', 'en': 'Arrived within 2km', 'ja': '2km以内に到着', 'zh': '已到达2km以内',
    'fr': 'Arrivé à moins de 2 km', 'de': 'Innerhalb von 2 km angekommen', 'es': 'Llegó a menos de 2 km',
    'pt': 'Chegou a menos de 2 km', 'ru': 'Прибыло в пределах 2 км', 'tr': '2 km içinde ulaştı',
    'ar': 'وصلت ضمن 2 كم', 'it': 'Arrivata entro 2 km', 'hi': '2 km के भीतर पहुँचा', 'th': 'มาถึงภายใน 2 กม.',
  });

  String get stageArrivedLocalPickup => _t({
    'ko': '현지 도착 - 수령 가능', 'en': 'Local arrival - Ready for pickup', 'ja': '現地到着 - 受取可能', 'zh': '已到达当地 - 可取件',
    'fr': 'Arrivée locale - Prêt pour le retrait', 'de': 'Vor Ort angekommen - Abholbereit', 'es': 'Llegada local - Listo para recoger',
    'pt': 'Chegada local - Pronto para retirada', 'ru': 'Прибыло на месте - Готово к получению', 'tr': 'Yerel varış - Teslim almaya hazır',
    'ar': 'وصول محلي - جاهز للاستلام', 'it': 'Arrivo locale - Pronto per il ritiro', 'hi': 'स्थानीय आगमन - लेने के लिए तैयार', 'th': 'ถึงในพื้นที่ - พร้อมรับ',
  });

  // ── Arrival (time estimates) ────────────────────────────────────────────

  String arrivalMinutes(int min) => _t({
    'ko': '$min분', 'en': '$min min', 'ja': '$min分', 'zh': '$min分钟',
    'fr': '$min min', 'de': '$min Min.', 'es': '$min min',
    'pt': '$min min', 'ru': '$min мин.', 'tr': '$min dk',
    'ar': '$min دقيقة', 'it': '$min min', 'hi': '$min मिनट', 'th': '$min นาที',
  });

  String arrivalHours(int h) => _t({
    'ko': '$h시간', 'en': '$h hr', 'ja': '$h時間', 'zh': '$h小时',
    'fr': '$h h', 'de': '$h Std.', 'es': '$h h',
    'pt': '$h h', 'ru': '$h ч.', 'tr': '$h sa',
    'ar': '$h ساعة', 'it': '$h ore', 'hi': '$h घंटा', 'th': '$h ชั่วโมง',
  });

  String arrivalHoursMinutes(int h, int m) => _t({
    'ko': '$h시간 $m분', 'en': '$h hr $m min', 'ja': '$h時間$m分', 'zh': '$h小时$m分钟',
    'fr': '$h h $m min', 'de': '$h Std. $m Min.', 'es': '$h h $m min',
    'pt': '$h h $m min', 'ru': '$h ч. $m мин.', 'tr': '$h sa $m dk',
    'ar': '$h ساعة $m دقيقة', 'it': '$h ore $m min', 'hi': '$h घंटा $m मिनट', 'th': '$h ชั่วโมง $m นาที',
  });

  String arrivalDays(int d, String date) => _t({
    'ko': '$d일 ($date)', 'en': '$d days ($date)', 'ja': '$d日 ($date)', 'zh': '$d天 ($date)',
    'fr': '$d jours ($date)', 'de': '$d Tage ($date)', 'es': '$d días ($date)',
    'pt': '$d dias ($date)', 'ru': '$d дн. ($date)', 'tr': '$d gün ($date)',
    'ar': '$d يوم ($date)', 'it': '$d giorni ($date)', 'hi': '$d दिन ($date)', 'th': '$d วัน ($date)',
  });

  String get arrivalComplete => _t({
    'ko': '도착 완료', 'en': 'Arrived', 'ja': '到着完了', 'zh': '已到达',
    'fr': 'Arrivé', 'de': 'Angekommen', 'es': 'Llegó',
    'pt': 'Chegou', 'ru': 'Прибыло', 'tr': 'Ulaştı',
    'ar': 'وصلت', 'it': 'Arrivata', 'hi': 'पहुँच गया', 'th': 'มาถึงแล้ว',
  });

  String get arrivalDestinationWaiting => _t({
    'ko': '목적지 대기 중', 'en': 'Waiting at destination', 'ja': '目的地で待機中', 'zh': '在目的地等待中',
    'fr': 'En attente à destination', 'de': 'Wartet am Zielort', 'es': 'Esperando en destino',
    'pt': 'Aguardando no destino', 'ru': 'Ожидание на месте назначения', 'tr': 'Hedefte bekliyor',
    'ar': 'في انتظار الوجهة', 'it': 'In attesa a destinazione', 'hi': 'गंतव्य पर प्रतीक्षा', 'th': 'รอที่จุดหมาย',
  });

  String get arrivalNearbyPickup => _t({
    'ko': '근처에서 수령 가능', 'en': 'Available for nearby pickup', 'ja': '近くで受取可能', 'zh': '可在附近取件',
    'fr': 'Disponible pour retrait à proximité', 'de': 'Zur Abholung in der Nähe verfügbar', 'es': 'Disponible para recogida cercana',
    'pt': 'Disponível para retirada próxima', 'ru': 'Доступно для получения поблизости', 'tr': 'Yakınlarda teslim alınabilir',
    'ar': 'متاح للاستلام القريب', 'it': 'Disponibile per ritiro nelle vicinanze', 'hi': 'आस-पास से लेने के लिए उपलब्ध', 'th': 'พร้อมรับใกล้เคียง',
  });

  // ── ETA (delivery time estimates) ───────────────────────────────────────

  String get etaSameDay => _t({
    'ko': '당일 배송', 'en': 'Same day', 'ja': '当日配達', 'zh': '当日送达',
    'fr': 'Le jour même', 'de': 'Am selben Tag', 'es': 'El mismo día',
    'pt': 'No mesmo dia', 'ru': 'В тот же день', 'tr': 'Aynı gün',
    'ar': 'نفس اليوم', 'it': 'Lo stesso giorno', 'hi': 'उसी दिन', 'th': 'ภายในวันเดียวกัน',
  });

  String get etaDomestic => _t({
    'ko': '국내 1~3시간', 'en': 'Domestic 1-3 hours', 'ja': '国内 1〜3時間', 'zh': '国内 1-3小时',
    'fr': 'National 1 à 3 heures', 'de': 'Inland 1–3 Stunden', 'es': 'Nacional 1-3 horas',
    'pt': 'Nacional 1-3 horas', 'ru': 'Внутри страны 1–3 часа', 'tr': 'Yurt içi 1-3 saat',
    'ar': 'محلي 1-3 ساعات', 'it': 'Nazionale 1-3 ore', 'hi': 'घरेलू 1-3 घंटे', 'th': 'ภายในประเทศ 1-3 ชั่วโมง',
  });

  String get etaIntlAirShort => _t({
    'ko': '국제 항공 6~12시간', 'en': 'Intl. air 6-12 hours', 'ja': '国際航空 6〜12時間', 'zh': '国际航空 6-12小时',
    'fr': 'Aérien intl. 6 à 12 heures', 'de': 'Intl. Luftpost 6–12 Stunden', 'es': 'Aéreo intl. 6-12 horas',
    'pt': 'Aéreo intl. 6-12 horas', 'ru': 'Междунар. авиа 6–12 часов', 'tr': 'Uluslararası hava 6-12 saat',
    'ar': 'جوي دولي 6-12 ساعة', 'it': 'Aereo intl. 6-12 ore', 'hi': 'अंतर्राष्ट्रीय हवाई 6-12 घंटे', 'th': 'ทางอากาศระหว่างประเทศ 6-12 ชั่วโมง',
  });

  String get etaIntlAirLong => _t({
    'ko': '국제 항공 12~24시간', 'en': 'Intl. air 12-24 hours', 'ja': '国際航空 12〜24時間', 'zh': '国际航空 12-24小时',
    'fr': 'Aérien intl. 12 à 24 heures', 'de': 'Intl. Luftpost 12–24 Stunden', 'es': 'Aéreo intl. 12-24 horas',
    'pt': 'Aéreo intl. 12-24 horas', 'ru': 'Междунар. авиа 12–24 часа', 'tr': 'Uluslararası hava 12-24 saat',
    'ar': 'جوي دولي 12-24 ساعة', 'it': 'Aereo intl. 12-24 ore', 'hi': 'अंतर्राष्ट्रीय हवाई 12-24 घंटे', 'th': 'ทางอากาศระหว่างประเทศ 12-24 ชั่วโมง',
  });

  String get etaIntlSea => _t({
    'ko': '해상 운송 2~5일', 'en': 'Sea shipping 2-5 days', 'ja': '海上輸送 2〜5日', 'zh': '海运 2-5天',
    'fr': 'Transport maritime 2 à 5 jours', 'de': 'Seeweg 2–5 Tage', 'es': 'Marítimo 2-5 días',
    'pt': 'Marítimo 2-5 dias', 'ru': 'Морская доставка 2–5 дней', 'tr': 'Deniz yolu 2-5 gün',
    'ar': 'شحن بحري 2-5 أيام', 'it': 'Via mare 2-5 giorni', 'hi': 'समुद्री शिपिंग 2-5 दिन', 'th': 'ทางเรือ 2-5 วัน',
  });

  // ── Transport ───────────────────────────────────────────────────────────

  String get transportLand => _t({
    'ko': '육로', 'en': 'Land', 'ja': '陸路', 'zh': '陆路',
    'fr': 'Terrestre', 'de': 'Landweg', 'es': 'Terrestre',
    'pt': 'Terrestre', 'ru': 'Наземный', 'tr': 'Kara',
    'ar': 'بري', 'it': 'Terrestre', 'hi': 'स्थलमार्ग', 'th': 'ทางบก',
  });

  String get transportAir => _t({
    'ko': '항공', 'en': 'Air', 'ja': '航空', 'zh': '航空',
    'fr': 'Aérien', 'de': 'Luftweg', 'es': 'Aéreo',
    'pt': 'Aéreo', 'ru': 'Воздушный', 'tr': 'Hava',
    'ar': 'جوي', 'it': 'Aereo', 'hi': 'हवाई', 'th': 'ทางอากาศ',
  });

  String get transportSea => _t({
    'ko': '해상', 'en': 'Sea', 'ja': '海上', 'zh': '海运',
    'fr': 'Maritime', 'de': 'Seeweg', 'es': 'Marítimo',
    'pt': 'Marítimo', 'ru': 'Морской', 'tr': 'Deniz',
    'ar': 'بحري', 'it': 'Marittimo', 'hi': 'समुद्री', 'th': 'ทางทะเล',
  });

  // ── Delivery Intro ──────────────────────────────────────────────────────

  String get deliveryIntroTitle => _t({
    'ko': '혜택이 배송을 시작했어요 🚚✈️🚢',
    'en': 'Your reward is now in transit 🚚✈️🚢',
    'ja': 'お手紙の配送が始まりました 🚚✈️🚢',
    'zh': '您的信件已开始运送 🚚✈️🚢',
    'fr': 'Votre lettre est en acheminement 🚚✈️🚢',
    'de': 'Ihr Brief ist nun im Versand 🚚✈️🚢',
    'es': 'Tu carta está ahora en tránsito 🚚✈️🚢',
    'pt': 'Sua carta está em trânsito 🚚✈️🚢',
    'ru': 'Ваше письмо в пути 🚚✈️🚢',
    'tr': 'Mektubunuz şimdi yolda 🚚✈️🚢',
    'ar': 'رسالتك الآن في الطريق 🚚✈️🚢',
    'it': 'La tua lettera è in consegna 🚚✈️🚢',
    'hi': 'आपका पत्र रास्ते में है 🚚✈️🚢',
    'th': 'จดหมายของคุณกำลังถูกจัดส่ง 🚚✈️🚢',
  });

  String get deliveryIntroSubtitle => _t({
    'ko': '육로, 항공, 해운으로 목적지를 향해 천천히 이동합니다',
    'en': 'Travelling slowly by land, air, and sea toward its destination',
    'ja': '陸路、空路、海路でゆっくりと目的地へ向かいます',
    'zh': '通过陆路、航空和海运缓缓抵达目的地',
    'fr': 'Voyage lent par la terre, les airs et la mer vers sa destination',
    'de': 'Reist langsam über Land, Luft und See zum Zielort',
    'es': 'Viajando lentamente por tierra, aire y mar hasta su destino',
    'pt': 'Viajando lentamente por terra, ar e mar até o destino',
    'ru': 'Медленно путешествует по суше, воздуху и морю к месту назначения',
    'tr': 'Karadan, havadan ve denizden yavaşça hedefine doğru ilerliyor',
    'ar': 'تسافر ببطء برًا وجوًا وبحرًا إلى وجهتها',
    'it': 'Viaggia lentamente via terra, aria e mare verso la sua destinazione',
    'hi': 'ज़मीन, हवा और समुद्र से धीरे-धीरे अपने गंतव्य की ओर',
    'th': 'เดินทางช้าๆ ทางบก ทางอากาศ และทางทะเล สู่ปลายทาง',
  });

  /// 앱의 핵심 포지셔닝 태그라인. 온보딩·공유 카드·마케팅에 사용.
  String get appTagline => _t({
    'ko': '혜택은 천천히 여행합니다 — 육로, 항공, 해운으로',
    'en': 'Rewards travel at their own pace — by land, air, and sea',
    'ja': 'お手紙はゆっくり旅をする — 陸路、空路、海路で',
    'zh': '信件按自己的节奏旅行 — 经陆、空、海',
    'fr': 'Les lettres voyagent à leur rythme — par terre, air et mer',
    'de': 'Briefe reisen im eigenen Tempo — über Land, Luft und See',
    'es': 'Las cartas viajan a su propio ritmo — por tierra, aire y mar',
    'pt': 'As cartas viajam no seu próprio ritmo — por terra, ar e mar',
    'ru': 'Письма путешествуют в своём ритме — по суше, воздуху и морю',
    'tr': 'Mektuplar kendi hızında yolculuk eder — karadan, havadan, denizden',
    'ar': 'تسافر الرسائل بإيقاعها الخاص — برًا وجوًا وبحرًا',
    'it': 'Le lettere viaggiano con il proprio ritmo — per terra, aria e mare',
    'hi': 'पत्र अपनी गति से चलते हैं — ज़मीन, हवा और समुद्र से',
    'th': 'จดหมายเดินทางในจังหวะของตัวเอง — ทางบก ทางอากาศ ทางทะเล',
  });

  /// 앱의 핵심 가치 한 줄 — Build 114 에서 "느린 소셜" 에서
  /// "지도 위 할인·홍보 혜택 헌트" 로 전환. 마케팅 기획서 Build 113 의
  /// 포지셔닝과 완전 일치.
  // Build 170: 보조 태그라인 — 포지셔닝 풀 (편지 형식의 글로벌 공간 쿠폰 플랫폼).
  // 스플래시에서 메인 tagline 아래 노출. 감성 + 실용 동시 강조.
  String get appSubTagline => _t({
    'ko': '혜택을 줍는 글로벌 공간 쿠폰 플랫폼',
    'en': 'The global space-based coupon platform — pick rewards near you',
    'ja': '手紙フォーマットのグローバル空間クーポンプラットフォーム',
    'zh': '以信件形式的全球空间优惠券平台',
    'fr': 'Plateforme mondiale de coupons spatiaux au format lettre',
    'de': 'Globale Coupon-Plattform im Briefformat',
    'es': 'Plataforma global de cupones espaciales en formato carta',
    'pt': 'Plataforma global de cupões espaciais em formato carta',
    'ru': 'Глобальная платформа купонов в формате писем',
    'tr': 'Mektup formatında küresel konum tabanlı kupon platformu',
    'ar': 'منصة القسائم المكانية العالمية بصيغة رسائل',
    'it': 'Piattaforma globale di coupon spaziali in formato lettera',
    'hi': 'पत्र फ़ॉर्मेट का वैश्विक स्थान-आधारित कूपन प्लेटफ़ॉर्म',
    'th': 'แพลตฟอร์มคูปองเชิงพื้นที่ระดับโลกในรูปแบบจดหมาย',
  });

  // ── v5 splash / brand ad (Build 203) ──────────────────────────────────

  /// 스플래시 sub-tagline — 메인 wordmark 아래 한 줄 설명.
  String get splashSub => _t({
    'ko': '근처에 떠있는 쿠폰과 혜택을\n주워 쓰는 지갑.',
    'en': 'Pick up nearby coupons and rewards\nright into your wallet.',
    'ja': '近くに浮かぶクーポンと手紙を\n拾って使う財布。',
    'zh': '附近的优惠券和信件\n捡起来,放进钱包。',
    'fr': 'Une cartera para coger les coupons\net les lettres autour de toi.',
    'de': 'Coupons und Briefe aus deiner Nähe\ndirekt in dein Wallet.',
    'es': 'Una cartera para recoger\ncupones y cartas a tu alrededor.',
    'pt': 'Uma carteira para recolher\ncupões e cartas à tua volta.',
    'ru': 'Кошелёк, чтобы собирать\nкупоны и письма рядом с тобой.',
    'tr': 'Yakındaki kuponları ve mektupları\ncüzdanına alıp kullan.',
    'ar': 'محفظة لالتقاط القسائم\nوالرسائل القريبة منك.',
    'it': 'Un portafoglio per raccogliere\ncoupon e lettere intorno a te.',
    'hi': 'आपके पास के कूपन और पत्र\nउठाकर इस्तेमाल करने वाला वॉलेट।',
    'th': 'กระเป๋าเก็บคูปองและจดหมาย\nที่ลอยอยู่ใกล้คุณ',
  });

  /// 브랜드 광고 모달 "혜택 받기" CTA.
  String get brandAdPickup => _t({
    'ko': '혜택 받기',
    'en': 'Pick up reward',
    'ja': '手紙を受け取る',
    'zh': '领取信件',
    'fr': 'Recevoir la lettre',
    'de': 'Brief annehmen',
    'es': 'Recoger carta',
    'pt': 'Receber carta',
    'ru': 'Получить письмо',
    'tr': 'Mektubu al',
    'ar': 'استلام الرسالة',
    'it': 'Ricevi lettera',
    'hi': 'पत्र प्राप्त करें',
    'th': 'รับจดหมาย',
  });

  /// 브랜드 광고 모달 "닫기" CTA.
  String get brandAdClose => _t({
    'ko': '닫기',
    'en': 'Close',
    'ja': '閉じる',
    'zh': '关闭',
    'fr': 'Fermer',
    'de': 'Schließen',
    'es': 'Cerrar',
    'pt': 'Fechar',
    'ru': 'Закрыть',
    'tr': 'Kapat',
    'ar': 'إغلاق',
    'it': 'Chiudi',
    'hi': 'बंद करें',
    'th': 'ปิด',
  });

  // ── Hardcoded string l10n (formerly hardcoded) ─────────────────────────

  String get labelThiscountPremium => _t({
    'ko': 'THISCOUNT PREMIUM', 'en': 'THISCOUNT PREMIUM', 'ja': 'THISCOUNT PREMIUM', 'zh': 'THISCOUNT PREMIUM',
    'fr': 'THISCOUNT PREMIUM', 'de': 'THISCOUNT PREMIUM', 'es': 'THISCOUNT PREMIUM',
    'pt': 'THISCOUNT PREMIUM', 'ru': 'THISCOUNT PREMIUM', 'tr': 'THISCOUNT PREMIUM',
    'ar': 'THISCOUNT PREMIUM', 'it': 'THISCOUNT PREMIUM', 'hi': 'THISCOUNT PREMIUM', 'th': 'THISCOUNT PREMIUM',
  });

  String get tierFree => _t({
    'ko': 'FREE', 'en': 'FREE', 'ja': '無料', 'zh': '免费',
    'fr': 'GRATUIT', 'de': 'KOSTENLOS', 'es': 'GRATIS',
    'pt': 'GRÁTIS', 'ru': 'БЕСПЛАТНО', 'tr': 'ÜCRETSİZ',
    'ar': 'مجاني', 'it': 'GRATIS', 'hi': 'मुफ़्त', 'th': 'ฟรี',
  });

  String get tierPremium => _t({
    'ko': 'PREMIUM', 'en': 'PREMIUM', 'ja': 'プレミアム', 'zh': '高级版',
    'fr': 'PREMIUM', 'de': 'PREMIUM', 'es': 'PREMIUM',
    'pt': 'PREMIUM', 'ru': 'ПРЕМИУМ', 'tr': 'PREMİUM',
    'ar': 'مميز', 'it': 'PREMIUM', 'hi': 'प्रीमियम', 'th': 'พรีเมียม',
  });

  String get tierBest => _t({
    'ko': 'BEST', 'en': 'BEST', 'ja': 'おすすめ', 'zh': '最佳',
    'fr': 'MEILLEUR', 'de': 'BESTE', 'es': 'MEJOR',
    'pt': 'MELHOR', 'ru': 'ЛУЧШИЙ', 'tr': 'EN İYİ',
    'ar': 'الأفضل', 'it': 'MIGLIORE', 'hi': 'सर्वश्रेष्ठ', 'th': 'ดีที่สุด',
  });

  String get labelStampAlbum => _t({
    'ko': '스탬프 앨범', 'en': 'STAMP ALBUM', 'ja': 'スタンプアルバム', 'zh': '邮票册',
    'fr': 'ALBUM DE TIMBRES', 'de': 'STEMPELALBUM', 'es': 'ÁLBUM DE SELLOS',
    'pt': 'ÁLBUM DE SELOS', 'ru': 'АЛЬБОМ МАРОК', 'tr': 'PUL ALBÜmü',
    'ar': 'ألبوم الطوابع', 'it': 'ALBUM DI FRANCOBOLLI', 'hi': 'स्टाम्प एल्बम', 'th': 'อัลบั้มแสตมป์',
  });

  String get labelReputationScore => _t({
    'ko': '평판 점수', 'en': 'REPUTATION SCORE', 'ja': '評価スコア', 'zh': '声望分数',
    'fr': 'SCORE DE RÉPUTATION', 'de': 'REPUTATIONSPUNKTE', 'es': 'PUNTUACIÓN',
    'pt': 'PONTUAÇÃO', 'ru': 'РЕЙТИНГ', 'tr': 'İTİBAR PUANI',
    'ar': 'نقاط السمعة', 'it': 'PUNTEGGIO', 'hi': 'प्रतिष्ठा स्कोर', 'th': 'คะแนนชื่อเสียง',
  });

  String get unitPts => _t({
    'ko': 'pts', 'en': 'pts', 'ja': 'pt', 'zh': '分',
    'fr': 'pts', 'de': 'Pkt', 'es': 'pts',
    'pt': 'pts', 'ru': 'очк', 'tr': 'puan',
    'ar': 'نقطة', 'it': 'pts', 'hi': 'अंक', 'th': 'คะแนน',
  });

  String get labelPassport => _t({
    'ko': '여권', 'en': 'PASSPORT', 'ja': 'パスポート', 'zh': '护照',
    'fr': 'PASSEPORT', 'de': 'REISEPASS', 'es': 'PASAPORTE',
    'pt': 'PASSAPORTE', 'ru': 'ПАСПОРТ', 'tr': 'PASAPORT',
    'ar': 'جواز سفر', 'it': 'PASSAPORTO', 'hi': 'पासपोर्ट', 'th': 'หนังสือเดินทาง',
  });

  String get inboxSubtitle => _t({
    'ko': '바다 건너 속삭임', 'en': 'WHISPERS FROM ACROSS THE TIDES', 'ja': '海を越えたささやき', 'zh': '跨越潮汐的耳语',
    'fr': 'MURMURES D\'OUTRE-MER', 'de': 'FLÜSTERN VON JENSEITS DER GEZEITEN', 'es': 'SUSURROS DEL OTRO LADO',
    'pt': 'SUSSURROS DO ALÉM-MAR', 'ru': 'ШЁПОТ ИЗДАЛЕКА', 'tr': 'DENİZLER ÖTESİNDEN FISILDAMALAR',
    'ar': 'همسات عبر المد', 'it': 'SUSSURRI D\'OLTREMARE', 'hi': 'समुद्र पार की फुसफुसाहट', 'th': 'เสียงกระซิบจากอีกฝั่ง',
  });

  String get labelBrand => _t({
    'ko': '브랜드', 'en': 'BRAND', 'ja': 'ブランド', 'zh': '品牌',
    'fr': 'MARQUE', 'de': 'MARKE', 'es': 'MARCA',
    'pt': 'MARCA', 'ru': 'БРЕНД', 'tr': 'MARKA',
    'ar': 'علامة تجارية', 'it': 'BRAND', 'hi': 'ब्रांड', 'th': 'แบรนด์',
  });

  String get labelBrandLetter => _t({
    'ko': '브랜드 레터', 'en': 'BRAND LETTER', 'ja': 'ブランドレター', 'zh': '品牌信件',
    'fr': 'LETTRE DE MARQUE', 'de': 'MARKENBRIEF', 'es': 'CARTA DE MARCA',
    'pt': 'CARTA DA MARCA', 'ru': 'ПИСЬМО БРЕНДА', 'tr': 'MARKA MEKTUP',
    'ar': 'رسالة العلامة التجارية', 'it': 'LETTERA BRAND', 'hi': 'ब्रांड पत्र', 'th': 'จดหมายแบรนด์',
  });

  String get labelAdmin => _t({
    'ko': 'ADMIN', 'en': 'ADMIN', 'ja': '管理者', 'zh': '管理员',
    'fr': 'ADMIN', 'de': 'ADMIN', 'es': 'ADMIN',
    'pt': 'ADMIN', 'ru': 'АДМИН', 'tr': 'YÖNETİCİ',
    'ar': 'المسؤول', 'it': 'ADMIN', 'hi': 'व्यवस्थापक', 'th': 'ผู้ดูแล',
  });

  String get labelGlobalFlow => _t({
    'ko': '글로벌 흐름', 'en': 'GLOBAL FLOW', 'ja': 'グローバルフロー', 'zh': '全球流量',
    'fr': 'FLUX GLOBAL', 'de': 'GLOBALER FLUSS', 'es': 'FLUJO GLOBAL',
    'pt': 'FLUXO GLOBAL', 'ru': 'ГЛОБАЛЬНЫЙ ПОТОК', 'tr': 'KÜRESEL AKIŞ',
    'ar': 'التدفق العالمي', 'it': 'FLUSSO GLOBALE', 'hi': 'वैश्विक प्रवाह', 'th': 'กระแสโลก',
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ── Terms of Service & Content Moderation Consent (Auth) ─────────────────
  // ══════════════════════════════════════════════════════════════════════════

  String get authTermsRequired => _t({
    'ko': '(필수) 서비스 이용약관 및 커뮤니티 가이드라인',
    'en': '(Required) Terms of Service & Community Guidelines',
    'ja': '（必須）利用規約とコミュニティガイドライン',
    'zh': '（必填）服务条款和社区准则',
    'fr': '(Obligatoire) Conditions d\'utilisation et règles communautaires',
    'de': '(Erforderlich) Nutzungsbedingungen und Community-Richtlinien',
    'es': '(Obligatorio) Términos de servicio y normas de la comunidad',
    'pt': '(Obrigatório) Termos de Serviço e Diretrizes da Comunidade',
    'ru': '(Обязательно) Условия использования и правила сообщества',
    'tr': '(Zorunlu) Kullanım Koşulları ve Topluluk Kuralları',
    'ar': '(مطلوب) شروط الخدمة وإرشادات المجتمع',
    'it': '(Obbligatorio) Termini di servizio e linee guida della comunità',
    'hi': '(आवश्यक) सेवा की शर्तें और सामुदायिक दिशानिर्देश',
    'th': '(จำเป็น) ข้อกำหนดการใช้งานและแนวทางชุมชน',
  });

  String get authTermsDesc => _t({
    'ko': '혜택 내용은 신고 접수 시에만 관리자가 검토할 수 있습니다.\n부적절한 콘텐츠 게시 시 서비스 이용이 제한될 수 있습니다.',
    'en': 'Reward content may only be reviewed by administrators upon receiving a report.\nPosting inappropriate content may result in service restrictions.',
    'ja': '手紙の内容は、報告を受けた場合にのみ管理者が確認できます。\n不適切なコンテンツの投稿はサービス制限の対象となります。',
    'zh': '信件内容仅在收到举报时由管理员审查。\n发布不当内容可能导致服务限制。',
    'fr': 'Le contenu des lettres ne peut être examiné par les administrateurs que sur signalement.\nLa publication de contenu inapproprié peut entraîner des restrictions de service.',
    'de': 'Briefinhalte werden nur bei einer Meldung von Administratoren überprüft.\nDas Veröffentlichen unangemessener Inhalte kann zu Diensteinschränkungen führen.',
    'es': 'El contenido de las cartas solo puede ser revisado por administradores al recibir un reporte.\nPublicar contenido inapropiado puede resultar en restricciones del servicio.',
    'pt': 'O conteúdo das cartas só pode ser revisado por administradores mediante denúncia.\nA publicação de conteúdo inadequado pode resultar em restrições de serviço.',
    'ru': 'Содержание писем проверяется администраторами только при получении жалобы.\nПубликация неприемлемого контента может привести к ограничению сервиса.',
    'tr': 'Mektup içeriği yalnızca şikayet alındığında yöneticiler tarafından incelenebilir.\nUygunsuz içerik yayınlamak hizmet kısıtlamalarına yol açabilir.',
    'ar': 'يمكن مراجعة محتوى الرسائل من قبل المسؤولين فقط عند تلقي بلاغ.\nنشر محتوى غير لائق قد يؤدي إلى تقييد الخدمة.',
    'it': 'Il contenuto delle lettere può essere esaminato dagli amministratori solo in caso di segnalazione.\nLa pubblicazione di contenuti inappropriati può comportare restrizioni del servizio.',
    'hi': 'पत्र सामग्री की समीक्षा प्रशासकों द्वारा केवल शिकायत प्राप्त होने पर की जा सकती है।\nअनुचित सामग्री पोस्ट करने पर सेवा प्रतिबंध हो सकते हैं।',
    'th': 'เนื้อหาจดหมายจะถูกตรวจสอบโดยผู้ดูแลเฉพาะเมื่อได้รับการรายงานเท่านั้น\nการโพสต์เนื้อหาที่ไม่เหมาะสมอาจส่งผลให้ถูกจำกัดการใช้บริการ',
  });

  // ── Privacy Policy expanded sections (5-7) ──────────────────────────────

  String get authPrivacySec5Title => _t({
    'ko': '5. 콘텐츠 열람 및 관리',
    'en': '5. Content Review & Moderation',
    'ja': '5. コンテンツの閲覧と管理',
    'zh': '5. 内容审查与管理',
    'fr': '5. Examen et modération du contenu',
    'de': '5. Inhaltsüberprüfung und Moderation',
    'es': '5. Revisión y moderación de contenido',
    'pt': '5. Revisão e Moderação de Conteúdo',
    'ru': '5. Проверка и модерация контента',
    'tr': '5. İçerik İnceleme ve Denetim',
    'ar': '5. مراجعة المحتوى والإشراف',
    'it': '5. Revisione e moderazione dei contenuti',
    'hi': '5. सामग्री समीक्षा और मॉडरेशन',
    'th': '5. การตรวจสอบและจัดการเนื้อหา',
  });

  String get authPrivacySec5Body => _t({
    'ko': '관리자는 사용자의 혜택 내용을 일상적으로 열람하지 않습니다. '
        '혜택 내용은 다른 사용자로부터 신고가 접수된 경우에 한하여 검토됩니다. '
        '검토는 커뮤니티 가이드라인 위반 여부를 판단하기 위한 목적으로만 수행되며, '
        '위반이 확인되면 해당 콘텐츠의 차단 및 계정 제한 조치가 이루어질 수 있습니다.',
    'en': 'Administrators do not routinely access your reward content. '
        'Rewards are reviewed only when a report is filed by another user. '
        'Reviews are conducted solely to determine violations of community guidelines. '
        'If a violation is confirmed, content may be blocked and account restrictions may apply.',
    'ja': '管理者は日常的にあなたの手紙の内容を閲覧しません。'
        '手紙の内容は、他のユーザーから報告があった場合にのみ確認されます。'
        '確認はコミュニティガイドライン違反の判断のためにのみ行われ、'
        '違反が確認された場合、コンテンツのブロックやアカウント制限が行われることがあります。',
    'zh': '管理员不会日常访问您的信件内容。'
        '仅在其他用户提交举报时才会审查信件。'
        '审查仅用于判断是否违反社区准则。'
        '如确认违规，相关内容可能被屏蔽，账号可能受到限制。',
    'fr': 'Les administrateurs n\'accèdent pas régulièrement au contenu de vos lettres. '
        'Les lettres ne sont examinées que lorsqu\'un signalement est déposé par un autre utilisateur. '
        'Les examens sont effectués uniquement pour déterminer les violations des règles communautaires. '
        'Si une violation est confirmée, le contenu peut être bloqué et des restrictions de compte peuvent s\'appliquer.',
    'de': 'Administratoren greifen nicht routinemäßig auf Ihre Briefinhalte zu. '
        'Briefe werden nur überprüft, wenn eine Meldung von einem anderen Benutzer eingeht. '
        'Überprüfungen dienen ausschließlich der Feststellung von Verstößen gegen Community-Richtlinien. '
        'Bei bestätigten Verstößen können Inhalte gesperrt und Kontoeinschränkungen verhängt werden.',
    'es': 'Los administradores no acceden rutinariamente al contenido de sus cartas. '
        'Las cartas se revisan solo cuando otro usuario presenta un reporte. '
        'Las revisiones se realizan únicamente para determinar violaciones de las normas de la comunidad. '
        'Si se confirma una violación, el contenido puede ser bloqueado y se pueden aplicar restricciones de cuenta.',
    'pt': 'Os administradores não acessam rotineiramente o conteúdo de suas cartas. '
        'As cartas são revisadas apenas quando uma denúncia é feita por outro usuário. '
        'As revisões são realizadas exclusivamente para determinar violações das diretrizes da comunidade. '
        'Se uma violação for confirmada, o conteúdo pode ser bloqueado e restrições de conta podem ser aplicadas.',
    'ru': 'Администраторы не просматривают содержание ваших писем на регулярной основе. '
        'Письма проверяются только при поступлении жалобы от другого пользователя. '
        'Проверки проводятся исключительно для выявления нарушений правил сообщества. '
        'При подтверждении нарушения контент может быть заблокирован, а на аккаунт наложены ограничения.',
    'tr': 'Yöneticiler mektup içeriğinize rutin olarak erişmez. '
        'Mektuplar yalnızca başka bir kullanıcı tarafından şikayet edildiğinde incelenir. '
        'İncelemeler yalnızca topluluk kurallarının ihlal edilip edilmediğini belirlemek için yapılır. '
        'İhlal tespit edilirse içerik engellenebilir ve hesap kısıtlamaları uygulanabilir.',
    'ar': 'لا يصل المسؤولون بشكل روتيني إلى محتوى رسائلك. '
        'تتم مراجعة الرسائل فقط عند تقديم بلاغ من مستخدم آخر. '
        'تُجرى المراجعات فقط لتحديد انتهاكات إرشادات المجتمع. '
        'إذا تم تأكيد الانتهاك، قد يتم حظر المحتوى وتطبيق قيود على الحساب.',
    'it': 'Gli amministratori non accedono regolarmente al contenuto delle tue lettere. '
        'Le lettere vengono esaminate solo quando viene presentata una segnalazione da un altro utente. '
        'Le revisioni vengono effettuate esclusivamente per determinare violazioni delle linee guida della comunità. '
        'Se viene confermata una violazione, il contenuto può essere bloccato e possono essere applicate restrizioni all\'account.',
    'hi': 'प्रशासक आपके पत्र सामग्री को नियमित रूप से नहीं देखते। '
        'पत्रों की समीक्षा केवल तब की जाती है जब किसी अन्य उपयोगकर्ता द्वारा शिकायत दर्ज की जाती है। '
        'समीक्षा केवल सामुदायिक दिशानिर्देशों के उल्लंघन का पता लगाने के लिए की जाती है। '
        'यदि उल्लंघन की पुष्टि होती है, तो सामग्री को अवरुद्ध किया जा सकता है और खाता प्रतिबंध लागू हो सकते हैं।',
    'th': 'ผู้ดูแลระบบไม่เข้าถึงเนื้อหาจดหมายของคุณเป็นประจำ '
        'จดหมายจะถูกตรวจสอบเฉพาะเมื่อมีการรายงานจากผู้ใช้รายอื่นเท่านั้น '
        'การตรวจสอบดำเนินการเพื่อตรวจสอบการละเมิดแนวทางชุมชนเท่านั้น '
        'หากยืนยันการละเมิด เนื้อหาอาจถูกบล็อกและอาจมีการจำกัดบัญชี',
  });

  String get authPrivacySec6Title => _t({
    'ko': '6. 이용자 권리 (GDPR/개인정보 보호법)',
    'en': '6. Your Rights (GDPR / Data Protection)',
    'ja': '6. ユーザーの権利（GDPR/データ保護）',
    'zh': '6. 您的权利（GDPR/数据保护）',
    'fr': '6. Vos droits (RGPD / Protection des données)',
    'de': '6. Ihre Rechte (DSGVO / Datenschutz)',
    'es': '6. Sus derechos (RGPD / Protección de datos)',
    'pt': '6. Seus Direitos (LGPD / Proteção de Dados)',
    'ru': '6. Ваши права (GDPR / Защита данных)',
    'tr': '6. Haklarınız (KVKK / Veri Koruma)',
    'ar': '6. حقوقك (GDPR / حماية البيانات)',
    'it': '6. I tuoi diritti (GDPR / Protezione dati)',
    'hi': '6. आपके अधिकार (GDPR / डेटा संरक्षण)',
    'th': '6. สิทธิ์ของคุณ (GDPR / การคุ้มครองข้อมูล)',
  });

  String get authPrivacySec6Body => _t({
    'ko': '• 열람권: 수집된 개인정보 열람을 요청할 수 있습니다\n'
        '• 정정권: 부정확한 정보의 수정을 요청할 수 있습니다\n'
        '• 삭제권: 계정 삭제 시 모든 데이터가 즉시 삭제됩니다\n'
        '• 이동권: 본인의 데이터 사본을 요청할 수 있습니다\n'
        '• 철회권: 동의를 언제든 철회할 수 있습니다\n'
        '문의: ceo@airony.xyz',
    'en': '• Right to Access: You may request access to your personal data\n'
        '• Right to Rectification: You may request correction of inaccurate data\n'
        '• Right to Erasure: All data is deleted immediately upon account deletion\n'
        '• Right to Portability: You may request a copy of your data\n'
        '• Right to Withdraw Consent: You may withdraw consent at any time\n'
        'Contact: ceo@airony.xyz',
    'ja': '• アクセス権: 収集された個人情報の閲覧を要求できます\n'
        '• 訂正権: 不正確な情報の修正を要求できます\n'
        '• 削除権: アカウント削除時にすべてのデータが即座に削除されます\n'
        '• データポータビリティ権: データのコピーを要求できます\n'
        '• 同意撤回権: いつでも同意を撤回できます\n'
        'お問い合わせ: ceo@airony.xyz',
    'zh': '• 访问权: 您可以请求访问收集的个人信息\n'
        '• 更正权: 您可以请求更正不准确的信息\n'
        '• 删除权: 删除账号时所有数据将立即删除\n'
        '• 可携带权: 您可以请求数据副本\n'
        '• 撤回同意权: 您可以随时撤回同意\n'
        '联系方式: ceo@airony.xyz',
    'fr': '• Droit d\'accès : Vous pouvez demander l\'accès à vos données personnelles\n'
        '• Droit de rectification : Vous pouvez demander la correction des données inexactes\n'
        '• Droit à l\'effacement : Toutes les données sont supprimées lors de la suppression du compte\n'
        '• Droit à la portabilité : Vous pouvez demander une copie de vos données\n'
        '• Droit de retrait : Vous pouvez retirer votre consentement à tout moment\n'
        'Contact : ceo@airony.xyz',
    'de': '• Auskunftsrecht: Sie können Zugang zu Ihren personenbezogenen Daten anfordern\n'
        '• Berichtigungsrecht: Sie können die Korrektur ungenauer Daten anfordern\n'
        '• Löschungsrecht: Alle Daten werden bei Kontolöschung sofort gelöscht\n'
        '• Recht auf Datenübertragbarkeit: Sie können eine Kopie Ihrer Daten anfordern\n'
        '• Widerrufsrecht: Sie können Ihre Einwilligung jederzeit widerrufen\n'
        'Kontakt: ceo@airony.xyz',
    'es': '• Derecho de acceso: Puede solicitar acceso a sus datos personales\n'
        '• Derecho de rectificación: Puede solicitar la corrección de datos inexactos\n'
        '• Derecho de supresión: Todos los datos se eliminan al eliminar la cuenta\n'
        '• Derecho de portabilidad: Puede solicitar una copia de sus datos\n'
        '• Derecho de revocación: Puede retirar su consentimiento en cualquier momento\n'
        'Contacto: ceo@airony.xyz',
    'pt': '• Direito de acesso: Você pode solicitar acesso aos seus dados pessoais\n'
        '• Direito de retificação: Você pode solicitar a correção de dados imprecisos\n'
        '• Direito de exclusão: Todos os dados são excluídos ao deletar a conta\n'
        '• Direito de portabilidade: Você pode solicitar uma cópia dos seus dados\n'
        '• Direito de revogação: Você pode retirar seu consentimento a qualquer momento\n'
        'Contato: ceo@airony.xyz',
    'ru': '• Право на доступ: Вы можете запросить доступ к своим персональным данным\n'
        '• Право на исправление: Вы можете запросить исправление неточных данных\n'
        '• Право на удаление: Все данные удаляются при удалении аккаунта\n'
        '• Право на переносимость: Вы можете запросить копию своих данных\n'
        '• Право на отзыв: Вы можете отозвать согласие в любое время\n'
        'Контакт: ceo@airony.xyz',
    'tr': '• Erişim hakkı: Kişisel verilerinize erişim talep edebilirsiniz\n'
        '• Düzeltme hakkı: Yanlış verilerin düzeltilmesini talep edebilirsiniz\n'
        '• Silme hakkı: Hesap silindiğinde tüm veriler hemen silinir\n'
        '• Taşınabilirlik hakkı: Verilerinizin bir kopyasını talep edebilirsiniz\n'
        '• Geri çekme hakkı: Onayınızı istediğiniz zaman geri çekebilirsiniz\n'
        'İletişim: ceo@airony.xyz',
    'ar': '• حق الوصول: يمكنك طلب الوصول إلى بياناتك الشخصية\n'
        '• حق التصحيح: يمكنك طلب تصحيح البيانات غير الدقيقة\n'
        '• حق الحذف: يتم حذف جميع البيانات فور حذف الحساب\n'
        '• حق النقل: يمكنك طلب نسخة من بياناتك\n'
        '• حق السحب: يمكنك سحب موافقتك في أي وقت\n'
        'التواصل: ceo@airony.xyz',
    'it': '• Diritto di accesso: Puoi richiedere l\'accesso ai tuoi dati personali\n'
        '• Diritto di rettifica: Puoi richiedere la correzione di dati inesatti\n'
        '• Diritto alla cancellazione: Tutti i dati vengono eliminati alla cancellazione dell\'account\n'
        '• Diritto alla portabilità: Puoi richiedere una copia dei tuoi dati\n'
        '• Diritto di revoca: Puoi revocare il consenso in qualsiasi momento\n'
        'Contatto: ceo@airony.xyz',
    'hi': '• पहुँच का अधिकार: आप अपने व्यक्तिगत डेटा तक पहुँच का अनुरोध कर सकते हैं\n'
        '• सुधार का अधिकार: आप गलत डेटा में सुधार का अनुरोध कर सकते हैं\n'
        '• मिटाने का अधिकार: खाता हटाने पर सभी डेटा तुरंत हटा दिया जाता है\n'
        '• पोर्टेबिलिटी का अधिकार: आप अपने डेटा की प्रति का अनुरोध कर सकते हैं\n'
        '• सहमति वापसी का अधिकार: आप किसी भी समय सहमति वापस ले सकते हैं\n'
        'संपर्क: ceo@airony.xyz',
    'th': '• สิทธิ์ในการเข้าถึง: คุณสามารถขอเข้าถึงข้อมูลส่วนบุคคลของคุณ\n'
        '• สิทธิ์ในการแก้ไข: คุณสามารถขอแก้ไขข้อมูลที่ไม่ถูกต้อง\n'
        '• สิทธิ์ในการลบ: ข้อมูลทั้งหมดจะถูกลบเมื่อลบบัญชี\n'
        '• สิทธิ์ในการเคลื่อนย้าย: คุณสามารถขอสำเนาข้อมูลของคุณ\n'
        '• สิทธิ์ในการถอน: คุณสามารถถอนความยินยอมได้ตลอดเวลา\n'
        'ติดต่อ: ceo@airony.xyz',
  });

  String get authPrivacySec7Title => _t({
    'ko': '7. 커뮤니티 가이드라인',
    'en': '7. Community Guidelines',
    'ja': '7. コミュニティガイドライン',
    'zh': '7. 社区准则',
    'fr': '7. Règles communautaires',
    'de': '7. Community-Richtlinien',
    'es': '7. Normas de la comunidad',
    'pt': '7. Diretrizes da Comunidade',
    'ru': '7. Правила сообщества',
    'tr': '7. Topluluk Kuralları',
    'ar': '7. إرشادات المجتمع',
    'it': '7. Linee guida della comunità',
    'hi': '7. सामुदायिक दिशानिर्देश',
    'th': '7. แนวทางชุมชน',
  });

  String get authPrivacySec7Body => _t({
    'ko': '• 혐오 발언, 차별, 괴롭힘 금지\n'
        '• 음란물 또는 폭력적 콘텐츠 금지\n'
        '• 스팸, 사기, 피싱 금지\n'
        '• 타인의 개인정보 무단 공유 금지\n'
        '• 3회 이상 신고 시 자동 차단됩니다',
    'en': '• No hate speech, discrimination, or harassment\n'
        '• No explicit sexual or violent content\n'
        '• No spam, scams, or phishing\n'
        '• Do not share others\' personal information without consent\n'
        '• Accounts with 3+ reports may be automatically blocked',
    'ja': '• ヘイトスピーチ、差別、嫌がらせの禁止\n'
        '• わいせつまたは暴力的なコンテンツの禁止\n'
        '• スパム、詐欺、フィッシングの禁止\n'
        '• 他人の個人情報を無断で共有しないでください\n'
        '• 3回以上の報告で自動ブロックされます',
    'zh': '• 禁止仇恨言论、歧视或骚扰\n'
        '• 禁止色情或暴力内容\n'
        '• 禁止垃圾邮件、欺诈或钓鱼\n'
        '• 不要未经同意分享他人个人信息\n'
        '• 被举报3次以上可能自动封禁',
    'fr': '• Pas de discours haineux, de discrimination ou de harcèlement\n'
        '• Pas de contenu sexuel explicite ou violent\n'
        '• Pas de spam, d\'escroquerie ou de phishing\n'
        '• Ne partagez pas les informations personnelles d\'autrui sans consentement\n'
        '• Les comptes avec 3+ signalements peuvent être automatiquement bloqués',
    'de': '• Keine Hassrede, Diskriminierung oder Belästigung\n'
        '• Keine explizit sexuellen oder gewalttätigen Inhalte\n'
        '• Kein Spam, Betrug oder Phishing\n'
        '• Teilen Sie keine persönlichen Daten anderer ohne Zustimmung\n'
        '• Konten mit 3+ Meldungen können automatisch gesperrt werden',
    'es': '• Prohibido el discurso de odio, discriminación o acoso\n'
        '• Prohibido el contenido sexual explícito o violento\n'
        '• Prohibido el spam, estafas o phishing\n'
        '• No comparta información personal de otros sin consentimiento\n'
        '• Cuentas con 3+ reportes pueden ser bloqueadas automáticamente',
    'pt': '• Proibido discurso de ódio, discriminação ou assédio\n'
        '• Proibido conteúdo sexual explícito ou violento\n'
        '• Proibido spam, fraudes ou phishing\n'
        '• Não compartilhe informações pessoais de outros sem consentimento\n'
        '• Contas com 3+ denúncias podem ser bloqueadas automaticamente',
    'ru': '• Запрещены ненавистнические высказывания, дискриминация или преследование\n'
        '• Запрещён откровенный сексуальный или насильственный контент\n'
        '• Запрещены спам, мошенничество или фишинг\n'
        '• Не делитесь личной информацией других без согласия\n'
        '• Аккаунты с 3+ жалобами могут быть автоматически заблокированы',
    'tr': '• Nefret söylemi, ayrımcılık veya taciz yasaktır\n'
        '• Cinsel veya şiddet içerikli içerik yasaktır\n'
        '• Spam, dolandırıcılık veya kimlik avı yasaktır\n'
        '• Başkalarının kişisel bilgilerini izinsiz paylaşmayın\n'
        '• 3+ şikayet alan hesaplar otomatik olarak engellenebilir',
    'ar': '• يحظر خطاب الكراهية والتمييز والمضايقة\n'
        '• يحظر المحتوى الجنسي الصريح أو العنيف\n'
        '• يحظر البريد العشوائي والاحتيال والتصيد\n'
        '• لا تشارك المعلومات الشخصية للآخرين بدون موافقة\n'
        '• قد يتم حظر الحسابات التي تتلقى 3+ بلاغات تلقائياً',
    'it': '• Vietati discorsi d\'odio, discriminazione o molestie\n'
        '• Vietati contenuti sessuali espliciti o violenti\n'
        '• Vietati spam, truffe o phishing\n'
        '• Non condividere informazioni personali altrui senza consenso\n'
        '• Gli account con 3+ segnalazioni possono essere bloccati automaticamente',
    'hi': '• नफ़रत भरे भाषण, भेदभाव या उत्पीड़न की मनाही\n'
        '• स्पष्ट यौन या हिंसक सामग्री की मनाही\n'
        '• स्पैम, धोखाधड़ी या फ़िशिंग की मनाही\n'
        '• बिना सहमति दूसरों की व्यक्तिगत जानकारी साझा न करें\n'
        '• 3+ शिकायतों वाले खाते स्वचालित रूप से अवरुद्ध हो सकते हैं',
    'th': '• ห้ามพูดจาเกลียดชัง เลือกปฏิบัติ หรือคุกคาม\n'
        '• ห้ามเนื้อหาทางเพศหรือความรุนแรง\n'
        '• ห้ามสแปม การฉ้อโกง หรือฟิชชิ่ง\n'
        '• ห้ามแชร์ข้อมูลส่วนบุคคลของผู้อื่นโดยไม่ได้รับความยินยอม\n'
        '• บัญชีที่ถูกรายงาน 3+ ครั้งอาจถูกบล็อกโดยอัตโนมัติ',
  });

  // ── Settings: Data & Privacy section ────────────────────────────────────

  String get settingsDataPrivacy => _t({
    'ko': '데이터 및 개인정보',
    'en': 'Data & Privacy',
    'ja': 'データとプライバシー',
    'zh': '数据与隐私',
    'fr': 'Données et confidentialité',
    'de': 'Daten & Datenschutz',
    'es': 'Datos y privacidad',
    'pt': 'Dados e Privacidade',
    'ru': 'Данные и конфиденциальность',
    'tr': 'Veri ve Gizlilik',
    'ar': 'البيانات والخصوصية',
    'it': 'Dati e Privacy',
    'hi': 'डेटा और गोपनीयता',
    'th': 'ข้อมูลและความเป็นส่วนตัว',
  });

  String get settingsContentPolicy => _t({
    'ko': '콘텐츠 열람 정책',
    'en': 'Content Review Policy',
    'ja': 'コンテンツ閲覧ポリシー',
    'zh': '内容审查政策',
    'fr': 'Politique d\'examen du contenu',
    'de': 'Inhaltsüberprüfungsrichtlinie',
    'es': 'Política de revisión de contenido',
    'pt': 'Política de Revisão de Conteúdo',
    'ru': 'Политика проверки контента',
    'tr': 'İçerik İnceleme Politikası',
    'ar': 'سياسة مراجعة المحتوى',
    'it': 'Politica di revisione dei contenuti',
    'hi': 'सामग्री समीक्षा नीति',
    'th': 'นโยบายตรวจสอบเนื้อหา',
  });

  String get settingsCommunityGuidelines => _t({
    'ko': '커뮤니티 가이드라인',
    'en': 'Community Guidelines',
    'ja': 'コミュニティガイドライン',
    'zh': '社区准则',
    'fr': 'Règles communautaires',
    'de': 'Community-Richtlinien',
    'es': 'Normas de la comunidad',
    'pt': 'Diretrizes da Comunidade',
    'ru': 'Правила сообщества',
    'tr': 'Topluluk Kuralları',
    'ar': 'إرشادات المجتمع',
    'it': 'Linee guida della comunità',
    'hi': 'सामुदायिक दिशानिर्देश',
    'th': 'แนวทางชุมชน',
  });

  String get settingsRequestData => _t({
    'ko': '내 데이터 요청',
    'en': 'Request My Data',
    'ja': 'データのリクエスト',
    'zh': '请求我的数据',
    'fr': 'Demander mes données',
    'de': 'Meine Daten anfordern',
    'es': 'Solicitar mis datos',
    'pt': 'Solicitar Meus Dados',
    'ru': 'Запросить мои данные',
    'tr': 'Verilerimi talep et',
    'ar': 'طلب بياناتي',
    'it': 'Richiedi i miei dati',
    'hi': 'मेरा डेटा अनुरोध करें',
    'th': 'ขอข้อมูลของฉัน',
  });

  String get settingsRequestDataDesc => _t({
    'ko': 'ceo@airony.xyz로 이메일을 보내 데이터 사본을 요청하세요',
    'en': 'Email ceo@airony.xyz to request a copy of your data',
    'ja': 'ceo@airony.xyzにメールでデータのコピーをリクエストしてください',
    'zh': '发送邮件至ceo@airony.xyz请求数据副本',
    'fr': 'Envoyez un email à ceo@airony.xyz pour demander une copie de vos données',
    'de': 'Senden Sie eine E-Mail an ceo@airony.xyz, um eine Kopie Ihrer Daten anzufordern',
    'es': 'Envíe un correo a ceo@airony.xyz para solicitar una copia de sus datos',
    'pt': 'Envie um email para ceo@airony.xyz para solicitar uma cópia dos seus dados',
    'ru': 'Отправьте email на ceo@airony.xyz для запроса копии ваших данных',
    'tr': 'Verilerinizin bir kopyasını talep etmek için ceo@airony.xyz adresine e-posta gönderin',
    'ar': 'أرسل بريداً إلكترونياً إلى ceo@airony.xyz لطلب نسخة من بياناتك',
    'it': 'Invia un\'email a ceo@airony.xyz per richiedere una copia dei tuoi dati',
    'hi': 'अपने डेटा की प्रति का अनुरोध करने के लिए ceo@airony.xyz पर ईमेल करें',
    'th': 'ส่งอีเมลไปที่ ceo@airony.xyz เพื่อขอสำเนาข้อมูลของคุณ',
  });

  // ── Content Policy Dialog ───────────────────────────────────────────────

  String get contentPolicyTitle => _t({
    'ko': '콘텐츠 열람 정책',
    'en': 'Content Review Policy',
    'ja': 'コンテンツ閲覧ポリシー',
    'zh': '内容审查政策',
    'fr': 'Politique d\'examen du contenu',
    'de': 'Inhaltsüberprüfungsrichtlinie',
    'es': 'Política de revisión de contenido',
    'pt': 'Política de Revisão de Conteúdo',
    'ru': 'Политика проверки контента',
    'tr': 'İçerik İnceleme Politikası',
    'ar': 'سياسة مراجعة المحتوى',
    'it': 'Politica di revisione dei contenuti',
    'hi': 'सामग्री समीक्षा नीति',
    'th': 'นโยบายตรวจสอบเนื้อหา',
  });

  String get contentPolicyBody => _t({
    'ko': 'Thiscount는 사용자의 프라이버시를 존중합니다.\n\n'
        '📋 기본 원칙\n'
        '관리자는 사용자의 혜택 내용을 일상적으로 열람하지 않습니다.\n\n'
        '🔍 열람이 이루어지는 경우\n'
        '• 다른 사용자가 해당 혜택을 신고한 경우\n'
        '• 법적 요청이 있는 경우\n'
        '• 서비스 안전에 중대한 위협이 있는 경우\n\n'
        '⚖️ 열람 절차\n'
        '1. 신고 접수 후 관리자가 해당 혜택만 확인\n'
        '2. 커뮤니티 가이드라인 위반 여부 판단\n'
        '3. 위반 시: 콘텐츠 차단 + 발신자에게 경고\n'
        '4. 3회 이상 위반 시: 계정 영구 차단\n\n'
        '🔒 투명성\n'
        '열람 사유와 조치 결과를 기록하며, 사용자는 자신의 콘텐츠에 대한 조치 사유를 문의할 수 있습니다.',
    'en': 'Thiscount respects your privacy.\n\n'
        '📋 Core Principle\n'
        'Administrators do not routinely access your letter content.\n\n'
        '🔍 When Review Occurs\n'
        '• When another user reports the letter\n'
        '• When required by law\n'
        '• When there is a serious threat to service safety\n\n'
        '⚖️ Review Process\n'
        '1. Upon receiving a report, only the reported letter is reviewed\n'
        '2. Determination of community guidelines violation\n'
        '3. If violation found: content blocked + warning to sender\n'
        '4. 3+ violations: permanent account suspension\n\n'
        '🔒 Transparency\n'
        'Review reasons and outcomes are logged. Users may inquire about actions taken on their content.',
    'ja': 'Thiscountはあなたのプライバシーを尊重します。\n\n'
        '📋 基本原則\n'
        '管理者はあなたの手紙の内容を日常的に閲覧しません。\n\n'
        '🔍 閲覧が行われる場合\n'
        '• 他のユーザーがその手紙を報告した場合\n'
        '• 法的要請がある場合\n'
        '• サービスの安全に重大な脅威がある場合\n\n'
        '⚖️ 閲覧手順\n'
        '1. 報告受理後、該当の手紙のみ確認\n'
        '2. コミュニティガイドライン違反の判断\n'
        '3. 違反の場合：コンテンツブロック＋送信者への警告\n'
        '4. 3回以上の違反：アカウント永久停止\n\n'
        '🔒 透明性\n'
        '閲覧理由と措置結果を記録し、ユーザーは自身のコンテンツに対する措置理由を問い合わせできます。',
    'zh': 'Thiscount 尊重您的隐私。\n\n'
        '📋 核心原则\n'
        '管理员不会日常访问您的信件内容。\n\n'
        '🔍 审查发生的情况\n'
        '• 当其他用户举报该信件时\n'
        '• 当法律要求时\n'
        '• 当服务安全面临严重威胁时\n\n'
        '⚖️ 审查流程\n'
        '1. 收到举报后，仅审查被举报的信件\n'
        '2. 判断是否违反社区准则\n'
        '3. 如确认违规：屏蔽内容 + 警告发件人\n'
        '4. 违规3次以上：永久封禁账号\n\n'
        '🔒 透明度\n'
        '审查原因和结果会被记录，用户可以查询对其内容采取的措施原因。',
    'fr': 'Thiscount respecte votre vie privée.\n\n'
        '📋 Principe fondamental\n'
        'Les administrateurs n\'accèdent pas régulièrement au contenu de vos lettres.\n\n'
        '🔍 Quand un examen a lieu\n'
        '• Lorsqu\'un autre utilisateur signale la lettre\n'
        '• Lorsque la loi l\'exige\n'
        '• Lorsqu\'il y a une menace grave pour la sécurité du service\n\n'
        '⚖️ Processus d\'examen\n'
        '1. Après signalement, seule la lettre signalée est examinée\n'
        '2. Détermination de la violation des règles\n'
        '3. Si violation : contenu bloqué + avertissement\n'
        '4. 3+ violations : suspension permanente du compte\n\n'
        '🔒 Transparence\n'
        'Les raisons et résultats sont enregistrés. Les utilisateurs peuvent demander des explications.',
    'de': 'Thiscount respektiert Ihre Privatsphäre.\n\n'
        '📋 Grundprinzip\n'
        'Administratoren greifen nicht routinemäßig auf Ihre Briefinhalte zu.\n\n'
        '🔍 Wann eine Überprüfung stattfindet\n'
        '• Wenn ein anderer Benutzer den Brief meldet\n'
        '• Wenn gesetzlich vorgeschrieben\n'
        '• Bei ernsthafter Bedrohung der Dienstsicherheit\n\n'
        '⚖️ Überprüfungsprozess\n'
        '1. Nach Meldung wird nur der gemeldete Brief geprüft\n'
        '2. Feststellung eines Richtlinienverstoßes\n'
        '3. Bei Verstoß: Inhalt gesperrt + Warnung\n'
        '4. 3+ Verstöße: dauerhafte Kontosperrung\n\n'
        '🔒 Transparenz\n'
        'Gründe und Ergebnisse werden protokolliert. Benutzer können Erklärungen anfordern.',
    'es': 'Thiscount respeta su privacidad.\n\n'
        '📋 Principio fundamental\n'
        'Los administradores no acceden rutinariamente al contenido de sus cartas.\n\n'
        '🔍 Cuándo se realiza una revisión\n'
        '• Cuando otro usuario reporta la carta\n'
        '• Cuando la ley lo requiere\n'
        '• Cuando hay una amenaza grave para la seguridad del servicio\n\n'
        '⚖️ Proceso de revisión\n'
        '1. Tras un reporte, solo se revisa la carta reportada\n'
        '2. Determinación de violación de normas\n'
        '3. Si hay violación: contenido bloqueado + advertencia\n'
        '4. 3+ violaciones: suspensión permanente\n\n'
        '🔒 Transparencia\n'
        'Las razones y resultados se registran. Los usuarios pueden consultar las acciones tomadas.',
    'pt': 'Thiscount respeita sua privacidade.\n\n'
        '📋 Princípio fundamental\n'
        'Administradores não acessam rotineiramente o conteúdo de suas cartas.\n\n'
        '🔍 Quando ocorre revisão\n'
        '• Quando outro usuário denuncia a carta\n'
        '• Quando exigido por lei\n'
        '• Quando há ameaça grave à segurança do serviço\n\n'
        '⚖️ Processo de revisão\n'
        '1. Após denúncia, apenas a carta denunciada é revisada\n'
        '2. Determinação de violação das diretrizes\n'
        '3. Se violação confirmada: conteúdo bloqueado + aviso\n'
        '4. 3+ violações: suspensão permanente\n\n'
        '🔒 Transparência\n'
        'Razões e resultados são registrados. Usuários podem consultar ações tomadas.',
    'ru': 'Thiscount уважает вашу конфиденциальность.\n\n'
        '📋 Основной принцип\n'
        'Администраторы не просматривают содержание ваших писем на регулярной основе.\n\n'
        '🔍 Когда проводится проверка\n'
        '• Когда другой пользователь подаёт жалобу\n'
        '• Когда этого требует закон\n'
        '• При серьёзной угрозе безопасности сервиса\n\n'
        '⚖️ Процесс проверки\n'
        '1. После жалобы проверяется только обжалованное письмо\n'
        '2. Определение нарушения правил\n'
        '3. При нарушении: блокировка контента + предупреждение\n'
        '4. 3+ нарушений: постоянная блокировка аккаунта\n\n'
        '🔒 Прозрачность\n'
        'Причины и результаты проверок фиксируются. Пользователи могут запросить информацию.',
    'tr': 'Thiscount gizliliğinize saygı duyar.\n\n'
        '📋 Temel İlke\n'
        'Yöneticiler mektup içeriğinize rutin olarak erişmez.\n\n'
        '🔍 İnceleme Ne Zaman Yapılır\n'
        '• Başka bir kullanıcı mektubu şikayet ettiğinde\n'
        '• Yasal gereklilik olduğunda\n'
        '• Hizmet güvenliğine ciddi tehdit olduğunda\n\n'
        '⚖️ İnceleme Süreci\n'
        '1. Şikayet sonrası yalnızca ilgili mektup incelenir\n'
        '2. Kural ihlali tespiti\n'
        '3. İhlal varsa: içerik engellenir + uyarı\n'
        '4. 3+ ihlal: kalıcı hesap askıya alma\n\n'
        '🔒 Şeffaflık\n'
        'İnceleme nedenleri ve sonuçları kaydedilir. Kullanıcılar bilgi talep edebilir.',
    'ar': 'Thiscount يحترم خصوصيتك.\n\n'
        '📋 المبدأ الأساسي\n'
        'لا يصل المسؤولون بشكل روتيني إلى محتوى رسائلك.\n\n'
        '🔍 متى تتم المراجعة\n'
        '• عندما يبلغ مستخدم آخر عن الرسالة\n'
        '• عندما يتطلب القانون ذلك\n'
        '• عند وجود تهديد خطير لأمان الخدمة\n\n'
        '⚖️ عملية المراجعة\n'
        '1. بعد البلاغ، يتم مراجعة الرسالة المبلغ عنها فقط\n'
        '2. تحديد مخالفة الإرشادات\n'
        '3. في حالة المخالفة: حظر المحتوى + تحذير\n'
        '4. 3+ مخالفات: تعليق دائم للحساب\n\n'
        '🔒 الشفافية\n'
        'يتم تسجيل الأسباب والنتائج. يمكن للمستخدمين الاستفسار عن الإجراءات المتخذة.',
    'it': 'Thiscount rispetta la tua privacy.\n\n'
        '📋 Principio fondamentale\n'
        'Gli amministratori non accedono regolarmente al contenuto delle tue lettere.\n\n'
        '🔍 Quando avviene la revisione\n'
        '• Quando un altro utente segnala la lettera\n'
        '• Quando richiesto dalla legge\n'
        '• Quando c\'è una grave minaccia alla sicurezza del servizio\n\n'
        '⚖️ Processo di revisione\n'
        '1. Dopo la segnalazione, viene esaminata solo la lettera segnalata\n'
        '2. Determinazione della violazione delle linee guida\n'
        '3. Se violazione confermata: contenuto bloccato + avvertimento\n'
        '4. 3+ violazioni: sospensione permanente dell\'account\n\n'
        '🔒 Trasparenza\n'
        'Motivazioni e risultati vengono registrati. Gli utenti possono richiedere informazioni.',
    'hi': 'Thiscount आपकी गोपनीयता का सम्मान करता है।\n\n'
        '📋 मूल सिद्धांत\n'
        'प्रशासक आपके पत्र सामग्री को नियमित रूप से नहीं देखते।\n\n'
        '🔍 समीक्षा कब होती है\n'
        '• जब कोई अन्य उपयोगकर्ता पत्र की शिकायत करता है\n'
        '• जब कानून द्वारा आवश्यक हो\n'
        '• जब सेवा सुरक्षा को गंभीर खतरा हो\n\n'
        '⚖️ समीक्षा प्रक्रिया\n'
        '1. शिकायत के बाद, केवल शिकायत किए गए पत्र की समीक्षा\n'
        '2. दिशानिर्देश उल्लंघन का निर्धारण\n'
        '3. उल्लंघन पर: सामग्री अवरुद्ध + चेतावनी\n'
        '4. 3+ उल्लंघन: स्थायी खाता निलंबन\n\n'
        '🔒 पारदर्शिता\n'
        'कारण और परिणाम दर्ज किए जाते हैं। उपयोगकर्ता कार्रवाई के बारे में पूछ सकते हैं।',
    'th': 'Thiscount เคารพความเป็นส่วนตัวของคุณ\n\n'
        '📋 หลักการพื้นฐาน\n'
        'ผู้ดูแลระบบไม่เข้าถึงเนื้อหาจดหมายของคุณเป็นประจำ\n\n'
        '🔍 เมื่อใดที่มีการตรวจสอบ\n'
        '• เมื่อผู้ใช้รายอื่นรายงานจดหมาย\n'
        '• เมื่อกฎหมายกำหนด\n'
        '• เมื่อมีภัยคุกคามร้ายแรงต่อความปลอดภัยของบริการ\n\n'
        '⚖️ กระบวนการตรวจสอบ\n'
        '1. หลังรับรายงาน ตรวจสอบเฉพาะจดหมายที่ถูกรายงาน\n'
        '2. พิจารณาว่าละเมิดแนวทางชุมชนหรือไม่\n'
        '3. หากละเมิด: บล็อกเนื้อหา + แจ้งเตือน\n'
        '4. ละเมิด 3+ ครั้ง: ระงับบัญชีถาวร\n\n'
        '🔒 ความโปร่งใส\n'
        'เหตุผลและผลลัพธ์จะถูกบันทึก ผู้ใช้สามารถสอบถามเกี่ยวกับมาตรการที่ดำเนินการ',
  });

  String get communityGuidelinesTitle => _t({
    'ko': '커뮤니티 가이드라인',
    'en': 'Community Guidelines',
    'ja': 'コミュニティガイドライン',
    'zh': '社区准则',
    'fr': 'Règles communautaires',
    'de': 'Community-Richtlinien',
    'es': 'Normas de la comunidad',
    'pt': 'Diretrizes da Comunidade',
    'ru': 'Правила сообщества',
    'tr': 'Topluluk Kuralları',
    'ar': 'إرشادات المجتمع',
    'it': 'Linee guida della comunità',
    'hi': 'सामुदायिक दिशानिर्देश',
    'th': 'แนวทางชุมชน',
  });

  String get communityGuidelinesBody => _t({
    'ko': 'Thiscount는 전 세계 사용자가 혜택을 통해 따뜻한 소통을 나누는 공간입니다.\n'
        '모든 사용자가 안전하고 즐거운 경험을 할 수 있도록 다음 규칙을 지켜주세요.\n\n'
        '✅ 권장 사항\n'
        '• 정중하고 친근한 톤으로 혜택을 쓰세요\n'
        '• 다양한 문화와 언어를 존중하세요\n'
        '• 긍정적이고 건설적인 내용을 공유하세요\n\n'
        '❌ 금지 사항\n'
        '• 혐오 발언, 차별, 인종차별적 표현\n'
        '• 성적으로 노골적인 콘텐츠\n'
        '• 폭력을 조장하거나 위협하는 내용\n'
        '• 스팸, 광고, 사기, 피싱\n'
        '• 타인의 개인정보 무단 공유\n'
        '• 저작권 침해 콘텐츠\n\n'
        '⚠️ 위반 시 조치\n'
        '• 1회: 해당 콘텐츠 차단 + 경고\n'
        '• 2회: 일시적 서비스 제한\n'
        '• 3회 이상: 영구 계정 차단\n\n'
        '부적절한 혜택을 받으면 혜택 읽기 화면에서 🚩 버튼으로 신고해 주세요.',
    'en': 'Thiscount is a space where users worldwide connect through rewards.\n'
        'Please follow these rules so everyone can have a safe, enjoyable experience.\n\n'
        '✅ Encouraged\n'
        '• Write rewards with a polite, friendly tone\n'
        '• Respect diverse cultures and languages\n'
        '• Share positive, constructive content\n\n'
        '❌ Prohibited\n'
        '• Hate speech, discrimination, racism\n'
        '• Sexually explicit content\n'
        '• Violence promotion or threats\n'
        '• Spam, advertising, scams, phishing\n'
        '• Sharing others\' personal information without consent\n'
        '• Copyright-infringing content\n\n'
        '⚠️ Enforcement\n'
        '• 1st offense: Content blocked + warning\n'
        '• 2nd offense: Temporary service restriction\n'
        '• 3+ offenses: Permanent account suspension\n\n'
        'If you receive an inappropriate reward, please report it using the 🚩 button on the reward screen.',
    'ja': 'Thiscountは世界中のユーザーが手紙でつながる場所です。\n'
        '安全で楽しい体験のために、以下のルールを守ってください。\n\n'
        '✅ 推奨事項\n'
        '• 丁寧で親しみやすいトーンで手紙を書いてください\n'
        '• 多様な文化と言語を尊重してください\n'
        '• ポジティブで建設的な内容を共有してください\n\n'
        '❌ 禁止事項\n'
        '• ヘイトスピーチ、差別、人種差別\n'
        '• 性的に露骨なコンテンツ\n'
        '• 暴力の助長や脅迫\n'
        '• スパム、広告、詐欺、フィッシング\n'
        '• 他人の個人情報の無断共有\n'
        '• 著作権侵害コンテンツ\n\n'
        '⚠️ 違反時の措置\n'
        '• 1回目：コンテンツブロック＋警告\n'
        '• 2回目：一時的なサービス制限\n'
        '• 3回以上：アカウント永久停止\n\n'
        '不適切な手紙を受け取った場合は、手紙画面の🚩ボタンで報告してください。',
    'zh': 'Thiscount 是全球用户通过信件连接的空间。\n'
        '请遵守以下规则，让每个人都能有安全、愉快的体验。\n\n'
        '✅ 鼓励的行为\n'
        '• 用礼貌、友好的语气写信\n'
        '• 尊重不同的文化和语言\n'
        '• 分享积极、建设性的内容\n\n'
        '❌ 禁止的行为\n'
        '• 仇恨言论、歧视、种族主义\n'
        '• 色情内容\n'
        '• 宣扬暴力或威胁\n'
        '• 垃圾邮件、广告、欺诈、钓鱼\n'
        '• 未经同意分享他人个人信息\n'
        '• 侵犯版权的内容\n\n'
        '⚠️ 处罚措施\n'
        '• 第1次：屏蔽内容 + 警告\n'
        '• 第2次：暂时限制服务\n'
        '• 3次以上：永久封禁账号\n\n'
        '如收到不当信件，请在信件页面点击🚩按钮举报。',
    'fr': 'Thiscount est un espace où les utilisateurs du monde entier communiquent par lettres.\n'
        'Suivez ces règles pour que chacun puisse vivre une expérience sûre et agréable.\n\n'
        '✅ Recommandé\n'
        '• Écrivez avec un ton poli et amical\n'
        '• Respectez les cultures et langues diverses\n'
        '• Partagez du contenu positif et constructif\n\n'
        '❌ Interdit\n'
        '• Discours haineux, discrimination, racisme\n'
        '• Contenu sexuellement explicite\n'
        '• Promotion de la violence ou menaces\n'
        '• Spam, publicité, escroqueries, phishing\n'
        '• Partage d\'informations personnelles sans consentement\n'
        '• Contenu violant les droits d\'auteur\n\n'
        '⚠️ Sanctions\n'
        '• 1ère infraction : Contenu bloqué + avertissement\n'
        '• 2e infraction : Restriction temporaire\n'
        '• 3+ infractions : Suspension permanente\n\n'
        'Si vous recevez une lettre inappropriée, signalez-la avec le bouton 🚩.',
    'de': 'Thiscount ist ein Raum, in dem Benutzer weltweit durch Briefe verbunden sind.\n'
        'Bitte befolgen Sie diese Regeln für eine sichere, angenehme Erfahrung.\n\n'
        '✅ Empfohlen\n'
        '• Schreiben Sie höflich und freundlich\n'
        '• Respektieren Sie verschiedene Kulturen und Sprachen\n'
        '• Teilen Sie positive, konstruktive Inhalte\n\n'
        '❌ Verboten\n'
        '• Hassrede, Diskriminierung, Rassismus\n'
        '• Sexuell explizite Inhalte\n'
        '• Gewaltverherrlichung oder Drohungen\n'
        '• Spam, Werbung, Betrug, Phishing\n'
        '• Unbefugte Weitergabe persönlicher Daten\n'
        '• Urheberrechtsverletzende Inhalte\n\n'
        '⚠️ Maßnahmen\n'
        '• 1. Verstoß: Inhalt gesperrt + Warnung\n'
        '• 2. Verstoß: Vorübergehende Einschränkung\n'
        '• 3+ Verstöße: Dauerhafte Kontosperrung\n\n'
        'Melden Sie unangemessene Briefe mit der 🚩-Taste.',
    'es': 'Thiscount es un espacio donde usuarios de todo el mundo se conectan a través de cartas.\n'
        'Siga estas reglas para que todos tengan una experiencia segura y agradable.\n\n'
        '✅ Recomendado\n'
        '• Escriba con un tono educado y amigable\n'
        '• Respete las diversas culturas e idiomas\n'
        '• Comparta contenido positivo y constructivo\n\n'
        '❌ Prohibido\n'
        '• Discurso de odio, discriminación, racismo\n'
        '• Contenido sexualmente explícito\n'
        '• Promoción de violencia o amenazas\n'
        '• Spam, publicidad, estafas, phishing\n'
        '• Compartir información personal sin consentimiento\n'
        '• Contenido que viola derechos de autor\n\n'
        '⚠️ Sanciones\n'
        '• 1ª infracción: Contenido bloqueado + advertencia\n'
        '• 2ª infracción: Restricción temporal\n'
        '• 3+ infracciones: Suspensión permanente\n\n'
        'Si recibe una carta inapropiada, repórtela con el botón 🚩.',
    'pt': 'Thiscount é um espaço onde usuários do mundo todo se conectam por cartas.\n'
        'Siga estas regras para que todos tenham uma experiência segura e agradável.\n\n'
        '✅ Recomendado\n'
        '• Escreva com um tom educado e amigável\n'
        '• Respeite culturas e idiomas diversos\n'
        '• Compartilhe conteúdo positivo e construtivo\n\n'
        '❌ Proibido\n'
        '• Discurso de ódio, discriminação, racismo\n'
        '• Conteúdo sexualmente explícito\n'
        '• Promoção de violência ou ameaças\n'
        '• Spam, publicidade, fraudes, phishing\n'
        '• Compartilhar informações pessoais sem consentimento\n'
        '• Conteúdo que viola direitos autorais\n\n'
        '⚠️ Sanções\n'
        '• 1ª infração: Conteúdo bloqueado + aviso\n'
        '• 2ª infração: Restrição temporária\n'
        '• 3+ infrações: Suspensão permanente\n\n'
        'Se receber uma carta inadequada, denuncie com o botão 🚩.',
    'ru': 'Thiscount — пространство, где пользователи со всего мира общаются через письма.\n'
        'Соблюдайте эти правила для безопасного и приятного опыта.\n\n'
        '✅ Рекомендуется\n'
        '• Пишите вежливым и дружелюбным тоном\n'
        '• Уважайте разные культуры и языки\n'
        '• Делитесь позитивным и конструктивным контентом\n\n'
        '❌ Запрещено\n'
        '• Ненавистнические высказывания, дискриминация, расизм\n'
        '• Откровенно сексуальный контент\n'
        '• Пропаганда насилия или угрозы\n'
        '• Спам, реклама, мошенничество, фишинг\n'
        '• Распространение личных данных без согласия\n'
        '• Контент, нарушающий авторские права\n\n'
        '⚠️ Меры\n'
        '• 1-е нарушение: Блокировка контента + предупреждение\n'
        '• 2-е нарушение: Временное ограничение\n'
        '• 3+ нарушений: Постоянная блокировка аккаунта\n\n'
        'Если получите неприемлемое письмо, пожалуйтесь через кнопку 🚩.',
    'tr': 'Thiscount, dünya genelinde kullanıcıların mektuplarla bağlandığı bir alandır.\n'
        'Herkesin güvenli ve keyifli bir deneyim yaşaması için bu kurallara uyun.\n\n'
        '✅ Önerilen\n'
        '• Kibar ve samimi bir tonla yazın\n'
        '• Farklı kültürlere ve dillere saygı gösterin\n'
        '• Olumlu ve yapıcı içerik paylaşın\n\n'
        '❌ Yasak\n'
        '• Nefret söylemi, ayrımcılık, ırkçılık\n'
        '• Cinsel açıdan müstehcen içerik\n'
        '• Şiddet teşviki veya tehditler\n'
        '• Spam, reklam, dolandırıcılık, kimlik avı\n'
        '• İzinsiz kişisel bilgi paylaşımı\n'
        '• Telif hakkı ihlali içerik\n\n'
        '⚠️ Yaptırımlar\n'
        '• 1. ihlal: İçerik engelleme + uyarı\n'
        '• 2. ihlal: Geçici kısıtlama\n'
        '• 3+ ihlal: Kalıcı hesap askıya alma\n\n'
        'Uygunsuz bir mektup alırsanız 🚩 düğmesiyle bildirin.',
    'ar': 'Thiscount مساحة يتواصل فيها المستخدمون حول العالم عبر الرسائل.\n'
        'يرجى اتباع هذه القواعد ليحظى الجميع بتجربة آمنة وممتعة.\n\n'
        '✅ مُشجع\n'
        '• اكتب بنبرة مهذبة وودية\n'
        '• احترم الثقافات واللغات المتنوعة\n'
        '• شارك محتوى إيجابياً وبناءً\n\n'
        '❌ محظور\n'
        '• خطاب الكراهية والتمييز والعنصرية\n'
        '• المحتوى الجنسي الصريح\n'
        '• الترويج للعنف أو التهديدات\n'
        '• البريد العشوائي والإعلانات والاحتيال\n'
        '• مشاركة معلومات الآخرين الشخصية بدون موافقة\n'
        '• المحتوى المنتهك لحقوق النشر\n\n'
        '⚠️ الإجراءات\n'
        '• المخالفة الأولى: حظر المحتوى + تحذير\n'
        '• المخالفة الثانية: تقييد مؤقت\n'
        '• 3+ مخالفات: تعليق دائم للحساب\n\n'
        'إذا تلقيت رسالة غير لائقة، أبلغ عنها باستخدام زر 🚩.',
    'it': 'Thiscount è uno spazio dove utenti di tutto il mondo si connettono tramite lettere.\n'
        'Segui queste regole per un\'esperienza sicura e piacevole per tutti.\n\n'
        '✅ Consigliato\n'
        '• Scrivi con un tono educato e amichevole\n'
        '• Rispetta culture e lingue diverse\n'
        '• Condividi contenuti positivi e costruttivi\n\n'
        '❌ Vietato\n'
        '• Discorsi d\'odio, discriminazione, razzismo\n'
        '• Contenuti sessualmente espliciti\n'
        '• Promozione della violenza o minacce\n'
        '• Spam, pubblicità, truffe, phishing\n'
        '• Condivisione di informazioni personali senza consenso\n'
        '• Contenuti che violano il diritto d\'autore\n\n'
        '⚠️ Sanzioni\n'
        '• 1ª violazione: Contenuto bloccato + avvertimento\n'
        '• 2ª violazione: Restrizione temporanea\n'
        '• 3+ violazioni: Sospensione permanente\n\n'
        'Se ricevi una lettera inappropriata, segnalala con il pulsante 🚩.',
    'hi': 'Thiscount एक ऐसा स्थान है जहां दुनिया भर के उपयोगकर्ता पत्रों के माध्यम से जुड़ते हैं।\n'
        'कृपया इन नियमों का पालन करें ताकि सभी को सुरक्षित, आनंददायक अनुभव मिले।\n\n'
        '✅ प्रोत्साहित\n'
        '• विनम्र, मैत्रीपूर्ण स्वर में लिखें\n'
        '• विविध संस्कृतियों और भाषाओं का सम्मान करें\n'
        '• सकारात्मक, रचनात्मक सामग्री साझा करें\n\n'
        '❌ निषिद्ध\n'
        '• नफ़रत भरा भाषण, भेदभाव, नस्लवाद\n'
        '• यौन रूप से स्पष्ट सामग्री\n'
        '• हिंसा को बढ़ावा या धमकी\n'
        '• स्पैम, विज्ञापन, धोखाधड़ी, फ़िशिंग\n'
        '• बिना सहमति दूसरों की व्यक्तिगत जानकारी साझा करना\n'
        '• कॉपीराइट उल्लंघन सामग्री\n\n'
        '⚠️ कार्रवाई\n'
        '• पहला उल्लंघन: सामग्री अवरुद्ध + चेतावनी\n'
        '• दूसरा उल्लंघन: अस्थायी प्रतिबंध\n'
        '• 3+ उल्लंघन: स्थायी खाता निलंबन\n\n'
        'अनुचित पत्र मिलने पर 🚩 बटन से रिपोर्ट करें।',
    'th': 'Thiscount เป็นพื้นที่ที่ผู้ใช้ทั่วโลกเชื่อมต่อกันผ่านจดหมาย\n'
        'กรุณาปฏิบัติตามกฎเหล่านี้เพื่อให้ทุกคนมีประสบการณ์ที่ปลอดภัยและสนุกสนาน\n\n'
        '✅ แนะนำ\n'
        '• เขียนด้วยน้ำเสียงที่สุภาพและเป็นมิตร\n'
        '• เคารพวัฒนธรรมและภาษาที่หลากหลาย\n'
        '• แบ่งปันเนื้อหาเชิงบวกและสร้างสรรค์\n\n'
        '❌ ห้าม\n'
        '• คำพูดแสดงความเกลียดชัง เลือกปฏิบัติ เหยียดเชื้อชาติ\n'
        '• เนื้อหาทางเพศที่ชัดเจน\n'
        '• ส่งเสริมความรุนแรงหรือข่มขู่\n'
        '• สแปม โฆษณา การฉ้อโกง ฟิชชิ่ง\n'
        '• แชร์ข้อมูลส่วนบุคคลโดยไม่ได้รับความยินยอม\n'
        '• เนื้อหาละเมิดลิขสิทธิ์\n\n'
        '⚠️ บทลงโทษ\n'
        '• ครั้งที่ 1: บล็อกเนื้อหา + แจ้งเตือน\n'
        '• ครั้งที่ 2: จำกัดบริการชั่วคราว\n'
        '• 3+ ครั้ง: ระงับบัญชีถาวร\n\n'
        'หากได้รับจดหมายที่ไม่เหมาะสม กรุณารายงานด้วยปุ่ม 🚩',
  });

  String get authMustAgreeTerms => _t({
    'ko': '서비스 이용약관에 동의해주세요',
    'en': 'Please agree to the Terms of Service',
    'ja': '利用規約に同意してください',
    'zh': '请同意服务条款',
    'fr': 'Veuillez accepter les conditions d\'utilisation',
    'de': 'Bitte stimmen Sie den Nutzungsbedingungen zu',
    'es': 'Por favor acepte los términos de servicio',
    'pt': 'Por favor, concorde com os Termos de Serviço',
    'ru': 'Пожалуйста, примите условия использования',
    'tr': 'Lütfen kullanım koşullarını kabul edin',
    'ar': 'يرجى الموافقة على شروط الخدمة',
    'it': 'Accetta i termini di servizio',
    'hi': 'कृपया सेवा की शर्तों से सहमत हों',
    'th': 'กรุณายอมรับข้อกำหนดการใช้งาน',
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ── Compose: Recall Last Letter ─────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  String get composeRecallLast => _t({
    'ko': '마지막 보낸 홍보 내용 불러오기',
    'en': 'Load last sent promo content',
    'ja': '最後に送った手紙の内容を読み込む',
    'zh': '加载上次发送的信件内容',
    'fr': 'Charger le contenu de la dernière lettre envoyée',
    'de': 'Inhalt des letzten gesendeten Briefes laden',
    'es': 'Cargar el contenido de la última carta enviada',
    'pt': 'Carregar conteúdo da última carta enviada',
    'ru': 'Загрузить содержание последнего письма',
    'tr': 'Son gönderilen mektup içeriğini yükle',
    'ar': 'تحميل محتوى آخر رسالة مرسلة',
    'it': 'Carica contenuto dell\'ultima lettera inviata',
    'hi': 'अंतिम भेजे गए पत्र की सामग्री लोड करें',
    'th': 'โหลดเนื้อหาจดหมายที่ส่งล่าสุด',
  });

  String get composeNoLastLetter => _t({
    'ko': '이전에 보낸 혜택이 없습니다',
    'en': 'No previously sent promo found',
    'ja': '以前送った手紙がありません',
    'zh': '没有找到之前发送的信件',
    'fr': 'Aucune lettre précédemment envoyée trouvée',
    'de': 'Kein zuvor gesendeter Brief gefunden',
    'es': 'No se encontró carta enviada anteriormente',
    'pt': 'Nenhuma carta enviada anteriormente encontrada',
    'ru': 'Ранее отправленных писем не найдено',
    'tr': 'Daha önce gönderilen mektup bulunamadı',
    'ar': 'لم يتم العثور على رسائل مرسلة سابقاً',
    'it': 'Nessuna lettera inviata in precedenza trovata',
    'hi': 'पहले भेजा गया कोई पत्र नहीं मिला',
    'th': 'ไม่พบจดหมายที่ส่งก่อนหน้านี้',
  });

  String get composeLoadLastTitle => _t({
    'ko': '마지막 보낸 홍보',
    'en': 'Last Sent Promo',
    'ja': '最後に送った手紙',
    'zh': '上次发送的信件',
    'fr': 'Dernière lettre envoyée',
    'de': 'Zuletzt gesendeter Brief',
    'es': 'Última carta enviada',
    'pt': 'Última carta enviada',
    'ru': 'Последнее отправленное письмо',
    'tr': 'Son gönderilen mektup',
    'ar': 'آخر رسالة مرسلة',
    'it': 'Ultima lettera inviata',
    'hi': 'अंतिम भेजा गया पत्र',
    'th': 'จดหมายที่ส่งล่าสุด',
  });

  String get composeLoadLastConfirm => _t({
    'ko': '불러오기',
    'en': 'Load',
    'ja': '読み込む',
    'zh': '加载',
    'fr': 'Charger',
    'de': 'Laden',
    'es': 'Cargar',
    'pt': 'Carregar',
    'ru': 'Загрузить',
    'tr': 'Yükle',
    'ar': 'تحميل',
    'it': 'Carica',
    'hi': 'लोड करें',
    'th': 'โหลด',
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ── Auth: Phone Number & Verify Method ──────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  String get authPhoneOptional => _t({
    'ko': '핸드폰 번호 (선택)',
    'en': 'Phone Number (Optional)',
    'ja': '電話番号（任意）',
    'zh': '手机号码（可选）',
    'fr': 'Numéro de téléphone (facultatif)',
    'de': 'Telefonnummer (optional)',
    'es': 'Número de teléfono (opcional)',
    'pt': 'Número de telefone (opcional)',
    'ru': 'Номер телефона (необязательно)',
    'tr': 'Telefon numarası (isteğe bağlı)',
    'ar': 'رقم الهاتف (اختياري)',
    'it': 'Numero di telefono (facoltativo)',
    'hi': 'फ़ोन नंबर (वैकल्पिक)',
    'th': 'หมายเลขโทรศัพท์ (ไม่บังคับ)',
  });

  String get authPhoneRequired => _t({
    'ko': '핸드폰 번호 (필수)',
    'en': 'Phone Number (Required)',
    'ja': '電話番号（必須）',
    'zh': '手机号码（必填）',
    'fr': 'Numéro de téléphone (obligatoire)',
    'de': 'Telefonnummer (erforderlich)',
    'es': 'Número de teléfono (obligatorio)',
    'pt': 'Número de telefone (obrigatório)',
    'ru': 'Номер телефона (обязательно)',
    'tr': 'Telefon numarası (zorunlu)',
    'ar': 'رقم الهاتف (مطلوب)',
    'it': 'Numero di telefono (obbligatorio)',
    'hi': 'फ़ोन नंबर (आवश्यक)',
    'th': 'หมายเลขโทรศัพท์ (จำเป็น)',
  });

  String get authPhoneHint => _t({
    'ko': '국가코드가 자동으로 추가됩니다',
    'en': 'Country code is added automatically',
    'ja': '国番号は自動的に追加されます',
    'zh': '国家代码会自动添加',
    'fr': 'L\'indicatif pays est ajouté automatiquement',
    'de': 'Landesvorwahl wird automatisch hinzugefügt',
    'es': 'El código de país se agrega automáticamente',
    'pt': 'O código do país é adicionado automaticamente',
    'ru': 'Код страны добавляется автоматически',
    'tr': 'Ülke kodu otomatik olarak eklenir',
    'ar': 'يتم إضافة رمز الدولة تلقائيًا',
    'it': 'Il prefisso internazionale viene aggiunto automaticamente',
    'hi': 'देश कोड स्वचालित रूप से जोड़ा जाता है',
    'th': 'รหัสประเทศจะถูกเพิ่มโดยอัตโนมัติ',
  });

  String get authPhoneRequiredMsg => _t({
    'ko': '핸드폰 번호를 입력해주세요',
    'en': 'Please enter your phone number',
    'ja': '電話番号を入力してください',
    'zh': '请输入手机号码',
    'fr': 'Veuillez entrer votre numéro de téléphone',
    'de': 'Bitte geben Sie Ihre Telefonnummer ein',
    'es': 'Ingrese su número de teléfono',
    'pt': 'Insira seu número de telefone',
    'ru': 'Введите номер телефона',
    'tr': 'Lütfen telefon numaranızı girin',
    'ar': 'يرجى إدخال رقم هاتفك',
    'it': 'Inserisci il tuo numero di telefono',
    'hi': 'कृपया अपना फ़ोन नंबर दर्ज करें',
    'th': 'กรุณากรอกหมายเลขโทรศัพท์',
  });

  String get authPhoneInvalid => _t({
    'ko': '올바른 전화번호를 입력해주세요',
    'en': 'Please enter a valid phone number',
    'ja': '有効な電話番号を入力してください',
    'zh': '请输入有效的手机号码',
    'fr': 'Veuillez entrer un numéro valide',
    'de': 'Bitte geben Sie eine gültige Nummer ein',
    'es': 'Ingrese un número de teléfono válido',
    'pt': 'Insira um número de telefone válido',
    'ru': 'Введите правильный номер телефона',
    'tr': 'Geçerli bir telefon numarası girin',
    'ar': 'يرجى إدخال رقم هاتف صالح',
    'it': 'Inserisci un numero di telefono valido',
    'hi': 'कृपया एक वैध फ़ोन नंबर दर्ज करें',
    'th': 'กรุณากรอกหมายเลขโทรศัพท์ที่ถูกต้อง',
  });

  String get authSelectCountryCode => _t({
    'ko': '국가코드 선택',
    'en': 'Select Country Code',
    'ja': '国番号を選択',
    'zh': '选择国家代码',
    'fr': 'Sélectionner l\'indicatif',
    'de': 'Landesvorwahl wählen',
    'es': 'Seleccionar código de país',
    'pt': 'Selecionar código do país',
    'ru': 'Выберите код страны',
    'tr': 'Ülke kodu seçin',
    'ar': 'اختر رمز الدولة',
    'it': 'Seleziona prefisso',
    'hi': 'देश कोड चुनें',
    'th': 'เลือกรหัสประเทศ',
  });

  String get authVerifyViaEmail => _t({
    'ko': '본인 인증은 이메일로 진행됩니다',
    'en': 'Verification will be done via email',
    'ja': '本人確認はメールで行われます',
    'zh': '身份验证将通过邮箱进行',
    'fr': 'La vérification se fera par e-mail',
    'de': 'Die Verifizierung erfolgt per E-Mail',
    'es': 'La verificación se realizará por correo electrónico',
    'pt': 'A verificação será feita por e-mail',
    'ru': 'Верификация будет выполнена по электронной почте',
    'tr': 'Doğrulama e-posta ile yapılacaktır',
    'ar': 'سيتم التحقق عبر البريد الإلكتروني',
    'it': 'La verifica avverrà tramite e-mail',
    'hi': 'सत्यापन ईमेल के माध्यम से किया जाएगा',
    'th': 'การยืนยันจะดำเนินการผ่านอีเมล',
  });

  String get authSmsVerification => _t({
    'ko': 'SMS 인증',
    'en': 'SMS Verification',
    'ja': 'SMS認証',
    'zh': '短信验证',
    'fr': 'Vérification SMS',
    'de': 'SMS-Verifizierung',
    'es': 'Verificación SMS',
    'pt': 'Verificação SMS',
    'ru': 'SMS-верификация',
    'tr': 'SMS Doğrulama',
    'ar': 'التحقق عبر SMS',
    'it': 'Verifica SMS',
    'hi': 'SMS सत्यापन',
    'th': 'ยืนยันทาง SMS',
  });

  String authOtpSentSms(String phone) => _t({
    'ko': '$phone 으로 인증번호가 발송되었습니다',
    'en': 'A verification code has been sent to $phone',
    'ja': '$phone に認証コードを送信しました',
    'zh': '验证码已发送至 $phone',
    'fr': 'Un code a été envoyé au $phone',
    'de': 'Ein Code wurde an $phone gesendet',
    'es': 'Se envió un código a $phone',
    'pt': 'Um código foi enviado para $phone',
    'ru': 'Код отправлен на $phone',
    'tr': '$phone numarasına kod gönderildi',
    'ar': 'تم إرسال رمز التحقق إلى $phone',
    'it': 'Un codice è stato inviato a $phone',
    'hi': '$phone पर सत्यापन कोड भेजा गया है',
    'th': 'รหัสยืนยันถูกส่งไปที่ $phone',
  });

  String get authVerifyMethodTitle => _t({
    'ko': '인증 수단 선택',
    'en': 'Verification Method',
    'ja': '認証方法の選択',
    'zh': '验证方式选择',
    'fr': 'Méthode de vérification',
    'de': 'Verifizierungsmethode',
    'es': 'Método de verificación',
    'pt': 'Método de Verificação',
    'ru': 'Способ верификации',
    'tr': 'Doğrulama yöntemi',
    'ar': 'طريقة التحقق',
    'it': 'Metodo di verifica',
    'hi': 'सत्यापन विधि',
    'th': 'วิธีการยืนยัน',
  });

  String get authVerifyMethodDesc => _t({
    'ko': '회원가입 확인, 비밀번호 재설정 시 사용됩니다',
    'en': 'Used for signup verification and password reset',
    'ja': '会員登録確認やパスワードリセット時に使用されます',
    'zh': '用于注册验证和密码重置',
    'fr': 'Utilisé pour la vérification d\'inscription et la réinitialisation du mot de passe',
    'de': 'Wird für Registrierungsverifizierung und Passwort-Zurücksetzung verwendet',
    'es': 'Usado para verificación de registro y restablecimiento de contraseña',
    'pt': 'Usado para verificação de cadastro e redefinição de senha',
    'ru': 'Используется для подтверждения регистрации и сброса пароля',
    'tr': 'Kayıt doğrulama ve şifre sıfırlama için kullanılır',
    'ar': 'يُستخدم لتأكيد التسجيل وإعادة تعيين كلمة المرور',
    'it': 'Utilizzato per la verifica della registrazione e il ripristino della password',
    'hi': 'साइनअप सत्यापन और पासवर्ड रीसेट के लिए उपयोग किया जाता है',
    'th': 'ใช้สำหรับยืนยันการสมัครและรีเซ็ตรหัสผ่าน',
  });

  String get authPhoneRequiredForSms => _t({
    'ko': 'SMS 인증을 사용하려면 핸드폰 번호를 먼저 입력해주세요',
    'en': 'Please enter your phone number first to use SMS verification',
    'ja': 'SMS認証を使用するには、まず電話番号を入力してください',
    'zh': '请先输入手机号码才能使用短信验证',
    'fr': 'Veuillez d\'abord entrer votre numéro de téléphone pour utiliser la vérification SMS',
    'de': 'Bitte geben Sie zuerst Ihre Telefonnummer ein, um die SMS-Verifizierung zu nutzen',
    'es': 'Ingrese su número de teléfono primero para usar la verificación por SMS',
    'pt': 'Insira seu número de telefone primeiro para usar a verificação por SMS',
    'ru': 'Сначала введите номер телефона для использования SMS-верификации',
    'tr': 'SMS doğrulama için lütfen önce telefon numaranızı girin',
    'ar': 'يرجى إدخال رقم هاتفك أولاً لاستخدام التحقق عبر SMS',
    'it': 'Inserisci prima il tuo numero di telefono per usare la verifica SMS',
    'hi': 'SMS सत्यापन उपयोग करने के लिए कृपया पहले अपना फ़ोन नंबर दर्ज करें',
    'th': 'กรุณากรอกหมายเลขโทรศัพท์ก่อนเพื่อใช้การยืนยันทาง SMS',
  });

  // ══════════════════════════════════════════════════════════════════════
  // Phase 2/3 — Streak · Challenge · Scarcity · City of Month · Share card
  // ══════════════════════════════════════════════════════════════════════

  // ── 일일 스트릭 ─────────────────────────────────────────────────────────
  String streakDayLabel(int days) => _t({
    'ko': '$days일', 'en': '$days d', 'ja': '$days日', 'zh': '$days天',
    'fr': '$days j', 'de': '$days T', 'es': '$days d', 'pt': '$days d',
    'ru': '$days д', 'tr': '$days g', 'ar': '$days يوم',
    'it': '$days g', 'hi': '$days दिन', 'th': '$days วัน',
  });

  String streakFreezeUsedMessage(int days) {
    switch (languageCode) {
      case 'ko': return '스트릭을 한 번 구해드렸어요! $days일 연속 유지 중';
      case 'ja': return 'ストリークを1回救いました！$days日連続継続中';
      case 'zh': return '我们帮你保住了一次连续签到！当前 $days 天';
      case 'fr': return "On a sauvé votre série une fois ! $days jours d'affilée";
      case 'de': return 'Wir haben deine Serie einmal gerettet! $days Tage in Folge';
      case 'es': return '¡Salvamos tu racha una vez! $days días seguidos';
      case 'pt': return 'Salvamos seu streak uma vez! $days dias seguidos';
      case 'ru': return 'Мы сохранили вашу серию! $days дней подряд';
      case 'tr': return 'Serini bir kez kurtardık! $days gün üst üste';
      case 'ar': return 'أنقذنا سلسلتك مرة واحدة! $days يوماً متتالياً';
      case 'it': return 'Abbiamo salvato la tua serie una volta! $days giorni di fila';
      case 'hi': return 'हमने आपकी स्ट्रीक एक बार बचा ली! लगातार $days दिन';
      case 'th': return 'เราช่วยสตรีคของคุณไว้หนึ่งครั้ง! ต่อเนื่อง $days วัน';
      case 'en':
      default: return 'We saved your streak once! $days days running';
    }
  }

  String streakMilestoneMessage(int days) {
    switch (days) {
      case 3: return streakMilestone3;
      case 7: return streakMilestone7;
      case 14: return streakMilestone14;
      case 30: return streakMilestone30;
      case 100: return streakMilestone100;
      default: return streakMilestoneGeneric(days);
    }
  }

  String get streakMilestone3 => _t({
    'ko': '3일 연속 접속! 습관이 시작되고 있어요',
    'en': '3-day streak! A new habit is forming',
    'ja': '3日連続アクセス！習慣が始まっています',
    'zh': '连续3天签到！习惯正在养成',
    'fr': '3 jours consécutifs ! Une habitude se forme',
    'de': '3-Tage-Serie! Eine Gewohnheit entsteht',
    'es': '¡3 días seguidos! Se forma un hábito',
    'pt': '3 dias seguidos! Um hábito está se formando',
    'ru': '3 дня подряд! Привычка формируется',
    'tr': '3 gün üst üste! Bir alışkanlık oluşuyor',
    'ar': '٣ أيام متتالية! عادة تتشكل',
    'it': '3 giorni di fila! Un\'abitudine sta nascendo',
    'hi': '3 दिन लगातार! आदत बन रही है',
    'th': 'ต่อเนื่อง 3 วัน! นิสัยกำลังก่อตัว',
  });

  String get streakMilestone7 => _t({
    'ko': '7일 연속 접속! 일주일을 채웠어요 ✨',
    'en': '7-day streak! A full week ✨',
    'ja': '7日連続アクセス！一週間達成 ✨',
    'zh': '连续7天签到！完整一周 ✨',
    'fr': '7 jours consécutifs ! Une semaine complète ✨',
    'de': '7-Tage-Serie! Eine ganze Woche ✨',
    'es': '¡7 días seguidos! Una semana completa ✨',
    'pt': '7 dias seguidos! Uma semana inteira ✨',
    'ru': '7 дней подряд! Целая неделя ✨',
    'tr': '7 gün üst üste! Tam bir hafta ✨',
    'ar': '٧ أيام متتالية! أسبوع كامل ✨',
    'it': '7 giorni di fila! Una settimana intera ✨',
    'hi': '7 दिन लगातार! पूरा हफ़्ता ✨',
    'th': 'ต่อเนื่อง 7 วัน! ครบสัปดาห์ ✨',
  });

  String get streakMilestone14 => _t({
    'ko': '14일 연속 접속! 혜택이 익숙해졌어요',
    'en': '14-day streak! Rewards feel like home',
    'ja': '14日連続アクセス！手紙が日課になりました',
    'zh': '连续14天签到！写信已成日常',
    'fr': '14 jours consécutifs ! Les lettres deviennent routine',
    'de': '14-Tage-Serie! Briefe sind zur Gewohnheit geworden',
    'es': '¡14 días seguidos! Las cartas se sienten naturales',
    'pt': '14 dias seguidos! As cartas viraram rotina',
    'ru': '14 дней подряд! Письма стали привычкой',
    'tr': '14 gün üst üste! Mektuplar rutine döndü',
    'ar': '١٤ يومًا متتاليًا! صارت الرسائل عادة',
    'it': '14 giorni di fila! Le lettere sono ormai familiari',
    'hi': '14 दिन लगातार! पत्र अब आदत बन गए',
    'th': 'ต่อเนื่อง 14 วัน! จดหมายกลายเป็นส่วนหนึ่งของวัน',
  });

  String get streakMilestone30 => _t({
    'ko': '30일 연속 접속! 한 달의 여정 🌟',
    'en': '30-day streak! A month-long journey 🌟',
    'ja': '30日連続アクセス！一ヶ月の旅 🌟',
    'zh': '连续30天签到！一个月的旅程 🌟',
    'fr': '30 jours consécutifs ! Un mois de voyage 🌟',
    'de': '30-Tage-Serie! Eine Reise von einem Monat 🌟',
    'es': '¡30 días seguidos! Un viaje de un mes 🌟',
    'pt': '30 dias seguidos! Uma jornada de um mês 🌟',
    'ru': '30 дней подряд! Месяц в пути 🌟',
    'tr': '30 gün üst üste! Bir aylık yolculuk 🌟',
    'ar': '٣٠ يومًا متتاليًا! رحلة شهر 🌟',
    'it': '30 giorni di fila! Un viaggio di un mese 🌟',
    'hi': '30 दिन लगातार! एक महीने की यात्रा 🌟',
    'th': 'ต่อเนื่อง 30 วัน! การเดินทางหนึ่งเดือน 🌟',
  });

  String get streakMilestone100 => _t({
    'ko': '100일 연속 접속! 전설의 카운터 🏆',
    'en': '100-day streak! Legendary mailer 🏆',
    'ja': '100日連続アクセス！伝説の手紙使い 🏆',
    'zh': '连续100天签到！传说中的信使 🏆',
    'fr': '100 jours consécutifs ! Écrivain légendaire 🏆',
    'de': '100-Tage-Serie! Legendärer Briefschreiber 🏆',
    'es': '¡100 días seguidos! Cartero legendario 🏆',
    'pt': '100 dias seguidos! Carteiro lendário 🏆',
    'ru': '100 дней подряд! Легендарный письмоносец 🏆',
    'tr': '100 gün üst üste! Efsanevi mektupçu 🏆',
    'ar': '١٠٠ يوم متتالي! ساعي البريد الأسطوري 🏆',
    'it': '100 giorni di fila! Scrittore leggendario 🏆',
    'hi': '100 दिन लगातार! दिग्गज पत्र लेखक 🏆',
    'th': 'ต่อเนื่อง 100 วัน! นักเขียนจดหมายในตำนาน 🏆',
  });

  String streakMilestoneGeneric(int days) => _t({
    'ko': '$days일 연속 접속! 계속 이어가요',
    'en': '$days-day streak! Keep it going',
    'ja': '$days日連続アクセス！このまま続けましょう',
    'zh': '连续$days天签到！继续保持',
    'fr': '$days jours consécutifs ! Continuez',
    'de': '$days-Tage-Serie! Weiter so',
    'es': '¡$days días seguidos! Sigue así',
    'pt': '$days dias seguidos! Continue assim',
    'ru': '$days дней подряд! Продолжайте',
    'tr': '$days gün üst üste! Devam edin',
    'ar': '$days يومًا متتاليًا! استمر',
    'it': '$days giorni di fila! Continua così',
    'hi': '$days दिन लगातार! जारी रखें',
    'th': 'ต่อเนื่อง $days วัน! ทำต่อไป',
  });

  // ── 주간 챌린지 ─────────────────────────────────────────────────────────
  String get weeklyChallengeTitle => _t({
    'ko': '이번 주 챌린지',
    'en': 'This Week\'s Challenge',
    'ja': '今週のチャレンジ',
    'zh': '本周挑战',
    'fr': 'Défi de la semaine',
    'de': 'Wochen-Challenge',
    'es': 'Reto de la semana',
    'pt': 'Desafio da semana',
    'ru': 'Вызов недели',
    'tr': 'Bu haftanın mücadelesi',
    'ar': 'تحدي هذا الأسبوع',
    'it': 'Sfida della settimana',
    'hi': 'इस हफ़्ते की चुनौती',
    'th': 'ชาเลนจ์ประจำสัปดาห์',
  });

  String get weeklyChallengeAchievedTitle => _t({
    'ko': '이번 주 챌린지 달성',
    'en': 'Weekly Challenge Achieved',
    'ja': '今週のチャレンジ達成',
    'zh': '本周挑战已完成',
    'fr': 'Défi hebdomadaire accompli',
    'de': 'Wochen-Challenge geschafft',
    'es': 'Reto semanal logrado',
    'pt': 'Desafio semanal concluído',
    'ru': 'Вызов недели выполнен',
    'tr': 'Haftalık mücadele tamamlandı',
    'ar': 'تم إنجاز تحدي الأسبوع',
    'it': 'Sfida settimanale completata',
    'hi': 'साप्ताहिक चुनौती पूरी',
    'th': 'ผ่านชาเลนจ์ประจำสัปดาห์แล้ว',
  });

  String get weeklyChallengeRewardPendingTitle => _t({
    'ko': '이번 주 챌린지 완료!',
    'en': 'Challenge Complete!',
    'ja': '今週のチャレンジ完了！',
    'zh': '挑战完成！',
    'fr': 'Défi terminé !',
    'de': 'Challenge abgeschlossen!',
    'es': '¡Reto completado!',
    'pt': 'Desafio completo!',
    'ru': 'Вызов завершён!',
    'tr': 'Mücadele tamamlandı!',
    'ar': 'اكتمل التحدي!',
    'it': 'Sfida completata!',
    'hi': 'चुनौती पूरी!',
    'th': 'ชาเลนจ์สำเร็จ!',
  });

  String weeklyChallengeDescription(int goal) => _t({
    'ko': '이번 주에 $goal개 나라로 홍보를 보내보세요',
    'en': 'Send promos to $goal countries this week',
    'ja': '今週$goalカ国に手紙を送ってみましょう',
    'zh': '本周向$goal个国家寄信',
    'fr': 'Envoyez des lettres à $goal pays cette semaine',
    'de': 'Sende Briefe in $goal Länder diese Woche',
    'es': 'Envía cartas a $goal países esta semana',
    'pt': 'Envie cartas para $goal países esta semana',
    'ru': 'Отправь письма в $goal стран на этой неделе',
    'tr': 'Bu hafta $goal ülkeye mektup gönder',
    'ar': 'أرسل رسائل إلى $goal دول هذا الأسبوع',
    'it': 'Invia lettere a $goal paesi questa settimana',
    'hi': 'इस हफ़्ते $goal देशों को पत्र भेजें',
    'th': 'ส่งจดหมายไปยัง $goal ประเทศในสัปดาห์นี้',
  });

  String weeklyChallengeProgress(int current, int goal) => _t({
    'ko': '$current / $goal 개국',
    'en': '$current / $goal countries',
    'ja': '$current / $goalカ国',
    'zh': '$current / $goal 国',
    'fr': '$current / $goal pays',
    'de': '$current / $goal Länder',
    'es': '$current / $goal países',
    'pt': '$current / $goal países',
    'ru': '$current / $goal стран',
    'tr': '$current / $goal ülke',
    'ar': '$current / $goal دولة',
    'it': '$current / $goal paesi',
    'hi': '$current / $goal देश',
    'th': '$current / $goal ประเทศ',
  });

  String weeklyChallengeRemaining(int n) => _t({
    'ko': '$n개국 남음',
    'en': '$n more to go',
    'ja': '残り$nカ国',
    'zh': '还差$n个国家',
    'fr': '$n de plus',
    'de': 'noch $n',
    'es': 'faltan $n',
    'pt': 'faltam $n',
    'ru': 'ещё $n',
    'tr': '$n ülke kaldı',
    'ar': 'متبقي $n دول',
    'it': 'ancora $n',
    'hi': '$n और बाकी',
    'th': 'เหลืออีก $n ประเทศ',
  });

  String get weeklyChallengeClaimButton => _t({
    'ko': '보상 받기',
    'en': 'Claim Reward',
    'ja': '報酬を受け取る',
    'zh': '领取奖励',
    'fr': 'Récupérer la récompense',
    'de': 'Belohnung holen',
    'es': 'Reclamar recompensa',
    'pt': 'Resgatar recompensa',
    'ru': 'Забрать награду',
    'tr': 'Ödülü al',
    'ar': 'استلام المكافأة',
    'it': 'Riscuoti ricompensa',
    'hi': 'इनाम पाएं',
    'th': 'รับรางวัล',
  });

  String get weeklyChallengeClaimed => _t({
    'ko': '보상 수령 완료',
    'en': 'Reward claimed',
    'ja': '報酬受取済み',
    'zh': '奖励已领取',
    'fr': 'Récompense reçue',
    'de': 'Belohnung erhalten',
    'es': 'Recompensa reclamada',
    'pt': 'Recompensa recebida',
    'ru': 'Награда получена',
    'tr': 'Ödül alındı',
    'ar': 'تم استلام المكافأة',
    'it': 'Ricompensa ricevuta',
    'hi': 'इनाम मिल गया',
    'th': 'รับรางวัลแล้ว',
  });

  String get weeklyChallengeClaimToast => _t({
    'ko': '보상을 받았어요! 다음 주에도 이어가볼까요?',
    'en': 'Reward claimed! See you next week?',
    'ja': '報酬を受け取りました！来週も続けましょう',
    'zh': '奖励已领取！下周继续吧',
    'fr': 'Récompense reçue ! À la semaine prochaine ?',
    'de': 'Belohnung erhalten! Weiter nächste Woche?',
    'es': '¡Recompensa reclamada! ¿La siguiente semana?',
    'pt': 'Recompensa recebida! Até a próxima semana?',
    'ru': 'Награда получена! Продолжим на следующей неделе?',
    'tr': 'Ödül alındı! Gelecek hafta devam edelim mi?',
    'ar': 'تم استلام المكافأة! نراكم الأسبوع القادم؟',
    'it': 'Ricompensa ricevuta! Ci vediamo la prossima settimana',
    'hi': 'इनाम मिल गया! अगले हफ़्ते फिर मिलते हैं',
    'th': 'รับรางวัลแล้ว! สัปดาห์หน้าเจอกันอีกนะ',
  });

  // ── 혜택 커뮤니티 감성 메시지 (scarcity 제거, 함께 읽기 강조) ──────────
  String get scarcityClosedTitle => _t({
    'ko': '많은 이들이 함께 읽은 혜택',
    'en': 'A reward read by many',
    'ja': '多くの人が読んだ手紙',
    'zh': '被许多人一起读过的信',
    'fr': 'Une lettre lue par beaucoup',
    'de': 'Ein Brief, den viele gelesen haben',
    'es': 'Una carta leída por muchos',
    'pt': 'Uma carta lida por muitos',
    'ru': 'Письмо, которое прочли многие',
    'tr': 'Birçok kişinin okuduğu bir mektup',
    'ar': 'رسالة قرأها الكثيرون',
    'it': 'Una lettera letta da molti',
    'hi': 'कई लोगों ने पढ़ा यह पत्र',
    'th': 'จดหมายที่ถูกอ่านโดยหลายคน',
  });

  String get scarcityClosedSub => _t({
    'ko': '이 혜택은 이미 여러 사람의 하루에 닿았어요',
    'en': 'This reward has already touched many days',
    'ja': 'この手紙はすでにたくさんの人の一日に届きました',
    'zh': '这封信已经触动了许多人的一天',
    'fr': 'Cette lettre a déjà touché bien des journées',
    'de': 'Dieser Brief hat schon viele Tage berührt',
    'es': 'Esta carta ya ha tocado muchos días',
    'pt': 'Esta carta já tocou muitos dias',
    'ru': 'Это письмо уже коснулось многих дней',
    'tr': 'Bu mektup şimdiden birçok güne dokundu',
    'ar': 'لمست هذه الرسالة بالفعل أياماً كثيرة',
    'it': 'Questa lettera ha già toccato molte giornate',
    'hi': 'इस पत्र ने कई दिनों को छू लिया है',
    'th': 'จดหมายนี้ได้สัมผัสวันของหลายคนแล้ว',
  });

  String get scarcityLastReaderTitle => _t({
    'ko': '이 혜택이 당신에게 왔어요',
    'en': 'This reward found you',
    'ja': 'この手紙はあなたに届きました',
    'zh': '这封信来到了你身边',
    'fr': 'Cette lettre vous a trouvé',
    'de': 'Dieser Brief hat dich gefunden',
    'es': 'Esta carta te encontró',
    'pt': 'Esta carta chegou até você',
    'ru': 'Это письмо нашло вас',
    'tr': 'Bu mektup sizi buldu',
    'ar': 'وجدتك هذه الرسالة',
    'it': 'Questa lettera ti ha trovato',
    'hi': 'यह पत्र आप तक पहुँचा',
    'th': 'จดหมายฉบับนี้ได้มาถึงคุณ',
  });

  String scarcityLastReaderSub(int ordinal, int total) => _t({
    'ko': '지구 어딘가에서 함께 읽는 중',
    'en': 'Being read somewhere on Earth right now',
    'ja': '地球のどこかで一緒に読まれています',
    'zh': '此刻正在地球某处被一起阅读',
    'fr': 'Lue quelque part sur Terre en ce moment',
    'de': 'Wird gerade irgendwo auf der Erde gelesen',
    'es': 'Siendo leída en algún lugar de la Tierra',
    'pt': 'Sendo lida em algum lugar da Terra agora',
    'ru': 'Читается где-то на Земле прямо сейчас',
    'tr': 'Şu an Dünya\'nın bir yerinde okunuyor',
    'ar': 'تُقرأ الآن في مكان ما على الأرض',
    'it': 'Letta in qualche parte della Terra in questo momento',
    'hi': 'पृथ्वी के किसी कोने में अभी पढ़ा जा रहा है',
    'th': 'กำลังถูกอ่านอยู่ที่ไหนสักแห่งบนโลก',
  });

  String scarcityCountTitle(int read, int total) => _t({
    'ko': '지구 어딘가에서 함께 읽는 중',
    'en': 'Being read somewhere on Earth',
    'ja': '地球のどこかで一緒に読まれています',
    'zh': '地球某处正在共同阅读',
    'fr': 'Lue quelque part sur Terre',
    'de': 'Wird irgendwo auf der Erde gelesen',
    'es': 'Siendo leída en algún lugar de la Tierra',
    'pt': 'Sendo lida em algum lugar da Terra',
    'ru': 'Читается где-то на Земле',
    'tr': 'Dünya\'nın bir yerinde okunuyor',
    'ar': 'تُقرأ في مكان ما على الأرض',
    'it': 'Letta in qualche parte della Terra',
    'hi': 'पृथ्वी के किसी कोने में पढ़ा जा रहा',
    'th': 'กำลังถูกอ่านที่ไหนสักแห่งบนโลก',
  });

  String scarcityCountSub(int remaining) => _t({
    'ko': '같은 혜택을 읽고 있는 다른 이들이 있어요',
    'en': 'Others are reading the same reward too',
    'ja': '同じ手紙を読んでいる人が他にもいます',
    'zh': '还有其他人也在读这封信',
    'fr': 'D\'autres lisent aussi cette lettre',
    'de': 'Andere lesen diesen Brief auch',
    'es': 'Otros también leen esta carta',
    'pt': 'Outros também estão lendo esta carta',
    'ru': 'Другие тоже читают это письмо',
    'tr': 'Başkaları da aynı mektubu okuyor',
    'ar': 'يقرأ الآخرون هذه الرسالة أيضاً',
    'it': 'Altri stanno leggendo questa lettera',
    'hi': 'और लोग भी यही पत्र पढ़ रहे हैं',
    'th': 'คนอื่นๆ ก็กำลังอ่านจดหมายนี้ด้วย',
  });

  // ── 레벨업 배너 ─────────────────────────────────────────────────────────
  // Build 183: 레벨업 배너 — 레터 중심으로 리프레임. "기능 해금" 이 아니라
  // "카운터 성장" 내러티브.
  String get levelUpBannerTitle => _t({
    'ko': '카운터가 성장했어요',
    'en': 'Your Counter has grown',
    'ja': 'カウンターが成長しました',
    'zh': '你的 Counter 成长了',
    'fr': 'Votre Counter a grandi',
    'de': 'Dein Counter ist gewachsen',
    'es': 'Tu Counter ha crecido',
    'pt': 'Seu Counter cresceu',
    'ru': 'Ваш Counter вырос',
    'tr': 'Counter\'ın büyüdü',
    'ar': 'نما Counter الخاص بك',
    'it': 'Il tuo Counter è cresciuto',
    'hi': 'आपका Counter बढ़ा',
    'th': 'Counter ของคุณเติบโต',
  });

  String get userLevelNewbieWelcome => _t({
    'ko': '첫 홍보를 보내볼까요?',
    'en': 'Ready to send your first promo?',
    'ja': '最初の手紙を送ってみませんか？',
    'zh': '要寄出第一封信吗？',
    'fr': 'Prêt à envoyer votre première lettre ?',
    'de': 'Bereit für den ersten Brief?',
    'es': '¿Listo para enviar tu primera carta?',
    'pt': 'Pronto para enviar sua primeira carta?',
    'ru': 'Готовы отправить первое письмо?',
    'tr': 'İlk mektubunu göndermeye hazır mısın?',
    'ar': 'مستعد لإرسال أول رسالة؟',
    'it': 'Pronto a inviare la tua prima lettera?',
    'hi': 'पहला पत्र भेजने को तैयार?',
    'th': 'พร้อมส่งจดหมายฉบับแรกหรือยัง?',
  });

  // Build 183: "탑 레벨" → 레터 레벨. 타워 잔상 제거.
  String get userLevelBeginnerWelcome => _t({
    'ko': '🎟 카운터 레벨이 공개되었어요',
    'en': '🎟 Your Counter level is now visible',
    'ja': '🎟 カウンターレベルが公開されました',
    'zh': '🎟 你的 Counter 等级已公开',
    'fr': '🎟 Votre niveau Counter est désormais visible',
    'de': '🎟 Dein Counter-Level ist nun sichtbar',
    'es': '🎟 Tu nivel de Counter ahora es visible',
    'pt': '🎟 Seu nível de Counter agora é visível',
    'ru': '🎟 Ваш уровень Counter теперь виден',
    'tr': '✉️ Letter seviyen artık görünür',
    'ar': '✉️ أصبح مستوى Letter مرئيًا',
    'it': '✉️ Il livello del tuo Letter è ora visibile',
    'hi': '✉️ आपका Letter स्तर अब दिखाई दे रहा है',
    'th': '✉️ ระดับ Letter ของคุณแสดงแล้ว',
  });

  String get userLevelCasualWelcome => _t({
    'ko': '✉️ 오늘의 혜택이 해금되었어요',
    'en': '✉️ Today\'s Reward is now available',
    'ja': '✉️ 今日の手紙が利用可能になりました',
    'zh': '✉️ 今日之信已解锁',
    'fr': '✉️ La Lettre du jour est disponible',
    'de': '✉️ Der Brief des Tages ist verfügbar',
    'es': '✉️ La Carta del día está disponible',
    'pt': '✉️ A Carta do dia está disponível',
    'ru': '✉️ Письмо дня теперь доступно',
    'tr': '✉️ Günün Mektubu artık kullanılabilir',
    'ar': '✉️ رسالة اليوم متاحة الآن',
    'it': '✉️ La Lettera del giorno è disponibile',
    'hi': '✉️ आज का पत्र अब उपलब्ध है',
    'th': '✉️ จดหมายวันนี้พร้อมแล้ว',
  });

  String get userLevelRegularWelcome => _t({
    'ko': '🎨 카드 디자인·폰트를 마음껏 꾸밀 수 있어요',
    'en': '🎨 Customize paper and fonts freely',
    'ja': '🎨 便箋・フォントを自由にカスタマイズ',
    'zh': '🎨 自由定制信纸与字体',
    'fr': '🎨 Personnalisez papier et polices librement',
    'de': '🎨 Papier und Schriftarten nach Belieben anpassen',
    'es': '🎨 Personaliza papel y fuentes libremente',
    'pt': '🎨 Personalize papel e fontes livremente',
    'ru': '🎨 Настройте бумагу и шрифты',
    'tr': '🎨 Kağıt ve yazı tipini istediğin gibi özelleştir',
    'ar': '🎨 خصّص الورق والخطوط بحرية',
    'it': '🎨 Personalizza carta e font liberamente',
    'hi': '🎨 कागज़ और फ़ॉन्ट मनपसंद चुनें',
    'th': '🎨 ปรับแต่งกระดาษและฟอนต์ได้ตามใจ',
  });

  String get userLevelExperiencedWelcome => _t({
    'ko': '🌍 주변 혜택 줍기와 DM 이 열렸어요',
    'en': '🌍 Nearby pickup and DM are now open',
    'ja': '🌍 近くの手紙拾いとDMが解放されました',
    'zh': '🌍 附近拾取和私信已开放',
    'fr': '🌍 Ramassage local et DM maintenant ouverts',
    'de': '🌍 Briefabholung in der Nähe und DM freigeschaltet',
    'es': '🌍 Recogida cercana y DM disponibles',
    'pt': '🌍 Coleta próxima e DM disponíveis',
    'ru': '🌍 Сбор поблизости и личные сообщения открыты',
    'tr': '🌍 Yakındaki toplama ve DM açıldı',
    'ar': '🌍 تم فتح الالتقاط القريب والرسائل الخاصة',
    'it': '🌍 Raccolta vicina e DM ora disponibili',
    'hi': '🌍 आस-पास संग्रह और DM अब खुले',
    'th': '🌍 เก็บจดหมายใกล้ตัวและ DM เปิดแล้ว',
  });

  // ── 이번 달의 도시 ──────────────────────────────────────────────────────
  String cityOfMonthBadge(int month) => _t({
    'ko': '$month월의 도시', 'en': 'City of month $month', 'ja': '$month月の都市',
    'zh': '$month月之城', 'fr': 'Ville du mois $month',
    'de': 'Stadt des Monats $month', 'es': 'Ciudad del mes $month',
    'pt': 'Cidade do mês $month', 'ru': 'Город месяца $month',
    'tr': '$month. ay şehri', 'ar': 'مدينة الشهر $month',
    'it': 'Città del mese $month', 'hi': '$month महीने का शहर',
    'th': 'เมืองประจำเดือนที่ $month',
  });

  String get cityOfMonthCta => _t({
    'ko': '이 도시로 홍보 쓰기',
    'en': 'Write a promo to this city',
    'ja': 'この都市に手紙を書く',
    'zh': '写信给这座城市',
    'fr': 'Écrire une lettre à cette ville',
    'de': 'Einen Brief an diese Stadt schreiben',
    'es': 'Escribir una carta a esta ciudad',
    'pt': 'Escrever uma carta para esta cidade',
    'ru': 'Написать письмо этому городу',
    'tr': 'Bu şehre mektup yaz',
    'ar': 'اكتب رسالة لهذه المدينة',
    'it': 'Scrivi una lettera a questa città',
    'hi': 'इस शहर को पत्र लिखें',
    'th': 'เขียนจดหมายถึงเมืองนี้',
  });

  // ── 공유 카드 ───────────────────────────────────────────────────────────
  String shareCardHeader(String country) => _t({
    'ko': '$country에서 혜택이 도착했어요',
    'en': 'A reward arrived from $country',
    'ja': '$countryから手紙が届きました',
    'zh': '来自$country的信件已送达',
    'fr': 'Une lettre est arrivée de $country',
    'de': 'Ein Brief aus $country ist angekommen',
    'es': 'Llegó una carta desde $country',
    'pt': 'Uma carta chegou de $country',
    'ru': 'Пришло письмо из $country',
    'tr': '$country\'den bir mektup geldi',
    'ar': 'وصلت رسالة من $country',
    'it': 'È arrivata una lettera da $country',
    'hi': '$country से एक पत्र आया',
    'th': 'จดหมายจาก$countryมาถึงแล้ว',
  });

  String shareCardDistance(String km) => _t({
    'ko': '약 $km km 여행했어요',
    'en': 'Traveled ~$km km',
    'ja': '約$km km の旅',
    'zh': '旅行约$km km',
    'fr': 'Voyage de ~$km km',
    'de': 'Reise ~$km km',
    'es': 'Viajó ~$km km',
    'pt': 'Viajou ~$km km',
    'ru': 'Преодолело ~$km км',
    'tr': '~$km km yol aldı',
    'ar': 'قطعت حوالي $km كم',
    'it': 'Ha percorso ~$km km',
    'hi': '~$km km का सफ़र',
    'th': 'เดินทาง ~$km กม.',
  });

  // ── 일반 공유 액션 라벨 ──────────────────────────────────────────────────
  String get shareAction => _t({
    'ko': '공유', 'en': 'Share', 'ja': '共有', 'zh': '分享',
    'fr': 'Partager', 'de': 'Teilen', 'es': 'Compartir',
    'pt': 'Compartilhar', 'ru': 'Поделиться', 'tr': 'Paylaş',
    'ar': 'مشاركة', 'it': 'Condividi', 'hi': 'शेयर', 'th': 'แชร์',
  });

  // ── 나의 여정 (Journey) ──────────────────────────────────────────────────
  String get journeyTitle => _t({
    'ko': '나의 여정',
    'en': 'My Journey',
    'ja': '私の旅',
    'zh': '我的旅程',
    'fr': 'Mon voyage',
    'de': 'Meine Reise',
    'es': 'Mi viaje',
    'pt': 'Minha jornada',
    'ru': 'Моё путешествие',
    'tr': 'Yolculuğum',
    'ar': 'رحلتي',
    'it': 'Il mio viaggio',
    'hi': 'मेरी यात्रा',
    'th': 'การเดินทางของฉัน',
  });

  String get journeyStatSent => _t({
    'ko': '보낸 혜택', 'en': 'Sent', 'ja': '送信', 'zh': '发送',
    'fr': 'Envoyées', 'de': 'Gesendet', 'es': 'Enviadas',
    'pt': 'Enviadas', 'ru': 'Отправлено', 'tr': 'Gönderilen',
    'ar': 'مُرسلة', 'it': 'Inviate', 'hi': 'भेजे', 'th': 'ส่งแล้ว',
  });

  String get journeyStatCountries => _t({
    'ko': '방문 나라',
    'en': 'Countries',
    'ja': '訪れた国',
    'zh': '到过的国家',
    'fr': 'Pays',
    'de': 'Länder',
    'es': 'Países',
    'pt': 'Países',
    'ru': 'Страны',
    'tr': 'Ülkeler',
    'ar': 'الدول',
    'it': 'Paesi',
    'hi': 'देश',
    'th': 'ประเทศ',
  });

  String get journeyStatReplies => _t({
    'ko': '답장', 'en': 'Replies', 'ja': '返信', 'zh': '回信',
    'fr': 'Réponses', 'de': 'Antworten', 'es': 'Respuestas',
    'pt': 'Respostas', 'ru': 'Ответы', 'tr': 'Yanıtlar',
    'ar': 'الردود', 'it': 'Risposte', 'hi': 'जवाब', 'th': 'ตอบกลับ',
  });

  String get journeyLongestDistance => _t({
    'ko': '가장 멀리 떠난 혜택',
    'en': 'Farthest promo sent',
    'ja': '最も遠くまで届いた手紙',
    'zh': '最远抵达的信件',
    'fr': 'Lettre la plus lointaine',
    'de': 'Weitester Brief',
    'es': 'Carta más lejana',
    'pt': 'Carta mais distante',
    'ru': 'Самое дальнее письмо',
    'tr': 'En uzak mektup',
    'ar': 'الرسالة الأبعد',
    'it': 'Lettera più lontana',
    'hi': 'सबसे दूर पहुँचा पत्र',
    'th': 'จดหมายที่ไกลที่สุด',
  });

  String journeyLongestDistanceValue(String km, String country) => _t({
    'ko': '$country까지 $km km',
    'en': '$km km to $country',
    'ja': '$countryまで$km km',
    'zh': '到$country $km km',
    'fr': '$km km jusqu\'à $country',
    'de': '$km km nach $country',
    'es': '$km km hasta $country',
    'pt': '$km km até $country',
    'ru': '$km км до $country',
    'tr': '$country\'a $km km',
    'ar': '$km كم إلى $country',
    'it': '$km km fino a $country',
    'hi': '$country तक $km km',
    'th': 'ถึง$country $km กม.',
  });

  String journeyLongestStreak(int days) => _t({
    'ko': '최장 연속 접속 $days일',
    'en': 'Longest streak: $days days',
    'ja': '最長連続アクセス $days日',
    'zh': '最长连续签到 $days 天',
    'fr': 'Plus longue série : $days jours',
    'de': 'Längste Serie: $days Tage',
    'es': 'Racha más larga: $days días',
    'pt': 'Sequência mais longa: $days dias',
    'ru': 'Самая долгая серия: $days дней',
    'tr': 'En uzun seri: $days gün',
    'ar': 'أطول سلسلة: $days يومًا',
    'it': 'Serie più lunga: $days giorni',
    'hi': 'सबसे लंबा सिलसिला: $days दिन',
    'th': 'สตรีคที่ยาวที่สุด $days วัน',
  });

  // ── Air Mail Pass 서브브랜드 ────────────────────────────────────────────
  /// 사용자 노출 브랜드명. 내부 코드·결제 플로우는 여전히 "Premium" 유지
  /// 하지만 UI 상단 타이틀은 "항공우편 패스 (Air Mail Pass)" 로 표기.
  String get airMailPassLabel => _t({
    'ko': '항공우편 패스',
    'en': 'Air Mail Pass',
    'ja': 'エアメールパス',
    'zh': '航空邮件通',
    'fr': 'Pass Courrier Aérien',
    'de': 'Luftpost Pass',
    'es': 'Pase de Correo Aéreo',
    'pt': 'Passe de Correio Aéreo',
    'ru': 'Авиапочтовый Пропуск',
    'tr': 'Hava Posta Paso',
    'ar': 'تذكرة البريد الجوي',
    'it': 'Pass Posta Aerea',
    'hi': 'एयर मेल पास',
    'th': 'บัตรจดหมายทางอากาศ',
  });

  String get airMailPassTagline => _t({
    'ko': '무제한 하늘길 · 이미지 홍보 · 특급 배송',
    'en': 'Unlimited sky · image promos · express delivery',
    'ja': '無制限の空路・画像手紙・特急配達',
    'zh': '无限航线 · 图片信件 · 特快配送',
    'fr': 'Ciel illimité · lettres avec image · livraison express',
    'de': 'Unbegrenzter Himmel · Bildbriefe · Express-Zustellung',
    'es': 'Cielo ilimitado · cartas con imagen · entrega exprés',
    'pt': 'Céu ilimitado · cartas com imagem · entrega expressa',
    'ru': 'Безлимитное небо · письма с фото · экспресс-доставка',
    'tr': 'Sınırsız gökyüzü · resimli mektuplar · hızlı teslimat',
    'ar': 'سماء بلا حدود · رسائل مصوّرة · توصيل سريع',
    'it': 'Cielo illimitato · lettere con immagine · consegna express',
    'hi': 'असीम आकाश · चित्र सहित पत्र · एक्सप्रेस डिलीवरी',
    'th': 'ท้องฟ้าไร้ขีดจำกัด · จดหมายมีภาพ · จัดส่งด่วน',
  });

  // ── 편지 맥락 배지 ──────────────────────────────────────────────────────
  String letterContextReceivedOrdinal(int n) => _t({
    'ko': '당신이 받은 $n번째 혜택',
    'en': 'Your ${_ordinalEn(n)} received reward',
    'ja': 'あなたの受け取った$n通目の手紙',
    'zh': '你收到的第 $n 封信',
    'fr': '$n${_ordinalFr(n)} lettre reçue',
    'de': 'Dein $n. empfangener Brief',
    'es': 'Tu $n.ª carta recibida',
    'pt': 'Sua $n.ª carta recebida',
    'ru': 'Ваше $n-е полученное письмо',
    'tr': '$n. aldığınız mektup',
    'ar': 'الرسالة رقم $n التي استلمتها',
    'it': 'La tua $n.ª lettera ricevuta',
    'hi': 'आपका $n पत्र (प्राप्त)',
    'th': 'จดหมายฉบับที่ $n ที่คุณได้รับ',
  });

  String letterContextFirstFromCountry(String country) => _t({
    'ko': '$country에서 온 첫 혜택이에요',
    'en': 'Your first reward from $country',
    'ja': '$countryからの最初の手紙',
    'zh': '来自$country的第一封信',
    'fr': 'Première lettre de $country',
    'de': 'Erster Brief aus $country',
    'es': 'Tu primera carta de $country',
    'pt': 'Sua primeira carta de $country',
    'ru': 'Первое письмо из $country',
    'tr': '$country\'den ilk mektup',
    'ar': 'أول رسالة لك من $country',
    'it': 'La tua prima lettera da $country',
    'hi': '$country से पहला पत्र',
    'th': 'จดหมายฉบับแรกจาก$country',
  });

  String letterContextNthFromCountry(int n, String country) => _t({
    'ko': '$country에서 온 $n번째 혜택',
    'en': 'Your ${_ordinalEn(n)} reward from $country',
    'ja': '$countryからの$n通目の手紙',
    'zh': '来自$country的第 $n 封信',
    'fr': '$n${_ordinalFr(n)} lettre de $country',
    'de': '$n. Brief aus $country',
    'es': 'Tu $n.ª carta de $country',
    'pt': 'Sua $n.ª carta de $country',
    'ru': '$n-е письмо из $country',
    'tr': '$country\'den $n. mektup',
    'ar': 'الرسالة رقم $n من $country',
    'it': 'La tua $n.ª lettera da $country',
    'hi': '$country से $n पत्र',
    'th': 'จดหมายฉบับที่ $n จาก$country',
  });

  static String _ordinalEn(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1: return '${n}st';
      case 2: return '${n}nd';
      case 3: return '${n}rd';
      default: return '${n}th';
    }
  }

  static String _ordinalFr(int n) => n == 1 ? 're' : 'e';

  // ── 빈 상태 CTA ─────────────────────────────────────────────────────────
  String get emptyStateWriteCta => _t({
    'ko': '첫 홍보 쓰기',
    'en': 'Write your first promo',
    'ja': '最初の手紙を書く',
    'zh': '写下第一封信',
    'fr': 'Écrire votre première lettre',
    'de': 'Ersten Brief schreiben',
    'es': 'Escribir tu primera carta',
    'pt': 'Escrever sua primeira carta',
    'ru': 'Написать первое письмо',
    'tr': 'İlk mektubunuzu yazın',
    'ar': 'اكتب رسالتك الأولى',
    'it': 'Scrivi la tua prima lettera',
    'hi': 'पहला पत्र लिखें',
    'th': 'เขียนจดหมายฉบับแรก',
  });

  // 🎯 오늘의 영감 통합 카드 헤더 — 요일 테마 + 퀵픽 + 월별 도시를 한 카드로
  String get composeInspirationHeader => _t({
    'ko': '오늘의 영감',
    'en': "Today's inspiration",
    'ja': '今日のインスピレーション',
    'zh': '今日灵感',
    'fr': 'Inspiration du jour',
    'de': 'Inspiration des Tages',
    'es': 'Inspiración de hoy',
    'pt': 'Inspiração de hoje',
    'ru': 'Сегодняшнее вдохновение',
    'tr': 'Bugünün ilhamı',
    'ar': 'إلهام اليوم',
    'it': "Ispirazione di oggi",
    'hi': 'आज की प्रेरणा',
    'th': 'แรงบันดาลใจวันนี้',
  });

  // 🎯 현재 레벨의 줍기 반경 보너스 — 프로필 XP 카드 하단
  String xpPickupBonusDesc(int radius, int bonus) {
    switch (languageCode) {
      case 'ko':
        return '줍기 반경 ${radius}m (레벨 보너스 +${bonus}m)';
      case 'en':
        return 'Pickup radius ${radius}m (level bonus +${bonus}m)';
      case 'ja':
        return '拾える範囲 ${radius}m (レベルボーナス +${bonus}m)';
      case 'zh':
        return '拾取范围 ${radius}m (等级加成 +${bonus}m)';
      case 'fr':
        return 'Rayon ${radius}m (bonus de niveau +${bonus}m)';
      case 'de':
        return 'Aufhebradius ${radius}m (Level-Bonus +${bonus}m)';
      case 'es':
        return 'Radio ${radius}m (bonus de nivel +${bonus}m)';
      case 'pt':
        return 'Raio ${radius}m (bónus de nível +${bonus}m)';
      case 'ru':
        return 'Радиус ${radius}м (бонус уровня +${bonus}м)';
      case 'tr':
        return 'Yarıçap ${radius}m (seviye bonusu +${bonus}m)';
      case 'ar':
        return 'نطاق ${radius} م (مكافأة المستوى +${bonus} م)';
      case 'it':
        return 'Raggio ${radius}m (bonus livello +${bonus}m)';
      case 'hi':
        return 'पिकअप ${radius}मी (स्तर बोनस +${bonus}मी)';
      case 'th':
        return 'รัศมี ${radius}ม (โบนัสระดับ +${bonus}ม)';
      default:
        return 'Pickup radius ${radius}m (+${bonus}m level bonus)';
    }
  }

  // 🪙 Level 50 도달 후 포인트 적립 라벨
  String xpPointsLabel(int points) {
    switch (languageCode) {
      case 'ko':
        return '적립 포인트 · $points P';
      case 'en':
        return 'Earned · $points pts';
      case 'ja':
        return '積立 · $points P';
      case 'zh':
        return '积分 · $points 点';
      case 'fr':
        return 'Points · $points';
      case 'de':
        return 'Punkte · $points';
      case 'es':
        return 'Puntos · $points';
      case 'pt':
        return 'Pontos · $points';
      case 'ru':
        return 'Очки · $points';
      case 'tr':
        return 'Puanlar · $points';
      case 'ar':
        return 'النقاط · $points';
      case 'it':
        return 'Punti · $points';
      case 'hi':
        return 'पॉइंट्स · $points';
      case 'th':
        return 'คะแนน · $points';
      default:
        return 'Earned · $points pts';
    }
  }

  String get xpPointsHint => _t({
    'ko': '구독 시 사용',
    'en': 'Use on subscription',
    'ja': '購読時に利用',
    'zh': '订阅时使用',
    'fr': 'Utilisable sur abonnement',
    'de': 'Für Abo einlösbar',
    'es': 'Usable en suscripción',
    'pt': 'Usável na subscrição',
    'ru': 'Для подписки',
    'tr': 'Abonelikte kullan',
    'ar': 'استخدامها في الاشتراك',
    'it': 'Utilizzabili per abbonamento',
    'hi': 'सदस्यता पर उपयोग',
    'th': 'ใช้ตอนสมัคร',
  });

  // 레벨 마일스톤 바텀시트 — 프로필의 🏆 버튼으로 열림
  String get xpMilestonesSheetOpen => _t({
    'ko': '레벨 마일스톤 보기',
    'en': 'View level milestones',
    'ja': 'レベルマイルストーンを見る',
    'zh': '查看等级里程碑',
    'fr': 'Voir les paliers de niveau',
    'de': 'Level-Meilensteine ansehen',
    'es': 'Ver hitos de nivel',
    'pt': 'Ver marcos de nível',
    'ru': 'Посмотреть вехи уровней',
    'tr': 'Seviye kilometre taşlarını gör',
    'ar': 'عرض محطات المستوى',
    'it': 'Vedi traguardi di livello',
    'hi': 'स्तर मील के पत्थर देखें',
    'th': 'ดูเป้าหมายระดับ',
  });

  String get xpMilestonesTitle => _t({
    'ko': '레벨 1 → 50 여정',
    'en': 'Level 1 → 50 Journey',
    'ja': 'レベル 1 → 50 の旅',
    'zh': '等级 1 → 50 之旅',
    'fr': 'Voyage niveau 1 → 50',
    'de': 'Reise: Level 1 → 50',
    'es': 'Viaje Nivel 1 → 50',
    'pt': 'Jornada Nível 1 → 50',
    'ru': 'Путь Уровень 1 → 50',
    'tr': 'Seviye 1 → 50 Yolculuğu',
    'ar': 'رحلة المستوى 1 → 50',
    'it': 'Viaggio Livello 1 → 50',
    'hi': 'स्तर 1 → 50 यात्रा',
    'th': 'การเดินทางเลเวล 1 → 50',
  });

  String get xpMilestonesSubtitle => _t({
    'ko': '5 레벨마다 등급이 진화해요. 혜택을 더 많이 주울수록, 멀리 보낼수록 빨라져요.',
    'en': 'Your tier evolves every 5 levels. Pick up more, send further — climb faster.',
    'ja': '5レベルごとに称号が進化します。多く拾い、遠くへ送るほど早く上がります。',
    'zh': '每 5 级称号进化。拾得越多、送得越远，晋升越快。',
    'fr': 'Votre rang évolue tous les 5 niveaux. Plus vous ramassez et envoyez loin, plus vite vous montez.',
    'de': 'Dein Rang entwickelt sich alle 5 Level. Mehr sammeln und weiter senden lässt dich schneller aufsteigen.',
    'es': 'Tu rango evoluciona cada 5 niveles. Recoger más y enviar más lejos acelera tu ascenso.',
    'pt': 'O teu nível evolui a cada 5 níveis. Apanhar mais e enviar mais longe acelera a subida.',
    'ru': 'Титул повышается каждые 5 уровней. Собирайте больше, отправляйте дальше — растите быстрее.',
    'tr': 'Rütbe her 5 seviyede evrilir. Daha çok topla, daha uzağa gönder, daha hızlı yüksel.',
    'ar': 'تتطور رتبتك كل 5 مستويات. التقط أكثر وأرسل أبعد لترتفع أسرع.',
    'it': 'Il tuo grado evolve ogni 5 livelli. Raccogli di più e invia più lontano per salire più veloce.',
    'hi': 'हर 5 स्तर पर आपका रैंक विकसित होता है. अधिक उठाएँ और दूर भेजें — तेज़ी से बढ़ें.',
    'th': 'ยศจะพัฒนาทุก 5 ระดับ ยิ่งเก็บและส่งไกล ยิ่งไปเร็ว',
  });

  String xpMilestoneTierLabel(int fromLevel, int toLevel) {
    switch (languageCode) {
      case 'ko':
        return 'Lv $fromLevel–$toLevel';
      case 'ja':
      case 'zh':
        return 'Lv $fromLevel–$toLevel';
      default:
        return 'Lv $fromLevel–$toLevel';
    }
  }

  String xpMilestoneXpReq(int xp) {
    switch (languageCode) {
      case 'ko':
        return '필요 XP · $xp+';
      case 'en':
        return 'Required XP · $xp+';
      case 'ja':
        return '必要 XP · $xp+';
      case 'zh':
        return '所需 XP · $xp+';
      case 'fr':
        return 'XP requis · $xp+';
      case 'de':
        return 'Benötigte XP · $xp+';
      case 'es':
        return 'XP requerida · $xp+';
      case 'pt':
        return 'XP necessário · $xp+';
      case 'ru':
        return 'Нужно XP · $xp+';
      case 'tr':
        return 'Gerekli XP · $xp+';
      case 'ar':
        return 'XP المطلوب · $xp+';
      case 'it':
        return 'XP richiesti · $xp+';
      case 'hi':
        return 'आवश्यक XP · $xp+';
      case 'th':
        return 'XP ที่ต้องการ · $xp+';
      default:
        return 'Required XP · $xp+';
    }
  }

  String get xpMilestoneCurrent => _t({
    'ko': '지금 여기',
    'en': 'You are here',
    'ja': '現在',
    'zh': '当前',
    'fr': 'Vous êtes ici',
    'de': 'Du bist hier',
    'es': 'Estás aquí',
    'pt': 'Está aqui',
    'ru': 'Вы здесь',
    'tr': 'Buradasın',
    'ar': 'أنت هنا',
    'it': 'Sei qui',
    'hi': 'आप यहाँ हैं',
    'th': 'คุณอยู่ที่นี่',
  });

  String xpMilestonesFootnote(int currentXp) {
    switch (languageCode) {
      case 'ko':
        return '현재 XP · $currentXp · 혜택 줍기 +10, 발송 +5, 거리 보너스.';
      case 'en':
        return 'Current XP · $currentXp · Pick up +10, send +5, distance bonus.';
      case 'ja':
        return '現在のXP · $currentXp · 拾う+10、送信+5、距離ボーナス。';
      case 'zh':
        return '当前 XP · $currentXp · 拾起+10、发送+5、距离奖励。';
      case 'fr':
        return 'XP actuel · $currentXp · Ramasser +10, envoyer +5, bonus distance.';
      case 'de':
        return 'Aktuelle XP · $currentXp · Aufheben +10, Senden +5, Distanz-Bonus.';
      case 'es':
        return 'XP actual · $currentXp · Recoger +10, enviar +5, bono distancia.';
      case 'pt':
        return 'XP atual · $currentXp · Apanhar +10, enviar +5, bónus distância.';
      case 'ru':
        return 'Текущий XP · $currentXp · Подбор +10, отправка +5, бонус за расстояние.';
      case 'tr':
        return 'Mevcut XP · $currentXp · Topla +10, gönder +5, mesafe bonusu.';
      case 'ar':
        return 'XP الحالي · $currentXp · التقاط +10، إرسال +5، مكافأة مسافة.';
      case 'it':
        return 'XP attuali · $currentXp · Raccogli +10, invia +5, bonus distanza.';
      case 'hi':
        return 'वर्तमान XP · $currentXp · उठाएँ +10, भेजें +5, दूरी बोनस.';
      case 'th':
        return 'XP ปัจจุบัน · $currentXp · เก็บ +10, ส่ง +5, โบนัสระยะทาง.';
      default:
        return 'Current XP · $currentXp · Pick up +10, send +5, distance bonus.';
    }
  }

  // 헌트 모드 필터(할인권·교환권·브랜드)에서 홍보 쓰기 대신 탐험 탭으로 유도
  String get emptyStateExploreCta => _t({
    'ko': '지도에서 찾아보기',
    'en': 'Find on the map',
    'ja': '地図で探す',
    'zh': '在地图上寻找',
    'fr': 'Chercher sur la carte',
    'de': 'Auf der Karte finden',
    'es': 'Buscar en el mapa',
    'pt': 'Procurar no mapa',
    'ru': 'Искать на карте',
    'tr': 'Haritada bul',
    'ar': 'ابحث على الخريطة',
    'it': 'Cerca sulla mappa',
    'hi': 'मानचित्र पर ढूंढें',
    'th': 'ค้นหาบนแผนที่',
  });

  // ── Build 211: i18n keys for Build 205-210 hardcoded strings ─────────────

  // Tower benefits popup (Build 205)
  String get towerBenefitsTitle => _t({
    'ko': '내 카운터 성장 가이드', 'en': 'Your Counter Growth Guide', 'ja': 'カウンター成長ガイド', 'zh': '我的信件成长指南',
    'fr': 'Votre guide de croissance Letter', 'de': 'Dein Letter-Wachstumsleitfaden', 'es': 'Guía de crecimiento de tu carta',
    'pt': 'Guia de crescimento da carta', 'ru': 'Руководство роста', 'tr': 'Letter Büyüme Rehberi',
    'ar': 'دليل نمو الرسائل', 'it': 'Guida crescita Letter', 'hi': 'लेटर ग्रोथ गाइड', 'th': 'คู่มือการเติบโตของเลตเตอร์',
  });

  String get towerBenefitsLevelUpSection => _t({
    'ko': '레벨업으로 얻는 것', 'en': 'What level-ups unlock', 'ja': 'レベルアップで得られるもの', 'zh': '升级解锁内容',
    'fr': 'Récompenses de niveau', 'de': 'Level-Up Belohnungen', 'es': 'Recompensas por subir de nivel',
    'pt': 'Recompensas de nível', 'ru': 'Награды за уровень', 'tr': 'Seviye atlama ödülleri',
    'ar': 'مكافآت المستوى', 'it': 'Ricompense livello', 'hi': 'स्तर पुरस्कार', 'th': 'รางวัลเลเวลอัพ',
  });

  String get towerBenefitsBulletRadius => _t({
    'ko': '픽업 반경 확장 — 레벨당 +10m', 'en': 'Pickup radius expands — +10m per level', 'ja': 'ピックアップ範囲拡大 — レベルごとに+10m', 'zh': '拾取半径扩展 — 每级+10m',
    'fr': 'Rayon de ramassage +10m par niveau', 'de': 'Abholradius +10m pro Level', 'es': 'Radio de recogida +10m por nivel',
    'pt': 'Raio +10m por nível', 'ru': 'Радиус +10м за уровень', 'tr': 'Toplama yarıçapı +10m / seviye',
    'ar': 'نطاق الالتقاط +10م لكل مستوى', 'it': 'Raggio +10m per livello', 'hi': 'पिकअप +10m प्रति स्तर', 'th': 'รัศมีรับ +10m/เลเวล',
  });

  String get towerBenefitsBulletTitles => _t({
    'ko': '명예 호칭 진화 — 견습→숙련→…→전설의 카운터', 'en': 'Title evolves — Apprentice → … → Legendary', 'ja': '称号進化 — 見習い→…→伝説', 'zh': '称号进化 — 学徒→…→传奇',
    'fr': 'Titres évoluent — Apprenti → … → Légendaire', 'de': 'Titel entwickeln sich', 'es': 'Títulos evolucionan',
    'pt': 'Títulos evoluem', 'ru': 'Звания развиваются', 'tr': 'Unvanlar gelişir',
    'ar': 'الألقاب تتطور', 'it': 'Titoli evolvono', 'hi': 'उपाधियाँ विकसित होती हैं', 'th': 'ฉายาก้าวหน้า',
  });

  String get towerBenefitsBulletUnlocks => _t({
    'ko': '캐릭터/컴패니언/악세사리 해금', 'en': 'Unlock characters / companions / accessories', 'ja': 'キャラクター/コンパニオン/アクセサリー解放', 'zh': '解锁角色/伙伴/配饰',
    'fr': 'Personnages/compagnons/accessoires', 'de': 'Charaktere/Begleiter/Accessoires', 'es': 'Personajes/compañeros/accesorios',
    'pt': 'Personagens/companheiros/acessórios', 'ru': 'Персонажи/спутники/аксессуары', 'tr': 'Karakter/yoldaş/aksesuar',
    'ar': 'شخصيات/رفقاء/إكسسوارات', 'it': 'Personaggi/compagni/accessori', 'hi': 'पात्र/साथी/सहायक', 'th': 'ตัวละคร/คู่หู/ของประดับ',
  });

  String get towerBenefitsTierSection => _t({
    'ko': '내 회원 등급 혜택', 'en': 'Your tier benefits', 'ja': '会員等級特典', 'zh': '会员等级权益',
    'fr': 'Avantages selon votre niveau', 'de': 'Vorteile deiner Stufe', 'es': 'Beneficios de tu nivel',
    'pt': 'Benefícios do seu nível', 'ru': 'Преимущества уровня', 'tr': 'Üyelik avantajları',
    'ar': 'مزايا الفئة', 'it': 'Vantaggi del tuo livello', 'hi': 'टियर लाभ', 'th': 'สิทธิ์ตามระดับ',
  });

  String get towerBenefitsFreeFeat1 => _t({
    'ko': '혜택 줍기 200m 반경', 'en': 'Pickup within 200m radius', 'ja': '200m範囲で手紙を拾える', 'zh': '200m半径拾取',
    'fr': 'Ramassage 200m', 'de': 'Abholung 200m', 'es': 'Recogida 200m',
    'pt': 'Coleta 200m', 'ru': 'Подбор 200м', 'tr': '200m içinde toplama',
    'ar': 'نطاق 200م', 'it': 'Raccolta 200m', 'hi': '200m पिकअप', 'th': 'รับในรัศมี 200m',
  });

  String get towerBenefitsFreeFeat2 => _t({
    'ko': '60분 쿨다운', 'en': '60min cooldown', 'ja': '60分クールダウン', 'zh': '60分钟冷却',
    'fr': 'Délai 60min', 'de': '60min Cooldown', 'es': 'Espera 60min',
    'pt': 'Espera 60min', 'ru': 'Ожидание 60мин', 'tr': '60dk bekleme',
    'ar': 'تبريد 60د', 'it': 'Attesa 60min', 'hi': '60मि कूलडाउन', 'th': 'พัก 60 นาที',
  });

  String get towerBenefitsFreeFeat3 => _t({
    'ko': '받은 혜택 답장은 가능', 'en': 'Replies to received rewards allowed', 'ja': '受信した手紙への返信可能', 'zh': '可回复已收信件',
    'fr': 'Réponses possibles', 'de': 'Antworten möglich', 'es': 'Respuestas posibles',
    'pt': 'Respostas possíveis', 'ru': 'Можно отвечать', 'tr': 'Yanıt verilebilir',
    'ar': 'يمكن الرد', 'it': 'Risposte consentite', 'hi': 'उत्तर देना संभव', 'th': 'ตอบจดหมายได้',
  });

  String get towerBenefitsPremiumFeat1 => _t({
    'ko': '혜택 줍기 1km 반경 + 10분 쿨다운', 'en': '1km pickup radius + 10min cooldown', 'ja': '1kmピックアップ + 10分クールダウン', 'zh': '1km半径 + 10分钟冷却',
    'fr': 'Ramassage 1km, 10min', 'de': '1km Abholung + 10min', 'es': 'Recogida 1km + 10min',
    'pt': 'Coleta 1km + 10min', 'ru': 'Подбор 1км + 10мин', 'tr': '1km alma + 10dk',
    'ar': 'نطاق 1كم + 10د', 'it': 'Raccolta 1km + 10min', 'hi': '1km पिकअप + 10मि', 'th': 'รับ 1km + 10นาที',
  });

  String get towerBenefitsPremiumFeat2 => _t({
    'ko': '📸 사진 첨부 + 🔗 채널/SNS 링크 발송', 'en': '📸 Photo + 🔗 social link sending', 'ja': '📸 写真 + 🔗 SNSリンク送信', 'zh': '📸 照片 + 🔗 社交链接发送',
    'fr': '📸 Photo + 🔗 lien social', 'de': '📸 Foto + 🔗 Social Link', 'es': '📸 Foto + 🔗 enlace social',
    'pt': '📸 Foto + 🔗 link social', 'ru': '📸 Фото + 🔗 ссылка', 'tr': '📸 Fotoğraf + 🔗 sosyal bağlantı',
    'ar': '📸 صورة + 🔗 رابط', 'it': '📸 Foto + 🔗 link social', 'hi': '📸 फोटो + 🔗 लिंक', 'th': '📸 รูป + 🔗 ลิงก์',
  });

  String get towerBenefitsPremiumFeat3 => _t({
    'ko': '일 30통 / 월 500통 발송', 'en': '30/day · 500/month send quota', 'ja': '日30通 / 月500通', 'zh': '日30 / 月500',
    'fr': '30/jour · 500/mois', 'de': '30/Tag · 500/Monat', 'es': '30/día · 500/mes',
    'pt': '30/dia · 500/mês', 'ru': '30/день · 500/мес', 'tr': '30/gün · 500/ay',
    'ar': '30/يوم · 500/شهر', 'it': '30/giorno · 500/mese', 'hi': '30/दिन · 500/माह', 'th': '30/วัน · 500/เดือน',
  });

  String get towerBenefitsBrandFeat1 => _t({
    'ko': '🎟 할인권 · 🎁 교환권 캠페인 발송', 'en': '🎟 Coupon · 🎁 Voucher campaigns', 'ja': '🎟 割引券 · 🎁 引換券キャンペーン', 'zh': '🎟 优惠券 · 🎁 兑换券推广',
    'fr': '🎟 Coupon · 🎁 Bon campagnes', 'de': '🎟 Gutschein · 🎁 Voucher Kampagnen', 'es': '🎟 Cupón · 🎁 Vale campañas',
    'pt': '🎟 Cupom · 🎁 Voucher campanhas', 'ru': '🎟 Купон · 🎁 Ваучер кампании', 'tr': '🎟 Kupon · 🎁 Voucher kampanyaları',
    'ar': '🎟 قسيمة · 🎁 سند حملات', 'it': '🎟 Coupon · 🎁 Voucher campagne', 'hi': '🎟 कूपन · 🎁 वाउचर अभियान', 'th': '🎟 คูปอง · 🎁 บัตรกำนัล',
  });

  String get towerBenefitsBrandFeat2 => _t({
    'ko': '🎯 정확한 위치 지정 · 대량 발송', 'en': '🎯 Exact-drop · bulk sending', 'ja': '🎯 正確な位置指定 · 一括送信', 'zh': '🎯 精确位置 · 批量发送',
    'fr': '🎯 Drop exact · envoi en masse', 'de': '🎯 Exakter Drop · Massenversand', 'es': 'Drop exacto · envío masivo',
    'pt': 'Drop exato · envio em massa', 'ru': 'Точная точка · массовая рассылка', 'tr': 'Tam konum · toplu gönderim',
    'ar': '🎯 موقع دقيق · إرسال جماعي', 'it': '🎯 Drop esatto · invio in massa', 'hi': '🎯 सटीक · बल्क', 'th': '🎯 ตำแหน่ง · ส่งจำนวนมาก',
  });

  String get towerBenefitsBrandFeat3 => _t({
    'ko': '일 200통 / 월 10,000통 + ROI 분석', 'en': '200/day · 10K/month + ROI analytics', 'ja': '日200 / 月10,000 + ROI分析', 'zh': '日200 / 月10K + ROI分析',
    'fr': '200/jour · 10K/mois + ROI', 'de': '200/Tag · 10K/Monat + ROI', 'es': '200/día · 10K/mes + ROI',
    'pt': '200/dia · 10K/mês + ROI', 'ru': '200/день · 10К/мес + ROI', 'tr': '200/gün · 10K/ay + ROI',
    'ar': '200/يوم · 10K/شهر + ROI', 'it': '200/giorno · 10K/mese + ROI', 'hi': '200/दिन · 10K/माह + ROI', 'th': '200/วัน · 10K/เดือน + ROI',
  });

  String get commonDontShowAgain => _t({
    'ko': '다시 보지 않기', 'en': "Don't show again", 'ja': '次回から表示しない', 'zh': '不再显示',
    'fr': 'Ne plus afficher', 'de': 'Nicht mehr anzeigen', 'es': 'No mostrar de nuevo',
    'pt': 'Não mostrar novamente', 'ru': 'Не показывать снова', 'tr': 'Tekrar gösterme',
    'ar': 'لا تظهر مرة أخرى', 'it': 'Non mostrare più', 'hi': 'फिर से न दिखाएँ', 'th': 'ไม่แสดงอีก',
  });

  String get commonConfirm => _t({
    'ko': '확인', 'en': 'OK', 'ja': '確認', 'zh': '确定',
    'fr': 'OK', 'de': 'OK', 'es': 'OK',
    'pt': 'OK', 'ru': 'ОК', 'tr': 'Tamam',
    'ar': 'موافق', 'it': 'OK', 'hi': 'ठीक है', 'th': 'ตกลง',
  });

  String get towerBenefitsMyTierBadge => _t({
    'ko': '내 등급', 'en': 'My tier', 'ja': '現在の等級', 'zh': '我的等级',
    'fr': 'Mon niveau', 'de': 'Mein Level', 'es': 'Mi nivel',
    'pt': 'Meu nível', 'ru': 'Мой уровень', 'tr': 'Seviyem',
    'ar': 'فئتي', 'it': 'Mio livello', 'hi': 'मेरा स्तर', 'th': 'ระดับของฉัน',
  });

  // PII linter (Build 207)
  String get piiLabelPhone => _t({
    'ko': '전화번호', 'en': 'Phone number', 'ja': '電話番号', 'zh': '电话号码',
    'fr': 'Numéro de téléphone', 'de': 'Telefonnummer', 'es': 'Número de teléfono',
    'pt': 'Número de telefone', 'ru': 'Телефон', 'tr': 'Telefon numarası',
    'ar': 'رقم الهاتف', 'it': 'Numero di telefono', 'hi': 'फोन नंबर', 'th': 'หมายเลขโทรศัพท์',
  });

  String get piiLabelKrRrn => _t({
    'ko': '주민등록번호', 'en': 'Resident registration number', 'ja': '住民登録番号', 'zh': '居民登记号码',
    'fr': 'Numéro d\'identité', 'de': 'Personalausweisnummer', 'es': 'DNI',
    'pt': 'Número de identidade', 'ru': 'ИНН', 'tr': 'Kimlik no',
    'ar': 'رقم الهوية', 'it': 'Codice fiscale', 'hi': 'पहचान संख्या', 'th': 'เลขประจำตัว',
  });

  String get piiLabelCard => _t({
    'ko': '카드번호', 'en': 'Card number', 'ja': 'カード番号', 'zh': '卡号',
    'fr': 'Numéro de carte', 'de': 'Kartennummer', 'es': 'Número de tarjeta',
    'pt': 'Número do cartão', 'ru': 'Номер карты', 'tr': 'Kart numarası',
    'ar': 'رقم البطاقة', 'it': 'Numero carta', 'hi': 'कार्ड नंबर', 'th': 'หมายเลขบัตร',
  });

  String piiDialogTitle(String label) => _t({
    'ko': '$label 가 포함됐어요', 'en': '$label detected', 'ja': '$label が含まれています', 'zh': '检测到$label',
    'fr': '$label détecté', 'de': '$label erkannt', 'es': '$label detectado',
    'pt': '$label detectado', 'ru': 'Найдено: $label', 'tr': '$label algılandı',
    'ar': 'تم الكشف عن $label', 'it': '$label rilevato', 'hi': '$label मिला', 'th': 'พบ $label',
  });

  String piiDialogBody(String label) => _t({
    'ko': '홍보 본문은 받는 사람이 누구나 읽을 수 있어요.\n$label 같은 개인정보는 빼고 보내는 게 안전해요.\n그래도 그대로 보낼까요?',
    'en': 'Promo content is publicly readable.\nIt is safer to remove $label before sending.\nSend it anyway?',
    'ja': '手紙本文は誰でも読めます。\n$label のような個人情報は除いた方が安全です。\nそのまま送りますか？',
    'zh': '信件正文任何人都能阅读。\n建议移除$label等个人信息。\n仍然发送吗？',
    'fr': 'Le contenu est public.\nMieux vaut retirer $label.\nEnvoyer quand même ?',
    'de': 'Briefinhalt ist öffentlich.\nBitte $label entfernen.\nTrotzdem senden?',
    'es': 'El contenido es público.\nQuita $label antes de enviar.\n¿Enviar igualmente?',
    'pt': 'O conteúdo é público.\nRemova $label antes.\nEnviar mesmo assim?',
    'ru': 'Текст письма публичен.\nЛучше убрать $label.\nОтправить всё равно?',
    'tr': 'Mektup içeriği herkese açık.\n$label kaldırın.\nYine de gönderilsin mi?',
    'ar': 'محتوى الرسالة عام.\nاحذف $label.\nأرسل على أي حال؟',
    'it': 'Il contenuto è pubblico.\nRimuovi $label prima.\nInvio comunque?',
    'hi': 'पत्र सार्वजनिक है।\n$label हटाएं।\nफिर भी भेजें?',
    'th': 'เนื้อหาเป็นสาธารณะ\nลบ $label\nส่งต่อไหม?',
  });

  String get piiSendAnyway => _t({
    'ko': '그래도 보내기', 'en': 'Send anyway', 'ja': 'そのまま送信', 'zh': '仍然发送',
    'fr': 'Envoyer quand même', 'de': 'Trotzdem senden', 'es': 'Enviar igualmente',
    'pt': 'Enviar mesmo assim', 'ru': 'Отправить', 'tr': 'Yine de gönder',
    'ar': 'أرسل على أي حال', 'it': 'Invia comunque', 'hi': 'फिर भी भेजें', 'th': 'ส่งต่อไป',
  });

  // Tower customizer (Brand-only, hardcoded since 2024) — Build 211 i18n.
  String get towerCustomizeTabVehicle => _t({
    'ko': '🚗 이동수단', 'en': '🚗 Vehicle', 'ja': '🚗 乗り物', 'zh': '🚗 交通工具',
    'fr': '🚗 Véhicule', 'de': '🚗 Fahrzeug', 'es': '🚗 Vehículo',
    'pt': '🚗 Veículo', 'ru': '🚗 Транспорт', 'tr': '🚗 Araç',
    'ar': '🚗 المركبة', 'it': '🚗 Veicolo', 'hi': '🚗 वाहन', 'th': '🚗 ยานพาหนะ',
  });

  String get towerCustomizeTabSkin => _t({
    'ko': '🏢 타워스킨', 'en': '🏢 Tower skin', 'ja': '🏢 タワースキン', 'zh': '🏢 塔皮肤',
    'fr': '🏢 Habillage', 'de': '🏢 Turmskin', 'es': '🏢 Apariencia',
    'pt': '🏢 Skin da torre', 'ru': '🏢 Внешний вид', 'tr': '🏢 Kule görünümü',
    'ar': '🏢 مظهر البرج', 'it': '🏢 Skin torre', 'hi': '🏢 टावर स्किन', 'th': '🏢 สกินหอคอย',
  });

  String get towerCustomizeVehicleSection => _t({
    'ko': '이동수단 장식', 'en': 'Vehicle decoration', 'ja': '乗り物装飾', 'zh': '交通工具装饰',
    'fr': 'Décoration véhicule', 'de': 'Fahrzeugdekoration', 'es': 'Decoración de vehículo',
    'pt': 'Decoração de veículo', 'ru': 'Транспорт декор', 'tr': 'Araç süslemesi',
    'ar': 'زخرفة المركبة', 'it': 'Decorazione veicolo', 'hi': 'वाहन सजावट', 'th': 'ตกแต่งยานพาหนะ',
  });

  String get towerCustomizeRoofSection => _t({
    'ko': '🏠 지붕 스타일', 'en': '🏠 Roof style', 'ja': '🏠 屋根スタイル', 'zh': '🏠 屋顶风格',
    'fr': '🏠 Style toit', 'de': '🏠 Dachstil', 'es': '🏠 Estilo de techo',
    'pt': '🏠 Estilo do telhado', 'ru': '🏠 Стиль крыши', 'tr': '🏠 Çatı stili',
    'ar': '🏠 نمط السقف', 'it': '🏠 Stile tetto', 'hi': '🏠 छत शैली', 'th': '🏠 รูปแบบหลังคา',
  });

  String get towerCustomizeWindowSection => _t({
    'ko': '🪟 창문 스타일', 'en': '🪟 Window style', 'ja': '🪟 窓スタイル', 'zh': '🪟 窗户风格',
    'fr': '🪟 Style fenêtre', 'de': '🪟 Fensterstil', 'es': '🪟 Estilo de ventana',
    'pt': '🪟 Estilo da janela', 'ru': '🪟 Стиль окон', 'tr': '🪟 Pencere stili',
    'ar': '🪟 نمط النافذة', 'it': '🪟 Stile finestra', 'hi': '🪟 खिड़की शैली', 'th': '🪟 รูปแบบหน้าต่าง',
  });

  /// 타워 커스터마이즈 항목 label 통합 lookup (vehicle/roof/window).
  /// 데이터 구조의 label 키(한국어) 를 받아 현재 언어로 변환.
  String towerItemLabel(String koreanKey) {
    const map = {
      // Vehicles
      '여객기': {'en': 'Airliner', 'ja': '旅客機', 'zh': '客机', 'fr': 'Avion', 'de': 'Flugzeug', 'es': 'Avión', 'pt': 'Avião', 'ru': 'Самолёт', 'tr': 'Uçak', 'ar': 'طائرة', 'it': 'Aereo', 'hi': 'विमान', 'th': 'เครื่องบิน'},
      '로켓': {'en': 'Rocket', 'ja': 'ロケット', 'zh': '火箭', 'fr': 'Fusée', 'de': 'Rakete', 'es': 'Cohete', 'pt': 'Foguete', 'ru': 'Ракета', 'tr': 'Roket', 'ar': 'صاروخ', 'it': 'Razzo', 'hi': 'रॉकेट', 'th': 'จรวด'},
      'UFO': {'en': 'UFO', 'ja': 'UFO', 'zh': 'UFO', 'fr': 'OVNI', 'de': 'UFO', 'es': 'OVNI', 'pt': 'OVNI', 'ru': 'НЛО', 'tr': 'UFO', 'ar': 'UFO', 'it': 'UFO', 'hi': 'UFO', 'th': 'UFO'},
      '열기구': {'en': 'Hot air balloon', 'ja': '熱気球', 'zh': '热气球', 'fr': 'Montgolfière', 'de': 'Heißluftballon', 'es': 'Globo aerostático', 'pt': 'Balão', 'ru': 'Воздушный шар', 'tr': 'Sıcak hava balonu', 'ar': 'منطاد', 'it': 'Mongolfiera', 'hi': 'हॉट एयर बैलून', 'th': 'บอลลูน'},
      '여객선': {'en': 'Cruise ship', 'ja': '客船', 'zh': '客轮', 'fr': 'Paquebot', 'de': 'Kreuzfahrtschiff', 'es': 'Crucero', 'pt': 'Cruzeiro', 'ru': 'Лайнер', 'tr': 'Yolcu gemisi', 'ar': 'سفينة ركاب', 'it': 'Crociera', 'hi': 'क्रूज़', 'th': 'เรือสำราญ'},
      '증기기차': {'en': 'Steam train', 'ja': '蒸気機関車', 'zh': '蒸汽火车', 'fr': 'Train à vapeur', 'de': 'Dampflok', 'es': 'Tren de vapor', 'pt': 'Trem a vapor', 'ru': 'Паровоз', 'tr': 'Buharlı tren', 'ar': 'قطار بخاري', 'it': 'Treno a vapore', 'hi': 'भाप ट्रेन', 'th': 'รถไฟไอน้ำ'},
      '헬리콥터': {'en': 'Helicopter', 'ja': 'ヘリコプター', 'zh': '直升机', 'fr': 'Hélicoptère', 'de': 'Hubschrauber', 'es': 'Helicóptero', 'pt': 'Helicóptero', 'ru': 'Вертолёт', 'tr': 'Helikopter', 'ar': 'مروحية', 'it': 'Elicottero', 'hi': 'हेलीकॉप्टर', 'th': 'เฮลิคอปเตอร์'},
      '나룻배': {'en': 'Rowboat', 'ja': '渡し舟', 'zh': '小船', 'fr': 'Barque', 'de': 'Ruderboot', 'es': 'Barca', 'pt': 'Barco a remo', 'ru': 'Лодка', 'tr': 'Sandal', 'ar': 'قارب', 'it': 'Barca a remi', 'hi': 'नौका', 'th': 'เรือพาย'},
      '산타썰매': {'en': 'Sleigh', 'ja': 'サンタのそり', 'zh': '雪橇', 'fr': 'Traîneau', 'de': 'Schlitten', 'es': 'Trineo', 'pt': 'Trenó', 'ru': 'Сани', 'tr': 'Kızak', 'ar': 'مزلجة', 'it': 'Slitta', 'hi': 'स्लेज', 'th': 'เลื่อน'},
      '낙하산': {'en': 'Parachute', 'ja': 'パラシュート', 'zh': '降落伞', 'fr': 'Parachute', 'de': 'Fallschirm', 'es': 'Paracaídas', 'pt': 'Paraquedas', 'ru': 'Парашют', 'tr': 'Paraşüt', 'ar': 'مظلة', 'it': 'Paracadute', 'hi': 'पैराशूट', 'th': 'ร่มชูชีพ'},
      '소형비행기': {'en': 'Small plane', 'ja': '小型機', 'zh': '小型飞机', 'fr': 'Petit avion', 'de': 'Kleinflugzeug', 'es': 'Avioneta', 'pt': 'Aviãozinho', 'ru': 'Самолётик', 'tr': 'Küçük uçak', 'ar': 'طائرة صغيرة', 'it': 'Aereo piccolo', 'hi': 'छोटा विमान', 'th': 'เครื่องเล็ก'},
      '스피드보트': {'en': 'Speedboat', 'ja': 'スピードボート', 'zh': '快艇', 'fr': 'Hors-bord', 'de': 'Schnellboot', 'es': 'Lancha', 'pt': 'Lancha', 'ru': 'Катер', 'tr': 'Sürat teknesi', 'ar': 'قارب سريع', 'it': 'Motoscafo', 'hi': 'स्पीडबोट', 'th': 'สปีดโบ๊ท'},
      // Roof
      '기본': {'en': 'Default', 'ja': '基本', 'zh': '默认', 'fr': 'Par défaut', 'de': 'Standard', 'es': 'Predeterminado', 'pt': 'Padrão', 'ru': 'По умолч.', 'tr': 'Varsayılan', 'ar': 'افتراضي', 'it': 'Predefinito', 'hi': 'डिफ़ॉल्ट', 'th': 'ค่าเริ่มต้น'},
      '뾰족': {'en': 'Pointed', 'ja': '尖り屋根', 'zh': '尖顶', 'fr': 'Pointu', 'de': 'Spitz', 'es': 'Puntiagudo', 'pt': 'Pontudo', 'ru': 'Острая', 'tr': 'Sivri', 'ar': 'مدبب', 'it': 'A punta', 'hi': 'नुकीला', 'th': 'แหลม'},
      '돔': {'en': 'Dome', 'ja': 'ドーム', 'zh': '圆顶', 'fr': 'Dôme', 'de': 'Kuppel', 'es': 'Cúpula', 'pt': 'Cúpula', 'ru': 'Купол', 'tr': 'Kubbe', 'ar': 'قبة', 'it': 'Cupola', 'hi': 'गुंबद', 'th': 'โดม'},
      '평지붕': {'en': 'Flat', 'ja': '平屋根', 'zh': '平顶', 'fr': 'Plat', 'de': 'Flach', 'es': 'Plano', 'pt': 'Plano', 'ru': 'Плоская', 'tr': 'Düz', 'ar': 'مسطح', 'it': 'Piatto', 'hi': 'सपाट', 'th': 'แบน'},
      '안테나': {'en': 'Antenna', 'ja': 'アンテナ', 'zh': '天线', 'fr': 'Antenne', 'de': 'Antenne', 'es': 'Antena', 'pt': 'Antena', 'ru': 'Антенна', 'tr': 'Anten', 'ar': 'هوائي', 'it': 'Antenna', 'hi': 'एंटेना', 'th': 'เสาอากาศ'},
      // Window
      '사각': {'en': 'Square', 'ja': '四角', 'zh': '方形', 'fr': 'Carré', 'de': 'Quadrat', 'es': 'Cuadrada', 'pt': 'Quadrada', 'ru': 'Квадрат', 'tr': 'Kare', 'ar': 'مربع', 'it': 'Quadrata', 'hi': 'चौकोर', 'th': 'สี่เหลี่ยม'},
      '원형': {'en': 'Round', 'ja': '丸窓', 'zh': '圆形', 'fr': 'Rond', 'de': 'Rund', 'es': 'Redonda', 'pt': 'Redonda', 'ru': 'Круг', 'tr': 'Yuvarlak', 'ar': 'دائري', 'it': 'Rotonda', 'hi': 'गोल', 'th': 'กลม'},
      '아치': {'en': 'Arch', 'ja': 'アーチ', 'zh': '拱形', 'fr': 'Arche', 'de': 'Bogen', 'es': 'Arco', 'pt': 'Arco', 'ru': 'Арка', 'tr': 'Kemer', 'ar': 'قوس', 'it': 'Arco', 'hi': 'आर्च', 'th': 'โค้ง'},
      '모던': {'en': 'Modern', 'ja': 'モダン', 'zh': '现代', 'fr': 'Moderne', 'de': 'Modern', 'es': 'Moderna', 'pt': 'Moderna', 'ru': 'Модерн', 'tr': 'Modern', 'ar': 'حديث', 'it': 'Moderna', 'hi': 'आधुनिक', 'th': 'ทันสมัย'},
    };
    if (languageCode == 'ko') return koreanKey;
    final entry = map[koreanKey];
    if (entry == null) return koreanKey;
    return entry[languageCode] ?? entry['en'] ?? koreanKey;
  }

}
