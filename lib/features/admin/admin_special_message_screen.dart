// Build 284 (Phase 3 — C 단계): 관리자 특별 메시지 zone 설정 화면.
//
// 관리자가 좌표 + 반경 + 메시지 + 시간 + 수량 을 입력해 brand_zones 에
// `brandId='admin'` 으로 POST. 일반 사용자가 zone 안에 들어오면
// BrandZoneService.triggerForUser 가 letter 자동 발급 + 지도에 brand 마커로
// 차별 표시.
//
// 본 화면은 admin 전용 진입. admin_screen 의 메뉴에서 push.
// 보안: 클라이언트 검증만 — Firestore rules 가 본문 크기/필드 화이트리스트
// 검증. anonymous Firebase Auth 한계로 server-side admin 검증은 Cloud
// Function (Phase 4) 까지 보류. 베타 기간엔 admin 패널 접근 자체가 통제됨.

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/config/app_keys.dart';
import '../../core/config/firebase_config.dart';
import '../../core/services/brand_zone_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/redemption_code.dart';
import '../../core/utils/secure_clipboard.dart';
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
  // Build 360 (PR-AA1): zone 자체에 매장 POS 코드 자동 부여 토글.
  //   ON 이면 zone 으로 발급되는 모든 letter 가 동일 코드 공유.
  bool _attachCode = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _redemptionCtrl.dispose();
    _maxRedeemsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    // Build 393 (PR-HH2 P0): admin 가드 enforcement — `/admin_special_message`
    //   라우트가 직접 navigate 가능하므로 _submit 진입 시 admin 재검증 필수.
    //   이전엔 라우트만 push 하면 누구나 zone POST 가능 → 일반 user 가
    //   'Admin' 위장 zone 생성으로 fake 자동 letter 살포 가능했음.
    if (!BetaConstants.isAdmin(state.currentUser.email)) {
      setState(() => _error = '관리자 권한 없음');
      return;
    }
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
    // Build 360 (PR-AA1): 토글 ON 이면 zone 1개 = 코드 1개 (zone 으로 발급되는
    //   모든 letter 가 동일 코드 공유 → 매장 POS 1회 등록).
    final code = _attachCode ? RedemptionCode.generate() : null;
    // Build 364 (PR-BB3): id 충돌 방지 — 같은 ms 안 2 zone 생성 또는 두 admin
    //   동시 생성 시 documentId 중복 → 409 ALREADY_EXISTS. 6-hex random suffix
    //   추가 (16M combinations) → 충돌 확률 무시 가능.
    final rng = math.Random.secure();
    final randSuffix = rng.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final zone = BrandZone(
      // id 는 Firestore POST 시점에 결정되지만 미리 생성해서 senderId 와 통일.
      id: 'admin_${now.millisecondsSinceEpoch}_$randSuffix',
      brandId: 'admin',
      // Build 383 (PR-FF1): senderName 이 비-ko 사용자 인박스에도 노출 →
      //   universal 'Admin' 영어. AppL10n 접근 어려운 model 생성 시점.
      brandName: 'Admin',
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
      redemptionCode: code,
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
      // Build 409 (sim P0.2): 인증 토큰 부착 — firestore.rules 가 isSignedIn()
      //   요구. apiKey 만으론 request.auth 비어 403. (brand_zone_service 와 동일)
      await FirebaseAuthService.ensureValidToken();
      final r = await http
          .post(
            uri,
            headers: FirestoreService.authHeaders,
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
      // Build 360 (PR-AA1): zone 매장 POS 코드 (옵션).
      if (z.redemptionCode != null)
        'redemptionCode': {'stringValue': s(z.redemptionCode!)},
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // Build 393 (PR-HH2 P0): admin 가드 — build 진입 시 admin email 검증.
    //   non-admin 진입 시 차단 화면 표시 (라우트 push 자체는 막을 수 없음).
    if (!BetaConstants.isAdmin(state.currentUser.email)) {
      return Scaffold(
        backgroundColor: AppColors.bgDeep,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(''),
        ),
        body: const Center(
          child: Text(
            '🔒 관리자 권한 필요',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('관리자 특별 메시지'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 24),
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
              const SizedBox(height: 16),
              // Build 360 (PR-AA1): 매장 POS 코드 자동 부여 토글.
              InkWell(
                onTap: _submitting
                    ? null
                    : () => setState(() => _attachCode = !_attachCode),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        _attachCode
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: _attachCode
                            ? AppColors.premium
                            : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '매장 POS 코드 자동 부여',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'zone 1개 = 코드 1개. 발급되는 모든 letter 가 동일 코드 공유.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
              const SizedBox(height: 28),
              // Build 289: 최근 생성 zone 목록 + 픽업/사용 카운터.
              // 페르소나 피드백 "Brand/Admin 가 zone 생성 후 피드백 루프 없음"
              // 해소. BrandZoneService 캐시 사용 → 같은 데이터 소스. admin 만
              // 진입 가능한 화면이므로 PII 위험 없음.
              const _RecentZonesList(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Build 289: brand_zones 컬렉션의 활성 + 만료 zone 5개를 redeemed/max 와 함께
/// 표시. BrandZoneService 의 캐시 (5분 TTL) 를 그대로 사용.
class _RecentZonesList extends StatefulWidget {
  const _RecentZonesList();
  @override
  State<_RecentZonesList> createState() => _RecentZonesListState();
}

class _RecentZonesListState extends State<_RecentZonesList> {
  bool _loading = true;
  List<BrandZone> _zones = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await BrandZoneService.instance.warmUp(force: true);
      if (!mounted) return;
      final all = BrandZoneService.instance.allCached;
      // admin 생성 zone 만 + 최근 5개.
      final filtered = all.where((z) => z.brandId == 'admin').toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _zones = filtered.take(5).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_zones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '아직 생성된 admin zone 이 없습니다.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
      );
    }
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '📋 내가 만든 zone (최근 5개)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
              child: const Text('새로고침', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final z in _zones)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: z.expiresAt.isAfter(now)
                    ? AppColors.premium.withValues(alpha: .35)
                    : AppColors.textMuted.withValues(alpha: .2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: z.expiresAt.isAfter(now)
                            ? AppColors.success.withValues(alpha: .2)
                            : AppColors.textMuted.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        z.expiresAt.isAfter(now) ? '활성' : '만료',
                        style: TextStyle(
                          color: z.expiresAt.isAfter(now)
                              ? AppColors.success
                              : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '반경 ${z.radiusM.toInt()}m',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${z.redeemedCount} / ${z.maxRedeems == 0 ? '∞' : z.maxRedeems}',
                      style: TextStyle(
                        color: AppColors.premium,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  z.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '생성 ${z.createdAt.toLocal().toString().substring(0, 16)} · '
                  '만료 ${z.expiresAt.toLocal().toString().substring(0, 16)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
                // Build 360 (PR-AA1): zone 매장 POS 코드 (있으면).
                // Build 364 (PR-BB3): 만료된 zone 의 코드는 매장 POS 에서 부정
                //   사용 위험 → 표시/복사 액션 둘 다 숨김. expired 뱃지만 노출.
                if (z.redemptionCode != null &&
                    z.redemptionCode!.isNotEmpty &&
                    z.expiresAt.isAfter(now)) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('🎫', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          RedemptionCode.formatForDisplay(z.redemptionCode!),
                          style: const TextStyle(
                            color: AppColors.premium,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          await SecureClipboard.copyEphemeral(
                            RedemptionCode.formatForDisplay(z.redemptionCode!),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('코드 복사됨 — POS 등록 시 사용'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            '복사',
                            style: TextStyle(
                              color: AppColors.premium,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
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
