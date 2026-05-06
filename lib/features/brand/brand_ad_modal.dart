import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/letter.dart';
import '../../state/app_state.dart';
import '../inbox/widgets/letter_read_screen.dart';

/// Build 202 — 온보딩 직후 1회 표시되는 브랜드 광고 모달.
///
/// 디자인:
/// - 화면 약 60% 차지하는 중앙 모달
/// - 상단 50%: 브랜드 광고 이미지
/// - 중간: 브랜드명 (UPPERCASE eyebrow) + 큰 헤드라인 + 본문 스니펫
/// - 하단: "닫기" (ghost) + "편지 받기" (solid coupon) 두 개 버튼
///
/// 트리거:
/// - main_scaffold initState 의 postFrameCallback 에서 1회 호출
/// - 마지막으로 노출한 광고 letter.id 와 다르면 표시 (= 새 광고 도착마다 1회)
/// - featuredBrandPromo 가 null 이면 미노출
///
/// Build 205: 이전엔 "하루 1회" 정책이었으나 테스트/베타 기간 동안 새 캠페인
/// 이 들어왔는지 사용자가 즉시 인지하도록 letter.id 기반 dedup 으로 변경.
/// 같은 광고는 두 번 안 뜨고, 새 광고는 즉시 뜬다.
class BrandAdModal {
  static const String _prefKey = 'brand_ad_last_shown_letter_id';

  /// 가장 최근 광고 letter 를 아직 본 적 없으면 표시.
  static Future<void> showIfDue(BuildContext context) async {
    if (!context.mounted) return;
    final state = context.read<AppState>();
    final promo = state.featuredBrandPromo;
    if (promo == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastShownId = prefs.getString(_prefKey);
    if (lastShownId == promo.id) return;

    if (!context.mounted) return;
    HapticFeedback.lightImpact();
    await prefs.setString(_prefKey, promo.id);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => _BrandAdDialog(letter: promo),
    );
  }

  /// 디버그/QA: 강제 표시.
  static void showForce(BuildContext context, Letter letter) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => _BrandAdDialog(letter: letter),
    );
  }
}

class _BrandAdDialog extends StatelessWidget {
  final Letter letter;

  const _BrandAdDialog({required this.letter});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final mq = MediaQuery.of(context);
    final modalHeight = mq.size.height * 0.62;
    // Build 246: 이미지 fallback — Voucher 의 경우 redemptionInfo 가 이미지 URL/path.
    // 이전엔 imageUrl 만 보고 → Voucher 발송 시 팝업 이미지 빈 상태였음.
    String? imageUrl = letter.imageUrl;
    if ((imageUrl == null || imageUrl.isEmpty) &&
        letter.category == LetterCategory.voucher) {
      final ri = letter.redemptionInfo?.trim() ?? '';
      if (ri.startsWith('http') ||
          ri.startsWith('/') ||
          ri.startsWith('file:')) {
        imageUrl = ri;
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: modalHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // ── 이미지 영역 (상단 ~50%) ──────────────────────────────────
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  color: AppColors.bgSurface,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? _buildImage(imageUrl)
                      : _buildPlaceholder(),
                ),
              ),
              // ── 텍스트 + 버튼 영역 (하단 ~50%) ────────────────────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 브랜드 eyebrow
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.coupon,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'BRAND · ${letter.senderName.toUpperCase()}',
                          style: const TextStyle(
                            color: Color(0xFF1A0008),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 큰 제목
                      Text(
                        _firstLine(letter.content),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // 본문 스니펫
                      Expanded(
                        child: Text(
                          _bodySnippet(letter.content),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // CTA 두 개
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  l10n.brandAdClose,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              // Build 246: 이중 Navigator.pop 버그 픽스 — onTap 에서
                              // pop 하지 않고 _pickUp 안에서만 처리. 이전엔 onTap pop
                              // + _pickUp 내부 pop = 부모 화면(지도) 까지 닫혀서
                              // "혜택받기 누르면 멈춤" 증상.
                              onTap: () => _pickUp(context),
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.coupon,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.coupon
                                          .withValues(alpha: 0.4),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  l10n.brandAdPickup,
                                  style: const TextStyle(
                                    color: Color(0xFF1A0008),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    final isNet = url.startsWith('http://') || url.startsWith('https://');
    if (isNet) {
      return Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
    final f = File(url);
    if (!f.existsSync()) return _buildPlaceholder();
    return Image.file(
      f,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.bgSurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 56,
        color: AppColors.textMuted,
      ),
    );
  }

  void _pickUp(BuildContext context) {
    final state = context.read<AppState>();
    // Build 246: Navigator state 캡처 후 작업 수행 — async gap 이나 중첩 호출에서
    // context invalidate 되어도 안전하게 navigation 가능.
    final navigator = Navigator.of(context);
    final lang = state.currentUser.languageCode;

    // 1) 인박스에 이미 픽업된 letter 면 readLetter 만, 없으면 pickUpLetter 로
    //    인박스 추가 후 read. (테스트 모드에서는 거리 검증 우회)
    // 2) modal 닫고 → letter_read_screen 으로 이동해 본문 표시.
    final inboxHas = state.inbox.any((l) => l.id == letter.id);
    if (!inboxHas) {
      state.pickUpLetter(letter.id, distanceCheck: false);
    }
    state.readLetter(letter.id);
    final picked = state.inbox.firstWhere(
      (l) => l.id == letter.id,
      orElse: () => letter,
    );
    // 단일 pop + push (이전 onTap pop 이중 호출 버그 제거됨)
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => LetterReadScreen(
          letter: picked,
          userLanguageCode: lang,
        ),
      ),
    );
  }

  String _firstLine(String content) {
    final lines = content.trim().split('\n');
    final first = lines.first.trim();
    if (first.isEmpty && lines.length > 1) return lines[1].trim();
    return first.isEmpty ? '광고' : first;
  }

  String _bodySnippet(String content) {
    final lines = content.trim().split('\n');
    if (lines.length <= 1) return content.trim();
    return lines.skip(1).join(' ').trim();
  }
}
