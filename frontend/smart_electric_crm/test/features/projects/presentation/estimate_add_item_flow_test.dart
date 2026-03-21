import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/features/catalog/data/catalog_repository.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/project_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/stage_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/repositories/project_repository.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/screens/estimate_screen.dart';
import 'package:smart_electric_crm/src/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Estimate add item flow', () {
    testWidgets(
      'adds a catalog item without leaving estimate screen',
      (tester) async {
        final stage = _buildStage();
        final fakeProjectRepository = _FakeProjectRepository(stage);
        final fakeCatalogRepository = _FakeCatalogRepository(
          [
            CatalogItem(
              id: 101,
              name: 'Кабель ВВГнг',
              category: 1,
              unit: 'м',
              defaultPrice: 12,
              defaultCurrency: 'USD',
              itemType: 'work',
            ),
          ],
        );

        await _pumpEstimateScreen(
          tester,
          stage: stage,
          fakeProjectRepository: fakeProjectRepository,
          fakeCatalogRepository: fakeCatalogRepository,
          width: 600,
          platform: TargetPlatform.android,
        );

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        final searchField = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(searchField, 'Кабель');
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Кабель ВВГнг'));
        await tester.pumpAndSettle();

        final quantityDialog = find.byType(Dialog);
        expect(quantityDialog, findsOneWidget);

        final quantityField = find
            .descendant(
              of: quantityDialog,
              matching: find.byType(TextField),
            )
            .first;
        await tester.enterText(quantityField, '3');
        await tester.pump();

        await tester.tap(
          find.descendant(
            of: quantityDialog,
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('objects screen'), findsNothing);
        expect(find.byType(EstimateScreen), findsOneWidget);
        expect(fakeProjectRepository.addedPayloads, hasLength(1));
        expect(fakeProjectRepository.addedPayloads.single['catalog_item'], 101);
        expect(find.text('Кабель ВВГнг'), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets(
      'uses sticky local add action instead of FAB on Windows',
      (tester) async {
        final stage = _buildStage();
        final fakeProjectRepository = _FakeProjectRepository(stage);
        final fakeCatalogRepository = _FakeCatalogRepository(
          [
            CatalogItem(
              id: 101,
              name: 'Кабель ВВГнг',
              category: 1,
              unit: 'м',
              defaultPrice: 12,
              defaultCurrency: 'USD',
              itemType: 'work',
            ),
          ],
        );

        await _pumpEstimateScreen(
          tester,
          stage: stage,
          fakeProjectRepository: fakeProjectRepository,
          fakeCatalogRepository: fakeCatalogRepository,
          width: 1280,
          platform: TargetPlatform.windows,
        );

        expect(
          find.byKey(const ValueKey('estimate_local_nav_add_action')),
          findsOneWidget,
        );
        expect(find.byType(FloatingActionButton), findsNothing);

        await tester
            .tap(find.byKey(const ValueKey('estimate_local_nav_add_action')));
        await tester.pumpAndSettle();

        final searchField = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(searchField, 'Кабель');
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Кабель ВВГнг'));
        await tester.pumpAndSettle();

        final quantityDialog = find.byType(Dialog);
        final quantityField = find
            .descendant(
              of: quantityDialog,
              matching: find.byType(TextField),
            )
            .first;
        await tester.enterText(quantityField, '2');
        await tester.pump();

        await tester.tap(
          find.descendant(
            of: quantityDialog,
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EstimateScreen), findsOneWidget);
        expect(fakeProjectRepository.addedPayloads, hasLength(1));
        expect(fakeProjectRepository.addedPayloads.single['catalog_item'], 101);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );

    testWidgets(
      'desktop local add action follows materials tab context on Windows',
      (tester) async {
        final stage = _buildStage();
        final fakeProjectRepository = _FakeProjectRepository(stage);
        final fakeCatalogRepository = _FakeCatalogRepository(
          [
            CatalogItem(
              id: 202,
              name: 'Кабель ПВС',
              category: 1,
              unit: 'м',
              defaultPrice: 7,
              defaultCurrency: 'USD',
              itemType: 'material',
            ),
          ],
        );

        await _pumpEstimateScreen(
          tester,
          stage: stage,
          fakeProjectRepository: fakeProjectRepository,
          fakeCatalogRepository: fakeCatalogRepository,
          width: 1280,
          platform: TargetPlatform.windows,
          initialTab: EstimateSection.materials,
        );

        await tester
            .tap(find.byKey(const ValueKey('estimate_local_nav_add_action')));
        await tester.pumpAndSettle();

        final searchField = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(searchField, 'Кабель');
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Кабель ПВС'));
        await tester.pumpAndSettle();

        final quantityDialog = find.byType(Dialog);
        final quantityField = find
            .descendant(
              of: quantityDialog,
              matching: find.byType(TextField),
            )
            .first;
        await tester.enterText(quantityField, '4');
        await tester.pump();

        await tester.tap(
          find.descendant(
            of: quantityDialog,
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EstimateScreen), findsOneWidget);
        expect(fakeProjectRepository.addedPayloads, hasLength(1));
        expect(fakeProjectRepository.addedPayloads.single['catalog_item'], 202);
        expect(fakeProjectRepository.addedPayloads.single['item_type'],
            'material');
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );

    testWidgets(
      'keeps estimate screen open for manual add and saves the new item',
      (tester) async {
        final stage = _buildStage();
        final fakeProjectRepository = _FakeProjectRepository(stage);

        await _pumpEstimateScreen(
          tester,
          stage: stage,
          fakeProjectRepository: fakeProjectRepository,
          fakeCatalogRepository: _FakeCatalogRepository(const []),
          width: 600,
          platform: TargetPlatform.android,
        );

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add_circle_outline));
        await tester.pumpAndSettle();

        final editDialog = find.byType(Dialog);
        final fields = find.descendant(
          of: editDialog,
          matching: find.byType(TextField),
        );

        await tester.enterText(fields.at(0), 'Ручная работа');
        await tester.enterText(fields.at(1), 'шт');
        await tester.enterText(fields.at(2), '2');
        await tester.pump();

        await tester.tap(
          find.descendant(
            of: editDialog,
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('objects screen'), findsNothing);
        expect(find.byType(EstimateScreen), findsOneWidget);
        expect(fakeProjectRepository.addedPayloads, hasLength(1));
        expect(
            fakeProjectRepository.addedPayloads.single['catalog_item'], isNull);
        expect(fakeProjectRepository.addedPayloads.single['name'],
            'Ручная работа');
        expect(find.text('Ручная работа'), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  });
}

Future<void> _pumpEstimateScreen(
  WidgetTester tester, {
  required StageModel stage,
  required _FakeProjectRepository fakeProjectRepository,
  required _FakeCatalogRepository fakeCatalogRepository,
  required double width,
  required TargetPlatform platform,
  EstimateSection initialTab = EstimateSection.works,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectRepositoryProvider.overrideWith((ref) => fakeProjectRepository),
        catalogRepositoryProvider.overrideWith((ref) => fakeCatalogRepository),
        projectListProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        theme: AppTheme.light().copyWith(platform: platform),
        routes: {
          '/': (_) => const Scaffold(body: Text('objects screen')),
          '/estimate': (_) => Scaffold(
                body: EstimateScreen(
                  projectId: '1',
                  stage: stage,
                  initialTab: initialTab,
                ),
              ),
        },
        initialRoute: '/estimate',
      ),
    ),
  );

  await tester.pumpAndSettle();
}

StageModel _buildStage() {
  return StageModel(
    id: 10,
    title: 'stage_3',
    status: 'plan',
    isPaid: false,
    createdAt: DateTime(2026, 3, 1),
    updatedAt: DateTime(2026, 3, 1),
  );
}

class _FakeProjectRepository extends ProjectRepository {
  _FakeProjectRepository(this._stage) : super(dio: Dio());

  final StageModel _stage;
  final List<Map<String, dynamic>> addedPayloads = [];
  final List<EstimateItemModel> _items = [];

  @override
  Future<StageModel> fetchStage(int stageId) async {
    return _stage.copyWith(estimateItems: List<EstimateItemModel>.from(_items));
  }

  @override
  Future<void> addEstimateItem(Map<String, dynamic> data) async {
    addedPayloads.add(Map<String, dynamic>.from(data));
    _items.add(
      EstimateItemModel(
        id: _items.length + 1,
        stage: data['stage'] as int,
        itemType: data['item_type'] as String,
        name: data['name'] as String? ?? '',
        unit: data['unit'] as String? ?? '',
        totalQuantity: (data['total_quantity'] as num?)?.toDouble() ?? 0,
        contractorQuantity: 0,
        employerQuantity: (data['employer_quantity'] as num?)?.toDouble() ?? 0,
        pricePerUnit: (data['price_per_unit'] as num?)?.toDouble() ?? 0,
        currency: data['currency'] as String? ?? 'USD',
        markupPercent: 0,
        isPreliminary: false,
      ),
    );
  }

  @override
  Future<List<ProjectModel>> fetchProjects({String? search}) async => const [];
}

class _FakeCatalogRepository extends CatalogRepository {
  _FakeCatalogRepository(this._results) : super(client: Dio());

  final List<CatalogItem> _results;

  @override
  Future<List<CatalogItem>> searchItems(String query,
      {String? itemType}) async {
    return _results
        .where((item) => itemType == null || item.itemType == itemType)
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
