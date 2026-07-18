// === Printer Service ===
// Стратегия печати:
//   Android: Web Bluetooth → PassPRNT → WiFi TCP:9100
//   iOS: PassPRNT → PDF + AirPrint

import { tg } from '../core/telegram.js';
import { EscPosEncoder } from '../utils/escpos.js';

class PrinterService {
  constructor() {
    this.platform = this._detectPlatform();
    this.bleDevice = null;
    this.bleCharacteristic = null;
    this.connectionType = null;
    this.printerConfig = {
      sellerName: 'ИП Crazy Trout Arena',
      inn: '7701234567',
      taxSystem: 'УСН доходы',
      fn: '8710000100412345',
      fd: '12345',
      fpd: '6789012345',
      address: 'г. Москва, ул. Прудовая, д. 1',
      website: 'nalog.gov.ru',
    };
  }

  // --- Определение платформы ---
  
  _detectPlatform() {
    const ua = navigator.userAgent.toLowerCase();
    if (/iphone|ipad/.test(ua)) return 'ios';
    if (/android/.test(ua)) return 'android';
    return 'desktop';
  }

  // --- Подключение к принтеру ---
  
  async connect(method = 'auto') {
    if (method === 'auto' || method === 'ble') {
      if (this.platform === 'android') {
        const result = await this._connectBLE();
        if (result) return result;
      }
    }

    if (method === 'auto' || method === 'passprnt') {
      return { type: 'passprnt', connected: true };
    }

    if (method === 'auto' || method === 'pdf') {
      return { type: 'pdf', connected: true };
    }

    return { type: 'none', connected: false };
  }

  // --- Web Bluetooth подключение ---
  
  async _connectBLE() {
    try {
      if (!navigator.bluetooth) {
        console.warn('Web Bluetooth not available');
        return null;
      }

      const device = await navigator.bluetooth.requestDevice({
        acceptAllDevices: true,
        optionalServices: [
          '000018f0-0000-1000-8000-00805f9b34fb', // SPP для принтеров
          '49535343-fe7d-4ae5-8fa9-9fafd205e455', // Generic SPP
          'e7810a71-73ae-499d-8c15-faa9aef0c3f2', // ESC/POS BLE
        ]
      });

      const server = await device.gatt.connect();

      // Пытаемся найти сервис печати
      const services = await server.getPrimaryServices();
      let characteristic = null;

      for (const service of services) {
        try {
          const chars = await service.getCharacteristics();
          for (const char of chars) {
            if (char.properties.write || char.properties.writeWithoutResponse) {
              characteristic = char;
              break;
            }
          }
          if (characteristic) break;
        } catch (e) {
          continue;
        }
      }

      if (!characteristic) {
        console.warn('No writable characteristic found');
        return null;
      }

      this.bleDevice = device;
      this.bleCharacteristic = characteristic;
      this.connectionType = 'ble';

      // Слушаем отключение
      device.addEventListener('gattserverdisconnected', () => {
        this.bleCharacteristic = null;
        this.connectionType = null;
      });

      return { type: 'ble', connected: true, device: device.productName || 'Bluetooth Printer' };

    } catch (e) {
      if (e.name === 'NotFoundError') {
        console.log('User cancelled Bluetooth device selection');
      } else {
        console.warn('BLE connection failed:', e);
      }
      return null;
    }
  }

  // --- Печать чека ---
  
  async print(receipt) {
    const escposBytes = EscPosEncoder.encode(receipt, this.printerConfig);

    // Определяем метод печати
    if (this.connectionType === 'ble' && this.bleCharacteristic) {
      return this._printBLE(escposBytes);
    }

    if (this.platform === 'ios') {
      return this._printPassPRNT(receipt);
    }

    if (this.platform === 'android') {
      // Пробуем BLE, потом PassPRNT
      const bleResult = await this._printBLE(escposBytes);
      if (bleResult) return bleResult;
      
      return this._printPassPRNT(receipt);
    }

    // Desktop fallback — PDF
    return this._printPDF(receipt);
  }

  // --- Печать через BLE ---
  
  async _printBLE(bytes) {
    if (!this.bleCharacteristic) return false;

    try {
      const CHUNK_SIZE = 512; // Типичный BLE MTU

      for (let i = 0; i < bytes.length; i += CHUNK_SIZE) {
        const chunk = bytes.slice(i, i + CHUNK_SIZE);
        await this.bleCharacteristic.writeValue(chunk);
        
        // Пауза между чанками для стабильности
        if (i + CHUNK_SIZE < bytes.length) {
          await new Promise(r => setTimeout(r, 50));
        }
      }

      tg.hapticNotification('success');
      return true;

    } catch (e) {
      console.warn('BLE print failed:', e);
      tg.hapticNotification('error');
      return false;
    }
  }

  // --- Печать через Star PassPRNT (URL scheme) ---
  
  _printPassPRNT(receipt) {
    try {
      // Формируем HTML чека для PassPRNT
      const html = this._buildReceiptHTML(receipt);
      const encodedHTML = encodeURIComponent(html);

      // Star PassPRNT URL scheme
      const url = `starpassprnt://print?html=${encodedHTML}&back=${encodeURIComponent(window.location.href)}`;

      // Пробуем открыть PassPRNT
      const iframe = document.createElement('iframe');
      iframe.style.display = 'none';
      iframe.src = url;
      document.body.appendChild(iframe);

      // Убираем iframe через 3 секунды
      setTimeout(() => {
        if (document.body.contains(iframe)) {
          document.body.removeChild(iframe);
        }
      }, 3000);

      // Показываем пользователю инструкцию
      tg.showPopup(
        'Печать через PassPRNT',
        'Убедитесь, что установлено приложение Star PassPRNT и принтер подключён по Bluetooth.',
        [{ type: 'ok' }]
      );

      return true;

    } catch (e) {
      console.warn('PassPRNT print failed:', e);
      return false;
    }
  }

  // --- Печать через WiFi (TCP:9100) ---
  
  async _printWiFi(bytes, printerIP = '192.168.1.50', port = 9100) {
    try {
      // Нужен WebSocket-прокси на локальной сети
      // Или прямое подключение через fetch к локальному серверу
      const response = await fetch(`http://${printerIP}:${port}`, {
        method: 'POST',
        body: bytes,
        headers: { 'Content-Type': 'application/octet-stream' }
      });

      return response.ok;

    } catch (e) {
      console.warn('WiFi print failed:', e);
      return false;
    }
  }

  // --- PDF fallback ---
  
  async _printPDF(receipt) {
    try {
      // Динамический импорт jsPDF
      const { jsPDF } = await import('https://cdn.jsdelivr.net/npm/jspdf@2.5.2/dist/jspdf.es.min.js');

      const doc = new jsPDF({
        unit: 'mm',
        format: [80, 200 + (receipt.catches?.length || 0) * 12]
      });

      let y = 10;

      // Заголовок
      doc.setFont('courier', 'bold');
      doc.setFontSize(14);
      doc.text('CRAZY TROUT ARENA', 40, y, { align: 'center' });
      y += 8;

      doc.setFont('courier', 'normal');
      doc.setFontSize(8);
      doc.text(this.printerConfig.address, 40, y, { align: 'center' });
      y += 5;
      doc.text(`ИНН: ${this.printerConfig.inn}`, 5, y);
      y += 8;

      // Разделитель
      doc.text('─'.repeat(36), 5, y);
      y += 6;

      // Данные чека
      doc.text(`Чек №${receipt.id}`, 5, y); y += 5;
      doc.text(`Дата: ${receipt.date}`, 5, y); y += 5;
      doc.text(`Тариф: ${receipt.tariffLabel} — ${receipt.tariffPrice}₽`, 5, y); y += 8;

      // Улов
      if (receipt.catches?.length) {
        doc.setFont('courier', 'bold');
        doc.text('УЛОВ:', 5, y); y += 5;
        doc.setFont('courier', 'normal');

        for (const c of receipt.catches) {
          const weight = c.kg > 0 ? `${c.kg}кг${c.grams > 0 ? c.grams + 'г' : ''}` : `${c.grams}г`;
          doc.text(`  ${c.breedLabel} ${weight} × ${c.pricePerKg}₽/кг`, 5, y); y += 5;
          doc.text(`  = ${c.sum}₽`, 5, y); y += 5;
        }

        doc.text('─'.repeat(36), 5, y);
        y += 6;
      }

      // Итого
      doc.setFont('courier', 'bold');
      doc.setFontSize(14);
      doc.text(`ИТОГО: ${receipt.total}₽`, 40, y, { align: 'center' });
      y += 10;

      // Оплата
      doc.setFontSize(8);
      doc.setFont('courier', 'normal');
      const paymentLabels = { cash: 'Наличные', card: 'Карта', account: 'Счёт заведения' };
      doc.text(`Оплата: ${paymentLabels[receipt.paymentMethod] || receipt.paymentMethod}`, 5, y);
      y += 8;

      // 54-ФЗ
      if (receipt.fiscal) {
        doc.text('─'.repeat(36), 5, y); y += 6;
        doc.text(`СНО: ${this.printerConfig.taxSystem}`, 5, y); y += 5;
        doc.text(`ФН: ${this.printerConfig.fn}`, 5, y); y += 5;
        doc.text(`ФД: ${this.printerConfig.fd}`, 5, y); y += 5;
        doc.text(`ФПД: ${this.printerConfig.fpd}`, 5, y); y += 5;
        doc.text(`Сайт ФНС: ${this.printerConfig.website}`, 5, y); y += 5;
      }

      // Скачиваем PDF
      doc.save(`receipt-${receipt.id}.pdf`);

      tg.hapticNotification('success');
      return true;

    } catch (e) {
      console.warn('PDF generation failed:', e);
      tg.hapticNotification('error');
      return false;
    }
  }

  // --- HTML чека для PassPRNT ---
  
  _buildReceiptHTML(receipt) {
    const catchesHTML = receipt.catches?.length
      ? receipt.catches.map(c => {
          const weight = c.kg > 0 ? `${c.kg}кг${c.grams > 0 ? c.grams + 'г' : ''}` : `${c.grams}г`;
          return `<tr><td>${c.breedLabel}</td><td>${weight} × ${c.pricePerKg}₽</td><td style="text-align:right">${c.sum}₽</td></tr>`;
        }).join('')
      : '<tr><td colspan="3" style="text-align:center">Нет улова</td></tr>';

    const paymentLabels = { cash: 'Наличные', card: 'Карта', account: 'Счёт заведения' };

    return `<!DOCTYPE html>
<html><head><meta charset="utf-8"><style>
  body { font-family: monospace; font-size: 12px; width: 300px; margin: 0 auto; }
  h2 { text-align: center; margin: 0; }
  .center { text-align: center; }
  table { width: 100%; border-collapse: collapse; }
  td { padding: 2px 0; }
  .total { font-size: 18px; font-weight: bold; text-align: center; margin: 10px 0; }
  .separator { border-top: 1px dashed #000; margin: 8px 0; }
  .small { font-size: 10px; }
</style></head><body>
  <h2>CRAZY TROUT ARENA</h2>
  <p class="center small">${this.printerConfig.address}<br>ИНН: ${this.printerConfig.inn}</p>
  <div class="separator"></div>
  <p>Чек №${receipt.id}<br>Дата: ${receipt.date}<br>Тариф: ${receipt.tariffLabel} — ${receipt.tariffPrice}₽</p>
  <div class="separator"></div>
  <p><strong>УЛОВ:</strong></p>
  <table>${catchesHTML}</table>
  <div class="separator"></div>
  <p class="total">ИТОГО: ${receipt.total}₽</p>
  <p>Оплата: ${paymentLabels[receipt.paymentMethod] || receipt.paymentMethod}</p>
  ${receipt.fiscal ? `
  <div class="separator"></div>
  <p class="small">СНО: ${this.printerConfig.taxSystem}<br>ФН: ${this.printerConfig.fn}<br>ФД: ${receipt.id}<br>ФПД: ${this.printerConfig.fpd}<br>Сайт ФНС: ${this.printerConfig.website}</p>
  ` : ''}
</body></html>`;
  }

  // --- Отключение ---
  
  disconnect() {
    if (this.bleDevice?.gatt?.connected) {
      this.bleDevice.gatt.disconnect();
    }
    this.bleCharacteristic = null;
    this.connectionType = null;
  }
}

export const printer = new PrinterService();
