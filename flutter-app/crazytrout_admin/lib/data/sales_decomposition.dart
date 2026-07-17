// ============================================================================
// sales_decomposition.dart — Декомпозиция продаж: выручка по породам рыб
// + оплата за вход на пруд.
//
// Агрегирует данные из demo_receipts.dart.
// В production заменяется на выборку из backend.
// ============================================================================

import 'package:flutter/material.dart';
import '../data/demo_receipts.dart';

class SalesSegment {
  final String label;
  final double amount;
  final String? colorHex; // для кастомных цветов извне (необязательно)

  const SalesSegment({
    required this.label,
    required this.amount,
    this.colorHex,
  });
}

class SalesDecomposition {
  final List<SalesSegment> segments;
  final double total;

  const SalesDecomposition({required this.segments, required this.total});

  double pct(SalesSegment s) => total > 0 ? (s.amount / total * 100) : 0;
}

/// Строит декомпозицию из демо-чеков.
/// [dateRange] — если задан, фильтрует чеки по дате.
SalesDecomposition buildSalesDecomposition({DateTimeRange? dateRange}) {
  double entryTotal = 0;
  final fishMap = <String, double>{};

  for (final r in kDemoReceipts) {
    // Фильтр по дате
    if (dateRange != null) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      final s = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
      final e = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);
      if (d.isBefore(s) || d.isAfter(e)) continue;
    }

    // Вход (тариф)
    entryTotal += r.tariffPrice;

    // Рыба
    for (final row in r.rows) {
      fishMap[row.name] = (fishMap[row.name] ?? 0) + row.sum;
    }
  }

  // Сортируем рыбу по убыванию выручки
  final fishEntries = fishMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final segments = <SalesSegment>[
    for (final e in fishEntries)
      SalesSegment(label: e.key, amount: e.value),
    if (entryTotal > 0)
      SalesSegment(label: 'Вход на пруд', amount: entryTotal),
  ];

  final total = segments.fold<double>(0, (s, e) => s + e.amount);

  return SalesDecomposition(segments: segments, total: total);
}
