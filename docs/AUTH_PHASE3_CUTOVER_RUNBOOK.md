# Auth Phase 3 Cutover 런북 — 익명 → 정식 Firebase Auth (owner-scoped WRITE)

> 목적: `request.auth.uid ≠ 앱 userId`(익명 auth) 한계를 닫아 users 문서 WRITE 를
> owner(본인)로 제한 → IDOR write / 타인 문서 위·변조 / self-grant 차단.
> **성공 가능성 최대 레버.** 잘못되면 전 사용자 write 잠금이라 **단계·검증·롤백**이 핵심.

현재 상태(Build 414): Phase 1/2 코드 완료, **flag OFF + rules.phase2 미배포** → 효력 없음.
배경/설계: `docs/AUTH_MIGRATION_DESIGN.md`. 백업 태그: `v413-pre-auth-migration`.

---

## 사전 준비 (1회)
1. **Firebase 콘솔 → Authentication → Sign-in method → Email/Password = 사용 설정** (확인됨).
2. **firebase CLI 재인증**: `firebase login --reauth` (현재 자격 만료).
3. **테스트 Firebase 프로젝트** 권장(프로덕션과 분리해 룰 먼저 실험). 없으면 프로덕션에서
   소수 계정으로 신중히.

---

## STEP 0 — Phase 1.5 룰 배포 (authUid 화이트리스트, additive·무위험)
이미 코드 반영됨(`firestore.rules` 의 `isAllowedUserUpdate` 에 `authUid` 포함). 미배포 상태.
```bash
cd "/Users/shimyup/Documents/New project/Lettergo"
firebase deploy --only firestore:rules
```
- 추가형이라 read·기존 제약 불변, flag OFF 프로덕션 무영향. **지금 배포해도 안전.**
- 효과: Phase 2(flag ON) 빌드가 user doc 에 `authUid` 를 실제로 저장 가능(이전엔 403).

## STEP 1 — Phase 2 활성 빌드로 그림자 바인딩 시작 (rules 아직 공개)
```bash
# 베타/내부 빌드에 flag 주입 (release_to_testflight 스크립트의 dart-define 에 추가)
--dart-define=AUTH_BIND_ENABLED=true
```
- 동작: 로그인/가입 성공 시 `signInOrMigrate(email,pw)` 로 정식 Firebase Auth 세션 확보 +
  user doc 에 `authUid` 기록. 실패해도 anon fallback → 앱 정상(rules 공개라 write 가능).
- **이 단계에서 rules 는 절대 cutover 하지 않는다.** 바인딩만 축적.

## STEP 2 — 실기기 검증 (TestFlight, AUTH_BIND_ENABLED=true)
체크리스트(실기기에서):
- [ ] 신규 가입 → Firebase Auth 계정 생성 + user doc `authUid` 기록 확인(콘솔).
- [ ] 로그아웃 → 재로그인 → 같은 authUid 로 복원.
- [ ] 앱 강제종료 후 cold-start → `restoreRealSessionIfAvailable` 로 비번 없이 세션 복원.
- [ ] 비밀번호 변경/재설정 후 재로그인 바인딩 유지(임시비번 흐름은 Phase 3 백로그).
- [ ] 다기기 동일 email/pw → 동일 authUid.
- [ ] 전화번호 전용(이메일 없음) 계정 비율 확인(합성 이메일 필요 여부 — 설계 §6).

## STEP 3 — 바인딩률 모니터링 (충분히 쌓일 때까지)
- 목표: 활성 사용자의 **authUid 바인딩률 95%+**.
- 측정: Firestore 콘솔/쿼리로 `users` 중 `authUid != null` 비율, 또는 임시 카운터.
- 미바인딩 사용자는 cutover 후에도 **다음 로그인 시 자동 바인딩**되어 write 복구(아래 TOFU).

## STEP 4 — rules cutover (되돌리기 가능, 신중)
`firestore.rules.phase2` 의 users 블록을 실제 `firestore.rules` 에 머지:
- `allow update` 에 `isUserDocOwnerOrClaim()`(본인 authUid 만, 미바인딩은 1회 TOFU claim) +
  `isAuthUidBindSafe()`(authUid 는 본인 uid 로만) 추가.
- `allow read: if true` 는 **유지**(지도 타워 공개 — PII 는 Build 412 에서 doc 에서 제거됨).
```bash
# rules.phase2 의 helper(isUserDocOwnerOrClaim/isAuthUidBindSafe)와 update 조건을
# firestore.rules 의 users 블록에 반영 후:
firebase deploy --only firestore:rules
```
- 효과: 이제 타인 user doc write 불가(owner 또는 미바인딩 1회 claim 만). self-grant 표면 축소.
- ⚠️ cutover 직후 미바인딩 사용자는 write 일시 제한(읽기는 됨) → 재로그인 시 자동 바인딩.

## STEP 5 — cutover 후 모니터링 (48h)
- [ ] write 실패(403) 급증 없는지(미바인딩 잔존 사용자 신호).
- [ ] 신규 가입/발송/프로필수정 정상.
- [ ] 결제 크레딧 grant 정상(revenueCatWebhook 서버 권위 — Phase 3 와 독립).

---

## 롤백 (즉시)
- **rules**: 직전 `firestore.rules`(공개-write 버전) 재배포 → 즉시 원복.
- **flag**: `AUTH_BIND_ENABLED=false` 빌드 재배포(바인딩 데이터는 무해히 잔존).
- **코드**: `git reset --hard v413-pre-auth-migration`.

## 잔여/주의 (Phase 3 범위 밖, 별도 백로그)
- **credit self-grant**: owner-scope 후에도 본인이 자기 doc credit 을 self-mint 가능 →
  `isReasonableUserCounterDelta`(감소만) 유지 + **revenueCatWebhook 서버 grant**(이미 구현,
  배포 대기)로 해결. rules 만으론 불충분.
- **letters owner-scope**: phase2 룰엔 users 만. letters 는 pickup(타인) 이 readCount 를
  증가시켜야 해 owner-only 불가 → 카운터는 공개 유지, 본문/발신자 immutable(현행).
  `senderIsBrand` 위조(공식발송인 사칭)는 verified-brand 레지스트리(서버) 필요 — 별도 과제.
- **임시비번 재설정 흐름**: 정식 세션 없이 재설정 → 재로그인 시 바인딩(Phase 3 후 모니터).
- **계정 삭제**: Firebase Auth `accounts:delete` 도 함께 호출하도록 deleteAccount 확장(설계 §6).
