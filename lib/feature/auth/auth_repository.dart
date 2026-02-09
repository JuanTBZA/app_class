import '../auth/auth_remote_ds.dart';
import '../../../../feature/auth/token_storage.dart';

class AuthRepository {
  final AuthRemoteDataSource remote;
  final TokenStorage tokenStorage;

  AuthRepository({required this.remote, required this.tokenStorage});

  Future<void> login({required String email, required String password}) async {
    final tokens = await remote.login(email: email, password: password);
    await tokenStorage.saveTokens(
      access: tokens.accessToken,
      refresh: tokens.refreshToken,
    );
  }

  Future<void> logout() => tokenStorage.clear();
}
