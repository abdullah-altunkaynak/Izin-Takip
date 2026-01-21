import 'package:flutter/material.dart';
import '../../../core/auth/auth_state.dart';
import '../../shell/app_shell.dart';
import 'login_page.dart';

// kullanıcının giriş yapıp yapmadığının ayrımını yapacağımız kabuk yapı
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthState.isLoggedIn
        ? const AppShell()
        : const LoginPage();
  }
}
