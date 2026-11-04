import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/product.dart';
import '../../../../app/theme/app_theme.dart';

/// หน้ารายละเอียดสเปก ตาม wireframe (description page):
/// คำอธิบาย + ตารางสเปก (ซ้าย: หัวข้อ / ขวา: รายละเอียด) + ปุ่มย้อนกลับ
/// รับ Product ผ่าน extra ของ go_router (ถ้ารีเฟรชหน้าเว็บ extra จะหาย → แสดงข้อความแทน)
class ProductSpecsPage extends StatelessWidget {
  const ProductSpecsPage({super.key, required this.extra});

  final Object? extra;

  @override
  Widget build(BuildContext context) {
    final product = extra is Product ? extra as Product : null;

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดสินค้า')),
      body: product == null
          ? const Center(child: Text('ไม่พบข้อมูล กรุณากลับไปเปิดสินค้าใหม่'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(child: _SpecsCard(product: product)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('ย้อนกลับ'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SpecsCard extends StatelessWidget {
  const _SpecsCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final s = product.specs;
    final rows = <MapEntry<String, String>>[
      if (s.cpu.isNotEmpty) MapEntry('CPU / ชิป', s.cpu),
      if (s.ram.isNotEmpty) MapEntry('RAM', s.ram),
      if (s.storage.isNotEmpty) MapEntry('ความจุ', s.storage),
      if (s.os.isNotEmpty) MapEntry('ระบบปฏิบัติการ', s.os),
      if (s.ports.isNotEmpty) MapEntry('พอร์ต', s.ports.join(', ')),
    ];

    return Card(
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              product.description.isEmpty
                  ? 'ผู้ขายยังไม่ได้ใส่คำอธิบายสินค้า'
                  : product.description,
            ),
            const SizedBox(height: 20),
            Text('สเปก', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const Text('ผู้ขายยังไม่ได้ระบุสเปก')
            else
              Table(
                columnWidths: const {
                  0: FixedColumnWidth(120),
                  1: FlexColumnWidth(),
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: context.placeholder(const Color(0xFFE0E0E0))),
                  top: BorderSide(color: context.placeholder(const Color(0xFFE0E0E0))),
                  bottom: BorderSide(color: context.placeholder(const Color(0xFFE0E0E0))),
                ),
                children: [
                  for (final r in rows)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(r.key),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            r.value,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
