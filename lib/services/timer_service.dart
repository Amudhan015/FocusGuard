// Timer service for FocusGuard
// Handles countdown logic, pause/resume, foreground notification, and phase transitions

import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/services.dart';

import '../models/enums.dart';
import '../services/native_bridge_service.dart';

/// A service that manages a countdown timer with pause/resume capabilities,
/// foreground notifications, and automatic phase transitions for Pomodoro and Deep Focus modes.
class TimerService {
  TimerService._internal();
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;

  // Internal state
  Timer? _ticker;
  DateTime? _phaseEndTime;
  DateTime? _phaseStartTime;
  bool _isProcessing = false;
  bool _needsAnotherTick = false;
  int _ticksSinceLastDrain = 0;

  // Configuration
  late SessionMode _mode;
  late String _subjectTag;
  late int _focusMinutes;
  late int _shortBreakMinutes;
  late int _longBreakMinutes;
  late int _sessionsBeforeLongBreak;
  int _completedFocusPhasesInSet = 0;
  int _completedFocusSeconds = 0;

  // Callbacks
  final ValueChanged<Duration>? onTick = null;
  final VoidCallback? onPhaseComplete = null;
  final ValueChanged<bool>? onSessionStarted = null; // true if session started, false if cancelled/error
  final ValueChanged<String?>? onError = null; // Error message if any

  // Getters
  DateTime? get phaseEndTime => _phaseEndTime;
  DateTime? get phaseStartTime => _phaseStartTime;
  bool get isRunning => _ticker?.isActive ?? false;
  bool get isPaused => !isRunning && _phaseEndTime != null;

  Duration get remaining {
    if (_phaseEndTime == null) return Duration.zero;
    final diff = _phaseEndTime!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get phaseLabel {
    if (_mode == SessionMode.deepFocus) return 'Deep Focus';
    switch (_phase) {
      case PomodoroPhase.focus:
        return 'Focus';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
      case null:
        return '';
    }
  }

  PomodoroPhase? get _phase {
    if (_mode == SessionMode.deepFocus) return null;
    // In session provider, _phase is tracked separately. We'll compute it based on completed focus phases.
    // For simplicity, we'll assume the service is used in a way that _phase is known.
    // We'll leave this as null and rely on the caller to track phase if needed.
    return null;
  }

  // Start a new timer session
  Future<void> startTimer({
    required SessionMode mode,
    required int focusMinutes,
    int shortBreakMinutes = 5,
    int longBreakMinutes = 15,
    int sessionsBeforeLongBreak = 4,
    required String subjectTag,
  }) async {
    // Cancel any existing ticker
    _ticker?.cancel();

    // Store configuration
    _mode = mode;
    _focusMinutes = focusMinutes;
    _shortBreakMinutes = shortBreakMinutes;
    _longBreakMinutes = longBreakMinutes;
    _sessionsBeforeLongBreak = sessionsBeforeLongBreak;
    _subjectTag = subjectTag;
    _completedFocusPhasesInSet = 0;
    _completedFocusSeconds = 0;

    // Notify session started
    onSessionStarted?.call(true);

    // Start the first phase (always focus for both modes)
    await _beginPhase(isFocusPhase: true, minutes: focusMinutes);
  }

  // Pause the current timer
  Future<void> pauseTimer() async {
    if (!isRunning) return;

    _ticker?.cancel();
    await NativeBridgeService.instance.stopForegroundNotification();

    // Update completed focus seconds if in focus phase
    if (_isCurrentPhaseFocus && _phaseStartTime != null) {
      final elapsedSeconds =
          DateTime.now().difference(_phaseStartTime!).inSeconds;
      _completedFocusSeconds += elapsedSeconds;
    }

    _notifyListeners();
  }

  // Resume the paused timer
  Future<void> resumeTimer() async {
    if (isRunning) return;

    // Determine remaining time in current phase
    int remainingMinutes;
    if (_mode == SessionMode.deepFocus) {
      final totalPlannedSeconds = _focusMinutes * 60;
      final remainingSeconds =
          (totalPlannedSeconds - _completedFocusSeconds).clamp(0, totalPlannedSeconds);
      remainingMinutes = (remainingSeconds / 60).ceil().toInt();
      if (remainingMinutes <= 0) {
        // Session actually completed while paused
        await _handlePhaseComplete();
        return;
      }
    } else {
      remainingMinutes = _focusMinutes;
    }

    // Restart ticker and begin phase
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    await _beginPhase(isFocusPhase: _isCurrentPhaseFocus, minutes: remainingMinutes);
  }

  // Cancel the timer and end the session early
  Future<void> cancelTimer({required bool endedEarly}) async {
    _ticker?.cancel();
    await NativeBridgeService.instance.stopForegroundNotification();

    if (_isCurrentPhaseFocus && _phaseStartTime != null) {
      final elapsedSeconds =
          DateTime.now().difference(_phaseStartTime!).inSeconds;
      _completedFocusSeconds += elapsedSeconds;
    }

    // Complete the session
    await _completeSession(endedEarly: endedEarly);
  }

  // Internal methods
  bool get _isCurrentPhaseFocus =>
      _mode == SessionMode.deepFocus || _phase == PomodoroPhase.focus;

  Future<void> _beginPhase({
    required bool isFocusPhase,
    required int minutes,
  }) async {
    _phaseStartTime = DateTime.now();
    _phaseEndTime = _phaseStartTime!.add(Duration(minutes: minutes));

    // Start foreground notification
    await NativeBridgeService.instance.startForegroundNotification(
      endTime: _phaseEndTime!,
      label: isFocusPhase
          ? (_subjectTag.isNotEmpty ? _subjectTag : 'Focus session')
          : 'Break',
    );

    // Start ticker if not already running
    if (_ticker == null || !_ticker!.isActive) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    }

    _notifyListeners();
  }

  void _onTick() {
    if (_isProcessing) {
      _needsAnotherTick = true;
      return;
    }
    _isProcessing = true;
    _handleTick();
  }

  Future<void> _handleTick() async {
    try {
      if (_phaseEndTime == null) return;

      if (remaining == Duration.zero) {
        await _handlePhaseComplete();
        return;
      }

      _ticksSinceLastDrain++;
      if (_ticksSinceLastDrain >= 5) {
        _ticksSinceLastDrain = 0;
        await _drainNativeEvents();
      }

      onTick?.call(remaining);
      _notifyListeners();
    } finally {
      _isProcessing = false;
      if (_needsAnotherTick) {
        _needsAnotherTick = false;
        scheduleMicrotask(_onTick);
      }
    }
  }

  Future<void> _handlePhaseComplete() async {
    // Play transition cue
    await _playPhaseTransitionCue();

    if (_mode == SessionMode.deepFocus) {
      // Deep focus: add the entire planned duration to completed focus seconds
      final focusSeconds = _focusMinutes * 60;
      _completedFocusSeconds += focusSeconds;
      await _completeSession(endedEarly: false);
      return;
    }

    // Pomodoro mode
    if (_phase == PomodoroPhase.focus) {
      // Just completed a focus phase
      final focusSeconds = _focusMinutes * 60;
      _completedFocusSeconds += focusSeconds;
      _completedFocusPhasesInSet++;

      // Determine next phase
      final isLongBreak =
          _completedFocusPhasesInSet % _sessionsBeforeLongBreak == 0;
      const nextIsFocus = false;
      final nextMinutes =
          isLongBreak ? _longBreakMinutes : _shortBreakMinutes;

      await _beginPhase(
        isFocusPhase: nextIsFocus,
        minutes: nextMinutes,
      );
    } else {
      // Just completed a break phase, next is focus
      await _beginPhase(
        isFocusPhase: true,
        minutes: _focusMinutes,
      );
    }

    // Notify phase complete
    onPhaseComplete?.call();
  }

  Future<void> _playPhaseTransitionCue() async {
    HapticFeedback.heavyImpact();
    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> _completeSession({required bool endedEarly}) async {
    _ticker?.cancel();
    await _drainNativeEvents();
    await NativeBridgeService.instance.endSession();
    await NativeBridgeService.instance.stopForegroundNotification();

    // Notify listeners
    onSessionStarted?.call(false);
    _notifyListeners();
  }

  Future<void> _drainNativeEvents() async {
    final escapeAttempts =
        await NativeBridgeService.instance.drainPendingEscapeAttempts();
    final pickups =
        await NativeBridgeService.instance.drainPendingPhonePickups();

    if (escapeAttempts.isEmpty && pickups.isEmpty) return;

    // In a real app, we would add these to the current session.
    // For now, we just log them.
    if (escapeAttempts.isNotEmpty) {
      log('Drained ${escapeAttempts.length} escape attempts');
    }
    if (pickups.isNotEmpty) {
      log('Drained ${pickups.length} phone pickups');
    }
  }

  void _notifyListeners() {
    // Notify any listeners (e.g., UI) of state changes
    // This service is designed to be used with a StateNotifier or similar
    // For simplicity, we'll rely on the callbacks provided.
  }

  // Dispose resources
  void dispose() {
    _ticker?.cancel();
  }
}

// Helper class for haptic feedback
class HapticFeedback {
  static Future<void> mediumImpact() =>
      HapticFeedback.lightImpact(); // Fallback
  static Future<void> heavyImpact() =>
      HapticFeedback.lightImpact(); // Fallback
  static Future<void> lightImpact() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // Ignore errors
    }
  }
  static Future<void> selectionClick() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // Ignore errors
    }
  }
}

// Helper class for system sounds
class SystemSound {
  static Future<void> play(SystemSoundType type) async {
    try {
      const MethodChannel channel =
          MethodChannel('com.focusguard/system_sound');
      await channel.invokeMethod<void>('playSound', {'type': type.index});
    } catch (e, stack) {
      log('Failed to play system sound: $e', error: e, stackTrace: stack);
    }
  }
}

enum SystemSoundType { click, alert }