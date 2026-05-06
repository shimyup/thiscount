import 'dart:math';

import '../../state/app_state.dart';

/// Quick-pick strategies for first-time writers who don't know where to
/// send their letter. Each strategy returns a country map
/// ({name, flag, lat, lng}) or null if no candidate matches — the UI
/// should fall back to a plain random pick in that case.

enum QuickPickKind { oppositeSide, sunrise, unvisitedContinent }

/// Country → continent mapping for the fallback country list. Not exhaustive
/// for the full 198-country GeocodingService set, but covers the 50 most
/// common. Countries not in the map are treated as "unknown continent" and
/// included only as a last-resort fallback.
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

Map<String, String>? _pickFromFiltered(
  Iterable<Map<String, String>> candidates, {
  String? excludeCountry,
}) {
  final pool = candidates
      .where((c) => c['name'] != excludeCountry)
      .where((c) => c['lat'] != null && c['lng'] != null)
      .toList();
  if (pool.isEmpty) return null;
  return pool[Random().nextInt(pool.length)];
}

/// Countries whose longitude is roughly opposite (150°–210° away) from
/// `userLng`. Returns null if none match — the caller should fall back
/// to plain random.
Map<String, String>? pickOppositeSideCountry({
  required double userLng,
  String? excludeCountry,
}) {
  final candidates = AppState.countries.where((c) {
    final lng = double.tryParse(c['lng'] ?? '');
    if (lng == null) return false;
    var diff = (lng - userLng).abs();
    if (diff > 180) diff = 360 - diff;
    return diff >= 150 && diff <= 180;
  });
  return _pickFromFiltered(candidates, excludeCountry: excludeCountry);
}

/// Countries whose *current* local hour is in 6–10 — "a place waking up
/// now". Local hour is approximated as (UTC hour + lng/15) % 24.
Map<String, String>? pickSunriseCountry({
  DateTime? now,
  String? excludeCountry,
}) {
  final t = (now ?? DateTime.now()).toUtc();
  final candidates = AppState.countries.where((c) {
    final lng = double.tryParse(c['lng'] ?? '');
    if (lng == null) return false;
    final offset = (lng / 15).round();
    var h = (t.hour + offset) % 24;
    if (h < 0) h += 24;
    return h >= 6 && h <= 10;
  });
  return _pickFromFiltered(candidates, excludeCountry: excludeCountry);
}

/// Picks a country from a continent the user has NOT sent to yet. Uses
/// the passed set of already-sent country names (typically drawn from
/// the weekly challenge tracker or sent-letter history). Falls back to
/// null if every continent has been touched or mapping is incomplete.
Map<String, String>? pickUnvisitedContinentCountry({
  required Set<String> sentCountries,
  String? excludeCountry,
}) {
  final visitedContinents = sentCountries
      .map((c) => _continentByCountry[c])
      .whereType<String>()
      .toSet();
  final candidates = AppState.countries.where((c) {
    final cont = _continentByCountry[c['name']];
    if (cont == null) return false;
    return !visitedContinents.contains(cont);
  });
  return _pickFromFiltered(candidates, excludeCountry: excludeCountry);
}
