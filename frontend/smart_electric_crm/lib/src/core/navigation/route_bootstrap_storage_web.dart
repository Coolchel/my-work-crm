// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

const _pendingRedirectKey = 'smart_electric_crm.pending_redirect';

void setPendingRedirect(String location) {
  final trimmed = location.trim();
  if (trimmed.isEmpty) {
    clearPendingRedirect();
    return;
  }
  html.window.sessionStorage[_pendingRedirectKey] = trimmed;
}

String? peekPendingRedirect() {
  final value = html.window.sessionStorage[_pendingRedirectKey];
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value;
}

void clearPendingRedirect() {
  html.window.sessionStorage.remove(_pendingRedirectKey);
}
