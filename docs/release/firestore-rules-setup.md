# Firestore Security Rules Setup

Last updated: 2026-04-18 (Build 74)

Build 74 부터 관리자 패널 회원 관리가 API key 기반 REST list 를 사용합니다.
이 방식이 작동하려면 Firestore 보안 규칙을 아래처럼 설정해야 합니다.

---

## 1. 관리자 UID 확보

1. [Firebase Console](https://console.firebase.google.com/project/lettergo-147eb) 접속
2. 좌측 메뉴 → **Authentication** → **Users** 탭
3. `ceo@airony.xyz` 행 우측의 **User UID** 컬럼 값 복사
   - 예시 형태: `vXyZ9a8B7cDe6FgHiJkLmNoPqRs`

---

## 2. 규칙 게시

Firebase Console → **Firestore Database** → **Rules** 탭 → 아래 내용 전체
교체 → `게시`.

`REPLACE_WITH_YOUR_UID_HERE` 를 1번에서 복사한 UID 로 바꿔야 합니다.

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAdmin() {
      return request.auth != null &&
             request.auth.uid in [
               'REPLACE_WITH_YOUR_UID_HERE'
             ];
    }

    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }

    // ── users 컬렉션 ──
    match /users/{userId} {
      allow read: if resource.data.isMapPublic == true
                  || isAdmin()
                  || isOwner(userId);
      allow list: if true;
      allow write: if isOwner(userId) || isAdmin();
    }

    // ── letters 컬렉션 ──
    match /letters/{letterId} {
      allow read: if true;
      allow list: if true;
      allow create: if isSignedIn()
                    && request.resource.data.senderId == request.auth.uid;
      allow update: if isSignedIn() || isAdmin();
      allow delete: if resource.data.senderId == request.auth.uid
                    || isAdmin();
    }

    // ── reports 컬렉션 ──
    match /reports/{reportId} {
      allow create: if isSignedIn();
      allow read, list, update, delete: if isAdmin();
    }

    // 기타 경로는 관리자만
    match /{document=**} {
      allow read, write: if isAdmin();
    }
  }
}
```

---

## 3. 검증 체크리스트

규칙 게시 후:

- [ ] ceo@airony.xyz 으로 앱 로그인
- [ ] 설정 → 🔐 관리자 패널 → 회원 관리 진입
- [ ] 목록이 정상 로드되는지 확인 (이전 403 오류 사라져야 함)
- [ ] 다른 이메일 계정으로 로그인 → 관리자 메뉴 안 보이는지 확인
- [ ] 지도에서 다른 사용자 타워가 계속 보이는지 (일반 조회 영향 없어야 함)

---

## 4. 관리자 추가 (나중에)

관리자가 2명 이상 필요할 때:

```js
function isAdmin() {
  return request.auth != null &&
         request.auth.uid in [
           'PRIMARY_ADMIN_UID',
           'SECOND_ADMIN_UID',
           'THIRD_ADMIN_UID'
         ];
}
```

Firestore Rules 편집 → 배열에 UID 추가 → **게시**.

---

## 5. 정식 출시 전 조정 (선택)

베타 기간에는 `letters` / `users` 가 list 공개이지만, 스팸 방지를 위해
정식 출시 시 다음을 고려:

- Anonymous sign-in 제거 (login 필수화)
- `letters` list 를 인증된 사용자로 제한: `allow list: if isSignedIn();`
- rate limiting (Firestore Extensions 또는 Cloud Functions)

## 6. 문제 해결

- **여전히 403**: Firebase Console 규칙 탭에 게시된 규칙 확인. UID 오타
  확인. 앱 완전 재실행 (토큰 갱신).
- **일반 사용자도 목록 보임**: `allow list: if true;` 라 그렇습니다. 필요 시
  `if isSignedIn();` 으로 변경.
- **관리자 계정이 Auth Users 탭에 없음**: 앱에서 회원가입 후 OTP 인증 완료
  → Firebase Auth 에 자동 등록됩니다.
