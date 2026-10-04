import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

// usecase เล็กๆ แต่ละตัวทำหน้าที่เดียว (ภายหลังจะแยกเป็นไฟล์ละตัวก็ได้)

class WatchCurrentUser {
  const WatchCurrentUser(this._repo);
  final AuthRepository _repo;

  Stream<AppUser?> call() => _repo.watchCurrentUser();
}

class SignIn {
  const SignIn(this._repo);
  final AuthRepository _repo;

  Future<void> call({required String email, required String password}) {
    return _repo.signIn(email: email, password: password);
  }
}

class SignUp {
  const SignUp(this._repo);
  final AuthRepository _repo;

  Future<void> call({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String username,
    required bool wantsShop,
  }) {
    return _repo.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      username: username,
      wantsShop: wantsShop,
    );
  }
}

class SignOut {
  const SignOut(this._repo);
  final AuthRepository _repo;

  Future<void> call() => _repo.signOut();
}

class SendPasswordReset {
  const SendPasswordReset(this._repo);
  final AuthRepository _repo;

  Future<void> call(String email) => _repo.sendPasswordReset(email);
}

class UpdateProfile {
  const UpdateProfile(this._repo);
  final AuthRepository _repo;

  Future<void> call({
    required String uid,
    required String firstName,
    required String lastName,
    required String phone,
    required String username,
  }) {
    return _repo.updateProfile(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      username: username,
    );
  }
}
