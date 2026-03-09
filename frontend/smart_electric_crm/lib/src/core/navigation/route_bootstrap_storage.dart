import 'route_bootstrap_storage_stub.dart'
    if (dart.library.html) 'route_bootstrap_storage_web.dart' as impl;

class RouteBootstrapStorage {
  RouteBootstrapStorage._();

  static void setPendingRedirect(String location) {
    impl.setPendingRedirect(location);
  }

  static String? peekPendingRedirect() {
    return impl.peekPendingRedirect();
  }

  static void clearPendingRedirect() {
    impl.clearPendingRedirect();
  }

  static String? takePendingRedirect() {
    final value = peekPendingRedirect();
    if (value == null || value.isEmpty) {
      clearPendingRedirect();
      return null;
    }
    clearPendingRedirect();
    return value;
  }
}
