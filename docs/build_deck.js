const pptxgen = require("pptxgenjs");
const p = new pptxgen();
p.layout = "LAYOUT_WIDE"; // 13.3 x 7.5
p.author = "Thiscount";
p.title = "Thiscount 사업기획서";

const W = 13.3, H = 7.5;
const BG = "0B0E11", CARD = "171B21", CARD2 = "1F242C";
const GOLD = "FFD60A", LIME = "B8FF5C", CORAL = "FF4D6D", BLUE = "5BA4F6", PURPLE = "C77DFF";
const WHITE = "FFFFFF", MUTED = "9AA0A6", FAINT = "6B7280";
const FONT = "Malgun Gothic";

function bg(s) { s.background = { color: BG }; }
function kicker(s, t, c = GOLD) {
  s.addText(t.toUpperCase(), { x: 0.7, y: 0.55, w: 11.9, h: 0.35, fontFace: FONT, fontSize: 12, bold: true, color: c, charSpacing: 3 });
}
function title(s, t) {
  s.addText(t, { x: 0.7, y: 0.9, w: 11.9, h: 0.9, fontFace: FONT, fontSize: 34, bold: true, color: WHITE });
}
function card(s, x, y, w, h, fill = CARD) {
  s.addShape(p.shapes.ROUNDED_RECTANGLE, { x, y, w, h, fill: { color: fill }, line: { type: "none" }, rectRadius: 0.12,
    shadow: { type: "outer", color: "000000", blur: 10, offset: 3, angle: 135, opacity: 0.35 } });
}
function dot(s, x, y, c, d = 0.34) { s.addShape(p.shapes.OVAL, { x, y, w: d, h: d, fill: { color: c }, line: { type: "none" } }); }

// ── S1 표지 ─────────────────────────────────────────
let s = p.addSlide(); bg(s);
[ [CORAL,1.0],[LIME,1.7],[GOLD,2.4],[BLUE,3.1],[PURPLE,3.8] ].forEach(([c,x]) => dot(s, x, 1.5, c, 0.5));
s.addText("Thiscount", { x: 0.9, y: 2.5, w: 11.5, h: 1.3, fontFace: FONT, fontSize: 72, bold: true, color: GOLD });
s.addText("내 주변 혜택을 '줍는' 위치기반 쿠폰 플랫폼", { x: 0.95, y: 3.85, w: 11.5, h: 0.7, fontFace: FONT, fontSize: 26, bold: true, color: WHITE });
s.addText("Pick up coupons and discounts around you", { x: 0.95, y: 4.5, w: 11.5, h: 0.5, fontFace: FONT, fontSize: 15, italic: true, color: MUTED });
s.addText("사업기획서  ·  2026  ·  글로벌 14개 언어  ·  iOS TestFlight 운영 중", { x: 0.95, y: 6.4, w: 11.5, h: 0.4, fontFace: FONT, fontSize: 13, color: FAINT });

// ── S2 문제 ─────────────────────────────────────────
s = p.addSlide(); bg(s); kicker(s, "Problem", CORAL); title(s, "혜택은 넘치는데, 닿지 않는다");
const probs = [
  [CORAL, "전단지·문자 광고", "도달률이 낮고 받는 즉시 버려진다. 비용 대비 전환 추적이 사실상 불가능."],
  [GOLD, "기존 쿠폰 앱", "사용자가 '검색'해야 보인다. 우연한 발견·재방문 동기가 약하다."],
  [BLUE, "소상공인 ROI", "광고비를 써도 누가 보고 실제 방문·사용했는지 모른다 = 깜깜이 집행."],
];
probs.forEach((pr, i) => {
  const y = 2.0 + i * 1.65;
  card(s, 0.7, y, 11.9, 1.45);
  dot(s, 1.05, y + 0.55, pr[0], 0.36);
  s.addText(pr[1], { x: 1.7, y: y + 0.22, w: 4.0, h: 0.5, fontFace: FONT, fontSize: 19, bold: true, color: WHITE, valign: "middle" });
  s.addText(pr[2], { x: 5.7, y: y + 0.2, w: 6.6, h: 1.05, fontFace: FONT, fontSize: 15, color: MUTED, valign: "middle" });
});

// ── S3 솔루션 ─────────────────────────────────────────
s = p.addSlide(); bg(s); kicker(s, "Solution", LIME); title(s, "지도에서 '줍는' 쿠폰");
s.addText("검색이 아니라 발견. 위치 기반으로 주변 혜택이 지도 위에 떨어지고, 줍는 행위 자체가 재미가 된다.",
  { x: 0.7, y: 1.85, w: 11.9, h: 0.6, fontFace: FONT, fontSize: 16, color: MUTED });
const sol = [
  [LIME, "발견의 재미", "지도 위 카테고리별 쿠폰 핀. 가까이 가면 줍는 게임 같은 경험."],
  [GOLD, "위치 기반 도달", "매장 반경에 들어온 사용자에게 자동 드롭 — 전단지보다 정확."],
  [PURPLE, "게임화 리텐션", "레어 드롭·수집·성장으로 매일 열게 만드는 습관 루프."],
];
sol.forEach((c, i) => {
  const x = 0.7 + i * 4.07;
  card(s, x, 2.7, 3.77, 3.6);
  dot(s, x + 0.45, 3.1, c[0], 0.5);
  s.addText(c[1], { x: x + 0.4, y: 3.85, w: 3.0, h: 0.5, fontFace: FONT, fontSize: 20, bold: true, color: WHITE });
  s.addText(c[2], { x: x + 0.4, y: 4.45, w: 3.0, h: 1.6, fontFace: FONT, fontSize: 15, color: MUTED });
});

// ── S4 작동 방식 ─────────────────────────────────────────
s = p.addSlide(); bg(s); kicker(s, "How it works", BLUE); title(s, "줍기 → 발송 → 사용, 3단계");
const steps = [
  [CORAL, "1", "줍기", "사용자가 주변 지도에서 쿠폰·편지를 발견하고 픽업한다."],
  [GOLD, "2", "발송", "매장이 캠페인을 보내거나 매장 반경 '자동발송 zone'을 설정한다."],
  [LIME, "3", "사용", "매장에서 코드·QR로 리딤. 발송→픽업→사용이 모두 측정된다."],
];
steps.forEach((st, i) => {
  const x = 0.7 + i * 4.07;
  card(s, x, 2.5, 3.77, 3.5);
  s.addShape(p.shapes.OVAL, { x: x + 0.4, y: 2.9, w: 0.85, h: 0.85, fill: { color: st[0] }, line: { type: "none" } });
  s.addText(st[1], { x: x + 0.4, y: 2.9, w: 0.85, h: 0.85, fontFace: FONT, fontSize: 30, bold: true, color: "0B0E11", align: "center", valign: "middle" });
  s.addText(st[2], { x: x + 0.4, y: 4.0, w: 3.0, h: 0.5, fontFace: FONT, fontSize: 21, bold: true, color: WHITE });
  s.addText(st[3], { x: x + 0.4, y: 4.6, w: 3.0, h: 1.3, fontFace: FONT, fontSize: 15, color: MUTED });
});

// ── S5 제품 ─────────────────────────────────────────
s = p.addSlide(); bg(s); kicker(s, "Product", GOLD); title(s, "세 개의 핵심 화면");
const prod = [
  [BLUE, "지도 (탐험)", "카테고리별 우편함 마커(할인·교환·브랜드), 레어 드롭 글로우, 근처 알림."],
  [CORAL, "받은함 (지갑)", "쿠폰 티켓형 카드 — 혜택값·절취선·'사용하기'. 사용/만료 상태 일목요연."],
  [LIME, "캠페인 (사장님)", "혜택→대상→확인 3단계 마법사 + 자동발송 zone + AI 글 생성."],
];
prod.forEach((c, i) => {
  const x = 0.7 + i * 4.07;
  card(s, x, 2.4, 3.77, 3.8, CARD);
  s.addShape(p.shapes.ROUNDED_RECTANGLE, { x: x, y: 2.4, w: 3.77, h: 0.16, fill: { color: c[0] }, line: { type: "none" }, rectRadius: 0.05 });
  s.addText(c[1], { x: x + 0.4, y: 2.85, w: 3.0, h: 0.5, fontFace: FONT, fontSize: 19, bold: true, color: c[0] });
  s.addText(c[2], { x: x + 0.4, y: 3.5, w: 3.0, h: 2.4, fontFace: FONT, fontSize: 15, color: MUTED });
});

// ── S6 리텐션 엔진 ─────────────────────────────────────────
s = p.addSlide(); bg(s); kicker(s, "Retention", PURPLE); title(s, "매일 열게 만드는 리텐션 엔진");
const ret = [
  [PURPLE, "레어 드롭", "일반/레어/에픽 등급. 희귀 쿠폰의 짜릿함이 탐색을 유도."],
  [GOLD, "타워 성장", "활동으로 자라는 나만의 타워 — 장기 목표·정체성."],
  [CORAL, "단골 스탬프", "국가·매장별 스탬프 수집. 완성 시 보상 쿠폰."],
  [LIME, "XP · 레벨", "줍기·발송·이동거리로 XP 적립, 레벨·칭호 상승."],
];
ret.forEach((c, i) => {
  const x = 0.7 + (i % 2) * 6.05, y = 2.3 + Math.floor(i / 2) * 2.1;
  card(s, x, y, 5.75, 1.85);
  dot(s, x + 0.4, y + 0.45, c[0], 0.42);
  s.addText(c[1], { x: x + 1.05, y: y + 0.3, w: 4.4, h: 0.5, fontFace: FONT, fontSize: 18, bold: true, color: WHITE });
  s.addText(c[2], { x: x + 1.05, y: y + 0.85, w: 4.4, h: 0.85, fontFace: FONT, fontSize: 14, color: MUTED });
});

// ── S7 매장 가치 ─────────────────────────────────────────
s = p.addSlide(); bg(s); kicker(s, "For Merchants", CORAL); title(s, "소상공인을 위한 측정 가능한 광고");
const mer = [
  [GOLD, "자동발송 zone", "매장 반경을 설정하면 들어온 손님에게 자동으로 쿠폰 드롭."],
  [BLUE, "ROI 퍼널", "발송 → 픽업 → 노출 → 사용까지 단계별 전환율을 한 화면에."],
  [PURPLE, "AI 쿠폰 생성", "업종·목표만 입력하면 카피·혜택 초안을 AI가 자동 작성."],
  [LIME, "매장 POS 코드", "캠페인당 코드 1개로 매장에서 즉시 리딤·정산."],
];
mer.forEach((c, i) => {
  const x = 0.7 + (i % 2) * 6.05, y = 2.3 + Math.floor(i / 2) * 2.1;
  card(s, x, y, 5.75, 1.85);
  dot(s, x + 0.4, y + 0.45, c[0], 0.42);
  s.addText(c[1], { x: x + 1.05, y: y + 0.3, w: 4.4, h: 0.5, fontFace: FONT, fontSize: 18, bold: true, color: WHITE });
  s.addText(c[2], { x: x + 1.05, y: y + 0.85, w: 4.4, h: 0.85, fontFace: FONT, fontSize: 14, color: MUTED });
});

// ── S8 AI 차별화 ─────────────────────────────────────────
s = p.addSlide(); bg(s); kicker(s, "AI Edge", PURPLE); title(s, "진짜 AI를 탑재한 쿠폰 생성");
card(s, 0.7, 2.2, 7.0, 4.1);
s.addText("generateCoupon", { x: 1.1, y: 2.55, w: 6.2, h: 0.5, fontFace: FONT, fontSize: 20, bold: true, color: PURPLE });
s.addText([
  { text: "서버(Cloud Function)에서 Google Gemini 2.5 Flash 호출", options: { bullet: true, breakLine: true, color: WHITE } },
  { text: "업종·설명 입력 → 카피 + 혜택 초안 자동 생성", options: { bullet: true, breakLine: true, color: WHITE } },
  { text: "ID 토큰 검증 + per-uid rate limit + 키 서버 보관(클라 비노출)", options: { bullet: true, breakLine: true, color: MUTED } },
  { text: "엔드투엔드 배포·검증 완료", options: { bullet: true, color: MUTED } },
], { x: 1.1, y: 3.2, w: 6.2, h: 2.9, fontFace: FONT, fontSize: 15.5, lineSpacingMultiple: 1.25 });
card(s, 7.9, 2.2, 4.7, 4.1, CARD2);
s.addText("지원사업 레버", { x: 8.25, y: 2.55, w: 4.0, h: 0.5, fontFace: FONT, fontSize: 18, bold: true, color: GOLD });
s.addText([
  { text: "AI 바우처 / TIPS 등 R&D·창업 지원 연계 포인트", options: { bullet: true, breakLine: true } },
  { text: "휴리스틱 추천 → 생성형 AI로 진화하는 로드맵", options: { bullet: true, breakLine: true } },
  { text: "데이터 축적 시 추천·타게팅 고도화 여지", options: { bullet: true } },
], { x: 8.25, y: 3.2, w: 4.0, h: 2.9, fontFace: FONT, fontSize: 14.5, color: WHITE, lineSpacingMultiple: 1.25 });

// ── S9 수익 모델 ─────────────────────────────────────────
s = p.addSlide(); bg(s); kicker(s, "Business Model", GOLD); title(s, "구독 + 향후 거래 수수료");
const plans = [
  [MUTED, "Free", "₩0", ["기본 줍기 반경", "쿠폰 수집·지도 탐험"]],
  [GOLD, "Premium", "₩4,900 / 월", ["넓은 반경 2km", "특급 발송 · 무제한 수집", "답장·DM"]],
  [CORAL, "Brand", "₩99,000 / 월", ["캠페인 발송", "자동발송 zone · AI 생성", "ROI 대시보드"]],
];
plans.forEach((pl, i) => {
  const x = 0.7 + i * 4.07;
  const featured = i === 1;
  card(s, x, 2.3, 3.77, 3.9, featured ? CARD2 : CARD);
  if (featured) s.addShape(p.shapes.ROUNDED_RECTANGLE, { x, y: 2.3, w: 3.77, h: 3.9, fill: { type: "none" }, line: { color: GOLD, width: 2 }, rectRadius: 0.12 });
  s.addText(pl[1], { x: x + 0.4, y: 2.65, w: 3.0, h: 0.5, fontFace: FONT, fontSize: 18, bold: true, color: pl[0] });
  s.addText(pl[2], { x: x + 0.4, y: 3.2, w: 3.2, h: 0.7, fontFace: FONT, fontSize: 26, bold: true, color: WHITE });
  s.addText(pl[3].map((f, j) => ({ text: f, options: { bullet: true, breakLine: j < pl[3].length - 1, color: MUTED } })),
    { x: x + 0.4, y: 4.1, w: 3.0, h: 2.0, fontFace: FONT, fontSize: 14, lineSpacingMultiple: 1.2 });
});
s.addText("향후: 매장 거래 수수료 · 프로모션 부스트 · 데이터/광고 인사이트", { x: 0.7, y: 6.45, w: 11.9, h: 0.4, fontFace: FONT, fontSize: 13, italic: true, color: MUTED });

// ── S10 시장 ─────────────────────────────────────────
s = p.addSlide(); bg(s); kicker(s, "Market", LIME); title(s, "위치 기반 로컬 커머스 시장");
const mk = [
  [BLUE, "TAM", "국내 O2O·로컬 광고 시장", "〈예시 — 실데이터 교체〉"],
  [GOLD, "SAM", "소상공인 디지털 쿠폰/판촉", "〈예시 — 실데이터 교체〉"],
  [CORAL, "SOM", "초기 타깃 지역·업종 도달", "〈예시 — 실데이터 교체〉"],
];
mk.forEach((m, i) => {
  const x = 0.7 + i * 4.07;
  card(s, x, 2.4, 3.77, 3.5);
  s.addText(m[1], { x: x + 0.4, y: 2.75, w: 3.0, h: 0.6, fontFace: FONT, fontSize: 30, bold: true, color: m[0] });
  s.addText(m[2], { x: x + 0.4, y: 3.55, w: 3.0, h: 0.9, fontFace: FONT, fontSize: 15, bold: true, color: WHITE });
  s.addText(m[3], { x: x + 0.4, y: 4.5, w: 3.0, h: 0.8, fontFace: FONT, fontSize: 13, italic: true, color: GOLD });
});
s.addText("※ 시장 규모 수치는 실제 리서치(통계청·업계 리포트)로 교체하세요.", { x: 0.7, y: 6.4, w: 11.9, h: 0.4, fontFace: FONT, fontSize: 12, italic: true, color: MUTED });

// ── S11 경쟁 우위 ─────────────────────────────────────────
s = p.addSlide(); bg(s); kicker(s, "Why we win", GOLD); title(s, "경쟁 우위");
const rows = [
  ["", "Thiscount", "기존 쿠폰앱", "지역 광고"],
  ["발견성(우연한 픽업)", "강함", "약함", "약함"],
  ["게임화·리텐션", "강함", "보통", "없음"],
  ["AI 쿠폰 생성", "내장", "없음", "없음"],
  ["발송→사용 ROI 측정", "전 구간", "부분", "불투명"],
  ["글로벌 14개 언어", "지원", "제한", "제한"],
];
const colX = [0.7, 5.2, 8.0, 10.5], colW = [4.4, 2.7, 2.4, 2.1];
const rowH = 0.72, top = 2.2;
rows.forEach((r, ri) => {
  const y = top + ri * rowH;
  if (ri === 0) s.addShape(p.shapes.ROUNDED_RECTANGLE, { x: 0.7, y, w: 11.9, h: rowH, fill: { color: CARD2 }, line: { type: "none" }, rectRadius: 0.06 });
  else if (ri % 2 === 1) s.addShape(p.shapes.RECTANGLE, { x: 0.7, y, w: 11.9, h: rowH, fill: { color: CARD, transparency: 30 }, line: { type: "none" } });
  r.forEach((cell, ci) => {
    const isHead = ri === 0, isThis = ci === 1;
    s.addText(cell, { x: colX[ci], y, w: colW[ci], h: rowH, margin: 6, fontFace: FONT,
      fontSize: isHead ? 15 : 14, bold: isHead || ci === 0 || isThis,
      color: isHead ? (isThis ? GOLD : WHITE) : (ci === 0 ? WHITE : (isThis ? LIME : MUTED)),
      align: ci === 0 ? "left" : "center", valign: "middle" });
  });
});

// ── S12 기술·보안 ─────────────────────────────────────────
s = p.addSlide(); bg(s); kicker(s, "Tech & Trust", BLUE); title(s, "검증된 기술·보안·컴플라이언스");
const tech = [
  [BLUE, "기술 스택", "Flutter(iOS/Android) · Firebase · RevenueCat · Cloud Functions · Gemini"],
  [LIME, "글로벌화", "14개 언어 현지화 — 첫인상 동선까지 다국어"],
  [GOLD, "보안", "토큰 보안저장 · 로그인/OTP brute-force 방어 · 익명화·좌표 마스킹 · 출시 전 보안 감사"],
  [CORAL, "컴플라이언스", "정보통신망법(마케팅 동의) · 위치정보법 · GDPR 동의/철회 — 다국어 동의 UI"],
];
tech.forEach((c, i) => {
  const y = 2.2 + i * 1.1;
  card(s, 0.7, y, 11.9, 0.95);
  dot(s, 1.05, y + 0.3, c[0], 0.36);
  s.addText(c[1], { x: 1.65, y, w: 2.7, h: 0.95, fontFace: FONT, fontSize: 16, bold: true, color: WHITE, valign: "middle" });
  s.addText(c[2], { x: 4.4, y, w: 8.0, h: 0.95, fontFace: FONT, fontSize: 14, color: MUTED, valign: "middle" });
});

// ── S13 로드맵 ─────────────────────────────────────────
s = p.addSlide(); bg(s); kicker(s, "Roadmap", LIME); title(s, "출시 → 고도화 → 확장");
const road = [
  [LIME, "현재", "iOS TestFlight 운영. 출시 게이트 마무리(문서 호스팅·IAP·신고)."],
  [GOLD, "Phase 2", "엔티tlement 서버화 · 결제 webhook · 리딤코드 보안 강화."],
  [BLUE, "Phase 3", "정식 인증 마이그레이션(IDOR 근본 해소) · 권한 모델 강화."],
  [PURPLE, "확장", "Android 출시 · 다지역 글로벌 · 추천/타게팅 AI 고도화."],
];
road.forEach((r, i) => {
  const x = 0.7 + i * 3.05;
  s.addShape(p.shapes.OVAL, { x: x + 0.05, y: 2.6, w: 0.55, h: 0.55, fill: { color: r[0] }, line: { type: "none" } });
  if (i < 3) s.addShape(p.shapes.LINE, { x: x + 0.6, y: 2.875, w: 2.45, h: 0, line: { color: FAINT, width: 1.5, dashType: "dash" } });
  s.addText(r[1], { x: x, y: 3.35, w: 2.8, h: 0.5, fontFace: FONT, fontSize: 18, bold: true, color: r[0] });
  s.addText(r[2], { x: x, y: 3.9, w: 2.75, h: 2.2, fontFace: FONT, fontSize: 14, color: MUTED });
});

// ── S14 요청/마무리 ─────────────────────────────────────────
s = p.addSlide(); bg(s);
[ [CORAL,1.0],[LIME,1.7],[GOLD,2.4],[BLUE,3.1],[PURPLE,3.8] ].forEach(([c,x]) => dot(s, x, 1.4, c, 0.45));
s.addText("함께 '줍는' 시장을 만듭니다", { x: 0.9, y: 2.4, w: 11.5, h: 1.0, fontFace: FONT, fontSize: 44, bold: true, color: WHITE });
s.addText("투자 · 지원사업 · 파트너십을 제안합니다.", { x: 0.95, y: 3.55, w: 11.5, h: 0.6, fontFace: FONT, fontSize: 20, color: GOLD });
s.addText([
  { text: "팀 소개 〈입력 필요〉", options: { bullet: true, breakLine: true } },
  { text: "자금 사용 계획 〈입력 필요〉", options: { bullet: true, breakLine: true } },
  { text: "연락처 / thiscount.io 〈입력 필요〉", options: { bullet: true } },
], { x: 0.95, y: 4.4, w: 11.5, h: 1.7, fontFace: FONT, fontSize: 15, color: MUTED, lineSpacingMultiple: 1.3 });

p.writeFile({ fileName: "docs/Thiscount_사업기획서.pptx" }).then(f => console.log("WROTE", f));
