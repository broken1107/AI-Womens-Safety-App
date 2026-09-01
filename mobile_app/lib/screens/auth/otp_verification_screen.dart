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
    this.isPasswordReset = false,
  });

  final String? email;
  final bool isPasswordReset;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _codeLength = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  ({String email, bool isPasswordReset}) _arguments(BuildContext context) {
    final routeArguments = ModalRoute.of(context)?.settings.arguments;
    var email = widget.email ?? '';
    var isPasswordReset = widget.isPasswordReset;
    if (routeArguments is String) {
      email = routeArguments;
    } else if (routeArguments is Map) {
      final mappedEmail = routeArguments['email'];
      if (mappedEmail != null) email = mappedEmail.toString();
      isPasswordReset = routeArguments['purpose'] == 'passwordReset';
    }
    return (email: email, isPasswordReset: isPasswordReset);
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
    final args = _arguments(context);
    if (args.email.isEmpty) {
      _showMessage('Your email address is missing. Please start again.');
      return;
    }
    if (_code.length != _codeLength) {
      _showMessage('Enter the complete $_codeLength-digit verification code.');
      return;
    }
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    try {
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
        _showMessage(
          providerErrorMessage(auth) ?? 'That code could not be verified.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          providerErrorMessage(auth) ?? 'That code could not be verified.',
        );
      }
    }
  }

  Future<void> _resend() async {
    final args = _arguments(context);
    if (args.email.isEmpty || _isResending) return;
    setState(() => _isResending = true);
    try {
      final auth = context.read<AuthProvider>();
      final result = await resendOtpWithProvider(auth, args.email);
      if (!mounted) return;
      if (result != null && !providerOperationSucceeded(result, auth)) {
        _showMessage(
          providerErrorMessage(auth) ?? 'Unable to resend the code.',
        );
      } else {
        _showMessage('A new verification code has been sent.');
      }
    } catch (_) {
      if (mounted) _showMessage('Unable to resend the code.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final args = _arguments(context);
    return AuthShell(
      showBackButton: true,
      title: 'Verify your email',
      subtitle: args.email.isEmpty
          ? 'Enter the code we sent to your email.'
          : 'Enter the 6-digit code sent to ${args.email}.',
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final isLoading = providerIsLoading(auth);
          final error = providerErrorMessage(auth);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) AuthErrorBanner(message: error),
              if (error != null) const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_codeLength, (index) {
                  return SizedBox(
                    width: 42,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      enabled: !isLoading,
                      autofocus: index == 0,
                      maxLength: _codeLength,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      textInputAction: index == _codeLength - 1
                          ? TextInputAction.done
                          : TextInputAction.next,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(counterText: ''),
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
                label: 'Verify code',
                icon: Icons.verified_user_outlined,
                isLoading: isLoading,
                onPressed: _verify,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Did not receive a code?'),
                  TextButton(
                    onPressed: isLoading || _isResending ? null : _resend,
                    child: Text(_isResending ? 'Sending…' : 'Resend'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
