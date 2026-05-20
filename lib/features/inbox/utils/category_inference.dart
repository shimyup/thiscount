// Build 315: 7개 카테고리 (식당/카페/뷰티/패션/IT/행사/기타) 키워드 매칭 추론.
// inbox_screen 의 필터링 + app_state pickUpLetter 시 자동 저장에 공유.

// 키 = LetterFilterType enum 의 `name` 과 일치 ('food', 'cafe', ...).
const Map<String, List<String>> categoryKeywords = {
  'food': [
    '음식', '맛집', '식당', '레스토랑', '한식', '중식', '일식', '양식',
    '치킨', '피자', '버거', '파스타', '마라', '고기', '회', '초밥',
    '라면', '분식', '국밥', '찌개', '국수', '면', '도시락', '런치',
    '디너', '야식', '스테이크', '정식', '백반', '음식점', '분식점',
    '뷔페', '뷔페식',
    'food', 'restaurant', 'dish', 'meal', 'lunch', 'dinner', 'snack',
    'burger', 'pizza', 'pasta', 'ramen', 'sushi', 'bbq', 'steak',
    'dining', 'cuisine', 'eatery',
  ],
  'cafe': [
    '카페', '커피', '라떼', '에스프레소', '아메리카노', '디저트',
    '케이크', '와플', '베이커리', '빵', '도넛', '마카롱', '스무디',
    '주스', '에이드', '녹차', '홍차', '허브티', '브런치',
    'cafe', 'coffee', 'latte', 'cappuccino', 'espresso', 'americano',
    'dessert', 'bakery', 'donut', 'macaron', 'smoothie', 'juice',
    'tea', 'brunch',
  ],
  'beauty': [
    '뷰티', '화장품', '미용', '헤어', '네일', '마사지', '에스테틱',
    '왁싱', '피부', '스킨', '메이크업', '립스틱', '마스크팩', '선크림',
    '토너', '에센스', '샴푸', '린스', '트리트먼트', '향수', '퍼퓸',
    '퍼머', '염색', '스파',
    'beauty', 'cosmetic', 'salon', 'hair', 'nail', 'spa', 'massage',
    'skin', 'makeup', 'lipstick', 'cushion', 'mask', 'serum', 'shampoo',
    'perfume',
  ],
  'fashion': [
    '패션', '옷', '의류', '신발', '가방', '액세서리', '쥬얼리', '주얼리',
    '모자', '양말', '티셔츠', '셔츠', '원피스', '스커트', '바지',
    '청바지', '코트', '재킷', '후드', '맨투맨', '운동화', '구두',
    '샌들', '부츠', '벨트', '스카프', '선글라스', '시계',
    'fashion', 'clothing', 'clothes', 'shoes', 'bag', 'accessory',
    'jewelry', 'hat', 'tshirt', 'shirt', 'dress', 'skirt', 'pants',
    'jeans', 'coat', 'jacket', 'hoodie', 'sneakers', 'heels', 'boots',
    'watch',
  ],
  'it': [
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
  'event': [
    '행사', '이벤트', '공연', '콘서트', '뮤지컬', '연극', '전시',
    '전시회', '박람회', '페스티벌', '축제', '팝업', '팝업스토어',
    '워크샵', '워크숍', '세미나', '컨퍼런스', '강연', '클래스',
    '체험', '체험학습', '관람', '티켓', '입장권',
    'event', 'concert', 'festival', 'exhibition', 'expo', 'show',
    'popup', 'workshop', 'seminar', 'conference', 'class', 'ticket',
    'admission', 'performance',
  ],
};

const List<String> _orderedCategories = [
  'food',
  'cafe',
  'beauty',
  'fashion',
  'it',
  'event',
];

/// 단순 keyword heuristic: letter 콘텐츠를 카테고리 키워드와 매칭.
/// 어느 카테고리도 매칭 안 되면 'other' 반환.
/// 영문 키워드는 단어 경계(\b) 매칭, 한글은 부분 문자열.
String inferCategoryTagFromText(String? content, String? senderName, String? redemptionInfo) {
  final hay = ('${content ?? ''} ${senderName ?? ''} ${redemptionInfo ?? ''}')
      .toLowerCase();
  for (final cat in _orderedCategories) {
    final kws = categoryKeywords[cat];
    if (kws == null || kws.isEmpty) continue;
    for (final k in kws) {
      final lower = k.toLowerCase();
      final isAscii = lower.runes.every((r) => r < 0x80);
      final hit = isAscii
          ? RegExp(r'\b' + RegExp.escape(lower) + r'\b').hasMatch(hay)
          : hay.contains(lower);
      if (hit) return cat;
    }
  }
  return 'other';
}
