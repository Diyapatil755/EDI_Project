// faceTracker.js
// Thin wrapper around MediaPipe Face Mesh + Camera setup. Emits landmark
// results via a callback so the rest of the app doesn't touch MediaPipe
// directly - makes it easier to swap the underlying detector later
// (e.g. for a native SDK on mobile) without touching challenge logic.

import { MEDIAPIPE_CDN } from './config.js';

export class FaceTracker {
  /**
   * @param {HTMLVideoElement} videoEl
   * @param {(landmarks: any[] | null) => void} onFrame - called every frame
   *        with the first detected face's 468 landmarks, or null if no face.
   */
  constructor(videoEl, onFrame) {
    this.videoEl = videoEl;
    this.onFrameCallback = onFrame;
    this.faceMesh = null;
    this.camera = null;
  }

  async start() {
    // eslint-disable-next-line no-undef -- FaceMesh/Camera loaded via <script> tags in index.html
    this.faceMesh = new FaceMesh({
      locateFile: (file) => `${MEDIAPIPE_CDN}/${file}`,
    });
    this.faceMesh.setOptions({
      maxNumFaces: 1,
      refineLandmarks: true,
      minDetectionConfidence: 0.6,
      minTrackingConfidence: 0.6,
    });
    this.faceMesh.onResults((results) => {
      const landmarks = results.multiFaceLandmarks && results.multiFaceLandmarks.length
        ? results.multiFaceLandmarks[0]
        : null;
      this.onFrameCallback(landmarks);
    });

    // eslint-disable-next-line no-undef -- Camera loaded via <script> tag in index.html
    this.camera = new Camera(this.videoEl, {
      onFrame: async () => {
        await this.faceMesh.send({ image: this.videoEl });
      },
      width: 640,
      height: 480,
    });
    await this.camera.start();
  }

  stop() {
    this.camera?.stop();
  }
}
