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

  String get tagline => _t({
    'ko': '세상 어딘가의 당신에게',
    'en': 'To you, somewhere in the world',
    'ja': 'どこかの誰かへ',
    'zh': '致世界某处的你',
    'fr': 'À toi, quelque part dans le monde',
    'de': 'An dich, irgendwo auf der Welt',
    'es': 'A ti, en algún lugar del mundo',
    'pt': 'Para você, em algum lugar do mundo',
    'ru': 'Тебе, где-то в мире',
    'tr': 'Dünyanın bir yerindeki sana',
    'ar': 'إليك، في مكان ما في العالم',
    'it': 'A te, da qualche parte nel mondo',
    'hi': 'दुनिया में कहीं तुम्हारे लिए',
    'th': 'ถึงคุณ ที่ไหนสักแห่งในโลก',
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
    'ko': '편지함',
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

  // ── Inbox ─────────────────────────────────────────────────────────────────
  String get received => _t({
    'ko': '받은 편지',
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
    'ko': '보낸 편지',
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
    'ko': '다음 편지를 읽으려면 편지를 3개 보내야 합니다',
    'en': 'Send 3 letters to unlock the next one',
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
    'ko': '편지 쓰기',
    'en': 'Write Letter',
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
    'ko': '편지 보내기',
    'en': 'Send Letter',
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
    'ko': '📬 편지가 도착했어요!',
    'en': '📬 A letter has arrived!',
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
    'ko': '2km 이내에 편지가 있어요. 앱에서 확인하세요!',
    'en': 'A letter is within 2km. Check it in the app!',
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

  // ── Onboarding ────────────────────────────────────────────────────────────
  String get onboarding1Title => _t({
    'ko': '🍾 메시지 인 어 보틀',
    'en': '🍾 Message in a Bottle',
    'ja': '🍾 メッセージ・イン・ア・ボトル',
    'zh': '🍾 漂流瓶',
    'fr': '🍾 Message dans une bouteille',
    'de': '🍾 Flaschenpost',
    'es': '🍾 Mensaje en una botella',
    'pt': '🍾 Mensagem numa garrafa',
    'ru': '🍾 Письмо в бутылке',
    'tr': '🍾 Şişedeki Mesaj',
    'ar': '🍾 رسالة في زجاجة',
    'it': '🍾 Messaggio in bottiglia',
    'hi': '🍾 बोतल में संदेश',
    'th': '🍾 ข้อความในขวด',
  });
  String get onboarding1Body => _t({
    'ko': '세상 어딘가의 누군가에게 익명 편지를 보내세요. 실제 우편 배송 경로로 전달됩니다.',
    'en':
        'Send anonymous letters to someone, somewhere in the world. Delivered via real postal routes.',
    'ja': '世界のどこかにいる誰かに匿名の手紙を送りましょう。実際の郵便ルートで届けられます。',
    'zh': '向世界某处的某人发送匿名信。通过真实邮政路线递送。',
    'fr':
        'Envoyez des lettres anonymes à quelqu\'un quelque part dans le monde.',
    'de': 'Sende anonyme Briefe an jemanden, irgendwo auf der Welt.',
    'es': 'Envía cartas anónimas a alguien en algún lugar del mundo.',
    'pt': 'Envie cartas anônimas para alguém em algum lugar do mundo.',
    'ru': 'Отправляйте анонимные письма кому-то, где-то в мире.',
    'tr': 'Dünyanın bir yerindeki birine anonim mektuplar gönderin.',
    'ar': 'أرسل رسائل مجهولة إلى شخص ما في مكان ما في العالم.',
    'it': 'Invia lettere anonime a qualcuno, da qualche parte nel mondo.',
    'hi': 'दुनिया में कहीं किसी को अनाम पत्र भेजें।',
    'th': 'ส่งจดหมายนิรนามถึงใครบางคนที่ไหนสักแห่งในโลก',
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
  String get onboarding2Body => _t({
    'ko': '편지는 트럭 🚚 → 공항 ✈️ → 목적지 트럭 🚚 순서로 세계지도에서 이동합니다. 실제 우편 시간을 반영합니다.',
    'en':
        'Letters travel 🚚 → ✈️ → 🚚 on a world map, reflecting real postal delivery times.',
    'ja': '手紙は🚚→✈️→🚚の順で世界地図を移動します。実際の郵便時間を反映します。',
    'zh': '信件在世界地图上沿🚚→✈️→🚚路线移动，反映真实邮递时间。',
    'fr':
        'Les lettres voyagent 🚚→✈️→🚚 sur la carte du monde, reflétant les délais postaux réels.',
    'de':
        'Briefe reisen 🚚→✈️→🚚 auf der Weltkarte, entsprechend echter Postzeiten.',
    'es':
        'Las cartas viajan 🚚→✈️→🚚 en el mapa del mundo, reflejando tiempos postales reales.',
    'pt':
        'As cartas viajam 🚚→✈️→🚚 no mapa mundial, refletindo tempos postais reais.',
    'ru':
        'Письма путешествуют 🚚→✈️→🚚 на карте мира, отражая реальные сроки доставки.',
    'tr':
        'Mektuplar dünya haritasında 🚚→✈️→🚚 seyahat eder, gerçek posta sürelerini yansıtır.',
    'ar':
        'تسافر الرسائل 🚚→✈️→🚚 على الخريطة العالمية، مما يعكس أوقات البريد الحقيقية.',
    'it':
        'Le lettere viaggiano 🚚→✈️→🚚 sulla mappa del mondo, riflettendo i tempi postali reali.',
    'hi':
        'पत्र विश्व मानचित्र पर 🚚→✈️→🚚 यात्रा करते हैं, वास्तविक डाक समय को दर्शाते हैं।',
    'th': 'จดหมายเดินทาง 🚚→✈️→🚚 บนแผนที่โลก สะท้อนเวลาส่งไปรษณีย์จริง',
  });

  String get onboarding3Title => _t({
    'ko': '📬 편지 교환 규칙',
    'en': '📬 Letter Exchange Rules',
    'ja': '📬 手紙交換ルール',
    'zh': '📬 信件交换规则',
    'fr': '📬 Règles d\'échange de lettres',
    'de': '📬 Briefaustauschregeln',
    'es': '📬 Reglas de intercambio de cartas',
    'pt': '📬 Regras de troca de cartas',
    'ru': '📬 Правила обмена письмами',
    'tr': '📬 Mektup alışverişi kuralları',
    'ar': '📬 قواعد تبادل الرسائل',
    'it': '📬 Regole di scambio lettere',
    'hi': '📬 पत्र विनिमय नियम',
    'th': '📬 กฎการแลกจดหมาย',
  });
  String get onboarding3Body => _t({
    'ko': '편지를 3개 보내야 다음 받은 편지를 읽을 수 있어요. 공정한 교환을 통해 모두가 편지를 받을 수 있습니다!',
    'en':
        'You must send 3 letters before reading the next received one. Fair exchange keeps letters flowing for everyone!',
    'ja': '次の受信した手紙を読む前に3通送る必要があります。公平な交換でみんなに手紙が届きます！',
    'zh': '阅读下一封收到的信件前，必须发送3封信。公平交换，让每个人都能收到信！',
    'fr':
        'Vous devez envoyer 3 lettres avant de lire la suivante. L\'échange équitable garde les lettres en circulation!',
    'de':
        'Sie müssen 3 Briefe senden, bevor Sie den nächsten lesen. Fairer Austausch hält Briefe für alle fließen!',
    'es':
        'Debes enviar 3 cartas antes de leer la siguiente recibida. ¡El intercambio justo mantiene las cartas fluyendo para todos!',
    'pt':
        'Você deve enviar 3 cartas antes de ler a próxima recebida. Troca justa mantém as cartas fluindo para todos!',
    'ru':
        'Вы должны отправить 3 письма, прежде чем прочитать следующее. Справедливый обмен держит письма в движении!',
    'tr':
        'Bir sonrakini okumadan önce 3 mektup göndermeniz gerekiyor. Adil değişim mektupları herkes için akıyor tutar!',
    'ar':
        'يجب عليك إرسال 3 رسائل قبل قراءة التالية. التبادل العادل يبقي الرسائل تتدفق للجميع!',
    'it':
        'Devi inviare 3 lettere prima di leggere la prossima ricevuta. Lo scambio equo mantiene le lettere in circolazione per tutti!',
    'hi':
        'अगली प्राप्त पत्र पढ़ने से पहले 3 पत्र भेजने होंगे। उचित विनिमय सभी के लिए पत्र प्रवाहित रखता है!',
    'th':
        'คุณต้องส่งจดหมาย 3 ฉบับก่อนอ่านฉบับถัดไปที่ได้รับ การแลกเปลี่ยนที่เป็นธรรมทำให้จดหมายไหลเวียนสำหรับทุกคน!',
  });

  String get onboarding4Title => _t({
    'ko': '🌗 시간대별 화면',
    'en': '🌗 Time-Based Themes',
    'ja': '🌗 時間帯のテーマ',
    'zh': '🌗 时间主题',
    'fr': '🌗 Thèmes selon l\'heure',
    'de': '🌗 Zeitbasierte Designs',
    'es': '🌗 Temas según la hora',
    'pt': '🌗 Temas baseados na hora',
    'ru': '🌗 Темы по времени суток',
    'tr': '🌗 Saate göre temalar',
    'ar': '🌗 مظاهر حسب الوقت',
    'it': '🌗 Temi basati sull\'ora',
    'hi': '🌗 समय-आधारित थीम',
    'th': '🌗 ธีมตามเวลา',
  });
  String get onboarding4Body => _t({
    'ko': '앱 화면이 내 나라의 현재 시간에 맞춰 낮☀️, 저녁🌅, 밤🌙으로 자동 변경됩니다.',
    'en':
        'The app automatically changes to morning☀️, evening🌅, or night🌙 based on your country\'s local time.',
    'ja': 'アプリは自国の現地時刻に合わせて朝☀️・夕方🌅・夜🌙に自動変更されます。',
    'zh': '应用根据您所在国家的当地时间自动切换为早晨☀️、傍晚🌅或夜晚🌙。',
    'fr':
        "L'app change automatiquement en matin☀️, soir🌅, nuit🌙 selon l'heure locale de votre pays.",
    'de':
        'Die App wechselt automatisch zu Morgen☀️, Abend🌅 oder Nacht🌙 entsprechend der Ortszeit.',
    'es':
        'La app cambia automáticamente a mañana☀️, tarde🌅 o noche🌙 según la hora local de tu país.',
    'pt':
        'O app muda automaticamente para manhã☀️, tarde🌅 ou noite🌙 conforme a hora local.',
    'ru':
        'Приложение автоматически меняется на утро☀️, вечер🌅 или ночь🌙 по местному времени.',
    'tr':
        'Uygulama ülkenizin yerel saatine göre otomatik olarak sabah☀️, akşam🌅 veya gece🌙ya dönüşür.',
    'ar':
        'يتغير التطبيق تلقائياً إلى صباح☀️ أو مساء🌅 أو ليل🌙 حسب التوقيت المحلي لبلدك.',
    'it':
        "L'app cambia automaticamente in mattina☀️, sera🌅 o notte🌙 in base all'ora locale.",
    'hi':
        'ऐप स्वचालित रूप से आपके देश के स्थानीय समय के अनुसार सुबह☀️, शाम🌅 या रात🌙 में बदल जाता है।',
    'th':
        'แอปเปลี่ยนเป็นเช้า☀️ เย็น🌅 หรือกลางคืน🌙 โดยอัตโนมัติตามเวลาท้องถิ่นของประเทศคุณ',
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
    'ko': '지금 바로 가입하고 세계 어딘가의 누군가와 특별한 편지를 교환해 보세요!',
    'en':
        'Sign up now and start exchanging special letters with someone, somewhere in the world!',
    'ja': '今すぐ登録して、世界のどこかにいる誰かと特別な手紙を交換しましょう！',
    'zh': '立即注册，开始与世界某处的某人交换特别的信件！',
    'fr':
        'Inscrivez-vous maintenant et commencez à échanger des lettres avec quelqu\'un dans le monde!',
    'de':
        'Registrieren Sie sich jetzt und tauschen Sie besondere Briefe mit jemandem auf der Welt aus!',
    'es':
        '¡Regístrate ahora y empieza a intercambiar cartas especiales con alguien en el mundo!',
    'pt':
        'Cadastre-se agora e comece a trocar cartas especiais com alguém no mundo!',
    'ru':
        'Зарегистрируйтесь сейчас и начните обмениваться особыми письмами с кем-то в мире!',
    'tr':
        'Şimdi kaydolun ve dünyadaki biriyle özel mektuplar alışverişi yapmaya başlayın!',
    'ar': 'سجّل الآن وابدأ تبادل رسائل خاصة مع شخص ما في العالم!',
    'it':
        'Registrati ora e inizia a scambiare lettere speciali con qualcuno nel mondo!',
    'hi':
        'अभी साइन अप करें और दुनिया में किसी के साथ विशेष पत्र आदान-प्रदान शुरू करें!',
    'th': 'สมัครเดี๋ยวนี้และเริ่มแลกจดหมายพิเศษกับใครบางคนในโลก!',
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
    'ko': '주변 2km 이내에 도착한 편지를\n수령할 수 있어요 🎉',
    'en': 'You can receive letters that arrive\nwithin 2km of you 🎉',
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
    'ko': '편지가 내 위치 2km 이내에 도착하면\n알림을 받을 수 있어요.\n위치 정보는 앱 내에서만 사용됩니다.',
    'en':
        'Get notified when a letter arrives\nwithin 2km of you.\nLocation is only used within the app.',
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
  String get premiumHeroTitle => _t({
    'ko': '더 넓은 세계로\n편지를 보내보세요',
    'en': 'Send letters\nto the wider world',
    'ja': 'より広い世界へ\n手紙を送ってみましょう',
    'zh': '向更广阔的世界\n发送信件',
    'fr': 'Envoyez des lettres\nvers un monde plus vaste',
    'de': 'Sende Briefe\nin die weite Welt',
    'es': 'Envía cartas\nal mundo más amplio',
    'pt': 'Envie cartas\npara o mundo mais amplo',
    'ru': 'Отправляйте письма\nв большой мир',
    'tr': 'Geniş dünyaya\nmektuplar gönderin',
    'ar': 'أرسل رسائل\nإلى العالم الأوسع',
    'it': 'Invia lettere\nal mondo più ampio',
    'hi': 'विस्तृत दुनिया में\nपत्र भेजें',
    'th': 'ส่งจดหมาย\nสู่โลกที่กว้างขึ้น',
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
    'en': '1,000 letters ₩15,000',
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
    'ko': '주변 편지 알림',
    'en': 'Nearby Letter Notification',
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
}
