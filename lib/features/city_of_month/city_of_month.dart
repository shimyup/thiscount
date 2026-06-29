/// "이번 달의 도시" 큐레이션 데이터.
///
/// 마케팅 로드맵의 Phase 3 아이템:
/// 매달 1개 도시를 큐레이션해 그 도시로 편지 보낼 때 테마 경험 제공.
/// 관광청·문화원 제휴·콘텐츠 마케팅 훅으로 확장 가능.
///
/// 현재는 정적 매핑. 향후 Firestore `featured_cities` 컬렉션으로 전환해
/// 원격 관리 가능하게 할 예정.
///
/// Build 421 (sim-fresh P2): 도시명/국가/헤드라인/설명이 한국어 하드코딩이라
///   비-한국어 사용자에게 한국어가 노출되던 문제 → 영어 필드 + 언어 접근자
///   (`cityNameL`/`countryL`/`headlineL`/`descriptionL`). ko 외에는 영어.
///   주의: `country`(canonical KR 명칭)는 국가 선택 로직 키라 그대로 유지하고,
///   표시 텍스트만 접근자로 현지화한다.
class CityOfMonth {
  CityOfMonth._();

  /// 월(1~12) → 큐레이션 도시 데이터.
  /// 북반구 계절 · 문화 이벤트 중심으로 선정.
  static const Map<int, CityMonthData> _byMonth = {
    1: CityMonthData(
      month: 1,
      cityName: '홋카이도',
      cityNameEn: 'Hokkaido',
      country: '일본',
      countryEn: 'Japan',
      countryFlag: '🇯🇵',
      themeEmoji: '❄️',
      headline: '겨울의 설원에서 온 편지',
      headlineEn: 'A letter from winter snowfields',
      description: '눈이 소리 없이 내리는 도시로, 따뜻한 한 줄을 보내세요',
      descriptionEn:
          'Send a warm line to a city where snow falls silently',
      accentColor: 0xFF9FC5E8, // 연한 하늘색
    ),
    2: CityMonthData(
      month: 2,
      cityName: '파리',
      cityNameEn: 'Paris',
      country: '프랑스',
      countryEn: 'France',
      countryFlag: '🇫🇷',
      themeEmoji: '🌹',
      headline: '발렌타인의 도시',
      headlineEn: 'City of Valentine',
      description: '사랑과 편지의 도시, 파리로 2월의 마음을 전하세요',
      descriptionEn:
          'Send your February heart to Paris, the city of love and letters',
      accentColor: 0xFFE06C75,
    ),
    3: CityMonthData(
      month: 3,
      cityName: '제주',
      cityNameEn: 'Jeju',
      country: '대한민국',
      countryEn: 'Korea',
      countryFlag: '🇰🇷',
      themeEmoji: '🌸',
      headline: '봄 바람이 먼저 오는 섬',
      headlineEn: 'The island where spring arrives first',
      description: '유채꽃이 피기 시작한 제주로 새 계절 인사를 보내세요',
      descriptionEn:
          'Send a new-season greeting to Jeju, where canola flowers bloom',
      accentColor: 0xFFFFB6A3,
    ),
    4: CityMonthData(
      month: 4,
      cityName: '교토',
      cityNameEn: 'Kyoto',
      country: '일본',
      countryEn: 'Japan',
      countryFlag: '🇯🇵',
      themeEmoji: '🌸',
      headline: '벚꽃의 전성기',
      headlineEn: 'Peak of cherry blossoms',
      description: '하늘을 뒤덮은 꽃잎 아래, 계절의 편지를 보내세요',
      descriptionEn: 'Send a seasonal letter beneath petals filling the sky',
      accentColor: 0xFFFFB6C1,
    ),
    5: CityMonthData(
      month: 5,
      cityName: '마라케시',
      cityNameEn: 'Marrakech',
      country: '모로코',
      countryEn: 'Morocco',
      countryFlag: '🇲🇦',
      themeEmoji: '🌶️',
      headline: '향신료 시장의 붉은 도시',
      headlineEn: 'The red city of spice markets',
      description: '사하라의 입구에서 여행자의 편지를 띄워보세요',
      descriptionEn: 'Send a traveler\'s letter from the gateway to the Sahara',
      accentColor: 0xFFD57247,
    ),
    6: CityMonthData(
      month: 6,
      cityName: '이스탄불',
      cityNameEn: 'Istanbul',
      country: '터키',
      countryEn: 'Türkiye',
      countryFlag: '🇹🇷',
      themeEmoji: '🕌',
      headline: '두 대륙이 만나는 곳',
      headlineEn: 'Where two continents meet',
      description: '유럽과 아시아의 경계에서 인연의 편지를 보내세요',
      descriptionEn:
          'Send a letter of connection at the border of Europe and Asia',
      accentColor: 0xFFD4A44B,
    ),
    7: CityMonthData(
      month: 7,
      cityName: '산토리니',
      cityNameEn: 'Santorini',
      country: '그리스',
      countryEn: 'Greece',
      countryFlag: '🇬🇷',
      themeEmoji: '🌊',
      headline: '에게해의 하얀 집',
      headlineEn: 'White houses of the Aegean',
      description: '푸른 바다와 하얀 벽 사이로 여름의 편지를',
      descriptionEn: 'Send a summer letter between blue seas and white walls',
      accentColor: 0xFF6BB6FF,
    ),
    8: CityMonthData(
      month: 8,
      cityName: '리우데자네이루',
      cityNameEn: 'Rio de Janeiro',
      country: '브라질',
      countryEn: 'Brazil',
      countryFlag: '🇧🇷',
      themeEmoji: '🎶',
      headline: '삼바의 도시',
      headlineEn: 'City of samba',
      description: '해변과 리듬이 있는 리우로 활기찬 안부를 전하세요',
      descriptionEn: 'Send a lively hello to Rio, full of beaches and rhythm',
      accentColor: 0xFFFFA94D,
    ),
    9: CityMonthData(
      month: 9,
      cityName: '뉴욕',
      cityNameEn: 'New York',
      country: '미국',
      countryEn: 'USA',
      countryFlag: '🇺🇸',
      themeEmoji: '🍂',
      headline: '가을이 가장 먼저 오는 도시',
      headlineEn: 'Where autumn comes first',
      description: '센트럴파크의 낙엽 위로 편지를 흩뿌려보세요',
      descriptionEn: 'Scatter a letter over the falling leaves of Central Park',
      accentColor: 0xFFCC8855,
    ),
    10: CityMonthData(
      month: 10,
      cityName: '부다페스트',
      cityNameEn: 'Budapest',
      country: '헝가리',
      countryEn: 'Hungary',
      countryFlag: '🇭🇺',
      themeEmoji: '🍷',
      headline: '도나우강의 노을',
      headlineEn: 'Sunset over the Danube',
      description: '야경이 가장 아름다운 달, 가을 편지를 보내세요',
      descriptionEn:
          'Send an autumn letter in the month of the loveliest night views',
      accentColor: 0xFFC9805A,
    ),
    11: CityMonthData(
      month: 11,
      cityName: '카이로',
      cityNameEn: 'Cairo',
      country: '이집트',
      countryEn: 'Egypt',
      countryFlag: '🇪🇬',
      themeEmoji: '🏜️',
      headline: '사막 너머의 고대',
      headlineEn: 'Antiquity beyond the desert',
      description: '피라미드 너머로 4000년의 편지를 보내세요',
      descriptionEn: 'Send a 4,000-year letter beyond the pyramids',
      accentColor: 0xFFD4A44B,
    ),
    12: CityMonthData(
      month: 12,
      cityName: '레이캬비크',
      cityNameEn: 'Reykjavik',
      country: '아이슬란드',
      countryEn: 'Iceland',
      countryFlag: '🇮🇸',
      themeEmoji: '✨',
      headline: '오로라가 흐르는 밤',
      headlineEn: 'Nights of flowing auroras',
      description: '북극의 빛 아래, 한 해의 마지막 편지를 보내세요',
      descriptionEn: 'Send the year\'s last letter under the Arctic lights',
      accentColor: 0xFF9B7FBF,
    ),
  };

  /// 오늘 날짜 기준 "이번 달의 도시" 반환.
  static CityMonthData forThisMonth() {
    return _byMonth[DateTime.now().month]!;
  }

  /// 특정 월의 도시 데이터 (테스트·프리뷰용).
  static CityMonthData forMonth(int month) {
    final data = _byMonth[month];
    if (data != null) return data;
    return _byMonth[1]!;
  }

  /// 12개월 전체 목록 (향후 "다른 달도 미리보기" 화면용).
  static List<CityMonthData> all() =>
      List.unmodifiable(_byMonth.values.toList());
}

/// 월간 큐레이션 도시 정보.
class CityMonthData {
  final int month;
  final String cityName;
  final String cityNameEn;
  final String country;
  final String countryEn;
  final String countryFlag;
  final String themeEmoji;
  final String headline;
  final String headlineEn;
  final String description;
  final String descriptionEn;
  final int accentColor; // 0xAARRGGBB

  const CityMonthData({
    required this.month,
    required this.cityName,
    required this.cityNameEn,
    required this.country,
    required this.countryEn,
    required this.countryFlag,
    required this.themeEmoji,
    required this.headline,
    required this.headlineEn,
    required this.description,
    required this.descriptionEn,
    required this.accentColor,
  });

  // Build 421 (sim-fresh P2): 표시 전용 언어 접근자 — ko 면 한국어, 그 외 영어.
  String cityNameL(String lang) => lang == 'ko' ? cityName : cityNameEn;
  String countryL(String lang) => lang == 'ko' ? country : countryEn;
  String headlineL(String lang) => lang == 'ko' ? headline : headlineEn;
  String descriptionL(String lang) =>
      lang == 'ko' ? description : descriptionEn;
}
