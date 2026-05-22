// Build 323: Brand 인사이트 데이터 — ROI 대시보드용.
// 사용자가 캠페인의 효과를 한눈에 보기 위한 단계별 funnel.

class BrandInsights {
  /// 최근 30일 누적 발송 수
  final int totalSent;

  /// 최근 30일 누적 픽업 수 (모든 캠페인 합)
  final int totalPickup;

  /// 최근 30일 누적 사용 완료 수 (사용자 "사용 완료" 누른 letter 수)
  final int totalRedeemed;

  /// 픽업률 = pickup / sent
  final double pickupRate;

  /// 사용 전환률 = redeemed / pickup (진짜 ROI 신호)
  final double redeemRate;

  /// 캠페인별 인사이트 (픽업 많은 순)
  final List<CampaignInsight> campaigns;

  const BrandInsights({
    required this.totalSent,
    required this.totalPickup,
    required this.totalRedeemed,
    required this.pickupRate,
    required this.redeemRate,
    required this.campaigns,
  });

  const BrandInsights.empty()
      : totalSent = 0,
        totalPickup = 0,
        totalRedeemed = 0,
        pickupRate = 0,
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
  final int redeemed;
  final double redeemRate;

  const CampaignInsight({
    required this.letterId,
    required this.title,
    required this.sent,
    required this.pickup,
    required this.redeemed,
    required this.redeemRate,
  });

  String get healthEmoji {
    if (pickup == 0) return '⚪'; // 픽업 없음 — 측정 불가
    if (redeemRate >= 0.20) return '🟢';
    if (redeemRate >= 0.05) return '🟡';
    return '🔴';
  }

  /// 코칭 메시지 — 사용자가 어떤 행동 할지 안내.
  String get coachingTip {
    if (pickup == 0 && sent > 0) {
      return '아직 픽업 0 — 반경 좁히거나 본문 매력 ↑';
    }
    if (redeemRate < 0.05 && pickup >= 3) {
      return '사용률 낮음 — 본문 변경 또는 더 큰 할인 권장';
    }
    if (redeemRate >= 0.20) {
      return '효과 좋아요! 동일 패턴으로 재집행';
    }
    return ''; // 보통 — 코칭 없음
  }
}
