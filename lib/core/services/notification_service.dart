import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Categories of notifications the app can fire. Used by the push-mode
/// gate below to drop noisy categories when a user has selected a
/// quieter mode.
enum PushCategory {
  daily,            // 8am "Today's Letter" reminder
  arrivedInbox,     // a letter landed in your mailbox
  arrivalCountdown, // 1h before an arrival
  dm,               // direct message
  nearby,           // letter within 500m
  cooldown,         // "nearby but on cooldown"
  reportBlock,      // your letter got reported
  couponExpiry,     // Build 134: 보유 쿠폰/교환권 만료 1일 전 알림
}

enum PushMode { quiet, standard, full }

PushMode _pushModeFromString(String s) {
  switch (s) {
    case 'quiet': return PushMode.quiet;
    case 'full': return PushMode.full;
    case 'standard':
    default: return PushMode.standard;
  }
}

String pushModeToString(PushMode m) {
  switch (m) {
    case PushMode.quiet: return 'quiet';
    case PushMode.standard: return 'standard';
    case PushMode.full: return 'full';
  }
}

/// Notification text localization helper
String _notiMsg(String key, [String langCode = 'en']) {
  return (_notiMessages[key]?[langCode]) ??
      (_notiMessages[key]?['en']) ??
      key;
}

const Map<String, Map<String, String>> _notiMessages = {
  'nearby_channel': {
    'ko': '근처 편지 알림',
    'en': 'Nearby Letter',
    'ja': '近くの手紙',
    'zh': '附近信件',
    'es': 'Carta cercana',
    'fr': 'Lettre à proximité',
    'de': 'Brief in der Nähe',
    'pt': 'Carta próxima',
    'ru': 'Письмо поблизости',
  },
  'nearby_desc': {
    'ko': '500m 이내에 편지가 도착했을 때 알림',
    'en': 'Notification when a letter arrives within 500m',
    'ja': '500m以内に手紙が届いた時の通知',
    'zh': '500米内有信件到达时通知',
    'es': 'Notificación cuando llega una carta a 500m',
    'fr': 'Notification quand une lettre arrive à 500m',
    'de': 'Benachrichtigung bei Brief innerhalb von 500m',
    'pt': 'Notificação quando uma carta chega a 500m',
    'ru': 'Уведомление о письме в радиусе 500м',
  },
  'arrived_channel': {
    'ko': '혜택 도착 알림',
    'en': 'Letter Arrived',
    'ja': '手紙到着',
    'zh': '信件到达',
    'es': 'Carta recibida',
    'fr': 'Lettre reçue',
    'de': 'Brief angekommen',
    'pt': 'Carta recebida',
    'ru': 'Письмо доставлено',
  },
  'arrived_desc': {
    'ko': '새 편지가 도착했을 때 알림',
    'en': 'Notification when a new letter arrives',
    'ja': '新しい手紙が届いた時の通知',
    'zh': '新信件到达时通知',
    'es': 'Notificación cuando llega una carta nueva',
    'fr': 'Notification à la réception d\'une nouvelle lettre',
    'de': 'Benachrichtigung bei neuem Brief',
    'pt': 'Notificação quando uma nova carta chega',
    'ru': 'Уведомление о новом письме',
  },
  'dm_channel': {
    'ko': 'DM 도착 알림',
    'en': 'DM Arrived',
    'ja': 'DM到着',
    'zh': 'DM到达',
    'es': 'DM recibido',
    'fr': 'DM reçu',
    'de': 'DM erhalten',
    'pt': 'DM recebido',
    'ru': 'DM получено',
  },
  'dm_desc': {
    'ko': '새 DM이 도착했을 때 알림',
    'en': 'Notification when a new DM arrives',
    'ja': '新しいDMが届いた時の通知',
    'zh': '新DM到达时通知',
    'es': 'Notificación cuando llega un DM nuevo',
    'fr': 'Notification à la réception d\'un nouveau DM',
    'de': 'Benachrichtigung bei neuer DM',
    'pt': 'Notificação quando um novo DM chega',
    'ru': 'Уведомление о новом DM',
  },
  'dm_title': {
    'ko': '님의 메시지',
    'en': '\'s message',
    'ja': 'さんのメッセージ',
    'zh': '的消息',
    'es': ' envió un mensaje',
    'fr': ' a envoyé un message',
    'de': 's Nachricht',
    'pt': ' enviou uma mensagem',
    'ru': ' отправил сообщение',
  },
  'cooldown_channel': {
    'ko': '픽업 쿨다운 알림',
    'en': 'Pickup Cooldown',
    'ja': 'ピックアップクールダウン',
    'zh': '拾取冷却',
    'es': 'Enfriamiento de recogida',
    'fr': 'Délai de récupération',
    'de': 'Abholwartezeit',
    'pt': 'Tempo de espera',
    'ru': 'Перезарядка подбора',
  },
  'cooldown_desc': {
    'ko': '근처 편지가 있지만 쿨다운으로 픽업할 수 없을 때 알림',
    'en': 'Notification when nearby letter cannot be picked up due to cooldown',
    'ja': '近くに手紙があるがクールダウン中でピックアップできない時の通知',
    'zh': '附近有信件但因冷却无法拾取时通知',
    'es': 'Notificación cuando no se puede recoger por enfriamiento',
    'fr': 'Notification quand une lettre ne peut être récupérée (délai)',
    'de': 'Benachrichtigung wenn Brief wegen Wartezeit nicht abholbar',
    'pt': 'Notificação quando carta não pode ser coletada (tempo de espera)',
    'ru': 'Уведомление когда письмо нельзя подобрать из-за перезарядки',
  },
  'report_channel': {
    'ko': '신고 알림',
    'en': 'Report Alert',
    'ja': '報告通知',
    'zh': '举报通知',
    'es': 'Alerta de reporte',
    'fr': 'Alerte de signalement',
    'de': 'Meldungsbenachrichtigung',
    'pt': 'Alerta de denúncia',
    'ru': 'Уведомление о жалобе',
  },
  'report_desc': {
    'ko': '혜택이 신고되어 임시 차단되었을 때 알림',
    'en': 'Notification when a letter is reported and temporarily blocked',
    'ja': '手紙が報告されて一時的にブロックされた時の通知',
    'zh': '信件被举报并临时屏蔽时通知',
    'es': 'Notificación cuando una carta es reportada y bloqueada',
    'fr': 'Notification quand une lettre est signalée et bloquée',
    'de': 'Benachrichtigung wenn Brief gemeldet und vorübergehend gesperrt',
    'pt': 'Notificação quando carta é denunciada e bloqueada temporariamente',
    'ru': 'Уведомление когда письмо заблокировано по жалобе',
  },
};

// Hunt 포지셔닝에 맞춰 이모지 풀을 교체. 펜팔 냄새가 나던 💌 🕊️ 🌊 ✉️
// 대신 쿠폰·줍기 이모지 (🎟 🎁 📩 🗺 🎯 ✨ 📮) 로 이동. 🌏 은 "먼 곳"
// 의미상 유지. 각 언어 복사는 그대로, 이모지만 위치별 교체.
const Map<String, List<String>> _arrivedTitlesByLang = {
  'ko': [
    '🎟 새 편지가 도착했어요!',
    '🌏 먼 곳에서 편지가 왔어요!',
    '🗺 편지함에 새 편지!',
    '🎁 편지가 여행을 마쳤어요!',
    '📩 편지가 무사히 도착했어요!',
    '✨ 바다를 건너 편지가 왔어요!',
    '🎯 새로운 편지 소식!',
    '📮 세계 어딘가에서 편지 도착!',
  ],
  'en': [
    '🎟 A new letter has arrived!',
    '🌏 A letter from afar!',
    '🗺 New letter in your mailbox!',
    '🎁 A letter finished its journey!',
    '📩 A letter arrived safely!',
    '✨ A letter crossed the ocean!',
    '🎯 New letter alert!',
    '📮 Letter arrived from somewhere!',
  ],
  'ja': [
    '🎟 新しい手紙が届きました！',
    '🌏 遠くから手紙が来ました！',
    '🗺 新しい手紙です！',
    '🎁 手紙が旅を終えました！',
    '📩 手紙が無事届きました！',
    '✨ 海を越えて手紙が来ました！',
    '🎯 新しい手紙のお知らせ！',
    '📮 世界のどこかから手紙到着！',
  ],
  'zh': [
    '🎟 新信件到了！',
    '🌏 远方来信！',
    '🗺 信箱里有新信！',
    '🎁 信件完成了旅程！',
    '📩 信件安全到达！',
    '✨ 跨洋来信！',
    '🎯 新信件提醒！',
    '📮 来自某处的信件！',
  ],
};

Map<String, List<String> Function(String, String)> _arrivedBodiesByLang = {
  'ko': (String flag, String country) => [
    '$flag $country에서 보낸 편지가 도착했습니다',
    '$flag $country 누군가의 이야기가 당신을 향해 왔어요',
    '$flag $country에서 출발한 편지가 목적지에 도착!',
    '$flag $country의 마음이 담긴 편지가 왔어요',
    '먼 $flag $country에서 편지병이 떠내려왔어요',
    '$flag $country 편지가 긴 여행을 마치고 도착했어요',
  ],
  'en': (String flag, String country) => [
    'A letter from $flag $country has arrived',
    'Someone in $flag $country sent you a story',
    'A letter from $flag $country reached its destination!',
    'A heartfelt letter from $flag $country arrived',
    'A letter drifted over from $flag $country',
    'A letter from $flag $country finished its long journey',
  ],
  'ja': (String flag, String country) => [
    '$flag $countryからの手紙が届きました',
    '$flag $countryの誰かの物語があなたに届きました',
    '$flag $countryから出発した手紙が到着！',
    '$flag $countryからの心のこもった手紙が届きました',
    '遠い$flag $countryから手紙が流れ着きました',
    '$flag $countryの手紙が長い旅を終えて届きました',
  ],
  'zh': (String flag, String country) => [
    '来自$flag $country的信件已到达',
    '$flag $country的某人向你讲述了一个故事',
    '从$flag $country出发的信件到达了目的地！',
    '来自$flag $country的真挚信件到了',
    '一封信从$flag $country漂流而来',
    '$flag $country的信件完成了漫长旅程',
  ],
};

// Daily "Today's Letter" reminder copy. One variant per language; the
// notification repeats daily so rotating variants isn't worth the complexity
// of re-scheduling per day. Build 117: 펜팔식 "편지함 열어보세요" → 헌트식
// "오늘의 쿠폰을 확인해봐요" 로 재정비. 마케팅 기획서 Build 113 의 Discovery
// 메시지 축에 정렬.
const Map<String, String> _dailyReminderTitles = {
  'ko': '🗺 오늘의 쿠폰을 확인해봐요',
  'en': '🗺 Check today\'s coupon drops',
  'ja': '🗺 今日のクーポンをチェック',
  'zh': '🗺 看看今天的优惠',
  'fr': "🗺 Regarde les coupons du jour",
  'de': '🗺 Heutige Coupons checken',
  'es': '🗺 Mira los cupones de hoy',
  'pt': '🗺 Vê os cupões de hoje',
  'ru': '🗺 Проверь сегодняшние купоны',
  'tr': '🗺 Bugünün kuponlarına bak',
  'ar': '🗺 تفقّد كوبونات اليوم',
  'it': '🗺 Controlla i coupon di oggi',
  'hi': '🗺 आज के कूपन देखो',
  'th': '🗺 ดูคูปองวันนี้',
};

// Anticipation ping ~1h before the next incoming letter arrives.
// 📮 (postbox) → 📩 (incoming envelope) — 임박 도착 정서를 더 잘 전달.
const Map<String, String> _arrivalCountdownTitles = {
  'ko': '📩 편지가 1시간 후 도착해요',
  'en': '📩 A letter arrives in about an hour',
  'ja': '📩 手紙はあと1時間で到着します',
  'zh': '📩 信件将在约 1 小时后到达',
  'fr': '📩 Une lettre arrive dans environ une heure',
  'de': '📩 Ein Brief kommt in etwa einer Stunde an',
  'es': '📩 Una carta llega en aproximadamente una hora',
  'pt': '📩 Uma carta chega em cerca de uma hora',
  'ru': '📩 Письмо придёт примерно через час',
  'tr': '📩 Bir mektup yaklaşık bir saat içinde varıyor',
  'ar': '📩 ستصل رسالة بعد نحو ساعة',
  'it': '📩 Una lettera arriva tra circa un\'ora',
  'hi': '📩 लगभग एक घंटे में एक पत्र पहुँचेगा',
  'th': '📩 จดหมายจะถึงในอีกประมาณหนึ่งชั่วโมง',
};

String _arrivalCountdownBody(String langCode, String flag, String country) {
  switch (langCode) {
    case 'ko': return '$flag $country에서 출발한 편지가 곧 우편함에 도착해요';
    case 'ja': return '$flag $countryから出発した手紙がもうすぐ届きます';
    case 'zh': return '来自 $flag $country 的信件即将到达你的信箱';
    case 'fr': return 'Une lettre partie de $flag $country arrive bientôt';
    case 'de': return 'Ein Brief aus $flag $country erreicht bald deinen Kasten';
    case 'es': return 'Una carta desde $flag $country está por llegar';
    case 'pt': return 'Uma carta de $flag $country está quase chegando';
    case 'ru': return 'Письмо из $flag $country скоро будет в ящике';
    case 'tr': return '$flag $country\'dan yola çıkan mektup kutuna yaklaşıyor';
    case 'ar': return 'رسالة من $flag $country ستصل إلى صندوقك قريباً';
    case 'it': return 'Una lettera da $flag $country sta per arrivare';
    case 'hi': return '$flag $country से एक पत्र जल्द ही आपके मेलबॉक्स में';
    case 'th': return 'จดหมายจาก $flag $country กำลังจะถึงกล่องของคุณ';
    case 'en':
    default: return 'A letter from $flag $country is about to reach your mailbox';
  }
}

// Build 117: 본문도 헌트 포지셔닝 — "누군가 편지를 보냈을지도" 에서 "근처
// 지도를 열어보면 새 쿠폰이 있을지도" 로. 구체적인 액션 유도.
const Map<String, String> _dailyReminderBodies = {
  'ko': '근처 지도에 새로 떨어진 할인·홍보 편지를 주워보세요',
  'en': 'Open the map — discount letters may have dropped nearby',
  'ja': '近くの地図を開いて、新しい割引・プロモ手紙を拾いましょう',
  'zh': '打开附近地图，看看新落下的优惠信件',
  'fr': "Ouvre la carte — des coupons sont peut-être tombés près de toi",
  'de': 'Öffne die Karte — vielleicht warten neue Rabatt-Briefe in der Nähe',
  'es': 'Abre el mapa — puede que haya cupones nuevos cerca de ti',
  'pt': 'Abre o mapa — podem ter caído novos cupões perto de ti',
  'ru': 'Откройте карту — рядом могли выпасть новые купонные письма',
  'tr': 'Haritayı aç — yakınlarına yeni indirim mektupları düşmüş olabilir',
  'ar': 'افتح الخريطة — ربما سقطت رسائل خصم قربك',
  'it': 'Apri la mappa — potrebbero esserci nuovi coupon vicino a te',
  'hi': 'नक्शा खोलो — पास में नए कूपन पत्र गिरे हो सकते हैं',
  'th': 'เปิดแผนที่ — อาจมีจดหมายส่วนลดใหม่ตกอยู่ใกล้คุณ',
};

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Notification ID reserved for the recurring daily letter reminder.
  static const int _dailyReminderId = 10;

  /// Single-slot notification for "your next letter arrives in ~1 hour".
  /// Overwrites any previously scheduled countdown so the user only ever
  /// sees one anticipation ping at a time.
  static const int _arrivalCountdownId = 11;

  static PushMode _currentMode = PushMode.standard;

  static Future<PushMode> loadPushMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString('push_mode') ?? 'standard';
      _currentMode = _pushModeFromString(s);
    } catch (_) {}
    return _currentMode;
  }

  static Future<void> setPushMode(PushMode mode) async {
    _currentMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('push_mode', pushModeToString(mode));
    } catch (_) {}
  }

  /// Gate: is this push category allowed given the current mode?
  /// `quiet`    — only the 8am daily nudge
  /// `standard` — daily + arrivals + DM + arrival countdown
  /// `full`     — everything (back-compat with old default)
  static bool _isAllowed(PushCategory cat) {
    switch (_currentMode) {
      case PushMode.full:
        return true;
      case PushMode.standard:
        return cat == PushCategory.daily ||
            cat == PushCategory.arrivedInbox ||
            cat == PushCategory.arrivalCountdown ||
            cat == PushCategory.dm ||
            cat == PushCategory.couponExpiry;
      case PushMode.quiet:
        return cat == PushCategory.daily;
    }
  }

  /// Build 254: 푸시 알림 탭 시 호출되는 콜백. main.dart 에서 등록.
  /// payload 에 따라 deep link 라우팅 가능. 현재 기본 동작 = 인박스 이동.
  static void Function(String? payload)? onNotificationTap;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initLocalTimezone();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      // Avoid showing the permission alert immediately at app launch.
      // We request notification permission explicitly via requestPermissions().
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(
      initSettings,
      // Build 254: 알림 탭 → onNotificationTap 콜백으로 라우팅 위임.
      // foreground/background/killed 모두 동일 핸들러 진입.
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        onNotificationTap?.call(payload);
      },
    );
    _initialized = true;
  }

  // IANA Etc/GMT uses sign-flipped hours (Etc/GMT-9 = UTC+9 = Seoul).
  // Fractional offsets (India +5:30) round to the nearest whole hour — a
  // daily reminder doesn't need minute precision and avoids the
  // flutter_timezone plugin dependency.
  static void _initLocalTimezone() {
    try {
      tz_data.initializeTimeZones();
      final offset = DateTime.now().timeZoneOffset;
      final hours = offset.inMinutes ~/ 60;
      if (hours == 0) {
        tz.setLocalLocation(tz.UTC);
        return;
      }
      final sign = hours >= 0 ? '-' : '+';
      final abs = hours.abs();
      tz.setLocalLocation(tz.getLocation('Etc/GMT$sign$abs'));
    } catch (e) {
      debugPrint('Timezone init error: $e');
    }
  }

  /// Returns true if the user granted the notification permission, false if
  /// denied, null if the platform doesn't respond (treat as denied).
  static Future<bool> requestPermissions() async {
    try {
      // iOS / macOS
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final iosResult = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Android 13+ (API 33+) — POST_NOTIFICATIONS 런타임 권한 필요
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final androidResult = await android?.requestNotificationsPermission();

      // 둘 중 어느 하나라도 true면 권한 허용으로 본다 (플랫폼별 단일 응답)
      return (iosResult ?? false) || (androidResult ?? false);
    } catch (e) {
      debugPrint('Notification permission error: $e');
      return false;
    }
  }

  // ── Localized channel metadata ─────────────────────────────────────────────
  static const _channelNames = <String, Map<String, String>>{
    'nearby_letter': {
      'ko': '근처 편지 알림',
      'en': 'Nearby Letter Alerts',
      'ja': '近くの手紙通知',
      'zh': '附近信件通知',
    },
    'nearby_letter_desc': {
      'ko': '500m 이내에 편지가 도착했을 때 알림',
      'en': 'Alerts when a letter arrives within 500m',
      'ja': '500m以内に手紙が届いた時の通知',
      'zh': '当信件到达500米以内时通知',
    },
    'letter_arrived': {
      'ko': '혜택 도착 알림',
      'en': 'Letter Arrival Alerts',
      'ja': '手紙到着通知',
      'zh': '信件到达通知',
    },
    'letter_arrived_desc': {
      'ko': '새 편지가 도착했을 때 알림',
      'en': 'Alerts when a new letter arrives',
      'ja': '新しい手紙が届いた時の通知',
      'zh': '新信件到达时通知',
    },
    'dm_arrived': {
      'ko': 'DM 도착 알림',
      'en': 'DM Alerts',
      'ja': 'DMの通知',
      'zh': 'DM通知',
    },
    'dm_arrived_desc': {
      'ko': '새 DM이 도착했을 때 알림',
      'en': 'Alerts when a new direct message arrives',
      'ja': '新しいDMが届いた時の通知',
      'zh': '新私信到达时通知',
    },
  };

  static String _ch(String key, String langCode) {
    final entry = _channelNames[key];
    if (entry == null) return key;
    return entry[langCode] ?? entry['ko']!;
  }

  static final Random _rng = Random();

  static Future<void> showNearbyLetterNotification({
    required String title,
    required String body,
    String langCode = 'en',
  }) async {
    if (!_isAllowed(PushCategory.nearby)) return;
    try {
      final androidDetails = AndroidNotificationDetails(
        'nearby_letter',
        _notiMsg('nearby_channel', langCode),
        channelDescription: _notiMsg('nearby_desc', langCode),
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      await _plugin.show(0, title, body, details);
    } catch (e) {
      debugPrint('Notification show error: $e');
    }
  }

  static Future<void> showLetterArrivedNotification({
    required String senderCountry,
    required String senderFlag,
    String langCode = 'en',
  }) async {
    if (!_isAllowed(PushCategory.arrivedInbox)) return;
    try {
      final androidDetails = AndroidNotificationDetails(
        'letter_arrived',
        _notiMsg('arrived_channel', langCode),
        channelDescription: _notiMsg('arrived_desc', langCode),
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final titles = _arrivedTitlesByLang[langCode] ?? _arrivedTitlesByLang['en']!;
      final title = titles[_rng.nextInt(titles.length)];
      final bodyFn = _arrivedBodiesByLang[langCode] ?? _arrivedBodiesByLang['en']!;
      final bodies = bodyFn(senderFlag, senderCountry);
      final body = bodies[_rng.nextInt(bodies.length)];

      await _plugin.show(1, title, body, details);
    } catch (e) {
      debugPrint('Letter notification error: $e');
    }
  }

  static Future<void> showDMArrivedNotification({
    required String senderName,
    required String message,
    String langCode = 'en',
  }) async {
    if (!_isAllowed(PushCategory.dm)) return;
    try {
      final androidDetails = AndroidNotificationDetails(
        'dm_arrived',
        _notiMsg('dm_channel', langCode),
        channelDescription: _notiMsg('dm_desc', langCode),
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        2,
        '💬 $senderName${_notiMsg('dm_title', langCode)}',
        message.length > 40 ? '${message.substring(0, 40)}...' : message,
        details,
      );
    } catch (e) {
      debugPrint('DM notification error: $e');
    }
  }

  /// 쿨다운으로 편지 픽업 불가 시 알림
  static Future<void> showCooldownNotification({
    required String title,
    required String body,
    String langCode = 'en',
  }) async {
    if (!_isAllowed(PushCategory.cooldown)) return;
    try {
      final androidDetails = AndroidNotificationDetails(
        'pickup_cooldown',
        _notiMsg('cooldown_channel', langCode),
        channelDescription: _notiMsg('cooldown_desc', langCode),
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      await _plugin.show(3, title, body, details);
    } catch (e) {
      debugPrint('Cooldown notification error: $e');
    }
  }

  /// 신고로 인한 임시 차단 알림 (발송자에게)
  static Future<void> showReportBlockNotification({
    required String title,
    required String body,
    String langCode = 'en',
  }) async {
    if (!_isAllowed(PushCategory.reportBlock)) return;
    try {
      final androidDetails = AndroidNotificationDetails(
        'report_block',
        _notiMsg('report_channel', langCode),
        channelDescription: _notiMsg('report_desc', langCode),
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      await _plugin.show(4, title, body, details);
    } catch (e) {
      debugPrint('Report block notification error: $e');
    }
  }

  /// Schedules a repeating local notification at `hour`:`minute` local time
  /// each day. Re-scheduling replaces the previous one, so it's safe to call
  /// on every app launch.
  static Future<void> scheduleDailyLetterReminder({
    int hour = 8,
    int minute = 0,
    String langCode = 'en',
  }) async {
    if (!_isAllowed(PushCategory.daily)) {
      await _plugin.cancel(_dailyReminderId);
      return;
    }
    try {
      await _plugin.cancel(_dailyReminderId);

      final now = tz.TZDateTime.now(tz.local);
      var first = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (!first.isAfter(now)) {
        first = first.add(const Duration(days: 1));
      }

      final title =
          _dailyReminderTitles[langCode] ?? _dailyReminderTitles['en']!;
      final body =
          _dailyReminderBodies[langCode] ?? _dailyReminderBodies['en']!;

      const androidDetails = AndroidNotificationDetails(
        'daily_letter_reminder',
        'Daily Letter Reminder',
        channelDescription:
            'Daily nudge to open the mailbox and read today\'s letters',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        _dailyReminderId,
        title,
        body,
        first,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Daily reminder schedule error: $e');
    }
  }

  static Future<void> cancelDailyLetterReminder() async {
    try {
      await _plugin.cancel(_dailyReminderId);
    } catch (e) {
      debugPrint('Daily reminder cancel error: $e');
    }
  }

  /// Schedules a one-shot local notification at `arrivalTime - 1h` that the
  /// next incoming letter is approaching. Passing an arrivalTime less than
  /// ~1h in the future is a no-op (no lead time left). Only one countdown
  /// is held at a time — calling this again replaces the previous slot.
  static Future<void> scheduleArrivalCountdown({
    required DateTime arrivalTime,
    required String senderCountry,
    required String senderFlag,
    String langCode = 'en',
  }) async {
    if (!_isAllowed(PushCategory.arrivalCountdown)) {
      await _plugin.cancel(_arrivalCountdownId);
      return;
    }
    try {
      await _plugin.cancel(_arrivalCountdownId);
      final fire = arrivalTime.subtract(const Duration(hours: 1));
      final now = DateTime.now();
      // 5분 이하 여유만 남았으면 굳이 알릴 가치가 낮다 — skip
      if (fire.isBefore(now.add(const Duration(minutes: 5)))) return;

      final title =
          _arrivalCountdownTitles[langCode] ?? _arrivalCountdownTitles['en']!;
      final body = _arrivalCountdownBody(langCode, senderFlag, senderCountry);

      const androidDetails = AndroidNotificationDetails(
        'letter_arrival_countdown',
        'Letter Arrival Countdown',
        channelDescription:
            'Anticipation ping about an hour before a letter arrives',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tzFire = tz.TZDateTime(
        tz.local,
        fire.year,
        fire.month,
        fire.day,
        fire.hour,
        fire.minute,
      );

      await _plugin.zonedSchedule(
        _arrivalCountdownId,
        title,
        body,
        tzFire,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Arrival countdown schedule error: $e');
    }
  }

  static Future<void> cancelArrivalCountdown() async {
    try {
      await _plugin.cancel(_arrivalCountdownId);
    } catch (e) {
      debugPrint('Arrival countdown cancel error: $e');
    }
  }

  /// Build 134: 쿠폰/교환권 유효기간 1일 전 만료 임박 알림을 예약한다.
  /// `letterId` 는 여러 쿠폰을 독립적으로 관리하기 위한 키 (SharedPreferences
  /// 와 무관하게 알림 시스템 내부 ID 로만 사용). ID 는 해시 기반이라 같은
  /// 레터 재예약 시 자동 치환됨.
  ///
  /// [expiresAt] 은 쿠폰의 만료 시각. 알림은 만료 24 시간 전에 발사.
  /// 이미 24 시간 이내이면 스킵 (너무 늦은 알림은 피로 유발).
  static Future<void> scheduleCouponExpiryReminder({
    required String letterId,
    required DateTime expiresAt,
    required String senderName,
    required bool isVoucher,
    String langCode = 'en',
  }) async {
    if (!_isAllowed(PushCategory.couponExpiry)) return;
    try {
      final id = _couponExpiryNotificationId(letterId);
      await _plugin.cancel(id); // 중복 예약 방지
      final fire = expiresAt.subtract(const Duration(hours: 24));
      final now = DateTime.now();
      // 이미 24시간 이내이거나 지난 쿠폰은 알림 불필요.
      if (fire.isBefore(now.add(const Duration(minutes: 1)))) return;

      final title = _couponExpiryTitle(langCode, isVoucher);
      final body = _couponExpiryBody(langCode, senderName, isVoucher);

      const androidDetails = AndroidNotificationDetails(
        'coupon_expiry_reminder',
        'Coupon expiry reminder',
        channelDescription: 'Alert 1 day before a coupon or voucher expires',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tzFire = tz.TZDateTime(
        tz.local,
        fire.year,
        fire.month,
        fire.day,
        fire.hour,
        fire.minute,
      );

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzFire,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Coupon expiry schedule error: $e');
    }
  }

  /// 예약된 쿠폰 만료 알림 취소 (사용 완료 · 편지 삭제 시).
  static Future<void> cancelCouponExpiryReminder(String letterId) async {
    try {
      await _plugin.cancel(_couponExpiryNotificationId(letterId));
    } catch (e) {
      debugPrint('Coupon expiry cancel error: $e');
    }
  }

  /// `letterId` 를 안정적인 양의 32-bit 정수로 매핑. 알림 시스템 ID 는 int
  /// 제한이 있어 hashCode 를 절대값 + 오프셋 (1000 부터 시작) 으로 clamp.
  static int _couponExpiryNotificationId(String letterId) {
    final h = letterId.hashCode.abs();
    return 1000 + (h % 1000000); // 1000 ~ 1_000_999 범위
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

String _couponExpiryTitle(String langCode, bool isVoucher) {
  final emoji = isVoucher ? '🎁' : '🎟';
  switch (langCode) {
    case 'ko': return '⏰ $emoji 내일 만료돼요';
    case 'ja': return '⏰ $emoji 明日で期限切れ';
    case 'zh': return '⏰ $emoji 明天就到期了';
    case 'fr': return '⏰ $emoji Expire demain';
    case 'de': return '⏰ $emoji Läuft morgen ab';
    case 'es': return '⏰ $emoji Caduca mañana';
    case 'pt': return '⏰ $emoji Expira amanhã';
    case 'ru': return '⏰ $emoji Истекает завтра';
    case 'tr': return '⏰ $emoji Yarın sona eriyor';
    case 'ar': return '⏰ $emoji تنتهي غدًا';
    case 'it': return '⏰ $emoji Scade domani';
    case 'hi': return '⏰ $emoji कल समाप्त';
    case 'th': return '⏰ $emoji พรุ่งนี้หมดอายุ';
    default: return '⏰ $emoji Expires tomorrow';
  }
}

String _couponExpiryBody(String langCode, String sender, bool isVoucher) {
  final kind = isVoucher
      ? (langCode == 'ko' ? '교환권' : 'voucher')
      : (langCode == 'ko' ? '할인권' : 'coupon');
  switch (langCode) {
    case 'ko': return '$sender의 $kind을(를) 오늘·내일 중에 사용하세요';
    case 'ja': return '$sender の$kind を今日か明日までに使ってください';
    case 'zh': return '请在今明两天内使用 $sender 的$kind';
    case 'fr': return "Utilisez le $kind de $sender aujourd'hui ou demain";
    case 'de': return 'Nutze den $kind von $sender heute oder morgen';
    case 'es': return 'Usa el $kind de $sender hoy o mañana';
    case 'pt': return 'Usa o $kind de $sender hoje ou amanhã';
    case 'ru': return 'Используйте $kind от $sender сегодня или завтра';
    case 'tr': return "$sender'in $kind'ini bugün veya yarın kullan";
    case 'ar': return 'استخدم $kind من $sender اليوم أو غدًا';
    case 'it': return 'Usa il $kind di $sender oggi o domani';
    case 'hi': return '$sender का $kind आज या कल तक उपयोग करें';
    case 'th': return 'ใช้$kindจาก $sender วันนี้หรือพรุ่งนี้';
    case 'en':
    default:
      return "Use $sender's $kind today or tomorrow";
  }
}
