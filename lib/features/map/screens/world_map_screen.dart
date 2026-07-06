import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/secure_clock.dart';
import '../../../core/services/secure_location.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/map_config.dart';
import '../../progression/user_level.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../widgets/app_snack.dart';
import '../../../core/localization/country_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/hunt_palette.dart';
import '../../../core/utils/person_emoji.dart';
import '../../../models/letter.dart';
import '../../inbox/widgets/letter_read_screen.dart';
import '../../../widgets/app_card.dart';
import '../../../models/user_profile.dart';
import '../../../state/app_state.dart';
import '../../brand/brand_promo_banner.dart';
import '../../premium/premium_gate_sheet.dart';

// 목업 타워 데이터 제거 → AppState.mapUsers (Firestore 실시간) 사용

class WorldMapScreen extends StatefulWidget {
  final VoidCallback? onGoToInbox;
  // Build 408 (QQ9): false 면 상단 chrome(헤더/국가바/배너 등)을 숨겨 지도를
  //   다른 탭의 배경 peek 로 쓸 때 UI 가 비치지 않게 한다. 기본 true.
  final bool showChrome;
  const WorldMapScreen({super.key, this.onGoToInbox, this.showChrome = true});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();

  /// MainScaffold에서 발송 직후 호출: 마지막 발송 편지 위치로 카메라 이동
  static final focusSentLetterNotifier = ValueNotifier<bool>(false);
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const String _permissionDialogDateKey =
      'world_map_permission_denied_forever_prompt_date';
  // Build 239: 카운터 라벨은 줌 거의 모든 단계에서 노출 (사용자 ID 항상 보이게).
  static const double _towerLabelZoomThreshold = 3.0;
  // Build 151: 지도 줌/센터 세션 persistence 키.
  static const String _prefLastZoom = 'map_last_zoom';
  static const String _prefLastLat = 'map_last_lat';
  static const String _prefLastLng = 'map_last_lng';

  // 타일 설정은 MapConfig에서 중앙 관리 (lib/core/config/map_config.dart)
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  Timer? _positionTimer; // 실시간 편지 위치 갱신용 1초 타이머
  Timer? _mapRefreshTimer; // 5분마다 타워 목록 갱신
  Timer? _positionSaveDebounce; // Build 151: 지도 이동 시 debounce 저장
  final _tickNotifier = ValueNotifier<int>(0);
  double _lastKnownZoom = 2.0;
  // Build 459 (UI 다이어트): 국가 점프 바는 세계 탐색 줌(<8)에서만 — 동네 줌
  //   레벨에선 무관한 글로벌 UI 가 최상단을 차지하던 과밀 해소.
  bool _showCountryBar = true;
  static const double _countryBarZoomThreshold = 8.0;
  bool _showTowerLabels = false;
  final bool _showRouteLines = true;
  bool _showNearbyOnly = false;
  final bool _showTowers = true;
  // Build 491 (줍기 코스): 코스 점선 표시 토글 (칩 탭).
  bool _showCourse = false;
  // Build 271: 위치 권한 거부 상태 — 상단 영구 배너 표시용.
  bool _locationPermissionDenied = false;
  // Build 250: 국가 점프 바 리셋 트리거 — "내 위치" 버튼 탭 시 증가시켜
  // _CountryJumpBar 가 본인 국가 (인덱스 0) 으로 자동 복귀하게 함.
  int _countryBarResetSignal = 0;

  @override
  void initState() {
    super.initState();
    // Build 219: lifecycle 옵저버 등록 — 백그라운드 → 포그라운드 복귀 시
    // pulse 애니메이션 재시작 + 마커 위치 즉시 재계산. 기존엔 OS 가 timer/
    // animation 을 정지해 "편지가 가다가 멈춰 보이는" 잔상이 남았음.
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    // 1초마다 tickNotifier 갱신 → 편지 마커 위치가 sentAt~arrivalTime 기반으로
    // 부드럽게 이동. Build 300 (HIGH performance audit): inTransit 편지가
    // 없으면 marker 위치가 변하지 않으므로 tick 발화를 skip — CPU/배터리 절약.
    _startPositionTimer();
    // 지도 열릴 때 회원 타워 즉시 로드 + 유저 위치로 자동 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      state.fetchMapUsers(force: true);
      // Build 408 (QQ8): 지도 진입 시 월드 편지(쿠폰)도 즉시 1회 fetch.
      //   이전엔 _initFirebaseAndSync 의 30초 주기 timer 에만 의존 → 신규
      //   가입자가 첫 지도 화면에서 이미 발송된 쿠폰이 안 보이고 최대 30초
      //   비어 있었음. force fetch 로 기존 드롭을 즉시 노출 + 줍기 가능.
      unawaited(state.syncWorldLettersFromServer());
      // Build 151: 이전 세션의 지도 위치·줌이 저장돼 있으면 우선 복원.
      // 없으면 기존 로직 (유저 현재 위치로 이동).
      _restoreLastMapPosition(state);
      // Build 414 (#3 아하모먼트): 첫 지도 진입 신규 사용자에게 줍기 유도 1회.
      unawaited(_maybeShowFirstPickupCoachmark(state));
    });
    // 15분마다 타워 목록 자동 갱신 (과도한 네트워크 호출 방지)
    _mapRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (mounted) context.read<AppState>().fetchMapUsers();
    });
    _checkLocationPermission();
    // 편지 발송 후 지도 포커스 이벤트 수신
    WorldMapScreen.focusSentLetterNotifier.addListener(_onFocusSentLetter);
  }

  void _onFocusSentLetter() {
    if (!WorldMapScreen.focusSentLetterNotifier.value) return;
    WorldMapScreen.focusSentLetterNotifier.value = false;
    final state = context.read<AppState>();
    if (state.sent.isEmpty) return;
    final last = state.sent.last;
    // 발송 편지의 출발 좌표로 카메라 이동 (줌 3 = 세계지도에서 경로 보이는 수준)
    final origin = last.originLocation;
    if (origin.latitude != 0 && origin.longitude != 0) {
      _mapController.move(ll.LatLng(origin.latitude, origin.longitude), 3.0);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WorldMapScreen.focusSentLetterNotifier.removeListener(_onFocusSentLetter);
    // Build 351 (PR-V1 시뮬레이션 P2): cancel + null 명시 — lifecycle resumed
    //   에서 재할당 시 이전 timer 가 GC 안 돼 callback chain leak 가능.
    _positionTimer?.cancel();
    _positionTimer = null;
    _mapRefreshTimer?.cancel();
    _mapRefreshTimer = null;
    _positionSaveDebounce?.cancel();
    _positionSaveDebounce = null;
    _tickNotifier.dispose();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Build 484: position tick 타이머 — inTransit 편지가 있을 때만 매초 발화
  //   (마커 위치 보간). initState·앱 재개 양쪽에서 동일 사용(중복/회귀 방지).
  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final hasInTransit = context.read<AppState>().worldLetters.any(
            (l) => l.status == DeliveryStatus.inTransit,
          );
      if (hasInTransit) _tickNotifier.value++;
    });
  }

  /// Build 219: 백그라운드에서 복귀할 때 편지가 멈춰 보이지 않도록.
  /// AppState 의 reconcile 은 wall-clock 기반으로 letter status 를 즉시
  /// 캐치업하지만, 지도 위 마커는 별도 vsync 애니메이션이라 OS 가 정지
  /// 시킨 상태로 머무를 수 있다. 이 콜백에서 명시적으로 깨운다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!mounted) return;
      // pulse 재시작 (이미 동작 중이면 idempotent)
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
      // position timer 가 OS 에 의해 멈춰 있으면 다시 등록
      // Build 351 (PR-V1 시뮬레이션 P2): cancel + null 명시 — 이전 timer leak 방지.
      if (_positionTimer == null || !_positionTimer!.isActive) {
        // Build 484: 재개 시에도 initState 와 동일한 hasInTransit skip 적용
        //   (이전엔 무조건 매초 _tickNotifier++ → inTransit 0 이어도 앱 재개 후
        //    매초 전체 마커 rebuild = 배터리/CPU 회귀).
        _startPositionTimer();
      }
      // 즉시 1회 강제 rebuild → 마커가 새 wall-clock 으로 위치 재계산
      _tickNotifier.value++;
    }
  }

  /// Build 151: 이전 세션 지도 위치·줌 복원. 저장된 값 없으면 유저 좌표로
  /// 초기 이동 (기존 로직).
  /// Build 247: 첫 시작 시 전체 지도(zoom 2) → 내 위치(zoom 14) 부드럽게
  /// 줌인 애니메이션 추가. 사용자에게 "어디서 → 어디로" 시각 컨텍스트 제공.
  Future<void> _restoreLastMapPosition(AppState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedZoom = prefs.getDouble(_prefLastZoom);
      final savedLat = prefs.getDouble(_prefLastLat);
      final savedLng = prefs.getDouble(_prefLastLng);
      if (!mounted) return;
      if (savedZoom != null && savedLat != null && savedLng != null) {
        // 복귀 사용자 (저장값 있음): 즉시 마지막 지점으로 이동.
        // Build 408 (QQ2 후속): minZoom 2.0→3.0 상향 후, 구버전에서 저장된
        //   2.x 줌은 카메라에선 3.0 으로 clamp 되지만 _lastKnownZoom 에는 raw
        //   값이 들어가 라벨 임계/다음 저장이 실제 카메라와 어긋남. clamp 통일.
        final clampedZoom = savedZoom < 3.0 ? 3.0 : savedZoom;
        _mapController.move(ll.LatLng(savedLat, savedLng), clampedZoom);
        _lastKnownZoom = clampedZoom;
        return;
      }
    } catch (_) {}
    // 저장값 없거나 실패 → 첫 시작: 전체 지도에서 줌인.
    if (!mounted) return;
    final lat = state.currentUser.latitude;
    final lng = state.currentUser.longitude;
    if (lat == 0 && lng == 0) return;
    final isDefault =
        (lat - 37.5665).abs() < 0.001 && (lng - 126.978).abs() < 0.001;
    final endZoom = isDefault ? 12.0 : 14.0;
    // 첫 프레임 잠시 보여주고 (전체 지도 인상), 줌인 시작
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await _animateZoomTo(ll.LatLng(lat, lng), endZoom);
  }

  /// Build 247: 부드러운 zoom-in 애니메이션. flutter_map 8.x 가 native
  /// 애니메이션 메서드 미제공이라 수동 보간 (30 프레임 / 1.4초).
  Future<void> _animateZoomTo(ll.LatLng target, double endZoom) async {
    const totalDuration = Duration(milliseconds: 1400);
    const frames = 30;
    final stepMs = totalDuration.inMilliseconds ~/ frames;
    final start = _mapController.camera;
    final startLat = start.center.latitude;
    final startLng = start.center.longitude;
    final startZoom = start.zoom;
    for (int i = 1; i <= frames; i++) {
      if (!mounted) return;
      final t = i / frames;
      final eased = Curves.easeInOutCubic.transform(t);
      final lat = startLat + (target.latitude - startLat) * eased;
      final lng = startLng + (target.longitude - startLng) * eased;
      final zoom = startZoom + (endZoom - startZoom) * eased;
      _mapController.move(ll.LatLng(lat, lng), zoom);
      _lastKnownZoom = zoom;
      await Future.delayed(Duration(milliseconds: stepMs));
    }
  }

  /// Build 151: 지도 이동 시 debounce 저장 (2초 후). `onPositionChanged`
  /// 가 드래그 중 초당 수 회 호출될 수 있어 매번 I/O 하면 낭비.
  void _scheduleMapPositionSave() {
    _positionSaveDebounce?.cancel();
    _positionSaveDebounce = Timer(const Duration(seconds: 2), () async {
      try {
        final camera = _mapController.camera;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_prefLastZoom, camera.zoom);
        await prefs.setDouble(_prefLastLat, camera.center.latitude);
        await prefs.setDouble(_prefLastLng, camera.center.longitude);
      } catch (_) {}
    });
  }

  // 타일 URL / 서브도메인 → MapConfig 위임 (중앙 관리)

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final l10n = AppL10n.of(state.currentUser.languageCode);
        final langCode = state.currentUser.languageCode;
        // 지도 표시: 배송중 + nearYou + deliveredFar + 도착했지만 아직 열리지 않은 편지
        // inbox에 있는 delivered(수령 후 미열람) 편지도 📮 마커로 지도에 표시
        // Build 409 (sim P1.48): 소진(만료/정원/차단)된 inbox 편지는 지도 마커
        //   에서 제외 — 이전엔 무조건 추가되어 만료 쿠폰이 줍기 가능처럼 보임.
        final inboxDelivered = state.inbox
            .where((l) =>
                l.status == DeliveryStatus.delivered &&
                !l.isReadByRecipient &&
                !_isLetterConsumed(l))
            .toList();
        // Build 409 (sim P1.46): 이미 인박스에 들어온 편지 id 집합 — worldLetters
        //   에서 같은 id 를 제외해 "주운 편지가 지도에 중복(여전히 줍기 가능)
        //   마커로 겹쳐 보이는" 문제 차단. inbox 복사본이 canonical 마커.
        final inboxIds = inboxDelivered.map((l) => l.id).toSet();
        final letters = _showNearbyOnly
            ? state.nearbyLetters
            : [
                ...state.worldLetters.where(
                  (l) =>
                      // Build 408 (QQ4): 다른 사람이 다 주워간(maxReaders 도달)
                      //   / 만료 / 신고차단된 쿠폰은 지도에서 제외. 이전엔 status
                      //   만 보고 표시 → 소진된 쿠폰이 잔존했음.
                      !_isLetterConsumed(l) &&
                      !inboxIds.contains(l.id) &&
                      // Build 421 (sim-fresh P3): nearbyLetters 와 동일 — 이미
                      //   픽업한 brandUniquePerUser 캠페인의 잔여 마커 숨김.
                      !state.hasPickedUpCampaign(l.campaignId) &&
                      (l.status == DeliveryStatus.inTransit ||
                          l.status == DeliveryStatus.nearYou ||
                          // 수령 대기 (목적지 도착, 500m 밖): 지도에서 계속 표시
                          l.status == DeliveryStatus.deliveredFar ||
                          // 일반 편지: 도착 후 누군가 열기 전까지 지도에 유지
                          (l.status == DeliveryStatus.delivered &&
                              !l.isReadByRecipient)),
                ),
                // 내가 수령했지만 아직 읽지 않은 inbox 편지도 지도에 📮로 표시
                ...inboxDelivered,
              ];
        // Build 457: Premium 관심 카테고리 필터 — 브랜드가 업종을 지정한 캠페인만
        //   대상(미지정·개인 편지는 통과). nearbyOnly/world 양 분기 공통 적용.
        final filteredLetters = state.interestFilterActive
            ? letters.where(state.passesInterestFilter).toList()
            : letters;
        final timeColors = AppTimeColors.of(context);
        final mapLangCode = MapConfig.resolveMapLanguage(
          country: state.currentUser.country,
          appLanguageCode: state.currentUser.languageCode,
        );
        const darkMode = false; // 지도는 항상 밝은 타일 고정 (밤/다크모드 무관)

        // ── 클러스터 사전 계산 (타워 마커 + 내 타워 onTap 공유) ──
        final mapClusters = _clusterMapUsers(state.mapUsers);
        final myNearestCluster = _findNearestCluster(
          mapClusters,
          state.currentUser.latitude,
          state.currentUser.longitude,
        );

        return Stack(
          children: [
            // ── 지도 ───────────────────────────────────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const ll.LatLng(20.0, 10.0), // 전체 세계 지도
                initialZoom: 3.0,
                // Build 408 (QQ2): minZoom 2.0 → 3.0. 세로로 긴 폰 화면에서
                //   zoom 2 는 월드 타일 높이(256*2^2=1024px)가 화면을 못 채워
                //   상/하단에 bgDeep(어두운) 검정 띠 노출. zoom 3(2048px)이면
                //   어떤 폰이든 타일이 화면을 덮음.
                minZoom: 3.0,
                maxZoom: 18.0,
                backgroundColor: timeColors.bgDeep,
                // Build 408 (QQ2): 카메라 가장자리를 월드 경계(±85 lat, ±180
                //   lng) 안으로 제한 → 축소·패닝 시 타일 밖 빈 영역(검정) 진입
                //   차단. contain 은 viewport edge 를 bounds 안에 가둔다.
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(
                    const ll.LatLng(-85.0, -180.0),
                    const ll.LatLng(85.0, 180.0),
                  ),
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onPositionChanged: (position, _) {
                  final zoom = position.zoom;
                  _lastKnownZoom = zoom;
                  final shouldShowLabels = zoom >= _towerLabelZoomThreshold;
                  if (shouldShowLabels != _showTowerLabels && mounted) {
                    setState(() => _showTowerLabels = shouldShowLabels);
                  }
                  final shouldShowCountryBar =
                      zoom < _countryBarZoomThreshold;
                  if (shouldShowCountryBar != _showCountryBar && mounted) {
                    setState(() => _showCountryBar = shouldShowCountryBar);
                  }
                  // Build 151: 이동 멈춘 2초 뒤 현재 좌표·줌 저장
                  // (SharedPreferences). 다음 앱 실행 시 이 지점으로 복원.
                  _scheduleMapPositionSave();
                },
              ),
              children: [
                // ── 기반 타일 (MapConfig 중앙 관리) ───────────────────────
                // key: 언어·테마 변경 시 캐시 타일 강제 갱신
                // keepBuffer: 뷰포트 밖 타일 최대 보유 수 (메모리 제한)
                // evictErrorTileStrategy: 오류 타일 즉시 해제
                TileLayer(
                  key: ValueKey('base_${mapLangCode}_$darkMode'),
                  urlTemplate: MapConfig.tileUrl(
                    mapLangCode,
                    darkMode: darkMode,
                  ),
                  subdomains: MapConfig.subdomains,
                  userAgentPackageName: 'io.thiscount',
                  maxZoom: 19,
                  maxNativeZoom: 19,
                  keepBuffer: 2,
                  evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                ),
                // ── 현지어 레이블 오버레이 (야간 + CartoDB 폴백 시에만) ─────
                if (MapConfig.labelOverlayUrl(darkMode: darkMode) != null)
                  TileLayer(
                    key: ValueKey('label_${mapLangCode}_$darkMode'),
                    urlTemplate: MapConfig.labelOverlayUrl(darkMode: darkMode)!,
                    subdomains: MapConfig.subdomains,
                    userAgentPackageName: 'io.thiscount',
                    maxZoom: 19,
                    maxNativeZoom: 19,
                    keepBuffer: 2,
                    evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                  ),
                // ── 배송 경로선 ────────────────────────────────────────────
                if (_showRouteLines)
                  PolylineLayer(polylines: _buildRoutePolylines(filteredLetters)),
                // ── Build 491 (줍기 코스): 유저→쿠폰들 최근접 순회 점선 ──
                if (_showCourse)
                  PolylineLayer(polylines: _buildCoursePolylines(state)),
                // ── 허브 마커 ─────────────────────────────────────────────
                MarkerLayer(markers: _buildHubMarkers(filteredLetters)),
                // ── 2km 반경 원 (마커 아래에 배치 → 탭 차단 방지) ──────
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: ll.LatLng(
                        state.currentUser.latitude,
                        state.currentUser.longitude,
                      ),
                      radius: 2000,
                      useRadiusInMeter: true,
                      // Build 460 (키비주얼 위계): 픽업 링(3px·0.98)이 유일한
                      //   주인공이 되도록 알림 반경 원은 점선 느낌의 옅은 보조로.
                      color: timeColors.accent.withValues(alpha: 0.04),
                      borderColor: timeColors.accent.withValues(alpha: 0.18),
                      borderStrokeWidth: 1.0,
                    ),
                  ],
                ),
                // ── 픽업 반경 링 (Build 120) ────────────────────────────
                // 실제 줍기 가능한 반경을 티어별 색으로 상시 표시. Premium
                // (골드) 과 Free (티일) 의 시각적 차이가 유저에게 "5× 넓은
                // 원" 을 매일 느끼게 하는 핵심 앵커.
                // - Free: teal (200m + 레벨 보너스)
                // - Premium: gold (1km + 레벨 보너스)
                // Build 429 (device): Brand 는 픽업 불가 → 줍기 반경 링 미표시
                //   (떠 있으면 "주울 수 있다" 오해). Brand 는 발송/캠페인 트랙.
                if (!state.currentUser.isBrand)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: ll.LatLng(
                          state.currentUser.latitude,
                          state.currentUser.longitude,
                        ),
                        radius: state.pickupRadiusMeters,
                        useRadiusInMeter: true,
                        color: state.currentUser.isPremium
                            ? AppColors.gold.withValues(alpha: 0.20)
                            : AppColors.teal.withValues(alpha: 0.22),
                        borderColor: state.currentUser.isPremium
                            ? AppColors.gold.withValues(alpha: 0.98)
                            : AppColors.teal.withValues(alpha: 0.98),
                        borderStrokeWidth: 3.0,
                      ),
                    ],
                  ),
                // ── 모든 마커 (단일 레이어 — 히트 테스팅 정확도 보장) ──
                // 순서: 클러스터 타워 → 내 타워 + 편지 (뒤쪽이 위에 렌더링)
                ValueListenableBuilder<int>(
                  valueListenable: _tickNotifier,
                  builder: (context, tick, child) {
                    return MarkerLayer(
                      markers: [
                        if (_showTowers)
                          ..._buildMapTowerMarkers(
                            context,
                            state,
                            l10n,
                            showLabels: _showTowerLabels,
                            zoom: _lastKnownZoom,
                            clusters: mapClusters,
                          ),
                        ..._buildLetterMarkers(
                          filteredLetters, state, l10n, langCode,
                          nearestCluster: myNearestCluster,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.15,
                      colors: [
                        Colors.transparent,
                        timeColors.bgDeep.withValues(alpha: 0.14),
                        timeColors.bgDeep.withValues(alpha: 0.28),
                      ],
                      stops: const [0.58, 0.84, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // ── 상단 헤더 ──────────────────────────────────────────────────
            // Build 408 (QQ9): peek 모드(showChrome=false)에서는 헤더/배너를
            //   숨겨 다른 탭 상단에 지도 chrome 이 비치는 회귀 차단.
            if (widget.showChrome)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: const _MapHeader(),
              ),
            // Build 485 (UX sim #2): 관심 필터가 모든 마커를 숨겼을 때 안내 —
            //   '왜 안 보이지?'(네트워크/위치 오류 오인) 막다른길 해소 + 1탭 해제.
            if (widget.showChrome &&
                state.interestFilterActive &&
                filteredLetters.isEmpty &&
                letters.isNotEmpty)
              Positioned(
                top: 92,
                left: 16,
                right: 16,
                child: SafeArea(
                  bottom: false,
                  child: GestureDetector(
                    onTap: () {
                      state.setInterestTypes({});
                      state.setInterestCategories({});
                    },
                    child: AppCard.accent(
                      color: AppColors.gold,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_alt_off_rounded,
                              color: AppColors.gold, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.mapFilterNoResults,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.commonClearAll,
                            style: TextStyle(
                              color: AppColors.gold.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Build 271: 위치 권한 거부 시 영구 배너 — 사용자가 "왜 핀이 안 보이지?"
            // 같은 혼란 차단. 탭 시 앱 설정 진입.
            if (widget.showChrome && _locationPermissionDenied)
              Positioned(
                top: 48,
                left: 12,
                right: 12,
                child: SafeArea(
                  bottom: false,
                  child: _LocationPermissionBanner(
                    onTap: () => Geolocator.openAppSettings(),
                  ),
                ),
              ),
            // Build 165: 국가 점프 스크롤 바 — 수평 스크롤 칩으로 다른 나라
            // 지도로 원탭 이동. 기존 "수동 줌아웃 후 드래그" 산만함 해소.
            //
            // Build 404 (PR-MM2): newcomer (가입 5분 이내) 에게는 hide.
            //   첫 인상 지도에 헤더 외 floating UI 가 5+ 동시 노출되면 인지
            //   부담. 5분 후 자연스럽게 나라 점프 + 브랜드 프로모 노출.
            if (widget.showChrome &&
                !state.currentUser.isNewcomer &&
                _showCountryBar)
              Positioned(
                top: 56,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: _CountryJumpBar(
                    myCountry: state.currentUser.country,
                    resetSignal: _countryBarResetSignal,
                    onJump: (lat, lng) {
                      HapticFeedback.lightImpact();
                      _mapController.move(ll.LatLng(lat, lng), 5.5);
                    },
                  ),
                ),
              ),
            // Build 142: 헤더·국가 바 아래로 슬라이드-다운 브랜드 홍보 배너.
            // Build 176: 국가 바 높이 42→32 로 축소, 배너 top 104→94.
            // Build 404 (PR-MM2): newcomer hide — 위 country bar 와 동일 사유.
            // Build 490: 헌트 배너 활성 시 숨김 (상호 배타 — 오버레이 과밀 방지).
            if (widget.showChrome &&
                !state.currentUser.isNewcomer &&
                state.activeHuntCampaign == null)
              Positioned(
                top: _showCountryBar ? 94 : 56,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: BrandPromoBanner(
                    onRevealOnMap: (letter) {
                      _mapController.move(
                        ll.LatLng(
                          letter.destinationLocation.latitude,
                          letter.destinationLocation.longitude,
                        ),
                        14.0,
                      );
                    },
                  ),
                ),
              ),
            // ── Build 490 (드롭 헌트 P1-N1): 캠페인 헌트 배너 ─────────────
            // 프로모 배너와 상호 배타(핸드오프 스펙 — 유료 캠페인 우선):
            // 헌트 캠페인 활성 시 이 배너만, 없으면 기존 프로모 배너.
            // 위치: 프로모 배너(위치3)와 도착 배너(위치4) 사이 top 130.
            if (widget.showChrome && state.activeHuntCampaign != null)
              Positioned(
                top: _showCountryBar ? 130 : 94,
                left: 16,
                right: 16,
                child: SafeArea(
                  bottom: false,
                  child: _CampaignHuntBanner(
                    l10n: l10n,
                    summary: state.activeHuntCampaign!,
                    onTap: () {
                      final s = state.activeHuntCampaign;
                      if (s == null) return;
                      _mapController.move(
                        ll.LatLng(s.anchor.latitude, s.anchor.longitude),
                        14.0,
                      );
                    },
                  ),
                ),
              ),
            // ── Build 491 (줍기 코스): 하단 코스 칩 ──────────────────────
            if (widget.showChrome && !state.currentUser.isBrand)
              _buildCourseChip(state, l10n),
            // ── 근처 도착 배너 (experienced 레벨 이상에서만) ─────────────
            // 브랜드도 줍기 가능해져서 `!isBrand` 조건 제거.
            if (state.hasNearbyAlert &&
                state.isFeatureUnlocked(UnlockableFeature.nearbyPickup))
              Positioned(
                top: 130,
                left: 16,
                right: 16,
                child: _NearbyAlertBanner(
                  l10n: l10n,
                  count: state.nearbyLetters.length,
                  onTap: () {
                    setState(() => _showNearbyOnly = true);
                    _mapController.move(
                      ll.LatLng(
                        state.currentUser.latitude,
                        state.currentUser.longitude,
                      ),
                      12.0,
                    );
                    state.clearNearbyAlert();
                  },
                ),
              ),
            // Brand-only send banner removed — 포지셔닝 변경으로 브랜드도
            // 편지를 주울 수 있게 됨. 배너를 띄울 이유가 사라짐.
            // Build 186: 픽업 쿨다운 pill — `nearbyPickupRemainingCooldown` 가
            // null 이 아닐 때만 상시 표시. `_tickNotifier` 가 1초마다 갱신되어
            // MM:SS 카운트다운이 실시간으로 줄어듦. Free 60분 / Premium·Brand
            // 10분. "지금 왜 못 줍지?" 하는 혼선 제거.
            ValueListenableBuilder<int>(
              valueListenable: _tickNotifier,
              builder: (_, __, ___) {
                final remaining = state.nearbyPickupRemainingCooldown;
                if (remaining == null) return const SizedBox.shrink();
                final mins = remaining.inMinutes;
                final secs = remaining.inSeconds % 60;
                final mmss = mins > 0
                    ? '${mins}m ${secs.toString().padLeft(2, '0')}s'
                    : '${secs}s';
                return Positioned(
                  top: 180,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textMuted.withValues(alpha: 0.35),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('⏱', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          l10n.mapCooldownPill(mmss),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Build 120: 나침반 힌트 배너 — 반경 안에 편지가 없을 때 가장 가까운
            // 바깥쪽 편지의 방향·거리를 한 줄로 알려준다. "앱을 열었는데 반경 0통"
            // 인 죽은 상태를 "저쪽으로 150m 가면 있어요" 로 전환.
            // Build 152: 반경 안에 편지 있을 때 시간대별 인사 + 카운트 pill.
            // 기존 나침반 슬롯과 상호 배타 — 둘 다 top 220 에 배치하되
            // nearbyLetters.isNotEmpty 이면 인사 pill, 비어있으면 방향 안내.
            //
            // Build 216: Brand 사용자는 "주울 편지" 가 아니라 "내 캠페인 픽업 결과"
            // 가 더 의미 있음. nearby info 대신 가장 최근 픽업된 캠페인 위치를
            // 표시하고 탭 시 그 좌표로 카메라 이동.
            if (state.currentUser.isBrand) ...[
              Builder(builder: (ctx) {
                final picked = state.brandMostRecentlyPickedUpLetter;
                if (picked == null) return const SizedBox.shrink();
                // Build 217: 위치를 하단으로 이동 — 상단의 country bar / brand
                // promo banner 와 겹침 해소. 탭 시 _showNearbyOnly 해제 + 카메라
                // 이동이 확실히 보이도록 zoom 14 단일 move 로 단순화.
                return Positioned(
                  bottom: 96,
                  left: 16,
                  right: 16,
                  child: _BrandRecentPickupBanner(
                    letter: picked,
                    l10n: AppL10n.of(
                      ctx.read<AppState>().currentUser.languageCode,
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final target = ll.LatLng(
                        picked.destinationLocation.latitude,
                        picked.destinationLocation.longitude,
                      );
                      _positionSaveDebounce?.cancel();
                      // 필터 해제 — 마커가 'nearby only' 로 가려지면 안 보임.
                      if (_showNearbyOnly) {
                        setState(() => _showNearbyOnly = false);
                      }
                      // 두 단계로 zoom 적용 — flutter_map 의 같은-프레임 두 번
                      // move() 무시 회피. 첫 번째 줌아웃, 두 번째 줌인 으로
                      // "이동했다" 시각 피드백 명확.
                      _mapController.move(target, 12.0);
                      Future.delayed(const Duration(milliseconds: 180), () {
                        if (!mounted) return;
                        _mapController.move(target, 14.5);
                      });
                    },
                  ),
                );
              }),
            ] else if (state.nearbyLetters.isNotEmpty &&
                !state.hasNearbyAlert)
              Positioned(
                top: 130,
                left: 16,
                right: 16,
                child: _DailyGreetingPill(
                  count: state.nearbyLetters.length,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showNearbyOnly = true);
                    _mapController.move(
                      ll.LatLng(
                        state.currentUser.latitude,
                        state.currentUser.longitude,
                      ),
                      14.0,
                    );
                  },
                ),
              ),
            if (!_locationPermissionDenied &&
                !state.currentUser.isBrand &&
                state.nearbyLetters.isEmpty &&
                state.worldLetters.isNotEmpty)
              Builder(builder: (ctx) {
                final hint = _nearestLetterCompass(state);
                if (hint == null) return const SizedBox.shrink();
                return Positioned(
                  top: 220,
                  left: 16,
                  right: 16,
                  // Build 141: 배너 탭 → 해당 편지 위치로 지도 이동.
                  // 반경 밖이라 줍을 순 없지만 "어디 있는지" 눈으로 확인
                  // 가능. 줌 레벨 14 로 시내 블록 수준까지 접근.
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final target = ll.LatLng(
                        hint.letter.destinationLocation.latitude,
                        hint.letter.destinationLocation.longitude,
                      );
                      // Build 183: 근본 원인 수정.
                      // (1) 세션 persist debounce (Build 151, 2초 지연) 을
                      //     먼저 취소 — 이전 수동 이동의 결과가 SharedPreferences
                      //     에 덮어써지는 경쟁 방지 + 다음 복원 실패 차단.
                      // (2) 필터를 "전체보기" 로 돌려 대상 편지 마커가 실제로
                      //     렌더되도록.
                      // (3) zoom nudge 를 **Future.delayed** 로 분리. 같은
                      //     프레임에서 두 번의 move() 를 연속 호출하면 flutter_map
                      //     8.x 는 두 번째만 반영하고 시각적 변화가 없다. 160ms
                      //     사이로 띄워 두 번의 카메라 이벤트가 독립적으로
                      //     처리되게 한다.
                      _positionSaveDebounce?.cancel();
                      setState(() {
                        _showNearbyOnly = false;
                      });
                      // 조건 없이 무조건 zoom out → zoom in — 이미 같은 위치여도
                      // 사용자에게 "이동했다" 는 피드백을 주기 위함.
                      _mapController.move(target, 12.8);
                      Future.delayed(const Duration(milliseconds: 160), () {
                        if (!mounted) return;
                        _mapController.move(target, 14.0);
                      });
                    },
                    // Build 404 (PR-MM2): inline Container → AppCard.accent
                    //   통일. border alpha / radius / shadow 모두 토큰 사용.
                    child: AppCard.accent(
                      color: AppColors.gold,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              l10n.mapCompassHint(
                                hint.distance, hint.arrow, hint.emoji,
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.gold,
                            size: 11,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            // ── 지도 퀵 액션 (전체보기/내 위치) ─────────────────────────────
            // Build 271: 줌 ± 버튼 제거. 핀치 제스처로 충분하고, 우측 4버튼이
            // 동시 노출돼 1순위 액션(내 위치)을 시각적으로 묻히게 했다.
            Positioned(
              bottom: 120,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Build 437 (device #7): 지도 위 줌 +/- 버튼 복원(Build 271 에서
                  //   제거됐었음). 핀치 외 명시적 줌 컨트롤 요구. min/max 3~18 clamp.
                  _MapQuickActionButton(
                    icon: Icons.add_rounded,
                    tooltip: l10n.koEn('확대', 'Zoom in'),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final cam = _mapController.camera;
                      _mapController.move(
                        cam.center,
                        (cam.zoom + 1).clamp(3.0, 18.0),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _MapQuickActionButton(
                    icon: Icons.remove_rounded,
                    tooltip: l10n.koEn('축소', 'Zoom out'),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final cam = _mapController.camera;
                      _mapController.move(
                        cam.center,
                        (cam.zoom - 1).clamp(3.0, 18.0),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  // Build 457: 관심 카테고리 필터 (Premium 전용) — Free 는 업셀.
                  // Build 480 (발견성): 활성 시 선택 수 배지 노출.
                  // Build 482 (사용자 요청): Brand 계정은 지도 필터 자체를 제외(숨김).
                  if (!state.currentUser.isBrand) ...[
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _MapQuickActionButton(
                          icon: state.interestFilterActive
                              ? Icons.filter_alt_rounded
                              : Icons.filter_alt_outlined,
                          tooltip: l10n.mapInterestFilterTitle,
                          highlighted: state.interestFilterActive,
                          onTap: () =>
                              _openInterestFilter(context, state, l10n),
                        ),
                        if (state.interestFilterActive)
                          PositionedDirectional(
                            top: -4,
                            end: -4,
                            child: Container(
                              constraints: const BoxConstraints(
                                  minWidth: 18, minHeight: 18),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.bgDeep, width: 1.5),
                              ),
                              child: Text(
                                '${state.interestFilterCount}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF1A1300),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  _MapQuickActionButton(
                    icon: Icons.public_rounded,
                    tooltip: l10n.mapViewAll,
                    onTap: () {
                      setState(() => _showNearbyOnly = false);
                      _mapController.move(
                        ll.LatLng(
                          state.currentUser.latitude,
                          state.currentUser.longitude,
                        ),
                        3.0,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _MyLocationButton(
                    mapController: _mapController,
                    onLocationUpdated: (lat, lng) {
                      state.updateUserLocation(lat, lng);
                      if (mounted) {
                        setState(() => _countryBarResetSignal++);
                      }
                    },
                  ),
                ],
              ),
            ),
            // 하단 통계 바 폐기 (Build 201) — 사용자 요청. 핵심 액션은 우측 quick
            // action 버튼 (전체보기·줌·내 위치) 으로 이미 커버됨.
          ],
        );
      },
    );
  }

  // ── 경로선 ──────────────────────────────────────────────────────────────────
  // ── Build 491: 줍기 코스 v2 ───────────────────────────────────────────
  // 반경 내 도착 쿠폰을 **점수 = 혜택 가중 ÷ 보정 도보거리** 로 선별해 시간
  // 프리셋(20/40분) 안에서 순회. 검증(4역할) 반영:
  //  · 거리 단독 최적화 → 낮은 가치 쿠폰 낭비 (기획) → 카테고리·티어·만료 가중
  //  · greedy 순서 손실 (수학) → 2-opt 개선 패스 (스톱≤6 이라 사실상 최적)
  //  · 직선≠보행 (하천/철길) → ×1.35 맨해튼 보정 + '예상' 표기, 실안내 외부 위임
  static const double _courseRadiusM = 2500;
  static const int _courseMaxStops = 6;
  static const double _walkMetersPerMin = 67; // 4km/h
  static const double _walkCorrection = 1.35; // 직선→보행 맨해튼 보정
  // 시간 프리셋 (칩 롱프레스 토글).
  int _courseBudgetMin = 20;

  double _courseWeight(AppState state, Letter l) {
    // 카테고리: 할인권/교환권 > 일반 홍보.
    var w = l.category == LetterCategory.general ? 0.8 : 1.2;
    // 티어 기여: "이 브랜드 2장 이내 승급"이면 가중 — 티어와 코스의 상호 견인.
    final card = state.stampCardFor(l.senderId);
    if (card != null && card.tierLevel < 3 && card.pickupsToNextTier <= 2) {
      w *= 1.3;
    }
    // 만료 임박(3시간 이내) 보너스 — 놓치기 전에 코스에 태움.
    final exp = l.expiresAt;
    if (exp != null && exp.difference(DateTime.now()).inHours < 3) w *= 1.4;
    return w;
  }

  List<Letter> _computePickupCourse(AppState state) {
    final uLat = state.currentUser.latitude;
    final uLng = state.currentUser.longitude;
    if (uLat == 0 || uLng == 0) return const [];
    final me = LatLng(uLat, uLng);
    // nearbyLetters 와 동일한 소진/만료/캠페인 dedup 기준 + 도착 상태 확장.
    final candidates = state.worldLetters
        .where((l) =>
            (l.status == DeliveryStatus.nearYou ||
                l.status == DeliveryStatus.deliveredFar) &&
            !l.isExpired &&
            l.readCount < l.maxReaders &&
            !l.isBlocked &&
            l.destinationLocation.distanceTo(me) <= _courseRadiusM)
        .toList();
    final course = <Letter>[];
    var cur = me;
    var totalM = 0.0;
    final budgetM = _courseBudgetMin * _walkMetersPerMin;
    while (candidates.isNotEmpty && course.length < _courseMaxStops) {
      Letter? best;
      var bestScore = -1.0;
      var bestD = 0.0;
      for (final l in candidates) {
        final d = l.destinationLocation.distanceTo(cur) * _walkCorrection;
        // +50m 상수: 초근접 후보의 점수 폭주(0 나눗셈 근접) 방지.
        final s = _courseWeight(state, l) / (d + 50);
        if (s > bestScore) {
          bestScore = s;
          best = l;
          bestD = d;
        }
      }
      if (best == null) break;
      candidates.remove(best);
      // 시간 예산 초과 스톱은 건너뛰고 다음 후보 탐색 (더 가까운 게 남을 수 있음).
      if (totalM + bestD > budgetM) continue;
      course.add(best);
      totalM += bestD;
      cur = best.destinationLocation;
    }
    _twoOptImprove(me, course);
    return course;
  }

  /// 2-opt: 선택된 스톱 집합의 방문 순서를 구간 뒤집기로 개선.
  /// 스톱 ≤6 → 반복 수 무시 가능, greedy 대비 최대 ~25% 거리 손실 제거.
  void _twoOptImprove(LatLng me, List<Letter> course) {
    if (course.length < 3) return;
    double len(List<Letter> c) {
      var cur = me;
      var t = 0.0;
      for (final l in c) {
        t += l.destinationLocation.distanceTo(cur);
        cur = l.destinationLocation;
      }
      return t;
    }

    var improved = true;
    while (improved) {
      improved = false;
      for (var i = 0; i < course.length - 1; i++) {
        for (var j = i + 1; j < course.length; j++) {
          final cand = [...course];
          final seg = cand.sublist(i, j + 1).reversed.toList();
          cand.replaceRange(i, j + 1, seg);
          if (len(cand) + 1e-9 < len(course)) {
            course
              ..clear()
              ..addAll(cand);
            improved = true;
          }
        }
      }
    }
  }

  double _courseDistanceM(AppState state, List<Letter> stops) {
    var cur = LatLng(
      state.currentUser.latitude,
      state.currentUser.longitude,
    );
    var total = 0.0;
    for (final l in stops) {
      total += l.destinationLocation.distanceTo(cur) * _walkCorrection;
      cur = l.destinationLocation;
    }
    return total;
  }

  List<Polyline> _buildCoursePolylines(AppState state) {
    final stops = _computePickupCourse(state);
    if (stops.length < 2) return const [];
    final pts = <ll.LatLng>[
      ll.LatLng(state.currentUser.latitude, state.currentUser.longitude),
      for (final l in stops)
        ll.LatLng(
          l.destinationLocation.latitude,
          l.destinationLocation.longitude,
        ),
    ];
    return [
      Polyline(
        points: pts,
        color: HuntPalette.lime.withValues(alpha: 0.9),
        strokeWidth: 3,
        pattern: const StrokePattern.dotted(),
      ),
    ];
  }

  Widget _buildCourseChip(AppState state, AppL10n l10n) {
    final stops = _computePickupCourse(state);
    if (stops.length < 2) return const SizedBox.shrink();
    final distM = _courseDistanceM(state, stops);
    final mins = (distM / _walkMetersPerMin).ceil();
    final first = stops.first;
    return Positioned(
      bottom: 18,
      left: 16,
      right: 16,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              button: true,
              label: l10n.mapCourseChip(stops.length, mins),
              child: GestureDetector(
                onTap: () => setState(() => _showCourse = !_showCourse),
                // Build 491 v2: 롱프레스 = 시간 프리셋 20↔40분 토글.
                onLongPress: () {
                  setState(() {
                    _courseBudgetMin = _courseBudgetMin == 20 ? 40 : 20;
                  });
                  AppSnack.info(
                    context,
                    l10n.mapCoursePreset(_courseBudgetMin),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _showCourse
                        ? HuntPalette.lime
                        : AppColors.bgCard.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _showCourse
                          ? HuntPalette.lime
                          : HuntPalette.lime.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🧺', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        l10n.mapCourseChip(stops.length, mins),
                        style: TextStyle(
                          color: _showCourse
                              ? HuntPalette.limeInk
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 길안내: 첫 목적지를 카카오맵 웹 링크로 (앱 스킴
                      // 화이트리스트 불필요 — universal link 가 앱/웹 자동 분기).
                      Semantics(
                        button: true,
                        label: l10n.mapCourseGuide,
                        child: GestureDetector(
                          onTap: () => launchUrl(
                            Uri.parse(
                              'https://map.kakao.com/link/to/'
                              '${Uri.encodeComponent(l10n.mapCourseGuide)},'
                              '${first.destinationLocation.latitude},'
                              '${first.destinationLocation.longitude}',
                            ),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: Icon(
                            Icons.navigation_rounded,
                            size: 18,
                            color: _showCourse
                                ? HuntPalette.limeInk
                                : HuntPalette.lime,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Polyline> _buildRoutePolylines(List<Letter> letters) {
    final polylines = <Polyline>[];
    for (final letter in letters) {
      if (letter.status != DeliveryStatus.inTransit) continue;
      for (int i = 0; i < letter.segments.length; i++) {
        final seg = letter.segments[i];
        final isActive = i == letter.currentSegmentIndex;
        final isCompleted = i < letter.currentSegmentIndex;
        polylines.add(
          Polyline(
            points: [
              ll.LatLng(seg.from.latitude, seg.from.longitude),
              ll.LatLng(seg.to.latitude, seg.to.longitude),
            ],
            color: isActive
                ? _transportColor(seg.mode).withValues(alpha: 0.75)
                : isCompleted
                ? AppColors.textMuted.withValues(alpha: 0.25)
                : AppColors.gold.withValues(alpha: 0.10),
            strokeWidth: isActive ? 2.5 : 1.0,
            pattern: isCompleted
                ? const StrokePattern.solid()
                : const StrokePattern.dotted(),
          ),
        );
      }
    }
    return polylines;
  }

  Color _transportColor(TransportMode mode) {
    switch (mode) {
      case TransportMode.truck:
        return AppColors.gold;
      case TransportMode.airplane:
        return AppColors.teal;
      case TransportMode.ship:
        return const Color(0xFF60A5FA);
    }
  }

  // ── 허브 마커 ────────────────────────────────────────────────────────────────
  List<Marker> _buildHubMarkers(List<Letter> letters) {
    final hubs = <String, ({ll.LatLng pos, bool isAirport})>{};
    for (final letter in letters) {
      if (letter.status != DeliveryStatus.inTransit) continue;
      for (final seg in letter.segments) {
        void addHub(LatLng p, HubType type) {
          final key = '${p.latitude},${p.longitude}';
          hubs[key] = (
            pos: ll.LatLng(p.latitude, p.longitude),
            isAirport: type == HubType.airport,
          );
        }

        if (seg.fromType == HubType.airport ||
            seg.fromType == HubType.seaport) {
          addHub(seg.from, seg.fromType);
        }
        if (seg.toType == HubType.airport || seg.toType == HubType.seaport) {
          addHub(seg.to, seg.toType);
        }
      }
    }

    return hubs.values.map((hub) {
      final color = hub.isAirport ? AppColors.teal : const Color(0xFF60A5FA);
      return Marker(
        point: hub.pos,
        width: 26,
        height: 26,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 4),
            ],
          ),
          child: Center(
            child: Text(
              hub.isAirport ? '✈' : '⚓',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ── 편지 마커 ────────────────────────────────────────────────────────────────
  // Build 457: 관심 카테고리 필터 — Premium 은 선택 시트, Free 는 업셀.
  Future<void> _openInterestFilter(
    BuildContext context,
    AppState state,
    AppL10n l10n,
  ) async {
    if (!state.canUseInterestFilter) {
      PremiumGateSheet.show(
        context,
        featureName: l10n.mapInterestFilterTitle,
        featureEmoji: '🔎',
        description: l10n.mapInterestFilterUpsell,
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgCard,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _InterestFilterSheet(state: state, l10n: l10n),
    );
    if (mounted) setState(() {});
  }

  List<Marker> _buildLetterMarkers(
    List<Letter> letters, AppState state, AppL10n l10n, String langCode, {
    List<MapUser>? nearestCluster,
  }) {
    final markers = <Marker>[];

    // 내 타워 마커 (탭하면 내 랭킹 정보 or 겹친 편지 disambiguation)
    // 타워 위치(2km 이내)에 수령 가능한 nearYou 편지 목록
    final towerLat = state.currentUser.latitude;
    final towerLng = state.currentUser.longitude;
    // Build 422 (sim-fresh2 P3): GPS 미설정(0,0) 사용자는 내 타워 마커를 (0,0)
    //   기니만 바다 한가운데 표시하지 않음.
    final hasValidTower = !(towerLat == 0.0 && towerLng == 0.0);
    final overlappingLetters = letters
        .where(
          (l) =>
              (l.status == DeliveryStatus.nearYou ||
                  (l.status == DeliveryStatus.delivered &&
                      !l.isReadByRecipient)) &&
              l.destinationLocation.distanceTo(LatLng(towerLat, towerLng)) <
                  state.pickupRadiusMeters,
        )
        .toList();

    if (hasValidTower) {
      markers.add(
      Marker(
        point: ll.LatLng(towerLat, towerLng),
        width: 64,
        height: 80,
        child: GestureDetector(
          onTap: () {
            if (overlappingLetters.isNotEmpty) {
              _showTowerLetterDisambiguation(
                context, state, overlappingLetters, l10n, langCode,
              );
              return;
            }
            // 사전 계산된 최근접 클러스터 사용 (GPS 거리 검색 대신)
            if (nearestCluster != null && nearestCluster.isNotEmpty) {
              if (kDebugMode) debugPrint('[MyTowerTap] nearestCluster=${nearestCluster.length}');
              _showOverlappingTowerPicker(context, nearestCluster, l10n);
            } else {
              _showMyTowerInfo(context, context.read<AppState>(), l10n);
            }
          },
          // Build 120: 내 타워 길게 누르면 "내 줍기 반경" 즉시 확인 — 반경 링
          // 이 항상 그려져 있지만, 확인 동작을 명시적으로 지원해 "여기가 내
          // 사냥터" 감각 + 숫자 확인 (haptic + 스낵바) 를 제공한다.
          onLongPress: () {
            HapticFeedback.mediumImpact();
            final radius = state.pickupRadiusMeters.round();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${l10n.towerPulseHint} · ${radius}m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                backgroundColor: state.currentUser.isPremium
                    ? AppColors.goldDark
                    : AppColors.tealDark,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          // Build 128: Brand 공식 발송인은 원래 타워 비주얼로 복귀
          // (레벨 시스템 밖 — 캐릭터 진화 아바타는 Free/Premium 전용).
          child: state.currentUser.isBrand
              ? _BrandTowerMarker(
                  tier: state.currentUser.activityScore.tier,
                  flag: state.currentUser.countryFlag,
                  floors: state.currentUser.activityScore.towerFloors,
                  pulseController: _pulseController,
                  pendingLetterCount: overlappingLetters.length,
                  isBrandVerified: state.isBrandVerified,
                )
              : _MyTowerMarker(
                  tier: state.currentUser.activityScore.tier,
                  flag: state.currentUser.countryFlag,
                  floors: state.currentUser.activityScore.towerFloors,
                  pulseController: _pulseController,
                  pendingLetterCount: overlappingLetters.length,
                  // Build 121: 아바타 색상을 픽업 반경 링과 일치시킨다.
                  isPremium: state.currentUser.isPremium,
                  isBrand: state.currentUser.isBrand,
                  hunterLevel: state.currentLevel,
                  // 최상위 획득 마일스톤의 대표 아이템을 아바타 좌상단에 작게.
                  milestoneItemEmoji: state.latestHunterItemEmoji,
                  // Build 122: 레벨에 따라 진화하는 캐릭터 이모지 (중앙).
                  characterEmoji: state.currentCharacterEmoji,
                  // Build 125: 동행 동물 + 머리 위 악세사리 — 꾸미기 요소.
                  companionEmoji: state.activeCompanionEmoji,
                  accessoryEmoji: state.activeAccessoryEmoji,
                  // Build 127: Brand 사업자 인증 완료 시 ✅ 뱃지.
                  isBrandVerified: state.isBrandVerified,
                ),
        ),
      ),
    );
    }

    // Build 422 (sim-fresh2 P3): 도착 마커 상태 판정도 SecureClock — 시계 앞당겨
    //   조기 '도착' 표시 차단.
    final now = SecureClock.now();
    final viewerIsPremiumOrBrand =
        state.currentUser.isPremium || state.currentUser.isBrand;

    // Build 164: 유저 GPS 위치 기준 "가장 가까운 편지" 식별.
    // delivered/nearYou 상태의 편지 중 거리 최소 1개만 highlight.
    // 픽업 가능 반경 안·밖 무관 — 지도에서 "어디가 가장 가까운지" 명시.
    final myPos = LatLng(
      state.currentUser.latitude,
      state.currentUser.longitude,
    );
    String? nearestLetterId;
    double nearestDist = double.infinity;
    for (final l in letters) {
      if (l.status != DeliveryStatus.delivered &&
          l.status != DeliveryStatus.nearYou) continue;
      if (l.isReadByRecipient) continue;
      final d = l.destinationLocation.distanceTo(myPos);
      if (d < nearestDist) {
        nearestDist = d;
        nearestLetterId = l.id;
      }
    }

    for (final letter in letters) {
      // 도착 후 미열람 편지: 도착지에 '📮 대기중' 마커로 표시
      if (letter.status == DeliveryStatus.delivered &&
          !letter.isReadByRecipient) {
        final destLoc = letter.destinationLocation;
        final isBrandLetter = letter.senderTier == LetterSenderTier.brand;
        final isNearest = letter.id == nearestLetterId;
        markers.add(
          Marker(
            point: ll.LatLng(destLoc.latitude, destLoc.longitude),
            width: isNearest ? 80 : 40,
            // Build 415: nearest 라벨(칩+2px gap) 포함 시 비-브랜드 마커가 70px
            //   박스를 1.5px 초과(RenderFlex overflow) → 추가 높이 22→24 로 여유.
            height: (isBrandLetter && viewerIsPremiumOrBrand ? 62 : 48) +
                (isNearest ? 26 : 0),
            child: GestureDetector(
              onTap: () => _onLetterTap(context, letter, state, l10n, langCode),
              child: _UnreadDeliveredMarker(
                letter: letter,
                pulseController: _pulseController,
                viewerIsPremiumOrBrand: viewerIsPremiumOrBrand,
                isNearest: isNearest,
                nearestLabel: l10n.mapNearestLetterLabel,
              ),
            ),
          ),
        );
        continue;
      }

      // nearYou: 미열람 마커와 동일한 스타일로 표시
      if (letter.status == DeliveryStatus.nearYou) {
        final destLoc = letter.destinationLocation;
        final isBrandLetter = letter.senderTier == LetterSenderTier.brand;
        final isNearest = letter.id == nearestLetterId;
        markers.add(
          Marker(
            point: ll.LatLng(destLoc.latitude, destLoc.longitude),
            width: isNearest ? 80 : 40,
            // Build 415: nearest 라벨(칩+2px gap) 포함 시 비-브랜드 마커가 70px
            //   박스를 1.5px 초과(RenderFlex overflow) → 추가 높이 22→24 로 여유.
            height: (isBrandLetter && viewerIsPremiumOrBrand ? 62 : 48) +
                (isNearest ? 26 : 0),
            child: GestureDetector(
              onTap: () => _onLetterTap(context, letter, state, l10n, langCode),
              child: _UnreadDeliveredMarker(
                letter: letter,
                pulseController: _pulseController,
                viewerIsPremiumOrBrand: viewerIsPremiumOrBrand,
                isNearest: isNearest,
                nearestLabel: l10n.mapNearestLetterLabel,
              ),
            ),
          ),
        );
        continue;
      }

      if (letter.status != DeliveryStatus.inTransit &&
          letter.status != DeliveryStatus.deliveredFar)
        continue;

      // 이미 도착 완료된 편지(progress >= 0.999 또는 arrivalTime 지남)는
      // 다음 deliveryTimer 사이클에서 상태가 전환될 때까지 📬로 표시
      final bool actuallyArrived = letter.status == DeliveryStatus.inTransit &&
          (letter.overallProgress >= 0.999 ||
              (letter.arrivalTime != null && !now.isBefore(letter.arrivalTime!)));

      // 실시간 위치: sentAt~arrivalTime 기반 보간 (arrivalTime 없으면 기존 currentLocation)
      final pos = (letter.status == DeliveryStatus.deliveredFar || actuallyArrived)
          ? letter.destinationLocation
          : letter.currentPositionAt(now);
      final showAsArrived = letter.status == DeliveryStatus.deliveredFar || actuallyArrived;
      markers.add(
        Marker(
          point: ll.LatLng(pos.latitude, pos.longitude),
          // Build 324: marker bounds 확대 — _ArrivedWaitingMarker 가 +35% 키워졌
          //   고 FOMO outer ring 까지 포함하려면 78px 필요. transport 도 일관성 위해 키움.
          width: showAsArrived ? 78 : 44,
          height: showAsArrived ? 78 : 44,
          child: GestureDetector(
            onTap: () => _onLetterTap(context, letter, state, l10n, langCode),
            child: showAsArrived && letter.status == DeliveryStatus.inTransit
                ? _ArrivedWaitingMarker(
                    letter: letter,
                    pulseController: _pulseController,
                  )
                : _TransportMarker(
                    letter: letter,
                    pulseController: _pulseController,
                  ),
          ),
        ),
      );
      // 도착지 핀 마커 제거 — 편지 이모지(📮💌📪)만 표시
    }
    return markers;
  }

  // Build 408 (QQ4): 쿠폰이 "소진"되어 지도에서 사라져야 하는지 판정.
  //   - readCount >= maxReaders : 정원 모두 주워감 (다른 사람 포함)
  //   - isExpired               : expiresAt 경과
  //   - isBlocked               : 신고 누적(reportCount>=3)
  //   syncWorldLettersFromServer 가 readCount/maxReaders/reportCount 를 주기적
  //   으로 병합하므로 다른 사용자의 픽업도 반영됨.
  static bool _isLetterConsumed(Letter l) =>
      l.readCount >= l.maxReaders || l.isExpired || l.isBlocked;

  // ── 지도 타워 마커 (내 타워 + 다른 회원) ─────────────────────────────────────
  //
  // 500m 이내 타워를 클러스터로 묶어 **하나의 마커**로 표시.
  // 클러스터 탭 → 바텀시트 리스트, 단독 타워 탭 → 상세.
  // ── 500m Union-Find 클러스터링 (공용) ──
  static List<List<MapUser>> _clusterMapUsers(List<MapUser> users) {
    if (users.isEmpty) return [];
    const radius500m = 0.005; // 500m ≈ 0.005°
    final n = users.length;
    final parent = List<int>.generate(n, (i) => i);
    int find(int x) {
      while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
      return x;
    }
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final dLat = users[i].lat - users[j].lat;
        final dLng = users[i].lng - users[j].lng;
        if (dLat * dLat + dLng * dLng < radius500m * radius500m) {
          parent[find(i)] = find(j);
        }
      }
    }
    final map = <int, List<int>>{};
    for (int i = 0; i < n; i++) {
      map.putIfAbsent(find(i), () => []).add(i);
    }
    return map.values.map((indices) {
      indices.sort((a, b) => users[a].rank.compareTo(users[b].rank));
      return indices.map((i) => users[i]).toList();
    }).toList();
  }

  /// 주어진 위치에 가장 가까운 클러스터를 반환 (5km 이내)
  static List<MapUser>? _findNearestCluster(
    List<List<MapUser>> clusters,
    double lat,
    double lng,
  ) {
    // Build 422 (sim-fresh2 P1): GPS 미설정(0,0) 사용자는 '내 타워' 매칭 불가 —
    //   (0,0) 근처 타인 클러스터를 내 것으로 오인해 타인 정보 화면이 뜨던 문제.
    if (lat == 0 && lng == 0) return null;
    List<MapUser>? best;
    // Build 422 (sim-fresh2 P1): 5.5km → ~500m 로 좁힘 — 이전엔 5km 내 아무 타인
    //   클러스터나 '내 타워' 탭으로 가로채 본인 정보 화면 도달 불가/타인 노출.
    double bestDist = 0.005 * 0.005; // 최대 ~500m
    for (final cluster in clusters) {
      for (final u in cluster) {
        final dLat = u.lat - lat;
        final dLng = u.lng - lng;
        final dist = dLat * dLat + dLng * dLng;
        if (dist < bestDist) {
          bestDist = dist;
          best = cluster;
        }
      }
    }
    return best;
  }

  List<Marker> _buildMapTowerMarkers(
    BuildContext context,
    AppState state,
    AppL10n l10n, {
    required bool showLabels,
    required double zoom,
    required List<List<MapUser>> clusters,
  }) {
    final markers = <Marker>[];
    final users = state.mapUsers;
    if (users.isEmpty) return markers;

    final scale = (zoom / 10.0).clamp(0.5, 1.2);

    for (final clusterUsers in clusters) {
      final rep = clusterUsers.first;
      final isCluster = clusterUsers.length > 1;

      // 커스텀 색상 적용 (기본은 티어색)
      final customColor = _parseHexColor(rep.towerColor);
      final tierColor = customColor ?? _towerTierColor(rep.tier);

      final rankLabel = rep.rank <= 3
          ? (rep.rank == 1 ? '🥇' : rep.rank == 2 ? '🥈' : '🥉')
          : '#${rep.rank}';
      // Build 239: 라벨 우선순위 = 사용자 ID (@username) → 타워명 (있으면 fallback).
      // 회원 식별이 최우선이라는 사용자 요청 반영.
      final hasUsername = rep.username != null && rep.username!.isNotEmpty;
      final displayLabel = hasUsername
          ? '@${rep.username}'
          : (rep.towerName?.isNotEmpty == true ? rep.towerName! : null);
      final labelText = displayLabel ?? '';
      final hasLabel = showLabels && labelText.isNotEmpty;

      // Build 239: 타워 형식 → 카운터 원형 아바타로 교체.
      // 회원 = 카운터 캐릭터, 타워 잔상 제거.
      final tierIdx = rep.tier.index;
      final hasAura = tierIdx >= 4; // Building 이상
      final hasParticles = tierIdx >= 6; // Skyscraper 이상
      final avatarSize = (44 * scale).roundToDouble();
      final auraExtra = hasAura ? 14.0 * scale : 0.0;
      final totalW = max(64.0, avatarSize + 24 + auraExtra * 2);
      final totalH =
          avatarSize + 36 * scale + (hasLabel ? 14.0 : 0.0) + auraExtra;
      // Build 252: 인물 이모지 매핑을 공통 helper (`personEmojiForId`) 로 통합.
      // 마커 / 인박스 카드 / 인포 시트 모두 동일 매핑 → 사용자 식별 시각 일관성.
      final centerEmoji = personEmojiForId(
        rep.id,
        isLandmark: rep.tier == TowerTier.landmark,
      );

      markers.add(
        Marker(
          point: ll.LatLng(rep.lat, rep.lng),
          width: totalW,
          height: totalH,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (isCluster) {
                _showOverlappingTowerPicker(context, clusterUsers, l10n);
              } else {
                _showMapTowerDetail(context, rep, null, l10n);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ── 카운터 원형 아바타 (Build 239) ──
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // 오라 글로우 (Building+)
                    if (hasAura)
                      Container(
                        width: avatarSize + 16 * scale,
                        height: avatarSize + 16 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: tierColor.withValues(
                                alpha: hasParticles ? 0.35 : 0.2,
                              ),
                              blurRadius: hasParticles ? 20 * scale : 12 * scale,
                              spreadRadius:
                                  hasParticles ? 4 * scale : 2 * scale,
                            ),
                            if (hasParticles)
                              BoxShadow(
                                color: tierColor.withValues(alpha: 0.12),
                                blurRadius: 36 * scale,
                                spreadRadius: 8 * scale,
                              ),
                          ],
                        ),
                      ),
                    // 외곽 링 (티어 색)
                    Container(
                      width: avatarSize + 6 * scale,
                      height: avatarSize + 6 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tierColor.withValues(alpha: 0.55),
                          width: 1.5,
                        ),
                      ),
                    ),
                    // 본체 원형 — 중앙 카운터/플래그
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgSurface,
                        border: Border.all(color: tierColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: tierColor.withValues(alpha: 0.25),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      // Build 415 (런타임 점검): emoji+flag 2줄 Column 이 고정 크기
                      //   아바타 원(avatarSize)을 ~2px 초과(RenderFlex overflow)하던
                      //   문제 — FittedBox(scaleDown)로 어떤 scale 에서도 원 안에 맞게
                      //   축소(필요할 때만, 확대는 안 함). 지도 줌아웃 시 다수 마커가
                      //   노란 overflow 줄무늬를 띄우던 표면 닫음.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              centerEmoji,
                              style: TextStyle(fontSize: 14 * scale),
                            ),
                            Text(
                              rep.flag,
                              style: TextStyle(fontSize: 12 * scale),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Build 246: Lv N 뱃지 제거 — 사용자 요청 (아이디만 노출).
                    // 레벨 정보는 마커 탭 시 인포 시트에서 확인 가능.
                    // ── 클러스터 뱃지 ──
                    if (isCluster)
                      Positioned(
                        top: -4 * scale,
                        right: -6 * scale,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4 * scale,
                            vertical: 1 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(8 * scale),
                            border: Border.all(color: AppColors.bgCard, width: 1.2),
                          ),
                          child: Text(
                            '${clusterUsers.length}',
                            style: TextStyle(
                              fontSize: 8 * scale,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // ── 랭킹 뱃지 ──
                Container(
                  margin: EdgeInsets.only(top: 1 * scale),
                  padding: EdgeInsets.symmetric(horizontal: 5 * scale, vertical: 1 * scale),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tierColor.withValues(alpha: 0.95),
                        tierColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    rankLabel,
                    style: TextStyle(
                      fontSize: 8 * scale,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                // ── 타워 이름 ──
                if (hasLabel)
                  Padding(
                    padding: EdgeInsets.only(top: 1 * scale),
                    child: Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 7.5 * scale,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return markers;
  }

  // ── 지붕 빌더 ──────────────────────────────────────────────────────────────
  // ignore: unused_element
  Widget _buildTowerRoof({
    required double width,
    required double height,
    required Color color,
    required int roofStyle,
    required double scale,
  }) {
    switch (roofStyle) {
      case 1: // 뾰족 지붕
        return CustomPaint(
          size: Size(width, height + 4 * scale),
          painter: _PointedRoofPainter(color: color),
        );
      case 2: // 돔 지붕
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.elliptical(width * 0.5, height),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.9),
                color.withValues(alpha: 0.4),
              ],
            ),
          ),
        );
      case 3: // 평지붕
        return Container(
          width: width,
          height: height * 0.5,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(2 * scale)),
          ),
        );
      case 4: // 안테나
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 2 * scale,
              height: 8 * scale,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Container(
              width: width,
              height: height * 0.5,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(3 * scale)),
              ),
            ),
          ],
        );
      default: // 기본 둥근 지붕
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(6 * scale)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.85),
                color.withValues(alpha: 0.45),
              ],
            ),
          ),
        );
    }
  }

  // ── 층 빌더 ────────────────────────────────────────────────────────────────
  // ignore: unused_element
  Widget _buildTowerFloor({
    required double width,
    required double height,
    required Color color,
    required double alpha,
    required bool isBottom,
    required double borderWidth,
    required int floorIndex,
    required int windowStyle,
    required double scale,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: alpha),
            AppColors.bgCard.withValues(alpha: 0.85),
          ],
        ),
        // Build 271: top BorderSide 추가 — 비대칭 border + borderRadius 경고
        // ("borderRadius can only be given on borders with uniform colors") 해소.
        border: Border(
          top: BorderSide(color: color.withValues(alpha: 0.45), width: borderWidth),
          left: BorderSide(color: color.withValues(alpha: 0.45), width: borderWidth),
          right: BorderSide(color: color.withValues(alpha: 0.45), width: borderWidth),
          bottom: BorderSide(color: color.withValues(alpha: 0.45), width: borderWidth),
        ),
        borderRadius: isBottom
            ? BorderRadius.vertical(bottom: Radius.circular(3 * scale))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildWindows(
          windowStyle: windowStyle,
          floorIndex: floorIndex,
          scale: scale,
        ),
      ),
    );
  }

  // ── 창문 빌더 ──────────────────────────────────────────────────────────────
  List<Widget> _buildWindows({
    required int windowStyle,
    required int floorIndex,
    required double scale,
  }) {
    final lit = (floorIndex * 7 + 3) % 3 != 0; // pseudo-random lit pattern
    final lit2 = (floorIndex * 5 + 1) % 3 != 0;
    final wSize = 3.0 * scale;

    Widget window(bool isLit) {
      final baseColor = isLit
          ? const Color(0xFFFFFFCC).withValues(alpha: 0.75)
          : const Color(0xFFFFFFCC).withValues(alpha: 0.15);
      switch (windowStyle) {
        case 1: // 원형 창문
          return Container(
            width: wSize,
            height: wSize,
            margin: EdgeInsets.symmetric(horizontal: 1.5 * scale),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: baseColor,
              boxShadow: isLit
                  ? [BoxShadow(color: baseColor.withValues(alpha: 0.5), blurRadius: 2 * scale)]
                  : [],
            ),
          );
        case 2: // 아치 창문
          return Container(
            width: wSize,
            height: wSize + 1 * scale,
            margin: EdgeInsets.symmetric(horizontal: 1.5 * scale),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(wSize * 0.5)),
              color: baseColor,
              boxShadow: isLit
                  ? [BoxShadow(color: baseColor.withValues(alpha: 0.5), blurRadius: 2 * scale)]
                  : [],
            ),
          );
        case 3: // 모던 (가로로 넓은 슬릿)
          return Container(
            width: wSize * 1.8,
            height: wSize * 0.6,
            margin: EdgeInsets.symmetric(horizontal: 1 * scale),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(0.5 * scale),
              color: baseColor,
              boxShadow: isLit
                  ? [BoxShadow(color: baseColor.withValues(alpha: 0.5), blurRadius: 2 * scale)]
                  : [],
            ),
          );
        default: // 사각 창문
          return Container(
            width: wSize,
            height: wSize,
            margin: EdgeInsets.symmetric(horizontal: 1.5 * scale),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(0.5 * scale),
              color: baseColor,
              boxShadow: isLit
                  ? [BoxShadow(color: baseColor.withValues(alpha: 0.5), blurRadius: 2 * scale)]
                  : [],
            ),
          );
      }
    }

    return [window(lit), window(lit2)];
  }

  // ── hex 색상 파싱 ──────────────────────────────────────────────────────────
  Color? _parseHexColor(String hex) {
    if (hex.isEmpty || hex == '#FFD700') return null; // 기본값이면 null → 티어색 사용
    try {
      final clean = hex.replaceFirst('#', '');
      if (clean.length == 6) return Color(int.parse('0xFF$clean'));
    } catch (_) {}
    return null;
  }

  Color _towerTierColor(TowerTier tier) {
    switch (tier) {
      case TowerTier.shack:
        return const Color(0xFF8B7355);
      case TowerTier.cottage:
        return const Color(0xFFCD7F32);
      case TowerTier.house:
        return const Color(0xFFC0C0C0);
      case TowerTier.townhouse:
        return const Color(0xFF90C878);
      case TowerTier.building:
        return AppColors.gold;
      case TowerTier.office:
        return AppColors.teal;
      case TowerTier.skyscraper:
        return const Color(0xFF60A5FA);
      case TowerTier.supertall:
        return const Color(0xFFAB78FF);
      case TowerTier.megatower:
        return const Color(0xFFFF9F43);
      case TowerTier.landmark:
        return AppColors.coupon;
    }
  }

  int _myTowerRank(AppState state) {
    final myFloors = state.currentUser.activityScore.towerFloors;
    final higherCount = state.mapUsers.where((u) => u.floors > myFloors).length;
    return higherCount + 1;
  }

  String _rankLabel(int rank, AppL10n l10n) {
    if (rank == 1) return '🥇 ${l10n.mapRankN(1)}';
    if (rank == 2) return '🥈 ${l10n.mapRankN(2)}';
    if (rank == 3) return '🥉 ${l10n.mapRankN(3)}';
    return '🌍 ${l10n.mapRankN(rank)}';
  }

  void _showMyTowerInfo(BuildContext ctx, AppState state, AppL10n l10n) {
    _showMapTowerDetail(ctx, null, state, l10n);
  }

  /// 타워 위치에 편지 마커가 겹쳤을 때 — 타워 보기 / 편지 선택 disambiguation
  void _showTowerLetterDisambiguation(
    BuildContext ctx,
    AppState state,
    List<Letter> letters,
    AppL10n l10n,
    String langCode,
  ) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              l10n.mapWhatsHere,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            // 내 타워 버튼
            _DisambiguationTile(
              icon: state.currentUser.activityScore.tier.emoji,
              title: l10n.mapMyTower,
              subtitle:
                  '${state.currentUser.activityScore.towerFloors}${l10n.mapFloorUnit} · ${state.currentUser.activityScore.tier.labelL(langCode)}',
              onTap: () {
                Navigator.pop(ctx);
                _showMyTowerInfo(ctx, state, l10n);
              },
            ),
            const SizedBox(height: 8),
            // 편지 목록
            ...letters.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DisambiguationTile(
                  // 브랜드 편지는 카테고리 맞춤 이모지 (할인권 🎟 / 교환권 🎁 / 일반 📪)
                  icon: l.senderIsBrand ? l.markerBrandEmoji : '📮',
                  title: '${l.senderCountryFlag} ${l10n.mapLetterFrom(CountryL10n.localizedName(l.senderCountry, langCode))}',
                  subtitle: l10n.mapReadCountTapToPickUp(l.readCount, l.maxReaders),
                  onTap: () {
                    Navigator.pop(ctx);
                    _onLetterTap(ctx, l, state, l10n, langCode);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 겹친 타워 선택 시트
  void _showOverlappingTowerPicker(
    BuildContext ctx,
    List<MapUser> towers,
    AppL10n l10n,
  ) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Container(
        margin: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 16),
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🏘️ ${l10n.mapNearbyTowers(towers.length)}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // Build 409 (sim P1.47): 큰 클러스터(타워 다수)에서 리스트가 화면을
            //   넘쳐 하단 행이 잘리던 문제 → 스크롤 가능 영역으로 감싸 높이 제한.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
            ...towers.map((u) {
              final tierColor = _towerTierColor(u.tier);
              final name = u.towerName?.isNotEmpty == true
                  ? u.towerName!
                  : (u.username?.isNotEmpty == true
                      ? '@${u.username}'
                      : '${u.flag} #${u.rank}');
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMapTowerDetail(ctx, u, null, l10n);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: tierColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Build 252: 공통 helper 로 통합 (마커와 동일 매핑)
                        Text(
                          personEmojiForId(
                            u.id,
                            isLandmark: u.tier == TowerTier.landmark,
                          ),
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          u.flag,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Build 246: 'SHACK · 1F' 옛 티어/층수 라벨 → 활동 레벨 (Lv N)
                              Text(
                                'Lv ${u.level}',
                                style: TextStyle(
                                  color: tierColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapTowerDetail(
    BuildContext ctx,
    MapUser? other,
    AppState? myState,
    AppL10n l10n,
  ) {
    // 데이터 추출 (다른 유저 or 내 타워)
    final flag = other?.flag ?? (myState?.currentUser.countryFlag ?? '🏠');
    final tier =
        other?.tier ??
        (myState?.currentUser.activityScore.tier ?? TowerTier.cottage);
    final floors =
        other?.floors ?? (myState?.currentUser.activityScore.towerFloors ?? 1);
    final rank = other?.rank ?? (myState != null ? _myTowerRank(myState) : 0);
    final username = other?.username ?? myState?.currentUser.username;
    final towerName = other?.towerName ?? myState?.currentUser.customTowerName;
    final tierColor = _towerTierColor(tier);
    final rankLabel = _rankLabel(rank, l10n);
    final towerH = (60 + floors * 4.0).clamp(60.0, 240.0);

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SingleChildScrollView(
        child: Container(
          margin: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 16),
          padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: tierColor.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // 국기 + 티어
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgSurface,
                      border: Border.all(color: tierColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: tierColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      // Build 252: 공통 helper 로 통합 — 인포 시트 이모지가 마커와 정확히 일치.
                      child: Text(
                        '${personEmojiForId(other?.id ?? "self", isLandmark: tier == TowerTier.landmark)} $flag',
                        style: const TextStyle(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Build 246: 티어 라벨 ('오두막'/'SHACK' 등) 제거 — 옛 타워 잔재
                        // 사용자 식별 우선 = @username 만 prominent 노출
                        if (username != null && username.isNotEmpty)
                          Text(
                            '@$username',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        if (towerName != null && towerName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.45),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.apartment_rounded,
                                  size: 13,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    towerName,
                                    style: const TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          other == null ? l10n.mapMyTower : l10n.mapCommunityTower,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // 세계 랭킹
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            rankLabel,
                            style: TextStyle(
                              color: rank <= 3
                                  ? AppColors.gold
                                  : AppColors.textSecondary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l10n.mapWorldRanking,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 활동 레벨 (Build 238: tower "F" 접미사 제거 — 카운터 정체성)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: tierColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Lv $floors',
                            style: TextStyle(
                              color: tierColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l10n.mapBuildingFloors,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 프로그레스바
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.bgSurface),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.mapTowerHeight,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${(towerH / 240.0 * 100).toInt()}%',
                          style: TextStyle(
                            color: tierColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: towerH / 240.0,
                        backgroundColor: AppColors.bgDeep,
                        valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bgSurface,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.mapClose),
                ),
              ),
            ],
          ),
        ), // Container
      ), // SingleChildScrollView
    );
  }

  void _onLetterTap(BuildContext ctx, Letter letter, AppState state, AppL10n l10n, String langCode) {
    // Build 239: `delivered` (도착 후 미열람) 도 픽업 다이얼로그로 라우팅.
    // 이전엔 `delivered` 가 `_showTransitInfo` 로 빠져 빈 시트처럼 보였음
    // (특히 데모 시드 쿠폰 — status=delivered 로 시작하므로 첫 tick 전엔
    // nearYou 로 승격되지 않아 사용자에게 "아무 반응 없음" 으로 인식됨).
    // 픽업 다이얼로그는 거리 검증 (`pickUpLetter`) 이 내장되어 너무 멀면
    // 에러 스낵바를 띄움.
    if (letter.status == DeliveryStatus.nearYou ||
        (letter.status == DeliveryStatus.delivered &&
            !letter.isReadByRecipient)) {
      _showPickupDialog(ctx, letter, state, l10n, langCode);
    } else if (letter.status == DeliveryStatus.deliveredFar) {
      _showDeliveredFarDialog(ctx, letter, l10n);
    } else {
      _showTransitInfo(ctx, letter, l10n);
    }
  }

  void _showDeliveredFarDialog(BuildContext ctx, Letter letter, AppL10n l10n) {
    // 브랜드 편지는 카테고리 맞춤 이모지로 도착 상태를 알림.
    // Build 223: Premium 발신 편지는 📣 (홍보) 로 직관 구분
    final arrivalEmoji = letter.senderIsBrand
        ? letter.markerBrandEmoji
        : letter.senderTier == LetterSenderTier.premium
            ? '📣'
            : '📬';
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          '$arrivalEmoji ${l10n.mapLetterArrivedVisitToOpen}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: Text(l10n.mapClose, style: const TextStyle(color: AppColors.bgDeep)),
          ),
        ],
      ),
    );
  }

  void _showPickupDialog(BuildContext ctx, Letter letter, AppState state, AppL10n l10n, String langCode) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PickupSheet(
        l10n: l10n,
        langCode: langCode,
        letter: letter,
        onPickup: () {
          // Build 324: 픽업 전 같은 캠페인의 다른 letter 수 미리 카운트.
          //   픽업 직후 nearbyLetters 필터로 사라지기 전에 차이로 hidden 카운트 계산.
          final preCampaignSiblings = (letter.brandUniquePerUser &&
                  letter.campaignId != null)
              ? state.worldLetters
                  .where((l) =>
                      l.id != letter.id &&
                      l.brandUniquePerUser &&
                      l.campaignId == letter.campaignId)
                  .length
              : 0;
          final error = state.pickUpLetter(letter.id);
          Navigator.pop(ctx);
          if (error == null) {
            // Build 415 (#5 레어 드롭): rare/epic 편지를 주웠으면 "발견" 축하
            //   토스트. campaign dedup 안내보다 우선 (더 강한 도파민 신호).
            if (letter.rarity.isSpecial) {
              final isEpic = letter.rarity == LetterRarity.epic;
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(
                    isEpic ? l10n.epicDropToast : l10n.rareDropToast,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  backgroundColor: isEpic
                      ? const Color(0xFF7C4DFF)
                      : const Color(0xFFB8860B),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
            // Build 324: brandUniquePerUser 캠페인 픽업 시 hidden 안내 스낵바.
            //   "왜 다른 letter 가 사라지지?" 의문 해소 (Premium 시뮬레이션 발견).
            if (preCampaignSiblings > 0) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(l10n.pickupCampaignDedupNotice(
                    preCampaignSiblings,
                  )),
                  backgroundColor: AppColors.bgCard,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            // Build 261: 픽업 직후 LetterReadScreen 즉시 push.
            // 이전: snackbar 만 → 사용자가 인박스로 이동해 다시 탭해야 했음.
            // 변경: 즉시 detail 화면 → 그 후 인박스/수집첩에서도 다시 확인 가능.
            // pickUpLetter 가 inbox 에 letter 추가했으므로 인박스 진입 시 자동 표시.
            final pickedLetter = state.inbox.firstWhere(
              (l) => l.id == letter.id,
              orElse: () => letter,
            );
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => LetterReadScreen(
                  letter: pickedLetter,
                  userLanguageCode: langCode,
                ),
              ),
            );
            // Build 115: 생애 첫 픽업이면 축하 모달을 띄운다. 포스트프레임으로
            // 밀어 snackbar 애니메이션과 겹치지 않게 한다. 한번 소진하면
            // SharedPreferences 에 저장되어 다시 뜨지 않음.
            if (state.shouldCelebrateFirstPickup) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!ctx.mounted) return;
                _showFirstPickupCelebration(ctx, l10n);
                state.acknowledgeFirstPickup();
              });
            }
            // Build 120: 마일스톤 레벨(2/5/10/25/50) 에 도달했다면 별도 축하
            // 모달. 픽업으로 XP 쌓다가 터졌을 가능성이 크므로 여기서 폴링.
            final milestone = state.pendingMilestoneLevel;
            if (milestone != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!ctx.mounted) return;
                _showMilestoneCelebration(ctx, l10n, milestone, state);
                state.acknowledgeMilestone();
              });
            }
          } else {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red.shade900,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  /// Build 115: 첫 픽업 축하 다이얼로그 — 3단 개봉 애니·햅틱에 이어
  /// 사용자에게 "이게 루프다" 를 알려주는 한 번뿐의 모먼트. 소진되면
  /// `acknowledgeFirstPickup` 으로 영구 비활성.
  void _showFirstPickupCelebration(BuildContext ctx, AppL10n l10n) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('🗺', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 14),
            Text(
              l10n.firstPickupCelebrationTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.firstPickupCelebrationBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 26,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              l10n.firstPickupCelebrationCta,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build 120: 레벨 마일스톤(2/5/10/25/50) 축하 모달. 반경이 얼마나
  /// 넓어졌는지 본문에서 강조해 "레벨업의 의미 = 픽업 범위 확대" 연결고리
  /// 를 계속 상기시킨다. `acknowledgeMilestone()` 으로 소진.
  void _showMilestoneCelebration(
    BuildContext ctx,
    AppL10n l10n,
    int level,
    AppState state,
  ) {
    final radius = state.pickupRadiusMeters.round();
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              l10n.milestoneLevelTitle(level),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.milestoneLevelBody(radius),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 26,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              l10n.milestoneLevelCta,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTransitInfo(BuildContext ctx, Letter letter, AppL10n l10n) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TransitInfoSheet(l10n: l10n, letter: letter),
    );
  }

  String _todayKey(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  /// Build 120: 나침반 힌트 — 내 위치에서 가장 가까운 "줍을 수 있는" 편지
  /// (nearYou / deliveredFar / 이동 중 또는 도착 후 미오픈) 의 거리와 방향을
  /// 찾아 `(미터, 방향 화살표 이모지, 카테고리 이모지)` 로 반환.
  /// 반경 내에 이미 있는 경우는 호출측에서 제외 — 반경 밖 가장 가까운 것을
  /// 찾는 것이 목적.
  /// Build 141: 반환형을 `(letter, distance, arrow, emoji)` 로 확장 —
  /// 배너 onTap 에서 해당 편지 위치로 지도 이동 가능하도록.
  ({Letter letter, int distance, String arrow, String emoji})?
      _nearestLetterCompass(AppState state) {
    final myLat = state.currentUser.latitude;
    final myLng = state.currentUser.longitude;
    final me = LatLng(myLat, myLng);
    final radius = state.pickupRadiusMeters;

    Letter? nearest;
    double nearestDist = double.infinity;
    for (final l in state.worldLetters) {
      final status = l.status;
      if (status != DeliveryStatus.nearYou &&
          status != DeliveryStatus.deliveredFar &&
          status != DeliveryStatus.inTransit &&
          !(status == DeliveryStatus.delivered && !l.isReadByRecipient)) {
        continue;
      }
      // Build 421 (sim-fresh P2): 마커 빌드/nearbyLetters 와 동일한 소진 가드 —
      //   이전엔 만료/소진/차단 쿠폰을 나침반이 가리켜 죽은 안내가 떴음.
      if (_isLetterConsumed(l)) continue;
      final d = l.destinationLocation.distanceTo(me);
      if (d < radius) continue; // 반경 안에 있으면 이미 줍기 가능 — 스킵
      if (d < nearestDist) {
        nearestDist = d;
        nearest = l;
      }
    }
    if (nearest == null || nearestDist == double.infinity) return null;

    // Bearing 계산 (Haversine)
    final lat1 = myLat * pi / 180;
    final lat2 = nearest.destinationLocation.latitude * pi / 180;
    final dLng = (nearest.destinationLocation.longitude - myLng) * pi / 180;
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    final bearing = (atan2(y, x) * 180 / pi + 360) % 360;

    // 8 방향 화살표 매핑 (0 = 북 = ↑, 45 = 북동 = ↗, ...)
    const arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
    final idx = ((bearing + 22.5) / 45).floor() % 8;

    // 카테고리 이모지 (브랜드 편지만 맞춤, 아니면 📬)
    final catEmoji = nearest.senderIsBrand
        ? nearest.markerBrandEmoji
        : '📬';

    return (
      letter: nearest,
      distance: nearestDist.round(),
      arrow: arrows[idx],
      emoji: catEmoji,
    );
  }

  // Build 414 (#3 아하모먼트): 첫 지도 진입 시 1회 줍기 유도 coachmark.
  //   가입 후 _maybePlaceTutorialLetter 가 반경 내 튜토리얼 쿠폰을 깔아두므로,
  //   신규 사용자(아직 픽업 0)에게 "탭해서 주워보세요"를 가볍게 안내 → 핵심
  //   가치(줍기)를 60초 내 체감하게. 1회만(prefs flag).
  Future<void> _maybeShowFirstPickupCoachmark(AppState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('map_first_pickup_hint_v1') == true) return;
      await prefs.setBool('map_first_pickup_hint_v1', true);
      // 이미 줍기 경험이 있으면(인박스 보유) 안내 불필요.
      if (state.inbox.isNotEmpty) return;
      // 지도·쿠폰이 그려질 시간을 약간 준 뒤 노출.
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      AppSnack.hint(
        context,
        AppL10n.of(state.currentUser.languageCode).mapFirstPickupHint,
      );
    } catch (_) {/* best-effort 안내 */}
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    final denied = permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever;
    if (mounted && denied != _locationPermissionDenied) {
      setState(() => _locationPermissionDenied = denied);
    }
    // Build 414 (sim100 #2): 신규 가입자가 (0,0) 으로 남아 줍기/지도가 전면
    //   불가하던 회귀 해소. 권한 허용 상태인데 좌표가 (0,0) 이면 즉시 1회 GPS
    //   취득 후 반영 (best-effort — 실패 시 (0,0) 유지, 기존 fallback 동작).
    if (!denied && mounted) {
      final state = context.read<AppState>();
      final u = state.currentUser;
      if (u.latitude == 0.0 && u.longitude == 0.0) {
        try {
          if (await Geolocator.isLocationServiceEnabled()) {
            final rawPos = await Geolocator.getCurrentPosition(
              locationSettings:
                  const LocationSettings(accuracy: LocationAccuracy.high),
            ).timeout(const Duration(seconds: 8));
            final pos = SecureLocation.guard(rawPos);
            if (pos != null && mounted) {
              state.updateUserLocation(pos.latitude, pos.longitude);
            }
          }
        } catch (_) {/* 권한 거부/타임아웃 등 — 무시 */}
      }
    }
    if (permission != LocationPermission.deniedForever) return;
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey(DateTime.now());
    if (prefs.getString(_permissionDialogDateKey) == todayKey) return;
    await prefs.setString(_permissionDialogDateKey, todayKey);
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bgDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '📍 ${l10n.mapLocationPermissionNeeded}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            l10n.mapLocationPermissionDesc,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.mapLater, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC9A84C),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Geolocator.openAppSettings();
              },
              child: Text(
                l10n.mapOpenSettings,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _MapQuickActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  // Build 457: 활성 상태 강조 (관심 필터 ON) — gold 톤.
  final bool highlighted;

  const _MapQuickActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeColors = AppTimeColors.of(context);
    final accent = highlighted ? AppColors.gold : timeColors.accent;
    // Build 161: Tooltip 은 이미 mouse-hover 라벨 제공, Semantics 는 터치
    // 접근성 (스크린리더) 전용. 동일 텍스트 재사용.
    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.bgCard.withValues(alpha: 0.96),
                    timeColors.bgSurface.withValues(alpha: 0.9),
                  ],
                ),
                border: Border.all(
                  color: accent.withValues(alpha: highlighted ? 0.8 : 0.42),
                  width: highlighted ? 1.6 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 내 위치 버튼 ───────────────────────────────────────────────────────────────
class _MyLocationButton extends StatefulWidget {
  final MapController mapController;
  final void Function(double lat, double lng) onLocationUpdated;
  const _MyLocationButton({
    required this.mapController,
    required this.onLocationUpdated,
  });
  @override
  State<_MyLocationButton> createState() => _MyLocationButtonState();
}

class _MyLocationButtonState extends State<_MyLocationButton> {
  bool _loading = false;

  Future<void> _goToMyLocation(BuildContext context) async {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    setState(() => _loading = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (context.mounted) {
          // Build 253: deniedForever 시 설정으로 이동 안내 액션 추가.
          // 시스템이 더 이상 권한 프롬프트 안 띄우므로 사용자가 직접 설정에서
          // 변경해야 함 → SnackBar action 으로 openAppSettings 트리거.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.mapLocationPermissionRequired),
              backgroundColor: AppColors.bgSurface,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
              action: permission == LocationPermission.deniedForever
                  ? SnackBarAction(
                      label: l10n.openSettings,
                      textColor: AppColors.gold,
                      onPressed: () => Geolocator.openAppSettings(),
                    )
                  : null,
            ),
          );
        }
        return;
      }
      // Build 371 (PR-CC5 P0 #21): GPS service-disabled 검사 — iOS 설정→
      //   개인정보보호→위치서비스 OFF 케이스. 이전엔 silent catch 로 swallow
      //   되어 사용자가 "왜 안 되지?" 혼란. SnackBar 로 명시 안내.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.gpsAccuracyLow)),
          );
        }
        return;
      }
      final rawPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 8));
      // Build 370 (PR-CC4 P0 #9): GPS spoofing 가드.
      final pos = SecureLocation.guard(rawPos);
      if (pos == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.gpsAccuracyLow)),
          );
        }
        return;
      }
      widget.onLocationUpdated(pos.latitude, pos.longitude);
      widget.mapController.move(ll.LatLng(pos.latitude, pos.longitude), 14.0);
      // Build 253: iOS Approximate Location 감지 — accuracy 가 500m 초과면
      // 픽업 정밀도 충분치 않음. 사용자에게 정확한 위치 활성화 안내.
      if (context.mounted && pos.accuracy > 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.gpsAccuracyLow),
            backgroundColor: AppColors.warning.withValues(alpha: 0.92),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: l10n.openSettings,
              textColor: Colors.white,
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mapCannotGetLocation),
            backgroundColor: AppColors.bgSurface,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeColors = AppTimeColors.of(context);
    // Build 423 (sim-crosscut P2): a11y — 아이콘 전용 버튼 라벨.
    final lang = context.read<AppState>().currentUser.languageCode;
    return Semantics(
      button: true,
      label: AppL10n.of(lang).koEn('내 위치로 이동', 'Go to my location'),
      child: GestureDetector(
      onTap: () => _goToMyLocation(context),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgCard.withValues(alpha: 0.96),
              timeColors.bgSurface.withValues(alpha: 0.9),
            ],
          ),
          border: Border.all(
            color: AppColors.teal.withValues(alpha: 0.42),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _loading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.teal,
                    strokeWidth: 2,
                  ),
                ),
              )
            : const Icon(
                Icons.my_location_rounded,
                color: AppColors.teal,
                size: 22,
              ),
      ),
    ),
    );
  }
}

// ── 운송수단 마커 ──────────────────────────────────────────────────────────────
/// 도착 대기 중 마커 (inTransit → 실제 도착했지만 아직 상태 전환 전)
/// 비행기 대신 📬로 표시
// ── Build 491 (프라이스태그 마커): 브랜드 딜 마커 공용 태그 pill ────────────
// "동네 세일이 길에 떨어져 있다" 정체성 — 구멍 뚫린 가격표 모양.
// 일반 홍보(priceTagLabel==null)는 기존 이모지 마커 유지(세일 위장 금지).
class _PriceTagPill extends StatelessWidget {
  final String label;
  final bool mystery;
  final double pulse;
  final double height;
  const _PriceTagPill({
    required this.label,
    required this.mystery,
    required this.pulse,
    this.height = 26,
  });

  @override
  Widget build(BuildContext context) {
    final bg = mystery ? HuntPalette.ink : HuntPalette.lime;
    final fg = mystery ? HuntPalette.lav : HuntPalette.limeInk;
    return Container(
      height: height,
      padding: const EdgeInsetsDirectional.only(start: 7, end: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(height / 2),
          bottomLeft: Radius.circular(height / 2),
          topRight: const Radius.circular(7),
          bottomRight: const Radius.circular(7),
        ),
        border: mystery
            ? Border.all(color: HuntPalette.lav, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: (mystery ? HuntPalette.lav : HuntPalette.lime)
                .withValues(alpha: 0.35 + pulse * 0.25),
            blurRadius: 10,
          ),
          const BoxShadow(
            color: Color(0x66000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 태그 구멍.
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: mystery ? HuntPalette.lav : HuntPalette.ink,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: height * 0.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrivedWaitingMarker extends StatelessWidget {
  final Letter letter;
  final AnimationController pulseController;
  const _ArrivedWaitingMarker({
    required this.letter,
    required this.pulseController,
  });

  // Build 324 (positioning): 카테고리별 이모지 분기.
  //   사용자 피드백 — 색깔 분기보다 이모지가 즉시 인식 가능. 색은 gold 로
  //   통일해 시각 노이즈 감소 + 이모지가 카테고리 시그널의 단일 채널이 됨.
  //   eat (food+cafe) = 🍴 / shop (beauty+fashion) = 🛍️ /
  //   etc (it+event+other) = 🎁 / categoryTag null = 📬 (기본).
  //   FOMO 시 빨강 ring 은 별개 — 긴급성 시각화는 유지.
  // Build 433 (device): 업종 카테고리별 도착 이모지 — 공유 헬퍼(bizCategoryEmoji)
  //   로 카페☕/음식🍔/뷰티💄/패션👗/행사🎉/기타🎁 구분. categoryTag null 이면
  //   📬(일반 편지).
  String get _categoryEmoji {
    final tag = letter.categoryTag;
    if (tag == null) return '📬';
    return bizCategoryEmoji(tag);
  }

  /// Build 415 (#5 레어 드롭): 희귀도별 글로우 색. normal 은 null (강조 없음).
  ///   epic = 보라, rare = 밝은 골드. 마커에 글로우 ring + 배지로 시각 구분.
  Color? get _rarityColor {
    switch (letter.rarity) {
      case LetterRarity.epic:
        return const Color(0xFF7C4DFF);
      case LetterRarity.rare:
        return const Color(0xFFFFD54F);
      case LetterRarity.normal:
        return null;
    }
  }

  /// Build 324 (FOMO): 만료 임박 (≤24h) 여부.
  ///   redemptionExpiresAt (쿠폰 사용 기한) 또는 expiresAt (편지 자동 삭제)
  ///   중 더 빠른 시각 기준. 24h 이내면 핀이 깜빡임 강화 + 빨간 ring 으로 시각화.
  bool get _isExpiringSoon {
    final coupon = letter.redemptionExpiresAt;
    final auto = letter.expiresAt;
    DateTime? earliest;
    if (coupon != null && auto != null) {
      earliest = coupon.isBefore(auto) ? coupon : auto;
    } else {
      earliest = coupon ?? auto;
    }
    if (earliest == null) return false;
    final remain = earliest.difference(DateTime.now());
    return !remain.isNegative && remain.inHours <= 24;
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _categoryEmoji;
    final expiringSoon = _isExpiringSoon;
    // Build 324: 핀 색상은 gold 로 통일. 카테고리 구분은 이모지 단일 채널.
    //   FOMO 모드 (≤24h) 시에만 빨강 outer ring + pulse 2배로 긴급성 시각화.
    //   사이즈 +35% (22→30 emoji, 40→54 container) — 시뮬레이션에서 줌아웃 시
    //   카테고리 이모지가 안 보이던 문제 해소. 줌인 시도 비례 자연스러움 유지.
    //   본인 sender letter 는 청록 dashed border 로 구분 — Brand 사장이 자기
    //   캠페인 letter 를 지도에서 즉시 식별 가능 (시뮬레이션 발견).
    // Build 324 (Q3 - UI/UX audit fix): ring 우선순위 단일화로 첫 인상 noise
    //   감소. 3색 동시 발화 (본인 청록 + FOMO 빨강 + gold pulse) → 사용자 시야
    //   noise. 우선순위 = FOMO > 본인 > 일반. 한 번에 1 ring 만 발화.
    final state = context.read<AppState>();
    final isMine = letter.senderId == state.currentUser.id;
    final fomoColor = expiringSoon ? const Color(0xFFE53935) : null;
    // Build 415 (#5 레어 드롭): rare/epic 글로우. FOMO(만료임박) 가 더 강한 행동
    //   신호라 빨강 ring 우선 — rare 글로우는 FOMO 아닐 때만 발화 (noise 억제).
    final rarityColor = _rarityColor;
    final rarityBadge = letter.rarity.badge;
    final showRarity = rarityColor != null && !expiringSoon;
    final baseColor = showRarity ? rarityColor : AppColors.gold;
    final showMineRing = isMine && !expiringSoon && !showRarity; // FOMO·레어 우선
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final speed = expiringSoon ? 2.0 : 1.0;
        final phase = (pulseController.value * 2 * pi * speed) % (2 * pi);
        final pulse = (sin(phase) * 0.5 + 0.5);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Build 415 (#5): rare/epic 글로우 ring — 희귀도 색으로 마커를 감싼다.
            if (showRarity)
              Container(
                width: 68 + pulse * 8,
                height: 68 + pulse * 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: baseColor.withValues(alpha: 0.5 + pulse * 0.4),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.35 + pulse * 0.3),
                      blurRadius: 16 + pulse * 8,
                    ),
                  ],
                ),
              ),
            // Build 324: 본인 sender ring — FOMO 가 아닐 때만 노출 (Q3 audit:
            //   동시발화 차단). FOMO 가 더 강한 사용자 행동 신호 → 우선.
            if (showMineRing)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.85),
                    width: 2.5,
                  ),
                ),
              ),
            // FOMO outer ring (빨강) — 만료 임박일 때만 노출.
            //   Build 324 (Q3): pulse 진폭 14→6 으로 줄임 (UX audit).
            if (fomoColor != null)
              Container(
                width: 64 + pulse * 6,
                height: 64 + pulse * 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: fomoColor.withValues(alpha: 0.4 + pulse * 0.5),
                    width: 2.0,
                  ),
                ),
              ),
            Container(
              width: 54 + pulse * 4,
              height: 54 + pulse * 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (fomoColor ?? baseColor)
                      .withValues(alpha: 0.25 + pulse * 0.35),
                  width: 1.5,
                ),
              ),
            ),
            // Build 491: 브랜드 딜은 프라이스태그 pill, 그 외/일반 홍보는
            // 기존 카테고리 이모지 유지.
            if (letter.senderIsBrand && letter.priceTagLabel != null)
              _PriceTagPill(
                label: letter.priceTagLabel!,
                mystery: letter.isMystery,
                pulse: pulse,
                height: 28,
              )
            else
              Text(
                emoji,
                style: TextStyle(
                  fontSize: 30,
                  shadows: [
                    Shadow(
                      color: (fomoColor ?? baseColor)
                          .withValues(alpha: 0.6 + pulse * 0.3),
                      blurRadius: 12,
                    ),
                    const Shadow(
                      color: Color(0x88000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            // Build 415 (#5, sim50 P2): rare/epic 배지 — 우상단 ✨/💎.
            //   만료 임박(FOMO)으로 glow ring 이 빨강 우선되어도 배지는 항상 노출
            //   (희소성 신호 소실 방지). 배지 색은 항상 희귀도 색.
            if (rarityColor != null && rarityBadge.isNotEmpty)
              Positioned(
                top: -2,
                right: 4,
                child: Text(
                  rarityBadge,
                  style: TextStyle(
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        color: rarityColor.withValues(alpha: 0.9),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TransportMarker extends StatelessWidget {
  final Letter letter;
  final AnimationController pulseController;
  const _TransportMarker({required this.letter, required this.pulseController});

  double _bearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final dLng = (to.longitude - from.longitude) * pi / 180;
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    return atan2(y, x);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final isNearby = letter.status == DeliveryStatus.nearYou;
        final isDeliveredFar = letter.status == DeliveryStatus.deliveredFar;
        final phase = (pulseController.value * 2 * pi) % (2 * pi);
        final pulse = (sin(phase) * 0.5 + 0.5);
        // 유저가 고른 이모티콘 — "|" 구분 포맷(land|air|sea) 파싱
        // 현재 운송수단 카테고리에 선택된 이모티콘만 사용, 없으면 기본 이모티콘
        String resolvedEmoji() {
          final raw = letter.deliveryEmoji;
          if (raw == null || raw.isEmpty) return letter.currentTransport.emoji;
          final parts = raw.split('|');
          if (parts.length == 3) {
            final categoryIndex = letter.currentTransport == TransportMode.truck
                ? 0
                : letter.currentTransport == TransportMode.airplane
                ? 1
                : 2;
            final e = parts[categoryIndex];
            // 해당 카테고리 선택값 사용, 없으면 기본 운송수단 이모티콘
            if (e.isNotEmpty) return e;
            return letter.currentTransport.emoji;
          }
          // 레거시 단일 이모티콘 포맷 호환
          return raw.isNotEmpty ? raw : letter.currentTransport.emoji;
        }

        // nearYou: 📩 (브랜드는 카테고리 맞춤), deliveredFar: 📬 (브랜드는 카테고리
        // 맞춤), inTransit: 운송수단 이모티콘
        final isBrandArrival = letter.senderIsBrand && (isNearby || isDeliveredFar);
        final emoji = isBrandArrival
            ? letter.markerBrandEmoji
            : isNearby
            ? '📩'
            : isDeliveredFar
            ? '📬'
            : resolvedEmoji();
        final color = (isNearby || isDeliveredFar)
            ? AppColors.gold
            : letter.currentTransport == TransportMode.truck
            ? AppColors.gold
            : letter.currentTransport == TransportMode.airplane
            ? AppColors.teal
            : const Color(0xFF60A5FA);
        final seg = letter.currentSegment;
        final bearing = _bearing(seg.from, seg.to);
        // 도착한 편지(nearYou/deliveredFar)는 회전 없음
        final rotationAngle = (isNearby || isDeliveredFar)
            ? 0.0
            : bearing - letter.currentTransport.headingOffsetRadians;

        // 브랜드 특송 여부
        final isBrandExpress = letter.letterType == LetterType.brandExpress;

        // 등급별 색상 오버라이드 (특송은 금색 강조)
        final tierGlowColor = isBrandExpress
            ? AppColors.gold
            : letter.senderTier == LetterSenderTier.brand
            ? AppColors.coupon
            : letter.senderTier == LetterSenderTier.premium
            ? AppColors.gold
            : color;
        final tierFontSize = isNearby
            ? 22.0
            : isBrandExpress
            ? 24.0
            : letter.senderTier == LetterSenderTier.brand
            ? 22.0
            : letter.senderTier == LetterSenderTier.premium
            ? 20.0
            : 18.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            // nearYou / deliveredFar 상태: 맥동 링 표시
            if (isNearby || isDeliveredFar)
              Container(
                width: 40 + pulse * 8,
                height: 40 + pulse * 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: tierGlowColor.withValues(alpha: 0.25 + pulse * 0.35),
                    width: 1.5,
                  ),
                ),
              ),
            // 프리미엄/브랜드 배경 글로우
            if (!isNearby && letter.senderTier != LetterSenderTier.free)
              Container(
                width: tierFontSize + 10,
                height: tierFontSize + 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tierGlowColor.withValues(alpha: 0.08 + pulse * 0.06),
                  border: Border.all(
                    color: tierGlowColor.withValues(alpha: 0.25 + pulse * 0.2),
                    width: 1.0,
                  ),
                ),
              ),
            // 이모티콘
            Transform.rotate(
              angle: rotationAngle,
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: tierFontSize,
                  shadows: [
                    Shadow(
                      color: tierGlowColor.withValues(
                        alpha: isNearby ? 0.6 + pulse * 0.3 : 0.4 + pulse * 0.2,
                      ),
                      blurRadius: letter.senderTier != LetterSenderTier.free
                          ? (isNearby ? 12 : 8)
                          : (isNearby ? 10 : 6),
                    ),
                    const Shadow(
                      color: Color(0x88000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            // 브랜드 특송 ⚡ 배지 (일반 브랜드 배지보다 우선)
            if (isBrandExpress && !isNearby)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black38, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('⚡', style: TextStyle(fontSize: 8)),
                  ),
                ),
              ),
            // 브랜드 배지 (특송이 아닌 일반 브랜드)
            if (letter.senderTier == LetterSenderTier.brand &&
                !isBrandExpress &&
                !isNearby)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.coupon,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26, width: 0.5),
                  ),
                ),
              ),
            // 프리미엄 배지
            if (letter.senderTier == LetterSenderTier.premium && !isNearby)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26, width: 0.5),
                  ),
                ),
              ),
            // nearYou 편지: 읽기 인원 카운터 (좌상단, 1명이라도 읽었으면 표시)
            if (isNearby && letter.readCount > 0)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '${letter.readCount}/${letter.maxReaders}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── 도착 후 미열람 / nearYou 편지 마커 ──────────────────────────────────────────
class _UnreadDeliveredMarker extends StatelessWidget {
  final Letter letter;
  final AnimationController pulseController;

  /// 지도를 보는 유저가 프리미엄/브랜드 회원인지 여부
  /// true  → 브랜드 편지: 📪 + 발신자 ID 표시
  /// false → 브랜드 편지: 💌 (프리미엄과 동일하게 표시)
  final bool viewerIsPremiumOrBrand;

  /// Build 164: 유저 GPS 기준 가장 가까운 편지 여부.
  /// true 면 상단에 "가장 가까운" 라벨 + gold halo 추가.
  final bool isNearest;
  final String nearestLabel;

  const _UnreadDeliveredMarker({
    required this.letter,
    required this.pulseController,
    this.viewerIsPremiumOrBrand = false,
    this.isNearest = false,
    this.nearestLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    // Build 304 (a11y): 마커가 도착한 편지임을 스크린리더에 알린다.
    final tierLabel = letter.senderTier == LetterSenderTier.brand
        ? 'Brand'
        : letter.senderTier == LetterSenderTier.premium
            ? 'Premium'
            : 'Letter';
    return Semantics(
      label: isNearest
          ? '$tierLabel, ${nearestLabel.isEmpty ? 'nearest' : nearestLabel}'
          : tierLabel,
      child: AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final phase = (pulseController.value * 2 * pi) % (2 * pi);
        final pulse = (sin(phase) * 0.5 + 0.5);

        final isBrandSender = letter.senderTier == LetterSenderTier.brand;
        final isPremiumSender = letter.senderTier == LetterSenderTier.premium;

        // 프리미엄/브랜드 뷰어에게만 브랜드 편지 구분 표시
        // 무료 뷰어에게는 브랜드 편지도 💌 (프리미엄과 동일)
        final showAsBrand = isBrandSender && viewerIsPremiumOrBrand;
        final showAsPremium =
            isPremiumSender || (isBrandSender && !viewerIsPremiumOrBrand);

        // 등급별 글로우 색상 (외곽 pulse 링)
        final glowColor = showAsBrand
            ? AppColors.coupon
            : showAsPremium
            ? AppColors.gold
            : Colors.white;

        // Build 147: 카테고리별 내부 테두리 색 — 외곽 tier glow 유지하면서
        // 내부 링이 카테고리를 시각화. 🎟 할인권=teal, 🎁 교환권=coral.
        //   브랜드 general / 비브랜드: tier glow 색 그대로.
        // 이중 링 구조로 "이 편지가 누구 거 (tier)" + "무엇 (category)" 동시 식별.
        final isCoupon =
            showAsBrand && letter.category == LetterCategory.coupon;
        final isVoucher =
            showAsBrand && letter.category == LetterCategory.voucher;
        final innerBorderColor = isCoupon
            ? AppColors.teal
            : isVoucher
                ? AppColors.coupon
                : glowColor;

        // 편지함 컨테이너 배경색
        final boxBg = showAsBrand
            ? const Color(0xFF3A1F10).withValues(alpha: 0.95)
            : showAsPremium
            ? const Color(0xFF2A2108).withValues(alpha: 0.95)
            : AppColors.bgCard.withValues(alpha: 0.92);

        // 이모지: 브랜드(프리미엄 뷰어)=카테고리 맞춤(🎟/🎁/📪),
        //         프리미엄/브랜드(무료뷰어)=💌, 일반=📮
        final mailEmoji = showAsBrand
            ? letter.markerBrandEmoji
            : showAsPremium
            ? '💌'
            : '📮';

        // Build 415 (#5 레어 드롭, sim50 P1): 실제 픽업 가능한 마커에도 희귀도
        //   글로우+배지. 이전엔 _ArrivedWaitingMarker(도착 직전 과도기)만 글로우가
        //   있어, 정작 줍는 delivered/nearYou 마커에선 FOMO 신호가 사라졌음.
        //   링/글로우 색만 recolor(레이아웃 불변) + 우상단 ✨/💎 배지(Positioned).
        final rarityColor = letter.rarity == LetterRarity.epic
            ? const Color(0xFF7C4DFF)
            : letter.rarity == LetterRarity.rare
                ? const Color(0xFFFFD54F)
                : null;
        final rarityBadge = letter.rarity.badge;
        // tier glow 보다 희귀도 색을 우선(특별함 강조). normal 은 기존 색 유지.
        final ringColor = rarityColor ?? glowColor;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Build 164: "가장 가까운" 라벨 — 최단 편지에만 마커 상단 표시.
            if (isNearest) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  '📍 $nearestLabel',
                  style: AppText.caption.copyWith(
                    color: AppColors.bgDeep,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 2),
            ],
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Build 164: 최단 편지 전용 추가 halo (gold)
                // Build 476 (마커 다듬기): 마커 크기 상향에 맞춰 halo 48 로.
                if (isNearest)
                  Container(
                    width: 48 + pulse * 8,
                    height: 48 + pulse * 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withValues(
                          alpha: 0.3 + pulse * 0.35,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                // 맥동 링 — Build 415: rare/epic 이면 희귀도 색으로 글로우.
                // Build 476 (마커 다듬기): 외곽 tier/희귀도 펄스링 36 으로.
                Container(
                  width: 36 + pulse * 6,
                  height: 36 + pulse * 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ringColor.withValues(alpha: 0.2 + pulse * 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
                // 편지함 아이콘 컨테이너 (Build 147: 내부 테두리 = 카테고리 색)
                // Build 476 (마커 다듬기): 30→34, 이모지 가독성·터치 시인성 상향.
                // Build 491: 브랜드 딜(할인/교환/밀봉)은 프라이스태그 pill —
                //   "떨어진 가격표" 정체성. 일반 홍보·비브랜드는 기존 원형 유지.
                if (showAsBrand && letter.priceTagLabel != null)
                  _PriceTagPill(
                    label: letter.priceTagLabel!,
                    mystery: letter.isMystery,
                    pulse: pulse,
                    height: 24,
                  )
                else
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: boxBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: innerBorderColor.withValues(
                          alpha: 0.55 + pulse * 0.3,
                        ),
                        width: showAsBrand ? 2.0 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(
                            alpha: showAsBrand
                                ? 0.35 + pulse * 0.2
                                : 0.25 + pulse * 0.15,
                          ),
                          blurRadius: showAsBrand ? 10 : 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        mailEmoji,
                        // Build 476 (마커 다듬기): 14→16 — 카테고리 이모지 가독성.
                        style: TextStyle(
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              color: ringColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Build 415 (#5 레어 드롭, sim50 P1): rare/epic 배지(✨/💎).
                //   Positioned 라 Column 높이에 영향 없음(오버플로우 무관).
                if (rarityColor != null && rarityBadge.isNotEmpty)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Text(
                      rarityBadge,
                      // Build 476 (마커 다듬기): 13→14, 마커 확대에 맞춰 배지도.
                      style: TextStyle(
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            color: rarityColor.withValues(alpha: 0.9),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // 브랜드 편지 + 프리미엄/브랜드 뷰어: 발신자 ID 표시
            if (showAsBrand && letter.senderName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A1F10).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.coupon.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  letter.senderName,
                  style: const TextStyle(
                    color: AppColors.coupon,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        );
      },
    ),
    );
  }
}

/// Build 152: 지도 상단 시간대별 인사 + 근처 편지 카운트 pill.
/// `nearbyLetters.isNotEmpty` 일 때만 표시 — 반경 안에 진짜 줍을 게 있어야
/// 동기화된 호출. 탭하면 근처 필터 on + 줌 14 로 이동.
class _DailyGreetingPill extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _DailyGreetingPill({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final langCode = context.read<AppState>().currentUser.languageCode;
    final l10n = AppL10n.of(langCode);
    final hour = DateTime.now().hour;
    String emoji;
    String greeting;
    if (hour >= 5 && hour < 12) {
      emoji = '🌅';
      greeting = l10n.dailyGreetingMorning;
    } else if (hour >= 12 && hour < 18) {
      emoji = '☀️';
      greeting = l10n.dailyGreetingAfternoon;
    } else if (hour >= 18 && hour < 22) {
      emoji = '🌇';
      greeting = l10n.dailyGreetingEvening;
    } else {
      emoji = '🌙';
      greeting = l10n.dailyGreetingNight;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.teal.withValues(alpha: 0.22),
              AppColors.teal.withValues(alpha: 0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.teal.withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.dailyGreetingCount(greeting, count),
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.teal,
              size: 11,
            ),
          ],
        ),
      ),
    );
  }
}

/// Build 165: 지도 상단 수평 국가 점프 바.
/// `LogisticsHubs.hubs` 의 30+ 국가 중심 좌표를 칩으로 스크롤. 탭 시 지도 이동.
/// 내 국가를 맨 앞으로 정렬하고 gold 테두리 강조. 각 칩: 플래그 + 현지어 이름.
/// v5 (Build 201) 좌우 화살표 버튼 navigation country bar.
///
/// 변경:
/// - 스크롤 폐기 → ◀ ▶ 좌우 버튼으로 한 칸씩 이동
/// - 가운데 큰 카드: 현재 국가 (flag + name) 가 항상 중앙에 표시
/// - 버튼 탭 시 햅틱 + 다음 국가 위치로 지도 자동 이동
/// - 끝에 도달하면 wrap-around (처음으로 / 끝으로)
class _CountryJumpBar extends StatefulWidget {
  final String myCountry;
  final void Function(double lat, double lng) onJump;
  /// Build 250: 외부에서 "내 위치" 버튼 탭 시 카운터를 0번 (= 본인 국가) 으로
  /// 강제 리셋시키는 트리거. int 값이 변경될 때마다 didUpdateWidget 가
  /// _idx=0 으로 reset. 호출 측에서 setState 로 정수 증가시키면 됨.
  final int resetSignal;
  const _CountryJumpBar({
    required this.myCountry,
    required this.onJump,
    this.resetSignal = 0,
  });

  static const List<({String name, String flag, double lat, double lng})>
      _countries = [
    (name: '대한민국', flag: '🇰🇷', lat: 37.5665, lng: 126.978),
    (name: '일본', flag: '🇯🇵', lat: 35.6762, lng: 139.6503),
    (name: '미국', flag: '🇺🇸', lat: 40.7128, lng: -74.006),
    (name: '중국', flag: '🇨🇳', lat: 39.9042, lng: 116.4074),
    (name: '영국', flag: '🇬🇧', lat: 51.5074, lng: -0.1278),
    (name: '프랑스', flag: '🇫🇷', lat: 48.8566, lng: 2.3522),
    (name: '독일', flag: '🇩🇪', lat: 52.52, lng: 13.405),
    (name: '이탈리아', flag: '🇮🇹', lat: 41.9028, lng: 12.4964),
    (name: '스페인', flag: '🇪🇸', lat: 40.4168, lng: -3.7038),
    (name: '브라질', flag: '🇧🇷', lat: -15.7942, lng: -47.8822),
    (name: '인도', flag: '🇮🇳', lat: 28.6139, lng: 77.209),
    (name: '호주', flag: '🇦🇺', lat: -33.8688, lng: 151.2093),
    (name: '캐나다', flag: '🇨🇦', lat: 43.6532, lng: -79.3832),
    (name: '멕시코', flag: '🇲🇽', lat: 19.4326, lng: -99.1332),
    (name: '러시아', flag: '🇷🇺', lat: 55.7558, lng: 37.6173),
    (name: '터키', flag: '🇹🇷', lat: 41.0082, lng: 28.9784),
    (name: '태국', flag: '🇹🇭', lat: 13.7563, lng: 100.5018),
    (name: '싱가포르', flag: '🇸🇬', lat: 1.3521, lng: 103.8198),
    (name: '베트남', flag: '🇻🇳', lat: 21.0285, lng: 105.8542),
    (name: '이집트', flag: '🇪🇬', lat: 30.0444, lng: 31.2357),
  ];

  @override
  State<_CountryJumpBar> createState() => _CountryJumpBarState();
}

class _CountryJumpBarState extends State<_CountryJumpBar> {
  int _idx = 0;
  late List<({String name, String flag, double lat, double lng})> _sorted;

  @override
  void initState() {
    super.initState();
    _sortCountries();
  }

  @override
  void didUpdateWidget(_CountryJumpBar old) {
    super.didUpdateWidget(old);
    // Build 250: resetSignal 증가 시 본인 국가 (인덱스 0) 으로 리셋. "내 위치"
    // 탭 시 호출. 이전엔 다른 나라 보고 있으면 그대로 남아있어 사용자 혼동.
    if (old.resetSignal != widget.resetSignal) {
      setState(() {
        _idx = 0;
      });
      return;
    }
    if (old.myCountry != widget.myCountry) {
      _sortCountries();
      setState(() {});
    }
  }

  void _sortCountries() {
    // Build 219: 현재 사용자의 국가를 항상 0번으로. 기존엔 myIdx==0(한국)
    // 인 경우만 정렬을 건너뛰어 모두 한국부터 시작했음. 이제 myIdx>=0 이면
    // 무조건 그 국가를 앞으로 끌어올린다.
    final myIdx = _CountryJumpBar._countries
        .indexWhere((c) => c.name == widget.myCountry);
    if (myIdx >= 0) {
      _sorted = [
        _CountryJumpBar._countries[myIdx],
        ..._CountryJumpBar._countries
            .where((c) => c.name != widget.myCountry),
      ];
    } else {
      // myCountry 가 정의 목록에 없는 경우 (희소 국가)
      _sorted = List.of(_CountryJumpBar._countries);
    }
    // 0번이 항상 자기 국가가 되도록 인덱스도 리셋
    _idx = 0;
  }

  void _step(int delta) {
    final n = _sorted.length;
    final next = (_idx + delta + n) % n;
    setState(() => _idx = next);
    Feedback.forTap(context);
    final c = _sorted[next];
    widget.onJump(c.lat, c.lng);
  }

  @override
  Widget build(BuildContext context) {
    final c = _sorted[_idx];
    final lang = context.read<AppState>().currentUser.languageCode;
    final name = CountryL10n.localizedName(c.name, lang);
    // Build 250: 사용자 요청 — 국가 선택 바 크기 축소. height 56→44,
    // fontSize 16→13.5, flag 22→18, 화살표 44→34, margin 12→16 으로 컴팩트.
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _ArrowBtn(icon: Icons.chevron_left_rounded, onTap: () => _step(-1)),
          const SizedBox(width: 6),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Container(
                key: ValueKey(c.name),
                height: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(c.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1A1300),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _ArrowBtn(icon: Icons.chevron_right_rounded, onTap: () => _step(1)),
        ],
      ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Build 253: RTL 언어 (아랍어 등) 에서 좌/우 화살표 의미 반전 — `Icon` 의
    // `textDirection` 를 명시적으로 LTR 로 고정해 chevron 자체는 그대로 유지하되,
    // Material `chevron_left/right` 자체는 directionality-aware 가 아니라
    // 시각적 좌우만 의미. 사용자 mental model: "왼쪽" 버튼 누르면 이전 국가, RTL 에서도 동일.
    return Material(
      color: AppColors.bgCard,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            color: AppColors.textPrimary,
            size: 20,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}

/// Build 271: 위치 권한 거부 시 지도 상단에 표시되는 영구 배너.
/// 탭하면 앱 설정 진입.
/// Build 273: 14개 언어 풀 번역 (AppL10n.locationDeniedBanner).
class _LocationPermissionBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _LocationPermissionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final label = l.locationDeniedBanner;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('📍', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 상단 헤더 ──────────────────────────────────────────────────────────────────
class _MapHeader extends StatelessWidget {
  // 지도 상단 헤더. Build 141 — 우측에 ⓘ 도움말 버튼 추가. 이모지 의미와
  // 티어별 역할을 한 번에 설명하는 바텀 시트를 연다.
  const _MapHeader();

  @override
  Widget build(BuildContext context) {
    final timeColors = AppTimeColors.of(context);
    // Build 148: 티어별 헤더 tint — Brand 는 미세한 오렌지 오버레이로
    // "대시보드 모드" 감각, Premium 은 gold 미세 오버레이. 티어 정체성이
    // 앱 상단에서 은은하게 드러나되 가독성은 해치지 않음 (alpha 0.08 이하).
    final isBrand = context.select<AppState, bool>(
      (s) => s.currentUser.isBrand,
    );
    final isPremium = context.select<AppState, bool>(
      (s) => s.currentUser.isPremium,
    );
    final tierTint = isBrand
        ? AppColors.coupon.withValues(alpha: 0.10)
        : isPremium
            ? AppColors.gold.withValues(alpha: 0.08)
            : Colors.transparent;
    return Container(
      decoration: BoxDecoration(
        // Build 146: 그라데이션 더 부드럽게 — bgDeep → transparent 부드러운
        // 페이드로 지도 첫 인상 시 "헤더가 덮고 있는 느낌" 감쇄.
        // Build 148: 티어 tint 를 bgDeep 위에 추가 — 색감만 은은히 변화.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(
              tierTint,
              timeColors.bgDeep.withValues(alpha: 0.45),
            ),
            timeColors.bgDeep.withValues(alpha: 0.0),
          ],
          stops: const [0.3, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          // Build 146: padding 20/10/12/8 → 16/6/8/4 로 컴팩트.
          padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 8, 4),
          child: Row(
            children: [
              // Build 146: 로고를 ✉️ 이모지 + 텍스트 조합으로 바꿔 브랜딩
              // 표현 강화. fontSize 18→16, weight w800→w900.
              // Build 460 (키비주얼): 로고 존재감 ↑ (🎟 16→18, 텍스트 16→17).
              const Text('🎟', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Text(
                'Thiscount',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              // Build 154: 주말(토·일) 감지 시 🌈 부스트 칩 노출. 유저에게
              // 매주 돌아오는 이벤트 감각 — 실제 XP 배수는 브랜드 활동량이
              // 주말 증가한다는 가정. 도움말 버튼 좌측.
              const _WeekendBoostChip(),
              _MapHelpButton(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Build 154: 주말 부스트 칩 — 토·일 하루 종일 표시. 탭하면 snackbar 로
/// 주말 이벤트 설명. 실제 XP 배수 로직은 미구현 (placeholder UI).
class _WeekendBoostChip extends StatelessWidget {
  const _WeekendBoostChip();

  @override
  Widget build(BuildContext context) {
    final weekday = DateTime.now().weekday; // 월=1, 일=7
    final isWeekend = weekday == DateTime.saturday || weekday == DateTime.sunday;
    if (!isWeekend) return const SizedBox.shrink();
    final langCode = context.read<AppState>().currentUser.languageCode;
    final l10n = AppL10n.of(langCode);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.weekendBoostDesc,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: const Color(0xFFB87333),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.coupon,
                  AppColors.coupon,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.coupon.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌈', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  l10n.weekendBoostLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Build 141: 지도 상단 우측 ⓘ 도움말 버튼. 이모지·마커 범례와 티어별 사용법.
/// Build 146: 터치 타겟 44pt 이상 확보 + Semantics 라벨 접근성.
class _MapHelpButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return Semantics(
      label: l10n.mapHelpTitle,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showMapHelpSheet(context),
          child: Container(
            // Build 146: 44×44pt 최소 터치 타겟 보장 (이전 34×34).
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.bgCard.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.textMuted.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMapHelpSheet(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📖', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.mapHelpTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    // Build 424 (WCAG P0): 닫기 버튼 a11y tooltip.
                    tooltip: l10n.authClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.mapHelpTierSection,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              _helpRow(emoji: '🎟', title: l10n.mapHelpTierFreeTitle, body: l10n.mapHelpTierFreeBody),
              const SizedBox(height: 10),
              _helpRow(emoji: '📸', title: l10n.mapHelpTierPremiumTitle, body: l10n.mapHelpTierPremiumBody),
              const SizedBox(height: 10),
              _helpRow(emoji: '📣', title: l10n.mapHelpTierBrandTitle, body: l10n.mapHelpTierBrandBody),
              const SizedBox(height: 16),
              Text(
                l10n.mapHelpMarkerSection,
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              _helpRow(emoji: '📮', title: l10n.mapHelpMarkerArrivedTitle, body: l10n.mapHelpMarkerArrivedBody),
              const SizedBox(height: 10),
              _helpRow(emoji: '🎟', title: l10n.mapHelpMarkerCouponTitle, body: l10n.mapHelpMarkerCouponBody),
              const SizedBox(height: 10),
              _helpRow(emoji: '🎁', title: l10n.mapHelpMarkerVoucherTitle, body: l10n.mapHelpMarkerVoucherBody),
              const SizedBox(height: 10),
              _helpRow(emoji: '🏢', title: l10n.mapHelpMarkerBrandTitle, body: l10n.mapHelpMarkerBrandBody),
              const SizedBox(height: 16),
              Text(
                l10n.mapHelpHowToSection,
                style: const TextStyle(
                  color: AppColors.coupon,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              _helpRow(emoji: '1️⃣', title: l10n.mapHelpStep1Title, body: l10n.mapHelpStep1Body),
              const SizedBox(height: 10),
              _helpRow(emoji: '2️⃣', title: l10n.mapHelpStep2Title, body: l10n.mapHelpStep2Body),
              const SizedBox(height: 10),
              _helpRow(emoji: '3️⃣', title: l10n.mapHelpStep3Title, body: l10n.mapHelpStep3Body),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpRow({required String emoji, required String title, required String body}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 28, child: Text(emoji, style: const TextStyle(fontSize: 18))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 근처 알림 배너 ─────────────────────────────────────────────────────────────
class _NearbyAlertBanner extends StatefulWidget {
  final AppL10n l10n;
  final int count;
  final VoidCallback onTap;
  const _NearbyAlertBanner({required this.l10n, required this.count, required this.onTap});

  @override
  State<_NearbyAlertBanner> createState() => _NearbyAlertBannerState();
}

class _NearbyAlertBannerState extends State<_NearbyAlertBanner>
    with SingleTickerProviderStateMixin {
  late final int _variantIndex;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    final variants = widget.l10n.mapNearbyBannerVariants(widget.count);
    _variantIndex = DateTime.now().millisecondsSinceEpoch % variants.length;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final variants = widget.l10n.mapNearbyBannerVariants(widget.count);
    final variant = variants[_variantIndex];
    return FadeTransition(
      opacity: _pulse,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(variant.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  variant.text,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gold,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 픽업 시트 ──────────────────────────────────────────────────────────────────
class _PickupSheet extends StatelessWidget {
  final AppL10n l10n;
  final String langCode;
  final Letter letter;
  final VoidCallback onPickup;
  const _PickupSheet({required this.l10n, required this.langCode, required this.letter, required this.onPickup});

  @override
  Widget build(BuildContext context) {
    final isBrand = letter.senderIsBrand ||
        letter.letterType == LetterType.brandExpress;
    final cardColor = isBrand ? AppColors.coupon : AppColors.letter;
    final ink = isBrand
        ? const Color(0xFF1A0008)
        : const Color(0xFF0A1A00);

    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 24),
      padding: const EdgeInsetsDirectional.fromSTEB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    isBrand ? 'BRAND' : 'LETTER',
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.66,
                    ),
                  ),
                  // Build 415 (#5 레어 드롭): rare/epic 이면 희귀도 칩 노출.
                  if (letter.rarity.isSpecial) ...[
                    const SizedBox(width: 8),
                    _RarityChip(rarity: letter.rarity, l10n: l10n),
                  ],
                ],
              ),
              Text(
                letter.senderCountryFlag,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.mapLetterFrom(
              CountryL10n.localizedName(letter.senderCountry, langCode),
            ),
            style: TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            letter.senderName,
            style: TextStyle(
              color: ink.withValues(alpha: 0.65),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Build 458 (페르소나 높음): 브랜드 쿠폰은 혜택 미리보기 — 이전엔
          //   발신처만 보여 1시간 1회 픽업이 '깜깜이 도박'이었음. 발송 종류 +
          //   본문 2줄로 "걸어갈 가치"를 픽업 전에 판단. 개인 편지는 미스터리 유지.
          if (isBrand) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: ink.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        bizCategoryEmoji(letter.categoryTag),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        letter.category == LetterCategory.coupon
                            ? l10n.composeBrandCategoryCoupon
                            : letter.category == LetterCategory.voucher
                                ? l10n.composeBrandCategoryVoucher
                                : l10n.composeBrandCategoryGeneral,
                        style: TextStyle(
                          color: ink.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Build 490 (드롭 헌트 P1-N2): 미스터리 드롭은 본문 미리보기
                  // 마스킹 — "내용은 개봉 전까지 비밀" + 소셜프루프. 브랜드명·
                  // 카테고리는 유지(신뢰·법적 표시, 핸드오프 스펙 B-1).
                  if (letter.isMystery)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: HuntPalette.ink,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: HuntPalette.lav.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          // 장식 문자열 — 스크린리더 제외 (스펙 A11y).
                          const ExcludeSemantics(
                            child: Text(
                              '?  ?  ?  ?  ?  ?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: HuntPalette.lav,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.mysterySealedHint,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: HuntPalette.cream,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.mysteryProofOpened(letter.readCount),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: HuntPalette.mut,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      letter.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink.withValues(alpha: 0.9),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Build 304 (a11y): VoiceOver/TalkBack — 픽업 버튼임을 명시.
          // Build 490: 미스터리 드롭은 "여기서 개봉하기" lime CTA (스펙 B-1).
          Semantics(
            button: true,
            label: letter.isMystery ? l10n.mysteryOpenCta : l10n.mapPickUpLetter,
            child: GestureDetector(
              onTap: onPickup,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: letter.isMystery
                      ? HuntPalette.lime
                      : AppColors.bgDeep,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  letter.isMystery ? l10n.mysteryOpenCta : l10n.mapPickUpLetter,
                  style: TextStyle(
                    color: letter.isMystery
                        ? HuntPalette.limeInk
                        : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Build 415 (#5 레어 드롭): 희귀도 칩 ──────────────────────────────────────
//   픽업 시트 헤더에서 rare/epic 편지임을 알리는 작은 배지. ✨ RARE / 💎 EPIC.
class _RarityChip extends StatelessWidget {
  final LetterRarity rarity;
  final AppL10n l10n;
  const _RarityChip({required this.rarity, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isEpic = rarity == LetterRarity.epic;
    final color =
        isEpic ? const Color(0xFF7C4DFF) : const Color(0xFFB8860B);
    final label = isEpic ? l10n.rarityEpicLabel : l10n.rarityRareLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        '${rarity.badge} $label',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── 배송 중 정보 시트 (전체 구간 경로 표시) ────────────────────────────────────
class _TransitInfoSheet extends StatelessWidget {
  final AppL10n l10n;
  final Letter letter;
  const _TransitInfoSheet({required this.l10n, required this.letter});

  Color _segColor(bool isDone, bool isActive) {
    if (isDone) return AppColors.textMuted;
    if (isActive) return AppColors.teal;
    return AppColors.textMuted.withValues(alpha: 0.35);
  }

  String _durLabel(int minutes) {
    if (minutes < 60) return l10n.mapMinutes(minutes);
    final h = (minutes / 60).round();
    return l10n.mapAboutHours(h);
  }

  @override
  Widget build(BuildContext context) {
    final seg = letter.currentSegment;
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 헤더: 운송수단 + 발신→수신국
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.teal.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      letter.currentTransport.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${letter.senderCountryFlag} ${letter.senderCountry}  →  ${letter.destinationCountryFlag} ${letter.destinationCountry}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${l10n.mapCurrent}: ${seg.displayFromName(l10n.languageCode)} → ${(seg == letter.segments.last && letter.destinationDisplayAddress != null) ? letter.destinationDisplayAddress! : seg.displayToName(l10n.languageCode)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 전체 진행률 바
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: letter.overallProgress,
                backgroundColor: AppColors.bgSurface,
                valueColor: const AlwaysStoppedAnimation(AppColors.teal),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.mapOverallProgress} ${(letter.overallProgress * 100).round()}%',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    letter.etaLabel,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 구간별 경로 목록
            Text(
              l10n.mapDeliveryRoute,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(letter.segments.length, (i) {
              final s = letter.segments[i];
              final isActive = i == letter.currentSegmentIndex;
              final isDone = i < letter.currentSegmentIndex;
              final segColor = _segColor(isDone, isActive);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상태 아이콘
                    Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? AppColors.textMuted.withValues(alpha: 0.12)
                                : isActive
                                ? AppColors.teal.withValues(alpha: 0.15)
                                : AppColors.bgSurface,
                            border: Border.all(
                              color: segColor.withValues(
                                alpha: isDone ? 0.4 : 0.7,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isDone ? '✓' : s.mode.emoji,
                              style: TextStyle(fontSize: isDone ? 12 : 13),
                            ),
                          ),
                        ),
                        if (i < letter.segments.length - 1)
                          Container(
                            width: 1.5,
                            height: 14,
                            color: segColor.withValues(alpha: 0.25),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 3),
                          Text(
                            '${s.displayFromName(l10n.languageCode)} → ${(s == letter.segments.last && letter.destinationDisplayAddress != null) ? letter.destinationDisplayAddress! : s.displayToName(l10n.languageCode)}',
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${s.mode.label} · ${_durLabel(s.estimatedMinutes)}',
                            style: TextStyle(color: segColor, fontSize: 10),
                          ),
                          if (isActive) ...[
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: s.progress.clamp(0.0, 1.0),
                                backgroundColor: AppColors.bgSurface,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.teal,
                                ),
                                minHeight: 3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          l10n.mapMoving,
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}


// ── 겹침 선택 타일 ───────────────────────────────────────────────────────────
class _DisambiguationTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DisambiguationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textMuted,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Build 128 — Brand 공식 발송인 전용: 타워 비주얼.
/// Build 220: 타워 이모지 → "돈 쌓이는" 이미지로 교체. 브랜드 = 광고비 →
/// 캠페인 효과(픽업·전환) 누적 → 돈이 쌓이는 비주얼 메타포. tier 별로
/// 돈 단계가 진화 (🪙 → 💵 → 💰 → 💴 → 💶 → 💷 → 💎 → 🏦 → 🏆 → 👑).
/// Build 127 ✅ 인증 뱃지는 플래그 앞에 유지.
class _BrandTowerMarker extends StatelessWidget {
  final TowerTier tier;
  final String flag;
  final int floors;
  final AnimationController pulseController;
  final int pendingLetterCount;
  final bool isBrandVerified;

  const _BrandTowerMarker({
    required this.tier,
    required this.flag,
    required this.floors,
    required this.pulseController,
    this.pendingLetterCount = 0,
    this.isBrandVerified = false,
  });

  /// Build 220: 브랜드 티어별 "돈 쌓이는" 이모지.
  /// 광고 캠페인 누적량 → 화폐 가치 진화로 시각화.
  static String _moneyEmoji(TowerTier t) {
    switch (t) {
      case TowerTier.shack:      return '🪙'; // 동전
      case TowerTier.cottage:    return '💵'; // 달러 지폐
      case TowerTier.house:      return '💰'; // 돈 주머니
      case TowerTier.townhouse:  return '💴'; // 엔
      case TowerTier.building:   return '💶'; // 유로
      case TowerTier.office:     return '💷'; // 파운드
      case TowerTier.skyscraper: return '💸'; // 돈 날아가는
      case TowerTier.supertall:  return '💎'; // 보석
      case TowerTier.megatower:  return '🏦'; // 은행
      case TowerTier.landmark:   return '👑'; // 왕관 (최고 단계)
    }
  }

  Color _tierColor() {
    switch (tier) {
      case TowerTier.shack:
        return const Color(0xFF8B7355);
      case TowerTier.cottage:
        return const Color(0xFFCD7F32);
      case TowerTier.house:
        return const Color(0xFFC0C0C0);
      case TowerTier.townhouse:
        return const Color(0xFF90C878);
      case TowerTier.building:
        return AppColors.gold;
      case TowerTier.office:
        return AppColors.teal;
      case TowerTier.skyscraper:
        return const Color(0xFF60A5FA);
      case TowerTier.supertall:
        return const Color(0xFFAB78FF);
      case TowerTier.megatower:
        return const Color(0xFFFF9F43);
      case TowerTier.landmark:
        return AppColors.coupon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final pulse = (sin(pulseController.value * 3.14159 * 2) * 0.5 + 0.5);
        final color = _tierColor();
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52 + pulse * 6,
              height: 52 + pulse * 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.2 + pulse * 0.2),
                  width: 1.5,
                ),
              ),
            ),
            Container(
              width: 44,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.bgCard.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4 + pulse * 0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Build 220: 타워 이모지 → 돈 누적 이모지로 교체
                    Text(_moneyEmoji(tier),
                        style: const TextStyle(fontSize: 18)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isBrandVerified) ...[
                          const Text('✅', style: TextStyle(fontSize: 9)),
                          const SizedBox(width: 2),
                        ],
                        Text(
                          pendingLetterCount > 0 ? '📮' : flag,
                          style: TextStyle(
                            fontSize: pendingLetterCount > 0 ? 12 : 10,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${floors}F',
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (pendingLetterCount > 0)
              Positioned(
                top: -10,
                right: -12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.coupon,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.bgCard, width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '$pendingLetterCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Build 121 → 122 — 타워를 레벨 기반 진화 캐릭터 이모지 아바타로 대체.
/// 내 위치 전용 마커 (`_MyTowerMarker` 지점만 이 위젯으로 교체). 다른 유저
/// 위치는 기존 `_TowerClusterMarker` 계열 유지 — 사회적 표식.
/// Build 128: Brand 는 `_BrandTowerMarker` 로 분기 — 아래 위젯은 Free/Premium 전용.
///
/// 시각 구성 (Build 122 업데이트):
///   • 외곽 맥동 링 (시선 유도)
///   • 원형 아바타 ← **중앙에 레벨별 진화 캐릭터 이모지** (Build 122)
///   • 티어(브랜드·프리미엄·프리)별 테두리 색 = 픽업 반경 링 색과 일치
///   • 하단: **🇰🇷 + Lv N 결합 pill** (Build 122 — 플래그를 여기에 표시)
///   • 좌상단: 최근 획득 마일스톤 아이템 이모지 (🎯🧭🗺🎒👑)
///   • 우상단: 수령 대기 편지 수 뱃지 (기존)
class _MyTowerMarker extends StatelessWidget {
  // 기존 호출 지점과의 호환을 위해 이름·시그니처 보존. `tier`·`floors` 는
  // 유저 위치 마커 렌더링에서는 더 이상 쓰이지 않지만 타 컴포넌트에서
  // 활용 가능해 남겨둠.
  final TowerTier tier;
  final String flag;
  final int floors;
  final AnimationController pulseController;
  final int pendingLetterCount;
  final bool isPremium;
  final bool isBrand;
  final int hunterLevel;
  final String? milestoneItemEmoji;
  final String characterEmoji;
  final String? companionEmoji;
  final String? accessoryEmoji;
  final bool isBrandVerified;

  const _MyTowerMarker({
    required this.tier,
    required this.flag,
    required this.floors,
    required this.pulseController,
    required this.isPremium,
    required this.isBrand,
    required this.hunterLevel,
    required this.characterEmoji,
    this.milestoneItemEmoji,
    this.companionEmoji,
    this.accessoryEmoji,
    this.isBrandVerified = false,
    this.pendingLetterCount = 0,
  });

  Color _accent() {
    if (isBrand) return AppColors.coupon;
    if (isPremium) return AppColors.gold;
    return AppColors.teal;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final pulse = (sin(pulseController.value * 3.14159 * 2) * 0.5 + 0.5);
        final color = _accent();
        // 수령 대기 편지가 있으면 중앙 이모지를 📮 로 잠깐 전환 (arrival alert).
        // 그 외엔 레벨 진화 캐릭터.
        final centerEmoji =
            pendingLetterCount > 0 ? '📮' : characterEmoji;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Build 148: Premium 유저 전용 추가 gold aura — 기존 맥동 링보다
            // 살짝 크게 + gold 색으로 오버레이 해서 "Premium 티어" 시각적으로
            // 강조. Free 는 teal 링 1개, Premium 은 teal + gold 2중 링.
            if (isPremium && !isBrand)
              Container(
                width: 64 + pulse * 8,
                height: 64 + pulse * 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(
                      alpha: 0.12 + pulse * 0.18,
                    ),
                    width: 2.0,
                  ),
                ),
              ),
            // 외곽 맥동 링
            Container(
              width: 54 + pulse * 6,
              height: 54 + pulse * 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.2 + pulse * 0.22),
                  width: 1.5,
                ),
              ),
            ),
            // 아바타 본체 (원형) — 중앙에 진화 캐릭터 이모지
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgCard.withValues(alpha: 0.97),
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45 + pulse * 0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  centerEmoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            // 하단 중앙 pill: 🇰🇷 플래그 + Lv N (Build 122 — 플래그를
            // 중앙에서 하단 pill 로 이동해 캐릭터가 주인공이 되게).
            // Brand 는 Lv 대신 👑 표시 (레벨 시스템 밖).
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgDeep,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color, width: 1.4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Build 127: Brand 사업자 인증 완료 시 플래그 앞에 ✅ 마크.
                    if (isBrandVerified) ...[
                      const Text('✅', style: TextStyle(fontSize: 9)),
                      const SizedBox(width: 2),
                    ],
                    Text(flag, style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 3),
                    Text(
                      isBrand
                          ? '👑'
                          : (hunterLevel > 0 ? 'Lv $hunterLevel' : 'Lv 1'),
                      style: TextStyle(
                        color: color,
                        fontSize: isBrand ? 10 : 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 좌상단: 최근 획득한 마일스톤 아이템 이모지 (있을 때만)
            if (milestoneItemEmoji != null)
              Positioned(
                top: -6,
                left: -6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.2),
                  ),
                  child: Text(
                    milestoneItemEmoji!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            // Build 125: 머리 위 악세사리 (해금 시). 캐릭터 중앙 위에 작게
            // 올려 "모자 쓴 레터" 느낌. 아바타 내부라 Positioned 대신
            // Align 으로 수직 정렬.
            if (accessoryEmoji != null)
              Positioned(
                top: -4,
                child: Text(
                  accessoryEmoji!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            // Build 125: 우하단 외부 동행 동물 — "함께 걷는 펫" 감각. 서클
            // 바깥 아래쪽에 offset 해서 산책 동반자처럼 보이게.
            if (companionEmoji != null)
              Positioned(
                bottom: -4,
                right: -14,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      companionEmoji!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            // 우상단: 수령 대기 편지 수 뱃지
            if (pendingLetterCount > 0)
              Positioned(
                top: -8,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.coupon,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.bgCard, width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '$pendingLetterCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── 뾰족 지붕 커스텀 페인터 ─────────────────────────────────────────────────
class _PointedRoofPainter extends CustomPainter {
  final Color color;
  const _PointedRoofPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.9),
          color.withValues(alpha: 0.45),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PointedRoofPainter old) => old.color != color;
}

/// Build 216: Brand 사용자가 지도에 들어왔을 때 상단에 노출되는
/// "최근 픽업 장소" 배너. 본인이 발송한 캠페인 중 누군가 최근에 픽업한
/// 도착 좌표를 표시. 탭 시 그 좌표로 카메라 이동.
class _BrandRecentPickupBanner extends StatelessWidget {
  final Letter letter;
  final VoidCallback onTap;
  // Build 421 (sim-fresh P2): 하드코딩 한국어(헤더+상대시간) 제거 위해 l10n 주입.
  final AppL10n l10n;
  const _BrandRecentPickupBanner({
    required this.letter,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final at = letter.arrivedAt ?? letter.readAt ?? letter.sentAt;
    final ago = _relativeTime(DateTime.now().difference(at));
    final city = letter.destinationCity ?? letter.destinationCountry;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.coupon.withValues(alpha: 0.22),
                AppColors.coupon.withValues(alpha: 0.10),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.coupon.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.koEn('캠페인이 픽업됐어요', 'A campaign was picked up'),
                      style: TextStyle(
                        color: AppColors.coupon,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${letter.destinationCountryFlag}  $city · $ago',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.coupon.withValues(alpha: 0.85),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(Duration d) {
    if (d.inMinutes < 1) return l10n.koEn('방금 전', 'just now');
    if (d.inMinutes < 60) return l10n.letterReadMinutesAgo(d.inMinutes);
    if (d.inHours < 24) return l10n.letterReadHoursAgo(d.inHours);
    if (d.inDays < 7) return l10n.letterReadDaysAgo(d.inDays);
    return l10n.koEn('${d.inDays ~/ 7}주 전', '${d.inDays ~/ 7}w ago');
  }
}


// Build 457: 관심 카테고리 선택 시트 — 업종 다중 선택. 비우면 전체 표시.
//   "브랜드가 업종을 지정한 캠페인만" 필터 대상이라는 안내 포함.
class _InterestFilterSheet extends StatefulWidget {
  final AppState state;
  final AppL10n l10n;
  const _InterestFilterSheet({required this.state, required this.l10n});

  @override
  State<_InterestFilterSheet> createState() => _InterestFilterSheetState();
}

class _InterestFilterSheetState extends State<_InterestFilterSheet> {
  late final Set<String> _sel = {...widget.state.interestCategoryKeys};
  // Build 482 (사용자 요청): 상위 티어 — 쿠폰 종류(메시지·홍보/할인권/교환권).
  late final Set<String> _selTypes = {...widget.state.interestTypeKeys};

  static const List<String> _keys = [
    'food', 'cafe', 'beauty', 'fashion', 'event', 'it', 'other',
  ];
  // 'general'=메시지·홍보, 'coupon'=할인권, 'voucher'=교환권 (LetterCategory.key).
  static const List<String> _typeKeys = ['general', 'coupon', 'voucher'];

  String _typeLabel(AppL10n l, String key) {
    switch (key) {
      case 'coupon':
        return l.inboxFilterCoupon;
      case 'voucher':
        return l.inboxFilterVoucher;
      default:
        return l.inboxFilterGeneral;
    }
  }

  Color _typeColor(String key) {
    switch (key) {
      case 'coupon':
        return AppColors.coupon;
      case 'voucher':
        return AppColors.teal;
      default:
        return AppColors.gold;
    }
  }

  // Build 480 (글로벌): koEn → 인박스 업종 getter(14언어) 재사용.
  String _label(AppL10n l, String key) {
    switch (key) {
      case 'food':
        return l.inboxFilterFood;
      case 'cafe':
        return l.inboxFilterCafe;
      case 'beauty':
        return l.inboxFilterBeauty;
      case 'fashion':
        return l.inboxFilterFashion;
      case 'event':
        return l.inboxFilterEvent;
      case 'it':
        return l.inboxFilterIt;
      default:
        return l.inboxFilterOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔎 ${l.mapInterestFilterTitle}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.mapInterestFilterDesc,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          // ── 상위: 쿠폰 종류 (다중 선택) ──
          Text(
            l.mapFilterTypeSection,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _typeKeys.map((k) {
              final on = _selTypes.contains(k);
              final c = _typeColor(k);
              return GestureDetector(
                onTap: () => setState(() {
                  if (on) {
                    _selTypes.remove(k);
                  } else {
                    _selTypes.add(k);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  // Build 486 (a11y): 터치 타깃 ≥44pt — vertical 9→12.
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: on ? c.withValues(alpha: 0.16) : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: on
                          ? c.withValues(alpha: 0.85)
                          : AppColors.textMuted.withValues(alpha: 0.25),
                      width: on ? 1.4 : 1.0,
                    ),
                  ),
                  child: Text(
                    _typeLabel(l, k),
                    style: TextStyle(
                      color: on ? c : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // ── 하위: 업종 (다중 선택) ──
          Text(
            l.mapFilterCategorySection,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _keys.map((k) {
              final on = _sel.contains(k);
              return GestureDetector(
                onTap: () => setState(() {
                  if (on) {
                    _sel.remove(k);
                  } else {
                    _sel.add(k);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  // Build 486 (a11y): 터치 타깃 ≥44pt — vertical 8→12.
                  padding: const EdgeInsets.symmetric(
                      horizontal: 13, vertical: 12),
                  decoration: BoxDecoration(
                    color: on
                        ? AppColors.gold.withValues(alpha: 0.16)
                        : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: on
                          ? AppColors.gold.withValues(alpha: 0.75)
                          : AppColors.textMuted.withValues(alpha: 0.25),
                      width: on ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(bizCategoryEmoji(k),
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        _label(l, k),
                        style: TextStyle(
                          color: on ? AppColors.gold : AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (_sel.isNotEmpty || _selTypes.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    _sel.clear();
                    _selTypes.clear();
                  }),
                  child: Text(
                    l.commonClearAll,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await widget.state.setInterestTypes(_selTypes);
                  await widget.state.setInterestCategories(_sel);
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.bgDeep,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l.commonApply,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Build 490 (드롭 헌트 P1-N1): 캠페인 헌트 배너 ──────────────────────────
// Figma v3 스펙(docs/HANDOFF_DROP_HUNT_P1.md): HuntPalette 서브 팔레트,
// elev 표면 + lime 1px 보더 pill, 좌 lime 도트 + 캠페인명, 우 잔여 카운터,
// 하단 진행바. 소진 시 카운터 "마감" + 보더 강등. 탭 → 캠페인 위치로 카메라.
class _CampaignHuntBanner extends StatelessWidget {
  final AppL10n l10n;
  final HuntCampaignSummary summary;
  final VoidCallback onTap;

  const _CampaignHuntBanner({
    required this.l10n,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final title = l10n.huntBannerTitle(s.brandName);
    final progress = s.total <= 0
        ? 0.0
        : ((s.total - s.remaining) / s.total).clamp(0.0, 1.0);
    return Semantics(
      button: true,
      label:
          '$title, ${s.soldOut ? l10n.huntSoldOut : l10n.huntRemaining(s.remaining, s.total)}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: HuntPalette.elev.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(27),
            border: Border.all(
              // 소진 시 보더 강등 (스펙 States).
              color: s.soldOut
                  ? HuntPalette.mut.withValues(alpha: 0.4)
                  : HuntPalette.lime,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: s.isMystery ? HuntPalette.lav : HuntPalette.lime,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.othersCount > 0
                          ? '$title · ${l10n.huntOthersSuffix(s.othersCount)}'
                          : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HuntPalette.cream,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.soldOut
                        ? l10n.huntSoldOut
                        : l10n.huntRemaining(s.remaining, s.total),
                    style: TextStyle(
                      color: s.soldOut ? HuntPalette.mut : HuntPalette.lime,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor:
                        HuntPalette.cream.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      HuntPalette.lime,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
