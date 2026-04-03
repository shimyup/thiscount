import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

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
    bool online = false;
    // Google이 차단된 국가(중국, 이란 등)를 위해 여러 호스트 순차 시도
    for (final host in ['one.one.one.one', 'dns.google', 'google.com']) {
      try {
        final result = await InternetAddress.lookup(
          host,
        ).timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
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
