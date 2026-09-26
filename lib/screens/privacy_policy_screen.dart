import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_app_bar.dart';

/// Screen for viewing the Privacy Policy.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: 'Privacy Policy',
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            kToolbarHeight + MediaQuery.of(context).padding.top + AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: const Text(
            'PRIVACY POLICY\n\n'
            'Last updated: September 13, 2026\n\n'
            '1. INFORMATION WE COLLECT\n'
            'FocusGuard collects minimal information necessary to provide its services. '
            'This includes:\n'
            '• Session data (start/end times, duration, subject tags)\n'
            '• App usage statistics (for blocking functionality)\n'
            '• Session photos and ratings (stored locally only)\n'
            '• User preferences and settings\n\n'
            '2. HOW WE USE YOUR INFORMATION\n'
            'The information we collect is used solely to:\n'
            '• Provide core app functionality (session tracking, app blocking)\n'
            '• Generate personal productivity statistics\n'
            '• Remember your preferences and settings\n'
            '• Improve the app experience (locally, not transmitted)\n\n'
            '3. DATA STORAGE AND SECURITY\n'
            'All data is stored locally on your device. FocusGuard does not transmit '
            'personal data to external servers. Data is secured using Android\'s/iOS\'s '
            'built-in storage protections.\n\n'
            '4. DATA SHARING\n'
            'FocusGuard does not share your personal data with any third parties. '
            'All session data, photos, and ratings remain on your device unless you '
            'choose to export them manually.\n\n'
            '5. CHILDREN\'S PRIVACY\n'
            'FocusGuard is not intended for children under 13 years of age. '
            'We do not knowingly collect personal information from children.\n\n'
            '6. YOUR RIGHTS\n'
            'You have the right to:\n'
            '• Access your data stored in the app\n'
            '• Delete your data at any time\n'
            '• Export your data for personal use\n'
            '• Opt out of data collection by not using the app\n\n'
            '7. CHANGES TO THIS PRIVACY POLICY\n'
            'We may update our Privacy Policy from time to time. We will notify you '
            'of any changes by posting the new Privacy Policy on this page.\n\n'
            '8. CONTACT US\n'
            'If you have any questions about this Privacy Policy, please contact us '
            'through the app.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}