# 🐟 Crazy Trout Arena — CRM

> Кроссплатформенная CRM-система для чек-кассы пруда платной рыбалки.
>
> **Два приложения:** [Нативное (Flutter)](#-скачать) · [Telegram Mini App](#-telegram-mini-app)

## 📱 Демонстрационный лендинг

Интерактивный мокап экрана профиля клиента для демонстрации добавления клиента через сканирование QR-кода из приложения админа.

🔗 **https://smartmoneymoscow-cell.github.io/CRM-Crazy_Trout_Arena/**

- Отображает экран профиля клиента (Уэйд Джереми, id: 100)
- При нажатии на QR-иконку отображается QR-код для сканирования
- QR-код:  — при сканировании в приложении подтягивается тестовый клиент
- Аватар и данные идентичны мок-клиенту в 



[![Build APK & IPA](https://github.com/smartmoneymoscow-cell/CRM-Crazy_Trout_Arena/actions/workflows/build-apk.yml/badge.svg)](https://github.com/smartmoneymoscow-cell/CRM-Crazy_Trout_Arena/actions/workflows/build-apk.yml)
[![Latest Release](https://img.shields.io/github/v/release/smartmoneymoscow-cell/CRM-Crazy_Trout_Arena)](https://github.com/smartmoneymoscow-cell/CRM-Crazy_Trout_Arena/releases/latest)
[![License](https://img.shields.io/badge/license-proprietary-red)](#)

---

## 📱 Скачать

| Платформа | Файл | Размер |
|-----------|------|--------|
| **Android** | [app-release.apk](https://github.com/smartmoneymoscow-cell/CRM-Crazy_Trout_Arena/releases/latest/download/app-release.apk) | ~31 MB |
| **iOS** | [app-release.ipa](https://github.com/smartmoneymoscow-cell/CRM-Crazy_Trout_Arena/releases/latest/download/app-release.ipa) | ~19 MB |

> ⚠️ iOS-сборка без кодирования (no-codesign). Для установки на устройство нужен provisioning profile через Xcode / Apple Developer.

---

## 📲 Telegram Mini App

> Версия CRM, работающая прямо внутри Telegram — без установки приложения.

| Возможность | Описание |
|-------------|----------|
| 🧾 **Выставление чеков** | Тарифы, улов, 54-ФЗ, три способа оплаты |
| 📷 **QR-сканер** | Нативный через Telegram API (`showScanQrPopup`) |
| 🗺️ **Карта пруда** | 16 секторов, профили клиентов, статистика |
| 📊 **Финансовый дашборд** | KPI, графики выручки, структура по тарифам/оплате |
| 📋 **История чеков** | Поиск, фильтры, карточки клиентов |
| 🖨️ **Печать** | Web Bluetooth (Android) / PassPRNT (iOS) / PDF fallback |
| 📱 **HapticFeedback** | Тактильная отдача при действиях |
| 🌙 **Тёмная тема** | Автоматически из настроек Telegram |

📂 **Исходники:** [`telegram-mini-app/`](telegram-mini-app/)
📖 **Документация:** [`telegram-mini-app/README.md`](telegram-mini-app/README.md)

---

## 🖥️ Эмулятор в браузере

Приложение можно запустить прямо в браузере:

🔗 **[https://appetize.io/app/yi7k2wtilanayxdmcsfnmb7zni](https://appetize.io/app/yi7k2wtilanayxdmcsfnmb7zni)**

> 📖 Инструкция по загрузке новых сборок: [docs/APPETIZE.md](docs/APPETIZE.md)

---

## ✅ Что умеет

### Выставление чеков
- 🔍 **Поиск клиента** — по имени или телефону, единая высота поисковой строки с экраном Чеки
- 📷 **QR-сканер** — идентификация клиента через камеру (mobile_scanner + ML Kit)
- 👤 **Гостевой режим** — быстрое оформление без анкеты, иконка инкогнито
- 🏷️ **Три тарифа** — Стандарт 750₽, Гостевой 500₽, Пенсионер 0₽
- 🐠 **Улов** — 5 пород (Осётр, Карп, Амур, Линь, Форель) с фиксированными ценами за кг, раздельные поля кг/граммы, авторасчёт суммы
- 💰 **Два типа чека** — фискальный (с ФН) и без ФН
- 💳 **Три способа оплаты** — наличные, карта, счёт заведения
- 📋 **54-ФЗ** — все обязательные реквизиты в ESC/POS, PDF и UI

### Печать
- 🖨️ **Bluetooth-принтер** — ESC/POS протокол, кириллица UTF-8, команда отреза бумаги, реквизиты по 54-ФЗ
- 📄 **Системная печать** — AirPrint (iOS) / PDF через системный диалог

### Карта пруда
- 🗺️ **Интерактивная карта** — 16 секторов пруда с визуализацией занятости
- 🎯 **Фильтры** — OverlayEntry + CompositedTransformFollower (стандартный Flutter-паттерн), dropdown следует за кнопкой при скролле, tap-to-close, maxHeight под нижнее меню
- 🔢 **Сектора** — увеличенные номера, увеличение иконки при нажатии
- 👤 **Профили клиентов** — баллы лояльности, история посещений, статистика улова
- 🏅 **Уровни** — Премиум, Стандарт, Базовый (медали с буквами)
- 📅 **Расписание** — бронирования по секторам и времени

### Отчёт и финансы
- 📊 **Финансовый дашборд** — выручка со спарклайном, маржинальная прибыль, переменные расходы (ClipRect от перекрытия)
- 📈 **KPI-карточки** — средний чек, LT/LTV, средний улов (штуки/кг), возвращающиеся клиенты, рейтинг ★
- 🥧 **Структура выручки** — кольцевая диаграмма с сокращением чисел (тыс./млн)
- 📉 **Динамика выручки** — линейный график по месяцам/неделям с fallback при < 2 точках
- 💳 **Оплата и тарифы** — столбчатая и кольцевая диаграммы
- 🔍 **Все данные пересчитываются** при переключении периода или диапазона календаря
- 🎛️ **Фильтры** — поздний фильтр сбрасывает ранний (период ↔ календарь), выбор одного дня в календаре, короткие лейблы (Сегодня/Неделя/Месяц/Квартал/Все вр.), оранжевая точка-индикатор

### Чеки (история)
- 🧾 **Лента чеков** — поиск, фильтры (Период + «За все время» / Иконки фильтров + сортировки)
- 💰 **Сумма чека** — зелёный цвет с префиксом «+»
- 👤 **Карточка клиента** — уровни, баллы, статы, улов, полная история
- 📅 **Последнее посещение** — вместо «Сейчас на секторе»
- 🖨️ **Превью чека** — детали с AirPrint

### Дизайн
- 🎨 Единый визуальный стиль: бежевая палитра (#FBF6EC, #F3EEE4), оранжевые акценты (#E8912B)
- 📐 Единая высота и цвет всех input-полей (vertical: 12, fillColor: #F3EEE4)
- 🔤 Шрифт PT Sans (Regular, Bold)
- 🖼️ Аватары клиентов — фото или инициалы для фолбэка

---

## 🏗️ Архитектура

```
flutter-app/crazytrout_admin/
├── lib/
│   ├── main.dart                        — точка входа
│   ├── models/
│   │   ├── client.dart                  — модель клиента (id, имя, телефон, тариф, аватар)
│   │   ├── tariff.dart                  — модель тарифа (id, label, цена)
│   │   ├── catch_row.dart               — строка улова (порода, кг, г, цена/кг, сумма)
│   │   └── receipt.dart                 — чек с реквизитами 54-ФЗ (продавец, СНО, ФН, ФД, ФПД, НДС)
│   ├── data/
│   │   └── demo_data.dart               — тарифы, породы с ценами, демо-клиенты
│   ├── services/
│   │   ├── escpos_builder.dart          — сборка ESC/POS байт для Bluetooth-принтера
│   │   ├── print_service.dart           — печать: Bluetooth и AirPrint/PDF
│   │   └── print_route.dart             — навигация к печати
│   ├── screens/
│   │   ├── home_shell.dart              — нижняя навигация (5 вкладок)
│   │   ├── pond_map_screen.dart         — карта пруда (секторы, фильтры, бронирования)
│   │   ├── receipt_screen.dart          — экран выставления чека
│   │   ├── qr_scan_screen.dart          — полноэкранный QR-сканер
│   │   ├── qr_scan_route.dart           — навигация к сканеру
│   │   ├── splash_screen.dart           — экран загрузки
│   │   └── stub_screen.dart             — заглушка для нереализованных разделов
│   ├── widgets/
│   │   ├── app_dropdown_field.dart       — кастомный дропдаун (ширина меню = ширина поля)
│   │   ├── catch_row_tile.dart           — виджет строки улова
│   │   ├── segmented_control.dart        — переключатель (оплата, тип чека)
│   │   ├── receipt_result_sheet.dart     — шторка с готовым чеком и печатью
│   │   └── float_preloader.dart          — анимированный прелоадер с поплавком
│   └── utils/
│       ├── format.dart                  — форматирование валюты
│       ├── qr_lookup.dart               — поиск клиента по QR-коду
│       └── permission_helper.dart       — запрос разрешений
├── assets/
│   ├── icon/                            — логотип (icon.png, icon_foreground.png, splash_logo.png)
│   ├── fonts/                           — PT Sans (Regular, Bold)
│   ├── avatars/                         — фото-аватары клиентов + иконка инкогнито
│   └── fish/                            — изображения пород рыб (для дропдауна)
├── test/                                — unit и widget тесты
├── integration_test/                    — интеграционные тесты
└── pubspec.yaml                         — зависимости и конфигурация
```

---

## 📦 Зависимости

| Пакет | Версия | Назначение |
|-------|--------|------------|
| `flutter_blue_plus` | ^1.32.12 | Bluetooth-принтер (ESC/POS) |
| `printing` | ^5.12.0 | Системный диалог печати (AirPrint/PDF) |
| `pdf` | ^3.10.8 | Генерация PDF для печати |
| `mobile_scanner` | 5.2.3 | QR-сканер через камеру |
| `permission_handler` | ^11.3.0 | Запрос разрешений (камера, Bluetooth) |
| `intl` | ^0.19.0 | Локализация и форматирование |
| `cupertino_icons` | ^1.0.6 | Иконки в стиле iOS |

**Dev-зависимости:**
| Пакет | Назначение |
|-------|------------|
| `flutter_test` | Unit и widget тесты |
| `flutter_lints` | Линтер |
| `flutter_launcher_icons` | Генерация иконок приложения |

---

## 🧪 Тесты

```bash
flutter test
```

**Покрытие тестов:**
- ✅ Генерация чеков (фискальный, без ФН, гость, пустой улов, пенсионер)
- ✅ Расчёт веса и суммы (кг + граммы → weight → sum)
- ✅ ESC/POS байты (Bluetooth) — структура, заголовок, содержимое, кириллица UTF-8, реквизиты 54-ФЗ
- ✅ PDF генерация (AirPrint) — все типы чекей, реквизиты 54-ФЗ
- ✅ Chunk splitting (BLE MTU / Classic SPP)
- ✅ Корректность данных перед отправкой на принтер
- ✅ Консистентность данных (тарифы, породы, клиенты)
- ✅ Smoke-тесты приложения (запуск, навигация, элементы UI)
- ✅ QR-сканер (поиск клиента по коду)
- ✅ Логика экрана чека
- ✅ Виджеты (SegmentedControl, CatchRowTile, FiltersDropdown)

---

## 🚀 Сборка

### Android APK

```bash
cd flutter-app/crazytrout_admin
flutter pub get
flutter test
flutter build apk --release --split-per-abi
# APK: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### iOS IPA

```bash
cd flutter-app/crazytrout_admin
flutter pub get
flutter test
flutter build ios --release --no-codesign
# Создание IPA:
mkdir -p Payload
cp -r build/ios/iphoneos/Runner.app Payload/
zip -r app-release.ipa Payload
```

### Иконка приложения

```bash
flutter pub run flutter_launcher_icons
```

Логотип Crazy Trout Arena на кремовом фоне `#FBF6EC`. Генерируется автоматически из `assets/icon/icon.png`.

---

## ⚙️ CI/CD

GitHub Actions автоматически собирает приложение при каждом пуше в `main`.

### Build APK & IPA

| Триггер | Действие |
|---------|----------|
| `push` в `main` | Сборка Android APK + iOS IPA, тесты |
| `push` тега `v*` | Сборка + создание GitHub Release |

### Что делает workflow:

1. **Android:**
   - Генерация обёрток проекта
   - Кэш debug-keystore (стабильная подпись между релизами)
   - Установка Bluetooth/Camera разрешений в AndroidManifest.xml
   - Отключение R8 (`isMinifyEnabled = true → false`) — без этого ML Kit DI крашится при старте
   - Sentry native DSN в AndroidManifest (ловит краши до старта Dart/Flutter)
   - Установка зависимостей, генерация иконки
   - Запуск тестов
   - Сборка APK (split-per-abi, arm64)

2. **iOS:**
   - Генерация обёрток проекта
   - Установка зависимостей
   - Разрешения в Info.plist (камера, Bluetooth)
   - Минимальная версия iOS 13.0
   - Генерация иконки
   - Запуск тестов
   - Сборка iOS (no-codesign)
   - Создание IPA

3. **Release** (при теге `v*`):
   - Скачивание APK и IPA
   - Создание GitHub Release с артефактами
   - iOS job имеет `continue-on-error: true` — если IPA не собрался, Android-релиз всё равно создаётся

---

## 🎯 Статус разделов

| Раздел | Статус |
|--------|--------|
| Чек (выставление) | ✅ Полностью функционален (54-ФЗ) |
| QR-сканер | ✅ Функционален |
| Печать Bluetooth (ESC/POS) | ✅ Функциональна (кириллица UTF-8 + отрез + 54-ФЗ) |
| Печать AirPrint (PDF) | ✅ Функциональна (54-ФЗ) |
| Аватары клиентов | ✅ Фото + инициалы для фолбэка |
| Гостевой режим | ✅ С иконкой инкогнито |
| Карта пруда | ✅ Секторы, фильтры, бронирования, профили клиентов |
| Чеки (история) | ✅ Поиск, фильтры, карточка клиента, превью чека |
| Отчёт (финансы) | ✅ Дашборд, KPI, декомпозиция, динамика, оплата/тарифы |
| Профиль | 🔲 Заглушка |

---

## 📊 Релизы

| Версия | Дата | Изменения |
|--------|------|-----------|
| **v1.3.94** | 17.07.2026 | Фикс перекрытия графиков — ClipRect на все CustomPaint |
| **v1.3.93** | 17.07.2026 | 10 правок Отчёты (фильтры, календарь, графики, лейблы, ClipRect), OverlayEntry dropdown на карте, fallback графиков |
| **v1.3.92** | 17.07.2026 | Единый скролл карты + border кнопки фильтров, FinanceDashboardCard к фильтру календаря |
| **v1.3.91** | 17.07.2026 | Расширенные фильтры и сортировка на экране Чеки |
| **v1.3.90** | 17.07.2026 | Dropdown фильтров — вынесен из ListView в Stack-слои |
| **v1.3.89** | 17.07.2026 | Dropdown поверх контента — вынесен в отдельный слой Stack |
| **v1.3.88** | 17.07.2026 | Рыбы в отчёте — разные пропорции, -25%, ClipRRect |
| **v1.3.69** | 16.07.2026 | Финансовый экран: KPI, динамика, структура, оплата/тарифы |
| **v1.3.68** | 16.07.2026 | Фикс dropdown фильтров: Overlay + CompositedTransform + скролл |
| **v1.3.64** | 16.07.2026 | Фикс dropdown фильтров: не перекрывает текст, Stack вместо OverlayEntry, не блокирует скролл |
| **v1.3.63** | 16.07.2026 | Фикс dropdown фильтров (финальный): ValueNotifier вместо GlobalKey |
| **v1.3.62** | 16.07.2026 | Фикс dropdown фильтров: closeDropdown публичный метод, Stack вместо OverlayEntry |
| **v1.3.61** | 16.07.2026 | Фикс dropdown фильтров на карте пруда: позиция, скролл, нижнее меню |
| **v1.3.60** | 16.07.2026 | Фикс: убран unused import format.dart из finance_pie_chart.dart |
| **v1.3.59** | 16.07.2026 | Фикс теста: обновлено Отчёт → Отчёты в widget_test.dart |
| **v1.3.58** | 16.07.2026 | Новые метрики: оплата (столбчатая диаграмма), тарифы (кольцевая диаграмма) |
| **v1.3.56** | 16.07.2026 | Revert: возврат порядка иконок в отчёте (₽ → Клиенты → Рыба) |
| **v1.3.55** | 16.07.2026 | Декомпозиция продаж: круговая диаграмма по 5 породам + вход по тарифам |
| **v1.3.54** | 16.07.2026 | Круговая диаграмма структуры выручки: маржа vs расходы |
| **v1.3.53** | 16.07.2026 | Финансовый дашборд: выручка со спарклайном, маржа, расходы, прогресс-бары |
| **v1.3.52** | 16.07.2026 | Фикс: сумма чека и LTV в одну строку в ленте клиентов |
| **v1.3.51** | 16.07.2026 | Фикс: иконки RGBA с прозрачным фоном, Image.asset вместо Material Icons |
| **v1.3.50** | 16.07.2026 | Фикс: _FilterDropdown в Отчёте — точная копия из checks_screen.dart |
| **v1.3.49** | 16.07.2026 | Страница Отчёт: фильтры, вкладки, статистика улова, таблицы с градиентами |
| **v1.3.48** | 15.07.2026 | Фикс: dropdown фильтры — Listener вместо GestureDetector, скролл работает |
| **v1.3.47** | 15.07.2026 | Фикс: dropdown фильтры карты — скролл страницы работает при раскрытом списке |
| **v1.3.46** | 15.07.2026 | Фикс: видимый цвет для disabled пунктов Нет/Все в dropdown фильтрах |
| **v1.3.45** | 15.07.2026 | Экран Чеки: история, фильтры, карточка клиента, фикс сборки lastVisit |
| **v1.3.44** | 15.07.2026 | Экран Чеки: история, фильтры с календарём, карточка клиента, AirPrint |
| **v1.3.43** | 16.07.2026 | 54-ФЗ: фискальные реквизиты в ESC/POS, PDF и UI чека (продавец, СНО, ФН, ФД, ФПД, НДС, сайт ФНС) |
| **v1.3.42** | 15.07.2026 | UI: карточки «Оплата»/«ИТОГО» переставлены, «Счет заведения», отступы выровнены по карте пруда |
| **v1.3.23** | 14.07.2026 | Карта пруда — начальный экран, двойная рамка сектора, FittedBox для 3-значных значений, фильтры dropdown, BT UTF-8, тесты |
| **v1.3.22** | 14.07.2026 | Карта пруда: секторы, фильтры, стили заголовков, секторы клиентов |
| **v1.3.18** | 13.07.2026 | Настоящие фото рыб в дропдауне, правильная центровка |
| **v1.3.16** | 13.07.2026 | ML Kit crash-фикс + UI v1.3.4 (гостевой режим, аватарки) |
| **v1.3.15** | 13.07.2026 | Фикс краша при старте: отключение R8, keep-правила ML Kit, фиксация mobile_scanner 5.2.3, Sentry |
| v1.3.4 | 12.07.2026 | Гостевой режим с инкогнито, аватарки всех клиентов, QR-сканер ProGuard-фикс, единый стиль полей |
| v1.3.3 | 12.07.2026 | Мок-клиент для QR-тестирования |
| v1.3.2 | 12.07.2026 | Кастомный дропдаун, карточка выбранного клиента |
| v1.3.1 | 12.07.2026 | Возврат на mobile_scanner, фикс null pointer |
| v1.3.0 | 12.07.2026 | split-per-abi (33.5MB → ~13MB) |
| v1.2.0 | 12.07.2026 | QR-сканер клиента |
| v1.1.0 | 12.07.2026 | SplashScreen, фикс widget-тестов |
| v1.0.3 | 12.07.2026 | Исправления сборки |
| v1.0.2 | 12.07.2026 | Исправления сборки |
| v1.0.1 | 12.07.2026 | Исправления сборки |
| v1.0.0 | 12.07.2026 | Первая версия — чек-касса |

---

## 🛠️ Технические детали

### Минимальные требования
- **Android:** minSdkVersion 24 (Android 7.0+)
- **iOS:** 13.0+ (пересечение mobile_scanner ≥12.0 и flutter_blue_plus ≥13.0)
- **Flutter:** 3.44.0+
- **Dart SDK:** ≥3.3.0 <4.0.0

### iOS Info.plist разрешения
- `NSCameraUsageDescription` — камера для QR-сканера
- `NSBluetoothAlwaysUsageDescription` — Bluetooth для печати чеков
- `NSBluetoothPeripheralUsageDescription` — Bluetooth-периферия

### Android разрешения
- `CAMERA` — QR-сканер
- `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` — Bluetooth-принтер (Android 12+)
- `BLUETOOTH` / `BLUETOOTH_ADMIN` — Bluetooth (Android ≤11)
- `ACCESS_FINE_LOCATION` — Bluetooth-сканирование (Android ≤11)

### Sentry
Приложение интегрировано с [Sentry](https://sentry.io) для мониторинга крашей:
- **Dart-level:** `SentryFlutter.init()` в `main.dart`
- **Native-level:** `meta-data` в `AndroidManifest.xml` (ловит краши до старта Flutter-движка)

### ProGuard/R8
R8 отключён в workflow (`isMinifyEnabled = false`). ProGuard keep-правила оставлены как страховка:
```proguard
# Flutter embedding
-keep class io.flutter.** { *; }

# ML Kit common (DI-система, MlKitInitProvider)
-keep class com.google.mlkit.common.** { *; }

# ML Kit barcode scanning
-keep class com.google.mlkit.vision.barcode.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }
-keep class androidx.camera.** { *; }

# Bluetooth-принтер
-keep class com.lib.flutter_blue_plus.** { *; }

# Печать
-keep class net.nfet.flutter.printing.** { *; }

# Разрешения
-keep class com.baseflow.permissionhandler.** { *; }
```

---

## 📁 Веб-прототип

В корне репозитория также находится HTML/CSS/JS прототип CRM (`index.html`) — витрина для демонстрации UI перед нативной разработкой. Переключение «Десктоп / Мобайл», навигация по экранам.

---

## 🤝 Контрибьюция

1. Fork репозитория
2. Создайте ветку (`git checkout -b feature/my-feature`)
3. Закоммитьте изменения (`git commit -m 'feat: мой фича'`)
4. Запушьте (`git push origin feature/my-feature`)
5. Создайте Pull Request

---

## 📄 Лицензия

Проприетарная. Все права защищены.
