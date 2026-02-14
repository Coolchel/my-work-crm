import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository)
      : super(const AuthState(isAuthenticated: false, isLoading: true)) {
    initialize();
  }

  Future<void> initialize() async {
    final isAuthenticated = await _repository.isAuthenticated();
    state = state.copyWith(isAuthenticated: isAuthenticated, isLoading: false);
  }

  Future<String?> login({required String login, required String password}) async {
    state = state.copyWith(isLoading: true);
    final error = await _repository.login(login: login, password: password);

    if (error != null) {
      state = state.copyWith(isAuthenticated: false, isLoading: false, error: error);
      return error;
    }

    state = state.copyWith(isAuthenticated: true, isLoading: false, error: null);
    return null;
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    state = state.copyWith(isAuthenticated: false, isLoading: false, error: null);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
