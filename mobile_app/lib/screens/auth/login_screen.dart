import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_shell.dart';
import '../../widgets/user_value.dart';
import 'auth_provider_actions.dart';
import 'auth_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final password = _passwordController.text;

    try {
      final result = await loginWithProvider(
        auth,
        email: _emailController.text.trim(),
        password: password,
        rememberMe: _rememberMe,
      );

      // Securely clear password from field memory immediately
      _passwordController.clear();

      if (!mounted) return;

      if (result is Map) {
        final isOtpRequired = result['otp_required'] == true;
        final challengeId = result['login_challenge_id']?.toString();

        if (isOtpRequired && challengeId != null) {
          final availableMethods = (result['available_methods'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['email'];

          Navigator.of(context).pushNamed(
            '/otp-method',
            arguments: {
              'login_challenge_id': challengeId,
              'available_methods': availableMethods,
              'masked_email': result['masked_email']?.toString(),
              'masked_phone': result['masked_phone']?.toString(),
            },
          );
          return;
        }
      }

      if (providerOperationSucceeded(result, auth)) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      } else {
        _showMessage(
          providerErrorMessage(auth) ?? 'Unable to sign in. Please check your credentials.',
        );
      }
    } catch (_) {
      if (mounted) {
        _passwordController.clear();
        _showMessage(
          providerErrorMessage(auth) ??
              'Unable to sign in. Check your connection and try again.',
        );
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Welcome back',
      subtitle: 'Sign in to keep your safety tools within reach.',
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
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  validator: validateEmail,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: validatePassword,
                  onFieldSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _rememberMe,
                        onChanged: isLoading
                            ? null
                            : (value) =>
                                  setState(() => _rememberMe = value ?? false),
                        title: const Text('Remember me'),
                      ),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(
                              context,
                            ).pushNamed('/forgot-password'),
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Sign in',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('New to Safety Guardian?'),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pushNamed('/register'),
                      child: const Text('Create account'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
