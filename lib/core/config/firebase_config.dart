/// Firebase 프로젝트 설정
///
/// 사용법:
/// 1. Firebase 콘솔 (https://console.firebase.google.com) 에서 새 프로젝트 생성
/// 2. iOS 앱 등록 (Bundle ID: io.thiscount)
/// 3. GoogleService-Info.plist 다운로드 → ios/Runner/ 에 추가
/// 4. 빌드 시 아래 dart-define 값 주입
///    --dart-define=FIREBASE_PROJECT_ID=...
///    --dart-define=FIREBASE_API_KEY=...
///    --dart-define=FIREBASE_STORAGE_BUCKET=...
class FirebaseConfig {
  /// Firebase 사용 여부
  /// 빌드 시 아래 값들이 모두 주입되면 true
  static bool get kFirebaseEnabled =>
      projectId.isNotEmpty && apiKey.isNotEmpty && storageBucket.isNotEmpty;

  /// Firebase 프로젝트 ID
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  /// Firebase Web API Key (프로젝트 설정 → 일반 탭에서 확인)
  static const String apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  /// Firebase Storage Bucket
  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: '',
  );

  /// Firebase Storage 활성화 여부.
  /// Firebase 가 2024 부터 Storage 를 Blaze 플랜 전용으로 변경. Spark 무료
  /// 플랜에서는 이 값을 `false` 로 두고 클라이언트에서 업로드 경로 자체를
  /// skip → 로컬 경로만 사용 (graceful degradation).
  /// Blaze 업그레이드 후 빌드에 `--dart-define=FIREBASE_STORAGE_ENABLED=true`
  /// 주입하면 즉시 활성화.
  static const bool storageEnabled = bool.fromEnvironment(
    'FIREBASE_STORAGE_ENABLED',
    defaultValue: false,
  );

  // Firestore REST API 기본 URL
  static String get firestoreBase =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  // Firebase Auth REST API 기본 URL
  static String get authBase =>
      'https://identitytoolkit.googleapis.com/v1/accounts';

  // FCM API URL (v1)
  static String get fcmBase =>
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

  // ── Twilio SMS 설정 ──────────────────────────────────────────────────────
  // 빌드 시 dart-define 으로 주입:
  //   --dart-define=TWILIO_ACCOUNT_SID=ACxxxxxxxxxx
  //   --dart-define=TWILIO_AUTH_TOKEN=xxxxxxxxxx
  //   --dart-define=TWILIO_FROM_NUMBER=+1xxxxxxxxxx

  /// Twilio Account SID
  static const String twilioAccountSid = String.fromEnvironment(
    'TWILIO_ACCOUNT_SID',
    defaultValue: '',
  );

  /// Twilio Auth Token
  static const String twilioAuthToken = String.fromEnvironment(
    'TWILIO_AUTH_TOKEN',
    defaultValue: '',
  );

  /// Twilio 발신 번호 (E.164 형식, 예: +15551234567)
  static const String twilioFromNumber = String.fromEnvironment(
    'TWILIO_FROM_NUMBER',
    defaultValue: '',
  );

  // ── SendGrid 이메일 설정 ─────────────────────────────────────────────────────
  // 빌드 시 dart-define 으로 주입:
  //   --dart-define=SENDGRID_API_KEY=SG.xxxxxxxxxx
  //   --dart-define=SENDGRID_FROM_EMAIL=noreply@yourdomain.com

  /// SendGrid API Key
  static const String sendgridApiKey = String.fromEnvironment(
    'SENDGRID_API_KEY',
    defaultValue: '',
  );

  /// SendGrid 발신 이메일 주소
  static const String sendgridFromEmail = String.fromEnvironment(
    'SENDGRID_FROM_EMAIL',
    defaultValue: '',
  );

  /// SendGrid 설정 여부
  static bool get isSendgridEnabled =>
      sendgridApiKey.isNotEmpty && sendgridFromEmail.isNotEmpty;

  // ── Resend 이메일 설정 ───────────────────────────────────────────────────────
  // SendGrid 대안 — 현재 프로젝트의 기본 이메일 발송 경로.
  // 빌드 시 dart-define 으로 주입:
  //   --dart-define=RESEND_API_KEY=re_xxxxxxxxxxxx
  //   --dart-define=RESEND_FROM_EMAIL=noreply@yourdomain.com

  /// Resend API Key
  static const String resendApiKey = String.fromEnvironment(
    'RESEND_API_KEY',
    defaultValue: '',
  );

  /// Resend 발신 이메일 주소. 도메인이 Resend 에 검증되어 있어야 하며
  /// 그렇지 않으면 `onboarding@resend.dev` 를 사용할 것.
  static const String resendFromEmail = String.fromEnvironment(
    'RESEND_FROM_EMAIL',
    defaultValue: '',
  );

  /// Resend 설정 여부
  static bool get isResendEnabled =>
      resendApiKey.isNotEmpty && resendFromEmail.isNotEmpty;

  /// 활성화된 이메일 발송 프로바이더가 하나라도 있는지
  static bool get isEmailProviderEnabled =>
      isResendEnabled || isSendgridEnabled;
}
