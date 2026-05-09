# thiscount.io 정적 호스팅 가이드 (Build 273 launch)

Last updated: 2026-05-10

App Store 정식 제출 전 `thiscount.io` 도메인에 다음 3개 페이지가 반드시 라이브여야 합니다 (Apple 심사 필수):

- `https://thiscount.io/privacy.html` — 개인정보 처리방침
- `https://thiscount.io/terms.html` — 이용약관
- `https://thiscount.io/support.html` — 지원 페이지
- `https://thiscount.io/` — 마케팅 랜딩 (선택)

---

## 1. 준비된 파일

이 worktree 의 `docs/` 안에 모두 준비됨:

```
docs/
├── privacy.html    (724 lines, 한·영 toggle 지원)
├── terms.html      (137 lines, 한·영 toggle 지원)
└── support.html    (지원 페이지)
```

각 파일은 self-contained HTML — CSS inline, JS toggle 포함.

---

## 2. 호스팅 옵션 (가장 간단한 순서)

### 옵션 A — GitHub Pages (무료, 즉시)
가장 빠름. GitHub repo `docs/` 폴더를 그대로 publish.

```bash
# 1. lettergo 리포지토리 GitHub 에 main push
cd "/Users/shimyup/Documents/New project/Lettergo"
git push origin main

# 2. GitHub repo settings:
#    Settings > Pages > Source: deploy from branch > main /docs
#    저장 후 1-2분 후 https://shimyup.github.io/lettergo/privacy.html 라이브
```

이후 thiscount.io 도메인 연결:
```
GitHub Pages 설정 > Custom domain > thiscount.io 입력
DNS 설정 (Namecheap 등):
  A 레코드:
    @ → 185.199.108.153
    @ → 185.199.109.153
    @ → 185.199.110.153
    @ → 185.199.111.153
  CNAME 레코드:
    www → shimyup.github.io
```

### 옵션 B — Cloudflare Pages (무료, 즉시, 더 빠름)
1. cloudflare.com → Pages → Connect to Git
2. lettergo 리포 선택, Build command 비움, Output `/docs`
3. Custom domain → thiscount.io 추가 (Cloudflare DNS 자동 설정)

### 옵션 C — Vercel (무료, 즉시)
1. vercel.com → New Project → lettergo 리포
2. Framework: Other, Output Directory: `docs`
3. Add domain → thiscount.io

---

## 3. DNS 설정 (Namecheap 가정)

도메인 구매: thiscount.io @ Namecheap (May 2026~)

Advanced DNS 설정:
```
Type    Host  Value                              TTL
A       @     185.199.108.153                    Auto
A       @     185.199.109.153                    Auto
A       @     185.199.110.153                    Auto
A       @     185.199.111.153                    Auto
CNAME   www   shimyup.github.io                  Auto
```

전파 시간: 5분~1시간

확인:
```bash
dig thiscount.io
curl -I https://thiscount.io/privacy.html  # 200 OK 확인
```

---

## 4. 검증 체크리스트

```
✅ 페이지 라이브
  [ ] https://thiscount.io/privacy.html → 200 OK + 한국어 콘텐츠 렌더링
  [ ] https://thiscount.io/terms.html → 200 OK
  [ ] https://thiscount.io/support.html → 200 OK
  [ ] HTTPS 인증서 유효 (브라우저 자물쇠 표시)

✅ 다국어
  [ ] privacy/terms 의 한↔영 toggle 동작
  [ ] mobile 반응형 (320px ~ 1280px)

✅ App 내부 link
  [ ] lib/core/config/app_links.dart 의 URL 일치
  [ ] Settings 화면 "개인정보 처리방침" 탭 → 외부 브라우저 → 페이지 정상 로드
  [ ] Auth 화면 약관 동의 텍스트 → 페이지 정상 로드

✅ App Store Connect 등록
  [ ] Privacy Policy URL 입력: https://thiscount.io/privacy.html
  [ ] Support URL: https://thiscount.io/support.html
  [ ] Marketing URL: https://thiscount.io
```

---

## 5. 제출 직전 fallback

도메인 배포가 launch 일까지 안 되면:
- App Store Connect에 임시로 `https://shimyup.github.io/lettergo/privacy.html` 등록
- Submit 후 도메인 배포 완료되면 메타데이터 업데이트 (re-submit 불필요)

---

## 6. 모니터링

launch 후:
- UptimeRobot 또는 Cloudflare Health Check 으로 5분마다 200 OK 확인
- 페이지 down 시 Slack/email 알림
