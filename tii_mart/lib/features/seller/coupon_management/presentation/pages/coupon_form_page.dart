import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/format.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../auth/presentation/state/auth_providers.dart';
import '../../../../coupon/domain/entities/coupon.dart';
import '../../../../coupon/presentation/state/coupon_providers.dart';

/// สร้าง/แก้ไขโค้ดส่วนลด — coupon == null คือสร้างใหม่
class CouponFormPage extends ConsumerStatefulWidget {
  const CouponFormPage({super.key, this.coupon});

  final Coupon? coupon;

  @override
  ConsumerState<CouponFormPage> createState() => _CouponFormPageState();
}

class _CouponFormPageState extends ConsumerState<CouponFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _description;
  late final TextEditingController _value;
  late final TextEditingController _minSpend;
  late final TextEditingController _quantity;
  late DiscountType _type;
  late bool _isActive;
  DateTime? _expiresAt;

  bool get _isNew => widget.coupon == null;

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _code = TextEditingController(text: c?.code ?? '');
    _description = TextEditingController(text: c?.description ?? '');
    _value = TextEditingController(text: c == null ? '' : '${c.value}');
    _minSpend = TextEditingController(text: c == null ? '0' : '${c.minSpend}');
    _quantity = TextEditingController(text: c == null ? '' : '${c.quantity}');
    _type = c?.type ?? DiscountType.percent;
    _isActive = c?.isActive ?? true;
    _expiresAt = c?.expiresAt;
  }

  @override
  void dispose() {
    _code.dispose();
    _description.dispose();
    _value.dispose();
    _minSpend.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    // หมดอายุสิ้นวันที่เลือก
    setState(() {
      _expiresAt = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
    });
  }

  String? _intField(String? v, {required String name, int min = 0, int? max}) {
    if (v == null || v.trim().isEmpty) return 'กรุณากรอก$name';
    final n = int.tryParse(v.trim());
    if (n == null) return '$nameต้องเป็นตัวเลข';
    if (n < min) return '$nameต้องไม่น้อยกว่า $min';
    if (max != null && n > max) return '$nameต้องไม่เกิน $max';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _snack('กรุณากรอกข้อมูลให้ครบและถูกต้อง');
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _snack('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
      return;
    }
    final old = widget.coupon;
    final coupon = Coupon(
      id: old?.id ?? '',
      ownerId: user.uid,
      code: _code.text.trim().toUpperCase(),
      description: _description.text.trim(),
      type: _type,
      value: int.parse(_value.text.trim()),
      minSpend: int.parse(_minSpend.text.trim()),
      quantity: int.parse(_quantity.text.trim()),
      used: old?.used ?? 0,
      isActive: _isActive,
      expiresAt: _expiresAt,
      createdAt: old?.createdAt,
    );
    final ok = await ref
        .read(couponManagementControllerProvider.notifier)
        .save(coupon, isNew: _isNew);
    if (!mounted || !ok) return;
    _snack(_isNew ? 'สร้างโค้ดแล้ว' : 'บันทึกการแก้ไขแล้ว');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(couponManagementControllerProvider, (prev, next) {
      if (next.hasError) _snack(errorMessage(next.error));
    });
    final loading = ref.watch(couponManagementControllerProvider).isLoading;
    final enabled = !loading;
    const gap = SizedBox(height: 12);

    return PopScope(
      canPop: !loading,
      child: Scaffold(
        appBar: AppBar(title: Text(_isNew ? 'สร้างโค้ดส่วนลด' : 'แก้ไขโค้ดส่วนลด')),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppTextField(
                    controller: _code,
                    label: 'รหัสโค้ด เช่น TII50 (A-Z, 0-9)',
                    enabled: enabled && _isNew, // แก้รหัสหลังสร้างไม่ได้
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.length < 3) return 'รหัสโค้ดต้องมีอย่างน้อย 3 ตัวอักษร';
                      return null;
                    },
                  ),
                  gap,
                  AppTextField(
                    controller: _description,
                    label: 'คำอธิบาย (ถ้ามี)',
                    enabled: enabled,
                  ),
                  gap,
                  SegmentedButton<DiscountType>(
                    segments: const [
                      ButtonSegment(
                        value: DiscountType.percent,
                        label: Text('ลดเป็น %'),
                      ),
                      ButtonSegment(
                        value: DiscountType.fixed,
                        label: Text('ลดเป็นบาท'),
                      ),
                      ButtonSegment(
                        value: DiscountType.freeShipping,
                        label: Text('ส่งฟรี'),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: enabled
                        ? (s) => setState(() => _type = s.first)
                        : null,
                  ),
                  gap,
                  AppTextField(
                    controller: _value,
                    label: switch (_type) {
                      DiscountType.percent => 'ส่วนลด (1-100 %)',
                      DiscountType.fixed => 'ส่วนลด (บาท)',
                      DiscountType.freeShipping =>
                        'ลดค่าส่งสูงสุด (บาท) — 0 = ส่งฟรีเต็มจำนวน',
                    },
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => _intField(
                      v,
                      name: 'ส่วนลด',
                      min: _type == DiscountType.freeShipping ? 0 : 1,
                      max: _type == DiscountType.percent ? 100 : null,
                    ),
                  ),
                  gap,
                  AppTextField(
                    controller: _minSpend,
                    label: 'ยอดซื้อขั้นต่ำ (บาท, 0 = ไม่มี)',
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => _intField(v, name: 'ยอดขั้นต่ำ'),
                  ),
                  gap,
                  AppTextField(
                    controller: _quantity,
                    label: 'จำนวนโค้ดทั้งหมด',
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.done,
                    validator: (v) => _intField(
                      v,
                      name: 'จำนวนโค้ด',
                      min: (widget.coupon?.used ?? 0) > 0 ? widget.coupon!.used : 1,
                    ),
                  ),
                  gap,
                  Card(
                    color: Colors.white,
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: Text(
                        _expiresAt == null
                            ? 'ไม่กำหนดวันหมดอายุ'
                            : 'หมดอายุ ${formatDate(_expiresAt!)}',
                      ),
                      trailing: _expiresAt == null
                          ? null
                          : IconButton(
                              tooltip: 'ล้างวันหมดอายุ',
                              icon: const Icon(Icons.clear),
                              onPressed: enabled
                                  ? () => setState(() => _expiresAt = null)
                                  : null,
                            ),
                      onTap: enabled ? _pickDate : null,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('เปิดใช้งานโค้ด'),
                    value: _isActive,
                    onChanged: enabled ? (v) => setState(() => _isActive = v) : null,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: enabled ? _submit : null,
                      child: const Text('บันทึกโค้ด'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (loading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
