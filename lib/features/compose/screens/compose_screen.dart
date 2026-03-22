import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/letter_style.dart';
import '../../../core/data/country_cities.dart';
import '../../../state/app_state.dart';

class ComposeScreen extends StatefulWidget {
  final String? replyToId;
  final String? replyToName;

  const ComposeScreen({super.key, this.replyToId, this.replyToName});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen>
    with SingleTickerProviderStateMixin {
  final _contentController = TextEditingController();
  final _socialLinkController = TextEditingController();
  final _contentFocus = FocusNode();

  late AnimationController _sendController;
  late Animation<double> _sendAnim;

  // 목적지 (기본값: 랜덤) — 빈 문자열로 초기화 후 initState에서 즉시 채움
  String _selectedCountry = '';
  String _selectedFlag = '';
  String _selectedCity = ''; // 도시/구 단위
  double _destLat = 0;
  double _destLng = 0;

  int _paperStyle = 0;
  int _fontStyle = 0;
  String? _deliveryEmoji; // 유저가 고른 배송 이모티콘 (null = 운송수단 기본값)

  bool _isRandom = true;
  bool _isAnonymous = true;
  bool _attachSocial = false;
  bool _isSending = false;
  int _charCount = 0;
  static const int _maxChars = 500;

  static const List<String> _bannedWords = [
    '욕설',
    'fuck',
    'shit',
    'bitch',
    'asshole',
  ];

  @override
  void initState() {
    super.initState();
    _sendController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _sendAnim = CurvedAnimation(parent: _sendController, curve: Curves.easeOut);
    _contentController.addListener(
      () => setState(() => _charCount = _contentController.text.length),
    );

    // 첫 빌드 전에 필드를 직접 설정 (setState 없이 — 아직 마운트 안 됨)
    final dest = AppState.randomDestination();
    _selectedCountry = dest['name']!;
    _selectedFlag = dest['flag']!;
    _destLat = double.parse(dest['lat']!);
    _destLng = double.parse(dest['lng']!);

    // 첫 프레임 후 사용자 나라를 제외하고 다시 랜덤 선택, SNS 자동 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      _pickRandomDestination(excludeCountry: state.currentUser.country);
      // 프로필에 SNS가 설정된 경우 자동으로 체크
      final userSns = state.currentUser.socialLink;
      if (userSns != null && userSns.isNotEmpty) {
        setState(() {
          _attachSocial = true;
          _socialLinkController.text = userSns;
        });
      }
    });
  }

  void _pickRandomDestination({String? excludeCountry}) {
    final dest = AppState.randomDestination(excludeCountry: excludeCountry);
    final countryName = dest['name']!;
    // 해당 국가의 랜덤 도시 선택
    final cityData = CountryCities.randomCity(countryName);
    setState(() {
      _selectedCountry = countryName;
      _selectedFlag = dest['flag']!;
      _selectedCity = cityData?['name'] as String? ?? '';
      _destLat = cityData != null
          ? (cityData['lat'] as num).toDouble()
          : double.parse(dest['lat']!);
      _destLng = cityData != null
          ? (cityData['lng'] as num).toDouble()
          : double.parse(dest['lng']!);
      _isRandom = true;
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _socialLinkController.dispose();
    _contentFocus.dispose();
    _sendController.dispose();
    super.dispose();
  }

  bool get _isReply => widget.replyToId != null;

  bool _hasBannedWords(String text) {
    final lower = text.toLowerCase();
    return _bannedWords.any((w) => lower.contains(w.toLowerCase()));
  }

  Future<void> _refreshCurrentLocationIfAvailable(AppState state) async {
    try {
      final permission = await Geolocator.checkPermission();
      final allowed =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!allowed) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 4));
      state.updateUserLocation(pos.latitude, pos.longitude);
    } catch (_) {
      // 위치 획득 실패 시 마지막 저장 좌표 사용
    }
  }

  Future<void> _onSend(AppState state) async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      _showError('편지 내용을 작성해주세요 ✍️');
      return;
    }
    if (content.length < 20) {
      _showError('편지는 최소 20자 이상 작성해주세요 ✍️ (현재 ${content.length}자)');
      return;
    }
    if (_hasBannedWords(content)) {
      _showError('부적절한 표현이 포함되어 있어요 🚫');
      return;
    }
    if (!state.hasRemainingDailyQuota) {
      _showError(state.dailyLimitExceededMessage);
      return;
    }

    setState(() => _isSending = true);
    await _sendController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    bool sent = false;
    await _refreshCurrentLocationIfAvailable(state);
    if (_isReply) {
      sent = state.replyToLetter(
        originalLetterId: widget.replyToId!,
        content: content,
      );
    } else {
      sent = state.sendLetter(
        content: content,
        destinationCountry: _selectedCountry,
        destinationFlag: _selectedFlag,
        destLat: _destLat,
        destLng: _destLng,
        // compose에서 이미 선택된 도시를 그대로 넘겨 재랜덤을 방지
        destCityName: _selectedCity.isNotEmpty ? _selectedCity : null,
        deliveryEmoji: _deliveryEmoji,
        socialLink: _attachSocial && _socialLinkController.text.isNotEmpty
            ? _socialLinkController.text.trim()
            : null,
        paperStyle: _paperStyle,
        fontStyle: _fontStyle,
      );
    }

    if (!sent) {
      if (mounted) {
        setState(() => _isSending = false);
        _sendController.reset();
        _showError(state.dailyLimitExceededMessage);
      }
      return;
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isReply
                ? '💌  답장이 ${widget.replyToName}에게 출발했어요!'
                : _isRandom
                ? '✈️  편지가 세상 어딘가로 출발했어요! 🌍'
                : '✈️  편지가 $_selectedFlag $_selectedCountry로 출발했어요!',
          ),
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _selectCountry() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CountryPickerSheet(
        currentCountry: _isRandom ? '' : _selectedCountry,
        onSelected: (name, flag, lat, lng) {
          final cityData = CountryCities.randomCity(name);
          setState(() {
            _selectedCountry = name;
            _selectedFlag = flag;
            _selectedCity = cityData?['name'] as String? ?? '';
            _destLat = cityData != null
                ? (cityData['lat'] as num).toDouble()
                : lat;
            _destLng = cityData != null
                ? (cityData['lng'] as num).toDouble()
                : lng;
            _isRandom = false;
          });
          Navigator.pop(context);
        },
        onRandom: () {
          final state = context.read<AppState>();
          _pickRandomDestination(excludeCountry: state.currentUser.country);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: AppColors.bgDeep,
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, state),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),
                            if (!_isReply) _buildDestinationCard(),
                            if (!_isReply) const SizedBox(height: 10),
                            if (!_isReply) _buildSocialToggle(),
                            if (!_isReply && _attachSocial) ...[
                              const SizedBox(height: 10),
                              _buildSocialInput(),
                            ],
                            if (!_isReply) const SizedBox(height: 10),
                            if (!_isReply) _buildAnonymousToggle(),
                            const SizedBox(height: 10),
                            _buildStyleBar(),
                            const SizedBox(height: 16),
                            _buildLetterBody(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                    _buildSendButton(state),
                  ],
                ),
              ),
              if (_isSending)
                AnimatedBuilder(
                  animation: _sendAnim,
                  builder: (_, __) => _SendingOverlay(
                    progress: _sendAnim.value,
                    emoji: _isReply ? '💌' : '✈️',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext ctx, AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              _isReply ? '💌  답장 쓰기' : '✍️  편지 쓰기',
              textAlign: TextAlign.center,
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 48), // 좌우 균형
        ],
      ),
    );
  }

  Widget _buildDestinationCard() {
    return GestureDetector(
      onTap: _selectCountry,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  _isRandom ? '🔒' : _selectedFlag,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('✈️ ', style: TextStyle(fontSize: 13)),
                      Text(
                        _isRandom ? '알 수 없는 어딘가' : _selectedCountry,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isRandom ? '🔒 비공개' : '선택됨',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isRandom ? '발송 후 배송지가 공개돼요' : '탭해서 목적지 변경 가능',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _isRandom
                  ? Icons.shuffle_rounded
                  : Icons.edit_location_alt_rounded,
              color: AppColors.gold,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterBody() {
    final paper = LetterStyles.paper(_paperStyle);
    final font = LetterStyles.font(_fontStyle);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: LetterPaperPainter(paper),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _contentFocus.hasFocus
                  ? AppColors.gold.withValues(alpha: 0.4)
                  : const Color(0xFF1F2D44),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header (the existing header with char count)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: paper.inkColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('✉️', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 8),
                        Text(
                          _isReply
                              ? '${widget.replyToName}에게 답장'
                              : '이 편지는 세상 어딘가로 흘러갑니다',
                          style: TextStyle(
                            color: paper.inkColor.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _charCount < 20
                              ? Row(
                                  key: const ValueKey('under'),
                                  children: [
                                    const Text(
                                      '✏️ ',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      '최소 20자 필요 (${20 - _charCount}자 더)',
                                      style: const TextStyle(
                                        color: AppColors.warning,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  key: const ValueKey('ok'),
                                  children: [
                                    const Text(
                                      '✅ ',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    const Text(
                                      '최소 글자수 충족',
                                      style: TextStyle(
                                        color: AppColors.teal,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        Text(
                          '$_charCount / $_maxChars',
                          style: TextStyle(
                            color: _charCount > _maxChars * 0.9
                                ? AppColors.error
                                : paper.inkColor.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextField(
                controller: _contentController,
                focusNode: _contentFocus,
                minLines: 8,
                maxLines: null,
                maxLength: _maxChars,
                style: font.textStyle.copyWith(color: paper.inkColor),
                decoration: InputDecoration(
                  hintText: '안녕하세요, 처음 뵙겠어요.\n저는 지금 이 편지를 쓰고 있는...',
                  hintStyle: TextStyle(
                    color: paper.inkColor.withValues(alpha: 0.35),
                    fontSize: 15,
                    height: 1.85,
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterText: '',
                  filled: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialToggle() {
    return GestureDetector(
      onTap: () => setState(() => _attachSocial = !_attachSocial),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: _attachSocial
                ? AppColors.teal.withValues(alpha: 0.4)
                : const Color(0xFF1F2D44),
          ),
        ),
        child: Row(
          children: [
            const Text('🔗', style: TextStyle(fontSize: 17)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SNS 링크 첨부 (선택)',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 13),
                  ),
                  const Text(
                    'Instagram, X 등 — 연결을 원할 때만',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Switch(
              value: _attachSocial,
              onChanged: (v) => setState(() => _attachSocial = v),
              activeThumbColor: AppColors.teal,
              activeTrackColor: AppColors.teal.withValues(alpha: 0.3),
              inactiveTrackColor: AppColors.bgSurface,
              inactiveThumbColor: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialInput() {
    return TextField(
      controller: _socialLinkController,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'https://instagram.com/your_id',
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: const Icon(
          Icons.link_rounded,
          color: AppColors.teal,
          size: 18,
        ),
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2D44)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2D44)),
        ),
      ),
    );
  }

  Widget _buildAnonymousToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isAnonymous = !_isAnonymous),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFF1F2D44)),
        ),
        child: Row(
          children: [
            Text(
              _isAnonymous ? '🎭' : '😊',
              style: const TextStyle(fontSize: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAnonymous ? '익명으로 발송' : '이름 공개',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 13),
                  ),
                  Text(
                    _isAnonymous ? '수신자가 발신자를 볼 수 없어요' : '수신자가 닉네임을 볼 수 있어요',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isAnonymous,
              onChanged: (v) => setState(() => _isAnonymous = v),
              activeThumbColor: AppColors.gold,
              activeTrackColor: AppColors.gold.withValues(alpha: 0.3),
              inactiveTrackColor: AppColors.bgSurface,
              inactiveThumbColor: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleBar() {
    final paper = LetterStyles.paper(_paperStyle);
    final font = LetterStyles.font(_fontStyle);
    return Row(
      children: [
        // Paper picker button
        Expanded(
          child: GestureDetector(
            onTap: _showPaperPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Text(paper.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      paper.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.gold,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Font picker button
        Expanded(
          child: GestureDetector(
            onTap: _showFontPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Text(font.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      font.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.teal,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // ── 배송 이모티콘 피커 버튼 ──────────────────────────────────────────
        GestureDetector(
          onTap: _showEmojiPicker,
          child: Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_deliveryEmoji != null)
                    ? AppColors.gold.withValues(alpha: 0.6)
                    : AppColors.textMuted.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _deliveryEmoji ?? '🚀',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  _deliveryEmoji != null ? '변경' : '꾸미기',
                  style: TextStyle(
                    color: _deliveryEmoji != null
                        ? AppColors.gold
                        : AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 배송 이모티콘 피커 ────────────────────────────────────────────────────
  static const _emojiGroups = [
    {
      'tab': '🛣️ 육지',
      'emojis': [
        '🚚', '🚛', '🚗', '🚕', '🚙', '🛻', '🚐', '🚌', '🚑', '🚒',
        '🚂', '🚄', '🚅', '🚆', '🚇', '🚊', '🚝', '🏎️', '🛵', '🏍️',
        '🐪', '🐘', '🐎', '🦒', '🛺', '📦', '🎁', '📫', '🗃️', '🧳',
      ],
    },
    {
      'tab': '✈️ 항공',
      'emojis': [
        '✈️', '🛩️', '🚀', '🛸', '🎈', '🪂', '🦅', '🕊️', '🦜', '🦋',
        '🦢', '🦩', '🦆', '🐦', '🌠', '💫', '⭐', '🌟', '🌪️', '🎆',
        '🎇', '🪁', '🛷', '💌', '🎠', '🛺', '🪄', '🔮', '🌈', '☁️',
      ],
    },
    {
      'tab': '🌊 바다',
      'emojis': [
        '🚢', '⛵', '🛥️', '🚤', '⛴️', '🛶', '⚓', '🌊', '🐳', '🐬',
        '🦈', '🐙', '🦀', '🦞', '🐠', '🐟', '🦑', '🐚', '🪸', '🏄',
        '🤿', '🧜', '🌍', '🗺️', '🧭', '🏝️', '⛅', '🌅', '🌊', '💎',
      ],
    },
  ];

  void _showEmojiPicker() {
    int _tabIndex = 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D1421),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 핸들 ──
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    const Text('🎨', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '배송 이모티콘 선택',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // 기본값으로 되돌리기
                    if (_deliveryEmoji != null)
                      TextButton(
                        onPressed: () {
                          setState(() => _deliveryEmoji = null);
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          '기본값',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              // ── 카테고리 탭 ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: List.generate(
                    _emojiGroups.length,
                    (i) => Expanded(
                      child: GestureDetector(
                        onTap: () => setSheet(() => _tabIndex = i),
                        child: Container(
                          margin: EdgeInsets.only(
                              left: i == 0 ? 0 : 4),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8),
                          decoration: BoxDecoration(
                            color: _tabIndex == i
                                ? AppColors.gold
                                    .withValues(alpha: 0.18)
                                : AppColors.bgCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _tabIndex == i
                                  ? AppColors.gold
                                      .withValues(alpha: 0.6)
                                  : AppColors.textMuted
                                      .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            _emojiGroups[i]['tab'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _tabIndex == i
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: _tabIndex == i
                                  ? AppColors.gold
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // ── 이모티콘 그리드 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: (_emojiGroups[_tabIndex]['emojis']
                          as List)
                      .length,
                  itemBuilder: (_, i) {
                    final emoji = (_emojiGroups[_tabIndex]['emojis']
                        as List)[i] as String;
                    final isSelected = _deliveryEmoji == emoji;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _deliveryEmoji = emoji);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.gold.withValues(alpha: 0.15)
                              : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.gold
                                : AppColors.textMuted
                                    .withValues(alpha: 0.15),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaperPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1421),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '편지지 선택',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...List.generate(LetterStyles.papers.length, (i) {
                final p = LetterStyles.papers[i];
                final isSelected = i == _paperStyle;
                return GestureDetector(
                  onTap: () {
                    setState(() => _paperStyle = i);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: p.bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.gold
                            : p.lineColor.withValues(alpha: 0.5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              color: p.inkColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.gold,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              // PRO locked item
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1F2D44)),
                ),
                child: Row(
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '더 많은 편지지 (PRO)',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '추후 제공',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ), // SingleChildScrollView
      ),
    );
  }

  void _showFontPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1421),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                '폰트 선택',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...List.generate(LetterStyles.fonts.length, (i) {
              final f = LetterStyles.fonts[i];
              final isSelected = i == _fontStyle;
              return GestureDetector(
                onTap: () {
                  setState(() => _fontStyle = i);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.teal
                          : const Color(0xFF1F2D44),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(f.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '가나다라마바사 Aa Bb',
                              style: f.textStyle.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.teal,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1F2D44)),
              ),
              child: Row(
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '더 많은 폰트 / 텍스트 효과 (PRO)',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '추후 제공',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(AppState state) {
    final canSend =
        !_isSending && _charCount >= 1 && state.hasRemainingDailyQuota;
    final quotaText = state.isGeneralMember
        ? '오늘 발송 ${state.todaySentCount}/10통 · 남은 ${state.remainingDailySendCount}통'
        : 'PRO 회원 · 발송 무제한';
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        border: Border(
          top: BorderSide(color: AppColors.gold.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            quotaText,
            style: TextStyle(
              color: state.hasRemainingDailyQuota
                  ? AppColors.textMuted
                  : const Color(0xFFFF8A80),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: canSend ? () => _onSend(state) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canSend ? AppColors.gold : AppColors.bgSurface,
                foregroundColor: canSend
                    ? AppColors.bgDeep
                    : AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isReply ? '💌' : '✈️',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isReply
                        ? '답장 보내기'
                        : _isRandom
                        ? '편지 보내기 → 🌍'
                        : '편지 보내기 → $_selectedFlag',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 편지지 배경 ───────────────────────────────────────────────────────────────
class _PaperBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _PaperPainter(),
    );
  }
}

class _PaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    for (double y = 80; y < size.height; y += 28) {
      canvas.drawLine(Offset(24, y), Offset(size.width - 24, y), linePaint);
    }
    final marginPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(56, 0), Offset(56, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── 발송 오버레이 ─────────────────────────────────────────────────────────────
class _SendingOverlay extends StatelessWidget {
  final double progress;
  final String emoji;
  const _SendingOverlay({required this.progress, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppColors.bgDeep.withValues(
          alpha: (progress * 0.88).clamp(0.0, 0.88),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, -80 * progress),
                child: Opacity(
                  opacity: progress.clamp(0.0, 1.0),
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: 20 + 40 * progress),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Opacity(
                opacity: progress,
                child: const Text(
                  '편지가 출발합니다...',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
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

// ── 국가 선택 바텀시트 ─────────────────────────────────────────────────────────
class _CountryPickerSheet extends StatefulWidget {
  final String currentCountry;
  final void Function(String, String, double, double) onSelected;
  final VoidCallback onRandom;

  const _CountryPickerSheet({
    required this.currentCountry,
    required this.onSelected,
    required this.onRandom,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = AppState.countries
        .where(
          (c) => c['name']!.contains(_search) || c['flag']!.contains(_search),
        )
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text('목적지 선택', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                // 랜덤 버튼
                GestureDetector(
                  onTap: widget.onRandom,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.shuffle_rounded,
                          color: AppColors.gold,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '랜덤',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '나라 검색...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                filled: true,
                fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final c = filtered[i];
                final isCurrent = c['name'] == widget.currentCountry;
                return ListTile(
                  onTap: () => widget.onSelected(
                    c['name']!,
                    c['flag']!,
                    double.parse(c['lat']!),
                    double.parse(c['lng']!),
                  ),
                  leading: Text(
                    c['flag']!,
                    style: const TextStyle(fontSize: 26),
                  ),
                  title: Text(
                    c['name']!,
                    style: TextStyle(
                      color: isCurrent ? AppColors.gold : AppColors.textPrimary,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.gold,
                          size: 16,
                        )
                      : const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
