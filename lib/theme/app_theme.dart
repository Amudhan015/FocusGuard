import 'package:flutter/material.dart';

/// FocusGuard design tokens - the single source of truth for color,
/// spacing, radius and typography. Every screen and widget pulls values
/// from here - no screen defines its own one-off Color(...) or
/// TextStyle(...).

class AppColors {
  AppColors._();

  // Light theme colors - more neutral, restrained palette following Apple principles
  static const Color lightPrimary = Color(0xFF007AFF); // Apple Blue
  static const Color lightSecondary = Color(0xFF5856D6); // Purple for secondary actions
  static const Color lightAccent = Color(0xFF34C759);   // Green for success/positive actions
  static const Color lightBackground = Color(0xFFF2F2F7); // Very light gray background
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white for cards/surfaces
  static const Color lightTextPrimary = Color(0xFF000000); // Black for primary text
  static const Color lightTextSecondary = Color(0xFF8E8E93); // Gray for secondary text
  static const Color lightTertiary = Color(0xFFEFEFF4);    // Very light gray for separators
  static const Color lightQuaternary = Color(0xFFF2F2F7);  // Background level
  static const Color lightError = Color(0xFFFF3B30);      // Red for destructive actions
  static const Color lightSuccess = Color(0xFF34C759);    // Green for positive actions
  static const Color lightWarning = Color(0xFFFF9500);    // Orange for warnings
  static const Color lightDivider = Color(0xFFE5E5EA);    // Thin separator

  // Dark theme colors
  static const Color darkPrimary = Color(0xFF0A84FF); // Brighter blue for dark mode
  static const Color darkSecondary = Color(0xFF5E5CE6); // Purple for dark mode
  static const Color darkAccent = Color(0xFF30D158);   // Green for dark mode
  static const Color darkBackground = Color(0xFF000000); // True black background
  static const Color darkSurface = Color(0xFF1C1C1E);   // Dark gray for surfaces
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // White for primary text
  static const Color darkTextSecondary = Color(0xFF8E8E93); // Gray for secondary text
  static const Color darkTertiary = Color(0xFF2C2C2E);    // Darker tertiary
  static const Color darkQuaternary = Color(0xFF000000);  // Background level
  static const Color darkError = Color(0xFFFF453A);      // Red for dark mode
  static const Color darkSuccess = Color(0xFF30D158);    // Green for dark mode
  static const Color darkWarning = Color(0xFFFFB400);    // Orange for dark mode
  static const Color darkDivider = Color(0xFF38383A);    // Thin separator for dark mode
}

class AppSpacing {
  AppSpacing._();

  // More generous spacing following Apple principles
  static const double xs = 8;   // Extra small
  static const double sm = 12;  // Small
  static const double md = 16;  // Medium
  static const double lg = 20;  // Large
  static const double xl = 24;  // Extra large
  static const double xxl = 30; // 2XL
}

class AppShape {
  AppShape._();

  // Consistent rounded corners
  static const double radius = 12;
  static const double radiusSmall = 8;
  static const double radiusLarge = 16;

  static BorderRadius get borderRadius => BorderRadius.circular(radius);
  static BorderRadius get borderRadiusSmall => BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusLarge => BorderRadius.circular(radiusLarge);
}

/// Typography following Apple's optical-sizing discipline with refined values
class AppTypography {
  AppTypography._();

  static TextTheme build(Color textPrimary, Color textSecondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
        height: 1.15,
        color: textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        height: 1.2,
        color: textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        height: 1.25,
        color: textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.15,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.2,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.3,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.5,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.45,
        color: textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.4,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        height: 1.2,
        color: textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        height: 1.3,
        color: textPrimary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.3,
        color: textSecondary,
      ),
    );
  }

  /// Dedicated style for very large numeric displays (the session
  /// countdown). Following Apple's approach for large numbers.
  static TextStyle countdownDisplay(Color color) {
    return TextStyle(
      fontSize: 88,
      fontWeight: FontWeight.w300,
      letterSpacing: -2.0,
      height: 1.0,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Style for timer display - prominent but not overwhelming
  static TextStyle timerDisplay(Color color) {
    return TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.1,
      color: color,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
        brightness: Brightness.light,
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        accent: AppColors.lightAccent,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
        error: AppColors.lightError,
        divider: AppColors.lightDivider,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        accent: AppColors.darkAccent,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        error: AppColors.darkError,
        divider: AppColors.darkDivider,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color accent,
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color error,
    required Color divider,
  }) {
    const onPrimary = Colors.white;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      tertiary: accent,
      surface: surface,
      error: error,
      onPrimary: onPrimary,
      onSecondary: onPrimary,
      onSurface: textPrimary,
      onError: onPrimary,
    );

    final textTheme = AppTypography.build(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      dividerTheme: DividerThemeData(color: divider, thickness: 0.5, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: background, // Using solid background for now
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0, // No elevation for cards, using subtle borders instead
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppShape.borderRadius,
          side: BorderSide(color: divider, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: textSecondary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppShape.borderRadius),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppShape.borderRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelLarge,
          padding: EdgeInsets.zero,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Removed duplicate fillColor specification
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: AppShape.borderRadiusSmall,
          borderSide: BorderSide.none, // No border by default
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShape.borderRadiusSmall,
          borderSide: BorderSide(color: divider, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShape.borderRadiusSmall,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShape.borderRadiusSmall,
          borderSide: BorderSide(color: error, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppShape.borderRadiusSmall,
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium,
        fillColor: surface.withValues(alpha: 0.05), // Very subtle fill
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: 0.1),
        disabledColor: textSecondary.withValues(alpha: 0.1),
        labelStyle: textTheme.labelLarge?.copyWith(color: textPrimary),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: primary),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: AppShape.borderRadiusSmall,
          side: BorderSide(color: divider, width: 0.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary.withValues(alpha: 0.2) : divider,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.all(textTheme.labelSmall),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppShape.borderRadiusLarge),
        elevation: 2,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: AppShape.borderRadius),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: AppShape.borderRadius),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppShape.borderRadius,
        ),
      ),
    );
  }
}