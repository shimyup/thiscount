import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

/// SMS 발송 서비스 — Cloud Function relay 경유.
///
/// Build 412 (PII sim CRITICAL fix): 이전엔 Twilio Account SID/Auth Token 을
/// 클라이언트 바이너리에 컴파일해 직접 Twilio REST 를 호출했음. 키 추출 시
/// 임의 SMS 발송(요금 폭탄/스미싱) 가능. 이제 키는 Cloud Function
/// (`sendAuthSms`) 서버에만 있고, 클라이언트는 함수 URL(비밀 아님)로 ID 토큰 +
/// {to, code} 만 전달 → 함수가 토큰 검증 + 고정 OTP 템플릿으로만 발송.
/// 함수 URL 미설정 시 발송 스킵(null) → on-screen OTP fallback.
class SmsService {
  SmsService._();

  /// SMS relay 가 설정돼 있는지 (함수 URL 존재).
  static bool get isConfigured => FirebaseConfig.isSmsProviderEnabled;

  /// OTP 코드를 SMS로 발송 (relay 경유).
  /// [phoneNumber]는 국가번호 포함 E.164 형식 (예: +821012345678)
  static Future<String?> sendOtp({
    required String phoneNumber,
    required String code,
    String langCode = 'en',
  }) async {
    if (!isConfigured) {
      assert(() {
        debugPrint('[SmsService] relay 미설정 — SMS 발송 스킵 (화면 노출 fallback)');
        return true;
      }());
      return null;
    }
    try {
      await FirebaseAuthService.ensureValidToken();
      final response = await http
          .post(
            Uri.parse(FirebaseConfig.authSmsFnUrl),
            headers: FirestoreService.authHeaders,
            body: jsonEncode({
              'to': phoneNumber,
              'code': code,
              'langCode': langCode,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        assert(() {
          debugPrint('[SmsService] relay 발송 성공: ${_maskPhone(phoneNumber)}');
          return true;
        }());
        return null;
      }
      assert(() {
        debugPrint('[SmsService] relay 실패 (${response.statusCode})');
        return true;
      }());
      return _networkErrorMsg(langCode);
    } on SocketException {
      return _networkErrorMsg(langCode);
    } on TimeoutException {
      return _networkErrorMsg(langCode);
    } catch (e) {
      assert(() {
        debugPrint('[SmsService] relay 예외: $e');
        return true;
      }());
      return _networkErrorMsg(langCode);
    }
  }

  static String _networkErrorMsg(String langCode) {
    const m = <String, String>{
      'ko': 'SMS 발송 실패: 네트워크 연결을 확인해주세요.',
      'en': 'Failed to send SMS. Please check your connection.',
      'ja': 'SMS送信失敗: ネットワーク接続を確認してください。',
      'zh': '短信发送失败：请检查网络连接。',
    };
    return m[langCode] ?? m['en']!;
  }

  /// E.164 형식으로 전화번호 정규화.
  /// 국가코드가 이미 포함된 경우 그대로 반환, 아닌 경우 국가코드 추가.
  static String normalizePhoneNumber(String phone, String countryCode) {
    // 공백, 하이픈, 괄호 제거
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // 이미 + 시작이면 그대로
    if (cleaned.startsWith('+')) return cleaned;

    // 국가코드에서 + 확인
    if (!countryCode.startsWith('+')) {
      countryCode = '+$countryCode';
    }

    // 앞자리 0 제거 (국내 번호 형식)
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    return '$countryCode$cleaned';
  }

  /// Build 305: 디버그 로그용 전화번호 마스킹. assert 안에서만 호출되지만,
  /// debug 빌드 logcat 에서도 풀 번호가 안 보이도록 뒷 4자리만 노출.
  static String _maskPhone(String phone) {
    if (phone.length <= 4) return '****';
    return '${'*' * (phone.length - 4)}${phone.substring(phone.length - 4)}';
  }
}
