import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/incident.dart';
import '../../../models/status_change.dart';

/// Vertical timeline of every status change, oldest at the top.
///
/// Built from the `statusHistory` sub-collection, so it also shows steps
/// that were later undone (e.g. a report that was re-opened) and any notes
/// staff left.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({
    super.key,
    required this.incident,
    required this.history,
  });

  final Incident incident;
  final List<StatusChange> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Text(
        'Submitted ${AppDateFormat.relative(incident.createdAt)}',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      children: [
        for (var i = 0; i < history.length; i++)
          _TimelineEntry(change: history[i], isLast: i == history.length - 1),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.change, required this.isLast});

  final StatusChange change;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = change.toStatus.color;
    final isFirst = change.fromStatus == null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dot + connecting line.
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: change.toStatus.softColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: isLast
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFirst
                        ? 'Report submitted'
                        : 'Moved to ${change.toStatus.label}',
                    style: theme.textTheme.titleSmall?.copyWith(color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isFirst
                        ? AppDateFormat.compact(change.changedAt)
                        : '${AppDateFormat.compact(change.changedAt)} · '
                              'by ${change.changedByName}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (!isFirst && change.note.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        change.note,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
