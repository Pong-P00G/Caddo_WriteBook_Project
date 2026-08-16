import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;
  final _storage = const FlutterSecureStorage();
  static VoidCallback? onUnauthorized;

  factory ApiClient() => _instance;

  static String get serverHost {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {}
    return 'http://localhost:3000';
  }

  static String get _baseUrl => '$serverHost/api/v1';

  static String resolveUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('data:')) return url;
    if (url.contains('localhost:3000')) {
      return url.replaceAll('http://localhost:3000', serverHost);
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/')) {
      return '$serverHost$url';
    }
    return '$serverHost/$url';
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth Token Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await clearToken();
            onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) return token;
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt_token');
    } catch (_) {
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: 'jwt_token', value: token);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
    } catch (_) {}
  }

  Future<void> clearToken() async {
    try {
      await _storage.delete(key: 'jwt_token');
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
    } catch (_) {}
  }
}
