import 'package:flutter/material.dart';

/// 편지지 스타일 정의 (5종 무료, 이후 유료 추가 예정)
class PaperStyle {
  final String name;
  final Color bgColor;
  final Color lineColor;
  final bool hasLines;
  final bool hasDots;
  final Color inkColor;
  final String emoji;
  const PaperStyle({
    required this.name,
    required this.bgColor,
    required this.lineColor,
    required this.hasLines,
    required this.hasDots,
    required this.inkColor,
    required this.emoji,
  });
}

/// 폰트 스타일 정의
class FontStyleConfig {
  final String name;
  final TextStyle textStyle;
  final String emoji;
  const FontStyleConfig({
    required this.name,
    required this.textStyle,
    required this.emoji,
  });
}

class LetterStyles {
  static const List<PaperStyle> papers = [
    PaperStyle(
      name: '클래식 크림',
      bgColor: Color(0xFFFDF6E3),
      lineColor: Color(0xFFD4C5A9),
      hasLines: false,
      hasDots: false,
      inkColor: Color(0xFF2C1810),
      emoji: '📄',
    ),
    PaperStyle(
      name: '파란 줄',
      bgColor: Color(0xFFF0F6FF),
      lineColor: Color(0xFFB0C8F0),
      hasLines: true,
      hasDots: false,
      inkColor: Color(0xFF1A2C4E),
      emoji: '📋',
    ),
    PaperStyle(
      name: '빈티지 양피지',
      bgColor: Color(0xFFEDD9A3),
      lineColor: Color(0xFFC4A96A),
      hasLines: false,
      hasDots: true,
      inkColor: Color(0xFF3B2A1A),
      emoji: '📜',
    ),
    PaperStyle(
      name: '딥오션 (다크)',
      bgColor: Color(0xFF0D1B2A),
      lineColor: Color(0xFF1E3A52),
      hasLines: true,
      hasDots: false,
      inkColor: Color(0xFFE0F0FF),
      emoji: '🌊',
    ),
    PaperStyle(
      name: '봄 도트',
      bgColor: Color(0xFFF5FFF0),
      lineColor: Color(0xFFB8E8A0),
      hasLines: false,
      hasDots: true,
      inkColor: Color(0xFF2A4A1E),
      emoji: '🌸',
    ),
  ];

  static const List<FontStyleConfig> fonts = [
    FontStyleConfig(
      name: '기본체',
      emoji: 'A',
      textStyle: TextStyle(
        fontSize: 16,
        height: 1.85,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w400,
      ),
    ),
    FontStyleConfig(
      name: '세리프체',
      emoji: 'Ã',
      textStyle: TextStyle(
        fontSize: 15,
        height: 1.9,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.normal,
        fontFamily: 'serif',
      ),
    ),
    FontStyleConfig(
      name: '타자기체',
      emoji: '⌨',
      textStyle: TextStyle(
        fontSize: 14,
        height: 1.95,
        letterSpacing: 1.0,
        fontFamily: 'Courier',
        fontWeight: FontWeight.w400,
      ),
    ),
    FontStyleConfig(
      name: '필기체',
      emoji: '✍',
      textStyle: TextStyle(
        fontSize: 16,
        height: 2.0,
        letterSpacing: 0.8,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w300,
      ),
    ),
  ];

  static PaperStyle paper(int index) =>
      papers[index.clamp(0, papers.length - 1)];
  static FontStyleConfig font(int index) =>
      fonts[index.clamp(0, fonts.length - 1)];
}

/// 편지지 배경 커스텀 페인터
class LetterPaperPainter extends CustomPainter {
  final PaperStyle style;
  const LetterPaperPainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    // 배경색
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = style.bgColor,
    );
    if (style.hasLines) {
      final paint = Paint()
        ..color = style.lineColor
        ..strokeWidth = 0.8;
      double y = 40;
      while (y < size.height) {
        canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), paint);
        y += 32;
      }
    }
    if (style.hasDots) {
      final paint = Paint()
        ..color = style.lineColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.fill;
      double y = 36;
      while (y < size.height) {
        double x = 24;
        while (x < size.width - 16) {
          canvas.drawCircle(Offset(x, y), 1.2, paint);
          x += 28;
        }
        y += 28;
      }
    }
  }

  @override
  bool shouldRepaint(LetterPaperPainter old) => old.style != style;
}
