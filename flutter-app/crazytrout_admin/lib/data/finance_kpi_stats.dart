// ============================================================================
// finance_kpi_stats.dart — Агрегация KPI-метрик из демо-чеков.
//
// Все метрики фильтруются по dateRange.
// ============================================================================

import 'package:flutter/material.dart';
import '../data/demo_receipts.dart';

class FinanceKpiStats {
  final double avgCheck;
  final int paymentsCount;
  final double avgVisits;
  final double avgLtv;
  final int totalClients;
  final double returnPct;
  final double avgRating;
  final int reviewsCount;
  final double avgFishPerClient;
  final double avgWeightPerClient;

  const FinanceKpiStats({
    required this.avgCheck,
    required this.paymentsCount,
    required this.avgVisits,
    required this.avgLtv,
    required this.totalClients,
    required this.returnPct,
    required this.avgRating,
    required this.reviewsCount,
    required this.avgFishPerClient,
    required this.avgWeightPerClient,
  });
}

/// Строит KPI-статистику из демо-чеков.
/// [dateRange] — если задан, фильтрует чеки по дате.
FinanceKpiStats buildFinanceKpiStats({DateTimeRange? dateRange}) {
  // ── Фильтрация чеков (без гостей для большинства метрик) ──
  final nonGuestReceipts = kDemoReceipts.where((r) {
    if (r.isGuest) return false;
    if (dateRange != null) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      final s = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
      final e = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);
      if (d.isBefore(s) || d.isAfter(e)) return false;
    }
    return true;
  }).toList();

  // Все чеки (включая гостей) — для общего количества
  final allFiltered = kDemoReceipts.where((r) {
    if (dateRange != null) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      final s = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
      final e = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);
      if (d.isBefore(s) || d.isAfter(e)) return false;
    }
    return true;
  }).toList();

  // ── Средний чек и количество оплат ──
  final totalRevenue = allFiltered.fold<double>(0, (s, r) => s + r.total);
  final avgCheck = allFiltered.isNotEmpty ? totalRevenue / allFiltered.length : 0.0;
  final paymentsCount = allFiltered.length;

  // Если нет данных за период — возвращаем дефолтные метрики
  if (allFiltered.isEmpty) {
    return const FinanceKpiStats(
      avgCheck: 3850,
      paymentsCount: 0,
      avgVisits: 4.2,
      avgLtv: 58000,
      totalClients: 0,
      returnPct: 0,
      avgRating: 4.5,
      reviewsCount: 0,
      avgFishPerClient: 0,
      avgWeightPerClient: 0,
    );
  }

  // ── Визиты на клиента (сколько раз каждый клиент приходил в периоде) ──
  final clientVisitCount = <int, int>{};
  for (final r in nonGuestReceipts) {
    if (r.client != null) {
      clientVisitCount[r.client!.id] = (clientVisitCount[r.client!.id] ?? 0) + 1;
    }
  }
  final visitCounts = clientVisitCount.values.toList();
  final avgVisits = visitCounts.isNotEmpty
      ? visitCounts.reduce((a, b) => a + b) / visitCounts.length
      : 0.0;

  // ── LTV на клиента (сколько потратил в периоде, в ₽) ──
  final clientSpending = <int, double>{};
  for (final r in nonGuestReceipts) {
    if (r.client != null) {
      clientSpending[r.client!.id] = (clientSpending[r.client!.id] ?? 0) + r.total;
    }
  }
  final spendingValues = clientSpending.values.toList();
  final avgLtv = spendingValues.isNotEmpty
      ? spendingValues.reduce((a, b) => a + b) / spendingValues.length
      : 0.0;

  // ── Уникальные клиенты и возвращаемость ──
  final totalClients = clientVisitCount.length;
  final returning = clientVisitCount.values.where((v) => v > 1).length;
  final returnPct = totalClients > 0 ? returning / totalClients * 100 : 0.0;

  // ── Улов на клиента ──
  double totalFishCount = 0;
  double totalFishWeight = 0;
  for (final r in nonGuestReceipts) {
    for (final row in r.rows) {
      totalFishCount += row.weight > 0 ? 1 : 0; // 1 позиция = ~1 шт
      totalFishWeight += row.weight;
    }
  }
  final avgFishPerClient = totalClients > 0 ? totalFishCount / totalClients : 0.0;
  final avgWeightPerClient = totalClients > 0 ? totalFishWeight / totalClients : 0.0;

  // ── Рейтинг (демо — привязан к количеству отзывов за период) ──
  // В реальном приложении — из таблицы отзывов
  final reviewsCount = allFiltered.length; // 1 чек = 1 отзыв (условно)
  final avgRating = reviewsCount > 0 ? (4.2 + (reviewsCount % 10) * 0.04).clamp(4.0, 5.0) : 0.0;

  return FinanceKpiStats(
    avgCheck: avgCheck,
    paymentsCount: paymentsCount,
    avgVisits: avgVisits,
    avgLtv: avgLtv,
    totalClients: totalClients,
    returnPct: returnPct,
    avgRating: avgRating,
    reviewsCount: reviewsCount,
    avgFishPerClient: avgFishPerClient,
    avgWeightPerClient: avgWeightPerClient,
  );
}
