import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import '../../../core/config/map_config.dart';
import '../../../core/data/country_cities.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/letter.dart';
import '../../../state/app_state.dart';

class LetterTrackingScreen extends StatefulWidget {
  final String letterId;

  const LetterTrackingScreen({super.key, required this.letterId});

  @override
  State<LetterTrackingScreen> createState() => _LetterTrackingScreenState();
}

class _LetterTrackingScreenState extends State<LetterTrackingScreen>
    with TickerProviderStateMixin {
  // 타일/언어 설정 → MapConfig 중앙 관리 (lib/core/config/map_config.dart)
  final MapController _mapController = MapController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Letter? _findLetter(AppState state) {
    try {
      return state.sent.firstWhere((l) => l.id == widget.letterId);
    } catch (_) {}
    try {
      return state.worldLetters.firstWhere((l) => l.id == widget.letterId);
    } catch (_) {}
    return null;
  }

  // ── 이모티콘 헬퍼 ──────────────────────────────────────────────────────────
  /// letter.deliveryEmoji ("|" 구분 포맷) 파싱 → 운송 모드에 맞는 이모티콘 반환
  /// 해당 모드 카테고리에 선택값 없으면 기본 운송수단 이모티콘 사용 (다른 카테고리 혼용 없음)
  String _resolvedEmoji(Letter letter, TransportMode mode) {
    final raw = letter.deliveryEmoji;
    if (raw == null || raw.isEmpty) return mode.emoji;
    final parts = raw.split('|');
    if (parts.length == 3) {
      final idx = mode == TransportMode.truck
          ? 0
          : mode == TransportMode.airplane
          ? 1
          : 2;
      final e = parts[idx];
      // 해당 카테고리 선택값 사용, 없으면 기본 운송수단 이모티콘
      if (e.isNotEmpty) return e;
      return mode.emoji;
    }
    // 레거시 단일 이모티콘 호환
    return raw.isNotEmpty ? raw : mode.emoji;
  }

  String _mapTileUrl(String langCode, {required bool darkMode}) =>
      MapConfig.tileUrl(langCode, darkMode: darkMode);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final l10n = AppL10n.of(state.currentUser.languageCode);
        final letter = _findLetter(state);
        if (letter == null) {
          return Scaffold(
            backgroundColor: AppColors.bgDeep,
            appBar: AppBar(
              backgroundColor: const Color(0xFF0D1421),
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.gold,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                l10n.mapDeliveryTracking,
                style: const TextStyle(color: AppColors.gold),
              ),
            ),
            body: Center(
              child: Text(
                l10n.mapLetterNotFound,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.bgDeep,
          appBar: _buildAppBar(context, letter, l10n),
          body: Column(
            children: [
              // 지도 영역
              Expanded(flex: 3, child: _buildMap(letter, state, l10n)),
              // 배송 진행 영역
              Expanded(flex: 2, child: _buildProgressPanel(letter, state, l10n)),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Letter letter, AppL10n l10n) {
    final destinationLabel =
        (letter.destinationCity != null && letter.destinationCity!.isNotEmpty)
        ? letter.destinationCity!
        : letter.destinationCountry;
    final routeIcon = _routeIcon(letter);
    final routeColor = _routeColor(letter);
    return AppBar(
      backgroundColor: const Color(0xFF0D1421),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.gold),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Text(letter.senderCountryFlag, style: const TextStyle(fontSize: 20)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(routeIcon, color: routeColor, size: 16),
          ),
          Text(
            letter.destinationCountryFlag,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '→ $destinationLabel',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _statusText(letter, l10n),
                  style: const TextStyle(color: AppColors.teal, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(Letter letter, AppL10n l10n) {
    switch (letter.status) {
      case DeliveryStatus.inTransit:
        return '${_resolvedEmoji(letter, letter.currentTransport)}  ${_segmentLabel(letter.currentSegment, letter)}';
      case DeliveryStatus.nearYou:
        return '📍 ${l10n.mapArrivedWithin2km}';
      case DeliveryStatus.delivered:
      case DeliveryStatus.read:
        return '✅ ${l10n.mapDeliveryComplete}';
      default:
        return l10n.mapPreparing;
    }
  }

  String _segmentLabel(RouteSegment seg, Letter letter) {
    final isLastSeg = seg == letter.segments.last;
    final displayTo = (isLastSeg && letter.destinationDisplayAddress != null)
        ? letter.destinationDisplayAddress!
        : null;

    if (letter.senderCountry != letter.destinationCountry) {
      return '${seg.fromName} → ${displayTo ?? seg.toName}';
    }
    final fromLabel = _nearestCityLabel(
      letter.senderCountry,
      seg.from,
      seg.fromName,
    );
    final toLabel = displayTo ??
        ((seg.toType == HubType.destination &&
                letter.destinationCity != null &&
                letter.destinationCity!.isNotEmpty)
            ? letter.destinationCity!
            : _nearestCityLabel(letter.destinationCountry, seg.to, seg.toName));
    return '$fromLabel → $toLabel';
  }

  String _nearestCityLabel(String country, LatLng point, String fallback) {
    final list = CountryCities.cities[country];
    if (list == null || list.isEmpty) return fallback;
    Map<String, dynamic>? best;
    var bestDist = double.infinity;
    for (final city in list) {
      final lat = (city['lat'] as num?)?.toDouble();
      final lng = (city['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final dist = point.distanceTo(LatLng(lat, lng));
      if (dist < bestDist) {
        bestDist = dist;
        best = city;
      }
    }
    final name = best?['name'];
    return name is String && name.isNotEmpty ? name : fallback;
  }

  TransportMode _primaryRouteMode(Letter letter) {
    for (final seg in letter.segments) {
      if (seg.mode != TransportMode.truck) return seg.mode;
    }
    return letter.currentTransport;
  }

  IconData _routeIcon(Letter letter) {
    switch (_primaryRouteMode(letter)) {
      case TransportMode.truck:
        return Icons.local_shipping_rounded;
      case TransportMode.airplane:
        return Icons.flight_rounded;
      case TransportMode.ship:
        return Icons.directions_boat_rounded;
    }
  }

  Color _routeColor(Letter letter) {
    switch (_primaryRouteMode(letter)) {
      case TransportMode.truck:
        return AppColors.gold;
      case TransportMode.airplane:
        return AppColors.teal;
      case TransportMode.ship:
        return const Color(0xFF60A5FA);
    }
  }

  Widget _buildMap(Letter letter, AppState state, AppL10n l10n) {
    // 모든 포인트 수집
    final points = <ll.LatLng>[];
    for (final seg in letter.segments) {
      points.add(ll.LatLng(seg.from.latitude, seg.from.longitude));
    }
    if (letter.segments.isNotEmpty) {
      final last = letter.segments.last;
      points.add(ll.LatLng(last.to.latitude, last.to.longitude));
    }

    if (points.isEmpty) {
      return Container(
        color: const Color(0xFF0A0F1A),
        child: Center(
          child: Text(l10n.mapNoRouteInfo, style: const TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    // 중심점 및 줌 레벨 계산
    final centerLat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final centerLng =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

    // 원점~목적지 거리로 줌 레벨 결정
    final origin = letter.originLocation;
    final dest = letter.destinationLocation;
    final distKm = origin.distanceTo(dest) / 1000;
    double zoom;
    if (distKm < 300)
      zoom = 7.0;
    else if (distKm < 1000)
      zoom = 5.5;
    else if (distKm < 3000)
      zoom = 4.5;
    else if (distKm < 8000)
      zoom = 3.0;
    else
      zoom = 2.0;

    final now = DateTime.now();
    final currentPos = letter.status == DeliveryStatus.deliveredFar
        ? letter.destinationLocation
        : letter.currentPositionAt(now);
    final myPos = ll.LatLng(
      state.currentUser.latitude,
      state.currentUser.longitude,
    );
    final mapLangCode = MapConfig.resolveMapLanguage(
      country: state.currentUser.country,
      appLanguageCode: state.currentUser.languageCode,
    );
    final darkMode = state.activeTimePeriod.name == 'night';

    return ClipRect(
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: ll.LatLng(centerLat, centerLng),
              initialZoom: zoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              // ── 기반 타일 ─────────────────────────────────────────────
              // key: 언어·테마 변경 시 캐시 타일 강제 갱신
              TileLayer(
                key: ValueKey('base_${mapLangCode}_$darkMode'),
                urlTemplate: _mapTileUrl(mapLangCode, darkMode: darkMode),
                subdomains: MapConfig.subdomains,
                userAgentPackageName: 'io.thiscount',
              ),
              // ── 현지어 레이블 오버레이 (야간 + CartoDB 폴백 시) ────────
              if (MapConfig.labelOverlayUrl(darkMode: darkMode) != null)
                TileLayer(
                  key: ValueKey('label_${mapLangCode}_$darkMode'),
                  urlTemplate: MapConfig.labelOverlayUrl(darkMode: darkMode)!,
                  subdomains: MapConfig.subdomains,
                  userAgentPackageName: 'io.thiscount',
                ),
              // 경로 선
              PolylineLayer(polylines: _buildRoutePolylines(letter)),
              // 마커
              MarkerLayer(
                markers: [
                  // 출발지
                  Marker(
                    point: ll.LatLng(origin.latitude, origin.longitude),
                    width: 32,
                    height: 32,
                    child: _HubMarker(emoji: '📤', color: AppColors.gold),
                  ),
                  // 경유 허브
                  ..._buildHubMarkers(letter),
                  // 목적지
                  Marker(
                    point: ll.LatLng(dest.latitude, dest.longitude),
                    width: 32,
                    height: 32,
                    child: _HubMarker(emoji: '📬', color: AppColors.teal),
                  ),
                  // 내 위치 포인트
                  Marker(
                    point: myPos,
                    width: 34,
                    height: 34,
                    child: _HubMarker(
                      emoji: '📍',
                      color: const Color(0xFF60A5FA),
                    ),
                  ),
                  // 현재 위치 (운송수단)
                  if (letter.status == DeliveryStatus.inTransit ||
                      letter.status == DeliveryStatus.nearYou)
                    Marker(
                      point: ll.LatLng(
                        currentPos.latitude,
                        currentPos.longitude,
                      ),
                      width: 44,
                      height: 44,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => _buildMovingMarker(letter),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(top: 12, right: 12, child: _buildMyLocationButton(state)),
        ],
      ),
    );
  }

  void _goToMyLocation(AppState state) {
    _mapController.move(
      ll.LatLng(state.currentUser.latitude, state.currentUser.longitude),
      9.5,
    );
  }

  Widget _buildMyLocationButton(AppState state) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _goToMyLocation(state),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bgCard.withValues(alpha: 0.92),
            border: Border.all(
              color: AppColors.teal.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.my_location_rounded,
            color: AppColors.teal,
            size: 22,
          ),
        ),
      ),
    );
  }

  List<Polyline> _buildRoutePolylines(Letter letter) {
    final lines = <Polyline>[];
    for (int i = 0; i < letter.segments.length; i++) {
      final seg = letter.segments[i];
      final isCompleted = i < letter.currentSegmentIndex;
      final isCurrent = i == letter.currentSegmentIndex;

      Color lineColor;
      double width;
      if (isCompleted) {
        lineColor = AppColors.teal.withValues(alpha: 0.6);
        width = 2.0;
      } else if (isCurrent) {
        lineColor = AppColors.teal;
        width = 3.0;
      } else {
        lineColor = AppColors.textMuted.withValues(alpha: 0.3);
        width = 1.5;
      }

      lines.add(
        Polyline(
          points: [
            ll.LatLng(seg.from.latitude, seg.from.longitude),
            ll.LatLng(seg.to.latitude, seg.to.longitude),
          ],
          color: lineColor,
          strokeWidth: width,
        ),
      );

      // 현재 구간은 진행 중 부분을 밝게 표시
      if (isCurrent && seg.progress > 0) {
        final midLat =
            seg.from.latitude +
            (seg.to.latitude - seg.from.latitude) * seg.progress;
        final midLng =
            seg.from.longitude +
            (seg.to.longitude - seg.from.longitude) * seg.progress;
        lines.add(
          Polyline(
            points: [
              ll.LatLng(seg.from.latitude, seg.from.longitude),
              ll.LatLng(midLat, midLng),
            ],
            color: AppColors.gold.withValues(alpha: 0.8),
            strokeWidth: 3.0,
          ),
        );
      }
    }
    return lines;
  }

  List<Marker> _buildHubMarkers(Letter letter) {
    final markers = <Marker>[];
    for (int i = 1; i < letter.segments.length; i++) {
      final hub = letter.segments[i].from;
      final isReached = i <= letter.currentSegmentIndex;
      markers.add(
        Marker(
          point: ll.LatLng(hub.latitude, hub.longitude),
          width: 16,
          height: 16,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isReached ? AppColors.teal : AppColors.bgSurface,
              border: Border.all(
                color: isReached ? AppColors.teal : AppColors.textMuted,
                width: 1.5,
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildMovingMarker(Letter letter) {
    final seg = letter.currentSegment;
    final bearing = _calcBearing(seg.from, seg.to);
    final rotationAngle =
        bearing - letter.currentTransport.headingOffsetRadians;
    final emoji = _resolvedEmoji(letter, letter.currentTransport);

    final color = letter.currentTransport == TransportMode.airplane
        ? AppColors.teal
        : letter.currentTransport == TransportMode.ship
        ? const Color(0xFF60A5FA)
        : AppColors.gold;

    return Transform.rotate(
      angle: rotationAngle,
      child: Text(
        emoji,
        style: TextStyle(
          fontSize: 26,
          shadows: [
            Shadow(color: color.withValues(alpha: 0.55), blurRadius: 10),
            const Shadow(
              color: Color(0x99000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  double _calcBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final dLng = (to.longitude - from.longitude) * pi / 180;
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    return atan2(y, x);
  }

  Widget _buildProgressPanel(Letter letter, AppState state, AppL10n l10n) {
    final myPos = LatLng(
      state.currentUser.latitude,
      state.currentUser.longitude,
    );
    final trackingPos = letter.status == DeliveryStatus.deliveredFar
        ? letter.destinationLocation
        : letter.currentPositionAt(DateTime.now());
    final distKm = trackingPos.distanceTo(myPos) / 1000;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1421),
        border: Border(top: BorderSide(color: Color(0xFF1F2D44))),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 전체 진행 게이지
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.mapOverallDeliveryProgress,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${(letter.overallProgress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: letter.overallProgress,
                          backgroundColor: AppColors.bgSurface,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.teal,
                          ),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        letter.etaLabel,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          '📍 ${l10n.mapMyLocationShown(distKm.toStringAsFixed(distKm >= 10 ? 0 : 1))}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.mapDeliveryRoute,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            // 구간별 스텝
            ...letter.segments.asMap().entries.map(
              (e) => _buildSegmentRow(e.key, e.value, letter, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentRow(int index, RouteSegment seg, Letter letter, AppL10n l10n) {
    final isCompleted = index < letter.currentSegmentIndex;
    final isCurrent = index == letter.currentSegmentIndex;
    final isPending = index > letter.currentSegmentIndex;

    Color color;
    if (isCompleted)
      color = AppColors.teal;
    else if (isCurrent)
      color = AppColors.gold;
    else
      color = AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // 인디케이터
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.teal.withValues(alpha: 0.15)
                  : isCurrent
                  ? AppColors.gold.withValues(alpha: 0.15)
                  : AppColors.bgSurface,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Center(
              child: isCompleted
                  ? Icon(Icons.check_rounded, color: AppColors.teal, size: 14)
                  : Text(
                      _resolvedEmoji(letter, seg.mode),
                      style: const TextStyle(fontSize: 12),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          // 구간 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _segmentLabel(seg, letter),
                  style: TextStyle(
                    color: isPending
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${seg.mode.label} · ${_formatMinutes(seg.estimatedMinutes, l10n)}',
                  style: TextStyle(color: color, fontSize: 10),
                ),
              ],
            ),
          ),
          // 현재 구간 진행도
          if (isCurrent) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(seg.progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: seg.progress,
                      backgroundColor: AppColors.bgSurface,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.gold,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isCompleted)
            const Icon(Icons.done_all_rounded, color: AppColors.teal, size: 16),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes, AppL10n l10n) {
    if (minutes < 60) return l10n.mapMinutes(minutes);
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return l10n.mapHours(h);
    return l10n.mapHoursMinutes(h, m);
  }
}

// ── 허브 마커 위젯 ─────────────────────────────────────────────────────────────
class _HubMarker extends StatelessWidget {
  final String emoji;
  final Color color;

  const _HubMarker({required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 13))),
    );
  }
}
