import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/di/service_providers.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/promptpay.dart';
import '../../../chat/domain/entities/chat.dart';
import '../../../chat/presentation/pages/media_viewer_page.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../orders/presentation/state/order_providers.dart';
import '../../../shop/presentation/state/shop_providers.dart';

/// ชำระเงิน (ตาม wireframe: payment page) — QR พร้อมเพย์ของร้าน + ยอดเงิน + แนบสลิป (ไม่บังคับ)
class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _uploading = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _attachSlip() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      setState(() => _uploading = true);
      final bytes = await file.readAsBytes();
      final url = await ref
          .read(imageUploadServiceProvider)
          .upload(bytes, folder: 'slips/${widget.orderId}');
      await ref.read(checkoutDataSourceProvider).attachSlip(widget.orderId, url);
      _snack('แนบสลิปแล้ว');
    } catch (e) {
      _snack(errorMessage(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _chatWithShop(String sellerId) {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final id = ChatThread.idFor(me.uid, sellerId);
    context.push(
      '/chat/$id',
      extra: ChatThread(id: id, customerId: me.uid, sellerId: sellerId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderByIdProvider(widget.orderId));
    final payment = ref.watch(paymentProvider(widget.orderId));
    final textTheme = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('ชำระเงิน'),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('ชำระภายหลัง'),
          ),
        ],
      ),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(errorMessage(e))),
        data: (o) {
          if (o == null) return const Center(child: Text('ไม่พบออเดอร์'));
          final shop = ref.watch(shopProvider(o.sellerId)).value;
          final ppId = shop?.promptPayId ?? '';
          final canQr = PromptPay.isValidId(ppId);
          final slip = payment.value?.slipUrl;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    if (shop != null && shop.name.isNotEmpty)
                      Text('โอนให้ ${shop.name}', style: textTheme.titleSmall),
                    const SizedBox(height: 12),
                    if (canQr)
                      QrImageView(
                        data: PromptPay.payload(ppId, amount: o.total),
                        size: 240,
                        backgroundColor: Colors.white,
                      )
                    else
                      Container(
                        height: 200,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(16),
                        color: const Color(0xFFEFEFEF),
                        child: const Text(
                          'ร้านนี้ยังไม่ได้ตั้งค่าช่องทางรับเงินพร้อมเพย์\nกรุณาติดต่อร้านค้าผ่านแชท',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text('จำนวนเงิน', style: textTheme.bodySmall),
                    Text(
                      '฿${formatBaht(o.total)}',
                      style: textTheme.headlineMedium?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'สแกนด้วยแอปธนาคาร ยอดเงินถูกกรอกให้อัตโนมัติ',
                      style: textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _attachSlip,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long_outlined),
                label: Text(slip == null ? 'แนบสลิปการโอน (ไม่บังคับ)' : 'เปลี่ยนสลิปการโอน'),
              ),
                            if (slip != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ImageViewerPage(url: slip),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 360),
                        child: Image.network(
                          slip,
                          fit: BoxFit.contain, // แสดงทั้งใบ ไม่ครอป
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              if (slip != null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'แตะที่สลิปเพื่อดูเต็มจอ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              TextButton.icon(
                onPressed: () => _chatWithShop(o.sellerId),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('แชทกับร้านค้า'),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: order.value == null
                  ? null
                  : () => context.go('/payment/${widget.orderId}/done'),
              child: const Text('ยืนยัน (โอนเงินแล้ว)'),
            ),
          ),
        ),
      ),
    );
  }
}

/// หลังแจ้งชำระเงิน (ตาม wireframe: confirm payment)
class PaymentDonePage extends ConsumerWidget {
  const PaymentDonePage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payment = ref.watch(paymentProvider(orderId)).value;
    final paid = payment?.isPaid ?? false;
    final primary = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('ชำระเงิน')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 96, color: primary),
              const SizedBox(height: 16),
              Text(
                paid ? 'ร้านค้ายืนยันการชำระเงินแล้ว' : 'แจ้งชำระเงินเรียบร้อย',
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                paid
                    ? 'กรุณารอทางร้านค้าจัดส่งสินค้า'
                    : 'กรุณารอทางร้านค้าตรวจสอบยอดและส่งสินค้า',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('ยืนยัน'),
            ),
          ),
        ),
      ),
    );
  }
}
