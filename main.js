// main.js - entry point. Wires FaceTracker -> ChallengeController -> UI.

import { FaceTracker } from './faceTracker.js';
import { ChallengeController } from './challengeController.js';
import { bindUI } from './ui.js';

const el = (id) => document.getElementById(id);

const elements = {
  video: el('video'),
  overlay: el('overlay'),
  placeholder: el('placeholder'),
  statusBar: el('statusBar'),
  statusText: el('statusText'),
  challengeBanner: el('challengeBanner'),
  earVal: el('earVal'),
  mouthVal: el('mouthVal'),
  yawVal: el('yawVal'),
  blinkVal: el('blinkVal'),
  startBtn: el('startBtn'),
  checkBtn: el('checkBtn'),
  resetBtn: el('resetBtn'),
  barHighlight: el('barHighlight'),
  barTexture: el('barTexture'),
  barColor: el('barColor'),
  valHighlight: el('valHighlight'),
  valTexture: el('valTexture'),
  valColor: el('valColor'),
  passiveVerdict: el('passiveVerdict'),
};

const overlayCtx = elements.overlay.getContext('2d');

const controller = new ChallengeController(elements.video, {});
bindUI(controller, elements);

let tracker = null;

function drawLandmarkDots(landmarks) {
  overlayCtx.clearRect(0, 0, elements.overlay.width, elements.overlay.height);
  if (!landmarks) return;
  overlayCtx.fillStyle = '#6fcf97';
  // Just the eyes + mouth corners for a lightweight visual confirmation;
  // swap in full mesh drawing (drawing_utils) if you want the full overlay.
  const pointsOfInterest = [33, 160, 158, 133, 153, 144, 362, 385, 387, 263, 373, 380, 61, 291];
  for (const i of pointsOfInterest) {
    const p = landmarks[i];
    overlayCtx.beginPath();
    overlayCtx.arc(p.x * elements.overlay.width, p.y * elements.overlay.height, 2.5, 0, Math.PI * 2);
    overlayCtx.fill();
  }
}

async function startCamera() {
  elements.startBtn.disabled = true;
  elements.statusText.textContent = 'Requesting camera access…';
  try {
    elements.video.style.display = 'block';
    elements.overlay.style.display = 'block';
    elements.placeholder.style.display = 'none';

    tracker = new FaceTracker(elements.video, (landmarks) => {
      elements.overlay.width = elements.video.videoWidth || 640;
      elements.overlay.height = elements.video.videoHeight || 480;
      drawLandmarkDots(landmarks);
      controller.handleFrame(landmarks);
    });
    await tracker.start();

    elements.statusText.textContent = 'Camera live — face detection running';
    elements.statusBar.className = 'status-bar neutral';
    elements.checkBtn.disabled = false;
    elements.resetBtn.disabled = false;
  } catch (err) {
    elements.statusText.textContent = 'Camera access failed: ' + err.message;
    elements.statusBar.className = 'status-bar bad';
    elements.startBtn.disabled = false;
  }
}

elements.startBtn.addEventListener('app:start-camera', startCamera);
