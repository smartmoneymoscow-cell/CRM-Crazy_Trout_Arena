// === Screen: История чеков (точь-в-точь Flutter checks_screen.dart) ===
import { store } from '../core/store.js';
import { tg } from '../core/telegram.js';
import { createFilterDropdown } from '../widgets/filter-dropdown.js';
import { showCalendarPicker } from '../widgets/calendar.js';

export function renderChecks() {
  const stats = store.getStats();
  const el = document.createElement('div');
  el.className = 'screen screen-checks';
  el.innerHTML = `
    <div class="screen-title">Чеки</div>

    <!-- Поиск -->
    <div class="search-bar" style="margin-bottom:10px;">
      <span class="search-icon">🔍</span>
      <input type="text" id="checks-search" placeholder="Имя, сумма, телефон, дата" autocomplete="off">
    </div>
    <div id="checks-client-suggestions" class="client-suggestions hidden"></div>

    <!-- Фильтры -->
    <div class="filter-bar">
      <div id="checks-period-dropdown"></div>
      <div class="calendar-chip" id="checks-calendar" title="Календарь">📅</div>
      <div class="icon-filter-chip" id="checks-filter-btn" title="Фильтры">⚙️</div>
      <div class="sort-chip" id="checks-sort">
        <div class="sort-trigger" id="sort-trigger" title="Сортировка">↕️</div>
      </div>
    </div>

    <!-- Сводка -->
    <div class="card" style="margin-bottom:var(--sp-lg);">
      <div style="display:flex;justify-content:space-between;">
        <div>
          <div style="font-size:13px;color:var(--kMuted);">Всего чеков</div>
          <div style="font-size:20px;font-weight:700;">${stats.totalReceipts}</div>
        </div>
        <div style="text-align:right;">
          <div style="font-size:13px;color:var(--kMuted);">Выручка</div>
          <div style="font-size:20px;font-weight:700;color:var(--kGreen);">+${store.formatMoney(stats.totalRevenue)} ₽</div>
        </div>
      </div>
    </div>

    <!-- Список чеков -->
    <div id="checks-list"></div>
  `;

  setTimeout(() => {
    renderChecksList();
    initChecksHandlers();
  }, 0);
  return el;
}

function renderChecksList(filter = '') {
  const list = document.getElementById('checks-list');
  if (!list) return;

  let receipts = [...store.receipts];
  if (filter) {
    const q = filter.toLowerCase();
    receipts = receipts.filter(r => {
      const client = store.getClientById(r.clientId);
      if (client && (client.name.toLowerCase().includes(q) || client.phone.includes(q))) return true;
      if (r.total.toString().includes(q)) return true;
      if (r.date.includes(q)) return true;
      return false;
    });
  }

  list.innerHTML = receipts.map(r => {
    const client = store.getClientById(r.clientId);
    return `
      <div class="card check-card" data-receipt-id="${r.id}">
        <div class="check-amount">${store.formatMoney(r.total)} ₽</div>
        <div class="check-info">
          <div class="check-client">${r.isGuest ? 'Гость' : (client?.name || 'Неизвестен')}</div>
          <div class="check-meta">${r.date} · ${r.tariffLabel}</div>
        </div>
        <div class="check-arrow">›</div>
      </div>
    `;
  }).join('');

  // Клик по чеку → детали
  list.querySelectorAll('.check-card').forEach(card => {
    card.addEventListener('click', () => {
      const receipt = store.receipts.find(r => r.id === card.dataset.receiptId);
      if (receipt) showCheckDetail(receipt);
    });
  });
}

function initChecksHandlers() {
  // Поиск
  const searchInput = document.getElementById('checks-search');
  searchInput?.addEventListener('input', (e) => {
    const q = e.target.value.trim();
    renderChecksList(q);
  });

  // Period dropdown (FilterDropdown-компонент)
  const periodContainer = document.getElementById('checks-period-dropdown');
  if (periodContainer) {
    periodContainer.innerHTML = '';
    createFilterDropdown(periodContainer, {
      value: null,
      label: 'Период',
      items: [
        { value: null, label: 'Нет', isReset: true, enabled: false },
        { value: 'today', label: 'Сегодня' },
        { value: 'week', label: 'Неделя' },
        { value: 'month', label: 'Месяц' },
        { value: 'quarter', label: 'Квартал' },
        { value: 'all', label: 'Все время' },
      ],
      onChanged: (v) => { renderChecksList(searchInput?.value?.trim() || ''); },
    });
  }

  // Calendar
  document.getElementById('checks-calendar')?.addEventListener('click', async () => {
    const result = await showCalendarPicker(null);
    if (result) renderChecksList(searchInput?.value?.trim() || '');
  });

  // Filter dialog
  document.getElementById('checks-filter-btn')?.addEventListener('click', showFilterDialog);

  // Sort chip (как Flutter _SortChip)
  const sortTrigger = document.getElementById('sort-trigger');
  const sortContainer = document.getElementById('checks-sort');
  let sortOpen = false;
  let sortMenu = null;
  let sortField = 'date';
  let sortDesc = true;
  const sortOptions = [
    { value: 'date', label: 'По дате' },
    { value: 'total', label: 'По сумме' },
    { value: 'visits', label: 'По посещениям' },
    { value: 'ltv', label: 'По LTV' },
    { value: 'fish', label: 'По улову' },
  ];

  sortTrigger?.addEventListener('click', (e) => {
    e.stopPropagation();
    if (sortOpen) { closeSort(); return; }
    sortOpen = true;
    sortTrigger.classList.add('active');
    sortMenu = document.createElement('div');
    sortMenu.className = 'sort-menu';
    sortMenu.style.cssText = 'position:absolute;top:calc(100% + 4px);right:0;background:#fff;border:1px solid #EFE8D8;border-radius:10px;box-shadow:0 6px 16px rgba(0,0,0,0.12);z-index:50;padding:4px 0;min-width:170px;';
    sortMenu.innerHTML = sortOptions.map(opt => `
      <div style="padding:10px 12px;font-size:13px;cursor:pointer;display:flex;align-items:center;gap:8px;background:${opt.value === sortField ? '#EFD9AC' : 'transparent'};font-weight:${opt.value === sortField ? '700' : '400'};" data-sort="${opt.value}">
        ${opt.label}
        ${opt.value === sortField ? `<span style="margin-left:auto;font-size:11px;color:#9C9484;">${sortDesc ? '↓' : '↑'}</span>` : ''}
      </div>
    `).join('') + `
      <div style="border-top:0.5px solid #E7E0D1;margin:4px 0;"></div>
      <div style="padding:10px 12px;font-size:13px;cursor:pointer;color:#9C9484;" data-sort-toggle>
        ${sortDesc ? 'По убыванию' : 'По возрастанию'} ↕
      </div>
    `;
    sortContainer.appendChild(sortMenu);
    sortMenu.querySelectorAll('[data-sort]').forEach(item => {
      item.addEventListener('click', (ev) => {
        ev.stopPropagation();
        sortField = item.dataset.sort;
        closeSort();
        renderChecksList(searchInput?.value?.trim() || '');
      });
    });
    sortMenu.querySelector('[data-sort-toggle]')?.addEventListener('click', (ev) => {
      ev.stopPropagation();
      sortDesc = !sortDesc;
      closeSort();
      renderChecksList(searchInput?.value?.trim() || '');
    });
    setTimeout(() => document.addEventListener('click', closeSort), 0);
  });

  function closeSort() {
    sortOpen = false;
    sortTrigger?.classList.remove('active');
    if (sortMenu) { sortMenu.remove(); sortMenu = null; }
    document.removeEventListener('click', closeSort);
  }
}

function showFilterDialog() {
  const overlay = document.createElement('div');
  overlay.className = 'modal-overlay';
  overlay.innerHTML = `
    <div class="sheet filter-dialog">
      <div style="text-align:center;font-size:18px;font-weight:700;color:var(--kInk);margin-bottom:20px;">Фильтры</div>
      <div class="filter-section">
        <div class="filter-section-title">Тип чека</div>
        <div class="chip-group">
          <div class="chip" data-filter-type="fiscal">С ФН</div>
          <div class="chip" data-filter-type="nonfiscal">Без ФН</div>
        </div>
      </div>
      <div class="filter-section">
        <div class="filter-section-title">Тариф</div>
        <div class="chip-group">
          <div class="chip" data-filter-tariff="Стандарт">Стандарт</div>
          <div class="chip" data-filter-tariff="Гостевой">Гостевой</div>
          <div class="chip" data-filter-tariff="Пенсионер">Пенсионер</div>
        </div>
      </div>
      <div class="filter-section">
        <div class="filter-section-title">Способ оплаты</div>
        <div class="chip-group">
          <div class="chip" data-filter-payment="Наличными">Наличными</div>
          <div class="chip" data-filter-payment="Картой">Картой</div>
          <div class="chip" data-filter-payment="Счет заведения">Счет заведения</div>
        </div>
      </div>
      <div class="filter-actions">
        <button class="btn-reset" id="filter-reset">Сбросить</button>
        <button class="btn-apply" id="filter-apply">Применить</button>
      </div>
    </div>
  `;

  document.body.appendChild(overlay);

  // Chip toggle
  overlay.querySelectorAll('.chip').forEach(chip => {
    chip.addEventListener('click', () => {
      chip.classList.toggle('selected');
      tg.hapticSelection();
    });
  });

  overlay.querySelector('#filter-reset')?.addEventListener('click', () => {
    overlay.querySelectorAll('.chip').forEach(c => c.classList.remove('selected'));
  });

  overlay.querySelector('#filter-apply')?.addEventListener('click', () => {
    overlay.remove();
    tg.hapticNotification('success');
  });

  overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove(); });
}

function showCheckDetail(receipt) {
  const client = store.getClientById(receipt.clientId);
  const overlay = document.createElement('div');
  overlay.className = 'modal-overlay';
  overlay.innerHTML = `
    <div class="sheet">
      <div style="text-align:center;font-size:24px;margin-bottom:12px;">🧾</div>
      <div style="text-align:center;font-size:18px;font-weight:700;margin-bottom:4px;">Чек №${receipt.id}</div>
      <div style="text-align:center;font-size:13px;color:var(--kMuted2);margin-bottom:16px;">${receipt.date}</div>

      <div style="display:flex;align-items:center;gap:12px;margin-bottom:16px;padding:12px;background:var(--kFill);border-radius:12px;">
        ${store.renderAvatar(client, 44)}
        <div style="flex:1;">
          <div style="font-weight:700;">${receipt.isGuest ? 'Гость' : (client?.name || 'Неизвестен')}</div>
          <div style="font-size:12px;color:var(--kMuted2);">${client?.phone || ''} · ${receipt.tariffLabel}</div>
        </div>
      </div>

      <div style="font-size:14px;">
        <div style="display:flex;justify-content:space-between;margin-bottom:6px;">
          <span style="color:var(--kMuted);">Тариф</span>
          <span>${receipt.tariffLabel} — ${receipt.tariffPrice} ₽</span>
        </div>
        <div style="display:flex;justify-content:space-between;margin-bottom:6px;">
          <span style="color:var(--kMuted);">Оплата</span>
          <span>${receipt.paymentLabel}</span>
        </div>
      </div>

      ${receipt.catches.length ? `
        <div style="font-weight:700;margin:12px 0 8px;">УЛОВ</div>
        ${receipt.catches.map(c => {
          const weight = c.kg > 0 ? `${c.kg}кг${c.grams > 0 ? c.grams + 'г' : ''}` : `${c.grams}г`;
          return `<div style="display:flex;justify-content:space-between;font-size:13px;margin-bottom:4px;">
            <span>${c.label || c.breedLabel} ${weight} × ${c.pricePerKg}₽/кг</span>
            <span style="font-weight:600;">${store.formatMoney(c.sum)} ₽</span>
          </div>`;
        }).join('')}
        <hr style="border:none;border-top:1px solid var(--kHairline2);margin:12px 0;">
      ` : ''}

      <div style="display:flex;justify-content:space-between;font-size:20px;font-weight:700;">
        <span>ИТОГО</span>
        <span style="color:var(--kOrange);">${store.formatMoney(receipt.total)} ₽</span>
      </div>

      <button class="btn btn-ghost btn-full" style="margin-top:20px;color:var(--kMuted2);">Закрыть</button>
    </div>
  `;

  document.body.appendChild(overlay);
  overlay.querySelector('.btn-ghost')?.addEventListener('click', () => overlay.remove());
  overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove(); });
}
