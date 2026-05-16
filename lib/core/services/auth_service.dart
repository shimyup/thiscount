import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/app_keys.dart';
import '../config/firebase_config.dart';
import '../localization/language_config.dart';
import 'firestore_service.dart';
import 'firebase_auth_service.dart';
import 'purchase_service.dart';
import 'sms_service.dart';

/// Auth error message localization helper.
/// Returns localized string for a given key based on language code.
String _authMsg(String key, [String langCode = 'en']) {
  return (_authMessages[key]?[langCode]) ??
      (_authMessages[key]?['en']) ??
      key;
}

const Map<String, Map<String, String>> _authMessages = {
  'otp_not_found': {
    'ko': '인증 코드가 없습니다. 다시 요청해주세요.',
    'en': 'No verification code found. Please request a new one.',
    'ja': '認証コードがありません。再度リクエストしてください。',
    'zh': '没有验证码。请重新请求。',
    'es': 'No se encontró el código. Solicite uno nuevo.',
    'fr': 'Aucun code trouvé. Veuillez en demander un nouveau.',
    'de': 'Kein Code gefunden. Bitte fordern Sie einen neuen an.',
    'pt': 'Código não encontrado. Solicite um novo.',
    'ru': 'Код не найден. Запросите новый.',
  },
  'otp_email_mismatch': {
    'ko': '이메일이 일치하지 않습니다.',
    'en': 'Email does not match.',
    'ja': 'メールアドレスが一致しません。',
    'zh': '邮箱不匹配。',
    'es': 'El correo no coincide.',
    'fr': 'L\'e-mail ne correspond pas.',
    'de': 'E-Mail stimmt nicht überein.',
    'pt': 'O e-mail não corresponde.',
    'ru': 'Email не совпадает.',
  },
  'otp_phone_mismatch': {
    'ko': '전화번호가 일치하지 않습니다.',
    'en': 'Phone number does not match.',
    'ja': '電話番号が一致しません。',
    'zh': '手机号码不匹配。',
    'es': 'El número de teléfono no coincide.',
    'fr': 'Le numéro de téléphone ne correspond pas.',
    'de': 'Telefonnummer stimmt nicht überein.',
    'pt': 'O número de telefone não corresponde.',
    'ru': 'Номер телефона не совпадает.',
  },
  'otp_expired': {
    'ko': '인증 코드가 만료되었습니다. 다시 요청해주세요.',
    'en': 'Verification code expired. Please request a new one.',
    'ja': '認証コードの有効期限が切れました。再度リクエストしてください。',
    'zh': '验证码已过期。请重新请求。',
    'es': 'El código ha expirado. Solicite uno nuevo.',
    'fr': 'Le code a expiré. Veuillez en demander un nouveau.',
    'de': 'Code abgelaufen. Bitte fordern Sie einen neuen an.',
    'pt': 'Código expirado. Solicite um novo.',
    'ru': 'Код истёк. Запросите новый.',
  },
  'otp_invalid': {
    'ko': '인증 코드가 올바르지 않습니다.',
    'en': 'Invalid verification code.',
    'ja': '認証コードが正しくありません。',
    'zh': '验证码不正确。',
    'es': 'Código de verificación incorrecto.',
    'fr': 'Code de vérification incorrect.',
    'de': 'Ungültiger Bestätigungscode.',
    'pt': 'Código de verificação inválido.',
    'ru': 'Неверный код подтверждения.',
  },
  'otp_too_many_attempts': {
    'ko': '인증 실패가 너무 많습니다. 인증 코드를 다시 요청해주세요.',
    'en': 'Too many failed attempts. Please request a new code.',
    'ja': '認証失敗が多すぎます。新しいコードをリクエストしてください。',
    'zh': '验证失败次数过多。请重新请求验证码。',
    'es': 'Demasiados intentos fallidos. Solicite un nuevo código.',
    'fr': 'Trop d\'échecs. Demandez un nouveau code.',
    'de': 'Zu viele Fehlversuche. Bitte neuen Code anfordern.',
    'pt': 'Muitas tentativas falhas. Solicite um novo código.',
    'ru': 'Слишком много неудачных попыток. Запросите новый код.',
  },
  'username_min': {
    'ko': '2자 이상 입력해주세요',
    'en': 'Must be at least 2 characters',
    'ja': '2文字以上入力してください',
    'zh': '至少输入2个字符',
    'es': 'Mínimo 2 caracteres',
    'fr': 'Minimum 2 caractères',
    'de': 'Mindestens 2 Zeichen',
    'pt': 'Mínimo 2 caracteres',
    'ru': 'Минимум 2 символа',
  },
  'username_max': {
    'ko': '20자 이하로 입력해주세요',
    'en': 'Must be 20 characters or less',
    'ja': '20文字以下で入力してください',
    'zh': '不超过20个字符',
    'es': 'Máximo 20 caracteres',
    'fr': 'Maximum 20 caractères',
    'de': 'Maximal 20 Zeichen',
    'pt': 'Máximo 20 caracteres',
    'ru': 'Максимум 20 символов',
  },
  'username_format': {
    'ko': '영문으로 시작, 영문·숫자·_ 만 사용 가능',
    'en': 'Must start with a letter; only letters, numbers, and _ allowed',
    'ja': '英字で始まり、英数字と_のみ使用可能',
    'zh': '以字母开头，仅允许字母、数字和_',
    'es': 'Debe empezar con letra; solo letras, números y _',
    'fr': 'Doit commencer par une lettre ; lettres, chiffres et _ uniquement',
    'de': 'Muss mit Buchstabe beginnen; nur Buchstaben, Zahlen und _',
    'pt': 'Deve começar com letra; apenas letras, números e _',
    'ru': 'Должно начинаться с буквы; только буквы, цифры и _',
  },
  'password_format': {
    'ko': '영문+숫자를 포함한 8~20자를 입력해주세요',
    'en': 'Must be 8-20 characters with letters and numbers',
    'ja': '英文と数字を含む8〜20文字を入力してください',
    'zh': '请输入包含字母和数字的8-20个字符',
    'es': '8-20 caracteres con letras y números',
    'fr': '8-20 caractères avec lettres et chiffres',
    'de': '8-20 Zeichen mit Buchstaben und Zahlen',
    'pt': '8-20 caracteres com letras e números',
    'ru': '8-20 символов с буквами и цифрами',
  },
  'email_required': {
    'ko': '이메일을 입력해주세요.',
    'en': 'Please enter your email.',
    'ja': 'メールアドレスを入力してください。',
    'zh': '请输入邮箱。',
    'es': 'Ingrese su correo electrónico.',
    'fr': 'Veuillez entrer votre e-mail.',
    'de': 'Bitte E-Mail eingeben.',
    'pt': 'Insira seu e-mail.',
    'ru': 'Введите email.',
  },
  'email_invalid': {
    'ko': '올바른 이메일 형식이 아닙니다.',
    'en': 'Invalid email format.',
    'ja': 'メールアドレスの形式が正しくありません。',
    'zh': '邮箱格式不正确。',
    'es': 'Formato de correo no válido.',
    'fr': 'Format d\'e-mail invalide.',
    'de': 'Ungültiges E-Mail-Format.',
    'pt': 'Formato de e-mail inválido.',
    'ru': 'Неверный формат email.',
  },
  'username_taken': {
    'ko': '이미 사용 중인 아이디입니다. 다른 아이디를 입력해주세요.',
    'en': 'This username is already taken. Please choose another.',
    'ja': 'このユーザー名は既に使用されています。別の名前を入力してください。',
    'zh': '用户名已被使用。请选择其他用户名。',
    'es': 'Nombre de usuario en uso. Elija otro.',
    'fr': 'Nom d\'utilisateur déjà pris. Choisissez-en un autre.',
    'de': 'Benutzername bereits vergeben. Bitte wählen Sie einen anderen.',
    'pt': 'Nome de usuário já em uso. Escolha outro.',
    'ru': 'Имя пользователя занято. Выберите другое.',
  },
  'email_taken': {
    'ko': '이미 가입된 이메일입니다. 다른 이메일을 사용하거나 로그인해주세요.',
    'en': 'This email is already registered. Use another or sign in.',
    'ja': 'このメールは既に登録されています。他のメールを使用するかログインしてください。',
    'zh': '该邮箱已注册。请使用其他邮箱或登录。',
    'es': 'Este correo ya está registrado. Use otro o inicie sesión.',
    'fr': 'Cet e-mail est déjà enregistré. Utilisez-en un autre ou connectez-vous.',
    'de': 'Diese E-Mail ist bereits registriert. Verwenden Sie eine andere oder melden Sie sich an.',
    'pt': 'Este e-mail já está cadastrado. Use outro ou faça login.',
    'ru': 'Email уже зарегистрирован. Используйте другой или войдите.',
  },
  'nickname_required': {
    'ko': '닉네임을 입력해주세요.',
    'en': 'Please enter your username.',
    'ja': 'ユーザー名を入力してください。',
    'zh': '请输入用户名。',
    'es': 'Ingrese su nombre de usuario.',
    'fr': 'Veuillez entrer votre nom d\'utilisateur.',
    'de': 'Bitte Benutzernamen eingeben.',
    'pt': 'Insira seu nome de usuário.',
    'ru': 'Введите имя пользователя.',
  },
  'password_required': {
    'ko': '비밀번호를 입력해주세요.',
    'en': 'Please enter your password.',
    'ja': 'パスワードを入力してください。',
    'zh': '请输入密码。',
    'es': 'Ingrese su contraseña.',
    'fr': 'Veuillez entrer votre mot de passe.',
    'de': 'Bitte Passwort eingeben.',
    'pt': 'Insira sua senha.',
    'ru': 'Введите пароль.',
  },
  'no_account': {
    'ko': '등록된 계정이 없습니다. 회원가입을 먼저 해주세요.',
    'en': 'No account found. Please sign up first.',
    'ja': 'アカウントが見つかりません。先に会員登録してください。',
    'zh': '未找到账户。请先注册。',
    'es': 'No se encontró cuenta. Regístrese primero.',
    'fr': 'Aucun compte trouvé. Inscrivez-vous d\'abord.',
    'de': 'Kein Konto gefunden. Bitte registrieren Sie sich zuerst.',
    'pt': 'Conta não encontrada. Cadastre-se primeiro.',
    'ru': 'Аккаунт не найден. Сначала зарегистрируйтесь.',
  },
  'login_failed': {
    'ko': '닉네임 또는 비밀번호가 올바르지 않습니다.',
    'en': 'Incorrect username or password.',
    'ja': 'ユーザー名またはパスワードが正しくありません。',
    'zh': '用户名或密码不正确。',
    'es': 'Nombre de usuario o contraseña incorrectos.',
    'fr': 'Nom d\'utilisateur ou mot de passe incorrect.',
    'de': 'Benutzername oder Passwort falsch.',
    'pt': 'Nome de usuário ou senha incorretos.',
    'ru': 'Неверное имя пользователя или пароль.',
  },
  'email_not_found': {
    'ko': '해당 이메일로 등록된 계정을 찾을 수 없습니다.',
    'en': 'No account found with this email.',
    'ja': 'このメールアドレスに登録されたアカウントが見つかりません。',
    'zh': '未找到与此邮箱关联的账户。',
    'es': 'No se encontró cuenta con este correo.',
    'fr': 'Aucun compte trouvé avec cet e-mail.',
    'de': 'Kein Konto mit dieser E-Mail gefunden.',
    'pt': 'Nenhuma conta encontrada com este e-mail.',
    'ru': 'Аккаунт с этим email не найден.',
  },
  'reset_input_required': {
    'ko': '닉네임과 가입 이메일을 모두 입력해주세요.',
    'en': 'Please enter both username and email.',
    'ja': 'ユーザー名とメールアドレスの両方を入力してください。',
    'zh': '请同时输入用户名和邮箱。',
    'es': 'Ingrese nombre de usuario y correo.',
    'fr': 'Veuillez entrer le nom d\'utilisateur et l\'e-mail.',
    'de': 'Bitte Benutzernamen und E-Mail eingeben.',
    'pt': 'Insira nome de usuário e e-mail.',
    'ru': 'Введите имя пользователя и email.',
  },
  'reset_mismatch': {
    'ko': '닉네임 또는 이메일이 일치하지 않습니다.',
    'en': 'Username or email does not match.',
    'ja': 'ユーザー名またはメールアドレスが一致しません。',
    'zh': '用户名或邮箱不匹配。',
    'es': 'El nombre de usuario o correo no coincide.',
    'fr': 'Le nom d\'utilisateur ou l\'e-mail ne correspond pas.',
    'de': 'Benutzername oder E-Mail stimmt nicht überein.',
    'pt': 'Nome de usuário ou e-mail não corresponde.',
    'ru': 'Имя пользователя или email не совпадает.',
  },
};

class AuthService {
  static const _keyIsLoggedIn = 'isLoggedIn';
  static const _keyUserId = 'userId';
  static const _keyUsername = 'username';
  static const _keyEmail = 'email';
  static const _keyCountry = 'country';
  static const _keyCountryFlag = 'countryFlag';
  static const _keyLanguageCode = 'languageCode';
  static const _keySocialLink = 'socialLink';
  static const _keyPassword = 'password';
  static const _keyTempPasswordHash = 'tempPasswordHash';
  static const _keyTempPasswordExpiresAt = 'tempPasswordExpiresAt';
  static const _keyMustChangePassword = 'mustChangePassword';
  static const _keyPhoneNumber = 'phoneNumber';
  static const _keyVerifyMethod = 'verifyMethod'; // 'email' or 'phone'
  static const _keySecureMigrated = 'auth_secure_migrated_v1';
  static const _tempPasswordTtl = Duration(minutes: 15);

  // ── Localized error messages ───────────────────────────────────────────────
  static const _messages = <String, Map<String, String>>{
    'otp_not_found': {
      'ko': '인증 코드가 없습니다. 다시 요청해주세요.',
      'en': 'No verification code found. Please request again.',
      'ja': '認証コードがありません。再度リクエストしてください。',
      'zh': '没有验证码。请重新请求。',
    },
    'otp_email_mismatch': {
      'ko': '이메일이 일치하지 않습니다.',
      'en': 'Email does not match.',
      'ja': 'メールアドレスが一致しません。',
      'zh': '电子邮件不匹配。',
    },
    'otp_expired': {
      'ko': '인증 코드가 만료되었습니다. 다시 요청해주세요.',
      'en': 'Verification code has expired. Please request again.',
      'ja': '認証コードの有効期限が切れました。再度リクエストしてください。',
      'zh': '验证码已过期。请重新请求。',
    },
    'otp_invalid': {
      'ko': '인증 코드가 올바르지 않습니다.',
      'en': 'Verification code is incorrect.',
      'ja': '認証コードが正しくありません。',
      'zh': '验证码不正确。',
    },
    'username_min_length': {
      'ko': '2자 이상 입력해주세요',
      'en': 'Must be at least 2 characters',
      'ja': '2文字以上入力してください',
      'zh': '请输入至少2个字符',
    },
    'username_max_length': {
      'ko': '20자 이하로 입력해주세요',
      'en': 'Must be 20 characters or fewer',
      'ja': '20文字以下で入力してください',
      'zh': '请输入20个字符以内',
    },
    'username_format': {
      'ko': '영문으로 시작, 영문·숫자·_ 만 사용 가능',
      'en': 'Must start with a letter; only letters, digits, and _ allowed',
      'ja': '英字で始まり、英数字と_のみ使用可能',
      'zh': '必须以字母开头，只能使用字母、数字和_',
    },
    'password_format': {
      'ko': '영문+숫자를 포함한 8~20자를 입력해주세요',
      'en': 'Must be 8–20 characters with at least one letter and one digit',
      'ja': '英文と数字を含む8〜20文字を入力してください',
      'zh': '请输入包含字母和数字的8-20个字符',
    },
    'email_required': {
      'ko': '이메일을 입력해주세요.',
      'en': 'Please enter your email.',
      'ja': 'メールアドレスを入力してください。',
      'zh': '请输入电子邮件。',
    },
    'email_invalid': {
      'ko': '올바른 이메일 형식이 아닙니다.',
      'en': 'Invalid email format.',
      'ja': '正しいメール形式ではありません。',
      'zh': '电子邮件格式无效。',
    },
    'username_taken': {
      'ko': '이미 사용 중인 아이디입니다. 다른 아이디를 입력해주세요.',
      'en': 'This username is already taken. Please choose another.',
      'ja': 'このユーザー名は既に使用されています。別のものを入力してください。',
      'zh': '该用户名已被使用。请选择其他用户名。',
    },
    'email_taken': {
      'ko': '이미 가입된 이메일입니다. 다른 이메일을 사용하거나 로그인해주세요.',
      'en': 'This email is already registered. Please use another or log in.',
      'ja': 'このメールアドレスは既に登録されています。別のものを使用するかログインしてください。',
      'zh': '该电子邮件已注册。请使用其他邮箱或登录。',
    },
    'nickname_required': {
      'ko': '닉네임을 입력해주세요.',
      'en': 'Please enter your nickname.',
      'ja': 'ニックネームを入力してください。',
      'zh': '请输入昵称。',
    },
    'password_required': {
      'ko': '비밀번호를 입력해주세요.',
      'en': 'Please enter your password.',
      'ja': 'パスワードを入力してください。',
      'zh': '请输入密码。',
    },
    'no_account': {
      'ko': '등록된 계정이 없습니다. 회원가입을 먼저 해주세요.',
      'en': 'No account found. Please sign up first.',
      'ja': 'アカウントが見つかりません。先に会員登録してください。',
      'zh': '未找到账户。请先注册。',
    },
    'login_failed': {
      'ko': '닉네임 또는 비밀번호가 올바르지 않습니다.',
      'en': 'Incorrect nickname or password.',
      'ja': 'ニックネームまたはパスワードが正しくありません。',
      'zh': '昵称或密码不正确。',
    },
    'email_not_found': {
      'ko': '해당 이메일로 등록된 계정을 찾을 수 없습니다.',
      'en': 'No account found with this email.',
      'ja': 'このメールアドレスで登録されたアカウントが見つかりません。',
      'zh': '未找到使用该电子邮件注册的账户。',
    },
    'reset_fields_required': {
      'ko': '닉네임과 가입 이메일을 모두 입력해주세요.',
      'en': 'Please enter both your nickname and registered email.',
      'ja': 'ニックネームと登録メールアドレスの両方を入力してください。',
      'zh': '请输入昵称和注册邮箱。',
    },
    'reset_mismatch': {
      'ko': '닉네임 또는 이메일이 일치하지 않습니다.',
      'en': 'Nickname or email does not match.',
      'ja': 'ニックネームまたはメールアドレスが一致しません。',
      'zh': '昵称或电子邮件不匹配。',
    },
  };

  /// Look up a localized message by key. Falls back to Korean.
  static String _t(String key, String langCode) {
    final entry = _messages[key];
    if (entry == null) return key;
    return entry[langCode] ?? entry['ko']!;
  }

  // ── 보안 저장소 ─────────────────────────────────────────────────────────────
  // 비밀번호는 SHA-256 해시 형태로만 저장 (평문 저장 없음).
  // iOS: Keychain (first_unlock_this_device) / Android: EncryptedSharedPreferences
  // 향후 Firebase Authentication 연동 시 _keyPassword 항목은 제거하고
  // FirebaseAuthService.signIn() 으로 완전 위임하세요.
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const List<String> _authKeys = [
    _keyIsLoggedIn,
    _keyUserId,
    _keyUsername,
    _keyEmail,
    _keyCountry,
    _keyCountryFlag,
    _keyLanguageCode,
    _keySocialLink,
    _keyPassword,
  ];

  // ── 이메일 인증 OTP ──────────────────────────────────────────────────────────
  // 평문 대신 SHA-256 해시로 보관 → 메모리 덤프 시 원본 코드 노출 방지
  static String? _pendingOtpHash; // SHA-256(OTP)
  static String? _pendingOtpEmail;
  static DateTime? _otpExpiresAt;
  static const _otpTtl = Duration(minutes: 10);
  // Build 286 (보안): OTP 검증 실패 brute-force 차단.
  // 6자리 OTP = 10^6 = 100만 조합. TTL 10분 동안 무제한 검증 가능했음.
  // 실패 5회 이후 OTP 즉시 무효화 → 사용자 재발급 필요. 공격자는 새 OTP 발급
  // rate limit (60s 쿨다운 + 10분당 5회) 에 묶임.
  static int _otpVerifyFailures = 0;
  static const _maxOtpVerifyAttempts = 5;

  // ── OTP Rate Limiting ────────────────────────────────────────────────────────
  // 10분 윈도우 내 최대 5회 요청 + 요청 간 60초 쿨다운
  // Build 288 (P2.3): email/phone 별도 윈도우. 이전엔 공유 카운터 → 공격자가
  // email OTP 5회 발급해 quota 소진 시 정상 사용자의 SMS OTP 도 차단됐음.
  static int _emailOtpRequestCount = 0;
  static DateTime? _emailOtpWindowStart;
  static DateTime? _lastEmailOtpSentAt;
  static int _phoneOtpRequestCount = 0;
  static DateTime? _phoneOtpWindowStart;
  static DateTime? _lastPhoneOtpSentAt;
  static const _maxOtpRequestsPerWindow = 5;
  static const _otpWindowDuration = Duration(minutes: 10);
  static const _otpCooldownDuration = Duration(seconds: 60);

  /// 다음 email OTP 요청까지 남은 초 (Build 288: email/phone 분리).
  /// 기존 호출자 (auth_screen) 가 email 채널 기준으로 보면 됨.
  static int get otpCooldownSecondsRemaining {
    if (_lastEmailOtpSentAt == null) return 0;
    final elapsed = DateTime.now().difference(_lastEmailOtpSentAt!);
    if (elapsed >= _otpCooldownDuration) return 0;
    return (_otpCooldownDuration - elapsed).inSeconds;
  }

  /// 다음 phone OTP 요청까지 남은 초 (Build 288 신규).
  static int get phoneOtpCooldownSecondsRemaining {
    if (_lastPhoneOtpSentAt == null) return 0;
    final elapsed = DateTime.now().difference(_lastPhoneOtpSentAt!);
    if (elapsed >= _otpCooldownDuration) return 0;
    return (_otpCooldownDuration - elapsed).inSeconds;
  }

  /// 현재 윈도우 내 남은 email OTP 요청 횟수 (Build 288: email/phone 분리).
  static int get otpRequestsRemaining {
    final now = DateTime.now();
    if (_emailOtpWindowStart == null ||
        now.difference(_emailOtpWindowStart!) >= _otpWindowDuration) {
      return _maxOtpRequestsPerWindow;
    }
    return (_maxOtpRequestsPerWindow - _emailOtpRequestCount).clamp(
      0,
      _maxOtpRequestsPerWindow,
    );
  }

  /// 현재 윈도우 내 남은 phone OTP 요청 횟수 (Build 288 신규).
  static int get phoneOtpRequestsRemaining {
    final now = DateTime.now();
    if (_phoneOtpWindowStart == null ||
        now.difference(_phoneOtpWindowStart!) >= _otpWindowDuration) {
      return _maxOtpRequestsPerWindow;
    }
    return (_maxOtpRequestsPerWindow - _phoneOtpRequestCount).clamp(
      0,
      _maxOtpRequestsPerWindow,
    );
  }

  static String _hashOtp(String otp) =>
      sha256.convert(utf8.encode(otp)).toString();

  /// 6자리 OTP 생성 및 반환.
  /// Rate limit 초과 시 null 반환 (UI에서 에러 메시지 표시).
  /// 실제 서비스에서는 이 코드를 이메일 발송 API와 연동.
  static String? generateEmailOtp(String email) {
    final now = DateTime.now();

    // 윈도우 리셋 (10분 경과) — Build 288: email 전용 윈도우
    if (_emailOtpWindowStart == null ||
        now.difference(_emailOtpWindowStart!) >= _otpWindowDuration) {
      _emailOtpWindowStart = now;
      _emailOtpRequestCount = 0;
    }

    // 쿨다운 체크 (마지막 요청으로부터 60초)
    if (_lastEmailOtpSentAt != null &&
        now.difference(_lastEmailOtpSentAt!) < _otpCooldownDuration) {
      return null; // 쿨다운 중
    }

    // 윈도우 내 최대 요청 횟수 초과
    if (_emailOtpRequestCount >= _maxOtpRequestsPerWindow) {
      return null; // Rate limit 초과
    }

    _emailOtpRequestCount++;
    _lastEmailOtpSentAt = now;

    final rng = Random.secure();
    final code = List.generate(6, (_) => rng.nextInt(10)).join();
    _pendingOtpHash = _hashOtp(code); // 평문 대신 해시만 보관
    _pendingOtpEmail = email.trim().toLowerCase();
    _otpExpiresAt = now.add(_otpTtl);
    _otpVerifyFailures = 0; // 새 OTP 발급 시 실패 카운터 리셋
    // 이메일 발송 연동 필요: Firebase Extensions "Trigger Email" 또는
    // SendGrid / Mailgun 등의 SMTP API를 사용하여 _pendingOtp 코드를 발송하세요.
    // 예) await EmailService.sendOtp(email: email, code: code);
    assert(() {
      // DEBUG 빌드 전용 로그 — 이메일은 앞 3자만, 코드는 표시 안 함
      final atIdx = email.indexOf('@');
      final prefix = atIdx > 0 ? email.substring(0, atIdx.clamp(0, 3)) : '***';
      final domain = atIdx > 0 ? email.substring(atIdx) : '';
      debugPrint(
        '[AuthService] 인증 코드 발송: $prefix***$domain (10분 유효, 이번 윈도우 $_emailOtpRequestCount/$_maxOtpRequestsPerWindow)',
      );
      return true;
    }());
    // Build 207: 릴리스 빌드에서는 OTP 코드를 클라이언트로 반환하지 않는다.
    // 이전엔 SendGrid 미설정·발송 실패 시 화면에 OTP 가 표시돼 인증 우회 가능.
    // DEBUG 빌드만 코드 반환 (개발자 화면 확인용).
    return kReleaseMode ? '' : code;
  }

  /// OTP 검증. null = 성공, 문자열 = 오류 메시지
  static String? verifyEmailOtp(String email, String otp, {String langCode = 'en'}) {
    if (_pendingOtpHash == null || _pendingOtpEmail == null) {
      return _authMsg('otp_not_found', langCode);
    }
    if (_pendingOtpEmail != email.trim().toLowerCase()) {
      return _authMsg('otp_email_mismatch', langCode);
    }
    if (_otpExpiresAt == null || DateTime.now().isAfter(_otpExpiresAt!)) {
      _pendingOtpHash = null;
      _pendingOtpEmail = null;
      _otpExpiresAt = null;
      return _authMsg('otp_expired', langCode);
    }
    // 입력값을 해시화하여 저장된 해시와 비교 (타이밍 공격 방지)
    if (_pendingOtpHash != _hashOtp(otp.trim())) {
      _otpVerifyFailures++;
      // Build 286: 5회 실패 후 OTP 즉시 무효화 → brute force 방어.
      // 공격자는 새 OTP 발급 받아야 함 (60s 쿨다운 + 5회/10분 rate limit 묶임).
      if (_otpVerifyFailures >= _maxOtpVerifyAttempts) {
        _pendingOtpHash = null;
        _pendingOtpEmail = null;
        _otpExpiresAt = null;
        _otpVerifyFailures = 0;
        return _authMsg('otp_too_many_attempts', langCode);
      }
      return _authMsg('otp_invalid', langCode);
    }
    // 인증 성공 → OTP 무효화 + 실패 카운터 리셋
    _pendingOtpHash = null;
    _pendingOtpEmail = null;
    _otpExpiresAt = null;
    _otpVerifyFailures = 0;
    return null;
  }

  /// OTP 만료까지 남은 초
  static int get otpRemainingSeconds {
    if (_otpExpiresAt == null) return 0;
    final remaining = _otpExpiresAt!.difference(DateTime.now()).inSeconds;
    return remaining.clamp(0, 600);
  }

  // ── 비밀번호 해싱 ────────────────────────────────────────────────────────────
  // v1: 단순 SHA-256 (레거시 — 기존 사용자 로그인 호환용으로 유지)
  // v2: HMAC-SHA256 × 10 000 라운드 + 16바이트 랜덤 salt
  //     저장 형식: "$pbkdf$<hex-salt>$<hex-hash>"

  // Build 207: OWASP 2023 권장값 600,000 으로 상향 (이전 10,000).
  // 기존 사용자 hash 는 verify 시 자연스럽게 재계산 → 차후 로그인 시 자동
  // 마이그레이션. 신규 가입자는 처음부터 강한 hash.
  static const int _pbkdf2Rounds = 600000;
  static const String _pbkdf2Prefix = r'$pbkdf$';

  /// [레거시] 단순 SHA-256 해시 — 기존 저장값 검증 전용, 신규 저장에는 사용하지 않음.
  static String _hashPasswordLegacy(String raw) {
    const salt = 'globaldrift_v1_';
    final bytes = utf8.encode(salt + raw);
    return sha256.convert(bytes).toString();
  }

  // ── SMS OTP ───────────────────────────────────────────────────────────────
  static String? _pendingPhoneOtpHash;
  static String? _pendingOtpPhone;

  /// SMS로 6자리 OTP 생성 및 발송.
  /// Build 288: email OTP 와 별도 rate limit (이전엔 공유라 attacker 가
  /// email quota 소진 시 사용자 SMS 차단되는 회귀 있었음).
  /// [phoneNumber]는 E.164 형식 (예: +821012345678).
  /// 성공 시 코드 반환 (개발용), 실패 시 null.
  static Future<String?> generatePhoneOtp(
    String phoneNumber, {
    String langCode = 'en',
  }) async {
    final now = DateTime.now();

    // 윈도우 리셋 (10분 경과) — Build 288: phone 전용 윈도우
    if (_phoneOtpWindowStart == null ||
        now.difference(_phoneOtpWindowStart!) >= _otpWindowDuration) {
      _phoneOtpWindowStart = now;
      _phoneOtpRequestCount = 0;
    }

    // 쿨다운 체크 (마지막 요청으로부터 60초)
    if (_lastPhoneOtpSentAt != null &&
        now.difference(_lastPhoneOtpSentAt!) < _otpCooldownDuration) {
      return null; // 쿨다운 중
    }

    // 윈도우 내 최대 요청 횟수 초과
    if (_phoneOtpRequestCount >= _maxOtpRequestsPerWindow) {
      return null; // Rate limit 초과
    }

    _phoneOtpRequestCount++;
    _lastPhoneOtpSentAt = now;

    final rng = Random.secure();
    final code = List.generate(6, (_) => rng.nextInt(10)).join();
    _pendingPhoneOtpHash = _hashOtp(code);
    _pendingOtpPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    _otpExpiresAt = now.add(_otpTtl);

    // Twilio를 통한 실제 SMS 발송
    final smsError = await SmsService.sendOtp(
      phoneNumber: _pendingOtpPhone!,
      code: code,
      langCode: langCode,
    );

    if (smsError != null) {
      assert(() {
        debugPrint('[AuthService] SMS 발송 실패: $smsError');
        return true;
      }());
      // Build 207: 릴리스 빌드에서 SMS 발송 실패 시 null 반환 — 코드를 절대
      // 클라이언트로 노출하지 않는다. DEBUG 빌드만 화면 표시용 코드 반환.
      if (kReleaseMode) return null;
    }

    assert(() {
      final masked = phoneNumber.length > 4
          ? '${'*' * (phoneNumber.length - 4)}${phoneNumber.substring(phoneNumber.length - 4)}'
          : '****';
      debugPrint(
        '[AuthService] SMS 인증 코드 발송: $masked (10분 유효, 이번 윈도우 $_phoneOtpRequestCount/$_maxOtpRequestsPerWindow)',
      );
      return true;
    }());
    return kReleaseMode ? '' : code;
  }

  /// SMS OTP 검증. null = 성공, 문자열 = 오류 메시지.
  static String? verifyPhoneOtp(String phoneNumber, String otp, {String langCode = 'en'}) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (_pendingPhoneOtpHash == null || _pendingOtpPhone == null) {
      return _authMsg('otp_not_found', langCode);
    }
    if (_pendingOtpPhone != cleaned) {
      return _authMsg('otp_phone_mismatch', langCode);
    }
    if (_otpExpiresAt == null || DateTime.now().isAfter(_otpExpiresAt!)) {
      _pendingPhoneOtpHash = null;
      _pendingOtpPhone = null;
      _otpExpiresAt = null;
      return _authMsg('otp_expired', langCode);
    }
    if (_pendingPhoneOtpHash != _hashOtp(otp.trim())) {
      return _authMsg('otp_invalid', langCode);
    }
    // 인증 성공 → OTP 무효화
    _pendingPhoneOtpHash = null;
    _pendingOtpPhone = null;
    _otpExpiresAt = null;
    return null;
  }

  /// 16바이트 암호학적 랜덤 salt 생성 (hex 문자열 반환).
  static String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// HMAC-SHA256 을 [_pbkdf2Rounds] 회 반복하여 키를 도출.
  /// PBKDF2-HMAC-SHA256 과 동일한 원리이며, 외부 패키지 없이 `crypto`만 사용.
  static List<int> _deriveKey(String password, List<int> salt) {
    final hmac = Hmac(sha256, utf8.encode(password));
    // U1 = HMAC(password, salt || INT(1))
    var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    var result = List<int>.from(block);
    for (var i = 1; i < _pbkdf2Rounds; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= block[j];
      }
    }
    return result;
  }

  /// 강화된 해싱: 랜덤 salt + 10 000회 HMAC-SHA256.
  /// 반환값: `$pbkdf$[hex-salt]$[hex-hash]`
  static String _hashPassword(String raw) {
    final saltHex = _generateSalt();
    final saltBytes =
        List<int>.generate(saltHex.length ~/ 2, (i) {
          return int.parse(saltHex.substring(i * 2, i * 2 + 2), radix: 16);
        });
    final derived = _deriveKey(raw, saltBytes);
    final hashHex = derived.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '$_pbkdf2Prefix$saltHex\$$hashHex';
  }

  /// 주어진 salt 로 해시를 재계산하여 저장값과 비교.
  static bool _verifyPasswordStrengthened(String raw, String stored) {
    if (!stored.startsWith(_pbkdf2Prefix)) return false;
    // 형식: $pbkdf$<saltHex>$<hashHex>
    final parts = stored.substring(_pbkdf2Prefix.length).split(r'$');
    if (parts.length != 2) return false;
    final saltHex = parts[0];
    final expectedHashHex = parts[1];
    final saltBytes =
        List<int>.generate(saltHex.length ~/ 2, (i) {
          return int.parse(saltHex.substring(i * 2, i * 2 + 2), radix: 16);
        });
    final derived = _deriveKey(raw, saltBytes);
    final hashHex = derived.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    // 상수 시간 비교 (타이밍 공격 방지)
    if (hashHex.length != expectedHashHex.length) return false;
    var diff = 0;
    for (var i = 0; i < hashHex.length; i++) {
      diff |= hashHex.codeUnitAt(i) ^ expectedHashHex.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// 비밀번호 검증: v2(강화) → v1(레거시) → 평문 순으로 시도.
  /// 레거시 또는 평문 일치 시 자동으로 v2 해시로 재저장(마이그레이션).
  static Future<bool> _verifyAndMigratePassword(
    String raw,
    String? stored,
  ) async {
    if (stored == null) return false;

    // (1) v2 강화 해시
    if (stored.startsWith(_pbkdf2Prefix)) {
      return _verifyPasswordStrengthened(raw, stored);
    }

    // (2) v1 레거시 SHA-256
    if (_isHashedLegacy(stored)) {
      if (stored == _hashPasswordLegacy(raw)) {
        // 마이그레이션: 강화 해시로 재저장
        await _writeSecure(_keyPassword, _hashPassword(raw));
        return true;
      }
      return false;
    }

    // (3) 평문 (아주 오래된 데이터)
    if (stored == raw) {
      await _writeSecure(_keyPassword, _hashPassword(raw));
      return true;
    }
    return false;
  }

  /// 저장된 값이 레거시 SHA-256 해시인지 확인 (64자 hex)
  static bool _isHashedLegacy(String value) =>
      value.length == 64 && RegExp(r'^[0-9a-f]+$').hasMatch(value);

  /// 저장된 값이 이미 해시인지 확인 (v2 또는 레거시)
  static bool _isHashed(String value) =>
      value.startsWith(_pbkdf2Prefix) || _isHashedLegacy(value);

  static String _generateTempPassword({int length = 12}) {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%';
    final rnd = Random.secure();
    final out = StringBuffer();
    for (var i = 0; i < length; i++) {
      out.write(chars[rnd.nextInt(chars.length)]);
    }
    return out.toString();
  }

  static Future<void> _writeSecure(String key, String value) async {
    await _secure.write(key: key, value: value);
  }

  static Future<void> _deleteSecure(String key) async {
    await _secure.delete(key: key);
  }

  static Future<String?> _readSecure(String key) async {
    return _secure.read(key: key);
  }

  static Future<void> _migrateLegacyAuthDataIfNeeded(
    SharedPreferences prefs,
  ) async {
    final migrated = prefs.getBool(_keySecureMigrated) ?? false;
    if (migrated) return;

    for (final key in _authKeys) {
      final legacy = key == _keyIsLoggedIn
          ? (prefs.getBool(key)?.toString())
          : prefs.getString(key);
      if (legacy == null) continue;

      final secureExisting = await _readSecure(key);
      if (secureExisting == null) {
        await _writeSecure(key, legacy);
      }
      await prefs.remove(key);
    }

    await prefs.setBool(_keySecureMigrated, true);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyAuthDataIfNeeded(prefs);
    return (await _readSecure(_keyIsLoggedIn)) == 'true';
  }

  static Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyAuthDataIfNeeded(prefs);

    if ((await _readSecure(_keyIsLoggedIn)) != 'true') return null;
    final country = (await _readSecure(_keyCountry)) ?? '대한민국';
    final languageCodeRaw = (await _readSecure(_keyLanguageCode)) ?? '';
    final languageCode = languageCodeRaw.isNotEmpty
        ? languageCodeRaw
        : LanguageConfig.getLanguageCode(country);
    if (languageCodeRaw.isEmpty) {
      await _writeSecure(_keyLanguageCode, languageCode);
    }
    return {
      'id': (await _readSecure(_keyUserId)) ?? '',
      'username': (await _readSecure(_keyUsername)) ?? '',
      'email': (await _readSecure(_keyEmail)) ?? '',
      'country': country,
      'countryFlag': (await _readSecure(_keyCountryFlag)) ?? '🇰🇷',
      'languageCode': languageCode,
      'socialLink': (await _readSecure(_keySocialLink)) ?? '',
      'phoneNumber': (await _readSecure(_keyPhoneNumber)) ?? '',
      'verifyMethod': (await _readSecure(_keyVerifyMethod)) ?? 'email',
    };
  }

  // ── 유효성 정규식 ──────────────────────────────────────────────────────────
  /// 아이디: 영문으로 시작, 영문+숫자+_로 2~20자
  static final _usernameRe = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{1,19}$');

  /// 비밀번호: 영문+숫자 포함 8~20자 (특수문자 허용)
  static final _passwordRe = RegExp(r'^(?=.*[a-zA-Z])(?=.*[0-9]).{8,20}$');
  static final _emailRe = RegExp(
    r'^[\w.+\-]+@[a-zA-Z\d\-]+(\.[a-zA-Z\d\-]+)*\.[a-zA-Z]{2,}$',
  );

  /// 아이디 유효성 검사 (UI 실시간 체크용)
  static String? validateUsername(String value, {String langCode = 'en'}) {
    final v = value.trim();
    if (v.isEmpty) return null;
    if (v.length < 2) return _authMsg('username_min', langCode);
    if (v.length > 20) return _authMsg('username_max', langCode);
    if (!_usernameRe.hasMatch(v)) return _authMsg('username_format', langCode);
    return null; // valid
  }

  /// 비밀번호 유효성 검사 (UI 실시간 체크용)
  static String? validatePassword(String value, {String langCode = 'en'}) {
    if (value.isEmpty) return null;
    if (!_passwordRe.hasMatch(value)) {
      return _authMsg('password_format', langCode);
    }
    return null; // valid
  }

  /// 이메일 유효성 검사
  static String? validateEmail(String email, {String langCode = 'en'}) {
    if (email.isEmpty) return _authMsg('email_required', langCode);
    if (!_emailRe.hasMatch(email)) return _authMsg('email_invalid', langCode);
    return null;
  }

  /// 이메일 중복 여부 확인 (기기 내 저장된 계정 한정)
  static Future<bool> isEmailTaken(String email) async {
    final saved = await _readSecure(_keyEmail);
    return saved != null && saved.toLowerCase() == email.trim().toLowerCase();
  }

  /// 아이디 중복 여부 확인 (기기 내 저장된 계정 한정)
  static Future<bool> isUsernameTaken(String username) async {
    final saved = await _readSecure(_keyUsername);
    return saved != null &&
        saved.toLowerCase() == username.trim().toLowerCase();
  }

  /// 회원가입 - nickname + password
  static Future<String?> signUp({
    required String username,
    required String password,
    required String country,
    required String countryFlag,
    String? languageCode,
    String? email,
    String? socialLink,
    String? phoneNumber,
    String verifyMethod = 'email',
    String langCode = 'en',
  }) async {
    // ── 형식 검사 ──
    final normalizedEmail = email?.trim() ?? '';
    final usernameErr = validateUsername(username, langCode: langCode);
    if (usernameErr != null) return usernameErr;
    // 영구 어드민 계정 (BetaConstants.permanentAdminEmail) 은 비번 형식 검증
    // 우회 — 초기 비번 0000 등 짧은 값 허용. 일반 사용자는 8~20자 영문+숫자.
    if (!BetaConstants.isAdmin(normalizedEmail)) {
      final passwordErr = validatePassword(password, langCode: langCode);
      if (passwordErr != null) return passwordErr;
    }
    if (normalizedEmail.isEmpty) return _authMsg('email_required', langCode);
    if (!_emailRe.hasMatch(normalizedEmail)) return _authMsg('email_invalid', langCode);

    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyAuthDataIfNeeded(prefs);

    // ── 중복 체크 ──
    final existingUsername = await _readSecure(_keyUsername);
    if (existingUsername != null &&
        existingUsername.toLowerCase() == username.trim().toLowerCase()) {
      return _authMsg('username_taken', langCode);
    }
    final existingEmail = await _readSecure(_keyEmail);
    if (existingEmail != null &&
        existingEmail.toLowerCase() == normalizedEmail.toLowerCase()) {
      return _authMsg('email_taken', langCode);
    }

    final userId = 'user_${const Uuid().v4()}';
    await _writeSecure(_keyIsLoggedIn, 'true');
    await _writeSecure(_keyUserId, userId);
    await _writeSecure(_keyUsername, username.trim());
    await _writeSecure(_keyEmail, normalizedEmail);
    await _writeSecure(_keyPassword, _hashPassword(password)); // SHA-256 저장
    await _writeSecure(_keyCountry, country);
    await _writeSecure(_keyCountryFlag, countryFlag);
    if (languageCode != null && languageCode.isNotEmpty) {
      await _writeSecure(_keyLanguageCode, languageCode);
    } else {
      await _deleteSecure(_keyLanguageCode);
    }
    if (socialLink != null && socialLink.isNotEmpty) {
      await _writeSecure(_keySocialLink, socialLink.trim());
    } else {
      await _deleteSecure(_keySocialLink);
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      await _writeSecure(_keyPhoneNumber, phoneNumber.trim());
    } else {
      await _deleteSecure(_keyPhoneNumber);
    }
    await _writeSecure(_keyVerifyMethod, verifyMethod);
    return null; // null = 성공
  }

  /// 로그인 - nickname + password
  static Future<String?> login({
    required String username,
    required String password,
    String langCode = 'en',
  }) async {
    if (username.trim().isEmpty) return _authMsg('nickname_required', langCode);
    if (password.isEmpty) return _authMsg('password_required', langCode);

    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyAuthDataIfNeeded(prefs);

    final savedUsername = await _readSecure(_keyUsername);
    final savedPassword = await _readSecure(_keyPassword);

    if (savedUsername == null) return _authMsg('no_account', langCode);
    if (savedUsername != username.trim()) return _authMsg('login_failed', langCode);

    // 비밀번호 검증 (v2 강화 해시 → v1 레거시 → 평문 순, 자동 마이그레이션 포함)
    final primaryPasswordMatched =
        await _verifyAndMigratePassword(password, savedPassword);

    if (!primaryPasswordMatched) {
      final tempHash = await _readSecure(_keyTempPasswordHash);
      final tempExpiresAtRaw = await _readSecure(_keyTempPasswordExpiresAt);
      final tempExpiresAt = int.tryParse(tempExpiresAtRaw ?? '');
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 임시 비밀번호 검증 (마이그레이션 없이 비교만 수행)
      final tempMatched = tempHash != null &&
          (tempHash.startsWith(_pbkdf2Prefix)
              ? _verifyPasswordStrengthened(password, tempHash)
              : tempHash == _hashPasswordLegacy(password));

      if (tempHash != null &&
          tempExpiresAt != null &&
          nowMs <= tempExpiresAt &&
          tempMatched) {
        await _writeSecure(_keyMustChangePassword, 'true');
        await _writeSecure(_keyIsLoggedIn, 'true');
        return null;
      }

      // 만료된 임시 비밀번호는 즉시 폐기
      if (tempHash != null && tempExpiresAt != null && nowMs > tempExpiresAt) {
        await _deleteSecure(_keyTempPasswordHash);
        await _deleteSecure(_keyTempPasswordExpiresAt);
      }

      return _authMsg('login_failed', langCode);
    }

    await _deleteSecure(_keyTempPasswordHash);
    await _deleteSecure(_keyTempPasswordExpiresAt);
    await _writeSecure(_keyMustChangePassword, 'false');
    await _writeSecure(_keyIsLoggedIn, 'true');
    return null; // null = 성공
  }

  /// 영구 어드민 계정 자동 부트스트랩.
  ///
  /// 앱 첫 실행 (또는 데이터 초기화 후) 시 호출. 이미 어떤 계정이라도 있으면
  /// no-op. 없으면 `BetaConstants.permanentAdminEmail` 로 자동 가입:
  ///   - username: `ceo`
  ///   - email   : `ceo@airony.xyz`
  ///   - password: `0000`
  ///   - country : 대한민국 / 🇰🇷
  /// signUp 의 password 형식 검증은 어드민 이메일에 한해 우회되므로 0000 가능.
  static Future<void> bootstrapAdminIfNeeded({String langCode = 'ko'}) async {
    final adminEmail = BetaConstants.permanentAdminEmail;
    if (adminEmail.isEmpty) return;

    final existing = await _readSecure(_keyUsername);
    if (existing != null && existing.isNotEmpty) return; // 이미 계정 있음

    // 영구 어드민 자동 가입
    await signUp(
      username: 'ceo',
      password: '0000',
      country: '대한민국',
      countryFlag: '🇰🇷',
      languageCode: langCode,
      email: adminEmail,
      verifyMethod: 'email',
      langCode: langCode,
    );
  }

  /// 로그아웃
  static Future<void> logout() async {
    await _writeSecure(_keyIsLoggedIn, 'false');
    FirebaseAuthService.signOut();
    await PurchaseService().syncUserIdentity();
  }

  /// 프로필 업데이트
  static Future<void> updateProfile({
    String? username,
    String? country,
    String? countryFlag,
    String? languageCode,
    String? socialLink,
    String? phoneNumber,
    String? verifyMethod,
  }) async {
    if (username != null && username.isNotEmpty) {
      await _writeSecure(_keyUsername, username.trim());
    }
    if (country != null) await _writeSecure(_keyCountry, country);
    if (countryFlag != null) await _writeSecure(_keyCountryFlag, countryFlag);
    if (languageCode != null && languageCode.isNotEmpty) {
      await _writeSecure(_keyLanguageCode, languageCode);
    }
    if (socialLink != null) {
      await _writeSecure(_keySocialLink, socialLink.trim());
    }
    if (phoneNumber != null) {
      await _writeSecure(_keyPhoneNumber, phoneNumber.trim());
    }
    if (verifyMethod != null) {
      await _writeSecure(_keyVerifyMethod, verifyMethod);
    }
  }

  // Find username by email
  static Future<Map<String, dynamic>> findId({required String email, String langCode = 'en'}) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyAuthDataIfNeeded(prefs);

    final storedEmail = (await _readSecure(_keyEmail)) ?? '';
    if (storedEmail.toLowerCase() == email.toLowerCase()) {
      final username = (await _readSecure(_keyUsername)) ?? '';
      return {'success': true, 'username': username};
    }
    return {'success': false, 'error': _authMsg('email_not_found', langCode)};
  }

  // Reset password
  static Future<Map<String, dynamic>> resetPassword({
    required String username,
    required String email,
    String langCode = 'en',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyAuthDataIfNeeded(prefs);

    final inputUsername = username.trim();
    final inputEmail = email.trim();
    if (inputUsername.isEmpty || inputEmail.isEmpty) {
      return {'success': false, 'error': _authMsg('reset_input_required', langCode)};
    }

    final storedUsername = (await _readSecure(_keyUsername)) ?? '';
    final storedEmail = (await _readSecure(_keyEmail)) ?? '';
    if (storedUsername == inputUsername &&
        storedEmail.isNotEmpty &&
        storedEmail.toLowerCase() == inputEmail.toLowerCase()) {
      final tempPassword = _generateTempPassword();
      final expiresAt = DateTime.now()
          .add(_tempPasswordTtl)
          .millisecondsSinceEpoch;
      await _writeSecure(_keyTempPasswordHash, _hashPassword(tempPassword));
      await _writeSecure(_keyTempPasswordExpiresAt, expiresAt.toString());
      await _writeSecure(_keyMustChangePassword, 'true');
      return {
        'success': true,
        'tempPassword': tempPassword,
        'expiresInMinutes': _tempPasswordTtl.inMinutes,
      };
    }
    return {'success': false, 'error': _authMsg('reset_mismatch', langCode)};
  }

  // Change password (requires old password verified by caller)
  static Future<void> updatePassword(String newPassword) async {
    await _writeSecure(_keyPassword, _hashPassword(newPassword));
    await _deleteSecure(_keyTempPasswordHash);
    await _deleteSecure(_keyTempPasswordExpiresAt);
    await _writeSecure(_keyMustChangePassword, 'false');
  }

  // Delete account
  static Future<void> deleteAccount() async {
    await _deleteRemoteAccountDataBestEffort();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    FirebaseAuthService.signOut();
    await _secure.deleteAll();
    await PurchaseService().syncUserIdentity();
  }

  // 회원탈퇴 시 원격 사용자 문서 + 보낸 편지 정리 (실패해도 로컬 탈퇴는 진행)
  //
  // FirestoreService.deleteDocument 를 사용하면 Firebase Auth anonymous 토큰이
  // Authorization 헤더에 자동 포함된다. API key 만 있는 요청은 보안 규칙의
  // `isSignedIn()` 체크를 통과하지 못해 401/403 으로 실패하므로 여기서 직접
  // http.delete 를 쓰면 안 된다.
  //
  // Build 207: 사용자 본인이 보낸 letters 도 스크럽. 이전엔 users/{id} 만
  // 삭제 → letter 본문·GPS·사용자명이 영구 잔존 (Apple/Google 데이터 삭제
  // 컴플라이언스 위반). 현재 firestore.rules 가 `delete: if false` 로 letter
  // 삭제를 막고 있어 클라이언트는 직접 못 지운다 — 대신 본문을 빈 문자열로
  // overwrite 하고 senderId/Name 을 익명화하여 PII 를 사실상 제거한다.
  // (실제 letter 문서 row 자체 삭제는 admin REST 로 후속 처리.)
  static Future<void> _deleteRemoteAccountDataBestEffort() async {
    final userId = (await _readSecure(_keyUserId))?.trim() ?? '';
    if (userId.isEmpty) return;
    if (!FirebaseConfig.kFirebaseEnabled) return;

    // Build 288: GDPR Art.17 — 3회 재시도. 실패 시 pending_gdpr_deletions
    // SharedPreferences 큐에 등록 → 다음 앱 실행 시 재시도. 사용자 입장에선
    // 로컬 탈퇴는 즉시 완료, 원격 데이터 정리는 비동기 보장.
    bool userDeleted = false;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        await FirestoreService.deleteDocument('users/$userId');
        userDeleted = true;
        break;
      } catch (e) {
        if (attempt == 2) {
          debugPrint('[AuthService] remote user delete failed after 3 tries: $e');
        }
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    // senderId == userId 인 letter 문서들의 PII 필드를 비움.
    // pickupCount/redeemedCount/status 외 필드는 update rule 화이트리스트
    // 밖이라 거부될 수 있음 — best-effort 시도 후 무시.
    bool scrubbed = false;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        await FirestoreService.scrubLettersBySender(userId);
        scrubbed = true;
        break;
      } catch (e) {
        if (attempt == 2) {
          debugPrint('[AuthService] remote letters scrub failed after 3 tries: $e');
        }
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    // 실패한 작업을 pending 큐에 등록 (다음 앱 실행 시 admin REST 로 후속 처리).
    if (!userDeleted || !scrubbed) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final pending = prefs.getStringList('pending_gdpr_deletions') ?? [];
        pending.add('$userId|${DateTime.now().toIso8601String()}|'
            '${userDeleted ? 'doc_ok' : 'doc_fail'}|'
            '${scrubbed ? 'scrub_ok' : 'scrub_fail'}');
        await prefs.setStringList('pending_gdpr_deletions', pending);
      } catch (_) {}
    }
  }

  // Check onboarding completion (v2 = with country selection)
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_v2_complete') ?? false;
  }

  // Mark onboarding complete
  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_v2_complete', true);
  }

  // Save onboarding country selection
  static Future<void> saveOnboardingCountry({
    required String country,
    required String countryFlag,
    String? languageCode,
  }) async {
    await _writeSecure(_keyCountry, country);
    await _writeSecure(_keyCountryFlag, countryFlag);
    if (languageCode != null && languageCode.isNotEmpty) {
      await _writeSecure(_keyLanguageCode, languageCode);
    }
  }

  static Future<Map<String, String>> getOnboardingCountry() async {
    final country = (await _readSecure(_keyCountry)) ?? '대한민국';
    final languageCodeRaw = (await _readSecure(_keyLanguageCode)) ?? '';
    final languageCode = languageCodeRaw.isNotEmpty
        ? languageCodeRaw
        : LanguageConfig.getLanguageCode(country);
    return {
      'country': country,
      'countryFlag': (await _readSecure(_keyCountryFlag)) ?? '🇰🇷',
      'languageCode': languageCode,
    };
  }
}
