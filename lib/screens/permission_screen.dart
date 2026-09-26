import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/permission_info.dart';
import '../providers/onboarding_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_app_bar.dart';

/// Screen for viewing and managing app permissions.
class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider()..refreshAll(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const GlassAppBar(
          title: 'App Permissions',
        ),
        body: SafeArea(
          top: false,
          child: Consumer<OnboardingProvider>(
            builder: (context, provider, _) {
              final steps = provider.permissionSteps;
              return ListView(
                padding: EdgeInsets.only(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top,
                ),
                children: [
                  for (final step in steps)
                    PermissionTile(
                      step: step,
                      isGranted: provider.isGranted(step.id),
                      onRequest: () => provider.request(step.id),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class PermissionTile extends StatelessWidget {
  const PermissionTile({
    super.key,
    required this.step,
    required this.isGranted,
    required this.onRequest,
  });

  final PermissionInfo step;
  final bool isGranted;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        ListTile(
          leading: Icon(step.icon, color: colorScheme.primary),
          title: Text(step.title, style: textTheme.titleMedium),
          subtitle: Text(step.description, style: textTheme.bodyMedium),
          trailing: isGranted
              ? Icon(Icons.check_circle, color: colorScheme.secondary)
              : const Icon(Icons.arrow_forward_ios),
          onTap: isGranted ? null : onRequest,
        ),
        if (!isGranted && step.isCritical)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs),
            child: Text(
              'Blocking will not work reliably without this permission.',
              style: textTheme.labelSmall?.copyWith(color: colorScheme.error),
            ),
          ),
        const Divider(height: 0.5, color: Colors.grey),
      ],
    );
  }
}