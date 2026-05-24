#!/usr/bin/env python3
"""Build 324: ExactDrop 100 paywall mockup PNG generator.

ASC 심사용 임시 스크린샷 (1284x2778, iPhone 14 Pro Max 해상도).
실제 sandbox 빌드에서 캡처한 PNG 로 추후 교체 권장. Pillow 만으로 자동 생성
가능 → CI / 새 i18n 추가 시 재생성 용이.

사용법:
    python3 scripts/generate_exact_drop_paywall_mockup.py
    # → docs/release/iap_screenshot_guides/exact_drop_100_paywall.png

옵션 (다른 언어 mockup):
    python3 scripts/generate_exact_drop_paywall_mockup.py --lang en
    # → docs/release/iap_screenshot_guides/exact_drop_100_paywall_en.png
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Pillow 가 필요합니다. 설치: pip install Pillow", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "docs" / "release" / "iap_screenshot_guides"

# iPhone 14 Pro Max 해상도 (ASC 권장).
W, H = 1284, 2778

# App color palette (lib/core/theme/app_theme.dart 와 일치).
BG_DEEP = (10, 10, 15)          # AppColors.bgDeep
BG_CARD = (28, 28, 36)          # AppColors.bgCard
BG_SURFACE = (38, 38, 48)       # AppColors.bgSurface
GOLD = (255, 215, 0)            # AppColors.gold
TEXT_PRIMARY = (255, 255, 255)
TEXT_SECONDARY = (176, 176, 184)
TEXT_MUTED = (107, 107, 114)
DIALOG_GOLD_BG = (255, 215, 0, 30)  # gold alpha 0.12

# 14언어 카피 (앱의 i18n 과 일치).
# emoji 는 Pillow 가 Apple Color Emoji 못 그려서 □ 박스로 나옴 → 단순 텍스트만.
# 실 sandbox 캡처 PNG 로 추후 교체 시 emoji 정상 렌더링.
COPY = {
    "ko": {
        "status_bar_time": "9:41",
        "scenario_chip": "정확 좌표 단건",
        "scenario_label": "어떤 캠페인이에요?",
        "title": "정확 좌표 드롭은 유료 기능이에요",
        "body": "원하는 매장·좌표에 혜택을 정확히 뿌릴 수 있어요. 아래 버튼으로 100통 패키지를 바로 구매하세요.",
        "price_label": "100통 패키지 · 10,000원",
        "close": "닫기",
        "buy": "100통 구매 (₩10,000)",
        "compose_header": "브랜드 옵션",
        "subcopy": "구매 후 자동으로 ExactDrop 핀 선택 화면 진입",
        "chip_nearby": "매장 반경 살포",
    },
    "en": {
        "status_bar_time": "9:41",
        "scenario_chip": "Exact location",
        "scenario_label": "What kind of campaign?",
        "title": "Exact-coordinate drop is a paid feature",
        "body": "Drop promos on exact store locations or coordinates. Tap below to buy the 100-promo package instantly.",
        "price_label": "100-promo package - KRW 10,000",
        "close": "Close",
        "buy": "Buy 100 promos (W10,000)",
        "compose_header": "Brand options",
        "subcopy": "After purchase, ExactDrop pin selector opens automatically",
        "chip_nearby": "Around my store",
    },
    "ja": {
        "status_bar_time": "9:41",
        "scenario_chip": "正確な座標",
        "scenario_label": "どんなキャンペーン？",
        "title": "正確な座標ドロップは有料機能です",
        "body": "店舗や正確な座標に特典を配信できます。下のボタンで100通パッケージを今すぐ購入。",
        "price_label": "100通パッケージ - 10,000ウォン",
        "close": "閉じる",
        "buy": "100通購入 (₩10,000)",
        "compose_header": "ブランドオプション",
        "subcopy": "購入後 ExactDrop 選択画面に自動遷移",
        "chip_nearby": "店舗周辺",
    },
    "zh": {
        "status_bar_time": "9:41",
        "scenario_chip": "精确坐标",
        "scenario_label": "什么类型的活动？",
        "title": "精确坐标投放为付费功能",
        "body": "将优惠精确投放到指定地点或坐标。点击下方按钮立即购买100次套餐。",
        "price_label": "100次套餐 - 10,000韩元",
        "close": "关闭",
        "buy": "购买 100次 (₩10,000)",
        "compose_header": "品牌选项",
        "subcopy": "购买后自动进入ExactDrop选择界面",
        "chip_nearby": "门店周边",
    },
    "fr": {
        "status_bar_time": "9:41",
        "scenario_chip": "Position exacte",
        "scenario_label": "Quel type de campagne ?",
        "title": "Le dépôt aux coordonnées exactes est payant",
        "body": "Déposez des récompenses à des emplacements précis. Achetez le pack de 100 maintenant via le bouton.",
        "price_label": "Pack de 100 - 10 000 KRW",
        "close": "Fermer",
        "buy": "Acheter 100 (W10 000)",
        "compose_header": "Options Brand",
        "subcopy": "Après achat, le sélecteur ExactDrop s'ouvre auto",
        "chip_nearby": "Autour du magasin",
    },
    "de": {
        "status_bar_time": "9:41",
        "scenario_chip": "Genauer Ort",
        "scenario_label": "Welche Kampagne?",
        "title": "Präzise Ablage ist kostenpflichtig",
        "body": "Belohnungen an exakten Orten. Mit der Schaltfläche das 100er-Paket sofort kaufen.",
        "price_label": "100er-Paket - 10.000 KRW",
        "close": "Schließen",
        "buy": "100 kaufen (W10.000)",
        "compose_header": "Brand-Optionen",
        "subcopy": "Nach Kauf öffnet ExactDrop-Selektor automatisch",
        "chip_nearby": "Nähe Geschäft",
    },
    "es": {
        "status_bar_time": "9:41",
        "scenario_chip": "Ubicacion exacta",
        "scenario_label": "Que tipo de campaña?",
        "title": "La entrega en coordenadas exactas es de pago",
        "body": "Deja recompensas en ubicaciones exactas. Compra el paquete de 100 al instante.",
        "price_label": "Paquete de 100 - 10.000 KRW",
        "close": "Cerrar",
        "buy": "Comprar 100 (W10.000)",
        "compose_header": "Opciones Brand",
        "subcopy": "Tras la compra se abre el selector ExactDrop",
        "chip_nearby": "Cerca tienda",
    },
    "pt": {
        "status_bar_time": "9:41",
        "scenario_chip": "Local exato",
        "scenario_label": "Que tipo de campanha?",
        "title": "A entrega em coordenadas exatas e paga",
        "body": "Deixe recompensas em locais exatos. Compre o pacote de 100 agora.",
        "price_label": "Pacote de 100 - 10.000 KRW",
        "close": "Fechar",
        "buy": "Comprar 100 (W10.000)",
        "compose_header": "Opcoes Brand",
        "subcopy": "Apos compra abre o seletor ExactDrop",
        "chip_nearby": "Perto da loja",
    },
    "ru": {
        "status_bar_time": "9:41",
        "scenario_chip": "Точное место",
        "scenario_label": "Какая кампания?",
        "title": "Точная доставка — платная функция",
        "body": "Размещайте награды в точных местах. Купите пакет из 100 сейчас.",
        "price_label": "Пакет 100 - 10 000 KRW",
        "close": "Закрыть",
        "buy": "Купить 100 (W10 000)",
        "compose_header": "Опции Brand",
        "subcopy": "После покупки открывается ExactDrop",
        "chip_nearby": "Рядом магазин",
    },
    "tr": {
        "status_bar_time": "9:41",
        "scenario_chip": "Tam konum",
        "scenario_label": "Ne tur kampanya?",
        "title": "Tam koordinat teslimi ucretli",
        "body": "Odulleri belirli yerlere yerlestirin. 100 odulu hemen satin alin.",
        "price_label": "100 paket - 10.000 KRW",
        "close": "Kapat",
        "buy": "100 satin al (W10.000)",
        "compose_header": "Brand secenekleri",
        "subcopy": "Satin alma sonrasi ExactDrop acilir",
        "chip_nearby": "Magazam yakinlari",
    },
    "ar": {
        "status_bar_time": "9:41",
        "scenario_chip": "موقع دقيق",
        "scenario_label": "ما نوع الحملة؟",
        "title": "توصيل الإحداثيات الدقيقة ميزة مدفوعة",
        "body": "ضع المكافآت في مواقع دقيقة. اشتر باقة 100 الآن.",
        "price_label": "باقة 100 - 10,000 KRW",
        "close": "إغلاق",
        "buy": "اشتر 100 (W10,000)",
        "compose_header": "خيارات Brand",
        "subcopy": "بعد الشراء يفتح محدد ExactDrop",
        "chip_nearby": "قرب متجري",
    },
    "it": {
        "status_bar_time": "9:41",
        "scenario_chip": "Posizione esatta",
        "scenario_label": "Che tipo di campagna?",
        "title": "Rilascio a coordinate esatte e a pagamento",
        "body": "Rilascia ricompense in luoghi precisi. Acquista pacchetto da 100 con il pulsante.",
        "price_label": "Pacchetto da 100 - 10.000 KRW",
        "close": "Chiudi",
        "buy": "Compra 100 (W10.000)",
        "compose_header": "Opzioni Brand",
        "subcopy": "Dopo acquisto si apre selettore ExactDrop",
        "chip_nearby": "Vicino negozio",
    },
    "hi": {
        "status_bar_time": "9:41",
        "scenario_chip": "सटीक स्थान",
        "scenario_label": "किस तरह का अभियान?",
        "title": "सटीक निर्देशांक ड्रॉप एक सशुल्क सुविधा है",
        "body": "सटीक स्थानों पर पुरस्कार छोड़ें। नीचे के बटन से 100 पैकेज खरीदें।",
        "price_label": "100 पैकेज - 10,000 KRW",
        "close": "बंद",
        "buy": "100 खरीदें (W10,000)",
        "compose_header": "ब्रांड विकल्प",
        "subcopy": "खरीद के बाद ExactDrop चयनकर्ता खुलता है",
        "chip_nearby": "दुकान के पास",
    },
    "th": {
        "status_bar_time": "9:41",
        "scenario_chip": "พิกัดแน่นอน",
        "scenario_label": "แคมเปญแบบไหน?",
        "title": "การวางจุดพิกัดเป็นฟีเจอร์เสียเงิน",
        "body": "วางรางวัลที่ตำแหน่งที่แม่นยำ ซื้อแพ็ก 100 ฉบับทันที",
        "price_label": "แพ็ก 100 - 10,000 KRW",
        "close": "ปิด",
        "buy": "ซื้อ 100 (W10,000)",
        "compose_header": "ตัวเลือก Brand",
        "subcopy": "หลังซื้อเปิดตัวเลือก ExactDrop",
        "chip_nearby": "ใกล้ร้าน",
    },
}

# 시스템 폰트 후보 (macOS 우선). 없으면 default fallback.
FONT_CANDIDATES = [
    "/System/Library/Fonts/AppleSDGothicNeo.ttc",          # ko/en
    "/System/Library/Fonts/Supplemental/AppleGothic.ttf",  # ko fallback
    "/System/Library/Fonts/PingFang.ttc",                  # zh
    "/System/Library/Fonts/Hiragino Sans GB.ttc",          # ja
    "/Library/Fonts/Arial Unicode.ttf",                    # 멀티 언어 fallback
    "/System/Library/Fonts/Helvetica.ttc",                 # final fallback
]


def find_font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    """가장 먼저 발견되는 시스템 폰트 로드. weight 는 ttc index hint."""
    # AppleSDGothicNeo.ttc — 0=Regular, 1=Bold, 2=Heavy, 3=Light, 4=Medium
    weight_idx = {"regular": 0, "bold": 1, "heavy": 2, "light": 3, "medium": 4}.get(
        weight, 0
    )
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            try:
                if path.endswith(".ttc"):
                    return ImageFont.truetype(path, size, index=weight_idx)
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def wrap_text(
    text: str, font: ImageFont.FreeTypeFont, max_width: int, draw: ImageDraw.ImageDraw
) -> list[str]:
    """공백 기준 단어 wrap. CJK 는 글자 단위 wrap (공백 없어도 끊김)."""
    if not text:
        return []
    # 영문/혼합 우선 시도
    words = text.split(" ")
    lines: list[str] = []
    current: list[str] = []
    for word in words:
        trial = " ".join(current + [word])
        bbox = draw.textbbox((0, 0), trial, font=font)
        if bbox[2] - bbox[0] <= max_width:
            current.append(word)
        else:
            if current:
                lines.append(" ".join(current))
            current = [word]
    if current:
        lines.append(" ".join(current))
    # 한 줄이 max_width 초과 시 글자 단위 추가 wrap (CJK)
    final: list[str] = []
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        if bbox[2] - bbox[0] <= max_width:
            final.append(line)
        else:
            chunk = ""
            for ch in line:
                trial = chunk + ch
                bbox = draw.textbbox((0, 0), trial, font=font)
                if bbox[2] - bbox[0] <= max_width:
                    chunk = trial
                else:
                    if chunk:
                        final.append(chunk)
                    chunk = ch
            if chunk:
                final.append(chunk)
    return final


def draw_rounded_rect(
    img: Image.Image,
    bbox: tuple[int, int, int, int],
    radius: int,
    fill: tuple[int, int, int] | tuple[int, int, int, int],
    outline: tuple[int, int, int] | None = None,
    outline_width: int = 0,
) -> None:
    """PIL 의 내장 rounded_rectangle — fill + 옵션 outline."""
    draw = ImageDraw.Draw(img, "RGBA")
    draw.rounded_rectangle(bbox, radius=radius, fill=fill)
    if outline and outline_width > 0:
        draw.rounded_rectangle(bbox, radius=radius, outline=outline, width=outline_width)


def render_paywall(lang: str = "ko") -> Path:
    """paywall mockup PNG 생성. 반환 = 저장 경로."""
    if lang not in COPY:
        raise ValueError(f"Unsupported lang: {lang}. Supported: {list(COPY.keys())}")

    img = Image.new("RGB", (W, H), BG_DEEP)
    draw = ImageDraw.Draw(img)

    # ── 1. 상태 바 (시간 + 신호 + 배터리) ─────────────────────────────────────
    font_status = find_font(48, "medium")
    draw.text((68, 60), COPY[lang]["status_bar_time"], font=font_status, fill=TEXT_PRIMARY)
    # 우측: 신호 바 + WiFi + 배터리 텍스트 (emoji 없이 도형).
    draw.text(
        (W - 200, 60),
        "100%",
        font=find_font(40, "regular"),
        fill=TEXT_SECONDARY,
    )
    # 신호 dot 4개
    for i, h in enumerate([14, 22, 30, 38]):
        x = W - 360 + i * 22
        y = 60 + (40 - h) // 2 + 8
        draw.rectangle((x, y, x + 16, y + h), fill=TEXT_SECONDARY)

    # ── 2. App bar (compose 화면 헤더) ──────────────────────────────────────
    font_appbar = find_font(64, "heavy")
    # 좌측 gold dot (📣 대용)
    ImageDraw.Draw(img).ellipse((68, 200, 116, 248), fill=GOLD)
    draw.text((140, 180), COPY[lang]["compose_header"], font=font_appbar, fill=TEXT_PRIMARY)

    # ── 3. 시나리오 라벨 ───────────────────────────────────────────────────
    font_label = find_font(38, "medium")
    draw.text(
        (68, 320), COPY[lang]["scenario_label"], font=font_label, fill=TEXT_MUTED
    )

    # ── 4. 시나리오 칩 행 (2개 — emoji 없이 색·도형으로 구분) ─────────────────
    chip_y = 400
    chip_h = 80
    chip_pad_x = 28
    chip_pad_y = 14
    # 칩 1 (매장 반경) — 비활성 (회색 배경)
    chip1_text = COPY[lang]["chip_nearby"]
    font_chip = find_font(34, "bold")
    bbox = draw.textbbox((0, 0), chip1_text, font=font_chip)
    w1 = bbox[2] - bbox[0]
    chip1_bullet_w = 28  # 좌측 dot
    chip1_total_w = w1 + chip_pad_x * 2 + chip1_bullet_w
    draw_rounded_rect(
        img,
        (68, chip_y, 68 + chip1_total_w, chip_y + chip_h),
        radius=999,
        fill=BG_SURFACE,
    )
    # 좌측 파란 dot (📍 대용)
    ImageDraw.Draw(img).ellipse(
        (68 + 22, chip_y + 26, 68 + 50, chip_y + 54),
        fill=(120, 180, 255),
    )
    draw.text(
        (68 + chip_pad_x + chip1_bullet_w, chip_y + chip_pad_y + 2),
        chip1_text,
        font=font_chip,
        fill=TEXT_PRIMARY,
    )

    # 칩 2 (정확 좌표) — 현재 강조됨 (gold 배경 + 좌측 빨간 target dot)
    chip2_text = COPY[lang]["scenario_chip"]
    bbox = draw.textbbox((0, 0), chip2_text, font=font_chip)
    w2 = bbox[2] - bbox[0]
    chip2_bullet_w = 28
    chip2_total_w = w2 + chip_pad_x * 2 + chip2_bullet_w
    x2 = 68 + chip1_total_w + 18
    draw_rounded_rect(
        img,
        (x2, chip_y, x2 + chip2_total_w, chip_y + chip_h),
        radius=999,
        fill=GOLD,
    )
    # 좌측 빨간 dot (🎯 target 대용)
    ImageDraw.Draw(img).ellipse(
        (x2 + 22, chip_y + 26, x2 + 50, chip_y + 54),
        fill=(220, 80, 70),
    )
    draw.text(
        (x2 + chip_pad_x + chip2_bullet_w, chip_y + chip_pad_y + 2),
        chip2_text,
        font=font_chip,
        fill=(26, 19, 0),
    )

    # ── 5. 반투명 dim 오버레이 (다이얼로그 효과) ─────────────────────────────
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    overlay_draw.rectangle((0, 600, W, H), fill=(0, 0, 0, 140))
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    draw = ImageDraw.Draw(img)

    # ── 6. 메인 다이얼로그 (paywall) ────────────────────────────────────────
    dialog_w = 1080
    dialog_x = (W - dialog_w) // 2
    dialog_y = 850
    # 동적 높이 — 본문 줄 수에 따라.
    font_title = find_font(58, "heavy")
    font_body = find_font(44, "regular")
    font_price = find_font(50, "heavy")
    font_btn = find_font(48, "bold")

    body_lines = wrap_text(
        COPY[lang]["body"], font_body, dialog_w - 120, draw
    )
    body_line_height = 64
    body_total_h = len(body_lines) * body_line_height

    # 다이얼로그 전체 높이 계산.
    dialog_h = (
        80  # top padding
        + 80  # emoji (🎯)
        + 30
        + 80  # title
        + 50
        + body_total_h  # body
        + 60
        + 130  # price card
        + 70
        + 140  # buttons
        + 80  # bottom padding
    )

    # 다이얼로그 배경 (둥근 모서리).
    draw_rounded_rect(
        img,
        (dialog_x, dialog_y, dialog_x + dialog_w, dialog_y + dialog_h),
        radius=40,
        fill=BG_CARD,
    )

    # 6.1 아이콘 — 🎯 emoji 대신 동심원 (target) 직접 draw.
    icon_cx = W // 2
    icon_cy = dialog_y + 130
    icon_y = icon_cy - 75  # 호환성 — title_y 계산용
    for radius, color in [
        (75, (255, 215, 0, 60)),   # outer gold soft
        (55, (255, 90, 80, 200)),  # red ring outer
        (40, (255, 215, 0, 200)),  # gold ring
        (22, (255, 90, 80, 255)),  # red center
    ]:
        rect = (
            icon_cx - radius,
            icon_cy - radius,
            icon_cx + radius,
            icon_cy + radius,
        )
        draw_overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(draw_overlay).ellipse(rect, fill=color)
        img = Image.alpha_composite(img.convert("RGBA"), draw_overlay).convert("RGB")
        draw = ImageDraw.Draw(img)

    # 6.2 제목
    title_y = icon_y + 130
    bbox = draw.textbbox((0, 0), COPY[lang]["title"], font=font_title)
    title_w = bbox[2] - bbox[0]
    if title_w > dialog_w - 80:
        # wrap if too long
        title_lines = wrap_text(COPY[lang]["title"], font_title, dialog_w - 80, draw)
        for i, line in enumerate(title_lines):
            bbox = draw.textbbox((0, 0), line, font=font_title)
            tw = bbox[2] - bbox[0]
            draw.text(
                ((W - tw) // 2, title_y + i * 78),
                line,
                font=font_title,
                fill=TEXT_PRIMARY,
            )
        title_consumed = len(title_lines) * 78
    else:
        draw.text(
            ((W - title_w) // 2, title_y),
            COPY[lang]["title"],
            font=font_title,
            fill=TEXT_PRIMARY,
        )
        title_consumed = 80

    # 6.3 본문
    body_y = title_y + title_consumed + 50
    for i, line in enumerate(body_lines):
        bbox = draw.textbbox((0, 0), line, font=font_body)
        bw = bbox[2] - bbox[0]
        draw.text(
            ((W - bw) // 2, body_y + i * body_line_height),
            line,
            font=font_body,
            fill=TEXT_SECONDARY,
        )

    # 6.4 가격 카드 (gold 배경 + 💰 + 텍스트)
    price_card_y = body_y + body_total_h + 60
    price_card_h = 130
    price_card_w = dialog_w - 120
    price_card_x = (W - price_card_w) // 2
    draw_rounded_rect(
        img,
        (price_card_x, price_card_y, price_card_x + price_card_w, price_card_y + price_card_h),
        radius=24,
        fill=(255, 215, 0, 38),  # gold alpha 0.15
        outline=GOLD,
        outline_width=2,
    )
    # 💰 emoji 대신 ₩ 기호 (가운데 정렬)
    won_font = find_font(72, "heavy")
    draw.text(
        (price_card_x + 50, price_card_y + 22),
        "₩",
        font=won_font,
        fill=GOLD,
    )
    draw.text(
        (price_card_x + 130, price_card_y + 38),
        COPY[lang]["price_label"],
        font=font_price,
        fill=GOLD,
    )

    # 6.5 버튼 행 (닫기 + 100통 구매)
    btn_y = price_card_y + price_card_h + 70
    btn_h = 130
    # "닫기" 버튼 (좌측 회색 텍스트)
    bbox = draw.textbbox((0, 0), COPY[lang]["close"], font=font_btn)
    close_w = bbox[2] - bbox[0]
    close_x = dialog_x + 80
    draw.text(
        (close_x, btn_y + 40),
        COPY[lang]["close"],
        font=font_btn,
        fill=TEXT_MUTED,
    )

    # "100통 구매" 버튼 (gold)
    buy_text = COPY[lang]["buy"]
    bbox = draw.textbbox((0, 0), buy_text, font=font_btn)
    buy_w = bbox[2] - bbox[0]
    buy_btn_pad_x = 50
    buy_btn_w = buy_w + buy_btn_pad_x * 2
    buy_btn_x = dialog_x + dialog_w - 80 - buy_btn_w
    draw_rounded_rect(
        img,
        (buy_btn_x, btn_y, buy_btn_x + buy_btn_w, btn_y + btn_h),
        radius=20,
        fill=GOLD,
    )
    draw.text(
        (buy_btn_x + buy_btn_pad_x, btn_y + 38),
        buy_text,
        font=font_btn,
        fill=(26, 19, 0),
    )

    # ── 7. 하단 안내 (서브카피) ────────────────────────────────────────────
    font_subcopy = find_font(34, "regular")
    sub = COPY[lang]["subcopy"]
    bbox = draw.textbbox((0, 0), sub, font=font_subcopy)
    sub_w = bbox[2] - bbox[0]
    draw.text(
        ((W - sub_w) // 2, dialog_y + dialog_h + 60),
        sub,
        font=font_subcopy,
        fill=TEXT_MUTED,
    )

    # ── 8. 저장 ────────────────────────────────────────────────────────────
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    suffix = "" if lang == "ko" else f"_{lang}"
    out_path = OUT_DIR / f"exact_drop_100_paywall{suffix}.png"
    img.save(out_path, "PNG", optimize=True)
    return out_path


def main() -> int:
    parser = argparse.ArgumentParser(
        description="ExactDrop 100 paywall mockup PNG generator (1284x2778)"
    )
    parser.add_argument(
        "--lang",
        choices=list(COPY.keys()),
        default="ko",
        help="Mockup 언어 (기본 ko). en/ja 지원.",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="모든 지원 언어 (ko/en/ja) 동시 생성.",
    )
    args = parser.parse_args()

    if args.all:
        for lang in COPY.keys():
            out = render_paywall(lang)
            size_kb = out.stat().st_size // 1024
            print(f"✅ {lang}: {out} ({size_kb} KB)")
    else:
        out = render_paywall(args.lang)
        size_kb = out.stat().st_size // 1024
        print(f"✅ {out} ({size_kb} KB)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
