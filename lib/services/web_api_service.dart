import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'inventory_repository.dart';
import 'network_exceptions.dart';

class WebApiService {
  String baseUrl;
  String? authToken;

  WebApiService({
    this.baseUrl = 'http://10.0.2.2:8000/api',
    this.authToken,
  });

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _request(
      'POST',
      '/login',
      body: {'email': email, 'password': password},
    );
    authToken = response['token']?.toString();
    return response;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _request(
      'POST',
      '/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    authToken = response['token']?.toString();
    return response;
  }

  Future<Map<String, dynamic>> syncWithRepository(
    InventoryRepository repository,
  ) async {
    final data = await _request('GET', '/sync');
    repository.applyRemoteSyncData(data);
    return data;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6);
    try {
      final uri = Uri.parse('$baseUrl$path');
      final HttpClientRequest req;
      switch (method) {
        case 'POST':
          req = await client.postUrl(uri);
          break;
        case 'PUT':
          req = await client.putUrl(uri);
          break;
        case 'PATCH':
          req = await client.patchUrl(uri);
          break;
        default:
          req = await client.getUrl(uri);
      }

      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (authToken != null && authToken!.isNotEmpty) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $authToken');
      }
      if (body != null) {
        req.headers.set(
          HttpHeaders.contentTypeHeader,
          'application/json; charset=utf-8',
        );
        req.add(utf8.encode(jsonEncode(body)));
      }

      final res = await req.close().timeout(const Duration(seconds: 8));
      final raw = await res.transform(utf8.decoder).join();
      if (res.statusCode >= 500) {
        throw NetworkException.serverError(res.statusCode);
      }

      final decoded = raw.isNotEmpty
          ? jsonDecode(raw) as Map<String, dynamic>
          : <String, dynamic>{};

      if (res.statusCode >= 400) {
        final msg =
            decoded['message']?.toString() ??
            'Error en la solicitud (${res.statusCode})';
        throw InventoryValidationException(msg);
      }

      return decoded;
    } on TimeoutException {
      throw NetworkException.timeout();
    } on SocketException {
      throw NetworkException.noConnection();
    } finally {
      client.close(force: true);
    }
  }
}
