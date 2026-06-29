import 'dart:math' as math;

import '../../models/letter.dart';
import '../../state/app_state.dart';

/// 사용자의 "여정 (Journey)" 통계.
/// 기존 activityScore + 편지 컬렉션에서 집계.
/// 연말 회고 (Spotify Wrapped 스타일) 의 상시 이용 가능한 버전.
class JourneyStats {
  /// 총 발송 편지 수
  final int totalSent;

  /// 총 수신 편지 수
  final int totalReceived;

  /// 총 답장 수
  final int totalReplies;

  /// 편지를 받은 국가 수 (고유)
  final int countriesFrom;

  /// 편지를 보낸 국가 수 (고유)
  final int countriesTo;

  /// Build 421 (sim-fresh P2): 방문 나라 = 발신·목적국의 합집합(고유) 크기.
  ///   이전엔 countriesFrom + countriesTo 로 양쪽에 모두 나타난 나라를 중복
  ///   계산해 '방문 나라' 가 부풀려졌음.
  final int countriesTotal;

  /// 가장 먼 편지 거리 (km). 발송/수신 모두 포함.
  final int longestDistanceKm;

  /// 가장 먼 편지의 상대국 이름 (표시용). 없으면 빈 문자열.
  final String longestDistanceCountry;

  /// 최장 연속 접속 일수
  final int longestStreak;

  const JourneyStats({
    required this.totalSent,
    required this.totalReceived,
    required this.totalReplies,
    required this.countriesFrom,
    required this.countriesTo,
    required this.countriesTotal,
    required this.longestDistanceKm,
    required this.longestDistanceCountry,
    required this.longestStreak,
  });

  /// AppState 로부터 현재 상태를 스냅샷으로 집계.
  factory JourneyStats.from(AppState state) {
    final score = state.currentUser.activityScore;

    // 받은 편지 발신국 집합
    final fromSet = state.inbox
        .map((l) => l.senderCountry)
        .where((c) => c.isNotEmpty)
        .toSet();

    // 보낸 편지 목적국 집합
    final toSet = state.sent
        .map((l) => l.destinationCountry)
        .where((c) => c.isNotEmpty)
        .toSet();

    // 가장 먼 편지 계산 (발송·수신 모두)
    int maxDist = 0;
    String farthestCountry = '';
    void consider(Letter letter, String opponentCountry) {
      final d = _haversineKm(
        letter.originLocation.latitude,
        letter.originLocation.longitude,
        letter.destinationLocation.latitude,
        letter.destinationLocation.longitude,
      );
      if (d > maxDist) {
        maxDist = d;
        farthestCountry = opponentCountry;
      }
    }

    for (final l in state.sent) {
      consider(l, l.destinationCountry);
    }
    for (final l in state.inbox) {
      consider(l, l.senderCountry);
    }

    return JourneyStats(
      totalSent: score.sentCount,
      totalReceived: score.receivedCount,
      totalReplies: score.replyCount,
      countriesFrom: fromSet.length,
      countriesTo: toSet.length,
      countriesTotal: fromSet.union(toSet).length,
      longestDistanceKm: maxDist,
      longestDistanceCountry: farthestCountry,
      longestStreak: state.longestStreak,
    );
  }

  /// 모든 지표가 0 인 경우 — 신규 유저 스킵 판단용.
  bool get isEmpty =>
      totalSent == 0 &&
      totalReceived == 0 &&
      countriesFrom == 0 &&
      countriesTo == 0;

  static int _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const earthR = 6371.0;
    double toRad(double deg) => deg * math.pi / 180.0;
    final dLat = toRad(lat2 - lat1);
    final dLng = toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return (earthR * c).round();
  }
}
