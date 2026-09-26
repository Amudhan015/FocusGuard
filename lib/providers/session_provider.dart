import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/enums.dart';
import '../models/escape_attempt.dart';
import '../models/focus_session.dart';
import '../models/phone_pickup_event.dart';
import '../services/database_service.dart';
import '../services/native_bridge_service.dart';
import 'dart:developer';

class SessionProvider extends ChangeNotifier {
  FocusSession? _session;
  PomodoroPhase? _phase;
  Timer? _ticker;

  int _focusMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _sessionsBeforeLongBreak = 4;
  int _completedFocusPhasesInSet = 0;
  // Elapsed seconds in current phase is stored in the session object
// as elapsedSecondsInCurrentPhase to survive app restarts

  DateTime? _phaseEndTime;
  DateTime? _phaseStartTime;
  int _completedFocusSeconds = 0; // Total focused seconds accumulated

  FocusSession? get session => _session;
  PomodoroPhase? get currentPhase => _phase;
  bool get hasActiveSession => _session != null;
  bool get isPaused => _session?.status == SessionStatus.paused;

  Duration get remaining {
    if (_phaseEndTime == null) return Duration.zero;
    final diff = _phaseEndTime!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Duration? get currentPhaseTotalDuration {
    if (_phaseEndTime == null || _phaseStartTime == null) return null;
    return _phaseEndTime!.difference(_phaseStartTime!);
  }

  String get phaseLabel {
    final mode = _session?.mode;
    if (mode == SessionMode.deepFocus) return 'Deep Focus';
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

  bool get _isCurrentPhaseFocus =>
      _session?.mode == SessionMode.deepFocus || _phase == PomodoroPhase.focus;

  Future<void> startDeepFocus({
    required int minutes,
    required String subjectTag,
    String? intentionText,
    String? templateId,
  }) async {
    HapticFeedback.mediumImpact();
    await _startInternal(
      mode: SessionMode.deepFocus,
      subjectTag: subjectTag,
      intentionText: intentionText,
      templateId: templateId,
      focusMinutes: minutes,
    );
    _phase = null;
    await _beginPhase(isFocusPhase: true, minutes: minutes);
  }

  Future<void> startPomodoro({
    required int focusMinutes,
    int shortBreakMinutes = 5,
    int longBreakMinutes = 15,
    int sessionsBeforeLongBreak = 4,
    required String subjectTag,
    String? intentionText,
    String? templateId,
  }) async {
    HapticFeedback.mediumImpact();
    _focusMinutes = focusMinutes;
    _shortBreakMinutes = shortBreakMinutes;
    _longBreakMinutes = longBreakMinutes;
    _sessionsBeforeLongBreak = sessionsBeforeLongBreak;
    _completedFocusPhasesInSet = 0;

    await _startInternal(
      mode: SessionMode.pomodoro,
      subjectTag: subjectTag,
      intentionText: intentionText,
      templateId: templateId,
      focusMinutes: focusMinutes,
    );
    _phase = PomodoroPhase.focus;
    await _beginPhase(isFocusPhase: true, minutes: focusMinutes);
  }

  Future<void> startQuickFocus({int minutes = 25}) async {
    await startDeepFocus(minutes: minutes, subjectTag: 'General');
  }

  Future<void> _startInternal({
    required SessionMode mode,
    required String subjectTag,
    String? intentionText,
    String? templateId,
    required int focusMinutes,
  }) async {
    final id = DatabaseService.instance.newSessionId();
    final newSession = FocusSession(
      id: id,
      startTime: DateTime.now(),
      mode: mode,
      plannedDurationMinutes: focusMinutes,
      subjectTag: subjectTag,
      intentionText: intentionText,
      templateId: templateId,
    );
    await DatabaseService.instance.saveSession(newSession);
    _session = newSession;
    _completedFocusSeconds = 0;
    _session!.actualDurationMinutes = 0;

    await Permission.notification.request();

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  /// Begins a phase. Pass either [minutes] (whole-minute durations, used
  /// when a phase starts fresh) or [exactDuration] (used on resume, so we
  /// don't lose sub-minute precision and desync the countdown/notification -
  /// see resumeSession()).
  Future<void> _beginPhase({
    required bool isFocusPhase,
    int? minutes,
    Duration? exactDuration,
  }) async {
    assert(minutes != null || exactDuration != null);

    _phaseStartTime = DateTime.now();
    _phaseEndTime = _phaseStartTime!.add(exactDuration ?? Duration(minutes: minutes!));

    if (isFocusPhase) {
      await NativeBridgeService.instance.startSession(_phaseEndTime!);
    } else {
      await NativeBridgeService.instance.endSession();
    }

    await NativeBridgeService.instance.startForegroundNotification(
      endTime: _phaseEndTime!,
      label: isFocusPhase ? (_session?.subjectTag ?? 'Focus session') : 'Break',
    );

    notifyListeners();
  }

  int _ticksSinceLastDrain = 0;
  bool _isProcessing = false;
  bool _needsAnotherTick = false;

  void _onTick() {
    if (_isProcessing) {
      _needsAnotherTick = true;
      return;
    }
    _needsAnotherTick = true;
    _handleTick();
  }

  Future<void> _handleTick() async {
    if (_isProcessing) {
      _needsAnotherTick = true;
      return;
    }
    _isProcessing = true;
    bool shouldScheduleAnotherTick = false;
    try {
      if (_session == null || _phaseEndTime == null) return;

      // If paused, don't update the display or check for phase completion
      if (isPaused) return;

      shouldScheduleAnotherTick = true;

      if (remaining == Duration.zero) {
        await _handlePhaseComplete();
        return;
      }

      _ticksSinceLastDrain++;
      if (_ticksSinceLastDrain >= 5) {
        _ticksSinceLastDrain = 0;
        await _drainNativeEvents();
      }

      notifyListeners();
    } catch (e, stack) {
      log('Error in _handleTick: $e', error: e, stackTrace: stack);
    } finally {
      _isProcessing = false;
      if (shouldScheduleAnotherTick && _needsAnotherTick && _ticker != null) {
        _needsAnotherTick = false;
        // Schedule another tick to process immediately
        scheduleMicrotask(_onTick);
      }
    }
  }

  Future<void> _handlePhaseComplete() async {
    if (_session == null) return;
    final mode = _session!.mode;

    if (mode == SessionMode.deepFocus) {
      final focusSeconds = _session!.plannedDurationMinutes * 60;
      _completedFocusSeconds += focusSeconds;
      _session!.actualDurationMinutes = (_completedFocusSeconds / 60).round();
      await _completeSession(endedEarly: false);
      return;
    }

    if (_phase == PomodoroPhase.focus) {
      final focusSeconds = _focusMinutes * 60;
      _completedFocusSeconds += focusSeconds;
      _session!.actualDurationMinutes = (_completedFocusSeconds / 60).round();
      _completedFocusPhasesInSet++;
      await _playPhaseTransitionCue();

      final isLongBreak = _completedFocusPhasesInSet % _sessionsBeforeLongBreak == 0;
      _phase = isLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
      await _beginPhase(
        isFocusPhase: false,
        minutes: isLongBreak ? _longBreakMinutes : _shortBreakMinutes,
      );
    } else {
      await _playPhaseTransitionCue();
      _phase = PomodoroPhase.focus;
      await _beginPhase(isFocusPhase: true, minutes: _focusMinutes);
    }

    // Reset elapsed seconds counter for new phase
    _session!.elapsedSecondsInCurrentPhase = 0;
    await DatabaseService.instance.saveSession(_session!);
  }

  Future<void> _playPhaseTransitionCue() async {
    HapticFeedback.heavyImpact();
    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> pauseSession() async {
    if (_session == null || isPaused) return;
    HapticFeedback.selectionClick();

    if (_phaseStartTime != null) {
      final elapsedSeconds = DateTime.now().difference(_phaseStartTime!).inSeconds;
      _session!.elapsedSecondsInCurrentPhase = elapsedSeconds;
      if (_isCurrentPhaseFocus) {
        _completedFocusSeconds += elapsedSeconds;
        _session!.actualDurationMinutes = (_completedFocusSeconds / 60).round();
      }
    } else {
      // Phase has not started yet (e.g., during session startup), so no time has elapsed
      _session!.elapsedSecondsInCurrentPhase = 0;
    }

    _ticker?.cancel();
    await NativeBridgeService.instance.endSession();
    await NativeBridgeService.instance.stopForegroundNotification();

    _session!.status = SessionStatus.paused;
    await DatabaseService.instance.saveSession(_session!);
    notifyListeners();
  }

  Future<void> resumeSession() async {
    if (_session == null || !isPaused) return;
    HapticFeedback.selectionClick();

    _session!.status = SessionStatus.active;
    await DatabaseService.instance.saveSession(_session!);

    // Total planned length of whichever phase we're resuming into, in
    // whole seconds - used only to compute the exact remaining seconds
    // below. Fixed: this previously rounded to whole minutes before
    // rebuilding _phaseEndTime, which silently shifted the countdown (and
    // the native notification, which reads _phaseEndTime too) by up to
    // ±30 seconds on every single pause/resume. Now we carry the exact
    // remaining Duration straight through instead of rounding at all.
    final int totalSecondsForPhase;
    if (_session!.mode == SessionMode.deepFocus) {
      totalSecondsForPhase = _focusMinutes * 60;
    } else {
      switch (_phase) {
        case PomodoroPhase.focus:
          totalSecondsForPhase = _focusMinutes * 60;
          break;
        case PomodoroPhase.shortBreak:
          totalSecondsForPhase = _shortBreakMinutes * 60;
          break;
        case PomodoroPhase.longBreak:
          totalSecondsForPhase = _longBreakMinutes * 60;
          break;
        case null:
          totalSecondsForPhase = _focusMinutes * 60; // fallback, shouldn't happen
          break;
      }
    }

    final elapsedSeconds = _session?.elapsedSecondsInCurrentPhase ?? 0;
    final remainingSeconds =
        (totalSecondsForPhase - elapsedSeconds).clamp(1, totalSecondsForPhase);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    await _beginPhase(
      isFocusPhase: _isCurrentPhaseFocus,
      exactDuration: Duration(seconds: remainingSeconds),
    );
  }

  Future<void> endSessionEarly() async {
    if (_session == null) return;
    if (_isCurrentPhaseFocus && _phaseStartTime != null) {
      final elapsedSeconds = DateTime.now().difference(_phaseStartTime!).inSeconds;
      _completedFocusSeconds += elapsedSeconds;
      _session!.actualDurationMinutes = (_completedFocusSeconds / 60).round();
    }
    await _completeSession(endedEarly: true);
  }

  Future<void> _completeSession({required bool endedEarly}) async {
    final activeSession = _session;
    if (activeSession == null) return;

    HapticFeedback.mediumImpact();
    _ticker?.cancel();
    await _drainNativeEvents();

    await NativeBridgeService.instance.endSession();
    await NativeBridgeService.instance.stopForegroundNotification();

    activeSession.status = SessionStatus.pendingClosure;
    activeSession.endedEarly = endedEarly;
    activeSession.endTime = DateTime.now();
    activeSession.actualDurationMinutes = (_completedFocusSeconds / 60).round();
    await DatabaseService.instance.saveSession(activeSession);

    _session = null;
    _phase = null;
    _phaseEndTime = null;
    _phaseStartTime = null;
    _elapsedSecondsInCurrentPhase = 0;
    notifyListeners();
  }

  Future<void> _drainNativeEvents() async {
    if (_session == null) return;

    final escapeAttempts = await NativeBridgeService.instance.drainPendingEscapeAttempts();
    final pickups = await NativeBridgeService.instance.drainPendingPhonePickups();

    if (escapeAttempts.isEmpty && pickups.isEmpty) return;

    for (final attempt in escapeAttempts) {
      _session!.escapeAttempts.add(
        EscapeAttempt(
          timestamp: attempt.timestamp,
          packageName: attempt.packageName,
          appName: attempt.appName,
        ),
      );
    }
    for (final pickup in pickups) {
      _session!.phonePickups.add(PhonePickupEvent(timestamp: pickup.timestamp));
    }

    await DatabaseService.instance.saveSession(_session!);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
