import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/catch_row.dart';
import '../models/client.dart';
import '../models/receipt.dart';
import '../models/tariff.dart';
import '../widgets/catch_row_tile.dart';
import '../widgets/receipt_result_sheet.dart';
import '../widgets/segmented_control.dart';
import '../utils/permission_helper.dart' deferred as perm_helper;
import 'qr_scan_route.dart' deferred as qr_route;
import '../utils/qr_lookup.dart';
import '../utils/format.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final _searchCtrl = TextEditingController();
  List<Client> _searchResults = [];
  Client? _selectedClient;
  bool _isGuest = false;

  Tariff _tariff = kTariffs.first; // Стандарт по умолчанию
  int _rowSeq = 1;
  final List<CatchRow> _rows = [];

  PaymentMethod _payment = PaymentMethod.card;
  bool _fiscal = true;
  int _receiptSeq = 1247; // TODO: сохранять в SharedPreferences для сквозной нумерации

  double get _catchTotal => _rows.fold(0.0, (s, r) => s + r.sum);
  double get _total => _tariff.price + _catchTotal;

  void _search(String q) {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final query = q.toLowerCase();
    setState(() {
      _searchResults = kDemoClients
          .where((c) => c.name.toLowerCase().contains(query) || c.phone.contains(query))
          .toList();
    });
  }

  Future<void> _scanQr() async {
    try {
      await perm_helper.loadLibrary();
      final granted = await perm_helper.requestCameraPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет разрешения на камеру — разрешите доступ в настройках')),
          );
        }
        return;
      }

      if (!mounted) return;

      await qr_route.loadLibrary();
      final code = await Navigator.of(context).push<String>(
        qr_route.createQrScanRoute(),
      );

      if (code == null || code.isEmpty || !mounted) return;

      final result = findClientByQr(code);
      if (result.client != null) {
        _selectClient(result.client!);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error!)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сканирования: $e')),
        );
      }
    }
  }

  void _selectClient(Client c) {
    setState(() {
      _selectedClient = c;
      _isGuest = false;
      _searchCtrl.text = c.name;
      _searchResults = [];
      final matched = kTariffs.where((t) => t.label == c.tariffLabel);
      if (matched.isNotEmpty) _tariff = matched.first;
    });
  }

  void _selectGuest() {
    setState(() {
      _isGuest = true;
      _selectedClient = null;
      _searchCtrl.clear();
      _searchResults = [];
      _tariff = kTariffs.firstWhere((t) => t.id == 'guest');
    });
  }

  void _addRow() {
    setState(() {
      _rows.add(CatchRow(
        id: _rowSeq++,
        species: kSpecies.first,
        kg: 0,
        grams: 0,
        pricePerKg: kSpeciesPrice[kSpecies.first]!,
      ));
    });
  }

  void _removeRow(CatchRow row) {
    setState(() => _rows.removeWhere((r) => r.id == row.id));
  }

  void _submit() {
    if (!_isGuest && _selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите клиента или отметьте «Гость»')),
      );
      return;
    }

    _receiptSeq += 1;

    final receipt = Receipt(
      number: _receiptSeq,
      date: DateTime.now(),
      client: _selectedClient,
      isGuest: _isGuest,
      tariffLabel: _tariff.label,
      tariffPrice: _tariff.price,
      rows: _rows
          .map((r) => ReceiptRow(name: r.species, weight: r.weight, price: r.pricePerKg, sum: r.sum))
          .toList(),
      total: _total,
      payment: _payment,
      fiscal: _fiscal,
      fiscalDoc: _fiscal ? '№ФД-${10000 + _receiptSeq}' : null,
    );

    showReceiptResultSheet(context, receipt).then((_) => _resetForm());
  }

  void _resetForm() {
    setState(() {
      _selectedClient = null;
      _isGuest = false;
      _searchCtrl.clear();
      _searchResults = [];
      _tariff = kTariffs.first;
      _rows.clear();
      _payment = PaymentMethod.card;
      _fiscal = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        const Text('Выставление чека', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _card(
          title: 'Клиент',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Поиск по имени или телефону…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2A6A7E)),
                    tooltip: 'Сканировать QR клиента',
                    onPressed: _scanQr,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF3EEE4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: _search,
              ),
              if (_searchResults.isNotEmpty)
                ..._searchResults.map(
                  (c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _ClientAvatar(client: c),
                    title: Text(c.name),
                    subtitle: Text('${c.phone} · ${c.tariffLabel}'),
                    onTap: () => _selectClient(c),
                  ),
                ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _selectGuest,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFDDD3BC), style: BorderStyle.solid),
                  ),
                ),
                child: Text(_isGuest ? '✓ Гость · без анкеты' : 'Гость · без анкеты'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Тип клиента',
          child: Row(
            children: [
              Expanded(
                child: _labeledField(
                  'ТАРИФ',
                  DropdownButtonFormField<Tariff>(
                    value: _tariff,
                    isExpanded: true,
                    decoration: _fieldDecoration(),
                    items: kTariffs
                        .map((t) => DropdownMenuItem(value: t, child: Text('${t.label} · ${t.price}')))
                        .toList(),
                    onChanged: (t) {
                      if (t != null) setState(() => _tariff = t);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _labeledField(
                  'ЦЕНА, ₽',
                  TextFormField(
                    key: ValueKey(_tariff.id),
                    initialValue: _tariff.price.toString(),
                    readOnly: true,
                    decoration: _fieldDecoration().copyWith(
                      fillColor: const Color(0xFFEDE8DC),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Улов',
          trailing: Text('${_rows.length} поз.', style: const TextStyle(color: Colors.grey)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._rows.map(
                (r) => CatchRowTile(
                  row: r,
                  onChanged: () => setState(() {}),
                  onRemove: () => _removeRow(r),
                ),
              ),
              OutlinedButton(
                onPressed: _addRow,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFDDD3BC)),
                  ),
                ),
                child: const Text('+ Добавить рыбу', style: TextStyle(color: Color(0xFF8A6D1E), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _summaryRow('Тариф клиента', money(_tariff.price), color: Colors.white70),
              _summaryRow('Улов · ${_rows.length} поз.', money(_catchTotal), color: Colors.white70),
              const Divider(color: Colors.white24, height: 24),
              _summaryRow('ИТОГО', money(_total), color: Colors.white, big: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Способ оплаты',
          child: SegmentedControl<PaymentMethod>(
            options: const [
              SegmentedOption(PaymentMethod.cash, 'Наличными'),
              SegmentedOption(PaymentMethod.card, 'Картой'),
            ],
            selected: _payment,
            onChanged: (v) => setState(() => _payment = v),
          ),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Тип чека',
          child: SegmentedControl<bool>(
            options: const [
              SegmentedOption(true, 'Фискальный чек'),
              SegmentedOption(false, 'Без ФН'),
            ],
            selected: _fiscal,
            onChanged: (v) => setState(() => _fiscal = v),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8912B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Создать и распечатать чек', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color color = Colors.white, bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: big ? 18 : 14, fontWeight: big ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: big ? const Color(0xFFE8912B) : color, fontSize: big ? 20 : 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration() => InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        filled: true,
        fillColor: const Color(0xFFF3EEE4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      );

  Widget _labeledField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9C9484), letterSpacing: .3)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _card({required String title, Widget? trailing, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE8D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Круглый аватар клиента: фото, если есть, иначе инициалы.
class _ClientAvatar extends StatelessWidget {
  final Client client;
  const _ClientAvatar({required this.client});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFF3EEE4),
      backgroundImage: client.avatarAsset != null ? AssetImage(client.avatarAsset!) : null,
      child: client.avatarAsset == null
          ? Text(
              client.initials,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8A6D1E),
              ),
            )
          : null,
    );
  }
}
