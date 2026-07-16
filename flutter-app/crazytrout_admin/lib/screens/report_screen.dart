import 'package:flutter/material.dart';
import '../data/demo_fish_stats.dart';

// ============================================================================
// Экран «Отчёт» — отчёт по прибыли и убыткам.
//
// Верхнее меню фильтров: Период (dropdown) + Календарь (date range picker)
// + 3 слота под иконки.
//
// Виджеты _FilterDropdown, _CalendarChip, _RangeCalendarPicker перенесены
// из checks_screen.dart без изменений.
// ============================================================================

// ─── Цветовые константы ─────────────────────────────────────────────────────
const _ink = Color(0xFF14130F);
const _paper = Color(0xFFFBF6EC);
const _fill = Color(0xFFF3EEE4);
const _orange = Color(0xFFE8912B);
const _hairline = Color(0xFFEFE8D8);
const _outline = Color(0xFFDDD3BC);
const _muted = Color(0xFF8C8576);
const _muted2 = Color(0xFF9C9484);
const _selected = Color(0xFFEFD9AC);

// ─── Фильтр «Период» ───────────────────────────────────────────────────────
enum _PeriodFilter { today, week, month, quarter, all }

extension on _PeriodFilter {
  String get label => switch (this) {
        _PeriodFilter.today => 'За сегодня',
        _PeriodFilter.week => 'За неделю',
        _PeriodFilter.month => 'За месяц',
        _PeriodFilter.quarter => 'За квартал',
        _PeriodFilter.all => 'За все время',
      };
}

// ============================================================================
// ReportScreen
// ============================================================================
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  _PeriodFilter? _period;
  DateTimeRange? _dateRange;
  int _selectedIcon = 0; // 0 = ruble (финансы), 1 = clients, 2 = fish

  // ---------- календарь ----------
  Future<void> _openCalendar() async {
    final res = await _showRangeCalendarPicker(context, _dateRange);
    if (!mounted || res == null) return;
    if (res.start.year == 2000 && res.end.year == 2000) {
      setState(() => _dateRange = null);
    } else {
      setState(() => _dateRange = res);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _paper,
      child: Column(
        children: [
          // ── Заголовок (меняется по вкладке) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Center(
              child: Text(
                switch (_selectedIcon) {
                  1 => 'Статистика клиентов',
                  2 => 'Статистика улова рыбы',
                  _ => 'Финансы и метрики',
                },
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _ink),
              ),
            ),
          ),

          // ── Фильтры (пропорции как в чеках: padding 18, gap 8) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Row(
              children: [
                // Период (dropdown) — Expanded, как в чеках
                Expanded(
                  child: _FilterDropdown<_PeriodFilter>(
                    value: _period,
                    label: 'Период',
                    items: [
                      _FilterDropdownItem<_PeriodFilter>(
                        value: null,
                        label: 'Нет',
                        isReset: true,
                        enabled: _period != null,
                      ),
                      for (final p in _PeriodFilter.values)
                        _FilterDropdownItem<_PeriodFilter>(
                          value: p,
                          label: p.label,
                        ),
                    ],
                    onChanged: (v) => setState(() => _period = v),
                  ),
                ),
                const SizedBox(width: 8),

                // Календарь — 44×44, как в чеках
                _CalendarChip(
                  active: _dateRange != null,
                  onTap: _openCalendar,
                ),

                // 3 иконки — тот же стиль 44×44, что и календарь
                const SizedBox(width: 8),
                _IconSlot(
                  assetPath: 'assets/icons/ruble.png',
                  active: _selectedIcon == 0,
                  onTap: () => setState(() =>
                      _selectedIcon = _selectedIcon == 0 ? -1 : 0),
                ),
                const SizedBox(width: 8),
                _IconSlot(
                  assetPath: 'assets/icons/clients.png',
                  active: _selectedIcon == 1,
                  onTap: () => setState(() =>
                      _selectedIcon = _selectedIcon == 1 ? -1 : 1),
                ),
                const SizedBox(width: 8),
                _IconSlot(
                  assetPath: 'assets/icons/fish.png',
                  active: _selectedIcon == 2,
                  onTap: () => setState(() =>
                      _selectedIcon = _selectedIcon == 2 ? -1 : 2),
                ),
              ],
            ),
          ),

          // ── Контент ──
          Expanded(
            child: switch (_selectedIcon) {
              2 => const _FishStatsContent(),
              _ => const Center(
                    child: Text('Раздел в разработке',
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFF9C9484))),
                  ),
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _FishStatsContent — контент вкладки «Статистика улова рыбы»
// ============================================================================
class _FishStatsContent extends StatelessWidget {
  const _FishStatsContent();

  static const _speciesImageHeight = <String, double>{
    'Осётр': 23,
    'Амур': 21,
    'Форель': 19,
    'Карп': 19,
  };
  static const _defaultImageHeight = 17.0;

  // Градиент выручки: бледно-оранжевый (мин) → зелёный (макс)
  static const _revenueMin = Color(0xFFFBE8D0); // бледно-оранжевый
  static const _revenueMax = Color(0xFFD4EDDA); // зелёный

  Color _revenueColor(double value, double min, double max) {
    if (max <= min) return _revenueMin;
    final t = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return Color.lerp(_revenueMin, _revenueMax, t)!;
  }

  @override
  Widget build(BuildContext context) {
    final stats = kDemoFishStats;
    final revenues = stats.map((s) => s.revenue).toList();
    final minRev = revenues.reduce((a, b) => a < b ? a : b);
    final maxRev = revenues.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Column(
        children: [
          // ── Шапка таблицы ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEE4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Тип рыбы',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Color(0xFF8C8576)))),
                Expanded(flex: 2, child: Text('Вылов\n(шт.)', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Color(0xFF8C8576)))),
                Expanded(flex: 2, child: Text('Вес (кг.)', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Color(0xFF8C8576)))),
                Expanded(flex: 3, child: Text('Выручка\n(₽)', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Color(0xFF8C8576)))),
                Expanded(flex: 2, child: Text('Остаток\n(шт.)', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Color(0xFF8C8576)))),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── Строки ──
          for (final s in stats) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF6EC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEFE8D8)),
              ),
              child: Row(
                children: [
                  // 1. Тип рыбы: изображение + название под ним
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          s.imageAsset,
                          height: _speciesImageHeight[s.species]
                              ?? _defaultImageHeight,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        Text(s.species,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: Color(0xFF14130F))),
                      ],
                    ),
                  ),
                  // 2. Вылов (шт.)
                  Expanded(
                    flex: 2,
                    child: Text(_formatNum(s.count), textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF14130F))),
                  ),
                  // 3. Ср. Вес
                  Expanded(
                    flex: 2,
                    child: Text(s.avgWeight.toStringAsFixed(1),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF14130F))),
                  ),
                  // 4. Выручка (₽) — градиентный фон
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: _revenueColor(
                            s.revenue, minRev, maxRev),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatRevenue(s.revenue),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: Color(0xFF14130F)),
                      ),
                    ),
                  ),
                  // 5. Остаток (шт.) — красный если < 50
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatNum(s.remaining),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: s.remaining < 50
                            ? FontWeight.w700 : FontWeight.w400,
                        color: s.remaining < 50
                            ? const Color(0xFFC9302C)
                            : const Color(0xFF14130F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],

          const SizedBox(height: 18),

          // ── Таблица 2: Доля в выручке + Маржинальность ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEE4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Тип рыбы',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Color(0xFF8C8576)))),
                Expanded(flex: 3, child: Text('Доля в выручке', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Color(0xFF8C8576)))),
                Expanded(flex: 3, child: Text('Маржа', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Color(0xFF8C8576)))),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── Строки таблицы 2 ──
          Builder(
            builder: (context) {
              final totalRev = stats.fold<double>(0, (s, e) => s + e.revenue);

              return Column(
                children: [
                  for (final s in stats) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF6EC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFEFE8D8)),
                      ),
                      child: Row(
                        children: [
                          // 1. Тип рыбы
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  s.imageAsset,
                                  height: _speciesImageHeight[s.species]
                                      ?? _defaultImageHeight,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 4),
                                Text(s.species,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF14130F))),
                              ],
                            ),
                          ),
                          // 2. Доля в выручке + мини-шкала
                          Expanded(
                            flex: 3,
                            child: _PercentCell(
                              pct: (s.revenue / totalRev * 100).round(),
                              barColor: const Color(0xFFE8912B),
                            ),
                          ),
                          // 3. Маржинальность + мини-шкала
                          Expanded(
                            flex: 3,
                            child: _PercentCell(
                              pct: s.marginPct.round(),
                              barColor: const Color(0xFF3FA66B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatNum(int v) {
    if (v >= 1000000) {
      final m = v / 1000000;
      final r = (m * 10).round() / 10.0;
      return '${r.toStringAsFixed(1).replaceAll('.', ',')} млн';
    }
    if (v > 999) {
      return '${(v / 1000).round()} тыс.';
    }
    return '$v';
  }

  String _formatRevenue(double v) {
    final rounded = v.round();
    if (rounded >= 1000000) {
      final m = rounded / 1000000.0;
      final r = (m * 10).round() / 10.0;
      return '${r.toStringAsFixed(1).replaceAll('.', ',')} млн ₽';
    }
    if (rounded > 999) {
      return '${(rounded / 1000).round()} тыс. ₽';
    }
    final s = rounded.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} ₽';
  }
}

// ============================================================================
// _IconSlot — иконка-кнопка 44×44 (аналог _CalendarChip, без индикатора)
// ============================================================================
class _PercentCell extends StatelessWidget {
  final int pct;
  final Color barColor;

  const _PercentCell({
    required this.pct,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$pct%',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF14130F))),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFEFE8D8),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct / 100.0,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconSlot extends StatelessWidget {
  final IconData? icon;
  final String? assetPath;
  final bool active;
  final VoidCallback onTap;

  const _IconSlot({
    this.icon,
    this.assetPath,
    required this.active,
    required this.onTap,
  }) : assert(icon != null || assetPath != null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? _orange : _fill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: assetPath != null
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(assetPath!,
                    color: active ? Colors.white : _ink,
                    fit: BoxFit.contain),
              )
            : Icon(icon,
                size: 19, color: active ? Colors.white : _ink),
      ),
    );
  }
}

// ============================================================================
// _FilterDropdown — точная копия из checks_screen.dart
// ============================================================================
// _FilterDropdown — OverlayEntry-based dropdown (как AppDropdownField)
// ============================================================================
class _FilterDropdownItem<T> {
  final T? value;
  final String label;
  final bool isReset;
  final bool enabled;
  const _FilterDropdownItem({
    required this.value,
    required this.label,
    this.isReset = false,
    this.enabled = true,
  });
}

class _FilterDropdown<T> extends StatefulWidget {
  final T? value;
  final String label;
  final List<_FilterDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_FilterDropdown<T>> createState() => _FilterDropdownState<T>();
}

class _FilterDropdownState<T> extends State<_FilterDropdown<T>> {
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

    _entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _close(),
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            // Ноль зазора — список приклеен к полю
            offset: Offset(0, size.height),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: size.width,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: BoxDecoration(
                    color: _fill,
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
                      final selected = item.value == widget.value &&
                          item.value != null;
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
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          color: selected
                              ? _selected
                              : Colors.transparent,
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
                                    ? (item.isReset ? _muted2 : _ink)
                                    : _muted,
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
    // Когда меню открыто — срезаем нижние углы поля
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(_borderRadius),
      topRight: const Radius.circular(_borderRadius),
      bottomLeft: Radius.circular(_open ? 0 : _borderRadius),
      bottomRight: Radius.circular(_open ? 0 : _borderRadius),
    );

    // Определяем текущий лейбл
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
            decoration: BoxDecoration(color: _fill, borderRadius: radius),
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
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? _ink : _muted2,
                    ),
                  ),
                ),
                Icon(
                  _open
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: _muted2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _CalendarChip — точная копия из checks_screen.dart
// ============================================================================
class _CalendarChip extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _CalendarChip({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: _fill, borderRadius: BorderRadius.circular(12)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 19, color: active ? _orange : _ink),
            if (active)
              const Positioned(
                top: 7,
                right: 7,
                child: SizedBox(
                  width: 7,
                  height: 7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: _orange, shape: BoxShape.circle),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _RangeCalendarPicker + _showRangeCalendarPicker — точная копия
// ============================================================================
Future<DateTimeRange?> _showRangeCalendarPicker(
    BuildContext context, DateTimeRange? initial) {
  return showDialog<DateTimeRange>(
    context: context,
    barrierColor: const Color(0x7314130F),
    builder: (_) => _RangeCalendarPicker(initial: initial),
  );
}

class _RangeCalendarPicker extends StatefulWidget {
  final DateTimeRange? initial;
  const _RangeCalendarPicker({this.initial});
  @override
  State<_RangeCalendarPicker> createState() => _RangeCalendarPickerState();
}

class _RangeCalendarPickerState extends State<_RangeCalendarPicker> {
  late DateTime cursor = DateTime(
      (widget.initial?.start ?? DateTime.now()).year,
      (widget.initial?.start ?? DateTime.now()).month,
      1);
  DateTime? start;
  DateTime? end;
  bool _wasReset = false;

  @override
  void initState() {
    super.initState();
    start = widget.initial?.start;
    end = widget.initial?.end;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _pick(DateTime d) {
    setState(() {
      if (start == null || (start != null && end != null)) {
        start = d;
        end = null;
      } else if (_sameDay(d, start!)) {
        end = null;
      } else if (d.isBefore(start!)) {
        end = start;
        start = d;
      } else {
        end = d;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday =
        (DateTime(cursor.year, cursor.month, 1).weekday - 1) % 7;
    final daysInMonth =
        DateTime(cursor.year, cursor.month + 1, 0).day;
    final cells = <int?>[
      ...List<int?>.filled(firstWeekday, null),
      ...List.generate(daysInMonth, (i) => i + 1),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_wasReset) {
          Navigator.pop(context,
              DateTimeRange(start: DateTime(2000), end: DateTime(2000)));
        } else {
          Navigator.pop(context);
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x4D000000),
                  blurRadius: 50,
                  offset: Offset(0, 20)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navButton(Icons.chevron_left, () => setState(() {
                        cursor =
                            DateTime(cursor.year, cursor.month - 1, 1);
                      })),
                  Text(
                      '${_monthsFull[cursor.month - 1]} ${cursor.year}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: _ink)),
                  _navButton(Icons.chevron_right, () => setState(() {
                        cursor =
                            DateTime(cursor.year, cursor.month + 1, 1);
                      })),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: _weekdaysShort
                    .map((w) => Expanded(
                        child: Center(
                            child: Text(w,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _muted2)))))
                    .toList(),
              ),
              const SizedBox(height: 6),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1,
                children: cells.map((d) {
                  if (d == null) return const SizedBox.shrink();
                  final date = DateTime(cursor.year, cursor.month, d);
                  final isStart =
                      start != null && _sameDay(date, start!);
                  final isEnd = end != null && _sameDay(date, end!);
                  final inRange = start != null &&
                      end != null &&
                      date.isAfter(start!) &&
                      date.isBefore(end!);
                  return GestureDetector(
                    onTap: () => _pick(date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: inRange
                            ? _selected.withOpacity(0.55)
                            : Colors.transparent,
                        borderRadius: BorderRadius.horizontal(
                          left: isStart
                              ? const Radius.circular(16)
                              : Radius.zero,
                          right: isEnd
                              ? const Radius.circular(16)
                              : Radius.zero,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: (isStart || isEnd)
                              ? _orange
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text('$d',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: (isStart || isEnd)
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: (isStart || isEnd)
                                  ? Colors.white
                                  : _ink,
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Text(
                start == null
                    ? 'Выберите дату'
                    : end == null
                        ? '${_fmtDateShort(start!)} · выберите вторую дату'
                        : '${_fmtDateShort(start!)} — ${_fmtDateShort(end!)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: _muted2),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        start = null;
                        end = null;
                        _wasReset = true;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _muted,
                      side: const BorderSide(color: _outline),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Сбросить',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: start == null
                        ? null
                        : () => Navigator.pop(
                            context,
                            DateTimeRange(
                                start: start!, end: end ?? start!)),
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _hairline,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Применить',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _hairline),
          ),
          child: Icon(icon, size: 15, color: _ink),
        ),
      );
}

String _fmtDateShort(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}';
}

// ─── Константы для календаря ────────────────────────────────────────────────
const _monthsFull = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];
const _weekdaysShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
