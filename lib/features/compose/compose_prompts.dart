// Daily-rotating writing prompts shown above the compose TextField when it
// is empty. Removes the blank-canvas fear for first-time writers and gives
// a subtle nudge to returning users on what to write about today.
//
// Rotation: dayOfYear % prompts.length. 7 prompts per language means a
// weekly rhythm — same day-of-week gives the same prompt, so users can
// anticipate themes.

const List<String> _promptsKo = [
  '지금 창 밖에 보이는 풍경을 한 문장으로 적어볼까요',
  '오늘 가장 감사했던 작은 순간을 나눠주세요',
  '당신이 가장 좋아하는 향을 설명해보세요',
  '최근 한 번 더 듣고 싶은 말은 무엇인가요',
  '어릴 적 살던 동네를 떠올리며 한 장면을 써볼까요',
  '오늘 먹은 음식 중 하나를 편지로 그려보세요',
  '요즘 반복해서 생각나는 노래가 있다면 가사를 적어주세요',
];

const List<String> _promptsEn = [
  'Describe what you can see outside your window in one sentence',
  'Share a small moment from today that you felt grateful for',
  'Tell the reader about a scent that always makes you pause',
  'What is a sentence you would like to hear again',
  'Picture a scene from the neighborhood you grew up in',
  'Describe a meal you had today — smell, color, first bite',
  'If a song has been looping in your head, write down a line from it',
];

const List<String> _promptsJa = [
  '今、窓の外に見える景色を一文で書いてみて',
  '今日ありがたいと感じた小さな瞬間を教えて',
  '好きな香りをひとつ、詳しく描いてみて',
  'もう一度聞きたい言葉は何ですか',
  '子どもの頃住んでいた街の一場面を書いて',
  '今日食べたものを手紙に絵のように描いて',
  '最近頭から離れない歌があれば、歌詞の一節を書いて',
];

const List<String> _promptsZh = [
  '用一句话描述此刻窗外的风景',
  '分享今天让你感到感激的一个小瞬间',
  '描述一种总让你停下脚步的气味',
  '你最想再听一次的话是什么',
  '回想童年住过的街区，描绘一个场景',
  '把今天吃的一餐画进这封信里',
  '最近循环的一首歌，写下其中的一句歌词',
];

const List<String> _promptsFr = [
  'Décrivez en une phrase ce que vous voyez par la fenêtre',
  'Partagez un petit moment de gratitude vécu aujourd\'hui',
  'Parlez d\'un parfum qui vous fait toujours vous arrêter',
  'Quelle phrase aimeriez-vous entendre à nouveau',
  'Décrivez une scène du quartier de votre enfance',
  'Peignez par les mots un repas que vous avez pris aujourd\'hui',
  'Une chanson tourne en boucle ? Écrivez-en une ligne',
];

const List<String> _promptsDe = [
  'Beschreiben Sie in einem Satz, was Sie aus dem Fenster sehen',
  'Teilen Sie einen kleinen dankbaren Moment von heute',
  'Erzählen Sie von einem Duft, der Sie innehalten lässt',
  'Welchen Satz würden Sie gern noch einmal hören',
  'Malen Sie eine Szene aus Ihrer Kindheitsnachbarschaft',
  'Beschreiben Sie ein Gericht von heute in Farben und Düften',
  'Welches Lied geht Ihnen nicht aus dem Kopf? Eine Zeile bitte',
];

const List<String> _promptsEs = [
  'Describe en una frase lo que ves por tu ventana',
  'Comparte un pequeño momento de gratitud de hoy',
  'Habla de un aroma que siempre te hace detenerte',
  '¿Qué frase te gustaría volver a escuchar?',
  'Evoca una escena del barrio donde creciste',
  'Pinta con palabras una comida que hayas probado hoy',
  'Si una canción te persigue, escribe una de sus líneas',
];

const List<String> _promptsPt = [
  'Descreva em uma frase o que vê pela janela',
  'Conte um pequeno momento de gratidão do seu dia',
  'Fale de um cheiro que sempre te faz parar',
  'Qual frase você gostaria de ouvir novamente',
  'Desenhe com palavras uma cena do bairro da sua infância',
  'Pinte uma refeição que teve hoje — cores, aromas',
  'Uma música na cabeça? Escreva uma linha dela',
];

const List<String> _promptsRu = [
  'Опишите одним предложением, что видно из вашего окна',
  'Поделитесь маленьким моментом благодарности за сегодня',
  'Расскажите о запахе, от которого вы всегда замираете',
  'Какую фразу вы хотели бы услышать ещё раз',
  'Нарисуйте словами сцену из района вашего детства',
  'Опишите сегодняшнюю еду — цвета, аромат, первый вкус',
  'Если какая-то песня не отпускает — запишите строчку',
];

const List<String> _promptsTr = [
  'Pencereden gördüğünüzü bir cümleyle anlatın',
  'Bugün minnet duyduğunuz küçük bir anı paylaşın',
  'Sizi hep durduran bir koku anlatın',
  'Bir kez daha duymak istediğiniz cümle ne',
  'Çocukluğunuzun geçtiği mahalleden bir sahne çizin',
  'Bugün yediğiniz bir yemeği mektuba resim gibi çizin',
  'Aklınıza takılan bir şarkıdan bir satır yazın',
];

const List<String> _promptsAr = [
  'صف ما تراه من نافذتك في جملة واحدة',
  'شارك لحظة صغيرة شعرت فيها بالامتنان اليوم',
  'تحدث عن رائحة تجعلك تتوقف دائماً',
  'ما الجملة التي تتمنى سماعها مرة أخرى',
  'ارسم بالكلمات مشهداً من حي طفولتك',
  'صف وجبة تناولتها اليوم — اللون والرائحة والمذاق',
  'إن كانت أغنية تتردد في رأسك، اكتب سطراً منها',
];

const List<String> _promptsIt = [
  'Descrivi in una frase ciò che vedi dalla finestra',
  'Condividi un piccolo momento di gratitudine di oggi',
  'Racconta di un profumo che ti fa sempre fermare',
  'Quale frase vorresti sentire di nuovo',
  'Dipingi a parole una scena del quartiere della tua infanzia',
  'Descrivi un pasto di oggi — colori, odori, primo morso',
  'Se una canzone ti gira in testa, scrivine un verso',
];

const List<String> _promptsHi = [
  'एक वाक्य में वर्णन करें कि आप अपनी खिड़की से क्या देख रहे हैं',
  'आज का एक छोटा सा कृतज्ञता का पल साझा करें',
  'ऐसी किसी खुशबू के बारे में बताएं जो आपको रोक देती है',
  'आप फिर से कौन सा वाक्य सुनना चाहेंगे',
  'बचपन के मोहल्ले का एक दृश्य शब्दों में चित्रित करें',
  'आज के भोजन का एक दृश्य — रंग, गंध, पहला स्वाद',
  'अगर कोई गाना दोहरा रहा है तो उसकी एक पंक्ति लिखें',
];

const List<String> _promptsTh = [
  'บรรยายสิ่งที่เห็นนอกหน้าต่างในหนึ่งประโยค',
  'แบ่งปันช่วงเวลาเล็ก ๆ ที่ทำให้คุณรู้สึกขอบคุณวันนี้',
  'เล่าถึงกลิ่นที่ทำให้คุณหยุดทุกครั้ง',
  'ประโยคไหนที่คุณอยากได้ยินอีกครั้ง',
  'วาดฉากจากย่านในวัยเด็กของคุณด้วยคำพูด',
  'วาดอาหารมื้อวันนี้ด้วยคำพูด — สี กลิ่น รสแรก',
  'ถ้ามีเพลงวนในหัวอยู่ ลองเขียนเนื้อร้องหนึ่งท่อน',
];

const Map<String, List<String>> _composeDailyPromptsByLang = {
  'ko': _promptsKo,
  'en': _promptsEn,
  'ja': _promptsJa,
  'zh': _promptsZh,
  'fr': _promptsFr,
  'de': _promptsDe,
  'es': _promptsEs,
  'pt': _promptsPt,
  'ru': _promptsRu,
  'tr': _promptsTr,
  'ar': _promptsAr,
  'it': _promptsIt,
  'hi': _promptsHi,
  'th': _promptsTh,
};

/// Returns today's writing prompt for the given language, rotating weekly.
String composeDailyPrompt(String langCode, {DateTime? now}) {
  final prompts = _composeDailyPromptsByLang[langCode] ??
      _composeDailyPromptsByLang['en']!;
  final t = now ?? DateTime.now();
  final dayOfYear = t.difference(DateTime(t.year)).inDays;
  return prompts[dayOfYear % prompts.length];
}
