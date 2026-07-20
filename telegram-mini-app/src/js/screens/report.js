// === Screen: Отчёт (точь-в-точь Flutter report_screen.dart) ===
import { store } from '../core/store.js';
import { tg } from '../core/telegram.js';
import { drawDoughnut, drawLineChart } from '../widgets/charts.js';
import { renderFinanceDashboardCard } from '../widgets/finance-dashboard.js';
import { createFilterDropdown } from '../widgets/filter-dropdown.js';
import { showCalendarPicker } from '../widgets/calendar.js';
import { showClientCard } from '../widgets/client-card.js';

// Состояние фильтров
let currentPeriod = null;
let currentDateRange = null;
let lastFilterSource = null;

let selectedIcon = 0;

// ── Счётчик добавленной рыбы (по породам) ──
let addedFish = {};

export function renderReport() {
  const stats = store.getStats();
  const el = document.createElement('div');
  el.className = 'screen screen-report';
  el.innerHTML = `
    <div class="screen-title" id="report-title">Финансы и метрики</div>
    <div class="filter-bar">
      <div id="period-dropdown"></div>
      <div class="calendar-chip" id="calendar-chip" title="Календарь"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="4" rx="2" ry="2"/><line x1="16" x2="16" y1="2" y2="6"/><line x1="8" x2="8" y1="2" y2="6"/><line x1="3" x2="21" y1="10" y2="10"/></svg></div>
      <div class="icon-filter-chip ${selectedIcon === 0 ? 'active' : ''}" data-icon="0" title="Финансы"><img src="src/assets/icons/ruble.png" style="width:20px;height:20px;"></div>
      <div class="icon-filter-chip ${selectedIcon === 1 ? 'active' : ''}" data-icon="1" title="Клиенты"><img src="src/assets/icons/clients.png" style="width:20px;height:20px;"></div>
      <div class="icon-filter-chip ${selectedIcon === 2 ? 'active' : ''}" data-icon="2" title="Рыба"><img src="src/assets/icons/fish.png" style="width:20px;height:20px;"></div>
    </div>
    <div id="report-content"></div>
  `;

  setTimeout(() => {
    renderFinanceContent();
    initReportHandlers();
  }, 0);
  return el;
}

function initReportHandlers() {
  document.querySelectorAll('.icon-filter-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      const icon = parseInt(chip.dataset.icon);
      selectedIcon = selectedIcon === icon ? -1 : icon;
      document.querySelectorAll('.icon-filter-chip').forEach(c => c.classList.remove('active'));
      if (selectedIcon >= 0) chip.classList.add('active');
      const titles = ['Финансы и метрики', 'Статистика клиентов', 'Статистика улова рыбы'];
      document.getElementById('report-title').textContent = titles[selectedIcon] || 'Финансы и метрики';
      renderContent();
      tg.hapticSelection();
    });
  });

  const periodContainer = document.getElementById('period-dropdown');
  if (periodContainer) {
    periodContainer.innerHTML = '';
    createFilterDropdown(periodContainer, {
      value: null,
      label: 'Период',
      items: [
        { value: null, label: 'Нет', isReset: true, enabled: currentPeriod != null },
        { value: 'today', label: 'Сегодня' },
        { value: 'week', label: 'Неделя' },
        { value: 'month', label: 'Месяц' },
        { value: 'quarter', label: 'Квартал' },
        { value: 'all', label: 'Все время' },
      ],
      onChanged: (v) => {
        currentPeriod = v;
        if (v != null) {
          currentDateRange = null;
          lastFilterSource = 'dropdown';
        } else {
          lastFilterSource = currentDateRange ? 'calendar' : null;
        }
        renderContent();
      },
    });
  }

  document.getElementById('calendar-chip')?.addEventListener('click', async () => {
    const result = await showCalendarPicker(currentDateRange);
    if (result && result.start && result.end) {
      if (result.start.getFullYear() === 2000) {
        currentDateRange = null;
        lastFilterSource = currentPeriod ? 'dropdown' : null;
      } else {
        currentDateRange = result;
        currentPeriod = null;
        lastFilterSource = 'calendar';
      }
    }
    renderContent();
  });
}

// ─── Фильтрация по периоду и дате ───
function isInPeriod(date, period) {
  if (!period) return true;
  const now = new Date();
  const d = new Date(date);
  let start;
  switch (period) {
    case 'today': start = new Date(now.getFullYear(), now.getMonth(), now.getDate()); break;
    case 'week': start = new Date(now - 7 * 86400000); break;
    case 'month': start = new Date(now - 30 * 86400000); break;
    case 'quarter': start = new Date(now - 90 * 86400000); break;
    default: return true;
  }
  return d >= start;
}

function isInDateRange(date, range) {
  if (!range || !range.start || !range.end) return true;
  const d = new Date(date); d.setHours(0,0,0,0);
  const s = new Date(range.start); s.setHours(0,0,0,0);
  const e = new Date(range.end); e.setHours(23,59,59,999);
  return d >= s && d <= e;
}

function getEffectivePeriod() {
  if (lastFilterSource === 'calendar') return null;
  return currentPeriod;
}

function getEffectiveDateRange() {
  if (lastFilterSource === 'dropdown') return null;
  return currentDateRange;
}

function renderContent() {
  if (selectedIcon === 1) renderClientStats();
  else if (selectedIcon === 2) renderFishStats();
  else renderFinanceContent();
}

// ─── KPI карточки (5 штук как в Flutter) ───
function renderKpiCards(container, stats, filteredAvgCheck) {
  const kpiData = [
    { value: `${store.formatMoney(filteredAvgCheck)} ₽`, label: 'Средний чек', delta: '↑ 5%' },
    { value: `LT ${stats.avgVisits || 3} / LTV ${store.formatMoney(stats.avgLTV || 120)} тыс`, label: 'LT / LTV', delta: '↑ 8%' },
    { value: `${stats.uniqueClients}`, label: 'Всего клиентов', delta: '↑ 3' },
    { value: `${stats.avgFish || 2.4} шт`, label: 'Средний улов', delta: '↑ 1' },
    { value: `★ ${(stats.rating || 4.7).toFixed(1)}`, label: 'Оценка', delta: '↑ 0.2' },
  ];
  container.innerHTML = `
    <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:10px;margin-bottom:14px;">
      ${kpiData.slice(0, 2).map(kpi => `
        <div class="card" style="padding:14px;">
          <div style="font-size:18px;font-weight:700;color:var(--kOrange);">${kpi.value}</div>
          <div style="font-size:12px;color:var(--kMuted);margin-top:4px;">${kpi.label}</div>
          <div style="font-size:11px;font-weight:700;color:var(--kDelta);margin-top:4px;">${kpi.delta}</div>
        </div>
      `).join('')}
    </div>
    <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-bottom:14px;">
      ${kpiData.slice(2).map(kpi => `
        <div class="card" style="padding:14px;">
          <div style="font-size:16px;font-weight:700;color:var(--kOrange);">${kpi.value}</div>
          <div style="font-size:11px;color:var(--kMuted);margin-top:4px;">${kpi.label}</div>
          <div style="font-size:10px;font-weight:700;color:var(--kDelta);margin-top:4px;">${kpi.delta}</div>
        </div>
      `).join('')}
    </div>
  `;
}

function renderFinanceContent() {
  const stats = store.getStats();
  const container = document.getElementById('report-content');
  if (!container) return;

  const period = getEffectivePeriod();
  const dateRange = getEffectiveDateRange();
  const filteredReceipts = store.receipts.filter(r => isInPeriod(r.date, period) && isInDateRange(r.date, dateRange));
  const filteredRevenue = filteredReceipts.reduce((s, r) => s + r.total, 0);
  const filteredAvgCheck = filteredReceipts.length ? Math.round(filteredRevenue / filteredReceipts.length) : 0;

  container.innerHTML = `
    <div id="finance-dashboard-card"></div>
    <div class="card pie-chart-card" style="margin-bottom:14px;">
      <div class="card-header"><div class="card-title">Структура выручки</div></div>
      <div style="height:180px;"><canvas id="sales-pie"></canvas></div>
    </div>
    <div id="kpi-cards-container"></div>
    <div class="card" style="margin-bottom:14px;">
      <div class="card-header"><div class="card-title">Оплата и тарифы</div></div>
      <div style="height:160px;"><canvas id="payment-chart"></canvas></div>
    </div>
    <div class="card" style="margin-bottom:14px;">
      <div class="card-header">
        <div class="card-title">Динамика выручки</div>
        <div style="display:flex;gap:4px;">
          <button class="btn btn-ghost" id="toggle-monthly" style="padding:4px 10px;font-size:12px;border-radius:8px;background:var(--kSelected);color:var(--kInk);font-weight:700;">Месяц</button>
          <button class="btn btn-ghost" id="toggle-weekly" style="padding:4px 10px;font-size:12px;border-radius:8px;color:var(--kMuted);">Неделя</button>
        </div>
      </div>
      <div style="height:200px;"><canvas id="revenue-chart"></canvas></div>
    </div>
  `;

  setTimeout(() => {
    // KPI карточки
    const kpiContainer = document.getElementById('kpi-cards-container');
    if (kpiContainer) renderKpiCards(kpiContainer, stats, filteredAvgCheck);

    const fdContainer = document.getElementById('finance-dashboard-card');
    if (fdContainer) {
      renderFinanceDashboardCard(fdContainer, {
        revenue: stats.totalRevenue,
        revenueDeltaPct: 12.3,
        marginProfit: Math.round(stats.totalRevenue * 0.7),
        marginPct: 70.0,
        variableExpenses: Math.round(stats.totalRevenue * 0.3),
        expensesPct: 30.0,
        sparkline: [0.45, 0, 0.25, 0.75, 0, 0.45, 0.38],
      });
    }
    const salesCanvas = document.getElementById('sales-pie');
    if (salesCanvas) drawDoughnut(salesCanvas,
      ['Осётр', 'Карп', 'Амур', 'Линь', 'Форель'],
      [6615, 885, 2250, 1449, 2760],
      ['#E8912B', '#F3EEE4', '#4F9D75', '#8B94A0', '#B8862E']
    );
    const payCanvas = document.getElementById('payment-chart');
    if (payCanvas) drawDoughnut(payCanvas,
      ['Наличные', 'Карта', 'Счёт заведения'],
      [3, 4, 1],
      ['#4F9D75', '#2196F3', '#FF9800']
    );
    const revCanvas = document.getElementById('revenue-chart');
    if (revCanvas) drawLineChart(revCanvas,
      ['13.07', '14.07', '15.07', '16.07', '17.07', '18.07'],
      [2550, 2199, 3018, 3000, 1710, 6732]
    );

    // Toggle месяц/неделя
    const monthlyData = { labels: ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл'], values: [45000, 52000, 48000, 61000, 55000, 67000, 72000] };
    const weeklyData = { labels: ['13.07', '14.07', '15.07', '16.07', '17.07', '18.07'], values: [2550, 2199, 3018, 3000, 1710, 6732] };
    let isMonthly = true;
    const btnMonthly = document.getElementById('toggle-monthly');
    const btnWeekly = document.getElementById('toggle-weekly');
    btnMonthly?.addEventListener('click', () => {
      isMonthly = true;
      btnMonthly.style.background = 'var(--kSelected)'; btnMonthly.style.color = 'var(--kInk)'; btnMonthly.style.fontWeight = '700';
      btnWeekly.style.background = 'transparent'; btnWeekly.style.color = 'var(--kMuted)'; btnWeekly.style.fontWeight = '400';
      drawLineChart(revCanvas, monthlyData.labels, monthlyData.values);
      tg.hapticSelection();
    });
    btnWeekly?.addEventListener('click', () => {
      isMonthly = false;
      btnWeekly.style.background = 'var(--kSelected)'; btnWeekly.style.color = 'var(--kInk)'; btnWeekly.style.fontWeight = '700';
      btnMonthly.style.background = 'transparent'; btnMonthly.style.color = 'var(--kMuted)'; btnMonthly.style.fontWeight = '400';
      drawLineChart(revCanvas, weeklyData.labels, weeklyData.values);
      tg.hapticSelection();
    });
  }, 0);
}

function renderClientStats() {
  const container = document.getElementById('report-content');
  if (!container) return;

  const period = getEffectivePeriod();
  const dateRange = getEffectiveDateRange();
  const entries = store.receipts
    .filter(r => r.clientId && !r.isGuest && isInPeriod(r.date, period) && isInDateRange(r.date, dateRange))
    .map(r => ({ receipt: r, client: store.getClientById(r.clientId) }))
    .sort((a, b) => b.receipt.date.localeCompare(a.receipt.date));

  container.innerHTML = entries.length ? entries.map(({ receipt: r, client }) => `
    <div class="payment-row" data-client-id="${r.clientId}" style="display:flex;align-items:center;gap:12px;padding:13px 2px;border-bottom:0.5px solid var(--kHairline2);">
      ${store.renderAvatar(client, 44)}
      <div style="flex:1;min-width:0;">
        <div style="font-size:15.5px;font-weight:700;color:var(--kInk);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${client?.name || 'Неизвестен'}</div>
        <div style="font-size:12.5px;color:var(--kMuted2);margin-top:2px;">${r.date}</div>
      </div>
      <div style="text-align:right;">
        <div style="font-size:17px;font-weight:700;color:#3FA66B;">+${store.formatMoney(r.total)} ₽</div>
        <div style="font-size:11.5px;color:var(--kMuted2);margin-top:2px;">LT ${client?.visits || 0} / LTV ${store.formatMoney(store.getClientLTV(r.clientId))}</div>
      </div>
    </div>
  `).join('') : `
    <div class="empty-state">
      <div style="font-size:48px;margin-bottom:12px;"><svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#9C9484" stroke-width="1.5"><path d="M3 3v18h18"/><path d="m19 9-5 5-4-4-3 3"/></svg></div>
      <div style="font-size:14px;color:var(--kMuted2);">Нет оплат по заданным условиям</div>
    </div>
  `;

  // Автокомплит клиентов
  renderClientAutocomplete(container);

  container.querySelectorAll('.payment-row').forEach(row => {
    const avatar = row.querySelector('.client-avatar');
    if (avatar) {
      avatar.style.cursor = 'pointer';
      avatar.addEventListener('click', () => {
        showClientCard(parseInt(row.dataset.clientId));
        tg.hapticImpact('light');
      });
    }
  });
}

// ── Автокомплит клиентов (как в Чеках) ──
function renderClientAutocomplete(container) {
  const searchHtml = `
    <div class="search-bar" style="margin-bottom:10px;">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#9C9484" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
      <input type="text" id="report-client-search" placeholder="Поиск клиента" autocomplete="off">
      <svg id="report-search-clear" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#9C9484" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="cursor:pointer;display:none;"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
    </div>
    <div id="report-client-suggestions"></div>
  `;
  container.insertAdjacentHTML('afterbegin', searchHtml);

  const searchInput = document.getElementById('report-client-search');
  const clearBtn = document.getElementById('report-search-clear');
  const suggestionsDiv = document.getElementById('report-client-suggestions');

  function updateSuggestions(q) {
    if (!suggestionsDiv) return;
    if (!q) { suggestionsDiv.innerHTML = ''; suggestionsDiv.className = 'hidden'; return; }
    const query = q.toLowerCase();
    const seen = new Set();
    const clients = store.receipts
      .filter(r => r.clientId && !r.isGuest)
      .map(r => store.getClientById(r.clientId))
      .filter(c => c && !seen.has(c.id) && (c.name.toLowerCase().includes(query) || c.phone.includes(query)) && seen.add(c.id))
      .sort((a, b) => {
        const aS = a.name.toLowerCase().startsWith(query) ? 0 : 1;
        const bS = b.name.toLowerCase().startsWith(query) ? 0 : 1;
        return aS !== bS ? aS - bS : a.name.localeCompare(b.name);
      })
      .slice(0, 4);
    if (!clients.length) { suggestionsDiv.innerHTML = ''; suggestionsDiv.className = 'hidden'; return; }
    suggestionsDiv.className = 'client-suggestions';
    suggestionsDiv.innerHTML = clients.map(c => `
      <div class="client-suggestion-item" data-client-id="${c.id}">
        ${store.renderAvatar(c, 36)}
        <div style="flex:1;min-width:0;"><div style="font-size:14px;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${c.name}</div><div style="font-size:12px;color:var(--kMuted2);">${c.phone}</div></div>
      </div>
    `).join('');
    suggestionsDiv.querySelectorAll('.client-suggestion-item').forEach(item => {
      item.addEventListener('click', () => {
        const clientId = parseInt(item.dataset.clientId);
        suggestionsDiv.innerHTML = '';
        suggestionsDiv.className = 'hidden';
        searchInput.value = '';
        clearBtn.style.display = 'none';
        showClientCard(clientId);
        tg.hapticImpact('light');
      });
    });
  }

  searchInput?.addEventListener('input', e => {
    const q = e.target.value.trim();
    clearBtn.style.display = q ? 'block' : 'none';
    updateSuggestions(q);
  });
  clearBtn?.addEventListener('click', () => {
    searchInput.value = '';
    clearBtn.style.display = 'none';
    if (suggestionsDiv) { suggestionsDiv.innerHTML = ''; suggestionsDiv.className = 'hidden'; }
  });
}

// ─── Статистика улова: две таблицы + кнопка «Добавить рыбу» ───
function renderFishStats() {
  const container = document.getElementById('report-content');
  if (!container) return;

  const period = getEffectivePeriod();
  const dateRange = getEffectiveDateRange();

  // Собираем статистику улова из чеков
  const fishStats = {};
  store.receipts.filter(r => isInPeriod(r.date, period) && isInDateRange(r.date, dateRange)).forEach(r => {
    r.catches.forEach(c => {
      const name = c.label || c.breedLabel;
      if (!fishStats[name]) fishStats[name] = { count: 0, totalKg: 0, totalSum: 0, emoji: '', image: '' };
      fishStats[name].count++;
      fishStats[name].totalKg += c.kg + c.grams / 1000;
      fishStats[name].totalSum += c.sum;
      const breed = store.fishBreeds.find(f => f.label === name);
      if (breed) {
        fishStats[name].emoji = breed.emoji;
        fishStats[name].image = breed.image;
      }
    });
  });

  // Остатки из store (демо)
  const fishRemaining = { 'Осётр': 120, 'Карп': 250, 'Амур': 80, 'Линь': 65, 'Форель': 45 };
  const fishMargin = { 'Осётр': 42, 'Карп': 28, 'Амур': 35, 'Линь': 30, 'Форель': 38 };

  const fishEntries = Object.entries(fishStats).sort((a, b) => b[1].totalSum - a[1].totalSum);
  const totalRevenue = fishEntries.reduce((s, [, v]) => s + v.totalSum, 0);
  const totalCount = fishEntries.reduce((s, [, v]) => s + v.count, 0);
  const totalRemaining = Object.entries(fishRemaining).reduce((s, [k, v]) => s + v + (addedFish[k] || 0), 0);
  const totalMargin = fishEntries.length ? Math.round(fishEntries.reduce((s, [name]) => s + (fishMargin[name] || 30), 0) / fishEntries.length) : 0;

  const revenues = fishEntries.map(([, s]) => s.totalSum);
  const minRev = revenues.length ? Math.min(...revenues) : 0;
  const maxRev = revenues.length ? Math.max(...revenues) : 1;

  function revenueColor(value) {
    if (maxRev <= minRev) return 'var(--kFill)';
    const t = Math.max(0, Math.min(1, (value - minRev) / (maxRev - minRev)));
    return t < 0.5 ? '#FBE8D0' : '#D4EDDA';
  }

  function formatNum(v) {
    if (v >= 1000000) return (v / 1000000).toFixed(1).replace('.', ',') + ' млн';
    if (v > 999) return Math.round(v / 1000) + ' тыс.';
    return String(v);
  }

  function formatRevenue(v) {
    const rounded = Math.round(v);
    if (rounded >= 1000000) return (rounded / 1000000).toFixed(1).replace('.', ',') + ' млн';
    if (rounded > 999) return Math.round(rounded / 1000) + ' тыс.';
    return store.formatMoney(rounded);
  }

  container.innerHTML = `
    <!-- Таблица 1: Вылов/Вес/Выручка/Остаток -->
    <div style="border:0.5px solid #EFE8D8;border-radius:12px;overflow:hidden;margin-bottom:18px;">
      <div style="display:flex;padding:10px 12px;background:#F3EEE4;border-bottom:0.5px solid #DDD3BC;">
        <div style="flex:3;font-size:11px;font-weight:700;color:#8C8576;">Тип рыбы</div>
        <div style="flex:2;font-size:11px;font-weight:700;color:#8C8576;text-align:center;">Вылов (шт.)</div>
        <div style="flex:2;font-size:11px;font-weight:700;color:#8C8576;text-align:center;">Ср. Вес (кг.)</div>
        <div style="flex:3;font-size:11px;font-weight:700;color:#8C8576;text-align:center;">Выручка</div>
        <div style="flex:2;font-size:11px;font-weight:700;color:#8C8576;text-align:center;">Остаток (шт.)</div>
      </div>
      ${fishEntries.map(([name, s]) => {
        const breed = store.fishBreeds.find(f => f.label === name);
        const avgWeight = s.count > 0 ? (s.totalKg / s.count).toFixed(1) : '0.0';
        const remaining = (fishRemaining[name] || 0) + (addedFish[name] || 0);
        const lowStock = remaining < 50;
        return `
          <div style="display:flex;padding:12px;background:#FBF6EC;border-top:0.5px solid #EFE8D8;align-items:center;">
            <div style="flex:3;display:flex;flex-direction:column;align-items:center;">
              <div style="height:24px;display:flex;align-items:center;justify-content:center;">
                ${breed?.image ? `<img src="${breed.image}" style="height:24px;border-radius:4px;" alt="">` : `<span style="font-size:18px;">${s.emoji}</span>`}
              </div>
              <div style="font-size:13px;font-weight:600;color:#14130F;margin-top:4px;">${name}</div>
            </div>
            <div style="flex:2;font-size:13px;color:#14130F;text-align:center;">${formatNum(s.count)}</div>
            <div style="flex:2;font-size:13px;color:#14130F;text-align:center;">${avgWeight}</div>
            <div style="flex:3;text-align:center;">
              <span style="display:inline-block;padding:4px 6px;font-size:13px;font-weight:600;border-radius:8px;background:${revenueColor(s.totalSum)};color:#14130F;">${formatRevenue(s.totalSum)}</span>
            </div>
            <div style="flex:2;font-size:13px;text-align:center;font-weight:${lowStock ? '700' : '400'};color:${lowStock ? '#C9302C' : '#14130F'};">${formatNum(remaining)}</div>
          </div>
        `;
      }).join('')}
      <div style="display:flex;padding:12px;background:#F3EEE4;border-top:0.5px solid #DDD3BC;">
        <div style="flex:3;font-size:13px;font-weight:800;color:#14130F;text-align:center;">ИТОГО</div>
        <div style="flex:2;font-size:13px;font-weight:700;color:#14130F;text-align:center;">${formatNum(totalCount)}</div>
        <div style="flex:2;font-size:13px;font-weight:700;color:#9C9484;text-align:center;">—</div>
        <div style="flex:3;text-align:center;">
          <span style="display:inline-block;padding:4px 6px;font-size:13px;font-weight:800;border-radius:8px;background:#D4EDDA;color:#14130F;">${formatRevenue(totalRevenue)}</span>
        </div>
        <div style="flex:2;font-size:13px;font-weight:700;color:#14130F;text-align:center;">${formatNum(totalRemaining)}</div>
      </div>
    </div>

    <!-- Таблица 2: Доля в выручке / Маржа -->
    <div style="border:0.5px solid #EFE8D8;border-radius:12px;overflow:hidden;margin-bottom:18px;">
      <div style="display:flex;padding:10px 12px;background:#F3EEE4;border-bottom:0.5px solid #DDD3BC;">
        <div style="flex:3;font-size:11px;font-weight:700;color:#8C8576;">Тип рыбы</div>
        <div style="flex:3;font-size:11px;font-weight:700;color:#8C8576;text-align:center;">Доля в выручке</div>
        <div style="flex:3;font-size:11px;font-weight:700;color:#8C8576;text-align:center;">Маржа</div>
      </div>
      ${fishEntries.map(([name, s]) => {
        const breed = store.fishBreeds.find(f => f.label === name);
        const sharePct = totalRevenue > 0 ? Math.round((s.totalSum / totalRevenue) * 100) : 0;
        const margin = fishMargin[name] || 30;
        return `
          <div style="display:flex;padding:12px;background:#FBF6EC;border-top:0.5px solid #EFE8D8;align-items:center;">
            <div style="flex:3;display:flex;flex-direction:column;align-items:center;">
              <div style="height:24px;display:flex;align-items:center;justify-content:center;">
                ${breed?.image ? `<img src="${breed.image}" style="height:24px;border-radius:4px;" alt="">` : `<span style="font-size:18px;">${s.emoji}</span>`}
              </div>
              <div style="font-size:13px;font-weight:600;color:#14130F;margin-top:4px;">${name}</div>
            </div>
            <div style="flex:3;text-align:center;">
              <div style="font-size:13px;color:#14130F;">${sharePct}%</div>
              <div style="height:6px;border-radius:3px;background:#EFE8D8;margin-top:4px;overflow:hidden;">
                <div style="height:100%;width:${sharePct}%;background:#E8912B;border-radius:3px;"></div>
              </div>
            </div>
            <div style="flex:3;text-align:center;">
              <div style="font-size:13px;color:#14130F;">${margin}%</div>
              <div style="height:6px;border-radius:3px;background:#EFE8D8;margin-top:4px;overflow:hidden;">
                <div style="height:100%;width:${margin}%;background:#3FA66B;border-radius:3px;"></div>
              </div>
            </div>
          </div>
        `;
      }).join('')}
      <div style="display:flex;padding:12px;background:#F3EEE4;border-top:0.5px solid #DDD3BC;">
        <div style="flex:3;font-size:13px;font-weight:800;color:#14130F;text-align:center;">ИТОГО</div>
        <div style="flex:3;font-size:13px;font-weight:700;color:#9C9484;text-align:center;">—</div>
        <div style="flex:3;text-align:center;">
          <div style="font-size:13px;font-weight:700;color:#14130F;">${totalMargin}%</div>
          <div style="height:6px;border-radius:3px;background:#EFE8D8;margin-top:4px;overflow:hidden;">
            <div style="height:100%;width:${totalMargin}%;background:#3FA66B;border-radius:3px;"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- Кнопка «Добавить рыбу в пруд» -->
    <button class="btn btn-outline" id="add-fish-btn" style="width:100%;padding:14px;border-radius:14px;background:var(--kFill);border:0.5px solid #DDD3BC;color:#8A6D1E;font-weight:700;font-size:14px;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:8px;">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" x2="12" y1="5" y2="19"/><line x1="5" x2="19" y1="12" y2="12"/></svg>
      Добавить рыбу в пруд
    </button>
  `;

  document.getElementById('add-fish-btn')?.addEventListener('click', () => {
    showAddFishDialog();
    tg.hapticImpact('light');
  });
}

// ── Диалог «Добавить рыбу в пруд» ──
function showAddFishDialog() {
  const overlay = document.createElement('div');
  overlay.className = 'modal-overlay';
  const species = store.fishBreeds.map(f => f.label);
  let selectedSpecies = species[0];

  overlay.innerHTML = `
    <div class="sheet" style="max-width:320px;">
      <div style="font-size:13px;font-weight:700;color:#8C8576;letter-spacing:0.5px;margin-bottom:16px;">ДОБАВИТЬ РЫБУ В ПРУД</div>
      <div style="margin-bottom:12px;">
        <div style="font-size:12px;font-weight:600;color:#8C8576;margin-bottom:6px;">Вид рыбы</div>
        <div id="fish-species-select" style="display:flex;flex-wrap:wrap;gap:8px;">
          ${species.map((sp, i) => {
            const breed = store.fishBreeds.find(f => f.label === sp);
            return `<div class="chip ${i === 0 ? 'selected' : ''}" data-species="${sp}" style="display:flex;align-items:center;gap:6px;padding:8px 12px;cursor:pointer;">
              ${breed?.image ? `<img src="${breed.image}" style="height:18px;border-radius:3px;">` : `<span>${breed?.emoji || ''}</span>`}
              <span>${sp}</span>
            </div>`;
          }).join('')}
        </div>
      </div>
      <div style="display:flex;gap:10px;margin-bottom:16px;">
        <div style="flex:1;">
          <div style="font-size:12px;font-weight:600;color:#8C8576;margin-bottom:6px;">Количество (шт.)</div>
          <input type="number" id="fish-qty" style="width:100%;padding:10px 12px;background:#F3EEE4;border:none;border-radius:12px;font-size:14px;box-sizing:border-box;" placeholder="0">
        </div>
        <div style="flex:1;">
          <div style="font-size:12px;font-weight:600;color:#8C8576;margin-bottom:6px;">Затраты</div>
          <input type="number" id="fish-cost" style="width:100%;padding:10px 12px;background:#F3EEE4;border:none;border-radius:12px;font-size:14px;box-sizing:border-box;" placeholder="0">
        </div>
      </div>
      <div style="display:flex;gap:10px;">
        <button class="btn btn-ghost" id="fish-cancel" style="flex:1;padding:14px;border-radius:12px;border:0.5px solid #DDD3BC;color:#9C9484;">Отмена</button>
        <button class="btn" id="fish-add" style="flex:1;padding:14px;border-radius:12px;background:#E8912B;color:#fff;font-weight:700;">Добавить</button>
      </div>
    </div>
  `;
  document.body.appendChild(overlay);

  // Выбор вида рыбы
  overlay.querySelectorAll('[data-species]').forEach(chip => {
    chip.addEventListener('click', () => {
      overlay.querySelectorAll('[data-species]').forEach(c => c.classList.remove('selected'));
      chip.classList.add('selected');
      selectedSpecies = chip.dataset.species;
      tg.hapticSelection();
    });
  });

  overlay.querySelector('#fish-cancel')?.addEventListener('click', () => overlay.remove());
  overlay.addEventListener('click', e => { if (e.target === overlay) overlay.remove(); });

  overlay.querySelector('#fish-add')?.addEventListener('click', () => {
    const qty = parseInt(overlay.querySelector('#fish-qty').value) || 0;
    if (qty <= 0) return;
    addedFish[selectedSpecies] = (addedFish[selectedSpecies] || 0) + qty;
    overlay.remove();
    tg.hapticNotification('success');
    renderFishStats();
  });
}
