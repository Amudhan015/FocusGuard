import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/focus_session.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_app_bar.dart';
import '../screens/timer_screen.dart';

/// Stats screen - displays statistics and insights about focus sessions.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<FocusSession> _sessions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final allSessions = DatabaseService.instance.getAllSessions();
      final closedSessions = allSessions
          .where((session) => session.status == SessionStatus.closed)
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Newest first

      if (!mounted) return;
      setState(() {
        _sessions = closedSessions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: 'Stats',
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sessions.isEmpty
                ? _buildEmptyState(context)
                : _buildStatsContent(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No stats yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Complete sessions to see your statistics here.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TimerScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                elevation: 0,
              ),
              child: const Text('Start Session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildOverviewStats(context),
        const SizedBox(height: AppSpacing.lg),
        _buildTimeStats(context),
        const SizedBox(height: AppSpacing.lg),
        _buildStreakStats(context),
        const SizedBox(height: AppSpacing.lg),
        _buildCategoryStats(context),
        const SizedBox(height: AppSpacing.lg),
        _buildWeeklyReview(context),
      ],
    );
  }

  Widget _buildOverviewStats(BuildContext context) {
    final totalSessions = _sessions.length;
    final totalHours = _sessions
        .fold(0.0, (sum, session) => sum + (getSessionDuration(session).inSeconds / 3600))
        .toDouble();
    final avgSessionLength = totalSessions > 0
        ? (totalHours * 60) / totalSessions
        : 0;
    final avgRating = _sessions.isNotEmpty
        ? _sessions
            .where((s) => s.selfRating != null)
            .map((s) => s.selfRating!.score)
            .reduce((a, b) => a + b) /
            _sessions.where((s) => s.selfRating != null).length
        : 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppShape.borderRadius,
        side: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context: context,
                  label: 'Total Sessions',
                  value: totalSessions.toString(),
                  icon: Icons.timeline,
                ),
                _buildStatItem(
                  context: context,
                  label: 'Total Time',
                  value: '${totalHours.toStringAsFixed(1)} hrs',
                  icon: Icons.hourglass_top,
                ),
                _buildStatItem(
                  context: context,
                  label: 'Avg Session',
                  value: '${avgSessionLength.toStringAsFixed(0)} min',
                  icon: Icons.timelapse,
                ),
                _buildStatItem(
                  context: context,
                  label: 'Avg Rating',
                  value: avgRating.toStringAsFixed(1),
                  icon: Icons.stars,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeStats(BuildContext context) {
    // Calculate time distribution
    final today = DateTime.now();
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = today.subtract(const Duration(days: 30));

    final todaySessions = _sessions
        .where((session) =>
            session.startTime.isAfter(weekAgo) &&
            session.startTime.isBefore(today.add(const Duration(days: 1))))
        .length;
    final weekSessions = _sessions
        .where((session) => session.startTime.isAfter(weekAgo))
        .length;
    final monthSessions = _sessions
        .where((session) => session.startTime.isAfter(monthAgo))
        .length;

    final todayHours = _sessions
        .where((session) =>
            session.startTime.isAfter(weekAgo) &&
            session.startTime.isBefore(today.add(const Duration(days: 1))))
        .fold(0.0, (sum, session) => sum + (getSessionDuration(session).inSeconds / 3600))
        .toDouble();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppShape.borderRadius,
        side: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Distribution',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTimeStatRow(
              context,
              label: 'Today',
              value: '$todaySessions sessions (${todayHours.toStringAsFixed(1)} hrs)',
              icon: Icons.today,
            ),
            _buildTimeStatRow(
              context,
              label: 'This Week',
              value: '$weekSessions sessions',
              icon: Icons.calendar_today,
            ),
            _buildTimeStatRow(
              context,
              label: 'This Month',
              value: '$monthSessions sessions',
              icon: Icons.calendar_month,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeStatRow(
      BuildContext context, {
      required String label,
      required String value,
      required IconData icon,
    }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStats(BuildContext context) {
    // Calculate streak stats directly from sessions
    final closedSessions = _sessions.where((s) => s.status == SessionStatus.closed).toList();
    closedSessions.sort((a, b) => b.startTime.compareTo(a.startTime)); // Newest first

    int currentStreak = 0;
    int longestStreak = 0;
    int perfectWeeks = 0;
    int sessionsThisWeek = 0;

    if (closedSessions.isNotEmpty) {
      // Calculate current and longest streak
      DateTime? lastSessionDate;
      int currentStreakTemp = 0;

      for (final session in closedSessions) {
        final sessionDate = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);

        if (lastSessionDate == null) {
          lastSessionDate = sessionDate;
          currentStreakTemp = 1;
          continue;
        }

        final yesterday = lastSessionDate.subtract(const Duration(days: 1));
        if (sessionDate.isAtSameMomentAs(yesterday)) {
          currentStreakTemp++;
          if (currentStreakTemp > longestStreak) {
            longestStreak = currentStreakTemp;
          }
        } else if (!sessionDate.isAtSameMomentAs(lastSessionDate)) {
          // Streak broken
          if (currentStreakTemp > longestStreak) {
            longestStreak = currentStreakTemp;
          }
          currentStreakTemp = 1;
          lastSessionDate = sessionDate;
          continue;
        }

        lastSessionDate = sessionDate;
      }

      // Handle the case where the streak is still going
      if (currentStreakTemp > longestStreak) {
        longestStreak = currentStreakTemp;
      }
      currentStreak = currentStreakTemp;

      // Calculate sessions this week
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      sessionsThisWeek = closedSessions.where((s) => s.startTime.isAfter(weekAgo)).length;

      // Calculate perfect weeks (weeks with at least one session every day)
      // This is a simplified version - in a real app you'd want to track this properly
      perfectWeeks = 0; // Placeholder - would require more complex tracking
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppShape.borderRadius,
        side: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Streak Stats',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context: context,
                  label: 'Current Streak',
                  value: '$currentStreak days',
                  icon: Icons.flash_on,
                ),
                _buildStatItem(
                  context: context,
                  label: 'Best Streak',
                  value: '$longestStreak days',
                  icon: Icons.stars,
                ),
                _buildStatItem(
                  context: context,
                  label: 'Perfect Weeks',
                  value: '$perfectWeeks',
                  icon: Icons.calendar_today,
                ),
                _buildStatItem(
                  context: context,
                  label: 'Sessions This Week',
                  value: '$sessionsThisWeek',
                  icon: Icons.timeline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStats(BuildContext context) {
    // Group sessions by subject/tag
    final Map<String, int> categoryCounts = {};
    final Map<String, double> categoryHours = {};

    for (final session in _sessions) {
      final subject = session.subjectTag;
      categoryCounts[subject] = (categoryCounts[subject] ?? 0) + 1;
      final hours = getSessionDuration(session).inSeconds / 3600;
      categoryHours[subject] = (categoryHours[subject] ?? 0.0) + hours;
    }

    // Sort by count descending
    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppShape.borderRadius,
        side: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By Category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (sortedCategories.isEmpty)
              const Center(
                child: Text('No categories yet'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedCategories.length > 5
                    ? 5
                    : sortedCategories.length, // Show top 5
                itemBuilder: (context, index) {
                  final entry = sortedCategories[index];
                  final hours = categoryHours[entry.key] ?? 0.0;
                  return _buildCategoryRow(
                    context,
                    category: entry.key,
                    count: entry.value,
                    hours: hours,
                  );
                },
              ),
            if (sortedCategories.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  '+ ${sortedCategories.length - 5} more',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(
      BuildContext context, {
      required String category,
      required int count,
      required double hours,
    }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$count sessions',
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${hours.toStringAsFixed(1)} hrs',
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyReview(BuildContext context) {
    // Calculate data for the last 7 days
    final today = DateTime.now();
    final weekAgo = today.subtract(const Duration(days: 7));

    final weekSessions = _sessions
        .where((session) => session.startTime.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime)); // Oldest first for chart

    final totalWeekHours = weekSessions
        .fold(0.0, (sum, session) => sum + (getSessionDuration(session).inSeconds / 3600));

    final bestDay = _findBestDay(weekSessions);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppShape.borderRadius,
        side: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 7 Days',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (weekSessions.isEmpty)
              const Center(
                child: Text('No sessions this week'),
              )
            else
              Column(
                children: [
                  _buildStatItem(
                    context: context,
                    label: 'Sessions This Week',
                    value: weekSessions.length.toString(),
                    icon: Icons.timeline,
                  ),
                  _buildStatItem(
                    context: context,
                    label: 'Hours This Week',
                    value: '${totalWeekHours.toStringAsFixed(1)} hrs',
                    icon: Icons.hourglass_top,
                  ),
                  _buildStatItem(
                    context: context,
                    label: 'Best Day',
                    value: bestDay ?? 'No data',
                    icon: Icons.wb_sunny,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: weekSessions.length,
                      itemBuilder: (context, index) {
                        final session = weekSessions[index];
                        final hours = getSessionDuration(session).inSeconds / 3600;
                        return Container(
                          width: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${hours.toStringAsFixed(1)}h',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 30,
                                height: hours * 10, // Scale for visibility
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${session.startTime.month}/${session.startTime.day}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String? _findBestDay(List<FocusSession> sessions) {
    if (sessions.isEmpty) return null;

    // Group by day
    final Map<String, double> dayHours = {};
    for (final session in sessions) {
      final dayKey = '${session.startTime.year}-${session.startTime.month}-${session.startTime.day}';
      final hours = getSessionDuration(session).inSeconds / 3600;
      dayHours[dayKey] = (dayHours[dayKey] ?? 0.0) + hours;
    }

    // Find day with most hours
    String? bestDayKey;
    double maxHours = 0;

    dayHours.forEach((day, hours) {
      if (hours > maxHours) {
        maxHours = hours;
        bestDayKey = day;
      }
    });

    if (bestDayKey == null) return null;

    // Format as readable date
    if (bestDayKey == null) {
      return null;
    }
    final parts = bestDayKey!.split('-');
    if (parts.length < 3) {
      return null;
    }
    final day = int.parse(parts[2]);
    final month = int.parse(parts[1]);
    return '$month/$day';
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Duration getSessionDuration(FocusSession session) {
    if (session.endTime != null) {
      return session.endTime!.difference(session.startTime);
    } else if (session.status == SessionStatus.active) {
      // For active sessions, calculate duration so far
      return DateTime.now().difference(session.startTime);
    } else {
      // For completed sessions without end time, estimate or return zero
      return Duration.zero;
    }
  }
}