# 📱 Appetize.io — Эмулятор приложения в браузере

> Облачный эмулятор iOS/Android, который запускает `.apk` и `.ipa` прямо в браузере без установки.

## 🔗 Ссылка

**https://appetize.io/**

## 🔑 API-ключ

```
YOUR_APPETIZE_API_TOKEN
```

> Замени на свой токен из настроек Appetize.io → Account → API Keys.

## 🚀 Как использовать

### Через веб-интерфейс

1. Зайди на https://appetize.io/demo
2. Нажми **Upload**
3. Загрузи APK: https://github.com/smartmoneymoscow-cell/CRM-/releases/latest/download/app-release.apk
4. Выбери устройство (iPhone / Android) и версию OS
5. Эмулятор запустится в браузере

### Через API (автоматизация)

#### Загрузка APK

```bash
curl -X POST "https://api.appetize.io/v1/app/upload" \
  -H "Authorization: Bearer YOUR_APPETIZE_API_TOKEN" \
  -F "file=@app-release.apk" \
  -F "platform=android" \
  -F "osVersion=15.0"
```

Ответ:
```json
{
  "publicKey": "abc123...",
  "appURL": "https://appetize.io/embed/abc123..."
}
```

#### Загрузка IPA (iOS)

```bash
curl -X POST "https://api.appetize.io/v1/app/upload" \
  -H "Authorization: Bearer YOUR_APPETIZE_API_TOKEN" \
  -F "file=@app-release.ipa" \
  -F platform=ios" \
  -F "osVersion=18.0"
```

#### Получение embed-ссылки

После загрузки получаешь `publicKey`. Embed-ссылка:

```
https://appetize.io/embed/<publicKey>
```

Можно вставить в `<iframe>` на любой странице:

```html
<iframe
  src="https://appetize.io/embed/<publicKey>?device=iphone15pro&osVersion=18.0"
  width="400"
  height="800"
  frameborder="0"
></iframe>
```

### Параметры embed

| Параметр | Пример | Описание |
|----------|--------|----------|
| `device` | `iphone15pro`, `pixel8` | Модель устройства |
| `osVersion` | `18.0`, `15.0` | Версия ОС |
| `scale` | `75` | Масштаб (по умолчанию 100) |
| `orientation` | `portrait`, `landscape` | Ориентация |
| `language` | `ru`, `en` | Язык системы |
| `launchUrl` | `myapp://deep-link` | Deep link при запуске |

## 📋 Тарифы

| Тариф | Минуты/месяц | Цена |
|-------|-------------|------|
| Free | 30 мин | $0 |
| Starter | 500 мин | $40/мес |
| Team | 2000 мин | $150/мес |
| Enterprise | ∞ | По запросу |

> Бесплатного таринга хватает на ~30 минут эмуляции — достаточно для быстрого тестирования.

## ⚠️ Ограничения

- iOS-сборка без кодирования (`no-codesign`) — Appetize может потребовать provisioning profile
- Bluetooth-принтер не работает в эмуляторе (нет реального Bluetooth)
- Камера/QR-сканер — только через заглушку (нет реальной камеры)
- Push-уведомления не поддерживаются

## 🔗 Полезные ссылки

- Документация API: https://docs.appetize.io
- Список устройств: https://docs.appetize.io/devices
- Тарифы: https://appetize.io/pricing
