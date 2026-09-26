import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import '../models/enums.dart';

class Preferences {
  final bool notificationsEnabled;
  final bool use24HourFormat;
  final SessionMode defaultMode;
  final int defaultFocusMinutes;
  final bool strictModeEnabled;
  final String displayName;
  final String email;
  final String bio;

  const Preferences({
    required this.notificationsEnabled,
    required this.use24HourFormat,
    required this.defaultMode,
    required this.defaultFocusMinutes,
    required this.strictModeEnabled,
    required this.displayName,
    required this.email,
    required this.bio,
  });
}

class AppPreferencesService {
  AppPreferencesService._();
  static final AppPreferencesService instance = AppPreferencesService._();

  static const _keyOnboardingCompleted = 'onboarding_completed';
  static const _keyNotificationsEnabled = 'notifications_enabled';
  static const _keyUse24HourFormat = 'use_24_hour_format';
  static const _keyDefaultMode = 'default_mode';
  static const _keyDefaultFocusMinutes = 'default_focus_minutes';
  static const _keyStrictModeEnabled = 'strict_mode_enabled';
  static const _keyDisplayName = 'display_name';
  static const _keyEmail = 'email';
  static const _keyBio = 'bio';

  late SharedPreferences _prefs;
  bool _initialized = false;

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError('AppPreferencesService not initialized. Call init() first.');
    }
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  bool get isOnboardingCompleted {
    if (!_initialized) {
      log('AppPreferencesService not initialized. Returning default value for isOnboardingCompleted.');
      return false;
    }
    return _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  Future<void> setOnboardingCompleted(bool value) async {
    _checkInitialized();
    await _prefs.setBool(_keyOnboardingCompleted, value);
  }

  Future<Preferences> getPreferences() async {
    _checkInitialized();
    return Preferences(
      notificationsEnabled: _prefs.getBool(_keyNotificationsEnabled) ?? true,
      use24HourFormat: _prefs.getBool(_keyUse24HourFormat) ?? false,
      defaultMode: SessionMode.values[_prefs.getInt(_keyDefaultMode) ?? SessionMode.pomodoro.index],
      defaultFocusMinutes: _prefs.getInt(_keyDefaultFocusMinutes) ?? 25,
      strictModeEnabled: _prefs.getBool(_keyStrictModeEnabled) ?? false,
      displayName: _prefs.getString(_keyDisplayName) ?? '',
      email: _prefs.getString(_keyEmail) ?? '',
      bio: _prefs.getString(_keyBio) ?? '',
    );
  }

  Future<void> updatePreferences({
    bool? notificationsEnabled,
    bool? use24HourFormat,
    SessionMode? defaultMode,
    int? defaultFocusMinutes,
    bool? strictModeEnabled,
    String? displayName,
    String? email,
    String? bio,
  }) async {
    _checkInitialized();
    if (notificationsEnabled != null) {
      await _prefs.setBool(_keyNotificationsEnabled, notificationsEnabled);
    }
    if (use24HourFormat != null) {
      await _prefs.setBool(_keyUse24HourFormat, use24HourFormat);
    }
    if (defaultMode != null) {
      await _prefs.setInt(_keyDefaultMode, defaultMode.index);
    }
    if (defaultFocusMinutes != null) {
      await _prefs.setInt(_keyDefaultFocusMinutes, defaultFocusMinutes);
    }
    if (strictModeEnabled != null) {
      await _prefs.setBool(_keyStrictModeEnabled, strictModeEnabled);
    }
    if (displayName != null) {
      await _prefs.setString(_keyDisplayName, displayName);
    }
    if (email != null) {
      await _prefs.setString(_keyEmail, email);
    }
    if (bio != null) {
      await _prefs.setString(_keyBio, bio);
    }
  }

  Future<void> updateProfile({
    required String displayName,
    required String email,
    required String bio,
  }) async =>
      updatePreferences(
        displayName: displayName,
        email: email,
        bio: bio,
      );

  Future<void> clearPreferences() async {
    _checkInitialized();
    await _prefs.remove(_keyNotificationsEnabled);
    await _prefs.remove(_keyUse24HourFormat);
    await _prefs.remove(_keyDefaultMode);
    await _prefs.remove(_keyDefaultFocusMinutes);
    await _prefs.remove(_keyStrictModeEnabled);
    await _prefs.remove(_keyDisplayName);
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keyBio);
  }
}