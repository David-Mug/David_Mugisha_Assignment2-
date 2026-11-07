import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../models/incident_status.dart';
import 'widgets/incident_list_widgets.dart';

/// Incidents the signed-in user reported, with a status filter.
class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  IncidentStatus? _status;

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(myIncidentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: Column(
        children: [
          StatusFilterChips(
            selected: _status,
            onChanged: (s) => setState(() => _status = s),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: IncidentListView(
              incidents: incidents,
              // The list is already small (one user's reports), so filtering
              // on the device avoids a second Firestore query and index.
              filter: _status == null ? null : (i) => i.status == _status,
              emptyTitle: _status == null
                  ? 'No reports yet'
                  : 'No ${_status!.label.toLowerCase()} reports',
              emptyMessage: 'Reports you submit will appear here.',
              onRetry: () => ref.invalidate(myIncidentsProvider),
            ),
          ),
        ],
      ),
    );
  }
}
