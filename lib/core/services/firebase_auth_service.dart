import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';
import 'firestore_service.dart';

/// Firebase Auth REST API 서비스
class FirebaseAuthService {
  static String? _idToken;
  static String? _uid;
  static DateTime? _tokenExpiry;
  static String? _refreshToken; // 자동 갱신용

  static String? get currentUid => _uid;
  static bool get isSignedIn => _idToken != null && _uid != null;

  /// Firestore 요청 전 호출 — 토큰 만료 시 자동 갱신
  static Future<void> ensureValidToken() async {
    if (_refreshToken == null) return;
    if (_tokenExpiry != null &&
        DateTime.now().isBefore(
          _tokenExpiry!.subtract(const Duration(minutes: 5)),
        )) {
      return; // 아직 5분 이상 남음
    }
    await refreshTokenIfNeeded(
      refreshToken: _refreshToken!,
      forceIfExpiringSoon: true,
    );
  }

  // ── 이메일/비밀번호 로그인 ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    if (!FirebaseConfig.kFirebaseEnabled) return null;
    try {
      final res = await http
          .post(
            Uri.parse(
              '${FirebaseConfig.authBase}:signInWithPassword?key=${FirebaseConfig.apiKey}',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'returnSecureToken': true,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _idToken = data['idToken'] as String?;
        _uid = data['localId'] as String?;
        _refreshToken = data['refreshToken'] as String?;
        _tokenExpiry = DateTime.now().add(const Duration(seconds: 3600));
        FirestoreService.setIdToken(_idToken ?? '');
        return data;
      }
    } catch (e, st) {
      debugPrint('[FirebaseAuthService] 에러: $e\n$st');
    }
    return null;
  }

  // ── 회원가입 ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> signUp({
    required String email,
    required String password,
  }) async {
    if (!FirebaseConfig.kFirebaseEnabled) return null;
    try {
      final res = await http
          .post(
            Uri.parse(
              '${FirebaseConfig.authBase}:signUp?key=${FirebaseConfig.apiKey}',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'returnSecureToken': true,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _idToken = data['idToken'] as String?;
        _uid = data['localId'] as String?;
        _refreshToken = data['refreshToken'] as String?;
        _tokenExpiry = DateTime.now().add(const Duration(seconds: 3600));
        FirestoreService.setIdToken(_idToken ?? '');
        return data;
      }
    } catch (e, st) {
      debugPrint('[FirebaseAuthService] 에러: $e\n$st');
    }
    return null;
  }

  // ── 로그아웃 ─────────────────────────────────────────────────────────────────
  static void signOut() {
    _idToken = null;
    _uid = null;
    _tokenExpiry = null;
    _refreshToken = null;
    FirestoreService.setIdToken('');
  }

  // ── 토큰 갱신 확인 ──────────────────────────────────────────────────────────
  static Future<void> refreshTokenIfNeeded({
    required String refreshToken,
    bool forceIfExpiringSoon = false,
  }) async {
    if (!FirebaseConfig.kFirebaseEnabled) return;
    // forceIfExpiringSoon=true(ensureValidToken 경유) 시에는 5분 전 갱신 허용
    // 일반 호출 시에는 실제 만료 후에만 갱신
    if (!forceIfExpiringSoon &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) return;
    try {
      final res = await http
          .post(
            Uri.parse(
              'https://securetoken.googleapis.com/v1/token?key=${FirebaseConfig.apiKey}',
            ),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'grant_type=refresh_token&refresh_token=$refreshToken',
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _idToken = data['id_token'] as String?;
        _tokenExpiry = DateTime.now().add(const Duration(seconds: 3600));
        FirestoreService.setIdToken(_idToken ?? '');
      }
    } catch (e, st) {
      debugPrint('[FirebaseAuthService] 에러: $e\n$st');
    }
  }
}
