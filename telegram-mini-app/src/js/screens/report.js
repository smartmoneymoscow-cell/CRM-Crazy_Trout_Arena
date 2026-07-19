// === Screen: Отчёт (точь-в-точь Flutter report_screen.dart) ===
import { store } from '../core/store.js';
import { tg } from '../core/telegram.js';
import { drawDoughnut, drawLineChart } from '../widgets/charts.js';
import { renderFinanceDashboardCard } from '../widgets/finance-dashboard.js';
import { createFilterDropdown } from '../widgets/filter-dropdown.js';
import { showCalendarPicker } from '../widgets/calendar.js';
import { showClientCard } from '../widgets/client-card.js';

let selectedIcon = 0; // 0=ruble, 1=clients, 2=fish

export function renderReport() {
  const stats = store.getStats();
  const el = document.createElement('div');
  el.className = 'screen screen-report';
  el.innerHTML = `
    <div class="screen-title" id="report-title">Финансы и метрики</div>

    <!-- Фильтры -->
    <div class="filter-bar">
      <div id="period-dropdown"></div>
      <div class="calendar-chip" id="calendar-chip" title="Календарь">📅</div>
      <div class="icon-filter-chip ${selectedIcon === 0 ? 'active' : ''}" data-icon="0" title="Финансы"><img src="src/assets/icons/ruble.png" style="width:20px;height:20px;"></div>
      <div class="icon-filter-chip ${selectedIcon === 1 ? 'active' : ''}" data-icon="1" title="Клиенты"><img src="src/assets/icons/clients.png" style="width:20px;height:20px;"></div>
      <div class="icon-filter-chip ${selectedIcon === 2 ? 'active' : ''}" data-icon="2" title="Рыба"><img src="src/assets/icons/fish.png" style="width:20px;height:20px;"></div>
    </div>

    <!-- Контент -->
    <div id="report-content"></div>
  `;

  setTimeout(() => {
    renderFinanceContent();
    initReportHandlers();
  }, 0);
  return el;
}

function initReportHandlers() {
  // Иконки-фильтры
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

  // Period dropdown (FilterDropdown-компонент)
  const periodContainer = document.getElementById('period-dropdown');
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
      onChanged: (v) => { renderContent(); },
    });
  }

  // Calendar
  document.getElementById('calendar-chip')?.addEventListener('click', async () => {
    const result = await showCalendarPicker(null);
    if (result) renderContent();
  });
}

function renderContent() {
  if (selectedIcon === 1) renderClientStats();
  else if (selectedIcon === 2) renderFishStats();
  else renderFinanceContent();
}

function renderFinanceContent() {
  const stats = store.getStats();
  const container = document.getElementById('report-content');
  if (!container) return;

  // KPI данные
  const kpiData = [
    { value: `${store.formatMoney(stats.totalRevenue)} ₽`, label: 'Выручка', change: '↑ 12%', up: true },
    { value: `${store.formatMoney(stats.avgCheck)} ₽`, label: 'Средний чек', change: '↑ 5%', up: true },
    { value: `${stats.uniqueClients}`, label: 'Клиентов', change: '↑ 3', up: true },
    { value: `${stats.totalReceipts}`, label: 'Чеков', change: '↑ 2', up: true },
  ];

  container.innerHTML = `
    <!-- Finance Dashboard Card (как Flutter FinanceDashboardCard) -->
    <div id="finance-dashboard-card"></div>

    <!-- Pie chart: структура выручки -->
    <div class="card pie-chart-card">
      <div class="card-header"><div class="card-title">Структура выручки</div></div>
      <div style="height:180px;"><canvas id="sales-pie"></canvas></div>
    </div>

    <!-- KPI карточки -->
    <div class="kpi-grid">
      ${kpiData.map(k => `
        <div class="card kpi-card">
          <div class="kpi-value">${k.value}</div>
          <div class="kpi-label">${k.label}</div>
          <div class="kpi-change ${k.up ? 'up' : 'down'}">${k.change}</div>
        </div>
      `).join('')}
    </div>

    <!-- Payment/Tariff -->
    <div class="card" style="margin-bottom:14px;">
      <div class="card-header"><div class="card-title">Оплата и тарифы</div></div>
      <div style="height:160px;"><canvas id="payment-chart"></canvas></div>
    </div>

    <!-- Revenue Dynamics -->
    <div class="card dynamics-card">
      <div class="card-header"><div class="card-title">Динамика выручки</div></div>
      <div style="height:200px;"><canvas id="revenue-chart"></canvas></div>
    </div>
  `;

  setTimeout(() => initCharts(), 0);
}

function initCharts() {
  // FinanceDashboardCard (как Flutter)
  const fdContainer = document.getElementById('finance-dashboard-card');
  if (fdContainer) {
    renderFinanceDashboardCard(fdContainer, {
      revenue: 17002,
      revenueDeltaPct: 12.3,
      marginProfit: 11901,
      marginPct: 70.0,
      variableExpenses: 5101,
      expensesPct: 30.0,
      sparkline: [0.45, 0, 0.25, 0.75, 0, 0.45, 0.38],
    });
  }

  // Sales pie (кастомный Canvas, как Flutter FinancePieChart)
  const salesCanvas = document.getElementById('sales-pie');
  if (salesCanvas) drawDoughnut(salesCanvas,
    ['Осётр', 'Карп', 'Амур', 'Линь', 'Форель'],
    [6615, 885, 2250, 1449, 2760],
    ['#E8912B', '#F3EEE4', '#4F9D75', '#8B94A0', '#B8862E']
  );

  // Payment chart (кастомный Canvas)
  const payCanvas = document.getElementById('payment-chart');
  if (payCanvas) drawDoughnut(payCanvas,
    ['Наличные', 'Карта', 'Счёт заведения'],
    [3, 4, 1],
    ['#4F9D75', '#2196F3', '#FF9800']
  );

  // Revenue dynamics (кастомный Canvas, как Flutter RevenueDynamicsChart)
  const revCanvas = document.getElementById('revenue-chart');
  if (revCanvas) drawLineChart(revCanvas,
    ['13.07', '14.07', '15.07', '16.07', '17.07', '18.07'],
    [2550, 2199, 3018, 3000, 1710, 6732]
  );
}

function renderClientStats() {
  const container = document.getElementById('report-content');
  if (!container) return;

  const entries = store.receipts
    .filter(r => r.clientId && !r.isGuest)
    .map(r => {
      const client = store.getClientById(r.clientId);
      return { receipt: r, client };
    })
    .sort((a, b) => b.receipt.date.localeCompare(a.receipt.date));

  container.innerHTML = entries.length ? entries.map(({ receipt: r, client }) => `
    <div class="payment-row" data-client-id="${r.clientId}">
      ${store.renderAvatar(client, 44)}
      <div class="payment-info">
        <div class="payment-name">${client?.name || 'Неизвестен'}</div>
        <div class="payment-date">${r.date}</div>
      </div>
      <div>
        <span class="payment-amount">+${store.formatMoney(r.total)} ₽</span>
        <span class="payment-lt">LT ${client?.visits || 0} / LTV ${store.formatMoney(store.getClientLTV(r.clientId))}</span>
      </div>
    </div>
  `).join('') : `
    <div class="empty-state">
      <div class="empty-icon">📊</div>
      <div class="empty-text">Нет оплат по заданным условиям</div>
    </div>
  `;

  // Клик по аватару → карточка клиента
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

function renderFishStats() {
  const container = document.getElementById('report-content');
  if (!container) return;

  const fishStats = {};
  store.receipts.forEach(r => {
    r.catches.forEach(c => {
      if (!fishStats[c.breedLabel]) fishStats[c.breedLabel] = { count: 0, totalKg: 0, totalSum: 0 };
      fishStats[c.breedLabel].count++;
      fishStats[c.breedLabel].totalKg += c.kg + c.grams / 1000;
      fishStats[c.breedLabel].totalSum += c.sum;
    });
  });

  container.innerHTML = `
    <div class="card" style="margin-bottom:14px;">
      <div class="card-header"><div class="card-title">Статистика улова</div></div>
      ${Object.entries(fishStats).map(([name, s]) => `
        <div style="display:flex;justify-content:space-between;padding:10px 0;border-bottom:0.5px solid var(--kHairline2);">
          <span style="font-weight:600;">${name}</span>
          <span style="color:var(--kMuted2);">${s.count} раз · ${s.totalKg.toFixed(1)} кг</span>
          <span style="font-weight:700;color:var(--kOrange);">${store.formatMoney(s.totalSum)} ₽</span>
        </div>
      `).join('')}
    </div>
  `;
}
