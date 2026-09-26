import 'package:flutter/material.dart';
import '../services/native_bridge_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_app_bar.dart';

/// Screen for viewing app usage statistics.
class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  Map<String, Duration> _usageStats = {};
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadUsageStats();
  }

  Future<void> _loadUsageStats() async {
    try {
      final stats = await NativeBridgeService.instance.getTodayUsageStats();
      setState(() {
        _usageStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: 'Usage Statistics',
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(child: Text('Error loading usage data: $_error'))
                : _usageStats.isEmpty
                    ? const Center(child: Text('No usage data available'))
                    : ListView(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          kToolbarHeight + MediaQuery.of(context).padding.top + AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        children: [
                          const Text(
                            'Today\'s App Usage',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          for (final entry in _usageStats.entries)
                            UsageTile(
                              appName: entry.key,
                              duration: entry.value,
                            ),
                        ],
                      ),
      ),
    );
  }
}

class UsageTile extends StatelessWidget {
  const UsageTile({
    super.key,
    required this.appName,
    required this.duration,
  });

  final String appName;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    String formattedTime;
    if (hours > 0) {
      formattedTime = '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      formattedTime = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: AppShape.borderRadius,
      ),
      child: ListTile(
        leading: const Icon(Icons.bar_chart),
        title: Text(appName, style: textTheme.titleMedium),
        trailing: Text(formattedTime, style: textTheme.bodyLarge),
      ),
    );
  }
}