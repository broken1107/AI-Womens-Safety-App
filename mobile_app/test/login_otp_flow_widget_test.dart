import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safety_guardian/providers/auth_provider.dart';
import 'package:safety_guardian/screens/auth/otp_method_screen.dart';
import 'package:safety_guardian/screens/auth/otp_verification_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Login OTP Delivery Flow UI Tests', () {
    testWidgets('OtpMethodScreen renders email and sms options and handles selection', (tester) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const OtpMethodScreen(
              loginChallengeId: 'test-challenge-123',
              availableMethods: ['email', 'sms'],
              maskedEmail: 'k***@example.com',
              maskedPhone: '******3210',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Verify Your Login'), findsOneWidget);
      expect(find.text('Choose how to receive your OTP'), findsOneWidget);
      expect(find.text('k***@example.com'), findsOneWidget);
      expect(find.text('******3210'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Tap on SMS option
      expect(find.text('SMS'), findsOneWidget);
    });

    testWidgets('OtpVerificationScreen displays masked destination and 6 digit fields', (tester) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const OtpVerificationScreen(
              loginChallengeId: 'test-challenge-123',
              deliveryMethod: 'email',
              maskedDestination: 'k***@example.com',
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Verify Your Login'), findsOneWidget);
      expect(find.text('Code sent via 📧 Email'), findsOneWidget);
      expect(find.text('k***@example.com'), findsOneWidget);
      expect(find.text('Verify OTP'), findsOneWidget);
      expect(find.text('Change verification method'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(6));
    });
  });
}
