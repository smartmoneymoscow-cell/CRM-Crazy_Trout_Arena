# ⛔ DO NOT MERGE — PREVIEW BRANCH

Эта ветка (`preview/receipt-ui-changes`) создана для визуального превью UI-правок.

**НЕ МЕРЖИТЬ В MAIN.**

Правки ещё не прошли ревью и тестирование на устройстве.

## Что изменено
- Объединён блок «Способ оплаты» + «Тип чека» с dropdown
- Добавлен новый способ оплаты «Счет зав.» (houseAccount)
- Поменяны местами кнопки печати (AirPrint первая, оранжевая)
- Отступы и фон приведены к эталону «Карта пруда»

## После ревью
Удалить ветку:
```bash
git branch -D preview/receipt-ui-changes
git push origin --delete preview/receipt-ui-changes
```
