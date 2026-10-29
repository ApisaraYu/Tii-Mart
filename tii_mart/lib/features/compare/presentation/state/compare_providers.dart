import 'package:flutter_riverpod/flutter_riverpod.dart';

/// สินค้าที่เลือกไว้เปรียบเทียบ (id ได้สูงสุด 2 ช่อง, ช่องว่าง = '')
class CompareSelection extends Notifier<List<String>> {
  @override
  List<String> build() => const ['', ''];

  /// ใส่สินค้าลงช่องว่างช่องแรก (ถ้ามีอยู่แล้วไม่ทำอะไร / เต็มแล้วแทนช่องที่ 2)
  void add(String id) {
    if (state.contains(id)) return;
    final i = state.indexOf('');
    setAt(i == -1 ? 1 : i, id);
  }

  void setAt(int index, String id) {
    final next = [...state];
    next[index] = id;
    state = next;
  }

  void clear() => state = const ['', ''];
}

final compareSelectionProvider =
    NotifierProvider<CompareSelection, List<String>>(CompareSelection.new);
