import 'package:flutter/foundation.dart';

/// FCM HTTP API를 통한 푸시 알림 서비스
/// 보안상 서버 키는 앱 클라이언트에 두면 안 되므로, 클라이언트 직접 전송을 비활성화한다.
/// 실제 푸시는 서버(Cloud Functions/백엔드)에서만 발송해야 한다.
class FcmPushService {
  // ── 특정 디바이스에 알림 전송 ─────────────────────────────────────────────
  static Future<bool> sendToDevice({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    required String serverKey, // Firebase 서버 키 (레거시 API)
  }) async {
    if (kDebugMode) debugPrint(
      '[FCMPush] blocked on client: use server-side push sender only.',
    );
    return false;
  }

  // ── 편지 도착 알림 ───────────────────────────────────────────────────────────
  static Future<void> sendLetterArrivedNotification({
    required String recipientToken,
    required String senderCountry,
    required String senderFlag,
    required String serverKey,
  }) async {
    await sendToDevice(
      deviceToken: recipientToken,
      title: '📩 새 쿠폰이 도착했어요!',
      body: '$senderFlag $senderCountry에서 보낸 쿠폰이 도착했습니다',
      data: {'type': 'letter_arrived'},
      serverKey: serverKey,
    );
  }

  // ── DM 알림 ─────────────────────────────────────────────────────────────────
  static Future<void> sendDMNotification({
    required String recipientToken,
    required String senderName,
    required String message,
    required String serverKey,
  }) async {
    await sendToDevice(
      deviceToken: recipientToken,
      title: '💬 $senderName님의 DM',
      body: message.length > 40 ? '${message.substring(0, 40)}...' : message,
      data: {'type': 'dm_arrived'},
      serverKey: serverKey,
    );
  }
}
