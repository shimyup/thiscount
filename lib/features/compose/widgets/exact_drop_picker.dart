import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/app_state.dart';

/// Brand 계정 전용 "정확한 좌표 드롭" 풀스크린 지도 모달.
///
/// 유저가 지도를 이동/확대해서 핀이 놓일 지점을 선택하면 현재 중앙 좌표가
/// 선택값으로 확정된다. 국가·도시 이름은 caller 쪽에서 GeocodingService
/// 로 역조회하기 때문에 이 위젯은 순수 좌표만 반환한다.
///
/// 일반 회원(Free · Premium) 용 "국가 선택 → 랜덤 도시" UX 와는 완전히 분리된
/// 경로다 — 이 모달은 Brand 만 부를 수 있고, compose_screen 이 토글로 제어.
class ExactDropPicker extends StatefulWidget {
  final ll.LatLng initial;
  final String langCode;
  /// Build 158: 과거 Brand 발송 좌표 추천 리스트. 각 좌표에 오렌지 핀 + 탭 시
  /// 지도 중앙을 해당 지점으로 이동. 추천 없으면 기본 UX 그대로.
  final List<ll.LatLng> recommendations;

  const ExactDropPicker({
    super.key,
    required this.initial,
    required this.langCode,
    this.recommendations = const [],
  });

  @override
  State<ExactDropPicker> createState() => _ExactDropPickerState();
}

class _ExactDropPickerState extends State<ExactDropPicker> {
  late final MapController _ctrl;
  late ll.LatLng _center;
  // Build 210: 내 위치 기준으로 가까이서 시작 — 도시 단위 핀 찍기 자연스럽게.
  // 이전엔 zoom=4 (대륙) 으로 시작해 사용자가 매번 +확대해야 했음.
  double _zoom = 11;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 나라 칩 탭 시 hub 좌표(또는 box 중심) 로 지도 이동.
  void _jumpToCountry(Map<String, dynamic> country) {
    final lat = (country['lat'] as num?)?.toDouble();
    final lng = (country['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    final pt = ll.LatLng(lat, lng);
    _ctrl.move(pt, 11);
    setState(() => _center = pt);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(widget.langCode);
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        title: Text(
          l.composeExactDropTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _ctrl,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              minZoom: 2,
              maxZoom: 14,
              onPositionChanged: (pos, _) {
                _center = pos.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.globaldrift.lettergo',
              ),
              // Build 158: 추천 좌표 핀 (과거 Brand 발송 지점) — 오렌지 tint
              // 로 중앙 빨간 고정핀과 시각적 구분. 탭 시 지도 센터 이동.
              if (widget.recommendations.isNotEmpty)
                MarkerLayer(
                  markers: widget.recommendations.map((p) {
                    return Marker(
                      point: p,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          _ctrl.move(p, _zoom);
                          setState(() => _center = p);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.coupon
                                .withValues(alpha: 0.22),
                            border: Border.all(
                              color: AppColors.coupon,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.history_rounded,
                            color: AppColors.coupon,
                            size: 18,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          // 중앙 고정 핀 — 지도가 움직이면 핀 아래 좌표가 바뀌는 개념
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.place_rounded,
                    color: AppColors.error,
                    size: 44,
                  ),
                  SizedBox(height: 36),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Build 210: 메인 지도처럼 상단에 빠른 나라 점프 칩 — 자주
                // 발송하는 나라로 한 번에 이동. 탭 시 해당 나라 hub 좌표 +
                // zoom 11 로 이동.
                _CountryQuickJumpBar(
                  langCode: widget.langCode,
                  onPick: _jumpToCountry,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    l.composeExactDropHint,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_center),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.bgDeep,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l.composeExactDropConfirm,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Build 210: 상단에 가로 스크롤 가능한 나라 칩 row.
/// AppState.countries 에서 데이터를 끌어다 flag + name 칩으로 노출.
/// 탭 시 부모의 _jumpToCountry 콜백이 지도 중심 이동.
class _CountryQuickJumpBar extends StatelessWidget {
  final String langCode;
  final void Function(Map<String, dynamic>) onPick;
  const _CountryQuickJumpBar({required this.langCode, required this.onPick});

  @override
  Widget build(BuildContext context) {
    // AppState.countries 는 List<Map<String, String>>. lat/lng 는 string.
    // 사용자가 가장 자주 보내는 나라 12개만 우선 노출.
    final raw = AppState.countries;
    final featured = <Map<String, dynamic>>[];
    const priority = ['대한민국', '일본', '미국', '호주', '영국', '프랑스', '독일',
        '캐나다', '중국', '인도', '브라질', '이탈리아'];
    for (final name in priority) {
      final entry = raw.firstWhere(
        (c) => c['name'] == name,
        orElse: () => const <String, String>{},
      );
      if (entry.isNotEmpty) {
        featured.add({
          'name': entry['name'],
          'flag': entry['flag'],
          'lat': double.tryParse(entry['lat'] ?? ''),
          'lng': double.tryParse(entry['lng'] ?? ''),
        });
      }
    }
    if (featured.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: featured.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final c = featured[i];
          final name = c['name'] as String;
          final flag = c['flag'] as String? ?? '🌍';
          final localized = CountryL10n.localizedName(name, langCode);
          return Material(
            color: AppColors.bgCard.withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onPick(c),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      localized,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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
}
