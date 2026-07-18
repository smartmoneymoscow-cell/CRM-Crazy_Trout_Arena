// === Screen: Профиль ===

import { store } from '../core/store.js';
import { tg } from '../core/telegram.js';

export function renderProfile() {
  // Демо-профиль (в реальности — из Telegram user data)
  const user = tg.getUser();
  const displayName = user ? `${user.first_name} ${user.last_name || ''}`.trim() : 'Администратор';
  const initials = displayName.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2);

  const stats = store.getStats();
  const totalClients = store.clients.length;
  const occupiedSectors = store.sectors.filter(s => s.occupied).length;

  const el = document.createElement('div');
  el.className = 'screen screen-profile';
  el.innerHTML = `
    <div class="profile-header">
      <div class="profile-avatar">
        ${user?.photo_url 
          ? `<img src="${user.photo_url}" alt="${displayName}">` 
          : initials}
      </div>
      <div class="profile-name">${displayName}</div>
      <div class="profile-level">
        <span class="badge badge-accent">Администратор</span>
      </div>
    </div>

    <!-- Статистика -->
    <div class="profile-stats">
      <div class="stat-item">
        <div class="stat-value">${stats.totalReceipts}</div>
        <div class="stat-label">Чеков</div>
      </div>
      <div class="stat-item">
        <div class="stat-value">${totalClients}</div>
        <div class="stat-label">Клиентов</div>
      </div>
      <div class="stat-item">
        <div class="stat-value">${occupiedSectors}/16</div>
        <div class="stat-label">Секторов</div>
      </div>
    </div>

    <div class="divider" style="margin: var(--spacing-xxl) 0;"></div>

    <!-- Меню -->
    <div class="card" style="margin-bottom: var(--spacing-md); cursor: pointer;" id="btn-settings">
      <div style="display: flex; align-items: center; gap: var(--spacing-md);">
        <span>⚙️</span>
        <div style="flex: 1;">Настройки</div>
        <span style="color: var(--color-text-secondary);">›</span>
      </div>
    </div>

    <div class="card" style="margin-bottom: var(--spacing-md); cursor: pointer;" id="btn-printers">
      <div style="display: flex; align-items: center; gap: var(--spacing-md);">
        <span>🖨️</span>
        <div style="flex: 1;">Принтеры</div>
        <span style="color: var(--color-text-secondary);">›</span>
      </div>
    </div>

    <div class="card" style="margin-bottom: var(--spacing-md); cursor: pointer;" id="btn-about">
      <div style="display: flex; align-items: center; gap: var(--spacing-md);">
        <span>ℹ️</span>
        <div style="flex: 1;">О приложении</div>
        <span style="color: var(--color-text-secondary);">›</span>
      </div>
    </div>

    <!-- Версия -->
    <div style="text-align: center; color: var(--color-text-secondary); font-size: var(--font-size-xs); margin-top: var(--spacing-xl);">
      Crazy Trout Arena CRM · Mini App v0.1.0
    </div>
  `;

  // Обработчики
  setTimeout(() => {
    document.getElementById('btn-about')?.addEventListener('click', () => {
      tg.showPopup('О приложении', 'Crazy Trout Arena CRM\nTelegram Mini App v0.1.0\n\n🐟 Пруд платной рыбалки', [{ type: 'ok' }]);
    });
  }, 0);

  return el;
}
