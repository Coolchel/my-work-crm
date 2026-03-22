import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_web_frame.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('desktop content ending matches shell sidebar bottom offset', () {
    expect(
      DesktopWebFrame.desktopContentEndPadding,
      DesktopWebFrame.shellSidebarBottomOffset,
    );
  });

  testWidgets(
    'wide Windows shell viewport ends at the sidebar bottom level',
    (tester) async {
      final viewportInset = await _measureShellViewportBottomInset(
        tester,
        width: 1280,
        height: 900,
      );

      expect(viewportInset, DesktopWebFrame.shellSidebarBottomOffset);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'Android content ending stays compact without overlay action',
    (tester) async {
      final bottomPadding = await _measureBottomPadding(
        tester,
        width: 390,
        height: 844,
        hasOverlayAction: false,
      );

      expect(bottomPadding, DesktopWebFrame.mobileContentEndPadding);
      expect(
        bottomPadding,
        DesktopWebFrame.mobileContentHorizontalPadding,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'Android overlay action does not add extra bottom clearance',
    (tester) async {
      final bottomPadding = await _measureBottomPadding(
        tester,
        width: 390,
        height: 844,
        hasOverlayAction: true,
      );

      expect(
        bottomPadding,
        DesktopWebFrame.mobileContentEndPadding,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'wide Windows layouts use the shell-aligned bottom ending',
    (tester) async {
      final bottomPadding = await _measureBottomPadding(
        tester,
        width: 1280,
        height: 900,
        hasOverlayAction: false,
      );

      expect(bottomPadding, DesktopWebFrame.shellSidebarBottomOffset);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}

Future<double> _measureBottomPadding(
  WidgetTester tester, {
  required double width,
  required double height,
  required bool hasOverlayAction,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  double? measuredPadding;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          measuredPadding = DesktopWebFrame.scrollableContentBottomPadding(
            context,
            hasOverlayAction: hasOverlayAction,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  expect(measuredPadding, isNotNull);
  return measuredPadding!;
}

Future<double> _measureShellViewportBottomInset(
  WidgetTester tester, {
  required double width,
  required double height,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  double? measuredInset;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          measuredInset = DesktopWebFrame.persistentShellViewportBottomInset(
            context,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  expect(measuredInset, isNotNull);
  return measuredInset!;
}
