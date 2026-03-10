import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

enum ProjectFileShareStatus { shared, copiedLink, cancelled, failed }

class ProjectFileShareResult {
  const ProjectFileShareResult._({
    required this.status,
    required this.message,
  });

  final ProjectFileShareStatus status;
  final String message;

  bool get isShared => status == ProjectFileShareStatus.shared;
  bool get isCopiedLink => status == ProjectFileShareStatus.copiedLink;
  bool get isCancelled => status == ProjectFileShareStatus.cancelled;
  bool get isFailed => status == ProjectFileShareStatus.failed;

  factory ProjectFileShareResult.shared() {
    return const ProjectFileShareResult._(
      status: ProjectFileShareStatus.shared,
      message: '',
    );
  }

  factory ProjectFileShareResult.copiedLink(String message) {
    return ProjectFileShareResult._(
      status: ProjectFileShareStatus.copiedLink,
      message: message,
    );
  }

  factory ProjectFileShareResult.cancelled() {
    return const ProjectFileShareResult._(
      status: ProjectFileShareStatus.cancelled,
      message: '',
    );
  }

  factory ProjectFileShareResult.failed(String message) {
    return ProjectFileShareResult._(
      status: ProjectFileShareStatus.failed,
      message: message,
    );
  }
}

typedef ProjectFileShareInvoker = Future<ShareResult> Function(
  ShareParams params,
);
typedef ProjectFileLinkCopier = Future<void> Function(String text);

class ProjectFileShareService {
  ProjectFileShareService({
    ProjectFileShareInvoker? share,
    ProjectFileLinkCopier? copyLink,
  })  : _share = share ?? SharePlus.instance.share,
        _copyLink = copyLink ?? _defaultCopyLink;

  final ProjectFileShareInvoker _share;
  final ProjectFileLinkCopier _copyLink;

  Future<ProjectFileShareResult> shareRemoteFile({
    required String url,
    required String displayName,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return ProjectFileShareResult.failed(
        'Не удалось поделиться файлом: некорректная ссылка.',
      );
    }

    try {
      final result = await _share(
        ShareParams(
          uri: uri,
          title: displayName,
          subject: displayName,
          downloadFallbackEnabled: false,
          mailToFallbackEnabled: false,
        ),
      );

      if (result.status == ShareResultStatus.dismissed) {
        return ProjectFileShareResult.cancelled();
      }

      return ProjectFileShareResult.shared();
    } catch (_) {
      try {
        await _copyLink(uri.toString());
        return ProjectFileShareResult.copiedLink(
          'Ссылка на файл скопирована в буфер обмена.',
        );
      } catch (_) {
        return ProjectFileShareResult.failed(
          'Не удалось поделиться файлом. Попробуйте открыть или скачать его вручную.',
        );
      }
    }
  }

  static Future<void> _defaultCopyLink(String text) {
    return Clipboard.setData(ClipboardData(text: text));
  }
}
