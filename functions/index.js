/**
 * Thiscount auth email/SMS relay (Build 412 — PII sim CRITICAL fix).
 *
 * WHY: 이전엔 Resend/SendGrid/Twilio 서버급 API 키가 dart-define 으로 클라이언트
 *   바이너리에 컴파일되어, 공격자가 IPA/APK 를 `strings` 로 긁어 키를 추출 →
 *   검증된 도메인(thiscount.io)으로 위장 메일 발송(피싱) → 계정 탈취가 가능했음.
 * 이 함수가 키를 서버에만 보관하고, 인증된(Firebase ID 토큰) 호출자에게
 *   '고정 템플릿' OTP / 임시비밀번호 메일·SMS 만 발송한다. 임의 본문 발송 불가 →
 *   도메인 사칭 차단.
 *
 * DEPLOY:
 *   cd functions && npm install
 *   # 시크릿 등록 (1회):
 *   firebase functions:secrets:set RESEND_API_KEY
 *   firebase functions:secrets:set TWILIO_ACCOUNT_SID
 *   firebase functions:secrets:set TWILIO_AUTH_TOKEN
 *   # from 주소/번호는 비밀 아님 → 환경변수(.env) 또는 아래 상수로:
 *   firebase deploy --only functions
 *   # 배포 후 출력된 함수 URL 을 클라이언트 빌드에 주입:
 *   #   --dart-define=AUTH_EMAIL_FN_URL=https://.../sendAuthEmail
 *   #   --dart-define=AUTH_SMS_FN_URL=https://.../sendAuthSms
 *
 * NOTE: 아웃바운드 네트워크(Resend/Twilio) 호출은 Firebase Blaze(종량제) 플랜 필요.
 */

const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

const RESEND_API_KEY = defineSecret("RESEND_API_KEY");
const TWILIO_ACCOUNT_SID = defineSecret("TWILIO_ACCOUNT_SID");
const TWILIO_AUTH_TOKEN = defineSecret("TWILIO_AUTH_TOKEN");
// RevenueCat webhook Authorization 헤더 검증용 공유 비밀.
//   RC 대시보드 → Integrations → Webhooks → Authorization header 에 동일 값 설정.
const RC_WEBHOOK_AUTH = defineSecret("RC_WEBHOOK_AUTH");
// AI 쿠폰 생성 LLM 키 (서버 전용 — 절대 클라이언트 바이너리에 두지 않음).
//   현재: 전 언어 Google Gemini Flash(무료티어+최저가) 단일 사용.
//   ⚠️ 한국어 품질 비교 후 ko→Upstage Solar(국산) 도입하려면:
//     1) const SOLAR_API_KEY = defineSecret("SOLAR_API_KEY"); 추가
//     2) generateCoupon 의 secrets 배열에 SOLAR_API_KEY 추가
//     3) callSolar() 복원(아래 주석) + 라우팅을 langCode==='ko' 분기로 변경
//     4) firebase functions:secrets:set SOLAR_API_KEY 후 재배포
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

// 발신 정보 (비밀 아님). 도메인이 Resend 에 검증돼 있어야 함.
const RESEND_FROM = "Thiscount <ceo@airony.xyz>";
const TWILIO_FROM = process.env.TWILIO_FROM_NUMBER || "";

// ── 간단 per-uid rate limit (인스턴스 메모리, best-effort) ──────────────────
//   클라이언트 OTP rate-limit 위에 얹는 2차 방어. cold-start 시 reset.
const _hits = new Map(); // uid → [timestamps(ms)]
const RL_WINDOW_MS = 60 * 1000;
const RL_MAX = 5; // 분당 5회
function rateLimited(uid) {
  const now = Date.now();
  const arr = (_hits.get(uid) || []).filter((t) => now - t < RL_WINDOW_MS);
  if (arr.length >= RL_MAX) return true;
  arr.push(now);
  _hits.set(uid, arr);
  return false;
}

// ── 입력 검증 헬퍼 ──────────────────────────────────────────────────────────
const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
// OTP 코드: 영숫자 4-10 (SMS/이메일 공통).
const OTP_RE = /^[A-Za-z0-9]{4,10}$/;
// 임시 비밀번호: 클라이언트 _generateTempPassword 가 12자 + !@#% 특수문자를
//   생성하므로 OTP_RE 로는 항상 거부됨(길이/문자셋 위반) → 비밀번호 찾기 메일
//   영구 발송 불가 버그. 임시비번 전용으로 특수문자 4종 + 8-20 길이 허용.
//   <>&"' 등 HTML/인젝션 위험 문자는 여전히 불허(인젝션 차단 유지).
const TEMP_PW_RE = /^[A-Za-z0-9!@#%]{8,20}$/;
function bad(res, code, msg) {
  return res.status(code).json({ ok: false, error: msg });
}
async function verifyCaller(req, res) {
  const authz = req.get("Authorization") || "";
  const m = authz.match(/^Bearer (.+)$/);
  if (!m) {
    bad(res, 401, "missing token");
    return null;
  }
  try {
    return await admin.auth().verifyIdToken(m[1]);
  } catch (e) {
    bad(res, 401, "invalid token");
    return null;
  }
}

// ── 이메일 템플릿 (서버 생성 — 클라이언트는 코드/타입만 전달) ─────────────────
function otpSubject(lang) {
  const m = {
    ko: "[Thiscount] 이메일 인증 코드", en: "[Thiscount] Email Verification Code",
    ja: "[Thiscount] メール認証コード", zh: "[Thiscount] 邮箱验证码",
  };
  return m[lang] || m.en;
}
function tempSubject(lang) {
  const m = {
    ko: "[Thiscount] 임시 비밀번호 발급", en: "[Thiscount] Temporary Password",
    ja: "[Thiscount] 仮パスワードのお知らせ", zh: "[Thiscount] 临时密码已发放",
  };
  return m[lang] || m.en;
}
function otpText(code, lang) {
  const m = {
    ko: `Thiscount 인증 코드: ${code}\n이 코드는 10분 동안 유효합니다.`,
    en: `Thiscount verification code: ${code}\nThis code is valid for 10 minutes.`,
    ja: `Thiscount 認証コード: ${code}\nこのコードは10分間有効です。`,
    zh: `Thiscount 验证码: ${code}\n此验证码10分钟内有效。`,
  };
  return m[lang] || m.en;
}
function tempText(pw, mins, lang) {
  const m = {
    ko: `임시 비밀번호: ${pw}\n유효 시간: ${mins}분\n로그인 후 새 비밀번호로 변경하세요.`,
    en: `Temporary password: ${pw}\nValid for ${mins} minutes\nPlease change it after logging in.`,
    ja: `仮パスワード: ${pw}\n有効期間: ${mins}分\nログイン後に変更してください。`,
    zh: `临时密码: ${pw}\n有效期: ${mins} 分钟\n登录后请立即修改。`,
  };
  return m[lang] || m.en;
}
function htmlWrap(title, codeBlock, note) {
  return `<!DOCTYPE html><html><head><meta charset="UTF-8"></head>
<body style="margin:0;padding:24px;background:#F5F6FA;font-family:-apple-system,Roboto,Helvetica,Arial,sans-serif;color:#111827;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;margin:0 auto;background:#fff;border-radius:16px;border:1px solid #E5E7EB;">
<tr><td style="padding:32px 32px 0;text-align:center;"><div style="font-size:24px;font-weight:800;">Thiscount</div>
<div style="font-size:13px;color:#6B7280;margin-top:6px;">${title}</div></td></tr>
<tr><td style="padding:24px 32px 8px;text-align:center;">${codeBlock}</td></tr>
<tr><td style="padding:8px 32px 32px;text-align:center;font-size:13px;color:#374151;line-height:1.6;">${note}</td></tr>
</table></body></html>`;
}

async function sendResend(apiKey, to, subject, html, text) {
  const r = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({ from: RESEND_FROM, to: [to], subject, html, text }),
  });
  return r.ok;
}

// ── sendAuthEmail: 인증된 사용자에게 OTP/임시비번 메일 발송 ───────────────────
exports.sendAuthEmail = onRequest(
  { secrets: [RESEND_API_KEY], cors: false, region: "us-central1" },
  async (req, res) => {
    if (req.method !== "POST") return bad(res, 405, "POST only");
    const decoded = await verifyCaller(req, res);
    if (!decoded) return;
    if (rateLimited(decoded.uid)) return bad(res, 429, "rate limited");

    const { type, to, code, expiresInMinutes, langCode } = req.body || {};
    const lang = typeof langCode === "string" ? langCode : "en";
    if (!EMAIL_RE.test(to || "")) return bad(res, 400, "bad email");

    let subject, html, text;
    if (type === "otp") {
      if (!OTP_RE.test(code || "")) return bad(res, 400, "bad code");
      subject = otpSubject(lang);
      text = otpText(code, lang);
      html = htmlWrap(subject,
        `<div style="font-size:36px;font-weight:800;letter-spacing:10px;background:#F3F4F6;border:2px solid #111827;border-radius:12px;padding:18px 12px;display:inline-block;min-width:220px;">${code}</div>`,
        text.replace(/\n/g, "<br>"));
    } else if (type === "tempPassword") {
      if (!TEMP_PW_RE.test(code || "")) return bad(res, 400, "bad code");
      const mins = Number.isFinite(+expiresInMinutes) ? +expiresInMinutes : 30;
      subject = tempSubject(lang);
      text = tempText(code, mins, lang);
      html = htmlWrap(subject,
        `<div style="display:inline-block;padding:14px 22px;font-size:24px;font-weight:800;letter-spacing:2px;background:#F3F4F6;border-radius:12px;">${code}</div>`,
        text.replace(/\n/g, "<br>"));
    } else {
      return bad(res, 400, "bad type");
    }

    try {
      const ok = await sendResend(RESEND_API_KEY.value(), to, subject, html, text);
      if (!ok) {
        logger.warn("resend send failed", { uid: decoded.uid });
        return bad(res, 502, "send failed");
      }
      return res.json({ ok: true });
    } catch (e) {
      logger.error("sendAuthEmail error", e);
      return bad(res, 500, "internal");
    }
  }
);

// ── sendAuthSms: 인증된 사용자에게 OTP SMS 발송 (Twilio) ──────────────────────
exports.sendAuthSms = onRequest(
  { secrets: [TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN], cors: false, region: "us-central1" },
  async (req, res) => {
    if (req.method !== "POST") return bad(res, 405, "POST only");
    const decoded = await verifyCaller(req, res);
    if (!decoded) return;
    if (rateLimited(decoded.uid)) return bad(res, 429, "rate limited");

    const { to, code, langCode } = req.body || {};
    const lang = typeof langCode === "string" ? langCode : "en";
    if (!/^\+?[0-9]{7,15}$/.test(to || "")) return bad(res, 400, "bad phone");
    if (!OTP_RE.test(code || "")) return bad(res, 400, "bad code"); // SMS 는 OTP 만
    if (!TWILIO_FROM) return bad(res, 500, "sms not configured");

    const body = (otpText(code, lang).split("\n")[0]) || `Thiscount: ${code}`;
    const sid = TWILIO_ACCOUNT_SID.value();
    const tok = TWILIO_AUTH_TOKEN.value();
    const creds = Buffer.from(`${sid}:${tok}`).toString("base64");
    try {
      const r = await fetch(
        `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,
        {
          method: "POST",
          headers: {
            Authorization: `Basic ${creds}`,
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: new URLSearchParams({ To: to, From: TWILIO_FROM, Body: body }),
        }
      );
      if (!r.ok) return bad(res, 502, "send failed");
      return res.json({ ok: true });
    } catch (e) {
      logger.error("sendAuthSms error", e);
      return bad(res, 500, "internal");
    }
  }
);

// ── generateCoupon: AI 쿠폰 생성 (ko→Solar 국산 / 그 외→Gemini Flash) ─────────
//
// WHY: 매장(Brand)이 업종·목표만 입력하면 LLM 이 쿠폰 카피/혜택을 생성 → 매장
//   진입장벽↓ (양면시장 콜드스타트 완화) + AI 특화(지원사업). LLM 키는 서버에만.
//
// 라우팅: langCode==='ko' → Upstage Solar(국산), 그 외 → Google Gemini 2.5 Flash
//   (무료티어 + 최저가). 둘 다 OpenAI/REST 호환.
//
// 콘텐츠 모델 정합: type = general(일반홍보)/coupon(할인권)/voucher(교환권),
//   category = cafe/food/beauty/fashion/it/event/other.
//
// DEPLOY:
//   firebase functions:secrets:set SOLAR_API_KEY     # console.upstage.ai
//   firebase functions:secrets:set GEMINI_API_KEY    # aistudio.google.com (무료)
//   firebase deploy --only functions:generateCoupon
//   # 함수 URL 을 클라 빌드에 주입: --dart-define=COUPON_AI_FN_URL=<url>

const TYPE_LABEL = {
  general: "일반 홍보 (할인/교환 없이 매장·이벤트·신메뉴 알림. 혜택 문구 없음)",
  coupon: "할인권 (예: 전 메뉴 20% 할인, 1만원 이상 2천원 할인)",
  voucher: "교환권 (예: 아메리카노 1잔 무료, 사이드 메뉴 증정)",
};
const CAT_LABEL = {
  cafe: "카페", food: "식당/음식", beauty: "뷰티/미용", fashion: "패션/의류",
  it: "IT/전자", event: "행사/이벤트", other: "기타",
};

function buildCouponPrompt({ businessName, businessDesc, type, category, langCode }) {
  const t = TYPE_LABEL[type] || TYPE_LABEL.coupon;
  const c = CAT_LABEL[category] || CAT_LABEL.other;
  const lang = langCode === "ko" ? "한국어" :
    (langCode === "ja" ? "일본어" : langCode === "zh" ? "중국어" : "영어");
  return `너는 하이퍼로컬 쿠폰 마케팅 카피라이터다. 아래 매장을 위한 ${type === "general" ? "홍보" : "쿠폰"} 1건을 만든다.
매장명: ${businessName || "(미입력)"}
업종: ${c}
설명/목표: ${businessDesc || "(미입력)"}
종류: ${t}
출력 언어: ${lang}

규칙:
- title: 25자 이내, 눈길 끄는 한 줄.
- body: 80자 이내, 따뜻하고 구체적인 홍보 문구. 과장·허위·의료/효능 단정 금지.
- redemptionInfo: ${type === "general" ? "빈 문자열\"\" (일반 홍보는 혜택 없음)" : "실제 제공 혜택 한 줄 (예: \"아메리카노 1잔 무료\" 또는 \"전 메뉴 20% 할인\"). 매장이 감당 가능한 현실적 수준."}
- 반드시 아래 JSON 만 출력 (코드펜스/설명 금지):
{"title":"...","body":"...","redemptionInfo":"..."}`;
}

function parseLooseJson(text) {
  if (!text) return null;
  let s = String(text).trim();
  // 코드펜스 제거
  s = s.replace(/^```(?:json)?/i, "").replace(/```$/i, "").trim();
  const a = s.indexOf("{"), b = s.lastIndexOf("}");
  if (a >= 0 && b > a) s = s.slice(a, b + 1);
  try {
    const o = JSON.parse(s);
    return {
      title: String(o.title || "").slice(0, 60),
      body: String(o.body || "").slice(0, 300),
      redemptionInfo: String(o.redemptionInfo || "").slice(0, 200),
    };
  } catch (_) { return null; }
}

// ⚠️ ko→Solar(국산) 도입 시 복원할 함수 (현재 미사용 — 전 언어 Gemini):
// async function callSolar(prompt) {
//   const r = await fetch("https://api.upstage.ai/v1/solar/chat/completions", {
//     method: "POST",
//     headers: { Authorization: `Bearer ${SOLAR_API_KEY.value()}`,
//       "Content-Type": "application/json" },
//     body: JSON.stringify({ model: "solar-pro2",
//       messages: [{ role: "user", content: prompt }], temperature: 0.8,
//       response_format: { type: "json_object" } }),
//   });
//   if (!r.ok) throw new Error(`solar ${r.status}`);
//   const d = await r.json();
//   return d.choices?.[0]?.message?.content || "";
// }

async function callGemini(prompt) {
  const r = await fetch(
    "https://generativelanguage.googleapis.com/v1beta/models/" +
      // gemini-2.0-flash 는 신규 사용자 단종 → 2.5-flash 사용(현행, 초저가).
      `gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY.value()}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.8, responseMimeType: "application/json" },
      }),
    }
  );
  if (!r.ok) throw new Error(`gemini ${r.status}`);
  const d = await r.json();
  return d.candidates && d.candidates[0] && d.candidates[0].content &&
    d.candidates[0].content.parts && d.candidates[0].content.parts[0]
    ? d.candidates[0].content.parts[0].text : "";
}

exports.generateCoupon = onRequest(
  { secrets: [GEMINI_API_KEY], cors: false, region: "us-central1" },
  async (req, res) => {
    if (req.method !== "POST") return bad(res, 405, "POST only");
    const decoded = await verifyCaller(req, res);
    if (!decoded) return;
    if (rateLimited(decoded.uid)) return bad(res, 429, "rate limited");

    const body = req.body || {};
    const type = ["general", "coupon", "voucher"].includes(body.type)
      ? body.type : "coupon";
    const category = Object.keys(CAT_LABEL).includes(body.category)
      ? body.category : "other";
    const langCode = typeof body.langCode === "string" ? body.langCode : "en";
    const input = {
      businessName: String(body.businessName || "").slice(0, 60),
      businessDesc: String(body.businessDesc || "").slice(0, 300),
      type, category, langCode,
    };
    const prompt = buildCouponPrompt(input);
    try {
      // 현재: 전 언어 Gemini Flash(무료/최저가) 단일.
      //   (ko→Solar 도입 시: langCode === "ko" ? await callSolar(prompt) : ...)
      const raw = await callGemini(prompt);
      const parsed = parseLooseJson(raw);
      if (!parsed) return bad(res, 502, "generation failed");
      return res.json({ ok: true, type, category, ...parsed });
    } catch (e) {
      logger.error("generateCoupon error", e);
      return bad(res, 502, "llm error");
    }
  }
);

// ── deleteMyData: GDPR Art.17 서버 hard-delete (owner 검증, Phase 3 게이트) ────
//
// WHY: 탈퇴 시 client best-effort REST 는 firestore.rules 한계로 본인 letters/
//   문서를 완전 삭제 못 한다. 이 함수가 Admin SDK(룰 우회)로 users/{userId} +
//   해당 사용자의 letters(senderId==userId) 를 확실히 삭제한다.
//
// 보안: 익명 auth 환경에선 "누가 이 userId 의 주인인지" 서버가 검증 불가 →
//   self-serve 삭제 엔드포인트는 타인 데이터 삭제(griefing) 위험. 따라서
//   **owner 검증 = users/{userId}.authUid == 호출자 ID토큰 uid** 를 요구한다.
//   Phase 3(authUid 바인딩) 전까진 authUid 가 없어 거부(=안전, 단 삭제 불가).
//   Phase 3 cutover 후 정상 동작. docs/AUTH_PHASE3_CUTOVER_RUNBOOK.md
//
// DEPLOY: firebase deploy --only functions:deleteMyData
exports.deleteMyData = onRequest(
  { cors: false, region: "us-central1" },
  async (req, res) => {
    if (req.method !== "POST") return bad(res, 405, "POST only");
    const decoded = await verifyCaller(req, res);
    if (!decoded) return;
    const { userId } = req.body || {};
    if (typeof userId !== "string" || !userId.match(/^[a-zA-Z0-9_-]{8,64}$/)) {
      return bad(res, 400, "bad userId");
    }
    try {
      const db = admin.firestore();
      const userRef = db.collection("users").doc(userId);
      const snap = await userRef.get();
      // owner 검증: authUid 바인딩된 본인만. 미바인딩(Phase 3 전) → 거부.
      if (!snap.exists) return res.json({ ok: true, alreadyGone: true });
      const authUid = snap.get("authUid");
      if (!authUid || authUid !== decoded.uid) {
        return bad(res, 403, "not owner (authUid mismatch — Phase 3 필요)");
      }
      // 1) 본인 letters 삭제 (비익명만 senderId==userId; 익명은 추적 불가/무PII).
      let deleted = 0;
      while (true) {
        const batch = db.batch();
        const q = await db.collection("letters")
            .where("senderId", "==", userId).limit(300).get();
        if (q.empty) break;
        q.docs.forEach((d) => batch.delete(d.ref));
        await batch.commit();
        deleted += q.size;
        if (q.size < 300) break;
      }
      // 2) user 문서 삭제.
      await userRef.delete();
      logger.info("deleteMyData done", { userId, letters: deleted });
      return res.json({ ok: true, lettersDeleted: deleted });
    } catch (e) {
      logger.error("deleteMyData error", e);
      return bad(res, 500, "internal");
    }
  }
);

// ── revenueCatWebhook: 결제 grant 서버 권위 부여 (sim200 P0-A 근본 해결) ───────
//
// WHY: ExactDrop/추가발송권 크레딧 '증가(grant)'는 firestore.rules 의
//   isReasonableUserCounterDelta 가 self-mint(결제 우회) 차단 위해 client write
//   를 막는다(감소만 허용). 따라서 grant 는 반드시 서버 권위로만 해야 한다.
//   이 함수가 RevenueCat 결제 webhook 을 받아 Admin SDK(룰 우회)로 users/{uid}
//   의 크레딧을 원자적으로 증가시킨다. RC app_user_id = 앱 userId (Purchases.logIn).
//
// DEPLOY:
//   firebase functions:secrets:set RC_WEBHOOK_AUTH   # 임의의 긴 무작위 문자열
//   firebase deploy --only functions:revenueCatWebhook
//   # RC 대시보드 → Project → Integrations → Webhooks:
//   #   URL  = https://us-central1-lettergo-147eb.cloudfunctions.net/revenueCatWebhook
//   #   Authorization header = (위 RC_WEBHOOK_AUTH 와 동일 값)
//
// 멱등성: event.id 로 purchaseClaims/{id} create-if-absent → 재전송(at-least-once)
//   webhook 이 중복 grant 하지 않도록 보장.

// product_id → 부여할 크레딧 (substring 매칭 — ios/android/legacy id 모두 커버).
function grantForProduct(productId) {
  const p = (productId || "").toLowerCase();
  if (p.includes("exact_drop_500")) return { field: "brandExactDropCredits", amount: 500 };
  if (p.includes("exact_drop_100")) return { field: "brandExactDropCredits", amount: 100 };
  if (p.includes("exact_drop_50")) return { field: "brandExactDropCredits", amount: 50 };
  if (p.includes("brand_extra_1000")) return { field: "brandExtraMonthlyQuota", amount: 1000 };
  return null; // premium/brand 구독은 아래 subTierForEvent 로 tier set/revoke 처리.
}

// Build 442 (sim100 #2/#6): 구독 product/entitlement → tier('brand'|'premium').
//   RC v2 webhook 의 entitlement_ids(배열) 우선, 없으면 product_id substring.
//   매출 무결성: Brand 구독 만료/환불 시 서버 isBrand=false 권위 강등을 위해 필요.
function subTierForEvent(productId, entitlementIds, entitlementId) {
  const ents = [];
  if (Array.isArray(entitlementIds)) {
    for (const e of entitlementIds) ents.push(String(e || "").toLowerCase());
  }
  if (typeof entitlementId === "string") ents.push(entitlementId.toLowerCase());
  if (ents.includes("brand")) return "brand";
  if (ents.includes("premium")) return "premium";
  const p = String(productId || "").toLowerCase();
  if (p.includes("brand")) return "brand";
  if (p.includes("premium")) return "premium";
  return null;
}

exports.revenueCatWebhook = onRequest(
  { secrets: [RC_WEBHOOK_AUTH], cors: false, region: "us-central1" },
  async (req, res) => {
    if (req.method !== "POST") return bad(res, 405, "POST only");
    // 1) webhook 인증 — RC 가 보내는 Authorization 헤더가 우리 비밀과 일치해야.
    const expected = RC_WEBHOOK_AUTH.value();
    if (!expected || (req.get("Authorization") || "") !== expected) {
      return bad(res, 401, "unauthorized");
    }
    const event = (req.body && req.body.event) || {};
    const type = event.type;
    const productId = event.product_id;
    const appUserId = event.app_user_id;
    const eventId = event.id;

    // uid/event id 가드 (공통).
    if (typeof appUserId !== "string" || appUserId.length < 3 ||
        appUserId.startsWith("$RCAnonymousID")) {
      return res.json({ ok: true, skipped: "anon-or-bad-uid" });
    }
    if (typeof eventId !== "string" || !eventId) {
      return bad(res, 400, "missing event id");
    }

    // 2) 이벤트 분류.
    //   SET: 구매/갱신/상품변경/취소철회 → 구독 tier 활성 + revoke 마커 삭제,
    //        consumable 크레딧 grant.
    //   REVOKE: 만료 → 구독 tier 강등 + revoke 마커 기록(환불은 EXPIRATION 후행).
    //   CANCELLATION(자동갱신 OFF)은 만료 전까지 접근 유지 → tier 무변경.
    const SET_TYPES = [
      "INITIAL_PURCHASE", "NON_RENEWING_PURCHASE", "RENEWAL",
      "PRODUCT_CHANGE", "UNCANCELLATION",
    ];
    const REVOKE_TYPES = ["EXPIRATION"];
    const grant = grantForProduct(productId);
    const tier = subTierForEvent(
      productId, event.entitlement_ids, event.entitlement_id,
    );
    const isSet = SET_TYPES.includes(type);
    const isRevoke = REVOKE_TYPES.includes(type);
    if (!isSet && !isRevoke) return res.json({ ok: true, skipped: type });

    try {
      const db = admin.firestore();
      const FV = admin.firestore.FieldValue;
      // 3) 멱등성 — 이미 처리한 event.id 면 skip.
      const claimRef = db.collection("purchaseClaims").doc(eventId);
      const userRef = db.collection("users").doc(appUserId);
      const result = await db.runTransaction(async (tx) => {
        const claim = await tx.get(claimRef);
        if (claim.exists) return { dup: true }; // 중복 webhook
        const patch = {};
        const actions = [];
        // (a) consumable 크레딧 grant — 구매성 이벤트만.
        if (grant && isSet) {
          patch[grant.field] = FV.increment(grant.amount);
          actions.push(`grant:${grant.field}+${grant.amount}`);
        }
        // (b) 구독 tier 활성(재구독/갱신/업그레이드) — revoke 마커 삭제로 client
        //     오강등 방지. Brand 는 Premium 포함.
        if (tier && isSet) {
          if (tier === "brand") {
            patch.isBrand = true;
            patch.isPremium = true;
            patch.brandEntitlementRevokedAt = FV.delete();
            patch.premiumEntitlementRevokedAt = FV.delete();
          } else {
            patch.isPremium = true;
            patch.premiumEntitlementRevokedAt = FV.delete();
          }
          actions.push(`set:${tier}`);
        }
        // (c) 구독 tier 강등(만료/환불) — 서버 권위 false + revoke 마커. client
        //     _restoreProfileFromServer 가 마커 존재 시에만 로컬 강등 수용.
        if (tier && isRevoke) {
          const now = FV.serverTimestamp();
          if (tier === "brand") {
            patch.isBrand = false;
            patch.brandEntitlementRevokedAt = now;
          } else {
            patch.isPremium = false;
            patch.premiumEntitlementRevokedAt = now;
          }
          actions.push(`revoke:${tier}`);
        }
        if (Object.keys(patch).length === 0) return { skipped: "no-op" };
        tx.set(claimRef, {
          appUserId, productId, type, actions,
          at: FV.serverTimestamp(),
        });
        tx.set(userRef, patch, { merge: true });
        return { actions };
      });
      return res.json({ ok: true, ...result });
    } catch (e) {
      logger.error("revenueCatWebhook error", e);
      return bad(res, 500, "internal");
    }
  }
);
