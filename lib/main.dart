import 'package:flutter/material.dart';
import 'feature/auth/auth_remote_ds.dart';
import 'feature/auth/token_storage.dart';
import 'feature/auth/dio_client.dart';
import '../../../feature/auth/auth_repository.dart';
import 'front/auth/login/login_page.dart';

void main() {
  final tokenStorage = TokenStorage();

  final dioClient = DioClient.create(
    baseUrl: "http://localhost:8080",
    tokenStorage: tokenStorage,
  );

  final authRemote = AuthRemoteDataSource(dioClient.dio);
  final authRepo = AuthRepository(
    remote: authRemote,
    tokenStorage: tokenStorage,
  );

  runApp(MyApp(authRepository: authRepo));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;

  const MyApp({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(authRepository: authRepository),
    );
  }
}
