import 'dart:math';

import '../../state/app_state.dart';

/// Day-of-week theme — a light, rotating "where to write today" hint that
/// gives users a weekly rhythm without forcing a challenge. Appears as a
/// one-line banner on the compose screen; tapping it applies a random
/// country from the themed region.
///
/// Rotation:
///   Mon · East Asia
///   Tue · Europe
///   Wed · Africa
///   Thu · South America
///   Fri · Oceania
///   Sat · North America
///   Sun · Middle East

enum DayTheme { eastAsia, europe, africa, southAmerica, oceania, northAmerica, middleEast }

const Map<int, DayTheme> _themeByWeekday = {
  DateTime.monday: DayTheme.eastAsia,
  DateTime.tuesday: DayTheme.europe,
  DateTime.wednesday: DayTheme.africa,
  DateTime.thursday: DayTheme.southAmerica,
  DateTime.friday: DayTheme.oceania,
  DateTime.saturday: DayTheme.northAmerica,
  DateTime.sunday: DayTheme.middleEast,
};

const Map<DayTheme, List<String>> _countriesByTheme = {
  DayTheme.eastAsia: [
    '대한민국', '일본', '중국', '베트남', '태국',
    '인도네시아', '말레이시아', '필리핀', '싱가포르',
  ],
  DayTheme.europe: [
    '프랑스', '영국', '독일', '이탈리아', '스페인',
    '네덜란드', '스웨덴', '노르웨이', '포르투갈',
    '폴란드', '체코', '헝가리', '그리스', '덴마크',
    '핀란드', '오스트리아',
  ],
  DayTheme.africa: [
    '이집트', '남아프리카', '나이지리아', '케냐',
    '에티오피아', '모로코',
  ],
  DayTheme.southAmerica: [
    '브라질', '아르헨티나', '콜롬비아', '페루', '칠레',
  ],
  DayTheme.oceania: [
    '호주', '뉴질랜드',
  ],
  DayTheme.northAmerica: [
    '미국', '캐나다', '멕시코',
  ],
  DayTheme.middleEast: [
    '사우디아라비아', 'UAE', '터키', '이스라엘',
  ],
};

DayTheme currentDayTheme({DateTime? now}) {
  final t = now ?? DateTime.now();
  return _themeByWeekday[t.weekday] ?? DayTheme.europe;
}

/// Picks a random country from the current day's theme region. Falls back
/// to null when the pool is exhausted after exclusion — caller should use
/// AppState.randomDestination then.
Map<String, String>? pickDayThemeCountry({
  DateTime? now,
  String? excludeCountry,
}) {
  final theme = currentDayTheme(now: now);
  final names = _countriesByTheme[theme] ?? const [];
  final pool = AppState.countries
      .where((c) => names.contains(c['name']))
      .where((c) => c['name'] != excludeCountry)
      .toList();
  if (pool.isEmpty) return null;
  return pool[Random().nextInt(pool.length)];
}
