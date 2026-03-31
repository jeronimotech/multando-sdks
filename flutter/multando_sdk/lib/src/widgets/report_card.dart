import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/report.dart';

/// A Material card widget that displays a summary of a report.
///
/// Shows the short ID, infraction name (passed via [infractionName]),
/// status badge, vehicle plate, and date.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    this.infractionName,
    this.onTap,
  });

  /// The report summary to display.
  final ReportSummary report;

  /// Human-readable infraction name. When `null` the raw [report.infractionId]
  /// is shown instead.
  final String? infractionName;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortId = report.id.length > 8
        ? report.id.substring(0, 8).toUpperCase()
        : report.id.toUpperCase();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: short id + status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#$shortId',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  _StatusBadge(status: report.status),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: infraction name
              Text(
                infractionName ?? report.infractionId,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Row 3: plate + date
              Row(
                children: [
                  Icon(Icons.directions_car_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    report.plateNumber,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.calendar_today_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(report.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusMeta(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (String, Color) _statusMeta(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return ('Draft', const Color(0xFF9E9E9E));
      case ReportStatus.submitted:
        return ('Submitted', const Color(0xFF3B5EEF));
      case ReportStatus.underReview:
        return ('Under Review', const Color(0xFFF59E0B));
      case ReportStatus.verified:
        return ('Verified', const Color(0xFF10B981));
      case ReportStatus.rejected:
        return ('Rejected', const Color(0xFFEF4444));
      case ReportStatus.appealed:
        return ('Appealed', const Color(0xFFF59E0B));
      case ReportStatus.resolved:
        return ('Resolved', const Color(0xFF10B981));
    }
  }
}
