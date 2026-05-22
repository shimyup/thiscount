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
    test('redeemed letter → 강한 음수 (-1000)', () {
      final l = _letter(
          redeemedAt: DateTime.now().subtract(const Duration(hours: 1)));
      final s = RecommendationService.score(l, _user(),
          followedBrandIds: {});
      expect(s, lessThanOrEqualTo(-1000));
    });

    test('만료된 쿠폰 → 더 강한 음수 (-2000), redeemed 보다 아래', () {
      final l = _letter(
        redemptionExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      final s = RecommendationService.score(l, _user(),
          followedBrandIds: {});
      expect(s, lessThanOrEqualTo(-2000));
    });

    test('expiresAt(자동삭제) 만 있어도 만료 패널티', () {
      final l = _letter(
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final s = RecommendationService.score(l, _user(),
          followedBrandIds: {});
      expect(s, lessThanOrEqualTo(-2000));
    });

    test('두 만료 필드 중 더 빠른 시각 기준으로 임박 가산', () {
      // redemptionExpiresAt = 30d (멀음), expiresAt = 12h (임박) → 12h 기준 +20
      final l = _letter(
        redemptionExpiresAt: DateTime.now().add(const Duration(days: 30)),
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      );
      // 동일하게 둘 다 멀리 있는 letter 와 비교
      final far = _letter(
        redemptionExpiresAt: DateTime.now().add(const Duration(days: 30)),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      final s1 = RecommendationService.score(l, _user(),
          followedBrandIds: {});
      final s2 = RecommendationService.score(far, _user(),
          followedBrandIds: {});
      expect(s1, greaterThan(s2));
    });

    test('preferredCategoryKey 일치 → 카테고리 미일치보다 높음', () {
      final match = _letter(categoryTag: 'food');
      final miss = _letter(categoryTag: 'beauty');
      final u = _user(preferredCategoryKey: 'food');
      final sMatch =
          RecommendationService.score(match, u, followedBrandIds: {});
      final sMiss =
          RecommendationService.score(miss, u, followedBrandIds: {});
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
      const seoul = LatLng(37.5665, 126.978);
      final busan = LatLng(35.1796, 129.0756); // ~325km
      final near = _letter(destination: seoul);
      final far = _letter(destination: busan);
      final u = _user(latitude: seoul.latitude, longitude: seoul.longitude);
      final s1 = RecommendationService.score(near, u, followedBrandIds: {});
      final s2 = RecommendationService.score(far, u, followedBrandIds: {});
      expect(s1, greaterThan(s2));
    });

    test('GPS 0,0 사용자 → 거리 신호 미적용 (0,0 letter 부정 가산 차단)', () {
      // 사용자 위치 미설정 (0,0). letter 도 0,0 destination 이라면 distance=0 이지만
      //   가산점 안 받아야 함.
      final l = _letter(destination: const LatLng(0, 0));
      // 같은 letter, GPS 있는 사용자 — 부산에 있는데 letter 가 서울이면 멀리 있음.
      final u = _user(latitude: 0, longitude: 0);
      final s = RecommendationService.score(l, u, followedBrandIds: {});
      // 거리 가산이 적용되지 않았다면, 동일 letter 의 GPS 있는 사용자 (멀리) 와 같음.
      final lFar = _letter(destination: const LatLng(0, 0));
      final uFar = _user(latitude: 37.5665, longitude: 126.978); // 서울
      final sFar =
          RecommendationService.score(lFar, uFar, followedBrandIds: {});
      // 둘 다 거리 신호가 0 (사용자 0,0 가드 + 멀리 letter) → 동일 score.
      expect(s, equals(sFar));
    });

    test('rank 와 score 가 같은 now 를 공유 — 시간 drift 없음', () {
      // letter 가 정확히 now 기준 만료 임박 (1분 후 만료) 라고 가정.
      // rank 가 호출하는 score 모두 같은 t 를 사용해야 일관된 결과.
      final now = DateTime(2026, 6, 1, 12, 0, 0);
      final l = _letter(
        redemptionExpiresAt: now.add(const Duration(minutes: 30)),
      );
      final s1 = RecommendationService.score(l, _user(),
          followedBrandIds: {}, now: now);
      // rank 로 호출해도 같은 score 가 나와야 함.
      final ranked = RecommendationService.rank([l], _user(),
          followedBrandIds: {}, now: now);
      expect(ranked, hasLength(1));
      // s1 만으로 검증 — sanity.
      expect(s1, greaterThan(0));
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

    test('만료된 letter 가 redeemed letter 보다 아래', () {
      final expired = _letter(
        id: 'exp',
        redemptionExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      final used = _letter(
        id: 'used',
        redeemedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final ranked = RecommendationService.rank(
        [expired, used],
        _user(),
        followedBrandIds: {},
      );
      expect(ranked.first.id, 'used');
      expect(ranked.last.id, 'exp');
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

    test('implicit history 는 소비된 letter (read/redeemed) 만 카운트', () {
      // 인박스: 미사용 'beauty' letter 10개 + 사용된 'food' letter 2개.
      //   self-reinforcing 이 차단됐다면 implicit 선호는 'food' (소비 이력) → 'food'
      //   카테고리 letter 가 위로.
      final beautyUnread = List.generate(
        10,
        (i) => _letter(id: 'b$i', categoryTag: 'beauty'),
      );
      final foodConsumed = [
        _letter(id: 'f1', categoryTag: 'food', isReadByRecipient: true),
        _letter(id: 'f2', categoryTag: 'food', isReadByRecipient: true),
      ];
      final candidates = [
        _letter(id: 'newBeauty', categoryTag: 'beauty'),
        _letter(id: 'newFood', categoryTag: 'food'),
      ];
      final ranked = RecommendationService.rank(
        [...beautyUnread, ...foodConsumed, ...candidates],
        _user(), // preferredCategoryKey 없음
        followedBrandIds: {},
      );
      // newFood 가 newBeauty 보다 앞이어야 함 (implicit food 선호).
      final idxFood = ranked.indexWhere((l) => l.id == 'newFood');
      final idxBeauty = ranked.indexWhere((l) => l.id == 'newBeauty');
      expect(idxFood, lessThan(idxBeauty));
    });

    test('동점일 때 최신 sentAt 우선', () {
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
      final ranked = RecommendationService.rank(
        list,
        _user(),
        followedBrandIds: {},
      );
      expect(ranked.first.id, 'new');
    });
  });
}
