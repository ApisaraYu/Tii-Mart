import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/app_text_field.dart';

/// ข้อมูลตัวเลือกย่อย 1 แถวที่กำลังแก้ไขในฟอร์ม
class VariantDraft {
  VariantDraft({
    this.id = '',
    String color = '',
    String size = '',
    String price = '',
    String stock = '',
  })  : color = TextEditingController(text: color),
        size = TextEditingController(text: size),
        price = TextEditingController(text: price),
        stock = TextEditingController(text: stock);

  final String id; // ว่าง = ตัวเลือกใหม่
  final TextEditingController color;
  final TextEditingController size;
  final TextEditingController price;
  final TextEditingController stock;

  void dispose() {
    color.dispose();
    size.dispose();
    price.dispose();
    stock.dispose();
  }
}

/// รายการตัวเลือกย่อย (สี/ขนาด + ราคา + สต๊อก) เพิ่ม/ลบแถวได้ อย่างน้อย 1 แถว
class VariantEditor extends StatelessWidget {
  const VariantEditor({
    super.key,
    required this.drafts,
    required this.onAdd,
    required this.onRemove,
    this.enabled = true,
  });

  final List<VariantDraft> drafts;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < drafts.length; i++)
          Card(
            key: ObjectKey(drafts[i]),
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ตัวเลือกที่ ${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: 'ลบตัวเลือกนี้',
                        icon: const Icon(Icons.delete_outline),
                        onPressed:
                            enabled && drafts.length > 1 ? () => onRemove(i) : null,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: drafts[i].color,
                          label: 'สี (ถ้ามี)',
                          enabled: enabled,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextField(
                          controller: drafts[i].size,
                          label: 'ขนาด/ความจุ (ถ้ามี)',
                          enabled: enabled,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: drafts[i].price,
                          label: 'ราคา (บาท)',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: Validators.price,
                          enabled: enabled,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextField(
                          controller: drafts[i].stock,
                          label: 'สต๊อก (ชิ้น)',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: Validators.stock,
                          enabled: enabled,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: enabled ? onAdd : null,
          icon: const Icon(Icons.add),
          label: const Text('เพิ่มตัวเลือก (สี / ขนาด)'),
        ),
      ],
    );
  }
}
