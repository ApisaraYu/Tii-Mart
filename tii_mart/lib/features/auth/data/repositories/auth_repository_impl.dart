import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<AppUser?> watchCurrentUser() => _remote.watchCurrentUser();

  @override
  Future<void> signIn({required String email, required String password}) {
    return _remote.signIn(email, password);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String username,
    required bool wantsShop,
  }) {
    return _remote.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      username: username,
      wantsShop: wantsShop,
    );
  }

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _remote.sendPasswordReset(email);

  @override
  Future<void> updateProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String phone,
    required String username,
  }) {
    return _remote.updateProfile(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      username: username,
    );
  }
}
