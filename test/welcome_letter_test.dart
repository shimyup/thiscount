import 'package:flutter_test/flutter_test.dart';
import 'package:thiscount/features/welcome/welcome_letter.dart';
import 'package:thiscount/models/letter.dart';

void main() {
  group('buildWelcomeLetter', () {
    test('uses stable per-user id and brand senderId', () {
      final l = buildWelcomeLetter(
        userId: 'user_123',
        userCountry: '대한민국',
        userCountryFlag: '🇰🇷',
        userLat: 37.5665,
        userLng: 126.978,
        langCode: 'ko',
      );
      expect(l.id, 'welcome_user_123');
      expect(l.senderId, 'letter_go_welcome');
      expect(l.senderIsBrand, isTrue);
      expect(l.senderTier, LetterSenderTier.brand);
    });

    test('already delivered (status=delivered) so user can read immediately', () {
      final l = buildWelcomeLetter(
        userId: 'u',
        userCountry: 'United States',
        userCountryFlag: '🇺🇸',
        userLat: 40.0,
        userLng: -74.0,
        langCode: 'en',
      );
      expect(l.status, DeliveryStatus.delivered);
      expect(l.arrivedAt, isNotNull);
    });

    test('falls back to 🌍 flag when user has empty flag', () {
      final l = buildWelcomeLetter(
        userId: 'u',
        userCountry: '대한민국',
        userCountryFlag: '',
        userLat: 37.5,
        userLng: 126.9,
        langCode: 'ko',
      );
      expect(l.destinationCountryFlag, '🌍');
    });

    test('content is language-specific (body text length > 50 chars)', () {
      for (final lang in ['ko', 'en', 'ja', 'fr', 'ar', 'hi', 'th']) {
        final l = buildWelcomeLetter(
          userId: 'u',
          userCountry: '대한민국',
          userCountryFlag: '🇰🇷',
          userLat: 37.5,
          userLng: 126.9,
          langCode: lang,
        );
        expect(l.content.length, greaterThan(50),
            reason: '$lang welcome body should be substantial');
      }
    });

    test('unknown language falls back to English body', () {
      final unknown = buildWelcomeLetter(
        userId: 'u',
        userCountry: '대한민국',
        userCountryFlag: '🇰🇷',
        userLat: 37.5,
        userLng: 126.9,
        langCode: 'xx',
      );
      final english = buildWelcomeLetter(
        userId: 'u',
        userCountry: '대한민국',
        userCountryFlag: '🇰🇷',
        userLat: 37.5,
        userLng: 126.9,
        langCode: 'en',
      );
      expect(unknown.content, english.content);
    });

    // Build 268: trial gating regression test (Build 265 fix).
    test('withTrial: false → body does NOT mention 7-day Premium trial', () {
      final l = buildWelcomeLetter(
        userId: 'u',
        userCountry: '대한민국',
        userCountryFlag: '🇰🇷',
        userLat: 37.5,
        userLng: 126.9,
        langCode: 'ko',
        // withTrial defaults to false
      );
      expect(l.content.contains('7일'), isFalse,
          reason: 'no trial mention when withTrial=false');
      expect(l.content.contains('Premium 체험'), isFalse);
    });

    test('withTrial: true → body includes trial mention paragraph (ko/en)', () {
      final ko = buildWelcomeLetter(
        userId: 'u',
        userCountry: '대한민국',
        userCountryFlag: '🇰🇷',
        userLat: 37.5,
        userLng: 126.9,
        langCode: 'ko',
        withTrial: true,
      );
      expect(ko.content.contains('7일간 Premium'), isTrue,
          reason: 'ko trial mention should be inserted');

      final en = buildWelcomeLetter(
        userId: 'u',
        userCountry: 'United States',
        userCountryFlag: '🇺🇸',
        userLat: 40.0,
        userLng: -74.0,
        langCode: 'en',
        withTrial: true,
      );
      expect(en.content.contains('7-day Premium trial'), isTrue,
          reason: 'en trial mention should be inserted');
    });

    test('senderId stable for inbox dedup keying', () {
      // Build 265: senderId 변경 시 기존 사용자 inbox 의 letter 매칭이 깨짐.
      // 누구나 senderId 를 'letter_go_welcome' 로 가정해 dedup 하므로 변경 금지.
      final l = buildWelcomeLetter(
        userId: 'any',
        userCountry: '대한민국',
        userCountryFlag: '🇰🇷',
        userLat: 37.5,
        userLng: 126.9,
        langCode: 'ko',
      );
      expect(l.senderId, 'letter_go_welcome');
    });
  });
}
