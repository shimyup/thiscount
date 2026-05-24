#!/usr/bin/env python3
"""Build 324: ExactDrop 100 promo square image (1024×1024).

용도:
- App Store Connect IAP "App Store Promotions" 섹션 첨부 이미지 (1024x1024 권장)
- 마케팅 SNS 카드 (Instagram / Twitter / KakaoTalk)
- ExactDrop 기능 설명 자료

사용법:
    python3 scripts/generate_exact_drop_promo_1024.py
    python3 scripts/generate_exact_drop_promo_1024.py --lang en
    python3 scripts/generate_exact_drop_promo_1024.py --all

출력:
    docs/release/iap_screenshot_guides/exact_drop_100_promo_1024{_lang}.png
"""
from __future__ import annotations

import argparse
import math
import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Pillow 필요. 설치: pip install Pillow", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "docs" / "release" / "iap_screenshot_guides"

SIZE = 1024

# 색 (lib/core/theme/app_theme.dart 와 일치)
BG_DEEP = (10, 10, 15)
BG_CARD = (28, 28, 36)
GOLD = (255, 215, 0)
GOLD_DIM = (140, 110, 0)
RED = (220, 80, 70)
TEXT_PRIMARY = (255, 255, 255)
TEXT_SECONDARY = (176, 176, 184)
TEXT_DARK = (26, 19, 0)

# 카피
COPY = {
    "ko": {
        "headline": "ExactDrop",
        "tagline": "정확한 매장 좌표에 혜택을 뿌리세요",
        "count_label": "100통",
        "price": "₩10,000",
        "badge": "BRAND ONLY",
        "footer": "1회 구매 · 영구 사용",
    },
    "en": {
        "headline": "ExactDrop",
        "tagline": "Drop rewards on exact store locations",
        "count_label": "100",
        "price": "₩10,000",
        "badge": "BRAND ONLY",
        "footer": "One-time purchase · No expiry",
    },
    "ja": {
        "headline": "ExactDrop",
        "tagline": "正確な店舗座標に特典を配信",
        "count_label": "100通",
        "price": "₩10,000",
        "badge": "BRAND ONLY",
        "footer": "1回購入 · 永久使用",
    },
    "zh": {
        "headline": "ExactDrop",
        "tagline": "在指定门店坐标投放优惠",
        "count_label": "100次",
        "price": "₩10,000",
        "badge": "BRAND ONLY",
        "footer": "一次购买 · 永久使用",
    },
}

FONT_CANDIDATES = [
    "/System/Library/Fonts/AppleSDGothicNeo.ttc",
    "/System/Library/Fonts/Supplemental/AppleGothic.ttf",
    "/System/Library/Fonts/PingFang.ttc",
    "/System/Library/Fonts/Hiragino Sans GB.ttc",
    "/Library/Fonts/Arial Unicode.ttf",
    "/System/Library/Fonts/Helvetica.ttc",
]


def find_font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
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


def draw_centered_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    y: int,
    font: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int],
) -> int:
    """가운데 정렬 텍스트 draw. 반환 = text 높이."""
    bbox = draw.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    draw.text(((SIZE - w) // 2, y), text, font=font, fill=fill)
    return h


def render_promo(lang: str = "ko") -> Path:
    if lang not in COPY:
        raise ValueError(f"Unsupported lang: {lang}. {list(COPY.keys())}")

    img = Image.new("RGB", (SIZE, SIZE), BG_DEEP)
    draw = ImageDraw.Draw(img, "RGBA")

    # ── 배경 — radial gradient (gold soft glow 중심 → 검정 외곽) ─────────────
    grad = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    grad_draw = ImageDraw.Draw(grad)
    cx, cy = SIZE // 2, SIZE // 2 - 80  # target 중심 위쪽
    for r in range(SIZE // 2, 0, -8):
        alpha = int(60 * (1 - r / (SIZE // 2)))
        if alpha <= 0:
            continue
        grad_draw.ellipse(
            (cx - r, cy - r, cx + r, cy + r),
            fill=(255, 215, 0, alpha),
        )
    img = Image.alpha_composite(img.convert("RGBA"), grad).convert("RGB")
    draw = ImageDraw.Draw(img, "RGBA")

    # ── 중앙 동심원 (🎯 target) ─────────────────────────────────────────────
    target_cx, target_cy = SIZE // 2, 380
    for radius, color in [
        (200, (255, 215, 0, 70)),
        (155, (255, 215, 0, 110)),
        (120, (220, 80, 70, 230)),
        (90, (255, 215, 0, 230)),
        (55, (220, 80, 70, 255)),
        (24, (255, 255, 255, 230)),
    ]:
        overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        ImageDraw.Draw(overlay).ellipse(
            (target_cx - radius, target_cy - radius, target_cx + radius, target_cy + radius),
            fill=color,
        )
        img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    draw = ImageDraw.Draw(img, "RGBA")

    # ── 헤드라인 "ExactDrop" ────────────────────────────────────────────────
    font_head = find_font(110, "heavy")
    h = draw_centered_text(draw, COPY[lang]["headline"], 620, font_head, TEXT_PRIMARY)

    # ── 100통 + 가격 (한 줄) ────────────────────────────────────────────────
    count_text = COPY[lang]["count_label"]
    price_text = COPY[lang]["price"]
    combined = f"{count_text}  ·  {price_text}"
    font_combined = find_font(72, "bold")
    draw_centered_text(draw, combined, 760, font_combined, GOLD)

    # ── tagline ──────────────────────────────────────────────────────────
    font_tag = find_font(36, "regular")
    draw_centered_text(draw, COPY[lang]["tagline"], 860, font_tag, TEXT_SECONDARY)

    # ── 상단 BRAND ONLY 뱃지 ────────────────────────────────────────────────
    badge_text = COPY[lang]["badge"]
    font_badge = find_font(30, "heavy")
    bbox = draw.textbbox((0, 0), badge_text, font=font_badge)
    bw = bbox[2] - bbox[0]
    badge_pad = 32
    badge_x = (SIZE - bw - badge_pad * 2) // 2
    badge_y = 80
    badge_h = 56
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(overlay).rounded_rectangle(
        (badge_x, badge_y, badge_x + bw + badge_pad * 2, badge_y + badge_h),
        radius=999,
        fill=(220, 80, 70, 220),
    )
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    draw = ImageDraw.Draw(img, "RGBA")
    draw.text(
        (badge_x + badge_pad, badge_y + 13),
        badge_text,
        font=font_badge,
        fill=TEXT_PRIMARY,
    )

    # ── 하단 footer ────────────────────────────────────────────────────────
    font_footer = find_font(28, "regular")
    bbox = draw.textbbox((0, 0), COPY[lang]["footer"], font=font_footer)
    fw = bbox[2] - bbox[0]
    draw.text(
        ((SIZE - fw) // 2, SIZE - 70),
        COPY[lang]["footer"],
        font=font_footer,
        fill=TEXT_SECONDARY,
    )

    # ── 저장 ────────────────────────────────────────────────────────────
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    suffix = "" if lang == "ko" else f"_{lang}"
    out_path = OUT_DIR / f"exact_drop_100_promo_1024{suffix}.png"
    img.save(out_path, "PNG", optimize=True)
    return out_path


def main() -> int:
    parser = argparse.ArgumentParser(
        description="ExactDrop 100 promo 1024x1024 PNG 생성"
    )
    parser.add_argument("--lang", choices=list(COPY.keys()), default="ko")
    parser.add_argument("--all", action="store_true")
    args = parser.parse_args()

    if args.all:
        for lang in COPY.keys():
            out = render_promo(lang)
            kb = out.stat().st_size // 1024
            print(f"✅ {lang}: {out} ({kb} KB)")
    else:
        out = render_promo(args.lang)
        kb = out.stat().st_size // 1024
        print(f"✅ {out} ({kb} KB)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
