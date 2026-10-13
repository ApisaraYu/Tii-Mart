import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/entities/chat.dart';
import '../domain/repositories/chat_repository.dart';

/// collection: chats/{customerId_sellerId}
///   { customerId, sellerId, participants:[customerId, sellerId],
///     customerName, sellerName, productId, productName,
///     lastMessage, lastSenderId, lastMessageAt, unread:{uid:int}, createdAt }
/// sub-collection: chats/{id}/messages/{auto}
///   { senderId, type: text|image|video, text, mediaUrl?, createdAt }
class ChatRemoteDataSource implements ChatRepository {
  ChatRemoteDataSource(this._db);

  final FirebaseFirestore _db;
  static const _timeout = Duration(seconds: 20);
  static const _pageSize = 200;

  CollectionReference<Map<String, dynamic>> get _chats => _db.collection('chats');

  static StreamTransformer<T, T> _mapErrors<T>() =>
      StreamTransformer<T, T>.fromHandlers(
        handleError: (error, stackTrace, sink) =>
            sink.addError(toFailure(error), stackTrace),
      );

  @override
  Stream<List<ChatThread>> watchMyChats(String uid) {
    // ไม่ใช้ orderBy เพื่อเลี่ยง composite index — เรียงฝั่งแอพแทน
    return _chats
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => _threadFrom(d.id, d.data()))
              .where((t) => t.hasMessages)
              .toList();
          final now = DateTime.now(); // ข้อความที่กำลังส่ง (ยังไม่มีเวลา) ถือว่าใหม่สุด
          list.sort(
            (a, b) => (b.lastMessageAt ?? now).compareTo(a.lastMessageAt ?? now),
          );
          return list;
        })
        .transform(_mapErrors<List<ChatThread>>());
  }

  @override
  Stream<ChatThread?> watchChat(String chatId) {
    return _chats
        .doc(chatId)
        .snapshots()
        .map((d) => d.exists ? _threadFrom(d.id, d.data()!) : null)
        .transform(_mapErrors<ChatThread?>());
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final m = d.data();
            return ChatMessage(
              id: d.id,
              senderId: (m['senderId'] ?? '') as String,
              text: (m['text'] ?? '') as String,
              type: MessageType.fromString(m['type'] as String?),
              mediaUrl: m['mediaUrl'] as String?,
              createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
            );
          }).toList(),
        )
        .transform(_mapErrors<List<ChatMessage>>());
  }

  @override
  Future<void> send({
    required ChatThread thread,
    required String senderId,
    required String senderName,
    String text = '',
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) {
    return guardFirebase(() async {
      final receiverId =
          senderId == thread.customerId ? thread.sellerId : thread.customerId;
      final chatRef = _chats.doc(thread.id);
      final msgRef = chatRef.collection('messages').doc();
      final isCustomer = senderId == thread.customerId;
      final preview = type != MessageType.text
          ? type.previewLabel
          : (text.length > 120 ? '${text.substring(0, 120)}…' : text);

      final batch = _db.batch();
      // set + merge: สร้างห้องถ้ายังไม่มี / อัพเดตถ้ามีแล้ว (ฟิลด์ตัวตนค่าเดิมเสมอ)
      batch.set(
        chatRef,
        {
          'customerId': thread.customerId,
          'sellerId': thread.sellerId,
          'participants': [thread.customerId, thread.sellerId],
          if (isCustomer) 'customerName': senderName,
          if (!isCustomer) 'sellerName': senderName,
          if (isCustomer && thread.productId != null) ...{
            'productId': thread.productId,
            'productName': thread.productName,
          },
          'lastMessage': preview,
          'lastSenderId': senderId,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unread': {receiverId: FieldValue.increment(1)},
        },
        SetOptions(merge: true),
      );
      batch.set(msgRef, {
        'senderId': senderId,
        'type': type.name,
        'text': text,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // ไม่ใส่ timeout: ออฟไลน์แล้ว batch จะรอส่งเองเมื่อเน็ตกลับมา (ผู้เรียกไม่ await)
      await batch.commit();
    });
  }

  @override
  Future<void> markRead({required String chatId, required String uid}) {
    return guardFirebase(() async {
      await _chats
          .doc(chatId)
          .update({'unread.$uid': 0}).timeout(_timeout);
    });
  }

  ChatThread _threadFrom(String id, Map<String, dynamic> m) {
    final rawUnread = (m['unread'] as Map?) ?? const {};
    return ChatThread(
      id: id,
      customerId: (m['customerId'] ?? '') as String,
      sellerId: (m['sellerId'] ?? '') as String,
      customerName: (m['customerName'] ?? '') as String,
      sellerName: (m['sellerName'] ?? '') as String,
      productId: m['productId'] as String?,
      productName: m['productName'] as String?,
      lastMessage: (m['lastMessage'] ?? '') as String,
      lastSenderId: m['lastSenderId'] as String?,
      lastMessageAt: (m['lastMessageAt'] as Timestamp?)?.toDate(),
      unread: {
        for (final e in rawUnread.entries)
          e.key as String: (e.value as num?)?.toInt() ?? 0,
      },
    );
  }
}
