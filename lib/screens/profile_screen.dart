import 'package:flutter/material.dart';
import '../services/app_preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_app_bar.dart';

/// Screen for viewing and editing user profile information.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = '';
  String _email = '';
  String _bio = '';

  // Was `TextEditingController(text: _displayName)` created inline inside
  // build() for each field - a brand new controller every single build
  // (i.e. every keystroke, since onChanged calls setState). That leaks a
  // controller per rebuild and can make the cursor jump since a fresh
  // controller has no memory of where you were typing.
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await AppPreferencesService.instance.getPreferences();
    setState(() {
      _displayName = prefs.displayName;
      _email = prefs.email;
      _bio = prefs.bio;
      _displayNameController.text = _displayName;
      _emailController.text = _email;
      _bioController.text = _bio;
    });
  }

  Future<void> _saveProfile() async {
    await AppPreferencesService.instance.updateProfile(
      displayName: _displayName,
      email: _email,
      bio: _bio,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: 'Profile',
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            kToolbarHeight + MediaQuery.of(context).padding.top + AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          children: [
            const Text(
              'Display Name',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextField(
              controller: _displayNameController,
              onChanged: (value) => setState(() => _displayName = value),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Email',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextField(
              controller: _emailController,
              onChanged: (value) => setState(() => _email = value),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Bio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextField(
              controller: _bioController,
              onChanged: (value) => setState(() => _bio = value),
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}