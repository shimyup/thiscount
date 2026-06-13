import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/services/brand_zone_service.dart';
import '../../core/services/coupon_ai_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/content_moderation.dart';
import '../../core/utils/redemption_code.dart';
import '../../core/utils/secure_clipboard.dart';
import '../../models/letter.dart';
import '../../state/app_state.dart';
import '../compose/screens/compose_screen.dart';

/// Build 459 (UI 다이어트 3단계): 브랜드 3스텝 발송 마법사.
///
/// 기존 ComposeScreen(8,400줄, 한 스크롤에 결정 9개+)의 체감 복잡도를 줄이기
/// 위한 **간단 경로**. 풀 compose 는 '고급 모드'로 보존되고 마법사에서 한 탭으로
/// 이동 가능. 스텝당 결정 1~2개:
///   ① 혜택 — 발송 종류(일반홍보/할인권/교환권) + 업종 + 본문(+AI 초안)
///   ② 방식 — 지금 매장 주변 1통 / 근처 온 손님에게 자동 발송(반경·수량)
///   ③ 확인 — 요약 + 할인코드(할인권) + 유효기간 → 발송
///
/// 발송은 기존 AppState.sendLetter(매장 좌표 보존)·BrandZoneService.createZone
/// 을 그대로 사용 — 새 발송 경로를 만들지 않아 회귀 표면 최소화. 금칙어는
/// ContentModeration(compose 와 동일 로직) 공유.
class BrandQuickSendWizard extends StatefulWidget {
  const BrandQuickSendWizard({super.key});

  @override
  State<BrandQuickSendWizard> createState() => _BrandQuickSendWizardState();
}

enum _SendMode { dropNow, autoZone }

class _BrandQuickSendWizardState extends State<BrandQuickSendWizard> {
  int _step = 0;
  bool _sending = false;

  // ① 혜택
  LetterCategory _category = LetterCategory.coupon;
  String? _bizKey;
  final _contentCtrl = TextEditingController();
  final _redemptionCtrl = TextEditingController();

  // ② 방식
  _SendMode _mode = _SendMode.dropNow;
  double _zoneRadius = 300;
  bool _zoneUnlimited = true;
  final _zoneQtyCtrl = TextEditingController(text: '100');

  // ③ 확인
  bool _attachCode = false;
  String? _previewCode;
  int _expireDays = 7; // 0 = 없음

  static const List<String> _bizKeys = [
    'food', 'cafe', 'beauty', 'fashion', 'event', 'it', 'other',
  ];

  @override
  void dispose() {
    _contentCtrl.dispose();
    _redemptionCtrl.dispose();
    _zoneQtyCtrl.dispose();
    super.dispose();
  }

  String _bizLabel(AppL10n l, String key) {
    switch (key) {
      case 'food':
        return l.bizLabelFood;
      case 'cafe':
        return l.bizLabelCafe;
      case 'beauty':
        return l.bizLabelBeauty;
      case 'fashion':
        return l.bizLabelFashion;
      case 'event':
        return l.bizLabelEvent;
      case 'it':
        return l.bizLabelIt;
      default:
        return l.bizLabelOther;
    }
  }

  String _categoryLabel(AppL10n l, LetterCategory c) {
    switch (c) {
      case LetterCategory.coupon:
        return l.composeBrandCategoryCoupon;
      case LetterCategory.voucher:
        return l.composeBrandCategoryVoucher;
      default:
        return l.composeBrandCategoryGeneral;
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            error ? AppColors.error.withValues(alpha: 0.92) : AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _validateStep1(AppL10n l) {
    final content = _contentCtrl.text.trim();
    final minChars = _category == LetterCategory.general ? 10 : 1;
    if (content.length < minChars) {
      _snack(
        l.wizardMinChars(minChars),
        error: true,
      );
      return false;
    }
    if (ContentModeration.hasBannedWords(
        '$content\n${_redemptionCtrl.text.trim()}')) {
      _snack(l.composeBannedWordError, error: true);
      return false;
    }
    return true;
  }

  Future<void> _runAiDraft(AppState state, AppL10n l) async {
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          l.wizardAiTitle,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: descCtrl,
          autofocus: true,
          maxLines: 2,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: l.wizardAiHint,
            hintStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 12),
            filled: true,
            fillColor: AppColors.bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(l.settingsCancel,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.bgDeep),
            child: Text(l.wizardGenerate),
          ),
        ],
      ),
    );
    if (ok != true) {
      descCtrl.dispose();
      return;
    }
    final desc = descCtrl.text.trim();
    descCtrl.dispose();
    if (desc.isEmpty) {
      _snack(l.wizardAiNeedDesc, error: true);
      return;
    }
    _snack(l.wizardGenerating);
    final typeKey = _category == LetterCategory.coupon
        ? 'coupon'
        : _category == LetterCategory.voucher
            ? 'voucher'
            : 'general';
    final result = await CouponAIService.generate(
      businessName: context.read<AppState>().currentUser.brandName ??
          context.read<AppState>().currentUser.username,
      businessDesc: desc,
      type: typeKey,
      category: _bizKey ?? 'other',
      langCode: state.currentUser.languageCode,
    );
    if (!mounted) return;
    if (result == null) {
      _snack(
        CouponAIService.lastWasRateLimited
            ? l.wizardAiBusy
            : l.wizardAiFailed,
        error: true,
      );
      return;
    }
    setState(() {
      _contentCtrl.text = result.body.isNotEmpty ? result.body : result.title;
      if (result.redemptionInfo.isNotEmpty) {
        _redemptionCtrl.text = result.redemptionInfo;
        if (_category == LetterCategory.general) {
          _category = LetterCategory.coupon;
        }
      }
    });
  }

  Future<void> _submit(AppState state, AppL10n l) async {
    if (_sending) return;
    if (!_validateStep1(l)) return;
    if (!state.canSendByQuota) {
      _snack(state.dailyLimitExceededMessage, error: true);
      return;
    }
    final user = state.currentUser;
    final lat =
        state.hasFixedStoreLocation ? state.fixedStoreLat! : user.latitude;
    final lng =
        state.hasFixedStoreLocation ? state.fixedStoreLng! : user.longitude;
    if (lat == 0 && lng == 0) {
      _snack(l.wizardNoLocation, error: true);
      return;
    }
    setState(() => _sending = true);
    final content = _contentCtrl.text.trim();
    final redemptionInfo = _redemptionCtrl.text.trim().isEmpty
        ? null
        : _redemptionCtrl.text.trim();
    final expiresAt = (_expireDays > 0 && _category != LetterCategory.general)
        ? DateTime.now().add(Duration(days: _expireDays))
        : null;
    final code = (_attachCode && _category == LetterCategory.coupon)
        ? (_previewCode ?? RedemptionCode.generate())
        : null;

    bool ok = false;
    try {
      if (_mode == _SendMode.dropNow) {
        ok = await state.sendLetter(
          content: content,
          destinationCountry: user.country,
          destinationFlag: user.countryFlag,
          destLat: lat,
          destLng: lng,
          useExactCoordinates: true, // 내 매장 주변 — 좌표 보존(무차감)
          category: _category,
          categoryTag: _bizKey,
          redemptionInfo: redemptionInfo,
          redemptionExpiresAt: expiresAt,
          attachRedemptionCode: code != null,
          explicitRedemptionCode: code,
        );
      } else {
        final maxR = _zoneUnlimited
            ? 0
            : (int.tryParse(_zoneQtyCtrl.text.trim()) ?? 0);
        if (!_zoneUnlimited && maxR <= 0) {
          _snack(l.zoneCampaignMaxRedeemsHint, error: true);
          setState(() => _sending = false);
          return;
        }
        final zoneId = await BrandZoneService.instance.createZone(
          brandId: user.id,
          brandName: user.brandName ?? user.username,
          center: LatLng(lat, lng),
          radiusM: _zoneRadius,
          content: content,
          redemptionInfo: redemptionInfo,
          maxRedeems: maxR,
          redemptionCode: code,
        );
        ok = zoneId != null;
      }
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _sending = false);
    if (!ok) {
      _snack(l.wizardSendFailed, error: true);
      return;
    }
    if (code != null) {
      await _showCodeDialog(l, code);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    _snack(
      _mode == _SendMode.dropNow ? l.wizardSentNear : l.wizardAutoOn,
    );
  }

  Future<void> _showCodeDialog(AppL10n l, String code) async {
    final formatted = RedemptionCode.formatForDisplay(code);
    await showDialog<void>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          l.redemptionSentDialogTitle,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.coupon.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.coupon.withValues(alpha: 0.5)),
              ),
              child: Text(
                formatted,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.wizardCodeNote,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11.5, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await SecureClipboard.copyEphemeral(formatted);
              if (dCtx.mounted) Navigator.pop(dCtx);
            },
            child: Text(l.redemptionCodeCopy,
                style: const TextStyle(color: AppColors.coupon)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.coupon,
                foregroundColor: AppColors.bgDeep),
            child: Text(l.wizardDone),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppL10n.of(state.currentUser.languageCode);
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _step--),
              )
            : null,
        title: Text(
          l.wizardTitleStep(_step + 1),
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800),
        ),
        actions: [
          // 고급 모드 — 풀 compose 로 전환.
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ComposeScreen()),
            ),
            child: Text(
              l.wizardAdvanced,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 진행 바
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? AppColors.coupon
                            : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: _step == 0
                    ? _buildStep1(state, l)
                    : _step == 1
                        ? _buildStep2(state, l)
                        : _buildStep3(state, l),
              ),
            ),
            // 하단 CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _sending
                      ? null
                      : () {
                          if (_step == 0) {
                            if (_validateStep1(l)) setState(() => _step = 1);
                          } else if (_step == 1) {
                            setState(() => _step = 2);
                          } else {
                            _submit(state, l);
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.coupon,
                    foregroundColor: AppColors.bgDeep,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _sending
                        ? l.wizardSending
                        : _step < 2
                            ? l.next
                            : (_mode == _SendMode.dropNow
                                ? l.wizardSend
                                : l.wizardTurnOnAuto),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ① 혜택 ────────────────────────────────────────────────────────────────
  Widget _buildStep1(AppState state, AppL10n l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.wizardStep1Title,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in [
              LetterCategory.coupon,
              LetterCategory.voucher,
              LetterCategory.general,
            ])
              _chip(
                label: _categoryLabel(l, c),
                selected: _category == c,
                color: AppColors.coupon,
                onTap: () => setState(() {
                  _category = c;
                  if (c != LetterCategory.coupon) {
                    _attachCode = false;
                    _previewCode = null;
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l.wizardBizHeader,
          style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final k in _bizKeys)
              _chip(
                label: '${bizCategoryEmoji(k)} ${_bizLabel(l, k)}',
                selected: _bizKey == k,
                color: AppColors.teal,
                onTap: () =>
                    setState(() => _bizKey = _bizKey == k ? null : k),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                l.wizardMessageHeader,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
            if (CouponAIService.isAvailable)
              TextButton.icon(
                onPressed: () => _runAiDraft(state, l),
                icon: const Text('✨', style: TextStyle(fontSize: 13)),
                label: Text(
                  l.wizardAiDraftBtn,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.gold),
              ),
          ],
        ),
        TextField(
          controller: _contentCtrl,
          maxLines: 4,
          minLines: 3,
          maxLength: 300,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: _category == LetterCategory.general
                ? l.wizardContentHintGeneral
                : l.wizardContentHintOffer,
            hintStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 13),
            filled: true,
            fillColor: AppColors.bgSurface,
            counterStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_category != LetterCategory.general) ...[
          const SizedBox(height: 4),
          TextField(
            controller: _redemptionCtrl,
            maxLines: 2,
            minLines: 1,
            maxLength: 200,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: l.wizardRedemptionHint,
              hintStyle:
                  const TextStyle(color: AppColors.textMuted, fontSize: 12),
              filled: true,
              fillColor: AppColors.bgSurface,
              counterStyle:
                  const TextStyle(color: AppColors.textMuted, fontSize: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── ② 방식 ────────────────────────────────────────────────────────────────
  Widget _buildStep2(AppState state, AppL10n l) {
    final hasFixed = state.hasFixedStoreLocation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.wizardStep2Title,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          hasFixed ? l.wizardLocFixed : l.wizardLocCurrent,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
        ),
        const SizedBox(height: 14),
        _modeCard(
          selected: _mode == _SendMode.dropNow,
          emoji: '📣',
          title: l.wizardModeDropTitle,
          desc: l.wizardModeDropDesc,
          onTap: () => setState(() => _mode = _SendMode.dropNow),
        ),
        const SizedBox(height: 10),
        _modeCard(
          selected: _mode == _SendMode.autoZone,
          emoji: '📍',
          title: l.zoneCampaignToggle,
          desc: l.wizardModeAutoDesc,
          onTap: () => setState(() => _mode = _SendMode.autoZone),
        ),
        if (_mode == _SendMode.autoZone) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _chip(
                label: '300 m',
                selected: _zoneRadius == 300,
                color: AppColors.gold,
                onTap: () => setState(() => _zoneRadius = 300),
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: _chip(
                label: '2 km',
                selected: _zoneRadius == 2000,
                color: AppColors.gold,
                onTap: () => setState(() => _zoneRadius = 2000),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _chip(
                label: l.wizardAlways,
                selected: _zoneUnlimited,
                color: AppColors.gold,
                onTap: () => setState(() => _zoneUnlimited = true),
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: _chip(
                label: l.wizardLimited,
                selected: !_zoneUnlimited,
                color: AppColors.gold,
                onTap: () => setState(() => _zoneUnlimited = false),
              )),
            ],
          ),
          if (!_zoneUnlimited) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _zoneQtyCtrl,
              keyboardType: TextInputType.number,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: l.wizardLimitHint,
                hintStyle:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  // ── ③ 확인 ────────────────────────────────────────────────────────────────
  Widget _buildStep3(AppState state, AppL10n l) {
    final content = _contentCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.wizardStep3Title,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.coupon.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(bizCategoryEmoji(_bizKey),
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.coupon.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _categoryLabel(l, _category),
                      style: const TextStyle(
                          color: AppColors.coupon,
                          fontSize: 11,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                content,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                _mode == _SendMode.dropNow
                    ? l.wizardSummaryDrop
                    : '📍 ${l.zoneCampaignToggle} · ${_zoneRadius == 300 ? '300m' : '2km'}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        if (_category == LetterCategory.coupon) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => setState(() {
              _attachCode = !_attachCode;
              if (_attachCode) {
                _previewCode ??= RedemptionCode.generate();
              }
            }),
            child: Row(
              children: [
                Icon(
                  _attachCode
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 20,
                  color: _attachCode ? AppColors.coupon : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.redemptionToggleLabel,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          if (_attachCode && _previewCode != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.coupon.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.coupon.withValues(alpha: 0.4)),
              ),
              child: Text(
                RedemptionCode.formatForDisplay(_previewCode!),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ],
        if (_category != LetterCategory.general) ...[
          const SizedBox(height: 14),
          Text(
            l.wizardValidFor,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final d in [0, 3, 7, 30])
                _chip(
                  label: d == 0 ? l.wizardNone : l.wizardDays(d),
                  selected: _expireDays == d,
                  color: AppColors.teal,
                  onTap: () => setState(() => _expireDays = d),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.75)
                : AppColors.textMuted.withValues(alpha: 0.2),
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _modeCard({
    required bool selected,
    required String emoji,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.coupon.withValues(alpha: 0.1)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.coupon.withValues(alpha: 0.7)
                : AppColors.bgSurface,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? AppColors.coupon
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? AppColors.coupon : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
