import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/time_theme.dart';
import '../../../models/letter.dart';
import '../../../models/user_profile.dart';
import '../../../state/app_state.dart';

// ── 지도 위 다른 회원 타워 목업 ─────────────────────────────────────────────────
class _MapTowerUser {
  final String flag;
  final double lat;
  final double lng;
  final TowerTier tier;
  final int floors;
  final int rank;
  const _MapTowerUser(
    this.flag,
    this.lat,
    this.lng,
    this.tier,
    this.floors,
    this.rank,
  );
}

const _mapTowers = [
  _MapTowerUser('🇯🇵', 35.6580, 139.7016, TowerTier.landmark, 83, 1),
  _MapTowerUser('🇧🇷', -23.5567, -46.6891, TowerTier.landmark, 67, 2),
  _MapTowerUser('🇨🇳', 31.2207, 121.4728, TowerTier.skyscraper, 55, 3),
  _MapTowerUser('🇺🇸', 40.7580, -73.9855, TowerTier.skyscraper, 47, 4),
  _MapTowerUser('🇫🇷', 48.8570, 2.3520, TowerTier.building, 31, 5),
  _MapTowerUser('🇬🇧', 51.5228, -0.0780, TowerTier.building, 22, 6),
  _MapTowerUser('🇩🇪', 52.5381, 13.4175, TowerTier.house, 12, 7),
  _MapTowerUser('🇦🇺', -33.8853, 151.2094, TowerTier.house, 9, 8),
  _MapTowerUser('🇮🇳', 28.6315, 77.2167, TowerTier.cottage, 5, 9),
];

class WorldMapScreen extends StatefulWidget {
  final VoidCallback? onGoToInbox;
  const WorldMapScreen({super.key, this.onGoToInbox});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin {
  static const String _stadiaApiKey = String.fromEnvironment(
    'STADIA_MAPS_API_KEY',
    defaultValue: '',
  );
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  Timer? _positionTimer; // 실시간 편지 위치 갱신용 1초 타이머
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
    // 1초마다 setState → 편지 마커 위치가 sentAt~arrivalTime 기반으로 부드럽게 이동
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  bool get _useStadiaTiles {
    final key = _stadiaApiKey.trim();
    if (key.isEmpty) return false;
    final lower = key.toLowerCase();
    if (lower.contains('your_') || lower.contains('placeholder')) {
      return false;
    }
    return key.length >= 20;
  }

  String _toMapLang(String langCode) {
    const supported = {
      'ko',
      'ja',
      'zh',
      'en',
      'fr',
      'de',
      'es',
      'pt',
      'it',
      'ru',
      'ar',
      'hi',
      'th',
      'tr',
      'nl',
      'pl',
    };
    return supported.contains(langCode) ? langCode : 'local';
  }

  String _tileUrl(String langCode, {required bool darkMode}) {
    if (_useStadiaTiles) {
      final lang = _toMapLang(langCode);
      final style = darkMode ? 'alidade_smooth_dark' : 'alidade_smooth';
      return 'https://tiles.stadiamaps.com/tiles/$style/{z}/{x}/{y}.png?api_key=$_stadiaApiKey&language=$lang';
    }
    return darkMode
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
  }

  List<String> _tileSubdomains() =>
      _useStadiaTiles ? const [] : const ['a', 'b', 'c', 'd'];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        // 지도에는 배송중(inTransit/nearYou) 편지만 표시
        final letters = _showNearbyOnly
            ? state.nearbyLetters
            : state.worldLetters
                  .where(
                    (l) =>
                        l.status == DeliveryStatus.inTransit ||
                        l.status == DeliveryStatus.nearYou,
                  )
                  .toList();
        final timeColors = AppTimeColors.of(context);
        final period = state.activeTimePeriod;
        final langCode = state.currentUser.languageCode;
        final darkMode = period == TimeOfDayPeriod.night;

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
              ),
              children: [
                // ── 기반 타일 (모드 연동: 밝은/다크/자동) ─────────────────
                TileLayer(
                  urlTemplate: _tileUrl(langCode, darkMode: darkMode),
                  subdomains: _tileSubdomains(),
                  userAgentPackageName: 'com.globaldrift.miab',
                  maxZoom: 19,
                  maxNativeZoom: 19,
                ),
                // ── 배송 경로선 ────────────────────────────────────────────
                if (_showRouteLines)
                  PolylineLayer(polylines: _buildRoutePolylines(letters)),
                // ── 허브 마커 ─────────────────────────────────────────────
                MarkerLayer(markers: _buildHubMarkers(letters)),
                // ── 회원 타워 마커 ─────────────────────────────────────────
                if (_showTowers)
                  MarkerLayer(markers: _buildMapTowerMarkers(context, state)),
                // ── 편지(운송수단) 마커 ────────────────────────────────────
                MarkerLayer(markers: _buildLetterMarkers(letters, state)),
                // ── 500m 반경 원 ──────────────────────────────────────────
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: ll.LatLng(
                        state.currentUser.latitude,
                        state.currentUser.longitude,
                      ),
                      radius: 500,
                      useRadiusInMeter: true,
                      color: timeColors.accent.withValues(alpha: 0.08),
                      borderColor: timeColors.accent.withValues(alpha: 0.35),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              ],
            ),
            // ── 상단 헤더 ──────────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _MapHeader(
                showNearbyOnly: _showNearbyOnly,
                letterCount: state.worldLetters.length,
                nearbyCount: state.nearbyLetters.length,
                inTransitCount: state.totalInTransitCount,
                period: period,
                onToggleNearby: () =>
                    setState(() => _showNearbyOnly = !_showNearbyOnly),
              ),
            ),
            // ── 근처 도착 배너 ─────────────────────────────────────────────
            if (state.hasNearbyAlert)
              Positioned(
                top: 130,
                left: 16,
                right: 16,
                child: _NearbyAlertBanner(
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
                    tooltip: '전체보기',
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
  List<Marker> _buildLetterMarkers(List<Letter> letters, AppState state) {
    final markers = <Marker>[];

    // 내 타워 마커 (탭하면 내 랭킹 정보)
    markers.add(
      Marker(
        point: ll.LatLng(
          state.currentUser.latitude,
          state.currentUser.longitude,
        ),
        width: 64,
        height: 80,
        child: GestureDetector(
          onTap: () => _showMyTowerInfo(context, state),
          child: _MyTowerMarker(
            tier: state.currentUser.activityScore.tier,
            flag: state.currentUser.countryFlag,
            floors: state.currentUser.activityScore.towerFloors,
            pulseController: _pulseController,
          ),
        ),
      ),
    );

    final now = DateTime.now();
    for (final letter in letters) {
      if (letter.status != DeliveryStatus.inTransit &&
          letter.status != DeliveryStatus.nearYou &&
          letter.status != DeliveryStatus.deliveredFar)
        continue;
      // 실시간 위치: sentAt~arrivalTime 기반 보간 (arrivalTime 없으면 기존 currentLocation)
      final pos = letter.status == DeliveryStatus.deliveredFar
          ? letter.destinationLocation
          : letter.currentPositionAt(now);
      markers.add(
        Marker(
          point: ll.LatLng(pos.latitude, pos.longitude),
          width: letter.status == DeliveryStatus.nearYou ? 48 : 36,
          height: letter.status == DeliveryStatus.nearYou ? 48 : 36,
          child: GestureDetector(
            onTap: () => _onLetterTap(context, letter, state),
            child: _TransportMarker(
              letter: letter,
              pulseController: _pulseController,
            ),
          ),
        ),
      );
      // 도착지 핀 마커 추가
      final destLoc = letter.destinationLocation;
      markers.add(
        Marker(
          point: ll.LatLng(destLoc.latitude, destLoc.longitude),
          width: 36,
          height: 42,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.bgCard.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    letter.destinationCountryFlag,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 8,
                color: AppColors.gold.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      );
    }
    return markers;
  }

  // ── 지도 타워 마커 (내 타워 + 다른 회원) ─────────────────────────────────────
  List<Marker> _buildMapTowerMarkers(BuildContext context, AppState state) {
    final markers = <Marker>[];

    // 다른 회원 타워
    for (final u in _mapTowers) {
      final tierColor = _towerTierColor(u.tier);
      final rankLabel = u.rank <= 3
          ? (u.rank == 1
                ? '🥇'
                : u.rank == 2
                ? '🥈'
                : '🥉')
          : '#${u.rank}';
      markers.add(
        Marker(
          point: ll.LatLng(u.lat, u.lng),
          width: 52,
          height: 64,
          child: GestureDetector(
            onTap: () => _showMapTowerDetail(context, u, null),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: tierColor.withValues(alpha: 0.75),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tierColor.withValues(alpha: 0.3),
                        blurRadius: 8,
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
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(u.flag, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                // 랭킹 뱃지 (고정 높이)
                SizedBox(
                  height: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        rankLabel,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
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

  Color _towerTierColor(TowerTier tier) {
    switch (tier) {
      case TowerTier.cottage:
        return const Color(0xFFCD7F32);
      case TowerTier.house:
        return const Color(0xFFC0C0C0);
      case TowerTier.building:
        return AppColors.gold;
      case TowerTier.skyscraper:
        return AppColors.teal;
      case TowerTier.landmark:
        return const Color(0xFFFF6B9D);
    }
  }

  int _myTowerRank(AppState state) {
    final myFloors = state.currentUser.activityScore.towerFloors;
    final higherCount = _mapTowers.where((u) => u.floors > myFloors).length;
    return higherCount + 1;
  }

  String _rankLabel(int rank) {
    if (rank == 1) return '🥇 1위';
    if (rank == 2) return '🥈 2위';
    if (rank == 3) return '🥉 3위';
    return '🌍 ${rank}위';
  }

  void _showMyTowerInfo(BuildContext ctx, AppState state) {
    _showMapTowerDetail(ctx, null, state);
  }

  void _showMapTowerDetail(
    BuildContext ctx,
    _MapTowerUser? other,
    AppState? myState,
  ) {
    // 데이터 추출 (다른 유저 or 내 타워)
    final flag = other?.flag ?? (myState?.currentUser.countryFlag ?? '🏠');
    final tier =
        other?.tier ??
        (myState?.currentUser.activityScore.tier ?? TowerTier.cottage);
    final floors =
        other?.floors ?? (myState?.currentUser.activityScore.towerFloors ?? 1);
    final rank = other?.rank ?? (myState != null ? _myTowerRank(myState) : 0);
    final tierColor = _towerTierColor(tier);
    final rankLabel = _rankLabel(rank);
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
                            '${tier.emoji}  ${tier.label}',
                            style: TextStyle(
                              color: tierColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          other == null ? '내 타워' : '커뮤니티 타워',
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
                          const Text(
                            '세계 랭킹',
                            style: TextStyle(
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
                          const Text(
                            '건물 층수',
                            style: TextStyle(
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
                        const Text(
                          '타워 높이',
                          style: TextStyle(
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
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ), // Container
      ), // SingleChildScrollView
    );
  }

  void _onLetterTap(BuildContext ctx, Letter letter, AppState state) {
    if (letter.status == DeliveryStatus.nearYou) {
      _showPickupDialog(ctx, letter, state);
    } else if (letter.status == DeliveryStatus.deliveredFar) {
      _showDeliveredFarDialog(ctx, letter);
    } else {
      _showTransitInfo(ctx, letter);
    }
  }

  void _showDeliveredFarDialog(BuildContext ctx, Letter letter) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Text(
          '📬 편지가 도착했어요!\n이 위치를 직접 방문해야 열어볼 수 있어요.',
          style: TextStyle(
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
            child: const Text('닫기', style: TextStyle(color: AppColors.bgDeep)),
          ),
        ],
      ),
    );
  }

  void _showPickupDialog(BuildContext ctx, Letter letter, AppState state) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PickupSheet(
        letter: letter,
        onPickup: () {
          final success = state.pickUpLetter(letter.id);
          Navigator.pop(ctx);
          if (success) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(
                  '📩  ${letter.senderCountryFlag} ${letter.senderCountry}에서 온 편지를 받았어요!',
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
                content: const Text('📍 편지 수령지 500m 이내에 있어야 받을 수 있어요'),
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

  void _showTransitInfo(BuildContext ctx, Letter letter) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TransitInfoSheet(letter: letter),
    );
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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bgCard,
            border: Border.all(
              color: timeColors.accent.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: timeColors.accent, size: 22),
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
            const SnackBar(
              content: Text('위치 권한이 필요합니다. 설정에서 허용해주세요.'),
              backgroundColor: Color(0xFF1F2D44),
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
          const SnackBar(
            content: Text('위치를 가져올 수 없어요. 잠시 후 다시 시도해주세요.'),
            backgroundColor: Color(0xFF1F2D44),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _goToMyLocation(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bgCard,
          border: Border.all(
            color: AppColors.teal.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
        final phase = (pulseController.value * 2 * pi) % (2 * pi);
        final pulse = (sin(phase) * 0.5 + 0.5);
        // 유저가 고른 이모티콘 우선 사용, 없으면 운송수단 기본 이모티콘
        final emoji = isNearby
            ? '📩'
            : (letter.deliveryEmoji ?? letter.currentTransport.emoji);
        final color = isNearby
            ? AppColors.gold
            : letter.currentTransport == TransportMode.truck
            ? AppColors.gold
            : letter.currentTransport == TransportMode.airplane
            ? AppColors.teal
            : const Color(0xFF60A5FA);
        final seg = letter.currentSegment;
        final bearing = _bearing(seg.from, seg.to);
        final rotationAngle = isNearby
            ? 0.0
            : bearing - letter.currentTransport.headingOffsetRadians;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (isNearby)
              Container(
                width: 40 + pulse * 6,
                height: 40 + pulse * 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.3 + pulse * 0.3),
                    width: 1.5,
                  ),
                ),
              ),
            Container(
              width: isNearby ? 36 : 28,
              height: isNearby ? 36 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgCard.withValues(alpha: 0.92),
                border: Border.all(
                  color: color.withValues(alpha: isNearby ? 0.7 : 0.45),
                  width: isNearby ? 2.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(
                      alpha: isNearby ? 0.4 + pulse * 0.2 : 0.2,
                    ),
                    blurRadius: isNearby ? 12 : 6,
                    spreadRadius: isNearby ? 2 : 0,
                  ),
                ],
              ),
              child: Center(
                child: Transform.rotate(
                  angle: rotationAngle,
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: isNearby ? 18 : 14),
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

// ── 상단 헤더 ──────────────────────────────────────────────────────────────────
class _MapHeader extends StatelessWidget {
  final bool showNearbyOnly;
  final int letterCount;
  final int nearbyCount;
  final int inTransitCount;
  final TimeOfDayPeriod period;
  final VoidCallback onToggleNearby;

  const _MapHeader({
    required this.showNearbyOnly,
    required this.letterCount,
    required this.nearbyCount,
    required this.inTransitCount,
    required this.period,
    required this.onToggleNearby,
  });

  String get _periodLabel {
    switch (period) {
      case TimeOfDayPeriod.morning:
        return '🌅 새벽';
      case TimeOfDayPeriod.day:
        return '☀️ 낮';
      case TimeOfDayPeriod.evening:
        return '🌆 저녁';
      case TimeOfDayPeriod.night:
        return '🌙 밤';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeColors = AppTimeColors.of(context);
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
                    tooltip: '배송중 편지',
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    label: '📍 $nearbyCount',
                    color: AppColors.gold,
                    active: showNearbyOnly,
                    onTap: onToggleNearby,
                    tooltip: '500m 근처',
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    label: '🌍 $letterCount',
                    color: AppColors.textMuted,
                    active: false,
                    onTap: null,
                    tooltip: '전체 편지',
                  ),
                ],
              ),
            ],
          ),
        ),
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
class _NearbyAlertBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NearbyAlertBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Text('📩', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '편지 $count개가 근처에 도착했어요!  탭해서 확인',
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
    );
  }
}

// ── 픽업 시트 ──────────────────────────────────────────────────────────────────
class _PickupSheet extends StatelessWidget {
  final Letter letter;
  final VoidCallback onPickup;
  const _PickupSheet({required this.letter, required this.onPickup});

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
            '${letter.senderCountryFlag} ${letter.senderCountry}에서 온 편지',
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
              child: const Text(
                '편지 수령하기',
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
  final Letter letter;
  const _TransitInfoSheet({required this.letter});

  Color _segColor(bool isDone, bool isActive) {
    if (isDone) return AppColors.textMuted;
    if (isActive) return AppColors.teal;
    return AppColors.textMuted.withValues(alpha: 0.35);
  }

  String _durLabel(int minutes) {
    if (minutes < 60) return '${minutes}분';
    final h = (minutes / 60).round();
    return '약 ${h}시간';
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
                        '현재: ${seg.fromName} → ${seg.toName}',
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
                  '전체 진행률 ${(letter.overallProgress * 100).round()}%',
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
            const Text(
              '배송 경로',
              style: TextStyle(
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
                            '${s.fromName} → ${s.toName}',
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
                        child: const Text(
                          '이동중',
                          style: TextStyle(
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
  final AppState state;
  final MapController mapController;
  final double userLat;
  final double userLng;
  final VoidCallback onShowAll;
  final VoidCallback onShowNearby;
  final VoidCallback? onGoToInbox;

  const _StatsBar({
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
            label: '전체 편지',
            onTap: onShowAll,
          ),
          _Divider(),
          // 근처 → 내 위치로 이동 + 근처 편지 필터
          _StatBtn(
            icon: '📍',
            value: '${state.nearbyLetters.length}',
            label: '근처',
            onTap: onShowNearby,
          ),
          _Divider(),
          // 받은 편지 → 편지함 탭으로 이동
          _StatBtn(
            icon: '📬',
            value: '${state.inbox.length}',
            label: '받은 편지',
            onTap: onGoToInbox,
            highlight: state.unreadCount > 0,
            badge: state.unreadCount > 0 ? '${state.unreadCount}' : null,
          ),
          _Divider(),
          // 보낸 편지 → 편지함 탭으로 이동
          _StatBtn(
            icon: '✍️',
            value: '${state.sent.length}',
            label: '보낸 편지',
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

class _MyTowerMarker extends StatelessWidget {
  final TowerTier tier;
  final String flag;
  final int floors;
  final AnimationController pulseController;
  const _MyTowerMarker({
    required this.tier,
    required this.flag,
    required this.floors,
    required this.pulseController,
  });

  Color _tierColor() {
    switch (tier) {
      case TowerTier.cottage:
        return const Color(0xFFCD7F32);
      case TowerTier.house:
        return const Color(0xFFC0C0C0);
      case TowerTier.building:
        return AppColors.gold;
      case TowerTier.skyscraper:
        return AppColors.teal;
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
                    Text(flag, style: const TextStyle(fontSize: 12)),
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
          ],
        );
      },
    );
  }
}
