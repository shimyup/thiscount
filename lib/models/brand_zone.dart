// Build 283 (Phase 1 MVP): Brand auto-drop zone 모델.
//
// Brand 사용자가 미리 설정한 "쿠폰 zone": 좌표(center) + 반경(radius_m) +
// 쿠폰 내용(redemptionInfo) + 시작/만료 시각 + 최대 발급 수량.
// 일반 사용자가 zone 반경 안에 들어오면 [BrandZoneService] 가 자동으로
// letter 1통을 그 사용자의 픽업 반경 안에 떨어뜨린다 (인박스 + 지도 핀).
//
// 보안 모델 (anonymous Firebase Auth 한계):
//   - allow create: Brand verified 사용자만 (클라이언트 검증 + Cloud Function
//     으로 server-side re-verify 권장 — Phase 2)
//   - allow read/list: 모두 (사용자 클라이언트가 가까운 zone 쿼리해야 함)
//   - allow update: redeemedCount 만 (counter increment) — firestore.rules
//     의 isAllowedBrandZoneUpdate
//   - allow delete: false (admin REST 만)
//
// Letter 생성 시:
//   - sender: zone.brandId + zone.brandName
//   - destination: 사용자 현재 위치 ± 30m random offset (깜짝 발견감)
//   - category: coupon
//   - redemptionInfo: zone.redemptionInfo
//   - expiresAt: zone.expiresAt 또는 픽업 후 72h 중 빠른 것
//   - brandZoneId: zone.id (dedup + analytics 용)

import 'letter.dart' show LatLng;

class BrandZone {
  /// Firestore document id (zone 의 고유 식별자, dedup 키).
  final String id;

  /// Brand 사용자 id (UserProfile.id 와 매칭). 발급된 letter 의 senderId 가 됨.
  final String brandId;

  /// Brand 표시 이름 (letter 의 senderName 으로 사용).
  final String brandName;

  /// Zone 중심 좌표 — Brand 가 picker 로 선택. 보통 매장 위치.
  final LatLng center;

  /// 쿠폰 자동 발급 반경 (meter). 권장 50~5000m.
  /// 너무 작으면 사용자가 매장 안에 있어야 함, 너무 크면 spam.
  final double radiusM;

  /// 쿠폰 본문 — Letter.content 로 그대로 들어감. "20% OFF 음료 1잔" 등.
  final String content;

  /// 쿠폰 redemption 정보 (코드/QR url/직원 안내). Letter.redemptionInfo 와 동일 스키마.
  final String? redemptionInfo;

  /// Zone 활성 시작. 이 시각 전엔 자동 발급 안 됨.
  final DateTime startsAt;

  /// Zone 활성 만료. 이 시각 후엔 자동 발급 안 됨 + 이미 발급된 letter 도
  /// expiresAt 으로 자동 만료.
  final DateTime expiresAt;

  /// 총 발급 가능 수량. 0 = 무제한. redeemedCount >= maxRedeems 면 추가 발급 중단.
  final int maxRedeems;

  /// 현재까지 발급된 수량 (Firestore counter increment).
  final int redeemedCount;

  /// Zone 생성 시각.
  final DateTime createdAt;

  const BrandZone({
    required this.id,
    required this.brandId,
    required this.brandName,
    required this.center,
    required this.radiusM,
    required this.content,
    this.redemptionInfo,
    required this.startsAt,
    required this.expiresAt,
    this.maxRedeems = 0,
    this.redeemedCount = 0,
    required this.createdAt,
  });

  /// 현재 활성 상태인지 — 시간 + 수량 모두 통과해야 true.
  bool isActive([DateTime? now]) {
    final t = now ?? DateTime.now();
    if (t.isBefore(startsAt)) return false;
    if (t.isAfter(expiresAt)) return false;
    if (maxRedeems > 0 && redeemedCount >= maxRedeems) return false;
    return true;
  }

  /// 사용자 좌표가 zone 반경 안에 있는지 (Haversine).
  bool containsPosition(LatLng userPos) {
    return center.distanceTo(userPos) <= radiusM;
  }

  /// 사용자 좌표로부터 zone 중심까지의 거리 (m). 정렬/디버그용.
  double distanceFrom(LatLng userPos) => center.distanceTo(userPos);

  Map<String, dynamic> toJson() => {
        'id': id,
        'brandId': brandId,
        'brandName': brandName,
        'center': center.toJson(),
        'radiusM': radiusM,
        'content': content,
        if (redemptionInfo != null) 'redemptionInfo': redemptionInfo,
        'startsAt': startsAt.toUtc().toIso8601String(),
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'maxRedeems': maxRedeems,
        'redeemedCount': redeemedCount,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory BrandZone.fromJson(Map<String, dynamic> j) => BrandZone(
        id: j['id'] as String,
        brandId: j['brandId'] as String,
        brandName: j['brandName'] as String? ?? 'Brand',
        center: LatLng.fromJson(j['center'] as Map<String, dynamic>),
        radiusM: (j['radiusM'] as num).toDouble(),
        content: j['content'] as String? ?? '',
        redemptionInfo: j['redemptionInfo'] as String?,
        startsAt: DateTime.parse(j['startsAt'] as String).toLocal(),
        expiresAt: DateTime.parse(j['expiresAt'] as String).toLocal(),
        maxRedeems: (j['maxRedeems'] as num?)?.toInt() ?? 0,
        redeemedCount: (j['redeemedCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      );

  BrandZone copyWith({int? redeemedCount}) => BrandZone(
        id: id,
        brandId: brandId,
        brandName: brandName,
        center: center,
        radiusM: radiusM,
        content: content,
        redemptionInfo: redemptionInfo,
        startsAt: startsAt,
        expiresAt: expiresAt,
        maxRedeems: maxRedeems,
        redeemedCount: redeemedCount ?? this.redeemedCount,
        createdAt: createdAt,
      );
}
