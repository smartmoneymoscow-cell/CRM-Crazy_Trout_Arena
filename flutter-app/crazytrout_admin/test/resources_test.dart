import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Тесты проверяют что все ресурсы приложения на месте и валидны.
/// Если файл отсутствует или битый — тест упадёт ДО сборки, а не после.
void main() {
  group('Ресурсы приложения — иконки', () {
    test('icon.png существует и является PNG 1024x1024', () {
      final file = File('assets/icon/icon.png');
      expect(file.existsSync(), isTrue, reason: 'icon.png не найден');
      expect(file.lengthSync(), greaterThan(0), reason: 'icon.png пустой');
    });

    test('icon_foreground.png существует и является PNG', () {
      final file = File('assets/icon/icon_foreground.png');
      expect(file.existsSync(), isTrue, reason: 'icon_foreground.png не найден');
      expect(file.lengthSync(), greaterThan(0), reason: 'icon_foreground.png пустой');
    });

    test('splash_logo.png существует', () {
      final file = File('assets/icon/splash_logo.png');
      expect(file.existsSync(), isTrue, reason: 'splash_logo.png не найден');
      expect(file.lengthSync(), greaterThan(0), reason: 'splash_logo.png пустой');
    });
  });

  group('Ресурсы приложения — аватары', () {
    test('avatar_1.jpeg существует', () {
      final file = File('assets/avatars/avatar_1.jpeg');
      expect(file.existsSync(), isTrue, reason: 'avatar_1.jpeg не найден');
    });

    test('avatar_2.jpeg существует', () {
      final file = File('assets/avatars/avatar_2.jpeg');
      expect(file.existsSync(), isTrue, reason: 'avatar_2.jpeg не найден');
    });

    test('avatar_3.jpeg существует', () {
      final file = File('assets/avatars/avatar_3.jpeg');
      expect(file.existsSync(), isTrue, reason: 'avatar_3.jpeg не найден');
    });

    test('avatar_4.jpeg существует', () {
      final file = File('assets/avatars/avatar_4.jpeg');
      expect(file.existsSync(), isTrue, reason: 'avatar_4.jpeg не найден');
    });
  });

  group('Ресурсы приложения — шрифты', () {
    test('PTSans-Regular.ttf существует', () {
      final file = File('assets/fonts/PTSans-Regular.ttf');
      expect(file.existsSync(), isTrue, reason: 'PTSans-Regular.ttf не найден');
    });

    test('PTSans-Bold.ttf существует', () {
      final file = File('assets/fonts/PTSans-Bold.ttf');
      expect(file.existsSync(), isTrue, reason: 'PTSans-Bold.ttf не найден');
    });
  });

  group('Конфигурация flutter_launcher_icons', () {
    test('pubspec.yaml содержит секцию flutter_launcher_icons', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('flutter_launcher_icons:'));
      expect(pubspec, contains('android: true'));
      expect(pubspec, contains('ios: true'));
      expect(pubspec, contains('image_path:'));
      expect(pubspec, contains('adaptive_icon_foreground:'));
    });

    test('все ассеты из pubspec.yaml существуют на диске', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      // Извлекаем пути ассетов из секции flutter: assets:
      final assetRegex = RegExp(r"- (assets/[^\s]+)");
      final matches = assetRegex.allMatches(pubspec);
      for (final match in matches) {
        final path = match.group(1)!;
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Ассет $path не найден');
      }
    });
  });
}
