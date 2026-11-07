import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_views.dart';
import '../../data/providers.dart';
import '../../routing/app_routes.dart';

/// Account creation. After success the user is signed in but unverified,
/// so the router moves them to the Verify Email screen automatically.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .register(
            fullName: _name.text,
            email: _email.text,
            password: _password.text,
          );
      if (mounted) context.showSuccess('Account created. Check your inbox!');
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
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    title: 'Create your account',
                    subtitle:
                        'Use your @${AppConstants.studentEmailDomain} or '
                        '@${AppConstants.staffEmailDomain} email.',
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const FieldLabel('Full name'),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    maxLength: AppConstants.nameMaxLength,
                    validator: Validators.fullName,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Amina Hassan',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const FieldLabel('ALU email'),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.aluEmail,
                    decoration: const InputDecoration(
                      hintText: 'you@alustudent.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const FieldLabel('Password'),
                  PasswordField(
                    controller: _password,
                    hint: 'At least 8 characters, with a number',
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: Validators.password,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const FieldLabel('Confirm password'),
                  PasswordField(
                    controller: _confirm,
                    hint: 'Re-enter your password',
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) =>
                        Validators.confirmPassword(v, _password.text),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Create account',
                    isLoading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Wrap (not Row) so it reflows on small screens / large text.
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () =>
                            context.pushReplacement(AppRoutes.login),
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
