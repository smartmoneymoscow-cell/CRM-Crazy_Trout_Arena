// === Camera Service ===
// Управление камерой с кешированием стрима

import { tg } from '../core/telegram.js';

class CameraService {
  constructor() {
    this.stream = null;
    this.permissionGranted = false;
  }

  // --- Получить стрим камеры (с кешированием) ---
  
  async getStream(facingMode = 'environment') {
    // Возвращаем кешированный стрим
    if (this.stream && this.stream.active) {
      return this.stream;
    }

    try {
      if (!navigator.mediaDevices?.getUserMedia) {
        return null;
      }

      this.stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode, width: { ideal: 1280 }, height: { ideal: 720 } },
        audio: false
      });

      this.permissionGranted = true;

      // Слушаем обрыв
      this.stream.getTracks().forEach(track => {
        track.onended = () => {
          console.warn('Camera track ended');
          this.stream = null;
        };
      });

      return this.stream;

    } catch (e) {
      if (e.name === 'NotAllowedError') {
        tg.showAlert('Для работы с камерой разрешите доступ в настройках');
      }
      return null;
    }
  }

  // --- Переключить камеру ---
  
  async switchCamera() {
    const currentFacing = this._getCurrentFacing();
    const newFacing = currentFacing === 'environment' ? 'user' : 'environment';
    
    // Останавливаем текущий стрим
    this.stopStream();
    
    return this.getStream(newFacing);
  }

  // --- Сделать фото ---
  
  async takePhoto(facingMode = 'environment') {
    const stream = await this.getStream(facingMode);
    if (!stream) return null;

    return new Promise((resolve) => {
      const video = document.createElement('video');
      video.srcObject = stream;
      video.setAttribute('playsinline', '');
      video.muted = true;

      video.onloadedmetadata = () => {
        video.play();
        
        // Ждём стабилизации кадра
        setTimeout(() => {
          const canvas = document.createElement('canvas');
          canvas.width = video.videoWidth;
          canvas.height = video.videoHeight;
          const ctx = canvas.getContext('2d');
          ctx.drawImage(video, 0, 0);
          
          const dataURL = canvas.toDataURL('image/jpeg', 0.85);
          video.remove();
          resolve(dataURL);
        }, 300);
      };

      video.onerror = () => {
        video.remove();
        resolve(null);
      };
    });
  }

  // --- Нативный диалог камеры (input capture) ---
  
  captureNative() {
    return new Promise((resolve) => {
      const input = document.createElement('input');
      input.type = 'file';
      input.accept = 'image/*';
      input.capture = 'environment';
      input.style.display = 'none';
      document.body.appendChild(input);

      input.onchange = (e) => {
        const file = e.target.files?.[0];
        document.body.removeChild(input);

        if (!file) {
          resolve(null);
          return;
        }

        const reader = new FileReader();
        reader.onload = () => resolve(reader.result);
        reader.onerror = () => resolve(null);
        reader.readAsDataURL(file);
      };

      setTimeout(() => {
        if (document.body.contains(input)) {
          document.body.removeChild(input);
          resolve(null);
        }
      }, 120000);

      input.click();
    });
  }

  // --- Остановить стрим ---
  
  stopStream() {
    if (this.stream) {
      this.stream.getTracks().forEach(t => t.stop());
      this.stream = null;
    }
  }

  // --- Приватные ---
  
  _getCurrentFacing() {
    if (!this.stream) return 'environment';
    const track = this.stream.getVideoTracks()[0];
    if (!track) return 'environment';
    const settings = track.getSettings();
    return settings.facingMode || 'environment';
  }
}

export const camera = new CameraService();
