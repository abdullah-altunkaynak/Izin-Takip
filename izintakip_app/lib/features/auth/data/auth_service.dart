import 'dart:async';
import 'dart:io';

import '../../../core/auth/auth_state.dart';
import '../../../core/network/api_client.dart';

class AuthService {


Future<void> login({required String email, required String password}) async {
  // burada endpoint tarafında oluşturduğumuz health endpointini loginden önce çalıştırıyoruz bunun sebebi
  // web abiyi Azure Cloud'da öğrenci kimliğiyle ücretsiz barındırdığım için kullanılmayınca servis uykuya geçiyor,
  // bu yüzden hızlı bir pingleme tarzı bişey için bu endpointi ekledim.
  try {
    await ApiClient().get('health/db', timeout: const Duration(seconds: 10));
  } catch (_) {
  }
  Future<void> attempt() async {
    final response = await ApiClient().post(
      'api/Auth/login',
      {'username': email, 'password': password},
      timeout: const Duration(seconds: 60),
    );

    final token = (response is Map) ? response['token'] : null;

    if (token == null) {
      throw Exception('Token alınamadı');
    }

    AuthState.setToken(token.toString());
  }
  try {
    await attempt();
  } on Object catch (e) {
    final isRetryable = e is TimeoutException || e is SocketException;
    if (!isRetryable) rethrow;

    await attempt();
  }

}

  void logout() {
    AuthState.clear();
  }
}
