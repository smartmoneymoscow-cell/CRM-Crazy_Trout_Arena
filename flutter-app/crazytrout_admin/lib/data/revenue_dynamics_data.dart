// ============================================================================
// revenue_dynamics_data.dart — Агрегация динамики выручки по периодам.
// ============================================================================

import '../data/demo_receipts.dart';

class PeriodPoint {
  final String label;
  final double revenue;
  final double margin;
  final double expenses;

  const PeriodPoint({
    required this.label,
    required this.revenue,
    required this.margin,
    required this.expenses,
  });
}

class RevenueDynamicsData {
  final List<PeriodPoint> monthly;
  final List<PeriodPoint> weekly;

  const RevenueDynamicsData({required this.monthly, required this.weekly});
}

RevenueDynamicsData buildRevenueDynamicsData() {
  final monthMap = <String, double>{};
  for (final r in kDemoReceipts) {
    final key = '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}';
    monthMap[key] = (monthMap[key] ?? 0) + r.total;
  }

  final monthLabels = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл'];
  final sortedKeys = monthMap.keys.toList()..sort();
  final monthly = <PeriodPoint>[];
  for (int i = 0; i < sortedKeys.length && i < monthLabels.length; i++) {
    final k = sortedKeys[i];
    final rev = monthMap[k] ?? 0;
    monthly.add(PeriodPoint(
      label: monthLabels[i],
      revenue: rev,
      margin: rev * 0.45,
      expenses: rev * 0.55,
    ));
  }

  if (monthly.length < 7) {
    const mockMonthly = [
      PeriodPoint(label: 'Янв', revenue: 280000, margin: 126000, expenses: 154000),
      PeriodPoint(label: 'Фев', revenue: 310000, margin: 139500, expenses: 170500),
      PeriodPoint(label: 'Мар', revenue: 340000, margin: 153000, expenses: 187000),
      PeriodPoint(label: 'Апр', revenue: 295000, margin: 132750, expenses: 162250),
      PeriodPoint(label: 'Май', revenue: 380000, margin: 171000, expenses: 209000),
      PeriodPoint(label: 'Июн', revenue: 420000, margin: 189000, expenses: 231000),
      PeriodPoint(label: 'Июл', revenue: 412800, margin: 186240, expenses: 226560),
    ];
    return RevenueDynamicsData(monthly: mockMonthly, weekly: _mockWeekly());
  }
  return RevenueDynamicsData(monthly: monthly, weekly: _mockWeekly());
}

List<PeriodPoint> _mockWeekly() => const [
  PeriodPoint(label: '1', revenue: 85000, margin: 38250, expenses: 46750),
  PeriodPoint(label: '2', revenue: 92000, margin: 41400, expenses: 50600),
  PeriodPoint(label: '3', revenue: 110000, margin: 49500, expenses: 60500),
  PeriodPoint(label: '4', revenue: 98000, margin: 44100, expenses: 53900),
  PeriodPoint(label: '5', revenue: 105000, margin: 47250, expenses: 57750),
  PeriodPoint(label: '6', revenue: 120000, margin: 54000, expenses: 66000),
  PeriodPoint(label: '7', revenue: 115000, margin: 51750, expenses: 63250),
  PeriodPoint(label: '8', revenue: 95000, margin: 42750, expenses: 52250),
  PeriodPoint(label: '9', revenue: 108000, margin: 48600, expenses: 59400),
  PeriodPoint(label: '10', revenue: 102000, margin: 45900, expenses: 56100),
  PeriodPoint(label: '11', revenue: 125000, margin: 56250, expenses: 68750),
  PeriodPoint(label: '12', revenue: 130000, margin: 58500, expenses: 71500),
];
