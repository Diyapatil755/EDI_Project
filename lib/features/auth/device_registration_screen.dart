import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import 'auth_provider.dart';

class DeviceRegistrationScreen extends StatelessWidget {
  const DeviceRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final device = auth.currentDeviceMetadata;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Device Binding Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: auth.logout,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueTint,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Icon(
                      Icons.phonelink_lock_rounded,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Register Attendance Device',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  const Text(
                    'This phone will be your registered device for all future attendance marks.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HARDWARE TELEMETRY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _infoRow('Detected Model', device?.modelName ?? 'Mobile Terminal'),
                        const Divider(height: AppSpacing.md),
                        _infoRow('Operating System', '${device?.osName ?? "OS"} ${device?.osVersion ?? ""}'),
                        const Divider(height: AppSpacing.md),
                        _infoRow('Hardware ID', device?.deviceId ?? 'DEV-INITIALIZING'),
                        const Divider(height: AppSpacing.md),
                        _infoRow('Binding Policy', '1 Account : 1 Device strict binding'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningTint,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, size: 20, color: AppColors.warning),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Anti-proxy policy: Marking attendance from another employee phone will be rejected automatically by server verification.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AppButton(
                    label: 'Confirm and Register This Device',
                    onPressed: () => auth.registerCurrentDevice(),
                    isLoading: auth.isLoading,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: auth.logout,
                    child: const Text('Cancel & Sign Out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
