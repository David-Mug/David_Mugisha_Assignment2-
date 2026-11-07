import 'package:flutter/material.dart';

import '../../models/incident.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import 'status_chip.dart';

/// List row for an incident: thumbnail, title, location, age and status.
/// Used on Home, Reports, My Reports and the Staff dashboard.
class IncidentCard extends StatelessWidget {
  const IncidentCard({super.key, required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              IncidentThumbnail(incident: incident, size: 64),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      incident.location.label,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppDateFormat.relative(incident.createdAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(incident.status, compact: true),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square photo of the incident, or its category icon if there is no photo.
class IncidentThumbnail extends StatelessWidget {
  const IncidentThumbnail({super.key, required this.incident, this.size = 64});

  final Incident incident;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: Icon(
        incident.category.icon,
        color: AppColors.primary,
        size: size * 0.42,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox.square(
        dimension: size,
        child: incident.hasPhoto
            ? Image.network(
                incident.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Container(color: AppColors.primarySoft),
              )
            : fallback,
      ),
    );
  }
}
