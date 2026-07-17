import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

import '../models/receipt.dart';
import '../widgets/float_preloader.dart';
import 'escpos_builder.dart';

/// Известные UUID сервисов печати для ESC/POS Bluetooth-принтеров.
/// Разные производители используют разные UUID, поэтому проверяем все.
final List<Guid> _printServiceUuids = [
  Guid('00001101-0000-1000-8000-00805f9b34fb'), // Стандартный SPP
  Guid('000018f0-0000-1000-8000-00805f9b34fb'), // Device Information (некоторые принтеры)
  Guid('e7810a71-73ae-499d-8c15-faa9aef0c3f2'), // BLE-принтеры (Xiaomi и др.)
  Guid('49535343-fe7d-4ae5-8fa9-9fafd205e455'), // HM-10 / CC2541 модули
  Guid('0000ffe0-0000-1000-8000-00805f9b34fb'), // HC-05/HC-06 модули
];

class PrintService {
  /// Аналог кнопки «Печать через AirPrint»: рендерит чек в PDF и показывает
  /// системный диалог печати. На iOS это открывает AirPrint, на Android —
  /// системную службу печати.
  static Future<void> printViaSystemDialog(Receipt r) async {
    // Стандартные PDF-шрифты (Helvetica/Base14) не содержат кириллических
    // глифов — без явного шрифта вместо букв печатаются «кракозябры» (□□□).
    pw.Font regular;
    pw.Font bold;
    try {
      regular = pw.Font.ttf(await rootBundle.load('assets/fonts/PTSans-Regular.ttf'));
      bold = pw.Font.ttf(await rootBundle.load('assets/fonts/PTSans-Bold.ttf'));
    } catch (_) {
      // Фолбэк: если шрифт не загрузился — используем стандартный (без кириллицы)
      regular = pw.Font.helvetica();
      bold = pw.Font.helveticaBold();
    }
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);

    // Заменяем символы, которых нет в PTSans/Helvetica: ₽ → руб., № → #
    String sanitize(String s) => s.replaceAll('\u20BD', 'руб.').replaceAll('\u2116', '#');
    String safeMoney(num n) => sanitize('${n.round()} \u20BD');
    String safeText(String s) => sanitize(s);

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        theme: theme,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Заголовок
            pw.Center(
              child: pw.Text(
                'CRAZY TROUT ARENA',
                style: pw.TextStyle(font: bold, fontSize: 14),
              ),
            ),
            pw.Center(
              child: pw.Text(
                safeText(r.fiscal ? 'КАССОВЫЙ ЧЕК (${r.operationType.label})' : 'ЧЕК (без ФН)'),
                style: pw.TextStyle(font: bold, fontSize: 10),
              ),
            ),
            pw.Divider(),

            // Реквизиты продавца (54-ФЗ)
            pw.Text(safeText('Продавец: ${r.sellerName}'), style: pw.TextStyle(font: regular, fontSize: 9)),
            pw.Text(safeText('ИНН: ${r.sellerINN}'), style: pw.TextStyle(font: regular, fontSize: 9)),
            pw.Text(safeText('Адрес: ${r.sellerAddress}'), style: pw.TextStyle(font: regular, fontSize: 9)),

            // Дата, время, номер чека, смена
            pw.Text(safeText('Дата: ${_fmtDate(r.date)}'), style: pw.TextStyle(font: regular, fontSize: 9)),
            pw.Text(safeText('Чек №${r.number}  Смена №${r.shiftNumber}'), style: pw.TextStyle(font: regular, fontSize: 9)),
            pw.Text(safeText('СНО: ${r.taxSystem.label}'), style: pw.TextStyle(font: regular, fontSize: 9)),
            pw.Divider(),

            // Клиент
            pw.Text(safeText('Клиент: ${r.clientLine}'), style: pw.TextStyle(font: regular, fontSize: 10)),
            pw.Text(safeText('Тариф · ${r.tariffLabel}: ${safeMoney(r.tariffPrice)}'), style: pw.TextStyle(font: regular, fontSize: 10)),
            pw.Divider(),

            // Товары
            ...r.rows.map(
              (it) => pw.Text(
                safeText('${it.name} ${it.weight.toStringAsFixed(2)}кг × ${it.price.round()} = ${safeMoney(it.sum)}'),
                style: pw.TextStyle(font: regular, fontSize: 10),
              ),
            ),
            pw.Divider(),

            // Итого
            pw.Text(
              'ИТОГО: ${safeMoney(r.total)}',
              style: pw.TextStyle(font: bold, fontSize: 13),
            ),
            // НДС
            pw.Text(
              safeText(r.ndsRate > 0 ? 'НДС ${r.ndsRate.round()}%: ${safeMoney(r.ndsSum)}' : 'НДС не облагается'),
              style: pw.TextStyle(font: regular, fontSize: 9),
            ),
            pw.Text(safeText('Оплата: ${r.payment.label}'), style: pw.TextStyle(font: regular, fontSize: 10)),
            pw.Divider(),

            // Фискальные реквизиты (54-ФЗ)
            if (r.fiscal) ...[
              pw.Text(safeText('ККТ: ${r.kktNumber}'), style: pw.TextStyle(font: regular, fontSize: 8)),
              pw.Text(safeText('ФН: ${r.fnNumber}'), style: pw.TextStyle(font: regular, fontSize: 8)),
              pw.Text(safeText('ФД №: ${r.fdNumber}'), style: pw.TextStyle(font: regular, fontSize: 8)),
              pw.Text(safeText('ФПД: ${r.fpd}'), style: pw.TextStyle(font: regular, fontSize: 8)),
              pw.Text(safeText('Проверка: nalog.ru'), style: pw.TextStyle(font: regular, fontSize: 8)),
              if (r.buyerEmail != null && r.buyerEmail!.isNotEmpty)
                pw.Text(safeText('Email покупателя: ${r.buyerEmail}'), style: pw.TextStyle(font: regular, fontSize: 8)),
              if (r.sellerEmail != null && r.sellerEmail!.isNotEmpty)
                pw.Text(safeText('Email продавца: ${r.sellerEmail}'), style: pw.TextStyle(font: regular, fontSize: 8)),
            ] else ...[
              pw.Text('Чек без фискального накопителя', style: pw.TextStyle(font: regular, fontSize: 9)),
            ],
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Чек #${r.number}',
    );
  }

  /// Показывает прелоадер с поплавком в bottom sheet.
  /// Возвращает функцию для закрытия sheet.
  static void _showFloatPreloaderSheet(
    BuildContext context, {
    required String label,
    double? progress,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFBF6EC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatPreloader(label: label, progress: progress),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Отмена'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Обновляет текст/прогресс в preloader sheet через StatefulBuilder.
  /// Показывает sheet с поплавком, возвращает контроллер для обновления.
  static Future<_PreloaderController> _showPreloader(
    BuildContext context, {
    String initialLabel = 'Ищем принтеры…',
  }) async {
    final controller = _PreloaderController(label: initialLabel);
    controller._sheetFuture = showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        controller._setState = (fn) {
          // ignore: invalid_use_of_protected_member
          (ctx as Element).markNeedsBuild();
        };
        controller._sheetContext = ctx;
        return WillPopScope(
          onWillPop: () async => false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFBF6EC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: StatefulBuilder(
              builder: (ctx, setState) {
                controller._setState = setState;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatPreloader(
                      label: controller.label,
                      progress: controller.progress,
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        controller._cancelled = true;
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Отмена'),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    // Ждём открытия
    await Future.delayed(const Duration(milliseconds: 100));
    return controller;
  }

  /// Аналог кнопки «Найти принтер и распечатать»: сканирует ближайшие
  /// Bluetooth-устройства, даёт пользователю выбрать принтер из списка
  /// и отправляет байты чека через ESC/POS.
  ///
  /// UX-поток:
  ///   1. Запрос разрешений
  ///   2. Показать прелоадер с поплавком «Ищем принтеры…»
  ///   3. Сканирование 4 сек
  ///   4. Найдены → список для выбора / Не найдены → сообщение + «Повторить»
  ///   5. Выбор → «Подключение…» → «Печать…» → «Чек отправлен ✓»
  static Future<void> printViaBluetooth(BuildContext context, Receipt r) async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        if (context.mounted) _toast(context, 'Bluetooth не поддерживается на этом устройстве');
        return;
      }

      // 1. Сначала запрашиваем разрешения (до проверки BT — на Android 12+
      //    turnOn() требует BLUETOOTH_CONNECT)
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      final denied = statuses.entries.where((e) => !e.value.isGranted && !e.value.isLimited).toList();
      if (denied.isNotEmpty) {
        if (context.mounted) {
          _toast(context, 'Нет разрешения на Bluetooth — разрешите доступ в настройках приложения');
        }
        return;
      }

      // 2. Проверяем Bluetooth — пробуем включить если выключен
      var adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {
          // turnOn() не поддерживается на всех устройствах
        }
        await Future.delayed(const Duration(milliseconds: 1500));
        adapterState = await FlutterBluePlus.adapterState.first;
        if (adapterState != BluetoothAdapterState.on) {
          if (context.mounted) _toast(context, 'Bluetooth выключен — включите его в настройках');
          return;
        }
      }

      // Показываем прелоадер с поплавком
      _PreloaderController? preloader;
      if (context.mounted) {
        preloader = await _showPreloader(context, initialLabel: 'Ищем принтеры…');
      }

      final found = <ScanResult>[];
      final sub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (r.device.platformName.isNotEmpty &&
              !found.any((f) => f.device.remoteId == r.device.remoteId)) {
            found.add(r);
            // Обновляем лейбл прелоадера в реальном времени
            preloader?.updateLabel(
              found.isEmpty
                  ? 'Ищем принтеры…'
                  : 'Найдено: ${found.length} ${_pluralPrinters(found.length)}',
            );
          }
        }
      });

      try {
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 5),
          androidUsesFineLocation: false,
        );
      } catch (e) {
        await sub.cancel();
        preloader?.close();
        if (context.mounted) {
          _toast(context, 'Не удалось начать поиск: $e');
        }
        return;
      }

      if (preloader?._cancelled == true) {
        await FlutterBluePlus.stopScan();
        await sub.cancel();
        return;
      }

      // Закрываем прелоадер, показываем список устройств
      preloader?.close();
      await Future.delayed(const Duration(milliseconds: 200));

      if (!context.mounted) {
        await FlutterBluePlus.stopScan();
        await sub.cancel();
        return;
      }

      // Bottom sheet со списком найденных устройств
      ScanResult? chosen;
      if (found.isEmpty) {
        // Ничего не найдено — показываем сообщение с кнопкой «Повторить»
        final retry = await _showNotFoundSheet(context);
        await FlutterBluePlus.stopScan();
        await sub.cancel();
        if (retry == true && context.mounted) {
          // Рекурсивный вызов — повторить поиск
          return printViaBluetooth(context, r);
        }
        return;
      }

      chosen = await _showDevicePickerSheet(context, found);
      await FlutterBluePlus.stopScan();
      await sub.cancel();

      if (chosen == null) {
        if (context.mounted) _toast(context, 'Принтер не выбран');
        return;
      }

      // Показываем прогресс подключения
      _PreloaderController? connectPreloader;
      if (context.mounted) {
        connectPreloader = await _showPreloader(
          context,
          initialLabel: 'Подключение к «${chosen.device.platformName}»…',
        );
      }

      final device = chosen.device;
      await device.connect(timeout: const Duration(seconds: 8));

      if (connectPreloader?._cancelled == true) {
        await device.disconnect();
        return;
      }

      BluetoothCharacteristic? printChar;
      try {
        if (connectPreloader != null) {
          connectPreloader.updateLabel('Печать на «${chosen.device.platformName}»…');
        }

        final services = await device.discoverServices();

        // Ищем характеристику для записи: сначала по известным UUID сервисов,
        // затем — по любой характеристике с поддержкой записи (write).
        for (final serviceUuid in _printServiceUuids) {
          for (final service in services) {
            if (service.uuid == serviceUuid) {
              for (final char in service.characteristics) {
                if (char.properties.write || char.properties.writeWithoutResponse) {
                  printChar = char;
                  break;
                }
              }
            }
            if (printChar != null) break;
          }
          if (printChar != null) break;
        }

        // Фолбэк: ищем любую характеристику с write-доступом
        if (printChar == null) {
          for (final service in services) {
            for (final char in service.characteristics) {
              if (char.properties.write || char.properties.writeWithoutResponse) {
                printChar = char;
                break;
              }
            }
            if (printChar != null) break;
          }
        }

        if (printChar == null) {
          connectPreloader?.close();
          if (context.mounted) _toast(context, 'Принтер не поддерживает запись данных. Попробуйте другой принтер.');
          await device.disconnect();
          return;
        }

        final data = buildEscPos(r);

        // BLE-устройства: chunk ≤ MTU-3 (обычно ~20 байт).
        // Classic SPP: можно отправлять булками по 512 байт.
        int chunkSize = 20;
        try {
          final mtu = await device.mtu.first;
          if (mtu > 23) chunkSize = mtu - 3;
        } catch (_) {
          chunkSize = 512;
        }

        for (var i = 0; i < data.length; i += chunkSize) {
          if (connectPreloader?._cancelled == true) break;
          final end = i + chunkSize > data.length ? data.length : i + chunkSize;
          final chunk = data.sublist(i, end);
          await printChar.write(chunk, withoutResponse: printChar.properties.writeWithoutResponse);
          // Обновляем прогресс
          if (connectPreloader != null && data.length > 0) {
            connectPreloader.progress = i / data.length;
          }
          if (chunkSize <= 20) {
            await Future.delayed(const Duration(milliseconds: 20));
          } else {
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }

        connectPreloader?.close();
        if (context.mounted) _toast(context, 'Чек отправлен на принтер ✓');
      } finally {
        try {
          await device.disconnect();
        } catch (_) {}
      }
    } catch (e) {
      if (context.mounted) _toast(context, 'Ошибка печати: $e');
    }
  }

  /// Sheet «Принтеры не найдены» с кнопкой «Повторить поиск».
  static Future<bool?> _showNotFoundSheet(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFBF6EC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bluetooth_disabled, size: 48, color: Color(0xFF8C8576)),
            const SizedBox(height: 16),
            const Text(
              'Принтеры не найдены',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Проверьте что принтер включён и находится рядом',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8C8576), fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Повторить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8912B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Sheet с выбором найденного устройства.
  static Future<ScanResult?> _showDevicePickerSheet(
    BuildContext context,
    List<ScanResult> devices,
  ) {
    return showModalBottomSheet<ScanResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFBF6EC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Выберите принтер', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ...devices.map(
                (d) => ListTile(
                  leading: const Icon(Icons.print, color: Color(0xFF8C8576)),
                  title: Text(d.device.platformName),
                  subtitle: Text(d.device.remoteId.toString()),
                  onTap: () => Navigator.of(ctx).pop(d),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  static String _pluralPrinters(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'принтер';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) return 'принтера';
    return 'принтеров';
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  static String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}

/// Контроллер для управления прелоадером извне.
class _PreloaderController {
  String label;
  double? progress;
  bool _cancelled = false;
  Future<void>? _sheetFuture;
  BuildContext? _sheetContext;
  void Function(void Function())? _setState;

  _PreloaderController({required this.label, this.progress});

  void close() {
    if (_sheetContext != null && _sheetContext!.mounted) {
      Navigator.of(_sheetContext!).pop();
    }
  }

  /// Обновляет label и вызывает перерисовку sheet.
  void updateLabel(String newLabel) {
    label = newLabel;
    _setState?.call(() {});
  }

  /// Обновляет progress и вызывает перерисовку sheet.
  void updateProgress(double? newProgress) {
    progress = newProgress;
    _setState?.call(() {});
  }
}
