# 실제 시뮬레이터 런타임 검증 — Build 414 (iPhone 17 Pro, iOS 26.2)

`scripts/run_ios_debug.sh` 로 debug 빌드 → 부팅된 시뮬레이터 실행. Xcode build done,
Dart VM 연결, 온보딩 1/3 화면("걸어가다 줍는 디스카운트") 정상 렌더 · **크래시 없음**.
스크린샷: `/tmp/sim_shots/01_launch.png`.

## 🔴 런타임 결함 RT-1 (P0 후보 — 데이터 무결성): user 프로필 doc 저장이 403 으로 전량 실패

**증상(로그):** 익명 로그인 성공(`[FirebaseAuth] 익명 로그인 성공: hGEZ...`) **이후에도**
`[Firestore] user save client error 403: PERMISSION_DENIED` 가 반복. 반면 `letters`
쓰기(`[Firebase] 월드 편지 추가 ... (delivered)`)는 정상 성공 → **letters OK / user doc만 403** 비대칭.

**근본 원인(코드):** `lib/state/app_state.dart:5555 _doSaveUserToFirestore` 의 PATCH 가
`isAllowedUserUpdate()`([firestore.rules:107](../firestore.rules)) 화이트리스트에 **없는 필드**
를 mask 에 포함:
- `id` (app_state.dart:5596) — 화이트리스트 부재
- `isBrand` (5629) — **Build 300 이 명시적으로 client 쓰기 차단**(티어=admin 전용). Build 406
  이 "계정종류 영구 동기화" 위해 PATCH 에 추가했으나 rules 와 충돌.
- `brandName` (5630, 조건부)
- `welcomeTrialClaimedAt` (5668, 조건부) — **Build 300 이 trial farming 차단 위해 화이트
  리스트에서 제거**. 그런데 client 가 여전히 mask 에 포함.
- `pickedUpCampaignIds` (5698, 조건부) — Build 324 멀티디바이스 dedup 동기화용. 화이트리스트 부재.

Firestore `diff().affectedKeys().hasOnly([whitelist])` 는 위 필드 중 하나라도 **affected
key**(값 변경/신규)면 전체 update 를 거부 → PATCH 가 atomic 이라 **카운터·위치·설정·타워
커스터마이즈 등 모든 프로필 변경이 통째로 유실**(silent, 4xx 라 retry 도 안 함).

**파급(이전 fix 들이 조용히 무력화됨):**
- Welcome trial claim 시 `welcomeTrialClaimedAt` 가 affected key → 403 → 서버 영구화 실패.
- Build 324 픽업 dedup: `pickedUpCampaignIds` 변경 → 403 → 멀티디바이스/재설치 우회 차단 무력.
- Build 406 계정종류: `isBrand`/`brandName` 변경 → 403 → Brand 재설치 시 강등 위험 (Build 406
  이 고치려던 바로 그 버그가 rules 충돌로 재발).

**주의 — 단순 화이트리스트 추가 금지:** `isBrand`/`welcomeTrialClaimedAt` 를 client-writable
로 추가하면 **무료 Brand 승급 / trial farming** 보안 구멍이 생긴다(Build 300/406 의도와 정면
충돌). 올바른 해법:
- 안전 필드(`id` immutable, `towerColor` 등 이미 일부 포함, `pickedUpCampaignIds` 검토)는
  화이트리스트 정합화.
- 보안 필드(`isBrand`/`brandName`/`welcomeTrialClaimedAt`)는 **client PATCH mask 에서 제외**
  하고 서버(admin/purchase 검증 / trial_claims) 권위 경로로만 기록. = Auth Phase 2/3 owner-
  scope 와 함께 설계.

→ deployed rules(authUid 라인 제외 = 로컬과 동일 whitelist)에서 실재. 출시 전 결정 필요.

## 한계
- `integration_test` 하네스 없음 + `idb` 미설치 → 네이티브 시뮬레이터 탭 자동화 불가.
  실제-런타임 검증 = 빌드/실행/스크린샷/로그 분석까지. 깊은 시나리오 커버리지는 100-시나리오
  다중 에이전트 시뮬레이션(코드 추론)으로 보완.
