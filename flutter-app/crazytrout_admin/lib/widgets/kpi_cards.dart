import 'package:flutter/material.dart';
import '../data/finance_kpi_stats.dart';

const _ink = Color(0xFF14130F);
const _paper = Color(0xFFFBF6EC);
const _orange = Color(0xFFE8912B);
const _hairline2 = Color(0xFFE7E0D1);
const _muted = Color(0xFF8C8576);
const _muted2 = Color(0xFF9C9484);
const _green = Color(0xFF4F9D75);
const _greenLight = Color(0xFFE8F5EE);

class KpiCards extends StatelessWidget {
  final FinanceKpiStats stats;
  const KpiCards({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _KpiCard(
              icon: Icons.receipt_long_outlined, iconColor: _orange,
              title: 'Средний чек',
              value: '${_fmtMoney(stats.avgCheck.round())} ₽',
              subtitle: '${stats.paymentsCount} оплат',
              delta: '+4,3%', deltaPositive: true,
            )),
            const SizedBox(width: 10),
            Expanded(child: _KpiCard(
              icon: Icons.calendar_month_outlined, iconColor: const Color(0xFF4A7C59),
              title: 'LT / LTV',
              value: '${stats.avgVisits.toStringAsFixed(1)} / ${_fmtMoney(stats.avgLtv.round())} ₽',
              subtitle: 'среднее на клиента',
              delta: '+18,3%', deltaPositive: true,
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _KpiCard(
              icon: Icons.people_outline, iconColor: const Color(0xFF6B4226),
              title: 'Всего клиентов',
              value: '${stats.totalClients}',
              subtitle: '${stats.returnPct.toStringAsFixed(0)}% возвращаются',
              delta: '+12', deltaPositive: true,
            )),
            const SizedBox(width: 10),
            Expanded(child: _KpiCard(
              icon: Icons.star_rounded, iconColor: _orange,
              title: 'Оценка сервиса',
              value: stats.avgRating.toStringAsFixed(1).replaceAll('.', ','),
              subtitle: '${stats.reviewsCount} отзывов',
              stars: stats.avgRating,
            )),
          ],
        ),
        const SizedBox(height: 10),
        _KpiCard(
          icon: Icons.set_meal_outlined, iconColor: const Color(0xFF4A7C59),
          title: 'Средний улов на клиента',
          value: '${stats.avgFishPerClient.toStringAsFixed(1).replaceAll('.', ',')} кг',
          delta: '+9,7%', deltaPositive: true, wide: true,
        ),
      ],
    );
  }

  String _fmtMoney(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String? subtitle;
  final String? delta;
  final bool deltaPositive;
  final double? stars;
  final bool wide;

  const _KpiCard({
    required this.icon, required this.iconColor, required this.title,
    required this.value, this.subtitle, this.delta, this.deltaPositive = true,
    this.stars, this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _hairline2, width: 0.5),
      ),
      child: wide ? _buildWide() : _buildCompact(),
    );
  }

  Widget _buildCompact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _muted))),
        ]),
        const SizedBox(height: 12),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Row(children: [
          if (subtitle != null) Expanded(child: Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: _muted2))),
          if (delta != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: deltaPositive ? _greenLight : const Color(0xFFFDEAEA), borderRadius: BorderRadius.circular(6)),
            child: Text(delta!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: deltaPositive ? _green : const Color(0xFFC0392B))),
          ),
        ]),
        if (stars != null) ...[const SizedBox(height: 8), _StarRating(rating: stars!)],
      ],
    );
  }

  Widget _buildWide() {
    return Row(children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 22, color: iconColor),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _muted)),
        const SizedBox(height: 4),
        Row(children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.3)),
          if (delta != null) ...[
            const SizedBox(width: 10),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: deltaPositive ? _greenLight : const Color(0xFFFDEAEA), borderRadius: BorderRadius.circular(6)),
              child: Text(delta!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: deltaPositive ? _green : const Color(0xFFC0392B))),
            ),
            const SizedBox(width: 6),
            const Text('к прошлому периоду', style: TextStyle(fontSize: 11, color: _muted2)),
          ],
        ]),
      ])),
    ]);
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(children: List.generate(5, (i) {
      final filled = rating - i;
      return Padding(padding: const EdgeInsets.only(right: 2), child: Icon(
        filled >= 0.75 ? Icons.star_rounded : filled >= 0.25 ? Icons.star_half_rounded : Icons.star_border_rounded,
        size: 18, color: filled > 0 ? _orange : _muted2,
      ));
    }));
  }
}
