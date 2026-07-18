// ============================================================================
// active_dot.dart — Единый индикатор активного фильтра.
//
// Оранжевая точка 7×7 в правом верхнем углу кнопки.
// Используется на ВСЕХ экранах: Чеки, Отчёт, Карта пруда.
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActiveDot extends StatelessWidget {
  const ActiveDot({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 7,
      right: 7,
      child: SizedBox(
        width: 7,
        height: 7,
        child: DecoratedBox(
          decoration: BoxDecoration(color: kOrange, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
