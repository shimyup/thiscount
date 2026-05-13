// Build 283: AppPalette 다크/라이트 토큰 무결성 + brightness 분기 테스트.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thiscount/core/theme/app_palette.dart';

void main() {
  group('AppPaletteDark — baseline tokens', () {
    const p = AppPaletteDark();

    test('5 카테고리 컬러 정확', () {
      expect(p.coupon, const Color(0xFFFF4D6D));
      expect(p.reward, const Color(0xFFB8FF5C));
      expect(p.premium, const Color(0xFFFFD60A));
      expect(p.map, const Color(0xFF5BA4F6));
      expect(p.streak, const Color(0xFFC77DFF));
    });

    test('Pure black baseline + 4-tier surface', () {
      expect(p.bgDeep, const Color(0xFF000000));
      expect(p.bgCanvas, const Color(0xFF0A0A0C));
      expect(p.bgCard, const Color(0xFF141417));
      expect(p.bgElevated, const Color(0xFF2A2A2E));
    });

    test('Semantic aliases 매핑', () {
      expect(p.success, equals(p.reward));
      expect(p.warning, equals(p.premium));
      expect(p.error, equals(p.coupon));
    });
  });

  group('AppPaletteLight — paper wallet 컨셉', () {
    const p = AppPaletteLight();

    test('Warm off-white baseline (not pure white)', () {
      expect(p.bgCanvas, const Color(0xFFFAF7F2));
      expect(p.bgDeep.value, lessThan(0xFFFFFFFF));
      expect(p.bgCard, const Color(0xFFFFFFFF));
    });

    test('Muted 카테고리 컬러 (saturation -8%, lightness -5%)', () {
      expect(p.coupon, const Color(0xFFE64463));
      expect(p.reward, const Color(0xFF8BD13A));
      expect(p.premium, const Color(0xFFE6B800));
    });

    test('Text 대비 — primary 가 가장 어둠', () {
      expect(p.textPrimary.value, lessThan(p.textSecondary.value));
      expect(p.textSecondary.value, lessThan(p.textMuted.value));
    });
  });

  group('context.palette — brightness 분기', () {
    testWidgets('dark theme → AppPaletteDark', (tester) async {
      AppPalette? captured;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(builder: (ctx) {
          captured = ctx.palette;
          return const SizedBox.shrink();
        }),
      ));
      expect(captured, isA<AppPaletteDark>());
      expect(captured!.coupon, const Color(0xFFFF4D6D));
    });

    testWidgets('light theme → AppPaletteLight', (tester) async {
      AppPalette? captured;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.light(),
        home: Builder(builder: (ctx) {
          captured = ctx.palette;
          return const SizedBox.shrink();
        }),
      ));
      expect(captured, isA<AppPaletteLight>());
      expect(captured!.coupon, const Color(0xFFE64463));
    });
  });
}
