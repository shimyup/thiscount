#!/usr/bin/env python3
"""
GeoNames 최대 주소 생성기
- 한국(KR): KR.txt 전체 (~62,000개)
- 기타 나라: cities1000.txt (~144,000개)
사용법: python3 generate_cities.py
"""

import json, os, re
from collections import defaultdict

COUNTRY_NAME_MAP = {
    'KR': '대한민국', 'US': '미국', 'JP': '일본', 'CN': '중국',
    'GB': '영국', 'FR': '프랑스', 'DE': '독일', 'IT': '이탈리아',
    'ES': '스페인', 'PT': '포르투갈', 'RU': '러시아', 'BR': '브라질',
    'AU': '호주', 'CA': '캐나다', 'MX': '멕시코', 'AR': '아르헨티나',
    'IN': '인도', 'TH': '태국', 'VN': '베트남', 'ID': '인도네시아',
    'PH': '필리핀', 'MY': '말레이시아', 'SG': '싱가포르', 'TW': '대만',
    'HK': '홍콩', 'NL': '네덜란드', 'SE': '스웨덴', 'NO': '노르웨이',
    'DK': '덴마크', 'FI': '핀란드', 'PL': '폴란드', 'CZ': '체코',
    'AT': '오스트리아', 'CH': '스위스', 'BE': '벨기에', 'GR': '그리스',
    'TR': '터키', 'EG': '이집트', 'ZA': '남아프리카', 'NG': '나이지리아',
    'KE': '케냐', 'MA': '모로코', 'SA': '사우디아라비아', 'AE': '아랍에미리트',
    'IL': '이스라엘', 'IR': '이란', 'PK': '파키스탄', 'BD': '방글라데시',
    'NZ': '뉴질랜드', 'CL': '칠레', 'CO': '콜롬비아', 'PE': '페루',
    'VE': '베네수엘라', 'UA': '우크라이나', 'RO': '루마니아', 'HU': '헝가리',
}

def is_korean(text):
    return bool(re.search(r'[\uAC00-\uD7A3]', text))

def parse_file(filepath, target_country=None):
    """GeoNames 파일 파싱. target_country='KR' 이면 해당 국가만 파싱."""
    cities = defaultdict(list)

    with open(filepath, encoding='utf-8') as f:
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) < 9:
                continue

            feature_cls  = parts[6]
            country_code = parts[8]

            if feature_cls != 'P':
                continue
            if target_country and country_code != target_country:
                continue
            if not target_country and country_code not in COUNTRY_NAME_MAP:
                continue
            if country_code not in COUNTRY_NAME_MAP:
                continue

            try:
                lat = round(float(parts[4]), 4)
                lng = round(float(parts[5]), 4)
            except ValueError:
                continue

            # 표시 이름 결정
            alt_names = parts[3]
            name_ascii = parts[2] if parts[2] else parts[1]
            display_name = name_ascii

            # 한국은 한글 이름 우선
            if country_code == 'KR':
                for alt in alt_names.split(','):
                    alt = alt.strip()
                    if is_korean(alt):
                        display_name = alt
                        break
                else:
                    # alt_names에 없으면 원본 이름(parts[1]) 시도
                    if is_korean(parts[1]):
                        display_name = parts[1]

            population = int(parts[14]) if len(parts) > 14 and parts[14].isdigit() else 0
            country_kr = COUNTRY_NAME_MAP[country_code]
            cities[country_kr].append((display_name, lat, lng, population))

    return cities

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    assets_dir = os.path.join(script_dir, '..', 'assets')
    os.makedirs(assets_dir, exist_ok=True)

    result = defaultdict(list)

    # ── 한국: KR.txt 전체 (최대 주소) ──────────────────────────
    kr_file = os.path.join(script_dir, 'KR.txt')
    if os.path.exists(kr_file):
        print("파싱 중: KR.txt (한국 전체)")
        kr_cities = parse_file(kr_file, target_country='KR')
        for country, entries in kr_cities.items():
            result[country].extend(entries)
        print(f"  → 한국: {len(result.get('대한민국', [])):,}개")
    else:
        print("KR.txt 없음 - cities1000.txt에서 한국 포함")

    # ── 기타 나라: cities1000.txt ───────────────────────────────
    cities_file = os.path.join(script_dir, 'cities1000.txt')
    if os.path.exists(cities_file):
        print("파싱 중: cities1000.txt (전 세계)")
        world_cities = parse_file(cities_file)
        for country, entries in world_cities.items():
            if country == '대한민국' and os.path.exists(kr_file):
                continue  # KR.txt로 이미 처리
            result[country].extend(entries)
    else:
        print("오류: cities1000.txt 없음")
        return

    # ── 정렬 및 직렬화 ──────────────────────────────────────────
    final = {}
    total = 0
    for country, entries in sorted(result.items()):
        entries.sort(key=lambda x: -x[3])  # 인구순 정렬
        final[country] = [
            {'name': e[0], 'lat': e[1], 'lng': e[2]}
            for e in entries
        ]
        total += len(entries)

    # 통계 출력
    print(f"\n총 {len(final)}개 나라, {total:,}개 주소")
    for country, city_list in sorted(final.items(), key=lambda x: -len(x[1]))[:15]:
        print(f"  {country}: {len(city_list):,}개")

    # JSON 저장
    out_path = os.path.join(assets_dir, 'cities.json')
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(final, f, ensure_ascii=False, separators=(',', ':'))

    size_kb = os.path.getsize(out_path) / 1024
    size_mb = size_kb / 1024
    print(f"\n저장 완료: {out_path}")
    print(f"파일 크기: {size_mb:.1f} MB ({size_kb:.0f} KB)")

if __name__ == '__main__':
    main()
