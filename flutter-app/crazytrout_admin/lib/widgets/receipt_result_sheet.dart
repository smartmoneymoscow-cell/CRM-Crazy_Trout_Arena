import 'package:flutter/material.dart';

import '../models/receipt.dart';
import '../services/print_route.dart' deferred as print_route;
import '../utils/format.dart';

Future<void> showReceiptResultSheet(BuildContext context, Receipt r) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ReceiptResultSheet(receipt: r),
  );
}

class _ReceiptResultSheet extends StatelessWidget {
  final Receipt receipt;
  const _ReceiptResultSheet({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFBF6EC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Чек создан', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E0CF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('CRAZY TROUT ARENA', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      'Чек № ${r.number} · ${_fmtDate(r.date)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    _row('Клиент', r.clientLine),
                    _row('Тариф · ${r.tariffLabel}', money(r.tariffPrice)),
                    const Divider(height: 24),
                    ...r.rows.map((it) => _row(
                          '${it.name} ${it.weight.toStringAsFixed(2)}кг × ${it.price.round()}',
                          money(it.sum),
                        )),
                    const Divider(height: 24),
                    _row('ИТОГО', money(r.total), bold: true),
                    _row('Оплата', r.payment.label),
                    _row('Тип чека', r.fiscal ? 'Фискальный ${r.fiscalDoc ?? ""}' : 'Без ФН'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8912B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.search),
                label: const Text('Найти принтер и распечатать', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await print_route.loadLibrary();
                  print_route.printViaBluetooth(context, r);
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFE0D8C5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.print_outlined),
                label: const Text('Печать через AirPrint', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await print_route.loadLibrary();
                  print_route.printViaSystemDialog(r);
                },
              ),
              const SizedBox(height: 12),
              Text(
                '«Найти принтер и распечатать» ищет доступные Bluetooth-принтеры рядом '
                'и отправляет чек напрямую (ESC/POS). «Печать через AirPrint» открывает '
                'системный диалог печати телефона.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Готово · новый чек'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 13)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, fontSize: bold ? 16 : 13)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
