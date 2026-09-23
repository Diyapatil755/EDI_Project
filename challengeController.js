// challengeController.js
// The core liveliness state machine. Framework/UI-agnostic: it takes
// landmark frames in, and emits state-change events out via callbacks.
// This is the piece most likely to need porting as-is into a native app,
// so it's kept free of DOM references (see passiveAnalysis.js for the one
// canvas-dependent helper it calls).

import { THRESHOLDS, TIMING, CHALLENGE_TYPES, CHALLENGE_LABELS } from './config.js';
import { averageEAR, mouthRatio, yawOffset } from './geometry.js';
import { samplePassiveFrame, aggregateSamples, computeSpoofRisk } from './passiveAnalysis.js';

export const STATE = {
  IDLE: 'idle',
  CALIBRATING: 'calibrating',
  CHALLENGE_ACTIVE: 'challenge_active',
  DONE: 'done',
};

export const RESULT = {
  PASS: 'pass',                 // active challenge passed, passive risk acceptable
  FLAGGED: 'flagged',           // active challenge passed, passive risk high -> admin review
  FAIL_ACTIVE: 'fail_active',   // active challenge not completed in time / face lost
};

export class ChallengeController {
  /**
   * @param {HTMLVideoElement} videoEl - needed for passive pixel sampling
   * @param {object} callbacks
   * @param {(state: string, detail?: any) => void} callbacks.onStateChange
   * @param {(result: string, detail: object) => void} callbacks.onComplete
   * @param {(metrics: object) => void} callbacks.onMetrics - per-frame metrics for UI display
   */
  constructor(videoEl, { onStateChange, onComplete, onMetrics }) {
    this.videoEl = videoEl;
    this.onStateChange = onStateChange || (() => {});
    this.onComplete = onComplete || (() => {});
    this.onMetrics = onMetrics || (() => {});

    this.state = STATE.IDLE;
    this.blinkCount = 0;
    this.consecLowEARFrames = 0;

    this.calibrationSamples = [];
    this.baselineMouthRatio = null;
    this.baselineYawOffset = null;

    this.challengeType = null;
    this.challengeStartedAt = 0;
    this.activePassed = false;
    this.passiveSamples = [];
    this._challengeTimerId = null;
    this._calibrationTimerId = null;
  }

  /** Call once per detected frame. Pass `null` if no face is currently visible. */
  handleFrame(landmarks) {
    if (!landmarks) {
      if (this.state === STATE.CHALLENGE_ACTIVE) {
        this._finishChallenge(RESULT.FAIL_ACTIVE, { reason: 'face_lost' });
      }
      this.onMetrics({ faceDetected: false });
      return;
    }

    const ear = averageEAR(landmarks);
    this._trackBlink(ear);

    const curMouthRatio = mouthRatio(landmarks);
    const curYawOffset = yawOffset(landmarks);

    if (this.state === STATE.CALIBRATING) {
      this.calibrationSamples.push({ mouth: curMouthRatio, yaw: curYawOffset });
    }

    let mouthDelta = null, yawDelta = null;
    if (this.baselineMouthRatio !== null) {
      mouthDelta = curMouthRatio - this.baselineMouthRatio;
      yawDelta = curYawOffset - this.baselineYawOffset;

      if (this.state === STATE.CHALLENGE_ACTIVE) {
        this._evaluateGesture(mouthDelta, yawDelta);
      }
    }

    if (this.state === STATE.CHALLENGE_ACTIVE) {
      const sample = samplePassiveFrame(this.videoEl, landmarks);
      if (sample) this.passiveSamples.push(sample);
    }

    this.onMetrics({
      faceDetected: true,
      ear,
      mouthDelta,
      yawDelta,
      blinkCount: this.blinkCount,
      landmarks,
    });
  }

  /** Begin calibration, then automatically start the randomized challenge. */
  startCheck() {
    if (this.state === STATE.CHALLENGE_ACTIVE || this.state === STATE.CALIBRATING) return;

    this.state = STATE.CALIBRATING;
    this.calibrationSamples = [];
    this.onStateChange(this.state);

    this._calibrationTimerId = setTimeout(() => {
      if (this.calibrationSamples.length === 0) {
        this.state = STATE.IDLE;
        this.onStateChange(this.state, { error: 'calibration_no_face' });
        return;
      }
      this.baselineMouthRatio = avg(this.calibrationSamples.map((s) => s.mouth));
      this.baselineYawOffset = avg(this.calibrationSamples.map((s) => s.yaw));
      this._runChallenge();
    }, TIMING.CALIBRATION_MS);
  }

  reset() {
    clearTimeout(this._calibrationTimerId);
    clearInterval(this._challengeTimerId);
    this.state = STATE.IDLE;
    this.blinkCount = 0;
    this.consecLowEARFrames = 0;
    this.baselineMouthRatio = null;
    this.baselineYawOffset = null;
    this.passiveSamples = [];
    this.onStateChange(this.state);
  }

  // ---- internals ----

  _trackBlink(ear) {
    if (ear < THRESHOLDS.EAR) {
      this.consecLowEARFrames++;
    } else {
      if (this.consecLowEARFrames >= THRESHOLDS.EAR_CONSEC_FRAMES) {
        this.blinkCount++;
        if (this.state === STATE.CHALLENGE_ACTIVE && this.challengeType === 'blink') {
          this.activePassed = true;
        }
      }
      this.consecLowEARFrames = 0;
    }
  }

  _evaluateGesture(mouthDelta, yawDelta) {
    switch (this.challengeType) {
      case 'smile':
        if (mouthDelta > this.baselineMouthRatio * THRESHOLDS.SMILE_REL_INCREASE) {
          this.activePassed = true;
        }
        break;
      case 'turn_left':
        if (yawDelta < -THRESHOLDS.YAW_DELTA) this.activePassed = true;
        break;
      case 'turn_right':
        if (yawDelta > THRESHOLDS.YAW_DELTA) this.activePassed = true;
        break;
      // 'blink' is handled in _trackBlink
    }
  }

  _runChallenge() {
    this.challengeType = CHALLENGE_TYPES[Math.floor(Math.random() * CHALLENGE_TYPES.length)];
    this.state = STATE.CHALLENGE_ACTIVE;
    this.activePassed = false;
    this.passiveSamples = [];
    this.challengeStartedAt = Date.now();

    this.onStateChange(this.state, {
      challengeType: this.challengeType,
      label: CHALLENGE_LABELS[this.challengeType],
    });

    this._challengeTimerId = setInterval(() => {
      const elapsed = Date.now() - this.challengeStartedAt;
      if (this.activePassed) {
        this._evaluatePassiveAndFinish();
        return;
      }
      if (elapsed >= TIMING.CHALLENGE_DURATION_MS) {
        this._finishChallenge(RESULT.FAIL_ACTIVE, { reason: 'timeout' });
      }
    }, 150);
  }

  _evaluatePassiveAndFinish() {
    clearInterval(this._challengeTimerId);
    if (this.passiveSamples.length === 0) {
      this._finishChallenge(RESULT.FAIL_ACTIVE, { reason: 'no_passive_samples' });
      return;
    }
    const avgSample = aggregateSamples(this.passiveSamples);
    const risk = computeSpoofRisk(avgSample);
    const result = risk < THRESHOLDS.SPOOF_RISK ? RESULT.PASS : RESULT.FLAGGED;
    this._finishChallenge(result, { risk, passiveMetrics: avgSample, challengeType: this.challengeType });
  }

  _finishChallenge(result, detail) {
    clearInterval(this._challengeTimerId);
    this.state = STATE.DONE;
    this.onStateChange(this.state);
    this.onComplete(result, detail);
  }
}

function avg(nums) {
  return nums.reduce((a, b) => a + b, 0) / nums.length;
}
