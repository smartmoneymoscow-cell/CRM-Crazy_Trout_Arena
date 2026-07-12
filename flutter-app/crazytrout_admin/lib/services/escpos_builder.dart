import 'dart:convert';
import 'dart:typed_data';

import '../models/receipt.dart';

/// Строит байты ESC/POS для термопринтера — порт функции buildEscPos()
/// из веб-версии на Dart.
///
/// Использует CP866 (кириллица) для корректного отображения русских букв
/// на большинстве термопринтеров, иначе вместо букв будут «кракозябры».
Uint8List buildEscPos(Receipt r) {
  final raw = <int>[];

  // Инициализация принтера
  raw.addAll([0x1B, 0x40]); // ESC @

  // Перекодировка на CP866 — стандартная кодовая страница для ESC/POS
  raw.addAll([0x1B, 0x74, 0x11]); // ESC t 17 — выбор таблицы кодов CP866

  // Заголовок — центрированный, жирный, увеличенный
  raw.addAll([0x1B, 0x61, 0x01]); // ESC a 1 — центрирование
  raw.addAll([0x1B, 0x45, 0x01]); // ESC E 1 — жирный
  raw.addAll([0x1B, 0x21, 0x30]); // ESC ! 0x30 — двойной размер
  raw.addAll(_encodeCp866('CRAZY TROUT ARENA'));
  raw.addAll([0x0A]);

  // Сброс форматирования
  raw.addAll([0x1B, 0x21, 0x00]); // ESC ! 0 — нормальный размер
  raw.addAll([0x1B, 0x45, 0x00]); // ESC E 0 — обычный
  raw.addAll([0x1B, 0x61, 0x00]); // ESC a 0 — выравнивание влево

  // Номер чека и дата
  raw.addAll(_encodeCp866('Чек №${r.number}'));
  raw.addAll([0x0A]);

  // Разделитель
  raw.addAll(_encodeCp866('--------------------------------'));
  raw.addAll([0x0A]);

  // Клиент
  raw.addAll(_encodeCp866('Клиент: ${r.clientLine}'));
  raw.addAll([0x0A]);
  raw.addAll(_encodeCp866('Тариф ${r.tariffLabel}: ${r.tariffPrice} руб.'));
  raw.addAll([0x0A]);
  raw.addAll(_encodeCp866('--------------------------------'));
  raw.addAll([0x0A]);

  // Улов
  for (final it in r.rows) {
    raw.addAll(_encodeCp866(
      '${it.name} ${it.weight.toStringAsFixed(2)}кг × ${it.price.round()} = ${it.sum.round()} руб.',
    ));
    raw.addAll([0x0A]);
  }

  // Итого — жирный, увеличенный
  raw.addAll(_encodeCp866('--------------------------------'));
  raw.addAll([0x0A]);
  raw.addAll([0x1B, 0x45, 0x01]); // жирный
  raw.addAll([0x1B, 0x21, 0x10]); // двойная высота
  raw.addAll(_encodeCp866('ИТОГО: ${r.total.round()} руб.'));
  raw.addAll([0x0A]);
  raw.addAll([0x1B, 0x21, 0x00]); // сброс размера
  raw.addAll([0x1B, 0x45, 0x00]); // сброс жирного

  raw.addAll(_encodeCp866('Оплата: ${r.payment.label}'));
  raw.addAll([0x0A]);
  raw.addAll(_encodeCp866(
    r.fiscal ? 'Фискальный чек ${r.fiscalDoc ?? ""}' : 'Без ФН',
  ));
  raw.addAll([0x0A]);

  // Пробелы перед отрезом
  raw.addAll([0x0A, 0x0A, 0x0A]);

  // Команда отреза бумаги (GS V 1 — partial cut)
  raw.addAll([0x1D, 0x56, 0x01]);

  return Uint8List.fromList(raw);
}

/// Кодирует строку в CP866 (байтовый массив для ESC/POS).
/// CP866 — стандартная кодовая страница русских термопринтеров.
/// Если принтер поддерживает UTF-8, можно заменить на utf8.encode().
List<int> _encodeCp866(String text) {
  // Таблица соответствия Unicode → CP866 для кириллицы:
  // А-Я = 0x80-0x9F, а-я = 0xA0-0xEF, ё/Ё = 0xF0/0xF1
  final result = <int>[];
  for (final codeUnit in text.codeUnits) {
    final ch = String.fromCharCode(codeUnit);
    final cp = _unicodeToCp866(ch);
    if (cp != null) {
      result.add(cp);
    } else {
      // Латиница и спецсимволы — прямое совпадение с ASCII
      result.add(codeUnit);
    }
  }
  return result;
}

int? _unicodeToCp866(String ch) {
  final code = ch.codeUnitAt(0);
  // А-Я: U+0410..U+042F → 0x80..0x9F
  if (code >= 0x0410 && code <= 0x042F) return 0x80 + (code - 0x0410);
  // а-п: U+0430..U+043F → 0xA0..0xAF
  if (code >= 0x0430 && code <= 0x043F) return 0xA0 + (code - 0x0430);
  // р-я: U+0440..U+044F → 0xE0..0xEF
  if (code >= 0x0440 && code <= 0x044F) return 0xE0 + (code - 0x0440);
  // ё: U+0451 → 0xF1
  if (code == 0x0451) return 0xF1;
  // Ё: U+0401 → 0xF0
  if (code == 0x0401) return 0xF0;
  // Знак рубля ₽: U+20BD → используем «р» (0xE0) как замену
  if (code == 0x20BD) return 0xE0; // «р» в CP866
  // Дефис/минус: U+2013, U+2014, U+2212 → обычный дефис
  if (code == 0x2013 || code == 0x2014 || code == 0x2212) return 0x2D;
  // Неразрывный пробел: U+00A0 → обычный пробел
  if (code == 0x00A0) return 0x20;
  // Пробел
  if (code == 0x20) return 0x20;
  // Точка, запятая, скобки и прочее — ASCII-совместимые
  return null; // используем codeUnit как есть
}
