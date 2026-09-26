import 'package:hive/hive.dart';

/// Category an installed app is bucketed into, either by heuristic
/// classification (see AppCategoryClassifier, built in the Apps-screen
/// stage) or by explicit user override.
enum AppCategory {
  socialMedia,
  games,
  entertainment,
  studyProductivity,
  utilities,
  other,
}

extension AppCategoryLabel on AppCategory {
  String get label {
    switch (this) {
      case AppCategory.socialMedia:
        return 'Social Media';
      case AppCategory.games:
        return 'Games';
      case AppCategory.entertainment:
        return 'Entertainment';
      case AppCategory.studyProductivity:
        return 'Study & Productivity';
      case AppCategory.utilities:
        return 'Utilities';
      case AppCategory.other:
        return 'Other';
    }
  }
}

/// Which timer mode produced a session.
enum SessionMode { pomodoro, deepFocus }

/// Which phase of a Pomodoro cycle is currently running. Not persisted
/// on its own — used by the live timer provider (Stage 4).
enum PomodoroPhase { focus, shortBreak, longBreak }

/// Lifecycle of a single FocusSession record.
enum SessionStatus {
  /// Timer is running.
  active,

  /// Timer is paused (Deep Focus mode only; Pomodoro auto-transitions).
  paused,

  /// Timer has stopped (naturally or ended early) but the mandatory
  /// photo + rating step has not been completed yet. Sessions may sit
  /// here indefinitely — they are not deleted or discarded.
  pendingClosure,

  /// Photo + rating submitted. Session is final and counted in stats.
  closed,
}

/// Student's self-rating of how productive a session felt.
enum SelfRating { poor, okay, average, good, great }

extension SelfRatingLabel on SelfRating {
  String get label {
    switch (this) {
      case SelfRating.poor:
        return 'Poor';
      case SelfRating.okay:
        return 'Okay';
      case SelfRating.average:
        return 'Average';
      case SelfRating.good:
        return 'Good';
      case SelfRating.great:
        return 'Great';
    }
  }

  /// 1-5 style numeric weight, used for averaging in Stats.
  int get score {
    switch (this) {
      case SelfRating.poor:
        return 1;
      case SelfRating.okay:
        return 2;
      case SelfRating.average:
        return 3;
      case SelfRating.good:
        return 4;
      case SelfRating.great:
        return 5;
    }
  }
}

/// Category of achievement badge, used to decide how progress toward
/// it is computed from history data.
enum AchievementType {
  streakDays,
  totalSessions,
  totalFocusMinutes,
  perfectWeek,
}

/// -----------------------------------------------------------------------
/// Hand-written Hive TypeAdapters for the enums above. Hive can't
/// serialize a raw Dart enum without an adapter registered for it, same
/// as for classes. Each writes/reads the enum's index as a single byte.
/// TypeIds 0-4 are reserved for enums; classes start at 5 (see
/// DatabaseService for the full registry table).
/// -----------------------------------------------------------------------

class AppCategoryAdapter extends TypeAdapter<AppCategory> {
  @override
  final int typeId = 0;

  @override
  AppCategory read(BinaryReader reader) => AppCategory.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, AppCategory obj) => writer.writeByte(obj.index);
}

class SessionModeAdapter extends TypeAdapter<SessionMode> {
  @override
  final int typeId = 1;

  @override
  SessionMode read(BinaryReader reader) => SessionMode.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, SessionMode obj) => writer.writeByte(obj.index);
}

class SessionStatusAdapter extends TypeAdapter<SessionStatus> {
  @override
  final int typeId = 2;

  @override
  SessionStatus read(BinaryReader reader) => SessionStatus.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, SessionStatus obj) => writer.writeByte(obj.index);
}

class SelfRatingAdapter extends TypeAdapter<SelfRating> {
  @override
  final int typeId = 3;

  @override
  SelfRating read(BinaryReader reader) => SelfRating.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, SelfRating obj) => writer.writeByte(obj.index);
}

class AchievementTypeAdapter extends TypeAdapter<AchievementType> {
  @override
  final int typeId = 4;

  @override
  AchievementType read(BinaryReader reader) => AchievementType.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, AchievementType obj) => writer.writeByte(obj.index);
}
