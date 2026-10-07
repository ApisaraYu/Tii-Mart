class Validators {
  static String? required(String? value, [String field = 'ข้อมูลนี้']) {
    if (value == null || value.trim().isEmpty) return 'กรุณากรอก$field';
    return null;
  }

  static String? email(String? value) {
    final empty = required(value, 'อีเมล');
    if (empty != null) return empty;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim());
    return ok ? null : 'รูปแบบอีเมลไม่ถูกต้อง';
  }

  /// ตอนล็อกอิน: ตรวจแค่ว่ากรอกแล้ว (ไม่ใช้กฎความแข็งแรง เพราะบัญชีเก่าอาจตั้งรหัสไว้ก่อนมีกฎนี้)
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    return null;
  }

  /// รหัสผ่านที่ใช้ตอนสมัคร/ตั้งใหม่: 8 ตัวขึ้นไป มีตัวอักษร A-Z และตัวเลข ไม่ใช่รหัสที่เดาง่าย
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    if (value.length < 8) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
    if (!RegExp('[A-Za-z]').hasMatch(value)) {
      return 'ต้องมีตัวอักษรภาษาอังกฤษอย่างน้อย 1 ตัว';
    }
    if (!RegExp('[0-9]').hasMatch(value)) {
      return 'ต้องมีตัวเลขอย่างน้อย 1 ตัว';
    }
    if (RegExp(r'^(.)\1+$').hasMatch(value)) {
      return 'รหัสผ่านต้องไม่ใช่ตัวอักษรเดียวซ้ำกัน';
    }
    const common = {
      'password1', 'password123', 'qwerty123', 'abc12345', 'abcd1234',
      'iloveyou1', 'admin1234', 'welcome1', 'letmein123', 'a1234567',
      'a12345678', 'asdf1234', 'qwer1234', 'q1w2e3r4',
    };
    if (common.contains(value.toLowerCase())) {
      return 'รหัสผ่านนี้เดาง่ายเกินไป กรุณาเปลี่ยน';
    }
    return null;
  }

  static String? phone(String? value) {
    final empty = required(value, 'เบอร์โทรศัพท์');
    if (empty != null) return empty;
    final ok = RegExp(r'^0\d{9}$').hasMatch(value!.trim());
    return ok ? null : 'เบอร์โทรต้องเป็นตัวเลข 10 หลัก ขึ้นต้นด้วย 0';
  }

  static String? username(String? value) {
    final empty = required(value, 'ชื่อผู้ใช้');
    if (empty != null) return empty;
    return value!.trim().length < 3 ? 'ชื่อผู้ใช้ต้องมีอย่างน้อย 3 ตัวอักษร' : null;
  }

  /// ราคา: จำนวนเต็มมากกว่า 0
  static String? price(String? value) {
    final empty = required(value, 'ราคา');
    if (empty != null) return empty;
    final n = int.tryParse(value!.trim());
    return (n == null || n <= 0) ? 'ราคาต้องมากกว่า 0' : null;
  }

  /// สต๊อก: จำนวนเต็ม 0 ขึ้นไป
  static String? stock(String? value) {
    final empty = required(value, 'จำนวนสต๊อก');
    if (empty != null) return empty;
    final n = int.tryParse(value!.trim());
    return (n == null || n < 0) ? 'จำนวนต้องเป็นตัวเลข 0 ขึ้นไป' : null;
  }
}
