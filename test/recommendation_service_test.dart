// Build 324: RecommendationService 핵심 scoring 동작 회귀 방지.
import 'package:flutter_test/flutter_test.dart';
import 'package:thiscount/core/services/recommendation_service.dart';
import 'package:thiscount/models/letter.dart';
import 'package:thiscount/models/user_profile.dart';

Letter _letter({
  String id = 'L',
  String senderId = 'brand1',
  String? categoryTag,
  LetterCategory category = LetterCategory.coupon,
  LetterSenderTier senderTier = LetterSenderTier.brand,
  bool senderIsBrand = true,
  DateTime? redemptionExpiresAt,
  DateTime? expiresAt,
  DateTime? redeemedAt,
  int likeCount = 0,
  int ratingTotal = 0,
  int ratingCount = 0,
  LatLng? destination,
  bool isReadByRecipient = false,
}) {
  final now = DateTime.now();
  return Letter(
    id: id,
    senderId: senderId,
    senderName: 'Brand',
    senderCountry: '대한민국',
    senderCountryFlag: '🇰🇷',
    content: 'x',
    originLocation: LatLng(37.5665, 126.978),
    destinationLocation: destination ?? LatLng(37.5665, 126.978),
    destinationCountry: '대한민국',
    destinationCountryFlag: '🇰🇷',
    segments: const [],
    sentAt: now,
    estimatedTotalMinutes: 60,
    senderIsBrand: senderIsBrand,
    senderTier: senderTier,
    category: category,
    categoryTag: categoryTag,
    redemptionExpiresAt: redemptionExpiresAt,
    expiresAt: expiresAt,
    redeemedAt: redeemedAt,
    likeCount: likeCount,
    ratingTotal: ratingTotal,
    ratingCount: ratingCount,
    isReadByRecipient: isReadByRecipient,
  );
}

UserProfile _user({
  String? preferredCategoryKey,
  double latitude = 37.5665,
  double longitude = 126.978,
  bool isPremium = true,
}) =>
    UserProfile(
      id: 'u1',
      username: 'u',
      country: '대한민국',
      countryFlag: '🇰🇷',
      isPremium: isPremium,
      latitude: latitude,
      longitude: longitude,
      preferredCategoryKey: preferredCategoryKey,
    );

void main() {
  group('RecommendationService.score', () {
    test('redeemed letter → 강한 음수', () {
      final l = _letter(redeemedAt: DateTime.now().subtract(const Duration(hours: 1)));
      final s = RecommendationService.score(l, _user(),
          followedBrandIds: {});
      expect(s, lessThan(0));
    });

    test('만료된 쿠폰 → 더 강한 음수 (-100)', () {
      final l = _letter(
        redemptionExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      final s = RecommendationService.score(l, _user(),
          followedBrandIds: {});
      expect(s, lessThanOrEqualTo(-100));
    });

    test('preferredCategoryKey 일치 → 카테고리 미일치보다 높음', () {
      final match = _letter(categoryTag: 'food');
      final miss = _letter(categoryTag: 'beauty');
      final u = _user(preferredCategoryKey: 'food');
      final sMatch = RecommendationService.score(match, u, followedBrandIds: {});
      final sMiss = RecommendationService.score(miss, u, followedBrandIds: {});
      expect(sMatch, greaterThan(sMiss));
    });

    test('만료 24h 이내 → 만료 7일 이상보다 높음', () {
      final urgent = _letter(
        redemptionExpiresAt: DateTime.now().add(const Duration(hours: 12)),
      );
      final relaxed = _letter(
        redemptionExpiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      final s1 = RecommendationService.score(urgent, _user(),
          followedBrandIds: {});
      final s2 = RecommendationService.score(relaxed, _user(),
          followedBrandIds: {});
      expect(s1, greaterThan(s2));
    });

    test('팔로우 브랜드 letter → 비팔로우보다 높음', () {
      final followed = _letter(senderId: 'brandA');
      final unfollowed = _letter(senderId: 'brandB');
      final u = _user();
      final s1 = RecommendationService.score(followed, u,
          followedBrandIds: {'brandA'});
      final s2 = RecommendationService.score(unfollowed, u,
          followedBrandIds: {'brandA'});
      expect(s1, greaterThan(s2));
    });

    test('근거리 letter → 원거리보다 높음', () {
      // 서울 강남
      const seoul = LatLng(37.5665, 126.978);
      // 부산 (~325km)
      final busan = LatLng(35.1796, 129.0756);
      final near = _letter(destination: seoul);
      final far = _letter(destination: busan);
      final u = _user(latitude: seoul.latitude, longitude: seoul.longitude);
      final s1 = RecommendationService.score(near, u, followedBrandIds: {});
      final s2 = RecommendationService.score(far, u, followedBrandIds: {});
      expect(s1, greaterThan(s2));
    });
  });

  group('RecommendationService.rank', () {
    test('빈 입력 → 빈 출력', () {
      final result =
          RecommendationService.rank([], _user(), followedBrandIds: {});
      expect(result, isEmpty);
    });

    test('redeemed letter 는 unredeemed letter 아래로 정렬', () {
      final used = _letter(
        id: 'used',
        redeemedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final fresh = _letter(id: 'fresh');
      final ranked = RecommendationService.rank(
        [used, fresh],
        _user(),
        followedBrandIds: {},
      );
      expect(ranked.first.id, 'fresh');
      expect(ranked.last.id, 'used');
    });

    test('preferred 카테고리 letter 가 다른 letter 들보다 상위', () {
      final pref = _letter(id: 'p', categoryTag: 'food');
      final other = _letter(id: 'o', categoryTag: 'beauty');
      final ranked = RecommendationService.rank(
        [other, pref],
        _user(preferredCategoryKey: 'food'),
        followedBrandIds: {},
      );
      expect(ranked.first.id, 'p');
    });

    test('동점일 때 최신 sentAt 우선', () {
      // 동일한 score 가 나오도록 모든 입력을 똑같이 — sentAt 만 다름.
      final older = _letter(id: 'old');
      final newer = _letter(id: 'new');
      // Letter._letter 헬퍼는 sentAt = now 라 둘이 동시. 직접 조정.
      // 대신 두 letter 가 서로 다른 sentAt 을 가지도록 시간차 letter 만들기.
      final list = [
        Letter(
          id: 'old',
          senderId: 'brand1',
          senderName: 'Brand',
          senderCountry: '대한민국',
          senderCountryFlag: '🇰🇷',
          content: '',
          originLocation: LatLng(0, 0),
          destinationLocation: LatLng(0, 0),
          destinationCountry: '대한민국',
          destinationCountryFlag: '🇰🇷',
          segments: const [],
          sentAt: DateTime.now().subtract(const Duration(hours: 5)),
          estimatedTotalMinutes: 60,
          senderIsBrand: true,
          senderTier: LetterSenderTier.brand,
          category: LetterCategory.coupon,
        ),
        Letter(
          id: 'new',
          senderId: 'brand1',
          senderName: 'Brand',
          senderCountry: '대한민국',
          senderCountryFlag: '🇰🇷',
          content: '',
          originLocation: LatLng(0, 0),
          destinationLocation: LatLng(0, 0),
          destinationCountry: '대한민국',
          destinationCountryFlag: '🇰🇷',
          segments: const [],
          sentAt: DateTime.now().subtract(const Duration(hours: 1)),
          estimatedTotalMinutes: 60,
          senderIsBrand: true,
          senderTier: LetterSenderTier.brand,
          category: LetterCategory.coupon,
        ),
      ];
      // 둘 다 동일한 신호 → score 동점 → tiebreaker 로 newer 가 먼저.
      final ranked = RecommendationService.rank(
        list,
        _user(),
        followedBrandIds: {},
      );
      expect(ranked.first.id, 'new');
      // older 참조 silencing — _letter helper 사용 안 한 이유는 sentAt 차이 필요.
      expect(older.id, 'old'); // sanity
      expect(newer.id, 'new');
    });
  });
}
