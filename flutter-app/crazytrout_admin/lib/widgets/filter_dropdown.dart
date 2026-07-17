// ============================================================================
// filter_dropdown.dart — Stack-based dropdown для фильтров.
//
// Dropdown рендерится ВНУТРИ дерева виджетов (не Overlay), поэтому нижнее
// меню Scaffold.bottomNavigationBar естественно перекрывает его при скролле.
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FilterDropdownItem<T> {
  final T? value;
  final String label;
  final bool isReset;
  final bool enabled;
  const FilterDropdownItem({
    required this.value,
    required this.label,
    this.isReset = false,
    this.enabled = true,
  });
}

class FilterDropdown<T> extends StatefulWidget {
  final T? value;
  final String label;
  final List<FilterDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool active;

  const FilterDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.active = false,
  });

  @override
  State<FilterDropdown<T>> createState() => _FilterDropdownState<T>();
}

class _FilterDropdownState<T> extends State<FilterDropdown<T>> {
  final GlobalKey _fieldKey = GlobalKey();
  bool _open = false;

  static const double _borderRadius = 12;
  static const double _itemHeight = 42;

  void _toggle() => _open ? _close() : _show();

  void _show() {
    setState(() => _open = true);
  }

  void _close() {
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(_borderRadius),
      topRight: const Radius.circular(_borderRadius),
      bottomLeft: Radius.circular(_open ? 0 : _borderRadius),
      bottomRight: Radius.circular(_open ? 0 : _borderRadius),
    );

    String displayLabel = widget.label;
    if (widget.value != null) {
      for (final item in widget.items) {
        if (item.value == widget.value && !item.isReset) {
          displayLabel = item.label;
          break;
        }
      }
    }
    final active = widget.value != null;

    // Строим кнопку
    final button = Container(
      key: _fieldKey,
      decoration: BoxDecoration(color: kFill, borderRadius: radius),
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              displayLabel,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? kInk : kMuted2,
              ),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                _open
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: kMuted2,
              ),
              if (widget.active)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: SizedBox(
                    width: 7,
                    height: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: kOrange, shape: BoxShape.circle),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    // Строим список элементов dropdown
    final dropdownList = Container(
      decoration: BoxDecoration(
        color: kFill,
        boxShadow: const [
          BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.items.map((item) {
          final selected = item.value == widget.value && item.value != null;
          final enabled = item.enabled;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled
                ? () {
                    widget.onChanged(item.value);
                    _close();
                  }
                : null,
            child: Container(
              width: double.infinity,
              height: _itemHeight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: selected ? kSelected : Colors.transparent,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: item.isReset
                        ? FontWeight.w400
                        : selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                    color: enabled
                        ? (item.isReset ? kMuted2 : kInk)
                        : kHairline,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    // Оборачиваем в Stack: кнопка + dropdown под ней
    // Dropdown рендерится в дереве виджетов → нижнее меню Scaffold
    // естественно перекрывает его (z-order: body < bottomNavigationBar)
    return GestureDetector(
      onTap: _toggle,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Кнопка фильтра
          Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _toggle,
              child: button,
            ),
          ),
          // Выпадающий список — строго под кнопкой, без зазора
          if (_open)
            Positioned(
              top: 44, // высота кнопки
              left: 0,
              right: 0,
              child: dropdownList,
            ),
        ],
      ),
    );
  }
}
