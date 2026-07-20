import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/sales_decomposition.dart';
import '../utils/format.dart';
import '../theme/app_theme.dart';

// ============================================================================
// FinancePieChart — «Структура выручки».
//
// Премиальная композиция: крупная донат-диаграмма с процентами прямо на
// сегментах, сверху; под ней — легенда в виде аккуратной «таблицы»
// (категория / доля / выручка целиком / количество шт.) с шапкой колонок
// и итоговой строкой, без сокращений и переносов.
// ============================================================================

// ─── Премиальная палитра сегментов (тёплое золото/медь — в стиле бренда) ───
// «Вход» всегда получает отдельный, холодный графитовый акцент, чтобы
// визуально отделять «плату за вход» от выручки по видам рыбы.
const _fishPalette = <Color>[
  Color(0xFFE8912B), // золото (kOrange) — топ-категория
  Color(0xFFB8862E), // тёмное золото
  Color(0xFF9C5A3C), // медь
  Color(0xFFCBA35C), // светлое золото
  Color(0xFF6B4226), // тёмный шоколад
];
const _entryColor = Color(0xFF3D3A33); // графит — «Вход»

const _fishGradients = <List<Color>>[
  [Color(0xFFF2A84D), Color(0xFFE8912B)],
  [Color(0xFFD3A24E), Color(0xFFB8862E)],
  [Color(0xFFB87050), Color(0xFF9C5A3C)],
  [Color(0xFFE0C48A), Color(0xFFCBA35C)],
  [Color(0xFF8B5A3A), Color(0xFF6B4226)],
];
const _entryGradient = [Color(0xFF524E44), Color(0xFF3D3A33)];

List<Color> _colorFor(int i, String label) =>
    label == 'Вход' ? [_entryColor] : [_fishPalette[i % _fishPalette.length]];

List<Color> _gradientFor(int i, String label) =>
    label == 'Вход' ? _entryGradient : _fishGradients[i % _fishGradients.length];

class FinancePieChart extends StatelessWidget {
  final SalesDecomposition data;
  const FinancePieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Реальные цвета сегментов (по индексу, с учётом спец-цвета «Вход»)
    final segColors = <Color>[
      for (int i = 0; i < data.segments.length; i++)
        _colorFor(i, data.segments[i].label).first,
    ];
    final segGradients = <List<Color>>[
      for (int i = 0; i < data.segments.length; i++)
        _gradientFor(i, data.segments[i].label),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kHairline2, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Структура выручки',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
        const SizedBox(height: 4),
        Text('за выбранный период',
          style: const TextStyle(fontSize: 12, color: kMuted2)),
        const SizedBox(height: 20),

        // ── Крупная диаграмма сверху, по центру ──
        LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final donutSize = w < 340 ? 180.0 : w < 400 ? 200.0 : 216.0;
          return Center(
            child: _DonutWithGlow(
              size: donutSize,
              data: data,
              colors: segColors,
              gradients: segGradients,
            ),
          );
        }),

        const SizedBox(height: 26),

        // ── Легенда-«таблица» ──
        _LegendTable(data: data, colors: segColors),
      ]),
    );
  }
}

// ─── Донат с мягким свечением позади (в духе hero-карточки выручки) ─────────
class _DonutWithGlow extends StatelessWidget {
  final double size;
  final SalesDecomposition data;
  final List<Color> colors;
  final List<List<Color>> gradients;
  const _DonutWithGlow({
    required this.size,
    required this.data,
    required this.colors,
    required this.gradients,
  });

  @override
  Widget build(BuildContext context) {
    final glowSize = size * 1.28;
    return SizedBox(
      width: glowSize,
      height: glowSize,
      child: Stack(alignment: Alignment.center, children: [
        // Мягкое золотое свечение позади диаграммы
        Container(
          width: glowSize,
          height: glowSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [kOrange.withOpacity(0.14), kOrange.withOpacity(0.0)],
              stops: const [0.0, 0.75],
            ),
          ),
        ),
        SizedBox(
          width: size,
          height: size,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: Size(size, size),
              painter: _DonutPainter(
                segments: data.segments,
                colors: colors,
                gradients: gradients,
                total: data.total,
              ),
            ),
            // ── Центр: итоговая сумма ──
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('ВСЕГО',
                style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w700,
                  color: kMuted2, letterSpacing: 1.2,
                )),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(money(data.total),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: kInk, letterSpacing: -0.4,
                      fontFeatures: [FontFeature.tabularFigures()],
                    )),
                ),
              ),
              const SizedBox(height: 3),
              Text('${data.segments.length} категори${_ruPlural(data.segments.length)}',
                style: const TextStyle(fontSize: 10.5, color: kMuted2, fontWeight: FontWeight.w500)),
            ]),
          ]),
        ),
      ]),
    );
  }

  String _ruPlural(int n) {
    final n10 = n % 10, n100 = n % 100;
    if (n10 == 1 && n100 != 11) return 'я';
    if (n10 >= 2 && n10 <= 4 && (n100 < 10 || n100 >= 20)) return 'и';
    return 'й';
  }
}

// ─── Отрисовка кольца + подписи процентов прямо на сегментах ───────────────
class _DonutPainter extends CustomPainter {
  final List<SalesSegment> segments;
  final List<Color> colors;
  final List<List<Color>> gradients;
  final double total;
  _DonutPainter({
    required this.segments,
    required this.colors,
    required this.gradients,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = size.width * 0.155;
    final r = radius - strokeWidth / 2 - 2;

    if (total <= 0 || segments.isEmpty) {
      canvas.drawCircle(center, r, Paint()
        ..color = const Color(0xFFE1DCCF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth);
      return;
    }

    double startAngle = -math.pi / 2;
    final labels = <_PctLabel>[];

    for (int i = 0; i < segments.length; i++) {
      final frac = segments[i].amount / total;
      final sweep = 2 * math.pi * frac;
      final gradColors = gradients[i];

      // Дуга сегмента
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle,
        sweep,
        false,
        Paint()
          ..shader = (gradColors.length > 1
              ? LinearGradient(
                  colors: gradColors,
                  begin: Alignment(math.cos(startAngle), math.sin(startAngle)),
                  end: Alignment(math.cos(startAngle + sweep), math.sin(startAngle + sweep)),
                ).createShader(Rect.fromCircle(center: center, radius: radius))
              : null)
          ..color = gradColors.length == 1 ? gradColors.first : kWhite
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );

      // Тонкий белый разделитель между секторами
      if (sweep > 0.02 && segments.length > 1) {
        final sepAngle = startAngle + sweep;
        canvas.drawLine(
          center + Offset(math.cos(sepAngle) * (r - strokeWidth / 2 - 1),
              math.sin(sepAngle) * (r - strokeWidth / 2 - 1)),
          center + Offset(math.cos(sepAngle) * (r + strokeWidth / 2 + 1),
              math.sin(sepAngle) * (r + strokeWidth / 2 + 1)),
          Paint()..color = kPaper..strokeWidth = 3..strokeCap = StrokeCap.round,
        );
      }

      // Подпись процента — только если сегмент достаточно крупный,
      // чтобы цифры не налезали друг на друга и не обрезались.
      if (frac >= 0.06) {
        final midAngle = startAngle + sweep / 2;
        final labelPos = center + Offset(math.cos(midAngle) * r, math.sin(midAngle) * r);
        final baseColor = colors[i];
        final textColor = baseColor.computeLuminance() > 0.42 ? kInk : kWhite;
        labels.add(_PctLabel(
          pos: labelPos,
          text: '${(frac * 100).toStringAsFixed(0)}%',
          color: textColor,
        ));
      }

      startAngle += sweep;
    }

    // Подписи рисуются отдельным проходом — поверх всех дуг,
    // чтобы разделительные линии их не перекрывали.
    for (final l in labels) {
      final tp = TextPainter(
        text: TextSpan(
          text: l.text,
          style: TextStyle(
            fontSize: strokeWidth * 0.34,
            fontWeight: FontWeight.w800,
            color: l.color,
            letterSpacing: -0.2,
            shadows: [
              Shadow(
                color: (l.color == kWhite ? Colors.black : Colors.white).withOpacity(0.35),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, l.pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments || old.total != total;
}

class _PctLabel {
  final Offset pos;
  final String text;
  final Color color;
  _PctLabel({required this.pos, required this.text, required this.color});
}

// ============================================================================
// _LegendTable — премиальная легенда в виде таблицы: категория, доля,
// выручка целиком, количество (шт. рыбы / входов). Без сокращений и
// переносов; с шапкой колонок и итоговой строкой.
// ============================================================================
class _LegendTable extends StatelessWidget {
  final SalesDecomposition data;
  final List<Color> colors;
  const _LegendTable({required this.data, required this.colors});

  static const _headerStyle = TextStyle(
    fontSize: 10.5, fontWeight: FontWeight.w700,
    color: kMuted2, letterSpacing: 0.4,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kFill,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      // Table с IntrinsicColumnWidth для числовых колонок: они всегда
      // ровно по ширине своего содержимого (без обрезаний и переносов —
      // ни на одном размере экрана), а колонка «Категория» забирает
      // весь оставшийся горизонтальный простор.
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(20),
          1: FlexColumnWidth(),
          2: IntrinsicColumnWidth(),
          3: IntrinsicColumnWidth(),
        },
        children: [
          _headerRow(),
          _dividerRow(topPad: 8, bottomPad: 8),
          for (int i = 0; i < data.segments.length; i++)
            _dataRow(
              color: colors[i],
              label: data.segments[i].label,
              pct: data.pct(data.segments[i]),
              amount: data.segments[i].amount,
              qty: data.segments[i].qty,
              qtyUnit: data.segments[i].qtyUnit,
              bold: false,
              padTop: i == 0 ? 0 : 6.5,
              padBottom: 6.5,
            ),
          _dividerRow(topPad: 4, bottomPad: 10),
          _dataRow(
            color: null,
            label: 'Итого',
            pct: 100,
            amount: data.total,
            qty: data.totalQty,
            qtyUnit: 'шт.',
            bold: true,
            padTop: 0,
            padBottom: 0,
          ),
        ],
      ),
    );
  }

  TableRow _headerRow() => TableRow(children: [
    const SizedBox(),
    const Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Text('КАТЕГОРИЯ', style: _headerStyle),
    ),
    const Padding(
      padding: EdgeInsets.only(left: 12, bottom: 4),
      child: Text('ВЫРУЧКА', textAlign: TextAlign.right, style: _headerStyle),
    ),
    const Padding(
      padding: EdgeInsets.only(left: 12, bottom: 4),
      child: Text('КОЛ-ВО', textAlign: TextAlign.right, style: _headerStyle),
    ),
  ]);

  TableRow _dividerRow({required double topPad, required double bottomPad}) {
    Widget line() => Padding(
      padding: EdgeInsets.only(top: topPad, bottom: bottomPad),
      child: Container(height: 1, color: kHairline2),
    );
    return TableRow(children: [line(), line(), line(), line(), line()]);
  }

  TableRow _dataRow({
    required Color? color,
    required String label,
    required double pct,
    required double amount,
    required int qty,
    required String qtyUnit,
    required bool bold,
    required double padTop,
    required double padBottom,
  }) {
    final labelStyle = TextStyle(
      fontSize: 13.5,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      color: kInk,
    );
    final amtStyle = TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
      color: kInk,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final pctStyle = TextStyle(
      fontSize: 12.5,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      color: bold ? kInk : kMuted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final qtyStyle = TextStyle(
      fontSize: 12,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      color: bold ? kInk : kMuted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    EdgeInsets pad([double left = 0]) =>
        EdgeInsets.only(left: left, top: padTop, bottom: padBottom);

    return TableRow(children: [
      Padding(
        padding: pad(),
        child: color != null
            ? Container(width: 10, height: 10,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)))
            : const SizedBox(width: 10, height: 10),
      ),
      Padding(
        padding: pad(10),
        child: Text(label, maxLines: 1, softWrap: false, overflow: TextOverflow.visible,
          style: labelStyle),
      ),
      Padding(
        padding: pad(12),
        child: Text(money(amount), textAlign: TextAlign.right, maxLines: 1,
          softWrap: false, overflow: TextOverflow.visible, style: amtStyle),
      ),
      Padding(
        padding: pad(12),
        child: Text('$qty $qtyUnit', textAlign: TextAlign.right, maxLines: 1,
          softWrap: false, overflow: TextOverflow.visible, style: qtyStyle),
      ),
    ]);
  }
}

String _fmtPct(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
