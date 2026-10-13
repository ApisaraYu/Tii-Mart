import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../domain/entities/chat.dart';
import '../state/chat_providers.dart';
import '../widgets/chat_time.dart';

/// รายการห้องแชท — ใช้ร่วมกันทั้งลูกค้า (/chats) และร้านค้า (แท็บแชทใน /seller/chats)
class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key, this.bottomNavigationBar});

  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final chats = ref.watch(myChatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('แชท')),
      bottomNavigationBar: bottomNavigationBar,
      body: me == null
          ? const SizedBox.shrink()
          : chats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(errorMessage(e), textAlign: TextAlign.center),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        me.isSeller
                            ? 'ยังไม่มีข้อความจากลูกค้า'
                            : 'ยังไม่มีแชท\nเปิดหน้าสินค้าแล้วกด "แชทกับร้านค้า" ได้เลย',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _ChatTile(thread: list[i], myUid: me.uid),
                );
              },
            ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.thread, required this.myUid});

  final ChatThread thread;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    final unread = thread.unreadFor(myUid);
    final title = thread.titleFor(myUid);
    final mine = thread.lastSenderId == myUid;

    return ListTile(
      tileColor: Colors.white,
      onTap: () => context.push('/chat/${thread.id}', extra: thread),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          title.isEmpty ? '?' : String.fromCharCode(title.runes.first),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${mine ? 'คุณ: ' : ''}${thread.lastMessage}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w400,
          color: unread > 0 ? Colors.black87 : null,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(chatTimeLabel(thread.lastMessageAt),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          if (unread > 0)
            Badge.count(count: unread)
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}
