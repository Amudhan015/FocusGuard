import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_app_bar.dart';

/// Screen for viewing detailed information about the app.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: 'About FocusGuard',
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            Center(
              child:  Icon(
                Icons.shield_outlined,
                size: 80,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'FocusGuard',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'About This App',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'FocusGuard is designed to help you stay focused during study and work sessions by blocking distracting apps and providing honest feedback about your productivity. '
              'Unlike simple timers, FocusGuard actively monitors app usage and helps you build better focus habits through accountability.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'How It Works',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '1. Start a focus session\n'
              '2. FocusGuard blocks distracting apps you\'ve selected\n'
              '3. At the end, take a photo of your work as proof\n'
              '4. Rate your session productivity\n'
              '5. Review your focus stats over time',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '• Customizable focus sessions (Pomodoro & Deep Focus modes)\n'
              '• App blocking with multiple permission systems\n'
              '• Photo verification for honest session tracking\n'
              '• Productivity rating system\n'
              '• Detailed statistics and trends\n'
              '• Session templates for quick setup\n'
              '• Break time reminders',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'For support or feedback, please visit our website or contact us directly through the app.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
