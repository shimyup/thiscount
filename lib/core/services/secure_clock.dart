import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 시계 되돌리기 (clock rewind) 우회 차단용 high-watermark clock.
///
/// 보안 검증 — trial 만료 / login lockout / OTP 만료 — 에서만 사용한다.
/// 일반 UI 시각 표시는 `DateTime.now()` 그대로 사용해도 무방.
///
/// 작동:
///   1. `init()` 가 secure storage 에서 `_watermarkMs` 를 로드 (앱 부팅).
///   2. `now()` 는 `max(DateTime.now(), _watermarkMs)` 반환 + 시스템 시각이
///      더 미래라면 watermark 를 그쪽으로 advance.
///   3. `touch(at)` 은 명시적으로 watermark 를 advance (OTP 발급 / lockout
///      셋팅 / trial 부여 시점에 호출하여 그 시각을 안전한 하한으로 박음).
///
/// secure storage 에 저장된 값은 Android EncryptedSharedPreferences /
/// iOS Keychain 에 있어 일반 "앱 데이터 지우기" 로 사라지지 않는다.
/// 단, 앱 재설치 시에는 사라질 수 있다 — 재설치는 어차피 trial 재발급
/// 트리거이므로 위협 모델상 동등하다.
class SecureClock {
  static const _key = 'secure_clock_watermark_ms_v1';
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static int _watermarkMs = 0;
  static bool _initialized = false;

  /// 앱 부팅 시 한 번 호출. secure storage 에서 watermark 로드.
  /// 미호출 상태에서 [now]/[touch] 호출 시 시스템 시각만 사용 (regression 없음).
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final raw = await _secure.read(key: _key);
      _watermarkMs = int.tryParse(raw ?? '') ?? 0;
    } catch (_) {
      _watermarkMs = 0;
    }
  }

  /// 시계 되돌리기에 강한 현재 시각.
  /// 시스템 시각이 watermark 보다 앞이면 watermark 를 advance (fire-and-forget).
  static DateTime now() {
    final sysMs = DateTime.now().millisecondsSinceEpoch;
    if (sysMs > _watermarkMs) {
      _watermarkMs = sysMs;
      // 잦은 write 를 피하기 위해 throttle: 마지막 persist 에서 1분 이상
      // 지났을 때만 secure storage 에 기록. 디스크 watermark 가 최대 60초
      // 뒤처질 수 있으나, 보안 검증 대상(trial 만료/lockout/OTP)은 분 단위
      // 이상 스케일이라 위협 모델상 무해. touch() 는 항상 즉시 persist.
      if (sysMs - _lastPersistedMs >= 60000) {
        _lastPersistedMs = sysMs;
        _persist();
      }
      return DateTime.fromMillisecondsSinceEpoch(sysMs);
    }
    return DateTime.fromMillisecondsSinceEpoch(_watermarkMs);
  }

  static int _lastPersistedMs = 0;

  /// 명시적으로 watermark 를 [at] (기본: 현재 시스템 시각) 까지 advance.
  /// OTP 발급 / lockout 셋팅 / trial 부여 시점에 호출하여 그 시각을 박는다.
  static void touch([DateTime? at]) {
    final ms = (at ?? DateTime.now()).millisecondsSinceEpoch;
    if (ms > _watermarkMs) {
      _watermarkMs = ms;
      _lastPersistedMs = ms; // 명시 anchor 는 즉시 persist (throttle 무시)
      _persist();
    }
  }

  static Future<void> _persist() async {
    if (!_hasServicesBinding) return;
    try {
      await _secure.write(key: _key, value: '$_watermarkMs');
    } catch (e) {
      assert(() {
        debugPrint('[SecureClock] persist failed: $e');
        return true;
      }());
    }
  }

  static bool get _hasServicesBinding {
    try {
      ServicesBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }
}
