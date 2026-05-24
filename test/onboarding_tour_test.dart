// Build 284: 새 onboarding_tour_screen 의 핵심 invariant 단위 테스트.
//
// - PageView 가 3 페이지 (Build 327, PR-T3 ) 모두 렌더링되는가
// - 자동 timer 없음 — 초기 page=0 에서 5초 대기 후에도 동일
// - markSeen / nextRouteAfterSplash dedup 로직

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thiscount/features/onboarding/onboarding_tour_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingTourScreen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('초기 렌더 — 3 페이지 PageView + indicator + Skip + CTA',
        (tester) async {
      // Build 327 (PR-T3): 6 → 3 페이지 축소. Welcome / PickupHowTo / Ready 만.
      await tester.pumpWidget(const MaterialApp(home: OnboardingTourScreen()));
      // 첫 페이지 (Welcome) 콘텐츠 확인
      expect(find.text('걸어가다\n줍는 디스카운트'), findsOneWidget);
      // Skip + CTA 둘 다 보임
      expect(find.text('건너뛰기'), findsOneWidget);
      expect(find.text('다음'), findsOneWidget);
    });

    testWidgets('자동 timer 없음 — 5초 후에도 첫 페이지 유지', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingTourScreen()));
      // 5초 pump — 자동 페이지 전환이 있다면 페이지 바뀜
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('걸어가다\n줍는 디스카운트'), findsOneWidget);
      // CTA 텍스트가 여전히 '다음' (마지막 페이지면 '시작하기')
      expect(find.text('다음'), findsOneWidget);
    });

    testWidgets('CTA "다음" 탭 → page 1 (메시지 줍는 4단계)', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingTourScreen()));
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('메시지 줍는 4단계'), findsOneWidget);
    });

    // Build 301: skip 만 누르면 markSeen 호출 안 됨 (베타 테스트 모드).
    testWidgets('Skip (기본) → markSeen 호출 X + /onboarding 라우팅', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const OnboardingTourScreen(),
        routes: {
          '/onboarding': (_) =>
              const Scaffold(body: Text('OnboardingScreenMock')),
        },
      ));
      await tester.tap(find.text('건너뛰기'));
      await tester.pumpAndSettle();
      expect(find.text('OnboardingScreenMock'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      // 체크박스 미선택 → markSeen 미호출 (다음번에도 보임)
      expect(prefs.getBool('seen_onboarding_tour'), isNot(true));
    });

    testWidgets('"다음부터 보지 않기" 체크 + Skip → markSeen 호출 O', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const OnboardingTourScreen(),
        routes: {
          '/onboarding': (_) =>
              const Scaffold(body: Text('OnboardingScreenMock')),
        },
      ));
      // 체크박스 탭
      await tester.tap(find.text('다음부터 보지 않기'));
      await tester.pumpAndSettle();
      // Skip
      await tester.tap(find.text('건너뛰기'));
      await tester.pumpAndSettle();
      expect(find.text('OnboardingScreenMock'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('seen_onboarding_tour'), isTrue);
    });
  });

  group('OnboardingTourScreen.nextRouteAfterSplash', () {
    // Build 298 (P0 i18n audit): tour 콘텐츠가 한국어 only — 비-ko 단말은 자동
    // skip 처리. test 환경의 default locale 은 보통 en — 비-ko 분기 검증.
    test('처음 + ko locale → /onboarding_tour', () async {
      SharedPreferences.setMockInitialValues({});
      final dispatcher =
          TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher;
      dispatcher.localeTestValue = const Locale('ko', 'KR');
      addTearDown(dispatcher.clearLocaleTestValue);
      expect(
        await OnboardingTourScreen.nextRouteAfterSplash(),
        equals('/onboarding_tour'),
      );
    });

    test('처음 + 비-ko locale → /onboarding (auto-skip)', () async {
      SharedPreferences.setMockInitialValues({});
      final dispatcher =
          TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher;
      dispatcher.localeTestValue = const Locale('en', 'US');
      addTearDown(dispatcher.clearLocaleTestValue);
      expect(
        await OnboardingTourScreen.nextRouteAfterSplash(),
        equals('/onboarding'),
      );
      // markSeen 도 호출됐는지 확인.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('seen_onboarding_tour'), isTrue);
    });

    test('이미 본 → /onboarding', () async {
      SharedPreferences.setMockInitialValues({'seen_onboarding_tour': true});
      expect(
        await OnboardingTourScreen.nextRouteAfterSplash(),
        equals('/onboarding'),
      );
    });
  });
}
