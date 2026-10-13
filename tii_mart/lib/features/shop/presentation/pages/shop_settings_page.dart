import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/promptpay.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../state/shop_providers.dart';

/// ตั้งค่าร้าน: ชื่อร้าน + พร้อมเพย์สำหรับรับเงิน (ลูกค้าจะเห็น QR ของร้านตอนชำระเงิน)
class ShopSettingsPage extends ConsumerStatefulWidget {
  const ShopSettingsPage({super.key});

  @override
  ConsumerState<ShopSettingsPage> createState() => _ShopSettingsPageState();
}

class _ShopSettingsPageState extends ConsumerState<ShopSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _promptPay = TextEditingController();
  bool _loaded = false;
  bool _exists = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _promptPay.dispose();
    super.dispose();
  }

  Future<void> _save(String uid) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(shopDataSourceProvider).save(
            ownerId: uid,
            name: _name.text.trim(),
            promptPayId: _promptPay.text.replaceAll(RegExp(r'[^0-9]'), ''),
            isNew: !_exists,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลร้านแล้ว')));
      if (context.canPop()) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const Scaffold();
    final shop = ref.watch(shopProvider(me.uid));

    // เติมค่าเดิมในฟอร์มครั้งเดียวเมื่อโหลดเสร็จ
    if (!_loaded && shop.hasValue) {
      _loaded = true;
      _exists = shop.value != null;
      _name.text = shop.value?.name ?? '';
      _promptPay.text = shop.value?.promptPayId ?? '';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่าร้านค้า')),
      body: !_loaded
          ? Center(
              child: shop.hasError
                  ? Text(errorMessage(shop.error))
                  : const CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'ชื่อร้านค้า'),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'กรุณากรอกชื่อร้าน' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _promptPay,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'พร้อมเพย์สำหรับรับเงิน',
                      helperText: 'เบอร์มือถือ 10 หลัก หรือเลขบัตรประชาชน 13 หลัก',
                    ),
                    validator: (v) => PromptPay.isValidId(v ?? '')
                        ? null
                        : 'ต้องเป็นเบอร์มือถือ 10 หลัก หรือเลขบัตร 13 หลัก',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ลูกค้าจะสแกน QR นี้เพื่อโอนเงินเข้าบัญชีพร้อมเพย์ของคุณโดยตรง '
                    'ตรวจสอบเลขให้ถูกต้องก่อนบันทึก',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _busy ? null : () => _save(me.uid),
                    child: const Text('บันทึก'),
                  ),
                ],
              ),
            ),
    );
  }
}
