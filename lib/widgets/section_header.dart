import 'package:flutter/material.dart';
import 'package:voice_ai_app/theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? color;
  final bool required; // <-- new flag

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.color,
    this.required = true, // <-- default true (all sections show star)
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(icon, color: color ?? AppColors.primary, size: 24),
            ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color ?? AppColors.primary,
                  ),
                ),
                if (required)
                  const TextSpan(
                    text: " *",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
