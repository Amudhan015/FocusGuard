import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/permission_info.dart';
import '../providers/onboarding_provider.dart';
import '../services/app_preferences_service.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  late final PageController _pageController;
  late final OnboardingProvider _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _provider = OnboardingProvider();
    _pageController = PageController();
    _provider.refreshAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Catches the return trip from a Settings screen (Accessibility,
    // Overlay, Battery, Notification Access, Usage Access all redirect
    // out of the app) so the granted/not-granted status updates the
    // moment the user comes back, without them having to do anything.
    if (state == AppLifecycleState.resumed) {
      _provider.refreshAll();
    }
  }

  int get _totalPages => _provider.permissionSteps.length + 2; // + intro + done

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        body: SafeArea(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _totalPages,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _IntroPage(onNext: () => _goToPage(1));
              }
              if (index == _totalPages - 1) {
                return _DonePage(
                  onFinish: () async {
                    await AppPreferencesService.instance.setOnboardingCompleted(true);
                    widget.onComplete();
                  },
                );
              }
              final step = _provider.permissionSteps[index - 1];
              return _PermissionPage(
                step: step,
                pageNumber: index,
                totalPermissionPages: _provider.permissionSteps.length,
                onBack: () => _goToPage(index - 1),
                onNext: () => _goToPage(index + 1),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 72, color: colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text('Welcome to FocusGuard', style: textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "FocusGuard blocks distracting apps during study sessions and builds an "
            "honest record of how your focus time actually goes. It needs a handful "
            "of permissions to do that for real, not just show a timer - the next "
            "few screens explain each one before asking for it.",
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}

class _PermissionPage extends StatelessWidget {
  const _PermissionPage({
    required this.step,
    required this.pageNumber,
    required this.totalPermissionPages,
    required this.onBack,
    required this.onNext,
  });

  final PermissionInfo step;
  final int pageNumber;
  final int totalPermissionPages;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<OnboardingProvider>(
      builder: (context, provider, _) {
        final granted = provider.isGranted(step.id);

        final bool canProceedToNext = !step.isCritical || granted;

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$pageNumber of $totalPermissionPages',
                style: textTheme.labelSmall,
              ),
              const Spacer(),
              Icon(step.icon, size: 64, color: colorScheme.primary),
              const SizedBox(height: AppSpacing.md),
              Text(step.title, style: textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(step.description, style: textTheme.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              _StatusChip(granted: granted, isCritical: step.isCritical),
              const Spacer(),
              ElevatedButton(
                onPressed: granted ? null : () => provider.request(step.id),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: Text(granted ? 'Granted' : 'Grant access'),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Next button logic: for critical steps, require permission to continue
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: onBack, child: const Text('Back')),
                  TextButton(
                    onPressed: canProceedToNext ? onNext : null,
                    child: Text(
                      granted
                          ? 'Continue'
                          : step.isCritical
                              ? 'Please grant permission to continue'
                              : 'Skip for now',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.granted, required this.isCritical});

  final bool granted;
  final bool isCritical;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (granted) {
      return Chip(
        avatar: Icon(Icons.check_circle, color: colorScheme.secondary, size: 18),
        label: const Text('Granted'),
      );
    }

    return Column(
      children: [
        const Chip(label: Text('Not granted yet')),
        if (isCritical)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Blocking will not work reliably without this.',
              style: textTheme.labelSmall?.copyWith(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _DonePage extends StatelessWidget {
  const _DonePage({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<OnboardingProvider>(
      builder: (context, provider, _) {
        final allCritical = provider.allCriticalGranted;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                allCritical ? Icons.check_circle_outline : Icons.info_outline,
                size: 72,
                color: allCritical ? colorScheme.secondary : colorScheme.tertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                allCritical ? "You're all set" : 'Almost there',
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                allCritical
                    ? 'FocusGuard can now actually block distracting apps during your sessions.'
                    : 'You skipped a permission blocking depends on. You can grant it '
                        'anytime from Settings, but blocking may not work reliably until you do.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onFinish,
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
                child: const Text('Start using FocusGuard'),
              ),
            ],
          ),
        );
      },
    );
  }
}
