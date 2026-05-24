import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/feedback_service.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/redemption_code.dart';
import '../../../core/theme/letter_style.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_names.dart';
import '../../../core/localization/language_config.dart';
import '../../../models/letter.dart';
import '../../../state/app_state.dart';
import '../../compose/screens/compose_screen.dart';
import '../../premium/premium_gate_sheet.dart';
import '../../../models/direct_message.dart';
import '../../dm/dm_conversation_screen.dart';
import '../../share/share_card_service.dart';
import 'letter_context_badge.dart';
import 'scarcity_indicator.dart';
import 'sender_moment_line.dart';
// 펜팔 배지 UI 제거 — import 도 제거. 데이터 통계 로직은 _PenpalStats 내부에서만 사용.
// import '../../penpal/penpal_tier.dart';

class LetterReadScreen extends StatefulWidget {
  final Letter letter;
  final String userLanguageCode;

  const LetterReadScreen({
    super.key,
    required this.letter,
    this.userLanguageCode = 'ko',
  });

  @override
  State<LetterReadScreen> createState() => _LetterReadScreenState();
}

class _LetterReadScreenState extends State<LetterReadScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _openController;
  late Animation<double> _openAnimation;
  bool _isOpened = false;
  bool _isTranslated = false;
  bool _isTranslating = false;
  String? _translatedText;
  String? _translateError;
  bool _hasLiked = false;
  int _userRating = 0; // 0 = 미선택, 1-5 = 별점

  bool _voucherProtectOn = false;

  // Build 337 (PR-S8 시뮬레이션 P1 #6): redemption box 로 auto-scroll 위함.
  //   redemptionCode 있는 letter 첫 진입 시 본문 아래로 스크롤 → "사용 진행"
  //   버튼이 즉시 보임.
  // Build 340 (PR-S11 2차 시뮬레이션): static Set 으로 letter 별 1회만 자동
  //   스크롤. 이전엔 인스턴스 변수 _didAutoScroll → 재진입 (회전, 뒤로가기)
  //   마다 false 로 reset 되어 매번 스크롤 발생 (사용자 의도 무시).
  final ScrollController _scrollCtl = ScrollController();
  final GlobalKey _redemptionBoxKey = GlobalKey();
  static final Set<String> _autoScrolledLetterIds = {};

  @override
  void initState() {
    super.initState();
    // Build 183: 교환권 편지 화면 전체도 스크린샷/recording 차단. 본문 보기
    // 단계에서 먼저 활성 → 풀스크린 뷰어도 자체적으로 재-활성 (중첩 안전).
    if (widget.letter.category == LetterCategory.voucher) {
      _voucherProtectOn = true;
      ScreenProtector.preventScreenshotOn();
      ScreenProtector.protectDataLeakageWithBlur();
    }
    // Build 182: content 가 비어 있으면 Firestore 에서 재조회 (백그라운드).
    // 성공 시 AppState notifyListeners → Consumer 가 본문을 다시 렌더한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      if (widget.letter.content.trim().isEmpty) {
        unawaited(state.refetchLetterContentIfEmpty(widget.letter.id));
      }
      // Build 324 (Q1): 화면 진입 시 만료된 pending redemption 자동 정리
      //   → redeemed 처리 + UI 즉시 반영 (dim + 사용됨 라벨).
      unawaited(state.consumeElapsedPendingRedemptions());
    });
    // 3단계 개봉 시퀀스 — 총 1500ms
    //   Phase 1 (0 → 0.3, ~400ms) : 봉투가 살짝 나타남 + light haptic
    //   Phase 2 (0.3 → 0.6, ~350ms): 봉인 터짐 느낌 + medium haptic
    //   Phase 3 (0.6 → 1.0, ~750ms): 편지 본문 펼침 (scale + opacity)
    //
    // Build 205: 이전엔 `await _openController.animateTo` 체인 + 중간에
    // `await HapticFeedback.heavyImpact()` 가 있어 플랫폼/시뮬레이터에 따라
    // 햅틱 Future 가 늦거나 영영 resolve 안 되면 마지막 단계가 안 돌고 본문이
    // 영영 안 보였다. 단일 `forward()` + status listener 로 단순화하고 햅틱은
    // 모두 fire-and-forget. 또한 상태가 어떻든 `dispose` 직전에 `_isOpened`
    // true 보장 로직 + 포커스 시점 `mounted` 체크.
    _openController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _openAnimation = CurvedAnimation(
      parent: _openController,
      curve: Curves.easeOutCubic,
    );
    _openController.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted && !_isOpened) {
        setState(() => _isOpened = true);
      }
    });
    // 단계별 햅틱: value 가 phase boundary 를 처음 지날 때 한 번씩 발화.
    bool firedPhase2 = false;
    bool firedPhase3 = false;
    _openController.addListener(() {
      final v = _openController.value;
      if (!firedPhase2 && v >= 0.3) {
        firedPhase2 = true;
        FeedbackService.onLetterOpen();
      }
      if (!firedPhase3 && v >= 0.6) {
        firedPhase3 = true;
        HapticFeedback.heavyImpact();
      }
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      _openController.forward();
    });
    // 안전망 — 어떤 이유든 1.6s 가 지나도 _isOpened 가 false 면 강제로 켠다.
    // 본문은 _openAnimation 이 1.0 이면 자연스럽게 풀-페이드인. listener 가
    // 못 따라온 corner case 보완.
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted && !_isOpened) {
        setState(() => _isOpened = true);
        if (_openController.status != AnimationStatus.completed) {
          _openController.value = 1.0;
        }
      }
      // Build 337 (PR-S8): 개봉 애니메이션 끝난 직후 redemption box 로 auto-scroll.
      //   redemptionCode 있는 letter 만 — 일반 letter 는 그대로.
      _maybeAutoScrollToRedemption();
    });
  }

  /// Build 337 (PR-S8 시뮬레이션 P1 #6): 코드 letter 진입 후 "사용 진행" 버튼
  ///   까지 자동 스크롤. 본문 긴 letter 에서 사용자가 직접 스크롤 다운하지
  ///   않으면 버튼 못 찾던 UX 회귀 해소.
  void _maybeAutoScrollToRedemption() {
    if (widget.letter.redemptionCode == null) return;
    if (_autoScrolledLetterIds.contains(widget.letter.id)) return;
    _autoScrolledLetterIds.add(widget.letter.id);
    final ctx = _redemptionBoxKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.1, // 화면 위쪽 살짝 떨어진 위치 (헤더 가림 방지)
      );
    } else if (_scrollCtl.hasClients) {
      // box key context 가 아직 마운트 안 됐으면 (rare) — 본문 끝까지 스크롤.
      _scrollCtl.animateTo(
        _scrollCtl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    if (_voucherProtectOn) {
      ScreenProtector.preventScreenshotOff();
      ScreenProtector.protectDataLeakageWithBlurOff();
    }
    _scrollCtl.dispose();
    _openController.dispose();
    super.dispose();
  }

  // SNS 링크 열기
  // Build 276 (P1 보안): javascript:/data:/file: 같은 위험 scheme 차단 (XSS).
  // http(s) 만 허용. 사용자 작성 URL 이 다른 사용자에게 보여지므로 stored XSS 방어.
  Future<void> _launchSnsLink(String rawUrl) async {
    final urlStr = rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl';
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return;
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid link scheme'),
            backgroundColor: AppColors.bgSurface,
          ),
        );
      }
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.letterReadCannotOpenLink(urlStr)),
          backgroundColor: AppColors.bgSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // MyMemory 번역 API 호출
  Future<void> _doTranslate(String text, String fromLang, String toLang) async {
    if (fromLang == toLang) {
      setState(() {
        _translatedText = text;
        _translateError = null;
        _isTranslated = true;
        _isTranslating = false;
      });
      return;
    }
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(text)}&langpair=$fromLang|$toLang',
      );
      // http 패키지 사용 — HttpClient 직접 사용 시 소켓 누수 위험 방지
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 6));
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final translated =
          (json['responseData'] as Map<String, dynamic>?)?['translatedText']
              as String?;
      if (!mounted) return;
      if (translated != null && translated.isNotEmpty) {
        setState(() {
          _translatedText = translated;
          _translateError = null;
          _isTranslated = true;
          _isTranslating = false;
        });
      } else {
        final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
        setState(() {
          _translateError = l10n.letterReadTranslationEmpty;
          _isTranslating = false;
        });
      }
    } catch (e, st) {
      // Build 305: silent swallow 였던 부분 — 디버그 빌드 로그로 원인 surface.
      assert(() {
        debugPrint('[LetterRead] translation 실패: $e\n$st');
        return true;
      }());
      if (mounted) {
        final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
        setState(() {
          _translateError = l10n.letterReadTranslationError;
          _isTranslating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.letter;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          // 배경 별빛
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _LetterBgPainter(),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, letter),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _openAnimation,
                    builder: (_, __) {
                      return SingleChildScrollView(
                        controller: _scrollCtl,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            // 발신자 정보 카드
                            _buildSenderCard(letter),
                            const SizedBox(height: 20),
                            // 편지 본문 — 3단계 개봉 연출
                            //  0.0-0.3: 봉투가 바닥에서 떠오름 (translateY + fade)
                            //  0.3-0.6: 봉인 터짐 (가벼운 흔들림 + 점진 노출)
                            //  0.6-1.0: 편지지가 펼쳐짐 (scale up to full)
                            Builder(builder: (_) {
                              final v = _openAnimation.value;
                              // Phase 1: 진입 — 아래에서 위로 + 투명도 상승
                              final enterT = (v / 0.3).clamp(0.0, 1.0);
                              final translateY = (1 - enterT) * 40;
                              final enterOpacity = enterT;
                              // Phase 2: 봉인 파열 — 좌우 wobble (0.3~0.6)
                              final wobbleT = ((v - 0.3) / 0.3).clamp(0.0, 1.0);
                              final wobbleX = wobbleT > 0 && wobbleT < 1
                                  ? math.sin(wobbleT * 8 * math.pi) * 2.5
                                  : 0.0;
                              // Phase 3: 펼침 — scale 0.85 → 1.0
                              final openT = ((v - 0.6) / 0.4).clamp(0.0, 1.0);
                              final scale = 0.85 + openT * 0.15;
                              final contentOpacity = 0.3 + wobbleT * 0.4 + openT * 0.3;
                              return Transform.translate(
                                offset: Offset(wobbleX, translateY),
                                child: Transform.scale(
                                  scale: scale,
                                  child: Opacity(
                                    opacity: (enterOpacity * contentOpacity)
                                        .clamp(0.0, 1.0),
                                    child: _buildLetterContent(letter),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                            if (_isOpened) LetterContextBadge(letter: letter),
                            if (_isOpened) ScarcityIndicator(letter: letter),
                            if (_isOpened) _buildReactionBar(context, letter),
                            const SizedBox(height: 12),
                            if (_isOpened)
                              Consumer<AppState>(
                                builder: (ctx, state, _) {
                                  final status = state.getChatStatus(
                                    letter.senderId,
                                  );
                                  if (status == ChatStatus.pendingAgreement) {
                                    return _buildChatInviteCard(
                                      ctx,
                                      letter,
                                      state,
                                    );
                                  }
                                  if (status == ChatStatus.chatting) {
                                    return _buildDMButton(ctx, letter);
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            const SizedBox(height: 24),
                            // 배송 여정
                            if (_isOpened) _buildJourneyCard(letter),
                            const SizedBox(height: 24),
                            // 🎁 쿠폰/교환권 사용 안내 — 브랜드 발송 + redemptionInfo
                            //   존재 OR Build 331 (PR-S1) 발급된 redemptionCode 보유.
                            //   둘 중 하나라도 있으면 box 노출 (PR-S8: code-only 경우도).
                            if (_isOpened &&
                                letter.senderIsBrand &&
                                ((letter.redemptionInfo ?? '').trim().isNotEmpty ||
                                    letter.redemptionCode != null))
                              KeyedSubtree(
                                key: _redemptionBoxKey,
                                child: _buildRedemptionBox(context, letter),
                              ),
                            // 답장 버튼 (AI 편지는 "닿지 않음" 카드로 대체)
                            if (_isOpened) _buildAiLetterNotice(context, letter),
                            // 브랜드 발송인이 답장 미수락으로 설정한 편지는 답장
                            // 버튼 대신 안내만.
                            // Build 259: 브랜드 쿠폰/홍보 letter 는 답장/보관/삭제 3-action.
                            // Build 295: 모든 픽업 letter (일반 + 브랜드) 에 3-action 적용.
                            //   사용자 요청: 픽업 후 수집첩 저장 / 삭제 선택권 제공.
                            if (_isOpened && !letter.senderId.startsWith('ai_'))
                              _buildBrandActionChooser(context, letter),
                            if (_isOpened &&
                                letter.senderIsBrand &&
                                !letter.acceptsReplies)
                              _buildBrandNoReplyNotice(context),
                            // 💎 팔로우 + 🚫 혜택 받지 않기 (Build 259 가시성 강화):
                            // 기존 textbutton 형태 → 색상 강조 chip (배경+테두리).
                            // 본인 발송 편지에는 노출 X.
                            if (_isOpened &&
                                letter.senderIsBrand &&
                                letter.senderId != context.read<AppState>().currentUser.id) ...[
                              const SizedBox(height: 16),
                              _buildBrandFollowMuteChips(context, letter),
                            ],
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext ctx, Letter letter, AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.block_rounded, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.dmBlockUser,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.dmBlockConfirm(letter.senderName),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              l10n.letterReadCancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              state.blockLetterSender(letter.senderId);
              Navigator.pop(dialogCtx);
              Navigator.pop(ctx); // 편지 화면 닫기
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(l10n.dmBlocked(letter.senderName)),
                  backgroundColor: AppColors.bgSurface,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              l10n.dmBlockAction,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext ctx, Letter letter, AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final _reasons = [l10n.letterReadReportReasonAbuse, l10n.letterReadReportReasonSpam, l10n.letterReadReportReasonPrivacy];
    String? selectedReason;
    final customCtrl = TextEditingController();

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sCtx, setS) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.letterReadReportTitle,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.letterReadReportDescription,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                // 이유 3가지
                ..._reasons.map(
                  (r) => GestureDetector(
                    onTap: () => setS(() => selectedReason = r),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selectedReason == r
                            ? AppColors.error.withValues(alpha: 0.12)
                            : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedReason == r
                              ? AppColors.error.withValues(alpha: 0.6)
                              : AppColors.bgSurface,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedReason == r
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 16,
                            color: selectedReason == r
                                ? AppColors.error
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            r,
                            style: TextStyle(
                              color: selectedReason == r
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: selectedReason == r
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 직접 입력
                GestureDetector(
                  onTap: () => setS(() => selectedReason = 'direct'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selectedReason == 'direct'
                          ? AppColors.error.withValues(alpha: 0.12)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedReason == 'direct'
                            ? AppColors.error.withValues(alpha: 0.6)
                            : AppColors.bgSurface,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedReason == 'direct'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 16,
                          color: selectedReason == 'direct'
                              ? AppColors.error
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.letterReadReportCustomInput,
                          style: TextStyle(
                            color: selectedReason == 'direct'
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: selectedReason == 'direct'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selectedReason == 'direct')
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                      controller: customCtrl,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: l10n.letterReadReportHint,
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: AppColors.bgSurface,
                        counterStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.bgSurface,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.bgSurface,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                l10n.letterReadCancel,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      final reason = selectedReason == 'direct'
                          ? (customCtrl.text.trim().isEmpty
                                ? l10n.letterReadReportCustomInput
                                : customCtrl.text.trim())
                          : selectedReason!;
                      state.reportLetter(letter.id, state.currentUser.id, reason: reason);
                      Navigator.pop(dialogCtx);
                      Navigator.pop(ctx); // 편지 화면 닫기
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(l10n.letterReadReportSubmitted(reason)),
                          backgroundColor: AppColors.bgSurface,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
              child: Text(
                l10n.letterReadReportSubmit,
                style: TextStyle(
                  color: selectedReason == null
                      ? AppColors.textMuted
                      : AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionBar(BuildContext ctx, Letter letter) {
    final l10n = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    return Consumer<AppState>(
      builder: (ctx2, state, _) => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.letterReadRatePrompt.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.66,
              ),
            ),
            const SizedBox(height: 14),
            // 별점 + 좋아요 + 인증/신고 (Flexible + spaceBetween 으로 오버플로우 방지)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      final selected = star <= _userRating;
                      return GestureDetector(
                        onTap: () {
                          final prev = _userRating;
                          setState(() => _userRating = star);
                          if (prev == 0) {
                            state.rateLetter(letter.id, star);
                          } else {
                            state.updateRating(letter.id, prev, star);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              selected ? '⭐' : '☆',
                              key: ValueKey('star_${i}_$selected'),
                              style: TextStyle(
                                fontSize: 24,
                                color: selected
                                    ? AppColors.gold
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // 좋아요 버튼
                GestureDetector(
                  onTap: () {
                    if (!_hasLiked) {
                      setState(() => _hasLiked = true);
                      state.likeLetter(letter.id);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _hasLiked
                          ? AppColors.coupon
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: _hasLiked
                              ? const Color(0xFF1A0008)
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${letter.likeCount}',
                          style: TextStyle(
                            color: _hasLiked
                                ? const Color(0xFF1A0008)
                                : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 신고 버튼 — 브랜드 계정은 미표시, 인증 배지로 대체
                if (letter.senderIsBrand)
                  Flexible(
                    flex: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.coupon.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.coupon.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        l10n.letterReadVerifiedAccount,
                        style: TextStyle(
                          color: AppColors.coupon,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                else if (letter.senderTier == LetterSenderTier.premium) ...[
                  // Build 223: Premium 발신자는 "📣 홍보" 배지로 명시.
                  // 일반 사용자가 발송한 게 아니라 자기 SNS·채널 홍보 편지임을
                  // 직관적으로 알 수 있게.
                  Flexible(
                    flex: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.85),
                            AppColors.goldDark.withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '📣 ${l10n.composePremiumPromoBadge}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // 공유 카드 버튼 (스토리·SNS 공유)
                  GestureDetector(
                    onTap: () async {
                      await ShareCardService.shareLetterCard(
                        letter: letter,
                        langCode: state.currentUser.languageCode,
                        tagline: l10n.appTagline,
                        brandName: 'Thiscount',
                      );
                    },
                    child: Tooltip(
                      message: l10n.shareAction,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.ios_share_rounded,
                          color: AppColors.teal,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ]
                else ...[
                  // 공유 카드 버튼 (스토리·SNS 공유)
                  GestureDetector(
                    onTap: () async {
                      await ShareCardService.shareLetterCard(
                        letter: letter,
                        langCode: state.currentUser.languageCode,
                        tagline: l10n.appTagline,
                        brandName: 'Thiscount',
                      );
                    },
                    child: Tooltip(
                      message: l10n.shareAction,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.ios_share_rounded,
                          color: AppColors.teal,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // 차단 버튼
                  GestureDetector(
                    onTap: () => _showBlockDialog(ctx2, letter, state),
                    child: Tooltip(
                      message: l10n.dmBlockAction,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.textMuted.withValues(alpha: 0.30),
                          ),
                        ),
                        child: const Icon(
                          Icons.block_rounded,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // 신고 버튼
                  GestureDetector(
                    onTap: () => _showReportDialog(ctx2, letter, state),
                    child: Tooltip(
                      message: l10n.letterReadReportAction,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.flag_outlined,
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_userRating > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.letterReadRatingConfirm(_userRating),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext ctx, Letter letter) {
    final l10n = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              l10n.letterReadReceivedLetter,
              textAlign: TextAlign.center,
              style: Theme.of(
                ctx,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderCard(Letter letter) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          // v5: 클린 원형 플래그
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                letter.senderCountryFlag,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        letter.isAnonymous ? l10n.letterReadAnonymousSender : letter.senderName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (letter.senderIsBrand) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.coupon,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.letterReadVerifiedBadge.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF1A0008),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                    if (letter.senderId.startsWith('ai_')) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.labelAiCurated.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.letterReadDepartedFrom(CountryL10n.localizedName(letter.senderCountry, l10n.languageCode)),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(letter.sentAt),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SenderMomentLine(letter: letter),
                // SNS 링크 + 팔로우 버튼 (하단 행)
                if (letter.socialLink != null || !letter.isAnonymous) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // SNS 링크
                      if (letter.socialLink != null)
                        GestureDetector(
                          onTap: () => _launchSnsLink(letter.socialLink!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.teal.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.link_rounded,
                                  color: AppColors.teal,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 90,
                                  ),
                                  child: Text(
                                    _trimUrl(letter.socialLink!),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.teal,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (letter.socialLink != null && !letter.isAnonymous)
                        const SizedBox(width: 8),
                      // Follow button (익명 편지에서는 팔로우 불가)
                      if (!letter.isAnonymous)
                        Consumer<AppState>(
                          builder: (ctx, state, _) {
                            final isFollowing = state.isFollowing(
                              letter.senderId,
                            );
                            return GestureDetector(
                              onTap: () {
                                if (isFollowing) {
                                  state.unfollowUser(letter.senderId);
                                } else {
                                  state.followUser(
                                    letter.senderId,
                                    letter.senderName,
                                    country: letter.senderCountry,
                                    flag: letter.senderCountryFlag,
                                  );
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.letterReadFollowed(letter.senderName),
                                      ),
                                      backgroundColor: AppColors.bgDeep,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isFollowing
                                      ? AppColors.teal.withValues(alpha: 0.15)
                                      : AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isFollowing
                                        ? AppColors.teal.withValues(alpha: 0.5)
                                        : AppColors.bgSurface,
                                  ),
                                ),
                                child: Text(
                                  isFollowing ? l10n.letterReadFollowing : l10n.letterReadFollow,
                                  style: TextStyle(
                                    color: isFollowing
                                        ? AppColors.teal
                                        : AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInviteCard(BuildContext ctx, Letter letter, AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.letter,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MUTUAL FOLLOW',
            style: TextStyle(
              color: Color(0xB30A1A00),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.66,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.letterReadMutualFollow(letter.senderName),
            style: const TextStyle(
              color: Color(0xFF0A1A00),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.letterReadStartChatPrompt,
            style: const TextStyle(
              color: Color(0xA60A1A00),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    state.acceptChatInvite(letter.senderId);
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => DmConversationScreen(
                          partnerId: letter.senderId,
                          partnerName: letter.senderName,
                          partnerFlag: letter.senderCountryFlag,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.bgDeep,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      l10n.letterReadStartChat,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => state.declineChatInvite(letter.senderId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x140A1A00),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    l10n.letterReadLater,
                    style: const TextStyle(
                      color: Color(0xCC0A1A00),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDMButton(BuildContext ctx, Letter letter) {
    final l10n = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    return GestureDetector(
      onTap: () => Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => DmConversationScreen(
            partnerId: letter.senderId,
            partnerName: letter.senderName,
            partnerFlag: letter.senderCountryFlag,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 16,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.letterReadDmChat(letter.senderName),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterContent(Letter letter) {
    // Build 182: content 가 비어 있을 가능성 대비 — inbox 에서 최신 letter 를
    // watch. refetchLetterContentIfEmpty 후 AppState 가 notifyListeners 하면
    // 여기가 재빌드되면서 본문이 채워진다.
    final state = context.watch<AppState>();
    final fresh = state.inbox.firstWhere(
      (l) => l.id == letter.id,
      orElse: () => letter,
    );
    letter = fresh;
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final paper = LetterStyles.paper(letter.paperStyle);
    final font = LetterStyles.font(letter.fontStyle);
    final fromLang = LanguageConfig.getLanguageCode(letter.senderCountry);
    final toLang = widget.userLanguageCode;
    final canTranslate = fromLang != toLang;
    final body = _isTranslated && _translatedText != null
        ? _translatedText!
        : letter.content;
    final hasBody = body.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CustomPaint(
        painter: LetterPaperPainter(paper),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 편지지 헤더
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    color: AppColors.gold.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.letterReadToYou,
                    style: TextStyle(
                      color: AppColors.gold.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              // 브랜드 편지 스탬프
              if (letter.senderIsBrand ||
                  letter.letterType == LetterType.brandExpress) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.coupon, AppColors.gold],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.coupon.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏢', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.labelBrandLetter,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              if (letter.letterType == LetterType.brandExpress)
                                const Text(
                                  '⚡ EXPRESS DELIVERY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              // 편지 내용 (원문 또는 번역)
              if (hasBody)
                Text(
                  body,
                  style: font.textStyle.copyWith(color: paper.inkColor),
                )
              else
                // Build 182: content 누락 방어 — 빈 본문일 때 명시적 상태 표시.
                // 쿠폰/교환권 편지는 redemptionInfo/image 가 본문 대신 핵심이므로
                // 아래 섹션에서 이어 렌더된다.
                Row(
                  children: [
                    const SizedBox(width: 2),
                    Icon(
                      Icons.sync_rounded,
                      size: 15,
                      color: paper.inkColor.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.letterReadBodyUnavailable,
                        style: font.textStyle.copyWith(
                          color: paper.inkColor.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              if (canTranslate && _isTranslated && _translatedText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.letterReadTranslated(_langLabel(widget.userLanguageCode)),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (canTranslate && _translateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '⚠️ $_translateError',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (canTranslate)
                GestureDetector(
                  onTap: () async {
                    if (_isTranslating) return;
                    if (_isTranslated) {
                      // 원문으로 되돌리기
                      setState(() {
                        _isTranslated = false;
                        _translateError = null;
                      });
                      return;
                    }
                    setState(() {
                      _isTranslating = true;
                      _translateError = null;
                    });
                    await _doTranslate(letter.content, fromLang, toLang);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    // Build 219: 가시성 강화 — 솔리드 teal 배경 + 흰 텍스트 +
                    // 미세한 그림자. 이전 alpha 0.1 배경 + teal 텍스트 조합은
                    // 어두운 배지 위에서 잘 안 보였음.
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isTranslating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🌐', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 6),
                              Text(
                                _isTranslated
                                    ? l10n.letterReadShowOriginal
                                    : l10n.letterReadTranslate,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              if (canTranslate) const SizedBox(height: 16),
              // 서명
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '— ${letter.isAnonymous ? l10n.letterReadAnonymousStranger : letter.senderName}',
                  style: TextStyle(
                    color: AppColors.gold.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              // 📸 첨부 이미지 표시 (로컬 파일 또는 네트워크 URL 모두 지원)
              if (letter.imageUrl != null) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _openFullscreenImage(context, letter.imageUrl!),
                  child: Hero(
                    tag: 'letter_image_${letter.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildLetterImage(letter.imageUrl!),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.touch_app_rounded,
                      size: 11,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.letterReadTapToEnlarge,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
              // 🔗 소셜 링크 카드
              if (letter.socialLink != null) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _launchSnsLink(letter.socialLink!),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.link_rounded,
                            color: AppColors.teal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.letterReadSenderLink,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                letter.socialLink!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.teal,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.open_in_new_rounded,
                          color: AppColors.teal,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyCard(Letter letter) {
    // Build 259: 한 줄 컴팩트 — 발신국 → 거리 → 도착국 (예: 🇰🇷 → 12 km → 🇯🇵).
    // 이전: 카드 + 2줄 (140px). 이후: 칩 + 1줄 (~36px). 약 75% 공간 회수.
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(letter.senderCountryFlag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            CountryL10n.localizedName(letter.senderCountry, l10n.languageCode),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Text('→', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(width: 8),
          Text(
            '${_calcDistance(letter)}km',
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          const Text('→', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(width: 8),
          Text(
            CountryL10n.localizedName(letter.destinationCountry, l10n.languageCode),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(letter.destinationCountryFlag, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildAiLetterNotice(BuildContext ctx, Letter letter) {
    if (!letter.senderId.startsWith('ai_')) return const SizedBox.shrink();
    final l10n = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.textMuted.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aiLetterNoticeTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.aiLetterNoticeBody,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build 259: 쿠폰/홍보 (브랜드) letter 의 답장 / 보관 / 삭제 3-action 행.
  /// - 답장: 기존 _buildReplyButton 진입점과 같지만 sub-action 으로 축소. 발송
  ///   브랜드가 acceptsReplies=false 면 disabled.
  /// - 보관: letter 를 inbox 에 그대로 두고 화면만 닫음 + 토스트.
  /// - 삭제: 확인 다이얼로그 → state.deleteFromInbox(id) + 화면 닫음 + 토스트.
  Widget _buildBrandActionChooser(BuildContext ctx, Letter letter) {
    final state = ctx.read<AppState>();
    final l10n = AppL10n.of(state.currentUser.languageCode);
    // Build 303 (MED audit): banned 사용자의 reply 경로도 차단 (Build 291 의
    // compose entry 가드 보완). letter 작성자가 acceptsReplies 라도 banned
    // 사용자는 reply 송신 불가.
    // Build 324 (positioning): Free 사용자는 "줍기 전용" — 답장도 발송이라 차단.
    //   버튼은 visible 하되 탭 시 PremiumGateSheet 노출 (가치 어필 + 업그레이드 유도).
    final isPremiumOrBrand =
        state.currentUser.isPremium || state.currentUser.isBrand;
    final canReply = letter.acceptsReplies && !state.currentUser.isBanned;

    Widget btn({
      required IconData icon,
      required Color color,
      required String label,
      required VoidCallback? onTap,
      bool primary = false,
    }) {
      final disabled = onTap == null;
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: primary
                  ? color
                  : color.withValues(alpha: disabled ? 0.04 : 0.10),
              borderRadius: BorderRadius.circular(14),
              border: primary
                  ? null
                  : Border.all(
                      color: color.withValues(alpha: disabled ? 0.15 : 0.4),
                      width: 1,
                    ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: primary
                      ? AppColors.bgDeep
                      : (disabled
                          ? color.withValues(alpha: 0.3)
                          : color),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: primary
                        ? AppColors.bgDeep
                        : (disabled
                            ? color.withValues(alpha: 0.4)
                            : color),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        btn(
          icon: Icons.reply_rounded,
          color: AppColors.textPrimary,
          label: l10n.letterReadReply,
          primary: true,
          onTap: canReply
              ? () {
                  // Build 324: Free 면 답장도 발송이라 차단 — upsell sheet.
                  if (!isPremiumOrBrand) {
                    PremiumGateSheet.show(
                      ctx,
                      featureName: l10n.composeGateFeatureName,
                      featureEmoji: '✉️',
                      description: l10n.composeGateDesc,
                    );
                    return;
                  }
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => ComposeScreen(
                        replyToId: letter.id,
                        replyToName: letter.isAnonymous
                            ? l10n.letterReadAnonymous
                            : letter.senderName,
                      ),
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(width: 8),
        btn(
          icon: Icons.bookmark_outline_rounded,
          color: AppColors.teal,
          label: l10n.letterReadKeep,
          onTap: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(l10n.letterReadKeepToast,
                    style: const TextStyle(color: Colors.white)),
                backgroundColor: AppColors.bgCard,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        btn(
          icon: Icons.delete_outline_rounded,
          color: AppColors.error,
          label: l10n.letterReadDelete,
          onTap: () {
            showDialog(
              context: ctx,
              builder: (dlg) => AlertDialog(
                backgroundColor: AppColors.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                content: Text(
                  l10n.letterReadDeleteConfirm,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dlg),
                    child: Text(
                      l10n.letterReadCancel,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dlg);
                      ctx.read<AppState>().deleteFromInbox(letter.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(l10n.letterReadDeletedToast,
                              style:
                                  const TextStyle(color: Colors.white)),
                          backgroundColor: AppColors.bgCard,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      l10n.letterReadDelete,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Build 259: 팔로우 + 혜택 받지 않기 가시성 강화 chip 행.
  /// 기존 작은 회색 TextButton.icon → 배경+테두리 강조 + 글자 크기 +1.
  Widget _buildBrandFollowMuteChips(BuildContext ctx, Letter letter) {
    final l10n = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    return Builder(builder: (inner) {
      final state = inner.watch<AppState>();
      final followed = state.isBrandFollowed(letter.senderId);
      final muted = state.isBrandMuted(letter.senderId);

      Widget chip({
        required IconData icon,
        required String label,
        required bool active,
        required Color activeColor,
        required VoidCallback onTap,
      }) {
        return Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? activeColor.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active
                      ? activeColor.withValues(alpha: 0.6)
                      : AppColors.textMuted.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: active ? activeColor : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: active
                          ? activeColor
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Row(
        children: [
          chip(
            icon: followed ? Icons.favorite : Icons.favorite_border,
            label: followed
                ? l10n.letterReadUnfollowBrand
                : l10n.letterReadFollowBrand,
            active: followed,
            activeColor: AppColors.gold,
            onTap: () async {
              await ctx.read<AppState>().toggleBrandFollow(letter.senderId);
              if (!inner.mounted) return;
              if (!followed) {
                ScaffoldMessenger.of(inner).showSnackBar(
                  SnackBar(
                    content: Text(l10n.letterReadFollowedToast,
                        style: const TextStyle(color: Colors.white)),
                    backgroundColor: AppColors.bgCard,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          chip(
            icon: muted
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            label:
                muted ? l10n.letterReadUnmuteBrand : l10n.letterReadMuteBrand,
            active: muted,
            activeColor: AppColors.teal,
            onTap: () async {
              await ctx.read<AppState>().toggleBrandMute(letter.senderId);
              if (!inner.mounted) return;
              if (!muted) {
                ScaffoldMessenger.of(inner).showSnackBar(
                  SnackBar(
                    content: Text(l10n.letterReadMutedToast,
                        style: const TextStyle(color: Colors.white)),
                    backgroundColor: AppColors.bgCard,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      );
    });
  }

  /// ❤️ "브랜드 팔로우" 토글 — 뮤트의 반대 (Build 115).
  /// 팔로우된 브랜드는 인박스 상단에 해당 브랜드 편지가 고정된다.
  /// 팔로우와 뮤트는 상호배타 — 팔로우 시 뮤트 자동 해제.
  Widget _buildFollowBrandButton(BuildContext ctx, Letter letter) {
    final l10n = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    return Builder(builder: (inner) {
      final state = inner.watch<AppState>();
      final followed = state.isBrandFollowed(letter.senderId);
      return TextButton.icon(
        icon: Icon(
          followed ? Icons.favorite : Icons.favorite_border,
          size: 16,
          color: followed ? AppColors.gold : AppColors.textMuted,
        ),
        label: Text(
          followed ? l10n.letterReadUnfollowBrand : l10n.letterReadFollowBrand,
          style: TextStyle(
            color: followed ? AppColors.gold : AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () async {
          await ctx.read<AppState>().toggleBrandFollow(letter.senderId);
          if (!inner.mounted) return;
          // 방금 팔로우한 경우에만 토스트 — 해제 시 조용히.
          if (!followed) {
            ScaffoldMessenger.of(inner).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.letterReadFollowedToast,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: AppColors.bgCard,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
      );
    });
  }

  /// 🔕 "이 브랜드 편지 받지 않기" 텍스트 버튼 — 스팸 방지 도구.
  /// 탭 시 AppState 에 senderId 추가/제거, SharedPreferences 영속, 이후
  /// 수집첩에서 해당 브랜드 편지는 숨겨짐. 이미 받은 편지는 남음 (쿠폰 등).
  Widget _buildMuteBrandButton(BuildContext ctx, Letter letter) {
    final l10n = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    return Builder(builder: (inner) {
      final state = inner.watch<AppState>();
      final muted = state.isBrandMuted(letter.senderId);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextButton.icon(
          icon: Icon(
            muted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
            size: 16,
            color: muted ? AppColors.teal : AppColors.textMuted,
          ),
          label: Text(
            muted ? l10n.letterReadUnmuteBrand : l10n.letterReadMuteBrand,
            style: TextStyle(
              color: muted ? AppColors.teal : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () async {
            await ctx.read<AppState>().toggleBrandMute(letter.senderId);
            if (!inner.mounted) return;
            // 방금 뮤트한 경우에만 토스트 — 해제 시 조용히.
            if (!muted) {
              ScaffoldMessenger.of(inner).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.letterReadMutedToast,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: AppColors.bgCard,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
        ),
      );
    });
  }

  /// 🎁 쿠폰/교환권 사용 안내 박스 — 브랜드가 composeBrandRedemptionLabel
  /// 필드에 입력한 자유 텍스트를 본문 아래 티일 강조 박스로 보여준다.
  /// 하단에 "🎫 사용 완료" 버튼 추가 (Build 108) — 수신자가 혜택을 실제로
  /// 쓰고 나면 탭해서 영구적으로 "사용됨" 으로 표시. 브랜드 측에서 전환율
  /// 집계에 활용 가능 (같은 디바이스 기준 로컬, 서버 집계는 후속).
  Widget _buildRedemptionBox(BuildContext ctx, Letter letter) {
    final l10n = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    return Builder(builder: (inner) {
      final state = inner.watch<AppState>();
      final redeemed = state.isLetterRedeemed(letter.id);
      // Build 133: 사용 기한 체크 — 만료된 쿠폰은 사용 완료된 것과 동일하게
      // 비활성 + 취소선. Mark-used 버튼도 숨긴다 (이미 쓸 수 없으므로).
      final expired = letter.isRedemptionExpired;
      final disabled = redeemed || expired;
      // Build 324 (Q1): "사용 진행" 흐름. 픽업 직후 코드/QR 자동 노출 차단.
      //   pending=true (1h 이내) 면 코드 노출 + 카운트다운, 만료 시 자동 redeemed.
      //   호출자가 entry 시점에 consumeElapsedPendingRedemptions 호출 → 이미
      //   만료된 pending 은 redeemed 로 처리됨.
      final pending = state.isPendingRedemption(letter.id);
      final pendingStartedAt = state.pendingRedemptionStartedAt(letter.id);
      // 만료 임박(3일 이내) — 노란 경고 톤으로 카운트다운 강조.
      final expiresAt = letter.redemptionExpiresAt;
      final daysLeft = expiresAt?.difference(DateTime.now()).inDays;
      final expiringSoon =
          !expired && daysLeft != null && daysLeft <= 3;
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: disabled
                ? [
                    const Color(0xFF4A5A75).withValues(alpha: 0.22),
                    const Color(0xFF4A5A75).withValues(alpha: 0.08),
                  ]
                : expiringSoon
                    ? [
                        AppColors.coupon.withValues(alpha: 0.16),
                        AppColors.coupon.withValues(alpha: 0.04),
                      ]
                    : [
                        AppColors.teal.withValues(alpha: 0.14),
                        AppColors.teal.withValues(alpha: 0.04),
                      ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: disabled
                ? const Color(0xFF4A5A75).withValues(alpha: 0.45)
                : expiringSoon
                    ? AppColors.coupon.withValues(alpha: 0.55)
                    : AppColors.teal.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    expired
                        ? l10n.letterReadRedemptionExpiredHeader
                        : redeemed
                            ? l10n.letterReadRedemptionUsedHeader
                            : l10n.letterReadRedemptionHeader,
                    style: TextStyle(
                      color: disabled
                          ? AppColors.textMuted
                          : expiringSoon
                              ? AppColors.coupon
                              : AppColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (redeemed)
                  _statusBadge(
                    icon: Icons.check_circle_rounded,
                    label: l10n.letterReadRedemptionUsedBadge,
                    color: AppColors.teal,
                  )
                else if (expired)
                  _statusBadge(
                    icon: Icons.timer_off_rounded,
                    label: l10n.letterReadRedemptionExpiredBadge,
                    color: const Color(0xFFE07A5F),
                  ),
              ],
            ),
            // Build 133: 유효기간 카운트다운 — 만료 상태가 아니면서 만료일이
            // 있을 때만. 임박(≤3일)이면 주황색, 그 외엔 teal.
            if (expiresAt != null && !redeemed) ...[
              const SizedBox(height: 6),
              _buildExpiryCountdown(expiresAt, expired, expiringSoon, l10n),
            ],
            const SizedBox(height: 8),
            // Build 324 (Q1): 코드/QR 노출은 pending=true (사용 진행) 또는
            //   redeemed=true (이미 사용) 일 때만. 픽업 직후 (둘 다 false) 면
            //   "🎁 사용 진행" 버튼만 노출 → 실수 노출 차단 + 의도적 사용 동의.
            if (pending || redeemed || expired) ...[
              // Build 331 (PR-S2): Brand 발행 redemptionCode 가 있으면 최상단에
              //   Code128 바코드 + 큰 코드 텍스트 panel 노출. 매장 POS 1D 스캔
              //   또는 코드 수동 입력 둘 다 가능.
              // Build 344 (PR-S15 4차 시뮬레이션 revert): pending 외에도 redeemed
              //   / expired 상태에서 panel 노출 (disabled 스타일 + line-through
              //   + "이미 사용됨" 헤더). 사용자가 "내가 본 코드 뭐였지?" 재조회
              //   가능 — pending only 였을 땐 일반 사용자가 코드 재조회 경로 0
              //   (BrandInsights 는 Brand 전용). 매장 측 혼란은 disabled 표기로
              //   해소 (POS 가 거절해도 화면에 "사용 완료" 명시).
              if (letter.redemptionCode != null)
                _RedemptionCodePanel(
                  code: letter.redemptionCode!,
                  redeemed: redeemed,
                  expired: expired,
                  l10n: l10n,
                ),
              // Build 335 (PR-S7 시뮬레이션 P1 #7): redemptionCode 와 redemptionInfo
              //   둘 다 있는 경우 시각 구분 헤더 추가 — 매장이 "어떤 코드 ?"
              //   헷갈리지 않도록.
              if (letter.redemptionCode != null
                  && letter.redemptionInfo != null
                  && (letter.redemptionInfo?.trim().isNotEmpty ?? false)) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 4),
                  child: Text(
                    l10n.redemptionInfoSubheader,
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.9),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
              if (letter.redemptionInfo != null
                  && (letter.redemptionInfo?.trim().isNotEmpty ?? false))
                _buildRedemptionContent(ctx, inner, letter, l10n, disabled),
            ] else ...[
              // 코드/QR 가려진 상태 안내 + 사용 진행 hint.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.letterReadRedemptionHiddenHint,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // 사용 진행 카운트다운 + "지금 사용 완료" 옵션 (pending 일 때만).
            if (pending && pendingStartedAt != null) ...[
              const SizedBox(height: 10),
              _RedemptionCountdown(startedAt: pendingStartedAt, l10n: l10n),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ctx.read<AppState>().markLetterRedeemed(letter.id);
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: Text(
                    l10n.letterReadRedemptionMarkUsed,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: const BorderSide(color: AppColors.teal, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ] else if (!disabled && !pending) ...[
              const SizedBox(height: 12),
              // "사용 진행" 거대 CTA — 탭 시 코드/QR 노출 + 1h 카운트다운 시작.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ctx.read<AppState>().startRedemption(letter.id);
                    if (!inner.mounted) return;
                    ScaffoldMessenger.of(inner).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.letterReadRedemptionStartedToast,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppColors.teal,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_2_rounded, size: 22),
                  label: Text(
                    l10n.letterReadRedemptionStartCta,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// Build 324 (Q1): 1h 카운트다운 위젯 — 사용 진행 시작 ~ 1h 자동 완료.
  ///   매 30s 자동 rebuild (남은 시간 표시 정확성).

  /// 브랜드 발송인이 "답장 받지 않음" 으로 설정한 편지에 표시되는 안내.
  /// Build 133: redemption box 우상단 뱃지 (used / expired 공통 템플릿).
  Widget _statusBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  /// Build 133: 유효기간 카운트다운 — 날짜 + "N일 남음". 만료일이 있을 때만
  /// 렌더. 임박(≤3일)이면 주황, 그 외 teal. 만료됐거나 사용완료면 숨김.
  Widget _buildExpiryCountdown(
    DateTime expiresAt,
    bool expired,
    bool expiringSoon,
    AppL10n l10n,
  ) {
    final dateStr =
        '${expiresAt.year}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.day.toString().padLeft(2, '0')}';
    final daysLeft = expiresAt.difference(DateTime.now()).inDays;
    final color = expired
        ? AppColors.textMuted
        : expiringSoon
            ? AppColors.coupon
            : AppColors.teal;
    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          l10n.letterReadRedemptionExpiresOn(dateStr),
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (!expired) ...[
          const SizedBox(width: 6),
          Text(
            '·',
            style: TextStyle(color: color.withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 6),
          Text(
            daysLeft == 0
                ? l10n.letterReadRedemptionTodayOnly
                : l10n.letterReadRedemptionDaysLeft(daysLeft),
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  /// Build 131: redemption box 내부 본문 — 카테고리별 분기 렌더링.
  ///   voucher → redemptionInfo 가 URL/로컬경로처럼 보이면 이미지 인라인,
  ///              아니면 SelectableText fallback
  ///   coupon  → 코드 텍스트 + 📋 복사 버튼
  ///   general → 기존 SelectableText (하위 호환)
  Widget _buildRedemptionContent(
    BuildContext ctx,
    BuildContext inner,
    Letter letter,
    AppL10n l10n,
    bool redeemed,
  ) {
    final info = letter.redemptionInfo ?? '';
    final baseStyle = TextStyle(
      color: redeemed ? AppColors.textMuted : AppColors.textPrimary,
      fontSize: 14,
      height: 1.45,
      fontWeight: FontWeight.w600,
      decoration: redeemed ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: AppColors.textMuted.withValues(alpha: 0.5),
    );

    if (letter.category == LetterCategory.voucher && _looksLikeImageRef(info)) {
      return _buildRedemptionImage(ctx, info, redeemed, l10n);
    }
    if (letter.category == LetterCategory.coupon && info.trim().isNotEmpty) {
      return _buildRedemptionCoupon(inner, info, baseStyle, redeemed, l10n);
    }
    return SelectableText(info, style: baseStyle);
  }

  bool _looksLikeImageRef(String v) {
    final t = v.trim();
    if (t.isEmpty) return false;
    if (t.startsWith('http://') || t.startsWith('https://')) return true;
    // 절대경로(로컬 파일) — iOS·Android 모두 `/` 시작.
    if (t.startsWith('/') || t.startsWith('file://')) return true;
    return false;
  }

  Widget _buildRedemptionImage(
    BuildContext ctx,
    String info,
    bool redeemed,
    AppL10n l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openFullscreenImage(ctx, info),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: Opacity(
                opacity: redeemed ? 0.55 : 1.0,
                child: _buildLetterImage(info),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.letterReadVoucherShowAtCounter,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRedemptionCoupon(
    BuildContext inner,
    String code,
    TextStyle baseStyle,
    bool redeemed,
    AppL10n l10n,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SelectableText(
            code,
            style: baseStyle.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: redeemed
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: code.trim()));
                  if (!inner.mounted) return;
                  ScaffoldMessenger.of(inner).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.letterReadCouponCopied,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: AppColors.teal,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: redeemed
                  ? AppColors.bgSurface
                  : AppColors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: redeemed
                    ? AppColors.textMuted.withValues(alpha: 0.3)
                    : AppColors.teal.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.copy_rounded,
                  size: 13,
                  color: redeemed ? AppColors.textMuted : AppColors.teal,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.letterReadCouponCopyBtn,
                  style: TextStyle(
                    color: redeemed ? AppColors.textMuted : AppColors.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 답장 버튼 자리를 대신해 "이 캠페인은 답장을 받지 않아요" 한 줄 카드.
  Widget _buildBrandNoReplyNotice(BuildContext ctx) {
    final l10n = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Row(
        children: [
          const Text('🔕', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.letterReadBrandNoReply,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyButton(BuildContext ctx, Letter letter) {
    final state = ctx.read<AppState>();
    final l10n = AppL10n.of(state.currentUser.languageCode);
    // Build 324 (positioning): Free 사용자는 답장 차단 — 발송 = Premium/Brand.
    final isPremiumOrBrand =
        state.currentUser.isPremium || state.currentUser.isBrand;
    // 답장 1회 제한을 제거 — 유저는 같은 편지에 여러 번 답장 가능.
    // `hasReplied` 플래그는 UI 상에서 "최근 답장함" 힌트로만 쓰고, 버튼 자체는
    // 항상 활성 상태로 둔다.
    final recentlyReplied = letter.hasReplied;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () {
            if (!isPremiumOrBrand) {
              PremiumGateSheet.show(
                ctx,
                featureName: l10n.composeGateFeatureName,
                featureEmoji: '✉️',
                description: l10n.composeGateDesc,
              );
              return;
            }
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => ComposeScreen(
                  replyToId: letter.id,
                  replyToName: letter.isAnonymous
                      ? l10n.letterReadAnonymous
                      : letter.senderName,
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              recentlyReplied
                  ? l10n.letterReadReplyAgain
                  : l10n.letterReadReply,
              style: const TextStyle(
                color: AppColors.bgDeep,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
        if (recentlyReplied)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.letterReadRepliedHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  /// URL에서 표시용 짧은 텍스트 추출 (https://www. 제거, 경로 축약)
  String _trimUrl(String url) {
    var display = url
        .replaceFirst(RegExp(r'^https?://(www\.)?'), '')
        .replaceFirst(RegExp(r'/$'), '');
    if (display.length > 24) display = '${display.substring(0, 22)}…';
    return display;
  }

  /// 이미지 URL이 로컬 파일 경로인지 네트워크 URL인지 판별하여 적절한 위젯 반환
  // ── 풀스크린 이미지 뷰어 ──────────────────────────────────────────────────
  void _openFullscreenImage(BuildContext context, String imageUrl) {
    final isVoucher = widget.letter.category == LetterCategory.voucher;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenImageViewer(
          imageUrl: imageUrl,
          heroTag: 'letter_image_${widget.letter.id}',
          isVoucher: isVoucher,
        ),
      ),
    );
  }

  Widget _buildLetterImage(String imageUrl) {
    final isNetwork =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    // Build 304: 디바이스 픽셀 비율에 맞춰 디코드 해상도 제한 — 서버 원본이
    // 4096px 라도 메모리는 화면 폭만큼만 차지 (decode OOM 회피).
    final mq = MediaQuery.maybeOf(context);
    final cacheW = mq == null
        ? 1024
        : (mq.size.width * mq.devicePixelRatio).round();
    if (isNetwork) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        cacheWidth: cacheW,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 180,
            color: AppColors.bgCard,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
                color: AppColors.teal,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    } else {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imagePlaceholder(),
        );
      }
      return _imagePlaceholder();
    }
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textMuted,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              AppL10n.of(context.read<AppState>().currentUser.languageCode).letterReadImageLoadFailed,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return l10n.letterReadMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.letterReadHoursAgo(diff.inHours);
    return l10n.letterReadDaysAgo(diff.inDays);
  }

  String _calcDistance(Letter letter) {
    final dist = letter.originLocation.distanceTo(letter.destinationLocation);
    return (dist / 1000).toStringAsFixed(0);
  }
}

String _langLabel(String code) {
  const labels = {
    'ko': '한국어',
    'en': 'English',
    'ja': '日本語',
    'zh': '中文',
    'fr': 'Français',
    'de': 'Deutsch',
    'es': 'Español',
    'pt': 'Português',
  };
  return labels[code] ?? code;
}

/// Build 324 (Q1): redemption "사용 진행" → 1h auto-complete 카운트다운.
///   30s 주기 rebuild 로 남은 시간 표시. 0 도달 시 부모 ChangeNotifier 의
///   consumeElapsedPendingRedemptions 가 markLetterRedeemed 호출 → 자동 사용 완료.
class _RedemptionCountdown extends StatefulWidget {
  final DateTime startedAt;
  final AppL10n l10n;
  const _RedemptionCountdown({required this.startedAt, required this.l10n});

  @override
  State<_RedemptionCountdown> createState() => _RedemptionCountdownState();
}

class _RedemptionCountdownState extends State<_RedemptionCountdown> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
      // 1h 경과 시 AppState 에서 자동 redeemed 처리 — 다음 rebuild 에 반영.
      final remaining = _remaining;
      if (remaining.isNegative || remaining == Duration.zero) {
        context.read<AppState>().consumeElapsedPendingRedemptions();
        _ticker?.cancel();
      }
    });
  }

  Duration get _remaining {
    final elapsed = DateTime.now().difference(widget.startedAt);
    // Build 337 (PR-S8): TTL 1h → 2h (AppState._pendingRedemptionTtl 와 일치).
    //   한국 매장 점심·저녁 줄 + 도착 시간 합쳐 1h 초과 케이스 대응.
    const ttl = Duration(hours: 2);
    return ttl - elapsed;
  }

  @override
  void dispose() {
    // Build 351 (PR-V1 시뮬레이션 P2): cancel 후 null 명시 — 외부 reference 가
    //   timer 객체에 남아 있어도 callback chain 끊기 + 메모리 해제 보장.
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _remaining;
    final mins = r.inMinutes.clamp(0, 60);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_rounded, size: 14, color: AppColors.teal),
          const SizedBox(width: 6),
          Text(
            widget.l10n.letterReadRedemptionCountdown(mins),
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.gold.withValues(alpha: 0.03);
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── 풀스크린 이미지 뷰어 위젯 ─────────────────────────────────────────────────
class _FullscreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String heroTag;
  // Build 183: 교환권 이미지 전용 플래그 — screenshot/recording 차단 활성.
  final bool isVoucher;

  const _FullscreenImageViewer({
    required this.imageUrl,
    required this.heroTag,
    this.isVoucher = false,
  });

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  bool _isSaving = false;
  bool _savedOk = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVoucher) {
      // Android: FLAG_SECURE — 시스템 레벨 스크린샷/recording 차단.
      // iOS: capture 감지 시 내부 blur overlay (플러그인 제공).
      ScreenProtector.preventScreenshotOn();
      ScreenProtector.protectDataLeakageWithBlur();
    }
  }

  @override
  void dispose() {
    if (widget.isVoucher) {
      ScreenProtector.preventScreenshotOff();
      ScreenProtector.protectDataLeakageWithBlurOff();
    }
    super.dispose();
  }

  Future<void> _saveImage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final isNetwork =
          widget.imageUrl.startsWith('http://') ||
          widget.imageUrl.startsWith('https://');

      if (isNetwork) {
        // 네트워크 이미지: 다운로드 후 임시 파일로 저장
        final response = await http.get(Uri.parse(widget.imageUrl));
        if (response.statusCode != 200) throw Exception('download failed');
        final tmpDir = await getTemporaryDirectory();
        final ext = widget.imageUrl.contains('.png') ? 'png' : 'jpg';
        final tmpFile = File(
          '${tmpDir.path}/thiscount_photo_${DateTime.now().millisecondsSinceEpoch}.$ext',
        );
        await tmpFile.writeAsBytes(response.bodyBytes);
        await Gal.putImage(tmpFile.path);
      } else {
        // 로컬 파일
        await Gal.putImage(widget.imageUrl);
      }
      if (mounted)
        setState(() {
          _isSaving = false;
          _savedOk = true;
        });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _savedOk = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.letterReadSaveFailed),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final isNetwork =
        widget.imageUrl.startsWith('http://') ||
        widget.imageUrl.startsWith('https://');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 배경 탭으로 닫기
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const SizedBox.expand(
              child: ColoredBox(color: Colors.black),
            ),
          ),
          // 중앙 이미지 (확대/축소)
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5.0,
              child: Hero(
                tag: widget.heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: isNetwork
                      ? Image.network(
                          widget.imageUrl,
                          fit: BoxFit.contain,
                          // Build 304: 5x 줌까지 허용하면서 메모리 cap.
                          // 2048px 면 일반 폰 화면 (414×3=1242) 5x 확대 시
                          // 충분히 선명, OOM 위험은 차단.
                          cacheWidth: 2048,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white54,
                            size: 64,
                          ),
                        )
                      : Image.file(
                          File(widget.imageUrl),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white54,
                            size: 64,
                          ),
                        ),
                ),
              ),
            ),
          ),
          // 상단 닫기 버튼
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 하단 저장 버튼
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: GestureDetector(
                  onTap: _saveImage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _savedOk
                          ? Colors.green.shade700
                          : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSaving)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black54,
                            ),
                          )
                        else
                          Icon(
                            _savedOk
                                ? Icons.check_rounded
                                : Icons.download_rounded,
                            size: 20,
                            color: _savedOk ? Colors.white : Colors.black87,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _isSaving
                              ? l10n.letterReadSaving
                              : _savedOk
                              ? l10n.letterReadSaved
                              : l10n.letterReadSavePhoto,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _savedOk ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Build 331 (PR-S2): 매장 POS 스캔용 코드 panel.
///
/// 구성:
///   1) Code128 1D 바코드 (가로 길게, 흰 배경 + 검정 바) — POS 스캐너 인식률 ↑
///   2) TC-XXXX-XXXX 큰 텍스트 (매장이 수동 입력 시 직접 읽음)
///   3) 클립보드 복사 버튼
///   4) "매장에 이 화면을 보여주세요" 안내
///
/// 화면 밝기 자동 max — POS 스캐너가 어두운 LCD 에서 인식률 떨어지는 문제 차단.
/// dispose 시 원래 밝기로 복원.
class _RedemptionCodePanel extends StatefulWidget {
  final String code; // raw 8자
  final bool redeemed;
  final bool expired;
  // Build 336 (PR-S5): i18n - 호출자가 사용자 언어 AppL10n 주입.
  final AppL10n l10n;

  const _RedemptionCodePanel({
    required this.code,
    required this.redeemed,
    required this.expired,
    required this.l10n,
  });

  @override
  State<_RedemptionCodePanel> createState() => _RedemptionCodePanelState();
}

class _RedemptionCodePanelState extends State<_RedemptionCodePanel> {
  // Build 345 (PR-S16 5차 시뮬레이션 P1): RedemptionCode.verify SHA256 결과
  //   캐싱 — 매 rebuild 마다 재계산하던 성능 오버헤드 차단. 코드 자체는
  //   StatefulWidget lifecycle 동안 불변.
  late final bool _codeValid = RedemptionCode.verify(widget.code);

  // Build 337 (PR-S8 시뮬레이션 P1 #8): 다중 panel reference counter.
  //   panel A initState → save orig + boost to 1.0
  //   panel A 위에 panel B initState → counter++ (밝기는 이미 1.0)
  //   panel B dispose → counter-- (아직 A 가 있으면 그대로 1.0 유지)
  //   panel A dispose → counter == 0 → 진짜 복원
  //   이전엔 각 panel 이 자기 saved 밝기로 복원 → panel B 가 panel A 의
  //   "최초 잘못된 saved" 인 1.0 으로 복원하던 버그.
  static int _activeCount = 0;
  static double? _originalBrightness;

  bool _registered = false;
  // Build 356 (PR-Y1 Y 시뮬레이션 P2): redemption code reveal 시 screenshot 차단.
  // Build 357 (PR-Z1 Z 시뮬레이션 P0): static reference counter — 다중 panel
  //   중첩 시 한 panel dispose 가 다른 panel 의 보호도 해제하던 race 차단.
  //   voucher fullscreen viewer 와 정확히 같은 패턴.
  static int _screenProtectCount = 0;
  bool _screenProtectOn = false;

  @override
  void initState() {
    super.initState();
    if (!widget.redeemed && !widget.expired) {
      _maxBrightness();
      _screenProtectOn = true;
      try {
        if (_screenProtectCount == 0) {
          ScreenProtector.preventScreenshotOn();
          ScreenProtector.protectDataLeakageWithBlur();
        }
        _screenProtectCount++;
      } catch (_) {/* 일부 플랫폼 미지원 — 무시 */}
    }
  }

  @override
  void dispose() {
    if (_screenProtectOn) {
      try {
        _screenProtectCount--;
        if (_screenProtectCount <= 0) {
          _screenProtectCount = 0;
          ScreenProtector.preventScreenshotOff();
          ScreenProtector.protectDataLeakageWithBlurOff();
        }
      } catch (_) {/* swallow */}
    }
    if (_registered) {
      _activeCount--;
      if (_activeCount <= 0) {
        _activeCount = 0;
        final orig = _originalBrightness;
        _originalBrightness = null;
        if (orig != null) {
          try {
            unawaited(
              ScreenBrightness.instance
                  .setApplicationScreenBrightness(orig),
            );
          } catch (_) {/* swallow */}
        }
      }
    }
    super.dispose();
  }

  Future<void> _maxBrightness() async {
    try {
      // 첫 panel 만 원래 밝기 캡처 — 이미 1.0 이면 캡처해도 1.0 (다시 1.0 으로
      //   복원해도 무관). 이후 panel 들은 단순 counter increment.
      if (_activeCount == 0) {
        _originalBrightness =
            await ScreenBrightness.instance.application;
      }
      _activeCount++;
      _registered = true;
      await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);
    } catch (_) {
      // 일부 기기/플랫폼 미지원 → 무시. counter 는 register 안 되어 dispose
      //   시점에 복원 시도도 안 함.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build 344 (PR-S15 4차 시뮬레이션 P0): _sanitizeRedemptionCode 가 invalid
    //   코드도 보존 → panel 단계에서 형식 검증 후 BarcodeWidget crash 차단.
    if (!_codeValid) {
      // 코드는 보존하되 panel 안 보임 — letter_read 의 다른 안내가 표시됨.
      return const SizedBox.shrink();
    }
    final disabled = widget.redeemed || widget.expired;
    final formatted = RedemptionCode.formatForDisplay(widget.code);
    return Container(
      // Build 335 (PR-S7 시뮬레이션 P1 #9): 좌우 padding 14 → 6 으로 줄여
      //   barcode 폭 확장. iPhone 12 mini 기준 290px → 330px 로 ↑.
      //   POS 스캐너 인식률 향상. 높이도 72 → 88 로 증가 (1D 권장 ≥ 80px).
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
      decoration: BoxDecoration(
        color: disabled
            ? AppColors.bgSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: disabled
              ? AppColors.textMuted.withValues(alpha: 0.3)
              : AppColors.teal.withValues(alpha: 0.5),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1D Code128 바코드 — 흰 배경 + 검은 바 강제 (POS 스캐너 호환).
          // Build 335 (PR-S7): 헤더 라벨 추가 — "이게 진짜 코드" 시각 강조.
          //   redemptionInfo 와 시각 혼동 차단 (P1 #7).
          // Build 345 (PR-S16 5차 시뮬레이션 P1): disabled 헤더 일관성 — 항상
          //   표시하되 disabled 시 회색 톤 → 접근성 정보 손실 차단.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Row(
              children: [
                const Text('🛒', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  widget.l10n.redemptionPanelHeader,
                  style: TextStyle(
                    color: disabled
                        ? AppColors.textMuted
                        : AppColors.teal.withValues(alpha: 0.95),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          // Build 340 (PR-S11 2차 시뮬레이션 P1): 스크린리더용 Semantics 라벨.
          //   바코드 위젯 자체는 시각 전용 → screen reader 가 "image" 라고만
          //   읽음. 명시 label 로 "사용 코드 X" 알려줌. excludeSemantics 로 본
          //   raw 안 텍스트 (없음 - drawText=false) 와 중복 차단.
          Semantics(
            label: widget.l10n.redemptionPanelHeader,
            value: formatted,
            excludeSemantics: true,
            child: SizedBox(
              height: 88,
              child: Opacity(
                opacity: disabled ? 0.4 : 1.0,
                child: BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: widget.code,
                  drawText: false,
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 큰 코드 텍스트 — 매장이 수동 입력 시 읽음. monospace 로 0/O 혼동 방지.
          // Build 341 (PR-S12 2차 시뮬레이션 P1): textScaler ↑ 사용자 overflow
          //   방지 — 큰 코드 텍스트는 FittedBox 로 자동 축소.
          GestureDetector(
            onLongPress: disabled
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: formatted));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          widget.l10n.redemptionCodeCopied,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppColors.teal,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatted,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: disabled ? AppColors.textMuted : const Color(0xFF0A1F1A),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: 2.0,
                  decoration: disabled
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            disabled
                ? (widget.redeemed
                    ? widget.l10n.redemptionPanelHintUsed
                    : widget.l10n.redemptionPanelHintExpired)
                : widget.l10n.redemptionPanelHintActive,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: disabled ? AppColors.textMuted : AppColors.teal,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
