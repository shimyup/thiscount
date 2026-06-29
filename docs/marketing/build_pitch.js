const pptxgen = require("pptxgenjs");
const React = require("react");
const ReactDOMServer = require("react-dom/server");
const sharp = require("sharp");
const {
  FaMapMarkerAlt, FaCoins, FaQuestionCircle, FaPenFancy,
  FaRobot, FaBroadcastTower, FaChartLine, FaCheckCircle,
  FaWalking, FaSearch, FaMotorcycle, FaRegNewspaper, FaBolt, FaGift, FaArrowRight
} = require("react-icons/fa");

// ---- palette (dark + yellow brand) ----
const DARK = "0E1014";
const DARK2 = "151A22";
const PANEL = "1C222C";
const PANEL2 = "232A35";
const YELLOW = "FFD23F";
const YELLOW_DEEP = "F5A623";
const WHITE = "FFFFFF";
const MUTE = "9AA3B2";
const MUTE2 = "6E7787";
const GREEN = "3DDC97";

const HEAD = "Arial Black";
const BODY = "Arial";

async function icon(IconComponent, color = "#FFFFFF", size = 256) {
  const svg = ReactDOMServer.renderToStaticMarkup(
    React.createElement(IconComponent, { color, size: String(size) })
  );
  const png = await sharp(Buffer.from(svg)).png().toBuffer();
  return "image/png;base64," + png.toString("base64");
}
const makeShadow = () => ({ type: "outer", color: "000000", blur: 10, offset: 3, angle: 135, opacity: 0.35 });

(async () => {
  const I = {
    pin: await icon(FaMapMarkerAlt, "#0E1014"),
    coins: await icon(FaCoins, "#FFD23F"),
    q: await icon(FaQuestionCircle, "#FFD23F"),
    pen: await icon(FaPenFancy, "#FFD23F"),
    pinY: await icon(FaMapMarkerAlt, "#FFD23F"),
    robot: await icon(FaRobot, "#0E1014"),
    tower: await icon(FaBroadcastTower, "#0E1014"),
    chart: await icon(FaChartLine, "#0E1014"),
    check: await icon(FaCheckCircle, "#3DDC97"),
    walk: await icon(FaWalking, "#0E1014"),
    search: await icon(FaSearch, "#CDD2DB"),
    moto: await icon(FaMotorcycle, "#CDD2DB"),
    news: await icon(FaRegNewspaper, "#CDD2DB"),
    bolt: await icon(FaBolt, "#0E1014"),
    gift: await icon(FaGift, "#FFD23F"),
    arrow: await icon(FaArrowRight, "#F5A623"),
    walkY: await icon(FaWalking, "#FFD23F"),
    chartY: await icon(FaChartLine, "#FFD23F"),
  };

  const pres = new pptxgen();
  pres.layout = "LAYOUT_WIDE"; // 13.3 x 7.5
  pres.author = "Thiscount";
  pres.title = "Thiscount 매장 파트너 제안";
  const W = 13.3, H = 7.5;

  // small helper: kicker label
  function kicker(slide, text, x, y, color = YELLOW) {
    slide.addText(text.toUpperCase(), {
      x, y, w: 6, h: 0.3, fontFace: BODY, fontSize: 12, bold: true,
      color, charSpacing: 3, margin: 0, align: "left",
    });
  }

  // ===================== SLIDE 1 — TITLE =====================
  {
    const s = pres.addSlide();
    s.background = { color: DARK };
    // ambient yellow glow circle
    s.addShape(pres.shapes.OVAL, { x: 9.0, y: -2.2, w: 7.5, h: 7.5, fill: { color: YELLOW_DEEP, transparency: 88 }, line: { type: "none" } });
    s.addShape(pres.shapes.OVAL, { x: 10.3, y: -0.6, w: 4.5, h: 4.5, fill: { color: YELLOW, transparency: 82 }, line: { type: "none" } });

    // brand pin badge
    s.addShape(pres.shapes.OVAL, { x: 0.9, y: 0.85, w: 0.95, h: 0.95, fill: { color: YELLOW }, line: { type: "none" }, shadow: makeShadow() });
    s.addImage({ data: I.pin, x: 1.16, y: 1.07, w: 0.43, h: 0.5 });
    s.addText("Thiscount", { x: 2.0, y: 0.92, w: 6, h: 0.8, fontFace: HEAD, fontSize: 30, bold: true, color: WHITE, valign: "middle", margin: 0 });

    s.addText("걷다가 줍는\n동네 쿠폰.", {
      x: 0.9, y: 2.35, w: 8.6, h: 2.2, fontFace: HEAD, fontSize: 60, bold: true,
      color: WHITE, lineSpacingMultiple: 0.98, margin: 0,
    });
    s.addText([
      { text: "AI", options: { color: YELLOW, bold: true } },
      { text: "가 매장 대신 쿠폰을 만들고, ", options: { color: MUTE } },
      { text: "가장 살 사람", options: { color: YELLOW, bold: true } },
      { text: "에게 뿌립니다.", options: { color: MUTE } },
    ], { x: 0.95, y: 4.7, w: 9.5, h: 0.6, fontFace: BODY, fontSize: 20, margin: 0 });

    s.addText("소상공인 파트너 제안", { x: 0.95, y: 6.55, w: 6, h: 0.4, fontFace: BODY, fontSize: 13, color: MUTE2, bold: true, charSpacing: 2, margin: 0 });
    s.addText("위치기반 쿠폰 발견 앱 · iOS / Android", { x: 7.0, y: 6.55, w: 5.4, h: 0.4, fontFace: BODY, fontSize: 13, color: MUTE2, align: "right", margin: 0 });
  }

  // ===================== SLIDE 2 — PROBLEM =====================
  {
    const s = pres.addSlide();
    s.background = { color: DARK2 };
    kicker(s, "The Problem", 0.9, 0.7);
    s.addText("동네 매장의 광고, 세 개의 벽", {
      x: 0.9, y: 1.05, w: 11.5, h: 0.9, fontFace: HEAD, fontSize: 36, bold: true, color: WHITE, margin: 0,
    });

    const cards = [
      { ic: I.coins, t: "비싼 광고비", d: "전단·배너·검색광고는\n작은 매장엔 부담. 한 번 쓰면\n끝나는 일회성 비용." },
      { ic: I.q, t: "효과를 알 수 없음", d: "노출은 됐다는데\n진짜 손님이 왔는지,\n얼마를 썼는지 불투명." },
      { ic: I.pen, t: "만들 줄 모름", d: "쿠폰 문구·디자인을\n직접 고민할 시간도,\n노하우도 없음." },
    ];
    const cw = 3.7, gap = 0.42, x0 = 0.9, y0 = 2.35, ch = 3.5;
    cards.forEach((c, i) => {
      const x = x0 + i * (cw + gap);
      s.addShape(pres.shapes.RECTANGLE, { x, y: y0, w: cw, h: ch, fill: { color: PANEL }, line: { color: PANEL2, width: 1 }, shadow: makeShadow() });
      s.addShape(pres.shapes.OVAL, { x: x + 0.4, y: y0 + 0.42, w: 0.95, h: 0.95, fill: { color: DARK }, line: { color: YELLOW, width: 1.5 } });
      s.addImage({ data: c.ic, x: x + 0.66, y: y0 + 0.68, w: 0.43, h: 0.43 });
      s.addText(c.t, { x: x + 0.4, y: y0 + 1.55, w: cw - 0.8, h: 0.6, fontFace: HEAD, fontSize: 21, bold: true, color: WHITE, margin: 0 });
      s.addText(c.d, { x: x + 0.4, y: y0 + 2.15, w: cw - 0.8, h: 1.2, fontFace: BODY, fontSize: 14.5, color: MUTE, lineSpacingMultiple: 1.1, margin: 0 });
    });

    s.addText([
      { text: "결국 — ", options: { color: MUTE } },
      { text: "“돈은 쓰는데, 효과는 모른다.”", options: { color: YELLOW, bold: true } },
    ], { x: 0.9, y: 6.35, w: 11.5, h: 0.5, fontFace: BODY, fontSize: 18, margin: 0 });
  }

  // ===================== SLIDE 3 — SOLUTION =====================
  {
    const s = pres.addSlide();
    s.background = { color: DARK };
    kicker(s, "The Solution", 0.9, 0.7);
    s.addText([
      { text: "Thiscount는 ", options: { color: WHITE } },
      { text: "30초", options: { color: YELLOW } },
      { text: "면 끝납니다.", options: { color: WHITE } },
    ], { x: 0.9, y: 1.05, w: 11.5, h: 0.9, fontFace: HEAD, fontSize: 36, bold: true, margin: 0 });

    const cards = [
      { ic: I.robot, t: "AI 쿠폰 생성", d: "업종과 한 줄 설명만 입력하면\nAI가 카피와 혜택을 자동 작성.\n일반홍보·할인권·교환권 지원." },
      { ic: I.tower, t: "반경 자동 살포", d: "매장 주변 반경과 기간만 설정하면\n쿠폰이 동네 지도에 자동 배포.\n손님은 걸어가다 줍습니다." },
      { ic: I.chart, t: "ROI 리포트", d: "몇 장이 줍혔고, 누가 매장에 왔는지\n한 화면에서 확인.\n노출이 아니라 ‘방문’을 측정." },
    ];
    const cw = 3.7, gap = 0.42, x0 = 0.9, y0 = 2.3, ch = 3.45;
    cards.forEach((c, i) => {
      const x = x0 + i * (cw + gap);
      s.addShape(pres.shapes.RECTANGLE, { x, y: y0, w: cw, h: ch, fill: { color: PANEL }, line: { type: "none" }, shadow: makeShadow() });
      s.addShape(pres.shapes.RECTANGLE, { x, y: y0, w: cw, h: 0.12, fill: { color: YELLOW }, line: { type: "none" } });
      s.addShape(pres.shapes.OVAL, { x: x + 0.4, y: y0 + 0.45, w: 1.0, h: 1.0, fill: { color: YELLOW }, line: { type: "none" } });
      s.addImage({ data: c.ic, x: x + 0.69, y: y0 + 0.72, w: 0.43, h: 0.45 });
      s.addText(`0${i + 1}`, { x: x + cw - 1.2, y: y0 + 0.38, w: 0.9, h: 0.7, fontFace: HEAD, fontSize: 30, bold: true, color: PANEL2, align: "right", margin: 0 });
      s.addText(c.t, { x: x + 0.4, y: y0 + 1.6, w: cw - 0.8, h: 0.5, fontFace: HEAD, fontSize: 20, bold: true, color: WHITE, margin: 0 });
      s.addText(c.d, { x: x + 0.4, y: y0 + 2.12, w: cw - 0.8, h: 1.2, fontFace: BODY, fontSize: 14, color: MUTE, lineSpacingMultiple: 1.12, margin: 0 });
    });
    s.addText("광고를 ‘사는’ 게 아니라, 동네에 ‘뿌리고’ 결과를 ‘봅니다’.", {
      x: 0.9, y: 6.35, w: 11.5, h: 0.5, fontFace: BODY, fontSize: 17, color: MUTE, italic: true, margin: 0,
    });
  }

  // ===================== SLIDE 4 — HOW IT WORKS =====================
  {
    const s = pres.addSlide();
    s.background = { color: "F4F5F7" };
    kicker(s, "How it works", 0.9, 0.7, YELLOW_DEEP);
    s.addText("쿠폰 한 장이 손님이 되기까지", {
      x: 0.9, y: 1.05, w: 11.5, h: 0.9, fontFace: HEAD, fontSize: 34, bold: true, color: DARK, margin: 0,
    });

    const steps = [
      { ic: I.pen, t: "입력", d: "업종 선택 +\n한 줄 설명" },
      { ic: I.robot, t: "AI 생성", d: "카피·혜택\n자동 초안" },
      { ic: I.tower, t: "자동 살포", d: "반경·기간\n설정 후 배포" },
      { ic: I.walk, t: "줍기·방문", d: "손님이 줍고\n매장에서 사용" },
      { ic: I.chart, t: "ROI 확인", d: "줍힘→방문\n한 화면 측정" },
    ];
    const n = steps.length;
    const cw = 2.05, gap = 0.32, x0 = 0.9, y0 = 2.75, ch = 2.9;
    steps.forEach((st, i) => {
      const x = x0 + i * (cw + gap);
      s.addShape(pres.shapes.RECTANGLE, { x, y: y0, w: cw, h: ch, fill: { color: WHITE }, line: { color: "E2E5EA", width: 1 }, shadow: makeShadow() });
      const isAI = i === 1 || i === 2;
      s.addShape(pres.shapes.OVAL, { x: x + cw / 2 - 0.5, y: y0 + 0.35, w: 1.0, h: 1.0, fill: { color: isAI ? YELLOW : DARK }, line: { type: "none" } });
      // dark circles -> yellow icons; yellow circles -> dark icons
      const stepIcon = [I.pen, I.robot, I.tower, I.walkY, I.chartY][i];
      s.addImage({ data: stepIcon, x: x + cw / 2 - 0.24, y: y0 + 0.6, w: 0.48, h: 0.5 });
      s.addText(st.t, { x, y: y0 + 1.5, w: cw, h: 0.4, fontFace: HEAD, fontSize: 17, bold: true, color: DARK, align: "center", margin: 0 });
      s.addText(st.d, { x: x + 0.15, y: y0 + 1.92, w: cw - 0.3, h: 0.85, fontFace: BODY, fontSize: 12.5, color: "5A6473", align: "center", lineSpacingMultiple: 1.05, margin: 0 });
      if (i < n - 1) {
        s.addImage({ data: I.arrow, x: x + cw + gap / 2 - 0.13, y: y0 + ch / 2 - 0.13, w: 0.26, h: 0.26 });
      }
    });
    s.addText([
      { text: "사장님이 하는 일은 ", options: { color: "5A6473" } },
      { text: "‘입력’ 한 번", options: { color: YELLOW_DEEP, bold: true } },
      { text: ". 나머지는 Thiscount가 합니다.", options: { color: "5A6473" } },
    ], { x: 0.9, y: 6.4, w: 11.5, h: 0.5, fontFace: BODY, fontSize: 17, margin: 0 });
  }

  // ===================== SLIDE 5 — WHY (differentiation) =====================
  {
    const s = pres.addSlide();
    s.background = { color: DARK2 };
    kicker(s, "Why Thiscount", 0.9, 0.7);
    s.addText("‘발견’의 방식이 다릅니다", {
      x: 0.9, y: 1.05, w: 11.5, h: 0.9, fontFace: HEAD, fontSize: 34, bold: true, color: WHITE, margin: 0,
    });

    const rows = [
      { ic: I.search, n: "네이버플레이스", d: "검색해야 보인다", hl: false },
      { ic: I.moto, n: "배민쿠폰", d: "배달 주문 안에서만", hl: false },
      { ic: I.news, n: "당근마켓", d: "피드를 봐야 보인다", hl: false },
      { ic: I.pinY, n: "Thiscount", d: "안 찾아도, 걷다가 줍는다 → 매장 방문", hl: true },
    ];
    const x0 = 0.9, y0 = 2.35, rw = 11.5, rh = 0.92, rg = 0.18;
    rows.forEach((r, i) => {
      const y = y0 + i * (rh + rg);
      s.addShape(pres.shapes.RECTANGLE, { x: x0, y, w: rw, h: rh, fill: { color: r.hl ? YELLOW : PANEL }, line: { type: "none" }, shadow: r.hl ? makeShadow() : undefined });
      s.addShape(pres.shapes.OVAL, { x: x0 + 0.3, y: y + 0.21, w: 0.5, h: 0.5, fill: { color: r.hl ? DARK : DARK2 }, line: { type: "none" } });
      s.addImage({ data: r.ic, x: x0 + 0.42, y: y + 0.32, w: 0.26, h: 0.28 });
      s.addText(r.n, { x: x0 + 1.1, y, w: 3.3, h: rh, fontFace: HEAD, fontSize: 18, bold: true, color: r.hl ? DARK : WHITE, valign: "middle", margin: 0 });
      s.addText(r.d, { x: x0 + 4.4, y, w: rw - 4.7, h: rh, fontFace: BODY, fontSize: 16, color: r.hl ? DARK : MUTE, bold: r.hl, valign: "middle", margin: 0 });
    });
    s.addText("검색은 네이버, 배달은 배민 — 걷다가 줍는 건 Thiscount 뿐.", {
      x: 0.9, y: 6.85, w: 11.5, h: 0.4, fontFace: BODY, fontSize: 14, color: MUTE2, italic: true, margin: 0,
    });
  }

  // ===================== SLIDE 6 — PRICING =====================
  {
    const s = pres.addSlide();
    s.background = { color: DARK };
    kicker(s, "Pricing", 0.9, 0.7);
    s.addText("부담 없이, 첫 달은 무료", {
      x: 0.9, y: 1.05, w: 11.5, h: 0.9, fontFace: HEAD, fontSize: 36, bold: true, color: WHITE, margin: 0,
    });

    // big offer card (left)
    s.addShape(pres.shapes.RECTANGLE, { x: 0.9, y: 2.35, w: 6.0, h: 4.2, fill: { color: YELLOW }, line: { type: "none" }, shadow: makeShadow() });
    s.addText("FIRST MONTH", { x: 1.3, y: 2.7, w: 5, h: 0.4, fontFace: BODY, fontSize: 14, bold: true, color: DARK, charSpacing: 3, margin: 0 });
    s.addText([
      { text: "0", options: { fontSize: 110, bold: true, color: DARK } },
      { text: "원", options: { fontSize: 40, bold: true, color: DARK } },
    ], { x: 1.25, y: 3.0, w: 5.3, h: 1.9, fontFace: HEAD, margin: 0, valign: "middle" });
    s.addText("카드 등록 없이 바로 시작 · 언제든 중단", {
      x: 1.3, y: 5.35, w: 5.2, h: 0.5, fontFace: BODY, fontSize: 15, bold: true, color: "5A4500", margin: 0,
    });

    // included list (right)
    const items = [
      "AI 쿠폰 생성 무제한 초안",
      "반경 자동 살포 (auto-zone)",
      "줍힘 → 방문 ROI 대시보드",
      "일반홍보 · 할인권 · 교환권",
      "노출이 아닌 ‘동네 반경·기간’ 단위 과금",
    ];
    s.addText("첫 달 포함 사항", { x: 7.4, y: 2.45, w: 5, h: 0.5, fontFace: HEAD, fontSize: 20, bold: true, color: WHITE, margin: 0 });
    items.forEach((it, i) => {
      const y = 3.15 + i * 0.66;
      s.addImage({ data: I.check, x: 7.45, y: y + 0.02, w: 0.3, h: 0.3 });
      s.addText(it, { x: 7.9, y, w: 4.9, h: 0.45, fontFace: BODY, fontSize: 15.5, color: WHITE, valign: "middle", margin: 0 });
    });
    s.addText("※ 첫 달 이후 합리적 월 정액 — 런치 파트너 특가는 미팅 시 별도 안내", {
      x: 7.4, y: 6.55, w: 5.4, h: 0.4, fontFace: BODY, fontSize: 11.5, color: MUTE2, margin: 0,
    });
  }

  // ===================== SLIDE 7 — CTA =====================
  {
    const s = pres.addSlide();
    s.background = { color: DARK };
    s.addShape(pres.shapes.OVAL, { x: -2.5, y: 2.5, w: 8, h: 8, fill: { color: YELLOW_DEEP, transparency: 90 }, line: { type: "none" } });

    s.addShape(pres.shapes.OVAL, { x: 0.9, y: 1.3, w: 0.95, h: 0.95, fill: { color: YELLOW }, line: { type: "none" }, shadow: makeShadow() });
    s.addImage({ data: I.pin, x: 1.16, y: 1.52, w: 0.43, h: 0.5 });

    s.addText("지금, 우리 동네에\n쿠폰을 뿌리세요.", {
      x: 0.9, y: 2.55, w: 11, h: 2.0, fontFace: HEAD, fontSize: 52, bold: true, color: WHITE, lineSpacingMultiple: 1.0, margin: 0,
    });
    s.addText([
      { text: "미팅에서 ", options: { color: MUTE } },
      { text: "30초", options: { color: YELLOW, bold: true } },
      { text: " 만에 매장 쿠폰 한 장을 직접 만들어 보여드립니다.", options: { color: MUTE } },
    ], { x: 0.95, y: 4.75, w: 11, h: 0.6, fontFace: BODY, fontSize: 20, margin: 0 });

    // CTA pill
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.95, y: 5.6, w: 4.4, h: 0.85, fill: { color: YELLOW }, line: { type: "none" }, rectRadius: 0.42, shadow: makeShadow() });
    s.addText("첫 달 무료로 시작하기", { x: 0.95, y: 5.6, w: 4.4, h: 0.85, fontFace: HEAD, fontSize: 19, bold: true, color: DARK, align: "center", valign: "middle", margin: 0 });

    s.addText("Thiscount · 위치기반 동네 쿠폰", { x: 0.95, y: 6.85, w: 11, h: 0.4, fontFace: BODY, fontSize: 13, color: MUTE2, bold: true, charSpacing: 1, margin: 0 });
  }

  await pres.writeFile({ fileName: "thiscount_brand_pitch.pptx" });
  console.log("WROTE thiscount_brand_pitch.pptx");
})();
