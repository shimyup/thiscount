import 'package:flutter/material.dart';

class V5Colors {
  static const bg = Color(0xFF000000);
  static const bg1 = Color(0xFF0A0A0C);
  static const bg2 = Color(0xFF141417);
  static const bg3 = Color(0xFF1C1C1F);
  static const bg4 = Color(0xFF2A2A2E);
  static const line = Color(0xFF2A2A2E);
  static const hairline = Color(0x1AFFFFFF);

  static const tx = Color(0xFFFFFFFF);
  static const tx2 = Color(0xFF8E8E93);
  static const tx3 = Color(0xFF5A5A5F);
  static const tx4 = Color(0xFF3A3A3E);

  static const coupon = Color(0xFFFF4D6D);
  static const couponInk = Color(0xFF1A0008);
  static const letter = Color(0xFFB8FF5C);
  static const letterInk = Color(0xFF0A1A00);
  static const premium = Color(0xFFFFD60A);
  static const premiumInk = Color(0xFF1A1300);
  static const map = Color(0xFF5BA4F6);
  static const mapInk = Color(0xFF001028);
  static const streak = Color(0xFFC77DFF);
  static const streakInk = Color(0xFF1F0033);
}

enum V5Category { coupon, letter, premium, streak }

extension V5CategoryColors on V5Category {
  Color get bg {
    switch (this) {
      case V5Category.coupon:
        return V5Colors.coupon;
      case V5Category.letter:
        return V5Colors.letter;
      case V5Category.premium:
        return V5Colors.premium;
      case V5Category.streak:
        return V5Colors.streak;
    }
  }

  Color get ink {
    switch (this) {
      case V5Category.coupon:
        return V5Colors.couponInk;
      case V5Category.letter:
        return V5Colors.letterInk;
      case V5Category.premium:
        return V5Colors.premiumInk;
      case V5Category.streak:
        return V5Colors.streakInk;
    }
  }
}

class V5Text {
  static const _systemFont = '.SF Pro Display';
  static const _mono = 'Menlo';

  // 큰 헤드라인 — 화면 타이틀
  static const display = TextStyle(
    fontFamily: _systemFont,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    height: 1.05,
    color: V5Colors.tx,
  );

  // 카드 타이틀 — wallet card 헤드
  static const cardTitle = TextStyle(
    fontFamily: _systemFont,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.15,
  );

  // 큰 숫자 — price, ratio
  static const number = TextStyle(
    fontFamily: _systemFont,
    fontSize: 38,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    height: 1,
  );

  // 섹션 헤더 — UPPERCASE
  static const sectionLabel = TextStyle(
    fontFamily: _systemFont,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.24,
    color: V5Colors.tx3,
  );

  // 카드 브랜드 라인 — UPPERCASE 작게
  static const brandLine = TextStyle(
    fontFamily: _systemFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.66,
  );

  // 본문 — 일반 텍스트
  static const body = TextStyle(
    fontFamily: _systemFont,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.15,
    height: 1.45,
    color: V5Colors.tx2,
  );

  // 메타 작은 텍스트
  static const meta = TextStyle(
    fontFamily: _systemFont,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  // 모노 시리얼/코드
  static const mono = TextStyle(
    fontFamily: _mono,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
  );

  // CTA 버튼
  static const button = TextStyle(
    fontFamily: _systemFont,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );
}

class V5Shadow {
  static const card = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const sheet = [
    BoxShadow(
      color: Color(0x80000000),
      blurRadius: 24,
      offset: Offset(0, -8),
    ),
  ];
}

class V5Radius {
  static const card = 22.0;
  static const cardLg = 26.0;
  static const tile = 18.0;
  static const chip = 999.0;
}
