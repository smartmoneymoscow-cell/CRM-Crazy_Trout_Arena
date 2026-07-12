# Установленные факты

## 1. Код Dart идентичен между v1.3.5 и v1.3.10 (последний HEAD)
Все .dart файлы в lib/ — одинаковые байт в байт.
Проверено: main.dart, receipt_screen.dart, demo_data.dart, catch_row_tile.dart, qr_scan_screen.dart и все остальные.

## 2. Различия между v1.3.3 и текущим кодом:

### demo_data.dart:
- Добавлены `kSpeciesImage` и `kSpeciesImageHeight` (карты для фото рыб)
- Удалён клиент 4 (Анна Морозова)
- Клиенты 5,6,7 получили avatarAsset
- Добавлен клиент 8 (Виктор Щукин) с аватаркой

### receipt_screen.dart:
- padding: (16,20,16,100) → (16,20,16,24)
- Title: добавлен textAlign: TextAlign.center
- fillColor: 0xFFEDE8DC → 0xFFF3EEE4
- Добавлен _GuestCard виджет (инкогнито)
- Кнопка гостя → карточка при выборе
- AppDropdownField получил fillColor и contentPadding

### qr_scan_screen.dart:
- УБРАНА задержка 500ms перед запуском камеры
- Изменены комментарии

### catch_row_tile.dart:
- contentPadding: vertical 10 → 12

## 3. Различия в pubspec.yaml (v1.3.3 vs текущий):
- Добавлены fish assets (5 файлов)
- Добавлены avatar_5-8, incognito.png
- Добавлены icon_check.png, splash_logo.jpg
- Добавлен/удалён sentry_flutter

## 4. Файлы assets:
- Все PNG/JPEG файлы существуют и валидны
- Fish PNG: 200x100, валидные PNG
- icon_check.png: 932KB
- splash_logo.jpg: 78KB

## 5. Workflow изменения:
- build-apk.yml → split на build.yml + release.yml
- Добавлена validate-assets job
- ProGuard rules вынесены в proguard-rules.pro (статический файл)
- Шаг minify УДАЛЁН из workflow (flutter 3.44 генерирует isMinifyEnabled=false)
