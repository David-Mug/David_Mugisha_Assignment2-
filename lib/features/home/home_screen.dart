import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/incident_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/providers.dart';
import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../routing/app_routes.dart';
import '../reports/widgets/incident_list_widgets.dart';

/// Home tab.
///
/// Students see a summary of *their own* reports; staff see the whole
/// campus plus a shortcut to the staff dashboard.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isStaff = user?.isStaff ?? false;
    final incidents = isStaff
        ? ref.watch(incidentsProvider(null))
        : ref.watch(myIncidentsProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, AppSpacing.lg, 20, 100),
          children: [
            _Greeting(user: user),
            const SizedBox(height: AppSpacing.xl),
            const _ReportHeroCard(),
            if (isStaff) ...[
              const SizedBox(height: AppSpacing.lg),
              const _StaffShortcut(),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text(
              isStaff ? 'Campus overview' : 'My reports at a glance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            incidents.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: LoadingView(),
              ),
              error: (e, _) => ErrorView(
                message: 'Could not load reports.',
                onRetry: () => isStaff
                    ? ref.invalidate(incidentsProvider(null))
                    : ref.invalidate(myIncidentsProvider),
              ),
              data: (list) => _Summary(incidents: list, isStaff: isStaff),
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${user?.firstName ?? 'there'} 👋',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(
                user?.isStaff ?? false
                    ? "Here's what needs attention on campus."
                    : 'Let\'s keep our campus safe and working.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.profile),
          child: UserAvatar(user: user, radius: 24),
        ),
      ],
    );
  }
}

class _ReportHeroCard extends StatelessWidget {
  const _ReportHeroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'See something wrong?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Broken tap, power cut, safety hazard — report it in '
                  'under a minute.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.newReport),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Report an incident'),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(
            Icons.campaign_rounded,
            size: 72,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ],
      ),
    );
  }
}

class _StaffShortcut extends StatelessWidget {
  const _StaffShortcut();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        leading: const CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          child: Icon(
            Icons.dashboard_customize_outlined,
            color: AppColors.primary,
          ),
        ),
        title: const Text('Staff dashboard'),
        subtitle: const Text('Review reports and update their status'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(AppRoutes.staff),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.incidents, required this.isStaff});

  final List<Incident> incidents;
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    final recent = incidents.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusStatsRow(incidents: incidents),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: isStaff ? 'Latest campus reports' : 'Recent reports',
          onSeeAll: incidents.isEmpty
              ? null
              : () => isStaff
                    ? context.go(AppRoutes.reports)
                    : context.push(AppRoutes.myReports),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (recent.isEmpty)
          const EmptyStateView(
            icon: Icons.inbox_outlined,
            title: 'No reports yet',
            message: 'When you report an incident it will show up here.',
          )
        else
          for (final incident in recent) ...[
            IncidentCard(
              incident: incident,
              onTap: () => context.push(AppRoutes.incident(incident.id)),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}
