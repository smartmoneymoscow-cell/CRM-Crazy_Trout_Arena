// === Screen: Выставление чека ===

import { store, TARIFFS, FISH_BREEDS } from '../core/store.js';
import { tg } from '../core/telegram.js';
import { qrScanner } from '../services/qr-scanner.js';
import { printer } from '../services/printer.js';

let currentClient = null;
let currentTariff = 'standard';
let currentCatches = [];
let paymentMethod = 'cash';
let isFiscal = true;

export function renderReceipt() {
  const el = document.createElement('div');
  el.className = 'screen screen-receipt';
  el.innerHTML = `
    <!-- Поиск клиента -->
    <div class="search-bar">
      <span class="search-icon">🔍</span>
      <input class="input" id="client-search" type="text" placeholder="Имя или телефон клиента...">
    </div>

    <!-- QR-сканер -->
    <button class="btn btn-secondary btn-full" id="btn-scan-qr" style="margin-bottom: var(--spacing-lg);">
      📷 Сканировать QR-код
    </button>

    <!-- Информация о клиенте -->
    <div id="client-section" class="card hidden" style="margin-bottom: var(--spacing-lg);">
      <div class="receipt-header">
        <div class="client-avatar" id="client-avatar">?</div>
        <div class="client-info">
          <div class="client-name" id="client-name">—</div>
          <div class="client-phone" id="client-phone">—</div>
        </div>
        <span class="badge badge-accent" id="client-level">—</span>
      </div>
    </div>

    <!-- Тарифы -->
    <h3 style="margin-bottom: var(--spacing-md); font-size: var(--font-size-lg);">Тариф</h3>
    <div class="tariff-grid" id="tariff-grid">
      ${TARIFFS.map(t => `
        <div class="tariff-card ${t.id === currentTariff ? 'selected' : ''}" data-tariff="${t.id}">
          <div class="tariff-name">${t.label}</div>
          <div class="tariff-price">${t.price}₽</div>
        </div>
      `).join('')}
    </div>

    <!-- Улов -->
    <h3 style="margin-bottom: var(--spacing-md); font-size: var(--font-size-lg);">Улов</h3>
    <div id="catch-list"></div>
    <button class="btn btn-secondary btn-full" id="btn-add-catch" style="margin-top: var(--spacing-sm);">
      + Добавить рыбу
    </button>

    <!-- Оплата -->
    <div class="divider"></div>
    <h3 style="margin-bottom: var(--spacing-md); font-size: var(--font-size-lg);">Оплата</h3>
    <div class="segmented" id="payment-method" style="margin-bottom: var(--spacing-md);">
      <button class="segmented-item active" data-method="cash">Наличные</button>
      <button class="segmented-item" data-method="card">Карта</button>
      <button class="segmented-item" data-method="account">Счёт</button>
    </div>

    <!-- Тип чека -->
    <div class="segmented" id="receipt-type" style="margin-bottom: var(--spacing-xl);">
      <button class="segmented-item active" data-fiscal="true">Фискальный</button>
      <button class="segmented-item" data-fiscal="false">Без ФН</button>
    </div>

    <!-- Итого -->
    <div class="card" style="margin-bottom: var(--spacing-lg);">
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <span style="font-size: var(--font-size-lg);">ИТОГО</span>
        <span style="font-size: var(--font-size-xxl); font-weight: bold; color: var(--color-accent);" id="total-amount">750₽</span>
      </div>
    </div>

    <!-- Кнопки -->
    <button class="btn btn-primary btn-full" id="btn-print" style="margin-bottom: var(--spacing-sm);">
      🖨️ Напечатать чек
    </button>
    <button class="btn btn-secondary btn-full" id="btn-send-chat">
      💬 Отправить в чат
    </button>
  `;

  setTimeout(() => initReceiptHandlers(), 0);
  return el;
}

function initReceiptHandlers() {
  // --- Поиск клиента ---
  const searchInput = document.getElementById('client-search');
  searchInput?.addEventListener('input', (e) => {
    const client = store.findClient(e.target.value);
    if (client) {
      selectClient(client);
    }
  });

  // --- QR-сканер ---
  document.getElementById('btn-scan-qr')?.addEventListener('click', async () => {
    const result = await qrScanner.scan('auto');
    if (result) {
      // Ищем клиента по ID из QR или по имени
      const client = store.getClientById(result) || store.findClient(result);
      if (client) {
        selectClient(client);
        if (searchInput) searchInput.value = client.name;
      } else {
        tg.showAlert(`Клиент не найден: ${result}`);
      }
    }
  });

  // --- Тарифы ---
  document.getElementById('tariff-grid')?.addEventListener('click', (e) => {
    const card = e.target.closest('.tariff-card');
    if (!card) return;
    document.querySelectorAll('.tariff-card').forEach(c => c.classList.remove('selected'));
    card.classList.add('selected');
    currentTariff = card.dataset.tariff;
    tg.hapticSelection();
    updateTotal();
  });

  // --- Добавить рыбу ---
  document.getElementById('btn-add-catch')?.addEventListener('click', () => {
    addCatchRow();
    tg.hapticImpact('light');
  });

  // --- Оплата ---
  document.getElementById('payment-method')?.addEventListener('click', (e) => {
    const btn = e.target.closest('.segmented-item');
    if (!btn) return;
    document.getElementById('payment-method').querySelectorAll('.segmented-item').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    paymentMethod = btn.dataset.method;
    tg.hapticSelection();
  });

  // --- Тип чека ---
  document.getElementById('receipt-type')?.addEventListener('click', (e) => {
    const btn = e.target.closest('.segmented-item');
    if (!btn) return;
    document.getElementById('receipt-type').querySelectorAll('.segmented-item').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    isFiscal = btn.dataset.fiscal === 'true';
    tg.hapticSelection();
  });

  // --- Печать ---
  document.getElementById('btn-print')?.addEventListener('click', async () => {
    const receipt = buildReceiptData();
    if (!receipt) return;

    tg.hapticImpact('heavy');
    
    // Показываем прогресс
    const btn = document.getElementById('btn-print');
    const originalText = btn.textContent;
    btn.textContent = '⏳ Печать...';
    btn.disabled = true;

    try {
      const result = await printer.print(receipt);
      if (result) {
        tg.hapticNotification('success');
      } else {
        tg.showAlert('Не удалось напечатать чек. Проверьте подключение принтера.');
      }
    } catch (e) {
      tg.showAlert('Ошибка печати: ' + e.message);
    } finally {
      btn.textContent = originalText;
      btn.disabled = false;
    }
  });

  // --- Отправить в чат ---
  document.getElementById('btn-send-chat')?.addEventListener('click', () => {
    const receipt = buildReceiptData();
    if (!receipt) return;

    const text = formatReceiptText(receipt);
    tg.sendData({ type: 'receipt', data: receipt });
    tg.hapticNotification('success');
  });
}

// --- Выбор клиента ---

function selectClient(client) {
  currentClient = client;
  const section = document.getElementById('client-section');
  if (section) {
    section.classList.remove('hidden');
    document.getElementById('client-avatar').textContent = store.getClientInitials(client);
    document.getElementById('client-name').textContent = client.name;
    document.getElementById('client-phone').textContent = client.phone;
    document.getElementById('client-level').textContent = store.getLevelBadge(client.level);
  }
  // Авто-выбор тарифа клиента
  const tariffCard = document.querySelector(`.tariff-card[data-tariff="${client.tariff}"]`);
  if (tariffCard) {
    document.querySelectorAll('.tariff-card').forEach(c => c.classList.remove('selected'));
    tariffCard.classList.add('selected');
    currentTariff = client.tariff;
    updateTotal();
  }
}

// --- Строка улова ---

let catchCounter = 0;

function addCatchRow() {
  catchCounter++;
  const list = document.getElementById('catch-list');
  if (!list) return;

  const row = document.createElement('div');
  row.className = 'card';
  row.style.marginBottom = 'var(--spacing-sm)';
  row.dataset.catchId = catchCounter;
  row.innerHTML = `
    <div style="display: flex; gap: var(--spacing-sm); align-items: center; flex-wrap: wrap;">
      <select class="input catch-breed" style="flex: 1; min-width: 100px; height: 40px;">
        ${FISH_BREEDS.map(f => `<option value="${f.id}">${f.emoji} ${f.label} (${f.pricePerKg}₽/кг)</option>`).join('')}
      </select>
      <input class="input catch-kg" type="number" min="0" max="50" placeholder="кг" style="width: 60px; height: 40px;">
      <input class="input catch-grams" type="number" min="0" max="999" placeholder="г" style="width: 60px; height: 40px;">
      <button class="btn btn-ghost catch-remove" style="padding: 8px; font-size: 18px;">✕</button>
    </div>
    <div class="catch-sum" style="text-align: right; margin-top: var(--spacing-xs); font-weight: bold; color: var(--color-accent);">0₽</div>
  `;

  list.appendChild(row);

  // Обработчики
  const updateCatchSum = () => {
    const breedId = row.querySelector('.catch-breed').value;
    const breed = FISH_BREEDS.find(f => f.id === breedId);
    const kg = parseInt(row.querySelector('.catch-kg').value) || 0;
    const grams = parseInt(row.querySelector('.catch-grams').value) || 0;
    const totalKg = kg + grams / 1000;
    const sum = Math.round(totalKg * (breed?.pricePerKg || 0));
    row.querySelector('.catch-sum').textContent = `${sum}₽`;
    updateTotal();
  };

  row.querySelector('.catch-breed').addEventListener('change', updateCatchSum);
  row.querySelector('.catch-kg').addEventListener('input', updateCatchSum);
  row.querySelector('.catch-grams').addEventListener('input', updateCatchSum);

  row.querySelector('.catch-remove')?.addEventListener('click', () => {
    row.remove();
    tg.hapticImpact('light');
    updateTotal();
  });
}

// --- Обновление итого ---

function updateTotal() {
  const tariff = TARIFFS.find(t => t.id === currentTariff);
  let total = tariff?.price || 0;

  // Суммируем улов
  document.querySelectorAll('#catch-list .card').forEach(row => {
    const sumText = row.querySelector('.catch-sum')?.textContent || '0₽';
    total += parseInt(sumText.replace(/\D/g, '')) || 0;
  });

  const el = document.getElementById('total-amount');
  if (el) el.textContent = `${total.toLocaleString('ru-RU')}₽`;
}

// --- Сборка данных чека ---

function buildReceiptData() {
  const tariff = TARIFFS.find(t => t.id === currentTariff);
  
  const catches = [];
  document.querySelectorAll('#catch-list .card').forEach(row => {
    const breedId = row.querySelector('.catch-breed')?.value;
    const breed = FISH_BREEDS.find(f => f.id === breedId);
    const kg = parseInt(row.querySelector('.catch-kg')?.value) || 0;
    const grams = parseInt(row.querySelector('.catch-grams')?.value) || 0;
    const sumText = row.querySelector('.catch-sum')?.textContent || '0₽';
    const sum = parseInt(sumText.replace(/\D/g, '')) || 0;

    if (breed && (kg > 0 || grams > 0)) {
      catches.push({
        breed: breedId,
        breedLabel: breed.label,
        kg, grams,
        pricePerKg: breed.pricePerKg,
        sum
      });
    }
  });

  let total = tariff?.price || 0;
  catches.forEach(c => total += c.sum);

  return {
    id: String(Date.now()).slice(-6),
    clientId: currentClient?.id || null,
    clientName: currentClient?.name || 'Гость',
    date: new Date().toLocaleString('ru-RU'),
    tariff: currentTariff,
    tariffLabel: tariff?.label || 'Стандарт',
    tariffPrice: tariff?.price || 0,
    catches,
    total,
    paymentMethod,
    fiscal: isFiscal
  };
}

// --- Текстовое представление чека ---

function formatReceiptText(receipt) {
  const lines = [
    '🐟 CRAZY TROUT ARENA',
    '─'.repeat(28),
    `Чек №${receipt.id}`,
    `Дата: ${receipt.date}`,
    `Клиент: ${receipt.clientName}`,
    `Тариф: ${receipt.tariffLabel} — ${receipt.tariffPrice}₽`,
    '─'.repeat(28),
  ];

  if (receipt.catches.length) {
    lines.push('УЛОВ:');
    for (const c of receipt.catches) {
      const weight = c.kg > 0 ? `${c.kg}кг${c.grams > 0 ? c.grams + 'г' : ''}` : `${c.grams}г`;
      lines.push(`  ${c.breedLabel} ${weight} × ${c.pricePerKg}₽ = ${c.sum}₽`);
    }
    lines.push('─'.repeat(28));
  }

  lines.push(`💰 ИТОГО: ${receipt.total}₽`);
  
  const paymentLabels = { cash: 'Наличные', card: 'Карта', account: 'Счёт' };
  lines.push(`Оплата: ${paymentLabels[receipt.paymentMethod]}`);

  if (receipt.fiscal) {
    lines.push('─'.repeat(28));
    lines.push('ФН: 8710000100412345');
    lines.push(`ФД: ${receipt.id}`);
    lines.push('Сайт ФНС: nalog.gov.ru');
  }

  return lines.join('\n');
}
