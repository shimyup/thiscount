# 출시 전 회원 보안 감사 — Build 479 (2026-06-20)

5도메인 병렬 감사(인증/세션 · PII노출 · IDOR/rules · 저장소/시크릿 · 입력검증/글로벌컴플라이언스)
→ 적대적 재검증 → 클라이언트 수정. 글로벌 14언어 출시 기준.

## ✅ 클라이언트 수정 완료 (Build 479)

| # | 심각도 | 항목 | 수정 |
|---|---|---|---|
| 1 | HIGH | 로그아웃 시 결제 예약 prefs 잔존 → 공유기기 다음 계정이 예약 다운그레이드/선물 trial/결제일 상속(거짓 Premium·강제 강등) | `_clearUserScopedPrefs` 에 `purchase_next_billing_date`/`purchase_giftExpiry`/`purchase_scheduled_plan_change_date`/`_target`/legacy `purchase_scheduledDowngrade` 추가 |
| 2 | MED | towerName 읽기-쓰기 비대칭 → 비공개 사용자의 pre-412/구버전 평문 타워명(실명·상호 가능)이 지도/타워에 노출 | `app_state.dart:7574` `towerName: isPublic ? towerName : null` (username 과 동일 게이트) |
| 3 | MED | redemptionInfo BIDI 미정화 → 공개 쿠폰 안내에 방향 스푸핑 | `_redemptionInfoSafe` getter(=`_stripBidiControls`)로 전 발송경로 정화 |
| 4 | MED | 비번찾기 relay 미설정 시 release 에서 임시비번 화면 노출 가능 | (확인) relay(AUTH_EMAIL_FN_URL)는 배포·주입됨 → release 정상 메일 경로. on-screen fallback 은 debug/미설정만. ※ 출시 빌드에 URL 주입 누락 안 되도록 빌드 스크립트 유지가 게이트 |
| 5 | LOW | BIDI 제거 집합 불완전(ZWSP/LRM/RLM/ALM/BOM) → 글자 사이 ZWSP 금칙어 우회 | `_bidiControlRe` 에 `U+200B-200F`/`U+061C`/`U+FEFF` 추가 |
| 6 | LOW | PII 자동검출 한국 한정 → 글로벌 회원 PII 무경고 공개 | 국제전화(E.164) + 이메일 검출 추가(`piiLabelEmail` 14언어) |
| 7 | LOW | OTP verify 실패 카운터 email/phone 공유(가용성) | (보류 — 권한상승 아님, 영향 경미. 다음 라운드) |

> #4 는 코드상 이미 안전(relay 배포됨). #7 은 보안 위협이 아니라 가용성 minor 라 이번 빌드 보류.

## 🔴 배포/백엔드 필요 (코드 단독 수정 불가 — 사용자 영역)

| 심각도 | 항목 | 필요 조치 |
|---|---|---|
| HIGH(기능회귀) | **초대보상 credit grant 가 firestore.rules(증가 차단)에 막혀 영구 실패** — `applyInviteCode` 의 `inviteRewardCredits=cur+5` PATCH 가 403 | revenueCatWebhook 패턴처럼 **Cloud Function 권위 grant** 로 이전(rules 유지). 배포 필요 |
| MED | isBrand 자가승급 — update 화이트리스트가 isBrand/brandName 허용 | `firestore.rules.phase2` cutover(화이트리스트 제거 + webhook 승급) 배포 |
| MED | followerCount IDOR — 타인 카운터 ±1 변조(KPI 오염) | Phase3 owner-bind 또는 집계 Function 권위 이전 |
| MED(컴플라이언스) | 약관(privacy/terms/locationTerms) ja/zh/fr/... 12언어 페이지 부재(`?lang=en` fallback) | thiscount.io 에 14언어 약관 호스팅 + `AppLinks` lang 화이트리스트 확장 |
| 수용/Phase2 | redemptionCode 평문 + `letters read:if true` | subcollection 분리(IDOR reveal 가드로 현 단계 수용) |

## 견고 확인(FALSE-POSITIVE)
로그인/OTP brute-force(5회 lockout·SecureClock·secure storage·email/phone 분리),
계정 enumeration timing oracle 방어, 토큰 secure storage(첫잠금·encryptedSharedPreferences),
익명 letter de-anon(클라+rules 백스톱), isMapPublic 좌표 4필드 null PATCH,
서버급 키(Resend/Gemini/Twilio) functions secret 이전, 본문 XSS 비해당(Text 위젯),
이메일 CR/LF(relay 고정템플릿), banned 발송 게이트, 연령 게이트(EU16/14 + 14언어),
동의 분리(마케팅§50 opt-in / 제3자§24의2) 14언어 완비.

## 총평
**출시 차단(BLOCKER)급 신규 0건.** 클라이언트 수정 6건 반영(공유기기 결제 상속 HIGH 포함).
남은 위협은 전부 익명-auth 구조 한계(Phase3 rules cutover) 또는 백엔드 grant(Cloud Function) /
문서 호스팅 = 코드 밖 사용자 영역. 출시 게이트 관점 코드 보안은 양호.
