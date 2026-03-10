import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/features/projects/services/project_file_save_service.dart';

void main() {
  test('saves file to selected desktop path', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'project-file-save-service-',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final targetPath = '${tempDir.path}${Platform.pathSeparator}report.txt';
    var downloadCount = 0;

    final service = ProjectFileSaveService(
      picker: _FakePicker(
        requiresBytesBeforePicking: false,
        selection: ProjectFileSaveSelection(
          path: targetPath,
          isPersistedByPlatform: false,
        ),
      ),
      downloadBytes: (_) async {
        downloadCount += 1;
        return Uint8List.fromList([1, 2, 3, 4]);
      },
    );

    final result = await service.saveRemoteFile(
      url: 'https://example.com/files/report.txt',
      displayName: ' report.txt ',
    );

    expect(result.isSaved, isTrue);
    expect(result.path, targetPath);
    expect(result.message, contains(targetPath));
    expect(downloadCount, 1);
    expect(await File(targetPath).readAsBytes(), [1, 2, 3, 4]);
  });

  test('returns cancelled result without downloading on desktop cancel',
      () async {
    var downloadCount = 0;

    final service = ProjectFileSaveService(
      picker: _FakePicker(
        requiresBytesBeforePicking: false,
        selection: null,
      ),
      downloadBytes: (_) async {
        downloadCount += 1;
        return Uint8List.fromList([9]);
      },
    );

    final result = await service.saveRemoteFile(
      url: 'https://example.com/files/report.txt',
      displayName: 'report.txt',
    );

    expect(result.isCancelled, isTrue);
    expect(result.message, 'Сохранение отменено');
    expect(downloadCount, 0);
  });

  test('returns friendly message for an invalid output path', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'project-file-save-service-invalid-',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final missingDirectory =
        '${tempDir.path}${Platform.pathSeparator}missing-folder';
    final targetPath = '$missingDirectory${Platform.pathSeparator}report.txt';

    final service = ProjectFileSaveService(
      picker: _FakePicker(
        requiresBytesBeforePicking: false,
        selection: ProjectFileSaveSelection(
          path: targetPath,
          isPersistedByPlatform: false,
        ),
      ),
      downloadBytes: (_) async => Uint8List.fromList([1, 2, 3]),
    );

    final result = await service.saveRemoteFile(
      url: 'https://example.com/files/report.txt',
      displayName: 'report.txt',
    );

    expect(result.isFailed, isTrue);
    expect(result.message, 'Выбранный путь недоступен.');
    expect(await File(targetPath).exists(), isFalse);
  });

  test('returns friendly message for access denied write errors', () async {
    const targetPath = 'C:\\blocked\\report.txt';

    final service = ProjectFileSaveService(
      picker: _FakePicker(
        requiresBytesBeforePicking: false,
        selection: const ProjectFileSaveSelection(
          path: targetPath,
          isPersistedByPlatform: false,
        ),
      ),
      writer: const _ThrowingWriter(
        FileSystemException(
          'Cannot open file',
          targetPath,
          OSError('Access is denied', 5),
        ),
      ),
      downloadBytes: (_) async => Uint8List.fromList([7, 8, 9]),
    );

    final result = await service.saveRemoteFile(
      url: 'https://example.com/files/report.txt',
      displayName: 'report.txt',
    );

    expect(result.isFailed, isTrue);
    expect(
      result.message,
      'Не удалось сохранить файл: нет доступа к выбранной папке.',
    );
  });

  test('loads bytes before opening picker when platform requires it', () async {
    Uint8List? receivedBytes;
    var downloadCount = 0;

    final service = ProjectFileSaveService(
      picker: _RecordingPicker(
        requiresBytesBeforePicking: true,
        onPick: ({required suggestedFileName, required bytes}) async {
          receivedBytes = bytes;
          return const ProjectFileSaveSelection(
            path: '/saved/report.txt',
            isPersistedByPlatform: true,
          );
        },
      ),
      downloadBytes: (_) async {
        downloadCount += 1;
        return Uint8List.fromList([4, 5, 6]);
      },
    );

    final result = await service.saveRemoteFile(
      url: 'https://example.com/files/report.txt',
      displayName: 'report.txt',
    );

    expect(result.isSaved, isTrue);
    expect(downloadCount, 1);
    expect(receivedBytes, [4, 5, 6]);
  });

  test('uses browser download flow when requested', () async {
    Uint8List? savedBytes;
    String? savedFileName;
    var downloadCount = 0;

    final service = ProjectFileSaveService(
      useBrowserDownload: true,
      browserSave: ({required bytes, required fileName}) async {
        savedBytes = bytes;
        savedFileName = fileName;
      },
      downloadBytes: (_) async {
        downloadCount += 1;
        return Uint8List.fromList([10, 20, 30]);
      },
    );

    final result = await service.saveRemoteFile(
      url: 'https://example.com/files/report.txt',
      displayName: 'report.txt',
    );

    expect(result.isSaved, isTrue);
    expect(result.message, 'Файл передан браузеру для сохранения.');
    expect(downloadCount, 1);
    expect(savedBytes, [10, 20, 30]);
    expect(savedFileName, 'report.txt');
  });
}

class _FakePicker implements ProjectFileSavePicker {
  _FakePicker({
    required this.requiresBytesBeforePicking,
    required this.selection,
  });

  @override
  final bool requiresBytesBeforePicking;

  final ProjectFileSaveSelection? selection;

  @override
  Future<ProjectFileSaveSelection?> pickDestination({
    required String suggestedFileName,
    Uint8List? bytes,
  }) async {
    return selection;
  }
}

class _RecordingPicker implements ProjectFileSavePicker {
  _RecordingPicker({
    required this.requiresBytesBeforePicking,
    required this.onPick,
  });

  @override
  final bool requiresBytesBeforePicking;

  final Future<ProjectFileSaveSelection?> Function({
    required String suggestedFileName,
    required Uint8List? bytes,
  }) onPick;

  @override
  Future<ProjectFileSaveSelection?> pickDestination({
    required String suggestedFileName,
    Uint8List? bytes,
  }) {
    return onPick(suggestedFileName: suggestedFileName, bytes: bytes);
  }
}

class _ThrowingWriter implements ProjectFileWriter {
  const _ThrowingWriter(this.error);

  final Object error;

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {
    throw error;
  }
}
