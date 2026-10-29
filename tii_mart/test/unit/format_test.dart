import 'package:flutter_test/flutter_test.dart';
import 'package:tii_mart/core/utils/format.dart';

void main() {
  group('formatBaht', () {
    test('ใส่จุลภาคคั่นหลักพัน', () {
      expect(formatBaht(13000), '13,000');
      expect(formatBaht(1234567), '1,234,567');
    });
    test('เลขน้อยกว่า 1,000 ไม่ใส่จุลภาค', () {
      expect(formatBaht(0), '0');
      expect(formatBaht(999), '999');
    });
  });

  group('วันที่แบบ พ.ศ.', () {
    test('formatDateTime แปลงปีเป็น พ.ศ. และเติมศูนย์หน้า', () {
      expect(formatDateTime(DateTime(2026, 10, 7, 14, 5)), '07/10/2569 14:05');
    });
    test('formatDate แสดงเฉพาะวันที่', () {
      expect(formatDate(DateTime(2026, 1, 2)), '02/01/2569');
    });
  });
}
