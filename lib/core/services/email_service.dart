import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';

/// 이메일 발송 서비스 (SendGrid REST API)
///
/// 빌드 시 dart-define 으로 인증 정보를 주입:
///   --dart-define=SENDGRID_API_KEY=SG.xxxxxxxxxx
///   --dart-define=SENDGRID_FROM_EMAIL=noreply@yourdomain.com
class EmailService {
  EmailService._();

  static const String _sendgridUrl =
      'https://api.sendgrid.com/v3/mail/send';
  static const String _resendUrl = 'https://api.resend.com/emails';

  /// 이메일 발송 프로바이더가 하나라도 설정되어 있는지.
  /// Resend 우선, SendGrid 폴백.
  static bool get isConfigured => FirebaseConfig.isEmailProviderEnabled;

  /// OTP 인증 이메일 발송.
  /// 성공 시 null 반환, 실패 시 에러 메시지 반환.
  ///
  /// 프로바이더 선택 우선순위:
  ///   1) Resend  (RESEND_API_KEY + RESEND_FROM_EMAIL)
  ///   2) SendGrid (SENDGRID_API_KEY + SENDGRID_FROM_EMAIL)
  ///   3) 미설정 — null 반환 (auth_screen 에서 on-screen OTP fallback)
  static Future<String?> sendOtp({
    required String to,
    required String code,
    String langCode = 'en',
  }) async {
    if (!isConfigured) {
      // 개발/베타 환경: 이메일 프로바이더 미설정 시 성공 처리
      // (OTP 는 auth_screen 의 on-screen fallback 으로 표시됨)
      assert(() {
        debugPrint('[EmailService] 이메일 프로바이더 미설정 — 발송 스킵 (화면 노출 fallback)');
        return true;
      }());
      return null;
    }

    final subject = _otpSubject(langCode);
    final htmlBody = _otpHtmlBody(code, langCode);
    final textBody = _otpTextBody(code, langCode);

    // Resend 우선 시도
    if (FirebaseConfig.isResendEnabled) {
      final err = await _sendViaResend(
        to: to,
        subject: subject,
        htmlBody: htmlBody,
        textBody: textBody,
        langCode: langCode,
      );
      if (err == null) return null; // 성공
      // Resend 가 실패했고 SendGrid 가 설정되어 있으면 폴백
      if (!FirebaseConfig.isSendgridEnabled) return err;
      assert(() {
        debugPrint('[EmailService] Resend 실패 → SendGrid 폴백');
        return true;
      }());
    }

    // SendGrid 경로
    return _sendViaSendgrid(
      to: to,
      subject: subject,
      htmlBody: htmlBody,
      textBody: textBody,
      langCode: langCode,
    );
  }

  /// Resend API 로 발송.
  static Future<String?> _sendViaResend({
    required String to,
    required String subject,
    required String htmlBody,
    required String textBody,
    required String langCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_resendUrl),
            headers: {
              'Authorization': 'Bearer ${FirebaseConfig.resendApiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'from': 'Thiscount <${FirebaseConfig.resendFromEmail}>',
              'to': [to],
              'subject': subject,
              'html': htmlBody,
              'text': textBody,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        assert(() {
          debugPrint('[EmailService] Resend 발송 성공: $to');
          return true;
        }());
        return null; // 성공
      }

      // Resend 에러 파싱
      String errorMsg = '이메일 발송에 실패했습니다.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        errorMsg = (body['message'] as String?) ?? errorMsg;
      } catch (_) {}
      assert(() {
        debugPrint('[EmailService] Resend 실패 (${response.statusCode}): $errorMsg');
        return true;
      }());
      return _networkErrorMsg(langCode);
    } on SocketException {
      return _networkErrorMsg(langCode);
    } on TimeoutException {
      return _networkErrorMsg(langCode);
    } catch (e) {
      assert(() {
        debugPrint('[EmailService] Resend 예외: $e');
        return true;
      }());
      return _networkErrorMsg(langCode);
    }
  }

  /// SendGrid API 로 발송 (폴백).
  static Future<String?> _sendViaSendgrid({
    required String to,
    required String subject,
    required String htmlBody,
    required String textBody,
    required String langCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_sendgridUrl),
            headers: {
              'Authorization': 'Bearer ${FirebaseConfig.sendgridApiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'personalizations': [
                {
                  'to': [{'email': to}],
                },
              ],
              'from': {'email': FirebaseConfig.sendgridFromEmail, 'name': 'Thiscount'},
              'subject': subject,
              'content': [
                {'type': 'text/plain', 'value': textBody},
                {'type': 'text/html', 'value': htmlBody},
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 202) {
        assert(() {
          debugPrint('[EmailService] SendGrid 발송 성공: $to');
          return true;
        }());
        return null; // 성공
      }

      // SendGrid 에러 처리
      String errorMsg = '이메일 발송에 실패했습니다.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final errors = body['errors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          errorMsg = errors.first['message'] as String? ?? errorMsg;
        }
      } catch (_) {}
      assert(() {
        debugPrint('[EmailService] SendGrid 실패 (${response.statusCode}): $errorMsg');
        return true;
      }());
      return _networkErrorMsg(langCode);
    } on SocketException {
      return _networkErrorMsg(langCode);
    } on TimeoutException {
      return _networkErrorMsg(langCode);
    } catch (e) {
      assert(() {
        debugPrint('[EmailService] SendGrid 예외: $e');
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

  // ── 이메일 제목 ─────────────────────────────────────────────────────────────
  static String _otpSubject(String langCode) {
    const subjects = <String, String>{
      'ko': '[Thiscount] 이메일 인증 코드',
      'en': '[Thiscount] Email Verification Code',
      'ja': '[Thiscount] メール認証コード',
      'zh': '[Thiscount] 邮箱验证码',
      'fr': '[Thiscount] Code de vérification par e-mail',
      'de': '[Thiscount] E-Mail-Bestätigungscode',
      'es': '[Thiscount] Código de verificación de correo',
      'pt': '[Thiscount] Código de verificação de e-mail',
      'ru': '[Thiscount] Код подтверждения электронной почты',
    };
    return subjects[langCode] ?? subjects['en']!;
  }

  // ── 이메일 텍스트 본문 ────────────────────────────────────────────────────────
  static String _otpTextBody(String code, String langCode) {
    switch (langCode) {
      case 'ko':
        return 'Thiscount 인증 코드: $code\n이 코드는 10분 동안 유효합니다.\n본인이 요청하지 않은 경우 이 이메일을 무시하세요.';
      case 'ja':
        return 'Thiscount 認証コード: $code\nこのコードは10分間有効です。\nご自身が申請していない場合は、このメールを無視してください。';
      case 'zh':
        return 'Thiscount 验证码: $code\n此验证码10分钟内有效。\n如非本人操作，请忽略此邮件。';
      case 'fr':
        return 'Code de vérification Thiscount: $code\nCe code est valable 10 minutes.\nSi vous n\'avez pas fait cette demande, ignorez cet e-mail.';
      case 'de':
        return 'Thiscount Bestätigungscode: $code\nDieser Code ist 10 Minuten gültig.\nWenn Sie diese Anfrage nicht gestellt haben, ignorieren Sie diese E-Mail.';
      case 'es':
        return 'Código de verificación de Thiscount: $code\nEste código es válido por 10 minutos.\nSi no solicitaste esto, ignora este correo.';
      case 'pt':
        return 'Código de verificação Thiscount: $code\nEste código é válido por 10 minutos.\nSe não foi você, ignore este e-mail.';
      case 'ru':
        return 'Код подтверждения Thiscount: $code\nКод действителен 10 минут.\nЕсли вы не запрашивали это, проигнорируйте письмо.';
      default:
        return 'Thiscount verification code: $code\nThis code is valid for 10 minutes.\nIf you did not request this, please ignore this email.';
    }
  }

  // ── 이메일 HTML 본문 ─────────────────────────────────────────────────────────
  static String _otpHtmlBody(String code, String langCode) {
    final subject = _otpSubject(langCode);
    final textContent = _otpTextBody(code, langCode)
        .replaceAll('\n', '<br>');
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: sans-serif; background: #070B14; color: #E8E8E0; margin: 0; padding: 20px; }
    .card { background: #111827; border-radius: 16px; padding: 32px; max-width: 480px; margin: 0 auto; }
    .logo { text-align: center; font-size: 48px; margin-bottom: 8px; }
    .title { text-align: center; font-size: 22px; font-weight: bold; color: #F0C35A; margin-bottom: 24px; }
    .code-box { background: #1E293B; border: 2px solid #F0C35A; border-radius: 12px; padding: 20px;
                text-align: center; font-size: 36px; font-weight: bold; letter-spacing: 8px;
                color: #F0C35A; margin: 24px 0; }
    .note { font-size: 13px; color: #9CA3AF; text-align: center; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">🍾</div>
    <div class="title">Thiscount</div>
    <p style="text-align:center; margin-bottom: 8px;">$subject</p>
    <div class="code-box">$code</div>
    <p class="note">$textContent</p>
  </div>
</body>
</html>
''';
  }
}
