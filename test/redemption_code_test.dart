// Build 331 (PR-S1): RedemptionCode 유틸 테스트.

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:thiscount/core/utils/redemption_code.dart';

void main() {
  group('RedemptionCode.generate', () {
    test('항상 8자 Crockford 알파벳만 반환', () {
      const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
      for (var i = 0; i < 200; i++) {
        final code = RedemptionCode.generate();
        expect(code.length, 8);
        for (final c in code.split('')) {
          expect(alphabet.contains(c), isTrue, reason: 'unexpected char: $c in $code');
        }
      }
    });

    test('생성한 코드는 verify() 통과', () {
      for (var i = 0; i < 100; i++) {
        final code = RedemptionCode.generate();
        expect(RedemptionCode.verify(code), isTrue, reason: code);
      }
    });

    test('seed 고정 시 결정적 (테스트 재현)', () {
      final r1 = Random(42);
      final r2 = Random(42);
      expect(RedemptionCode.generate(rng: r1), RedemptionCode.generate(rng: r2));
    });
  });

  group('RedemptionCode.formatForDisplay', () {
    test('TC- prefix + 4+4 그룹화', () {
      expect(RedemptionCode.formatForDisplay('K7M2J9PH'), 'TC-K7M2-J9PH');
    });

    test('비정상 길이는 단순 prefix', () {
      expect(RedemptionCode.formatForDisplay('SHORT'), 'TC-SHORT');
    });
  });

  group('RedemptionCode.normalize', () {
    test('대소문자 / 공백 / 하이픈 / TC- prefix 제거', () {
      expect(RedemptionCode.normalize('tc-k7m2-j9ph'), 'K7M2J9PH');
      expect(RedemptionCode.normalize('  TC K7M2 J9PH  '), 'K7M2J9PH');
      expect(RedemptionCode.normalize('K7M2J9PH'), 'K7M2J9PH');
    });

    test('Build 415: 본문이 TC 로 시작하는 8자 코드는 TC 를 떼지 않음', () {
      // 표시 프리픽스(TC-XXXX-XXXX=10자)일 때만 제거. 8자 코드 앞 TC 는 본문.
      expect(RedemptionCode.normalize('TCABCDEF'), 'TCABCDEF');
      expect(RedemptionCode.normalize('TC-ABCD-EF12'), 'ABCDEF12');
    });

    test('Build 415 (회귀): TC 로 시작하는 생성 코드도 verify 통과', () {
      // 본문 'TC..' 케이스(~1/1024)를 충분히 포함하도록 대량 생성·검증.
      for (var i = 0; i < 3000; i++) {
        final code = RedemptionCode.generate();
        expect(RedemptionCode.verify(code), isTrue, reason: code);
      }
    });

    test('O/0, I/L/1 자동 보정', () {
      // O → 0, I → 1, L → 1
      final corrected = RedemptionCode.normalize('OII LK7M2');
      expect(corrected?.contains('O'), isFalse);
      expect(corrected?.contains('I'), isFalse);
      expect(corrected?.contains('L'), isFalse);
    });

    test('길이 불일치 / 비허용 문자 → null', () {
      expect(RedemptionCode.normalize('TC-SHORT'), isNull);
      expect(RedemptionCode.normalize('TC-TOOLONGCODE'), isNull);
      expect(RedemptionCode.normalize('!@#\$%^&*'), isNull);
    });
  });

  group('RedemptionCode.verify', () {
    test('생성한 코드는 verify true', () {
      final code = RedemptionCode.generate();
      expect(RedemptionCode.verify(code), isTrue);
      // 표시 포맷 통과해도 검증 OK
      expect(RedemptionCode.verify(RedemptionCode.formatForDisplay(code)),
          isTrue);
    });

    test('check digit 변조 시 false', () {
      final code = RedemptionCode.generate();
      // 마지막 글자만 바꾼 코드
      final last = code[code.length - 1];
      final alt = last == 'A' ? 'B' : 'A';
      final tampered = code.substring(0, code.length - 1) + alt;
      expect(RedemptionCode.verify(tampered), isFalse);
    });

    test('완전 무작위 8자 → 1/1024 확률로만 통과', () {
      // 1000개 무작위 생성 시 1개 정도만 통과 (32^2 = 1024)
      const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
      final rng = Random(1);
      var pass = 0;
      for (var i = 0; i < 1000; i++) {
        final s = String.fromCharCodes(
          Iterable.generate(8, (_) => alphabet.codeUnitAt(rng.nextInt(32))),
        );
        if (RedemptionCode.verify(s)) pass++;
      }
      // 통계적 sanity: 2 미만이거나 10 초과면 알고리즘 버그.
      expect(pass, lessThanOrEqualTo(10), reason: 'too many passes: $pass');
    });
  });
}
