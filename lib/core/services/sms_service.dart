import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';

/// Twilio REST API를 사용한 SMS 발송 서비스.
///
/// 빌드 시 dart-define 으로 인증 정보를 주입:
///   --dart-define=TWILIO_ACCOUNT_SID=ACxxxxxxxxxx
///   --dart-define=TWILIO_AUTH_TOKEN=xxxxxxxxxx
///   --dart-define=TWILIO_FROM_NUMBER=+1xxxxxxxxxx
class SmsService {
  SmsService._();

  /// Twilio 설정이 유효한지 확인
  static bool get isConfigured =>
      FirebaseConfig.twilioAccountSid.isNotEmpty &&
      FirebaseConfig.twilioAuthToken.isNotEmpty &&
      FirebaseConfig.twilioFromNumber.isNotEmpty;

  /// SMS 발송.
  /// 성공 시 null 반환, 실패 시 에러 메시지 반환.
  static Future<String?> sendSms({
    required String to,
    required String body,
  }) async {
    if (!isConfigured) {
      assert(() {
        debugPrint('[SmsService] Twilio 미설정 — SMS 발송 스킵');
        return true;
      }());
      // 개발 환경에서 Twilio 미설정 시 성공 처리 (OTP는 화면에 표시)
      return null;
    }

    final accountSid = FirebaseConfig.twilioAccountSid;
    final authToken = FirebaseConfig.twilioAuthToken;
    final fromNumber = FirebaseConfig.twilioFromNumber;

    final url = Uri.parse(
      'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json',
    );

    final credentials = base64Encode(utf8.encode('$accountSid:$authToken'));

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': to,
          'From': fromNumber,
          'Body': body,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        assert(() {
          debugPrint('[SmsService] SMS 발송 성공: $to');
          return true;
        }());
        return null; // 성공
      }

      // 에러 처리
      final errorBody = jsonDecode(response.body);
      final errorMsg = errorBody['message'] ?? 'Unknown error';
      assert(() {
        debugPrint('[SmsService] SMS 발송 실패 (${response.statusCode}): $errorMsg');
        return true;
      }());
      return 'SMS sending failed: $errorMsg';
    } catch (e) {
      assert(() {
        debugPrint('[SmsService] SMS 발송 예외: $e');
        return true;
      }());
      return 'SMS sending failed: ${e.toString()}';
    }
  }

  /// OTP 코드를 SMS로 발송.
  /// [phoneNumber]는 국가번호 포함 E.164 형식 (예: +821012345678)
  static Future<String?> sendOtp({
    required String phoneNumber,
    required String code,
    String langCode = 'en',
  }) {
    final message = _otpMessage(code, langCode);
    return sendSms(to: phoneNumber, body: message);
  }

  /// 언어별 OTP 메시지 생성
  static String _otpMessage(String code, String langCode) {
    switch (langCode) {
      case 'ko':
        return '[Thiscount] 인증번호: $code (10분 유효)';
      case 'ja':
        return '[Thiscount] 認証コード: $code（10分間有効）';
      case 'zh':
        return '[Thiscount] 验证码: $code（10分钟有效）';
      case 'fr':
        return '[Thiscount] Code de vérification: $code (valide 10 min)';
      case 'de':
        return '[Thiscount] Bestätigungscode: $code (10 Min. gültig)';
      case 'es':
        return '[Thiscount] Código de verificación: $code (válido 10 min)';
      case 'pt':
        return '[Thiscount] Código de verificação: $code (válido por 10 min)';
      case 'ru':
        return '[Thiscount] Код подтверждения: $code (действителен 10 мин)';
      case 'tr':
        return '[Thiscount] Doğrulama kodu: $code (10 dk geçerli)';
      case 'ar':
        return '[Thiscount] رمز التحقق: $code (صالح لمدة 10 دقائق)';
      case 'it':
        return '[Thiscount] Codice di verifica: $code (valido 10 min)';
      case 'hi':
        return '[Thiscount] सत्यापन कोड: $code (10 मिनट के लिए वैध)';
      case 'th':
        return '[Thiscount] รหัสยืนยัน: $code (ใช้ได้ 10 นาที)';
      default:
        return '[Thiscount] Verification code: $code (valid for 10 min)';
    }
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
}
