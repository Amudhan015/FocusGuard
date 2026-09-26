import 'package:flutter/services.dart';
import 'dart:developer' show log;

class NativeEscapeAttempt {
  NativeEscapeAttempt({
    required this.packageName,
    required this.appName,
    required this.timestamp,
  });

  final String packageName;
  final String appName;
  final DateTime timestamp;

  factory NativeEscapeAttempt._fromMap(Map<dynamic, dynamic> map) {
    return NativeEscapeAttempt(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestampMillis'] as int),
    );
  }
}

class NativePhonePickup {
  NativePhonePickup({required this.timestamp});

  final DateTime timestamp;

  factory NativePhonePickup._fromMap(Map<dynamic, dynamic> map) {
    return NativePhonePickup(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestampMillis'] as int),
    );
  }
}

class NativeBridgeService {
  NativeBridgeService._();
  static final NativeBridgeService instance = NativeBridgeService._();

  static const MethodChannel _channel = MethodChannel('com.focusguard/native_bridge');

  /// Registers a handler for calls initiated FROM native code, e.g. the
  /// user tapping Pause/Resume/Stop actions on the foreground-service
  /// notification. Requires the native side to add those actions to the
  /// notification and invoke the method channel with one of
  /// 'notificationPauseTapped' / 'notificationResumeTapped' /
  /// 'notificationStopTapped' when tapped - that part is native Android
  /// work (a NotificationCompat.Action + PendingIntent/BroadcastReceiver)
  /// that isn't in this Dart codebase. This just makes sure the Flutter
  /// side is ready to react the moment that native support exists.
  void setNotificationActionHandler({
    required VoidCallback onPause,
    required VoidCallback onResume,
    required VoidCallback onStop,
  }) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'notificationPauseTapped':
          onPause();
          break;
        case 'notificationResumeTapped':
          onResume();
          break;
        case 'notificationStopTapped':
          onStop();
          break;
      }
    });
  }

  Future<void> syncBlockedApps({
    required List<String> packages,
    required Map<String, String> notes,
  }) async {
    try {
      await _channel.invokeMethod<void>('syncBlockedApps', {
        'packages': packages,
        'notes': notes,
      });
    } catch (e, stack) {
      log('Failed to sync blocked apps: $e', error: e, stackTrace: stack);
      rethrow; // Optionally rethrow if the caller should handle it
    }
  }

  Future<void> setNotificationWhitelist(List<String> packages) async {
    try {
      await _channel.invokeMethod<void>('setNotificationWhitelist', {
        'packages': packages,
      });
    } catch (e, stack) {
      log('Failed to set notification whitelist: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> startSession(DateTime endTime) async {
    try {
      await _channel.invokeMethod<void>('startSession', {
        'endTimeMillis': endTime.millisecondsSinceEpoch,
      });
    } catch (e, stack) {
      log('Failed to start session: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> endSession() async {
    try {
      await _channel.invokeMethod<void>('endSession');
    } catch (e, stack) {
      log('Failed to end session: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<List<NativeEscapeAttempt>> drainPendingEscapeAttempts() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('drainPendingEscapeAttempts');
      if (result == null) return const [];
      return result.cast<Map<dynamic, dynamic>>().map(NativeEscapeAttempt._fromMap).toList();
    } catch (e, stack) {
      log('Failed to drain pending escape attempts: $e', error: e, stackTrace: stack);
      return const []; // Return empty list on error to avoid breaking the flow
    }
  }

  Future<List<NativePhonePickup>> drainPendingPhonePickups() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('drainPendingPhonePickups');
      if (result == null) return const [];
      return result.cast<Map<dynamic, dynamic>>().map(NativePhonePickup._fromMap).toList();
    } catch (e, stack) {
      log('Failed to drain pending phone pickups: $e', error: e, stackTrace: stack);
      return const [];
    }
  }

  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      return (await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled')) ?? false;
    } catch (e, stack) {
      log('Failed to check accessibility service: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> isOverlayPermissionGranted() async {
    try {
      return (await _channel.invokeMethod<bool>('isOverlayPermissionGranted')) ?? false;
    } catch (e, stack) {
      log('Failed to check overlay permission: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> isNotificationListenerEnabled() async {
    try {
      return (await _channel.invokeMethod<bool>('isNotificationListenerEnabled')) ?? false;
    } catch (e, stack) {
      log('Failed to check notification listener: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> isUsageAccessGranted() async {
    try {
      return (await _channel.invokeMethod<bool>('isUsageAccessGranted')) ?? false;
    } catch (e, stack) {
      log('Failed to check usage access: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      return (await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations')) ?? false;
    } catch (e, stack) {
      log('Failed to check battery optimization: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod<void>('requestAccessibilityPermission');
    } catch (e, stack) {
      log('Failed to request accessibility permission: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod<void>('requestOverlayPermission');
    } catch (e, stack) {
      log('Failed to request overlay permission: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> requestNotificationListenerPermission() async {
    try {
      await _channel.invokeMethod<void>('requestNotificationListenerPermission');
    } catch (e, stack) {
      log('Failed to request notification listener permission: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> requestUsageAccessPermission() async {
    try {
      await _channel.invokeMethod<void>('requestUsageAccessPermission');
    } catch (e, stack) {
      log('Failed to request usage access permission: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _channel.invokeMethod<void>('requestIgnoreBatteryOptimizations');
    } catch (e, stack) {
      log('Failed to request ignore battery optimizations: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<bool> isCameraPermissionGranted() async {
    try {
      return (await _channel.invokeMethod<bool>('isCameraPermissionGranted')) ?? false;
    } catch (e, stack) {
      log('Failed to check camera permission: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<void> requestCameraPermission() async {
    try {
      await _channel.invokeMethod<void>('requestCameraPermission');
    } catch (e, stack) {
      log('Failed to request camera permission: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<Map<String, Duration>> getTodayUsageStats() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getTodayUsageStats');
      if (result == null) return const {};
      return result.map(
        (key, value) => MapEntry(key as String, Duration(milliseconds: value as int)),
      );
    } catch (e, stack) {
      log('Failed to get today usage stats: $e', error: e, stackTrace: stack);
      return const {};
    }
  }

  Future<void> startForegroundNotification({
    required DateTime endTime,
    required String label,
  }) async {
    try {
      await _channel.invokeMethod<void>('startForegroundNotification', {
        'endTimeMillis': endTime.millisecondsSinceEpoch,
        'label': label,
      });
    } catch (e, stack) {
      log('Failed to start foreground notification: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> stopForegroundNotification() async {
    try {
      await _channel.invokeMethod<void>('stopForegroundNotification');
    } catch (e, stack) {
      log('Failed to stop foreground notification: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
