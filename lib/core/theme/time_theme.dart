import 'package:flutter/material.dart';
import '../localization/language_config.dart';

enum TimeOfDayPeriod { morning, day, evening, night }

class TimeTheme {
  final TimeOfDayPeriod period;
  final Color bgDeep;
  final Color bgCard;
  final Color bgSurface;
  final Color accent;
  final String emoji;
  final String label;
  // 하늘 그라디언트 (상단 → 하단)
  final Color gradientTop;
  final Color gradientMid;
  final Color gradientBottom;

  const TimeTheme({
    required this.period,
    required this.bgDeep,
    required this.bgCard,
    required this.bgSurface,
    required this.accent,
    required this.emoji,
    required this.label,
    required this.gradientTop,
    required this.gradientMid,
    required this.gradientBottom,
  });

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0.0, 0.45, 1.0],
    colors: [gradientTop, gradientMid, gradientBottom],
  );

  static TimeOfDayPeriod getPeriodForCountry(String country) {
    final offset = LanguageConfig.getTimezoneOffset(country);
    final utcNow = DateTime.now().toUtc();
    final localHour = (utcNow.hour + offset).floor() % 24;
    final h = localHour < 0 ? localHour + 24 : localHour;
    // 낮/밤 두 가지만 적용 (오전 7시~오후 7시는 낮, 나머지는 밤)
    if (h >= 7 && h < 19) return TimeOfDayPeriod.day;
    return TimeOfDayPeriod.night;
  }

  static TimeTheme forCountry(String country) =>
      forPeriod(getPeriodForCountry(country));

  static TimeTheme forPeriod(TimeOfDayPeriod period) {
    switch (period) {
      // ── 🌅 새벽 (05:00-09:00) ─ 보라빛 새벽, 따뜻한 오렌지 노을 ────────────
      case TimeOfDayPeriod.morning:
        return const TimeTheme(
          period: TimeOfDayPeriod.morning,
          bgDeep: Color(0xFF16093A),
          bgCard: Color(0xFF211550),
          bgSurface: Color(0xFF2C2068),
          accent: Color(0xFFFFB347),
          gradientTop: Color(0xFF3D1060), // 짙은 보라
          gradientMid: Color(0xFF6B2E52), // 로즈 핑크
          gradientBottom: Color(0xFF0D0E28), // 어두운 남색
          emoji: '🌅',
          label: '새벽',
        );

      // ── ☀️ 낮 (09:00-18:00) ─ 맑은 하늘, 깊은 바다 ──────────────────────────
      case TimeOfDayPeriod.day:
        return const TimeTheme(
          period: TimeOfDayPeriod.day,
          bgDeep: Color(0xFF04213E),
          bgCard: Color(0xFF072E58),
          bgSurface: Color(0xFF0B3C72),
          accent: Color(0xFF38BEFF),
          gradientTop: Color(0xFF1565C0), // 파란 하늘
          gradientMid: Color(0xFF0A3D7A), // 깊은 파랑
          gradientBottom: Color(0xFF021526), // 심해
          emoji: '☀️',
          label: '낮',
        );

      // ── 🌆 저녁 (18:00-21:00) ─ 선셋 오렌지-레드 ──────────────────────────────
      case TimeOfDayPeriod.evening:
        return const TimeTheme(
          period: TimeOfDayPeriod.evening,
          bgDeep: Color(0xFF1E0608),
          bgCard: Color(0xFF2E0E14),
          bgSurface: Color(0xFF3E1620),
          accent: Color(0xFFFF6B35),
          gradientTop: Color(0xFF7B1E18), // 선셋 레드
          gradientMid: Color(0xFF4A1020), // 어두운 로즈
          gradientBottom: Color(0xFF0A0408), // 거의 블랙
          emoji: '🌆',
          label: '저녁',
        );

      // ── 🌙 밤 (21:00-05:00) ─ 트루 다크모드 ──────────────────────────────────
      case TimeOfDayPeriod.night:
        return const TimeTheme(
          period: TimeOfDayPeriod.night,
          bgDeep: Color(0xFF0A0A0A),
          bgCard: Color(0xFF141414),
          bgSurface: Color(0xFF1E1E1E),
          accent: Color(0xFFB8B8B8),
          gradientTop: Color(0xFF111111),
          gradientMid: Color(0xFF0A0A0A),
          gradientBottom: Color(0xFF050505),
          emoji: '🌙',
          label: '밤',
        );
    }
  }
}
