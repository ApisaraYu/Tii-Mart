import 'package:flutter_test/flutter_test.dart';
import 'package:tii_mart/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('อีเมลถูกต้อง ผ่าน', () {
      expect(Validators.email('user@example.com'), isNull);
    });
    test('ไม่มี @ ไม่ผ่าน', () {
      expect(Validators.email('userexample.com'), 'รูปแบบอีเมลไม่ถูกต้อง');
    });
    test('ค่าว่าง ไม่ผ่าน', () {
      expect(Validators.email('   '), isNotNull);
    });
  });

  group('Validators.newPassword (รหัสผ่านตอนสมัคร)', () {
    test('สั้นกว่า 8 ตัว ไม่ผ่าน', () {
      expect(Validators.newPassword('Ab1'), 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
    });
    test('ไม่มีตัวอักษรอังกฤษ ไม่ผ่าน', () {
      expect(
        Validators.newPassword('12345678'),
        'ต้องมีตัวอักษรภาษาอังกฤษอย่างน้อย 1 ตัว',
      );
    });
    test('ไม่มีตัวเลข ไม่ผ่าน', () {
      expect(Validators.newPassword('abcdefgh'), 'ต้องมีตัวเลขอย่างน้อย 1 ตัว');
    });
    test('รหัสที่เดาง่าย ไม่ผ่าน (ไม่สนตัวพิมพ์เล็กใหญ่)', () {
      expect(Validators.newPassword('Abcd1234'), isNotNull);
    });
    test('ตัวพิมพ์เล็กล้วน + เลข ผ่าน (ไม่บังคับตัวพิมพ์ใหญ่)', () {
      expect(Validators.newPassword('tiimart2026'), isNull);
    });
    test('รหัสที่ถูกต้อง ผ่าน', () {
      expect(Validators.newPassword('TiiMart2026'), isNull);
    });
  });

  group('Validators.password (ตอนล็อกอิน)', () {
    test('ว่าง ไม่ผ่าน', () {
      expect(Validators.password(''), 'กรุณากรอกรหัสผ่าน');
    });
    test('บัญชีเก่าที่รหัสสั้นยังล็อกอินได้ (ตรวจแค่ว่ากรอกแล้ว)', () {
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.phone', () {
    test('10 หลัก ขึ้นต้น 0 ผ่าน', () {
      expect(Validators.phone('0812345678'), isNull);
    });
    test('ไม่ขึ้นต้นด้วย 0 ไม่ผ่าน', () {
      expect(Validators.phone('8123456789'), isNotNull);
    });
    test('ไม่ครบ 10 หลัก ไม่ผ่าน', () {
      expect(Validators.phone('08123'), isNotNull);
    });
  });

  group('Validators.username / price / stock', () {
    test('ชื่อผู้ใช้สั้นกว่า 3 ตัว ไม่ผ่าน', () {
      expect(Validators.username('ab'), isNotNull);
      expect(Validators.username('abc'), isNull);
    });
    test('ราคาต้องมากกว่า 0 และเป็นตัวเลข', () {
      expect(Validators.price('0'), 'ราคาต้องมากกว่า 0');
      expect(Validators.price('abc'), 'ราคาต้องมากกว่า 0');
      expect(Validators.price('100'), isNull);
    });
    test('สต๊อกเป็น 0 ได้ แต่ติดลบไม่ได้', () {
      expect(Validators.stock('0'), isNull);
      expect(Validators.stock('-1'), isNotNull);
    });
  });
}
