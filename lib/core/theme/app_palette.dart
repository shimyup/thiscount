// Build 283: Light/Dark mode 추상 팔레트 — 두 테마 공용 인터페이스.
// Widget 은 brightness 분기 없이 `context.palette` 만 의존.
// dark 는 "도시의 밤" (기존 baseline), light 는 "카페에서 펼친 종이 지갑".
//
// 점진 마이그레이션 전략: 기존 `AppColors.*` 사용처는 그대로 두고, 새 widget
// 부터 `context.palette` 채택. 모든 widget 이 마이그레이션되면 `AppColors`
// 의 hex 상수만 남기고 deprecate.

import 'package:flutter/material.dart';

/// 두 모드 공용 토큰 인터페이스.
abstract class AppPalette {
  Color get bgDeep;
  Color get bgCanvas;
  Color get bgCard;
  Color get bgElevated;

  Color get textPrimary;
  Color get textSecondary;
  Color get textMuted;
  Color get textDisabled;

  // 5 카테고리 — 두 모드 공용 (밝기만 살짝 조정)
  Color get coupon;
  Color get reward;
  Color get premium;
  Color get map;
  Color get streak;

  // 카테고리 ink (카테고리 컬러 위의 텍스트)
  Color get couponInk;
  Color get rewardInk;
  Color get premiumInk;

  // 시맨틱
  Color get success => reward;
  Color get warning => premium;
  Color get error;

  Color get hairline;
  Color get overlay;
}

/// Dark — "도시의 밤" (Build 282 baseline).
class AppPaletteDark implements AppPalette {
  const AppPaletteDark();
  @override Color get bgDeep      => const Color(0xFF000000);
  @override Color get bgCanvas    => const Color(0xFF0A0A0C);
  @override Color get bgCard      => const Color(0xFF141417);
  @override Color get bgElevated  => const Color(0xFF2A2A2E);

  @override Color get textPrimary   => const Color(0xFFFFFFFF);
  @override Color get textSecondary => const Color(0xFF8E8E93);
  @override Color get textMuted     => const Color(0xFF5A5A5F);
  @override Color get textDisabled  => const Color(0xFF3A3A3E);

  @override Color get coupon  => const Color(0xFFFF4D6D);
  @override Color get reward  => const Color(0xFFB8FF5C);
  @override Color get premium => const Color(0xFFFFD60A);
  @override Color get map     => const Color(0xFF5BA4F6);
  @override Color get streak  => const Color(0xFFC77DFF);

  @override Color get couponInk  => const Color(0xFF1A0008);
  @override Color get rewardInk  => const Color(0xFF0A1A00);
  @override Color get premiumInk => const Color(0xFF1A1300);

  @override Color get success  => reward;
  @override Color get warning  => premium;
  @override Color get error    => coupon;
  @override Color get hairline => const Color(0x1AFFFFFF);
  @override Color get overlay  => const Color(0x99000000);
}

/// Light — "카페에서 펼친 종이 지갑".
/// saturation -8%, lightness -5% 로 muted 한 카테고리 컬러.
class AppPaletteLight implements AppPalette {
  const AppPaletteLight();
  @override Color get bgDeep      => const Color(0xFFF1ECE3);
  @override Color get bgCanvas    => const Color(0xFFFAF7F2);
  @override Color get bgCard      => const Color(0xFFFFFFFF);
  @override Color get bgElevated  => const Color(0xFFFFFEFB);

  @override Color get textPrimary   => const Color(0xFF1A1A1C);
  @override Color get textSecondary => const Color(0xFF5F5F66);
  @override Color get textMuted     => const Color(0xFF8E8E96);
  @override Color get textDisabled  => const Color(0xFFC0C0C8);

  @override Color get coupon  => const Color(0xFFE64463);
  @override Color get reward  => const Color(0xFF8BD13A);
  @override Color get premium => const Color(0xFFE6B800);
  @override Color get map     => const Color(0xFF3D8DDB);
  @override Color get streak  => const Color(0xFFA85FD9);

  @override Color get couponInk  => Colors.white;
  @override Color get rewardInk  => const Color(0xFF0A1A00);
  @override Color get premiumInk => const Color(0xFF1A1300);

  @override Color get success  => reward;
  @override Color get warning  => premium;
  @override Color get error    => coupon;
  @override Color get hairline => const Color(0x1A000000);
  @override Color get overlay  => const Color(0x66000000);
}

/// Widget 에서 짧게 쓰기 위한 확장.
extension PaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).brightness == Brightness.dark
          ? const AppPaletteDark()
          : const AppPaletteLight();
}
