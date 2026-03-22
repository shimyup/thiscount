import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/letter.dart';
import '../models/user_profile.dart';
import '../core/localization/language_config.dart';
import '../core/data/country_cities.dart';
import '../core/services/notification_service.dart';
import '../core/theme/time_theme.dart';
import '../models/direct_message.dart';

enum DisplayThemeMode { auto, light, dark }

class AppState extends ChangeNotifier {
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

  // ── 지도 위 편지들 ──────────────────────────────────────────────────────────
  final List<Letter> _worldLetters = [];
  List<Letter> get worldLetters => List.unmodifiable(_worldLetters);

  // ── 내 받은 편지함 ──────────────────────────────────────────────────────────
  final List<Letter> _inbox = [];
  List<Letter> get inbox => List.unmodifiable(_inbox);

  // ── 내가 보낸 편지 ──────────────────────────────────────────────────────────
  final List<Letter> _sent = [];
  List<Letter> get sent => List.unmodifiable(_sent);

  // ── 500m 이내 편지 ─────────────────────────────────────────────────────────
  List<Letter> get nearbyLetters =>
      _worldLetters.where((l) => l.status == DeliveryStatus.nearYou).toList();

  // ── 편지 교환 잠금 해제 카운터 ────────────────────────────────────────────
  int _sentSinceLastUnlock = 0;
  int get sentSinceLastUnlock => _sentSinceLastUnlock;
  bool get canViewNextLetter => _sentSinceLastUnlock >= 3;

  // ── 일반 회원 일일 발송 제한 ──────────────────────────────────────────────
  static const int _dailyLimitForGeneralMember = 10;
  int _dailySentCount = 0;
  String _dailySentDateKey = _dateKey(DateTime.now());
  bool get isGeneralMember => !_currentUser.isPremium;
  int get dailySendLimit =>
      isGeneralMember ? _dailyLimitForGeneralMember : 999999;
  int get todaySentCount {
    _rolloverDailySendCounterIfNeeded();
    return _dailySentCount;
  }

  int get remainingDailySendCount {
    _rolloverDailySendCounterIfNeeded();
    if (!isGeneralMember) return 999999;
    return (_dailyLimitForGeneralMember - _dailySentCount).clamp(0, 999999);
  }

  bool get hasRemainingDailyQuota =>
      !isGeneralMember || remainingDailySendCount > 0;
  String get dailyLimitExceededMessage =>
      '일반 회원은 하루 $_dailyLimitForGeneralMember통까지 발송할 수 있어요. 내일 다시 시도해주세요.';

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
        return '자동 (시간대)';
      case DisplayThemeMode.light:
        return '밝은 모드';
      case DisplayThemeMode.dark:
        return '다크 모드';
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

  // ── 사용된 배송지 (나라 → 도시 키 Set, 중복 방지) ──────────────────────────
  final Map<String, Set<String>> _usedDestinations = {};

  // ── 차단된 발신자 (3회 이상 신고) ────────────────────────────────────────
  final Set<String> _blockedSenderIds = {};
  Set<String> get blockedSenderIds => Set.unmodifiable(_blockedSenderIds);

  // ── DM/채팅 시스템 ─────────────────────────────────────────────────────────
  final Map<String, ChatSession> _chatSessions = {};
  Map<String, ChatSession> get chatSessions => Map.unmodifiable(_chatSessions);
  final Map<String, List<DirectMessage>> _dmMessages = {};
  int get totalDMUnread =>
      _chatSessions.values.fold(0, (s, c) => s + c.unreadCount);

  // ── 국가 목록 (좌표 포함) ──────────────────────────────────────────────────
  static const List<Map<String, String>> countries = [
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

  // ── 랜덤 목적지 선택 ───────────────────────────────────────────────────────
  static Map<String, String> randomDestination({String? excludeCountry}) {
    final rng = Random();
    final pool = countries.where((c) => c['name'] != excludeCountry).toList();
    return pool[rng.nextInt(pool.length)];
  }

  AppState() {
    // 목업 데이터는 디버그 빌드에서만 초기화 (릴리즈 빌드에서는 실 데이터만 사용)
    if (kDebugMode) _initMockData();
    _startDeliverySimulation();
  }

  static String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

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

  void _rolloverDailySendCounterIfNeeded() {
    final todayKey = _dateKey(DateTime.now());
    if (_dailySentDateKey != todayKey) {
      _dailySentDateKey = todayKey;
      _dailySentCount = 0;
    }
  }

  bool _canSendLetterByDailyLimit() {
    _rolloverDailySendCounterIfNeeded();
    if (!isGeneralMember) return true;
    return _dailySentCount < _dailyLimitForGeneralMember;
  }

  void _consumeDailyQuota() {
    _rolloverDailySendCounterIfNeeded();
    if (isGeneralMember) _dailySentCount++;
  }

  // ── SharedPreferences 저장 ─────────────────────────────────────────────────
  void _saveToPrefs() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(
        'inbox',
        jsonEncode(_inbox.map((l) => l.toJson()).toList()),
      );
      prefs.setString(
        'sent',
        jsonEncode(_sent.map((l) => l.toJson()).toList()),
      );
      prefs.setStringList('blocked', _blockedSenderIds.toList());
      prefs.setInt('sentSinceLastUnlock', _sentSinceLastUnlock);
      prefs.setInt('dailySentCount', _dailySentCount);
      prefs.setString('dailySentDateKey', _dailySentDateKey);
      prefs.setString(
        'activityScore',
        jsonEncode(_currentUser.activityScore.toJson()),
      );
      prefs.setString('profileImagePath', _currentUser.profileImagePath ?? '');
      prefs.setInt(
        'nicknameChangedAtEpochMs',
        _lastNicknameChangedAt?.millisecondsSinceEpoch ?? 0,
      );
      prefs.setString('displayThemeMode', _displayThemeMode.name);
    });
  }

  // ── SharedPreferences 복원 (main.dart에서 앱 시작 시 호출) ─────────────────
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // 받은 편지함 복원
    final inboxJson = prefs.getString('inbox');
    if (inboxJson != null) {
      _inbox.clear();
      for (final j in jsonDecode(inboxJson) as List) {
        try {
          _inbox.add(Letter.fromJson(j as Map<String, dynamic>));
        } catch (_) {}
      }
    }

    // 보낸 편지 복원
    final sentJson = prefs.getString('sent');
    if (sentJson != null) {
      final decoded = jsonDecode(sentJson) as List;
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
                fromName: '내 위치',
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

    // 차단 목록 복원
    _blockedSenderIds.clear();
    _blockedSenderIds.addAll(prefs.getStringList('blocked') ?? []);

    // 잠금 해제 카운터 복원
    _sentSinceLastUnlock = prefs.getInt('sentSinceLastUnlock') ?? 0;
    _dailySentCount = prefs.getInt('dailySentCount') ?? 0;
    _dailySentDateKey =
        prefs.getString('dailySentDateKey') ?? _dateKey(DateTime.now());
    _rolloverDailySendCounterIfNeeded();
    final profileImagePath = prefs.getString('profileImagePath');
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

    notifyListeners();
  }

  // ── 유저 세팅 (로그인/회원가입 후) ────────────────────────────────────────
  void setUser({
    required String id,
    required String username,
    required String country,
    required String countryFlag,
    bool isPremium = false,
    String? socialLink,
    double? latitude,
    double? longitude,
  }) {
    _currentUser = UserProfile(
      id: id,
      username: username,
      country: country,
      countryFlag: countryFlag,
      isPremium: isPremium,
      socialLink: socialLink,
      profileImagePath: _currentUser.profileImagePath,
      languageCode: LanguageConfig.getLanguageCode(country),
      latitude: latitude ?? 37.5665,
      longitude: longitude ?? 126.9780,
      activityScore: ActivityScore(
        receivedCount: 2,
        replyCount: 0,
        sentCount: 1,
      ),
    );
    _dailySentCount = 0;
    _dailySentDateKey = _dateKey(DateTime.now());
    notifyListeners();
  }

  // ── 위치 업데이트 ─────────────────────────────────────────────────────────
  void updateUserLocation(double lat, double lng) {
    _currentUser.latitude = lat;
    _currentUser.longitude = lng;
    notifyListeners();
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
    notifyListeners();
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
    );
  }

  // ── 배송 시뮬레이션 ────────────────────────────────────────────────────────
  void _startDeliverySimulation() {
    _deliveryTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      bool changed = false;
      final now = DateTime.now();

      for (final letter in _worldLetters) {
        // deliveredFar 편지: 유저가 500m 이내로 이동하면 nearYou로 변경
        if (letter.status == DeliveryStatus.deliveredFar) {
          final dist = letter.destinationLocation.distanceTo(
            LatLng(_currentUser.latitude, _currentUser.longitude),
          );
          if (dist <= 500) {
            letter.status = DeliveryStatus.nearYou;
            _hasNearbyAlert = true;
            _triggerNearbyNotification(letter);
            changed = true;
          }
          continue;
        }

        // nearYou 편지: 유저가 500m 밖으로 이동하면 deliveredFar로 되돌림
        if (letter.status == DeliveryStatus.nearYou) {
          final dist = letter.destinationLocation.distanceTo(
            LatLng(_currentUser.latitude, _currentUser.longitude),
          );
          if (dist > 500) {
            letter.status = DeliveryStatus.deliveredFar;
            changed = true;
          }
          continue;
        }

        if (letter.status != DeliveryStatus.inTransit) continue;

        if (_syncLetterProgressWithClock(letter, now)) {
          changed = true;
        }

        final arrived = letter.arrivalTime != null
            ? !now.isBefore(letter.arrivalTime!)
            : letter.overallProgress >= 0.999;

        if (arrived) {
          // 내 위치 500m 이내인지 확인
          final dist = letter.destinationLocation.distanceTo(
            LatLng(_currentUser.latitude, _currentUser.longitude),
          );
          if (dist <= 500) {
            // 실제 500m 이내
            letter.status = DeliveryStatus.nearYou;
            _hasNearbyAlert = true;
            _triggerNearbyNotification(letter);
          } else {
            // 500m 밖에 있으면 deliveredFar (지도에 표시되지만 열 수 없음)
            letter.status = DeliveryStatus.deliveredFar;
          }
          letter.arrivedAt ??= now;
          changed = true;
        }
      }

      if (changed) notifyListeners();
    });
  }

  bool _syncLetterProgressWithClock(Letter letter, DateTime now) {
    if (letter.segments.isEmpty) return false;

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

    final elapsedMsRaw = now.difference(letter.sentAt).inMilliseconds;
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
    final prefs = await SharedPreferences.getInstance();
    final notifyEnabled = prefs.getBool('notify_nearby') ?? true;
    if (!notifyEnabled) return;
    NotificationService.showNearbyLetterNotification(
      title: '📩 편지가 근처에 있어요!',
      body:
          '${letter.senderCountryFlag} ${letter.senderCountry}에서 온 편지가 500m 이내에 도착했어요',
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
  bool sendLetter({
    required String content,
    required String destinationCountry,
    required String destinationFlag,
    required double destLat,
    required double destLng,
    String? destCityName,  // compose 화면에서 이미 선택된 도시명 (재랜덤 방지)
    String? deliveryEmoji, // 유저가 고른 배송 이모티콘
    String? socialLink,
    bool useShip = false,
    int paperStyle = 0,
    int fontStyle = 0,
  }) {
    if (!_canSendLetterByDailyLimit()) {
      return false;
    }

    final id = 'sent_${DateTime.now().millisecondsSinceEpoch}';
    final fromCity = LatLng(_currentUser.latitude, _currentUser.longitude);

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
      // 도시 미선택일 경우: 나라별 랜덤 도시 선택 (중복 방지)
      _usedDestinations[destinationCountry] ??= {};
      final cityData = CountryCities.randomCityWithOffset(
        destinationCountry,
        usedCityKeys: _usedDestinations[destinationCountry],
      );
      if (cityData != null) {
        finalLat = (cityData['lat'] as num).toDouble();
        finalLng = (cityData['lng'] as num).toDouble();
        toCityName = cityData['name'] as String?;
        _usedDestinations[destinationCountry]!.add(
          CountryCities.cityKey(destinationCountry, cityData['name'] as String),
        );
      } else {
        // 2차: LandAddressGenerator — 육지 경계 박스 내 랜덤 좌표
        final landAddr = LandAddressGenerator.generate(
          excludeCountry: _currentUser.country,
        );
        finalLat = (landAddr['lat'] as num).toDouble();
        finalLng = (landAddr['lng'] as num).toDouble();
      }
    }
    final toCity = LatLng(finalLat, finalLng);
    final isDomestic = _currentUser.country == destinationCountry;
    final segments = LogisticsHubs.buildRoute(
      fromCountry: _currentUser.country,
      fromCity: fromCity,
      toCountry: destinationCountry,
      toCity: toCity,
      fromCityName: '내 위치',
      preferAir: !useShip,
      toCityName: toCityName,
    );

    final segMin = segments.fold<int>(0, (s, seg) => s + seg.estimatedMinutes);
    final int totalMin;
    if (isDomestic) {
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
      senderCountry: _currentUser.country,
      senderCountryFlag: _currentUser.countryFlag,
      content: content,
      originLocation: fromCity,
      destinationLocation: toCity,
      destinationCountry: destinationCountry,
      destinationCountryFlag: destinationFlag,
      destinationCity: toCityName,
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
    );

    _worldLetters.add(letter);
    _sent.add(letter);
    _consumeDailyQuota();
    _currentUser.activityScore.sentCount++;
    _sentSinceLastUnlock++;
    notifyListeners();
    _saveToPrefs();
    return true;
  }

  // ── 편지 습득 ─────────────────────────────────────────────────────────────
  /// [distanceCheck] false로 설정하면 거리 검증 없이 습득 (테스트/관리자용)
  bool pickUpLetter(String letterId, {bool distanceCheck = true}) {
    final idx = _worldLetters.indexWhere((l) => l.id == letterId);
    if (idx == -1) return false;

    final letter = _worldLetters[idx];

    // 실제 거리 재검증: 편지 목적지와 현재 유저 위치 간 Haversine 거리
    if (distanceCheck) {
      final dist = letter.destinationLocation.distanceTo(
        LatLng(_currentUser.latitude, _currentUser.longitude),
      );
      if (dist > 500) return false; // 500m 초과 → 수령 불가
    }

    letter.status = DeliveryStatus.delivered;
    letter.arrivedAt = DateTime.now();

    _inbox.add(letter);
    _worldLetters.removeAt(idx);
    _currentUser.activityScore.receivedCount++;
    NotificationService.showLetterArrivedNotification(
      senderCountry: letter.senderCountry,
      senderFlag: letter.senderCountryFlag,
    );
    notifyListeners();
    _saveToPrefs();
    return true;
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
  bool replyToLetter({
    required String originalLetterId,
    required String content,
  }) {
    final original = _inbox.firstWhere(
      (l) => l.id == originalLetterId,
      orElse: () => _inbox.first,
    );
    final sent = sendLetter(
      content: content,
      destinationCountry: original.senderCountry,
      destinationFlag: original.senderCountryFlag,
      destLat: original.originLocation.latitude,
      destLng: original.originLocation.longitude,
    );
    if (sent) {
      _currentUser.activityScore.replyCount++;
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

  void sendDM(String partnerId, String content) {
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
        final replies = [
          '정말요? 저도 그렇게 생각해요! 😊',
          '편지로 이렇게 대화할 수 있다니 신기해요',
          '언젠가 직접 만날 수 있으면 좋겠어요 ✨',
          '당신의 이야기가 궁금해요. 더 들려주세요!',
          '저도 비슷한 경험이 있어요. 공감이 가네요',
          '와, 정말요? 그 나라는 어때요?',
          '너무 좋은 말이에요. 감사해요 💌',
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
        );
        notifyListeners();
        _saveDMToPrefs();
      }
    });

    notifyListeners();
    _saveDMToPrefs();
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
  bool sendExpressLetter({
    required String content,
    required String recipientId,
    required String recipientName,
    required String destinationCountry,
    required String destinationFlag,
    required double destLat,
    required double destLng,
  }) {
    if (!_canSendLetterByDailyLimit()) {
      return false;
    }

    final id = 'express_${DateTime.now().millisecondsSinceEpoch}';
    final fromCity = LatLng(_currentUser.latitude, _currentUser.longitude);
    final toCity = LatLng(destLat, destLng);
    final segments = LogisticsHubs.buildRoute(
      fromCountry: _currentUser.country,
      fromCity: fromCity,
      toCountry: destinationCountry,
      toCity: toCity,
      fromCityName: '내 위치',
      preferAir: true,
      toCityName: null,
    );
    const expressTotalMin = 20;
    _rebalanceSegmentEstimatedMinutes(segments, expressTotalMin);
    final now = DateTime.now();
    final letter = Letter(
      id: id,
      senderId: _currentUser.id,
      senderName: _currentUser.username,
      senderCountry: _currentUser.country,
      senderCountryFlag: _currentUser.countryFlag,
      content: content,
      originLocation: fromCity,
      destinationLocation: toCity,
      destinationCountry: destinationCountry,
      destinationCountryFlag: destinationFlag,
      segments: segments,
      currentSegmentIndex: 0,
      status: DeliveryStatus.inTransit,
      sentAt: now,
      arrivalTime: now.add(const Duration(minutes: expressTotalMin)),
      estimatedTotalMinutes: expressTotalMin,
      letterType: LetterType.express,
    );
    _worldLetters.add(letter);
    _sent.add(letter);
    _consumeDailyQuota();
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
  }) {
    if (username != null && username.isNotEmpty)
      _currentUser.username = username;
    if (country != null) _currentUser.country = country;
    if (countryFlag != null) _currentUser.countryFlag = countryFlag;
    if (socialLink != null) _currentUser.socialLink = socialLink;
    if (email != null) _currentUser.email = email;
    notifyListeners();
  }

  // ── 알림 초기화 ────────────────────────────────────────────────────────────
  void clearNearbyAlert() {
    _hasNearbyAlert = false;
    notifyListeners();
  }

  // ── 편지 신고 ─────────────────────────────────────────────────────────────
  void reportLetter(String letterId, String reporterId) {
    final idx = _worldLetters.indexWhere((l) => l.id == letterId);
    if (idx == -1) return;
    final letter = _worldLetters[idx];
    if (letter.reportedBy.contains(reporterId)) return; // 이미 신고함
    letter.reportedBy.add(reporterId);
    letter.reportCount++;
    if (letter.reportCount >= 3) {
      _blockedSenderIds.add(letter.senderId);
      _worldLetters.removeWhere((l) => l.senderId == letter.senderId);
      _inbox.removeWhere((l) => l.senderId == letter.senderId);
    }
    notifyListeners();
    _saveToPrefs();
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

  // ── 차단 여부 확인 ────────────────────────────────────────────────────────
  bool isSenderBlocked(String senderId) => _blockedSenderIds.contains(senderId);

  @override
  void dispose() {
    _deliveryTimer?.cancel();
    super.dispose();
  }
}
