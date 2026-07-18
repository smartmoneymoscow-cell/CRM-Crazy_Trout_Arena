# 🐟 Crazy Trout Arena — Telegram Mini App

> Telegram Mini App (Web App) версия CRM-системы для чек-кассы пруда платной рыбалки.
> Работает прямо внутри Telegram — без установки, на iOS и Android.

---

## 📋 Статус

| Модуль | Статус | Примечание |
|--------|:------:|------------|
| Каркас (навигация, тема) | ✅ | SPA-роутер, 5 вкладок, тёмная тема |
| Выставление чеков | ✅ | Тарифы, улов, 54-ФЗ |
| QR-сканер | ✅ | Telegram API + getUserMedia + input capture |
| Печать (Android) | ✅ | Web Bluetooth + ESC/POS |
| Печать (iOS) | ✅ | Star PassPRNT / PDF fallback |
| Карта пруда | ✅ | 16 секторов, профили клиентов |
| Финансовый дашборд | ✅ | KPI, графики Chart.js |
| История чеков | ✅ | Поиск, фильтры |
| Профиль клиента | ✅ | Статистика, меню |
| Telegram-бот | ✅ | Приём чеков, уведомления, команды |

---

## 🏗️ Архитектура

```
telegram-mini-app/
├── index.html                    — точка входа, Telegram WebApp SDK
├── .gitignore
├── README.md                     — этот файл
├── package.json                  — зависимости и скрипты
├── src/
│   ├── css/
│   │   ├── variables.css         — CSS-переменные (бежевая палитра, оранжевые акценты)
│   │   ├── base.css              — сброс, типографика (PT Sans)
│   │   ├── components.css        — кнопки, инпуты, карточки
│   │   └── screens.css           — стили экранов
│   ├── js/
│   │   ├── app.js                — инициализация, роутинг
│   │   ├── core/
│   │   │   ├── telegram.js       — обёртка над Telegram WebApp API
│   │   │   ├── router.js         — SPA-роутер (hash-based)
│   │   │   ├── store.js          — состояние (клиенты, чеки, настройки)
│   │   │   └── events.js         — шина событий
│   │   ├── screens/
│   │   │   ├── receipt.js        — экран выставления чека
│   │   │   ├── checks.js         — экран истории чеков
│   │   │   ├── pond-map.js       — экран карты пруда
│   │   │   ├── report.js         — экран финансового дашборда
│   │   │   └── profile.js        — экран профиля
│   │   ├── widgets/
│   │   │   ├── nav-bar.js        — нижняя навигация (5 вкладок)
│   │   │   ├── search-bar.js     — поисковая строка
│   │   │   ├── tariff-selector.js — выбор тарифа
│   │   │   ├── catch-row.js      — строка улова
│   │   │   ├── sector-card.js    — карточка сектора
│   │   │   ├── kpi-card.js       — KPI карточка
│   │   │   └── receipt-preview.js — превью чека
│   │   ├── services/
│   │   │   ├── printer.js        — печать (Web Bluetooth + PassPRNT + PDF)
│   │   │   ├── qr-scanner.js     — QR-сканер (Telegram API + fallback)
│   │   │   ├── camera.js         — камера (getUserMedia + input capture)
│   │   │   └── storage.js        — Telegram CloudStorage / localStorage
│   │   └── utils/
│   │       ├── format.js         — форматирование валюты, дат
│   │       ├── escpos.js         — ESC/POS байт-кодировщик
│   │       └── pdf.js            — PDF генерация (jspdf)
│   └── assets/
│       ├── icons/                — SVG иконки
│       ├── fish/                 — изображения пород рыб
│       └── avatars/              — аватары клиентов
├── docs/
│   └── ARCHITECTURE.md           — описание архитектуры
└── tests/
    └── ...                       — unit-тесты
```

---

## 🛠️ Технологии

| Технология | Назначение |
|-----------|------------|
| **Vanilla JS (ES modules)** | Основной фреймворк — без React/Vue, минимальный размер |
| **Telegram WebApp SDK v9.6** | Интеграция с Telegram (тема, кнопки, haptic, QR, storage) |
| **CSS Variables** | Дизайн-система (бежевая палитра #FBF6EC, оранжевый #E8912B) |
| **PT Sans** | Шрифт (Google Fonts) |
| **ReceiptPrinterEncoder** | ESC/POS кодировка для Bluetooth-принтера |
| **jsPDF** | PDF генерация чеков (iOS fallback) |
| **jsQR** | Декодирование QR из изображений (fallback) |
| **Chart.js** | Графики и диаграммы (дашборд) |

---

## 🔗 Интеграция с Telegram WebApp API

| Возможность | API | Описание |
|-------------|-----|----------|
| QR-сканер | `WebApp.showScanQrPopup()` | Нативный сканер камеры |
| HapticFeedback | `WebApp.HapticFeedback` | Тактильная отдача |
| Тема | `WebApp.themeParams` | Авто тёмная/светлая |
| CloudStorage | `WebApp.CloudStorage` | Хранение данных |
| SecureStorage | `WebApp.SecureStorage` | Защищённое хранилище |
| Кнопки | `WebApp.MainButton` / `WebApp.SecondaryButton` | Нижние кнопки |
| Геолокация | `WebApp.LocationManager` | GPS для карты пруда |
| Оплата | Telegram Stars + провайдеры | Google Pay / Apple Pay |
| Поделиться | `WebApp.shareMessage()` | Отправка чека в чат |
| Полный экран | `WebApp.requestFullscreen()` | Иммерсивный режим |
| Ориентация | `WebApp.lockOrientation()` | Фиксация экрана |

---

## 🖨️ Печать — стратегия

| Платформа | Метод | Описание |
|-----------|-------|----------|
| **Android** | Web Bluetooth | Прямое BLE-подключение к принтеру, ESC/POS |
| **Android** (fallback) | PassPRNT URL scheme | Через приложение Star Micronics |
| **iOS** | PassPRNT URL scheme | Нативное iOS-приложение, Bluetooth-печать |
| **iOS** (fallback) | PDF + AirPrint | Системный диалог печати |
| **Любая** (WiFi) | TCP:9100 | Прямая печать на WiFi-принтер |

---

## 🚀 Запуск локально

```bash
cd telegram-mini-app

# Любой локальный сервер (HTTPS нужен для Telegram WebApp)
npx serve . --ssl
# или
python3 -m http.server 8443

# Открыть в Telegram (для тестирования):
# https://t.me/YOUR_BOT/app?url=https://localhost:8443
```

---

## 🤖 Telegram-бот

```bash
cd telegram-mini-app/bot
npm install
cp .env.example .env  # заполнить токены
npm start
```

📖 [Подробная инструкция по деплою бота](bot/README.md)

---

## 📦 Сборка

```bash
# Минификация (опционально)
npx terser src/js/app.js -o dist/app.js -c -m
npx cleancss src/css/*.css -o dist/style.css

# Деплой на GitHub Pages / любой хостинг
```

---

## ⚠️ Ограничения

| Ограничение | Решение |
|-------------|---------|
| iOS: нет Web Bluetooth | PassPRNT URL scheme / PDF fallback |
| Android: повторные диалоги камеры | Stream singleton + Telegram QR API |
| WebView: нет доступа к файловой системе | Telegram CloudStorage + DeviceStorage |
| Нет бэкенда | Демо-данные, localStorage (как Flutter MVP) |

---

## 📐 Дизайн-система

Идентична Flutter-приложению:

| Элемент | Значение |
|---------|----------|
| Фон основной | `#FBF6EC` |
| Фон инпутов | `#F3EEE4` |
| Акцент | `#E8912B` |
| Текст основной | `#2D2D2D` |
| Текст вторичный | `#8E8E8E` |
| Шрифт | PT Sans (Regular 400, Bold 700) |
| Радиус | 12px (карточки), 8px (инпуты) |
| Тень карточек | `0 2px 8px rgba(0,0,0,0.06)` |
