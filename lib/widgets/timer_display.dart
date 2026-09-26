import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Large countdown readout: phase label, mm:ss, optional subject tag.
/// Optionally shows a circular progress indicator indicating elapsed fraction.
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({
    super.key,
    required this.phaseLabel,
    required this.remaining,
    this.subjectTag,
    this.totalDuration, // If provided, shows progress indicator
  });

  final String phaseLabel;
  final Duration remaining;
  final String? subjectTag;
  final Duration? totalDuration; // Total duration of the current phase

  String get _formatted {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (totalDuration == null || totalDuration! == Duration.zero) return 0.0;
    final elapsed = totalDuration! - remaining;
    return elapsed.inSeconds / totalDuration!.inSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          phaseLabel.toUpperCase(),
          style: textTheme.labelLarge?.copyWith(color: colorScheme.primary, letterSpacing: 2),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (totalDuration != null)
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 8,
                  color: colorScheme.primary,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              Text(
                _formatted,
                style: AppTypography.countdownDisplay(colorScheme.onSurface),
              ),
            ],
          )
        else
          Text(_formatted, style: AppTypography.countdownDisplay(colorScheme.onSurface)),
        if (subjectTag != null && subjectTag!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(subjectTag!, style: textTheme.bodyMedium),
        ],
      ],
    );
  }
}
