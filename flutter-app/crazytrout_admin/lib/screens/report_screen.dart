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
import '../data/demo_data.dart' as app_data show kSpecies, kSpeciesImage, kSpeciesImageHeight, kSpeciesImageHeightDefault;
import '../models/client.dart';
import '../theme/app_theme.dart';
import '../data/pond_stats.dart';
import '../widgets/client_avatar.dart';
import '../widgets/level_badge.dart';
import '../data/filter_types.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/app_dropdown_field.dart';

/// Конвертирует PeriodFilter в DateTimeRange для фильтрации данных.
DateTimeRange? _periodToDateRange(PeriodFilter? period) {
  return periodToDateRange(period);
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

// ─── Унифицированная фильтрация чеков по периоду и дате ──────────────────────
/// Общая логика фильтрации для всех вкладок экрана «Отчёт».
/// Календарь и период применяются совместно (AND), если оба заданы.
bool _receiptInPeriod(_ClientPaymentEntry e, PeriodFilter? period) {
  if (period == null || period == PeriodFilter.all) return true;
  final now = DateTime.now();
  final start = switch (period) {
    PeriodFilter.today => DateTime(now.year, now.month, now.day),
    PeriodFilter.week => now.subtract(const Duration(days: 7)),
    PeriodFilter.month => now.subtract(const Duration(days: 30)),
    PeriodFilter.quarter => now.subtract(const Duration(days: 90)),
    PeriodFilter.all => DateTime(0),
  };
  return e.date.isAfter(start) || e.date.isAtSameMomentAs(start);
}

bool _dateInRange(DateTime date, DateTimeRange? range) {
  if (range == null) return true;
  final d = DateTime(date.year, date.month, date.day);
  final s = DateTime(range.start.year, range.start.month, range.start.day);
  final e = DateTime(range.end.year, range.end.month, range.end.day);
  return !d.isBefore(s) && !d.isAfter(e);
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
  PeriodFilter? _period;
  DateTimeRange? _dateRange;
  int _selectedIcon = 0; // 0 = ruble, 1 = clients, 2 = fish

  // Tracks which filter was set last: 'calendar' or 'dropdown' or null
  String? _lastFilterSource;

  /// Effective period — calendar takes priority if it was set last.
  PeriodFilter? get _effectivePeriod {
    if (_lastFilterSource == 'calendar') return null;
    return _period;
  }

  /// Effective date range — dropdown takes priority if it was set last.
  DateTimeRange? get _effectiveDateRange {
    if (_lastFilterSource == 'dropdown') return null;
    return _dateRange;
  }

  /// DateTimeRange для вкладки «Финансы».
  /// Календарь имеет приоритет, если был выбран последним.
  DateTimeRange? get _effectiveDateForFinance {
    if (_lastFilterSource == 'calendar' && _dateRange != null) return _dateRange;
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
                  child: FilterDropdown<PeriodFilter>(
                    value: _period,
                    label: 'Период',
                    items: [
                      FilterDropdownItem<PeriodFilter>(
                        value: null,
                        label: 'Нет',
                        isReset: true,
                        enabled: _period != null,
                      ),
                      for (final p in PeriodFilter.values)
                        FilterDropdownItem<PeriodFilter>(
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

  /// Виртуальный periodKey для автопереключения графиком «мецы/недели».
  /// Если periodKey задан из дропдауна — используем его.
  /// Если фильтр через календарь — определяем по длительности диапазона.
  String? get _effectivePeriodKey {
    if (periodKey != null) return periodKey;
    if (dateRange != null) {
      final days = dateRange!.end.difference(dateRange!.start).inDays;
      if (days <= 7) return 'week';
      if (days <= 31) return 'month';
      return 'quarter';
    }
    return null;
  }

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
          RevenueDynamicsChart(data: dynamicsData, periodKey: _effectivePeriodKey),
        ],
      ),
    );
  }
}

// =============================================================================
// _ClientStatsContent — лента оплат клиентов
// ============================================================================
class _ClientStatsContent extends StatelessWidget {
  final PeriodFilter? period;
  final DateTimeRange? dateRange;

  const _ClientStatsContent({required this.period, required this.dateRange});

  @override
  Widget build(BuildContext context) {
    final items = _paymentFeed.where((e) {
      return _receiptInPeriod(e, period) && _dateInRange(e.date, dateRange);
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
          final full = findFullClient(items[i].client.id);
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
            child: ClientAvatar(client: entry.client, size: 44),
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
                              LevelBadge(level: client.level),
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
  final PeriodFilter? period;
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
    'Осётр': 32,
    'Амур': 28,
    'Форель': 24,
    'Карп': 24,
    'Линь': 22,
  };
  static const double _imageHeightDefault = 22;

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
    if (widget.period != null && widget.period != PeriodFilter.all) {
      final daysBack = switch (widget.period!) {
        PeriodFilter.today => 1,
        PeriodFilter.week => 7,
        PeriodFilter.month => 30,
        PeriodFilter.quarter => 90,
        PeriodFilter.all => 99999,
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
          // ── Таблица 1: единый контейнер без зазоров ──
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEFE8D8)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Шапка — нижние углы прямые, разделитель снизу
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3EEE4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: Border(bottom: BorderSide(color: Color(0xFFDDD3BC))),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('Тип рыбы',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                              color: Color(0xFF8C8576)))),
                      Expanded(flex: 2, child: Text('Вылов\n(шт.)', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                              color: Color(0xFF8C8576)))),
                      Expanded(flex: 2, child: Text('Ср. Вес\n(кг.)', textAlign: TextAlign.center,
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
                // Строки рыбы — без скруглений, с разделителем
                for (final s in stats)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBF6EC),
                      border: Border(top: BorderSide(color: Color(0xFFEFE8D8))),
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
                              textAlign: TextAlign.center,
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
                // ИТОГО — верхние углы прямые, нижние скруглены
                Builder(
                  builder: (context) {
                    final totalCount = stats.fold<int>(0, (s, e) => s + e.count);
                    final totalRevenue = stats.fold<double>(0, (s, e) => s + e.revenue);
                    final totalRemaining = stats.fold<int>(0, (s, e) => s + e.remaining)
                        + _addedFish.values.fold<int>(0, (a, b) => a + b);
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3EEE4),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        border: Border(top: BorderSide(color: Color(0xFFDDD3BC))),
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
                          const Expanded(
                            flex: 2,
                            child: Text('—',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: Color(0xFF9C9484))),
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
                                textAlign: TextAlign.center,
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
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Таблица 2: единый контейнер без зазоров ──
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEFE8D8)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Шапка таблицы 2 — нижние углы прямые, разделитель
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3EEE4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: Border(bottom: BorderSide(color: Color(0xFFDDD3BC))),
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
                // Строки таблицы 2 — без скруглений
                Builder(
                  builder: (context) {
                    final totalRev = stats.fold<double>(0, (s, e) => s + e.revenue);
                    return Column(
                      children: [
                        for (final s in stats)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFBF6EC),
                              border: Border(top: BorderSide(color: Color(0xFFEFE8D8))),
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
                        // ИТОГО таблицы 2 — верхние углы прямые, нижние скруглены
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3EEE4),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            border: Border(top: BorderSide(color: Color(0xFFDDD3BC))),
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
              ],
            ),
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
    String selectedSpecies = app_data.kSpecies.first;
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
                constraints: const BoxConstraints(maxWidth: 320),
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
                          AppDropdownField<String>(
                              value: selectedSpecies,
                              items: app_data.kSpecies.map((sp) => AppDropdownItem(
                                value: sp,
                                child: Row(
                                  children: [
                                    Text(sp, overflow: TextOverflow.ellipsis),
                                    Expanded(
                                      child: Center(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.asset(
                                            app_data.kSpeciesImage[sp]!,
                                            height: app_data.kSpeciesImageHeight[sp]
                                                ?? app_data.kSpeciesImageHeightDefault,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              onChanged: (v) => setDialogState(() => selectedSpecies = v),
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
                              onPressed: () {
                                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                                if (qty <= 0) return;
                                setState(() {
                                  _addedFish[selectedSpecies] =
                                      (_addedFish[selectedSpecies] ?? 0) + qty;
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
                                      '${selectedSpecies}: $qty шт. добавлено',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                );
                              },
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
