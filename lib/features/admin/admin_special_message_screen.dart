// Build 284 (Phase 3 — C 단계): 관리자 특별 메시지 zone 설정 화면.
//
// 관리자가 좌표 + 반경 + 메시지 + 시간 + 수량 을 입력해 brand_zones 에
// `brandId='admin'` 으로 POST. 일반 사용자가 zone 안에 들어오면
// BrandZoneService.triggerForUser 가 letter 자동 발급 + 지도에 [AutoDropMarker]
// (gold 핀 + %) 로 차별 표시.
//
// 본 화면은 admin 전용 진입. admin_screen 의 메뉴에서 push.
// 보안: 클라이언트 검증만 — Firestore rules 가 본문 크기/필드 화이트리스트
// 검증. anonymous Firebase Auth 한계로 server-side admin 검증은 Cloud
// Function (Phase 4) 까지 보류. 베타 기간엔 admin 패널 접근 자체가 통제됨.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/config/firebase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/brand_zone.dart';
import '../../models/letter.dart' show LatLng;
import '../../state/app_state.dart';

class AdminSpecialMessageScreen extends StatefulWidget {
  const AdminSpecialMessageScreen({super.key});
  @override
  State<AdminSpecialMessageScreen> createState() =>
      _AdminSpecialMessageScreenState();
}

class _AdminSpecialMessageScreenState extends State<AdminSpecialMessageScreen> {
  final _contentCtrl = TextEditingController();
  final _redemptionCtrl = TextEditingController();
  final _maxRedeemsCtrl = TextEditingController(text: '100');

  double _radiusM = 200;
  int _durationHours = 24;
  bool _useMyLocation = true;
  bool _submitting = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _redemptionCtrl.dispose();
    _maxRedeemsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      setState(() => _error = '메시지 본문을 입력하세요');
      return;
    }
    if (content.length > 1000) {
      setState(() => _error = '메시지는 1000자 이내 (현재 ${content.length}자)');
      return;
    }
    if (_radiusM < 50 || _radiusM > 5000) {
      setState(() => _error = '반경은 50m – 5km 범위');
      return;
    }
    final maxRedeems = int.tryParse(_maxRedeemsCtrl.text.trim()) ?? 0;
    if (maxRedeems < 0 || maxRedeems > 100000) {
      setState(() => _error = '수량은 0 (무제한) – 100,000 범위');
      return;
    }
    final centerLat = state.currentUser.latitude;
    final centerLng = state.currentUser.longitude;
    if (_useMyLocation && centerLat == 0 && centerLng == 0) {
      setState(() => _error = '내 위치를 확인할 수 없습니다. 지도에서 위치 설정 후 재시도');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });

    final now = DateTime.now();
    final zone = BrandZone(
      // id 는 Firestore POST 시점에 결정되지만 미리 생성해서 senderId 와 통일.
      id: 'admin_${now.millisecondsSinceEpoch}',
      brandId: 'admin',
      brandName: '관리자',
      center: LatLng(centerLat, centerLng),
      radiusM: _radiusM,
      content: content,
      redemptionInfo: _redemptionCtrl.text.trim().isEmpty
          ? null
          : _redemptionCtrl.text.trim(),
      startsAt: now,
      expiresAt: now.add(Duration(hours: _durationHours)),
      maxRedeems: maxRedeems,
      redeemedCount: 0,
      createdAt: now,
    );

    final ok = await _postZoneToFirestore(zone);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (ok) {
        _success = '특별 메시지 zone 생성됨 (반경 ${_radiusM.toInt()}m · '
            '${_durationHours}h · max ${maxRedeems == 0 ? '무제한' : maxRedeems}통)';
        _contentCtrl.clear();
        _redemptionCtrl.clear();
        _maxRedeemsCtrl.text = '100';
      } else {
        _error = 'Firestore 전송 실패. 네트워크 확인 후 재시도';
      }
    });
  }

  /// Firestore REST `brand_zones` 컬렉션에 BrandZone 을 POST.
  /// 응답 status 200 = 성공.
  Future<bool> _postZoneToFirestore(BrandZone zone) async {
    if (!FirebaseConfig.kFirebaseEnabled) return false;
    try {
      final fields = _zoneToFirestoreFields(zone);
      final uri = Uri.parse(
        '${FirebaseConfig.firestoreBase}/brand_zones?documentId=${zone.id}',
      );
      final r = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'fields': fields}),
          )
          .timeout(const Duration(seconds: 10));
      return r.statusCode >= 200 && r.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// 모델 JSON → Firestore typed-value JSON (REST API 가 요구).
  Map<String, dynamic> _zoneToFirestoreFields(BrandZone z) {
    String s(String v) => v;
    return {
      'id': {'stringValue': s(z.id)},
      'brandId': {'stringValue': s(z.brandId)},
      'brandName': {'stringValue': s(z.brandName)},
      'center': {
        'mapValue': {
          'fields': {
            'lat': {'doubleValue': z.center.latitude},
            'lng': {'doubleValue': z.center.longitude},
          }
        }
      },
      'radiusM': {'doubleValue': z.radiusM},
      'content': {'stringValue': s(z.content)},
      if (z.redemptionInfo != null)
        'redemptionInfo': {'stringValue': s(z.redemptionInfo!)},
      'startsAt': {'stringValue': z.startsAt.toUtc().toIso8601String()},
      'expiresAt': {'stringValue': z.expiresAt.toUtc().toIso8601String()},
      'maxRedeems': {'integerValue': z.maxRedeems.toString()},
      'redeemedCount': {'integerValue': z.redeemedCount.toString()},
      'createdAt': {'stringValue': z.createdAt.toUtc().toIso8601String()},
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('관리자 특별 메시지'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.premium.withValues(alpha: .4)),
                ),
                child: const Row(
                  children: [
                    Text('🛠', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '내 위치 주변에 특별 메시지 zone 을 만듭니다. '
                        'zone 반경 안에 들어오는 사용자에게 자동으로 letter 가 발송되며, '
                        '지도에 골드 핀 (Icon A-refined) 으로 차별 표시됩니다.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _Label(text: '메시지 본문 (필수, 1000자 이내)'),
              _Field(
                controller: _contentCtrl,
                hint: '예: 이번 주말 신상품 30% 할인 이벤트',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              const _Label(text: '쿠폰 코드 / QR URL (선택)'),
              _Field(
                controller: _redemptionCtrl,
                hint: '예: ADMIN20 또는 https://...',
              ),
              const SizedBox(height: 16),
              _Label(text: '반경 ${_radiusM.toInt()}m (50m – 5km)'),
              Slider(
                value: _radiusM,
                min: 50,
                max: 5000,
                divisions: 99,
                activeColor: AppColors.premium,
                onChanged: _submitting ? null : (v) => setState(() => _radiusM = v),
              ),
              const SizedBox(height: 8),
              _Label(text: '유효 시간 ${_durationHours}시간'),
              Wrap(
                spacing: 8,
                children: [1, 6, 24, 72, 168]
                    .map(
                      (h) => ChoiceChip(
                        label: Text('${h}h'),
                        selected: _durationHours == h,
                        onSelected: _submitting
                            ? null
                            : (_) => setState(() => _durationHours = h),
                        selectedColor: AppColors.premium,
                        labelStyle: TextStyle(
                          color: _durationHours == h
                              ? const Color(0xFF1A1300)
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        backgroundColor: AppColors.bgCard,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              const _Label(text: '최대 발급 수량 (0 = 무제한)'),
              _Field(
                controller: _maxRedeemsCtrl,
                hint: '100',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '⚠️ $_error',
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              if (_success != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '✓ $_success',
                    style: const TextStyle(color: AppColors.success, fontSize: 13),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.premium,
                    foregroundColor: const Color(0xFF1A1300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Color(0xFF1A1300),
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          '특별 메시지 zone 생성',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          filled: true,
          fillColor: AppColors.bgCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
