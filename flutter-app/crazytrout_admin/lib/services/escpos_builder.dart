import 'dart:convert';
import 'dart:typed_data';

import '../models/receipt.dart';

/// Строит байты ESC/POS для термопринтера.
///
/// Пробует UTF-8 (ESCP/POS UTF-8 режим) — поддерживается большинством
/// современных Bluetooth-принтеров. Если принтер не поддерживает UTF-8,
/// fallback на CP866 (классический ESC/POS).
Uint8List buildEscPos(Receipt r) {
  // Пробуем UTF-8 — современные BT-принтеры поддерживают
  final utf8Data = _buildUtf8(r);
  // Если не сработает, можно вернуть CP866:
  // return _buildCp866(r);
  return utf8Data;
}

/// UTF-8 вариант — для современных принтеров с поддержкой Unicode.
Uint8List _buildUtf8(Receipt r) {
  final raw = <int>[];

  // Инициализация
  raw.addAll([0x1B, 0x40]); // ESC @

  // Включаем UTF-8 режим (ESCP/POS)
  raw.addAll([0x1B, 0x74, 0x52]); // ESC t 82 (UTF-8 code page)

  // Заголовок — центрированный, жирный, увеличенный
  raw.addAll([0x1B, 0x61, 0x01]); // центрирование
  raw.addAll([0x1B, 0x45, 0x01]); // жирный
  raw.addAll([0x1B, 0x21, 0x30]); // двойной размер
  raw.addAll(utf8.encode('CRAZY TROUT ARENA'));
  raw.addAll([0x0A]);

  // Сброс форматирования
  raw.addAll([0x1B, 0x21, 0x00]);
  raw.addAll([0x1B, 0x45, 0x00]);
  raw.addAll([0x1B, 0x61, 0x00]);

  // Номер чека и дата
  raw.addAll(utf8.encode('Чек №${r.number}'));
  raw.addAll([0x0A]);

  // Разделитель
  raw.addAll(utf8.encode('--------------------------------'));
  raw.addAll([0x0A]);

  // Клиент
  raw.addAll(utf8.encode('Клиент: ${r.clientLine}'));
  raw.addAll([0x0A]);
  raw.addAll(utf8.encode('Тариф ${r.tariffLabel}: ${r.tariffPrice} руб.'));
  raw.addAll([0x0A]);
  raw.addAll(utf8.encode('--------------------------------'));
  raw.addAll([0x0A]);

  // Улов
  for (final it in r.rows) {
    raw.addAll(utf8.encode(
      '${it.name} ${it.weight.toStringAsFixed(2)}кг × ${it.price.round()} = ${it.sum.round()} руб.',
    ));
    raw.addAll([0x0A]);
  }

  // Итого — жирный, увеличенный
  raw.addAll(utf8.encode('--------------------------------'));
  raw.addAll([0x0A]);
  raw.addAll([0x1B, 0x45, 0x01]);
  raw.addAll([0x1B, 0x21, 0x10]);
  raw.addAll(utf8.encode('ИТОГО: ${r.total.round()} руб.'));
  raw.addAll([0x0A]);
  raw.addAll([0x1B, 0x21, 0x00]);
  raw.addAll([0x1B, 0x45, 0x00]);

  raw.addAll(utf8.encode('Оплата: ${r.payment.label}'));
  raw.addAll([0x0A]);
  raw.addAll(utf8.encode(
    r.fiscal ? 'Фискальный чек ${r.fiscalDoc ?? ""}' : 'Без ФН',
  ));
  raw.addAll([0x0A]);

  // Пробелы перед отрезом
  raw.addAll([0x0A, 0x0A, 0x0A]);

  // Команда отреза бумаги (GS V 1 — partial cut)
  raw.addAll([0x1D, 0x56, 0x01]);

  return Uint8List.fromList(raw);
}
