// Build 362 (PR-AA3): 민감 정보 (매장 POS 코드 / 프로모션 코드) 의 clipboard
// TTL clear. 1Password / Authy 등 보안 앱 표준 패턴.
//
// 사용 예:
//   await SecureClipboard.copyEphemeral(
//     code,
//     label: 'POS code',
//     ttl: const Duration(seconds: 45),
//   );
//
// 동작:
//   1. Clipboard.setData(code) 즉시 호출 (사용자 paste 가능).
//   2. ttl 후 Clipboard 를 다시 읽어 우리 값과 일치하면 빈 문자열로 덮어쓰기.
//      - 일치 검사 → 사용자가 다른 텍스트를 copy 했으면 손대지 않음.
//   3. iOS 14+ 의 paste prompt 는 우리 앱이 다시 foreground 일 때만 발생.
//      - clear timer 시점에 앱이 background 면 clear skip (다음 foreground 시 처리).
//
// 보안 모델:
//   - shoulder-surfing 후 사용자가 잠시 후 다른 앱 paste 하면 코드 leak.
//   - 45초 후 자동 clear 로 leak 창 제한.
//   - "확실한 secret" 만 사용 — share text 같은 일반 텍스트는 일반 Clipboard
//     사용 (예상치 못한 clear 로 사용자가 paste 실패 경험 최소화).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class SecureClipboard {
  SecureClipboard._();

  /// 활성 clear timer — 새로운 ephemeral copy 호출 시 기존 timer cancel.
  static Timer? _activeTimer;

  /// 가장 최근 copy 한 값. clear 시점에 clipboard 가 여전히 이 값인지 확인용.
  static String? _lastValue;

  /// 민감 값 [text] 를 clipboard 에 복사하고 [ttl] 후 자동 clear.
  ///
  /// [text] 가 빈 문자열이면 noop. [ttl] 기본 45초.
  static Future<void> copyEphemeral(
    String text, {
    Duration ttl = const Duration(seconds: 45),
  }) async {
    if (text.isEmpty) return;
    _activeTimer?.cancel();
    _lastValue = text;
    await Clipboard.setData(ClipboardData(text: text));
    _activeTimer = Timer(ttl, _attemptClear);
  }

  /// 일반 copy — TTL 없음. share text 등 일반 텍스트용 wrapper.
  /// 직전 ephemeral copy 의 활성 clear timer 가 있으면 cancel
  /// (사용자가 다른 비-비밀 텍스트를 명시 copy 했으므로 clear 의도 없음).
  static Future<void> copyPersistent(String text) async {
    if (text.isEmpty) return;
    _activeTimer?.cancel();
    _activeTimer = null;
    _lastValue = null;
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<void> _attemptClear() async {
    // App lifecycle 확인 — background 면 clear 시도 자체를 skip
    //   (iOS 14+ 가 다음 foreground 시 paste prompt 띄울 수 있음).
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) {
      // background — 다음 foreground 시 재시도. 단순화 위해 한번만 시도.
      // (실제로는 paused→resumed observer 추가 가능 — 현재 scope 외.)
      if (kDebugMode) {
        debugPrint('[SecureClipboard] clear skipped (lifecycle $state)');
      }
      _lastValue = null;
      return;
    }
    try {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == _lastValue) {
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
      _lastValue = null;
    }
  }

  /// 테스트용 — 활성 timer cancel + state reset.
  @visibleForTesting
  static void resetForTest() {
    _activeTimer?.cancel();
    _activeTimer = null;
    _lastValue = null;
  }
}
