import 'package:flutter/material.dart';
import '../../../feature/auth/auth_repository.dart';

class LoginController extends ChangeNotifier {
  final AuthRepository repo;

  bool loading = false;
  String? error;

  LoginController(this.repo);

  Future<bool> doLogin(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await repo.login(email: email, password: password);
      return true;
    } catch (_) {
      error = "Email o contraseña incorrectos";
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
