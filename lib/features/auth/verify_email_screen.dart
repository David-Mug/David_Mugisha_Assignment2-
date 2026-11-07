import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_views.dart';
import '../../data/providers.dart';

/// Shown to signed-in users whose email isn't verified yet.
///
/// Checks every few seconds whether they've clicked the link. As soon as
/// Firebase reports `emailVerified`, the auth stream changes and the router
/// moves them into the app — this screen never navigates by itself.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _resendCooldown = 30;

  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _secondsLeft = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// [showResult] is true when the user tapped the button themselves.
  Future<void> _check({bool showResult = false}) async {
    if (_checking) return;
    setState(() => _checking = showResult);
    try {
      final verified = await ref.read(authRepositoryProvider).reloadUser();
      if (verified) {
        // Re-subscribe to the auth stream so it emits the now-verified user
        // even on platforms where reload() doesn't trigger userChanges.
        ref.invalidate(authStateProvider);
        return;
      }
      if (showResult && mounted) {
        context.showError(
          'Not verified yet. Click the link in the email first.',
        );
      }
    } on AppException catch (e) {
      if (showResult && mounted) context.showError(e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).resendVerificationEmail();
      if (!mounted) return;
      context.showSuccess('Verification email sent.');
      setState(() => _secondsLeft = _resendCooldown);
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 0) t.cancel();
      });
    } on AppException catch (e) {
      if (mounted) context.showError(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = ref.watch(authStateProvider).value?.email ?? 'your email';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 64),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Verify your email',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text.rich(
                TextSpan(
                  text: 'We sent a verification link to\n',
                  children: [
                    TextSpan(
                      text: email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(
                      text:
                          '\n\nOpen it to activate your account. '
                          'Check your spam folder if you cannot find it.',
                    ),
                  ],
                ),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: "I've verified my email",
                isLoading: _checking,
                onPressed: () => _check(showResult: true),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: _secondsLeft > 0 ? null : _resend,
                child: Text(
                  _secondsLeft > 0
                      ? 'Resend email in ${_secondsLeft}s'
                      : 'Resend email',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                child: const Text('Use a different account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
