// === App — точка входа, инициализация ===

import { tg } from './core/telegram.js';
import { router } from './core/router.js';
import { events } from './core/events.js';
import { store } from './core/store.js';

// Импорт экранов
import { renderReceipt } from './screens/receipt.js';
import { renderChecks } from './screens/checks.js';
import { renderPondMap } from './screens/pond-map.js';
import { renderReport } from './screens/report.js';
import { renderProfile } from './screens/profile.js';

// Импорт виджетов
import { initNavBar } from './widgets/nav-bar.js';

// --- Инициализация ---
document.addEventListener('DOMContentLoaded', () => {
  // Регистрация экранов
  router.register('receipt', renderReceipt);
  router.register('checks', renderChecks);
  router.register('pond', renderPondMap);
  router.register('report', renderReport);
  router.register('profile', renderProfile);

  // Контейнер
  router.init('screen-container');

  // Навигация
  initNavBar('nav-bar');

  // Обновление навигации при смене экрана
  router.onNavigate = (screenName) => {
    events.emit('navigate', screenName);
  };

  // Скрываем splash, показываем app
  setTimeout(() => {
    const splash = document.getElementById('splash');
    const app = document.getElementById('app');
    
    splash.classList.add('fade-out');
    app.classList.remove('hidden');
    
    setTimeout(() => splash.remove(), 300);
    
    // Запуск роутера
    router.start();
  }, 800);

  // Telegram: цвета из темы
  if (tg.isAvailable) {
    const params = tg.getThemeParams();
    if (params.bg_color) {
      document.documentElement.style.setProperty('--color-bg-primary', params.bg_color);
    }
    if (params.secondary_bg_color) {
      document.documentElement.style.setProperty('--color-bg-secondary', params.secondary_bg_color);
    }
  }
});
