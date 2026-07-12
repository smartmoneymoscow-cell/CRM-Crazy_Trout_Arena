import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/catch_row.dart';
import '../utils/format.dart';

class CatchRowTile extends StatefulWidget {
  final CatchRow row;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const CatchRowTile({
    super.key,
    required this.row,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<CatchRowTile> createState() => _CatchRowTileState();
}

class _CatchRowTileState extends State<CatchRowTile> {
  late final TextEditingController _kgCtrl;
  late final TextEditingController _gramsCtrl;

  @override
  void initState() {
    super.initState();
    // Поля пустые по умолчанию — не нужно стирать «0» перед вводом.
    // Значение 0 в модели (row.kg / row.grams) подставляется автоматически
    // при onChanged, если поле осталось пустым.
    _kgCtrl = TextEditingController(
      text: widget.row.kg == 0 ? '' : (widget.row.kg == widget.row.kg.roundToDouble()
          ? widget.row.kg.toInt().toString()
          : widget.row.kg.toString()),
    );
    _gramsCtrl = TextEditingController(
      text: widget.row.grams == 0 ? '' : widget.row.grams.toString(),
    );
  }

  @override
  void dispose() {
    _kgCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECE5D4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Порода на отдельной строке — иначе название рыбы обрезается до
          // одной буквы. Цена всегда фиксированная и подставляется автоматически.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Field(
                  label: 'Порода',
                  child: DropdownButtonFormField<String>(
                    value: widget.row.species,
                    isExpanded: true,
                    decoration: _decoration(),
                    items: kSpecies
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      widget.row.species = v;
                      widget.row.pricePerKg = kSpeciesPrice[v] ?? widget.row.pricePerKg;
                      widget.onChanged();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFFB4483A)),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Кг / Грамм / Сумма — теперь без соседства с полем породы у них
          // достаточно места, чтобы полностью показывать 3-значные граммы.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: _Field(
                  label: 'Кг',
                  child: TextField(
                    controller: _kgCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    decoration: _decoration(),
                    onChanged: (v) {
                      widget.row.kg = double.tryParse(v) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _Field(
                  label: 'Грамм',
                  child: TextField(
                    controller: _gramsCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: _decoration(),
                    onChanged: (v) {
                      var g = int.tryParse(v) ?? 0;
                      if (g > 999) g = 999;
                      if (g < 0) g = 0;
                      widget.row.grams = g;
                      widget.onChanged();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: _Field(
                  label: 'Сумма',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      money(widget.row.sum),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration() => InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        filled: true,
        fillColor: const Color(0xFFF3EEE4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, color: Color(0xFF9C9484), letterSpacing: .3),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
