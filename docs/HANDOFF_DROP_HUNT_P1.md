# Handoff Spec: 드롭 헌트 P1 (헌트 지도 오버레이 + 미스터리 봉투)

> 2026-07-03 · **Figma v3 · Acid Editorial 기준** (파일 Snvu81q2iyFNOSpZrImJtn, 프레임 A 11:3 / B1 12:2 / B2 12:28)
> 대상: Flutter · 전제: docs/PIVOT_P1_GAP_ANALYSIS.md — `campaignId`/`_PickupSheet`/`codeRevealedAt` 재사용
> ⚠️ v3 개정: 키 컬러 = **Thiscount Lime `#D9F154`** (캠페인 서브 브랜드 팔레트 — 본 앱 palette.premium 골드와 별개 운용)

## Overview

| 화면 | 신규/수정 | 파일 |
|---|---|---|
| A. 캠페인 카운터 오버레이 | 신규 위젯 `_CampaignHuntBanner` | world_map_screen.dart (배너 스택 위치3↔4 사이) |
| B-1. 밀봉 픽업시트 | `_PickupSheet` 에 `isMystery` 분기 | world_map_screen.dart:2425~ |
| B-2. 개봉 리드화면 | `LetterReadScreen` 개봉 연출 + 혜택 티켓 | letter_read_screen.dart |

## Design Tokens — v3 캠페인 서브 팔레트 (신규 `HuntPalette` 상수 클래스로 도입)

기존 `context.palette` 와 별개의 **캠페인 한정 상수**. 드롭 헌트 UI 밖에서 사용 금지.

| 상수 (HuntPalette.*) | 값 | 사용처 |
|---|---|---|
| `lime` (키) | #D9F154 | 카운터 숫자, 드롭 핀 fill, 경로 점선, LIVE·진행바, 왁스 실, CTA fill, 하이라이트 |
| `limeInk` | #232B04 | lime fill 위 텍스트/아이콘 (핀 %, CTA 라벨) |
| `limeDeep` | #55660A | 라이트 표면(티켓) 위 lime 계열 텍스트 |
| `ink` | #141315 | 다크 캔버스 (웜 잉크 — 청색 블랙 금지) |
| `elev` | #232226 | 배너/칩 표면 |
| `cream` | #F2EDE2 | 다크 위 본문 텍스트, 독(dock) 표면 |
| `paper` | #FAF7EF | 봉투 카드 |
| `oat` | #EFEAE0 | B2 라이트 캔버스, 티켓 펀치홀 |
| `mut` | #8F8B80 | 보조 텍스트 (다크) |
| `cherry` | #FF5C48 | **긴급·만료 전용** (장식 금지) |
| `lav` | #B9A8FF | **밀봉(미스터리) 상태 전용** — SEALED 링, 상태 라벨 |

접근성 검증: lime on ink ≈13:1 ✓ / limeInk on lime ✓ / limeDeep on paper ≥6:1 ✓ / cream on ink ✓.

## Typography — v3

| 역할 | 서체 (Figma) | Flutter 적용 |
|---|---|---|
| 디스플레이 숫자 (`47`, `30%`, `320M`) | Bricolage Grotesque ExtraBold | google_fonts `BricolageGrotesque` 또는 폰트 에셋 번들 |
| 감성 액센트 (*drops left*, *sealed drop*, *off, today*) | Instrument Serif Italic | google_fonts `InstrumentSerif` italic |
| 마이크로 라벨 (`SEALED DROP`, `ETA 08:24`, `NO. 0047/0300`) | DM Mono + letterSpacing 넓게 | google_fonts `DMMono` |
| 한글 본문/CTA | IBM Plex Sans KR (이상적으로 Pretendard 에셋) | 기존 앱 폰트 유지 가능 — P1은 한글만 기존 폰트로 타협 허용 |

P1 구현 타협 허용: 신규 폰트 3종 번들이 부담이면 **숫자/라벨만 monospace 계열 fallback** 으로 시작하고 폰트는 P2 폴리시로 이월 가능 (스펙상 명시).

## A. `_CampaignHuntBanner`

### Layout
- 배너 스택 내 삽입 위치: 브랜드 프로모 배너(위치3) 아래, 도착 배너(위치4) 위.
  **상호 배타**: 헌트 배너 표시 중엔 프로모 배너 숨김 (헌트 우선 — 유료 캠페인이 우선순위).
- 좌우 margin 12, 내부 padding 10×8, radius 12, 높이 40(+진행바 3).
- 구조: `Row[ ti-target 아이콘 16 + 캠페인명(좌, ellipsis) | Spacer | 잔여 카운터(우) ]`
  + 하단 `LinearProgressIndicator` 높이 3 (track bgElevated / fill lime).
- 배경 bgCard 92% opacity, border lime 1px. (지도 위라 반투명 필요)

### Data
- 잔여 = `campaignTotalCount − Σpickup` (N1 신규 필드). 갱신 = 기존 30s letter sync tick.
- 내 픽업 성공 시 **optimistic 즉시 −1** (서버 확인 전 UI 선반영, 실패 시 롤백).
- 다중 캠페인: P1 은 최신 1개 + "외 N개" suffix. 탭 → 헌트 캠페인 마커로 카메라 이동.

### States
| 상태 | 표현 |
|---|---|
| 기본 | 위 스펙 |
| 잔여 0 (소진) | 카운터 → "마감" mut, border hairline 로 강등, 진행바 100% lime 유지. 4시간 후 배너 자동 숨김 |
| 로딩(총량 미수신) | 카운터 자리 "—" (skeleton 금지 — 지도 위 셔머는 소음) |
| 오프라인 | 마지막 값 + 우측 stale dot 6px textMuted |

### Animation
| 요소 | 트리거 | 애니 | 시간/이징 |
|---|---|---|---|
| 배너 | 등장 | slide-down + fade | 200ms easeOut |
| 잔여 숫자 | 감소 | scale 1.0→1.15→1.0 | 150ms easeOut |
| 진행바 | 값 변경 | 폭 애니 | 300ms easeInOut |

### 마커 (기존 `_UnreadDeliveredMarker` 변형)
- 헌트 드롭: 이모지 대신 `ti-lock` 글리프 + lime 외곽 링 1.5px + 하단 라벨 "밀봉 드롭"(11px textMuted, zoom ≥ 15 만).
- 소진 캠페인 마커: opacity 0.4 + 픽업 시트 진입 시 "마감" 안내.

### A11y
- Semantics: "『A브랜드 드롭 헌트』, 잔여 47/300, 탭하면 지도 이동".
- 터치 타겟 44px 이상 (배너 전체 탭 영역).
- lime on ink 대비 ≈ 13:1 통과. RTL(ar): Row 자동 반전 확인.

## B-1. 밀봉 픽업시트 (`_PickupSheet` isMystery 분기)

### 분기 조건
`letter.isMystery == true && 미픽업` → 본문 미리보기 블록을 마스크 카드로 교체. 나머지(발신 브랜드명, 시트 구조) 유지 — **브랜드명은 항상 공개** (신뢰·법적 표시).

### 마스크 카드
- bgDeep, radius 8, border 1px dashed hairline, padding 10.
- 1행: "? ? ? ? ? ?" textDisabled, letterSpacing 3 (장식 — Semantics 제외).
- 2행: 소셜프루프 "{pickupCount}명이 이미 열었어요" textSecondary 11px. pickupCount==0 → "첫 번째로 열어보세요".

### CTA + 근접 상태
| 상태 | CTA | 보조 라인 |
|---|---|---|
| 반경 안 | filled lime / HuntPalette.limeInk "여기서 개봉하기", 높이 48 | lime색 "ti-map-pin 지금 열 수 있어요" |
| 반경 밖 | bgElevated + textDisabled (탭 가능, 탭 시 아래 라인 강조) | textSecondary "{m}m 더 가까이 가면 열려요" (기존 거리 계산 재사용) |
| 픽업 중 | CTA 내 16px 스피너, 중복 탭 차단 | — |
| 소진 | "마감된 드롭이에요" textMuted, CTA 제거 | — |

**왜 disabled 탭 허용**: 완전 disabled 는 이유를 알 수 없음 — 탭하면 거리 라인이 shake 120ms 로 응답 (CDS '비활성 대신 응답' 원칙).

### Animation
개봉 탭 → 봉투 flap `rotationX 0→-150°` 400ms easeOutBack → 시트 dismiss + LetterReadScreen push(fade 200ms). `MediaQuery.disableAnimations` 시 fade 만.

## B-2. 개봉 리드화면 (LetterReadScreen)

### 개봉 연출 (mystery 최초 1회)
- 진입 시: 콘텐츠 opacity 0 → 봉투 개봉 350ms → 내용 fade+slide-up(12px) 250ms(delay 150ms).
- 1회성: `letter.openedAnimationShown` 로컬 플래그(prefs 불요 — 세션 메모리로 충분).

### "개봉 완료" 헤더 밴드
- lime 10% tint(bgCard 위 오버레이), padding 10×12, `ti-confetti` 16px lime + "개봉 완료" textPrimary 500.

### 혜택 티켓 (기존 `_buildInboxTicket` 스타일 재사용)
- 좌: 브랜드명 textMuted 11px / 혜택 텍스트 textPrimary 14px 500 (max 2줄 ellipsis).
- 중: `_TicketDashLine` 세로 재사용 (inbox_screen.dart:3688 — 공용 위젯로 승격).
- 우: "사용하기" limeDeep 세로 라벨 → 기존 리딤 플로우.
- 코드 블록: 기존 `codeRevealedAt` 게이트 그대로 — 마스크 "TC-••••-••••" textDisabled letterSpacing 2 + "리딤코드는 매장에서 공개" textSecondary 11px.

## Content (i18n 14언어 신규 키 7개)

| 키 | ko 기준 카피 | 제한 |
|---|---|---|
| huntBannerTitle | "{brand} 드롭 헌트" | brand 20자 ellipsis |
| huntRemaining | "잔여 {n}/{total}" | — |
| huntSoldOut | "마감" | — |
| mysterySealedHint | "내용은 개봉 전까지 비밀" | — |
| mysteryOpenCta | "여기서 개봉하기" | — |
| mysteryProofOpened | "{n}명이 이미 열었어요" / 0건 변형 | 복수형 처리(ru/ar 주의) |
| mysteryTooFar | "{m}m 더 가까이 가면 열려요" | — |

## Edge Cases
- 긴 브랜드명(th/de 장문): 배너 좌측 max 55% 폭 ellipsis.
- 카운터 총량 미기록(구버전 letter): 카운터 미표시, 마커·밀봉만 동작 (graceful).
- 동시 픽업 경합으로 잔여 음수: `max(0, …)` clamp.
- 서버 pickupCount 지연: optimistic 값과 충돌 시 서버 값 우선.
- 오프라인 개봉 시도: 기존 픽업 오프라인 처리 흐름 따름 (신규 없음).

## Accessibility 요약
- 포커스 순서(시트): 브랜드명 → 마스크 카드(소셜프루프만 낭독) → CTA → 거리 라인.
- 마스크 "?" 문자열·마스크 코드: Semantics excludeSemantics.
- 개봉 애니: disableAnimations 존중. CTA 높이 48dp. 대비: 모든 신규 조합 기존 WCAG 통과 토큰만 사용.
