import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

/// Build 435 (design): Free→Premium 줍기 반경 비교 시각화.
///
/// 200m(Free, 라임) vs 1km(Premium, 골드) 를 지도 동심원으로 보여줘 "5배 넓다" 를
/// 한 스캔에 전달하는 conversion 부스터. 페이월(PremiumScreen)·온보딩 환영 페이월
/// 양쪽에서 공유. Premium = 줍기 부스터 포지셔닝(발송 문구 없음).
class RadiusCompareViz extends StatelessWidget {
  final AppL10n l;
  const RadiusCompareViz({super.key, required this.l});

  Widget _emoji(String e,
      {double? left, double? right, double? top, double? bottom}) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Opacity(
        opacity: 0.85,
        child: Text(e, style: const TextStyle(fontSize: 17)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 212,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          radius: 0.95,
          colors: [Color(0xFF15161B), Color(0xFF0B0C10)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.10)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 산재 업종 이모지 (반경 안에 더 많은 혜택이 잡힌다는 신호)
          _emoji('☕', left: 44, top: 36),
          _emoji('🍔', right: 50, top: 52),
          _emoji('💄', left: 56, bottom: 44),
          _emoji('🎉', right: 52, bottom: 54),
          _emoji('👗', right: 96, top: 116),
          // Premium 1km 원 (골드, 큰 원)
          Container(
            width: 196,
            height: 196,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.13),
                  AppColors.gold.withValues(alpha: 0.03),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.66, 0.74],
              ),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
          ),
          // Free 200m 원 (라임, 작은 원)
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal.withValues(alpha: 0.14),
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
          ),
          // 중심 점 (내 위치)
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textPrimary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          // Free 라벨 (작은 원 아래)
          Positioned(
            top: 150,
            child: Text(
              'Free · 200m',
              style: TextStyle(
                color: AppColors.teal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // Premium 라벨 (하단)
          Positioned(
            bottom: 14,
            child: Text(
              l.koEn('👑 Premium · 1km 반경', '👑 Premium · 1km radius'),
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // 부스터 칩 (우상단)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Text(
                l.koEn('✦ 줍기 부스터', '✦ Pickup boost'),
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
