import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'project_file_browser_bridge.dart';

enum ProjectFileShareStatus {
  shared,
  copiedLink,
  cancelled,
  manualFallback,
  failed,
}

class ProjectFileShareResult {
  const ProjectFileShareResult._({
    required this.status,
    required this.message,
    this.url,
  });

  final ProjectFileShareStatus status;
  final String message;
  final String? url;

  bool get isShared => status == ProjectFileShareStatus.shared;
  bool get isCopiedLink => status == ProjectFileShareStatus.copiedLink;
  bool get isCancelled => status == ProjectFileShareStatus.cancelled;
  bool get requiresManualFallback =>
      status == ProjectFileShareStatus.manualFallback;
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

  factory ProjectFileShareResult.manualFallback({
    required String message,
    required String url,
  }) {
    return ProjectFileShareResult._(
      status: ProjectFileShareStatus.manualFallback,
      message: message,
      url: url,
    );
  }
}

typedef ProjectFileShareInvoker = Future<ShareResult> Function(
  ShareParams params,
);
typedef ProjectFileLinkCopier = Future<void> Function(String text);

const _linkCopiedMessage =
    'Ссылка на файл скопирована. Ее можно отправить в чат или письмо.';

class ProjectFileShareService {
  ProjectFileShareService({
    ProjectFileShareInvoker? share,
    ProjectFileLinkCopier? copyLink,
    bool? isWeb,
    TargetPlatform? targetPlatform,
  })  : _share = share ?? SharePlus.instance.share,
        _copyLink = copyLink ?? _defaultCopyLink,
        _isWeb = isWeb ?? kIsWeb,
        _targetPlatform = targetPlatform ?? defaultTargetPlatform;

  final ProjectFileShareInvoker _share;
  final ProjectFileLinkCopier _copyLink;
  final bool _isWeb;
  final TargetPlatform _targetPlatform;

  bool get usesCopyLinkAsPrimaryAction =>
      _isWeb && !_isMobileTargetPlatform(_targetPlatform);

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

    if (usesCopyLinkAsPrimaryAction) {
      return _copyLinkResult(
        uri,
        message: _linkCopiedMessage,
        manualFallbackMessage:
            'Не удалось автоматически скопировать ссылку. Используйте ссылку вручную или откройте файл из диалога.',
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
      return _copyLinkResult(
        uri,
        message: _linkCopiedMessage,
        manualFallbackMessage:
            'Не удалось автоматически передать ссылку. Используйте ссылку вручную или откройте файл из диалога.',
      );
    }
  }

  Future<ProjectFileShareResult> copyLink({
    required String url,
    String successMessage = _linkCopiedMessage,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return ProjectFileShareResult.failed(
        'Не удалось скопировать ссылку: некорректный адрес.',
      );
    }

    return _copyLinkResult(
      uri,
      message: successMessage,
      manualFallbackMessage:
          'Не удалось автоматически скопировать ссылку. Скопируйте ее вручную.',
    );
  }

  static Future<void> _defaultCopyLink(String text) {
    if (kIsWeb) {
      return copyTextInBrowser(text);
    }
    return Clipboard.setData(ClipboardData(text: text));
  }

  Future<ProjectFileShareResult> _copyLinkResult(
    Uri uri, {
    required String message,
    required String manualFallbackMessage,
  }) async {
    try {
      await _copyLink(uri.toString());
      return ProjectFileShareResult.copiedLink(message);
    } catch (_) {
      return ProjectFileShareResult.manualFallback(
        message: manualFallbackMessage,
        url: uri.toString(),
      );
    }
  }

  static bool _isMobileTargetPlatform(TargetPlatform targetPlatform) {
    return targetPlatform == TargetPlatform.android ||
        targetPlatform == TargetPlatform.iOS;
  }
}
