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
import '../data/demo_finance_stats.dart' show buildFinanceStats;
import '../data/revenue_dynamics_data.dart';
import '../data/demo_receipts.dart';
import '../data/demo_data.dart' as app_data show kDemoClients, kSpecies, kSpeciesImage, kSpeciesImageHeight, kSpeciesImageHeightDefault;
import '../models/client.dart';
import '../theme/app_theme.dart';
import '../data/pond_stats.dart';
import 'pond_map_filter_config.dart' show kBottomNavHeight;

enum _PeriodFilter { today, week, month, quarter, all }

extension on _PeriodFilter {
  String get label => switch (this) {
        _PeriodFilter.today => 'Сегодня',
        _PeriodFilter.week => 'Неделя',
        _PeriodFilter.month => 'Месяц',
        _PeriodFilter.quarter => 'Квартал',
        _PeriodFilter.all => 'Все вр.',
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
    final stats = kPondStatsById[r.client!.id];
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
    if (_period != null) return _periodToDateRange(_period);
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
        _period = null; // Сбрасываем период (требование 1)
        _lastFilterSource = 'calendar';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPaper,
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
                    color: kInk),
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
                    if (v != null) {
                      // Выбран период — сбрасываем календарь (требование 1)
                      _dateRange = null;
                      _lastFilterSource = 'dropdown';
                    } else {
                      _lastFilterSource = _dateRange != null ? 'calendar' : null;
                    }
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
              _ => _FinanceContent(periodKey: _period?.name, dateRange: _effectiveDateForFinance),
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
          FinanceDashboardCard(stats: buildFinanceStats(dateRange: dateRange)),
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
            style: TextStyle(fontSize: 14, color: kMuted2),
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
        border: Border(bottom: BorderSide(color: kHairline2)),
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
                      color: kInk),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmtDate(entry.date),
                  style:
                      const TextStyle(fontSize: 12.5, color: kMuted2),
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
                    const TextStyle(fontSize: 11.5, color: kMuted2),
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
// _ClientCard — полная карточка клиента (из чеков)
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
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
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

// ── LevelBadge ──────────────────────────────────────────────────────────────
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

class _FishStatsContent extends StatefulWidget {
  final _PeriodFilter? period;
  final DateTimeRange? dateRange;

  const _FishStatsContent({this.period, this.dateRange});

  @override
  State<_FishStatsContent> createState() => _FishStatsContentState();
}

class _FishStatsContentState extends State<_FishStatsContent> {
  // Счётчик добавленной рыбы (по породам).
  final Map<String, int> _addedFish = {};

  // Размеры рыб в отчёте — пропорции из dropdown чека, уменьшены на 25%.
  // Каждая рыба имеет свой размер, не единый квадрат.
  static const Map<String, double> _imageHeight = {
    'Осётр': 33,
    'Амур': 30,
    'Форель': 27,
    'Карп': 27,
    'Линь': 24,
  };
  static const double _imageHeightDefault = 24;

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
    if (widget.period != null && widget.period != _PeriodFilter.all) {
      final daysBack = switch (widget.period!) {
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
    if (widget.dateRange != null) {
      final days = widget.dateRange!.end.difference(widget.dateRange!.start).inDays + 1;
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            s.imageAsset,
                            height: _imageHeight[s.species] ?? _imageHeightDefault,
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
                    child: Builder(
                      builder: (_) {
                        final remaining = s.remaining + (_addedFish[s.species] ?? 0);
                        return Text(
                          _formatNum(remaining),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: remaining < 50
                                ? FontWeight.w700 : FontWeight.w400,
                            color: remaining < 50
                                ? const Color(0xFFC9302C)
                                : const Color(0xFF14130F),
                          ),
                        );
                      },
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
              final totalRemaining = stats.fold<int>(0, (s, e) => s + e.remaining)
                  + _addedFish.values.fold<int>(0, (a, b) => a + b);
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
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    s.imageAsset,
                                    height: _imageHeight[s.species] ?? _imageHeightDefault,
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

          // ── Кнопка «Добавить рыбу» ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showAddFishDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8A6D1E),
                side: const BorderSide(color: Color(0xFFDDD3BC)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: const Color(0xFFFBF6EC),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Добавить рыбу в пруд',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFishDialog(BuildContext context) {
    String? selectedSpecies;
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: const BoxConstraints(maxWidth: 360),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF6EC),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 60,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'ДОБАВИТЬ РЫБУ В ПРУД',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8C8576),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Выбор рыбы
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
                                value: selectedSpecies,
                                hint: const Text('Выберите рыбу',
                                  style: TextStyle(fontSize: 14, color: Color(0xFF9C9484))),
                                icon: const Icon(Icons.keyboard_arrow_down,
                                  size: 20, color: Color(0xFF9C9484)),
                                items: app_data.kSpecies.map((sp) => DropdownMenuItem(
                                  value: sp,
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        app_data.kSpeciesImage[sp]!,
                                        height: app_data.kSpeciesImageHeight[sp]
                                            ?? app_data.kSpeciesImageHeightDefault,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(sp, style: const TextStyle(
                                        fontSize: 14, color: Color(0xFF14130F))),
                                    ],
                                  ),
                                )).toList(),
                                onChanged: (v) => setDialogState(() => selectedSpecies = v),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Количество + Затраты
                          Row(children: [
                            Expanded(child: TextField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Количество (шт.)',
                                labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF9C9484)),
                                filled: true,
                                fillColor: const Color(0xFFF3EEE4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: TextField(
                              controller: costCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Затраты',
                                labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF9C9484)),
                                filled: true,
                                fillColor: const Color(0xFFF3EEE4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                            )),
                          ]),
                          const SizedBox(height: 16),
                          // Кнопки
                          Row(children: [
                            Expanded(child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF9C9484),
                                side: const BorderSide(color: Color(0xFFDDD3BC)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Отмена'),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: ElevatedButton(
                              onPressed: selectedSpecies != null ? () {
                                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                                if (qty <= 0) return;
                                setState(() {
                                  _addedFish[selectedSpecies!] =
                                      (_addedFish[selectedSpecies!] ?? 0) + qty;
                                });
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.fromLTRB(16, 50, 16, 0),
                                    backgroundColor: const Color(0xFF4A7C59),
                                    duration: const Duration(seconds: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                    content: Text(
                                      '$selectedSpecies: $qty шт. добавлено',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                );
                              } : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE8912B),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Добавить',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            )),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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
          color: active ? kOrange : kFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: assetPath != null
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(assetPath!,
                    color: active ? Colors.white : kInk,
                    fit: BoxFit.contain),
              )
            : Icon(icon,
                size: 20, color: active ? Colors.white : kInk),
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
                  border: Border.all(color: kOutline),
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
                                ? kSelected.withOpacity(0.4)
                                : null,
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: item.enabled
                                    ? kInk
                                    : kMuted2,
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
            color: kFill,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_open ? 0 : _borderRadius),
              topRight: Radius.circular(_open ? 0 : _borderRadius),
              bottomLeft: Radius.circular(_open ? 0 : _borderRadius),
              bottomRight: Radius.circular(_open ? 0 : _borderRadius),
            ),
            border: Border.all(
                color: _open ? kOrange : kHairline),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
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
                    color: widget.value != null ? kInk : kMuted2,
                  ),
                ),
              ),
              Icon(
                _open
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 20,
                color: kMuted2,
              ),
              ],
              ),
              // Оранжевая точка-индикатор — поверх карточки (требование 8)
              if (widget.value != null)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: kOrange,
                      shape: BoxShape.circle,
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: kInk,
            ),
          ),
          // Оранжевая точка-индикатор (требование 9)
          if (active)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: kOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
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
      backgroundColor: kPaper,
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
                  color: kInk,
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
                        color: kInk),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 22),
                  onPressed: _next,
                  color: kInk,
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
                                color: kMuted2)),
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
                            color: kMuted2,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _start != null
                        ? () => Navigator.of(context).pop(
                            DateTimeRange(
                                start: _start!,
                                end: _end ?? _start!))
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
          color: selected ? kOrange : null,
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
            color: selected ? Colors.white : kInk,
          ),
        ),
      ),
    );
  }
}
