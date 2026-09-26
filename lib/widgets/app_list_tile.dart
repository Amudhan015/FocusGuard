import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:focusguard/models/enums.dart';

import '../models/app_list_item.dart';
import '../theme/app_theme.dart';

class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.app,
    required this.onToggleBlocked,
    required this.onCategoryTap,
    required this.onEditNote,
  });

  final AppListItem app;
  final ValueChanged<bool> onToggleBlocked;
  final VoidCallback onCategoryTap;
  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          _AppIcon(iconBytes: app.iconBytes),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.appName,
                  style: textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: onCategoryTap,
                  borderRadius: AppShape.borderRadiusSmall,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          app.resolvedCategory.label,
                          style: textTheme.labelSmall?.copyWith(color: colorScheme.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (app.isCategoryOverridden) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.edit, size: 12, color: colorScheme.primary),
                        ],
                      ],
                    ),
                  ),
                ),
                if (app.isBlocked && (app.blockNote?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      app.blockNote!,
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (app.isBlocked)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Edit blocking note',
              onPressed: onEditNote,
            ),
          Switch(
            value: app.isBlocked,
            onChanged: onToggleBlocked,
          ),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.iconBytes});

  final Uint8List? iconBytes;

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    if (iconBytes == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppShape.borderRadiusSmall,
        ),
        child: const Icon(Icons.apps, size: 24),
      );
    }
    return ClipRRect(
      borderRadius: AppShape.borderRadiusSmall,
      child: Image.memory(iconBytes!, width: size, height: size, fit: BoxFit.cover),
    );
  }
}
