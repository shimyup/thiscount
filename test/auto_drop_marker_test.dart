// Build 284: AutoDropMarker widget smoke tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thiscount/features/map/widgets/auto_drop_marker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutoDropMarker', () {
    testWidgets('기본 렌더 — ClipOval 안 Image asset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: AutoDropMarker())),
        ),
      );
      expect(find.byType(AutoDropMarker), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);
      // Image.asset 또는 errorBuilder fallback Container 중 하나는 존재.
      // test 환경에선 asset 로딩 실패해 errorBuilder 가 보일 수 있음.
    });

    testWidgets('size custom — 48px (errorBuilder fallback 도 포함)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: AutoDropMarker(size: 48))),
        ),
      );
      // Image widget 이 size 48 로 요청됨
      final img = tester.widget<Image>(find.byType(Image).first);
      expect(img.width, 48);
      expect(img.height, 48);
    });

    testWidgets('breathing: true → 자체 _Breathing State 가 추가됨',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: AutoDropMarker(breathing: true))),
        ),
      );
      // Transform.scale 이 추가로 들어감 (호흡 효과)
      expect(find.byType(Transform), findsWidgets);
      expect(find.byType(AutoDropMarker), findsOneWidget);
    });

    testWidgets('breathing: false → 호흡 효과 없음 (smoke 렌더 OK)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: AutoDropMarker(breathing: false))),
        ),
      );
      // 위젯 트리에 AutoDropMarker 가 있고 ClipOval 만 있으면 OK
      // (breathing=false 면 Transform.scale 호흡 wrapper 가 추가되지 않음)
      expect(find.byType(AutoDropMarker), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);
    });
  });
}
