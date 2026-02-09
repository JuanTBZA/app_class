import 'package:dio/dio.dart';
import '../auth/auth_tokens.dart';

class AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSource(this.dio);

  Future<AuthTokens> login({required String email, required String password}) async {
    final res = await dio.post(
      "/auth/login",
      data: {"email": email, "password": password},
    );
    return AuthTokens.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AuthTokens> refreshToken({required String refreshToken}) async {
    final res = await dio.post(
      "/auth/refresh-token",
      options: Options(headers: {
        "Authorization": "Bearer $refreshToken",
      }),
    );
    return AuthTokens.fromJson(res.data as Map<String, dynamic>);
  }
}
