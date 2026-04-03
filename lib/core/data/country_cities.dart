import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'address_generator.dart';

/// GeoNames 기반 나라별 도시 주소 로더
/// - assets/cities.json (206,000+ 도시, 56개 나라)
/// - 한국: 62,752개 / 미국: 17,317개 등
class CountryCities {
  static Map<String, List<Map<String, dynamic>>>? _cache;

  /// cities.json 로드 (최초 1회만 로드 후 캐싱)
  static Future<void> init() async {
    if (_cache != null) return;
    final raw = await rootBundle.loadString('assets/cities.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _cache = decoded.map(
      (k, v) => MapEntry(
        k,
        (v as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      ),
    );
  }

  /// 나라 이름으로 도시 목록 반환 (필터링 적용)
  static List<Map<String, dynamic>> citiesOf(String countryName) {
    final raw = _cache?[countryName] ?? [];
    return _filterCities(countryName, raw);
  }

  /// 나라별 불필요한 지명 필터링
  static List<Map<String, dynamic>> _filterCities(
    String country,
    List<Map<String, dynamic>> cities,
  ) {
    if (country == '대한민국') {
      // 행정구역 단위: 이 어미들이 있으면 우선 포함 (부산시, 강남구 등)
      const includeEndings = ['시', '구', '군', '읍', '동', '면'];
      // 자연지명 어미 (명백한 지형·지물 명칭만 제외 — '산','천'은 부산·인천에 쓰여 제외 안 함)
      const excludeEndings = [
        '골',
        '말',
        '실',
        '터',
        '봉',
        '재',
        '령',
        '뱅이',
        '쟁이',
        '배기',
        '바위',
        '들',
        '밭',
        '곡',
        '고개',
        '모퉁이',
        '나루',
        '갯',
        '숲',
        '탄',
      ];
      // 특정 단어 포함 지명 제외 (자연지명으로 확실한 것들)
      const excludeContains = ['고개', '바위', '재골'];
      return cities.where((c) {
        final name = c['name'] as String? ?? '';
        // 1글자 제외
        if (name.length <= 1) return false;
        // 영문자 포함 제외 (로마자 지명: Tallang-dong, Yul-li 등)
        if (name.contains(RegExp(r'[A-Za-z]'))) return false;
        // 숫자 포함 제외
        if (name.contains(RegExp(r'[0-9]'))) return false;
        // 행정구역 어미면 무조건 포함
        for (final inc in includeEndings) {
          if (name.endsWith(inc)) return true;
        }
        // 특정 단어 포함이면 제외
        for (final word in excludeContains) {
          if (name.contains(word)) return false;
        }
        // 자연지명 어미면 제외
        for (final ending in excludeEndings) {
          if (name.endsWith(ending)) return false;
        }
        return true;
      }).toList();
    } else {
      // 다른 나라: 1글자 및 로마자 하이픈 지명 제외
      return cities.where((c) {
        final name = c['name'] as String? ?? '';
        if (name.length <= 1) return false;
        // '-dong', '-ri', '-ni' 같은 소규모 로마자 지명 제외
        if (name.contains(RegExp(r'-dong|-ri$|-ni$|-li$|-gun$'))) return false;
        return true;
      }).toList();
    }
  }

  /// 하위 호환용: CountryCities.cities['대한민국'] 형태
  static Map<String, List<Map<String, dynamic>>> get cities {
    return _cache ?? {};
  }

  // ── 경로 표시용 주요 도시 화이트리스트 (국가 → 도시명 Set) ──────────────
  // _nearestCityName에서 이 목록 안에서만 최근접 도시를 찾음
  static const Map<String, Set<String>> _majorCityWhitelist = {
    '대한민국': {
      // 특별·광역시
      '서울', '부산', '인천', '대구', '광주', '대전', '울산', '세종',
      // 경기도
      '수원', '고양', '용인', '성남', '부천', '안산', '안양', '평택',
      '의정부', '화성', '광명', '군포', '하남', '오산', '의왕', '파주',
      '김포', '이천', '안성', '구리', '양주', '여주', '동두천', '과천',
      // 강원도
      '춘천', '원주', '강릉', '동해', '태백', '속초', '삼척',
      // 충청북도
      '청주', '충주', '제천',
      // 충청남도
      '천안', '공주', '보령', '아산', '서산', '논산', '계룡', '당진',
      // 전라북도
      '전주', '군산', '익산', '정읍', '남원', '김제',
      // 전라남도
      '목포', '여수', '순천', '나주', '광양',
      // 경상북도
      '포항', '경주', '김천', '안동', '구미', '영주', '영천', '상주', '문경', '경산',
      // 경상남도
      '창원', '진주', '통영', '사천', '김해', '밀양', '거제', '양산',
      // 제주
      '제주', '서귀포',
    },
    '일본': {
      '東京',
      '大阪',
      '名古屋',
      '横浜',
      '福岡',
      '神戸',
      '京都',
      '札幌',
      '仙台',
      '広島',
      '北九州',
      '千葉',
      'さいたま',
      '堺',
      '浜松',
      '熊本',
      '相模原',
      '岡山',
      '静岡',
      '鹿児島',
    },
    '중국': {
      '北京',
      '上海',
      '广州',
      '深圳',
      '成都',
      '杭州',
      '武汉',
      '西安',
      '苏州',
      '南京',
      '天津',
      '重庆',
      '长沙',
      '青岛',
      '宁波',
      '郑州',
    },
    '미국': {
      'New York',
      'Los Angeles',
      'Chicago',
      'Houston',
      'Phoenix',
      'Philadelphia',
      'San Antonio',
      'San Diego',
      'Dallas',
      'San Jose',
      'Austin',
      'Jacksonville',
      'San Francisco',
      'Columbus',
      'Indianapolis',
      'Seattle',
      'Denver',
      'Boston',
      'Portland',
      'Las Vegas',
      'Atlanta',
      'Miami',
      'Minneapolis',
      'Tampa',
      'New Orleans',
      'Cleveland',
    },
  };

  /// 경로 표시용 행정구역명 목록 (시/구/군/읍/동 어미 포함)
  /// 화이트리스트보다 세분화된 행정구역명을 경로 표시에 사용
  static List<Map<String, dynamic>> majorCitiesOf(String country) {
    final all = _cache?[country] ?? [];
    if (all.isEmpty) return citiesOf(country);

    // 행정구역 어미 필터 (시·도·군·읍·동 포함, 자연지명 제외)
    const adminEndings = ['시', '구', '군', '읍', '동'];
    // 화이트리스트 이름이 있으면 우선 포함
    final whitelist = _majorCityWhitelist[country];

    final result = all.where((c) {
      final name = c['name'] as String? ?? '';
      if (name.length <= 1) return false;
      if (name.contains(RegExp(r'[A-Za-z0-9]'))) return false;
      // 화이트리스트에 있으면 포함
      if (whitelist != null && whitelist.contains(name)) return true;
      // 행정구역 어미면 포함
      for (final e in adminEndings) {
        if (name.endsWith(e)) return true;
      }
      return false;
    }).toList();

    return result.isNotEmpty ? result : citiesOf(country);
  }

  /// 도시명 품질 필터 (숫자로 시작, 괄호, 슬래시, 과도하게 긴 이름 제외)
  static bool _isCleanCityName(String name) {
    if (name.isEmpty || name.length > 35) return false;
    if (name.contains('(') || name.contains(')')) return false;
    if (name.contains('/') || name.contains('\\')) return false;
    if (RegExp(r'^\d').hasMatch(name)) return false; // 숫자로 시작
    if (RegExp(r'\d{2,}').hasMatch(name)) return false; // 2자리 이상 연속 숫자
    return true;
  }

  /// 나라에서 랜덤 도시 1개 반환 (사용된 주소 제외, address 필드 포함)
  static Map<String, dynamic>? randomCity(
    String country, {
    Set<String>? usedCityKeys,
    String? languageCode,
  }) {
    final rng = Random();
    // 행정구역 필터 + 전역 품질 필터 적용
    final raw = majorCitiesOf(country);
    final list = raw
        .where((c) => _isCleanCityName(c['name'] as String? ?? ''))
        .toList();
    final pool = list.isNotEmpty ? list : raw;
    if (pool.isEmpty) return null;

    final available = usedCityKeys != null
        ? pool
              .where((c) => !usedCityKeys.contains('${country}_${c['name']}'))
              .toList()
        : pool;

    final base = available.isEmpty
        ? pool[rng.nextInt(pool.length)]
        : available[rng.nextInt(available.length)];

    final cityName = base['name'] as String? ?? '';
    return {
      ...base,
      'address': AddressGenerator.generate(
        country,
        cityName,
        languageCode: languageCode,
      ),
    };
  }

  /// 도시 키 생성
  static String cityKey(String country, String cityName) =>
      '${country}_$cityName';

  /// ±300m 이내 랜덤 오프셋 적용 (실제 주소처럼)
  static Map<String, dynamic> withStreetOffset(Map<String, dynamic> city) {
    final rng = Random();
    const maxDeg = 0.0027; // ≈ 300m
    final lat = (city['lat'] as num).toDouble();
    final lng = (city['lng'] as num).toDouble();
    final cosLat = cos(lat * pi / 180);
    return {
      ...city,
      'lat': lat + (rng.nextDouble() * 2 - 1) * maxDeg,
      'lng':
          lng +
          (rng.nextDouble() * 2 - 1) * maxDeg / (cosLat == 0 ? 1 : cosLat),
    };
  }

  /// 랜덤 도시 + 오프셋 (사용된 주소 제외)
  static Map<String, dynamic>? randomCityWithOffset(
    String country, {
    Set<String>? usedCityKeys,
    String? languageCode,
  }) {
    final base = randomCity(
      country,
      usedCityKeys: usedCityKeys,
      languageCode: languageCode,
    );
    if (base == null) return null;
    return withStreetOffset(base);
  }

  /// 섬 도시 여부 (GeoNames에는 island 플래그 없으므로 이름 기반 판별)
  static bool isIslandCity(String cityName) {
    const islandKeywords = [
      '제주',
      'Jeju',
      '울릉',
      '독도',
      'Hawaii',
      'Okinawa',
      '沖縄',
      'Bali',
      'Jeju-si',
      'Seogwipo',
      '서귀포',
      'Lombok',
      'Flores',
      'Sumatra',
      'Borneo',
      'Sulawesi',
      'Papua',
    ];
    return islandKeywords.any((k) => cityName.contains(k));
  }

  /// 섬 도시 + 공항 여부
  static bool isIslandWithAirport(String cityName) {
    const airportIslands = [
      '제주',
      'Jeju',
      'Hawaii',
      'Okinawa',
      '沖縄',
      'Bali',
      'Jeju-si',
      'Seogwipo',
      '서귀포',
    ];
    return airportIslands.any((k) => cityName.contains(k));
  }

  /// 지원 나라 목록
  static List<String> get supportedCountries => _cache?.keys.toList() ?? [];
}

// ── 전 세계 육지 유효 주소 생성기 ──────────────────────────────────────────────
class LandAddressGenerator {
  static final _rng = Random();

  static const List<_CountryBound> countryBounds = [
    _CountryBound('대한민국', 34.0, 38.5, 126.0, 129.5),
    _CountryBound('일본', 30.5, 45.5, 130.0, 145.5),
    _CountryBound('미국', 25.0, 49.0, -125.0, -66.0),
    _CountryBound('프랑스', 42.0, 51.1, -5.0, 8.5),
    _CountryBound('영국', 50.0, 58.7, -6.0, 2.0),
    _CountryBound('독일', 47.3, 55.0, 6.0, 15.0),
    _CountryBound('이탈리아', 37.0, 47.1, 6.5, 18.5),
    _CountryBound('스페인', 36.0, 43.8, -9.3, 3.3),
    _CountryBound('브라질', -33.5, 5.3, -73.5, -35.0),
    _CountryBound('인도', 8.0, 35.5, 68.0, 97.5),
    _CountryBound('중국', 18.0, 53.5, 73.5, 135.0),
    _CountryBound('호주', -43.5, -10.5, 114.0, 153.5),
    _CountryBound('캐나다', 42.0, 83.0, -141.0, -52.0),
    _CountryBound('멕시코', 14.5, 32.7, -118.0, -86.5),
    _CountryBound('아르헨티나', -55.0, -22.0, -73.5, -53.5),
    _CountryBound('러시아', 41.0, 77.5, 27.0, 180.0),
    _CountryBound('터키', 36.0, 42.1, 26.0, 45.0),
    _CountryBound('이집트', 22.0, 31.7, 25.0, 37.0),
    _CountryBound('태국', 5.5, 20.5, 97.5, 105.6),
    _CountryBound('네덜란드', 50.7, 53.6, 3.3, 7.2),
    _CountryBound('스웨덴', 55.3, 69.0, 10.5, 24.1),
    _CountryBound('포르투갈', 36.9, 42.2, -9.5, -6.1),
    _CountryBound('인도네시아', -8.8, 5.9, 95.0, 141.0),
    _CountryBound('말레이시아', 1.0, 7.3, 100.0, 119.3),
    _CountryBound('싱가포르', 1.2, 1.5, 103.6, 104.0),
    _CountryBound('필리핀', 5.0, 19.5, 117.0, 127.0),
    _CountryBound('베트남', 8.3, 23.4, 102.1, 109.5),
    _CountryBound('폴란드', 49.0, 54.9, 14.1, 24.2),
    _CountryBound('그리스', 34.8, 41.8, 20.0, 28.3),
    _CountryBound('아랍에미리트', 22.6, 26.1, 51.5, 56.4),
    _CountryBound('벨기에', 49.5, 51.5, 2.5, 6.4),
    _CountryBound('노르웨이', 57.9, 71.2, 4.5, 31.1),
    _CountryBound('덴마크', 54.6, 57.7, 8.1, 15.2),
    _CountryBound('핀란드', 59.8, 70.1, 20.0, 31.6),
    _CountryBound('스위스', 45.8, 47.8, 6.0, 10.5),
    _CountryBound('오스트리아', 46.4, 49.0, 9.5, 17.2),
    _CountryBound('루마니아', 43.6, 48.3, 20.3, 30.0),
    _CountryBound('우크라이나', 44.4, 52.4, 22.1, 40.2),
    _CountryBound('콜롬비아', -4.2, 12.4, -79.0, -66.9),
    _CountryBound('페루', -18.4, 0.0, -81.3, -68.7),
    _CountryBound('칠레', -55.9, -17.5, -75.6, -66.4),
    _CountryBound('체코', 48.6, 51.1, 12.1, 18.9),
    _CountryBound('헝가리', 45.7, 48.6, 16.1, 22.9),
    _CountryBound('남아프리카', -34.8, -22.1, 16.5, 32.9),
    _CountryBound('나이지리아', 4.3, 13.9, 3.0, 15.0),
    _CountryBound('이란', 25.1, 39.8, 44.0, 63.3),
    _CountryBound('뉴질랜드', -46.6, -34.4, 166.4, 178.6),
    _CountryBound('파키스탄', 24.0, 37.1, 60.9, 77.8),
    _CountryBound('모로코', 27.7, 35.9, -13.2, -1.1),
    _CountryBound('이스라엘', 29.5, 33.3, 34.3, 35.9),
    _CountryBound('베네수엘라', 0.7, 12.2, -73.4, -60.0),
    _CountryBound('케냐', -4.7, 4.6, 34.0, 41.9),
    _CountryBound('홍콩', 22.1, 22.6, 113.8, 114.5),
    _CountryBound('방글라데시', 20.6, 26.6, 88.0, 92.7),
    _CountryBound('사우디아라비아', 16.4, 32.2, 36.5, 55.7),
    _CountryBound('대만', 22.0, 25.3, 120.0, 122.0),
  ];

  static Map<String, dynamic> generate({
    String? excludeCountry,
    int maxRetries = 10,
  }) {
    final pool = excludeCountry != null
        ? countryBounds.where((b) => b.country != excludeCountry).toList()
        : countryBounds;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final bound = pool[_rng.nextInt(pool.length)];
      final lat =
          bound.minLat + _rng.nextDouble() * (bound.maxLat - bound.minLat);
      final lng =
          bound.minLng + _rng.nextDouble() * (bound.maxLng - bound.minLng);

      final nearest = _findNearestCity(lat, lng, bound.country);
      if (nearest != null) {
        const maxDeg = 0.0045;
        final cosLat = cos(lat * pi / 180);
        return {
          'name': nearest['name'],
          'lat': lat + (_rng.nextDouble() * 2 - 1) * maxDeg,
          'lng':
              lng +
              (_rng.nextDouble() * 2 - 1) * maxDeg / (cosLat == 0 ? 1 : cosLat),
          'country': bound.country,
          'flag': _countryFlag(bound.country),
        };
      }
    }

    // 최대 재시도 초과 → DB에서 직접 랜덤 픽
    final fallbackBound = pool[_rng.nextInt(pool.length)];
    final fallback = CountryCities.randomCityWithOffset(fallbackBound.country);
    if (fallback != null) {
      return {
        ...fallback,
        'country': fallbackBound.country,
        'flag': _countryFlag(fallbackBound.country),
      };
    }
    return {
      'name': '서울 강남구',
      'lat': 37.5172,
      'lng': 127.0473,
      'country': '대한민국',
      'flag': '🇰🇷',
    };
  }

  static Map<String, dynamic>? _findNearestCity(
    double lat,
    double lng,
    String country,
  ) {
    final list = CountryCities.cities[country];
    if (list == null || list.isEmpty) return null;

    Map<String, dynamic>? nearest;
    double minDist = double.infinity;

    for (final city in list) {
      final cLat = (city['lat'] as num).toDouble();
      final cLng = (city['lng'] as num).toDouble();
      final dist = _haversineKm(lat, lng, cLat, cLng);
      if (dist < minDist) {
        minDist = dist;
        nearest = city;
      }
    }
    return minDist <= 200.0 ? nearest : null;
  }

  static double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static String _countryFlag(String country) {
    const flags = {
      '대한민국': '🇰🇷',
      '일본': '🇯🇵',
      '미국': '🇺🇸',
      '프랑스': '🇫🇷',
      '영국': '🇬🇧',
      '독일': '🇩🇪',
      '이탈리아': '🇮🇹',
      '스페인': '🇪🇸',
      '브라질': '🇧🇷',
      '인도': '🇮🇳',
      '중국': '🇨🇳',
      '호주': '🇦🇺',
      '캐나다': '🇨🇦',
      '멕시코': '🇲🇽',
      '아르헨티나': '🇦🇷',
      '러시아': '🇷🇺',
      '터키': '🇹🇷',
      '이집트': '🇪🇬',
      '태국': '🇹🇭',
      '네덜란드': '🇳🇱',
      '스웨덴': '🇸🇪',
      '포르투갈': '🇵🇹',
      '인도네시아': '🇮🇩',
      '말레이시아': '🇲🇾',
      '싱가포르': '🇸🇬',
      '필리핀': '🇵🇭',
      '베트남': '🇻🇳',
      '폴란드': '🇵🇱',
      '그리스': '🇬🇷',
      '아랍에미리트': '🇦🇪',
      '벨기에': '🇧🇪',
      '노르웨이': '🇳🇴',
      '덴마크': '🇩🇰',
      '핀란드': '🇫🇮',
      '스위스': '🇨🇭',
      '오스트리아': '🇦🇹',
      '루마니아': '🇷🇴',
      '우크라이나': '🇺🇦',
      '콜롬비아': '🇨🇴',
      '페루': '🇵🇪',
      '칠레': '🇨🇱',
      '체코': '🇨🇿',
      '헝가리': '🇭🇺',
      '남아프리카': '🇿🇦',
      '나이지리아': '🇳🇬',
      '이란': '🇮🇷',
      '뉴질랜드': '🇳🇿',
      '파키스탄': '🇵🇰',
      '모로코': '🇲🇦',
      '이스라엘': '🇮🇱',
      '베네수엘라': '🇻🇪',
      '케냐': '🇰🇪',
      '홍콩': '🇭🇰',
      '방글라데시': '🇧🇩',
      '사우디아라비아': '🇸🇦',
      '대만': '🇹🇼',
    };
    return flags[country] ?? '🌍';
  }
}

class _CountryBound {
  final String country;
  final double minLat, maxLat, minLng, maxLng;
  const _CountryBound(
    this.country,
    this.minLat,
    this.maxLat,
    this.minLng,
    this.maxLng,
  );
}
