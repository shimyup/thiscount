const pptxgen = require("pptxgenjs");
const React = require("react");
const ReactDOMServer = require("react-dom/server");
const sharp = require("sharp");
const Fa = require("react-icons/fa");
const Md = require("react-icons/md");

// ---------- palette ----------
const BG = "0B0B0D";       // deep black
const CARD = "17171C";     // dark card
const CARD2 = "202028";    // lighter card
const LIME = "B8FF5C";     // accent
const GOLD = "FFD60A";     // point
const WHITE = "FFFFFF";
const TXT = "ECECEF";      // near-white body
const MUTED = "9A9AA5";    // muted
const LINE = "2E2E36";     // hairline

const HEAD = "Apple SD Gothic Neo";   // macOS native, handles KR + Latin, has bold
const BODY = "Apple SD Gothic Neo";

// ---------- icon rasterizer ----------
function renderIconSvg(Icon, color, size) {
  return ReactDOMServer.renderToStaticMarkup(
    React.createElement(Icon, { color, size: String(size) })
  );
}
async function icon(Icon, color, size = 256) {
  const svg = renderIconSvg(Icon, color, size);
  const buf = await sharp(Buffer.from(svg)).png().toBuffer();
  return "image/png;base64," + buf.toString("base64");
}

async function main() {
  const pres = new pptxgen();
  pres.defineLayout({ name: "W16x9", width: 13.333, height: 7.5 });
  pres.layout = "W16x9";
  pres.author = "Thiscount";
  pres.title = "Thiscount IR Pitch";

  const W = 13.333, H = 7.5;

  // pre-rasterize icons
  const ic = {
    pin: await icon(Fa.FaMapMarkerAlt, "#" + LIME),
    pinD: await icon(Fa.FaMapMarkerAlt, "#" + BG),
    ticket: await icon(Fa.FaTicketAlt, "#" + GOLD),
    game: await icon(Fa.FaGamepad, "#" + LIME),
    bolt: await icon(Fa.FaBolt, "#" + GOLD),
    chart: await icon(Fa.FaChartLine, "#" + LIME),
    chartD: await icon(Fa.FaChartLine, "#" + BG),
    search: await icon(Fa.FaSearch, "#" + MUTED),
    store: await icon(Fa.FaStore, "#" + MUTED),
    globe: await icon(Fa.FaGlobeAsia, "#" + MUTED),
    user: await icon(Fa.FaUserAstronaut, "#" + LIME),
    robot: await icon(Fa.FaRobot, "#" + GOLD),
    trophy: await icon(Fa.FaTrophy, "#" + GOLD),
    crown: await icon(Fa.FaCrown, "#" + LIME),
    shield: await icon(Fa.FaShieldAlt, "#" + LIME),
    server: await icon(Fa.FaServer, "#" + LIME),
    brain: await icon(Fa.FaBrain, "#" + GOLD),
    paper: await icon(Fa.FaPaperPlane, "#" + LIME),
    hand: await icon(Fa.FaHandPointer, "#" + LIME),
    money: await icon(Fa.FaMoneyBillWave, "#" + LIME),
    rocket: await icon(Fa.FaRocket, "#" + LIME),
    users: await icon(Fa.FaUsers, "#" + GOLD),
    layers: await icon(Fa.FaLayerGroup, "#" + LIME),
    route: await icon(Md.MdRoute, "#" + GOLD),
    target: await icon(Fa.FaBullseye, "#" + LIME),
    handshake: await icon(Fa.FaHandshake, "#" + GOLD),
    flag: await icon(Fa.FaFlagCheckered, "#" + LIME),
    diamond: await icon(Fa.FaGem, "#" + GOLD),
    check: await icon(Fa.FaCheckCircle, "#" + LIME),
    lang: await icon(Md.MdTranslate, "#" + LIME),
  };

  // ---------- helpers ----------
  const newSlide = () => { const s = pres.addSlide(); s.background = { color: BG }; return s; };

  function pageFoot(s, n) {
    s.addText("Thiscount", { x: 0.55, y: H - 0.5, w: 3, h: 0.3, fontFace: BODY, fontSize: 9, color: MUTED, align: "left", margin: 0 });
    s.addText(String(n).padStart(2, "0") + " / 15", { x: W - 1.8, y: H - 0.5, w: 1.25, h: 0.3, fontFace: BODY, fontSize: 9, color: MUTED, align: "right", margin: 0 });
  }
  // small kicker label with lime dot
  function kicker(s, text, x = 0.55, y = 0.55) {
    s.addShape(pres.shapes.OVAL, { x, y: y + 0.05, w: 0.12, h: 0.12, fill: { color: LIME } });
    s.addText(text.toUpperCase(), { x: x + 0.22, y, w: 6, h: 0.3, fontFace: BODY, fontSize: 11, color: LIME, bold: true, charSpacing: 2, align: "left", margin: 0 });
  }
  function title(s, text, opts = {}) {
    s.addText(text, Object.assign({ x: 0.55, y: 1.0, w: 12.2, h: 1.1, fontFace: HEAD, fontSize: 38, color: WHITE, bold: true, align: "left", valign: "top", margin: 0 }, opts));
  }
  // rounded card
  function card(s, x, y, w, h, fill = CARD) {
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, fill: { color: fill }, line: { color: LINE, width: 1 }, rectRadius: 0.12 });
  }
  const mkShadow = () => ({ type: "outer", color: "000000", blur: 10, offset: 3, angle: 90, opacity: 0.45 });

  // ===================================================================
  // 1) COVER
  // ===================================================================
  {
    const s = newSlide();
    // faint radial-ish glow using big translucent ovals
    s.addShape(pres.shapes.OVAL, { x: 8.6, y: -1.6, w: 7, h: 7, fill: { color: LIME, transparency: 88 } });
    s.addShape(pres.shapes.OVAL, { x: 9.8, y: 0.2, w: 4.2, h: 4.2, fill: { color: LIME, transparency: 80 } });
    // radius ring + pin motif (right)
    s.addShape(pres.shapes.OVAL, { x: 9.0, y: 1.5, w: 3.6, h: 3.6, fill: { color: BG, transparency: 100 }, line: { color: LIME, width: 1.5, transparency: 40 } });
    s.addShape(pres.shapes.OVAL, { x: 9.9, y: 2.4, w: 1.8, h: 1.8, fill: { color: BG, transparency: 100 }, line: { color: LIME, width: 1.25, transparency: 20 } });
    s.addImage({ data: ic.pin, x: 10.45, y: 2.55, w: 0.7, h: 0.7 });

    kicker(s, "Location-based discovery coupon platform", 0.7, 0.85);
    s.addText("Thiscount", { x: 0.62, y: 2.0, w: 8.5, h: 1.5, fontFace: HEAD, fontSize: 84, color: WHITE, bold: true, align: "left", margin: 0 });
    s.addText([
      { text: "걷다 보면, ", options: { color: WHITE } },
      { text: "혜택이 떨어진다", options: { color: LIME } },
    ], { x: 0.7, y: 3.45, w: 9, h: 0.8, fontFace: HEAD, fontSize: 30, bold: true, align: "left", margin: 0 });
    s.addText("위치기반 발견형 쿠폰 플랫폼  ·  글로벌 14개 언어", { x: 0.7, y: 4.25, w: 9, h: 0.4, fontFace: BODY, fontSize: 15, color: MUTED, align: "left", margin: 0 });

    s.addShape(pres.shapes.LINE, { x: 0.7, y: 5.55, w: 5.2, h: 0, line: { color: LINE, width: 1 } });
    s.addText([
      { text: "[회사명]", options: { color: TXT, bold: true } },
      { text: "   ·   [발표자 / 직함]   ·   [날짜]", options: { color: MUTED } },
    ], { x: 0.7, y: 5.7, w: 8, h: 0.4, fontFace: BODY, fontSize: 13, align: "left", margin: 0 });
    s.addText("IR PITCH", { x: W - 2.4, y: 5.7, w: 1.85, h: 0.4, fontFace: BODY, fontSize: 12, color: LIME, bold: true, charSpacing: 3, align: "right", margin: 0 });
  }

  // ===================================================================
  // 2) WHAT IS — two column
  // ===================================================================
  {
    const s = newSlide();
    kicker(s, "What is Thiscount");
    title(s, [
      { text: "포켓몬 고처럼 ", options: { color: WHITE } },
      { text: "줍는 쿠폰", options: { color: LIME } },
    ], { fontSize: 44 });

    const rows = [
      { ic: ic.hand, t: "걸어가서 줍는다", d: "내 주변 200m 안에 떨어진 브랜드 혜택(할인권·교환권)을 지도에서 발견해 직접 픽업합니다." },
      { ic: ic.ticket, t: "매장에서 바로 쓴다", d: "주운 쿠폰은 매장 코드로 즉시 사용 — 발견이 곧 오프라인 방문으로 이어집니다." },
      { ic: ic.chart, t: "브랜드는 자동으로 뿌린다", d: "매장 반경에 쿠폰을 자동 발송(zone)하고, 실시간으로 방문 ROI를 측정합니다." },
    ];
    let y = 2.5;
    rows.forEach((r) => {
      s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.55, y, w: 0.78, h: 0.78, fill: { color: CARD }, line: { color: LINE, width: 1 }, rectRadius: 0.1 });
      s.addImage({ data: r.ic, x: 0.72, y: y + 0.17, w: 0.44, h: 0.44 });
      s.addText(r.t, { x: 1.6, y: y - 0.02, w: 6.0, h: 0.4, fontFace: HEAD, fontSize: 19, color: WHITE, bold: true, align: "left", margin: 0 });
      s.addText(r.d, { x: 1.6, y: y + 0.38, w: 6.3, h: 0.6, fontFace: BODY, fontSize: 13, color: MUTED, align: "left", valign: "top", margin: 0 });
      y += 1.15;
    });

    // right visual panel
    card(s, 8.5, 2.3, 4.3, 3.9, CARD);
    s.addText("감성 × 실용", { x: 8.5, y: 2.65, w: 4.3, h: 0.4, fontFace: HEAD, fontSize: 20, color: LIME, bold: true, align: "center", margin: 0 });
    s.addShape(pres.shapes.OVAL, { x: 9.55, y: 3.35, w: 2.2, h: 2.2, fill: { color: BG }, line: { color: LIME, width: 1.5, transparency: 30 } });
    s.addImage({ data: ic.pin, x: 10.3, y: 4.05, w: 0.7, h: 0.7 });
    s.addText([
      { text: "발견의 재미", options: { color: WHITE, bold: true, breakLine: true } },
      { text: "+  즉시 사용 가능한 할인", options: { color: MUTED } },
    ], { x: 8.5, y: 5.55, w: 4.3, h: 0.6, fontFace: BODY, fontSize: 14, align: "center", margin: 0 });
    pageFoot(s, 2);
  }

  // ===================================================================
  // 3) PROBLEM — three stacked rows w/ muted icons
  // ===================================================================
  {
    const s = newSlide();
    kicker(s, "Problem");
    title(s, [
      { text: "쿠폰은 넘치는데, ", options: { color: WHITE } },
      { text: "아무도 안 줍는다", options: { color: GOLD } },
    ]);

    const probs = [
      { ic: ic.search, t: "소비자", d: "검색·필터·스팸 푸시 피로. 발견의 재미가 없어 사용률이 낮다." },
      { ic: ic.store, t: "오프라인 매장", d: "전단지·배달앱 광고는 누가 봤는지·왔는지 측정 불가. 비싸고 일회성." },
      { ic: ic.globe, t: "관광 / 로컬", d: "외국인·신규 방문객이 '내 주변 실시간 혜택'을 찾을 채널이 없다." },
    ];
    let y = 2.55;
    probs.forEach((p) => {
      card(s, 0.55, y, 12.25, 1.0);
      s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.85, y: y + 0.2, w: 0.6, h: 0.6, fill: { color: CARD2 }, line: { color: LINE, width: 1 }, rectRadius: 0.1 });
      s.addImage({ data: p.ic, x: 0.97, y: y + 0.32, w: 0.36, h: 0.36 });
      s.addText(p.t, { x: 1.7, y: y + 0.12, w: 3.0, h: 0.8, fontFace: HEAD, fontSize: 20, color: WHITE, bold: true, align: "left", valign: "middle", margin: 0 });
      s.addText(p.d, { x: 4.6, y: y + 0.12, w: 8.0, h: 0.8, fontFace: BODY, fontSize: 14, color: MUTED, align: "left", valign: "middle", margin: 0 });
      y += 1.18;
    });
    s.addText([
      { text: "“노출”은 팔지만 ", options: { color: MUTED } },
      { text: "“방문”은 못 파는", options: { color: GOLD, bold: true } },
      { text: " 광고 시장", options: { color: MUTED } },
    ], { x: 0.55, y: 6.35, w: 12.25, h: 0.4, fontFace: BODY, fontSize: 15, italic: true, align: "center", margin: 0 });
    pageFoot(s, 3);
  }

  // ===================================================================
  // 4) SOLUTION — three cards
  // ===================================================================
  {
    const s = newSlide();
    kicker(s, "Solution");
    title(s, [
      { text: "위치 + 게임 = ", options: { color: WHITE } },
      { text: "실제 매장 방문", options: { color: LIME } },
    ]);

    const cards = [
      { ic: ic.game, t: "줍는 재미", d: "지도 위 발견 · 희귀도(레어/에픽) · 레벨 · 연속출석으로 리텐션 확보." },
      { ic: ic.bolt, t: "즉시 전환", d: "주운 쿠폰은 매장 POS 코드로 바로 사용 → 오프라인 방문에 직결." },
      { ic: ic.chart, t: "측정 가능", d: "발송→픽업→노출→사용 퍼널을 브랜드 실시간 대시보드로 확인." },
    ];
    const cw = 3.95, gap = 0.25, x0 = 0.55, cy = 2.55, ch = 3.5;
    cards.forEach((c, i) => {
      const x = x0 + i * (cw + gap);
      card(s, x, cy, cw, ch);
      s.addShape(pres.shapes.RECTANGLE, { x, y: cy, w: cw, h: 0.1, fill: { color: i === 1 ? GOLD : LIME } });
      s.addShape(pres.shapes.OVAL, { x: x + 0.35, y: cy + 0.45, w: 0.95, h: 0.95, fill: { color: CARD2 }, line: { color: i === 1 ? GOLD : LIME, width: 1.25 } });
      s.addImage({ data: c.ic, x: x + 0.6, y: cy + 0.7, w: 0.45, h: 0.45 });
      s.addText(c.t, { x: x + 0.35, y: cy + 1.6, w: cw - 0.7, h: 0.5, fontFace: HEAD, fontSize: 24, color: WHITE, bold: true, align: "left", margin: 0 });
      s.addText(c.d, { x: x + 0.35, y: cy + 2.2, w: cw - 0.7, h: 1.1, fontFace: BODY, fontSize: 14, color: MUTED, align: "left", valign: "top", margin: 0 });
    });
    s.addText("광고비를 “방문 · 사용”이라는 결과로 전환", { x: 0.55, y: 6.3, w: 12.25, h: 0.4, fontFace: BODY, fontSize: 15, italic: true, color: LIME, align: "center", margin: 0 });
    pageFoot(s, 4);
  }

  // ===================================================================
  // 5) HOW IT WORKS — 3-step horizontal flow
  // ===================================================================
  {
    const s = newSlide();
    kicker(s, "How it works");
    title(s, "발송 → 픽업 → 사용, 한 흐름");

    const steps = [
      { n: "1", ic: ic.paper, t: "브랜드 발송", d: "쿠폰 발송 / 매장 zone 설정\n(AI가 카피 자동 생성)" },
      { n: "2", ic: ic.hand, t: "사용자 픽업", d: "지도에서 발견 →\n200m 안으로 걸어가 픽업" },
      { n: "3", ic: ic.ticket, t: "매장 사용", d: "코드 제시 → 사용 →\n브랜드 ROI에 집계" },
    ];
    const cw = 3.7, gap = 0.85, x0 = 0.75, cy = 2.75, ch = 3.1;
    steps.forEach((st, i) => {
      const x = x0 + i * (cw + gap);
      card(s, x, cy, cw, ch);
      s.addShape(pres.shapes.OVAL, { x: x + cw / 2 - 0.45, y: cy - 0.45, w: 0.9, h: 0.9, fill: { color: LIME } });
      s.addText(st.n, { x: x + cw / 2 - 0.45, y: cy - 0.45, w: 0.9, h: 0.9, fontFace: HEAD, fontSize: 30, color: BG, bold: true, align: "center", valign: "middle", margin: 0 });
      s.addImage({ data: st.ic, x: x + cw / 2 - 0.4, y: cy + 0.7, w: 0.8, h: 0.8 });
      s.addText(st.t, { x: x + 0.2, y: cy + 1.65, w: cw - 0.4, h: 0.45, fontFace: HEAD, fontSize: 21, color: WHITE, bold: true, align: "center", margin: 0 });
      s.addText(st.d, { x: x + 0.2, y: cy + 2.15, w: cw - 0.4, h: 0.8, fontFace: BODY, fontSize: 13, color: MUTED, align: "center", valign: "top", margin: 0 });
      // arrow
      if (i < steps.length - 1) {
        s.addText("›", { x: x + cw + 0.05, y: cy + 0.9, w: gap - 0.1, h: 0.9, fontFace: HEAD, fontSize: 40, color: LIME, bold: true, align: "center", valign: "middle", margin: 0 });
      }
    });
    s.addText("발송 → 픽업 → 사용까지 끊김 없는 단일 흐름", { x: 0.55, y: 6.35, w: 12.25, h: 0.4, fontFace: BODY, fontSize: 15, italic: true, color: MUTED, align: "center", margin: 0 });
    pageFoot(s, 5);
  }

  // ===================================================================
  // 6) PRODUCT — 2x2 grid
  // ===================================================================
  {
    const s = newSlide();
    kicker(s, "Product");
    title(s, "양면 시장을 한 앱에서");

    const items = [
      { ic: ic.user, t: "사용자 (헌터)", d: "지도 픽업 · 희귀 드롭 · 레벨/타워 성장 · 수집첩 · 팔로우/DM", c: LIME },
      { ic: ic.chart, t: "브랜드", d: "매장 zone 자동 발송 · ExactDrop 정밀 투하 · 1캠페인=1코드 POS · ROI 퍼널 대시보드", c: LIME },
      { ic: ic.robot, t: "AI", d: "업종·설명 입력 → 쿠폰 카피·혜택 초안 자동 생성 (온보딩 마찰 제거)", c: GOLD },
      { ic: ic.lang, t: "글로벌", d: "14개 언어(아랍어 RTL 포함) · 국가별 현지화", c: LIME },
    ];
    const cw = 6.0, chh = 1.78, gx = 0.55, gy = 2.5, gap = 0.25;
    items.forEach((it, i) => {
      const x = gx + (i % 2) * (cw + gap);
      const y = gy + Math.floor(i / 2) * (chh + gap);
      card(s, x, y, cw, chh);
      s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: x + 0.35, y: y + 0.35, w: 0.85, h: 0.85, fill: { color: CARD2 }, line: { color: it.c, width: 1.25 }, rectRadius: 0.12 });
      s.addImage({ data: it.ic, x: x + 0.57, y: y + 0.57, w: 0.42, h: 0.42 });
      s.addText(it.t, { x: x + 1.45, y: y + 0.32, w: cw - 1.7, h: 0.45, fontFace: HEAD, fontSize: 20, color: it.c, bold: true, align: "left", margin: 0 });
      s.addText(it.d, { x: x + 1.45, y: y + 0.78, w: cw - 1.75, h: 0.85, fontFace: BODY, fontSize: 13.5, color: TXT, align: "left", valign: "top", margin: 0 });
    });
    pageFoot(s, 6);
  }

  // ===================================================================
  // 7) MOAT — 4 icon rows + caption
  // ===================================================================
  {
    const s = newSlide();
    kicker(s, "Why us / Moat");
    title(s, [
      { text: "검색하는 쿠폰이 아니라, ", options: { color: WHITE } },
      { text: "줍는 쿠폰", options: { color: LIME } },
    ]);

    const moats = [
      { ic: ic.game, t: "발견형 UX", d: "검색형 쿠폰앱과 다른 “줍는” 경험 → 높은 인게이지먼트" },
      { ic: ic.target, t: "오프라인 전환 측정", d: "픽업·사용 데이터로 “방문 단가” 광고 상품화 (전단지·배달광고가 못 하는 것)" },
      { ic: ic.robot, t: "AI 온보딩", d: "매장이 30초 만에 캠페인 생성 → 공급(쿠폰) 확보 속도" },
      { ic: ic.trophy, t: "게이미피케이션 리텐션", d: "레벨·희귀도·스트릭으로 재방문 동기 부여" },
    ];
    let y = 2.45;
    moats.forEach((m, i) => {
      s.addShape(pres.shapes.OVAL, { x: 0.6, y, w: 0.7, h: 0.7, fill: { color: CARD }, line: { color: i === 2 ? GOLD : LIME, width: 1.25 } });
      s.addImage({ data: m.ic, x: 0.77, y: y + 0.17, w: 0.36, h: 0.36 });
      s.addText(m.t, { x: 1.55, y: y - 0.02, w: 4.6, h: 0.4, fontFace: HEAD, fontSize: 18, color: WHITE, bold: true, align: "left", margin: 0 });
      s.addText(m.d, { x: 1.55, y: y + 0.36, w: 11.1, h: 0.5, fontFace: BODY, fontSize: 13.5, color: MUTED, align: "left", valign: "top", margin: 0 });
      if (i < moats.length - 1) s.addShape(pres.shapes.LINE, { x: 1.55, y: y + 0.95, w: 11.1, h: 0, line: { color: LINE, width: 1 } });
      y += 1.05;
    });
    s.addText([
      { text: "데이터가 쌓일수록 추천·매칭 정확도 강화 — ", options: { color: MUTED } },
      { text: "네트워크 효과", options: { color: LIME, bold: true } },
    ], { x: 0.55, y: 6.5, w: 12.25, h: 0.35, fontFace: BODY, fontSize: 14, italic: true, align: "center", margin: 0 });
    pageFoot(s, 7);
  }

  // ===================================================================
  // 8) MARKET — TAM/SAM/SOM nested
  // ===================================================================
  {
    const s = newSlide();
    kicker(s, "Market");
    title(s, [
      { text: "노출 광고 → ", options: { color: WHITE } },
      { text: "방문 광고", options: { color: LIME } },
      { text: "로의 진입", options: { color: WHITE } },
    ]);

    // concentric rings
    const cx = 3.55, cyc = 4.35;
    s.addShape(pres.shapes.OVAL, { x: cx - 2.5, y: cyc - 2.5, w: 5.0, h: 5.0, fill: { color: CARD }, line: { color: LINE, width: 1 } });
    s.addShape(pres.shapes.OVAL, { x: cx - 1.7, y: cyc - 1.7, w: 3.4, h: 3.4, fill: { color: CARD2 }, line: { color: LIME, width: 1, transparency: 40 } });
    s.addShape(pres.shapes.OVAL, { x: cx - 0.95, y: cyc - 0.95, w: 1.9, h: 1.9, fill: { color: LIME } });
    s.addText("SOM", { x: cx - 0.95, y: cyc - 0.45, w: 1.9, h: 0.5, fontFace: HEAD, fontSize: 20, color: BG, bold: true, align: "center", margin: 0 });
    s.addText("TAM", { x: cx - 2.5, y: cyc - 2.35, w: 5.0, h: 0.35, fontFace: HEAD, fontSize: 13, color: MUTED, bold: true, align: "center", margin: 0 });
    s.addText("SAM", { x: cx - 1.7, y: cyc - 1.55, w: 3.4, h: 0.35, fontFace: HEAD, fontSize: 13, color: LIME, bold: true, align: "center", margin: 0 });

    // right definitions
    const defs = [
      { k: "TAM", t: "글로벌 디지털 로컬 광고 / 프로모션 시장", v: "[규모 · 출처 채워넣기]", c: MUTED },
      { k: "SAM", t: "위치기반 O2O 프로모션 · 관광 / 로컬 쿠폰", v: "[규모 채워넣기]", c: LIME },
      { k: "SOM", t: "국내 카페·외식·뷰티 소상공인 + 관광 상권 (초기)", v: "[수치 채워넣기]", c: LIME },
    ];
    let y = 2.6;
    defs.forEach((d) => {
      card(s, 6.6, y, 6.2, 1.05);
      s.addText(d.k, { x: 6.85, y: y + 0.16, w: 1.1, h: 0.7, fontFace: HEAD, fontSize: 22, color: d.c, bold: true, align: "left", valign: "middle", margin: 0 });
      s.addText(d.t, { x: 7.95, y: y + 0.15, w: 4.7, h: 0.5, fontFace: BODY, fontSize: 13.5, color: TXT, align: "left", valign: "top", margin: 0 });
      s.addText(d.v, { x: 7.95, y: y + 0.62, w: 4.7, h: 0.35, fontFace: BODY, fontSize: 12, color: GOLD, bold: true, align: "left", margin: 0 });
      y += 1.2;
    });
    s.addText("시장 규모는 출처 있는 수치로 교체 예정 (현재 플레이스홀더)", { x: 6.6, y: 6.45, w: 6.2, h: 0.3, fontFace: BODY, fontSize: 11, italic: true, color: MUTED, align: "left", margin: 0 });
    pageFoot(s, 8);
  }

  // ===================================================================
  // 9) BUSINESS MODEL — 3 columns
  // ===================================================================
  {
    const s = newSlide();
    kicker(s, "Business Model");
    title(s, [
      { text: "양면 수익 — ", options: { color: WHITE } },
      { text: "구독 + 성과형 광고", options: { color: LIME } },
    ]);

    const cols = [
      { ic: ic.crown, t: "구독 (소비자)", items: ["Premium: 픽업 반경 · 쿨다운", "선호 카테고리 · DM", "RevenueCat 결제"], c: LIME },
      { ic: ic.money, t: "브랜드 과금", items: ["ExactDrop 크레딧 (정밀 투하)", "월 발송 쿼터 확장", "캠페인 상품"], c: GOLD },
      { ic: ic.rocket, t: "확장", items: ["AI 쿠폰 생성 프리미엄", "데이터 / 인사이트", "관광청 · 프랜차이즈 제휴"], c: LIME },
    ];
    const cw = 3.95, gap = 0.25, x0 = 0.55, cy = 2.5, ch = 3.35;
    cols.forEach((c, i) => {
      const x = x0 + i * (cw + gap);
      card(s, x, cy, cw, ch);
      s.addShape(pres.shapes.OVAL, { x: x + 0.35, y: cy + 0.35, w: 0.8, h: 0.8, fill: { color: CARD2 }, line: { color: c.c, width: 1.25 } });
      s.addImage({ data: c.ic, x: x + 0.55, y: cy + 0.55, w: 0.4, h: 0.4 });
      s.addText(c.t, { x: x + 1.25, y: cy + 0.4, w: cw - 1.4, h: 0.75, fontFace: HEAD, fontSize: 18, color: c.c, bold: true, align: "left", valign: "middle", margin: 0 });
      s.addText(c.items.map((t, j) => ({ text: t, options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 8, color: TXT } })),
        { x: x + 0.4, y: cy + 1.45, w: cw - 0.75, h: 1.7, fontFace: BODY, fontSize: 13.5, align: "left", valign: "top", margin: 0 });
    });
    s.addText("결제 인프라(구독·크레딧) 구현 완료 — 정식 상품 등록 단계", { x: 0.55, y: 6.25, w: 12.25, h: 0.35, fontFace: BODY, fontSize: 13, italic: true, color: GOLD, align: "center", margin: 0 });
    pageFoot(s, 9);
  }

  // ===================================================================
  // 10) TECHNOLOGY — 4 icon rows
  // ===================================================================
  {
    const s = newSlide();
    kicker(s, "Technology");
    title(s, "출시 가능한 수준의 보안·결제·AI 파이프라인");

    const techs = [
      { ic: ic.pin, t: "위치 / 지도", d: "200m 반경 픽업 · 좌표 마스킹(프라이버시) · 시계 조작 방지(SecureClock)" },
      { ic: ic.server, t: "백엔드", d: "Firebase (Firestore · Cloud Functions · Auth) · RevenueCat 구독" },
      { ic: ic.brain, t: "AI", d: "Google Gemini 2.5 Flash 쿠폰 카피 생성 (서버 시크릿 · rate-limit)" },
      { ic: ic.shield, t: "신뢰 / 보안", d: "GDPR · 위치정보법 / 정보통신망법 동의 체계 · OTP · 차단 · 신고" },
    ];
    const cw = 6.0, chh = 1.78, gx = 0.55, gy = 2.5, gap = 0.25;
    techs.forEach((it, i) => {
      const x = gx + (i % 2) * (cw + gap);
      const y = gy + Math.floor(i / 2) * (chh + gap);
      card(s, x, y, cw, chh);
      s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: x + 0.35, y: y + 0.35, w: 0.85, h: 0.85, fill: { color: CARD2 }, line: { color: i === 2 ? GOLD : LIME, width: 1.25 }, rectRadius: 0.12 });
      s.addImage({ data: it.ic, x: x + 0.57, y: y + 0.57, w: 0.42, h: 0.42 });
      s.addText(it.t, { x: x + 1.45, y: y + 0.32, w: cw - 1.7, h: 0.45, fontFace: HEAD, fontSize: 19, color: WHITE, bold: true, align: "left", margin: 0 });
      s.addText(it.d, { x: x + 1.45, y: y + 0.78, w: cw - 1.75, h: 0.85, fontFace: BODY, fontSize: 13, color: MUTED, align: "left", valign: "top", margin: 0 });
    });
    pageFoot(s, 10);
  }

  // ===================================================================
  // 11) TRACTION — honest
  // ===================================================================
  {
    const s = newSlide();
    kicker(s, "Traction · 정직하게");
    title(s, "기능 완성 → 시장 검증 단계");

    // status callouts (verified facts)
    const facts = [
      { big: "424", small: "TestFlight 베타 Build\n(다수 시뮬레이션·QA 라운드)" },
      { big: "14", small: "지원 언어\n(아랍어 RTL 포함)" },
      { big: "100%", small: "결제·구독·AI·지도·브랜드\nROI 전 기능 동작" },
    ];
    const cw = 3.95, gap = 0.25, x0 = 0.55, cy = 2.45, ch = 1.95;
    facts.forEach((f, i) => {
      const x = x0 + i * (cw + gap);
      card(s, x, cy, cw, ch);
      s.addText(f.big, { x: x + 0.3, y: cy + 0.25, w: cw - 0.6, h: 0.85, fontFace: HEAD, fontSize: 48, color: LIME, bold: true, align: "left", margin: 0 });
      s.addText(f.small, { x: x + 0.32, y: cy + 1.15, w: cw - 0.6, h: 0.7, fontFace: BODY, fontSize: 12.5, color: MUTED, align: "left", valign: "top", margin: 0 });
    });

    // milestones + placeholders
    card(s, 0.55, 4.7, 7.6, 1.95, CARD);
    s.addText("다음 마일스톤", { x: 0.85, y: 4.9, w: 7, h: 0.4, fontFace: HEAD, fontSize: 16, color: WHITE, bold: true, align: "left", margin: 0 });
    s.addText([
      { text: "정식 IAP 상품 등록", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 6 } },
      { text: "위치기반서비스 신고 · 앱스토어 심사", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 6 } },
      { text: "[파일럿 매장 N곳] 확보", options: { bullet: { code: "2022" }, color: GOLD } },
    ], { x: 0.85, y: 5.4, w: 7.0, h: 1.1, fontFace: BODY, fontSize: 13.5, color: TXT, align: "left", valign: "top", margin: 0 });

    card(s, 8.35, 4.7, 4.45, 1.95, CARD);
    s.addText("출시 후 수집 지표", { x: 8.6, y: 4.9, w: 4, h: 0.4, fontFace: HEAD, fontSize: 16, color: GOLD, bold: true, align: "left", margin: 0 });
    s.addText([
      { text: "[베타 테스터 수]", options: { breakLine: true, paraSpaceAfter: 5 } },
      { text: "[파일럿 매장 수]", options: { breakLine: true, paraSpaceAfter: 5 } },
      { text: "[픽업 / 사용 전환율]", options: {} },
    ], { x: 8.6, y: 5.4, w: 4.0, h: 1.1, fontFace: BODY, fontSize: 13.5, color: MUTED, align: "left", valign: "top", margin: 0 });

    s.addText("실사용·매출 지표는 출시 후 — 위 [   ] 항목은 추정·목표로 표기 예정", { x: 0.55, y: 6.85, w: 12.25, h: 0.3, fontFace: BODY, fontSize: 10.5, italic: true, color: MUTED, align: "center", margin: 0 });
    pageFoot(s, 11);
  }

  // ===================================================================
  // 12) GO-TO-MARKET — supply -> demand flow
  // ===================================================================
  {
    const s = newSlide();
    kicker(s, "Go-to-Market");
    title(s, "지역 밀도 → 양면 네트워크 효과 점화");

    const gtm = [
      { ic: ic.store, t: "공급(매장) 먼저", d: "카페·외식·뷰티 밀집 상권 1~2곳 집중 → 쿠폰 밀도 확보", c: LIME },
      { ic: ic.users, t: "수요(사용자)", d: "상권 내 픽업 밀도 → 입소문·지역 마케팅 → 게이미피케이션 리텐션", c: GOLD },
      { ic: ic.handshake, t: "레버", d: "AI 온보딩으로 매장 가입 마찰 최소화 · 관광 상권·프랜차이즈 제휴", c: LIME },
    ];
    let y = 2.55;
    gtm.forEach((g, i) => {
      card(s, 0.55, y, 12.25, 1.2);
      s.addShape(pres.shapes.OVAL, { x: 0.85, y: y + 0.27, w: 0.66, h: 0.66, fill: { color: CARD2 }, line: { color: g.c, width: 1.25 } });
      s.addImage({ data: g.ic, x: 1.0, y: y + 0.42, w: 0.36, h: 0.36 });
      s.addText(g.t, { x: 1.75, y: y + 0.2, w: 3.4, h: 0.8, fontFace: HEAD, fontSize: 19, color: g.c, bold: true, align: "left", valign: "middle", margin: 0 });
      s.addText(g.d, { x: 5.1, y: y + 0.2, w: 7.5, h: 0.8, fontFace: BODY, fontSize: 14, color: TXT, align: "left", valign: "middle", margin: 0 });
      if (i < gtm.length - 1) s.addText("↓", { x: 1.0, y: y + 1.18, w: 0.5, h: 0.3, fontFace: HEAD, fontSize: 16, color: LIME, bold: true, align: "center", margin: 0 });
      y += 1.45;
    });
    pageFoot(s, 12);
  }

  // ===================================================================
  // 13) ROADMAP — timeline
  // ===================================================================
  {
    const s = newSlide();
    kicker(s, "Roadmap");
    title(s, [
      { text: "제품 → 상권 → 도시 → ", options: { color: WHITE } },
      { text: "글로벌", options: { color: LIME } },
    ]);

    const phases = [
      { tag: "NOW", t: "정식 출시", items: ["IAP · 신고 · 심사", "파일럿 상권"], c: LIME },
      { tag: "6개월", t: "고도화", items: ["매장 셀프서비스 대시보드", "AI 추천 임베딩(개인화)", "제휴 확장"], c: GOLD },
      { tag: "12개월", t: "확장", items: ["도시 단위 확장", "데이터 인사이트 상품", "글로벌 관광 상권"], c: LIME },
    ];
    // timeline base line
    s.addShape(pres.shapes.LINE, { x: 1.0, y: 3.05, w: 11.3, h: 0, line: { color: LINE, width: 2 } });
    const cw = 3.85, gap = 0.3, x0 = 0.6, cy = 3.5, ch = 2.9;
    phases.forEach((p, i) => {
      const x = x0 + i * (cw + gap);
      s.addShape(pres.shapes.OVAL, { x: x + cw / 2 - 0.14, y: 2.91, w: 0.28, h: 0.28, fill: { color: p.c } });
      card(s, x, cy, cw, ch);
      s.addText(p.tag, { x: x + 0.35, y: cy + 0.3, w: cw - 0.7, h: 0.4, fontFace: HEAD, fontSize: 15, color: p.c, bold: true, charSpacing: 2, align: "left", margin: 0 });
      s.addText(p.t, { x: x + 0.35, y: cy + 0.72, w: cw - 0.7, h: 0.5, fontFace: HEAD, fontSize: 23, color: WHITE, bold: true, align: "left", margin: 0 });
      s.addText(p.items.map((t) => ({ text: t, options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 7, color: TXT } })),
        { x: x + 0.4, y: cy + 1.4, w: cw - 0.75, h: 1.4, fontFace: BODY, fontSize: 13.5, align: "left", valign: "top", margin: 0 });
    });
    pageFoot(s, 13);
  }

  // ===================================================================
  // 14) TEAM / THE ASK
  // ===================================================================
  {
    const s = newSlide();
    kicker(s, "Team · The Ask");
    title(s, [
      { text: "출시 직전 — 자본은 ", options: { color: WHITE } },
      { text: "상권 점화", options: { color: LIME } },
      { text: "에", options: { color: WHITE } },
    ]);

    // team
    card(s, 0.55, 2.5, 6.0, 4.0, CARD);
    s.addShape(pres.shapes.OVAL, { x: 0.85, y: 2.8, w: 0.7, h: 0.7, fill: { color: CARD2 }, line: { color: LIME, width: 1.25 } });
    s.addImage({ data: ic.users, x: 1.0, y: 2.95, w: 0.4, h: 0.4 });
    s.addText("팀", { x: 1.7, y: 2.85, w: 4, h: 0.6, fontFace: HEAD, fontSize: 22, color: WHITE, bold: true, align: "left", valign: "middle", margin: 0 });
    s.addText([
      { text: "[대표 · 핵심 멤버]", options: { bold: true, color: TXT, breakLine: true, paraSpaceAfter: 10 } },
      { text: "[경력 한 줄씩 채워넣기]", options: { color: MUTED, breakLine: true, paraSpaceAfter: 10 } },
      { text: "[조직 구성 · 역할]", options: { color: MUTED } },
    ], { x: 0.9, y: 3.85, w: 5.4, h: 2.4, fontFace: BODY, fontSize: 15, align: "left", valign: "top", margin: 0 });

    // ask
    card(s, 6.8, 2.5, 6.0, 4.0, CARD);
    s.addShape(pres.shapes.RECTANGLE, { x: 6.8, y: 2.5, w: 6.0, h: 0.1, fill: { color: GOLD } });
    s.addShape(pres.shapes.OVAL, { x: 7.1, y: 2.85, w: 0.7, h: 0.7, fill: { color: CARD2 }, line: { color: GOLD, width: 1.25 } });
    s.addImage({ data: ic.diamond, x: 7.27, y: 3.02, w: 0.36, h: 0.36 });
    s.addText("투자 요청", { x: 7.95, y: 2.9, w: 4, h: 0.6, fontFace: HEAD, fontSize: 22, color: GOLD, bold: true, align: "left", valign: "middle", margin: 0 });
    s.addText("[투자 금액]", { x: 7.1, y: 3.7, w: 5.5, h: 0.8, fontFace: HEAD, fontSize: 40, color: WHITE, bold: true, align: "left", margin: 0 });
    s.addText([
      { text: "용도 — [제품 · 영업 · 마케팅 비중]", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 8, color: TXT } },
      { text: "[런웨이 N개월]", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 8, color: TXT } },
      { text: "정부 지원사업(AI 바우처·TIPS) 매칭 가능성 [해당 시]", options: { bullet: { code: "2022" }, color: MUTED } },
    ], { x: 7.15, y: 4.65, w: 5.4, h: 1.7, fontFace: BODY, fontSize: 13.5, align: "left", valign: "top", margin: 0 });
    pageFoot(s, 14);
  }

  // ===================================================================
  // 15) VISION / CLOSING
  // ===================================================================
  {
    const s = newSlide();
    s.addShape(pres.shapes.OVAL, { x: -2.2, y: 3.6, w: 8, h: 8, fill: { color: LIME, transparency: 90 } });
    s.addShape(pres.shapes.OVAL, { x: 9.5, y: -2.5, w: 7, h: 7, fill: { color: GOLD, transparency: 92 } });

    kicker(s, "Vision", 0.7, 1.1);
    s.addText([
      { text: "동네를 걷는 모든 순간이,\n", options: { color: WHITE } },
      { text: "혜택의 발견", options: { color: LIME } },
      { text: "이 된다", options: { color: WHITE } },
    ], { x: 0.7, y: 2.1, w: 12, h: 2.2, fontFace: HEAD, fontSize: 50, bold: true, align: "left", valign: "top", lineSpacingMultiple: 1.05, margin: 0 });

    s.addText("위치기반 발견형 커머스의 표준을 만든다 — 소비자에겐 재미, 매장엔 측정 가능한 방문.", { x: 0.72, y: 4.55, w: 11, h: 0.5, fontFace: BODY, fontSize: 17, color: MUTED, align: "left", margin: 0 });

    s.addShape(pres.shapes.LINE, { x: 0.72, y: 5.55, w: 11.9, h: 0, line: { color: LINE, width: 1 } });
    s.addText([
      { text: "Thiscount", options: { color: WHITE, bold: true } },
      { text: "    걷다 보면, 혜택이 떨어진다", options: { color: LIME } },
    ], { x: 0.72, y: 5.75, w: 8.5, h: 0.5, fontFace: HEAD, fontSize: 18, align: "left", margin: 0 });
    s.addText("[연락처 · 데모 링크 · QR]", { x: 8.5, y: 5.78, w: 4.1, h: 0.45, fontFace: BODY, fontSize: 13, color: MUTED, align: "right", margin: 0 });
  }

  const out = "Thiscount_IR_Deck_KO.pptx";
  await pres.writeFile({ fileName: out });
  console.log("WROTE " + out);
}

main().catch((e) => { console.error(e); process.exit(1); });
