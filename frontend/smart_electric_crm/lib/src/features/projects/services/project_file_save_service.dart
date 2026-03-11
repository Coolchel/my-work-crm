import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'project_file_browser_bridge.dart';

enum ProjectFileSaveStatus { saved, cancelled, failed }

class ProjectFileSaveResult {
  const ProjectFileSaveResult._({
    required this.status,
    required this.message,
    this.path,
  });

  final ProjectFileSaveStatus status;
  final String message;
  final String? path;

  bool get isSaved => status == ProjectFileSaveStatus.saved;
  bool get isCancelled => status == ProjectFileSaveStatus.cancelled;
  bool get isFailed => status == ProjectFileSaveStatus.failed;

  factory ProjectFileSaveResult.saved({required String message, String? path}) {
    return ProjectFileSaveResult._(
      status: ProjectFileSaveStatus.saved,
      message: message,
      path: path,
    );
  }

  factory ProjectFileSaveResult.cancelled({
    String message = 'Сохранение отменено',
  }) {
    return ProjectFileSaveResult._(
      status: ProjectFileSaveStatus.cancelled,
      message: message,
    );
  }

  factory ProjectFileSaveResult.failed(String message) {
    return ProjectFileSaveResult._(
      status: ProjectFileSaveStatus.failed,
      message: message,
    );
  }
}

class ProjectFileSaveSelection {
  const ProjectFileSaveSelection({
    required this.path,
    required this.isPersistedByPlatform,
  });

  final String? path;
  final bool isPersistedByPlatform;
}

abstract class ProjectFileSavePicker {
  bool get requiresBytesBeforePicking;

  Future<ProjectFileSaveSelection?> pickDestination({
    required String suggestedFileName,
    Uint8List? bytes,
  });
}

abstract class ProjectFileWriter {
  Future<void> writeBytes(String path, Uint8List bytes);
}

class FilePickerProjectFileSavePicker implements ProjectFileSavePicker {
  @override
  bool get requiresBytesBeforePicking => Platform.isAndroid || Platform.isIOS;

  @override
  Future<ProjectFileSaveSelection?> pickDestination({
    required String suggestedFileName,
    Uint8List? bytes,
  }) async {
    final extension = p.extension(suggestedFileName).replaceFirst('.', '');
    final allowedExtensions =
        extension.isEmpty ? null : <String>[extension.toLowerCase()];
    final type = allowedExtensions == null ? FileType.any : FileType.custom;

    if (requiresBytesBeforePicking) {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить файл как...',
        fileName: suggestedFileName,
        type: type,
        allowedExtensions: allowedExtensions,
        bytes: bytes,
      );
      if (outputPath == null) {
        return null;
      }
      return ProjectFileSaveSelection(
        path: outputPath,
        isPersistedByPlatform: true,
      );
    }

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить файл как...',
      fileName: suggestedFileName,
      type: type,
      allowedExtensions: allowedExtensions,
    );
    if (outputPath == null) {
      return null;
    }
    return ProjectFileSaveSelection(
      path: outputPath,
      isPersistedByPlatform: false,
    );
  }
}

class LocalProjectFileWriter implements ProjectFileWriter {
  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) {
      throw const _ProjectFileSaveException(
        'Не удалось определить путь сохранения файла.',
      );
    }

    final entityType = await FileSystemEntity.type(normalizedPath);
    if (entityType == FileSystemEntityType.directory) {
      throw const _ProjectFileSaveException(
        'Выбран путь к папке, а не к файлу.',
      );
    }

    final targetFile = File(normalizedPath);
    final parentDirectory = targetFile.parent;
    if (!await parentDirectory.exists()) {
      throw const _ProjectFileSaveException(
        'Выбранный путь недоступен.',
      );
    }

    await targetFile.writeAsBytes(bytes, flush: true);
  }
}

typedef ProjectFileBytesDownloader = Future<Uint8List> Function(Uri uri);
typedef ProjectFileBrowserSaver = Future<void> Function({
  required Uint8List bytes,
  required String fileName,
});

class ProjectFileSaveService {
  ProjectFileSaveService({
    ProjectFileSavePicker? picker,
    ProjectFileWriter? writer,
    ProjectFileBytesDownloader? downloadBytes,
    ProjectFileBrowserSaver? browserSave,
    bool? useBrowserDownload,
  })  : _picker = picker ?? FilePickerProjectFileSavePicker(),
        _writer = writer ?? LocalProjectFileWriter(),
        _downloadBytes = downloadBytes ?? _defaultDownloadBytes,
        _browserSave = browserSave ?? downloadBytesInBrowser,
        _useBrowserDownload = useBrowserDownload ?? kIsWeb;

  final ProjectFileSavePicker _picker;
  final ProjectFileWriter _writer;
  final ProjectFileBytesDownloader _downloadBytes;
  final ProjectFileBrowserSaver _browserSave;
  final bool _useBrowserDownload;

  static String sanitizeFileName(String rawName, {String fallback = 'file'}) {
    final trimmed = rawName.trim();
    final candidate = trimmed.isEmpty ? fallback : trimmed;
    final sanitized = candidate
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'[\u0000-\u001F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final withoutTrailingDots = sanitized.replaceAll(RegExp(r'[. ]+$'), '');
    return withoutTrailingDots.isEmpty ? fallback : withoutTrailingDots;
  }

  Future<ProjectFileSaveResult> saveRemoteFile({
    required String url,
    required String displayName,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.hasAbsolutePath && uri.scheme.isEmpty)) {
      return ProjectFileSaveResult.failed(
        'Не удалось сохранить файл: некорректный адрес файла.',
      );
    }

    final suggestedFileName = sanitizeFileName(displayName, fallback: 'file');
    Uint8List? downloadedBytes;

    Future<Uint8List> ensureBytes() async {
      if (downloadedBytes != null) {
        return downloadedBytes!;
      }
      downloadedBytes = await _downloadBytes(uri);
      return downloadedBytes!;
    }

    try {
      return await _saveBytesInternal(
        suggestedFileName: suggestedFileName,
        bytesLoader: ensureBytes,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'ProjectFileSaveService.saveRemoteFile failed: $error\n$stackTrace',
      );
      return ProjectFileSaveResult.failed(_mapErrorToMessage(error));
    }
  }

  Future<ProjectFileSaveResult> saveBytes({
    required Uint8List bytes,
    required String displayName,
  }) async {
    final suggestedFileName = sanitizeFileName(displayName, fallback: 'file');

    try {
      return await _saveBytesInternal(
        suggestedFileName: suggestedFileName,
        bytesLoader: () async => bytes,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'ProjectFileSaveService.saveBytes failed: $error\n$stackTrace',
      );
      return ProjectFileSaveResult.failed(_mapErrorToMessage(error));
    }
  }

  Future<ProjectFileSaveResult> _saveBytesInternal({
    required String suggestedFileName,
    required Future<Uint8List> Function() bytesLoader,
  }) async {
    if (_useBrowserDownload) {
      await _browserSave(
        bytes: await bytesLoader(),
        fileName: suggestedFileName,
      );
      return ProjectFileSaveResult.saved(
        message: 'Файл передан браузеру для сохранения.',
      );
    }

    final selection = await _picker.pickDestination(
      suggestedFileName: suggestedFileName,
      bytes: _picker.requiresBytesBeforePicking ? await bytesLoader() : null,
    );

    if (selection == null) {
      return ProjectFileSaveResult.cancelled();
    }

    final outputPath = selection.path?.trim();
    if (selection.isPersistedByPlatform) {
      return ProjectFileSaveResult.saved(
        message: outputPath == null || outputPath.isEmpty
            ? 'Файл сохранен'
            : 'Файл сохранен: $outputPath',
        path: outputPath,
      );
    }

    if (outputPath == null || outputPath.isEmpty) {
      return ProjectFileSaveResult.failed(
        'Не удалось определить путь сохранения файла.',
      );
    }

    await _writer.writeBytes(outputPath, await bytesLoader());
    return ProjectFileSaveResult.saved(
      message: 'Файл сохранен: $outputPath',
      path: outputPath,
    );
  }

  static Future<Uint8List> _defaultDownloadBytes(Uri uri) async {
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const _ProjectFileSaveException(
        'Не удалось загрузить файл для сохранения.',
      );
    }
    return response.bodyBytes;
  }

  String _mapErrorToMessage(Object error) {
    if (error is _ProjectFileSaveException) {
      return error.message;
    }

    if (error is FileSystemException) {
      final combinedMessage = [
        error.message,
        error.osError?.message,
      ].whereType<String>().join(' ').toLowerCase();

      if (combinedMessage.contains('access is denied') ||
          combinedMessage.contains('permission denied')) {
        return 'Не удалось сохранить файл: нет доступа к выбранной папке.';
      }

      if (combinedMessage.contains('path not found') ||
          combinedMessage.contains('cannot find the path') ||
          combinedMessage.contains('no such file or directory')) {
        return 'Не удалось сохранить файл: выбранный путь недоступен.';
      }

      return 'Не удалось сохранить файл. Проверьте путь и права доступа.';
    }

    if (error is ArgumentError) {
      return 'Не удалось сохранить файл. Проверьте выбранное место сохранения.';
    }

    return 'Не удалось сохранить файл. Попробуйте еще раз.';
  }
}

class _ProjectFileSaveException implements Exception {
  const _ProjectFileSaveException(this.message);

  final String message;
}
