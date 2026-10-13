import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/firebase_providers.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../coupon/domain/entities/coupon.dart';
import '../../data/cart_remote_datasource.dart';
import '../../domain/entities/cart_item.dart';

final cartDataSourceProvider = Provider<CartRemoteDataSource>((ref) {
  return CartRemoteDataSource(ref.watch(firestoreProvider));
});

/// รถเข็นของผู้ใช้ที่ล็อกอินอยู่ (อัพเดตสด)
final cartItemsProvider = StreamProvider<List<CartItem>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream<List<CartItem>>.value(const []);
  return ref.watch(cartDataSourceProvider).watch(uid);
});

/// จำนวนชิ้นรวมในรถเข็น (ใช้โชว์ badge บนเมนู)
final cartCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartItemsProvider).value ?? const <CartItem>[];
  return items.fold<int>(0, (sum, i) => sum + i.qty);
});

/// รายการที่ติ๊กเลือกไว้ (เก็บเป็น id)
/// กติกา: ชำระเงินได้ทีละ 1 ร้าน → ติ๊กสินค้าของร้านอื่น จะเลิกติ๊กของร้านเดิมให้อัตโนมัติ
class CartSelection extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(CartItem item, List<CartItem> all) {
    final next = {...state};
    if (next.remove(item.id)) {
      state = next;
      return;
    }
    // ถ้าที่ติ๊กอยู่เป็นของร้านอื่น ให้ล้างก่อน
    final otherShop = all.any(
      (i) => next.contains(i.id) && i.sellerId != item.sellerId,
    );
    if (otherShop) next.clear();
    next.add(item.id);
    state = next;
  }

  /// ติ๊ก/เลิกติ๊กทั้งร้าน
  void toggleShop(String sellerId, List<CartItem> all) {
    final ids = all.where((i) => i.sellerId == sellerId).map((i) => i.id).toSet();
    final allOn = ids.isNotEmpty && ids.every(state.contains);
    state = allOn ? <String>{} : ids;
  }

  void remove(String id) {
    if (state.contains(id)) state = {...state}..remove(id);
  }

  void clear() => state = <String>{};
}

final cartSelectionProvider =
    NotifierProvider<CartSelection, Set<String>>(CartSelection.new);

/// สินค้าที่ติ๊กเลือกอยู่จริง (ตัด id ที่ไม่อยู่ในรถเข็นแล้วออก)
final selectedCartItemsProvider = Provider<List<CartItem>>((ref) {
  final items = ref.watch(cartItemsProvider).value ?? const <CartItem>[];
  final selected = ref.watch(cartSelectionProvider);
  return items.where((i) => selected.contains(i.id)).toList();
});

/// โค้ดส่วนลดที่เลือกไว้สำหรับการชำระเงินรอบนี้ (null = ไม่ใช้)
class SelectedCoupon extends Notifier<Coupon?> {
  @override
  Coupon? build() => null;

  void set(Coupon? c) => state = c;
}

final selectedCouponProvider =
    NotifierProvider<SelectedCoupon, Coupon?>(SelectedCoupon.new);

/// โค้ดนี้ใช้กับตะกร้านี้ได้ไหม (เป็นของร้านเดียวกัน, ยังใช้ได้, ยอดถึงขั้นต่ำ)
/// คืนข้อความเหตุผลถ้าใช้ไม่ได้ / null ถ้าใช้ได้
String? couponProblem(Coupon c, String? sellerId, int subtotal) {
  if (sellerId == null || c.ownerId != sellerId) return 'โค้ดนี้ไม่ใช่ของร้านที่เลือกสินค้าไว้';
  if (!c.isActive) return 'โค้ดนี้ถูกปิดใช้งาน';
  if (c.isExpired) return 'โค้ดนี้หมดอายุแล้ว';
  if (c.remaining <= 0) return 'โค้ดนี้ถูกใช้ครบแล้ว';
  if (subtotal < c.minSpend) return 'ยอดซื้อยังไม่ถึงขั้นต่ำ ฿${c.minSpend}';
  return null;
}

/// ส่วนลดค่าสินค้า (โค้ด % และ บาท) — โค้ดส่งฟรีไม่ลดค่าสินค้า
int discountFor(Coupon? c, String? sellerId, int subtotal) {
  if (c == null || c.isFreeShipping) return 0;
  if (couponProblem(c, sellerId, subtotal) != null) return 0;
  final raw = c.type == DiscountType.percent ? subtotal * c.value ~/ 100 : c.value;
  return raw.clamp(0, subtotal);
}

/// ส่วนลดค่าส่ง (เฉพาะโค้ดส่งฟรี): value = 0 → ฟรีเต็มจำนวน / มากกว่า 0 → ลดไม่เกิน value บาท
int shippingDiscountFor(Coupon? c, String? sellerId, int subtotal, int shippingFee) {
  if (c == null || !c.isFreeShipping) return 0;
  if (couponProblem(c, sellerId, subtotal) != null) return 0;
  if (c.value <= 0) return shippingFee;
  return shippingFee < c.value ? shippingFee : c.value;
}

/// ยอดรวมสินค้าที่เลือก + ส่วนลดจากโค้ด
class CartTotals {
  const CartTotals({
    required this.subtotal,
    required this.discount,
    required this.coupon,
    required this.sellerId,
  });

  final int subtotal;
  final int discount; // ส่วนลดค่าสินค้า
  final Coupon? coupon;
  final String? sellerId;

  int get afterDiscount => (subtotal - discount).clamp(0, subtotal);

  /// เหตุผลที่โค้ดที่เลือกไว้ใช้ไม่ได้ (null = ไม่ได้เลือกโค้ด หรือใช้ได้)
  String? get couponProblemText =>
      coupon == null ? null : couponProblem(coupon!, sellerId, subtotal);

  bool get couponApplied => coupon != null && couponProblemText == null;

  /// ส่วนลดค่าส่งตามตัวเลือกจัดส่ง (ขึ้นกับค่าส่งที่เลือกในหน้าชำระเงิน)
  int shippingDiscount(int shippingFee) =>
      shippingDiscountFor(coupon, sellerId, subtotal, shippingFee);
}

final cartTotalsProvider = Provider<CartTotals>((ref) {
  final items = ref.watch(selectedCartItemsProvider);
  final coupon = ref.watch(selectedCouponProvider);
  final subtotal = items.fold<int>(0, (s, i) => s + i.lineTotal);
  final sellerId = items.isEmpty ? null : items.first.sellerId;
  return CartTotals(
    subtotal: subtotal,
    discount: discountFor(coupon, sellerId, subtotal),
    coupon: coupon,
    sellerId: sellerId,
  );
});
