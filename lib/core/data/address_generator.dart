import 'dart:math';

/// 나라별 실제 주소 형식으로 랜덤 주소 생성
/// GeoNames 도시명은 모두 로마자(라틴 알파벳)이므로 모든 형식을 라틴 기반으로 통일
class AddressGenerator {
  static final _rng = Random();

  /// countryName: 한국어 나라 이름 (예: '대한민국', '미국')
  /// cityName: GeoNames 지명 (예: '역삼동', 'Manhattan')
  /// 반환: 실제 주소 형식 문자열
  static String generate(
    String countryName,
    String cityName, {
    String? languageCode,
  }) {
    // 향후 다국어 주소 포맷 확장용 파라미터 (현재 포맷은 국가별 고정)
    final _ = languageCode;
    switch (countryName) {
      case '대한민국':
        return _korea(cityName);
      case '미국':
        return _usa(cityName);
      case '일본':
        return _japan(cityName);
      case '중국':
        return _china(cityName);
      case '프랑스':
        return _france(cityName);
      case '독일':
        return _germany(cityName);
      case '영국':
        return _uk(cityName);
      case '이탈리아':
        return _italy(cityName);
      case '스페인':
        return _spain(cityName);
      case '브라질':
        return _brazil(cityName);
      case '러시아':
        return _russia(cityName);
      case '인도':
        return _india(cityName);
      case '호주':
        return _australia(cityName);
      case '캐나다':
        return _canada(cityName);
      case '멕시코':
        return _mexico(cityName);
      case '터키':
        return _turkey(cityName);
      case '포르투갈':
        return _portugal(cityName);
      case '폴란드':
        return _poland(cityName);
      case '네덜란드':
        return _netherlands(cityName);
      case '벨기에':
        return _belgium(cityName);
      case '스웨덴':
        return _sweden(cityName);
      case '노르웨이':
        return _norway(cityName);
      case '덴마크':
        return _denmark(cityName);
      case '핀란드':
        return _finland(cityName);
      case '스위스':
        return _switzerland(cityName);
      case '오스트리아':
        return _austria(cityName);
      case '그리스':
        return _greece(cityName);
      case '루마니아':
        return _romania(cityName);
      case '우크라이나':
        return _ukraine(cityName);
      case '아르헨티나':
        return _argentina(cityName);
      case '콜롬비아':
        return _colombia(cityName);
      case '페루':
        return _peru(cityName);
      case '칠레':
        return _chile(cityName);
      case '필리핀':
        return _philippines(cityName);
      case '인도네시아':
        return _indonesia(cityName);
      case '태국':
        return _thailand(cityName);
      case '이집트':
        return _egypt(cityName);
      case '체코':
        return _czech(cityName);
      case '헝가리':
        return _hungary(cityName);
      case '남아프리카':
        return _southAfrica(cityName);
      case '나이지리아':
        return _nigeria(cityName);
      case '이란':
        return _iran(cityName);
      case '베트남':
        return _vietnam(cityName);
      case '말레이시아':
        return _malaysia(cityName);
      case '뉴질랜드':
        return _newZealand(cityName);
      case '파키스탄':
        return _pakistan(cityName);
      case '모로코':
        return _morocco(cityName);
      case '이스라엘':
        return _israel(cityName);
      case '베네수엘라':
        return _venezuela(cityName);
      case '케냐':
        return _kenya(cityName);
      case '홍콩':
        return _hongKong(cityName);
      case '방글라데시':
        return _bangladesh(cityName);
      case '사우디아라비아':
        return _saudiArabia(cityName);
      case '싱가포르':
        return _singapore(cityName);
      case '아랍에미리트':
        return _uae(cityName);
      case '대만':
        return _taiwan(cityName);
      default:
        return _generic(cityName);
    }
  }

  static int _n(int max) => _rng.nextInt(max) + 1;
  static T _pick<T>(List<T> list) => list[_rng.nextInt(list.length)];

  // ── 한국: 역삼동 234-12 ────────────────────────────────────────────────────
  static String _korea(String dong) {
    final n = _n(999);
    final h = _n(50);
    return '$dong $n-$h';
  }

  // ── 미국: 1234 Springfield Ave ───────────────────────────────────────────
  static String _usa(String city) {
    final n = _n(9999);
    final type = _pick(['St', 'Ave', 'Blvd', 'Dr', 'Ln', 'Way', 'Rd', 'Ct']);
    return '$n $city $type';
  }

  // ── 일본: Shibuya 1-2-3 (GeoNames 로마자 표기) ───────────────────────────
  static String _japan(String area) {
    final chome = _n(9);
    final ban = _n(30);
    final go = _n(20);
    return '$area $chome-$ban-$go';
  }

  // ── 중국: No.42 Wushan Road (GeoNames Pinyin 표기) ───────────────────────
  static String _china(String area) {
    final n = _n(999);
    final type = _pick(['Road', 'Street', 'Avenue', 'Lane', 'Boulevard']);
    return 'No.$n $area $type';
  }

  // ── 프랑스: 12 Rue de la Paix ─────────────────────────────────────────────
  static String _france(String city) {
    final n = _n(200);
    final type = _pick(['Rue', 'Avenue', 'Boulevard', 'Place', 'Impasse']);
    return '$n $type $city';
  }

  // ── 독일: Hamburg Str. 42 (공백으로 자연스럽게 분리) ──────────────────────
  static String _germany(String city) {
    final n = _n(200);
    final type = _pick(['Str.', 'Gasse', 'Weg', 'Allee', 'Platz']);
    return '$city $type $n';
  }

  // ── 영국: 24 High Street ──────────────────────────────────────────────────
  static String _uk(String city) {
    final n = _n(300);
    final type = _pick(['Street', 'Road', 'Lane', 'Avenue', 'Close', 'Drive']);
    return '$n $city $type';
  }

  // ── 이탈리아: Via Roma 15 ─────────────────────────────────────────────────
  static String _italy(String city) {
    final n = _n(200);
    final type = _pick(['Via', 'Corso', 'Piazza', 'Viale', 'Vicolo']);
    return '$type $city, $n';
  }

  // ── 스페인: Calle Mayor 8 ─────────────────────────────────────────────────
  static String _spain(String city) {
    final n = _n(200);
    final type = _pick(['Calle', 'Avenida', 'Plaza', 'Paseo', 'Carrer']);
    return '$type $city, $n';
  }

  // ── 브라질: Rua das Flores, 234 ──────────────────────────────────────────
  static String _brazil(String city) {
    final n = _n(2000);
    final type = _pick(['Rua', 'Avenida', 'Estrada', 'Travessa', 'Alameda']);
    return '$type $city, $n';
  }

  // ── 러시아: 42 Nadym Street (GeoNames 로마자 → 라틴 형식) ─────────────────
  static String _russia(String city) {
    final n = _n(200);
    final type = _pick(['Street', 'Avenue', 'Boulevard', 'Lane', 'Road']);
    return '$n $city $type';
  }

  // ── 인도: 42 MG Road ──────────────────────────────────────────────────────
  static String _india(String city) {
    final n = _n(500);
    final type = _pick(['Road', 'Street', 'Nagar', 'Marg', 'Colony']);
    return '$n $city $type';
  }

  // ── 호주: 15 Collins Street ───────────────────────────────────────────────
  static String _australia(String city) {
    final n = _n(500);
    final type = _pick(['Street', 'Road', 'Avenue', 'Drive', 'Place', 'Court']);
    return '$n $city $type';
  }

  // ── 캐나다: 220 Bay Street ────────────────────────────────────────────────
  static String _canada(String city) {
    final n = _n(9999);
    final type = _pick(['Street', 'Avenue', 'Boulevard', 'Drive', 'Road']);
    return '$n $city $type';
  }

  // ── 멕시코: Calle Hidalgo #45 ─────────────────────────────────────────────
  static String _mexico(String city) {
    final n = _n(500);
    final type = _pick([
      'Calle',
      'Avenida',
      'Boulevard',
      'Callejón',
      'Andador',
    ]);
    return '$type $city #$n';
  }

  // ── 터키: Istanbul Cad. No:12 ────────────────────────────────────────────
  static String _turkey(String city) {
    final n = _n(300);
    final type = _pick(['Cad.', 'Sok.', 'Bul.', 'Mah.', 'Cd.']);
    return '$city $type No:$n';
  }

  // ── 포르투갈: Rua Augusta, 15 ────────────────────────────────────────────
  static String _portugal(String city) {
    final n = _n(300);
    final type = _pick(['Rua', 'Avenida', 'Largo', 'Praça', 'Travessa']);
    return '$type $city, $n';
  }

  // ── 폴란드: ul. Marszałkowska 28 ─────────────────────────────────────────
  static String _poland(String city) {
    final n = _n(200);
    final type = _pick(['ul.', 'al.', 'pl.', 'os.', 'rondo']);
    return '$type $city $n';
  }

  // ── 네덜란드: Amsterdam Straat 15 (공백으로 분리) ─────────────────────────
  static String _netherlands(String city) {
    final n = _n(400);
    final type = _pick(['Straat', 'Gracht', 'Laan', 'Weg', 'Plein']);
    return '$city $type $n';
  }

  // ── 벨기에: Rue Neuve 34 ─────────────────────────────────────────────────
  static String _belgium(String city) {
    final n = _n(200);
    final type = _pick(['Rue', 'Avenue', 'Boulevard', 'Chaussée', 'Place']);
    return '$type $city $n';
  }

  // ── 스웨덴: Stockholm Gatan 12 (공백으로 분리) ───────────────────────────
  static String _sweden(String city) {
    final n = _n(200);
    final type = _pick(['Gatan', 'Vägen', 'Torget', 'Stigen', 'Allén']);
    return '$city $type $n';
  }

  // ── 노르웨이: Oslo Veien 8 (공백으로 분리) ───────────────────────────────
  static String _norway(String city) {
    final n = _n(200);
    final type = _pick(['Veien', 'Gata', 'Gate', 'Torget', 'Stien']);
    return '$city $type $n';
  }

  // ── 덴마크: Copenhagen Gade 15 (공백으로 분리) ───────────────────────────
  static String _denmark(String city) {
    final n = _n(200);
    final type = _pick(['Gade', 'Vej', 'Allé', 'Plads', 'Stræde']);
    return '$city $type $n';
  }

  // ── 핀란드: Helsinki Katu 5 (공백으로 분리) ──────────────────────────────
  static String _finland(String city) {
    final n = _n(200);
    final type = _pick(['Katu', 'Tie', 'Tori', 'Kuja', 'Polku']);
    return '$city $type $n';
  }

  // ── 스위스: Zurich Str. 12 (공백으로 분리) ───────────────────────────────
  static String _switzerland(String city) {
    final n = _n(200);
    final type = _pick(['Str.', 'Gasse', 'Weg', 'Allee', 'Platz']);
    return '$city $type $n';
  }

  // ── 오스트리아: Wien Straße 8 ────────────────────────────────────────────
  static String _austria(String city) {
    final n = _n(200);
    final type = _pick(['Straße', 'Gasse', 'Weg', 'Allee', 'Platz']);
    return '$city $type $n';
  }

  // ── 그리스: 15 Athens Street (GeoNames 로마자 → 라틴 형식) ─────────────────
  static String _greece(String city) {
    final n = _n(200);
    final type = _pick(['Street', 'Avenue', 'Square', 'Road', 'Boulevard']);
    return '$n $city $type';
  }

  // ── 루마니아: Str. Unirii nr. 12 ─────────────────────────────────────────
  static String _romania(String city) {
    final n = _n(200);
    final type = _pick(['Str.', 'Bd.', 'Calea', 'Aleea', 'Piața']);
    return '$type $city nr. $n';
  }

  // ── 우크라이나: 42 Kyiv Street (GeoNames 로마자 → 라틴 형식) ────────────────
  static String _ukraine(String city) {
    final n = _n(200);
    final type = _pick(['Street', 'Avenue', 'Boulevard', 'Lane', 'Road']);
    return '$n $city $type';
  }

  // ── 아르헨티나: Av. Florida 234 ──────────────────────────────────────────
  static String _argentina(String city) {
    final n = _n(2000);
    final type = _pick(['Av.', 'Calle', 'Paseo', 'Ruta']);
    return '$type $city $n';
  }

  // ── 콜롬비아: Carrera 7 #32-15 ───────────────────────────────────────────
  static String _colombia(String city) {
    final c = _n(120);
    final n1 = _n(99);
    final n2 = _n(99);
    return 'Carrera $c #$n1-$n2 ($city)';
  }

  // ── 페루: Jr. de la Unión 345 ────────────────────────────────────────────
  static String _peru(String city) {
    final n = _n(999);
    final type = _pick(['Jr.', 'Av.', 'Calle', 'Psje.']);
    return '$type $city $n';
  }

  // ── 칠레: Av. Libertador 150 ─────────────────────────────────────────────
  static String _chile(String city) {
    final n = _n(2000);
    final type = _pick(['Av.', 'Calle', 'Pasaje', 'Camino']);
    return '$type $city $n';
  }

  // ── 필리핀: 15 Rizal Street ───────────────────────────────────────────────
  static String _philippines(String city) {
    final n = _n(500);
    final type = _pick(['Street', 'Avenue', 'Boulevard', 'Road', 'Lane']);
    return '$n $city $type';
  }

  // ── 인도네시아: Jl. Sudirman No.45 ───────────────────────────────────────
  static String _indonesia(String city) {
    final n = _n(500);
    final type = _pick(['Jl.', 'Gang', 'Jalan']);
    return '$type $city No.$n';
  }

  // ── 태국: 15 Bangkok Road (GeoNames 로마자 → 라틴 형식) ──────────────────
  static String _thailand(String city) {
    final n = _n(500);
    final type = _pick(['Road', 'Street', 'Soi', 'Lane', 'Avenue']);
    return '$n $city $type';
  }

  // ── 이집트: 42 Cairo Street (GeoNames 로마자 → 라틴 형식) ────────────────
  static String _egypt(String city) {
    final n = _n(200);
    final type = _pick(['Street', 'Road', 'Square', 'Avenue']);
    return '$n $city $type';
  }

  // ── 체코: Václavské náměstí 12 ───────────────────────────────────────────
  static String _czech(String city) {
    final n = _n(200);
    final type = _pick(['ulice', 'náměstí', 'třída', 'nábřeží']);
    return '$city $type $n';
  }

  // ── 헝가리: Váci utca 15 ─────────────────────────────────────────────────
  static String _hungary(String city) {
    final n = _n(200);
    final type = _pick(['utca', 'út', 'tér', 'köz', 'körút']);
    return '$city $type $n.';
  }

  // ── 남아프리카: 12 Bree Street ────────────────────────────────────────────
  static String _southAfrica(String city) {
    final n = _n(500);
    final type = _pick(['Street', 'Road', 'Avenue', 'Drive', 'Lane']);
    return '$n $city $type';
  }

  // ── 나이지리아: 15 Broad Street ───────────────────────────────────────────
  static String _nigeria(String city) {
    final n = _n(500);
    final type = _pick(['Street', 'Road', 'Avenue', 'Way', 'Close']);
    return '$n $city $type';
  }

  // ── 이란: 42 Tehran Street (GeoNames 로마자 → 라틴 형식) ─────────────────
  static String _iran(String city) {
    final n = _n(400);
    final type = _pick(['Street', 'Avenue', 'Boulevard', 'Lane', 'Road']);
    return '$n $city $type';
  }

  // ── 베트남: 15 Đường Lê Lợi ──────────────────────────────────────────────
  static String _vietnam(String city) {
    final n = _n(500);
    final type = _pick(['Đường', 'Phố', 'Ngõ', 'Hẻm']);
    return '$n $type $city';
  }

  // ── 말레이시아: 12 Jalan Bukit Bintang ────────────────────────────────────
  static String _malaysia(String city) {
    final n = _n(400);
    final type = _pick(['Jalan', 'Lorong', 'Persiaran', 'Lebuh']);
    return '$n $type $city';
  }

  // ── 뉴질랜드: 15 Queen Street ─────────────────────────────────────────────
  static String _newZealand(String city) {
    final n = _n(500);
    final type = _pick([
      'Street',
      'Road',
      'Avenue',
      'Drive',
      'Place',
      'Terrace',
    ]);
    return '$n $city $type';
  }

  // ── 파키스탄: House 12, Street 5, Gulberg ────────────────────────────────
  static String _pakistan(String city) {
    final house = _n(300);
    final street = _n(50);
    return 'House $house, Street $street, $city';
  }

  // ── 모로코: 15 Rue Hassan II ──────────────────────────────────────────────
  static String _morocco(String city) {
    final n = _n(300);
    final type = _pick(['Rue', 'Avenue', 'Boulevard', 'Impasse', 'Derb']);
    return '$n $type $city';
  }

  // ── 이스라엘: 42 Jerusalem Street (GeoNames 로마자 → 라틴 형식) ────────────
  static String _israel(String city) {
    final n = _n(300);
    final type = _pick(['Street', 'Road', 'Boulevard', 'Avenue', 'Lane']);
    return '$n $city $type';
  }

  // ── 베네수엘라: Av. Bolívar #45 ───────────────────────────────────────────
  static String _venezuela(String city) {
    final n = _n(500);
    final type = _pick(['Av.', 'Calle', 'Carrera', 'Bulevar']);
    return '$type $city #$n';
  }

  // ── 케냐: 12 Kenyatta Avenue ─────────────────────────────────────────────
  static String _kenya(String city) {
    final n = _n(400);
    final type = _pick(['Avenue', 'Road', 'Street', 'Lane', 'Close']);
    return '$n $city $type';
  }

  // ── 홍콩: 15 Nathan Road ─────────────────────────────────────────────────
  static String _hongKong(String city) {
    final n = _n(300);
    final type = _pick(['Road', 'Street', 'Avenue', 'Lane']);
    return '$n $city $type';
  }

  // ── 방글라데시: House 12, Road 5, Dhanmondi ──────────────────────────────
  static String _bangladesh(String city) {
    final house = _n(200);
    final road = _n(30);
    return 'House $house, Road $road, $city';
  }

  // ── 사우디아라비아: 42 Riyadh Street (GeoNames 로마자 → 라틴 형식) ──────────
  static String _saudiArabia(String city) {
    final n = _n(300);
    final type = _pick(['Street', 'Road', 'Avenue', 'Boulevard']);
    return '$n $city $type';
  }

  // ── 싱가포르: 15 Orchard Road ─────────────────────────────────────────────
  static String _singapore(String city) {
    final n = _n(400);
    final type = _pick(['Road', 'Street', 'Avenue', 'Drive', 'Lane', 'Way']);
    return '$n $city $type';
  }

  // ── 아랍에미리트: Villa 15, Al Wasl Road ─────────────────────────────────
  static String _uae(String city) {
    final n = _n(300);
    final type = _pick(['Road', 'Street', 'Avenue', 'Boulevard']);
    return 'Villa $n, $city $type';
  }

  // ── 대만: No.42 Taipei Road (GeoNames Pinyin 표기 → 라틴 형식) ─────────────
  static String _taiwan(String city) {
    final n = _n(500);
    final type = _pick(['Road', 'Street', 'Lane', 'Avenue', 'Boulevard']);
    return 'No.$n $city $type';
  }

  // ── 기본: City 123 ────────────────────────────────────────────────────────
  static String _generic(String city) {
    final n = _n(999);
    final type = _pick(['Street', 'Road', 'Avenue']);
    return '$n $city $type';
  }
}
