import 'package:cairo_coding_app/core/theme/app_colors.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryLight,
      onPrimary: AppColors.onPrimaryLight,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.onPrimaryLight,
      tertiary: AppColors.thirdLight,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      surfaceContainerLowest: AppColors.deepLight,
      surfaceContainerHighest: AppColors.backgroundAltLight,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.borderLight,
      error: AppColors.errorLight,
    ),
    background: AppColors.backgroundLight,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.onPrimaryDark,
      tertiary: AppColors.thirdDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      surfaceContainerLowest: AppColors.deepDark,
      surfaceContainerHighest: AppColors.backgroundAltDark,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.borderDark,
      error: AppColors.errorDark,
    ),
    background: AppColors.backgroundDark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color background,
  }) {
    final isDark = brightness == Brightness.dark;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;
    final fieldRadius = BorderRadius.circular(12);
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    OutlineInputBorder fieldBorder(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: fieldRadius,
      borderSide: BorderSide(color: color, width: width),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: AppTextStyles.font16Normal.fontFamily,
      splashFactory: InkSparkle.splashFactory,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.font32Bold.copyWith(color: textPrimary),
        displayMedium: AppTextStyles.font24Bold.copyWith(color: textPrimary),
        displaySmall: AppTextStyles.font20Bold.copyWith(color: textPrimary),
        titleMedium: AppTextStyles.font16SemiBold.copyWith(color: textPrimary),
        bodyLarge: AppTextStyles.font16Normal.copyWith(color: textPrimary),
        bodyMedium: AppTextStyles.font14Normal.copyWith(color: textPrimary),
        bodySmall: AppTextStyles.font12Normal.copyWith(color: textSecondary),
        labelLarge: AppTextStyles.font14Bold.copyWith(color: textPrimary),
        labelMedium: AppTextStyles.font12Medium.copyWith(color: textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.font18ExtraBold.copyWith(color: textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: brightness,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: .4),
          disabledForegroundColor: colorScheme.onPrimary,
          elevation: 0,
          minimumSize: Size(0, 48),
          padding: EdgeInsets.symmetric(horizontal: 18),
          textStyle: AppTextStyles.font16ExtraBold,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: Size(0, 44),
          padding: EdgeInsets.symmetric(horizontal: 16),
          side: BorderSide(color: colorScheme.outline),
          textStyle: AppTextStyles.font14Bold,
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: Size(0, 44),
          textStyle: AppTextStyles.font14Bold,
          shape: buttonShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondary,
          minimumSize: Size(40, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: colorScheme.outline),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, 44)),
          textStyle: WidgetStatePropertyAll(AppTextStyles.font14Bold),
          side: WidgetStatePropertyAll(BorderSide(color: colorScheme.outline)),
          shape: WidgetStatePropertyAll(buttonShape),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? colorScheme.onPrimary : textSecondary,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outline),
        shape: const StadiumBorder(),
        showCheckmark: false,
        labelStyle: AppTextStyles.font14SemiBold.copyWith(color: textSecondary),
        secondaryLabelStyle: AppTextStyles.font14ExtraBold.copyWith(color: colorScheme.onPrimary),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        hintStyle: AppTextStyles.font14Normal.copyWith(color: textSecondary),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: fieldBorder(colorScheme.outline),
        enabledBorder: fieldBorder(colorScheme.outline),
        focusedBorder: fieldBorder(colorScheme.primary, 1.5),
        errorBorder: fieldBorder(colorScheme.error),
        focusedErrorBorder: fieldBorder(colorScheme.error, 1.5),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        indicatorColor: colorScheme.primary.withValues(alpha: .16),
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppTextStyles.font12SemiBold.copyWith(color: colorScheme.primary)
              : AppTextStyles.font12Medium.copyWith(color: textSecondary),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? colorScheme.primary : textSecondary),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
        labelStyle: AppTextStyles.font16ExtraBold,
        unselectedLabelStyle: AppTextStyles.font16SemiBold,
        indicatorColor: colorScheme.primary,
        dividerColor: colorScheme.outline,
        tabAlignment: TabAlignment.start,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outline),
        ),
        titleTextStyle: AppTextStyles.font18ExtraBold.copyWith(color: textPrimary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: AppTextStyles.font14SemiBold.copyWith(color: background),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outline, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colorScheme.primary),
    );
  }
}
