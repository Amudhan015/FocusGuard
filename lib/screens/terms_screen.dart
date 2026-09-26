import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_app_bar.dart';

/// Screen for viewing the Terms of Service.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Terms of Service',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'TERMS OF SERVICE\n\n'
            'Last updated: September 13, 2026\n\n'
            '1. ACCEPTANCE OF TERMS\n'
            'By downloading or using the FocusGuard app, you agree to be bound by these '
            'Terms of Service. If you do not agree to these terms, please do not use the app.\n\n'
            '2. DESCRIPTION OF SERVICE\n'
            'FocusGuard is a productivity application designed to help users maintain focus '
            'during study and work sessions by blocking distracting applications and tracking '
            'session data.\n\n'
            '3. USER RESPONSIBILITIES\n'
            'You agree to use the app only for lawful purposes and in accordance with these '
            'Terms. You are responsible for maintaining the confidentiality of your account '
            'and for all activities that occur under your account.\n\n'
            '4. DATA PRIVACY\n'
            'Your session data is stored locally on your device. FocusGuard does not collect '
            'or transmit personal data to external servers without your explicit consent.\n\n'
            '5. DISCLAIMER OF WARRANTIES\n'
            'The app is provided "as is" without warranties of any kind, either express or '
            'implied, including but not limited to merchantability, fitness for a particular '
            'purpose, or non-infringement.\n\n'
            '6. LIMITATION OF LIABILITY\n'
            'In no event shall FocusGuard be liable for any indirect, incidental, special, '
            'consequential, or punitive damages, or any loss of profits or revenues, whether '
            'incurred directly or indirectly.\n\n'
            '7. GOVERNING LAW\n'
            'These Terms shall be governed by and construed in accordance with the laws of '
            'the jurisdiction in which FocusGuard operates.\n\n'
            '8. CHANGES TO TERMS\n'
            'FocusGuard reserves the right to modify or replace these Terms at any time. '
            'If a revision is material, we will provide notice.\n\n'
            '9. CONTACT INFORMATION\n'
            'If you have any questions about these Terms, please contact us through the app.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}