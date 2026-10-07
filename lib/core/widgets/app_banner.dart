import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

enum AppBannerType { info, warning, error, offline }

/// Status and notification banner with restrained tint background and 1px border.
class AppBanner extends StatelessWidget {
  final String message;
  final String? title;
  final AppBannerType type;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData? customIcon;

  const AppBanner({
    super.key,
    required this.message,
    this.title,
    this.type = AppBannerType.info,
    this.onAction,
    this.actionLabel,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color fg;
    IconData icon;

    switch (type) {
      case AppBannerType.info:
        bg = AppColors.lightBlueTint;
        border = AppColors.primaryBlue.withValues(alpha: 0.25);
        fg = AppColors.primaryBlue;
        icon = Icons.info_outline;
        break;
      case AppBannerType.warning:
        bg = AppColors.warningTint;
        border = AppColors.warning.withValues(alpha: 0.3);
        fg = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case AppBannerType.error:
        bg = AppColors.errorTint;
        border = AppColors.error.withValues(alpha: 0.3);
        fg = AppColors.error;
        icon = Icons.error_outline;
        break;
      case AppBannerType.offline:
        bg = const Color(0xFFF1F5F9);
        border = const Color(0xFFCBD5E1);
        fg = const Color(0xFF475569);
        icon = Icons.wifi_off_rounded;
        break;
    }

    if (customIcon != null) {
      icon = customIcon!;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: type == AppBannerType.offline
                        ? const Color(0xFF334155)
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: fg,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
