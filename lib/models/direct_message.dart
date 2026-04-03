enum ChatStatus { followed, pendingAgreement, chatting }

class ChatSession {
  final String partnerId;
  final String partnerName;
  final String partnerCountry;
  final String partnerFlag;
  ChatStatus status;
  DateTime createdAt;
  int unreadCount;

  ChatSession({
    required this.partnerId,
    required this.partnerName,
    required this.partnerCountry,
    required this.partnerFlag,
    this.status = ChatStatus.followed,
    DateTime? createdAt,
    this.unreadCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'partnerId': partnerId,
    'partnerName': partnerName,
    'partnerCountry': partnerCountry,
    'partnerFlag': partnerFlag,
    'status': status.index,
    'createdAt': createdAt.toIso8601String(),
    'unreadCount': unreadCount,
  };

  static ChatSession fromJson(Map<String, dynamic> j) => ChatSession(
    partnerId: j['partnerId'] as String,
    partnerName: j['partnerName'] as String,
    partnerCountry: j['partnerCountry'] as String? ?? '',
    partnerFlag: j['partnerFlag'] as String? ?? '🌍',
    status: ChatStatus.values[j['status'] as int? ?? 0],
    createdAt:
        DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    unreadCount: j['unreadCount'] as int? ?? 0,
  );
}

class DirectMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;
  bool isRead;

  DirectMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'sentAt': sentAt.toIso8601String(),
    'isRead': isRead,
  };

  static DirectMessage fromJson(Map<String, dynamic> j) => DirectMessage(
    id: j['id'] as String,
    senderId: j['senderId'] as String,
    senderName: j['senderName'] as String? ?? '?',
    content: j['content'] as String,
    sentAt: DateTime.tryParse(j['sentAt'] as String? ?? '') ?? DateTime.now(),
    isRead: j['isRead'] as bool? ?? false,
  );
}
