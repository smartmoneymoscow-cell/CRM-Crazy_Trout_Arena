// === Telegram WebApp API Wrapper ===
class TelegramAPI {
  constructor() {
    this.webapp = window.Telegram?.WebApp;
    this.isAvailable = !!this.webapp;
    if (this.isAvailable) {
      this.webapp.ready();
      this.webapp.expand();
      this._applySafeArea();
    }
  }
  ready() { this.webapp?.ready(); }
  expand() { this.webapp?.expand(); }
  close() { this.webapp?.close(); }
  getUser() { return this.webapp?.initDataUnsafe?.user || null; }
  getInitData() { return this.webapp?.initData || ''; }
  getThemeParams() {
    if (!this.isAvailable) return {
      bg_color: '#FBF6EC', text_color: '#14130F', hint_color: '#9C9484',
      link_color: '#E8912B', button_color: '#E8912B', button_text_color: '#FFFFFF',
      secondary_bg_color: '#F3EEE4',
    };
    return this.webapp.themeParams;
  }
  setHeaderColor(color) { this.webapp?.setHeaderColor(color); }
  setBackgroundColor(color) { this.webapp?.setBackgroundColor(color); }
  showMainButton(text, onClick) {
    if (!this.isAvailable) return;
    this.webapp.MainButton.text = text;
    this.webapp.MainButton.show();
    this.webapp.MainButton.onClick(onClick);
  }
  hideMainButton() { this.webapp?.MainButton.hide(); }
  showBackButton(onClick) {
    if (!this.isAvailable) return;
    this.webapp.BackButton.show();
    this.webapp.BackButton.onClick(onClick);
  }
  hideBackButton() { this.webapp?.BackButton.hide(); }
  showScanQR(text = 'Наведите на QR-код') {
    return new Promise((resolve) => {
      if (!this.isAvailable) { resolve(null); return; }
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
  hapticImpact(style = 'medium') { this.webapp?.HapticFeedback.impactOccurred(style); }
  hapticNotification(type = 'success') { this.webapp?.HapticFeedback.notificationOccurred(type); }
  hapticSelection() { this.webapp?.HapticFeedback.selectionChanged(); }
  showPopup(title, message, buttons = []) {
    if (!this.isAvailable) { alert(`${title}\n\n${message}`); return Promise.resolve(null); }
    return this.webapp.showPopup({ title, message, buttons });
  }
  showAlert(message) {
    if (!this.isAvailable) { alert(message); return Promise.resolve(); }
    return this.webapp.showAlert(message);
  }
  showConfirm(message) {
    if (!this.isAvailable) return Promise.resolve(confirm(message));
    return this.webapp.showConfirm(message);
  }
  setStorage(key, value) {
    return new Promise((resolve) => {
      if (!this.isAvailable) { localStorage.setItem(key, typeof value === 'string' ? value : JSON.stringify(value)); resolve(true); return; }
      this.webapp.CloudStorage.setItem(key, typeof value === 'string' ? value : JSON.stringify(value), (err, result) => { resolve(err ? false : result); });
    });
  }
  getStorage(key) {
    return new Promise((resolve) => {
      if (!this.isAvailable) { resolve(localStorage.getItem(key)); return; }
      this.webapp.CloudStorage.getItem(key, (err, value) => { resolve(err ? null : value); });
    });
  }
  sendData(data) {
    if (typeof data === 'object') data = JSON.stringify(data);
    this.webapp?.sendData(data);
  }
  requestFullscreen() { this.webapp?.requestFullscreen(); }
  exitFullscreen() { this.webapp?.exitFullscreen(); }
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
export const tg = new TelegramAPI();
