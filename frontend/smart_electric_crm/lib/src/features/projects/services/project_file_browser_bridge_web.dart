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

Future<void> copyTextInBrowser(String text) async {
  try {
    await web.window.navigator.clipboard.writeText(text).toDart;
    return;
  } catch (_) {
    // Fall through to legacy copy below.
  }

  final textArea = web.HTMLTextAreaElement()
    ..value = text
    ..style.position = 'fixed'
    ..style.left = '-9999px'
    ..style.top = '0'
    ..setAttribute('readonly', 'readonly');
  web.document.body?.append(textArea);
  textArea.focus();
  textArea.select();

  final copied = web.document.execCommand('copy');
  textArea.remove();

  if (!copied) {
    throw Exception('Browser clipboard copy failed.');
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
