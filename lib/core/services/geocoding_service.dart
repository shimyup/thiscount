import 'dart:convert';
import 'package:http/http.dart' as http;

/// Nominatim 역지오코딩으로 발신자 언어 기준 3단계 주소 반환
/// 예) 한국 발신 → "Россия Надтеречный район Братское"
///     일본 발신 → "ロシア ナドテレチヌイ地区 ブラツコエ"
class GeocodingService {
  static const _nominatimUrl = 'https://nominatim.openstreetmap.org/reverse';

  // ── 인메모리 캐시 (앱 세션 내 중복 요청 제거) ────────────────────────────────
  // key: "${lat3d},${lng3d},${langCode}" (좌표 ≈111m 격자 + 언어 코드)
  // 최대 500개 유지 (초과 시 가장 오래된 항목 제거)
  static final Map<String, String?> _cache = {};
  static const int _maxCacheSize = 500;

  static void _evictIfNeeded() {
    if (_cache.length > _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// 캐시 키: 소수점 3자리 반올림 + 언어 코드
  static String _cacheKey(double lat, double lng, String? lang) =>
      '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)},${lang ?? ''}';

  /// lat/lng + 발신자 언어 코드(ISO 639-1) → 발신자 언어 "국가 구단위 동단위" 문자열
  /// 실패 시 null 반환 (타임아웃 5초, 캐시 히트 시 즉시 반환, 실패 시 1회 재시도)
  static Future<String?> getDisplayAddress(
    double lat,
    double lng, {
    String? languageCode, // 발신자 언어 코드 (예: 'ko', 'ja', 'en')
  }) async {
    final key = _cacheKey(lat, lng, languageCode);
    if (_cache.containsKey(key)) return _cache[key];

    // 1차 시도
    try {
      final addr = await _reverseRequest(lat, lng, languageCode: languageCode);
      final result = addr != null ? _buildDisplayAddress(addr) : null;
      if (result != null) {
        _evictIfNeeded();
        _cache[key] = result;
        return result;
      }
    } catch (_) {}

    // 2차 시도 (1초 대기 후 재시도)
    try {
      await Future.delayed(const Duration(seconds: 1));
      final addr = await _reverseRequest(lat, lng, languageCode: languageCode);
      final result = addr != null ? _buildDisplayAddress(addr) : null;
      _evictIfNeeded();
      _cache[key] = result; // 실패(null)도 캐싱하여 무한 재시도 방지
      return result;
    } catch (_) {
      return null;
    }
  }

  // ── Nominatim HTTP 요청 ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> _reverseRequest(
    double lat,
    double lng, {
    String? languageCode,
  }) async {
    final uri = Uri.parse(_nominatimUrl).replace(
      queryParameters: {
        'lat': lat.toStringAsFixed(6),
        'lon': lng.toStringAsFixed(6),
        'format': 'jsonv2',
        'addressdetails': '1',
        'zoom': '14',
      },
    );
    final headers = <String, String>{
      'User-Agent': 'LetterGo/1.0 (lettergo.app)',
    };
    if (languageCode != null) headers['Accept-Language'] = languageCode;

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['address'] as Map<String, dynamic>?;
  }

  // ── Nominatim address 객체 → "국가 구단위 동단위" 문자열 ──────────────────
  static String? _buildDisplayAddress(Map<String, dynamic> addr) {
    final country = addr['country'] as String?;
    if (country == null) return null;

    // Level 2: 구/군/county/district 단위
    final district =
        addr['city_district'] as String? ?? // 서초구, Arrondissement
        addr['county'] as String? ?? // Landkreis (독일), County (영국)
        addr['district'] as String? ??
        addr['borough'] as String? ?? // 런던 Borough
        addr['municipality'] as String?;

    // Level 3: 동/suburb/neighbourhood 단위
    final neighborhood =
        addr['suburb'] as String? ?? // 반포동, Suburb
        addr['neighbourhood'] as String? ??
        addr['quarter'] as String? ??
        addr['residential'] as String? ??
        addr['village'] as String? ??
        addr['city'] as String? ??
        addr['town'] as String?;

    final cityFallback =
        addr['city'] as String? ??
        addr['town'] as String? ??
        addr['village'] as String?;

    if (district == null && neighborhood == null) {
      return '$country ${cityFallback ?? ''}'.trim();
    }
    if (district == null) return '$country $neighborhood'.trim();
    if (neighborhood == null || neighborhood == district) {
      final extra = (cityFallback != null && cityFallback != district)
          ? ' $cityFallback'
          : '';
      return '$country $district$extra'.trim();
    }
    return '$country $district $neighborhood'.trim();
  }
}
