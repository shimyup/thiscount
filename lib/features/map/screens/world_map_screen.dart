import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/map_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/time_theme.dart';
import '../../../models/letter.dart';
import '../../../models/user_profile.dart';
import '../../../state/app_state.dart';

// 목업 타워 데이터 제거 → AppState.mapUsers (Firestore 실시간) 사용

class WorldMapScreen extends StatefulWidget {
  final VoidCallback? onGoToInbox;
  const WorldMapScreen({super.key, this.onGoToInbox});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin {
  static const String _permissionDialogDateKey =
      'world_map_permission_denied_forever_prompt_date';
  static const double _towerLabelZoomThreshold = 4.8;

  // 타일 설정은 MapConfig에서 중앙 관리 (lib/core/config/map_config.dart)
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  Timer? _positionTimer; // 실시간 편지 위치 갱신용 1초 타이머
  Timer? _mapRefreshTimer; // 5분마다 타워 목록 갱신
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
      // 유저 위치가 기본값(서울)이 아니면 유저 위치로 자동 이동
      final lat = state.currentUser.latitude;
      final lng = state.currentUser.longitude;
      final isDefault = (lat - 37.5665).abs() < 0.001 && (lng - 126.978).abs() < 0.001;
      if (lat != 0 && lng != 0) {
        _mapController.move(
          ll.LatLng(lat, lng),
          isDefault ? 5.0 : 11.0, // 기본 위치면 넓게, 실제 위치면 가깝게
        );
      }
    });
    // 15분마다 타워 목록 자동 갱신 (과도한 네트워크 호출 방지)
    _mapRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (mounted) context.read<AppState>().fetchMapUsers();
    });
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _mapRefreshTimer?.cancel();
    _tickNotifier.dispose();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
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
        final period = state.activeTimePeriod;
        final mapLangCode = MapConfig.resolveMapLanguage(
          country: state.currentUser.country,
          appLanguageCode: state.currentUser.languageCode,
        );
        const darkMode = false; // 지도는 항상 밝은 타일 고정 (밤/다크모드 무관)

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
                  userAgentPackageName: 'com.globaldrift.miab',
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
                    userAgentPackageName: 'com.globaldrift.miab',
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
                // ── 회원 타워 마커 ─────────────────────────────────────────
                if (_showTowers)
                  MarkerLayer(
                    markers: _buildMapTowerMarkers(
                      context,
                      state,
                      l10n,
                      showLabels: _showTowerLabels,
                      zoom: _lastKnownZoom,
                    ),
                  ),
                // ── 편지(운송수단) 마커 ────────────────────────────────────
                ValueListenableBuilder<int>(
                  valueListenable: _tickNotifier,
                  builder: (context, tick, child) {
                    return MarkerLayer(
                      markers: _buildLetterMarkers(letters, state, l10n, langCode),
                    );
                  },
                ),
                // ── 2km 반경 원 ──────────────────────────────────────────
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
              child: _MapHeader(
                l10n: l10n,
                showNearbyOnly: _showNearbyOnly,
                letterCount: state.worldLetters.length,
                nearbyCount: state.nearbyLetters.length,
                inTransitCount: state.totalInTransitCount,
                mapUsersCount: state.mapUsers.length,
                period: period,
                mapLanguageLabel: MapConfig.mapLanguageLabel(mapLangCode),
                isUnifiedLanguageMode: MapConfig.isUnifiedLanguageMode,
                mapProviderLabel: MapConfig.tileProviderLabel,
                showTowerLabels: _showTowerLabels,
                currentZoom: _lastKnownZoom,
                onToggleNearby: () =>
                    setState(() => _showNearbyOnly = !_showNearbyOnly),
              ),
            ),
            // ── 근처 도착 배너 ─────────────────────────────────────────────
            if (state.hasNearbyAlert)
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
  List<Marker> _buildLetterMarkers(List<Letter> letters, AppState state, AppL10n l10n, String langCode) {
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
          onTap: () => overlappingLetters.isNotEmpty
              ? _showTowerLetterDisambiguation(
                  context,
                  state,
                  overlappingLetters,
                  l10n,
                  langCode,
                )
              : _showMyTowerInfo(context, state, l10n),
          child: _MyTowerMarker(
            tier: state.currentUser.activityScore.tier,
            flag: state.currentUser.countryFlag,
            floors: state.currentUser.activityScore.towerFloors,
            pulseController: _pulseController,
            pendingLetterCount: overlappingLetters.length,
          ),
        ),
      ),
    );

    final now = DateTime.now();
    final viewerIsPremiumOrBrand =
        state.currentUser.isPremium || state.currentUser.isBrand;

    for (final letter in letters) {
      // 도착 후 미열람 편지: 도착지에 '📮 대기중' 마커로 표시
      if (letter.status == DeliveryStatus.delivered &&
          !letter.isReadByRecipient) {
        final destLoc = letter.destinationLocation;
        final isBrandLetter = letter.senderTier == LetterSenderTier.brand;
        markers.add(
          Marker(
            point: ll.LatLng(destLoc.latitude, destLoc.longitude),
            width: 40,
            height: isBrandLetter && viewerIsPremiumOrBrand ? 62 : 48,
            child: GestureDetector(
              onTap: () => _onLetterTap(context, letter, state, l10n, langCode),
              child: _UnreadDeliveredMarker(
                letter: letter,
                pulseController: _pulseController,
                viewerIsPremiumOrBrand: viewerIsPremiumOrBrand,
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
        markers.add(
          Marker(
            point: ll.LatLng(destLoc.latitude, destLoc.longitude),
            width: 40,
            height: isBrandLetter && viewerIsPremiumOrBrand ? 62 : 48,
            child: GestureDetector(
              onTap: () => _onLetterTap(context, letter, state, l10n, langCode),
              child: _UnreadDeliveredMarker(
                letter: letter,
                pulseController: _pulseController,
                viewerIsPremiumOrBrand: viewerIsPremiumOrBrand,
              ),
            ),
          ),
        );
        continue;
      }

      if (letter.status != DeliveryStatus.inTransit &&
          letter.status != DeliveryStatus.deliveredFar)
        continue;
      // 실시간 위치: sentAt~arrivalTime 기반 보간 (arrivalTime 없으면 기존 currentLocation)
      final pos = letter.status == DeliveryStatus.deliveredFar
          ? letter.destinationLocation
          : letter.currentPositionAt(now);
      markers.add(
        Marker(
          point: ll.LatLng(pos.latitude, pos.longitude),
          width: letter.status == DeliveryStatus.deliveredFar ? 48 : 36,
          height: letter.status == DeliveryStatus.deliveredFar ? 48 : 36,
          child: GestureDetector(
            onTap: () => _onLetterTap(context, letter, state, l10n, langCode),
            child: _TransportMarker(
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
  List<Marker> _buildMapTowerMarkers(
    BuildContext context,
    AppState state,
    AppL10n l10n, {
    required bool showLabels,
    required double zoom,
  }) {
    final markers = <Marker>[];

    // 줌 레벨별 크기 스케일 (줌아웃 시 작게, 줌인 시 크게)
    final scale = (zoom / 10.0).clamp(0.5, 1.2);
    final markerW = (40 * scale).roundToDouble();
    final markerH = (44 * scale).roundToDouble();
    final emojiSize = 16.0 * scale;
    final flagSize = 10.0 * scale;
    final borderRadius = 10.0 * scale;
    final borderWidth = 1.8 * scale;

    // 자동 오프셋: 가까운 타워들을 원형으로 퍼뜨림
    final users = state.mapUsers;
    final offsets = _computeTowerOffsets(users, zoom);

    // 실제 회원 타워 (Firestore)
    for (int i = 0; i < users.length; i++) {
      final u = users[i];
      final offset = offsets[i];
      final tierColor = _towerTierColor(u.tier);
      final rankLabel = u.rank <= 3
          ? (u.rank == 1
                ? '🥇'
                : u.rank == 2
                ? '🥈'
                : '🥉')
          : '#${u.rank}';
      final hasUsername = u.username != null && u.username!.isNotEmpty;
      final displayLabel = u.towerName?.isNotEmpty == true
          ? u.towerName!
          : (hasUsername ? '@${u.username}' : null);
      final labelText = displayLabel ?? '';
      final hasLabel = showLabels && labelText.isNotEmpty;
      final totalW = hasLabel ? markerW + 32 : markerW + 12;
      final totalH = hasLabel ? markerH + 34 : markerH + 20;
      markers.add(
        Marker(
          point: ll.LatLng(u.lat + offset.dy, u.lng + offset.dx),
          width: totalW,
          height: totalH,
          child: GestureDetector(
            onTap: () => _showMapTowerDetail(context, u, null, l10n),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: markerW,
                  height: markerH,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: tierColor.withValues(alpha: 0.75),
                      width: borderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tierColor.withValues(alpha: 0.3),
                        blurRadius: 8 * scale,
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          u.tier.emoji,
                          style: TextStyle(fontSize: emojiSize),
                        ),
                        Text(u.flag, style: TextStyle(fontSize: flagSize)),
                      ],
                    ),
                  ),
                ),
                // 랭킹 뱃지 (고정 높이)
                SizedBox(
                  height: 16 * scale,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 5 * scale),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(5 * scale),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        rankLabel,
                        style: TextStyle(
                          fontSize: 9 * scale,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                // 타워 이름 또는 닉네임 표시
                if (hasLabel)
                  SizedBox(
                    height: 14,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labelText,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
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
    return markers;
  }

  /// 겹치는 타워들을 원형으로 퍼뜨리는 오프셋 계산
  List<Offset> _computeTowerOffsets(List<MapUser> users, double zoom) {
    final offsets = List<Offset>.filled(users.length, Offset.zero);
    // 줌 레벨에 따라 "겹침" 판정 거리 조절 (줌아웃일수록 넓게)
    final threshold = 0.8 / pow(2, zoom - 3).clamp(0.1, 1000);

    for (int i = 0; i < users.length; i++) {
      // 이 타워와 겹치는 다른 타워 인덱스 수집
      final cluster = <int>[i];
      for (int j = 0; j < users.length; j++) {
        if (i == j) continue;
        final dLat = users[i].lat - users[j].lat;
        final dLng = users[i].lng - users[j].lng;
        if (dLat * dLat + dLng * dLng < threshold * threshold) {
          cluster.add(j);
        }
      }
      if (cluster.length <= 1) continue; // 겹침 없음

      // 클러스터 내 순서를 기반으로 원형 배치
      final idx = cluster.indexOf(i);
      final count = cluster.length;
      final angle = (2 * pi * idx / count) - pi / 2;
      final radius = threshold * 0.6;
      offsets[i] = Offset(cos(angle) * radius, sin(angle) * radius);
    }
    return offsets;
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
                  icon: '📮',
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
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          '📬 ${l10n.mapLetterArrivedVisitToOpen}',
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
    return Tooltip(
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

        // nearYou: 📩, deliveredFar: 📬 (도착 대기), inTransit: 운송수단 이모티콘
        final emoji = isNearby
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

  const _UnreadDeliveredMarker({
    required this.letter,
    required this.pulseController,
    this.viewerIsPremiumOrBrand = false,
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

        // 등급별 글로우 색상
        final glowColor = showAsBrand
            ? const Color(0xFFFF8A5C)
            : showAsPremium
            ? AppColors.gold
            : Colors.white;

        // 편지함 컨테이너 배경색
        final boxBg = showAsBrand
            ? const Color(0xFF3A1F10).withValues(alpha: 0.95)
            : showAsPremium
            ? const Color(0xFF2A2108).withValues(alpha: 0.95)
            : AppColors.bgCard.withValues(alpha: 0.92);

        // 이모지: 브랜드(프리미엄 뷰어)=📪, 프리미엄/브랜드(무료뷰어)=💌, 일반=📮
        final mailEmoji = showAsBrand
            ? '📪'
            : showAsPremium
            ? '💌'
            : '📮';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
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
                // 편지함 아이콘 컨테이너
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: boxBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: glowColor.withValues(alpha: 0.55 + pulse * 0.3),
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

// ── 상단 헤더 ──────────────────────────────────────────────────────────────────
class _MapHeader extends StatelessWidget {
  final AppL10n l10n;
  final bool showNearbyOnly;
  final int letterCount;
  final int nearbyCount;
  final int inTransitCount;
  final int mapUsersCount;
  final TimeOfDayPeriod period;
  final String mapLanguageLabel;
  final bool isUnifiedLanguageMode;
  final String mapProviderLabel;
  final bool showTowerLabels;
  final double currentZoom;
  final VoidCallback onToggleNearby;

  const _MapHeader({
    required this.l10n,
    required this.showNearbyOnly,
    required this.letterCount,
    required this.nearbyCount,
    required this.inTransitCount,
    required this.mapUsersCount,
    required this.period,
    required this.mapLanguageLabel,
    required this.isUnifiedLanguageMode,
    required this.mapProviderLabel,
    required this.showTowerLabels,
    required this.currentZoom,
    required this.onToggleNearby,
  });

  String get _periodLabel {
    switch (period) {
      case TimeOfDayPeriod.morning:
        return '🌅 ${l10n.mapDawn}';
      case TimeOfDayPeriod.day:
        return '☀️ ${l10n.mapDay}';
      case TimeOfDayPeriod.evening:
        return '🌆 ${l10n.mapEvening}';
      case TimeOfDayPeriod.night:
        return '🌙 ${l10n.mapNight}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeColors = AppTimeColors.of(context);
    final socialProofLabel = mapUsersCount > 0
        ? 'LIVE ${l10n.mapLiveExploring(mapUsersCount, inTransitCount)}'
        : 'LIVE ${l10n.mapSyncingData}';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            timeColors.bgDeep.withValues(alpha: 0.97),
            timeColors.bgDeep.withValues(alpha: 0.0),
          ],
          stops: const [0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: timeColors.bgCard.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: timeColors.accent.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 시간대 + 앱 이름
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _periodLabel,
                          style: TextStyle(
                            color: timeColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Text(
                          'Letter Go',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // GLOBAL FLOW 카드 (Stitch AI 추천)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1421).withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'GLOBAL FLOW',
                            style: TextStyle(
                              color: AppColors.teal,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$inTransitCount',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          socialProofLabel,
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (isUnifiedLanguageMode)
                      _MapMetaChip(
                        icon: Icons.translate_rounded,
                        text: '${l10n.mapMapLanguage}: $mapLanguageLabel',
                      ),
                    _MapMetaChip(
                      icon: Icons.layers_rounded,
                      text:
                          '$mapProviderLabel · ${l10n.mapZoom} ${currentZoom.toStringAsFixed(1)}',
                    ),
                    _MapMetaChip(
                      icon: Icons.location_city_rounded,
                      text: showTowerLabels ? '${l10n.mapTowerLabel} ON' : '${l10n.mapTowerLabel} OFF',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 통계 칩
                Row(
                  children: [
                    _StatChip(
                      label: '✈️ $inTransitCount',
                      color: AppColors.teal,
                      active: !showNearbyOnly,
                      onTap: onToggleNearby,
                      tooltip: l10n.mapInTransitLetters,
                    ),
                    const SizedBox(width: 6),
                    _StatChip(
                      label: '📍 $nearbyCount',
                      color: AppColors.gold,
                      active: showNearbyOnly,
                      onTap: onToggleNearby,
                      tooltip: l10n.mapNearby2km,
                    ),
                    const SizedBox(width: 6),
                    _StatChip(
                      label: '🌍 $letterCount',
                      color: AppColors.textMuted,
                      active: false,
                      onTap: null,
                      tooltip: l10n.mapAllLetters,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapMetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MapMetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback? onTap;
  final String tooltip;

  const _StatChip({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
    this.tooltip = '',
  });

  void _showTooltip(BuildContext ctx) {
    if (tooltip.isEmpty) return;
    final overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    final box = ctx.findRenderObject() as RenderBox?;
    final pos =
        box?.localToGlobal(Offset.zero, ancestor: overlay) ?? Offset.zero;
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: pos.dx,
        top: pos.dy + 36,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              tooltip,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(ctx).insert(entry);
    Future.delayed(const Duration(seconds: 2), entry.remove);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (tooltip.isNotEmpty) _showTooltip(context);
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.15)
              : AppColors.bgCard.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.5)
                : AppColors.textMuted.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : AppColors.textMuted,
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: timeColors.bgCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: timeColors.accent.withValues(alpha: 0.15)),
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
          // 전체 편지 → 지도 전체 보기
          _StatBtn(
            icon: '✈️',
            value: '${state.totalInTransitCount}',
            label: l10n.mapAllLetters,
            onTap: onShowAll,
          ),
          _Divider(),
          // 근처 → 내 위치로 이동 + 근처 편지 필터
          _StatBtn(
            icon: '📍',
            value: '${state.nearbyLetters.length}',
            label: l10n.mapNearby,
            onTap: onShowNearby,
          ),
          _Divider(),
          // 받은 편지 → 편지함 탭으로 이동
          _StatBtn(
            icon: '📬',
            value: '${state.inbox.length}',
            label: l10n.mapReceivedLetters,
            onTap: onGoToInbox,
            highlight: state.unreadCount > 0,
            badge: state.unreadCount > 0 ? '${state.unreadCount}' : null,
          ),
          _Divider(),
          // 보낸 편지 → 편지함 탭으로 이동
          _StatBtn(
            icon: '✍️',
            value: '${state.sent.length}',
            label: l10n.mapSentLetters,
            onTap: onGoToInbox,
          ),
        ],
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

  const _StatBtn({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
    this.highlight = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final timeColors = AppTimeColors.of(context);
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.gold.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: highlight
                        ? AppColors.gold
                        : active
                        ? timeColors.accent
                        : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: active
                        ? AppColors.textMuted
                        : AppColors.textMuted.withValues(alpha: 0.5),
                    fontSize: 9,
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
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
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

class _MyTowerMarker extends StatelessWidget {
  final TowerTier tier;
  final String flag;
  final int floors;
  final AnimationController pulseController;
  final int pendingLetterCount; // 타워 위치에 겹친 수령 가능 편지 수
  const _MyTowerMarker({
    required this.tier,
    required this.flag,
    required this.floors,
    required this.pulseController,
    this.pendingLetterCount = 0,
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
            // 펄스 링
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
            // 타워 마커 본체
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
                    Text(
                      pendingLetterCount > 0 ? '📮' : flag,
                      style: TextStyle(
                        fontSize: pendingLetterCount > 0 ? 12 : 10,
                      ),
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
            // 📮 뱃지: 타워 위치에 겹친 편지가 있을 때 우상단에 표시
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
