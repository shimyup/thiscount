import 'package:flutter/material.dart';
import 'app_palette.dart';

// ── 시간대별 동적 색상 (ThemeExtension) ──────────────────────────────────────
class AppTimeColors extends ThemeExtension<AppTimeColors> {
  final Color bgDeep;
  final Color bgCard;
  final Color bgSurface;
  final Color accent;
  final String periodEmoji;
  final String periodLabel;
  final Color gradientTop;
  final Color gradientMid;
  final Color gradientBottom;

  const AppTimeColors({
    required this.bgDeep,
    required this.bgCard,
    required this.bgSurface,
    required this.accent,
    required this.periodEmoji,
    required this.periodLabel,
    this.gradientTop = const Color(0xFF060E20),
    this.gradientMid = const Color(0xFF04080F),
    this.gradientBottom = const Color(0xFF020406),
  });

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0.0, 0.45, 1.0],
    colors: [gradientTop, gradientMid, gradientBottom],
  );

  static AppTimeColors of(BuildContext context) {
    return Theme.of(context).extension<AppTimeColors>() ??
        const AppTimeColors(
          bgDeep: Color(0xFF030609),
          bgCard: Color(0xFF09101C),
          bgSurface: Color(0xFF101826),
          accent: Color(0xFF8B65FF),
          periodEmoji: '🌙',
          periodLabel: 'Night',
        );
  }

  @override
  AppTimeColors copyWith({
    Color? bgDeep,
    Color? bgCard,
    Color? bgSurface,
    Color? accent,
    String? periodEmoji,
    String? periodLabel,
    Color? gradientTop,
    Color? gradientMid,
    Color? gradientBottom,
  }) {
    return AppTimeColors(
      bgDeep: bgDeep ?? this.bgDeep,
      bgCard: bgCard ?? this.bgCard,
      bgSurface: bgSurface ?? this.bgSurface,
      accent: accent ?? this.accent,
      periodEmoji: periodEmoji ?? this.periodEmoji,
      periodLabel: periodLabel ?? this.periodLabel,
      gradientTop: gradientTop ?? this.gradientTop,
      gradientMid: gradientMid ?? this.gradientMid,
      gradientBottom: gradientBottom ?? this.gradientBottom,
    );
  }

  @override
  AppTimeColors lerp(ThemeExtension<AppTimeColors>? other, double t) {
    if (other is! AppTimeColors) return this;
    return AppTimeColors(
      bgDeep: Color.lerp(bgDeep, other.bgDeep, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      periodEmoji: t < 0.5 ? periodEmoji : other.periodEmoji,
      periodLabel: t < 0.5 ? periodLabel : other.periodLabel,
      gradientTop: Color.lerp(gradientTop, other.gradientTop, t)!,
      gradientMid: Color.lerp(gradientMid, other.gradientMid, t)!,
      gradientBottom: Color.lerp(gradientBottom, other.gradientBottom, t)!,
    );
  }
}

class AppColors {
  // Background
  static const Color bgDeep = Color(0xFF000000);
  static const Color bgCard = Color(0xFF141417);
  static const Color bgSurface = Color(0xFF1C1C1F);
  static const Color bgElevated = Color(0xFF2A2A2E);

  // Accent
  static const Color gold = Color(0xFFFFD60A);
  static const Color goldLight = Color(0xFFFFE761);
  static const Color goldDark = Color(0xFFB89500);
  static const Color teal = Color(0xFFB8FF5C);
  static const Color tealDark = Color(0xFF7BC93C);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0xFF5A5A5F);

  // Letter glow colors
  static const Color letterGlow = Color(0xFFFFD60A);
  static const Color letterGlowDelivering = Color(0xFFB8FF5C);
  static const Color letterGlowRead = Color(0xFF5A5A5F);

  // Status colors
  static const Color success = Color(0xFFB8FF5C);
  static const Color warning = Color(0xFFFFD60A);
  static const Color error = Color(0xFFFF4D6D);

  // Map overlay
  static const Color mapOverlay = Color(0x99000000);
  static const Color nearbyRadius = Color(0x33FFD60A);
  static const Color nearbyBorder = Color(0x80FFD60A);

  // v5 wallet category colors (직접 참조용)
  static const Color coupon = Color(0xFFFF4D6D);
  static const Color premium = Color(0xFFFFD60A);
  static const Color letter = Color(0xFFB8FF5C);
  static const Color map = Color(0xFF5BA4F6);
  static const Color streak = Color(0xFFC77DFF);
}

/// Build 159: 앱 전역 타이포 스케일.
/// 539 개 분산된 `fontSize` 참조를 수렴시키기 위한 semantic tokens.
/// 기존 값은 유지하되 신규 위젯은 반드시 이 스케일 중 하나를 사용.
///
/// 스케일 (모든 값 `TextStyle` — color 는 호출자가 덮어씀):
///   caption   11 / w500  — 최소 라벨·보조 텍스트
///   small     12 / w600  — 작은 라벨·뱃지
///   body      14 / w500  — 본문 기본
///   bodyBold  14 / w700  — 본문 강조
///   title     16 / w800  — 카드 제목
///   heading   20 / w800  — 섹션 헤더
///   display   26 / w900  — 페이지 타이틀 (수집첩 등)
class AppText {
  AppText._();

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  static const TextStyle small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );
  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );
  static const TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    height: 1.3,
  );
  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    height: 1.25,
  );
  static const TextStyle display = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    height: 1.2,
  );
}

/// Build 159: 간격 토큰 — padding/margin/gap 에 공통 사용.
/// 기존 8/12/14/16/20/28 혼재 → 표준 5단계로 수렴.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;

  // 편의 EdgeInsets 헬퍼.
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  // 수평/수직 개별.
  static const EdgeInsets hSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets hMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets hLg = EdgeInsets.symmetric(horizontal: lg);
}

/// Build 159: 모서리 반경 토큰 — 483 개 분산된 값을 5단계로 수렴.
///   chip    8  — pill·chip·small button
///   button 12  — 일반 button·input field
///   card   16  — card·container
///   sheet  22  — bottom sheet·large modal
///   pill  999  — full-rounded pill
class AppRadius {
  AppRadius._();

  static const double chip = 8;
  static const double button = 12;
  static const double card = 16;
  static const double sheet = 22;
  static const double pill = 999;
}

/// Build 159: 캐노니컬 로딩 인디케이터.
/// 17 개 CircularProgressIndicator 의 색·크기 분산을 일관화 (gold / 2px).
class AppLoading {
  AppLoading._();

  /// 버튼 안·작은 공간용 (16×16, stroke 2).
  static const Widget small = SizedBox(
    width: 16,
    height: 16,
    child: CircularProgressIndicator(
      color: AppColors.gold,
      strokeWidth: 2,
    ),
  );

  /// 화면 중앙 기본 로더 (24×24, stroke 2).
  static const Widget medium = SizedBox(
    width: 24,
    height: 24,
    child: CircularProgressIndicator(
      color: AppColors.gold,
      strokeWidth: 2,
    ),
  );

  /// 전체 화면 로딩 (기본 size, stroke 3).
  static const Widget large = Center(
    child: SizedBox(
      width: 36,
      height: 36,
      child: CircularProgressIndicator(
        color: AppColors.gold,
        strokeWidth: 3,
      ),
    ),
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.teal,
        surface: AppColors.bgCard,
        onPrimary: AppColors.bgDeep,
        onSecondary: AppColors.bgDeep,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
        labelSmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.bgSurface, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.bgDeep,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bgSurface),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bgSurface),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0D1421),
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.bgSurface,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      useMaterial3: true,
    );
  }

  /// Build 283: Light theme — "카페에서 펼친 종이 지갑" 컨셉.
  /// AppPalette (Build 282 PR #12) 의 light 토큰 기반. 실제 활성화는 main.dart
  /// 의 `themeMode: ThemeMode.system` 으로 OS brightness 따라 전환되지만, 본
  /// 빌드에서는 `ThemeMode.dark` 강제 (모든 widget 이 dark 가정 hardcoded).
  ///
  /// Phase 3: widget 들이 `AppColors.*` → `context.palette.*` 로 마이그레이션
  /// 80% 이상 되면 themeMode 를 system 으로 전환해서 light 활성화.
  static ThemeData get lightTheme {
    const p = AppPaletteLight();
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: p.bgCanvas,
      colorScheme: ColorScheme.light(
        primary: p.premium,
        secondary: p.reward,
        surface: p.bgCard,
        onPrimary: p.premiumInk,
        onSecondary: p.rewardInk,
        onSurface: p.textPrimary,
        error: p.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: p.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: p.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: p.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          color: p.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: p.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: p.textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: p.textMuted, fontSize: 12),
      ),
      cardTheme: CardThemeData(
        color: p.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      iconTheme: IconThemeData(color: p.textSecondary),
      dividerTheme: DividerThemeData(color: p.hairline, thickness: 1),
      useMaterial3: true,
    );
  }
}
