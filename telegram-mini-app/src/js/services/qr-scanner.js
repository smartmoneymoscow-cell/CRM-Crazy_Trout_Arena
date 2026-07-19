// === QR Scanner Service ===
import { tg } from '../core/telegram.js';

class QRScanner {
  constructor() {
    this.stream = null;
    this.scanning = false;
    this.scanInterval = null;
  }

  async scan(preferredMethod = 'auto') {
    if (preferredMethod === 'auto' || preferredMethod === 'telegram') {
      const result = await this._scanTelegram();
      if (result) return result;
      if (preferredMethod === 'telegram') return null;
    }
    if (preferredMethod === 'auto' || preferredMethod === 'camera') {
      const result = await this._scanCamera();
      if (result) return result;
      if (preferredMethod === 'camera') return null;
    }
    if (preferredMethod === 'auto' || preferredMethod === 'input') {
      return await this._scanInput();
    }
    return null;
  }

  async _scanTelegram() {
    try { return await tg.showScanQR('Наведите на QR-код клиента'); }
    catch (e) { return null; }
  }

  async _scanCamera() {
    try {
      if (!navigator.mediaDevices?.getUserMedia) return null;
      this.stream = await this._getCameraStream();
      if (!this.stream) return null;

      const { overlay, video, canvas } = this._createScannerUI();
      document.body.appendChild(overlay);
      video.srcObject = this.stream;
      await video.play();

      const ctx = canvas.getContext('2d', { willReadFrequently: true });
      this.scanning = true;

      return new Promise((resolve) => {
        const cleanup = () => {
          this.scanning = false;
          if (this.scanInterval) { clearInterval(this.scanInterval); this.scanInterval = null; }
          overlay.remove();
        };

        overlay.querySelector('.qr-cancel')?.addEventListener('click', () => { cleanup(); resolve(null); });

        this.scanInterval = setInterval(() => {
          if (!this.scanning || !video.videoWidth) return;
          canvas.width = video.videoWidth;
          canvas.height = video.videoHeight;
          ctx.drawImage(video, 0, 0);
          const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
          if (typeof jsQR !== 'undefined') {
            const code = jsQR(imageData.data, imageData.width, imageData.height, { inversionAttempts: 'dontInvert' });
            if (code) { cleanup(); tg.hapticNotification('success'); resolve(code.data); }
          }
        }, 200);

        setTimeout(() => { if (this.scanning) { cleanup(); resolve(null); } }, 60000);
      });
    } catch (e) { this._cleanup(); return null; }
  }

  _getCameraStream() {
    if (this.stream && this.stream.active) return Promise.resolve(this.stream);
    return navigator.mediaDevices.getUserMedia({
      video: { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } },
      audio: false
    }).then(stream => {
      this.stream = stream;
      stream.getTracks().forEach(track => { track.onended = () => { this.stream = null; }; });
      return stream;
    }).catch(e => {
      if (e.name === 'NotAllowedError') tg.showAlert('Для сканирования QR-кода разрешите доступ к камере');
      return null;
    });
  }

  async _scanInput() {
    return new Promise((resolve) => {
      const input = document.createElement('input');
      input.type = 'file';
      input.accept = 'image/*';
      input.capture = 'environment';
      input.style.display = 'none';
      document.body.appendChild(input);
      input.onchange = async (e) => {
        const file = e.target.files?.[0];
        document.body.removeChild(input);
        if (!file) { resolve(null); return; }
        try {
          const reader = new FileReader();
          reader.onload = () => {
            const img = new Image();
            img.onload = () => {
              const canvas = document.createElement('canvas');
              canvas.width = img.width;
              canvas.height = img.height;
              const ctx = canvas.getContext('2d');
              ctx.drawImage(img, 0, 0);
              const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
              if (typeof jsQR !== 'undefined') {
                const code = jsQR(imageData.data, imageData.width, imageData.height);
                if (code) { tg.hapticNotification('success'); resolve(code.data); }
                else resolve(null);
              } else resolve(null);
            };
            img.src = reader.result;
          };
          reader.readAsDataURL(file);
        } catch (err) { resolve(null); }
      };
      input.click();
    });
  }

  _createScannerUI() {
    const overlay = document.createElement('div');
    overlay.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,0.9);z-index:9999;display:flex;flex-direction:column;align-items:center;justify-content:center;';
    overlay.innerHTML = `
      <video style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover;" playsinline autoplay muted></video>
      <div style="position:relative;width:250px;height:250px;z-index:2;">
        <div style="position:absolute;top:0;left:0;width:30px;height:30px;border:3px solid #E8912B;border-right:none;border-bottom:none;border-radius:8px 0 0 0;"></div>
        <div style="position:absolute;top:0;right:0;width:30px;height:30px;border:3px solid #E8912B;border-left:none;border-bottom:none;border-radius:0 8px 0 0;"></div>
        <div style="position:absolute;bottom:0;left:0;width:30px;height:30px;border:3px solid #E8912B;border-right:none;border-top:none;border-radius:0 0 0 8px;"></div>
        <div style="position:absolute;bottom:0;right:0;width:30px;height:30px;border:3px solid #E8912B;border-left:none;border-top:none;border-radius:0 0 8px 0;"></div>
        <div style="position:absolute;top:0;left:10%;width:80%;height:2px;background:#E8912B;box-shadow:0 0 8px rgba(232,145,43,0.6);animation:qr-scan 2s ease-in-out infinite;"></div>
      </div>
      <div style="position:relative;z-index:2;color:white;font-size:15px;margin-top:32px;text-shadow:0 1px 4px rgba(0,0,0,0.5);">Наведите камеру на QR-код</div>
      <button class="qr-cancel" style="position:relative;z-index:2;margin-top:24px;color:white;background:rgba(255,255,255,0.2);border:1px solid rgba(255,255,255,0.3);border-radius:10px;padding:10px 20px;font-size:14px;cursor:pointer;">Отмена</button>
      <canvas style="display:none;"></canvas>
    `;
    return {
      overlay,
      video: overlay.querySelector('video'),
      canvas: overlay.querySelector('canvas'),
    };
  }

  _cleanup() {
    this.scanning = false;
    if (this.scanInterval) { clearInterval(this.scanInterval); this.scanInterval = null; }
  }

  destroy() {
    this._cleanup();
    if (this.stream) { this.stream.getTracks().forEach(t => t.stop()); this.stream = null; }
  }
}

export const qrScanner = new QRScanner();
