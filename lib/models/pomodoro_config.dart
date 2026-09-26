// Pomodoro configuration model for FocusGuard
// Defines the structure for Pomodoro technique settings

import 'package:flutter/foundation.dart';

/// Configuration for Pomodoro technique sessions
@immutable
class PomodoroConfig {
  const PomodoroConfig({
    required this.focusDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.sessionsBeforeLongBreak,
  });

  /// Duration of focus period in minutes
  final int focusDuration;

  /// Duration of short break in minutes
  final int shortBreakDuration;

  /// Duration of long break in minutes
  final int longBreakDuration;

  /// Number of focus sessions before a long break is triggered
  final int sessionsBeforeLongBreak;

  /// Creates a copy of this configuration with the given fields replaced
  PomodoroConfig copyWith({
    int? focusDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? sessionsBeforeLongBreak,
  }) {
    return PomodoroConfig(
      focusDuration: focusDuration ?? this.focusDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      sessionsBeforeLongBreak: sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
    );
  }

  /// Default Pomodoro configuration (25/5/15/4)
  static const PomodoroConfig defaultConfig = PomodoroConfig(
    focusDuration: 25,
    shortBreakDuration: 5,
    longBreakDuration: 15,
    sessionsBeforeLongBreak: 4,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroConfig &&
          runtimeType == other.runtimeType &&
          focusDuration == other.focusDuration &&
          shortBreakDuration == other.shortBreakDuration &&
          longBreakDuration == other.longBreakDuration &&
          sessionsBeforeLongBreak == other.sessionsBeforeLongBreak;

  @override
  int get hashCode =>
      focusDuration.hashCode ^
      shortBreakDuration.hashCode ^
      longBreakDuration.hashCode ^
      sessionsBeforeLongBreak.hashCode;

  @override
  String toString() {
    return 'PomodoroConfig(focusDuration: $focusDuration, shortBreakDuration: $shortBreakDuration, longBreakDuration: $longBreakDuration, sessionsBeforeLongBreak: $sessionsBeforeLongBreak)';
  }
}