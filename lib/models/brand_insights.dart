// Build 323: Brand 인사이트 데이터 — ROI 대시보드용.
// 사용자가 캠페인의 효과를 한눈에 보기 위한 단계별 funnel.
// Build 331 (PR-S3): 4단계 funnel — 발송 → 픽업 → 코드 노출 → 사용 완료.
//   코드 노출 (revealedCount) 은 "지금 매장에 있다" 의도 신호 — 가장 강한
//   상점 의도. 픽업 → 노출 drop 큰 letter = 본문 매력 OK 지만 매장 가는
//   친화도 낮음 (예: 거리 멀음 / 시간대 어긋남).

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

  const CampaignInsight({
    required this.letterId,
    required this.title,
    required this.sent,
    required this.pickup,
    required this.revealed,
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
  /// Build 331 (PR-S3): 노출→사용 drop 패턴 추가 — 매장 도착했는데 사용 안 함.
  String get coachingTip {
    if (pickup == 0 && sent > 0) {
      return '아직 픽업 0 — 반경 좁히거나 본문 매력 ↑';
    }
    if (revealed == 0 && pickup >= 5) {
      return '픽업 후 코드 노출 0 — 매장이 너무 멀거나 사용 시점 불명확';
    }
    if (revealed > 0 && redeemed == 0 && pickup >= 3) {
      return '코드 노출됐는데 사용 완료 0 — POS 등록 누락 가능. 점주 확인';
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
