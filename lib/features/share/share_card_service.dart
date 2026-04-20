import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/letter.dart';
import '../journey/journey_stats.dart';

/// 받은 편지를 인스타그램 스토리·Twitter 등 SNS 에 공유하기 위한 이미지
/// 카드 생성 서비스.
///
/// 설계:
/// - 출력: 1080×1920 PNG (인스타 스토리·릴스 표준)
/// - Flutter `dart:ui` Canvas 로 오프라인 렌더링 (서버 의존 없음)
/// - 발신국 국기 + 경로 + 운송수단 이모지 + 편지 한 줄 + 태그라인
/// - share_plus 로 네이티브 공유 시트 호출
///
/// 바이럴 루프 핵심: 받은 편지의 감성을 스토리에 그대로 전하는 동기 제공.
class ShareCardService {
  ShareCardService._();

  static const int _cardWidth = 1080;
  static const int _cardHeight = 1920;

  /// 편지 카드를 생성하고 SNS 공유 다이얼로그를 연다.
  /// 성공 시 true, 실패 시 false.
  ///
  /// [langCode] 를 주면 해당 언어로 카드 헤더·거리 문구를 렌더링.
  /// 미지정 시 'en' 기본. 대부분 호출처에서 현재 사용자 언어 주입.
  static Future<bool> shareLetterCard({
    required Letter letter,
    required String langCode,
    String tagline = '',
    String brandName = 'Letter Go',
    String shareText = '',
  }) async {
    try {
      final l10n = AppL10n.of(langCode);
      final effectiveTagline =
          tagline.isNotEmpty ? tagline : l10n.appTagline;
      final bytes = await renderCardBytes(
        letter: letter,
        langCode: langCode,
        tagline: effectiveTagline,
        brandName: brandName,
      );
      if (bytes == null) return false;

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/lettergo_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = await File(path).writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: shareText.isNotEmpty
            ? shareText
            : '$effectiveTagline · $brandName',
      );
      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[ShareCardService] $e\n$st');
      return false;
    }
  }

  /// 이미지 바이트만 반환 (프리뷰·미리보기 용도).
  @visibleForTesting
  static Future<Uint8List?> renderCardBytes({
    required Letter letter,
    required String tagline,
    required String brandName,
    String langCode = 'en',
  }) async {
    final l10n = AppL10n.of(langCode);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(_cardWidth.toDouble(), _cardHeight.toDouble());

    _paintBackground(canvas, size);
    _paintHeader(canvas, size, letter, l10n);
    _paintJourneyGraphic(canvas, size, letter, l10n);
    _paintLetterSnippet(canvas, size, letter);
    _paintBottomBranding(canvas, size, tagline, brandName);

    final picture = recorder.endRecording();
    final image = await picture.toImage(_cardWidth, _cardHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  // ── 배경: 깊은 남색 그라디언트 + 별 ─────────────────────────────────────
  static void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = ui.Gradient.linear(
      rect.topLeft,
      rect.bottomRight,
      const [
        Color(0xFF070B14),
        Color(0xFF0D1D3A),
        Color(0xFF1F2D44),
      ],
      const [0.0, 0.5, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient);

    // 은은한 별
    final starPaint = Paint()
      ..color = const Color(0xFFF0C35A).withValues(alpha: 0.45);
    const seeds = <List<double>>[
      [120, 180, 3.0],
      [880, 240, 2.0],
      [540, 90, 2.5],
      [200, 900, 2.0],
      [980, 1500, 3.0],
      [100, 1700, 2.0],
      [800, 1200, 2.5],
      [420, 1400, 1.8],
    ];
    for (final s in seeds) {
      canvas.drawCircle(Offset(s[0], s[1]), s[2], starPaint);
    }
  }

  // ── 상단: 발신국 + 도착 메시지 ─────────────────────────────────────────
  static void _paintHeader(
    Canvas canvas,
    Size size,
    Letter letter,
    AppL10n l10n,
  ) {
    // "A letter arrived from {country}" 두 줄로 분리 렌더링
    _drawText(
      canvas,
      '${letter.senderCountryFlag}  ${letter.senderCountry}',
      offset: const Offset(80, 200),
      fontSize: 54,
      color: const Color(0xFFE8E8E0),
      weight: FontWeight.w500,
    );
    _drawText(
      canvas,
      l10n.shareCardHeader(''),
      offset: const Offset(80, 280),
      fontSize: 68,
      color: const Color(0xFFF0C35A),
      weight: FontWeight.w800,
      maxLines: 2,
    );
  }

  // ── 중앙: 여정 그래픽 (출발 → 운송수단 → 도착) ─────────────────────────
  static void _paintJourneyGraphic(
    Canvas canvas,
    Size size,
    Letter letter,
    AppL10n l10n,
  ) {
    // 카드 배경
    final cardRect = RRect.fromLTRBR(
      80, 440, size.width - 80, 1200,
      const Radius.circular(32),
    );
    canvas.drawRRect(
      cardRect,
      Paint()..color = const Color(0xFF1F2D44).withValues(alpha: 0.85),
    );

    // 발신 → 수신 경로 곡선
    final startPt = const Offset(200, 680);
    final endPt = Offset(size.width - 200, 980);
    final midPt = Offset((startPt.dx + endPt.dx) / 2, startPt.dy - 140);
    final path = Path()
      ..moveTo(startPt.dx, startPt.dy)
      ..quadraticBezierTo(midPt.dx, midPt.dy, endPt.dx, endPt.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF0C35A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // 출발점 국기
    _drawText(
      canvas,
      letter.senderCountryFlag,
      offset: Offset(startPt.dx - 54, startPt.dy - 54),
      fontSize: 108,
    );
    // 도착점 국기
    _drawText(
      canvas,
      letter.destinationCountryFlag,
      offset: Offset(endPt.dx - 54, endPt.dy - 54),
      fontSize: 108,
    );
    // 중간 운송수단 이모지
    final transport = _transportEmoji(letter);
    _drawText(
      canvas,
      transport,
      offset: Offset(midPt.dx - 48, midPt.dy - 48),
      fontSize: 96,
    );

    // 도착 도시
    final city = letter.destinationCity?.isNotEmpty == true
        ? letter.destinationCity!
        : letter.destinationCountry;
    _drawText(
      canvas,
      '→ $city',
      offset: const Offset(120, 1080),
      fontSize: 44,
      color: const Color(0xFFE8E8E0).withValues(alpha: 0.9),
      weight: FontWeight.w600,
    );

    // 이동 거리
    final km = _estimateDistanceKm(letter);
    if (km != null && km > 0) {
      _drawText(
        canvas,
        l10n.shareCardDistance(_formatKm(km)),
        offset: const Offset(120, 1140),
        fontSize: 32,
        color: const Color(0xFFE8E8E0).withValues(alpha: 0.6),
      );
    }
  }

  // ── 편지 한 줄 snippet ──────────────────────────────────────────────────
  static void _paintLetterSnippet(Canvas canvas, Size size, Letter letter) {
    final raw = letter.content.trim().replaceAll('\n', ' ');
    final snippet = raw.length > 70 ? '${raw.substring(0, 70)}…' : raw;
    _drawText(
      canvas,
      '"$snippet"',
      offset: const Offset(80, 1280),
      fontSize: 40,
      color: const Color(0xFFE8E8E0),
      weight: FontWeight.w400,
      maxWidth: _cardWidth - 160.0,
      maxLines: 4,
    );
  }

  // ── 하단: 태그라인 + 브랜드 ─────────────────────────────────────────────
  static void _paintBottomBranding(
    Canvas canvas,
    Size size,
    String tagline,
    String brandName,
  ) {
    _drawText(
      canvas,
      tagline,
      offset: const Offset(80, 1660),
      fontSize: 32,
      color: const Color(0xFFE8E8E0).withValues(alpha: 0.75),
      weight: FontWeight.w400,
      maxWidth: _cardWidth - 160.0,
      maxLines: 2,
    );
    _drawText(
      canvas,
      '〰️  $brandName',
      offset: const Offset(80, 1780),
      fontSize: 44,
      color: const Color(0xFFF0C35A),
      weight: FontWeight.w700,
    );
  }

  // ── 헬퍼 ────────────────────────────────────────────────────────────────

  static void _drawText(
    Canvas canvas,
    String text, {
    required Offset offset,
    required double fontSize,
    Color color = Colors.white,
    FontWeight weight = FontWeight.normal,
    double? maxWidth,
    int maxLines = 3,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: maxLines,
      ellipsis: '…',
    );
    tp.layout(maxWidth: maxWidth ?? _cardWidth - offset.dx - 40);
    tp.paint(canvas, offset);
  }

  /// 편지 상태·거리에 따라 대표 운송수단 이모지 선택.
  /// - > 3000 km: 항공편 ✈️
  /// - > 500 km: 해운 🚢
  /// - 그 외: 육로 🚚
  /// - 거리 불명: 기본 ✉️
  static String _transportEmoji(Letter letter) {
    final km = _estimateDistanceKm(letter);
    if (km == null) return '✉️';
    if (km > 3000) return '✈️';
    if (km > 500) return '🚢';
    return '🚚';
  }

  /// 하버사인 공식으로 두 좌표 사이의 대원 거리 계산 (km).
  static int? _estimateDistanceKm(Letter letter) {
    try {
      const earthR = 6371.0;
      double toRad(double deg) => deg * math.pi / 180.0;
      final lat1 = letter.originLocation.latitude;
      final lng1 = letter.originLocation.longitude;
      final lat2 = letter.destinationLocation.latitude;
      final lng2 = letter.destinationLocation.longitude;

      final dLat = toRad(lat2 - lat1);
      final dLng = toRad(lng2 - lng1);
      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(toRad(lat1)) *
              math.cos(toRad(lat2)) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      final km = (earthR * c).round();
      return km > 0 ? km : null;
    } catch (_) {
      return null;
    }
  }

  /// 천 단위 구분자를 넣어 "12,345" 형태로 포맷.
  static String _formatKm(int km) {
    final s = km.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  // ╔══════════════════════════════════════════════════════════════════════╗
  // ║ Journey Share Card — "나의 여정" 공유 카드                            ║
  // ╚══════════════════════════════════════════════════════════════════════╝

  /// 사용자의 누적 여정 통계를 1080×1920 공유 카드로 생성해 SNS 공유.
  /// 개별 편지 공유와 구분되는 개인 회고 바이럴 루프.
  static Future<bool> shareJourneyCard({
    required JourneyStats stats,
    required String langCode,
    required String username,
    String brandName = 'Letter Go',
  }) async {
    if (stats.isEmpty) return false;
    try {
      final bytes = await _renderJourneyCardBytes(
        stats: stats,
        langCode: langCode,
        username: username,
        brandName: brandName,
      );
      if (bytes == null) return false;

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/lettergo_journey_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = await File(path).writeAsBytes(bytes);

      final l10n = AppL10n.of(langCode);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: '${l10n.journeyTitle} · $brandName',
      );
      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[ShareCardService/journey] $e\n$st');
      return false;
    }
  }

  static Future<Uint8List?> _renderJourneyCardBytes({
    required JourneyStats stats,
    required String langCode,
    required String username,
    required String brandName,
  }) async {
    final l10n = AppL10n.of(langCode);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(_cardWidth.toDouble(), _cardHeight.toDouble());

    // 배경: 재사용
    _paintBackground(canvas, size);

    // 상단 헤더
    _drawText(
      canvas,
      '📬  ${l10n.journeyTitle}',
      offset: const Offset(80, 180),
      fontSize: 56,
      color: const Color(0xFFF0C35A),
      weight: FontWeight.w800,
    );
    _drawText(
      canvas,
      '@$username',
      offset: const Offset(80, 260),
      fontSize: 36,
      color: const Color(0xFFE8E8E0).withValues(alpha: 0.8),
      weight: FontWeight.w500,
    );

    // 중앙 카드: 3개 핵심 지표
    final statCardRect = RRect.fromLTRBR(
      80, 380, size.width - 80, 900,
      const Radius.circular(28),
    );
    canvas.drawRRect(
      statCardRect,
      Paint()..color = const Color(0xFF1F2D44).withValues(alpha: 0.85),
    );

    // 2열 통계 — 펜팔식 "답장" 지표 제거 후 발송·방문국만 노출.
    _drawJourneyStatCell(
      canvas,
      x: 240, y: 440,
      emoji: '✉️',
      value: '${stats.totalSent}',
      label: l10n.journeyStatSent,
    );
    _drawJourneyStatCell(
      canvas,
      x: 640, y: 440,
      emoji: '🌍',
      value: '${stats.countriesFrom + stats.countriesTo}',
      label: l10n.journeyStatCountries,
    );

    // 하단 카드 내부: 최장 거리 강조
    if (stats.longestDistanceKm > 0) {
      _drawText(
        canvas,
        '✈️  ${l10n.journeyLongestDistance}',
        offset: const Offset(120, 720),
        fontSize: 36,
        color: const Color(0xFFF0C35A),
        weight: FontWeight.w700,
      );
      _drawText(
        canvas,
        l10n.journeyLongestDistanceValue(
          _formatKm(stats.longestDistanceKm),
          stats.longestDistanceCountry,
        ),
        offset: const Offset(120, 780),
        fontSize: 44,
        color: const Color(0xFFE8E8E0),
        weight: FontWeight.w800,
        maxWidth: _cardWidth - 240.0,
        maxLines: 2,
      );
    }

    // 최장 스트릭
    if (stats.longestStreak > 0) {
      _drawText(
        canvas,
        '🔥  ${l10n.journeyLongestStreak(stats.longestStreak)}',
        offset: const Offset(80, 1250),
        fontSize: 40,
        color: const Color(0xFFE8E8E0),
        weight: FontWeight.w600,
      );
    }

    // 하단 태그라인 + 브랜드
    _drawText(
      canvas,
      l10n.appTagline,
      offset: const Offset(80, 1660),
      fontSize: 32,
      color: const Color(0xFFE8E8E0).withValues(alpha: 0.75),
      maxWidth: _cardWidth - 160.0,
      maxLines: 2,
    );
    _drawText(
      canvas,
      '〰️  $brandName',
      offset: const Offset(80, 1780),
      fontSize: 44,
      color: const Color(0xFFF0C35A),
      weight: FontWeight.w700,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(_cardWidth, _cardHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static void _drawJourneyStatCell(
    Canvas canvas, {
    required double x,
    required double y,
    required String emoji,
    required String value,
    required String label,
  }) {
    _drawText(
      canvas,
      emoji,
      offset: Offset(x, y),
      fontSize: 56,
    );
    _drawText(
      canvas,
      value,
      offset: Offset(x, y + 90),
      fontSize: 64,
      color: const Color(0xFFE8E8E0),
      weight: FontWeight.w800,
    );
    _drawText(
      canvas,
      label,
      offset: Offset(x, y + 180),
      fontSize: 24,
      color: const Color(0xFFE8E8E0).withValues(alpha: 0.6),
      maxWidth: 220,
    );
  }
}
