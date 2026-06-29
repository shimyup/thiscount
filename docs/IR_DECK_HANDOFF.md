# IR 발표자료 작업 핸드오프 (새 창 진입점)

> 이 저장소(`/Users/shimyup/Documents/New project/Lettergo`)에서 **새 Claude Code
> 창**을 열고 아래 한 줄만 입력하면 IR PPT 작업이 이어진다:
>
> **"docs/IR_DECK_HANDOFF.md 읽고 IR 발표자료(PPT) 작업 이어서 진행"**

---

## 현재 상태 (2026-06-04)
- ✅ IR 슬라이드 콘텐츠 완성: **`docs/IR_DECK_CONTENT.md`** (한국어, 15장, 슬라이드별 스크립트 + 톤/디자인 가이드 + 클로드 챗 프롬프트)
- ✅ **실제 `.pptx` 생성 완료**: **`docs/Thiscount_IR_Deck_KO.pptx`** (16:9, 15장, 딥블랙+라임그린+골드 다크 테마, 한국어)
  - 생성 스크립트: `docs/ir_deck_build/build_deck.js` (pptxgenjs + react-icons). 수정 시 `NODE_PATH="$(npm root -g)" node build_deck.js` 로 재생성.
  - 플레이스홀더(`[투자금액]`·`[팀]`·`[시장규모]`·[베타지표])는 **대괄호 그대로 유지** (사용자 요청). 슬라이드 8/11/14 에 위치.
  - 폰트: Apple SD Gothic Neo (macOS 네이티브). 시각 QA 통과 (카드 클리핑/제목 em-dash 미렌더/캡션 italic 스크립트폰트 3건 수정 완료).
- ⏳ 미진행: 플레이스홀더 실데이터 교체 · 영문(EN) 버전 · 3분 피치 스크립트
- 앱 정체성: **Thiscount** — 위치기반 발견형 쿠폰 플랫폼("포켓몬 고 × 쿠폰"), Flutter, Firebase/RevenueCat/Gemini AI, 14개 언어, 출시 전 TestFlight 베타(Build 424)

## 다음 작업 후보 (사용자가 고르면 진행)
1. **`.pptx` 실제 생성** — `pptx` 스킬 사용. 소스: `docs/IR_DECK_CONTENT.md` 의 1~15 슬라이드.
   - 디자인: 딥블랙(#0B0B0D) 배경 + 라임그린(#B8FF5C) 강조 + 골드(#FFD60A) 포인트, 16:9, 한 슬라이드=한 메시지.
   - 결과물은 `docs/` 또는 사용자 지정 경로에 저장.
2. **플레이스홀더 채우기** — `[투자금액]`·`[팀]`·`[시장규모/출처]`·`[베타 지표]` 등 실데이터로 교체(사용자에게 질문해서 수집).
3. **영문 버전** — 외국 투자자용 슬라이드 번역(EN).
4. **3분 피치 스크립트** — 발표 대본(슬라이드별 말하기 문장).

## ⚠️ 정직성 원칙 (반드시 지킬 것)
- 앱은 **출시 전 베타** → 실사용/매출 지표 없음. 현황·재무 슬라이드의 수치는 **목표/추정으로 명시**(허위 지표 금지).
- 시장 규모는 **출처 있는 수치**로만. 모르면 플레이스홀더 유지.

## 참고 — 앱 핵심 셀링포인트 (콘텐츠 근거)
- 양면 시장: 소비자(줍는 재미·게이미피케이션) + 매장(측정 가능한 방문 광고).
- 해자: 발견형 UX / 오프라인 전환 측정 / AI 30초 온보딩 / 레벨·희귀도 리텐션.
- 기술: 200m 픽업·좌표 마스킹·SecureClock, Firebase Functions, RevenueCat, Gemini 2.5 Flash.
- 상세 기능 근거가 더 필요하면 메인 핸드오프 `docs/ITERATION_HANDOFF.md` 및 앱 코드(`lib/features/**`) 참조.

## 주의
- 이 작업은 **앱 코드 수정과 무관** — IR 문서/PPT 산출물만 다룬다. 코드 빌드 루프(ITERATION_HANDOFF.md)와 별개.
