import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import 'failure.dart';

/// แปลง error ใดๆ เป็น Failure (ข้อความไทย) — ใช้ร่วมกันทุกฟีเจอร์
Failure toFailure(Object e) {
  if (e is Failure) return e;
  if (e is FirebaseException) {
    return Failure(_firebaseMessage(e.code), code: e.code);
  }
  if (e is TimeoutException) {
    return const Failure(
      'ใช้เวลานานเกินไป กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่',
      code: 'timeout',
    );
  }
  return const Failure('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง');
}

/// ครอบการทำงาน: ถ้าผิดพลาดให้ throw เป็น Failure เสมอ
Future<T> guardFirebase<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (e) {
    throw toFailure(e);
  }
}

String _firebaseMessage(String code) {
  switch (code) {
    case 'permission-denied':
    case 'unauthorized':
    case 'unauthenticated':
      return 'ไม่มีสิทธิ์ทำรายการนี้ (ตรวจสอบ firestore.rules / การล็อกอิน)';
    case 'unavailable':
    case 'retry-limit-exceeded':
      return 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต';
    case 'not-found':
    case 'object-not-found':
      return 'ไม่พบข้อมูลที่ต้องการ';
    case 'quota-exceeded':
    case 'resource-exhausted':
      return 'โควต้าของ Firebase เต็มแล้ว';
    case 'canceled':
      return 'ยกเลิกการทำรายการ';
    default:
      return 'เกิดข้อผิดพลาดกับ Firebase ($code)';
  }
}
