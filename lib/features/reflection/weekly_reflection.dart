import '../../models/letter.dart';

/// Weekly reflection stats — a lightweight "Spotify Wrapped for this week"
/// computed on-the-fly from the user's sent letters. No persistence of
/// its own; callers pass in the current sent list and receive a snapshot.

// Rough continent bucketing used for the "continents" metric. Keys match
// the Korean country names used throughout AppState. Unknown countries
// fall into 'other' and count once collectively.
const Map<String, String> _continentByCountry = {
  '대한민국': 'asia', '일본': 'asia', '중국': 'asia', '인도': 'asia',
  '태국': 'asia', '베트남': 'asia', '필리핀': 'asia',
  '인도네시아': 'asia', '말레이시아': 'asia', '싱가포르': 'asia',
  '파키스탄': 'asia', '방글라데시': 'asia', '이스라엘': 'asia',
  '사우디아라비아': 'asia', 'UAE': 'asia',
  '미국': 'n_america', '캐나다': 'n_america', '멕시코': 'n_america',
  '브라질': 's_america', '아르헨티나': 's_america',
  '콜롬비아': 's_america', '페루': 's_america', '칠레': 's_america',
  '프랑스': 'europe', '영국': 'europe', '독일': 'europe',
  '이탈리아': 'europe', '스페인': 'europe', '네덜란드': 'europe',
  '스웨덴': 'europe', '노르웨이': 'europe', '포르투갈': 'europe',
  '폴란드': 'europe', '체코': 'europe', '헝가리': 'europe',
  '그리스': 'europe', '덴마크': 'europe', '핀란드': 'europe',
  '오스트리아': 'europe', '러시아': 'europe', '터키': 'europe',
  '우크라이나': 'europe',
  '이집트': 'africa', '남아프리카': 'africa', '나이지리아': 'africa',
  '케냐': 'africa', '에티오피아': 'africa', '모로코': 'africa',
  '호주': 'oceania', '뉴질랜드': 'oceania',
};

class WeeklyReflection {
  final int letterCount;
  final int uniqueCountries;
  final int uniqueContinents;
  final double longestKm;

  const WeeklyReflection({
    required this.letterCount,
    required this.uniqueCountries,
    required this.uniqueContinents,
    required this.longestKm,
  });

  bool get isEmpty => letterCount == 0;

  static WeeklyReflection compute(
    List<Letter> sent, {
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    // ISO week: 월요일 00:00 ~ 다음 월요일 00:00 (유저 로컬 시간 기준)
    final weekStart = _mondayOf(t);
    final inWeek = sent
        .where((l) =>
            !l.sentAt.isBefore(weekStart) &&
            l.sentAt.isBefore(weekStart.add(const Duration(days: 7))))
        .toList();
    final countries = inWeek.map((l) => l.destinationCountry).toSet();
    final continents = countries
        .map((c) => _continentByCountry[c] ?? 'other')
        .toSet();
    double longest = 0;
    for (final l in inWeek) {
      final d = l.originLocation.distanceTo(l.destinationLocation) / 1000.0;
      if (d > longest) longest = d;
    }
    return WeeklyReflection(
      letterCount: inWeek.length,
      uniqueCountries: countries.length,
      uniqueContinents: continents.length,
      longestKm: longest,
    );
  }

  static DateTime _mondayOf(DateTime t) {
    final daysFromMonday = (t.weekday - 1) % 7;
    return DateTime(t.year, t.month, t.day).subtract(
      Duration(days: daysFromMonday),
    );
  }
}
