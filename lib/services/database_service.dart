import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/achievement.dart';
import '../models/app_meta.dart';
import '../models/enums.dart';
import '../models/escape_attempt.dart';
import '../models/focus_session.dart';
import '../models/phone_pickup_event.dart';
import '../models/session_template.dart';
import '../models/streak_data.dart';
import 'dart:developer';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const _appMetaBoxName = 'app_meta';
  static const _sessionsBoxName = 'sessions';
  static const _templatesBoxName = 'templates';
  static const _streakBoxName = 'streak';
  static const _achievementsBoxName = 'achievements';
  static const _streakKey = 'streak_data';

  static const _uuid = Uuid();

  late Box<AppMeta> _appMetaBox;
  late Box<FocusSession> _sessionsBox;
  late Box<SessionTemplate> _templatesBox;
  late Box<StreakData> _streakBox;
  late Box<Achievement> _achievementsBox;

  bool _initialized = false;

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError('DatabaseService not initialized. Call init() first.');
    }
  }

  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    Hive.registerAdapter(AppCategoryAdapter());
    Hive.registerAdapter(SessionModeAdapter());
    Hive.registerAdapter(SessionStatusAdapter());
    Hive.registerAdapter(SelfRatingAdapter());
    Hive.registerAdapter(AchievementTypeAdapter());
    Hive.registerAdapter(EscapeAttemptAdapter());
    Hive.registerAdapter(PhonePickupEventAdapter());
    Hive.registerAdapter(FocusSessionAdapter());
    Hive.registerAdapter(SessionTemplateAdapter());
    Hive.registerAdapter(AppMetaAdapter());
    Hive.registerAdapter(StreakDataAdapter());
    Hive.registerAdapter(AchievementAdapter());

    _appMetaBox = await Hive.openBox<AppMeta>(_appMetaBoxName);
    _sessionsBox = await Hive.openBox<FocusSession>(_sessionsBoxName);
    _templatesBox = await Hive.openBox<SessionTemplate>(_templatesBoxName);
    _streakBox = await Hive.openBox<StreakData>(_streakBoxName);
    _achievementsBox = await Hive.openBox<Achievement>(_achievementsBoxName);

    await _seedFirstLaunchDataIfNeeded();

    _initialized = true;
  }

  AppMeta? getAppMeta(String packageName) {
    if (!_initialized) {
      log('DatabaseService not initialized. Returning null for getAppMeta.');
      return null;
    }
    return _appMetaBox.get(packageName);
  }

  Future<void> saveAppMeta(AppMeta meta) async {
    _checkInitialized();
    await _appMetaBox.put(meta.packageName, meta);
  }

  Future<void> setBlocked(
    String packageName, {
    required bool isBlocked,
    String? blockNote,
  }) async {
    _checkInitialized();
    final existing = _appMetaBox.get(packageName);
    if (existing != null) {
      existing.isBlocked = isBlocked;
      existing.blockNote = blockNote;
      existing.lastUpdated = DateTime.now();
      await existing.save();
    } else {
      await saveAppMeta(AppMeta(
        packageName: packageName,
        isBlocked: isBlocked,
        blockNote: blockNote,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  Future<void> setCategoryOverride(
    String packageName,
    AppCategory category,
  ) async {
    _checkInitialized();
    final existing = _appMetaBox.get(packageName);
    if (existing != null) {
      existing.categoryOverride = category;
      existing.lastUpdated = DateTime.now();
      await existing.save();
    } else {
      await saveAppMeta(AppMeta(
        packageName: packageName,
        categoryOverride: category,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  List<String> get blockedPackageNames => _appMetaBox.values
      .where((meta) => meta.isBlocked)
      .map((meta) => meta.packageName)
      .toList();

  String newSessionId() {
    if (!_initialized) {
      log('DatabaseService not initialized. Generating session ID anyway.');
    }
    return _uuid.v4();
  }

  Future<void> saveSession(FocusSession session) async {
    _checkInitialized();
    await _sessionsBox.put(session.id, session);
  }

  FocusSession? getSession(String id) {
    if (!_initialized) {
      log('DatabaseService not initialized. Returning null for getSession.');
      return null;
    }
    return _sessionsBox.get(id);
  }

  List<FocusSession> getAllSessions() {
    if (!_initialized) {
      log('DatabaseService not initialized. Returning empty list for getAllSessions.');
      return [];
    }
    final all = _sessionsBox.values.toList();
    all.sort((a, b) => b.startTime.compareTo(a.startTime));
    return all;
  }

  Future<void> clearAllSessions() async {
    _checkInitialized();
    await _sessionsBox.clear();
  }

  List<FocusSession> getSessionsByStatus(SessionStatus status) =>
      getAllSessions().where((s) => s.status == status).toList();

  List<FocusSession> getPendingClosureSessions() =>
      getSessionsByStatus(SessionStatus.pendingClosure);

  Future<void> deleteSession(String id) async {
    _checkInitialized();
    await _sessionsBox.delete(id);
  }

  Future<void> saveTemplate(SessionTemplate template) async {
    _checkInitialized();
    await _templatesBox.put(template.id, template);
  }

  List<SessionTemplate> getAllTemplates() {
    if (!_initialized) {
      log('DatabaseService not initialized. Returning empty list for getAllTemplates.');
      return [];
    }
    return _templatesBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> deleteTemplate(String id) async {
    _checkInitialized();
    await _templatesBox.delete(id);
  }

  StreakData getStreakData() {
    if (!_initialized) {
      log('DatabaseService not initialized. Returning default streak data.');
      return StreakData();
    }
    return _streakBox.get(_streakKey) ?? StreakData();
  }

  Future<void> saveStreakData(StreakData data) async {
    _checkInitialized();
    await _streakBox.put(_streakKey, data);
  }

  List<Achievement> getAllAchievements() {
    if (!_initialized) {
      log('DatabaseService not initialized. Returning empty list for getAllAchievements.');
      return [];
    }
    return _achievementsBox.values.toList();
  }

  Future<void> saveAchievement(Achievement achievement) async {
    _checkInitialized();
    await _achievementsBox.put(achievement.id, achievement);
  }

  Future<void> _seedFirstLaunchDataIfNeeded() async {
    if (_templatesBox.isEmpty) {
      final now = DateTime.now();
      await _templatesBox.putAll({
        'seed-homework-45': SessionTemplate(
          id: 'seed-homework-45',
          name: 'Homework - 45 min',
          mode: SessionMode.deepFocus,
          focusMinutes: 45,
          subjectTag: 'Homework',
          intentionText: null,
          createdAt: now,
        ),
        'seed-revision-90': SessionTemplate(
          id: 'seed-revision-90',
          name: 'Revision - 90 min',
          mode: SessionMode.pomodoro,
          focusMinutes: 25,
          shortBreakMinutes: 5,
          longBreakMinutes: 20,
          sessionsBeforeLongBreak: 3,
          subjectTag: 'Revision',
          intentionText: null,
          createdAt: now,
        ),
        'seed-quick-focus-25': SessionTemplate(
          id: 'seed-quick-focus-25',
          name: 'Quick Focus - 25 min',
          mode: SessionMode.pomodoro,
          focusMinutes: 25,
          shortBreakMinutes: 5,
          longBreakMinutes: 15,
          sessionsBeforeLongBreak: 4,
          subjectTag: 'General',
          intentionText: null,
          createdAt: now,
        ),
      });
    }

    if (_achievementsBox.isEmpty) {
      final catalog = <Achievement>[
        Achievement(
          id: 'streak-3',
          title: '3-Day Streak',
          description: 'Complete a qualifying session 3 days in a row.',
          type: AchievementType.streakDays,
          thresholdValue: 3,
        ),
        Achievement(
          id: 'streak-7',
          title: 'Week Warrior',
          description: 'Complete a qualifying session 7 days in a row.',
          type: AchievementType.streakDays,
          thresholdValue: 7,
        ),
        Achievement(
          id: 'streak-30',
          title: 'Month of Focus',
          description: 'Complete a qualifying session 30 days in a row.',
          type: AchievementType.streakDays,
          thresholdValue: 30,
        ),
        Achievement(
          id: 'sessions-10',
          title: 'Getting Started',
          description: 'Close 10 focus sessions.',
          type: AchievementType.totalSessions,
          thresholdValue: 10,
        ),
        Achievement(
          id: 'sessions-50',
          title: 'Committed',
          description: 'Close 50 focus sessions.',
          type: AchievementType.totalSessions,
          thresholdValue: 50,
        ),
        Achievement(
          id: 'minutes-600',
          title: '10 Hours Focused',
          description: 'Accumulate 600 minutes of closed focus time.',
          type: AchievementType.totalFocusMinutes,
          thresholdValue: 600,
        ),
        Achievement(
          id: 'minutes-3000',
          title: '50 Hours Focused',
          description: 'Accumulate 3000 minutes of closed focus time.',
          type: AchievementType.totalFocusMinutes,
          thresholdValue: 3000,
        ),
        Achievement(
          id: 'perfect-week-1',
          title: 'Perfect Week',
          description: 'Close at least one session every day for a week.',
          type: AchievementType.perfectWeek,
          thresholdValue: 1,
        ),
      ];
      await _achievementsBox.putAll({for (final a in catalog) a.id: a});
    }
  }
}
