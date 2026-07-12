import 'package:flutter/material.dart';

/// Элемент кастомного дропдауна.
class AppDropdownItem<T> {
  final T value;
  final Widget child;
  const AppDropdownItem({required this.value, required this.child});
}

/// Кастомное поле-дропдаун.
///
/// В отличие от стандартного [DropdownButtonFormField], меню которого
/// само выбирает ширину (по самому длинному пункту) и позицию (может
/// открыться вверх, если снизу мало места, и не выравнивается по краям
/// поля), этот виджет гарантирует:
///  - ширина меню == ширина поля;
///  - меню открывается строго под полем и визуально соединено с ним
///    (нет зазора, общая скруглённая "капсула");
///  - у меню такое же скругление углов, как у самого поля;
///  - при открытии меню нижние углы поля становятся прямыми — чтобы
///    поле и список читались как единая форма.
class AppDropdownField<T> extends StatefulWidget {
  final T value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final Color fillColor;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;
  final double maxMenuHeight;

  const AppDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.fillColor = const Color(0xFFF3EEE4),
    this.borderRadius = 10,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    this.maxMenuHeight = 260,
  });

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  final GlobalKey _fieldKey = GlobalKey();
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  bool _open = false;

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  void _toggle() => _open ? _close() : _show();

  void _show() {
    final box = _fieldKey.currentContext!.findRenderObject() as RenderBox;
    final size = box.size;

    _entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Клик вне меню — закрыть.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            // Ноль зазора по вертикали — список визуально "приклеен" к полю.
            offset: Offset(0, size.height),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: size.width,
                child: Container(
                  constraints: BoxConstraints(maxHeight: widget.maxMenuHeight),
                  decoration: BoxDecoration(
                    color: widget.fillColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(widget.borderRadius),
                      bottomRight: Radius.circular(widget.borderRadius),
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 6)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: widget.items.map((item) {
                      final selected = item.value == widget.value;
                      return InkWell(
                        onTap: () {
                          widget.onChanged(item.value);
                          _close();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: widget.contentPadding,
                          color: selected ? const Color(0xFFEFD9AC) : Colors.transparent,
                          child: DefaultTextStyle.merge(
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                            child: item.child,
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
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.items.firstWhere(
      (i) => i.value == widget.value,
      orElse: () => widget.items.first,
    );

    // Когда меню открыто — "срезаем" нижние углы поля, чтобы оно
    // визуально соединялось со списком без шва.
    final radius = BorderRadius.only(
      topLeft: Radius.circular(widget.borderRadius),
      topRight: Radius.circular(widget.borderRadius),
      bottomLeft: Radius.circular(_open ? 0 : widget.borderRadius),
      bottomRight: Radius.circular(_open ? 0 : widget.borderRadius),
    );

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
            decoration: BoxDecoration(color: widget.fillColor, borderRadius: radius),
            padding: widget.contentPadding,
            child: Row(
              children: [
                Expanded(child: selected.child),
                Icon(
                  _open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF9C9484),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
