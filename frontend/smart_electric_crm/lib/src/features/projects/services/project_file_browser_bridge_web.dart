import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> downloadBytesInBrowser({
  required Uint8List bytes,
  required String fileName,
}) async {
  final blob = web.Blob(
    [bytes.buffer.toJS].toJS,
    web.BlobPropertyBag()..type = 'application/octet-stream',
  );
  final objectUrl = web.URL.createObjectURL(blob);

  try {
    final anchor = web.HTMLAnchorElement()
      ..href = objectUrl
      ..download = fileName
      ..style.display = 'none';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  } finally {
    web.URL.revokeObjectURL(objectUrl);
  }
}

void openUrlInBrowser(String url) {
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..target = '_blank'
    ..rel = 'noopener noreferrer'
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
