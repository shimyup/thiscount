const sharp = require("sharp");

// ---- brand tokens ----
const W = 1080, H = 1350;
const DARK = "#0E1014";
const YELLOW = "#FFD23F";
const YELLOW_DEEP = "#F5A623";
const WHITE = "#FFFFFF";
const MUTE = "#9AA3B2";
const GREEN = "#3DDC97";
const KFONT = "Apple SD Gothic Neo, AppleSDGothicNeo, AppleGothic, sans-serif";
const LFONT = "Helvetica Neue, Helvetica, Arial, sans-serif";

// shared <defs>
function defs() {
  return `
  <defs>
    <radialGradient id="glow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="${YELLOW_DEEP}" stop-opacity="0.55"/>
      <stop offset="45%" stop-color="${YELLOW_DEEP}" stop-opacity="0.18"/>
      <stop offset="100%" stop-color="${YELLOW_DEEP}" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="amber" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="${YELLOW}"/>
      <stop offset="100%" stop-color="${YELLOW_DEEP}"/>
    </linearGradient>
    <linearGradient id="vign" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#11151C"/>
      <stop offset="60%" stop-color="${DARK}"/>
      <stop offset="100%" stop-color="#070809"/>
    </linearGradient>
    <filter id="soft" x="-40%" y="-40%" width="180%" height="180%">
      <feGaussianBlur stdDeviation="9"/>
    </filter>
    <filter id="ds" x="-50%" y="-50%" width="200%" height="200%">
      <feDropShadow dx="0" dy="10" stdDeviation="16" flood-color="#000000" flood-opacity="0.45"/>
    </filter>
  </defs>`;
}

// map pin: tip at (cx,cy), pointing down. s = scale
function pin(cx, cy, s = 1, withGlow = true) {
  const path = "M0,0 C -9,-20 -26,-30 -26,-52 a26,26 0 1,1 52,0 C26,-30 9,-20 0,0 Z";
  const glow = withGlow ? `<circle cx="${cx}" cy="${cy - 52 * s}" r="${78 * s}" fill="url(#glow)"/>` : "";
  return `${glow}
    <g transform="translate(${cx},${cy}) scale(${s})" filter="url(#ds)">
      <path d="${path}" fill="url(#amber)"/>
      <circle cx="0" cy="-52" r="11" fill="${DARK}"/>
    </g>`;
}

// concentric auto-zone radius rings around a point
function rings(cx, cy, radii) {
  return radii.map((r, i) =>
    `<circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="${YELLOW}" stroke-opacity="${0.22 - i * 0.05}" stroke-width="2" stroke-dasharray="3 12"/>`
  ).join("");
}

// brand badge top-left
function brand(x = 64, y = 74) {
  return `
    <g>
      <circle cx="${x + 26}" cy="${y + 26}" r="30" fill="url(#amber)" filter="url(#ds)"/>
      <g transform="translate(${x + 26},${y + 44}) scale(0.62)">
        <path d="M0,0 C -9,-20 -26,-30 -26,-52 a26,26 0 1,1 52,0 C26,-30 9,-20 0,0 Z" fill="${DARK}"/>
        <circle cx="0" cy="-52" r="11" fill="url(#amber)"/>
      </g>
      <text x="${x + 70}" y="${y + 37}" font-family="${LFONT}" font-size="34" font-weight="700" fill="${WHITE}" letter-spacing="0.3">Thiscount</text>
    </g>`;
}

// subtle map streets background (low opacity rounded lines)
function streets(seed) {
  const lines = [];
  const cols = seed.v;
  cols.forEach(c => {
    lines.push(`<line x1="${c.x1}" y1="${c.y1}" x2="${c.x2}" y2="${c.y2}" stroke="#FFFFFF" stroke-opacity="0.05" stroke-width="${c.w||10}" stroke-linecap="round"/>`);
  });
  return lines.join("");
}

// CTA pill
function cta(label, cx, y, w = 460, h = 96) {
  const x = cx - w / 2;
  return `
    <rect x="${x}" y="${y}" rx="${h/2}" ry="${h/2}" width="${w}" height="${h}" fill="url(#amber)" filter="url(#ds)"/>
    <text x="${cx}" y="${y + h/2 + 14}" text-anchor="middle" font-family="${KFONT}" font-size="40" font-weight="800" fill="${DARK}">${label}</text>`;
}

function wrap(svgInner) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  ${defs()}
  <rect width="${W}" height="${H}" fill="url(#vign)"/>
  ${svgInner}
</svg>`;
}

// ============ CREATIVE 1 — 소비자 훅: 걸어가다 줍는 쿠폰 ============
function creative1() {
  const streetSeed = { v: [
    {x1:0,y1:980,x2:1080,y2:900,w:14},
    {x1:120,y1:1350,x2:520,y2:760,w:12},
    {x1:980,y1:1350,x2:640,y2:740,w:12},
    {x1:0,y1:1180,x2:1080,y2:1240,w:10},
  ]};
  // central glow behind pin
  const pinX = 540, pinY = 1000;
  // dotted walking path: from lower-left start to the pin
  const path = `M 250 1280 C 330 1150, 300 1080, 420 1040 S 520 1010, 540 1010`;
  return wrap(`
    ${brand()}
    <!-- headline -->
    <text x="64" y="320" font-family="${KFONT}" font-size="118" font-weight="800" fill="${WHITE}">걸어가다</text>
    <text x="64" y="446" font-family="${KFONT}" font-size="118" font-weight="800" fill="${WHITE}">줍는 <tspan fill="${YELLOW}">쿠폰.</tspan></text>
    <text x="66" y="520" font-family="${KFONT}" font-size="38" font-weight="500" fill="${MUTE}">지도 켜고 동네 한 바퀴 —</text>
    <text x="66" y="572" font-family="${KFONT}" font-size="38" font-weight="500" fill="${MUTE}">발 밑에 할인이 떨어져 있다.</text>

    <!-- map area -->
    <g opacity="0.9">${streets(streetSeed)}</g>
    ${rings(pinX, pinY - 52, [150, 230, 320])}
    <!-- start marker (person) -->
    <circle cx="250" cy="1280" r="16" fill="${WHITE}" fill-opacity="0.85"/>
    <circle cx="250" cy="1280" r="30" fill="none" stroke="${WHITE}" stroke-opacity="0.25" stroke-width="2"/>
    <!-- walking dotted path -->
    <path d="${path}" fill="none" stroke="${YELLOW}" stroke-width="13" stroke-linecap="round" stroke-dasharray="0.5 40" opacity="0.95"/>
    ${pin(pinX, pinY, 1.55)}

    ${cta("지금 주우러 가기", 540, 1208, 520)}
  `);
}

// ============ CREATIVE 2 — 게임화 보물찾기 ============
function creative2() {
  // scattered mini pins (treasure)
  const minis = [
    [205, 720, 0.7], [820, 690, 0.62], [330, 980, 0.66],
    [760, 1010, 0.7], [560, 1120, 0.58], [905, 880, 0.55],
    [150, 1130, 0.6],
  ];
  const grid = [];
  for (let gx = 60; gx <= 1020; gx += 120) grid.push(`<line x1="${gx}" y1="640" x2="${gx}" y2="1300" stroke="#FFFFFF" stroke-opacity="0.045" stroke-width="2"/>`);
  for (let gy = 640; gy <= 1300; gy += 120) grid.push(`<line x1="40" y1="${gy}" x2="1040" y2="${gy}" stroke="#FFFFFF" stroke-opacity="0.045" stroke-width="2"/>`);
  const heroX = 560, heroY = 970;
  const miniSvg = minis.map(([x, y, s]) => pin(x, y, s, false)).join("");
  return wrap(`
    ${brand()}
    <!-- eyebrow chip -->
    <rect x="64" y="200" rx="26" ry="26" width="300" height="52" fill="none" stroke="${YELLOW}" stroke-opacity="0.6" stroke-width="2"/>
    <text x="88" y="235" font-family="${KFONT}" font-size="28" font-weight="700" fill="${YELLOW}">오늘의 보물찾기</text>
    <!-- headline -->
    <text x="64" y="346" font-family="${KFONT}" font-size="96" font-weight="800" fill="${WHITE}">우리 동네에</text>
    <text x="64" y="452" font-family="${KFONT}" font-size="96" font-weight="800" fill="${YELLOW}">쿠폰이 떨어졌다</text>
    <text x="66" y="528" font-family="${KFONT}" font-size="37" font-weight="500" fill="${MUTE}">가까이 걸어가면 줍힘. 몇 장 주울 수 있을까?</text>

    <!-- treasure map -->
    <g>${grid.join("")}</g>
    ${rings(heroX, heroY - 52, [160, 250])}
    ${miniSvg}
    ${pin(heroX, heroY, 1.7)}
    <!-- count chip near hero -->
    <g transform="translate(${heroX + 70},${heroY - 150})">
      <rect x="0" y="0" rx="22" ry="22" width="250" height="58" fill="${DARK}" stroke="${YELLOW}" stroke-width="2" filter="url(#ds)"/>
      <text x="24" y="38" font-family="${KFONT}" font-size="28" font-weight="700" fill="${WHITE}">근처 <tspan fill="${YELLOW}" font-weight="800">12장</tspan> 줍기</text>
    </g>

    ${cta("지도 열고 줍기", 540, 1228, 480)}
  `);
}

// ============ CREATIVE 3 — 매장용: 30초 AI 쿠폰 ============
function creative3() {
  // coupon ticket with side notches + dashed perforation
  const tx = 150, ty = 800, tw = 780, th = 360, notch = 26;
  const splitX = tx + tw * 0.66;
  const stubCx = splitX + ((tx + tw) - splitX) / 2;
  const ticket = `
    <g filter="url(#ds)">
      <path d="
        M ${tx + 28} ${ty}
        H ${tx + tw - 28} a28 28 0 0 1 28 28
        V ${ty + th/2 - notch}
        a ${notch} ${notch} 0 0 0 0 ${2*notch}
        V ${ty + th - 28} a28 28 0 0 1 -28 28
        H ${tx + 28} a28 28 0 0 1 -28 -28
        V ${ty + th/2 + notch}
        a ${notch} ${notch} 0 0 0 0 ${-2*notch}
        V ${ty + 28} a28 28 0 0 1 28 -28 Z"
        fill="#FFFFFF"/>
    </g>
    <line x1="${splitX}" y1="${ty + 34}" x2="${splitX}" y2="${ty + th - 34}" stroke="#C9CDD4" stroke-width="3" stroke-dasharray="3 12"/>
    <!-- left: coupon copy -->
    <text x="${tx + 48}" y="${ty + 92}" font-family="${KFONT}" font-size="30" font-weight="700" fill="${YELLOW_DEEP}">동네 카페 · 할인권</text>
    <text x="${tx + 46}" y="${ty + 178}" font-family="${KFONT}" font-size="78" font-weight="800" fill="${DARK}">아메리카노</text>
    <text x="${tx + 46}" y="${ty + 262}" font-family="${KFONT}" font-size="78" font-weight="800" fill="${DARK}"><tspan fill="${YELLOW_DEEP}">1,500원</tspan> 할인</text>
    <text x="${tx + 48}" y="${ty + 320}" font-family="${KFONT}" font-size="26" font-weight="500" fill="#8A8F98">AI가 자동으로 작성한 초안</text>
    <!-- right stub: value (centered in stub) -->
    <text x="${stubCx}" y="${ty + th/2 - 26}" text-anchor="middle" font-family="${KFONT}" font-size="28" font-weight="700" fill="#8A8F98">반경</text>
    <text x="${stubCx}" y="${ty + th/2 + 28}" text-anchor="middle" font-family="${LFONT}" font-size="56" font-weight="800" fill="${DARK}">500m</text>
    <text x="${stubCx}" y="${ty + th/2 + 72}" text-anchor="middle" font-family="${KFONT}" font-size="26" font-weight="500" fill="#8A8F98">자동 살포</text>
  `;
  // AI + timer badges floating on ticket top
  const badges = `
    <g transform="translate(${tx + tw - 250},${ty - 34})">
      <rect x="0" y="0" rx="30" ry="30" width="210" height="60" fill="url(#amber)" filter="url(#ds)"/>
      <text x="105" y="40" text-anchor="middle" font-family="${KFONT}" font-size="30" font-weight="800" fill="${DARK}">✨ AI · 00:30</text>
    </g>`;
  return wrap(`
    ${brand()}
    <text x="64" y="332" font-family="${KFONT}" font-size="100" font-weight="800" fill="${WHITE}">광고 문구</text>
    <text x="64" y="448" font-family="${KFONT}" font-size="100" font-weight="800" fill="${WHITE}">고민, <tspan fill="${YELLOW}">그만.</tspan></text>
    <text x="66" y="524" font-family="${KFONT}" font-size="38" font-weight="500" fill="${MUTE}">업종이랑 한 줄만 적으면, AI가 30초 만에</text>
    <text x="66" y="576" font-family="${KFONT}" font-size="38" font-weight="500" fill="${MUTE}">쿠폰을 만들어 동네 반경에 자동으로 뿌려요.</text>

    <!-- first month free badge -->
    <g transform="translate(64,650)">
      <rect x="0" y="0" rx="30" ry="30" width="412" height="60" fill="none" stroke="${GREEN}" stroke-width="2"/>
      <circle cx="38" cy="30" r="9" fill="${GREEN}"/>
      <text x="64" y="40" font-family="${KFONT}" font-size="30" font-weight="700" fill="${GREEN}">첫 달 무료 · 카드 없이 시작</text>
    </g>

    ${ticket}
    ${badges}

    ${cta("사장님, 시작하기", 540, 1232, 500)}
  `);
}

async function render(name, svg) {
  await sharp(Buffer.from(svg)).png().toFile(name);
  console.log("WROTE", name);
}

(async () => {
  await render("ig_ad_1_consumer_hook.png", creative1());
  await render("ig_ad_2_treasure_hunt.png", creative2());
  await render("ig_ad_3_merchant_ai.png", creative3());
})();
