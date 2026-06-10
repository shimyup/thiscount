import 'package:flutter_test/flutter_test.dart';
import 'package:thiscount/core/utils/gift_code.dart';

void main() {
  group('GiftCode (Build 453 친구 선물)', () {
    test('공유 메시지 전체에서 letter id 추출', () {
      const msg = '🎁 Thiscount 쿠폰 선물이 도착했어요!\n'
          '"아메리카노 50% 할인"\n'
          '선물 코드: sent_1717000000000_ab12cd34';
      expect(GiftCode.extract(msg), 'sent_1717000000000_ab12cd34');
    });

    test('id 만 입력(앞뒤 공백)해도 추출', () {
      expect(
        GiftCode.extract('  sent_1717000000000_ab12cd34  '),
        'sent_1717000000000_ab12cd34',
      );
    });

    test('빈 입력 → null', () {
      expect(GiftCode.extract('   '), null);
    });

    test('패턴 없는 여러 단어 문장 → null', () {
      expect(GiftCode.extract('안녕하세요 쿠폰 주세요'), null);
    });

    test('패턴 없는 단일 토큰은 그대로 시도(미래 id 형식 허용)', () {
      expect(GiftCode.extract('futureid_xyz'), 'futureid_xyz');
    });

    test('isGiftableId — 서버 letter(sent_*)만 true', () {
      expect(GiftCode.isGiftableId('sent_1717_ab12'), true);
      expect(GiftCode.isGiftableId('brand_zone_z1_1717_ab'), false);
      expect(GiftCode.isGiftableId('stamp_reward_1717_ab'), false);
      expect(GiftCode.isGiftableId('gift_sent_1_2'), false);
    });
  });
}
