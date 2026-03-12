import 'package:flutter/services.dart';

const MethodChannel _projectFileAndroidSaveChannel = MethodChannel(
  'smart_electric_crm/project_file_save',
);

Future<String?> saveFileOnAndroid({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) {
  return _projectFileAndroidSaveChannel.invokeMethod<String>('saveFile', {
    'fileName': fileName,
    'bytes': bytes,
    'mimeType': mimeType,
  });
}
