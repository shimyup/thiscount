// Build 370 (PR-CC4 P0 #9): GPS spoofing 차단 — SecureClock 대칭 패턴.
//
// `Geolocator.getCurrentPosition` 의 반환 Position 객체는 `isMocked` flag 를
// 노출 (Android API 18+ / iOS Simulator 일부). 이 flag 가 true 면:
//   - Android: Fake GPS / Mock Location 앱 활성
//   - iOS Simulator: Xcode Custom Location 또는 .gpx 파일 주입
//
// 차단 대상:
//   - Brand zone redemption 위조 (사용자가 매장 위치로 위장 → 자동 발급)
//   - 다른 사용자 지도에 위장 위치 표시 (isMapPublic ON)
//   - 픽업 200m 반경 우회 (먼 letter 위치로 위장 → 픽업)
//
// 정책:
//   - kReleaseMode + isMocked → 차단 (예외 throw 또는 null 반환)
//   - debug / simulator → 경고만 (개발 편의 — 시뮬레이터는 항상 mocked)
//
// 호출 예:
//   final pos = await Geolocator.getCurrentPosition(...);
//   if (!SecureLocation.allow(pos)) {
//     // spoofing detected — UI 알림 or skip
//     return;
//   }

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class SecureLocation {
  SecureLocation._();

  /// Position 이 신뢰 가능한지 검증.
  /// release 빌드 + mocked = false (차단).
  /// debug/profile 빌드 + mocked = true (경고만 — 시뮬레이터/개발 편의).
  static bool allow(Position pos) {
    final mocked = pos.isMocked;
    if (!mocked) return true;
    if (kReleaseMode) {
      if (kDebugMode) {
        debugPrint('[SecureLocation] mocked position rejected (release)');
      }
      return false;
    }
    if (kDebugMode) {
      debugPrint('[SecureLocation] mocked position allowed (non-release)');
    }
    return true;
  }

  /// 차단된 spoofing 시도 카운터 (analytics / debugging 용).
  static int _rejectedCount = 0;
  static int get rejectedCount => _rejectedCount;

  /// Position 신뢰 검증 + spoofing 차단 시 reject counter +1.
  /// returns null 이면 caller 가 위치 처리 skip.
  static Position? guard(Position pos) {
    if (allow(pos)) return pos;
    _rejectedCount++;
    return null;
  }

  /// 테스트용 reset.
  @visibleForTesting
  static void resetForTest() {
    _rejectedCount = 0;
  }
}
