// === QR Scanner Service ===
// Стратегия: Telegram native → getUserMedia + jsQR → <input capture>

import { tg } from '../core/telegram.js';

class QRScanner {
  constructor() {
    this.stream = null;
    this.videoElement = null;
    this.canvasElement = null;
    this.canvasContext = null;
    this.scanning = false;
    this.scanInterval = null;
  }

  // --- Основной метод: сканирование QR ---
  
  async scan(preferredMethod = 'auto') {
    // Метод 1: Telegram нативный сканер (самый надёжный)
    if (preferredMethod === 'auto' || preferredMethod === 'telegram') {
      const result = await this._scanTelegram();
      if (result) return result;
      if (preferredMethod === 'telegram') return null;
    }

    // Метод 2: getUserMedia + jsQR (live stream)
    if (preferredMethod === 'auto' || preferredMethod === 'camera') {
      const result = await this._scanCamera();
      if (result) return result;
      if (preferredMethod === 'camera') return null;
    }

    // Метод 3: <input capture> (нативный UI камеры)
    if (preferredMethod === 'auto' || preferredMethod === 'input') {
      return await this._scanInput();
    }

    return null;
  }

  // --- Метод 1: Telegram нативный QR ---
  
  async _scanTelegram() {
    try {
      return await tg.showScanQR('Наведите на QR-код клиента');
    } catch (e) {
      console.warn('Telegram QR scanner unavailable:', e);
      return null;
    }
  }

  // --- Метод 2: getUserMedia + jsQR ---
  
  async _scanCamera() {
    try {
      // Проверяем доступность камеры
      if (!navigator.mediaDevices?.getUserMedia) {
        return null;
      }

      // Запрашиваем камеру (с кешированием стрима)
      this.stream = await this._getCameraStream();
      if (!this.stream) return null;

      // Создаём UI
      const { overlay, video, canvas } = this._createScannerUI();
      document.body.appendChild(overlay);

      video.srcObject = this.stream;
      await video.play();

      this.canvasElement = canvas;
      this.canvasContext = canvas.getContext('2d', { willReadFrequently: true });
      this.videoElement = video;
      this.scanning = true;

      // Сканирование
      return new Promise((resolve) => {
        const onResult = (data) => {
          this._cleanup();
          overlay.remove();
          tg.hapticNotification('success');
          resolve(data);
        };

        const onCancel = () => {
          this._cleanup();
          overlay.remove();
          resolve(null);
        };

        // Кнопка отмены
        overlay.querySelector('.qr-cancel')?.addEventListener('click', onCancel);
        overlay.querySelector('.qr-overlay')?.addEventListener('click', (e) => {
          if (e.target === overlay.querySelector('.qr-overlay')) onCancel();
        });

        // Периодическое сканирование кадров
        this.scanInterval = setInterval(() => {
          if (!this.scanning) return;
          
          const result = this._scanFrame(video, canvas);
          if (result) {
            onResult(result);
          }
        }, 200); // 5 fps

        // Таймаут 60 секунд
        setTimeout(() => {
          if (this.scanning) onCancel();
        }, 60000);
      });

    } catch (e) {
      console.warn('Camera QR scan failed:', e);
      this._cleanup();
      return null;
    }
  }

  _getCameraStream() {
    // Кеширование стрима — один запрос разрешений
    if (this.stream && this.stream.active) {
      return Promise.resolve(this.stream);
    }

    return navigator.mediaDevices.getUserMedia({
      video: { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } },
      audio: false
    }).then(stream => {
      this.stream = stream;
      
      // Слушаем обрыв
      stream.getTracks().forEach(track => {
        track.onended = () => {
          this.stream = null;
        };
      });
      
      return stream;
    }).catch(e => {
      if (e.name === 'NotAllowedError') {
        tg.showAlert('Для сканирования QR-кода разрешите доступ к камере');
      }
      return null;
    });
  }

  _scanFrame(video, canvas) {
    if (!video.videoWidth || !video.videoHeight) return null;

    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    this.canvasContext.drawImage(video, 0, 0);

    const imageData = this.canvasContext.getImageData(0, 0, canvas.width, canvas.height);

    // jsQR — глобальная (загружена через CDN) или динамический импорт
    if (typeof jsQR !== 'undefined') {
      const code = jsQR(imageData.data, imageData.width, imageData.height, {
        inversionAttempts: 'dontInvert'
      });
      if (code) return code.data;
    }

    return null;
  }

  _createScannerUI() {
    const overlay = document.createElement('div');
    overlay.className = 'qr-overlay';
    overlay.innerHTML = `
      <div class="qr-scanner-container">
        <div class="qr-scanner-frame">
          <div class="qr-corner qr-corner-tl"></div>
          <div class="qr-corner qr-corner-tr"></div>
          <div class="qr-corner qr-corner-bl"></div>
          <div class="qr-corner qr-corner-br"></div>
          <div class="qr-scan-line"></div>
        </div>
        <div class="qr-hint">Наведите камеру на QR-код</div>
        <button class="qr-cancel btn btn-secondary">Отмена</button>
        <video class="qr-video" playsinline autoplay muted></video>
        <canvas class="qr-canvas" style="display:none;"></canvas>
      </div>
    `;

    // Стили
    if (!document.getElementById('qr-scanner-styles')) {
      const style = document.createElement('style');
      style.id = 'qr-scanner-styles';
      style.textContent = `
        .qr-overlay {
          position: fixed;
          inset: 0;
          background: rgba(0,0,0,0.9);
          z-index: 9999;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .qr-scanner-container {
          position: relative;
          width: 100%;
          height: 100%;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
        }
        .qr-video {
          position: absolute;
          inset: 0;
          width: 100%;
          height: 100%;
          object-fit: cover;
        }
        .qr-scanner-frame {
          position: relative;
          width: 250px;
          height: 250px;
          z-index: 2;
        }
        .qr-corner {
          position: absolute;
          width: 30px;
          height: 30px;
          border: 3px solid #E8912B;
        }
        .qr-corner-tl { top: 0; left: 0; border-right: none; border-bottom: none; border-radius: 8px 0 0 0; }
        .qr-corner-tr { top: 0; right: 0; border-left: none; border-bottom: none; border-radius: 0 8px 0 0; }
        .qr-corner-bl { bottom: 0; left: 0; border-right: none; border-top: none; border-radius: 0 0 0 8px; }
        .qr-corner-br { bottom: 0; right: 0; border-left: none; border-top: none; border-radius: 0 0 8px 0; }
        .qr-scan-line {
          position: absolute;
          top: 0;
          left: 10%;
          width: 80%;
          height: 2px;
          background: #E8912B;
          box-shadow: 0 0 8px rgba(232,145,43,0.6);
          animation: qr-scan 2s ease-in-out infinite;
        }
        @keyframes qr-scan {
          0%, 100% { top: 10%; }
          50% { top: 90%; }
        }
        .qr-hint {
          position: relative;
          z-index: 2;
          color: white;
          font-size: 15px;
          margin-top: 32px;
          text-shadow: 0 1px 4px rgba(0,0,0,0.5);
        }
        .qr-cancel {
          position: relative;
          z-index: 2;
          margin-top: 24px;
          color: white;
          background: rgba(255,255,255,0.2);
          border: 1px solid rgba(255,255,255,0.3);
        }
      `;
      document.head.appendChild(style);
    }

    return {
      overlay,
      video: overlay.querySelector('.qr-video'),
      canvas: overlay.querySelector('.qr-canvas')
    };
  }

  // --- Метод 3: <input capture> (нативный UI камеры) ---
  
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

        if (!file) {
          resolve(null);
          return;
        }

        try {
          const result = await this._decodeQRFromFile(file);
          if (result) {
            tg.hapticNotification('success');
          }
          resolve(result);
        } catch (err) {
          console.warn('QR decode from file failed:', err);
          resolve(null);
        }
      };

      // Если пользователь закрыл диалог без выбора файла
      setTimeout(() => {
        if (document.body.contains(input)) {
          document.body.removeChild(input);
          resolve(null);
        }
      }, 120000);

      input.click();
    });
  }

  _decodeQRFromFile(file) {
    return new Promise((resolve, reject) => {
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
            resolve(code ? code.data : null);
          } else {
            reject(new Error('jsQR not loaded'));
          }
        };
        img.onerror = reject;
        img.src = reader.result;
      };
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }

  // --- Очистка ---
  
  _cleanup() {
    this.scanning = false;
    if (this.scanInterval) {
      clearInterval(this.scanInterval);
      this.scanInterval = null;
    }
    // НЕ останавливаем stream — кешируем для повторного использования
  }

  destroy() {
    this._cleanup();
    if (this.stream) {
      this.stream.getTracks().forEach(t => t.stop());
      this.stream = null;
    }
  }
}

export const qrScanner = new QRScanner();
