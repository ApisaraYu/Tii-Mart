import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/app_user.dart';
import '../models/user_model.dart';

/// ส่วนที่คุยกับ Firebase Auth + Firestore (collection: users)
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const _timeout = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// ติดตาม "สถานะล็อกอิน" + "เอกสารโปรไฟล์" พร้อมกัน
  /// - ออกจากระบบ → ส่ง null
  /// - ล็อกอิน → ส่งข้อมูลโปรไฟล์ (รอจนเอกสารถูกสร้าง จึงไม่เกิดช่วงที่ไม่มี role)
  Stream<UserModel?> watchCurrentUser() {
    final controller = StreamController<UserModel?>();
    StreamSubscription<User?>? authSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? docSub;

    controller.onListen = () {
      authSub = _auth.authStateChanges().listen(
        (firebaseUser) {
          docSub?.cancel();
          docSub = null;

          if (firebaseUser == null) {
            controller.add(null);
            return;
          }

          docSub = _users.doc(firebaseUser.uid).snapshots().listen(
            (snap) {
              if (snap.exists) controller.add(UserModel.fromDoc(snap));
            },
            onError: (Object e) => controller.addError(_toFailure(e)),
          );
        },
        onError: (Object e) => controller.addError(_toFailure(e)),
      );
    };

    controller.onCancel = () async {
      await docSub?.cancel();
      await authSub?.cancel();
    };

    return controller.stream;
  }

  Future<void> signIn(String email, String password) {
    return _guard(() async {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String username,
    required bool wantsShop,
  }) {
    return _guard(() async {
      UserCredential? cred;
      try {
        cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final role = wantsShop ? UserRole.seller : UserRole.customer;
        await _users.doc(cred.user!.uid).set({
          'email': email.trim(),
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'phone': phone.trim(),
          'username': username.trim(),
          'role': role.name,
          'shopId': null,
          'photoUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(_timeout);
      } catch (_) {
        // สร้างบัญชีแล้วแต่บันทึกโปรไฟล์ไม่สำเร็จ → ลบบัญชีทิ้ง ไม่ให้ค้างครึ่งๆ กลางๆ
        try {
          await cred?.user?.delete();
        } catch (_) {}
        rethrow;
      }
    });
  }

  Future<void> signOut() => _guard(() => _auth.signOut());

  Future<void> sendPasswordReset(String email) {
    return _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  Future<void> updateProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String phone,
    required String username,
  }) {
    return _guard(() async {
      await _users.doc(uid).update({
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': phone.trim(),
        'username': username.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);
    });
  }

  // ---------- error handling ----------

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw _toFailure(e);
    }
  }

  Failure _toFailure(Object e) {
    if (e is Failure) return e;
    // FirebaseAuthException เป็นลูกของ FirebaseException ต้องเช็กก่อน
    if (e is FirebaseAuthException) {
      return Failure(_authMessage(e.code), code: e.code);
    }
    if (e is FirebaseException) {
      return Failure(_firestoreMessage(e.code), code: e.code);
    }
    if (e is TimeoutException) {
      return const Failure(
        'ใช้เวลานานเกินไป กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่',
        code: 'timeout',
      );
    }
    return const Failure('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง');
  }

  String _authMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีนี้ถูกระงับการใช้งาน';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้สมัครไปแล้ว';
      case 'weak-password':
        return 'รหัสผ่านง่ายเกินไป ต้องมีอย่างน้อย 6 ตัวอักษร';
      case 'network-request-failed':
        return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้ กรุณาตรวจสอบเครือข่าย';
      case 'too-many-requests':
        return 'ลองหลายครั้งเกินไป กรุณารอสักครู่แล้วลองใหม่';
      case 'operation-not-allowed':
        return 'ยังไม่ได้เปิดการล็อกอินด้วยอีเมลใน Firebase Console';
      default:
        return 'เกิดข้อผิดพลาดในการยืนยันตัวตน ($code)';
    }
  }

  String _firestoreMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'ไม่มีสิทธิ์ทำรายการนี้ (ตรวจสอบ firestore.rules)';
      case 'unavailable':
        return 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต';
      case 'not-found':
        return 'ไม่พบข้อมูลที่ต้องการ';
      default:
        return 'เกิดข้อผิดพลาดกับฐานข้อมูล ($code)';
    }
  }
}
