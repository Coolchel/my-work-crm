import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/core/theme/app_theme.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/confirmation_dialog.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/desktop_dialog_foundation.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/text_input_dialog.dart';

void main() {
  testWidgets(
    'ConfirmationDialog uses desktop foundation on Windows and preserves close/cancel/confirm flows',
    (tester) async {
      await _pumpDialogHost(
        tester,
        size: const Size(1280, 900),
        dialogBuilder: () => const ConfirmationDialog(
          title: 'Delete item',
          content:
              'Delete this item permanently? This action affects dependent records and should be reviewed before confirming. Delete this item permanently?',
          confirmText: 'Delete',
          cancelText: 'Cancel',
          isDestructive: true,
        ),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopDialogShell), findsOneWidget);
      expect(
        tester.getSize(find.widgetWithText(TextButton, 'Cancel')),
        tester.getSize(find.widgetWithText(FilledButton, 'Delete')),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Result: false'), findsOneWidget);

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopDialogShell), findsOneWidget);
      expect(find.byType(Scrollbar), findsWidgets);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Result: false'), findsOneWidget);

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Result: true'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'TextInputDialog uses desktop foundation on Windows and returns both fields',
    (tester) async {
      await _pumpDialogHost(
        tester,
        size: const Size(1280, 900),
        dialogBuilder: () => const TextInputDialog(
          title: 'Create template',
          labelText: 'Name',
          descriptionLabelText: 'Description',
          confirmText: 'Save',
          cancelText: 'Cancel',
        ),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopDialogShell), findsOneWidget);
      expect(
        tester.getSize(find.widgetWithText(TextButton, 'Cancel')),
        tester.getSize(find.widgetWithText(FilledButton, 'Save')),
      );

      final nameField = tester.widget<TextField>(find.byType(TextField).first);
      final focusedBorder =
          nameField.decoration!.focusedBorder! as OutlineInputBorder;
      expect(focusedBorder.borderSide.width, 1.25);

      await tester.enterText(find.byType(TextField).at(0), 'Template A');
      await tester.enterText(find.byType(TextField).at(1), 'Two field dialog');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Result: {text: Template A, description: Two field dialog}'),
        findsOneWidget,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'Shared dialogs keep mobile presentation path on Android and still submit',
    (tester) async {
      await _pumpDialogHost(
        tester,
        size: const Size(390, 844),
        dialogBuilder: () => const TextInputDialog(
          title: 'Rename',
          labelText: 'Name',
          confirmText: 'Save',
          cancelText: 'Cancel',
        ),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopDialogShell), findsNothing);

      await tester.enterText(find.byType(TextField), 'Mobile value');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Result: Mobile value'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}

Future<void> _pumpDialogHost(
  WidgetTester tester, {
  required Size size,
  required Widget Function() dialogBuilder,
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
      home: _DialogHost(dialogBuilder: dialogBuilder),
    ),
  );
  await tester.pumpAndSettle();
}

class _DialogHost extends StatefulWidget {
  final Widget Function() dialogBuilder;

  const _DialogHost({required this.dialogBuilder});

  @override
  State<_DialogHost> createState() => _DialogHostState();
}

class _DialogHostState extends State<_DialogHost> {
  Object? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () async {
                final result = await showDialog<Object?>(
                  context: context,
                  builder: (_) => widget.dialogBuilder(),
                );
                if (!mounted) {
                  return;
                }
                setState(() => _result = result);
              },
              child: const Text('Open dialog'),
            ),
            const SizedBox(height: 16),
            Text('Result: ${_result ?? 'none'}'),
          ],
        ),
      ),
    );
  }
}
