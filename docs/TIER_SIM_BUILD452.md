# 3-티어 시뮬레이션 (Build 452) — 확정 40건

P0 0 / P1 3 / P2 18 / P3 19 · byTier {'Premium': 12, 'Brand': 14, 'All': 5, 'Cross': 6, 'Free': 3}

## P0

## P1

### [Premium] 인박스 TabController length 고정 vs. DM 탭 조건부 → 실시간 티어 변경 시 크래시
- lib/features/inbox/screens/inbox_screen.dart:619, 1129, 1552-1561
- 수정: canUseDM 변화에 맞춰 TabController 를 재생성하거나 length 를 재동기화해야 함. 권장: lib/features/inbox/screens/inbox_screen.dart 의 _InboxScreenState 에 didChangeDependencies 추가하여 현재 canUseDM 으로 필요한 length(비-Brand 기준 canDM?3:2, Brand 는 2)를 계산하고 _tabController.length 와 다르면 기존 컨트롤러 dispose 후 새 length 로 재생성(가능하면 현재 index clamp 유지).

예:
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final state = context.read<AppState>();
  final isBrand = state.currentUser.isBrand;
  final wantLength = isBrand ? 2 : (state.canUseDM ? 3 : 2);
  if (_tabController.length != wantLength) {
    final prevIndex = _tabController.index.clamp(0, wantLength - 1);
    _tabController.dispose();
    _tabController = TabController(length: wantLength, vsync: this, initialIndex: prevIndex);
  }
}
```
(_tabController 가 late non-final 이므로 재할당 가능.) 또는 가장 단순/견고한 대안: 전체 탭 영역을 `DefaultTabController(length: wantLength, ...)` 로 감싸고 TabBar/TabBarView 에서 명시 controller 제거 — DefaultTabController 는 length 변경 시 내부적으로 컨트롤러를 재생성하므로 수동 length 동기화 부담이 사라짐. 어느 쪽이든 build 의 tabs/children 분기(1129, 1560)와 length 가 항상 일치하도록 단일 source(wantLength)에서 파생시킬 것.

### [Brand] 비-특급 대량발송 precise(ExactDrop) 타깃이 ExactDrop 크레딧을 차감하지 않음 — 유료 정밀발송 무료 우회
- lib/state/app_state.dart:8984-9018 (precise 차감 누락) / lib/state/app_state.dart:9316-9319 (express 경로는 차감) / lib/features/compose/screens/compose_screen.dart:1940-1956 (단건 경로는 차감) / lib/features/compose/screens/compose_screen.dart:6435-6441 (precise 타깃 생성) / lib/features/compose/screens/compose_screen.dart:1846-1871 (비-특급 bulk 디스패치)
- 수정: lib/state/app_state.dart 의 sendBulkLetter precise 분기 루프(8991-9017)에 통당 ExactDrop 크레딧 차감을 추가. sendBrandExpressBlast(9316-9319)와 동일 패턴 적용:

```dart
for (int i = 0; i < sendCount; i++) {
  if (!_canSendLetterByDailyLimit()) break;
  if (imageUrl != null && !_canSendImageLetter()) break;
  // ADD: precise(ExactDrop) 타깃은 통당 1크레딧 차감 — 단건/특급 경로와 동일 정책
  if (isPrecise) {
    final ok = await consumeExactDropCredit();
    if (!ok) break;
  }
  final ok = await sendLetter( ... useExactCoordinates: isPrecise, ... );
  if (ok) sent++;
}
```

추가로 8991의 imageUrl/dailyLimit break 와 마찬가지로 크레딧 부족 시 break 하면 부분발송 처리 로직(compose_screen.dart:1903 `totalSent < expected` 경고)이 이미 ExactDrop 부족 안내를 커버함(line 1906-1908 "한도 부족" 메시지). 정밀도를 위해 해당 스낵바 카피를 express 경로(1810-1811)처럼 "ExactDrop 크레딧/한도 부족" 으로 통일 권장.

### [All] letters.status IDOR — 임의 인증자가 타인 letter 를 deletedBySender/deletedByAdmin 로 PATCH 해 전 사용자에게서 소멸 가능
- firestore.rules:76,245-248 / lib/state/app_state.dart:3854,4547,4720,5035
- 수정: 근본: Auth Phase 3 owner-check cutover (firestore.rules.phase2 / authUid 바인딩) — letters update 를 발신자 owner-scope 로 제한. 단, pickup(타인 readCount++) 때문에 카운터/도착상태 필드는 공개 유지 필요하므로 status 만 별도 처리해야 함.

즉시 부분완화(cutover 전, 코드 가능): firestore.rules 의 isLetterTamperSafe() 에 status 전이 제약 추가. 예:

function isStatusTransitionSafe() {
  // deletedBy* 는 클라이언트 PATCH 금지(admin REST/Cloud Function 전용).
  return !(request.resource.data.status in ['deletedBySender','deletedByAdmin'])
      // 기존이 deletedBy* 면 변경 불가(write-once 소멸).
      && !(resource.data.status in ['deletedBySender','deletedByAdmin']
           && request.resource.data.status != resource.data.status);
}

그리고 firestore.rules:248 의 update 조건에 `&& isStatusTransitionSafe()` 추가(line 246-248 옆). 이렇게 하면 정상 픽업 흐름(delivered→read 계열 status 전이)은 유지하되, 임의 인증자의 deletedBy* PATCH(검열)는 차단된다. 정상 scrub/admin 삭제는 deleteMyData/admin Cloud Function(Admin SDK, rules 우회)로 이전해야 함.

영향 파일: /Users/shimyup/Documents/New project/Lettergo/firestore.rules (line 115-118 isLetterTamperSafe 확장 또는 신규 함수 + line 245-248 update 조건 추가). 클라이언트 admin 삭제 경로(app_state.dart line 5035 부근)가 직접 status PATCH 한다면 Cloud Function 경유로 재배선 필요. ⚠️ firebase deploy --only firestore:rules 배포 필수(미배포 시 무효).

## P2

### [Premium] _initFromPrefs 무결성 가드가 billingDate 로드 전에 검사 → RC 폴백 시 정식 결제 Premium 박탈
- lib/core/services/purchase_service.dart:782-795
- 수정: lib/core/services/purchase_service.dart 의 `_initFromPrefs` 에서 billingDate 로드(현재 L792-795)를 무결성 가드(현재 L782-790)보다 앞으로 이동. 구체:

L780 `await _evaluateGiftExpiryFromPrefs(prefs);` 직후, 가드 이전에
```dart
_nextBillingDate = _loadDateFromPrefs(prefs, PrefKeys.purchaseNextBillingDate);
```
를 먼저 실행하고, 기존 L792-795 의 중복 대입은 제거. 이렇게 하면 가드 L783 의 `_nextBillingDate == null` 검사가 prefs 에 저장된 정식 구독자의 billingDate 를 반영해 false 가 되어, 결제 사용자는 가드에 걸리지 않음. 동시에 L787 의 잘못된 주석도 실제 동작과 일치하게 됨. 가드의 의도(billing/gift 둘 다 없는 무결성 위반만 차단)는 그대로 유지된다.

### [Premium] 답장 발송 시 첨부 이미지가 조용히 누락됨 (replyToLetter 이 imageUrl 미전달)
- lib/state/app_state.dart:9979-9985 + lib/features/compose/screens/compose_screen.dart:1961-1965, 2464-2489
- 수정: lib/state/app_state.dart 의 replyToLetter 시그니처에 `String? imageUrl` 를 추가하고 sendLetter 호출에 `imageUrl: imageUrl` 를 전달한다(9966-9985). 그러면 sendLetter 내부의 _canSendImageLetter 게이트와 _consumeImageQuota 가 자동으로 적용된다. 호출부 compose_screen.dart:1961-1965 의 replyToLetter 호출에 `imageUrl: _imageFilePath` 를 추가한다. 더불어 compose_screen.dart:2472 첨부 버튼 노출 조건을 검토 — 의도가 'Brand 답장만 첨부 허용'이라면 현 동작이 맞지만, Premium 답장도 이미지를 허용할 의도였다면 `!(hasPremium && !isBrand)` 조건을 답장 케이스에서 완화해야 한다. 두 위치를 함께 고쳐야 첨부 가능성과 발송 전달이 일관된다.

### [Premium] Premium 답장에서 이미지 첨부 버튼이 숨겨짐 (Premium 의 광고 포지셔닝과 모순)
- lib/features/compose/screens/compose_screen.dart:2472-2489
- 수정: compose_screen.dart:2472 게이트 수정. `!(hasPremium && !isBrand)` 는 compose(비-답장) 모드에서 Premium 인라인 버튼을 억제하려는 의도(홍보 배지 카드가 대신 처리)인데, 답장 모드엔 그 카드가 없음. 답장일 땐 Premium 도 인라인 버튼을 노출하도록 변경:

기존:
  if (!(hasPremium && !isBrand) &&
      (_isReply || _brandCategory == LetterCategory.general)) ...[

수정:
  if ((_isReply || !(hasPremium && !isBrand)) &&
      (_isReply || _brandCategory == LetterCategory.general)) ...[

또는 더 명확히, 첨부 버튼 표시 조건을 별도 bool 로:
  final showInlineAttach = (_isReply || _brandCategory == LetterCategory.general)
      && (_isReply || isBrand || !(hasPremium));
처럼 "답장이면 Premium 포함 항상 노출, 비-답장 Premium 은 홍보카드가 처리하므로 숨김" 의도를 명시. 핵심은 `_isReply == true` 케이스에서 순수 Premium 도 _buildImageAttachButton 이 렌더되도록 하는 것. _buildImageAttachButton 은 이미 hasPremium 파라미터로 한도/업셀을 처리하므로 추가 변경 불필요.

### [Cross] Brand→하위티어 실시간 강등 시 하단탭 _currentIndex 미보정 → 네비 하이라이트 desync
- lib/widgets/main_scaffold.dart:31, 290-303, 437-444
- 수정: lib/widgets/main_scaffold.dart 의 build()(또는 별도 보정)에서 isBrand 로 표시 가능한 탭 수가 바뀔 때 _currentIndex 를 clamp 한다. isBrand 를 select 한 직후(약 207행 이후)에 보정 로직 추가: 비-Brand 일 때 최대 인덱스는 2, Brand 일 때는 3. 예) `final maxIdx = isBrand ? 3 : 2; if (_currentIndex > maxIdx) { WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _currentIndex = maxIdx); }); }` 로 강등 시 _currentIndex==3 → 2(프로필)로 맞춰 본문/네비 강조 정합. build 중 동기 setState 회피 위해 postFrame 사용. 또는 didChangeDependencies 에서 동일 clamp 수행.

### [Brand] 교환권(voucher)→할인권(coupon) 전환 시 _voucherImageLocalPath 미해제 — UI엔 이미지 첨부됐는데 발송 안 됨 (state desync)
- lib/features/compose/screens/compose_screen.dart:4955-4960, 4429, 4470-4483, 1990-1992
- 수정: lib/features/compose/screens/compose_screen.dart 의 카테고리 탭 핸들러 voucher→coupon 전환 블록(line 4955-4960)에서 _redemptionInfoController.clear() 와 함께 _voucherImageLocalPath = null; (필요시 _isUploadingVoucher = false;) 도 해제해 _imageFilePath(4964-4967)와 대칭을 맞춘다. 더 견고하게는, coupon 이 아닌 카테고리로 빠질 때 또는 redemptionInfo 가 비워질 때 항상 두 상태를 함께 정리하도록, line 4946-4950 의 c != coupon && _attachRedemptionCode 분기에도 동일 정리를 추가하거나, _redemptionInfoController.clear() 를 호출하는 모든 지점에서 _voucherImageLocalPath = null 을 짝지어 호출하는 헬퍼(_resetRedemptionState())로 묶는다.

### [Brand] 본문 글자수 헬퍼가 Brand 할인권/교환권에도 '10자 미만 경고' 고정 표시 — 버튼은 1자로 활성(게이트 불일치)
- lib/features/compose/screens/compose_screen.dart:3530-3545, 7603-7606, 1593-1626
- 수정: compose_screen.dart:3530 의 `_charCount < 10` 임계값을 버튼/검증 게이트와 동일하게 분기. 예: build 메서드 상단(또는 line 3528 위)에서 `final bool _isShortFormAllowed = _isReply || _attachRedemptionCode || (state.currentUser.isBrand && _brandCategory != LetterCategory.general); final int helperMinChars = _isShortFormAllowed ? 1 : 10;` 를 계산하고, line 3530 을 `child: _charCount < helperMinChars` 로, line 3539 의 `l10n.composeMinCharsNeeded(10 - _charCount)` 를 `l10n.composeMinCharsNeeded(helperMinChars - _charCount)` 로 교체. (단 이 빌더 스코프에서 state/currentUser 접근 가능 여부 확인 — 7603 처럼 state 가 인자로 흐르거나 위젯 필드로 접근 가능해야 함.) 이로써 버튼(7606)·검증(1626) 게이트와 일치.

### [Cross] '이번 달 사용'(redemptionsThisMonth) 집계가 general(홍보) letter 를 포함 — totalRedemptions/서버 redeemedCount 와 불일치
- lib/state/app_state.dart:2231-2236 (redemptionsThisMonth) vs 2243-2248 (totalRedemptions) vs 1990-1994/2005 (markLetterRedeemed)
- 수정: lib/state/app_state.dart:2231-2236 의 redemptionsThisMonth getter 에 totalRedemptions(2243-2248)와 동일한 category 필터를 추가:

  int get redemptionsThisMonth => _inbox
      .where((l) =>
          l.senderIsBrand &&
          l.category != LetterCategory.general &&   // 추가: general 정보성 제외
          l.redeemedAt != null &&
          l.redeemedAt!.isAfter(_startOfMonth))
      .length;

이로써 markLetterRedeemed 의 isRedeemable 게이트, totalRedemptions, 서버 redeemedCount 세 집계와 일관성 확보.

### [Brand] Brand 일일 한도 초과 메시지가 실제 캡(10,000+)이 아닌 죽은 상수 200통을 표시
- lib/state/app_state.dart:1599-1600
- 수정: lib/state/app_state.dart:1599-1600 의 Brand 분기를 실제 캡으로 수정. monthlyLimitExceededMessage (line 1612-1614)와 동일 패턴 사용:
  if (isBrandMember) {
    final total = _monthlyLimitBrand + _brandExtraMonthlyQuota;
    return _l10n.stateDailyLimitBrand(total);
  }
또는 dailySendLimit getter 를 직접 전달: return _l10n.stateDailyLimitBrand(dailySendLimit); (단 _isTestLimitedBrand 시 _dailyLimitPremium 가 들어가도 정확하므로 dailySendLimit 직접 전달이 더 견고). 수정 후 사용처 없어진 _dailyLimitBrand 상수(line 396) 제거 권장.

### [All] 시계 전진(clock-forward)으로 일/월 발송·이미지 quota 무제한 farming 가능 — SecureClock 은 전진을 막지 않음
- lib/state/app_state.dart:2726-2743, lib/core/services/secure_clock.dart:48-58
- 수정: 단조성을 발송 카운터 자체에 박아야 한다(전진도 막도록). 구체:

(A) lib/state/app_state.dart 롤오버 게이트를 "마지막 발송 watermark 와 비교한 단조 dateKey" 로 변경. 신규 영속 필드 `_lastSendEpochMs`(SharedPreferences) 추가 후, _rolloverDailySendCounterIfNeeded(2726)/_rolloverMonthlySendCounterIfNeeded(2736)/_rolloverDailyImageCounterIfNeeded(2799) 에서 SecureClock.now() 대신 `SecureClock.now()` 와 저장된 `_lastSendEpochMs` 의 차이가 실제 경과(예: 일 카운터는 자정 경계 + 최소 경과시간 sanity, 또는 단순히 dateKey 가 저장 키보다 '단조 증가'할 때만 리셋하고 동일/과거면 유지)를 검증. 즉 현재 키 < 저장 키(전진 후 복귀)면 리셋 금지, 비현실적 점프(예: 하루에 +N일)면 carry-over.

(B) 더 견고: SecureClock 에 forward-jump rate 가드 추가 — touch() 시 직전 watermark 대비 과도한 점프(예: > 25h/clock-skew 허용치) 를 별도 'suspicious advance' 로 기록하고, 발송 quota 롤오버는 이 의심 advance 를 신뢰하지 않게 함.

(C) 근본책(권장): _saveCreditCountersToFirestore (lib/state/app_state.dart:6179-6183) mask 에 dailySentCount/monthlySentCount/dailyImageSentCount + 해당 dateKey/monthKey 를 추가하고, 발송 허용 판정을 서버 권위 카운터로 reconcile(또는 Cloud Function sendLetter 경유 서버 enforce). 단 이는 정식 Auth 마이그레이션(BLOCKER②) 선결 필요. 출시 전 즉효는 (A) 의 단조-키 가드.

부수: 2727-2728/2800-2801 의 "시계 전진 우회 차단" 주석은 현재 거짓 — 수정 전까지 "되돌리기만 차단(전진 미차단)" 으로 정정.

### [Premium] 초대 크레딧만 남고 base quota 소진 시 DM 발송이 base 카운터를 한도 초과로 증가시키고 크레딧을 소비하지 않음
- lib/state/app_state.dart:10081-10095
- 수정: sendDM 의 차감 분기(lib/state/app_state.dart:10087-10091)를 _consumeDailyQuota() 호출로 교체해 sendLetter 와 동일하게 base quota 우선, 부족 시 _inviteRewardCredits 차감하도록 통일. 예: line 10087-10091 의 `_pendingDMCount = 0; _dailySentCount++; _monthlySentCount++; _sentSinceLastUnlock++; _saveToPrefs();` 를 `_pendingDMCount = 0; _consumeDailyQuota(); _sentSinceLastUnlock++; _saveToPrefs();` 로 변경. _consumeDailyQuota 가 hasBaseQuota 검사 후 카운터 증가 또는 크레딧 차감(+서버 영속화)을 처리하므로 한도 초과 증가가 방지되고 크레딧이 정상 소비된다.

### [Cross] 결제 오류 메시지 전체가 한글 하드코딩 — Premium/Brand 비한국어 사용자에게 한국어 노출
- lib/core/services/purchase_service.dart:1098,1120,1158,1172,1208
- 수정: PurchaseService 메서드들은 이미 AppState 를 인자로 받으므로(buyBrandExtra(AppState appState), buyExactDrop(AppState appState, …)) AppState 에 현지화 getter 를 추가해 위임하면 됨 — 기존 brandExtraServerVerificationUnavailableMessage(lib/state/app_state.dart:1473) 패턴 그대로.

1) lib/state/app_state.dart 에 getter 추가:
  String get purchaseConfigMissingMessage => _l10n.statePurchaseConfigMissing;
  String get purchaseServiceConnectMessage => _l10n.statePurchaseServiceConnect;
  String get purchaseVerifyErrorMessage => _l10n.statePurchaseVerifyError;
  String get purchaseVerifyIncompleteMessage => _l10n.statePurchaseVerifyIncomplete;
  (구독/베타 차단/계정 제한 문구도 동일하게 추가)
2) AppL10n 14언어에 대응 키 추가.
3) purchase_service.dart 의 인라인 한글을 교체:
  1098/1208 → _setError(appState.purchaseConfigMissingMessage)
  1120/1225/962/1030/1284 → _setError(appState.purchaseServiceConnectMessage)
  1158 → _setError(appState.purchaseVerifyErrorMessage)
  1172 → _setError(appState.purchaseVerifyIncompleteMessage)
  나머지 구독 경로(580/939/1002/1009/1252) 및 1088/1196 계정 제한 문구도 동일 처리.
appState 미접근 메서드(예: gift card 1077, _setProductResolveError)는 호출 site(premium_screen)에서 errorMessage 키 매핑 또는 별도 AppState 주입으로 처리.

### [Cross] 계정 전환(isNewUser) 시 _appliedInviteCode/_lastInviteRewardAt in-memory 미리셋 → A의 초대코드가 B의 Firestore 프로필에 기록 + B의 초대코드 적용 차단
- lib/state/app_state.dart:5075-5167 (isNewUser 블록), 6077-6082 (_saveUserToFirestore write), 1494 (hasAppliedInviteCode 가드), 1306-1307 (필드 선언)
- 수정: lib/state/app_state.dart 의 isNewUser 리셋 블록(5113 _inviteRewardCredits 인접)에 두 줄 추가: `_appliedInviteCode = null;` `_lastInviteRewardAt = null;`. 이렇게 하면 setUser→_saveUserToFirestore(5220) 시 6077-6082 의 conditional PATCH 가 둘 다 null 이라 B doc 에 A 값을 쓰지 않고, hasAppliedInviteCode(1380)도 false 가 되어 B 의 정당한 applyInviteCode(1494) 차단이 풀린다. 추가 견고화: restoreFromServerIfMissing 6293 의 if 가드를 else 로 보강해 rewardAtRaw 부재 시 `_lastInviteRewardAt = null` self-heal 도 추가(_appliedInviteCode 6285-6291 패턴과 정합). 권장은 reset 블록 2줄이 근본 수정(restore 전 transient 누수까지 차단).

### [Brand] redemptionInfo(쿠폰 사용 방법/혜택 안내)가 단건·특송·대량 발송에서 PII 검사 누락 — zone 만 검사
- lib/features/compose/screens/compose_screen.dart:1636 / 1990 / 1863 / 1723
- 수정: 단건·특송·대량 3경로의 가드를 zone(line 1043-1044)과 동일하게 합쳐 검사하도록 수정. compose_screen.dart line 1626 직후(network/length 통과 후) content 만 검사하는 대신 결합 텍스트로 교체: `final checkText = _redemptionInfoController.text.trim().isEmpty ? content : '$content\n${_redemptionInfoController.text.trim()}';` 를 만든 뒤 line 1630 `_hasBannedWords(content)` → `_hasBannedWords(checkText)`, line 1636 `_detectPii(content)` → `_detectPii(checkText)` 로 변경. 이렇게 하면 단건/특송/대량/zone 4경로 모두 일관되게 content+redemptionInfo 를 검사하게 됨. 가드는 기존대로 confirm 다이얼로그(soft)라 정상 혜택 안내 텍스트의 false-positive 도 사용자가 진행 가능.

### [Free] users.update 화이트리스트에 isBrand/brandName 잔존 — 클라이언트 self-promote(매장 티어 자가승급) 가능
- firestore.rules:153,211-213
- 수정: firestore.rules:153 화이트리스트에서 'isBrand','brandName' 제거가 가장 깔끔하나, 클라이언트 _doSaveUserToFirestore 가 이 필드를 항상 PATCH 에 포함하면 atomic 403 회귀(Build 414 P0-1 의 원인)가 재발함. 따라서 두 단계 권장: (1) 즉시 — isAllowedUserUpdate() 에 값-불변 가드 추가, 예: `&& (!('isBrand' in request.resource.data.diff(resource.data).affectedKeys()) || request.resource.data.isBrand == resource.data.isBrand)` 형태로 isBrand/brandName 이 변경되는 경우 거부(기존값과 동일할 때만 통과 → no-op write 는 허용하되 승급 차단). brandName 도 동일 패턴. 이러면 클라이언트가 두 필드를 PATCH 에 포함해도 값이 같으면 통과해 회귀 없음. (2) 근본 — Auth Phase 3 cutover (firestore.rules.phase2) 로 owner-check 도입 후 isBrand/brandName grant 는 RC webhook / admin REST(서버 entitlement) 전용으로 완전 이관. 검증: 시뮬레이터에서 Free 계정으로 PATCH {isBrand:true} → 403, PATCH {isBrand:false}(동일값) → 200 확인.

### [Brand] redemptionCode 가 public letters/brand_zones doc 에 평문 저장 + world-readable
- firestore.rules:230-237,356-358
- 수정: 근본 수정(Phase 2 — anon-auth 마이그레이션 선결):
1. redemptionCode 를 서브컬렉션으로 분리: letters/{id}/private/code, brand_zones/{id}/private/code. firestore.rules 에서 부모 doc read 는 if true 유지하되, private/code 는 `allow read: if isOwnerOrPicker(...)` 로 제한. 정식 Auth(request.auth.uid == doc.ownerUid) 도입 후라야 owner-scope 가능.
   - 위치: firestore.rules:226-252(letters)·354-363(brand_zones) 에 nested match /private/{d} 추가.
   - 코드 write 분리: lib/state/app_state.dart:4138 와 lib/core/services/brand_zone_service.dart:248 / admin_special_message_screen.dart:200 의 redemptionCode 를 별도 subcollection write 로 이전, lib/models/letter.dart:800·brand_zone.dart:116 toJson 에서 redemptionCode 제거.

2. 즉시 완화(anon-auth 환경에서도 가능한 차선): 서버 redemption 검증 추가 — 평문 코드 노출 자체는 막지 못해도, 코드 사용을 Cloud Function(functions/) 에서 검증(코드+letterId+picker uid 매칭, 1회 멱등 사용)하게 해 raw read 로 수집한 코드만으로는 redeem 불가하게 만든다. brand_zones.redeemedCount increment 룰(rules:342-352)은 이미 +1 cap 이 있으나, 코드 소유권 검증이 없으므로 함수측 검증 필요.

3. 보강: redemptionCode 를 평문 대신 HMAC 해시로 doc 에 저장하고 실제 코드는 owner 디바이스 secure storage + private subcollection 에만 두기. read 룰에서 해시만 노출.

Phase 2 미도달 시 최소한 docs/SIM 백로그에 'redemptionCode public read = 코드 수집 가능' 을 출시-차단 known-issue 로 명시하고, 서버 redemption 검증(위 2번)을 우선 적용 권장.

### [All] 145/197 목적지 국가명이 비-한국어 사용자에게 한국어로 노출 (번역 누락)
- lib/core/localization/country_names.dart:344-347 / assets/countries_bounds.json
- 수정: lib/core/localization/country_names.dart 의 _map 에 나머지 145개국 번역 엔트리를 추가해 197개국 전부 14언어 커버. 우선 high-traffic 목적지(카타르/홍콩/대만/네팔 등)부터. 임시 완화로는, 전체 번역 전까지 localizedName 의 폴백(line 346)을 한국어 키 대신 영어로 — 단 이는 JSON 에 별도 영어명 필드가 없어 불가하므로 근본은 _map 확장. 추가로 matchesSearch (line 358-362)도 미번역국은 한국어 키 검색만 되므로 같은 _map 확장으로 동시 해소됨. 검증: python 으로 set(json.keys) - set(_map keys) == empty 확인하는 테스트 추가 권장.

### [Premium] Premium 홍보 라벨 다국어가 폐기된 '쿠폰/보상' 용어로 오역
- lib/core/localization/app_localizations.dart:5697-5712
- 수정: In lib/core/localization/app_localizations.dart:5701-5711, unify all languages to the 'Promo Message' meaning matching ko/en (and fix ja which uses 'レター'). Suggested values: zh='📣 我的推广信息', ja='📣 マイ宣伝メッセージ', fr='📣 Mon message promo', de='📣 Meine Promo-Nachricht', es='📣 Mi mensaje promo', pt='📣 Minha mensagem promo', ru='📣 Моё промо-сообщение', tr='📣 Promo Mesajım', ar='📣 رسالتي الترويجية', it='📣 Il mio messaggio promo', hi='📣 मेरा प्रोमो संदेश', th='📣 ข้อความโปรของฉัน'. This removes the retired coupon/reward (优惠券/Kupon/récompense/Belohnung/recompensa/награда/ricompensa/รางวัล) vocabulary and aligns all 14 locales with the ko/en 'Message' semantics.

### [All] 아랍어 인박스 '메시지·홍보' 필터 라벨이 'مكافآت(보상)' 으로 오역
- lib/core/localization/app_localizations.dart:10194-10209 (ar: 'مكافآت' line 10205)
- 수정: lib/core/localization/app_localizations.dart:10205 의 inboxFilterGeneral getter 에서 ar 값을 'مكافآت' → 'رسائل'(Messages) 로 변경. ko 가 '메시지·홍보'(메시지+홍보)인 점을 반영하려면 'رسائل وعروض'(메시지·프로모션) 도 가능하나, 다른 12개 언어가 단순 'Messages' 한 단어이므로 'رسائل' 로 통일 권장. 'مكافآت'(보상)은 앱 전체에서 reward/쿠폰 개념 표준어이므로 메시지 필터에 절대 사용하면 안 됨.

## P3

### [Free] 픽업 쿨다운 pill 주석/실제 동작 불일치 (Premium·Brand '10분' 잔존)
- lib/features/map/screens/world_map_screen.dart:571-572
- 수정: In lib/features/map/screens/world_map_screen.dart lines 571-572, change the comment "Free 60분 / Premium·Brand 10분." to "Free 60분 / Premium·Brand 0분(쿨다운 없음, Build 429)." to match _nearbyPickupCooldown in lib/state/app_state.dart:307-310.

### [Premium] stateTierPremium10min — Premium 쿨다운 0이라 도달 불가한 dead branch
- lib/state/app_state.dart:9488-9491
- 수정: lib/state/app_state.dart:9488-9491 의 tier 삼항을 단순화. Premium 쿨다운이 0이라 이 블록은 Free 만 도달하므로 Premium 분기 제거: `final tier = _l10n.stateTierFree1hour;` 로 고정(혹은 변수 없이 statePickupCooldown 에 직접 전달). 향후 Premium 쿨다운이 0이 아니게 바뀔 경우를 대비하려면 _nearbyPickupCooldown 값에서 분기 메시지를 파생하도록 통일하는 편이 정합적이나, 현 시점 최소 수정은 stateTierPremium10min 분기 삭제. 사용 안 하게 되는 stateTierPremium10min i18n 키는 다른 참조 없으면 함께 정리 가능.

### [Free] _ComposeNavItem 클래스 헤더 주석이 폐기된 'Free→💎업그레이드 탭' 기술
- lib/widgets/main_scaffold.dart:456-459
- 수정: lib/widgets/main_scaffold.dart:456-459 의 헤더 주석을 현 동작 반영으로 교체. 예:\n```\n// ── 중앙 CTA 탭 — Brand(광고주) 전용 캠페인 발송 (Build 425) ──\n// Brand → 📣 캠페인 (orange) · tap → compose\n// Free·Premium 은 줍기 중심이라 이 탭을 렌더하지 않음 (_buildBottomNav if(isBrand) 가드).\n```\n선택적으로 isLocked 파라미터·line 510+ 잠금 오버레이 코드가 이제 dead 이므로 별도 정리 가능(주장 범위 밖, 후속).

### [Premium] restorePurchases 가 _isBetaUpgradeSimulator 만인 빌드에서 RC키 가드에 막혀 실패 (buyBrand/buyExactDrop 과 비대칭)
- lib/core/services/purchase_service.dart:1248-1267
- 수정: lib/core/services/purchase_service.dart 의 restorePurchases 를 매수 메서드와 대칭으로 맞춘다. (1) config 가드 L1249-1251 을 `if (!_isTestMode && !_isBetaFreePremium && !_isBetaUpgradeSimulator && !_isRcKeyConfiguredForCurrentPlatform)` 로 `!_isBetaUpgradeSimulator &&` 추가. (2) 로컬 복원 분기 L1257 의 `if (_isBetaFreePremium)` 를 `if (_isBetaFreePremium || _isBetaUpgradeSimulator)` 로 확장하거나, L1269 의 `if (_isTestMode)` 를 `if (_isTestMode || _isBetaUpgradeSimulator)` 로 묶어 시뮬레이터 모드에서도 로컬 _loadSecurePremiumState 복원 경로를 타게 한다. buyBrand/buyExactDrop 의 `_isTestMode || _isBetaUpgradeSimulator` 패턴과 동일하게 하는 것이 가장 일관적.

### [Brand] _fakePurchase 의 action 이 throw 하면 _stopLoading 미호출 → 로딩 영구 고착
- lib/core/services/purchase_service.dart:1653-1658
- 수정: lib/core/services/purchase_service.dart:1653-1658 의 `_fakePurchase` 를 try/finally 로 감싸 락 해제를 보장:

  Future<bool> _fakePurchase(Future<void> Function() action) async {
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      await action();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[purchase] _fakePurchase action failed: $e');
      _setError('구매 처리 중 문제가 발생했습니다.');
      return false;
    } finally {
      // 성공/예외 무관하게 락 해제 — _setError 도 _loading=false 로 풀지만
      // 성공 시엔 _setError 미호출이므로 finally 의 _stopLoading 이 필요.
      if (_loading) _stopLoading();
    }
  }

(_setError 가 이미 _loading=false 로 만들므로 finally 의 `if (_loading)` 가드로 중복 notify 회피.) 부수적으로 `_saveSecurePremiumState`(line 341)에 try/catch 를 추가하면 근본 원인도 완화되나, 락 고착 자체는 _fakePurchase 의 try/finally 가 결정적 수정.

### [Premium] Premium 특급(express) 토글·quota 표시 UI 가 도달 불가능한 데드 경로
- lib/features/compose/screens/compose_screen.dart:3623-3673, 7618-7625 + lib/state/app_state.dart:1384-1403, 2791-2797
- 수정: 발송=Brand 전용 재포지셔닝과 정합되게 Premium 전용 express 자취를 정리. (A) compose_screen.dart:3625-3674 `_buildExpressToggle` 의 `hasPremium && !isBrand` 분기(composePremiumExpressOn/composePremiumExpress 라벨·expressExhausted·remainingPremiumExpressCount 사용)를 제거하고, 이 메서드는 `if (!isBrand) return SizedBox.shrink()` 또는 Free 업셀(3676-)만 유지하도록 단순화. (B) compose_screen.dart:7618-7625 `expressQuotaSuffix` 의 `!isBrand && isPremium` 분기를 제거(항상 ''). (C) app_state.dart 1390-1403 `remainingPremiumExpressCount`/`canUsePremiumExpress` 의 비-Brand Premium 경로(1392, 1402)와 1384 premiumExpressDailyLimit, 1660-1667 의 `useExpressSingle` 비-Brand 가드가 더 이상 호출되지 않으면 함께 제거하거나, 향후 'Premium 답장 특급'을 의도한다면 `if (!_isReply)` 게이트를 답장 경로까지 확장해 실제 동작하도록 연결. 둘 중 제거 방향이 현 재포지셔닝과 일치. 위치기반 i18n 키(composePremiumExpress/On, composeExpressQuota)도 미사용 시 정리.

### [Cross] DM 발송이 편지 compose 의 금칙어·PII·길이·XSS 검열을 전부 우회
- lib/state/app_state.dart:10064-10154 (sendDM)
- 수정: lib/state/app_state.dart 의 sendDM(10064) 진입부, blocked 가드(10076) 직후에 content 검열을 추가: (1) 길이 cap — `final trimmed = content.length > 5000 ? content.substring(0, 5000) : content;` 후 trimmed 사용(편지 5000자와 정합). (2) 금칙어/PII 재사용을 위해 compose_screen 의 _bannedWords/_hasBannedWords/_detectPii 로직을 공용 유틸(예: lib/core/util/content_moderation.dart)로 추출해 sendDM 과 compose 양쪽에서 호출 — sendDM 에서 금칙어 매치 시 return false(또는 마스킹), PII 매치 시 호출부에 경고 전달. 단기 최소조치로는 dm_conversation_screen.dart:691 TextField 에 maxLength:5000 + 본문 길이 cap 만이라도 추가. DM 이 향후 Firestore/서버 전송으로 전환될 경우 이 검열을 BLOCKER 로 승격할 것.

### [Premium] Premium 인박스 DM 탭이 '미읽음 우선' 정렬을 하지 않음 (Brand 탭과 불일치)
- lib/features/inbox/screens/inbox_screen.dart:4506-4512 vs lib/features/brand/brand_campaign_screen.dart:256-262
- 수정: lib/features/inbox/screens/inbox_screen.dart:4506-4512 의 sort 비교를 brand_campaign_screen.dart:256-262 과 동일하게 미읽음 우선으로 맞춘다. AppState 의 ChatSession 에 unreadCount 가 존재하는지 확인 후(brand 탭이 a.unreadCount 사용하므로 존재) 다음으로 교체: `..sort((a, b) { if ((a.unreadCount > 0) != (b.unreadCount > 0)) { return a.unreadCount > 0 ? -1 : 1; } final am = state.getDMConversation(a.partnerId); final bm = state.getDMConversation(b.partnerId); final at = am.isNotEmpty ? am.last.sentAt : a.createdAt; final bt = bm.isNotEmpty ? bm.last.sentAt : b.createdAt; return bt.compareTo(at); });` — 미읽음 동률일 때는 기존(Build 421) 의 마지막 메시지 시각 정렬을 유지해 양쪽 장점(미읽음 우선 + 최근 메시지 부상)을 모두 확보.

### [Premium] sendDM 실패 시 사유와 무관하게 항상 '쿼터 부족' 안내 — banned/차단/자기자신도 동일
- lib/features/dm/dm_conversation_screen.dart:77-89, lib/state/app_state.dart:10066-10076
- 수정: sendDM 의 bool 반환을 실패 사유 enum/result 로 확장하거나, dm_conversation_screen.dart _sendMessage(77-89)에서 발송 전 차단/banned/자기자신을 선검사해 사유별 메시지를 분기. 최소 수정안: app_state.dart 에 사유 노출 헬퍼(예: dmBlockReason(partnerId) → {ok, banned, blocked, self, quota}) 추가 후, dm_conversation_screen.dart line 78-89 에서 success==false 시 해당 사유에 맞는 i18n 스트링(차단됨/계정 정지/쿼터 부족)을 선택. 차단/banned 케이스용 신규 i18n 키(예: dmBlockedPartner, dmAccountSuspended) 14언어 추가 필요.

### [Brand] Brand DM 탭이 followed(채팅 비활성) 세션까지 노출 — Premium 탭과 필터 불일치
- lib/features/brand/brand_campaign_screen.dart:256 vs lib/features/inbox/screens/inbox_screen.dart:4497-4502
- 수정: lib/features/brand/brand_campaign_screen.dart:256 의 _buildDmTab 에서 Premium _DMTab(inbox_screen.dart:4497-4502)과 동일 필터를 적용:

```dart
final sessions = state.chatSessions.values
    .where((s) =>
        s.status == ChatStatus.chatting ||
        s.status == ChatStatus.pendingAgreement)
    .toList()
  ..sort((a, b) { ... });
```

ChatStatus import 가 brand_campaign_screen.dart 에 없으면 `package:.../models/direct_message.dart` import 추가. (선택: 양 티어가 같은 공유 헬퍼/extension 으로 필터를 일원화하면 향후 재발 방지.)

### [Premium] Premium→Free 다운그레이드 시 DM 세션/메시지가 메모리·prefs 에 잔존 (재업그레이드 시 부활)
- lib/state/app_state.dart:4349-4353, 5106-5107
- 수정: 강등 경로에 DM 정리를 추가한다. app_state.dart:4351 (`_currentUser.isPremium = false;`) 직후 — Brand 도 아닐 때만(여전히 isBrand 면 canUseDM 유지되므로) 정리: `if (!_currentUser.isBrand) { _chatSessions.clear(); _dmMessages.clear(); _saveDMToPrefs(); }`. 또는 더 견고하게, _clearDMState() 헬퍼를 만들어 in-memory clear + prefs.remove('chatSessions')/remove('dmMessages') 까지 수행(빈 jsonEncode 가 아니라 키 삭제로 평문 본문 완전 제거)하고, 강등 직후 권한(canUseDM)이 false 가 되는 시점에 호출. brandEntitlementRevokedAt(4344-4347) 강등과 일관되게 두 강등 모두에서 권한 재평가 후 DM 정리하는 것이 바람직.

### [Brand] Build 451 카테고리 본문 힌트·'업종/발송 종류' 라벨이 koEn 2개 언어만 — ja/zh/es 등 Brand 사용자는 영어 노출 (i18n 회귀)
- lib/features/compose/screens/compose_screen.dart:2164-2177, 4904, 4921; lib/core/localization/app_localizations.dart:58
- 수정: 신규 Build 451 문자열을 `_t()` 14언어 키로 전환. (1) app_localizations.dart에 신규 게터 5개 추가: composeBrandBodyHintCoupon / composeBrandBodyHintVoucher / composeBrandBodyHintGeneral / composeBizCategoryLabel('업종 (도착 마커 표시)') / composeSendTypeLabel('발송 종류') — 각각 `_t({'ko':..., 'en':..., 'ja':..., 'zh':..., ...14언어})`. (2) compose_screen.dart:2164/2169/2174의 `l10n.koEn(...)`을 `l10n.composeBrandBodyHintCoupon` 등으로 교체. (3) line 4904 → `l10n.composeBizCategoryLabel`, line 4921 → `l10n.composeSendTypeLabel`로 교체. 기존 composeBrandCouponAutoCodeNote 패턴과 동일하게 14언어 채울 것.

### [Brand] app_state redemptionCode 부여가 category==coupon 미검사 — UI 의존(코드 invariant 백엔드 미강제)
- lib/state/app_state.dart:8860-8868, 9284-9285; lib/features/compose/screens/compose_screen.dart:4946-4950
- 수정: Add a backend `category == LetterCategory.coupon` guard to mirror the sibling invariants. In lib/state/app_state.dart at sendLetter line 8860, change the condition to `(_currentUser.isBrand && attachRedemptionCode && category == LetterCategory.coupon)`. In sendBrandExpressBlast at lines 9284-9285, gate the blast code similarly: `final blastRedemptionCode = (category == LetterCategory.coupon) ? (explicitRedemptionCode ?? (attachRedemptionCode ? RedemptionCode.generate() : null)) : null;` (the blast path's category parameter / categoryTag should be checked — verify the category variable name in that signature, around line 9274). This double-enforces the Build 448 invariant at the data layer so it no longer depends solely on the single compose-screen handler.

### [Brand] 드래프트 복원 시 attachRedemptionCode 를 카테고리 결합(Build 448) 재검증 없이 그대로 ON 복원 → 비-할인권 카테고리에 할인코드 부착 가능
- lib/features/compose/screens/compose_screen.dart:828-843 (draft restore) / 4946-4960 (toggle-time coupling) / lib/state/app_state.dart:8860 (sendLetter)
- 수정: compose_screen.dart 드래프트 복원 블록(836-841 직후, Brand 가드 849 와 무관하게 모든 사용자에 적용)에 카테고리/코드 정합성 재검증을 추가한다:

```dart
_attachRedemptionCode = snap['attachRedemptionCode'] as bool? ?? false;
// 정책: 할인코드는 할인권(coupon) 전용 — 레거시 드래프트의
//   category!=coupon + attachRedemptionCode=true 조합을 복원 시 정규화.
if (_brandCategory != LetterCategory.coupon) {
  _attachRedemptionCode = false;
  _previewRedemptionCode = null;
} else if (_attachRedemptionCode) {
  _previewRedemptionCode ??= RedemptionCode.generate();
}
```
이렇게 하면 toggle-time 결합(4946-4960)과 동일한 불변식이 복원 경로에서도 보장된다.

추가 방어선(이중 안전): app_state.dart:8860 의 redemptionCode 발급 조건에 category 게이트를 넣어 비-coupon 카테고리에는 코드를 발급하지 않도록 서버측(모델 생성측) 가드를 강화하는 것을 권장한다 — `(_currentUser.isBrand && attachRedemptionCode && category == LetterCategory.coupon)`. 단 voucher(교환권)에 코드 발급을 허용하는 기존 정책이 있는지 먼저 확인 필요(현 8849 redemptionExpiresAt 는 general 만 제외하고 voucher 는 허용하므로 voucher 코드 발급이 의도된 흐름일 수 있음 → 이 경우 게이트는 `category != LetterCategory.general` 로 조정).

### [Cross] 초대 보상 크레딧 grant 가 inviter 측에서 read-modify-write(setDocument) — 동시 초대 시 lost update
- lib/state/app_state.dart:1544-1567
- 수정: lib/state/app_state.dart 의 inviter 측 grant 를 atomic increment 로 교체. L1564-1567 의 `setDocument('users/$inviterId', {'inviteRewardCredits': inviterCredits, ...})` 를 기존 헬퍼로 대체:

  final updatedInviter = await FirestoreService.incrementField(
    path: 'users/$inviterId',
    field: 'inviteRewardCredits',
    by: 5,
  );

이러면 inviter read(L1544-1546, L1555-1556 의 inviterCredits 계산)도 불필요해져 제거 가능. inviteRewardAt 타임스탬프가 필요하면 별도 best-effort setDocument(updateMask)로 두거나 commit writes 배열에 update+transform 를 함께 묶으면 됨. claimer 본인(myCredits, L1554/L1558-1563)은 1:1 문서라 현행 read-modify-write 유지해도 무방하나 일관성을 위해 동일하게 incrementField('users/${_currentUser.id}', 'inviteRewardCredits', by:5) 적용 권장.

### [Brand] 카테고리별 본문 힌트(Build 451)가 koEn — 비-한국어 Brand 에게 영어만
- lib/features/compose/screens/compose_screen.dart:2159-2178
- 수정: app_localizations.dart 에 3개의 카테고리별 본문 힌트 getter를 14언어 _t 맵으로 신설(예: composeBrandBodyHintCoupon / composeBrandBodyHintVoucher / composeBrandBodyHintGeneral), 카테고리 라벨과 동일 수준으로 ja/zh/fr/de/es/pt/ru/tr/ar/it/hi/th 번역 채움. 그 후 compose_screen.dart:2162-2178 의 switch 분기에서 koEn(...) 호출을 각각 l10n.composeBrandBodyHintCoupon / Voucher / General 로 교체. 줄바꿈(\n)·예시 문구도 각 언어로 번역. 이렇게 하면 line 3597 hintText 가 14언어로 노출되어 라벨/힌트 언어 혼재 해소됨.

### [Brand] 대량발송 부분발송 경고 스낵바가 koEn — 비-한국어 Brand 에게 영어만
- lib/features/compose/screens/compose_screen.dart:1809-1812, 1905-1908
- 수정: app_localizations.dart 에 14언어 완역 메서드 2개 신설 후 koEn 호출 대체. 예: composeBulkPartialSent(int sent, int expected) → _t({'ko':'요청 $expected통 중 $sent통만 발송됐어요 (ExactDrop 크레딧/한도 부족)','en':'Only $sent of $expected sent (insufficient ExactDrop credit/quota)', ...나머지 12언어}) 및 composeBulkPartialSentQuota (한도 부족 버전, app_localizations.dart 신설). 그 후 compose_screen.dart:1809-1812 를 l10n.composeBulkPartialSent(totalSent, expected) 로, compose_screen.dart:1906-1908 을 l10n.composeBulkPartialSentQuota(totalSent, expected) 로 교체. 인자/플레이스홀더는 기존 composeBulkSent 패턴 준수.

### [Brand] compose/Brand 화면 전반 Semantics 라벨 부재 (고정 매장 위치 토글 포함)
- lib/features/compose/screens/compose_screen.dart:5663-5734 (Switch 5674) — 파일 내 Semantics 0건
- 수정: compose_screen.dart:5671-5680 의 고정 매장 위치 Switch 를 Semantics 로 래핑하여 토글 의미를 명시. 예: Switch 를 Semantics(label: l10n.zoneFixedLocationTitle, toggled: _useFixedStoreLocation, child: Switch(...)) 로 감싸거나, 더 간단히는 Row 전체를 MergeSemantics 로 묶어 제목 Text 와 Switch 를 하나의 노드로 병합. 카테고리 칩(compose_screen.dart 내 선택 칩) 및 exact_drop_picker.dart 선택 항목에도 selected 상태를 Semantics(selected:, label:) 로 부여. textScaler clamp 는 이미 lib/main.dart:404-410 에서 전역 처리되므로 추가 작업 불필요. WCAG 백로그 항목으로 일괄 처리 권장 (출시 차단 아님).

### [All] 로그아웃(비-isNewUser 경로) 시 in-memory 아웃박스 set 미정리 가능성
- lib/state/app_state.dart:5161 vs 5929/9176, 4209-4237
- 수정: lib/state/app_state.dart 의 `_clearUserScopedPrefs()`(line 9088 정의)에서 prefs 키 제거 후 in-memory 아웃박스도 함께 비워 대칭을 보장한다. 함수 끝부분(prefs.remove 루프 이후, line 9088-의 try 블록 내)에 다음 한 줄 추가:

    _pendingLetterUploadIds.clear();

이렇게 하면 setUser isNewUser 경로(line 5161)와 명시적 로그아웃 경로(line 5929 → _clearUserScopedPrefs) 모두에서 prefs('pending_letter_uploads', line 9176)와 in-memory set 이 항상 함께 비워져, guest 로그아웃 후 동일 인스턴스 재로그인(isNewUser=false) 경로의 잔존을 self-heal 의존 없이 차단한다. 단, _clearUserScopedPrefs 는 isNewUser 블록(line 5167)에서도 unawaited 로 호출되는데, 그 블록은 이미 line 5161 에서 clear 하므로 중복 clear 는 무해(idempotent).

