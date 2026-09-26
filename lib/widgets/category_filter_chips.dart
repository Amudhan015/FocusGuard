import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/enums.dart';
import '../theme/app_theme.dart';

/// Horizontal scrollable row of category filter chips, with "All" as
/// the null-category option.
class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppCategory? selected;
  final ValueChanged<AppCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        children: [
          _chip(context, label: 'All', value: null),
          for (final category in AppCategory.values) ...[
            const SizedBox(width: AppSpacing.xs),
            _chip(context, label: category.label, value: category),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, {required String label, required AppCategory? value}) {
    final isSelected = selected == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onSelected(value);
      },
      showCheckmark: false,
    );
  }
}
