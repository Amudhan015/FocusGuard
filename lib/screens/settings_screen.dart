import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../services/app_preferences_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_app_bar.dart';
import 'profile_screen.dart';
import 'permission_screen.dart';
import 'usage_screen.dart';
import 'about_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';

/// Settings screen - allows users to configure app preferences and settings.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _use24HourFormat = false;
  SessionMode _defaultMode = SessionMode.pomodoro;
  int _defaultFocusMinutes = 25;
  bool _strictModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await AppPreferencesService.instance.getPreferences();
    setState(() {
      _notificationsEnabled = prefs.notificationsEnabled;
      _use24HourFormat = prefs.use24HourFormat;
      _defaultMode = prefs.defaultMode;
      _defaultFocusMinutes = prefs.defaultFocusMinutes;
      _strictModeEnabled = prefs.strictModeEnabled;
    });
  }

  void _saveSettings() {
    AppPreferencesService.instance.updatePreferences(
      notificationsEnabled: _notificationsEnabled,
      use24HourFormat: _use24HourFormat,
      defaultMode: _defaultMode,
      defaultFocusMinutes: _defaultFocusMinutes,
      strictModeEnabled: _strictModeEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: 'Settings',
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildAccountSection(context),
            _buildPreferencesSection(context),
            _buildDefaultsSection(context),
            _buildPrivacySection(context),
            _buildDataSection(context),
            _buildAboutSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
          child: Text(
            'Account',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        _buildSettingsTile(
          context,
          title: 'Profile',
          subtitle: 'Edit your profile information',
          icon: Icons.person_outline,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            );
          },
        ),
        const Divider(height: 0.5, color: Colors.grey),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
          child: Text(
            'Preferences',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        _buildSettingsTile(
          context,
          title: 'Notifications',
          subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
          icon: Icons.notifications,
          onTap: () {
            setState(() {
              _notificationsEnabled = !_notificationsEnabled;
              _saveSettings();
            });
          },
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
                _saveSettings();
              });
            },
          ),
        ),
        const Divider(height: 0.5, color: Colors.grey),
        _buildSettingsTile(
          context,
          title: 'Time Format',
          subtitle: _use24HourFormat ? '24 Hour' : '12 Hour',
          icon: Icons.timer,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Time Format'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.timer),
                      title: const Text('12 Hour'),
                      selected: !_use24HourFormat,
                      onTap: () {
                        setState(() {
                          _use24HourFormat = false;
                          _saveSettings();
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.timer),
                      title: const Text('24 Hour'),
                      selected: _use24HourFormat,
                      onTap: () {
                        setState(() {
                          _use24HourFormat = true;
                          _saveSettings();
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const Divider(height: 0.5, color: Colors.grey),
      ],
    );
  }

  Widget _buildDefaultsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
          child: Text(
            'Defaults',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        _buildSettingsTile(
          context,
          title: 'Default Mode',
          subtitle: _defaultMode == SessionMode.pomodoro ? 'Pomodoro' : 'Deep Focus',
          icon: Icons.rotate_left,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Default Session Mode'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.timer),
                      title: const Text('Pomodoro'),
                      selected: _defaultMode == SessionMode.pomodoro,
                      onTap: () {
                        setState(() {
                          _defaultMode = SessionMode.pomodoro;
                          _saveSettings();
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Deep Focus'),
                      selected: _defaultMode == SessionMode.deepFocus,
                      onTap: () {
                        setState(() {
                          _defaultMode = SessionMode.deepFocus;
                          _saveSettings();
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const Divider(height: 0.5, color: Colors.grey),
        _buildSettingsTile(
          context,
          title: 'Default Focus Time',
          subtitle: '$_defaultFocusMinutes minutes',
          icon: Icons.timelapse,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Default Focus Time'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('15 minutes'),
                      onTap: () {
                        setState(() {
                          _defaultFocusMinutes = 15;
                          _saveSettings();
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('25 minutes'),
                      selected: _defaultFocusMinutes == 25,
                      onTap: () {
                        setState(() {
                          _defaultFocusMinutes = 25;
                          _saveSettings();
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('30 minutes'),
                      onTap: () {
                        setState(() {
                          _defaultFocusMinutes = 30;
                          _saveSettings();
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('45 minutes'),
                      onTap: () {
                        setState(() {
                          _defaultFocusMinutes = 45;
                          _saveSettings();
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('60 minutes'),
                      onTap: () {
                        setState(() {
                          _defaultFocusMinutes = 60;
                          _saveSettings();
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const Divider(height: 0.5, color: Colors.grey),
        _buildSettingsTile(
          context,
          title: 'Strict Mode',
          subtitle: _strictModeEnabled ? 'Enabled' : 'Disabled',
          icon: Icons.security_outlined,
          onTap: () {
            setState(() {
              _strictModeEnabled = !_strictModeEnabled;
              _saveSettings();
            });
          },
          trailing: Switch(
            value: _strictModeEnabled,
            onChanged: (value) {
              setState(() {
                _strictModeEnabled = value;
                _saveSettings();
              });
            },
          ),
        ),
        const Divider(height: 0.5, color: Colors.grey),
      ],
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
          child: Text(
            'Privacy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        _buildSettingsTile(
          context,
          title: 'App Permissions',
          subtitle: 'View and manage permissions',
          icon: Icons.perm_device_information_outlined,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PermissionScreen(),
              ),
            );
          },
        ),
        const Divider(height: 0.5, color: Colors.grey),
        _buildSettingsTile(
          context,
          title: 'Data Usage',
          subtitle: 'View data usage statistics',
          icon: Icons.storage_outlined,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const UsageScreen(),
              ),
            );
          },
        ),
        const Divider(height: 0.5, color: Colors.grey),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
          child: Text(
            'Data',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        _buildSettingsTile(
          context,
          title: 'Export Data',
          subtitle: 'Export your focus session data',
          icon: Icons.download_outlined,
          onTap: () {
            _exportData(context);
          },
        ),
        const Divider(height: 0.5, color: Colors.grey),
        _buildSettingsTile(
          context,
          title: 'Import Data',
          subtitle: 'Import focus session data',
          icon: Icons.upload_outlined,
          onTap: () {
            _importData(context);
          },
        ),
        const Divider(height: 0.5, color: Colors.grey),
        _buildSettingsTile(
          context,
          title: 'Reset All Data',
          subtitle: 'Delete all focus session data',
          icon: Icons.delete_outline,
          isDestructive: true,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Reset All Data'),
                content: const Text(
                    'Are you sure you want to delete all focus session data? This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await DatabaseService.instance.clearAllSessions();
                      await AppPreferencesService.instance.clearPreferences();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        // Refresh the screen
                        setState(() {});
                      }
                    },
                    style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 0.5, color: Colors.grey),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
          child: Text(
            'About',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        _buildSettingsTile(
          context,
          title: 'FocusGuard',
          subtitle: 'Version 1.0.0',
          icon: Icons.info_outline,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AboutScreen(),
              ),
            );
          },
        ),
        const Divider(height: 0.5, color: Colors.grey),
        _buildSettingsTile(
          context,
          title: 'Terms of Service',
          subtitle: 'View the terms of service',
          icon: Icons.description_outlined,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TermsScreen(),
              ),
            );
          },
        ),
        const Divider(height: 0.5, color: Colors.grey),
        _buildSettingsTile(
          context,
          title: 'Privacy Policy',
          subtitle: 'View the privacy policy',
          icon: Icons.privacy_tip_outlined,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PrivacyPolicyScreen(),
              ),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
          child: Text(
            '© 2026 FocusGuard. All rights reserved.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
      BuildContext context, {
      required String title,
      required String subtitle,
      required IconData icon,
      VoidCallback? onTap,
      bool isDestructive = false,
      Widget? trailing,
    }) {
    return ListTile(
      leading: Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ??
          (isDestructive
              ? Icon(Icons.arrow_forward_ios,
                  size: 18, color: Theme.of(context).colorScheme.error)
              : const Icon(Icons.arrow_forward_ios)),
      onTap: onTap,
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      // Export sessions to JSON
      final sessions = DatabaseService.instance.getAllSessions();
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'sessions': sessions.map((session) => session.toJson()).toList(),
      };

      // For debugging in development - remove in production
      debugPrint('Exporting data: $exportData');

      // For now, show a success message since actual file export
      // would require platform-specific implementation
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully! (Feature coming soon)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      // For now, just show a message since actual file import
      // would require platform-specific implementation
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import feature coming soon!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}