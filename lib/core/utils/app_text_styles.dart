import 'package:cairo_coding_app/core/const/app_fonts.dart';
import 'package:cairo_coding_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppTextStyles {
  static bool _isArabic = false;

  static void setLanguage(String languageCode) => _isArabic = languageCode == 'ar';

  static String get bodyFamily => _isArabic ? AppFonts.cairo : AppFonts.nunito;

  static TextStyle _font(double size, FontWeight weight) =>
      TextStyle(fontFamily: bodyFamily, fontSize: size, fontWeight: weight);

  static TextStyle _mono(double size, FontWeight weight) =>
      TextStyle(fontFamily: AppFonts.mono, fontSize: size, fontWeight: weight);

  static TextStyle get font32Bold => _font(32, FontWeight.bold);

  static TextStyle get font28ExtraBold => _font(28, FontWeight.w800);

  static TextStyle get font24Bold => _font(24, FontWeight.bold);

  static TextStyle get font24ExtraBold => _font(24, FontWeight.w800);

  static TextStyle get font22ExtraBold => _font(22, FontWeight.w800);

  static TextStyle get font20Bold => _font(20, FontWeight.bold);

  static TextStyle get font18Normal => _font(18, FontWeight.normal);

  static TextStyle get font18Bold => _font(18, FontWeight.bold);

  static TextStyle get font18ExtraBold => _font(18, FontWeight.w800);

  static TextStyle get font16Normal => _font(16, FontWeight.normal);

  static TextStyle get font16SemiBold => _font(16, FontWeight.w600);

  static TextStyle get font16Bold => _font(16, FontWeight.bold);

  static TextStyle get font16ExtraBold => _font(16, FontWeight.w800);

  static TextStyle get font14Normal => _font(14, FontWeight.normal);

  static TextStyle get font14Medium => _font(14, FontWeight.w500);

  static TextStyle get font14SemiBold => _font(14, FontWeight.w600);

  static TextStyle get font14Bold => _font(14, FontWeight.bold);

  static TextStyle get font14ExtraBold => _font(14, FontWeight.w800);

  static TextStyle get font12Normal => _font(12, FontWeight.normal);

  static TextStyle get font12Medium => _font(12, FontWeight.w500);

  static TextStyle get font12SemiBold => _font(12, FontWeight.w600);

  static TextStyle get monoFont28Bold => _mono(28, FontWeight.w700);

  static TextStyle get monoFont20Bold => _mono(20, FontWeight.w700);

  static TextStyle get monoFont16Bold => _mono(16, FontWeight.w700);

  static TextStyle get monoFont14Bold => _mono(14, FontWeight.w700);

  static TextStyle get monoFont14Medium => _mono(14, FontWeight.w500);

  static TextStyle get monoFont12Bold => _mono(12, FontWeight.w700);

  static TextStyle get monoFont12Medium => _mono(12, FontWeight.w500);

  static TextStyle get monoFont10Medium => _mono(10, FontWeight.w500);

  static TextStyle get arabicLabel =>
      const TextStyle(fontFamily: AppFonts.cairo, fontSize: 14, fontWeight: FontWeight.bold);

  static TextStyle get latinLabel =>
      const TextStyle(fontFamily: AppFonts.nunito, fontSize: 14, fontWeight: FontWeight.bold);

  static TextStyle wordmarkOf(double fontSize) => TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    height: 0.98,
    letterSpacing: -0.01 * fontSize,
  );
}

extension AppTextStyleColors on TextStyle {
  TextStyle secondary(BuildContext context) => copyWith(
    color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
  );
}
