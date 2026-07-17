// ============================================================================
// demo_finance_stats.dart — Демо-данные для финансового дашборда экрана
// «Отчёт» (вкладка «Финансы и метрики»).
//
// buildFinanceStats() — динамическая версия, фильтрует kDemoReceipts
// по dateRange. kDemoFinanceStats оставлен как fallback.
// ============================================================================

import 'package:flutter/material.dart';
import '../data/demo_receipts.dart';
import '../models/receipt_history.dart';
import '../models/receipt_history.dart';

class FinanceStats {
  final double revenue;         // выручка за период, ₽
  final double revenueDeltaPct; // изменение к прошлому периоду, %
  final double marginProfit;    // маржинальная прибыль, ₽
  final double variableExpenses; // переменные расходы, ₽

  // Точки для спарклайна тренда выручки, нормализованные 0..1
  final List<double> sparkline;

  const FinanceStats({
    required this.revenue,
    required this.revenueDeltaPct,
    required this.marginProfit,
    required this.variableExpenses,
    required this.sparkline,
  });

  double get marginPct =>
      revenue > 0 ? (marginProfit / revenue * 100) : 0;

  double get expensesPct =>
      revenue > 0 ? (variableExpenses / revenue * 100) : 0;
}

const kDemoFinanceStats = FinanceStats(
  revenue: 412800,
  revenueDeltaPct: 12.4,
  marginProfit: 186240,
  variableExpenses: 226560,
  sparkline: [
    0.32, 0.22, 0.40, 0.34, 0.34, 0.58,
    0.62, 0.40, 0.46, 0.86, 0.94, 1.00,
  ],
);

/// Строит FinanceStats из демо-чеков с фильтрацией по [dateRange].
/// Если dateRange == null, берёт все чеки.
FinanceStats buildFinanceStats({DateTimeRange? dateRange}) {
  // ── Фильтрация чеков ──
  final filtered = <ReceiptHistoryItem>[];
  final prevFiltered = <ReceiptHistoryItem>[];

  // Длительность периода для расчёта «прошлого периода»
  Duration periodDuration;
  if (dateRange != null) {
    periodDuration = dateRange.end.difference(dateRange.start);
  } else {
    // Для «всего времени» — сравниваем с пустым прошлым периодом
    periodDuration = const Duration(days: 30);
  }

  for (final r in kDemoReceipts) {
    final d = DateTime(r.date.year, r.date.month, r.date.day);

    if (dateRange != null) {
      final s = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
      final e = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);

      // Текущий период
      if (!d.isBefore(s) && !d.isAfter(e)) {
        filtered.add(r);
      }

      // Прошлый период (той же длительности, перед текущим)
      final prevEnd = s.subtract(const Duration(days: 1));
      final prevStart = prevEnd.subtract(periodDuration);
      if (!d.isBefore(prevStart) && !d.isAfter(prevEnd)) {
        prevFiltered.add(r);
      }
    } else {
      filtered.add(r);
    }
  }

  // ── Вычисление выручки ──
  final revenue = filtered.fold<double>(0, (s, r) => s + r.total);
  final prevRevenue = prevFiltered.fold<double>(0, (s, r) => s + r.total);

  final deltaPct = prevRevenue > 0
      ? ((revenue - prevRevenue) / prevRevenue * 100)
      : (revenue > 0 ? 100.0 : 0.0);

  // ── Маржа и расходы (из данных чеков) ──
  // Маржинальная прибыль: выручка от рыбы (с наценкой) минус себестоимость
  // Условно: тариф — чистая маржа, рыба — 45% маржа
  double fishRevenue = 0;
  double tariffRevenue = 0;
  for (final r in filtered) {
    tariffRevenue += r.tariffPrice;
    for (final row in r.rows) {
      fishRevenue += row.sum;
    }
  }
  // Маржа: тариф 100% + рыба 45%
  final marginProfit = tariffRevenue + fishRevenue * 0.45;
  final variableExpenses = revenue - marginProfit;

  // ── Спарклайн (агрегация по дням) ──
  final dayMap = <String, double>{};
  for (final r in filtered) {
    final key = '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';
    dayMap[key] = (dayMap[key] ?? 0) + r.total;
  }

  List<double> sparkline;
  if (dayMap.length >= 2) {
    final sorted = dayMap.values.toList()..sort();
    final minVal = sorted.first;
    final maxVal = sorted.last;
    final range = maxVal - minVal;
    sparkline = dayMap.keys.toList()..sort();
    sparkline = (dayMap.keys.toList()..sort())
        .map((k) => range > 0 ? (dayMap[k]! - minVal) / range : 0.5)
        .toList();
  } else {
    // Недостаточно точек — рисуем ровную линию
    sparkline = [0.5, 0.5];
  }

  return FinanceStats(
    revenue: revenue,
    revenueDeltaPct: deltaPct,
    marginProfit: marginProfit,
    variableExpenses: variableExpenses,
    sparkline: sparkline,
  );
}
