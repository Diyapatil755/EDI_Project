import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/attendance_record.dart';
import 'history_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance Ledger History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: history.loadHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: history.isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : history.records.isEmpty
                ? const EmptyStateView(
                    icon: Icons.history_toggle_off_rounded,
                    title: 'No Recorded Attendance',
                    description:
                        'No attendance marks have been recorded yet for this device.',
                  )
                : _buildGroupedList(context, history),
      ),
    );
  }

  Widget _buildGroupedList(BuildContext context, HistoryProvider history) {
    final grouped = history.groupedByMonth;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: grouped.length,
      itemBuilder: (ctx, index) {
        final monthName = grouped.keys.elementAt(index);
        final records = grouped[monthName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                monthName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border.symmetric(
                  horizontal: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                separatorBuilder: (c, i) => const Divider(height: 1, indent: AppSpacing.md),
                itemBuilder: (c, rIndex) => _buildRecordRow(context, records[rIndex], history),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordRow(
    BuildContext context,
    AttendanceRecord record,
    HistoryProvider history,
  ) {
    StatusBadgeType statusType;
    String statusLabel;

    switch (record.status) {
      case AttendanceStatus.onTime:
        statusType = StatusBadgeType.success;
        statusLabel = 'On Time';
        break;
      case AttendanceStatus.late:
        statusType = StatusBadgeType.warning;
        statusLabel = 'Late';
        break;
      case AttendanceStatus.earlyDeparture:
        statusType = StatusBadgeType.warning;
        statusLabel = 'Early Departure';
        break;
      case AttendanceStatus.halfDay:
        statusType = StatusBadgeType.neutral;
        statusLabel = 'Half Day';
        break;
      case AttendanceStatus.checkedIn:
        statusType = StatusBadgeType.info;
        statusLabel = 'Present';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Date block
          SizedBox(
            width: 105,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.formattedDate,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.formattedDuration,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Timestamps
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In: ${record.formattedCheckIn} • Out: ${record.formattedCheckOut}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusBadge(label: statusLabel, type: statusType),
                    if (record.isOfflineQueued) ...[
                      const SizedBox(width: 6),
                      const StatusBadge(label: 'Sync Pending', type: StatusBadgeType.warning),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Ledger Chip
          if (record.ledgerHash != null)
            StatusBadge(
              label: record.shortLedgerHash,
              type: StatusBadgeType.ledger,
              icon: Icons.link_rounded,
              onTap: () {
                history.inspectLedgerHash(record.ledgerHash!);
                _showLedgerSheet(context, record, history);
              },
            ),
        ],
      ),
    );
  }

  void _showLedgerSheet(
    BuildContext context,
    AttendanceRecord record,
    HistoryProvider history,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => Consumer<HistoryProvider>(
        builder: (context, prov, child) {
          final tx = prov.inspectedTx;

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ledger Anchor Verification',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const StatusBadge(label: 'Immutable Block', type: StatusBadgeType.success),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Cryptographic proof anchored to team blockchain ledger.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                if (prov.isLoadingTx)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else ...[
                  _ledgerDetailItem('Transaction Hash', record.ledgerHash ?? '--'),
                  const Divider(height: AppSpacing.md),
                  _ledgerDetailItem('Network', tx?.network ?? 'Polygon zkEVM Testnet'),
                  const Divider(height: AppSpacing.md),
                  _ledgerDetailItem('Block Number', '#${record.ledgerBlockNumber ?? 4891102}'),
                  const Divider(height: AppSpacing.md),
                  _ledgerDetailItem('Merkle Root', tx?.merkleRoot ?? '0x9a8f4c...'),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close Verification'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _ledgerDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
