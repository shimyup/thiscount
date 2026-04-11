import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

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
    'ko': '편지 도착 알림',
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
    'ko': '편지가 신고되어 임시 차단되었을 때 알림',
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

const Map<String, List<String>> _arrivedTitlesByLang = {
  'ko': [
    '💌 새 편지가 도착했어요!',
    '🌏 먼 곳에서 편지가 왔어요!',
    '📬 편지함에 새 편지!',
    '🎉 편지가 여행을 마쳤어요!',
    '🕊️ 편지가 무사히 도착했어요!',
    '🌊 바다를 건너 편지가 왔어요!',
    '✉️ 새로운 편지 소식!',
    '🗺️ 세계 어딘가에서 편지 도착!',
  ],
  'en': [
    '💌 A new letter has arrived!',
    '🌏 A letter from afar!',
    '📬 New letter in your mailbox!',
    '🎉 A letter finished its journey!',
    '🕊️ A letter arrived safely!',
    '🌊 A letter crossed the ocean!',
    '✉️ New letter alert!',
    '🗺️ Letter arrived from somewhere!',
  ],
  'ja': [
    '💌 新しい手紙が届きました！',
    '🌏 遠くから手紙が来ました！',
    '📬 新しい手紙です！',
    '🎉 手紙が旅を終えました！',
    '🕊️ 手紙が無事届きました！',
    '🌊 海を越えて手紙が来ました！',
    '✉️ 新しい手紙のお知らせ！',
    '🗺️ 世界のどこかから手紙到着！',
  ],
  'zh': [
    '💌 新信件到了！',
    '🌏 远方来信！',
    '📬 信箱里有新信！',
    '🎉 信件完成了旅程！',
    '🕊️ 信件安全到达！',
    '🌊 跨洋来信！',
    '✉️ 新信件提醒！',
    '🗺️ 来自某处的信件！',
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

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
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
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    try {
      // iOS / macOS
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);

      // Android 13+ (API 33+) — POST_NOTIFICATIONS 런타임 권한 필요
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission error: $e');
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
      'ko': '편지 도착 알림',
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

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
