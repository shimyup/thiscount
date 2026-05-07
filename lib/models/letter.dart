import 'dart:math';
import 'package:intl/intl.dart';
import '../core/data/country_cities.dart';
import '../core/localization/app_localizations.dart';

// ── 편지 타입 ──────────────────────────────────────────────────────────────────
enum LetterType { normal, express, brandExpress }

// ── 발신자 등급 (시각적 구분용) ────────────────────────────────────────────────
enum LetterSenderTier { free, premium, brand }

// ── 편지 카테고리 (브랜드 전용 — 수집첩 필터링 + 쿠폰함 표시) ──────────────────
//
// - general : 일반 편지 (기본값). 브랜드가 아닌 유저의 모든 편지도 이 값.
// - coupon  : 할인권 편지. 수집첩에서 쿠폰함 섹션에 분류.
// - voucher : 교환권 편지. 동일.
//
// 브랜드 유저만 컴포즈 화면에서 coupon/voucher 를 선택할 수 있다. Firestore
// 에도 그대로 문자열로 저장되어 다른 유저가 수신할 때 필터링 기준으로 쓴다.
enum LetterCategory { general, coupon, voucher }

extension LetterCategoryExt on LetterCategory {
  String get key {
    switch (this) {
      case LetterCategory.general:
        return 'general';
      case LetterCategory.coupon:
        return 'coupon';
      case LetterCategory.voucher:
        return 'voucher';
    }
  }

  /// 브랜드 발송 편지의 카테고리별 시각 구분 이모지.
  /// 지도 마커·도착 다이얼로그·인박스 오버레이에서 "이게 어떤 편지인지"를
  /// 한 눈에 알려준다. 비브랜드 편지는 호출 측에서 기존 기본값(📬/📮/📩)
  /// 을 그대로 쓰고, `senderIsBrand` 일 때만 이 getter 를 사용한다.
  ///
  /// 값은 브랜드 compose 화면의 카테고리 칩
  /// (`compose_screen.dart:2625-2629`) 과 반드시 동일해야 한다 — 보낸 쪽이
  /// 고른 이모지와 받는 쪽이 보는 이모지가 매칭되어야 "같은 편지"라는 감각이
  /// 끊기지 않음.
  ///   coupon  → 🎟 (할인권)
  ///   voucher → 🎁 (교환권)
  ///   general → ✉️ (일반 브랜드 발송)
  String get brandEmoji {
    switch (this) {
      case LetterCategory.coupon:
        return '🎟';
      case LetterCategory.voucher:
        return '🎁';
      case LetterCategory.general:
        return '✉️';
    }
  }

  static LetterCategory fromKey(String? s) {
    switch (s) {
      case 'coupon':
        return LetterCategory.coupon;
      case 'voucher':
        return LetterCategory.voucher;
      case 'general':
      default:
        return LetterCategory.general;
    }
  }
}

// ── 배송 상태 ──────────────────────────────────────────────────────────────────
enum DeliveryStatus {
  composing,
  inTransit,
  nearYou,
  deliveredFar,
  delivered,
  read,
}

// ── 운송 수단 ──────────────────────────────────────────────────────────────────
enum TransportMode { truck, airplane, ship }

extension TransportModeExt on TransportMode {
  String get emoji {
    switch (this) {
      case TransportMode.truck:
        return '🚚';
      case TransportMode.airplane:
        return '✈️';
      case TransportMode.ship:
        return '🚢';
    }
  }

  String get label => localizedLabel('ko');

  String localizedLabel(String langCode) {
    final l = AppL10n.of(langCode);
    switch (this) {
      case TransportMode.truck:
        return l.transportLand;
      case TransportMode.airplane:
        return l.transportAir;
      case TransportMode.ship:
        return l.transportSea;
    }
  }

  double get headingOffsetRadians {
    switch (this) {
      // 🚚는 기본적으로 오른쪽(동쪽) 방향이어서 bearing(북기준)에서 π/2를 뺀다.
      case TransportMode.truck:
        return pi / 2;
      // ✈️는 약간 북동향(45도)으로 그려져 있어 별도 보정.
      case TransportMode.airplane:
        return pi / 4;
      // 🚢는 폰트에 따라 좌향으로 보이는 경우가 많아 반대 오프셋을 사용.
      case TransportMode.ship:
        return -pi / 2;
    }
  }
}

// ── 허브 타입 ──────────────────────────────────────────────────────────────────
enum HubType { city, localHub, airport, seaport, destinationHub, destination }

extension HubTypeExt on HubType {
  String get emoji {
    switch (this) {
      case HubType.city:
        return '🏙️';
      case HubType.localHub:
        return '🏭';
      case HubType.airport:
        return '✈️';
      case HubType.seaport:
        return '🚢';
      case HubType.destinationHub:
        return '📦';
      case HubType.destination:
        return '📬';
    }
  }
}

// ── 배송 구간 (Segment) ────────────────────────────────────────────────────────
class RouteSegment {
  final LatLng from;
  final LatLng to;
  final TransportMode mode;
  final String fromName;
  final String toName;
  final HubType fromType;
  final HubType toType;
  int estimatedMinutes;
  double progress; // 0.0 ~ 1.0 (이 구간 진행도)

  RouteSegment({
    required this.from,
    required this.to,
    required this.mode,
    required this.fromName,
    required this.toName,
    required this.fromType,
    required this.toType,
    required this.estimatedMinutes,
    this.progress = 0.0,
  });

  LatLng get currentPosition => LatLng(
    from.latitude + (to.latitude - from.latitude) * progress.clamp(0.0, 1.0),
    from.longitude + (to.longitude - from.longitude) * progress.clamp(0.0, 1.0),
  );

  bool get isComplete => progress >= 1.0;

  Map<String, dynamic> toJson() => {
    'from': from.toJson(),
    'to': to.toJson(),
    'mode': mode.index,
    'fromName': fromName,
    'toName': toName,
    'fromType': fromType.index,
    'toType': toType.index,
    'estimatedMinutes': estimatedMinutes,
    'progress': progress,
  };

  static RouteSegment fromJson(Map<String, dynamic> j) => RouteSegment(
    from: LatLng.fromJson(j['from'] as Map<String, dynamic>),
    to: LatLng.fromJson(j['to'] as Map<String, dynamic>),
    mode: TransportMode.values[j['mode'] as int],
    fromName: j['fromName'] as String,
    toName: j['toName'] as String,
    fromType: HubType.values[j['fromType'] as int],
    toType: HubType.values[j['toType'] as int],
    estimatedMinutes: j['estimatedMinutes'] as int,
    progress: (j['progress'] as num).toDouble(),
  );
}

// ── 좌표 ──────────────────────────────────────────────────────────────────────
class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);

  Map<String, dynamic> toJson() => {'lat': latitude, 'lng': longitude};
  static LatLng fromJson(Map<String, dynamic> j) =>
      LatLng((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble());

  double distanceTo(LatLng other) {
    const R = 6371000.0;
    final dLat = _toRad(other.latitude - latitude);
    final dLng = _toRad(other.longitude - longitude);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(latitude)) *
            cos(_toRad(other.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;

  @override
  String toString() => '($latitude, $longitude)';
}

// ── 편지 모델 ──────────────────────────────────────────────────────────────────
class Letter {
  final String id;
  final String senderId;
  final String senderName;
  final String senderCountry;
  final String senderCountryFlag;
  final String content;
  final LatLng originLocation;
  final LatLng destinationLocation;
  final String destinationCountry;
  final String destinationCountryFlag;
  final String? destinationCity; // 구/동 단위 배송 도착지
  String? destinationDisplayAddress; // 현지 언어 3단계 표시 주소 (화면 전용, 지연 보완 가능)
  final List<RouteSegment> segments; // 배송 구간 목록
  int currentSegmentIndex; // 현재 구간 인덱스
  DeliveryStatus status;
  final DateTime sentAt;
  DateTime? arrivedAt;
  DateTime? readAt;
  DateTime? arrivalTime; // 예상 도착 시각 (sentAt + estimatedTotalMinutes)
  final bool isAnonymous;
  final String? socialLink;
  final int estimatedTotalMinutes;
  bool isReadByRecipient;
  LetterType letterType;
  int reportCount;
  Set<String> reportedBy;
  // ── 지역 내 최대 읽기 인원 (기본 3명) ──────────────────────────────────────
  int readCount;         // 현재까지 읽은 인원 수
  static const int maxReadersDefault = 3;
  int maxReaders;        // 최대 읽기 가능 인원
  int likeCount;
  int ratingTotal;
  int ratingCount;
  final int paperStyle;
  final int fontStyle;
  final String? deliveryEmoji; // 유저가 고른 배송 이모티콘 (없으면 운송수단 기본값)
  bool hasReplied; // 수신자가 이미 답장했는지 여부 (1회 제한)
  final String? imageUrl; // 첨부 이미지 로컬 경로 (프리미엄)
  final bool senderIsBrand; // 발신자가 브랜드/크리에이터 계정인지
  final LetterSenderTier senderTier; // 발신자 등급 (시각 구분)
  final bool brandUniquePerUser; // 브랜드: 수신자당 1회만 수신 가능
  final DateTime? expiresAt; // 자동 삭제 시각 (null이면 만료 없음)
  // 카테고리 — 브랜드가 컴포즈 화면에서 선택. 기본은 general (일반 편지).
  // 수집첩(InboxScreen) 에서 필터링 기준으로 사용되며 coupon/voucher 편지는
  // "쿠폰함" 섹션에 시각적으로 분리 표시된다.
  final LetterCategory category;

  /// 발신자가 답장 수락 여부를 켠 편지인지. Brand 발송 시 한정 선택 가능.
  /// Free/Premium 은 항상 true. (false 면 수신자의 letter_read_screen 에서
  /// 답장 버튼이 숨겨지고, 발신자 브랜드가 "이 캠페인은 답장 미수락" 이라는
  /// 안내만 받도록 처리.)
  final bool acceptsReplies;

  /// 쿠폰/교환권 사용 안내 (브랜드 발송 시만 채움).
  /// 예: "LETTERGO20 결제 시 입력", "매장 방문 시 이 화면 제시", "https://..."
  /// 수신자가 편지를 열면 본문 아래에 🎁 박스로 강조 렌더. URL·코드·설명 무엇이든
  /// 자유 텍스트로 허용. 최대 200자.
  final String? redemptionInfo;

  /// Build 132: 쿠폰/교환권 **유효기간** (사용 가능 마지막 시각).
  /// `expiresAt` 는 "편지가 지도/수령함에서 사라지는 시각" (보통 12–72h) 이고,
  /// 이것은 "쿠폰 자체의 사용 기한" (보통 7/30/90일). 두 의미가 달라 분리 유지.
  /// 기프트 앱들 (Kakao Gift / Starbucks) 의 유효기간 패턴과 동일.
  /// null = 무제한.
  final DateTime? redemptionExpiresAt;

  Letter({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderCountry,
    required this.senderCountryFlag,
    required this.content,
    required this.originLocation,
    required this.destinationLocation,
    required this.destinationCountry,
    required this.destinationCountryFlag,
    this.destinationCity,
    this.destinationDisplayAddress,
    required this.segments,
    this.currentSegmentIndex = 0,
    this.status = DeliveryStatus.inTransit,
    required this.sentAt,
    this.arrivedAt,
    this.readAt,
    this.arrivalTime,
    this.isAnonymous = true,
    this.socialLink,
    required this.estimatedTotalMinutes,
    this.isReadByRecipient = false,
    this.letterType = LetterType.normal,
    this.reportCount = 0,
    Set<String>? reportedBy,
    this.readCount = 0,
    this.maxReaders = maxReadersDefault,
    this.likeCount = 0,
    this.ratingTotal = 0,
    this.ratingCount = 0,
    this.paperStyle = 0,
    this.fontStyle = 0,
    this.deliveryEmoji,
    this.hasReplied = false,
    this.imageUrl,
    this.senderIsBrand = false,
    this.senderTier = LetterSenderTier.free,
    this.brandUniquePerUser = false,
    this.expiresAt,
    this.category = LetterCategory.general,
    this.acceptsReplies = true,
    this.redemptionInfo,
    this.redemptionExpiresAt,
  }) : reportedBy = reportedBy ?? {};

  /// 인박스용 독립 복사본 (worldLetters에서 제거 전 inbox에 추가할 때 사용)
  Letter clone() => Letter(
    id: id,
    senderId: senderId,
    senderName: senderName,
    senderCountry: senderCountry,
    senderCountryFlag: senderCountryFlag,
    content: content,
    originLocation: originLocation,
    destinationLocation: destinationLocation,
    destinationCountry: destinationCountry,
    destinationCountryFlag: destinationCountryFlag,
    destinationCity: destinationCity,
    destinationDisplayAddress: destinationDisplayAddress,
    // 동일 reference 공유 시 worldLetters 와 inbox 가 segment progress 를
    // 서로 조작 — 받은함 사본은 새 list 로 격리.
    segments: List<RouteSegment>.from(segments),
    currentSegmentIndex: currentSegmentIndex,
    status: status,
    sentAt: sentAt,
    arrivedAt: arrivedAt,
    readAt: readAt,
    arrivalTime: arrivalTime,
    isAnonymous: isAnonymous,
    socialLink: socialLink,
    estimatedTotalMinutes: estimatedTotalMinutes,
    isReadByRecipient: isReadByRecipient,
    letterType: letterType,
    reportCount: reportCount,
    reportedBy: Set<String>.from(reportedBy),
    likeCount: likeCount,
    ratingTotal: ratingTotal,
    ratingCount: ratingCount,
    paperStyle: paperStyle,
    fontStyle: fontStyle,
    deliveryEmoji: deliveryEmoji,
    hasReplied: hasReplied,
    imageUrl: imageUrl,
    senderIsBrand: senderIsBrand,
    senderTier: senderTier,
    brandUniquePerUser: brandUniquePerUser,
    expiresAt: expiresAt,
    category: category,
    acceptsReplies: acceptsReplies,
    redemptionInfo: redemptionInfo,
    redemptionExpiresAt: redemptionExpiresAt,
    readCount: readCount,
    maxReaders: maxReaders,
  );

  double get avgRating => ratingCount > 0 ? ratingTotal / ratingCount : 0.0;
  bool get isBlocked => reportCount >= 3;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Build 132: 쿠폰/교환권 사용 기한이 지났는지.
  /// `redemptionExpiresAt` 이 null 이면 무제한 → false.
  bool get isRedemptionExpired =>
      redemptionExpiresAt != null &&
      DateTime.now().isAfter(redemptionExpiresAt!);

  // ── 현재 구간 ───────────────────────────────────────────────────────────────
  /// segments 가 비어 있으면 RangeError 가 나기 때문에 destination 좌표로
  /// fallback 한 sentinel segment 를 반환. welcome/brand_ad seed letters 는
  /// segments 를 의도적으로 비울 때가 있어 방어가 필요.
  RouteSegment get currentSegment {
    if (segments.isEmpty) {
      return RouteSegment(
        from: destinationLocation,
        to: destinationLocation,
        mode: TransportMode.truck,
        fromName: destinationCountry,
        toName: destinationCountry,
        fromType: HubType.destination,
        toType: HubType.destination,
        estimatedMinutes: 0,
        progress: 1.0,
      );
    }
    return segments[currentSegmentIndex.clamp(0, segments.length - 1)];
  }

  // ── 현재 위치 ───────────────────────────────────────────────────────────────
  LatLng get currentLocation => currentSegment.currentPosition;

  // ── 현재 운송 수단 ──────────────────────────────────────────────────────────
  TransportMode get currentTransport => currentSegment.mode;

  // ── 전체 진행도 (0.0~1.0) ───────────────────────────────────────────────────
  double get overallProgress {
    if (segments.isEmpty) return 0.0;
    final totalMin = segments.fold<int>(
      0,
      (s, seg) => s + seg.estimatedMinutes,
    );
    if (totalMin == 0) return 0.0;
    double completedMin = 0;
    for (int i = 0; i < segments.length; i++) {
      if (i < currentSegmentIndex) {
        completedMin += segments[i].estimatedMinutes;
      } else if (i == currentSegmentIndex) {
        completedMin += segments[i].estimatedMinutes * segments[i].progress;
        break;
      }
    }
    return (completedMin / totalMin).clamp(0.0, 1.0);
  }

  // ── 상태 라벨 ───────────────────────────────────────────────────────────────
  String get statusLabel => localizedStatusLabel('ko');

  String localizedStatusLabel(String langCode) {
    final l = AppL10n.of(langCode);
    switch (status) {
      case DeliveryStatus.composing:
        return l.statusDrafting;
      case DeliveryStatus.inTransit:
        return currentSegment.mode.localizedLabel(langCode);
      case DeliveryStatus.nearYou:
        return l.statusNearby;
      case DeliveryStatus.deliveredFar:
        return l.statusArrivedPickup;
      case DeliveryStatus.delivered:
        return l.statusDelivered;
      case DeliveryStatus.read:
        return l.statusRead;
    }
  }

  String get currentStageLabel => localizedCurrentStageLabel('ko');

  String localizedCurrentStageLabel(String langCode) {
    final l = AppL10n.of(langCode);
    if (status == DeliveryStatus.nearYou) return l.stageNearby2km;
    if (status == DeliveryStatus.deliveredFar) return l.stageArrivedLocalPickup;
    if (status == DeliveryStatus.delivered || status == DeliveryStatus.read) {
      return l.stageDelivered;
    }
    final seg = currentSegment;
    final isLastSeg = currentSegmentIndex >= segments.length - 1;
    final toDisplay = (isLastSeg && destinationDisplayAddress != null)
        ? destinationDisplayAddress!
        : seg.toName;
    return '${seg.mode.emoji}  ${seg.fromName} → $toDisplay';
  }

  // ── 현실적인 배송 예상 시간 ─────────────────────────────────────────────────
  String get realisticEtaLabel => localizedRealisticEtaLabel('ko');

  String localizedRealisticEtaLabel(String langCode) {
    final l = AppL10n.of(langCode);
    final m = estimatedTotalMinutes;
    if (m < 300) return l.etaSameDay;
    if (m < 2880) return l.etaDomestic;
    if (m < 10080) return l.etaIntlAirShort;
    if (m < 20160) return l.etaIntlAirLong;
    return l.etaIntlSea;
  }

  // ── 예상 도착 시각 라벨 ─────────────────────────────────────────────────────
  String get arrivalTimeLabel => localizedArrivalTimeLabel('ko');

  String localizedArrivalTimeLabel(String langCode) {
    final l = AppL10n.of(langCode);
    if (status == DeliveryStatus.nearYou) return l.arrivalNearbyPickup;
    if (status == DeliveryStatus.deliveredFar) return l.arrivalDestinationWaiting;
    if (status == DeliveryStatus.delivered || status == DeliveryStatus.read) {
      return l.arrivalComplete;
    }

    final remainMin =
        ((1.0 - overallProgress.clamp(0.0, 1.0)) * estimatedTotalMinutes)
            .ceil();
    if (remainMin <= 0) return l.arrivalComplete;
    if (remainMin < 60) return l.arrivalMinutes(remainMin);

    if (remainMin < 1440) {
      final h = remainMin ~/ 60;
      final m = remainMin % 60;
      if (m == 0) return l.arrivalHours(h);
      return l.arrivalHoursMinutes(h, m);
    }

    final days = (remainMin / 1440).ceil();
    final etaDate = DateTime.now().add(Duration(minutes: remainMin));
    return l.arrivalDays(days, _fmtDate(etaDate, langCode));
  }

  static String _fmtDate(DateTime dt, String langCode) =>
      DateFormat.MMMd(langCode).add_Hm().format(dt);

  // ── 예상 남은 시간 ──────────────────────────────────────────────────────────
  String get etaLabel => arrivalTimeLabel;
  String localizedEtaLabel(String langCode) => localizedArrivalTimeLabel(langCode);

  // ── 실시간 위치 보간 (sentAt ~ arrivalTime 기반) ────────────────────────────
  /// 지도 애니메이션용: 현재 시각 기준으로 편지의 실제 위치를 계산
  LatLng currentPositionAt(DateTime now) {
    final eta = arrivalTime;
    if (eta == null || segments.isEmpty) return currentLocation;

    final totalMs = eta.difference(sentAt).inMilliseconds;
    if (totalMs <= 0) return destinationLocation;

    final elapsedMs = now.difference(sentAt).inMilliseconds.clamp(0, totalMs);
    final t = elapsedMs / totalMs; // 0.0 ~ 1.0

    final totalMin = segments.fold<int>(
      0,
      (s, seg) => s + seg.estimatedMinutes,
    );
    if (totalMin == 0) return destinationLocation;

    double targetMin = t * totalMin;
    double accMin = 0;
    for (final seg in segments) {
      final segEnd = accMin + seg.estimatedMinutes;
      if (targetMin <= segEnd) {
        final segT = seg.estimatedMinutes > 0
            ? (targetMin - accMin) / seg.estimatedMinutes
            : 0.0;
        return LatLng(
          seg.from.latitude +
              (seg.to.latitude - seg.from.latitude) * segT.clamp(0.0, 1.0),
          seg.from.longitude +
              (seg.to.longitude - seg.from.longitude) * segT.clamp(0.0, 1.0),
        );
      }
      accMin = segEnd;
    }
    return destinationLocation;
  }

  // ── JSON 직렬화 ─────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'senderCountry': senderCountry,
    'senderCountryFlag': senderCountryFlag,
    'content': content,
    'originLocation': originLocation.toJson(),
    'destinationLocation': destinationLocation.toJson(),
    'destinationCountry': destinationCountry,
    'destinationCountryFlag': destinationCountryFlag,
    'destinationCity': destinationCity,
    if (destinationDisplayAddress != null)
      'destinationDisplayAddress': destinationDisplayAddress,
    'segments': segments.map((s) => s.toJson()).toList(),
    'currentSegmentIndex': currentSegmentIndex,
    'status': status.index,
    'sentAt': sentAt.millisecondsSinceEpoch,
    'arrivedAt': arrivedAt?.millisecondsSinceEpoch,
    'readAt': readAt?.millisecondsSinceEpoch,
    'arrivalTime': arrivalTime?.millisecondsSinceEpoch,
    'isAnonymous': isAnonymous,
    'socialLink': socialLink,
    'estimatedTotalMinutes': estimatedTotalMinutes,
    'isReadByRecipient': isReadByRecipient,
    'letterType': letterType.index,
    'reportCount': reportCount,
    'reportedBy': reportedBy.toList(),
    'likeCount': likeCount,
    'ratingTotal': ratingTotal,
    'ratingCount': ratingCount,
    'paperStyle': paperStyle,
    'fontStyle': fontStyle,
    if (deliveryEmoji != null) 'deliveryEmoji': deliveryEmoji,
    'hasReplied': hasReplied,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'senderIsBrand': senderIsBrand,
    'senderTier': senderTier.index,
    'brandUniquePerUser': brandUniquePerUser,
    if (expiresAt != null) 'expiresAt': expiresAt!.millisecondsSinceEpoch,
    'category': category.key,
    'acceptsReplies': acceptsReplies,
    if (redemptionInfo != null) 'redemptionInfo': redemptionInfo,
    if (redemptionExpiresAt != null)
      'redemptionExpiresAt': redemptionExpiresAt!.millisecondsSinceEpoch,
    'readCount': readCount,
    'maxReaders': maxReaders,
  };

  static Letter fromJson(Map<String, dynamic> j) => Letter(
    id: j['id'] as String,
    senderId: (j['senderId'] as String?) ?? '',
    senderName: (j['senderName'] as String?) ?? '',
    senderCountry: (j['senderCountry'] as String?) ?? '',
    senderCountryFlag: (j['senderCountryFlag'] as String?) ?? '🌍',
    content: (j['content'] as String?) ?? '',
    originLocation: LatLng.fromJson(
      j['originLocation'] as Map<String, dynamic>,
    ),
    destinationLocation: LatLng.fromJson(
      j['destinationLocation'] as Map<String, dynamic>,
    ),
    destinationCountry: (j['destinationCountry'] as String?) ?? '',
    destinationCountryFlag: (j['destinationCountryFlag'] as String?) ?? '🌍',
    destinationCity: j['destinationCity'] as String?,
    destinationDisplayAddress: j['destinationDisplayAddress'] as String?,
    segments: (j['segments'] as List)
        .map((s) => RouteSegment.fromJson(s as Map<String, dynamic>))
        .toList(),
    currentSegmentIndex: j['currentSegmentIndex'] as int,
    status: DeliveryStatus.values[j['status'] as int],
    sentAt: DateTime.fromMillisecondsSinceEpoch(j['sentAt'] as int),
    arrivedAt: j['arrivedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(j['arrivedAt'] as int)
        : null,
    readAt: j['readAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(j['readAt'] as int)
        : null,
    arrivalTime: j['arrivalTime'] != null
        ? DateTime.fromMillisecondsSinceEpoch(j['arrivalTime'] as int)
        : null,
    isAnonymous: j['isAnonymous'] as bool? ?? true,
    socialLink: j['socialLink'] as String?,
    estimatedTotalMinutes: j['estimatedTotalMinutes'] as int,
    isReadByRecipient: j['isReadByRecipient'] as bool? ?? false,
    letterType: LetterType.values[j['letterType'] as int? ?? 0],
    reportCount: j['reportCount'] as int? ?? 0,
    reportedBy: Set<String>.from(j['reportedBy'] as List? ?? []),
    likeCount: j['likeCount'] as int? ?? 0,
    ratingTotal: j['ratingTotal'] as int? ?? 0,
    ratingCount: j['ratingCount'] as int? ?? 0,
    paperStyle: j['paperStyle'] as int? ?? 0,
    fontStyle: j['fontStyle'] as int? ?? 0,
    deliveryEmoji: j['deliveryEmoji'] as String?,
    hasReplied: j['hasReplied'] as bool? ?? false,
    imageUrl: j['imageUrl'] as String?,
    senderIsBrand: j['senderIsBrand'] as bool? ?? false,
    senderTier: LetterSenderTier.values[j['senderTier'] as int? ?? 0],
    brandUniquePerUser: j['brandUniquePerUser'] as bool? ?? false,
    category: LetterCategoryExt.fromKey(j['category'] as String?),
    acceptsReplies: j['acceptsReplies'] as bool? ?? true,
    redemptionInfo: j['redemptionInfo'] as String?,
    redemptionExpiresAt: j['redemptionExpiresAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            j['redemptionExpiresAt'] as int,
          )
        : null,
    expiresAt: j['expiresAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(j['expiresAt'] as int)
        : null,
    readCount: j['readCount'] as int? ?? 0,
    maxReaders: j['maxReaders'] as int? ?? Letter.maxReadersDefault,
  );
}

// ── 전 세계 물류 허브 DB ────────────────────────────────────────────────────────
class LogisticsHubs {
  // 나라코드 → {airport: LatLng, seaport: LatLng?, airportName, seaportName?}
  static const Map<String, _CountryHub> hubs = {
    '대한민국': _CountryHub(
      cityLat: 37.5665,
      cityLng: 126.9780,
      cityName: '서울',
      airportLat: 37.4602,
      airportLng: 126.4407,
      airportName: '인천국제공항',
      seaportLat: 35.1028,
      seaportLng: 129.0403,
      seaportName: '부산항',
    ),
    '일본': _CountryHub(
      cityLat: 35.6762,
      cityLng: 139.6503,
      cityName: '도쿄',
      airportLat: 35.7720,
      airportLng: 140.3928,
      airportName: '나리타공항',
      seaportLat: 34.6937,
      seaportLng: 135.5023,
      seaportName: '오사카항',
    ),
    '미국': _CountryHub(
      cityLat: 40.7128,
      cityLng: -74.0060,
      cityName: '뉴욕',
      airportLat: 40.6413,
      airportLng: -73.7781,
      airportName: 'JFK 국제공항',
      seaportLat: 33.7395,
      seaportLng: -118.2654,
      seaportName: 'LA 항구',
    ),
    '프랑스': _CountryHub(
      cityLat: 48.8566,
      cityLng: 2.3522,
      cityName: '파리',
      airportLat: 49.0097,
      airportLng: 2.5479,
      airportName: 'CDG 공항',
      seaportLat: 49.4431,
      seaportLng: 1.0993,
      seaportName: '르아브르항',
    ),
    '영국': _CountryHub(
      cityLat: 51.5074,
      cityLng: -0.1278,
      cityName: '런던',
      airportLat: 51.4700,
      airportLng: -0.4543,
      airportName: '히드로공항',
      seaportLat: 51.5000,
      seaportLng: 0.0200,
      seaportName: '포트오브런던',
    ),
    '독일': _CountryHub(
      cityLat: 52.5200,
      cityLng: 13.4050,
      cityName: '베를린',
      airportLat: 50.0333,
      airportLng: 8.5706,
      airportName: '프랑크푸르트공항',
      seaportLat: 53.5753,
      seaportLng: 10.0153,
      seaportName: '함부르크항',
    ),
    '이탈리아': _CountryHub(
      cityLat: 41.9028,
      cityLng: 12.4964,
      cityName: '로마',
      airportLat: 41.7999,
      airportLng: 12.2462,
      airportName: '피우미치노공항',
      seaportLat: 44.4056,
      seaportLng: 8.9463,
      seaportName: '제노바항',
    ),
    '스페인': _CountryHub(
      cityLat: 40.4168,
      cityLng: -3.7038,
      cityName: '마드리드',
      airportLat: 40.4936,
      airportLng: -3.5668,
      airportName: '마드리드공항',
      seaportLat: 43.3619,
      seaportLng: -3.8276,
      seaportName: '빌바오항',
    ),
    '브라질': _CountryHub(
      cityLat: -15.7801,
      cityLng: -47.9292,
      cityName: '브라질리아',
      airportLat: -23.4356,
      airportLng: -46.4731,
      airportName: '상파울루공항',
      seaportLat: -22.8833,
      seaportLng: -43.1333,
      seaportName: '리우항',
    ),
    '인도': _CountryHub(
      cityLat: 28.6139,
      cityLng: 77.2090,
      cityName: '뉴델리',
      airportLat: 28.5665,
      airportLng: 77.1031,
      airportName: '인디라간디공항',
      seaportLat: 18.9388,
      seaportLng: 72.8354,
      seaportName: '뭄바이항',
    ),
    '중국': _CountryHub(
      cityLat: 39.9042,
      cityLng: 116.4074,
      cityName: '베이징',
      airportLat: 40.0799,
      airportLng: 116.5847,
      airportName: '베이징수도공항',
      seaportLat: 31.2304,
      seaportLng: 121.4737,
      seaportName: '상하이항',
    ),
    '호주': _CountryHub(
      cityLat: -33.8688,
      cityLng: 151.2093,
      cityName: '시드니',
      airportLat: -33.9461,
      airportLng: 151.1772,
      airportName: '시드니공항',
      seaportLat: -33.8600,
      seaportLng: 151.2000,
      seaportName: '시드니항',
    ),
    '캐나다': _CountryHub(
      cityLat: 43.6532,
      cityLng: -79.3832,
      cityName: '토론토',
      airportLat: 43.6777,
      airportLng: -79.6248,
      airportName: '피어슨공항',
      seaportLat: 49.2827,
      seaportLng: -123.1207,
      seaportName: '밴쿠버항',
    ),
    '멕시코': _CountryHub(
      cityLat: 19.4326,
      cityLng: -99.1332,
      cityName: '멕시코시티',
      airportLat: 19.4363,
      airportLng: -99.0721,
      airportName: '베니토후아레스공항',
      seaportLat: 19.2000,
      seaportLng: -96.1333,
      seaportName: '베라크루스항',
    ),
    '아르헨티나': _CountryHub(
      cityLat: -34.6037,
      cityLng: -58.3816,
      cityName: '부에노스아이레스',
      airportLat: -34.8222,
      airportLng: -58.5358,
      airportName: '에세이사공항',
      seaportLat: -34.6100,
      seaportLng: -58.3700,
      seaportName: '부에노스아이레스항',
    ),
    '러시아': _CountryHub(
      cityLat: 55.7558,
      cityLng: 37.6176,
      cityName: '모스크바',
      airportLat: 55.9736,
      airportLng: 37.4125,
      airportName: '셰레메티예보공항',
      seaportLat: 59.9311,
      seaportLng: 30.3609,
      seaportName: '상트페테르부르크항',
    ),
    '터키': _CountryHub(
      cityLat: 41.0082,
      cityLng: 28.9784,
      cityName: '이스탄불',
      airportLat: 41.2608,
      airportLng: 28.7424,
      airportName: '이스탄불공항',
      seaportLat: 41.0000,
      seaportLng: 28.9500,
      seaportName: '이스탄불항',
    ),
    '이집트': _CountryHub(
      cityLat: 30.0444,
      cityLng: 31.2357,
      cityName: '카이로',
      airportLat: 30.1219,
      airportLng: 31.4056,
      airportName: '카이로공항',
      seaportLat: 31.1956,
      seaportLng: 29.8906,
      seaportName: '알렉산드리아항',
    ),
    '남아프리카': _CountryHub(
      cityLat: -25.7479,
      cityLng: 28.2293,
      cityName: '프리토리아',
      airportLat: -26.1367,
      airportLng: 28.2411,
      airportName: 'O.R.탐보공항',
      seaportLat: -33.9249,
      seaportLng: 18.4241,
      seaportName: '케이프타운항',
    ),
    '태국': _CountryHub(
      cityLat: 13.7563,
      cityLng: 100.5018,
      cityName: '방콕',
      airportLat: 13.6900,
      airportLng: 100.7501,
      airportName: '수완나품공항',
      seaportLat: 13.0827,
      seaportLng: 100.9014,
      seaportName: '레암차방항',
    ),
    '네덜란드': _CountryHub(
      cityLat: 52.3676,
      cityLng: 4.9041,
      cityName: '암스테르담',
      airportLat: 52.3086,
      airportLng: 4.7639,
      airportName: '스키폴공항',
      seaportLat: 51.9225,
      seaportLng: 4.4792,
      seaportName: '로테르담항',
    ),
    '스웨덴': _CountryHub(
      cityLat: 59.3293,
      cityLng: 18.0686,
      cityName: '스톡홀름',
      airportLat: 59.6519,
      airportLng: 17.9186,
      airportName: '알란다공항',
      seaportLat: 57.7089,
      seaportLng: 11.9746,
      seaportName: '예테보리항',
    ),
    '노르웨이': _CountryHub(
      cityLat: 59.9139,
      cityLng: 10.7522,
      cityName: '오슬로',
      airportLat: 60.1939,
      airportLng: 11.1004,
      airportName: '가르데르모엔공항',
      seaportLat: 59.9050,
      seaportLng: 10.7375,
      seaportName: '오슬로항',
    ),
    '포르투갈': _CountryHub(
      cityLat: 38.7169,
      cityLng: -9.1399,
      cityName: '리스본',
      airportLat: 38.7814,
      airportLng: -9.1359,
      airportName: '움베르토공항',
      seaportLat: 38.7078,
      seaportLng: -9.1366,
      seaportName: '리스본항',
    ),
    '인도네시아': _CountryHub(
      cityLat: -6.2088,
      cityLng: 106.8456,
      cityName: '자카르타',
      airportLat: -6.1256,
      airportLng: 106.6558,
      airportName: '수카르노하타공항',
      seaportLat: -6.1000,
      seaportLng: 106.8833,
      seaportName: '탄중프리옥항',
    ),
    '말레이시아': _CountryHub(
      cityLat: 3.1390,
      cityLng: 101.6869,
      cityName: '쿠알라룸푸르',
      airportLat: 2.7456,
      airportLng: 101.7099,
      airportName: 'KLIA공항',
      seaportLat: 3.0000,
      seaportLng: 101.3667,
      seaportName: '클랑항',
    ),
    '싱가포르': _CountryHub(
      cityLat: 1.3521,
      cityLng: 103.8198,
      cityName: '싱가포르',
      airportLat: 1.3644,
      airportLng: 103.9915,
      airportName: '창이공항',
      seaportLat: 1.2600,
      seaportLng: 103.8200,
      seaportName: '싱가포르항',
    ),
    '뉴질랜드': _CountryHub(
      cityLat: -36.8485,
      cityLng: 174.7633,
      cityName: '오클랜드',
      airportLat: -37.0082,
      airportLng: 174.7850,
      airportName: '오클랜드공항',
      seaportLat: -36.8410,
      seaportLng: 174.7680,
      seaportName: '오클랜드항',
    ),
    '필리핀': _CountryHub(
      cityLat: 14.5995,
      cityLng: 120.9842,
      cityName: '마닐라',
      airportLat: 14.5086,
      airportLng: 121.0197,
      airportName: '니노이아키노공항',
      seaportLat: 14.5833,
      seaportLng: 120.9667,
      seaportName: '마닐라항',
    ),
    '베트남': _CountryHub(
      cityLat: 21.0285,
      cityLng: 105.8542,
      cityName: '하노이',
      airportLat: 21.2212,
      airportLng: 105.8072,
      airportName: '노이바이공항',
      seaportLat: 10.7622,
      seaportLng: 106.6820,
      seaportName: '호찌민항',
    ),
    '그리스': _CountryHub(
      cityLat: 37.9838,
      cityLng: 23.7275,
      cityName: '아테네',
      airportLat: 37.9364,
      airportLng: 23.9445,
      airportName: '엘레프테리오스베니젤로스공항',
      seaportLat: 37.9408,
      seaportLng: 23.6319,
      seaportName: '피레우스항',
    ),
    '이스라엘': _CountryHub(
      cityLat: 31.7683,
      cityLng: 35.2137,
      cityName: '예루살렘',
      airportLat: 31.9965,
      airportLng: 34.8854,
      airportName: '벤구리온공항',
      seaportLat: 32.8231,
      seaportLng: 34.9808,
      seaportName: '하이파항',
    ),
    '사우디아라비아': _CountryHub(
      cityLat: 24.7136,
      cityLng: 46.6753,
      cityName: '리야드',
      airportLat: 24.9576,
      airportLng: 46.6988,
      airportName: '킹칼리드공항',
      seaportLat: 21.5433,
      seaportLng: 39.1728,
      seaportName: '제다항',
    ),
    'UAE': _CountryHub(
      cityLat: 25.2048,
      cityLng: 55.2708,
      cityName: '두바이',
      airportLat: 25.2532,
      airportLng: 55.3657,
      airportName: '두바이국제공항',
      seaportLat: 25.2697,
      seaportLng: 55.3095,
      seaportName: '두바이항',
    ),
    '파키스탄': _CountryHub(
      cityLat: 33.6844,
      cityLng: 73.0479,
      cityName: '이슬라마바드',
      airportLat: 24.9008,
      airportLng: 67.1681,
      airportName: '진나국제공항',
      seaportLat: 24.8460,
      seaportLng: 67.0104,
      seaportName: '카라치항',
    ),
    '방글라데시': _CountryHub(
      cityLat: 23.8103,
      cityLng: 90.4125,
      cityName: '다카',
      airportLat: 23.8433,
      airportLng: 90.3979,
      airportName: '하즈라트샤잘랄공항',
      seaportLat: 22.3419,
      seaportLng: 91.8152,
      seaportName: '치타공항',
    ),
    '나이지리아': _CountryHub(
      cityLat: 9.0765,
      cityLng: 7.3986,
      cityName: '아부자',
      airportLat: 6.5774,
      airportLng: 3.3212,
      airportName: '무르탈라모하메드공항',
      seaportLat: 6.4432,
      seaportLng: 3.3699,
      seaportName: '라고스아파파항',
    ),
    '케냐': _CountryHub(
      cityLat: -1.2921,
      cityLng: 36.8219,
      cityName: '나이로비',
      airportLat: -1.3192,
      airportLng: 36.9275,
      airportName: '조모케냐타공항',
      seaportLat: -4.0500,
      seaportLng: 39.6667,
      seaportName: '몸바사항',
    ),
    '에티오피아': _CountryHub(
      cityLat: 9.0054,
      cityLng: 38.7636,
      cityName: '아디스아바바',
      airportLat: 8.9779,
      airportLng: 38.7993,
      airportName: '볼레국제공항',
      seaportLat: 11.5892,
      seaportLng: 43.1450,
      seaportName: '지부티항', // 내륙국 → 지부티 경유
    ),
    '모로코': _CountryHub(
      cityLat: 33.9716,
      cityLng: -6.8498,
      cityName: '라바트',
      airportLat: 33.3675,
      airportLng: -7.5898,
      airportName: '카사블랑카공항',
      seaportLat: 33.5731,
      seaportLng: -7.5898,
      seaportName: '카사블랑카항',
    ),
    '콜롬비아': _CountryHub(
      cityLat: 4.7110,
      cityLng: -74.0721,
      cityName: '보고타',
      airportLat: 4.7016,
      airportLng: -74.1469,
      airportName: '엘도라도공항',
      seaportLat: 10.4260,
      seaportLng: -75.5279,
      seaportName: '카르타헤나항',
    ),
    '페루': _CountryHub(
      cityLat: -12.0464,
      cityLng: -77.0428,
      cityName: '리마',
      airportLat: -12.0219,
      airportLng: -77.1143,
      airportName: '호르헤차베스공항',
      seaportLat: -12.0564,
      seaportLng: -77.1382,
      seaportName: '카야오항',
    ),
    '칠레': _CountryHub(
      cityLat: -33.4489,
      cityLng: -70.6693,
      cityName: '산티아고',
      airportLat: -33.3930,
      airportLng: -70.7858,
      airportName: '메리노베니테스공항',
      seaportLat: -33.0472,
      seaportLng: -71.6127,
      seaportName: '발파라이소항',
    ),
    '덴마크': _CountryHub(
      cityLat: 55.6761,
      cityLng: 12.5683,
      cityName: '코펜하겐',
      airportLat: 55.6180,
      airportLng: 12.6508,
      airportName: '카스트루프공항',
      seaportLat: 55.6700,
      seaportLng: 12.6000,
      seaportName: '코펜하겐항',
    ),
    '핀란드': _CountryHub(
      cityLat: 60.1699,
      cityLng: 24.9384,
      cityName: '헬싱키',
      airportLat: 60.3172,
      airportLng: 24.9633,
      airportName: '헬싱키반타공항',
      seaportLat: 60.1587,
      seaportLng: 24.9527,
      seaportName: '헬싱키항',
    ),
    '오스트리아': _CountryHub(
      cityLat: 48.2082,
      cityLng: 16.3738,
      cityName: '빈',
      airportLat: 48.1102,
      airportLng: 16.5697,
      airportName: '빈슈베하트공항',
    ),
    '폴란드': _CountryHub(
      cityLat: 52.2297,
      cityLng: 21.0122,
      cityName: '바르샤바',
      airportLat: 52.1657,
      airportLng: 20.9671,
      airportName: '쇼팽공항',
      seaportLat: 54.4021,
      seaportLng: 18.6601,
      seaportName: '그단스크항',
    ),
    '체코': _CountryHub(
      cityLat: 50.0755,
      cityLng: 14.4378,
      cityName: '프라하',
      airportLat: 50.1008,
      airportLng: 14.2600,
      airportName: '바클라프하벨공항',
    ),
    '헝가리': _CountryHub(
      cityLat: 47.4979,
      cityLng: 19.0402,
      cityName: '부다페스트',
      airportLat: 47.4298,
      airportLng: 19.2613,
      airportName: '페렌츠리스트공항',
    ),
    '우크라이나': _CountryHub(
      cityLat: 50.4501,
      cityLng: 30.5234,
      cityName: '키이우',
      airportLat: 50.3450,
      airportLng: 30.8947,
      airportName: '보리스필공항',
      seaportLat: 46.4775,
      seaportLng: 30.7326,
      seaportName: '오데사항',
    ),
  };

  static _CountryHub? getHub(String country) => hubs[country];

  // ── 육로 인접 국가 쌍 (국경 공유) ────────────────────────────────────────────
  // 대한민국·일본 등 도서국가 및 북한으로 막힌 국가는 포함하지 않음
  static const Set<String> _landBorders = {
    // 북미
    '미국|캐나다', '미국|멕시코',
    // 남미
    '브라질|아르헨티나', '브라질|콜롬비아', '브라질|페루',
    '아르헨티나|칠레', '아르헨티나|페루',
    '칠레|페루', '콜롬비아|페루',
    // 유럽 서부
    '프랑스|스페인', '프랑스|이탈리아', '프랑스|독일',
    '스페인|포르투갈',
    '독일|네덜란드', '독일|덴마크',
    '독일|오스트리아', '독일|체코', '독일|폴란드',
    '이탈리아|오스트리아',
    '오스트리아|체코', '오스트리아|헝가리',
    '체코|폴란드',
    // 유럽 북부
    '노르웨이|스웨덴', '노르웨이|핀란드', '스웨덴|핀란드',
    // 유럽 동부
    '러시아|핀란드', '러시아|폴란드', '러시아|우크라이나',
    '우크라이나|폴란드', '우크라이나|헝가리',
    // 중동
    '그리스|터키', '사우디아라비아|UAE', '이스라엘|이집트',
    // 아프리카
    '케냐|에티오피아',
    // 아시아
    '인도|파키스탄', '인도|방글라데시', '인도|중국',
    '중국|러시아', '중국|베트남',
    '말레이시아|태국',
  };

  /// 두 나라 사이에 육로 국경이 있는지 확인 (순서 무관)
  static bool _isLandAdjacent(String a, String b) =>
      _landBorders.contains('$a|$b') || _landBorders.contains('$b|$a');

  /// Node.js의 findNearestHub() 포트 — 임의 좌표에서 가장 가까운 공항 허브 탐색
  static ({String country, LatLng coords, String name}) findNearestHub(
    LatLng from,
  ) {
    double minDist = double.infinity;
    String bestCountry = '대한민국';
    LatLng bestCoords = const LatLng(37.4602, 126.4407);
    String bestName = '인천국제공항';

    for (final entry in hubs.entries) {
      final hub = entry.value;
      final airCoords = LatLng(hub.airportLat, hub.airportLng);
      final dist = from.distanceTo(airCoords);
      if (dist < minDist) {
        minDist = dist;
        bestCountry = entry.key;
        bestCoords = airCoords;
        bestName = hub.airportName;
      }
    }
    return (country: bestCountry, coords: bestCoords, name: bestName);
  }

  /// Node.js의 calculateDeliveryTime() 포트 — 구간별 현실적 배송 시간 계산 (분)
  /// 경로: 발신지 → 출발 허브(트럭) → 도착 허브(항공) → 목적지(트럭)
  static int calculateDeliveryTime({
    required LatLng from,
    required LatLng startHub,
    required LatLng endHub,
    required LatLng destination,
  }) {
    final rng = Random();
    // 1) 픽업 트럭: 발신지 → 출발 공항 (60km/h, 최소 15분~최대 8시간)
    final pickupMin = (from.distanceTo(startHub) / 1000 / 60 * 60)
        .round()
        .clamp(15, 480);
    // 2) 출발 공항 대기: 30~120분
    final hubWait1 = 30 + rng.nextInt(91);
    // 3) 항공편: 출발 공항 → 도착 공항 (900km/h, 최소 45분~최대 24시간)
    final flightMin = (startHub.distanceTo(endHub) / 1000 / 900 * 60)
        .round()
        .clamp(45, 1440);
    // 4) 도착 공항 대기: 30~60분
    final hubWait2 = 30 + rng.nextInt(31);
    // 5) 라스트마일 트럭: 도착 공항 → 목적지 (60km/h, 최소 15분~최대 5시간)
    final lastMileMin = (endHub.distanceTo(destination) / 1000 / 60 * 60)
        .round()
        .clamp(15, 300);

    return pickupMin + hubWait1 + flightMin + hubWait2 + lastMileMin;
  }

  /// 두 나라 사이 배송 구간 생성
  static List<RouteSegment> buildRoute({
    required String fromCountry,
    required LatLng fromCity,
    required String toCountry,
    required LatLng toCity,
    bool preferAir = true, // 항공 우선 여부
    String? fromCityName,
    String? toCityName, // 섬 판별용 목적지 도시명
  }) {
    final fromHub = getHub(fromCountry);
    final toHub = getHub(toCountry);

    // 허브 정보가 없으면 가장 가까운 공항을 경유하는 임시 루트
    if (fromHub == null || toHub == null) {
      final nearFrom = findNearestHub(fromCity);
      final nearTo = findNearestHub(toCity);
      final fakeFromHub = hubs[nearFrom.country]!;
      final fakeToHub = hubs[nearTo.country]!;
      return _buildAirRoute(
        fromCity,
        fakeFromHub,
        toCity,
        fakeToHub,
        fromCityLabel: fromCityName ?? fromCountry,
        toCityLabel:
            toCityName != null ? '$toCountry $toCityName' : toCountry,
      );
    }

    final resolvedFromCityName =
        fromCityName ??
        _nearestCityName(fromCountry, fromCity, fallback: fromHub.cityName);
    final rawToCityName =
        toCityName ??
        _nearestCityName(toCountry, toCity, fallback: toHub.cityName);
    final resolvedToCityName = '$toCountry $rawToCityName';

    // 같은 나라 국내 배송
    if (fromCountry == toCountry) {
      final distance = fromCity.distanceTo(toCity);

      // 섬 목적지: 국제공항 있으면 항공, 없으면 선박
      if (toCityName != null && CountryCities.isIslandCity(toCityName)) {
        if (CountryCities.isIslandWithAirport(toCityName)) {
          // 섬 + 공항 → 국내선 항공
          return _buildAirRoute(
            fromCity,
            fromHub,
            toCity,
            toHub,
            fromCityLabel: resolvedFromCityName,
            toCityLabel: resolvedToCityName,
          );
        } else {
          // 섬 + 공항 없음 → 선박
          return _buildSeaRoute(
            fromCity,
            fromHub,
            toCity,
            toHub,
            fromCityLabel: resolvedFromCityName,
            toCityLabel: resolvedToCityName,
          );
        }
      }

      // 800km 이상 국내 노선은 항공 사용 (대륙 국가 대비)
      if (distance > 800000) {
        return _buildAirRoute(
          fromCity,
          fromHub,
          toCity,
          toHub,
          fromCityLabel: resolvedFromCityName,
          toCityLabel: resolvedToCityName,
        );
      }
      // 트럭 배송 (거리 비례 시간)
      final truckMin = (distance / 1000 / 80 * 60).round().clamp(
        30,
        600,
      ); // 80km/h
      return [
        RouteSegment(
          from: fromCity,
          to: toCity,
          mode: TransportMode.truck,
          fromName: resolvedFromCityName,
          toName: resolvedToCityName,
          fromType: HubType.city,
          toType: HubType.destination,
          estimatedMinutes: truckMin,
        ),
      ];
    }

    // ── 인접국 육로 우선 ───────────────────────────────────────────────────────
    // 육로 국경이 있는 나라끼리는 공항을 거치지 않고 트럭으로 직접 이동
    if (_isLandAdjacent(fromCountry, toCountry)) {
      return _buildLandRoute(
        fromCity,
        toCity,
        fromCityLabel: resolvedFromCityName,
        toCityLabel: resolvedToCityName,
      );
    }

    // ── 해외 → 국제공항 경유 필수 ─────────────────────────────────────────────
    final distance = fromCity.distanceTo(toCity);
    // 5000km 이상 + 해상 허브 있으면 선박, 나머지는 항공
    final useShip = !preferAir && distance > 5000000;

    if (useShip && fromHub.seaportLat != null && toHub.seaportLat != null) {
      return _buildSeaRoute(
        fromCity,
        fromHub,
        toCity,
        toHub,
        fromCityLabel: resolvedFromCityName,
        toCityLabel: resolvedToCityName,
      );
    } else {
      return _buildAirRoute(
        fromCity,
        fromHub,
        toCity,
        toHub,
        fromCityLabel: resolvedFromCityName,
        toCityLabel: resolvedToCityName,
      );
    }
  }

  static String _nearestCityName(
    String country,
    LatLng target, {
    required String fallback,
  }) {
    // 주요 도시 화이트리스트 사용 (경로 표시용 — 인식 가능한 도시명만)
    final list = CountryCities.majorCitiesOf(country);
    if (list.isEmpty) return fallback;
    Map<String, dynamic>? best;
    var bestDist = double.infinity;
    for (final city in list) {
      final lat = (city['lat'] as num?)?.toDouble();
      final lng = (city['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final dist = target.distanceTo(LatLng(lat, lng));
      if (dist < bestDist) {
        bestDist = dist;
        best = city;
      }
    }
    final name = best?['name'];
    return name is String && name.isNotEmpty ? name : fallback;
  }

  static List<RouteSegment> _buildAirRoute(
    LatLng fromCity,
    _CountryHub fromHub,
    LatLng toCity,
    _CountryHub toHub, {
    required String fromCityLabel,
    required String toCityLabel,
  }) {
    final fromAirport = LatLng(fromHub.airportLat, fromHub.airportLng);
    final toAirport = LatLng(toHub.airportLat, toHub.airportLng);
    final dist = fromCity.distanceTo(toCity);
    final flightMin = (dist / 1000 / 15).round().clamp(
      45,
      1440,
    ); // 900km/h = 15km/min

    return [
      RouteSegment(
        from: fromCity,
        to: fromAirport,
        mode: TransportMode.truck,
        fromName: fromCityLabel,
        toName: fromHub.airportName,
        fromType: HubType.city,
        toType: HubType.airport,
        estimatedMinutes: 60,
      ),
      RouteSegment(
        from: fromAirport,
        to: toAirport,
        mode: TransportMode.airplane,
        fromName: fromHub.airportName,
        toName: toHub.airportName,
        fromType: HubType.airport,
        toType: HubType.airport,
        estimatedMinutes: flightMin,
      ),
      RouteSegment(
        from: toAirport,
        to: toCity,
        mode: TransportMode.truck,
        fromName: toHub.airportName,
        toName: toCityLabel,
        fromType: HubType.airport,
        toType: HubType.destination,
        estimatedMinutes: 60,
      ),
    ];
  }

  static List<RouteSegment> _buildSeaRoute(
    LatLng fromCity,
    _CountryHub fromHub,
    LatLng toCity,
    _CountryHub toHub, {
    required String fromCityLabel,
    required String toCityLabel,
  }) {
    final fromPort = LatLng(fromHub.seaportLat!, fromHub.seaportLng!);
    final toPort = LatLng(toHub.seaportLat!, toHub.seaportLng!);
    final dist = fromPort.distanceTo(toPort);
    final sailMin = (dist / 1000 / 0.75).round().clamp(
      240,
      20160,
    ); // 45km/h ship speed

    return [
      RouteSegment(
        from: fromCity,
        to: fromPort,
        mode: TransportMode.truck,
        fromName: fromCityLabel,
        toName: fromHub.seaportName!,
        fromType: HubType.city,
        toType: HubType.seaport,
        estimatedMinutes: 90,
      ),
      RouteSegment(
        from: fromPort,
        to: toPort,
        mode: TransportMode.ship,
        fromName: fromHub.seaportName!,
        toName: toHub.seaportName!,
        fromType: HubType.seaport,
        toType: HubType.seaport,
        estimatedMinutes: sailMin,
      ),
      RouteSegment(
        from: toPort,
        to: toCity,
        mode: TransportMode.truck,
        fromName: toHub.seaportName!,
        toName: toCityLabel,
        fromType: HubType.seaport,
        toType: HubType.destination,
        estimatedMinutes: 90,
      ),
    ];
  }

  /// 인접 국가 직접 육로 배송 (국경 검문소 경유 트럭)
  static List<RouteSegment> _buildLandRoute(
    LatLng fromCity,
    LatLng toCity, {
    required String fromCityLabel,
    required String toCityLabel,
  }) {
    final distance = fromCity.distanceTo(toCity);
    // 국경 검문소: 두 도시의 중간 지점
    final borderLat = (fromCity.latitude + toCity.latitude) / 2;
    final borderLng = (fromCity.longitude + toCity.longitude) / 2;
    final borderPoint = LatLng(borderLat, borderLng);

    // 트럭 평균 80 km/h, 각 구간 배분
    final halfMin = (distance / 1000 / 80 * 60 / 2).round().clamp(30, 2160);
    // 국경 통관 대기 시간: 60~180분
    const borderWait = 120;

    return [
      RouteSegment(
        from: fromCity,
        to: borderPoint,
        mode: TransportMode.truck,
        fromName: fromCityLabel,
        toName: '국경 검문소',
        fromType: HubType.city,
        toType: HubType.localHub,
        estimatedMinutes: halfMin,
      ),
      RouteSegment(
        from: borderPoint,
        to: toCity,
        mode: TransportMode.truck,
        fromName: '국경 검문소',
        toName: toCityLabel,
        fromType: HubType.localHub,
        toType: HubType.destination,
        estimatedMinutes: halfMin + borderWait,
      ),
    ];
  }
}

class _CountryHub {
  final double cityLat, cityLng;
  final String cityName;
  final double airportLat, airportLng;
  final String airportName;
  final double? seaportLat, seaportLng;
  final String? seaportName;

  const _CountryHub({
    required this.cityLat,
    required this.cityLng,
    required this.cityName,
    required this.airportLat,
    required this.airportLng,
    required this.airportName,
    this.seaportLat,
    this.seaportLng,
    this.seaportName,
  });
}
