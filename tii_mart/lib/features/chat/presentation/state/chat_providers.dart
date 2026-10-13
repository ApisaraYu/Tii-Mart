import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/firebase_providers.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../data/chat_media_uploader.dart';
import '../../data/chat_remote_datasource.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRemoteDataSource(ref.watch(firestoreProvider));
});

final chatMediaUploaderProvider = Provider<ChatMediaUploader>((ref) {
  return ChatMediaUploader();
});

/// ห้องแชททั้งหมดของผู้ใช้ที่ล็อกอินอยู่ (อัพเดตสด)
final myChatsProvider = StreamProvider<List<ChatThread>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream<List<ChatThread>>.value(const []);
  return ref.watch(chatRepositoryProvider).watchMyChats(uid);
});

final chatThreadProvider =
    StreamProvider.family<ChatThread?, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).watchChat(chatId);
});

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).watchMessages(chatId);
});

/// จำนวนข้อความที่ยังไม่อ่านรวมทุกห้อง (ใช้โชว์ badge บนเมนู)
final unreadTotalProvider = Provider<int>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return 0;
  final chats = ref.watch(myChatsProvider).value ?? const <ChatThread>[];
  return chats.fold<int>(0, (sum, t) => sum + t.unreadFor(uid));
});

/// เก็บว่าตอนนี้ผู้ใช้เปิดห้องไหนอยู่ (ห้องที่เปิดอยู่ไม่ต้องเด้งแจ้งเตือน)
class ChatPresence {
  ChatPresence._();
  static String? activeChatId;
}
