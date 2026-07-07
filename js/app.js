// ===== Crazy Trout Arena — Client Prototype JS =====
(function () {
  'use strict';

  // --- Screen navigation ---
  const screenEl = document.getElementById('phoneScreen');

  function goTo(screenId) {
    const current = screenEl.querySelector('.screen.active');
    const next = document.getElementById('screen-' + screenId);
    if (!next || next === current) return;

    current.classList.remove('active');
    next.classList.add('active');

    // Update sidebar
    document.querySelectorAll('.sidebar-link').forEach(l => {
      l.classList.toggle('active', l.dataset.screen === screenId);
    });
  }

  // Delegate clicks on [data-screen]
  document.addEventListener('click', function (e) {
    const btn = e.target.closest('[data-screen]');
    if (!btn) return;
    e.preventDefault();
    goTo(btn.dataset.screen);
  });

  // --- Splash auto-forward ---
  setTimeout(() => goTo('auth-phone'), 2400);

  // --- Auth: send code ---
  const btnSendCode = document.getElementById('btnSendCode');
  if (btnSendCode) {
    btnSendCode.addEventListener('click', function () {
      const phone = document.getElementById('phoneInput').value || '900 123-45-67';
      document.getElementById('otpPhone').textContent = '+7 ' + phone.replace(/(\d{3})(\d{3})(\d{2})(\d{2})/, '$1 ***-**-$4');
      goTo('auth-otp');
      startOtpTimer();
      activateOtpBoxes();
    });
  }

  // --- OTP timer ---
  let timerInterval;
  function startOtpTimer() {
    let sec = 30;
    const el = document.getElementById('otpTimer');
    clearInterval(timerInterval);
    timerInterval = setInterval(() => {
      sec--;
      if (sec <= 0) {
        clearInterval(timerInterval);
        el.textContent = 'Отправить повторно';
        el.style.cursor = 'pointer';
        el.style.color = '#E89829';
        return;
      }
      el.textContent = '0:' + String(sec).padStart(2, '0');
    }, 1000);
  }

  // --- OTP boxes ---
  function activateOtpBoxes() {
    const boxes = document.querySelectorAll('.otp-box');
    const btnVerify = document.getElementById('btnVerifyOtp');
    let code = '';

    // Simulate typing with clicks
    boxes.forEach((box, i) => {
      box.addEventListener('click', function () {
        if (code.length >= 6) return;
        const digit = String(Math.floor(Math.random() * 10));
        code += digit;
        box.textContent = digit;
        box.classList.add('filled');

        // Auto-advance
        if (i < 5 && code.length < 6) {
          boxes[i + 1].classList.add('active');
        }

        if (code.length === 6) {
          btnVerify.disabled = false;
          btnVerify.textContent = 'Подтвердить ✓';
        }
      });
    });

    // Reset on re-entry
    boxes.forEach(b => { b.textContent = ''; b.classList.remove('filled', 'active'); });
    if (boxes[0]) boxes[0].classList.add('active');
    code = '';
    if (btnVerify) { btnVerify.disabled = true; btnVerify.textContent = 'Подтвердить'; }
  }

  // --- OTP verify ---
  const btnVerify = document.getElementById('btnVerifyOtp');
  if (btnVerify) {
    btnVerify.addEventListener('click', function () {
      if (btnVerify.disabled) return;
      goTo('home');
    });
  }

  // --- Guests counter ---
  const guestsCount = document.getElementById('guestsCount');
  const guestsMinus = document.getElementById('guestsMinus');
  const guestsPlus = document.getElementById('guestsPlus');
  if (guestsCount && guestsMinus && guestsPlus) {
    let count = 2;
    guestsMinus.addEventListener('click', function () {
      if (count > 1) { count--; guestsCount.textContent = count; updateBookingSummary(); }
    });
    guestsPlus.addEventListener('click', function () {
      if (count < 10) { count++; guestsCount.textContent = count; updateBookingSummary(); }
    });
  }

  function updateBookingSummary() {
    const count = parseInt(guestsCount?.textContent || '2');
    const totalEl = document.querySelector('.summary-row.total span:last-child');
    const perPerson = 2500;
    const gazebo = 500;
    if (totalEl) {
      const total = count * perPerson + gazebo;
      totalEl.textContent = total.toLocaleString('ru-RU') + ' ₽';
    }
    // Update the first row
    const firstRow = document.querySelector('.summary-row span:first-child');
    if (firstRow) firstRow.textContent = count + ' × Дневная смена';
    const firstPrice = document.querySelector('.summary-row span:last-child:not(.summary-row.total span)');
    // Update pay button
    const payBtn = document.querySelector('#screen-booking-pay .btn-primary');
    if (payBtn) {
      const total = count * perPerson + gazebo;
      payBtn.textContent = 'Оплатить ' + total.toLocaleString('ru-RU') + ' ₽';
    }
    const payAmount = document.querySelector('.pay-amount-val');
    if (payAmount) {
      const total = count * perPerson + gazebo;
      payAmount.textContent = total.toLocaleString('ru-RU') + ' ₽';
    }
  }

  // --- Date picker ---
  document.querySelectorAll('.date-btn').forEach(btn => {
    btn.addEventListener('click', function () {
      document.querySelectorAll('.date-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });

  // --- Time picker ---
  document.querySelectorAll('.time-btn').forEach(btn => {
    btn.addEventListener('click', function () {
      document.querySelectorAll('.time-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });

  // --- Filter chips ---
  document.querySelectorAll('.filter-chips .chip').forEach(chip => {
    chip.addEventListener('click', function () {
      document.querySelectorAll('.filter-chips .chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
    });
  });

  // --- Payment methods ---
  document.querySelectorAll('.pay-method').forEach(m => {
    m.addEventListener('click', function () {
      document.querySelectorAll('.pay-method').forEach(p => p.classList.remove('active'));
      m.classList.add('active');
    });
  });

  // --- History tabs ---
  document.querySelectorAll('.htab').forEach(tab => {
    tab.addEventListener('click', function () {
      document.querySelectorAll('.htab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
    });
  });

  // --- Stats period ---
  document.querySelectorAll('.period-btn').forEach(btn => {
    btn.addEventListener('click', function () {
      document.querySelectorAll('.period-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });

  // --- Map pins ---
  document.querySelectorAll('.map-pin').forEach(pin => {
    pin.style.cursor = 'pointer';
    pin.addEventListener('click', function () {
      goTo('spot-detail');
    });
  });

  // --- Pay button ---
  const btnPay = document.getElementById('btnPay');
  if (btnPay) {
    btnPay.addEventListener('click', function () {
      btnPay.textContent = 'Обработка...';
      btnPay.disabled = true;
      setTimeout(() => {
        btnPay.textContent = 'Оплатить';
        btnPay.disabled = false;
        goTo('booking-done');
      }, 1200);
    });
  }

  // --- Phone input formatting ---
  const phoneInput = document.getElementById('phoneInput');
  if (phoneInput) {
    phoneInput.addEventListener('input', function () {
      let v = phoneInput.value.replace(/\D/g, '');
      if (v.length > 10) v = v.slice(0, 10);
      let formatted = '';
      if (v.length > 0) formatted += v.slice(0, 3);
      if (v.length > 3) formatted += ' ' + v.slice(3, 6);
      if (v.length > 6) formatted += '-' + v.slice(6, 8);
      if (v.length > 8) formatted += '-' + v.slice(8, 10);
      phoneInput.value = formatted;
    });
  }

})();
