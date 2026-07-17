// ============================================================================
// app_theme.dart — единые цветовые константы приложения.
//
// Ранее копипастились в report_screen.dart, checks_screen.dart,
// pond_map_screen.dart, revenue_dynamics_chart.dart, finance_pie_chart.dart
// и других виджетах. Теперь все импортируют отсюда.
// ============================================================================

import 'package:flutter/material.dart';

// ─── Основная палитра ───────────────────────────────────────────────────────
const Color kInk = Color(0xFF14130F);
const Color kPaper = Color(0xFFFBF6EC);
const Color kFill = Color(0xFFF3EEE4);
const Color kOrange = Color(0xFFE8912B);
const Color kEmber = Color(0xFF886F11);
const Color kHairline = Color(0xFFEFE8D8);
const Color kHairline2 = Color(0xFFE7E0D1);
const Color kOutline = Color(0xFFDDD3BC);
const Color kMuted = Color(0xFF8C8576);
const Color kMuted2 = Color(0xFF9C9484);
const Color kSelected = Color(0xFFEFD9AC);
const Color kWhite = Color(0xFFFFFFFF);
const Color kDelta = Color(0xFF4F9D75);
const Color kDeltaLabel = Color(0xFF8B8579);

// ─── Уровни клиентов ────────────────────────────────────────────────────────
enum LevelKey { premium, standard, basic }

class LevelStyle {
  final String label, letter;
  final Color color, medalTop, medalMid, medalBottom, letterColor, ring;
  const LevelStyle({
    required this.label,
    required this.letter,
    required this.color,
    required this.medalTop,
    required this.medalMid,
    required this.medalBottom,
    required this.letterColor,
    required this.ring,
  });
}

const Map<LevelKey, LevelStyle> kLevelStyles = <LevelKey, LevelStyle>{
  LevelKey.premium: LevelStyle(
    label: 'Премиум',
    letter: 'П',
    color: Color(0xFFB8862E),
    medalTop: Color(0xFFFFE18A),
    medalMid: Color(0xFFE0A62E),
    medalBottom: Color(0xFFAD7A16),
    letterColor: Color(0xFF4A3300),
    ring: Color(0xFFB8862E),
  ),
  LevelKey.standard: LevelStyle(
    label: 'Стандарт',
    letter: 'С',
    color: Color(0xFF8B94A0),
    medalTop: Color(0xFFF2F5F8),
    medalMid: Color(0xFFC9D1D9),
    medalBottom: Color(0xFF98A2AD),
    letterColor: Color(0xFF2E3438),
    ring: Color(0xFF8B94A0),
  ),
  LevelKey.basic: LevelStyle(
    label: 'Базовый',
    letter: 'Б',
    color: Color(0xFF8C5C34),
    medalTop: Color(0xFFE3B98B),
    medalMid: Color(0xFFC08A54),
    medalBottom: Color(0xFF8C5C34),
    letterColor: Color(0xFFFFFFFF),
    ring: Color(0xFF8C5C34),
  ),
};

// ─── BestCatch — общий для карты, чеков и отчёта ────────────────────────────
class BestCatch {
  final String species, weight, date;
  final int sector;
  const BestCatch({
    required this.species,
    required this.weight,
    required this.sector,
    required this.date,
  });
}
