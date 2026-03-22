import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_electric_crm/src/core/theme/app_theme.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/dialogs/project_file_share_fallback_dialog.dart';
import 'package:smart_electric_crm/src/features/projects/services/project_file_save_service.dart';
import 'package:smart_electric_crm/src/features/projects/services/project_file_share_service.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/desktop_dialog_foundation.dart';
import 'package:smart_electric_crm/src/shared/presentation/utils/error_feedback.dart';

void main() {
  testWidgets(
    'project file fallback dialog uses desktop foundation on Windows',
    (tester) async {
      await _pumpHost(
        tester,
        size: const Size(1280, 900),
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showProjectFileShareFallbackDialog(
              context: context,
              url: 'https://example.com/file.pdf',
              displayName: 'file.pdf',
              saveService: _FakeSaveService(),
              shareService: _FakeShareService(),
            ),
            child: const Text('Open fallback'),
          ),
        ),
      );

      await tester.tap(find.text('Open fallback'));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopDialogShell), findsOneWidget);
      expect(find.text('https://example.com/file.pdf'), findsOneWidget);

      await tester.tap(find.text('\u0417\u0430\u043a\u0440\u044b\u0442\u044c'));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopDialogShell), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'ErrorFeedback uses desktop message dialog when invoked from popup route on Windows',
    (tester) async {
      await _pumpHost(
        tester,
        size: const Size(1280, 900),
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    content: FilledButton(
                      onPressed: () => ErrorFeedback.showMessage(
                        dialogContext,
                        '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043e\u0431\u043d\u043e\u0432\u0438\u0442\u044c \u0434\u0430\u043d\u043d\u044b\u0435.',
                      ),
                      child: const Text('Trigger error'),
                    ),
                  );
                },
              );
            },
            child: const Text('Open popup'),
          ),
        ),
      );

      await tester.tap(find.text('Open popup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trigger error'));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopMessageDialog), findsOneWidget);

      await tester.tap(find.text('\u041f\u043e\u043d\u044f\u0442\u043d\u043e'));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopMessageDialog), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'ErrorFeedback keeps snackbar fallback outside popup route',
    (tester) async {
      await _pumpHost(
        tester,
        size: const Size(1280, 900),
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () => ErrorFeedback.showMessage(
              context,
              'Simple message',
              title: 'Info',
            ),
            child: const Text('Show message'),
          ),
        ),
      );

      await tester.tap(find.text('Show message'));
      await tester.pump();

      expect(find.byType(DesktopMessageDialog), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Simple message'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required Size size,
  required Widget child,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;

  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeShareService extends ProjectFileShareService {
  _FakeShareService()
      : super(
          share: _share,
          copyLink: _copyLink,
          isWeb: false,
          targetPlatform: TargetPlatform.windows,
        );

  static Future<ShareResult> _share(ShareParams params) async {
    return const ShareResult('', ShareResultStatus.unavailable);
  }

  static Future<void> _copyLink(String text) async {}
}

class _FakeSaveService extends ProjectFileSaveService {
  _FakeSaveService()
      : super(
          picker: _FakeSavePicker(),
          writer: _FakeWriter(),
          downloadBytes: (_) async => throw UnimplementedError(),
          browserSave: ({required bytes, required fileName}) async {},
          useBrowserDownload: false,
        );
}

class _FakeSavePicker implements ProjectFileSavePicker {
  @override
  bool get requiresBytesBeforePicking => false;

  @override
  Future<ProjectFileSaveSelection?> pickDestination({
    required String suggestedFileName,
    bytes,
  }) async {
    return const ProjectFileSaveSelection(
      path: 'C:/tmp/file.pdf',
      isPersistedByPlatform: false,
    );
  }
}

class _FakeWriter implements ProjectFileWriter {
  @override
  Future<void> writeBytes(String path, bytes) async {}
}
