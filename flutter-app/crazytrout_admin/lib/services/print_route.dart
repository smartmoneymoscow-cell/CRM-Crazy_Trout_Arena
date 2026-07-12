import 'package:flutter/material.dart';
import '../models/receipt.dart';
import '../services/print_service.dart';

/// Обёртка для вызова PrintService через deferred-импорт,
/// чтобы receipt_result_sheet.dart не тянул flutter_blue_plus
/// в цепочку компиляции тестов.
void printViaBluetooth(BuildContext context, Receipt r) {
  PrintService.printViaBluetooth(context, r);
}

void printViaSystemDialog(Receipt r) {
  PrintService.printViaSystemDialog(r);
}
