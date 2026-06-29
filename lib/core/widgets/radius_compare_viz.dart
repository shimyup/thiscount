import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

/// Build 435 (design): Free→Premium 줍기 반경 비교 시각화.
///
/// 200m(Free, 라임) vs 1km(Premium, 골드) 를 지도 동심원으로 보여줘 "5배 넓다" 를
/// 한 스캔에 전달하는 conversion 부스터. 페이월(PremiumScreen)·온보딩 환영 페이월
/// 양쪽에서 공유. Premium = 줍기 부스터 포지셔닝(발송 문구 없음).
///
/// Build 437: [height] 파라미터화 — 온보딩은 한 화면에 카드/사용법까지 들어오도록
/// 작게(예: 150), PremiumScreen 은 기본 212. 원·라벨·이모지 모두 height 비례.
class RadiusCompareViz extends StatelessWidget {
  final AppL10n l;
  final double height;
  const RadiusCompareViz({super.key, required this.l, this.height = 212});

  @override
  Widget build(BuildContext context) {
    final h = height;
    final s = h / 212.0; // 기준 디자인(212) 대비 스케일
    final goldD = h * 0.925; // 큰 원(1km)
    final limeD = h * 0.368; // 작은 원(200m)
    final dotD = (13 * s).clamp(9.0, 13.0);
    final emojiSize = (17 * s).clamp(12.0, 17.0);
    final freeLabelTop = h * 0.70;
    final labelFont = (12 * s).clamp(9.5, 12.0);
    final chipFont = (11 * s).clamp(9.0, 11.0);

    Widget emoji(String e, {double? left, double? right, double? top}) {
      return Positioned(
        left: left == null ? null : left * s,
        right: right == null ? null : right * s,
        top: top == null ? null : top * s,
        child: Opacity(
          opacity: 0.9,
          child: Text(e, style: TextStyle(fontSize: emojiSize)),
        ),
      );
    }

    return Container(
      height: h,
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
          // 업종 이모지 — 두 원 사이 고리 윗부분에만 정돈 배치(중심/라벨과 미충돌).
          emoji('☕', left: 58, top: 44),
          emoji('🍔', right: 70, top: 62),
          emoji('💄', left: 48, top: 96),
          emoji('🎉', right: 52, top: 104),
          // Premium 1km 원 (골드, 큰 원)
          Container(
            width: goldD,
            height: goldD,
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
            width: limeD,
            height: limeD,
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
            width: dotD,
            height: dotD,
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
            top: freeLabelTop,
            child: Text(
              'Free · 200m',
              style: TextStyle(
                color: AppColors.teal,
                fontSize: labelFont,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // Premium 라벨 (하단)
          Positioned(
            bottom: 12 * s,
            child: Text(
              l.koEn('👑 Premium · 1km 반경', '👑 Premium · 1km radius'),
              style: TextStyle(
                color: AppColors.gold,
                fontSize: labelFont + 0.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // 부스터 칩 (우상단)
          Positioned(
            top: 11 * s,
            right: 11 * s,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 3 * s),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Text(
                l.koEn('✦ 줍기 부스터', '✦ Pickup boost'),
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: chipFont,
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
