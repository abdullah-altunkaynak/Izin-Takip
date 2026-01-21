import 'auth_claims.dart';

class AuthState {
  static String? _token;
  static AuthClaims? _claims;

  static String? get token => _token;
  static AuthClaims? get claims => _claims;

  static bool get isLoggedIn => _token != null;
  static bool get isManager => _claims?.isManager == true;

  static void setToken(String token) {
    _token = token;
    _claims = AuthClaims.fromJwt(token);
  }

  static void clear() {
    _token = null;
    _claims = null;
  }
}
