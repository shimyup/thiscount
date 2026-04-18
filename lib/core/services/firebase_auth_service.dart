import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

  // ── Firebase 에러 코드 → 사용자 메시지 매핑 ──────────────────────────────────
  static String _mapFirebaseError(String code) {
    switch (code) {
      case 'EMAIL_NOT_FOUND':
        return '등록되지 않은 이메일입니다.';
      case 'INVALID_PASSWORD':
        return '비밀번호가 올바르지 않습니다.';
      case 'USER_DISABLED':
        return '비활성화된 계정입니다. 고객 지원에 문의해주세요.';
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return '로그인 시도가 너무 많습니다. 잠시 후 다시 시도해주세요.';
      case 'EMAIL_EXISTS':
        return '이미 가입된 이메일입니다.';
      case 'WEAK_PASSWORD':
        return '비밀번호가 너무 약합니다 (6자 이상 입력해주세요).';
      case 'INVALID_EMAIL':
        return '이메일 형식이 올바르지 않습니다.';
      case 'OPERATION_NOT_ALLOWED':
        return '이메일 로그인이 비활성화되어 있습니다.';
      default:
        return '인증 오류가 발생했습니다 ($code).';
    }
  }

  /// Firebase REST API 응답에서 에러 코드를 추출합니다.
  static String? _extractErrorCode(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>?;
      return error?['message'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── 이메일/비밀번호 로그인 ────────────────────────────────────────────────────
  /// 성공 시 data Map 반환.
  /// 실패 시 `data['error']` 키에 사용자 메시지 포함.
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

      // Firebase 에러 코드 파싱
      final errorCode = _extractErrorCode(res);
      final userMsg = errorCode != null ? _mapFirebaseError(errorCode) : '로그인에 실패했습니다.';
      if (kDebugMode) debugPrint('[FirebaseAuthService] 로그인 실패: $errorCode');
      return {'error': userMsg};
    } on SocketException {
      return {'error': '네트워크 연결을 확인해주세요.'};
    } on TimeoutException {
      return {'error': '서버 응답 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.'};
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FirebaseAuthService] 에러: $e\n$st');
      return {'error': '로그인 중 오류가 발생했습니다.'};
    }
  }

  // ── 회원가입 ─────────────────────────────────────────────────────────────────
  /// 성공 시 data Map 반환.
  /// 실패 시 `data['error']` 키에 사용자 메시지 포함.
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

      // Firebase 에러 코드 파싱
      final errorCode = _extractErrorCode(res);
      final userMsg = errorCode != null ? _mapFirebaseError(errorCode) : '회원가입에 실패했습니다.';
      if (kDebugMode) debugPrint('[FirebaseAuthService] 회원가입 실패: $errorCode');
      return {'error': userMsg};
    } on SocketException {
      return {'error': '네트워크 연결을 확인해주세요.'};
    } on TimeoutException {
      return {'error': '서버 응답 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.'};
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FirebaseAuthService] 에러: $e\n$st');
      return {'error': '회원가입 중 오류가 발생했습니다.'};
    }
  }

  // ── 익명 로그인 (테스터용 — Firebase 계정 없이 Firestore 접근) ────────────────
  static Future<bool> signInAnonymously() async {
    if (!FirebaseConfig.kFirebaseEnabled) return false;
    // 이미 로그인 상태면 스킵
    if (_idToken != null && _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) return true;
    try {
      final res = await http
          .post(
            Uri.parse(
              '${FirebaseConfig.authBase}:signUp?key=${FirebaseConfig.apiKey}',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'returnSecureToken': true}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _idToken = data['idToken'] as String?;
        _uid = data['localId'] as String?;
        _refreshToken = data['refreshToken'] as String?;
        _tokenExpiry = DateTime.now().add(const Duration(seconds: 3600));
        FirestoreService.setIdToken(_idToken ?? '');
        if (kDebugMode) debugPrint('[FirebaseAuth] 익명 로그인 성공: $_uid');
        return true;
      }
      if (kDebugMode) debugPrint(
        '[FirebaseAuth] 익명 로그인 실패: ${res.statusCode} ${res.body}',
      );
    } on SocketException {
      if (kDebugMode) debugPrint('[FirebaseAuth] 익명 로그인 실패: 네트워크 연결 없음');
    } on TimeoutException {
      if (kDebugMode) debugPrint('[FirebaseAuth] 익명 로그인 실패: 응답 시간 초과');
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FirebaseAuth] 익명 로그인 에러: $e\n$st');
    }
    return false;
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
    } on SocketException {
      if (kDebugMode) debugPrint('[FirebaseAuthService] 토큰 갱신 실패: 네트워크 연결 없음');
    } on TimeoutException {
      if (kDebugMode) debugPrint('[FirebaseAuthService] 토큰 갱신 실패: 응답 시간 초과');
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FirebaseAuthService] 에러: $e\n$st');
    }
  }
}
