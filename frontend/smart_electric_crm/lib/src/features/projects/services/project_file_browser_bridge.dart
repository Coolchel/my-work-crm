import 'dart:typed_data';

import 'project_file_browser_bridge_stub.dart'
    if (dart.library.js_interop) 'project_file_browser_bridge_web.dart'
    as browser_bridge;

Future<void> downloadBytesInBrowser({
  required Uint8List bytes,
  required String fileName,
}) {
  return browser_bridge.downloadBytesInBrowser(
    bytes: bytes,
    fileName: fileName,
  );
}

Future<void> copyTextInBrowser(String text) {
  return browser_bridge.copyTextInBrowser(text);
}

void openUrlInBrowser(String url) {
  browser_bridge.openUrlInBrowser(url);
}
