import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;

  ConnectivityService._internal() {
    _startPolling();
  }

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _timer;

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
    _check();
  }

  Future<void> _check() async {
    // 웹 환경: dart:io InternetAddress.lookup 미지원 → HTTP HEAD 요청으로 대체
    // 네이티브: 동일하게 HTTP HEAD 요청 사용 (웹/앱 통합 방식)
    bool online = false;
    const checkUrls = [
      'https://one.one.one.one',       // Cloudflare DNS
      'https://connectivitycheck.gstatic.com/generate_204', // Google
      'https://www.apple.com/library/test/success.html',    // Apple
    ];
    for (final url in checkUrls) {
      try {
        final res = await http.head(Uri.parse(url)).timeout(const Duration(seconds: 4));
        if (res.statusCode < 500) {
          online = true;
          break;
        }
      } catch (_) {
        continue;
      }
    }
    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }
  }

  Future<void> recheck() => _check();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
