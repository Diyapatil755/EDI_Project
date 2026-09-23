// ui.js
// All DOM manipulation lives here, kept separate from the detection logic
// so challengeController.js / faceTracker.js can be reused (e.g. ported to
// a native app or a headless test) without dragging the UI along.

export function bindUI(controller, elements) {
  const {
    statusBar, statusText, challengeBanner,
    earVal, mouthVal, yawVal, blinkVal,
    startBtn, checkBtn, resetBtn,
    barHighlight, barTexture, barColor,
    valHighlight, valTexture, valColor,
    passiveVerdict,
  } = elements;

  function setStatus(text, kind) {
    statusText.textContent = text;
    statusBar.className = 'status-bar ' + kind;
  }

  controller.onStateChange = (state, detail) => {
    if (state === 'calibrating') {
      setStatus('Calibrating — please hold a neutral expression…', 'neutral');
    } else if (state === 'challenge_active') {
      challengeBanner.textContent = detail.label;
      challengeBanner.style.display = 'block';
      setStatus(detail.label + '…', 'warn');
      checkBtn.disabled = true;
    } else if (state === 'idle') {
      challengeBanner.style.display = 'none';
      checkBtn.disabled = false;
      if (detail && detail.error === 'calibration_no_face') {
        setStatus('Calibration failed — face not visible', 'bad');
      } else {
        setStatus('Reset — face detection running', 'neutral');
      }
    } else if (state === 'done') {
      challengeBanner.style.display = 'none';
      checkBtn.disabled = false;
    }
  };

  controller.onComplete = (result, detail) => {
    if (result === 'fail_active') {
      const reasonText = {
        face_lost: 'Face lost during check — try again',
        timeout: 'No gesture detected — liveliness check failed',
        no_passive_samples: 'Gesture detected but no passive samples captured — retry',
      }[detail.reason] || 'Liveliness check failed';
      setStatus(reasonText, 'bad');
      passiveVerdict.style.display = 'none';
      return;
    }

    updatePassiveUI(detail.passiveMetrics);
    passiveVerdict.style.display = 'block';

    if (result === 'pass') {
      setStatus('Liveliness confirmed ✓', 'good');
      passiveVerdict.textContent = `Passive spoof-risk score: ${detail.risk.toFixed(0)}/100 — looks live`;
      passiveVerdict.style.background = 'var(--good-soft)';
      passiveVerdict.style.color = 'var(--good)';
    } else if (result === 'flagged') {
      setStatus('Gesture passed, but texture analysis is suspicious — flagged for admin review', 'warn');
      passiveVerdict.textContent = `Passive spoof-risk score: ${detail.risk.toFixed(0)}/100 — flagged for review`;
      passiveVerdict.style.background = 'var(--warn-soft)';
      passiveVerdict.style.color = 'var(--warn)';
    }
  };

  controller.onMetrics = (m) => {
    if (!m.faceDetected) {
      earVal.textContent = '—';
      mouthVal.textContent = '—';
      yawVal.textContent = '—';
      return;
    }
    earVal.textContent = m.ear.toFixed(3);
    blinkVal.textContent = m.blinkCount;
    mouthVal.textContent = m.mouthDelta === null ? '—' : fmtSigned(m.mouthDelta);
    yawVal.textContent = m.yawDelta === null ? '—' : fmtSigned(m.yawDelta);
  };

  function updatePassiveUI(avg) {
    barHighlight.style.width = Math.min(100, avg.highlightRatio * 400).toFixed(0) + '%';
    barTexture.style.width = Math.min(100, (avg.textureStd / 60) * 100).toFixed(0) + '%';
    barColor.style.width = Math.min(100, (avg.colorStd / 40) * 100).toFixed(0) + '%';
    valHighlight.textContent = (avg.highlightRatio * 100).toFixed(1) + '%';
    valTexture.textContent = avg.textureStd.toFixed(1);
    valColor.textContent = avg.colorStd.toFixed(1);
  }

  function fmtSigned(n) {
    return (n >= 0 ? '+' : '') + n.toFixed(3);
  }

  startBtn.addEventListener('click', () => startBtn.dispatchEvent(new CustomEvent('app:start-camera')));
  checkBtn.addEventListener('click', () => controller.startCheck());
  resetBtn.addEventListener('click', () => {
    controller.reset();
    valHighlight.textContent = '—'; valTexture.textContent = '—'; valColor.textContent = '—';
    barHighlight.style.width = '0%'; barTexture.style.width = '0%'; barColor.style.width = '0%';
    passiveVerdict.style.display = 'none';
    blinkVal.textContent = '0';
  });

  return { setStatus };
}
