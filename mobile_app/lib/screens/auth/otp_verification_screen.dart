import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/auth_shell.dart';
import '../../widgets/user_value.dart';
import 'auth_provider_actions.dart';
import 'auth_ui.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    this.email,
    this.loginChallengeId,
    this.deliveryMethod,
    this.maskedDestination,
    this.isPasswordReset = false,
  });

  final String? email;
  final String? loginChallengeId;
  final String? deliveryMethod;
  final String? maskedDestination;
  final bool isPasswordReset;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _codeLength = 6;
  static const _resendCooldownSeconds = 45;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  Timer? _timer;
  int _remainingSeconds = _resendCooldownSeconds;
  bool _isResending = false;
  bool _isVerifying = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _remainingSeconds = _resendCooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  ({
    String loginChallengeId,
    String deliveryMethod,
    String maskedDestination,
    String email,
    bool isPasswordReset,
    bool isLoginFlow,
    List<String> availableMethods,
    String? maskedEmail,
    String? maskedPhone,
  }) _resolveArguments(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final routeArguments = ModalRoute.of(context)?.settings.arguments;

    var challengeId = widget.loginChallengeId ?? auth.loginChallengeId ?? '';
    var method = widget.deliveryMethod ?? auth.selectedMethod ?? 'email';
    var maskedDestination = widget.maskedDestination ?? auth.maskedDestination ?? '';
    var email = widget.email ?? '';
    var isPasswordReset = widget.isPasswordReset;
    var availableMethods = auth.availableMethods;
    var maskedEmail = auth.maskedEmail;
    var maskedPhone = auth.maskedPhone;

    if (routeArguments is String) {
      email = routeArguments;
    } else if (routeArguments is Map<String, dynamic>) {
      if (routeArguments['login_challenge_id'] != null) {
        challengeId = routeArguments['login_challenge_id'].toString();
      }
      if (routeArguments['method'] != null) {
        method = routeArguments['method'].toString();
      }
      if (routeArguments['masked_destination'] != null) {
        maskedDestination = routeArguments['masked_destination'].toString();
      }
      if (routeArguments['email'] != null) {
        email = routeArguments['email'].toString();
      }
      if (routeArguments['available_methods'] is List) {
        availableMethods = (routeArguments['available_methods'] as List)
            .map((e) => e.toString())
            .toList();
      }
      if (routeArguments['masked_email'] != null) {
        maskedEmail = routeArguments['masked_email'].toString();
      }
      if (routeArguments['masked_phone'] != null) {
        maskedPhone = routeArguments['masked_phone'].toString();
      }
      isPasswordReset = routeArguments['purpose'] == 'passwordReset';
    }

    final isLoginFlow = challengeId.isNotEmpty;
    if (maskedDestination.isEmpty) {
      if (isLoginFlow) {
        maskedDestination = method == 'email'
            ? (maskedEmail ?? 'your email')
            : (maskedPhone ?? 'your phone');
      } else {
        maskedDestination = email;
      }
    }

    return (
      loginChallengeId: challengeId,
      deliveryMethod: method,
      maskedDestination: maskedDestination,
      email: email,
      isPasswordReset: isPasswordReset,
      isLoginFlow: isLoginFlow,
      availableMethods: availableMethods,
      maskedEmail: maskedEmail,
      maskedPhone: maskedPhone,
    );
  }

  String get _code => _controllers.map((controller) => controller.text).join();

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final characters = value.characters.take(_codeLength).toList();
      for (var i = 0; i < characters.length; i++) {
        _controllers[i].text = characters[i];
      }
      _focusNodes[(characters.length - 1).clamp(0, _codeLength - 1)]
          .requestFocus();
      setState(() {});
      return;
    }
    if (value.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    final args = _resolveArguments(context);

    if (_code.length != _codeLength) {
      setState(() {
        _localError = 'Enter the complete $_codeLength-digit verification code.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();

    setState(() {
      _localError = null;
      _isVerifying = true;
    });

    try {
      if (args.isLoginFlow) {
        final result = await verifyLoginOtpWithProvider(
          auth,
          loginChallengeId: args.loginChallengeId,
          otp: _code,
        );

        if (!mounted) return;

        if (result == true || providerOperationSucceeded(result, auth)) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
        } else {
          setState(() {
            _localError = providerErrorMessage(auth) ??
                'Invalid verification code. Please check and try again.';
          });
        }
      } else {
        // Fallback / Registration Flow
        final result = await verifyOtpWithProvider(
          auth,
          email: args.email,
          otp: _code,
        );

        if (!mounted) return;

        if (providerOperationSucceeded(result, auth)) {
          if (args.isPasswordReset) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
          }
        } else {
          setState(() {
            _localError = providerErrorMessage(auth) ??
                'That code could not be verified.';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _localError = 'Verification failed. Please check your connection and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resend() async {
    final args = _resolveArguments(context);
    if (_remainingSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _localError = null;
    });

    final auth = context.read<AuthProvider>();

    try {
      if (args.isLoginFlow) {
        final result = await resendLoginOtpWithProvider(
          auth,
          loginChallengeId: args.loginChallengeId,
        );

        if (!mounted) return;

        if (result != null && providerOperationSucceeded(result, auth)) {
          _showMessage('A new verification code has been sent.');
          _startCountdown();
          _clearCode();
        } else {
          setState(() {
            _localError = providerErrorMessage(auth) ??
                'Unable to resend verification code. You may change verification method.';
          });
        }
      } else {
        final result = await resendOtpWithProvider(auth, args.email);
        if (!mounted) return;
        if (result != null && !providerOperationSucceeded(result, auth)) {
          setState(() {
            _localError = providerErrorMessage(auth) ??
                'Unable to resend verification code.';
          });
        } else {
          _showMessage('A new verification code has been sent.');
          _startCountdown();
          _clearCode();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _localError = 'Unable to resend code. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _clearCode() {
    for (final controller in _controllers) {
      controller.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
    setState(() {});
  }

  void _changeMethod() {
    final args = _resolveArguments(context);
    _timer?.cancel();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(
        '/otp-method',
        arguments: {
          'login_challenge_id': args.loginChallengeId,
          'available_methods': args.availableMethods,
          'masked_email': args.maskedEmail,
          'masked_phone': args.maskedPhone,
        },
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final args = _resolveArguments(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEmail = args.deliveryMethod == 'email';

    return AuthShell(
      showBackButton: true,
      title: 'Verify Your Login',
      subtitle: isEmail
          ? 'Code sent via 📧 Email'
          : 'Code sent via 📱 SMS',
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final isLoading = _isVerifying || _isResending || providerIsLoading(auth);
          final error = _localError ?? providerErrorMessage(auth);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                AuthErrorBanner(message: error),
                const SizedBox(height: 18),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: .3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEmail ? Icons.mark_email_read_outlined : Icons.sms_outlined,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEmail ? 'Verification Email' : 'Verification SMS',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            args.maskedDestination,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_codeLength, (index) {
                  return SizedBox(
                    width: 44,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      enabled: !isLoading,
                      autofocus: index == 0,
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      textInputAction: index == _codeLength - 1
                          ? TextInputAction.done
                          : TextInputAction.next,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: .4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => _onChanged(index, value),
                      onSubmitted: (_) {
                        if (index == _codeLength - 1) _verify();
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 26),
              AppButton(
                label: 'Verify OTP',
                icon: Icons.verified_user_outlined,
                isLoading: _isVerifying,
                onPressed: _verify,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _remainingSeconds > 0
                        ? 'Resend OTP in ${_remainingSeconds}s'
                        : 'Did not receive code?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_remainingSeconds == 0) ...[
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: isLoading ? null : _resend,
                      child: Text(_isResending ? 'Sending…' : 'Resend OTP'),
                    ),
                  ],
                ],
              ),
              if (args.isLoginFlow) ...[
                const Divider(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: isLoading ? null : _changeMethod,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Change verification method'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
