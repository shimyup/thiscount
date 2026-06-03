// Build 283 (Phase 1 MVP): Brand auto-drop trigger service.
//
// 책임:
//   1. Firestore `brand_zones` 컬렉션에서 활성 zone list 캐싱 (5분 TTL).
//   2. 사용자 위치 update 시 (`AppState._runDeliveryTick` 매 30s) 가까운
//      zone 매칭 → 처음 만나는 zone 마다 letter 자동 생성.
//   3. dedup: 같은 (user, zone) 조합은 한 번만. SharedPreferences 에
//      `brand_zones_seen_$userId` set 으로 보관 (재설치 시 reset 됨 — Phase 2
//      에서 Firestore sub-collection 으로 영구화 검토).
//   4. 새 letter 의 destinationLocation = 사용자 현재 위치 ± 30m random offset
//      (정확한 zone 중심 아님 → 깜짝 발견감 + 픽업 반경 안 보장).
//
// 호출 흐름:
//   ```dart
//   final svc = BrandZoneService.instance;
//   await svc.warmUp();                       // 앱 부팅 시 1회
//   final picked = await svc.triggerForUser(  // 30s 마다 또는 위치 50m+ 이동 시
//     userId: state.currentUser.id,
//     userPos: LatLng(state.currentUser.latitude, state.currentUser.longitude),
//     onLetterCreate: state.handleAutoBrandDrop, // AppState 가 letter 모델 + 인박스 반영
//   );
//   ```
//
// Phase 2 예정:
//   - Cloud Function 으로 server-side 검증 (Brand verified 만 zone create)
//   - geospatial index (Algolia/GeoFirestore) 로 zone 쿼리 효율화
//   - 영구 dedup (Firestore sub-collection)

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/brand_zone.dart';
import '../../models/letter.dart' show LatLng;
import '../config/firebase_config.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

class BrandZoneService {
  BrandZoneService._();
  static final BrandZoneService instance = BrandZoneService._();

  /// 활성 zone 캐시. 5분 TTL.
  List<BrandZone> _cache = const [];
  DateTime? _cachedAt;
  static const _cacheTtl = Duration(minutes: 5);

  /// SharedPreferences key prefix.
  static const _seenKey = 'brand_zones_seen_';

  bool get _hasCacheFresh =>
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!).compareTo(_cacheTtl) < 0;

  /// Build 289: admin/brand 화면에서 zone 목록을 보기 위한 read-only accessor.
  /// 최신 캐시 그대로 (admin 만 사용 — 별도 PII 위험 없음).
  List<BrandZone> get allCached => List.unmodifiable(_cache);

  /// 앱 부팅 또는 zone fetch 강제 시.
  Future<void> warmUp({bool force = false}) async {
    if (!force && _hasCacheFresh) return;
    await _refreshCache();
  }

  Future<void> _refreshCache() async {
    if (!FirebaseConfig.kFirebaseEnabled) return;
    try {
      final uri = Uri.parse(
        '${FirebaseConfig.firestoreBase}/brand_zones?pageSize=200',
      );
      final r = await http.get(uri).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return;
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      final docs = (body['documents'] as List?) ?? const [];
      final zones = <BrandZone>[];
      for (final raw in docs) {
        try {
          final fields = (raw as Map)['fields'] as Map<String, dynamic>;
          final json = _firestoreFieldsToJson(fields);
          // Firestore document id 는 name 끝의 마지막 segment.
          final name = (raw)['name'] as String? ?? '';
          json['id'] = name.split('/').last;
          zones.add(BrandZone.fromJson(json));
        } catch (e, st) {
          if (kDebugMode) debugPrint('[BrandZone] parse skip: $e\n$st');
        }
      }
      _cache = zones;
      _cachedAt = DateTime.now();
      if (kDebugMode) debugPrint('[BrandZone] cache refreshed: ${zones.length}');
    } catch (e, st) {
      if (kDebugMode) debugPrint('[BrandZone] refresh err: $e\n$st');
    }
  }

  /// 캐시된 zone 중 활성 + 거리 <= radius 인 후보 list (정렬: 가까운 순).
  List<BrandZone> candidatesNear(LatLng userPos, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final picks = _cache
        .where((z) => z.isActive(t) && z.containsPosition(userPos))
        .toList()
      ..sort((a, b) => a.distanceFrom(userPos).compareTo(b.distanceFrom(userPos)));
    return picks;
  }

  /// 사용자가 본 zone id set (Phase 2 에서 Firestore 로 이전 예정).
  Future<Set<String>> seenZones(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('$_seenKey$userId') ?? const <String>[];
    return list.toSet();
  }

  Future<void> _markSeen(String userId, String zoneId) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList('$_seenKey$userId') ?? const <String>[])
        .toSet()
      ..add(zoneId);
    await prefs.setStringList('$_seenKey$userId', set.toList());
  }

  /// 매 deliveryTick 또는 위치 update 마다 호출. 새 zone 진입을 트리거.
  ///
  /// 반환: 이번 호출에서 새로 발급된 letter 의 zone list (호출자가 letter
  /// model 생성 + Firestore POST 책임).
  ///
  /// 호출자 [onZoneEnter] 에 (zone, letterDestination) 전달 — 호출자가
  /// 실제 Letter 모델 만들고 인박스 + Firestore 반영.
  Future<List<BrandZone>> triggerForUser({
    required String userId,
    required LatLng userPos,
    // Build 421 (sim-fresh P2): 콜백이 실제 letter 생성 여부를 bool 로 보고 —
    //   false(만료/본인zone/예외)면 seen 마킹을 보류해, 잠깐 zone 을 스쳐도
    //   영구히 '받음' 처리돼 진짜 도착 시 letter 를 못 받던 문제 차단.
    required Future<bool> Function(BrandZone zone, LatLng destination)
        onZoneEnter,
    DateTime? now,
    math.Random? rng,
  }) async {
    if (userId.isEmpty) return const [];
    await warmUp();
    final seen = await seenZones(userId);
    final candidates = candidatesNear(userPos, now: now)
        .where((z) => !seen.contains(z.id))
        .toList();
    if (candidates.isEmpty) return const [];

    final picked = <BrandZone>[];
    final r = rng ?? math.Random();
    for (final zone in candidates) {
      // 사용자 현재 위치 ± 10m random offset → 정확한 zone 중심 아님 → 픽업
      // 반경 100m 이내 보장 (현재 위치 근처라서) + 깜짝 발견감.
      // Build 394 (PR-HH3 audit 지도 P0-4): 30m → 10m. 이전 30m offset +
      //   사용자 이동으로 pickup radius 200m 초과 → deliveredFar 강등 → letter
      //   못 받는 회귀. 10m 면 사용자가 200m 이동해도 안전 margin 확보.
      final dest = randomOffset(userPos, maxMeters: 10, rng: r);
      try {
        final delivered = await onZoneEnter(zone, dest);
        // letter 가 실제로 생성된 경우에만 seen 마킹 (재시도 여지 보존).
        if (delivered) {
          await _markSeen(userId, zone.id);
          picked.add(zone);
        }
      } catch (e, st) {
        if (kDebugMode) debugPrint('[BrandZone] trigger err ${zone.id}: $e\n$st');
      }
    }
    return picked;
  }

  /// 사용자 좌표를 중심으로 [maxMeters] 이내 random 좌표 반환.
  /// random angle (0..2π) + random distance (uniform 0..maxMeters).
  /// haversine 역연산 (small angle approximation 으로 충분 — 30m 수준에선 오차 <1cm).
  static LatLng randomOffset(
    LatLng origin, {
    required double maxMeters,
    math.Random? rng,
  }) {
    final r = rng ?? math.Random();
    final angle = r.nextDouble() * 2 * math.pi;
    final distance = r.nextDouble() * maxMeters;
    const earthR = 6371000.0;
    // 위도 1° ≈ 111.32 km. 경도 1° ≈ 111.32 km × cos(latitude).
    final dLatRad = (distance * math.cos(angle)) / earthR;
    final dLngRad =
        (distance * math.sin(angle)) /
        (earthR * math.cos(origin.latitude * math.pi / 180));
    final newLat = origin.latitude + dLatRad * 180 / math.pi;
    final newLng = origin.longitude + dLngRad * 180 / math.pi;
    return LatLng(newLat, newLng);
  }

  /// 캐시 강제 비움 (테스트 / 디버그용).
  void clearCacheForTest() {
    _cache = const [];
    _cachedAt = null;
  }

  /// Build 317: Brand 자동 발송 캠페인 zone 등록 (Firestore POST).
  /// 옵션: radiusM (300 or 2000), maxRedeems (0 = 상시 / 양수 = 한정).
  ///
  /// Build 360 (PR-AA1): 두 변경.
  ///   1. `center` 필드를 admin 흐름과 동일한 `mapValue {lat, lng}` 로 통일.
  ///      이전 평면 `centerLat`/`centerLng` 스키마는 `BrandZone.fromJson`
  ///      이 `j['center'] as Map` 으로 읽어서 silent parse-skip 됐었음
  ///      → compose 로 생성한 zone 이 cache 에 들어가지 못해 trigger 안 됨.
  ///   2. [redemptionCode] 매장 코드 자동 부여 (zone 1개 = 코드 1개, bulk
  ///      letter 들 동일 코드 공유). null 이면 코드 없는 일반 zone.
  Future<String?> createZone({
    required String brandId,
    required String brandName,
    required LatLng center,
    required double radiusM,
    required String content,
    String? redemptionInfo,
    int maxRedeems = 0,
    int durationDays = 30,
    String? redemptionCode,
  }) async {
    if (!FirebaseConfig.kFirebaseEnabled) return null;
    if (brandId.isEmpty || content.isEmpty) return null;
    // Build 371 (PR-CC5 P0 #19): durationDays 클램프 1-90 — rule 에서 ISO8601
    //   string size 만 검증 가능, 실제 duration cap 은 클라이언트가 책임.
    //   영구 zone (9999-12-31) 차단 — read cap 점유 amplification 방어.
    final clampedDays = durationDays.clamp(1, 90);
    try {
      final now = DateTime.now().toUtc();
      final expires = now.add(Duration(days: clampedDays));
      final fields = <String, dynamic>{
        'brandId': {'stringValue': brandId},
        'brandName': {'stringValue': brandName},
        'center': {
          'mapValue': {
            'fields': {
              'lat': {'doubleValue': center.latitude},
              'lng': {'doubleValue': center.longitude},
            },
          },
        },
        'radiusM': {'doubleValue': radiusM},
        'content': {'stringValue': content},
        if (redemptionInfo != null && redemptionInfo.isNotEmpty)
          'redemptionInfo': {'stringValue': redemptionInfo},
        if (redemptionCode != null && redemptionCode.isNotEmpty)
          'redemptionCode': {'stringValue': redemptionCode},
        // Build 366 (PR-BB5): timestamp 필드를 admin path 와 통일해 stringValue
        //   로. Firestore rules 의 isValidBrandZoneCreate 가 `is string` 검사
        //   → timestampValue 면 rule 강화 시 reject 가능. 양 path 동일 schema.
        'startsAt': {'stringValue': now.toIso8601String()},
        'expiresAt': {'stringValue': expires.toIso8601String()},
        'maxRedeems': {'integerValue': '$maxRedeems'},
        'redeemedCount': {'integerValue': '0'},
        'createdAt': {'stringValue': now.toIso8601String()},
      };
      final uri = Uri.parse(
        '${FirebaseConfig.firestoreBase}/brand_zones'
        '?key=${FirebaseConfig.apiKey}',
      );
      final body = jsonEncode({'fields': fields});
      // Build 409 (sim P0.2): 인증 토큰 부착. firestore.rules 의 brand_zones
      //   create 는 isSignedIn()(request.auth != null) 필요 — apiKey 만으론
      //   request.auth 가 비어 403 reject. 다른 인증 write 와 동일하게
      //   ensureValidToken() + Bearer 헤더(FirestoreService.authHeaders) 사용.
      await FirebaseAuthService.ensureValidToken();
      final r = await http
          .post(
            uri,
            headers: FirestoreService.authHeaders,
            body: body,
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode < 200 || r.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('[BrandZone] createZone ${r.statusCode}: ${r.body}');
        }
        return null;
      }
      final resp = jsonDecode(r.body) as Map<String, dynamic>;
      final docName = resp['name'] as String? ?? '';
      final id = docName.split('/').last;
      // Build 364 (PR-BB3): cache 무효화 race fix.
      //   이전엔 `_cache = const []` + `_cachedAt = null` → 다음 triggerForUser
      //   가 8초간 _refreshCache 대기. 그 사이 첫 손님이 zone 진입 시 letter
      //   못 받는 윈도우. 대신 새 zone 을 in-place inject + timestamp 유지.
      final newZone = BrandZone(
        id: id,
        brandId: brandId,
        brandName: brandName,
        center: center,
        radiusM: radiusM,
        content: content,
        redemptionInfo: redemptionInfo,
        startsAt: now.toLocal(),
        expiresAt: expires.toLocal(),
        maxRedeems: maxRedeems,
        redeemedCount: 0,
        createdAt: now.toLocal(),
        redemptionCode: redemptionCode,
      );
      _cache = List<BrandZone>.unmodifiable([..._cache, newZone]);
      // _cachedAt 유지 — 다음 triggerForUser 는 in-memory 즉시 응답.
      return id;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[BrandZone] createZone err: $e\n$st');
      return null;
    }
  }

  /// 테스트용 cache 주입.
  @visibleForTesting
  void injectCacheForTest(List<BrandZone> zones) {
    _cache = zones;
    _cachedAt = DateTime.now();
  }

  /// Build 368 (PR-CC3 P0 #14): in-memory cache 의 zone redeemedCount +1.
  /// AppState._handleAutoBrandDrop 가 Firestore PATCH 와 동시 호출.
  /// 다음 isActive 검증이 정확 — `redeemedCount >= maxRedeems` 가드 작동.
  void bumpRedeemedCount(String zoneId) {
    final updated = <BrandZone>[];
    var changed = false;
    for (final z in _cache) {
      if (z.id == zoneId) {
        updated.add(z.copyWith(redeemedCount: z.redeemedCount + 1));
        changed = true;
      } else {
        updated.add(z);
      }
    }
    if (changed) _cache = List<BrandZone>.unmodifiable(updated);
  }

  /// Firestore REST 응답의 `fields` 객체를 일반 JSON map 으로 변환.
  /// (Firebase REST 의 typed value 표현 ↔ 우리 모델의 plain JSON)
  Map<String, dynamic> _firestoreFieldsToJson(Map<String, dynamic> fields) {
    final out = <String, dynamic>{};
    for (final entry in fields.entries) {
      out[entry.key] = _firestoreValue(entry.value);
    }
    return out;
  }

  dynamic _firestoreValue(dynamic v) {
    if (v is! Map<String, dynamic>) return v;
    if (v.containsKey('stringValue')) return v['stringValue'];
    if (v.containsKey('integerValue')) {
      // Build 423 (sim-crosscut P2): FirestoreService 와 동일하게 방어적 파싱 —
      //   integerValue 가 비-String(예: num)으로 와도 zone 전체가 드롭되지 않게.
      return int.tryParse(v['integerValue'].toString()) ?? 0;
    }
    if (v.containsKey('doubleValue')) return (v['doubleValue'] as num).toDouble();
    if (v.containsKey('booleanValue')) return v['booleanValue'] as bool;
    if (v.containsKey('timestampValue')) return v['timestampValue'];
    if (v.containsKey('nullValue')) return null;
    if (v.containsKey('mapValue')) {
      final inner = (v['mapValue'] as Map<String, dynamic>)['fields']
          as Map<String, dynamic>? ??
          <String, dynamic>{};
      return _firestoreFieldsToJson(inner);
    }
    if (v.containsKey('arrayValue')) {
      final values =
          ((v['arrayValue'] as Map<String, dynamic>)['values'] as List?) ??
              const [];
      return values.map(_firestoreValue).toList();
    }
    return v;
  }
}
