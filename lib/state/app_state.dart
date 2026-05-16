import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../features/progression/user_level.dart';
import '../features/progression/user_progress.dart';
import '../features/welcome/welcome_letter.dart';
import '../models/letter.dart';
import '../models/user_profile.dart';
import '../core/config/app_keys.dart';
import '../core/config/firebase_config.dart';
import '../core/localization/language_config.dart';
import '../core/localization/app_localizations.dart';
import '../core/data/country_cities.dart';
import '../core/services/notification_service.dart';
import '../core/services/feedback_service.dart';
import '../core/services/geocoding_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/firebase_auth_service.dart';
import '../core/services/brand_zone_service.dart';
import '../models/brand_zone.dart';
import '../core/theme/time_theme.dart';
import '../models/direct_message.dart';
import 'package:encrypt/encrypt.dart' as enc;

enum DisplayThemeMode { auto, light, dark }

enum InviteCodeApplyResult {
  success,
  invalid,
  self,
  alreadyUsed,
  serverUnavailable,
  networkError,
}

enum BrandExtraVerificationResult {
  success,
  alreadyProcessed,
  serverUnavailable,
  networkError,
}

// ── 지도에 표시할 실제 회원 타워 데이터 ────────────────────────────────────────
class MapUser {
  final String id;
  final String flag;
  final double lat;
  final double lng;
  final TowerTier tier;
  final int floors;
  final int rank;
  // Build 240: 실제 사용자 레벨 (1~50). receivedCount/sentCount 기반 근사 XP 로
  // 계산 — Firestore 에 km 데이터가 저장되지 않아 정확한 XP 는 불가하지만
  // 마커 라벨 용도엔 충분히 정합. 이전엔 floors(1~15) 를 'Lv N' 으로
  // 잘못 노출해서 실 사용자 레벨과 mismatch 했음.
  final int level;
  final String? username;
  final String? towerName; // 사용자 지정 타워 이름
  final String towerColor; // 타워 커스텀 색상 (hex)
  final String? towerAccentEmoji; // 타워 장식 이모지
  final int towerRoofStyle; // 지붕 스타일
  final int towerWindowStyle; // 창문 스타일

  const MapUser({
    required this.id,
    required this.flag,
    required this.lat,
    required this.lng,
    required this.tier,
    required this.floors,
    required this.rank,
    this.level = 1,
    this.username,
    this.towerName,
    this.towerColor = '#FFD700',
    this.towerAccentEmoji,
    this.towerRoofStyle = 0,
    this.towerWindowStyle = 0,
  });

  MapUser copyWith({int? rank}) => MapUser(
    id: id,
    flag: flag,
    lat: lat,
    lng: lng,
    tier: tier,
    floors: floors,
    rank: rank ?? this.rank,
    level: level,
    username: username,
    towerName: towerName,
    towerColor: towerColor,
    towerAccentEmoji: towerAccentEmoji,
    towerRoofStyle: towerRoofStyle,
    towerWindowStyle: towerWindowStyle,
  );
}

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  // ── 현재 유저 ──────────────────────────────────────────────────────────────
  UserProfile _currentUser = UserProfile(
    id: 'guest',
    username: 'Guest',
    country: '대한민국',
    countryFlag: '🇰🇷',
    latitude: 37.5665,
    longitude: 126.9780,
  );

  UserProfile get currentUser => _currentUser;

  /// Build 271: 푸시 알림 deep link payload 에서 추출한 편지 ID.
  /// 인박스 진입 후 1회 소비되어 해당 편지를 자동 오픈하는 데 사용.
  /// null/빈문자열이면 동작 없음.
  String? pendingDeepLinkLetterId;

  /// Localization helper — uses the current user's language code.
  AppL10n get _l10n => AppL10n.of(_currentUser.languageCode);

  // ── 지도 위 다른 회원 타워 (Firestore 실시간) ──────────────────────────────
  List<MapUser> _mapUsers = [];
  List<MapUser> get mapUsers => List.unmodifiable(_mapUsers);
  DateTime? _lastMapUsersFetchedAt;
  bool _isFetchingMapUsers = false;
  // Build 253: 시스템 시간 조작 감지 플래그. 다음 실행 시 lastSeenAt 보다
  // 1분 이상 과거면 true. 향후 anti-cheat 백엔드 연동 신호.
  bool _clockTamperingDetected = false;
  bool get clockTamperingDetected => _clockTamperingDetected;
  // Build 218: 베타 빌드에서는 30초로 짧게 — 테스터들이 같은 지도에서 서로
  // 빨리 보이도록. 정식 빌드는 10분 유지 (비용/배터리).
  static Duration get _mapUsersMinRefreshInterval =>
      (kDebugMode || !BetaConstants.disableInRelease || !kReleaseMode)
          ? const Duration(seconds: 30)
          : const Duration(minutes: 10);
  static const int _mapUsersPageSize = 100;
  static const int _mapUsersMaxPages = 2;
  static const int _mapUsersMaxCount = 180;

  // ── 지도 위 편지들 ──────────────────────────────────────────────────────────
  final List<Letter> _worldLetters = [];
  List<Letter> get worldLetters => List.unmodifiable(_worldLetters);

  // ── 서버 동기화 타이머 (편지 수신 + 다른 사용자) ──────────────────────────
  //
  // 비용/성능 최적화 설계:
  // 1) 적응형 주기: 로그인 직후 5분간은 30초 주기(새 편지 체감 빠르게),
  //    그 이후엔 90초로 완화. 사용자가 앱을 계속 쓰고 있어도 포그라운드
  //    트래픽이 과하지 않게 설계.
  // 2) 지도 타워 갱신은 편지 수신과 별도 주기 (180초): 타워는 시각적
  //    업데이트라 덜 자주 바꿔도 무방 → 호출 수 3~6배 감소.
  // 3) 백그라운드 진입 시 타이머 정지, 포그라운드 복귀 시 재개
  //    (main isolate wake 수 자체를 줄여 배터리·비용 절감).
  // 4) 델타 싱크: 마지막 동기화 시각(`_lastLetterSyncAt`) 이후 발송된
  //    편지만 가져오도록 서버에서 페이지 크기를 최소화 → 읽기 수 감소.
  //
  // 40K MAU 기준 예상 절감: 기존 30초 단일 주기 ~$1,400/월 →
  //   최적화 후 ~$250~400/월 (70~80% 감소)
  Timer? _syncTimer;            // 편지 수신 주기 타이머
  Timer? _mapSyncTimer;         // 다른 사용자 타워 주기 타이머
  static const Duration _letterSyncFast = Duration(seconds: 30);
  static const Duration _letterSyncSlow = Duration(seconds: 90);
  static const Duration _mapSyncInterval = Duration(seconds: 180);
  static const Duration _fastModeDuration = Duration(minutes: 5);
  DateTime? _syncStartedAt;
  // ignore: unused_field  // TODO: FCM 연동 시 델타 싱크 경계로 활용
  DateTime? _lastLetterSyncAt;
  bool _syncInFlight = false;
  bool _mapSyncInFlight = false;
  bool _syncPaused = false;     // 백그라운드 진입 시 true

  // ── 내 받은 편지함 ──────────────────────────────────────────────────────────
  final List<Letter> _inbox = [];
  List<Letter> get inbox => List.unmodifiable(_inbox);

  // ── 내가 보낸 편지 ──────────────────────────────────────────────────────────
  final List<Letter> _sent = [];
  List<Letter> get sent => List.unmodifiable(_sent);

  // ── 2km 이내 편지 ─────────────────────────────────────────────────────────
  // Build 218: Premium Lv11+ 가 카테고리 선호를 설정하면 매칭 카테고리 편지가
  // 리스트 앞쪽으로 오도록 정렬 부스트 (UI · 알림 · 가장 가까운 편지 추천에서
  // 선호 카테고리 우선 노출).
  List<Letter> get nearbyLetters {
    final list = _worldLetters
        .where((l) => l.status == DeliveryStatus.nearYou)
        .toList();
    final pref = preferredCategory;
    if (pref != null && _currentUser.isPremium && currentLevel >= 11) {
      list.sort((a, b) {
        final aMatch = a.category == pref ? 0 : 1;
        final bMatch = b.category == pref ? 0 : 1;
        return aMatch.compareTo(bMatch);
      });
    }
    return list;
  }

  // ── 카테고리 선호 (Premium Lv11+ 전용) ──────────────────────────────────
  /// 선호 카테고리 잠금 해제 조건 — Brand 가 아니고 Premium Level 11 이상.
  bool get isCategoryPreferenceUnlocked =>
      !_currentUser.isBrand &&
      _currentUser.isPremium &&
      currentLevel >= 11;

  /// 현재 선호 카테고리 (없으면 null).
  LetterCategory? get preferredCategory {
    final key = _currentUser.preferredCategoryKey;
    if (key == null || key.isEmpty) return null;
    return LetterCategoryExt.fromKey(key);
  }

  /// 선호 카테고리 변경. 잠금 해제 조건 미충족 시 false 반환.
  /// `null` 또는 `LetterCategory.general` 전달 = 선호 해제 (랜덤).
  bool setPreferredCategory(LetterCategory? c) {
    if (!isCategoryPreferenceUnlocked) return false;
    if (c == null || c == LetterCategory.general) {
      _currentUser.preferredCategoryKey = null;
    } else {
      _currentUser.preferredCategoryKey = c.key;
    }
    notifyListeners();
    _saveToPrefs();
    _saveUserToFirestore();
    return true;
  }

  // ── 주변 편지 줍기 제한 (무료: 1시간, 프리미엄: 10분, 선착순) ─────────────
  /// 티어별 쿨다운: 프리미엄/브랜드 10분, 무료 60분
  Duration get _nearbyPickupCooldown =>
      (_currentUser.isPremium || _currentUser.isBrand)
      ? const Duration(minutes: 10)
      : const Duration(minutes: 60);

  // ── 등급별 픽업 반경 ──────────────────────────────────────────────────
  // 기본 반경:
  //   무료     200m — 주변을 걸어야 편지가 잡히는 보물찾기 느낌
  //   프리미엄 1km  — 여유 있게 탐험 가능
  //   브랜드   1km  — Premium 과 동일 (줍기에 참여, 발송이 본업)
  //
  // 레벨 보너스 (Build 106):
  //   Free/Premium 은 현재 레벨에서 (level - 1) × 10m 가 기본 반경에 더해진다.
  //   Level 1 = +0m, Level 50 = +490m.
  //     → Free 최대 690m, Premium 최대 1,490m.
  //   Brand 는 레벨 시스템 외 (`currentLevel` 이 항상 0) 이라 보너스 0m.
  //
  // `nearYou` / `deliveredFar` 상태 전환과 픽업 시 거리 검증 모두 이 getter
  // 를 통해 간다.
  double get pickupRadiusMeters {
    if (_currentUser.isBrand) return 1000;
    final base = _currentUser.isPremium ? 1000.0 : 200.0;
    final levelBonus = (currentLevel - 1).clamp(0, 49) * 10.0;
    return base + levelBonus;
  }

  // ── 포인트 (Level 50 이후 초과 XP 누적) ─────────────────────────────────
  // Level 50 도달 XP = (50-1)² × 50 = 120,050. 이후 쌓이는 XP 는 "포인트"
  // 로 환산되어 추후 구독 결제 시 크레딧으로 사용할 수 있도록 적립된다.
  // 환산 비율: 50 XP = 1 point (편지 5회 줍기 ≈ 1 point).
  // 별도 영속 필드 없이 currentXp 에서 파생 — 항상 정합.
  static const int _level50Threshold = 120050;
  static const int _xpPerPoint = 50;

  int get userPoints {
    if (_currentUser.isBrand) return 0;
    final xp = currentXp;
    if (xp <= _level50Threshold) return 0;
    return (xp - _level50Threshold) ~/ _xpPerPoint;
  }

  bool get hasMaxLevel => currentLevel >= 50;

  DateTime? _lastNearbyPickupAt;

  /// 현재 유저가 이미 줍기한 편지 ID 집합 (동일 편지 중복 줍기 방지)
  final Set<String> _myPickedUpLetterIds = {};

  /// 다음 줍기 가능까지 남은 시간 (null = 바로 가능)
  Duration? get nearbyPickupRemainingCooldown {
    if (_lastNearbyPickupAt == null) return null;
    final elapsed = DateTime.now().difference(_lastNearbyPickupAt!);
    if (elapsed >= _nearbyPickupCooldown) return null;
    return _nearbyPickupCooldown - elapsed;
  }

  /// 현재 유저의 쿨다운 시간 (UI 표시용)
  Duration get pickupCooldownDuration => _nearbyPickupCooldown;

  // ── SharedPreferences 암호화 ─────────────────────────────────────────────
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _encKeyName = 'sp_enc_key_v1';
  static Uint8List? _encKey; // 32바이트 XOR 키 (앱 최초 실행 시 생성)

  // ── 편지 교환 잠금 해제 카운터 ────────────────────────────────────────────
  // "3통 보내야 다음 편지 읽기" 체인 룰은 Build 103 의 답장 무제한 정책과
  // 정합성을 맞추기 위해 항상 해제. 값은 통계/표시 목적으로 유지하되 게이트
  // 로직에서는 언제나 true 를 반환.
  int _sentSinceLastUnlock = 0;
  int get sentSinceLastUnlock => _sentSinceLastUnlock;
  bool get canViewNextLetter => true;

  // ── 일일 발송 제한 ────────────────────────────────────────────────────────
  static const int _dailyLimitFree = 3;
  static const int _dailyLimitPremium = 30;
  static const int _dailyLimitBrand = 200;
  static const int _dailyPremiumExpressLimit = 3;
  static const Duration _readLetterRetention = Duration(days: 30);
  static const Duration _unopenedLetterExpiry = Duration(days: 7);

  int _dailySentCount = 0;
  String _dailySentDateKey = _dateKey(DateTime.now());
  int _dailyPremiumExpressSentCount = 0;
  String _dailyPremiumExpressDateKey = _dateKey(DateTime.now());

  // ── 일일 스트릭 (리텐션 후크) ─────────────────────────────────────────
  /// 연속 접속 일수. 매일 앱 진입 시 1 증가, 하루 건너뛰면 1로 리셋.
  /// UI: 프로필·타워 화면에 🔥 N 뱃지로 노출.
  int _currentStreak = 0;
  int _longestStreak = 0;
  String _lastStreakCheckinDate = ''; // yyyy-MM-dd
  bool _streakJustIncreased = false;  // 방금 증가했는지 — UI 알림용

  // ── 스트릭 방어권 (Streak Freeze) ───────────────────────────────────────
  // 하루 놓쳐도 스트릭 1회 구제. 30일마다 1개씩 자동 충전 (최대 1개 보유).
  int _streakFreezeTokens = 0;
  String _streakFreezeLastRefill = ''; // yyyy-MM-dd — 마지막 충전·소비일
  bool _streakJustSaved = false;       // 직전 체크인에서 방어권 소비했는지
  static const int _streakFreezeMax = 1;
  static const int _streakFreezeRefillDays = 30;

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get streakFreezeTokens => _streakFreezeTokens;
  bool get hasCheckedInToday =>
      _lastStreakCheckinDate == _dateKey(DateTime.now());

  /// UI 에서 축하 메시지 1회 띄운 후 소비할 것.
  bool consumeStreakIncreaseFlag() {
    if (!_streakJustIncreased) return false;
    _streakJustIncreased = false;
    return true;
  }

  /// 스트릭 방어권이 방금 사용되었는지 — UI 스낵바용. 1회 소비.
  bool consumeStreakSavedFlag() {
    if (!_streakJustSaved) return false;
    _streakJustSaved = false;
    return true;
  }

  // ── 주간 챌린지 (Weekly Challenge) ──────────────────────────────────────
  /// 이번 주 발송 편지의 목적지 국가 집합.
  /// 현재 챌린지: "이번 주에 3개 이상 다른 국가로 편지 보내기"
  final Set<String> _weeklyChallengeCountries = {};
  String _weeklyChallengeWeekKey = ''; // yyyy-WW
  bool _weeklyChallengeClaimed = false; // 보상 수령 여부
  int _challengeRewardBalance = 0;       // 미청구 보상 카운터 (향후 프리미엄 연동)

  /// 이번 주 주간 챌린지 목표 — 3개 대륙/국가
  int get weeklyChallengeGoal => 3;

  /// 이번 주까지 발송한 서로 다른 목적지 국가 수 (진행도).
  int get weeklyChallengeProgress {
    _rolloverWeeklyChallengeIfNeeded();
    return _weeklyChallengeCountries.length;
  }

  /// 이번 주 챌린지 달성 여부.
  bool get weeklyChallengeAchieved =>
      weeklyChallengeProgress >= weeklyChallengeGoal;

  /// 보상 수령 대기 여부 (완료했고 아직 청구 안 함).
  bool get weeklyChallengeRewardPending =>
      weeklyChallengeAchieved && !_weeklyChallengeClaimed;

  /// 주간 챌린지 보상 수령 처리. UI 에서 "보상 받기" 탭 시 호출.
  /// 반환: 수령 직전 주 번호(UI 축하용). 실패 시 null.
  String? claimWeeklyChallengeReward() {
    if (!weeklyChallengeRewardPending) return null;
    _weeklyChallengeClaimed = true;
    _challengeRewardBalance += 1;
    notifyListeners();
    _saveToPrefs();
    return _weeklyChallengeWeekKey;
  }

  /// 발송 시 호출되어 챌린지 진행도를 갱신.
  /// 이미 같은 국가를 보낸 주에는 무효 (중복 카운트 X).
  void _recordWeeklyChallengeSend(String destinationCountry) {
    if (destinationCountry.isEmpty) return;
    _rolloverWeeklyChallengeIfNeeded();
    if (_weeklyChallengeCountries.add(destinationCountry)) {
      // 새 국가 추가된 경우에만 저장
      notifyListeners();
      _saveToPrefs();
    }
  }

  /// 주 경계를 넘었으면 진행도 초기화.
  void _rolloverWeeklyChallengeIfNeeded() {
    final nowKey = _isoWeekKey(DateTime.now());
    if (_weeklyChallengeWeekKey != nowKey) {
      _weeklyChallengeWeekKey = nowKey;
      _weeklyChallengeCountries.clear();
      _weeklyChallengeClaimed = false;
    }
  }

  /// ISO 주 번호 (예: "2026-W17"). 월요일을 한 주의 시작으로.
  static String _isoWeekKey(DateTime date) {
    // 그레고리력 → ISO 8601 week date
    final thursday = date.add(Duration(days: 4 - (date.weekday)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeek = firstThursday
        .subtract(Duration(days: (firstThursday.weekday - 1)));
    final weekNumber =
        1 + (thursday.difference(firstWeek).inDays / 7).floor();
    return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  // ── 사용자 레벨 (점진적 해금) ───────────────────────────────────────────
  /// 누적 지표에서 계산된 현재 사용자 레벨.
  /// 신규 유저는 newbie → 첫 편지 → beginner → ... → experienced 로 성장.
  UserLevel get userLevel {
    final sent = _currentUser.activityScore.sentCount;
    final received = _currentUser.activityScore.replyCount +
        _currentUser.activityScore.receivedCount;
    if (sent >= 20 || _currentStreak >= 14) return UserLevel.experienced;
    if (sent >= 10) return UserLevel.regular;
    if (sent >= 5 || received >= 1) return UserLevel.casual;
    if (sent >= 1) return UserLevel.beginner;
    return UserLevel.newbie;
  }

  /// 특정 기능이 현재 해금되어 있는지 확인.
  /// UI: `if (state.isFeatureUnlocked(UnlockableFeature.todaysLetter)) ...`
  bool isFeatureUnlocked(UnlockableFeature feature) =>
      FeatureUnlockPolicy.isUnlocked(feature, userLevel);

  /// 직전 레벨 — 레벨업 감지용.
  UserLevel? _previousUserLevel;
  bool _justLeveledUp = false;

  // ── XP / 레벨 1~50 시스템 (Free · Premium 전용) ──────────────────────────
  //
  // Brand 계정은 "공식 발송인(Postmaster)" 으로 레벨 시스템에서 완전히 제외.
  // `currentLevel` getter 에서 Brand 분기로 0 (= 레벨 없음) 을 반환한다.
  //
  // XP 공식 (사용자 지시, `UserProgress.calcXp` 참조):
  //   picked_count * 10
  // + sent_count   * 5
  // + sum_pickup_km * 0.1
  // + sum_sent_km   * 0.05
  //
  // picked_count / sent_count 는 기존 `ActivityScore` 를 재활용. 거리 합계
  // 두 개만 새 누적 필드로 관리하며 SharedPreferences 에 영속화한다.
  double _sumPickupKm = 0.0;
  double _sumSentKm = 0.0;
  int _previousXpLevel = 1;

  double get sumPickupKm => _sumPickupKm;
  double get sumSentKm => _sumSentKm;

  /// 현재 XP — Brand 계정은 0 반환 (레벨 시스템 외).
  int get currentXp {
    if (_currentUser.isBrand) return 0;
    return UserProgress.calcXp(
      pickedCount: _currentUser.activityScore.receivedCount,
      sentCount: _currentUser.activityScore.sentCount,
      sumPickupKm: _sumPickupKm,
      sumSentKm: _sumSentKm,
    );
  }

  /// 현재 레벨. Brand 는 0 (표시는 👑 배지로 대체).
  int get currentLevel {
    if (_currentUser.isBrand) return 0;
    return UserProgress.calcLevel(currentXp);
  }

  /// 다음 레벨 도달까지 남은 XP. 50 레벨 또는 Brand 는 null.
  int? get xpToNextLevel {
    if (_currentUser.isBrand) return null;
    return UserProgress.xpToNextLevel(currentXp);
  }

  /// 현재 레벨 내 진척도 (0.0 ~ 1.0). 진행 바에 사용. Brand 는 1.0.
  double get levelProgress {
    if (_currentUser.isBrand) return 1.0;
    return UserProgress.levelProgress(currentXp);
  }

  /// 레벨 라벨 — UI 에서 직접 이 문자열만 렌더.
  String get levelLabel {
    if (_currentUser.isBrand) return '👑 공식 발송인';
    return xpLevelLabel(currentLevel);
  }

  /// 레벨업 일회성 플래그를 소비. UI 에서 축하 배너 표시 후 호출.
  /// 반환: 방금 달성한 레벨 (레벨업 아니면 null).
  UserLevel? consumeLevelUpFlag() {
    if (!_justLeveledUp) return null;
    _justLeveledUp = false;
    return userLevel;
  }

  /// 레벨 변화 감지 — `sendLetter` 성공, 답장 수신, 체크인, 픽업 등 주요 이벤트
  /// 이후 호출. UserLevel (5단계 호환) 또는 XP 레벨 (1~50) 중 어느 쪽이든
  /// 올랐으면 `_justLeveledUp = true`.
  void _detectLevelUp() {
    // 기존 UserLevel 5단계 진급
    final current = userLevel;
    if (_previousUserLevel != null &&
        current.rank > _previousUserLevel!.rank) {
      _justLeveledUp = true;
    }
    _previousUserLevel = current;
    // XP 기반 1~50 레벨 진급 (Brand 는 currentLevel 이 항상 0 이라 트리거 안 됨)
    final xpLevel = currentLevel;
    if (xpLevel > 0 && xpLevel > _previousXpLevel) {
      _justLeveledUp = true;
      // Build 120: 마일스톤 레벨(2/5/10/25/50) 도달 시 별도 플래그 — UI 에서
      // 축하 모달 트리거용. 단순 레벨업 배너보다 무거운 축하 모먼트.
      if (_milestoneLevels.contains(xpLevel) &&
          !_celebratedMilestones.contains(xpLevel)) {
        _pendingMilestoneLevel = xpLevel;
      }
    }
    _previousXpLevel = xpLevel;
  }

  // ── 레벨 마일스톤 축하 (Build 120, Build 126 재분배) ─────────────────────
  // 레벨 시스템의 게임플레이 상 의미를 느끼게 하는 주요 마디. 한 번만 표시.
  // Build 126: Lv 25–50 간 너무 큰 공백 해소를 위해 {2,5,10,25,50} →
  // {2,5,10,20,35,50} 로 재분배. 마지막 20 → 50 도 공백 크지만 50 은 최종
  // 전설이라 유지.
  static const Set<int> _milestoneLevels = {2, 5, 10, 20, 35, 50};
  int? _pendingMilestoneLevel;
  final Set<int> _celebratedMilestones = {};

  int? get pendingMilestoneLevel => _pendingMilestoneLevel;

  Future<void> acknowledgeMilestone() async {
    final lvl = _pendingMilestoneLevel;
    if (lvl == null) return;
    _pendingMilestoneLevel = null;
    _celebratedMilestones.add(lvl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'celebratedMilestones',
      _celebratedMilestones.map((e) => e.toString()).toList(),
    );
    notifyListeners();
  }

  // ── 헌터 캐릭터 이모지 진화 (Build 122) ──────────────────────────────────
  // 타워/플래그 중심의 정적 마커 → 레벨에 따라 변하는 캐릭터 이모지. 10개
  // 티어(5레벨씩) 에 한 개씩 매핑해 "내 레벨이 올라갈수록 지도에 보이는
  // 내 모습이 달라진다" 는 RPG 식 진화감. 플래그는 보조 정보로 bottom pill
  // 에 합쳐짐.
  //
  // 캐릭터 선정 원칙:
  //   1) 모두 사람·인격체 이모지 (객체·도구 배제 — 도구는 hunter items 슬롯)
  //   2) 스토리 아크 = 초보 → 활동적 → 기술 습득 → 달인 → 전설
  //   3) 단일 코드포인트 사용 (ZWJ sequence 피해 OS 간 호환성)
  static const List<String> _characterEmojisByTier = [
    '🧑',  //  1–4  평범한 사람
    '🚶',  //  5–9  걷기 시작
    '🏃',  // 10–14 달리는 사람
    '🧗',  // 15–19 등반가
    '🕵',  // 20–24 탐정
    '🥷',  // 25–29 닌자
    '🧙',  // 30–34 마법사
    '🦸',  // 35–39 영웅
    '🧝',  // 40–44 요정·엘프
    '👑',  // 45–50 전설의 왕관
  ];

  /// 특정 레벨(1–50)의 캐릭터 이모지. Brand 는 왕관 고정 (레벨 시스템 밖).
  /// 0 이하/범위 밖은 첫 티어 이모지 반환.
  static String characterEmojiForLevel(int level, {bool isBrand = false}) {
    if (isBrand) return '👑';
    if (level <= 0) return _characterEmojisByTier.first;
    final tierIndex = ((level - 1) ~/ 5).clamp(0, _characterEmojisByTier.length - 1);
    return _characterEmojisByTier[tierIndex];
  }

  /// 현재 사용자의 캐릭터 이모지 — UI 에서 바로 쓰도록 getter 제공.
  String get currentCharacterEmoji => characterEmojiForLevel(
        currentLevel,
        isBrand: _currentUser.isBrand,
      );

  /// 전체 티어 진화 목록 — 프로필 설명/가이드 UI 에서 노출 가능.
  static List<String> get characterTierEmojis =>
      List.unmodifiable(_characterEmojisByTier);

  // ── 헌터 아이템 (Build 121) ──────────────────────────────────────────────
  // 타워 층 비주얼을 대체해 "주웠다 = 모았다" 감각을 주는 이모지 아이템. 5개
  // 마일스톤 레벨에 한 개씩 매핑. 지도 아바타 좌상단에 가장 최근 획득 아이템
  // 작게 노출, 프로필 HuntWalletCard 에 전체 슬롯 5칸 나열.
  // Build 126: 5 → 6 슬롯. Lv 25–50 공백을 완화하기 위해 25 → 20 이동 +
  // 35 (⚡) 신규 추가. 마일스톤 세트와 동일한 키 목록 유지.
  static const Map<int, String> _hunterItemEmojis = {
    2: '🎯',  // 조준 — 첫 마일스톤
    5: '🧭',  // 나침반
    10: '🗺', // 보물 지도
    20: '🎒', // 여행자 배낭
    35: '⚡', // 번개 — 중반 마일스톤 (Build 126 신규)
    50: '👑', // 전설의 왕관
  };

  /// 특정 마일스톤 레벨의 아이템 이모지 (정의된 레벨이 아니면 null).
  static String? hunterItemEmoji(int milestoneLevel) =>
      _hunterItemEmojis[milestoneLevel];

  /// 마일스톤 레벨 목록 (정렬된 오름차순) — UI 슬롯 렌더링용.
  static List<int> get hunterMilestoneLevels =>
      _milestoneLevels.toList()..sort();

  /// 현재 사용자가 이미 획득한 헌터 아이템 레벨 목록 (오름차순).
  /// 레벨이 마일스톤 기준 이상이면 아직 축하 모달을 안 봤어도 아이템은 소유.
  List<int> get earnedHunterItemLevels {
    if (_currentUser.isBrand) return const [];
    final lvl = currentLevel;
    return _milestoneLevels.where((m) => lvl >= m).toList()..sort();
  }

  /// 가장 높은 마일스톤의 아이템 이모지 (지도 아바타 뱃지용). 없으면 null.
  String? get latestHunterItemEmoji {
    if (_currentUser.isBrand) return null;
    final earned = earnedHunterItemLevels;
    if (earned.isEmpty) return null;
    return _hunterItemEmojis[earned.last];
  }

  // ── 레터 동행 동물 (Companion) · Build 125 ──────────────────────────────
  // 타워 층 대신 "내 레터와 함께 걷는 동물" 이모지 펫. 특정 레벨 달성 시
  // 해금. 지도 아바타 옆·프로필에 노출. 게임성·캐릭터 애착 강화.
  // Build 126: 18/28/38/48 을 15/25/35/45 로 당겨 Lv 25–45 중반 구간 공백
  // 해소. 다른 시스템(아이템·악세사리) 과 언락 시점이 겹치지 않게 조정.
  static const Map<int, String> _letterCompanions = {
    3: '🐕',  // 강아지 — 첫 동반자
    8: '🐈',  // 고양이
    15: '🦊', // 여우
    25: '🦉', // 부엉이
    35: '🐉', // 드래곤
    45: '🦄', // 유니콘 — 전설
  };

  static String? letterCompanionEmoji(int level) => _letterCompanions[level];
  static List<int> get letterCompanionLevels =>
      _letterCompanions.keys.toList()..sort();

  List<int> get earnedCompanionLevels {
    if (_currentUser.isBrand) return const [];
    final lvl = currentLevel;
    return _letterCompanions.keys.where((m) => lvl >= m).toList()..sort();
  }

  /// 현재 레터가 데리고 다니는 최상위 동반자 (지도 아바타 옆 노출).
  String? get activeCompanionEmoji {
    if (_currentUser.isBrand) return null;
    final earned = earnedCompanionLevels;
    if (earned.isEmpty) return null;
    return _letterCompanions[earned.last];
  }

  // ── 레터 장식·악세사리 · Build 125 ───────────────────────────────────────
  // 내 레터를 꾸미는 악세사리. 레벨 해금 방식. 프로필에 컬렉션 표시.
  static const Map<int, String> _letterAccessories = {
    4: '🎩',   // 실크햇
    12: '🕶',  // 선글라스
    20: '🎀',  // 리본
    30: '💎',  // 보석
    40: '🌈',  // 무지개
    50: '⭐',  // 별
  };

  static String? letterAccessoryEmoji(int level) =>
      _letterAccessories[level];
  static List<int> get letterAccessoryLevels =>
      _letterAccessories.keys.toList()..sort();

  List<int> get earnedAccessoryLevels {
    if (_currentUser.isBrand) return const [];
    final lvl = currentLevel;
    return _letterAccessories.keys.where((m) => lvl >= m).toList()..sort();
  }

  /// 현재 레터가 착용한 최상위 악세사리. 지도 아바타 머리 위에 올릴 수 있음.
  String? get activeAccessoryEmoji {
    if (_currentUser.isBrand) return null;
    final earned = earnedAccessoryLevels;
    if (earned.isEmpty) return null;
    return _letterAccessories[earned.last];
  }

  // ── 레터 생일 · Build 173 ────────────────────────────────────────────────
  // `joinedAt` 기준 매년 같은 월·일 → 레터 생일. 첫 해는 1주년, 두 번째 해는
  // 2주년. 가입 당일도 "태어난 날" 로 인정해 Day 0 축하 가능.
  // Brand 는 제외 (캐릭터 없음).

  /// 오늘이 유저의 레터 생일 (가입 기념일) 인지.
  /// joinedAt 이 오늘과 동일한 month·day 이면 true. 가입 연도 자체는 무관.
  bool get isLetterBirthdayToday {
    if (_currentUser.isBrand) return false;
    final now = DateTime.now();
    final j = _currentUser.joinedAt;
    return j.month == now.month && j.day == now.day;
  }

  /// 가입 후 경과 일수 (캐릭터 "나이" 표시용).
  int get daysSinceJoined {
    final now = DateTime.now();
    return now.difference(_currentUser.joinedAt).inDays;
  }

  /// 가입 후 경과 연도 (기념일 차수, 0 = 가입 첫 해).
  int get letterAgeYears {
    if (_currentUser.isBrand) return 0;
    final now = DateTime.now();
    final j = _currentUser.joinedAt;
    int years = now.year - j.year;
    if (now.month < j.month ||
        (now.month == j.month && now.day < j.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
  }

  /// 다음 레터 생일까지 남은 일수. 생일 당일 = 0.
  int get daysUntilNextBirthday {
    final now = DateTime.now();
    final j = _currentUser.joinedAt;
    var next = DateTime(now.year, j.month, j.day);
    if (next.isBefore(DateTime(now.year, now.month, now.day))) {
      next = DateTime(now.year + 1, j.month, j.day);
    }
    return next.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  // ── Brand 사업자 인증 (Build 127) ───────────────────────────────────────
  // Brand 계정이 진짜 사업자인지 입력·저장·(후속) 관리자 승인. 승인 완료
  // 시점(brandVerifiedAt) 이 찍히면 지도 아바타 플래그 앞에 ✅ 노출.

  bool get isBrandVerified =>
      _currentUser.isBrand && _currentUser.brandVerifiedAt != null;

  /// Brand 인증 정보 제출 — 사업자 번호 · 등록증 URL · 담당자 전화.
  /// 현재는 SharedPreferences 에 저장만. 관리자 승인은 후속 빌드.
  ///
  /// Build 207: `autoApprove=true` 는 베타 기간(`!kReleaseMode` 또는
  /// `BetaConstants.disableInRelease==false`) 에만 동작. 정식 출시 빌드에서
  /// 클라이언트가 자가 승인하지 못하도록 차단. 향후 Cloud Function 으로
  /// `verifyBrandRequest` 를 만들어 관리자 콘솔에서만 승인 가능하게 이전 예정.
  Future<void> submitBrandVerification({
    required String businessRegistrationNumber,
    required String businessRegistrationDocUrl,
    required String businessContactPhone,
    bool autoApprove = false,
  }) async {
    _currentUser.businessRegistrationNumber =
        businessRegistrationNumber.trim();
    _currentUser.businessRegistrationDocUrl =
        businessRegistrationDocUrl.trim();
    _currentUser.businessContactPhone = businessContactPhone.trim();
    final allowAutoApprove = !kReleaseMode || !BetaConstants.disableInRelease;
    if (autoApprove && allowAutoApprove) {
      _currentUser.brandVerifiedAt = DateTime.now();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'brandBusinessNumber',
      _currentUser.businessRegistrationNumber ?? '',
    );
    await prefs.setString(
      'brandRegistrationDocUrl',
      _currentUser.businessRegistrationDocUrl ?? '',
    );
    await prefs.setString(
      'brandContactPhone',
      _currentUser.businessContactPhone ?? '',
    );
    final verifiedAt = _currentUser.brandVerifiedAt;
    if (verifiedAt != null) {
      await prefs.setInt(
        'brandVerifiedAtMs',
        verifiedAt.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove('brandVerifiedAtMs');
    }
    notifyListeners();
  }

  /// 관리자 측에서 인증 승인 (후속 빌드에서 서버 동기화 예정). 현재 로컬.
  Future<void> approveBrandVerification() async {
    if (!_currentUser.isBrand) return;
    _currentUser.brandVerifiedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'brandVerifiedAtMs',
      _currentUser.brandVerifiedAt!.millisecondsSinceEpoch,
    );
    notifyListeners();
  }

  /// 인증 취소 (관리자 검토 후 반려 시).
  Future<void> revokeBrandVerification() async {
    _currentUser.brandVerifiedAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('brandVerifiedAtMs');
    notifyListeners();
  }

  /// Build 242: 가맹점 영입 관심 등록 — 빈 상태에서 일반 사용자가 누른
  /// "사장님이세요?" 시트로부터 호출. Firestore `merchant_interest` 컬렉션에
  /// 도시 + 언어 + 타임스탬프 저장. 운영자가 이 리스트로 closed beta 영업 진행.
  /// 실패 시 throw — 시트 측에서 best-effort 캐치.
  Future<void> recordMerchantInterest({
    required String country,
    required String countryFlag,
    required String languageCode,
  }) async {
    final docId = 'interest_${_currentUser.id}_${DateTime.now().millisecondsSinceEpoch}';
    await FirestoreService.setDocument('merchant_interest/$docId', {
      'userId': _currentUser.id,
      'username': _currentUser.username,
      'country': country,
      'countryFlag': countryFlag,
      'languageCode': languageCode,
      'lat': _currentUser.latitude,
      'lng': _currentUser.longitude,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// 앱 진입 / 첫 액티비티 시 호출. 하루 1회만 실제 증가, 중복 호출 안전.
  /// - 처음 접속: streak = 1
  /// - 어제 접속 → 오늘 재접속: streak++
  /// - 2일 이상 공백 + 방어권 보유 + 공백이 정확히 1일: 방어권 소비, 스트릭 유지
  /// - 그 외 공백: streak = 1
  /// - 오늘 이미 체크인: no-op
  void registerDailyStreakCheckin() {
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    if (_lastStreakCheckinDate == todayKey) {
      return; // 오늘 이미 처리
    }

    _maybeRefillStreakFreeze(today);

    if (_lastStreakCheckinDate.isEmpty) {
      // 첫 접속 — 방어권은 _maybeRefillStreakFreeze가 이미 지급했다
      _currentStreak = 1;
    } else {
      final lastDate = _parseDateKey(_lastStreakCheckinDate);
      final gapDays = lastDate == null
          ? 2
          : _dayDifference(lastDate, today);
      if (gapDays == 1) {
        _currentStreak += 1;
      } else if (gapDays == 2 && _streakFreezeTokens > 0) {
        // 어제 하루 놓침 — 방어권으로 구제
        _streakFreezeTokens -= 1;
        _streakFreezeLastRefill = todayKey;
        _streakJustSaved = true;
        _currentStreak += 1; // 어제 접속한 것처럼 1 증가
      } else {
        _currentStreak = 1; // 2일 이상 공백 또는 토큰 없음 → 리셋
      }
    }

    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }
    _lastStreakCheckinDate = todayKey;
    _streakJustIncreased = true;
    notifyListeners();
    _saveToPrefs();
  }

  void _maybeRefillStreakFreeze(DateTime today) {
    if (_streakFreezeTokens >= _streakFreezeMax) return;
    // 최초 1회 지급 — 신규 유저와 Build 95 이전부터 쓰던 기존 유저(마이그레이션)
    // 모두 여기에서 토큰을 받는다. lastRefill이 비어 있으면 "지금 충전 기준선을
    // 오늘로 설정"한다.
    if (_streakFreezeLastRefill.isEmpty) {
      _streakFreezeTokens = _streakFreezeMax;
      _streakFreezeLastRefill = _dateKey(today);
      return;
    }
    final lastRefill = _parseDateKey(_streakFreezeLastRefill);
    if (lastRefill == null) return;
    final gap = _dayDifference(lastRefill, today);
    if (gap >= _streakFreezeRefillDays) {
      _streakFreezeTokens = _streakFreezeMax;
      _streakFreezeLastRefill = _dateKey(today);
    }
  }

  DateTime? _parseDateKey(String yyyyMMdd) {
    try {
      final parts = yyyyMMdd.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  int _dayDifference(DateTime a, DateTime b) {
    final aDay = DateTime(a.year, a.month, a.day);
    final bDay = DateTime(b.year, b.month, b.day);
    return bDay.difference(aDay).inDays;
  }

  // ── 월간 발송 제한 ────────────────────────────────────────────────────────
  static const int _monthlyLimitFree = 100;
  static const int _monthlyLimitPremium = 500;
  static const int _monthlyLimitBrand = 10000;

  int _monthlySentCount = 0;
  String _monthlyDateKey = _monthKey(DateTime.now());

  // ── DM 쿼터 (프리미엄 전용, DM 10회 = 편지 1통 차감) ──────────────────────
  static const int _dmPerLetterQuota = 10; // DM 몇 회당 편지 1통 차감
  int _pendingDMCount = 0; // 마지막 차감 이후 보낸 DM 수

  // ── 브랜드 추가 구매 월간 발송권 ───────────────────────────────────────────
  int _brandExtraMonthlyQuota = 0;

  // ── 브랜드 정확 좌표 드롭 (ExactDrop) 크레딧 ─────────────────────────────
  // Build 106: 지도에 편지를 정확히 찍어 뿌리는 기능은 유료 애드온으로 전환.
  // 100통 패키지 = 10,000원. 관리자 패널에서 수동 충전 (RevenueCat / 실제
  // 결제 연동은 후속 작업). 크레딧 0 이면 컴포즈 화면에서 "관리자 문의"
  // 다이얼로그로 안내. 1통 발송 시 1 크레딧 차감.
  int _brandExactDropCredits = 0;
  int get brandExactDropCredits => _brandExactDropCredits;
  bool get canUseExactDrop =>
      _currentUser.isBrand && _brandExactDropCredits > 0;

  Future<void> adminGrantExactDropCredits(int amount) async {
    if (amount <= 0) return;
    _brandExactDropCredits += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('brandExactDropCredits', _brandExactDropCredits);
    notifyListeners();
  }

  /// ExactDrop 로 편지 1통을 발송한 후 호출 — 크레딧 차감.
  /// 잔고 부족 시 false 반환 (호출측에서 발송 중단).
  Future<bool> consumeExactDropCredit() async {
    if (_brandExactDropCredits <= 0) return false;
    _brandExactDropCredits--;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('brandExactDropCredits', _brandExactDropCredits);
    notifyListeners();
    return true;
  }

  // ── 🎟 브랜드 홍보 팝업 — 티켓형 (Build 107) ────────────────────────────
  // 로그인 직후 홈 화면에서 "신상 50% 할인 by 000 브랜드" 스타일의 티켓 팝업을
  // 1회 노출. 유저가 닫으면 해당 세션 동안 재출현 금지 (`_promoShownThisSession`).
  // 앱 재시작 시 플래그 리셋 → 다시 노출. 세션 플래그는 영속화하지 않는다.
  //
  // 팝업에 쓸 campaign 데이터는 현재 `_worldLetters` 중 브랜드가 보낸 최신
  // 활성 편지 (`senderIsBrand=true`, `!isExpired`) 에서 파생. 만료 기간은
  // 브랜드가 컴포즈 시 설정한 `expiresAt` 을 그대로 따른다 — 별도 설정 불필요.
  bool _promoShownThisSession = false;
  bool get promoShownThisSession => _promoShownThisSession;
  void markPromoShownThisSession() {
    _promoShownThisSession = true;
  }

  /// 현재 활성 중인 브랜드 홍보 편지 중 가장 최근 것을 반환.
  /// 기준: senderIsBrand=true · 만료되지 않음 · coupon 또는 voucher 카테고리.
  /// 없으면 null (팝업 미노출).
  Letter? get featuredBrandPromo {
    final now = DateTime.now();
    final candidates = _worldLetters.where((l) =>
        l.senderIsBrand &&
        (l.category == LetterCategory.coupon ||
            l.category == LetterCategory.voucher) &&
        (l.expiresAt == null || l.expiresAt!.isAfter(now))).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return candidates.first;
  }
  int _inviteRewardCredits = 0;
  String _inviteCode = '';
  String? _appliedInviteCode;
  DateTime? _lastInviteRewardAt;

  bool get isGeneralMember => !_currentUser.isPremium && !_currentUser.isBrand;
  bool get isBrandMember => _currentUser.isBrand;

  // 테스트 모드에서 shimyup@gmail.com 외 브랜드 계정은 발송 한도를 프리미엄 수준으로 제한
  bool get _isTestLimitedBrand {
    if (!kDebugMode) return false;
    if (!isBrandMember) return false;
    final email = _currentUser.email?.toLowerCase() ?? '';
    return email != DebugConstants.testBrandEmail;
  }

  int get dailySendLimit {
    if (isBrandMember) {
      return _isTestLimitedBrand ? _dailyLimitPremium : _dailyLimitBrand;
    }
    if (!isGeneralMember) return _dailyLimitPremium;
    // 이벤트 모드: 무료 유저도 프리미엄 한도 적용
    if (_adminEventMode) return _dailyLimitPremium;
    return _dailyLimitFree;
  }

  int get todaySentCount {
    _rolloverDailySendCounterIfNeeded();
    return _dailySentCount;
  }

  int get remainingDailySendCount {
    _rolloverDailySendCounterIfNeeded();
    return (dailySendLimit - _dailySentCount).clamp(0, dailySendLimit);
  }

  bool get hasRemainingDailyQuota =>
      remainingDailySendCount > 0 || _inviteRewardCredits > 0;

  int get monthlySendLimit {
    if (isBrandMember) {
      return _isTestLimitedBrand
          ? _monthlyLimitPremium
          : _monthlyLimitBrand + _brandExtraMonthlyQuota;
    }
    if (!isGeneralMember) return _monthlyLimitPremium;
    // 이벤트 모드: 무료 유저도 프리미엄 월간 한도 적용
    if (_adminEventMode) return _monthlyLimitPremium;
    return _monthlyLimitFree;
  }

  int get remainingMonthlySendCount {
    _rolloverMonthlySendCounterIfNeeded();
    return (monthlySendLimit - _monthlySentCount).clamp(0, monthlySendLimit);
  }

  bool get hasRemainingMonthlyQuota => remainingMonthlySendCount > 0;

  int get brandExtraMonthlyQuota => _brandExtraMonthlyQuota;
  int get inviteRewardCredits => _inviteRewardCredits;
  bool get hasAppliedInviteCode => (_appliedInviteCode?.isNotEmpty ?? false);
  String? get appliedInviteCode => _appliedInviteCode;
  DateTime? get lastInviteRewardAt => _lastInviteRewardAt;

  int get premiumExpressDailyLimit => _dailyPremiumExpressLimit;
  int get todayPremiumExpressSentCount {
    _rolloverDailyPremiumExpressCounterIfNeeded();
    return _dailyPremiumExpressSentCount;
  }

  int get remainingPremiumExpressCount {
    if (_currentUser.isBrand) return 9999;
    if (!_currentUser.isPremium) return 0;
    _rolloverDailyPremiumExpressCounterIfNeeded();
    return (_dailyPremiumExpressLimit - _dailyPremiumExpressSentCount).clamp(
      0,
      _dailyPremiumExpressLimit,
    );
  }

  bool get canUsePremiumExpress {
    if (_currentUser.isBrand) return true;
    return remainingPremiumExpressCount > 0;
  }

  // ── DM 권한 (프리미엄 전용) ─────────────────────────────────────────────────
  /// DM은 프리미엄 회원만 사용 가능. 무료·브랜드 계정은 불가.
  bool get canUseDM => _currentUser.isPremium && !_currentUser.isBrand;

  /// DM 사용 불가 사유 메시지
  String get dmUnavailableMessage {
    if (_currentUser.isBrand)
      return _l10n.stateDmUnavailableBrand;
    return _l10n.stateDmUnavailableFree(_dailyLimitPremium);
  }

  /// DM 몇 회당 편지 1통 차감하는지 (외부 노출용)
  int get dmPerLetterQuota => _dmPerLetterQuota;

  /// 다음 편지 쿼터 차감까지 남은 DM 횟수
  int get dmCountUntilNextQuotaDeduction =>
      _dmPerLetterQuota - (_pendingDMCount % _dmPerLetterQuota);

  String get premiumExpressLimitExceededMessage =>
      _l10n.statePremiumExpressLimitExceeded(_dailyPremiumExpressLimit);

  String get imageLimitExceededMessage {
    if (_currentUser.isBrand) {
      return _l10n.stateImageLimitExceeded(_dailyImageLetterLimitBrand);
    }
    return _l10n.stateImageLimitExceeded(_dailyImageLetterLimit);
  }

  String get myInviteCode =>
      _inviteCode.isNotEmpty ? _inviteCode : _deriveInviteCode();

  bool get isBrandExtraServerVerificationReady =>
      FirebaseConfig.kFirebaseEnabled &&
      FirebaseAuthService.isSignedIn &&
      _currentUser.id != 'guest';

  String get brandExtraServerVerificationUnavailableMessage =>
      _l10n.stateBrandExtraVerificationUnavailable;

  String _deriveInviteCode() {
    final seed = (_currentUser.id.isNotEmpty && _currentUser.id != 'guest')
        ? _currentUser.id
        : _currentUser.username;
    var hash = 2166136261;
    for (final codeUnit in seed.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash.toRadixString(36).toUpperCase().padLeft(6, '0').substring(0, 6);
  }

  Future<InviteCodeApplyResult> applyInviteCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    final validPattern = RegExp(r'^[A-Z0-9]{6}$');
    if (!validPattern.hasMatch(code)) {
      return InviteCodeApplyResult.invalid;
    }
    if (hasAppliedInviteCode) {
      return InviteCodeApplyResult.alreadyUsed;
    }
    if (code == myInviteCode) {
      return InviteCodeApplyResult.self;
    }

    if (!FirebaseConfig.kFirebaseEnabled || _currentUser.id == 'guest') {
      return InviteCodeApplyResult.serverUnavailable;
    }
    if (!FirebaseAuthService.isSignedIn) {
      return InviteCodeApplyResult.serverUnavailable;
    }

    await _ensureInviteIdentityOnServer();

    final inviterDocs = await FirestoreService.queryWhereEquals(
      collectionId: 'users',
      field: 'inviteCode',
      value: code,
      limit: 1,
    );
    if (inviterDocs.isEmpty) return InviteCodeApplyResult.invalid;

    final inviterDoc = inviterDocs.first;
    final inviterName = inviterDoc['name'] as String? ?? '';
    final inviterId = inviterName.split('/').last;
    if (inviterId.isEmpty) return InviteCodeApplyResult.invalid;
    if (inviterId == _currentUser.id) return InviteCodeApplyResult.self;

    final claimResult = await FirestoreService.createDocumentIfAbsent(
      'inviteClaims/${_currentUser.id}',
      {
        'claimerId': _currentUser.id,
        'inviterId': inviterId,
        'inviteCode': code,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
    if (claimResult == CreateDocumentResult.alreadyExists) {
      return InviteCodeApplyResult.alreadyUsed;
    }
    if (claimResult == CreateDocumentResult.error) {
      return InviteCodeApplyResult.networkError;
    }

    final nowIso = DateTime.now().toIso8601String();
    final myDoc = await FirestoreService.getDocument(
      'users/${_currentUser.id}',
    );
    final inviterUserDoc = await FirestoreService.getDocument(
      'users/$inviterId',
    );
    if (myDoc == null || inviterUserDoc == null) {
      return InviteCodeApplyResult.networkError;
    }

    final myData = FirestoreService.fromFirestoreDoc(myDoc);
    final inviterData = FirestoreService.fromFirestoreDoc(inviterUserDoc);

    final myCredits = (myData['inviteRewardCredits'] as int? ?? 0) + 5;
    final inviterCredits =
        (inviterData['inviteRewardCredits'] as int? ?? 0) + 5;

    final updatedMine =
        await FirestoreService.setDocument('users/${_currentUser.id}', {
          'inviteAppliedCode': code,
          'inviteRewardCredits': myCredits,
          'inviteRewardAt': nowIso,
        });
    final updatedInviter = await FirestoreService.setDocument(
      'users/$inviterId',
      {'inviteRewardCredits': inviterCredits, 'inviteRewardAt': nowIso},
    );

    if (!updatedMine || !updatedInviter) {
      return InviteCodeApplyResult.networkError;
    }

    _appliedInviteCode = code;
    _inviteRewardCredits = myCredits;
    _lastInviteRewardAt = DateTime.now();
    _saveToPrefs();
    notifyListeners();
    return InviteCodeApplyResult.success;
  }

  bool get useValueBasedPremiumCopy {
    final seed = (_currentUser.id.isNotEmpty && _currentUser.id != 'guest')
        ? _currentUser.id
        : _currentUser.username;
    var hash = 0;
    for (final codeUnit in seed.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash.isEven;
  }

  String get dailyLimitExceededMessage {
    if (isGeneralMember) {
      if (useValueBasedPremiumCopy) {
        return _l10n.stateDailyLimitFreeValueCopy(_dailyLimitFree, _dailyLimitPremium);
      }
      return _l10n.stateDailyLimitFree(_dailyLimitFree, _dailyLimitPremium);
    }
    if (isBrandMember) {
      return _l10n.stateDailyLimitBrand(_dailyLimitBrand);
    }
    return _l10n.stateDailyLimitPremium(_dailyLimitPremium);
  }

  String get monthlyLimitExceededMessage {
    if (isGeneralMember) {
      if (useValueBasedPremiumCopy) {
        return _l10n.stateMonthlyLimitFreeValueCopy(_monthlyLimitFree, _monthlyLimitPremium);
      }
      return _l10n.stateMonthlyLimitFree(_monthlyLimitFree, _monthlyLimitPremium);
    }
    if (isBrandMember) {
      final total = _monthlyLimitBrand + _brandExtraMonthlyQuota;
      return _l10n.stateMonthlyLimitBrand(total);
    }
    return _l10n.stateMonthlyLimitPremium(_monthlyLimitPremium);
  }

  // ── 이미지/링크 편지 일일 한도 (프리미엄 20통, 브랜드 300통, 무료 0통) ────────
  static const int _dailyImageLetterLimit = 20; // 프리미엄 한도
  static const int _dailyImageLetterLimitBrand = 300; // 브랜드 한도
  int _dailyImageSentCount = 0;
  String _dailyImageDateKey = _dateKey(DateTime.now());

  bool get hasRemainingImageQuota {
    _rolloverDailyImageCounterIfNeeded();
    if (!_currentUser.isPremium && !_currentUser.isBrand) return false;
    final limit = _currentUser.isBrand
        ? _dailyImageLetterLimitBrand
        : _dailyImageLetterLimit;
    return _dailyImageSentCount < limit;
  }

  int get remainingImageQuota {
    _rolloverDailyImageCounterIfNeeded();
    final limit = _currentUser.isBrand
        ? _dailyImageLetterLimitBrand
        : _dailyImageLetterLimit;
    return (limit - _dailyImageSentCount).clamp(0, limit);
  }

  // ── 프로필 설정 제한 ───────────────────────────────────────────────────────
  static const int _nicknameCooldownMonths = 3;
  DateTime? _lastNicknameChangedAt;
  DateTime? get lastNicknameChangedAt => _lastNicknameChangedAt;
  DateTime? get nextNicknameChangeAvailableAt {
    final last = _lastNicknameChangedAt;
    if (last == null) return null;
    return _addMonths(last, _nicknameCooldownMonths);
  }

  bool canChangeNicknameNow() {
    final next = nextNicknameChangeAvailableAt;
    if (next == null) return true;
    return !DateTime.now().isBefore(next);
  }

  int get nicknameChangeRemainingDays {
    final next = nextNicknameChangeAvailableAt;
    if (next == null) return 0;
    final now = DateTime.now();
    if (!now.isBefore(next)) return 0;
    final remaining = next.difference(now);
    return (remaining.inMinutes / Duration.minutesPerDay).ceil();
  }

  // ── 화면 테마 모드 (자동/밝은/다크) ────────────────────────────────────────
  DisplayThemeMode _displayThemeMode = DisplayThemeMode.auto;
  DisplayThemeMode get displayThemeMode => _displayThemeMode;
  TimeOfDayPeriod get activeTimePeriod {
    switch (_displayThemeMode) {
      case DisplayThemeMode.light:
        return TimeOfDayPeriod.day;
      case DisplayThemeMode.dark:
        return TimeOfDayPeriod.night;
      case DisplayThemeMode.auto:
        return TimeTheme.getPeriodForCountry(_currentUser.country);
    }
  }

  String get displayThemeModeLabel {
    switch (_displayThemeMode) {
      case DisplayThemeMode.auto:
        return _l10n.stateThemeAuto;
      case DisplayThemeMode.light:
        return _l10n.stateThemeLight;
      case DisplayThemeMode.dark:
        return _l10n.stateThemeDark;
    }
  }

  // ── 배송 중 편지 수 ────────────────────────────────────────────────────────
  int get totalInTransitCount =>
      _worldLetters.where((l) => l.status == DeliveryStatus.inTransit).length;

  // ── 알림 ─────────────────────────────────────────────────────────────────
  // computed getter — 항상 실제 inbox 상태 기준
  int get unreadCount =>
      _inbox.where((l) => l.status == DeliveryStatus.delivered).length;

  bool _hasNearbyAlert = false;
  bool get hasNearbyAlert => _hasNearbyAlert;

  // ── 딜리버리 타이머 ─────────────────────────────────────────────────────────
  Timer? _deliveryTimer;

  // ── AI 자동 편지 발송 ──────────────────────────────────────────────────────
  String _lastAiLetterDateKey = '';

  // ── 사용된 배송지 (나라 → 도시 키 Set, 중복 방지) ──────────────────────────
  final Map<String, Set<String>> _usedDestinations = {};

  // ── 차단된 발신자 (영구 차단: 관리자 확인 후) ─────────────────────────────
  final Set<String> _blockedSenderIds = {};
  Set<String> get blockedSenderIds => Set.unmodifiable(_blockedSenderIds);

  // ── 유저가 직접 뮤트한 브랜드 (SharedPreferences 로 영속) ──────────────
  // 편지 읽기 화면에서 "이 브랜드 편지 받지 않기" 탭으로 추가/해제. 뮤트된
  // 브랜드의 새 편지는 수집첩에 합류할 때 필터링되어 인박스에서 제외됨
  // (기존 편지는 그대로 유지 — 과거 수령한 혜택은 남김).
  final Set<String> _mutedBrandIds = {};
  Set<String> get mutedBrandIds => Set.unmodifiable(_mutedBrandIds);
  bool isBrandMuted(String senderId) => _mutedBrandIds.contains(senderId);

  Future<void> toggleBrandMute(String senderId) async {
    if (senderId.isEmpty) return;
    if (_mutedBrandIds.contains(senderId)) {
      _mutedBrandIds.remove(senderId);
    } else {
      _mutedBrandIds.add(senderId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('mutedBrandIds', _mutedBrandIds.toList());
    notifyListeners();
  }

  // ── 쿠폰 사용 완료 추적 (Build 108) ─────────────────────────────────────
  // 수신자가 편지 안 할인 코드·링크를 실제로 써서 "사용 완료" 버튼을 누르면
  // letterId 가 이 set 에 들어간다. SharedPreferences 로 영속. 브랜드 쪽에서
  // 자기 편지들 중 얼마나 사용됐는지 집계해 편지 카드에 배지 노출 가능.
  // 서버 동기화·브랜드 대시보드 대용량 집계는 후속 작업 — 현재는 로컬 추적만.
  final Set<String> _redeemedLetterIds = {};
  bool isLetterRedeemed(String letterId) =>
      _redeemedLetterIds.contains(letterId);

  /// 편지의 쿠폰/링크를 실제로 사용했음을 표시 (단방향 — 한번 사용 → 계속 사용됨).
  Future<void> markLetterRedeemed(String letterId) async {
    if (letterId.isEmpty) return;
    if (_redeemedLetterIds.contains(letterId)) return;
    _redeemedLetterIds.add(letterId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'redeemedLetterIds',
      _redeemedLetterIds.toList(),
    );
    // Build 134: 이미 사용했으니 만료 임박 알림은 불필요 — 예약됐다면 취소.
    unawaited(NotificationService.cancelCouponExpiryReminder(letterId));
    // Build 138: 브랜드 편지 사용 완료 집계 — 브랜드 대시보드 conversion
    // 계산 원천. 로컬 `_redeemedLetterIds` 와 별도로 서버에도 기록.
    if (FirebaseConfig.kFirebaseEnabled) {
      unawaited(
        FirestoreService.incrementField(
          path: 'letters/$letterId',
          field: 'redeemedCount',
        ),
      );
    }
    notifyListeners();
  }

  /// 브랜드 대시보드 용 — 내가 보낸 편지 중 몇 통이 사용됐는지 (동일 디바이스 기준).
  int get myRedeemedSentCount {
    if (!_currentUser.isBrand) return 0;
    return _sent.where((l) => _redeemedLetterIds.contains(l.id)).length;
  }

  // ── 브랜드 팔로우 (뮤트의 반대 — Build 115) ──────────────────────────────
  // 관심 브랜드를 표시해두면 인박스 상단에 해당 브랜드 편지가 고정되고,
  // 향후 신규 편지 알림 우선순위 판단에도 쓰일 수 있다. mute 와 상호배타 —
  // follow 하면 mute 해제, mute 하면 follow 해제. 둘 다 SharedPreferences
  // 영속.
  final Set<String> _followedBrandIds = {};
  Set<String> get followedBrandIds => Set.unmodifiable(_followedBrandIds);
  bool isBrandFollowed(String senderId) =>
      _followedBrandIds.contains(senderId);

  Future<void> toggleBrandFollow(String senderId) async {
    if (senderId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (_followedBrandIds.contains(senderId)) {
      _followedBrandIds.remove(senderId);
    } else {
      _followedBrandIds.add(senderId);
      if (_mutedBrandIds.remove(senderId)) {
        await prefs.setStringList('mutedBrandIds', _mutedBrandIds.toList());
      }
    }
    await prefs.setStringList(
      'followedBrandIds',
      _followedBrandIds.toList(),
    );
    notifyListeners();
  }

  // ── 첫 픽업 축하 모먼트 (Build 115) ──────────────────────────────────────
  // 신규 유저의 첫 편지 픽업은 온보딩-본격 사용 전환의 결정적 순간.
  // 프로필/지도 어디서든 이 getter 가 true 면 축하 모달을 띄우고
  // `acknowledgeFirstPickup()` 으로 플래그를 소진한다. 한 번 소진 후 다시
  // true 되지 않음 (영구).
  bool _hasCelebratedFirstPickup = false;
  bool get shouldCelebrateFirstPickup =>
      !_hasCelebratedFirstPickup && _myPickedUpLetterIds.isNotEmpty;

  Future<void> acknowledgeFirstPickup() async {
    if (_hasCelebratedFirstPickup) return;
    _hasCelebratedFirstPickup = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCelebratedFirstPickup', true);
    notifyListeners();
  }

  // ── 헌트 지표 집계 (Build 115 "나의 헌트 기록" 카드용) ───────────────────
  // 프로필 카드에서 "이번 달 얼마나 벌었나?" 감각을 만드는 핵심 수치. 쿠폰
  // 편지만 카운트 — 일반 편지는 혜택 개념이 아님. arrivedAt 은 픽업 시점에
  // 세팅되므로 월별 필터링의 기준 시각으로 쓴다.
  DateTime get _startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  int get pickupsThisMonth => _inbox
      .where((l) => l.arrivedAt != null && l.arrivedAt!.isAfter(_startOfMonth))
      .length;

  int get brandPickupsThisMonth => _inbox
      .where((l) =>
          l.senderIsBrand &&
          l.arrivedAt != null &&
          l.arrivedAt!.isAfter(_startOfMonth))
      .length;

  int get redemptionsThisMonth => _inbox
      .where((l) =>
          l.senderIsBrand &&
          l.arrivedAt != null &&
          l.arrivedAt!.isAfter(_startOfMonth) &&
          _redeemedLetterIds.contains(l.id))
      .length;

  int get totalBrandPickups =>
      _inbox.where((l) => l.senderIsBrand).length;
  int get totalRedemptions => _redeemedLetterIds.length;

  // 주간 (월요일 00:00 부터 현재까지) 픽업 수 — 주간 퀘스트 진행 바용.
  // 로컬 타임존 기준. 일요일 자정에 자동 리셋. Build 116.
  DateTime get _startOfWeek {
    final now = DateTime.now();
    final daysFromMonday = (now.weekday - DateTime.monday) % 7;
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysFromMonday));
    return monday;
  }

  int get pickupsThisWeek => _inbox
      .where(
          (l) => l.arrivedAt != null && l.arrivedAt!.isAfter(_startOfWeek))
      .length;

  /// 주간 헌트 퀘스트 기본 목표치 (현재 하드코딩 5통). Free/Premium/Brand
  /// 동일. 추후 티어별 차등 도입 시 이 값만 조정하면 됨.
  int get weeklyQuestGoal => 5;

  // ── 만료 임박 쿠폰 (Build 115 "만료 사이렌" 배너용) ────────────────────────
  // 받은 브랜드 쿠폰·교환권 중 24h 이내 만료 + 미사용. 인박스 상단 빨간
  // 배너로 FOMO 트리거. 일반 브랜드 편지는 제외 (혜택 개념 없음).
  List<Letter> get expiringSoonLetters {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(hours: 24));
    return _inbox
        .where((l) =>
            l.senderIsBrand &&
            l.category != LetterCategory.general &&
            l.expiresAt != null &&
            l.expiresAt!.isAfter(now) &&
            l.expiresAt!.isBefore(cutoff) &&
            !_redeemedLetterIds.contains(l.id))
        .toList();
  }

  // ── 임시 차단 (신고 접수 → 관리자 검토 전까지) ──────────────────────────────
  final Set<String> _tempBlockedSenderIds = {};
  Set<String> get tempBlockedSenderIds =>
      Set.unmodifiable(_tempBlockedSenderIds);
  bool isSenderTempBlocked(String senderId) =>
      _tempBlockedSenderIds.contains(senderId);

  // ── 관리자 전용: 이벤트 모드 & 배송 속도 배율 ──────────────────────────────
  bool _adminEventMode = false;
  double _adminSpeedMultiplier = 1.0;

  bool get adminEventMode => _adminEventMode;
  double get adminSpeedMultiplier => _adminSpeedMultiplier;

  /// 이벤트 모드: 무료 유저 일일/월간 한도를 프리미엄 수준으로 임시 상향
  void setAdminEventMode(bool value) {
    _adminEventMode = value;
    notifyListeners();
  }

  /// 배송 속도 배율 (1.0 = 기본, 10.0 = 10배속, 100.0 = 100배속)
  void setAdminSpeedMultiplier(double value) {
    _adminSpeedMultiplier = value.clamp(1.0, 1000.0);
    notifyListeners();
  }

  // ── 관리자 전용: 통계 ──────────────────────────────────────────────────────
  int get adminTotalSent => _sent.length;
  int get adminInboxCount => _inbox.length;
  int get adminInTransitCount =>
      _worldLetters.where((l) => l.status == DeliveryStatus.inTransit).length;
  int get adminBlockedCount => _blockedSenderIds.length;
  int get adminReportedCount =>
      _worldLetters.where((l) => l.reportCount > 0).toList().length +
      _inbox.where((l) => l.reportCount > 0).toList().length;
  List<Letter> get adminReportedLetters {
    final seen = <String>{};
    final result = <Letter>[];
    for (final l in [..._worldLetters, ..._inbox]) {
      if (l.reportCount > 0 && seen.add(l.id)) result.add(l);
    }
    result.sort((a, b) => b.reportCount.compareTo(a.reportCount));
    return result;
  }

  // ── 관리자 전용: 조작 도구 ─────────────────────────────────────────────────
  /// 이동 중인 모든 편지를 즉시 도착으로 강제 처리
  void adminForceDeliverAll() {
    final now = DateTime.now();
    for (final letter in _worldLetters) {
      if (letter.status == DeliveryStatus.inTransit ||
          letter.status == DeliveryStatus.nearYou) {
        for (final seg in letter.segments) {
          seg.progress = 1.0;
        }
        letter.currentSegmentIndex = letter.segments.isEmpty
            ? 0
            : letter.segments.length - 1;
        letter.arrivalTime = now;
      }
    }
    notifyListeners();
    _saveToPrefs();
  }

  /// 일일 발송 카운터 리셋
  void adminResetDailyCount() {
    _dailySentCount = 0;
    _dailySentDateKey = _dateKey(DateTime.now());
    _dailyPremiumExpressSentCount = 0;
    _dailyPremiumExpressDateKey = _dateKey(DateTime.now());
    notifyListeners();
    _saveToPrefs();
  }

  /// 월간 발송 카운터 리셋
  void adminResetMonthlyCount() {
    _monthlySentCount = 0;
    _monthlyDateKey = _monthKey(DateTime.now());
    notifyListeners();
    _saveToPrefs();
  }

  /// 차단 목록 전체 초기화 (영구 + 임시)
  void adminClearBlockList() {
    _blockedSenderIds.clear();
    _tempBlockedSenderIds.clear();
    notifyListeners();
    _saveToPrefs();
  }

  /// 특정 발신자 차단 해제 (영구 + 임시 모두)
  void adminUnblockSender(String senderId) {
    _blockedSenderIds.remove(senderId);
    _tempBlockedSenderIds.remove(senderId);
    notifyListeners();
    _saveToPrefs();
  }

  /// 관리자: 임시 차단 → 영구 차단으로 승격
  void adminConfirmBlock(String senderId) {
    _tempBlockedSenderIds.remove(senderId);
    _blockedSenderIds.add(senderId);
    _inbox.removeWhere((l) => l.senderId == senderId);
    notifyListeners();
    _saveToPrefs();
  }

  /// 관리자: 임시 차단 해제 (무혐의)
  void adminDismissReport(String senderId) {
    _tempBlockedSenderIds.remove(senderId);
    notifyListeners();
    _saveToPrefs();
  }

  /// 임시 차단된 유저 수
  int get adminTempBlockedCount => _tempBlockedSenderIds.length;

  /// 특정 편지의 신고 카운터 초기화 (관리자 검토 후 클리어)
  void adminClearLetterReport(String letterId) {
    for (final l in [..._worldLetters, ..._inbox]) {
      if (l.id == letterId) {
        l.reportCount = 0;
        l.reportedBy.clear();
        break;
      }
    }
    notifyListeners();
    _saveToPrefs();
  }

  /// 편지함 전체 비우기 (받은 편지)
  void adminClearInbox() {
    _inbox.clear();
    notifyListeners();
    _saveToPrefs();
  }

  /// 모든 편지 전체 삭제 (받은 편지 + 보낸 편지 + 지도)
  void adminClearAllLetters() {
    _inbox.clear();
    _sent.clear();
    _worldLetters.clear();
    _hasNearbyAlert = false;
    notifyListeners();
    _saveToPrefs();
  }

  /// 활동 점수 리셋
  void adminResetActivityScore() {
    _currentUser.activityScore.receivedCount = 0;
    _currentUser.activityScore.replyCount = 0;
    _currentUser.activityScore.sentCount = 0;
    _currentUser.activityScore.likeCount = 0;
    _currentUser.activityScore.ratingTotal = 0;
    _currentUser.activityScore.ratingCount = 0;
    notifyListeners();
    _saveToPrefs();
  }

  /// 발신자 수동 차단 (관리자)
  void adminBlockSender(String senderId) {
    _blockedSenderIds.add(senderId);
    _worldLetters.removeWhere((l) => l.senderId == senderId);
    _inbox.removeWhere((l) => l.senderId == senderId);
    notifyListeners();
    _saveToPrefs();
  }

  /// 시스템 편지를 받은 편지함에 직접 추가
  void adminAddSystemLetter(String content) {
    final now = DateTime.now();
    final originLoc = LatLng(_currentUser.latitude, _currentUser.longitude);
    final letter = Letter(
      id: 'system_${now.millisecondsSinceEpoch}',
      senderId: 'system',
      senderName: '📮 Message in a Bottle',
      senderCountry: _l10n.stateAdmin,
      senderCountryFlag: '🌐',
      content: content,
      originLocation: originLoc,
      destinationLocation: originLoc,
      destinationCountry: _currentUser.country,
      destinationCountryFlag: _currentUser.countryFlag,
      segments: [],
      currentSegmentIndex: 0,
      status: DeliveryStatus.delivered,
      sentAt: now,
      arrivedAt: now,
      estimatedTotalMinutes: 0,
      isAnonymous: false,
      senderTier: LetterSenderTier.brand,
    );
    _inbox.insert(0, letter);
    notifyListeners();
    _saveToPrefs();
  }

  // ── DM/채팅 시스템 ─────────────────────────────────────────────────────────
  final Map<String, ChatSession> _chatSessions = {};
  Map<String, ChatSession> get chatSessions => Map.unmodifiable(_chatSessions);
  final Map<String, List<DirectMessage>> _dmMessages = {};
  int get totalDMUnread =>
      _chatSessions.values.fold(0, (s, c) => s + c.unreadCount);

  // ── 국가 목록 (GeocodingService 198개국 → fallback 50개) ────────────────
  static List<Map<String, String>> get countries {
    final geo = GeocodingService.instance;
    if (geo.isInitialized && geo.countryCount > 0) return geo.allCountries;
    return _fallbackCountries;
  }

  /// GeocodingService 미초기화 시 폴백 (기존 50개국)
  static const List<Map<String, String>> _fallbackCountries = [
    {'name': '대한민국', 'flag': '🇰🇷', 'lat': '37.5665', 'lng': '126.9780'},
    {'name': '일본', 'flag': '🇯🇵', 'lat': '35.6762', 'lng': '139.6503'},
    {'name': '미국', 'flag': '🇺🇸', 'lat': '40.7128', 'lng': '-74.0060'},
    {'name': '프랑스', 'flag': '🇫🇷', 'lat': '48.8566', 'lng': '2.3522'},
    {'name': '영국', 'flag': '🇬🇧', 'lat': '51.5074', 'lng': '-0.1278'},
    {'name': '독일', 'flag': '🇩🇪', 'lat': '52.5200', 'lng': '13.4050'},
    {'name': '이탈리아', 'flag': '🇮🇹', 'lat': '41.9028', 'lng': '12.4964'},
    {'name': '스페인', 'flag': '🇪🇸', 'lat': '40.4168', 'lng': '-3.7038'},
    {'name': '브라질', 'flag': '🇧🇷', 'lat': '-15.7801', 'lng': '-47.9292'},
    {'name': '인도', 'flag': '🇮🇳', 'lat': '28.6139', 'lng': '77.2090'},
    {'name': '중국', 'flag': '🇨🇳', 'lat': '39.9042', 'lng': '116.4074'},
    {'name': '호주', 'flag': '🇦🇺', 'lat': '-33.8688', 'lng': '151.2093'},
    {'name': '캐나다', 'flag': '🇨🇦', 'lat': '45.4215', 'lng': '-75.6919'},
    {'name': '멕시코', 'flag': '🇲🇽', 'lat': '19.4326', 'lng': '-99.1332'},
    {'name': '아르헨티나', 'flag': '🇦🇷', 'lat': '-34.6037', 'lng': '-58.3816'},
    {'name': '러시아', 'flag': '🇷🇺', 'lat': '55.7558', 'lng': '37.6176'},
    {'name': '터키', 'flag': '🇹🇷', 'lat': '41.0082', 'lng': '28.9784'},
    {'name': '이집트', 'flag': '🇪🇬', 'lat': '30.0444', 'lng': '31.2357'},
    {'name': '남아프리카', 'flag': '🇿🇦', 'lat': '-25.7479', 'lng': '28.2293'},
    {'name': '태국', 'flag': '🇹🇭', 'lat': '13.7563', 'lng': '100.5018'},
    {'name': '네덜란드', 'flag': '🇳🇱', 'lat': '52.3676', 'lng': '4.9041'},
    {'name': '스웨덴', 'flag': '🇸🇪', 'lat': '59.3293', 'lng': '18.0686'},
    {'name': '노르웨이', 'flag': '🇳🇴', 'lat': '59.9139', 'lng': '10.7522'},
    {'name': '포르투갈', 'flag': '🇵🇹', 'lat': '38.7223', 'lng': '-9.1393'},
    {'name': '인도네시아', 'flag': '🇮🇩', 'lat': '-6.2088', 'lng': '106.8456'},
    {'name': '말레이시아', 'flag': '🇲🇾', 'lat': '3.1390', 'lng': '101.6869'},
    {'name': '싱가포르', 'flag': '🇸🇬', 'lat': '1.3521', 'lng': '103.8198'},
    {'name': '뉴질랜드', 'flag': '🇳🇿', 'lat': '-36.8485', 'lng': '174.7633'},
    {'name': '필리핀', 'flag': '🇵🇭', 'lat': '14.5995', 'lng': '120.9842'},
    {'name': '베트남', 'flag': '🇻🇳', 'lat': '21.0285', 'lng': '105.8542'},
    {'name': '우크라이나', 'flag': '🇺🇦', 'lat': '50.4501', 'lng': '30.5234'},
    {'name': '폴란드', 'flag': '🇵🇱', 'lat': '52.2297', 'lng': '21.0122'},
    {'name': '체코', 'flag': '🇨🇿', 'lat': '50.0755', 'lng': '14.4378'},
    {'name': '헝가리', 'flag': '🇭🇺', 'lat': '47.4979', 'lng': '19.0402'},
    {'name': '그리스', 'flag': '🇬🇷', 'lat': '37.9838', 'lng': '23.7275'},
    {'name': '이스라엘', 'flag': '🇮🇱', 'lat': '31.7683', 'lng': '35.2137'},
    {'name': '사우디아라비아', 'flag': '🇸🇦', 'lat': '24.7136', 'lng': '46.6753'},
    {'name': 'UAE', 'flag': '🇦🇪', 'lat': '25.2048', 'lng': '55.2708'},
    {'name': '파키스탄', 'flag': '🇵🇰', 'lat': '33.6844', 'lng': '73.0479'},
    {'name': '방글라데시', 'flag': '🇧🇩', 'lat': '23.8103', 'lng': '90.4125'},
    {'name': '나이지리아', 'flag': '🇳🇬', 'lat': '9.0579', 'lng': '7.4951'},
    {'name': '케냐', 'flag': '🇰🇪', 'lat': '-1.2921', 'lng': '36.8219'},
    {'name': '에티오피아', 'flag': '🇪🇹', 'lat': '9.0320', 'lng': '38.7469'},
    {'name': '모로코', 'flag': '🇲🇦', 'lat': '33.9716', 'lng': '-6.8498'},
    {'name': '콜롬비아', 'flag': '🇨🇴', 'lat': '4.7110', 'lng': '-74.0721'},
    {'name': '페루', 'flag': '🇵🇪', 'lat': '-12.0464', 'lng': '-77.0428'},
    {'name': '칠레', 'flag': '🇨🇱', 'lat': '-33.4489', 'lng': '-70.6693'},
    {'name': '덴마크', 'flag': '🇩🇰', 'lat': '55.6761', 'lng': '12.5683'},
    {'name': '핀란드', 'flag': '🇫🇮', 'lat': '60.1699', 'lng': '24.9384'},
    {'name': '오스트리아', 'flag': '🇦🇹', 'lat': '48.2082', 'lng': '16.3738'},
  ];

  // ── 랜덤 목적지 선택 (198개국 지원) ────────────────────────────────────────
  static Map<String, String> randomDestination({String? excludeCountry}) {
    final geo = GeocodingService.instance;
    if (geo.isInitialized && geo.countryCount > 0) {
      return geo.randomCountry(exclude: excludeCountry) ??
          _fallbackRandomDestination(excludeCountry);
    }
    return _fallbackRandomDestination(excludeCountry);
  }

  static Map<String, String> _fallbackRandomDestination(String? exclude) {
    final rng = Random();
    final pool = _fallbackCountries.where((c) => c['name'] != exclude).toList();
    return pool[rng.nextInt(pool.length)];
  }

  AppState() {
    WidgetsBinding.instance.addObserver(this);
    // 목업 데이터는 디버그 빌드에서만 초기화 (릴리즈 빌드에서는 실 데이터만 사용)
    if (kDebugMode) _initMockData();
    _startDeliverySimulation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Build 205: 백그라운드 동안 wall-clock 기반 진행을 즉시 catch-up.
      // (timer 없이도 한 번 sync — 진행이 멈춰 보이지 않게)
      _reconcileLetterStatuses();
      // Build 218: 진행도 sync 직후 1회 tick 으로 nearYou/deliveredFar
      // 상태 전환 + UI 알림까지 즉시 반영. 5s timer 첫 발화 대기 없이
      // 사용자가 "편지가 멈춰 있다" 고 느끼는 빈 frame 을 제거.
      _runDeliveryTick(triggerNotifications: false);
      // 포그라운드 복귀 → 타이머 재시작
      if (_deliveryTimer == null || !_deliveryTimer!.isActive) {
        _startDeliverySimulation();
      }
      // 서버 편지 동기화 재개
      if (_worldLetterSyncTimer == null || !_worldLetterSyncTimer!.isActive) {
        syncWorldLettersFromServer();
        _worldLetterSyncTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => syncWorldLettersFromServer(),
        );
      }
      // 서버 사용자/편지 동기화 재개 (비용 최적화)
      resumeServerSyncFromBackground();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // 백그라운드 진입 → 타이머 정지 + 주소 캐시 저장
      _deliveryTimer?.cancel();
      _deliveryTimer = null;
      _worldLetterSyncTimer?.cancel();
      _worldLetterSyncTimer = null;
      // 서버 동기화 일시정지 (Firestore 호출 중단 → 비용 절감)
      pauseServerSyncForBackground();
      unawaited(GeocodingService.instance.saveAllCache());
    }
  }

  static String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _monthKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

  static DateTime _addMonths(DateTime date, int monthsToAdd) {
    final monthIndex = date.month - 1 + monthsToAdd;
    final year = date.year + (monthIndex ~/ 12);
    final month = (monthIndex % 12) + 1;
    final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    final day = min(date.day, lastDayOfTargetMonth);
    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  bool _purgeExpiredReadLetters() {
    final now = DateTime.now();
    final before = _inbox.length;
    _inbox.removeWhere((letter) {
      // 1) 읽은 편지: 30일 후 삭제
      if (letter.status == DeliveryStatus.read) {
        final baseTime = letter.readAt ?? letter.arrivedAt ?? letter.sentAt;
        return now.difference(baseTime) >= _readLetterRetention;
      }
      // 2) 도착했지만 7일간 미열람 편지: 자동 삭제
      if (letter.status == DeliveryStatus.delivered ||
          letter.status == DeliveryStatus.nearYou ||
          letter.status == DeliveryStatus.deliveredFar) {
        final arrivedTime = letter.arrivedAt ?? letter.sentAt;
        if (!letter.isReadByRecipient &&
            now.difference(arrivedTime) >= _unopenedLetterExpiry) {
          return true;
        }
      }
      return false;
    });
    return _inbox.length != before;
  }

  void _rolloverDailySendCounterIfNeeded() {
    final todayKey = _dateKey(DateTime.now());
    if (_dailySentDateKey != todayKey) {
      _dailySentDateKey = todayKey;
      _dailySentCount = 0;
    }
  }

  void _rolloverMonthlySendCounterIfNeeded() {
    final thisMonthKey = _monthKey(DateTime.now());
    if (_monthlyDateKey != thisMonthKey) {
      _monthlyDateKey = thisMonthKey;
      _monthlySentCount = 0;
      // 브랜드 추가 발송권은 유료 구매 상품이므로 월 초에 리셋하지 않음
    }
  }

  void _rolloverDailyPremiumExpressCounterIfNeeded() {
    final todayKey = _dateKey(DateTime.now());
    if (_dailyPremiumExpressDateKey != todayKey) {
      _dailyPremiumExpressDateKey = todayKey;
      _dailyPremiumExpressSentCount = 0;
    }
  }

  bool _canSendLetterByDailyLimit() {
    _rolloverDailySendCounterIfNeeded();
    _rolloverMonthlySendCounterIfNeeded();
    final hasBaseQuota =
        _dailySentCount < dailySendLimit &&
        _monthlySentCount < monthlySendLimit;
    if (hasBaseQuota) return true;
    return _inviteRewardCredits > 0;
  }

  bool _canUseExpressMode() {
    if (_currentUser.isBrand) return true;
    if (!_currentUser.isPremium) return false;
    _rolloverDailyPremiumExpressCounterIfNeeded();
    return _dailyPremiumExpressSentCount < _dailyPremiumExpressLimit;
  }

  void _consumeDailyQuota() {
    _rolloverDailySendCounterIfNeeded();
    _rolloverMonthlySendCounterIfNeeded();
    final hasBaseQuota =
        _dailySentCount < dailySendLimit &&
        _monthlySentCount < monthlySendLimit;
    if (hasBaseQuota) {
      _dailySentCount++;
      _monthlySentCount++;
      return;
    }
    if (_inviteRewardCredits > 0) {
      _inviteRewardCredits--;
    }
  }

  void _consumeExpressQuotaIfNeeded(bool isExpress) {
    if (!isExpress) return;
    if (_currentUser.isBrand) return;
    if (!_currentUser.isPremium) return;
    _rolloverDailyPremiumExpressCounterIfNeeded();
    _dailyPremiumExpressSentCount++;
  }

  void _rolloverDailyImageCounterIfNeeded() {
    final todayKey = _dateKey(DateTime.now());
    if (_dailyImageDateKey != todayKey) {
      _dailyImageDateKey = todayKey;
      _dailyImageSentCount = 0;
    }
  }

  bool _canSendImageLetter() {
    _rolloverDailyImageCounterIfNeeded();
    if (!_currentUser.isPremium && !_currentUser.isBrand)
      return false; // 무료: 불가
    final limit = _currentUser.isBrand
        ? _dailyImageLetterLimitBrand
        : _dailyImageLetterLimit;
    return _dailyImageSentCount < limit;
  }

  void _consumeImageQuota() {
    _rolloverDailyImageCounterIfNeeded();
    _dailyImageSentCount++;
  }

  // ── 타워 스킨 업데이트 ────────────────────────────────────────────────────
  void updateTowerSkin({
    String? color,
    String? accentEmoji,
    int? roofStyle,
    int? windowStyle,
  }) {
    if (color != null) _currentUser.towerColor = color;
    if (accentEmoji != null) _currentUser.towerAccentEmoji = accentEmoji;
    if (roofStyle != null) _currentUser.towerRoofStyle = roofStyle;
    if (windowStyle != null) _currentUser.towerWindowStyle = windowStyle;
    _saveToPrefs();
    _saveUserToFirestore();
    notifyListeners();
  }

  // ── 브랜드 계정 설정 ──────────────────────────────────────────────────────
  void setBrandAccount({required bool isBrand, String? brandName}) {
    _currentUser.isBrand = isBrand;
    if (brandName != null) _currentUser.brandName = brandName;
    _saveToPrefs();
    notifyListeners();
  }

  // ── 프리미엄 상태 동기화 (PurchaseService → AppState) ────────────────────
  void syncPremiumStatus({required bool isPremium, required bool isBrand}) {
    bool changed = false;
    if (_currentUser.isPremium != isPremium) {
      _currentUser.isPremium = isPremium;
      changed = true;
    }
    if (_currentUser.isBrand != isBrand) {
      _currentUser.isBrand = isBrand;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  // ── SharedPreferences 저장 ─────────────────────────────────────────────────
  // ── 암호화 헬퍼: 앱 고유 키(SecureStorage) + XOR 치환 ─────────────────────
  static Future<Uint8List> _getOrCreateEncKey() async {
    if (_encKey != null) return _encKey!;
    final stored = await _secure.read(key: _encKeyName);
    if (stored != null && stored.length == 64) {
      _encKey = Uint8List.fromList(
        List.generate(
          32,
          (i) => int.parse(stored.substring(i * 2, i * 2 + 2), radix: 16),
        ),
      );
      return _encKey!;
    }
    // 최초 실행: 32바이트 랜덤 키 생성
    final rng = Random.secure();
    final key = Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
    final hex = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _secure.write(key: _encKeyName, value: hex);
    _encKey = key;
    return _encKey!;
  }

  /// AES-256-CBC encryption. Returns "aes:" + base64(IV + ciphertext).
  static String _encryptStr(String plain, Uint8List key) {
    final aesKey = enc.Key(key); // 32-byte key → AES-256
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(utf8.encode(plain), iv: iv);
    // Prefix IV to ciphertext so decrypt can recover it.
    final combined = Uint8List(16 + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(16, encrypted.bytes);
    return 'aes:${base64Encode(combined)}';
  }

  /// Decrypts AES-256-CBC (prefixed "aes:") or legacy XOR base64.
  ///
  /// Build 207: 마지막 catch 의 `return cipher;` (평문 fallback) 제거.
  /// 손상되거나 외부에서 주입된 데이터를 그대로 평문 처리하면 우회 위험.
  /// 복호화 실패 시 빈 문자열 반환 → 호출부는 "데이터 없음" 으로 안전 처리.
  static String _decryptStr(String cipher, Uint8List key) {
    try {
      if (cipher.startsWith('aes:')) {
        // ── AES-256-CBC path ──
        final combined = base64Decode(cipher.substring(4));
        final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
        final cipherBytes = combined.sublist(16);
        final aesKey = enc.Key(key);
        final encrypter =
            enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc));
        return encrypter.decrypt(enc.Encrypted(cipherBytes), iv: iv);
      }
      // ── Legacy XOR path (will be re-encrypted as AES on next save) ──
      final input = base64Decode(cipher);
      final output = Uint8List(input.length);
      for (var i = 0; i < input.length; i++) {
        output[i] = input[i] ^ key[i % key.length];
      }
      return utf8.decode(output);
    } catch (_) {
      // 복호화 실패 — 평문 fallback 금지. 빈 문자열로 안전하게 무효화.
      if (kDebugMode) {
        debugPrint('[Crypto] _decryptStr 실패 — 손상 데이터 무시');
      }
      return '';
    }
  }

  void _saveToPrefs() {
    Future(() async {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getOrCreateEncKey();
      _purgeExpiredReadLetters();

      // mock 편지(senderId: 'mock_...')는 저장 제외 — 디버그 테스트 데이터가 실 데이터에 섞이지 않도록
      final realInbox = _inbox
          .where((l) => !l.senderId.startsWith('mock_'))
          .toList();
      final realSent = _sent
          .where((l) => !l.senderId.startsWith('mock_'))
          .toList();

      prefs.setString(
        'inbox',
        _encryptStr(jsonEncode(realInbox.map((l) => l.toJson()).toList()), key),
      );
      prefs.setString(
        'sent',
        _encryptStr(jsonEncode(realSent.map((l) => l.toJson()).toList()), key),
      );
      // 배송 중인 incoming 편지 (daily 포함) 저장 — mock 제외
      final incomingInTransit = _worldLetters
          .where(
            (l) => l.id.startsWith('daily_') && !l.senderId.startsWith('mock_'),
          )
          .toList();
      prefs.setString(
        'worldLettersIncoming',
        _encryptStr(
          jsonEncode(incomingInTransit.map((l) => l.toJson()).toList()),
          key,
        ),
      );
      prefs.setStringList('blocked', _blockedSenderIds.toList());
      prefs.setStringList('temp_blocked', _tempBlockedSenderIds.toList());
      prefs.setString('lastAiLetterDateKey', _lastAiLetterDateKey);
      prefs.setInt('sentSinceLastUnlock', _sentSinceLastUnlock);
      prefs.setInt('dailySentCount', _dailySentCount);
      prefs.setString('dailySentDateKey', _dailySentDateKey);
      // 일일 스트릭
      prefs.setInt('streak_current', _currentStreak);
      prefs.setInt('streak_longest', _longestStreak);
      prefs.setString('streak_last_checkin', _lastStreakCheckinDate);
      // 스트릭 방어권 (30일마다 1회 충전, 1일 공백 구제)
      prefs.setInt('streak_freeze_tokens', _streakFreezeTokens);
      prefs.setString('streak_freeze_last_refill', _streakFreezeLastRefill);
      // XP 거리 누적 (Brand 계정도 필드는 보존해 다시 Free 로 전환 시 유지)
      prefs.setDouble('sum_pickup_km', _sumPickupKm);
      prefs.setDouble('sum_sent_km', _sumSentKm);
      // 주간 챌린지
      prefs.setStringList(
        'challenge_week_countries',
        _weeklyChallengeCountries.toList(),
      );
      prefs.setString('challenge_week_key', _weeklyChallengeWeekKey);
      prefs.setBool('challenge_week_claimed', _weeklyChallengeClaimed);
      prefs.setInt('challenge_reward_balance', _challengeRewardBalance);
      prefs.setInt(
        PrefKeys.dailyPremiumExpressSentCount,
        _dailyPremiumExpressSentCount,
      );
      prefs.setString(
        PrefKeys.dailyPremiumExpressDateKey,
        _dailyPremiumExpressDateKey,
      );
      prefs.setInt('dailyImageSentCount', _dailyImageSentCount);
      prefs.setString('dailyImageDateKey', _dailyImageDateKey);
      prefs.setInt('monthlySentCount', _monthlySentCount);
      prefs.setString('monthlyDateKey', _monthlyDateKey);
      prefs.setInt('pendingDMCount', _pendingDMCount);
      prefs.setInt(PrefKeys.brandExtraMonthlyQuota, _brandExtraMonthlyQuota);
      prefs.setInt(PrefKeys.inviteRewardCredits, _inviteRewardCredits);
      prefs.setString(PrefKeys.inviteCode, myInviteCode);
      prefs.setString(PrefKeys.inviteAppliedCode, _appliedInviteCode ?? '');
      prefs.setInt(
        PrefKeys.inviteRewardAtEpochMs,
        _lastInviteRewardAt?.millisecondsSinceEpoch ?? 0,
      );
      prefs.setString(PrefKeys.towerColor, _currentUser.towerColor);
      if (_currentUser.towerAccentEmoji != null) {
        prefs.setString(
          PrefKeys.towerAccentEmoji,
          _currentUser.towerAccentEmoji!,
        );
      }
      prefs.setInt('towerRoofStyle', _currentUser.towerRoofStyle);
      prefs.setInt('towerWindowStyle', _currentUser.towerWindowStyle);
      prefs.setBool(PrefKeys.isBrand, _currentUser.isBrand);
      if (_currentUser.brandName != null) {
        prefs.setString(PrefKeys.brandName, _currentUser.brandName!);
      }
      prefs.setString(
        'activityScore',
        jsonEncode(_currentUser.activityScore.toJson()),
      );
      prefs.setString(
        PrefKeys.profileImagePath,
        _currentUser.profileImagePath ?? '',
      );
      prefs.setInt(
        'nicknameChangedAtEpochMs',
        _lastNicknameChangedAt?.millisecondsSinceEpoch ?? 0,
      );
      prefs.setString('displayThemeMode', _displayThemeMode.name);
      // 타워 이름 / 언어 코드 영속 저장
      prefs.setString('customTowerName', _currentUser.customTowerName ?? '');
      prefs.setString('languageCode', _currentUser.languageCode);
      // Build 218: 카테고리 선호 영속 저장 (Premium Lv11+)
      prefs.setString(
        'preferredCategoryKey',
        _currentUser.preferredCategoryKey ?? '',
      );
      prefs.setInt(
        'lastNearbyPickupAtMs',
        _lastNearbyPickupAt?.millisecondsSinceEpoch ?? 0,
      );
      // 줍기 완료 편지 ID 목록 저장
      prefs.setStringList('myPickedUpLetterIds', _myPickedUpLetterIds.toList());
    });
  }

  // ── SharedPreferences 복원 (main.dart에서 앱 시작 시 호출) ─────────────────
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encKey = await _getOrCreateEncKey(); // 복호화 키 로드

    // 받은 편지함 복원
    final inboxJsonRaw = prefs.getString('inbox');
    if (inboxJsonRaw != null) {
      final inboxJson = _decryptStr(inboxJsonRaw, encKey);
      _inbox.clear();
      for (final j in jsonDecode(inboxJson) as List) {
        try {
          _inbox.add(Letter.fromJson(j as Map<String, dynamic>));
        } catch (_) {}
      }
    }
    // Build 202 — 테스트용 브랜드 광고 편지 (사진 + coupon 카테고리).
    // BrandAdModal 의 featuredBrandPromo 가 이 편지를 픽업해서 온보딩 후 모달
    // 노출. 실제로는 admin 업로드로 추가될 예정.
    if (!_worldLetters.any((l) => l.id == 'brand_ad_seed')) {
      final now = DateTime.now();
      _worldLetters.add(Letter(
        id: 'brand_ad_seed',
        senderId: 'brand_seed',
        senderName: 'Blue Bottle Coffee',
        senderCountry: '대한민국',
        senderCountryFlag: '🇰🇷',
        content:
            '아메리카노 1+1 쿠폰\n오늘 성수점에서 받아가세요. 첫 잔은 저희가 살게요.',
        originLocation: const LatLng(37.5447, 127.0557),
        destinationLocation: const LatLng(37.5447, 127.0557),
        destinationCountry: '대한민국',
        destinationCountryFlag: '🇰🇷',
        destinationCity: '성수동',
        segments: const [],
        currentSegmentIndex: 0,
        status: DeliveryStatus.delivered,
        sentAt: now.subtract(const Duration(hours: 2)),
        arrivedAt: now.subtract(const Duration(hours: 1)),
        arrivalTime: now.subtract(const Duration(hours: 1)),
        estimatedTotalMinutes: 60,
        senderIsBrand: true,
        senderTier: LetterSenderTier.brand,
        category: LetterCategory.coupon,
        acceptsReplies: false,
        deliveryEmoji: '☕',
        imageUrl:
            'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&q=80',
        expiresAt: now.add(const Duration(days: 7)),
      ));
    }

    // 디버그 모드: 사진 예시 편지가 없으면 추가 (inbox 유무와 무관하게 항상 체크)
    if (kDebugMode && !_inbox.any((l) => l.id == 'inbox4_photo')) {
      _inbox.add(
        _makeMockLetter(
          id: 'inbox4_photo',
          senderName: 'Sofia M.',
          senderCountry: '미국',
          senderFlag: '🇺🇸',
          content:
              'Hello from New York! 🗽\n\n오늘 센트럴 파크에서 찍은 사진을 보내드려요. 벚꽃이 한창이라 정말 아름답답니다. 언젠가 뉴욕에 오시면 꼭 봄에 오세요.\n\nI hope this little piece of my world finds you well. 당신의 일상도 이렇게 아름다우면 좋겠어요 🌸',
          fromCountry: '미국',
          fromLat: 40.7851,
          fromLng: -73.9683,
          toCountry: '대한민국',
          toLat: 37.5665,
          toLng: 126.9780,
          segProgress: [1.0, 1.0, 1.0],
          segIdx: 2,
          status: DeliveryStatus.delivered,
          hoursAgo: 6,
          imageUrl:
              'https://images.unsplash.com/photo-1534430480872-3498386e7856?w=800&q=80',
          socialLink: 'https://instagram.com/sofia.nyc',
          isAnonymous: false,
          paperStyle: 2,
        ),
      );
    }

    // 보낸 편지 복원
    final sentJsonRaw = prefs.getString('sent');
    if (sentJsonRaw != null) {
      final decoded = jsonDecode(_decryptStr(sentJsonRaw, encKey)) as List;
      if (decoded.isNotEmpty) {
        // 실제 유저가 보낸 편지가 있으면 목업 제거 후 복원
        _sent.clear();
        // worldLetters에서 mock sent 편지도 제거
        _worldLetters.removeWhere((l) => l.id.startsWith('sent_mock'));
        for (final j in decoded) {
          try {
            final letter = Letter.fromJson(j as Map<String, dynamic>);
            if (letter.id.startsWith('sent_mock')) continue; // 과거 목업 데이터 정리
            if (letter.senderId == _currentUser.id &&
                letter.segments.isNotEmpty) {
              final first = letter.segments.first;
              letter.segments[0] = RouteSegment(
                from: first.from,
                to: first.to,
                mode: first.mode,
                fromName: _l10n.stateMyLocation,
                toName: first.toName,
                fromType: first.fromType,
                toType: first.toType,
                estimatedMinutes: first.estimatedMinutes,
                progress: first.progress,
              );
            }
            if (letter.senderId == _currentUser.id &&
                letter.senderCountry == letter.destinationCountry &&
                letter.segments.isNotEmpty) {
              final domesticMin = _estimateDomesticDeliveryMinutes(
                letter.originLocation,
                letter.destinationLocation,
              );
              _rebalanceSegmentEstimatedMinutes(letter.segments, domesticMin);
              letter.arrivalTime = letter.sentAt.add(
                Duration(minutes: domesticMin),
              );
            }
            _sent.add(letter);
            // 배송 중인 편지는 worldLetters에도 추가
            if (letter.status == DeliveryStatus.inTransit ||
                letter.status == DeliveryStatus.nearYou) {
              _worldLetters.add(letter);
            }
          } catch (_) {}
        }
      }
      // decoded가 비어있으면 mock sent 편지를 그대로 유지
    }

    // 배송 중인 incoming 편지 복원 (daily 등 worldLetters)
    final incomingJsonRaw = prefs.getString('worldLettersIncoming');
    if (incomingJsonRaw != null) {
      for (final j
          in jsonDecode(_decryptStr(incomingJsonRaw, encKey)) as List) {
        try {
          final letter = Letter.fromJson(j as Map<String, dynamic>);
          // 이미 worldLetters에 없는 경우에만 추가
          if (!_worldLetters.any((l) => l.id == letter.id) &&
              !_inbox.any((l) => l.id == letter.id)) {
            _worldLetters.add(letter);
          }
        } catch (_) {}
      }
    }

    // 차단 목록 복원
    _blockedSenderIds.clear();
    _blockedSenderIds.addAll(prefs.getStringList('blocked') ?? []);
    _tempBlockedSenderIds.clear();
    _tempBlockedSenderIds.addAll(prefs.getStringList('temp_blocked') ?? []);

    // 유저가 뮤트한 브랜드 복원
    _mutedBrandIds.clear();
    _mutedBrandIds.addAll(prefs.getStringList('mutedBrandIds') ?? []);

    // 쿠폰 사용 완료 복원
    _redeemedLetterIds.clear();
    _redeemedLetterIds.addAll(prefs.getStringList('redeemedLetterIds') ?? []);

    // 브랜드 팔로우 복원
    _followedBrandIds.clear();
    _followedBrandIds.addAll(prefs.getStringList('followedBrandIds') ?? []);

    // Brand 사업자 인증 복원 (Build 127)
    _currentUser.businessRegistrationNumber =
        prefs.getString('brandBusinessNumber');
    if (_currentUser.businessRegistrationNumber?.isEmpty ?? false) {
      _currentUser.businessRegistrationNumber = null;
    }
    _currentUser.businessRegistrationDocUrl =
        prefs.getString('brandRegistrationDocUrl');
    if (_currentUser.businessRegistrationDocUrl?.isEmpty ?? false) {
      _currentUser.businessRegistrationDocUrl = null;
    }
    _currentUser.businessContactPhone = prefs.getString('brandContactPhone');
    if (_currentUser.businessContactPhone?.isEmpty ?? false) {
      _currentUser.businessContactPhone = null;
    }
    final brandVerifiedMs = prefs.getInt('brandVerifiedAtMs');
    _currentUser.brandVerifiedAt = brandVerifiedMs != null
        ? DateTime.fromMillisecondsSinceEpoch(brandVerifiedMs)
        : null;

    // 레벨 마일스톤 축하 소진 이력 복원 (Build 120)
    _celebratedMilestones
      ..clear()
      ..addAll(
        (prefs.getStringList('celebratedMilestones') ?? const [])
            .map(int.tryParse)
            .whereType<int>(),
      );

    // 첫 픽업 축하 소진 여부 복원. Build 117 마이그레이션: Build 115 이전부터
    // 이미 편지를 주운 사용자는 축하 키가 없으면서 픽업 이력이 있다. 그대로
    // 두면 다음 실행에서 "첫 픽업!" 모달이 오발사하므로, 키 미존재 + prefs 의
    // 픽업 이력이 비어있지 않으면 즉시 소진으로 백필. prefs 에서 직접 읽어서
    // 로드 순서 의존성을 피한다 (`_myPickedUpLetterIds` 채워지는 시점이 뒤쪽).
    _hasCelebratedFirstPickup =
        prefs.getBool('hasCelebratedFirstPickup') ?? false;
    if (!prefs.containsKey('hasCelebratedFirstPickup')) {
      final prior = prefs.getStringList('myPickedUpLetterIds') ?? const [];
      if (prior.isNotEmpty) {
        _hasCelebratedFirstPickup = true;
        await prefs.setBool('hasCelebratedFirstPickup', true);
      }
    }

    // 잠금 해제 카운터 복원
    _sentSinceLastUnlock = prefs.getInt('sentSinceLastUnlock') ?? 0;
    _dailySentCount = prefs.getInt('dailySentCount') ?? 0;
    _dailySentDateKey =
        prefs.getString('dailySentDateKey') ?? _dateKey(DateTime.now());
    _rolloverDailySendCounterIfNeeded();

    // 일일 스트릭 복원
    _currentStreak = prefs.getInt('streak_current') ?? 0;
    _longestStreak = prefs.getInt('streak_longest') ?? 0;
    _lastStreakCheckinDate = prefs.getString('streak_last_checkin') ?? '';
    _streakFreezeTokens = prefs.getInt('streak_freeze_tokens') ?? 0;
    _streakFreezeLastRefill =
        prefs.getString('streak_freeze_last_refill') ?? '';
    _sumPickupKm = prefs.getDouble('sum_pickup_km') ?? 0.0;
    _sumSentKm = prefs.getDouble('sum_sent_km') ?? 0.0;
    // 레거시 테스터: 거리 기록이 없을 때, 기존 활동량 기반으로 초기 추정 XP 를
    // 확보해 레벨 라벨이 신규 유저처럼 보이지 않도록 한다. 정확한 누적값은
    // 앞으로의 픽업·발송부터 실측이 덮어쓴다.
    if (_sumPickupKm == 0.0 && _currentUser.activityScore.receivedCount > 0) {
      _sumPickupKm = _currentUser.activityScore.receivedCount * 4000.0;
    }
    if (_sumSentKm == 0.0 && _currentUser.activityScore.sentCount > 0) {
      _sumSentKm = _currentUser.activityScore.sentCount * 6000.0;
    }
    _previousXpLevel = currentLevel;

    // 주간 챌린지 복원
    _weeklyChallengeCountries
      ..clear()
      ..addAll(prefs.getStringList('challenge_week_countries') ?? []);
    _weeklyChallengeWeekKey = prefs.getString('challenge_week_key') ?? '';
    _weeklyChallengeClaimed = prefs.getBool('challenge_week_claimed') ?? false;
    _challengeRewardBalance = prefs.getInt('challenge_reward_balance') ?? 0;
    // 주 경계 체크 (필요시 리셋)
    _rolloverWeeklyChallengeIfNeeded();
    _dailyPremiumExpressSentCount =
        prefs.getInt(PrefKeys.dailyPremiumExpressSentCount) ?? 0;
    _dailyPremiumExpressDateKey =
        prefs.getString(PrefKeys.dailyPremiumExpressDateKey) ??
        _dateKey(DateTime.now());
    _rolloverDailyPremiumExpressCounterIfNeeded();
    _dailyImageSentCount = prefs.getInt('dailyImageSentCount') ?? 0;
    _dailyImageDateKey =
        prefs.getString('dailyImageDateKey') ?? _dateKey(DateTime.now());
    _rolloverDailyImageCounterIfNeeded();
    _monthlySentCount = prefs.getInt('monthlySentCount') ?? 0;
    _monthlyDateKey =
        prefs.getString('monthlyDateKey') ?? _monthKey(DateTime.now());
    _pendingDMCount = prefs.getInt('pendingDMCount') ?? 0;
    _brandExtraMonthlyQuota =
        prefs.getInt(PrefKeys.brandExtraMonthlyQuota) ?? 0;
    _brandExactDropCredits = prefs.getInt('brandExactDropCredits') ?? 0;
    _inviteRewardCredits = prefs.getInt(PrefKeys.inviteRewardCredits) ?? 0;
    final restoredOwnInviteCode = prefs.getString(PrefKeys.inviteCode);
    _inviteCode =
        (restoredOwnInviteCode != null && restoredOwnInviteCode.isNotEmpty)
        ? restoredOwnInviteCode
        : _deriveInviteCode();
    final restoredInviteCode = prefs.getString(PrefKeys.inviteAppliedCode);
    _appliedInviteCode =
        (restoredInviteCode != null && restoredInviteCode.isNotEmpty)
        ? restoredInviteCode
        : null;
    final inviteRewardAtMs = prefs.getInt(PrefKeys.inviteRewardAtEpochMs) ?? 0;
    _lastInviteRewardAt = inviteRewardAtMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(inviteRewardAtMs)
        : null;
    _rolloverMonthlySendCounterIfNeeded();
    _currentUser.towerColor = prefs.getString(PrefKeys.towerColor) ?? '#FFD700';
    _currentUser.towerAccentEmoji = prefs.getString(PrefKeys.towerAccentEmoji);
    _currentUser.towerRoofStyle = prefs.getInt('towerRoofStyle') ?? 0;
    _currentUser.towerWindowStyle = prefs.getInt('towerWindowStyle') ?? 0;
    _currentUser.isBrand = prefs.getBool(PrefKeys.isBrand) ?? false;
    _currentUser.isPremium = prefs.getBool(PrefKeys.purchaseIsPremium) ?? false;
    _currentUser.brandName = prefs.getString(PrefKeys.brandName);
    final profileImagePath = prefs.getString(PrefKeys.profileImagePath);
    _currentUser.profileImagePath = (profileImagePath?.isNotEmpty ?? false)
        ? profileImagePath
        : null;
    final nicknameChangedAtEpochMs =
        prefs.getInt('nicknameChangedAtEpochMs') ?? 0;
    _lastNicknameChangedAt = nicknameChangedAtEpochMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(nicknameChangedAtEpochMs)
        : null;
    final displayThemeModeRaw = prefs.getString('displayThemeMode');
    _displayThemeMode = DisplayThemeMode.values.firstWhere(
      (m) => m.name == displayThemeModeRaw,
      orElse: () => DisplayThemeMode.auto,
    );

    // Build 218: 카테고리 선호 복원
    final savedPreferredCategory =
        prefs.getString('preferredCategoryKey') ?? '';
    _currentUser.preferredCategoryKey =
        savedPreferredCategory.isEmpty ? null : savedPreferredCategory;

    // 타워 이름 복원
    final savedTowerName = prefs.getString('customTowerName') ?? '';
    if (savedTowerName.isNotEmpty) {
      _currentUser.customTowerName = savedTowerName;
    }
    // 언어 코드 복원 (빈 값이면 country에서 재파생)
    final savedLangCode = prefs.getString('languageCode') ?? '';
    if (savedLangCode.isNotEmpty) {
      _currentUser.languageCode = savedLangCode;
    }

    // 주변 편지 줍기 쿨다운 복원
    final lastPickupMs = prefs.getInt('lastNearbyPickupAtMs') ?? 0;
    _lastNearbyPickupAt = lastPickupMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(lastPickupMs)
        : null;

    // 이미 줍기한 편지 ID 목록 복원
    final pickedIds = prefs.getStringList('myPickedUpLetterIds') ?? [];
    _myPickedUpLetterIds.addAll(pickedIds);

    // 서버 동기화 중복 방지용 ID 캐시 초기화 (로컬 편지 모두 등록)
    _seenLetterIds
      ..addAll(_inbox.map((l) => l.id))
      ..addAll(_worldLetters.map((l) => l.id))
      ..addAll(_sent.map((l) => l.id));

    final purgedExpiredReadLetters = _purgeExpiredReadLetters();

    // 활동 점수 복원
    final scoreJson = prefs.getString('activityScore');
    if (scoreJson != null) {
      try {
        final score = ActivityScore.fromJson(
          jsonDecode(scoreJson) as Map<String, dynamic>,
        );
        _currentUser.activityScore.receivedCount = score.receivedCount;
        _currentUser.activityScore.replyCount = score.replyCount;
        _currentUser.activityScore.sentCount = score.sentCount;
        _currentUser.activityScore.likeCount = score.likeCount;
        _currentUser.activityScore.ratingTotal = score.ratingTotal;
        _currentUser.activityScore.ratingCount = score.ratingCount;
      } catch (_) {}
    }

    // DM/채팅 복원
    final chatJson = prefs.getString('chatSessions');
    if (chatJson != null) {
      _chatSessions.clear();
      final map = jsonDecode(chatJson) as Map<String, dynamic>;
      for (final entry in map.entries) {
        try {
          _chatSessions[entry.key] = ChatSession.fromJson(
            entry.value as Map<String, dynamic>,
          );
        } catch (_) {}
      }
    }
    final dmJson = prefs.getString('dmMessages');
    if (dmJson != null) {
      _dmMessages.clear();
      final map = jsonDecode(dmJson) as Map<String, dynamic>;
      for (final entry in map.entries) {
        try {
          _dmMessages[entry.key] = (entry.value as List)
              .map((j) => DirectMessage.fromJson(j as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
    }

    if (kDebugMode) {
      await _checkAndDeliverDailyLetter();
      await sendTestWorldLetters();
    }

    // _initMockData()가 추가한 mock 편지 정리 — 실제 사용자 데이터 로드 후 제거
    // (kDebugMode 빌드에서 mock 데이터가 실 계정에 노출되지 않도록)
    _worldLetters.removeWhere((l) => l.senderId.startsWith('mock_'));
    _inbox.removeWhere((l) => l.senderId.startsWith('mock_'));

    if (purgedExpiredReadLetters) {
      _saveToPrefs();
    }

    // Build 253: SharedPreferences 스키마 버전 — iCloud/Android 백업 복구 시
    // 옛 키 형식이 들어와도 안전하게 무시/마이그레이션. 현재 schema=1 으로
    // 시작. 추후 키 이름이 바뀌거나 형식이 변경되면 schema 증가시키고
    // _migrateSharedPrefs(oldVer, newVer) 분기 추가.
    final schemaVer = prefs.getInt('shared_prefs_schema_version') ?? 1;
    if (schemaVer < 1) {
      // 미래의 마이그레이션 분기 (현재 v1 베이스라인)
    }
    if (schemaVer != 1) {
      await prefs.setInt('shared_prefs_schema_version', 1);
    }

    // AI 자동 편지 생성 (하루 5통)
    _lastAiLetterDateKey = prefs.getString('lastAiLetterDateKey') ?? '';
    _generateDailyAiLetters();

    await _ensureInviteIdentityOnServer();

    // ── Firebase 익명 로그인 + 서버 편지 동기화 ─────────────────────────────
    await _initFirebaseAndSync();

    // Build 253: 시스템 시간 조작 감지 (client-side mitigation).
    // 마지막 앱 실행 시각 (lastSeenAt) 기록 → 다음 실행 시 현재 시각이 그보다
    // 과거이거나 7일 이상 미래로 점프했으면 "시간 변경 감지" 로 logged.
    // 향후 anti-cheat 백엔드 연동 시 신호로 활용 가능.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lastSeenMs = prefs.getInt('lastSeenAtMs') ?? 0;
    if (lastSeenMs > 0) {
      final delta = nowMs - lastSeenMs;
      if (delta < -60000) {
        // 1분 이상 거꾸로 — 명백한 조작 가능성
        if (kDebugMode) debugPrint('[CLOCK] backward jump detected: ${delta}ms');
        _clockTamperingDetected = true;
      } else if (delta > 7 * 24 * 3600 * 1000) {
        // 7일 이상 미래 점프 — 의심 (단, 정상적으로 7일 이상 안 켰을 가능성도 있음)
        if (kDebugMode) debugPrint('[CLOCK] suspicious forward jump: ${delta}ms');
      }
    }
    await prefs.setInt('lastSeenAtMs', nowMs);

    // ── 시간 기반 편지 상태 보정 ─────────────────────────────────────────────
    // 앱이 꺼져 있던 동안 arrivalTime이 지난 편지를 즉시 도착 처리
    _reconcileLetterStatuses();

    // ── 매일 오전 8시 "오늘의 편지" 리마인더 재예약 ─────────────────────────
    // 사용자가 opt-in한 경우에만 예약. 재시작·시간대 변경·DST 보정을 겸해
    // 매 앱 실행마다 다시 스케줄한다. (Opt-in 기본값은 false)
    if (prefs.getBool('notify_daily_letter') ?? false) {
      NotificationService.scheduleDailyLetterReminder(
        langCode: _currentUser.languageCode,
      );
    }

    // ── 도착 1시간 전 카운트다운 재예약 ─────────────────────────────────────
    _rescheduleArrivalCountdown();

    notifyListeners();
  }

  /// 가장 임박한 미래 도착 편지 1건에 대해 도착 1시간 전 알림 스케줄.
  /// 신규 편지 수신·앱 실행·AI 편지 생성 후에 호출한다.
  void _rescheduleArrivalCountdown() {
    try {
      final now = DateTime.now();
      // 2시간 이상 여유가 있는 편지만 — 리드타임이 너무 짧으면 무의미
      Letter? next;
      for (final l in [..._worldLetters, ..._inbox]) {
        // 내가 보낸 편지는 제외 — 국내 근거리 발송(예: 서울→인천)이 목적지
        // 100km 필터를 통과해 "도착 예정" 푸시로 잘못 걸리는 문제 방지
        if (l.senderId == _currentUser.id) continue;
        if (l.status != DeliveryStatus.inTransit) continue;
        final at = l.arrivalTime;
        if (at == null) continue;
        if (at.isBefore(now.add(const Duration(hours: 2)))) continue;
        // 목적지가 내 계정 위치 근방인지로 "나에게 오는 편지" 판단
        final distKm = l.destinationLocation.distanceTo(
              LatLng(_currentUser.latitude, _currentUser.longitude),
            ) /
            1000.0;
        if (distKm > 100) continue;
        if (next == null || at.isBefore(next.arrivalTime!)) {
          next = l;
        }
      }
      if (next == null) {
        NotificationService.cancelArrivalCountdown();
        return;
      }
      NotificationService.scheduleArrivalCountdown(
        arrivalTime: next.arrivalTime!,
        senderCountry: next.senderCountry,
        senderFlag: next.senderCountryFlag,
        langCode: _currentUser.languageCode,
      );
    } catch (_) {}
  }

  /// 앱 재시작 후 arrivalTime이 이미 지난 편지들의 상태를 즉시 보정한다.
  /// (delivery timer 5초 대기 없이 로드 직후 실행)
  void _reconcileLetterStatuses() {
    final now = DateTime.now();
    bool changed = false;
    final List<Letter> dailyToInbox = [];

    for (final letter in _worldLetters) {
      // 이미 도착 처리된 편지는 건너뜀
      if (letter.status == DeliveryStatus.deliveredFar ||
          letter.status == DeliveryStatus.nearYou ||
          letter.status == DeliveryStatus.delivered ||
          letter.status == DeliveryStatus.read) {
        continue;
      }
      if (letter.status != DeliveryStatus.inTransit) continue;

      // 세그먼트 진행도를 현재 시각에 맞춰 동기화
      _syncLetterProgressWithClock(letter, now);

      final arrived = letter.arrivalTime != null
          ? !now.isBefore(letter.arrivalTime!)
          : letter.overallProgress >= 0.999;

      if (arrived) {
        if (letter.id.startsWith('daily_')) {
          letter.status = DeliveryStatus.delivered;
          letter.arrivedAt ??= now;
          dailyToInbox.add(letter);
          changed = true;
          continue;
        }
        final dist = letter.destinationLocation.distanceTo(
          LatLng(_currentUser.latitude, _currentUser.longitude),
        );
        if (dist <= pickupRadiusMeters) {
          letter.status = DeliveryStatus.nearYou;
          _hasNearbyAlert = true;
        } else {
          letter.status = DeliveryStatus.deliveredFar;
        }
        letter.arrivedAt ??= now;
        changed = true;
      }
    }

    // daily 편지: worldLetters → inbox 이동
    for (final l in dailyToInbox) {
      _worldLetters.removeWhere((x) => x.id == l.id);
      _inbox.add(l);
      _currentUser.activityScore.receivedCount++;
    }

    // _sent 리스트의 편지 상태도 동기화 (_worldLetters와 같은 객체를 참조하지만
    // worldLetters에 없는 sent 편지가 있을 수 있으므로 별도 처리)
    for (final letter in _sent) {
      if (letter.status != DeliveryStatus.inTransit) continue;
      _syncLetterProgressWithClock(letter, now);
      final arrived = letter.arrivalTime != null
          ? !now.isBefore(letter.arrivalTime!)
          : letter.overallProgress >= 0.999;
      if (arrived) {
        letter.status = DeliveryStatus.delivered;
        letter.arrivedAt ??= now;
        changed = true;
      }
    }

    if (changed) {
      _saveToPrefs();
      // Build 218: 백그라운드에서 진행이 catch-up 됐어도 UI 가 안 바뀌면
      // "편지가 가다가 멈춰 보이는" 체감 버그가 그대로 남는다. 명시적으로
      // notify 해서 지도/수집첩이 즉시 새 상태로 다시 그려지게.
      notifyListeners();
    }
  }

  // ── Firebase 익명 로그인 + 서버 동기화 ────────────────────────────────────────
  Timer? _worldLetterSyncTimer;

  Future<void> _initFirebaseAndSync() async {
    if (!FirebaseConfig.kFirebaseEnabled) return;
    // 익명 로그인 (Firestore 접근용 ID 토큰 획득)
    final ok = await FirebaseAuthService.signInAnonymously();
    if (!ok) {
      if (kDebugMode) debugPrint('[Firebase] 익명 로그인 실패 — 서버 동기화 스킵');
      return;
    }
    // 내 프로필을 Firestore에 저장 (다른 테스터가 지도에서 볼 수 있도록)
    _saveUserToFirestore();
    // 서버에서 다른 유저들의 편지 가져와서 지도에 표시
    await syncWorldLettersFromServer();
    // 30초마다 서버 편지 동기화 (다른 테스터가 보낸 새 편지를 반영)
    _worldLetterSyncTimer?.cancel();
    _worldLetterSyncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => syncWorldLettersFromServer(),
    );
  }

  /// 서버에서 모든 유저의 최근 편지를 가져와 지도에 표시
  Future<void> syncWorldLettersFromServer() async {
    if (!FirebaseConfig.kFirebaseEnabled) return;
    if (!FirebaseAuthService.isSignedIn) return;
    try {
      final docs = await FirestoreService.queryCollection(
        'letters',
        orderBy: 'sentAt desc',
        limit: 50,
      );
      if (docs.isEmpty) return;

      final now = DateTime.now();
      bool changed = false;

      for (final doc in docs) {
        final data = FirestoreService.fromFirestoreDoc(doc);
        final letterId = data['id'] as String? ?? '';
        if (letterId.isEmpty) continue;
        // 자기가 보낸 편지는 건너뜀 (이미 로컬에 있음)
        if (data['senderId'] == _currentUser.id) continue;
        // 이미 로컬에 있으면 건너뜀
        if (_worldLetters.any((l) => l.id == letterId) ||
            _inbox.any((l) => l.id == letterId)) continue;

        // 서버 데이터로 Letter 객체 생성
        final letter = _letterFromFirestoreData(data, now);
        if (letter == null) continue;

        // 지도에 추가 (배송 중이든 도착했든 모두 표시)
        _worldLetters.add(letter);
        changed = true;

        if (kDebugMode) {
          debugPrint('[Firebase] 월드 편지 추가: ${letter.id} '
              '${letter.senderCountryFlag}→${letter.destinationCountryFlag} '
              '(${letter.status.name})');
        }
      }

      if (changed) {
        _saveToPrefs();
        notifyListeners();
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Firebase] 월드 편지 동기화 실패: $e\n$st');
    }
  }

  /// Firestore 문서 데이터를 Letter 객체로 변환
  Letter? _letterFromFirestoreData(Map<String, dynamic> data, DateTime now) {
    try {
      final originLat = (data['originLat'] as num?)?.toDouble() ?? 0;
      final originLng = (data['originLng'] as num?)?.toDouble() ?? 0;
      final destLat = (data['destLat'] as num?)?.toDouble() ?? 0;
      final destLng = (data['destLng'] as num?)?.toDouble() ?? 0;
      final fromCity = LatLng(originLat, originLng);
      final toCity = LatLng(destLat, destLng);
      final sentAtStr = data['sentAt'] as String? ?? '';
      final sentAt = DateTime.tryParse(sentAtStr) ?? now;
      final totalMin = (data['estimatedTotalMinutes'] as num?)?.toInt() ?? 60;
      final arrivalTime = sentAt.add(Duration(minutes: totalMin));

      // 경로 세그먼트 재생성
      final senderCountry = data['senderCountry'] as String? ?? '';
      final destCountry = data['destinationCountry'] as String? ?? '';
      final segments = LogisticsHubs.buildRoute(
        fromCountry: senderCountry,
        fromCity: fromCity,
        toCountry: destCountry,
        toCity: toCity,
        fromCityName: data['senderName'] as String? ?? '',
        preferAir: true,
      );
      _rebalanceSegmentEstimatedMinutes(segments, totalMin);

      // 이미 도착했는지 확인
      final arrived = now.isAfter(arrivalTime);
      final status = arrived ? DeliveryStatus.delivered : DeliveryStatus.inTransit;

      // Build 135: 쿠폰/교환권 메타 복원. senderTier 문자열 → enum.
      LetterSenderTier tier = LetterSenderTier.free;
      final tierStr = data['senderTier'] as String?;
      if (tierStr == 'brand') {
        tier = LetterSenderTier.brand;
      } else if (tierStr == 'premium') {
        tier = LetterSenderTier.premium;
      }
      final catKey = data['category'] as String?;
      final category = LetterCategoryExt.fromKey(catKey);
      final redInfoRaw = data['redemptionInfo'] as String?;
      final redInfo = (redInfoRaw == null || redInfoRaw.isEmpty)
          ? null
          : redInfoRaw;
      final redExpiresStr = data['redemptionExpiresAt'] as String?;
      final redExpiresAt = redExpiresStr == null
          ? null
          : DateTime.tryParse(redExpiresStr);
      final expStr = data['expiresAt'] as String?;
      final expAt = expStr == null ? null : DateTime.tryParse(expStr);

      return Letter(
        id: data['id'] as String? ?? 'srv_${now.millisecondsSinceEpoch}',
        senderId: data['senderId'] as String? ?? '',
        senderName: data['senderName'] as String? ?? '???',
        senderCountry: senderCountry,
        senderCountryFlag: data['senderCountryFlag'] as String? ?? '🏳️',
        content: data['content'] as String? ?? '',
        originLocation: fromCity,
        destinationLocation: toCity,
        destinationCountry: destCountry,
        destinationCountryFlag: data['destinationCountryFlag'] as String? ?? '',
        destinationCity: data['destinationCity'] as String?,
        segments: segments,
        currentSegmentIndex: 0,
        status: status,
        sentAt: sentAt,
        arrivalTime: arrivalTime,
        socialLink: data['socialLink'] as String?,
        estimatedTotalMinutes: totalMin,
        paperStyle: (data['paperStyle'] as num?)?.toInt() ?? 0,
        fontStyle: (data['fontStyle'] as num?)?.toInt() ?? 0,
        imageUrl: data['imageUrl'] as String?,
        arrivedAt: arrived ? arrivalTime : null,
        deliveryEmoji: data['deliveryEmoji'] as String?,
        isAnonymous: data['isAnonymous'] as bool? ?? true,
        category: category,
        redemptionInfo: redInfo,
        redemptionExpiresAt: redExpiresAt,
        acceptsReplies: data['acceptsReplies'] as bool? ?? true,
        senderIsBrand: data['senderIsBrand'] as bool? ?? (tier == LetterSenderTier.brand),
        senderTier: tier,
        brandUniquePerUser: data['brandUniquePerUser'] as bool? ?? false,
        expiresAt: expAt,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Firebase] Letter 변환 실패: $e\n$st');
      return null;
    }
  }

  /// 보낸 편지를 Firestore에 저장 (다른 유저가 수신할 수 있도록)
  Future<void> _saveLetterToFirestore(Letter letter) async {
    if (!FirebaseConfig.kFirebaseEnabled) return;
    if (!FirebaseAuthService.isSignedIn) return;
    try {
      // Build 207: 익명 편지의 발신자 정보를 서버 사이드에서 stripping.
      // 이전엔 isAnonymous=true 여도 senderId/Name 가 그대로 Firestore 에
      // 들어가 letter.id 만 알면 발신자 역추적 가능. 클라이언트 + Firestore
      // rules 양쪽에서 enforcement.
      //   senderId  → "anon_<letterId>" (per-letter unique, 역추적 불가)
      //   senderName → 고정 sentinel '__anonymous__' (UI 가 i18n 으로 치환)
      // GPS origin 도 정확한 위치 노출 차단을 위해 destination 좌표로 통일.
      final isAnon = letter.isAnonymous;
      final firestoreSenderId = isAnon ? 'anon_${letter.id}' : letter.senderId;
      final firestoreSenderName = isAnon ? '__anonymous__' : letter.senderName;
      final firestoreOriginLat = isAnon
          ? letter.destinationLocation.latitude
          : letter.originLocation.latitude;
      final firestoreOriginLng = isAnon
          ? letter.destinationLocation.longitude
          : letter.originLocation.longitude;
      await FirestoreService.setDocument('letters/${letter.id}', {
        'id': letter.id,
        'senderId': firestoreSenderId,
        'senderName': firestoreSenderName,
        'senderCountry': letter.senderCountry,
        'senderCountryFlag': letter.senderCountryFlag,
        'content': letter.content,
        'originLat': firestoreOriginLat,
        'originLng': firestoreOriginLng,
        'destLat': letter.destinationLocation.latitude,
        'destLng': letter.destinationLocation.longitude,
        'destinationCountry': letter.destinationCountry,
        'destinationCountryFlag': letter.destinationCountryFlag,
        'destinationCity': letter.destinationCity ?? '',
        'sentAt': letter.sentAt.toIso8601String(),
        'estimatedTotalMinutes': letter.estimatedTotalMinutes,
        'paperStyle': letter.paperStyle,
        'fontStyle': letter.fontStyle,
        'imageUrl': letter.imageUrl ?? '',
        'socialLink': letter.socialLink ?? '',
        'letterType': letter.letterType.name,
        'status': letter.status.name,
        'senderTier': letter.senderTier.name,
        // Build 135: 쿠폰/교환권 필드 전체 동기화. 이전엔 누락돼 다른 기기에서
        // 주운 수신자가 할인 코드·교환권 이미지·유효기간을 볼 수 없었음.
        'category': letter.category.key,
        'redemptionInfo': letter.redemptionInfo ?? '',
        if (letter.redemptionExpiresAt != null)
          'redemptionExpiresAt':
              letter.redemptionExpiresAt!.toIso8601String(),
        'acceptsReplies': letter.acceptsReplies,
        'senderIsBrand': letter.senderIsBrand,
        'brandUniquePerUser': letter.brandUniquePerUser,
        if (letter.expiresAt != null)
          'expiresAt': letter.expiresAt!.toIso8601String(),
        'isAnonymous': letter.isAnonymous,
        if (letter.deliveryEmoji != null) 'deliveryEmoji': letter.deliveryEmoji,
      });
      if (kDebugMode) {
        debugPrint('[Firebase] 편지 업로드 완료: ${letter.id} → ${letter.destinationCountry}');
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Firebase] 편지 업로드 실패: $e\n$st');
    }
  }

  // ╔══════════════════════════════════════════════════════════════════════╗
  // ║ 서버 동기화 (수신 편지 + 다른 온라인 사용자)                         ║
  // ╚══════════════════════════════════════════════════════════════════════╝

  /// 앱 시작 / 로그인 직후 한 번 호출.
  /// 로컬에 없거나 손실된 데이터를 Firestore 에서 복원한다.
  ///
  /// 보존 대상:
  /// - 내 프로필·타워 커스터마이징 (users/{myId})
  /// - 내가 보낸 편지 (letters where senderId == myId)
  /// - 활동 점수 (users/{myId} 의 *Count 필드)
  ///
  /// 복원 정책:
  /// - 로컬 > 서버. 즉 로컬에 동일 ID 편지가 있으면 서버 버전으로 덮어쓰지 않음
  /// - 로컬에 아예 없는 항목만 추가 → 오프라인 편집 내역 보호
  Future<void> restoreFromServerIfMissing() async {
    if (!FirebaseConfig.kFirebaseEnabled) return;
    if (_currentUser.id.isEmpty || _currentUser.id == 'guest') return;
    try {
      await Future.wait([
        _restoreProfileFromServer(),
        _restoreSentLettersFromServer(),
      ]);
    } catch (e) {
      if (kDebugMode) debugPrint('[Restore] 실패: $e');
    }
  }

  /// 내 유저 문서(타워 커스텀·활동 점수)를 로컬에 병합.
  /// 로컬 값이 더 최신(서버보다 activityScore 합이 더 큼)이면 유지.
  Future<void> _restoreProfileFromServer() async {
    try {
      final doc = await FirestoreService.getDocument(
        'users/${_currentUser.id}',
      );
      if (doc == null) return;
      final map = FirestoreService.fromFirestoreDoc(doc);

      final serverTower = map['customTowerName'] as String?;
      final serverColor = map['towerColor'] as String?;
      final serverAccent = map['towerAccentEmoji'] as String?;
      final serverRoof = (map['towerRoofStyle'] as num?)?.toInt();
      final serverWindow = (map['towerWindowStyle'] as num?)?.toInt();

      bool updated = false;
      // 로컬에 비어 있으면 서버 값으로 채우기
      if ((_currentUser.customTowerName ?? '').isEmpty &&
          serverTower != null &&
          serverTower.isNotEmpty) {
        _currentUser.customTowerName = serverTower;
        updated = true;
      }
      if (_currentUser.towerColor == '#FFD700' &&
          serverColor != null &&
          serverColor.isNotEmpty &&
          serverColor != '#FFD700') {
        _currentUser.towerColor = serverColor;
        updated = true;
      }
      if (_currentUser.towerAccentEmoji == null &&
          serverAccent != null &&
          serverAccent.isNotEmpty) {
        _currentUser.towerAccentEmoji = serverAccent;
        updated = true;
      }
      if (_currentUser.towerRoofStyle == 0 &&
          serverRoof != null &&
          serverRoof > 0) {
        _currentUser.towerRoofStyle = serverRoof;
        updated = true;
      }
      if (_currentUser.towerWindowStyle == 0 &&
          serverWindow != null &&
          serverWindow > 0) {
        _currentUser.towerWindowStyle = serverWindow;
        updated = true;
      }

      // 활동 점수 — 서버가 더 크면 그 값 채택 (편지 발송 기록 손실 방지)
      final serverReceived = (map['receivedCount'] as num?)?.toInt() ?? 0;
      final serverReply = (map['replyCount'] as num?)?.toInt() ?? 0;
      final serverSent = (map['sentCount'] as num?)?.toInt() ?? 0;
      final serverLike = (map['likeCount'] as num?)?.toInt() ?? 0;
      if (serverReceived > _currentUser.activityScore.receivedCount) {
        _currentUser.activityScore.receivedCount = serverReceived;
        updated = true;
      }
      if (serverReply > _currentUser.activityScore.replyCount) {
        _currentUser.activityScore.replyCount = serverReply;
        updated = true;
      }
      if (serverSent > _currentUser.activityScore.sentCount) {
        _currentUser.activityScore.sentCount = serverSent;
        updated = true;
      }
      if (serverLike > _currentUser.activityScore.likeCount) {
        _currentUser.activityScore.likeCount = serverLike;
        updated = true;
      }

      if (updated) {
        notifyListeners();
        _saveToPrefs();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Restore] 프로필 실패: $e');
    }
  }

  /// Build 216: Brand 가 보낸 편지 중 가장 최근에 누군가 픽업한 letter.
  /// Build 248: 정보 불일치 픽스 — 배너 카피 "캠페인이 픽업됐어요" 와 정합.
  /// 이전엔 delivered/nearYou/deliveredFar (단순 "도착") 도 포함해 misleading.
  /// 진짜 "픽업" = 수신자가 줍고 본문 읽음 (status=read) OR readCount>0
  /// (다중 수신자 letter 의 경우 누군가 픽업했음).
  /// readAt 기준 정렬, 없으면 null (배너 미노출).
  Letter? get brandMostRecentlyPickedUpLetter {
    if (!_currentUser.isBrand) return null;
    Letter? best;
    DateTime? bestAt;
    for (final l in _sent) {
      if (!l.senderIsBrand) continue;
      final isTrulyPicked =
          l.status == DeliveryStatus.read || l.readCount > 0;
      if (!isTrulyPicked) continue;
      final at = l.readAt ?? l.arrivedAt;
      if (at == null) continue;
      if (bestAt == null || at.isAfter(bestAt)) {
        bestAt = at;
        best = l;
      }
    }
    return best;
  }

  /// Build 158: ExactDrop 화면에서 보여줄 "최근 발송 좌표" 추천 리스트.
  /// 로컬 `_sent` 중 Brand 편지 역순 N개 destination. 서버 쿼리 불필요.
  /// 과거 캠페인 좌표를 재활용하면 동일 동네 유저에게 반복 노출 가능.
  List<LatLng> brandRecentDropCoordinates({int limit = 3}) {
    if (!_currentUser.isBrand) return const [];
    final coords = <LatLng>[];
    final seen = <String>{};
    for (final l in _sent.reversed) {
      if (!l.senderIsBrand) continue;
      final key =
          '${l.destinationLocation.latitude.toStringAsFixed(3)},'
          '${l.destinationLocation.longitude.toStringAsFixed(3)}';
      if (seen.contains(key)) continue;
      seen.add(key);
      coords.add(l.destinationLocation);
      if (coords.length >= limit) break;
    }
    return coords;
  }

  /// Build 138: 브랜드 분석 대시보드 데이터. Firestore 에서 내가 보낸
  /// 편지들을 쿼리해 총 발송·총 픽업·총 사용·전환율 집계. Brand 유저가
  /// 프로필 화면에서 자신의 캠페인 ROI 를 볼 수 있게 함.
  ///
  /// 네트워크 실패 시 `null` 반환 → UI 에서 "오프라인" 표시.
  Future<BrandAnalytics?> fetchBrandAnalytics() async {
    if (!_currentUser.isBrand) return null;
    if (!FirebaseConfig.kFirebaseEnabled) return null;
    try {
      final docs = await FirestoreService.queryWhereEquals(
        collectionId: 'letters',
        field: 'senderId',
        value: _currentUser.id,
        limit: 500,
      );
      int totalSent = 0;
      int totalPicked = 0;
      int totalRedeemed = 0;
      int couponSent = 0;
      int voucherSent = 0;
      final countryPicks = <String, int>{};
      // Build 157: 최근 7일 일별 발송량. 오늘(=index 6) 까지 거슬러 7일치.
      // 현재 Firestore 에 per-pickup timestamp 가 없어 "픽업 수" 는 일자별
      // 귀속 불가 → 발송 리듬만 시각화 (brand activity 추이).
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final List<int> daily = List<int>.filled(7, 0);
      for (final doc in docs) {
        final map = FirestoreService.fromFirestoreDoc(doc);
        totalSent++;
        final picks = (map['pickupCount'] as num?)?.toInt() ?? 0;
        final redeemed = (map['redeemedCount'] as num?)?.toInt() ?? 0;
        totalPicked += picks;
        totalRedeemed += redeemed;
        final cat = map['category'] as String?;
        if (cat == 'coupon') couponSent++;
        if (cat == 'voucher') voucherSent++;
        final country = map['destinationCountry'] as String? ?? '';
        if (country.isNotEmpty && picks > 0) {
          countryPicks[country] = (countryPicks[country] ?? 0) + picks;
        }
        // sentAt 이 ISO 문자열 — Letter.toJson 직렬화 기준 (app_state.dart 2712)
        final sentAtStr = map['sentAt'] as String? ?? '';
        final sentAt = DateTime.tryParse(sentAtStr);
        if (sentAt != null) {
          final sentDay = DateTime(sentAt.year, sentAt.month, sentAt.day);
          final delta = todayStart.difference(sentDay).inDays;
          if (delta >= 0 && delta < 7) {
            // delta=0 → 오늘 (index 6), delta=6 → 6일 전 (index 0)
            daily[6 - delta]++;
          }
        }
      }
      return BrandAnalytics(
        totalSent: totalSent,
        totalPicked: totalPicked,
        totalRedeemed: totalRedeemed,
        couponSent: couponSent,
        voucherSent: voucherSent,
        countryPicks: countryPicks,
        dailySent: daily,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Analytics] fetchBrandAnalytics 실패: $e\n$st');
      return null;
    }
  }

  /// 내가 보낸 편지를 Firestore 에서 조회해 _sent 에 보충.
  /// 이미 로컬에 있는 ID 는 건너뛴다.
  Future<void> _restoreSentLettersFromServer() async {
    try {
      final docs = await FirestoreService.queryWhereEquals(
        collectionId: 'letters',
        field: 'senderId',
        value: _currentUser.id,
        limit: 100,
      );
      if (docs.isEmpty) return;
      int added = 0;
      for (final doc in docs) {
        final map = FirestoreService.fromFirestoreDoc(doc);
        final letter = _letterFromFirestore(map);
        if (letter == null) continue;
        if (_sent.any((l) => l.id == letter.id)) continue;
        if (_worldLetters.any((l) => l.id == letter.id)) continue;
        _sent.add(letter);
        // 아직 배송 중이면 worldLetters 에도 추가 (지도에 궤적 표시)
        if (letter.status != DeliveryStatus.delivered) {
          _worldLetters.add(letter);
        }
        added++;
      }
      if (added > 0) {
        notifyListeners();
        _saveToPrefs();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Restore] 보낸 편지 실패: $e');
    }
  }

  /// 앱 시작 직후 호출. 편지 수신 + 다른 사용자 타워 동기화를 각각 분리된
  /// 주기로 시작. Firebase 가 꺼져 있거나 사용자가 설정되지 않았으면 NOP.
  void startServerSync() {
    if (_syncTimer != null || _mapSyncTimer != null) return;
    if (!FirebaseConfig.kFirebaseEnabled) return;
    if (_currentUser.id.isEmpty || _currentUser.id == 'guest') return;
    _syncStartedAt = DateTime.now();
    _syncPaused = false;
    // 첫 1회 즉시 실행
    unawaited(_runLetterSync());
    unawaited(_runMapSync());
    // 편지 수신: 적응형 주기 (처음 5분 30초 → 이후 90초)
    _scheduleNextLetterSync();
    // 지도 타워: 고정 180초 (자주 안 바뀜)
    _mapSyncTimer = Timer.periodic(
      _mapSyncInterval,
      (_) => _runMapSync(),
    );
  }

  /// 편지 동기화 타이머를 현재 적응 상태에 맞춰 다시 스케줄.
  /// 5분 경계를 넘어가면 빠른(30초) → 느린(90초) 주기로 전환.
  void _scheduleNextLetterSync() {
    _syncTimer?.cancel();
    final interval = _currentLetterSyncInterval;
    _syncTimer = Timer.periodic(interval, (_) async {
      await _runLetterSync();
      // 빠른 모드 구간을 막 벗어났다면 타이머 재생성
      if (_shouldSwitchToSlowMode(interval)) {
        _scheduleNextLetterSync();
      }
    });
  }

  Duration get _currentLetterSyncInterval {
    final started = _syncStartedAt;
    if (started == null) return _letterSyncSlow;
    final elapsed = DateTime.now().difference(started);
    return elapsed < _fastModeDuration
        ? _letterSyncFast
        : _letterSyncSlow;
  }

  bool _shouldSwitchToSlowMode(Duration currentInterval) {
    // 빠른 주기로 돌고 있는데 이제 5분이 지났으면 느린 주기로 전환
    return currentInterval == _letterSyncFast &&
        _currentLetterSyncInterval == _letterSyncSlow;
  }

  /// 로그아웃 등으로 세션이 끊겼을 때 호출.
  void stopServerSync() {
    _syncTimer?.cancel();
    _mapSyncTimer?.cancel();
    _syncTimer = null;
    _mapSyncTimer = null;
    _syncStartedAt = null;
    _syncPaused = false;
  }

  /// 앱이 백그라운드로 들어갈 때 호출 (배터리·비용 절약).
  /// WidgetsBindingObserver.didChangeAppLifecycleState 에서 연동.
  void pauseServerSyncForBackground() {
    _syncPaused = true;
  }

  /// 앱이 포그라운드로 복귀할 때 호출. 즉시 1회 동기화.
  void resumeServerSyncFromBackground() {
    if (!_syncPaused) return;
    _syncPaused = false;
    if (!FirebaseConfig.kFirebaseEnabled) return;
    if (_currentUser.id.isEmpty || _currentUser.id == 'guest') return;
    // 사용자 복귀한 순간엔 즉시 fetch 해서 새 편지 체감 시간 최소화
    unawaited(_runLetterSync());
    unawaited(_runMapSync());
  }

  /// Build 218: 사용자가 명시적으로 새로고침을 요청할 때 (지도 풀투리프레시 등).
  /// fetchMapUsers cooldown 우회 + 즉시 1회.
  Future<void> forceRefreshMapUsersAndLetters() async {
    if (!FirebaseConfig.kFirebaseEnabled) return;
    if (_currentUser.id.isEmpty || _currentUser.id == 'guest') return;
    await Future.wait([
      fetchMapUsers(force: true),
      _runLetterSync(),
    ]);
  }

  Future<void> _runLetterSync() async {
    if (_syncPaused || _syncInFlight) return;
    _syncInFlight = true;
    try {
      await _fetchIncomingLettersFromServer();
    } finally {
      _syncInFlight = false;
    }
  }

  Future<void> _runMapSync() async {
    if (_syncPaused || _mapSyncInFlight) return;
    _mapSyncInFlight = true;
    try {
      await fetchMapUsers(force: true);
    } finally {
      _mapSyncInFlight = false;
    }
  }

  /// 다른 사용자가 **내가 있는 국가**로 보낸 편지를 서버에서 내려받아 inbox
  /// 와 worldLetters 에 병합. 자기 자신이 보낸 편지, 이미 local 에 있는
  /// 편지, 차단된 발송자의 편지는 제외.
  ///
  /// 비용 최적화:
  /// - 페이지 크기 20 (기존 50). 새 편지는 90초 간격당 0~2통 정도라 20으로 충분.
  /// - `_seenLetterIds` Set 으로 중복 검사를 O(1) 로 처리 (기존 O(n) any).
  /// - `_lastLetterSyncAt` 갱신해 필요 시 델타 필터링에 활용.
  Future<void> _fetchIncomingLettersFromServer() async {
    if (!FirebaseConfig.kFirebaseEnabled) return;
    if (_currentUser.country.isEmpty) return;
    try {
      final docs = await FirestoreService.queryWhereEquals(
        collectionId: 'letters',
        field: 'destinationCountry',
        value: _currentUser.country,
        limit: 20,
      );
      if (docs.isEmpty) {
        _lastLetterSyncAt = DateTime.now();
        return;
      }

      int added = 0;
      for (final doc in docs) {
        final map = FirestoreService.fromFirestoreDoc(doc);
        final letter = _letterFromFirestore(map);
        if (letter == null) continue;
        // 자기 자신이 보낸 편지는 제외
        if (letter.senderId == _currentUser.id) continue;
        // 차단된 발송자 편지 제외
        if (_blockedSenderIds.contains(letter.senderId)) continue;
        if (_tempBlockedSenderIds.contains(letter.senderId)) continue;
        // 이미 처리한 편지 ID 는 빠르게 스킵 (O(1))
        if (_seenLetterIds.contains(letter.id)) continue;

        // 도착 상태에 따라 분배:
        //   - delivered → inbox (받은 편지함)
        //   - inTransit / nearYou → worldLetters (지도)
        if (letter.status == DeliveryStatus.delivered) {
          _inbox.add(letter);
        } else {
          _worldLetters.add(letter);
        }
        _seenLetterIds.add(letter.id);
        added++;
      }
      _lastLetterSyncAt = DateTime.now();
      if (added > 0) {
        notifyListeners();
        _saveToPrefs();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Firebase] 수신 편지 동기화 실패: $e');
    }
  }

  /// 중복 fetch 방지용 ID 캐시. 앱 세션 동안만 유지.
  /// inbox / worldLetters / sent 에 추가되는 모든 편지 ID 를 기록.
  final Set<String> _seenLetterIds = <String>{};

  /// Firestore 문서(필드 디코딩 완료) → Letter 객체 변환.
  /// 필수 필드 누락 시 null 반환.
  Letter? _letterFromFirestore(Map<String, dynamic> map) {
    try {
      final id = map['id'] as String?;
      final senderId = map['senderId'] as String?;
      final content = map['content'] as String?;
      if (id == null || senderId == null || content == null) return null;

      final originLat = (map['originLat'] as num?)?.toDouble() ?? 0.0;
      final originLng = (map['originLng'] as num?)?.toDouble() ?? 0.0;
      final destLat = (map['destLat'] as num?)?.toDouble() ?? 0.0;
      final destLng = (map['destLng'] as num?)?.toDouble() ?? 0.0;
      final origin = LatLng(originLat, originLng);
      final dest = LatLng(destLat, destLng);

      final sentAtStr = map['sentAt'] as String?;
      final sentAt = sentAtStr != null
          ? DateTime.tryParse(sentAtStr) ?? DateTime.now()
          : DateTime.now();
      final estimatedMinutes =
          (map['estimatedTotalMinutes'] as num?)?.toInt() ?? 60;

      // status 파싱
      DeliveryStatus status = DeliveryStatus.inTransit;
      final statusStr = map['status'] as String?;
      if (statusStr != null) {
        status = DeliveryStatus.values.firstWhere(
          (s) => s.name == statusStr,
          orElse: () => DeliveryStatus.inTransit,
        );
      }

      // letterType 파싱
      LetterType letterType = LetterType.normal;
      final typeStr = map['letterType'] as String?;
      if (typeStr != null) {
        letterType = LetterType.values.firstWhere(
          (t) => t.name == typeStr,
          orElse: () => LetterType.normal,
        );
      }

      // senderTier 파싱
      LetterSenderTier senderTier = LetterSenderTier.free;
      final tierStr = map['senderTier'] as String?;
      if (tierStr != null) {
        senderTier = LetterSenderTier.values.firstWhere(
          (t) => t.name == tierStr,
          orElse: () => LetterSenderTier.free,
        );
      }

      // 간이 segment (서버 전송 시 저장되지 않아 클라이언트에서 재구성).
      // 세부 출발/도착 허브 정보는 로컬에만 존재하므로 국가명으로 placeholder.
      final segment = RouteSegment(
        from: origin,
        to: dest,
        mode: TransportMode.airplane,
        fromName: (map['senderCountry'] as String?) ?? '',
        toName: (map['destinationCountry'] as String?) ?? '',
        fromType: HubType.city,
        toType: HubType.destination,
        estimatedMinutes: estimatedMinutes,
        progress:
            status == DeliveryStatus.delivered ? 1.0 : 0.0,
      );

      // 도착 시각이 이미 지났다면 자동으로 delivered 처리
      final arrivalTime =
          sentAt.add(Duration(minutes: estimatedMinutes));
      final now = DateTime.now();
      if (status == DeliveryStatus.inTransit && now.isAfter(arrivalTime)) {
        status = DeliveryStatus.delivered;
      }

      return Letter(
        id: id,
        senderId: senderId,
        senderName: (map['senderName'] as String?) ?? 'Traveler',
        senderCountry: (map['senderCountry'] as String?) ?? '',
        senderCountryFlag: (map['senderCountryFlag'] as String?) ?? '🌍',
        content: content,
        originLocation: origin,
        destinationLocation: dest,
        destinationCountry:
            (map['destinationCountry'] as String?) ?? '',
        destinationCountryFlag:
            (map['destinationCountryFlag'] as String?) ?? '🌍',
        destinationCity: (map['destinationCity'] as String?)?.isEmpty == true
            ? null
            : map['destinationCity'] as String?,
        segments: [segment],
        status: status,
        sentAt: sentAt,
        arrivalTime: arrivalTime,
        arrivedAt:
            status == DeliveryStatus.delivered ? arrivalTime : null,
        estimatedTotalMinutes: estimatedMinutes,
        letterType: letterType,
        paperStyle: (map['paperStyle'] as num?)?.toInt() ?? 0,
        fontStyle: (map['fontStyle'] as num?)?.toInt() ?? 0,
        imageUrl: (map['imageUrl'] as String?)?.isEmpty == true
            ? null
            : map['imageUrl'] as String?,
        socialLink: (map['socialLink'] as String?)?.isEmpty == true
            ? null
            : map['socialLink'] as String?,
        senderTier: senderTier,
        senderIsBrand: senderTier == LetterSenderTier.brand,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Firebase] 편지 파싱 실패: $e');
      return null;
    }
  }

  /// 관리자: 서버의 모든 편지 목록 조회. API key 기반 REST 리스트로
  /// 통일 (adminFetchAllUsers 와 동일 이유).
  Future<List<Map<String, dynamic>>> adminFetchAllLetters() async {
    if (!FirebaseConfig.kFirebaseEnabled) return [];
    final results = <Map<String, dynamic>>[];
    String? pageToken;
    const int pageSize = 100;
    const int maxPages = 3; // 최대 300 통
    int pagesFetched = 0;
    while (pagesFetched < maxPages) {
      try {
        final params = <String>[
          'key=${Uri.encodeQueryComponent(FirebaseConfig.apiKey)}',
          'pageSize=$pageSize',
          'orderBy=sentAt desc',
        ];
        if (pageToken != null && pageToken.isNotEmpty) {
          params.add('pageToken=${Uri.encodeQueryComponent(pageToken)}');
        }
        final url = Uri.parse(
          '${FirebaseConfig.firestoreBase}/letters?${params.join('&')}',
        );
        final res = await http.get(url).timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) {
          if (kDebugMode) {
            debugPrint(
              '[adminFetchAllLetters] http ${res.statusCode} ${res.body}',
            );
          }
          throw Exception('HTTP ${res.statusCode}');
        }
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final docs = (body['documents'] as List?) ?? const [];
        for (final raw in docs.whereType<Map>()) {
          try {
            final doc = Map<String, dynamic>.from(raw);
            results.add(FirestoreService.fromFirestoreDoc(doc));
          } catch (_) {}
        }
        pageToken = (body['nextPageToken'] as String?)?.trim();
        pagesFetched++;
        if (pageToken == null || pageToken.isEmpty) break;
      } catch (e) {
        if (kDebugMode) debugPrint('[adminFetchAllLetters] $e');
        if (results.isNotEmpty) return results;
        rethrow;
      }
    }
    return results;
  }

  /// 관리자: 서버의 모든 유저 목록 조회.
  ///
  /// `fetchMapUsers` 와 동일한 `?key=API_KEY` 방식으로 REST 리스트를
  /// 호출한다. Bearer 토큰 경로(`queryCollection`)가 Firestore 규칙에
  /// 의해 403 을 반환하는 경우가 있어 이 경로로 통일. 응답 포맷은
  /// fromFirestoreDoc 으로 평면화해 UI 레이어에서 바로 사용 가능하게
  /// 반환한다.
  Future<List<Map<String, dynamic>>> adminFetchAllUsers() async {
    if (!FirebaseConfig.kFirebaseEnabled) return [];
    final results = <Map<String, dynamic>>[];
    String? pageToken;
    const int pageSize = 100;
    const int maxPages = 5; // 최대 500 명
    int pagesFetched = 0;
    while (pagesFetched < maxPages) {
      try {
        final params = <String>[
          'key=${Uri.encodeQueryComponent(FirebaseConfig.apiKey)}',
          'pageSize=$pageSize',
        ];
        if (pageToken != null && pageToken.isNotEmpty) {
          params.add('pageToken=${Uri.encodeQueryComponent(pageToken)}');
        }
        final url = Uri.parse(
          '${FirebaseConfig.firestoreBase}/users?${params.join('&')}',
        );
        final res = await http.get(url).timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) {
          if (kDebugMode) {
            debugPrint(
              '[adminFetchAllUsers] http ${res.statusCode} ${res.body}',
            );
          }
          // 권한 에러는 상위에서 감지할 수 있게 예외 전파
          throw Exception('HTTP ${res.statusCode}');
        }
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final docs = (body['documents'] as List?) ?? const [];
        for (final raw in docs.whereType<Map>()) {
          try {
            final doc = Map<String, dynamic>.from(raw);
            results.add(FirestoreService.fromFirestoreDoc(doc));
          } catch (_) {}
        }
        pageToken = (body['nextPageToken'] as String?)?.trim();
        pagesFetched++;
        if (pageToken == null || pageToken.isEmpty) break;
      } catch (e) {
        if (kDebugMode) debugPrint('[adminFetchAllUsers] $e');
        // 이미 받은 결과가 있으면 그대로 반환, 없으면 에러 전파
        if (results.isNotEmpty) return results;
        rethrow;
      }
    }
    return results;
  }

  /// 관리자: 특정 편지 삭제
  ///
  /// Build 207: firestore.rules 가 letters delete 를 차단(`if false`)했으므로
  /// 클라이언트에서는 hard-delete 불가. 대신 status='deletedByAdmin' 으로
  /// 마킹 (rule 의 update 화이트리스트 통과). 실제 row 삭제는 Cloud Function
  /// 또는 admin SDK 가 후속 처리. 클라이언트 UI 는 이 status 를 보고 즉시
  /// 숨김 처리.
  Future<bool> adminDeleteLetter(String letterId) async {
    if (!FirebaseConfig.kFirebaseEnabled) return false;
    try {
      final url = Uri.parse(
        '${FirebaseConfig.firestoreBase}/letters/$letterId'
        '?updateMask.fieldPaths=status',
      );
      final body = jsonEncode({
        'fields': {
          'status': {'stringValue': 'deletedByAdmin'},
        },
      });
      // Bearer 토큰 포함된 PATCH — rule 의 update 화이트리스트 통과 필요.
      await FirebaseAuthService.ensureValidToken();
      final res = await http
          .patch(url, headers: FirestoreService.authHeaders, body: body)
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('[adminDeleteLetter] $e');
      return false;
    }
  }

  // ── 유저 세팅 (로그인/회원가입 후) ────────────────────────────────────────
  void setUser({
    required String id,
    required String username,
    required String country,
    required String countryFlag,
    bool isPremium = false,
    String? socialLink,
    String? languageCode,
    double? latitude,
    double? longitude,
    String? phoneNumber,
    String? verifyMethod,
  }) {
    final resolvedLanguageCode =
        (languageCode != null && languageCode.isNotEmpty)
        ? languageCode
        : (_currentUser.languageCode.isNotEmpty
              ? _currentUser.languageCode
              : LanguageConfig.getLanguageCode(country));
    _currentUser = UserProfile(
      id: id,
      username: username,
      country: country,
      countryFlag: countryFlag,
      isPremium: isPremium,
      socialLink: socialLink,
      profileImagePath: _currentUser.profileImagePath,
      languageCode: resolvedLanguageCode,
      latitude: latitude ?? 37.5665,
      longitude: longitude ?? 126.9780,
      activityScore: _currentUser.activityScore, // 기존 점수 유지 (초기값 하드코딩 제거)
      phoneNumber: phoneNumber,
      verifyMethod: verifyMethod ?? 'email',
    );
    _dailySentCount = 0;
    _dailySentDateKey = _dateKey(DateTime.now());
    _inviteCode = _deriveInviteCode();
    notifyListeners();
    // Firestore에 내 정보 저장 + 다른 회원 타워 불러오기
    _saveUserToFirestore();
    unawaited(_ensureInviteIdentityOnServer());
    fetchMapUsers(force: true);
    // AI 자동 편지 생성 (하루 5통)
    _generateDailyAiLetters();
    // 서버 복원: 앱 업데이트/재설치로 로컬 데이터가 비어 있어도
    // 서버에서 내 편지·타워·활동점수 자동 복구
    unawaited(restoreFromServerIfMissing());
    // 서버 동기화 시작 (편지 수신 + 다른 온라인 사용자 타워)
    startServerSync();
    // 일일 스트릭 체크인 (하루 1회 자동 증가)
    registerDailyStreakCheckin();
    // 초기 레벨 baseline 설정 (레벨업 감지에 사용)
    _previousUserLevel = userLevel;
    // 첫 가입 유저에게 운영팀 웰컴 편지 시딩 (한 번만)
    unawaited(_seedWelcomeLetterIfNeeded());
  }

  // 웰컴 편지: 유저별 1회만 시딩. 이미 존재하면 no-op.
  Future<void> _seedWelcomeLetterIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seedKey = 'welcome_letter_seeded_${_currentUser.id}';
      if (prefs.getBool(seedKey) ?? false) return;
      if (_inbox.any((l) => l.senderId == 'letter_go_welcome')) {
        await prefs.setBool(seedKey, true);
        return;
      }
      final letter = buildWelcomeLetter(
        userId: _currentUser.id,
        userCountry: _currentUser.country,
        userCountryFlag: _currentUser.countryFlag,
        userLat: _currentUser.latitude,
        userLng: _currentUser.longitude,
        langCode: _currentUser.languageCode.isNotEmpty
            ? _currentUser.languageCode
            : 'en',
      );
      _inbox.insert(0, letter);
      await prefs.setBool(seedKey, true);
      _saveToPrefs();
      notifyListeners();
    } catch (_) {
      // 실패해도 유저 흐름을 막지 않음
    }
  }

  // ── 위치 업데이트 ─────────────────────────────────────────────────────────
  void updateUserLocation(double lat, double lng) {
    _currentUser.latitude = lat;
    _currentUser.longitude = lng;
    notifyListeners();
    _saveUserToFirestore(); // 위치 변경 시 Firestore 업데이트
    // Build 149: 유효한 좌표 첫 확보 시점에 튜토리얼 편지 1통 자동 배치.
    // 첫 실행 빈 지도 경험 해소 — 온보딩 직후 반경 안에 반드시 줍을 수 있는
    // 환영 편지가 보이도록.
    unawaited(_maybePlaceTutorialLetter());
    // Build 218: 베타 테스트 기간 한정 — 다양한 카테고리/거리/발신자의 데모
    // 편지 6~10통을 유저 반경 내 살포. 빈 지도에서 "주워도 아무 것도 안 뜸"
    // 문제 해소. 정식 출시 빌드 (`disableInRelease=true` & kReleaseMode)
    // 에서는 자동으로 비활성화.
    unawaited(_maybeSeedDemoLetters());
  }

  /// Build 149: 첫 실행 시 유저 근처(~100m)에 환영 편지 1통 자동 배치.
  /// SharedPreferences 플래그로 한 번만 수행. Brand 유저는 제외 (광고주라서
  /// 실제 편지 풀에 더미가 들어가면 ROI 대시보드 오염).
  Future<void> _maybePlaceTutorialLetter() async {
    try {
      if (_currentUser.isBrand) return;
      if (_currentUser.latitude == 0 && _currentUser.longitude == 0) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('tutorial_letter_placed') == true) return;

      // 유저 반경 안쪽 (~100m 북쪽) 에 고정 위치로 생성.
      // 1도 위도 ≈ 111km → 100m = 0.0009도.
      final lat = _currentUser.latitude + 0.0009;
      final lng = _currentUser.longitude;

      final now = DateTime.now();
      final id = 'tutorial_welcome_${_currentUser.id}';
      // 이미 같은 id 존재 시 스킵 (중복 방지).
      if (_worldLetters.any((l) => l.id == id)) {
        await prefs.setBool('tutorial_letter_placed', true);
        return;
      }

      final welcomeLetter = Letter(
        id: id,
        senderId: 'system_welcome',
        senderName: _l10n.tutorialLetterSenderName,
        senderCountry: _currentUser.country,
        senderCountryFlag: _currentUser.countryFlag,
        content: _l10n.tutorialLetterContent,
        originLocation: LatLng(lat, lng),
        destinationLocation: LatLng(lat, lng),
        destinationCountry: _currentUser.country,
        destinationCountryFlag: _currentUser.countryFlag,
        destinationCity: null,
        segments: const [],
        currentSegmentIndex: 0,
        status: DeliveryStatus.delivered, // 즉시 줍기 가능
        sentAt: now,
        arrivedAt: now,
        arrivalTime: now,
        estimatedTotalMinutes: 0,
        isAnonymous: false,
        senderIsBrand: false,
        senderTier: LetterSenderTier.free,
        category: LetterCategory.general,
        acceptsReplies: false,
        deliveryEmoji: '✨',
      );

      _worldLetters.add(welcomeLetter);
      await prefs.setBool('tutorial_letter_placed', true);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('[Tutorial] 환영 편지 배치: ($lat, $lng)');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Tutorial] 환영 편지 배치 실패: $e');
    }
  }

  /// Build 218: 베타 테스트 기간 전용 — 유저 반경 안쪽에 다양한 편지 8통 살포.
  ///
  /// 활성 조건 (모두 만족):
  ///   - Brand 가 아닐 것 (광고주 ROI 오염 방지)
  ///   - 좌표 확보됨
  ///   - SharedPreferences `demo_letters_seeded_v1` 가 미설정
  ///   - 베타 빌드 — `kDebugMode` 또는 `BetaConstants.disableInRelease == false`
  ///
  /// 배치 패턴:
  ///   - 8 방위(N/NE/E/SE/S/SW/W/NW) 에 50~280m 거리로 분산
  ///   - LetterCategory 3종 (general·coupon·voucher) 골고루 + 발신자 8개국 회전
  ///   - status=delivered → 즉시 nearYou 로 전환되어 반경 안 줍기 가능
  ///   - id prefix `demo_seed_` → 데모 표식. 실 픽업 통계와 분리 가능
  Future<void> _maybeSeedDemoLetters() async {
    try {
      if (_currentUser.isBrand) return;
      if (_currentUser.latitude == 0 && _currentUser.longitude == 0) return;
      // 정식 출시 빌드에서는 비활성화 (베타 한정 기능)
      final isBetaBuild =
          kDebugMode || !BetaConstants.disableInRelease || !kReleaseMode;
      if (!isBetaBuild) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('demo_letters_seeded_v1') == true) return;

      final myLat = _currentUser.latitude;
      final myLng = _currentUser.longitude;
      final now = DateTime.now();
      final rand = Random(now.millisecondsSinceEpoch);

      // 8 방위 + 거리 (Build 240: Free 픽업 반경 200m 안으로 압축 — 60~180m).
      // 이전엔 230m/280m 가 Free 반경 밖이라 픽업 시 "거리 너무 멀다" 에러로
      // 첫인상 혼동을 유발. 이제 모든 데모 쿠폰이 Free 사용자에게도 줍기 가능.
      const samples = <Map<String, Object>>[
        {'bearingDeg': 0,   'distM': 60,  'sender': 'Emma',     'country': '영국',     'flag': '🇬🇧'},
        {'bearingDeg': 45,  'distM': 110, 'sender': 'Yuki',     'country': '일본',     'flag': '🇯🇵'},
        {'bearingDeg': 90,  'distM': 170, 'sender': 'Lucas',    'country': '브라질',   'flag': '🇧🇷'},
        {'bearingDeg': 135, 'distM': 130, 'sender': 'Marie',    'country': '프랑스',   'flag': '🇫🇷'},
        {'bearingDeg': 180, 'distM': 90,  'sender': 'James',    'country': '미국',     'flag': '🇺🇸'},
        {'bearingDeg': 225, 'distM': 150, 'sender': 'Lina',     'country': '독일',     'flag': '🇩🇪'},
        {'bearingDeg': 270, 'distM': 80,  'sender': 'Carlos',   'country': '스페인',   'flag': '🇪🇸'},
        {'bearingDeg': 315, 'distM': 180, 'sender': 'Sofia',    'country': '아르헨티나','flag': '🇦🇷'},
      ];

      // 카테고리 풀 — Premium 카테고리 선호도 부스트가 켜져 있으면 50% 매칭.
      final preferred = preferredCategory;
      final boostActive =
          preferred != null && _currentUser.isPremium && currentLevel >= 11;
      LetterCategory pickCategory(int idx) {
        if (boostActive && rand.nextDouble() < 0.5) return preferred;
        // 8통 중 골고루: 4 general / 2 coupon / 2 voucher
        if (idx == 1 || idx == 5) return LetterCategory.coupon;
        if (idx == 3 || idx == 6) return LetterCategory.voucher;
        return LetterCategory.general;
      }

      const sampleBodies = <String>[
        '안녕하세요! 오늘 우연히 이 앱을 알게 되어 첫 편지를 보내요. 당신의 하루는 어떤가요?',
        'こんにちは！世界の反対側から手紙を送ります。良い一日を！',
        'Hello from across the world! Hope this little note brightens your day.',
        '낯선 사람의 안부, 그 자체가 작은 선물이라고 믿어요. 항상 건강하세요.',
        'Bonjour ! J\'envoie cette lettre depuis très loin. Quel temps fait-il chez toi ?',
        '걷다가 우연히 발견한 편지가 누군가의 하루를 바꿀 수 있다면, 그게 마법이겠죠.',
        '¡Hola! Envío esta carta con mucho cariño. Espero que te haga sonreír.',
        'Wherever you are, may today be gentler than yesterday.',
      ];

      int placed = 0;
      for (int i = 0; i < samples.length; i++) {
        final s = samples[i];
        final bearing = (s['bearingDeg'] as int) * pi / 180.0;
        final distM = (s['distM'] as int).toDouble();
        // 위도 1도 ≈ 111km. 경도 1도 ≈ cos(lat)·111km.
        final dLat = (distM / 111000.0) * cos(bearing);
        final dLng = (distM / (111000.0 * cos(myLat * pi / 180.0).abs().clamp(1e-6, 1.0))) * sin(bearing);
        final lat = myLat + dLat;
        final lng = myLng + dLng;
        final cat = pickCategory(i);
        final id = 'demo_seed_${i}_${now.millisecondsSinceEpoch}';
        if (_worldLetters.any((l) => l.id == id)) continue;

        _worldLetters.add(
          Letter(
            id: id,
            senderId: 'demo_${s['flag']}',
            senderName: s['sender'] as String,
            senderCountry: s['country'] as String,
            senderCountryFlag: s['flag'] as String,
            content: sampleBodies[i % sampleBodies.length],
            originLocation: LatLng(lat, lng),
            destinationLocation: LatLng(lat, lng),
            destinationCountry: _currentUser.country,
            destinationCountryFlag: _currentUser.countryFlag,
            destinationCity: null,
            segments: const [],
            currentSegmentIndex: 0,
            status: DeliveryStatus.delivered, // 즉시 픽업 가능
            sentAt: now.subtract(Duration(minutes: 30 + i * 5)),
            arrivedAt: now,
            arrivalTime: now,
            estimatedTotalMinutes: 0,
            isAnonymous: false,
            senderIsBrand: false,
            senderTier: LetterSenderTier.free,
            category: cat,
            acceptsReplies: true,
            deliveryEmoji: cat == LetterCategory.coupon
                ? '🎟'
                : cat == LetterCategory.voucher
                    ? '🎁'
                    : '💌',
          ),
        );
        placed++;
      }

      await prefs.setBool('demo_letters_seeded_v1', true);
      if (placed > 0) notifyListeners();
      if (kDebugMode) {
        debugPrint('[DemoSeed] 데모 편지 $placed통 배치 (boost=$boostActive)');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DemoSeed] 데모 편지 배치 실패: $e');
    }
  }

  // ── 타워 이름 업데이트 ─────────────────────────────────────────────────────
  void updateTowerName(String? name) {
    _currentUser.customTowerName = name?.trim().isEmpty == true
        ? null
        : name?.trim();
    notifyListeners();
    _saveToPrefs(); // 로컬 영속 저장 (업데이트 후에도 유지)
    _saveUserToFirestore();
  }

  // ── 닉네임/SNS 업데이트 (설정 화면에서 호출) ─────────────────────────────
  bool updateUsername(String name) {
    if (!canChangeNicknameNow()) return false;
    _currentUser.username = name;
    _lastNicknameChangedAt = DateTime.now();
    _saveToPrefs();
    notifyListeners();
    return true;
  }

  void updateSocialLink(String? link) {
    _currentUser.socialLink = link;
    _saveToPrefs();
    notifyListeners();
  }

  void updateVerifyMethod(String method) {
    _currentUser.verifyMethod = method;
    _saveToPrefs();
    notifyListeners();
  }

  void updatePhoneNumber(String? phone) {
    _currentUser.phoneNumber = phone;
    _saveToPrefs();
    notifyListeners();
  }

  void updateProfileImage(String? path) {
    _currentUser.profileImagePath = path;
    _saveToPrefs();
    notifyListeners();
  }

  void updateDisplayThemeMode(DisplayThemeMode mode) {
    if (_displayThemeMode == mode) return;
    _displayThemeMode = mode;
    _saveToPrefs();
    notifyListeners();
  }

  void updatePrivacySettings({bool? isUsernamePublic, bool? isSnsPublic}) {
    _currentUser.isUsernamePublic =
        isUsernamePublic ?? _currentUser.isUsernamePublic;
    _currentUser.isSnsPublic = isSnsPublic ?? _currentUser.isSnsPublic;
    _saveToPrefs();
    _saveUserToFirestore();
    notifyListeners();
  }

  // ── Firestore: 내 정보 저장/업데이트 ──────────────────────────────────────
  /// 로그아웃 직전 호출: 마지막 위치·프로필을 Firestore에 한 번 더 동기화하고
  /// 완료까지 대기한다. Firebase 세션이 살아있는 동안 write가 성공하도록
  /// 반드시 `AuthService.logout()` 전에 호출해야 한다.
  ///
  /// 이 메서드가 없으면, 로그아웃한 테스터의 최근 위치가 Firestore에 반영되지
  /// 않은 채 세션만 종료되어, 다른 회원들의 지도에서 해당 타워가 누락되거나
  /// 오래된 좌표로 남는 문제가 발생한다.
  Future<void> snapshotUserForLogout() async {
    if (_currentUser.id.isEmpty || _currentUser.id == 'guest') return;
    if (!FirebaseConfig.kFirebaseEnabled) return;
    await _saveUserToFirestore(markLoggedOut: true);
  }

  Future<void> _saveUserToFirestore({bool markLoggedOut = false}) async {
    if (_currentUser.id == 'guest') return;
    if (!FirebaseConfig.kFirebaseEnabled) return;
    try {
      // Build 207: GPS 좌표 ~100m 정밀도로 coarsen.
      // 이전엔 cm 정밀도 그대로 업로드 → 자택 핀포인트 가능. firestore.rules
      // list 가 isMapPublic=true 만 노출하도록 강화됐어도 좌표 자체는 coarse
      // 하게 보내는 게 PII 방어 layer. 픽업 반경(200m–1km)에 비해 100m 오차는
      // 게임플레이 영향 미미.
      final coarseLat = (_currentUser.latitude * 1000).round() / 1000.0;
      final coarseLng = (_currentUser.longitude * 1000).round() / 1000.0;
      final fields = <String, Map<String, dynamic>>{
        'id': {'stringValue': _currentUser.id},
        'username': {'stringValue': _currentUser.username},
        'countryFlag': {'stringValue': _currentUser.countryFlag},
        'country': {'stringValue': _currentUser.country},
        'latitude': {'doubleValue': coarseLat},
        'longitude': {'doubleValue': coarseLng},
        'isUsernamePublic': {'booleanValue': _currentUser.isUsernamePublic},
        // 지도 노출은 명시적 opt-in 필드로 관리
        'isMapPublic': {'booleanValue': _currentUser.isUsernamePublic},
        // 로그아웃 스냅샷 + 최근 활동 타임스탬프
        'lastSeenAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
        if (markLoggedOut)
          'loggedOutAt': {
            'timestampValue': DateTime.now().toUtc().toIso8601String(),
          },
        'receivedCount': {
          'integerValue': '${_currentUser.activityScore.receivedCount}',
        },
        'replyCount': {
          'integerValue': '${_currentUser.activityScore.replyCount}',
        },
        'sentCount': {
          'integerValue': '${_currentUser.activityScore.sentCount}',
        },
        'likeCount': {
          'integerValue': '${_currentUser.activityScore.likeCount}',
        },
        'inviteCode': {'stringValue': myInviteCode},
        'inviteRewardCredits': {'integerValue': '$_inviteRewardCredits'},
        'brandExtraMonthlyQuota': {
          'integerValue': '$_brandExtraMonthlyQuota',
        },
        if (_appliedInviteCode != null)
          'inviteAppliedCode': {'stringValue': _appliedInviteCode!},
        if (_lastInviteRewardAt != null)
          'inviteRewardAt': {
            'timestampValue': _lastInviteRewardAt!.toUtc().toIso8601String(),
          },
        'updatedAt': {'stringValue': DateTime.now().toIso8601String()},
        if (_currentUser.customTowerName != null)
          'customTowerName': {'stringValue': _currentUser.customTowerName!},
        'towerColor': {'stringValue': _currentUser.towerColor},
        if (_currentUser.towerAccentEmoji != null)
          'towerAccentEmoji': {'stringValue': _currentUser.towerAccentEmoji!},
        'towerRoofStyle': {'integerValue': '${_currentUser.towerRoofStyle}'},
        'towerWindowStyle': {'integerValue': '${_currentUser.towerWindowStyle}'},
        // Build 218: 카테고리 선호 (Premium Lv11+ 한정)
        if (_currentUser.preferredCategoryKey != null)
          'preferredCategoryKey': {
            'stringValue': _currentUser.preferredCategoryKey!,
          },
      };
      // updateMask 를 명시해야 PATCH 가 다른 필드(예: 병렬로 쓰는 invite 정보)를
      // 삭제하지 않는다. 이걸 빼면 병렬 쓰기가 서로의 필드를 밀어내 0,0 좌표가
      // 남는 버그가 재현된다.
      final maskParams = fields.keys
          .map((k) => 'updateMask.fieldPaths=${Uri.encodeQueryComponent(k)}')
          .join('&');
      final url = Uri.parse(
        '${FirebaseConfig.firestoreBase}/users/${_currentUser.id}'
        '?key=${FirebaseConfig.apiKey}&$maskParams',
      );
      final body = jsonEncode({'fields': fields});
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          await http.patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          ).timeout(const Duration(seconds: 20));
          return; // 성공 시 종료
        } catch (e) {
          if (attempt < 2) {
            await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          } else {
            debugPrint('[Firestore] user save error (3 attempts): $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[Firestore] user save error: $e');
    }
  }

  Future<void> _ensureInviteIdentityOnServer() async {
    if (_currentUser.id == 'guest') return;
    if (!FirebaseConfig.kFirebaseEnabled) return;
    if (!FirebaseAuthService.isSignedIn) return;
    try {
      final path = 'users/${_currentUser.id}';
      final doc = await FirestoreService.getDocument(path);
      if (doc == null) {
        await FirestoreService.setDocument(path, {
          'id': _currentUser.id,
          'username': _currentUser.username,
          'inviteCode': myInviteCode,
          'inviteRewardCredits': _inviteRewardCredits,
          'brandExtraMonthlyQuota': _brandExtraMonthlyQuota,
          if (_appliedInviteCode != null)
            'inviteAppliedCode': _appliedInviteCode!,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        _saveToPrefs();
        return;
      }

      final data = FirestoreService.fromFirestoreDoc(doc);
      final serverInviteCode = (data['inviteCode'] as String?)?.trim();
      if (serverInviteCode != null && serverInviteCode.isNotEmpty) {
        _inviteCode = serverInviteCode;
      }
      final serverCredits = data['inviteRewardCredits'] as int? ?? 0;
      final serverBrandExtraQuota = data['brandExtraMonthlyQuota'] as int? ?? 0;
      final serverAppliedCode = (data['inviteAppliedCode'] as String?)?.trim();
      final rewardAtRaw = data['inviteRewardAt'] as String?;

      var changed = false;
      if (_inviteRewardCredits != serverCredits) {
        _inviteRewardCredits = serverCredits;
        changed = true;
      }
      if (_brandExtraMonthlyQuota != serverBrandExtraQuota) {
        _brandExtraMonthlyQuota = serverBrandExtraQuota;
        changed = true;
      }
      final normalizedApplied =
          (serverAppliedCode != null && serverAppliedCode.isNotEmpty)
          ? serverAppliedCode
          : null;
      if (_appliedInviteCode != normalizedApplied) {
        _appliedInviteCode = normalizedApplied;
        changed = true;
      }
      if (rewardAtRaw != null && rewardAtRaw.isNotEmpty) {
        final parsed = DateTime.tryParse(rewardAtRaw)?.toLocal();
        if (parsed != null &&
            (_lastInviteRewardAt == null ||
                _lastInviteRewardAt!.millisecondsSinceEpoch !=
                    parsed.millisecondsSinceEpoch)) {
          _lastInviteRewardAt = parsed;
          changed = true;
        }
      }

      if (serverInviteCode == null || serverInviteCode.isEmpty) {
        await FirestoreService.setDocument(path, {
          'inviteCode': myInviteCode,
          'brandExtraMonthlyQuota': _brandExtraMonthlyQuota,
        });
      }

      if (changed) {
        _saveToPrefs();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Invite] _ensureInviteIdentityOnServer error: $e');
    }
  }

  // ── 하루 1편지 자동 수신 (테스터·데모용) ──────────────────────────────
  Future<void> _checkAndDeliverDailyLetter() async {
    final todayKey = _dateKey(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final lastKey = prefs.getString('dailyLetterKey_v2') ?? '';
    if (lastKey == todayKey) return; // 오늘 이미 수신됨
    await prefs.setString('dailyLetterKey_v2', todayKey);

    final rng = Random();
    final senders = [
      {
        'name': 'Maria G.',
        'country': '스페인',
        'flag': '🇪🇸',
        'lat': 40.4168,
        'lng': -3.7038,
        'content':
            'Desde la Plaza Mayor de Madrid, te escribo esta carta. Hoy asistí a un espectáculo de flamenco y sentí cómo el ritmo del baile me llenaba el alma. Hay algo mágico en esta ciudad que nunca deja de sorprenderme. ¿Cómo estás tú, al otro lado del mundo?',
      },
      {
        'name': 'Dmitri V.',
        'country': '러시아',
        'flag': '🇷🇺',
        'lat': 55.7558,
        'lng': 37.6176,
        'content':
            'Привет из Москвы! Сегодня выпал первый снег, и Красная площадь стала похожа на сказку. Купола собора Василия Блаженного сверкают под белым покровом. Я сижу у окна с горячим чаем и думаю о незнакомцах по всему свету. Как ты?',
      },
      {
        'name': 'Yuki T.',
        'country': '일본',
        'flag': '🇯🇵',
        'lat': 35.6762,
        'lng': 139.6503,
        'content':
            '東京の小さなカフェからこの手紙を書いています。今日は窓の外の景色がとても美しく、つい見とれてしまいました。遠い場所に住む見知らぬあなたに、この穏やかな瞬間を届けたくて。お元気でいますか？',
      },
      {
        'name': 'Amara D.',
        'country': '남아프리카',
        'flag': '🇿🇦',
        'lat': -26.2041,
        'lng': 28.0473,
        'content':
            "Hallo vanuit Johannesburg! Die goue sonsondergang verf die lug in skakerings van oranje en pienk. Suid-Afrika het sulke asemrowende skoonheid — die wye savanna, die warmte van sy mense, die stories in elke hoek. Ek hoop hierdie brief vind jou goed, waar jy ook al is.",
      },
      {
        'name': 'Lucas B.',
        'country': '브라질',
        'flag': '🇧🇷',
        'lat': -23.5505,
        'lng': -46.6333,
        'content':
            'Olá! Escrevo esta carta das ruas vibrantes de São Paulo. A cidade pulsa com vida, música e alegria em cada esquina. Há algo especial em imaginar que estas palavras vão viajar até você do outro lado do mundo. Como vai você por aí?',
      },
      {
        'name': 'Priya S.',
        'country': '인도',
        'flag': '🇮🇳',
        'lat': 28.6139,
        'lng': 77.2090,
        'content':
            'नमस्ते! नई दिल्ली से आपको यह पत्र लिख रही हूँ। शाम की हवा में चमेली की खुशबू घुली हुई है और मन में बड़ी शांति है। दुनिया के किसी कोने में बैठे आपसे यह पल साझा करना चाहती थी। आप कैसे हैं?',
      },
      {
        'name': 'Chloe M.',
        'country': '프랑스',
        'flag': '🇫🇷',
        'lat': 48.8566,
        'lng': 2.3522,
        'content':
            "Bonjour depuis Paris ! Je t'écris depuis les bords de la Seine, où les lumières de la ville se reflètent doucement sur l'eau. Aujourd'hui, j'ai admiré la Joconde au Louvre — ce sourire mystérieux reste gravé dans ma mémoire. Comment vas-tu, de l'autre côté du monde ?",
      },
      {
        'name': 'James O.',
        'country': '영국',
        'flag': '🇬🇧',
        'lat': 51.5074,
        'lng': -0.1278,
        'content':
            'Greetings from foggy London! There is something rather poetic about writing to a complete stranger on a grey afternoon, with a warm cup of tea in hand and the Thames quietly flowing outside. I do hope your day is going splendidly, wherever you may be.',
      },
      {
        'name': 'Elena K.',
        'country': '그리스',
        'flag': '🇬🇷',
        'lat': 37.9838,
        'lng': 23.7275,
        'content':
            'Γεια σου από τη Σαντορίνη! Κάθομαι κάτω από τον γαλάζιο τρούλο και κοιτώ αναλογιστικά το Αιγαίο. Ο κόσμος είναι τόσο μεγάλος, αλλά μια επιστολή μπορεί να φέρει δύο ψυχές κοντά. Ελπίζω η μέρα σου να είναι γεμάτη φως. Πώς είσαι;',
      },
      {
        'name': 'Tariq A.',
        'country': '이집트',
        'flag': '🇪🇬',
        'lat': 30.0444,
        'lng': 31.2357,
        'content':
            'مرحباً من القاهرة! أكتب إليك في فجر هادئ والأهرامات تلوح في الأفق، شاهدةً على آلاف السنين. هناك شيء ما في هذا المنظر يجعلني أفكر في الغرباء الذين يعيشون في أجزاء أخرى من العالم. كيف حالك في مكانك البعيد؟',
      },
      {
        'name': 'Mei L.',
        'country': '중국',
        'flag': '🇨🇳',
        'lat': 39.9042,
        'lng': 116.4074,
        'content':
            '你好！我在北京故宫附近给你写这封信。春风带着历史的气息轻轻拂过，让人心旷神怡。希望这封漂洋过海的信，能为你带来来自东方的一份温暖与问候。你还好吗？',
      },
      {
        'name': 'Oliver H.',
        'country': '호주',
        'flag': '🇦🇺',
        'lat': -33.8688,
        'lng': 151.2093,
        'content':
            "G'day from Sydney Harbour! Today I took a yacht out on the water and came across a pod of dolphins leaping alongside the bow. Reckon that was the highlight of my week! Hope wherever you are, you're finding your own little moments of magic too.",
      },
      {
        'name': 'Sofia R.',
        'country': '이탈리아',
        'flag': '🇮🇹',
        'lat': 41.9028,
        'lng': 12.4964,
        'content':
            'Ciao da Roma! Stasera ho passeggiato tra i vicoli della città eterna e ho gettato una moneta nella Fontana di Trevi. Ho espresso un desiderio: che questa lettera raggiunga qualcuno che ne aveva bisogno. Come stai, amico lontano?',
      },
      {
        'name': 'Hana W.',
        'country': '태국',
        'flag': '🇹🇭',
        'lat': 13.7563,
        'lng': 100.5018,
        'content':
            'สวัสดีจากกรุงเทพฯ! ฉันนั่งเขียนจดหมายนี้ใกล้วัดทอง แสงอาทิตย์ยามเย็นสาดกระทบยอดปรางค์ทำให้ทุกอย่างดูสวยงามราวกับฝัน อยากแบ่งปันความสงบนี้ให้คุณบ้าง คุณเป็นยังไงบ้างในวันนี้?',
      },
      {
        'name': 'Ananya P.',
        'country': '인도네시아',
        'flag': '🇮🇩',
        'lat': -8.4095,
        'lng': 115.1889,
        'content':
            'Halo dari Bali! Aku menulis surat ini sambil memandangi terasering sawah yang hijau membentang hingga ke bukit. Dunia ini begitu indah dan aku merasa sangat beruntung bisa menikmatinya setiap hari. Semoga kamu juga baik-baik saja di sana, ya.',
      },
      {
        'name': 'Jake M.',
        'country': '미국',
        'flag': '🇺🇸',
        'lat': 40.7128,
        'lng': -74.0060,
        'content':
            'Hey there from New York City! I\'m sitting on the steps of the Met, watching the whole world walk by. Every face has a story, every hurried step carries a dream. In this city of eight million, it\'s easy to feel both lost and found at once. Hope you\'re doing well out there.',
      },
      {
        'name': 'Klaus W.',
        'country': '독일',
        'flag': '🇩🇪',
        'lat': 52.5200,
        'lng': 13.4050,
        'content':
            'Guten Tag aus Berlin! Ich schreibe dir von der Spree, während die Herbstblätter wie goldene Briefe vom Himmel fallen. Diese Stadt trägt die Geschichte Europas in jedem Stein. Manchmal halte ich inne und denke an all die Menschen, die ich nie kennenlernen werde. Wie geht es dir?',
      },
      {
        'name': 'Emily C.',
        'country': '캐나다',
        'flag': '🇨🇦',
        'lat': 45.5017,
        'lng': -73.5673,
        'content':
            "Bonjour de Montréal! Les érables se sont transformés en une mer de rouge et d'ambre, et j'ai marché dans les feuilles toute la matinée. Le Canada est un pays de merveilles tranquilles — des lacs gelés, des forêts infinies et les étrangers les plus gentils. Je t'envoie un peu de cette chaleur automnale.",
      },
      {
        'name': 'Diego R.',
        'country': '멕시코',
        'flag': '🇲🇽',
        'lat': 19.4326,
        'lng': -99.1332,
        'content':
            '¡Hola desde la Ciudad de México! Estoy sentado en el Zócalo mientras el mariachi llena el aire con su melodía. Los colores de esta ciudad — los murales, los mercados, las flores — son un festín para los ojos. Espero que este mensaje te llegue con todo el sabor de México. ¿Cómo estás?',
      },
      {
        'name': 'Kemal A.',
        'country': '터키',
        'flag': '🇹🇷',
        'lat': 41.0082,
        'lng': 28.9784,
        'content':
            'Merhaba İstanbul\'dan! Boğaz\'da iki kıtanın buluştuğu noktada oturmuş, sana bu mektubu yazıyorum. Şehrin sesi, seyyar satıcıların bağrışları ve uzaktan gelen ezan sesiyle harmanlı. Dünyanın bir başka köşesinde yaşayan sana buradan selam yolluyorum. Nasılsın?',
      },
      {
        'name': 'Valentina M.',
        'country': '아르헨티나',
        'flag': '🇦🇷',
        'lat': -34.6037,
        'lng': -58.3816,
        'content':
            '¡Buenas desde Buenos Aires! Esta noche fui a una milonga y el tango me envolvió como ningún otro baile puede hacerlo. Hay algo en los pasos del tango que habla de amor, de pérdida, de esperanza. Quería compartir este momento con alguien del otro lado del mundo. ¿Cómo estás tú?',
      },
      {
        'name': 'Ana L.',
        'country': '포르투갈',
        'flag': '🇵🇹',
        'lat': 38.7169,
        'lng': -9.1399,
        'content':
            'Olá de Lisboa! Estou sentada num café a ouvir fado enquanto o sol se põe sobre o rio Tejo. Há uma palavra portuguesa — saudade — que não tem tradução, mas que sinto agora ao escrever-te. É a melancolia doce de tudo o que foi ou poderia ser. Espero que estejas bem, amigo distante.',
      },
      {
        'name': 'Lars B.',
        'country': '스웨덴',
        'flag': '🇸🇪',
        'lat': 59.3293,
        'lng': 18.0686,
        'content':
            'Hej från Stockholm! Det är midnattssol och himlen är aldrig helt mörk den här årstiden. Jag sitter vid vattnet och funderar på hur stor världen egentligen är. Det finns något magiskt med att skicka ett brev till någon man aldrig träffat. Hur mår du, var du än är?',
      },
      {
        'name': 'Nguyen T.',
        'country': '베트남',
        'flag': '🇻🇳',
        'lat': 21.0285,
        'lng': 105.8542,
        'content':
            'Xin chào từ Hà Nội! Tôi đang ngồi bên hồ Hoàn Kiếm, nhìn mặt hồ gợn sóng trong buổi sáng sớm. Mùi cà phê trứng thơm nồng từ quán nhỏ bên cạnh cứ vấn vương. Tôi muốn gửi đến bạn một chút bình yên của buổi sáng Hà Nội hôm nay. Bạn có khỏe không?',
      },
      {
        'name': 'Aisha M.',
        'country': '나이지리아',
        'flag': '🇳🇬',
        'lat': 6.5244,
        'lng': 3.3792,
        'content':
            'Hello from Lagos! This city never sleeps — it hums, it dances, it shouts with life at every hour. I am writing to you from my balcony as the sun rises over the lagoon, painting everything in shades of copper and gold. Africa has a pulse unlike anywhere else. How are you, friend?',
      },
      {
        'name': 'Amina K.',
        'country': '케냐',
        'flag': '🇰🇪',
        'lat': -1.2921,
        'lng': 36.8219,
        'content':
            'Jambo kutoka Nairobi! Asubuhi hii nilikuwa bustanini nikitazama ndege wa rangi mbalimbali wakizunguka. Kenya ni nchi ya maajabu — misitu, savana, na watu wenye moyo mkunjufu. Nilitaka kukushirikisha furaha hii ndogo. Je, uko salama?',
      },
      {
        'name': 'Carlos P.',
        'country': '페루',
        'flag': '🇵🇪',
        'lat': -13.1631,
        'lng': -72.5450,
        'content':
            '¡Saludos desde Machu Picchu! Estoy entre las ruinas de los incas, donde las nubes rozan las piedras antiguas y el silencio habla más fuerte que las palabras. Subir aquí fue como tocar el cielo con las manos. Quería compartir este instante suspendido en el tiempo contigo. ¿Cómo estás?',
      },
      {
        'name': 'Fatima Z.',
        'country': '모로코',
        'flag': '🇲🇦',
        'lat': 34.0209,
        'lng': -6.8416,
        'content':
            'مرحباً من الرباط! أجلس في حديقة القصبة والياسمين يملأ الهواء برائحته الزكية. المغرب بلد الألوان والروائح والحكايات القديمة. أريد أن أهديك لحظة من هذا الهدوء الجميل. كيف حالك في مكانك البعيد؟',
      },
      {
        'name': 'Pita F.',
        'country': '뉴질랜드',
        'flag': '🇳🇿',
        'lat': -36.8485,
        'lng': 174.7633,
        'content':
            'Kia ora from Auckland! I\'ve just come back from a hike along the Waitakere ranges, and my heart is still full of green hills and crashing waves. New Zealand is like a dream you don\'t want to wake from. I hope this letter carries a little of that wonder to wherever you are. How\'s life treating you?',
      },
      {
        'name': 'Marcin W.',
        'country': '폴란드',
        'flag': '🇵🇱',
        'lat': 52.2297,
        'lng': 21.0122,
        'content':
            'Witaj z Warszawy! Siedzę przy Wiśle i patrzę, jak miasto odbija się w spokojnej wodzie. Warszawa nosi w sobie blizny historii, ale też niesamowitą siłę odrodzenia. Jest coś pięknego w wysyłaniu listu do kogoś, kogo nigdy nie spotkałem. Jak się masz po tamtej stronie świata?',
      },
    ];

    // ── 하루 3통: 서로 다른 나라에서 발송 ──
    final koreaCities = CountryCities.cities['대한민국'] ?? [];
    final shuffledSenders = List.of(senders)..shuffle(rng);
    final pickedThree = shuffledSenders.take(3).toList();

    for (int i = 0; i < pickedThree.length; i++) {
      final picked = pickedThree[i];
      final randomKorCity = koreaCities[rng.nextInt(koreaCities.length)];
      final toLat = (randomKorCity['lat'] as num).toDouble();
      final toLng = (randomKorCity['lng'] as num).toDouble();

      final letterId = 'daily_${todayKey}_${i}_${rng.nextInt(9999)}';

      final letter = _makeMockLetter(
        id: letterId,
        senderName: picked['name'] as String,
        senderCountry: picked['country'] as String,
        senderFlag: picked['flag'] as String,
        content: picked['content'] as String,
        fromCountry: picked['country'] as String,
        fromLat: (picked['lat'] as num).toDouble(),
        fromLng: (picked['lng'] as num).toDouble(),
        toCountry: '대한민국',
        toLat: toLat,
        toLng: toLng,
        segProgress: [0.0, 0.0, 0.0],
        segIdx: 0,
        status: DeliveryStatus.inTransit,
        hoursAgo: 0,
      );
      _worldLetters.add(letter);
    }
    _saveToPrefs();
    notifyListeners();
  }

  // ── 테스트용: 30개국에서 한국으로 편지 일괄 발송 ──────────────────────────
  Future<void> sendTestWorldLetters() async {
    final prefs = await SharedPreferences.getInstance();
    final doneKey = prefs.getBool('testWorldLetters_v3') ?? false;
    if (doneKey) return;
    await prefs.setBool('testWorldLetters_v3', true);

    final rng = Random();
    final koreaCitiesAll = CountryCities.cities['대한민국'] ?? [];

    final allSenders = [
      {
        'name': 'Maria G.',
        'country': '스페인',
        'flag': '🇪🇸',
        'lat': 40.4168,
        'lng': -3.7038,
        'content':
            'Desde la Plaza Mayor de Madrid, te escribo esta carta. Hoy asistí a un espectáculo de flamenco y sentí cómo el ritmo del baile me llenaba el alma. Hay algo mágico en esta ciudad que nunca deja de sorprenderme. ¿Cómo estás tú, al otro lado del mundo?',
      },
      {
        'name': 'Dmitri V.',
        'country': '러시아',
        'flag': '🇷🇺',
        'lat': 55.7558,
        'lng': 37.6176,
        'content':
            'Привет из Москвы! Сегодня выпал первый снег, и Красная площадь стала похожа на сказку. Купола собора Василия Блаженного сверкают под белым покровом. Я сижу у окна с горячим чаем и думаю о незнакомцах по всему свету. Как ты?',
      },
      {
        'name': 'Yuki T.',
        'country': '일본',
        'flag': '🇯🇵',
        'lat': 35.6762,
        'lng': 139.6503,
        'content':
            '東京の小さなカフェからこの手紙を書いています。今日は窓の外の景色がとても美しく、つい見とれてしまいました。遠い場所に住む見知らぬあなたに、この穏やかな瞬間を届けたくて。お元気でいますか？',
      },
      {
        'name': 'Amara D.',
        'country': '남아프리카',
        'flag': '🇿🇦',
        'lat': -26.2041,
        'lng': 28.0473,
        'content':
            "Hallo vanuit Johannesburg! Die goue sonsondergang verf die lug in skakerings van oranje en pienk. Suid-Afrika het sulke asemrowende skoonheid — die wye savanna, die warmte van sy mense, die stories in elke hoek. Ek hoop hierdie brief vind jou goed, waar jy ook al is.",
      },
      {
        'name': 'Lucas B.',
        'country': '브라질',
        'flag': '🇧🇷',
        'lat': -23.5505,
        'lng': -46.6333,
        'content':
            'Olá! Escrevo esta carta das ruas vibrantes de São Paulo. A cidade pulsa com vida, música e alegria em cada esquina. Há algo especial em imaginar que estas palavras vão viajar até você do outro lado do mundo. Como vai você por aí?',
      },
      {
        'name': 'Priya S.',
        'country': '인도',
        'flag': '🇮🇳',
        'lat': 28.6139,
        'lng': 77.2090,
        'content':
            'नमस्ते! नई दिल्ली से आपको यह पत्र लिख रही हूँ। शाम की हवा में चमेली की खुशबू घुली हुई है और मन में बड़ी शांति है। दुनिया के किसी कोने में बैठे आपसे यह पल साझा करना चाहती थी। आप कैसे हैं?',
      },
      {
        'name': 'Chloe M.',
        'country': '프랑스',
        'flag': '🇫🇷',
        'lat': 48.8566,
        'lng': 2.3522,
        'content':
            "Bonjour depuis Paris ! Je t'écris depuis les bords de la Seine, où les lumières de la ville se reflètent doucement sur l'eau. Aujourd'hui, j'ai admiré la Joconde au Louvre — ce sourire mystérieux reste gravé dans ma mémoire. Comment vas-tu, de l'autre côté du monde ?",
      },
      {
        'name': 'James O.',
        'country': '영국',
        'flag': '🇬🇧',
        'lat': 51.5074,
        'lng': -0.1278,
        'content':
            'Greetings from foggy London! There is something rather poetic about writing to a complete stranger on a grey afternoon, with a warm cup of tea in hand and the Thames quietly flowing outside. I do hope your day is going splendidly, wherever you may be.',
      },
      {
        'name': 'Elena K.',
        'country': '그리스',
        'flag': '🇬🇷',
        'lat': 37.9838,
        'lng': 23.7275,
        'content':
            'Γεια σου από τη Σαντορίνη! Κάθομαι κάτω από τον γαλάζιο τρούλο και κοιτώ αναλογιστικά το Αιγαίο. Ο κόσμος είναι τόσο μεγάλος, αλλά μια επιστολή μπορεί να φέρει δύο ψυχές κοντά. Ελπίζω η μέρα σου να είναι γεμάτη φως. Πώς είσαι;',
      },
      {
        'name': 'Tariq A.',
        'country': '이집트',
        'flag': '🇪🇬',
        'lat': 30.0444,
        'lng': 31.2357,
        'content':
            'مرحباً من القاهرة! أكتب إليك في فجر هادئ والأهرامات تلوح في الأفق، شاهدةً على آلاف السنين. هناك شيء ما في هذا المنظر يجعلني أفكر في الغرباء الذين يعيشون في أجزاء أخرى من العالم. كيف حالك في مكانك البعيد؟',
      },
      {
        'name': 'Mei L.',
        'country': '중국',
        'flag': '🇨🇳',
        'lat': 39.9042,
        'lng': 116.4074,
        'content':
            '你好！我在北京故宫附近给你写这封信。春风带着历史的气息轻轻拂过，让人心旷神怡。希望这封漂洋过海的信，能为你带来来自东方的一份温暖与问候。你还好吗？',
      },
      {
        'name': 'Oliver H.',
        'country': '호주',
        'flag': '🇦🇺',
        'lat': -33.8688,
        'lng': 151.2093,
        'content':
            "G'day from Sydney Harbour! Today I took a yacht out on the water and came across a pod of dolphins leaping alongside the bow. Reckon that was the highlight of my week! Hope wherever you are, you're finding your own little moments of magic too.",
      },
      {
        'name': 'Sofia R.',
        'country': '이탈리아',
        'flag': '🇮🇹',
        'lat': 41.9028,
        'lng': 12.4964,
        'content':
            'Ciao da Roma! Stasera ho passeggiato tra i vicoli della città eterna e ho gettato una moneta nella Fontana di Trevi. Ho espresso un desiderio: che questa lettera raggiunga qualcuno che ne aveva bisogno. Come stai, amico lontano?',
      },
      {
        'name': 'Hana W.',
        'country': '태국',
        'flag': '🇹🇭',
        'lat': 13.7563,
        'lng': 100.5018,
        'content':
            'สวัสดีจากกรุงเทพฯ! ฉันนั่งเขียนจดหมายนี้ใกล้วัดทอง แสงอาทิตย์ยามเย็นสาดกระทบยอดปรางค์ทำให้ทุกอย่างดูสวยงามราวกับฝัน อยากแบ่งปันความสงบนี้ให้คุณบ้าง คุณเป็นยังไงบ้างในวันนี้?',
      },
      {
        'name': 'Ananya P.',
        'country': '인도네시아',
        'flag': '🇮🇩',
        'lat': -8.4095,
        'lng': 115.1889,
        'content':
            'Halo dari Bali! Aku menulis surat ini sambil memandangi terasering sawah yang hijau membentang hingga ke bukit. Dunia ini begitu indah dan aku merasa sangat beruntung bisa menikmatinya setiap hari. Semoga kamu juga baik-baik saja di sana, ya.',
      },
      {
        'name': 'Jake M.',
        'country': '미국',
        'flag': '🇺🇸',
        'lat': 40.7128,
        'lng': -74.0060,
        'content':
            'Hey there from New York City! I\'m sitting on the steps of the Met, watching the whole world walk by. Every face has a story, every hurried step carries a dream. In this city of eight million, it\'s easy to feel both lost and found at once. Hope you\'re doing well out there.',
      },
      {
        'name': 'Klaus W.',
        'country': '독일',
        'flag': '🇩🇪',
        'lat': 52.5200,
        'lng': 13.4050,
        'content':
            'Guten Tag aus Berlin! Ich schreibe dir von der Spree, während die Herbstblätter wie goldene Briefe vom Himmel fallen. Diese Stadt trägt die Geschichte Europas in jedem Stein. Manchmal halte ich inne und denke an all die Menschen, die ich nie kennenlernen werde. Wie geht es dir?',
      },
      {
        'name': 'Emily C.',
        'country': '캐나다',
        'flag': '🇨🇦',
        'lat': 45.5017,
        'lng': -73.5673,
        'content':
            "Bonjour de Montréal! Les érables se sont transformés en une mer de rouge et d'ambre, et j'ai marché dans les feuilles toute la matinée. Le Canada est un pays de merveilles tranquilles — des lacs gelés, des forêts infinies et les étrangers les plus gentils. Je t'envoie un peu de cette chaleur automnale.",
      },
      {
        'name': 'Diego R.',
        'country': '멕시코',
        'flag': '🇲🇽',
        'lat': 19.4326,
        'lng': -99.1332,
        'content':
            '¡Hola desde la Ciudad de México! Estoy sentado en el Zócalo mientras el mariachi llena el aire con su melodía. Los colores de esta ciudad — los murales, los mercados, las flores — son un festín para los ojos. Espero que este mensaje te llegue con todo el sabor de México. ¿Cómo estás?',
      },
      {
        'name': 'Kemal A.',
        'country': '터키',
        'flag': '🇹🇷',
        'lat': 41.0082,
        'lng': 28.9784,
        'content':
            'Merhaba İstanbul\'dan! Boğaz\'da iki kıtanın buluştuğu noktada oturmuş, sana bu mektubu yazıyorum. Şehrin sesi, seyyar satıcıların bağrışları ve uzaktan gelen ezan sesiyle harmanlı. Dünyanın bir başka köşesinde yaşayan sana buradan selam yolluyorum. Nasılsın?',
      },
      {
        'name': 'Valentina M.',
        'country': '아르헨티나',
        'flag': '🇦🇷',
        'lat': -34.6037,
        'lng': -58.3816,
        'content':
            '¡Buenas desde Buenos Aires! Esta noche fui a una milonga y el tango me envolvió como ningún otro baile puede hacerlo. Hay algo en los pasos del tango que habla de amor, de pérdida, de esperanza. Quería compartir este momento con alguien del otro lado del mundo. ¿Cómo estás tú?',
      },
      {
        'name': 'Ana L.',
        'country': '포르투갈',
        'flag': '🇵🇹',
        'lat': 38.7169,
        'lng': -9.1399,
        'content':
            'Olá de Lisboa! Estou sentada num café a ouvir fado enquanto o sol se põe sobre o rio Tejo. Há uma palavra portuguesa — saudade — que não tem tradução, mas que sinto agora ao escrever-te. É a melancolia doce de tudo o que foi ou poderia ser. Espero que estejas bem, amigo distante.',
      },
      {
        'name': 'Lars B.',
        'country': '스웨덴',
        'flag': '🇸🇪',
        'lat': 59.3293,
        'lng': 18.0686,
        'content':
            'Hej från Stockholm! Det är midnattssol och himlen är aldrig helt mörk den här årstiden. Jag sitter vid vattnet och funderar på hur stor världen egentligen är. Det finns något magiskt med att skicka ett brev till någon man aldrig träffat. Hur mår du, var du än är?',
      },
      {
        'name': 'Nguyen T.',
        'country': '베트남',
        'flag': '🇻🇳',
        'lat': 21.0285,
        'lng': 105.8542,
        'content':
            'Xin chào từ Hà Nội! Tôi đang ngồi bên hồ Hoàn Kiếm, nhìn mặt hồ gợn sóng trong buổi sáng sớm. Mùi cà phê trứng thơm nồng từ quán nhỏ bên cạnh cứ vấn vương. Tôi muốn gửi đến bạn một chút bình yên của buổi sáng Hà Nội hôm nay. Bạn có khỏe không?',
      },
      {
        'name': 'Aisha M.',
        'country': '나이지리아',
        'flag': '🇳🇬',
        'lat': 6.5244,
        'lng': 3.3792,
        'content':
            'Hello from Lagos! This city never sleeps — it hums, it dances, it shouts with life at every hour. I am writing to you from my balcony as the sun rises over the lagoon, painting everything in shades of copper and gold. Africa has a pulse unlike anywhere else. How are you, friend?',
      },
      {
        'name': 'Amina K.',
        'country': '케냐',
        'flag': '🇰🇪',
        'lat': -1.2921,
        'lng': 36.8219,
        'content':
            'Jambo kutoka Nairobi! Asubuhi hii nilikuwa bustanini nikitazama ndege wa rangi mbalimbali wakizunguka. Kenya ni nchi ya maajabu — misitu, savana, na watu wenye moyo mkunjufu. Nilitaka kukushirikisha furaha hii ndogo. Je, uko salama?',
      },
      {
        'name': 'Carlos P.',
        'country': '페루',
        'flag': '🇵🇪',
        'lat': -13.1631,
        'lng': -72.5450,
        'content':
            '¡Saludos desde Machu Picchu! Estoy entre las ruinas de los incas, donde las nubes rozan las piedras antiguas y el silencio habla más fuerte que las palabras. Subir aquí fue como tocar el cielo con las manos. Quería compartir este instante suspendido en el tiempo contigo. ¿Cómo estás?',
      },
      {
        'name': 'Fatima Z.',
        'country': '모로코',
        'flag': '🇲🇦',
        'lat': 34.0209,
        'lng': -6.8416,
        'content':
            'مرحباً من الرباط! أجلس في حديقة القصبة والياسمين يملأ الهواء برائحته الزكية. المغرب بلد الألوان والروائح والحكايات القديمة. أريد أن أهديك لحظة من هذا الهدوء الجميل. كيف حالك في مكانك البعيد؟',
      },
      {
        'name': 'Pita F.',
        'country': '뉴질랜드',
        'flag': '🇳🇿',
        'lat': -36.8485,
        'lng': 174.7633,
        'content':
            'Kia ora from Auckland! I\'ve just come back from a hike along the Waitakere ranges, and my heart is still full of green hills and crashing waves. New Zealand is like a dream you don\'t want to wake from. I hope this letter carries a little of that wonder to wherever you are. How\'s life treating you?',
      },
      {
        'name': 'Marcin W.',
        'country': '폴란드',
        'flag': '🇵🇱',
        'lat': 52.2297,
        'lng': 21.0122,
        'content':
            'Witaj z Warszawy! Siedzę przy Wiśle i patrzę, jak miasto odbija się w spokojnej wodzie. Warszawa nosi w sobie blizny historii, ale też niesamowitą siłę odrodzenia. Jest coś pięknego w wysyłaniu listu do kogoś, kogo nigdy nie spotkałem. Jak się masz po tamtej stronie świata?',
      },
    ];

    for (int i = 0; i < allSenders.length; i++) {
      final s = allSenders[i];
      final letterId = 'world_test_v3_$i';
      // 각 편지마다 다른 한국 랜덤 주소로 발송
      final korCity = koreaCitiesAll[rng.nextInt(koreaCitiesAll.length)];
      final toLat = (korCity['lat'] as num).toDouble();
      final toLng = (korCity['lng'] as num).toDouble();
      final letter = _makeMockLetter(
        id: letterId,
        senderName: s['name'] as String,
        senderCountry: s['country'] as String,
        senderFlag: s['flag'] as String,
        content: s['content'] as String,
        fromCountry: s['country'] as String,
        fromLat: (s['lat'] as num).toDouble(),
        fromLng: (s['lng'] as num).toDouble(),
        toCountry: '대한민국',
        toLat: toLat,
        toLng: toLng,
        segProgress: [rng.nextDouble() * 0.8, 0.0, 0.0],
        segIdx: 0,
        status: DeliveryStatus.inTransit,
        hoursAgo: rng.nextInt(48),
      );
      _worldLetters.add(letter);
    }
    _saveToPrefs();
    notifyListeners();
  }

  // ── Firestore: 지도 회원 타워 불러오기 ────────────────────────────────────
  Future<void> fetchMapUsers({bool force = false}) async {
    if (!FirebaseConfig.kFirebaseEnabled) {
      // Firebase 비활성 시에도 데모 타워 표시
      if (_mapUsers.isEmpty) {
        final demoUsers = _buildDemoMapUsers();
        demoUsers.sort((a, b) => b.floors.compareTo(a.floors));
        _mapUsers = demoUsers
            .asMap()
            .entries
            .map((e) => e.value.copyWith(rank: e.key + 1))
            .toList();
        notifyListeners();
      }
      return;
    }
    if (_isFetchingMapUsers) return;
    final now = DateTime.now();
    if (!force &&
        _lastMapUsersFetchedAt != null &&
        _mapUsers.isNotEmpty &&
        now.difference(_lastMapUsersFetchedAt!) < _mapUsersMinRefreshInterval) {
      return;
    }

    _isFetchingMapUsers = true;
    try {
      double parseDouble(Map<String, dynamic> fields, String key) {
        final f = fields[key];
        if (f == null) return 0.0;
        final v = f as Map<String, dynamic>;
        return (v['doubleValue'] as num?)?.toDouble() ??
            double.tryParse(v['integerValue']?.toString() ?? '') ??
            0.0;
      }

      int parseInt(Map<String, dynamic> fields, String key) {
        final f = fields[key];
        if (f == null) return 0;
        final v = f as Map<String, dynamic>;
        return int.tryParse(v['integerValue']?.toString() ?? '') ??
            (v['doubleValue'] as num?)?.toInt() ??
            0;
      }

      String parseString(
        Map<String, dynamic> fields,
        String key, {
        String fallback = '',
      }) {
        final f = fields[key];
        if (f is! Map) return fallback;
        final v = Map<String, dynamic>.from(f);
        final value =
            (v['stringValue'] ??
                    v['integerValue'] ??
                    v['doubleValue'] ??
                    v['timestampValue'] ??
                    fallback)
                .toString()
                .trim();
        return value;
      }

      bool parseBool(
        Map<String, dynamic> fields,
        String key, {
        bool fallback = false,
      }) {
        final f = fields[key];
        if (f is! Map) return fallback;
        final v = Map<String, dynamic>.from(f);
        final raw = v['boolValue'];
        if (raw is bool) return raw;
        if (raw is String) return raw.toLowerCase() == 'true';
        return fallback;
      }

      String extractDocId(
        Map<String, dynamic> doc,
        Map<String, dynamic> fields,
      ) {
        final fromField = parseString(fields, 'id');
        if (fromField.isNotEmpty) return fromField;
        final fullName = (doc['name'] ?? '').toString().trim();
        if (fullName.isEmpty) return '';
        return fullName.split('/').last.trim();
      }

      final users = <MapUser>[];
      final seenUserIds = <String>{};
      String? nextPageToken;
      int fetchedPageCount = 0;

      String buildUsersListUrl(String pageToken) {
        final params = <String>[
          'key=${Uri.encodeQueryComponent(FirebaseConfig.apiKey)}',
          'pageSize=$_mapUsersPageSize',
          // 필수 필드만 요청해서 데이터 노출 범위 최소화
          'mask.fieldPaths=id',
          'mask.fieldPaths=countryFlag',
          'mask.fieldPaths=latitude',
          'mask.fieldPaths=longitude',
          'mask.fieldPaths=isMapPublic',
          'mask.fieldPaths=isUsernamePublic',
          'mask.fieldPaths=username',
          'mask.fieldPaths=receivedCount',
          'mask.fieldPaths=replyCount',
          'mask.fieldPaths=sentCount',
          'mask.fieldPaths=likeCount',
          'mask.fieldPaths=customTowerName',
        ];
        if (pageToken.isNotEmpty) {
          params.add('pageToken=${Uri.encodeQueryComponent(pageToken)}');
        }
        return '${FirebaseConfig.firestoreBase}/users?${params.join('&')}';
      }

      do {
        fetchedPageCount++;
        final pageToken = nextPageToken?.trim() ?? '';
        final url = Uri.parse(buildUsersListUrl(pageToken));

        final res = await http.get(url).timeout(const Duration(seconds: 20));
        if (res.statusCode != 200) {
          debugPrint('[Firestore] fetchMapUsers http ${res.statusCode}');
          break;
        }

        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final docs = (data['documents'] as List?) ?? const [];

        for (final raw in docs.whereType<Map>()) {
          try {
            final doc = Map<String, dynamic>.from(raw);
            final fields = (doc['fields'] as Map<String, dynamic>?) ?? {};
            final id = extractDocId(doc, fields);
            if (id.isEmpty || id == _currentUser.id || !seenUserIds.add(id)) {
              continue;
            }

            final isMapPublic = parseBool(
              fields,
              'isMapPublic',
              fallback: parseBool(fields, 'isUsernamePublic', fallback: true),
            );
            if (!isMapPublic) continue;

            var lat = parseDouble(fields, 'latitude');
            var lng = parseDouble(fields, 'longitude');
            final flag = parseString(fields, 'countryFlag', fallback: '🌍');
            // Build 285: GPS 미허가 등으로 좌표 (0,0) 인 가입자는 국가 깃발
            // 기준으로 해당 국가 중심에 표시. 좌표·깃발 모두 없으면만 skip.
            if (lat == 0.0 && lng == 0.0) {
              final fallback = _countryFlagCenter(flag);
              if (fallback == null) continue;
              lat = fallback.$1;
              lng = fallback.$2;
            }
            final isPublic = parseBool(
              fields,
              'isUsernamePublic',
              fallback: false,
            );
            final usernameRaw = parseString(fields, 'username');
            final username = usernameRaw.isEmpty ? null : usernameRaw;

            final score = ActivityScore(
              receivedCount: parseInt(fields, 'receivedCount'),
              replyCount: parseInt(fields, 'replyCount'),
              sentCount: parseInt(fields, 'sentCount'),
              likeCount: parseInt(fields, 'likeCount'),
            );

            final towerNameRaw = parseString(fields, 'customTowerName');
            final towerName = towerNameRaw.isEmpty ? null : towerNameRaw;
            final towerColorRaw = parseString(fields, 'towerColor', fallback: '#FFD700');
            final towerAccentRaw = parseString(fields, 'towerAccentEmoji');
            final towerAccent = towerAccentRaw.isEmpty ? null : towerAccentRaw;

            // Build 240: receivedCount + sentCount 기반 근사 XP → level.
            // Firestore 에 km 누적은 없지만 활동량 비례하므로 마커 라벨엔 충분.
            final approxXp = score.receivedCount * 10 + score.sentCount * 5;
            final approxLevel = UserProgress.calcLevel(approxXp);
            users.add(
              MapUser(
                id: id,
                flag: flag,
                lat: lat,
                lng: lng,
                tier: score.tier,
                floors: score.towerFloors,
                rank: 0,
                level: approxLevel,
                username: isPublic ? username : null,
                towerName: towerName,
                towerColor: towerColorRaw,
                towerAccentEmoji: towerAccent,
                towerRoofStyle: parseInt(fields, 'towerRoofStyle'),
                towerWindowStyle: parseInt(fields, 'towerWindowStyle'),
              ),
            );
            if (users.length >= _mapUsersMaxCount) break;
          } catch (_) {}
        }

        nextPageToken = (data['nextPageToken'] ?? '').toString().trim();
      } while (nextPageToken.isNotEmpty &&
          fetchedPageCount < _mapUsersMaxPages &&
          users.length < _mapUsersMaxCount);

      // 항상 데모 타워 표시 (실제 유저가 없는 나라만)
      if (true) {
        // ── 가상 회원 데이터 추가 (20개국 데모) ──────────────────────────
        final demoUsers = _buildDemoMapUsers();
        // 이미 실제 유저가 있는 나라의 데모 유저는 제외 (중복 방지)
        final realCountryFlags = users.map((u) => u.flag).toSet();
        for (final demo in demoUsers) {
          if (!realCountryFlags.contains(demo.flag)) {
            users.add(demo);
          }
        }
      }

      // floors 내림차순 정렬 → 랭킹 부여
      users.sort((a, b) => b.floors.compareTo(a.floors));
      _mapUsers = users
          .asMap()
          .entries
          .map((e) => e.value.copyWith(rank: e.key + 1))
          .toList();
      _lastMapUsersFetchedAt = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('[Firestore] fetchMapUsers error: $e');
      // ── 오류 발생 시에도 데모 타워는 항상 표시 ──────────────────────────
      if (_mapUsers.isEmpty) {
        try {
          final demoUsers = _buildDemoMapUsers();
          demoUsers.sort((a, b) => b.floors.compareTo(a.floors));
          _mapUsers = demoUsers
              .asMap()
              .entries
              .map((e) => e.value.copyWith(rank: e.key + 1))
              .toList();
          notifyListeners();
        } catch (_) {}
      }
    } finally {
      _isFetchingMapUsers = false;
    }
  }

  // Build 285: countryFlag → 해당 국가 수도 좌표 fallback. GPS 미허가 가입자
  // 핀이 (0,0) 으로 죽지 않고 본인 나라에 표시되도록.
  (double, double)? _countryFlagCenter(String flag) {
    const m = <String, (double, double)>{
      '🇰🇷': (37.5665, 126.9780),
      '🇯🇵': (35.6762, 139.6503),
      '🇺🇸': (40.7128, -74.0060),
      '🇬🇧': (51.5074, -0.1278),
      '🇫🇷': (48.8566, 2.3522),
      '🇩🇪': (52.5200, 13.4050),
      '🇮🇹': (41.9028, 12.4964),
      '🇪🇸': (40.4168, -3.7038),
      '🇧🇷': (-23.5505, -46.6333),
      '🇮🇳': (28.6139, 77.2090),
      '🇨🇳': (39.9042, 116.4074),
      '🇦🇺': (-33.8688, 151.2093),
      '🇨🇦': (43.6532, -79.3832),
      '🇲🇽': (19.4326, -99.1332),
      '🇷🇺': (55.7558, 37.6173),
      '🇹🇷': (41.0082, 28.9784),
      '🇪🇬': (30.0444, 31.2357),
      '🇿🇦': (-26.2041, 28.0473),
      '🇹🇭': (13.7563, 100.5018),
      '🇦🇷': (-34.6037, -58.3816),
      '🇳🇱': (52.3676, 4.9041),
      '🇸🇪': (59.3293, 18.0686),
      '🇳🇴': (59.9139, 10.7522),
      '🇵🇹': (38.7223, -9.1393),
      '🇮🇩': (-6.2088, 106.8456),
      '🇲🇾': (3.1390, 101.6869),
      '🇸🇬': (1.3521, 103.8198),
      '🇳🇿': (-36.8485, 174.7633),
      '🇵🇭': (14.5995, 120.9842),
      '🇻🇳': (10.7769, 106.7009),
    };
    return m[flag];
  }

  // ── 가상 회원 20개국 데이터 ──────────────────────────────────────────────
  List<MapUser> _buildDemoMapUsers() {
    return [
      MapUser(
        id: 'demo_us',
        flag: '🇺🇸',
        lat: 40.7128,
        lng: -74.0060,
        tier: TowerTier.skyscraper,
        floors: 33,
        rank: 0,
        username: 'NYC_Writer',
      ),
      MapUser(
        id: 'demo_jp',
        flag: '🇯🇵',
        lat: 35.6762,
        lng: 139.6503,
        tier: TowerTier.supertall,
        floors: 42,
        rank: 0,
        username: 'TokyoPen',
      ),
      MapUser(
        id: 'demo_gb',
        flag: '🇬🇧',
        lat: 51.5074,
        lng: -0.1278,
        tier: TowerTier.office,
        floors: 24,
        rank: 0,
        username: 'LondonInk',
      ),
      MapUser(
        id: 'demo_fr',
        flag: '🇫🇷',
        lat: 48.8566,
        lng: 2.3522,
        tier: TowerTier.building,
        floors: 18,
        rank: 0,
        username: 'ParisDreamer',
      ),
      MapUser(
        id: 'demo_de',
        flag: '🇩🇪',
        lat: 52.5200,
        lng: 13.4050,
        tier: TowerTier.house,
        floors: 8,
        rank: 0,
        username: 'BerlinWords',
      ),
      MapUser(
        id: 'demo_au',
        flag: '🇦🇺',
        lat: -33.8688,
        lng: 151.2093,
        tier: TowerTier.building,
        floors: 16,
        rank: 0,
        username: 'SydneyWriter',
      ),
      MapUser(
        id: 'demo_br',
        flag: '🇧🇷',
        lat: -23.5505,
        lng: -46.6333,
        tier: TowerTier.cottage,
        floors: 3,
        rank: 0,
        username: 'Rio_Letters',
      ),
      MapUser(
        id: 'demo_in',
        flag: '🇮🇳',
        lat: 28.6139,
        lng: 77.2090,
        tier: TowerTier.townhouse,
        floors: 12,
        rank: 0,
        username: 'DelhiPen',
      ),
      MapUser(
        id: 'demo_cn',
        flag: '🇨🇳',
        lat: 39.9042,
        lng: 116.4074,
        tier: TowerTier.skyscraper,
        floors: 35,
        rank: 0,
        username: 'BeijingQuill',
      ),
      MapUser(
        id: 'demo_ru',
        flag: '🇷🇺',
        lat: 55.7558,
        lng: 37.6176,
        tier: TowerTier.office,
        floors: 22,
        rank: 0,
        username: 'MoscowMemo',
      ),
      MapUser(
        id: 'demo_it',
        flag: '🇮🇹',
        lat: 41.9028,
        lng: 12.4964,
        tier: TowerTier.townhouse,
        floors: 11,
        rank: 0,
        username: 'RomaPenna',
      ),
      MapUser(
        id: 'demo_es',
        flag: '🇪🇸',
        lat: 40.4168,
        lng: -3.7038,
        tier: TowerTier.house,
        floors: 7,
        rank: 0,
        username: 'MadridLetras',
      ),
      MapUser(
        id: 'demo_ca',
        flag: '🇨🇦',
        lat: 45.4215,
        lng: -75.6919,
        tier: TowerTier.building,
        floors: 19,
        rank: 0,
        username: 'CanadaInk',
      ),
      MapUser(
        id: 'demo_mx',
        flag: '🇲🇽',
        lat: 19.4326,
        lng: -99.1332,
        tier: TowerTier.cottage,
        floors: 4,
        rank: 0,
        username: 'MexicoPluma',
      ),
      MapUser(
        id: 'demo_za',
        flag: '🇿🇦',
        lat: -26.2041,
        lng: 28.0473,
        tier: TowerTier.house,
        floors: 9,
        rank: 0,
        username: 'CapePenman',
      ),
      MapUser(
        id: 'demo_th',
        flag: '🇹🇭',
        lat: 13.7563,
        lng: 100.5018,
        tier: TowerTier.townhouse,
        floors: 13,
        rank: 0,
        username: 'BangkokScribe',
      ),
      MapUser(
        id: 'demo_eg',
        flag: '🇪🇬',
        lat: 30.0444,
        lng: 31.2357,
        tier: TowerTier.cottage,
        floors: 5,
        rank: 0,
        username: 'CairoLetters',
      ),
      MapUser(
        id: 'demo_gr',
        flag: '🇬🇷',
        lat: 37.9838,
        lng: 23.7275,
        tier: TowerTier.house,
        floors: 6,
        rank: 0,
        username: 'AthensWriter',
      ),
      MapUser(
        id: 'demo_id',
        flag: '🇮🇩',
        lat: -8.4095,
        lng: 115.1889,
        tier: TowerTier.cottage,
        floors: 3,
        rank: 0,
        username: 'BaliWords',
      ),
      MapUser(
        id: 'demo_tr',
        flag: '🇹🇷',
        lat: 41.0082,
        lng: 28.9784,
        tier: TowerTier.townhouse,
        floors: 10,
        rank: 0,
        username: 'IstanbulMemo',
      ),
      MapUser(
        id: 'demo_ar',
        flag: '🇦🇷',
        lat: -34.6037,
        lng: -58.3816,
        tier: TowerTier.house,
        floors: 7,
        rank: 0,
        username: 'BsAsWriter',
      ),
      MapUser(
        id: 'demo_pt',
        flag: '🇵🇹',
        lat: 38.7169,
        lng: -9.1399,
        tier: TowerTier.cottage,
        floors: 5,
        rank: 0,
        username: 'LisbonPen',
      ),
      MapUser(
        id: 'demo_se',
        flag: '🇸🇪',
        lat: 59.3293,
        lng: 18.0686,
        tier: TowerTier.building,
        floors: 15,
        rank: 0,
        username: 'StockholmInk',
      ),
      MapUser(
        id: 'demo_vn',
        flag: '🇻🇳',
        lat: 21.0285,
        lng: 105.8542,
        tier: TowerTier.townhouse,
        floors: 11,
        rank: 0,
        username: 'HanoiQuill',
      ),
      MapUser(
        id: 'demo_ng',
        flag: '🇳🇬',
        lat: 6.5244,
        lng: 3.3792,
        tier: TowerTier.house,
        floors: 8,
        rank: 0,
        username: 'LagosLetters',
      ),
      MapUser(
        id: 'demo_ke',
        flag: '🇰🇪',
        lat: -1.2921,
        lng: 36.8219,
        tier: TowerTier.cottage,
        floors: 4,
        rank: 0,
        username: 'NairobiWords',
      ),
      MapUser(
        id: 'demo_pe',
        flag: '🇵🇪',
        lat: -13.1631,
        lng: -72.5450,
        tier: TowerTier.house,
        floors: 6,
        rank: 0,
        username: 'MachuScribe',
      ),
      MapUser(
        id: 'demo_ma',
        flag: '🇲🇦',
        lat: 34.0209,
        lng: -6.8416,
        tier: TowerTier.cottage,
        floors: 4,
        rank: 0,
        username: 'RabatPen',
      ),
      MapUser(
        id: 'demo_nz',
        flag: '🇳🇿',
        lat: -36.8485,
        lng: 174.7633,
        tier: TowerTier.building,
        floors: 14,
        rank: 0,
        username: 'AucklandInk',
      ),
      MapUser(
        id: 'demo_pl',
        flag: '🇵🇱',
        lat: 52.2297,
        lng: 21.0122,
        tier: TowerTier.townhouse,
        floors: 12,
        rank: 0,
        username: 'WarsawWriter',
      ),
    ];
  }

  // ── 목업 데이터 초기화 ─────────────────────────────────────────────────────
  void _initMockData() {
    final letters = [
      _makeMockLetter(
        id: 'l1',
        senderName: 'Emma W.',
        senderCountry: '영국',
        senderFlag: '🇬🇧',
        content:
            '비가 내리는 런던의 카페에서 이 편지를 씁니다. 오늘따라 낯선 곳의 낯선 누군가와 연결되고 싶었어요. 당신은 지금 어디에 있나요?',
        fromCountry: '영국',
        fromLat: 51.5074,
        fromLng: -0.1278,
        toCountry: '대한민국',
        toLat: 37.5665,
        toLng: 126.9780,
        segProgress: [1.0, 1.0, 0.7],
        segIdx: 2,
        status: DeliveryStatus.inTransit,
        hoursAgo: 5,
      ),
      _makeMockLetter(
        id: 'l2',
        senderName: 'Kenji M.',
        senderCountry: '일본',
        senderFlag: '🇯🇵',
        content:
            '桜の季節が来ました。벚꽃이 피는 계절이 왔습니다. 도쿄의 봄은 정말 아름다워요. 세상 어딘가의 당신에게도 봄이 오길 바랍니다.',
        fromCountry: '일본',
        fromLat: 35.6762,
        fromLng: 139.6503,
        toCountry: '프랑스',
        toLat: 48.8566,
        toLng: 2.3522,
        segProgress: [1.0, 0.45, 0.0],
        segIdx: 1,
        status: DeliveryStatus.inTransit,
        hoursAgo: 3,
      ),
      _makeMockLetter(
        id: 'l3',
        senderName: 'Sofia R.',
        senderCountry: '이탈리아',
        senderFlag: '🇮🇹',
        content:
            'Ciao! 로마의 트레비 분수 앞에서 동전을 던지며 이 편지를 씁니다. 소원은 비밀이에요. 당신의 소원은 무엇인가요?',
        fromCountry: '이탈리아',
        fromLat: 41.9028,
        fromLng: 12.4964,
        toCountry: '미국',
        toLat: 40.7128,
        toLng: -74.0060,
        segProgress: [0.6, 0.0, 0.0],
        segIdx: 0,
        status: DeliveryStatus.inTransit,
        hoursAgo: 1,
      ),
      _makeMockLetter(
        id: 'l4',
        senderName: 'Carlos M.',
        senderCountry: '멕시코',
        senderFlag: '🇲🇽',
        content: '¡Hola! 멕시코시티의 밤은 형형색색의 불빛으로 가득합니다. 언젠가 이곳에 꼭 와보세요!',
        fromCountry: '멕시코',
        fromLat: 19.4326,
        fromLng: -99.1332,
        toCountry: '호주',
        toLat: -33.8688,
        toLng: 151.2093,
        segProgress: [1.0, 0.62, 0.0],
        segIdx: 1,
        status: DeliveryStatus.inTransit,
        hoursAgo: 4,
      ),
      _makeMockLetter(
        id: 'l7',
        senderName: 'Liam O.',
        senderCountry: '호주',
        senderFlag: '🇦🇺',
        content:
            'G\'day! 시드니 오페라 하우스 앞에서 씁니다. 남반구의 하늘은 북반구와 별자리가 달라요. 같은 하늘 아래 다른 별을 보고 있다는 게 신기하지 않나요?',
        fromCountry: '호주',
        fromLat: -33.8688,
        fromLng: 151.2093,
        toCountry: '대한민국',
        toLat: 37.5665,
        toLng: 126.9780,
        segProgress: [1.0, 1.0, 0.95],
        segIdx: 2,
        status: DeliveryStatus.nearYou,
        hoursAgo: 6,
      ),
    ];

    _worldLetters.addAll(letters);

    // 도착 후 미열람 편지 마커 테스트용 (delivered + !isReadByRecipient → 📮 마커)
    final deliveredMock = _makeMockLetter(
      id: 'l_delivered_test',
      senderName: 'Mia Chen',
      senderCountry: '대만',
      senderFlag: '🇹🇼',
      content: '타이베이에서 보내는 편지입니다. 잘 도착했으면 좋겠어요!',
      fromCountry: '대만',
      fromLat: 25.0330,
      fromLng: 121.5654,
      toCountry: '대한민국',
      toLat: 35.1796,
      toLng: 129.0756,
      segProgress: [1.0, 1.0, 1.0],
      segIdx: 2,
      status: DeliveryStatus.delivered,
      hoursAgo: 2,
    );
    _worldLetters.add(deliveredMock);

    // 받은 편지함
    final inbox1 = _makeMockLetter(
      id: 'inbox1',
      senderName: 'Alex K.',
      senderCountry: '독일',
      senderFlag: '🇩🇪',
      content:
          'Guten Tag! 베를린의 브란덴부르크 문 앞에서 씁니다. 역사의 무게가 느껴지는 이곳에서, 당신에게 안녕을 전합니다.',
      fromCountry: '독일',
      fromLat: 52.5200,
      fromLng: 13.4050,
      toCountry: '대한민국',
      toLat: 37.5665,
      toLng: 126.9780,
      segProgress: [1.0, 1.0, 1.0],
      segIdx: 2,
      status: DeliveryStatus.delivered,
      hoursAgo: 12,
    );
    _inbox.add(inbox1);

    // 번역 테스트용: 일본어 편지
    final inbox2 = _makeMockLetter(
      id: 'inbox2',
      senderName: 'Hana T.',
      senderCountry: '일본',
      senderFlag: '🇯🇵',
      content:
          '桜が満開の京都から手紙を送ります。今年の春は特別に美しいです。嵐山の竹林を歩きながら、遠くにいる誰かと繋がりたいと思いました。あなたの街では今、どんな季節ですか？いつかお互いの国を訪れてみたいですね。',
      fromCountry: '일본',
      fromLat: 35.0116,
      fromLng: 135.7681,
      toCountry: '대한민국',
      toLat: 37.5665,
      toLng: 126.9780,
      segProgress: [1.0, 1.0, 1.0],
      segIdx: 2,
      status: DeliveryStatus.delivered,
      hoursAgo: 18,
    );
    _inbox.add(inbox2);

    // 번역 테스트용: 프랑스어 편지
    final inbox3 = _makeMockLetter(
      id: 'inbox3',
      senderName: 'Marie L.',
      senderCountry: '프랑스',
      senderFlag: '🇫🇷',
      content:
          'Bonjour depuis Paris ! Je t\'écris depuis un café près de la Seine, avec une tasse de café au lait. La tour Eiffel scintille ce soir et je me sens inspirée. La vie est tellement belle quand on prend le temps de la regarder. Comment vas-tu de ton côté du monde ?',
      fromCountry: '프랑스',
      fromLat: 48.8566,
      fromLng: 2.3522,
      toCountry: '대한민국',
      toLat: 37.5665,
      toLng: 126.9780,
      segProgress: [1.0, 1.0, 1.0],
      segIdx: 2,
      status: DeliveryStatus.delivered,
      hoursAgo: 24,
    );
    _inbox.add(inbox3);

    // 📸 사진 + 링크 첨부 예시 편지 (미국) — 마지막에 추가해서 목록 최상단에 표시
    final inbox4 = _makeMockLetter(
      id: 'inbox4_photo',
      senderName: 'Sofia M.',
      senderCountry: '미국',
      senderFlag: '🇺🇸',
      content:
          'Hello from New York! 🗽\n\n오늘 센트럴 파크에서 찍은 사진을 보내드려요. 벚꽃이 한창이라 정말 아름답답니다. 언젠가 뉴욕에 오시면 꼭 봄에 오세요.\n\nI hope this little piece of my world finds you well. 당신의 일상도 이렇게 아름다우면 좋겠어요 🌸',
      fromCountry: '미국',
      fromLat: 40.7851,
      fromLng: -73.9683,
      toCountry: '대한민국',
      toLat: 37.5665,
      toLng: 126.9780,
      segProgress: [1.0, 1.0, 1.0],
      segIdx: 2,
      status: DeliveryStatus.delivered,
      hoursAgo: 6,
      imageUrl:
          'https://images.unsplash.com/photo-1534430480872-3498386e7856?w=800&q=80',
      socialLink: 'https://instagram.com/sofia.nyc',
      isAnonymous: false,
      paperStyle: 2,
    );
    _inbox.add(inbox4);

    // 보낸 편지 목업은 실제 출발지 오해를 줄이기 위해 제거
  }

  Letter _makeMockLetter({
    required String id,
    required String senderName,
    required String senderCountry,
    required String senderFlag,
    required String content,
    required String fromCountry,
    required double fromLat,
    required double fromLng,
    required String toCountry,
    required double toLat,
    required double toLng,
    required List<double> segProgress,
    required int segIdx,
    required DeliveryStatus status,
    required int hoursAgo,
    String? destinationCity,
    String? imageUrl,
    String? socialLink,
    bool isAnonymous = true,
    int paperStyle = 0,
    int fontStyle = 0,
  }) {
    final fromCity = LatLng(fromLat, fromLng);
    final toCity = LatLng(toLat, toLng);
    final segments = LogisticsHubs.buildRoute(
      fromCountry: fromCountry,
      fromCity: fromCity,
      toCountry: toCountry,
      toCity: toCity,
    );

    // 구간 진행도 적용
    for (int i = 0; i < segments.length && i < segProgress.length; i++) {
      segments[i].progress = segProgress[i];
    }

    final totalMin = segments.fold<int>(
      0,
      (s, seg) => s + seg.estimatedMinutes,
    );

    return Letter(
      id: id,
      senderId: 'mock_$senderName',
      senderName: senderName,
      senderCountry: senderCountry,
      senderCountryFlag: senderFlag,
      content: content,
      originLocation: fromCity,
      destinationLocation: toCity,
      destinationCountry: toCountry,
      destinationCountryFlag: countries.firstWhere(
        (c) => c['name'] == toCountry,
        orElse: () => {'flag': '🌍'},
      )['flag']!,
      destinationCity: destinationCity,
      segments: segments,
      currentSegmentIndex: segIdx.clamp(0, segments.length - 1),
      status: status,
      sentAt: DateTime.now().subtract(Duration(hours: hoursAgo)),
      arrivalTime:
          status == DeliveryStatus.inTransit || status == DeliveryStatus.nearYou
          ? DateTime.now()
                .subtract(Duration(hours: hoursAgo))
                .add(Duration(minutes: totalMin))
          : null,
      arrivedAt:
          status == DeliveryStatus.delivered || status == DeliveryStatus.read
          ? DateTime.now().subtract(const Duration(hours: 1))
          : null,
      estimatedTotalMinutes: totalMin,
      imageUrl: imageUrl,
      socialLink: socialLink,
      isAnonymous: isAnonymous,
      paperStyle: paperStyle,
      fontStyle: fontStyle,
    );
  }

  // ── 배송 시뮬레이션 ────────────────────────────────────────────────────────
  void _startDeliverySimulation() {
    _deliveryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _runDeliveryTick();
    });
  }

  void _runDeliveryTick({bool triggerNotifications = true}) {
    bool changed = false;
    final now = DateTime.now();
    final List<Letter> dailyToInbox = [];

    for (final letter in _worldLetters) {
        // deliveredFar 편지: 유저가 반경 이내로 이동하면 nearYou로 변경
        if (letter.status == DeliveryStatus.deliveredFar) {
          final dist = letter.destinationLocation.distanceTo(
            LatLng(_currentUser.latitude, _currentUser.longitude),
          );
          if (dist <= pickupRadiusMeters) {
            letter.status = DeliveryStatus.nearYou;
            _hasNearbyAlert = true;
            if (triggerNotifications) _triggerNearbyNotification(letter);
            changed = true;
          }
          continue;
        }

        // nearYou 편지: 유저가 반경 밖으로 이동하면 deliveredFar로 되돌림
        if (letter.status == DeliveryStatus.nearYou) {
          final dist = letter.destinationLocation.distanceTo(
            LatLng(_currentUser.latitude, _currentUser.longitude),
          );
          if (dist > pickupRadiusMeters) {
            letter.status = DeliveryStatus.deliveredFar;
            changed = true;
          }
          continue;
        }

        if (letter.status != DeliveryStatus.inTransit) continue;

        // Build 247: 방어적 픽스 — inTransit 이지만 arrivalTime 이 null 인 letter
        // 자동 보정. 이전엔 arrivalTime 없으면 progress 가 0 에서 멈춰서
        // "보내던 혜택이 멈춰 보임" 증상. estimatedTotalMinutes 또는 segments
        // 합으로 계산해서 즉시 채워줌.
        if (letter.arrivalTime == null) {
          final segMin = letter.segments.fold<int>(
            0,
            (s, seg) => s + (seg.estimatedMinutes <= 0 ? 1 : seg.estimatedMinutes),
          );
          final mins = letter.estimatedTotalMinutes > 0
              ? letter.estimatedTotalMinutes
              : (segMin > 0 ? segMin : 30); // 최후 fallback 30분
          letter.arrivalTime = letter.sentAt.add(Duration(minutes: mins));
          changed = true;
        }

        if (_syncLetterProgressWithClock(letter, now)) {
          changed = true;
        }

        final arrived = !now.isBefore(letter.arrivalTime!);

        if (arrived) {
          // daily_ 편지: 거리와 무관하게 자동으로 inbox로 이동
          if (letter.id.startsWith('daily_')) {
            letter.status = DeliveryStatus.delivered;
            letter.arrivedAt ??= now;
            dailyToInbox.add(letter);
            changed = true;
            continue;
          }
          // 내 위치 반경 이내인지 확인
          final dist = letter.destinationLocation.distanceTo(
            LatLng(_currentUser.latitude, _currentUser.longitude),
          );
          if (dist <= pickupRadiusMeters) {
            // 실제 반경 이내
            letter.status = DeliveryStatus.nearYou;
            _hasNearbyAlert = true;
            if (triggerNotifications) _triggerNearbyNotification(letter);
          } else {
            // 반경 밖에 있으면 deliveredFar (지도에 표시되지만 열 수 없음)
            letter.status = DeliveryStatus.deliveredFar;
            if (triggerNotifications) {
              NotificationService.showLetterArrivedNotification(
                senderCountry: letter.senderCountry,
                senderFlag: letter.senderCountryFlag,
                langCode: _currentUser.languageCode,
              );
            }
          }
          letter.arrivedAt ??= now;
          changed = true;
        }
      }

      // daily 편지: worldLetters → inbox 이동
      for (final l in dailyToInbox) {
        _worldLetters.removeWhere((x) => x.id == l.id);
        _inbox.add(l);
        _currentUser.activityScore.receivedCount++;
        NotificationService.showLetterArrivedNotification(
          senderCountry: l.senderCountry,
          senderFlag: l.senderCountryFlag,
          langCode: _currentUser.languageCode,
        );
      }
      if (dailyToInbox.isNotEmpty) {
        changed = true;
      }

      if (changed) {
        _saveToPrefs();
        notifyListeners();
      }

      // Build 283 (Brand auto-drop Phase 2): 사용자 위치 update 마다 가까운
      // brand_zone 매칭 → 처음 만나는 zone 마다 letter 1통 자동 발급.
      // 비동기 호출 — _runDeliveryTick 의 sync 흐름을 막지 않음. trigger 결과는
      // 다음 tick (또는 즉시 fire-and-forget) 에서 _worldLetters / _inbox 갱신.
      _checkBrandZoneTriggers(triggerNotifications: triggerNotifications);
  }

  /// Build 283: BrandZoneService 호출 + 새 zone 진입 마다 자동 letter 생성.
  /// fire-and-forget — _runDeliveryTick 의 sync flow 를 차단 안 함.
  void _checkBrandZoneTriggers({bool triggerNotifications = true}) {
    if (_currentUser.id.isEmpty) return;
    if (_currentUser.latitude == 0 && _currentUser.longitude == 0) return;
    final userPos = LatLng(_currentUser.latitude, _currentUser.longitude);
    final userId = _currentUser.id;
    final notify = triggerNotifications;

    BrandZoneService.instance.triggerForUser(
      userId: userId,
      userPos: userPos,
      onZoneEnter: (zone, destination) async {
        _handleAutoBrandDrop(zone, destination, triggerNotification: notify);
      },
    ).catchError((e, st) {
      if (kDebugMode) debugPrint('[BrandZone] trigger err: $e\n$st');
      return const <BrandZone>[];
    });
  }

  /// Brand zone 진입 시 letter 자동 생성. _worldLetters (지도) + _inbox 에 add.
  /// status=nearYou (이미 픽업 반경 안 보장 — destination 이 user pos ± 30m).
  ///
  /// Firestore POST 는 본 letter 가 "이 사용자만의 것" 이라 skip (다른 device
  /// 가 봐도 의미 없음). 영구 dedup 은 SharedPreferences (BrandZoneService 가
  /// 책임). 사용자가 letter 를 읽거나 만료되면 자연스럽게 inbox 에서 정리.
  void _handleAutoBrandDrop(
    BrandZone zone,
    LatLng destination, {
    bool triggerNotification = true,
  }) {
    try {
      final now = DateTime.now();
      final id = 'brand_zone_${zone.id}_${now.millisecondsSinceEpoch}';

      // 사용자가 zone 안에 있고 destination 이 user pos ± 30m → 즉시 nearYou.
      final letter = Letter(
        id: id,
        senderId: zone.brandId,
        senderName: zone.brandName,
        senderCountry: _currentUser.country,
        senderCountryFlag: _currentUser.countryFlag,
        content: zone.content,
        originLocation: zone.center,
        destinationLocation: destination,
        destinationCountry: _currentUser.country,
        destinationCountryFlag: _currentUser.countryFlag,
        segments: const [],
        status: DeliveryStatus.nearYou,
        sentAt: now,
        arrivedAt: now,
        isAnonymous: false,
        estimatedTotalMinutes: 0,
        senderIsBrand: true,
        senderTier: LetterSenderTier.brand,
        category: LetterCategory.coupon,
        acceptsReplies: false,
        redemptionInfo: zone.redemptionInfo,
        // zone.expiresAt 와 픽업 후 72h 중 빠른 것 (Build 132 redemption vs
        // expiresAt 분리 패턴 따름). expiresAt = letter 가 지도에서 사라지는
        // 시각 (보통 12-72h).
        expiresAt: now.add(const Duration(hours: 72)),
        redemptionExpiresAt: zone.expiresAt,
        brandZoneId: zone.id,
      );

      _worldLetters.add(letter);
      _inbox.add(letter.clone());
      _hasNearbyAlert = true;
      _currentUser.activityScore.receivedCount++;

      if (triggerNotification) {
        // Build 263 카피 정리 후 — "혜택이 도착" 흐름 따름
        NotificationService.showLetterArrivedNotification(
          senderCountry: zone.brandName,
          senderFlag: '🎁',
          langCode: _currentUser.languageCode,
        );
      }

      if (kDebugMode) {
        debugPrint('[BrandZone] auto-drop ${zone.id} '
            'brand=${zone.brandName} dest=${destination.latitude.toStringAsFixed(5)},'
            '${destination.longitude.toStringAsFixed(5)}');
      }

      _saveToPrefs();
      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) debugPrint('[BrandZone] auto-drop err: $e\n$st');
    }
  }

  // ── AI 자동 편지 발송 (하루 3통, 랜덤 3개국 → 유저 나라 랜덤 주소) ──────────
  static const _aiSenders = <Map<String, Object>>[
    {'name': 'Emma', 'country': '영국', 'flag': '🇬🇧', 'lat': 51.5074, 'lng': -0.1278, 'city': 'London'},
    {'name': 'Yuki', 'country': '일본', 'flag': '🇯🇵', 'lat': 35.6762, 'lng': 139.6503, 'city': 'Tokyo'},
    {'name': 'Lucas', 'country': '브라질', 'flag': '🇧🇷', 'lat': -23.5505, 'lng': -46.6333, 'city': 'São Paulo'},
    {'name': 'Marie', 'country': '프랑스', 'flag': '🇫🇷', 'lat': 48.8566, 'lng': 2.3522, 'city': 'Paris'},
    {'name': 'James', 'country': '미국', 'flag': '🇺🇸', 'lat': 40.7128, 'lng': -74.0060, 'city': 'New York'},
    {'name': 'Lina', 'country': '독일', 'flag': '🇩🇪', 'lat': 52.5200, 'lng': 13.4050, 'city': 'Berlin'},
    {'name': 'Carlos', 'country': '스페인', 'flag': '🇪🇸', 'lat': 40.4168, 'lng': -3.7038, 'city': 'Madrid'},
    {'name': 'Mei', 'country': '중국', 'flag': '🇨🇳', 'lat': 31.2304, 'lng': 121.4737, 'city': 'Shanghai'},
    {'name': 'Alessandro', 'country': '이탈리아', 'flag': '🇮🇹', 'lat': 41.9028, 'lng': 12.4964, 'city': 'Rome'},
    {'name': 'Olivia', 'country': '호주', 'flag': '🇦🇺', 'lat': -33.8688, 'lng': 151.2093, 'city': 'Sydney'},
    {'name': 'Priya', 'country': '인도', 'flag': '🇮🇳', 'lat': 28.6139, 'lng': 77.2090, 'city': 'New Delhi'},
    {'name': 'Sven', 'country': '스웨덴', 'flag': '🇸🇪', 'lat': 59.3293, 'lng': 18.0686, 'city': 'Stockholm'},
    {'name': 'Fatima', 'country': '터키', 'flag': '🇹🇷', 'lat': 41.0082, 'lng': 28.9784, 'city': 'Istanbul'},
    {'name': 'Aiden', 'country': '캐나다', 'flag': '🇨🇦', 'lat': 43.6532, 'lng': -79.3832, 'city': 'Toronto'},
    {'name': 'Sofia', 'country': '아르헨티나', 'flag': '🇦🇷', 'lat': -34.6037, 'lng': -58.3816, 'city': 'Buenos Aires'},
    {'name': 'Jing', 'country': '태국', 'flag': '🇹🇭', 'lat': 13.7563, 'lng': 100.5018, 'city': 'Bangkok'},
    {'name': 'Anna', 'country': '러시아', 'flag': '🇷🇺', 'lat': 55.7558, 'lng': 37.6173, 'city': 'Moscow'},
    {'name': 'Noah', 'country': '뉴질랜드', 'flag': '🇳🇿', 'lat': -36.8485, 'lng': 174.7633, 'city': 'Auckland'},
  ];

  // 나라별 고유 언어 메시지 (flag → 3개 메시지)
  static const _aiMessagesByFlag = <String, List<String>>{
    '🇬🇧': [
      'Hello from London! 🌍\n\nI found this app today and wanted to send a letter to someone far away. I hope this little message brightens your day.\n\nTell me about your city — what\'s your favourite place to visit?',
      'Good day! ☕\n\nI\'m writing this from a cosy pub near the Thames. It\'s raining outside, of course. There\'s something rather lovely about writing to a stranger across the world.\n\nHow are you doing today?',
      'Hi there! 🌸\n\nI\'ve always been fascinated by different cultures. The food, the mountains, the scenery... your country seems wonderful.\n\nWould you like to be pen pals?',
    ],
    '🇯🇵': [
      'こんにちは！🌸\n\n東京からこの手紙を書いています。今日は桜が咲き始めて、街がピンク色に染まっています。\n\nあなたの街の春はどんな感じですか？いつか訪れてみたいです！',
      'はじめまして！✨\n\n日本から遠い国に手紙を送れるなんて素敵ですね。今カフェでコーヒーを飲みながら書いています。\n\nあなたの街のおすすめの場所を教えてください！',
      'やっほー！😊\n\n知らない誰かに手紙を送るってワクワクしますね。今夜は星がとてもきれいです。\n\nそちらの空はどうですか？',
    ],
    '🇧🇷': [
      'Olá! 🌍\n\nEstou escrevendo de São Paulo e queria mandar uma carta para alguém do outro lado do mundo. Espero que esta mensagem alegre o seu dia!\n\nMe conta sobre a sua cidade — qual é o seu lugar favorito?',
      'Oi! 🌸\n\nSempre sonhei em conhecer novas culturas. A comida, as montanhas... tudo parece maravilhoso.\n\nO que só os locais sabem sobre a sua cidade? Adoraria ouvir de você!',
      'E aí! 😊\n\nMandei esta carta sem saber quem vai receber. É isso que torna tudo tão emocionante, né?\n\nSe pudesse viajar para qualquer lugar amanhã, para onde iria?',
    ],
    '🇫🇷': [
      'Bonjour ! 🥐\n\nJe t\'écris depuis Paris, assis dans un café près de la Seine. Découvrir de nouvelles cultures me fascine — le mélange de tradition et de modernité est vraiment inspirant.\n\nQuelle est ta saison préférée chez toi ?',
      'Salut ! ✨\n\nC\'est incroyable de pouvoir envoyer des lettres à travers le monde comme ça. En ce moment, il pleut dehors et je regarde les gouttes sur la vitre.\n\nComment ça va chez toi ?',
      'Coucou ! 🌸\n\nJ\'ai toujours rêvé de voyager partout dans le monde. La nourriture, les montagnes, les temples... tout semble merveilleux.\n\nTu voudrais qu\'on devienne correspondants ?',
    ],
    '🇺🇸': [
      'Hey there! 🌍\n\nWriting from New York City! I found this app and thought it would be cool to connect with someone across the world.\n\nWhat\'s your favorite place to hang out in your city?',
      'Hi! 🎵\n\nMusic has no borders. I\'ve been exploring different world music lately and it inspired me to write to a stranger.\n\nWhat songs are you listening to these days?',
      'What\'s up! 🍜\n\nI love trying food from different countries. What\'s your favorite local dish?\n\nI\'d love to try making it someday!',
    ],
    '🇩🇪': [
      'Hallo aus Berlin! 🌍\n\nIch schreibe dir aus einem Café an der Spree. Es ist faszinierend, dass wir Briefe um die Welt schicken können.\n\nWie ist das Leben bei dir? Erzähl mir von deiner Stadt!',
      'Guten Tag! ✨\n\nHeute Abend sind die Sterne wunderschön. Ob wohl jemand auf der anderen Seite der Welt gerade die gleichen Sterne sieht?\n\nIch hoffe, es geht dir gut!',
      'Hi! 😊\n\nIch habe diesen Brief in die Welt geschickt, ohne zu wissen, wer ihn empfangen wird. Das macht es so aufregend!\n\nWohin würdest du morgen reisen, wenn du könntest?',
    ],
    '🇪🇸': [
      '¡Hola desde Madrid! 🌍\n\nHoy encontré esta app y quise enviar una carta a alguien del otro lado del mundo. ¡Espero que este mensaje te alegre el día!\n\nCuéntame de tu ciudad — ¿cuál es tu lugar favorito?',
      '¡Hey! 🌸\n\nSiempre soñé con conocer nuevas culturas. La comida, las montañas... todo parece maravilloso.\n\n¿Qué es algo de tu país que solo los locales saben?',
      '¡Buenas! ☕\n\nEstoy tomando café mientras escribo esto. Me encanta conectar con personas de diferentes países.\n\n¿Cuál es tu bebida favorita?',
    ],
    '🇨🇳': [
      '你好！🌍\n\n我从上海给你写这封信。能把信寄到世界另一端，真是太神奇了。\n\n跟我聊聊你的城市吧——你最喜欢的地方是哪里？',
      '嗨！🌸\n\n我一直梦想着去世界各地旅行。听说你那里的风景特别美，是真的吗？\n\n希望我们能成为笔友！',
      '你好呀！✨\n\n今晚的星星很美。你有没有抬头看过夜空，想着世界某处是否有人也在看同样的星星？\n\n愿你一切都好。',
    ],
    '🇮🇹': [
      'Ciao da Roma! 🌍\n\nHo trovato questa app oggi e volevo mandare una lettera a qualcuno dall\'altra parte del mondo. Spero che questo piccolo messaggio ti renda la giornata più bella!\n\nRaccontami della tua città — qual è il tuo posto preferito?',
      'Salve! 🍝\n\nSono seduto in un caffè vicino al Colosseo e penso a quanto sia bello poter scrivere a uno sconosciuto dall\'altra parte del mondo.\n\nCome stai oggi?',
      'Ehi! 😊\n\nHo mandato questa lettera nel mondo senza sapere chi la riceverà. È emozionante, no?\n\nSe potessi viaggiare ovunque domani, dove andresti?',
    ],
    '🇦🇺': [
      'G\'day! 🌍\n\nWriting from Sydney! Found this app and reckoned it\'d be bonzer to connect with someone across the globe.\n\nWhat\'s your city like? I\'d love to hear about it!',
      'Hey mate! 🌅\n\nJust watched the sunset over the harbour and thought — someone across the world is watching the sunrise right now. Maybe that\'s you!\n\nHow was your morning?',
      'Hi! 🏄\n\nI went surfing today and it got me thinking about how the ocean connects all of us. This letter is like a message in a bottle.\n\nHope it reached someone awesome — and I reckon it has!',
    ],
    '🇮🇳': [
      'नमस्ते! 🌍\n\nमैं नई दिल्ली से यह पत्र लिख रहा/रही हूँ। दुनिया भर में पत्र भेज सकना कितना अद्भुत है!\n\nअपने शहर के बारे में बताइए — आपकी पसंदीदा जगह कौन सी है?',
      'हेलो! 🌸\n\nमैंने हमेशा दुनिया घूमने का सपना देखा है। आपका देश बहुत अद्भुत लगता है।\n\nक्या आप पेन पाल बनना चाहेंगे?',
      'हाय! ✨\n\nआज रात तारे बहुत सुंदर हैं। क्या आप भी कभी आसमान देखकर सोचते हैं कि कोई और भी वही तारे देख रहा है?\n\nउम्मीद है आप ठीक हैं!',
    ],
    '🇸🇪': [
      'Hej! 🌍\n\nJag skriver till dig från Stockholm. Det är fantastiskt att kunna skicka brev runt hela världen.\n\nBerätta om din stad — vad är din favoritplats?',
      'Tjena! 🌸\n\nJag har alltid drömt om att resa jorden runt. Olika kulturer, mat och landskap... allt verkar underbart.\n\nVill du bli brevvänner?',
      'Hallå! ✨\n\nStjärnorna är vackra ikväll. Undrar du ibland om någon på andra sidan jorden tittar på samma stjärnor?\n\nHoppas allt är bra med dig!',
    ],
    '🇹🇷': [
      'Merhaba! 🌍\n\nİstanbul\'dan sana bu mektubu yazıyorum. Dünyanın öbür ucuna mektup gönderebilmek ne güzel!\n\nŞehrini anlat bana — en sevdiğin yer neresi?',
      'Selam! 🌸\n\nHep farklı ülkeleri keşfetmeyi hayal ettim. Yemekleri, kültürü, doğası... her şey harika görünüyor.\n\nMektup arkadaşı olmak ister misin?',
      'Hey! ✨\n\nBu gece yıldızlar çok güzel. Sen de gökyüzüne bakıp dünyanın başka bir yerinde birinin aynı yıldızlara baktığını merak eder misin?\n\nUmarım iyisindir!',
    ],
    '🇨🇦': [
      'Hello from Toronto! 🌍\n\nI found this app today and wanted to send a letter to someone far away. I hope this little message brightens your day!\n\nTell me about your city — what\'s your favourite place to visit?',
      'Bonjour ! 🍁\n\nLes érables ici sont magnifiques en automne. J\'aimerais savoir à quoi ressemble l\'automne chez toi.\n\nQuelle est ta saison préférée ?',
      'Hey! 😊\n\nI just sent this letter into the world, not knowing who would receive it. That\'s pretty exciting, right?\n\nIf you could travel anywhere tomorrow, where would you go?',
    ],
    '🇦🇷': [
      '¡Hola desde Buenos Aires! 🌍\n\nEncontré esta app hoy y quise enviar una carta a alguien del otro lado del mundo. ¡Espero que este mensaje te alegre el día!\n\nContame de tu ciudad — ¿cuál es tu lugar favorito?',
      '¡Che! 🌸\n\nSiempre soñé con conocer nuevas culturas. La comida, la música, los paisajes... todo parece increíble.\n\n¿Qué es algo de tu país que solo los locales conocen?',
      '¡Buenas! 😊\n\nMandé esta carta sin saber quién la iba a recibir. Eso es lo emocionante, ¿no?\n\nSi pudieras viajar a cualquier lugar mañana, ¿a dónde irías?',
    ],
    '🇹🇭': [
      'สวัสดี! 🌍\n\nฉันเขียนจดหมายนี้จากกรุงเทพฯ สุดยอดมากที่เราส่งจดหมายข้ามโลกได้!\n\nเล่าให้ฟังหน่อยสิว่าเมืองคุณเป็นยังไง ที่ไหนที่คุณชอบไปมากที่สุด?',
      'หวัดดี! 🌸\n\nฉันฝันอยากเดินทางไปทั่วโลก อาหาร วัฒนธรรม ธรรมชาติ... ดูวิเศษไปหมด\n\nอยากเป็นเพื่อนทางจดหมายกันไหม?',
      'ไง! ✨\n\nคืนนี้ดาวสวยมาก คุณเคยมองท้องฟ้าแล้วสงสัยไหมว่ามีใครอีกฝั่งโลกกำลังมองดาวดวงเดียวกันอยู?\n\nหวังว่าคุณสบายดีนะ!',
    ],
    '🇷🇺': [
      'Привет! 🌍\n\nПишу тебе из Москвы. Удивительно, что можно отправлять письма через весь мир!\n\nРасскажи мне о своём городе — какое твоё любимое место?',
      'Здравствуй! 🌸\n\nЯ всегда мечтал(а) путешествовать по миру. Разные культуры, еда, природа... всё кажется таким замечательным.\n\nДавай станем друзьями по переписке?',
      'Привет! ✨\n\nСегодня ночью звёзды невероятно красивые. Ты когда-нибудь смотришь на небо и думаешь, кто ещё на другом конце мира смотрит на те же звёзды?\n\nНадеюсь, у тебя всё хорошо!',
    ],
    '🇳🇿': [
      'Kia ora! 🌍\n\nWriting from Auckland! Found this app and thought it would be awesome to connect with someone across the globe.\n\nWhat\'s your city like? I\'d love to hear about it!',
      'Hey! 🌅\n\nJust came back from a hike and the views were incredible. New Zealand is like a dream.\n\nWhat\'s the most beautiful spot in your area?',
      'Hi! 😊\n\nSent this letter out into the world not knowing who\'d get it. That\'s the magic of it, right?\n\nIf you could travel anywhere tomorrow, where would you go?',
    ],
  };

  void _generateDailyAiLetters() {
    final today = _dateKey(DateTime.now());
    if (_lastAiLetterDateKey == today) return; // 오늘 이미 생성됨
    if (_currentUser.id.isEmpty) return; // 로그인 전이면 스킵

    _lastAiLetterDateKey = today;
    final rng = Random();
    final now = DateTime.now();

    // 유저 나라 결정 (미설정 시 대한민국 기본)
    final userCountry = _currentUser.country.isNotEmpty ? _currentUser.country : '대한민국';
    final userFlag = _currentUser.countryFlag.isNotEmpty ? _currentUser.countryFlag : '🇰🇷';

    // 랜덤 3개국 선택 (중복 없이, 유저 나라 제외)
    final availableSenders = _aiSenders
        .where((s) => s['country'] != userCountry)
        .toList()
      ..shuffle(rng);
    final selectedSenders = availableSenders.take(3).toList();

    for (int i = 0; i < selectedSenders.length; i++) {
      final sender = selectedSenders[i];
      final senderFlag = sender['flag'] as String;
      final senderName = sender['name'] as String;
      final senderCountry = sender['country'] as String;
      final senderLat = sender['lat'] as double;
      final senderLng = sender['lng'] as double;
      final senderCity = sender['city'] as String;

      // 발송 나라 고유 언어 메시지 랜덤 선택
      final msgs = _aiMessagesByFlag[senderFlag] ?? _aiMessagesByFlag['🇬🇧']!;
      final message = msgs[rng.nextInt(msgs.length)];

      // 유저 나라 내 랜덤 도시 좌표
      final destCity = CountryCities.randomCityWithOffset(userCountry);
      final destLat = destCity != null ? (destCity['lat'] as num).toDouble() : _currentUser.latitude;
      final destLng = destCity != null ? (destCity['lng'] as num).toDouble() : _currentUser.longitude;

      // 배송 시간: 1~6시간 랜덤 (거리별 현실감)
      final deliveryMin = 60 + rng.nextInt(300);
      // 발송 시간을 오늘 내 랜덤 시점으로 분산
      final offsetMin = rng.nextInt(120 * (i + 1));
      final sentAt = now.subtract(Duration(minutes: offsetMin));

      final id = 'daily_ai_${today}_$i';
      // 이미 존재하면 스킵
      if (_worldLetters.any((l) => l.id == id) || _inbox.any((l) => l.id == id)) {
        continue;
      }

      final fromCity = LatLng(senderLat, senderLng);
      final toCity = LatLng(destLat, destLng);

      final segments = LogisticsHubs.buildRoute(
        fromCountry: senderCountry,
        fromCity: fromCity,
        toCountry: userCountry,
        toCity: toCity,
        fromCityName: senderCity,
        preferAir: true,
      );
      final segMin = segments.fold<int>(0, (s, seg) => s + seg.estimatedMinutes);
      final totalMin = max(segMin, deliveryMin);
      _rebalanceSegmentEstimatedMinutes(segments, totalMin);

      final letter = Letter(
        id: id,
        senderId: 'ai_${senderName.toLowerCase()}_${senderCountry.hashCode}',
        senderName: senderName,
        senderCountry: senderCountry,
        senderCountryFlag: senderFlag,
        content: message,
        originLocation: fromCity,
        destinationLocation: toCity,
        destinationCountry: userCountry,
        destinationCountryFlag: userFlag,
        destinationCity: null,
        destinationDisplayAddress: null,
        segments: segments,
        currentSegmentIndex: 0,
        status: DeliveryStatus.inTransit,
        sentAt: sentAt,
        arrivalTime: sentAt.add(Duration(minutes: totalMin)),
        estimatedTotalMinutes: totalMin,
        paperStyle: rng.nextInt(5),
        fontStyle: rng.nextInt(3),
        isAnonymous: false,
      );

      _worldLetters.add(letter);
    }
    _saveToPrefs();
    _rescheduleArrivalCountdown();
    notifyListeners();
  }

  bool _syncLetterProgressWithClock(Letter letter, DateTime now) {
    if (letter.segments.isEmpty) {
      // 세그먼트 없는 편지: estimatedTotalMinutes 기반으로 arrivalTime 설정
      if (letter.arrivalTime == null && letter.estimatedTotalMinutes > 0) {
        letter.arrivalTime = letter.sentAt.add(
          Duration(minutes: letter.estimatedTotalMinutes.clamp(1, 999999)),
        );
        return true;
      }
      return false;
    }

    if (letter.arrivalTime == null) {
      letter.arrivalTime = letter.sentAt.add(
        Duration(minutes: letter.estimatedTotalMinutes.clamp(1, 999999)),
      );
    }

    final eta = letter.arrivalTime!;
    final totalMs = eta.difference(letter.sentAt).inMilliseconds;
    final totalMin = letter.segments.fold<int>(
      0,
      (s, seg) => s + (seg.estimatedMinutes <= 0 ? 1 : seg.estimatedMinutes),
    );
    if (totalMs <= 0 || totalMin <= 0) return false;

    final elapsedMsRaw =
        (now.difference(letter.sentAt).inMilliseconds * _adminSpeedMultiplier)
            .round();
    final elapsedMs = elapsedMsRaw.clamp(0, totalMs);
    final ratio = elapsedMs / totalMs;
    final targetMin = ratio * totalMin;

    bool changed = false;
    var accMin = 0.0;
    var newSegmentIndex = 0;

    for (int i = 0; i < letter.segments.length; i++) {
      final seg = letter.segments[i];
      final segMin = (seg.estimatedMinutes <= 0 ? 1 : seg.estimatedMinutes)
          .toDouble();
      final segStart = accMin;
      final segEnd = accMin + segMin;
      double nextProgress;

      if (targetMin <= segStart) {
        nextProgress = 0.0;
      } else if (targetMin >= segEnd) {
        nextProgress = 1.0;
        if (i < letter.segments.length - 1) {
          newSegmentIndex = i + 1;
        } else {
          newSegmentIndex = i;
        }
      } else {
        nextProgress = (targetMin - segStart) / segMin;
        newSegmentIndex = i;
      }

      nextProgress = nextProgress.clamp(0.0, 1.0);
      if ((seg.progress - nextProgress).abs() > 1e-6) {
        seg.progress = nextProgress;
        changed = true;
      }
      accMin = segEnd;
    }

    if (letter.currentSegmentIndex != newSegmentIndex) {
      letter.currentSegmentIndex = newSegmentIndex;
      changed = true;
    }
    return changed;
  }

  // ── 근처 도착 알림 트리거 ────────────────────────────────────────────────────

  Future<void> _triggerNearbyNotification(Letter letter) async {
    // 편지 도착 피드백 (3단 light — 부드러운 우편함 노크)
    FeedbackService.onLetterArrive();
    final prefs = await SharedPreferences.getInstance();
    final notifyEnabled = prefs.getBool('notify_nearby') ?? true;
    if (!notifyEnabled) return;

    // 쿨다운 중이면 "편지가 근처에 있지만 쿨다운 중" 알림
    final remaining = nearbyPickupRemainingCooldown;
    if (remaining != null) {
      final mins = remaining.inMinutes;
      final secs = remaining.inSeconds % 60;
      final timeStr = mins > 0
          ? _l10n.stateMinSec(mins, secs)
          : _l10n.stateSec(secs);
      NotificationService.showCooldownNotification(
        title: _l10n.stateCooldownNearbyTitle,
        body: _l10n.stateCooldownNearbyBody(
          letter.senderCountryFlag,
          letter.senderCountry,
          timeStr,
        ),
      );
      return;
    }

    NotificationService.showNearbyLetterNotification(
      title: _l10n.stateNearbyNotificationTitle,
      body:
          _l10n.stateNearbyNotificationBody(letter.senderCountryFlag, letter.senderCountry),
      langCode: _currentUser.languageCode,
    );
  }

  // 총 예상 시간과 구간 합계 시간을 일치시켜, ETA/진행률/실제 도착 시점이 어긋나지 않게 맞춘다.
  void _rebalanceSegmentEstimatedMinutes(
    List<RouteSegment> segments,
    int totalMin,
  ) {
    if (segments.isEmpty) return;
    if (totalMin <= 0) return;

    final count = segments.length;
    if (count == 1) {
      segments.first.estimatedMinutes = totalMin;
      return;
    }

    final original = segments
        .map((s) => s.estimatedMinutes <= 0 ? 1 : s.estimatedMinutes)
        .toList();
    final originalTotal = original.fold<int>(0, (sum, v) => sum + v);

    if (originalTotal == totalMin) return;

    final ratio = totalMin / originalTotal;
    for (var i = 0; i < segments.length; i++) {
      final scaled = (original[i] * ratio).round();
      segments[i].estimatedMinutes = scaled < 1 ? 1 : scaled;
    }

    var adjustedTotal = segments.fold<int>(
      0,
      (sum, s) => sum + s.estimatedMinutes,
    );
    var diff = totalMin - adjustedTotal;
    var idx = 0;
    while (diff != 0 && idx < 10000) {
      final target = segments[idx % count];
      if (diff > 0) {
        target.estimatedMinutes += 1;
        diff -= 1;
      } else if (target.estimatedMinutes > 1) {
        target.estimatedMinutes -= 1;
        diff += 1;
      }
      idx++;
    }
  }

  // ── 국내(같은 나라) 배송 시간 추정: 도로 이동 기준 ─────────────────────────
  int _estimateDomesticDeliveryMinutes(LatLng from, LatLng to) {
    final distanceKm = from.distanceTo(to) / 1000;
    if (distanceKm <= 0.5) return 8;

    double avgSpeedKmh;
    int handlingMin;
    if (distanceKm <= 20) {
      avgSpeedKmh = 35;
      handlingMin = 8;
    } else if (distanceKm <= 80) {
      avgSpeedKmh = 50;
      handlingMin = 15;
    } else if (distanceKm <= 250) {
      avgSpeedKmh = 65;
      handlingMin = 25;
    } else {
      avgSpeedKmh = 75;
      handlingMin = 35;
    }

    final driveMin = (distanceKm / avgSpeedKmh * 60).round();
    return (driveMin + handlingMin).clamp(10, 720);
  }

  // ── 편지 발송 ─────────────────────────────────────────────────────────────
  Future<bool> sendLetter({
    required String content,
    required String destinationCountry,
    required String destinationFlag,
    required double destLat,
    required double destLng,
    String? destCityName, // compose 화면에서 이미 선택된 도시명 (재랜덤 방지)
    String? deliveryEmoji, // 유저가 고른 배송 이모티콘
    String? socialLink,
    bool useShip = false,
    int paperStyle = 0,
    int fontStyle = 0,
    String? imageUrl, // 첨부 이미지 경로 (프리미엄)
    bool isExpress = false, // 프리미엄/브랜드 특급 배송
    bool brandUniquePerUser = false, // 브랜드: 수신자당 1회 수신
    int? brandAutoExpireHours, // 브랜드: 자동 삭제 시간
    LetterCategory category = LetterCategory.general, // 브랜드만 coupon/voucher 선택 가능
    bool acceptsReplies = true, // 브랜드가 답장 받기 off로 보낼 수 있음
    String? redemptionInfo, // 브랜드: 쿠폰/교환권 사용 안내 (자유 텍스트)
    DateTime? redemptionExpiresAt, // Build 132: 브랜드 쿠폰/교환권 유효기간 (사용 가능 마지막 시각)
  }) async {
    if (!_canSendLetterByDailyLimit()) {
      return false;
    }
    if (isExpress && !_canUseExpressMode()) {
      return false;
    }
    // 이미지 편지 한도 체크
    if (imageUrl != null && !_canSendImageLetter()) {
      return false;
    }

    final id = 'sent_${DateTime.now().millisecondsSinceEpoch}';
    final fromCity = LatLng(_currentUser.latitude, _currentUser.longitude);

    // ── 실제 위치 기반 발신국 결정 ─────────────────────────────────────────
    // 사용자 프로필 country (회원가입 시 선택) 와 실제 GPS 위치가 다른 경우
    // (예: 한국 회원이 호주 여행 중) — 발신국은 실제 위치 기준이 맞다.
    // GeocodingService 의 country bounds 로 좌표 → 국가 매핑.
    final geoSvc = GeocodingService.instance;
    final detected = geoSvc.isInitialized
        ? geoSvc.findCountryByCoord(
            _currentUser.latitude,
            _currentUser.longitude,
          )
        : null;
    final actualSenderCountry = detected?['name'] ?? _currentUser.country;
    final actualSenderFlag = detected?['flag'] ?? _currentUser.countryFlag;

    double finalLat;
    double finalLng;
    String? toCityName;

    if (destCityName != null && destCityName.isNotEmpty) {
      // compose 화면에서 이미 선택된 도시 그대로 사용 → "서울→서울" 방지
      finalLat = destLat;
      finalLng = destLng;
      toCityName = destCityName;
      _usedDestinations[destinationCountry] ??= {};
      _usedDestinations[destinationCountry]!.add(
        CountryCities.cityKey(destinationCountry, destCityName),
      );
    } else {
      // 도시 미선택일 경우: 실제 주소 캐시 → cities.json → 육지 랜덤 좌표 순
      _usedDestinations[destinationCountry] ??= {};

      // 1차: GeocodingService 캐시에서 실제 주소 사용
      final geo = GeocodingService.instance;
      final cachedAddr = geo.isInitialized
          ? geo.getCachedAddress(destinationCountry)
          : null;

      if (cachedAddr != null) {
        finalLat = (cachedAddr['lat'] as num).toDouble();
        finalLng = (cachedAddr['lng'] as num).toDouble();
        toCityName = cachedAddr['city'] as String?;
        final cityName = toCityName;
        if (cityName != null && cityName.isNotEmpty) {
          _usedDestinations[destinationCountry]!.add(
            CountryCities.cityKey(destinationCountry, cityName),
          );
        }
        // 캐시 소진 시 백그라운드 보충
        if (geo.cachedCountOf(destinationCountry) < 5) {
          unawaited(geo.prefetch(destinationCountry, count: 10));
        }
      } else {
        // 2차: cities.json 기반 랜덤 도시 (기존 56개국)
        final cityData = CountryCities.randomCityWithOffset(
          destinationCountry,
          usedCityKeys: _usedDestinations[destinationCountry],
          languageCode: _currentUser.languageCode,
        );
        if (cityData != null) {
          finalLat = (cityData['lat'] as num).toDouble();
          finalLng = (cityData['lng'] as num).toDouble();
          toCityName = cityData['name'] as String?;
          _usedDestinations[destinationCountry]!.add(
            CountryCities.cityKey(destinationCountry, cityData['name'] as String),
          );
        } else if (geo.isInitialized) {
          // 3차: GeocodingService 경계 내 랜덤 좌표 (cities.json에 없는 나라)
          final coord = geo.randomCoordinate(destinationCountry);
          if (coord != null) {
            finalLat = coord['lat']!;
            finalLng = coord['lng']!;
          } else {
            final landAddr = LandAddressGenerator.generate(
              excludeCountry: _currentUser.country,
            );
            finalLat = (landAddr['lat'] as num).toDouble();
            finalLng = (landAddr['lng'] as num).toDouble();
          }
        } else {
          // 4차: 최종 폴백 — LandAddressGenerator
          final landAddr = LandAddressGenerator.generate(
            excludeCountry: _currentUser.country,
          );
          finalLat = (landAddr['lat'] as num).toDouble();
          finalLng = (landAddr['lng'] as num).toDouble();
        }
      }
    }
    final toCity = LatLng(finalLat, finalLng);

    // Build 210: 라우팅 fromCountry 강건화. 이전엔 GeocodingService 가
    // 미초기화이거나 좌표가 box 매칭 안 되면 프로필 country 로 폴백 → 한국
    // 회원이 호주에서 호주로 보낼 때 'KR→AU' 로 잘못 인식돼 공항 경유 항공
    // 루트가 짜였다. 두 가지 방어 추가:
    //   1) fromCity 와 toCity 가 충분히 가까우면(< 300km) 무조건 domestic 으로
    //      간주. 두 좌표가 한 도시 권역 내라면 국가 식별 결과와 무관하게
    //      트럭 단일 구간이 자연스럽다.
    //   2) GeocodingService 가 detect 실패해도 destinationCountry box 안에
    //      fromCity 가 들어가는지 한 번 더 체크. 들어가면 domestic 으로 강제.
    String routingFromCountry = actualSenderCountry;
    final fromToDistanceM = fromCity.distanceTo(toCity);
    if (fromToDistanceM < 300000) {
      // < 300km → 같은 나라로 간주 (대륙 어느 쪽이든)
      routingFromCountry = destinationCountry;
    } else if (geoSvc.isInitialized &&
        actualSenderCountry != destinationCountry) {
      // detect 결과가 dest 와 다르더라도 fromCity 좌표가 dest 박스 안이면
      // domestic 으로 보정.
      final destBoxCheck = geoSvc.findCountryByCoord(
        fromCity.latitude,
        fromCity.longitude,
      );
      if (destBoxCheck?['name'] == destinationCountry) {
        routingFromCountry = destinationCountry;
      }
    }

    final isDomestic = routingFromCountry == destinationCountry;
    final segments = LogisticsHubs.buildRoute(
      fromCountry: routingFromCountry,
      fromCity: fromCity,
      toCountry: destinationCountry,
      toCity: toCity,
      fromCityName: _l10n.stateMyLocation,
      preferAir: !useShip,
      toCityName: toCityName,
    );

    final segMin = segments.fold<int>(0, (s, seg) => s + seg.estimatedMinutes);
    final int totalMin;
    if (isExpress) {
      totalMin = _currentUser.isBrand ? 5 : 20;
    } else if (isDomestic) {
      final domesticMin = _estimateDomesticDeliveryMinutes(fromCity, toCity);
      totalMin = max(segMin, domesticMin);
    } else {
      // 국제 배송은 공항 허브 기반 계산과 세그먼트 계산 중 더 큰 값 사용
      final startHubInfo = LogisticsHubs.findNearestHub(fromCity);
      final endHubInfo = LogisticsHubs.findNearestHub(toCity);
      final deliveryMin = LogisticsHubs.calculateDeliveryTime(
        from: fromCity,
        startHub: startHubInfo.coords,
        endHub: endHubInfo.coords,
        destination: toCity,
      );
      totalMin = max(segMin, deliveryMin);
    }
    _rebalanceSegmentEstimatedMinutes(segments, totalMin);

    final now = DateTime.now();
    final letter = Letter(
      id: id,
      senderId: _currentUser.id,
      senderName: _currentUser.username,
      // 실제 위치 기반 — 한국 회원이 호주 여행 중 발송 시 senderCountry='호주'.
      // 좌표 매칭 실패(바다 등) 시 프로필 country 폴백.
      senderCountry: actualSenderCountry,
      senderCountryFlag: actualSenderFlag,
      content: content,
      originLocation: fromCity,
      destinationLocation: toCity,
      destinationCountry: destinationCountry,
      destinationCountryFlag: destinationFlag,
      destinationCity: toCityName,
      destinationDisplayAddress: null,
      segments: segments,
      currentSegmentIndex: 0,
      status: DeliveryStatus.inTransit,
      sentAt: now,
      arrivalTime: now.add(Duration(minutes: totalMin)),
      socialLink: socialLink,
      estimatedTotalMinutes: totalMin,
      paperStyle: paperStyle,
      fontStyle: fontStyle,
      deliveryEmoji: deliveryEmoji,
      imageUrl: imageUrl,
      letterType: isExpress
          ? (_currentUser.isBrand
                ? LetterType.brandExpress
                : LetterType.express)
          : LetterType.normal,
      senderIsBrand: _currentUser.isBrand,
      senderTier: _currentUser.isBrand
          ? LetterSenderTier.brand
          : _currentUser.isPremium
          ? LetterSenderTier.premium
          : LetterSenderTier.free,
      brandUniquePerUser: _currentUser.isBrand && brandUniquePerUser,
      expiresAt: (_currentUser.isBrand && brandAutoExpireHours != null)
          ? now.add(Duration(minutes: totalMin) + Duration(hours: brandAutoExpireHours))
          : null,
      // coupon/voucher 카테고리는 브랜드만 선택할 수 있도록 서버 사이드 가드
      // 일반·프리미엄 유저가 어떤 방식으로 category 를 전달해도 general 로 강제.
      category: _currentUser.isBrand ? category : LetterCategory.general,
      // 답장 수락은 브랜드만 off 가능 — Free/Premium 은 항상 true 로 강제.
      acceptsReplies: _currentUser.isBrand ? acceptsReplies : true,
      // 쿠폰/교환권 사용 안내도 브랜드만 기록됨. 일반 유저가 넘겨도 무시.
      redemptionInfo: _currentUser.isBrand ? redemptionInfo : null,
      // Build 132: 쿠폰/교환권 유효기간 — coupon/voucher 카테고리일 때만 저장.
      redemptionExpiresAt: (_currentUser.isBrand &&
              category != LetterCategory.general)
          ? redemptionExpiresAt
          : null,
    );

    _worldLetters.add(letter);
    _sent.add(letter);
    _consumeDailyQuota();
    if (imageUrl != null) _consumeImageQuota();
    _consumeExpressQuotaIfNeeded(isExpress);
    _currentUser.activityScore.sentCount++;
    _sentSinceLastUnlock++;
    // 주간 챌린지 진행도 갱신 (중복 국가는 자동으로 무시됨)
    _recordWeeklyChallengeSend(letter.destinationCountry);
    // 발송 거리 누적 — XP 공식의 "보낸 편지 거리" 원천
    _sumSentKm += letter.originLocation.distanceTo(letter.destinationLocation) /
        1000.0;
    // 레벨업 감지 (발송 수 + 거리 증가로 레벨 바뀔 수 있음)
    _detectLevelUp();
    notifyListeners();
    _saveToPrefs();
    // Firestore에 편지 저장 (다른 유저가 수신할 수 있도록)
    unawaited(_saveLetterToFirestore(letter));
    // 주소 조회: 편지 저장 후 비동기 업데이트 (앱 종료 시에도 편지 유지)
    unawaited(
      GeocodingService.getDisplayAddress(
            finalLat,
            finalLng,
            languageCode: _currentUser.languageCode,
          )
          .then((addr) {
            if (addr != null) {
              letter.destinationDisplayAddress = addr;
              _saveToPrefs();
              notifyListeners();
            }
          })
          .catchError((Object _) {
            // 주소 조회 실패는 무시 (표시용 데이터, 발송에 영향 없음)
          }),
    );
    return true;
  }

  // ── 브랜드 대량 발송 ──────────────────────────────────────────────────────
  /// 브랜드 계정 전용: 동일 내용을 복수 나라에 지정 횟수만큼 발송
  /// [targets] : [{'country':..,'flag':..,'lat':..,'lng':..}] 목록
  ///             빈 목록이면 198개국 중 랜덤 선택하여 발송
  /// [sendCount]: 나라당 발송 횟수 (랜덤 모드에서는 총 발송 횟수)
  /// [randomMode]: true이면 targets 무시, 매 편지마다 랜덤 국가 선택
  /// returns: 실제 발송된 편지 수 (한도 초과 시 부분 발송)
  Future<int> sendBulkLetter({
    required String content,
    required List<Map<String, dynamic>> targets,
    required int sendCount,
    bool randomMode = false,
    String? socialLink,
    String? imageUrl,
    int paperStyle = 0,
    int fontStyle = 0,
    bool brandUniquePerUser = false,
    int? brandAutoExpireHours,
    LetterCategory category = LetterCategory.general,
    bool acceptsReplies = true,
    String? redemptionInfo,
    DateTime? redemptionExpiresAt,
  }) async {
    if (!_currentUser.isBrand) return 0;
    int sent = 0;

    if (randomMode) {
      // 랜덤 모드: 매 편지마다 198개국 중 랜덤 국가 선택
      final totalToSend = sendCount;
      for (int i = 0; i < totalToSend; i++) {
        if (!_canSendLetterByDailyLimit()) break;
        if (imageUrl != null && !_canSendImageLetter()) break;
        final dest = randomDestination(excludeCountry: _currentUser.country);
        final ok = await sendLetter(
          content: content,
          destinationCountry: dest['name']!,
          destinationFlag: dest['flag']!,
          destLat: double.parse(dest['lat']!),
          destLng: double.parse(dest['lng']!),
          socialLink: socialLink,
          imageUrl: imageUrl,
          paperStyle: paperStyle,
          fontStyle: fontStyle,
          brandUniquePerUser: brandUniquePerUser,
          brandAutoExpireHours: brandAutoExpireHours,
          category: category,
          acceptsReplies: acceptsReplies,
          redemptionInfo: redemptionInfo,
          redemptionExpiresAt: redemptionExpiresAt,
        );
        if (ok) sent++;
      }
    } else {
      // 기존: 선택된 나라에 나라당 sendCount만큼 발송
      for (final target in targets) {
        for (int i = 0; i < sendCount; i++) {
          if (!_canSendLetterByDailyLimit()) break;
          if (imageUrl != null && !_canSendImageLetter()) break;
          final ok = await sendLetter(
            content: content,
            destinationCountry: target['country'] as String,
            destinationFlag: target['flag'] as String,
            destLat: (target['lat'] as num).toDouble(),
            destLng: (target['lng'] as num).toDouble(),
            socialLink: socialLink,
            imageUrl: imageUrl,
            paperStyle: paperStyle,
            fontStyle: fontStyle,
            brandUniquePerUser: brandUniquePerUser,
            brandAutoExpireHours: brandAutoExpireHours,
            category: category,
            acceptsReplies: acceptsReplies,
            redemptionInfo: redemptionInfo,
            redemptionExpiresAt: redemptionExpiresAt,
          );
          if (ok) sent++;
        }
      }
    }
    return sent;
  }

  // ── 브랜드 특송 (즉시 다중 주소 발송) ─────────────────────────────────────
  /// 브랜드 계정 전용: 선택한 나라의 랜덤 주소 [count]개에 즉시(5분) 발송
  /// returns: 실제 발송된 편지 수
  Future<int> sendBrandExpressBlast({
    required String content,
    required String destinationCountry,
    required String destinationFlag,
    int count = 5,
    String? deliveryEmoji,
    String? socialLink,
    int paperStyle = 0,
    int fontStyle = 0,
    String? imageUrl,
    bool brandUniquePerUser = false,
    int? brandAutoExpireHours,
    LetterCategory category = LetterCategory.general,
    bool acceptsReplies = true,
    String? redemptionInfo,
    DateTime? redemptionExpiresAt,
    double? preciseLat,
    double? preciseLng,
  }) async {
    if (!_currentUser.isBrand) return 0;

    const expressTotalMin = 5; // 특송: 5분 즉시 배송
    final now = DateTime.now();
    final fromCity = LatLng(_currentUser.latitude, _currentUser.longitude);
    // 실제 위치 기반 발신국 (호주 여행 중인 한국 회원도 호주 발송으로 표시)
    final geoSvc = GeocodingService.instance;
    final detected = geoSvc.isInitialized
        ? geoSvc.findCountryByCoord(
            _currentUser.latitude,
            _currentUser.longitude,
          )
        : null;
    final actualSenderCountry = detected?['name'] ?? _currentUser.country;
    final actualSenderFlag = detected?['flag'] ?? _currentUser.countryFlag;
    final usedCityKeys = <String>{};
    int sent = 0;

    final usePrecise = preciseLat != null && preciseLng != null;
    for (int i = 0; i < count; i++) {
      if (!_canSendLetterByDailyLimit()) break;

      String cityName;
      double cityLat;
      double cityLng;
      if (usePrecise) {
        // 정확한 위치 모드: 모든 letter 가 동일 좌표 단일점 발송 (산포 X)
        cityName = '';
        cityLat = preciseLat;
        cityLng = preciseLng;
      } else {
        var cityData = CountryCities.randomCityWithOffset(
          destinationCountry,
          usedCityKeys: usedCityKeys,
          languageCode: _currentUser.languageCode,
        );
        if (cityData == null) {
          if (usedCityKeys.isEmpty) break; // 해당 국가 도시 데이터 없음
          usedCityKeys.clear(); // 모든 도시 소진 → 중복 허용으로 재시도
          cityData = CountryCities.randomCityWithOffset(
            destinationCountry,
            usedCityKeys: usedCityKeys,
            languageCode: _currentUser.languageCode,
          );
          if (cityData == null) break;
        }

        cityName = cityData['name'] as String? ?? '';
        usedCityKeys.add(CountryCities.cityKey(destinationCountry, cityName));

        cityLat = (cityData['lat'] as num).toDouble();
        cityLng = (cityData['lng'] as num).toDouble();
      }
      final toCity = LatLng(cityLat, cityLng);

      final segments = LogisticsHubs.buildRoute(
        fromCountry: actualSenderCountry,
        fromCity: fromCity,
        toCountry: destinationCountry,
        toCity: toCity,
        fromCityName: _l10n.stateMyLocation,
        preferAir: true,
        toCityName: cityName,
      );
      _rebalanceSegmentEstimatedMinutes(segments, expressTotalMin);

      final id = 'bx_${now.millisecondsSinceEpoch}_$i';
      final letter = Letter(
        id: id,
        senderId: _currentUser.id,
        senderName: _currentUser.username,
        senderCountry: actualSenderCountry,
        senderCountryFlag: actualSenderFlag,
        content: content,
        originLocation: fromCity,
        destinationLocation: toCity,
        destinationCountry: destinationCountry,
        destinationCountryFlag: destinationFlag,
        destinationCity: cityName,
        destinationDisplayAddress: null,
        segments: segments,
        currentSegmentIndex: 0,
        status: DeliveryStatus.inTransit,
        sentAt: now,
        arrivalTime: now.add(const Duration(minutes: expressTotalMin)),
        estimatedTotalMinutes: expressTotalMin,
        letterType: LetterType.brandExpress,
        deliveryEmoji: deliveryEmoji,
        socialLink: socialLink,
        paperStyle: paperStyle,
        fontStyle: fontStyle,
        imageUrl: imageUrl,
        senderIsBrand: true,
        senderTier: LetterSenderTier.brand,
        isAnonymous: false,
        brandUniquePerUser: brandUniquePerUser,
        expiresAt: brandAutoExpireHours != null
            ? now.add(Duration(minutes: expressTotalMin) + Duration(hours: brandAutoExpireHours))
            : null,
        category: category,
        acceptsReplies: acceptsReplies,
        redemptionInfo: redemptionInfo,
        redemptionExpiresAt: category != LetterCategory.general
            ? redemptionExpiresAt
            : null,
      );

      _worldLetters.add(letter);
      _sent.add(letter);
      _consumeDailyQuota();
      if (imageUrl != null) _consumeImageQuota();
      _currentUser.activityScore.sentCount++;
      _sentSinceLastUnlock++;
      sent++;
      // 주소 조회: 저장 후 비동기 업데이트 (앱 종료 시에도 편지 유지)
      unawaited(
        GeocodingService.getDisplayAddress(
              cityLat,
              cityLng,
              languageCode: _currentUser.languageCode,
            )
            .then((addr) {
              if (addr != null) {
                letter.destinationDisplayAddress = addr;
              }
            })
            .catchError((Object _) {}),
      );
    }

    if (sent > 0) {
      notifyListeners();
      _saveToPrefs();
    }
    return sent;
  }

  // ── 편지 습득 ─────────────────────────────────────────────────────────────
  /// 반환값: null = 성공, 非non-null = 실패 사유 메시지
  /// [distanceCheck] false로 설정하면 거리 검증 없이 습득 (테스트/관리자용)
  String? pickUpLetter(String letterId, {bool distanceCheck = true}) {
    // 브랜드 픽업 차단은 포지셔닝 변경으로 해제 — 모든 등급이 줍기 가능.
    // (Free 200m / Premium 1km / Brand 1km — 브랜드는 발송 중심이지만
    //  본인도 다른 발신자의 쿠폰/이벤트 편지를 주울 수 있음.)
    //
    // ① 쿨다운 체크 (무료: 1시간, 프리미엄/브랜드: 10분)
    final remaining = nearbyPickupRemainingCooldown;
    if (remaining != null) {
      final mins = remaining.inMinutes;
      final secs = remaining.inSeconds % 60;
      final timeStr = mins > 0
          ? _l10n.stateMinSec(mins, secs)
          : _l10n.stateSec(secs);
      final tier = _currentUser.isPremium
          ? _l10n.stateTierPremium10min
          : _l10n.stateTierFree1hour;
      return _l10n.statePickupCooldown(timeStr, tier);
    }

    // ② 이미 내가 읽은 편지인지 확인
    if (_myPickedUpLetterIds.contains(letterId)) {
      return _l10n.stateAlreadyRead;
    }

    // ③ 편지 존재 여부
    final idx = _worldLetters.indexWhere((l) => l.id == letterId);
    if (idx == -1) return _l10n.stateAlreadyTaken;

    final letter = _worldLetters[idx];

    // ④ 최대 읽기 인원 초과 확인 (같은 지역 최대 3명)
    if (letter.readCount >= letter.maxReaders) {
      return _l10n.stateMaxReadersReached(letter.maxReaders);
    }

    // ⑤ 거리 재검증: 편지 목적지와 현재 유저 위치 간 Haversine 거리
    if (distanceCheck) {
      final dist = letter.destinationLocation.distanceTo(
        LatLng(_currentUser.latitude, _currentUser.longitude),
      );
      if (dist > pickupRadiusMeters) return _l10n.stateDistanceTooFar;
    }

    // ⑥ 수령 처리: readCount 증가 후 inbox에 복사본 추가
    letter.readCount++;
    _myPickedUpLetterIds.add(letterId);

    // 인박스용 독립 복사본 (status/arrivedAt 새로 설정)
    final inboxCopy = letter.clone()
      ..status = DeliveryStatus.delivered
      ..arrivedAt = DateTime.now();

    _inbox.add(inboxCopy);

    // 최대 읽기 인원 도달 시 지도에서 제거
    if (letter.readCount >= letter.maxReaders) {
      _worldLetters.removeAt(idx);
    }

    _currentUser.activityScore.receivedCount++;
    _lastNearbyPickupAt = DateTime.now(); // 쿨다운 시작

    // 픽업 모먼트 햅틱 — 포켓몬 고식 "편지 주움" 감각. Brand 발신 편지는
    // 한 단계 더 무거운 시퀀스로 "공식 발송인" 체감 차별화.
    FeedbackService.onLetterPickUp(isBrand: letter.senderIsBrand);

    // 픽업 거리 누적 — XP 공식의 "편지 간 거리" 원천. Brand 계정은 레벨
    // 시스템 밖이지만 필드 자체는 동일하게 축적해서 후일 Brand 전용 통계에
    // 재활용할 수 있도록 한다.
    final pickupKm = letter.originLocation.distanceTo(
      LatLng(_currentUser.latitude, _currentUser.longitude),
    ) /
        1000.0;
    _sumPickupKm += pickupKm;
    _detectLevelUp();

    // Build 134: 쿠폰/교환권 편지를 주웠다면 만료 24h 전 알림 예약.
    // general 카테고리·만료일 없음·이미 지남 = 스킵 (service 내부 guard).
    if (letter.category != LetterCategory.general &&
        letter.redemptionExpiresAt != null) {
      unawaited(
        NotificationService.scheduleCouponExpiryReminder(
          letterId: letter.id,
          expiresAt: letter.redemptionExpiresAt!,
          senderName: letter.senderName.isNotEmpty
              ? letter.senderName
              : letter.senderCountry,
          isVoucher: letter.category == LetterCategory.voucher,
          langCode: _currentUser.languageCode,
        ),
      );
    }

    NotificationService.showLetterArrivedNotification(
      senderCountry: letter.senderCountry,
      senderFlag: letter.senderCountryFlag,
      langCode: _currentUser.languageCode,
    );
    notifyListeners();
    _saveToPrefs();

    // ⑦ Firestore 클레임 등록 (Firebase 활성화 시, 선착순 기록)
    if (FirebaseConfig.kFirebaseEnabled) {
      _claimLetterOnFirestore(letter.id);
      // Build 138: 브랜드 편지 픽업 집계 — 브랜드 대시보드에서 impression
      // 숫자로 노출. 원자적 증감 (`:commit` fieldTransforms.increment).
      if (letter.senderIsBrand) {
        unawaited(
          FirestoreService.incrementField(
            path: 'letters/${letter.id}',
            field: 'pickupCount',
          ),
        );
      }
    }

    return null; // 성공
  }

  /// Firestore에 편지 클레임을 등록 (선착순 기록용, 비동기 fire-and-forget)
  Future<void> _claimLetterOnFirestore(String letterId) async {
    try {
      final url = Uri.parse(
        '${FirebaseConfig.firestoreBase}/claimedLetters/$letterId'
        '?currentDocument.exists=false',
      );
      await http
          .patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fields': {
                'claimedBy': {'stringValue': _currentUser.id},
                'claimedAt': {
                  'timestampValue': DateTime.now().toUtc().toIso8601String(),
                },
              },
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[pickUp] _claimLetterOnFirestore error: $e');
    }
  }

  // ── 편지 삭제 ─────────────────────────────────────────────────────────────
  void deleteFromInbox(String letterId) {
    final before = _inbox.length;
    _inbox.removeWhere((l) => l.id == letterId);
    if (_inbox.length < before) {
      notifyListeners();
      _saveToPrefs();
    }
  }

  void deleteFromSent(String letterId) {
    final before = _sent.length;
    _sent.removeWhere((l) => l.id == letterId);
    // 지도에서도 제거 (inTransit 상태인 경우)
    _worldLetters.removeWhere((l) => l.id == letterId);
    if (_sent.length < before) {
      notifyListeners();
      _saveToPrefs();
    }
  }

  // ── 편지 읽기 ─────────────────────────────────────────────────────────────
  void readLetter(String letterId) {
    final idx = _inbox.indexWhere((l) => l.id == letterId);
    if (idx == -1) return;
    final letter = _inbox[idx];
    if (letter.status == DeliveryStatus.delivered) {
      letter.status = DeliveryStatus.read;
      letter.readAt = DateTime.now();
      // 데모: 일부 보낸 편지를 읽음 처리 (랜덤)
      if (_sent.isNotEmpty) {
        final rng = Random();
        if (rng.nextBool()) {
          final sentIdx = rng.nextInt(_sent.length);
          _sent[sentIdx].isReadByRecipient = true;
        }
      }
      notifyListeners();
      _saveToPrefs();
    }
  }

  /// Build 182: 픽업한 편지의 `content` 가 어떤 이유로든 비어 있을 때
  /// Firestore 에서 원본 문서를 재조회해 본문/이미지/쿠폰코드를 채운다.
  /// - 이전 버전에서 쓰인 후 Firestore 에 도착한 편지 (sync 누락)
  /// - 로컬 prefs 만 남은 잔존 문서
  /// - 네트워크 타이밍 문제로 `content` 가 sync 전에 저장된 경우
  ///
  /// Letter 필드는 final 이라 inbox 항목을 새 인스턴스로 **교체** 해야 한다.
  /// status·readAt 등 이미 mutate 된 상태는 유지.
  /// 반환값 true = 업데이트 발생 (UI 는 notifyListeners 로 리빌드됨).
  Future<bool> refetchLetterContentIfEmpty(String letterId) async {
    if (!FirebaseConfig.kFirebaseEnabled) return false;
    final idx = _inbox.indexWhere((l) => l.id == letterId);
    if (idx == -1) return false;
    final letter = _inbox[idx];
    final needsContent = letter.content.trim().isEmpty;
    final needsRedemption = (letter.category != LetterCategory.general) &&
        (letter.redemptionInfo == null || letter.redemptionInfo!.isEmpty);
    final needsImage = (letter.category == LetterCategory.voucher) &&
        (letter.imageUrl == null || letter.imageUrl!.isEmpty);
    if (!needsContent && !needsRedemption && !needsImage) return false;

    try {
      final doc = await FirestoreService.getDocument('letters/$letterId');
      if (doc == null) return false;
      final map = FirestoreService.fromFirestoreDoc(doc);
      final serverContent = (map['content'] as String?)?.trim() ?? '';
      final serverRed = (map['redemptionInfo'] as String?)?.trim() ?? '';
      final serverImg = (map['imageUrl'] as String?)?.trim() ?? '';

      final fillContent = needsContent && serverContent.isNotEmpty;
      final fillRed = needsRedemption && serverRed.isNotEmpty;
      final fillImg = needsImage && serverImg.isNotEmpty;
      if (!fillContent && !fillRed && !fillImg) return false;

      // Letter 필드 대부분 final — clone 후 신규 인스턴스로 교체. mutate 된
      // inbox 전용 status/readAt 은 유지.
      final updated = Letter(
        id: letter.id,
        senderId: letter.senderId,
        senderName: letter.senderName,
        senderCountry: letter.senderCountry,
        senderCountryFlag: letter.senderCountryFlag,
        content: fillContent ? serverContent : letter.content,
        originLocation: letter.originLocation,
        destinationLocation: letter.destinationLocation,
        destinationCountry: letter.destinationCountry,
        destinationCountryFlag: letter.destinationCountryFlag,
        destinationCity: letter.destinationCity,
        destinationDisplayAddress: letter.destinationDisplayAddress,
        segments: letter.segments,
        currentSegmentIndex: letter.currentSegmentIndex,
        status: letter.status,
        sentAt: letter.sentAt,
        arrivedAt: letter.arrivedAt,
        readAt: letter.readAt,
        arrivalTime: letter.arrivalTime,
        isAnonymous: letter.isAnonymous,
        socialLink: letter.socialLink,
        estimatedTotalMinutes: letter.estimatedTotalMinutes,
        isReadByRecipient: letter.isReadByRecipient,
        letterType: letter.letterType,
        reportCount: letter.reportCount,
        reportedBy: Set<String>.from(letter.reportedBy),
        readCount: letter.readCount,
        maxReaders: letter.maxReaders,
        likeCount: letter.likeCount,
        ratingTotal: letter.ratingTotal,
        ratingCount: letter.ratingCount,
        paperStyle: letter.paperStyle,
        fontStyle: letter.fontStyle,
        deliveryEmoji: letter.deliveryEmoji,
        hasReplied: letter.hasReplied,
        imageUrl: fillImg ? serverImg : letter.imageUrl,
        senderIsBrand: letter.senderIsBrand,
        senderTier: letter.senderTier,
        brandUniquePerUser: letter.brandUniquePerUser,
        expiresAt: letter.expiresAt,
        category: letter.category,
        acceptsReplies: letter.acceptsReplies,
        redemptionInfo: fillRed ? serverRed : letter.redemptionInfo,
        redemptionExpiresAt: letter.redemptionExpiresAt,
      );
      _inbox[idx] = updated;
      notifyListeners();
      _saveToPrefs();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Refetch] letter content 실패: $e');
      return false;
    }
  }

  // ── 잠금 해제 소비 ────────────────────────────────────────────────────────
  void consumeLetterUnlock() {
    _sentSinceLastUnlock = 0;
    notifyListeners();
  }

  // ── 보낸 편지 읽음 처리 ──────────────────────────────────────────────────
  void markLetterReadByRecipient(String letterId) {
    final idx = _sent.indexWhere((l) => l.id == letterId);
    if (idx == -1) return;
    _sent[idx].isReadByRecipient = true;
    notifyListeners();
  }

  // ── 답장 ─────────────────────────────────────────────────────────────────
  Future<bool> replyToLetter({
    required String originalLetterId,
    required String content,
  }) async {
    final idx = _inbox.indexWhere((l) => l.id == originalLetterId);
    if (idx < 0) return false;
    final original = _inbox[idx];
    final sent = await sendLetter(
      content: content,
      destinationCountry: original.senderCountry,
      destinationFlag: original.senderCountryFlag,
      destLat: original.originLocation.latitude,
      destLng: original.originLocation.longitude,
    );
    if (sent) {
      _currentUser.activityScore.replyCount++;
      // 원본 편지에 답장 완료 표시 (1회 제한)
      original.hasReplied = true;
      _saveToPrefs();
      notifyListeners();
    }
    return sent;
  }

  // ── 팔로우 시스템 ──────────────────────────────────────────────────────────
  void followUser(
    String userId,
    String username, {
    String country = '',
    String flag = '🌍',
  }) {
    if (_currentUser.followingIds.contains(userId)) return;
    _currentUser.followingIds.add(userId);

    // Create or update chat session
    if (!_chatSessions.containsKey(userId)) {
      _chatSessions[userId] = ChatSession(
        partnerId: userId,
        partnerName: username,
        partnerCountry: country,
        partnerFlag: flag,
        status:
            ChatStatus.pendingAgreement, // Simulate mutual follow immediately
      );
    } else {
      _chatSessions[userId]!.status = ChatStatus.pendingAgreement;
    }
    notifyListeners();
    _saveDMToPrefs();
  }

  void unfollowUser(String userId) {
    _currentUser.followingIds.remove(userId);
    _chatSessions.remove(userId);
    notifyListeners();
    _saveDMToPrefs();
  }

  bool isFollowing(String userId) => _currentUser.followingIds.contains(userId);

  ChatStatus? getChatStatus(String userId) => _chatSessions[userId]?.status;

  void acceptChatInvite(String partnerId) {
    if (_chatSessions.containsKey(partnerId)) {
      _chatSessions[partnerId]!.status = ChatStatus.chatting;
      if (!_dmMessages.containsKey(partnerId)) {
        _dmMessages[partnerId] = [];
      }
      notifyListeners();
      _saveDMToPrefs();
    }
  }

  void declineChatInvite(String partnerId) {
    _chatSessions[partnerId]?.status = ChatStatus.followed;
    notifyListeners();
    _saveDMToPrefs();
  }

  /// DM 발송. 프리미엄만 가능; DM 10회마다 편지 쿼터 1통 차감.
  /// 반환값: true = 성공, false = 쿼터 부족 또는 권한 없음
  bool sendDM(String partnerId, String content) {
    // ① 권한 체크: 프리미엄만 가능
    if (!canUseDM) return false;

    // ② 발송 가능 여부 체크 (DM 10회 = 편지 1통 쿼터 차감 시점)
    // 이번 DM이 10의 배수가 되면 편지 쿼터 1통 차감
    final nextPending = _pendingDMCount + 1;
    if (nextPending >= _dmPerLetterQuota) {
      // 편지 쿼터 차감 필요 — 일일·월간 모두 체크
      // _canSendLetterByDailyLimit()은 일일+월간 동시 체크
      if (!_canSendLetterByDailyLimit()) {
        return false; // 쿼터 없으면 DM 차단
      }
      _pendingDMCount = 0;
      _dailySentCount++;
      _monthlySentCount++;
      _sentSinceLastUnlock++;
      _saveToPrefs();
    } else {
      _pendingDMCount = nextPending;
      _saveToPrefs();
    }

    if (!_dmMessages.containsKey(partnerId)) {
      _dmMessages[partnerId] = [];
    }
    final msg = DirectMessage(
      id: 'dm_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUser.id,
      senderName: _currentUser.username,
      content: content,
      sentAt: DateTime.now(),
      isRead: false,
    );
    _dmMessages[partnerId]!.add(msg);

    // Simulate partner reply after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_chatSessions.containsKey(partnerId)) {
        final session = _chatSessions[partnerId]!;
        final l10n = _l10n;
        final replies = [
          l10n.stateDmReply1,
          l10n.stateDmReply2,
          l10n.stateDmReply3,
          l10n.stateDmReply4,
          l10n.stateDmReply5,
          l10n.stateDmReply6,
          l10n.stateDmReply7,
        ];
        final reply = DirectMessage(
          id: 'dm_reply_${DateTime.now().millisecondsSinceEpoch}',
          senderId: partnerId,
          senderName: session.partnerName,
          content: replies[DateTime.now().millisecond % replies.length],
          sentAt: DateTime.now(),
          isRead: false,
        );
        _dmMessages[partnerId]!.add(reply);
        session.unreadCount++;
        NotificationService.showDMArrivedNotification(
          senderName: session.partnerName,
          message: reply.content,
          langCode: _currentUser.languageCode,
        );
        notifyListeners();
        _saveDMToPrefs();
      }
    });

    notifyListeners();
    _saveDMToPrefs();
    return true;
  }

  List<DirectMessage> getDMConversation(String partnerId) {
    return List.unmodifiable(_dmMessages[partnerId] ?? []);
  }

  void markDMsRead(String partnerId) {
    if (_dmMessages.containsKey(partnerId)) {
      for (final m in _dmMessages[partnerId]!) {
        m.isRead = true;
      }
    }
    if (_chatSessions.containsKey(partnerId)) {
      _chatSessions[partnerId]!.unreadCount = 0;
    }
    notifyListeners();
    _saveDMToPrefs();
  }

  void _saveDMToPrefs() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(
        'chatSessions',
        jsonEncode(_chatSessions.map((k, v) => MapEntry(k, v.toJson()))),
      );
      prefs.setString(
        'dmMessages',
        jsonEncode(
          _dmMessages.map(
            (k, v) => MapEntry(k, v.map((m) => m.toJson()).toList()),
          ),
        ),
      );
    });
  }

  // ── 익스프레스 편지 발송 (팔로우한 사용자 전용) ────────────────────────────
  Future<bool> sendExpressLetter({
    required String content,
    required String recipientId,
    required String recipientName,
    required String destinationCountry,
    required String destinationFlag,
    required double destLat,
    required double destLng,
  }) async {
    if (!_canSendLetterByDailyLimit()) {
      return false;
    }

    final id = 'express_${DateTime.now().millisecondsSinceEpoch}';
    final fromCity = LatLng(_currentUser.latitude, _currentUser.longitude);
    final toCity = LatLng(destLat, destLng);

    // 실제 위치 기반 발신국 (프로필 country 와 다를 수 있음)
    final geoSvc = GeocodingService.instance;
    final detected = geoSvc.isInitialized
        ? geoSvc.findCountryByCoord(
            _currentUser.latitude,
            _currentUser.longitude,
          )
        : null;
    final actualSenderCountry = detected?['name'] ?? _currentUser.country;
    final actualSenderFlag = detected?['flag'] ?? _currentUser.countryFlag;

    // 현지 언어 3단계 표시 주소 (표시 전용)
    final displayAddr = await GeocodingService.getDisplayAddress(
      destLat,
      destLng,
      languageCode: _currentUser.languageCode,
    );

    final segments = LogisticsHubs.buildRoute(
      fromCountry: actualSenderCountry,
      fromCity: fromCity,
      toCountry: destinationCountry,
      toCity: toCity,
      fromCityName: _l10n.stateMyLocation,
      preferAir: true,
      toCityName: null,
    );
    final expressTotalMin = _currentUser.isBrand ? 5 : 20;
    _rebalanceSegmentEstimatedMinutes(segments, expressTotalMin);
    final now = DateTime.now();
    final letter = Letter(
      id: id,
      senderId: _currentUser.id,
      senderName: _currentUser.username,
      senderCountry: actualSenderCountry,
      senderCountryFlag: actualSenderFlag,
      content: content,
      originLocation: fromCity,
      destinationLocation: toCity,
      destinationCountry: destinationCountry,
      destinationCountryFlag: destinationFlag,
      destinationDisplayAddress: displayAddr,
      segments: segments,
      currentSegmentIndex: 0,
      status: DeliveryStatus.inTransit,
      sentAt: now,
      arrivalTime: now.add(Duration(minutes: expressTotalMin)),
      estimatedTotalMinutes: expressTotalMin,
      letterType: _currentUser.isBrand
          ? LetterType.brandExpress
          : LetterType.express,
    );
    _worldLetters.add(letter);
    _sent.add(letter);
    _consumeDailyQuota();
    _consumeExpressQuotaIfNeeded(true);
    _sentSinceLastUnlock++;
    notifyListeners();
    _saveToPrefs();
    return true;
  }

  // ── 프로필 업데이트 ────────────────────────────────────────────────────────
  void updateProfile({
    String? username,
    String? country,
    String? countryFlag,
    String? socialLink,
    String? email,
    String? languageCode,
  }) {
    if (username != null && username.isNotEmpty)
      _currentUser.username = username;
    if (country != null) _currentUser.country = country;
    if (countryFlag != null) _currentUser.countryFlag = countryFlag;
    if (socialLink != null) _currentUser.socialLink = socialLink;
    if (email != null) _currentUser.email = email;
    if (languageCode != null && languageCode.isNotEmpty)
      _currentUser.languageCode = languageCode;
    notifyListeners();
    _saveToPrefs();
  }

  // ── 알림 초기화 ────────────────────────────────────────────────────────────
  void clearNearbyAlert() {
    _hasNearbyAlert = false;
    notifyListeners();
  }

  // ── 편지 신고 ─────────────────────────────────────────────────────────────
  // 1회 신고 → 즉시 임시 차단 + 발송자 알림 → 관리자가 검토 후 영구 처리
  void reportLetter(String letterId, String reporterId, {String reason = ''}) {
    // inbox에서도 검색
    Letter? letter;
    for (final l in [..._worldLetters, ..._inbox]) {
      if (l.id == letterId) { letter = l; break; }
    }
    if (letter == null) return;
    if (letter.reportedBy.contains(reporterId)) return; // 이미 신고함

    letter.reportedBy.add(reporterId);
    letter.reportCount++;

    // ① 즉시 임시 차단: 발송자의 다른 편지도 지도에서 숨김
    _tempBlockedSenderIds.add(letter.senderId);
    _worldLetters.removeWhere((l) => l.senderId == letter!.senderId);

    // ② 발송자에게 로컬 알림 (발송자가 현재 유저인 경우)
    if (letter.senderId == _currentUser.id) {
      NotificationService.showReportBlockNotification(
        title: _l10n.stateReportBlockTitle,
        body: _l10n.stateReportBlockBody,
      );
    }

    // ③ Firestore에 신고 기록 저장 (관리자 대시보드에서 조회용)
    if (FirebaseConfig.kFirebaseEnabled) {
      _saveReportToFirestore(
        letterId: letterId,
        senderId: letter.senderId,
        reporterId: reporterId,
        reason: reason,
        reportCount: letter.reportCount,
      );
    }

    // ④ 3회 이상 누적 시 영구 차단으로 승격
    if (letter.reportCount >= 3) {
      _blockedSenderIds.add(letter.senderId);
      _tempBlockedSenderIds.remove(letter.senderId);
      _inbox.removeWhere((l) => l.senderId == letter!.senderId);
    }

    notifyListeners();
    _saveToPrefs();
  }

  /// Firestore에 신고 기록 저장 (관리자 조회용)
  Future<void> _saveReportToFirestore({
    required String letterId,
    required String senderId,
    required String reporterId,
    required String reason,
    required int reportCount,
  }) async {
    try {
      final url = Uri.parse(
        '${FirebaseConfig.firestoreBase}/reports?key=${Uri.encodeQueryComponent(FirebaseConfig.apiKey)}',
      );
      final body = {
        'fields': {
          'letterId': {'stringValue': letterId},
          'senderId': {'stringValue': senderId},
          'reporterId': {'stringValue': reporterId},
          'reason': {'stringValue': reason},
          'reportCount': {'integerValue': '$reportCount'},
          'status': {'stringValue': 'pending'}, // pending → reviewed → resolved
          'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        },
      };
      await http.post(url, body: jsonEncode(body), headers: {
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Failed to save report to Firestore: $e');
    }
  }

  // ── 편지 좋아요 ───────────────────────────────────────────────────────────
  void likeLetter(String letterId) {
    for (final letter in [..._worldLetters, ..._inbox]) {
      if (letter.id == letterId) {
        letter.likeCount++;
        if (letter.senderId == _currentUser.id) {
          _currentUser.activityScore.likeCount++;
        }
        notifyListeners();
        _saveToPrefs();
        return;
      }
    }
  }

  // ── 편지 별점 ─────────────────────────────────────────────────────────────
  void rateLetter(String letterId, int rating) {
    // rating: 1~5
    final validRating = rating.clamp(1, 5);
    for (final letter in [..._worldLetters, ..._inbox]) {
      if (letter.id == letterId) {
        letter.ratingTotal += validRating;
        letter.ratingCount++;
        if (letter.senderId == _currentUser.id) {
          _currentUser.activityScore.ratingTotal += validRating;
          _currentUser.activityScore.ratingCount++;
        }
        notifyListeners();
        _saveToPrefs();
        return;
      }
    }
  }

  void updateRating(String letterId, int oldStars, int newStars) {
    // inbox에서 찾기
    final inboxIdx = _inbox.indexWhere((l) => l.id == letterId);
    if (inboxIdx != -1) {
      final letter = _inbox[inboxIdx];
      // 이전 별점 제거, 새 별점 추가
      letter.ratingTotal = (letter.ratingTotal - oldStars + newStars).clamp(
        0,
        999999,
      );
      notifyListeners();
      _saveToPrefs();
      return;
    }
    // worldLetters에서 찾기
    final worldIdx = _worldLetters.indexWhere((l) => l.id == letterId);
    if (worldIdx != -1) {
      final letter = _worldLetters[worldIdx];
      letter.ratingTotal = (letter.ratingTotal - oldStars + newStars).clamp(
        0,
        999999,
      );
      notifyListeners();
      _saveToPrefs();
    }
  }

  // ── Geocoding 누락 주소 보완 ──────────────────────────────────────────────
  /// 이미 로드된 편지 중 destinationDisplayAddress 가 null 인 편지에 대해
  /// 백그라운드로 주소를 조회하여 채워 넣습니다.
  /// (앱 시작 후 또는 편지 목록 갱신 후 한 번 호출하면 됨)
  Future<void> fillMissingDisplayAddresses() async {
    final targets = [
      ..._worldLetters.where((l) => l.destinationDisplayAddress == null),
      ..._sent.where((l) => l.destinationDisplayAddress == null),
    ];
    if (targets.isEmpty) return;
    for (final letter in targets) {
      final addr = await GeocodingService.getDisplayAddress(
        letter.destinationLocation.latitude,
        letter.destinationLocation.longitude,
        languageCode: _currentUser.languageCode,
      );
      if (addr != null) {
        letter.destinationDisplayAddress = addr;
      }
    }
    notifyListeners();
  }

  // ── 차단 여부 확인 ────────────────────────────────────────────────────────
  bool isSenderBlocked(String senderId) =>
      _blockedSenderIds.contains(senderId) ||
      _tempBlockedSenderIds.contains(senderId);

  // ── 편지함에서 발송자 차단 ────────────────────────────────────────────────
  /// 받은 편지 상세 화면에서 해당 편지 발송자를 차단.
  /// 해당 사용자가 보낸 편지를 inbox / worldLetters 에서 모두 제거하고,
  /// 이후 수신도 막음. DM 세션도 함께 정리.
  void blockLetterSender(String senderId) {
    if (senderId.isEmpty || senderId == _currentUser.id) return;
    _blockedSenderIds.add(senderId);
    _chatSessions.remove(senderId);
    _dmMessages.remove(senderId);
    _inbox.removeWhere((l) => l.senderId == senderId);
    _worldLetters.removeWhere((l) => l.senderId == senderId);
    // 지도 위 타워에서도 즉시 제거 (다음 동기화 주기까지 기다리지 않음)
    _mapUsers.removeWhere((u) => u.id == senderId);
    notifyListeners();
    _saveToPrefs();
    _saveDMToPrefs();
  }

  // ── DM 발송자 차단 ────────────────────────────────────────────────────────
  /// DM 화면에서 상대방을 차단. 해당 세션과 메시지를 모두 제거.
  void blockDMSender(String partnerId) {
    _blockedSenderIds.add(partnerId);
    _chatSessions.remove(partnerId);
    _dmMessages.remove(partnerId);
    // 차단된 사용자가 보낸 편지도 inbox / worldLetters 에서 제거
    _inbox.removeWhere((l) => l.senderId == partnerId);
    _worldLetters.removeWhere((l) => l.senderId == partnerId);
    notifyListeners();
    _saveToPrefs();
    _saveDMToPrefs();
  }

  // ── DM 발송자 신고 ────────────────────────────────────────────────────────
  /// DM 화면에서 상대방을 신고. 신고 후 자동 차단.
  /// [reason]: 신고 사유 (스팸, 욕설, 불법정보, 기타)
  void reportDMSender(String partnerId, String reason) {
    // 실제 서버 연동 시 Firestore에 신고 기록 저장 필요
    // 로컬에서는 즉시 차단 처리
    blockDMSender(partnerId);
  }

  // ── DM 파트너 차단 여부 확인 ─────────────────────────────────────────────
  bool isDMPartnerBlocked(String partnerId) =>
      _blockedSenderIds.contains(partnerId);

  // ── 브랜드 추가 발송권 서버 검증 + 지급 ─────────────────────────────────────
  /// 결제 건별 transactionId를 Firestore에 1회성으로 기록한 뒤에만 발송권을 지급.
  Future<BrandExtraVerificationResult> verifyAndGrantBrandExtraQuota({
    required String transactionId,
    required String productId,
    required int quotaAmount,
    String? purchaseDateIso,
    String? appUserId,
  }) async {
    if (!isBrandMember) return BrandExtraVerificationResult.networkError;
    if (!isBrandExtraServerVerificationReady) {
      return BrandExtraVerificationResult.serverUnavailable;
    }

    final nowIso = DateTime.now().toIso8601String();
    final claimDocId = _toSafeDocId(
      'brandextra:${_currentUser.id}:$transactionId',
    );
    final claimResult = await FirestoreService.createDocumentIfAbsent(
      'purchaseClaims/$claimDocId',
      {
        'type': 'brand_extra_quota',
        'userId': _currentUser.id,
        'appUserId': appUserId ?? '',
        'transactionId': transactionId,
        'productId': productId,
        'quotaAmount': quotaAmount,
        'purchaseDate': purchaseDateIso ?? '',
        'createdAt': nowIso,
      },
    );

    if (claimResult == CreateDocumentResult.alreadyExists) {
      return BrandExtraVerificationResult.alreadyProcessed;
    }
    if (claimResult == CreateDocumentResult.error) {
      return BrandExtraVerificationResult.networkError;
    }

    _brandExtraMonthlyQuota += quotaAmount;
    _saveToPrefs();
    notifyListeners();

    final synced =
        await FirestoreService.setDocument('users/${_currentUser.id}', {
          'brandExtraMonthlyQuota': _brandExtraMonthlyQuota,
          'lastBrandExtraTransactionId': transactionId,
          'lastBrandExtraPurchaseAt': purchaseDateIso ?? nowIso,
          'updatedAt': nowIso,
        });
    if (!synced) {
      debugPrint(
        '[BrandExtra] server sync failed after verified claim: tx=$transactionId',
      );
    }
    return BrandExtraVerificationResult.success;
  }

  /// 디버그/테스트 모드 전용 로컬 지급
  Future<bool> grantBrandExtraQuotaLocally({int quotaAmount = 1000}) async {
    if (!isBrandMember) return false;
    _brandExtraMonthlyQuota += quotaAmount;
    _saveToPrefs();
    notifyListeners();
    return true;
  }

  String _toSafeDocId(String raw) =>
      base64Url.encode(utf8.encode(raw)).replaceAll('=', '');

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deliveryTimer?.cancel();
    _worldLetterSyncTimer?.cancel();
    _syncTimer?.cancel();
    _mapSyncTimer?.cancel();
    super.dispose();
  }
}

/// Build 138: 브랜드 분석 결과 데이터 클래스.
/// `fetchBrandAnalytics()` 가 Firestore 에서 집계해 반환.
class BrandAnalytics {
  final int totalSent;      // 총 발송 편지 수
  final int totalPicked;    // 총 픽업 수 (impression)
  final int totalRedeemed;  // 총 사용 완료 수 (conversion)
  final int couponSent;     // 할인권 발송 건수
  final int voucherSent;    // 교환권 발송 건수
  final Map<String, int> countryPicks; // 국가별 픽업 수
  // Build 157: 최근 7일 일별 발송 횟수 (index 0 = 6일 전, index 6 = 오늘).
  final List<int> dailySent;

  const BrandAnalytics({
    required this.totalSent,
    required this.totalPicked,
    required this.totalRedeemed,
    required this.couponSent,
    required this.voucherSent,
    required this.countryPicks,
    this.dailySent = const [0, 0, 0, 0, 0, 0, 0],
  });

  /// 픽업 대비 사용 전환율 (0.0 ~ 1.0). picks 가 0 이면 0.
  double get redeemConversion =>
      totalPicked == 0 ? 0 : totalRedeemed / totalPicked;

  /// 발송 대비 픽업률 (reach — 얼마나 주워졌는지).
  double get pickupReach => totalSent == 0 ? 0 : totalPicked / totalSent;
}
