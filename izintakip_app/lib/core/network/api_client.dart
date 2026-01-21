import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_state.dart';
import '../constants/api_constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final dynamic body;

  ApiException(this.statusCode, this.body);

  @override
  String toString() {
    if (body == null) return "HTTP $statusCode";
    return "HTTP $statusCode: $body";
  }
}

class ApiClient {
  final _timeout = const Duration(seconds: 25);
  Future<dynamic> get(String path, {Duration? timeout}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final response = await http.get(uri, headers: _headers()).timeout(timeout ?? _timeout);
    return _handle(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {Duration? timeout}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(timeout ?? _timeout);
    return _handle(response);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');

    final response = await http.put(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);

    return _handle(response);
  }


  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    final token = AuthState.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      final trimmed = response.body.trim();
      // JSON değilse (backend tarafında dönen veriyi hep object tanımlayama çalıştık ama string değer de dönebilir veya bunu unutabiliriz)
      if (!(trimmed.startsWith('{') || trimmed.startsWith('['))) {
        return trimmed;
      }
      return jsonDecode(response.body);
    }


    final decoded = jsonDecode(response.body);
    throw ApiException(response.statusCode, decoded);
  }
}
