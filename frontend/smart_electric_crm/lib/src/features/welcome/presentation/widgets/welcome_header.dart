import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_quotes.dart';
import '../../../../core/theme/app_design_tokens.dart';

class WelcomeHeader extends StatelessWidget {
  final VoidCallback onSettingsPressed;

  const WelcomeHeader({
    required this.onSettingsPressed,
    super.key,
  });

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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Настройки',
                  onPressed: onSettingsPressed,
                  icon: const Icon(Icons.settings_outlined),
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateStr,
              style: TextStyle(
                color: Colors.white.withOpacity(isDark ? 0.74 : 0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '"${appQuotes[Random().nextInt(appQuotes.length)]}"',
              style: TextStyle(
                color: Colors.white.withOpacity(isDark ? 0.62 : 0.8),
                fontSize: 14,
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
