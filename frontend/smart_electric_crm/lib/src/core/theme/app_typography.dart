import 'package:flutter/material.dart';

@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.heroTitle,
    required this.pageTitle,
    required this.sectionTitle,
    required this.cardTitle,
    required this.dialogTitle,
    required this.body,
    required this.bodyStrong,
    required this.secondaryBody,
    required this.caption,
    required this.captionStrong,
    required this.button,
    required this.input,
    required this.fieldLabel,
    required this.navLabel,
    required this.metricValue,
    required this.metricLabel,
    required this.chartLabel,
  });

  final TextStyle heroTitle;
  final TextStyle pageTitle;
  final TextStyle sectionTitle;
  final TextStyle cardTitle;
  final TextStyle dialogTitle;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle secondaryBody;
  final TextStyle caption;
  final TextStyle captionStrong;
  final TextStyle button;
  final TextStyle input;
  final TextStyle fieldLabel;
  final TextStyle navLabel;
  final TextStyle metricValue;
  final TextStyle metricLabel;
  final TextStyle chartLabel;

  @override
  AppTextStyles copyWith({
    TextStyle? heroTitle,
    TextStyle? pageTitle,
    TextStyle? sectionTitle,
    TextStyle? cardTitle,
    TextStyle? dialogTitle,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? secondaryBody,
    TextStyle? caption,
    TextStyle? captionStrong,
    TextStyle? button,
    TextStyle? input,
    TextStyle? fieldLabel,
    TextStyle? navLabel,
    TextStyle? metricValue,
    TextStyle? metricLabel,
    TextStyle? chartLabel,
  }) {
    return AppTextStyles(
      heroTitle: heroTitle ?? this.heroTitle,
      pageTitle: pageTitle ?? this.pageTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      cardTitle: cardTitle ?? this.cardTitle,
      dialogTitle: dialogTitle ?? this.dialogTitle,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      secondaryBody: secondaryBody ?? this.secondaryBody,
      caption: caption ?? this.caption,
      captionStrong: captionStrong ?? this.captionStrong,
      button: button ?? this.button,
      input: input ?? this.input,
      fieldLabel: fieldLabel ?? this.fieldLabel,
      navLabel: navLabel ?? this.navLabel,
      metricValue: metricValue ?? this.metricValue,
      metricLabel: metricLabel ?? this.metricLabel,
      chartLabel: chartLabel ?? this.chartLabel,
    );
  }

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) {
      return this;
    }

    return AppTextStyles(
      heroTitle: TextStyle.lerp(heroTitle, other.heroTitle, t) ?? heroTitle,
      pageTitle: TextStyle.lerp(pageTitle, other.pageTitle, t) ?? pageTitle,
      sectionTitle:
          TextStyle.lerp(sectionTitle, other.sectionTitle, t) ?? sectionTitle,
      cardTitle: TextStyle.lerp(cardTitle, other.cardTitle, t) ?? cardTitle,
      dialogTitle:
          TextStyle.lerp(dialogTitle, other.dialogTitle, t) ?? dialogTitle,
      body: TextStyle.lerp(body, other.body, t) ?? body,
      bodyStrong: TextStyle.lerp(bodyStrong, other.bodyStrong, t) ?? bodyStrong,
      secondaryBody: TextStyle.lerp(secondaryBody, other.secondaryBody, t) ??
          secondaryBody,
      caption: TextStyle.lerp(caption, other.caption, t) ?? caption,
      captionStrong: TextStyle.lerp(captionStrong, other.captionStrong, t) ??
          captionStrong,
      button: TextStyle.lerp(button, other.button, t) ?? button,
      input: TextStyle.lerp(input, other.input, t) ?? input,
      fieldLabel: TextStyle.lerp(fieldLabel, other.fieldLabel, t) ?? fieldLabel,
      navLabel: TextStyle.lerp(navLabel, other.navLabel, t) ?? navLabel,
      metricValue:
          TextStyle.lerp(metricValue, other.metricValue, t) ?? metricValue,
      metricLabel:
          TextStyle.lerp(metricLabel, other.metricLabel, t) ?? metricLabel,
      chartLabel: TextStyle.lerp(chartLabel, other.chartLabel, t) ?? chartLabel,
    );
  }
}

class AppTypography {
  const AppTypography._();

  static AppTextStyles build({
    required ColorScheme scheme,
    required String fontFamily,
    required List<String> fontFamilyFallback,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    final strongColor =
        isDark ? scheme.onSurface.withOpacity(0.92) : scheme.onSurface;
    final bodyColor =
        isDark ? scheme.onSurface.withOpacity(0.76) : scheme.onSurface;
    final mutedColor =
        isDark ? scheme.onSurface.withOpacity(0.62) : scheme.onSurfaceVariant;
    final labelColor = isDark
        ? scheme.onSurfaceVariant.withOpacity(0.92)
        : scheme.onSurfaceVariant;

    return AppTextStyles(
      heroTitle: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: strongColor,
        size: 32,
        weight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.6,
      ),
      pageTitle: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: strongColor,
        size: 20,
        weight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.2,
      ),
      sectionTitle: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: strongColor,
        size: 17,
        weight: FontWeight.w600,
        height: 1.24,
        letterSpacing: -0.1,
      ),
      cardTitle: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: strongColor,
        size: 15,
        weight: FontWeight.w600,
        height: 1.26,
      ),
      dialogTitle: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: strongColor,
        size: 18,
        weight: FontWeight.w700,
        height: 1.22,
        letterSpacing: -0.15,
      ),
      body: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: bodyColor,
        size: 14,
        weight: FontWeight.w400,
        height: 1.43,
      ),
      bodyStrong: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: bodyColor,
        size: 14,
        weight: FontWeight.w500,
        height: 1.43,
      ),
      secondaryBody: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: mutedColor,
        size: 13,
        weight: FontWeight.w500,
        height: 1.38,
      ),
      caption: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: mutedColor,
        size: 12,
        weight: FontWeight.w400,
        height: 1.33,
      ),
      captionStrong: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: mutedColor,
        size: 12,
        weight: FontWeight.w600,
        height: 1.33,
      ),
      button: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: strongColor,
        size: 14,
        weight: FontWeight.w600,
        height: 1.14,
        letterSpacing: 0.1,
      ),
      input: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: bodyColor,
        size: 14,
        weight: FontWeight.w400,
        height: 1.36,
      ),
      fieldLabel: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: labelColor,
        size: 12,
        weight: FontWeight.w500,
        height: 1.33,
        letterSpacing: 0.1,
      ),
      navLabel: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: labelColor,
        size: 12,
        weight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.1,
      ),
      metricValue: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: strongColor,
        size: 30,
        weight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.35,
      ),
      metricLabel: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: mutedColor,
        size: 12,
        weight: FontWeight.w500,
        height: 1.25,
        letterSpacing: 0.1,
      ),
      chartLabel: _style(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        color: mutedColor,
        size: 11,
        weight: FontWeight.w500,
        height: 1.2,
      ),
    );
  }

  static TextTheme buildTextTheme({
    required TextTheme baseTextTheme,
    required AppTextStyles textStyles,
  }) {
    return baseTextTheme.copyWith(
      displaySmall: textStyles.heroTitle,
      headlineSmall: textStyles.pageTitle,
      titleLarge: textStyles.dialogTitle,
      titleMedium: textStyles.sectionTitle,
      titleSmall: textStyles.cardTitle,
      bodyLarge: textStyles.input,
      bodyMedium: textStyles.body,
      bodySmall: textStyles.caption,
      labelLarge: textStyles.button,
      labelMedium: textStyles.fieldLabel,
      labelSmall: textStyles.navLabel,
    );
  }

  static AppTextStyles fallbackFor(ThemeData theme) {
    final baseStyle = theme.textTheme.bodyMedium;
    return build(
      scheme: theme.colorScheme,
      fontFamily: baseStyle?.fontFamily ?? 'Inter',
      fontFamilyFallback:
          baseStyle?.fontFamilyFallback ?? const <String>['Roboto', 'Arial'],
    );
  }

  static TextStyle _style({
    required String fontFamily,
    required List<String> fontFamilyFallback,
    required Color color,
    required double size,
    required FontWeight weight,
    required double height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

extension AppThemeDataTextStylesX on ThemeData {
  AppTextStyles get appTextStyles =>
      extension<AppTextStyles>() ?? AppTypography.fallbackFor(this);
}

extension AppBuildContextTextStylesX on BuildContext {
  AppTextStyles get appTextStyles => Theme.of(this).appTextStyles;
}
