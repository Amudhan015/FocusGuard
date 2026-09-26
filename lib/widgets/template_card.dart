import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/session_template.dart';
import '../theme/app_theme.dart';
import 'pressable_scale.dart';

/// One tappable template card, wrapped in PressableScale for immediate
/// press feedback per the design skill's response principle.
class TemplateCard extends StatelessWidget {
  const TemplateCard({super.key, required this.template, required this.onTap});

  final SessionTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppShape.borderRadius,
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              template.mode == SessionMode.pomodoro ? Icons.repeat : Icons.timer,
              color: colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              template.name,
              style: textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              template.mode == SessionMode.pomodoro
                  ? '${template.focusMinutes} min focus - Pomodoro'
                  : '${template.focusMinutes} min - Deep Focus',
              style: textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              template.subjectTag,
              style: textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
