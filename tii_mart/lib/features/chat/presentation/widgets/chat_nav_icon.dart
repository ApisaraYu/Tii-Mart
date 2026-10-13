import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/chat_providers.dart';

/// ไอคอนแชท + ตัวเลขข้อความที่ยังไม่อ่าน
class ChatNavIcon extends ConsumerWidget {
  const ChatNavIcon({super.key, this.selected = false});

  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadTotalProvider);
    return Badge.count(
      count: count,
      isLabelVisible: count > 0,
      child: Icon(
        selected ? Icons.chat_bubble : Icons.chat_bubble_outline,
      ),
    );
  }
}
