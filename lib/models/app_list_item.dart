import 'dart:typed_data';

import 'enums.dart';

class AppListItem {
  AppListItem({
    required this.packageName,
    required this.appName,
    required this.iconBytes,
    required this.heuristicCategory,
    this.categoryOverride,
    required this.isBlocked,
    this.blockNote,
  });

  final String packageName;
  final String appName;
  final Uint8List? iconBytes;
  final AppCategory heuristicCategory;
  final AppCategory? categoryOverride;
  final bool isBlocked;
  final String? blockNote;

  AppCategory get resolvedCategory => categoryOverride ?? heuristicCategory;
  bool get isCategoryOverridden => categoryOverride != null;

  AppListItem copyWith({
    AppCategory? categoryOverride,
    bool clearCategoryOverride = false,
    bool? isBlocked,
    String? blockNote,
    bool clearBlockNote = false,
  }) {
    return AppListItem(
      packageName: packageName,
      appName: appName,
      iconBytes: iconBytes,
      heuristicCategory: heuristicCategory,
      categoryOverride:
          clearCategoryOverride ? null : (categoryOverride ?? this.categoryOverride),
      isBlocked: isBlocked ?? this.isBlocked,
      blockNote: clearBlockNote ? null : (blockNote ?? this.blockNote),
    );
  }
}
