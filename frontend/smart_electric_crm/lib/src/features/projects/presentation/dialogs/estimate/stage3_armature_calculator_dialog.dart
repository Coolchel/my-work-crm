import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/app_dialog_scrollbar.dart';
import 'package:flutter/services.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';

class Stage3ArmatureCalculatorResult {
  final CatalogItem item;
  final double quantity;

  const Stage3ArmatureCalculatorResult({
    required this.item,
    required this.quantity,
  });
}

class _ArmaturePosition {
  final String label;
  final String mappingKey;
  final String legacyName;
  final IconData icon;
  final Color iconColor;

  const _ArmaturePosition({
    required this.label,
    required this.mappingKey,
    required this.legacyName,
    required this.icon,
    required this.iconColor,
  });
}

const List<_ArmaturePosition> _targetPositions = [
  _ArmaturePosition(
    label: 'Выключатель, 1 клавиша',
    mappingKey: 'arm_switch_1g',
    legacyName: 'вкл 1кл',
    icon: Icons.toggle_on_rounded,
    iconColor: Color(0xFF1565C0),
  ),
  _ArmaturePosition(
    label: 'Выключатель, 2 клавиши',
    mappingKey: 'arm_switch_2g',
    legacyName: 'вкл 2кл',
    icon: Icons.toggle_on_outlined,
    iconColor: Color(0xFF1565C0),
  ),
  _ArmaturePosition(
    label: 'Выключатель проходной, 1 клавиша',
    mappingKey: 'arm_switch_1g_pass',
    legacyName: 'вкл 1кл проходной',
    icon: Icons.sync_alt_rounded,
    iconColor: Color(0xFF0D47A1),
  ),
  _ArmaturePosition(
    label: 'Выключатель проходной, 2 клавиши',
    mappingKey: 'arm_switch_2g_pass',
    legacyName: 'вкл 2кл проходной',
    icon: Icons.swap_horiz_rounded,
    iconColor: Color(0xFF0D47A1),
  ),
  _ArmaturePosition(
    label: 'Выключатель перекрестный, 1 клавиша',
    mappingKey: 'arm_switch_1g_cross',
    legacyName: 'вкл 1кл перекрестный',
    icon: Icons.call_split_rounded,
    iconColor: Color(0xFF283593),
  ),
  _ArmaturePosition(
    label: 'Выключатель перекрестный, 2 клавиши',
    mappingKey: 'arm_switch_2g_cross',
    legacyName: 'вкл 2кл перекрестный',
    icon: Icons.alt_route_rounded,
    iconColor: Color(0xFF283593),
  ),
  _ArmaturePosition(
    label: 'Розетка силовая',
    mappingKey: 'arm_socket',
    legacyName: 'розетка',
    icon: Icons.power_outlined,
    iconColor: Color(0xFF00897B),
  ),
  _ArmaturePosition(
    label: 'Розетка влагозащищённая',
    mappingKey: 'arm_socket_ip',
    legacyName: 'розетка с влагозащитой',
    icon: Icons.shield_moon_rounded,
    iconColor: Color(0xFF00897B),
  ),
  _ArmaturePosition(
    label: 'Розетка LAN, 1 порт',
    mappingKey: 'arm_socket_lan_1',
    legacyName: 'розетка LANx1',
    icon: Icons.lan_rounded,
    iconColor: Color(0xFF455A64),
  ),
  _ArmaturePosition(
    label: 'Розетка LAN, 2 порта',
    mappingKey: 'arm_socket_lan_2',
    legacyName: 'розетка LANx2',
    icon: Icons.settings_ethernet_rounded,
    iconColor: Color(0xFF455A64),
  ),
  _ArmaturePosition(
    label: 'Розетка ТВ',
    mappingKey: 'arm_socket_tv',
    legacyName: 'розетка TV',
    icon: Icons.tv_rounded,
    iconColor: Color(0xFF5D4037),
  ),
  _ArmaturePosition(
    label: 'Розетка телефонная',
    mappingKey: 'arm_socket_tel',
    legacyName: 'розетка TEL',
    icon: Icons.phone_in_talk_rounded,
    iconColor: Color(0xFF5D4037),
  ),
  _ArmaturePosition(
    label: 'Вывод кабеля',
    mappingKey: 'arm_cable_output',
    legacyName: 'вывод кабеля',
    icon: Icons.cable_rounded,
    iconColor: Color(0xFF6D4C41),
  ),
  _ArmaturePosition(
    label: 'Рамка, 1 пост',
    mappingKey: 'arm_frame_1x',
    legacyName: 'рамка 1х',
    icon: Icons.crop_portrait_rounded,
    iconColor: Color(0xFF6A1B9A),
  ),
  _ArmaturePosition(
    label: 'Рамка, 2 поста',
    mappingKey: 'arm_frame_2x',
    legacyName: 'рамка 2х',
    icon: Icons.crop_16_9_rounded,
    iconColor: Color(0xFF6A1B9A),
  ),
  _ArmaturePosition(
    label: 'Рамка, 3 поста',
    mappingKey: 'arm_frame_3x',
    legacyName: 'рамка 3х',
    icon: Icons.view_week_rounded,
    iconColor: Color(0xFF6A1B9A),
  ),
  _ArmaturePosition(
    label: 'Рамка, 4 поста',
    mappingKey: 'arm_frame_4x',
    legacyName: 'рамка 4х',
    icon: Icons.grid_4x4_rounded,
    iconColor: Color(0xFF6A1B9A),
  ),
  _ArmaturePosition(
    label: 'Рамка, 5 постов',
    mappingKey: 'arm_frame_5x',
    legacyName: 'рамка 5х',
    icon: Icons.grid_view_rounded,
    iconColor: Color(0xFF6A1B9A),
  ),
];

class Stage3ArmatureCalculatorDialog extends StatefulWidget {
  final List<CatalogItem> materialCatalogItems;

  const Stage3ArmatureCalculatorDialog({
    super.key,
    required this.materialCatalogItems,
  });

  @override
  State<Stage3ArmatureCalculatorDialog> createState() =>
      _Stage3ArmatureCalculatorDialogState();
}

class _Stage3ArmatureCalculatorDialogState
    extends State<Stage3ArmatureCalculatorDialog> {
  final Map<String, int> _quantities = {};
  final Map<String, TextEditingController> _controllers = {};
  final ScrollController _listScrollController = ScrollController();
  String? _inlineError;

  late final Map<String, CatalogItem> _catalogByMappingKey;
  late final Map<String, CatalogItem> _catalogByName;

  @override
  void initState() {
    super.initState();

    _catalogByMappingKey = {
      for (final item in widget.materialCatalogItems)
        if ((item.mappingKey ?? '').trim().isNotEmpty)
          item.mappingKey!.trim(): item,
    };
    _catalogByName = {
      for (final item in widget.materialCatalogItems) item.name.trim(): item,
    };

    for (final position in _targetPositions) {
      _quantities[position.mappingKey] = 0;
      _controllers[position.mappingKey] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  CatalogItem? _resolveCatalogItem(_ArmaturePosition position) {
    final byKey = _catalogByMappingKey[position.mappingKey];
    if (byKey != null) {
      return byKey;
    }
    return _catalogByName[position.legacyName];
  }

  bool _isMissingCatalogItem(_ArmaturePosition position) =>
      _resolveCatalogItem(position) == null;

  void _increment(_ArmaturePosition position, int delta) {
    if (_isMissingCatalogItem(position)) {
      return;
    }

    final key = position.mappingKey;
    final nextValue = (_quantities[key] ?? 0) + delta;
    setState(() {
      _quantities[key] = nextValue;
      _controllers[key]?.text = nextValue.toString();
      _inlineError = null;
    });
  }

  void _setManualValue(_ArmaturePosition position, String value) {
    if (_isMissingCatalogItem(position)) {
      return;
    }

    final key = position.mappingKey;
    final parsed = int.tryParse(value) ?? 0;
    setState(() {
      _quantities[key] = parsed < 0 ? 0 : parsed;
      _inlineError = null;
    });
  }

  void _submit() {
    final results = <Stage3ArmatureCalculatorResult>[];

    for (final position in _targetPositions) {
      final quantity = _quantities[position.mappingKey] ?? 0;
      if (quantity <= 0) {
        continue;
      }

      final item = _resolveCatalogItem(position);
      if (item == null) {
        continue;
      }

      results.add(
        Stage3ArmatureCalculatorResult(
          item: item,
          quantity: quantity.toDouble(),
        ),
      );
    }

    if (results.isEmpty) {
      setState(() {
        _inlineError = 'Добавьте хотя бы одну позицию с количеством больше 0.';
      });
      return;
    }

    Navigator.of(context).pop(results);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final missingItems = _targetPositions
        .where(_isMissingCatalogItem)
        .map((position) => position.label)
        .toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 760,
              maxHeight: constraints.maxHeight * 0.9,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.34)
                        : Colors.blue.withOpacity(0.15),
                    blurRadius: isDark ? 12 : 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppDesignTokens.surface3(context)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate_rounded,
                          color: isDark ? scheme.onSurface : Colors.blue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Калькулятор арматуры (Этап 3)',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: isDark ? scheme.onSurface : Colors.blue,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: 'Закрыть',
                        ),
                      ],
                    ),
                  ),
                  if (missingItems.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppDesignTokens.softBorder(context)
                              : Colors.orange.withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        'Не найдены в каталоге: ${missingItems.join(', ')}',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  Expanded(
                    child: AppDialogScrollbar(
                      controller: _listScrollController,
                      child: ListView.builder(
                        controller: _listScrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _targetPositions.length,
                        itemBuilder: (context, index) {
                          final position = _targetPositions[index];
                          final disabled = _isMissingCatalogItem(position);
                          return _buildRow(position, disabled);
                        },
                      ),
                    ),
                  ),
                  if (_inlineError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _inlineError!,
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            color: AppDesignTokens.softBorder(context)),
                      ),
                    ),
                    child: Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Отмена'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.playlist_add_check_rounded),
                          label: const Text('Перенести в смету'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: scheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(_ArmaturePosition position, bool disabled) {
    final textController = _controllers[position.mappingKey]!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: disabled
            ? (isDark ? AppDesignTokens.surface2(context) : Colors.grey.shade50)
            : (isDark ? AppDesignTokens.surface1(context) : scheme.surface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppDesignTokens.softBorder(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;

          final quantityField = SizedBox(
            width: isNarrow ? 96 : 86,
            child: TextField(
              controller: textController,
              enabled: !disabled,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Всего',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) => _setManualValue(position, value),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: disabled
                            ? (isDark
                                ? scheme.surfaceContainerHigh
                                : Colors.grey.shade200)
                            : position.iconColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        position.icon,
                        size: 18,
                        color: disabled
                            ? Colors.grey.shade500
                            : position.iconColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        position.label,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: disabled
                              ? Colors.grey.shade500
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.end,
                  children: [
                    _quickBtn(position, 1, disabled, compact: true),
                    _quickBtn(position, 2, disabled, compact: true),
                    _quickBtn(position, 3, disabled, compact: true),
                    quantityField,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: disabled
                      ? (isDark
                          ? scheme.surfaceContainerHigh
                          : Colors.grey.shade200)
                      : position.iconColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  position.icon,
                  size: 18,
                  color: disabled ? Colors.grey.shade500 : position.iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  position.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: disabled ? Colors.grey.shade500 : scheme.onSurface,
                  ),
                ),
              ),
              _quickBtn(position, 1, disabled),
              const SizedBox(width: 6),
              _quickBtn(position, 2, disabled),
              const SizedBox(width: 6),
              _quickBtn(position, 3, disabled),
              const SizedBox(width: 10),
              quantityField,
            ],
          );
        },
      ),
    );
  }

  Widget _quickBtn(_ArmaturePosition position, int delta, bool disabled,
      {bool compact = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton(
      onPressed: disabled ? null : () => _increment(position, delta),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(compact ? 42 : 46, compact ? 34 : 36),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 6 : 8,
        ),
        visualDensity: VisualDensity.compact,
        side: BorderSide(
          color: isDark
              ? AppDesignTokens.softBorder(context)
              : Colors.blue.withOpacity(0.35),
        ),
      ),
      child: Text(
        '+$delta',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.blue,
        ),
      ),
    );
  }
}
