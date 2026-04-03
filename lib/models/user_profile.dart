class ActivityScore {
  int receivedCount;
  int replyCount;
  int sentCount;
  int likeCount; // 받은 좋아요 수
  int ratingTotal; // 별점 합계
  int ratingCount; // 별점 받은 횟수

  ActivityScore({
    this.receivedCount = 0,
    this.replyCount = 0,
    this.sentCount = 0,
    this.likeCount = 0,
    this.ratingTotal = 0,
    this.ratingCount = 0,
  });

  double get avgRating => ratingCount > 0 ? ratingTotal / ratingCount : 0.0;

  // 랭킹 점수: 받은편지 + 좋아요 + 답장 + 별점
  double get towerHeight =>
      (receivedCount * 1.2) +
      (likeCount * 2.0) +
      (replyCount * 1.5) +
      (sentCount * 0.8) +
      (avgRating * 3.0);

  // 랭킹 스코어 (타워 높이와 동일하게 사용)
  double get rankScore => towerHeight;

  int get towerFloors => (towerHeight / 5).floor().clamp(1, 99);

  Map<String, dynamic> toJson() => {
    'receivedCount': receivedCount,
    'replyCount': replyCount,
    'sentCount': sentCount,
    'likeCount': likeCount,
    'ratingTotal': ratingTotal,
    'ratingCount': ratingCount,
  };

  static ActivityScore fromJson(Map<String, dynamic> j) => ActivityScore(
    receivedCount: j['receivedCount'] as int? ?? 0,
    replyCount: j['replyCount'] as int? ?? 0,
    sentCount: j['sentCount'] as int? ?? 0,
    likeCount: j['likeCount'] as int? ?? 0,
    ratingTotal: j['ratingTotal'] as int? ?? 0,
    ratingCount: j['ratingCount'] as int? ?? 0,
  );

  TowerTier get tier {
    final h = towerHeight;
    if (h < 6) return TowerTier.shack;
    if (h < 15) return TowerTier.cottage;
    if (h < 30) return TowerTier.house;
    if (h < 50) return TowerTier.townhouse;
    if (h < 80) return TowerTier.building;
    if (h < 120) return TowerTier.office;
    if (h < 170) return TowerTier.skyscraper;
    if (h < 250) return TowerTier.supertall;
    if (h < 330) return TowerTier.megatower;
    return TowerTier.landmark;
  }

  double get tierMin {
    switch (tier) {
      case TowerTier.shack:
        return 0;
      case TowerTier.cottage:
        return 6;
      case TowerTier.house:
        return 15;
      case TowerTier.townhouse:
        return 30;
      case TowerTier.building:
        return 50;
      case TowerTier.office:
        return 80;
      case TowerTier.skyscraper:
        return 120;
      case TowerTier.supertall:
        return 170;
      case TowerTier.megatower:
        return 250;
      case TowerTier.landmark:
        return 330;
    }
  }

  double get tierMax {
    switch (tier) {
      case TowerTier.shack:
        return 6;
      case TowerTier.cottage:
        return 15;
      case TowerTier.house:
        return 30;
      case TowerTier.townhouse:
        return 50;
      case TowerTier.building:
        return 80;
      case TowerTier.office:
        return 120;
      case TowerTier.skyscraper:
        return 170;
      case TowerTier.supertall:
        return 250;
      case TowerTier.megatower:
        return 330;
      case TowerTier.landmark:
        return 500;
    }
  }

  double get tierProgress =>
      ((towerHeight - tierMin) / (tierMax - tierMin)).clamp(0.0, 1.0);

  // 명성 칭호 (Stitch AI 추천 — 활동 점수 기반 시적 호칭)
  String get reputationTitle {
    final h = towerHeight;
    if (h < 6) return '새내기 편지꾼';
    if (h < 15) return '이야기 수집가';
    if (h < 30) return '바람의 심부름꾼';
    if (h < 50) return '항구의 전령사';
    if (h < 80) return '바다의 기록자';
    if (h < 120) return '파도를 가르는 자';
    if (h < 170) return '천 개의 편지 주인';
    if (h < 250) return '영원한 항해사';
    if (h < 330) return '세계를 연결하는 자';
    return '전설의 필경원';
  }
}

enum TowerTier {
  shack,
  cottage,
  house,
  townhouse,
  building,
  office,
  skyscraper,
  supertall,
  megatower,
  landmark,
}

extension TowerTierExt on TowerTier {
  int get tierNumber => TowerTier.values.indexOf(this) + 1;

  String get label {
    switch (this) {
      case TowerTier.shack:
        return '오두막';
      case TowerTier.cottage:
        return '농가주택';
      case TowerTier.house:
        return '마을집';
      case TowerTier.townhouse:
        return '타운하우스';
      case TowerTier.building:
        return '빌딩';
      case TowerTier.office:
        return '오피스타워';
      case TowerTier.skyscraper:
        return '마천루';
      case TowerTier.supertall:
        return '초고층빌딩';
      case TowerTier.megatower:
        return '메가타워';
      case TowerTier.landmark:
        return '랜드마크';
    }
  }

  String get emoji {
    switch (this) {
      case TowerTier.shack:
        return '🛖';
      case TowerTier.cottage:
        return '🏠';
      case TowerTier.house:
        return '🏡';
      case TowerTier.townhouse:
        return '🏘️';
      case TowerTier.building:
        return '🏢';
      case TowerTier.office:
        return '🏣';
      case TowerTier.skyscraper:
        return '🏙️';
      case TowerTier.supertall:
        return '🌆';
      case TowerTier.megatower:
        return '🌇';
      case TowerTier.landmark:
        return '🗼';
    }
  }

  String get nextGoal {
    switch (this) {
      case TowerTier.shack:
        return '편지 3개 받으면 농가주택으로!';
      case TowerTier.cottage:
        return '활동 점수 15점이면 마을집으로!';
      case TowerTier.house:
        return '답장 5개 보내면 타운하우스로!';
      case TowerTier.townhouse:
        return '활동 점수 50점이면 빌딩으로!';
      case TowerTier.building:
        return '활동 점수 80점이면 오피스타워로!';
      case TowerTier.office:
        return '활동 점수 120점이면 마천루로!';
      case TowerTier.skyscraper:
        return '활동 점수 170점이면 초고층빌딩으로!';
      case TowerTier.supertall:
        return '활동 점수 250점이면 메가타워로!';
      case TowerTier.megatower:
        return '활동 점수 330점이면 랜드마크로!';
      case TowerTier.landmark:
        return '최고 등급 달성! 🎉';
    }
  }

  // 타워 시적 이름 (Stitch AI 추천)
  String get towerName {
    switch (this) {
      case TowerTier.shack:
        return '작은 편지 오두막';
      case TowerTier.cottage:
        return '들판의 이야기집';
      case TowerTier.house:
        return '마을 편지터';
      case TowerTier.townhouse:
        return '골목 서재';
      case TowerTier.building:
        return '도시 메신저탑';
      case TowerTier.office:
        return '구름 편지국';
      case TowerTier.skyscraper:
        return '하늘 기록탑';
      case TowerTier.supertall:
        return '천공의 탑';
      case TowerTier.megatower:
        return '세계의 정점';
      case TowerTier.landmark:
        return '전설의 필경원';
    }
  }
}

class UserProfile {
  final String id;
  String username;
  String? profileImagePath;
  String country;
  String countryFlag;
  bool isPremium;
  String? email;
  String? socialLink;
  String languageCode; // e.g. 'ko', 'en', 'ja'
  final ActivityScore activityScore;
  final DateTime joinedAt;
  double latitude;
  double longitude;
  List<String> followingIds; // IDs of users I follow
  List<String> followerIds; // IDs of users who follow me
  bool isUsernamePublic; // 닉네임 공개 여부
  bool isSnsPublic; // SNS 링크 공개 여부
  // ── 프리미엄/유료 전용 필드 ──────────────────────────────────────────────
  bool isBrand; // 브랜드/크리에이터 인증 계정
  String? brandName; // 브랜드 표시명
  String towerColor; // 타워 글로우 색상 (hex, 기본 금색)
  String? towerAccentEmoji; // 타워 장식 이모지
  String? customTowerName; // 사용자 지정 타워 이름

  UserProfile({
    required this.id,
    required this.username,
    this.profileImagePath,
    required this.country,
    required this.countryFlag,
    this.isPremium = false,
    this.email,
    this.socialLink,
    this.languageCode = 'ko',
    ActivityScore? activityScore,
    DateTime? joinedAt,
    this.latitude = 37.5665,
    this.longitude = 126.9780,
    List<String>? followingIds,
    List<String>? followerIds,
    this.isUsernamePublic = true,
    this.isSnsPublic = true,
    this.isBrand = false,
    this.brandName,
    this.towerColor = '#FFD700',
    this.towerAccentEmoji,
    this.customTowerName,
  }) : activityScore = activityScore ?? ActivityScore(),
       joinedAt = joinedAt ?? DateTime.now(),
       followingIds = followingIds ?? [],
       followerIds = followerIds ?? [];
}
