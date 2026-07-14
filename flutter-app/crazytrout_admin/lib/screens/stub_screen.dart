import 'package:flutter/material.dart';

class StubScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String note;

  const StubScreen({super.key, required this.title, required this.icon, required this.note});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: const Color(0xFFBBAF95)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              note,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9C9484), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
