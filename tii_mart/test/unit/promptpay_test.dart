import 'package:flutter_test/flutter_test.dart';
import 'package:tii_mart/core/utils/promptpay.dart';

/// CRC-16/CCITT-FALSE เขียนซ้ำในเทสต์เพื่อตรวจ payload แบบอิสระ
String _crc(String data) {
  var crc = 0xFFFF;
  for (final u in data.codeUnits) {
    crc ^= u << 8;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) : (crc << 1);
      crc &= 0xFFFF;
    }
  }
  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}

void main() {
  group('PromptPay.isValidId', () {
    test('เบอร์มือถือ 10 หลัก และเลขบัตร 13 หลัก ผ่าน', () {
      expect(PromptPay.isValidId('081-234-5678'), isTrue);
      expect(PromptPay.isValidId('1234567890123'), isTrue);
    });
    test('ความยาวอื่น ไม่ผ่าน', () {
      expect(PromptPay.isValidId('08123'), isFalse);
      expect(PromptPay.isValidId(''), isFalse);
    });
  });

  group('PromptPay.payload', () {
    test('เบอร์มือถือ + ยอด 100 บาท ตรงกับค่าอ้างอิง', () {
      expect(
        PromptPay.payload('0812345678', amount: 100),
        '00020101021229370016A0000006770101110113006681234567853037645406100.005802TH6304F142',
      );
    });
    test('ไม่กำหนดยอด ใช้รหัสแบบใช้ซ้ำได้ (11) และไม่มีแท็ก 54', () {
      final p = PromptPay.payload('0812345678');
      expect(p, contains('010211'));
      expect(p, isNot(contains('5406')));
      expect(
        p,
        '00020101021129370016A0000006770101110113006681234567853037645802TH6304823E',
      );
    });
    test('เลขบัตร 13 หลักใช้แท็ก 02 และยอดมีทศนิยม 2 ตำแหน่ง', () {
      final p = PromptPay.payload('1234567890123', amount: 1);
      expect(p, contains('02131234567890123'));
      expect(p, contains('54041.00'));
      expect(
        p,
        '00020101021229370016A00000067701011102131234567890123530376454041.005802TH6304E9B7',
      );
    });
    test('ตัวเลข CRC 4 ตัวท้ายตรงกับการคำนวณใหม่เสมอ', () {
      final p = PromptPay.payload('0899999999', amount: 459);
      final body = p.substring(0, p.length - 4);
      expect(p.substring(p.length - 4), _crc(body));
    });
  });
}
