import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/enums.dart';
import '../theme/app_theme.dart';

class CategoryPickerSheet extends StatelessWidget {
  const CategoryPickerSheet({super.key, required this.current});

  final AppCategory current;

  static Future<AppCategory?> show(BuildContext context, {required AppCategory current}) {
    return showModalBottomSheet<AppCategory>(
      context: context,
      builder: (_) => CategoryPickerSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text('Set category', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final category in AppCategory.values)
              ListTile(
                title: Text(category.label),
                trailing: category == current ? const Icon(Icons.check) : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop(category);
                },
              ),
          ],
        ),
      ),
    );
  }
}
