// Build 362 (PR-AA3): 민감 정보 (매장 POS 코드 / 프로모션 코드) 의 clipboard
// TTL clear. 1Password / Authy 등 보안 앱 표준 패턴.
//
// Build 365 (PR-BB4): 보안 모델 보강
//   - WidgetsBindingObserver 등록 → background 였다가 resumed 시 pending clear
//     재시도 (이전엔 background 진입 시 clear skip + _lastValue null → 무기한
//     잔존하는 P0 회귀가 있었음. 가장 흔한 모바일 패턴 "copy 후 즉시 홈" 에서
//     보안 모델 사실상 무산이었음.)
//   - Clipboard.setData 실패 try/catch — iOS lockdown 등 rare 환경에서 unhandled
//     future error 방지.
//
// 한계 (docstring 명시):
//   - 사용자가 앱 강제 종료 (kill swipe) 하면 Dart Timer 가 isolate 와 함께
//     소멸 → clipboard 영구 잔존. 분실폰 잠금화면 우회 후 메모장 paste 시 leak
//     위험. native iOS keychain-based background daemon 으로만 완전 해결 가능.
//   - iOS 14+ Universal Clipboard 가 Handoff 로 Mac 에 즉시 sync → 45초 후
//     iPhone 만 clear, Mac 잔존 가능 (Apple 일방향 push, write-back 없음).
//
// 사용 예:
//   await SecureClipboard.copyEphemeral(
//     code,
//     ttl: const Duration(seconds: 45),
//   );

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureClipboard {
  SecureClipboard._();

  /// 활성 clear timer — 새로운 ephemeral copy 호출 시 기존 timer cancel.
  static Timer? _activeTimer;

  // Build 412 (PII sim LOW YES.8): kill-swipe(앱 강제종료) 시 Dart Timer 가
  //   isolate 와 함께 소멸 → clipboard 의 민감 코드가 무기한 잔존하던 한계.
  //   pending clear 를 secure storage 에 (값이 아닌 sha256 해시 + 만료시각으로)
  //   영속화하고, 다음 cold-start 에 clearStaleOnLaunch() 가 만료된 항목을
  //   clipboard 와 대조 후 제거. 값 자체는 저장하지 않음(해시만).
  static const _persistKey = 'sec_clip_pending_v1';
  static const FlutterSecureStorage _store = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static String _hash(String v) => sha256.convert(utf8.encode(v)).toString();

  /// 가장 최근 copy 한 값. clear 시점에 clipboard 가 여전히 이 값인지 확인용.
  static String? _pendingValue;

  /// pending clear 의 만료 시각 (Build 365 P0-2 fix). lifecycle observer 가
  /// resumed 시 이 값을 검사해 overdue 면 즉시 clear.
  static DateTime? _pendingExpiresAt;

  static bool _observerAttached = false;
  static final _LifecycleHook _observer = _LifecycleHook();

  static void _ensureObserverAttached() {
    if (_observerAttached) return;
    _observerAttached = true;
    // ensureInitialized — main.dart 보다 먼저 호출될 수 있으므로 안전 가드.
    WidgetsBinding.instance.addObserver(_observer);
  }

  /// 민감 값 [text] 를 clipboard 에 복사하고 [ttl] 후 자동 clear.
  ///
  /// [text] 가 빈 문자열이면 noop. [ttl] 기본 45초.
  ///
  /// Clipboard.setData 실패 시 (iOS lockdown 등 rare) 빈 try/catch 로 swallow
  /// + pending state cleanup → 호출자는 SnackBar 표시 그대로 진행 (UX 비용 적음).
  static Future<void> copyEphemeral(
    String text, {
    Duration ttl = const Duration(seconds: 45),
  }) async {
    if (text.isEmpty) return;
    _ensureObserverAttached();
    _activeTimer?.cancel();
    _pendingValue = text;
    _pendingExpiresAt = DateTime.now().add(ttl);
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      if (kDebugMode) debugPrint('[SecureClipboard] setData err: $e');
      _pendingValue = null;
      _pendingExpiresAt = null;
      return;
    }
    _activeTimer = Timer(ttl, _attemptClear);
    // 영속화 (kill-swipe 후 cold-start clear 용). 실패해도 in-memory timer 가
    //   주 경로이므로 best-effort.
    unawaited(_persistPending(text, _pendingExpiresAt!));
  }

  static Future<void> _persistPending(String text, DateTime expiresAt) async {
    try {
      await _store.write(
        key: _persistKey,
        value: jsonEncode({
          'h': _hash(text),
          'exp': expiresAt.millisecondsSinceEpoch,
        }),
      );
    } catch (_) {/* best-effort */}
  }

  static Future<void> _clearPersisted() async {
    try {
      await _store.delete(key: _persistKey);
    } catch (_) {/* best-effort */}
  }

  /// 앱 cold-start 시 1회 호출 (main). 직전 세션에서 kill 돼 clear 못 한
  /// 민감 clipboard 가 만료됐고, clipboard 가 여전히 그 값(해시 일치)이면 제거.
  static Future<void> clearStaleOnLaunch() async {
    try {
      final raw = await _store.read(key: _persistKey);
      if (raw == null) return;
      await _store.delete(key: _persistKey); // 1회성 — 즉시 소비
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final expMs = (m['exp'] as num?)?.toInt() ?? 0;
      final h = m['h'] as String? ?? '';
      if (h.isEmpty) return;
      // 만료 전이면 그대로 둔다 (정상 TTL 범위 — 새 세션 timer 없지만 곧 만료).
      if (DateTime.now().millisecondsSinceEpoch < expMs) return;
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      final cur = current?.text;
      if (cur != null && cur.isNotEmpty && _hash(cur) == h) {
        await Clipboard.setData(const ClipboardData(text: ''));
        if (kDebugMode) debugPrint('[SecureClipboard] stale cleared on launch');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SecureClipboard] launch-clear err: $e');
    }
  }

  /// 일반 copy — TTL 없음. share text 등 일반 텍스트용 wrapper.
  /// 직전 ephemeral copy 의 활성 clear timer 가 있으면 cancel.
  static Future<void> copyPersistent(String text) async {
    if (text.isEmpty) return;
    _activeTimer?.cancel();
    _activeTimer = null;
    _pendingValue = null;
    _pendingExpiresAt = null;
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      if (kDebugMode) debugPrint('[SecureClipboard] setData err: $e');
    }
  }

  static Future<void> _attemptClear() async {
    if (_pendingValue == null) return;
    // App lifecycle 확인 — background 면 clear 시도 자체를 skip
    //   (iOS 14+ 가 다음 foreground 시 paste prompt 띄울 수 있음).
    //   Build 365 (PR-BB4 P0-2 fix): _pendingValue / _pendingExpiresAt 는
    //   null 처리 안 함 → 다음 resumed 시 observer 가 재시도.
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) {
      if (kDebugMode) {
        debugPrint('[SecureClipboard] clear deferred (lifecycle $state)');
      }
      return;
    }
    try {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == _pendingValue) {
        await Clipboard.setData(const ClipboardData(text: ''));
        if (kDebugMode) debugPrint('[SecureClipboard] cleared after TTL');
      } else {
        if (kDebugMode) {
          debugPrint('[SecureClipboard] clear skipped — clipboard changed');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SecureClipboard] clear err: $e');
    } finally {
      _pendingValue = null;
      _pendingExpiresAt = null;
      _activeTimer = null;
      unawaited(_clearPersisted());
    }
  }

  /// Lifecycle observer 가 resumed 시 호출 — pending TTL 이 이미 경과했으면
  /// 즉시 clear 시도.
  static void _onAppResumed() {
    final expiresAt = _pendingExpiresAt;
    if (expiresAt == null) return;
    if (DateTime.now().isAfter(expiresAt)) {
      // overdue — background 중 timer 가 fire 못 한 케이스. 즉시 clear.
      _attemptClear();
    }
    // 아직 만료 전이면 timer 가 자동 fire (foreground 복귀 후).
  }

  /// 테스트용 — 활성 timer cancel + state reset.
  @visibleForTesting
  static void resetForTest() {
    _activeTimer?.cancel();
    _activeTimer = null;
    _pendingValue = null;
    _pendingExpiresAt = null;
  }

  /// 테스트용 — observer 가 resumed 호출했을 때의 동작 직접 트리거.
  @visibleForTesting
  static void simulateAppResumedForTest() => _onAppResumed();
}

class _LifecycleHook extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SecureClipboard._onAppResumed();
    }
  }
}
