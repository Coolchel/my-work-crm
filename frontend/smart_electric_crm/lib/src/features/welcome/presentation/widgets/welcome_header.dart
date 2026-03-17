import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_quotes.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/presentation/widgets/desktop_web_frame.dart';

class WelcomeHeader extends StatefulWidget {
  final VoidCallback onSettingsPressed;

  const WelcomeHeader({
    required this.onSettingsPressed,
    super.key,
  });

  @override
  State<WelcomeHeader> createState() => _WelcomeHeaderState();
}

class _WelcomeHeaderState extends State<WelcomeHeader> {
  late final String _quote;

  @override
  void initState() {
    super.initState();
    _quote = appQuotes[Random().nextInt(appQuotes.length)];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Доброй ночи';
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('d MMMM yyyy, EEEE', 'ru').format(DateTime.now());
    final isDark = AppDesignTokens.isDark(context);
    final textStyles = context.appTextStyles;
    final isDesktopLike =
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) ||
            DesktopWebFrame.isDesktop(context, minWidth: 1180);
    final greetingFontSize = isDesktopLike ? 26.0 : 28.0;
    final dateFontSize = isDesktopLike ? 14.0 : 15.0;
    final quoteFontSize = isDesktopLike ? 12.0 : 13.0;

    final gradientColors = isDark
        ? const [
            Color(0xFF181B20),
            Color(0xFF1D2229),
            Color(0xFF1A1F26),
          ]
        : [
            Colors.indigo.shade700,
            Colors.teal.shade500,
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _getGreeting(),
                    style: textStyles.heroTitle.copyWith(
                      fontSize: greetingFontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Настройки',
                  onPressed: widget.onSettingsPressed,
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  color: Colors.white.withOpacity(isDark ? 0.82 : 0.9),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateStr,
              style: textStyles.bodyStrong.copyWith(
                color: Colors.white.withOpacity(isDark ? 0.74 : 0.9),
                fontSize: dateFontSize,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '"$_quote"',
              style: textStyles.secondaryBody.copyWith(
                color: Colors.white.withOpacity(isDark ? 0.62 : 0.8),
                fontSize: quoteFontSize,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
