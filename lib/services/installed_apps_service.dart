import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

import '../models/app_list_item.dart';
import '../utils/app_category_classifier.dart';
import 'database_service.dart';

class InstalledAppsService {
  InstalledAppsService._();
  static final InstalledAppsService instance = InstalledAppsService._();

  Future<List<AppListItem>> loadApps() async {
    final rawApps = await InstalledApps.getInstalledApps(
      excludeSystemApps: true,
      excludeNonLaunchableApps: true,
      withIcon: true,
    );

    final items = rawApps.map((app) => _mergeWithMeta(app)).toList();
    items.sort(
      (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
    );
    return items;
  }

  AppListItem _mergeWithMeta(AppInfo app) {
    final meta = DatabaseService.instance.getAppMeta(app.packageName);
    return AppListItem(
      packageName: app.packageName,
      appName: app.name,
      iconBytes: app.icon,
      heuristicCategory: AppCategoryClassifier.classify(app.packageName),
      categoryOverride: meta?.categoryOverride,
      isBlocked: meta?.isBlocked ?? false,
      blockNote: meta?.blockNote,
    );
  }
}
