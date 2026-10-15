import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class LessonProgress extends StatelessWidget {
  const LessonProgress({super.key, required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: AppColors.border,
        color: AppColors.accent,
      ),
    );
  }
}
