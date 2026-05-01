# Letter Go — 개인정보 처리방침 핵심 공시 항목

이 문서는 App Store / Google Play 데이터 안전 양식 + 개인정보 처리방침
페이지에 반영해야 할 내용을 한 곳에 모은 운영 자료입니다.

---

## 1. 수집하는 개인정보

| 항목 | 수집 시점 | 사용 목적 | 보관 기간 |
|------|-----------|-----------|-----------|
| 이메일 또는 전화번호 | 가입 OTP 인증 | 계정 식별 + 로그인 | 회원 탈퇴 시 즉시 삭제 |
| 닉네임 | 가입 시 | UI 표시 | 회원 탈퇴 시 즉시 삭제 |
| 국가·도시 | 가입 시 (사용자 선택) | 발신/수신지 매칭 | 좌표는 ~110m 정밀도로 round 후 저장 |
| GPS 좌표 (When In Use) | 앱 사용 중 | 편지 픽업·발송 위치 결정 | 자동 round 후 Firestore `users/{id}` |
| 편지 본문·사진 | 사용자 직접 입력 | 다른 사용자에게 전달 | 발신 후 30일 자동 만료 (정책) |
| 디바이스 IDFA / GAID | 수집 안 함 | — | — |

## 2. 제3자 공유

| 수신자 | 데이터 | 목적 |
|--------|--------|------|
| Firebase (Google) | 모든 위 항목 | 인증 / 데이터베이스 / 알림 |
| Twilio | 전화번호 | SMS OTP 발송 |
| Resend / SendGrid | 이메일 | 이메일 OTP 발송 |
| RevenueCat | 사용자 ID, 이메일 | 구독 결제 처리 |
| MyMemory Translation API | **편지 본문 텍스트** | 사용자가 번역 버튼 누를 때만 |
| Google Translate API | **편지 본문 텍스트** | MyMemory fallback |

⚠️ **MyMemory / Google Translate** 는 사용자가 번역 버튼을 누를 때마다 letter
본문이 외부 서비스로 전송됩니다. 처리방침에 명시 + UI 에 1회 안내가
필요합니다.

## 3. 사용자 권리

- **데이터 삭제 요청**: 앱 내 "회원 탈퇴" → 30초 내 즉시 처리
  - `users/{id}` 문서 영구 삭제
  - 본인 발송 letters 의 status 를 `deletedBySender` 로 마킹 (admin 후속
    hard-delete)
  - SharedPreferences + Secure Storage 완전 wipe
- **데이터 열람 요청**: ceo@airony.xyz 로 이메일. 7영업일 이내 회신.
- **수정 요청**: 앱 내 프로필 편집 / 또는 위 이메일.

## 4. 데이터 보안

- 디바이스 로컬: AES-256-CBC + per-device 키 (Flutter Secure Storage / iOS
  Keychain / Android Keystore)
- 비밀번호: PBKDF2-SHA256 × 600,000 라운드 + 16바이트 salt
- 전송 구간: HTTPS (TLS 1.2+) 강제
- Firestore 규칙: 본인만 자기 프로필 수정, letters 본문 immutable, delete
  관리자 한정
- 백그라운드 위치 추적: 사용 안 함 (`When In Use` 권한만 요청)

## 5. 14세 미만 사용자

- 14세 미만 가입 차단 정책. 가입 시 만 14세 이상임을 동의 받음.
- COPPA / GDPR-K 준수.

## 6. 분쟁 해결

문의: ceo@airony.xyz
회사: Airony (서울특별시)
시행일: 2026-05-01 (Build 207)
