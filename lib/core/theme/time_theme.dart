import 'package:flutter/material.dart';
import '../localization/language_config.dart';

enum TimeOfDayPeriod { morning, day, evening, night }

/// v5 마이그레이션:
/// 시간대별 색 변동 → 단일 v5 wallet 톤으로 통일.
/// 시간대 enum 자체는 여전히 외부에서 사용되므로 유지.
class TimeTheme {
  final TimeOfDayPeriod period;
  final Color bgDeep;
  final Color bgCard;
  final Color bgSurface;
  final Color accent;
  final String emoji;
  final String label;
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
    if (h >= 7 && h < 19) return TimeOfDayPeriod.day;
    return TimeOfDayPeriod.night;
  }

  static TimeTheme forCountry(String country) =>
      forPeriod(getPeriodForCountry(country));

  /// v5: 모든 period 가 동일한 dark wallet 톤 반환.
  /// 시간대별 emoji/label 만 유지 (헤더 표시용).
  static TimeTheme forPeriod(TimeOfDayPeriod period) {
    final base = _base(period);
    return TimeTheme(
      period: period,
      bgDeep: const Color(0xFF000000),
      bgCard: const Color(0xFF141417),
      bgSurface: const Color(0xFF1C1C1F),
      accent: const Color(0xFFFFD60A),
      emoji: base.$1,
      label: base.$2,
      gradientTop: const Color(0xFF000000),
      gradientMid: const Color(0xFF050507),
      gradientBottom: const Color(0xFF0A0A0C),
    );
  }

  static (String, String) _base(TimeOfDayPeriod p) {
    switch (p) {
      case TimeOfDayPeriod.morning:
        return ('🌅', 'Dawn');
      case TimeOfDayPeriod.day:
        return ('☀️', 'Day');
      case TimeOfDayPeriod.evening:
        return ('🌆', 'Evening');
      case TimeOfDayPeriod.night:
        return ('🌙', 'Night');
    }
  }
}
