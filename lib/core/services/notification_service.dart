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

  static Future<void> showNearbyLetterNotification({
    required String title,
    required String body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'nearby_letter',
        '근처 편지 알림',
        channelDescription: '500m 이내에 편지가 도착했을 때 알림',
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
      await _plugin.show(0, title, body, details);
    } catch (e) {
      debugPrint('Notification show error: $e');
    }
  }

  static final Random _rng = Random();

  static const _arrivedTitles = [
    '💌 새 편지가 도착했어요!',
    '🌏 먼 곳에서 편지가 왔어요!',
    '📬 편지함에 새 편지!',
    '🎉 편지가 여행을 마쳤어요!',
    '🕊️ 편지가 무사히 도착했어요!',
    '🌊 바다를 건너 편지가 왔어요!',
    '✉️ 새로운 편지 소식!',
    '🗺️ 세계 어딘가에서 편지 도착!',
  ];

  static List<String> _arrivedBodies(String flag, String country) => [
    '$flag $country에서 보낸 편지가 도착했습니다',
    '$flag $country 누군가의 이야기가 당신을 향해 왔어요',
    '$flag $country에서 출발한 편지가 목적지에 도착!',
    '$flag $country의 마음이 담긴 편지가 왔어요',
    '먼 $flag $country에서 편지병이 떠내려왔어요',
    '$flag $country 편지가 긴 여행을 마치고 도착했어요',
  ];

  static Future<void> showLetterArrivedNotification({
    required String senderCountry,
    required String senderFlag,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'letter_arrived',
        '편지 도착 알림',
        channelDescription: '새 편지가 도착했을 때 알림',
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

      final title = _arrivedTitles[_rng.nextInt(_arrivedTitles.length)];
      final bodies = _arrivedBodies(senderFlag, senderCountry);
      final body = bodies[_rng.nextInt(bodies.length)];

      await _plugin.show(1, title, body, details);
    } catch (e) {
      debugPrint('Letter notification error: $e');
    }
  }

  static Future<void> showDMArrivedNotification({
    required String senderName,
    required String message,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'dm_arrived',
        'DM 도착 알림',
        channelDescription: '새 DM이 도착했을 때 알림',
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
      await _plugin.show(
        2,
        '💬 $senderName님의 메시지',
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
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'pickup_cooldown',
        '픽업 쿨다운 알림',
        channelDescription: '근처 편지가 있지만 쿨다운으로 픽업할 수 없을 때 알림',
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
      await _plugin.show(3, title, body, details);
    } catch (e) {
      debugPrint('Cooldown notification error: $e');
    }
  }

  /// 신고로 인한 임시 차단 알림 (발송자에게)
  static Future<void> showReportBlockNotification({
    required String title,
    required String body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'report_block',
        '신고 알림',
        channelDescription: '편지가 신고되어 임시 차단되었을 때 알림',
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
      await _plugin.show(4, title, body, details);
    } catch (e) {
      debugPrint('Report block notification error: $e');
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
