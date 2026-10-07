import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_banner.dart';
import '../auth/auth_provider.dart';
import 'home_provider.dart';
import 'widgets/device_security_card.dart';
import 'widgets/dominant_status_card.dart';
import 'widgets/geofence_status_card.dart';
import 'widgets/punch_details_card.dart';
import 'widgets/telemetry_simulation_sheet.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToFace;

  const HomeScreen({super.key, required this.onNavigateToFace});

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final auth = context.watch<AppAuthProvider>();
    final employee = auth.currentEmployee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              employee?.fullName ?? 'Aarav Deshmukh',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${employee?.employeeId ?? "EMP-0417"} • ${AppConstants.organizationName}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20),
            tooltip: 'Security Telemetry Simulation',
            onPressed: () => showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              builder: (_) => TelemetrySimulationSheet(home: home),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: home.refreshLocation,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!home.isOnline) ...[
                  const AppBanner(
                    type: AppBannerType.offline,
                    title: 'Offline Mode Active',
                    message:
                        'Local cache active. Marks will be queued and verified when internet resumes.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                DominantStatusCard(home: home, onNavigateToFace: onNavigateToFace),
                const SizedBox(height: AppSpacing.md),
                PunchDetailsCard(home: home, today: home.todayRecord),
                const SizedBox(height: AppSpacing.md),
                GeofenceStatusCard(home: home),
                const SizedBox(height: AppSpacing.md),
                DeviceSecurityCard(home: home, auth: auth),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
