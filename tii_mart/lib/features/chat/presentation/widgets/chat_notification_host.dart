import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../domain/entities/chat.dart';
import '../state/chat_providers.dart';
import '../../../../app/theme/app_theme.dart';

/// แบนเนอร์แจ้งเตือน "ข้อความใหม่" เด้งจากด้านบนของจอ (ขณะเปิดแอพอยู่)
/// ครอบแอพทั้งหมดผ่าน MaterialApp.router(builder: ...)
/// ไม่เด้งถ้า: ข้อความเราส่งเอง / กำลังเปิดห้องนั้นอยู่ / โหลดข้อมูลครั้งแรก
class ChatNotificationHost extends ConsumerStatefulWidget {
  const ChatNotificationHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ChatNotificationHost> createState() =>
      _ChatNotificationHostState();
}

class _ChatNotificationHostState extends ConsumerState<ChatNotificationHost> {
  final Map<String, DateTime?> _seen = {};
  final Set<String> _nameSynced = {};
  bool _primed = false;
  ChatThread? _banner;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onChats(List<ChatThread> chats) {
    final me = ref.read(currentUserProvider);
    if (me == null) {
      _seen.clear();
      _nameSynced.clear();
      _primed = false;
      return;
    }
        // ชื่อในห้องเป็นสำเนา: ถ้าไม่ตรงกับ username ปัจจุบัน ให้แก้ให้ตรง
    if (me.username.isNotEmpty) {
      for (final t in chats) {
        final stored = me.uid == t.customerId ? t.customerName : t.sellerName;
        if (stored != me.username && _nameSynced.add(t.id)) {
          ref
              .read(chatRepositoryProvider)
              .syncName(thread: t, uid: me.uid, name: me.username)
              .catchError((_) {});
        }
      }
    }

    ChatThread? fresh;
    for (final t in chats) {
      final changed = !_seen.containsKey(t.id) ||
          _seen[t.id]?.millisecondsSinceEpoch !=
              t.lastMessageAt?.millisecondsSinceEpoch;
      _seen[t.id] = t.lastMessageAt;
      if (_primed &&
          changed &&
          t.lastSenderId != null &&
          t.lastSenderId != me.uid &&
          t.unreadFor(me.uid) > 0 &&
          t.id != ChatPresence.activeChatId) {
        fresh = t; // เก็บอันล่าสุด (รายการเรียงใหม่สุดก่อน → อันแรกที่เจอ)
        break;
      }
    }
    _primed = true;
    if (fresh != null) _show(fresh);
  }

  void _show(ChatThread t) {
    _timer?.cancel();
    setState(() => _banner = t);
    _timer = Timer(const Duration(seconds: 5), _hide);
  }

  void _hide() {
    _timer?.cancel();
    if (mounted) setState(() => _banner = null);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<ChatThread>>>(myChatsProvider, (_, next) {
      final data = next.value;
      if (data != null) _onChats(data);
    });
    // ล็อกเอาต์ → ล้างสถานะ กันเด้งผิดคนเมื่อสลับบัญชี
    ref.listen(currentUserProvider.select((u) => u?.uid), (prev, next) {
      if (prev != next) {
        _seen.clear();
        _nameSynced.clear();
        _primed = false;
        _hide();
      }
    });

    final me = ref.watch(currentUserProvider);
    final banner = _banner;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (banner != null && me != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).cardColor,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      _hide();
                      ref
                          .read(routerProvider)
                          .push('/chat/${banner.id}', extra: banner);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: const Icon(Icons.chat_bubble,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  banner.titleFor(me.uid),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  banner.lastMessage,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.ink54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: _hide,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
