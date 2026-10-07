import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/auth_provider.dart';
import '../home_provider.dart';

class DeviceSecurityCard extends StatelessWidget {
  final HomeProvider home;
  final AppAuthProvider auth;

  const DeviceSecurityCard({
    super.key,
    required this.home,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    final isMismatched = home.deviceService.isSimulationMismatched;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            isMismatched ? Icons.warning_amber_rounded : Icons.verified_user_outlined,
            size: 20,
            color: isMismatched ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMismatched
                      ? 'Unregistered Phone Active'
                      : 'Single-Device Policy Enforced',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isMismatched ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                Text(
                  isMismatched
                      ? 'Attendance mark will be rejected by server.'
                      : 'Bound to ${auth.currentEmployee?.registeredDeviceModel ?? "Current Terminal"}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
