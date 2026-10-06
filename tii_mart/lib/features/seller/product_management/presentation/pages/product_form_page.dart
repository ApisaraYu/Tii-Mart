import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/product_options.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../auth/presentation/state/auth_providers.dart';
import '../../../../products/domain/entities/product.dart';
import '../../../../products/presentation/state/product_providers.dart';
import '../state/product_management_controller.dart';
import '../widgets/image_picker_section.dart';
import '../widgets/variant_editor.dart';

/// หน้าเพิ่ม/แก้ไขสินค้า — productId == null คือเพิ่มใหม่, มีค่าคือแก้ไข
class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  Future<Product?>? _future;

  @override
  void initState() {
    super.initState();
    final id = widget.productId;
    if (id != null) {
      _future = ref.read(productRepositoryProvider).getProduct(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.productId == null ? 'เพิ่มสินค้า' : 'แก้ไขสินค้า';
    if (_future == null) return _ProductForm(title: title, initial: null);

    return FutureBuilder<Product?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || snap.data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Center(
              child: Text(
                snap.hasError ? errorMessage(snap.error) : 'ไม่พบสินค้านี้',
              ),
            ),
          );
        }
        return _ProductForm(title: title, initial: snap.data);
      },
    );
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({required this.title, required this.initial});

  final String title;
  final Product? initial;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  static const _maxImages = 8;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _brand;
  late final TextEditingController _cpu;
  late final TextEditingController _ram;
  late final TextEditingController _storage;
  late final TextEditingController _ports;

  late String _category;
  late String _os;
  late List<String> _existingUrls;
  final List<Uint8List> _newImages = [];
  late final List<VariantDraft> _variants;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _cpu = TextEditingController(text: p?.specs.cpu ?? '');
    _ram = TextEditingController(text: p?.specs.ram ?? '');
    _storage = TextEditingController(text: p?.specs.storage ?? '');
    _ports = TextEditingController(text: p?.specs.ports.join(', ') ?? '');

    _category = (p != null && productCategories.contains(p.category))
        ? p.category
        : productCategories.first;
    final os = p?.specs.os ?? '';
    _os = osOptions.contains(os) ? os : 'ไม่ระบุ';
    _existingUrls = [...?p?.images];

    _variants = [
      if (p != null)
        for (final v in p.variants)
          VariantDraft(
            id: v.id,
            color: v.color,
            size: v.size,
            price: '${v.price}',
            stock: '${v.stock}',
          ),
    ];
    if (_variants.isEmpty) _variants.add(VariantDraft());
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _brand, _cpu, _ram, _storage, _ports]) {
      c.dispose();
    }
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final room = _maxImages - _existingUrls.length - _newImages.length;
    if (room <= 0) return;
    try {
      final files = await ImagePicker().pickMultiImage(
        imageQuality: 80,
        maxWidth: 1280,
      );
      final picked = <Uint8List>[];
      for (final f in files.take(room)) {
        picked.add(await f.readAsBytes());
      }
      if (!mounted || picked.isEmpty) return;
      setState(() => _newImages.addAll(picked));
    } catch (_) {
      _snack('เลือกรูปไม่สำเร็จ ลองใหม่อีกครั้ง');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _snack('กรุณากรอกข้อมูลให้ครบและถูกต้อง');
      return;
    }
    if (_existingUrls.isEmpty && _newImages.isEmpty) {
      _snack('กรุณาเพิ่มรูปสินค้าอย่างน้อย 1 รูป');
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _snack('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
      return;
    }

    final variants = [
      for (final d in _variants)
        Variant(
          id: d.id,
          color: d.color.text.trim(),
          size: d.size.text.trim(),
          price: int.parse(d.price.text.trim()),
          stock: int.parse(d.stock.text.trim()),
        ),
    ];
    final minPrice =
        variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
    final totalStock = variants.fold<int>(0, (sum, v) => sum + v.stock);

    final ports = _ports.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final old = widget.initial;
    final draft = Product(
      id: old?.id ?? '',
      ownerId: user.uid,
      shopId: user.shopId ?? user.uid,
      name: _name.text.trim(),
      description: _description.text.trim(),
      category: _category,
      brand: _brand.text.trim(),
      specs: ProductSpecs(
        cpu: _cpu.text.trim(),
        ram: _ram.text.trim(),
        storage: _storage.text.trim(),
        os: _os == 'ไม่ระบุ' ? '' : _os,
        ports: ports,
      ),
      images: _existingUrls,
      variants: variants,
      minPrice: minPrice,
      totalStock: totalStock,
      isActive: old?.isActive ?? true,
      createdAt: old?.createdAt,
    );

    final ok = await ref
        .read(productManagementControllerProvider.notifier)
        .save(draft: draft, newImages: _newImages);
    if (!mounted || !ok) return;
    _snack(old == null ? 'เพิ่มสินค้าแล้ว' : 'บันทึกการแก้ไขแล้ว');
    context.pop();
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String) onChanged,
    required bool enabled,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: [
            for (final i in items) DropdownMenuItem(value: i, child: Text(i)),
          ],
          onChanged: enabled
              ? (v) {
                  if (v != null) onChanged(v);
                }
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(productManagementControllerProvider,
        (prev, next) {
      if (next.hasError) _snack(errorMessage(next.error));
    });
    final loading = ref.watch(productManagementControllerProvider).isLoading;
    final enabled = !loading;
    const gap = SizedBox(height: 12);

    Widget heading(String t) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(t, style: Theme.of(context).textTheme.titleMedium),
        );

    return PopScope(
      canPop: !loading,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  heading('รูปสินค้า'),
                  ImagePickerSection(
                    existingUrls: _existingUrls,
                    newImages: _newImages,
                    maxImages: _maxImages,
                    enabled: enabled,
                    onAdd: _pickImages,
                    onRemoveExisting: (i) =>
                        setState(() => _existingUrls.removeAt(i)),
                    onRemoveNew: (i) => setState(() => _newImages.removeAt(i)),
                  ),
                  heading('ข้อมูลทั่วไป'),
                  AppTextField(
                    controller: _name,
                    label: 'ชื่อสินค้า',
                    enabled: enabled,
                    validator: (v) => Validators.required(v, 'ชื่อสินค้า'),
                  ),
                  gap,
                  _dropdown(
                    label: 'หมวดหมู่',
                    value: _category,
                    items: productCategories,
                    enabled: enabled,
                    onChanged: (v) => setState(() => _category = v),
                  ),
                  gap,
                  AppTextField(
                    controller: _brand,
                    label: 'ยี่ห้อ',
                    enabled: enabled,
                  ),
                  gap,
                  AppTextField(
                    controller: _description,
                    label: 'รายละเอียดสินค้า',
                    maxLines: 4,
                    enabled: enabled,
                  ),
                  heading('สเปก'),
                  AppTextField(
                    controller: _cpu,
                    label: 'CPU / ชิป (ถ้ามี)',
                    enabled: enabled,
                  ),
                  gap,
                  AppTextField(
                    controller: _ram,
                    label: 'RAM เช่น 16GB (ถ้ามี)',
                    enabled: enabled,
                  ),
                  gap,
                  AppTextField(
                    controller: _storage,
                    label: 'พื้นที่เก็บข้อมูล เช่น 512GB SSD (ถ้ามี)',
                    enabled: enabled,
                  ),
                  gap,
                  _dropdown(
                    label: 'ระบบปฏิบัติการที่รองรับ',
                    value: _os,
                    items: osOptions,
                    enabled: enabled,
                    onChanged: (v) => setState(() => _os = v),
                  ),
                  gap,
                  AppTextField(
                    controller: _ports,
                    label: 'พอร์ต คั่นด้วยจุลภาค เช่น USB-C, HDMI',
                    enabled: enabled,
                    textInputAction: TextInputAction.done,
                  ),
                  heading('ตัวเลือกสินค้า (สี/ขนาด ราคา สต๊อก)'),
                  VariantEditor(
                    drafts: _variants,
                    enabled: enabled,
                    onAdd: () => setState(() => _variants.add(VariantDraft())),
                    onRemove: (i) {
                      if (_variants.length <= 1) {
                        _snack('ต้องมีตัวเลือกอย่างน้อย 1 รายการ');
                        return;
                      }
                      final removed = _variants.removeAt(i);
                      setState(() {});
                      // dispose หลังเฟรมถัดไป กัน widget เก่ายังอ่าน controller อยู่
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => removed.dispose());
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: enabled ? _submit : null,
                      child: const Text('บันทึกสินค้า'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (loading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
