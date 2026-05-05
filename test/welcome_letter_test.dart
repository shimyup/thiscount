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
  });
}
