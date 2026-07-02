# 드롭 헌트 P1 갭 분석 — 후보 A(헌트 지도) + B(미스터리 봉투)

> 2026-07-02 · 코드 조사 기반 (file:line 은 조사 시점 기준)
> 결론: **재사용 ~85% 확인. 신규 코드는 3덩어리, 총 예상 1~1.5주.**

## 1. 이미 있음 (그대로 재사용)

| 자산 | 위치 | 비고 |
|---|---|---|
| 캠페인 식별 `campaignId` | letter.dart:444 — bulk/express 발송이 이미 동일 campaignId 공유 (app_state 9403/9740) | Build 324 |
| 발송 수량 개념 | bulk `_sendPerCountry`(1~50), express 100~5000 | compose→sendBulkLetter/sendBrandExpressBlast |
| 근접 픽업 판정 + 픽업 시트 | app_state 10002(distanceTo 게이트) + `_PickupSheet`(world_map 2425~) 자동 오픈 | |
| 퍼널 카운터 (서버 atomic) | `pickupCount`(10124)/`revealedCount`(2429)/`redeemedCount`(2430) | 발송→픽업→코드노출→사용 4단계 |
| Brand Insights 4단계 퍼널 | brand_insights.dart + refreshBrandInsightsFromServer(2402~) | 대시보드 D의 데이터 소스 |
| 혜택 필드 + 노출 게이트 | `redemptionInfo`/`redemptionCode`/`codeRevealedAt` | 코드는 이미 reveal 탭 전까지 비공개 |
| zone 수량 캡 | brand_zone `maxRedeems`/`redeemedCount`/`isActive` | zone 경로는 잔여 계산까지 이미 가능 |
| ExactDrop 크레딧 소비/환불 | consumeExactDropCredit(1252)/refund(1270) | 과금 파이프 |
| 마커 배지 체계 | brandEmoji/레어 배지 (letter.dart:128, world_map 2393) | 캠페인 배지 얹을 자리 확보 |

## 2. 신규 구현 3덩어리 (P1 범위)

### N1. 캠페인 잔여 카운터 (후보 A 핵심) — ~2일
- **갭**: bulk/express 는 발송 총량을 letter 에 기록 안 함 → 클라가 "잔여 47/300" 계산 불가
  (zone 경로만 maxRedeems−redeemedCount 가능)
- **설계**: Letter 에 `campaignTotalCount` 필드 추가(발송 시 1회 기록) →
  잔여 = campaignTotalCount − Σpickup. 또는 campaigns/{id} 집계 doc(서버 권위, P2 로 미뤄도 됨).
  P1 은 **letter 필드 방식**(클라 단독, rules 추가 불요) 권장.
- 지도 오버레이 위젯: 상단 배너 스택(world_map 495~750)의 **프로모 배너(위치3)와
  도착 배너(위치4) 사이**에 캠페인 카운터 pill 삽입. 오버레이 과밀 주의(기존 백로그 A).

### N2. 미스터리 봉투 연출 (후보 B) — ~2일
- **갭**: 혜택 숨김 게이트(codeRevealedAt)는 있으나 '밀봉→개봉' 연출 없음.
  `_PickupSheet` 가 본문 미리보기를 이미 노출 — 미스터리 캠페인이면 마스킹 필요.
- **설계**: Letter 에 `isMystery` 플래그(발송 파라미터) →
  ① `_PickupSheet`: 본문 대신 밀봉 봉투 카드("내용은 개봉 전까지 비밀")
  ② 픽업 → LetterReadScreen 진입 시 개봉 애니메이션 후 내용 공개
  ③ 리딤코드는 기존 reveal 게이트 그대로 (2중 공개 구조 = 티저→개봉→사용 3막)

### N3. 중간 퍼널 이벤트 (대시보드 D 보강) — ~1일, P2 로 이월 가능
- **갭**: '지도 발견/근접 이동' 로깅 없음 (발송→픽업 사이 블랙박스)
- **설계**: 기존 atomic increment 패턴 재사용 — `mapSeenCount`(마커 첫 노출 시 1회,
  클라 dedup), `nearApproachCount`(픽업 반경 진입). 과금은 픽업 기준이므로 P1 필수 아님.

## 3. 명시적 비범위 (P1 에서 안 함)
- campaigns 컬렉션/서버 권위 카운터 (P2 — rules 배포 필요)
- 웹 공유 리포트 (P2)
- 팝업 여권/웰컴 스탬프 (P3)
- 지도 상단 오버레이 전면 정리 (기존 백로그 — 카운터 pill 추가로 과밀해지면 그때)

## 4. 리스크
- 오버레이 과밀: 상단 배너 5종 + 카운터 → 캠페인 활성 시에만 표시 + 기존 배너와 상호 배타 규칙 필요
- readCount/maxReaders(3 고정) 와 캠페인 수량의 의미 충돌 — 드롭 헌트는 **1드롭=1픽업** 모델이
  자연스러움: 드롭 letter 는 maxReaders=1 로 발송 (기존 필드로 표현 가능, 스키마 변경 없음)
- i18n: 신규 문자열 14언어 (카운터/밀봉 카피 ~6키)

## 5. 일정 (P1 = 1~1.5주)
| 일 | 작업 |
|---|---|
| 1-2 | N1 campaignTotalCount + 카운터 오버레이 |
| 3-4 | N2 isMystery + 밀봉/개봉 연출 |
| 5 | maxReaders=1 드롭 모드 + 마커 캠페인 배지 |
| 6-7 | i18n 14언어 + 테스트 + TestFlight |
