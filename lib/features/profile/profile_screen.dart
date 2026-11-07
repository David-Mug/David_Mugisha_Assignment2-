import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/photo_picker.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/providers.dart';
import '../../models/app_user.dart';
import '../../routing/app_routes.dart';

/// Profile tab: photo, name, role, shortcuts and sign out.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;

  Future<void> _changePhoto(AppUser user) async {
    final bytes = await pickPhoto(context);
    if (bytes == null) return;
    setState(() => _uploading = true);
    try {
      final url = await ref
          .read(storageRepositoryProvider)
          .uploadProfilePhoto(uid: user.uid, bytes: bytes);
      // Same file path every time, so add a version to force a refresh of
      // the cached image.
      final versioned = '$url&v=${DateTime.now().millisecondsSinceEpoch}';
      await ref
          .read(userRepositoryProvider)
          .updateProfile(user.uid, photoUrl: versioned);
      if (mounted) context.showSuccess('Profile photo updated.');
    } on AppException catch (e) {
      if (mounted) context.showError(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _editName(AppUser user) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(initial: user.fullName),
    );
    if (name == null || name.trim() == user.fullName) return;
    try {
      await ref
          .read(userRepositoryProvider)
          .updateProfile(user.uid, fullName: name);
      if (mounted) context.showSuccess('Name updated.');
    } on AppException catch (e) {
      if (mounted) context.showError(e.message);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to report.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    // The router notices the sign-out and returns to the Welcome screen.
    if (confirmed ?? false) await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: AppException.from(e).message,
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
        data: (user) => user == null
            ? EmptyStateView(
                icon: Icons.person_off_outlined,
                title: 'Profile not found',
                message: 'Sign out and sign in again to continue.',
                actionLabel: 'Sign out',
                onAction: _signOut,
              )
            : _buildProfile(context, user),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, AppUser user) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, AppSpacing.md, 20, 100),
      children: [
        Center(
          child: Stack(
            children: [
              UserAvatar(user: user, radius: 52),
              if (_uploading)
                const Positioned.fill(
                  child: CircleAvatar(
                    backgroundColor: Colors.black38,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: IconButton.filled(
                  tooltip: 'Change profile photo',
                  onPressed: _uploading ? null : () => _changePhoto(user),
                  icon: const Icon(Icons.photo_camera_outlined, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          user.fullName,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          user.email,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Chip(
            avatar: Icon(
              user.isStaff ? Icons.badge_outlined : Icons.school_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            label: Text(user.isStaff ? 'Staff' : 'Student'),
            backgroundColor: AppColors.primarySoft,
            side: BorderSide.none,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit name'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _editName(user),
              ),
              const Divider(indent: 56),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('My reports'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.myReports),
              ),
              if (user.isStaff) ...[
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.dashboard_customize_outlined),
                  title: const Text('Staff dashboard'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.staff),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text(
              'Sign out',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: _signOut,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          '${AppConstants.appName} · Member since '
          '${user.createdAt == null ? '—' : user.createdAt!.year}',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initial});

  final String initial;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit name'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: AppConstants.nameMaxLength,
          validator: Validators.fullName,
          onFieldSubmitted: (_) => _save(),
          decoration: const InputDecoration(hintText: 'Full name'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
