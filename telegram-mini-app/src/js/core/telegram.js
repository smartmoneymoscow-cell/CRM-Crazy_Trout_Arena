// === Telegram WebApp API Wrapper ===
// Обёртка над Telegram WebApp SDK с fallback для тестирования вне Telegram

class TelegramAPI {
  constructor() {
    this.webapp = window.Telegram?.WebApp;
    this.isAvailable = !!this.webapp;
    
    if (this.isAvailable) {
      // Инициализация
      this.webapp.ready();
      this.webapp.expand();
      
      // Safe area
      this._applySafeArea();
    }
  }

  // --- Инициализация ---
  
  ready() {
    this.webapp?.ready();
  }

  expand() {
    this.webapp?.expand();
  }

  close() {
    this.webapp?.close();
  }

  // --- Пользователь ---
  
  getUser() {
    return this.webapp?.initDataUnsafe?.user || null;
  }

  getInitData() {
    return this.webapp?.initData || '';
  }

  // --- Тема ---
  
  getThemeParams() {
    if (!this.isAvailable) {
      return {
        bg_color: '#FBF6EC',
        text_color: '#2D2D2D',
        hint_color: '#8E8E8E',
        link_color: '#E8912B',
        button_color: '#E8912B',
        button_text_color: '#FFFFFF',
        secondary_bg_color: '#F3EEE4',
      };
    }
    return this.webapp.themeParams;
  }

  setHeaderColor(color) {
    this.webapp?.setHeaderColor(color);
  }

  setBackgroundColor(color) {
    this.webapp?.setBackgroundColor(color);
  }

  // --- Кнопки ---
  
  showMainButton(text, onClick) {
    if (!this.isAvailable) return;
    this.webapp.MainButton.text = text;
    this.webapp.MainButton.show();
    this.webapp.MainButton.onClick(onClick);
  }

  hideMainButton() {
    this.webapp?.MainButton.hide();
  }

  showSecondaryButton(text, onClick) {
    if (!this.isAvailable) return;
    this.webapp.SecondaryButton.text = text;
    this.webapp.SecondaryButton.show();
    this.webapp.SecondaryButton.onClick(onClick);
  }

  hideSecondaryButton() {
    this.webapp?.SecondaryButton.hide();
  }

  showBackButton(onClick) {
    if (!this.isAvailable) return;
    this.webapp.BackButton.show();
    this.webapp.BackButton.onClick(onClick);
  }

  hideBackButton() {
    this.webapp?.BackButton.hide();
  }

  // --- QR-сканер (нативный) ---
  
  showScanQR(text = 'Наведите на QR-код') {
    return new Promise((resolve) => {
      if (!this.isAvailable) {
        resolve(null);
        return;
      }

      this.webapp.showScanQrPopup({ text });

      const onQR = (event) => {
        this.webapp.offEvent('qrTextReceived', onQR);
        this.webapp.closeScanQrPopup();
        this.webapp.HapticFeedback.notificationOccurred('success');
        resolve(event.data);
      };

      const onClose = () => {
        this.webapp.offEvent('scanQrPopupClosed', onClose);
        this.webapp.offEvent('qrTextReceived', onQR);
        resolve(null);
      };

      this.webapp.onEvent('qrTextReceived', onQR);
      this.webapp.onEvent('scanQrPopupClosed', onClose);
    });
  }

  // --- HapticFeedback ---
  
  hapticImpact(style = 'medium') {
    this.webapp?.HapticFeedback.impactOccurred(style); // light | medium | heavy | rigid | soft
  }

  hapticNotification(type = 'success') {
    this.webapp?.HapticFeedback.notificationOccurred(type); // success | error | warning
  }

  hapticSelection() {
    this.webapp?.HapticFeedback.selectionChanged();
  }

  // --- Popup / Alert ---
  
  showPopup(title, message, buttons = []) {
    if (!this.isAvailable) {
      alert(`${title}\n\n${message}`);
      return Promise.resolve(null);
    }
    return this.webapp.showPopup({ title, message, buttons });
  }

  showAlert(message) {
    if (!this.isAvailable) {
      alert(message);
      return Promise.resolve();
    }
    return this.webapp.showAlert(message);
  }

  showConfirm(message) {
    if (!this.isAvailable) {
      return Promise.resolve(confirm(message));
    }
    return this.webapp.showConfirm(message);
  }

  // --- CloudStorage ---
  
  setStorage(key, value) {
    return new Promise((resolve) => {
      if (!this.isAvailable) {
        localStorage.setItem(key, typeof value === 'string' ? value : JSON.stringify(value));
        resolve(true);
        return;
      }
      this.webapp.CloudStorage.setItem(key, typeof value === 'string' ? value : JSON.stringify(value), (err, result) => {
        resolve(err ? false : result);
      });
    });
  }

  getStorage(key) {
    return new Promise((resolve) => {
      if (!this.isAvailable) {
        resolve(localStorage.getItem(key));
        return;
      }
      this.webapp.CloudStorage.getItem(key, (err, value) => {
        resolve(err ? null : value);
      });
    });
  }

  removeStorage(key) {
    return new Promise((resolve) => {
      if (!this.isAvailable) {
        localStorage.removeItem(key);
        resolve(true);
        return;
      }
      this.webapp.CloudStorage.removeItem(key, (err, result) => {
        resolve(err ? false : result);
      });
    });
  }

  // --- Поделиться ---
  
  shareMessage(text) {
    if (!this.isAvailable) {
      // Fallback — копировать в буфер
      navigator.clipboard?.writeText(text);
      return;
    }
    this.webapp.switchInlineQuery(text);
  }

  // --- Данные ---
  
  sendData(data) {
    if (typeof data === 'object') {
      data = JSON.stringify(data);
    }
    this.webapp?.sendData(data);
  }

  // --- Полный экран ---
  
  requestFullscreen() {
    this.webapp?.requestFullscreen();
  }

  exitFullscreen() {
    this.webapp?.exitFullscreen();
  }

  // --- Safe Area ---
  
  _applySafeArea() {
    if (!this.webapp?.safeAreaInset) return;
    const { top, bottom, left, right } = this.webapp.safeAreaInset;
    const root = document.documentElement;
    root.style.setProperty('--safe-top', `${top}px`);
    root.style.setProperty('--safe-bottom', `${bottom}px`);
    root.style.setProperty('--safe-left', `${left}px`);
    root.style.setProperty('--safe-right', `${right}px`);
  }
}

// Синглтон
export const tg = new TelegramAPI();
