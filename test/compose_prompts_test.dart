import 'package:flutter_test/flutter_test.dart';
import 'package:thiscount/features/compose/compose_prompts.dart';

void main() {
  group('composeDailyPrompt', () {
    test('same day + same lang returns same prompt', () {
      final t = DateTime(2026, 4, 19);
      expect(composeDailyPrompt('ko', now: t), composeDailyPrompt('ko', now: t));
    });

    test('rotates across 7 consecutive days', () {
      final seen = <String>{};
      for (int i = 0; i < 7; i++) {
        seen.add(
          composeDailyPrompt('ko', now: DateTime(2026, 4, 1).add(Duration(days: i))),
        );
      }
      expect(seen.length, 7, reason: '7 distinct prompts across a week');
    });

    test('day 0 and day 7 produce the same prompt (weekly rhythm)', () {
      final a = composeDailyPrompt('ko', now: DateTime(2026, 4, 1));
      final b = composeDailyPrompt('ko', now: DateTime(2026, 4, 8));
      expect(a, b);
    });

    test('falls back to English for unknown language', () {
      final t = DateTime(2026, 4, 19);
      final unknown = composeDailyPrompt('xx', now: t);
      final english = composeDailyPrompt('en', now: t);
      expect(unknown, english);
    });

    test('all 14 supported languages return non-empty prompts', () {
      const langs = [
        'ko', 'en', 'ja', 'zh', 'fr', 'de', 'es', 'pt',
        'ru', 'tr', 'ar', 'it', 'hi', 'th',
      ];
      final t = DateTime(2026, 4, 19);
      for (final l in langs) {
        final p = composeDailyPrompt(l, now: t);
        expect(p, isNotEmpty, reason: '$l prompt must be non-empty');
      }
    });
  });
}
