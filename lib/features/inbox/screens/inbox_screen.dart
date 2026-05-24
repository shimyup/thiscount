import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/person_emoji.dart';
import '../../../core/services/recommendation_service.dart';
import '../../../models/letter.dart';
import '../../../models/direct_message.dart';
import '../../../state/app_state.dart';
import '../widgets/letter_read_screen.dart';
import '../../map/screens/letter_detail_map_screen.dart';
import '../../dm/dm_conversation_screen.dart';
import '../../merchant/merchant_interest_sheet.dart';
import '../../premium/premium_gate_sheet.dart';

// 포지셔닝 변경 + Build 183 에서 brand 제거, general 추가.
//   all · general · coupon · voucher
// 배송 상태(read/inTransit/waitingPickup) 는 각 편지 카드의 뱃지에서 확인.
// 필터는 "편지의 종류"만 다룸. 기존 enum 값은 유지 (코드베이스 호환성),
// 필터 바의 표시 목록에서만 빠진다.
enum LetterFilterType {
  all,
  read,
  inTransit,
  waitingPickup,
  brand,
  coupon,
  voucher,
  general,
  // Build 264: 카테고리 필터 (heuristic content keyword matching).
  // 사용자가 "오늘 음식점 쿠폰만 보고 싶다" 같은 빠른 탐색용. 사용자 보이는
  // 명칭은 "카테고리" (Build 315 — 이전 "산업군" 에서 명칭 변경).
  // Build 315: 7개 카테고리로 확장 — 식당/카페/뷰티/패션/IT/행사/기타.
  food,
  cafe,
  beauty,
  fashion,
  it,
  event,
  other,
  // Build 324 (positioning): 카테고리 단순화 — 7개 → 3개 그룹.
  //   eat = food + cafe / shop = beauty + fashion / etc = it + event + other.
  //   데이터 categoryTag 는 7-way 그대로 유지 (호환성), UI 필터만 통합.
  eat,
  shop,
  etc,
}

/// 필터 바에 노출되는 타입.
/// Build 264: 식음/카페/뷰티/패션 4개 산업 필터 추가 (PPT quick win FILTER).
/// Build 271: 메인 필터(편지 종류) 와 산업군 필터(키워드 매칭) 를 분리.
/// BottomSheet 에서 섹션 헤더로 구분해 인지 부하 감소.
const List<LetterFilterType> _mainFilters = [
  LetterFilterType.all,
  LetterFilterType.general,
  LetterFilterType.coupon,
  LetterFilterType.voucher,
];

// Build 315: 7개 카테고리 (식당/카페/뷰티/패션/IT/행사/기타).
// Build 324 (positioning): UI 노출은 3개 그룹으로 단순화. 7개 칩 가로 스크롤
//   선택 마비 해소 — 먹기 / 쇼핑 / 기타 한눈에. 데이터 categoryTag (7-way)
//   는 인박스 그룹 헤더 / 추천 알고리즘 등에서 그대로 활용.
const List<LetterFilterType> _industryFilters = [
  LetterFilterType.eat,
  LetterFilterType.shop,
  LetterFilterType.etc,
];

/// Build 324: 3개 그룹 → 7-way categoryTag 의 mapping. _applyFilter 의
/// _matchesIndustry 에서 사용. group=eat 면 categoryTag in {food, cafe}.
const Map<LetterFilterType, Set<String>> _groupToCategoryTags = {
  LetterFilterType.eat: {'food', 'cafe'},
  LetterFilterType.shop: {'beauty', 'fashion'},
  LetterFilterType.etc: {'it', 'event', 'other'},
};

const List<LetterFilterType> _visibleFilters = [
  ..._mainFilters,
  ..._industryFilters,
];

/// Build 264: 산업군 키워드 사전. letter.content + senderName + redemptionInfo
/// 안에 키워드 하나라도 있으면 그 산업군에 해당.
const Map<LetterFilterType, List<String>> _industryKeywords = {
  LetterFilterType.food: [
    '음식',
    '맛집',
    '식당',
    '레스토랑',
    '한식',
    '중식',
    '일식',
    '양식',
    '치킨',
    '피자',
    '버거',
    '파스타',
    '마라',
    '고기',
    '회',
    '초밥',
    '라면',
    '분식',
    '국밥',
    '찌개',
    '국수',
    '면',
    '도시락',
    '런치',
    '디너',
    '야식',
    '스테이크',
    '정식',
    '백반',
    '음식점',
    '분식점',
    '뷔페',
    '뷔페식',
    'food',
    'restaurant',
    'dish',
    'meal',
    'lunch',
    'dinner',
    'snack',
    'burger',
    'pizza',
    'pasta',
    'ramen',
    'sushi',
    'bbq',
    'steak',
    'dining',
    'cuisine',
    'eatery',
  ],
  LetterFilterType.cafe: [
    '카페',
    '커피',
    '라떼',
    '에스프레소',
    '아메리카노',
    '디저트',
    '케이크',
    '와플',
    '베이커리',
    '빵',
    '도넛',
    '마카롱',
    '스무디',
    '주스',
    '에이드',
    '녹차',
    '홍차',
    '허브티',
    '브런치',
    'cafe',
    'coffee',
    'latte',
    'cappuccino',
    'espresso',
    'americano',
    'dessert',
    'bakery',
    'donut',
    'macaron',
    'smoothie',
    'juice',
    'tea',
    'brunch',
  ],
  LetterFilterType.beauty: [
    '뷰티',
    '화장품',
    '미용',
    '헤어',
    '네일',
    '마사지',
    '에스테틱',
    '왁싱',
    '피부',
    '스킨',
    '메이크업',
    '립스틱',
    '마스크팩',
    '선크림',
    '토너',
    '에센스',
    '샴푸',
    '린스',
    '트리트먼트',
    '향수',
    '퍼퓸',
    '퍼머',
    '염색',
    '스파',
    'beauty',
    'cosmetic',
    'salon',
    'hair',
    'nail',
    'spa',
    'massage',
    'skin',
    'makeup',
    'lipstick',
    'cushion',
    'mask',
    'serum',
    'shampoo',
    'perfume',
  ],
  LetterFilterType.fashion: [
    '패션',
    '옷',
    '의류',
    '신발',
    '가방',
    '액세서리',
    '쥬얼리',
    '주얼리',
    '모자',
    '양말',
    '티셔츠',
    '셔츠',
    '원피스',
    '스커트',
    '바지',
    '청바지',
    '코트',
    '재킷',
    '후드',
    '맨투맨',
    '운동화',
    '구두',
    '샌들',
    '부츠',
    '벨트',
    '스카프',
    '선글라스',
    '시계',
    'fashion',
    'clothing',
    'clothes',
    'shoes',
    'bag',
    'accessory',
    'jewelry',
    'hat',
    'tshirt',
    'shirt',
    'dress',
    'skirt',
    'pants',
    'jeans',
    'coat',
    'jacket',
    'hoodie',
    'sneakers',
    'heels',
    'boots',
    'watch',
  ],
  // Build 315: IT/기술 카테고리 — SaaS / 앱 / 디바이스 / 컴퓨터 관련
  LetterFilterType.it: [
    'IT', 'it서비스', '앱', '소프트웨어', 'SaaS', '구독서비스',
    '컴퓨터', '노트북', '맥북', '데스크탑', '스마트폰', '핸드폰',
    '갤럭시', '아이폰', '아이패드', '태블릿', '이어폰', '에어팟',
    '키보드', '마우스', '모니터', '게임', '구글', '애플', '마이크로소프트',
    '클라우드', 'AI', '인공지능', '챗GPT', '데이터',
    'app', 'software', 'saas', 'subscription', 'tech', 'technology',
    'laptop', 'macbook', 'desktop', 'smartphone', 'phone', 'tablet',
    'ipad', 'iphone', 'galaxy', 'airpods', 'keyboard', 'mouse',
    'monitor', 'cloud', 'gaming', 'computer',
  ],
  // Build 315: 행사/이벤트 카테고리 — 공연 / 전시 / 페스티벌 / 컨퍼런스
  LetterFilterType.event: [
    '행사', '이벤트', '공연', '콘서트', '뮤지컬', '연극',
    '전시', '전시회', '박람회', '페스티벌', '축제', '팝업',
    '팝업스토어', '워크샵', '워크숍', '세미나', '컨퍼런스', '강연',
    '클래스', '체험', '체험학습', '관람', '티켓', '입장권',
    'event', 'concert', 'festival', 'exhibition', 'expo',
    'show', 'popup', 'workshop', 'seminar', 'conference',
    'class', 'ticket', 'admission', 'performance',
  ],
  // Build 315: 기타 — 위 카테고리 명시 매칭 안 되면 fallback 으로 처리
  // (heuristic 만으로는 비어있음; 키워드 매칭 안 되는 letter 는 자동으로 기타).
  LetterFilterType.other: [],
};

/// 영문 키워드는 단어 경계(`\b`) 로 매칭해 거짓양성 (예: "art" → "start") 방지.
/// 한글 키워드는 부분 문자열 매칭 그대로 유지 (한글에는 단어 경계 의미 없음).
///
/// Build 315: letter.categoryTag 가 있으면 그것을 우선 사용 (픽업 시 명시 저장
/// 된 카테고리). 없으면 키워드 heuristic. "other" 는 다른 카테고리 매칭 안 됐을
/// 때 fallback.
bool _matchesIndustry(LetterFilterType industry, dynamic letter) {
  // Build 324: 새 3-그룹 (eat/shop/etc) 필터 — 7-way categoryTag mapping.
  //   eat = food + cafe / shop = beauty + fashion / etc = it + event + other.
  final groupTags = _groupToCategoryTags[industry];
  if (groupTags != null) {
    final saved = (letter.categoryTag as String?)?.toLowerCase();
    if (saved != null && saved.isNotEmpty) {
      return groupTags.contains(saved);
    }
    // categoryTag 없으면 키워드 추론으로 그룹 7-way 매칭 일부라도 trigger.
    for (final tag in groupTags) {
      final subFilter = _filterTypeFromName(tag);
      if (subFilter != null && _matchesIndustry(subFilter, letter)) return true;
    }
    return false;
  }

  // 1) Letter 의 명시적 categoryTag 우선
  final saved = (letter.categoryTag as String?)?.toLowerCase();
  if (saved != null && saved.isNotEmpty) {
    return saved == industry.name.toLowerCase();
  }

  // 2) "other" 는 다른 4개 산업 카테고리 매칭 안 됐을 때만 true
  if (industry == LetterFilterType.other) {
    for (final cat in const [
      LetterFilterType.food,
      LetterFilterType.cafe,
      LetterFilterType.beauty,
      LetterFilterType.fashion,
      LetterFilterType.it,
      LetterFilterType.event,
    ]) {
      if (_matchesIndustry(cat, letter)) return false;
    }
    return true;
  }

  // 3) 키워드 매칭
  final kws = _industryKeywords[industry];
  if (kws == null || kws.isEmpty) return false;
  final hay =
      ('${letter.content ?? ''} ${letter.senderName ?? ''} ${letter.redemptionInfo ?? ''}')
          .toLowerCase();
  for (final k in kws) {
    final lower = k.toLowerCase();
    final isAscii = lower.runes.every((r) => r < 0x80);
    if (isAscii) {
      // 영문: 단어 경계 매칭
      final pattern = RegExp(r'\b' + RegExp.escape(lower) + r'\b');
      if (pattern.hasMatch(hay)) return true;
    } else {
      // 한글/유니코드: 부분 문자열 그대로
      if (hay.contains(lower)) return true;
    }
  }
  return false;
}

// Build 324: name 문자열 → LetterFilterType 역매핑 (그룹 → 7-way 추론용).
LetterFilterType? _filterTypeFromName(String name) {
  for (final f in LetterFilterType.values) {
    if (f.name == name) return f;
  }
  return null;
}

/// Build 324 (Q2): letter content + redemptionInfo 에서 "혜택 강도" 텍스트
///   추출 — 카드 leading 영역의 big text 용. 사용자가 0.5초에 "얼마 이득"
///   인지 → 픽업/사용 결정 가속.
///
/// 패턴 우선순위:
///   1. `(\d+)%` — 퍼센트 할인 (예: "30%" — 가장 흔한 패턴)
///   2. `1\+1` — 1+1 / 2+1
///   3. `-?\d[\d,]*원` — 원 단위 (예: "3,000원 할인")
///   4. `무료` — 무료 라벨
///   5. fallback — null (호출 측이 이모지 사용)
String? _extractBenefitBigText(Letter letter) {
  final hay = '${letter.content} ${letter.redemptionInfo ?? ''}';
  // 1) 퍼센트
  final pct = RegExp(r'(\d{1,2})\s*%').firstMatch(hay);
  if (pct != null) {
    final n = int.tryParse(pct.group(1) ?? '');
    if (n != null && n > 0 && n <= 99) return '$n%';
  }
  // 2) 1+1 / 2+1
  final plus = RegExp(r'([123])\s*\+\s*([123])').firstMatch(hay);
  if (plus != null) return '${plus.group(1)}+${plus.group(2)}';
  // 3) N원 (할인)
  final won = RegExp(r'(\d[\d,]+)\s*원').firstMatch(hay);
  if (won != null) {
    final raw = won.group(1)!.replaceAll(',', '');
    final n = int.tryParse(raw);
    if (n != null && n >= 1000) {
      // 1k 단위로 줄임: 3000 → 3K
      if (n >= 10000) return '${(n / 1000).round()}K';
      return '${(n / 1000).toStringAsFixed(0)}K';
    }
  }
  // 4) 무료 / FREE
  if (RegExp(r'무료|FREE|free').hasMatch(hay)) return 'FREE';
  return null;
}

/// Build 324: AI 추천 모드 letter 카드 칩용 — RecommendationService.topReason
///   결과를 i18n 라벨 + emoji 조합 문자열로 반환. null 이면 칩 미노출.
/// Build 325 (T2): top 외 추가 매칭 신호 수도 함께 반환 (다신호 letter 가시화).
({String text, int extra})? _resolveAiReasonChip(BuildContext ctx, Letter letter) {
  final state = ctx.read<AppState>();
  final reason = RecommendationService.topReason(
    letter,
    state.currentUser,
    followedBrandIds: state.followedBrandIds,
  );
  if (reason == null) return null;
  final l10n = AppL10n.of(state.currentUser.languageCode);
  final extra = RecommendationService.extraSignalCount(
    letter,
    state.currentUser,
    followedBrandIds: state.followedBrandIds,
  );
  return (
    text: '${reason.emoji} ${l10n.aiReasonLabel(reason.labelKey)}',
    extra: extra,
  );
}

// Build 315: 카테고리 추론은 `lib/features/inbox/utils/category_inference.dart` 의
// inferCategoryTagFromText 사용 (app_state pickUpLetter 와 공유).

// 필터별 empty state 이모지. 수집첩이 비었을 때 어떤 종류의 편지를 찾고
// 있었는지 시각적으로 힌트를 준다. (예: 할인권 필터에서 비면 🎟)
String _emptyEmojiForFilter(LetterFilterType f) {
  switch (f) {
    case LetterFilterType.coupon:
      return '🎟';
    case LetterFilterType.voucher:
      return '🎁';
    case LetterFilterType.brand:
      return '🏢';
    case LetterFilterType.general:
      return '✉️';
    case LetterFilterType.read:
      return '📖';
    case LetterFilterType.inTransit:
      return '✈️';
    case LetterFilterType.waitingPickup:
      return '📬';
    case LetterFilterType.all:
      return '📭';
    // Build 315: 7개 카테고리 — 알아보기 쉬운 직관 이모지로 통일.
    case LetterFilterType.food:
      return '🍽️'; // 식당
    case LetterFilterType.cafe:
      return '☕'; // 카페
    case LetterFilterType.beauty:
      return '💄'; // 뷰티
    case LetterFilterType.fashion:
      return '👗'; // 패션
    case LetterFilterType.it:
      return '💻'; // IT
    case LetterFilterType.event:
      return '🎉'; // 행사
    case LetterFilterType.other:
      return '📌'; // 기타
    // Build 324: 3-그룹 단순화
    case LetterFilterType.eat:
      return '🍴';
    case LetterFilterType.shop:
      return '🛍️';
    case LetterFilterType.etc:
      return '🎁';
  }
}

// 필터가 "헌트 모드"인지 판정. 할인권 · 교환권 · 브랜드 편지는 유저가
// 지도에서 주워야 얻는 것이므로 빈 상태 CTA를 "편지 쓰기"가 아닌
// "지도에서 찾기"로 바꾼다.
bool _isHuntFilter(LetterFilterType f) {
  return f == LetterFilterType.coupon ||
      f == LetterFilterType.voucher ||
      f == LetterFilterType.brand;
}

// 필터별 이름. inboxEmptyForFilter() 에 전달해 "아직 받은 할인권이 없어요"
// 식으로 쓰인다. 사용자가 어떤 필터를 켜놨는지 empty state 제목에서 즉시 인지.
String _filterName(LetterFilterType f, AppL10n l10n) {
  switch (f) {
    case LetterFilterType.coupon:
      return l10n.inboxFilterCoupon;
    case LetterFilterType.voucher:
      return l10n.inboxFilterVoucher;
    case LetterFilterType.brand:
      return l10n.inboxFilterBrand;
    case LetterFilterType.general:
      return l10n.inboxFilterGeneral;
    case LetterFilterType.read:
      return l10n.inboxRead;
    case LetterFilterType.inTransit:
      return l10n.inboxFilterInTransit;
    case LetterFilterType.waitingPickup:
      return l10n.inboxFilterWaiting;
    case LetterFilterType.all:
      return l10n.inboxFilterAll;
    case LetterFilterType.food:
      return l10n.inboxFilterFood;
    case LetterFilterType.cafe:
      return l10n.inboxFilterCafe;
    case LetterFilterType.beauty:
      return l10n.inboxFilterBeauty;
    case LetterFilterType.fashion:
      return l10n.inboxFilterFashion;
    // Build 315: 새 3개 카테고리
    case LetterFilterType.it:
      return l10n.inboxFilterIt;
    case LetterFilterType.event:
      return l10n.inboxFilterEvent;
    case LetterFilterType.other:
      return l10n.inboxFilterOther;
    // Build 324: 3-그룹 단순화
    case LetterFilterType.eat:
      return l10n.inboxFilterEat;
    case LetterFilterType.shop:
      return l10n.inboxFilterShop;
    case LetterFilterType.etc:
      return l10n.inboxFilterEtc;
  }
}

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

// Build 295: 수집첩 정렬 모드. 사용자 요청 — 유효기간 / 최신 / 중요도.
// Build 324: AI 추천 정렬 모드 추가 (Premium 전용). 카테고리 선호 / 만료 임박 /
// 사회 신호 / 거리 / 팔로우 브랜드 등 다신호 heuristic 으로 score 산출.
enum InboxSortMode { latest, expiry, importance, aiRecommend }

class _InboxScreenState extends State<InboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _inboxScrollController = ScrollController();
  LetterFilterType _inboxFilter = LetterFilterType.all;
  LetterFilterType _sentFilter = LetterFilterType.all;
  // Build 295: 사용자 선택 정렬 모드. default = 최신순 (기존 동작).
  InboxSortMode _sortMode = InboxSortMode.latest;
  String _searchQuery = '';
  bool _searchMode = false;
  final TextEditingController _searchController = TextEditingController();

  AppL10n _l10n(BuildContext context) =>
      AppL10n.of(context.read<AppState>().currentUser.languageCode);

  List<Letter> _applySearch(List<Letter> letters) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return letters;
    return letters.where((l) {
      if (l.content.toLowerCase().contains(q)) return true;
      if (l.senderName.toLowerCase().contains(q)) return true;
      if (l.senderCountry.toLowerCase().contains(q)) return true;
      if (l.senderCountryFlag.contains(q)) return true;
      if ((l.redemptionInfo ?? '').toLowerCase().contains(q)) return true;
      // 별칭 검색 (CountryL10n: 14개 언어 전체 매칭)
      if (CountryL10n.matchesSearch(l.senderCountry, q)) return true;
      return false;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Build 217: Brand 는 [보낸/받은] 순서로 탭 자체가 재배치되어 0번이 이미
    // sent. 별도 자동 전환 불필요.
    _tabController = TabController(length: 2, vsync: this);
    // Build 271: 푸시 알림 deep link 로 진입 시 해당 편지 자동 오픈.
    // main.dart 의 onNotificationTap 에서 AppState.pendingDeepLinkLetterId 를
    // 채우고 인박스로 이동 → 첫 프레임 후 1회 소비.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _consumePendingDeepLink();
    });
  }

  void _consumePendingDeepLink() {
    final state = context.read<AppState>();
    final id = state.pendingDeepLinkLetterId;
    if (id == null || id.isEmpty) return;
    state.pendingDeepLinkLetterId = null; // 1회 소비
    // 인박스 + worldLetters 통합 검색
    Letter? letter;
    for (final l in state.inbox) {
      if (l.id == id) {
        letter = l;
        break;
      }
    }
    if (letter == null) {
      for (final l in state.worldLetters) {
        if (l.id == id) {
          letter = l;
          break;
        }
      }
    }
    if (letter == null) return;
    _openLetter(context, letter, state);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inboxScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToFirstUnread(List<Letter> letters) {
    final unreadIdx = letters.indexWhere(
      (l) => l.status == DeliveryStatus.delivered,
    );
    if (unreadIdx < 0) return;
    // Build 205.1: 필터=전체 일 때는 카테고리별 그룹 헤더가 사이에 끼어 들어가
    // 단순히 letterIdx × itemH 로 오프셋을 계산하면 헤더 만큼 어긋난다.
    // 이전 카테고리에 속한 letter 개수 + 헤더 1개씩을 더해 실제 row 위치 계산.
    const double filterBarH = 56.0;
    const double itemH = 110.0;
    const double headerH = 36.0; // _CategorySectionHeader 의 vertical 합계 근사
    final unreadLetter = letters[unreadIdx];
    int rowIdx = 0;
    if (_inboxFilter == LetterFilterType.all) {
      // 일반 → 할인권 → 교환권 순서대로 헤더 + 그룹 letters 누적.
      final order = [
        LetterCategory.general,
        LetterCategory.coupon,
        LetterCategory.voucher,
      ];
      for (final cat in order) {
        final group = letters.where((l) => l.category == cat).toList();
        if (group.isEmpty) continue;
        rowIdx += 1; // header
        if (cat == unreadLetter.category) {
          rowIdx += group.indexOf(unreadLetter);
          break;
        } else {
          rowIdx += group.length;
        }
      }
    } else {
      rowIdx = unreadIdx;
    }
    final isAll = _inboxFilter == LetterFilterType.all;
    final headerCount = isAll
        ? letters.map((l) => l.category).toSet().take(3).length
        : 0;
    // 더 정확한 추정: 위에서 누적한 rowIdx 를 row 별 평균 높이로 환산.
    // 헤더 ≪ letter card 라 letter idx 기준 + headers 보정으로 충분.
    final precedingHeaders = isAll
        ? rowIdx -
              unreadIdx // 누적 row - 누적 letter (= 앞쪽 헤더 수)
        : 0;
    final double target =
        filterBarH +
        unreadIdx * itemH +
        precedingHeaders.clamp(0, headerCount) * headerH;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_inboxScrollController.hasClients) {
        _inboxScrollController.animateTo(
          target.clamp(0.0, _inboxScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  List<Letter> _applyFilter(
    List<Letter> letters, {
    required LetterFilterType filter,
    required bool isInbox,
  }) {
    // 검색어가 있으면 먼저 검색 필터 적용
    final searched = _applySearch(letters);
    if (filter == LetterFilterType.all) return searched;
    return searched.where((letter) {
      switch (filter) {
        case LetterFilterType.read:
          return isInbox
              ? letter.status == DeliveryStatus.read
              : (letter.status == DeliveryStatus.read ||
                    letter.isReadByRecipient);
        case LetterFilterType.inTransit:
          return letter.status == DeliveryStatus.inTransit ||
              letter.status == DeliveryStatus.nearYou;
        case LetterFilterType.waitingPickup:
          return letter.status == DeliveryStatus.deliveredFar;
        case LetterFilterType.brand:
          return letter.senderIsBrand ||
              letter.letterType == LetterType.brandExpress;
        case LetterFilterType.coupon:
          return letter.category == LetterCategory.coupon;
        case LetterFilterType.voucher:
          return letter.category == LetterCategory.voucher;
        case LetterFilterType.general:
          // Build 183: 일반 = 브랜드 발신 여부와 무관하게 category 가 general.
          return letter.category == LetterCategory.general;
        case LetterFilterType.food:
        case LetterFilterType.cafe:
        case LetterFilterType.beauty:
        case LetterFilterType.fashion:
        case LetterFilterType.it:
        case LetterFilterType.event:
        case LetterFilterType.other:
          // Build 315: 카테고리 필터 — categoryTag 우선, keyword fallback.
          return _matchesIndustry(filter, letter);
        // Build 324: 3-그룹 단순화 (eat/shop/etc) — _matchesIndustry 가 자동
        //   으로 _groupToCategoryTags 매핑으로 dispatch.
        case LetterFilterType.eat:
        case LetterFilterType.shop:
        case LetterFilterType.etc:
          return _matchesIndustry(filter, letter);
        case LetterFilterType.all:
          return true;
      }
    }).toList();
  }

  // Build 290 (P1): inbox/sent letter 를 도착(또는 발송) 시각 DESC 로 정렬.
  // 이전엔 `.reversed.toList()` 만 사용 → 원본 list 가 ASC 정렬됐다는 전제
  // 가 깨지면 무작위 순서. arrivedAt 이 null 이면 sentAt 으로 fallback.
  // Build 295: 정렬 모드 분기. _sortMode 기반.
  // Build 324: aiRecommend 모드 — RecommendationService 로 score 산출 후 DESC.
  //   currentUser / followedBrandIds 가 필요해 AppState 인자를 받도록 확장.
  //   Free 사용자가 aiRecommend 선택 시 호출 측에서 PremiumGateSheet 노출 후
  //   latest 로 fallback — 이 메서드는 가드 없이 그대로 score 함수만 호출.
  //   isInbox=false (Sent 탭) 면 aiRecommend 는 받은 letter 신호 (followed brand /
  //   preferredCategory / 미사용 등) 가 의미 없으므로 latest 로 자동 fallback.
  List<Letter> _sortByArrivedDesc(
    AppState state,
    List<Letter> letters, {
    bool isInbox = true,
  }) {
    final sorted = List<Letter>.from(letters);
    final effectiveMode = (!isInbox && _sortMode == InboxSortMode.aiRecommend)
        ? InboxSortMode.latest
        : _sortMode;
    switch (effectiveMode) {
      case InboxSortMode.latest:
        // Build 324 (audit fix): 만료된 letter 는 정렬 후 자동 하단.
        //   3개월 묵은 인박스 복귀 시 만료 letter 가 상단 점령해 "다 지난 거잖아"
        //   좌절하던 버그 (복귀 사용자 시뮬레이션). 사용/만료 letter 는
        //   chronological 우선순위를 잃고 별도 그룹으로 하단 배치.
        sorted.sort((a, b) {
          final aExpired = a.isExpired || a.isRedemptionExpired ||
              a.redeemedAt != null;
          final bExpired = b.isExpired || b.isRedemptionExpired ||
              b.redeemedAt != null;
          if (aExpired != bExpired) {
            return aExpired ? 1 : -1; // expired → 하단
          }
          final ta = a.arrivedAt ?? a.sentAt;
          final tb = b.arrivedAt ?? b.sentAt;
          final cmp = tb.compareTo(ta); // DESC: 최신 먼저
          // Build 352 (PR-V3 시뮬레이션 P1): tied timestamp tiebreaker —
          //   같은 ms 에 도착한 letter 의 sort 순서가 매 호출마다 바뀌어 UI
          //   flicker. letter.id 사전순으로 stable.
          if (cmp != 0) return cmp;
          return a.id.compareTo(b.id);
        });
        break;
      case InboxSortMode.expiry:
        // 만료 임박 먼저. expiresAt null → 맨 뒤로.
        sorted.sort((a, b) {
          final ea = a.expiresAt;
          final eb = b.expiresAt;
          if (ea == null && eb == null) return a.id.compareTo(b.id);
          if (ea == null) return 1;
          if (eb == null) return -1;
          final cmp = ea.compareTo(eb); // ASC: 빨리 만료되는 것 먼저
          if (cmp != 0) return cmp;
          return a.id.compareTo(b.id);
        });
        break;
      case InboxSortMode.importance:
        // 중요도 가중치: Brand=4, Coupon=3, Voucher=3, Followed=2, Unread=1
        int weight(Letter l) {
          int w = 0;
          if (l.senderIsBrand) w += 4;
          final cat = l.category.key;
          if (cat == 'coupon' || cat == 'voucher') w += 3;
          if (!l.isReadByRecipient) w += 1;
          return w;
        }
        sorted.sort((a, b) {
          final wa = weight(a);
          final wb = weight(b);
          if (wa != wb) return wb.compareTo(wa); // 가중치 DESC
          final ta = a.arrivedAt ?? a.sentAt;
          final tb = b.arrivedAt ?? b.sentAt;
          final cmp = tb.compareTo(ta); // tiebreaker = 최신
          if (cmp != 0) return cmp;
          // Build 352 (PR-V3): final tiebreaker — letter.id 사전순 stable.
          return a.id.compareTo(b.id);
        });
        break;
      case InboxSortMode.aiRecommend:
        return RecommendationService.rank(
          sorted,
          state.currentUser,
          followedBrandIds: state.followedBrandIds,
        );
    }
    return sorted;
  }

  // Build 115: 팔로우한 브랜드의 편지는 인박스 상단에 고정. stable sort 라
  // 같은 follow/non-follow 그룹 내부의 시간 역순은 보존된다.
  // Build 324: aiRecommend 모드에서는 score 자체에 followed brand +20 이 이미
  //   포함되어 있고, 추가로 redeemed/만료 letter 도 큰 음수 패널티로 하단으로
  //   밀려야 한다. 여기서 followed 그룹을 통째로 상단 고정하면 만료된 followed
  //   쿠폰이 score 패널티를 무시하고 최상단에 노출되는 버그. AI 모드 시 skip.
  List<Letter> _sortFollowedFirst(AppState state, List<Letter> letters) {
    if (_sortMode == InboxSortMode.aiRecommend) return letters;
    if (state.followedBrandIds.isEmpty) return letters;
    final followed = <Letter>[];
    final rest = <Letter>[];
    for (final l in letters) {
      if (l.senderIsBrand && state.isBrandFollowed(l.senderId)) {
        followed.add(l);
      } else {
        rest.add(l);
      }
    }
    return [...followed, ...rest];
  }

  void _toggleSearch() {
    setState(() {
      _searchMode = !_searchMode;
      if (!_searchMode) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: AppTimeColors.of(context).bgDeep,
          // Build 321: 자동 발송 캠페인 등록을 compose 화면에 통합 — inbox FAB 제거.
          // Brand 사용자는 일반 발송 화면 (compose) 에서 "자동 zone 으로 등록"
          // 토글로 같은 흐름에 진입.
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, state),
                // 포지셔닝 힌트 — "주변에서 할인·이벤트 편지를 주우면 혜택이
                // 있어요" 메시지 한 줄. 브랜드 포지셔닝 변경으로 브랜드도
                // 줍기 가능해졌기에 모든 등급에 표시.
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🎟', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppL10n.of(
                            state.currentUser.languageCode,
                          ).inboxHuntHint,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 만료 사이렌 (Build 115, Build 116 에서 탭 가능) — 24h 이내
                // 만료되는 쿠폰/교환권이 있을 때만 붉은 배너 노출. 탭 시
                // 쿠폰 필터로 즉시 전환 + 받은 편지 탭으로 이동해 사용 유도.
                Builder(
                  builder: (ctx) {
                    final expiring = state.expiringSoonLetters;
                    if (expiring.isEmpty) return const SizedBox.shrink();
                    final l10n = AppL10n.of(state.currentUser.languageCode);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _inboxFilter = LetterFilterType.coupon;
                          _tabController.animateTo(0);
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.coupon.withValues(alpha: 0.18),
                              AppColors.coupon.withValues(alpha: 0.10),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.coupon.withValues(alpha: 0.55),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.expirySirenTitle(expiring.length),
                                style: const TextStyle(
                                  color: AppColors.coupon,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.expirySirenCta,
                              style: const TextStyle(
                                color: AppColors.coupon,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Build 179: 3-stat card (new/transit/total) 을 한 줄 compact
                // pill 로 축소. 수직 공간 ~60px 회수.
                Builder(
                  builder: (ctx) {
                    final newCount = state.inbox
                        .where((l) => l.status == DeliveryStatus.delivered)
                        .length;
                    final transitCount = state.inbox
                        .where(
                          (l) =>
                              l.status == DeliveryStatus.inTransit ||
                              l.status == DeliveryStatus.nearYou,
                        )
                        .length;
                    final l10n = AppL10n.of(state.currentUser.languageCode);
                    if (newCount == 0 && transitCount == 0) {
                      return const SizedBox(height: 6);
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (newCount > 0) ...[
                            Text(
                              '📩 ${l10n.inboxStatNew} $newCount',
                              style: AppText.caption.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (transitCount > 0) ...[
                              const SizedBox(width: 10),
                              Container(
                                width: 2,
                                height: 2,
                                decoration: const BoxDecoration(
                                  color: AppColors.textMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ],
                          if (transitCount > 0)
                            Text(
                              '🚀 ${l10n.inboxStatTransit} $transitCount',
                              style: AppText.caption.copyWith(
                                color: AppColors.teal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    // Build 217: Brand 면 [보낸 / 받은] 순서. 그 외 기본 순.
                    children: state.currentUser.isBrand
                        ? [
                            _SentTab(
                              letters: _applyFilter(
                                _sortByArrivedDesc(
                                  state,
                                  state.sent.toList(),
                                  isInbox: false,
                                ),
                                filter: _sentFilter,
                                isInbox: false,
                              ),
                              activeFilter: _sentFilter,
                              onFilterChanged: (next) {
                                setState(() => _sentFilter = next);
                              },
                            ),
                            _InboxTab(
                              letters: _applyFilter(
                                _sortFollowedFirst(
                                  state,
                                  _sortByArrivedDesc(
                                    state,
                                    state.inbox
                                        .where(
                                          (l) => !(l.senderIsBrand &&
                                              state.isBrandMuted(l.senderId)),
                                        )
                                        .toList(),
                                  ),
                                ),
                                filter: _inboxFilter,
                                isInbox: true,
                              ),
                              activeFilter: _inboxFilter,
                              onFilterChanged: (next) {
                                setState(() => _inboxFilter = next);
                              },
                              onTap: (letter) =>
                                  _openLetter(context, letter, state),
                              sentSinceLastUnlock: state.sentSinceLastUnlock,
                              canViewNext: state.canViewNextLetter,
                              scrollController: _inboxScrollController,
                              aiRecommendActive:
                                  _sortMode == InboxSortMode.aiRecommend,
                            ),
                          ]
                        : [
                            _InboxTab(
                              letters: _applyFilter(
                                _sortFollowedFirst(
                                  state,
                                  // Build 324: 정렬 모드 (Build 295 의 sort 필터)
                                  //   를 비-Brand 인박스에도 적용. 이전엔
                                  //   `.reversed.toList()` 만 사용 → sort 메뉴 무력화.
                                  _sortByArrivedDesc(
                                    state,
                                    state.inbox
                                        .where(
                                          (l) =>
                                              !(l.senderIsBrand &&
                                                  state.isBrandMuted(l.senderId)),
                                        )
                                        .toList(),
                                  ),
                                ),
                                filter: _inboxFilter,
                                isInbox: true,
                              ),
                              activeFilter: _inboxFilter,
                              onFilterChanged: (next) {
                                setState(() => _inboxFilter = next);
                              },
                              onTap: (letter) =>
                                  _openLetter(context, letter, state),
                              sentSinceLastUnlock: state.sentSinceLastUnlock,
                              canViewNext: state.canViewNextLetter,
                              scrollController: _inboxScrollController,
                              aiRecommendActive:
                                  _sortMode == InboxSortMode.aiRecommend,
                            ),
                            _SentTab(
                              letters: _applyFilter(
                                _sortByArrivedDesc(
                                  state,
                                  state.sent.toList(),
                                  isInbox: false,
                                ),
                                filter: _sentFilter,
                                isInbox: false,
                              ),
                              activeFilter: _sentFilter,
                              onFilterChanged: (next) {
                                setState(() => _sentFilter = next);
                              },
                            ),
                          ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  /// Build 153: 이번 달(로컬 타임존) 수령 편지 수 집계.
  /// 월 경계는 `arrivedAt.year == now.year && month == now.month` 기준.
  int _countThisMonth(List<Letter> letters) {
    final now = DateTime.now();
    return letters.where((l) {
      final a = l.arrivedAt;
      if (a == null) return false;
      return a.year == now.year && a.month == now.month;
    }).length;
  }

  Widget _buildHeader(BuildContext ctx, AppState state) {
    final l10n = AppL10n.of(state.currentUser.languageCode);
    return Padding(
      // Build 179: 세로 패딩 축소 (16→12), 내부 구조 단일화.
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Build 179: title fontSize 26→22, subtitle caps 제거.
                    // 전체 수집 수가 제목 옆에 "· 30" 형식으로 바로 노출.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [AppColors.goldLight, AppColors.gold],
                          ).createShader(b),
                          child: Text(
                            l10n.navCollection,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '· ${state.inbox.length}',
                          style: AppText.small.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Build 179: Monthly progress 만 남김 (subtitle caps + total 수 제거 — title 옆으로 흡수).
                    _MonthlyProgressBar(
                      collected: _countThisMonth(state.inbox),
                      target: 50,
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
              // Build 295: 정렬 모드 선택 (유효기간 / 최신 / 중요도).
              // Build 315: 아이콘만 → 현재 모드 텍스트+icon 칩으로 가시성 강화.
              //   "🕐 최신순 ▾" 같이 사용자가 어떤 정렬인지 즉시 인지.
              // Build 324: aiRecommend 옵션 추가 (Premium 전용). Free 사용자가
              //   선택 시 PremiumGateSheet 노출 + 모드는 변경하지 않음.
              PopupMenuButton<InboxSortMode>(
                tooltip: l10n.inboxSortTooltip,
                color: AppColors.bgCard,
                onSelected: (mode) {
                  if (mode == InboxSortMode.aiRecommend &&
                      !state.currentUser.isPremium) {
                    PremiumGateSheet.show(
                      context,
                      featureName: l10n.aiRecommendSortName,
                      featureEmoji: '✨',
                      description: l10n.aiRecommendUpsellDesc,
                    );
                    return;
                  }
                  setState(() => _sortMode = mode);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sort_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        () {
                          switch (_sortMode) {
                            case InboxSortMode.latest:
                              return l10n.inboxSortLatest;
                            case InboxSortMode.expiry:
                              return l10n.inboxSortExpiry;
                            case InboxSortMode.importance:
                              return l10n.inboxSortImportance;
                            case InboxSortMode.aiRecommend:
                              return l10n.inboxSortAiRecommend;
                          }
                        }(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                itemBuilder: (_) => [
                  CheckedPopupMenuItem(
                    value: InboxSortMode.latest,
                    checked: _sortMode == InboxSortMode.latest,
                    child: Text(l10n.inboxSortLatest,
                        style: const TextStyle(color: AppColors.textPrimary)),
                  ),
                  CheckedPopupMenuItem(
                    value: InboxSortMode.expiry,
                    checked: _sortMode == InboxSortMode.expiry,
                    child: Text(l10n.inboxSortExpiry,
                        style: const TextStyle(color: AppColors.textPrimary)),
                  ),
                  CheckedPopupMenuItem(
                    value: InboxSortMode.importance,
                    checked: _sortMode == InboxSortMode.importance,
                    child: Text(l10n.inboxSortImportance,
                        style: const TextStyle(color: AppColors.textPrimary)),
                  ),
                  // Build 324: AI 추천 (Premium 전용). 잠긴 상태는 트레일링 🔒
                  //   배지로 명시 — Free 사용자가 탭하면 PremiumGateSheet 으로
                  //   넘어가고 모드는 변경되지 않음.
                  CheckedPopupMenuItem(
                    value: InboxSortMode.aiRecommend,
                    checked: _sortMode == InboxSortMode.aiRecommend,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.inboxSortAiRecommend,
                            style: const TextStyle(
                                color: AppColors.textPrimary)),
                        if (!state.currentUser.isPremium) ...[
                          const SizedBox(width: 6),
                          const Text('🔒',
                              style: TextStyle(fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // 검색 버튼
              IconButton(
                onPressed: _toggleSearch,
                icon: Icon(
                  _searchMode ? Icons.search_off_rounded : Icons.search_rounded,
                  color: _searchMode ? AppColors.gold : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              if (!_searchMode && state.unreadCount > 0)
                GestureDetector(
                  onTap: () {
                    _tabController.animateTo(0);
                    final letters = _applyFilter(
                      _sortByArrivedDesc(state, state.inbox.toList()),
                      filter: _inboxFilter,
                      isInbox: true,
                    );
                    _scrollToFirstUnread(letters);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📩', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(
                          '${state.unreadCount}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_downward_rounded,
                          color: AppColors.gold,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // 검색 바 (검색 모드일 때만 표시)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => SizeTransition(
              sizeFactor: anim,
              axisAlignment: -1,
              child: child,
            ),
            child: _searchMode
                ? Padding(
                    key: const ValueKey('searchbar'),
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: l10n.inboxSearchHint,
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                                onPressed: () => setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                }),
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.bgCard,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('nosearch')),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final isBrand = context.read<AppState>().currentUser.isBrand;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(999),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(999),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.bgDeep,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: -0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: -0.1,
        ),
        // Build 217: Brand 사용자는 [보낸 / 받은] 순서 — 캠페인 추적 우선.
        // Free/Premium 은 [받은 / 보낸] 기본.
        tabs: isBrand
            ? [
                Tab(text: _l10n(context).inboxTabSent),
                Tab(text: _l10n(context).inboxTabReceived),
              ]
            : [
                Tab(text: _l10n(context).inboxTabReceived),
                Tab(text: _l10n(context).inboxTabSent),
              ],
      ),
    );
  }

  void _openLetter(BuildContext ctx, Letter letter, AppState state) {
    // Block opening deliveredFar letters
    if (letter.status == DeliveryStatus.deliveredFar) {
      final l10n = _l10n(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(l10n.inboxLocalOnly),
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    // Chain rule: first unread letter is always free to open
    if (letter.status == DeliveryStatus.delivered) {
      final unread = state.inbox
          .where((l) => l.status == DeliveryStatus.delivered)
          .toList();
      // The first unread (oldest) is always free; subsequent ones need chain rule
      final bool isFirstUnread =
          unread.isNotEmpty && unread.first.id == letter.id;
      if (!isFirstUnread && !state.canViewNextLetter) {
        _showChainRuleDialog(ctx, state);
        return;
      }
      if (!isFirstUnread && state.canViewNextLetter) {
        state.consumeLetterUnlock();
      }
    }
    state.readLetter(letter.id);
    Navigator.push(
      ctx,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => LetterReadScreen(
          letter: letter,
          userLanguageCode: state.currentUser.languageCode,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _showChainRuleDialog(BuildContext ctx, AppState state) {
    final l10n = _l10n(ctx);
    final remaining = 3 - state.sentSinceLastUnlock;
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '📬 ${l10n.inboxLetterLocked}',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.inboxSendMoreToRead(remaining),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.sentSinceLastUnlock / 3.0,
                backgroundColor: AppColors.bgSurface,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.inboxLettersSent(state.sentSinceLastUnlock, 3),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: Text(
              l10n.inboxConfirm,
              style: const TextStyle(color: AppColors.bgDeep),
            ),
          ),
        ],
      ),
    );
  }
}

void _confirmDelete(
  BuildContext ctx,
  AppState state,
  String letterId, {
  required bool isInbox,
}) {
  final l10n = AppL10n.of(state.currentUser.languageCode);
  showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.inboxDeleteTitle,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        l10n.inboxDeleteBody,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.6,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            l10n.inboxCancel,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            if (isInbox)
              state.deleteFromInbox(letterId);
            else
              state.deleteFromSent(letterId);
          },
          child: Text(
            l10n.inboxDelete,
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

// ── 받은 편지 탭 ──────────────────────────────────────────────────────────────
class _InboxTab extends StatelessWidget {
  final List<Letter> letters;
  final LetterFilterType activeFilter;
  final ValueChanged<LetterFilterType> onFilterChanged;
  final void Function(Letter) onTap;
  final int sentSinceLastUnlock;
  final bool canViewNext;
  final ScrollController? scrollController;
  // Build 324: AI 추천 모드 활성 시 letter 카드에 "왜 이 순서?" 칩 노출.
  //   false 면 칩 미노출 (latest/expiry/importance 모드).
  final bool aiRecommendActive;

  const _InboxTab({
    required this.letters,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.onTap,
    required this.sentSinceLastUnlock,
    required this.canViewNext,
    this.scrollController,
    this.aiRecommendActive = false,
  });

  /// Build 204: 필터=전체일 때 카테고리별 그룹 + 헤더 삽입. 특정 필터일 때는
  /// 단일 그룹이라 헤더 없이 letter rows 만 반환.
  List<_InboxRow> _buildRows(List<Letter> source, AppL10n l10n) {
    if (activeFilter != LetterFilterType.all) {
      return source.map((l) => _InboxLetterRow(l)).toList();
    }
    // 카테고리별 분리 — 원래 정렬 순서(팔로우 우선 + 최신순) 유지.
    final general = <Letter>[];
    final coupon = <Letter>[];
    final voucher = <Letter>[];
    for (final l in source) {
      switch (l.category) {
        case LetterCategory.coupon:
          coupon.add(l);
          break;
        case LetterCategory.voucher:
          voucher.add(l);
          break;
        case LetterCategory.general:
          general.add(l);
          break;
      }
    }
    final out = <_InboxRow>[];
    void appendGroup(List<Letter> group, String label, Color color) {
      if (group.isEmpty) return;
      out.add(_InboxHeaderRow(label: label, count: group.length, color: color));
      for (final l in group) {
        out.add(_InboxLetterRow(l));
      }
    }

    // 일반 → 할인권 → 교환권 (브랜드 카테고리 패널과 동일한 순서).
    appendGroup(general, l10n.inboxFilterGeneral, AppColors.textSecondary);
    appendGroup(coupon, l10n.inboxFilterCoupon, AppColors.coupon);
    appendGroup(voucher, l10n.inboxFilterVoucher, AppColors.gold);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    // 체인 룰 해제 — "3통 보내야 읽기" 게이트와 🔒 배너 모두 제거됨.
    // (unread / showChainBanner 계산이 필요 없어져 삭제.)
    // Build 204: 필터가 전체일 때 같은 분류끼리 자동 그룹핑(일반→할인권→
    // 교환권). 각 그룹 위에 작은 섹션 헤더를 끼워 넣어 시각 분리. 특정 필터
    // 가 켜져 있으면 그룹이 1개뿐이라 헤더 없이 평이한 리스트.
    final List<_InboxRow> rows = _buildRows(letters, l10n);
    return Column(
      children: [
        _LetterFilterBar(
          activeFilter: activeFilter,
          onChanged: onFilterChanged,
        ),
        if (letters.isEmpty)
          Expanded(
            child: Builder(
              builder: (ctx) {
                // Build 115 — "지금 근처에 N통 있어요" 실시간 카운터를 부제에
                // 덧붙여 empty state 가 "죽은 공간" 이 되지 않게 한다.
                final state = ctx.read<AppState>();
                final nearby = state.nearbyLetters.length;
                final baseSub = l10n.inboxEmptyReceivedSub;
                final sub = nearby > 0
                    ? '$baseSub\n${l10n.inboxEmptyNearbyCount(nearby)}'
                    : baseSub;
                return Stack(
                  children: [
                    _EmptyState(
                      emoji: _emptyEmojiForFilter(activeFilter),
                      title: activeFilter == LetterFilterType.all
                          ? l10n.inboxEmptyReceived
                          : l10n.inboxEmptyForFilter(
                              _filterName(activeFilter, l10n),
                            ),
                      subtitle: sub,
                      ctaLabel: _isHuntFilter(activeFilter)
                          ? l10n.emptyStateExploreCta
                          : l10n.emptyStateWriteCta,
                      onCtaTap: () => _isHuntFilter(activeFilter)
                          ? Navigator.of(
                              context,
                            ).pushNamedAndRemoveUntil('/home', (route) => false)
                          : Navigator.of(context).pushNamed('/compose'),
                    ),
                    // Build 242: 빈 상태 하단에 가맹점 영입 CTA — Cold-start
                    // 양방향 마켓 부트스트랩의 핵심. Free/Premium 사용자에게
                    // "사장님이세요?" 노출 → 실 가맹점 관심 캡처. Brand 등급은
                    // 이미 가맹점이므로 노출 안 함. 이미 등록한 사용자도 숨김.
                    if (!state.currentUser.isBrand)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 24,
                        child: FutureBuilder<bool>(
                          future: MerchantInterestSheet.isAlreadyRegistered(),
                          builder: (ctx, snap) {
                            if (snap.data == true)
                              return const SizedBox.shrink();
                            return _MerchantHookCard(l10n: l10n);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          )
        else ...[
          // "🔒 3통 보내야 다음 읽기" 체인 배너 제거 — 답장 무제한 정책과
          // 정합 맞추기. `sentSinceLastUnlock` 카운터는 통계용으로 유지.
          Expanded(
            // Build 254: Pull-to-refresh — 서버 letter 동기화 + UI 갱신.
            child: RefreshIndicator(
              color: AppColors.gold,
              backgroundColor: AppColors.bgCard,
              onRefresh: () async {
                final s = context.read<AppState>();
                await s.syncWorldLettersFromServer();
                await s.fetchMapUsers(force: true);
              },
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: rows.length,
                itemBuilder: (ctx, i) {
                  final row = rows[i];
                  if (row is _InboxHeaderRow) {
                    return _CategorySectionHeader(
                      label: row.label,
                      count: row.count,
                      color: row.color,
                    );
                  }
                  final letter = (row as _InboxLetterRow).letter;
                  // 체인 룰 해제로 잠금 표시 항상 false.
                  const isLocked = false;
                  // Build 183: 받은 편지 카드 양방향 스와이프 —
                  //   → (startToEnd): 사용 완료 (초록)
                  //   ← (endToStart): 삭제 (빨강)
                  // mark-used 는 dismissible 이 아니라 일반 swipe callback 으로
                  // 처리. dismissed 되면 카드가 사라지지만 mark used 후에도
                  // 카드는 유지해야 하므로 `confirmDismiss` false 반환 + 별도
                  // markRedeemed 호출로 상태 갱신.
                  final alreadyUsed = ctx.read<AppState>().isLetterRedeemed(
                    letter.id,
                  );
                  return Dismissible(
                    key: ValueKey(letter.id),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      decoration: BoxDecoration(
                        color: alreadyUsed
                            ? const Color(0xFF435448)
                            : const Color(0xFF1A6B45),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alreadyUsed
                                ? l10n.inboxAlreadyUsed
                                : l10n.inboxMarkUsed,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.inboxDelete,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        // 사용 완료 토글: 이미 사용됐으면 무시 (snackbar 로 알림).
                        if (alreadyUsed) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(l10n.inboxAlreadyUsedSnack),
                              backgroundColor: AppColors.bgCard,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                          return false;
                        }
                        ctx.read<AppState>().markLetterRedeemed(letter.id);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(l10n.inboxMarkedUsed),
                            backgroundColor: const Color(0xFF1A6B45),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return false; // 카드 제거 안 함 — 상태만 바뀜.
                      }
                      // 삭제 확인 다이얼로그
                      return await showDialog<bool>(
                            context: ctx,
                            builder: (dialogCtx) => AlertDialog(
                              backgroundColor: AppColors.bgCard,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                l10n.inboxDeleteTitle,
                                style: const TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                l10n.inboxDeleteConfirm,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, false),
                                  child: Text(
                                    l10n.inboxCancel,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, true),
                                  child: Text(
                                    l10n.inboxDelete,
                                    style: const TextStyle(
                                      color: AppColors.coupon,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                    },
                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        ctx.read<AppState>().deleteFromInbox(letter.id);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(l10n.inboxDeleted),
                            backgroundColor: AppColors.bgCard,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    child: _LetterCard(
                      letter: letter,
                      isInbox: true,
                      isLocked: isLocked,
                      // Build 324: AI 추천 모드 활성 시 letter 별 추천 이유 칩 계산.
                      aiReasonChip: aiRecommendActive
                          ? _resolveAiReasonChip(ctx, letter)
                          : null,
                      onTap: () => onTap(letter),
                      onDelete: () => _confirmDelete(
                        ctx,
                        ctx.read<AppState>(),
                        letter.id,
                        isInbox: true,
                      ),
                    ),
                  );
                },
              ),
            ), // close RefreshIndicator (Build 254 pull-to-refresh)
          ),
        ],
      ],
    );
  }
}

// ── 보낸 편지 탭 ──────────────────────────────────────────────────────────────
class _SentTab extends StatelessWidget {
  final List<Letter> letters;
  final LetterFilterType activeFilter;
  final ValueChanged<LetterFilterType> onFilterChanged;

  const _SentTab({
    required this.letters,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final state = context.watch<AppState>();
    final isBrand = state.currentUser.isBrand;
    // Build 216: Brand 사용자는 발송 letter 를 1건씩 리스트로 안 봐도 됨.
    // 캠페인 효율 위주로 요약 카드(전체 N · 픽업 M · 사용 K · 미확인 X)
    // + drill-down 분류별 상세. _BrandSentSummaryView 로 완전 교체.
    if (isBrand) {
      return Column(
        children: [
          _LetterFilterBar(
            activeFilter: activeFilter,
            onChanged: onFilterChanged,
          ),
          Expanded(
            child: _BrandSentSummaryView(
              letters: letters,
              activeFilter: activeFilter,
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _LetterFilterBar(
          activeFilter: activeFilter,
          onChanged: onFilterChanged,
        ),
        if (letters.isEmpty)
          Expanded(
            child: _EmptyState(
              emoji: activeFilter == LetterFilterType.all
                  ? '📮'
                  : _emptyEmojiForFilter(activeFilter),
              title: activeFilter == LetterFilterType.all
                  ? l10n.inboxEmptySent
                  : l10n.inboxEmptyForFilter(_filterName(activeFilter, l10n)),
              subtitle: l10n.inboxEmptySentSub,
              ctaLabel: l10n.emptyStateWriteCta,
              onCtaTap: () => Navigator.of(context).pushNamed('/compose'),
              // 발송함의 "헌트 모드" 필터(할인권·교환권·브랜드)는 발송 이력
              // 기반이므로 CTA는 "편지 쓰기"로 유지 (수신함과 다름).
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: letters.length,
              itemBuilder: (ctx, i) {
                final letter = letters[i];
                return Dismissible(
                  key: ValueKey(letter.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.inboxDelete,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: ctx,
                          builder: (dialogCtx) => AlertDialog(
                            backgroundColor: AppColors.bgCard,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              l10n.inboxDeleteTitle,
                              style: const TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              l10n.inboxDeleteConfirm,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogCtx, false),
                                child: Text(
                                  l10n.inboxCancel,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx, true),
                                child: Text(
                                  l10n.inboxDelete,
                                  style: const TextStyle(
                                    color: AppColors.coupon,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) {
                    ctx.read<AppState>().deleteFromSent(letter.id);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(l10n.inboxDeleted),
                        backgroundColor: AppColors.bgCard,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: _LetterCard(
                    letter: letter,
                    isInbox: false,
                    onTap: () => _showSentDetail(ctx, letter),
                    onDelete: () => _confirmDelete(
                      ctx,
                      ctx.read<AppState>(),
                      letter.id,
                      isInbox: false,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showSentDetail(BuildContext ctx, Letter letter) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SentDetailSheet(
        letter: letter,
        onTrackTap:
            (letter.status == DeliveryStatus.inTransit ||
                letter.status == DeliveryStatus.nearYou)
            ? () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => LetterTrackingScreen(letterId: letter.id),
                ),
              )
            : null,
      ),
    );
  }
}

// ── 편지 카드 ─────────────────────────────────────────────────────────────────
class _LetterCard extends StatelessWidget {
  final Letter letter;
  final bool isInbox;
  final bool isLocked;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  // Build 324: AI 추천 모드 시 "왜 이 순서?" 1줄 이유 칩. null 이면 미노출.
  //   형식 예: "🏷 팔로우한 브랜드" / "⏰ 곧 만료" / "🎯 내 선호 카테고리".
  // Build 325 (T2): top 외 추가 매칭 신호 수 (extraSignals) — 1+ 이면 "+N"
  //   보조 뱃지 표시 → 다신호 letter 강조 ("팔로우 브랜드 + 만료 임박 + 근거리").
  final ({String text, int extra})? aiReasonChip;

  const _LetterCard({
    required this.letter,
    required this.isInbox,
    this.isLocked = false,
    required this.onTap,
    this.onDelete,
    this.aiReasonChip,
  });

  bool get _isUnread => isInbox && letter.status == DeliveryStatus.delivered;

  /// Build 325 (T5): 단일 뱃지 priority — Brand > Premium promo > AI curated.
  ///   기존 3개 뱃지 동시 노출을 1개로 압축 (5요소 룰).
  ///   반환 list 은 Row.children spread 가능한 [SizedBox + Container] (또는 빈 list).
  List<Widget> _buildSingleContextBadge(Letter letter, AppL10n l10n) {
    if (letter.senderIsBrand ||
        letter.letterType == LetterType.brandExpress) {
      return [
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            gradient: (letter.category == LetterCategory.coupon ||
                    letter.category == LetterCategory.voucher)
                ? const LinearGradient(
                    colors: [AppColors.teal, Color(0xFF4DD0E1)],
                  )
                : const LinearGradient(
                    colors: [AppColors.coupon, Color(0xFFFFB347)],
                  ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                letter.category == LetterCategory.coupon
                    ? '🎟'
                    : letter.category == LetterCategory.voucher
                        ? '🎁'
                        : '🏢',
                style: const TextStyle(fontSize: 9),
              ),
              const SizedBox(width: 2),
              Text(
                letter.category == LetterCategory.coupon
                    ? l10n.inboxFilterCoupon
                    : letter.category == LetterCategory.voucher
                        ? l10n.inboxFilterVoucher
                        : l10n.labelBrand,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              if (letter.letterType == LetterType.brandExpress) ...[
                const SizedBox(width: 2),
                const Text('⚡', style: TextStyle(fontSize: 9)),
              ],
            ],
          ),
        ),
      ];
    }
    if (letter.senderTier == LetterSenderTier.premium) {
      return [
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gold, Color(0xFFFFD86B)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📣', style: TextStyle(fontSize: 9)),
              const SizedBox(width: 2),
              Text(
                l10n.inboxBadgePromo,
                style: const TextStyle(
                  color: Color(0xFF1A1300),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    if (letter.senderId.startsWith('ai_')) {
      return [
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.textMuted.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🤖', style: TextStyle(fontSize: 9)),
              const SizedBox(width: 2),
              Text(
                l10n.labelAiCurated,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return const [];
  }

  /// Build 325 (T5): "거리 or 만료" smart indicator — 5요소 룰.
  ///   우선순위:
  ///   1) 만료 ≤ 24h 이면 "⏰ Nh" (가장 행동 자극)
  ///   2) 사용자 GPS 유효 + 거리 측정 가능 → "📍 Nm" or "📍 N.Nkm"
  ///   3) fallback: 발송지 (기존 동작 보존)
  String _buildSmartContextLabel(
    BuildContext ctx,
    Letter letter,
    AppL10n l10n,
  ) {
    final now = DateTime.now();
    final couponExp = letter.redemptionExpiresAt;
    final autoExp = letter.expiresAt;
    DateTime? earliest;
    if (couponExp != null && autoExp != null) {
      earliest = couponExp.isBefore(autoExp) ? couponExp : autoExp;
    } else {
      earliest = couponExp ?? autoExp;
    }
    if (earliest != null && earliest.isAfter(now)) {
      final remain = earliest.difference(now);
      if (remain.inHours <= 24) {
        if (remain.inHours >= 1) return '⏰ ${remain.inHours}h';
        return '⏰ ${remain.inMinutes}m';
      }
    }

    final user = ctx.read<AppState>().currentUser;
    if (user.latitude != 0 || user.longitude != 0) {
      final dest = letter.destinationLocation;
      if (dest.latitude != 0 || dest.longitude != 0) {
        final distM = LatLng(user.latitude, user.longitude)
            .distanceTo(dest);
        if (distM < 1000) return '📍 ${distM.round()}m';
        return '📍 ${(distM / 1000).toStringAsFixed(1)}km';
      }
    }

    return '${letter.senderCountryFlag} ${CountryL10n.localizedName(letter.senderCountry, l10n.languageCode)}';
  }

  /// Build 324 (Q2): leading 영역 위젯 — Brand letter + 혜택 강도 추출 성공
  ///   시 big text. 그 외 인물+국기 stack 또는 destination 국기.
  Widget _buildLetterLeading(Letter letter, bool isInbox) {
    if (isInbox && letter.senderIsBrand) {
      final benefit = _extractBenefitBigText(letter);
      if (benefit != null) {
        return Text(
          benefit,
          style: TextStyle(
            color: AppColors.coupon,
            fontSize: benefit.length >= 4 ? 16 : 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        );
      }
    }
    // fallback: 인물+국기 stack
    if (isInbox) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            letter.senderIsBrand
                ? '🏢'
                : personEmojiForId(letter.senderId),
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            letter.senderCountryFlag,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      );
    }
    return Text(
      letter.destinationCountryFlag,
      style: const TextStyle(fontSize: 26),
    );
  }

  /// Build 261: letter 종류별 시각 구분 색상.
  /// 메시지 (일반 user 발송) → teal: 사람 간 letter
  /// 쿠폰 (LetterCategory.coupon/voucher) → coupon (#FF4D6D 핑크/레드): 할인권/교환권
  /// 홍보 (브랜드 일반 + brandExpress + Premium 발송) → gold: 마케팅 메시지
  Color get _accentColor {
    // 1) 쿠폰/교환권 (Brand 한정)
    if (letter.senderIsBrand &&
        (letter.category == LetterCategory.coupon ||
            letter.category == LetterCategory.voucher)) {
      return AppColors.coupon;
    }
    // 2) 홍보 (Brand 일반 + brandExpress + Premium 발송 promo)
    if (letter.senderIsBrand ||
        letter.letterType == LetterType.brandExpress ||
        letter.senderTier == LetterSenderTier.premium) {
      return AppColors.gold;
    }
    // 3) 일반 메시지 (Free user)
    return AppColors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final accent = _accentColor;
    final highlight = _isUnread && !isLocked;
    // Build 304 (a11y): VoiceOver/TalkBack 라벨 — 발신자/내용 prefix/상태.
    // 기존 AppL10n 키만 사용 (l10n.inboxRead 등). 새 키 추가 회피.
    final isKo = l10n.languageCode == 'ko';
    final preview = letter.content.length > 40
        ? '${letter.content.substring(0, 40)}…'
        : letter.content;
    final semanticsLabel = [
      if (_isUnread) (isKo ? '안 읽음' : 'Unread'),
      if (isLocked) (isKo ? '잠김' : 'Locked'),
      letter.senderName,
      preview,
    ].where((s) => s.isNotEmpty).join(', ');
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: isInbox && !isLocked
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        accent.withValues(alpha: highlight ? 0.16 : 0.08),
                        AppColors.bgCard,
                      ],
                      stops: const [0.0, 0.45],
                    )
                  : null,
              color: isInbox && !isLocked
                  ? null
                  : (isLocked
                        ? AppColors.bgCard.withValues(alpha: 0.4)
                        : AppColors.bgCard),
              borderRadius: BorderRadius.circular(22),
              // 모든 inbox 카드에 4px 좌측 accent stripe + unread 시 전체 테두리.
              border: Border(
                left: BorderSide(
                  color: isInbox && !isLocked
                      ? accent.withValues(alpha: highlight ? 1.0 : 0.7)
                      : Colors.transparent,
                  width: 4,
                ),
                top: BorderSide(
                  color: highlight
                      ? accent.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1,
                ),
                right: BorderSide(
                  color: highlight
                      ? accent.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1,
                ),
                bottom: BorderSide(
                  color: highlight
                      ? accent.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              boxShadow: highlight
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Build 324: AI 추천 모드 시 "왜 이 순서?" 이유 칩 노출 — 사용자
              //   신뢰 확보 + 추천 알고리즘 투명성. aiReasonChip null 이면 미노출.
              // Build 325 (T1): gold → violet (AppColors.aiSignal) — gold 가 FOMO
              //   / Brand / Premium 와 충돌해 변별 0 이던 문제 해소. AI 추천은
              //   violet 단독 시각 신호로 분리.
              if (aiReasonChip != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.aiSignalBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.aiSignalBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  aiReasonChip!.text,
                                  style: const TextStyle(
                                    color: AppColors.aiSignal,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Build 325 (T2): 추가 매칭 신호 수 > 0 이면 "+N" 보조 뱃지.
                      //   다신호 letter (예: 팔로우 + 만료 + 근거리) 가시화.
                      if (aiReasonChip!.extra > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.aiSignal,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '+${aiReasonChip!.extra}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Build 324 (Q2): leading 영역 — Brand letter 면 할인율 big text
                //   (사용자가 0.5초에 "얼마 이득" 인지 → 픽업/사용 결정 가속).
                //   추출 실패 또는 일반 letter 면 이전 인물+국기 stack 유지.
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: (isInbox && letter.senderIsBrand &&
                            _extractBenefitBigText(letter) != null)
                        ? LinearGradient(
                            colors: [
                              AppColors.coupon.withValues(alpha: 0.25),
                              AppColors.coupon.withValues(alpha: 0.10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: (isInbox && letter.senderIsBrand &&
                            _extractBenefitBigText(letter) != null)
                        ? null
                        : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: (isInbox && letter.senderIsBrand &&
                            _extractBenefitBigText(letter) != null)
                        ? Border.all(
                            color: AppColors.coupon.withValues(alpha: 0.5),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Center(
                    child: _buildLetterLeading(letter, isInbox),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isInbox
                                  ? (letter.isAnonymous
                                        ? l10n.inboxAnonymousLetter
                                        : letter.senderName)
                                  : '→ ${CountryL10n.localizedName(letter.destinationCountry, l10n.languageCode)}',
                              style: TextStyle(
                                color: _isUnread
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: _isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Build 325 (T5): 5요소 룰 — Brand / Premium / AI 다중
                          //   뱃지 중복 노출 (3) 을 **단일** 뱃지 priority 로직
                          //   으로 통합. Brand > Premium promo > AI curated.
                          ..._buildSingleContextBadge(letter, l10n),
                          if (_isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.gold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        letter.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _isUnread
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Build 325 (T5): 5요소 룰 — 발송지 (국기+국명) 대신
                          //   "거리 or 만료" smart indicator. 만료 ≤ 24h 이면
                          //   "⏰ Nh", 그 외 거리 가능 시 "📍 Nm/km", fallback
                          //   원래 발송지.
                          Text(
                            _buildSmartContextLabel(context, letter, l10n),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          // 보낸 편지 읽음 여부
                          if (!isInbox && letter.isReadByRecipient)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '✓ ${l10n.inboxRead}',
                                style: const TextStyle(
                                  color: AppColors.teal,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          // 상태
                          _StatusBadge(status: letter.status, isInbox: isInbox),
                        ],
                      ),
                      // 배송 게이지 (보낸 편지 + 배송 중)
                      if (!isInbox &&
                          letter.status == DeliveryStatus.inTransit) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: letter.overallProgress,
                            backgroundColor: AppColors.bgSurface,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.teal,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${letter.currentTransport.emoji} ${(letter.overallProgress * 100).toStringAsFixed(0)}% · ${letter.etaLabel} ${l10n.inboxEta}',
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
              ], // Column.children close (Build 324: AI 추천 칩 + Row 카드 본문)
            ),
          ),
          // 잠금 오버레이 (chain rule)
          if (isLocked)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgDeep.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔒', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        l10n.inboxSend3ToOpen,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 삭제 버튼 (우상단)
          if (onDelete != null && !isLocked)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.bgDeep.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 15,
                  ),
                ),
              ),
            ),
          // 현지 수령 필요 오버레이 (deliveredFar)
          if (letter.status == DeliveryStatus.deliveredFar)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgDeep.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 브랜드 편지는 카테고리 맞춤 이모지(✉️/🎟/🎁), Premium 발신자는
                      // 📣 (홍보 편지), 그 외는 📬 (일반).
                      Text(
                        letter.senderIsBrand
                            ? letter.category.brandEmoji
                            : letter.senderTier == LetterSenderTier.premium
                            ? '📣'
                            : '📬',
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.inboxLocalOnly,
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

/// Build 204: 수집첩 동일 분류 그룹 헤더 + 행 모델.
sealed class _InboxRow {}

class _InboxLetterRow extends _InboxRow {
  final Letter letter;
  _InboxLetterRow(this.letter);
}

class _InboxHeaderRow extends _InboxRow {
  final String label;
  final int count;
  final Color color;
  _InboxHeaderRow({
    required this.label,
    required this.count,
    required this.color,
  });
}

class _CategorySectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CategorySectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Row(
        children: [
          Container(width: 3, height: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.66,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Build 216: Brand 사용자 전용 발송 요약 뷰.
/// 1건씩 리스트가 아닌 캠페인 통계 hero + 분류별 drill-down 카드.
///
/// 구조:
///   1) Hero — 총 발송 수 (큰 글자)
///   2) 4-stat 그리드: 픽업·미확인·사용·답장
///   3) 분류별 카드 (탭하면 해당 카테고리 letter list 모달)
class _BrandSentSummaryView extends StatelessWidget {
  final List<Letter> letters;
  final LetterFilterType activeFilter;
  const _BrandSentSummaryView({
    required this.letters,
    required this.activeFilter,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final l = AppL10n.of(state.currentUser.languageCode);

    // 분류별 카운트
    final total = letters.length;
    final picked = letters
        .where(
          (l) =>
              l.status == DeliveryStatus.delivered ||
              l.status == DeliveryStatus.read ||
              l.status == DeliveryStatus.deliveredFar ||
              l.status == DeliveryStatus.nearYou,
        )
        .length;
    final inTransit = letters
        .where(
          (l) =>
              l.status == DeliveryStatus.inTransit ||
              l.status == DeliveryStatus.nearYou,
        )
        .length;
    final unconfirmed = letters
        .where(
          (l) =>
              l.status == DeliveryStatus.deliveredFar ||
              l.status == DeliveryStatus.delivered,
        )
        .length;
    final used = letters.where((l) => state.isLetterRedeemed(l.id)).length;
    final replied = letters.where((l) => l.hasReplied).length;

    if (total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📮', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                l.inboxEmptySent,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.inboxEmptySentSub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/compose'),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text(l.emptyStateWriteCta),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coupon,
                  foregroundColor: const Color(0xFF1A0008),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pickRate = total > 0 ? (picked / total * 100) : 0.0;
    final useRate = picked > 0 ? (used / picked * 100) : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // ── Hero: 총 발송 수 ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.coupon.withValues(alpha: 0.22),
                AppColors.coupon.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.coupon.withValues(alpha: 0.5),
              width: 1.4,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📮 총 발송 캠페인',
                style: TextStyle(
                  color: AppColors.coupon,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.brandStatsUnit,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _RatePill(
                    label: l.brandStatsPickRate,
                    value: '${pickRate.toStringAsFixed(1)}%',
                  ),
                  const SizedBox(width: 8),
                  _RatePill(
                    label: l.brandStatsUseRate,
                    value: '${useRate.toStringAsFixed(1)}%',
                    accent: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── 4-stat 그리드 (Build 249: i18n 14개 언어 적용) ──
        Row(
          children: [
            Expanded(
              child: _BrandStatBlock(
                emoji: '🎯',
                label: l.brandStatsPickedLabel,
                value: picked,
                color: AppColors.success,
                onTap: () => _showCategoryDetail(
                  context,
                  l.brandStatsPickedDetailTitle,
                  letters
                      .where(
                        (l) =>
                            l.status == DeliveryStatus.delivered ||
                            l.status == DeliveryStatus.read ||
                            l.status == DeliveryStatus.deliveredFar ||
                            l.status == DeliveryStatus.nearYou,
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BrandStatBlock(
                emoji: '✈️',
                label: l.brandStatsInTransitLabel,
                value: inTransit,
                color: AppColors.teal,
                onTap: () => _showCategoryDetail(
                  context,
                  l.brandStatsInTransitDetailTitle,
                  letters
                      .where(
                        (l) =>
                            l.status == DeliveryStatus.inTransit ||
                            l.status == DeliveryStatus.nearYou,
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BrandStatBlock(
                emoji: '✅',
                label: l.brandStatsUsedLabel,
                value: used,
                color: AppColors.coupon,
                onTap: () {
                  final state2 = context.read<AppState>();
                  _showCategoryDetail(
                    context,
                    l.brandStatsUsedDetailTitle,
                    letters
                        .where((l) => state2.isLetterRedeemed(l.id))
                        .toList(),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BrandStatBlock(
                emoji: '📬',
                label: l.brandStatsUnconfirmedLabel,
                value: unconfirmed,
                color: AppColors.warning,
                onTap: () => _showCategoryDetail(
                  context,
                  l.brandStatsUnconfirmedDetailTitle,
                  letters
                      .where(
                        (l) =>
                            l.status == DeliveryStatus.deliveredFar ||
                            l.status == DeliveryStatus.delivered,
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BrandStatBlock(
                emoji: '💌',
                label: l.brandStatsRepliedLabel,
                value: replied,
                color: AppColors.gold,
                highlight: true,
                onTap: () => _showCategoryDetail(
                  context,
                  l.brandStatsRepliedDetailTitle,
                  letters.where((l) => l.hasReplied).toList(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BrandStatBlock(
                emoji: '📋',
                label: l.brandStatsViewAllLabel,
                value: total,
                color: AppColors.textSecondary,
                onTap: () => _showCategoryDetail(
                  context,
                  l.brandStatsAllDetailTitle,
                  letters,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),
        // 발송 안내 — 대량 캠페인 유도
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textMuted.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.brandStatsTapHint,
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
    );
  }

  void _showCategoryDetail(
    BuildContext context,
    String title,
    List<Letter> subset,
  ) {
    if (subset.isEmpty) {
      // Build 297 (P0 i18n): 한국어 조사 (가) 가정 + 한글 하드코딩 제거.
      final l10n = AppL10n.of(
        context.read<AppState>().currentUser.languageCode,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.inboxNothingForFilter(title)),
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$title (${subset.length})',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.bgSurface, height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: subset.length,
                itemBuilder: (_, i) => _LetterCard(
                  letter: subset[i],
                  isInbox: false,
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatePill extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  const _RatePill({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ? AppColors.coupon : AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgDeep.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandStatBlock extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;
  final Color color;
  final bool highlight;
  final VoidCallback onTap;
  const _BrandStatBlock({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight ? color.withValues(alpha: 0.14) : AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight
                  ? color.withValues(alpha: 0.5)
                  : AppColors.textMuted.withValues(alpha: 0.15),
              width: highlight ? 1.3 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    size: 11,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: TextStyle(
                  color: highlight ? color : AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LetterFilterBar extends StatelessWidget {
  final LetterFilterType activeFilter;
  final ValueChanged<LetterFilterType> onChanged;

  const _LetterFilterBar({required this.activeFilter, required this.onChanged});

  /// Build 324: 그룹 칩 long-press 시 7-way sub-filter 시트.
  ///   eat → food/cafe / shop → beauty/fashion / etc → it/event/other 칩으로 펼침.
  ///   세분 의도 사용자 (예: "패션만") 마찰 해소 (Premium 시뮬레이션 발견).
  void _showSubfilterSheet(
    BuildContext context,
    LetterFilterType group,
    AppL10n l10n,
  ) {
    final subTags = _groupToCategoryTags[group];
    if (subTags == null || subTags.isEmpty) return;
    final subFilters = subTags
        .map(_filterTypeFromName)
        .whereType<LetterFilterType>()
        .toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sCtx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              _textLabel(group, l10n),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subFilters.map((f) {
                return _FilterChipInline(
                  label: '${_emptyEmojiForFilter(f)} ${_textLabel(f, l10n)}',
                  selected: false,
                  onTap: () {
                    Navigator.of(sCtx).pop();
                    onChanged(f);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _textLabel(LetterFilterType type, AppL10n l10n) {
    switch (type) {
      case LetterFilterType.all:
        return l10n.inboxFilterAll;
      case LetterFilterType.read:
        return l10n.inboxRead;
      case LetterFilterType.inTransit:
        return l10n.inboxFilterInTransit;
      case LetterFilterType.waitingPickup:
        return l10n.inboxFilterWaiting;
      case LetterFilterType.brand:
        return l10n.inboxFilterBrand;
      case LetterFilterType.coupon:
        return l10n.inboxFilterCoupon;
      case LetterFilterType.voucher:
        return l10n.inboxFilterVoucher;
      case LetterFilterType.general:
        return l10n.inboxFilterGeneral;
      case LetterFilterType.food:
        return l10n.inboxFilterFood;
      case LetterFilterType.cafe:
        return l10n.inboxFilterCafe;
      case LetterFilterType.beauty:
        return l10n.inboxFilterBeauty;
      case LetterFilterType.fashion:
        return l10n.inboxFilterFashion;
      case LetterFilterType.it:
        return l10n.inboxFilterIt;
      case LetterFilterType.event:
        return l10n.inboxFilterEvent;
      case LetterFilterType.other:
        return l10n.inboxFilterOther;
      // Build 324: 3-그룹 단순화
      case LetterFilterType.eat:
        return l10n.inboxFilterEat;
      case LetterFilterType.shop:
        return l10n.inboxFilterShop;
      case LetterFilterType.etc:
        return l10n.inboxFilterEtc;
    }
  }

  void _openSheet(BuildContext ctx, AppL10n l10n) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Build 315: "산업군" → "카테고리" 명칭 변경 (i18n).
              Text(
                l10n.inboxCategorySectionTitle.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.66,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _industryFilters.map((type) {
                  final selected = type == activeFilter;
                  return Material(
                    color: selected ? AppColors.gold : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(999),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        onChanged(type);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        child: Text(
                          _textLabel(type, l10n),
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF1A1300)
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    // Build 318: 인라인 칩 row 1줄로 통합 — 11개 필터 (메인 4 + 카테고리 7).
    // 가로 스크롤 + 우측 fade 로 화면 폭 부족할 때 시각 cue.
    // BottomSheet 제거 — 모든 선택이 1탭 (이전엔 BottomSheet 열고 닫는 추가 2탭).
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: SizedBox(
        height: 34,
        child: ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.black, Colors.black, Colors.transparent],
              stops: [0.0, 0.92, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          // Build 318 (단순화): BottomSheet + 더보기 ⋯ 칩 제거.
          // 모든 11개 필터 (메인 4 + 카테고리 7) 를 가로 스크롤 row 에 직접 노출.
          // 사용자가 BottomSheet 열고 닫는 1단계 제거 — 원탭으로 즉시 선택.
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: [
              ..._visibleFilters.map((type) {
                final selected = type == activeFilter;
                // Build 324: 그룹 칩 (eat/shop/etc) 만 long-press 활성 → 7-way
                //   sub-filter 시트로 세분 의도 사용자 마찰 해소.
                final isGroup = _groupToCategoryTags.containsKey(type);
                return _FilterChipInline(
                  label: _textLabel(type, l10n),
                  selected: selected,
                  showSubfilterHint: isGroup,
                  onTap: () => onChanged(type),
                  onLongPress: isGroup
                      ? () => _showSubfilterSheet(context, type, l10n)
                      : null,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipInline extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  // Build 324: 그룹 칩 (eat/shop/etc) long-press 시 7-way sub-filter 시트.
  //   null 이면 long-press 무효 (단일 카테고리/메인 필터).
  final VoidCallback? onLongPress;
  // Build 324: long-press 가능한 칩에 ⋯ trailing 점 노출 — 사용자에게 long-press
  //   힌트 (모든 사용자가 long-press 알아채는 건 아님 — 작은 시각 어포던스).
  final bool showSubfilterHint;

  const _FilterChipInline({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.showSubfilterHint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected ? AppColors.gold : AppColors.bgCard,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF1A1300)
                        : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                // Build 324: long-press 어포던스 (⋯).
                if (showSubfilterHint) ...[
                  const SizedBox(width: 4),
                  Text(
                    '⋯',
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF1A1300).withValues(alpha: 0.6)
                          : AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DeliveryStatus status;
  final bool isInbox;

  const _StatusBadge({required this.status, required this.isInbox});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    Color color;
    String label;

    if (!isInbox) {
      switch (status) {
        case DeliveryStatus.inTransit:
          color = AppColors.teal;
          label = '✈️ ${l10n.inboxStatusInTransit}';
          break;
        case DeliveryStatus.nearYou:
          color = AppColors.gold;
          label = '📍 ${l10n.inboxStatusNearby}';
          break;
        case DeliveryStatus.deliveredFar:
          color = AppColors.warning;
          label = '📬 ${l10n.inboxStatusWaiting}';
          break;
        case DeliveryStatus.delivered:
        case DeliveryStatus.read:
          color = AppColors.success;
          label = '✅ ${l10n.inboxStatusDelivered}';
          break;
        default:
          color = AppColors.textMuted;
          label = '—';
      }
    } else {
      switch (status) {
        case DeliveryStatus.deliveredFar:
          color = AppColors.warning;
          label = '📬 ${l10n.inboxStatusWaiting}';
          break;
        case DeliveryStatus.delivered:
          color = AppColors.gold;
          label = '📩 ${l10n.inboxStatusNewLetter}';
          break;
        case DeliveryStatus.read:
          color = AppColors.textMuted;
          label = '✓ ${l10n.inboxRead}';
          break;
        default:
          color = AppColors.textMuted;
          label = '—';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── 빈 상태 ──────────────────────────────────────────────────────────────────
/// Build 242: 빈 상태 하단의 가맹점 영입 카드. 일반 사용자가 누르면
/// MerchantInterestSheet 노출 → 관심 등록 → Firestore + SharedPreferences 저장.
class _MerchantHookCard extends StatelessWidget {
  final AppL10n l10n;

  const _MerchantHookCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final orange = AppColors.coupon;
    return InkWell(
      onTap: () => MerchantInterestSheet.show(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: orange.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: orange.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.merchantHookCardTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.merchantHookCardSub,
                    style: TextStyle(
                      color: orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: orange, size: 20),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            if (ctaLabel != null && onCtaTap != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCtaTap,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(ctaLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 보낸 편지 상세 ───────────────────────────────────────────────────────────
class _SentDetailSheet extends StatelessWidget {
  final Letter letter;
  final VoidCallback? onTrackTap;

  const _SentDetailSheet({required this.letter, this.onTrackTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                letter.senderCountryFlag,
                style: const TextStyle(fontSize: 28),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Builder(
                  builder: (_) {
                    final raw = letter.deliveryEmoji;
                    if (raw == null || raw.isEmpty) {
                      return const Icon(
                        Icons.flight_rounded,
                        color: AppColors.teal,
                        size: 18,
                      );
                    }
                    // "|" 구분 포맷 → 선택된 이모티콘만 모아 표시
                    final parts = raw.split('|');
                    final selected = parts.where((e) => e.isNotEmpty).toList();
                    if (selected.isEmpty) {
                      return const Icon(
                        Icons.flight_rounded,
                        color: AppColors.teal,
                        size: 18,
                      );
                    }
                    return Text(
                      selected.join(' '),
                      style: const TextStyle(fontSize: 18),
                    );
                  },
                ),
              ),
              Text(
                letter.destinationCountryFlag,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '→ ${CountryL10n.localizedName(letter.destinationCountry, l10n.languageCode)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (letter.destinationCity != null &&
                        letter.destinationCity!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            letter.destinationCity!,
                            style: const TextStyle(
                              color: AppColors.teal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    Text(
                      letter.currentStageLabel,
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: letter.overallProgress,
            backgroundColor: AppColors.bgSurface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(letter.overallProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.inboxEtaRemaining(letter.etaLabel),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 배송 경로
          ...letter.segments.asMap().entries.map(
            (e) => _RouteStep(
              segment: e.value,
              isActive: e.key <= letter.currentSegmentIndex,
              isCurrent: e.key == letter.currentSegmentIndex,
              isLastSegment: e.key == letter.segments.length - 1,
              destinationDisplayAddress: letter.destinationDisplayAddress,
            ),
          ),
          // 지도에서 배송 추적 버튼 (배송 중일 때만)
          if (onTrackTap != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                onTrackTap!();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.map_rounded,
                      color: AppColors.teal,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '🗺️ ${l10n.inboxTrackOnMap}',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RouteStep extends StatelessWidget {
  final RouteSegment segment;
  final bool isActive;
  final bool isCurrent;
  final bool isLastSegment;
  final String? destinationDisplayAddress;

  const _RouteStep({
    required this.segment,
    required this.isActive,
    required this.isCurrent,
    this.isLastSegment = false,
    this.destinationDisplayAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.gold.withValues(alpha: 0.2)
                  : isActive
                  ? AppColors.teal.withValues(alpha: 0.1)
                  : AppColors.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent
                    ? AppColors.gold
                    : isActive
                    ? AppColors.teal.withValues(alpha: 0.4)
                    : AppColors.bgSurface,
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                segment.mode.emoji,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${segment.fromName} → ${(isLastSegment && destinationDisplayAddress != null) ? destinationDisplayAddress! : segment.toName}',
              style: TextStyle(
                color: isCurrent
                    ? AppColors.gold
                    : isActive
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCurrent)
            const Icon(Icons.circle, size: 8, color: AppColors.gold),
          if (!isCurrent && isActive)
            const Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: AppColors.success,
            ),
        ],
      ),
    );
  }
}

// ── DM 탭 ─────────────────────────────────────────────────────────────────────
class _DMTab extends StatelessWidget {
  const _DMTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final l10n = AppL10n.of(state.currentUser.languageCode);
        final sessions =
            state.chatSessions.values
                .where(
                  (s) =>
                      s.status == ChatStatus.chatting ||
                      s.status == ChatStatus.pendingAgreement,
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💬', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  l10n.inboxNoDM,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    l10n.inboxNoDMSub,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (_, i) {
            final session = sessions[i];
            final messages = state.getDMConversation(session.partnerId);
            final lastMsg = messages.isNotEmpty ? messages.last : null;

            return GestureDetector(
              onTap: () {
                if (session.status == ChatStatus.pendingAgreement) {
                  // Show agreement dialog
                  showDialog(
                    context: ctx,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.bgCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        '${session.partnerFlag} ${l10n.inboxDMChatWith(session.partnerName)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: Text(
                        l10n.inboxDMStartPrompt,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            state.declineChatInvite(session.partnerId);
                          },
                          child: Text(
                            l10n.inboxCancel,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            state.acceptChatInvite(session.partnerId);
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => DmConversationScreen(
                                  partnerId: session.partnerId,
                                  partnerName: session.partnerName,
                                  partnerFlag: session.partnerFlag,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            l10n.inboxStartChat,
                            style: const TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => DmConversationScreen(
                        partnerId: session.partnerId,
                        partnerName: session.partnerName,
                        partnerFlag: session.partnerFlag,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: session.unreadCount > 0
                        ? AppColors.teal.withValues(alpha: 0.4)
                        : AppColors.bgSurface,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          session.partnerFlag,
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
                              Text(
                                session.partnerName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (session.status == ChatStatus.pendingAgreement)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l10n.inboxInvite,
                                    style: const TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            lastMsg?.content ??
                                (session.status == ChatStatus.pendingAgreement
                                    ? l10n.inboxMutualFollow
                                    : l10n.inboxStartConversation),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (session.unreadCount > 0)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${session.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── 팔로잉/팔로워 탭 (향후 소셜 기능 확장 시 사용) ─────────────────────────
// ignore: unused_element
class _FollowListTab extends StatelessWidget {
  final String title;
  final List<String> userIds;
  final Map<String, dynamic> sessions;

  const _FollowListTab({
    required this.title,
    required this.userIds,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    final isFollowing = title == l10n.inboxFollowing;
    if (userIds.isEmpty) {
      return _EmptyState(
        emoji: isFollowing ? '🔭' : '🌟',
        title: isFollowing ? l10n.inboxNoFollowing : l10n.inboxNoFollowers,
        subtitle: isFollowing
            ? l10n.inboxNoFollowingSub
            : l10n.inboxNoFollowersSub,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: userIds.length,
      itemBuilder: (ctx, i) {
        final uid = userIds[i];
        final session = sessions[uid];
        final name = session?.partnerName ?? uid;
        final flag = session?.partnerFlag ?? '🌍';
        final country = session?.partnerCountry ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.bgSurface),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(flag, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (country.isNotEmpty)
                      Text(
                        '$flag $country',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (session != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    '💬 DM',
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Build 153: 이번 달 수령 편지 진척도 막대.
/// 50통 목표 대비 현재까지 수집 비율 + 색상 티어링:
///   < 50% : teal
///   50–99%: gold
///   >= 100%: gold 애니메이션 (달성)
class _MonthlyProgressBar extends StatelessWidget {
  final int collected;
  final int target;
  final AppL10n l10n;
  const _MonthlyProgressBar({
    required this.collected,
    required this.target,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = target == 0 ? 0.0 : (collected / target).clamp(0.0, 1.0);
    final pct = (ratio * 100).round();
    final reached = collected >= target;
    final color = reached
        ? AppColors.gold
        : (ratio >= 0.5 ? AppColors.gold : AppColors.teal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.inboxMonthlyGoalLabel(collected, target),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            Text(
              reached ? "🏆 $pct%" : "$pct%",
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: AppColors.bgSurface,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
