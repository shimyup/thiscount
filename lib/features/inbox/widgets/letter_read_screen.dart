import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/letter_style.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_names.dart';
import '../../../core/localization/language_config.dart';
import '../../../models/letter.dart';
import '../../../state/app_state.dart';
import '../../compose/screens/compose_screen.dart';
import '../../../models/direct_message.dart';
import '../../dm/dm_conversation_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _openController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _openAnimation = CurvedAnimation(
      parent: _openController,
      curve: Curves.easeOutBack,
    );
    // 봉투 열기 애니메이션 시작
    Future.delayed(const Duration(milliseconds: 300), () {
      _openController.forward().then((_) {
        if (mounted) setState(() => _isOpened = true);
      });
    });
  }

  @override
  void dispose() {
    _openController.dispose();
    super.dispose();
  }

  // SNS 링크 열기
  Future<void> _launchSnsLink(String rawUrl) async {
    // http(s):// 없으면 자동 추가
    final urlStr = rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl';
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.letterReadCannotOpenLink(urlStr)),
          backgroundColor: const Color(0xFF1F2D44),
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
    } catch (_) {
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            // 발신자 정보 카드
                            _buildSenderCard(letter),
                            const SizedBox(height: 20),
                            // 편지 본문
                            Transform.scale(
                              scale: _openAnimation.value.clamp(0.8, 1.0),
                              child: Opacity(
                                opacity: _openAnimation.value.clamp(0.0, 1.0),
                                child: _buildLetterContent(letter),
                              ),
                            ),
                            const SizedBox(height: 12),
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
                            // 답장 버튼
                            if (_isOpened) _buildReplyButton(context, letter),
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
                              : const Color(0xFF1F2D44),
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
                            : const Color(0xFF1F2D44),
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
                            color: Color(0xFF1F2D44),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF1F2D44),
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
                          backgroundColor: const Color(0xFF1F2D44),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2D44)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                const SizedBox(width: 6),
                Text(
                  l10n.letterReadRatePrompt,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
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
                          ? AppColors.gold.withValues(alpha: 0.15)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _hasLiked
                            ? AppColors.gold.withValues(alpha: 0.5)
                            : const Color(0xFF1F2D44),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _hasLiked ? '❤️' : '🤍',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${letter.likeCount}',
                          style: TextStyle(
                            color: _hasLiked
                                ? AppColors.gold
                                : AppColors.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
                        color: const Color(0xFFFF8A5C).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF8A5C).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        l10n.letterReadVerifiedAccount,
                        style: TextStyle(
                          color: Color(0xFFFF8A5C),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                else
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 국가 플래그
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                letter.senderCountryFlag,
                style: const TextStyle(fontSize: 30),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // 브랜드 인증 배지
                    if (letter.senderIsBrand) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFF8A5C,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(
                              0xFFFF8A5C,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          l10n.letterReadVerifiedBadge,
                          style: TextStyle(
                            color: Color(0xFFFF8A5C),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.flight_takeoff_rounded,
                      size: 12,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.letterReadDepartedFrom(CountryL10n.localizedName(letter.senderCountry, l10n.languageCode)),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(letter.sentAt),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
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
                                      backgroundColor: const Color(0xFF0D1421),
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
                                        : const Color(0xFF1F2D44),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.letterReadMutualFollow(letter.senderName),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.letterReadStartChatPrompt,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        l10n.letterReadStartChat,
                        style: TextStyle(
                          color: AppColors.teal,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1F2D44)),
                  ),
                  child: Text(
                    l10n.letterReadLater,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => DmConversationScreen(
              partnerId: letter.senderId,
              partnerName: letter.senderName,
              partnerFlag: letter.senderCountryFlag,
            ),
          ),
        ),
        icon: const Text('💬', style: TextStyle(fontSize: 16)),
        label: Text(
          l10n.letterReadDmChat(letter.senderName),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal,
          side: BorderSide(color: AppColors.teal.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildLetterContent(Letter letter) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final paper = LetterStyles.paper(letter.paperStyle);
    final font = LetterStyles.font(letter.fontStyle);
    final fromLang = LanguageConfig.getLanguageCode(letter.senderCountry);
    final toLang = widget.userLanguageCode;
    final canTranslate = fromLang != toLang;
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
                          colors: [Color(0xFFFF8C00), Color(0xFFFFD700)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8C00).withValues(alpha: 0.35),
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
                              const Text(
                                'BRAND LETTER',
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
              Text(
                _isTranslated && _translatedText != null
                    ? _translatedText!
                    : letter.content,
                style: font.textStyle.copyWith(color: paper.inkColor),
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
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: _isTranslating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.teal,
                            ),
                          )
                        : Text(
                            _isTranslated ? l10n.letterReadShowOriginal : l10n.letterReadTranslate,
                            style: const TextStyle(
                              color: AppColors.teal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2D44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, color: AppColors.teal, size: 16),
              const SizedBox(width: 6),
              Text(
                l10n.letterReadDeliveryJourney,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                letter.senderCountryFlag,
                style: const TextStyle(fontSize: 24),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 1,
                      color: AppColors.gold.withValues(alpha: 0.3),
                    ),
                    const Icon(
                      Icons.flight_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                  ],
                ),
              ),
              Text(
                letter.destinationCountryFlag,
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CountryL10n.localizedName(letter.senderCountry, l10n.languageCode),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              Text(
                '${_calcDistance(letter)} km',
                style: const TextStyle(color: AppColors.teal, fontSize: 11),
              ),
              Text(
                CountryL10n.localizedName(letter.destinationCountry, l10n.languageCode),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyButton(BuildContext ctx, Letter letter) {
    final l10n = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    final alreadyReplied = letter.hasReplied;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: alreadyReplied
            ? null
            : () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => ComposeScreen(
                    replyToId: letter.id,
                    replyToName: letter.isAnonymous ? l10n.letterReadAnonymous : letter.senderName,
                  ),
                ),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: alreadyReplied
              ? AppColors.bgSurface
              : AppColors.bgCard,
          foregroundColor: alreadyReplied
              ? AppColors.textMuted
              : AppColors.gold,
          side: BorderSide(
            color: alreadyReplied ? const Color(0xFF1F2D44) : AppColors.gold,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              alreadyReplied ? '✅' : '💌',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              alreadyReplied ? l10n.letterReadReplied : l10n.letterReadReply,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenImageViewer(
          imageUrl: imageUrl,
          heroTag: 'letter_image_${widget.letter.id}',
        ),
      ),
    );
  }

  Widget _buildLetterImage(String imageUrl) {
    final isNetwork =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
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

  const _FullscreenImageViewer({required this.imageUrl, required this.heroTag});

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  bool _isSaving = false;
  bool _savedOk = false;

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
          '${tmpDir.path}/lettergo_photo_${DateTime.now().millisecondsSinceEpoch}.$ext',
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
