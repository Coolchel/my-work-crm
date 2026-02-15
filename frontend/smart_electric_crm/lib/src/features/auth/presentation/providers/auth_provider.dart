import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/auth_repository.dart';

part 'auth_provider.g.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

@riverpod
class Auth extends _$Auth {
  @override
  AuthStatus build() {
    return AuthStatus.initial;
  }

  Future<void> checkAuth() async {
    state = AuthStatus.loading;
    final repo = await ref.read(authRepositoryProvider.future);

    // Check if we have an access token
    final accessToken = repo.getAccessToken();
    if (accessToken != null) {
      // Optimistically set authenticated
      state = AuthStatus.authenticated;

      // Optionally verify with /me endpoint or refresh if needed
      try {
        await repo.getUser();
        // still authenticated
      } catch (e) {
        // If /me fails, try refresh
        final success = await repo.refreshToken();
        if (!success) {
          state = AuthStatus.unauthenticated;
          await repo.logout();
        }
      }
    } else {
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> login(String username, String password) async {
    state = AuthStatus.loading;
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.login(username, password);
      // If login successful, we are authenticated
      state = AuthStatus.authenticated;
    } catch (e) {
      state = AuthStatus.error;
      // You might want to expose the error message too, but for now simple status
      rethrow;
    }
  }

  Future<void> logout() async {
    final repo = await ref.read(authRepositoryProvider.future);
    await repo.logout();
    state = AuthStatus.unauthenticated;
  }
}

final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authStatus = ref.watch(authProvider);
  if (authStatus != AuthStatus.authenticated) {
    throw Exception('Не авторизован');
  }

  final repo = await ref.read(authRepositoryProvider.future);
  try {
    return await repo.getUser();
  } catch (e) {
    // If it's a 401, maybe try checkAuth again to trigger a refresh
    if (e is DioException && e.response?.statusCode == 401) {
      await ref.read(authProvider.notifier).checkAuth();
      // After checkAuth, if still authenticated, repo.getUser() should work on retry
      // but FutureProviders don't easily retry like this without recursion.
      // For now, rethrow a cleaner error.
      throw Exception('Ошибка авторизации. Попробуйте перезайти.');
    }
    rethrow;
  }
});
