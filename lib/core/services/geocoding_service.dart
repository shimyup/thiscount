import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Nominatim (OpenStreetMap) 역지오코딩 기반 전 세계 실제 주소 서비스.
///
/// 작동 흐름:
/// 1. countries_bounds.json에서 195개국 경계 박스 로드
/// 2. 나라 경계 내 랜덤 좌표 생성 → Nominatim reverse geocode → 실제 주소
/// 3. SharedPreferences에 나라별 캐시 저장 (오프라인 지원)
/// 4. 기존 getDisplayAddress() 기능도 유지
class GeocodingService {
  static const _nominatimUrl = 'https://nominatim.openstreetmap.org/reverse';
  static const _userAgent = 'Thiscount/1.0 (thiscount.io)';
  static const _cachePrefix = 'geo_addr_cache_';
  static const _maxCachePerCountry = 50;
  static const _prefetchCount = 15;

  // ── 싱글턴 ─────────────────────────────────────────────────────────────────
  GeocodingService._();
  static final instance = GeocodingService._();

  /// 나라 경계 박스 {koreanName: {flag, iso, lat_min, lat_max, lng_min, lng_max}}
  Map<String, dynamic>? _bounds;

  /// 주소 캐시: {나라명: [주소 데이터]}
  final Map<String, List<Map<String, dynamic>>> _addressCache = {};

  final _rng = Random();

  /// 마지막 API 호출 시각 (rate limit 준수: 1 req/sec)
  DateTime? _lastApiCall;

  /// 초기화 완료 여부
  bool _initialized = false;
  bool get isInitialized => _initialized;

  // ══════════════════════════════════════════════════════════════════════════
  // 초기화
  // ══════════════════════════════════════════════════════════════════════════

  /// 앱 시작 시 호출 — 경계 박스 로드 + 디스크 캐시 복원
  Future<void> initialize() async {
    if (_initialized) return;
    await _loadBounds();
    await _restoreDiskCache();
    _initialized = true;
  }

  Future<void> _loadBounds() async {
    try {
      final raw = await rootBundle.loadString('assets/countries_bounds.json');
      _bounds = json.decode(raw) as Map<String, dynamic>;
      assert(() {
        debugPrint('[Geocoding] Loaded ${_bounds!.length} country bounds');
        return true;
      }());
    } catch (e) {
      assert(() {
        debugPrint('[Geocoding] Failed to load bounds: $e');
        return true;
      }());
    }
  }

  Future<void> _restoreDiskCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix));
      for (final key in keys) {
        final country = key.substring(_cachePrefix.length);
        final raw = prefs.getString(key);
        if (raw != null) {
          final list = (json.decode(raw) as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _addressCache[country] = list;
        }
      }
      assert(() {
        final total = _addressCache.values.fold<int>(0, (s, l) => s + l.length);
        debugPrint('[Geocoding] Restored $total cached addresses');
        return true;
      }());
    } catch (e) {
      assert(() {
        debugPrint('[Geocoding] Cache restore error: $e');
        return true;
      }());
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 공개 API — 나라/주소 조회
  // ══════════════════════════════════════════════════════════════════════════

  /// 제외 국가 목록 (제재 대상 및 우편 서비스 불가 지역)
  static const Set<String> _excludedCountries = {
    '북한', // DPRK - 우편 서비스 불가
  };

  /// 국가가 편지 목적지로 허용되는지 확인
  static bool isAllowedCountry(String country) =>
      !_excludedCountries.contains(country);

  /// 전체 나라 목록 반환 (제외 국가 필터링)
  List<Map<String, String>> get allCountries {
    if (_bounds == null) return [];
    return _bounds!.entries
        .where((e) => !_excludedCountries.contains(e.key))
        .map((e) {
      final b = e.value as Map<String, dynamic>;
      final latCenter = ((b['lat_min'] as num) + (b['lat_max'] as num)) / 2;
      final lngCenter = ((b['lng_min'] as num) + (b['lng_max'] as num)) / 2;
      return {
        'name': e.key,
        'flag': (b['flag'] as String?) ?? '🏳️',
        'iso': (b['iso'] as String?) ?? '',
        'lat': latCenter.toStringAsFixed(4),
        'lng': lngCenter.toStringAsFixed(4),
      };
    }).toList();
  }

  /// 나라 수
  int get countryCount => _bounds?.length ?? 0;

  /// 나라 경계 박스 존재 여부 (제외 국가는 false 반환)
  bool hasCountry(String country) =>
      !_excludedCountries.contains(country) &&
      (_bounds?.containsKey(country) ?? false);

  /// 나라의 국기 이모지
  String flagOf(String country) {
    final b = _bounds?[country] as Map<String, dynamic>?;
    return (b?['flag'] as String?) ?? '🏳️';
  }

  /// 나라의 ISO 코드
  String isoOf(String country) {
    final b = _bounds?[country] as Map<String, dynamic>?;
    return (b?['iso'] as String?) ?? '';
  }

  /// 캐시에서 실제 주소 1개 꺼내기 (즉시 반환, 없으면 null)
  Map<String, dynamic>? getCachedAddress(String country) {
    final cache = _addressCache[country];
    if (cache == null || cache.isEmpty) return null;
    final idx = _rng.nextInt(cache.length);
    return cache.removeAt(idx); // 사용 후 제거 (중복 방지)
  }

  /// 캐시된 주소 수
  int cachedCountOf(String country) => _addressCache[country]?.length ?? 0;

  /// 좌표를 포함하는 나라 찾기 (실제 위치 기반).
  /// 미국·러시아·캐나다 등 큰 나라가 더 작은 나라를 포함하지 않도록
  /// 박스 면적 작은 순으로 정렬한 후 첫 매칭 반환.
  ///
  /// 반환: {'name', 'flag', 'iso'} 또는 null (어느 나라 박스에도 안 들어감 — 바다 등)
  Map<String, String>? findCountryByCoord(double lat, double lng) {
    if (_bounds == null) return null;
    final candidates = <Map<String, dynamic>>[];
    _bounds!.forEach((name, value) {
      if (_excludedCountries.contains(name)) return;
      final b = value as Map<String, dynamic>;
      final latMin = (b['lat_min'] as num).toDouble();
      final latMax = (b['lat_max'] as num).toDouble();
      final lngMin = (b['lng_min'] as num).toDouble();
      final lngMax = (b['lng_max'] as num).toDouble();
      if (lat >= latMin && lat <= latMax && lng >= lngMin && lng <= lngMax) {
        final area = (latMax - latMin) * (lngMax - lngMin);
        candidates.add({
          'name': name,
          'flag': (b['flag'] as String?) ?? '🏳️',
          'iso': (b['iso'] as String?) ?? '',
          'area': area,
        });
      }
    });
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) =>
        (a['area'] as double).compareTo(b['area'] as double));
    final c = candidates.first;
    return {
      'name': c['name'] as String,
      'flag': c['flag'] as String,
      'iso': c['iso'] as String,
    };
  }

  /// 나라 경계 내 랜덤 좌표 생성 (API 없이)
  Map<String, double>? randomCoordinate(String country) {
    final b = _bounds?[country] as Map<String, dynamic>?;
    if (b == null) return null;
    final latMin = (b['lat_min'] as num).toDouble();
    final latMax = (b['lat_max'] as num).toDouble();
    final lngMin = (b['lng_min'] as num).toDouble();
    final lngMax = (b['lng_max'] as num).toDouble();
    return {
      'lat': latMin + _rng.nextDouble() * (latMax - latMin),
      'lng': lngMin + _rng.nextDouble() * (lngMax - lngMin),
    };
  }

  /// 랜덤 나라 선택 (제외 가능, 제외 국가 목록은 allCountries에서 이미 필터링됨)
  Map<String, String>? randomCountry({String? exclude}) {
    final list = allCountries.where((c) => c['name'] != exclude).toList();
    if (list.isEmpty) return null;
    return list[_rng.nextInt(list.length)];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 프리페치 — 백그라운드에서 실제 주소 미리 조회
  // ══════════════════════════════════════════════════════════════════════════

  /// 특정 나라의 실제 주소 N개 프리페치
  Future<int> prefetch(String country, {int count = _prefetchCount}) async {
    final b = _bounds?[country] as Map<String, dynamic>?;
    if (b == null) return 0;

    int fetched = 0;
    final iso = ((b['iso'] as String?) ?? 'en').toLowerCase();
    int retries = 0;
    const maxRetries = 3; // 연속 실패 시 중단

    for (int i = 0; i < count + 10 && fetched < count; i++) {
      // 캐시 충분하면 중단
      if ((_addressCache[country]?.length ?? 0) >= _maxCachePerCountry) break;
      // 연속 실패 시 중단
      if (retries >= maxRetries) break;

      final coord = randomCoordinate(country);
      if (coord == null) continue;

      final result = await _reverseGeocodeForCache(
        coord['lat']!,
        coord['lng']!,
        langCode: iso,
        expectedCountryIso: iso.toUpperCase(),
      );

      if (result != null) {
        _addressCache.putIfAbsent(country, () => []);
        _addressCache[country]!.add(result);
        fetched++;
        retries = 0;
      } else {
        retries++;
      }
    }

    if (fetched > 0) await _saveDiskCache(country);
    return fetched;
  }

  /// 여러 나라 일괄 프리페치 (앱 시작 시 백그라운드)
  Future<void> prefetchMultiple(List<String> countries, {int perCountry = 10}) async {
    for (final country in countries) {
      if ((_addressCache[country]?.length ?? 0) >= perCountry) continue;
      final needed = perCountry - (_addressCache[country]?.length ?? 0);
      await prefetch(country, count: needed);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 기존 호환 API — getDisplayAddress (경로 표시용)
  // ══════════════════════════════════════════════════════════════════════════

  // 인메모리 캐시 (좌표→주소 문자열, 세션 내 중복 제거)
  static final Map<String, String?> _displayCache = {};
  static const int _maxDisplayCacheSize = 500;

  static void _evictDisplayIfNeeded() {
    if (_displayCache.length > _maxDisplayCacheSize) {
      _displayCache.remove(_displayCache.keys.first);
    }
  }

  static String _displayCacheKey(double lat, double lng, String? lang) =>
      '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)},${lang ?? ''}';

  /// lat/lng → 발신자 언어 "국가 구단위 동단위" 문자열 (기존 호환)
  static Future<String?> getDisplayAddress(
    double lat,
    double lng, {
    String? languageCode,
  }) async {
    final key = _displayCacheKey(lat, lng, languageCode);
    if (_displayCache.containsKey(key)) return _displayCache[key];

    // 1차 시도
    try {
      final addr = await _reverseRequest(lat, lng, languageCode: languageCode);
      final result = addr != null ? _buildDisplayAddress(addr) : null;
      if (result != null) {
        _evictDisplayIfNeeded();
        _displayCache[key] = result;
        return result;
      }
    } catch (_) {}

    // 2차 시도 (1초 대기 후 재시도)
    try {
      await Future.delayed(const Duration(seconds: 1));
      final addr = await _reverseRequest(lat, lng, languageCode: languageCode);
      final result = addr != null ? _buildDisplayAddress(addr) : null;
      _evictDisplayIfNeeded();
      _displayCache[key] = result;
      return result;
    } catch (_) {
      return null;
    }
  }

  /// 공용 역지오코딩. Brand 전용 "정확한 좌표 드롭" UI 가 핀 좌표에서 국가·
  /// 도시·국기 이모지를 얻는 용도. 실패 시 null — caller 가 좌표만으로
  /// 발송을 계속 진행할 수 있다.
  Future<Map<String, String>?> reverseLookup(
    double lat,
    double lng, {
    String? languageCode,
  }) async {
    try {
      final addr = await _reverseRequest(lat, lng, languageCode: languageCode);
      if (addr == null) return null;
      final country = (addr['country'] as String?) ?? '';
      final city = (addr['city'] as String?) ??
          (addr['town'] as String?) ??
          (addr['village'] as String?) ??
          (addr['county'] as String?) ??
          '';
      final countryCode = (addr['country_code'] as String?)?.toUpperCase() ?? '';
      String flag = '';
      if (countryCode.length == 2) {
        // ISO-3166-1 alpha-2 → regional indicator emoji
        final base = 0x1F1E6 - 'A'.codeUnitAt(0);
        flag = String.fromCharCodes([
          base + countryCode.codeUnitAt(0),
          base + countryCode.codeUnitAt(1),
        ]);
      }
      return {
        'country': country,
        'city': city,
        'flag': flag,
      };
    } catch (_) {
      return null;
    }
  }

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
    final headers = <String, String>{'User-Agent': _userAgent};
    if (languageCode != null) headers['Accept-Language'] = languageCode;

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['address'] as Map<String, dynamic>?;
  }

  static String? _buildDisplayAddress(Map<String, dynamic> addr) {
    final country = addr['country'] as String?;
    if (country == null) return null;

    final district =
        addr['city_district'] as String? ??
        addr['county'] as String? ??
        addr['district'] as String? ??
        addr['borough'] as String? ??
        addr['municipality'] as String?;

    final neighborhood =
        addr['suburb'] as String? ??
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

  // ══════════════════════════════════════════════════════════════════════════
  // 내부 — Nominatim 역지오코딩 (캐시용)
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> _reverseGeocodeForCache(
    double lat,
    double lng, {
    String langCode = 'en',
    String? expectedCountryIso,
  }) async {
    await _waitForRateLimit();

    try {
      final uri = Uri.parse(
        '$_nominatimUrl?lat=$lat&lon=$lng&format=json&addressdetails=1&accept-language=$langCode',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': _userAgent,
      }).timeout(const Duration(seconds: 10));

      _lastApiCall = DateTime.now();

      if (resp.statusCode != 200) return null;
      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (data.containsKey('error')) return null;

      // 국가 코드 검증 (바다/다른 나라에 떨어진 경우 필터)
      if (expectedCountryIso != null) {
        final address = data['address'] as Map<String, dynamic>?;
        final cc = (address?['country_code'] as String?)?.toUpperCase();
        if (cc != null && cc != expectedCountryIso) return null;
      }

      final displayName = data['display_name'] as String? ?? '';
      final resultLat = double.tryParse(data['lat']?.toString() ?? '') ?? lat;
      final resultLng = double.tryParse(data['lon']?.toString() ?? '') ?? lng;

      final address = data['address'] as Map<String, dynamic>? ?? {};
      final city = (address['city'] ??
          address['town'] ??
          address['village'] ??
          '').toString();
      final district = (address['city_district'] ??
          address['borough'] ??
          address['county'] ??
          '').toString();
      final state = (address['state'] ?? '').toString();
      final country = (address['country'] ?? '').toString();

      // 도시(시/군/구) 레벨로 통일 — 도로명은 제외 (편지 앱 표시용)
      String shortAddress;
      if (city.isNotEmpty && district.isNotEmpty && district != city) {
        shortAddress = '$city $district';
      } else if (city.isNotEmpty) {
        shortAddress = state.isNotEmpty && state != city
            ? '$state $city'
            : city;
      } else if (district.isNotEmpty) {
        shortAddress = state.isNotEmpty ? '$state $district' : district;
      } else if (state.isNotEmpty) {
        shortAddress = state;
      } else {
        shortAddress = displayName.split(',').take(2).join(',').trim();
      }

      return {
        'lat': resultLat,
        'lng': resultLng,
        'address': shortAddress,
        'city': city,
        'country': country,
        'displayName': displayName,
      };
    } catch (e) {
      assert(() {
        debugPrint('[Geocoding] Reverse geocode error: $e');
        return true;
      }());
      return null;
    }
  }

  Future<void> _waitForRateLimit() async {
    if (_lastApiCall != null) {
      final elapsed = DateTime.now().difference(_lastApiCall!);
      if (elapsed < const Duration(milliseconds: 1100)) {
        await Future.delayed(const Duration(milliseconds: 1100) - elapsed);
      }
    }
  }

  // ── 디스크 캐시 ────────────────────────────────────────────────────────────

  Future<void> _saveDiskCache(String country) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _addressCache[country];
      if (list != null && list.isNotEmpty) {
        await prefs.setString('$_cachePrefix$country', json.encode(list));
      }
    } catch (_) {}
  }

  /// 전체 캐시 저장 (앱 백그라운드 진입 시)
  Future<void> saveAllCache() async {
    for (final country in _addressCache.keys) {
      await _saveDiskCache(country);
    }
  }

  /// 캐시 통계
  Map<String, int> get cacheStats =>
      _addressCache.map((k, v) => MapEntry(k, v.length));
}
