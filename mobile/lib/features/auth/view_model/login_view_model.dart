import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_service.dart';

class LoginState {
  const LoginState({this.loading = false, this.errorMessage});
  final bool loading;
  final String? errorMessage;

  LoginState copyWith({
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginState(
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LoginViewModel extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  AuthService get _service => ref.read(authServiceProvider);

  Future<bool> login(String login, String senha) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _service.login(login.trim(), senha);
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      final msg = (e is DioException &&
              (e.type == DioExceptionType.connectionError ||
                  e.type == DioExceptionType.connectionTimeout))
          ? 'Não foi possível conectar ao servidor. Verifique sua conexão.'
          : 'Login ou senha inválidos';
      state = state.copyWith(loading: false, errorMessage: msg);
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
  }
}

final loginViewModelProvider = NotifierProvider<LoginViewModel, LoginState>(
  LoginViewModel.new,
);
