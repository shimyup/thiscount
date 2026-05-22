import '../../models/letter.dart';
import '../../models/user_profile.dart';

/// Build 324: AI 추천 정렬 모드의 핵심 scoring 엔진.
///
/// 외부 LLM 호출 없이 on-device heuristic 으로 작동 (offline 안전, API 비용 0).
/// 입력 신호를 가중 합산해서 letter 별 score 를 산출하고, score DESC 로 정렬한 결과를
/// 인박스에 노출한다.
///
/// **설계 근거**
/// - 기존 산업군 필터·중요도 정렬도 모두 heuristic 기반이라 일관성 유지.
/// - 사용자 행동 (followed brand / preferredCategoryKey / 인박스의 categoryTag 분포)
///   에서 선호를 추출 → 같은 카테고리·만료 임박·미사용·근거리·신뢰도 높은 letter 를
///   상위로 끌어올린다.
/// - **사용된 쿠폰 / 만료된 쿠폰** 은 큰 음수 가중치로 하단으로 밀어낸다 (UX: 끝났는데
///   상단에 있으면 짜증).
class RecommendationService {
  RecommendationService._();

  /// 한 letter 의 추천 score 산출. 큰 값일수록 상위 노출.
  /// [historyByCategory] 는 사용자가 과거 픽업한 letter 의 categoryTag → 빈도.
  /// preferredCategoryKey 가 비어 있을 때 implicit 선호를 추정하는 데 쓰임.
  static double score(
    Letter letter,
    UserProfile user, {
    required Set<String> followedBrandIds,
    Map<String, int> historyByCategory = const {},
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();

    // 사용 완료·만료 → 큰 음수. 정렬 후 자연스럽게 맨 아래로 가도록.
    if (letter.redeemedAt != null) return -50;
    if (letter.isRedemptionExpired || letter.isExpired) return -100;

    double s = 0;

    // 1) 카테고리 매치 (+0~25)
    //   명시 선호 (Premium Lv11+) 가 있으면 우선, 없으면 인박스 분포로 implicit 추론.
    final tag = letter.categoryTag;
    if (tag != null) {
      final explicit = user.preferredCategoryKey;
      if (explicit != null && explicit.isNotEmpty && explicit == tag) {
        s += 25;
      } else if ((explicit == null || explicit.isEmpty) &&
          historyByCategory.isNotEmpty) {
        final total = historyByCategory.values.fold<int>(0, (a, b) => a + b);
        final freq = historyByCategory[tag] ?? 0;
        if (total > 0) {
          // 30% 비중 이상이면 만점, 그 미만은 비율 만큼.
          final ratio = (freq / total).clamp(0.0, 0.3) / 0.3;
          s += 18 * ratio;
        }
      }
    }

    // 2) 만료 임박 (+0~20)
    //   24h 이내 = 만점, 7일 이내 선형 감쇠. 만료 없음 = 0.
    final exp = letter.redemptionExpiresAt ?? letter.expiresAt;
    if (exp != null) {
      final remain = exp.difference(t);
      if (remain.isNegative) {
        // 이미 만료 — 위에서 이미 -100 처리됐지만 방어.
        // no boost
      } else if (remain.inHours <= 24) {
        s += 20;
      } else if (remain.inDays <= 7) {
        s += 20 * (1 - (remain.inHours - 24) / (7 * 24 - 24));
      }
    }

    // 3) 발신자 등급 (+0~10) — Brand 가 가장 credibility 높음.
    switch (letter.senderTier) {
      case LetterSenderTier.brand:
        s += 10;
        break;
      case LetterSenderTier.premium:
        s += 5;
        break;
      case LetterSenderTier.free:
        break;
    }

    // 4) 사회 신호 (+0~15) — likeCount 와 avgRating 결합.
    //   likeCount 50 이상이면 만점, 5점 별점 = 만점.
    final likeWeight = (letter.likeCount.clamp(0, 50)) / 50.0 * 8;
    final ratingWeight = letter.ratingCount > 0
        ? (letter.avgRating / 5.0).clamp(0.0, 1.0) * 7
        : 0;
    s += likeWeight + ratingWeight;

    // 5) 거리 가까움 (+0~10) — 사용자 GPS 가 있고 letter 목적지 좌표 있으면.
    //   500m 이내 = 만점, 5km 이상 = 0. 그 사이 선형.
    final userLat = user.latitude;
    final userLng = user.longitude;
    final dest = letter.destinationLocation;
    final distM = LatLng(userLat, userLng).distanceTo(dest);
    if (distM <= 500) {
      s += 10;
    } else if (distM <= 5000) {
      s += 10 * (1 - (distM - 500) / 4500);
    }

    // 6) 미사용 letter (+0~10) — 새 컨텐츠 우선.
    if (!letter.isReadByRecipient) s += 10;

    // 7) 팔로우 브랜드 (+0~20) — 명시 선호와 같은 무게.
    if (letter.senderIsBrand && followedBrandIds.contains(letter.senderId)) {
      s += 20;
    }

    // 8) 쿠폰/교환권 (+0~10) — 즉시 행동 가능한 컨텐츠 가산.
    if (letter.category == LetterCategory.coupon ||
        letter.category == LetterCategory.voucher) {
      s += 10;
    }

    return s;
  }

  /// letters 전체를 score DESC 로 정렬한 새 리스트 반환. 동점 시 최신 sentAt 우선.
  static List<Letter> rank(
    List<Letter> letters,
    UserProfile user, {
    required Set<String> followedBrandIds,
    DateTime? now,
  }) {
    if (letters.isEmpty) return List<Letter>.from(letters);

    // 카테고리 빈도 분포 (이미 인박스에 있는 letter 들의 categoryTag 분포로 implicit
    // 선호 추론). 사용자가 명시 선호를 설정하지 않은 경우의 fallback.
    final history = <String, int>{};
    for (final l in letters) {
      final tag = l.categoryTag;
      if (tag != null && tag.isNotEmpty) {
        history[tag] = (history[tag] ?? 0) + 1;
      }
    }

    final scored = letters
        .map((l) => (
              letter: l,
              score: score(
                l,
                user,
                followedBrandIds: followedBrandIds,
                historyByCategory: history,
                now: now,
              ),
            ))
        .toList();

    scored.sort((a, b) {
      final c = b.score.compareTo(a.score);
      if (c != 0) return c;
      final ta = a.letter.arrivedAt ?? a.letter.sentAt;
      final tb = b.letter.arrivedAt ?? b.letter.sentAt;
      return tb.compareTo(ta);
    });

    return scored.map((e) => e.letter).toList();
  }
}
