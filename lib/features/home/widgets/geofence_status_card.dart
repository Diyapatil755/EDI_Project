import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import 'home_provider.dart';

class GeofenceStatusCard extends StatelessWidget {
  final HomeProvider home;

  const GeofenceStatusCard({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    final location = home.currentLocation;
    final isInside = location?.isInsideGeofence ?? true;
    final isMock = location?.isMockLocation ?? false;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OFFICE GEOFENCE TELEMETRY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
              StatusBadge(
                label: isMock
                    ? 'Mock GPS'
                    : isInside
                        ? 'Inside Boundary'
                        : 'Outside Boundary',
                type: isMock
                    ? StatusBadgeType.error
                    : isInside
                        ? StatusBadgeType.success
                        : StatusBadgeType.error,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            location?.locationDescription ?? 'Inside office – 35 m from office',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Target: VIT Pune Campus • Perimeter radius: ${AppConstants.geofenceRadiusMeters.toInt()} m',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
