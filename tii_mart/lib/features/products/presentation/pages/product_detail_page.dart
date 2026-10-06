import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/format.dart';
import '../../domain/entities/product.dart';
import '../state/product_providers.dart';

/// หน้ารายละเอียดสินค้า: รูป เลือกตัวเลือก (สี/ขนาด) ราคา สต๊อก สเปก
class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  late Future<Product> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(productRepositoryProvider).getProduct(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage(snap.error), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => setState(_load),
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return _DetailView(product: snap.data!);
      },
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView({required this.product});

  final Product product;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  final _pageController = PageController();
  int _imageIndex = 0;
  late int _variantIndex;

  Product get p => widget.product;

  @override
  void initState() {
    super.initState();
    // เริ่มที่ตัวเลือกแรกที่ยังมีของ (ถ้าหมดทุกตัวเลือก เริ่มที่ตัวแรก)
    final firstInStock = p.variants.indexWhere((v) => v.stock > 0);
    _variantIndex = firstInStock >= 0 ? firstInStock : 0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    final variant = p.variants.isEmpty ? null : p.variants[_variantIndex];
    final price = variant?.price ?? p.minPrice;
    final stock = variant?.stock ?? p.totalStock;

    final specRows = <MapEntry<String, String>>[
      if (p.specs.cpu.isNotEmpty) MapEntry('CPU / ชิป', p.specs.cpu),
      if (p.specs.ram.isNotEmpty) MapEntry('RAM', p.specs.ram),
      if (p.specs.storage.isNotEmpty) MapEntry('พื้นที่เก็บข้อมูล', p.specs.storage),
      if (p.specs.os.isNotEmpty) MapEntry('ระบบปฏิบัติการ', p.specs.os),
      if (p.specs.ports.isNotEmpty) MapEntry('พอร์ต', p.specs.ports.join(', ')),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดสินค้า')),
      body: ListView(
        children: [
          // ---------- รูป ----------
          AspectRatio(
            aspectRatio: 1.2,
            child: p.images.isEmpty
                ? const ColoredBox(
                    color: Color(0xFFEAEAEA),
                    child: Icon(Icons.image_outlined, size: 56),
                  )
                : Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: p.images.length,
                        onPageChanged: (i) => setState(() => _imageIndex = i),
                        itemBuilder: (_, i) => Image.network(
                          p.images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFEAEAEA),
                            child: Icon(Icons.broken_image_outlined, size: 56),
                          ),
                        ),
                      ),
                      if (p.images.length > 1)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_imageIndex + 1}/${p.images.length}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  [if (p.brand.isNotEmpty) p.brand, p.category].join(' • '),
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '฿${formatBaht(price)}',
                  style: textTheme.headlineSmall?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stock > 0 ? 'คงเหลือ $stock ชิ้น' : 'สินค้าหมด',
                  style: TextStyle(
                    color: stock > 0 ? Colors.green[800] : Colors.red[700],
                  ),
                ),

                // ---------- ตัวเลือก ----------
                if (p.variants.length > 1) ...[
                  const SizedBox(height: 16),
                  Text('ตัวเลือก', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < p.variants.length; i++)
                        ChoiceChip(
                          label: Text(
                            p.variants[i].stock > 0
                                ? p.variants[i].label
                                : '${p.variants[i].label} (หมด)',
                          ),
                          selected: _variantIndex == i,
                          onSelected: (_) => setState(() => _variantIndex = i),
                        ),
                    ],
                  ),
                ],

                // ---------- สเปก ----------
                if (specRows.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('สเปก', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.white,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          for (final r in specRows)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 130,
                                    child: Text(r.key, style: textTheme.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text(
                                      r.value,
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],

                // ---------- รายละเอียด ----------
                if (p.description.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('รายละเอียดสินค้า', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(p.description),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: stock > 0
                  ? () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('ระบบรถเข็นจะเพิ่มในขั้นถัดไป'),
                      ),
                    )
                  : null,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('เพิ่มลงรถเข็น'),
            ),
          ),
        ),
      ),
    );
  }
}
