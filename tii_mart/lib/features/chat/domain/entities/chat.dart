/// ห้องแชทระหว่างลูกค้า 1 คน กับร้านค้า (เจ้าของร้าน) 1 ร้าน
class ChatThread {
  const ChatThread({
    required this.id,
    required this.customerId,
    required this.sellerId,
    this.customerName = '',
    this.sellerName = '',
    this.productId,
    this.productName,
    this.lastMessage = '',
    this.lastSenderId,
    this.lastMessageAt,
    this.unread = const {},
  });

  final String id;
  final String customerId;
  final String sellerId;
  final String customerName;
  final String sellerName; // ว่างจนกว่าร้านจะตอบครั้งแรก
  final String? productId; // สินค้าที่ลูกค้าถามล่าสุด
  final String? productName;
  final String lastMessage;
  final String? lastSenderId;
  final DateTime? lastMessageAt;
  final Map<String, int> unread; // uid -> จำนวนข้อความที่ยังไม่อ่าน

  /// รหัสห้อง = customerId_sellerId (คู่เดิมได้ห้องเดิมเสมอ)
  static String idFor(String customerId, String sellerId) =>
      '${customerId}_$sellerId';

  int unreadFor(String uid) => unread[uid] ?? 0;

  /// ชื่อที่แสดงให้ผู้ใช้ uid เห็น (อีกฝั่งคือใคร)
  String titleFor(String uid) {
    if (uid == customerId) {
      return sellerName.isEmpty ? 'ร้านค้า' : sellerName;
    }
    return customerName.isEmpty ? 'ลูกค้า' : customerName;
  }

  bool get hasMessages => lastMessageAt != null || lastMessage.isNotEmpty;
}

enum MessageType {
  text,
  image,
  video;

  static MessageType fromString(String? v) => MessageType.values.firstWhere(
        (t) => t.name == v,
        orElse: () => MessageType.text, // ข้อความเก่าที่ยังไม่มีฟิลด์ type
      );

  /// ข้อความย่อที่โชว์ในรายการแชท/แบนเนอร์
  String get previewLabel => switch (this) {
        MessageType.text => '',
        MessageType.image => '📷 ส่งรูปภาพ',
        MessageType.video => '🎥 ส่งวิดีโอ',
      };
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.type = MessageType.text,
    this.mediaUrl,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String text; // ข้อความ (รูป/วิดีโอ: ว่าง)
  final MessageType type;
  final String? mediaUrl; // URL รูป/วิดีโอ (Cloudinary)
  final DateTime? createdAt; // null = ยังส่งไม่ถึงเซิร์ฟเวอร์ (กำลังส่ง)
}
