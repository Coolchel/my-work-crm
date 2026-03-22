import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/core/theme/app_theme.dart';
import 'package:smart_electric_crm/src/features/statistics/data/models/statistics_model.dart';
import 'package:smart_electric_crm/src/features/statistics/data/repositories/statistics_repository.dart';
import 'package:smart_electric_crm/src/features/statistics/presentation/screens/statistics_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StatisticsScreen UI', () {
    testWidgets(
      'keeps analytics hierarchy readable on desktop width',
      (tester) async {
        await _pumpStatisticsScreen(
          tester,
          width: 1280,
          height: 900,
          platform: TargetPlatform.windows,
        );

        expect(find.text('Финансы за месяц'), findsOneWidget);
        expect(find.text('Откуда объекты'), findsOneWidget);
        expect(find.text('Типы объектов'), findsOneWidget);
        expect(find.text('Динамика работ'), findsOneWidget);
        expect(find.text('USD \$'), findsOneWidget);
        expect(find.text('BYN р'), findsOneWidget);
        expect(find.text('Заработок по сделанным объектам'), findsNWidgets(2));
      },
    );

    testWidgets(
      'keeps mobile portrait special-case for charts',
      (tester) async {
        await _pumpStatisticsScreen(
          tester,
          width: 390,
          height: 844,
          platform: TargetPlatform.android,
        );

        expect(find.text('Финансы за месяц'), findsOneWidget);
        expect(find.text('Динамика работ'), findsOneWidget);
        expect(find.byIcon(Icons.screen_rotation_alt_rounded), findsOneWidget);
        expect(
          find.text(
            'Поверните устройство горизонтально для просмотра графиков',
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SizedBox &&
                widget.height == 24 &&
                widget.width == null,
          ),
          findsNWidgets(2),
        );
      },
    );
  });
}

Future<void> _pumpStatisticsScreen(
  WidgetTester tester, {
  required double width,
  required double height,
  required TargetPlatform platform,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        statisticsDataProvider.overrideWith((ref) async => _buildStats()),
      ],
      child: MaterialApp(
        theme: AppTheme.light().copyWith(platform: platform),
        home: const StatisticsScreen(
          onBackPressed: _noop,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

StatisticsModel _buildStats() {
  return const StatisticsModel(
    finances: CurrencyAmount(
      usd: 12450.0,
      byn: 38500.0,
    ),
    sources: [
      SourceData(name: 'Рекомендации', count: 5, usd: 6200, byn: 0),
      SourceData(name: 'Сайт', count: 3, usd: 4100, byn: 0),
      SourceData(name: 'Повторные', count: 2, usd: 2150, byn: 0),
    ],
    objectTypes: [
      ObjectTypeData(name: 'Квартира', count: 4, usd: 5900, byn: 0),
      ObjectTypeData(name: 'Дом', count: 3, usd: 4300, byn: 0),
      ObjectTypeData(name: 'Офис', count: 1, usd: 2250, byn: 0),
    ],
    workDynamics: [
      WorkDynamicsData(date: '2026-03-01', usd: 1200, byn: 3600),
      WorkDynamicsData(date: '2026-03-08', usd: 1800, byn: 5400),
      WorkDynamicsData(date: '2026-03-15', usd: 2400, byn: 7200),
      WorkDynamicsData(date: '2026-03-20', usd: 1650, byn: 4950),
    ],
  );
}

void _noop() {}
