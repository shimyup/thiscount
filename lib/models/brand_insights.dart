// Build 323: Brand 인사이트 데이터 — ROI 대시보드용.
// 사용자가 캠페인의 효과를 한눈에 보기 위한 단계별 funnel.
// Build 331 (PR-S3): 4단계 funnel — 발송 → 픽업 → 코드 노출 → 사용 완료.
//   코드 노출 (revealedCount) 은 "지금 매장에 있다" 의도 신호 — 가장 강한
//   상점 의도. 픽업 → 노출 drop 큰 letter = 본문 매력 OK 지만 매장 가는
//   친화도 낮음 (예: 거리 멀음 / 시간대 어긋남).
// Build 336 (PR-S5): coachingTip i18n 분리 — coachingTipL10n(AppL10n) 사용.

import '../core/localization/app_localizations.dart';

class BrandInsights {
  /// 최근 30일 누적 발송 수
  final int totalSent;

  /// 최근 30일 누적 픽업 수 (모든 캠페인 합)
  final int totalPickup;

  /// 최근 30일 누적 코드 노출 수 (사용자가 "사용 진행" 탭한 unique 카운트)
  /// Build 331 (PR-S3): 4단계 funnel 신규 — 매장 도착 의도 신호.
  final int totalRevealed;

  /// 최근 30일 누적 사용 완료 수 (사용자 "사용 완료" 누른 letter 수)
  final int totalRedeemed;

  /// 픽업률 = pickup / sent
  final double pickupRate;

  /// 노출률 = revealed / pickup — 매장 도달 의도 (Build 331)
  final double revealRate;

  /// 사용 전환률 = redeemed / pickup (진짜 ROI 신호)
  final double redeemRate;

  /// 캠페인별 인사이트 (픽업 많은 순)
  final List<CampaignInsight> campaigns;

  const BrandInsights({
    required this.totalSent,
    required this.totalPickup,
    required this.totalRevealed,
    required this.totalRedeemed,
    required this.pickupRate,
    required this.revealRate,
    required this.redeemRate,
    required this.campaigns,
  });

  const BrandInsights.empty()
      : totalSent = 0,
        totalPickup = 0,
        totalRevealed = 0,
        totalRedeemed = 0,
        pickupRate = 0,
        revealRate = 0,
        redeemRate = 0,
        campaigns = const [];

  /// 색상 코딩 — 사용 전환률 기준:
  ///   ≥ 20% → 🟢 잘됨
  ///   ≥ 5%  → 🟡 보통
  ///   <  5% → 🔴 안됨
  String get healthEmoji {
    if (redeemRate >= 0.20) return '🟢';
    if (redeemRate >= 0.05) return '🟡';
    return '🔴';
  }

  /// Build 415 (sim50 P2): 한국어 하드코딩이던 healthLabel 을 현지화. 비-KR
  ///   브랜드에 한국어가 노출되던 i18n 부정합 해소. 호출자가 사용자 언어 l 전달.
  String healthLabelL10n(AppL10n l) {
    if (redeemRate >= 0.20) return l.koEn('잘 되고 있어요', 'Going well');
    if (redeemRate >= 0.05) return l.koEn('보통이에요', 'Doing okay');
    return l.koEn('개선 필요', 'Needs work');
  }

  /// Deprecated — 한국어 고정. 신규 호출은 healthLabelL10n 사용.
  String get healthLabel {
    if (redeemRate >= 0.20) return '잘 되고 있어요';
    if (redeemRate >= 0.05) return '보통이에요';
    return '개선 필요';
  }
}

class CampaignInsight {
  final String letterId;
  final String title; // letter 본문 prefix
  final int sent;
  final int pickup;
  final int revealed; // Build 331 (PR-S3)
  final int redeemed;
  final double redeemRate;
  // Build 334 (PR-S4, 시뮬레이션 P0 #1): redemptionCode + 유효기간 노출.
  //   기존 PR-S1/S2/S3 가 코드 발급/사용 자체는 구현했지만 사장이 자기 코드를
  //   다시 볼 화면이 없어 매장 POS 등록 자체 불가능했음. brandInsights 캠페인
  //   카드에서 코드 + 만료 표시 → 사장이 POS 관리 가능.
  final String? redemptionCode;
  final DateTime? redemptionExpiresAt;

  const CampaignInsight({
    required this.letterId,
    required this.title,
    required this.sent,
    required this.pickup,
    required this.revealed,
    required this.redeemed,
    required this.redeemRate,
    this.redemptionCode,
    this.redemptionExpiresAt,
  });

  /// Build 334 (PR-S4): 캠페인 코드가 매장에서 아직 유효한지.
  bool get isCodeExpired =>
      redemptionExpiresAt != null &&
      DateTime.now().isAfter(redemptionExpiresAt!);

  String get healthEmoji {
    if (pickup == 0) return '⚪'; // 픽업 없음 — 측정 불가
    if (redeemRate >= 0.20) return '🟢';
    if (redeemRate >= 0.05) return '🟡';
    return '🔴';
  }

  /// 코칭 메시지 — 사용자가 어떤 행동 할지 안내.
  /// Build 331 (PR-S3): 노출→사용 drop 패턴 추가 — 매장 도착했는데 사용 안 함.
  /// Build 334 (PR-S4): 코드 만료 케이스 추가.
  /// Build 336 (PR-S5): i18n — coachingTip(AppL10n) 사용. 호출자가 사용자
  ///   언어로 l10n 전달. 기존 한국어 직접 반환 getter 는 deprecated.
  String coachingTip(AppL10n l) {
    if (isCodeExpired) return l.coachingExpired;
    if (pickup == 0 && sent > 0) return l.coachingNoPickup;
    if (revealed == 0 && pickup >= 5) return l.coachingNoReveal;
    if (revealed > 0 && redeemed == 0 && pickup >= 3) {
      return l.coachingNoRedeem;
    }
    if (redeemRate < 0.05 && pickup >= 3) return l.coachingLowRate;
    if (redeemRate >= 0.20) return l.coachingGood;
    return ''; // 보통 — 코칭 없음
  }
}
