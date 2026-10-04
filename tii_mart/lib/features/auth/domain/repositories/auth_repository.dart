import '../entities/app_user.dart';

/// interface ของระบบสมาชิก (ตัวทำงานจริงอยู่ที่ data/repositories)
/// ถ้าผิดพลาดจะ throw Failure ที่มีข้อความภาษาไทยพร้อมแสดง
abstract class AuthRepository {
  /// null = ยังไม่ล็อกอิน, มีค่า = ล็อกอินแล้วพร้อมข้อมูลโปรไฟล์ (อัพเดตสดเมื่อแก้ไข)
  Stream<AppUser?> watchCurrentUser();

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String username,
    required bool wantsShop,
  });

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  Future<void> updateProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String phone,
    required String username,
  });
}
