// config.js
// All tunable parameters live here so a developer can adjust behavior
// without hunting through the detection logic.

export const LANDMARKS = {
  RIGHT_EYE: [33, 160, 158, 133, 153, 144],
  LEFT_EYE: [362, 385, 387, 263, 373, 380],
  MOUTH_L: 61,
  MOUTH_R: 291,
  FACE_L: 234, // lateral cheek extreme, used as a face-width reference
  FACE_R: 454,
  NOSE_TIP: 1,
};

export const THRESHOLDS = {
  EAR: 0.21,               // eye aspect ratio below this = eye considered closed
  EAR_CONSEC_FRAMES: 2,    // consecutive low-EAR frames required to count as a blink
  SMILE_REL_INCREASE: 0.14,// mouth-width ratio increase (relative to baseline) to count as a smile
  YAW_DELTA: 0.045,        // normalized nose-offset delta to count as a head turn
  SPOOF_RISK: 55,          // 0-100 passive risk score; at/above this => flagged for review
};

export const TIMING = {
  CALIBRATION_MS: 1200,      // neutral-face baseline capture window
  CHALLENGE_DURATION_MS: 7000, // time allowed to complete the active challenge
};

export const CHALLENGE_TYPES = ['blink', 'smile', 'turn_left', 'turn_right'];

export const CHALLENGE_LABELS = {
  blink: 'Please blink',
  smile: 'Please smile',
  turn_left: 'Turn your head to one side',
  turn_right: 'Turn your head to the other side',
};

export const MEDIAPIPE_CDN = 'https://cdn.jsdelivr.net/npm/@mediapipe/face_mesh';

// Passive analysis sample size (px) - small for speed, plenty for aggregate texture stats
export const PASSIVE_SAMPLE_SIZE = 48;
