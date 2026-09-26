import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_app_bar.dart';
import '../screens/timer_screen.dart';
import '../services/database_service.dart';
import '../services/app_preferences_service.dart';
import '../models/enums.dart';
import '../models/focus_session.dart';
import '../utils/streak_calculator.dart';

/// Home screen - serves as the main dashboard showing today's focus stats
/// and providing quick access to start a session.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _todaySessions = 0;
  double _todayHours = 0.0;
  int _currentStreak = 0;
  List<FocusSession> _recentSessions = [];
  bool _use24HourFormat = true;

  @override
  void initState() {
    super.initState();
    _updateTodayStats();
    _loadRecentSessions();
    _loadTimeFormatPreference();
  }

  Future<void> _loadTimeFormatPreference() async {
    final prefs = await AppPreferencesService.instance.getPreferences();
    if (!mounted) return;
    setState(() => _use24HourFormat = prefs.use24HourFormat);
  }

  Future<void> _updateTodayStats() async {
    final db = DatabaseService.instance;

    final todaySessions = db.getAllSessions().where((session) {
      final sessionDate = session.startTime;
      final today = DateTime.now();
      return sessionDate.year == today.year &&
          sessionDate.month == today.month &&
          sessionDate.day == today.day &&
          session.status == SessionStatus.closed;
    }).toList();

    // Use actualDurationMinutes (the timer's own tracked focus time)
    // rather than endTime - startTime: the latter is wall-clock time and
    // for Pomodoro sessions includes break time, and for any paused
    // session includes idle paused time, both of which overstate how much
    // was actually focused.
    final todayMinutes =
        todaySessions.fold(0, (sum, session) => sum + session.actualDurationMinutes);

    final streak = StreakCalculator.calculate(db.getAllSessions());

    if (!mounted) return;

    setState(() {
      _todaySessions = todaySessions.length;
      _todayHours = todayMinutes / 60;
      _currentStreak = streak.currentStreak;
    });
  }

  Future<void> _loadRecentSessions() async {
    final db = DatabaseService.instance;
    final allSessions = db.getAllSessions();

    // Get the 5 most recent closed sessions
    final recentSessions = allSessions
        .where((session) => session.status == SessionStatus.closed)
        .take(5)
        .toList();

    if (!mounted) return;

    setState(() {
      _recentSessions = recentSessions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'FocusGuard',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Start New Session',
            onPressed: () {
              // Navigate to timer screen for quick session start
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TimerScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // GlassAppBar is translucent and floats over the body
            // (extendBodyBehindAppBar: true) - without this spacer, the
            // stats header rendered underneath/behind the blurred bar
            // instead of below it.
            SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top),
            // Today's stats header
            _buildTodayStats(context),
            const SizedBox(height: AppSpacing.lg),

            // Quick start button
            _buildQuickStartButton(context),

            // Recent sessions preview
            Expanded(
              child: _buildRecentSessionsPreview(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'Today',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                context: context,
                label: 'Sessions',
                value: _todaySessions.toString(),
                icon: Icons.timeline,
              ),
              _buildStatCard(
                context: context,
                label: 'Hours',
                value: _todayHours.toStringAsFixed(1),
                icon: Icons.hourglass_empty,
              ),
              _buildStatCard(
                context: context,
                label: 'Streak',
                value: '$_currentStreak days',
                icon: Icons.flash_on, // Using flash_on instead of fire
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildQuickStartButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ElevatedButton(
        onPressed: () {
          // Navigate to timer screen
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TimerScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppShape.borderRadius,
          ),
        ),
        child: const Text(
          'Start Focus Session',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildRecentSessionsPreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Sessions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _recentSessions.isEmpty
              ? const Center(
                  child: Text(
                    'No recent sessions',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                )
              : SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentSessions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final session = _recentSessions[index];
                      return _buildRecentSessionItem(context, session);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildRecentSessionItem(BuildContext context, FocusSession session) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
        borderRadius: AppShape.borderRadius,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              session.subjectTag,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${_formatDuration(Duration(minutes: session.actualDurationMinutes))} • ${_formatTime(session.startTime)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (session.selfRating != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppShape.borderRadiusSmall,
                ),
                child: Text(
                  '${session.selfRating!.score}/5',
                  style: (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatTime(DateTime dateTime) {
    if (_use24HourFormat) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}
