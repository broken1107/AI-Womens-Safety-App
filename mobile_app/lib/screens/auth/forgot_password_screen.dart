import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_shell.dart';
import '../../widgets/user_value.dart';
import 'auth_ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _showMessage(
      'Password reset is not available yet. Please contact support to recover your account.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBackButton: true,
      title: 'Reset your password',
      subtitle: 'Enter your email so we can help you recover your account.',
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final isLoading = providerIsLoading(auth);
          final error = providerErrorMessage(auth);
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error != null) AuthErrorBanner(message: error),
                if (error != null) const SizedBox(height: 16),
                AppTextField(
                  controller: _emailController,
                  label: 'Email address',
                  hint: 'you@example.com',
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  validator: validateEmail,
                  onFieldSubmitted: (_) => _sendCode(),
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: 'Request account help',
                  icon: Icons.mark_email_read_outlined,
                  isLoading: isLoading,
                  onPressed: _sendCode,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.maybePop(context),
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
