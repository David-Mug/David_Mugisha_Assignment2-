import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../models/incident.dart';
import '../../models/incident_status.dart';
import 'widgets/incident_list_widgets.dart';

/// "Reports" tab: every incident reported on campus, newest first.
///
/// The status filter is done by Firestore (a `where` query); the search box
/// filters the results on the device, because Firestore has no full-text
/// search.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  IncidentStatus? _status;
  String _query = '';

  bool _matches(Incident i) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return i.title.toLowerCase().contains(q) ||
        i.locationLabel.toLowerCase().contains(q) ||
        i.category.label.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(incidentsProvider(_status));
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Reports')),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.screen,
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search by title, place or category',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StatusFilterChips(
            selected: _status,
            onChanged: (s) => setState(() => _status = s),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: IncidentListView(
              incidents: incidents,
              filter: _matches,
              emptyTitle: 'No reports found',
              emptyMessage: _query.isEmpty
                  ? 'Nothing has been reported here yet.'
                  : 'Try a different search.',
              onRetry: () => ref.invalidate(incidentsProvider(_status)),
            ),
          ),
        ],
      ),
    );
  }
}
