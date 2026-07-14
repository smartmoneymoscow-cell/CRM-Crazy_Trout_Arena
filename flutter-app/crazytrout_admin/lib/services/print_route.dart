import 'package:flutter/material.dart';
import '../models/receipt.dart';
import '../services/print_service.dart';

/// Обёртка для вызова PrintService через deferred-импорт,
/// чтобы receipt_result_sheet.dart не тянул flutter_blue_plus
/// в цепочку компиляции тестов.
Future<void> printViaBluetooth(BuildContext context, Receipt r) async {
  try {
    await PrintService.printViaBluetooth(context, r);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка Bluetooth-печати: $e')),
      );
    }
  }
}

Future<void> printViaSystemDialog(Receipt r) async {
  await PrintService.printViaSystemDialog(r);
}
