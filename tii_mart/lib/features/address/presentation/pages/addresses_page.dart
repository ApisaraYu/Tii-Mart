import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../state/address_providers.dart';

/// รายการที่อยู่จัดส่ง — [pick] = true เปิดมาจากหน้าชำระเงิน: กดเลือกแล้วย้อนกลับ
class AddressesPage extends ConsumerWidget {
  const AddressesPage({super.key, this.pick = false});

  final bool pick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    final selected = ref.watch(checkoutAddressProvider);

    return Scaffold(
      appBar: AppBar(title: Text(pick ? 'เลือกที่อยู่จัดส่ง' : 'ที่อยู่ของฉัน')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/addresses/new'),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มที่อยู่'),
      ),
      body: addresses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(errorMessage(e))),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('ยังไม่มีที่อยู่ กด "เพิ่มที่อยู่" ได้เลย'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final a = list[i];
              return Card(
                margin: EdgeInsets.zero,
                color: Colors.white,
                child: ListTile(
                  onTap: pick
                      ? () {
                          ref.read(selectedAddressIdProvider.notifier).set(a.id);
                          context.pop();
                        }
                      : () => context.push('/addresses/edit', extra: a),
                  leading: pick
                      ? Icon(
                          selected?.id == a.id
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        )
                      : const Icon(Icons.location_on_outlined),
                  title: Text(
                    '${a.recipientName} • ${a.phone}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${a.label.isEmpty ? '' : '[${a.label}] '}${a.fullText}'
                    '${a.isDefault ? '\n(ค่าเริ่มต้น)' : ''}',
                  ),
                  isThreeLine: a.isDefault,
                  trailing: pick
                      ? IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => context.push('/addresses/edit', extra: a),
                        )
                      : const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
