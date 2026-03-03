import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/shared/presentation/utils/error_feedback.dart';
import '../../../../engineering/data/models/shield_group_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../providers/project_providers.dart';

class ShieldGroupDialog extends StatefulWidget {
  final String projectId;
  final int shieldId;
  final ShieldGroupModel? group;
  final Color themeColor;

  const ShieldGroupDialog(
      {required this.projectId,
      required this.shieldId,
      this.group,
      required this.themeColor,
      super.key});

  @override
  State<ShieldGroupDialog> createState() => _ShieldGroupDialogState();
}

class _ShieldGroupDialogState extends State<ShieldGroupDialog> {
  late TextEditingController _zoneController;
  final ScrollController _scrollController = ScrollController();
  String _selectedDeviceType = 'diff_breaker';
  String _selectedRating = '16A';
  String _selectedPoles = '2P';
  bool _isSaving = false;

  final Map<String, String> _deviceTypes = {
    'circuit_breaker': 'РђРІС‚РѕРјР°С‚',
    'diff_breaker': 'Р”РёС„.Р°РІС‚РѕРјР°С‚',
    'rcd': 'РЈР—Рћ',
    'relay': 'Р РµР»Рµ РЅР°РїСЂСЏР¶РµРЅРёСЏ',
    'contactor': 'РљРѕРЅС‚Р°РєС‚РѕСЂ',
    'load_switch': 'Р’С‹РєР»СЋС‡Р°С‚РµР»СЊ РЅР°РіСЂСѓР·РєРё',
    'other': 'Р”СЂСѓРіРѕРµ',
  };

  @override
  void initState() {
    super.initState();
    debugPrint('ShieldGroupDialog: initState');
    try {
      _zoneController = TextEditingController(text: widget.group?.zone ?? '');
      _selectedRating = widget.group?.rating ?? '16A';
      _selectedPoles = widget.group?.poles ?? '2P';

      if (widget.group != null) {
        debugPrint('Editing group: ${widget.group!.id}');
        _selectedDeviceType = widget.group!.deviceType;
      }
    } catch (e, stack) {
      debugPrint('Error in ShieldGroupDialog initState: $e\n$stack');
    }
  }

  @override
  void dispose() {
    _zoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.group != null;
    final themeColor = widget.themeColor;
    final isDark = AppDesignTokens.isDark(context);

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme:
            Theme.of(context).colorScheme.copyWith(primary: themeColor),
      ),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.34)
                    : Colors.black.withOpacity(0.12),
                blurRadius: isDark ? 12 : 20,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        isEdit
                            ? "Р РµРґР°РєС‚РёСЂРѕРІР°С‚СЊ РіСЂСѓРїРїСѓ"
                            : "Р”РѕР±Р°РІРёС‚СЊ РіСЂСѓРїРїСѓ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: themeColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Device Type Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                "РўРёРї СѓСЃС‚СЂРѕР№СЃС‚РІР°",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                            _buildPopupBtn(
                              _deviceTypes[_selectedDeviceType] ??
                                  'Р”РёС„.Р°РІС‚РѕРјР°С‚',
                              _withMenuDividers(
                                _deviceTypes.entries
                                    .map((e) => PopupMenuItem<String>(
                                          value: e.key,
                                          height: 40,
                                          padding: EdgeInsets.zero,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                            alignment: Alignment.centerLeft,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _getDeviceIcon(e.key),
                                                  size: 18,
                                                  color:
                                                      _getDeviceTypeColor(e.key)
                                                          .withOpacity(0.7),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(e.value,
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              (value) =>
                                  setState(() => _selectedDeviceType = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Rating and Poles Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      "РќРѕРјРёРЅР°Р»",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  _buildPopupBtn(
                                    _selectedRating,
                                    _withMenuDividers(
                                      [
                                        '6A',
                                        '10A',
                                        '16A',
                                        '20A',
                                        '25A',
                                        '32A',
                                        '40A',
                                        '50A',
                                        '63A',
                                        '80A'
                                      ]
                                          .map((choice) =>
                                              PopupMenuItem<String>(
                                                value: choice,
                                                height: 40,
                                                padding: EdgeInsets.zero,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.flash_on,
                                                          color: Colors
                                                              .orange.shade600,
                                                          size: 18),
                                                      const SizedBox(width: 8),
                                                      Text(choice,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      13)),
                                                    ],
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                    (value) =>
                                        setState(() => _selectedRating = value),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      "РџРѕР»СЋСЃР°",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  _buildPopupBtn(
                                    _selectedPoles,
                                    _withMenuDividers(
                                      ['1P', '2P', '3P', '4P']
                                          .map((choice) =>
                                              PopupMenuItem<String>(
                                                value: choice,
                                                height: 40,
                                                padding: EdgeInsets.zero,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.electric_bolt,
                                                          color: Colors
                                                              .blue.shade600,
                                                          size: 18),
                                                      const SizedBox(width: 8),
                                                      Text(choice,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      13)),
                                                    ],
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                    (value) =>
                                        setState(() => _selectedPoles = value),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _zoneController,
                          decoration: InputDecoration(
                            labelText: "Р—РѕРЅР° / РџРѕС‚СЂРµР±РёС‚РµР»СЊ",
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            hintText: "РќР°РїСЂРёРјРµСЂ: РљСѓС…РЅСЏ",
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.75),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: themeColor.withOpacity(0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: themeColor.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: themeColor, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface),
                      child: const Text("РћС‚РјРµРЅР°"),
                    ),
                    const SizedBox(width: 8),
                    Consumer(builder: (context, ref, _) {
                      return FilledButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                setState(() => _isSaving = true);
                                try {
                                  final data = {
                                    'device_type': _selectedDeviceType,
                                    'rating': _selectedRating,
                                    'poles': _selectedPoles,
                                    'zone': _zoneController.text,
                                    'quantity': 1,
                                  };
                                  if (isEdit) {
                                    await ref
                                        .read(engineeringRepositoryProvider)
                                        .updateShieldGroup(
                                            widget.group!.id, data);
                                  } else {
                                    await ref
                                        .read(engineeringRepositoryProvider)
                                        .addShieldGroup(widget.shieldId, data);
                                  }
                                  ref.invalidate(projectListProvider);
                                  ref.invalidate(
                                      projectByIdProvider(widget.projectId));
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e, st) {
                                  if (context.mounted) {
                                    debugPrint(
                                        'ShieldGroupDialog save failed: $e\n$st');
                                    await ErrorFeedback.show(
                                      context,
                                      e,
                                      fallbackMessage:
                                          'РќРµ СѓРґР°Р»РѕСЃСЊ СЃРѕС…СЂР°РЅРёС‚СЊ РіСЂСѓРїРїСѓ.',
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSaving = false);
                                  }
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: themeColor,
                          minimumSize: const Size(120, 44),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(isEdit
                                ? 'РЎРѕС…СЂР°РЅРёС‚СЊ'
                                : 'Р”РѕР±Р°РІРёС‚СЊ'),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _withMenuDividers(
      List<PopupMenuEntry<String>> entries) {
    final result = <PopupMenuEntry<String>>[];
    for (var i = 0; i < entries.length; i++) {
      result.add(entries[i]);
      if (i < entries.length - 1) {
        result.add(const PopupMenuDivider(height: 1));
      }
    }
    return result;
  }

  Widget _buildPopupBtn(String label, List<PopupMenuEntry<String>> items,
      ValueChanged<String> onSelected) {
    const bg = Colors.brown;
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final popupBackgroundColor =
        (isDark ? scheme.surfaceContainerHigh : scheme.surface).withOpacity(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: popupBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppDesignTokens.softBorder(context)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final Offset position = box.localToGlobal(Offset.zero);
                final Size size = box.size;

                // Configure Theme to remove dividers/decorations from showMenu
                showMenu<String>(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    position.dx,
                    position.dy + size.height + 4, // 4px offset
                    position.dx + size.width,
                    position.dy + size.height + 300,
                  ),
                  items: items,
                  elevation: 4,
                  shadowColor: AppDesignTokens.cardShadow(context),
                  surfaceTintColor: Colors.transparent, // Disable M3 tint
                  color: popupBackgroundColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  constraints: BoxConstraints(
                    minWidth: size.width,
                    maxWidth: size.width,
                  ),
                ).then((value) {
                  if (value != null) {
                    onSelected(value);
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              mouseCursor: SystemMouseCursors.click,
              hoverColor: bg.shade700.withOpacity(isDark ? 0.12 : 0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isDark ? scheme.onSurface : bg.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down,
                        color: isDark ? scheme.onSurface : bg.shade800,
                        size: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Resolve icon by device type.
  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'circuit_breaker':
        return Icons.bolt;
      case 'diff_breaker':
        return Icons.shield_outlined;
      case 'rcd':
        return Icons.gpp_maybe_outlined;
      case 'relay':
        return Icons.av_timer;
      case 'contactor':
        return Icons.settings_input_component;
      case 'load_switch':
        return Icons.power_settings_new;
      default:
        return Icons.electrical_services;
    }
  }

  // Resolve accent color by device type.
  Color _getDeviceTypeColor(String type) {
    switch (type) {
      case 'load_switch':
        return Colors.red.shade600;
      case 'rcd':
        return Colors.amber.shade700;
      case 'circuit_breaker':
        return Colors.blue.shade600;
      case 'diff_breaker':
        return Colors.purple.shade600;
      case 'relay':
        return Colors.teal.shade600;
      case 'contactor':
        return Colors.orange.shade700;
      default:
        return Colors.blueGrey.shade600;
    }
  }
}
