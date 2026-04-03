import 'package:flutter/material.dart';

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
          periodLabel: '밤',
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
  static const Color bgDeep = Color(0xFF070B14);
  static const Color bgCard = Color(0xFF111827);
  static const Color bgSurface = Color(0xFF1A2235);
  static const Color bgElevated = Color(0xFF222E45);

  // Accent
  static const Color gold = Color(0xFFF0C35A);
  static const Color goldLight = Color(0xFFFBE08A);
  static const Color goldDark = Color(0xFFB8922A);
  static const Color teal = Color(0xFF2DD4BF);
  static const Color tealDark = Color(0xFF0D9488);

  // Text
  static const Color textPrimary = Color(0xFFE8E0D0);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Letter glow colors
  static const Color letterGlow = Color(0xFFF0C35A);
  static const Color letterGlowDelivering = Color(0xFF2DD4BF);
  static const Color letterGlowRead = Color(0xFF6B7280);

  // Status colors
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);

  // Map overlay
  static const Color mapOverlay = Color(0x99070B14);
  static const Color nearbyRadius = Color(0x2AF0C35A);
  static const Color nearbyBorder = Color(0x66F0C35A);
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
          side: const BorderSide(color: Color(0xFF1F2D44), width: 1),
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
          borderSide: const BorderSide(color: Color(0xFF1F2D44)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2D44)),
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
        color: Color(0xFF1F2D44),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      useMaterial3: true,
    );
  }
}
