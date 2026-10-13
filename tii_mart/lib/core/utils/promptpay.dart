/// สร้างข้อความ QR PromptPay (มาตรฐาน EMVCo / Thai QR Payment)
/// รองรับเบอร์มือถือ 10 หลัก (0812345678) หรือเลขบัตรประชาชน/ภาษี 13 หลัก
class PromptPay {
  PromptPay._();

  /// true ถ้ารูปแบบถูกต้อง (ใช้ตรวจตอนร้านกรอก)
  static bool isValidId(String raw) {
    final id = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return id.length == 10 || id.length == 13;
  }

  /// [amount] หน่วยบาท (จำนวนเต็ม) — ส่งค่า 0 หรือ null จะได้ QR แบบไม่กำหนดยอด
  static String payload(String rawId, {int? amount}) {
    final id = rawId.replaceAll(RegExp(r'[^0-9]'), '');
    final String accountTag;
    final String account;
    if (id.length == 13) {
      accountTag = '02'; // เลขบัตรประชาชน/เลขผู้เสียภาษี
      account = id;
    } else {
      accountTag = '01'; // เบอร์มือถือ: 0812345678 → 0066812345678
      account = '0066${id.substring(1)}';
    }

    final hasAmount = amount != null && amount > 0;
    final merchant = _tlv('00', 'A000000677010111') + _tlv(accountTag, account);

    final body = StringBuffer()
      ..write(_tlv('00', '01'))
      ..write(_tlv('01', hasAmount ? '12' : '11')) // 12 = ใช้ครั้งเดียว (มียอด)
      ..write(_tlv('29', merchant))
      ..write(_tlv('53', '764')) // สกุลเงิน THB
      ..write(hasAmount ? _tlv('54', amount.toStringAsFixed(2)) : '')
      ..write(_tlv('58', 'TH'))
      ..write('6304');
    final text = body.toString();
    return text + _crc16(text);
  }

  static String _tlv(String tag, String value) =>
      '$tag${value.length.toString().padLeft(2, '0')}$value';

  /// CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF)
  static String _crc16(String data) {
    var crc = 0xFFFF;
    for (final unit in data.codeUnits) {
      crc ^= unit << 8;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) : (crc << 1);
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
