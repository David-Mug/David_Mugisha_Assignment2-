import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/incident_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/incident.dart';
import '../../../models/incident_status.dart';
import '../../../routing/app_routes.dart';

/// "All · Submitted · In Progress · Resolved" chips. `null` means All.
class StatusFilterChips extends StatelessWidget {
  const StatusFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final IncidentStatus? selected;
  final ValueChanged<IncidentStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <IncidentStatus?>[null, ...IncidentStatus.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSpacing.screen,
      child: Row(
        children: [
          for (final status in options)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(status?.label ?? 'All'),
                selected: selected == status,
                onSelected: (_) => onChanged(status),
                labelStyle: TextStyle(
                  color: selected == status
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders a live list of incidents with loading, error and empty states.
///
/// [filter] is applied on the device (e.g. search text), after Firestore
/// has returned the documents.
class IncidentListView extends StatelessWidget {
  const IncidentListView({
    super.key,
    required this.incidents,
    required this.emptyTitle,
    required this.emptyMessage,
    this.filter,
    this.onRetry,
  });

  final AsyncValue<List<Incident>> incidents;
  final String emptyTitle;
  final String emptyMessage;
  final bool Function(Incident)? filter;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return incidents.when(
      loading: () => const LoadingView(),
      error: (e, _) =>
          ErrorView(message: AppException.from(e).message, onRetry: onRetry),
      data: (all) {
        final items = filter == null ? all : all.where(filter!).toList();
        if (items.isEmpty) {
          return EmptyStateView(
            icon: Icons.inbox_outlined,
            title: emptyTitle,
            message: emptyMessage,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, AppSpacing.sm, 20, 100),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) => IncidentCard(
            incident: items[i],
            onTap: () => context.push(AppRoutes.incident(items[i].id)),
          ),
        );
      },
    );
  }
}

/// Three tiles with the number of incidents in each status.
class StatusStatsRow extends StatelessWidget {
  const StatusStatsRow({super.key, required this.incidents, this.onTap});

  final List<Incident> incidents;
  final ValueChanged<IncidentStatus>? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final status in IncidentStatus.values) ...[
          if (status != IncidentStatus.values.first)
            const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _StatTile(
              status: status,
              count: incidents.where((i) => i.status == status).length,
              onTap: onTap == null ? null : () => onTap!(status),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.status, required this.count, this.onTap});

  final IncidentStatus status;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$count ${status.label}',
      button: onTap != null,
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$count',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: status.color,
                  ),
                ),
                Text(
                  status.label,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
