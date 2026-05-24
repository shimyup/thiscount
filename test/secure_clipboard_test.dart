// Build 362 (PR-AA3): SecureClipboard 유틸 테스트.
//
// flutter_test 의 BinaryMessenger 를 가로채서 Clipboard.setData/getData 호출을
// 흉내내고 TTL clear 동작을 검증.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thiscount/core/utils/secure_clipboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Clipboard 흉내 — 실제로는 platform 채널 호출이지만 테스트에서는
  //   binaryMessenger 를 가로채서 in-memory string 으로 처리.
  late String? _stored;

  setUp(() {
    _stored = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        _stored = (call.arguments as Map)['text'] as String?;
        return null;
      }
      if (call.method == 'Clipboard.getData') {
        return {'text': _stored ?? ''};
      }
      return null;
    });
    SecureClipboard.resetForTest();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    SecureClipboard.resetForTest();
  });

  group('SecureClipboard.copyEphemeral', () {
    test('즉시 clipboard 에 복사', () async {
      await SecureClipboard.copyEphemeral('TC-ABCD-1234');
      expect(_stored, 'TC-ABCD-1234');
    });

    test('빈 문자열은 noop', () async {
      _stored = 'previous';
      await SecureClipboard.copyEphemeral('');
      expect(_stored, 'previous');
    });

    test('TTL 후 clipboard 가 우리 값이면 빈 문자열로 clear', () async {
      await SecureClipboard.copyEphemeral(
        'TC-WXYZ-0000',
        ttl: const Duration(milliseconds: 50),
      );
      expect(_stored, 'TC-WXYZ-0000');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(_stored, '');
    });

    test('TTL 사이 사용자가 다른 값으로 변경하면 clear skip', () async {
      await SecureClipboard.copyEphemeral(
        'TC-AAAA-BBBB',
        ttl: const Duration(milliseconds: 50),
      );
      _stored = 'user copied something else';
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(_stored, 'user copied something else');
    });

    test('새로운 ephemeral copy 가 직전 timer 를 cancel', () async {
      await SecureClipboard.copyEphemeral(
        'TC-1111-2222',
        ttl: const Duration(milliseconds: 50),
      );
      // 30ms 후 두번째 copy — 첫번째 timer 가 살아 있으면 우리 두번째 값을 clear 함
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await SecureClipboard.copyEphemeral(
        'TC-3333-4444',
        ttl: const Duration(milliseconds: 200),
      );
      // 첫번째 timer 가 트리거됐을 시점 — 만약 cancel 안됐으면 _stored='' 가 됐을 것
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(_stored, 'TC-3333-4444');
    });
  });

  group('SecureClipboard.copyPersistent', () {
    test('clipboard 에 복사, TTL clear 없음', () async {
      await SecureClipboard.copyPersistent('share text');
      expect(_stored, 'share text');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(_stored, 'share text');
    });

    test('직전 ephemeral 의 clear timer 가 persistent 값을 건드리지 않음', () async {
      await SecureClipboard.copyEphemeral(
        'TC-EPHEMERAL',
        ttl: const Duration(milliseconds: 50),
      );
      await SecureClipboard.copyPersistent('share text');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(_stored, 'share text');
    });
  });
}
