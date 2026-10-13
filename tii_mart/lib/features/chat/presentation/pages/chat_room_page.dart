import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../data/chat_media_uploader.dart';
import '../../domain/entities/chat.dart';
import '../state/chat_providers.dart';
import '../widgets/chat_time.dart';
import 'media_viewer_page.dart';

/// ห้องแชท: รายการข้อความ (ใหม่สุดอยู่ล่าง) + ช่องพิมพ์
/// [initial] ใช้ตอนเปิดห้องใหม่ที่ยังไม่มีข้อมูลใน Firestore (เช่นมาจากหน้าสินค้า)
class ChatRoomPage extends ConsumerStatefulWidget {
  const ChatRoomPage({super.key, required this.chatId, this.initial});

  final String chatId;
  final ChatThread? initial;

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _controller = TextEditingController();
  bool _marking = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    ChatPresence.activeChatId = widget.chatId;
  }

  @override
  void dispose() {
    if (ChatPresence.activeChatId == widget.chatId) {
      ChatPresence.activeChatId = null;
    }
    _controller.dispose();
    super.dispose();
  }

  void _markReadIfNeeded(ChatThread t, String uid) {
    final unread = t.unreadFor(uid);
    if (unread == 0) {
      _marking = false;
      return;
    }
    if (_marking) return;
    _marking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(chatRepositoryProvider)
          .markRead(chatId: t.id, uid: uid)
          .catchError((_) {}); // อ่านแล้วไม่สำเร็จ ไม่ต้องรบกวนผู้ใช้
    });
  }

  void _send(ChatThread thread, String uid, String name) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    // ไม่ await: ออฟไลน์ก็พิมพ์ต่อได้ ข้อความจะถูกส่งเองเมื่อเน็ตกลับมา
    ref
        .read(chatRepositoryProvider)
        .send(thread: thread, senderId: uid, senderName: name, text: text)
        .catchError((Object e) {
      if (!mounted) return;
      if (_controller.text.isEmpty) _controller.text = text;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(e))));
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickMedia(
    ChatThread thread,
    String uid,
    String name, {
    required MessageType type,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? file = type == MessageType.video
          ? await picker.pickVideo(source: source)
          : await picker.pickImage(
              source: source,
              maxWidth: 1600,
              imageQuality: 80,
            );
      if (file == null) return; // ผู้ใช้ปิดหน้าเลือกไฟล์
      final bytes = await file.readAsBytes();

      if (type == MessageType.video && bytes.length > ChatMediaUploader.maxVideoBytes) {
        _snack('วิดีโอใหญ่เกินไป (ส่งได้ไม่เกิน 50 MB)');
        return;
      }

      setState(() => _uploading = true);
      final url = await ref
          .read(chatMediaUploaderProvider)
          .upload(bytes, type: type, chatId: thread.id);
      // ไม่ await: เหมือนข้อความปกติ
      ref
          .read(chatRepositoryProvider)
          .send(
            thread: thread,
            senderId: uid,
            senderName: name,
            type: type,
            mediaUrl: url,
          )
          .catchError((Object e) => _snack(errorMessage(e)));
    } catch (e) {
      _snack(errorMessage(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showAttachMenu(ChatThread thread, String uid, String name) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('รูปภาพจากอัลบั้ม'),
              onTap: () {
                Navigator.pop(ctx);
                _pickMedia(thread, uid, name, type: MessageType.image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('ถ่ายรูป'),
              onTap: () {
                Navigator.pop(ctx);
                _pickMedia(
                  thread,
                  uid,
                  name,
                  type: MessageType.image,
                  source: ImageSource.camera,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('วิดีโอจากอัลบั้ม (ไม่เกิน 50 MB)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickMedia(thread, uid, name, type: MessageType.video);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final live = ref.watch(chatThreadProvider(widget.chatId));
    final thread = live.value ?? widget.initial;

    if (me == null || thread == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
        ),
        body: Center(
          child: live.hasError
              ? Text(errorMessage(live.error))
              : live.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('ไม่พบห้องแชท'),
        ),
      );
    }

    _markReadIfNeeded(thread, me.uid);
    final messages = ref.watch(chatMessagesProvider(widget.chatId));
    final senderName = me.username.isEmpty ? me.fullName : me.username; // แสดงเป็น username ไม่ใช่ชื่อจริง

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(me.isSeller ? '/seller' : '/'),
        ),
        title: Text(thread.titleFor(me.uid)),
      ),
      body: Column(
        children: [
          if (thread.productName != null && thread.productId != null)
            Material(
              color: Colors.white,
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.shopping_bag_outlined),
                title: Text(
                  'สอบถามสินค้า: ${thread.productName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/product/${thread.productId}'),
              ),
            ),
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(errorMessage(e))),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text('ทักทายได้เลย พิมพ์ข้อความด้านล่าง'),
                  );
                }
                return ListView.builder(
                  reverse: true, // list เรียงใหม่สุดก่อน → แสดงใหม่สุดไว้ล่าง
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) =>
                      _Bubble(message: list[i], mine: list[i].senderId == me.uid),
                );
              },
            ),
          ),
          if (_uploading)
            const LinearProgressIndicator(minHeight: 3),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'ส่งรูป/วิดีโอ',
                    onPressed: _uploading
                        ? null
                        : () => _showAttachMenu(thread, me.uid, senderName),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'พิมพ์ข้อความ...',
                        counterText: '',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () => _send(thread, me.uid, senderName),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final maxWidth = MediaQuery.of(context).size.width * 0.75;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: EdgeInsets.all(message.type == MessageType.text ? 12 : 6),
        decoration: BoxDecoration(
          color: mine ? primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.type == MessageType.text)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.text,
                  style: TextStyle(color: mine ? Colors.white : Colors.black87),
                ),
              )
            else
              _MediaContent(message: message),
            const SizedBox(height: 2),
            Text(
              message.createdAt == null
                  ? 'กำลังส่ง...'
                  : chatTimeLabel(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: mine ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// รูป/วิดีโอในฟองแชท (กดเพื่อดูเต็มจอ / เล่นวิดีโอ)
class _MediaContent extends StatelessWidget {
  const _MediaContent({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final url = message.mediaUrl;
    if (url == null) return const Text('ไม่พบไฟล์');
    final isVideo = message.type == MessageType.video;
    final thumb = isVideo ? ChatMediaUploader.videoThumbnail(url) : url;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              isVideo ? VideoViewerPage(url: url) : ImageViewerPage(url: url),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                thumb,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const ColoredBox(
                        color: Colors.black12,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: Colors.black12,
                  child: Icon(
                    isVideo ? Icons.videocam : Icons.broken_image,
                    size: 48,
                    color: Colors.black38,
                  ),
                ),
              ),
              if (isVideo)
                const Center(
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.play_arrow, color: Colors.white, size: 34),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
