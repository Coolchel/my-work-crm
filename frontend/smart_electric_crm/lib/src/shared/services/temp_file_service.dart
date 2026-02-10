import 'dart:io';
import 'package:flutter/foundation.dart';

/// Сервис для отслеживания и очистки временных файлов.
class TempFileService {
  static final TempFileService _instance = TempFileService._internal();

  factory TempFileService() {
    return _instance;
  }

  TempFileService._internal();

  final List<File> _trackedFiles = [];

  /// Добавляет файл в список отслеживаемых для последующего удаления.
  void track(File file) {
    if (!_trackedFiles.contains(file)) {
      _trackedFiles.add(file);
      debugPrint("📄 TempFileService: Tracked ${file.path}");
    }
  }

  /// Удаляет все отслеживаемые файлы.
  /// Должен вызываться при закрытии приложения.
  Future<void> disposeAll() async {
    debugPrint(
        "🧹 TempFileService: Cleaning up ${_trackedFiles.length} files...");

    for (final file in _trackedFiles) {
      try {
        if (await file.exists()) {
          await file.delete();
          debugPrint("✅ Deleted: ${file.path}");
        }
      } catch (e) {
        debugPrint("❌ Failed to delete ${file.path}: $e");
      }
    }
    _trackedFiles.clear();
  }
}
