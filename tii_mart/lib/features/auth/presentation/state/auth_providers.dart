import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/firebase_providers.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

// ---------- dependency injection ----------

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

// ---------- สถานะผู้ใช้ปัจจุบัน ----------

/// null = ยังไม่ล็อกอิน / มีค่า = ล็อกอินแล้ว (อัพเดตสดจาก Firestore)
final authUserProvider = StreamProvider<AppUser?>((ref) {
  return WatchCurrentUser(ref.watch(authRepositoryProvider))();
});

/// ทางลัด: ผู้ใช้ปัจจุบัน (null ถ้ายังไม่ล็อกอินหรือกำลังโหลด)
final currentUserProvider = Provider<AppUser?>((ref) {
  final auth = ref.watch(authUserProvider);
  return auth.hasValue ? auth.value : null;
});

// ---------- ตัวสั่งงาน (สมัคร/ล็อกอิน/ออก/แก้โปรไฟล์) ----------

/// state = AsyncLoading ตอนกำลังทำงาน, AsyncError(Failure) ถ้าผิดพลาด
/// ทุกเมธอดคืนค่า true เมื่อสำเร็จ
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  Future<bool> signIn({required String email, required String password}) {
    return _run(() => SignIn(_repo)(email: email, password: password));
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String username,
    required bool wantsShop,
  }) {
    return _run(
      () => SignUp(_repo)(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        username: username,
        wantsShop: wantsShop,
      ),
    );
  }

  Future<bool> signOut() => _run(() => SignOut(_repo)());

  Future<bool> sendPasswordReset(String email) {
    return _run(() => SendPasswordReset(_repo)(email));
  }

  Future<bool> updateProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String phone,
    required String username,
  }) {
    return _run(
      () => UpdateProfile(_repo)(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        username: username,
      ),
    );
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
