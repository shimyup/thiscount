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
    required Future<void> Function(BrandZone zone, LatLng destination)
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
      // 사용자 현재 위치 ± 30m random offset → 정확한 zone 중심 아님 → 픽업
      // 반경 100m 이내 보장 (현재 위치 근처라서) + 깜짝 발견감.
      final dest = randomOffset(userPos, maxMeters: 30, rng: r);
      try {
        await onZoneEnter(zone, dest);
        await _markSeen(userId, zone.id);
        picked.add(zone);
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

  /// 테스트용 cache 주입.
  @visibleForTesting
  void injectCacheForTest(List<BrandZone> zones) {
    _cache = zones;
    _cachedAt = DateTime.now();
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
      return int.parse(v['integerValue'] as String);
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
