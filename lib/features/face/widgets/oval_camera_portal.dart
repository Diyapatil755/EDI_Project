import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/face_liveness_service.dart';
import '../face_attendance_provider.dart';

/// Oval camera portal with liveness-reactive guide ring and inline progress chip.
class OvalCameraPortal extends StatelessWidget {
  final FaceAttendanceProvider provider;
  final LivenessDetectionResult liveness;

  const OvalCameraPortal({
    super.key,
    required this.provider,
    required this.liveness,
  });

  @override
  Widget build(BuildContext context) {
    final camera = provider.faceService.cameraController;
    final isInitialized = provider.faceService.isCameraInitialized &&
        camera != null &&
        camera.value.isInitialized;

    final Color guideColor;
    if (liveness.state == LivenessState.success) {
      guideColor = AppColors.success;
    } else if (liveness.state == LivenessState.failed ||
        liveness.state == LivenessState.spoofSuspected) {
      guideColor = AppColors.error;
    } else if (liveness.state == LivenessState.challenge) {
      guideColor = AppColors.primaryBlue;
    } else {
      guideColor = AppColors.border;
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 290,
            decoration: BoxDecoration(
              color: const Color(0xFF1C2833),
              borderRadius: const BorderRadius.all(Radius.elliptical(110, 145)),
              border: Border.all(
                color: guideColor,
                width: liveness.state == LivenessState.challenge ? 3 : 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.elliptical(110, 145)),
              child: isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: camera.value.previewSize?.height ?? 220,
                        height: camera.value.previewSize?.width ?? 290,
                        child: CameraPreview(camera),
                      ),
                    )
                  : _FallbackPreview(liveness: liveness),
            ),
          ),
          if (liveness.state == LivenessState.challenge ||
              liveness.state == LivenessState.scanning)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: liveness.progress > 0 ? liveness.progress : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(liveness.progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FallbackPreview extends StatelessWidget {
  final LivenessDetectionResult liveness;

  const _FallbackPreview({required this.liveness});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF101924),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              liveness.state == LivenessState.spoofSuspected
                  ? Icons.warning_amber_rounded
                  : Icons.face_retouching_natural_rounded,
              size: 54,
              color: liveness.state == LivenessState.spoofSuspected
                  ? AppColors.error
                  : AppColors.primaryBlue.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 8),
            Text(
              liveness.state == LivenessState.idle
                  ? 'Sensor Ready'
                  : 'Active Biometric Sensor',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
