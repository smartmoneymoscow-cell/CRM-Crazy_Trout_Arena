// === Screen: Карта пруда (16 секторов) ===

import { store } from '../core/store.js';
import { tg } from '../core/telegram.js';

export function renderPondMap() {
  const el = document.createElement('div');
  el.className = 'screen screen-pond';
  el.innerHTML = `
    <h2 style="margin-bottom: var(--spacing-md); font-size: var(--font-size-xl);">🗺️ Карта пруда</h2>
    <p style="color: var(--color-text-secondary); margin-bottom: var(--spacing-xl); font-size: var(--font-size-sm);">
      16 секторов · ${store.sectors.filter(s => s.occupied).length} занято
    </p>

    <!-- Карта секторов -->
    <div class="pond-map" id="pond-map">
      ${store.sectors.map(sector => {
        const client = sector.occupied ? store.getClientById(sector.clientId) : null;
        return `
          <div class="sector-cell ${sector.occupied ? 'occupied' : ''}" 
               data-sector="${sector.id}" 
               data-client-id="${sector.clientId || ''}">
            <div class="sector-number">${sector.id}</div>
            <div class="sector-status">
              ${sector.occupied 
                ? (client ? store.getClientInitials(client) : '👤') 
                : 'Свободен'}
            </div>
          </div>
        `;
      }).join('')}
    </div>

    <!-- Легенда -->
    <div style="display: flex; gap: var(--spacing-lg); margin-bottom: var(--spacing-xl); font-size: var(--font-size-sm);">
      <div style="display: flex; align-items: center; gap: var(--spacing-xs);">
        <div style="width: 12px; height: 12px; border-radius: 3px; background: var(--color-bg-secondary);"></div>
        <span style="color: var(--color-text-secondary);">Свободен</span>
      </div>
      <div style="display: flex; align-items: center; gap: var(--spacing-xs);">
        <div style="width: 12px; height: 12px; border-radius: 3px; background: var(--color-accent-light); border: 1px solid var(--color-accent);"></div>
        <span style="color: var(--color-text-secondary);">Занят</span>
      </div>
    </div>

    <!-- Детали выбранного сектора -->
    <div id="sector-details" class="card hidden"></div>
  `;

  // Клик по сектору
  setTimeout(() => {
    document.getElementById('pond-map')?.addEventListener('click', (e) => {
      const cell = e.target.closest('.sector-cell');
      if (!cell) return;
      
      // Подсветка
      document.querySelectorAll('.sector-cell').forEach(c => c.classList.remove('selected'));
      cell.classList.add('selected');
      tg.hapticImpact('light');

      const sectorId = cell.dataset.sector;
      const clientId = cell.dataset.clientId;
      const client = clientId ? store.getClientById(clientId) : null;
      const details = document.getElementById('sector-details');

      if (details) {
        details.classList.remove('hidden');
        if (client) {
          const ltv = store.getClientLTV(client.id);
          const avgCatch = store.getClientAvgCatch(client.id);
          details.innerHTML = `
            <div class="card-header">
              <div class="card-title">Сектор ${sectorId}</div>
              <span class="badge badge-accent">${store.getLevelBadge(client.level)}</span>
            </div>
            <div style="display: flex; align-items: center; gap: var(--spacing-md); margin-bottom: var(--spacing-md);">
              <div class="client-avatar" style="width:40px;height:40px;border-radius:50%;background:var(--color-accent-light);display:flex;align-items:center;justify-content:center;font-weight:bold;color:var(--color-accent);">
                ${store.getClientInitials(client)}
              </div>
              <div>
                <div style="font-weight: bold;">${client.name}</div>
                <div style="font-size: var(--font-size-sm); color: var(--color-text-secondary);">${client.phone}</div>
              </div>
            </div>
            <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: var(--spacing-sm); text-align: center;">
              <div>
                <div style="font-size: var(--font-size-lg); font-weight: bold; color: var(--color-accent);">${client.visits}</div>
                <div style="font-size: var(--font-size-xs); color: var(--color-text-secondary);">Посещений</div>
              </div>
              <div>
                <div style="font-size: var(--font-size-lg); font-weight: bold; color: var(--color-accent);">${ltv.toLocaleString('ru-RU')}₽</div>
                <div style="font-size: var(--font-size-xs); color: var(--color-text-secondary);">LTV</div>
              </div>
              <div>
                <div style="font-size: var(--font-size-lg); font-weight: bold; color: var(--color-accent);">${avgCatch.kg}кг</div>
                <div style="font-size: var(--font-size-xs); color: var(--color-text-secondary);">Ср. улов</div>
              </div>
            </div>
          `;
        } else {
          details.innerHTML = `
            <div class="card-header">
              <div class="card-title">Сектор ${sectorId}</div>
              <span class="badge badge-success">Свободен</span>
            </div>
            <p style="color: var(--color-text-secondary); font-size: var(--font-size-sm);">
              Сектор пуст. Назначить клиента можно через экран Чек.
            </p>
          `;
        }
      }
    });
  }, 0);

  return el;
}
