import 'dart:io';

import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/focus_session.dart';
import '../services/database_service.dart';
import '../screens/timer_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_app_bar.dart';
import '../screens/session_detail_screen.dart';

/// History screen - displays a list of past focus sessions with filtering options.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Completed, Early Ended
  List<FocusSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    final allSessions = DatabaseService.instance.getAllSessions();
    setState(() {
      _sessions = allSessions
          .where((session) =>
              session.subjectTag
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) &&
              (_selectedFilter == 'All' ||
                  (_selectedFilter == 'Completed' &&
                      session.status == SessionStatus.closed) ||
                  (_selectedFilter == 'Early Ended' &&
                      session.status == SessionStatus.closed &&
                      /* would need to check if ended early */ true)))
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Most recent first
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'History',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _sessions.isEmpty
            ? _buildEmptyState(context)
            : _buildSessionList(context),
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
              Icons.timeline_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No sessions yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Complete your first focus session to see it here.',
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

  Widget _buildSessionList(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _sessions.length,
      separatorBuilder: (_, __) => Divider(
        height: 0.5,
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
      ),
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return _buildSessionItem(context, session);
      },
    );
  }

  Widget _buildSessionItem(BuildContext context, FocusSession session) {
    return ListTile(
      leading: session.photoPath != null
          ? ClipRRect(
              borderRadius: AppShape.borderRadiusSmall,
              child: Image.file(
                File(session.photoPath!),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            )
          : Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                borderRadius: AppShape.borderRadiusSmall,
              ),
              child: const Icon(
                Icons.image_not_supported,
                size: 24,
                color: Colors.grey,
              ),
            ),
      title: Text(
        session.subjectTag,
        style: Theme.of(context).textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${_formatDuration(getSessionDuration(session))} • ${_formatTime(session.startTime)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: session.selfRating != null
          ? Chip(
              label: Text('${session.selfRating!.score}/5'),
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              padding: EdgeInsets.zero,
            )
          : const Icon(
              Icons.radio_button_unchecked,
              size: 20,
              color: Colors.grey,
            ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SessionDetailScreen(sessionId: session.id),
          ),
        );
      },
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
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Sessions'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by subject or tag',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _loadSessions();
            });
          },
          onSubmitted: (_) => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Sessions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.timeline),
              title: const Text('All Sessions'),
              selected: _selectedFilter == 'All',
              onTap: () {
                setState(() {
                  _selectedFilter = 'All';
                  _loadSessions();
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Completed Sessions'),
              selected: _selectedFilter == 'Completed',
              onTap: () {
                setState(() {
                  _selectedFilter = 'Completed';
                  _loadSessions();
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.timelapse),
              title: const Text('Early Ended'),
              selected: _selectedFilter == 'Early Ended',
              onTap: () {
                setState(() {
                  _selectedFilter = 'Early Ended';
                  _loadSessions();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}