import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/core/utils/app_number_formatter.dart';
import 'package:smart_electric_crm/src/features/catalog/data/catalog_repository.dart';
import 'package:smart_electric_crm/src/shared/presentation/utils/error_feedback.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

class ItemListScreen extends ConsumerWidget {
  final int categoryId;
  final String categoryName;

  const ItemListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(fetchCategoryItemsProvider(categoryId));
    final theme = Theme.of(context);
    final textStyles = context.appTextStyles;

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const FriendlyEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'В этой категории пока нет товаров',
              subtitle: 'Добавьте первый элемент каталога.',
              accentColor: Colors.blue,
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading:
                    const Icon(Icons.inventory_2_outlined, color: Colors.blue),
                title: Text(item.name),
                trailing: Text(
                  '${AppNumberFormatter.decimal(item.defaultPrice)}\$ / ${item.unit}',
                  style: textStyles.bodyStrong.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Ошибка: $err',
            style: textStyles.body.copyWith(color: theme.colorScheme.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => _CreateItemDialog(categoryId: categoryId),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PopupSelectOption<T> {
  final T value;
  final String label;

  const _PopupSelectOption({
    required this.value,
    required this.label,
  });
}

Color _catalogDialogFieldFillColor(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return AppDesignTokens.isDark(context)
      ? scheme.surfaceContainerHigh
      : scheme.surfaceContainer.withOpacity(0.4);
}

const double _catalogDialogSingleLineFieldHeight = 56;

bool _isCatalogPopupTouchPlatform() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      return true;
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return false;
  }
}

List<PopupMenuEntry<T>> _buildPopupMenuEntriesWithDividers<T>(
  List<PopupMenuEntry<T>> entries,
) {
  final result = <PopupMenuEntry<T>>[];
  for (var index = 0; index < entries.length; index++) {
    if (index > 0) {
      result.add(const PopupMenuDivider(height: 1));
    }
    result.add(entries[index]);
  }
  return result;
}

InputDecoration _catalogDialogInputDecoration(
  BuildContext context, {
  required String label,
  bool alignLabelWithHint = false,
  BoxConstraints? constraints,
  EdgeInsetsGeometry? contentPadding,
}) {
  final scheme = Theme.of(context).colorScheme;
  final textStyles = context.appTextStyles;
  final labelStyle = textStyles.fieldLabel.copyWith(
    fontSize: 12.5,
    color: Colors.indigo.shade400,
  );
  return InputDecoration(
    labelText: label,
    labelStyle: labelStyle,
    floatingLabelStyle: labelStyle,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    alignLabelWithHint: alignLabelWithHint,
    constraints: constraints,
    isDense: true,
    filled: true,
    fillColor: _catalogDialogFieldFillColor(context),
    hintStyle: textStyles.secondaryBody.copyWith(
      color: scheme.onSurfaceVariant.withOpacity(0.75),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppDesignTokens.softBorder(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppDesignTokens.softBorder(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.indigo, width: 2),
    ),
    contentPadding: contentPadding ?? const EdgeInsets.fromLTRB(16, 18, 16, 10),
  );
}

class _CatalogDialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  const _CatalogDialogTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlignVertical: TextAlignVertical.center,
      style: context.appTextStyles.input,
      decoration: _catalogDialogInputDecoration(
        context,
        label: label,
        constraints: const BoxConstraints(
          minHeight: _catalogDialogSingleLineFieldHeight,
          maxHeight: _catalogDialogSingleLineFieldHeight,
        ),
      ),
    );
  }
}

class _PopupSelectField<T> extends StatefulWidget {
  final String label;
  final T value;
  final List<_PopupSelectOption<T>> options;
  final ValueChanged<T> onChanged;

  const _PopupSelectField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  State<_PopupSelectField<T>> createState() => _PopupSelectFieldState<T>();
}

class _PopupSelectFieldState<T> extends State<_PopupSelectField<T>> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = context.appTextStyles;
    final isTouchPlatform = _isCatalogPopupTouchPlatform();
    final menuHoverColor = AppDesignTokens.isDark(context)
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.045);
    final selected = widget.options.cast<_PopupSelectOption<T>?>().firstWhere(
          (option) => option?.value == widget.value,
          orElse: () => null,
        );
    final displayText = selected?.label ?? '';
    if (_controller.text != displayText) {
      _controller.value = TextEditingValue(
        text: displayText,
        selection: TextSelection.collapsed(offset: displayText.length),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Theme(
            data: theme.copyWith(
              hoverColor: menuHoverColor,
              highlightColor: menuHoverColor,
              splashColor: menuHoverColor,
              popupMenuTheme: theme.popupMenuTheme.copyWith(
                color: theme.colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                mouseCursor: const WidgetStatePropertyAll<MouseCursor>(
                  SystemMouseCursors.click,
                ),
              ),
            ),
            child: PopupMenuButton<T>(
              tooltip: '',
              padding: EdgeInsets.zero,
              menuPadding: EdgeInsets.zero,
              elevation: 4,
              shadowColor: AppDesignTokens.cardShadow(context),
              surfaceTintColor: Colors.transparent,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppDesignTokens.softBorder(context),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              position: isTouchPlatform
                  ? PopupMenuPosition.under
                  : PopupMenuPosition.over,
              offset: Offset(
                0,
                isTouchPlatform ? 2 : 48,
              ),
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
              ),
              onSelected: widget.onChanged,
              itemBuilder: (context) => _buildPopupMenuEntriesWithDividers(
                widget.options
                    .map(
                      (option) => PopupMenuItem<T>(
                        value: option.value,
                        height: 40,
                        mouseCursor: SystemMouseCursors.click,
                        textStyle: textStyles.body.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
              ),
              child: IgnorePointer(
                child: TextField(
                  controller: _controller,
                  readOnly: true,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  textAlignVertical: TextAlignVertical.center,
                  style: textStyles.input.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: _catalogDialogInputDecoration(
                    context,
                    label: widget.label,
                    constraints: const BoxConstraints(
                      minHeight: _catalogDialogSingleLineFieldHeight,
                      maxHeight: _catalogDialogSingleLineFieldHeight,
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(16, 18, 12, 10),
                  ).copyWith(
                    suffixIcon: Align(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CreateItemDialog extends ConsumerStatefulWidget {
  final int categoryId;

  const _CreateItemDialog({required this.categoryId});

  @override
  ConsumerState<_CreateItemDialog> createState() => _CreateItemDialogState();
}

class _CreateItemDialogState extends ConsumerState<_CreateItemDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController(text: 'шт');
  String _itemType = 'material';

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    final isDark = AppDesignTokens.isDark(context);
    final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: maxDialogHeight),
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppDesignTokens.softBorder(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.12),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Добавить товар',
                    style: textStyles.dialogTitle.copyWith(
                      color: Colors.indigo.withOpacity(0.8),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.indigo),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PopupSelectField<String>(
                      label: 'Тип',
                      value: _itemType,
                      options: const [
                        _PopupSelectOption(
                            value: 'material', label: 'Материал'),
                        _PopupSelectOption(value: 'work', label: 'Работа'),
                      ],
                      onChanged: (val) => setState(() => _itemType = val),
                    ),
                    const SizedBox(height: 16),
                    _CatalogDialogTextField(
                      controller: _nameController,
                      label: 'Название',
                    ),
                    const SizedBox(height: 16),
                    _CatalogDialogTextField(
                      controller: _priceController,
                      label: 'Цена (\$)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    _CatalogDialogTextField(
                      controller: _unitController,
                      label: 'Ед. измерения',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final name = _nameController.text;
                      final priceString =
                          _priceController.text.replaceAll(',', '.');
                      final price = double.tryParse(priceString);
                      final unit = _unitController.text;

                      if (name.isEmpty || price == null || unit.isEmpty) {
                        return;
                      }

                      try {
                        await ref.read(catalogRepositoryProvider).createItem(
                              categoryId: widget.categoryId,
                              name: name,
                              price: price,
                              measurementUnit: unit,
                              itemType: _itemType,
                            );

                        ref.invalidate(
                          fetchCategoryItemsProvider(widget.categoryId),
                        );

                        if (context.mounted) Navigator.of(context).pop();
                      } catch (e, st) {
                        if (context.mounted) {
                          debugPrint('Create catalog item failed: $e\n$st');
                          await ErrorFeedback.show(
                            context,
                            e,
                            fallbackMessage:
                                'Не удалось создать товар. Попробуйте снова.',
                          );
                        }
                      }
                    },
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
