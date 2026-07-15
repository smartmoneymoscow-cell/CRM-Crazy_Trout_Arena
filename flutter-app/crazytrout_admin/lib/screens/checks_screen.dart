import 'package:flutter/material.dart';

import '../data/demo_receipts.dart';
import '../models/client.dart';
import '../models/receipt_history.dart';
import '../services/print_route.dart' deferred as print_route;
import '../models/receipt.dart' as receipt_model;

// ============================================================================
// Экран «Чеки» — история выставленных чеков.
//
// Открывается по нажатию иконки «Чеки» в нижнем меню (см. home_shell.dart).
// Компонует:
//   • Поисковую строку (имя / телефон / сумма / дата),
//   • Три чипа-фильтра: «Период» (dropdown), «Календарь» (иконка → date range),
//     «Тип» (dropdown: С ФН / Без ФН),
//   • Ленту чеков,
//   • Экран деталей чека с превью и кнопкой AirPrint.
//
// Данные — из lib/data/demo_receipts.dart. В production заменяется на выборку
// из backend.
// ============================================================================

const _ink = Color(0xFF14130F);
const _paper = Color(0xFFFBF6EC);
const _fill = Color(0xFFF3EEE4);
const _orange = Color(0xFFE8912B);
const _hairline = Color(0xFFEFE8D8);
const _hairline2 = Color(0xFFE7E0D1);
const _outline = Color(0xFFDDD3BC);
const _muted = Color(0xFF8C8576);
const _muted2 = Color(0xFF9C9484);
const _selected = Color(0xFFEFD9AC);

enum _PeriodFilter { today, week, month, quarter }
enum _TypeFilter { fiscal, nonfiscal }

extension on _PeriodFilter {
  String get label => switch (this) {
        _PeriodFilter.today => 'За сегодня',
        _PeriodFilter.week => 'За неделю',
        _PeriodFilter.month => 'За месяц',
        _PeriodFilter.quarter => 'За квартал',
      };
}

extension on _TypeFilter {
  String get label =>
      this == _TypeFilter.fiscal ? 'С ФН' : 'Без ФН';
}

class ChecksScreen extends StatefulWidget {
  const ChecksScreen({super.key});

  @override
  State<ChecksScreen> createState() => _ChecksScreenState();
}

class _ChecksScreenState extends State<ChecksScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  _PeriodFilter? _period;
  _TypeFilter? _type;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------- фильтрация ----------
  bool _matchesQuery(ReceiptHistoryItem r) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    if (!r.isGuest && r.client != null) {
      if (r.client!.name.toLowerCase().contains(q)) return true;
      if (r.client!.phone.replaceAll(RegExp(r'\s|-|\(|\)'), '').contains(
          q.replaceAll(RegExp(r'\s|-|\(|\)'), ''))) {
        return true;
      }
    }
    if (r.total.round().toString().contains(q)) return true;
    final d = r.date;
    two(int n) => n.toString().padLeft(2, '0');
    final dateStr = '${two(d.day)}.${two(d.month)}.${d.year}';
    if (dateStr.contains(q)) return true;
    return false;
  }

  bool _matchesPeriod(ReceiptHistoryItem r) {
    if (_period == null) return true;
    final now = DateTime.now();
    final start = switch (_period!) {
      _PeriodFilter.today => DateTime(now.year, now.month, now.day),
      _PeriodFilter.week => now.subtract(const Duration(days: 7)),
      _PeriodFilter.month => now.subtract(const Duration(days: 30)),
      _PeriodFilter.quarter => now.subtract(const Duration(days: 90)),
    };
    return r.date.isAfter(start) || r.date.isAtSameMomentAs(start);
  }

  bool _matchesRange(ReceiptHistoryItem r) {
    if (_dateRange == null) return true;
    final d = DateTime(r.date.year, r.date.month, r.date.day);
    final s = DateTime(
        _dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
    final e = DateTime(
        _dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  bool _matchesType(ReceiptHistoryItem r) {
    if (_type == null) return true;
    return _type == _TypeFilter.fiscal ? r.fiscal : !r.fiscal;
  }

  List<ReceiptHistoryItem> get _filtered => kDemoReceipts
      .where((r) =>
          _matchesQuery(r) &&
          _matchesPeriod(r) &&
          _matchesRange(r) &&
          _matchesType(r))
      .toList();

  // ---------- поисковые подсказки клиентов ----------
  List<Client> get _clientSuggestions {
    if (_query.isEmpty) return const [];
    final q = _query.toLowerCase();
    final seen = <int>{};
    final res = <Client>[];
    for (final r in kDemoReceipts) {
      final c = r.client;
      if (c == null || seen.contains(c.id)) continue;
      if (c.name.toLowerCase().contains(q) || c.phone.contains(q)) {
        seen.add(c.id);
        res.add(c);
      }
    }
    return res.take(4).toList();
  }

  // ---------- открытия ----------
  Future<void> _openPeriodMenu(BuildContext anchor) async {
    final box = anchor.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    final res = await showMenu<_PeriodFilter?>(
      context: context,
      color: _fill,
      elevation: 8,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
      position: RelativeRect.fromLTRB(
          pos.dx, pos.dy + box.size.height, pos.dx + box.size.width, 0),
      constraints: BoxConstraints.tightFor(width: box.size.width),
      items: [
        for (final p in _PeriodFilter.values)
          PopupMenuItem<_PeriodFilter?>(
            value: p,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              p.label,
              style: TextStyle(
                fontSize: 14,
                color: _ink,
                fontWeight:
                    _period == p ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        if (_period != null)
          const PopupMenuItem<_PeriodFilter?>(
            value: null,
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('Сбросить',
                style: TextStyle(fontSize: 13, color: _muted2)),
          ),
      ],
    );
    if (!mounted) return;
    setState(() => _period = res);
  }

  Future<void> _openTypeMenu(BuildContext anchor) async {
    final box = anchor.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    final res = await showMenu<_TypeFilter?>(
      context: context,
      color: _fill,
      elevation: 8,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
      position: RelativeRect.fromLTRB(
          pos.dx, pos.dy + box.size.height, pos.dx + box.size.width, 0),
      constraints: BoxConstraints.tightFor(width: box.size.width),
      items: [
        for (final t in _TypeFilter.values)
          PopupMenuItem<_TypeFilter?>(
            value: t,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(t.label,
                style: TextStyle(
                    fontSize: 14,
                    color: _ink,
                    fontWeight:
                        _type == t ? FontWeight.w700 : FontWeight.w400)),
          ),
        if (_type != null)
          const PopupMenuItem<_TypeFilter?>(
            value: null,
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('Сбросить',
                style: TextStyle(fontSize: 13, color: _muted2)),
          ),
      ],
    );
    if (!mounted) return;
    setState(() => _type = res);
  }

  Future<void> _openCalendar() async {
    // Кастомный пагинируемый календарь — визуально идентичен _CalendarPicker
    // с экрана «Карта пруда» (та же карточка 300×auto, круглые стрелки
    // навигации по месяцам, оранжевый кружок на выбранном дне), но с
    // поддержкой диапазона: первый тап = начало периода, второй тап по
    // другой дате = конец периода (дни между ними подсвечиваются).
    final res = await _showRangeCalendarPicker(context, _dateRange);
    if (!mounted || res == null) return;
    setState(() => _dateRange = res);
  }

  void _openDetail(ReceiptHistoryItem r) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _ChecksDetailScreen(receipt: r)),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final clientHits = _clientSuggestions;

    return Container(
      color: _paper,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Center(
              child: Text('Чеки',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, color: _ink)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Column(
              children: [
                _SearchField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                if (clientHits.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ClientSuggestions(
                    clients: clientHits,
                    onPick: (c) {
                      setState(() {
                        _searchCtrl.text = c.name;
                        _query = c.name;
                      });
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FilterChip(
                        label: _period?.label ?? 'Период',
                        active: _period != null,
                        onTap: (ctx) => _openPeriodMenu(ctx),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CalendarChip(
                      active: _dateRange != null,
                      onTap: _openCalendar,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        label: _type?.label ?? 'Тип',
                        active: _type != null,
                        onTap: (ctx) => _openTypeMenu(ctx),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ReceiptRow(
                      item: items[i],
                      onTap: () => _openDetail(items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// widgets — список
// ============================================================================
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: _fill, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: _muted2),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: _orange,
              style: const TextStyle(fontSize: 14.5, color: _ink),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Имя, сумма, телефон, дата',
                hintStyle: TextStyle(color: _muted2, fontSize: 14.5),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(Icons.close, size: 18, color: _muted2),
            ),
        ],
      ),
    );
  }
}

class _ClientSuggestions extends StatelessWidget {
  final List<Client> clients;
  final ValueChanged<Client> onPick;
  const _ClientSuggestions({required this.clients, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _hairline),
      ),
      child: Column(
        children: [
          for (int i = 0; i < clients.length; i++) ...[
            InkWell(
              onTap: () => onPick(clients[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    _Avatar(client: clients[i], size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clients[i].name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _ink)),
                          const SizedBox(height: 2),
                          Text(clients[i].phone,
                              style: const TextStyle(
                                  fontSize: 12, color: _muted2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < clients.length - 1)
              const Divider(height: 1, color: _hairline2),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final void Function(BuildContext ctx) onTap;
  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) => GestureDetector(
        onTap: () => onTap(ctx),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: _fill, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: active ? _ink : _muted2,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: _muted2),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarChip extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _CalendarChip({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: _fill, borderRadius: BorderRadius.circular(12)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 19, color: active ? _orange : _ink),
            if (active)
              const Positioned(
                top: 7,
                right: 7,
                child: SizedBox(
                  width: 7,
                  height: 7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: _orange, shape: BoxShape.circle),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final ReceiptHistoryItem item;
  final VoidCallback onTap;
  const _ReceiptRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _hairline2)),
        ),
        child: Row(
          children: [
            _Avatar(client: item.client, guest: item.isGuest, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: _ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtDateTime(item.date),
                    style: const TextStyle(fontSize: 12.5, color: _muted2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_money(item.total)} ₽',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: _ink),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.fiscal ? _orange : _hairline,
                shape: BoxShape.circle,
              ),
              child: Text(
                item.fiscal ? 'Ф' : 'Б',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: item.fiscal ? Colors.white : _muted2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'Нет чеков по заданным условиям',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _muted2),
          ),
        ),
      );
}

class _Avatar extends StatelessWidget {
  final Client? client;
  final bool guest;
  final double size;
  const _Avatar({this.client, this.guest = false, required this.size});

  @override
  Widget build(BuildContext context) {
    if (guest || client == null) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            color: Color(0xFFF1ECE0), shape: BoxShape.circle),
        child: const Icon(Icons.person_outline, color: _muted2, size: 22),
      );
    }
    final c = client!;
    if (c.avatarAsset != null) {
      return ClipOval(
        child: Image.asset(c.avatarAsset!,
            width: size, height: size, fit: BoxFit.cover),
      );
    }
    final colors = [
      const Color(0xFFE8912B),
      const Color(0xFF6A8CBB),
      const Color(0xFF7BAE7F),
      const Color(0xFFC97A7A),
    ];
    final color = colors[c.id % colors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        c.initials.toUpperCase(),
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.36),
      ),
    );
  }
}

// ============================================================================
// Экран деталей чека
// ============================================================================
class _ChecksDetailScreen extends StatelessWidget {
  final ReceiptHistoryItem receipt;
  const _ChecksDetailScreen({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        surfaceTintColor: _paper,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: _ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Чек',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          children: [
            _ReceiptCard(receipt: receipt),
            const SizedBox(height: 16),
            _ClientPill(
              client: receipt.client,
              isGuest: receipt.isGuest,
              onTap: () {
                if (receipt.client != null) {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black54,
                    builder: (_) => _ClientProfileDialog(client: receipt.client!),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: _outline),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Печать через AirPrint',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              onPressed: () async {
                await print_route.loadLibrary();
                final r = receipt_model.Receipt(
                  number: receipt.number,
                  date: receipt.date,
                  client: receipt.client,
                  isGuest: receipt.isGuest,
                  tariffLabel: receipt.tariffLabel,
                  tariffPrice: receipt.tariffPrice,
                  rows: receipt.rows
                      .map((r) => receipt_model.ReceiptRow(
                          name: r.name,
                          weight: r.weight,
                          price: r.price,
                          sum: r.sum))
                      .toList(),
                  total: receipt.total,
                  payment: receipt.paymentLabel == 'Наличными'
                      ? receipt_model.PaymentMethod.cash
                      : receipt_model.PaymentMethod.card,
                  fiscal: receipt.fiscal,
                  fiscalDoc: receipt.fiscalDoc,
                );
                await print_route.printViaSystemDialog(r);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final ReceiptHistoryItem receipt;
  const _ReceiptCard({required this.receipt});
  @override
  Widget build(BuildContext context) {
    final r = receipt;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _hairline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('CRAZY TROUT ARENA',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: _ink)),
          const SizedBox(height: 3),
          Text('Чек № ${r.number} · ${_fmtDateTime(r.date)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: _muted2)),
          const _CardDivider(),
          _row('Клиент', r.displayName),
          _row('Телефон', r.client?.phone ?? '—'),
          const _CardDivider(),
          _row('Тариф · ${r.tariffLabel}', '${_money(r.tariffPrice)} ₽'),
          for (final it in r.rows)
            _row(
                '${it.name} ${it.weight.toStringAsFixed(2)} кг × ${it.price.round()}',
                '${_money(it.sum)} ₽'),
          const _CardDivider(),
          _row('ИТОГО', '${_money(r.total)} ₽', bigTotal: true),
          _row('Оплата', r.paymentLabel),
          _row('Тип чека',
              r.fiscal ? 'Фискальный ${r.fiscalDoc ?? ""}' : 'Без ФН'),
        ],
      ),
    );
  }

  Widget _row(String l, String v, {bool bigTotal = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(l,
                  style: TextStyle(
                    fontSize: bigTotal ? 17 : 13.5,
                    color: _ink,
                    fontWeight: bigTotal ? FontWeight.w700 : FontWeight.w400,
                  )),
            ),
            const SizedBox(width: 12),
            Text(v,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: bigTotal ? 19 : 13.5,
                  color: _ink,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      );
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();
  @override
  Widget build(BuildContext context) => Container(
      height: 1, color: _hairline2, margin: const EdgeInsets.symmetric(vertical: 12));
}

class _ClientPill extends StatelessWidget {
  final Client? client;
  final bool isGuest;
  final VoidCallback onTap;
  const _ClientPill(
      {required this.client, required this.isGuest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isGuest || client == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: _fill, borderRadius: BorderRadius.circular(14)),
        child: const Text('Гость (без анкеты)',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted2, fontSize: 13)),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: _fill, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            _Avatar(client: client, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  const SizedBox(height: 1),
                  Text('${client!.phone} · ${client!.tariffLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _muted2)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _muted2, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ClientProfileDialog extends StatelessWidget {
  final Client client;
  const _ClientProfileDialog({required this.client});

  @override
  Widget build(BuildContext context) {
    // Урезанный вариант карточки клиента для превью (полная версия живёт
    // на экране «Карта»). Дизайн подогнан под остальной flow.
    return Dialog(
      backgroundColor: _paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF14130F), Color(0xFF3B342A)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.35), width: 3),
                        ),
                        child: ClipOval(child: _Avatar(client: client, size: 54)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(client.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                client.tariffLabel.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _contact(Icons.phone_outlined, client.phone),
                  const SizedBox(height: 8),
                  _contact(Icons.card_membership_outlined,
                      'Тариф · ${client.tariffLabel}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contact(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFFC9932E)),
          const SizedBox(width: 9),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, color: _ink))),
        ],
      );
}

// ============================================================================
// Календарь периода — тот же визуальный язык, что и _CalendarPicker на
// экране «Карта пруда»: центрированная карточка 300×auto на затемнённом
// фоне, пагинация по месяцам круглыми стрелками, сетка дней с оранжевым
// кружком на выбранном дне. Отличие от карты — здесь выбирается диапазон
// (первый тап — начало, второй — конец), а не одна дата.
// ============================================================================
const _monthsFull = [
  'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
];
const _weekdaysShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

Future<DateTimeRange?> _showRangeCalendarPicker(
    BuildContext context, DateTimeRange? initial) {
  return showDialog<DateTimeRange>(
    context: context,
    barrierColor: const Color(0x7314130F), // rgba(20,19,15,0.45)
    builder: (_) => _RangeCalendarPicker(initial: initial),
  );
}

class _RangeCalendarPicker extends StatefulWidget {
  final DateTimeRange? initial;
  const _RangeCalendarPicker({this.initial});
  @override
  State<_RangeCalendarPicker> createState() => _RangeCalendarPickerState();
}

class _RangeCalendarPickerState extends State<_RangeCalendarPicker> {
  late DateTime cursor = DateTime(
      (widget.initial?.start ?? DateTime.now()).year,
      (widget.initial?.start ?? DateTime.now()).month, 1);
  DateTime? start = null;
  DateTime? end = null;

  @override
  void initState() {
    super.initState();
    start = widget.initial?.start;
    end = widget.initial?.end;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _pick(DateTime d) {
    setState(() {
      if (start == null || (start != null && end != null)) {
        start = d;
        end = null;
      } else if (_sameDay(d, start!)) {
        end = null;
      } else if (d.isBefore(start!)) {
        end = start;
        start = d;
      } else {
        end = d;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday = (DateTime(cursor.year, cursor.month, 1).weekday - 1) % 7;
    final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;
    final cells = <int?>[
      ...List<int?>.filled(firstWeekday, null),
      ...List.generate(daysInMonth, (i) => i + 1),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x4D000000), blurRadius: 50, offset: Offset(0, 20)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _navButton(Icons.chevron_left, () => setState(() {
              cursor = DateTime(cursor.year, cursor.month - 1, 1);
            })),
            Text('${_monthsFull[cursor.month - 1]} ${cursor.year}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
            _navButton(Icons.chevron_right, () => setState(() {
              cursor = DateTime(cursor.year, cursor.month + 1, 1);
            })),
          ]),
          const SizedBox(height: 12),
          Row(
            children: _weekdaysShort
                .map((w) => Expanded(
                    child: Center(
                        child: Text(w,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: _muted2)))))
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 2,
            crossAxisSpacing: 0,
            childAspectRatio: 1,
            children: cells.map((d) {
              if (d == null) return const SizedBox.shrink();
              final date = DateTime(cursor.year, cursor.month, d);
              final isStart = start != null && _sameDay(date, start!);
              final isEnd = end != null && _sameDay(date, end!);
              final inRange = start != null &&
                  end != null &&
                  date.isAfter(start!) &&
                  date.isBefore(end!);
              return GestureDetector(
                onTap: () => _pick(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: inRange ? _selected.withOpacity(0.55) : Colors.transparent,
                    borderRadius: BorderRadius.horizontal(
                      left: isStart ? const Radius.circular(16) : Radius.zero,
                      right: isEnd ? const Radius.circular(16) : Radius.zero,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (isStart || isEnd) ? _orange : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text('$d',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              (isStart || isEnd) ? FontWeight.w800 : FontWeight.w500,
                          color: (isStart || isEnd) ? Colors.white : _ink,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            start == null
                ? 'Выберите дату'
                : end == null
                    ? '${_fmtDateShort(start!)} · выберите вторую дату'
                    : '${_fmtDateShort(start!)} — ${_fmtDateShort(end!)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: _muted2),
          ),
          const SizedBox(height: 12),
          Row(children: [
            if (widget.initial != null)
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                style: TextButton.styleFrom(foregroundColor: _muted2),
                child: const Text('Сбросить',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            const Spacer(),
            SizedBox(
              width: widget.initial != null ? 160 : double.infinity,
              child: FilledButton(
                onPressed: start == null
                    ? null
                    : () => Navigator.pop(
                        context, DateTimeRange(start: start!, end: end ?? start!)),
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _hairline,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Применить',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _hairline),
          ),
          child: Icon(icon, size: 15, color: _ink),
        ),
      );
}

String _fmtDateShort(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}';
}

// ============================================================================
// helpers
// ============================================================================
String _money(num v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _fmtDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  const months = [
    'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year} · ${two(d.hour)}:${two(d.minute)}';
}
