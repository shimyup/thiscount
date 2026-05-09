#!/usr/bin/env python3
"""
Build 270: Master 아이콘에서 iOS / Android 모든 크기 재생성.

입력: assets/branding/app_icon_master.png (1024×1024 RGBA)
출력:
  - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png (15종)
    · 1024@1x 는 Apple App Store 규정상 alpha 제거 (검정 배경 합성)
    · 나머지는 RGBA 유지
  - android/app/src/main/res/mipmap-{mdpi..xxxhdpi}/ic_launcher.png (5종)

masking / adaptive icon 분리는 별도 작업 (foreground 추출 필요).
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).parent.parent
MASTER = ROOT / 'assets' / 'branding' / 'app_icon_master.png'

assert MASTER.exists(), f'master not found: {MASTER}'

src = Image.open(MASTER).convert('RGBA')
assert src.size == (1024, 1024), f'expected 1024x1024, got {src.size}'

# iOS 사이즈 매핑 — (filename, pixel_size, strip_alpha)
ios_specs = [
    ('Icon-App-20x20@1x.png', 20, False),
    ('Icon-App-20x20@2x.png', 40, False),
    ('Icon-App-20x20@3x.png', 60, False),
    ('Icon-App-29x29@1x.png', 29, False),
    ('Icon-App-29x29@2x.png', 58, False),
    ('Icon-App-29x29@3x.png', 87, False),
    ('Icon-App-40x40@1x.png', 40, False),
    ('Icon-App-40x40@2x.png', 80, False),
    ('Icon-App-40x40@3x.png', 120, False),
    ('Icon-App-60x60@2x.png', 120, False),
    ('Icon-App-60x60@3x.png', 180, False),
    ('Icon-App-76x76@1x.png', 76, False),
    ('Icon-App-76x76@2x.png', 152, False),
    ('Icon-App-83.5x83.5@2x.png', 167, False),
    ('Icon-App-1024x1024@1x.png', 1024, True),  # App Store: no alpha
]

ios_dir = ROOT / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset'
for name, size, strip_alpha in ios_specs:
    img = src.resize((size, size), Image.LANCZOS)
    if strip_alpha:
        # App Store 거부 회피 — 알파 검정 배경에 합성 후 RGB 저장.
        # master 가 이미 검정 둥근 사각 안이라 시각 차이 없음.
        bg = Image.new('RGB', (size, size), (0, 0, 0))
        bg.paste(img, mask=img.split()[3])
        bg.save(ios_dir / name, 'PNG', optimize=True)
    else:
        img.save(ios_dir / name, 'PNG', optimize=True)
    print(f'[ios] {name} ({size}×{size}{" RGB" if strip_alpha else " RGBA"})')

# Android 사이즈 매핑
android_specs = [
    ('mipmap-mdpi', 48),
    ('mipmap-hdpi', 72),
    ('mipmap-xhdpi', 96),
    ('mipmap-xxhdpi', 144),
    ('mipmap-xxxhdpi', 192),
]

android_dir = ROOT / 'android' / 'app' / 'src' / 'main' / 'res'
for bucket, size in android_specs:
    img = src.resize((size, size), Image.LANCZOS)
    out = android_dir / bucket / 'ic_launcher.png'
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, 'PNG', optimize=True)
    print(f'[android] {bucket}/ic_launcher.png ({size}×{size})')

print('\n✓ done')
