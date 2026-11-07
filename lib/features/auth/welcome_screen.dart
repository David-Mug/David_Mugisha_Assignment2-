import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/form_fields.dart';
import '../../routing/app_routes.dart';

/// First screen for signed-out users: what the app does + Sign in / Register.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: AppSpacing.screen,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(),
                    const AppLogo(size: 96),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Report campus issues in seconds and follow them '
                      'until they are fixed.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const _Feature(
                      icon: Icons.add_a_photo_outlined,
                      title: 'Report with a photo',
                      text: 'Describe the problem, where it is, and snap a picture.',
                    ),
                    const _Feature(
                      icon: Icons.timeline_rounded,
                      title: 'Track progress',
                      text: 'See when staff start working on it and when it is resolved.',
                    ),
                    const _Feature(
                      icon: Icons.verified_user_outlined,
                      title: 'ALU accounts only',
                      text:
                          'Sign in with your @${AppConstants.studentEmailDomain} '
                          'or @${AppConstants.staffEmailDomain} email.',
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: () => context.push(AppRoutes.login),
                      child: const Text('Sign in'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                      onPressed: () => context.push(AppRoutes.register),
                      child: const Text('Create an account'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
