import 'dart:convert';

class AuthClaims {
  final String? role;
  final bool isManager;

  AuthClaims({
    required this.role,
    required this.isManager,
  });

  // backend tarafında endpointleri role göre ayarladık zaten ama ui tarafında gösterilecek gösterilmeyecek ekranları ayarlamak için JWT token içindeki headerları kullanacağız
  static AuthClaims fromJwt(String jwt) {
    // örnek token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
    // eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1laWRlbnRpZmllciI6IjIiLCJlbXBsb3llZUlkIjoiMiIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvcm9sZSI6IkVtcGxveWVlIiwiaXNNYW5hZ2VyIjoiZmFsc2UiLCJleHAiOjE3Njg3NTg0MjEsImlzcyI6Ikl6aW5UYWtpcEFwaSIsImF1ZCI6Ikl6aW5UYWtpcE1vYmlsZSJ9.
    // CV2ri3BBZIXUW7OU3Vgyf5b-lZbz8RVTRC88-7_IkBE
    final parts = jwt.split('.');
    if (parts.length != 3) {
      return AuthClaims(role: null, isManager: false);
    }

    final payload = _decodeBase64Url(parts[1]);
    final map = jsonDecode(payload) as Map<String, dynamic>;


    final role = map[
    'http://schemas.microsoft.com/ws/2008/06/identity/claims/role'
    ]?.toString();


    final isManagerStr = map['isManager']?.toString().toLowerCase();
    final isManager = isManagerStr == 'true';

    return AuthClaims(
      role: role,
      isManager: isManager,
    );
  }

  static String _decodeBase64Url(String input) {
    // örnek gelen input: eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1laWRlbnRpZmllciI6IjIiLCJlbXBsb3llZUlkIjoiMiIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvcm9sZSI6IkVtcGxveWVlIiwiaXNNYW5hZ2VyIjoiZmFsc2UiLCJleHAiOjE3Njg3NTg0MjEsImlzcyI6Ikl6aW5UYWtpcEFwaSIsImF1ZCI6Ikl6aW5UYWtpcE1vYmlsZSJ9.
    var normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (normalized.length % 4) {
      case 0:
        break;
      case 2:
        normalized += '==';
        break;
      case 3:
        normalized += '=';
        break;
      default:
        return '{}';
    }
    return utf8.decode(base64Decode(normalized));
  }
}
