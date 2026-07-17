import 'package:flutter/material.dart';
import '../data/demo_fish_stats.dart';
import '../widgets/finance_dashboard_card.dart';
import '../widgets/finance_pie_chart.dart';
import '../data/sales_decomposition.dart';
import '../widgets/payment_tariff_card.dart';
import '../data/payment_tariff_stats.dart';
import '../widgets/kpi_cards.dart';
import '../widgets/revenue_dynamics_chart.dart';
import '../data/finance_kpi_stats.dart';
import '../data/revenue_dynamics_data.dart';
import '../data/demo_receipts.dart';
import '../data/demo_data.dart' as app_data show kDemoClients, kSpecies, kSpeciesImage;
import '../models/client.dart';
import 'pond_map_filter_config.dart' show kBottomNavHeight;

// ============================================================================
// Экран «Отчёт» — отчёт по прибыли и убыткам.
//
// Верхнее меню фильтров: Период (dropdown) + Календарь (date range picker)
// + 3 слота под иконки.
//
// Вкладки: Финансы (заглушка), Клиенты (лента оплат), Рыба (таблица).
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

/// Конвертирует _PeriodFilter в DateTimeRange для фильтрации данных.
DateTimeRange? _periodToDateRange(_PeriodFilter? period) {
  if (period == null || period == _PeriodFilter.all) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = switch (period) {
    _PeriodFilter.today => today,
    _PeriodFilter.week => today.subtract(const Duration(days: 7)),
    _PeriodFilter.month => today.subtract(const Duration(days: 30)),
    _PeriodFilter.quarter => today.subtract(const Duration(days: 90)),
    _PeriodFilter.all => DateTime(0),
  };
  return DateTimeRange(start: start, end: today);
}

// ─── Уровни клиентов ────────────────────────────────────────────────────────
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

// ─── Модели данных для карточки клиента ──────────────────────────────────────
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
    lastVisit: _lastVisitFromReceipts[c.id] ?? s.lastVisit,
    bestCatch: s.bestCatch,
    currentSector: s.currentSector,
  );
}).toList();

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

// ─── Демо-данные ленты оплат ─────────────────────────────────────────────────
class _ClientPaymentEntry {
  final Client client;
  final DateTime date;
  final double amount;
  final int visits;
  final int ltvK;
  const _ClientPaymentEntry({
    required this.client,
    required this.date,
    required this.amount,
    required this.visits,
    required this.ltvK,
  });
}

List<_ClientPaymentEntry> _buildPaymentFeed() {
  final entries = <_ClientPaymentEntry>[];
  for (final r in kDemoReceipts) {
    if (r.isGuest || r.client == null) continue;
    final stats = _pondStatsById[r.client!.id];
    entries.add(_ClientPaymentEntry(
      client: r.client!,
      date: r.date,
      amount: r.total,
      visits: stats?.visits ?? 0,
      ltvK: stats?.ltvK ?? 0,
    ));
  }
  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
}

final List<_ClientPaymentEntry> _paymentFeed = _buildPaymentFeed();

// Compute last visit dates from actual receipt data
final Map<int, String> _lastVisitFromReceipts = () {
  final latestMap = <int, DateTime>{};
  for (final r in kDemoReceipts) {
    if (r.isGuest || r.client == null) continue;
    final id = r.client!.id;
    if (!latestMap.containsKey(id) || r.date.isAfter(latestMap[id]!)) {
      latestMap[id] = r.date;
    }
  }
  return latestMap.map((id, dt) => MapEntry(id, _fmtDate(dt)));
}();

// ─── Утилиты ─────────────────────────────────────────────────────────────────
String _fmtDate(DateTime d) {
  two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year}';
}

String _money(double v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
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
  int _selectedIcon = 0; // 0 = ruble, 1 = clients, 2 = fish

  // Tracks which filter was set last: 'calendar' or 'dropdown' or null
  String? _lastFilterSource;

  /// Effective period — calendar takes priority if it was set last.
  _PeriodFilter? get _effectivePeriod {
    if (_lastFilterSource == 'calendar') return null;
    return _period;
  }

  /// Effective date range — dropdown takes priority if it was set last.
  DateTimeRange? get _effectiveDateRange {
    if (_lastFilterSource == 'dropdown') return null;
    return _dateRange;
  }

  /// DateTimeRange для вкладки «Финансы».
  DateTimeRange? get _effectiveDateForFinance {
    if (_lastFilterSource == 'dropdown') {
      return _periodToDateRange(_period);
    }
    return _dateRange;
  }

  Future<void> _openCalendar() async {
    final res = await _showRangeCalendarPicker(context, _dateRange);
    if (!mounted || res == null) return;
    if (res.start.year == 2000 && res.end.year == 2000) {
      setState(() {
        _dateRange = null;
        _lastFilterSource = _period != null ? 'dropdown' : null;
      });
    } else {
      setState(() {
        _dateRange = res;
        _lastFilterSource = 'calendar';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _paper,
      child: Column(
        children: [
          // ── Заголовок ──
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

          // ── Фильтры ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Row(
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
                    onChanged: (v) => setState(() {
                    _period = v;
                    _lastFilterSource = v != null ? 'dropdown' : (_dateRange != null ? 'calendar' : null);
                  }),
                  ),
                ),
                const SizedBox(width: 8),
                _CalendarChip(
                  active: _dateRange != null,
                  onTap: _openCalendar,
                ),
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
              1 => _ClientStatsContent(
                    period: _effectivePeriod,
                    dateRange: _effectiveDateRange,
                  ),
              2 => _FishStatsContent(period: _effectivePeriod, dateRange: _effectiveDateRange),
              _ => _FinanceContent(
                    periodKey: _period?.name,
                    dateRange: _effectiveDateForFinance,
                  ),
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _FinanceContent — контент вкладки «Финансы и метрики».
//
// Дашборд «Выручка / Маржинальная прибыль / Переменные расходы» со
// спарклайном, портированный из dashboard_2.html (см. FinanceDashboardCard).
// ============================================================================
class _FinanceContent extends StatelessWidget {
  final String? periodKey;
  final DateTimeRange? dateRange;
  const _FinanceContent({this.periodKey, this.dateRange});

  @override
  Widget build(BuildContext context) {
    final salesData = buildSalesDecomposition(dateRange: dateRange);
    final paymentData = buildPaymentTariffStats(dateRange: dateRange);
    final kpiData = buildFinanceKpiStats(dateRange: dateRange);
    final dynamicsData = buildRevenueDynamicsData(dateRange: dateRange);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
      child: Column(
        children: [
          const FinanceDashboardCard(),
          const SizedBox(height: 14),
          FinancePieChart(data: salesData),
          const SizedBox(height: 14),
          KpiCards(stats: kpiData),
          const SizedBox(height: 14),
          PaymentTariffCard(stats: paymentData),
          const SizedBox(height: 14),
          RevenueDynamicsChart(data: dynamicsData, periodKey: periodKey),
        ],
      ),
    );
  }
}

// =============================================================================
// _ClientStatsContent — лента оплат клиентов
// ============================================================================
class _ClientStatsContent extends StatelessWidget {
  final _PeriodFilter? period;
  final DateTimeRange? dateRange;

  const _ClientStatsContent({required this.period, required this.dateRange});

  @override
  Widget build(BuildContext context) {
    final items = _paymentFeed.where((e) {
      if (period == null || period == _PeriodFilter.all) {
        // фильтр по календарю если есть
        if (dateRange != null) {
          final d = DateTime(e.date.year, e.date.month, e.date.day);
          final s = DateTime(dateRange!.start.year, dateRange!.start.month,
              dateRange!.start.day);
          final en = DateTime(
              dateRange!.end.year, dateRange!.end.month, dateRange!.end.day);
          return !d.isBefore(s) && !d.isAfter(en);
        }
        return true;
      }
      final now = DateTime.now();
      final start = switch (period!) {
        _PeriodFilter.today => DateTime(now.year, now.month, now.day),
        _PeriodFilter.week => now.subtract(const Duration(days: 7)),
        _PeriodFilter.month => now.subtract(const Duration(days: 30)),
        _PeriodFilter.quarter => now.subtract(const Duration(days: 90)),
        _PeriodFilter.all => DateTime(0),
      };
      final matchesPeriod =
          e.date.isAfter(start) || e.date.isAtSameMomentAs(start);
      if (dateRange != null) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        final s = DateTime(dateRange!.start.year, dateRange!.start.month,
            dateRange!.start.day);
        final en = DateTime(
            dateRange!.end.year, dateRange!.end.month, dateRange!.end.day);
        return matchesPeriod && !d.isBefore(s) && !d.isAfter(en);
      }
      return matchesPeriod;
    }).toList();

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'Нет оплат по заданным условиям',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _muted2),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
      itemCount: items.length,
      itemBuilder: (_, i) => _ClientPaymentRow(
        entry: items[i],
        onAvatarTap: () {
          final full = _findFullClient(items[i].client.id);
          if (full != null) {
            showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.5),
              builder: (_) => _ClientCard(client: full),
            );
          }
        },
      ),
    );
  }
}

// ============================================================================
// _ClientPaymentRow — строка ленты оплат (стиль как _ReceiptRow)
// ============================================================================
class _ClientPaymentRow extends StatelessWidget {
  final _ClientPaymentEntry entry;
  final VoidCallback onAvatarTap;

  const _ClientPaymentRow({
    required this.entry,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _hairline2)),
      ),
      child: Row(
        children: [
          // Аватар (кликабельный)
          GestureDetector(
            onTap: onAvatarTap,
            child: _Avatar(client: entry.client, size: 44),
          ),
          const SizedBox(width: 12),
          // Имя + дата оплаты
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.client.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: _ink),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmtDate(entry.date),
                  style:
                      const TextStyle(fontSize: 12.5, color: _muted2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Сумма оплаты (зелёная, с "+")
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '+${_money(entry.amount)} ₽',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3FA66B)),
              ),
              const SizedBox(width: 8),
              // LT/LTV
              Text(
                'LT ${entry.visits} / LTV ${formatLtv(entry.ltvK)}',
                style:
                    const TextStyle(fontSize: 11.5, color: _muted2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _Avatar — аватар клиента (как в чеках)
// ============================================================================
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
// _ClientCard — полная карточка клиента (из чеков)
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
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
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

// ── LevelBadge ──────────────────────────────────────────────────────────────
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
// _FishStatsContent — контент вкладки «Статистика улова рыбы»
// ============================================================================
// ── Обёртка для масштабирования демо-данных по периоду ──
class _ScaledFishStats implements FishSpeciesStats {
  final FishSpeciesStats _inner;
  final double _factor;
  _ScaledFishStats(this._inner, this._factor);

  @override String get species => _inner.species;
  @override String get imageAsset => _inner.imageAsset;
  @override int get count => (_inner.count * _factor).round().clamp(0, _inner.count);
  @override double get weightKg => (_inner.weightKg * _factor).clamp(0, _inner.weightKg);
  @override double get pricePerKg => _inner.pricePerKg;
  @override int get remaining => _inner.remaining;
  @override double get marginPct => _inner.marginPct;
  @override double get revenue => weightKg * pricePerKg;
  @override double get avgWeight => count > 0 ? weightKg / count : 0;
}

class _FishStatsContent extends StatelessWidget {
  final _PeriodFilter? period;
  final DateTimeRange? dateRange;

  _FishStatsContent({this.period, this.dateRange});

  static const double _imageSize = 48;

  static const _revenueMin = Color(0xFFFBE8D0);
  static const _revenueMax = Color(0xFFD4EDDA);

  Color _revenueColor(double value, double min, double max) {
    if (max <= min) return _revenueMin;
    final t = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return Color.lerp(_revenueMin, _revenueMax, t)!;
  }

  @override
  Widget build(BuildContext context) {
    // ── Фильтрация данных по периоду / календарю ──
    List<FishSpeciesStats> stats = kDemoFishStats;
    if (period != null && period != _PeriodFilter.all) {
      final daysBack = switch (period!) {
        _PeriodFilter.today => 1,
        _PeriodFilter.week => 7,
        _PeriodFilter.month => 30,
        _PeriodFilter.quarter => 90,
        _PeriodFilter.all => 99999,
      };
      // Scale demo data proportionally to represent the period
      final factor = daysBack / 30.0;
      stats = kDemoFishStats.map((s) => _ScaledFishStats(s, factor)).toList();
    }
    if (dateRange != null) {
      final days = dateRange!.end.difference(dateRange!.start).inDays + 1;
      final factor = days / 30.0;
      stats = kDemoFishStats.map((s) => _ScaledFishStats(s, factor)).toList();
    }
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
                Expanded(flex: 3, child: Text('Выручка', textAlign: TextAlign.center,
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
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: _imageSize,
                          height: _imageSize,
                          child: Image.asset(
                            s.imageAsset,
                            fit: BoxFit.contain,
                          ),
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
                  Expanded(
                    flex: 2,
                    child: Text(_formatNum(s.count), textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF14130F))),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(s.avgWeight.toStringAsFixed(1),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF14130F))),
                  ),
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
          ],

          // ── ИТОГО строка таблицы 1 ──
          Builder(
            builder: (context) {
              final totalCount = stats.fold<int>(0, (s, e) => s + e.count);
              final totalWeight = stats.fold<double>(0, (s, e) => s + e.weightKg);
              final totalRevenue = stats.fold<double>(0, (s, e) => s + e.revenue);
              final totalRemaining = stats.fold<int>(0, (s, e) => s + e.remaining);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEE4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDD3BC)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text('ИТОГО',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800,
                              color: Color(0xFF14130F))),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(_formatNum(totalCount), textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: Color(0xFF14130F))),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(totalWeight.toStringAsFixed(1),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: Color(0xFF14130F))),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4EDDA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatRevenue(totalRevenue),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800,
                              color: Color(0xFF14130F)),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatNum(totalRemaining),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: Color(0xFF14130F)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

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
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: _imageSize,
                                  height: _imageSize,
                                  child: Image.asset(
                                    s.imageAsset,
                                    fit: BoxFit.contain,
                                  ),
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
                          Expanded(
                            flex: 3,
                            child: _PercentCell(
                              pct: (s.revenue / totalRev * 100).round(),

                              barColor: const Color(0xFFE8912B),
                            ),
                          ),
                          const SizedBox(width: 4),
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
                  ],
                  // ── ИТОГО строка таблицы 2 ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EEE4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDD3BC)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 3,
                          child: Text('ИТОГО',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800,
                                  color: Color(0xFF14130F))),
                        ),
                        Expanded(
                          flex: 3,
                          child: _PercentCell(
                            pct: 100,
                            barColor: const Color(0xFFE8912B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 3,
                          child: _PercentCell(
                            pct: (stats.fold<double>(0, (s, e) => s + e.marginPct) / stats.length).round(),
                            barColor: const Color(0xFF3FA66B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Добавить рыбу в пруд ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF6EC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEFE8D8)),
            ),
            child: _AddFishForm(),
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
      return '${r.toStringAsFixed(1).replaceAll('.', ',')} млн';
    }
    if (rounded > 999) {
      return '${(rounded / 1000).round()} тыс.';
    }
    final s = rounded.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ============================================================================
// _PercentCell — ячейка с процентом и мини-шкалой
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
        SizedBox(
          width: double.infinity,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFEFE8D8),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (pct / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// _AddFishForm — форма добавления рыбы в пруд
// ============================================================================
class _AddFishForm extends StatefulWidget {
  const _AddFishForm();

  @override
  State<_AddFishForm> createState() => _AddFishFormState();
}

class _AddFishFormState extends State<_AddFishForm> {
  String? _selectedSpecies;
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();

  @override
  void dispose() {
    _qtyController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ДОБАВИТЬ РЫБУ В ПРУД',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8C8576),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        // Species dropdown
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEE4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEFE8D8)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedSpecies,
              hint: const Text('Выберите рыбу',
                  style: TextStyle(fontSize: 14, color: Color(0xFF9C9484))),
              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF9C9484)),
              items: app_data.kSpecies.map((sp) => DropdownMenuItem(
                value: sp,
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Image.asset(app_data.kSpeciesImage[sp]!, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 10),
                    Text(sp, style: const TextStyle(fontSize: 14, color: Color(0xFF14130F))),
                  ],
                ),
              )).toList(),
              onChanged: (v) => setState(() => _selectedSpecies = v),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Quantity + Cost row
        Row(
          children: [
            Expanded(
              child: _NumberInput(
                controller: _qtyController,
                label: 'Количество (шт.)',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberInput(
                controller: _costController,
                label: 'Затраты',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Submit button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8912B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: _selectedSpecies != null ? () {
              // Demo — just show a snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${_selectedSpecies!}: ${_qtyController.text.isEmpty ? "0" : _qtyController.text} шт. добавлено',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: const Color(0xFF4A7C59),
                  duration: const Duration(seconds: 2),
                ),
              );
              setState(() {
                _selectedSpecies = null;
                _qtyController.clear();
                _costController.clear();
              });
            } : null,
            child: const Text(
              'Добавить',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _NumberInput({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEE4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFE8D8)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 14, color: Color(0xFF14130F)),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: label,
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9C9484)),
        ),
      ),
    );
  }
}

// ============================================================================
// _IconSlot — иконка-кнопка 44×44
// ============================================================================ 
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
                size: 20, color: active ? Colors.white : _ink),
      ),
    );
  }
}

// ============================================================================
// _FilterDropdown — OverlayEntry-based dropdown
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
    // Глобальная Y нижнего края кнопки — для ограничения высоты dropdown.
    final btnBottomY = box.localToGlobal(Offset(0, size.height)).dy;
    final mq = MediaQuery.of(context);
    // Dropdown НЕ перекрывает нижнее меню.
    final maxH = mq.size.height - btnBottomY - kBottomNavHeight - mq.padding.bottom - 8;

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
            offset: Offset(0, size.height),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_borderRadius),
                  border: Border.all(color: _outline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_borderRadius),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxH > 0 ? maxH : 0),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: widget.items.length,
                      itemBuilder: (_, i) {
                        final item = widget.items[i];
                        final isSelected = item.value == widget.value;
                        return InkWell(
                          onTap: item.enabled
                              ? () {
                                  widget.onChanged(item.value);
                                  _close();
                                }
                              : null,
                          child: Container(
                            height: _itemHeight,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.centerLeft,
                            color: isSelected
                                ? _selected.withOpacity(0.4)
                                : null,
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: item.enabled
                                    ? _ink
                                    : _muted2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
    setState(() => _open = false);
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
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(_borderRadius),
              topRight: const Radius.circular(_borderRadius),
              bottomLeft: Radius.circular(_open ? 0 : _borderRadius),
              bottomRight: Radius.circular(_open ? 0 : _borderRadius),
            ),
            border: Border.all(
                color: _open ? _orange : _hairline),
          ),
          child: Row(
            children: [
              if (widget.value != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  widget.value != null
                      ? widget.items
                          .firstWhere((i) => i.value == widget.value)
                          .label
                      : widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.value != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: widget.value != null ? _ink : _muted2,
                  ),
                ),
              ),
              Icon(
                _open
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 20,
                color: _muted2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _CalendarChip — кнопка календаря 44×44
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
          color: active ? _orange : _fill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.calendar_today_outlined,
          size: 20,
          color: active ? Colors.white : _ink,
        ),
      ),
    );
  }
}

// ============================================================================
// Календарь периода (range-выбор)
// ============================================================================
const _monthsFull = [
  'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
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
  State<_RangeCalendarPicker> createState() => _RangeCalendarPickerState();
}

class _RangeCalendarPickerState extends State<_RangeCalendarPicker> {
  late DateTime _month;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initial?.start;
    _end = widget.initial?.end;
    _month = _start ?? DateTime.now();
    _month = DateTime(_month.year, _month.month);
  }

  void _pick(DateTime d) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = d;
        _end = null;
      } else {
        if (d.isBefore(_start!)) {
          _end = _start;
          _start = d;
        } else {
          _end = d;
        }
      }
    });
  }

  void _prev() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));
  void _next() =>
      setState(() => _month = DateTime(_month.year, _month.month + 1));

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday =
        DateTime(_month.year, _month.month, 1).weekday; // 1=Mon
    final cells = <_DayCell>[];
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const _DayCell.empty());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_month.year, _month.month, d);
      bool selected = false;
      if (_start != null && _end != null) {
        selected = !date.isBefore(_start!) && !date.isAfter(_end!);
      } else if (_start != null) {
        selected = date.isAtSameMomentAs(_start!);
      }
      cells.add(_DayCell(
        day: d,
        selected: selected,
        isStart: _start != null && date.isAtSameMomentAs(_start!),
        isEnd: _end != null && date.isAtSameMomentAs(_end!),
        onTap: () => _pick(date),
      ));
    }

    return Dialog(
      backgroundColor: _paper,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 22),
                  onPressed: _prev,
                  color: _ink,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                ),
                Expanded(
                  child: Text(
                    '${_monthsFull[_month.month - 1]} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _ink),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 22),
                  onPressed: _next,
                  color: _ink,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Weekdays
            Row(
              children: _weekdaysShort
                  .map((d) => Expanded(
                        child: Text(d,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _muted2)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),
            // Grid
            Wrap(
              children: cells,
            ),
            const SizedBox(height: 12),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      // Сброс
                      Navigator.of(context).pop(
                          DateTimeRange(
                              start: DateTime(2000),
                              end: DateTime(2000)));
                    },
                    child: const Text('Сбросить',
                        style: TextStyle(
                            color: _muted2,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _start != null && _end != null
                        ? () => Navigator.of(context).pop(
                            DateTimeRange(
                                start: _start!, end: _end!))
                        : null,
                    child: const Text('Применить',
                        style: TextStyle(
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int? day;
  final bool selected, isStart, isEnd;
  final VoidCallback? onTap;

  const _DayCell({
    this.day,
    this.selected = false,
    this.isStart = false,
    this.isEnd = false,
    this.onTap,
  });

  const _DayCell.empty()
      : day = null,
        selected = false,
        isStart = false,
        isEnd = false,
        onTap = null;

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      return const SizedBox(width: 40, height: 36);
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _orange : null,
          borderRadius: BorderRadius.horizontal(
            left: isStart ? const Radius.circular(8) : Radius.zero,
            right: isEnd ? const Radius.circular(8) : Radius.zero,
          ),
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 14,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? Colors.white : _ink,
          ),
        ),
      ),
    );
  }
}
