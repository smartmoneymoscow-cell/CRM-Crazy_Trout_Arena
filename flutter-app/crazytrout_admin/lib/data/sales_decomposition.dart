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
  final int qty;        // количество единиц (шт. рыбы / входов)
  final String qtyUnit; // подпись единицы измерения: 'шт.' / 'вход.'
  final String? colorHex; // для кастомных цветов извне (необязательно)

  const SalesSegment({
    required this.label,
    required this.amount,
    this.qty = 0,
    this.qtyUnit = 'шт.',
    this.colorHex,
  });
}

class SalesDecomposition {
  final List<SalesSegment> segments;
  final double total;

  const SalesDecomposition({required this.segments, required this.total});

  double pct(SalesSegment s) => total > 0 ? (s.amount / total * 100) : 0;

  int get totalQty => segments.fold<int>(0, (s, e) => s + e.qty);
}

/// Строит декомпозицию из демо-чеков.
/// [dateRange] — если задан, фильтрует чеки по дате.
SalesDecomposition buildSalesDecomposition({DateTimeRange? dateRange}) {
  double entryTotal = 0;
  int entryCount = 0;
  final fishAmountMap = <String, double>{};
  final fishQtyMap = <String, int>{};

  for (final r in kDemoReceipts) {
    // Фильтр по дате
    if (dateRange != null) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      final s = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
      final e = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);
      if (d.isBefore(s) || d.isAfter(e)) continue;
    }

    // Вход (тариф) — каждый чек с тарифом = один вход
    if (r.tariffPrice > 0) {
      entryTotal += r.tariffPrice;
      entryCount += 1;
    }

    // Рыба — каждая строка чека = одна выловленная рыба
    for (final row in r.rows) {
      fishAmountMap[row.name] = (fishAmountMap[row.name] ?? 0) + row.sum;
      fishQtyMap[row.name] = (fishQtyMap[row.name] ?? 0) + 1;
    }
  }

  // Сортируем рыбу по убыванию выручки
  final fishEntries = fishAmountMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final segments = <SalesSegment>[
    for (final e in fishEntries)
      SalesSegment(
        label: e.key,
        amount: e.value,
        qty: fishQtyMap[e.key] ?? 0,
        qtyUnit: 'шт.',
      ),
    if (entryTotal > 0)
      SalesSegment(
        label: 'Вход',
        amount: entryTotal,
        qty: entryCount,
        qtyUnit: 'вход.',
      ),
  ];

  final total = segments.fold<double>(0, (s, e) => s + e.amount);

  // Если нет данных за период — возвращаем демо-данные
  if (segments.isEmpty) {
    return const SalesDecomposition(
      segments: [
        SalesSegment(label: 'Осётр', amount: 168000, qty: 41, qtyUnit: 'шт.'),
        SalesSegment(label: 'Карп', amount: 95000, qty: 63, qtyUnit: 'шт.'),
        SalesSegment(label: 'Форель', amount: 52000, qty: 28, qtyUnit: 'шт.'),
        SalesSegment(label: 'Амур', amount: 47000, qty: 19, qtyUnit: 'шт.'),
        SalesSegment(label: 'Вход', amount: 50800, qty: 68, qtyUnit: 'вход.'),
      ],
      total: 412800,
    );
  }

  return SalesDecomposition(segments: segments, total: total);
}
