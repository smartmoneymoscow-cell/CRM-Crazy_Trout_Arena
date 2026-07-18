// ============================================================================
// pond_stats.dart — статистика клиентов на пруду (единый источник).
//
// Ранее дублировалась в report_screen.dart и checks_screen.dart (~200 строк
// копипасты). Теперь все экраны импортируют отсюда.
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'demo_data.dart' as app_data show kDemoClients;

// ─── Модель статистики клиента на пруду ─────────────────────────────────────
class PondStats {
  final Color color;
  final LevelKey level;
  final int points, pointsNext, visits, ltvK, fish, totalWeight;
  final String firstVisit, lastVisit, email;
  final BestCatch bestCatch;
  final int? currentSector;
  const PondStats({
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

// ─── Полная модель клиента (Client + PondStats) ─────────────────────────────
class FullClient {
  final int id;
  final String name, phone, email, tariff, firstVisit, lastVisit;
  final Color color;
  final LevelKey level;
  final int points, pointsNext, visits, ltvK, fish, totalWeight;
  final BestCatch bestCatch;
  final int? currentSector;
  final String? avatarAsset;
  const FullClient({
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

// ─── Демо-данные статистики ─────────────────────────────────────────────────
const Map<int, PondStats> kPondStatsById = {
  1: PondStats(
    color: Color(0xFFE89829),
    level: LevelKey.premium,
    points: 1280, pointsNext: 1500, visits: 42, ltvK: 120,
    fish: 96, totalWeight: 215,
    firstVisit: '14.03.2023', lastVisit: '15.07.2026',
    email: 'ivanov@mail.ru', currentSector: 7,
    bestCatch: BestCatch(species: 'Осётр', weight: '6.2 кг', sector: 7, date: '02.07.2026'),
  ),
  2: PondStats(
    color: Color(0xFF3FA66B),
    level: LevelKey.standard,
    points: 640, pointsNext: 1000, visits: 18, ltvK: 54,
    fish: 31, totalWeight: 78,
    firstVisit: '02.08.2024', lastVisit: '15.07.2026',
    email: 'koshkin@mail.ru', currentSector: 4,
    bestCatch: BestCatch(species: 'Карп', weight: '3.4 кг', sector: 4, date: '28.06.2026'),
  ),
  3: PondStats(
    color: Color(0xFF2A6A7E),
    level: LevelKey.premium,
    points: 1410, pointsNext: 1500, visits: 55, ltvK: 1200,
    fish: 122, totalWeight: 289,
    firstVisit: '27.01.2022', lastVisit: '14.07.2026',
    email: 'petrov@mail.ru', currentSector: 2,
    bestCatch: BestCatch(species: 'Осётр', weight: '7.8 кг', sector: 2, date: '19.06.2026'),
  ),
  4: PondStats(
    color: Color(0xFF9C5A3C),
    level: LevelKey.basic,
    points: 30, pointsNext: 500, visits: 1, ltvK: 2,
    fish: 3, totalWeight: 5,
    firstVisit: '14.07.2026', lastVisit: '14.07.2026',
    email: 'kryukova@mail.ru',
    bestCatch: BestCatch(species: 'Линь', weight: '1.1 кг', sector: 9, date: '14.07.2026'),
  ),
  5: PondStats(
    color: Color(0xFF886F11),
    level: LevelKey.standard,
    points: 780, pointsNext: 1000, visits: 21, ltvK: 68,
    fish: 40, totalWeight: 103,
    firstVisit: '11.11.2023', lastVisit: '13.07.2026',
    email: 'laguta@mail.ru', currentSector: 5,
    bestCatch: BestCatch(species: 'Амур', weight: '4.9 кг', sector: 5, date: '30.06.2026'),
  ),
  6: PondStats(
    color: Color(0xFFB8862E),
    level: LevelKey.premium,
    points: 1500, pointsNext: 1500, visits: 68, ltvK: 2400,
    fish: 150, totalWeight: 365,
    firstVisit: '03.06.2021', lastVisit: '15.07.2026',
    email: 'orlov@mail.ru', currentSector: 1,
    bestCatch: BestCatch(species: 'Осётр', weight: '8.4 кг', sector: 1, date: '24.06.2026'),
  ),
  7: PondStats(
    color: Color(0xFF6B7280),
    level: LevelKey.basic,
    points: 260, pointsNext: 500, visits: 7, ltvK: 15,
    fish: 12, totalWeight: 22,
    firstVisit: '09.02.2026', lastVisit: '10.07.2026',
    email: 'sidorov@mail.ru', currentSector: 10,
    bestCatch: BestCatch(species: 'Линь', weight: '1.6 кг', sector: 10, date: '11.06.2026'),
  ),
  8: PondStats(
    color: Color(0xFF9C5A3C),
    level: LevelKey.standard,
    points: 520, pointsNext: 1000, visits: 14, ltvK: 46,
    fish: 27, totalWeight: 61,
    firstVisit: '18.01.2025', lastVisit: '12.07.2026',
    email: 'shchukin@mail.ru', currentSector: 8,
    bestCatch: BestCatch(species: 'Щука', weight: '4.1 кг', sector: 8, date: '15.06.2026'),
  ),
  100: PondStats(
    color: Color(0xFF8C5C34),
    level: LevelKey.basic,
    points: 40, pointsNext: 500, visits: 1, ltvK: 1,
    fish: 2, totalWeight: 3,
    firstVisit: '10.07.2026', lastVisit: '10.07.2026',
    email: 'guest@crazytroutarena.ru', currentSector: 3,
    bestCatch: BestCatch(species: 'Карп', weight: '0.9 кг', sector: 3, date: '10.07.2026'),
  ),
};

// ─── Фабрика: собираем FullClient из Client + PondStats ─────────────────────
const PondStats _defaultStats = PondStats(
  color: Color(0xFF8B94A0),
  level: LevelKey.basic,
  points: 0, pointsNext: 500, visits: 0, ltvK: 0,
  fish: 0, totalWeight: 0,
  firstVisit: '—', lastVisit: '—', email: '—',
  bestCatch: BestCatch(species: '—', weight: '—', sector: 0, date: '—'),
);

final List<FullClient> kFullClients = app_data.kDemoClients.map((c) {
  final s = kPondStatsById[c.id] ?? _defaultStats;
  return FullClient(
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
    lastVisit: s.lastVisit,
    bestCatch: s.bestCatch,
    currentSector: s.currentSector,
  );
}).toList();

/// Поиск полного клиента по id.
FullClient? findFullClient(int id) {
  for (final c in kFullClients) {
    if (c.id == id) return c;
  }
  return null;
}

/// Форматирование LTV для отображения.
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
