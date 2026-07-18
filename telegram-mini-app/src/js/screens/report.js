// === Screen: Финансовый дашборд ===

import { store } from '../core/store.js';

export function renderReport() {
  const stats = store.getStats();
  const el = document.createElement('div');
  el.className = 'screen screen-report';
  el.innerHTML = `
    <h2 style="margin-bottom: var(--spacing-xl); font-size: var(--font-size-xl);">📊 Отчёт</h2>

    <!-- KPI карточки -->
    <div class="kpi-grid">
      <div class="card kpi-card">
        <div class="kpi-value">${stats.totalRevenue.toLocaleString('ru-RU')}₽</div>
        <div class="kpi-label">Выручка</div>
        <div class="kpi-change up">↑ 12%</div>
      </div>
      <div class="card kpi-card">
        <div class="kpi-value">${stats.avgCheck.toLocaleString('ru-RU')}₽</div>
        <div class="kpi-label">Средний чек</div>
        <div class="kpi-change up">↑ 5%</div>
      </div>
      <div class="card kpi-card">
        <div class="kpi-value">${stats.uniqueClients}</div>
        <div class="kpi-label">Клиентов</div>
        <div class="kpi-change up">↑ 3</div>
      </div>
      <div class="card kpi-card">
        <div class="kpi-value">${stats.totalReceipts}</div>
        <div class="kpi-label">Чеков</div>
        <div class="kpi-change up">↑ 2</div>
      </div>
    </div>

    <!-- График выручки -->
    <div class="card" style="margin-bottom: var(--spacing-lg);">
      <div class="card-header">
        <div class="card-title">Динамика выручки</div>
      </div>
      <div class="chart-container">
        <canvas id="revenue-chart"></canvas>
      </div>
    </div>

    <!-- Структура выручки -->
    <div class="card" style="margin-bottom: var(--spacing-lg);">
      <div class="card-header">
        <div class="card-title">По тарифам</div>
      </div>
      <div class="chart-container" style="height: 160px;">
        <canvas id="tariff-chart"></canvas>
      </div>
    </div>

    <!-- По способу оплаты -->
    <div class="card">
      <div class="card-header">
        <div class="card-title">Оплата</div>
      </div>
      <div class="chart-container" style="height: 160px;">
        <canvas id="payment-chart"></canvas>
      </div>
    </div>
  `;

  // Инициализация графиков после рендера
  setTimeout(() => initCharts(stats), 0);

  return el;
}

function initCharts(stats) {
  // Revenue chart
  const revenueCtx = document.getElementById('revenue-chart');
  if (revenueCtx && window.Chart) {
    new Chart(revenueCtx, {
      type: 'line',
      data: {
        labels: ['14.07', '15.07', '16.07', '17.07', '18.07'],
        datasets: [{
          label: 'Выручка',
          data: [3150, 0, 0, 1950, 5160],
          borderColor: '#E8912B',
          backgroundColor: 'rgba(232,145,43,0.1)',
          fill: true,
          tension: 0.4,
          pointRadius: 4,
          pointBackgroundColor: '#E8912B',
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          y: { beginAtZero: true, ticks: { callback: v => v + '₽' } },
          x: { grid: { display: false } }
        }
      }
    });
  }

  // Tariff chart
  const tariffCtx = document.getElementById('tariff-chart');
  if (tariffCtx && window.Chart) {
    new Chart(tariffCtx, {
      type: 'doughnut',
      data: {
        labels: ['Стандарт', 'Гостевой', 'Пенсионер'],
        datasets: [{
          data: [4, 1, 1],
          backgroundColor: ['#E8912B', '#F3EEE4', '#8E8E8E'],
          borderWidth: 0,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { position: 'right' } },
        cutout: '60%',
      }
    });
  }

  // Payment chart
  const paymentCtx = document.getElementById('payment-chart');
  if (paymentCtx && window.Chart) {
    new Chart(paymentCtx, {
      type: 'doughnut',
      data: {
        labels: ['Наличные', 'Карта', 'Счёт заведения'],
        datasets: [{
          data: [2, 2, 1],
          backgroundColor: ['#4CAF50', '#2196F3', '#FF9800'],
          borderWidth: 0,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { position: 'right' } },
        cutout: '60%',
      }
    });
  }
}
