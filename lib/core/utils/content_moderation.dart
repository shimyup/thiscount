/// Build 459: 발송 본문 금칙어 검사 — compose 와 발송 마법사가 공유.
/// (이전엔 compose_screen 내부 private 라 신규 발송 표면이 재사용 불가했음.
/// 로직/리스트는 compose Build 397 구현 그대로 이동.)
class ContentModeration {
  ContentModeration._();

  static const List<String> bannedWords = [
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
    // Build 375 (PR-DD4 audit msg P1-8): AR/TR/IT/HI/TH 추가 — PR-AA2 가
    //   user-facing 14언어 정리했으나 banned word 사전이 9언어만 → 5언어
    //   사용자 욕설 leak.
    // العربية
    'كس', 'زب', 'شرموطة', 'كلب', 'لعنة', 'احمق', 'قحبة', 'منيك',
    // Türkçe
    'siktir', 'amına', 'orospu', 'piç', 'aptal', 'göt', 'yarrak', 'kahpe',
    // Italiano
    'cazzo', 'merda', 'vaffanculo', 'stronzo', 'coglione', 'puttana', 'fanculo',
    'figa', 'troia',
    // हिन्दी
    'मादरचोद', 'भोसडी', 'चूतिया', 'गांडू', 'रंडी', 'हरामी', 'कमीना',
    // ภาษาไทย
    'ควย', 'หี', 'แม่ง', 'เหี้ย', 'สัส', 'อีดอก', 'มึง',
    // Spam patterns (multilingual)
    '카지노', '도박', '대출', '비트코인 투자', '클릭하세요',
    'casino', 'gambling', 'bitcoin invest', 'click here', 'free money',
    'カジノ', '赌博', '賭博',
  ];

  static bool hasBannedWords(String text) {
    // Build 397 (PR-HH6): 영문/숫자 word 는 \b boundary — "class/passion" 같은
    //   정상 단어 false-positive 방지. CJK/Arabic/Thai/Hindi 는 normalized
    //   substring 매칭(우회 차단).
    final lowerOriginal = text.toLowerCase();
    final normalized = lowerOriginal
        .replaceAll(RegExp(r'[^a-z0-9À-ſ가-힯぀-ヿ一-鿿؀-ۿ฀-๿ऀ-ॿ]'), '');
    return bannedWords.any((w) {
      final wl = w.toLowerCase();
      final isAsciiWord = RegExp(r'^[a-z0-9 \-]+$').hasMatch(wl);
      if (isAsciiWord) {
        final pattern = r'\b' + RegExp.escape(wl) + r'\b';
        if (RegExp(pattern).hasMatch(lowerOriginal)) return true;
      } else {
        if (lowerOriginal.contains(wl)) return true;
        final wn = wl.replaceAll(
            RegExp(r'[^a-z0-9À-ſ가-힯぀-ヿ一-鿿؀-ۿ฀-๿ऀ-ॿ]'), '');
        if (wn.isNotEmpty && normalized.contains(wn)) return true;
      }
      return false;
    });
  }
}
