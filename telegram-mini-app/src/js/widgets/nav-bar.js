// === Nav Bar — нижняя навигация (точь-в-точь Flutter HomeShell) ===
import { router } from '../core/router.js';
import { events } from '../core/events.js';
import { tg } from '../core/telegram.js';

// Material Design outlined icons (точные SVG paths из Google Material Icons)
const ICONS = {
  // Icons.map_outlined
  map: '<svg width="24" height="24" viewBox="0 0 24 24"><path d="M20.5 3l-.16.03L15 5.1 9 3 3.36 4.9c-.21.07-.36.25-.36.48V20.5c0 .28.22.5.5.5l.16-.03L9 18.9l6 2.1 5.64-1.9c.21-.07.36-.25.36-.48V3.5c0-.28-.22-.5-.5-.5zM15 19l-6-2.11V5l6 2.11V19z" fill="currentColor"/></svg>',
  // Icons.receipt_outlined
  receipt: '<svg width="24" height="24" viewBox="0 0 24 24"><path d="M18 17H6v-2h12v2zm0-4H6v-2h12v2zm0-4H6V7h12v2zM3 22l1.5-1.5L6 22l1.5-1.5L9 22l1.5-1.5L12 22l1.5-1.5L15 22l1.5-1.5L18 22l1.5-1.5L21 22V2l-1.5 1.5L18 2l-1.5 1.5L15 2l-1.5 1.5L12 2l-1.5 1.5L9 2 7.5 3.5 6 2 4.5 3.5 3 2v20z" fill="currentColor"/></svg>',
  // Icons.receipt_long_outlined
  receiptLong: '<svg width="24" height="24" viewBox="0 0 24 24"><path d="M19.5 3.5L18 2l-1.5 1.5L15 2l-1.5 1.5L12 2l-1.5 1.5L9 2 7.5 3.5 6 2 4.5 3.5 3 2v20l1.5-1.5L6 22l1.5-1.5L9 22l1.5-1.5L12 22l1.5-1.5L15 22l1.5-1.5L18 22l1.5-1.5L21 22V2l-1.5 1.5zM19 19.09H5V4.91h14v14.18zM6 15h12v2H6zm0-4h12v2H6zm0-4h12v2H6z" fill="currentColor"/></svg>',
  // Icons.show_chart
  chart: '<svg width="24" height="24" viewBox="0 0 24 24"><path d="M3.5 18.49l6-6.01 4 4L22 6.92l-1.41-1.41-7.09 7.97-4-4L2 16.99z" fill="currentColor"/></svg>',
  // Icons.person_outline
  person: '<svg width="24" height="24" viewBox="0 0 24 24"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4zm0-6c1.1 0 2 .9 2 2s-.9 2-2 2-2-.9-2-2 .9-2 2-2zm0 8.55c2.25.39 4.58.97 5.73 1.45H6.27c1.15-.48 3.48-1.06 5.73-1.45zM12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z" fill="currentColor"/></svg>',
};

const TABS = [
  { id: 'pond',    icon: ICONS.map,        label: 'Карта' },
  { id: 'receipt', icon: ICONS.receipt,     label: 'Чек' },
  { id: 'checks',  icon: ICONS.receiptLong, label: 'Чеки' },
  { id: 'report',  icon: ICONS.chart,       label: 'Отчёты' },
  { id: 'profile', icon: ICONS.person,      label: 'Профиль' },
];

let navContainer = null;
let activeTab = 'pond';

function renderNav() {
  if (!navContainer) return;
  navContainer.innerHTML = TABS.map(tab => `
    <button class="nav-item ${tab.id === activeTab ? 'active' : ''}" data-tab="${tab.id}">
      <span class="nav-icon">${tab.icon}</span>
      <span class="nav-label">${tab.label}</span>
    </button>
  `).join('');

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
  events.on('navigate', (screenName) => {
    if (TABS.find(t => t.id === screenName)) {
      activeTab = screenName;
      renderNav();
    }
  });
}
