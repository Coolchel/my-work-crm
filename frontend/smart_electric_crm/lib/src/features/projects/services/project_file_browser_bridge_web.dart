import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> downloadBytesInBrowser({
  required Uint8List bytes,
  required String fileName,
  String mimeType = 'application/octet-stream',
}) async {
  final objectUrl = _createObjectUrl(bytes, mimeType: mimeType);
  _clickAnchor(
    href: objectUrl,
    download: fileName,
  );
  _scheduleObjectUrlCleanup(objectUrl);
}

Future<void> openBytesInBrowser({
  required Uint8List bytes,
  required String fileName,
  String mimeType = 'application/octet-stream',
}) async {
  final objectUrl = _createObjectUrl(bytes, mimeType: mimeType);
  _clickAnchor(
    href: objectUrl,
    target: '_blank',
    rel: 'noopener noreferrer',
  );
  _scheduleObjectUrlCleanup(objectUrl);
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
  _clickAnchor(
    href: url,
    target: '_blank',
    rel: 'noopener noreferrer',
  );
}

String _createObjectUrl(Uint8List bytes, {required String mimeType}) {
  final blob = web.Blob(
    [bytes.buffer.toJS].toJS,
    web.BlobPropertyBag()..type = mimeType,
  );
  return web.URL.createObjectURL(blob);
}

void _clickAnchor({
  required String href,
  String? download,
  String? target,
  String? rel,
}) {
  final anchor = web.HTMLAnchorElement()
    ..href = href
    ..style.display = 'none';
  if (download != null) {
    anchor.download = download;
  }
  if (target != null) {
    anchor.target = target;
  }
  if (rel != null) {
    anchor.rel = rel;
  }

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}

void _scheduleObjectUrlCleanup(String objectUrl) {
  unawaited(
    Future<void>.delayed(const Duration(minutes: 1), () {
      web.URL.revokeObjectURL(objectUrl);
    }),
  );
}
