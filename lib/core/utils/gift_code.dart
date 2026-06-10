/// Build 453: 친구 쿠폰 선물 — 선물 코드(=서버 letter id) 추출 유틸.
///
/// 공유 메시지 전체를 붙여넣어도 동작하도록, 텍스트에서 letter id 패턴
/// (`sent_<ms>_<hex>`) 을 찾아낸다. 패턴이 없으면 trim 한 원문을 그대로
/// 반환(사용자가 id 만 입력한 경우).
class GiftCode {
  GiftCode._();

  static final RegExp _idPattern = RegExp(r'sent_\d{10,}_[a-f0-9]{4,}');

  /// 붙여넣은 텍스트에서 선물 코드(letter id)를 추출. 빈 입력이면 null.
  static String? extract(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final match = _idPattern.firstMatch(text);
    if (match != null) return match.group(0);
    // 패턴 미일치 — 공백 없는 단일 토큰이면 그대로 시도(미래 id 형식 허용).
    if (!text.contains(RegExp(r'\s'))) return text;
    return null;
  }

  /// 이 letter id 가 선물 가능한 서버 letter 인지 (로컬 전용 zone/스탬프 보상/
  /// 웰컴 letter 는 서버에 없어 선물 불가).
  static bool isGiftableId(String id) => id.startsWith('sent_');
}
