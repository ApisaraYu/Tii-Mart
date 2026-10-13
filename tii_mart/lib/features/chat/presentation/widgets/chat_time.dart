/// เวลาแบบสั้น: วันนี้ = 14:05, วันอื่น = 3/10
String chatTimeLabel(DateTime? t) {
  if (t == null) return '';
  final now = DateTime.now();
  final local = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  final sameDay =
      local.year == now.year && local.month == now.month && local.day == now.day;
  return sameDay
      ? '${two(local.hour)}:${two(local.minute)}'
      : '${local.day}/${local.month}';
}
