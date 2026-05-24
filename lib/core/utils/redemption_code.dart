// Build 331 (PR-S1): Letter 사용 코드 발급 + 검증 유틸.
//
// 매장 POS 스캔 / 수동 입력용 8자 영숫자 코드.
//   - Crockford base32 알파벳 (혼동 문자 I/L/O/U 제거) → 통화 시 오류 ↓
//   - 6자 랜덤 + 2자 check digit (SHA256 기반)
//   - 표시 형식: `TC-XXXX-XXXX` (1+4+4)
//   - 검증: verify() — 코드 끝 2자 check digit 일치 확인 → 단순 typo / 무작위
//     fake 코드 거절. 진짜 변조 차단은 Phase 2 서버 portal 에서.
//
// 코드 충돌: 32^6 = 1.07억 조합. 1 Brand 가 10만 letter 발송 시 충돌 확률
// ≈ 0.0001% (생일 역설 적용). 무시 가능.
//
// HMAC 비밀키 미사용 — 클라이언트 측에 secret 두면 leak 위험. 대신 stable
// SALT 로 check digit 만 계산 → "사람 typo 잡기" 가 주 목적. 진짜 위조는
// 픽업한 사용자만 reveal 가능 + redemptionExpiresAt + redeemedAt 1회 가드.

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class RedemptionCode {
  // Crockford base32: 0-9 + A-Z minus I, L, O, U → 32 chars
  static const String _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static const int _alphabetLen = 32; // _alphabet.length 사전 계산
  static const String _salt = 'thiscount-v1-redemption-code-check-digit';

  /// 8자 영숫자 코드 생성 (6 랜덤 + 2 check digit).
  /// [rng] null 이면 Random.secure() 사용 (예측 불가).
  static String generate({Random? rng}) {
    final r = rng ?? Random.secure();
    final body = String.fromCharCodes(
      Iterable.generate(6, (_) => _alphabet.codeUnitAt(r.nextInt(_alphabetLen))),
    );
    return body + _checkDigit(body);
  }

  /// 표시용 포맷: `TC-XXXX-XXXX` (1+4+4).
  static String formatForDisplay(String code) {
    if (code.length != 8) return 'TC-$code';
    return 'TC-${code.substring(0, 4)}-${code.substring(4, 8)}';
  }

  /// 사용자 입력 (TC-/공백/대소문자 등) 정규화 → 8자 영숫자 코드.
  /// 형식 불일치 시 null.
  static String? normalize(String raw) {
    var c = raw.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
    if (c.startsWith('TC')) c = c.substring(2);
    if (c.length != 8) return null;
    // 알파벳 외 문자 1개라도 있으면 invalid (단, 0/O · 1/I/L 자동 보정).
    c = c.replaceAll('O', '0').replaceAll('I', '1').replaceAll('L', '1');
    for (var i = 0; i < c.length; i++) {
      if (!_alphabet.contains(c[i])) return null;
    }
    return c;
  }

  /// check digit 일치 확인. invalid 형식 → false.
  ///
  /// ⚠️ 보안 한계 (Build 339, PR-S10 시뮬레이션 P1 #14):
  ///   check digit = 32^2 = 1024 조합. brute-force 시 평균 512 시도로 통과.
  ///   클라이언트 SALT 도 APK 디컴파일로 추출 가능 → 누구나 위조 가능.
  ///   **이 함수는 typo 자동 보정 + 명백한 가짜 거절 목적만**. 진짜 인증은
  ///   Phase 2 의 서버 측 verify (HMAC secret 서버 보관) 가 필요.
  ///   클라이언트는 throttle 의미 없음 (공격자는 verify 를 로컬 무한 호출).
  static bool verify(String code) {
    final n = normalize(code);
    if (n == null) return false;
    final body = n.substring(0, 6);
    final check = n.substring(6, 8);
    return _checkDigit(body) == check;
  }

  /// body (6자) → check digit (2자).
  static String _checkDigit(String body) {
    final h = sha256.convert(utf8.encode('$_salt:$body')).bytes;
    final c0 = _alphabet[h[0] % _alphabetLen];
    final c1 = _alphabet[h[1] % _alphabetLen];
    return '$c0$c1';
  }
}
