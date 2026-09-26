// This replaces the default `flutter create` counter-app test, which
// referenced a `MyApp` widget in lib/main.dart that doesn't exist yet -
// main.dart is wired up once providers/screens exist in a later stage.
//
// Until then, this file holds real sanity tests against Stage 1 code
// (design tokens + models) instead of sitting broken. It will grow into
// proper widget tests once lib/main.dart lands.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/models/achievement.dart';
import 'package:focusguard/models/enums.dart';
import 'package:focusguard/theme/app_theme.dart';

void main() {
  group('AppSpacing', () {
    test('every spacing token is a multiple of 8', () {
      const tokens = [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ];
      for (final value in tokens) {
        expect(value % 8, 0, reason: '$value is not a multiple of 8');
      }
    });
  });

  group('AppTheme', () {
    test('light and dark themes build without throwing', () {
      expect(() => AppTheme.light, returnsNormally);
      expect(() => AppTheme.dark, returnsNormally);
    });

    test('light and dark use different brightness', () {
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
    });
  });

  group('SelfRating', () {
    test('score ordering matches Poor < Okay < Good < Great', () {
      expect(SelfRating.poor.score, lessThan(SelfRating.okay.score));
      expect(SelfRating.okay.score, lessThan(SelfRating.good.score));
      expect(SelfRating.good.score, lessThan(SelfRating.great.score));
    });
  });

  group('Achievement', () {
    test('isUnlocked reflects unlockedAt', () {
      final locked = Achievement(
        id: 'a',
        title: 'A',
        description: 'desc',
        type: AchievementType.totalSessions,
        thresholdValue: 10,
      );
      expect(locked.isUnlocked, isFalse);

      final unlocked = Achievement(
        id: 'b',
        title: 'B',
        description: 'desc',
        type: AchievementType.totalSessions,
        thresholdValue: 10,
        unlockedAt: DateTime(2026, 1, 1),
      );
      expect(unlocked.isUnlocked, isTrue);
    });
  });
}
