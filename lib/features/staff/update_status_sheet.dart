import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/providers.dart';
import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../models/incident_status.dart';

/// Opens the staff "Update status" bottom sheet.
Future<void> showUpdateStatusSheet(
  BuildContext context, {
  required Incident incident,
  required AppUser staff,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // lets the sheet move up with the keyboard
    showDragHandle: true,
    builder: (_) => UpdateStatusSheet(incident: incident, staff: staff),
  );
}

/// Lets staff pick the next status (only the allowed ones are offered) and
/// leave an optional note that the reporter will see on the timeline.
class UpdateStatusSheet extends ConsumerStatefulWidget {
  const UpdateStatusSheet({
    super.key,
    required this.incident,
    required this.staff,
  });

  final Incident incident;
  final AppUser staff;

  @override
  ConsumerState<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends ConsumerState<UpdateStatusSheet> {
  final _note = TextEditingController();
  late IncidentStatus _selected;
  bool _saving = false;

  /// Allowed next statuses, in timeline order.
  late final List<IncidentStatus> _options = IncidentStatus.values
      .where(widget.incident.status.canTransitionTo)
      .toList();

  @override
  void initState() {
    super.initState();
    // Pre-select the natural "next step" if there is one.
    _selected = _options.firstWhere(
      (s) => s.step > widget.incident.status.step,
      orElse: () => _options.first,
    );
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(incidentRepositoryProvider)
          .updateStatus(
            incidentId: widget.incident.id,
            next: _selected,
            staff: widget.staff,
            note: _note.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      context.showSuccess('Status updated to ${_selected.label}.');
    } on AppException catch (e) {
      if (mounted) context.showError(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update status', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text('Currently ', style: theme.textTheme.bodyMedium),
                StatusChip(widget.incident.status, compact: true),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const FieldLabel('Move to'),
            RadioGroup<IncidentStatus>(
              groupValue: _selected,
              onChanged: (s) {
                if (s != null) setState(() => _selected = s);
              },
              child: Column(
                children: [
                  for (final status in _options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: RadioListTile<IncidentStatus>(
                        value: status,
                        title: Text(status.label),
                        subtitle: Text(_describe(status)),
                        activeColor: status.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: BorderSide(
                            color: _selected == status
                                ? status.color
                                : AppColors.border,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const FieldLabel('Note for the reporter', optional: true),
            TextField(
              controller: _note,
              maxLines: 3,
              maxLength: AppConstants.statusNoteMaxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Plumber assigned, expected fix by Friday',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(label: 'Save', isLoading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }

  String _describe(IncidentStatus target) {
    final from = widget.incident.status;
    if (target.step < from.step) {
      return target == IncidentStatus.inProgress
          ? 'Re-open: the issue is not fully fixed'
          : 'Move back to the queue';
    }
    return switch (target) {
      IncidentStatus.inProgress => 'Someone is working on it',
      IncidentStatus.resolved => 'The issue has been fixed',
      IncidentStatus.submitted => 'Waiting to be reviewed',
    };
  }
}
