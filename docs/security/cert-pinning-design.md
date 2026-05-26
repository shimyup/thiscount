# HTTPS Certificate Pinning — 설계 (PR-GG4 doc, Build 391)

> Audit A4: 현재 Firestore / Auth REST 직접 호출인데 cert pinning 없음. 공항 wifi 등 MITM 환경에서 idToken 탈취 위험. Phase 2 구현 전 설계 문서.

## 현황

- `firebase_config.dart` 가 hardcoded URL 사용:
  - `https://firestore.googleapis.com/...`
  - `https://identitytoolkit.googleapis.com/...`
  - `https://fcm.googleapis.com/...`
- `http` 패키지 직접 호출 (cloud_firestore SDK 미사용).
- iOS ATS 만 적용 — cert 자체 검증 X.

## 위협 모델

| 시나리오 | 영향 |
|---|---|
| 공항/카페 wifi MITM | idToken 탈취 → 사용자 가장 |
| 회사 proxy 의 HTTPS intercept | idToken / 인박스 내용 leak |
| 손상된 root CA (역사적 사례 다수) | 전체 통신 plaintext |

## 설계 — 2 단계 적용

### Stage 1: SPKI Pin 적용 (출시 후 1주일 내)

**패키지**: `http_certificate_pinning` (현재 미사용).

```dart
final dio = Dio(...);
HttpCertificatePinning.check(
  serverURL: 'firestore.googleapis.com',
  sha: SHA.SHA256,
  allowedSHAFingerprints: const [
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // 현재 인증서
    'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // 1 step backup
  ],
  timeout: 8,
);
```

**Pin 추출** (출시 전 1회):
```sh
echo | openssl s_client -servername firestore.googleapis.com \
  -connect firestore.googleapis.com:443 2>/dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary | base64
```

3 도메인 모두 추출:
- `firestore.googleapis.com`
- `identitytoolkit.googleapis.com`
- `fcm.googleapis.com`

### Stage 2: OTA Pin Rotation (Phase 2 — Cloud Function)

**문제**: Google cert 는 ~3개월마다 rotation. 앱 강제 업데이트 없이 새 pin 적용 필요.

**해결**: Firebase Remote Config 의 `cert_pins_v1` JSON:

```json
{
  "firestore.googleapis.com": {
    "active": ["AAA...", "BBB..."],
    "backup": ["CCC..."],
    "expiresAt": "2026-08-15T00:00:00Z"
  },
  ...
}
```

**Client 부트**:
1. Remote Config fetch (cache 1h)
2. `cert_pins_v1` 갱신
3. 메모리에 pin set 로드
4. `expiresAt` 24h 전 알림 → 운영자가 새 pin 업데이트

**Fail-safe**:
- pin 검증 실패 → 사용자에게 "보안: 안전하지 않은 네트워크" SnackBar → request 거부
- 99.99% 인증서 정상이지만 0.01% rotation 누락 시 사용자 사용 불가 — **소프트 모드** 권장 (release 빌드 첫 6주):
  - pin 실패 시 client-side log → 운영자 알림 → 사용자 사용 차단 X
  - 6주 후 hard fail 전환

## 출시 timing

1. **Build 391+**: 디자인 doc only (이 파일)
2. **Build 400 (1주 후)**: Stage 1 (hardcoded pins 3 도메인)
   - 24h 모니터링 → false-positive 0% 확인 후
3. **Build 410 (2주 후)**: OTA Remote Config integration

## Trade-off

| Pro | Con |
|---|---|
| MITM 차단 | Pin rotation 누락 시 출시 차단 사용자 |
| 회사 proxy 우회 | 회사 환경에서 사용자 사용 불가 (boundary case) |
| ATS 보강 | Implementation 비용 |

## Phase 2 의존성

- Cloud Function (Firebase Remote Config 서버 mutator)
- 모니터링 dashboard (pin 실패율)
- 운영 runbook (cert rotation 시 응답 절차)

## 관련 audit 항목

- A4 (이 문서)
- A11 Anti-replay nonce — cert pinning 와 별개
- A12 Server-side rate limit — Cloud Function 도입 시 함께

## 참고

- [Google CA cert rotation](https://pki.goog/)
- [http_certificate_pinning](https://pub.dev/packages/http_certificate_pinning)
- [OWASP Mobile Top 10 M3 — Insecure Communication](https://owasp.org/www-project-mobile-top-10/)
