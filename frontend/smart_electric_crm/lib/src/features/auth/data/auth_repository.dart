import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  static const bool enableDevAuth = false;
  static const String _tokenKey = 'auth_token';

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> login({
    required String login,
    required String password,
  }) async {
    if (!enableDevAuth) {
      return 'Auth backend not configured';
    }

    if (login.trim().isEmpty || password.isEmpty) {
      return 'Введите логин и пароль';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, 'dev-token');
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
