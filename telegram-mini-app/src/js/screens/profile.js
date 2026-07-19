// === Screen: Профиль ===
import { store } from '../core/store.js';
import { tg } from '../core/telegram.js';

export function renderProfile() {
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
        ${user?.photo_url ? `<img src="${user.photo_url}" alt="${displayName}" style="width:100%;height:100%;object-fit:cover;">` : initials}
      </div>
      <div class="profile-name">${displayName}</div>
      <div class="profile-level">
        <span class="chip selected" style="font-size:11px;padding:4px 10px;">Администратор</span>
      </div>
    </div>

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

    <div class="divider" style="margin:24px 0;"></div>

    <div class="card menu-card" id="btn-settings">
      <span>⚙️</span>
      <div style="flex:1;">Настройки</div>
      <span class="menu-arrow">›</span>
    </div>

    <div class="card menu-card" id="btn-printers">
      <span>🖨️</span>
      <div style="flex:1;">Принтеры</div>
      <span class="menu-arrow">›</span>
    </div>

    <div class="card menu-card" id="btn-about">
      <span>ℹ️</span>
      <div style="flex:1;">О приложении</div>
      <span class="menu-arrow">›</span>
    </div>

    <div style="text-align:center;color:var(--kMuted2);font-size:10px;margin-top:20px;">
      Crazy Trout Arena CRM · Mini App v0.1.0
    </div>
  `;

  setTimeout(() => {
    document.getElementById('btn-about')?.addEventListener('click', () => {
      tg.showPopup('О приложении', 'Crazy Trout Arena CRM\nTelegram Mini App v0.1.0\n\n🐟 Пруд платной рыбалки', [{ type: 'ok' }]);
    });
  }, 0);
  return el;
}
