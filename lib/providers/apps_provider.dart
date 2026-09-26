import 'dart:developer';
import 'package:flutter/foundation.dart';

import '../models/app_list_item.dart';
import '../models/enums.dart';
import '../services/database_service.dart';
import '../services/installed_apps_service.dart';
import '../services/native_bridge_service.dart';

class AppsProvider extends ChangeNotifier {
  List<AppListItem> _allApps = [];
  bool _isLoading = false;
  String? _loadError;
  String _searchQuery = '';
  AppCategory? _categoryFilter;

  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  String get searchQuery => _searchQuery;
  AppCategory? get categoryFilter => _categoryFilter;

  List<AppListItem> get filteredApps {
    Iterable<AppListItem> result = _allApps;

    if (_categoryFilter != null) {
      result = result.where((app) => app.resolvedCategory == _categoryFilter);
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      result = result.where((app) => app.appName.toLowerCase().contains(query));
    }

    // Convert to list and sort by appName (case-insensitive)
    var list = result.toList();
    list.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    return list;
  }

  List<String> get blockedPackageNames =>
      _allApps.where((app) => app.isBlocked).map((app) => app.packageName).toList();

  Future<void> loadApps() async {
    if (_isLoading) return;
    _isLoading = true;
    _loadError = null;
    _allApps = []; // Reset to empty list while loading
    notifyListeners();

    try {
      _allApps = await InstalledAppsService.instance.loadApps();
    } catch (e) {
      _loadError = 'Could not load installed apps: $e';
      _allApps = []; // Ensure empty list on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(AppCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  Future<void> setBlocked(
    AppListItem app, {
    required bool isBlocked,
    String? note,
  }) async {
    final resolvedNote = isBlocked && (note != null && note.isNotEmpty) ? note : null;

    try {
      // Sync with native bridge first
      await _syncNativeBridge();
      // Then update local state and database
      await DatabaseService.instance.setBlocked(
        app.packageName,
        isBlocked: isBlocked,
        blockNote: resolvedNote,
      );
      _replaceApp(
        app.copyWith(
          isBlocked: isBlocked,
          blockNote: resolvedNote,
          clearBlockNote: resolvedNote == null,
        ),
      );
    } catch (e) {
      // If sync fails, do not update local state
      rethrow;
    }
  }

  Future<void> setCategoryOverride(AppListItem app, AppCategory category) async {
    await DatabaseService.instance.setCategoryOverride(app.packageName, category);
    _replaceApp(app.copyWith(categoryOverride: category));
  }

  void _replaceApp(AppListItem updated) {
    final index = _allApps.indexWhere((a) => a.packageName == updated.packageName);
    if (index == -1) return;
    _allApps = List.of(_allApps)..[index] = updated;
    notifyListeners();
  }

  Future<void> _syncNativeBridge() async {
    try {
      final blocked = _allApps.where((app) => app.isBlocked).toList();
      await NativeBridgeService.instance.syncBlockedApps(
        packages: blocked.map((app) => app.packageName).toList(),
        notes: {
          for (final app in blocked)
            if (app.blockNote != null && app.blockNote!.isNotEmpty) app.packageName: app.blockNote!,
        },
      );
    } catch (e, stack) {
      log('Failed to sync blocked apps: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }
}