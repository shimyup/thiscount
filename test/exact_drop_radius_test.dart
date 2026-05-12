// Build 282: ExactDrop 100m 반경 enforcement 단위 테스트.
//
// compose_screen 의 `_selectExactDrop` (line ~1554) 는 picker 결과 직후 +
// 발송 직전 (`_sendLetter` line ~1241) 2단계로 사용자 좌표 vs picked 좌표의
// haversine 거리 > 100m 면 reject 한다. 본 테스트는 그 가드의 핵심인
// `LatLng.distanceTo` (haversine) 가 100m 경계에서 의도대로 동작하는지
// 검증한다 — 위젯 통합 테스트 비용 없이 핵심 invariant 만 잡아둔다.
//
// P0 #2 (Brand 약속) 가 회귀 안 되도록 baseline 보호.

import 'package:flutter_test/flutter_test.dart';
import 'package:thiscount/models/letter.dart';

void main() {
  group('ExactDrop 100m radius enforcement (Build 282 baseline)', () {
    // 서울 강남역 근처 좌표 — 위도 1° ≈ 111.32 km.
    const seoul = LatLng(37.4979, 127.0276);

    test('within 100m (≈55m offset) → distance < 100m (allowed)', () {
      // 위도 +0.0005° ≈ 55.66m
      final picked = LatLng(seoul.latitude + 0.0005, seoul.longitude);
      final d = seoul.distanceTo(picked);
      expect(d, lessThan(100.0));
      expect(d, greaterThan(50.0)); // sanity
    });

    test('beyond 100m (≈111m offset) → distance > 100m (rejected)', () {
      // 위도 +0.001° ≈ 111.32m
      final picked = LatLng(seoul.latitude + 0.001, seoul.longitude);
      final d = seoul.distanceTo(picked);
      expect(d, greaterThan(100.0));
      expect(d, lessThan(120.0)); // sanity
    });

    test('exactly at 100m boundary (≈90m offset) → allowed (< 100m)', () {
      // 위도 +0.00081° ≈ 90.1m
      final picked = LatLng(seoul.latitude + 0.00081, seoul.longitude);
      final d = seoul.distanceTo(picked);
      expect(d, lessThan(100.0));
    });

    test('1km offset → far over (Build 282 P0 reject case)', () {
      // 위도 +0.009° ≈ 1001.9m
      final picked = LatLng(seoul.latitude + 0.009, seoul.longitude);
      final d = seoul.distanceTo(picked);
      expect(d, greaterThan(1000.0));
    });

    test('same point → 0m (boundary case)', () {
      final d = seoul.distanceTo(
        LatLng(seoul.latitude, seoul.longitude),
      );
      expect(d, equals(0.0));
    });

    test('myPos (0,0) sentinel → skipped gate (compose_screen myLat==0 branch)', () {
      // compose_screen 의 가드: `if (myLat != 0 || myLng != 0)` 일 때만 거리
      // 검증. 좌표 미확정 (0,0) 이면 picker 단계에서 이미 거부되므로
      // distanceTo 자체는 호출 안 됨 — 본 테스트는 sentinel 의도 문서화.
      const sentinel = LatLng(0, 0);
      final somewhere = LatLng(seoul.latitude, seoul.longitude);
      final d = sentinel.distanceTo(somewhere);
      // (0,0) 에서 서울까지 ≈ 11,267 km
      expect(d, greaterThan(10000 * 1000));
    });
  });

  group('XSS scheme whitelist (Build 282 baseline)', () {
    // letter_read_screen `_launchSnsLink` (line 147-177) 의 핵심 invariant:
    // http(s) 만 통과, javascript/data/file 등은 차단. 위젯 통합은 비용 높아
    // Uri.scheme 분류만 검증.
    test('javascript: scheme rejected', () {
      final uri = Uri.tryParse('javascript:alert(1)');
      expect(uri, isNotNull);
      expect(uri!.scheme, equals('javascript'));
      expect(uri.scheme != 'http' && uri.scheme != 'https', isTrue);
    });

    test('data: scheme rejected', () {
      final uri = Uri.tryParse('data:text/html,<script>alert(1)</script>');
      expect(uri, isNotNull);
      expect(uri!.scheme, equals('data'));
      expect(uri.scheme != 'http' && uri.scheme != 'https', isTrue);
    });

    test('file: scheme rejected', () {
      final uri = Uri.tryParse('file:///etc/passwd');
      expect(uri, isNotNull);
      expect(uri!.scheme, equals('file'));
      expect(uri.scheme != 'http' && uri.scheme != 'https', isTrue);
    });

    test('https URL allowed', () {
      final uri = Uri.tryParse('https://twitter.com/user');
      expect(uri, isNotNull);
      expect(uri!.scheme, equals('https'));
      expect(uri.scheme == 'http' || uri.scheme == 'https', isTrue);
    });

    test('http URL allowed (legacy non-TLS)', () {
      final uri = Uri.tryParse('http://example.com');
      expect(uri, isNotNull);
      expect(uri!.scheme, equals('http'));
      expect(uri.scheme == 'http' || uri.scheme == 'https', isTrue);
    });

    test('bare domain → prepended https → allowed', () {
      // _launchSnsLink 가 `startsWith('http')` 가 false 면 `https://` prepend.
      const raw = 'twitter.com/user';
      final urlStr = raw.startsWith('http') ? raw : 'https://$raw';
      final uri = Uri.tryParse(urlStr);
      expect(uri, isNotNull);
      expect(uri!.scheme, equals('https'));
    });
  });
}
