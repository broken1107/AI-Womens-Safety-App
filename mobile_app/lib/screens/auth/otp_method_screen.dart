import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/auth_shell.dart';
import '../../widgets/user_value.dart';
import 'auth_provider_actions.dart';
import 'auth_ui.dart';

class OtpMethodScreen extends StatefulWidget {
  const OtpMethodScreen({
    super.key,
    this.loginChallengeId,
    this.availableMethods,
    this.maskedEmail,
    this.maskedPhone,
  });

  final String? loginChallengeId;
  final List<String>? availableMethods;
  final String? maskedEmail;
  final String? maskedPhone;

  @override
  State<OtpMethodScreen> createState() => _OtpMethodScreenState();
}

class _OtpMethodScreenState extends State<OtpMethodScreen> {
  String? _selectedMethod;
  String? _localError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDefaultMethod();
    });
  }

  void _initDefaultMethod() {
    final data = _resolveArguments(context);
    final methods = data.availableMethods;
    if (_selectedMethod == null && methods.isNotEmpty) {
      setState(() {
        if (methods.contains('email')) {
          _selectedMethod = 'email';
        } else if (methods.contains('sms')) {
          _selectedMethod = 'sms';
        } else {
          _selectedMethod = methods.first;
        }
      });
    }
  }

  ({
    String loginChallengeId,
    List<String> availableMethods,
    String? maskedEmail,
    String? maskedPhone,
  }) _resolveArguments(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final routeArgs = ModalRoute.of(context)?.settings.arguments;

    var challengeId = widget.loginChallengeId ?? auth.loginChallengeId ?? '';
    var methods = widget.availableMethods ?? auth.availableMethods;
    var maskedEmail = widget.maskedEmail ?? auth.maskedEmail;
    var maskedPhone = widget.maskedPhone ?? auth.maskedPhone;

    if (routeArgs is Map<String, dynamic>) {
      if (routeArgs['login_challenge_id'] != null) {
        challengeId = routeArgs['login_challenge_id'].toString();
      }
      if (routeArgs['available_methods'] is List) {
        methods = (routeArgs['available_methods'] as List)
            .map((e) => e.toString())
            .toList();
      }
      if (routeArgs['masked_email'] != null) {
        maskedEmail = routeArgs['masked_email'].toString();
      }
      if (routeArgs['masked_phone'] != null) {
        maskedPhone = routeArgs['masked_phone'].toString();
      }
    }

    return (
      loginChallengeId: challengeId,
      availableMethods: methods,
      maskedEmail: maskedEmail,
      maskedPhone: maskedPhone,
    );
  }

  Future<void> _continue() async {
    final data = _resolveArguments(context);
    if (data.loginChallengeId.isEmpty) {
      setState(() {
        _localError = 'Login session is missing or expired. Please return to login.';
      });
      return;
    }

    if (_selectedMethod == null) {
      setState(() {
        _localError = 'Please select a verification method.';
      });
      return;
    }

    setState(() {
      _localError = null;
      _isSubmitting = true;
    });

    final auth = context.read<AuthProvider>();

    try {
      final result = await sendLoginOtpWithProvider(
        auth,
        loginChallengeId: data.loginChallengeId,
        method: _selectedMethod!,
      );

      if (!mounted) return;

      if (result != null && providerOperationSucceeded(result, auth)) {
        final maskedDestination = result is Map
            ? (result['masked_destination']?.toString() ??
                (_selectedMethod == 'email'
                    ? (data.maskedEmail ?? 'your email')
                    : (data.maskedPhone ?? 'your phone')))
            : (_selectedMethod == 'email'
                ? (data.maskedEmail ?? 'your email')
                : (data.maskedPhone ?? 'your phone'));

        Navigator.of(context).pushNamed(
          '/otp-verification',
          arguments: {
            'login_challenge_id': data.loginChallengeId,
            'method': _selectedMethod,
            'masked_destination': maskedDestination,
            'available_methods': data.availableMethods,
            'masked_email': data.maskedEmail,
            'masked_phone': data.maskedPhone,
          },
        );
      } else {
        final errMsg = providerErrorMessage(auth) ??
            (result is Map ? result['message']?.toString() : null) ??
            'Unable to send verification code. Please try another method.';
        setState(() {
          _localError = errMsg;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _localError = 'Unable to send verification code. Please check your network or try another method.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _resolveArguments(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasEmail = data.availableMethods.contains('email') &&
        (data.maskedEmail != null && data.maskedEmail!.isNotEmpty);
    final hasSms = data.availableMethods.contains('sms') &&
        (data.maskedPhone != null && data.maskedPhone!.isNotEmpty);
    final hasAnyMethod = hasEmail || hasSms;

    return AuthShell(
      showBackButton: true,
      title: 'Verify Your Login',
      subtitle: 'Choose how to receive your OTP',
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final isLoading = _isSubmitting || providerIsLoading(auth);
          final error = _localError ?? providerErrorMessage(auth);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                AuthErrorBanner(message: error),
                const SizedBox(height: 20),
              ],
              if (!hasAnyMethod) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.error.withValues(alpha: .3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No verified email or phone number is available for OTP verification. Please contact support.',
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                if (hasEmail)
                  _buildMethodCard(
                    context: context,
                    methodKey: 'email',
                    icon: Icons.mark_email_read_outlined,
                    iconColor: const Color(0xFF6366F1),
                    title: 'Email',
                    destination: data.maskedEmail ?? 'Verified Email',
                    description: 'Receive a 6-digit verification code by email',
                    isSelected: _selectedMethod == 'email',
                    enabled: !isLoading,
                    onTap: () => setState(() => _selectedMethod = 'email'),
                  ),
                if (hasEmail && hasSms) const SizedBox(height: 14),
                if (hasSms)
                  _buildMethodCard(
                    context: context,
                    methodKey: 'sms',
                    icon: Icons.sms_outlined,
                    iconColor: const Color(0xFF10B981),
                    title: 'SMS',
                    destination: data.maskedPhone ?? 'Verified Phone',
                    description: 'Receive a 6-digit verification code by SMS',
                    isSelected: _selectedMethod == 'sms',
                    enabled: !isLoading,
                    onTap: () => setState(() => _selectedMethod = 'sms'),
                  ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: isLoading,
                  onPressed: (_selectedMethod != null && hasAnyMethod) ? _continue : null,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMethodCard({
    required BuildContext context,
    required String methodKey,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String destination,
    required String description,
    required bool isSelected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: .28)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: .5),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: .12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: .15)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: .6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? colorScheme.primary : iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destination,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : colorScheme.outline,
                    width: isSelected ? 6.5 : 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
