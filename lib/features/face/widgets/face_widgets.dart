import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../models/evidence_model.dart';
import '../../../services/face_liveness_service.dart';
import '../../auth/auth_provider.dart';
import '../face_attendance_provider.dart';

/// Challenge prompt card showing current liveness instruction and state badge.
class ChallengePromptCard extends StatelessWidget {
  final FaceAttendanceProvider provider;
  final LivenessDetectionResult liveness;

  const ChallengePromptCard({
    super.key,
    required this.provider,
    required this.liveness,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'CHALLENGE: ${provider.currentChallenge.title.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              _livenessStateBadge(liveness.state),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            liveness.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider.currentChallenge.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _livenessStateBadge(LivenessState state) {
    Color bg, fg, border;
    if (state == LivenessState.success) {
      bg = AppColors.successTint;
      fg = AppColors.success;
      border = AppColors.success.withValues(alpha: 0.3);
    } else if (state == LivenessState.failed || state == LivenessState.spoofSuspected) {
      bg = AppColors.errorTint;
      fg = AppColors.error;
      border = AppColors.error.withValues(alpha: 0.3);
    } else {
      bg = AppColors.lightBlueTint;
      fg = AppColors.primaryBlue;
      border = AppColors.primaryBlue.withValues(alpha: 0.25);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        state.name.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.3),
      ),
    );
  }
}

/// Displays the server decision result or rejection with specific error labelling.
class ServerResultView extends StatelessWidget {
  final ServerVerificationResult serverRes;
  final VoidCallback? onRetry;

  const ServerResultView({
    super.key,
    required this.serverRes,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (serverRes.isSuccess) {
      return AppCard(
        backgroundColor: AppColors.successTint,
        borderColor: AppColors.success.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                SizedBox(width: 8),
                Text(
                  'Verified by Server Decision Engine',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(serverRes.message,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            if (serverRes.ledgerHash != null) ...[
              const SizedBox(height: 8),
              Text(
                'Ledger Anchor: ${serverRes.ledgerHash}',
                style: const TextStyle(
                    fontSize: 11, fontFamily: 'monospace', color: Color(0xFF243B53)),
              ),
            ],
          ],
        ),
      );
    }

    final String errorTitle;
    switch (serverRes.status) {
      case ServerDecisionStatus.unregisteredDevice:
        errorTitle = 'Device Security Violation';
        break;
      case ServerDecisionStatus.outsideGeofence:
        errorTitle = 'Geofence Perimeter Rejection';
        break;
      case ServerDecisionStatus.mockLocationDetected:
        errorTitle = 'Anti-Spoofing GPS Trigger';
        break;
      case ServerDecisionStatus.tokenExpired:
        errorTitle = 'Authentication Session Expired';
        break;
      case ServerDecisionStatus.livenessFailed:
        errorTitle = 'Biometric Liveness Failed';
        break;
      default:
        errorTitle = 'Verification Rejected';
    }

    return AppBanner(
      type: AppBannerType.error,
      title: errorTitle,
      message: serverRes.message,
      onAction: serverRes.status == ServerDecisionStatus.tokenExpired
          ? () => context.findAncestorWidgetOfExactType<AppAuthProvider>() != null
              ? null
              : null
          : null,
    );
  }
}

/// Action buttons for verification flow states.
class VerificationActionControls extends StatelessWidget {
  final FaceAttendanceProvider provider;
  final LivenessDetectionResult liveness;
  final VoidCallback onBackToHome;

  const VerificationActionControls({
    super.key,
    required this.provider,
    required this.liveness,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.flowStep == VerificationFlowStep.submittingEvidence) {
      return const Column(
        children: [
          SizedBox(height: AppSpacing.sm),
          SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Sending cryptographic evidence bundle to server...',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      );
    }

    if (provider.flowStep == VerificationFlowStep.completed) {
      return AppButton(
        label: 'Return to Dashboard',
        icon: Icons.check,
        onPressed: onBackToHome,
      );
    }

    if (provider.flowStep == VerificationFlowStep.rejected) {
      return Column(
        children: [
          AppButton(
            label: 'Retry Biometric Check',
            icon: Icons.refresh,
            onPressed: provider.resetVerification,
          ),
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton(
            onPressed: onBackToHome,
            child: const Text('Back to Dashboard'),
          ),
        ],
      );
    }

    return AppButton(
      label: liveness.state == LivenessState.idle
          ? 'Start Biometric Liveness Scan'
          : 'Scanning Active...',
      icon: Icons.camera_alt_outlined,
      onPressed:
          liveness.state == LivenessState.idle ? provider.startVerification : null,
    );
  }
}
