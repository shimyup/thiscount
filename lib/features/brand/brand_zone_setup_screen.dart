import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/brand_zone_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/letter.dart' show LatLng;
import '../../state/app_state.dart';

/// Build 317: Brand 자동 zone 발송 캠페인 등록 화면.
///
/// 회원이 지정한 반경 (300m / 2km) 안에 들어오면 자동으로 letter 1통이 인박스에
/// 도착. Brand 가 매장 / 행사장 / 팝업 위치를 미리 등록해 두는 캠페인.
///
/// 옵션:
///   - 반경: 300m (작은 매장) / 2km (광역 캠페인)
///   - 수량: 한정 수량 (숫자 입력) / 상시 (0 = 무제한)
///   - 본문: zone 진입 시 자동 발송되는 letter content
///   - redemption: 쿠폰 코드 / 사용 안내 (옵션)
///   - 위치: 사용자 현재 GPS 좌표 (기본). 향후 ExactDropPicker 통합 예정.
class BrandZoneSetupScreen extends StatefulWidget {
  static const String routeName = '/brand_zone_setup';
  const BrandZoneSetupScreen({super.key});

  @override
  State<BrandZoneSetupScreen> createState() => _BrandZoneSetupScreenState();
}

class _BrandZoneSetupScreenState extends State<BrandZoneSetupScreen> {
  // 옵션 default — 사용자 명시 옵션 2개.
  double _radius = 300;
  final _contentCtrl = TextEditingController();
  final _redemptionCtrl = TextEditingController();
  final _maxRedeemsCtrl = TextEditingController(text: '100');
  bool _isUnlimited = true;
  bool _submitting = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _redemptionCtrl.dispose();
    _maxRedeemsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    final user = state.currentUser;
    if (!user.isBrand) {
      _toast('Brand 계정만 캠페인을 등록할 수 있어요.');
      return;
    }
    if (user.latitude == 0 && user.longitude == 0) {
      _toast('현재 위치를 확인할 수 없어요. 위치 권한을 허용해 주세요.');
      return;
    }
    final content = _contentCtrl.text.trim();
    if (content.length < 5) {
      _toast('캠페인 본문은 5자 이상 입력해 주세요.');
      return;
    }
    final maxR = _isUnlimited
        ? 0
        : int.tryParse(_maxRedeemsCtrl.text.trim()) ?? 0;
    if (!_isUnlimited && maxR <= 0) {
      _toast('한정 수량은 1 이상이어야 해요.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final id = await BrandZoneService.instance.createZone(
        brandId: user.id,
        brandName: user.username,
        center: LatLng(user.latitude, user.longitude),
        radiusM: _radius,
        content: content,
        redemptionInfo: _redemptionCtrl.text.trim().isEmpty
            ? null
            : _redemptionCtrl.text.trim(),
        maxRedeems: maxR,
      );
      if (!mounted) return;
      if (id == null) {
        _toast('캠페인 등록에 실패했어요. 잠시 후 다시 시도해 주세요.');
        setState(() => _submitting = false);
        return;
      }
      _toast('캠페인이 등록됐어요!');
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      _toast('등록 중 오류가 발생했어요.');
      setState(() => _submitting = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.bgCard),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        title: const Text(
          '자동 발송 캠페인 등록',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Text(
            '회원이 지정 반경 안에 들어오면 자동으로 메시지가 발송됩니다.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _sectionTitle('📍 반경'),
          Row(
            children: [
              _radiusChip(300, '300 m', '소형 매장'),
              const SizedBox(width: 10),
              _radiusChip(2000, '2 km', '광역 행사'),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('🎟️ 발송 수량'),
          Row(
            children: [
              _modeChip(true, '상시 발송', '무제한'),
              const SizedBox(width: 10),
              _modeChip(false, '한정 수량', '숫자 입력'),
            ],
          ),
          if (!_isUnlimited) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _maxRedeemsCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('한정 수량 (예: 100)'),
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle('💌 본문'),
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            maxLength: 200,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration('zone 진입 시 발송될 메시지 본문'),
          ),
          const SizedBox(height: 12),
          _sectionTitle('🎫 사용 안내 (선택)'),
          TextField(
            controller: _redemptionCtrl,
            maxLines: 2,
            maxLength: 200,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration('쿠폰 코드 / QR / 매장 안내 등'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.bgDeep,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _submitting ? '등록 중...' : '캠페인 등록',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          s,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _radiusChip(double value, String label, String sub) {
    final selected = _radius == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _radius = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.2)
                : AppColors.bgCard,
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.textMuted,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.gold : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeChip(bool unlimited, String label, String sub) {
    final selected = _isUnlimited == unlimited;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _isUnlimited = unlimited),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.coupon.withValues(alpha: 0.2)
                : AppColors.bgCard,
            border: Border.all(
              color: selected ? AppColors.coupon : AppColors.textMuted,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.coupon : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
      );
}
