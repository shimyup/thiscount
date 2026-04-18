# Release Notes — Build 68 (1.0.0+68)

Date: 2026-04-18

---

## Korean (한국어)

**새로운 기능**

- "행운의 편지"를 "오늘의 편지"로 변경했습니다 (14개 언어 전체 반영)
- 아랍어·히브리어·페르시아어·우르두 등 RTL(우→좌) 언어 지원 추가
- 설정에서 언어를 변경하면 즉시 앱 전체에 반영됩니다 (재시작 불필요)
- 받은 편지함에서 발송자 차단 버튼 추가 (편지 상세 화면)

**개선 사항**

- 회원가입 시 전화번호 입력을 선택 사항으로 변경 (이메일 인증만으로 가입 가능)
- 아이디 입력 중 중복 여부를 실시간으로 확인합니다
- 오늘의 편지 탭 시 직전과 다른 글귀가 나오도록 개선
- 오늘의 편지 글 앞뒤 공백 추가 시 플래그가 잘못 풀리던 문제 수정

---

## English

**New Features**

- Renamed "Lucky Letter" to "Today's Letter" across all 14 languages
- Added RTL (right-to-left) language support for Arabic, Hebrew, Persian, Urdu
- Language change in Settings now applies instantly (no restart required)
- Added a Block button on the received letter detail screen

**Improvements**

- Phone number is now optional at signup (email verification is sufficient)
- Username availability is checked in real-time as you type
- Today's Letter now picks a different quote on consecutive taps
- Fixed an issue where adding whitespace cleared the Today's Letter flag incorrectly

---

## Japanese (日本語)

**新機能**

- 「幸運の手紙」を「今日の手紙」に変更しました（14言語すべてに反映）
- アラビア語、ヘブライ語、ペルシア語、ウルドゥー語などRTL（右→左）言語に対応
- 設定で言語を変更すると即座にアプリ全体に反映されます（再起動不要）
- 受信した手紙の詳細画面にブロックボタンを追加

**改善**

- 会員登録時の電話番号入力を任意に変更（メール認証のみで登録可能）
- ユーザーIDの重複をリアルタイムで確認できるようになりました
- 今日の手紙をタップすると直前と異なる文章が表示されるようになりました
- 今日の手紙の前後に空白を追加するとフラグが誤って解除される問題を修正

---

## Chinese (中文)

**新功能**

- 将"幸运信"更名为"今日之信"（14种语言全部反映）
- 新增阿拉伯语、希伯来语、波斯语、乌尔都语等从右到左（RTL）语言支持
- 在设置中更改语言后立即应用于整个应用（无需重启）
- 在收到的信件详情界面新增屏蔽发送者按钮

**改进**

- 注册时的手机号码改为可选项（仅通过邮件验证即可注册）
- 输入用户ID时实时检查是否重复
- 点击今日之信时会显示与上一次不同的文案
- 修复了在今日之信前后添加空格时标记被错误清除的问题

---

## 빌드 검증

- `flutter analyze`: 0 issues
- `flutter build web`: 성공 (23.1s)

## 업로드 대상

- Play Console 내부 테스트 트랙
- App Store Connect TestFlight
