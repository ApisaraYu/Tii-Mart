import '../entities/chat.dart';

abstract class ChatRepository {
  /// ห้องแชททั้งหมดของผู้ใช้ (ทั้งลูกค้าและร้านค้า) เรียงใหม่สุดก่อน
  Stream<List<ChatThread>> watchMyChats(String uid);

  /// ห้องเดียว (null ถ้ายังไม่เคยส่งข้อความ)
  Stream<ChatThread?> watchChat(String chatId);

  Stream<List<ChatMessage>> watchMessages(String chatId);

  /// ส่งข้อความ — ถ้ายังไม่มีห้องจะสร้างให้พร้อมกัน
  Future<void> send({
    required ChatThread thread,
    required String senderId,
    required String senderName,
    String text = '',
    MessageType type = MessageType.text,
    String? mediaUrl,
  });
    /// อัพเดตชื่อที่แสดงของฉันในห้อง (ซิงก์เมื่อเป็นข้อมูลเก่า)
  Future<void> syncName({
    required ChatThread thread,
    required String uid,
    required String name,
  });

  /// ตั้งจำนวนที่ยังไม่อ่านของ uid เป็น 0
  Future<void> markRead({required String chatId, required String uid});
}
