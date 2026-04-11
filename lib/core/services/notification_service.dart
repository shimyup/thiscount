import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
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

  // ── Localized letter-arrived notification text ─────────────────────────────
  static const _arrivedTitles = <String, List<String>>{
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
      '🌏 A letter from far away!',
      '📬 New letter in your mailbox!',
      '🎉 A letter finished its journey!',
      '🕊️ A letter arrived safely!',
      '🌊 A letter crossed the ocean!',
      '✉️ New letter news!',
      '🗺️ A letter arrived from somewhere in the world!',
    ],
    'ja': [
      '💌 新しい手紙が届きました！',
      '🌏 遠くから手紙が届きました！',
      '📬 メールボックスに新しい手紙！',
      '🎉 手紙が旅を終えました！',
      '🕊️ 手紙が無事に届きました！',
      '🌊 海を越えて手紙が届きました！',
      '✉️ 新しい手紙のお知らせ！',
      '🗺️ 世界のどこかから手紙が到着！',
    ],
    'zh': [
      '💌 新信件已到达！',
      '🌏 远方来信！',
      '📬 邮箱里有新信件！',
      '🎉 信件完成了旅程！',
      '🕊️ 信件安全到达！',
      '🌊 信件漂洋过海而来！',
      '✉️ 新信件消息！',
      '🗺️ 来自世界某处的信件到达！',
    ],
  };

  // Body templates use {flag} and {country} placeholders replaced at runtime.
  static const _arrivedBodyTemplates = <String, List<String>>{
    'ko': [
      '{flag} {country}에서 보낸 편지가 도착했습니다',
      '{flag} {country} 누군가의 이야기가 당신을 향해 왔어요',
      '{flag} {country}에서 출발한 편지가 목적지에 도착!',
      '{flag} {country}의 마음이 담긴 편지가 왔어요',
      '먼 {flag} {country}에서 편지병이 떠내려왔어요',
      '{flag} {country} 편지가 긴 여행을 마치고 도착했어요',
    ],
    'en': [
      'A letter from {flag} {country} has arrived',
      'Someone in {flag} {country} sent you their story',
      'A letter from {flag} {country} reached its destination!',
      'A heartfelt letter from {flag} {country} is here',
      'A bottle letter drifted in from {flag} {country}',
      'A letter from {flag} {country} finished its long journey',
    ],
    'ja': [
      '{flag} {country}から手紙が届きました',
      '{flag} {country}の誰かの物語があなたに届きました',
      '{flag} {country}から出発した手紙が目的地に到着！',
      '{flag} {country}の心のこもった手紙が届きました',
      '遠い{flag} {country}からボトルメールが漂着しました',
      '{flag} {country}の手紙が長い旅を終えて届きました',
    ],
    'zh': [
      '来自{flag} {country}的信件已到达',
      '{flag} {country}某人的故事向你飞来了',
      '从{flag} {country}出发的信件到达目的地！',
      '来自{flag} {country}的真挚信件到了',
      '远方{flag} {country}的漂流信到了',
      '{flag} {country}的信件完成了漫长旅程',
    ],
  };

  // ── Localized DM notification text ─────────────────────────────────────────
  static const _dmTitleTemplates = <String, String>{
    'ko': '💬 {name}님의 메시지',
    'en': '💬 Message from {name}',
    'ja': '💬 {name}さんからのメッセージ',
    'zh': '💬 来自{name}的消息',
  };

  static final Random _rng = Random();

  static Future<void> showNearbyLetterNotification({
    required String title,
    required String body,
    String langCode = 'ko',
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'nearby_letter',
        _ch('nearby_letter', langCode),
        channelDescription: _ch('nearby_letter_desc', langCode),
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
    String langCode = 'ko',
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'letter_arrived',
        _ch('letter_arrived', langCode),
        channelDescription: _ch('letter_arrived_desc', langCode),
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

      final titles = _arrivedTitles[langCode] ?? _arrivedTitles['ko']!;
      final title = titles[_rng.nextInt(titles.length)];

      final bodyTemplates =
          _arrivedBodyTemplates[langCode] ?? _arrivedBodyTemplates['ko']!;
      final template = bodyTemplates[_rng.nextInt(bodyTemplates.length)];
      final body = template
          .replaceAll('{flag}', senderFlag)
          .replaceAll('{country}', senderCountry);

      await _plugin.show(1, title, body, details);
    } catch (e) {
      debugPrint('Letter notification error: $e');
    }
  }

  static Future<void> showDMArrivedNotification({
    required String senderName,
    required String message,
    String langCode = 'ko',
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'dm_arrived',
        _ch('dm_arrived', langCode),
        channelDescription: _ch('dm_arrived_desc', langCode),
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

      final titleTemplate = _dmTitleTemplates[langCode] ?? _dmTitleTemplates['ko']!;
      final title = titleTemplate.replaceAll('{name}', senderName);

      await _plugin.show(
        2,
        title,
        message.length > 40 ? '${message.substring(0, 40)}...' : message,
        details,
      );
    } catch (e) {
      debugPrint('DM notification error: $e');
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
