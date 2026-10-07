import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../home_provider.dart';

class DominantStatusCard extends StatelessWidget {
  final HomeProvider home;
  final VoidCallback onNavigateToFace;

  const DominantStatusCard({
    super.key,
    required this.home,
    required this.onNavigateToFace,
  });

  @override
  Widget build(BuildContext context) {
    String headline;
    String subcopy;
    Color blockBg;
    Color blockBorder;
    Color textCol;
    StatusBadgeType badgeType;
    String badgeLabel;

    if (home.isCheckedOut) {
      headline = 'Shift Completed';
      subcopy = 'All punches recorded for today';
      blockBg = AppColors.surface;
      blockBorder = AppColors.border;
      textCol = AppColors.textPrimary;
      badgeType = StatusBadgeType.neutral;
      badgeLabel = 'Checked Out';
    } else if (home.isCheckedIn) {
      headline = 'Currently Checked In';
      subcopy = 'Work hours recording active';
      blockBg = AppColors.lightBlueTint;
      blockBorder = AppColors.primaryBlue.withValues(alpha: 0.3);
      textCol = AppColors.primaryBlue;
      badgeType = StatusBadgeType.success;
      badgeLabel = 'Active Shift';
    } else {
      headline = 'Not Checked In';
      subcopy = 'Shift starts ${AppConstants.shiftStartTime}';
      blockBg = AppColors.surface;
      blockBorder = AppColors.border;
      textCol = AppColors.textPrimary;
      badgeType = StatusBadgeType.warning;
      badgeLabel = 'Pending Check-in';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: blockBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: blockBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TODAY'S STATUS",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: home.isCheckedIn ? AppColors.primaryBlue : AppColors.textMuted,
                ),
              ),
              StatusBadge(label: badgeLabel, type: badgeType),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            headline,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: textCol,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subcopy,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!home.isCheckedOut)
            AppButton(
              label: home.isCheckedIn ? 'Record Check-out with Face' : 'Mark Attendance with Face',
              icon: Icons.face_rounded,
              onPressed: onNavigateToFace,
              variant: home.isCheckedIn ? AppButtonVariant.secondary : AppButtonVariant.primary,
            )
          else
            const AppBanner(
              type: AppBannerType.info,
              message: 'You have logged out for today. See history for full ledger records.',
            ),
        ],
      ),
    );
  }
}
