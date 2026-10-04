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

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    if (value.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
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
}
