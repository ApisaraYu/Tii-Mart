import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/state/cart_providers.dart';
import '../../../chat/domain/entities/chat.dart';
import '../../../home/presentation/widgets/customer_bottom_nav.dart';
import '../../../compare/presentation/state/compare_providers.dart';
import '../../../shop/presentation/pages/shop_profile_page.dart';
import '../../../shop/presentation/state/shop_providers.dart';
import '../../domain/entities/product.dart';
import '../state/product_providers.dart';

/// หน้าสินค้า ตาม wireframe (product page):
/// รูป (ปุ่ม < >) → ชื่อ/ราคา → ตัวเลือก + จำนวน → กล่องคำอธิบาย (ดูเพิ่มเติม) → ปุ่มเพิ่มลงรถเข็น
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

class _DetailView extends ConsumerStatefulWidget {
  const _DetailView({required this.product});

  final Product product;

  @override
  ConsumerState<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<_DetailView> {
  final _pageController = PageController();
  int _imageIndex = 0;
  int _variantIndex = 0;
  int _qty = 1;

  Product get p => widget.product;
  Variant? get _variant => p.variants.isEmpty ? null : p.variants[_variantIndex];
  int get _price => _variant?.price ?? p.minPrice;
  int get _stock => _variant?.stock ?? p.totalStock;

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

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickVariant() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var i = 0; i < p.variants.length; i++)
              ListTile(
                enabled: p.variants[i].stock > 0,
                selected: i == _variantIndex,
                title: Text(p.variants[i].label),
                subtitle: Text(
                  p.variants[i].stock > 0
                      ? '฿${formatBaht(p.variants[i].price)} • คงเหลือ ${p.variants[i].stock} ชิ้น'
                      : 'สินค้าหมด',
                ),
                trailing: i == _variantIndex ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, i),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _variantIndex = picked;
      _qty = 1;
    });
  }

  void _changeQty(int delta) {
    final next = _qty + delta;
    if (next < 1) return;
    if (next > _stock) {
      _snack('มีสินค้าคงเหลือ $_stock ชิ้น');
      return;
    }
    setState(() => _qty = next);
  }

  /// ผู้เยี่ยมชม: พาไปเข้าสู่ระบบ แล้วกลับมาที่หน้าสินค้านี้
  void _goLogin() {
    context.push('/login?from=${Uri.encodeComponent('/product/${p.id}')}');
  }

  /// เปิดห้องแชทกับเจ้าของสินค้า (ห้องเดิมถ้าเคยคุยแล้ว)
  void _openChat() {
    final me = ref.read(currentUserProvider);
    if (me == null) {
      _goLogin();
      return;
    }
    if (me.uid == p.ownerId) {
      _snack('นี่คือสินค้าของคุณเอง');
      return;
    }
    final id = ChatThread.idFor(me.uid, p.ownerId);
    context.push(
      '/chat/$id',
      extra: ChatThread(
        id: id,
        customerId: me.uid,
        sellerId: p.ownerId,
        productId: p.id,
        productName: p.name,
      ),
    );
  }

  Future<void> _addToCart() async {
    if (_stock <= 0) {
      _snack('สินค้านี้หมดแล้ว');
      return;
    }
    final me = ref.read(currentUserProvider);
    if (me == null) {
      _goLogin();
      return;
    }
    if (me.uid == p.ownerId) {
      _snack('ไม่สามารถสั่งซื้อสินค้าของร้านตัวเองได้');
      return;
    }
    final v = _variant;
    final variantId = (v != null && v.id.isNotEmpty) ? v.id : 'default';
    try {
      await ref.read(cartDataSourceProvider).add(
            CartItem(
              id: CartItem.idFor(me.uid, variantId),
              uid: me.uid,
              productId: p.id,
              variantId: variantId,
              sellerId: p.ownerId,
              name: p.name,
              variantLabel: v?.label ?? '',
              price: _price,
              qty: _qty,
              maxQty: _stock,
              imageUrl: p.images.isEmpty ? '' : p.images.first,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('เพิ่มลงรถเข็นแล้ว'),
            action: SnackBarAction(
              label: 'ดูรถเข็น',
              onPressed: () => context.push('/cart'),
            ),
          ),
        );
    } catch (e) {
      _snack(errorMessage(e));
    }
  }

  Widget _arrow(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black38,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _imageSection() {
    final box = BorderRadius.circular(16);
    return ClipRRect(
      borderRadius: box,
      child: AspectRatio(
        aspectRatio: 1.3,
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
                  if (p.images.length > 1) ...[
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _arrow(
                              Icons.chevron_left,
                              () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                            ),
                            _arrow(
                              Icons.chevron_right,
                              () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                ],
              ),
      ),
    );
  }

  Widget _qtyStepper() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black26),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _changeQty(-1),
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$_qty',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: () => _changeQty(1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    final soldOut = _stock <= 0;
    final loggedIn = ref.watch(currentUserProvider) != null;

    return Scaffold(
      appBar: AppBar(
        // ปุ่ม back ซ้าย (ถ้าเปิดมาตรงๆ ไม่มีหน้าก่อนหน้า ให้กลับหน้าแรก) / โลโก้ขวา ตาม wireframe
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: AppLogo()),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loggedIn ? _addToCart : _goLogin,
                child: Text(
                  !loggedIn
                      ? 'เข้าสู่ระบบเพื่อเพิ่มเข้ารถเข็น'
                      : soldOut
                          ? 'สินค้าหมด'
                          : 'เพิ่มสินค้าเข้ารถเข็น',
                ),
              ),
            ),
          ),
          const CustomerBottomNav(index: 0),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _imageSection(),
          const SizedBox(height: 16),
          Text(p.name, style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            [if (p.brand.isNotEmpty) p.brand, p.category].join(' • '),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '฿${formatBaht(_price)}',
            style: textTheme.headlineSmall?.copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            soldOut ? 'สินค้าหมด' : 'คงเหลือ $_stock ชิ้น',
            style: TextStyle(
              color: soldOut ? Colors.red[700] : Colors.green[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: p.variants.isEmpty ? null : _pickVariant,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _variant?.label ?? 'ตัวเลือกที่มี',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _qtyStepper(),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.storefront_outlined)),
              title: Text(
                shopDisplayName(ref.watch(shopProvider(p.ownerId)).value?.name),
              ),
              subtitle: const Text('ร้านที่ลงขายสินค้านี้'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/shop/${p.ownerId}'),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _openChat,
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(loggedIn ? 'แชทกับร้านค้า' : 'เข้าสู่ระบบเพื่อแชทกับร้านค้า'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(compareSelectionProvider.notifier).add(p.id);
              context.push('/compare');
            },
            icon: const Icon(Icons.compare_arrows),
            label: const Text('เปรียบเทียบสินค้า'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.description.isEmpty
                        ? 'ผู้ขายยังไม่ได้ใส่คำอธิบายสินค้า'
                        : p.description,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          context.push('/product/${p.id}/specs', extra: p),
                      child: const Text('ดูเพิ่มเติม'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
