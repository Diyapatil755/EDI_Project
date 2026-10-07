import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outlined, danger }

/// Standard button component adhering to 48dp touch targets and flat visual language.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonVariant variant;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    BorderSide borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = isEnabled ? AppColors.primaryBlue : AppColors.primaryBlue.withValues(alpha: 0.5);
        fg = Colors.white;
        borderSide = BorderSide.none;
        break;
      case AppButtonVariant.secondary:
        bg = isEnabled ? AppColors.lightBlueTint : AppColors.lightBlueTint.withValues(alpha: 0.5);
        fg = AppColors.primaryBlue;
        borderSide = const BorderSide(color: AppColors.border, width: 1);
        break;
      case AppButtonVariant.outlined:
        bg = Colors.transparent;
        fg = isEnabled ? AppColors.primaryBlue : AppColors.textMuted;
        borderSide = const BorderSide(color: AppColors.border, width: 1);
        break;
      case AppButtonVariant.danger:
        bg = isEnabled ? AppColors.error : AppColors.error.withValues(alpha: 0.5);
        fg = Colors.white;
        borderSide = BorderSide.none;
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else {
      content = Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: fg,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: AppSpacing.minTouchTarget,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: content,
          ),
        ),
      ),
    );
  }
}
