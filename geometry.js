// geometry.js
// Pure functions that turn MediaPipe Face Mesh landmarks into the
// scalar signals the rest of the app reasons about. No DOM, no state -
// easy to unit test in isolation.

import { LANDMARKS } from './config.js';

export function dist(a, b) {
  return Math.hypot(a.x - b.x, a.y - b.y);
}

/**
 * Eye Aspect Ratio: ratio of eye height to eye width.
 * Drops sharply during a blink. Standard formula from Soukupová & Čech (2016).
 */
export function eyeAspectRatio(landmarks, eyeIndices) {
  const p = eyeIndices.map((i) => landmarks[i]);
  const vertical1 = dist(p[1], p[5]);
  const vertical2 = dist(p[2], p[4]);
  const horizontal = dist(p[0], p[3]);
  return horizontal === 0 ? 0 : (vertical1 + vertical2) / (2 * horizontal);
}

export function averageEAR(landmarks) {
  const right = eyeAspectRatio(landmarks, LANDMARKS.RIGHT_EYE);
  const left = eyeAspectRatio(landmarks, LANDMARKS.LEFT_EYE);
  return (right + left) / 2;
}

export function faceWidth(landmarks) {
  return dist(landmarks[LANDMARKS.FACE_L], landmarks[LANDMARKS.FACE_R]);
}

/** Mouth width normalized by face width - widens measurably during a smile. */
export function mouthRatio(landmarks) {
  const fw = faceWidth(landmarks);
  if (fw === 0) return 0;
  return dist(landmarks[LANDMARKS.MOUTH_L], landmarks[LANDMARKS.MOUTH_R]) / fw;
}

/**
 * Horizontal nose-tip offset from the midpoint of the two cheek landmarks,
 * normalized by face width. A crude but effective proxy for head yaw
 * without needing a full 3D pose solve.
 */
export function yawOffset(landmarks) {
  const fw = faceWidth(landmarks);
  if (fw === 0) return 0;
  const midX = (landmarks[LANDMARKS.FACE_L].x + landmarks[LANDMARKS.FACE_R].x) / 2;
  return (landmarks[LANDMARKS.NOSE_TIP].x - midX) / fw;
}

/** Bounding box of all landmarks, with padding, in normalized [0,1] coords. */
export function landmarksBoundingBox(landmarks, paddingRatio = 0.15) {
  let minX = 1, maxX = 0, minY = 1, maxY = 0;
  for (const p of landmarks) {
    if (p.x < minX) minX = p.x;
    if (p.x > maxX) maxX = p.x;
    if (p.y < minY) minY = p.y;
    if (p.y > maxY) maxY = p.y;
  }
  const padX = (maxX - minX) * paddingRatio;
  const padY = (maxY - minY) * paddingRatio;
  return {
    minX: Math.max(0, minX - padX),
    minY: Math.max(0, minY - padY),
    maxX: Math.min(1, maxX + padX),
    maxY: Math.min(1, maxY + padY),
  };
}
