// === Nav Bar — нижняя навигация (5 вкладок) ===

import { router } from '../core/router.js';
import { events } from '../core/events.js';
import { tg } from '../core/telegram.js';

const TABS = [
  { id: 'receipt', icon: '🧾', label: 'Чек' },
  { id: 'checks',  icon: '📋', label: 'Чеки' },
  { id: 'pond',    icon: '🗺️', label: 'Пруд' },
  { id: 'report',  icon: '📊', label: 'Отчёт' },
  { id: 'profile', icon: '👤', label: 'Профиль' },
];

let navContainer = null;
let activeTab = 'receipt';

function renderNav() {
  if (!navContainer) return;

  navContainer.innerHTML = TABS.map(tab => `
    <button class="nav-item ${tab.id === activeTab ? 'active' : ''}" data-tab="${tab.id}">
      <span class="nav-icon">${tab.icon}</span>
      <span class="nav-label">${tab.label}</span>
    </button>
  `).join('');

  // Обработчики
  navContainer.querySelectorAll('.nav-item').forEach(btn => {
    btn.addEventListener('click', () => {
      const tabId = btn.dataset.tab;
      if (tabId !== activeTab) {
        activeTab = tabId;
        router.navigate(tabId);
        tg.hapticSelection();
        renderNav();
      }
    });
  });
}

export function initNavBar(containerId) {
  navContainer = document.getElementById(containerId);
  renderNav();

  // Слушаем навигацию (назад/вперёд)
  events.on('navigate', (screenName) => {
    if (TABS.find(t => t.id === screenName)) {
      activeTab = screenName;
      renderNav();
    }
  });
}
