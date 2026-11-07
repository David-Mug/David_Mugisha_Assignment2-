import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_views.dart';
import '../../data/providers.dart';

/// Sends a Firebase password-reset email.
///
/// The confirmation message is the same whether or not the account exists,
/// so the screen can't be used to discover who has an account.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AppException catch (e) {
      if (mounted) context.showError(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          child: _sent ? _buildSent(context) : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Reset your password',
            subtitle: "Enter your ALU email and we'll send you a reset link.",
          ),
          const SizedBox(height: AppSpacing.xxl),
          const FieldLabel('Email'),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.aluEmail,
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'you@alustudent.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Send reset link',
            isLoading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildSent(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        const Icon(
          Icons.mark_email_read_outlined,
          size: 72,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Check your email',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'If an account exists for ${_email.text.trim()}, a password reset '
          'link is on its way. Remember to check your spam folder.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        FilledButton(
          onPressed: () => context.pop(),
          child: const Text('Back to sign in'),
        ),
      ],
    );
  }
}
