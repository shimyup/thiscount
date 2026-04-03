import '../config/firebase_config.dart';
import 'firestore_service.dart';

/// 데이터베이스 서비스 (Firebase Firestore REST API 래퍼)
///
/// Firebase 활성화 방법:
/// 1. lib/core/config/firebase_config.dart 에서 kFirebaseEnabled = true 로 변경
/// 2. projectId, apiKey 값 입력
/// 3. iOS: ios/Runner/ 에 GoogleService-Info.plist 추가 (필요 시)
/// 4. AppState의 sendLetter(), loadFromPrefs() 등을 이 서비스로 교체
class DatabaseService {
  static bool get isEnabled => FirebaseConfig.kFirebaseEnabled;

  // ── 유저 프로필 저장 ─────────────────────────────────────────────────────────
  static Future<void> saveUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    if (!isEnabled) return;
    await FirestoreService.setDocument('users/$userId', data);
  }

  // ── 편지 저장 (발송 시) ──────────────────────────────────────────────────────
  static Future<void> saveLetter({
    required String letterId,
    required Map<String, dynamic> letterData,
  }) async {
    if (!isEnabled) return;
    await FirestoreService.setDocument('letters/$letterId', letterData);
  }

  // ── 특정 유저의 받은 편지함 조회 ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getInboxLetters(
    String userId,
  ) async {
    if (!isEnabled) return [];
    // Firestore 쿼리: destinationUserId == userId
    return FirestoreService.queryCollection(
      'letters',
      orderBy: 'sentAt desc',
      limit: 50,
    );
  }

  // ── 세계 지도 위 배송 중 편지 조회 ──────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getWorldLetters() async {
    if (!isEnabled) return [];
    return FirestoreService.queryCollection(
      'letters',
      orderBy: 'sentAt desc',
      limit: 100,
    );
  }

  // ── 랭킹 리더보드 조회 ──────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getLeaderboard({
    int limit = 10,
  }) async {
    if (!isEnabled) return [];
    return FirestoreService.queryCollection(
      'users',
      orderBy: 'activityScore.rankScore desc',
      limit: limit,
    );
  }

  // ── DM 메시지 저장 ─────────────────────────────────────────────────────────
  static Future<void> saveDMMessage({
    required String sessionId,
    required Map<String, dynamic> messageData,
  }) async {
    if (!isEnabled) return;
    await FirestoreService.setDocument(
      'dm_sessions/$sessionId/messages/${messageData['id']}',
      messageData,
    );
  }
}
