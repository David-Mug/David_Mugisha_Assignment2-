import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/photo_picker.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_views.dart';
import '../../data/providers.dart';
import '../../models/campus_location.dart';
import '../../models/incident_category.dart';
import '../../routing/app_routes.dart';

/// The "Report an Incident" form.
///
/// Validation happens in two places: here (instant feedback) and in
/// Firestore Security Rules (the real guarantee).
class NewReportScreen extends ConsumerStatefulWidget {
  const NewReportScreen({super.key});

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _locationDetails = TextEditingController();
  IncidentCategory? _category;
  CampusLocation? _location;
  Uint8List? _photo;
  bool _submitting = false;

  bool get _hasChanges =>
      _title.text.isNotEmpty ||
      _description.text.isNotEmpty ||
      _locationDetails.text.isNotEmpty ||
      _category != null ||
      _location != null ||
      _photo != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _locationDetails.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    final bytes = await pickPhoto(context);
    if (bytes != null) setState(() => _photo = bytes);
  }

  Future<void> _submit() async {
    // `_submitting` + the disabled button stop double submissions.
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      context.showError('Please fix the highlighted fields.');
      return;
    }
    final reporter = ref.read(currentUserProvider).value;
    if (reporter == null) {
      context.showError('Your profile is still loading. Try again shortly.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final id = await ref
          .read(incidentRepositoryProvider)
          .createIncident(
            reporter: reporter,
            title: _title.text,
            description: _description.text,
            category: _category!,
            location: _location!,
            locationDetails: _locationDetails.text,
            photoBytes: _photo,
          );
      if (!mounted) return;
      context.showSuccess('Report submitted. Thank you!');
      // Replace the form with the new report so "back" doesn't reopen it.
      context.pushReplacement(AppRoutes.incident(id));
    } on AppException catch (e) {
      if (mounted) {
        context.showError(e.message);
        setState(() => _submitting = false);
      }
    }
  }

  /// Ask before throwing away a half-filled form.
  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard report?'),
        content: const Text('What you have entered will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges || _submitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Report an Incident')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            // SingleChildScrollView (not ListView) keeps every field built,
            // so Form.validate() checks all of them, even off-screen ones.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FieldLabel('Title'),
                  TextFormField(
                    controller: _title,
                    maxLength: AppConstants.titleMaxLength,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.maxLength(
                      v,
                      AppConstants.titleMaxLength,
                      field: 'Title',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Broken water tap in Block B',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const FieldLabel('Category'),
                  _CategoryPicker(
                    selected: _category,
                    onChanged: (c) => setState(() => _category = c),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const FieldLabel('Location'),
                  DropdownButtonFormField<CampusLocation>(
                    initialValue: _location,
                    isExpanded: true,
                    hint: const Text('Select a campus area'),
                    validator: (v) => v == null ? 'Choose a location' : null,
                    onChanged: (v) => setState(() => _location = v),
                    items: [
                      for (final loc in CampusLocation.values)
                        DropdownMenuItem(
                          value: loc,
                          child: Row(
                            children: [
                              Icon(
                                loc.icon,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Flexible(
                                child: Text(
                                  loc.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _locationDetails,
                    maxLength: AppConstants.locationDetailsMaxLength,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText:
                          'Exact spot (optional), e.g. Room 204, 2nd floor',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const FieldLabel('Description'),
                  TextFormField(
                    controller: _description,
                    maxLines: 5,
                    minLines: 4,
                    maxLength: AppConstants.descriptionMaxLength,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) {
                      final error = Validators.maxLength(
                        v,
                        AppConstants.descriptionMaxLength,
                        field: 'Description',
                      );
                      if (error != null) return error;
                      return v!.trim().length < 10
                          ? 'Please add a few more details'
                          : null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'What happened? Since when? Is anyone at risk?',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const FieldLabel('Photo', optional: true),
                  _PhotoField(
                    photo: _photo,
                    onPick: _submitting ? null : _choosePhoto,
                    onRemove: () => setState(() => _photo = null),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    label: 'Submit report',
                    icon: Icons.send_rounded,
                    isLoading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grid of category chips, wired into the Form so it shows an error when
/// nothing is selected.
class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selected, required this.onChanged});

  final IncidentCategory? selected;
  final ValueChanged<IncidentCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<IncidentCategory>(
      initialValue: selected,
      validator: (_) => selected == null ? 'Choose a category' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final c in IncidentCategory.values)
                ChoiceChip(
                  avatar: Icon(
                    c.icon,
                    size: 18,
                    color: selected == c ? Colors.white : AppColors.primary,
                  ),
                  label: Text(c.label),
                  selected: selected == c,
                  labelStyle: TextStyle(
                    color: selected == c ? Colors.white : AppColors.textPrimary,
                  ),
                  onSelected: (_) {
                    onChanged(c);
                    field.didChange(c);
                  },
                ),
            ],
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, left: 12),
              child: Text(
                field.errorText!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoField extends StatelessWidget {
  const _PhotoField({
    required this.photo,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? photo;
  final VoidCallback? onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (photo == null) {
      return OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add a photo'),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.memory(photo!, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Change photo',
                onPressed: onPick,
                icon: const Icon(Icons.edit_outlined),
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                tooltip: 'Remove photo',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
