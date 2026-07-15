import 'package:flutter/material.dart';

import 'checks_screen.dart';
import 'pond_map_screen.dart';
import 'receipt_screen.dart';
import 'stub_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    PondMapScreen(),
    ReceiptScreen(),
    ChecksScreen(),
    StubScreen(title: 'P&L', icon: Icons.show_chart, note: 'Отчёт по прибыли и убыткам — раздел в разработке.'),
    StubScreen(title: 'Профиль', icon: Icons.person_outline, note: 'Профиль администратора — раздел в разработке.'),
  ];

  static const _items = [
    _BottomItem(Icons.map_outlined, 'Карта'),
    _BottomItem(Icons.receipt_outlined, 'Чек'),
    _BottomItem(Icons.receipt_long_outlined, 'Чеки'),
    _BottomItem(Icons.show_chart, 'P&L'),
    _BottomItem(Icons.person_outline, 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      body: SafeArea(child: _screens[_index]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            // +1px добавлен сверху (над иконками), как попросили —
            // остальные отступы не тронуты.
            padding: const EdgeInsets.only(top: 5, bottom: 4),
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final selected = _index == i;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _index = i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 24, // ← без изменений
                          color: selected ? const Color(0xFFE8912B) : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12, // ← без изменений
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? const Color(0xFFE8912B) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomItem {
  final IconData icon;
  final String label;
  const _BottomItem(this.icon, this.label);
}
