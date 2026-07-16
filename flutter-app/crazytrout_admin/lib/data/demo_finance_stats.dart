// ============================================================================
// demo_finance_stats.dart — Демо-данные для финансового дашборда экрана
// «Отчёт» (вкладка «Финансы и метрики»).
//
// В production заменяется на выборку из backend за выбранный период.
// ============================================================================

class FinanceStats {
  final double revenue;         // выручка за период, ₽
  final double revenueDeltaPct; // изменение к прошлому периоду, %
  final double marginProfit;    // маржинальная прибыль, ₽
  final double variableExpenses; // переменные расходы, ₽

  // Точки для спарклайна тренда выручки, нормализованные 0..1
  // (0 — минимум графика, 1 — максимум).
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
