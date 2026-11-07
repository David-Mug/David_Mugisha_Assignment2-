import 'package:flutter/material.dart';

import '../../models/incident_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Colours associated with each status, shared by chips, stats and timeline.
extension IncidentStatusColors on IncidentStatus {
  Color get color => switch (this) {
    IncidentStatus.submitted => AppColors.warning,
    IncidentStatus.inProgress => AppColors.primary,
    IncidentStatus.resolved => AppColors.success,
  };

  Color get softColor => switch (this) {
    IncidentStatus.submitted => AppColors.warningSoft,
    IncidentStatus.inProgress => AppColors.primarySoft,
    IncidentStatus.resolved => AppColors.successSoft,
  };
}

/// Pill-shaped status label, e.g. a yellow "Submitted" badge.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.compact = false});

  final IncidentStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: ${status.label}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 3 : 6,
        ),
        decoration: BoxDecoration(
          color: status.softColor,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            color: status.color,
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
