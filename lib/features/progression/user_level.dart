/// 신규 사용자 온보딩을 위한 점진적 기능 해금 시스템.
///
/// 목표: 첫 3일간 복잡 기능을 숨겨 인지 부담을 낮추고,
///       사용자가 주요 액션(편지 발송, 답장 수신)을 완료할 때마다
///       새 기능을 보상처럼 공개하여 성장감 제공.
///
/// 판단 기준은 읽기 전용 속성이라 Flutter 의 조건부 렌더링과
/// 궁합이 잘 맞음. UI 레이어에서 `isFeatureUnlocked(X)` 한 줄로 게이팅.
enum UserLevel {
  /// 가입 직후 — 기본 편지 작성 + 지도 + 인박스만 노출
  newbie(0),

  /// 첫 편지 발송 후 — 타워 레벨·스탯 공개
  beginner(1),

  /// 5통 이상 발송 or 첫 답장 수신 — 오늘의 편지(자동 글귀) 해금
  casual(2),

  /// 10통 이상 발송 — 편지지·폰트 커스터마이징 해금
  regular(3),

  /// 20통 이상 발송 or 2주 연속 접속 — 주변 줍기·DM 해금
  experienced(4);

  final int rank;
  const UserLevel(this.rank);

  /// 이 레벨의 사용자에게 보여줄 환영 메시지.
  String get welcomeMessage {
    switch (this) {
      case UserLevel.newbie:
        return '첫 편지를 보내볼까요?';
      case UserLevel.beginner:
        return '🏠 나의 탑 레벨이 공개되었어요';
      case UserLevel.casual:
        return '✉️ 오늘의 편지가 해금되었어요';
      case UserLevel.regular:
        return '🎨 편지지·폰트를 마음껏 꾸밀 수 있어요';
      case UserLevel.experienced:
        return '🌍 주변 편지 줍기와 DM 이 열렸어요';
    }
  }
}

/// 레벨에 따라 노출 여부가 바뀌는 기능 목록.
/// UI 에서 `appState.isFeatureUnlocked(UnlockableFeature.X)` 로 체크.
enum UnlockableFeature {
  /// 타워 레벨·층수·성취 배지 노출 (신규 유저에겐 숨김)
  towerLevel,

  /// "오늘의 편지" 자동 글귀 채우기 (Today's Letter)
  todaysLetter,

  /// 편지지·폰트 커스터마이징 패널
  customPaper,

  /// 지도 위 2km 이내 주변 편지 줍기
  nearbyPickup,

  /// DM (Direct Message) 대화
  directMessage,

  /// 주간 챌린지 카드 노출
  weeklyChallenge,
}

/// UserLevel 과 UnlockableFeature 매핑 테이블.
///
/// 각 기능의 최소 해금 레벨을 정의. 이 표를 수정하면 전체 앱의
/// 노출 정책이 한 번에 바뀐다.
class FeatureUnlockPolicy {
  FeatureUnlockPolicy._();

  static bool isUnlocked(UnlockableFeature feature, UserLevel level) {
    final requiredRank = _requiredRank(feature);
    return level.rank >= requiredRank;
  }

  static int _requiredRank(UnlockableFeature feature) {
    switch (feature) {
      case UnlockableFeature.towerLevel:
        return UserLevel.beginner.rank;
      case UnlockableFeature.todaysLetter:
        return UserLevel.casual.rank;
      case UnlockableFeature.customPaper:
        return UserLevel.regular.rank;
      case UnlockableFeature.weeklyChallenge:
        return UserLevel.casual.rank;
      case UnlockableFeature.nearbyPickup:
        return UserLevel.experienced.rank;
      case UnlockableFeature.directMessage:
        return UserLevel.experienced.rank;
    }
  }

  /// 특정 기능이 해금되기 위해 필요한 레벨 — UI 의 "잠금" 표시용.
  static UserLevel requiredLevel(UnlockableFeature feature) {
    return UserLevel.values.firstWhere(
      (l) => l.rank == _requiredRank(feature),
      orElse: () => UserLevel.newbie,
    );
  }
}
