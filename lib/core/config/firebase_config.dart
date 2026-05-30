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

  // ── 인증 메일/SMS relay (Build 412 — PII sim CRITICAL fix) ───────────────
  // 이전엔 Resend/SendGrid/Twilio 서버급 API 키를 dart-define 으로 클라이언트
  // 바이너리에 컴파일 → IPA/APK 를 `strings` 로 긁어 키 추출 → 도메인 사칭
  // 피싱 → 계정 탈취가 가능했음 (CRITICAL). 이제 키는 Cloud Function 서버에만
  // 보관하고, 클라이언트는 '함수 URL'(비밀 아님)만 안다. 함수가 ID 토큰 검증 +
  // 고정 템플릿으로만 발송 → 임의 본문 발송/도메인 사칭 불가.
  //
  // 빌드 시 dart-define 으로 함수 URL 주입 (값이 비밀이 아니므로 안전):
  //   --dart-define=AUTH_EMAIL_FN_URL=https://us-central1-<proj>.cloudfunctions.net/sendAuthEmail
  //   --dart-define=AUTH_SMS_FN_URL=https://us-central1-<proj>.cloudfunctions.net/sendAuthSms
  // 미설정(빈 값) 시 클라이언트는 발송을 스킵하고 on-screen OTP fallback 사용.

  /// 인증 메일 relay Cloud Function URL (비밀 아님).
  static const String authEmailFnUrl = String.fromEnvironment(
    'AUTH_EMAIL_FN_URL',
    defaultValue: '',
  );

  /// 인증 SMS relay Cloud Function URL (비밀 아님).
  static const String authSmsFnUrl = String.fromEnvironment(
    'AUTH_SMS_FN_URL',
    defaultValue: '',
  );

  /// 이메일 발송 relay 가 설정돼 있는지 (함수 URL 존재 여부).
  static bool get isEmailProviderEnabled => authEmailFnUrl.isNotEmpty;

  /// SMS 발송 relay 가 설정돼 있는지.
  static bool get isSmsProviderEnabled => authSmsFnUrl.isNotEmpty;
}
