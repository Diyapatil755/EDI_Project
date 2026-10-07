import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _confirmLogout(BuildContext context, AppAuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: const Text(
          'Sign Out Confirmation',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Signing out will clear your active session token. You will need to re-verify OTP on next sign-in.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final employee = auth.currentEmployee;
    final device = auth.currentDeviceMetadata;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Employee Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee identity header
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlueTint,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: const Center(
                        child: Text(
                          'AD',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee?.fullName ?? 'Aarav Deshmukh',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            employee?.role ?? 'Senior Embedded Engineer',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          StatusBadge(
                            label: employee?.employeeId ?? 'EMP-0417',
                            type: StatusBadgeType.info,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Employment Details Card
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ORGANIZATION RECORD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _profileRow('Institution', AppConstants.organizationName),
                    const Divider(height: AppSpacing.md),
                    _profileRow('Department', employee?.department ?? 'IoT & Embedded Systems Lab'),
                    const Divider(height: AppSpacing.md),
                    _profileRow('Work Email', employee?.email ?? 'aarav.deshmukh@vit.edu'),
                    const Divider(height: AppSpacing.md),
                    _profileRow('Shift Schedule', '${AppConstants.shiftStartTime} - ${AppConstants.shiftEndTime}'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Registered Hardware Binding Card
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'REGISTERED DEVICE BINDING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                        StatusBadge(label: 'Bound & Verified', type: StatusBadgeType.success),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _profileRow('Hardware Model', employee?.registeredDeviceModel ?? device?.modelName ?? 'Pixel 7a'),
                    const Divider(height: AppSpacing.md),
                    _profileRow('Device Hardware ID', employee?.registeredDeviceId ?? device?.deviceId ?? 'DEV-0417-VIT'),
                    const Divider(height: AppSpacing.md),
                    _profileRow('Policy Status', 'Single-Device Strict Anti-Proxy Active'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Security Architecture Note
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.lightBlueTint,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2), width: 1),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security_rounded, size: 18, color: AppColors.primaryBlue),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Zero-Trust Architecture: Client never sends employee ID as trusted data. Requests are verified via Firebase ID Token signature at the server.',
                        style: TextStyle(fontSize: 12, color: AppColors.primaryBlue, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              AppButton(
                label: 'Sign Out Account',
                icon: Icons.logout_rounded,
                variant: AppButtonVariant.outlined,
                onPressed: () => _confirmLogout(context, auth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}
