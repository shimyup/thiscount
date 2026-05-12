# Thiscount Pre-Release Readiness (2026-05-10)

Source checklist reference: attached thread screenshots (`IMG_4544~4546`)

## 1) App Store Assets / Metadata

| 항목 | 상태 | 비고 |
|---|---|---|
| 앱 아이콘 1024x1024 | 완료 | 프로젝트 아이콘 세팅 상태 확인됨 |
| iPhone 스크린샷 세트 | 진행 필요 | 실제 기기/시뮬레이터 캡처 후 업로드 필요 |
| iPad 스크린샷 세트 | 정책 결정 필요 | iPad 배포 시 필수, 미배포면 제외 가능 |
| 앱 설명/키워드 | 완료(최신화 필요 시 재검토) | `docs/marketing/aso-copy-ko-en.md` |
| iOS 부제목 | 최신 기준 확인 필요 | 최신 쿠폰/혜택 포지셔닝 기준 문안으로 통일 |
| 개인정보 처리방침 URL | 완료(문서) / 배포 필요 | `docs/privacy.html`를 실제 웹 URL로 호스팅 필요 |
| 지원 URL | 완료(문서) / 배포 필요 | `docs/support.html`를 실제 웹 URL로 호스팅 필요 |

## 2) 기술 세팅

| 항목 | 상태 | 비고 |
|---|---|---|
| 프리플라이트(analyze/test/env) | 완료 | production-safe env 기준 `./scripts/release_preflight.sh` PASS |
| 현재 로컬 env 상태 | 블로커 | `BETA_DISABLE_IN_RELEASE` / `BETA_*` 값 정리 전에는 release preflight 실패 |
| Android 릴리즈 빌드 | 완료 | `app-release.aab`, `app-release.apk` 생성 확인 |
| iOS 릴리즈 빌드(no-codesign) | 완료 | `build/ios/iphoneos/Runner.app` 생성 확인 |
| API 키 환경변수 주입 | 완료 | preflight 스크립트에서 강제 검사 |
| Stadia 지도 언어 통일 | 경고 | `STADIA_MAPS_API_KEY` 비어 있으면 현지어 라벨 혼합 가능 |
| Android Firebase 설정 위생 | 경고 | `google-services.json` 에 legacy package 항목 2개 잔존 |
| 에러 트래킹 설정 | 미적용 | Firebase Crashlytics/Sentry 미연동 상태 |
| 서드파티 SDK 점검 | 완료(코드기준) | RevenueCat/Firebase REST/geolocator 등 사용 |
| 메모리 누수 점검 | 진행 필요 | Xcode Instruments / Android Profiler 실측 필요 |
| OTP 코드 노출(릴리즈) | 완료(패치) | 디버그에서만 표시되도록 수정 |

## 3) 법적/정책

| 항목 | 상태 | 비고 |
|---|---|---|
| 개인정보 처리방침 | 완료(문서) | `docs/privacy.html` |
| 이용약관 | 완료(문서) | `docs/terms.html` |
| Data Safety 기입안 | 완료(초안) | `docs/release/play-data-safety-draft.md` |
| 연령등급/콘텐츠 등급 | 진행 필요 | App Store / Play 콘솔에서 설문 제출 |
| COPPA 대상 여부 확인 | 진행 필요 | 13세 미만 타깃 여부 정책 결정 필요 |

## 4) 계정/인증서/번들

| 항목 | 상태 | 비고 |
|---|---|---|
| Apple Developer 계정 | 콘솔 확인 필요 | 스레드 체크리스트 기준 유료 계정 필수 |
| 인증서/프로비저닝 | 콘솔 확인 필요 | Xcode/ASC에서 최신 상태 확인 필요 |
| Bundle/Application ID 일관성 | 완료 | iOS/Android 통일: `io.thiscount` |

## 5) 자주 발생 실수 기준 점검

| 리스크 | 상태 | 대응 |
|---|---|---|
| 지원 이메일/브랜드 일관성 | 진행 필요 | `thiscount.io` 기준 운영 이메일과 앱 내 링크 일치 확인 필요 |
| 개인정보 처리방침 URL 오류 | 진행 필요 | URL 호스팅 후 외부 접속/모바일 접속 확인 |
| 인증서 만료 | 진행 필요 | 배포 직전 인증서/프로비저닝 재확인 |
| 에러 트래킹 미설정 | 진행 필요 | 최소 crash 수집 도입 권장 |

## 6) 배포 직전 실행 순서 (권장)

1. `docs/privacy.html`, `docs/support.html`, `docs/terms.html`를 실제 `thiscount.io` 도메인에 배포
2. App Store Connect/Play Console에 최신 쿠폰/혜택 포지셔닝 문안 반영
3. `.env.local` 또는 release env 에서 `BETA_FREE_PREMIUM`, `BETA_UPGRADE_SIMULATOR`, `BETA_ADMIN_EMAIL` 제거 확인
4. `STADIA_MAPS_API_KEY` 주입 여부 확인
5. 실기기 결제 시나리오 최종 확인
   - Premium 구매
   - Brand 구매
   - Gift 구매
   - Restore 구매
6. iPhone/Android 스크린샷 최종 세트 업로드
7. 인증서/프로비저닝/심사 메모 최종 점검 후 제출
