import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/providers.dart';
import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../staff/update_status_sheet.dart';
import 'widgets/status_timeline.dart';

/// Full details of one incident, updated live.
///
/// Everyone sees the photo, details and timeline. Staff also get an
/// "Update status" button at the bottom.
class IncidentDetailScreen extends ConsumerWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentAsync = ref.watch(incidentProvider(incidentId));
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Report details')),
      body: incidentAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: AppException.from(e).message,
          onRetry: () => ref.invalidate(incidentProvider(incidentId)),
        ),
        data: (incident) => incident == null
            ? const EmptyStateView(
                icon: Icons.search_off_rounded,
                title: 'Report not found',
                message: 'It may have been removed.',
              )
            : _Details(incident: incident, viewer: user),
      ),
      bottomNavigationBar: _staffActions(context, incidentAsync.value, user),
    );
  }

  /// "Update status" button — only built for staff. Firestore rules also
  /// reject status changes from non-staff, so hiding it is just for UX.
  Widget? _staffActions(
    BuildContext context,
    Incident? incident,
    AppUser? user,
  ) {
    if (incident == null || user == null || !user.isStaff) return null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: FilledButton.icon(
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Update status'),
          onPressed: () =>
              showUpdateStatusSheet(context, incident: incident, staff: user),
        ),
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.incident, required this.viewer});

  final Incident incident;
  final AppUser? viewer;

  /// Other students don't see who reported something — only staff and the
  /// reporter themselves do.
  String get _reporterLabel {
    if (viewer?.uid == incident.reporterId) return 'You';
    if (viewer?.isStaff ?? false) return incident.reporterName;
    return 'A campus member';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(statusHistoryProvider(incident.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        if (incident.hasPhoto) ...[
          _Photo(url: incident.photoUrl!),
          const SizedBox(height: AppSpacing.lg),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(incident.title, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusChip(incident.status),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                _InfoRow(
                  icon: incident.category.icon,
                  label: 'Category',
                  value: incident.category.label,
                ),
                _InfoRow(
                  icon: incident.location.icon,
                  label: 'Location',
                  value: incident.locationLabel,
                ),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Reported',
                  value: AppDateFormat.full(incident.createdAt),
                ),
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Reported by',
                  value: _reporterLabel,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Description', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          incident.description,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Progress', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        history.when(
          loading: () => const LoadingView(),
          error: (e, _) => Text(AppException.from(e).message),
          data: (entries) =>
              StatusTimeline(incident: incident, history: entries),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 92,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Incident photo; tap to open it full screen with pinch-to-zoom.
class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Incident photo. Double tap to enlarge.',
      button: true,
      child: GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Center(child: InteractiveViewer(child: Image.network(url))),
                SafeArea(
                  child: IconButton(
                    tooltip: 'Close',
                    color: Colors.white,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : Container(
                      color: AppColors.primarySoft,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
              errorBuilder: (_, _, _) => Container(
                color: AppColors.primarySoft,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
