/// 13000 -> "13,000"
String formatBaht(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
}
