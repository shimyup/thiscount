import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/letter_style.dart';
import '../../../core/data/country_cities.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../models/letter.dart';
import '../../../state/app_state.dart';
import '../../../core/services/purchase_service.dart';
import '../../city_of_month/city_of_month.dart';
import '../../premium/premium_gate_sheet.dart';
import '../../premium/brand_only_gate_sheet.dart';
import '../compose_prompts.dart';
import '../compose_quick_pick.dart';
import '../day_theme.dart';
import '../widgets/exact_drop_picker.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/services/storage_service.dart';

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
  // 브랜드 쿠폰/교환권 사용 안내 (자유 텍스트, 최대 200자)
  final _redemptionInfoController = TextEditingController();
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

  // ── 오늘의 편지 (Today's Letter) ─────────────────────────────────────────
  bool _isLuckyLetter = false;

  static const Map<String, List<String>> _luckyQuotesByLang = {
    'ko': [
      // 1. 일상의 행복
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
    ],
    'en': [
      'Hello, warm greetings to you who received this letter.\n\n'
          'I hope today brings you joy in the little things — '
          'a warm cup of coffee in the morning, a gentle breeze passing by, '
          'sunlight streaming through the window. '
          'Those small moments add up to make your day shine.\n\n'
          'From a stranger cheering you on, somewhere out there. 🍀',
      'Hello, I write this letter hoping it reaches you.\n\n'
          'The world is vast, and beautiful connections can begin anywhere. '
          'I would love it if this letter became one such beginning. '
          'Even though we may never know each other\'s names or faces, '
          'being connected through this letter is already something wonderful.\n\n'
          'Looking forward to the day our paths might cross. 💌',
      'Hello, I hope these words give you a little strength.\n\n'
          'No matter what kind of day you\'re having, you\'re doing just fine. '
          'It\'s okay not to be perfect. You don\'t have to do it all. '
          'Just making it through today already makes you remarkable.\n\n'
          'Don\'t give up. I\'m rooting for you from afar. 💪',
      'Hello, I\'m sending this letter from somewhere in the world.\n\n'
          'Moving forward little by little each day — that alone is incredible. '
          'Don\'t compare yourself to others; just be a little better than yesterday, '
          'and that\'s more than enough. A life lived at your own pace is the most beautiful life.\n\n'
          'Thank you for all your hard work today. 🌟',
      'Hello, I believe receiving this letter is a meaningful connection.\n\n'
          'The world is full of warmer hearts than you might think. '
          'Sometimes a small kindness from a stranger can change your whole day. '
          'I hope this letter brings that kind of warmth to your today.\n\n'
          'The world is a little warmer because of you. 🌍',
    ],
    'ja': [
      'こんにちは、この手紙を受け取ったあなたに温かい挨拶を送ります。\n\n'
          '今日一日、小さなことの中に幸せを見つける日になりますように。'
          '朝の温かいコーヒー一杯、通り過ぎる風、窓の外の日差し — '
          'その小さなものが集まって、あなたの一日を輝かせてくれるでしょう。\n\n'
          'どこかであなたを応援している見知らぬ友人より。🍀',
      'こんにちは、この手紙があなたに届くことを願って書いています。\n\n'
          '世界は広く、素敵な縁はいつどこで始まるかわかりません。'
          'この手紙がそのきっかけになれたら本当に嬉しいです。'
          '名前も顔も知らない私たちですが、こうして手紙で繋がったことだけでも '
          '十分に美しい縁だと思います。\n\n'
          'いつか、どこかで会える日を楽しみにしています。💌',
      'こんにちは、この言葉があなたの小さな力になることを願っています。\n\n'
          '今どんな一日を過ごしていても、あなたは十分頑張っています。'
          '完璧でなくてもいい、すべてをやり遂げなくてもいい。'
          'ただ今日一日を乗り越えただけで、あなたはすでに素晴らしい人です。\n\n'
          '諦めないでください。遠くから応援しています。💪',
      'こんにちは、世界のどこかからこの手紙を送ります。\n\n'
          '毎日少しずつ前に進むこと、それだけでも十分にすごいことです。'
          '他人と比べず、昨日の自分より少しだけ前に進めばそれで十分。'
          'あなたのペースで歩む人生が、一番美しい人生です。\n\n'
          '今日もお疲れ様でした。🌟',
      'こんにちは、この手紙を受け取ったことも一つの縁だと思います。\n\n'
          '世界は思ったよりもずっと温かい人々で溢れています。'
          '時には見知らぬ人の小さな思いやりが一日を変えることもあります。'
          'この手紙があなたの今日にそんな小さな温もりになれたら幸いです。\n\n'
          'あなたのおかげで世界は少し温かくなっています。🌍',
    ],
  };

  /// Returns all lucky quotes for the given language (falls back to English).
  static List<String> _luckyQuotesForLang(String langCode) {
    return _luckyQuotesByLang[langCode] ?? _luckyQuotesByLang['en']!;
  }

  /// 직전에 적용된 영감 편지 글귀 (같은 글귀 반복 방지용)
  String? _lastLuckyQuote;

  void _applyLuckyLetter() {
    final langCode = context.read<AppState>().currentUser.languageCode;
    final quotes = _luckyQuotesForLang(langCode).toList()..shuffle();
    // 직전 글귀와 다른 것을 선택 (2개 이상이면 보장)
    String quote = quotes.first;
    if (quotes.length > 1 && quote == _lastLuckyQuote) {
      quote = quotes[1];
    }
    _lastLuckyQuote = quote;
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
  bool _isBulkRandom = false; // 랜덤 국가 대량 발송 모드
  final List<Map<String, dynamic>> _bulkTargets = []; // 선택된 나라 목록

  // ── 브랜드 특송 ───────────────────────────────────────────────────────────
  bool _isExpressMode = false; // 특송 모드 여부

  // ── 나라당 발송 수 (통합) ─────────────────────────────────────────────────
  int _sendPerCountry = 5; // 나라당 발송 수 (1~50)

  // ── 브랜드 고급 옵션 ──────────────────────────────────────────────────────
  bool _brandUniquePerUser = false; // 1 아이디당 1 편지
  bool _brandAcceptsReplies = true; // 답장 수락 여부 (기본 on)
  bool _isExactDropped = false; // ExactDrop 로 좌표 선택됨 → 발송 시 크레딧 차감
  int? _brandAutoExpireHours; // 자동 삭제 시간 (null=없음)
  // Brand 전용 편지 카테고리 — 일반 / 할인권 / 교환권. 수집첩에서 쿠폰함 섹션
  // 으로 분리 표시되므로 브랜드 운영자가 발송 의도를 명확히 지정한다.
  LetterCategory _brandCategory = LetterCategory.general;

  // Build 130: 교환권(voucher) 이미지 선택 로컬 경로. non-null 일 때는
  // `_redemptionInfoController.text` 도 이 경로와 동기화돼 있음. 유저가 URL
  // 을 직접 타이핑하면 null 로 되돌아가 이미지 선택 상태 해제.
  String? _voucherImageLocalPath;
  // Build 136: Firebase Storage 업로드 중 플래그 — 썸네일 위에 progress 표시.
  bool _isUploadingVoucher = false;

  // Build 132: 쿠폰/교환권 유효기간 (일 단위). null = 무제한.
  // 기본 30일 — Kakao Gift 평균 유효기간과 동일. coupon/voucher 카테고리에서만
  // 전송되며 general 카테고리에서는 무시.
  int? _redemptionValidityDays = 30;
  static const List<int?> _redemptionValidityChoices = [7, 30, 90, 365, null];

  static const List<String> _bannedWords = [
    // English
    'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'dick', 'pussy', 'cunt',
    'nigger', 'nigga', 'faggot', 'whore', 'slut', 'rape', 'kill yourself',
    'kys', 'retard',
    // 한국어
    '씨발', '병신', '개새끼', '존나', '지랄', '엿먹', '꺼져', '죽어',
    '미친놈', '미친년', '창녀', '보지', '자지', '좆',
    // 日本語
    'くそ', 'ばか', 'しね', '死ね', 'きもい', 'うざい', 'ころす', '殺す',
    'ちんこ', 'まんこ', 'おっぱい', 'やりまん',
    // 中文
    '他妈', '操你', '妈逼', '傻逼', '狗屎', '去死', '废物', '贱人',
    '混蛋', '王八蛋', '滚蛋',
    // Español
    'mierda', 'puta', 'cabrón', 'pendejo', 'joder', 'coño', 'maricón',
    'hijo de puta', 'culero', 'verga',
    // Français
    'merde', 'putain', 'connard', 'salaud', 'enculé', 'bordel', 'nique',
    'ta gueule', 'pédé', 'salope',
    // Deutsch
    'scheiße', 'arschloch', 'hurensohn', 'wichser', 'fotze', 'missgeburt',
    'schwuchtel', 'drecksau',
    // Português
    'merda', 'porra', 'caralho', 'filho da puta', 'buceta', 'viado',
    'desgraça', 'otário', 'piranha',
    // Русский
    'блядь', 'сука', 'хуй', 'пизда', 'ебать', 'мудак', 'дерьмо',
    'говно', 'пиздец', 'заткнись',
    // Spam patterns (multilingual)
    '카지노', '도박', '대출', '비트코인 투자', '클릭하세요',
    'casino', 'gambling', 'bitcoin invest', 'click here', 'free money',
    'カジノ', '赌博', '賭博',
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
      // 오늘의 편지 글귀와 달라지면 플래그 해제 (직접 수정한 것으로 간주).
      // 앞뒤 공백 추가/제거는 사용자 편집으로 간주하지 않음 → trim 후 비교.
      final langCode = context.read<AppState>().currentUser.languageCode;
      final allQuotes = _luckyQuotesForLang(langCode);
      final isStillLucky = allQuotes.contains(text.trim());
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
                backgroundColor: AppColors.bgSurface,
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
      // Build 189: 3초마다 자동 저장. text 가 비었어도 brand/mode 상태가 바뀌어
      // 있으면 저장 (이전엔 text 비면 저장 안 해서 bulk/express 상태가 휘발).
      _autoSaveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (_isSending) return;
        if (_contentController.text.isNotEmpty ||
            _isBulkMode ||
            _isExpressMode ||
            _bulkTargets.isNotEmpty ||
            _selectedCountry.isNotEmpty) {
          _saveDraft();
        }
      });
    });
  }

  /// Build 189: 브랜드 필드까지 저장. 창 닫아도 모드/나라 선택이 유지되도록.
  void _saveDraft() {
    SharedPreferences.getInstance().then((prefs) {
      final text = _contentController.text;
      if (text.isEmpty) {
        prefs.remove('compose_draft');
      } else {
        prefs.setString('compose_draft', text);
      }
      // Brand/compose 상태 스냅샷 — JSON 한 덩어리에 묶어 저장·복원.
      final snapshot = <String, dynamic>{
        'isBulkMode': _isBulkMode,
        'isExpressMode': _isExpressMode,
        'isRandom': _isRandom,
        'selectedCountry': _selectedCountry,
        'selectedFlag': _selectedFlag,
        'selectedCity': _selectedCity,
        'destLat': _destLat,
        'destLng': _destLng,
        'isExactDropped': _isExactDropped,
        'sendPerCountry': _sendPerCountry,
        'isBulkRandom': _isBulkRandom,
        'bulkTargets': _bulkTargets,
        'attachSocial': _attachSocial,
        'socialLink': _socialLinkController.text,
        'brandCategory': _brandCategory.key,
        'redemptionInfo': _redemptionInfoController.text,
      };
      final hasState = _isBulkMode ||
          _isExpressMode ||
          _bulkTargets.isNotEmpty ||
          _selectedCountry.isNotEmpty;
      if (hasState) {
        try {
          prefs.setString('compose_draft_brand', jsonEncode(snapshot));
        } catch (_) {}
      } else {
        prefs.remove('compose_draft_brand');
      }
    });
  }

  Future<void> _loadDraftIfExists() async {
    if (_isReply) return;
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString('compose_draft') ?? '';
    final brandRaw = prefs.getString('compose_draft_brand');
    if (draft.isEmpty && brandRaw == null) return;
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
                if (draft.isNotEmpty) {
                  _contentController.text = draft;
                  _charCount = draft.length;
                }
                // Build 189: Brand/compose 상태 복원.
                if (brandRaw != null && brandRaw.isNotEmpty) {
                  try {
                    final snap =
                        jsonDecode(brandRaw) as Map<String, dynamic>;
                    _isBulkMode = snap['isBulkMode'] as bool? ?? false;
                    _isExpressMode =
                        snap['isExpressMode'] as bool? ?? false;
                    _isRandom = snap['isRandom'] as bool? ?? true;
                    _selectedCountry =
                        snap['selectedCountry'] as String? ?? '';
                    _selectedFlag = snap['selectedFlag'] as String? ?? '';
                    _selectedCity = snap['selectedCity'] as String? ?? '';
                    _destLat =
                        (snap['destLat'] as num?)?.toDouble() ?? 0.0;
                    _destLng =
                        (snap['destLng'] as num?)?.toDouble() ?? 0.0;
                    _isExactDropped =
                        snap['isExactDropped'] as bool? ?? false;
                    _sendPerCountry =
                        (snap['sendPerCountry'] as num?)?.toInt() ?? 5;
                    _isBulkRandom =
                        snap['isBulkRandom'] as bool? ?? false;
                    _bulkTargets.clear();
                    final rawTargets = snap['bulkTargets'];
                    if (rawTargets is List) {
                      for (final t in rawTargets) {
                        if (t is Map) {
                          _bulkTargets.add(
                            Map<String, dynamic>.from(t),
                          );
                        }
                      }
                    }
                    _attachSocial = snap['attachSocial'] as bool? ?? false;
                    final sns = snap['socialLink'] as String? ?? '';
                    if (sns.isNotEmpty) _socialLinkController.text = sns;
                    final catKey = snap['brandCategory'] as String?;
                    if (catKey != null) {
                      _brandCategory = LetterCategoryExt.fromKey(catKey);
                    }
                    final ri = snap['redemptionInfo'] as String? ?? '';
                    if (ri.isNotEmpty) {
                      _redemptionInfoController.text = ri;
                    }
                  } catch (_) {}
                }
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
      prefs.remove('compose_draft_brand');
    });
  }

  /// 마지막 보낸 편지 내용 저장 (사진/링크 제외, 텍스트만)
  static void saveLastSentContent(String content) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('last_sent_content', content);
    });
  }

  /// 마지막 보낸 편지 불러오기
  void _loadLastSentLetter() async {
    if (_isReply) return;
    final prefs = await SharedPreferences.getInstance();
    final lastContent = prefs.getString('last_sent_content') ?? '';
    if (lastContent.isEmpty) {
      if (mounted) {
        final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.composeNoLastLetter),
            backgroundColor: AppColors.bgCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.composeLoadLastTitle,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Text(
              lastContent,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.composeDiscard, style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _contentController.text = lastContent;
                _charCount = lastContent.length;
                _isLuckyLetter = false;
              });
              Navigator.pop(ctx);
            },
            child: Text(l10n.composeLoadLastConfirm, style: const TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  void _pickRandomDestination({String? excludeCountry}) {
    final dest = AppState.randomDestination(excludeCountry: excludeCountry);
    final countryName = dest['name']!;
    final langCode = context.read<AppState>().currentUser.languageCode;

    // 1차: GeocodingService 캐시에서 실제 주소 사용
    final geo = GeocodingService.instance;
    final cachedAddr = geo.isInitialized
        ? geo.getCachedAddress(countryName)
        : null;

    if (cachedAddr != null) {
      setState(() {
        _selectedCountry = countryName;
        _selectedFlag = dest['flag']!;
        _selectedCity = (cachedAddr['city'] as String?) ?? '';
        _destLat = (cachedAddr['lat'] as num).toDouble();
        _destLng = (cachedAddr['lng'] as num).toDouble();
        _isRandom = true;
      });
      // 캐시 소진 시 백그라운드 보충
      if (geo.cachedCountOf(countryName) < 3) {
        geo.prefetch(countryName, count: 5);
      }
      return;
    }

    // 2차: cities.json 기반 랜덤 도시
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
    // Build 189: dispose 시 항상 저장 (text 비어도 bulk/express/나라 상태 유지).
    // 이전엔 text 가 empty 면 save 안 해서 "작성 중간 화면 나가면 모드가 날아감".
    if (!_isSending) {
      _saveDraft();
    }
    _contentController.dispose();
    _socialLinkController.dispose();
    _redemptionInfoController.dispose();
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
          backgroundColor: AppColors.bgSurface,
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
    // Brand 가 쿠폰/교환권 카테고리로 보낼 때는 본문 대신 "사용 방법" 필드가
    // 핵심 콘텐츠가 되므로 20자 최소 규칙을 완화. 본문은 여전히 비어선 안 되고
    // (스낵바·알림·인박스 프리뷰에 쓰임) 1자 이상만 있으면 통과. 일반 편지는
    // 기존 규칙(20자 이상) 유지.
    final isBrandPromo = state.currentUser.isBrand &&
        _brandCategory != LetterCategory.general;
    if (content.isEmpty) {
      _showError(l10n.composeEmptyError);
      return;
    }
    if (!isBrandPromo && content.length < 20) {
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
      if (!_isBulkRandom && _bulkTargets.isEmpty) {
        _showError(l10n.composeSelectCountryError);
        return;
      }
      FocusScope.of(context).unfocus();
      setState(() => _isSending = true);
      await _sendController.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      await _refreshCurrentLocationIfAvailable(state);

      int totalSent = 0;
      if (_isBulkRandom) {
        // 랜덤 국가 특송: 매 편지마다 랜덤 국가 선택
        for (int i = 0; i < _sendPerCountry; i++) {
          final dest = AppState.randomDestination(
            excludeCountry: state.currentUser.country,
          );
          final sent = await state.sendBrandExpressBlast(
            content: content,
            destinationCountry: dest['name']!,
            destinationFlag: dest['flag']!,
            count: 1,
            deliveryEmoji: _deliveryEmojiEncoded,
            socialLink: _attachSocial && _socialLinkController.text.isNotEmpty
                ? _socialLinkController.text.trim()
                : null,
            paperStyle: _paperStyle,
            fontStyle: _fontStyle,
            brandUniquePerUser: _brandUniquePerUser,
            brandAutoExpireHours: _brandAutoExpireHours,
            imageUrl: _imageFilePath,
            category: _brandCategory,
            acceptsReplies: _brandAcceptsReplies,
            redemptionInfo: _redemptionInfoController.text.trim().isEmpty
                ? null
                : _redemptionInfoController.text.trim(),
            redemptionExpiresAt: _computeRedemptionExpiresAt(),
          );
          totalSent += sent;
          if (sent == 0) break; // 한도 초과 시 중단
        }
      } else {
        for (final target in _bulkTargets) {
          totalSent += await state.sendBrandExpressBlast(
            content: content,
            destinationCountry: target['country'] as String,
            destinationFlag: target['flag'] as String,
            count: _sendPerCountry,
            deliveryEmoji: _deliveryEmojiEncoded,
            socialLink: _attachSocial && _socialLinkController.text.isNotEmpty
                ? _socialLinkController.text.trim()
                : null,
            paperStyle: _paperStyle,
            fontStyle: _fontStyle,
            brandUniquePerUser: _brandUniquePerUser,
            brandAutoExpireHours: _brandAutoExpireHours,
            imageUrl: _imageFilePath,
            category: _brandCategory,
            acceptsReplies: _brandAcceptsReplies,
            redemptionInfo: _redemptionInfoController.text.trim().isEmpty
                ? null
                : _redemptionInfoController.text.trim(),
            redemptionExpiresAt: _computeRedemptionExpiresAt(),
          );
        }
      }
      if (mounted) {
        _clearDraft();
        FeedbackService.onLetterSend();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.composeExpressBulkSent(_bulkTargets.length, _sendPerCountry, totalSent),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.bgCard,
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
      if (!_isBulkRandom && _bulkTargets.isEmpty) {
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
        sendCount: _isBulkRandom ? _sendPerCountry : _sendPerCountry,
        randomMode: _isBulkRandom,
        socialLink: _attachSocial && _socialLinkController.text.isNotEmpty
            ? _socialLinkController.text.trim()
            : null,
        imageUrl: _imageFilePath,
        paperStyle: _paperStyle,
        fontStyle: _fontStyle,
        brandUniquePerUser: _brandUniquePerUser,
        brandAutoExpireHours: _brandAutoExpireHours,
        category: _brandCategory,
        acceptsReplies: _brandAcceptsReplies,
        redemptionInfo: _redemptionInfoController.text.trim().isEmpty
            ? null
            : _redemptionInfoController.text.trim(),
        redemptionExpiresAt: _computeRedemptionExpiresAt(),
      );

      if (mounted) {
        _clearDraft();
        FeedbackService.onLetterSend();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBulkRandom
                  ? '🎲 ${l10n.composeBulkSent(totalSent, totalSent)}'
                  : l10n.composeBulkSent(totalSent, _bulkTargets.length),
              style: const TextStyle(color: Colors.white),
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
      return;
    }

    setState(() => _isSending = true);
    await _sendController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    bool sent = false;
    await _refreshCurrentLocationIfAvailable(state);

    // ExactDrop 사용 편지는 1 크레딧 차감. 부족 시 발송 중단.
    if (_isExactDropped && !_isReply) {
      final ok = await state.consumeExactDropCredit();
      if (!ok) {
        setState(() => _isSending = false);
        _sendController.reset();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.composeExactDropOutOfCredits),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

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
        brandUniquePerUser: _brandUniquePerUser,
        brandAutoExpireHours: _brandAutoExpireHours,
        category: _brandCategory,
        acceptsReplies: _brandAcceptsReplies,
        redemptionInfo: _redemptionInfoController.text.trim().isEmpty
            ? null
            : _redemptionInfoController.text.trim(),
        redemptionExpiresAt: _computeRedemptionExpiresAt(),
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
      // 마지막 보낸 편지 내용 저장 (텍스트만, 사진/링크 제외)
      saveLastSentContent(content);
      // 편지 발송 성공 시 초안 삭제
      _clearDraft();
      // 편지 발송 성공 피드백 (햅틱 + 시스템 사운드)
      FeedbackService.onLetterSend();
      if (shouldShowPremiumWelcome) {
        Navigator.of(context).popAndPushNamed('/premium_welcome');
        return;
      }
      if (_isReply) {
        // 답장: ComposeScreen + LetterReadScreen 모두 닫고 편지함으로 복귀
        Navigator.pop(context, true); // ComposeScreen 닫기
        Navigator.pop(context); // LetterReadScreen 닫기
      } else {
        Navigator.pop(context, true); // ComposeScreen 닫기 → 지도 탭 전환
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
                        color: AppColors.textPrimary,
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
          backgroundColor: AppColors.bgCard,
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

  // Brand 전용 — 지도에서 정확한 좌표 핀을 찍어 편지를 떨어뜨린다.
  // Free / Premium 은 이 진입점을 볼 수 없다.
  // Build 106: 유료 크레딧 필요 (100통 = 10,000원). 크레딧 0 이면 "관리자 문의"
  // 다이얼로그 안내 후 진입 차단.
  Future<void> _selectExactDrop() async {
    final state = context.read<AppState>();
    final langCode = state.currentUser.languageCode;
    final l = AppL10n.of(langCode);

    // Build 189: 디버그/테스트 빌드 에서는 크레딧 0 이어도 ExactDrop 을 열 수
    // 있게 자동 부여 5 통. 개발자/QA 가 실결제 없이 UX 검증 가능.
    if (kDebugMode &&
        state.currentUser.isBrand &&
        state.brandExactDropCredits == 0) {
      await state.adminGrantExactDropCredits(5);
    }

    // 크레딧 체크 — 0 이면 유료 안내 다이얼로그로 이탈.
    if (!state.canUseExactDrop) {
      await showDialog(
        context: context,
        builder: (dCtx) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.composeExactDropPaywallTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.composeExactDropPaywallBody,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('💰', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.composeExactDropPaywallPricing,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              child: Text(
                l.authClose,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final initial = ll.LatLng(
      _destLat != 0.0 ? _destLat : state.currentUser.latitude,
      _destLng != 0.0 ? _destLng : state.currentUser.longitude,
    );
    // Build 158: 과거 Brand 발송 좌표 3개 → ExactDrop 추천 핀으로 전달.
    // 로컬 `_sent` 기반 경량 추천 — 동일 지역 재발송 시 원탭 이동.
    final recs = state
        .brandRecentDropCoordinates(limit: 3)
        .map((p) => ll.LatLng(p.latitude, p.longitude))
        .toList();
    final picked = await Navigator.of(context).push<ll.LatLng>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ExactDropPicker(
          initial: initial,
          langCode: langCode,
          recommendations: recs,
        ),
      ),
    );
    if (!mounted || picked == null) return;

    // 역조회로 국가·도시 이름을 채움. 실패 시 좌표만 세팅하고 국가는
    // "Unknown" 으로 두어 발송 자체는 막지 않는다.
    final geo = GeocodingService.instance;
    String country = '';
    String city = '';
    String flag = '🎯';
    try {
      final addr = await geo.reverseLookup(
        picked.latitude,
        picked.longitude,
        languageCode: langCode,
      );
      if (addr != null) {
        country = addr['country'] ?? '';
        city = addr['city'] ?? '';
        final f = addr['flag'] ?? '';
        if (f.isNotEmpty) flag = f;
      }
    } catch (_) {}

    setState(() {
      _destLat = picked.latitude;
      _destLng = picked.longitude;
      _selectedCountry = country;
      _selectedCity = city;
      _selectedFlag = flag;
      _isRandom = false;
      // 유료 ExactDrop 크레딧은 실제 발송 시점에 차감한다. 단순 선택만으론
      // 크레딧이 소모되지 않게 플래그로 마킹.
      _isExactDropped = true;
    });
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
        final l10n = AppL10n.of(state.currentUser.languageCode);
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
                            // Build 201 — 사용자 요청 재배치:
                            //   1) 나라 선택
                            //   2) 대량 발송 (나라와 편지종류 사이)
                            //   3) 특급 배송 (대량 밑)
                            //   4) 편지 종류 (Brand 카테고리)
                            //   5) 오늘의 영감 (강조)
                            //   6) 편지 꾸미기 (StyleBar)
                            //   7) 더 많은 옵션 (접히는 섹션 — SNS/익명/이미지 등)
                            //   8) 편지 본문 (가장 아래)
                            //   9) 보내기 버튼
                            if (!_isReply)
                              _buildDestinationCard(state, hasPremium),
                            if (!_isReply) const SizedBox(height: 8),

                            // ── 대량 발송 (Brand) — 나라와 편지종류 사이 ──
                            if (!_isReply && isBrand) ...[
                              if (_isBulkMode) _buildActiveModeBanner(state),
                              _buildBulkModeToggle(),
                              const SizedBox(height: 8),
                              if (_isBulkMode) ...[
                                _buildBulkSendPanel(state),
                                const SizedBox(height: 8),
                              ],
                            ],
                            // ── 특급 배송 — 대량 밑 ──
                            if (!_isReply) _buildExpressToggle(state, hasPremium),
                            if (!_isReply) const SizedBox(height: 8),

                            // ── 편지 종류 (Brand 카테고리 / 일반에겐 안내 시트) ──
                            if (!_isReply) _buildBrandCategoryPanel(state),
                            if (!_isReply) const SizedBox(height: 8),

                            // ── 오늘의 영감 (강조 노출) ──
                            if (!_isReply) ...[
                              _buildLuckyLetterButton(),
                              const SizedBox(height: 10),
                              _buildRecallLastLetterButton(),
                              const SizedBox(height: 10),
                            ],

                            // ── 편지 꾸미기 (StyleBar) — 편지지 위쪽 ──
                            _buildStyleBar(),
                            const SizedBox(height: 10),

                            // ── 더 많은 옵션 (접히는 섹션) — 편지지 위쪽 ──
                            _ComposeOptionsSection(
                              title: l10n.composeOptionsSectionTitle,
                              children: [
                                if (!_isReply)
                                  _buildSocialToggle(hasPremium: hasPremium),
                                if (!_isReply && _attachSocial && hasPremium) ...[
                                  const SizedBox(height: 10),
                                  _buildSocialInput(),
                                ],
                                if (!_isReply) const SizedBox(height: 10),
                                if (!_isReply) _buildAnonymousToggle(state),
                                if (!_isReply && isBrand) const SizedBox(height: 10),
                                if (!_isReply && isBrand) _buildBrandOptions(state),
                                const SizedBox(height: 10),
                                _buildImageAttachButton(
                                  state,
                                  hasPremium: hasPremium,
                                  purchase: purchase,
                                ),
                                if (_imageFilePath != null) ...[
                                  const SizedBox(height: 10),
                                  _buildImagePreview(),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── 편지 본문 (가장 아래) ──
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

  /// Build 189.1: 닫기 버튼 안전장치. 본문/모드 상태 있을 때만 확인. 있으면
  /// 1) 임시 저장 후 닫기 (기본)
  /// 2) 초안 삭제 후 닫기
  /// 3) 취소
  Future<void> _tryClose(BuildContext ctx) async {
    final l10n = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    final hasContent = _contentController.text.trim().isNotEmpty ||
        _isBulkMode ||
        _isExpressMode ||
        _bulkTargets.isNotEmpty ||
        (_selectedCountry.isNotEmpty && !_isRandom) ||
        (_redemptionInfoController.text.trim().isNotEmpty);
    if (!hasContent) {
      Navigator.pop(ctx);
      return;
    }
    final choice = await showDialog<String>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.composeCloseConfirmTitle,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: Text(
          l10n.composeCloseConfirmBody,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, 'cancel'),
            child: Text(
              l10n.inboxCancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, 'discard'),
            child: Text(
              l10n.composeDiscard,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, 'save'),
            child: Text(
              l10n.composeSaveDraftAndClose,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (choice == null || choice == 'cancel') return;
    if (choice == 'discard') {
      _clearDraft();
    } else {
      _saveDraft();
    }
    if (ctx.mounted) Navigator.pop(ctx);
  }

  Widget _buildHeader(BuildContext ctx, AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _tryClose(ctx),
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
          // Build 182: 목적지 레이아웃 재배치 — 🌍 나라 선택을 최상단 primary 버튼
          // 으로 두고, 🎲 랜덤 · 🎯 정확한 위치 지정(Brand) 을 그 **아래** 보조
          // 옵션으로 배치. 이전엔 [랜덤|나라선택] 50/50 row 였으나 "의도적인
          // 목적지" 가 기본이고 랜덤은 대안이라는 위계를 UI 가 반영하도록 함.
          GestureDetector(
            onTap: _selectCountry,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 14,
              ),
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
              child: Row(
                children: [
                  Text(
                    !_isRandom ? _selectedFlag : '🌍',
                    style: TextStyle(fontSize: !_isRandom ? 26 : 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          !_isRandom
                              ? CountryL10n.localizedName(
                                  _selectedCountry, langCode,
                                )
                              : l10n.selectCountry,
                          style: TextStyle(
                            color: !_isRandom
                                ? AppColors.gold
                                : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          !_isRandom
                              ? l10n.composeTapToChange
                              : l10n.composeChooseDirectly,
                          style: TextStyle(
                            color: !_isRandom
                                ? AppColors.gold.withValues(alpha: 0.75)
                                : AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: !_isRandom
                        ? AppColors.gold
                        : AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── 보조 옵션: 🎲 랜덤 + 🎯 정확한 위치 지정(Brand 전용) ────────
          Row(
            children: [
              // 랜덤 버튼 (secondary)
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
                          ? AppColors.gold.withValues(alpha: 0.14)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isRandom
                            ? AppColors.gold.withValues(alpha: 0.7)
                            : AppColors.textMuted.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '🎲',
                          style: TextStyle(
                            fontSize: _isRandom ? 17 : 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.composeRandom,
                            style: TextStyle(
                              color: _isRandom
                                  ? AppColors.gold
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Brand 전용 — 정확한 위치 지정 버튼을 나라 선택 아래 보조 옵션으로 배치.
              if (state.currentUser.isBrand) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectExactDrop,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 15)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l10n.composeExactDropToggle,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLuckyLetterButton() {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    // Build 201: 강조 노출 — 솔리드 노란 카드 + 큰 헤드라인 + 큰 아이콘.
    return GestureDetector(
      onTap: _applyLuckyLetter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1300),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isLuckyLetter
                    ? Icons.autorenew_rounded
                    : Icons.auto_awesome_rounded,
                color: AppColors.gold,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TODAY · INSPIRATION',
                    style: TextStyle(
                      color: const Color(0xFF1A1300).withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.66,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLuckyLetter
                        ? l10n.composeLuckyApplied
                        : l10n.composeLuckySend,
                    style: const TextStyle(
                      color: Color(0xFF1A1300),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isLuckyLetter
                        ? l10n.composeLuckyAppliedSub
                        : l10n.composeLuckySendSub,
                    style: TextStyle(
                      color: const Color(0xFF1A1300).withValues(alpha: 0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "이번 달의 도시" 소프트 프로모션 배너 — 탭 시 해당 국가로 목적지 변경.
  Widget _buildCityOfMonthHint(AppState state) {
    final city = CityOfMonth.forThisMonth();
    final accent = Color(city.accentColor);
    final l10n = AppL10n.of(state.currentUser.languageCode);
    // 이미 해당 국가로 설정되어 있으면 배너 숨김 (노이즈 방지)
    if (_selectedCountry == city.country) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCountry = city.country;
          _selectedFlag = city.countryFlag;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${city.themeEmoji}  ${city.cityName} · ${city.country}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: accent.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.12),
              AppColors.bgCard,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(city.themeEmoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.cityOfMonthBadge(city.month),
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${city.cityName} · ${city.country}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecallLastLetterButton() {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return GestureDetector(
      onTap: _loadLastSentLetter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Text('📝', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.composeRecallLast,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(
              Icons.history_rounded,
              color: AppColors.textMuted,
              size: 16,
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
    // 편지지 체감을 강화: 포커스 시 골드 글로우, 기본 상태도 은은한 음영.
    // 컴포즈 모달에서 본문 영역을 가장 먼저 인지하도록 시각 우선순위 부여.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _contentFocus.hasFocus
                ? AppColors.gold.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: _contentFocus.hasFocus ? 18 : 12,
            spreadRadius: _contentFocus.hasFocus ? 1 : 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: LetterPaperPainter(paper),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _contentFocus.hasFocus
                  ? AppColors.gold.withValues(alpha: 0.55)
                  : AppColors.bgSurface,
              width: _contentFocus.hasFocus ? 1.8 : 1.5,
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
              if (_charCount == 0 && !_isReply)
                _buildDailyPromptChip(paper.inkColor),
              TextField(
                controller: _contentController,
                focusNode: _contentFocus,
                minLines: 10,
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
    ),
    );
  }

  /// Build 182: 이전까진 `_buildDestinationCard` 내부에 박혀 있던 ⚡ 특송 토글을
  /// 밖으로 분리. main build() 에서 대량발송 섹션 바로 아래(프리미엄 특급배송
  /// "위"는 bulk 토글이, 그 아래가 이 express) 에 배치되도록 한다.
  Widget _buildExpressToggle(AppState state, bool hasPremium) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    if (hasPremium) {
      // Build 189.1: 특급 한도 0 일 때 토글 비활성 시각 상태 (Premium only).
      // 이전엔 토글이 켜져 보이나 탭하면 에러 뜨고 원복 — 사용자에게 이유 불명확.
      final expressExhausted = !state.currentUser.isBrand &&
          state.remainingPremiumExpressCount == 0 &&
          !_isExpressMode;
      return GestureDetector(
        onTap: () {
          final canEnable =
              state.currentUser.isBrand || state.canUsePremiumExpress;
          if (!canEnable && !_isExpressMode) {
            _showError(state.premiumExpressLimitExceededMessage);
            return;
          }
          setState(() => _isExpressMode = !_isExpressMode);
        },
        child: Opacity(
          opacity: expressExhausted ? 0.55 : 1.0,
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                color: _isExpressMode ? AppColors.gold : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              // Build 186: Premium 유저가 오늘 특급 배송을 모두 쓰면 "내일 00:00
              // 리필" 보조 라인으로 리셋 시각을 명시. 기존엔 "X/3" 만 보여서
              // "언제 리필?" 혼선.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
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
                    if (!state.currentUser.isBrand &&
                        state.remainingPremiumExpressCount == 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.composePremiumExpressResetAt,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: _isExpressMode,
                onChanged: expressExhausted
                    ? null
                    : (v) {
                        final canEnable = state.currentUser.isBrand ||
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
        ),
      );
    }
    return GestureDetector(
      onTap: () => PremiumGateSheet.show(
        context,
        featureName: '⚡ ${l10n.composeExpressDelivery}',
        featureEmoji: '⚡',
        description: l10n.composeExpressDeliveryDesc,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Text(
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
    );
  }

  // Build 182: ExactDrop 버튼은 이제 목적지 카드 내부 보조 옵션으로 이동.
  // 아래 standalone 은 향후 다른 진입점 (브랜드 캠페인 대시보드 등) 재사용을
  // 대비해 보존. 현재 compose 메인 빌드에서는 호출하지 않음.
  // ignore: unused_element
  Widget _buildExactDropButton(AppState state) {
    final l = AppL10n.of(state.currentUser.languageCode);
    return InkWell(
      onTap: _selectExactDrop,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.composeExactDropToggle,
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.composeExactDropHint,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.map_rounded,
              size: 16,
              color: AppColors.gold.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎯 오늘의 영감 통합 카드 — 요일 테마 + 퀵픽 목적지 + 월별 도시 힌트를
  /// 하나의 골드 테두리 Container 로 묶어 제공. 기존 3개 카드로 흩어져있던
  /// "어디로 쓰지?" 의사결정을 한 화면 블록 안에서 완료.
  Widget _buildInspirationCard(AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                l10n.composeInspirationHeader,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 3 요소를 하나의 카드 안에 수직 스택. 구분자는 얇은 라인 하나만.
          _buildDayThemeBanner(state),
          const Divider(
            height: 18,
            thickness: 0.6,
            color: AppColors.bgSurface,
          ),
          _buildQuickPickRow(state),
          const Divider(
            height: 18,
            thickness: 0.6,
            color: AppColors.bgSurface,
          ),
          _buildCityOfMonthHint(state),
        ],
      ),
    );
  }

  Widget _buildDayThemeBanner(AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final theme = currentDayTheme();
    final (emoji, label) = _dayThemeDisplay(theme, l10n);
    return InkWell(
      onTap: () {
        final pick = pickDayThemeCountry(
          excludeCountry: state.currentUser.country,
        ) ?? AppState.randomDestination(
          excludeCountry: state.currentUser.country,
        );
        _applyPickedDestination(pick, state.currentUser.languageCode);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dayThemeBannerTitle,
                    style: TextStyle(
                      color: AppColors.gold.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: AppColors.gold.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  (String, String) _dayThemeDisplay(DayTheme theme, AppL10n l10n) {
    switch (theme) {
      case DayTheme.eastAsia:
        return ('🏮', l10n.dayThemeEastAsia);
      case DayTheme.europe:
        return ('🏛️', l10n.dayThemeEurope);
      case DayTheme.africa:
        return ('🌍', l10n.dayThemeAfrica);
      case DayTheme.southAmerica:
        return ('🌴', l10n.dayThemeSouthAmerica);
      case DayTheme.oceania:
        return ('🌊', l10n.dayThemeOceania);
      case DayTheme.northAmerica:
        return ('🗽', l10n.dayThemeNorthAmerica);
      case DayTheme.middleEast:
        return ('🕌', l10n.dayThemeMiddleEast);
    }
  }

  // Row of 3 preset destination strategies for users who don't know where
  // to send their letter. Each chip calls a helper in compose_quick_pick.dart
  // and applies the result via _applyQuickPickResult. Falls back to plain
  // random when no candidate matches the strategy's filter.
  Widget _buildQuickPickRow(AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final chips = [
      (
        emoji: '🎲',
        label: l10n.composeQuickPickOpposite,
        onTap: () => _handleQuickPick(state, QuickPickKind.oppositeSide),
      ),
      (
        emoji: '🌅',
        label: l10n.composeQuickPickSunrise,
        onTap: () => _handleQuickPick(state, QuickPickKind.sunrise),
      ),
      (
        emoji: '🌏',
        label: l10n.composeQuickPickUnvisited,
        onTap: () => _handleQuickPick(state, QuickPickKind.unvisitedContinent),
      ),
    ];
    return Row(
      children: [
        for (int i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: chips[i].onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(chips[i].emoji,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(
                      chips[i].label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _handleQuickPick(AppState state, QuickPickKind kind) {
    final exclude = state.currentUser.country;
    final sentSet =
        state.sent.map((l) => l.destinationCountry).toSet();
    Map<String, String>? picked;
    switch (kind) {
      case QuickPickKind.oppositeSide:
        picked = pickOppositeSideCountry(
          userLng: state.currentUser.longitude,
          excludeCountry: exclude,
        );
        break;
      case QuickPickKind.sunrise:
        picked = pickSunriseCountry(excludeCountry: exclude);
        break;
      case QuickPickKind.unvisitedContinent:
        picked = pickUnvisitedContinentCountry(
          sentCountries: sentSet,
          excludeCountry: exclude,
        );
        break;
    }
    picked ??= AppState.randomDestination(excludeCountry: exclude);
    _applyPickedDestination(picked, state.currentUser.languageCode);
  }

  void _applyPickedDestination(Map<String, String> dest, String langCode) {
    final name = dest['name']!;
    final flag = dest['flag']!;
    // 캐시 주소 우선 — 없으면 cities.json → 폴백
    final geo = GeocodingService.instance;
    final cachedAddr =
        geo.isInitialized ? geo.getCachedAddress(name) : null;
    if (cachedAddr != null) {
      setState(() {
        _selectedCountry = name;
        _selectedFlag = flag;
        _selectedCity = (cachedAddr['city'] as String?) ?? '';
        _destLat = (cachedAddr['lat'] as num).toDouble();
        _destLng = (cachedAddr['lng'] as num).toDouble();
        _isRandom = true;
      });
      if (geo.cachedCountOf(name) < 3) geo.prefetch(name, count: 5);
      return;
    }
    final cityData = CountryCities.randomCity(name, languageCode: langCode);
    setState(() {
      _selectedCountry = name;
      _selectedFlag = flag;
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

  // Daily inspiration strip shown only when the body is empty and this isn't
  // a reply. Tapping inserts the prompt as a starter so the blank canvas
  // problem doesn't stall first-time writers.
  Widget _buildDailyPromptChip(Color inkColor) {
    final langCode = context.read<AppState>().currentUser.languageCode;
    final l10n = AppL10n.of(langCode);
    final prompt = composeDailyPrompt(langCode);
    return InkWell(
      onTap: () {
        final insert = '$prompt\n\n';
        _contentController.value = TextEditingValue(
          text: insert,
          selection: TextSelection.collapsed(offset: insert.length),
        );
        _contentFocus.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: inkColor.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✨', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.composeDailyPromptLabel,
                    style: TextStyle(
                      color: inkColor.withValues(alpha: 0.45),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prompt,
                    style: TextStyle(
                      color: inkColor.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_rounded,
              size: 13,
              color: inkColor.withValues(alpha: 0.35),
            ),
          ],
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
            border: Border.all(color: AppColors.bgSurface),
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
                : AppColors.bgSurface,
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
          borderSide: const BorderSide(color: AppColors.bgSurface),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bgSurface),
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
                    backgroundColor: AppColors.bgSurface,
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
                  : AppColors.bgSurface,
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

  /// Build 132: 쿠폰/교환권 유효기간 DateTime 계산.
  /// `_redemptionValidityDays` 가 null 이면 무제한 → null 반환.
  /// 그 외엔 "지금부터 N일 후 자정 23:59" 로 설정 — 유저가 발송 시각이 아닌
  /// 만료일 자정 기준으로 이해하도록 (기프트 앱 관습).
  DateTime? _computeRedemptionExpiresAt() {
    if (_brandCategory == LetterCategory.general) return null;
    final days = _redemptionValidityDays;
    if (days == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + days, 23, 59, 59);
  }

  /// Build 132: 유효기간 선택 칩 로우. coupon/voucher 카테고리일 때만 표시.
  /// [7일] [30일] [90일] [1년] [무제한] — 중앙 만료일 라벨.
  Widget _buildRedemptionValidityRow(AppL10n l10n) {
    final computed = _computeRedemptionExpiresAt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.event_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.composeBrandRedemptionValidityLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (computed != null)
              Text(
                l10n.composeBrandRedemptionExpiresOn(
                  '${computed.year}.${computed.month.toString().padLeft(2, '0')}.${computed.day.toString().padLeft(2, '0')}',
                ),
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                l10n.composeBrandRedemptionUnlimited,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _redemptionValidityChoices.map((d) {
            final selected = _redemptionValidityDays == d;
            final label = d == null
                ? l10n.composeBrandRedemptionUnlimitedChip
                : (d == 365
                    ? l10n.composeBrandRedemptionOneYear
                    : l10n.composeBrandRedemptionDays(d));
            return InkWell(
              onTap: () => setState(() => _redemptionValidityDays = d),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.teal.withValues(alpha: 0.16)
                      : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? AppColors.teal
                        : AppColors.textMuted.withValues(alpha: 0.3),
                    width: selected ? 1.3 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.teal : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build 130: 교환권 이미지 선택 row — 버튼 + 선택 시 썸네일 미리보기.
  /// 탭하면 `image_picker` 로 갤러리 열고 로컬 경로를 `_redemptionInfoController`
  /// 에 채운다. 다시 탭해서 교체 가능. 옆의 ✕ 버튼으로 제거.
  Widget _buildVoucherImagePickRow(AppL10n l10n) {
    final hasImage = _voucherImageLocalPath != null;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _pickVoucherImage,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: AppColors.teal,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasImage
                        ? l10n.composeBrandVoucherImageChange
                        : l10n.composeBrandVoucherImagePick,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasImage) ...[
          const SizedBox(width: 8),
          _VoucherImagePreview(
            path: _voucherImageLocalPath!,
            uploading: _isUploadingVoucher,
            onRemove: () {
              setState(() {
                _voucherImageLocalPath = null;
                _redemptionInfoController.clear();
                _isUploadingVoucher = false;
              });
            },
          ),
        ],
      ],
    );
  }

  /// Build 130: 교환권 이미지 갤러리 선택. 프리미엄 게이트·데일리 쿼터 불필요
  /// (이미 Brand 전용 섹션). 압축 후 로컬 경로를 `_redemptionInfoController`
  /// 에 채운다.
  /// Build 136: 압축 후 Firebase Storage 에 업로드 → HTTPS download URL 을
  /// 편지에 저장해 **다른 기기 수신자도 이미지를 볼 수 있게** 함. 업로드 실패
  /// 시 로컬 경로 fallback 유지 (오프라인·로그인 안됨 대응).
  Future<void> _pickVoucherImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (picked == null || !mounted) return;
    String finalPath = picked.path;
    try {
      final targetPath = '${picked.path}_voucher.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        quality: 80,
        minWidth: 200,
        minHeight: 200,
        keepExif: false,
      );
      if (result?.path != null) finalPath = result!.path;
    } catch (_) {
      // 압축 실패 시 원본 경로 그대로 사용.
    }
    if (!mounted) return;

    // 우선 로컬 썸네일을 바로 보여주고 "업로드 중" 상태 표시.
    setState(() {
      _voucherImageLocalPath = finalPath;
      _redemptionInfoController.text = finalPath;
      _isUploadingVoucher = true;
    });

    // Build 136: Firebase Storage 업로드 시도. 성공 시 HTTPS URL 로 교체,
    // 실패 시 로컬 경로 유지 (같은 기기 테스트는 가능).
    try {
      final uploadPath = StorageService.voucherPath(
        'voucher_${DateTime.now().millisecondsSinceEpoch}',
      );
      final url = await StorageService.uploadImage(
        file: File(finalPath),
        path: uploadPath,
      );
      if (!mounted) return;
      setState(() {
        _isUploadingVoucher = false;
        if (url != null) {
          // HTTPS URL 로 교체 — 미리보기는 여전히 로컬 경로에서 그려
          // (네트워크 왕복 생략). 발송 시점엔 redemptionInfo=URL.
          _redemptionInfoController.text = url;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isUploadingVoucher = false);
    }
  }

  /// Build 128: Free/Premium 이 🎟 할인권 / 🎁 교환권 칩을 탭했을 때 안내.
  /// Build 182: Premium 유저에게 PremiumGateSheet (Premium 업그레이드 유도) 가
  /// 뜨던 오류 수정 — Premium 은 이미 Premium 이므로 Brand 전용 안내 시트
  /// (`BrandOnlyGateSheet`) 를 띄운다. Free 는 기존 Premium 게이트 유지.
  void _showBrandOnlyCategorySheet(
    BuildContext ctx,
    AppL10n l10n,
    LetterCategory c,
  ) {
    final name = c == LetterCategory.coupon
        ? l10n.composeBrandCategoryCoupon
        : l10n.composeBrandCategoryVoucher;
    final emoji = c == LetterCategory.coupon ? '🎟' : '🎁';
    final state = ctx.read<AppState>();
    final purchase = ctx.read<PurchaseService>();
    final viewerIsPremium = state.currentUser.isPremium || purchase.isPremium;
    if (viewerIsPremium) {
      BrandOnlyGateSheet.show(
        ctx,
        featureName: name,
        featureEmoji: emoji,
        description: l10n.categoryHelpBrandOnlyNote,
        viewerIsPremium: true,
      );
    } else {
      PremiumGateSheet.show(
        ctx,
        featureName: name,
        featureEmoji: emoji,
        description: l10n.categoryHelpBrandOnlyNote,
      );
    }
  }

  /// Build 127: 편지 종류 사용법 바텀시트.
  /// 할인권 = 웹사이트에서 쓸 수 있는 코드 형식 (LETTERGO20 같은 문자열)
  /// 교환권 = 매장 등에서 실사용 가능한 쿠폰 이미지 업로드 형식
  /// 일반 = 브랜드 스토리·공지 등 자유 텍스트
  void _showCategoryHelpSheet(BuildContext ctx, AppL10n l10n) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📖', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.categoryHelpTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _helpRow(
                emoji: '🎟',
                title: l10n.composeBrandCategoryCoupon,
                body: l10n.categoryHelpCouponDesc,
              ),
              const SizedBox(height: 14),
              _helpRow(
                emoji: '🎁',
                title: l10n.composeBrandCategoryVoucher,
                body: l10n.categoryHelpVoucherDesc,
              ),
              const SizedBox(height: 14),
              _helpRow(
                emoji: '✉️',
                title: l10n.composeBrandCategoryGeneral,
                body: l10n.categoryHelpGeneralDesc,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  l10n.categoryHelpBrandOnlyNote,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpRow({
    required String emoji,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 브랜드 편지 카테고리 패널 (본문 위 STEP) ────────────────────────────
  // Build 113 에서 `_buildBrandOptions()` 의 상단 (카테고리 + 사용 방법) 을
  // 이 메서드로 분리해 ExpansionTile 밖에서 노출. 브랜드는 "무엇을 드롭할지"
  // (🎟 할인권 / 🎁 교환권 / ✉️ 일반) 를 destination 바로 아래에서 선택.
  // 쿠폰·교환권일 때만 사용 방법 입력 필드가 함께 보인다. 나머지 고급 옵션
  // (1-per-user · 답장 받기 · 자동 삭제) 은 `_buildBrandAdvancedOptions()`
  // 로 이동.
  // Build 128: Free/Premium 에게도 표시 — 쿠폰·교환권 칩은 🔒 비활성 상태로
  // "이건 Brand 가 뿌리는 편지예요" 를 가시화. 탭하면 Brand 업그레이드 안내
  // 시트 오픈.
  Widget _buildBrandCategoryPanel(AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final isBrand = state.currentUser.isBrand;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 — "어떤 편지인가요?" + Build 127 정보 아이콘(사용법 모달).
          Row(
            children: [
              const Text('🏢', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Text(
                l10n.composeBrandCategoryLabel,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _showCategoryHelpSheet(context, l10n),
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final c in LetterCategory.values) ...[
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // Build 128: 쿠폰/교환권은 Brand 전용. Free/Premium 이
                      // 탭하면 업그레이드 안내 시트를 연다. `_brandCategory`
                      // 는 바꾸지 않아 서버 guard 와 UI 상태가 일치한다.
                      if (!isBrand && c != LetterCategory.general) {
                        _showBrandOnlyCategorySheet(context, l10n, c);
                        return;
                      }
                      setState(() => _brandCategory = c);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Opacity(
                      opacity: (!isBrand && c != LetterCategory.general)
                          ? 0.55
                          : 1.0,
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _brandCategory == c && isBrand
                              ? AppColors.teal.withValues(alpha: 0.16)
                              : AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _brandCategory == c && isBrand
                                ? AppColors.teal
                                : AppColors.textMuted.withValues(alpha: 0.3),
                            width: _brandCategory == c && isBrand ? 1.3 : 1,
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              children: [
                                Text(
                                  c == LetterCategory.coupon
                                      ? '🎟'
                                      : c == LetterCategory.voucher
                                          ? '🎁'
                                          : '✉️',
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c == LetterCategory.coupon
                                      ? l10n.composeBrandCategoryCoupon
                                      : c == LetterCategory.voucher
                                          ? l10n.composeBrandCategoryVoucher
                                          : l10n.composeBrandCategoryGeneral,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _brandCategory == c && isBrand
                                        ? AppColors.teal
                                        : AppColors.textSecondary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            // Build 128: Free/Premium 에게 쿠폰·교환권 칩이
                            // Brand 전용임을 알리는 🔒 뱃지.
                            if (!isBrand && c != LetterCategory.general)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.coupon,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.bgCard,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.lock_rounded,
                                    size: 9,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          // ── 쿠폰/교환권 사용 방법 (브랜드 & 카테고리가 coupon/voucher 일 때만) ──
          if (isBrand && _brandCategory != LetterCategory.general) ...[
            const SizedBox(height: 12),
            Text(
              l10n.composeBrandRedemptionLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              // Build 127: 카테고리별 설명 · 힌트 · 아이콘 분기.
              //   할인권 → 코드 형식 설명 (예: LETTERGO20)
              //   교환권 → 쿠폰 이미지 업로드 안내
              _brandCategory == LetterCategory.coupon
                  ? l10n.composeBrandCouponDesc
                  : l10n.composeBrandVoucherDesc,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _redemptionInfoController,
              maxLength: 200,
              minLines: 1,
              maxLines: 3,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              onChanged: (_) {
                // 유저가 텍스트를 직접 타이핑하면 이미지 선택 상태 해제.
                if (_voucherImageLocalPath != null) {
                  setState(() => _voucherImageLocalPath = null);
                }
              },
              decoration: InputDecoration(
                hintText: _brandCategory == LetterCategory.coupon
                    ? l10n.composeBrandCouponHint
                    : l10n.composeBrandVoucherHint,
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
                prefixIcon: Icon(
                  _brandCategory == LetterCategory.coupon
                      ? Icons.qr_code_2_rounded
                      : Icons.image_rounded,
                  color: AppColors.teal,
                  size: 18,
                ),
                filled: true,
                fillColor: AppColors.bgSurface,
                counterStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.bgSurface),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.teal, width: 1.4),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.bgSurface),
                ),
              ),
            ),
            // Build 130: 교환권일 때 이미지 선택 버튼 + 미리보기. 선택하면 로컬
            // 경로가 `_redemptionInfoController` 에 채워진다 (URL 자리를
            // 로컬 경로가 대신함). 수신자 렌더링은 Build 131 에서 경로 vs URL
            // 을 분기해 이미지로 표시.
            // NOTE: 크로스 디바이스 동기화는 Firebase Storage 업로드 경로가
            // 필요함 — 현재 `letter.imageUrl` 패턴과 동일하게 로컬 경로만 저장.
            if (_brandCategory == LetterCategory.voucher) ...[
              const SizedBox(height: 8),
              _buildVoucherImagePickRow(l10n),
            ],
            // Build 132: 쿠폰/교환권 유효기간 선택 — Kakao Gift / Starbucks 패턴.
            // general 편지에는 의미 없음 (쿠폰이 아니니까).
            const SizedBox(height: 12),
            _buildRedemptionValidityRow(l10n),
            const SizedBox(height: 4),
            // 쿠폰/교환권 발송 시 본문 최소 20자 완화 안내.
            Text(
              l10n.composeBrandPromoBodyHint,
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 브랜드 고급 옵션 (ExpansionTile 내부) ───────────────────────────────
  Widget _buildBrandOptions(AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final expireOptions = <int?>[null, 12, 24, 48, 72];

    String expireLabel(int? hours) {
      if (hours == null) return l10n.composeBrandExpireOff;
      if (hours == 12) return l10n.composeBrandExpire12h;
      if (hours == 24) return l10n.composeBrandExpire24h;
      if (hours == 48) return l10n.composeBrandExpire2d;
      return l10n.composeBrandExpire3d;
    }

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 — "브랜드 고급 옵션"
          Row(
            children: [
              const Text('🏢', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Text(
                l10n.composeBrandOptions,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── 1 아이디당 1 편지 ──
          GestureDetector(
            onTap: () => setState(() => _brandUniquePerUser = !_brandUniquePerUser),
            child: Row(
              children: [
                Icon(
                  _brandUniquePerUser ? Icons.check_circle : Icons.circle_outlined,
                  color: _brandUniquePerUser ? AppColors.teal : AppColors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.composeBrandUniquePerUser,
                        style: TextStyle(
                          color: _brandUniquePerUser ? AppColors.teal : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.composeBrandUniquePerUserDesc,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── 답장 받기 (브랜드 전용 — 기본 on) ──
          // 이 캠페인에 답장을 받을지 발신 시점에 결정. Off 면 수신자에게
          // 답장 버튼이 숨겨지고 "답장 미수락" 안내 카드가 대신 뜬다.
          GestureDetector(
            onTap: () => setState(() => _brandAcceptsReplies = !_brandAcceptsReplies),
            child: Row(
              children: [
                Icon(
                  _brandAcceptsReplies ? Icons.check_circle : Icons.circle_outlined,
                  color: _brandAcceptsReplies ? AppColors.teal : AppColors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.composeBrandAcceptsReplies,
                        style: TextStyle(
                          color: _brandAcceptsReplies ? AppColors.teal : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.composeBrandAcceptsRepliesDesc,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── 자동 삭제 기간 ──
          Text(
            l10n.composeBrandAutoExpire,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.composeBrandAutoExpireDesc,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: expireOptions.map((h) {
              final isSelected = _brandAutoExpireHours == h;
              return GestureDetector(
                onTap: () => setState(() => _brandAutoExpireHours = h),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.teal.withValues(alpha: 0.15)
                        : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.teal.withValues(alpha: 0.6)
                          : AppColors.textMuted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    expireLabel(h),
                    style: TextStyle(
                      color: isSelected ? AppColors.teal : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── 브랜드 대량 발송 토글 ────────────────────────────────────────────────
  Widget _buildBulkModeToggle() {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    // 특송 ON이면 gold, 대량만 ON이면 orange, OFF면 기본
    final activeColor = (_isBulkMode && _isExpressMode)
        ? AppColors.gold
        : AppColors.coupon;
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
                        color: AppColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        '⚡ ${l10n.composeWithin5Min}',
                        style: TextStyle(
                          color: AppColors.gold,
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

  // ── 브랜드 특송 토글 (legacy, 미사용) ─────────────────────────────────────
  // Build 182: 새 `_buildExpressToggle(state, hasPremium)` 로 대체. 기존
  // zero-arg 구현은 dead code. 외부 reference 가 발견되지 않아 rename 으로 충돌만 해소.
  // ignore: unused_element
  Widget _buildExpressToggleLegacy() {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return GestureDetector(
      onTap: () => setState(() => _isExpressMode = !_isExpressMode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isExpressMode
              ? AppColors.gold.withValues(alpha: 0.12)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: _isExpressMode
                ? AppColors.gold.withValues(alpha: 0.6)
                : AppColors.textMuted.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.bolt_rounded,
              color: _isExpressMode
                  ? AppColors.gold
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
                      ? AppColors.gold
                      : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch(
              value: _isExpressMode,
              onChanged: (v) => setState(() => _isExpressMode = v),
              activeColor: AppColors.gold,
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
          color: AppColors.gold.withValues(alpha: 0.4),
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
                          ? AppColors.gold.withValues(alpha: 0.15)
                          : AppColors.bgDeep,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? AppColors.gold.withValues(alpha: 0.7)
                            : AppColors.textMuted.withValues(alpha: 0.15),
                        width: selected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      '$flag ${CountryL10n.localizedName(name, langCode)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: selected
                            ? AppColors.gold
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
          const SizedBox(height: 8),
          Text(
            _selectedCountry.isNotEmpty
                ? l10n.composeExpressSummary(_selectedFlag, CountryL10n.localizedName(_selectedCountry, langCode), _sendPerCountry)
                : l10n.composeSelectCountryAbove,
            style: TextStyle(
              color: _selectedCountry.isNotEmpty
                  ? AppColors.gold.withValues(alpha: 0.85)
                  : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build 189: bulk/express 모드가 켜진 상태에서 명시적 "끄기" 를 제공하는 배너.
  /// 모드를 모르고 닫아 버려서 발송 실수가 나는 걸 방지 + 되돌리기 가능.
  Widget _buildActiveModeBanner(AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final orange = AppColors.coupon;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: orange.withValues(alpha: 0.55),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Text('📦', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.composeBulkModeActive,
                style: TextStyle(
                  color: orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _isBulkMode = false;
                  _bulkTargets.clear();
                  _isExpressMode = false;
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      color: orange,
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      l10n.composeDisableMode,
                      style: TextStyle(
                        color: orange,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 브랜드 대량 발송 패널 ────────────────────────────────────────────────
  Widget _buildBulkSendPanel(AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final langCode = state.currentUser.languageCode;
    final allCountries = AppState.countries;
    // Build 201: destination 카드에서 이미 선택한 나라가 있으면 자동으로 bulk target.
    // 사용자 요청 — 대량 발송에서 나라 재선택 안 하고 몇 통 보낼지만 선택.
    if (!_isBulkRandom &&
        _bulkTargets.isEmpty &&
        _selectedCountry.isNotEmpty) {
      final match = allCountries.firstWhere(
        (c) => c['name'] == _selectedCountry,
        orElse: () => const <String, String>{},
      );
      if (match.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _bulkTargets.add({
                'country': match['name'],
                'flag': match['flag'],
                'lat': double.parse(match['lat']!),
                'lng': double.parse(match['lng']!),
              });
            });
          }
        });
      }
    }
    final panelColor = _isExpressMode
        ? AppColors.gold
        : AppColors.coupon;
    final hasFixedTarget = !_isBulkRandom && _selectedCountry.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: panelColor.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 나라당 발송 수
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                _isExpressMode
                    ? '⚡ ${l10n.composeSendPerCountry}'
                    : '📮 ${l10n.composeSendPerCountry}',
                style: TextStyle(
                  color: _isExpressMode
                      ? AppColors.gold
                      : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  if (_sendPerCountry > 1) _sendPerCountry--;
                }),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.bgDeep,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: _isExpressMode
                          ? AppColors.gold.withValues(alpha: 0.3)
                          : AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 14,
                    color: _isExpressMode
                        ? AppColors.gold
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  l10n.composeCountUnit(_sendPerCountry),
                  style: TextStyle(
                    color: _isExpressMode
                        ? AppColors.gold
                        : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  if (_sendPerCountry < 50) _sendPerCountry++;
                }),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.bgDeep,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: _isExpressMode
                          ? AppColors.gold.withValues(alpha: 0.3)
                          : AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 14,
                    color: _isExpressMode
                        ? AppColors.gold
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 랜덤 국가 토글
          GestureDetector(
            onTap: () => setState(() {
              _isBulkRandom = !_isBulkRandom;
              if (_isBulkRandom) _bulkTargets.clear();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _isBulkRandom
                    ? AppColors.streak.withValues(alpha: 0.12)
                    : AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isBulkRandom
                      ? AppColors.streak.withValues(alpha: 0.6)
                      : AppColors.textMuted.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Text('🎲', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.composeBulkRandomCountry,
                          style: TextStyle(
                            color: _isBulkRandom
                                ? AppColors.streak
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_isBulkRandom)
                          Text(
                            l10n.composeBulkRandomDesc,
                            style: const TextStyle(
                              color: AppColors.streak,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isBulkRandom,
                    onChanged: (v) => setState(() {
                      _isBulkRandom = v;
                      if (v) _bulkTargets.clear();
                    }),
                    activeColor: AppColors.streak,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          ),
          // Build 201: destination 카드에서 이미 선택한 나라가 자동으로
          // bulk target. 따라서 나라 그리드 제거. 단 hasFixedTarget=false
          // (나라 선택 안 됨 + 랜덤 모드도 아님) 일 때만 안내 메시지 표시.
          if (hasFixedTarget) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.gps_fixed_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      CountryL10n.localizedName(_selectedCountry, langCode),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Text(
                    l10n.composeCountUnit(_sendPerCountry),
                    style: TextStyle(
                      color: panelColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!_isBulkRandom) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.composeSelectTargetCountry,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          // 총 발송 요약
          if (_isBulkRandom)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.streak.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '🎲 ${l10n.composeBulkRandomSummary(_sendPerCountry)}',
                style: const TextStyle(
                  color: AppColors.streak,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (_bulkTargets.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isExpressMode
                    ? AppColors.gold.withValues(alpha: 0.08)
                    : AppColors.coupon.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isExpressMode
                        ? l10n.composeBulkExpressSummary(_bulkTargets.length * _sendPerCountry, _bulkTargets.length, _sendPerCountry)
                        : l10n.composeBulkSendSummary(_bulkTargets.length * _sendPerCountry, _bulkTargets.length, _sendPerCountry),
                    style: TextStyle(
                      color: _isExpressMode
                          ? AppColors.gold
                          : AppColors.coupon,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_isExpressMode) ...[
                    const SizedBox(height: 2),
                    Text(
                      '⏱ ${l10n.composeDeliveryIn5Min}',
                      style: const TextStyle(color: AppColors.gold, fontSize: 10),
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
    final _lc = context.read<AppState>().currentUser.languageCode;
    final l10n = AppL10n.of(_lc);
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
                      paper.localizedName(_lc),
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
                      font.localizedName(_lc),
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
            AppColors.map,
          ];
          final tabLabel = ['🛣️ ${l10n.composeLand}', '✈️ ${l10n.composeAir}', '🌊 ${l10n.composeSea}'];
          final selectedInTab = _categoryEmojis[tabIndex];

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.bgDeep,
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
                            ? AppColors.bgDeep
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
    final _plc = context.read<AppState>().currentUser.languageCode;
    final l10n = AppL10n.of(_plc);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgDeep,
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
                            p.localizedName(_plc),
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
                  border: Border.all(color: AppColors.bgSurface),
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
    final _flc = context.read<AppState>().currentUser.languageCode;
    final l10n = AppL10n.of(_flc);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgDeep,
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
                          : AppColors.bgSurface,
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
                              f.localizedName(_flc),
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
                border: Border.all(color: AppColors.bgSurface),
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
                  : AppColors.coupon,
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

/// Build 130: 교환권 이미지 미리보기 썸네일. 로컬 경로에서 File 로드.
/// 우상단 ✕ 버튼으로 선택 해제.
class _VoucherImagePreview extends StatelessWidget {
  final String path;
  final bool uploading;
  final VoidCallback onRemove;
  const _VoucherImagePreview({
    required this.path,
    required this.onRemove,
    this.uploading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 44,
              height: 44,
              color: AppColors.bgSurface,
              child: const Icon(
                Icons.broken_image_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
        // Build 136: 업로드 중 오버레이 — 썸네일 위에 반투명 + 작은 스피너.
        if (uploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.teal, width: 1.2),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 11,
                color: AppColors.teal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 부가 옵션 섹션 (접이식) ──────────────────────────────────────────────────
// Compose 모달에서 편지 본문 아래에 두는 보조 옵션(테마·퀵픽·SNS·익명·스타일·
// 이미지·운세·최근·4월의 도시) 을 하나의 ExpansionTile 로 묶는다. 기본은 접힘
// 상태로 보이므로 사용자는 "목적지 → 본문 → 보내기" 기본 플로우만 인지하면
// 된다. 옵션이 필요한 사용자는 한 번만 펼치면 전부 볼 수 있다.
class _ComposeOptionsSection extends StatefulWidget {
  final String title;
  final List<Widget> children;

  const _ComposeOptionsSection({required this.title, required this.children});

  @override
  State<_ComposeOptionsSection> createState() => _ComposeOptionsSectionState();
}

class _ComposeOptionsSectionState extends State<_ComposeOptionsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (탭하면 펼침/접힘 토글)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Text('⚙️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _expanded ? 0.5 : 0,
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 컨텐츠 (펼쳐진 상태에서만 렌더)
          if (_expanded) ...[
            Container(
              height: 1,
              color: AppColors.bgSurface,
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
