# Release Notes — Build 101 (1.0.0+101)

Date: 2026-04-19

Build 99–101 핫픽스 3종 누적 (Build 98 위에 얹힘). Build 98 의 기능 요약은
[release-notes-build-98.md](release-notes-build-98.md) 참조.

- Build 99 — 로그아웃 시 마지막 위치 Firestore 스냅샷
- Build 100 — Firestore PATCH race condition 수정 (0,0 좌표 버그 근본 원인)
- Build 101 — 관리자 회원 삭제·회원탈퇴 인증 토큰 누락 수정

---

## 🇰🇷 Korean

### 🗺️ 지도: 로그아웃한 테스터도 마지막 위치가 유지돼요 (Build 99)

- `AuthService.logout()` 이전에 Firestore에 최종 위치·프로필 스냅샷
- `isMapPublic` 설정은 그대로 존중 (프라이버시 강제 공개 안 함)
- `lastSeenAt` · `loggedOutAt` 타임스탬프 추가 — 나중에 "최근 접속" 필터에 활용 가능

### 🛠 좌표 0,0 버그 근본 수정 (Build 100)

**증상**: 관리자 패널에서 일부 회원 좌표가 `0.0000, 0.0000` 으로 표시되고
지도에서도 보이지 않았어요.

**원인**: Firestore REST API 의 PATCH는 `updateMask` 없이 쓰면 요청에 없는
필드를 서버에서 삭제합니다. 가입 시 두 개의 쓰기(`_saveUserToFirestore`,
`_ensureInviteIdentityOnServer`) 가 `unawaited` 로 경쟁하며 서로의 필드를
덮어써서, 초대코드 쓰기가 나중에 도착하면 위도/경도가 지워졌습니다.

**해결**:
- `FirestoreService.setDocument()` 가 모든 PATCH에 `updateMask.fieldPaths` 자동 삽입
- `_saveUserToFirestore()` 직접 호출 경로도 동일하게 updateMask 적용
- 기존 0,0 유저는 **다음 로그인 시 자동 복구** — GPS 또는 기본 위치(서울)로
  latitude/longitude 가 다시 써짐

### 🔐 관리자 회원 삭제·회원탈퇴 복구 (Build 101)

**증상**: 관리자 패널의 "회원 삭제" 버튼을 눌러도 삭제되지 않고, 일반 회원의
"회원탈퇴" 도 원격 데이터를 지우지 못했어요.

**원인**: 두 경로 모두 `http.delete(url?key=API_KEY)` 로 raw 호출 — Firestore
보안 규칙이 `/users/{id}` 삭제에 `isSignedIn()` 을 요구하는데 Authorization
헤더가 없어 401/403 무음 실패.

**해결**: 두 경로 모두 `FirestoreService.deleteDocument()` 경유로 변경. 이
헬퍼가 Firebase Auth anonymous 토큰을 자동으로 헤더에 주입합니다. 차단/등급
변경은 이미 같은 경로였기에 원래 정상이었습니다.

---

## 🇺🇸 English

### 🗺️ Map: logged-out testers stay at their last position (Build 99)

- Final snapshot to Firestore before `FirebaseAuth.signOut()`
- Respects `isMapPublic` (privacy setting not forced on)
- Adds `lastSeenAt` / `loggedOutAt` for future "recent activity" filters

### 🛠 Root-cause fix: towers stuck at 0,0 (Build 100)

**Symptom**: some members showed `0.0000, 0.0000` in the admin panel and
never appeared on the map.

**Cause**: the Firestore REST PATCH, when called without an `updateMask`,
deletes any field not present in the request body. Two writes race on
signup (`_saveUserToFirestore` + `_ensureInviteIdentityOnServer`, both
unawaited); whichever lands second wipes the other's fields. When the
invite write won, `latitude` / `longitude` were erased.

**Fix**: every PATCH to `/users/{id}` now carries
`updateMask.fieldPaths` for each key in the body. Affected testers
self-heal on their next sign-in (their current GPS or the Seoul default
gets written back with the new merge-safe PATCH).

### 🔐 Admin delete-user + self account-delete restored (Build 101)

**Symptom**: the admin "Delete" button on 회원 관리 and the user-facing
"회원탈퇴" both silently failed.

**Cause**: both code paths used raw `http.delete` with only
`?key=API_KEY` — no Authorization header. Firestore rules require
`isSignedIn()` for delete on `/users/{id}`, so the server returned 401/403
and the delete never happened.

**Fix**: both paths now go through `FirestoreService.deleteDocument`,
which attaches the Firebase Auth anonymous token automatically. The ban
and tier-change admin actions were already using this helper and were
working correctly the whole time — only the two delete paths had
bypassed it.

---

## 🔧 Technical

- Zero new runtime dependencies
- `flutter analyze`: 0 issues
- `flutter test`: 11 passing
- Firestore security rules unchanged (fix was entirely client-side)
- 3 commits on top of Build 98: de9c6dd, b4201e5, 6720969

---

## 📋 Post-deploy checklist

Once Build 101 rolls out:

1. **Check admin 회원 관리 screen** — members previously stuck at
   `0.0000, 0.0000` should show real coordinates after they open the
   updated app and trigger a sign-in (location grant or even Seoul
   default will write correctly now).
2. **Verify delete** — the red 🗑️ "회원 삭제" button should produce a
   "🗑️ {username} deleted" snackbar and remove the row from the list.
   If it still shows "Update failed", the Firestore rules file may
   need redeploy — run `firebase deploy --only firestore:rules`.
3. **Self-delete** — test 회원탈퇴 with a disposable account. The user
   row should disappear from admin panel within a few seconds.
4. **Logged-out tester towers** — a tester who logs out on Build 101+
   should remain on the map at their last known location; their
   username/tower style stays visible until they toggle isMapPublic off.

---

## 🚀 Store-submission summary

Both the full Build 98 feature set (welcome letter, compose prompt,
quick-pick destinations, AI letter transparency, reply-limit tooltip,
weekly reflection, push mode control, Premium collections, pen-pal tier
badges, day-of-week theme banner, streak freeze, arrival countdown,
daily 8am reminder) AND these three hotfixes ship together in Build 101.

Store-facing copy is unchanged from Build 98 —
[release-notes-build-98-paste-ready.md](release-notes-build-98-paste-ready.md)
is still the paste-ready text. The 99/100/101 fixes are pure stability
repairs; they don't need user-facing notes.
