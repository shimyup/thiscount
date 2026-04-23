import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

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
  double _zoom = 4;

  @override
  void initState() {
    super.initState();
    _ctrl = MapController();
    _center = widget.initial;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
                            color: const Color(0xFFFF8A5C)
                                .withValues(alpha: 0.22),
                            border: Border.all(
                              color: const Color(0xFFFF8A5C),
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.history_rounded,
                            color: Color(0xFFFF8A5C),
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
                    color: Color(0xFFFF5959),
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
            child: Container(
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
