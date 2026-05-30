# 인증 마이그레이션 설계안 — 익명 Auth → 정식 Firebase Auth

작성: 2026-05-30 (Build 413 기준). 목적: PII 시뮬레이션 **HIGH** 결함 해소 —
"익명 Firebase Auth 라 `request.auth.uid` 가 앱 `userId` 와 결합되지 않아
Firestore owner-check 가 불가능 → 타인 문서 위·변조(IDOR write) + 크레딧 self-grant".

> ⚠️ 이 변경은 잘못되면 **전 사용자 로그인 잠금**으로 이어진다. 따라서 무중단
> 단계별로 진행하고, 되돌릴 수 없는 단계(rules cutover)는 실기기 + 테스트
> 프로젝트 검증 후에만 적용한다.

---

## 1. 현재 구조

- **로컬 인증**: username + password(PBKDF2)를 `FlutterSecureStorage` 에 보관.
  `userId = 'user_<uuid>'` 를 가입 시 1회 생성·로컬 저장. 서버는 비번을 모른다.
- **서버 접근**: Firestore/Storage REST 호출용으로 Firebase **anonymous** 로그인
  (`signInAnonymously`, firebase_auth_service.dart:166). 이 anon uid 는
  cold-start 마다 새로 발급되며 앱 `userId` 와 무관.
- **Firestore rules**: owner 식별 불가 → `users`/`letters` `allow read: if true`,
  write 도 사실상 누구나 가능(필드 화이트리스트·delta cap 만 존재).
- **이미 존재(미사용)**: `FirebaseAuthService.signIn(email,password)` /
  `signUp(email,password)` REST 메서드가 구현돼 있음 (identitytoolkit
  signInWithPassword / signUp). → 마이그레이션 plumbing 의 대부분이 이미 있음.

## 2. 핵심 난점과 해결

- **서버가 비번을 모른다** → custom-token 으로 `userId` 소유를 서버가 검증할 수
  없다. 따라서 "서버가 신원을 검증"하려면 **자격증명이 서버에 있어야** 한다 →
  Firebase Auth **이메일/비밀번호** 사용 (이미 OTP 로 검증하는 이메일 활용).
- **문서 re-keying 회피**: 기존 문서는 `user_<uuid>` 로 키됨. 이를 Firebase uid
  로 다시 키하는 건 위험·대규모. 대신 **`userId` 는 그대로 두고**, 문서에
  `authUid`(Firebase Auth uid) 필드를 바인딩. rules 는 `request.auth.uid ==
  resource.data.authUid` 로 owner 확인.

## 3. 목표 구조

- 신원 = Firebase Auth (email/password). `request.auth.uid` = Firebase uid.
- `users/{userId}` 문서에 `authUid` 필드 = 그 사용자의 Firebase uid (TOFU 바인딩).
- username 은 표시·로그인 alias (로컬에서 email 로 resolve).
- **WRITE owner-scoped** (핵심 보안 이득): `users`/`letters`/credit 필드 변경은
  `request.auth.uid == authUid/senderAuthUid` 인 본인만. → IDOR write + self-grant 차단.
- **READ**: 지도용 공개 읽기는 유지(본 doc 은 Build 412 에서 PII 최소화 완료 —
  email/phone/비번은 애초에 server doc 에 없음, username 은 비공개 시 null).

## 4. authUid 바인딩 (TOFU claim) 규칙

```
// users/{userId}
allow update: if isSignedIn() && (
     resource.data.authUid == null            // 아직 미바인딩 → 최초 claim 허용
  || resource.data.authUid == request.auth.uid // 이미 내 것
);
```
- 최초 마이그레이션 시 `authUid` 가 비어 있으므로 누구나 claim 가능해 보이지만,
  **자기 userId 는 본인만 안다**(로컬 비밀). 실사용 위험은 낮고, claim 직후
  잠금. 강화하려면 claim 을 Cloud Function(ID 토큰 + userId 매칭 로그) 경유로.

## 5. 단계별 무중단 롤아웃

**Phase 0 — 백업 (완료)**: 태그 `v413-pre-auth-migration`.

**Phase 1 — 비파괴 groundwork (이번 커밋, 런타임 동작 불변)**
- 플래그 `AUTH_BIND_ENABLED` (dart-define, 기본 **false**).
- `FirebaseAuthService.signInOrMigrate(email,password)` 헬퍼 추가
  (signIn → EMAIL_NOT_FOUND 면 signUp 로 on-the-fly 생성). **미호출**(플래그 OFF).
- 목표 rules 를 `firestore.rules.phase2` 별도 파일로 작성(**미배포**, 리뷰용).
- 현재 rules / 로그인 흐름 **무변경** → 빌드/사용자 영향 0.

**Phase 2 — 그림자 바인딩 (✅ 코드 구현 완료, 플래그 OFF — 실기기 검증 후 활성)**
- 구현됨 (`AUTH_BIND_ENABLED`, 기본 false):
  · auth_service.login/signUp 성공 직후 `_bindFirebaseAuthIfEnabled(email,pw)`
    → `FirebaseAuthService.signInOrMigrate` (best-effort, 실패 무시).
  · 정식 세션의 refresh token 을 secure storage 에 보관(`_persistRealRefreshToken`).
  · cold-start: `_initFirebaseAndSync` 가 `restoreRealSessionIfAvailable()` 우선
    시도(비번 없이 정식 세션 복원) → 실패 시 anon fallback.
  · `_doSaveUserToFirestore` 가 `realAuthUid != null` 일 때 user doc 에 `authUid` 기록.
  · logout(signOut) 시 보관된 refresh token 삭제.
- rules 는 **아직 공개 유지** → 바인딩 실패해도 앱 정상.
- ⚠️ **미검증**: auth 흐름은 analyze/유닛테스트로 검증 불가 → `AUTH_BIND_ENABLED=true`
  로 **테스트 빌드 + 실기기**에서 가입/로그인/재로그인(cold-start)/다기기/비번재설정/
  로그아웃 시나리오 검증 필수. 검증 전까지 플래그 OFF 유지.

**Phase 3 — rules cutover (되돌리기 어려움 · GATED)**
- 바인딩률 충분(예: 활성 사용자 95%+) 확인 후, `firestore.rules.phase2` 배포 →
  WRITE owner-scoped 활성. READ 공개 유지.
- 미바인딩 사용자는 다음 로그인 시 자동 바인딩 → write 복구. 그 전까진 read 가능,
  write 만 제한(드문 edge: 발송/프로필수정 일시 제한 → 재로그인 안내).

## 6. Edge cases
- **전화번호 전용(이메일 없음)**: 합성 이메일(`<userId>@phone.thiscount.local`) 로
  Firebase Auth 생성 또는 Firebase Phone Auth. (소수 — Phase 2 모니터링으로 식별)
- **비번 분실**: 기존 temp-password 흐름 → 재설정 후 로그인 시 바인딩.
- **다기기**: 같은 email/password 면 같은 Firebase uid → 자연 동작.
- **계정 삭제**: Firebase Auth `accounts:delete` 도 함께 호출 (deleteAccount 확장).

## 7. 롤백
- Phase 1/2: 플래그 OFF 빌드 재배포 → 즉시 원복(바인딩은 무해히 남음).
- Phase 3: `firestore.rules` (현재 public-write) 재배포로 즉시 원복.
- 코드: 태그 `v413-pre-auth-migration` 로 reset.

## 8. 코드 밖 (사용자/인프라 필요)
- Firebase 콘솔: **Email/Password 공급자 활성화**.
- 실기기 + 테스트 Firebase 프로젝트에서 가입/로그인/재로그인/다기기/비번재설정 검증.
- Phase 3 rules 배포는 모니터링 후 수동 결정.

## 9. 이번 세션 구현 범위 = Phase 1 only (비파괴)
런타임 동작을 바꾸지 않는 groundwork 만. Phase 2(플래그 ON)·Phase 3(rules 배포)는
실기기 검증 + 명시 승인 후.
