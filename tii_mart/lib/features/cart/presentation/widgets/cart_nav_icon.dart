import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/cart_providers.dart';

/// ไอคอนรถเข็น + จำนวนชิ้นในรถเข็น
class CartNavIcon extends ConsumerWidget {
  const CartNavIcon({super.key, this.selected = false});

  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    return Badge.count(
      count: count,
      isLabelVisible: count > 0,
      child: Icon(selected ? Icons.shopping_cart : Icons.shopping_cart_outlined),
    );
  }
}
