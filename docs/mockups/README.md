# Thiscount — 트렌디 리디자인 UI 목업 (2026-06-06)

다크테마 모바일(393×852pt) 5개 화면 고해상도 목업. 1179×2556px(@3x) PNG.
설계도: [DESIGN_CRITIQUE_TRENDY.md](../DESIGN_CRITIQUE_TRENDY.md). 액센트 3색 고정(gold=Premium / teal=Free·긍정 / coupon=Brand·긴급·만료).
소스 HTML/CSS: `src/`. 렌더: Chrome headless `--force-device-scale-factor=3`.

| # | 화면 | PNG | 개선 전 | 핵심 변경 |
|---|---|---|---|---|
| 1 | 수집첩(인박스) | `1_inbox.png` | `/tmp/s428_inbox.png` | 상단 막대 6개→만료 사이렌 1개(진행바는 헤더 흡수). letter 카드를 당근식 자기설명형으로: 업종 이모지 썸네일 + 매장명·업종 + **혜택 굵게** + D-N 만료 배지 + 코드 칩. rare 카드 골드 글로우. |
| 2 | 프로필 | `2_profile.png` | `/tmp/s428_profile3.png` | 아바타-타이틀 겹침 제거. 히어로 1블록(아바타+이름+티어+🔥연속). 토스식 단일 "이번 달 활동" 카드(큰 숫자=줍기 + 보조 grid 사용·연속일·방문). 레벨 진행바 1개. 지표 분산 해소. |
| 3 | 지도(탐험) | `3_map.png` | `/tmp/s428_home.png` | Pokémon GO 식. 사용자 반경 원(Free teal 200m), 업종 이모지 핀 마커, rare 골드/epic 퍼플 글로우. 상단 근접 방향·거리 칩(☕ 80m 북동), 깨진이미지 시트 제거. 하단 3탭. |
| 4 | Premium 페이월 | `4_paywall.png` | `/tmp/s428_i8.png` | Free 200m vs Premium 1km 반경을 지도 동심원 2개로 시각화(전환 셀링). 혜택 4행(반경/쿨다운/DM/커스텀) + 단일 CTA. **줍기 부스터** 포지셔닝(발송 문구 없음). |
| 5 | 온보딩 1화면 | `5_onboarding.png` | `/tmp/r433_1.png` | 줍기 컨셉 1화면: 반경 링 + 떠다니는 업종 쿠폰 핀 일러스트 + 큰 타이포("내 주변 혜택을 **주워** 담으세요") + 단일 CTA. |

## 전역 디자인 토큰
- 배경 #0A0A0C, surface 한 톤 위(#17171E), radius 20, soft shadow(0 4 16 / black .25).
- 핵심 숫자 32~54pt 800, 라벨 11pt uppercase muted. 위계 또렷.
- 여백 +20%(카드 padding 15~20, 카드 간 13~16). 액센트 절제.

> 오리지널 디자인 — 특정 앱 UI 복제 없이 패턴/원칙만 참조.
