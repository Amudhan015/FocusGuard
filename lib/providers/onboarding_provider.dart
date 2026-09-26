import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/permission_info.dart';
import '../services/native_bridge_service.dart';

class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider() : _steps = _buildSteps() {
    _granted = {for (final step in _steps) step.id: false};
  }

  final List<PermissionInfo> _steps;
  late final Map<String, bool> _granted;

  List<PermissionInfo> get permissionSteps => _steps;

  bool isGranted(String id) => _granted[id] ?? false;

  bool get allCriticalGranted =>
      _steps.where((s) => s.isCritical).every((s) => isGranted(s.id));

  Future<void> refreshAll() async {
    for (final step in _steps) {
      _granted[step.id] = await step.checkGranted();
    }
    notifyListeners();
  }

  Future<void> request(String id) async {
    final step = _steps.firstWhere((s) => s.id == id);
    final wasGranted = isGranted(id);
    await step.requestGrant();
    _granted[id] = await step.checkGranted();
    if (!wasGranted && isGranted(id)) {
      HapticFeedback.lightImpact();
    }
    notifyListeners();
  }

  static List<PermissionInfo> _buildSteps() {
    final bridge = NativeBridgeService.instance;
    return [
      PermissionInfo(
        id: 'accessibility',
        title: 'Detect blocked apps',
        description: 'FocusGuard needs Accessibility access to notice when you open '
            'a blocked app during a session. It only checks which app is in the '
            'foreground - it never reads your screen content.',
        icon: Icons.visibility_outlined,
        isCritical: true,
        checkGranted: bridge.isAccessibilityServiceEnabled,
        requestGrant: bridge.requestAccessibilityPermission,
      ),
      PermissionInfo(
        id: 'overlay',
        title: 'Show the block screen',
        description: 'This lets FocusGuard cover a blocked app with the block screen. '
            "Without it, FocusGuard can notice a blocked app opened but can't actually "
            'stop you from using it.',
        icon: Icons.layers_outlined,
        isCritical: true,
        checkGranted: bridge.isOverlayPermissionGranted,
        requestGrant: bridge.requestOverlayPermission,
      ),
      PermissionInfo(
        id: 'battery',
        title: 'Keep blocking reliable',
        description: 'Some phones aggressively kill background apps to save battery, '
            'which can silently stop blocking mid-session. Exempting FocusGuard keeps '
            'it reliable.',
        icon: Icons.battery_charging_full_outlined,
        isCritical: true,
        checkGranted: bridge.isIgnoringBatteryOptimizations,
        requestGrant: bridge.requestIgnoreBatteryOptimizations,
      ),
      PermissionInfo(
        id: 'notifications',
        title: 'Silence distracting notifications',
        description: 'Lets FocusGuard suppress notifications from blocked apps during '
            'a session, while always letting calls and messages through.',
        icon: Icons.notifications_off_outlined,
        isCritical: true,
        checkGranted: bridge.isNotificationListenerEnabled,
        requestGrant: bridge.requestNotificationListenerPermission,
      ),
      PermissionInfo(
        id: 'usage_access',
        title: 'See your daily screen time',
        description: "Used only for FocusGuard's Usage Insights, showing how long you "
            'spend in each app today. Nothing is sent anywhere.',
        icon: Icons.bar_chart_outlined,
        isCritical: true,
        checkGranted: bridge.isUsageAccessGranted,
        requestGrant: bridge.requestUsageAccessPermission,
      ),
      PermissionInfo(
        id: 'camera',
        title: 'Prove your session with a photo',
        description: 'Every session ends with a quick photo of your work, captured '
            'live in-app, as honest proof for your history. FocusGuard needs camera '
            'access for that.',
        icon: Icons.camera_alt_outlined,
        isCritical: false,
        checkGranted: bridge.isCameraPermissionGranted,
        requestGrant: bridge.requestCameraPermission,
      ),
    ];
  }
}
