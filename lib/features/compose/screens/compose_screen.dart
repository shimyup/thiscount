import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/letter_style.dart';
import '../../../core/data/country_cities.dart';
import '../../../state/app_state.dart';
import '../../../core/services/purchase_service.dart';
import '../../premium/premium_gate_sheet.dart';

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
  Timer? _autoSaveTimer; // 3초 자동 저장

  // 목적지 (기본값: 랜덤) — 빈 문자열로 초기화 후 initState에서 즉시 채움
  String _selectedCountry = '';
  String _selectedFlag = '';
  String _selectedCity = ''; // 도시/구 단위
  double _destLat = 0;
  double _destLng = 0;

  int _paperStyle = 0;
  int _fontStyle = 0;
  // 카테고리별 이모티콘 (0=육지, 1=항공, 2=바다) — 각 카테고리에서 1개씩 독립 선택
  final Map<int, String> _categoryEmojis = {};

  /// 선택된 이모티콘을 "|" 구분 문자열로 직렬화 (Letter 저장용)
  String? get _deliveryEmojiEncoded {
    final land = _categoryEmojis[0] ?? '';
    final air = _categoryEmojis[1] ?? '';
    final sea = _categoryEmojis[2] ?? '';
    if (land.isEmpty && air.isEmpty && sea.isEmpty) return null;
    return '$land|$air|$sea';
  }

  /// 버튼 미리보기용 — 선택된 이모티콘 최대 3개 합친 문자열
  String get _emojiPreview {
    final selected = [0, 1, 2]
        .where((i) => _categoryEmojis.containsKey(i))
        .map((i) => _categoryEmojis[i]!)
        .toList();
    return selected.isEmpty ? '' : selected.join(' ');
  }

  bool _isRandom = true;
  bool _isAnonymous = true;
  bool _attachSocial = false;
  bool _isSending = false;
  int _charCount = 0;
  String? _imageFilePath; // 첨부 이미지 경로 (프리미엄)
  bool _isCompressingImage = false;
  static const int _maxChars = 1000;

  // ── 행운의 편지 ──────────────────────────────────────────────────────────
  bool _isLuckyLetter = false;

  static const List<String> _luckyQuotes = [
    '안녕하세요, 이 편지를 받게 된 당신에게 따뜻한 인사를 전합니다.\n\n'
        '오늘 하루, 작은 것들 속에서 행복을 발견하는 하루가 되기를 바랍니다. '
        '아침에 마신 따뜻한 커피 한 잔, 스쳐 지나가는 바람, 창밖의 햇살 — '
        '그 작은 것들이 모여 당신의 하루를 빛나게 만들어 줄 거예요.\n\n'
        '어디선가 당신을 응원하고 있는 낯선 친구로부터. 🍀',

    '안녕하세요, 이 편지가 당신에게 닿기를 바라며 씁니다.\n\n'
        '세상은 참 넓고, 좋은 인연은 언제 어디서 시작될지 모릅니다. '
        '이 편지가 그 시작이 된다면 정말 좋겠어요. '
        '우리가 비록 이름도, 얼굴도 모르지만, 이렇게 편지로 이어진 것만으로도 '
        '충분히 아름다운 인연이라고 생각합니다.\n\n'
        '언젠가, 어딘가에서 만날 날을 기대하며. 💌',

    '안녕하세요, 이 글이 당신에게 작은 힘이 되길 바랍니다.\n\n'
        '지금 어떤 하루를 보내고 있든, 당신은 충분히 잘 하고 있어요. '
        '완벽하지 않아도 괜찮고, 모든 걸 해내지 않아도 됩니다. '
        '그냥 오늘 하루를 버텨낸 것만으로도, 당신은 이미 대단한 사람입니다.\n\n'
        '포기하지 마세요. 멀리서 응원합니다. 💪',

    '안녕하세요, 세상 어딘가에서 이 편지를 보냅니다.\n\n'
        '매일 조금씩 나아가는 것, 그것만으로도 충분히 대단한 일입니다. '
        '남들과 비교하지 말고, 어제의 나보다 조금만 더 나아가면 그걸로 충분해요. '
        '당신의 속도로 걸어가는 삶이 가장 아름다운 삶입니다.\n\n'
        '오늘도 수고 많으셨습니다. 🌟',

    '안녕하세요, 이 편지를 받게 된 것도 하나의 인연이라 생각합니다.\n\n'
        '세상은 생각보다 훨씬 따뜻한 사람들로 가득 차 있습니다. '
        '때로는 낯선 사람의 작은 배려가 하루를 바꾸기도 하죠. '
        '이 편지가 당신의 오늘에 그런 작은 온기가 되었으면 합니다.\n\n'
        '당신 덕분에 세상이 조금 더 따뜻해집니다. 🌍',
  ];

  void _applyLuckyLetter() {
    final quotes = _luckyQuotes.toList()..shuffle();
    final quote = quotes.first;
    setState(() {
      _isLuckyLetter = true;
      _contentController.text = quote;
      _contentController.selection = TextSelection.fromPosition(
        TextPosition(offset: quote.length),
      );
    });
  }

  // ── 브랜드 대량 발송 ──────────────────────────────────────────────────────
  bool _isBulkMode = false; // 대량 발송 모드 여부
  final List<Map<String, dynamic>> _bulkTargets = []; // 선택된 나라 목록
  int _bulkSendCount = 1; // 나라당 발송 횟수

  // ── 브랜드 특송 ───────────────────────────────────────────────────────────
  bool _isExpressMode = false; // 특송 모드 여부
  int _expressCount = 5; // 발송할 주소 수 (3~10)

  static const List<String> _bannedWords = [
    // 영어
    'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'dick', 'pussy', 'cunt',
    'nigger', 'nigga', 'faggot', 'whore', 'slut', 'rape', 'kill yourself',
    'kys', 'retard',
    // 한국어 욕설
    '씨발', '병신', '개새끼', '존나', '지랄', '엿먹', '꺼져', '죽어',
    '미친놈', '미친년', '창녀', '보지', '자지', '좆',
    // 스팸 패턴
    '카지노', '도박', '대출', '비트코인 투자', '클릭하세요',
  ];

  @override
  void initState() {
    super.initState();
    _sendController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _sendAnim = CurvedAnimation(parent: _sendController, curve: Curves.easeOut);
    _contentController.addListener(() {
      final text = _contentController.text;
      // 행운의 편지 글귀와 달라지면 플래그 해제 (직접 수정한 것으로 간주)
      final isStillLucky = _luckyQuotes.contains(text);
      setState(() {
        _charCount = text.length;
        if (_isLuckyLetter && !isStillLucky) _isLuckyLetter = false;
      });
      // URL 감지 및 차단
      final urlRegex = RegExp(
        r'(https?://|www\.)\S+|(\S+\.(com|net|org|io|co|kr|me|ly|gg|app|link)(\S*))',
        caseSensitive: false,
      );
      if (urlRegex.hasMatch(text)) {
        // URL 부분 제거
        final cleaned = text.replaceAll(urlRegex, '');
        _contentController.value = TextEditingValue(
          text: cleaned,
          selection: TextSelection.collapsed(offset: cleaned.length),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppL10n.of(context.read<AppState>().currentUser.languageCode).composeLinkNotAllowed,
                ),
                backgroundColor: const Color(0xFF1F2D44),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    });

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
      final purchase = context.read<PurchaseService>();
      _pickRandomDestination(excludeCountry: state.currentUser.country);
      // 프리미엄/브랜드 유저만 SNS 자동 첨부
      final hasPremiumForSns =
          purchase.isPremium ||
          purchase.isBrand ||
          state.currentUser.isPremium ||
          state.currentUser.isBrand;
      if (hasPremiumForSns) {
        final userSns = state.currentUser.socialLink;
        if (userSns != null && userSns.isNotEmpty) {
          setState(() {
            _attachSocial = true;
            _socialLinkController.text = userSns;
          });
        }
      }
      _loadDraftIfExists();
      // 3초마다 자동 저장 (앱 강제 종료 시 임시 저장 보장)
      _autoSaveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (_contentController.text.isNotEmpty && !_isSending) _saveDraft();
      });
    });
  }

  void _saveDraft() {
    SharedPreferences.getInstance().then((prefs) {
      final text = _contentController.text;
      if (text.isEmpty) {
        prefs.remove('compose_draft');
      } else {
        prefs.setString('compose_draft', text);
      }
    });
  }

  Future<void> _loadDraftIfExists() async {
    if (_isReply) return;
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString('compose_draft') ?? '';
    if (draft.isEmpty) return;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          AppL10n.of(context.read<AppState>().currentUser.languageCode).composeDraftFound,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearDraft();
              Navigator.pop(ctx);
            },
            child: Text(
              AppL10n.of(context.read<AppState>().currentUser.languageCode).composeDiscard,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _contentController.text = draft;
                _charCount = draft.length;
              });
              Navigator.pop(ctx);
            },
            child: Text(AppL10n.of(context.read<AppState>().currentUser.languageCode).composeContinueWriting, style: const TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  void _clearDraft() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('compose_draft');
    });
  }

  void _pickRandomDestination({String? excludeCountry}) {
    final dest = AppState.randomDestination(excludeCountry: excludeCountry);
    final countryName = dest['name']!;
    final langCode = context.read<AppState>().currentUser.languageCode;
    // 해당 국가의 랜덤 도시 선택
    final cityData = CountryCities.randomCity(
      countryName,
      languageCode: langCode,
    );
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
    _autoSaveTimer?.cancel();
    if (_contentController.text.isNotEmpty && !_isSending) {
      _saveDraft();
    }
    _contentController.dispose();
    _socialLinkController.dispose();
    _contentFocus.dispose();
    _sendController.dispose();
    super.dispose();
  }

  // ── 이미지 첨부 (프리미엄 전용) ───────────────────────────────────────────
  Future<void> _pickImage(AppState state, PurchaseService purchase) async {
    final hasPremium =
        purchase.isPremium ||
        purchase.isBrand ||
        state.currentUser.isPremium ||
        state.currentUser.isBrand;
    if (!hasPremium) {
      final _l = AppL10n.of(context.read<AppState>().currentUser.languageCode);
      PremiumGateSheet.show(
        context,
        featureName: '📸 ${_l.composePhotoAttach}',
        featureEmoji: '📸',
        description: _l.composePhotoAttachDesc,
      );
      return;
    }
    if (!state.hasRemainingImageQuota) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppL10n.of(context.read<AppState>().currentUser.languageCode).composeImageLimitReached),
          backgroundColor: const Color(0xFF1F2D44),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (picked == null || !mounted) return;

    setState(() => _isCompressingImage = true);
    try {
      final targetPath = '${picked.path}_lgo.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        quality: 80,
        minWidth: 200,
        minHeight: 200,
        keepExif: false,
      );
      if (mounted) {
        setState(() {
          _imageFilePath = result?.path ?? picked.path;
          _isCompressingImage = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _imageFilePath = picked.path;
          _isCompressingImage = false;
        });
      }
    }
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
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      _showError(l10n.composeEmptyError);
      return;
    }
    if (content.length < 20) {
      _showError(l10n.composeMinLengthError(content.length));
      return;
    }
    if (_hasBannedWords(content)) {
      _showError(l10n.composeBannedWordError);
      return;
    }
    if (!state.hasRemainingDailyQuota) {
      _showError(state.dailyLimitExceededMessage);
      return;
    }
    final useExpressSingle = _isExpressMode && !_isBulkMode && !_isReply;
    if (useExpressSingle &&
        !state.currentUser.isBrand &&
        !state.canUsePremiumExpress) {
      _showError(state.premiumExpressLimitExceededMessage);
      setState(() => _isExpressMode = false);
      return;
    }

    // ── 특송 + 대량 동시 모드 ──────────────────────────────────────────────
    if (_isExpressMode && _isBulkMode && state.currentUser.isBrand) {
      if (_bulkTargets.isEmpty) {
        _showError(l10n.composeSelectCountryError);
        return;
      }
      FocusScope.of(context).unfocus();
      setState(() => _isSending = true);
      await _sendController.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      await _refreshCurrentLocationIfAvailable(state);

      int totalSent = 0;
      for (final target in _bulkTargets) {
        totalSent += await state.sendBrandExpressBlast(
          content: content,
          destinationCountry: target['country'] as String,
          destinationFlag: target['flag'] as String,
          count: _expressCount,
          deliveryEmoji: _deliveryEmojiEncoded,
          socialLink: _attachSocial && _socialLinkController.text.isNotEmpty
              ? _socialLinkController.text.trim()
              : null,
          paperStyle: _paperStyle,
          fontStyle: _fontStyle,
          imageUrl: _imageFilePath,
        );
      }
      if (mounted) {
        _clearDraft();
        HapticFeedback.heavyImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.composeExpressBulkSent(_bulkTargets.length, _expressCount, totalSent),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF1A1A2A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // ── 대량 발송 모드 ─────────────────────────────────────────────────────
    if (_isBulkMode && state.currentUser.isBrand) {
      if (_bulkTargets.isEmpty) {
        _showError(l10n.composeSelectCountryError);
        return;
      }
      // 키보드 해제
      FocusScope.of(context).unfocus();
      setState(() => _isSending = true);
      await _sendController.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      await _refreshCurrentLocationIfAvailable(state);

      final totalSent = await state.sendBulkLetter(
        content: content,
        targets: _bulkTargets,
        sendCount: _bulkSendCount,
        socialLink: _attachSocial && _socialLinkController.text.isNotEmpty
            ? _socialLinkController.text.trim()
            : null,
        imageUrl: _imageFilePath,
        paperStyle: _paperStyle,
        fontStyle: _fontStyle,
      );

      if (mounted) {
        _clearDraft();
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.composeBulkSent(totalSent, _bulkTargets.length),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF111827),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _isSending = true);
    await _sendController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    bool sent = false;
    await _refreshCurrentLocationIfAvailable(state);
    if (_isReply) {
      sent = await state.replyToLetter(
        originalLetterId: widget.replyToId!,
        content: content,
      );
    } else {
      sent = await state.sendLetter(
        content: content,
        destinationCountry: _selectedCountry,
        destinationFlag: _selectedFlag,
        destLat: _destLat,
        destLng: _destLng,
        // compose에서 이미 선택된 도시를 그대로 넘겨 재랜덤을 방지
        destCityName: _selectedCity.isNotEmpty ? _selectedCity : null,
        deliveryEmoji: _deliveryEmojiEncoded,
        socialLink: _attachSocial && _socialLinkController.text.isNotEmpty
            ? _socialLinkController.text.trim()
            : null,
        paperStyle: _paperStyle,
        fontStyle: _fontStyle,
        imageUrl: _imageFilePath,
        isExpress: useExpressSingle,
      );
    }

    if (!sent) {
      if (mounted) {
        setState(() => _isSending = false);
        _sendController.reset();
        final String errMsg;
        if (useExpressSingle) {
          errMsg = state.premiumExpressLimitExceededMessage;
        } else if (_imageFilePath != null && !state.hasRemainingImageQuota) {
          errMsg = state.imageLimitExceededMessage;
        } else {
          errMsg = state.dailyLimitExceededMessage;
        }
        _showError(errMsg);
      }
      return;
    }

    var shouldShowPremiumWelcome = false;
    if (!_isReply && state.isGeneralMember) {
      final prefs = await SharedPreferences.getInstance();
      final welcomeShown = prefs.getBool('premium_welcome_shown') ?? false;
      if (!welcomeShown) {
        await prefs.setBool('premium_welcome_shown', true);
        shouldShowPremiumWelcome = true;
      }
    }

    if (mounted) {
      // 편지 발송 성공 시 초안 삭제
      _clearDraft();
      // 편지 발송 성공 햅틱 (medium vibration)
      HapticFeedback.mediumImpact();
      if (shouldShowPremiumWelcome) {
        Navigator.of(context).popAndPushNamed('/premium_welcome');
        return;
      }
      if (_isReply) {
        // 답장: ComposeScreen + LetterReadScreen 모두 닫고 편지함으로 복귀
        Navigator.pop(context); // ComposeScreen 닫기
        Navigator.pop(context); // LetterReadScreen 닫기
      } else {
        Navigator.pop(context); // ComposeScreen만 닫기
      }
      final lastLetter = state.sent.isNotEmpty ? state.sent.last : null;
      final estMin = lastLetter?.estimatedTotalMinutes ?? 0;
      final langCode = state.currentUser.languageCode;
      final localCountry = CountryL10n.localizedName(_selectedCountry, langCode);
      final String estLabel = _isReply || estMin <= 0
          ? ''
          : estMin < 60
          ? l10n.composeEstMinutes(estMin)
          : estMin < 1440
          ? l10n.composeEstHours((estMin / 60).ceil())
          : l10n.composeEstDays((estMin / 1440).ceil());
      final String mainMsg = _isReply
          ? l10n.composeReplySent(widget.replyToName ?? '')
          : useExpressSingle
          ? (_isRandom
                ? state.currentUser.isBrand
                      ? l10n.composeExpressSentRandomBrand
                      : l10n.composeExpressSentRandomPremium
                : l10n.composeExpressSentTo(_selectedFlag, localCountry))
          : _isRandom
          ? l10n.composeLetterSentRandom
          : l10n.composeLetterSentTo(_selectedFlag, localCountry);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: estLabel.isNotEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainMsg,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      estLabel,
                      style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : Text(
                  mainMsg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          backgroundColor: const Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      // 특급 배송 한도 소진 알림
      if (useExpressSingle &&
          !state.currentUser.isBrand &&
          state.remainingPremiumExpressCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.composeExpressLimitUsed(state.premiumExpressDailyLimit),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.gold.withValues(alpha: 0.92),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.error.withValues(alpha: 0.92),
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
          final langCode = context.read<AppState>().currentUser.languageCode;
          final cityData = CountryCities.randomCity(
            name,
            languageCode: langCode,
          );
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
    return Consumer2<AppState, PurchaseService>(
      builder: (context, state, purchase, _) {
        final isBrand = state.currentUser.isBrand || purchase.isBrand;
        final hasPremium =
            purchase.isPremium ||
            purchase.isBrand ||
            state.currentUser.isPremium ||
            state.currentUser.isBrand;
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
                            if (!_isReply && isBrand) _buildBulkModeToggle(),
                            if (!_isReply && isBrand)
                              const SizedBox(height: 10),
                            // 대량 패널 (대량 ON) — 특송 토글 포함
                            if (!_isReply && isBrand && _isBulkMode)
                              _buildBulkSendPanel(state),
                            if (!_isReply && isBrand && _isBulkMode)
                              const SizedBox(height: 10),
                            // 일반 목적지 카드 (대량 OFF일 때만)
                            if (!_isReply && !_isBulkMode)
                              _buildDestinationCard(state, hasPremium),
                            if (!_isReply && !_isBulkMode)
                              const SizedBox(height: 10),
                            if (!_isReply)
                              _buildSocialToggle(hasPremium: hasPremium),
                            if (!_isReply && _attachSocial && hasPremium) ...[
                              const SizedBox(height: 10),
                              _buildSocialInput(),
                            ],
                            if (!_isReply) const SizedBox(height: 10),
                            if (!_isReply) _buildAnonymousToggle(state),
                            const SizedBox(height: 10),
                            _buildStyleBar(),
                            const SizedBox(height: 10),
                            // 📸 이미지 첨부 버튼
                            _buildImageAttachButton(
                              state,
                              hasPremium: hasPremium,
                              purchase: purchase,
                            ),
                            // 📸 이미지 미리보기
                            if (_imageFilePath != null) ...[
                              const SizedBox(height: 10),
                              _buildImagePreview(),
                            ],
                            const SizedBox(height: 16),
                            _buildLuckyLetterButton(),
                            const SizedBox(height: 10),
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
    final l10n = AppL10n.of(state.currentUser.languageCode);
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
              _isReply ? '💌  ${l10n.composeWriteReply}' : '✍️  ${l10n.writeLetter}',
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

  Widget _buildDestinationCard(AppState state, bool hasPremium) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final langCode = state.currentUser.languageCode;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 라벨 ──────────────────────────────────────────────────
          Text(
            '✈️  ${l10n.composeDestination}',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // ── 토글 버튼 행 ──────────────────────────────────────────
          Row(
            children: [
              // 랜덤 버튼
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _isRandom = true);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isRandom
                          ? AppColors.gold.withValues(alpha: 0.18)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isRandom ? AppColors.gold : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🎲',
                          style: TextStyle(fontSize: _isRandom ? 22 : 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.composeRandom,
                          style: TextStyle(
                            color: _isRandom
                                ? AppColors.gold
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.composeSomewhereInWorld,
                          style: TextStyle(
                            color: _isRandom
                                ? AppColors.gold.withValues(alpha: 0.7)
                                : AppColors.textMuted.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 나라 선택 버튼
              Expanded(
                child: GestureDetector(
                  onTap: _selectCountry,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isRandom
                          ? AppColors.gold.withValues(alpha: 0.18)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_isRandom ? AppColors.gold : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          !_isRandom ? _selectedFlag : '🌍',
                          style: TextStyle(fontSize: !_isRandom ? 22 : 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          !_isRandom ? CountryL10n.localizedName(_selectedCountry, langCode) : l10n.selectCountry,
                          style: TextStyle(
                            color: !_isRandom
                                ? AppColors.gold
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          !_isRandom ? l10n.composeTapToChange : l10n.composeChooseDirectly,
                          style: TextStyle(
                            color: !_isRandom
                                ? AppColors.gold.withValues(alpha: 0.7)
                                : AppColors.textMuted.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasPremium)
            GestureDetector(
              onTap: () {
                final canEnable =
                    state.currentUser.isBrand || state.canUsePremiumExpress;
                if (!canEnable && !_isExpressMode) {
                  _showError(state.premiumExpressLimitExceededMessage);
                  return;
                }
                setState(() => _isExpressMode = !_isExpressMode);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _isExpressMode
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isExpressMode
                        ? AppColors.gold.withValues(alpha: 0.65)
                        : AppColors.textMuted.withValues(alpha: 0.24),
                    width: _isExpressMode ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: _isExpressMode
                          ? AppColors.gold
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.currentUser.isBrand
                            ? (_isExpressMode
                                  ? '⚡ ${l10n.composeBrandExpressOn}'
                                  : '⚡ ${l10n.composeBrandExpress}')
                            : (_isExpressMode
                                  ? '⚡ ${l10n.composePremiumExpressOn(state.todayPremiumExpressSentCount, state.premiumExpressDailyLimit)}'
                                  : '⚡ ${l10n.composePremiumExpress(state.premiumExpressDailyLimit)}'),
                        style: TextStyle(
                          color: _isExpressMode
                              ? AppColors.gold
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isExpressMode,
                      onChanged: (v) {
                        final canEnable =
                            state.currentUser.isBrand ||
                            state.canUsePremiumExpress;
                        if (v && !canEnable) {
                          _showError(state.premiumExpressLimitExceededMessage);
                          return;
                        }
                        setState(() => _isExpressMode = v);
                      },
                      activeColor: AppColors.gold,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => PremiumGateSheet.show(
                context,
                featureName: '⚡ ${l10n.composeExpressDelivery}',
                featureEmoji: '⚡',
                description: l10n.composeExpressDeliveryDesc,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textMuted.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚡ ${l10n.composeExpressLocked}',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '👑 PRO',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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

  Widget _buildLuckyLetterButton() {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return GestureDetector(
      onTap: _applyLuckyLetter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: _isLuckyLetter
              ? LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.25),
                    const Color(0xFFFF8C00).withValues(alpha: 0.15),
                  ],
                )
              : LinearGradient(colors: [AppColors.bgCard, AppColors.bgCard]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isLuckyLetter
                ? const Color(0xFFFFD700).withValues(alpha: 0.7)
                : AppColors.textMuted.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Text('🍀', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLuckyLetter ? l10n.composeLuckyApplied : l10n.composeLuckySend,
                    style: TextStyle(
                      color: _isLuckyLetter
                          ? const Color(0xFFFFD700)
                          : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isLuckyLetter
                        ? l10n.composeLuckyAppliedSub
                        : l10n.composeLuckySendSub,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _isLuckyLetter
                  ? Icons.autorenew_rounded
                  : Icons.auto_awesome_rounded,
              color: _isLuckyLetter
                  ? const Color(0xFFFFD700)
                  : AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterBody() {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
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
                              ? l10n.composeReplyTo(widget.replyToName ?? '')
                              : l10n.composeLetterFlows,
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
                                      l10n.composeMinCharsNeeded(20 - _charCount),
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
                                    Text(
                                      l10n.composeMinCharsMet,
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
                  hintText: l10n.composeHint,
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

  Widget _buildSocialToggle({required bool hasPremium}) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    // 비프리미엄: 잠금 상태 UI 표시
    if (!hasPremium) {
      return GestureDetector(
        onTap: () => PremiumGateSheet.show(
          context,
          featureName: '🔗 ${l10n.composeLinkAttach}',
          featureEmoji: '🔗',
          description: l10n.composeLinkAttachDesc,
        ),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFF1F2D44)),
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
                      l10n.composeSnsLinkAttach,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      l10n.composePremiumBrandOnly,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  '👑 PRO',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                    l10n.composeSnsLinkOptional,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 13),
                  ),
                  Text(
                    l10n.composeSnsLinkSub,
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

  Widget _buildAnonymousToggle(AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final isBrand = state.currentUser.isBrand;
    // 브랜드 계정은 익명 발송 불가 — 강제로 false 유지
    if (isBrand && _isAnonymous) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _isAnonymous = false),
      );
    }
    return Opacity(
      opacity: isBrand ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: isBrand
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🏢 ${l10n.composeBrandNoAnonymous}'),
                    backgroundColor: const Color(0xFF1F2D44),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            : () => setState(() => _isAnonymous = !_isAnonymous),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isBrand
                  ? AppColors.textMuted.withValues(alpha: 0.15)
                  : const Color(0xFF1F2D44),
            ),
          ),
          child: Row(
            children: [
              Text(
                isBrand ? '🏢' : (_isAnonymous ? '🎭' : '😊'),
                style: const TextStyle(fontSize: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBrand
                          ? l10n.composeNamePublicBrand
                          : (_isAnonymous ? l10n.composeSendAnonymous : l10n.composeNamePublic),
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 13),
                    ),
                    Text(
                      isBrand
                          ? l10n.composeBrandNoAnonymousSub
                          : (_isAnonymous
                                ? l10n.composeAnonymousSub
                                : l10n.composeNamePublicSub),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isBrand ? false : _isAnonymous,
                onChanged: isBrand
                    ? null
                    : (v) => setState(() => _isAnonymous = v),
                activeThumbColor: AppColors.gold,
                activeTrackColor: AppColors.gold.withValues(alpha: 0.3),
                inactiveTrackColor: AppColors.bgSurface,
                inactiveThumbColor: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 브랜드 대량 발송 토글 ────────────────────────────────────────────────
  Widget _buildBulkModeToggle() {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    // 특송 ON이면 gold, 대량만 ON이면 orange, OFF면 기본
    final activeColor = (_isBulkMode && _isExpressMode)
        ? const Color(0xFFFFD700)
        : const Color(0xFFFF8A5C);
    return GestureDetector(
      onTap: () => setState(() {
        _isBulkMode = !_isBulkMode;
        if (!_isBulkMode) {
          _bulkTargets.clear();
          _isExpressMode = false;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isBulkMode
              ? activeColor.withValues(alpha: 0.12)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: _isBulkMode
                ? activeColor.withValues(alpha: 0.5)
                : AppColors.textMuted.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isBulkMode ? Icons.public_rounded : Icons.public_off_rounded,
              color: _isBulkMode ? activeColor : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Text(
                    _isBulkMode ? '🌍 ${l10n.composeBulkOn}' : '🌍 ${l10n.composeBulkBrandOnly}',
                    style: TextStyle(
                      color: _isBulkMode ? activeColor : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_isBulkMode && _isExpressMode) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        '⚡ ${l10n.composeWithin5Min}',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: _isBulkMode,
              onChanged: (v) => setState(() {
                _isBulkMode = v;
                if (!v) {
                  _bulkTargets.clear();
                  _isExpressMode = false;
                }
              }),
              activeColor: activeColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  // ── 브랜드 특송 토글 ─────────────────────────────────────────────────────
  Widget _buildExpressToggle() {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return GestureDetector(
      onTap: () => setState(() => _isExpressMode = !_isExpressMode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isExpressMode
              ? const Color(0xFFFFD700).withValues(alpha: 0.12)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: _isExpressMode
                ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                : AppColors.textMuted.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.bolt_rounded,
              color: _isExpressMode
                  ? const Color(0xFFFFD700)
                  : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isExpressMode
                    ? '⚡ ${l10n.composeExpressModeOn}'
                    : '⚡ ${l10n.composeExpressModeBrand}',
                style: TextStyle(
                  color: _isExpressMode
                      ? const Color(0xFFFFD700)
                      : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch(
              value: _isExpressMode,
              onChanged: (v) => setState(() => _isExpressMode = v),
              activeColor: const Color(0xFFFFD700),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  // ── 브랜드 특송 패널 ─────────────────────────────────────────────────────
  Widget _buildExpressPanel() {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final langCode = context.read<AppState>().currentUser.languageCode;
    final allCountries = AppState.countries;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Text(
                '⚡ ${l10n.composeExpressSettings}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.composeExpressSettingsSub,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 나라 선택
          Text(
            l10n.composeTargetCountry,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 2.2,
              ),
              itemCount: allCountries.length.clamp(0, 16),
              itemBuilder: (context, idx) {
                final c = allCountries[idx];
                final name = c['name'] as String;
                final flag = c['flag'] as String;
                final selected = _selectedCountry == name && _isExpressMode;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCountry = name;
                      _selectedFlag = flag;
                      _isRandom = false;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                          : AppColors.bgDeep,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFFFD700).withValues(alpha: 0.7)
                            : AppColors.textMuted.withValues(alpha: 0.15),
                        width: selected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      '$flag ${CountryL10n.localizedName(name, langCode)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: selected
                            ? const Color(0xFFFFD700)
                            : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // 발송 수 선택
          Row(
            children: [
              Text(
                l10n.composeAddressCount,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // 슬라이더
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      if (_expressCount > 3) _expressCount--;
                    }),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.bgDeep,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: AppColors.textMuted.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.remove,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.composeCountUnit(_expressCount),
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() {
                      if (_expressCount < 10) _expressCount++;
                    }),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.bgDeep,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: AppColors.textMuted.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCountry.isNotEmpty
                ? l10n.composeExpressSummary(_selectedFlag, CountryL10n.localizedName(_selectedCountry, langCode), _expressCount)
                : l10n.composeSelectCountryAbove,
            style: TextStyle(
              color: _selectedCountry.isNotEmpty
                  ? const Color(0xFFFFD700).withValues(alpha: 0.85)
                  : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── 브랜드 대량 발송 패널 ────────────────────────────────────────────────
  Widget _buildBulkSendPanel(AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final langCode = state.currentUser.languageCode;
    final allCountries = AppState.countries;
    final panelColor = _isExpressMode
        ? const Color(0xFFFFD700)
        : const Color(0xFFFF8A5C);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isExpressMode
            ? const Color(0xFFFFD700).withValues(alpha: 0.05)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: panelColor.withValues(alpha: 0.45),
          width: _isExpressMode ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 특송 토글 ──────────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _isExpressMode = !_isExpressMode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _isExpressMode
                    ? const Color(0xFFFFD700).withValues(alpha: 0.12)
                    : AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isExpressMode
                      ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                      : AppColors.textMuted.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: _isExpressMode
                        ? const Color(0xFFFFD700)
                        : AppColors.textMuted,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isExpressMode
                              ? '⚡ ${l10n.composeExpressOnShort}'
                              : '⚡ ${l10n.composeExpressModeBrand}',
                          style: TextStyle(
                            color: _isExpressMode
                                ? const Color(0xFFFFD700)
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_isExpressMode)
                          Text(
                            l10n.composeExpressDeliveryEachCountry,
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isExpressMode,
                    onChanged: (v) => setState(() => _isExpressMode = v),
                    activeColor: const Color(0xFFFFD700),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          ),
          // 특송 ON → 나라당 주소 수 선택
          if (_isExpressMode) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '⚡ ${l10n.composeAddressPerCountry}',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    if (_expressCount > 3) _expressCount--;
                  }),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.bgDeep,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.remove,
                      size: 13,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    l10n.composeCountUnit(_expressCount),
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    if (_expressCount < 10) _expressCount++;
                  }),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.bgDeep,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 13,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // 헤더
          Row(
            children: [
              Text(
                '🌍 ${l10n.composeSelectTargetCountry}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                l10n.composeSelectedCount(_bulkTargets.length),
                style: TextStyle(
                  color: panelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 나라 그리드
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allCountries.map((c) {
              final selected = _bulkTargets.any(
                (t) => t['country'] == c['name'],
              );
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _bulkTargets.removeWhere((t) => t['country'] == c['name']);
                  } else {
                    _bulkTargets.add({
                      'country': c['name'],
                      'flag': c['flag'],
                      'lat': double.parse(c['lat']!),
                      'lng': double.parse(c['lng']!),
                    });
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFF8A5C).withValues(alpha: 0.2)
                        : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFF8A5C)
                          : AppColors.textMuted.withValues(alpha: 0.25),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c['flag']!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Text(
                        CountryL10n.localizedName(c['name']!, langCode),
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFFFF8A5C)
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // 나라당 발송 횟수
          Row(
            children: [
              Text(
                '📮 ${l10n.composeSendPerCountry}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  if (_bulkSendCount > 1) _bulkSendCount--;
                }),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$_bulkSendCount',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  if (_bulkSendCount < 10) _bulkSendCount++;
                }),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 총 발송 요약
          if (_bulkTargets.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isExpressMode
                    ? const Color(0xFFFFD700).withValues(alpha: 0.08)
                    : const Color(0xFFFF8A5C).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isExpressMode
                        ? l10n.composeBulkExpressSummary(_bulkTargets.length * _expressCount, _bulkTargets.length, _expressCount)
                        : l10n.composeBulkSendSummary(_bulkTargets.length * _bulkSendCount, _bulkTargets.length, _bulkSendCount),
                    style: TextStyle(
                      color: _isExpressMode
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFFF8A5C),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_isExpressMode) ...[
                    const SizedBox(height: 2),
                    Text(
                      '⏱ ${l10n.composeDeliveryIn5Min}',
                      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── 이미지 첨부 버튼 ─────────────────────────────────────────────────────
  Widget _buildImageAttachButton(
    AppState state, {
    required bool hasPremium,
    required PurchaseService purchase,
  }) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final isPremium = hasPremium;
    final hasImage = _imageFilePath != null;
    final color = hasImage
        ? AppColors.teal
        : (isPremium ? AppColors.textSecondary : AppColors.textMuted);

    return GestureDetector(
      onTap: _isCompressingImage ? null : () => _pickImage(state, purchase),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage
                ? AppColors.teal.withValues(alpha: 0.4)
                : AppColors.textMuted.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            _isCompressingImage
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.teal,
                    ),
                  )
                : Icon(
                    hasImage
                        ? Icons.image_rounded
                        : Icons.add_photo_alternate_outlined,
                    color: color,
                    size: 18,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isCompressingImage
                    ? l10n.composeImageProcessing
                    : hasImage
                    ? l10n.composePhotoAttached
                    : isPremium
                    ? '📸 ${l10n.composePhotoAttachPremium}'
                    : '📸 ${l10n.composePhotoAttachLocked}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  '👑 PRO',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            if (isPremium && !_isCompressingImage)
              Text(
                l10n.composeQuotaRemaining(state.remainingImageQuota),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── 이미지 미리보기 ──────────────────────────────────────────────────────
  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_imageFilePath!),
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _imageFilePath = null),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              padding: const EdgeInsets.all(5),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyleBar() {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
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
        // ── 배송 이모티콘 꾸미기 버튼 ─────────────────────────────────────────
        GestureDetector(
          onTap: _showEmojiPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: _categoryEmojis.isNotEmpty
                  ? LinearGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.22),
                        AppColors.teal.withValues(alpha: 0.14),
                      ],
                    )
                  : null,
              color: _categoryEmojis.isEmpty ? AppColors.bgCard : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _categoryEmojis.isNotEmpty
                    ? AppColors.gold.withValues(alpha: 0.75)
                    : AppColors.textMuted.withValues(alpha: 0.35),
                width: _categoryEmojis.isNotEmpty ? 1.5 : 1.0,
              ),
              boxShadow: _categoryEmojis.isNotEmpty
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.18),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 선택된 이모티콘 미리보기 or 기본 아이콘
                _categoryEmojis.isNotEmpty
                    ? Text(
                        _emojiPreview,
                        style: const TextStyle(fontSize: 15),
                        textAlign: TextAlign.center,
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('🚚', style: TextStyle(fontSize: 13)),
                          Text('✈️', style: TextStyle(fontSize: 13)),
                          Text('🚢', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 9,
                      color: _categoryEmojis.isNotEmpty
                          ? AppColors.gold
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _categoryEmojis.isNotEmpty ? l10n.composeDecorating : l10n.composeDecorate,
                      style: TextStyle(
                        color: _categoryEmojis.isNotEmpty
                            ? AppColors.gold
                            : AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
        '🚚',
        '🚛',
        '🚗',
        '🚕',
        '🚙',
        '🛻',
        '🚐',
        '🚌',
        '🚑',
        '🚒',
        '🚂',
        '🚄',
        '🚅',
        '🚆',
        '🚇',
        '🚊',
        '🚝',
        '🏎️',
        '🛵',
        '🏍️',
        '🐪',
        '🐘',
        '🐎',
        '🦒',
        '🛺',
        '📦',
        '🎁',
        '📫',
        '🗃️',
        '🧳',
      ],
    },
    {
      'tab': '✈️ 항공',
      'emojis': [
        '✈️',
        '🛩️',
        '🚀',
        '🛸',
        '🎈',
        '🪂',
        '🦅',
        '🕊️',
        '🦜',
        '🦋',
        '🦢',
        '🦩',
        '🦆',
        '🐦',
        '🌠',
        '💫',
        '⭐',
        '🌟',
        '🌪️',
        '🎆',
        '🎇',
        '🪁',
        '🛷',
        '💌',
        '🎠',
        '🛺',
        '🪄',
        '🔮',
        '🌈',
        '☁️',
      ],
    },
    {
      'tab': '🌊 바다',
      'emojis': [
        '🚢',
        '⛵',
        '🛥️',
        '🚤',
        '⛴️',
        '🛶',
        '⚓',
        '🌊',
        '🐳',
        '🐬',
        '🦈',
        '🐙',
        '🦀',
        '🦞',
        '🐠',
        '🐟',
        '🦑',
        '🐚',
        '🪸',
        '🏄',
        '🤿',
        '🧜',
        '🌍',
        '🗺️',
        '🧭',
        '🏝️',
        '⛅',
        '🌅',
        '🌊',
        '💎',
      ],
    },
  ];

  void _showEmojiPicker() {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    int tabIndex = 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final tabColors = [
            AppColors.gold,
            AppColors.teal,
            const Color(0xFF60A5FA),
          ];
          final tabLabel = ['🛣️ ${l10n.composeLand}', '✈️ ${l10n.composeAir}', '🌊 ${l10n.composeSea}'];
          final selectedInTab = _categoryEmojis[tabIndex];

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0D1421),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 핸들 ──────────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // ── 헤더 ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                  child: Row(
                    children: [
                      const Text('🎨', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.composeEmojiDecorate,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              l10n.composeEmojiDecorateSub,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_categoryEmojis.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() => _categoryEmojis.clear());
                            setSheet(() {});
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            l10n.composeReset,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
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
                // ── 현재 조합 미리보기 ──────────────────────────────────────
                if (_categoryEmojis.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${l10n.composeSelectedCombo}  ',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        for (int i = 0; i < 3; i++) ...[
                          if (_categoryEmojis.containsKey(i)) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: tabColors[i].withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: tabColors[i].withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                _categoryEmojis[i]!,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            if (i < 2 && _categoryEmojis.keys.any((k) => k > i))
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '+',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ],
                    ),
                  ),
                // ── 카테고리 탭 ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: List.generate(
                      3,
                      (i) => Expanded(
                        child: GestureDetector(
                          onTap: () => setSheet(() => tabIndex = i),
                          child: Container(
                            margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: tabIndex == i
                                  ? tabColors[i].withValues(alpha: 0.15)
                                  : AppColors.bgCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: tabIndex == i
                                    ? tabColors[i].withValues(alpha: 0.7)
                                    : _categoryEmojis.containsKey(i)
                                    ? tabColors[i].withValues(alpha: 0.35)
                                    : AppColors.textMuted.withValues(
                                        alpha: 0.2,
                                      ),
                                width: tabIndex == i ? 1.5 : 1.0,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Center(
                                  child: Text(
                                    tabLabel[i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: tabIndex == i
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: tabIndex == i
                                          ? tabColors[i]
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                // 선택 완료 배지
                                if (_categoryEmojis.containsKey(i))
                                  Positioned(
                                    top: -4,
                                    right: 4,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: tabColors[i],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // ── 이모티콘 그리드 ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
                    itemCount:
                        (_emojiGroups[tabIndex]['emojis'] as List).length,
                    itemBuilder: (_, i) {
                      final emoji =
                          (_emojiGroups[tabIndex]['emojis'] as List)[i]
                              as String;
                      final isSelected = selectedInTab == emoji;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              // 이미 선택된 거 다시 탭하면 해제
                              _categoryEmojis.remove(tabIndex);
                            } else {
                              _categoryEmojis[tabIndex] = emoji;
                            }
                          });
                          setSheet(() {});
                          // 자동 닫기 없이 계속 선택 가능
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? tabColors[tabIndex].withValues(alpha: 0.18)
                                : AppColors.bgCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? tabColors[tabIndex]
                                  : AppColors.textMuted.withValues(alpha: 0.15),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: tabColors[tabIndex].withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
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
                // ── 완료 버튼 ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _categoryEmojis.isNotEmpty
                            ? AppColors.gold
                            : AppColors.bgCard,
                        foregroundColor: _categoryEmojis.isNotEmpty
                            ? const Color(0xFF0D1421)
                            : AppColors.textMuted,
                        elevation: _categoryEmojis.isNotEmpty ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: _categoryEmojis.isNotEmpty
                                ? AppColors.gold
                                : AppColors.textMuted.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_categoryEmojis.isNotEmpty) ...[
                            Text(
                              _categoryEmojis.values.join(' '),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _categoryEmojis.isNotEmpty ? l10n.composeComboDone : l10n.composeCloseNoSelection,
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPaperPicker() {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
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
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.composePaperSelect,
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
                    Expanded(
                      child: Text(
                        l10n.composeMorePaperPro,
                        style: const TextStyle(
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
                      child: Text(
                        l10n.composeComingSoon,
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
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
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
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.composeFontSelect,
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
                              l10n.composeFontPreview,
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
                  Expanded(
                    child: Text(
                      l10n.composeMoreFontPro,
                      style: const TextStyle(
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
                    child: Text(
                      l10n.composeComingSoon,
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
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final canSend =
        !_isSending && _charCount >= 1 && state.hasRemainingDailyQuota;
    final expressQuotaSuffix =
        (!_isReply &&
            _isExpressMode &&
            !_isBulkMode &&
            !state.currentUser.isBrand &&
            state.currentUser.isPremium)
        ? ' · ${l10n.composeExpressQuota(state.todayPremiumExpressSentCount, state.premiumExpressDailyLimit)}'
        : '';
    final rewardSuffix = state.inviteRewardCredits > 0
        ? ' · ${l10n.composeBonus(state.inviteRewardCredits)}'
        : '';
    final quotaText =
        (state.isGeneralMember
            ? l10n.composeQuotaGeneral(state.todaySentCount, state.dailySendLimit, state.remainingDailySendCount)
            : state.isBrandMember
            ? l10n.composeQuotaBrand(state.todaySentCount, state.dailySendLimit, state.remainingMonthlySendCount)
            : l10n.composeQuotaPremium(state.todaySentCount, state.dailySendLimit, state.remainingMonthlySendCount)) +
        expressQuotaSuffix +
        rewardSuffix;
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
                        ? l10n.composeSendReply
                        : _isRandom
                        ? '${l10n.sendLetter} → 🌍'
                        : '${l10n.sendLetter} → $_selectedFlag',
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

// ── 편지지 배경 (향후 사용 예정) ────────────────────────────────────────────
// ignore: unused_element
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
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
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
                child: Text(
                  l10n.composeLetterDeparting,
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
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final langCode = context.read<AppState>().currentUser.languageCode;
    final filtered = AppState.countries
        .where(
          (c) => c['name']!.contains(_search) || c['flag']!.contains(_search) || CountryL10n.localizedName(c['name']!, langCode).toLowerCase().contains(_search.toLowerCase()),
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
            child: Text(
              l10n.composeSelectDestination,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          // ── 랜덤 카드 (목록 최상단) ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GestureDetector(
              onTap: widget.onRandom,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('🎲', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🌍 ${l10n.composeSendRandom}',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.composeSendRandomSub,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.shuffle_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── 구분선 ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppColors.textMuted.withValues(alpha: 0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    l10n.composeOrSelectCountry,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: AppColors.textMuted.withValues(alpha: 0.2),
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
                hintText: '🔍  ${l10n.composeSearchCountry}',
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
                    CountryL10n.localizedName(c['name']!, langCode),
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
