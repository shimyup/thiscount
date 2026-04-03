/// Firebase 프로젝트 설정
///
/// 사용법:
/// 1. Firebase 콘솔 (https://console.firebase.google.com) 에서 새 프로젝트 생성
/// 2. iOS 앱 등록 (Bundle ID: com.globaldrift.messageInABottle)
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

  // Firestore REST API 기본 URL
  static String get firestoreBase =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  // Firebase Auth REST API 기본 URL
  static String get authBase =>
      'https://identitytoolkit.googleapis.com/v1/accounts';

  // FCM API URL (v1)
  static String get fcmBase =>
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
}
