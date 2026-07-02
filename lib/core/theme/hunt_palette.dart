// Build 490 (드롭 헌트 P1): 캠페인 서브 브랜드 팔레트 — Figma v3 · Acid
// Editorial (docs/HANDOFF_DROP_HUNT_P1.md). 드롭 헌트 캠페인 UI(헌트 배너·
// 밀봉 픽업시트·개봉 연출) 한정으로 사용하고, 본 앱 공통 UI 에는 기존
// `context.palette`(AppPalette) 를 유지한다 — 두 시스템 혼용 금지.
import 'package:flutter/material.dart';

abstract final class HuntPalette {
  /// 키 컬러 "Thiscount Lime" — 카운터·드롭 핀·경로·CTA·왁스 실.
  static const Color lime = Color(0xFFD9F154);

  /// lime fill 위 텍스트/아이콘.
  static const Color limeInk = Color(0xFF232B04);

  /// 라이트 표면(티켓/페이퍼) 위 lime 계열 텍스트 (대비 확보용).
  static const Color limeDeep = Color(0xFF55660A);

  /// 다크 캔버스 (웜 잉크 — 청색 블랙 아님).
  static const Color ink = Color(0xFF141315);

  /// 배너/칩 표면.
  static const Color elev = Color(0xFF232226);

  /// 다크 위 본문 텍스트·독 표면.
  static const Color cream = Color(0xFFF2EDE2);

  /// 봉투 카드.
  static const Color paper = Color(0xFFFAF7EF);

  /// 라이트 캔버스·티켓 펀치홀.
  static const Color oat = Color(0xFFEFEAE0);

  /// 보조 텍스트 (다크).
  static const Color mut = Color(0xFF8F8B80);

  /// 긴급·만료 **전용** (장식 금지).
  static const Color cherry = Color(0xFFFF5C48);

  /// 밀봉(미스터리) 상태 **전용** — SEALED 링/라벨.
  static const Color lav = Color(0xFFB9A8FF);
}
