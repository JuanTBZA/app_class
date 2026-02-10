import 'package:flutter/material.dart';
import '../../../feature/auth/token_storage.dart';
import '../../../front/auth/login/login_page.dart';
import '../../../front/home/home/home_page.dart';
import '../../../feature/auth/auth_repository.dart';

class SplashPage extends StatefulWidget {
  final TokenStorage tokenStorage;
  final AuthRepository authRepository;

  const SplashPage({
    super.key,
    required this.tokenStorage,
    required this.authRepository,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final accessToken = await widget.tokenStorage.getAccessToken();

    await Future.delayed(const Duration(milliseconds: 600)); // UX

    if (!mounted) return;

    if (accessToken != null && accessToken.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(authRepository: widget.authRepository),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
