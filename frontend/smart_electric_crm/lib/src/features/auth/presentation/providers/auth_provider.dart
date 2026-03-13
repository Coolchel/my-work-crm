import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
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

enum PostAuthDestination {
  restoreRequestedLocation,
  defaultLanding,
}

final postAuthDestinationProvider = StateProvider<PostAuthDestination>(
  (ref) => PostAuthDestination.restoreRequestedLocation,
);

@riverpod
class Auth extends _$Auth {
  @override
  AuthStatus build() {
    return AuthStatus.initial;
  }

  Future<void> checkAuth() async {
    try {
      ref.read(postAuthDestinationProvider.notifier).state =
          PostAuthDestination.restoreRequestedLocation;
      state = AuthStatus.loading;

      final repo = await ref
          .read(authRepositoryProvider.future)
          .timeout(const Duration(seconds: 15));

      final accessToken = repo.getAccessToken();
      if (accessToken == null) {
        state = AuthStatus.unauthenticated;
        return;
      }

      try {
        await repo.getUser().timeout(const Duration(seconds: 15));
        state = AuthStatus.authenticated;
        return;
      } catch (_) {
        final refreshed =
            await repo.refreshToken().timeout(const Duration(seconds: 15));
        if (!refreshed) {
          await repo.logout();
          state = AuthStatus.unauthenticated;
          return;
        }
      }

      try {
        await repo.getUser().timeout(const Duration(seconds: 15));
        state = AuthStatus.authenticated;
      } catch (_) {
        await repo.logout();
        state = AuthStatus.unauthenticated;
      }
    } catch (error, stackTrace) {
      debugPrint('Auth.checkAuth failed: $error\n$stackTrace');
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> login(String username, String password) async {
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.login(username, password);
      ref.read(postAuthDestinationProvider.notifier).state =
          PostAuthDestination.defaultLanding;
      state = AuthStatus.authenticated;
    } catch (e, st) {
      ref.read(postAuthDestinationProvider.notifier).state =
          PostAuthDestination.restoreRequestedLocation;
      state = AuthStatus.error;
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> logout() async {
    final repo = await ref.read(authRepositoryProvider.future);
    await repo.logout();
    ref.read(postAuthDestinationProvider.notifier).state =
        PostAuthDestination.restoreRequestedLocation;
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
