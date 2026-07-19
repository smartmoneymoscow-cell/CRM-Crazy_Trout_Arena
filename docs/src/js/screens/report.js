// === Screen: Отчёт (точь-в-точь Flutter report_screen.dart) ===
import { store } from '../core/store.js';
import { tg } from '../core/telegram.js';
import { drawDoughnut, drawLineChart } from '../widgets/charts.js';
import { renderFinanceDashboardCard } from '../widgets/finance-dashboard.js';
import { createFilterDropdown } from '../widgets/filter-dropdown.js';
import { showCalendarPicker } from '../widgets/calendar.js';
import { showClientCard } from '../widgets/client-card.js';

let selectedIcon = 0;

export function renderReport() {
  const stats = store.getStats();
  const el = document.createElement('div');
  el.className = 'screen screen-report';
  el.innerHTML = `
    <div class="screen-title" id="report-title">Финансы и метрики</div>
    <div class="filter-bar">
      <div id="period-dropdown"></div>
      <div class="calendar-chip" id="calendar-chip" title="Календарь">📅</div>
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
        { value: null, label: 'Нет', isReset: true, enabled: false },
        { value: 'today', label: 'Сегодня' },
        { value: 'week', label: 'Неделя' },
        { value: 'month', label: 'Месяц' },
        { value: 'quarter', label: 'Квартал' },
        { value: 'all', label: 'Все время' },
      ],
      onChanged: () => renderContent(),
    });
  }

  document.getElementById('calendar-chip')?.addEventListener('click', async () => {
    await showCalendarPicker(null);
    renderContent();
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

  container.innerHTML = `
    <div id="finance-dashboard-card"></div>
    <div class="card pie-chart-card" style="margin-bottom:14px;">
      <div class="card-header"><div class="card-title">Структура выручки</div></div>
      <div style="height:180px;"><canvas id="sales-pie"></canvas></div>
    </div>
    <div class="kpi-grid" style="display:grid;grid-template-columns:repeat(2,1fr);gap:12px;margin-bottom:14px;">
      <div class="card" style="padding:16px;">
        <div style="font-size:22px;font-weight:700;color:var(--kOrange);">${store.formatMoney(stats.totalRevenue)} ₽</div>
        <div style="font-size:12px;color:var(--kMuted);margin-top:4px;">Выручка</div>
        <div style="font-size:11px;font-weight:700;color:var(--kDelta);margin-top:4px;">↑ 12%</div>
      </div>
      <div class="card" style="padding:16px;">
        <div style="font-size:22px;font-weight:700;color:var(--kOrange);">${store.formatMoney(stats.avgCheck)} ₽</div>
        <div style="font-size:12px;color:var(--kMuted);margin-top:4px;">Средний чек</div>
        <div style="font-size:11px;font-weight:700;color:var(--kDelta);margin-top:4px;">↑ 5%</div>
      </div>
      <div class="card" style="padding:16px;">
        <div style="font-size:22px;font-weight:700;color:var(--kOrange);">${stats.uniqueClients}</div>
        <div style="font-size:12px;color:var(--kMuted);margin-top:4px;">Клиентов</div>
        <div style="font-size:11px;font-weight:700;color:var(--kDelta);margin-top:4px;">↑ 3</div>
      </div>
      <div class="card" style="padding:16px;">
        <div style="font-size:22px;font-weight:700;color:var(--kOrange);">${stats.totalReceipts}</div>
        <div style="font-size:12px;color:var(--kMuted);margin-top:4px;">Чеков</div>
        <div style="font-size:11px;font-weight:700;color:var(--kDelta);margin-top:4px;">↑ 2</div>
      </div>
    </div>
    <div class="card" style="margin-bottom:14px;">
      <div class="card-header"><div class="card-title">Оплата и тарифы</div></div>
      <div style="height:160px;"><canvas id="payment-chart"></canvas></div>
    </div>
    <div class="card" style="margin-bottom:14px;">
      <div class="card-header"><div class="card-title">Динамика выручки</div></div>
      <div style="height:200px;"><canvas id="revenue-chart"></canvas></div>
    </div>
  `;

  setTimeout(() => {
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
  }, 0);
}

function renderClientStats() {
  const container = document.getElementById('report-content');
  if (!container) return;

  const entries = store.receipts
    .filter(r => r.clientId && !r.isGuest)
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
      <div style="font-size:48px;margin-bottom:12px;">📊</div>
      <div style="font-size:14px;color:var(--kMuted2);">Нет оплат по заданным условиям</div>
    </div>
  `;

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
      if (!fishStats[c.breedLabel]) fishStats[c.breedLabel] = { count: 0, totalKg: 0, totalSum: 0, emoji: '' };
      fishStats[c.breedLabel].count++;
      fishStats[c.breedLabel].totalKg += c.kg + c.grams / 1000;
      fishStats[c.breedLabel].totalSum += c.sum;
      const breed = store.fishBreeds.find(f => f.label === c.breedLabel);
      if (breed) fishStats[c.breedLabel].emoji = breed.emoji;
    });
  });

  const fishEntries = Object.entries(fishStats).sort((a, b) => b[1].totalSum - a[1].totalSum);
  const maxSum = fishEntries.length ? fishEntries[0][1].totalSum : 1;

  container.innerHTML = `
    <div class="card" style="margin-bottom:14px;">
      <div class="card-header"><div class="card-title">Статистика улова</div></div>
      <div style="height:200px;margin-bottom:16px;"><canvas id="fish-chart"></canvas></div>
      ${fishEntries.map(([name, s]) => {
        const pct = Math.round((s.totalSum / maxSum) * 100);
        const breed = store.fishBreeds.find(f => f.label === name);
        return `
          <div style="display:flex;align-items:center;gap:10px;padding:10px 0;border-bottom:0.5px solid var(--kHairline2);">
            <div style="width:36px;height:36px;border-radius:8px;background:var(--kFill);display:flex;align-items:center;justify-content:center;flex-shrink:0;">
              <img src="${breed?.image || ''}" style="height:24px;border-radius:4px;" alt="">
            </div>
            <div style="flex:1;min-width:0;">
              <div style="display:flex;justify-content:space-between;margin-bottom:4px;">
                <span style="font-size:13px;font-weight:600;">${name}</span>
                <span style="font-size:13px;font-weight:700;color:var(--kOrange);">${store.formatMoney(s.totalSum)} ₽</span>
              </div>
              <div style="height:4px;border-radius:2px;background:var(--kFill);overflow:hidden;">
                <div style="height:100%;width:${pct}%;background:linear-gradient(90deg,var(--kOrange),#F0A050);border-radius:2px;"></div>
              </div>
              <div style="font-size:11px;color:var(--kMuted2);margin-top:4px;">${s.count} раз · ${s.totalKg.toFixed(1)} кг</div>
            </div>
          </div>
        `;
      }).join('')}
    </div>
  `;

  setTimeout(() => {
    const fishCanvas = document.getElementById('fish-chart');
    if (fishCanvas && fishEntries.length) {
      drawDoughnut(fishCanvas,
        fishEntries.map(([name]) => name),
        fishEntries.map(([, s]) => s.totalSum),
        ['#E8912B', '#F3EEE4', '#4F9D75', '#8B94A0', '#B8862E']
      );
    }
  }, 0);
}
