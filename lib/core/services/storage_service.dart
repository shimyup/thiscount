import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

/// Firebase Storage REST API 서비스 (Build 136)
///
/// 프로젝트는 Firebase SDK 대신 raw HTTP 로 Firestore 를 쓰고 있어 Storage 도
/// 같은 REST 패턴 유지. `firebase_storage` Flutter 플러그인을 추가하면
/// `firebase_core` 까지 끌고 와 iOS/Android native 설정이 필요한데,
/// 프로젝트는 dart-define 기반 경량 셋업을 유지하기 위해 REST 선택.
///
/// 업로드 API:
///   POST https://firebasestorage.googleapis.com/v0/b/{bucket}/o
///        ?uploadType=media&name={encodedPath}
///   Content-Type: image/jpeg
///   Authorization: Bearer {idToken}
///   Body: raw bytes
///
/// Response 에 `downloadTokens` 가 포함되며, 이를 alt=media URL 쿼리에 붙여
/// public download URL 을 구성.
class StorageService {
  /// 이미지 파일을 Firebase Storage 에 업로드하고 download URL 을 반환.
  /// 실패 시 null 반환 → 호출자는 로컬 경로 fallback 으로 graceful degradation.
  ///
  /// [path] 는 버킷 내 저장 경로 (e.g. `vouchers/{letterId}.jpg`).
  /// 기존 파일이 있으면 덮어씀.
  static Future<String?> uploadImage({
    required File file,
    required String path,
    String contentType = 'image/jpeg',
  }) async {
    if (!FirebaseConfig.kFirebaseEnabled) return null;
    // Build 208: Storage 가 비활성(Spark 플랜 등) 이면 즉시 null 반환 →
    // 호출자가 로컬 경로 fallback 사용. 네트워크 시도 자체를 안 하므로 30초
    // 타임아웃 대기 시간 절약.
    if (!FirebaseConfig.storageEnabled) {
      if (kDebugMode) {
        debugPrint(
          '[Storage] 업로드 스킵: FIREBASE_STORAGE_ENABLED=false (Blaze 미활성)',
        );
      }
      return null;
    }
    if (!FirebaseAuthService.isSignedIn) {
      if (kDebugMode) {
        debugPrint('[Storage] 업로드 스킵: 로그인 안 됨');
      }
      return null;
    }
    try {
      await FirebaseAuthService.ensureValidToken();
      final token = FirestoreService.idToken;
      if (token == null || token.isEmpty) {
        if (kDebugMode) debugPrint('[Storage] idToken 없음');
        return null;
      }
      final bucket = FirebaseConfig.storageBucket;
      final encodedPath = Uri.encodeComponent(path);
      final url = Uri.parse(
        'https://firebasestorage.googleapis.com/v0/b/$bucket/o'
        '?uploadType=media&name=$encodedPath',
      );

      final bytes = await file.readAsBytes();
      final res = await http
          .post(
            url,
            headers: {
              'Content-Type': contentType,
              'Authorization': 'Bearer $token',
            },
            body: bytes,
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[Storage] 업로드 실패 ${res.statusCode}: ${res.body}');
        }
        return null;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final name = data['name'] as String? ?? path;
      final downloadToken = (data['downloadTokens'] as String?) ?? '';
      if (downloadToken.isEmpty) {
        if (kDebugMode) {
          debugPrint('[Storage] downloadTokens 비어있음 — URL 생성 불가');
        }
        return null;
      }
      final encodedName = Uri.encodeComponent(name);
      return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/'
          '$encodedName?alt=media&token=$downloadToken';
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Storage] 업로드 예외: $e\n$st');
      return null;
    }
  }

  /// 교환권 이미지 저장 경로.
  static String voucherPath(String letterId) => 'vouchers/$letterId.jpg';
}
