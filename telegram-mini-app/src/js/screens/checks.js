// === Screen: История чеков ===

import { store } from '../core/store.js';
import { tg } from '../core/telegram.js';

export function renderChecks() {
  const stats = store.getStats();
  
  const el = document.createElement('div');
  el.className = 'screen screen-checks';
  el.innerHTML = `
    <!-- Поиск -->
    <div class="search-bar">
      <span class="search-icon">🔍</span>
      <input class="input" id="checks-search" type="text" placeholder="Поиск по клиенту...">
    </div>

    <!-- Сводка -->
    <div class="card" style="margin-bottom: var(--spacing-lg);">
      <div style="display: flex; justify-content: space-between;">
        <div>
          <div style="font-size: var(--font-size-sm); color: var(--color-text-secondary);">Всего чеков</div>
          <div style="font-size: var(--font-size-xl); font-weight: bold;">${stats.totalReceipts}</div>
        </div>
        <div style="text-align: right;">
          <div style="font-size: var(--font-size-sm); color: var(--color-text-secondary);">Выручка</div>
          <div style="font-size: var(--font-size-xl); font-weight: bold; color: var(--color-success);">+${stats.totalRevenue.toLocaleString('ru-RU')}₽</div>
        </div>
      </div>
    </div>

    <!-- Список чеков -->
    <div id="checks-list">
      ${store.receipts.map(receipt => {
        const client = store.getClientById(receipt.clientId);
        return `
          <div class="card check-card" data-receipt-id="${receipt.id}">
            <div class="check-amount">${receipt.total.toLocaleString('ru-RU')}₽</div>
            <div class="check-info">
              <div class="check-client">${client?.name || 'Гость'}</div>
              <div class="check-meta">${receipt.date} · ${receipt.tariff}</div>
            </div>
            <div class="check-arrow">›</div>
          </div>
        `;
      }).join('')}
    </div>
  `;

  // Поиск
  setTimeout(() => {
    document.getElementById('checks-search')?.addEventListener('input', (e) => {
      const q = e.target.value.toLowerCase().trim();
      document.querySelectorAll('.check-card').forEach(card => {
        const client = card.querySelector('.check-client')?.textContent.toLowerCase() || '';
        card.style.display = !q || client.includes(q) ? '' : 'none';
      });
    });
  }, 0);

  return el;
}
