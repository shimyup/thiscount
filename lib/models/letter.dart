import 'dart:math';
import '../core/data/country_cities.dart';

// ── 편지 타입 ──────────────────────────────────────────────────────────────────
enum LetterType { normal, express }

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

  String get label {
    switch (this) {
      case TransportMode.truck:
        return '육상 배송';
      case TransportMode.airplane:
        return '항공 배송';
      case TransportMode.ship:
        return '해상 배송';
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
  int likeCount;
  int ratingTotal;
  int ratingCount;
  final int paperStyle;
  final int fontStyle;
  final String? deliveryEmoji; // 유저가 고른 배송 이모티콘 (없으면 운송수단 기본값)

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
    this.likeCount = 0,
    this.ratingTotal = 0,
    this.ratingCount = 0,
    this.paperStyle = 0,
    this.fontStyle = 0,
    this.deliveryEmoji,
  }) : reportedBy = reportedBy ?? {};

  double get avgRating => ratingCount > 0 ? ratingTotal / ratingCount : 0.0;
  bool get isBlocked => reportCount >= 3;

  // ── 현재 구간 ───────────────────────────────────────────────────────────────
  RouteSegment get currentSegment =>
      segments[currentSegmentIndex.clamp(0, segments.length - 1)];

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
  String get statusLabel {
    switch (status) {
      case DeliveryStatus.composing:
        return '작성 중';
      case DeliveryStatus.inTransit:
        return currentSegment.mode.label;
      case DeliveryStatus.nearYou:
        return '근처 도착!';
      case DeliveryStatus.deliveredFar:
        return '도착 (수령 대기)';
      case DeliveryStatus.delivered:
        return '배달 완료';
      case DeliveryStatus.read:
        return '읽음';
    }
  }

  String get currentStageLabel {
    if (status == DeliveryStatus.nearYou) return '📍 500m 이내 도착!';
    if (status == DeliveryStatus.deliveredFar) return '📬 목적지 도착 - 현지 수령 필요';
    if (status == DeliveryStatus.delivered || status == DeliveryStatus.read) {
      return '✅ 배달 완료';
    }
    final seg = currentSegment;
    return '${seg.mode.emoji}  ${seg.fromName} → ${seg.toName}';
  }

  // ── 현실적인 배송 예상 시간 ─────────────────────────────────────────────────
  String get realisticEtaLabel {
    final m = estimatedTotalMinutes;
    if (m < 300) return '당일 배송 (1-2일)';
    if (m < 2880) return '국내 배송 (2-5일)';
    if (m < 10080) return '국제 항공 (5-10일)';
    if (m < 20160) return '국제 항공 (7-14일)';
    return '국제 선박 (20-45일)';
  }

  // ── 예상 도착 시각 라벨 ─────────────────────────────────────────────────────
  String get arrivalTimeLabel {
    if (status == DeliveryStatus.nearYou) return '근처 도착! 수령 가능 📍';
    if (status == DeliveryStatus.deliveredFar) return '목적지 도착 · 현지 수령 대기';
    if (status == DeliveryStatus.delivered || status == DeliveryStatus.read) {
      return '도착 완료 ✅';
    }

    final remainMin =
        ((1.0 - overallProgress.clamp(0.0, 1.0)) * estimatedTotalMinutes)
            .ceil();
    if (remainMin <= 0) return '도착 완료 ✅';
    if (remainMin < 60) return '약 $remainMin분 후 도착';

    if (remainMin < 1440) {
      final h = remainMin ~/ 60;
      final m = remainMin % 60;
      if (m == 0) return '약 $h시간 후 도착';
      return '약 $h시간 $m분 후 도착';
    }

    final days = (remainMin / 1440).ceil();
    final etaDate = DateTime.now().add(Duration(minutes: remainMin));
    return '약 $days일 후 도착 (${_fmtDate(etaDate)})';
  }

  static String _fmtDate(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ── 예상 남은 시간 ──────────────────────────────────────────────────────────
  String get etaLabel => arrivalTimeLabel;

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
  };

  static Letter fromJson(Map<String, dynamic> j) => Letter(
    id: j['id'] as String,
    senderId: j['senderId'] as String,
    senderName: j['senderName'] as String,
    senderCountry: j['senderCountry'] as String,
    senderCountryFlag: j['senderCountryFlag'] as String,
    content: j['content'] as String,
    originLocation: LatLng.fromJson(
      j['originLocation'] as Map<String, dynamic>,
    ),
    destinationLocation: LatLng.fromJson(
      j['destinationLocation'] as Map<String, dynamic>,
    ),
    destinationCountry: j['destinationCountry'] as String,
    destinationCountryFlag: j['destinationCountryFlag'] as String,
    destinationCity: j['destinationCity'] as String?,
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
  };

  static _CountryHub? getHub(String country) => hubs[country];

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

    // 허브 정보가 없으면 직선 루트
    if (fromHub == null || toHub == null) {
      return [
        RouteSegment(
          from: fromCity,
          to: toCity,
          mode: TransportMode.airplane,
          fromName: fromCountry,
          toName: toCountry,
          fromType: HubType.city,
          toType: HubType.destination,
          estimatedMinutes: 480,
        ),
      ];
    }

    final resolvedFromCityName =
        fromCityName ??
        _nearestCityName(fromCountry, fromCity, fallback: fromHub.cityName);
    final resolvedToCityName =
        toCityName ??
        _nearestCityName(toCountry, toCity, fallback: toHub.cityName);

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

    final distance = fromCity.distanceTo(toCity);
    // 5000km 이상 = 항공 또는 선박, 그 이하 = 항공 우선
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
    final list = CountryCities.cities[country];
    if (list == null || list.isEmpty) return fallback;
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
