import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../domain/address.dart';
import '../state/address_providers.dart';

/// เพิ่ม/แก้ไข/ลบที่อยู่จัดส่ง
class AddressFormPage extends ConsumerStatefulWidget {
  const AddressFormPage({super.key, this.address});

  final Address? address;

  @override
  ConsumerState<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends ConsumerState<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.address?.label);
  late final _name = TextEditingController(text: widget.address?.recipientName);
  late final _phone = TextEditingController(text: widget.address?.phone);
  late final _line1 = TextEditingController(text: widget.address?.line1);
  late final _sub = TextEditingController(text: widget.address?.subdistrict);
  late final _district = TextEditingController(text: widget.address?.district);
  late final _province = TextEditingController(text: widget.address?.province);
  late final _postal = TextEditingController(text: widget.address?.postalCode);
  late bool _isDefault = widget.address?.isDefault ?? false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // เติมชื่อ/เบอร์จากโปรไฟล์ให้ตอนเพิ่มที่อยู่ใหม่ (แก้ได้)
    final me = ref.read(currentUserProvider);
    if (widget.address == null && me != null) {
      _name.text = me.fullName;
      _phone.text = me.phone;
    }
  }

  @override
  void dispose() {
    for (final c in [_label, _name, _phone, _line1, _sub, _district, _province, _postal]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String what) =>
      (v == null || v.trim().isEmpty) ? 'กรุณากรอก$what' : null;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(addressDataSourceProvider).save(
            Address(
              id: widget.address?.id ?? '',
              uid: me.uid,
              label: _label.text.trim(),
              recipientName: _name.text.trim(),
              phone: _phone.text.trim(),
              line1: _line1.text.trim(),
              subdistrict: _sub.text.trim(),
              district: _district.text.trim(),
              province: _province.text.trim(),
              postalCode: _postal.text.trim(),
              isDefault: _isDefault,
            ),
            existing: ref.read(addressesProvider).value ?? const [],
          );
      if (mounted) context.pop();
    } catch (e) {
      _snack(errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบที่อยู่นี้?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(addressDataSourceProvider).delete(widget.address!.id);
      if (ref.read(selectedAddressIdProvider) == widget.address!.id) {
        ref.read(selectedAddressIdProvider.notifier).set(null);
      }
      if (mounted) context.pop();
    } catch (e) {
      _snack(errorMessage(e));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.address != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'แก้ไขที่อยู่' : 'เพิ่มที่อยู่'),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'ลบ',
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'ชื่อที่อยู่ (เช่น บ้าน, ที่ทำงาน)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'ชื่อผู้รับ'),
              validator: (v) => _required(v, 'ชื่อผู้รับ'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'เบอร์โทรผู้รับ'),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'กรุณากรอกเบอร์โทร';
                if (!RegExp(r'^[0-9]{9,10}$').hasMatch(t)) return 'เบอร์โทรต้องเป็นตัวเลข 9-10 หลัก';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _line1,
              decoration: const InputDecoration(labelText: 'บ้านเลขที่ / ถนน / ซอย'),
              validator: (v) => _required(v, 'ที่อยู่'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sub,
              decoration: const InputDecoration(labelText: 'ตำบล / แขวง'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _district,
              decoration: const InputDecoration(labelText: 'อำเภอ / เขต'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _province,
              decoration: const InputDecoration(labelText: 'จังหวัด'),
              validator: (v) => _required(v, 'จังหวัด'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _postal,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'รหัสไปรษณีย์'),
              validator: (v) =>
                  RegExp(r'^[0-9]{5}$').hasMatch((v ?? '').trim()) ? null : 'รหัสไปรษณีย์ 5 หลัก',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ตั้งเป็นที่อยู่เริ่มต้น'),
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }
}
