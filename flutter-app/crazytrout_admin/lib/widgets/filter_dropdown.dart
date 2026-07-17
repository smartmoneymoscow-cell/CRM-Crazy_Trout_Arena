// ============================================================================
// filter_dropdown.dart — OverlayEntry-based dropdown для фильтров.
//
// Ранее дублировался в report_screen.dart и checks_screen.dart.
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/pond_map_filter_config.dart' show kBottomNavHeight;

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
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  bool _open = false;

  static const double _borderRadius = 12;
  static const double _itemHeight = 42;

  @override
  void dispose() {
    _entry = null;
    super.dispose();
  }

  void _toggle() => _open ? _close() : _show();

  void _show() {
    final box = _fieldKey.currentContext!.findRenderObject() as RenderBox;
    final size = box.size;
    final btnBottomY = box.localToGlobal(Offset(0, size.height)).dy;
    final btnTopY = box.localToGlobal(Offset.zero).dy;
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final safeBottom = kBottomNavHeight + mq.padding.bottom + 8;
    final safeTop = mq.padding.top + 8;

    final spaceBelow = screenH - btnBottomY - safeBottom;
    final spaceAbove = btnTopY - safeTop;

    // 1. Снизу есть место → вниз
    // 2. Снизу нет, сверху есть → вверх
    // 3. Нигде нет → не открывать
    final bool showBelow = spaceBelow >= _itemHeight;
    final bool showAbove = !showBelow && spaceAbove >= _itemHeight;
    if (!showBelow && !showAbove) return;

    final maxH = showBelow ? spaceBelow : spaceAbove;
    final offset = showBelow
        ? Offset(0, size.height)
        : Offset(0, -maxH);

    _entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: offset,
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: size.width,
                child: Container(
                  constraints: BoxConstraints(maxHeight: maxH),
                  decoration: BoxDecoration(
                    color: kFill,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(_borderRadius),
                      bottomRight: Radius.circular(_borderRadius),
                    ),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          offset: Offset(0, 6)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
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
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_entry!);
    setState(() => _open = true);
  }

  void _close() {
    final entry = _entry;
    _entry = null;
    if (mounted) setState(() => _open = false);
    if (mounted) entry?.remove();
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

    return CompositedTransformTarget(
      link: _link,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: _fieldKey,
          onTap: _toggle,
          child: Ink(
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
          ),
        ),
      ),
    );
  }
}
