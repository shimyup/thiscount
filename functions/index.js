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
  return null; // premium/brand 구독은 entitlement(RC)로 처리 — 크레딧 grant 아님.
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

    // 2) consumable 결제 이벤트만 grant. 구독/취소/환불 등은 무시(RC entitlement).
    const GRANT_TYPES = ["INITIAL_PURCHASE", "NON_RENEWING_PURCHASE", "RENEWAL"];
    if (!GRANT_TYPES.includes(type)) return res.json({ ok: true, skipped: type });

    const grant = grantForProduct(productId);
    if (!grant) return res.json({ ok: true, skipped: "no-credit-product" });
    if (typeof appUserId !== "string" || appUserId.length < 3 ||
        appUserId.startsWith("$RCAnonymousID")) {
      return res.json({ ok: true, skipped: "anon-or-bad-uid" });
    }
    if (typeof eventId !== "string" || !eventId) {
      return bad(res, 400, "missing event id");
    }

    try {
      const db = admin.firestore();
      // 3) 멱등성 — 이미 처리한 event.id 면 skip.
      const claimRef = db.collection("purchaseClaims").doc(eventId);
      const userRef = db.collection("users").doc(appUserId);
      const granted = await db.runTransaction(async (tx) => {
        const claim = await tx.get(claimRef);
        if (claim.exists) return false; // 중복 webhook
        tx.set(claimRef, {
          appUserId, productId, field: grant.field, amount: grant.amount,
          type, at: admin.firestore.FieldValue.serverTimestamp(),
        });
        tx.set(userRef, {
          [grant.field]: admin.firestore.FieldValue.increment(grant.amount),
        }, { merge: true });
        return true;
      });
      return res.json({ ok: true, granted, field: grant.field, amount: grant.amount });
    } catch (e) {
      logger.error("revenueCatWebhook error", e);
      return bad(res, 500, "internal");
    }
  }
);
