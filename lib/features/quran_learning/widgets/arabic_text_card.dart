import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ArabicTextCard extends StatelessWidget {
  const ArabicTextCard({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 36,
          height: 2.2,
          fontFamily: 'Amiri',
          color: Colors.white,
        ),
      ),
    );
  }
}
