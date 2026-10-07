import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../home_provider.dart';

class TelemetrySimulationSheet extends StatelessWidget {
  final HomeProvider home;

  const TelemetrySimulationSheet({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Telemetry Simulation (Demo / Team)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Simulate hostile or non-compliant states to verify server-side rejection logic:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            dense: true,
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Simulate Outside Geofence (140 m)'),
            trailing: Switch(
              value: (home.currentLocation?.distanceToOfficeMeters ?? 0) > 100,
              onChanged: (val) {
                home.toggleGeofenceSimulation(!val);
                Navigator.pop(context);
              },
            ),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.gps_off_rounded),
            title: const Text('Simulate Virtual / Mock GPS'),
            trailing: Switch(
              value: home.currentLocation?.isMockLocation ?? false,
              onChanged: (val) {
                home.toggleMockLocationSimulation(val);
                Navigator.pop(context);
              },
            ),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.phone_android),
            title: const Text('Simulate Unregistered / Rogue Phone'),
            trailing: Switch(
              value: home.deviceService.isSimulationMismatched,
              onChanged: (val) {
                home.toggleDeviceMismatchSimulation(val);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
