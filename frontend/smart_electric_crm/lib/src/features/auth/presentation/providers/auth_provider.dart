import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/api/api_exception.dart';
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

    final accessToken = repo.getAccessToken();
    if (accessToken == null) {
      state = AuthStatus.unauthenticated;
      return;
    }

    try {
      await repo.getUser();
      state = AuthStatus.authenticated;
      return;
    } catch (_) {
      final refreshed = await repo.refreshToken();
      if (!refreshed) {
        await repo.logout();
        state = AuthStatus.unauthenticated;
        return;
      }
    }

    try {
      await repo.getUser();
      state = AuthStatus.authenticated;
    } catch (_) {
      await repo.logout();
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> login(String username, String password) async {
    state = AuthStatus.loading;
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.login(username, password);
      state = AuthStatus.authenticated;
    } catch (e, st) {
      state = AuthStatus.error;
      Error.throwWithStackTrace(e, st);
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
    throw const ApiException(
      message: 'Не авторизован',
      statusCode: 401,
      raw: 'unauthenticated',
    );
  }

  final repo = await ref.read(authRepositoryProvider.future);
  try {
    return await repo.getUser();
  } catch (e, st) {
    if (e is ApiException && e.statusCode == 401) {
      await ref.read(authProvider.notifier).checkAuth();
      throw ApiException(
        message: 'Ошибка авторизации. Попробуйте перезайти.',
        statusCode: 401,
        raw: e,
      );
    }
    Error.throwWithStackTrace(e, st);
  }
});
