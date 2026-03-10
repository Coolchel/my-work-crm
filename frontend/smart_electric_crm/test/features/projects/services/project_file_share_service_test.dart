import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_electric_crm/src/features/projects/services/project_file_share_service.dart';

void main() {
  test('returns cancelled result when share sheet is dismissed', () async {
    final service = ProjectFileShareService(
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

  test('copies link when native web share is unavailable', () async {
    String? copiedLink;

    final service = ProjectFileShareService(
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
    expect(result.message, 'Ссылка на файл скопирована в буфер обмена.');
    expect(copiedLink, 'https://example.com/files/report.pdf');
  });

  test('returns failed result for malformed links', () async {
    final service = ProjectFileShareService();

    final result = await service.shareRemoteFile(
      url: 'not a url',
      displayName: 'report.pdf',
    );

    expect(result.isFailed, isTrue);
  });
}
