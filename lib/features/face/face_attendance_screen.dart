import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/liveness_challenge.dart';
import '../../services/face_liveness_service.dart';
import '../auth/auth_provider.dart';
import 'face_attendance_provider.dart';
import 'widgets/face_widgets.dart';
import 'widgets/oval_camera_portal.dart';

class FaceAttendanceScreen extends StatelessWidget {
  final VoidCallback onBackToHome;

  const FaceAttendanceScreen({super.key, required this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FaceAttendanceProvider>();
    final liveness = provider.livenessResult;
    final serverRes = provider.serverResponse;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Biometric Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackToHome,
        ),
        actions: [
          PopupMenuButton<LivenessChallenge>(
            tooltip: 'Select Challenge Prompt',
            icon: const Icon(Icons.psychology_outlined, size: 20),
            onSelected: provider.selectChallenge,
            itemBuilder: (ctx) => LivenessChallenge.standardChallenges()
                .map((c) => PopupMenuItem(
                      value: c,
                      child: Text(c.title, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report_outlined, size: 20),
            tooltip: 'Test Spoof / Failure Mode',
            onPressed: () => _showLivenessTestSheet(context, provider),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OvalCameraPortal(provider: provider, liveness: liveness),
              const SizedBox(height: AppSpacing.md),
              ChallengePromptCard(provider: provider, liveness: liveness),
              const SizedBox(height: AppSpacing.md),
              if (serverRes != null) ...[
                ServerResultView(
                  serverRes: serverRes,
                  onRetry: provider.resetVerification,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              VerificationActionControls(
                provider: provider,
                liveness: liveness,
                onBackToHome: onBackToHome,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLivenessTestSheet(
      BuildContext context, FaceAttendanceProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Liveness Testing Sandbox',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Trigger simulated challenge outcomes to verify security rejection flows:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
              title: const Text('Simulate Successful Liveness'),
              onTap: () {
                provider.faceService.triggerSimulatedOutcome(LivenessState.success);
                Navigator.pop(ctx);
                provider.startVerification();
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.camera_front_outlined, color: AppColors.error),
              title: const Text('Simulate Photo / Screen Spoofing (Rejected)'),
              onTap: () {
                provider.faceService.triggerSimulatedOutcome(LivenessState.spoofSuspected);
                Navigator.pop(ctx);
                provider.startVerification();
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.timer_off_outlined, color: AppColors.warning),
              title: const Text('Simulate Liveness Timeout / Incomplete'),
              onTap: () {
                provider.faceService.triggerSimulatedOutcome(LivenessState.failed);
                Navigator.pop(ctx);
                provider.startVerification();
              },
            ),
          ],
        ),
      ),
    );
  }
}
