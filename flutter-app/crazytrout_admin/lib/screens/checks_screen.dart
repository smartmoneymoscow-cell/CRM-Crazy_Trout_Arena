import 'package:flutter/material.dart';

import '../data/demo_receipts.dart';
import '../data/demo_data.dart' as app_data show kDemoClients;
import '../models/client.dart';
import '../models/receipt_history.dart';
import '../services/print_route.dart' deferred as print_route;
import '../models/receipt.dart' as receipt_model;

// ============================================================================
// Экран «Чеки» — история выставленных чеков.
//
// Открывается по нажатию иконки «Чеки» в нижнем меню (см. home_shell.dart).
// Компонует:
//   • Поисковую строку (имя / телефон / сумма / дата),
//   • Три чипа-фильтра: «Период» (dropdown), «Календарь» (иконка → date range),
//     «Тип» (dropdown: С ФН / Без ФН),
//   • Ленту чеков,
//   • Экран деталей чека с превью и кнопкой AirPrint.
//
// Данные — из lib/data/demo_receipts.dart. В production заменяется на выборку
// из backend.
// ============================================================================

// ─── Цветовые константы ─────────────────────────────────────────────────────
const _ink = Color(0xFF14130F);
const _paper = Color(0xFFFBF6EC);
const _fill = Color(0xFFF3EEE4);
const _orange = Color(0xFFE8912B);
const _ember = Color(0xFF886F11);
const _hairline = Color(0xFFEFE8D8);
const _hairline2 = Color(0xFFE7E0D1);
const _outline = Color(0xFFDDD3BC);
const _muted = Color(0xFF8C8576);
const _muted2 = Color(0xFF9C9484);
const _selected = Color(0xFFEFD9AC);

// ─── Уровни клиентов (перенесено из карты пруда) ────────────────────────────
enum LevelKey { premium, standard, basic }

class LevelStyle {
  final String label, letter;
  final Color color, medalTop, medalMid, medalBottom, letterColor, ring;
  const LevelStyle({
    required this.label,
    required this.letter,
    required this.color,
    required this.medalTop,
    required this.medalMid,
    required this.medalBottom,
    required this.letterColor,
    required this.ring,
  });
}

const _levels = <LevelKey, LevelStyle>{
  LevelKey.premium: LevelStyle(
    label: 'Премиум',
    letter: 'П',
    color: Color(0xFFB8862E),
    medalTop: Color(0xFFFFE18A),
    medalMid: Color(0xFFE0A62E),
    medalBottom: Color(0xFFAD7A16),
    letterColor: Color(0xFF4A3300),
    ring: Color(0xFFB8862E),
  ),
  LevelKey.standard: LevelStyle(
    label: 'Стандарт',
    letter: 'С',
    color: Color(0xFF8B94A0),
    medalTop: Color(0xFFF2F5F8),
    medalMid: Color(0xFFC9D1D9),
    medalBottom: Color(0xFF98A2AD),
    letterColor: Color(0xFF2E3438),
    ring: Color(0xFF8B94A0),
  ),
  LevelKey.basic: LevelStyle(
    label: 'Базовый',
    letter: 'Б',
    color: Color(0xFF8C5C34),
    medalTop: Color(0xFFE3B98B),
    medalMid: Color(0xFFC08A54),
    medalBottom: Color(0xFF8C5C34),
    letterColor: Color(0xFFFFFFFF),
    ring: Color(0xFF8C5C34),
  ),
};

// ─── BestCatch, _PondStats, _FullClient ──────────────────────────────────────
class BestCatch {
  final String species, weight, date;
  final int sector;
  const BestCatch({
    required this.species,
    required this.weight,
    required this.sector,
    required this.date,
  });
}

class _PondStats {
  final Color color;
  final LevelKey level;
  final int points, pointsNext, visits, ltvK, fish, totalWeight;
  final String firstVisit, lastVisit, email;
  final BestCatch bestCatch;
  final int? currentSector;
  const _PondStats({
    required this.color,
    required this.level,
    required this.points,
    required this.pointsNext,
    required this.visits,
    required this.ltvK,
    required this.fish,
    required this.totalWeight,
    required this.firstVisit,
    required this.lastVisit,
    required this.email,
    required this.bestCatch,
    this.currentSector,
  });
}

const Map<int, _PondStats> _pondStatsById = {
  1: _PondStats(
    color: Color(0xFFE89829),
    level: LevelKey.premium,
    points: 1280,
    pointsNext: 1500,
    visits: 42,
    ltvK: 120,
    fish: 96,
    totalWeight: 215,
    firstVisit: '14.03.2023',
    lastVisit: '15.07.2026',
    email: 'ivanov@mail.ru',
    currentSector: 7,
    bestCatch:
        BestCatch(species: 'Осётр', weight: '6.2 кг', sector: 7, date: '02.07.2026'),
  ),
  2: _PondStats(
    color: Color(0xFF3FA66B),
    level: LevelKey.standard,
    points: 640,
    pointsNext: 1000,
    visits: 18,
    ltvK: 54,
    fish: 31,
    totalWeight: 78,
    firstVisit: '02.08.2024',
    lastVisit: '15.07.2026',
    email: 'koshkin@mail.ru',
    currentSector: 4,
    bestCatch:
        BestCatch(species: 'Карп', weight: '3.4 кг', sector: 4, date: '28.06.2026'),
  ),
  3: _PondStats(
    color: Color(0xFF2A6A7E),
    level: LevelKey.premium,
    points: 1410,
    pointsNext: 1500,
    visits: 55,
    ltvK: 1200,
    fish: 122,
    totalWeight: 289,
    firstVisit: '27.01.2022',
    lastVisit: '14.07.2026',
    email: 'petrov@mail.ru',
    currentSector: 2,
    bestCatch:
        BestCatch(species: 'Осётр', weight: '7.8 кг', sector: 2, date: '19.06.2026'),
  ),
  5: _PondStats(
    color: Color(0xFF886F11),
    level: LevelKey.standard,
    points: 780,
    pointsNext: 1000,
    visits: 21,
    ltvK: 68,
    fish: 40,
    totalWeight: 103,
    firstVisit: '11.11.2023',
    lastVisit: '13.07.2026',
    email: 'laguta@mail.ru',
    currentSector: 5,
    bestCatch:
        BestCatch(species: 'Амур', weight: '4.9 кг', sector: 5, date: '30.06.2026'),
  ),
  6: _PondStats(
    color: Color(0xFFB8862E),
    level: LevelKey.premium,
    points: 1500,
    pointsNext: 1500,
    visits: 68,
    ltvK: 2400,
    fish: 150,
    totalWeight: 365,
    firstVisit: '03.06.2021',
    lastVisit: '15.07.2026',
    email: 'orlov@mail.ru',
    currentSector: 1,
    bestCatch:
        BestCatch(species: 'Осётр', weight: '8.4 кг', sector: 1, date: '24.06.2026'),
  ),
  7: _PondStats(
    color: Color(0xFF6B7280),
    level: LevelKey.basic,
    points: 260,
    pointsNext: 500,
    visits: 7,
    ltvK: 15,
    fish: 12,
    totalWeight: 22,
    firstVisit: '09.02.2026',
    lastVisit: '10.07.2026',
    email: 'sidorov@mail.ru',
    currentSector: 10,
    bestCatch:
        BestCatch(species: 'Линь', weight: '1.6 кг', sector: 10, date: '11.06.2026'),
  ),
  8: _PondStats(
    color: Color(0xFF9C5A3C),
    level: LevelKey.standard,
    points: 520,
    pointsNext: 1000,
    visits: 14,
    ltvK: 46,
    fish: 27,
    totalWeight: 61,
    firstVisit: '18.01.2025',
    lastVisit: '12.07.2026',
    email: 'shchukin@mail.ru',
    currentSector: 8,
    bestCatch:
        BestCatch(species: 'Щука', weight: '4.1 кг', sector: 8, date: '15.06.2026'),
  ),
  100: _PondStats(
    color: Color(0xFF8C5C34),
    level: LevelKey.basic,
    points: 40,
    pointsNext: 500,
    visits: 1,
    ltvK: 1,
    fish: 2,
    totalWeight: 3,
    firstVisit: '10.07.2026',
    lastVisit: '10.07.2026',
    email: 'guest@crazytroutarena.ru',
    currentSector: 3,
    bestCatch:
        BestCatch(species: 'Карп', weight: '0.9 кг', sector: 3, date: '10.07.2026'),
  ),
};

/// Полная модель клиента для карточки (объединяет данные из models/client.dart
/// и статистику из карты пруда).
class _FullClient {
  final int id;
  final String name, phone, email, tariff, firstVisit, lastVisit;
  final Color color;
  final LevelKey level;
  final int points, pointsNext, visits, ltvK, fish, totalWeight;
  final BestCatch bestCatch;
  final int? currentSector;
  final String? avatarAsset;
  const _FullClient({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.color,
    required this.level,
    required this.tariff,
    required this.points,
    required this.pointsNext,
    required this.visits,
    required this.ltvK,
    required this.fish,
    required this.totalWeight,
    required this.firstVisit,
    required this.lastVisit,
    required this.bestCatch,
    this.currentSector,
    this.avatarAsset,
  });
}

/// Собираем полных клиентов из общего источника + статистика карты.
final List<_FullClient> _fullClients = app_data.kDemoClients.map((c) {
  final s = _pondStatsById[c.id] ??
      const _PondStats(
        color: Color(0xFF8B94A0),
        level: LevelKey.basic,
        points: 0,
        pointsNext: 500,
        visits: 0,
        ltvK: 0,
        fish: 0,
        totalWeight: 0,
        firstVisit: '—',
        lastVisit: '—',
        email: '—',
        bestCatch: BestCatch(species: '—', weight: '—', sector: 0, date: '—'),
      );
  return _FullClient(
    id: c.id,
    name: c.name,
    phone: c.phone,
    email: s.email,
    tariff: c.tariffLabel,
    avatarAsset: c.avatarAsset,
    color: s.color,
    level: s.level,
    points: s.points,
    pointsNext: s.pointsNext,
    visits: s.visits,
    ltvK: s.ltvK,
    fish: s.fish,
    totalWeight: s.totalWeight,
    firstVisit: s.firstVisit,
    lastVisit: s.lastVisit,
    bestCatch: s.bestCatch,
    currentSector: s.currentSector,
  );
}).toList();

/// Поиск полного клиента по id.
_FullClient? _findFullClient(int id) {
  for (final c in _fullClients) {
    if (c.id == id) return c;
  }
  return null;
}

String formatLtv(int k) {
  if (k >= 1000) {
    final v = k / 1000.0;
    final rounded = (v * 10).round() / 10.0;
    final str = rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
    return '${str.replaceAll('.', ',')} млн';
  }
  return '$k тыс.';
}

// ─── Фильтры ────────────────────────────────────────────────────────────────
enum _PeriodFilter { today, week, month, quarter }
enum _TypeFilter { fiscal, nonfiscal }

extension on _PeriodFilter {
  String get label => switch (this) {
        _PeriodFilter.today => 'За сегодня',
        _PeriodFilter.week => 'За неделю',
        _PeriodFilter.month => 'За месяц',
        _PeriodFilter.quarter => 'За квартал',
      };
}

extension on _TypeFilter {
  String get label => this == _TypeFilter.fiscal ? 'С ФН' : 'Без ФН';
}

// ============================================================================
// ChecksScreen
// ============================================================================
class ChecksScreen extends StatefulWidget {
  const ChecksScreen({super.key});

  @override
  State<ChecksScreen> createState() => _ChecksScreenState();
}

class _ChecksScreenState extends State<ChecksScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  _PeriodFilter? _period;
  _TypeFilter? _type;
  DateTimeRange? _dateRange;

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
    if (_period == null) return true;
    final now = DateTime.now();
    final start = switch (_period!) {
      _PeriodFilter.today => DateTime(now.year, now.month, now.day),
      _PeriodFilter.week => now.subtract(const Duration(days: 7)),
      _PeriodFilter.month => now.subtract(const Duration(days: 30)),
      _PeriodFilter.quarter => now.subtract(const Duration(days: 90)),
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
    return _type == _TypeFilter.fiscal ? r.fiscal : !r.fiscal;
  }

  List<ReceiptHistoryItem> get _filtered => kDemoReceipts
      .where((r) =>
          _matchesQuery(r) &&
          _matchesPeriod(r) &&
          _matchesRange(r) &&
          _matchesType(r))
      .toList();

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
    return res.take(4).toList();
  }

  // ---------- открытия ----------
  Future<void> _openCalendar() async {
    final res = await _showRangeCalendarPicker(context, _dateRange);
    if (!mounted || res == null) return;
    // DateTimeRange(2000,2000) — маркер «Сбросить»
    if (res.start.year == 2000 && res.end.year == 2000) {
      setState(() => _dateRange = null);
    } else {
      setState(() => _dateRange = res);
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
      color: _paper,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Center(
              child: Text('Чеки',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, color: _ink)),
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
                    _CalendarChip(
                      active: _dateRange != null,
                      onTap: _openCalendar,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterDropdown<_TypeFilter>(
                        value: _type,
                        label: 'Тип',
                        items: [
                          _FilterDropdownItem<_TypeFilter>(
                            value: null,
                            label: 'Все',
                            isReset: true,
                            enabled: _type != null,
                          ),
                          for (final t in _TypeFilter.values)
                            _FilterDropdownItem<_TypeFilter>(
                              value: t,
                              label: t.label,
                            ),
                        ],
                        onChanged: (v) => setState(() => _type = v),
                      ),
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
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
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
                                    : _hairline,
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
// Widgets — список
// ============================================================================
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
          color: _fill, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: _muted2),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: _orange,
              style: const TextStyle(fontSize: 14.5, color: _ink),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Имя, сумма, телефон, дата',
                hintStyle: TextStyle(color: _muted2, fontSize: 14.5),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(Icons.close, size: 18, color: _muted2),
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
        border: Border.all(color: _hairline),
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
                                  color: _ink)),
                          const SizedBox(height: 2),
                          Text(clients[i].phone,
                              style: const TextStyle(
                                  fontSize: 12, color: _muted2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < clients.length - 1)
              const Divider(height: 1, color: _hairline2),
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
          border: Border(bottom: BorderSide(color: _hairline2)),
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
                        color: _ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtDateTime(item.date),
                    style: const TextStyle(
                        fontSize: 12.5, color: _muted2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_money(item.total)} ₽',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _ink),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              height: 22,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.fiscal ? const Color(0xFFE8D5B5) : _hairline,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.fiscal ? 'С ФН' : 'Без ФН',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: item.fiscal ? _ink : _muted2,
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
            style: TextStyle(fontSize: 14, color: _muted2),
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
        child: const Icon(Icons.person_outline, color: _muted2, size: 22),
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
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        surfaceTintColor: _paper,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, size: 20, color: _ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Чек',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _ink)),
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
                      _findFullClient(receipt.client!.id);
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
                foregroundColor: _ink,
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: _outline),
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
        border: Border.all(color: _hairline),
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
                  color: _ink)),
          const SizedBox(height: 3),
          Text('Чек № ${r.number} · ${_fmtDateTime(r.date)}',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 11.5, color: _muted2)),
          const _CardDivider(),
          _row('Клиент', r.displayName),
          _row('Телефон', r.client?.phone ?? '—'),
          const _CardDivider(),
          _row('Тариф · ${r.tariffLabel}',
              '${_money(r.tariffPrice)} ₽'),
          for (final it in r.rows)
            _row(
                '${it.name} ${it.weight.toStringAsFixed(2)} кг × ${it.price.round()}',
                '${_money(it.sum)} ₽'),
          const _CardDivider(),
          _row('ИТОГО', '${_money(r.total)} ₽', bigTotal: true),
          _row('Оплата', r.paymentLabel),
          _row('Тип чека',
              r.fiscal ? 'Фискальный ${r.fiscalDoc ?? ""}' : 'Без ФН'),
        ],
      ),
    );
  }

  Widget _row(String l, String v, {bool bigTotal = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(l,
                  style: TextStyle(
                    fontSize: bigTotal ? 17 : 13.5,
                    color: _ink,
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
                  color: _ink,
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
      color: _hairline2,
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
            color: _fill,
            borderRadius: BorderRadius.circular(14)),
        child: const Text('Гость (без анкеты)',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted2, fontSize: 13)),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: _fill,
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
                          color: _ink)),
                  const SizedBox(height: 1),
                  Text(
                      '${client!.phone} · ${client!.tariffLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: _muted2)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: _muted2, size: 22),
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
  final _FullClient client;
  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final l = _levels[client.level]!;
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
          color: _paper,
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
                      colors: [l.color, _ink],
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
                                      color: _ink)),
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
                          border: Border.all(color: _hairline),
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
                                color: _ember,
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
                                          color: _ink)),
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
                                        color: _ink)),
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
        Icon(icon, size: 15, color: _ember),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 13, color: _ink)),
      ]);

  static Widget _statBlock(String label, String value) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _hairline),
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
                      color: _ink)),
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
    final l = _levels[level]!;
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
      backgroundColor: _paper,
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
                      const TextStyle(fontSize: 13, color: _ink))),
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
                      cursor = DateTime(
                          cursor.year, cursor.month - 1, 1);
                    })),
                Text(
                    '${_monthsFull[cursor.month - 1]} ${cursor.year}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: _ink)),
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
              style:
                  const TextStyle(fontSize: 11.5, color: _muted2),
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
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _hairline,
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
