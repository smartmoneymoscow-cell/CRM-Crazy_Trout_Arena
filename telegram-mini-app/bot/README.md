# 🤖 Деплой Telegram-бота

## 1. Создать бота в BotFather

1. Откройте [@BotFather](https://t.me/BotFather) в Telegram
2. Отправьте `/newbot`
3. Введите имя: `Crazy Trout Arena CRM`
4. Введите username: `crazy_trout_arena_bot` (или доступный)
5. Сохраните **Bot Token**

## 2. Настроить Mini App

В [@BotFather](https://t.me/BotFather):

1. Отправьте `/mybots`
2. Выберите вашего бота
3. **Bot Settings → Configure Mini App → Enable Mini App**
4. Введите URL: `https://smartmoneymoscow-cell.github.io/CRM-Crazy_Trout_Arena/mini-app/`
5. **Bot Settings → Menu Button** (опционально)
   - Введите URL для кнопки меню

## 3. Деплой бота

### Вариант A: Локальный запуск

```bash
cd telegram-mini-app/bot
npm install

# Создать .env файл
cp .env.example .env
# Заполнить BOT_TOKEN, MINI_APP_URL, ADMIN_IDS

npm start
```

### Вариант B: Railway (бесплатно)

1. Зарегистрируйтесь на [railway.app](https://railway.app)
2. Подключите GitHub-репозиторий
3. Выберите папку `telegram-mini-app/bot`
4. Добавьте переменные окружения:
   - `BOT_TOKEN` — токен от BotFather
   - `MINI_APP_URL` — URL Mini App
   - `ADMIN_IDS` — Telegram ID администраторов
5. Deploy

### Вариант C: Render (бесплатно)

1. Зарегистрируйтесь на [render.com](https://render.com)
2. New → Web Service → Connect GitHub
3. Root Directory: `telegram-mini-app/bot`
4. Build Command: `npm install`
5. Start Command: `npm start`
6. Environment Variables: `BOT_TOKEN`, `MINI_APP_URL`, `ADMIN_IDS`

### Вариант D: VPS (DigitalOcean, Hetzner и т.д.)

```bash
# Установка Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Клонировать репозиторий
git clone https://github.com/smartmoneymoscow-cell/CRM-Crazy_Trout_Arena.git
cd CRM-Crazy_Trout_Arena/telegram-mini-app/bot

# Установить зависимости
npm install

# Создать .env
cp .env.example .env
nano .env  # заполнить токены

# Запустить через PM2
npm install -g pm2
pm2 start index.js --name trout-bot
pm2 save
pm2 startup
```

## 4. Проверка

1. Откройте бота в Telegram
2. Отправьте `/start`
3. Нажмите «Открыть CRM»
4. Создайте чек → «Отправить в чат»
5. Бот должен получить данные и показать чек

## 5. Команды бота

| Команда | Описание |
|---------|----------|
| `/start` | Главное меню с кнопкой Mini App |
| `/app` | Открыть CRM |
| `/stats` | Быстрая статистика |

## 6. Что бот умеет

- 📱 Открывает Mini App по кнопке
- 🧾 Принимает чеки из Mini App (web_app_data)
- 📊 Показывает статистику
- 🖨️ Кнопки «Напечатать» / «PDF» в чеке
- 👤 Ссылка на профиль клиента
- 🔔 Уведомления админам о новых чеках
