// === Screen: Выставление чека (точь-в-точь Flutter receipt_screen.dart) ===
import { store, TARIFFS, FISH_BREEDS } from '../core/store.js';
import { tg } from '../core/telegram.js';
import { qrScanner } from '../services/qr-scanner.js';
import { printer } from '../services/printer.js';
import { createDropdown } from '../widgets/dropdown.js';

let currentClient = null;
let isGuest = false;
let currentTariff = TARIFFS[0];
let currentCatches = [];
let paymentMethod = 'card';
let isFiscal = true;
let catchSeq = 1;

export function renderReceipt() {
  const el = document.createElement('div');
  el.className = 'screen screen-receipt';
  el.innerHTML = `
    <div class="screen-title">Выставление чека</div>

    <!-- Клиент -->
    <div class="card receipt-section">
      <div class="card-header"><div class="card-title">Клиент</div></div>
      <div class="client-search-bar">
        <span class="search-icon">🔍</span>
        <input type="text" id="client-search" placeholder="Поиск по имени или телефону…" autocomplete="off">
        <button class="qr-btn" id="btn-scan-qr" title="Сканировать QR клиента">📷</button>
      </div>
      <div id="search-results" class="search-results"></div>
      <div id="client-section"></div>
    </div>

    <!-- Тип клиента (Тариф + Цена) -->
    <div class="card receipt-section">
      <div class="card-header"><div class="card-title">Тип клиента</div></div>
      <div style="display:flex;gap:12px;">
        <div style="flex:1;">
          <div class="field-label">ТАРИФ</div>
          <div id="tariff-dropdown"></div>
        </div>
        <div style="flex:1;">
          <div class="field-label">ЦЕНА, ₽</div>
          <div class="readonly-field" id="price-field">${currentTariff.price}</div>
        </div>
      </div>
    </div>

    <!-- Улов -->
    <div class="card receipt-section">
      <div class="card-header">
        <div class="card-title">Улов</div>
        <span style="color:#999;font-size:13px;" id="catch-count">0 поз.</span>
      </div>
      <div id="catch-list"></div>
      <button class="btn btn-outline" id="btn-add-catch">+ Добавить рыбу</button>
    </div>

    <!-- Способ оплаты и тип чека -->
    <div class="card receipt-section">
      <div class="card-header"><div class="card-title">Способ оплаты и тип чека</div></div>
      <div style="display:flex;gap:12px;">
        <div style="flex:1;">
          <div class="field-label">СПОСОБ ОПЛАТЫ</div>
          <div id="payment-dropdown"></div>
        </div>
        <div style="flex:1;">
          <div class="field-label">ТИП ЧЕКА</div>
          <div id="fiscal-dropdown"></div>
        </div>
      </div>
    </div>

    <!-- Итого -->
    <div class="total-block receipt-section">
      <div class="total-row">
        <span class="total-label">Тариф клиента</span>
        <span class="total-value" id="sum-tariff">${store.formatMoney(currentTariff.price)} ₽</span>
      </div>
      <div class="total-row">
        <span class="total-label" id="sum-catch-label">Улов · 0 поз.</span>
        <span class="total-value" id="sum-catch">0 ₽</span>
      </div>
      <hr class="total-divider">
      <div class="total-row big">
        <span class="total-label">ИТОГО</span>
        <span class="total-value" id="sum-total">${store.formatMoney(currentTariff.price)} ₽</span>
      </div>
    </div>

    <!-- Кнопка -->
    <button class="btn btn-primary" id="btn-submit">Создать и распечатать чек</button>
  `;

  setTimeout(() => {
    initReceiptHandlers(el);
    // Начальное состояние: кнопка «Гость»
    document.getElementById('client-section').innerHTML = renderGuestButton();
    attachGuestHandler();
  }, 0);
  return el;
}

function initReceiptHandlers(el) {
  const searchInput = document.getElementById('client-search');
  const resultsDiv = document.getElementById('search-results');

  // Поиск клиента
  searchInput?.addEventListener('input', (e) => {
    const q = e.target.value.trim();
    if (!q) { resultsDiv.innerHTML = ''; return; }
    const clients = store.searchClients(q);
    if (!clients.length) { resultsDiv.innerHTML = ''; return; }
    resultsDiv.innerHTML = clients.map(c => `
      <div class="search-result-item" data-id="${c.id}">
        ${store.renderAvatar(c, 40)}
        <div class="result-info">
          <div class="result-name">${c.name}</div>
          <div class="result-meta">${c.phone} · ${c.tariff === 'standard' ? 'Стандарт' : c.tariff === 'pensioner' ? 'Пенсионер' : 'Гостевой'}</div>
        </div>
      </div>
    `).join('');
    resultsDiv.querySelectorAll('.search-result-item').forEach(item => {
      item.addEventListener('click', () => {
        const client = store.getClientById(item.dataset.id);
        if (client) selectClient(client);
        resultsDiv.innerHTML = '';
      });
    });
  });

  // QR-сканер
  document.getElementById('btn-scan-qr')?.addEventListener('click', async () => {
    const result = await qrScanner.scan('auto');
    if (result) {
      const client = store.getClientById(result) || store.findClient(result);
      if (client) { selectClient(client); searchInput.value = client.name; }
      else tg.showAlert(`Клиент не найден: ${result}`);
    }
  });

  // Тариф dropdown (OverlayEntry-паттерн)
  const tariffContainer = document.getElementById('tariff-dropdown');
  tariffContainer.innerHTML = '';
  createDropdown(tariffContainer, TARIFFS.map(t => ({ value: t.id, label: t.label })), currentTariff.id, (v) => {
    currentTariff = TARIFFS.find(t => t.id === v);
    document.getElementById('price-field').textContent = currentTariff.price;
    updateTotal();
  });

  // Оплата dropdown (OverlayEntry-паттерн)
  const paymentContainer = document.getElementById('payment-dropdown');
  paymentContainer.innerHTML = '';
  const payMethods = [
    { value: 'cash', label: 'Наличными' },
    { value: 'card', label: 'Картой' },
    { value: 'account', label: 'Счет заведения' },
  ];
  createDropdown(paymentContainer, payMethods, paymentMethod, (v) => { paymentMethod = v; });

  // Тип чека dropdown (OverlayEntry-паттерн)
  const fiscalContainer = document.getElementById('fiscal-dropdown');
  fiscalContainer.innerHTML = '';
  createDropdown(fiscalContainer, [
    { value: 'true', label: 'Фискальный' },
    { value: 'false', label: 'Нефискальный' },
  ], String(isFiscal), (v) => { isFiscal = v === 'true'; });

  // Добавить рыбу
  document.getElementById('btn-add-catch')?.addEventListener('click', () => {
    addCatchRow();
    tg.hapticImpact('light');
  });

  // Отправить чек
  document.getElementById('btn-submit')?.addEventListener('click', () => {
    if (!isGuest && !currentClient) {
      tg.showAlert('Выберите клиента или отметьте «Гость»');
      return;
    }
    const receipt = buildReceiptData();
    showReceiptResult(receipt);
    tg.hapticImpact('heavy');
  });
}



// ─── Выбор клиента (как Flutter _selectClient) ───
function selectClient(client) {
  currentClient = client;
  isGuest = false;
  document.getElementById('client-search').value = client.name;
  document.getElementById('search-results').innerHTML = '';

  const section = document.getElementById('client-section');
  section.innerHTML = `
    <div class="selected-client-card">
      ${store.renderAvatar(client, 40)}
      <div class="client-info">
        <div class="client-name">${client.name}</div>
        <div class="client-meta">${client.phone} · ${client.tariff === 'standard' ? 'Стандарт' : client.tariff === 'pensioner' ? 'Пенсионер' : 'Гостевой'}</div>
      </div>
      <button class="clear-btn" id="clear-client">✕</button>
    </div>
  `;
  document.getElementById('clear-client')?.addEventListener('click', () => {
    currentClient = null;
    document.getElementById('client-search').value = '';
    section.innerHTML = renderGuestButton();
    attachGuestHandler();
  });

  // Авто-выбор тарифа
  const matched = TARIFFS.find(t => t.label === (client.tariff === 'standard' ? 'Стандарт' : client.tariff === 'pensioner' ? 'Пенсионер' : 'Гостевой'));
  if (matched) {
    currentTariff = matched;
    document.getElementById('price-field').textContent = matched.price;
    // Re-init tariff dropdown
    const tariffContainer = document.getElementById('tariff-dropdown');
    if (tariffContainer) { tariffContainer.innerHTML = ''; createDropdown(tariffContainer, TARIFFS.map(t => ({ value: t.id, label: t.label })), currentTariff.id, (v) => { currentTariff = TARIFFS.find(t => t.id === v); document.getElementById('price-field').textContent = currentTariff.price; updateTotal(); }); }
    updateTotal();
  }
}

function renderGuestButton() {
  return `<button class="btn btn-outline guest-btn" id="btn-guest">Гость · без анкеты</button>`;
}

function attachGuestHandler() {
  document.getElementById('btn-guest')?.addEventListener('click', () => {
    isGuest = true;
    currentClient = null;
    document.getElementById('client-search').value = '';
    document.getElementById('search-results').innerHTML = '';
    currentTariff = TARIFFS.find(t => t.id === 'guest');
    document.getElementById('tariff-label').textContent = currentTariff.label;
    document.getElementById('price-field').textContent = currentTariff.price;
    updateTotal();

    const section = document.getElementById('client-section');
    section.innerHTML = `
      <div class="guest-card">
        <div class="guest-icon"><img src="src/assets/avatars/incognito.png" style="width:100%;height:100%;object-fit:cover;border-radius:50%;"></div>
        <div>
          <div class="guest-label">Гость</div>
          <div class="guest-meta">Без анкеты · Гостевой тариф</div>
        </div>
        <button class="clear-btn" id="clear-guest">✕</button>
      </div>
    `;
    document.getElementById('clear-guest')?.addEventListener('click', () => {
      isGuest = false;
      currentTariff = TARIFFS[0];
      document.getElementById('tariff-label').textContent = currentTariff.label;
      document.getElementById('price-field').textContent = currentTariff.price;
      updateTotal();
      section.innerHTML = renderGuestButton();
      attachGuestHandler();
    });
  });
}

// ─── Строка улова (как Flutter CatchRowTile) ───
function addCatchRow() {
  const rowId = catchSeq++;
  const breed = FISH_BREEDS[0];
  const list = document.getElementById('catch-list');
  if (!list) return;

  const row = document.createElement('div');
  row.className = 'catch-row';
  row.dataset.catchId = rowId;
  row.innerHTML = `
    <div class="catch-breed-row">
      <div class="field-wrap">
        <div class="field-label">ПОРОДА</div>
        <div id="breed-dd-${rowId}"></div>
      </div>
      <button class="btn btn-ghost catch-remove" style="color:var(--kRed);font-size:18px;padding:4px;">✕</button>
    </div>
    <div class="catch-fields-row">
      <div class="field-wrap">
        <div class="field-label">КГ</div>
        <input class="input catch-kg" type="number" min="0" max="50" placeholder="" style="text-align:center;">
      </div>
      <div class="field-wrap">
        <div class="field-label">ГРАММ</div>
        <input class="input catch-grams" type="number" min="0" max="999" placeholder="" style="text-align:center;">
      </div>
      <div class="field-wrap sum-field">
        <div class="field-label">СУММА</div>
        <div class="catch-sum">0 ₽</div>
      </div>
    </div>
  `;

  list.appendChild(row);
  document.getElementById('catch-count').textContent = `${list.children.length} поз.`;

  // Breed dropdown (OverlayEntry-паттерн с PNG рыб)
  let selectedBreed = breed;
  const breedContainer = row.querySelector(`#breed-dd-${rowId}`);
  const breedItems = FISH_BREEDS.map(f => ({
    value: f.id,
    label: `${f.label} (${f.pricePerKg}₽/кг)`,
    render: () => {
      const el = document.createElement('div');
      el.style.cssText = 'display:flex;align-items:center;gap:8px;width:100%;';
      el.innerHTML = `<span style="flex:1;">${f.label} (${f.pricePerKg}₽/кг)</span><img src="${f.image}" alt="${f.label}" style="height:${f.imageHeight}px;border-radius:6px;">`;
      return el;
    },
  }));
  createDropdown(breedContainer, breedItems, selectedBreed.id, (v) => {
    selectedBreed = FISH_BREEDS.find(f => f.id === v);
    row.dataset.breedId = v;
    updateCatchSum();
  });
  row.dataset.breedId = selectedBreed.id;

  // Кг/Грамм → сумма
  const updateCatchSum = () => {
    const kg = parseFloat(row.querySelector('.catch-kg').value) || 0;
    const grams = parseInt(row.querySelector('.catch-grams').value) || 0;
    const totalKg = kg + grams / 1000;
    const sum = Math.round(totalKg * selectedBreed.pricePerKg);
    row.querySelector('.catch-sum').textContent = `${store.formatMoney(sum)} ₽`;
    updateTotal();
  };

  row.querySelector('.catch-kg').addEventListener('input', updateCatchSum);
  row.querySelector('.catch-grams').addEventListener('input', updateCatchSum);

  // Удалить строку
  row.querySelector('.catch-remove')?.addEventListener('click', () => {
    row.remove();
    document.getElementById('catch-count').textContent = `${list.children.length} поз.`;
    tg.hapticImpact('light');
    updateTotal();
  });
}

// ─── Обновление итого (как Flutter _total) ───
function updateTotal() {
  let catchTotal = 0;
  document.querySelectorAll('#catch-list .catch-row').forEach(row => {
    const sumText = row.querySelector('.catch-sum')?.textContent || '0 ₽';
    catchTotal += parseInt(sumText.replace(/[^0-9]/g, '')) || 0;
  });
  const total = currentTariff.price + catchTotal;

  document.getElementById('sum-tariff').textContent = `${store.formatMoney(currentTariff.price)} ₽`;
  document.getElementById('sum-catch-label').textContent = `Улов · ${document.querySelectorAll('#catch-list .catch-row').length} поз.`;
  document.getElementById('sum-catch').textContent = `${store.formatMoney(catchTotal)} ₽`;
  document.getElementById('sum-total').textContent = `${store.formatMoney(total)} ₽`;
}

// ─── Сборка данных чека ───
function buildReceiptData() {
  const catches = [];
  document.querySelectorAll('#catch-list .catch-row').forEach(row => {
    const breedId = row.dataset.breedId;
    const breed = FISH_BREEDS.find(f => f.id === breedId);
    const kg = parseFloat(row.querySelector('.catch-kg')?.value) || 0;
    const grams = parseInt(row.querySelector('.catch-grams')?.value) || 0;
    const sumText = row.querySelector('.catch-sum')?.textContent || '0 ₽';
    const sum = parseInt(sumText.replace(/[^0-9]/g, '')) || 0;
    if (breed && (kg > 0 || grams > 0)) {
      catches.push({ breed: breed.id, breedLabel: breed.label, kg, grams, pricePerKg: breed.pricePerKg, sum });
    }
  });

  let total = currentTariff.price;
  catches.forEach(c => total += c.sum);

  return {
    id: String(Date.now()).slice(-6),
    clientId: currentClient?.id || null,
    clientName: isGuest ? 'Гость' : (currentClient?.name || 'Неизвестен'),
    date: new Date().toLocaleString('ru-RU'),
    tariff: currentTariff.id,
    tariffLabel: currentTariff.label,
    tariffPrice: currentTariff.price,
    catches,
    total,
    paymentMethod,
    paymentLabel: paymentMethod === 'cash' ? 'Наличными' : paymentMethod === 'card' ? 'Картой' : 'Счет заведения',
    fiscal: isFiscal,
  };
}

// ─── Показать результат чека (как Flutter showReceiptResultSheet) ───
function showReceiptResult(receipt) {
  const overlay = document.createElement('div');
  overlay.className = 'modal-overlay';
  overlay.innerHTML = `
    <div class="sheet">
      <div style="text-align:center;font-size:24px;margin-bottom:16px;">🧾</div>
      <div style="text-align:center;font-size:18px;font-weight:700;margin-bottom:8px;">Чек №${receipt.id}</div>
      <div style="text-align:center;font-size:13px;color:var(--kMuted2);margin-bottom:20px;">${receipt.date}</div>
      <div style="font-size:14px;margin-bottom:12px;">
        <div style="display:flex;justify-content:space-between;margin-bottom:4px;">
          <span style="color:var(--kMuted);">Клиент</span>
          <span style="font-weight:600;">${receipt.clientName}</span>
        </div>
        <div style="display:flex;justify-content:space-between;margin-bottom:4px;">
          <span style="color:var(--kMuted);">Тариф</span>
          <span>${receipt.tariffLabel} — ${receipt.tariffPrice} ₽</span>
        </div>
        <div style="display:flex;justify-content:space-between;margin-bottom:4px;">
          <span style="color:var(--kMuted);">Оплата</span>
          <span>${receipt.paymentLabel}</span>
        </div>
      </div>
      ${receipt.catches.length ? `
        <div style="font-weight:700;margin-bottom:8px;">УЛОВ</div>
        ${receipt.catches.map(c => {
          const weight = c.kg > 0 ? `${c.kg}кг${c.grams > 0 ? c.grams + 'г' : ''}` : `${c.grams}г`;
          return `<div style="display:flex;justify-content:space-between;font-size:13px;margin-bottom:4px;">
            <span>${c.breedLabel} ${weight} × ${c.pricePerKg}₽/кг</span>
            <span style="font-weight:600;">${store.formatMoney(c.sum)} ₽</span>
          </div>`;
        }).join('')}
        <hr style="border:none;border-top:1px solid var(--kHairline2);margin:12px 0;">
      ` : ''}
      <div style="display:flex;justify-content:space-between;font-size:20px;font-weight:700;">
        <span>ИТОГО</span>
        <span style="color:var(--kOrange);">${store.formatMoney(receipt.total)} ₽</span>
      </div>
      ${receipt.fiscal ? `
        <div style="margin-top:12px;font-size:11px;color:var(--kMuted2);text-align:center;">
          ФН: 8710000100412345 · ФД: ${receipt.id}<br>Сайт ФНС: nalog.gov.ru
        </div>
      ` : ''}
      <div style="display:flex;gap:12px;margin-top:20px;">
        <button class="btn btn-outline" id="receipt-print" style="flex:1;">🖨️ Печать</button>
        <button class="btn btn-primary" id="receipt-send" style="flex:1;">💬 В чат</button>
      </div>
      <button class="btn btn-ghost btn-full" id="receipt-close" style="margin-top:8px;color:var(--kMuted2);">Закрыть</button>
    </div>
  `;

  document.body.appendChild(overlay);

  overlay.querySelector('#receipt-close')?.addEventListener('click', () => {
    overlay.remove();
    resetForm();
  });
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) { overlay.remove(); resetForm(); }
  });
  overlay.querySelector('#receipt-print')?.addEventListener('click', async () => {
    const result = await printer.print(receipt);
    if (result) tg.hapticNotification('success');
    else tg.showAlert('Не удалось напечатать чек.');
  });
  overlay.querySelector('#receipt-send')?.addEventListener('click', () => {
    tg.sendData({ type: 'receipt', data: receipt });
    tg.hapticNotification('success');
    overlay.remove();
    resetForm();
  });
}

function resetForm() {
  currentClient = null;
  isGuest = false;
  currentTariff = TARIFFS[0];
  currentCatches = [];
  paymentMethod = 'card';
  isFiscal = true;
  document.getElementById('client-search').value = '';
  document.getElementById('search-results').innerHTML = '';
  document.getElementById('client-section').innerHTML = renderGuestButton();
  attachGuestHandler();
  document.getElementById('catch-list').innerHTML = '';
  document.getElementById('catch-count').textContent = '0 поз.';
  document.getElementById('price-field').textContent = currentTariff.price;
  // Re-init dropdowns
  const tariffContainer = document.getElementById('tariff-dropdown');
  if (tariffContainer) { tariffContainer.innerHTML = ''; createDropdown(tariffContainer, TARIFFS.map(t => ({ value: t.id, label: t.label })), currentTariff.id, (v) => { currentTariff = TARIFFS.find(t => t.id === v); document.getElementById('price-field').textContent = currentTariff.price; updateTotal(); }); }
  const paymentContainer = document.getElementById('payment-dropdown');
  if (paymentContainer) { paymentContainer.innerHTML = ''; createDropdown(paymentContainer, [{ value: 'cash', label: 'Наличными' }, { value: 'card', label: 'Картой' }, { value: 'account', label: 'Счет заведения' }], paymentMethod, (v) => { paymentMethod = v; }); }
  const fiscalContainer = document.getElementById('fiscal-dropdown');
  if (fiscalContainer) { fiscalContainer.innerHTML = ''; createDropdown(fiscalContainer, [{ value: 'true', label: 'Фискальный' }, { value: 'false', label: 'Нефискальный' }], String(isFiscal), (v) => { isFiscal = v === 'true'; }); }
  updateTotal();
}
