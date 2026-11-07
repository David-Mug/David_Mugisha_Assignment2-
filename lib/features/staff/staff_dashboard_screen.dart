import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../models/incident_category.dart';
import '../../models/incident_status.dart';
import '../reports/widgets/incident_list_widgets.dart';

/// Staff-only overview of every report, with counts and filters.
///
/// The router blocks students from this route, and Firestore rules block
/// non-staff from changing statuses, so hiding it is not the only guard.
class StaffDashboardScreen extends ConsumerStatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  ConsumerState<StaffDashboardScreen> createState() =>
      _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends ConsumerState<StaffDashboardScreen> {
  /// Defaults to the queue that needs action first.
  IncidentStatus? _status = IncidentStatus.submitted;
  IncidentCategory? _category;

  @override
  Widget build(BuildContext context) {
    // One live query for everything; counts and filters are worked out on
    // the device so the stat tiles stay correct whatever filter is chosen.
    final all = ref.watch(incidentsProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Dashboard')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSpacing.screen,
            child: StatusStatsRow(
              incidents: all.value ?? const [],
              onTap: (s) => setState(() => _status = s),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StatusFilterChips(
            selected: _status,
            onChanged: (s) => setState(() => _status = s),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: AppSpacing.screen,
            child: DropdownButtonFormField<IncidentCategory?>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.filter_list_rounded),
                isDense: true,
              ),
              onChanged: (c) => setState(() => _category = c),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All categories'),
                ),
                for (final c in IncidentCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: IncidentListView(
              incidents: all,
              filter: (i) =>
                  (_status == null || i.status == _status) &&
                  (_category == null || i.category == _category),
              emptyTitle: 'Nothing here',
              emptyMessage: _status == IncidentStatus.submitted
                  ? 'No new reports are waiting. Nice work!'
                  : 'No reports match these filters.',
              onRetry: () => ref.invalidate(incidentsProvider(null)),
            ),
          ),
        ],
      ),
    );
  }
}
