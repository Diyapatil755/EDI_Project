import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

enum StatusBadgeType { success, warning, error, info, neutral, ledger }

/// Status indicator chip with flat styling, border, and clear text contrast.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;
  final VoidCallback? onTap;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.neutral,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (type) {
      case StatusBadgeType.success:
        bg = AppColors.successTint;
        fg = AppColors.success;
        border = AppColors.success.withValues(alpha: 0.3);
        break;
      case StatusBadgeType.warning:
        bg = AppColors.warningTint;
        fg = AppColors.warning;
        border = AppColors.warning.withValues(alpha: 0.3);
        break;
      case StatusBadgeType.error:
        bg = AppColors.errorTint;
        fg = AppColors.error;
        border = AppColors.error.withValues(alpha: 0.3);
        break;
      case StatusBadgeType.info:
        bg = AppColors.lightBlueTint;
        fg = AppColors.primaryBlue;
        border = AppColors.primaryBlue.withValues(alpha: 0.3);
        break;
      case StatusBadgeType.ledger:
        bg = const Color(0xFFF0F4F8);
        fg = const Color(0xFF243B53);
        border = const Color(0xFFBCCCDC);
        break;
      case StatusBadgeType.neutral:
        bg = const Color(0xFFF1F5F9);
        fg = AppColors.textSecondary;
        border = AppColors.border;
        break;
    }

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        child: content,
      );
    }

    return content;
  }
}
