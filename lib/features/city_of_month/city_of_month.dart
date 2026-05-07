/// "이번 달의 도시" 큐레이션 데이터.
///
/// 마케팅 로드맵의 Phase 3 아이템:
/// 매달 1개 도시를 큐레이션해 그 도시로 편지 보낼 때 테마 경험 제공.
/// 관광청·문화원 제휴·콘텐츠 마케팅 훅으로 확장 가능.
///
/// 현재는 정적 매핑. 향후 Firestore `featured_cities` 컬렉션으로 전환해
/// 원격 관리 가능하게 할 예정.
class CityOfMonth {
  CityOfMonth._();

  /// 월(1~12) → 큐레이션 도시 데이터.
  /// 북반구 계절 · 문화 이벤트 중심으로 선정.
  static const Map<int, CityMonthData> _byMonth = {
    1: CityMonthData(
      month: 1,
      cityName: '홋카이도',
      country: '일본',
      countryFlag: '🇯🇵',
      themeEmoji: '❄️',
      headline: '겨울의 설원에서 온 메시지',
      description: '눈이 소리 없이 내리는 도시로, 따뜻한 한 줄을 보내세요',
      accentColor: 0xFF9FC5E8, // 연한 하늘색
    ),
    2: CityMonthData(
      month: 2,
      cityName: '파리',
      country: '프랑스',
      countryFlag: '🇫🇷',
      themeEmoji: '🌹',
      headline: '발렌타인의 도시',
      description: '사랑과 사연의 도시, 파리로 2월의 마음을 전하세요',
      accentColor: 0xFFE06C75,
    ),
    3: CityMonthData(
      month: 3,
      cityName: '제주',
      country: '대한민국',
      countryFlag: '🇰🇷',
      themeEmoji: '🌸',
      headline: '봄 바람이 먼저 오는 섬',
      description: '유채꽃이 피기 시작한 제주로 새 계절 인사를 보내세요',
      accentColor: 0xFFFFB6A3,
    ),
    4: CityMonthData(
      month: 4,
      cityName: '교토',
      country: '일본',
      countryFlag: '🇯🇵',
      themeEmoji: '🌸',
      headline: '벚꽃의 전성기',
      description: '하늘을 뒤덮은 꽃잎 아래, 계절의 메시지를 보내세요',
      accentColor: 0xFFFFB6C1,
    ),
    5: CityMonthData(
      month: 5,
      cityName: '마라케시',
      country: '모로코',
      countryFlag: '🇲🇦',
      themeEmoji: '🌶️',
      headline: '향신료 시장의 붉은 도시',
      description: '사하라의 입구에서 여행자의 메시지를 띄워보세요',
      accentColor: 0xFFD57247,
    ),
    6: CityMonthData(
      month: 6,
      cityName: '이스탄불',
      country: '터키',
      countryFlag: '🇹🇷',
      themeEmoji: '🕌',
      headline: '두 대륙이 만나는 곳',
      description: '유럽과 아시아의 경계에서 인연의 메시지를 보내세요',
      accentColor: 0xFFD4A44B,
    ),
    7: CityMonthData(
      month: 7,
      cityName: '산토리니',
      country: '그리스',
      countryFlag: '🇬🇷',
      themeEmoji: '🌊',
      headline: '에게해의 하얀 집',
      description: '푸른 바다와 하얀 벽 사이로 여름의 메시지를',
      accentColor: 0xFF6BB6FF,
    ),
    8: CityMonthData(
      month: 8,
      cityName: '리우데자네이루',
      country: '브라질',
      countryFlag: '🇧🇷',
      themeEmoji: '🎶',
      headline: '삼바의 도시',
      description: '해변과 리듬이 있는 리우로 활기찬 안부를 전하세요',
      accentColor: 0xFFFFA94D,
    ),
    9: CityMonthData(
      month: 9,
      cityName: '뉴욕',
      country: '미국',
      countryFlag: '🇺🇸',
      themeEmoji: '🍂',
      headline: '가을이 가장 먼저 오는 도시',
      description: '센트럴파크의 낙엽 위로 메시지를 흩뿌려보세요',
      accentColor: 0xFFCC8855,
    ),
    10: CityMonthData(
      month: 10,
      cityName: '부다페스트',
      country: '헝가리',
      countryFlag: '🇭🇺',
      themeEmoji: '🍷',
      headline: '도나우강의 노을',
      description: '야경이 가장 아름다운 달, 가을 메시지를 보내세요',
      accentColor: 0xFFC9805A,
    ),
    11: CityMonthData(
      month: 11,
      cityName: '카이로',
      country: '이집트',
      countryFlag: '🇪🇬',
      themeEmoji: '🏜️',
      headline: '사막 너머의 고대',
      description: '피라미드 너머로 4000년의 메시지를 보내세요',
      accentColor: 0xFFD4A44B,
    ),
    12: CityMonthData(
      month: 12,
      cityName: '레이캬비크',
      country: '아이슬란드',
      countryFlag: '🇮🇸',
      themeEmoji: '✨',
      headline: '오로라가 흐르는 밤',
      description: '북극의 빛 아래, 한 해의 마지막 메시지를 보내세요',
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
  final String country;
  final String countryFlag;
  final String themeEmoji;
  final String headline;
  final String description;
  final int accentColor; // 0xAARRGGBB

  const CityMonthData({
    required this.month,
    required this.cityName,
    required this.country,
    required this.countryFlag,
    required this.themeEmoji,
    required this.headline,
    required this.description,
    required this.accentColor,
  });
}
