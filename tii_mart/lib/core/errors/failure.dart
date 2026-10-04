/// ข้อผิดพลาดที่แปลงเป็นข้อความภาษาไทยพร้อมแสดงให้ผู้ใช้อ่านแล้ว
class Failure implements Exception {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// แปลง error อะไรก็ได้เป็นข้อความสำหรับแสดงบนหน้าจอ
String errorMessage(Object? error) {
  if (error is Failure) return error.message;
  return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
}
