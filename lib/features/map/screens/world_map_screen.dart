import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/map_config.dart';
import '../../progression/user_level.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/letter.dart';
import '../../../models/user_profile.dart';
import '../../../state/app_state.dart';
import '../../brand/brand_promo_banner.dart';

// 목업 타워 데이터 제거 → AppState.mapUsers (Firestore 실시간) 사용

class WorldMapScreen extends StatefulWidget {
  final VoidCallback? onGoToInbox;
  const WorldMapScreen({super.key, this.onGoToInbox});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();

  /// MainScaffold에서 발송 직후 호출: 마지막 발송 편지 위치로 카메라 이동
  static final focusSentLetterNotifier = ValueNotifier<bool>(false);
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin {
  static const String _permissionDialogDateKey =
      'world_map_permission_denied_forever_prompt_date';
  static const double _towerLabelZoomThreshold = 4.8;
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
  bool _showTowerLabels = false;
  final bool _showRouteLines = true;
  bool _showNearbyOnly = false;
  final bool _showTowers = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    // 1초마다 tickNotifier 갱신 → 편지 마커 위치가 sentAt~arrivalTime 기반으로 부드럽게 이동
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _tickNotifier.value++;
    });
    // 지도 열릴 때 회원 타워 즉시 로드 + 유저 위치로 자동 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      state.fetchMapUsers(force: true);
      // Build 151: 이전 세션의 지도 위치·줌이 저장돼 있으면 우선 복원.
      // 없으면 기존 로직 (유저 현재 위치로 이동).
      _restoreLastMapPosition(state);
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
    WorldMapScreen.focusSentLetterNotifier.removeListener(_onFocusSentLetter);
    _positionTimer?.cancel();
    _mapRefreshTimer?.cancel();
    _positionSaveDebounce?.cancel();
    _tickNotifier.dispose();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Build 151: 이전 세션 지도 위치·줌 복원. 저장된 값 없으면 유저 좌표로
  /// 초기 이동 (기존 로직).
  Future<void> _restoreLastMapPosition(AppState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedZoom = prefs.getDouble(_prefLastZoom);
      final savedLat = prefs.getDouble(_prefLastLat);
      final savedLng = prefs.getDouble(_prefLastLng);
      if (!mounted) return;
      if (savedZoom != null && savedLat != null && savedLng != null) {
        _mapController.move(ll.LatLng(savedLat, savedLng), savedZoom);
        _lastKnownZoom = savedZoom;
        return;
      }
    } catch (_) {}
    // 저장값 없거나 실패 → 기존 로직 (유저 현재 위치).
    if (!mounted) return;
    final lat = state.currentUser.latitude;
    final lng = state.currentUser.longitude;
    final isDefault =
        (lat - 37.5665).abs() < 0.001 && (lng - 126.978).abs() < 0.001;
    if (lat != 0 && lng != 0) {
      _mapController.move(
        ll.LatLng(lat, lng),
        isDefault ? 5.0 : 11.0,
      );
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
        final inboxDelivered = state.inbox
            .where((l) => l.status == DeliveryStatus.delivered)
            .toList();
        final letters = _showNearbyOnly
            ? state.nearbyLetters
            : [
                ...state.worldLetters.where(
                  (l) =>
                      l.status == DeliveryStatus.inTransit ||
                      l.status == DeliveryStatus.nearYou ||
                      // 수령 대기 (목적지 도착, 500m 밖): 지도에서 계속 표시
                      l.status == DeliveryStatus.deliveredFar ||
                      // 일반 편지: 도착 후 누군가 열기 전까지 지도에 유지
                      (l.status == DeliveryStatus.delivered &&
                          !l.isReadByRecipient),
                ),
                // 내가 수령했지만 아직 읽지 않은 inbox 편지도 지도에 📮로 표시
                ...inboxDelivered,
              ];
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
                initialZoom: 2.0,
                minZoom: 2.0,
                maxZoom: 18.0,
                backgroundColor: timeColors.bgDeep,
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
                  userAgentPackageName: 'com.globaldrift.lettergo',
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
                    userAgentPackageName: 'com.globaldrift.lettergo',
                    maxZoom: 19,
                    maxNativeZoom: 19,
                    keepBuffer: 2,
                    evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                  ),
                // ── 배송 경로선 ────────────────────────────────────────────
                if (_showRouteLines)
                  PolylineLayer(polylines: _buildRoutePolylines(letters)),
                // ── 허브 마커 ─────────────────────────────────────────────
                MarkerLayer(markers: _buildHubMarkers(letters)),
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
                      color: timeColors.accent.withValues(alpha: 0.08),
                      borderColor: timeColors.accent.withValues(alpha: 0.35),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
                // ── 픽업 반경 링 (Build 120) ────────────────────────────
                // 실제 줍기 가능한 반경을 티어별 색으로 상시 표시. Premium
                // (골드) 과 Free (티일) 의 시각적 차이가 유저에게 "5× 넓은
                // 원" 을 매일 느끼게 하는 핵심 앵커.
                // - Free: teal (200m + 레벨 보너스)
                // - Premium: gold (1km + 레벨 보너스)
                // - Brand: orange (1km)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: ll.LatLng(
                        state.currentUser.latitude,
                        state.currentUser.longitude,
                      ),
                      radius: state.pickupRadiusMeters,
                      useRadiusInMeter: true,
                      color: state.currentUser.isBrand
                          ? const Color(0xFFFF8A5C).withValues(alpha: 0.07)
                          : state.currentUser.isPremium
                              ? AppColors.gold.withValues(alpha: 0.10)
                              : AppColors.teal.withValues(alpha: 0.10),
                      borderColor: state.currentUser.isBrand
                          ? const Color(0xFFFF8A5C).withValues(alpha: 0.70)
                          : state.currentUser.isPremium
                              ? AppColors.gold.withValues(alpha: 0.75)
                              : AppColors.teal.withValues(alpha: 0.75),
                      borderStrokeWidth: 2.0,
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
                          letters, state, l10n, langCode,
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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: const _MapHeader(),
            ),
            // Build 165: 국가 점프 스크롤 바 — 수평 스크롤 칩으로 다른 나라
            // 지도로 원탭 이동. 기존 "수동 줌아웃 후 드래그" 산만함 해소.
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _CountryJumpBar(
                  myCountry: state.currentUser.country,
                  onJump: (lat, lng) {
                    HapticFeedback.lightImpact();
                    _mapController.move(ll.LatLng(lat, lng), 5.5);
                  },
                ),
              ),
            ),
            // Build 142: 헤더·국가 바 아래로 슬라이드-다운 브랜드 홍보 배너.
            Positioned(
              top: 104,
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
            // ── 근처 도착 배너 (experienced 레벨 이상에서만) ─────────────
            // 브랜드도 줍기 가능해져서 `!isBrand` 조건 제거.
            if (state.hasNearbyAlert &&
                state.isFeatureUnlocked(UnlockableFeature.nearbyPickup))
              Positioned(
                top: 220,
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
            // Build 120: 나침반 힌트 배너 — 반경 안에 편지가 없을 때 가장 가까운
            // 바깥쪽 편지의 방향·거리를 한 줄로 알려준다. "앱을 열었는데 반경 0통"
            // 인 죽은 상태를 "저쪽으로 150m 가면 있어요" 로 전환.
            // Build 152: 반경 안에 편지 있을 때 시간대별 인사 + 카운트 pill.
            // 기존 나침반 슬롯과 상호 배타 — 둘 다 top 220 에 배치하되
            // nearbyLetters.isNotEmpty 이면 인사 pill, 비어있으면 방향 안내.
            if (state.nearbyLetters.isNotEmpty &&
                !state.hasNearbyAlert)
              Positioned(
                top: 220,
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
            if (state.nearbyLetters.isEmpty && state.worldLetters.isNotEmpty)
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
                      _mapController.move(
                        ll.LatLng(
                          hint.letter.destinationLocation.latitude,
                          hint.letter.destinationLocation.longitude,
                        ),
                        14.0,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
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
            Positioned(
              bottom: 120,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  _MapQuickActionButton(
                    icon: Icons.add_rounded,
                    tooltip: l10n.mapZoomIn,
                    onTap: () => _zoomBy(1.0),
                  ),
                  const SizedBox(height: 10),
                  _MapQuickActionButton(
                    icon: Icons.remove_rounded,
                    tooltip: l10n.mapZoomOut,
                    onTap: () => _zoomBy(-1.0),
                  ),
                  const SizedBox(height: 10),
                  _MyLocationButton(
                    mapController: _mapController,
                    onLocationUpdated: (lat, lng) =>
                        state.updateUserLocation(lat, lng),
                  ),
                ],
              ),
            ),
            // ── 하단 통계 바 ───────────────────────────────────────────────
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _StatsBar(
                l10n: l10n,
                state: state,
                mapController: _mapController,
                userLat: state.currentUser.latitude,
                userLng: state.currentUser.longitude,
                onShowAll: () {
                  setState(() => _showNearbyOnly = false);
                  _mapController.move(
                    ll.LatLng(
                      state.currentUser.latitude,
                      state.currentUser.longitude,
                    ),
                    3.0,
                  );
                },
                onShowNearby: () {
                  setState(() => _showNearbyOnly = true);
                  _mapController.move(
                    ll.LatLng(
                      state.currentUser.latitude,
                      state.currentUser.longitude,
                    ),
                    12.0,
                  );
                },
                onGoToInbox: widget.onGoToInbox,
              ),
            ),
          ],
        );
      },
    );
  }

  // ── 경로선 ──────────────────────────────────────────────────────────────────
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
  List<Marker> _buildLetterMarkers(
    List<Letter> letters, AppState state, AppL10n l10n, String langCode, {
    List<MapUser>? nearestCluster,
  }) {
    final markers = <Marker>[];

    // 내 타워 마커 (탭하면 내 랭킹 정보 or 겹친 편지 disambiguation)
    // 타워 위치(2km 이내)에 수령 가능한 nearYou 편지 목록
    final towerLat = state.currentUser.latitude;
    final towerLng = state.currentUser.longitude;
    final overlappingLetters = letters
        .where(
          (l) =>
              (l.status == DeliveryStatus.nearYou ||
                  (l.status == DeliveryStatus.delivered &&
                      !l.isReadByRecipient)) &&
              l.destinationLocation.distanceTo(LatLng(towerLat, towerLng)) <
                  200,
        )
        .toList();

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
                    ? const Color(0xFF7C4A00)
                    : const Color(0xFF004D47),
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

    final now = DateTime.now();
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
            height: (isBrandLetter && viewerIsPremiumOrBrand ? 62 : 48) +
                (isNearest ? 22 : 0),
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
            height: (isBrandLetter && viewerIsPremiumOrBrand ? 62 : 48) +
                (isNearest ? 22 : 0),
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
          width: showAsArrived ? 48 : 36,
          height: showAsArrived ? 48 : 36,
          child: GestureDetector(
            onTap: () => _onLetterTap(context, letter, state, l10n, langCode),
            child: showAsArrived && letter.status == DeliveryStatus.inTransit
                ? _ArrivedWaitingMarker(pulseController: _pulseController)
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
    List<MapUser>? best;
    double bestDist = 0.05 * 0.05; // 최대 5km
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
      final hasUsername = rep.username != null && rep.username!.isNotEmpty;
      final displayLabel = rep.towerName?.isNotEmpty == true
          ? rep.towerName!
          : (hasUsername ? '@${rep.username}' : null);
      final labelText = displayLabel ?? '';
      final hasLabel = showLabels && labelText.isNotEmpty;

      // 층수 제한 (마커 크기 제한)
      final displayFloors = rep.floors.clamp(1, 15);
      final floorH = (7.0 * scale).roundToDouble();
      final towerW = (34 * scale).roundToDouble();
      final roofH = (10 * scale).roundToDouble();
      final towerBodyH = roofH + (displayFloors * floorH);
      // 오라 여백
      final tierIdx = rep.tier.index;
      final hasAura = tierIdx >= 4; // Building 이상
      final hasParticles = tierIdx >= 6; // Skyscraper 이상
      final auraExtra = hasAura ? 14.0 * scale : 0.0;
      final totalW = max(56.0, towerW + 24 + auraExtra * 2);
      final totalH = towerBodyH + 36 * scale + (hasLabel ? 14.0 : 0.0) + auraExtra;

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
                // ── 오라 + 타워 본체 ──
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // 오라 글로우 (Building+)
                    if (hasAura)
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: towerW + 20 * scale,
                            height: towerBodyH + 10 * scale,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(towerW * 0.5),
                              boxShadow: [
                                BoxShadow(
                                  color: tierColor.withValues(alpha: hasParticles ? 0.35 : 0.2),
                                  blurRadius: hasParticles ? 20 * scale : 12 * scale,
                                  spreadRadius: hasParticles ? 4 * scale : 2 * scale,
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
                        ),
                      ),
                    // 파티클 (Skyscraper+)
                    if (hasParticles) ...[
                      for (int pi = 0; pi < (tierIdx >= 8 ? 5 : 3); pi++)
                        Positioned(
                          top: (towerBodyH * 0.15 * pi) - 2 * scale,
                          left: pi.isEven ? -3 * scale : null,
                          right: pi.isOdd ? -3 * scale : null,
                          child: Container(
                            width: 3 * scale,
                            height: 3 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tierColor.withValues(alpha: 0.6),
                              boxShadow: [
                                BoxShadow(
                                  color: tierColor.withValues(alpha: 0.4),
                                  blurRadius: 4 * scale,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                    // ── 타워 본체 ──
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 장식 이모지 (지붕 위)
                        if (rep.towerAccentEmoji != null)
                          Padding(
                            padding: EdgeInsets.only(bottom: 1 * scale),
                            child: Text(
                              rep.towerAccentEmoji!,
                              style: TextStyle(fontSize: 10 * scale),
                            ),
                          ),
                        // 국기 (지붕 위)
                        Text(rep.flag, style: TextStyle(fontSize: 10 * scale)),
                        // 지붕
                        _buildTowerRoof(
                          width: towerW + 6 * scale,
                          height: roofH,
                          color: tierColor,
                          roofStyle: rep.towerRoofStyle,
                          scale: scale,
                        ),
                        // 층 쌓기
                        ...List.generate(displayFloors, (i) {
                          final isBottom = i == displayFloors - 1;
                          final fadeAlpha = 0.25 - (i / displayFloors) * 0.15;
                          return _buildTowerFloor(
                            width: towerW,
                            height: floorH,
                            color: tierColor,
                            alpha: fadeAlpha.clamp(0.05, 0.25),
                            isBottom: isBottom,
                            borderWidth: 1.5 * scale,
                            floorIndex: i,
                            windowStyle: rep.towerWindowStyle,
                            scale: scale,
                          );
                        }),
                      ],
                    ),
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
                            color: const Color(0xFFEF4444),
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
            const Color(0xFF1E293B).withValues(alpha: 0.85),
          ],
        ),
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.45), width: borderWidth),
          right: BorderSide(color: color.withValues(alpha: 0.45), width: borderWidth),
          bottom: isBottom
              ? BorderSide(color: color.withValues(alpha: 0.45), width: borderWidth)
              : BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 0.5,
                ),
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
        return const Color(0xFFFF6B9D);
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
          color: Color(0xFF1A2535),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                  icon: l.senderIsBrand ? l.category.brandEmoji : '📮',
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
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                        Text(
                          u.tier.emoji,
                          style: const TextStyle(fontSize: 24),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${u.tier.name.toUpperCase()} · ${u.floors}F',
                                style: TextStyle(
                                  color: tierColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
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
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                      child: Text(
                        '${tier.emoji} $flag',
                        style: const TextStyle(fontSize: 14),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: tierColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '${tier.emoji}  ${tier.labelL(l10n.languageCode)}',
                            style: TextStyle(
                              color: tierColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (username != null && username.isNotEmpty)
                          Text(
                            '@$username',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
                  // 건물 층수
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
                            '${floors}F',
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
                  border: Border.all(color: const Color(0xFF1F2D44)),
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
                          '${towerH.toInt()} / 240px',
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
    if (letter.status == DeliveryStatus.nearYou) {
      _showPickupDialog(ctx, letter, state, l10n, langCode);
    } else if (letter.status == DeliveryStatus.deliveredFar) {
      _showDeliveredFarDialog(ctx, letter, l10n);
    } else {
      _showTransitInfo(ctx, letter, l10n);
    }
  }

  void _showDeliveredFarDialog(BuildContext ctx, Letter letter, AppL10n l10n) {
    // 브랜드 편지는 카테고리 맞춤 이모지로 도착 상태를 알림.
    final arrivalEmoji = letter.senderIsBrand ? letter.category.brandEmoji : '📬';
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
          final error = state.pickUpLetter(letter.id);
          Navigator.pop(ctx);
          if (error == null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(
                  '📩  ${letter.senderCountryFlag} ${l10n.mapReceivedLetterFrom(CountryL10n.localizedName(letter.senderCountry, langCode))}',
                ),
                backgroundColor: AppColors.bgCard,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(2.0, 18.0);
    _mapController.move(camera.center, nextZoom);
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
        ? nearest.category.brandEmoji
        : '📬';

    return (
      letter: nearest,
      distance: nearestDist.round(),
      arrow: arrows[idx],
      emoji: catEmoji,
    );
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
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
          backgroundColor: const Color(0xFF0D1421),
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

  const _MapQuickActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeColors = AppTimeColors.of(context);
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
                  color: timeColors.accent.withValues(alpha: 0.42),
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
              child: Icon(icon, color: timeColors.accent, size: 22),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.mapLocationPermissionRequired),
              backgroundColor: const Color(0xFF1F2D44),
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 8));
      widget.onLocationUpdated(pos.latitude, pos.longitude);
      widget.mapController.move(ll.LatLng(pos.latitude, pos.longitude), 14.0);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mapCannotGetLocation),
            backgroundColor: const Color(0xFF1F2D44),
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
    return GestureDetector(
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
    );
  }
}

// ── 운송수단 마커 ──────────────────────────────────────────────────────────────
/// 도착 대기 중 마커 (inTransit → 실제 도착했지만 아직 상태 전환 전)
/// 비행기 대신 📬로 표시
class _ArrivedWaitingMarker extends StatelessWidget {
  final AnimationController pulseController;
  const _ArrivedWaitingMarker({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final phase = (pulseController.value * 2 * pi) % (2 * pi);
        final pulse = (sin(phase) * 0.5 + 0.5);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 40 + pulse * 8,
              height: 40 + pulse * 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.25 + pulse * 0.35),
                  width: 1.5,
                ),
              ),
            ),
            Text(
              '📬',
              style: TextStyle(
                fontSize: 22,
                shadows: [
                  Shadow(
                    color: AppColors.gold.withValues(alpha: 0.6 + pulse * 0.3),
                    blurRadius: 10,
                  ),
                  const Shadow(
                    color: Color(0x88000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
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
            ? letter.category.brandEmoji
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
            ? const Color(0xFFFFD700)
            : letter.senderTier == LetterSenderTier.brand
            ? const Color(0xFFFF8A5C)
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
                    color: const Color(0xFFFFD700),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black38, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.6),
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
                    color: const Color(0xFFFF8A5C),
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
    return AnimatedBuilder(
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
            ? const Color(0xFFFF8A5C)
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
                ? const Color(0xFFFFB86B)
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
            ? letter.category.brandEmoji
            : showAsPremium
            ? '💌'
            : '📮';

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
              children: [
                // Build 164: 최단 편지 전용 추가 halo (width 44+pulse, gold)
                if (isNearest)
                  Container(
                    width: 44 + pulse * 8,
                    height: 44 + pulse * 8,
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
                // 맥동 링
                Container(
                  width: 32 + pulse * 6,
                  height: 32 + pulse * 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: glowColor.withValues(alpha: 0.2 + pulse * 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
                // 편지함 아이콘 컨테이너 (Build 147: 내부 테두리 = 카테고리 색)
                Container(
                  width: 30,
                  height: 30,
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
                      style: TextStyle(
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            color: glowColor.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
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
                    color: const Color(0xFFFF8A5C).withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  letter.senderName,
                  style: const TextStyle(
                    color: Color(0xFFFF8A5C),
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
class _CountryJumpBar extends StatelessWidget {
  final String myCountry;
  final void Function(double lat, double lng) onJump;
  const _CountryJumpBar({required this.myCountry, required this.onJump});

  /// 대표 국가 리스트 — LogisticsHubs 에 정의된 주요 hub 중 선별.
  /// (Flag emoji + Korean country name from LogisticsHubs key).
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
  Widget build(BuildContext context) {
    // 내 국가 맨 앞, 그 외 기존 순서.
    final myIdx = _countries.indexWhere((c) => c.name == myCountry);
    final sorted = myIdx > 0
        ? [_countries[myIdx], ..._countries.where((c) => c.name != myCountry)]
        : _countries;
    return Container(
      height: 42,
      margin: const EdgeInsets.only(top: 2),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final c = sorted[i];
          final isMine = c.name == myCountry;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () => onJump(c.lat, c.lng),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgCard.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isMine
                        ? AppColors.gold.withValues(alpha: 0.7)
                        : AppColors.textMuted.withValues(alpha: 0.25),
                    width: isMine ? 1.4 : 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.flag, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      _countryLabel(context, c.name),
                      style: AppText.caption.copyWith(
                        color: isMine
                            ? AppColors.gold
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _countryLabel(BuildContext context, String koName) {
    final lang = context.read<AppState>().currentUser.languageCode;
    return CountryL10n.localizedName(koName, lang);
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
        ? const Color(0xFFFF8A5C).withValues(alpha: 0.10)
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
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 4),
          child: Row(
            children: [
              // Build 146: 로고를 ✉️ 이모지 + 텍스트 조합으로 바꿔 브랜딩
              // 표현 강화. fontSize 18→16, weight w800→w900.
              const Text('✉️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text(
                'Letter Go',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
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
                  Color(0xFFFF8A5C),
                  Color(0xFFFFB86B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8A5C).withValues(alpha: 0.35),
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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
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
                  color: Color(0xFFFF8A5C),
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
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📩', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            '${letter.senderCountryFlag} ${l10n.mapLetterFrom(CountryL10n.localizedName(letter.senderCountry, langCode))}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            letter.senderName,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPickup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.bgDeep,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.mapPickUpLetter,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
                        '${l10n.mapCurrent}: ${seg.fromName} → ${(seg == letter.segments.last && letter.destinationDisplayAddress != null) ? letter.destinationDisplayAddress! : seg.toName}',
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
                            '${s.fromName} → ${(s == letter.segments.last && letter.destinationDisplayAddress != null) ? letter.destinationDisplayAddress! : s.toName}',
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

// ── 하단 통계 바 (인터랙티브 네비게이션) ────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final AppL10n l10n;
  final AppState state;
  final MapController mapController;
  final double userLat;
  final double userLng;
  final VoidCallback onShowAll;
  final VoidCallback onShowNearby;
  final VoidCallback? onGoToInbox;

  const _StatsBar({
    required this.l10n,
    required this.state,
    required this.mapController,
    required this.userLat,
    required this.userLng,
    required this.onShowAll,
    required this.onShowNearby,
    this.onGoToInbox,
  });

  @override
  Widget build(BuildContext context) {
    final timeColors = AppTimeColors.of(context);
    // Build 144: 반투명 + 블러 톤 + primary/secondary 위계 도입.
    // 📍 "근처" 지표만 primary (줍기 가능 여부가 핵심 action).
    // 나머지 (전체/받은/보낸) 은 secondary 로 톤 다운.
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          // 반투명 (0.78) + 얇은 테두리 → 지도 배경이 살짝 비쳐
          // "지도 주인공" 느낌 유지. 기존 0.92 너무 불투명.
          color: timeColors.bgCard.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: timeColors.accent.withValues(alpha: 0.22),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatBtn(
              icon: '✈️',
              value: '${state.totalInTransitCount}',
              label: l10n.mapAllLetters,
              onTap: onShowAll,
            ),
            _Divider(),
            _StatBtn(
              icon: '📍',
              value: '${state.nearbyLetters.length}',
              label: l10n.mapNearby,
              onTap: onShowNearby,
              // Build 144: 근처 편지가 있을 때 primary 강조 (main action)
              highlight: state.nearbyLetters.isNotEmpty,
              primary: true,
            ),
            _Divider(),
            _StatBtn(
              icon: '📬',
              value: '${state.inbox.length}',
              label: l10n.mapReceivedLetters,
              onTap: onGoToInbox,
              highlight: state.unreadCount > 0,
              badge: state.unreadCount > 0 ? '${state.unreadCount}' : null,
            ),
            _Divider(),
            _StatBtn(
              icon: '✍️',
              value: '${state.sent.length}',
              label: l10n.mapSentLetters,
              onTap: onGoToInbox,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBtn extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final VoidCallback? onTap;
  final bool highlight;
  final String? badge;
  final bool primary; // Build 144: primary 액션 (📍 근처) 전용 강조

  const _StatBtn({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
    this.highlight = false,
    this.badge,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeColors = AppTimeColors.of(context);
    final active = onTap != null;
    // Build 144: primary (근처) 지표는 크기·폰트 한 단계 상승, 터치 타겟도
    // 확보. 다른 지표는 secondary 톤 다운. 접근성을 위해 최소 44pt 높이.
    final valueFont = primary ? 14.5 : 12.5;
    final labelFont = primary ? 9.5 : 9.0;
    final iconFont = primary ? 15.0 : 13.0;
    // Build 161: Semantics — "근처 3통" 같은 full-sentence 라벨 제공.
    return Semantics(
      label: '$label · $value',
      button: active,
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: highlight
              ? (primary
                  ? AppColors.teal.withValues(alpha: 0.14)
                  : AppColors.gold.withValues(alpha: 0.10))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: TextStyle(fontSize: iconFont)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: highlight
                        ? (primary ? AppColors.teal : AppColors.gold)
                        : active
                            ? (primary
                                ? timeColors.accent
                                : AppColors.textSecondary)
                            : AppColors.textMuted,
                    fontSize: valueFont,
                    fontWeight:
                        primary ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: active
                        ? AppColors.textMuted.withValues(alpha: 0.85)
                        : AppColors.textMuted.withValues(alpha: 0.5),
                    fontSize: labelFont,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                right: -4,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: AppColors.bgDeep,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.textMuted.withValues(alpha: 0.15),
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

/// Build 128 — Brand 공식 발송인 전용: 원래의 타워 비주얼 복원.
/// 레벨 시스템(XP/캐릭터 진화/아이템/동반자) 밖이므로, 사각형 타워 본체 +
/// 티어 이모지 + 플래그 + 층수(floors) 만 표시. Build 121 이전과 동일.
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
        return const Color(0xFFFF6B9D);
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
                    Text(tier.emoji, style: const TextStyle(fontSize: 18)),
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
                    color: const Color(0xFFFF6B35),
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
    if (isBrand) return const Color(0xFFFF8A5C);
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
                    color: const Color(0xFFFF6B35),
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
