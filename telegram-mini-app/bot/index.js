// === Telegram Bot — Crazy Trout Arena CRM ===
// Принимает данные из Mini App, отправляет чеки в чат, управляет печатью

const { Bot, GrammyError, HttpError } = require('grammy');

// --- Конфигурация ---
const BOT_TOKEN = process.env.BOT_TOKEN || 'YOUR_BOT_TOKEN_HERE';
const MINI_APP_URL = process.env.MINI_APP_URL || 'https://smartmoneymoscow-cell.github.io/CRM-Crazy_Trout_Arena/mini-app/';
const ADMIN_IDS = (process.env.ADMIN_IDS || '').split(',').filter(Boolean).map(Number);

const bot = new Bot(BOT_TOKEN);

// --- Команда /start ---
bot.command('start', async (ctx) => {
  await ctx.reply(
    '🐟 *Crazy Trout Arena — CRM*\n\n' +
    'Управляйте чеками, клиентами и прудом прямо в Telegram!',
    {
      parse_mode: 'Markdown',
      reply_markup: {
        inline_keyboard: [
          [{ text: '🧾 Открыть CRM', web_app: { url: MINI_APP_URL } }],
          [{ text: '📊 Статистика за день', callback_data: 'day_stats' }, { text: '🐠 Остатки', callback_data: 'fish_stock' }],
          [{ text: '📊 Общая статистика', callback_data: 'stats' }],
          [{ text: '❓ Помощь', callback_data: 'help' }],
        ]
      }
    }
  );
});

// --- Команда /menu — закреплённое меню с кнопкой Mini App ---
bot.command('menu', async (ctx) => {
  const msg = await ctx.reply(
    '🐟 *Crazy Trout Arena — CRM*\n' +
    '━━━━━━━━━━━━━━━\n\n' +
    '🧾 *Чеки* — выставление и история\n' +
    '🗺️ *Карта* — 16 секторов пруда\n' +
    '📊 *Отчёты* — финансы и статистика\n' +
    '👤 *Профиль* — данные клиентов\n\n' +
    'Нажмите кнопку ниже 👇',
    {
      parse_mode: 'Markdown',
      reply_markup: {
        inline_keyboard: [
          [{ text: '🐟 Открыть CRM', web_app: { url: MINI_APP_URL } }],
          [{ text: '📊 Статистика за день', callback_data: 'day_stats' }, { text: '🐠 Остатки', callback_data: 'fish_stock' }],
        ]
      }
    }
  );
  // Закрепляем сообщение
  try {
    await ctx.api.pinChatMessage(ctx.chat.id, msg.message_id, { disable_notification: true });
  } catch (e) {
    console.warn('Не удалось закрепить:', e.message);
  }
});

// --- Команда /app — открыть Mini App ---
bot.command('app', async (ctx) => {
  await ctx.reply('Откройте CRM-систему:', {
    reply_markup: {
      inline_keyboard: [
        [{ text: '🐟 Открыть Crazy Trout Arena', web_app: { url: MINI_APP_URL } }]
      ]
    }
  });
});

// --- Команда /stats — быстрая статистика ---
bot.command('stats', async (ctx) => {
  // TODO: подключить реальные данные
  await ctx.reply(
    '📊 *Статистика за сегодня*\n\n' +
    '🧾 Чеков: 5\n' +
    '💰 Выручка: 10 260₽\n' +
    '👥 Клиентов: 4\n' +
    '🐟 Улов: 6.6 кг\n' +
    '📍 Секторов занято: 5/16',
    { parse_mode: 'Markdown' }
  );
});

// --- Обработка данных из Mini App ---
bot.on('message:web_app_data', async (ctx) => {
  const rawData = ctx.message.web_app_data.data;
  
  try {
    const data = JSON.parse(rawData);
    
    if (data.type === 'receipt') {
      await handleReceipt(ctx, data.data);
    } else if (data.type === 'print_request') {
      await handlePrintRequest(ctx, data);
    } else {
      await ctx.reply(`📦 Данные из Mini App:\n\`\`\`json\n${JSON.stringify(data, null, 2)}\`\`\``, {
        parse_mode: 'Markdown'
      });
    }
  } catch (e) {
    await ctx.reply(`📦 Данные из Mini App:\n${rawData}`);
  }
});

// --- Обработка чека ---
async function handleReceipt(ctx, receipt) {
  const paymentLabels = { cash: '💵 Наличные', card: '💳 Карта', account: '🏢 Счёт' };
  
  let catchesText = '';
  if (receipt.catches?.length) {
    catchesText = '\n\n🐟 *Улов:*\n';
    for (const c of receipt.catches) {
      const weight = c.kg > 0 
        ? `${c.kg}кг${c.grams > 0 ? c.grams + 'г' : ''}` 
        : `${c.grams}г`;
      catchesText += `  • ${c.breedLabel} ${weight} × ${c.pricePerKg}₽ = ${c.sum}₽\n`;
    }
  }

  const text = 
    '🧾 *НОВЫЙ ЧЕК*\n' +
    '━━━━━━━━━━━━━━━\n' +
    `📋 Номер: \`${receipt.id}\`\n` +
    `📅 Дата: ${receipt.date}\n` +
    `👤 Клиент: ${receipt.clientName}\n` +
    `🏷️ Тариф: ${receipt.tariffLabel} — ${receipt.tariffPrice}₽` +
    catchesText + '\n\n' +
    `💰 *ИТОГО: ${receipt.total.toLocaleString('ru-RU')}₽*\n` +
    `${paymentLabels[receipt.paymentMethod] || receipt.paymentMethod}\n` +
    (receipt.fiscal ? '✅ Фискальный чек (54-ФЗ)' : '⚠️ Без ФН');

  await ctx.reply(text, {
    parse_mode: 'Markdown',
    reply_markup: {
      inline_keyboard: [
        [
          { text: '🖨️ Напечатать', callback_data: `print_${receipt.id}` },
          { text: '📄 PDF', callback_data: `pdf_${receipt.id}` },
        ],
        [{ text: '👤 Профиль клиента', callback_data: `client_${receipt.clientId}` }]
      ]
    }
  });

  // Уведомление админам
  for (const adminId of ADMIN_IDS) {
    try {
      await bot.api.sendMessage(adminId, `🔔 Новый чек от ${ctx.from.first_name}:\n💰 ${receipt.total}₽ — ${receipt.clientName}`);
    } catch (e) {
      console.warn(`Failed to notify admin ${adminId}:`, e.message);
    }
  }
}

// --- Обработка запроса на печать ---
async function handlePrintRequest(ctx, data) {
  await ctx.reply(`🖨️ Запрос на печать чека \`${data.receiptId}\`\n\nДля печати используйте кнопку в Mini App или отправьте чек на принтер через PassPRNT.`, {
    parse_mode: 'Markdown'
  });
}

// --- Callback: статистика ---
bot.callbackQuery('stats', async (ctx) => {
  await ctx.answerCallbackQuery();
  await ctx.reply(
    '📊 *Статистика*\n\n' +
    'За сегодня: 5 чеков, 10 260₽\n' +
    'За неделю: 28 чеков, 67 400₽\n' +
    'За месяц: 124 чека, 285 600₽',
    { parse_mode: 'Markdown' }
  );
});

// --- Callback: помощь ---
bot.callbackQuery('help', async (ctx) => {
  await ctx.answerCallbackQuery();
  await ctx.reply(
    '❓ *Команды бота:*\n\n' +
    '/start — Главное меню\n' +
    '/menu — Закреплённое меню с кнопкой\n' +
    '/app — Открыть CRM\n' +
    '/stats — Статистика\n\n' +
    '📱 *Mini App*\n' +
    'Нажмите кнопку "Открыть CRM" для работы с чеками, картой пруда и отчётами.',
    { parse_mode: 'Markdown' }
  );
});

// --- Callback: печать ---
bot.callbackQuery(/^print_(.+)$/, async (ctx) => {
  const receiptId = ctx.match[1];
  await ctx.answerCallbackQuery({ text: `🖨️ Чек ${receiptId} отправлен на печать` });
  await ctx.reply(`🖨️ Чек \`${receiptId}\` отправлен на принтер.\n\nУбедитесь, что:\n• Принтер включён\n• Bluetooth подключён\n• Star PassPRNT установлен (iOS)`, {
    parse_mode: 'Markdown'
  });
});

// --- Callback: PDF ---
bot.callbackQuery(/^pdf_(.+)$/, async (ctx) => {
  const receiptId = ctx.match[1];
  await ctx.answerCallbackQuery({ text: `📄 Генерация PDF...` });
  await ctx.reply(`📄 PDF чека \`${receiptId}\` будет отправлен файлом.\n\n_(В разработке)_`, {
    parse_mode: 'Markdown'
  });
});

// --- Callback: профиль клиента ---
bot.callbackQuery(/^client_(\d+)$/, async (ctx) => {
  const clientId = ctx.match[1];
  await ctx.answerCallbackQuery();
  // TODO: загрузить реальные данные клиента
  await ctx.reply(
    `👤 *Профиль клиента #${clientId}*\n\n` +
    'Имя: —\n' +
    'Телефон: —\n' +
    'Посещений: —\n' +
    'LTV: —₽',
    { parse_mode: 'Markdown' }
  );
});

// --- Callback: статистика за день ---
bot.callbackQuery('day_stats', async (ctx) => {
  await ctx.answerCallbackQuery();
  const now = new Date();
  const today = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

  // Демо-данные (в продакшене — из БД)
  const dayReceipts = [
    { tariff: 'Стандарт', catches: [{ breed: 'Осётр', kg: 2.4, sum: 4536 }], total: 5286, payment: 'card', fiscal: true },
    { tariff: 'Стандарт', catches: [{ breed: 'Карп', kg: 1.8, sum: 1062 }], total: 1812, payment: 'cash', fiscal: false },
    { tariff: 'Гостевой', catches: [], total: 500, payment: 'card', fiscal: true },
    { tariff: 'Стандарт', catches: [{ breed: 'Форель', kg: 1.2, sum: 1440 }], total: 2190, payment: 'card', fiscal: true },
    { tariff: 'Пенсионер', catches: [{ breed: 'Линь', kg: 0.9, sum: 621 }], total: 621, payment: 'cash', fiscal: false },
  ];

  const totalRevenue = dayReceipts.reduce((s, r) => s + r.total, 0);
  const totalCatch = dayReceipts.reduce((s, r) => s + r.catches.reduce((cs, c) => cs + c.sum, 0), 0);
  const tariffBreakdown = {};
  const paymentBreakdown = {};
  const fishBreakdown = {};

  dayReceipts.forEach(r => {
    tariffBreakdown[r.tariff] = (tariffBreakdown[r.tariff] || 0) + r.total;
    const pLabel = r.payment === 'card' ? '💳 Карта' : r.payment === 'cash' ? '💵 Наличные' : '🏢 Счёт';
    paymentBreakdown[pLabel] = (paymentBreakdown[pLabel] || 0) + 1;
    r.catches.forEach(c => {
      if (!fishBreakdown[c.breed]) fishBreakdown[c.breed] = { kg: 0, sum: 0 };
      fishBreakdown[c.breed].kg += c.kg;
      fishBreakdown[c.breed].sum += c.sum;
    });
  });

  let text = `📊 *Статистика за ${today}*\n`;
  text += '━━━━━━━━━━━━━━━\n\n';
  text += `💰 *Выручка: ${totalRevenue.toLocaleString('ru-RU')}₽*\n`;
  text += `🧾 Чеков: ${dayReceipts.length}\n`;
  text += `🐟 Улов: ${totalCatch.toLocaleString('ru-RU')}₽\n\n`;

  text += '📋 *По тарифам:*\n';
  for (const [tariff, sum] of Object.entries(tariffBreakdown)) {
    const pct = Math.round(sum / totalRevenue * 100);
    text += `  • ${tariff}: ${sum.toLocaleString('ru-RU')}₽ (${pct}%)\n`;
  }

  text += '\n💳 *По оплате:*\n';
  for (const [method, count] of Object.entries(paymentBreakdown)) {
    text += `  • ${method}: ${count} чек.\n`;
  }

  if (Object.keys(fishBreakdown).length) {
    text += '\n🐠 *По породам:*\n';
    for (const [breed, data] of Object.entries(fishBreakdown)) {
      text += `  • ${breed}: ${data.kg.toFixed(1)} кг = ${data.sum.toLocaleString('ru-RU')}₽\n`;
    }
  }

  text += '\n_Данные демонстрационные_';

  await ctx.reply(text, { parse_mode: 'Markdown' });
});

// --- Callback: остатки по рыбам ---
bot.callbackQuery('fish_stock', async (ctx) => {
  await ctx.answerCallbackQuery();

  // Демо-данные остатков (в продакшене — из БД)
  // Последний столбец верхней таблицы рыб: остаток в кг
  const stock = [
    { breed: '🐟 Осётр', stock: 45.2, max: 80, price: 1890 },
    { breed: '🐠 Карп', stock: 62.8, max: 100, price: 590 },
    { breed: '🐡 Амур', stock: 28.4, max: 50, price: 750 },
    { breed: '🎣 Линь', stock: 15.6, max: 40, price: 690 },
    { breed: '🍣 Форель', stock: 33.1, max: 60, price: 1200 },
  ];

  let text = '🐠 *Остатки по рыбам*\n';
  text += '━━━━━━━━━━━━━━━\n\n';

  stock.forEach(f => {
    const pct = Math.round(f.stock / f.max * 100);
    const bar = pct > 60 ? '🟢' : pct > 30 ? '🟡' : '🔴';
    const barLen = Math.round(pct / 10);
    const barStr = '█'.repeat(barLen) + '░'.repeat(10 - barLen);
    text += `${f.breed}\n`;
    text += `  ${bar} \`${barStr}\` ${pct}%\n`;
    text += `  Остаток: *${f.stock.toFixed(1)} кг* / ${f.max} кг\n`;
    text += `  Цена: ${f.price}₽/кг\n\n`;
  });

  const totalStock = stock.reduce((s, f) => s + f.stock, 0);
  const totalValue = stock.reduce((s, f) => s + f.stock * f.price, 0);
  text += `📦 *Всего: ${totalStock.toFixed(1)} кг*\n`;
  text += `💰 *На сумму: ${totalValue.toLocaleString('ru-RU')}₽*\n`;
  text += '\n_Данные демонстрационные_';

  await ctx.reply(text, { parse_mode: 'Markdown' });
});

// --- Обработка ошибок ---
bot.catch((err) => {
  const ctx = err.ctx;
  const e = err.error;
  
  if (e instanceof GrammyError) {
    console.error('Grammy error:', e.description);
  } else if (e instanceof HttpError) {
    console.error('HTTP error:', e);
  } else {
    console.error('Unknown error:', e);
  }
});

// --- Запуск ---
bot.start({
  onStart: (botInfo) => {
    console.log(`🐟 Бот @${botInfo.username} запущен!`);
    console.log(`📱 Mini App: ${MINI_APP_URL}`);
  }
});
