import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/core/theme/app_theme.dart';
import 'package:smart_electric_crm/src/features/catalog/data/directory_repository.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/category_model.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/directory_models.dart';
import 'package:smart_electric_crm/src/features/catalog/presentation/category_list_screen.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_side_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Catalog and directory card layout audit', () {
    testWidgets(
      'uses sticky top add action instead of FAB on wide layout',
      (tester) async {
        await _pumpCatalogScreen(
          tester,
          width: 1280,
          initialTab: CatalogSection.system,
        );

        expect(
          find.byKey(const ValueKey('catalog_local_nav_add_action')),
          findsOneWidget,
        );
        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );

    testWidgets(
      'uses mobile overlay add action on Android root catalog screen',
      (tester) async {
        await _pumpCatalogScreen(
          tester,
          width: 390,
          initialTab: CatalogSection.system,
          targetPlatform: TargetPlatform.android,
        );

        expect(
          find.byKey(const ValueKey('catalog_mobile_add_action')),
          findsOneWidget,
        );
        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );

    testWidgets(
      'keeps root catalog content separated from desktop shell menu',
      (tester) async {
        await _pumpCatalogScreen(
          tester,
          width: 1280,
          initialTab: CatalogSection.system,
        );

        final menuRect = tester.getRect(find.byType(DesktopSideMenu));
        final titleRect = tester.getRect(find.text(_longSectionName));

        expect(titleRect.left, greaterThan(menuRect.right));
      },
    );

    testWidgets(
      'uses top add action in section entries screen instead of FAB',
      (tester) async {
        await _pumpCatalogScreen(
          tester,
          width: 1280,
          initialTab: CatalogSection.system,
        );

        await tester.tap(find.text(_longSectionName));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('directory_entries_add_action')),
          findsOneWidget,
        );
        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );

    testWidgets(
      'uses top add action in category items screen instead of FAB',
      (tester) async {
        await _pumpCatalogScreen(
          tester,
          width: 1280,
          initialTab: CatalogSection.catalog,
        );

        await tester.tap(find.text(_categoryName));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('category_items_add_action')),
          findsOneWidget,
        );
        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );

    testWidgets(
      'returns to catalog root when switching from system nested screen',
      (tester) async {
        await _pumpCatalogScreen(
          tester,
          width: 1280,
          initialTab: CatalogSection.system,
        );

        await tester.tap(find.text(_longSectionName));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('directory_entries_local_nav')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey('directory_entries_local_nav_catalog')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('directory_entries_local_nav')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('catalog_local_nav')), findsOneWidget);
        expect(find.text(_categoryName), findsOneWidget);
      },
    );

    testWidgets(
      'returns to system root when tapping system from system nested screen',
      (tester) async {
        await _pumpCatalogScreen(
          tester,
          width: 1280,
          initialTab: CatalogSection.system,
        );

        await tester.tap(find.text(_longSectionName));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('directory_entries_local_nav_system')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('directory_entries_local_nav')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('catalog_local_nav')), findsOneWidget);
        expect(find.text(_longSectionName), findsOneWidget);
      },
    );

    testWidgets(
      'returns to system root when switching from catalog nested screen',
      (tester) async {
        await _pumpCatalogScreen(
          tester,
          width: 1280,
          initialTab: CatalogSection.catalog,
        );

        await tester.tap(find.text(_categoryName));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('category_items_local_nav')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey('category_items_local_nav_system')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('category_items_local_nav')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('catalog_local_nav')), findsOneWidget);
        expect(find.text(_longSectionName), findsOneWidget);
      },
    );

    testWidgets(
      'returns to catalog root when tapping catalog from catalog nested screen',
      (tester) async {
        await _pumpCatalogScreen(
          tester,
          width: 1280,
          initialTab: CatalogSection.catalog,
        );

        await tester.tap(find.text(_categoryName));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('category_items_local_nav_catalog')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('category_items_local_nav')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('catalog_local_nav')), findsOneWidget);
        expect(find.text(_categoryName), findsOneWidget);
      },
    );

    testWidgets(
      'keeps system section titles readable on narrow layout',
      (tester) async {
        await _pumpCatalogScreen(
          tester,
          width: 390,
          initialTab: CatalogSection.system,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(_longSectionName), findsOneWidget);
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);

        final title = tester.widget<Text>(find.text(_longSectionName));
        expect(title.maxLines, 2);
        expect(title.overflow, TextOverflow.ellipsis);
      },
    );

    testWidgets(
      'keeps actions top-aligned and metadata directly under title on narrow layout',
      (tester) async {
        await _pumpCatalogScreen(
          tester,
          width: 390,
          initialTab: CatalogSection.system,
        );

        expect(tester.takeException(), isNull);

        final titleRect = tester.getRect(find.text(_longSectionName));
        final subtitleRect = tester.getRect(find.text(_sectionCode));
        final descriptionRect = tester.getRect(find.text(_sectionDescription));
        final editRect = tester.getRect(find.byIcon(Icons.edit_outlined));
        final deleteRect = tester.getRect(find.byIcon(Icons.close));

        expect((editRect.top - titleRect.top).abs(), lessThanOrEqualTo(8));
        expect((deleteRect.top - titleRect.top).abs(), lessThanOrEqualTo(8));
        expect(subtitleRect.top, greaterThan(titleRect.top));
        expect(subtitleRect.top - titleRect.bottom, lessThanOrEqualTo(12));
        expect(descriptionRect.top, greaterThan(subtitleRect.top));
        expect(
            descriptionRect.top - subtitleRect.bottom, lessThanOrEqualTo(12));
      },
    );

    testWidgets(
      'keeps catalog item titles readable on narrow layout',
      (tester) async {
        await _pumpCatalogScreen(
          tester,
          width: 390,
          initialTab: CatalogSection.catalog,
        );

        await tester.tap(find.text(_categoryName));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(_longItemName), findsOneWidget);
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);

        final title = tester.widget<Text>(find.text(_longItemName));
        expect(title.maxLines, 2);
        expect(title.overflow, TextOverflow.ellipsis);
      },
    );

    testWidgets(
      'preserves dense one-line card layout on wide screens',
      (tester) async {
        await _pumpCatalogScreen(
          tester,
          width: 1280,
          initialTab: CatalogSection.catalog,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(_categoryName), findsOneWidget);
        final categoryTitle = tester.widget<Text>(find.text(_categoryName));
        expect(categoryTitle.maxLines, 1);

        await tester.tap(find.text(_categoryName));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(_longItemName), findsOneWidget);
        final itemTitle = tester.widget<Text>(find.text(_longItemName));
        expect(itemTitle.maxLines, 1);
      },
    );

    testWidgets(
      'desktop side menu uses the shared soft border in dark theme',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
            home: Scaffold(
              body: DesktopSideMenu(
                items: [
                  DesktopSideMenuItem(
                    label: 'Test',
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    isSelected: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        final decoration = tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(DesktopSideMenu),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration as BoxDecoration;
        final border = decoration.border! as Border;

        expect(border.top.color, const Color(0x1FFFFFFF));
      },
    );
  });
}

const _longSectionName =
    'Очень длинное название системного раздела для проверки локальной адаптивной иерархии карточки';
const _sectionCode = 'system.section.long.code';
const _sectionDescription = 'Описание раздела для локальной проверки UI.';
const _categoryName =
    'Категория с длинным названием для проверки плотности и читаемости в каталоге';
const _longItemName =
    'Сверхдлинная позиция каталога для проверки читаемости строки и доступности действий на узком экране';

class _FakeDirectoryRepository extends DirectoryRepository {
  _FakeDirectoryRepository() : super(client: Dio());

  @override
  Future<void> bootstrapDirectory() async {}

  @override
  Future<List<DirectorySection>> getSections() async {
    return const [
      DirectorySection(
        id: 1,
        code: _sectionCode,
        name: _longSectionName,
        description: _sectionDescription,
      ),
    ];
  }

  @override
  Future<List<DirectoryEntry>> getEntries(int sectionId) async {
    return const [
      DirectoryEntry(
        id: 1,
        section: 1,
        code: 'entry.code.long.value',
        name: 'Запись справочника',
        sortOrder: 100,
        isActive: true,
        metadata: <String, dynamic>{'group': 'alpha'},
      ),
    ];
  }

  @override
  Future<List<CatalogCategory>> getCategories() async {
    return [
      CatalogCategory(
        id: 10,
        name: _categoryName,
        slug: 'catalog-long-category',
        laborCoefficient: 1.25,
      ),
    ];
  }

  @override
  Future<List<CatalogItem>> getCategoryItems(int categoryId) async {
    return [
      CatalogItem(
        id: 101,
        category: categoryId,
        name: _longItemName,
        unit: 'шт',
        defaultPrice: 1250,
        defaultCurrency: 'USD',
        itemType: 'material',
        mappingKey: 'catalog.mapping.long.key',
        aggregationKey: 'catalog.aggregation.long.key',
      ),
    ];
  }

  @override
  Future<List<CatalogItem>> getWorkItems() async {
    return [
      CatalogItem(
        id: 501,
        name: 'Монтажная работа',
        unit: 'час',
        defaultPrice: 100,
        defaultCurrency: 'USD',
        itemType: 'work',
      ),
    ];
  }
}

Future<void> _pumpCatalogScreen(
  WidgetTester tester, {
  required double width,
  required CatalogSection initialTab,
  TargetPlatform targetPlatform = TargetPlatform.windows,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  SharedPreferences.setMockInitialValues({
    'show_welcome_screen': false,
    'show_catalog_menu': true,
    'app_theme_mode': themeMode.index,
  });

  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1200);
  final previousPlatform = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = targetPlatform;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        directoryRepositoryProvider
            .overrideWithValue(_FakeDirectoryRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.light().copyWith(platform: targetPlatform),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: CategoryListScreen(initialTab: initialTab),
      ),
    ),
  );

  await tester.pumpAndSettle();
  debugDefaultTargetPlatformOverride = previousPlatform;
}
