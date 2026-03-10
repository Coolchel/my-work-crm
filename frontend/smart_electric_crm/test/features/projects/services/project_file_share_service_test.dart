import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_electric_crm/src/features/projects/services/project_file_share_service.dart';

void main() {
  test('uses copy-link as primary action on desktop web', () async {
    var shareCalled = false;
    String? copiedLink;

    final service = ProjectFileShareService(
      isWeb: true,
      targetPlatform: TargetPlatform.windows,
      share: (_) async {
        shareCalled = true;
        return const ShareResult('', ShareResultStatus.unavailable);
      },
      copyLink: (text) async {
        copiedLink = text;
      },
    );

    final result = await service.shareRemoteFile(
      url: 'https://example.com/files/report.pdf',
      displayName: 'report.pdf',
    );

    expect(service.usesCopyLinkAsPrimaryAction, isTrue);
    expect(result.isCopiedLink, isTrue);
    expect(
      result.message,
      'Ссылка на файл скопирована. Ее можно отправить в чат или письмо.',
    );
    expect(copiedLink, 'https://example.com/files/report.pdf');
    expect(shareCalled, isFalse);
  });

  test('uses native share on mobile web when available', () async {
    var shareCalled = false;

    final service = ProjectFileShareService(
      isWeb: true,
      targetPlatform: TargetPlatform.android,
      share: (_) async {
        shareCalled = true;
        return const ShareResult('', ShareResultStatus.unavailable);
      },
    );

    final result = await service.shareRemoteFile(
      url: 'https://example.com/files/report.pdf',
      displayName: 'report.pdf',
    );

    expect(service.usesCopyLinkAsPrimaryAction, isFalse);
    expect(result.isShared, isTrue);
    expect(shareCalled, isTrue);
  });

  test('falls back to copy link when mobile web share is unavailable',
      () async {
    String? copiedLink;

    final service = ProjectFileShareService(
      isWeb: true,
      targetPlatform: TargetPlatform.iOS,
      share: (_) async => throw Exception('navigator.share unavailable'),
      copyLink: (text) async {
        copiedLink = text;
      },
    );

    final result = await service.shareRemoteFile(
      url: 'https://example.com/files/report.pdf',
      displayName: 'report.pdf',
    );

    expect(result.isCopiedLink, isTrue);
    expect(
      result.message,
      'Ссылка на файл скопирована. Ее можно отправить в чат или письмо.',
    );
    expect(copiedLink, 'https://example.com/files/report.pdf');
  });

  test('returns manual fallback when desktop copy also fails', () async {
    final service = ProjectFileShareService(
      isWeb: true,
      targetPlatform: TargetPlatform.windows,
      copyLink: (_) async => throw Exception('clipboard blocked'),
    );

    final result = await service.shareRemoteFile(
      url: 'https://example.com/files/report.pdf',
      displayName: 'report.pdf',
    );

    expect(result.requiresManualFallback, isTrue);
    expect(result.url, 'https://example.com/files/report.pdf');
  });

  test('returns cancelled result when mobile share sheet is dismissed',
      () async {
    final service = ProjectFileShareService(
      isWeb: true,
      targetPlatform: TargetPlatform.iOS,
      share: (_) async => const ShareResult(
        'dismissed',
        ShareResultStatus.dismissed,
      ),
    );

    final result = await service.shareRemoteFile(
      url: 'https://example.com/files/report.pdf',
      displayName: 'report.pdf',
    );

    expect(result.isCancelled, isTrue);
  });

  test('returns failed result for malformed links', () async {
    final service = ProjectFileShareService();

    final result = await service.shareRemoteFile(
      url: 'not a url',
      displayName: 'report.pdf',
    );

    expect(result.isFailed, isTrue);
  });

  test('copyLink returns failed result for malformed links', () async {
    final service = ProjectFileShareService();

    final result = await service.copyLink(url: 'not a url');

    expect(result.isFailed, isTrue);
  });
}
