import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';

class AuthState {
  final UserModel? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = true,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api = ApiClient();

  AuthNotifier() : super(AuthState()) {
    ApiClient.onUnauthorized = () {
      state = AuthState(isLoading: false, isAuthenticated: false);
    };
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _api.getToken();
      if (token == null || token.isEmpty) {
        state = AuthState(isLoading: false, isAuthenticated: false);
        return;
      }

      final response = await _api.dio.get('/users/me');
      if (response.data['success'] == true && response.data['data'] != null) {
        final user = UserModel.fromJson(response.data['data']);
        state = AuthState(user: user, isAuthenticated: true, isLoading: false);
      } else {
        await _api.clearToken();
        state = AuthState(isLoading: false, isAuthenticated: false);
      }
    } catch (e) {
      await _api.clearToken();
      state = AuthState(isLoading: false, isAuthenticated: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.post('/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });

      if (response.data['accessToken'] != null) {
        final token = response.data['accessToken'] as String;
        await _api.saveToken(token);

        final user = UserModel.fromJson(response.data['user']);
        state = AuthState(user: user, isAuthenticated: true, isLoading: false);
        return true;
      } else {
        final message = response.data['message'] ?? 'Login failed';
        state = state.copyWith(isLoading: false, error: message);
        return false;
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Invalid email or password';
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.post('/auth/register', data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      });

      if (response.data['accessToken'] != null) {
        final token = response.data['accessToken'] as String;
        await _api.saveToken(token);

        final user = UserModel.fromJson(response.data['user']);
        state = AuthState(user: user, isAuthenticated: true, isLoading: false);
        return true;
      } else {
        final message = response.data['message'] ?? 'Registration failed';
        state = state.copyWith(isLoading: false, error: message);
        return false;
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Registration failed';
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('/auth/logout');
    } catch (_) {}
    await _api.clearToken();
    state = AuthState(isLoading: false, isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
