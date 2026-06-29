import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

/// 이메일 발송 서비스 — Cloud Function relay 경유.
///
/// Build 412 (PII sim CRITICAL fix): 이전엔 Resend/SendGrid 서버급 API 키를
/// 클라이언트 바이너리에 컴파일해 직접 api.resend.com 을 호출했음. 공격자가
/// 바이너리에서 키를 추출해 도메인 사칭 피싱 → 계정 탈취가 가능 (CRITICAL).
/// 이제 키는 Cloud Function(`sendAuthEmail`) 서버에만 있고, 클라이언트는 함수
/// URL(비밀 아님)로 ID 토큰 + {type, code} 만 전달한다. 함수가 토큰 검증 +
/// 고정 템플릿으로만 발송 → 임의 본문/도메인 사칭 불가. OTP 코드 자체는 기존과
/// 동일하게 클라이언트가 생성·검증(이메일 소유 확인 용도)한다.
///
/// 함수 URL 미설정(빈 값) 시 발송을 스킵하고 null 반환 → auth_screen 이
/// on-screen OTP fallback 표시 (개발/미배포 환경에서 흐름 유지).
class EmailService {
  EmailService._();

  /// relay 가 설정돼 있는지 (함수 URL 존재).
  static bool get isConfigured => FirebaseConfig.isEmailProviderEnabled;

  /// OTP 인증 이메일 발송. 성공/미설정 시 null, 실패 시 에러 메시지.
  static Future<String?> sendOtp({
    required String to,
    required String code,
    String langCode = 'en',
  }) {
    return _send(
      type: 'otp',
      to: to,
      code: code,
      langCode: langCode,
    );
  }

  /// 임시 비밀번호 이메일 발송.
  static Future<String?> sendTempPassword({
    required String to,
    required String tempPassword,
    required int expiresInMinutes,
    String langCode = 'en',
  }) {
    return _send(
      type: 'tempPassword',
      to: to,
      code: tempPassword,
      expiresInMinutes: expiresInMinutes,
      langCode: langCode,
    );
  }

  static Future<String?> _send({
    required String type,
    required String to,
    required String code,
    int? expiresInMinutes,
    required String langCode,
  }) async {
    if (!isConfigured) {
      // relay 미설정 — auth_screen 의 on-screen OTP fallback 으로 표시.
      assert(() {
        debugPrint('[EmailService] relay 미설정 — 발송 스킵 (화면 노출 fallback)');
        return true;
      }());
      return null;
    }
    try {
      // ID 토큰 확보 (함수가 verifyIdToken 으로 호출자 인증).
      await FirebaseAuthService.ensureValidToken();
      final response = await http
          .post(
            Uri.parse(FirebaseConfig.authEmailFnUrl),
            headers: FirestoreService.authHeaders,
            body: jsonEncode({
              'type': type,
              'to': to,
              'code': code,
              if (expiresInMinutes != null)
                'expiresInMinutes': expiresInMinutes,
              'langCode': langCode,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        assert(() {
          debugPrint('[EmailService] relay 발송 성공: ${_maskEmail(to)}');
          return true;
        }());
        return null;
      }
      assert(() {
        debugPrint('[EmailService] relay 실패 (${response.statusCode})');
        return true;
      }());
      return _networkErrorMsg(langCode);
    } on SocketException {
      return _networkErrorMsg(langCode);
    } on TimeoutException {
      return _networkErrorMsg(langCode);
    } catch (e) {
      assert(() {
        debugPrint('[EmailService] relay 예외: $e');
        return true;
      }());
      return _networkErrorMsg(langCode);
    }
  }

  // ── 네트워크 에러 메시지 ────────────────────────────────────────────────────
  static String _networkErrorMsg(String langCode) {
    const msgs = <String, String>{
      'ko': '이메일 발송 실패: 네트워크 연결을 확인해주세요.',
      'en': 'Failed to send email. Please check your connection.',
      'ja': 'メール送信失敗: ネットワーク接続を確認してください。',
      'zh': '邮件发送失败：请检查网络连接。',
      'fr': 'Échec d\'envoi de l\'e-mail. Vérifiez votre connexion.',
      'de': 'E-Mail-Versand fehlgeschlagen. Netzwerkverbindung prüfen.',
      'es': 'Error al enviar el correo. Comprueba tu conexión.',
      'pt': 'Falha ao enviar e-mail. Verifique sua conexão.',
      'ru': 'Ошибка отправки email. Проверьте подключение к сети.',
    };
    return msgs[langCode] ?? msgs['en']!;
  }

  /// 디버그 로그용 이메일 마스킹 (assert 안에서만 호출).
  static String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 0) return '***';
    final local = email.substring(0, at);
    final domain = email.substring(at);
    final keep = local.length <= 2 ? 1 : 2;
    return '${local.substring(0, keep)}***$domain';
  }
}
