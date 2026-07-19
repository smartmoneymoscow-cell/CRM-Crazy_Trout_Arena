// === SPA Router (hash-based) ===
class Router {
  constructor() {
    this.routes = new Map();
    this.currentScreen = null;
    this.container = null;
    this.onNavigate = null;
    window.addEventListener('hashchange', () => this._handleRoute());
  }
  init(containerId) { this.container = document.getElementById(containerId); }
  register(name, renderFn) { this.routes.set(name, renderFn); }
  navigate(name, params = {}) {
    const hash = params && Object.keys(params).length > 0
      ? `#${name}?${new URLSearchParams(params).toString()}`
      : `#${name}`;
    if (window.location.hash === hash) { this._handleRoute(); }
    else { window.location.hash = hash; }
  }
  _handleRoute() {
    const hash = window.location.hash.slice(1) || 'pond';
    const [name, queryString] = hash.split('?');
    const params = queryString ? Object.fromEntries(new URLSearchParams(queryString)) : {};
    if (!this.container) return;
    const renderFn = this.routes.get(name);
    if (renderFn) {
      this.currentScreen = name;
      this.container.innerHTML = '';
      const content = renderFn(params);
      if (typeof content === 'string') this.container.innerHTML = content;
      else if (content instanceof HTMLElement) this.container.appendChild(content);
      if (this.onNavigate) this.onNavigate(name);
    }
  }
  getCurrentScreen() { return this.currentScreen; }
  start() {
    if (!window.location.hash) window.location.hash = '#pond';
    this._handleRoute();
  }
}
export const router = new Router();
