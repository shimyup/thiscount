/// Build 453: 단골 스탬프 카드 — 같은 매장(브랜드) 쿠폰/교환권을 사용할 때마다
/// 스탬프 1개. [rewardThreshold] 개 완성 시 보상 쿠폰이 자동 발급되고 스탬프는
/// 리셋([completedCount] 누적). 앱의 유니크 포지션 "헌팅(신규 유입) × 스탬프
/// (재방문)" 풀퍼널의 재방문 절반을 담당한다.
///
/// 저장은 user-scoped prefs JSON(`brand_stamp_cards_v1`) — 서버 스키마/룰 변경
/// 없이 동작(픽업자 디바이스 기준). 크로스 디바이스 동기화는 Auth Phase 3 이후
/// user doc 필드로 승격 후보.
class BrandStampCard {
  final String brandId;
  String brandName;
  int stamps;
  int rewardThreshold;
  int completedCount;
  DateTime? lastStampAt;

  BrandStampCard({
    required this.brandId,
    required this.brandName,
    this.stamps = 0,
    this.rewardThreshold = defaultThreshold,
    this.completedCount = 0,
    this.lastStampAt,
  });

  /// 커피 스탬프 통념(5/10) 중 모바일 루프에 맞는 짧은 쪽.
  static const int defaultThreshold = 5;

  bool get isComplete => stamps >= rewardThreshold;

  Map<String, dynamic> toJson() => {
        'brandId': brandId,
        'brandName': brandName,
        'stamps': stamps,
        'rewardThreshold': rewardThreshold,
        'completedCount': completedCount,
        if (lastStampAt != null)
          'lastStampAt': lastStampAt!.millisecondsSinceEpoch,
      };

  factory BrandStampCard.fromJson(Map<String, dynamic> j) {
    // 방어적 파싱 — prefs corruption 시에도 카드 1장이 전체 로드를 깨지 않게.
    int asInt(dynamic v, int def) =>
        v is int ? v : (v is num ? v.toInt() : def);
    final threshold = asInt(j['rewardThreshold'], defaultThreshold);
    return BrandStampCard(
      brandId: (j['brandId'] as String?) ?? '',
      brandName: (j['brandName'] as String?) ?? '',
      stamps: asInt(j['stamps'], 0).clamp(0, 1000),
      rewardThreshold: threshold < 1 ? defaultThreshold : threshold,
      completedCount: asInt(j['completedCount'], 0).clamp(0, 100000),
      lastStampAt: j['lastStampAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(j['lastStampAt'] as int)
          : null,
    );
  }
}
