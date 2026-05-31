import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

/// Build 414: AI 쿠폰 생성 결과.
class AICouponResult {
  final String title;
  final String body;
  final String redemptionInfo; // general 타입이면 빈 문자열
  final String type; // general / coupon / voucher
  final String category; // cafe / food / beauty / fashion / it / event / other
  const AICouponResult({
    required this.title,
    required this.body,
    required this.redemptionInfo,
    required this.type,
    required this.category,
  });
}

/// AI 쿠폰 생성 서비스 — Cloud Function(generateCoupon) 경유.
///
/// LLM 키는 서버(Cloud Function secret)에만 있고, 라우팅도 서버가 한다
/// (ko→Upstage Solar 국산 / 그 외→Gemini Flash). 클라이언트는 함수 URL(공개)로
/// ID 토큰 + 입력만 전달. 미설정 시 isAvailable=false → UI 가 버튼 숨김.
class CouponAIService {
  CouponAIService._();

  static bool get isAvailable => FirebaseConfig.isCouponAIEnabled;

  /// 성공 시 AICouponResult, 실패/미설정 시 null (호출처가 에러 메시지 표시).
  static Future<AICouponResult?> generate({
    required String businessName,
    required String businessDesc,
    required String type, // general / coupon / voucher
    required String category, // cafe / food / ...
    String langCode = 'en',
  }) async {
    if (!isAvailable) return null;
    try {
      await FirebaseAuthService.ensureValidToken();
      final res = await http
          .post(
            Uri.parse(FirebaseConfig.couponAIFnUrl),
            headers: FirestoreService.authHeaders,
            body: jsonEncode({
              'businessName': businessName,
              'businessDesc': businessDesc,
              'type': type,
              'category': category,
              'langCode': langCode,
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        assert(() {
          debugPrint('[CouponAI] 실패 ${res.statusCode}: ${res.body}');
          return true;
        }());
        return null;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['ok'] != true) return null;
      return AICouponResult(
        title: (data['title'] as String?)?.trim() ?? '',
        body: (data['body'] as String?)?.trim() ?? '',
        redemptionInfo: (data['redemptionInfo'] as String?)?.trim() ?? '',
        type: (data['type'] as String?) ?? type,
        category: (data['category'] as String?) ?? category,
      );
    } on SocketException {
      return null;
    } on TimeoutException {
      return null;
    } catch (e) {
      assert(() {
        debugPrint('[CouponAI] 예외: $e');
        return true;
      }());
      return null;
    }
  }
}
