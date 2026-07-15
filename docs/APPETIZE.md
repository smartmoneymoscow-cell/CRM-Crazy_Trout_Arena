# Appetize.io — эмулятор в браузере

Приложение запускается в облачном Android-эмуляторе прямо в браузере.

## Ссылка

🔗 **https://appetize.io/app/3pyz3i55q35iixrkebtthhiqiq**

## API-ключ

```
tok_mmcyms2cp2sd43fgi53ypx6wsi
```

> ⚠️ Не публикуй ключ в открытом доступе. Используй только для автоматизации сборок.

## Обновление APK

После сборки новой версии загрузи APK через API:

```bash
curl -X POST "https://api.appetize.io/v1/apps" \
  -u "tok_mmcyms2cp2sd43fgi53ypx6wsi:" \
  -F "file=@app-release.apk" \
  -F "platform=android" \
  -F "note=Crazy Trout Arena CRM vX.Y.Z"
```

Ответ вернёт `publicURL` — это и есть ссылка на эмулятор.

## Лимиты

- Бесплатный тариф: **100 минут/месяц**
- Сессия: ~15 минут бездействия → автозакрытие
- Платформа: Android (по умолчанию)

## Управление

- Панель: https://appetize.io/manage/3pyz3i55q35iixrkebtthhiqiq
- Настройки API-ключей: https://appetize.io/account/api-keys