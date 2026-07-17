// ============================================================================
// finance_kpi_stats.dart — Агрегация KPI-метрик из демо-чеков.
// ============================================================================

import 'package:flutter/material.dart';
import '../data/demo_receipts.dart';
import '../data/demo_data.dart' as app_data show kDemoClients;

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
  final nonGuestReceipts = kDemoReceipts.where((r) {
    if (r.isGuest) return false;
    // Фильтр по дате
    if (dateRange != null) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      final s = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
      final e = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);
      if (d.isBefore(s) || d.isAfter(e)) return false;
    }
    return true;
  }).toList();

  final totalRevenue = nonGuestReceipts.fold<double>(0, (s, r) => s + r.total);
  final avgCheck = nonGuestReceipts.isNotEmpty
      ? totalRevenue / nonGuestReceipts.length
      : 0.0;

  const visitsMap = <int, int>{
    1: 42, 2: 18, 3: 55, 5: 21, 6: 68, 7: 7, 8: 14, 100: 1,
  };
  const ltvMap = <int, int>{
    1: 120, 2: 54, 3: 1200, 5: 68, 6: 2400, 7: 15, 8: 46, 100: 1,
  };

  final clients = app_data.kDemoClients;
  final clientVisits = <int>[];
  final clientLtv = <int>[];
  for (final c in clients) {
    final v = visitsMap[c.id] ?? 0;
    final l = ltvMap[c.id] ?? 0;
    if (v > 0) clientVisits.add(v);
    if (l > 0) clientLtv.add(l);
  }

  final avgVisits = clientVisits.isNotEmpty
      ? clientVisits.reduce((a, b) => a + b) / clientVisits.length
      : 0.0;
  final avgLtv = clientLtv.isNotEmpty
      ? clientLtv.reduce((a, b) => a + b) / clientLtv.length * 1000.0
      : 0.0;

  final totalClients = clients.length;
  final returning = clientVisits.where((v) => v > 1).length;
  final returnPct = totalClients > 0 ? returning / totalClients * 100 : 0.0;

  const fishMap = <int, double>{
    1: 215, 2: 78, 3: 289, 5: 103, 6: 365, 7: 22, 8: 61, 100: 3,
  };
  final fishWeights = fishMap.values.where((w) => w > 0).toList();
  final avgFish = fishWeights.isNotEmpty
      ? fishWeights.reduce((a, b) => a + b) / fishWeights.length
      : 0.0;

  const weightMap = <int, double>{
    1: 215, 2: 78, 3: 289, 5: 103, 6: 365, 7: 22, 8: 61, 100: 3,
  };
  final weights = weightMap.values.where((w) => w > 0).toList();
  final avgWeight = weights.isNotEmpty
      ? weights.reduce((a, b) => a + b) / weights.length
      : 0.0;

  return FinanceKpiStats(
    avgCheck: avgCheck,
    paymentsCount: nonGuestReceipts.length,
    avgVisits: avgVisits,
    avgLtv: avgLtv,
    totalClients: totalClients,
    returnPct: returnPct,
    avgRating: 4.6,
    reviewsCount: 128,
    avgFishPerClient: avgFish,
    avgWeightPerClient: avgWeight,
  );
}
