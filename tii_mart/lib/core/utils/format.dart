/// 13000 -> "13,000"
String formatBaht(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
}

/// 7/10/2026 14:05 -> "07/10/2569 14:05" (ปี พ.ศ.)
String formatDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year + 543} ${two(d.hour)}:${two(d.minute)}';
}

/// 7/10/2026 -> "07/10/2569"
String formatDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year + 543}';
}
