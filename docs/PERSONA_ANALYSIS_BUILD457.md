# 페르소나 분석 (Build 457) — 마케터(브랜드) vs 소비자(일반)

## [마케터] 동네 카페 사장 — 가입 후 첫 캠페인까지

### 강점
- **가입 첫 화면의 계정 종류 비교 카드 — 사장이 헤매지 않고 Brand 경로 진입**
  lib/features/auth/screens/auth_screen.dart:1897-1927 — 🆓 일반 vs 🏷️ 브랜드 카드가 bullet 3개씩("📣 위치 지정 대량 발송 / 📊 픽업·사용률 실시간 분석 / 🎯 매장 zone 자동 발송", app_localizations.dart:290-339)으로 나란히 비교되고, 카드 탭 한 번이 곧 선택. 가입 도중에도 _SelectedAccountTypeBar(1942-1948)의 '← 다른 계정 종류 선택'으로 복귀 가능. 잘못 가입해도 isNewUser 분기에서 Brand→Free 강등 안 되도록 isBrand 보존(299-302). 카페 사장이 '사업자용이 따로 있구나'를 첫 화면에서 인지한다.
- **Brand 전용 티어 투어가 사장 언어로 말한다**
  lib/features/onboarding/tier_tour_screen.dart:73-103 — 슬라이드 1 "동네 손님에게 쿠폰을 뿌리세요"(일반홍보/할인권/교환권 3종 bullet), 슬라이드 2 "매장 위치를 고정하세요"(자동 발송), 슬라이드 3 "코드 한 번 등록, 성과는 인사이트에서"(POS 1회 등록). '캠페인·POS·인사이트'라는 사장의 실제 업무 어휘로 3장 안에 발송→자동화→정산 흐름을 요약. Free/Premium과 분리된 투어라 관심 없는 줍기 설명을 안 본다(_slides 분기 71-159).
- **발송 직후 할인코드 reveal 다이얼로그 — POS 등록을 놓칠 수 없게**
  compose_screen.dart:2551-2676 — 코드가 monospace 22pt로 크게 뜨고(2596-2606), '이 코드를 매장 POS의 "쿠폰/할인" 항목에 1회 등록하세요'(app_localizations.dart:29745) + 복사 버튼(SecureClipboard, 2640-2669). 단건(2135-2140)·특급+대량(1806-1811)·일반 대량 모두 동일 reveal. 토글 첫 ON 시에도 POS 셋업 가이드 다이얼로그(_showRedemptionCodeGuide 2682, 5197-5201)가 떠서 '이 토글이 뭘 하는지'를 켜기 전에 설명한다. 코드 발급-등록-사용의 사슬이 화면에 명시돼 있다.
- **카테고리별 본문 placeholder + 쿠폰은 최소 글자 완화 — 빈 화면 공포 제거**
  compose_screen.dart:2179-2199 — 할인권 선택 시 "할인 내용을 한 줄로 적어주세요 (예: 전 메뉴 20% 할인)\n할인코드는 아래에서 자동 발급돼요", 교환권은 "아메리카노 1잔 무료 교환" 예시. 일반홍보 10자 최소 규칙도 할인권/교환권은 1자로 완화(1593-1598, 7702-7705)해 버튼 게이트와 발송 검증이 일치. 글쓰기가 부담스러운 사장이 '전 메뉴 20% 할인' 한 줄만 쳐도 발송된다.
- **AI 쿠폰 생성 — 업종/설명 2칸 입력으로 카피·혜택 초안 자동 완성**
  compose_screen.dart:1408-1550 — Brand + 함수 설정 시 본문 위에 ✨ 버튼(3603-3607). 다이얼로그는 brandName 프리필(1438-1439) + 설명 + 업종 7택. 결과가 본문/redemptionInfo에 자동 주입되고 혜택이 생성되면 '일반→할인권' 자동 승격(1531-1534). 빈 입력 차단·rate-limit 별도 안내·빈 응답 가드(1498-1548)까지. 마케팅 카피를 못 쓰는 사장의 진입 장벽을 정확히 겨냥한 기능.
- **0통 발송 가짜 성공 차단 + 부분 발송 경고 — 예산 빠듯한 사장의 신뢰 보호**
  compose_screen.dart:1791-1798 — 쿼터 소진으로 0통이면 _clearDraft/햅틱/코드 reveal 전에 차단하고 한도 메시지 표시(phantom POS 코드 방지). 1812-1820 — 요청 통수 대비 부족 시 "요청 N통 중 M통만 발송됐어요" 경고 스낵바. 발송 버튼 위에 오늘/월간 잔여 통수 상시 표기(7728-7735) + 소진 시 경고색(7757-7759). 돈 쓴 만큼 나갔는지가 항상 보인다.

### 불편
- [치명] **기본 목적지가 '내 나라 제외 랜덤 해외' — 동네 카페의 첫 캠페인이 외국으로 날아갈 수 있다**
  compose_screen.dart:644-648 initState가 randomDestination()으로 시작하고, 첫 프레임 후 655에서 _pickRandomDestination(excludeCountry: state.currentUser.country)로 '사용자 나라를 제외'한 랜덤 국가를 다시 뽑는다. _isRandom 기본 true(:90)이며 canSend 게이트(7712-7716)에 목적지 조건이 전혀 없어, 사장이 목적지 카드를 건드리지 않고 본문만 쓰고 '보내기 → 🌍'를 누르면 그대로 발송된다. 200m 줍기 기반 동네 쿠폰 모델과 정면 충돌 — 우리 카페 20% 할인권이 해외 랜덤 도시에 떨어지고, 사장은 월 쿼터만 소모한 채 '픽업 0'을 보게 된다. 매장 위치 발송은 ExactDrop(유료 크레딧, 2232-2237) 또는 auto-zone 카드(5611-5748)를 스스로 찾아야 한다.
- [높음] **체크리스트 1단계 '사업자 인증 제출'이 일반 Brand 유저에겐 도달 불가능한 화면에 있다**
  brand_checklist_card.dart:109-114가 '1️⃣ 사업자 인증 제출'을 첫 과제로 제시하지만, submitBrandVerification 호출 UI(_showBrandVerificationSheet)는 admin_screen.dart:505, 995에만 존재하고 AdminScreen은 admin email 게이트(admin_screen.dart:168-173: kDebugMode 테스트 이메일 또는 BETA_ADMIN_EMAIL)로 막혀 있다. 체크리스트 _step 위젯에는 onTap도 없어(136-209) 탭해도 아무 데도 못 간다. 사장은 영영 1/3에서 시작해 '뭘 제출하라는 거지?'로 끝난다 — ✅ 신뢰 뱃지를 가장 원할 신규 사장에게 막힌 길.
- [높음] **가입 시 '매장 이름'을 묻지 않는다 — 로그인 아이디가 그대로 브랜드명으로 노출**
  auth_screen.dart:1546-1549 — Brand 가입 시 brandName: _usernameCtrl.text.trim() (username fallback). 주석 스스로 "브랜드명 별도 입력 step 은 후속 PR 에서 강화 예정"(1544-1545). 아이디 규칙(영숫자, authUsernameRule 헬퍼 1974-1985)에 맞춰 'happycafe77' 같은 ID를 지은 사장은 손님 지도/편지에 그 ID가 상호로 찍힌다. 한글 상호('행복카페')는 아이디로 쓸 수 없으니 사실상 모든 한국 가게명이 깨진다. 업종·주소도 가입 단계에 없어 첫 캠페인에서야 업종 칩(4828-4867)을 처음 만난다.
- [중간] **대량 발송의 축이 '나라당 발송 수' — 동네 사장에게 무의미한 멘탈 모델**
  compose_screen.dart:6510-6749 — 대량 패널의 유일한 입력이 '📮 나라당 발송 수'(composeSendPerCountry) ±스테퍼(1~50)와 국가 타깃이고, 랜덤 모드 요약은 '🎲 전 세계 무작위 N통'(6696-6710)이다. 글로벌 편지 앱의 유산이 그대로 남아, '우리 동네 반경 500m에 50통' 같은 사장의 실제 니즈를 표현할 입력이 없다. 동네 타게팅은 ExactDrop 단일 좌표(유료) 또는 auto-zone(300m/2km 2택, 5705-5711)뿐인데 셋이 각각 다른 카드에 흩어져 있어 어떤 걸 써야 동네에 뿌려지는지 비교 불가.
- [중간] **Brand 투어·compose 핵심 카피가 ko/en 2언어 하드코딩 — 12개 언어 사장은 영어를 본다**
  app_localizations.dart:58 koEn()은 languageCode=='ko'면 한국어, 아니면 무조건 영어. tier_tour_screen.dart 전체 슬라이드(74-158), compose의 '매장 위치 · 자동 발송' 카드(5627-5694), 업종 라벨(4925), 발송 종류 라벨(4942), 자동발송 반경/수량 칩(5718-5732), AI 빈입력 안내(1502-1505)가 모두 koEn. 나머지 앱은 14언어 _t() 패턴(예: brandChecklist 5865-5962)인데 Brand 온보딩 동선만 일본/프랑스 사장에게 영어로 나간다 — 첫인상 구간에서의 i18n 역행.
- [중간] **첫 캠페인까지 한 화면에 결정 9개+ — 단계 안내 없는 롱 스크롤**
  compose_screen.dart:2439-2521 빌드 순서 — 목적지 카드 / 업종 칩 6개 / 발송종류 3택 / 사용방법 수동입력 vs 자동발급 토글(+가이드 다이얼로그 확인) / 유효기간 / 매장위치·자동발송 골드 카드(반경+수량) / 대량·특급 토글 / 접힘 옵션 / 본문 / 발송. 카페 사장의 최단 경로(캠페인 탭→FAB '빠른 발송'(brand_campaign_screen.dart:148-158)→할인권)도 탭 8~9회 + 본문 입력이며, 어떤 항목이 필수이고 어떤 게 선택인지 시각 위계가 없다. 점심 장사 전 5분에 보내려던 사장은 목적지 함정(위 치명 이슈)까지 겹쳐 실수하기 딱 좋은 구조. 8387줄 단일 화면이라는 코드 구조가 UI 과밀을 그대로 반영한다.
- [낮음] **코드 reveal 다이얼로그의 '인사이트에서 다시 확인' 약속에 실제 버튼이 없다**
  compose_screen.dart:2540-2543 주석은 "+ BrandInsights 진입 (나중에 다시 확인) 옵션"을 의도했지만 실제 actions는 닫기(2630-2639)와 복사(2640-2669)뿐. footer 텍스트 '💡 캠페인 인사이트에서 언제든 다시 확인 가능'(app_localizations.dart:29779)만 있고 탭 액션이 없다. POS 앞이 아닌 곳에서 발송한 사장이 '닫기'를 누른 뒤 코드를 다시 찾으려면 인사이트 탭을 스스로 발굴해야 한다.

### 개선안
- (공수 중) **Brand compose 기본 목적지를 '내 매장 주변'으로 반전**
  compose_screen.dart:651-655의 postFrameCallback에서 isBrand면 _pickRandomDestination(excludeCountry:...) 대신 (1) hasFixedStoreLocation이면 고정 매장 좌표, (2) 없으면 현재 GPS + 자국을 기본 선택(_isRandom=false, _destinationTouched=true)으로 설정. 랜덤 해외는 보조 옵션 그대로 유지. 추가 안전망으로 _onSendInner(1564~)에 'Brand + _isRandom + 목적지 미터치'면 1회 확인 다이얼로그("해외 랜덤으로 발송됩니다. 매장 주변으로 보내시겠어요?"). 기존 _useFixedStoreLocation(558-560) 로직을 재사용하므로 변경 범위 작음.
- (공수 소) **사업자 인증 시트를 Brand 프로필로 이전 + 체크리스트 스텝에 딥링크**
  admin_screen.dart:912-1010의 _showBrandVerificationSheet(3필드: 사업자번호/등록증 URL/연락처)를 brand 공용 위젯으로 추출해 profile_screen.dart의 Brand 섹션(BrandChecklistCard 1067 근처)에 '사업자 인증' 타일로 노출. brand_checklist_card.dart:136-209 _step에 onTap 추가 — step1→인증 시트, step2→ComposeScreen push, step3→인사이트 탭. 제출 후 승인 대기는 기존 brandVerificationStatusPending 문자열 재사용. 베타의 '입력 즉시 자동 승인'(admin_screen.dart:999-1000)은 운영 전 관리자 검토로 전환.
- (공수 소) **Brand 가입 폼에 '매장 이름' 필드 추가**
  auth_screen.dart:1933~ _buildSignupForm에서 _selectedAccountType==brand일 때 아이디 아래 '매장 이름(손님에게 보여요)' 입력 추가, signUp 호출(1546-1549)의 brandName fallback을 이 값으로 교체(미입력 시에만 username). 한글/공백 허용 — username 규칙과 분리. 같은 자리에서 업종 칩(_bizCategoryKeys, compose의 4936 재사용)까지 미리 받으면 첫 compose에서 업종이 프리셋되고 AI 생성 다이얼로그(1438-1442)의 brandName/category 프리필 품질도 올라간다.
- (공수 대) **투어 마지막 장에 '첫 캠페인 만들기' CTA + 3스텝 첫 캠페인 마법사**
  tier_tour_screen.dart:330-359 — Brand의 마지막 버튼이 '시작하기'(pop만)로 끝남. isBrand && isLast면 Premium CTA 패턴(284-313)처럼 '📣 첫 캠페인 만들기' 버튼으로 ComposeScreen(또는 간이 마법사)을 pushReplacement. 마법사는 기존 compose 위젯 재사용 3스텝: ①혜택(발송종류+본문, AI 생성 버튼 전면 배치) ②범위(매장 위치 고정 + 반경) ③확인(코드 미리보기+유효기간) → 발송. 풀 compose는 '고급 모드'로 유지. 결정 9개를 스텝당 1~2개로 줄여 '가입 5분 내 첫 발송' 퍼널을 만든다.
- (공수 중) **Brand 온보딩 동선의 koEn 카피를 14언어 _t()로 승격**
  tier_tour_screen.dart 슬라이드 9건 + compose_screen.dart의 매장위치/자동발송/업종/발송종류/반경·수량 칩(4925, 4942, 5627-5732) + AI 안내(1502-1505, 1541-1544)를 app_localizations.dart의 _t() 14언어 getter로 이동. 기존 brandChecklist*(5865-5962), accountType*(137-373)과 동일 패턴이라 기계적 작업 — 번역 키 약 20개. Brand 유료 고객 첫인상 구간이므로 i18n 우선순위 최상.
- (공수 소) **코드 reveal 다이얼로그에 '인사이트에서 보기' 세 번째 액션 추가**
  compose_screen.dart:2628-2670 actions에 TextButton 추가 — pop 후 MainScaffold의 인사이트 탭으로 전환(brand_insights_screen 진입)하거나 최소한 해당 캠페인 상세로 이동. footer 텍스트(29778)의 약속과 UI를 일치시키고, Build 334 주석(2542-2543)의 원래 의도를 완성. 닫기 전 '코드를 복사했나요?' 확인은 불필요 — 인사이트 경로가 생기면 재확인 불안 자체가 사라진다.
- (공수 대) **대량 발송 패널에 '내 동네' 프리셋 추가**
  compose_screen.dart:6510~ _buildBulkSendPanel 상단에 Brand 전용 라디오: '🏠 내 매장 주변 N통'(고정 매장 좌표 또는 현재 GPS 중심, sendBrandExpressBlast의 preciseLat/preciseLng 경로 1775-1776 재사용 + 좌표 주변 산포) vs 기존 '🌍 나라 단위'. 라벨도 '나라당 발송 수'→'발송 수량'으로 동네 모드에서 변경. ExactDrop 크레딧 차감 정책은 유지하되 동네 프리셋에는 auto-zone(무료)과의 차이를 한 줄 비교로 안내 — 흩어진 3개 타게팅 수단(ExactDrop/auto-zone/bulk)이 한 패널에서 선택지로 정리된다.

---

## [마케터] 운영·성과 — 캠페인 관리/인사이트/비용 체감

### 강점
- **대량발송 1000통이 캠페인 1행으로 — campaignId 그룹화가 마케터 멘탈모델과 일치**
  brand_campaign_screen.dart:163-188 _groupKey/_group 이 같은 campaignId(또는 본문+코드+업종)를 1개 캠페인 행으로 묶고 'N통' 배지(849-867)로 발송 규모를 표시. 인사이트 쪽도 동일 키로 그룹화(app_state.dart:2380-2391)해 두 화면의 캠페인 단위가 일관됨. 캠페인 여러 개 돌리는 입장에서 letter 단위가 아니라 캠페인 단위로 보이는 건 기본기인데 정확히 구현돼 있음.
- **발송→픽업→노출→사용 4단계 퍼널 + 단계전환% + 캠페인별 코칭팁**
  brand_insights_screen.dart:122-211 요약 카드가 4단계 막대 퍼널과 직전 단계 대비 전환율(_stepRate)을 보여주고, brand_insights.dart:128-138 coachingTip 이 '픽업0→반경/본문', '노출0→매장 친화도', '코드만료' 등 패턴별 행동 지침을 줌. 특히 '코드 노출(revealed)'을 매장 도착 의도 신호로 분리(brand_insights.dart:18-20)한 건 단순 픽업률보다 의사결정에 유용한 설계. 지표 읽는 법 푸터(633-672)에 ≥20%/5~20%/<5% 기준선까지 제시.
- **POS 운영 동선 — 코드 단위 dedup 섹션 + 원탭 복사 + 만료 표시**
  brand_insights_screen.dart:307-384 가 같은 redemptionCode 를 쓰는 캠페인을 코드 1장 카드로 합산(발급/픽업/노출/사용), 만료된 코드는 취소선+안내(489-498). 캠페인 상세 시트(brand_campaign_screen.dart:944-1115)에서도 코드를 monospace 22pt 로 크게 보여주고 SecureClipboard 복사(1147-1165). 직원에게 'POS에 이 코드 등록해'라고 전달하는 실제 매장 운영 흐름이 화면에 반영돼 있음.
- **고객 응대(DM)가 캠페인 화면 안에 — 미읽음 우선 정렬 + 탭 배지**
  brand_campaign_screen.dart:102-139 캠페인/받은DM 2탭 구조, dmUnread 합계 배지(73, 116-134), DM 목록은 미읽음 우선→최신순(256-261). 쿠폰 받은 손님 문의를 캠페인 성과와 같은 화면에서 처리할 수 있어 마케터가 앱을 오가지 않아도 됨.
- **비용 체감 장치 — 잔여 발송량 색상 경고 + 스토어 현지화 가격**
  brand_campaign_screen.dart:516-611 _QuotaSummaryCard 가 '오늘 남은 발송 수'를 잔여율 40%/15% 기준 teal→gold→red 로 색상 경고(538-541)하고 ExactDrop 크레딧 잔량을 부지표로 병기. ExactDrop 구매 다이얼로그는 RC priceString 우선 + KRW fallback(compose_screen.dart:2795-2798, purchase_service.dart:1497-1506)으로 해외 스토어프론트에서도 통화가 안 깨짐.
- **본사에서 매장 좌표로 발송 — 고정 매장 위치가 GPS 모순을 해소**
  compose_screen.dart:475-476, 558-560 고정 매장 위치 저장 시 자동발송 기본 사용, 1029-1030 현재 GPS 없어도 고정 좌표로 zone 생성 가능, 1089-1092 zone 중심을 매장 좌표로. 본사 사무실에서 매장 캠페인을 등록하는 프랜차이즈 마케터의 실제 근무 위치 문제(매장 100m 가드 모순, 1938-1941 주석)를 풀어둔 상태.

### 불편
- [높음] **캠페인 탭과 인사이트 탭의 성과 숫자가 서로 다름 — 보고서 못 쓰는 지표**
  내 캠페인 탭의 픽업/사용 집계(brand_campaign_screen.dart:182-183)는 로컬 letter 의 l.readCount/l.redeemedAt 을 합산하는데, 서버 sync 는 '자기가 보낸 편지는 건너뜀'(app_state.dart:4150)이라 타인 픽업이 로컬 _sent 에 반영되지 않음(대부분 0 표시). 반면 인사이트 화면은 _serverInsightsCache(app_state.dart:2373-2376, refreshBrandInsightsFromServer 2324-2346)로 서버 atomic 카운터를 읽음. 같은 캠페인이 두 화면에서 다른 숫자 — 점주/본사에 숫자 보고하는 마케터에게 신뢰 붕괴 포인트.
- [치명] **자동발송 zone 은 만들면 끝 — 목록도, 중단도, 성과도 안 보임**
  BrandZoneService 에 createZone(brand_zone_service.dart:212)만 있고 update/delete/pause 가 없음(grep 확인). allCached 는 admin 전용(64-66) — Brand 가 자기 zone 을 볼 화면 자체가 없음. zone 이 만드는 letter 는 수신자 디바이스에서 생성돼 수신자 inbox 로만 들어가고(app_state.dart:8385-8422) 브랜드 _sent 에 없으므로 캠페인 탭/인사이트(둘 다 _sent 기반, app_state.dart:2358) 어디에도 zone 성과가 집계되지 않음. 게다가 compose 는 durationDays 를 안 넘겨 30일 고정(brand_zone_service.dart:220, compose_screen.dart:1086-1100). 가격 오타 쿠폰을 zone 으로 걸면 30일간 회수 수단이 maxRedeems 소진뿐 — 운영자 입장에서 치명적.
- [높음] **시간 축이 없는 성과 — 30일 누적 단일 숫자뿐, 시간대/일별/재방문 전무**
  인사이트는 cutoff 30일 하드코딩(app_state.dart:2327, 2357) 누적 합산만 제공. 기간 선택, 일별 추이, 시간대별 픽업/사용 분포, 동일 고객 재방문(재사용) 지표가 코드에 없음(grep 으로 시계열/트렌드 관련 구현 부재 확인). 캠페인 행의 시간 정보는 '3d/2h' 단축 표기(brand_campaign_screen.dart:932-939)뿐. '점심 쿠폰을 11시에 뿌리는 게 나은가 17시인가'라는 마케터의 기본 질문에 답할 데이터가 화면 어디에도 없음.
- [중간] **데이터 내보내기 0건 — 본사 보고는 스크린샷으로**
  lib/features/brand/ 와 brand_insights 모델 전체에 export/CSV/share 관련 코드 없음(grep 'export|csv|CSV' 무결과). 캠페인 목록도 활성/종료 각 take(50)(brand_campaign_screen.dart:230, 241), 인사이트 캠페인 카드는 take(10)(brand_insights_screen.dart:95) 캡이라 과거 캠페인 이력 열람조차 잘림. 주간 보고서를 쓰는 프랜차이즈 마케터는 매번 두 화면을 스크린샷해서 수기로 엑셀에 옮겨야 함.
- [중간] **ExactDrop 가격표가 비합리 — 500회 ₩40,000 옆에 1000회 ₩10,000**
  구매 다이얼로그(compose_screen.dart:2835-2860)에 50회 ₩6,000 / 1000회 ₩10,000(best) / 500회 ₩40,000 이 동시 노출. Build 429 에서 100회 슬롯을 1000회 ₩10,000 으로 교체(purchase_service.dart:61-63)하면서 500회 ₩40,000(58행) 티어를 방치 — 회당 단가가 120원/10원/80원으로 뒤죽박죽이라 500회 버튼은 존재 이유가 없고, 예산 결재 올리는 마케터 눈에는 '가격 오류 있는 서비스'로 보여 신뢰를 깎음.
- [높음] **'동일 패턴 재집행' 코칭은 주는데 재발송 버튼이 없음**
  coachingTip 이 redeemRate ≥20% 캠페인에 '잘됨 — 재집행'(brand_insights.dart:136, l.coachingGood)을 권하지만, 캠페인 상세 시트(brand_campaign_screen.dart:944-1047)에는 복사/통계만 있고 복제·재발송 액션이 없음(grep '재발송|resend|duplicate' — compose 의 지역 추천 주석 1건뿐). 잘된 캠페인을 다시 돌리려면 본문·혜택·반경을 compose 에 처음부터 다시 타이핑해야 함. 캠페인 수정/중단도 불가(letter 는 발송 후 immutable, 중단 API 부재).
- [높음] **다지점 관리 불가 — 매장 위치 1좌표, 이름도 주소도 없음**
  고정 매장 위치는 _fixedStoreLat/_fixedStoreLng 단일 쌍(app_state.dart:1411-1416)이고 화면 표시도 위경도 숫자 raw 노출(compose_screen.dart:5820-5822 toStringAsFixed(5)) — '강남점' 같은 라벨/주소가 없음. 지점 5곳을 맡은 프랜차이즈 마케터는 캠페인마다 좌표를 갈아끼우거나 계정 5개를 써야 하고, 인사이트에도 지점 축이 없어 지점별 성과 비교가 원천 불가.
- [중간] **인사이트 새로고침이 letter 수만큼 순차 HTTP — 대량발송 브랜드일수록 느려짐**
  refreshBrandInsightsFromServer(app_state.dart:2324-2346)가 최근 30일 _sent 의 letter 마다 getDocument 를 순차 await(주석 스스로 'N letters → N HTTP requests' 인정). 1,000통 bulk 캠페인 2번 돌린 브랜드는 인사이트 진입 시 2,000회 순차 fetch — 화면은 캐시로 먼저 그려지지만 정확한 숫자가 뜨기까지 수십 초 이상 걸릴 수 있고 Firestore read 비용도 발송량에 비례해 증가. 캠페인 단위(campaignId) 집계 문서가 없는 구조적 한계.

### 개선안
- (공수 소) **캠페인 탭도 서버 집계 캐시 공유 — 두 화면 숫자 단일화**
  brand_campaign_screen 의 _group(brand_campaign_screen.dart:172-188)이 l.readCount 대신 AppState._serverInsightsCache 를 조회하도록 lookup 함수를 AppState 에 public 으로 노출하고, 캠페인 탭 진입(initState)에서 refreshBrandInsightsFromServer() 를 호출. 인사이트와 동일 소스가 되어 픽업/사용 숫자 불일치 해소. 기존 캐시·그룹키 로직 재사용이라 변경 범위 작음.
- (공수 중) **내 자동발송 zone 관리 섹션 — 목록/일시중지/조기종료 + 성과 합산**
  ① BrandZoneService 에 zonesForBrand(brandId)(brand_zones 쿼리 필터)와 deactivateZone(expiresAt 을 now 로 PATCH) 추가, firestore.rules 에 brandId 본인 zone 한정 update 허용. ② 캠페인 탭에 '자동발송 중인 매장 N곳' 섹션을 추가해 zone 별 redeemedCount(이미 zone doc 에 존재, brand_zone.dart:56-57)와 만료일·중지 버튼 노출. ③ zone letter 가 brandZoneId(app_state.dart:8415)를 이미 갖고 있으므로 인사이트 집계에 zone 캠페인 행 합류. 잘못 건 쿠폰을 30일간 못 멈추는 치명 결함 해소.
- (공수 중) **캠페인 '같은 조건으로 다시 보내기' — 코칭팁과 액션 연결**
  _CampaignDetailSheet(brand_campaign_screen.dart:944)에 재집행 버튼 추가 → ComposeScreen 에 initialContent/initialRedemptionInfo/initialCategory 생성자 파라미터를 추가해 그룹 대표 letter(group.rep) 값으로 프리필 진입. 인사이트 캠페인 카드의 coachingGood('재집행 권장')에도 동일 액션 연결. 새 코드 자동 발급은 기존 RedemptionCode.generate 흐름 재사용.
- (공수 소) **인사이트 CSV 내보내기/공유**
  brandInsights getter 가 이미 캠페인별 sent/pickup/revealed/redeemed/rate/code/만료(app_state.dart:2401-2413)를 들고 있으므로 CSV 문자열 생성은 순수 변환. 인사이트 AppBar 에 공유 아이콘 → share_plus(또는 기존 lib/features/share 경로)로 파일 공유. take(10) 캡과 무관하게 전체 campaigns 를 덤프해 본사 보고/엑셀 분석 요구 충족.
- (공수 대) **일별 추이 + 시간대 분포 — 캠페인 문서에 시계열 카운터 적재**
  현재 pickupCount/revealedCount/redeemedCount atomic increment(app_state.dart:2335-2338) 패턴을 확장해 letter(또는 campaignId 별 집계 doc)에 'pickupByDay.{yyyyMMdd}'·'redeemByHour.{0-23}' 맵 필드를 함께 increment. 인사이트 요약 카드 아래 7/30일 막대 추이와 시간대 히트맵을 추가하고 기간 선택(7/30/90일) 도입 — cutoff 30일 하드코딩(app_state.dart:2327) 파라미터화. ExactDrop 회당 단가(구매가/수량)를 곱해 '사용 1건당 비용'도 같은 카드에 표기 가능.
- (공수 소) **ExactDrop 티어 가격 정합화**
  compose_screen.dart:2835-2860 의 50/1000/500 티어를 단가가 단조 하락하도록 재설계(예: 50=₩3,000 / 500=₩20,000 / 1000=₩30,000)하고 각 버튼에 '회당 ₩N' 단가 라벨 추가. purchase_service.dart fallback 가격(23, 58-63행 주석 포함)과 ASC 상품 가격 동기화. 코드 변경 자체는 상수+라벨 수준이나 스토어 상품 가격 변경 동반 필요.
- (공수 대) **다지점 지원 — 매장 위치 리스트화 + 라벨 + 지점 축 성과**
  1단계: _fixedStoreLat/Lng 단일 쌍(app_state.dart:1411-1416)을 {label, lat, lng} 리스트로 확장하고 compose 의 고정 매장 카드(compose_screen.dart:5764 이하)를 지점 선택 드롭다운으로, 좌표 raw 표시는 라벨 우선으로 교체. 2단계: 발송 letter 에 storeLabel 태그를 실어 인사이트 캠페인 그룹키/필터에 지점 축 추가 — 지점별 전환율 비교가 가능해져 프랜차이즈 본사 마케터의 핵심 의사결정(어느 지점에 예산 더 쓸지)을 지원.

---

## [마케터] 단골·재방문 — 스탬프/팔로우/DM 의 사장 관점 가치

### 강점
- **스탬프가 '진짜 결제'에만 적립 — 허수 단골이 안 생김**
  스탬프는 픽업이 아니라 쿠폰 '사용 완료' 시점에만 +1 (app_state.dart:2031-2032 markLetterRedeemed 내 _recordStampForRedeem 호출). 정보성(general) 편지 제외(app_state.dart:1998-1999), 보상 쿠폰 자체 사용 제외(2074), 브랜드 본인 self-redeem 제외(2077). 사장 입장에서 스탬프 1개 = 실제 매장 방문·결제 1회라는 정의가 코드로 강제돼 있다 — 종이 쿠폰 도장 남발 문제가 구조적으로 없음.
- **단골 보상이 POS 추가 작업 0으로 설계됨**
  보상 쿠폰은 같은 매장의 기존 redemptionCode 를 재사용(app_state.dart:2105-2115 '코드는 같은 매장의 최근 코드를 재사용(POS 추가 등록 0)'). 알바생에게 새 코드를 교육할 필요 없이 기존 코드 그대로 처리된다. 보상은 epic 레어리티 고정(2141)으로 고객 쾌감을 극대화하고, 30일 사용 기한(2149-2150)이 재방문 윈도우를 만든다.
- **친구 선물이 매장 퍼널 수치에 잡히는 공짜 바이럴**
  claimGiftLetter 가 원본 letter 의 pickupCount/readCount 를 increment(app_state.dart:2296-2299) — 선물로 퍼진 도달이 Brand 인사이트 픽업 수에 반영된다. 브랜드 쿠폰/교환권만 선물 가능(2262), 만료는 SecureClock 으로 시계조작 차단(2268-2272), brandUniquePerUser 캠페인은 1인 1회 dedup(2273-2280) — 내 한정 오퍼 정책이 선물 경로에서도 대체로 존중됨.
- **팔로우하면 내 쿠폰이 고객 인박스 상단에 고정**
  inbox_screen.dart:950 — senderIsBrand && isBrandFollowed 면 인박스 상단 고정. follow 와 mute 가 상호배타(app_state.dart:2450-2456)라 단골이 실수로 내 매장을 뮤트한 상태로 팔로우하는 모순이 없음. 단골의 다음 방문 쿠폰이 광고 더미에 묻히지 않는다.
- **ROI 퍼널이 서버 집계 우선이라 '남이 주운 것'도 보임**
  refreshBrandInsightsFromServer(app_state.dart:2324-2346)가 letter 별 pickupCount/revealedCount/redeemedCount 를 Firestore 에서 fetch 해 캐시하고, brandInsights(2353-2433)가 캠페인 단위로 그룹화해 발송→픽업→코드노출→사용 4단계 퍼널을 계산. 대량발송도 campaignId 로 묶여 카드 1장(2363-2391) — 사장이 한 화면에서 캠페인별 사용률을 본다.

### 불편
- [치명] **사장은 단골 현황을 영원히 볼 수 없다 — 스탬프가 고객 폰 안에만 있음**
  스탬프는 픽업자 디바이스의 SharedPreferences JSON('brand_stamp_cards_v1')에만 저장(brand_stamp.dart:6-8 '서버 스키마/룰 변경 없이 동작(픽업자 디바이스 기준)', app_state.dart:2157-2167 _saveStampCards). lib/features/brand 디렉토리에 stamp 참조 0건(grep 확인) — Brand 화면 어디에도 단골 수·회차 분포가 없다. 재방문율이 생명인 식당 사장이 '우리 단골이 몇 명인지, 누가 4번째 방문인지' 알 방법이 전혀 없고, 고객이 폰을 바꾸거나 재설치하면 단골 기록 자체가 소멸한다.
- [치명] **DM 이 가짜 — 앱이 내 가게 이름으로 헛소리 자동응답을 지어낸다**
  sendDM 후 3초 뒤 상대(=내 매장) 이름으로 canned 응답을 fabricate(app_state.dart:10428-10450 'Simulate partner reply after 3 seconds', senderName: session.partnerName). 응답 풀은 stateDmReply1~7 — '정말요? 저도 그렇게 생각해요! 😊'(app_localizations.dart:15603) 같은 잡담. 고객이 '주차 되나요?'라고 물으면 내 가게 명의로 무관한 답이 가고, 고객은 매장이 답한 줄 안다. 매장 신뢰에 직격타인데 사장은 그 대화의 존재조차 모른다.
- [치명] **Brand '받은 DM' 탭은 구조적으로 영원히 빈 화면**
  DM 메시지는 발신자 디바이스 prefs 에만 저장되고 Firestore 에 일절 안 써짐(_saveDMToPrefs app_state.dart:10499-10516 — prefs.setString 만, dm 관련 FirestoreService 호출 0건 grep 확인). brand_campaign_screen.dart:253-275 의 받은 DM 탭은 state.chatSessions(로컬)만 읽으므로 고객 메시지가 사장 디바이스에 도달할 경로가 아예 없다. Build 446 에서 '브랜드도 고객 문의를 받을 수 있도록'(app_state.dart:1440) 만든 탭이 실제로는 아무것도 받을 수 없는 장식이다.
- [높음] **내가 만든 적 없는 '단골 보상'이 내 매장 이름으로 발급된다 — 임계값·내용·opt-out 전부 불가**
  threshold 는 5 하드코드(brand_stamp.dart:27 defaultThreshold=5, 설정 UI 없음), 보상 문구는 자동 생성('직원에게 이 화면을 보여주세요' app_state.dart:2145)이며 브랜드 동의 절차가 없다. 직원은 처음 보는 쿠폰을 들이미는 손님 앞에서 당황하고, 사장은 5번째 방문마다 자동 할인이 나가는 걸 모른 채 마진 계산을 한다. 게다가 보상이 기존 redemptionCode 를 재사용하면서 기한을 now+30일로 새로 연장(2149-2151) — 내가 종료한 캠페인 코드가 내 동의 없이 한 달 더 살아있게 된다.
- [높음] **단골 보상·선물 쿠폰의 '사용'이 ROI 퍼널에서 증발**
  보상 letter id 는 'stamp_reward_*'(app_state.dart:2116-2117), 선물 사본 id 는 'gift_*'(2284) — 둘 다 서버에 없는 로컬 문서라 markLetterRedeemed 의 letters/$letterId patch(2010-2027)가 존재하지 않는 경로에 best-effort 로 날아가 집계 실패. 즉 단골 루프와 선물 바이럴의 최종 전환(실제 사용)이 brandInsights 에 0으로 잡힌다. 사장 눈엔 '픽업은 느는데 사용은 안 느는' 캠페인으로 보여 오판을 부른다.
- [중간] **팔로워가 몇 명인지, 누군지 모르고 팔로워에게 보낼 수단도 없다**
  followedBrandIds 는 고객 디바이스 prefs 에만 저장(app_state.dart:2458-2461)되고 서버 기록이 없어 Brand 는 팔로워 수 자체를 알 수 없다. 팔로워 대상 발송 기능도 없음 — _FollowListTab 은 '향후 소셜 기능 확장 시 사용' 주석의 unused_element(inbox_screen.dart:4930-4932). l10n 에는 '팔로워 10명 모으기'(app_localizations.dart:23815) 같은 미션 카피까지 있는데 정작 데이터가 어디에도 집계되지 않는다 — 사장에게 팔로우는 효과를 확인할 수 없는 깜깜이 채널.
- [중간] **선물 코드 무제한 확산 — 한정 수량 오퍼 설계 불가**
  선물 코드 = 서버 letter id 평문(letter_read_screen.dart:2619 'Gift code: ${letter.id}', gift_code.dart:9 sent_* 패턴). 수령 cap 필드가 letter.dart 에 없고(grep maxPickup/quantity 0건) dedup 은 로컬 _myPickedUpLetterIds prefs(app_state.dart:2243, 3386) — 코드가 맘카페에 올라가면 전 사용자가 1장씩 받고, 재설치하면 같은 사람이 또 받는다. '선착순 50명' 류 한정 프로모션을 돌릴 방법이 없어 마진 통제가 안 된다.

### 개선안
- (공수 중) **스탬프 서버 승격 + Brand 단골 대시보드 카드**
  markLetterRedeemed 의 기존 redeemedCount increment(app_state.dart:2010-2027) 옆에 brand_stamps/{brandId}_{userId} 카운터 문서 PATCH 를 추가(기존 FirestoreService.incrementField 패턴 재사용). Brand 인사이트 화면(brand_insights_screen)에 '단골 N명 / 회차 분포 / 이번 주 보상 발급 M건' 카드 1장. Auth Phase 3 authUid 바인딩과 묶으면 크로스 디바이스 단골 기록도 해결.
- (공수 중) **스탬프 프로그램 브랜드 설정·opt-in UI**
  BrandStampCard.rewardThreshold 필드는 이미 존재(brand_stamp.dart:13) — Brand 캠페인 화면에 threshold(5/10)·보상 문구·전용 보상 redemptionCode·참여 여부 토글을 추가하고 brand_zones 문서(이미 world-readable 캐시 경로 존재) 류 서버 필드로 고객 디바이스에 전파. _recordStampForRedeem(app_state.dart:2069)이 브랜드 설정을 읽어 적용. 최소안: opt-out 플래그 + 보상 코드 지정만이라도.
- (공수 대) **DM 시뮬 자동응답 즉시 제거 + 실제 메시지 동기화**
  1단계(소): app_state.dart:10428-10467 의 Future.delayed 가짜 응답 블록 삭제, '사장님 확인 후 답장됩니다' placeholder 로 교체 — 매장 명의 fabrication 만 먼저 끊는다. 2단계(대): dm_threads/{idPair}/messages Firestore 컬렉션 + 기존 REST 폴링 패턴(refreshBrandInsightsFromServer 식)으로 Brand 받은 DM 탭(brand_campaign_screen.dart:253)을 진짜 수신함으로. firestore.rules 에 participant 검사 필요 — Auth Phase 3 이후가 현실적.
- (공수 소) **보상·선물 사본의 redeem 을 원본 캠페인에 귀속**
  stamp_reward_*/gift_* letter 생성 시 원본 letterId(또는 campaignId)를 필드로 보존(claimGiftLetter app_state.dart:2283-2287 의 toJson 라운드트립에 'sourceLetterId' 추가)하고, markLetterRedeemed 가 로컬 전용 id 면 원본 경로로 incrementField('loyaltyRedeemedCount'/'giftRedeemedCount'). brandInsights 퍼널에 합산 — 단골 루프의 전환이 처음으로 측정된다.
- (공수 소) **팔로워 카운트 서버 집계 + Brand KPI 노출**
  toggleBrandFollow(app_state.dart:2445-2463)에서 users/{brandId} followerCount 를 incrementField 로 ±1(best-effort, 기존 패턴 그대로). brand_insights_screen KPI 행에 팔로워 수 1줄 추가. 이후 '팔로워 전용 쿠폰 발송'(팔로워에게만 push) 의 데이터 기반이 된다 — 사장에게 팔로우를 '모을 이유'가 생긴다.
- (공수 소) **선물 수령 cap — 한정 오퍼 지원**
  Letter 에 maxGiftClaims(옵션) 필드 추가, compose 의 브랜드 옵션에 '선물 확산 허용/최대 수량' 입력. claimGiftLetter(app_state.dart:2234)가 원본의 giftClaimCount 를 read 후 cap 초과 시 '선물 수량이 소진됐어요' 반환, 수령 시 incrementField. 트랜잭션 없는 best-effort 라 약간의 초과는 허용되지만 무제한 확산은 막힌다. brandUniquePerUser 처럼 brand compose 옵션과 일관된 자리.

---

## [소비자] Free 회원 — 발견→픽업→매장 사용 첫 경험

### 강점
- **매장 직원 앞 사용(리딤) 흐름이 실전용으로 완성도 높음**
  코드는 사용 직전까지 숨김(letter_read_screen.dart:2438 'pending||redeemed||expired 일 때만 panel', :2492-2506 🔒 hiddenHint) → '사용 진행' 1탭에 Code128 바코드(흰 배경 강제, 폭 330px·높이 88px, POS 인식률 주석 :3570-3572) + monospace 대형 코드(:3664-3677, 0/O 혼동 방지) + 화면 밝기 자동 1.0(:3542-3552, ref-counter 로 다중 패널 복원 버그까지 처리 :3491-3498) + 스크린샷 차단(_ScreenProtectionGuard :3704-3728). 점심 줄 서서 직원에게 보여줄 때 버벅댈 요소가 거의 없고, 사용됨/만료 시 dim+취소선(:3567, :3673)으로 재사용 시비도 차단.
- **콜드스타트가 '빈 지도'로 끝나지 않게 3중 설계**
  신규 가입 시 welcome letter + 카테고리·만료시점 다양한 demo 쿠폰 5장을 내 위치 ±89m(Free 200m 반경 안에 들어오도록 의도적으로 좁힘, app_state.dart:5602-5606 주석)에 시드(:5575-5585), 14언어 현지화 + '(체험)' prefix 로 낚시 인상 차단(:5594-5608). 튜토리얼 환영 편지 반경 내 배치(:5942-5996) + 첫 지도 진입 1회 줍기 coachmark(world_map_screen.dart:2650-2668). 주변에 실제 브랜드 쿠폰이 0개여도 첫 픽업 성공 경험은 보장됨.
- **반경 밖 0통 상태를 '나침반 힌트'로 살림**
  반경 안에 편지가 없으면 가장 가까운 편지의 방향 화살표(8방위)+거리를 골드 배너로 표시하고 탭 시 해당 위치로 지도 이동(world_map_screen.dart:631-770, _nearestLetterCompass :2596-2648). 만료/소진/차단 쿠폰은 나침반 대상에서 제외(:2613-2615)해 죽은 안내도 차단. 점심시간에 '저쪽으로 150m' 수준의 행동 가능한 정보를 줌.
- **쿨다운 상태 가시화가 꼼꼼함 — '왜 못 줍지' 혼선 제거**
  쿨다운 중엔 지도 상단에 MM:SS 실시간 pill(world_map_screen.dart:575-630, 1초 tick), 픽업 시도 시 정확한 잔여시간 에러 메시지(app_state.dart:9792-9803), 쿨다운 중 근처 도착 시 '혜택이 근처에 있어요 + 잔여시간' 알림(:8761-8778). 선착순 claim 패배로 픽업이 롤백되면 쿨다운도 해제(:10045-10048)해서 '받지도 못한 쿠폰에 1시간 잠김'을 막음.
- **픽업 → 즉시 상세 화면, '가장 가까운' 마커 강조**
  픽업 성공 시 인박스로 보내지 않고 LetterReadScreen 을 즉시 push(world_map_screen.dart:2383-2399 주석: '이전엔 인박스로 이동해 다시 탭해야 했음') — 시간 압박 있는 사용자에게 단계 절약. GPS 기준 최단 편지 1개에 '📍 가장 가까운' 골드 라벨+halo(:1110-1121, :3517-3543)로 다음 행동이 명확.
- **만료 쿠폰으로부터 사용자(와 쿨다운)를 보호**
  지도만료(expiresAt)뿐 아니라 사용기한(redemptionExpiresAt) 지난 쿠폰도 픽업 자체를 차단해 쿨다운 헛소모 방지(app_state.dart:9820-9822, Build 414 sim 수정 주석), 픽업한 쿠폰은 만료 24h 전 로컬 알림 예약(:9926-9941), 상세 화면에 유효기간 카운트다운 + 3일 이내 임박 경고 톤(letter_read_screen.dart:2352-2357, 2681-2710).

### 불편
- [치명] **체험(demo)·튜토리얼 쿠폰 픽업도 60분 쿨다운을 소모 — 첫 세션이 '가짜 쿠폰 1개 줍고 끝'**
  pickUpLetter 는 성공 시 무조건 _lastNearbyPickupAt = SecureClock.now() 로 쿨다운 시작(app_state.dart:9906)하고, demo_/tutorial_ id 예외 분기가 전혀 없음(9784-9960 전 구간 grep 확인). 그런데 온보딩은 demo 쿠폰 5장을 일부러 반경 안 89m에 깔아 첫 픽업을 유도(:5602-5606)함. 점심시간 신규 Free 유저의 실제 시나리오: '(체험) 아메리카노 1+1' 을 줍는 순간 진짜 매장 쿠폰은 60분 잠김 → 점심시간(보통 60분) 안에 실 매장 전환 0회. 온보딩 설계가 자기 쿨다운에 막히는 자가당착.
- [높음] **픽업 시트가 혜택 내용을 안 보여줘 — 1시간에 1번뿐인 픽업을 '깜깜이 도박'으로 만듦**
  _PickupSheet 는 BRAND 라벨/국기/발신 국가/상호명만 표시(world_map_screen.dart:4465-4513)하고 letter.content(혜택 문구), category(할인권/교환권/일반홍보), redemptionExpiresAt 을 전혀 노출하지 않음. Free 는 줍고 나서야 '30% 할인'인지 단순 홍보문인지 알게 되는데, 일반홍보(general) 픽업도 동일하게 60분 쿨다운을 소모(pickUpLetter 에 카테고리 분기 없음, app_state.dart:9784-9906). 점심 예산으로 식당 쿠폰을 노리는 직장인이 패션 홍보를 주워 1시간 잠기는 구조.
- [중간] **Free 에겐 브랜드 쿠폰 마커가 전부 💌 — 걸어갈 가치 판단 불가**
  _UnreadDeliveredMarker 는 viewerIsPremiumOrBrand=false 면 브랜드 편지를 카테고리 이모지(🎟/🎁) 대신 💌 로 통일하고 카테고리 내부 링 색도 숨김(world_map_screen.dart:3459-3499 'showAsBrand = isBrandSender && viewerIsPremiumOrBrand'). 의도된 tier 차별화지만, Free 첫 경험에서 '저 마커가 식당 할인인지 모름 → 150m 안 걸어감 → 매장 전환 실패'로 이어져 브랜드(돈 내는 쪽)의 ROI 도 깎는 양날.
- [중간] **60분 쿨다운을 어디서도 사전 고지하지 않음 — 첫 픽업 후 기습**
  Free 투어 슬라이드 1은 '주변 200m 안에 떨어진 할인권을 탭해서 주우세요'만 말하고 쿨다운 무언급(tier_tour_screen.dart:133-141), 슬라이드 3의 Premium 업셀 '쿨다운 없음'(:150-156)으로 간접 암시가 유일. 가입 전 온보딩 카피도 200m만 언급(app_localizations.dart:1236 onboarding3Body). 첫 픽업 직후 갑자기 'Next pickup in 59m 59s' pill(world_map_screen.dart:579-630)이 떠서 규칙을 벌칙으로 학습하게 됨.
- [중간] **'사용 진행' TTL 숫자가 3중 불일치 — 직원 앞에서 시간 신뢰 붕괴**
  실제 자동완료 TTL 은 2시간(app_state.dart:1769 _pendingRedemptionTtl = Duration(hours: 2)), 시작 토스트는 '1시간 안에 매장에서 사용하세요'(app_localizations.dart letterReadRedemptionStartedToast), 카운트다운 위젯은 2h 기준으로 계산하지만 표시를 r.inMinutes.clamp(0, 60) 으로 잘라(letter_read_screen.dart:3156 vs :3172) 처음 60분 동안 '⏱ 60분 후 자동 완료'가 고정 표시됨. AppConstants.pendingRedemptionTtl 도 1h 로 따로 존재(app_constants.dart:59) — 같은 값의 source 3개가 전부 다름.
- [중간] **'사용 진행'은 확인·취소 없음 — 호기심 탭 한 번에 쿠폰이 2시간 뒤 자동 소멸**
  큰 CTA 탭 즉시 startRedemption 호출(letter_read_screen.dart:2566-2585, confirm 다이얼로그 없음) → 2h 경과 시 consumeElapsedPendingRedemptions 가 자동 markLetterRedeemed(app_state.dart:1906-1943). pending 상태에서 제공되는 버튼은 '지금 사용 완료'(즉시 소멸 가속)뿐이고 취소 경로가 없음(letter_read_screen.dart:2509-2562). 집에서 '코드가 뭐지' 하고 눌러본 직장인의 쿠폰이 출근길에 이미 '사용됨' 처리되는 시나리오.

### 개선안
- (공수 소) **데모/튜토리얼 쿠폰 쿨다운 면제 (+ 첫 실픽업 1회 grace)**
  app_state.dart pickUpLetter 의 _lastNearbyPickupAt 설정(:9906) 앞에 letter.id 가 'demo_'/'tutorial_' prefix(이미 시드에서 보장, :5649 'demo_xxx_${userId}', :5955 'tutorial_welcome_')면 쿨다운 미설정 분기 1줄 추가. 추가로 prefs 카운터로 '실제 쿠폰 첫 1회 픽업'도 면제하면 점심시간 첫 세션에서 체험→실전 2연속 픽업이 가능해져 온보딩 설계 의도(89m demo 시드)가 살아남.
- (공수 소) **픽업 시트에 혜택 프리뷰 + 카테고리·만료 칩 노출**
  world_map_screen.dart _PickupSheet(:4461-4541)에 letter.content 1-2줄(maxLines:2, ellipsis) + letter.category.brandEmoji 칩(할인권/교환권/홍보 구분) + redemptionExpiresAt D-day 를 추가. 이미 시트에 letter 전체가 전달되므로 데이터 추가 불필요. '줍기 전에 내용 판단 → 쿨다운을 의미 있게 소비' 로 깜깜이 도박 해소. 일반홍보는 쿨다운 미소모(또는 절반)로 차등하는 것도 pickUpLetter 카테고리 분기 몇 줄.
- (공수 소) **쿨다운 규칙을 '게임 룰'로 사전 고지 + 픽업 성공 토스트에 업셀 연결**
  tier_tour_screen.dart Free 슬라이드 1(:134-141) body 에 '1시간에 1번, 신중히 골라 주우세요' 한 줄 추가(보물찾기 프레이밍). 픽업 성공 직후 스낵바(world_map_screen.dart:2344 이후)에 '다음 줍기는 60분 후 · Premium 은 기다림 없음' 을 붙이면 기습당한 벌칙이 아니라 알고 있던 룰 + 자연스러운 전환 포인트가 됨. l10n 14언어 키 2개 추가.
- (공수 소) **리딤 TTL 단일화: 상수 1곳 + 카피·카운트다운 정합**
  AppConstants.pendingRedemptionTtl 를 2h 로 수정(app_constants.dart:59)하고 app_state.dart:1769 와 letter_read_screen.dart:3156 이 이 상수를 참조하도록 교체. letterReadRedemptionStartedToast 14언어를 '2시간'으로 정정, 카운트다운 clamp(0,60)(:3172)을 ttl.inMinutes 상한으로 변경 + 60분 초과 시 '1시간 58분' 식 표기. 직원 앞 시간 신뢰 회복.
- (공수 중) **'사용 진행' 시작 confirm + 시작 후 5분 취소 유예**
  letter_read_screen.dart:2569 onPressed 에 '매장 직원에게 보여줄 준비가 되셨나요?' 1단 다이얼로그 추가(매장 앞이면 1탭 추가일 뿐, 실수 비용은 쿠폰 1장 전체). 또는 _pendingRedemptionStartedAt 기준 5분 이내면 'pending 취소' 버튼 노출 — app_state 에 cancelRedemption(letterId) 추가(map remove + prefs 재저장, :1818-1873 구조 재사용). 서버 revealedCount 는 이미 best-effort 라 정합 부담 낮음.
- (공수 중) **쿨다운 pill 을 '대기 시간'에서 '다음 행동 안내'로 전환**
  world_map_screen.dart 쿨다운 pill(:589-628)에 onTap 추가 → 바텀시트로 (1) 수집첩의 미사용 쿠폰 N장 바로가기(이미 state.inbox 필터로 계산 가능) (2) 만료 임박 쿠폰 강조 (3) 'Premium 은 쿨다운 없음' 업셀. 점심시간 잔여 40분을 '이미 주운 쿠폰 사용'으로 돌려 매장 전환율과 Premium 전환 양쪽을 끌어올림.

---

## [소비자] Premium 회원 — 4,900원 값어치 체감

### 강점
- **쿨다운 0 + 반경 5배 — 매일 체감되는 진짜 혜택**
  app_state.dart:309-312 Premium 쿨다운 Duration.zero (Free는 60분/1회), app_state.dart:328-333 반경 1km vs Free 200m + 레벨 보너스 스택(Premium 최대 1,490m). 점심시간에 카페·식당 쿠폰을 연속으로 줍는 동선에서 Free였으면 1시간에 1장. 출퇴근길마다 차이를 몸으로 느끼는, 4,900원의 본체.
- **발송·답장 권한 자체가 Premium 전유 — 줍기만 vs 소통**
  app_state.dart:8904 sendLetter가 Free를 통째로 차단(모든 발송·답장이 이 함수로 합류) → 주운 쿠폰에 답장하거나 내 편지를 보내는 행위 전부가 Premium 전용. 하루 30통(app_state.dart:397) + 사진 20통(1625) + 특급 3통 20분 배송(400, 9066). Free에서 답장 버튼 누를 때마다 PremiumGateSheet가 떠서 결제 후 '풀린' 감각이 분명함.
- **관심 카테고리 필터 — 지도 마커에 실제로 동작 + 정직한 카피**
  world_map_screen.dart:299-301 interestFilterActive 시 지도 마커 전체에 passesInterestFilter 적용(nearbyOnly/world 공통), 버튼 gold highlight(820-824)로 켜짐 상태 표시. 시트 카피(5531)가 '업종 미지정 캠페인은 항상 표시'라고 한계를 정직하게 고지. 프랜차이즈 전단지 도배 속에서 카페만 골라 보는 건 Premium에서만 가능(app_state.dart:2198).
- **결제 직후 혜택 4종 다이얼로그 + 갱신일 투명 표시**
  premium_screen.dart:54-107 결제 성공 즉시 '뭐가 달라졌나' 다이얼로그 1회 노출, 146-148 nextBillingDate를 언어별 포맷으로 표시, 411-413 RC 현지화 가격 우선(fallback ₩4,900). '내가 뭘 샀고 언제 또 빠져나가는지'가 화면에 있어 구독 불안이 적다.
- **트라이얼 중에도 정식 결제 전환 가능 + 시계 조작 차단**
  premium_screen.dart:415-423 trial 중 '체험 중' 배지 + 결제 CTA 유지(Build 441 — 이전엔 '현재 사용 중'으로 잠겨 전환 불가), purchase_service.dart:434-437 isTrialActive가 SecureClock 기반이라 만료가 공정. 3일 체험에서 갱신으로 가는 길이 막혀있지 않다.

### 불편
- [치명] **Premium 셀링포인트 1번 'DM'이 가짜 — 봇과 대화하고 있었다**
  premiumFeature3(app_localizations.dart:10820-10821)는 '💬 발송인과 1:1 채팅(DM)으로 직접 소통'을 features 최상단(premium_screen.dart:153-154)에 판매. 그러나 sendDM(app_state.dart:10380-10472)은 Firestore에 한 글자도 안 쓰고 prefs('dmMessages', 9478)에만 저장, 10428-10450에서 3초 뒤 7개 canned 문구(stateDmReply1~7)를 '상대 답장'으로 주입 + 푸시 알림까지 발사. 팔로우도 10337 'Simulate mutual follow immediately'. 매장 사장님과 얘기 중인 줄 알았던 결제 회원이 같은 말만 반복하는 봇임을 눈치채는 순간 = 즉시 해지 + 환불 분쟁 + 리뷰 테러 시나리오.
- [높음] **관심 필터, 브랜드가 태그 안 달면 no-op**
  passesInterestFilter(app_state.dart:2219-2225)는 categoryTag가 있는 브랜드 letter만 거름. 태그는 Build 433 이후 브랜드 발송 시 '선택' 입력(app_state.dart:8894-8897)이고, 미지정 캠페인은 픽업 시점에야 inferCategoryTagFromText로 추론(9888) → 지도 필터 단계에서는 전부 통과. 내 동네 브랜드들이 태그를 안 달면 Premium 필터를 켜도 지도가 그대로 — '눌러봤는데 아무것도 안 변하네' 체험.
- [높음] **preferredCategory는 Lv11 게이트 — 첫 달엔 도달 불가능한 장식**
  isCategoryPreferenceUnlocked(app_state.dart:279-282)는 Premium AND Lv11. Lv11 = 5,000 XP, 픽업 1회 = 10 XP(538-547 공식) → 약 500회 픽업 필요. 갱신 판단하는 첫 달 안에 못 만져보는 '유료 혜택'. 효과도 nearbyLetters 정렬 부스트뿐(261-268)이라 Build 457 관심 필터와 기능 중복 — 잠금 풀어도 감흥 없는 이중 장식.
- [중간] **관심 필터 설정이 기기 로컬 휘발 — 유료 설정인데 재로그인하면 증발**
  setInterestCategories(app_state.dart:2204-2216)는 SharedPreferences에만 저장(Firestore sync mask에 없음 — preferredCategoryKey는 6392-6394에서 sync하는 것과 대조), 로그아웃 시 clear(5416). 폰 바꾸거나 재로그인하면 매번 7개 칩 다시 골라야 함. 4,900원 내는 설정이 계정이 아니라 기기에 붙어있다.
- [중간] **관심 필터 UI가 14언어 앱에서 ko/en 2언어만**
  _InterestFilterSheet 라벨·설명·버튼 전부 l.koEn(world_map_screen.dart:5490-5506, 5521, 5531, 5597, 5620) + Free 업셀 카피도 koEn(968-973). premiumFeature 시리즈는 14언어 풀 번역(app_localizations.dart:10785-10854)인데 정작 새 Premium 기능 화면은 일본어 사용자에게 영어 노출 — '돈 낸 기능이 번역도 안 돼있네'.
- [중간] **특급 배송 — 카피는 '제거됐다'는데 기능은 남아있는 정체불명 혜택**
  app_localizations.dart:10837-10838 주석 '특급 배송(발송 기능)은 Premium에서 제거' + premiumFeatures 목록(premium_screen.dart:153-159)에서 빠졌는데, compose에는 ⚡ 토글 잔존(compose_screen.dart:3644-3694, 일 3회). 효과는 20분 배송 vs Brand 5분(app_state.dart:9066). 결제 페이지에서 안 팔던 기능이 compose에 갑자기 있고, 쿠폰 줍는 소비자에게 '내 편지가 20분 만에 간다'가 왜 좋은지 앱이 설명 못 함 — 가치 서사 단절.
- [낮음] **기프트 카드 코드가 클라이언트에서 생성되는 모조품**
  premium_screen.dart:1406-1409 결제 성공 시 코드 'LTGO-...-PREM'을 timestamp로 로컬 생성, 주석 스스로 '실제 서비스에서는 서버에서 발급'. ₩8,910 선물 상품이 검증 불가 코드 — 친구에게 보냈다가 안 먹히면 결제 신뢰 전체가 흔들림.

### 개선안
- (공수 대) **DM 정직화 — 실배선하거나 셀링 카피에서 즉시 내리기**
  단기(소): premiumFeature3을 '발송·답장 권한'(이미 진짜인 혜택)으로 교체 + sendDM의 3초 가짜 답장(app_state.dart:10428-10467) 제거하고 '상대가 아직 안 읽음' 상태로 정직 표기. 중기(대): letters 패턴 재사용해 dm_messages Firestore 컬렉션 + 수신자 sync 폴링 배선(이미 _syncWorldFromFirestore 인프라 존재). 환불 분쟁 1건 비용 > 카피 수정 비용.
- (공수 소) **관심 필터에 지도-시점 카테고리 추론 fallback**
  passesInterestFilter(app_state.dart:2222-2223)에서 tag null이면 통과 대신 inferCategoryTagFromText(content, senderName, redemptionInfo)를 호출해 추론값으로 매칭(픽업 시점 9888과 동일 함수 재사용, letter id 키 메모이즈로 매 프레임 재계산 방지). 브랜드 태그 보급률과 무관하게 필터가 항상 일하게 됨.
- (공수 소) **preferredCategory를 관심 필터에 흡수 — Lv11 게이트 폐지**
  isCategoryPreferenceUnlocked(app_state.dart:279-282)에서 currentLevel>=11 조건 제거, nearbyLetters 정렬 부스트(261-268)를 interestCategoryKeys 첫 항목 기준으로 자동 적용. 설정 진입점 2개(프로필 preferredCategory + 지도 필터)를 1개로 통합해 '뭐가 다르지?' 혼란 제거. 결제 첫 주에 만질 수 있는 혜택 +1.
- (공수 소) **interestCategoryKeys 서버 동기화**
  preferredCategoryKey가 이미 user doc sync mask에 있는 패턴(app_state.dart:6392-6394) 그대로 interestCategoryKeys를 arrayValue로 추가 + _restoreProfileFromServer에서 복원, 로그아웃 clear(5416)는 유지하되 재로그인 시 서버에서 복귀. firestore.rules 화이트리스트에 필드 1개 추가.
- (공수 소) **관심 필터 시트·업셀 14언어 i18n**
  world_map_screen.dart:5490-5506 라벨 7개 + 시트 타이틀/설명/버튼(5521,5531,5597,5620) + 업셀(968-973)을 AppL10n 키로 승격. 카테고리 라벨은 inbox 필터 칩에 이미 14언어 번역이 있을 가능성 높음(category_inference.dart 연관 키) — 재사용 우선 확인.
- (공수 중) **월간 '절약 리포트' 배너 — 4,900원 vs 내가 아낀 돈**
  redeemedAt(Build 322)과 redemptionInfo 데이터가 이미 letter에 있음 → 인박스 상단에 '이번 달 쿠폰 N장 사용, Premium 반경 덕에 주운 쿠폰 M장' 월간 카드. 금액 파싱이 어려우면 장수만이라도. 갱신 직전 '이 돈 값을 했나' 질문에 앱이 먼저 답하게 하는 리텐션 장치 — 현재 코드엔 갱신 시점 가치 요약이 전무(premium_screen은 혜택 나열만).
- (공수 소) **특급 배송 카피-기능 정합 — 빼든가 다시 팔든가**
  결제 페이지에서 안 파는데 compose에 남은 ⚡(compose_screen.dart:3644)는 둘 중 하나로: (a) premiumFeatures에 '⚡ 내 편지 20분 특급 3통/일' 복귀시켜 혜택 수 4→5로 늘리기, (b) Premium express 경로 제거하고 Brand 전용화. 현재 상태는 발견한 사용자에게만 존재하는 유령 혜택이라 가치 인지 0.

---

## [소비자] 리텐션 — 게임화/수집/스탬프/선물이 2주차에도 작동하는가

### 강점
- **단골 스탬프는 '진짜 작동하는' 풀 루프 — 적립→5개 완성→epic 보상 쿠폰 자동 발급**
  lib/state/app_state.dart:2069-2096 _recordStampForRedeem: 실제 매장 '사용(redeem)' 시에만 스탬프 적립, 보상 쿠폰 재적립 제외(2074)·브랜드 self-redeem 차단(2077). 5개 완성 시 _issueStampRewardLetter(2100-2155)가 epic 고정(2141)·30일 기한(2149-2150) 보상 쿠폰을 자동 발급하고 같은 매장 최근 redemptionCode 재사용(2106-2115)으로 POS 추가 등록 0. 사용 직후 inbox_screen.dart:2390 / letter_read_screen.dart:2521 takeStampCelebration 축하 연출까지 연결돼, 2주차 사용자에게 '한 번 더 가면 도장 하나'라는 재방문 동기가 코드로 실재한다.
- **스트릭 방어권(Freeze) — 하루 빠져도 안 끊기는 용서 설계**
  lib/state/app_state.dart:984-1002: 하루 공백(gapDays==2) 시 방어권 토큰 자동 소비로 스트릭 보존, 30일마다 1개 재충전(_maybeRefillStreakFreeze 1014-1030). streak_badge.dart:72-97에서 '🎟️ 스트릭을 지켰어요' 전용 스낵바로 구분 알림. 2주차에 하루 깜빡한 사용자가 리셋 좌절로 이탈하는 고전 패턴을 막는다. 3/7/14/30/100일 milestone 카피도 구현됨(app_localizations.dart:26727-26741).
- **레어 드롭 픽업 순간의 멀티 감각 연출 — 글로우 마커 + 칩 + 단계별 햅틱**
  지도 마커 rare/epic 글로우 + ✨/💎 배지(world_map_screen.dart:3062-3161, 3510-3623), 픽업 시트 _RarityChip(4482, 4549), rarity.index 만큼 강해지는 햅틱 루프(feedback_service.dart:141-162, 호출 app_state.dart:9911-9914). '특별한 걸 주웠다'는 포켓몬고식 순간 도파민이 시각·촉각·토스트 3중으로 구현돼 있다.
- **재방문 푸시가 '내가 가진 쿠폰' 기반의 실체 있는 알림 — 만료 24h 전 + 아침 만료 다이제스트**
  픽업 시 쿠폰별 만료 24h 전 리마인더 자동 예약(app_state.dart:9926-9939 → notification_service.dart:804+), 아침 9시 만료 임박 다이제스트(app_state.dart:2588-2592, notification_service.dart:877-930). 가짜 FOMO 가 아니라 실제 보유 쿠폰 손실 회피를 건드는 알림이라 2주차에도 양치기 안 된다. 푸시는 quiet/standard/full 피로 제어(notification_service.dart:24, 371-384).
- **친구 선물 = 공유 바이럴 루프, 가드도 촘촘**
  letter_read_screen.dart:2610-2640: 미사용·미만료 서버 쿠폰(sent_*)만 '친구에게 선물하기' → 공유 텍스트에 코드 포함. 수신 claimGiftLetter(app_state.dart:2234-2302): 중복(2243)·본인 매장(2265)·SecureClock 만료(2268-2272)·1인 1캠페인(2275) 가드 + 브랜드 퍼널 pickupCount +1(2296-2299). 선물해도 내 쿠폰을 잃지 않아 부담 없이 뿌릴 수 있는 구조.
- **레벨이 코어 메커니즘(픽업 반경)에 직결 — 장식용 progression 이 아님**
  app_state.dart:328-333 pickupRadiusMeters: Free 200m + (level-1)×10m 보너스. XP 원천도 픽업×10 중심(user_progress.dart:16-29)이라 '주울수록 더 멀리서 주울 수 있다'는 자기강화 루프 방향이 옳다. Lv50 초과 XP 포인트 적립 설계(app_state.dart:335-348)까지 존재.

### 불편
- [높음] **주간 챌린지는 빈 껍데기: 카드가 어디에도 안 붙어 있고, 목표는 '3개국 발송'(편지앱 잔재), 보상은 아무 효과 없는 카운터**
  WeeklyChallengeCard 는 lib/features/streak/weekly_challenge_card.dart 에 정의만 되고 전체 lib 에서 단 한 번도 mount 되지 않음(grep 결과 0건 — 주석의 '프로필·타워 등에 배치'는 허위). 로직도 app_state.dart:483 _recordWeeklyChallengeSend(destinationCountry) — '이번 주 3개국으로 편지 보내기'(447) 인데 호출부는 발송 경로(9176)뿐이라 쿠폰을 '줍는' 소비자에선 영원히 0/3. 설령 달성해도 claimWeeklyChallengeReward(472-479)는 _challengeRewardBalance 만 +1 하는데 이 필드는 어디서도 안 쓰임(451 주석 '향후 프리미엄 연동'). 2주차 재방문용 '이번 주 목표'가 사실상 존재하지 않는다.
- [높음] **아침 8시 알림이 공급 무인지(supply-blind): 베타 초기 빈 지도로 보내 알림 무시 학습을 유발**
  notification_service.dart:641-704 scheduleDailyLetterReminder 는 매일 같은 시각·고정 카피(260-275, 318-333: '근처 지도에 새로 떨어진 할인·홉보 편지를 주워보세요')로 반복 예약 — 주변에 쿠폰이 실제로 있는지 전혀 반영 안 됨. 동네 브랜드가 몇 없는 베타 2주차: 8시 알림→지도 오픈→빈 지도를 2-3번 겪으면 알림 자체를 끄거나 무시한다(유일한 데일리 재진입 트리거의 소진). 카피에 '편지' 잔존(ko 본문 319)도 리브랜딩 미완.
- [중간] **레어리티가 픽업 3초 후 증발: 수집첩·인박스에 흔적 제로 + 기능적 혜택 제로 + 희소 공급에서 무천장(pity 없음)**
  rarity 배지/칩은 world_map_screen.dart(마커 3062-3161, 픽업시트 4480-4482)에만 존재 — lib/features/inbox/ 와 wallet_card_stack.dart 에 rarity 참조 0건(grep 확인). epic 을 주워도 다음날 수집첩에서는 일반 쿠폰과 구분 불가, 컬렉션 카운터도 없음. 게다가 rare/epic 이 할인폭·기한 등 실익과 무관(롤은 발송 시점 app_state.dart:9342-9347, 쿠폰 내용과 독립) — '빛나는 같은 쿠폰'. 확률도 브랜드 발송당 1%/5%라 베타 동네 공급(주변 브랜드 쿠폰 ~10장)이면 2주 내 rare 1장도 못 볼 확률이 절반 이상 — 보장(pity) 장치 없음.
- [중간] **스트릭이 아무것도 주지 않음: 앱만 열면 오르고, 보상은 프로필 구석 배지 + 14일차 '배너 해금'뿐**
  registerDailyStreakCheckin 은 앱 구동 시 자동 호출(app_state.dart:5528) — 픽업/사용 같은 행동 불필요. 그런데 스트릭의 유일한 기능적 효과는 14일 연속 시 UserLevel.experienced 승격(app_state.dart:522)이고, 이게 여는 건 '근처 도착 배너' 노출 조건(world_map_screen.dart:551-552) 정도. 쿠폰·크레딧·반경 등 실익 연결 0. 노출도 StreakBadge 가 profile_screen.dart:1790 단 한 곳(compact) — 매일 보는 지도/인박스에는 없어 2주차 사용자는 자기 스트릭이 몇 일인지도 모른다. '끊기면 아깝다'가 아니라 '있는지도 몰랐다'가 된다.
- [중간] **스탬프 5개의 현실 주기는 캠페인 리듬에 종속(사실상 5주+), 그마저 기기 로컬—재설치/폰 교체 시 단골 이력 증발**
  스탬프는 redeem 당 1개인데 brandUniquePerUser 캠페인은 1인 1쿠폰(app_state.dart:257-259 사전 차단)이므로 같은 매장 스탬프 속도 = 그 매장의 새 캠페인/auto-drop 빈도. 주 1회 드롭이면 첫 보상까지 ~5주 — 2주차엔 ●●○○○ 에서 멈췄다(임계 5는 brand_stamp.dart:27). 저장은 prefs JSON 로컬 전용(brand_stamp.dart:6-8 주석 자인: 서버 동기화 없음) → 재설치 시 4/5까지 모은 단골 이력이 통채 사라짐. UI 노출도 profile_screen.dart:1056 단 한 곳 + 카드 0장이면 위젯 자체 미렌더(stamp_cards_row.dart:23)라 시스템 존재를 보상 받기 전엔 알 길이 없다.
- [중간] **XP 커브가 Free 소비자 페이스와 어귋남: 2주차 체감 보상 ≈10-20m 반경, 첫 기능 해금(Lv11)은 반년 뒤**
  XP = 픽업×10 + 발송×5 + km 보정(user_progress.dart:16-29), 레벨 임계 (n-1)²×50(56-60). Free 는 픽업 쿨다운 60분(app_state.dart:309-312)이라 하루 2-3픽업≈20-30XP → 2주차 누적 ~300XP = Lv3. 보상은 반경 +10m/레벨(331) — 200m 기본 대비 5% 로 지각 불가. 유일한 레벨 기능 해금인 카테고리 선호는 Premium+Lv11(279-282)=5,000XP≈픽업 500회≈반년, Lv50 포인트는 120,050XP(340)≈픽업 1.2만 회로 사실상 도달 불능 설계. progression 이 2주차에 '오르고 있다'는 감각을 주지 못한다.
- [높음] **선물 코드가 무한 복제 가능 — 리텐션 기능이 브랜드 신뢰를 깎는 부메랑**
  claimGiftLetter(app_state.dart:2234-2302)는 수령자별 dedup(2243)만 있고 원본 letter 의 maxReaders/readCount 한도를 검사하지 않음 — 쿠폰 1장의 id(공유 텍스트에 평문 노출, letter_read_screen.dart:2618-2623)를 단톡방에 뿌리면 수백 명이 각자 수령 가능하고 그때마다 pickupCount/readCount 가 증가(2296-2299)해 브랜드 ROI 퍼널이 오염된다. 소비자 관점에서도 '선물'이 아니라 무한 복사라 희소성/성의가 없고, 남용되면 브랜드가 쿠폰 발행을 줄여 공급 악순환으로 돌아온다.

### 개선안
- (공수 중) **주간 챌린지를 소비자 픽업 챌린지로 재배선 + 실보상 + 카드 장착**
  app_state.dart:483 을 픽업 경로(9885 부근)에서 '서로 다른 매장(senderId) 3곳 줍기'로 교체(기존 Set 구조 재사용). claimWeeklyChallengeReward(472)의 죽은 카운터를 실보상으로: 쿨다운 면제 1회(_lastNearbyPickupAt=null) 또는 스탬프 +1. WeeklyChallengeCard 를 world_map_screen 상단(기존 BrandPromoBanner:530 패턴) 또는 inbox 헤더에 mount — 카드 UI·진행바·i18n·claim 흐름이 완성돼 있어 배선만 하면 동작.
- (공수 중) **레어리티 사후 생존: 수집첩 칩 + 컬렉션 카운터 + epic 실혜택 + pity**
  world_map_screen.dart:4549 _RarityChip 을 공용 위젯으로 올려 inbox 카드·letter_read 헤더에 표시. 프로필에 'rare N · epic M' 카운터(_inbox 파생, 영속 필드 불필요). epic 기능 부여 — 사용 시 스탬프 2개(_recordStampForRedeem 2087 에 rarity 분기 1줄) 또는 redemption 기한 +7일. 픽업 n회 무발현 시 rare 보장 pity(픽업 카운터는 activityScore.receivedCount 재사용)로 베타 희소 공급 보완.
- (공수 소) **스트릭 milestone 에 실익 연결 + 지도 HUD 노출 + '첫 픽업 시 체크인'**
  registerDailyStreakCheckin(app_state.dart:971) milestone 분기에 3일=쿨다운 면제권, 7일=24h 반경 부스트(pickupRadiusMeters:328 에 boost 항) 지급하고 기존 milestone 스낵바(streak_badge.dart:102)에 보상 문구 합치. StreakBadge(compact)를 world_map_screen 상단에 추가(현재 profile_screen.dart:1790 단 1곳). 체크인 조건을 앱 구동(5528)이 아닌 그날 첫 픽업/지도 오픈으로 옮겨 행동 기반화.
- (공수 중) **아침 알림 공급 인지화 — 앱 종료 시점 재예약에 마지막 공급 반영 + 빈 동네 카피 분기**
  로컬 알림 특성상 발화 시 조회 불가하므로, scheduleDailyLetterReminder(notification_service.dart:641) 호출부에 nearbyLetters.length·보유 쿠폰 수를 인자로 전달해 본문 분기: 근처 N>0 → '근처에 쿠폰 N장', N==0 & 보유 쿠폰 있음 → 만료 임박 카피, 둘 다 0 → cancel. 9시 만료 다이제스트(877)와 시간 통합해 아침 푸시 1발로. ko 본문 '편지' 잔존(319)도 쿠폰 어휘로 정리.
- (공수 소) **XP 임계 하향 + 레벨 보상 체감화 — 2주 내 첫 의미 있는 도달점**
  user_progress.dart:33 공식 분모 50→15 또는 픽업 XP 10→25로 조정해 하루 2-3픽업 기준 2주차 Lv5-6 도달. 반경 보너스 +10m→+25m/레벨(app_state.dart:331). 카테고리 선호 게이트 Lv11→Lv5(279-282, Premium 조건 유지로 수익 레버 보존). 레벨업 배너에 '픽업 반경 +Xm' 구체 수치 표기. 숫자 튜닝 위주라 회귀 위험 낮음 — 기존 137+ 테스트에 progression 케이스 추가 권장.
- (공수 중) **스탬프 가시성·서버 보존 + 선물 복제 cap**
  StampCardsRow 를 inbox(쿠폰 사용 동선)에도 mount 하고, 카드 0장일 때 숨기기(stamp_cards_row.dart:23) 대신 '같은 매장 5번 쓰면 보상' 티저 1줄로 루프 사전 학습. brand_stamp_cards_v1 JSON 을 user doc 필드로 best-effort 미러링(기존 _saveUserToFirestore 인프라 재사용)해 재설치 증발 방지. 동시에 claimGiftLetter(app_state.dart:2249 이후)에 원본 readCount<maxReaders 검사와 giftClaimCount 상한을 넣어 쿠폰 1장 무한 복제 차단 — 브랜드 공급 신뢰가 소비자 리텐션의 전제.

---

