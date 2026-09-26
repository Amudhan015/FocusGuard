import '../models/enums.dart';
import '../models/focus_session.dart';

/// Result of a streak calculation.
class StreakResult {
  const StreakResult({required this.currentStreak, required this.longestStreak});

  final int currentStreak;
  final int longestStreak;
}

/// Single source of truth for "current streak" / "longest streak", used by
/// both HomeScreen and StatsScreen. Previously each screen had its own
/// near-duplicate copy of this logic, and both shared the same bug: they
/// counted consecutive days backward from whatever the most recent closed
/// session was, without ever checking whether that most recent session was
/// actually today or yesterday. So if you hadn't done a session in a week,
/// the app would still proudly report your old streak instead of 0 - the
/// streak being *broken* was never actually detected.
class StreakCalculator {
  StreakCalculator._();

  static StreakResult calculate(List<FocusSession> sessions) {
    final closed = sessions.where((s) => s.status == SessionStatus.closed).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    if (closed.isEmpty) {
      return const StreakResult(currentStreak: 0, longestStreak: 0);
    }

    // Collect the distinct calendar days that had at least one closed
    // session, newest first.
    final days = <DateTime>[];
    for (final session in closed) {
      final day = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);
      if (days.isEmpty || days.last != day) {
        days.add(day);
      }
    }

    int longest = 0;
    int run = 1;
    for (int i = 0; i < days.length; i++) {
      if (i > 0) {
        final expectedPrevDay = days[i - 1].subtract(const Duration(days: 1));
        if (days[i] == expectedPrevDay) {
          run++;
        } else {
          if (run > longest) longest = run;
          run = 1;
        }
      }
    }
    if (run > longest) longest = run;

    // A "current" streak only counts if it's still alive - i.e. the most
    // recent day with a session is today or yesterday. Otherwise the
    // streak has been broken and the current count is 0, even though the
    // days list still shows an old consecutive run somewhere in the past.
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final mostRecentDay = days.first;
    final gapFromToday = todayDay.difference(mostRecentDay).inDays;

    int current = 0;
    if (gapFromToday <= 1) {
      current = 1;
      for (int i = 1; i < days.length; i++) {
        final expectedPrevDay = days[i - 1].subtract(const Duration(days: 1));
        if (days[i] == expectedPrevDay) {
          current++;
        } else {
          break;
        }
      }
    }

    return StreakResult(currentStreak: current, longestStreak: longest);
  }

  /// Number of complete Mon-Sun weeks in the given sessions where every
  /// single day of that week had at least one closed session. Previously
  /// hardcoded to 0 in StatsScreen as a placeholder.
  static int perfectWeeks(List<FocusSession> sessions) {
    final closedDays = sessions
        .where((s) => s.status == SessionStatus.closed)
        .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet();
    if (closedDays.isEmpty) return 0;

    final sortedDays = closedDays.toList()..sort();
    final firstMonday =
        sortedDays.first.subtract(Duration(days: (sortedDays.first.weekday - 1)));
    final today = DateTime.now();
    final lastCompleteWeekStart =
        today.subtract(Duration(days: today.weekday - 1 + 7));

    int perfectWeeks = 0;
    for (DateTime weekStart = firstMonday;
        !weekStart.isAfter(lastCompleteWeekStart);
        weekStart = weekStart.add(const Duration(days: 7))) {
      var allDaysPresent = true;
      for (int i = 0; i < 7; i++) {
        if (!closedDays.contains(weekStart.add(Duration(days: i)))) {
          allDaysPresent = false;
          break;
        }
      }
      if (allDaysPresent) perfectWeeks++;
    }
    return perfectWeeks;
  }
}
