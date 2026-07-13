import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

import '../models/receipt.dart';
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
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/PTSans-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/PTSans-Bold.ttf'));
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        theme: theme,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'CRAZY TROUT ARENA',
                style: pw.TextStyle(font: bold, fontSize: 14),
              ),
            ),
            pw.Center(
              child: pw.Text('Чек № ${r.number} · ${_fmtDate(r.date)}', style: pw.TextStyle(font: regular, fontSize: 9)),
            ),
            pw.Divider(),
            pw.Text('Клиент: ${r.clientLine}', style: pw.TextStyle(font: regular, fontSize: 10)),
            pw.Text('Тариф · ${r.tariffLabel}: ${r.tariffPrice} ₽', style: pw.TextStyle(font: regular, fontSize: 10)),
            pw.Divider(),
            ...r.rows.map(
              (it) => pw.Text(
                '${it.name} ${it.weight.toStringAsFixed(2)}кг × ${it.price.round()} = ${it.sum.round()} ₽',
                style: pw.TextStyle(font: regular, fontSize: 10),
              ),
            ),
            pw.Divider(),
            pw.Text(
              'ИТОГО: ${r.total.round()} ₽',
              style: pw.TextStyle(font: bold, fontSize: 13),
            ),
            pw.Text('Оплата: ${r.payment.label}', style: pw.TextStyle(font: regular, fontSize: 10)),
            pw.Text(
              r.fiscal ? 'Фискальный чек ${r.fiscalDoc ?? ""}' : 'Без ФН',
              style: pw.TextStyle(font: regular, fontSize: 10),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Чек №${r.number}',
    );
  }

  /// Аналог кнопки «Найти принтер и распечатать»: сканирует ближайшие
  /// Bluetooth-устройства, даёт пользователю выбрать принтер из списка
  /// (диалог строим сами — Flutter не показывает системный пикер, как это
  /// делает Web Bluetooth в Chrome) и отправляет байты чека через ESC/POS.
  static Future<void> printViaBluetooth(BuildContext context, Receipt r) async {
    // ВАЖНО: раньше сканирование не было обёрнуто в try/catch, а разрешения
    // на Bluetooth вообще не запрашивались — на Android 12+ это приводило к
    // тому, что startScan() падал с исключением молча, и кнопка выглядела
    // так, будто "ничего не происходит". Теперь любая ошибка на любом шаге
    // показывает тост, а не проглатывается.
    try {
      if (await FlutterBluePlus.isSupported == false) {
        if (context.mounted) _toast(context, 'Bluetooth не поддерживается на этом устройстве');
        return;
      }

      // Разрешения BLUETOOTH_SCAN / BLUETOOTH_CONNECT / геолокация — без них
      // сканирование на Android 12+ падает без единого сообщения пользователю.
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

      // Проверяем текущее состояние адаптера — напрямую, а не через стрим.
      // firstWhere() на стриме ненадёжен: после выдачи разрешений стрим может
      // не успеть эмитить `on` за 5 секунд → timeout → тихий выход.
      var adapterState = FlutterBluePlus.adapterStateNow;

      // Если состояние unknown (ещё не инициализировано) — подписываемся на стрим
      // и ждём до 5 секунд.
      if (adapterState != BluetoothAdapterState.on) {
        adapterState = await FlutterBluePlus.adapterState
            .firstWhere((s) => s == BluetoothAdapterState.on)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => BluetoothAdapterState.unknown,
            );
      }

      if (adapterState != BluetoothAdapterState.on) {
        if (context.mounted) _toast(context, 'Включите Bluetooth на устройстве');
        return;
      }

      final found = <ScanResult>[];
      final sub = FlutterBluePlus.scanResults.listen((results) {
        found
          ..clear()
          ..addAll(results.where((r) => r.device.platformName.isNotEmpty));
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      if (!context.mounted) {
        await sub.cancel();
        return;
      }

      final chosen = await showModalBottomSheet<ScanResult>(
        context: context,
        builder: (ctx) {
          return StreamBuilder<List<ScanResult>>(
            stream: FlutterBluePlus.scanResults,
            initialData: found,
            builder: (ctx, snapshot) {
              final devices = (snapshot.data ?? []).where((d) => d.device.platformName.isNotEmpty).toList();
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Выберите принтер', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    if (devices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Поиск устройств рядом…'),
                      ),
                    ...devices.map(
                      (d) => ListTile(
                        title: Text(d.device.platformName),
                        subtitle: Text(d.device.remoteId.toString()),
                        onTap: () => Navigator.of(ctx).pop(d),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      );

      await FlutterBluePlus.stopScan();
      await sub.cancel();

      if (chosen == null) {
        if (context.mounted) _toast(context, 'Принтер не выбран');
        return;
      }

      if (context.mounted) _toast(context, 'Подключение к «${chosen.device.platformName}»…');

      final device = chosen.device;
      await device.connect(timeout: const Duration(seconds: 8));

      BluetoothCharacteristic? printChar;
      try {
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
          if (context.mounted) _toast(context, 'Принтер не поддерживает запись данных. Попробуйте другой принтер.');
          await device.disconnect();
          return;
        }

        if (context.mounted) _toast(context, 'Печать на «${chosen.device.platformName}»…');

        final data = buildEscPos(r);
        // BLE-устройства: chunk ≤ MTU-3 (обычно ~20 байт).
        // Classic SPP: можно отправлять булками по 512 байт.
        // Определяем MTU, если доступен, иначе используем 20.
        int chunkSize = 20;
        try {
          final mtu = await device.mtu.first;
          if (mtu > 23) chunkSize = mtu - 3; // BLE MTU минус ATT overhead
        } catch (_) {
          // MTU не доступен (Classic BT или старая версия) — используем 512
          chunkSize = 512;
        }

        for (var i = 0; i < data.length; i += chunkSize) {
          final end = i + chunkSize > data.length ? data.length : i + chunkSize;
          final chunk = data.sublist(i, end);
          await printChar.write(chunk, withoutResponse: printChar.properties.writeWithoutResponse);
          // Небольшая задержка для надёжности — принтер должен успеть обработать
          if (chunkSize <= 20) {
            await Future.delayed(const Duration(milliseconds: 20));
          } else {
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }

        if (context.mounted) _toast(context, 'Чек отправлен на принтер ✓');
      } finally {
        // Всегда отключаемся, даже при ошибке записи
        try {
          await device.disconnect();
        } catch (_) {} // disconnect может упасть, если уже отключились
      }
    } catch (e) {
      if (context.mounted) _toast(context, 'Ошибка печати: $e');
    }
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  static String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
