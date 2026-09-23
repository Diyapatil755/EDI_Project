// passiveAnalysis.js
//
// PLACEHOLDER FOR A TRAINED SPOOF-CLASSIFIER MODEL.
//
// This module computes hand-engineered texture/reflection statistics as a
// stand-in for a lightweight CNN anti-spoofing classifier (e.g. the kind
// used in Silent-Face-Anti-Spoofing or similar open-source projects).
//
// WHY IT'S A HEURISTIC AND NOT A REAL MODEL:
// A real passive spoof classifier needs pretrained weights, which this
// reference build intentionally avoids bundling so it stays a plain,
// dependency-light starting point. Swap this module out for real inference
// - see "SWAPPING IN A REAL MODEL" at the bottom of this file.
//
// WHAT IT MEASURES (per sampled frame, on the cropped face region):
//   - highlightRatio: fraction of near-white pixels -> proxy for screen glare
//   - textureStd:      std dev of grayscale intensity -> local texture/contrast
//   - colorStd:        std dev of hue -> chrominance diversity (flat prints/
//                       screens tend to have less natural color variation)
//
// These are combined into a single 0-100 "spoof risk" score. The weights
// below are illustrative starting points, NOT validated against a labeled
// dataset - tune them against your own bona-fide/spoof samples before
// relying on this for anything beyond a demo.

import { PASSIVE_SAMPLE_SIZE } from './config.js';
import { landmarksBoundingBox } from './geometry.js';

// Reusable offscreen canvas for fast pixel sampling.
const analysisCanvas = document.createElement('canvas');
analysisCanvas.width = PASSIVE_SAMPLE_SIZE;
analysisCanvas.height = PASSIVE_SAMPLE_SIZE;
const actx = analysisCanvas.getContext('2d', { willReadFrequently: true });

/**
 * Samples the current video frame's face region and returns raw texture
 * statistics. Returns null if the crop region is degenerate.
 */
export function samplePassiveFrame(videoEl, landmarks) {
  const box = landmarksBoundingBox(landmarks, 0.15);
  const sx = box.minX * videoEl.videoWidth;
  const sy = box.minY * videoEl.videoHeight;
  const sw = (box.maxX - box.minX) * videoEl.videoWidth;
  const sh = (box.maxY - box.minY) * videoEl.videoHeight;
  if (sw <= 0 || sh <= 0) return null;

  actx.drawImage(videoEl, sx, sy, sw, sh, 0, 0, PASSIVE_SAMPLE_SIZE, PASSIVE_SAMPLE_SIZE);
  const { data } = actx.getImageData(0, 0, PASSIVE_SAMPLE_SIZE, PASSIVE_SAMPLE_SIZE);

  let brightCount = 0;
  const grayVals = [];
  const hueVals = [];

  for (let i = 0; i < data.length; i += 4) {
    const r = data[i], g = data[i + 1], b = data[i + 2];
    const gray = 0.299 * r + 0.587 * g + 0.114 * b;
    grayVals.push(gray);
    if (gray > 235) brightCount++;
    hueVals.push(rgbToHue(r, g, b));
  }

  const n = grayVals.length;
  const highlightRatio = brightCount / n;
  const textureStd = stddev(grayVals);
  const colorStd = stddev(hueVals);

  return { highlightRatio, textureStd, colorStd };
}

function rgbToHue(r, g, b) {
  const max = Math.max(r, g, b), min = Math.min(r, g, b), delta = max - min;
  if (delta === 0) return 0;
  let hue;
  if (max === r) hue = ((g - b) / delta) % 6;
  else if (max === g) hue = (b - r) / delta + 2;
  else hue = (r - g) / delta + 4;
  hue *= 60;
  return hue < 0 ? hue + 360 : hue;
}

function stddev(values) {
  const mean = values.reduce((a, v) => a + v, 0) / values.length;
  const variance = values.reduce((a, v) => a + (v - mean) ** 2, 0) / values.length;
  return Math.sqrt(variance);
}

/** Average a list of per-frame samples into one aggregate reading. */
export function aggregateSamples(samples) {
  const n = samples.length;
  return {
    highlightRatio: samples.reduce((a, s) => a + s.highlightRatio, 0) / n,
    textureStd: samples.reduce((a, s) => a + s.textureStd, 0) / n,
    colorStd: samples.reduce((a, s) => a + s.colorStd, 0) / n,
  };
}

/**
 * Weighted heuristic -> 0 (looks live) .. 100 (looks spoofed).
 * Tune these weights/normalizers against real labeled samples before
 * treating the output as anything more than a rough signal.
 */
export function computeSpoofRisk(avg) {
  const highlightRisk = Math.min(100, avg.highlightRatio * 500);
  const colorRisk = Math.max(0, 100 - (avg.colorStd / 40) * 100);
  const textureRisk = Math.max(0, 100 - (avg.textureStd / 60) * 100) * 0.6;
  return Math.min(100, highlightRisk * 0.45 + colorRisk * 0.35 + textureRisk * 0.2);
}

/*
SWAPPING IN A REAL MODEL
=========================
To replace this heuristic with an actual trained classifier:

1. Pick a lightweight anti-spoofing model, e.g.:
   - Silent-Face-Anti-Spoofing (MiniFASNet, ONNX/PyTorch export available)
   - A MobileNetV2/V3 binary classifier fine-tuned on a spoof dataset
     (CelebA-Spoof, NUAA Photograph Imposter, OULU-NPU)

2. Export it to a web-runnable format:
   - TensorFlow.js: convert with `tensorflowjs_converter`, load with
     `@tensorflow/tfjs` + `tf.loadGraphModel()`
   - ONNX Runtime Web: export to .onnx, load with `onnxruntime-web`

3. Host the model weights on your own server/CDN (not a public model hub
   if your deployment target has restricted egress - check your own
   network policy).

4. Replace `samplePassiveFrame` + `computeSpoofRisk` with:
     const tensor = preprocessFrame(croppedFaceImage); // resize/normalize
     const output = await model.predict(tensor);
     const spoofRisk = output.dataSync()[0] * 100; // adjust to your model's output shape

Keep the function signature (`videoEl, landmarks -> risk score 0-100`) the
same so the rest of the app (challengeController.js) doesn't need to change.
*/
