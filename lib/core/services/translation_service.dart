import 'dart:convert';
import 'package:http/http.dart' as http;

/// 번역 서비스 (MyMemory 무료 API + Google Translate 폴백)
class TranslationService {
  // MyMemory 무료 API (월 5000 단어, 키 없이 사용 가능)
  static Future<String?> translate({
    required String text,
    required String fromLang,
    required String toLang,
  }) async {
    if (text.isEmpty) return null;
    if (fromLang == toLang) return text;

    // 1차 시도: MyMemory API
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(text)}'
        '&langpair=$fromLang|$toLang',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final translated =
            (json['responseData'] as Map?)?['translatedText'] as String?;
        if (translated != null &&
            translated.isNotEmpty &&
            translated != 'INVALID LANGUAGE PAIR') {
          return translated;
        }
      }
    } catch (_) {}

    // 2차 시도: Google Translate 비공식 엔드포인트
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single'
        '?client=gtx'
        '&sl=${Uri.encodeComponent(fromLang)}'
        '&tl=${Uri.encodeComponent(toLang)}'
        '&dt=t'
        '&q=${Uri.encodeComponent(text)}',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        final sentences = data[0] as List<dynamic>?;
        if (sentences != null) {
          final buffer = StringBuffer();
          for (final s in sentences) {
            final list = s as List<dynamic>?;
            if (list != null && list.isNotEmpty && list[0] is String) {
              buffer.write(list[0] as String);
            }
          }
          final result = buffer.toString();
          if (result.isNotEmpty) return result;
        }
      }
    } catch (_) {}

    return null;
  }

  // 언어 코드 → 표시 이름
  static String langName(String code) {
    const names = {
      'ko': '한국어',
      'en': '영어',
      'ja': '일본어',
      'zh': '중국어',
      'fr': '프랑스어',
      'de': '독일어',
      'es': '스페인어',
      'pt': '포르투갈어',
      'it': '이탈리아어',
      'ru': '러시아어',
      'ar': '아랍어',
      'hi': '힌디어',
    };
    return names[code] ?? code.toUpperCase();
  }
}
