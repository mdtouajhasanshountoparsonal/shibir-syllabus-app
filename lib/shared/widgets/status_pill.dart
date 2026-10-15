import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';

/// A colored pill showing a [StudyStatus].
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.compact = false});

  final StudyStatus status;
  final bool compact;

  Color get _color {
    switch (status) {
      case StudyStatus.notStarted:
        return Colors.white54;
      case StudyStatus.reading:
        return AppColors.info;
      case StudyStatus.completed:
        return AppColors.success;
      case StudyStatus.needsRevision:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.labelBn,
        style: TextStyle(
          color: _color,
          fontSize: compact ? 10.5 : 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
