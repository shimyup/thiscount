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
/// - 사용자 행동 (followed brand / preferredCategoryKey / **읽거나 사용한** letter 의
///   categoryTag 분포) 에서 선호를 추출 → 같은 카테고리·만료 임박·미사용·근거리·
///   신뢰도 높은 letter 를 상위로 끌어올린다.
/// - **사용된 쿠폰 / 만료된 쿠폰** 은 큰 음수 가중치로 하단으로 밀어낸다.
class RecommendationService {
  RecommendationService._();

  /// 가산점 합계의 상한 (변경 시 패널티 상수와의 균형 재확인).
  static const double _maxBoost = 120;

  /// 사용 완료 패널티 — 가산점 만점보다 절댓값이 크게 (정렬 시 dominance 보장).
  static const double _redeemedPenalty = -1000;

  /// 만료 패널티 — 사용 완료보다 더 아래로 (만료 < 사용 완료).
  static const double _expiredPenalty = -2000;

  /// 한 letter 의 추천 score 산출. 큰 값일수록 상위 노출.
  /// [historyByCategory] 는 사용자가 **읽거나 사용한** letter 의 categoryTag → 빈도.
  /// preferredCategoryKey 가 비어 있을 때 implicit 선호를 추정하는 데 쓰임.
  /// **인박스의 모든 letter 분포가 아니라 사용자가 실제로 소비한 letter 만** 카운트해서
  /// self-reinforcing 편향을 막는다 ([rank] 가 이 분포를 계산해 넘긴다).
  static double score(
    Letter letter,
    UserProfile user, {
    required Set<String> followedBrandIds,
    Map<String, int> historyByCategory = const {},
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();

    // Build 324 fix: letter.isExpired/isRedemptionExpired 는 자체 DateTime.now() 를
    //   호출해 score 의 t 와 drift 가능. 여기서는 직접 t 와 비교 — 단일 호출 내
    //   일관성 보장 + unit test 가 now 주입할 수 있도록.
    final couponExp = letter.redemptionExpiresAt;
    final autoExp = letter.expiresAt;
    final isAnyExpired =
        (couponExp != null && !t.isBefore(couponExp)) ||
        (autoExp != null && !t.isBefore(autoExp));

    // 사용 완료·만료 → 강한 음수. 정렬 후 자연스럽게 맨 아래로.
    if (isAnyExpired) return _expiredPenalty;
    if (letter.redeemedAt != null) return _redeemedPenalty;

    double s = 0;

    // 1) 카테고리 매치 (+0~25)
    //   명시 선호 (Premium Lv11+) 가 있으면 우선, 없으면 소비 이력 분포로 implicit 추론.
    final tag = letter.categoryTag;
    if (tag != null) {
      final explicit = user.preferredCategoryKey;
      if (explicit != null && explicit.isNotEmpty && explicit == tag) {
        s += 25;
      } else if ((explicit == null || explicit.isEmpty) &&
          historyByCategory.isNotEmpty) {
        final total = historyByCategory.values.fold<int>(0, (a, b) => a + b);
        final freq = historyByCategory[tag] ?? 0;
        // Build 324 fix: 신호의 자기강화를 막기 위해 threshold 를 0.4 로 상향
        //   (이전 0.3). 40% 비중 이상이어야 만점.
        if (total > 0) {
          final ratio = (freq / total).clamp(0.0, 0.4) / 0.4;
          s += 18 * ratio;
        }
      }
    }

    // 2) 만료 임박 (+0~20)
    //   두 만료 필드 (redemptionExpiresAt = 쿠폰 사용 기한 / expiresAt = 편지 자동 삭제)
    //   중 **더 빠른 시각** 을 기준으로 잡아 가산점/패널티 기준 일치 보장.
    //   24h 이내 = 만점, 7일 이내 선형 감쇠. 만료 필드 없음 = 0.
    DateTime? earliest;
    if (couponExp != null && autoExp != null) {
      earliest = couponExp.isBefore(autoExp) ? couponExp : autoExp;
    } else {
      earliest = couponExp ?? autoExp;
    }
    if (earliest != null) {
      final remainMin = earliest.difference(t).inMinutes;
      if (remainMin <= 0) {
        // 위에서 이미 처리됐어야 함 — 방어.
      } else if (remainMin <= 1440) {
        // 24h 이내
        s += 20;
      } else if (remainMin <= 10080) {
        // 7d 이내 — 1440 → 10080 구간 선형 감쇠
        s += 20 * (1 - (remainMin - 1440) / (10080 - 1440));
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
        : 0.0;
    s += likeWeight + ratingWeight;

    // 5) 거리 가까움 (+0~10)
    //   Build 324 fix: 사용자 GPS 가 (0, 0) 인 경우 (위치 권한 거부 또는 미설정)
    //   거리 신호 자체를 건너뛴다 — 0,0 destination letter (시드/테스트 데이터)
    //   에 부정 가산점을 주지 않기 위함.
    if (user.latitude != 0 || user.longitude != 0) {
      final distM = LatLng(user.latitude, user.longitude)
          .distanceTo(letter.destinationLocation);
      if (distM <= 500) {
        s += 10;
      } else if (distM <= 5000) {
        s += 10 * (1 - (distM - 500) / 4500);
      }
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

    // 최대 가산점 _maxBoost 를 넘지 않도록 clamp (방어).
    return s > _maxBoost ? _maxBoost : s;
  }

  /// Build 324: AI 추천 모드에서 letter 카드에 노출할 "추천 이유" 1줄 산출.
  ///   가장 강한 single signal 을 emoji + 라벨 키로 반환 (null = 이유 없음).
  ///   호출 측에서 i18n 으로 라벨 매핑 (`aiReason*` 키).
  ///
  /// 우선순위:
  ///   1) 팔로우 브랜드  → ('🏷', 'aiReasonFollowed')
  ///   2) 만료 임박 24h  → ('⏰', 'aiReasonExpiring')
  ///   3) 선호 카테고리 매치 → ('🎯', 'aiReasonCategoryMatch')
  ///   4) 사회 신호 강함 (likeCount ≥ 30 또는 avgRating ≥ 4.5)
  ///                    → ('⭐', 'aiReasonPopular')
  ///   5) 근거리 (≤500m) → ('📍', 'aiReasonNearby')
  static ({String emoji, String labelKey})? topReason(
    Letter letter,
    UserProfile user, {
    required Set<String> followedBrandIds,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();

    // 만료된 letter 는 이유 표시 안 함.
    final couponExp = letter.redemptionExpiresAt;
    final autoExp = letter.expiresAt;
    final isAnyExpired =
        (couponExp != null && !t.isBefore(couponExp)) ||
        (autoExp != null && !t.isBefore(autoExp));
    if (isAnyExpired || letter.redeemedAt != null) return null;

    // 1) 팔로우 브랜드
    if (letter.senderIsBrand &&
        followedBrandIds.contains(letter.senderId)) {
      return (emoji: '🏷', labelKey: 'aiReasonFollowed');
    }

    // 2) 만료 임박 24h (둘 중 더 빠른 시각 기준)
    DateTime? earliest;
    if (couponExp != null && autoExp != null) {
      earliest = couponExp.isBefore(autoExp) ? couponExp : autoExp;
    } else {
      earliest = couponExp ?? autoExp;
    }
    if (earliest != null) {
      final remainMin = earliest.difference(t).inMinutes;
      if (remainMin > 0 && remainMin <= 1440) {
        return (emoji: '⏰', labelKey: 'aiReasonExpiring');
      }
    }

    // 3) 선호 카테고리 매치
    final tag = letter.categoryTag;
    final pref = user.preferredCategoryKey;
    if (tag != null && pref != null && pref.isNotEmpty && tag == pref) {
      return (emoji: '🎯', labelKey: 'aiReasonCategoryMatch');
    }

    // 4) 사회 신호 강함
    if (letter.likeCount >= 30 ||
        (letter.ratingCount > 0 && letter.avgRating >= 4.5)) {
      return (emoji: '⭐', labelKey: 'aiReasonPopular');
    }

    // 5) 근거리 — user GPS 유효한 경우만
    if (user.latitude != 0 || user.longitude != 0) {
      final distM = LatLng(user.latitude, user.longitude)
          .distanceTo(letter.destinationLocation);
      if (distM <= 500) {
        return (emoji: '📍', labelKey: 'aiReasonNearby');
      }
    }

    return null;
  }

  /// letters 전체를 score DESC 로 정렬한 새 리스트 반환. 동점 시 최신 sentAt 우선.
  static List<Letter> rank(
    List<Letter> letters,
    UserProfile user, {
    required Set<String> followedBrandIds,
    DateTime? now,
  }) {
    if (letters.isEmpty) return List<Letter>.from(letters);

    // Build 324 fix: implicit 카테고리 선호는 **사용자가 실제로 소비한** letter
    //   (읽거나 사용 완료) 의 분포에서만 추출. 인박스의 모든 letter 분포로 잡으면
    //   많이 받은 카테고리가 더 위로 가는 self-reinforcing loop 가 생긴다.
    final history = <String, int>{};
    for (final l in letters) {
      final consumed = l.isReadByRecipient || l.redeemedAt != null;
      if (!consumed) continue;
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
