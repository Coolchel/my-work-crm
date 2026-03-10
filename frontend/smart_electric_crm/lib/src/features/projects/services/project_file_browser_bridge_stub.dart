import 'dart:typed_data';

Future<void> downloadBytesInBrowser({
  required Uint8List bytes,
  required String fileName,
}) {
  throw UnsupportedError('Browser downloads are only supported on web.');
}

Future<void> copyTextInBrowser(String text) {
  throw UnsupportedError('Browser clipboard is only supported on web.');
}

void openUrlInBrowser(String url) {
  throw UnsupportedError('Browser opening is only supported on web.');
}
