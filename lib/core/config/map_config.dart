/// 지도 설정 & API 키 관리
///
/// ─────────────────────────────────────────────────────────────
/// 국가명·도시명을 사용자 언어로 표시하려면 Stadia Maps API 키 필요
///
/// 무료 키 발급 (200,000 타일/월 무료):
///   1. https://client.stadiamaps.com/signup/ 에서 회원가입
///   2. Dashboard → API Keys → Create API Key
///   3. 빌드 시 --dart-define=STADIA_MAPS_API_KEY=... 로 주입
///
/// API 키가 없으면: CartoDB Voyager 타일 사용 (각 국가 현지어 표시)
///   예) 한국→한글, 일본→일본어, 중국→중국어 ... 단, 사용자 언어로 통일 불가
///
/// API 키가 있으면: Stadia Maps alidade_smooth 사용 (사용자 설정 언어로 통일)
///   예) 한국어 설정 → 미국=미국, 일본=일본, 중국=중국 모두 한글로 표시
/// ─────────────────────────────────────────────────────────────
abstract class MapConfig {
  // Stadia Maps API 키 (절대 소스코드에 하드코딩하지 않음)
  // 예: flutter run --dart-define=STADIA_MAPS_API_KEY=xxxx
  static const String stadiaApiKey = String.fromEnvironment(
    'STADIA_MAPS_API_KEY',
    defaultValue: '',
  );

  // ── 내부 유효성 검사 ──────────────────────────────────────────────────────
  static bool get hasValidStadiaKey {
    final key = stadiaApiKey.trim();
    if (key.isEmpty) return false;
    if (key.contains('your_') || key.contains('placeholder')) return false;
    return key.length >= 20;
  }

  // ── 국가 기반 지도 언어 힌트 ────────────────────────────────────────────────
  static const Map<String, String> _countryLangHints = {
    '대한민국': 'ko',
    '일본': 'ja',
    '미국': 'en',
    '프랑스': 'fr',
    '영국': 'en',
    '독일': 'de',
    '이탈리아': 'it',
    '스페인': 'es',
    '브라질': 'pt',
    '인도': 'hi',
    '중국': 'zh',
    '호주': 'en',
    '캐나다': 'en',
    '멕시코': 'es',
    '아르헨티나': 'es',
    '러시아': 'ru',
    '터키': 'tr',
    '이집트': 'ar',
    '남아프리카': 'en',
    '태국': 'th',
    '네덜란드': 'nl',
    '스웨덴': 'sv',
    '노르웨이': 'no',
    '포르투갈': 'pt',
    '인도네시아': 'id',
    '말레이시아': 'ms',
    '싱가포르': 'en',
    '뉴질랜드': 'en',
    '필리핀': 'en',
    '베트남': 'vi',
    '우크라이나': 'uk',
    '폴란드': 'pl',
    '체코': 'cs',
    '헝가리': 'hu',
    '그리스': 'el',
    '이스라엘': 'he',
    '사우디아라비아': 'ar',
    'UAE': 'ar',
    '파키스탄': 'ur',
    '방글라데시': 'bn',
    '나이지리아': 'en',
    '케냐': 'en',
    '에티오피아': 'am',
    '모로코': 'ar',
    '콜롬비아': 'es',
    '페루': 'es',
    '칠레': 'es',
    '덴마크': 'da',
    '핀란드': 'fi',
    '오스트리아': 'de',
  };

  static const Map<String, String> _langDisplayName = {
    'ko': '한국어',
    'ja': '일본어',
    'zh': '중국어',
    'en': '영어',
    'fr': '프랑스어',
    'de': '독일어',
    'es': '스페인어',
    'pt': '포르투갈어',
    'it': '이탈리아어',
    'ru': '러시아어',
    'ar': '아랍어',
    'hi': '힌디어',
    'th': '태국어',
    'tr': '터키어',
    'nl': '네덜란드어',
    'pl': '폴란드어',
    'local': '현지어',
  };

  static String toMapLang(String langCode) {
    final normalized = langCode.trim().toLowerCase();
    if (normalized.isEmpty) return 'local';
    final primary = normalized.split(RegExp(r'[-_]')).first;
    return RegExp(r'^[a-z]{2}$').hasMatch(primary) ? primary : 'local';
  }

  static String resolveMapLanguage({
    required String country,
    String? appLanguageCode,
  }) {
    final byApp = toMapLang(appLanguageCode ?? '');
    if (byApp != 'local') return byApp;

    final byCountry = _countryLangHints[country];
    if (byCountry != null) return toMapLang(byCountry);
    return 'en';
  }

  static String mapLanguageLabel(String mapLangCode) =>
      _langDisplayName[mapLangCode] ?? mapLangCode.toUpperCase();

  static bool get isUnifiedLanguageMode => hasValidStadiaKey;

  static String get tileProviderLabel =>
      hasValidStadiaKey ? 'Stadia Maps' : 'CartoDB';

  // ── 타일 URL 생성 ─────────────────────────────────────────────────────────
  /// 기반 타일 URL
  ///   Stadia (API 키 있을 때): 사용자 언어로 국가명 표시 (ko → 미국, 일본 …)
  ///   CartoDB 폴백 (API 키 없을 때): 지역 현지어 표시 (무료, 인증 불필요)
  static String tileUrl(String langCode, {required bool darkMode}) {
    if (hasValidStadiaKey) {
      final lang = toMapLang(langCode);
      final style = darkMode ? 'alidade_smooth_dark' : 'alidade_smooth';
      return 'https://tiles.stadiamaps.com/tiles/$style/{z}/{x}/{y}.png'
          '?api_key=$stadiaApiKey&language=$lang';
    }
    // API 키 없음 → CartoDB (인증 불필요, 무료)
    // 주간: Voyager (현지어 레이블 포함)
    // 야간: dark_nolabels + voyager_only_labels 오버레이
    return darkMode
        ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  }

  /// 야간 현지어 레이블 오버레이 (CartoDB 폴백 + 다크모드일 때만)
  /// Stadia 사용 시에는 null (단일 레이어에 레이블 포함)
  static String? labelOverlayUrl({required bool darkMode}) {
    if (hasValidStadiaKey) return null;
    if (!darkMode) return null;
    return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager_only_labels/{z}/{x}/{y}.png';
  }

  /// TileLayer subdomains
  /// Stadia: 서브도메인 불필요 / CartoDB: a·b·c·d 필요
  static List<String> get subdomains =>
      hasValidStadiaKey ? const [] : const ['a', 'b', 'c', 'd'];
}
