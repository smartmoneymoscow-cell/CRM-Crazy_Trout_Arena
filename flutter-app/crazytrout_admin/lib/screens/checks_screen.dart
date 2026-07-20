import 'package:flutter/material.dart';
import '../data/demo_receipts.dart';
import '../models/client.dart';
import '../models/receipt_history.dart';
import '../services/print_route.dart' deferred as print_route;
import '../models/receipt.dart' as receipt_model;
import '../data/filter_types.dart';
import '../theme/app_theme.dart';
import '../data/pond_stats.dart';
import '../widgets/filter_dropdown.dart';

class ChecksScreen extends StatefulWidget {
  const ChecksScreen({super.key});

  @override
  State<ChecksScreen> createState() => _ChecksScreenState();
}

class _ChecksScreenState extends State<ChecksScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  PeriodFilter? _period;
  TypeFilter? _type;
  DateTimeRange? _dateRange;

  // ── Расширенные фильтры (диалог) ──
  Set<String> _filterTariffs = {};    // 'Стандарт', 'Гостевой', 'Пенсионер'
  Set<String> _filterPayments = {};   // 'Наличными', 'Картой', 'Счет заведения'
  bool _filterFirstTime = false;

  // ── Сортировка ──
  bool _sortDesc = true;              // true = по убыванию
  String _sortField = 'date';         // date, total, visits, ltv, fish

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------- фильтрация ----------
  bool _matchesQuery(ReceiptHistoryItem r) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    if (!r.isGuest && r.client != null) {
      if (r.client!.name.toLowerCase().contains(q)) return true;
      if (r.client!.phone
          .replaceAll(RegExp(r'\s|-|\(|\)'), '')
          .contains(q.replaceAll(RegExp(r'\s|-|\(|\)'), ''))) {
        return true;
      }
    }
    if (r.total.round().toString().contains(q)) return true;
    final d = r.date;
    two(int n) => n.toString().padLeft(2, '0');
    final dateStr = '${two(d.day)}.${two(d.month)}.${d.year}';
    if (dateStr.contains(q)) return true;
    return false;
  }

  bool _matchesPeriod(ReceiptHistoryItem r) {
    if (_period == null || _period == PeriodFilter.all) return true;
    final now = DateTime.now();
    final start = switch (_period!) {
      PeriodFilter.today => DateTime(now.year, now.month, now.day),
      PeriodFilter.week => now.subtract(const Duration(days: 7)),
      PeriodFilter.month => now.subtract(const Duration(days: 30)),
      PeriodFilter.quarter => now.subtract(const Duration(days: 90)),
      PeriodFilter.all => DateTime(0),
    };
    return r.date.isAfter(start) || r.date.isAtSameMomentAs(start);
  }

  bool _matchesRange(ReceiptHistoryItem r) {
    if (_dateRange == null) return true;
    final d = DateTime(r.date.year, r.date.month, r.date.day);
    final s = DateTime(
        _dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
    final e = DateTime(
        _dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  bool _matchesType(ReceiptHistoryItem r) {
    if (_type == null) return true;
    return _type == TypeFilter.fiscal ? r.fiscal : !r.fiscal;
  }

  bool _matchesAdvancedFilters(ReceiptHistoryItem r) {
    // Тариф
    if (_filterTariffs.isNotEmpty && !_filterTariffs.contains(r.tariffLabel)) return false;
    // Способ оплаты
    if (_filterPayments.isNotEmpty && !_filterPayments.contains(r.paymentLabel)) return false;
    // Первый раз на пруду
    if (_filterFirstTime && !r.isGuest) {
      final stats = r.client != null ? kPondStatsById[r.client!.id] : null;
      if (stats == null || stats.visits > 1) return false;
    }
    return true;
  }

  bool get _hasAdvancedFilters =>
      _filterTariffs.isNotEmpty || _filterPayments.isNotEmpty || _filterFirstTime;

  List<ReceiptHistoryItem> get _filtered {
    final list = kDemoReceipts
        .where((r) =>
            _matchesQuery(r) &&
            _matchesPeriod(r) &&
            _matchesRange(r) &&
            _matchesType(r) &&
            _matchesAdvancedFilters(r))
        .toList();

    // Сортировка
    int Function(ReceiptHistoryItem, ReceiptHistoryItem) cmp;
    switch (_sortField) {
      case 'total':
        cmp = (a, b) => a.total.compareTo(b.total);
        break;
      case 'visits':
        cmp = (a, b) {
          final av = a.client != null ? (kPondStatsById[a.client!.id]?.visits ?? 0) : 0;
          final bv = b.client != null ? (kPondStatsById[b.client!.id]?.visits ?? 0) : 0;
          return av.compareTo(bv);
        };
        break;
      case 'ltv':
        cmp = (a, b) {
          final av = a.client != null ? (kPondStatsById[a.client!.id]?.ltvK ?? 0) : 0;
          final bv = b.client != null ? (kPondStatsById[b.client!.id]?.ltvK ?? 0) : 0;
          return av.compareTo(bv);
        };
        break;
      case 'fish':
        cmp = (a, b) => a.rows.length.compareTo(b.rows.length);
        break;
      default: // date
        cmp = (a, b) => a.date.compareTo(b.date);
    }
    list.sort(_sortDesc ? (a, b) => cmp(b, a) : cmp);
    return list;
  }

  // ---------- поисковые подсказки клиентов ----------
  List<Client> get _clientSuggestions {
    if (_query.isEmpty) return const [];
    final q = _query.toLowerCase();
    final seen = <int>{};
    final res = <Client>[];
    for (final r in kDemoReceipts) {
      final c = r.client;
      if (c == null || seen.contains(c.id)) continue;
      if (c.name.toLowerCase().contains(q) || c.phone.contains(q)) {
        seen.add(c.id);
        res.add(c);
      }
    }
    // Сортировка: имя начинается с запроса → выше, потом по алфавиту.
    // Перенесено из receipt_screen.dart (правильная логика).
    res.sort((a, b) {
      final an = a.name.toLowerCase();
      final bn = b.name.toLowerCase();
      final aStarts = an.startsWith(q) ? 0 : 1;
      final bStarts = bn.startsWith(q) ? 0 : 1;
      if (aStarts != bStarts) return aStarts - bStarts;
      return an.compareTo(bn);
    });
    return res.take(4).toList();
  }

  // ---------- открытия ----------
  // ---------- Диалог фильтров (центр экрана) ----------
  void _showFilterDialog() {
    // Локальные копии для редактирования
    Set<String> tmpTariffs = Set.from(_filterTariffs);
    Set<String> tmpPayments = Set.from(_filterPayments);
    bool tmpFirstTime = _filterFirstTime;
    TypeFilter? tmpType = _type;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: kPaper,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text('Фильтры',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk))),
                  const SizedBox(height: 20),

                  // ── Тип чека ──
                  _filterSectionTitle('Тип чека'),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _filterChip('С ФН', tmpType == TypeFilter.fiscal, () {
                      setDialogState(() => tmpType = tmpType == TypeFilter.fiscal ? null : TypeFilter.fiscal);
                    }),
                    _filterChip('Без ФН', tmpType == TypeFilter.nonfiscal, () {
                      setDialogState(() => tmpType = tmpType == TypeFilter.nonfiscal ? null : TypeFilter.nonfiscal);
                    }),
                  ]),
                  const SizedBox(height: 16),

                  // ── Тариф ──
                  _filterSectionTitle('Тариф'),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final t in ['Стандарт', 'Гостевой', 'Пенсионер'])
                      _filterChip(t, tmpTariffs.contains(t), () {
                        setDialogState(() {
                          tmpTariffs.contains(t) ? tmpTariffs.remove(t) : tmpTariffs.add(t);
                        });
                      }),
                  ]),
                  const SizedBox(height: 16),

                  // ── Способ оплаты ──
                  _filterSectionTitle('Способ оплаты'),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final p in ['Наличными', 'Картой', 'Счет заведения'])
                      _filterChip(p, tmpPayments.contains(p), () {
                        setDialogState(() {
                          tmpPayments.contains(p) ? tmpPayments.remove(p) : tmpPayments.add(p);
                        });
                      }),
                  ]),
                  const SizedBox(height: 16),

                  // ── Первый раз на пруду ──
                  GestureDetector(
                    onTap: () => setDialogState(() => tmpFirstTime = !tmpFirstTime),
                    behavior: HitTestBehavior.opaque,
                    child: Row(children: [
                      SizedBox(width: 24, height: 24, child: Checkbox(
                        value: tmpFirstTime,
                        onChanged: (v) => setDialogState(() => tmpFirstTime = v ?? false),
                        activeColor: kOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      )),
                      const SizedBox(width: 10),
                      const Text('Первый раз на пруду',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kInk)),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Кнопки ──
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () {
                        setDialogState(() {
                          tmpTariffs = {};
                          tmpPayments = {};
                          tmpFirstTime = false;
                          tmpType = null;
                        });
                        setState(() {
                          _filterTariffs = {};
                          _filterPayments = {};
                          _filterFirstTime = false;
                          _type = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kMuted,
                        side: const BorderSide(color: kOutline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('Сбросить'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _filterTariffs = tmpTariffs;
                          _filterPayments = tmpPayments;
                          _filterFirstTime = tmpFirstTime;
                          _type = tmpType;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('Применить'),
                    )),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterSectionTitle(String text) => Text(text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted));

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? kSelected : kFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? kOrange : kHairline2, width: selected ? 1.5 : 0.5),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? kInk : kMuted,
        )),
      ),
    );
  }

  // ---------- Dropdown сортировки ----------
  // Sort is now handled by _SortChip widget (overlay-based)

  Future<void> _openCalendar() async {
    final res = await _showRangeCalendarPicker(context, _dateRange);
    if (!mounted || res == null) return;
    // DateTimeRange(2000,2000) — маркер «Сбросить»
    if (res.start.year == 2000 && res.end.year == 2000) {
      setState(() => _dateRange = null);
    } else {
      setState(() { _dateRange = res; _period = null; });
    }
  }

  void _openDetail(ReceiptHistoryItem r) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _ChecksDetailScreen(receipt: r)),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final clientHits = _clientSuggestions;

    return Container(
      color: kPaper,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Center(
              child: Text('Чеки',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, color: kInk)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Column(
              children: [
                _SearchField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                if (clientHits.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ClientSuggestions(
                    clients: clientHits,
                    onPick: (c) {
                      setState(() {
                        _searchCtrl.text = c.name;
                        _query = c.name;
                      });
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilterDropdown<PeriodFilter>(
                        value: _period,
                        label: 'Период',
                        active: _period != null,
                        items: [
                          FilterDropdownItem<PeriodFilter>(
                            value: null,
                            label: 'Нет',
                            isReset: true,
                            enabled: true,
                          ),
                          for (final p in PeriodFilter.values)
                            FilterDropdownItem<PeriodFilter>(
                              value: p,
                              label: p.label,
                            ),
                        ],
                        onChanged: (v) => setState(() { _period = v; _dateRange = null; }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CalendarChip(
                      active: _dateRange != null,
                      onTap: _openCalendar,
                    ),
                    const SizedBox(width: 8),
                    _FiscalFilterChip(
                      type: _type,
                      hasAdvanced: _hasAdvancedFilters,
                      onTap: _showFilterDialog,
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      active: _sortField != 'date' || !_sortDesc,
                      sortField: _sortField,
                      sortDesc: _sortDesc,
                      onFieldChanged: (v) => setState(() => _sortField = v),
                      onDescChanged: (v) => setState(() => _sortDesc = v),
                    ),
                  ],
                ),

            ],
          ),
          ),
          Expanded(
            child: items.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ReceiptRow(
                      item: items[i],
                      onTap: () => _openDetail(items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Widgets — список
// ============================================================================1
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: kFill, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: kMuted2),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: kOrange,
              style: const TextStyle(fontSize: 14.5, color: kInk),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Имя, сумма, телефон, дата',
                hintStyle: TextStyle(color: kMuted2, fontSize: 14.5),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(Icons.close, size: 18, color: kMuted2),
            ),
        ],
      ),
    );
  }
}

class _ClientSuggestions extends StatelessWidget {
  final List<Client> clients;
  final ValueChanged<Client> onPick;
  const _ClientSuggestions({required this.clients, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kHairline),
      ),
      child: Column(
        children: [
          for (int i = 0; i < clients.length; i++) ...[
            InkWell(
              onTap: () => onPick(clients[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    _Avatar(client: clients[i], size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clients[i].name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: kInk)),
                          const SizedBox(height: 2),
                          Text(clients[i].phone,
                              style: const TextStyle(
                                  fontSize: 12, color: kMuted2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < clients.length - 1)
              const Divider(height: 1, color: kHairline2),
          ],
        ],
      ),
    );
  }
}

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
            color: kFill, borderRadius: BorderRadius.circular(12)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 19, color: active ? kOrange : kInk),
            if (active)
              const Positioned(
                top: 7,
                right: 7,
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
      ),
    );
  }
}

class _FiscalFilterChip extends StatelessWidget {
  final TypeFilter? type;
  final bool hasAdvanced;
  final VoidCallback onTap;
  const _FiscalFilterChip({required this.type, required this.hasAdvanced, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = type != null || hasAdvanced;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: kFill, borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                alignment: Alignment.center,
                child: Icon(Icons.receipt_long_outlined,
                    size: 19, color: active ? kOrange : kInk),
              ),
            ),
            if (active)
              const Positioned(
                top: 7,
                right: 7,
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
      ),
    );
  }
}

class _SortChip extends StatefulWidget {
  final bool active;
  final String sortField;
  final bool sortDesc;
  final ValueChanged<String> onFieldChanged;
  final ValueChanged<bool> onDescChanged;
  const _SortChip({
    required this.active,
    required this.sortField,
    required this.sortDesc,
    required this.onFieldChanged,
    required this.onDescChanged,
  });

  @override
  State<_SortChip> createState() => _SortChipState();
}

class _SortChipState extends State<_SortChip> {
  final GlobalKey _fieldKey = GlobalKey();
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  bool _open = false;
  late String _tmpField;
  late bool _tmpDesc;

  static const _sortLabels = {
    'date': 'По дате',
    'total': 'По сумме чека',
    'visits': 'По числу посещений',
    'ltv': 'По LTV',
    'fish': 'По кол-ву пойманной рыбы',
  };

  @override
  void initState() {
    super.initState();
    _tmpField = widget.sortField;
    _tmpDesc = widget.sortDesc;
  }

  @override
  void dispose() {
    _entry = null;
    super.dispose();
  }

  void _toggle() => _open ? _close() : _show();

  void _show() {
    _tmpField = widget.sortField;
    _tmpDesc = widget.sortDesc;
    final box = _fieldKey.currentContext!.findRenderObject() as RenderBox;
    final size = box.size;

    // Сдвигаем dropdown влево если он обрезается правым краем экрана.
    const dropdownW = 220.0;
    final btnGlobal = box.localToGlobal(Offset.zero);
    final screenW = MediaQuery.of(context).size.width;
    final overflow = (btnGlobal.dx + dropdownW) - screenW + 8;
    final dx = overflow > 0 ? -overflow : 0.0;

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
            offset: Offset(dx, size.height + 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 220,
                decoration: BoxDecoration(
                  color: kPaper,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 6)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: StatefulBuilder(
                  builder: (ctx, setOverlayState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Порядок', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted)),
                        ),
                      ),
                      _radioTile('desc', 'По убыванию', _tmpDesc, setOverlayState),
                      _radioTile('asc', 'По возрастанию', !_tmpDesc, setOverlayState),
                      const Divider(height: 1, color: kHairline2),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Сортировать по', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted)),
                        ),
                      ),
                      for (final e in _sortLabels.entries)
                        _fieldTile(e.key, e.value, _tmpField == e.key, setOverlayState),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        child: Column(children: [
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () {
                                widget.onFieldChanged(_tmpField);
                                widget.onDescChanged(_tmpDesc);
                                _close();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('Применить', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: OutlinedButton(
                              onPressed: () {
                                setOverlayState(() {
                                  _tmpField = 'date';
                                  _tmpDesc = true;
                                });
                                widget.onFieldChanged('date');
                                widget.onDescChanged(true);
                                _close();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kMuted,
                                side: const BorderSide(color: kHairline2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Сбросить', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 8),
                    ],
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

  Widget _radioTile(String value, String label, bool selected, StateSetter setOverlayState) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setOverlayState(() => _tmpDesc = value == 'desc'),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18, color: selected ? kOrange : kMuted2),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? kInk : kMuted,
          )),
        ]),
      ),
    );
  }

  Widget _fieldTile(String value, String label, bool selected, StateSetter setOverlayState) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setOverlayState(() => _tmpField = value),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18, color: selected ? kOrange : kMuted2),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? kInk : kMuted,
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        key: _fieldKey,
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: kFill, borderRadius: BorderRadius.circular(12)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.sort_rounded, size: 19, color: kInk),
              if (widget.active)
                const Positioned(
                  top: 7,
                  right: 7,
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
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final ReceiptHistoryItem item;
  final VoidCallback onTap;
  const _ReceiptRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kHairline2)),
        ),
        child: Row(
          children: [
            _Avatar(
                client: item.client, guest: item.isGuest, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: kInk),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtDateTime(item.date),
                    style: const TextStyle(
                        fontSize: 12.5, color: kMuted2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '+${_money(item.total)} ₽',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3FA66B)),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              height: 22,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.fiscal ? const Color(0xFFE8D5B5) : kHairline,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.fiscal ? 'С ФН' : 'Без ФН',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: item.fiscal ? kInk : kMuted2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'Нет чеков по заданным условиям',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: kMuted2),
          ),
        ),
      );
}

class _Avatar extends StatelessWidget {
  final Client? client;
  final bool guest;
  final double size;
  const _Avatar({this.client, this.guest = false, required this.size});

  @override
  Widget build(BuildContext context) {
    if (guest || client == null) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            color: Color(0xFFF1ECE0), shape: BoxShape.circle),
        child: const Icon(Icons.person_outline, color: kMuted2, size: 22),
      );
    }
    final c = client!;
    if (c.avatarAsset != null) {
      return ClipOval(
        child: Image.asset(c.avatarAsset!,
            width: size, height: size, fit: BoxFit.cover),
      );
    }
    final colors = [
      const Color(0xFFE8912B),
      const Color(0xFF6A8CBB),
      const Color(0xFF7BAE7F),
      const Color(0xFFC97A7A),
    ];
    final color = colors[c.id % colors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        c.initials.toUpperCase(),
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.36),
      ),
    );
  }
}

// ============================================================================
// Экран деталей чека
// ============================================================================
class _ChecksDetailScreen extends StatelessWidget {
  final ReceiptHistoryItem receipt;
  const _ChecksDetailScreen({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPaper,
      appBar: AppBar(
        backgroundColor: kPaper,
        surfaceTintColor: kPaper,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, size: 20, color: kInk),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Чек',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kInk)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          children: [
            _ReceiptCard(receipt: receipt),
            const SizedBox(height: 16),
            _ClientPill(
              client: receipt.client,
              isGuest: receipt.isGuest,
              onTap: () {
                if (receipt.client != null) {
                  final fullClient =
                      findFullClient(receipt.client!.id);
                  if (fullClient != null) {
                    // Полная карточка клиента из карты пруда
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.5),
                      builder: (_) =>
                          _ClientCard(client: fullClient),
                    );
                  } else {
                    // Фолбэк — упрощённая карточка
                    showDialog(
                      context: context,
                      barrierColor: Colors.black54,
                      builder: (_) => _ClientProfileFallback(
                          client: receipt.client!),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: kInk,
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: kOutline),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Печать через AirPrint',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              onPressed: () async {
                await print_route.loadLibrary();
                final r = receipt_model.Receipt(
                  number: receipt.number,
                  date: receipt.date,
                  client: receipt.client,
                  isGuest: receipt.isGuest,
                  tariffLabel: receipt.tariffLabel,
                  tariffPrice: receipt.tariffPrice,
                  rows: receipt.rows
                      .map((r) => receipt_model.ReceiptRow(
                          name: r.name,
                          weight: r.weight,
                          price: r.price,
                          sum: r.sum))
                      .toList(),
                  total: receipt.total,
                  payment: receipt.paymentLabel == 'Наличными'
                      ? receipt_model.PaymentMethod.cash
                      : receipt_model.PaymentMethod.card,
                  fiscal: receipt.fiscal,
                  fiscalDoc: receipt.fiscalDoc,
                );
                await print_route.printViaSystemDialog(r);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Превью чека
// ============================================================================
class _ReceiptCard extends StatelessWidget {
  final ReceiptHistoryItem receipt;
  const _ReceiptCard({required this.receipt});
  @override
  Widget build(BuildContext context) {
    final r = receipt;
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kHairline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('CRAZY TROUT ARENA',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: kInk)),
          Text(
            r.fiscal ? 'КАССОВЫЙ ЧЕК (Приход)' : 'ЧЕК (без ФН)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: kMuted2),
          ),
          const _CardDivider(),
          _small('Продавец: ИП Сидоров А.В.'),
          _small('ИНН: 770123456789'),
          _small('Адрес: г. Москва, ул. Рыбацкая, д. 12'),
          _small('Дата: ${_fmtDateTime(r.date)}  Чек №${r.number}  Смена №1'),
          _small('СНО: УСН доходы'),
          const _CardDivider(),
          _row('Клиент', r.displayName),
          _row('Телефон', r.client?.phone ?? '—'),
          const _CardDivider(),
          _row('Тариф · ${r.tariffLabel}',
              '${_money(r.tariffPrice)} ₽'),
          for (final it in r.rows)
            _row(
                '${it.name} ${it.weight.toStringAsFixed(2)}кг × ${it.price.round()}',
                '${_money(it.sum)} ₽'),
          const _CardDivider(),
          _row('ИТОГО', '${_money(r.total)} ₽', bigTotal: true),
          _small('НДС не облагается'),
          _row('Оплата', r.paymentLabel),
          const _CardDivider(),
          if (r.fiscal) ...[
            _small('ККТ: 0001234567001234'),
            _small('ФН: 9999078900001234'),
            _small('ФД №: ${r.fiscalDoc?.replaceAll('#', '') ?? '—'}'),
            _small('Проверка: nalog.ru'),
          ] else
            _small('Чек без фискального накопителя'),
        ],
      ),
    );
  }

  Widget _small(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(text, style: const TextStyle(fontSize: 11, color: kMuted2)),
      );

  Widget _row(String l, String v, {bool bigTotal = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(l,
                  style: TextStyle(
                    fontSize: bigTotal ? 17 : 13.5,
                    color: kInk,
                    fontWeight: bigTotal
                        ? FontWeight.w700
                        : FontWeight.w400,
                  )),
            ),
            const SizedBox(width: 12),
            Text(v,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: bigTotal ? 19 : 13.5,
                  color: kInk,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      );
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();
  @override
  Widget build(BuildContext context) => Container(
      height: 1,
      color: kHairline2,
      margin: const EdgeInsets.symmetric(vertical: 12));
}

// ============================================================================
// Карточка клиента (pill в деталях чека)
// ============================================================================
class _ClientPill extends StatelessWidget {
  final Client? client;
  final bool isGuest;
  final VoidCallback onTap;
  const _ClientPill(
      {required this.client,
      required this.isGuest,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isGuest || client == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: kFill,
            borderRadius: BorderRadius.circular(14)),
        child: const Text('Гость (без анкеты)',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted2, fontSize: 13)),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: kFill,
            borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            _Avatar(client: client, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                  const SizedBox(height: 1),
                  Text(
                      '${client!.phone} · ${client!.tariffLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: kMuted2)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: kMuted2, size: 22),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Полная карточка клиента (перенесена 1-в-1 из карты пруда)
// ============================================================================
class _ClientCard extends StatelessWidget {
  final FullClient client;
  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final l = kLevelStyles[client.level]!;
    final initials = client.name
        .split(' ')
        .map((p) => p.isEmpty ? '' : p[0])
        .take(2)
        .join();
    final pct =
        ((client.points / client.pointsNext) * 100).clamp(0, 100).round();

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: kPaper,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 60,
                offset: const Offset(0, 24))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Container(
                  padding:
                      const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [l.color, kInk],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          client.avatarAsset != null
                              ? ClipOval(
                                  child: Image.asset(
                                    client.avatarAsset!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(
                                          width: 60,
                                          height: 60,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: client.color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.5),
                                                width: 3),
                                          ),
                                          child: Text(initials,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.w800,
                                                  fontSize: 22)),
                                        ),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: client.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white
                                            .withOpacity(0.5),
                                        width: 3),
                                  ),
                                  child: Text(initials,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22)),
                                ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(client.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              _LevelBadge(level: client.level),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.white.withOpacity(0.18),
                            minimumSize: const Size(28, 28),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body ──
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _iconRow(Icons.phone_outlined,
                                    client.phone),
                                const SizedBox(height: 8),
                                _iconRow(Icons.mail_outline,
                                    client.email),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.center,
                            children: [
                              const Text('ПОСЛЕДНЕЕ ПОСЕЩЕНИЕ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black45,
                                      letterSpacing: 0.3)),
                              const SizedBox(height: 2),
                              Text(client.lastVisit,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: kInk)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Прогресс баллов
                      Container(
                        padding: const EdgeInsets.fromLTRB(
                            14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kHairline),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('БАЛЛЫ ЛОЯЛЬНОСТИ',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black54)),
                                Text(
                                    '${client.points} / ${client.pointsNext}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: l.color)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 7,
                                backgroundColor:
                                    const Color(0xFFEFE9DC),
                                valueColor:
                                    AlwaysStoppedAnimation(l.color),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Сетка статов
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.1,
                        children: [
                          _statBlock('Тариф', client.tariff),
                          _statBlock(
                              'Посещений / LTV',
                              '${client.visits} / ${formatLtv(client.ltvK)}'),
                          _statBlock('Всего поймано рыб',
                              '${client.fish} шт. / ${client.totalWeight} кг.'),
                          _statBlock(
                              'Первый визит', client.firstVisit),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Лучший улов
                      Container(
                        padding: const EdgeInsets.fromLTRB(
                            14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBEEDA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                                Icons.emoji_events_outlined,
                                color: kEmber,
                                size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text('ЛУЧШИЙ УЛОВ',
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight:
                                              FontWeight.w700,
                                          color: Colors.black54,
                                          letterSpacing: 0.3)),
                                  Text(
                                      '${client.bestCatch.species} · ${client.bestCatch.weight}',
                                      style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight:
                                              FontWeight.w700,
                                          color: kInk)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'СЕКТОР №${client.bestCatch.sector}',
                                    style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black54,
                                        letterSpacing: 0.3)),
                                Text(client.bestCatch.date,
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: kInk)),
                              ],
                            ),
                          ],
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
    );
  }

  static Widget _iconRow(IconData icon, String text) => Row(children: [
        Icon(icon, size: 15, color: kEmber),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 13, color: kInk)),
      ]);

  static Widget _statBlock(String label, String value) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kHairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label,
                textAlign: TextAlign.left,
                style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black45,
                    letterSpacing: 0.3)),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(value,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: kInk)),
            ),
          ],
        ),
      );
}

// ── LevelBadge (перенесено из карты пруда) ──────────────────────────────────
class _LevelBadge extends StatelessWidget {
  final LevelKey level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final l = kLevelStyles[level]!;
    const size = 18.0;
    final medal = _Medal(style: l, size: size);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: l.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        medal,
        const SizedBox(width: 4),
        Text(l.label,
            style: TextStyle(
                color: l.color,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _Medal extends StatelessWidget {
  final LevelStyle style;
  final double size;
  const _Medal({required this.style, required this.size});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MedalPainter(style: style)),
    );
  }
}

class _MedalPainter extends CustomPainter {
  final LevelStyle style;
  _MedalPainter({required this.style});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            radius: 0.75,
            colors: [
              style.medalTop,
              style.medalMid,
              style.medalBottom
            ],
            stops: const [0, 0.55, 1],
          ).createShader(rect));
    final tp = TextPainter(
      text: TextSpan(
          text: style.letter,
          style: TextStyle(
            color: style.letterColor,
            fontWeight: FontWeight.w800,
            fontSize: size.width * 0.52,
          )),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MedalPainter old) =>
      old.style != style;
}

// ============================================================================
// Упрощённая карточка клиента (фолбэк, если нет данных карты пруда)
// ============================================================================
class _ClientProfileFallback extends StatelessWidget {
  final Client client;
  const _ClientProfileFallback({required this.client});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kPaper,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF14130F), Color(0xFF3B342A)],
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 3),
                        ),
                        child: ClipOval(
                            child: _Avatar(
                                client: client, size: 54)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(client.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withOpacity(0.22),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                client.tariffLabel.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _contactRow(
                      Icons.phone_outlined, client.phone),
                  const SizedBox(height: 8),
                  _contactRow(Icons.card_membership_outlined,
                      'Тариф · ${client.tariffLabel}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFFC9932E)),
          const SizedBox(width: 9),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(fontSize: 13, color: kInk))),
        ],
      );
}

// ============================================================================
// Календарь периода (с range-выбором, визуально идентичен карте пруда)
// ============================================================================
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
  State<_RangeCalendarPicker> createState() =>
      _RangeCalendarPickerState();
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
          Navigator.pop(context, DateTimeRange(
              start: DateTime(2000), end: DateTime(2000)));
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
          color: kPaper,
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
                      cursor = DateTime(
                          cursor.year, cursor.month - 1, 1);
                    })),
                Text(
                    '${_monthsFull[cursor.month - 1]} ${cursor.year}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: kInk)),
                _navButton(Icons.chevron_right, () => setState(() {
                      cursor = DateTime(
                          cursor.year, cursor.month + 1, 1);
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
                                  color: kMuted2)))))
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
                final date =
                    DateTime(cursor.year, cursor.month, d);
                final isStart =
                    start != null && _sameDay(date, start!);
                final isEnd =
                    end != null && _sameDay(date, end!);
                final inRange = start != null &&
                    end != null &&
                    date.isAfter(start!) &&
                    date.isBefore(end!);
                return GestureDetector(
                  onTap: () => _pick(date),
                  child: Container(
                    decoration: BoxDecoration(
                      color: inRange
                          ? kSelected.withOpacity(0.55)
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
                            ? kOrange
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
                                : kInk,
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
              style:
                  const TextStyle(fontSize: 11.5, color: kMuted2),
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
                    foregroundColor: kMuted,
                    side: const BorderSide(color: kOutline),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Сбросить',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
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
                              start: start!,
                              end: end ?? start!)),
                  style: FilledButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: kHairline,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Применить',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ],
        ),
      ),
    ),
  );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) =>
      InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: kHairline),
          ),
          child: Icon(icon, size: 15, color: kInk),
        ),
      );
}

String _fmtDateShort(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}';
}

// ============================================================================
// Helpers
// ============================================================================
String _money(num v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _fmtDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  const months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'мая',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year} · ${two(d.hour)}:${two(d.minute)}';
}
